"""
Applet: Islamic Prayer
Summary: Islamic Prayer Times
Description: Shows the daily Islamic prayer times for a given location.
Author: Austin Fonacier
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = {
    "lat": 34.0522,
    "lng": -118.2437,
    "locality": "Los Angeles",
    "timezone": "US/Pacific",
}
DEVICE_WIDTH = 64
DEVICE_HEIGHT = 32
ONE_MONTH = 604800
FONT = "CG-pixel-3x5-mono"
COLOR_0 = "#819121"
COLOR_1 = "#f48c94"
COLOR_2 = "#fbc362"
COLOR_3 = "#b23e21"
COLOR_4 = "#6cad54"
COLOR_5 = "#a3ccc8"
COLOR_6 = "#d2baaf"
COLOR_7 = "#a17e4b"
COLOR_8 = "#3c5453"
ALL_COLORS = [COLOR_0, COLOR_1, COLOR_2, COLOR_3, COLOR_4, COLOR_5, COLOR_6, COLOR_7, COLOR_8]

def main(config):
    loc = location(config)
    latitude = loc["lat"]
    longitude = loc["lng"]
    prayer_calc_option = config.get("prayer_calc_options")
    show_sunrise = config.bool("show_sunrise", False)
    non_color_mode = config.bool("non_color", False)
    now = time.now().in_location(loc["timezone"])
    day = now.day
    month = now.month
    year = now.year

    prayer_timings = get_prayer_for_the_day(latitude, longitude, day, month, year, show_sunrise, prayer_calc_option)

    return render.Root(
        delay = int(config.str("speed", "70")),
        child = render.Column(
            children = [
                render_top_column(day, month, year),
                # render.Box(
                render.Animation(
                    children = get_render_frames(prayer_timings, show_sunrise, non_color_mode),
                ),
                # )
            ],
        ),
    )

def location(config):
    location = config.get("location")
    return json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))

def get_table_of_prayer_times(prayer_timings, non_color_mode):
    column_children = []
    counter = 0
    for prayer_and_time in prayer_timings:
        time = prayer_and_time[1]
        prayer = prayer_and_time[0]
        time_no_zone = time.split(" ")[0]  # 21:00 PDT -> 21:00
        column_children.append(render_individual_prayer_time(prayer, time_no_zone, counter, non_color_mode))
        counter = counter + 1
        column_children.append(render.Box(width = 1, height = 1))

    return render.Column(
        children = column_children,
    )

def get_render_frames(prayer_timings, show_sunrise, non_color_mode):
    children = []

    # 60 frames of it at the top so people can read before scrolling
    for offset in range(35):
        children.append(
            render.Padding(
                pad = (0, 0, 0, 0),
                child = get_table_of_prayer_times(prayer_timings, non_color_mode),
            ),
        )

    scroll_depth = 12
    if show_sunrise:
        scroll_depth = 18

    for offset in range(scroll_depth):
        children.append(
            render.Padding(
                pad = (0, -offset, 0, 0),
                child = get_table_of_prayer_times(prayer_timings, non_color_mode),
            ),
        )

    for offset in range(35):
        children.append(
            render.Padding(
                pad = (0, -scroll_depth, 0, 0),
                child = get_table_of_prayer_times(prayer_timings, non_color_mode),
            ),
        )

    return children

def render_individual_prayer_time(k, v, counter, non_color_mode):
    children = []
    current_color = ALL_COLORS[counter]
    if non_color_mode:
        current_color = "#FFF"
    children.append(render.Box(width = 2, height = 5, color = current_color))
    children.append(render.Box(width = 2, height = 5))
    children.append(render.Text("{} {}".format(k, v), font = FONT, color = current_color))
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = children,
    )

def render_top_column(day, month, year):
    return render.Row(
        children = [
            render.Text("Prayer Times {}/{}".format(day, month, year), font = FONT),
        ],
    )

# Returns a list of tuples
# of all the prayers and times
def get_prayer_for_the_day(latitude, longitude, day, month, year, show_sunrise, prayer_calc_option):
    matched_entry = {}

    # Truncate latitude and longitude to protect the users privacy,
    # by not leaking their exact location to a third-party API.
    lat_truncate = humanize.float("#.##", float(latitude))
    lng_truncate = humanize.float("#.##", float(longitude))
    prayer_month_parsed = fetch_prayer_times(lat_truncate, lng_truncate, month, year, prayer_calc_option)

    # TODO error handling?
    day_str = day_to_str(day)

    # the API returns the whole month.  So we just need to find today.
    for entry in prayer_month_parsed["data"]:
        # returns the whole month.  So let's find today
        if entry["date"]["gregorian"]["day"] == day_str:
            matched_entry = entry
            break

    return prayer_timings_filter(matched_entry["timings"], show_sunrise)

# Return a list of Tuples
# We only care about: fajr, Dhuhr, asr, maghrib, isha
# Additionally if `show_sunrise` is set we can add that.
def prayer_timings_filter(pre_filtered_timings, show_sunrise):
    filtered_prayer_times = [
        ("Fajr", pre_filtered_timings["Fajr"]),
    ]

    if show_sunrise:
        filtered_prayer_times.append(("Sunrise", pre_filtered_timings["Sunrise"]))

    # the rest
    for prayer in ["Dhuhr", "Asr", "Maghrib", "Isha"]:
        filtered_prayer_times.append((prayer, pre_filtered_timings[prayer]))

    return filtered_prayer_times

def fetch_prayer_times(latitude, longitude, month, year, prayer_calc_option):
    cache_key = "prayer_{}/{}".format(month, year)

    cached_data = cache.get(cache_key)

    if cached_data == None:
        # API docs: https://aladhan.com/prayer-times-api#GetCalendar
        api_url = "http://api.aladhan.com/v1/calendar?latitude={}&longitude={}&month={}&year={}&method={}".format(latitude, longitude, month, year, prayer_calc_option)
        prayer_month_raw = http.get(api_url)
        prayer_month_body = prayer_month_raw.body()
        cache.set(cache_key, prayer_month_body, ttl_seconds = ONE_MONTH)
        cached_data = prayer_month_body

    return json.decode(cached_data)

# Helper function for: 4 -> 04
def day_to_str(day):
    if day < 10:
        return "0{}".format(str(day))
    else:
        return str(day)

def get_prayer_calculation_options():
    return [
        schema.Option(
            display = "University of Islamic Sciences, Karachi",
            value = "1",
        ),
        schema.Option(
            display = "Islamic Society of North America",
            value = "2",
        ),
        schema.Option(
            display = "Muslim World League",
            value = "3",
        ),
        schema.Option(
            display = "Umm Al-Qura University, Makkah",
            value = "4",
        ),
        schema.Option(
            display = "Egyptian General Authority of Survey",
            value = "5",
        ),
        schema.Option(
            display = "Institute of Geophysics, University of Tehran",
            value = "7",
        ),
        schema.Option(
            display = "Gulf Region",
            value = "8",
        ),
        schema.Option(
            display = "Kuwait",
            value = "9",
        ),
        schema.Option(
            display = "Qatar",
            value = "10",
        ),
        schema.Option(
            display = "Majlis Ugama Islam Singapura, Singapore",
            value = "11",
        ),
        schema.Option(
            display = "Union Organization islamic de France",
            value = "12",
        ),
        schema.Option(
            display = "Diyanet İşleri Başkanlığı, Turkey",
            value = "13",
        ),
        schema.Option(
            display = "Spiritual Administration of Muslims of Russia",
            value = "14",
        ),
        # schema.Option(
        #     display = "Moonsighting Committee Worldwide", # requires shafaq paramteer
        #     value = 15,
        # ),
    ]

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slower", value = "100"),
        schema.Option(display = "Slow", value = "70"),
        schema.Option(display = "Normal", value = "50"),
        schema.Option(display = "Fast (Default)", value = "30"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display times",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll Speed",
                desc = "How fast do you want to scroll?",
                icon = "gear",
                default = scroll_speed[1].value,
                options = scroll_speed,
            ),
            schema.Toggle(
                id = "non_color",
                name = "Make the text non colored",
                desc = "Make the text non colored for people that want things a little more readable",
                icon = "fillDrip",
                default = False,
            ),
            schema.Toggle(
                id = "show_sunrise",
                name = "Show Sunrise Time",
                desc = "Whether to show sunrise time",
                icon = "sun",
                default = False,
            ),
            schema.Dropdown(
                id = "prayer_calc_options",
                name = "Prayer Calculation Method",
                desc = "A prayer times calculation method. Methods identify various schools of thought about how to compute the timings. ",
                icon = "mosque",
                default = "default",
                options = get_prayer_calculation_options(),
            ),
        ],
    )
