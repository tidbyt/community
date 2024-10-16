"""
Applet: OctoWatts
Summary: Live Energy Monitor
Description: Octopus Energy live consumption monitor with one minute energy trend. Requires an Octopus Home Mini device.
Author: TomForeman86
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_KEY = ""  # Replace with your Octopus Energy API key
DEVICE_ID = ""  # Replace with your actual device ID, You can find your device id on your smart meter or by using thwe FIND_MY_DEVICE config, it will look like this 12-34-AB-CD-56-78-90-EF, there is more than one ID like this on your meters, take care to use the right one

GRAPHQL_URL = "https://api.octopus.energy/v1/graphql/"

RANGE_MIN = -2000
RANGE_MAX = 2000
CHART_TYPE = "pie"

DEMO_MODE = False

COLOR_SCALE_POS = ["#FFFB5E", "#FCE013", "#FCB913", "#FD3900", "#D01A0F", "#7C0A01"]
COLOR_SCALE_NEG = ["#b7ffbf", "#95f985", "#4ded30", "#26d701", "#00c301", "#00ab08"]

ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAMAAAC67D+PAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAACoUExURQAAAP2sMf6sM/6sMv2qNv2sMv+rM/2qOPmsMv+sMv2sNf2tNP2tM/2tMf2tMvmtM/2sM/6tNv2tMv6sMv6sMv6sM/+sMv+sMv6sMv6sMv+sMv+sMv+sMv6sMf+sMv+sMv6sM/2sNf6sNP6sM/uuNf6sMv+sMv+sMv+sMv+sMv+sMv6tMv2tMv6sMvyuMP2tMf6sMv2sMv6sMv+sMv6sMv6sMv+sMv///xmJN0wAAAA2dFJOUwAAAAAAAAAAAAAAAAAAAAAAAAqHWhGUxxseqvxpLsDPIgsNAwFF1+jFyKIcHKIBAw0LLqsRCh/vcn8AAAABYktHRDcwuLhHAAAAB3RJTUUH6AoNCiAYBWbKEQAAAGlJREFUCNcFwQcCgkAMBMDlImikqSBdDlS6Hcj/n+YMAEOpUxDSBjAtdY7ihLYwd5RmecF7Gw5fStFVfb3h3rQiXT+MEx7Poe9E2uaF9+dbaSl/7ML1uMjnlP0DjpTE0cKWBxCFwUpsAH/dWwkrzmInGQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNC0xMC0xM1QxMDozMjoxNCswMDowMKPJwsIAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjQtMTAtMTNUMTA6MzI6MTQrMDA6MDDSlHp+AAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI0LTEwLTEzVDEwOjMyOjI0KzAwOjAwCw5cQgAAAABJRU5ErkJggg==""")

