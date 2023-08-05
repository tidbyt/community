"""
Applet: SailGP
Summary: Sail GP Race and Leaders
Description: Sail GP Next Race Info and Current Leaderboard.
Author: jvivona
"""

# ############################
# Mods - jvivona - 2023-07-13
# - added in standings display with country flags (** I learned a bunch about flag sizes in this exercise)
# - convert next race info color to generated schema field

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23194

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
    "slide_duration": 75,
}

FLAGS = {
    "ESP": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAbCAMAAAA5zj1cAAAAjVBMVEX/xADWsQvknRS4ZEq1RxL5tQD8wgXGCx7VORftug6rTgixPxXrrwq7rUjOvZbUiArNrou4eQSkYhCUmFLIrCvyvwfvqAbamA/YegrHiB3PbQiiUxbhkA3PusTASw/rtwW+elrOnkjTlUjFpYX2vQDCmhzRpbK5XRKzXEDImHGLPSqyWkF3TFrgkbVSZWU/pl0VAAAAiklEQVQ4y+XTRw7CQAxA0amB6SUhPQRI6OX+x+MG8Qh28NdPsmTZaJUY+im4Tgx9lkhSmdDHcZMA9VadWQsy7jIXQqg4gQbjnqmrtzOG4FTH6J8D8QCsd23sHqfB0XIZEtp0t9ed9pQvw9I2UiqmhAUgNpWUF8awAVZZ5ILszUEXuUDflXw9f/lcb4nLFkvy34BaAAAAAElFTkSuQmCC",
    "SUI": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAoBAMAAAB+0KVeAAAAElBMVEX/AAD/////wMD/gID/YGD/8PBDRn5nAAAANklEQVQoz2NgGLzA2djYBENQUVBQaJALsigBQaCgoCiIdoAKMgsiAQN6C2J10lAJT9yJYfAAAHGvEL146aHXAAAAAElFTkSuQmCC",
    "GER": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAYAgMAAAD16ldTAAAACVBMVEUAAADdAAD/zgDGIigcAAAAFUlEQVQY02NgoBEIhQPqMlfBAVWZANYST7G6bxb2AAAAAElFTkSuQmCC",
    "USA": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAVCAMAAAADxFwsAAAAM1BMVEXGWmdWVoJGRXV/fqDsyM1BQHE8O27YkZr///+yIjS1nLBKSXheXYdzcpdmZY2JiKfrx8sZZnA7AAAAjUlEQVQoz62Q2wrDQAhE1e1Mkrq5/P/Xdi8plFLBhx7E8yLKKHTCWutGa1uAoHhVL2bTWAKEKGhVdZprgODkUXnibYkg+ybWOs1w8GNoODxN261V1WmGYbCb3kPdCN9DPdwObQzHqekKU3c0Q52P31wjjN5husPTzy/CjWsS2ZLIkiR/+v+kT6fDZN/zArG+FImrLSObAAAAAElFTkSuQmCC",
    "GBR": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAUCAMAAADImI+JAAAANlBMVEX////w8vfyxcx8jbJCWpAOLHFVa5sBIWnIEC7WTGLnv8qAkLTheYpecqHx0digrMfz3+T21dqBS5WQAAAApUlEQVQoz8WTyxpFMAyEpyqOuhTv/7IntImmurAzC59kfsIIhA5wnn6iASMLgzbIT2Fk6joUaAUKBsiJm+kJ0iyuR1mQBam8Cex1dINkZ6EesSZwrR8JfdYWl7AcbCRw5ypytYmPpy6w3X6jL8HXL6PxOODgTPYEcnXmFe94cuBsdJzwpIFrRwK3WPkJLQqL2aUoUVisXjOvLizWWNyMVljrV0gz/wdhEi0lRIbcAAAAAElFTkSuQmCC",
    "FRA": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAbBAMAAAD8PtBdAAAAD1BMVEXtKTkAI5X///+qtdz5uL22UrpzAAAAGElEQVQoz2MQBANhJTBwYICAUcFRQbyCAK7MKQicBg83AAAAAElFTkSuQmCC",
    "DEN": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAeBAMAAACs80HuAAAAElBMVEXIEC7////WTGPYV2zJFjPigZEAQ1emAAAAJ0lEQVQoz2NgAANHQWEGDDDsBZXAQFFQVAkBGASxAEoFsVo0gkMeAIyVE9snzfM0AAAAAElFTkSuQmCC",
    "AUS": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAUCAMAAADImI+JAAAAdVBMVEUBIWn+/v8LKm8rRoLsS2lZa5sCI2rkACvAyNojP317jLGrtc2qtc3FzN1fc6FBWY/5w83ecIr+8vQRL3P5x9DY3ejU2OVeZpZLVIn709oYNndNZJacqcWLmrra3unVZ4Xy9Pj22uFEXJHIz94VM3XUZYPb3+rlcwqvAAAAz0lEQVQoz7WQyRKDIBBEB2STRHHfTdQs//+JQVxiSlNFDunLAPOomW4gycVnAHDi/KwLoyEJ4EjFgyQpXcBcY54C+IpmdAQNNmxavv8+C62sLyPEeVRGXTbelx72BF5BfqC16bpgB25lRnd6KucoKvuP0UaOdObT4CUkzEczNA3ItZheq2oxhKYUlMHmeNiK4ps3+7jXzFSN0W3g/jMgY5WSwS+i1BLcBrS4c6x+xrJpZGxDtgi1NpwSCAlls44rxG5vfEnxHozjvUFaw//0ApepC3HnUeodAAAAAElFTkSuQmCC",
    "NZL": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAUCAMAAADImI+JAAAAclBMVEUBIWn68/artc2qtc0OLXHYVmtbbZzIEC7AyNrPd4z0zdPPZXskQX1dZpT12N3yxs0CImpGV4w+T4bGboXFzN3U2OXVUWja3uk6R4DLRl4wSINtapYjO3nX3Of8/P1EXJFYWovJaYDMJkKkdJGceZnYV2wLvzvsAAAAuElEQVQoz9WQWxOCIBCFlxIIBMRral6yy///iwmK5WQNLz10XnZhvzlndqHgR6IBYEfpfiyasILDluIU85Y4UDIcZTHARzQnBrRY/zIKgmd/GJUrhTpKkUIoN283E8MgFpBuaBkyBn7gWzQaUyntkFKraKtz7bo+45hJswxpI5y6nU+zaRFOtnHG70zO59EWTcz/7SInsiynOrqtD36MsDW8CvgqDX+mpvHjkqpK/Mgw9IwW9Q/3egATpQmIac+/QgAAAABJRU5ErkJggg==",
    "CAN": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAUCAMAAADImI+JAAAASFBMVEX/////ubn/oqL/Z2f/Jib/09P/7e3/AAD/+/v/Gxv/W1v/rq7/eXn/nZ3/DAz/OTn/AwP/Pj7//Pz/QED/PT3/g4P/xsb/xcWY5npoAAAAkUlEQVQoz43TyQ7DIAxFUQbDNZCx4///aTdt00ohsXdPHIFsGce33E79nO5AvRjhGCxQVYs41fMbpUIVw9MzwHwKk4sA0aUj6IdW7iNAGEobfBfmBbgC3IAld6HKllhEuzDwV6HfjJ+2OPmjrlP5pJKOx5PfsuSTOWZZY61xlWxYiufDuD3eG2FrRpiSEe5+hRcblQ+AegtNbgAAAABJRU5ErkJggg==",
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
    else:
        displayrow = current_standings(standings, config)

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

def current_standings(standings, config):
    standings_text_color = config.get("standings_text_color", DEFAULTS["standings_text_color"])
    return [render.Sequence(
        children = [
            current_standings_slide(standings[0], standings[1], standings_text_color),
            current_standings_slide(standings[2], standings[3], standings_text_color),
            current_standings_slide(standings[4], standings[5], standings_text_color),
            current_standings_slide(standings[6], standings[7], standings_text_color),
            current_standings_slide(standings[8], standings[9], standings_text_color),
        ],
    )]

def current_standings_slide(standingsLeft, standingsRight, standings_text_color):
    return animation.Transformation(
        child =
            render.Row(expanded = True, children = [
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Box(width = 32, height = 14, child = render.Image(base64.decode(FLAGS[standingsLeft["teamAbbreviation"]]), height = 14)),
                        render.Text("{} {}".format(str(standingsLeft["position"]), standingsLeft["teamAbbreviation"]), font = DEFAULTS["regular_font"], color = standings_text_color),
                        render.Text("{} pts".format(str(standingsLeft["points"])), font = DEFAULTS["regular_font"], color = standings_text_color),
                    ],
                ),
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Box(width = 32, height = 14, child = render.Image(base64.decode(FLAGS[standingsRight["teamAbbreviation"]]), height = 14)),
                        render.Text("{} {}".format(str(standingsRight["position"]), standingsRight["teamAbbreviation"]), font = DEFAULTS["regular_font"], color = standings_text_color),
                        render.Text("{} pts".format(str(standingsRight["points"])), font = DEFAULTS["regular_font"], color = standings_text_color),
                    ],
                ),
            ]),
        duration = DEFAULTS["slide_duration"],
        delay = 0,
        origin = animation.Origin(0, 0),
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(DEFAULTS["data_box_width"], 0)],
                curve = DEFAULTS["ease_in_out"],
            ),
            animation.Keyframe(
                percentage = 0.1,
                transforms = [animation.Translate(-0, 0)],
                curve = DEFAULTS["ease_in_out"],
            ),
            animation.Keyframe(
                percentage = 0.9,
                transforms = [animation.Translate(-0, 0)],
                curve = DEFAULTS["ease_in_out"],
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(-DEFAULTS["data_box_width"], 0)],
                curve = DEFAULTS["ease_in_out"],
            ),
        ],
    )

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
        display = "Standings Display with Flags",
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
            schema.Color(
                id = "text_color",
                name = "Race Info Color",
                desc = "The color for Race Info and Date.",
                icon = "palette",
                default = DEFAULTS["text_color"],
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
