"""
Applet: Hourly Temperature Graph
Summary: Date, temperature, and hourly temperature graph
Description: Display date and current temperature along with a graph of temperature each hour
Author: D. Segel
"""

# Hourly Temperature Graph App
# Copyright (c) 2023 Daniel Segel
# MIT License
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# config
API_KEY = ""

DEFAULT_DAY_COLOR = "#33F8FF"
DEFAULT_DATE_COLOR = "#33F8FF"
DEFAULT_MONTH_COLOR = "#33F8FF"

DEFAULT_NOW_LABEL_COLOR = "#fff"
DEFAULT_NOW_TEMP_COLOR = "#fff"

DEFAULT_MIN_TEMP_COLOR = "#10f"
DEFAULT_MIN_LABEL_COLOR = "#10f"

DEFAULT_MAX_TEMP_COLOR = "#f00"
DEFAULT_MAX_LABEL_COLOR = "#f00"

DEFAULT_GRAPH_TOP_COLOR = "#ED3209"
DEFAULT_GRAPH_FILL_COLOR = "#EAFF00"

DEFAULT_LABEL_FONT = "CG-pixel-3x5-mono"
DEFAULT_TIME_FONT = "tb-8"
DEFAULT_UNITS = False  # False = Fahrenheit
DEFAULT_LOW_OFFSET = 2
DEFAULT_HIGH_OFFSET = 3
DEFAULT_TIME_FORMAT = "false"
DEFAULT_LOCATION = """
{
    "lat": "38.5465",
    "lng": "-121.7465",
    "description": "Davis, CA",
    "locality": "Davis",
    "timezone": "America/Los_Angeles"
}
"""

DEFAULT_POLLING_INTERVAL = 15
DEFAULT_MAX_BAR_HEIGHT = 14

