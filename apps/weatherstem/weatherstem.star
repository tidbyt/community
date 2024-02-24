"""
Applet: WeatherSTEM
Summary: Display WeatherSTEM data
Description: Display real-time current weather conditons provided by WeatherSTEM API.
Author: imaginuts
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

# The WeatherSTEM API endpoint used to retrieve current conditions data.
#
# This applet uses https://api.weatherstem.com/api which is free to use but does
# require registration. Visit https://www.weatherstem.com/register to register and recieve your
# free API Key which will need to be entered into the settings.
api_url = "https://api.weatherstem.com/api"

# How long to cache data before making another request
cache_seconds = 240

# Color of the lines used to break up sections of the display
border_color = "#33c"

# Weather icons used in display
wind_icon = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAcAAAAGCAYAAAAPDoR2AAAACXBIWXMAABYlAAAWJQFJUiTwAAAAcElEQVQImWP8//8/AzI4fhsiYKnKyMjEgAYsVRkZYWwWmEpk0LflEzMDAwMjY+h0TEkGBgaG+8cWcrB8uHtSio2b+xMrt+gvpr9//r55cYvx4ATHv2EM8f9Z+KU0nsOVszAwHJzgyBA2g+E/AwMDAwBGoyYA+tOwOwAAAABJRU5ErkJggg==""")

# Sample data for preview - this is a subset of the full data available for rendering a preview image only
sample_data = {
    "record": {
        "readings": [
            {
                "sensor": "Anemometer",
                "value": 7.0,
                "unit": "Miles Per Hour",
                "unit_symbol": "mph",
            },
            {
                "sensor": "Hygrometer",
                "unit": "Percent Humidity",
                "value": 90.0,
                "sensor_type": "Hygrometer",
                "unit_symbol": "%",
            },
            {
                "sensor": "Thermometer",
                "unit": "Degrees Fahrenheit",
                "value": "57.1",
                "sensor_type": "Thermometer",
                "unit_symbol": "&deg;F",
            },
            {
                "unit_symbol": "&deg;",
                "sensor": "Wind Vane",
                "value": 161.0,
                "unit": "Degrees",
                "sensor_type": "Wind Vane",
            },
        ],
    },
    "station": {
        "name": "My Town Center",
    },
}

def main(config):
    """The applet entry point.

    Args:
        config: The applet configuration.

    Returns:
        A definition of what to render.
    """

    api_key = config.str("api_key", "")
    station_id = config.str("station_id", "")
    temperature_type = config.str("temperature_type", "F")
    station_name_override = config.str("station_name", "")
    response_data = {}

    # Check for valid config
    if api_key == "" or station_id == "":
        # return render_error("Invalid WeatherSTEM configuration")
        response_data = load_data(sample_data)

    else:
        # Request data
        request_data = {"api_key": api_key, "stations": [station_id]}
        header_data = {"Content-Type": "application/json"}
        response_data = {}

        resp = http.post(api_url, headers = header_data, json_body = request_data, ttl_seconds = cache_seconds)

        if resp.status_code != 200:
            return render_error("WeatherSTEM request failed with status %d" % resp.status_code)
        else:
            # store the sensor data returned
            response_data = load_data(resp.json()[0])

    station_name = response_data["station"]["name"]
    if station_name_override != "":
        station_name = station_name_override

    temperature_value = float(response_data["Thermometer"]["value"])

    if response_data["Thermometer"]["unit"] == "Degrees Fahrenheit":
        if temperature_type != "F":
            temperature_value = (temperature_value - 32) * (5 / 9)
    elif temperature_type != "C":
        temperature_value = (temperature_value * (9 / 5) + 32)

    humidity_value = math.round(float(response_data["Hygrometer"]["value"]))
    temperature_value = math.round(temperature_value)
    wind_speed = math.round(float(response_data["Anemometer"]["value"]))

    wind_info = "%d %s %s" % (wind_speed, response_data["Anemometer"]["unit_symbol"], deg_to_compass(response_data["Wind Vane"]["value"]))
    humidity_info = "%d%s" % (humidity_value, response_data["Hygrometer"]["unit_symbol"])

    current_temperature_display = "%d°" % (temperature_value)

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Column(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls vertical alignment
                cross_align = "center",  # Controls horizontal alignment
                children = [
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(content = station_name, font = "tom-thumb"),
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",  # Controls vertical alignment
                        cross_align = "center",  # Controls horizontal alignment
                        children = [
                            render.Image(src = wind_icon),
                            render.Text(
                                content = wind_info,
                            ),
                        ],
                    ),
                    render.Box(
                        width = 62,
                        height = 1,
                        color = border_color,
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text(content = "Temp", font = "tom-thumb"),
                                    render.Text(content = current_temperature_display),
                                ],
                            ),
                            render.Box(
                                width = 1,
                                height = 16,
                                color = border_color,
                            ),
                            render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text(content = "Humidity", font = "tom-thumb"),
                                    render.Text(content = "%s" % (humidity_info)),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def load_data(json_data):
    """Parse through json data and store for display

    Args:
        json_data: JSON data returned by API call

    Returns:
       Dictionary holding the stored data.
    """

    response_data = {}

    # store the sensor data returned
    for reading in json_data["record"]["readings"]:
        response_data[reading["sensor"]] = reading

    response_data["station"] = json_data["station"]

    return (response_data)

def deg_to_compass(degress):
    """Convert degrees to named compass direction

    Args:
        degress: compass direction in degreess 0-360.

    Returns:
       String containing named compass direction.
    """

    val = int((degress / 22.5) + .5)
    arr = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    return arr[(val % 16)]

def get_schema():
    temperature_options = [
        schema.Option(
            display = "Fahrenheit",
            value = "F",
        ),
        schema.Option(
            display = "Celcius",
            value = "C",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Private WeatherSTEM API Key. Register for free here https://www.weatherstem.com/register",
                icon = "key",
            ),
            schema.Text(
                id = "station_id",
                name = "Station Id",
                desc = "WeatherSTEM station to use for data. A station Id can be determined from its web address, for example, a station of https://leon.weatherstem.com/fsu has an ID of fsu@leon.weatherstem.com",
                icon = "gaugeHigh",
            ),
            schema.Dropdown(
                id = "temperature_type",
                name = "Temperature Type",
                desc = "The type of temperature to display",
                icon = "temperatureHalf",
                default = temperature_options[0].value,
                options = temperature_options,
            ),
            schema.Text(
                id = "station_name",
                name = "Station Name",
                desc = "Manually override weather station name for display",
                icon = "iCursor",
            ),
        ],
    )

def render_error(msg):
    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Column(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls vertical alignment
                cross_align = "center",  # Controls horizontal alignment
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",  # Controls vertical alignment
                        cross_align = "center",  # Controls horizontal alignment
                        children = [
                            render.Text(
                                content = "ERROR",
                                color = "#F00",
                            ),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(content = msg),
                    ),
                ],
            ),
        ),
    )
