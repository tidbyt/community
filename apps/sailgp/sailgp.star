"""
Applet: SailGP
Summary: Sail GP Race and Leaders
Description: Sail GP Next Race Info and Current Leaderboard.
Author: jvivona
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23170

DEFAULTS = {
    "display": "nri",
    "timezone": "America/New_York",
    "time_24": False,
    "date_us": True,
    "api": "https://tidbyt.apis.ajcomputers.com/indy/api/{}/{}.json",
    "ttl": 1800,
    "positions": 16,
    "text_color": "#FFFFFF",
    "regular_font" : "tom-thumb"
}


def main(config):
    timezone = config.get("$tz", DEFAULTS["timezone"])  # Utilize special timezone variable to get TZ - otherwise assume US Eastern w/DST
    
    date_and_time_first = "2023-07-22T16:00-07:00"
    date_and_time_second = "2023-07-23T17:30-07:00"
    date_and_time_first_dt = time.parse_time(date_and_time_first, "2006-01-02T15:04-07:00").in_location(timezone)
    date_and_time_second_dt = time.parse_time(date_and_time_second, "2006-01-02T15:04-07:00").in_location(timezone)

    date_time_format = date_and_time_first_dt.format("Jan 02-") + date_and_time_second_dt.format("02 2006") if config.bool("is_us_date_format", DEFAULTS["date_us"]) else date_and_time_first_dt.format("02-") + date_and_time_second_dt.format("02 Jan 2006")

    #series = config.get("series", DEFAULTS["series"])
    #displaytype = config.get("datadisplay", DEFAULTS["display"])
    #data = json.decode(get_cachable_data(DEFAULTS["api"].format(series, displaytype)))
    #if displaytype == "nri":
    #    displayrow = nextrace(config, data)
    #else:
    #    displayrow = standings(config, data)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Text("Sail GP", font = "tom-thumb"),
                    color = "#0a2627",
                ),
                render.WrappedText("Mubadala New York SailGP", font = DEFAULTS["regular_font"], color = DEFAULTS["text_color"]),
                render.Text(date_time_format, font = DEFAULTS["regular_font"], color = DEFAULTS["text_color"]),
                render.Marquee(offset_start = 48, child = render.Text(height = 6, content = "1. AUS (10)   2. NZL (9)   3. CAN (8)   4. USA (6)   5. GBR (5)   6. NED (4)   7. GER (3)", font = DEFAULTS["regular_font"], color = DEFAULTS["text_color"]), scroll_direction = "horizontal", width = 64),
                #displayrow,
            ],
        ),
    )


# ##############################################
#           Schema Funcitons
# ##############################################

dispopt = [
    schema.Option(
        display = "Next Race",
        value = "nri",
    ),
    schema.Option(
        display = "Standings with Flags",
        value = "standings",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "datadisplay",
                name = "Display Type",
                desc = "What data to display?",
                icon = "eye",
                default = "nri",
                options = dispopt,
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "The color for Standings / Race / Track / Time text.",
                icon = "palette",
                default = DEFAULTS["text_color"],
            ),
            schema.Generated(
                id = "nri_generated",
                source = "datadisplay",
                handler = show_nri_options,
            ),
        ],
    )

def show_nri_options(datadisplay):
    if datadisplay == "nri":
        return [
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = DEFAULTS["time_24"],
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format.",
                icon = "calendarDays",
                default = DEFAULTS["date_us"],
            ),
        ]
    else:
        return []




# ##############################################
#           General Funcitons
# ##############################################
def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = DEFAULTS["ttl"])
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def text_justify_trunc(length, text, direction):
    #  thanks to @inxi and @whyamihere / @rs7q5 for the codepoints() and codepoints_ords() help
    chars = list(text.codepoints())
    textlen = len(chars)

    # if string is shorter than desired - we can just use the count of chars (not bytes) and add on spaces - we're good
    if textlen < length:
        for _ in range(0, length - textlen):
            text = " " + text if direction == "right" else text + " "
    else:
        # text is longer - need to trunc it get the list of characters & trunc at length
        text = ""  # clear out text
        for i in range(0, length):
            text = text + chars[i]

    return text