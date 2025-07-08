load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DAILY_FOTM_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAADUAAAAsCAYAAADFP/AjAAAEsWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS41LjAiPgogPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIKICAgIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIKICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIKICAgIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIgogICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgdGlmZjpJbWFnZUxlbmd0aD0iNDQiCiAgIHRpZmY6SW1hZ2VXaWR0aD0iNTMiCiAgIHRpZmY6UmVzb2x1dGlvblVuaXQ9IjIiCiAgIHRpZmY6WFJlc29sdXRpb249IjcyLzEiCiAgIHRpZmY6WVJlc29sdXRpb249IjcyLzEiCiAgIGV4aWY6UGl4ZWxYRGltZW5zaW9uPSI1MyIKICAgZXhpZjpQaXhlbFlEaW1lbnNpb249IjQ0IgogICBleGlmOkNvbG9yU3BhY2U9IjEiCiAgIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiCiAgIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIKICAgeG1wOk1vZGlmeURhdGU9IjIwMjQtMDkt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
""")

NIGHTMARE = {
    "name_without_label": "Nightmare",
    "name_with_label": "Nightmare",
    "has_cm": True,
}
SNOWBLIND = {
    "name_without_label": "Snowblind",
    "name_with_label": "Snowblind",
    "has_cm": False,
}
VOLCANIC = {
    "name_without_label": "Volcanic",
    "name_with_label": "Volcanic",
    "has_cm": False,
}
AETHERBLADE = {
    "name_without_label": "Aetherblade",
    "name_with_label": "Aetherblade",
    "has_cm": False,
}
THAUMANOVA_REACTOR = {
    "name_without_label": "Thaumanova",
    "name_with_label": "Thaumanova",
    "has_cm": False,
}
UNCATEGORIZED = {
    "name_without_label": "Uncategorized",
    "name_with_label": "Uncategorized",
    "has_cm": False,
}
CHAOS = {
    "name_without_label": "Chaos",
    "name_with_label": "Chaos",
    "has_cm": False,
}
CLIFFSIDE = {
    "name_without_label": "Cliffside",
    "name_with_label": "Cliffside",
    "has_cm": False,
}
TWILIGHT_OASIS = {
    "name_without_label": "Twilight Oasis",
    "name_with_label": "Twilight Oas.",
    "has_cm": False,
}
CAPTAIN_MAI_TRIN_BOSS = {
    "name_without_label": "Mai Trin",
    "name_with_label": "Mai Trin",
    "has_cm": False,
}
DEEPSTONE = {
    "name_without_label": "Deepstone",
    "name_with_label": "Deepstone",
    "has_cm": False,
}
SILENT_SURF = {
    "name_without_label": "Silent Surf",
    "name_with_label": "Silent Surf",
    "has_cm": True,
}
SOLID_OCEAN = {
    "name_without_label": "Solid Ocean",
    "name_with_label": "Solid Ocean",
    "has_cm": False,
}
URBAN_BATTLEGROUND = {
    "name_without_label": "Urban Btlgrnd",
    "name_with_label": "Urban Btlgrnd",
    "has_cm": False,
}
MOLTEN_FURNACE = {
    "name_without_label": "Molten Furnace",
    "name_with_label": "Molten Furn.",
    "has_cm": False,
}
SIRENS_REEF = {
    "name_without_label": "Siren's Reef",
    "name_with_label": "Siren's Reef",
    "has_cm": False,
}
UNDERGROUND_FACILITY = {
    "name_without_label": "Undrgrnd Fac.",
    "name_with_label": "Undrgrnd Fac.",
    "has_cm": False,
}
MOLTEN_BOSS = {
    "name_without_label": "Molten Boss",
    "name_with_label": "Molten Boss",
    "has_cm": False,
}
SWAMPLAND = {
    "name_without_label": "Swampland",
    "name_with_label": "Swampland",
    "has_cm": False,
}
AQUATIC_RUINS = {
    "name_without_label": "Aquatic Ruins",
    "name_with_label": "Aquatic Ruins",
    "has_cm": False,
}
LONELY_TOWER = {
    "name_without_label": "Lonely Tower",
    "name_with_label": "Lonely Tower",
    "has_cm": True,
}
SUNQUA_PEAK = {
    "name_without_label": "Sunqua Peak",
    "name_with_label": "Sunqua Peak",
    "has_cm": True,
}
SHATTERED_OBSERVATORY = {
    "name_without_label": "Shattered",
    "name_with_label": "Shattered",
    "has_cm": True,
}
KINFALL = {
    "name_without_label": "Kinfall",
    "name_with_label": "Kinfall",
    "has_cm": False,
}

DAILY_FRACTALS = [
    (NIGHTMARE, SNOWBLIND, VOLCANIC),
    (AETHERBLADE, THAUMANOVA_REACTOR, UNCATEGORIZED),
    (CHAOS, CLIFFSIDE, TWILIGHT_OASIS),
    (CAPTAIN_MAI_TRIN_BOSS, DEEPSTONE, SILENT_SURF),
    (NIGHTMARE, SNOWBLIND, SOLID_OCEAN),
    (CHAOS, UNCATEGORIZED, URBAN_BATTLEGROUND),
    (DEEPSTONE, MOLTEN_FURNACE, SIRENS_REEF),
    (MOLTEN_BOSS, TWILIGHT_OASIS, UNDERGROUND_FACILITY),
    (SILENT_SURF, SWAMPLAND, VOLCANIC),
    (AQUATIC_RUINS, LONELY_TOWER, THAUMANOVA_REACTOR),
    (SUNQUA_PEAK, UNDERGROUND_FACILITY, URBAN_BATTLEGROUND),
    (AETHERBLADE, CHAOS, NIGHTMARE),
    (CLIFFSIDE, LONELY_TOWER, KINFALL),
    (DEEPSTONE, SOLID_OCEAN, SWAMPLAND),
    (CAPTAIN_MAI_TRIN_BOSS, MOLTEN_BOSS, SHATTERED_OBSERVATORY),
]

RECOMMENDED_FRACTALS = [
    (
        {"scale": 2, "fractal": UNCATEGORIZED},
        {"scale": 37, "fractal": SIRENS_REEF},
        {"scale": 53, "fractal": UNDERGROUND_FACILITY},
    ),
    (
        {"scale": 6, "fractal": CLIFFSIDE},
        {"scale": 28, "fractal": VOLCANIC},
        {"scale": 61, "fractal": AQUATIC_RUINS},
    ),
    (
        {"scale": 10, "fractal": MOLTEN_BOSS},
        {"scale": 32, "fractal": SWAMPLAND},
        {"scale": 65, "fractal": AETHERBLADE},
    ),
    (
        {"scale": 14, "fractal": AETHERBLADE},
        {"scale": 34, "fractal": THAUMANOVA_REACTOR},
        {"scale": 74, "fractal": SUNQUA_PEAK},
    ),
    (
        {"scale": 19, "fractal": VOLCANIC},
        {"scale": 50, "fractal": LONELY_TOWER},
        {"scale": 70, "fractal": KINFALL},
    ),
    (
        {"scale": 15, "fractal": THAUMANOVA_REACTOR},
        {"scale": 48, "fractal": SHATTERED_OBSERVATORY},
        {"scale": 60, "fractal": SOLID_OCEAN},
    ),
    (
        {"scale": 24, "fractal": SUNQUA_PEAK},
        {"scale": 35, "fractal": SOLID_OCEAN},
        {"scale": 66, "fractal": SILENT_SURF},
    ),
    (
        {"scale": 21, "fractal": SILENT_SURF},
        {"scale": 36, "fractal": UNCATEGORIZED},
        {"scale": 75, "fractal": LONELY_TOWER},
    ),
    (
        {"scale": 7, "fractal": AQUATIC_RUINS},
        {"scale": 40, "fractal": MOLTEN_BOSS},
        {"scale": 67, "fractal": DEEPSTONE},
    ),
    (
        {"scale": 8, "fractal": UNDERGROUND_FACILITY},
        {"scale": 31, "fractal": URBAN_BATTLEGROUND},
        {"scale": 54, "fractal": SIRENS_REEF},
    ),
    (
        {"scale": 11, "fractal": DEEPSTONE},
        {"scale": 39, "fractal": MOLTEN_FURNACE},
        {"scale": 59, "fractal": TWILIGHT_OASIS},
    ),
    (
        {"scale": 18, "fractal": CAPTAIN_MAI_TRIN_BOSS},
        {"scale": 27, "fractal": SNOWBLIND},
        {"scale": 64, "fractal": THAUMANOVA_REACTOR},
    ),
    (
        {"scale": 4, "fractal": URBAN_BATTLEGROUND},
        {"scale": 30, "fractal": CHAOS},
        {"scale": 58, "fractal": MOLTEN_FURNACE},
    ),
    (
        {"scale": 16, "fractal": TWILIGHT_OASIS},
        {"scale": 42, "fractal": CAPTAIN_MAI_TRIN_BOSS},
        {"scale": 62, "fractal": UNCATEGORIZED},
    ),
    (
        {"scale": 5, "fractal": SWAMPLAND},
        {"scale": 47, "fractal": NIGHTMARE},
        {"scale": 68, "fractal": CLIFFSIDE},
    ),
]

THEME = {
    "bg": "#2a173b",
    "text": "#F5DBFD",
    "text_cm": "#ff0000",
    "text_secondary": "#CA8DF0",
}

FRAMES_PER_SCREEN = 125

# The length of the months, in days. We use this for calculating the DOY index.
# The DOY index is static -- March 1 is always 60, whether it's a leap year or
# not. When not in a leap year, the index skips from 58 -> 60. Therefore, for
# the purposes of calculating our index, February always has 29 days.
CALENDAR_MONTH_DURATIONS_FOR_INDICES = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

# Returns a day of year index (0-365) that is fixed to a given month and day. Meaning that for every combination
# of month and day the index will be the same in both leap and non leap years. Notably this will skip the index
# value of 59 (February 29) in non leap years.
#
# Corresponds to https://wiki.guildwars2.com/wiki/Template:Day_of_year_index
def get_day_of_year_index():
    utc = time.now().in_location("UTC")

    index = 0
    for month in range(utc.month - 1):
        index += CALENDAR_MONTH_DURATIONS_FOR_INDICES[month]
    index += utc.day - 1

    return index

# Corresponds to the math logic from https://wiki.guildwars2.com/wiki/Template:Daily_Fractal_Schedule
def get_fractal_index():
    doy_index = get_day_of_year_index()
    fotm_index = int(math.mod(doy_index, 15))
    return fotm_index

def make_fotm(highlight_cm, label, fotm):
    FONT = "CG-pixel-3x5-mono"

    name_color = THEME["text_cm" if highlight_cm and fotm["has_cm"] else "text"]

    if label == None:
        # If we have no label, let's center-align the name and take up full row
        return render.Text(
            content = fotm["name_without_label"].upper(),
            font = FONT,
            color = name_color,
        )

    # If we have a label, let's left-align the name using all space not reserved by the two-length label
    return render.Row(
        children = [
            render.Padding(
                child = render.Text(
                    content = label.upper(),
                    font = FONT,
                    color = THEME["text_secondary"],
                ),
                pad = (1, 0, 1, 0),
            ),
            render.WrappedText(
                content = fotm["name_with_label"].upper(),
                font = FONT,
                color = name_color,
            ),
        ],
        expanded = True,
    )

def two_digit_str(num):
    return ("00" + str(num))[-2:]

def make_screen(highlight_cm, header, fractals, icon_align):
    FOTM_ICON_SIZE = 32
    FOTM_ICON_HORIZONTAL_OFFSCREEN = 8  # amount of pixels icon should go offscreen by

    if icon_align == "right":
        fotm_icon_padding_left = 64 - FOTM_ICON_SIZE + FOTM_ICON_HORIZONTAL_OFFSCREEN
    else:
        fotm_icon_padding_left = -FOTM_ICON_HORIZONTAL_OFFSCREEN

    return animation.Transformation(
        child = render.Stack(
            children = [
                render.Box(color = THEME["bg"]),
                render.Padding(
                    child = render.Image(
                        src = DAILY_FOTM_ICON,
                        width = FOTM_ICON_SIZE,
                        height = FOTM_ICON_SIZE,
                    ),
                    pad = (fotm_icon_padding_left, -10, 0, 0),
                ),
                render.Column(
                    children = [
                        render.WrappedText(
                            content = header,
                            font = "5x8",
                            color = "#ff0",
                            align = "center",
                            width = 64,
                        ),
                    ] + [render.Padding(
                        child = make_fotm(
                            highlight_cm,
                            label = x["label"],
                            fotm = x["fotm"],
                        ),
                        pad = (0, 1, 0, 0),
                    ) for x in fractals],
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                ),
            ],
        ),
        duration = FRAMES_PER_SCREEN,
        keyframes = [],
    )

def main(config):
    fotm_index = get_fractal_index()

    screens = []

    # Daily Fractals
    if config.bool("show_dailies"):
        screens.append(
            make_screen(
                highlight_cm = config.bool("highlight_cm"),
                header = "DAILY T4",
                fractals = [{"label": None, "fotm": fotm} for fotm in DAILY_FRACTALS[fotm_index]],
                icon_align = "left",
            ),
        )

    # Recommended Fractals
    if config.bool("show_recs"):
        screens.append(
            make_screen(
                highlight_cm = False,
                header = "RECS",
                fractals = [{"label": two_digit_str(rec["scale"]), "fotm": rec["fractal"]} for rec in RECOMMENDED_FRACTALS[fotm_index]],
                icon_align = "right",
            ),
        )

    # Render
    if len(screens) == 0:
        return []

    return render.Root(
        child = render.Sequence(children = screens),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_dailies",
                name = "Daily T4s",
                desc = "Show today's Daily T4 Fractals",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "show_recs",
                name = "Recommended Fractals",
                desc = "Show today's Recommended Fractals",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "highlight_cm",
                name = "Highlight CMs",
                desc = "Display T4 fractals with challenge modes in red font.",
                icon = "skullCrossbones",
                default = True,
            ),
        ],
    )
