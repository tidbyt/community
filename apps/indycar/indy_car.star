"""
Applet: Indy Car
Summary: Indy Car Race & Standings
Description: Show Indy Car next race info and current driver standings. - F1 Next Race from AMillionAir was the original inspiration for my race apps.  Track images by @samhi113.
Author: jvivona
"""

# 20230407  v23097
#  changed to new color schema option
#  samhi113 provided all the track images
# 20230826 jvivona  v23238
#  add qualifing date/time to json on server for NRI
#  add display of qualifing date/time on app
# 20230904 jvivona
#  fix date display remove leading 0
# 20230911 - jvivona - update code and API to better handle end of season with not upcoming race
# 20230927 - jvivona - thanks to @samhi113 for additional 2024 tracks
#  - move data and track images to github instead of our datacenter
#  - fixed some notes and inline documentation to actually match the code
# 20231108 - jvivona - cleanup some code in for loops

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23311

DEFAULTS = {
    "series": "car",
    "display": "nri",
    "timezone": "America/New_York",
    "time_24": False,
    "date_us": True,
    "api": "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/indycar/{}/{}.json",
    "ttl": 1800,
    "trackttl": 86400,
    "positions": 12,
    "text_color": "#FFFFFF",
}

SIZES = {
    "regular_font": "tom-thumb",
    "datetime_font": "tom-thumb",
    "animation_frames": 30,
    "animation_hold_frames": 75,
    "data_box_bkg": "#000",
    "slide_duration": 99,
    "nri_data_box_width": 48,
    "drv_data_box_width": 64,
    "data_box_height": 26,
    "title_box_width": 64,
    "title_box_height": 7,
}

SERIES = {
    "car": ["NTT Indycar", "#0086bf80"],
    "nxt": ["Indy NXT Series", "#da291c80"],
}

def main(config):
    series = config.get("series", DEFAULTS["series"])
    displaytype = config.get("datadisplay", DEFAULTS["display"])
    data = json.decode(get_cachable_data(DEFAULTS["api"].format(series, displaytype)))

    if displaytype == "nri":
        if data.get("start", "") == "":
            return []
        else:
            displayrow = nextrace(config, data)
    else:
        displayrow = standings(config, data)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Text(SERIES[series][0], font = "tom-thumb"),
                    color = SERIES[series][1],
                ),
                displayrow,
            ],
        ),
    )

# ##############################################
#            Next Race  Functions
# ##############################################
def nextrace(config, data):
    IMAGES = json.decode(get_cachable_data(DEFAULTS["api"].format("tracks", "tracks"), DEFAULTS["trackttl"]))
    timezone = config.get("$tz", DEFAULTS["timezone"])  # Utilize special timezone variable to get TZ - otherwise assume US Eastern w/DST
    date_and_time = data["start"]
    date_and_time3 = time.parse_time(date_and_time, "2006-01-02T15:04:05-0700").in_location(timezone)
    date_str = date_and_time3.format("Jan 2" if config.bool("is_us_date_format", DEFAULTS["date_us"]) else "2 Jan").title()  #current format of your current date str
    time_str = "TBD" if date_and_time.endswith("T00:00:00-0500") else date_and_time3.format("15:04 " if config.bool("is_24_hour_format", DEFAULTS["time_24"]) else "3:04pm")[:-1]
    if data.get("qual", "TBD") == "TBD":
        qual_date_str = "TBD"
        qual_time_str = "TBD"
    else:
        qual_date_and_time = data.get("qual", "TBD")
        qual_date_and_time3 = time.parse_time(qual_date_and_time, "2006-01-02T15:04:05-0700").in_location(timezone)
        qual_date_str = qual_date_and_time3.format("Jan 2" if config.bool("is_us_date_format", DEFAULTS["date_us"]) else "2 Jan").title()  #current format of your current date str
        qual_time_str = "TBD" if qual_date_and_time.endswith("T00:00:00-0500") else qual_date_and_time3.format("15:04 " if config.bool("is_24_hour_format", DEFAULTS["time_24"]) else "3:04pm")[:-1]
    text_color = config.get("text_color", DEFAULTS["text_color"])

    return render.Row(expanded = True, children = [
        render.Box(width = 16, height = 26, child = render.Image(src = base64.decode(IMAGES[data["trackid"]]), height = 24, width = 14)),
        #render.Box(width = 16, height = 26, child = render.Image(src = base64.decode(IMAGES[data["type"]]), height = 24, width = 14)),
        fade_child(data["name"], data["track"], "Race\n{}\n{}\nTV: {}".format(date_str, time_str, data["tv"].upper()), "Qual\n{}\n{}".format(qual_date_str, qual_time_str), text_color),
    ])