def main(config):
    """Main function that renders the Tidbyt display

    Args:
        config: configuration values
    Returns:
        Pixlet Root element
    """
    api_key = config.get("api_key", API_KEY)
    api_key = "0f21fd8fc8e54c84b9a13812232004"

    if api_key == None:
        return render.Root(
            render.Padding(
                pad = (0, 20, 0, 0),
                child = render.Marquee(
                    child = render.Text("Enter API Key in Options", color = "#fff"),
                    width = 64,
                    align = "center",
                ),
            ),
        )
    history_data = []

    day_color = config.str("day_color", DEFAULT_DAY_COLOR)
    date_color = config.get("date_color", DEFAULT_DATE_COLOR)
    month_color = config.get("month_color", DEFAULT_MONTH_COLOR)
    now_label_color = config.get("now_label_color", DEFAULT_NOW_LABEL_COLOR)
    now_temp_color = config.get("now_temp_color", DEFAULT_NOW_TEMP_COLOR)
    min_label_color = config.get("min_label_color", DEFAULT_MIN_LABEL_COLOR)
    min_temp_color = config.get("min_temp_color", DEFAULT_MIN_TEMP_COLOR)
    max_label_color = config.get("max_label_color", DEFAULT_MAX_LABEL_COLOR)
    max_temp_color = config.get("max_temp_color", DEFAULT_MAX_TEMP_COLOR)
    graph_color = config.get("graph_color", DEFAULT_GRAPH_TOP_COLOR)
    graph_fill_color = config.get("graph_fill_color", DEFAULT_GRAPH_FILL_COLOR)
    fahrenheit_or_celsius = config.get("fahrenheit_or_celsius", DEFAULT_UNITS)
    low_offset = config.get("low_offset", DEFAULT_LOW_OFFSET)
    high_offset = config.get("high_offset", DEFAULT_HIGH_OFFSET)
    polling_interval = int(config.get("polling_interval", DEFAULT_POLLING_INTERVAL)) * 60
    time_format_24 = config.get("24_hour_time", DEFAULT_TIME_FORMAT)

    loc = config.get("location", DEFAULT_LOCATION)
    location = json.decode(loc)

    timezone = location["timezone"]
    lat = location["lat"]
    lng = location["lng"]

    local_time = time.now().in_location(timezone)
    display_time = humanize.time_format("K:mmaa", local_time)

    date_day = humanize.time_format("EEE", local_time)
    date_month = humanize.time_format("MMM", local_time)
    date_date = humanize.time_format("dd", local_time)
    local_date = humanize.time_format("yyyy-MM-dd", local_time)

    weather_data_history = get_data("history", polling_interval, lat, lng, local_date, api_key)
    weather_data_current = get_data("current", polling_interval, lat, lng, local_date, api_key)

    if fahrenheit_or_celsius == "true":
        unit_str = "c"
    else:
        unit_str = "f"

    min_unit = "mintemp_" + unit_str
    max_unit = "maxtemp_" + unit_str
    current_unit = "temp_" + unit_str

    min_temp_float = weather_data_history["forecast"]["forecastday"][0]["day"][min_unit]
    max_temp_float = weather_data_history["forecast"]["forecastday"][0]["day"][max_unit]
    current_temp_float = weather_data_current["current"][current_unit]

    if current_temp_float > max_temp_float:
        max_temp_float = current_temp_float

    min_temp_str = humanize.ftoa(min_temp_float, 0)
    max_temp_str = humanize.ftoa(max_temp_float, 0)
    current_temp_str = humanize.ftoa(current_temp_float, 0)

    # POSITIONING - the whole thing is just one big stack with each item padded out to position it properly
    # COLUMN 1
    day_offset_h = 1
    day_offset_v = 3
    min_temp_offset_h = 1
    min_temp_offset_v = 17
    min_label_offset_h = 1
    min_label_offset_v = 26

    # COLUMN 2
    time_offset_v = 0
    time_offset_h = 17
    current_temp_offset_v = 8
    current_temp_offset_h = 27
    plot_offset_h = 18
    plot_offset_v = 17

    # COLUMN 3
    date_offset_h = 52
    date_offset_v = 1
    month_offset_v = 8
    month_offset_h = 49
    max_temp_offset_h = 50
    max_temp_offset_v = 17
    max_label_offset_h = 48
    max_label_offset_v = 26

    # ADJUSTMENTS
    if time_format_24 == "true":
        display_time = humanize.time_format("HH:mm", local_time)
        time_offset_h += 5
    elif len(display_time) < 7:
        time_offset_h += 2

    if len(min_temp_str) > 2:
        min_temp_offset_h = 1
        min_label_offset_h = 3

    if len(max_temp_str) > 2:
        max_temp_offset_h -= 4
        max_label_offset_h -= 0

    if len(current_temp_str) > 2:
        current_temp_offset_h -= 3

    # get temps for prior hours so we can fill the bargraph
    hour_range = local_time.hour + 1  # range goes to 1 less than value
    for hour in range(hour_range):
        if fahrenheit_or_celsius == "true":
            history_temp = weather_data_history["forecast"]["forecastday"][0]["hour"][hour]["temp_c"]
        else:
            history_temp = weather_data_history["forecast"]["forecastday"][0]["hour"][hour]["temp_f"]
        mapped_temp = map(history_temp, min_temp_float - int(low_offset), max_temp_float + int(high_offset), 0, DEFAULT_MAX_BAR_HEIGHT)
        history_data.extend([(hour, mapped_temp)])

    # print("{}: Lo: {}, Hi: {}, current: {}".format(local_time, min_temp_str, max_temp_str, current_temp_str))
    return render.Root(
        # delay = 5000,
        max_age = 90,  # can't remember what this does
        child = render.Stack(
            children = [
                # COLUMN 1
                render.Padding(pad = (day_offset_h, day_offset_v, 0, 0), child = render.Text(date_day, color = day_color)),
                render.Padding(pad = (min_temp_offset_h, min_temp_offset_v, 0, 0), child = render.Text(content = min_temp_str + "°", color = min_temp_color)),
                render.Padding(pad = (min_label_offset_h, min_label_offset_v, 0, 0), child = render.Text(content = "Low", color = min_label_color, font = DEFAULT_LABEL_FONT)),
                # COLUMN 2
                render.Padding(pad = (time_offset_h, time_offset_v, 0, 0), child = render.Text(content = display_time, color = now_label_color, font = DEFAULT_TIME_FONT)),
                render.Padding(pad = (current_temp_offset_h, current_temp_offset_v, 0, 0), child = render.Text(content = "" + current_temp_str + "°", color = now_temp_color)),
                render.Padding(pad = (plot_offset_h, plot_offset_v, 0, 0), child = render.Plot(data = history_data, width = 24, height = 15, color = graph_color, fill_color = graph_fill_color, x_lim = (0, 23), y_lim = (0, 15), fill = True)),
                # COLUMN 3
                render.Padding(pad = (date_offset_h, date_offset_v, 0, 0), child = render.Text(date_date, color = date_color)),
                render.Padding(pad = (month_offset_h, month_offset_v, 0, 0), child = render.Text(date_month, color = month_color)),
                render.Padding(pad = (max_temp_offset_h, max_temp_offset_v, 0, 0), child = render.Text(content = max_temp_str + "°", color = max_temp_color)),
                render.Padding(pad = (max_label_offset_h, max_label_offset_v, 0, 0), child = render.Text(content = "High", color = max_label_color, font = DEFAULT_LABEL_FONT)),
            ],
        ),
    )

polling_interval_options = [
    schema.Option(
        display = "5 minutes",
        value = "5",
    ),
    schema.Option(
        display = "10 minutes",
        value = "10",
    ),
    schema.Option(
        display = "15 minutes",
        value = "15",
    ),
    schema.Option(
        display = "30 minutes",
        value = "30",
    ),
    schema.Option(
        display = "60 minutes",
        value = "60",
    ),
]

