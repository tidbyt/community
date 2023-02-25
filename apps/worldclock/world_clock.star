"""
Applet: World Clock
Summary: Multi timezone clock
Description: Displays the time in up to four different locations, now with temperature option
Author: Elliot Bentley

Note - the default API key listed is a free one which I registered for. It can do up to 1 million calls per month
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("sunrise.star", "sunrise")
load("time.star", "time")

WEATHER_API_URL_PREFIX = "https://api.weatherapi.com/v1/current.json?key="
CACHE_TTL_MINS = 30

WEATHER_API_SECRETKEY = "AV6+xWcET3luBTCeNzeQiLgXPdaj08p2ET8MAIC3U/FJea1tx1OTfy+7mDY7C1jnFu7vj0sv4DBS6Ky3sfmnR0+0bIy9UnXRs4GeEEQgMFkisABtmn2k9DD+yl+Gtg17qMQ1jQOHsgJFbSwUowVBtGHBhmKcmssDQVUTx0xakVfq/bSCXA=="
WEATHER_API_KEY = secret.decrypt(WEATHER_API_SECRETKEY)

number_font = "tom-thumb"
font = "tom-thumb"

def main(config):
    if (config.get("location_1")):
        locations = [
            json.decode(config.get("location_1")),
            json.decode(config.get("location_2")),
            json.decode(config.get("location_3")),
        ]
        if "location_4" in config:
            locations.append(json.decode(config.get("location_4")))
    else:
        locations = [
            {
                "timezone": "America/New_York",
                "locality": "New York",
                "lat": 0,
                "lng": 0,
            },
            {
                "timezone": "Europe/London",
                "locality": "London",
                "lat": 0,
                "lng": 0,
            },
            {
                "timezone": "Asia/Tokyo",
                "locality": "Tokyo",
                "lat": 35.703286,
                "lng": 139.748475,
            },
            {
                "timezone": "America/Sao_Paulo",
                "locality": "Sao Paulo",
                "lat": -23.55,
                "lng": -46.633333,
            },
        ]

    location_count = int(config.get("location_count") or 3)

    if location_count < 4 and len(locations) > 3:
        locations.remove(locations[3])

    if location_count < 3:
        locations.remove(locations[2])

    horizonal_rule = render.Box(
        height = 1,
        color = "#555",
    )

    rows = []

    TempFormat = config.get("temp_format", "C")
    DisplayTemp = ""

    i = 0
    for location in locations:
        i += 1

        timezone = location["timezone"]
        locality = config.get("location_%s_label" % i)
        useMeridianTime = 1 if config.bool("time_format") else 0
        if (not locality):
            locality = location["locality"]

        now = time.now().in_location(timezone)
        lat, lng = float(location["lat"]), float(location["lng"])
        rise = sunrise.sunrise(lat, lng, now)
        set = sunrise.sunset(lat, lng, now)
        is_daytime = now > rise and now < set

        time_color = "#bbbbbb"

        if (config.get("color_by_daylight") != "false"):
            if (is_daytime):
                time_color = "#ffe9ad"
            else:
                time_color = "#94a0ff"

        location_name = render.Box(
            height = 7,
            width = (43, 35)[useMeridianTime],
            child = render.Padding(
                pad = (4, 1, 0, 0),
                child = render.Marquee(
                    width = (43, 35)[useMeridianTime],
                    child = render.Text(
                        content = locality,
                        font = font,
                        color = time_color,
                        offset = 0,
                    ),
                ),
            ),
        )

        if TempFormat == "C" or TempFormat == "F":
            locality_str = locality.replace(" ", "%20")
            WEATHER_API_URL_FULL = WEATHER_API_URL_PREFIX + WEATHER_API_KEY + "&q=" + locality_str

            # Get the temperature from cache
            CacheTempC = cache.get(locality_str + "C")
            CacheTempF = cache.get(locality_str + "F")
            # '\u00b0'

            # if either cache is empty, get new temperatures (both C & F) and hold them for 30 mins
            if CacheTempC == None or CacheTempF == None:
                TempJSON = http.get(WEATHER_API_URL_FULL).json()
                TempC = TempJSON["current"]["temp_c"]
                TempC = humanize.float("##.", TempC) + "\u00b0" + "C"
                cache.set(locality_str + "C", TempC, ttl_seconds = 60 * CACHE_TTL_MINS)
                TempF = TempJSON["current"]["temp_f"]
                TempF = humanize.float("###.", TempF) + "\u00b0" + "F"
                cache.set(locality_str + "F", TempF, ttl_seconds = 60 * CACHE_TTL_MINS)

            # display cached temperatures for either C or F
            if TempFormat == "C":
                DisplayTemp = cache.get(locality_str + "C")
            elif TempFormat == "F":
                DisplayTemp = cache.get(locality_str + "F")

            location_temp = render.Box(
                width = (23, 30)[useMeridianTime],
                height = 7,
                child = render.Padding(
                    pad = (0, 1, 0, 0),
                    child = render.Row(
                        children = [
                            render.Box(
                                child = render.Animation(
                                    children = [
                                        render.Text(
                                            content = (now.format("15"), now.format("03"))[useMeridianTime] + ":" + (now.format("04"), now.format("04PM"))[useMeridianTime],
                                            font = number_font,
                                            color = "#ffffff",
                                        ),
                                        render.Text(
                                            content = DisplayTemp,
                                            font = number_font,
                                            color = "#ffffff",
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            )

            row = render.Row(
                main_align = "start",
                children = [
                    location_name,
                    location_temp,
                ],
            )

        else:
            location_time = render.Box(
                child = render.Padding(
                    pad = (0, 1, 0, 1),
                    child = render.Row(
                        children = [
                            render.Text(
                                content = (now.format("15"), now.format("03"))[useMeridianTime],
                                font = number_font,
                                color = "#ffffff",
                            ),
                            render.Box(
                                width = 2,
                                child = render.Animation(
                                    children = [
                                        render.Text(
                                            content = ":",
                                            font = "CG-pixel-3x5-mono",
                                            color = "#777777",
                                            offset = 0,
                                        ),
                                        render.Text(
                                            content = " ",
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                ),
                            ),
                            render.Text(
                                content = (now.format("04"), now.format("04PM"))[useMeridianTime],
                                font = number_font,
                                color = "#ffffff",
                            ),
                        ],
                    ),
                ),
                width = (23, 30)[useMeridianTime],
                height = 7,
            )

            row = render.Row(
                main_align = "start",
                children = [
                    location_name,
                    location_time,
                ],
            )

        rows.append(row)
        if (i < len(locations)):
            rows.append(horizonal_rule)

    return render.Root(
        delay = 2500,
        child = render.Column(
            children = rows,
            main_align = "space_around",
            expanded = True,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "location_count",
                name = "Number of clocks",
                desc = "How many locations to display onscreen.",
                icon = "list",
                default = "3",
                options = [
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
                ],
            ),
            schema.Location(
                id = "location_1",
                name = "Location 1",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "location_1_label",
                name = "Location 1 label",
                desc = "Custom label (optional)",
                icon = "tag",
                default = "",
            ),
            schema.Location(
                id = "location_2",
                name = "Location 2",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "location_2_label",
                name = "Location 2 label",
                desc = "Custom label (optional)",
                icon = "tag",
                default = "",
            ),
            schema.Location(
                id = "location_3",
                name = "Location 3",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "location_3_label",
                name = "Location 3 label",
                desc = "Custom label (optional)",
                icon = "tag",
                default = "",
            ),
            schema.Location(
                id = "location_4",
                name = "Location 4",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "location_4_label",
                name = "Location 4 label",
                desc = "Custom label (optional)",
                icon = "tag",
                default = "",
            ),
            schema.Toggle(
                id = "time_format",
                name = "Time Format",
                desc = "Format time as 12H clock instead of 24H",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "color_by_daylight",
                name = "Color by daylight",
                desc = "Adjust location name color based on time of day.",
                icon = "sun",
                default = True,
            ),
            schema.Dropdown(
                id = "temp_format",
                name = "Show Temperature",
                desc = "Off, Celsius or Fahrenheit",
                icon = "temperatureHigh",
                default = "Off",
                options = [
                    schema.Option(
                        display = "Off",
                        value = "Off",
                    ),
                    schema.Option(
                        display = "Celsius",
                        value = "C",
                    ),
                    schema.Option(
                        display = "Fahrenheit",
                        value = "F",
                    ),
                ],
            ),
        ],
    )
