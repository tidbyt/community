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

BASE_URL = "https://api.co2signal.com/v1/latest"  # base co2signal api url
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

# Location and CO2Signal API key are required settings.
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
                name = "CO2Signal API key",
                desc = "Get API key: https://www.co2signal.com",
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
                            "CO2Signal",
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

# Get and render CO2Signal data for the given api key and location.
def render_data(api_key, location):
    data = get_data(api_key, location)

    if data == None:
        return render_message("Couldn't retrieve data")

    else:
        fossil_fuel_percentage = math.round(data["fossil_fuel_percentage"])
        fossil_fuel_color = get_fossil_fuel_color(fossil_fuel_percentage)

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
            ),
        )

# Get and cache CO2Signal data for the given api key and location.
def get_data(api_key, location_string):
    user_cache_key = "co2signal-%s" % hash.sha256(api_key)
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
        response = http.get(BASE_URL, params = params, headers = headers)
        if response.status_code != 200:
            print("Api request failed with status %d" % response.status_code)
            return None
        else:
            raw_data = response.json()
            data = {
                "grid": raw_data["countryCode"],
                "carbon_intensity": raw_data["data"]["carbonIntensity"],
                "fossil_fuel_percentage": raw_data["data"]["fossilFuelPercentage"],
                "intensity_units": raw_data["units"]["carbonIntensity"],
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
