"""
Applet: CO2 Signal
Summary: Local power CO2 intensity
Description: Shows the carbon intensity of your local electricity.
Author: Harper Trow
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

BASE_URL = "https://api.electricitymaps.com/v3"  # base electricity maps api url
USER_DATA_CACHE_EXPIRATION_SECONDS = 300  # 5 minute cache
FONT = "tom-thumb"

def main(config):
    location = config.get("location") or json.encode({
        "lat": "37.63247",
        "lng": "-77.58936",
    })
    api_key = config.get("api_key")

    if api_key == None:
        return render_message("Configure Settings")
    else:
        return render_data(api_key, location)

# Location and electicity API key are required settings.
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Set your current location",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "Electricity Maps API key",
                desc = "Get API key: https://www.electricitymaps.com/get-started",
                icon = "gear",
            ),
        ],
    )

# Render the message in the center of the screen.
def render_message(message):
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            "Electricity Maps CO2",
                            font = FONT,
                            color = "#fa0",
                        ),
                        render.WrappedText(
                            message,
                            font = FONT,
                            color = "#fa0",
                        ),
                    ],
                ),
            ],
        ),
    )

# Get and render Electricity Maps data for the given api key and location.
def render_data(api_key, location):
    data = get_data(api_key, location)

    if data == None:
        return render_message("Couldn't retrieve data")

    else:
        fossil_fuel_percentage = math.round(data["fossil_fuel_percentage"])
        fossil_fuel_color = get_fossil_fuel_color(fossil_fuel_percentage)

        # Frame 1: Original Carbon Intensity
        frame_main = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            data["grid"],
                            font = FONT,
                        ),
                        render.WrappedText(
                            "%s %s" % (int(data["carbon_intensity"]), data["intensity_units"]),
                            font = FONT,
                        ),
                        render.WrappedText(
                            "fossil: %s%%" % fossil_fuel_percentage,
                            font = FONT,
                            color = fossil_fuel_color,
                        ),
                    ],
                ),
            ],
        )

        # Frame 2: Renewable Gauge
        frame_renewable = render_gauge("Renewable", data["renewable_percentage"])

        # Frame 3: Fossil Free Gauge
        frame_fossil_free = render_gauge("Fossil Free", data["fossil_free_percentage"])

        return render.Root(
            delay = 3000,
            child = render.Animation(
                children = [
                    frame_main,
                    frame_renewable,
                    frame_fossil_free,
                ],
            ),
        )

# Get and cache Electricity Maps data for the given api key and location.
def get_data(api_key, location_string):
    user_cache_key = "electricitymaps-%s" % hash.sha256(api_key)
    data = cache.get(user_cache_key)
    location = json.decode(location_string)

    # Fuzz the location coordinates to protect user privacy
    latitude = humanize.float("#.#####", float(location["lat"]))
    longitude = humanize.float("#.#####", float(location["lng"]))

    if data == None:
        print("User data cache miss, calling api to get data")
        headers = {"auth-token": api_key}
        params = {
            "lat": latitude,
            "lon": longitude,
        }

        # 1. Get Carbon Intensity
        url_intensity = "%s/carbon-intensity/latest" % BASE_URL
        response = http.get(url_intensity, params = params, headers = headers)
        if response.status_code != 200:
            print("Intensity API request failed with status %d" % response.status_code)
            return None

        raw_intensity = response.json()

        # 2. Get Power Breakdown (for fossil fuel %)
        # We need a separate call because carbon-intensity endpoint doesn't include it.
        url_breakdown = "%s/power-breakdown/latest" % BASE_URL
        response_breakdown = http.get(url_breakdown, params = params, headers = headers)

        fossil_percentage = 0
        renewable_percentage = 0
        fossil_free_percentage = 0

        if response_breakdown.status_code == 200:
            raw_breakdown = response_breakdown.json()
            if "fossilFreePercentage" in raw_breakdown and raw_breakdown["fossilFreePercentage"] != None:
                # If fossilFreePercentage is available, fossil is 100 - that.
                # Ensure it's treated as a number.
                fossil_free_percentage = int(raw_breakdown["fossilFreePercentage"])
                fossil_percentage = 100 - fossil_free_percentage
            else:
                print("fossilFreePercentage not found in breakdown")

            if "renewablePercentage" in raw_breakdown and raw_breakdown["renewablePercentage"] != None:
                renewable_percentage = int(raw_breakdown["renewablePercentage"])
            else:
                print("renewablePercentage not found in breakdown")

        else:
            print("Breakdown API request failed with status %d" % response_breakdown.status_code)

        data = {
            "grid": raw_intensity.get("zone", "Unknown"),
            "carbon_intensity": raw_intensity.get("carbonIntensity", 0),
            "fossil_fuel_percentage": fossil_percentage,
            "fossil_free_percentage": fossil_free_percentage,
            "renewable_percentage": renewable_percentage,
            "intensity_units": "gCO2eq/kWh",
        }

        cache.set(
            user_cache_key,
            json.encode(data),
            ttl_seconds = USER_DATA_CACHE_EXPIRATION_SECONDS,
        )
        return data
    else:
        print("User data cache hit")
        return json.decode(data)

# Get the color highlighting the fossil fuel intensity percentage.
def get_fossil_fuel_color(fossil_fuel_percentage):
    fossil_fuel_int = int(fossil_fuel_percentage)

    if fossil_fuel_int < 25:
        return "#0f0"  # green
    elif fossil_fuel_int < 50:
        return "#ff0"  # yellow
    elif fossil_fuel_int < 66:
        return "#ffa500"  # orange

    return "#f00"  # red

# Get the color for efficiency metrics (higher is better).
def get_efficiency_color(percentage):
    if percentage >= 66:
        return "#0f0"  # green
    elif percentage >= 33:
        return "#ff0"  # yellow
    return "#f00"  # red

# Render a ring gauge with the percentage in the center.
def render_gauge(title, percentage):
    color = get_efficiency_color(percentage)

    # Ring parameters
    radius = 10
    dot_size = 3
    center = 12

    # Generate dots for the "track" (background ring)
    track_dots = []
    for i in range(0, 360, 10):
        angle = math.radians(i - 90)
        x = center + int(radius * math.cos(angle)) - 1
        y = center + int(radius * math.sin(angle)) - 1
        track_dots.append(
            render.Padding(
                pad = (x, y, 0, 0),
                child = render.Circle(diameter = dot_size, color = "#333"),
            ),
        )

    # Generate dots for the progress
    progress_dots = []
    end_angle = int(360 * percentage / 100)
    for i in range(0, end_angle, 10):
        angle = math.radians(i - 90)
        x = center + int(radius * math.cos(angle)) - 1
        y = center + int(radius * math.sin(angle)) - 1
        progress_dots.append(
            render.Padding(
                pad = (x, y, 0, 0),
                child = render.Circle(diameter = dot_size, color = color),
            ),
        )

    return render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text(title, font = FONT, color = "#fa0"),
            render.Box(height = 1),
            render.Stack(
                children = [
                    # Container for the rings
                    render.Box(
                        width = 24,
                        height = 24,
                        child = render.Stack(children = track_dots + progress_dots),
                    ),
                    # Text in the middle
                    render.Box(
                        width = 24,
                        height = 24,
                        child = render.Row(
                            expanded = True,
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Text("%d%%" % percentage, font = "tom-thumb", color = "#fff"),
                            ],
                        ),
                    ),
                ],
            ),
        ],
    )
