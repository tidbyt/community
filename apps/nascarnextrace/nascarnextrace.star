"""
Applet: NASCAR Next Race
Summary: Next NASCAR race or current standings
Description: Shows NASCAR next race, standings, playoffs for Cup, Xfinity and Trucks - original version based heavily on F1 next race from AMillionAir
Author: jvivona
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23060

# cache data for 15 minutes - cycle through with cache on the API side
CACHE_TTL_SECONDS = 900

DEFAULT_TIMEZONE = "America/New_York"

#we grab the current schedule from nascar website and cache it at this api location to prevent getting blocked by nascar website, data is refreshed every 30 minutes
NASCAR_API = "https://tidbyt.apis.ajcomputers.com/nascar/api/"
DEFAULT_SERIES = "cup"
DEFAULT_TIME_24 = False
DEFAULT_DATE_US = True

REGULAR_FONT = "tom-thumb"
DATETIME_FONT = "tb-8"

ANIMATION_FRAMES = 30
ANIMATION_HOLD_FRAMES = 75
DEFAULT_ANIMATION = "slide"

DATA_BOX_BKG = "#000"
SLIDE_DURATION = 99

DATA_BOX_WIDTH = 64
DATA_BOX_HEIGHT = 20
TITLE_BOX_WIDTH = 64
TITLE_BOX_HEIGHT = 12

# Easing
EASE_IN = "ease_in"
EASE_OUT = "ease_out"
EASE_IN_OUT = "ease_in_out"

DISPLAY_VALUES = {
    "cup": ["cup", "#333333", "#fff", "NASCAR Cup"],
    "xfinity": ["xfinity", "#4427ad", "#fff", "Xfinity Series"],
    "trucks": ["trucks", "#990000", "#fff", "Craftsman Trucks"],
    "mfg": "MFG Pts / Wins",
    "own": "Ownr Pts / Wins",
    "drv": "Drvr Pts / Wins",
    "ply": "Drvr Playoff Pos",
    "nri": "Next Race",
}

def main(config):
    series = config.get("NASCAR_Series", DEFAULT_SERIES)

    NASCAR_DATA = json.decode(get_cachable_data(NASCAR_API + series))

    data_display = config.get("data_display", "nri")

    if data_display == "nri":
        NASCAR_DATA = json.decode(get_cachable_data(NASCAR_API + series))
        text = nextrace(NASCAR_DATA, config)
    else:
        NASCAR_DATA = json.decode(get_cachable_data(NASCAR_API + series + data_display))
        text = standings(NASCAR_DATA, config, data_display)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                title_box(series, data_display),
            ] + text,
        ),
    )

# ###################################################
#          Next Race Functions
# ###################################################

def nextrace(api_data, config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)  # Utilize special timezone variable to get TZ - otherwise assume US Eastern w/DST
    date_and_time = api_data["Race_Date"]
    date_and_time3 = time.parse_time(date_and_time, "2006-01-02T15:04:05-0700").in_location(timezone)
    date_str = date_and_time3.format("Jan 02" if config.bool("is_us_date_format", DEFAULT_DATE_US) else "02 Jan").title()  #current format of your current date str
    time_str = "TBD" if date_and_time.endswith("T00:00:00-0500") else date_and_time3.format("15:04 " if config.bool("is_24_hour_format", DEFAULT_TIME_24) else "3:04pm")[:-1]
    tv_str = api_data["Race_TV_Display"] if api_data["Race_TV_Display"] != "" else "TBD"

    text_color = config.get("text_color", coloropt[0].value)

    if config.get("fade_slide", DEFAULT_ANIMATION) == "slide":
        data_child = slideinout_child(api_data["Race_Name"], api_data["Track_Name"], "%s %s\nTV: %s" % (date_str, time_str, tv_str), text_color)
    else:
        data_child = fade_child(api_data["Race_Name"], api_data["Track_Name"], "%s %s\nTV: %s" % (date_str, time_str, tv_str), text_color)

    return [data_child]

def slideinout_child(race, track, time, text_color):
    return render.Sequence(
        children = [
            slidetransform(race, REGULAR_FONT, text_color),
            slidetransform(track, REGULAR_FONT, text_color),
            slidetransform(time, DATETIME_FONT, text_color),
        ],
    )

def slidetransform(text, font, text_color):
    return animation.Transformation(
        child = render.Box(width = DATA_BOX_WIDTH, height = DATA_BOX_HEIGHT, color = DATA_BOX_BKG, child = render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = font, color = text_color, align = "center", width = DATA_BOX_WIDTH)])),
        duration = SLIDE_DURATION,
        delay = 0,
        origin = animation.Origin(0, 0),
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(-DATA_BOX_WIDTH, 0)],
                curve = EASE_IN_OUT,
            ),
            animation.Keyframe(
                percentage = 0.1,
                transforms = [animation.Translate(-0, 0)],
                curve = EASE_IN_OUT,
            ),
            animation.Keyframe(
                percentage = 0.9,
                transforms = [animation.Translate(-0, 0)],
                curve = EASE_IN_OUT,
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(DATA_BOX_WIDTH, 0)],
                curve = EASE_IN_OUT,
            ),
        ],
    )

# need to come back to this, this is just an up down slide - it should simulate a flip motion
#def flip(text, text_font):
#    return animation.Transformation(
#        child = render.Box(width = DATA_BOX_WIDTH, height = DATA_BOX_HEIGHT, color = DATA_BOX_BKG, child = render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = DATETIME_FONT, color = "#fff", align = "center", width = 64)])),
#        height = 20,
#        keyframes = [
#            animation.Keyframe(0.0, [animation.Translate(0, 0), animation.Scale(1, 1)], curve = "ease_in_out"),
#            animation.Keyframe(1.0, [animation.Translate(0, -DATA_BOX_HEIGHT), animation.Scale(1, 1)], curve = "ease_in_out"),
#        ],
#        duration = 20,
#        delay = 100,
#        direction = "alternate",
#        fill_mode = "backwards",
#    )

def fade_child(race, track, date_time_tv, text_color):
    return render.Animation(
        children =
            createfadelist(race, ANIMATION_HOLD_FRAMES, REGULAR_FONT, text_color) +
            createfadelist(track, ANIMATION_HOLD_FRAMES, REGULAR_FONT, text_color) +
            createfadelist(date_time_tv, ANIMATION_HOLD_FRAMES, DATETIME_FONT, text_color),
    )

def createfadelist(text, cycles, text_font, text_color):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

    # this is a pure genius technique and is borrowed from @CubsAaron countdown_clock
    # need to ponder if there is a different way to do it if we want something other than grey
    # use alpha channel to fade in and out

    # go from none to full color
    for x in alpha_values:
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color + x))
    for x in range(cycles):
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color))

    # go from full color back to none
    for x in alpha_values[5:0]:
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color + x))
    return cycle_list

def fadelistchildcolumn(text, font, color):
    return render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(content = text, font = font, color = color, align = "center", width = DATA_BOX_WIDTH)])

# ###################################################
#          Points Display Functions
# ###################################################

# we're going to display 3 marquees, 9 total data elements, 3 on each line
def standings(api_data, config, data_display):
    # there is a more generic way to do this by passing in an array of fields & the formatting string - have to ponder it
    if data_display == "drv":
        text = drvrtext(api_data)
    elif data_display == "own":
        text = owners(api_data)
    elif data_display == "mfg":
        text = mfgtext(api_data)
    else:
        text = playoff(api_data)

    text_color = config.get("text_color", coloropt[0].value)

    return [
        render.Marquee(offset_start = 48, child = render.Text(height = 6, content = text[0], font = REGULAR_FONT, color = text_color), scroll_direction = "horizontal", width = 64),
        render.Marquee(offset_start = 48, child = render.Text(height = 7, content = text[1], font = REGULAR_FONT, color = text_color), scroll_direction = "horizontal", width = 64),
        render.Marquee(offset_start = 48, child = render.Text(height = 7, content = text[2], font = REGULAR_FONT, color = text_color), scroll_direction = "horizontal", width = 64),
    ]

# there is a more generic way to do this by passing in an array of fields & the formatting string - have to ponder it

def mfgtext(data):
    text = ["", "", ""]  # preset 3 text strings

    # layout is:   1 digit position, 9 char mfg name, 4 digit points, 2 digit wins  - with spaces or / between values
    # loop through mfgs and parse the data - there are only 3 MFGs in eacho of the series (as of 2023) - but the logic is here to support more
    positions = len(data) if len(data) <= 9 else 9

    for i in range(0, positions):
        text[int(math.mod(i, 3))] = text[int(math.mod(i, 3))] + "{} {} {} / {}   ".format(data[i]["position"], text_justify_trunc(9, data[i]["manufacturer"], "left"), text_justify_trunc(4, str(data[i]["points"]), "right"), text_justify_trunc(2, str(data[i]["wins"]), "right"))

    return text

def drvrtext(data):
    text = ["", "", ""]  # preset 3 text strings

    # layout is:   1 digit position, 1st 2 chars of driver first name + 10 char driver last name, 4 digit points, 2 digit wins  - with spaces or / between values
    # loop through drivers and parse the data
    positions = len(data) if len(data) <= 9 else 9

    for i in range(0, positions):
        text[int(math.mod(i, 3))] = text[int(math.mod(i, 3))] + "{} {} {} {} / {}    ".format(data[i]["position"], data[i]["driver_first_name"][0:2], text_justify_trunc(10, data[i]["driver_last_name"], "left"), text_justify_trunc(4, str(data[i]["points"]), "right"), text_justify_trunc(2, str(data[i]["wins"]), "right"))

    return text

def playoff(data):
    text = ["", "", ""]  # preset 3 text strings

    # layout is:   1 digit position, 1st 2 chars of driver first name + 10 char driver last name, 4 digit points, 2 digit wins  - with spaces or / between values
    # loop through drivers and parse the data - api sorts the data by playoff position
    positions = len(data) if len(data) <= 9 else 9

    for i in range(0, positions):
        text[int(math.mod(i, 3))] = text[int(math.mod(i, 3))] + "{} {} {} {} / {}    ".format(data[i]["playoff_rank"], data[i]["driver_first_name"][0:2], text_justify_trunc(10, data[i]["driver_last_name"], "left"), text_justify_trunc(4, str(data[i]["playoff_points"]), "right"), text_justify_trunc(2, str(data[i]["playoff_race_wins"]), "right"))

    return text

def owners(data):
    text = ["", "", ""]  # preset 3 text strings

    # layout is:   1 digit position, 2 digit car number, 10 char owner name, 4 digit points, 2 digit wins  - with spaces or / between values
    # loop through owners and parse the data
    positions = len(data) if len(data) <= 9 else 9

    for i in range(0, positions):
        text[int(math.mod(i, 3))] = text[int(math.mod(i, 3))] + "{}. {} {} {} / {}      ".format(data[i]["position"], text_justify_trunc(2, data[i]["vehicle_number"], "right"), text_justify_trunc(10, data[i]["owner_name"], "left"), text_justify_trunc(4, str(data[i]["points"]), "right"), text_justify_trunc(2, str(data[i]["wins"]), "right"))

    return text

# ###################################################
#          Schema Stuff
# ###################################################

coloropt = [
    schema.Option(
        display = "White",
        value = "#FFFFFF",
    ),
    schema.Option(
        display = "Red",
        value = "#FF0000",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FFFF00",
    ),
    schema.Option(
        display = "Green",
        value = "#008000",
    ),
    schema.Option(
        display = "Blue",
        value = "#0000FF",
    ),
    schema.Option(
        display = "Indigo",
        value = "#4B0082",
    ),
    schema.Option(
        display = "Violet",
        value = "#EE82EE",
    ),
    schema.Option(
        display = "Pink",
        value = "#FC46AA",
    ),
]

dispopt = [
    schema.Option(
        display = "Next Race",
        value = "nri",
    ),
    schema.Option(
        display = "Driver Standings",
        value = "drv",
    ),
    schema.Option(
        display = "Driver Playoff Standings",
        value = "ply",
    ),
    schema.Option(
        display = "Owner Standings",
        value = "own",
    ),
    schema.Option(
        display = "Manufacturer Standings",
        value = "mfg",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "NASCAR_Series",
                name = "Series",
                desc = "Select which series to display",
                icon = "flagCheckered",
                default = DEFAULT_SERIES,
                options = [
                    schema.Option(
                        display = "NASCAR Cup Series",
                        value = "cup",
                    ),
                    schema.Option(
                        display = "NASCAR Xfinity Series",
                        value = "xfinity",
                    ),
                    schema.Option(
                        display = "NASCAR Craftsman Truck Series",
                        value = "trucks",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "data_display",
                name = "Display Type",
                desc = "What data to display?",
                icon = "eye",
                default = "nri",
                options = dispopt,
            ),
            schema.Dropdown(
                id = "text_color",
                name = "Text Color",
                desc = "The color for Standings / Race / Track / Time text.",
                icon = "palette",
                default = coloropt[0].value,
                options = coloropt,
            ),
            schema.Generated(
                id = "nascar_generated",
                source = "data_display",
                handler = show_nri_options,
            ),
        ],
    )

def show_nri_options(data_display):
    if data_display == "nri":
        return [
            schema.Dropdown(
                id = "fade_slide",
                name = "Fade or Slide",
                desc = "Show Race / Track / Time via Fade or Slide",
                icon = "eye",
                default = DEFAULT_ANIMATION,
                options = [
                    schema.Option(
                        display = "Fade Race / Track / Time In and Out",
                        value = "fade",
                    ),
                    schema.Option(
                        display = "Slide Race / Track / Time In and Out",
                        value = "slide",
                    ),
                ],
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = DEFAULT_TIME_24,
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format.",
                icon = "calendarDays",
                default = DEFAULT_DATE_US,
            ),
        ]
    else:
        return []

# ###################################################
#          General Functions
# ###################################################

def title_box(series, display):
    display_values = DISPLAY_VALUES[series]
    display_second_line = DISPLAY_VALUES[display]

    return render.Box(
        width = TITLE_BOX_WIDTH,
        height = TITLE_BOX_HEIGHT,
        color = display_values[1],
        child = render.Padding(
            pad = (0, 0, 0, 0),
            child = render.WrappedText("{}\n{}".format(display_values[3], display_second_line), color = display_values[2], font = REGULAR_FONT, align = "center", height = TITLE_BOX_HEIGHT, width = TITLE_BOX_WIDTH),
        ),
    )

def get_cachable_data(url):
    key = url

    data = cache.get(key)
    if data != None:
        return data

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, res.body(), ttl_seconds = CACHE_TTL_SECONDS)

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
