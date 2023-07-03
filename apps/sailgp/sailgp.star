"""
Applet: SailGP
Summary: Sail GP Race and Leaders
Description: Sail GP Next Race Info and Current Leaderboard.
Author: jvivona
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23171

DEFAULTS = {
    "display": "nri",
    "timezone": "America/New_York",
    "date_us": True,
    "api": "https://tidbyt.apis.ajcomputers.com/sailgp/api/{}.json",
    "ttl": 1800,
    "text_color": "#FFFFFF",
    "standings_text_color": "#FFFFFF",
    "regular_font": "tom-thumb",
    "data_box_width": 64,
    "data_box_height": 16,
    "data_box_bkg": "#000",
    "ease_in_out": "ease_in_out",
    "animation_frames": 30,
    "animation_hold_frames": 75,
    "title_bkg_color": "#0a2627",
}

def main(config):
    displaytype = config.get("datadisplay", DEFAULTS["display"])

    # we always need standings - so just go get it
    standings = json.decode(get_cachable_data(DEFAULTS["api"].format("standings")))

    displayrow = []

    # if we're showing NRI go and get that data
    if displaytype == "nri":
        data = json.decode(get_cachable_data(DEFAULTS["api"].format(displaytype)))
        displayrow = nri(data, standings, config)

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
                    color = DEFAULTS["title_bkg_color"],
                ),
            ] + displayrow,
        ),
    )

def nri(nri, standings, config):
    text_color = config.get("text_color", DEFAULTS["text_color"])
    standings_text_color = config.get("standings_text_color", DEFAULTS["standings_text_color"])
    timezone = config.get("$tz", DEFAULTS["timezone"])  # Utilize special timezone variable to get TZ - otherwise assume US Eastern w/DST

    date_and_time_first = nri["startDateTime"]
    date_and_time_second = nri["endDateTime"]
    date_and_time_first_dt = time.parse_time(date_and_time_first, "2006-01-02T15:04-07:00").in_location(timezone)
    date_and_time_second_dt = time.parse_time(date_and_time_second, "2006-01-02T15:04-07:00").in_location(timezone)
    date_time_format = date_and_time_first_dt.format("Jan 02-") + date_and_time_second_dt.format("02 2006") if config.bool("is_us_date_format", DEFAULTS["date_us"]) else date_and_time_first_dt.format("02-") + date_and_time_second_dt.format("02 Jan 2006")

    standing_text = ""
    for i in standings:
        standing_text = standing_text + "{}. {} ({})  ".format(str(i["position"]), i["teamAbbreviation"], str(i["points"]))

    return [
        render.Box(width = 64, height = 1),
        fade_child(nri["name"].replace("Sail Grand Prix", "GP"), nri["locationName"], text_color),
        render.WrappedText(content = date_time_format, font = DEFAULTS["regular_font"], color = text_color, align = "center", width = DEFAULTS["data_box_width"], height = 5),
        render.Box(width = 64, height = 1),
        render.Marquee(offset_start = 48, child = render.Text(height = 6, content = standing_text, font = DEFAULTS["regular_font"], color = standings_text_color), scroll_direction = "horizontal", width = 64),
    ]

def fade_child(race, location, text_color):
    return render.Animation(
        children =
            createfadelist(race, DEFAULTS["animation_hold_frames"], DEFAULTS["regular_font"], text_color) +
            createfadelist(location, DEFAULTS["animation_hold_frames"], DEFAULTS["regular_font"], text_color),
    )

def createfadelist(text, cycles, text_font, text_color):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

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
    return render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = text, font = font, color = color, align = "center", width = DEFAULTS["data_box_width"], height = 14)])

# ##############################################
#           Schema Funcitons
# ##############################################

dispopt = [
    schema.Option(
        display = "Next Race",
        value = "nri",
    ),
    schema.Option(
        display = "** Coming Soon ** Standings with Flags",
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
                name = "Race Info Color",
                desc = "The color for Race Info and Date.",
                icon = "palette",
                default = DEFAULTS["text_color"],
            ),
            schema.Color(
                id = "standings_text_color",
                name = "Standings Color",
                desc = "The color for Standings.",
                icon = "palette",
                default = DEFAULTS["standings_text_color"],
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