def fade_child(race, track, date_time_tv, qual_string, text_color):
    # IndyNXT doesn't name their races, so we're just going to flip back & forth between track & date/time/tv
    if race == track:
        return render.Animation(
            children =
                createfadelist(track, SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(qual_string, SIZES["animation_hold_frames"], SIZES["datetime_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(date_time_tv, SIZES["animation_hold_frames"], SIZES["datetime_font"], text_color, SIZES["nri_data_box_width"], "center"),
        )
    else:
        return render.Animation(
            children =
                createfadelist(race, SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(track, SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(qual_string, SIZES["animation_hold_frames"], SIZES["datetime_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(date_time_tv, SIZES["animation_hold_frames"], SIZES["datetime_font"], text_color, SIZES["nri_data_box_width"], "center"),
        )

# ##############################################
#            Standings  Functions
# ##############################################
# we're going to display 3 windows, 12 total data elements, 4 lines per window
def standings(config, data):
    standingformat = "{}\n{}\n{}\n{}"

    text_color = config.get("text_color", DEFAULTS["text_color"])
    text = drvrtext(data)

    return render.Animation(
        children =
            createfadelist(standingformat.format(text[0], text[1], text[2], text[3]), SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["drv_data_box_width"], "right") +
            createfadelist(standingformat.format(text[4], text[5], text[6], text[7]), SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["drv_data_box_width"], "right") +
            createfadelist(standingformat.format(text[8], text[9], text[10], text[11]), SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["drv_data_box_width"], "right"),
    )

def drvrtext(data):
    text = []  # preset 4 text strings

    # layout is:   2 digit position, 9 char driver last name, 3 digit points - with spaces between values
    # loop through drivers and parse the data

    positions = len(data) if len(data) <= DEFAULTS["positions"] else DEFAULTS["positions"]

    for i in range(positions):
        text.append("{} {} {}".format(text_justify_trunc(2, str(data[i]["RANK"]), "right"), text_justify_trunc(9, data[i]["DRIVER"].replace(" Jr.", "").split(" ")[-1], "left"), text_justify_trunc(3, str(data[i]["TOTAL"]), "right")))

    return text

# ##############################################
#            Text Display Functions
# ##############################################

def createfadelist(text, cycles, text_font, text_color, data_box_width, text_align):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

    # this is a pure genius technique and is borrowed from @CubsAaron countdown_clock
    # need to ponder if there is a different way to do it if we want something other than grey
    # use alpha channel to fade in and out

    # go from none to full color
    for x in alpha_values:
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color + x, data_box_width, text_align))
    for x in range(cycles):
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color, data_box_width, text_align))

    # go from full color back to none
    for x in alpha_values[5:0]:
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color + x, data_box_width, text_align))
    return cycle_list

def fadelistchildcolumn(text, font, color, data_box_width, text_align):
    return render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(content = text, font = font, color = color, align = text_align, width = data_box_width)])

# ##############################################
#           Schema Funcitons
# ##############################################

dispopt = [
    schema.Option(
        display = "Next Race",
        value = "nri",
    ),
    schema.Option(
        display = "Driver Standings",
        value = "drv",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "series",
                name = "Series",
                desc = "Select which series to display",
                icon = "flagCheckered",
                default = DEFAULTS["series"],
                options = [
                    schema.Option(
                        display = "NTT Indycar",
                        value = "car",
                    ),
                    schema.Option(
                        display = "Indycar NXT Series",
                        value = "nxt",
                    ),
                ],
            ),
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
def get_cachable_data(url, ttl = DEFAULTS["ttl"]):
    res = http.get(url = url, ttl_seconds = ttl)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def text_justify_trunc(length, text, direction):
    #  thanks to @inxi and @whyamihere / @rs7q5 for the codepoints() and codepoints_ords() help
    chars = list(text.codepoints())
    textlen = len(chars)

    # if string is shorter than desired - we can just use the count of chars (not bytes) and add on spaces - we're good
    if textlen < length:
        for _ in range(length - textlen):
            text = " " + text if direction == "right" else text + " "
    else:
        # text is longer - need to trunc it get the list of characters & trunc at length
        text = ""  # clear out text
        for i in range(length):
            text = text + chars[i]

    return text
