"""
Applet: Hourly Weather
Summary: Hourly weather at a glance
Description: Shows today's weather summary and an hour-by-hour forecast with temperature,
weather conditions, precipitation probability, and rainfall in millimeters.
Rainfall colors show peak hourly intensity: green/light, yellow/moderate, red/heavy. Weather data by Open-Meteo.com
(https://open-meteo.com/), CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/).
Values are rounded and conditions are represented by icons.
Author: Johnny Chen
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Weather data by Open-Meteo.com (CC BY 4.0): https://open-meteo.com/
OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"
CACHE_TTL_SECONDS = 15 * 60
ROOT_MAX_AGE_SECONDS = 15 * 60
FRAME_DELAY_MS = 3500
HOURS_PER_PAGE = 4

# Used only when the app has not been configured yet.
DEFAULT_LOCATION = """{"lat":"47.6062","lng":"-122.3321","description":"Seattle, WA, USA","locality":"Seattle","timezone":"America/Los_Angeles"}"""

CLEAR_DAY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAO0lEQVR42mNgwAL+X0z7z0A1gMs0ZHFGQhoY9WfB
1TCRYjsTsZ75fzHtPxOyNfgAo/4sRiaahQbtwhwAc1wfSCQdfEkAAAAASUVORK5CYII=
""")

CLEAR_NIGHT_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAOUlEQVR42mNgoATcef3//53X//9TrJAJWSEhw5hI
cSITLueQZDI2DXDFKqKMjIQ0oJiMrgGbAbQBAGqfHubfEMwkAAAAAElFTkSuQmCC
""")

PARTLY_CLOUDY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAASklEQVR42mNgQAL/L6b9ZyAE0BXh0sRCiqmMuBRN
vxmBws8Kc2JkYdSfhaIBXRGKychOwKeQgYGBgYmBBMCIzJm2at9/qplMOwAA76Mgpo9Od0EAAAAASUVORK5CYII=
""")

CLOUDY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAMElEQVR42mNgGBSAEZvgtFX7/iPzs8KcGBkYGBhY
8ClCB0zEKITJMZHiZtopph0AAIB8DQWHaahmAAAAAElFTkSuQmCC
""")

RAIN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAOElEQVR42mNgGBSAEZvgtFX7/iPzs8KcGBkYGBhY
8ClCB0zEKITJMZHiZtopRgHxW/7/J8QmWiEAkUofa5qYDNMAAAAASUVORK5CYII=
""")

SNOW_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAOElEQVR42mNgGBSAEZvgtFX7/iPzs8KcGBkYGBhY
8ClCB0zEKITJMZHiZtophoOvX7/+J8QmSQMAZhokOZrzewMAAAAASUVORK5CYII=
""")

THUNDER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAASElEQVR42mNgGBSAEZvgtFX7/iPzs8KcGBkYGBhY
8ClCB0zEKITJMZHiZuoozlRfQVxo/L+YBnc/o/4sRpxW/b+Y9h9ZMTIAAKeZGKjQWD3kAAAAAElFTkSuQmCC
""")

