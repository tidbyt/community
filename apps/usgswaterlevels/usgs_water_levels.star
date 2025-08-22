"""
USGS Water Levels Tidbyt App
Displays local lake and river water levels as a graph using USGS data
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Default USGS site ID (Lake Champlain at Burlington, VT)
DEFAULT_SITE_ID = "04294500"
CACHE_TTL_SECONDS = 3600  # 1 hour

def main(config):
    site_id = config.get("site_id", DEFAULT_SITE_ID)
    water_body_type = config.get("water_body_type", "0")  # 0 for lakes, 1 for rivers
    param_code = config.get("param_code", "auto")  # auto or specific code

    # Get cached data or fetch new data
    cache_key = "usgs_data_" + site_id + "_" + water_body_type + "_" + param_code
    cached_data = cache.get(cache_key)

    if cached_data != None:
        data = json.decode(cached_data)
    else:
        data = fetch_usgs_data(site_id, water_body_type, param_code)
        if data:
            cache.set(cache_key, json.encode(data), ttl_seconds = CACHE_TTL_SECONDS)

    if not data:
        return render.Root(
            child = render.Column(
                children = [
                    render.Text("USGS Water Levels", color = "#4A90E2"),
                    render.Text("No data available", color = "#FF6B6B"),
                    render.Text("Check site ID: " + site_id, font = "tom-thumb"),
                ],
            ),
        )

    # Create the display - 3 box layout
    return render.Root(
        child = render.Row(
            children = [
                # Left side: 85% of width for content
                render.Box(
                    width = 54,  # 85% of 64 pixels
                    child = render.Column(
                        children = [
                            # Top: marquee section
                            render.Box(
                                height = 12,
                                child = render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 54,
                                            child = render.Text(data["site_name"], color = "#4A90E2", font = "tom-thumb"),
                                        ) if len(data["site_name"]) > 12 else render.Text(data["site_name"], color = "#888", font = "tom-thumb"),
                                        render.Text(data["param_description"], color = "#ff4", font = "tom-thumb"),
                                    ],
                                ),
                            ),
                            # Bottom: Large number display
                            render.Box(
                                height = 20,  # Remaining height
                                child = render.Column(
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        # Large number with units beside it
                                        render.Row(
                                            main_align = "center",
                                            cross_align = "end",
                                            children = [
                                                render.Text(
                                                    str(int(data["current_value"] * 100) / 100),
                                                    color = "#4A90E2",
                                                    font = "6x13",
                                                ),
                                                render.Text(
                                                    " " + data["units"],
                                                    color = "#FFF",
                                                    font = "tom-thumb",
                                                ),
                                            ],
                                        ),
                                        # Small icon/description
                                        render.Text(
                                            get_param_icon(data["param_description"]),
                                            color = "#888",
                                            font = "tom-thumb",
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
                # Right side: 15% of width, FULL HEIGHT for indicator
                render.Box(
                    width = 10,  # 15% of 64 pixels
                    height = 32,  # FULL display height
                    child = render_indicator(data["current_value"], data.get("high_30d"), data.get("low_30d")),
                ),
            ],
        ),
    )

def fetch_usgs_data(site_id, water_body_type, param_code):
    # Get 30 days of data for high/low calculation, plus current data
    end_date = time.now()
    start_date_30d = time.now() - time.parse_duration("720h")  # 30 days
    start_date_current = time.now() - time.parse_duration("24h")  # Current data

    start_str_30d = start_date_30d.format("2006-01-02")
    start_str_current = start_date_current.format("2006-01-02")
    end_str = end_date.format("2006-01-02")

    # Select parameter codes based on settings
    if param_code == "auto":
        # Auto-select based on water body type - prioritize working codes for lakes
        if water_body_type == "0":
            # Lake/reservoir - try working codes first for Lake Champlain
            param_codes = ["62614", "00010", "00095", "62610", "62611", "00062", "00065"]  # Temp, conductance, then elevation codes
        else:
            # River/stream gage height
            param_codes = ["00065", "00010", "00095"]  # Gage height, then temp, conductance
    else:
        # Use the specific parameter code selected by user
        param_codes = [param_code]

    # Try each parameter code until we find data
    for param_code_to_try in param_codes:
        print("Trying parameter code: " + param_code_to_try)

        # USGS Instantaneous Values Web Service URL
        url = "https://waterservices.usgs.gov/nwis/iv/"

        # First get 30 days of data for high/low calculation
        param_parts_30d = []
        param_parts_30d.append("format=json")
        param_parts_30d.append("sites=" + site_id)
        param_parts_30d.append("startDT=" + start_str_30d)
        param_parts_30d.append("endDT=" + end_str)
        param_parts_30d.append("parameterCd=" + param_code_to_try)
        param_parts_30d.append("siteStatus=all")
        param_string_30d = "&".join(param_parts_30d)
        full_url_30d = url + "?" + param_string_30d

        print("Fetching 30-day USGS data from: " + full_url_30d)

        resp_30d = http.get(full_url_30d, ttl_seconds = CACHE_TTL_SECONDS)
        if resp_30d.status_code != 200:
            print("Error fetching 30-day USGS data: " + str(resp_30d.status_code))
            continue

        usgs_data_30d = resp_30d.json()

        if not usgs_data_30d.get("value") or not usgs_data_30d["value"].get("timeSeries"):
            print("No 30-day time series data found for parameter " + param_code_to_try)
            continue

        time_series_30d = usgs_data_30d["value"]["timeSeries"][0]
        values_30d = time_series_30d["values"][0]["value"]

        if not values_30d:
            print("No 30-day values found in time series for parameter " + param_code_to_try)
            continue

        # Now get current data
        param_parts_current = []
        param_parts_current.append("format=json")
        param_parts_current.append("sites=" + site_id)
        param_parts_current.append("startDT=" + start_str_current)
        param_parts_current.append("endDT=" + end_str)
        param_parts_current.append("parameterCd=" + param_code_to_try)
        param_parts_current.append("siteStatus=all")
        param_string_current = "&".join(param_parts_current)
        full_url_current = url + "?" + param_string_current

        print("Fetching current USGS data from: " + full_url_current)

        resp_current = http.get(full_url_current, ttl_seconds = CACHE_TTL_SECONDS)
        if resp_current.status_code != 200:
            print("Error fetching current USGS data: " + str(resp_current.status_code))
            continue

        usgs_data_current = resp_current.json()

        if not usgs_data_current.get("value") or not usgs_data_current["value"].get("timeSeries"):
            print("No current time series data found for parameter " + param_code_to_try)
            continue

        time_series_current = usgs_data_current["value"]["timeSeries"][0]
        site_info = time_series_current["sourceInfo"]
        values_current = time_series_current["values"][0]["value"]

        if not values_current:
            print("No current values found in time series for parameter " + param_code_to_try)
            continue

        print("Found data with parameter code: " + param_code_to_try)

        # Process the 30-day values for high/low
        processed_values_30d = []
        for value in values_30d:
            val_str = value.get("value", "")
            if val_str and val_str != "":
                processed_values_30d.append(float(val_str))

        # Process current values
        processed_values_current = []
        for value in values_current[-10:]:  # Last 10 readings
            val_str = value.get("value", "")
            if val_str and val_str != "":
                processed_values_current.append(float(val_str))

        if not processed_values_current:
            print("No valid current values found for parameter " + param_code_to_try)
            continue

        # Calculate 30-day high and low
        high_30d = None
        low_30d = None
        if processed_values_30d:
            high_30d = max(processed_values_30d)
            low_30d = min(processed_values_30d)

        # Calculate trend from current data
        trend = "Unknown"
        if len(processed_values_current) >= 6:
            recent_vals = processed_values_current[-3:]
            older_vals = processed_values_current[:3]

            # Calculate averages manually since sum() isn't available
            recent_total = 0
            for val in recent_vals:
                recent_total = recent_total + val
            recent_avg = recent_total / len(recent_vals)

            older_total = 0
            for val in older_vals:
                older_total = older_total + val
            older_avg = older_total / len(older_vals)

            if recent_avg > older_avg + 0.1:
                trend = "Rising"
            elif recent_avg < older_avg - 0.1:
                trend = "Falling"
            else:
                trend = "Stable"

        # Get parameter description for display
        param_description = get_param_description(param_code_to_try)

        # Convert temperature from Celsius to Fahrenheit if it's temperature data
        current_value = processed_values_current[-1] if processed_values_current else 0
        if param_code_to_try == "00010":  # Water temperature
            current_value = (current_value * 9 / 5) + 32  # Convert C to F
            if high_30d != None:
                high_30d = (high_30d * 9 / 5) + 32
            if low_30d != None:
                low_30d = (low_30d * 9 / 5) + 32

        return {
            "site_name": site_info["siteName"],
            "values": processed_values_current,
            "current_value": current_value,
            "high_30d": high_30d,
            "low_30d": low_30d,
            "trend": trend,
            "units": get_param_units(param_code_to_try),
            "param_description": param_description,
        }

    # If we get here, no parameter codes worked
    print("No data found for any parameter codes")
    return None

def get_param_description(param_code):
    # Get human-readable description for parameter code
    descriptions = {
        "62614": "Daily Level",
        "00010": "Water Temp",
        "00095": "Conductance",
        "00065": "Gage Height",
        "00062": "Lake Level",
        "62610": "Lake Level",
        "62611": "Lake Level",
    }
    return descriptions.get(param_code, "Water Data")

def get_param_units(param_code):
    # Get units for parameter code
    units = {
        "00010": "°F",  # Temperature in Fahrenheit
        "00095": "μS/cm",
        "00065": "ft",  # Gage height in feet
        "00062": "ft",  # Lake elevation in feet
        "62610": "ft",  # Lake elevation NGVD 1929 in feet
        "62611": "ft",  # Lake elevation NAVD 1988 in feet
        "62614": "ft",  # Daily lake level in feet
    }
    return units.get(param_code, "ft")

def get_param_icon(param_description):
    # Get a simple icon/symbol for the parameter type
    icons = {
        "Water Temp": "🌡️",
        "Conductance": "⚡",
        "Gage Height": "📏",
        "Lake Level": "🌊",
        "Daily Level": "📊",
    }
    return icons.get(param_description, "💧")

def render_indicator(current_value, high_30d, low_30d):
    # Render a vertical indicator showing current value vs 30-day high/low
    if high_30d == None or low_30d == None:
        # No historical data, just show a simple indicator
        return render.Column(
            children = [
                render.Text("x", color = "#4A90E2", font = "tom-thumb"),
            ],
        )

    # Debug: print the values to see what's happening
    print("Current: " + str(current_value) + ", High: " + str(high_30d) + ", Low: " + str(low_30d))

    # Calculate where current value should be positioned (0 = top, 28 = bottom)
    range_val = high_30d - low_30d
    if range_val > 0:
        # Position ratio: 0.0 = at high (top), 1.0 = at low (bottom)
        position_ratio = (current_value - low_30d) / range_val

        # Invert so high values go to top: 1.0 = at high (top), 0.0 = at low (bottom)
        position_ratio = 1.0 - position_ratio

        # Scale to pixel range (0 to 28 pixels from top)
        x_position = int(position_ratio * 28)
    else:
        x_position = 14  # Middle if no range

    print("Position ratio: " + str(1.0 - (current_value - low_30d) / range_val if range_val > 0 else 0.5))
    print("X position (pixels from top): " + str(x_position))

    # Use Stack to position elements absolutely
    elements = []

    # Always show green dash at top (unless current is at/above high)
    if current_value >= high_30d:
        elements.append(
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text("x", color = "#4A90E2", font = "tom-thumb"),
            ),
        )
        print("Added X at top (replacing green dash)")
    else:
        elements.append(
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text("-", color = "#a7fc00", font = "tom-thumb"),
            ),
        )
        print("Added green dash at top")

    # Show blue X at calculated position if current is between high and low
    if current_value < high_30d and current_value > low_30d:
        elements.append(
            render.Padding(
                pad = (0, x_position, 0, 0),  # Calculated position from top
                child = render.Text("x", color = "#4A90E2", font = "tom-thumb"),
            ),
        )
        print("Added X at calculated position: " + str(x_position))

    # Always show red dash at bottom (unless current is at/below low)
    if current_value <= low_30d:
        elements.append(
            render.Padding(
                pad = (0, 28, 0, 0),  # 28 pixels from top (near bottom)
                child = render.Text("x", color = "#4A90E2", font = "tom-thumb"),
            ),
        )
        print("Added X at bottom (replacing red dash)")
    else:
        elements.append(
            render.Padding(
                pad = (0, 28, 0, 0),  # 28 pixels from top
                child = render.Text("-", color = "#FF6B6B", font = "tom-thumb"),
            ),
        )
        print("Added red dash at bottom")

    return render.Stack(
        children = elements,
    )

def render_graph(values):
    # Render a simple line graph that fills most of the screen
    if not values or len(values) < 2:
        return render.Text("No data", color = "#888", font = "tom-thumb")

    # Use most of the available screen space
    graph_width = 60  # Almost full width
    graph_height = 28  # Almost full height

    # Normalize values to fit in display area
    min_val = min(values)
    max_val = max(values)
    range_val = max_val - min_val if max_val != min_val else 1

    # Create a more detailed graph representation
    graph_bars = []
    for i in range(graph_width):
        # Map screen position to data point
        data_index = int((i / (graph_width - 1)) * (len(values) - 1))
        val = values[data_index]

        # Calculate bar height (normalized to graph height)
        bar_height = int(((val - min_val) / range_val) * graph_height)
        bar_height = max(1, min(bar_height, graph_height))  # Ensure valid range

        # Create vertical bar for this data point
        graph_bars.append(
            render.Box(
                width = 1,
                height = bar_height,
                color = "#4A90E2",
            ),
        )

    return render.Stack(
        children = [
            # Graph background
            render.Box(
                width = graph_width,
                height = graph_height,
                color = "#0a0a0a",
            ),
            # Graph bars
            render.Row(
                children = graph_bars,
                main_align = "start",
                cross_align = "end",
            ),
        ],
    )

def get_trend_color(trend):
    # Get color for trend indicator
    if trend == "Rising":
        return "#50E3C2"  # Green
    elif trend == "Falling":
        return "#FF6B6B"  # Red
    else:
        return "#FFD93D"  # Yellow

def get_schema():
    # Configuration schema for the app
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "site_id",
                name = "USGS Site ID",
                desc = "Enter the USGS site ID for your local water body",
                icon = "water",
                default = DEFAULT_SITE_ID,
            ),
            schema.Dropdown(
                id = "water_body_type",
                name = "Water Body Type",
                desc = "Select the type of water body to monitor",
                icon = "water",
                default = "0",
                options = [
                    schema.Option(display = "Lake/Reservoir", value = "0"),
                    schema.Option(display = "River/Stream", value = "1"),
                ],
            ),
            schema.Dropdown(
                id = "param_code",
                name = "Data Parameter",
                desc = "Choose what type of data to display",
                icon = "ruler",
                default = "00010",
                options = [
                    schema.Option(display = "Auto (tries multiple)", value = "auto"),
                    schema.Option(display = "Daily Lake Level", value = "62614"),
                    schema.Option(display = "Water Temperature", value = "00010"),
                    schema.Option(display = "Specific Conductance", value = "00095"),
                    schema.Option(display = "Lake Elevation - NGVD 1929", value = "62610"),
                    schema.Option(display = "Lake Elevation - NAVD 1988", value = "62611"),
                    schema.Option(display = "Lake/Reservoir Elevation", value = "00062"),
                    schema.Option(display = "River/Stream Gage Height", value = "00065"),
                ],
            ),
        ],
    )
