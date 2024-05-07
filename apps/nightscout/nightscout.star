"""
Applet: Nightscout
Summary: Displays Nightscout CGM Data
Description: Displays Continuous Glucose Monitoring (CGM) blood sugar data (BG, Trend, Delta, IOB, COB) from Nightscout. Will display blood sugar as mg/dL or mmol/L. Optionally display historical readings on a graph. Also a clock.
For support, join the Nightscout for Tidbyt Facebook group.
(v2.5.1)
Authors: Paul Murphy, Jason Hanson, Jeremy Tavener
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

COLOR_BLACK = "#000"
COLOR_PINK = "#F8A7A7"
COLOR_RED = "#C00"
COLOR_DARK_RED = "#911"
COLOR_BRIGHT_RED = "#F10404"
COLOR_YELLOW = "#ff8"
COLOR_ORANGE = "#d61"
COLOR_GREEN = "#2b3"
COLOR_BRIGHT_GREEN = "#03FF20"
COLOR_DARK_GREEN = "#087C15"
COLOR_BLUE = "#00D0FF"
COLOR_DARK_BLUE = "#0676FF"
COLOR_PURPLE = "#009"
COLOR_MAGENTA = "#FF00D0"
COLOR_GREY = "#777"
COLOR_WHITE = "#fff"
COLOR_NIGHT = "#444"
COLOR_HOURS = "#222"

DEFAULT_DISPLAY_UNIT = "mgdl"
DEFAULT_NORMAL_HIGH = 180
DEFAULT_NORMAL_LOW = 100
DEFAULT_URGENT_HIGH = 200
DEFAULT_URGENT_LOW = 70

DEFAULT_SHOW_GRAPH = True
DEFAULT_SHOW_GRAPH_HOUR_BARS = True
DEFAULT_GRAPH_HEIGHT = 300
DEFAULT_CLOCK_OPTION = "Clock"
DEFAULT_ID_BORDER_COLOR = COLOR_BLACK
DEFAULT_SHOW_24_HOUR_TIME = False
DEFAULT_NIGHT_MODE = False
GRAPH_BOTTOM = 40

CACHE_TTL_SECONDS = 1800  #30 mins

DEFAULT_LOCATION = """
{
    "lat": "40.666250",
    "lng": "-111.910780",
    "description": "Taylorsville, UT, USA",
    "locality": "Taylorsville",
    "place_id": "ChIJ_wlEps6LUocRJ9DmE4xv9OI",
    "timezone": "America/Denver"
}
"""

DEFAULT_NSID = ""
DEFAULT_NSHOST = ""
DEFAULT_NSURL = ""
DEFAULT_NSTOKEN = ""

def main(config):
    print("---START---")
    UTC_TIME_NOW = time.now().in_location("UTC")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    now = time.now().in_location(loc["timezone"])
    lat, lng = float(loc["lat"]), float(loc["lng"])
    sun_rise = sunrise.sunrise(lat, lng, now)
    sun_set = sunrise.sunset(lat, lng, now)
    nightscout_id = config.get("nightscout_id", DEFAULT_NSID)
    nightscout_host = config.get("nightscout_host", DEFAULT_NSHOST)
    nightscout_url = config.get("nightscout_url", DEFAULT_NSURL)
    nightscout_token = config.get("nightscout_token", DEFAULT_NSTOKEN)
    show_graph = config.bool("show_graph", DEFAULT_SHOW_GRAPH)
    show_graph_hour_bars = config.bool("show_graph_hour_bars", DEFAULT_SHOW_GRAPH_HOUR_BARS)

    # for backward compatibilty
    if (config.bool("show_clock") == True):
        DEFAULT_CLOCK_OPTION = "Clock"
    else:
        DEFAULT_CLOCK_OPTION = "None"

    if (config.bool("show_mgdl") == True):
        DEFAULT_DISPLAY_UNIT = "mgdl"
    else:
        DEFAULT_DISPLAY_UNIT = "mmol"

    display_unit = config.get("display_unit", DEFAULT_DISPLAY_UNIT)
    clock_option = config.get("clock_option", DEFAULT_CLOCK_OPTION)
    id_border_color = config.get("id_border_color", DEFAULT_ID_BORDER_COLOR)
    show_24_hour_time = config.bool("show_24_hour_time", DEFAULT_SHOW_24_HOUR_TIME)
    night_mode = config.bool("night_mode", DEFAULT_NIGHT_MODE)
    nightscout_iob = "n/a"
    nightscout_cob = "n/a"

    if nightscout_url == "" and nightscout_id != "" and nightscout_host != "":
        nightscout_url = nightscout_id + "." + nightscout_host

    print(nightscout_url)

    if nightscout_url != "":
        sample_data = False

        nightscout_data, status_code = get_nightscout_data(nightscout_url, nightscout_token, show_graph, display_unit)

        if status_code == 503:
            print("Page not found for nightscout ID '" + nightscout_id + "' - is this ID correct?")
            return display_failure("Page not found for nightscout ID '" + nightscout_id + "' - is this ID correct?")
        elif status_code > 200:
            return display_failure("Nightscout Error: " + str(status_code))
    else:
        nightscout_data, status_code = {
            "api_version": "n/a",
            "sgv_current": "85",
            "sgv_delta": "-2" if display_unit == "mgdl" else float("-0.1"),
            "latest_reading_date_string": (time.now() - time.parse_duration("3m")),
            "direction": "Flat",
            "iob": "0.00u",
            "cob": "0.0g",
            "history": [
                ((time.now() - time.parse_duration("213m")).unix, 125),
                ((time.now() - time.parse_duration("208m")).unix, 130),
                ((time.now() - time.parse_duration("203m")).unix, 135),
                ((time.now() - time.parse_duration("198m")).unix, 132),
                ((time.now() - time.parse_duration("193m")).unix, 131),
                ((time.now() - time.parse_duration("188m")).unix, 137),
                ((time.now() - time.parse_duration("183m")).unix, 142),
                ((time.now() - time.parse_duration("178m")).unix, 147),
                ((time.now() - time.parse_duration("173m")).unix, 155),
                ((time.now() - time.parse_duration("168m")).unix, 160),
                ((time.now() - time.parse_duration("163m")).unix, 172),
                ((time.now() - time.parse_duration("158m")).unix, 184),
                ((time.now() - time.parse_duration("153m")).unix, 175),
                ((time.now() - time.parse_duration("148m")).unix, 170),
                ((time.now() - time.parse_duration("143m")).unix, 167),
                ((time.now() - time.parse_duration("138m")).unix, 156),
                ((time.now() - time.parse_duration("133m")).unix, 152),
                ((time.now() - time.parse_duration("128m")).unix, 140),
                ((time.now() - time.parse_duration("123m")).unix, 137),
                ((time.now() - time.parse_duration("118m")).unix, 129),
                ((time.now() - time.parse_duration("113m")).unix, 121),
                ((time.now() - time.parse_duration("108m")).unix, 118),
                ((time.now() - time.parse_duration("103m")).unix, 113),
                ((time.now() - time.parse_duration("98m")).unix, 108),
                ((time.now() - time.parse_duration("93m")).unix, 106),
                ((time.now() - time.parse_duration("88m")).unix, 104),
                ((time.now() - time.parse_duration("83m")).unix, 101),
                ((time.now() - time.parse_duration("78m")).unix, 97),
                ((time.now() - time.parse_duration("73m")).unix, 95),
                ((time.now() - time.parse_duration("68m")).unix, 93),
                ((time.now() - time.parse_duration("63m")).unix, 91),
                ((time.now() - time.parse_duration("58m")).unix, 87),
                ((time.now() - time.parse_duration("53m")).unix, 87),
                ((time.now() - time.parse_duration("48m")).unix, 85),
                ((time.now() - time.parse_duration("43m")).unix, 84),
                ((time.now() - time.parse_duration("38m")).unix, 83),
                ((time.now() - time.parse_duration("33m")).unix, 80),
                ((time.now() - time.parse_duration("28m")).unix, 83),
                ((time.now() - time.parse_duration("23m")).unix, 88),
                ((time.now() - time.parse_duration("18m")).unix, 90),
                ((time.now() - time.parse_duration("13m")).unix, 88),
                ((time.now() - time.parse_duration("8m")).unix, 87),
                ((time.now() - time.parse_duration("3m")).unix, 85),
            ],
        }, 0
        sample_data = True

    # Pull the data from the cache
    sgv_current_mgdl = int(nightscout_data["sgv_current"])
    sgv_delta = nightscout_data["sgv_delta"]
    if nightscout_data["api_version"] == "v1":
        latest_reading_dt = time.parse_time(nightscout_data["latest_reading_date_string"])
    else:
        latest_reading_dt = nightscout_data["latest_reading_date_string"]
    direction = nightscout_data["direction"]
    nightscout_iob = nightscout_data["iob"]
    nightscout_cob = nightscout_data["cob"]
    history = nightscout_data["history"]
    api_version = nightscout_data["api_version"]
    print("api_version: ", api_version)

    #sgv_delta_mgdl = 25
    #sgv_current_mgdl = 420
    print("display_unit:", display_unit)
    if display_unit == "mgdl":
        graph_height = int(str(config.get("mgdl_graph_height", DEFAULT_GRAPH_HEIGHT)))
        normal_high = int(str(config.get("mgdl_normal_high", DEFAULT_NORMAL_HIGH)))
        normal_low = int(str(config.get("mgdl_normal_low", DEFAULT_NORMAL_LOW)))
        urgent_high = int(str(config.get("mgdl_urgent_high", DEFAULT_URGENT_HIGH)))
        urgent_low = int(str(config.get("mgdl_urgent_low", DEFAULT_URGENT_LOW)))
        str_current = str(int(sgv_current_mgdl))

        # Delta
        str_delta = str(int(sgv_delta))
        print("int(sgv_delta): ", int(sgv_delta))
        if (int(sgv_delta) >= 0):
            str_delta = "+" + str_delta
            print("str_delta: ", str_delta)
        left_col_width = 28
        graph_width = 34
    else:
        graph_height = int(float(config.get("mmol_graph_height", mgdl_to_mmol(DEFAULT_GRAPH_HEIGHT))) * 18)
        normal_high = int(float(config.get("mmol_normal_high", mgdl_to_mmol(DEFAULT_NORMAL_HIGH))) * 18)
        normal_low = int(float(config.get("mmol_normal_low", mgdl_to_mmol(DEFAULT_NORMAL_LOW))) * 18)
        urgent_high = int(float(config.get("mmol_urgent_high", mgdl_to_mmol(DEFAULT_URGENT_HIGH))) * 18)
        urgent_low = int(float(config.get("mmol_urgent_low", mgdl_to_mmol(DEFAULT_URGENT_LOW))) * 18)

        sgv_current = mgdl_to_mmol(sgv_current_mgdl)
        str_current = str(sgv_current)

        str_delta = str(sgv_delta)
        if (str_delta == "0.0"):
            str_delta = "+0"
        elif (sgv_delta > 0):
            str_delta = "+" + str_delta

        left_col_width = 28
        graph_width = 34

    OLDEST_READING_TARGET = UTC_TIME_NOW - time.parse_duration(str(5 * graph_width) + "m")

    #for reading in history:
    #graph_data.append(tuple((reading[0], reading[1] - urgent_low)))
    reading_mins_ago = int((UTC_TIME_NOW - latest_reading_dt).minutes)
    print("time:", UTC_TIME_NOW)
    print("latest_reading_dt:", latest_reading_dt)
    print("oldest_reading_target:", OLDEST_READING_TARGET)
    print("reading_mins_ago:", reading_mins_ago)

    if (reading_mins_ago < 1):
        human_reading_ago = "< 1 min ago"
    elif (reading_mins_ago == 1):
        human_reading_ago = "1 min ago"
    else:
        human_reading_ago = str(reading_mins_ago) + " mins ago"

    print("human_reading_ago:", human_reading_ago)

    ago_dashes = "-" * reading_mins_ago
    full_ago_dashes = ago_dashes

    # Default state is yellow to make the logic easier
    color_reading = COLOR_YELLOW
    color_delta = COLOR_YELLOW
    color_arrow = COLOR_YELLOW
    color_ago = COLOR_GREY
    color_graph_urgent_high = COLOR_RED
    color_graph_high = COLOR_YELLOW
    color_graph_normal = COLOR_GREEN
    color_graph_low = COLOR_YELLOW
    color_graph_urgent_low = COLOR_RED
    color_graph_lines = COLOR_GREY
    color_clock = COLOR_ORANGE
    color_id_border = id_border_color

    if (reading_mins_ago > 5):
        # The information is stale (i.e. over 5 minutes old) - overrides everything.
        color_reading = COLOR_GREY
        color_delta = COLOR_GREY
        color_arrow = COLOR_GREY
        color_ago = COLOR_GREY
        direction = "None"
        str_delta = "old"
        ago_dashes = ">" + str(reading_mins_ago)
        full_ago_dashes = human_reading_ago
    elif (sgv_current_mgdl <= normal_high and sgv_current_mgdl >= normal_low):
        # We're in the normal range, so use green.
        color_reading = COLOR_GREEN
        color_delta = COLOR_GREEN
        color_arrow = COLOR_GREEN
    elif (sgv_current_mgdl >= urgent_high or sgv_current_mgdl <= urgent_low):
        # We're in the urgent range, so use red.
        color_reading = COLOR_RED
        color_delta = COLOR_RED
        color_arrow = COLOR_RED
    print("night_mode:", night_mode)
    if (night_mode and (now > sun_set or now < sun_rise)):
        color_reading = COLOR_NIGHT
        color_delta = COLOR_NIGHT
        color_arrow = COLOR_NIGHT
        color_ago = COLOR_NIGHT
        color_graph_urgent_high = COLOR_NIGHT
        color_graph_high = COLOR_NIGHT
        color_graph_normal = COLOR_NIGHT
        color_graph_low = COLOR_NIGHT
        color_graph_urgent_low = COLOR_NIGHT
        color_graph_lines = COLOR_NIGHT
        color_clock = COLOR_NIGHT

    if clock_option == "Clock":
        lg_string = [
            render.Stack(
                children = [
                    render.Box(
                        height = 32,
                        width = 64,
                        color = color_id_border,
                        child = render.Box(
                            height = 30,
                            width = 62,
                            color = COLOR_BLACK,
                        ),
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(height = 1),
                            render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                    render.Animation(
                                        children = [
                                            render.Text(
                                                content = now.format("15:04" if show_24_hour_time else "3:04 PM"),
                                                font = "6x13",
                                                color = color_clock,
                                            ),
                                            render.Text(
                                                content = now.format("15 04" if show_24_hour_time else "3 04 PM"),
                                                font = "6x13",
                                                color = color_clock,
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(height = 13),
                            render.Row(
                                cross_align = "center",
                                main_align = "center",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = str_current,
                                        font = "6x13",
                                        color = color_reading,
                                    ),
                                    render.Text(
                                        content = " " + str_delta.replace("0", "O"),
                                        font = "tb-8",
                                        color = color_delta,
                                        offset = -1,
                                    ),
                                    render.Text(
                                        content = " " + ARROWS[direction],
                                        font = "tb-8",
                                        color = color_arrow,
                                        offset = -1,
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(height = 26),
                            render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = full_ago_dashes,
                                        font = "tom-thumb",
                                        color = color_ago,
                                        offset = 0,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ]

        sm_string = [
            render.WrappedText(
                content = now.format("15:04" if show_24_hour_time else "3:04"),
                font = "tom-thumb",
                color = color_clock,
                width = left_col_width,
                align = "center",
            ),
            render.WrappedText(
                content = now.format("15 04" if show_24_hour_time else "3 04"),
                font = "tom-thumb",
                color = color_clock,
                width = left_col_width,
                align = "center",
            ),
        ]

    elif clock_option == "IOB" or clock_option == "COB":
        lg_string = [
            render.Stack(
                children = [
                    render.Box(
                        height = 32,
                        width = 64,
                        color = color_id_border,
                        child = render.Box(
                            height = 30,
                            width = 62,
                            color = COLOR_BLACK,
                        ),
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(height = 1),
                            render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                    render.Animation(
                                        children = [
                                            render.Text(
                                                content = nightscout_iob if clock_option == "IOB" else nightscout_cob,
                                                font = "6x13",
                                                color = color_clock,
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(height = 13),
                            render.Row(
                                cross_align = "center",
                                main_align = "center",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = str_current,
                                        font = "6x13",
                                        color = color_reading,
                                    ),
                                    render.Text(
                                        content = " " + str_delta.replace("0", "O"),
                                        font = "tb-8",
                                        color = color_delta,
                                        offset = -1,
                                    ),
                                    render.Text(
                                        content = " " + ARROWS[direction],
                                        font = "tb-8",
                                        color = color_arrow,
                                        offset = -1,
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(height = 26),
                            render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = full_ago_dashes,
                                        font = "tom-thumb",
                                        color = color_ago,
                                        offset = 0,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ]

        sm_string = [
            render.WrappedText(
                content = nightscout_iob if clock_option == "IOB" else nightscout_cob,
                font = "tom-thumb",
                color = color_clock,
                width = left_col_width,
                align = "center",
            ),
        ]
    else:
        lg_string = [
            render.Stack(
                children = [
                    render.Box(
                        height = 32,
                        width = 64,
                        color = color_id_border,
                        child = render.Box(
                            height = 30,
                            width = 62,
                            color = COLOR_BLACK,
                        ),
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = str_current,
                                        font = "10x20",
                                        color = color_reading,
                                        offset = 1,
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(height = 15),
                            render.Row(
                                cross_align = "center",
                                main_align = "center",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = str_delta.replace("0", "O"),
                                        font = "6x13",
                                        color = color_delta,
                                        offset = 0,
                                    ),
                                    render.Text(
                                        content = " " + ARROWS[direction],
                                        font = "tb-8",
                                        color = color_arrow,
                                        offset = 0,
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(height = 26),
                            render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = full_ago_dashes,
                                        font = "tom-thumb",
                                        color = color_ago,
                                        offset = 0,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ]

        sm_string = [
            render.Box(
                width = left_col_width,
                height = 6,
            ),
        ]

    if not show_graph:
        output = [
            render.Box(
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Column(
                            cross_align = "center",
                            main_align = "space_between",
                            expanded = True,
                            children = lg_string,
                        ),
                    ],
                ),
            ),
        ]
    else:
        # high and low lines
        graph_plot = []
        graph_hour_bars = []
        min_time = OLDEST_READING_TARGET.unix

        # the rest of the graph
        for point in range(graph_width):
            max_time = min_time + 299
            this_point = 0
            for history_point in history:
                if (min_time <= history_point[0] and history_point[0] <= max_time):
                    this_point = history_point[1]

            #print(this_point)
            if this_point < GRAPH_BOTTOM and this_point > 0:
                this_point = GRAPH_BOTTOM

            if this_point > graph_height:
                this_point = graph_height

            graph_point_color = color_graph_normal

            if this_point > normal_high:
                graph_point_color = color_graph_high

            if this_point > urgent_high:
                graph_point_color = color_graph_urgent_high

            if this_point < normal_low:
                graph_point_color = color_graph_low

            if this_point < urgent_low:
                graph_point_color = color_graph_urgent_low

            if show_graph_hour_bars:
                min_hour = time.from_timestamp(min_time, 0).hour
                max_hour = time.from_timestamp(max_time, 0).hour
                if min_hour != max_hour:
                    # Add hour marker at this point
                    graph_hour_bars.append(render.Padding(
                        pad = (point, 0, 0, 0),
                        child = render.Box(
                            width = 1,
                            height = 30,
                            color = COLOR_HOURS,
                        ),
                    ))

            graph_plot.append(
                render.Plot(
                    data = [
                        (0, this_point),
                        (1, this_point),
                    ],
                    width = 1,
                    height = 30,
                    color = graph_point_color,
                    color_inverted = graph_point_color,
                    fill = False,
                    x_lim = (0, 1),
                    y_lim = (GRAPH_BOTTOM, graph_height),
                ),
            )

            min_time = max_time + 1

        output = [
            render.Stack(
                children = [
                    render.Box(
                        height = 32,
                        width = 64,
                        color = color_id_border,
                        child =
                            render.Box(
                                height = 30,
                                width = 62,
                                color = COLOR_BLACK,
                            ),
                    ),
                    render.Box(
                        height = 32,
                        width = 64,
                        child =
                            render.Box(
                                render.Row(
                                    main_align = "center",
                                    cross_align = "start",
                                    expanded = True,
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(
                                                    width = 1,
                                                    height = 32,
                                                ),
                                            ],
                                        ),
                                        render.Column(
                                            cross_align = "center",
                                            expanded = True,
                                            children = [
                                                render.Row(
                                                    children = [
                                                        render.WrappedText(
                                                            content = str_current,
                                                            font = "6x13",
                                                            color = color_reading,
                                                            width = left_col_width,
                                                            height = 12,
                                                            align = "center",
                                                        ),
                                                    ],
                                                ),
                                                render.Row(
                                                    children = [
                                                        render.Text(
                                                            content = str_delta.replace("0", "O"),
                                                            font = "tb-8",
                                                            color = color_delta,
                                                            offset = 1,
                                                        ),
                                                        render.Box(
                                                            height = 1,
                                                            width = 1,
                                                        ),
                                                        render.Text(
                                                            content = ARROWS[direction],
                                                            font = "5x8",
                                                            color = color_arrow,
                                                            offset = 1,
                                                        ),
                                                    ],
                                                ),
                                                render.Row(
                                                    children = [
                                                        render.Animation(
                                                            sm_string,
                                                        ),
                                                    ],
                                                ),
                                                render.Row(
                                                    main_align = "start",
                                                    cross_align = "start",
                                                    children = [
                                                        render.WrappedText(
                                                            content = full_ago_dashes,
                                                            font = "tom-thumb",
                                                            color = color_ago,
                                                            width = left_col_width,
                                                            align = "center",
                                                        ),
                                                    ],
                                                ),
                                            ],
                                        ),
                                        render.Column(
                                            cross_align = "start",
                                            main_align = "start",
                                            expanded = False,
                                            children = [
                                                render.Box(
                                                    height = 1,
                                                    width = graph_width,
                                                ),
                                                render.Stack(
                                                    children = [
                                                        render.Stack(
                                                            children = graph_hour_bars,
                                                        ),
                                                        render.Plot(
                                                            data = [
                                                                (0, normal_low),
                                                                (1, normal_low),
                                                            ],
                                                            width = graph_width,
                                                            height = 30,
                                                            color = color_graph_lines,
                                                            color_inverted = color_graph_lines,
                                                            fill = False,
                                                            x_lim = (0, 1),
                                                            y_lim = (GRAPH_BOTTOM, graph_height),
                                                        ),
                                                        render.Plot(
                                                            data = [
                                                                (0, normal_high),
                                                                (1, normal_high),
                                                            ],
                                                            width = graph_width,
                                                            height = 30,
                                                            color = color_graph_lines,
                                                            color_inverted = color_graph_lines,
                                                            fill = False,
                                                            x_lim = (0, 1),
                                                            y_lim = (GRAPH_BOTTOM, graph_height),
                                                        ),
                                                        render.Row(
                                                            main_align = "start",
                                                            cross_align = "start",
                                                            expanded = True,
                                                            children = graph_plot,
                                                        ),
                                                    ],
                                                ),
                                            ],
                                        ),
                                    ],
                                ),
                            ),
                    ),
                ],
            ),
        ]

    if sample_data == True:
        output = [
            render.Stack(
                children = [
                    render.Row(
                        children = output,
                    ),
                    render.Animation(
                        children = [
                            render.WrappedText(
                                width = 64,
                                align = "center",
                                font = "10x20",
                                color = "#f00",
                                linespacing = -6,
                                content = "SAMPLE DATA",
                            ),
                            render.Box(),
                        ],
                    ),
                ],
            ),
        ]

    #    print (output)
    print("---END---")
    return render.Root(
        max_age = 120,
        child = render.Row(
            children = output,
        ),
        delay = 500,
    )

def display_unit_options(display_unit):
    if display_unit == "mgdl":
        graph_height = DEFAULT_GRAPH_HEIGHT
        normal_high = DEFAULT_NORMAL_HIGH
        normal_low = DEFAULT_NORMAL_LOW
        urgent_high = DEFAULT_URGENT_HIGH
        urgent_low = DEFAULT_URGENT_LOW
        unit = "mg/dL"
    else:
        graph_height = mgdl_to_mmol(DEFAULT_GRAPH_HEIGHT)
        normal_high = mgdl_to_mmol(DEFAULT_NORMAL_HIGH)
        normal_low = mgdl_to_mmol(DEFAULT_NORMAL_LOW)
        urgent_high = mgdl_to_mmol(DEFAULT_URGENT_HIGH)
        urgent_low = mgdl_to_mmol(DEFAULT_URGENT_LOW)
        unit = "mmol/L"

    return [
        schema.Text(
            id = display_unit + "_graph_height",
            name = "Graph Height",
            desc = "Height of Graph (in " + unit + ") (Default " + str(graph_height) + ")",
            icon = "rulerVertical",
            default = str(graph_height),
        ),
        schema.Text(
            id = display_unit + "_normal_high",
            name = "Normal High Threshold (in " + unit + ")",
            desc = "Anything above this is displayed yellow unless it is above the Urgent High Threshold (default " + str(normal_high) + ")",
            icon = "droplet",
            default = str(normal_high),
        ),
        schema.Text(
            id = display_unit + "_normal_low",
            name = "Normal Low Threshold (in " + unit + ")",
            desc = "Anything below this is displayed yellow unless it is below the Urgent Low Threshold (default " + str(normal_low) + ")",
            icon = "droplet",
            default = str(normal_low),
        ),
        schema.Text(
            id = display_unit + "_urgent_high",
            name = "Urgent High Threshold (in " + unit + ")",
            desc = "Anything above this is displayed red (Default " + str(urgent_high) + ")",
            icon = "droplet",
            default = str(urgent_high),
        ),
        schema.Text(
            id = display_unit + "_urgent_low",
            name = "Urgent Low Threshold (in " + unit + ")",
            desc = "Anything below this is displayed red (Default " + str(urgent_low) + ")",
            icon = "droplet",
            default = str(urgent_low),
        ),
    ]

def get_schema():
    clock_options = [
        schema.Option(
            display = "None",
            value = "None",
        ),
        schema.Option(
            display = "Clock",
            value = "Clock",
        ),
        schema.Option(
            display = "Insulin on Board",
            value = "IOB",
        ),
        schema.Option(
            display = "Carbs on Board",
            value = "COB",
        ),
    ]

    unit_options = [
        schema.Option(
            display = "mg/dL",
            value = "mgdl",
        ),
        schema.Option(
            display = "mmol/L",
            value = "mmol",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "nightscout_url",
                name = "Nightscout URL",
                desc = "Your Nightscout URL (i.e. yournightscoutID.heroku.com)",
                icon = "link",
            ),
            schema.Text(
                id = "nightscout_token",
                name = "Nightscout Token",
                desc = "Token for Nightscout Subject with 'readable' Role (optional)",
                icon = "key",
            ),
            schema.Color(
                id = "id_border_color",
                name = "ID Border Color",
                desc = "Color of the border. Used for differentiating between multiple T1D's in a household",
                icon = "idBadge",
                default = COLOR_BLACK,
                palette = [
                    COLOR_BLACK,
                    COLOR_WHITE,
                    COLOR_GREY,
                    COLOR_RED,
                    COLOR_DARK_RED,
                    COLOR_PINK,
                    COLOR_ORANGE,
                    COLOR_YELLOW,
                    COLOR_BRIGHT_GREEN,
                    COLOR_GREEN,
                    COLOR_DARK_GREEN,
                    COLOR_BLUE,
                    COLOR_DARK_BLUE,
                    COLOR_PURPLE,
                    COLOR_MAGENTA,
                    COLOR_BRIGHT_RED,
                ],
            ),
            schema.Dropdown(
                id = "display_unit",
                name = "Unit of Measure (mg/dL or mmol/L)",
                desc = "Select unit of measure to display readings and delta (mg/dL or mmol/L)",
                icon = "droplet",
                default = unit_options[0].value,
                options = unit_options,
            ),
            schema.Toggle(
                id = "show_graph",
                name = "Show Graph",
                desc = "Show graph along with reading",
                icon = "chartLine",
                default = True,
            ),
            schema.Toggle(
                id = "show_graph_hour_bars",
                name = "Show Graph Hours",
                desc = "Show hour makings on the graph",
                icon = "chartColumn",
                default = DEFAULT_SHOW_GRAPH_HOUR_BARS,
            ),
            schema.Generated(
                id = "graph_options",
                source = "display_unit",
                handler = display_unit_options,
            ),
            schema.Dropdown(
                id = "clock_option",
                name = "Show Clock/IOB/COB",
                desc = "Show Clock, Insulin on Board, or Carbs on Board along with reading",
                icon = "gear",
                default = clock_options[1].value,
                options = clock_options,
            ),
            schema.Toggle(
                id = "show_24_hour_time",
                name = "Show 24 Hour Time",
                desc = "Show 24 hour time format",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "night_mode",
                name = "Night Mode",
                desc = "Dim display between sunset and sunrise",
                icon = "moon",
                default = False,
            ),
        ],
    )

# This method returns a tuple of a nightscout_data and a status_code.
def get_nightscout_data(nightscout_url, nightscout_token, show_graph, display_unit):
    nightscout_url = nightscout_url.replace("https://", "")
    nightscout_url = nightscout_url.replace("http://", "")
    nightscout_url = nightscout_url.split("/")[0]

    json_url = "https://" + nightscout_url + "/api/v2/properties/bgnow,iob,delta,direction,cob"
    headers = {}
    if nightscout_token != "":
        headers["Api-Secret"] = hash.sha1(nightscout_token)

    print(json_url)

    # Request latest properties from the Nightscout URL
    resp = http.get(json_url, headers = headers)
    print("resp.status_code:", resp.status_code)
    if resp.status_code != 200:
        # Fall back to v1
        print("v2:properties failed, falling back to v1")
        return get_nightscout_data_v1(nightscout_url, nightscout_token, display_unit)
    ns_properties = resp.json()

    sgv_current = ""
    sgv_delta = ""
    latest_reading_date_string = ""
    direction = ""
    iob = "n/a"
    cob = "n/a"
    nightsout_history = []

    if "bgnow" in ns_properties:
        if "last" in ns_properties["bgnow"]:
            sgv_current = str(int(ns_properties["bgnow"]["last"]))
        if "mills" in ns_properties["bgnow"]:
            latest_reading_date_string = ns_properties["bgnow"]["mills"]
            latest_reading_date_string = time.from_timestamp(int(int(latest_reading_date_string) / 1000))
    if "delta" in ns_properties:
        if "absolute" in ns_properties["delta"]:
            sgv_delta = ns_properties["delta"]["absolute"]
            sgv_delta = int(sgv_delta)
            if display_unit == "mmol":
                sgv_delta = mgdl_to_mmol(int(sgv_delta))
    if "direction" in ns_properties:
        if "value" in ns_properties["direction"]:
            direction = ns_properties["direction"]["value"]
    if "iob" in ns_properties:
        if "display" in ns_properties["iob"]:
            iob = str(ns_properties["iob"]["display"]) + "u"
    if "cob" in ns_properties:
        if "display" in ns_properties["cob"]:
            cob = str(ns_properties["cob"]["display"]) + "g"

    if show_graph:
        nightsout_history, status = get_nightscout_history(nightscout_url, nightscout_token)
        if status != 200:
            print("v2:entries - History call failed")
            nightsout_history = []

    nightscout_data = {
        "api_version": "v2",
        "sgv_current": sgv_current,
        "sgv_delta": sgv_delta,
        "latest_reading_date_string": latest_reading_date_string,
        "direction": direction,
        "iob": iob,
        "cob": cob,
        "history": nightsout_history,
    }

    # Check required fields, if they are blank fall back to v1
    if nightscout_data["sgv_current"] == "" or nightscout_data["sgv_delta"] == "" or nightscout_data["latest_reading_date_string"] == "" or nightscout_data["direction"] == "":
        # Fall back to v1
        print("v2 fields missing, falling back to v1")
        return get_nightscout_data_v1(nightscout_url, nightscout_token, display_unit)
    elif show_graph and nightscout_data["history"] == []:
        # Fall back to v1
        print("v2 history missing, falling back to v1")
        return get_nightscout_data_v1(nightscout_url, nightscout_token, display_unit)

    return nightscout_data, resp.status_code

# Used with v2, just to get the history
def get_nightscout_history(nightscout_url, nightscout_token):
    nightscout_url = nightscout_url.replace("https://", "")
    nightscout_url = nightscout_url.replace("http://", "")
    nightscout_url = nightscout_url.split("/")[0]
    oldest_reading = str((time.now() - time.parse_duration("240m")).unix)
    json_url = "https://" + nightscout_url + "/api/v2/entries.json?count=200&find[date][$gte]=" + oldest_reading
    headers = {}
    if nightscout_token != "":
        headers["Api-Secret"] = hash.sha1(nightscout_token)

    print(json_url)

    key = nightscout_url + "_nightscout_data"

    # Request latest entries from the Nightscout URL
    resp = http.get(json_url, headers = headers)
    if resp.status_code != 200:
        # If Error, Get the JSON object from the cache
        nightscout_data_cached = cache.get(key)
        if nightscout_data_cached != None:
            print("NS Error - displaying cached data")
            return json.decode(nightscout_data_cached), 0

        # If it's not in the cache, return the NS error.
        print("NS Error - Display Error")

        return {}, resp.status_code

    history = []

    for x in resp.json():
        if "sgv" in x:
            history.append(tuple((int(int(x["date"]) / 1000), int(x["sgv"]))))

    return history, resp.status_code

# Fall back function for v1 API
def get_nightscout_data_v1(nightscout_url, nightscout_token, display_unit):
    nightscout_url = nightscout_url.replace("https://", "")
    nightscout_url = nightscout_url.replace("http://", "")
    nightscout_url = nightscout_url.split("/")[0]
    oldest_reading = str((time.now() - time.parse_duration("240m")).unix)
    json_url = "https://" + nightscout_url + "/api/v1/entries.json?count=200&find[date][$gte]=" + oldest_reading
    headers = {}
    if nightscout_token != "":
        headers["Api-Secret"] = hash.sha1(nightscout_token)

    print(json_url)

    key = nightscout_url + "_nightscout_data"

    # Request latest entries from the Nightscout URL
    resp = http.get(json_url, headers = headers)
    if resp.status_code != 200:
        # If Error, Get the JSON object from the cache
        nightscout_data_cached = cache.get(key)
        if nightscout_data_cached != None:
            print("NS Error - displaying cached data")
            return json.decode(nightscout_data_cached), 0

        # If it's not in the cache, return the NS error.
        print("NS Error - Display Error")

        return {}, resp.status_code

    latest_reading = resp.json()[0]
    previous_reading = resp.json()[1]

    latest_reading_date_string = latest_reading["dateString"]

    # Current sgv value
    sgv_current = latest_reading["sgv"]

    # Delta between the current and previous
    if display_unit == "mgdl":
        sgv_delta = int(sgv_current - previous_reading["sgv"])
    else:
        sgv_delta = math.round((mgdl_to_mmol(int(sgv_current)) - mgdl_to_mmol(int(previous_reading["sgv"]))) * 10) / 10
        print("sgv_delta:" + str(sgv_delta))

    # Get the direction
    direction = latest_reading["direction"] if "direction" in latest_reading else "None"
    history = []

    for x in resp.json():
        if "sgv" in x:
            history.append(tuple((int(int(x["date"]) / 1000), int(x["sgv"]))))

    nightscout_data = {
        "api_version": "v1",
        "sgv_current": str(int(sgv_current)),
        "sgv_delta": sgv_delta,
        "latest_reading_date_string": latest_reading_date_string,
        "direction": direction,
        "history": history,
        "iob": "n/a",
        "cob": "n/a",
    }

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(key, json.encode(nightscout_data), ttl_seconds = CACHE_TTL_SECONDS)

    return nightscout_data, resp.status_code

def mgdl_to_mmol(mgdl):
    mmol = float(math.round((mgdl / 18) * 10) / 10)
    return mmol

def display_failure(msg):
    return render.Root(
        max_age = 120,
        child = render.WrappedText(
            width = 64,
            content = msg,
            color = COLOR_NIGHT,
            font = "tom-thumb",
        ),
    )

ARROWS = {
    "None": "",
    "NONE": "",
    "DoubleDown": "↓↓",
    "DoubleUp": "↑↑",
    "Flat": "→",
    "FortyFiveDown": "↘",
    "FortyFiveUp": "↗",
    "SingleDown": "↓",
    "SingleUp": "↑",
    "Error": "?",
    "Dash": "-",
    "NOT COMPUTABLE": "?",
}