def main(config):
    APIKEY = config.str("API_KEY", API_KEY)
    DEVICEID = config.str("DEVICE_ID", DEVICE_ID)
    CHARTTYPE = config.str("CHART_TYPE", CHART_TYPE)
    RANGEMAX = abs(int(config.str("RANGE_MAX", RANGE_MAX) or RANGE_MAX))
    RANGEMIN = -abs(int(config.str("RANGE_MIN", RANGE_MIN) or RANGE_MIN))
    DEMO = bool(config.str("DEMO_MODE", DEMO_MODE) or DEMO_MODE)

    if config.bool("DEMO_MODE"):
        DEMO = True

    # Ensure RANGEMIN and RANGEMAX are not zero
    RANGEMIN = RANGEMIN if RANGEMIN != 0 else -1
    RANGEMAX = RANGEMAX if RANGEMAX != 0 else 1

    if not DEMO:
        if not APIKEY or APIKEY.strip() == "":
            return render_content("error", None, None, "SETUP", "!", "#7C0A01", None, "ENTER API KEY", "Please provide a valid API KEY.", "Obtain API KEY from Octopus Energy", " ")

        if not DEVICEID or DEVICEID.strip() == "":
            print(DEVICEID)
            return render_content("error", None, None, "SETUP", "!", "#7C0A01", None, "ENTER DEVICE ID", "Located on your smart meter, there is more than one", "Example: 12-34-AB-CD-56-78-90-EF")

        # Obtain the access token
        access_token, error = obtain_access_token(APIKEY)

        # Error handling
        if not access_token and error:
            return render_content("error", None, None, "SETUP", "!", "#7C0A01", None, "API ERROR", error, "Incorrect API KEY in config", " ")

        # Fetch and process telemetry data
        telemetry, error = fetch_telemetry(access_token, DEVICEID, 10)
        if not telemetry and error:
            return render_content("error", None, None, "SETUP", "!", "#7C0A01", None, "API ERROR", error, "Incorrect DEVICE ID in config", " ")
            # Handle API Faults

        elif not telemetry:
            return render_content("error", None, None, "ERROR", "!", "#7C0A01", None, "API ERROR", error, "Octopus API System error, try later", " ")

        # Proccess telemetry data
        demand_value, demand_average = process_telemetry(telemetry)
    else:
        # Generate a random data for DEMO_MODE

        demand_value = random_in_range(1, RANGEMAX)
        demand_average = int(float(demand_value / random_in_range(1, 100) * 10))

        if demand_value % 2 == 0:
            demand_value = -abs(demand_value)
            demand_average = -abs(demand_average)

        print(demand_value)
        print(demand_average)

    # Calculate percentages
    percentage = calculate_percentage(demand_value, RANGEMIN, RANGEMAX)
    trend_percentage = calculate_trend_percentage(demand_value, demand_average)

    # Draw trend arrow and usage text
    trend = draw_arrow(demand_value, demand_average)
    demand_text = format_demand_text(demand_value)

    # Get colours and weights
    trend_color = get_color(int(trend_percentage))
    color = get_color(int(percentage))

    # Render root content
    if CHARTTYPE == "bar_horizontal":
        pixels, pixels_border = calculate_pixels(CHARTTYPE, percentage, demand_value)
        return render_content("bar_horizontal", pixels, pixels_border, demand_text, trend, trend_color, color, None, None, None, None)
    elif CHARTTYPE == "bar_vertical":
        pixels, pixels_border = calculate_pixels(CHARTTYPE, percentage, demand_value)
        return render_content("bar_vertical", pixels, pixels_border, demand_text, trend, trend_color, color, None, None, None, None)
    else:
        weights = generate_weights(percentage)
        return render_content("pie", None, None, demand_text, trend, trend_color, color, weights, None, None, None)

def basic_random():
    seed = str(time.now())[0:27].replace(":", "").replace(".", "").replace("-", "").replace(" ", "").replace("+", "")
    seed = int(seed)
    return (seed * 48271) % 2147483647

def random_in_range(min_val, max_val):
    # Generate a pseudo-random number
    rand_value = basic_random()

    # Scale to the desired range
    range_size = max_val - min_val + 1
    return min_val + (rand_value % range_size)

def process_telemetry(telemetry):
    # Extract the latest demand value and compare with the previous one
    latest_telemetry = telemetry[-1]

    # Check if there are at least 6 telemetry entries
    if len(telemetry) >= 7:
        # Extract previous telemetry data from -6 to -2 (for the last minute)
        previous_telemetries = telemetry[-7:-1]  # Get entries from -6 to -2 (non-inclusive of -2)
        print(previous_telemetries)

        # Initialize total and count for averaging
        total_demand = 0.0
        count = 0

        # Calculate the total of previous demand values
        for t in previous_telemetries:
            demand = float(t.get("demand", 0))
            total_demand += demand
            count += 1

        # Calculate average
        demand_average = total_demand / count if count > 0 else 0

    else:
        # Not enough entries; set to current demand
        demand_average = latest_telemetry["demand"]

    demand_value = int(float(latest_telemetry.get("demand", 0)))
    return demand_value, demand_average

def fetch_telemetry(access_token, device_id, ttl):
    # Check cache so we don't make requests more than every 10 seconds
    cached_telemetry = cache.get("telemetry".format(device_id))
    if cached_telemetry:
        print("Using cached telemetry data.")
        return json.decode(cached_telemetry), None

    # Get the current local time
    current_time = time.now()

    # Add and subtract one minute for time range
    time_range = calculate_time_range(current_time)

    # Build graphql query
    query = """
    query {
      smartMeterTelemetry(
        deviceId: "%s"
        grouping: TEN_SECONDS
        start: "%s"
        end: "%s"
      ) {
        readAt
        demand
      }
    }
    """ % (device_id, time_range["start"], time_range["end"])

    headers = {
        "Content-Type": "application/json",
        "Authorization": access_token,
    }

    response_data, error_message = post_graphql_request(query, headers, ttl)

    if error_message:
        return None, error_message

    telemetry = response_data.get("data", {}).get("smartMeterTelemetry", [])
    if telemetry:
        cache.set("telemetry".format(device_id), json.encode(telemetry), ttl_seconds = 10)
        return telemetry, None

    return None, "No telemetry data found"

