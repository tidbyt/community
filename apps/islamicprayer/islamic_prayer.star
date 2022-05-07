"""
Applet: Islamic Prayer
Summary: Islamic Prayer Times
Description: Shows the daily Islamic prayer times for a given location.
Author: Austin Fonacier
"""

load("render.star", "render")
load("schema.star", "schema")
load("animation.star", "animation")
load("time.star", "time")
load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")

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
COLOR_0 = "#3c5453"
COLOR_1 = "#572824"
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
    now = time.now().in_location(loc["timezone"])
    day = now.day
    month = now.month
    year = now.year

    prayer_timings = get_prayer_for_the_day(latitude, longitude, day, month, year, prayer_calc_option)

    return render.Root(
        delay = 5,
        child = render.Column(
            children = [
                render_top_column(day, month, year),
                # render.Box(
                render.Animation(
                    children = get_render_frames(prayer_timings),
                ),
                # )
            ],
        ),
    )

def location(config):
    location = config.get("location")
    return json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))

def timezone(config):
    return location(config)["timezone"]

def get_table_of_prayer_times(prayer_timings):
    column_children = []
    counter = 0
    for k, v in prayer_timings.items():
        v = v.split(" ")[0]
        column_children.append(render_individual_prayer_time(k, v, counter))
        counter = counter + 1
        column_children.append(render.Box(width = 1, height = 1))

    return render.Column(
        children = column_children,
    )

def get_render_frames(prayer_timings):
    children = []
    counter = 0

    # start the scroll below
    for offset in reversed(range(28)):
        children.append(
            render.Padding(
                pad = (0, offset, 0, 0),
                child = get_table_of_prayer_times(prayer_timings),
            ),
        )

    # end above
    for offset in range(30):
        children.append(
            render.Padding(
                pad = (0, -offset, 0, 0),
                child = get_table_of_prayer_times(prayer_timings),
            ),
        )

    return children

def render_individual_prayer_time(k, v, counter):
    children = []
    children.append(render.Box(width = 2, height = 5, color = ALL_COLORS[counter]))
    children.append(render.Box(width = 2, height = 5))
    children.append(render.Text("{} {}".format(k, v), font = FONT, color = ALL_COLORS[counter]))
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

def get_prayer_for_the_day(latitude, longitude, day, month, year, prayer_calc_option):
    matched_entry = {}
    prayer_month_parsed = fetch_prayer_times(latitude, longitude, day, month, year, prayer_calc_option)

    # TODO error handling?
    day_str = day_to_str(day)

    # the API returns the whole month.  So we just need to find today.
    for entry in prayer_month_parsed["data"]:
        # print(entry['date']['gregorian']['day'])
        # returns the whole month.  So let's find today
        if entry["date"]["gregorian"]["day"] == day_str:
            matched_entry = entry
            break

    #    "timings": {
    #        "Fajr": "03:57",
    #        "Sunrise": "05:46",
    #        "Dhuhr": "12:59",
    #        "Asr": "16:55",
    #        "Sunset": "20:12",
    #        "Maghrib": "20:12",
    #        "Isha": "22:02",
    #        "Imsak": "03:47",
    #        "Midnight": "00:59"
    #    },
    return matched_entry["timings"]

def fetch_prayer_times(latitude, longitude, day, month, year, prayer_calc_option):
    cache_key = "prayer_{}/{}".format(month, year)

    cached_data = cache.get(cache_key)
    print(cached_data)
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
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display times",
                icon = "place",
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
