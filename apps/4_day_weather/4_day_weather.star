"""
Applet:  4 Day Weather
Summary: Use api.openweathermap.org
Description: Using api.openweathermap.org forecast. 
Author: jslevine
"""

load("http. star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    appid = config.get("appid", "")
    lat = config.get("lat", "")
    lon = config.get("lon", "")
    url = WEATHER_URL % (lat, lon, appid)
    if not appid:
        lines = [{
            "text": "openweathermap.org",
            "temp": "-",
            "color": "#ffffff",
        }, {
            "text": "get appid",
            "temp": "-",
            "color": "#ff0000",
        }, {
            "text": "enter lat & lng",
            "temp": "-",
            "color": "#ffffff",
        }]
    else:
        data = get_data(url)

        # We need the timezone offset to ensure we get the correct day of the week
        # for the local user, not UTC.

        tz_offset = int(data.get("timezone_offset", 0))

        lines = []

        # We loop through the first 4 days of the daily forecast
        # index 0 = Today, 1 = Tomorrow, etc.

        for i in range(0, 4):
            day = data["daily"][i]

            # 1. Calculate Day (Mon, Tue, Wed, etc.)
            # We add the offset to the timestamp to force it into local time

            local_ts = int(day["dt"]) + tz_offset
            t = time.from_timestamp(local_ts, 0)

            day_letter = t.format("Mon")

            # 2. Get Description & Temp

            desc = day["weather"][0]["description"]
            min_c = int(day["temp"]["min"] - 273.15)
            max_c = int(day["temp"]["max"] - 273.15)
            temp_str = "%d/%d" % (min_c, max_c)

            # 3. Combine for the Marquee
            # Example:  "Mon: scattered clouds"

            full_text = "%s:%s" % (day_letter, desc)

            # Visual Style:
            # Make the first line (Today) bright white, others yellow

            color = ("#ffffff" if i == 0 else "#ffcc00")

            lines.append({
                "text": full_text,
                "temp": temp_str,
                "color": color,
            })

    # Render: 4 rows of 8px height

    return render.Root(child = render.Column(
        expanded = True,
        main_align = "start",
        children = [render_row(
            item["text"],
            item["temp"],
            item["color"],
        ) for item in lines],
    ))

def get_data(url):
    res = http.get(url, ttl_seconds = 3600)  # cache for 1 hour
    if res.status_code != 200:
        fail(
            "GET %s failed with status %d: %s",
            url,
            res.status_code,
            res.body(),
        )
    return res.json()

def render_row(text, temp, color):
    # Force exactly 8 pixels per row
    # Left Side: "M: description..."
    # Right Side: Temp "-2/4"
    return render.Box(
        width = 64,
        height = 8,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = 40,
                    delay = 100,
                    align = "start",
                    child = render.Text(
                        content = text,
                        font = "tom-thumb",
                        color = color,
                    ),
                ),
                render.Text(
                    content = temp,
                    font = "tom-thumb",
                    color = color,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [schema.Text(
        id = "appid",
        name = "Openweathermap",
        desc = "AppId",
        icon = "gear",
        default = "",
    ), schema.Text(
        id = "lat",
        name = "Latitude",
        desc = "Latitude",
        icon = "gear",
        default = "",
    ), schema.Text(
        id = "lon",
        name = "Longitude",
        desc = "Longitude",
        icon = "gear",
        default = "",
    )])

WEATHER_URL = \
    "https://api.openweathermap.org/data/3.0/onecall?lat=%s&lon=%s&exclude=current,minutely,hourly,alerts&appid=%s"