def calculate_time_range(current_time):
    one_minute = time.parse_duration("1m")
    return {
        "start": (current_time - one_minute).format("2006-01-02T15:04Z07:00"),
        "end": (current_time + one_minute).format("2006-01-02T15:04Z07:00"),
    }

def round_to_nearest_ten(value):
    return int(((value + 5) // 10) * 10)

def post_graphql_request(query, headers, ttl_seconds):
    payload = json.encode({"query": query})
    response = http.post(url = GRAPHQL_URL, body = payload, headers = headers, ttl_seconds = ttl_seconds)
    parsed_data = response.json()

    errors = parsed_data.get("errors", [])
    if errors:
        error_message = errors[0].get("message", "Unknown error")
        error_description = errors[0].get("extensions", {}).get("errorDescription", None)
        if error_description:
            error_message = error_message + " - " + error_description
        return parsed_data, error_message

    return parsed_data, None

def obtain_access_token(api_key):
    cache_key = "auth_token_" + api_key
    cached_token = cache.get(cache_key)
    if cached_token:
        print("Using existing token")
        return json.decode(cached_token), None

    # Construct the GraphQL mutation query
    mutation = """
    mutation {
      obtainKrakenToken(input: { APIKey: "%s" }) {
        token
      }
    }
    """ % api_key

    headers = {"Content-Type": "application/json"}

    response_data, error_message = post_graphql_request(mutation, headers, 1500)
    if error_message:
        return None, "Error obtaining token: " + error_message

    token = response_data["data"]["obtainKrakenToken"]["token"]
    cache.set(cache_key, json.encode(token), ttl_seconds = 1500)

    return token, None

def calculate_percentage(demand_value, range_min, range_max):
    range_diff = range_max if demand_value >= 0 else range_min
    percentage = (demand_value / range_diff) * 100 if range_diff != 0 else 0

    # Directly negate the percentage if demand_value is negative
    if demand_value <= -1:
        percentage = -abs(percentage)

    if percentage > 100:
        return 100
    elif percentage < -100:
        return -100

    return percentage

def generate_weights(percentage):
    if percentage <= -1:
        percentage = abs(percentage)
    weight = int(1.7 * percentage)

    if percentage > 50:
        value_1 = weight
        value_2 = 175 - weight
    elif percentage == 50:  # Use '==' for comparison
        value_1 = weight
        value_2 = weight
    elif percentage == 0:  # Use '==' for comparison
        value_1 = 5
        value_2 = 175
    else:  # For percentage < 50
        value_1 = weight
        value_2 = 175 - weight

    weights = [180, value_1, 4, 1, value_2]

    return weights

def get_color(percentage):
    color_scale = COLOR_SCALE_POS if percentage > 0 else COLOR_SCALE_NEG

    index = min(max(0, abs(percentage) // 10 - 1), len(color_scale) - 1)
    color = color_scale[index]
    return color

def format_demand_text(demand_value):
    demand_text = "{}w".format(demand_value)
    return demand_text.replace(" w", "w")

def draw_arrow(demand_value, demand_prev_value):
    demand_value, demand_prev_value = float(demand_value), float(demand_prev_value)
    return "↑" if demand_value > demand_prev_value else "↓" if demand_value < demand_prev_value else "→"

def render_content(chart, pixels, pixels_border, demand_text, trend, trend_color, color, weights = None, title = None, error = None, message = None):
    common_row = render.Row(
        main_align = "space_between",
        children = [
            render.Box(width = 12, height = 10, child = render.Image(src = ICON)),
            render.Box(width = 42, height = 10, child = render.Text(content = demand_text, font = "6x13")),
            render.Box(width = 12, height = 10, child = render.Text(content = trend, color = trend_color, font = "6x13")),
        ],
    )

    if chart == "bar_horizontal":
        chart_body = render.Padding(
            pad = (-1, 1, 0, 0),
            child = render.Column(
                cross_align = "left",
                children = [
                    render.Box(
                        color = "#5C5C5C",
                        width = pixels,
                        height = 19,
                        child = render.Box(width = pixels_border, height = 17, color = color),
                    ),
                ],
            ),
        )
    elif chart == "bar_vertical":
        chart_body = render.Row(
            main_align = "center",
            children = [
                render.Stack(
                    children = [
                        render.Box(color = color, width = 64, height = 19),
                        render.Box(color = "#5C5C5C", width = 64, height = pixels_border),
                        render.Box(color = "#000000", width = 64, height = pixels),
                    ],
                ),
            ],
        )
    elif chart == "error":
        chart_body = render.Column(
            main_align = "center",
            children = [
                render.Marquee(width = 64, child = render.Text(title, color = "#fa0", font = "tom-thumb")),
                render.Marquee(width = 64, child = render.Text(error, color = "#fa0", font = "tom-thumb")),
                render.Marquee(width = 64, child = render.Text(message, color = "#D2D2D2", font = "tom-thumb")),
            ],
        )
    else:  # Pie chart case
        chart_body = render.Row(
            main_align = "space_around",
            expanded = True,
            children = [
                render.Stack(
                    children = [
                        render.Circle(color = "#333333", diameter = 40),
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.PieChart(
                                colors = ["#000000", color, "#000000", "#333333", color],
                                weights = weights,
                                diameter = 38,
                            ),
                        ),
                    ],
                ),
            ],
        )

    return render.Root(
        delay = 100,
        child = render.Column(
            expanded = True,
            children = [
                render.Box(height = 1),
                common_row,
                render.Box(height = 2),
                chart_body,
            ],
        ),
    )

def calculate_pixels(chart, percentage, demand_value):
    # Handle negative demand value
    if demand_value <= -1:
        percentage = abs(percentage)

    if chart == "bar_horizontal":
        pixels = int(percentage * 0.64 + 0.5)
        pixels = max(pixels, 3)  # Ensure minimum width of 3
        pixels_border = max(pixels - 2, 2)  # Ensure border is at least 2 less than pixels
    elif chart == "bar_vertical":
        pixels = int((100 - percentage) * (18 / 100))
        pixels = (pixels // 1) + (1 if pixels % 1 > 0 else 0)
        pixels = max(min(pixels, 18), 1)  # Ensure the width is between 1 and 18
        pixels_border = pixels + 1  # Border width is 1 more than pixels
    else:
        return "50", "50"

    return pixels, pixels_border

def calculate_trend_percentage(demand_value, demand_prev_value):
    if demand_prev_value != 0:
        # Calculate percentage difference, rounding before dividing
        percentage_difference = ((int(float(demand_value)) - int(float(demand_prev_value))) * 100 +
                                 (int(float(demand_prev_value)) // 2)) // int(float(demand_prev_value))

        # If demand_value is negative, reverse the sign of percentage_difference
        if demand_value < 0:
            percentage_difference = -percentage_difference
            trend_percentage = max(min(round_to_nearest_ten(percentage_difference), -100), -10)  # Limit to -100 to -10
        else:
            trend_percentage = max(min(round_to_nearest_ten(percentage_difference), 100), 10)  # Limit to 10 to 100

        # Cap the percentage difference between -100% and 100%
        trend_percentage = max(min(percentage_difference, 100), -100)
    else:
        trend_percentage = 0  # Handle division by zero
    return trend_percentage

def get_schema():
    options = [
        schema.Option(
            display = "Guage",
            value = "pie",
        ),
        schema.Option(
            display = "Bar Vertical",
            value = "bar_vertical",
        ),
        schema.Option(
            display = "Bar Horizontal",
            value = "bar_horizontal",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "API_KEY",
                name = "API_KEY",
                desc = "Your Octopus API KEY ",
                icon = "key",
            ),
            schema.Text(
                id = "API_KEY",
                name = "DEVICE_ID",
                desc = "You can find your device id on your smart meter, it will look like this 12-34-AB-CD-56-78-90-EF, there is more than one ID like this on your meters, take care to use the right one",
                icon = "fingerprint",
            ),
            schema.Dropdown(
                id = "CHART_TYPE",
                name = "Chart Type",
                desc = "The type of chart to dispay your current electricity usage.",
                icon = "chartPie",
                default = options[0].value,
                options = options,
            ),
            schema.Text(
                id = "RANGE_MAX",
                name = "MAX GUAGE",
                desc = "Enter your maximum usage in watts, the default is set to 2000 ",
                icon = "fingerprint",
            ),
            schema.Text(
                id = "RANGE_MIN",
                name = "MIN GUAGE",
                desc = "If you use solar panels enter the maximum production value in watts, the default is set to -2000 ",
                icon = "fingerprint",
            ),
            schema.Toggle(
                id = "DEMO_MODE",
                name = "DEMO_MODE",
                desc = "Test the app without providing API credentials",
                icon = "compress",
                default = False,
            ),
        ],
    )
