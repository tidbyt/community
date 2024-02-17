"""
Applet: Sun And Moon
Summary: Sun and Moon data
Description: Displays Sun and Moon rise/set times for user's location.
Author: Ben Boatwright
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SUNRISE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAAXNSR0IArs4c6QAAACZJREFUGFdjZICC//8Z/sPYjIwMjHA2iIEsia4IrJJyBeimILsBAFfjDwbCAc9RAAAAAElFTkSuQmCC
""")

SUNSET_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAAXNSR0IArs4c6QAAAC1JREFUGFdjZCAAGGHy/1cx/IexGcMY4OJgBrIkuiLCChoaGuBGozunoaGBEQB2xQ0Gc3yMuwAAAABJRU5ErkJggg==
""")

MOONRISE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAAXNSR0IArs4c6QAAAC1JREFUGFdjZEAC///v/8/I6MiILIbCASkASSIrQlEAkkQ3hTgTYEajGw/iAwCjXhQGmq+bBgAAAABJRU5ErkJggg==
""")

MOONSET_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAAXNSR0IArs4c6QAAADBJREFUGFdjZCAAGJHl/19l+M+ozYAihqEApAFZEYoCkCS6KYwNDQ3/cTmjoaGBEQA91Q0GLMg8ZAAAAABJRU5ErkJggg==
""")

DEFAULT_LOCATION = {
    "lat": 34.05,
    "lng": -118.25,
    "locality": "Los Angeles",
}
DEFAULT_TIMEZONE = "US/Pacific"

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )
    lat = humanize.float("##.##", loc.get("lat"))
    lon = humanize.float("###.##", loc.get("lng"))
    now = time.now().in_location(timezone)
    today = now.format("2006-01-02")

    utcoffset = now.format("-07")
    if utcoffset == "+00":
        utcfmt = "+0"
    else:
        utcoffset_nozero = re.split("0", utcoffset)
        utcfmt = utcoffset_nozero[0] + utcoffset_nozero[1]

    apiurl = "https://aa.usno.navy.mil/api/rstt/oneday?date=" + today + "&coords=" + lat + "," + lon + "&tz=" + utcfmt

    # print(apiurl)
    res = http.get(apiurl)
    apidata = res.json()

    sr = "--:--"
    ss = "--:--"
    mr = "--:--"
    ms = "--:--"

    for i in range(0, 4):
        phen = apidata["properties"]["data"]["sundata"][i]["phen"]
        if phen == "Object continuously below the Horizon":
            break
        if phen == "Object continuously above the Horizon":
            break
        if phen == "Rise":
            sr = apidata["properties"]["data"]["sundata"][i]["time"]
        if phen == "Set":
            ss = apidata["properties"]["data"]["sundata"][i]["time"]

    for j in range(0, 2):
        phen = apidata["properties"]["data"]["moondata"][j]["phen"]
        if phen == "Object continuously below the Horizon":
            break
        if phen == "Object continuously above the Horizon":
            break
        if phen == "Rise":
            mr = apidata["properties"]["data"]["moondata"][j]["time"]
        if phen == "Set":
            ms = apidata["properties"]["data"]["moondata"][j]["time"]

    if config.bool("timefmt"):
        time_array = [sr, ss, mr, ms]
        for t in range(0, 4):
            if time_array[t] != "--:--":
                tparse = time.parse_time(time_array[t], "15:04", timezone)
                ampm = tparse.format("PM")
                if ampm == "PM":
                    time_array[t] = tparse.format("3:04") + "P"
                else:
                    time_array[t] = tparse.format("3:04") + "A"
        sr = time_array[0]
        ss = time_array[1]
        mr = time_array[2]
        ms = time_array[3]

    # print(time_array,t)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = 32,
                            height = 10,
                            child = render.Row(
                                expanded = True,
                                main_align = "start",
                                cross_align = "center",
                                children = [
                                    render.Image(src = SUNRISE_ICON),
                                    render.Text(content = sr, font = "tom-thumb"),
                                ],
                            ),
                        ),
                        render.Box(
                            width = 32,
                            height = 10,
                            child = render.Row(
                                expanded = True,
                                main_align = "start",
                                cross_align = "center",
                                children = [
                                    render.Image(src = MOONRISE_ICON),
                                    render.Text(content = mr, font = "tom-thumb"),
                                ],
                            ),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 32,
                            height = 10,
                            child = render.Row(
                                expanded = True,
                                main_align = "start",
                                cross_align = "center",
                                children = [
                                    render.Image(src = SUNSET_ICON),
                                    render.Text(content = ss, font = "tom-thumb"),
                                ],
                            ),
                        ),
                        render.Box(
                            width = 32,
                            height = 10,
                            child = render.Row(
                                expanded = True,
                                main_align = "start",
                                cross_align = "center",
                                children = [
                                    render.Image(src = MOONSET_ICON),
                                    render.Text(content = ms, font = "tom-thumb"),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "timefmt",
                name = "AM/PM",
                desc = "Toggle between AM/PM and 24-hr time display.",
                icon = "clock",
                default = True,
            ),
        ],
    )
