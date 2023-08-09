"""
Applet: Prayer Times
Summary: Islamic Prayer Time Display
Description: Displays the prayer times for today's date and also shows the remaining time till the next prayer based on the user's location.
Author: EslamMoh
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Adhan prayer API URL
PRAYER_TIME_BASE_URL = "http://api.aladhan.com/v1/timings/"

# Load Moon icon from base64 encoded data
MOON_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBUeOG9t+GkAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAATElEQVQoz2NkYGD4z0AiYGIgA7BgE/z/2hrOZhQ9StgmZA3Y+Bg2EbIBwyZiNZ
AdEJRpQnYSNs8jA0b0yMWmAd2PTIQUYAsURrolIwA2fBgZWqCnTgAAAABJRU5ErkJggg==
""")

# Load Sun icon from base64 encoded data
SUN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBQ5HxFglVAAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAYUlEQVQoz2NgYGD4jw3/f239H5ccEwMDA8P/19YMxABkdQRNRpdnhDJwmsgoeh
TDRiZ8GnA5nYmQAmziLDABbM7ApZmFGMXo/mPCJohLMc6AQFeAyyCS44kBlwYCYqSnPQAb
5W9EvIXnIQAAAABJRU5ErkJggg==
""")

# Default location and timezone data for prayer
DEFAULT_LOCATION = """
{
    "timezone": "Asia/Riyadh",
    "lat": "24.7136",
	"lng": "46.6753"
}
"""

# Default method of calculating prayer time
DEFAULT_METHOD = "4"

# Mapping current prayer to the matching icon
PRAYER_ICON = {
    "sunrise": SUN_ICON,
    "duhr": SUN_ICON,
    "asr": SUN_ICON,
    "maghrib": MOON_ICON,
    "isha": MOON_ICON,
    "fajr": MOON_ICON,
}

# Cache prayer times request for one day.
TTL_CACHE = 86400

# Fetch location configs
def get_location(config):
    location = config.get("location", DEFAULT_LOCATION)
    return json.decode(location)

# Fetch method of calculation for prayer time config
def get_method(config):
    return config.get("method", DEFAULT_METHOD)

def main(config):
    location = get_location(config)
    method = get_method(config)
    now = time.now().in_location(location["timezone"])
    date = now.format("2-01-2006")

    # Fetch today prayer times
    prayers = get_prayers(date, location, method)

    # Calculate the next prayer based on the current time
    next_prayer = next_prayer_time(prayers, now, location, method)

    # Get the current prayer name
    current_prayer = current_prayer_name(next_prayer["prayer"])

    return render.Root(
        delay = 2000,
        max_age = 60,
        child = render.Column(
            children = [
                render.Sequence(children = [
                    animation.Transformation(
                        child = render.Row(children = [
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (7, 17, 0, 0),
                                        child = render.Box(
                                            width = 17,
                                            height = 7,
                                            color = current_prayer_color("fajr", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "FAJR",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 15,
                                                color = current_prayer_color("fajr", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (5, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Fajr"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (30, 17, 0, 0),
                                        child = render.Box(
                                            width = 29,
                                            height = 7,
                                            color = current_prayer_color("sunrise", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "sunrise",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 27,
                                                color = current_prayer_color("sunrise", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (34, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Sunrise"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                ] + render_meta_data(PRAYER_ICON[current_prayer], next_prayer),
                            ),
                        ]),
                        duration = 1,
                        keyframes = keyframes(0),
                    ),
                    animation.Transformation(
                        child = render.Row(children = [
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (7, 17, 0, 0),
                                        child = render.Box(
                                            width = 17,
                                            height = 7,
                                            color = current_prayer_color("duhr", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "Duhr",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 15,
                                                color = current_prayer_color("duhr", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (5, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Dhuhr"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (38, 17, 0, 0),
                                        child = render.Box(
                                            width = 13,
                                            height = 7,
                                            color = current_prayer_color("asr", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "Asr",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 11,
                                                color = current_prayer_color("asr", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (34, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Asr"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                ] + render_meta_data(PRAYER_ICON[current_prayer], next_prayer),
                            ),
                        ]),
                        duration = 1,
                        keyframes = keyframes(64),
                    ),
                    animation.Transformation(
                        child = render.Row(children = [
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (5, 17, 0, 0),
                                        child = render.Box(
                                            width = 29,
                                            height = 7,
                                            color = current_prayer_color("maghrib", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "MAGHRIB",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 26,
                                                color = current_prayer_color("maghrib", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (8, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Maghrib"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (42, 17, 0, 0),
                                        child = render.Box(
                                            width = 16,
                                            height = 7,
                                            color = current_prayer_color("isha", current_prayer)["box_color"],
                                            child = render.WrappedText(
                                                content = "ISHA",
                                                font = "CG-pixel-3x5-mono",
                                                align = "left",
                                                width = 16,
                                                color = current_prayer_color("isha", current_prayer)["font_color"],
                                            ),
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (40, 24, 0, 0),
                                        child = render.Box(
                                            width = 22,
                                            height = 8,
                                            child = render.WrappedText(
                                                content = prayers["Isha"],
                                                align = "left",
                                                width = 22,
                                            ),
                                        ),
                                    ),
                                ] + render_meta_data(PRAYER_ICON[current_prayer], next_prayer),
                            ),
                        ]),
                        duration = 1,
                        keyframes = keyframes(64),
                    ),
                ]),
            ],
        ),
    )

def render_time_icon(icon):
    return render.Padding(
        pad = (0, 0, 0, 0),
        child = render.Image(
            src = icon,
        ),
    )

def render_line_separator():
    return render.Padding(
        pad = (0, 16, 0, 0),
        child = render.Box(
            width = 64,
            height = 1,
            color = "#f00",
        ),
    )

def render_next_prayer_time(next_prayer):
    return {
        "name": render.Padding(
            pad = (20, 1, 0, 0),
            child = render.Box(
                width = 28,
                height = 7,
                child = render.WrappedText(
                    content = next_prayer["prayer"],
                    font = "CG-pixel-3x5-mono",
                    color = "#228B22",
                    align = "left",
                ),
            ),
        ),
        "time": render.Padding(
            pad = (12, 5, 0, 0),
            child = render.Box(
                width = 50,
                height = 15,
                child = render.WrappedText(
                    content = next_prayer["time"],
                    font = "CG-pixel-3x5-mono",
                    linespacing = 1,
                    align = "left",
                ),
            ),
        ),
    }

# Format prayer times in DateTime format
def formatted_prayer_times(prayers, now, timezone):
    return {
        "fajr": format_time(prayers["Fajr"], now, timezone),
        "sunrise": format_time(prayers["Sunrise"], now, timezone),
        "duhr": format_time(prayers["Dhuhr"], now, timezone),
        "asr": format_time(prayers["Asr"], now, timezone),
        "maghrib": format_time(prayers["Maghrib"], now, timezone),
        "isha": format_time(prayers["Isha"], now, timezone),
    }

# Format time from "HH:MM" to DateTime format
def format_time(prayer, now, timezone):
    p = prayer.partition(":")

    return time.time(year = now.year, month = now.month, day = now.day, hour = int(p[0]), minute = int(p[2]), second = 0o0, location = timezone)

# Calculate next prayer time based on the current time
def next_prayer_time(prayers, now, location, method):
    pt = formatted_prayer_times(prayers, now, location["timezone"])

    if (now > pt["fajr"]) and (now < pt["sunrise"]):
        return {"prayer": "sunrise", "time": time_till_next_prayer(now, pt["sunrise"])}

    elif (now > pt["sunrise"]) and (now < pt["duhr"]):
        return {"prayer": "duhr", "time": time_till_next_prayer(now, pt["duhr"])}

    elif (now > pt["duhr"]) and (now < pt["asr"]):
        return {"prayer": "asr", "time": time_till_next_prayer(now, pt["asr"])}

    elif (now > pt["asr"]) and (now < pt["maghrib"]):
        return {"prayer": "maghrib", "time": time_till_next_prayer(now, pt["maghrib"])}

    elif (now > pt["maghrib"]) and (now < pt["isha"]):
        return {"prayer": "isha", "time": time_till_next_prayer(now, pt["isha"])}

    elif (pt["isha"] < now) and (now <= (format_time("23:59", now, location["timezone"]))):  # Get the next prayer time in case the current time is between Isha time and midnight
        # Get Fajr prayer time for tomorrow date
        tomorrow_fajr = get_tomorrow_fajr(now, location, method)

        return {"prayer": "fajr", "time": time_till_next_prayer(now, tomorrow_fajr)}

    elif (now < pt["fajr"]):  # Get the next prayer time in case current time is between Midnight and Fajr time.
        return {"prayer": "fajr", "time": time_till_next_prayer(now, pt["fajr"])}

    else:
        fail("Failed to calculate the remaining time till the next prayer")

# Get Fajr prayer time for tomorrow date.
def get_tomorrow_fajr(now, location, method):
    tomorrow = now + 24 * time.hour
    tomorrow_date = tomorrow.format("2-01-2006")
    tomorrow_prayers = get_prayers(tomorrow_date, location, method)
    return format_time(tomorrow_prayers["Fajr"], tomorrow, location["timezone"])

# Send API request to get prayer times according to location and date.
def get_prayers(date, location, method):
    url = PRAYER_TIME_BASE_URL + date + "?latitude=%s" % (location["lat"]) + "&longitude=%s" % (location["lng"]) + "&method=%s" % (method)
    rep = http.get(url, ttl_seconds = TTL_CACHE)

    if rep.status_code != 200:
        fail("Prayer Time request failed with status %d", rep.status_code)

    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Prayer Times API.")

    return rep.json()["data"]["timings"]

# Render time icon, next prayer times data and separation line.
def render_meta_data(icon, next_prayer):
    return [
        render_time_icon(icon),
        render_line_separator(),
        render_next_prayer_time(next_prayer)["name"],
        render_next_prayer_time(next_prayer)["time"],
    ]

# Animate prayers frames based on x axis input.
def keyframes(x):
    return [
        animation.Keyframe(
            percentage = 0.0,
            transforms = [animation.Translate(x, 0)],
            curve = "linear",
        ),
        animation.Keyframe(
            percentage = 1.0,
            transforms = [animation.Translate(-64, 0)],
            curve = "linear",
        ),
    ]

# Pick the highlight color for the current prayer.
def current_prayer_color(prayer_name, current_prayer):
    if current_prayer == prayer_name:
        return {"box_color": "#F4C430", "font_color": "#000000"}
    else:
        return {"box_color": "#000000", "font_color": "#FFFFFF"}

# Calculate the remaining time till the next prayer time.
def time_till_next_prayer(now, nxt_pryr_time):
    remaining_time = nxt_pryr_time - now
    hours = int(remaining_time.hours)
    mins = int(remaining_time.minutes) % 60

    return "%shrs %smins" % (hours, mins)

# Get the current prayer time based on the next prayer time name.
def current_prayer_name(next_prayer):
    return {
        "sunrise": "fajr",
        "duhr": "sunrise",
        "asr": "duhr",
        "maghrib": "asr",
        "isha": "maghrib",
        "fajr": "isha",
    }[next_prayer]

def get_schema():
    method_options = [
        schema.Option(
            display = "Shia Ithna-Ansari",
            value = "0",
        ),
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
        schema.Option(
            display = "Moonsighting Committee Worldwide (also requires shafaq parameter)",
            value = "15",
        ),
        schema.Option(
            display = "Dubai (unofficial)",
            value = "16",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display prayer times",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "method",
                name = "Prayer Calculation Method",
                desc = "A prayer times calculation method. Methods identify various schools of thought about how to compute the timings. If not specified, it defaults to Umm Al-Qura University, Makkah",
                icon = "mosque",
                default = "4",
                options = method_options,
            ),
        ],
    )