FOG_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAM0lEQVR42mNgGBSAkYGBgWHaqn3/CSnMCnNiJN1k
Yk0nzWSauBfFzVEVq/DasKwjjDTTAR19DwIeDN+oAAAAAElFTkSuQmCC
""")

TEMPERATURE_OPTIONS = [
    schema.Option(display = "Fahrenheit", value = "fahrenheit"),
    schema.Option(display = "Celsius", value = "celsius"),
]

HOURS_OPTIONS = [
    schema.Option(display = "Next 8 hours", value = "8"),
    schema.Option(display = "Next 12 hours", value = "12"),
]

def main(config):
    location = get_location(config)
    temperature_unit = config.get("temperature_unit") or "fahrenheit"
    if temperature_unit not in ["fahrenheit", "celsius"]:
        temperature_unit = "fahrenheit"
    hours_ahead = 12 if config.get("hours_ahead") == "12" else 8
    forecast = fetch_forecast(location, temperature_unit)
    if forecast == None:
        return render_unavailable()

    timezone = forecast.get("timezone") or location.get("timezone") or "UTC"
    if not time.is_valid_timezone(timezone):
        timezone = "UTC"
    now = time.now().in_location(timezone)
    summary = build_summary(forecast, now, timezone)
    entries = build_hourly_entries(forecast, now, hours_ahead, timezone)
    if summary == None or len(entries) != hours_ahead:
        return render_unavailable()

    pages = [render_summary_page(summary, temperature_unit)]
    for start in range(0, len(entries), HOURS_PER_PAGE):
        pages.append(render_hourly_page(entries[start:start + HOURS_PER_PAGE]))
    return render.Root(
        delay = FRAME_DELAY_MS,
        max_age = ROOT_MAX_AGE_SECONDS,
        child = render.Sequence(children = pages),
    )

def render_unavailable():
    # Never present demonstration values as an actual weather forecast.
    return render.Root(
        max_age = 300,
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text("WEATHER", font = "CG-pixel-3x5-mono", color = "#a7a7a7"),
                    render.Text("UNAVAILABLE", font = "CG-pixel-3x5-mono", color = "#ffd166"),
                    render.Text("TRY LATER", font = "CG-pixel-3x5-mono", color = "#58a6ff"),
                ],
            ),
        ),
    )

def get_location(config):
    location = json.decode(config.get("location") or DEFAULT_LOCATION)
    if type(location) != "dict" or location.get("lat") == None or location.get("lng") == None:
        return json.decode(DEFAULT_LOCATION)
    return location

def fetch_forecast(location, temperature_unit):
    # Pixlet v0.34.0 propagates transport/JSON decode errors to the host.
    # Starlark has no exception handling; HTTP status errors are handled below.
    response = http.get(
        url = OPEN_METEO_URL,
        params = {
            "latitude": str(location["lat"]),
            "longitude": str(location["lng"]),
            "current": "temperature_2m,weather_code,is_day",
            "hourly": "temperature_2m,precipitation_probability,weather_code,is_day,rain,showers",
            "precipitation_unit": "mm",
            "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max",
            "forecast_days": "2",
            "temperature_unit": temperature_unit,
            "timezone": "auto",
            "timeformat": "unixtime",
        },
        ttl_seconds = CACHE_TTL_SECONDS,
    )
    if response.status_code != 200:
        print("Open-Meteo request failed with status %d" % response.status_code)
        return None
    data = response.json()
    if type(data) != "dict":
        return None
    for key in ["current", "hourly", "daily"]:
        if type(data.get(key)) != "dict":
            return None
    return data

def is_number(value):
    return type(value) in ["int", "float"]

def build_summary(forecast, now, timezone):
    current = forecast["current"]
    daily = forecast["daily"]
    for key in ["temperature_2m", "weather_code", "is_day", "time"]:
        if not is_number(current.get(key)):
            return None

    # Reject responses from a previous day or an out-of-date API cache.
    if abs(now.unix - current["time"]) > 3600:
        return None
    dates = daily.get("time")
    if type(dates) != "list" or len(dates) < 2 or not is_number(dates[0]) or not is_number(dates[1]):
        return None
    if time.from_timestamp(int(dates[0])).in_location(timezone).format("2006-01-02") != now.format("2006-01-02"):
        return None
    for key in ["temperature_2m_max", "temperature_2m_min", "precipitation_probability_max"]:
        values = daily.get(key)
        if type(values) != "list" or len(values) == 0 or not is_number(values[0]):
            return None
    rain = daily_rain(forecast["hourly"], dates[0], dates[1])
    if rain == None:
        return None
    return {
        "rain": rain["total"],
        "rain_color": rain_color(rain["peak"]),
        "temperature": current["temperature_2m"],
        "weather_code": current["weather_code"],
        "is_day": current["is_day"],
        "high": daily["temperature_2m_max"][0],
        "low": daily["temperature_2m_min"][0],
        "precipitation": daily["precipitation_probability_max"][0],
    }

def build_hourly_entries(forecast, now, hours_ahead, timezone):
    hourly = forecast["hourly"]
    times = hourly.get("time")
    if type(times) != "list" or len(times) == 0:
        return []
    for key in ["temperature_2m", "precipitation_probability", "weather_code", "is_day", "rain", "showers"]:
        values = hourly.get(key)
        if type(values) != "list" or len(values) != len(times):
            return []
    start_index = None
    for i in range(len(times)):
        if not is_number(times[i]):
            return []
        if i > 0 and times[i] - times[i - 1] != 3600:
            return []

        # Unix timestamps disambiguate the repeated hour when DST ends.
        if times[i] <= now.unix and now.unix < times[i] + 3600:
            start_index = i
    if start_index == None or start_index + hours_ahead >= len(times):
        return []
    entries = []
    for i in range(start_index, start_index + hours_ahead):
        for key in ["temperature_2m", "precipitation_probability", "weather_code", "is_day", "rain", "showers"]:
            if not is_number(hourly[key][i]):
                return []

        # Precipitation fields at t+1 describe the interval beginning at t.
        for key in ["precipitation_probability", "rain", "showers"]:
            if not is_number(hourly[key][i + 1]) or hourly[key][i + 1] < 0:
                return []
        if hourly["precipitation_probability"][i + 1] > 100:
            return []
        amount = hourly["rain"][i + 1] + hourly["showers"][i + 1]
        entries.append({
            "rain": amount,
            "rain_color": rain_color(amount),
            "time": time.from_timestamp(int(times[i])).in_location(timezone).format("2006-01-02T15:04"),
            "temperature": hourly["temperature_2m"][i],
            "precipitation": hourly["precipitation_probability"][i + 1],
            "weather_code": hourly["weather_code"][i],
            "is_day": hourly["is_day"][i],
            "is_current": i == start_index,
        })
    return entries

def render_summary_page(summary, temperature_unit):
    condition_icon = weather_widget(summary["weather_code"], summary["is_day"])
    temp = rounded_temperature(summary["temperature"])
    high = rounded_temperature(summary["high"])
    low = rounded_temperature(summary["low"])
    rain = int(math.round(summary["precipitation"]))

    return render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text(
                    content = "TODAY %s" % ("C" if temperature_unit == "celsius" else "F"),
                    font = "CG-pixel-3x5-mono",
                    color = "#a7a7a7",
                ),
                render.Row(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        condition_icon,
                        render.Text(
                            content = " %s°" % temp,
                            font = "tb-8",
                            color = "#ffffff",
                        ),
                    ],
                ),
                render.Text(
                    content = "H%s L%s" % (high, low),
                    font = "CG-pixel-3x5-mono",
                    color = "#7ec8ff",
                ),
                render.Row(
                    main_align = "center",
                    children = [
                        render.Text(
                            content = "%s%% " % rain,
                            font = "CG-pixel-3x5-mono",
                            color = "#58a6ff",
                        ),
                        render.Text(
                            content = "%smm" % format_rain(summary["rain"]),
                            font = "CG-pixel-3x5-mono",
                            color = summary["rain_color"],
                        ),
                    ],
                ),
            ],
        ),
    )

def render_hourly_page(entries):
    columns = []

    for entry in entries:
        time_color = "#ffd166" if entry["is_current"] else "#a7a7a7"
        precipitation = int(math.round(entry["precipitation"]))

        columns.append(
            render.Box(
                width = 16,
                height = 32,
                child = render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = format_hour(entry["time"]),
                            font = "CG-pixel-3x5-mono",
                            color = time_color,
                        ),
                        weather_widget(entry["weather_code"], entry["is_day"]),
                        render.Text(
                            content = compact_temperature(entry["temperature"]),
                            font = "CG-pixel-3x5-mono",
                            color = "#ffffff",
                        ),
                        render.Text(
                            content = "%s%%" % precipitation,
                            font = "CG-pixel-3x5-mono",
                            color = "#58a6ff",
                        ),
                        render.Text(
                            content = format_rain(entry["rain"]),
                            font = "CG-pixel-3x5-mono",
                            color = entry["rain_color"],
                        ),
                    ],
                ),
            ),
        )

    return render.Row(children = columns)

def daily_rain(hourly, start, end):
    times = hourly.get("time")
    if type(times) != "list" or end <= start:
        return None
    for key in ["rain", "showers"]:
        if type(hourly.get(key)) != "list" or len(hourly[key]) != len(times):
            return None
    total = 0.0
    peak = 0.0
    count = 0
    for i in range(len(times)):
        if not is_number(times[i]):
            return None
        if start < times[i] and times[i] <= end:
            for key in ["rain", "showers"]:
                if not is_number(hourly[key][i]) or hourly[key][i] < 0:
                    return None
            amount = hourly["rain"][i] + hourly["showers"][i]
            total += amount
            peak = max(peak, amount)
            count += 1
    if count != int((end - start) / 3600):
        return None
    return {"total": total, "peak": peak}

def rain_color(peak):
    # Simplified WMO rain-rate bands, including showers; hourly means can
    # conceal brief downpours. https://www.weather.gov/media/epz/mesonet/CWOP-WMO8.pdf
    if peak <= 0:
        return "#a7a7a7"
    if peak < 2.5:
        return "#78dba9"
    if peak < 10:
        return "#ffd166"
    return "#ff5c5c"

def format_rain(total):
    if total <= 0:
        return "0.0"
    if total < 0.05:
        return "<0.1"
    tenths = int(math.round(total * 10))
    if tenths < 100:
        return "%d.%d" % (tenths // 10, tenths % 10)
    rounded = int(math.round(total))
    if rounded >= 1000:
        return "999+"
    return str(rounded)

def weather_widget(code, is_day):
    if int(code) in [1, 2] and is_day == 0:
        return render.Stack(children = [
            render.Image(src = CLEAR_NIGHT_ICON),
            render.Image(src = CLOUDY_ICON),
        ])
    return render.Image(src = weather_icon(code, is_day))

def weather_icon(code, is_day):
    code = int(code)

    if code == 0:
        return CLEAR_DAY_ICON if is_day == 1 else CLEAR_NIGHT_ICON
    if code == 1 or code == 2:
        return PARTLY_CLOUDY_ICON
    if code == 3:
        return CLOUDY_ICON
    if code == 45 or code == 48:
        return FOG_ICON
    if code >= 51 and code <= 67:
        return RAIN_ICON
    if code >= 71 and code <= 77:
        return SNOW_ICON
    if code >= 80 and code <= 82:
        return RAIN_ICON
    if code >= 85 and code <= 86:
        return SNOW_ICON
    if code in [95, 96, 99]:
        return THUNDER_ICON

    return CLOUDY_ICON

def rounded_temperature(value):
    return int(math.round(value))

def format_hour(timestamp):
    hour = int(timestamp[11:13])

    if hour == 0:
        return "12a"
    if hour < 12:
        return "%sa" % hour
    if hour == 12:
        return "12p"
    return "%sp" % (hour - 12)

def compact_temperature(value):
    text = str(rounded_temperature(value))

    # Four glyphs fit a 16-pixel column. The summary identifies the unit.
    return text + "°" if len(text) < 4 else text

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for the hourly weather forecast",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "temperature_unit",
                name = "Temperature Unit",
                desc = "Display temperatures in Fahrenheit or Celsius",
                icon = "temperatureHalf",
                options = TEMPERATURE_OPTIONS,
                default = TEMPERATURE_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "hours_ahead",
                name = "Forecast Length",
                desc = "How many upcoming hours to show",
                icon = "clock",
                options = HOURS_OPTIONS,
                default = HOURS_OPTIONS[0].value,
            ),
        ],
    )