offset_options = [
    schema.Option(
        display = "-5",
        value = "-5",
    ),
    schema.Option(
        display = "-4",
        value = "-4",
    ),
    schema.Option(
        display = "-3",
        value = "-3",
    ),
    schema.Option(
        display = "-2",
        value = "-2",
    ),
    schema.Option(
        display = "-1",
        value = "-1",
    ),
    schema.Option(
        display = "0",
        value = "0",
    ),
    schema.Option(
        display = "1",
        value = "1",
    ),
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "4",
        value = "4",
    ),
    schema.Option(
        display = "5",
        value = "5",
    ),
]

def color_options(custom_colors):
    if custom_colors == "true":
        return [
            schema.Color(
                id = "day_color",
                name = "Day Color",
                desc = "Color of the Date text",
                icon = "brush",
                default = DEFAULT_DAY_COLOR,
            ),
            schema.Color(
                id = "min_temp_color",
                name = "Low Temp Color",
                desc = "Color of the Low temp",
                icon = "brush",
                default = DEFAULT_MIN_TEMP_COLOR,
            ),
            schema.Color(
                id = "min_label_color",
                name = "Low Label Color",
                desc = "Color of the \"Low\" text",
                icon = "brush",
                default = DEFAULT_MIN_LABEL_COLOR,
            ),
            schema.Color(
                id = "now_label_color",
                name = "Now Label Color",
                desc = "Color of the \"Now/time\" text",
                icon = "brush",
                default = DEFAULT_NOW_LABEL_COLOR,
            ),
            schema.Color(
                id = "now_temp_color",
                name = "Now Temp Color",
                desc = "Color of the Now temp",
                icon = "brush",
                default = DEFAULT_NOW_TEMP_COLOR,
            ),
            schema.Color(
                id = "graph_color",
                name = "Graph Top Line Color",
                desc = "Color of the temp graph top line",
                icon = "brush",
                default = DEFAULT_GRAPH_TOP_COLOR,
            ),
            schema.Color(
                id = "graph_fill_color",
                name = "Graph Fill Color",
                desc = "Color of the temp graph fill",
                icon = "brush",
                default = DEFAULT_GRAPH_FILL_COLOR,
            ),
            schema.Color(
                id = "date_color",
                name = "Date Color",
                desc = "Color of the Date text",
                icon = "brush",
                default = DEFAULT_DATE_COLOR,
            ),
            schema.Color(
                id = "month_color",
                name = "Month Color",
                desc = "Color of the Month text",
                icon = "brush",
                default = DEFAULT_MONTH_COLOR,
            ),
            schema.Color(
                id = "max_temp_color",
                name = "High Temp Color",
                desc = "Color of the High temp",
                icon = "brush",
                default = DEFAULT_MAX_TEMP_COLOR,
            ),
            schema.Color(
                id = "max_label_color",
                name = "High Label Color",
                desc = "Color of the \"High\" text",
                icon = "brush",
                default = DEFAULT_MAX_LABEL_COLOR,
            ),
        ]
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "OpenWeather API Key",
                desc = "API Key for OpenWeathermap",
                icon = "user",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for weather source",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "polling_interval",
                name = "Polling Interval",
                desc = "How often to retrieve the current temperature",
                icon = "clock",
                default = polling_interval_options[2].value,
                options = polling_interval_options,
            ),
            schema.Toggle(
                id = "24_hour_time",
                name = "Use a 24-hour clock",
                desc = "Toggle 12/24 hour clock",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "fahrenheit_or_celsius",
                name = "Use Celsius",
                desc = "Toggle between Fahrenheit and Celsius",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "high_offset",
                name = "Graph Top Offset",
                desc = "High Offset Value",
                icon = "gear",
                default = offset_options[3].value,
                options = offset_options,
            ),
            schema.Dropdown(
                id = "low_offset",
                name = "Graph Bottom Offset",
                desc = "Low Offset Value",
                icon = "gear",
                default = offset_options[7].value,
                options = offset_options,
            ),
            schema.Toggle(
                id = "custom_colors",
                name = "Use Custom Colors",
                desc = "A toggle to enable custom colors",
                icon = "gear",
                default = False,
            ),
            schema.Generated(
                id = "generated",
                source = "custom_colors",
                handler = color_options,
            ),
        ],
    )

def get_data(type, polling_interval, lat, lng, local_date, api_key):
    """Function that calls openweathermap.com API

    Args:
        type: current or historical values
        polling_interval: how long to cache each API request
        lat: latitude of the location to use
        lng: longitude of the location to use
        local_date: the date in YYYY-MM-DD format for one of the calls
        api_key: the api_key to use with weatherapi.com
    Returns:
        Pixlet weather data in JSON format
    """
    url = ""
    if type == "current":
        url = "http://api.weatherapi.com/v1/current.json?key={}&q={},{}".format(api_key, lat, lng)
    elif type == "history":
        url = "http://api.weatherapi.com/v1/history.json?key={}&q={},{}&dt={}".format(api_key, lat, lng, local_date)

    res = http.get(url, ttl_seconds = polling_interval)  # cache for polling_interval seconds

    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())

    return res.json()

def map(x, in_min, in_max, out_min, out_max):
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
