"""
Applet: Nightscout
Summary: Shows Nightscout CGM Data
Description: Displays Continuous Glucose Monitoring (CGM) data from the Nightscout Open Source project (https://nightscout.github.io/).
Authors: Jeremy Tavener, Paul Murphy
"""

load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("encoding/csv.star", "csv")
load("cache.star", "cache")
load("schema.star", "schema")
load("re.star", "re")
load("humanize.star", "humanize")
load("sunrise.star", "sunrise")

COLOR_RED = "#C00"
COLOR_DARK_RED = "#911"
COLOR_YELLOW = "#ff8"
COLOR_ORANGE = "#d61"
COLOR_GREEN = "#2b3"
COLOR_GREY = "#777"
COLOR_WHITE = "#fff"
COLOR_NIGHT = "#444"

DEFAULT_NORMAL_HIGH = 180
DEFAULT_NORMAL_LOW = 100
DEFAULT_URGENT_HIGH = 200
DEFAULT_URGENT_LOW = 70

DEFAULT_SHOW_GRAPH = "true"
DEFAULT_SHOW_CLOCK = "true"
DEFAULT_NIGHT_MODE = "false"
GRAPH_WIDTH = 43
GRAPH_BOTTOM = 50
GRAPH_TOP = 275

CACHE_TTL_SECONDS = 1800  #30 mins

PROVIDER_CACHE_TTL = 7200  #2 hours
NS_PROVIDERS = "https://raw.githubusercontent.com/IsThisPaul/TidBytCommunity/Nightscout-Provider-File/apps/nightscout/nightscout_providers.csv"

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

def get_providers():
    # Check cache for providers
    providers = cache.get("ns_providers")

    # If no cached providers, fetch from server
    if providers == None:
        request = http.get(NS_PROVIDERS)
        if request.status_code != 200:
            print("Unexpected status code: " + request.status_code)
            return ["Heroku", "herokuapp.com"]

        providers = request.body()
        cache.set("nightscout_providers", providers, ttl_seconds = PROVIDER_CACHE_TTL)
    return csv.read_all(providers)

def main(config):
    UTC_TIME_NOW = time.now().in_location("UTC")
    OLDEST_READING_TARGET = UTC_TIME_NOW - time.parse_duration(str(5 * GRAPH_WIDTH) + "m")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    now = time.now().in_location(loc["timezone"])
    lat, lng = float(loc["lat"]), float(loc["lng"])
    sun_rise = sunrise.sunrise(lat, lng, now)
    sun_set = sunrise.sunset(lat, lng, now)
    nightscout_id = config.get("nightscout_id", DEFAULT_NSID)
    nightscout_host = config.get("nightscout_host", DEFAULT_NSHOST)
    normal_high = int(config.get("normal_high", DEFAULT_NORMAL_HIGH))
    normal_low = int(config.get("normal_low", DEFAULT_NORMAL_LOW))
    urgent_high = int(config.get("urgent_high", DEFAULT_URGENT_HIGH))
    urgent_low = int(config.get("urgent_low", DEFAULT_URGENT_LOW))
    show_graph = config.get("show_graph", DEFAULT_SHOW_GRAPH)
    show_clock = config.get("show_clock", DEFAULT_SHOW_CLOCK)
    night_mode = config.get("night_mode", DEFAULT_NIGHT_MODE)

    if nightscout_id != None:
        nightscout_data_json, status_code = get_nightscout_data(nightscout_id, nightscout_host)
    else:
        nightscout_data_json, status_code = EXAMPLE_DATA, 0

    if status_code == 503:
        print("Page not found for nightscout ID '" + nightscout_id + "' - is this ID correct?")
        return display_failure("Page not found for nightscout ID '" + nightscout_id + "' - is this ID correct?")
    elif status_code > 200:
        return display_failure("Nightscout Error: " + str(status_code))

    # Pull the data from the cache
    sgv_current = int(nightscout_data_json["sgv_current"])
    sgv_delta = int(nightscout_data_json["sgv_delta"])
    latest_reading_dt = time.parse_time(nightscout_data_json["latest_reading_date_string"])
    trend = nightscout_data_json["trend"]
    direction = nightscout_data_json["direction"]
    history = nightscout_data_json["history"]

    # Delta
    str_delta = str(sgv_delta)
    if (sgv_delta < 0):
        str_delta = str_delta
    else:
        str_delta = "+" + str_delta

    #for reading in history:
    #graph_data.append(tuple((reading[0], reading[1] - urgent_low)))
    reading_mins_ago = int((UTC_TIME_NOW - latest_reading_dt).minutes)
    print("time:", UTC_TIME_NOW)
    print("latest_reading_dt:", latest_reading_dt)
    print("oldest_reading_target:", OLDEST_READING_TARGET)
    print(reading_mins_ago)

    if (reading_mins_ago < 1):
        human_reading_ago = "< 1 min ago"
    elif (reading_mins_ago == 1):
        human_reading_ago = "1 min ago"
    else:
        human_reading_ago = str(reading_mins_ago) + " mins ago"

    print(human_reading_ago)

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
    font_color = COLOR_YELLOW

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
    elif (sgv_current <= normal_high and sgv_current >= normal_low):
        # We're in the normal range, so use green.
        color_reading = COLOR_GREEN
        color_delta = COLOR_GREEN
        color_arrow = COLOR_GREEN
    elif (sgv_current >= urgent_high or sgv_current <= urgent_low):
        # We're in the urgent range, so use red.
        color_reading = COLOR_RED
        color_delta = COLOR_RED
        color_arrow = COLOR_RED
    print(night_mode)
    if (night_mode == "true" and (now > sun_set or now < sun_rise)):
        print("Night Mode")
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

    print(ago_dashes)

    if show_clock == "true":
        lg_clock = [
            render.Stack(
                children = [
                    render.Box(height = 32, width = 64),
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
                                        content = str(int(sgv_current)),
                                        font = "6x13",
                                        color = color_reading,
                                    ),
                                    render.Text(
                                        content = str_delta,
                                        font = "tom-thumb",
                                        color = color_delta,
                                        offset = -1,
                                    ),
                                    render.Text(
                                        content = ARROWS[direction],
                                        font = "6x13",
                                        color = color_arrow,
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
                            render.Box(height = 13),
                            render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                    render.Animation(
                                        children = [
                                            render.Text(
                                                content = now.format("3:04 PM"),
                                                font = "6x13",
                                                color = color_clock,
                                            ),
                                            render.Text(
                                                content = now.format("3 04 PM"),
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

        left_col_width = 20

        sm_clock = [
            render.WrappedText(
                content = now.format("3:04"),
                font = "tom-thumb",
                color = color_clock,
                width = left_col_width,
                align = "center",
            ),
            render.WrappedText(
                content = now.format("3 04"),
                font = "tom-thumb",
                color = color_clock,
                width = left_col_width,
                align = "center",
            ),
        ]
    else:
        lg_clock = [
            render.Stack(
                children = [
                    render.Box(height = 32, width = 64),
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
                                        content = str(int(sgv_current)),
                                        font = "10x20",
                                        color = color_reading,
                                        offset = 1,
                                    ),
                                    render.Text(
                                        content = str_delta,
                                        font = "6x13",
                                        color = color_delta,
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
                            render.Box(height = 11),
                            render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = ARROWS[direction],
                                        font = "10x20",
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

        left_col_width = 20

        sm_clock = [
            render.Box(
                width = left_col_width,
                height = 6,
            ),
        ]

    if show_graph == "false":
        return render.Root(
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
                            children = lg_clock,
                        ),
                    ],
                ),
            ),
            delay = 500,
        )
    else:
        # high and low lines
        graph_plot = []
        min_time = OLDEST_READING_TARGET.unix

        # the rest of the graph
        for point in range(GRAPH_WIDTH):
            max_time = min_time + 299
            this_point = 0
            for history_point in history:
                if (min_time <= history_point[0] and history_point[0] <= max_time):
                    this_point = history_point[1]

            print(this_point)
            if this_point < GRAPH_BOTTOM and this_point > 0:
                this_point = GRAPH_BOTTOM

            if this_point > GRAPH_TOP:
                this_point = GRAPH_TOP

            graph_point_color = color_graph_normal

            if this_point > normal_high:
                graph_point_color = color_graph_high

            if this_point > urgent_high:
                graph_point_color = color_graph_urgent_high

            if this_point < normal_low:
                graph_point_color = color_graph_low

            if this_point < urgent_low:
                graph_point_color = color_graph_urgent_low

            graph_plot.append(
                render.Plot(
                    data = [
                        (0, this_point),
                        (1, this_point),
                    ],
                    width = 1,
                    height = 32,
                    color = graph_point_color,
                    color_inverted = graph_point_color,
                    fill = False,
                    x_lim = (0, 1),
                    y_lim = (GRAPH_BOTTOM, GRAPH_TOP),
                ),
            )

            min_time = max_time + 1

        return render.Root(
            render.Box(
                render.Row(
                    main_align = "center",
                    cross_align = "start",
                    expanded = True,
                    children = [
                        render.Column(
                            cross_align = "center",
                            expanded = True,
                            children = [
                                render.Row(
                                    children = [
                                        render.WrappedText(
                                            content = str(int(sgv_current)),
                                            font = "6x13",
                                            color = color_reading,
                                            width = left_col_width,
                                            align = "center",
                                        ),
                                    ],
                                ),
                                render.Row(
                                    children = [
                                        render.Text(
                                            content = str_delta,
                                            font = "tom-thumb",
                                            color = color_delta,
                                            offset = -1,
                                        ),
                                        render.Box(
                                            height = 1,
                                            width = 1,
                                            color = "#000",
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
                                            sm_clock,
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
                                render.Stack(
                                    children = [
                                        render.Plot(
                                            data = [
                                                (0, normal_low),
                                                (1, normal_low),
                                            ],
                                            width = GRAPH_WIDTH,
                                            height = 32,
                                            color = color_graph_lines,
                                            color_inverted = color_graph_lines,
                                            fill = False,
                                            x_lim = (0, 1),
                                            y_lim = (GRAPH_BOTTOM, GRAPH_TOP),
                                        ),
                                        render.Plot(
                                            data = [
                                                (0, normal_high),
                                                (1, normal_high),
                                            ],
                                            width = GRAPH_WIDTH,
                                            height = 32,
                                            color = color_graph_lines,
                                            color_inverted = color_graph_lines,
                                            fill = False,
                                            x_lim = (0, 1),
                                            y_lim = (GRAPH_BOTTOM, GRAPH_TOP),
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
            delay = 500,
        )

def get_schema():
    providers = get_providers()

    hostOptions = []

    for index in range(0, len(providers)):
        hostOptions.append(
            schema.Option(
                display = providers[index][0],
                value = providers[index][1],
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "nightscout_host",
                name = "Nightscout Provider",
                desc = "Your Nightscout Provider",
                icon = "gear",
                default = hostOptions[0].value,
                options = hostOptions,
            ),
            schema.Text(
                id = "nightscout_id",
                name = "Nightscout ID",
                desc = "Your Nightscout ID (i.e. [nightscoutID].heroku.com)",
                icon = "gear",
            ),
            schema.Text(
                id = "normal_high",
                name = "Normal High Threshold",
                desc = "Anything above this is displayed yellow unless it is above the Urgent High Threshold (default " + str(DEFAULT_NORMAL_HIGH) + ")",
                icon = "hashtag",
                default = str(DEFAULT_NORMAL_HIGH),
            ),
            schema.Text(
                id = "normal_low",
                name = "Normal Low Threshold",
                desc = "Anything below this is displayed yellow unless it is below the Urgent Low Threshold (default " + str(DEFAULT_NORMAL_LOW) + ")",
                icon = "hashtag",
                default = str(DEFAULT_NORMAL_LOW),
            ),
            schema.Text(
                id = "urgent_high",
                name = "Urgent High Threshold",
                desc = "Anything above this is displayed red (Default " + str(DEFAULT_URGENT_HIGH) + ")",
                icon = "hashtag",
                default = str(DEFAULT_URGENT_HIGH),
            ),
            schema.Text(
                id = "urgent_low",
                name = "Urgent Low Threshold",
                desc = "Anything below this is displayed red (Default " + str(DEFAULT_URGENT_LOW) + ")",
                icon = "hashtag",
                default = str(DEFAULT_URGENT_LOW),
            ),
            schema.Toggle(
                id = "show_graph",
                name = "Show Graph",
                desc = "Show graph along with reading",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "show_clock",
                name = "Show Clock",
                desc = "Show clock along with reading",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "night_mode",
                name = "Night Mode",
                desc = "Dim display between sunset and sunrise",
                icon = "gear",
                default = False,
            ),
        ],
    )

# This method returns a tuple of a nightscout_data and a status_code. If it's
# served from cache, we return a status_code of 0.
def get_nightscout_data(nightscout_id, nightscout_host):
    key = nightscout_id + "." + nightscout_host + "_nightscout_data"

    nightscout_url = "https://" + nightscout_id + "." + nightscout_host + "/api/v1/entries.json?count=100"

    print(nightscout_url)

    # Request latest entries from the Nightscout URL
    resp = http.get(nightscout_url)
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

    #print (latest_reading)
    #print (previous_reading)
    latest_reading_date_string = latest_reading["dateString"]
    latest_reading_dt = time.parse_time(latest_reading_date_string)

    # Current sgv value
    sgv_current = latest_reading["sgv"]

    # Delta between the current and previous
    sgv_delta = int(sgv_current - previous_reading["sgv"])

    # Get the trend
    trend = latest_reading["trend"]
    direction = latest_reading["direction"]

    print("%d %d %s" % (sgv_current, sgv_delta, ARROWS[direction]))

    history = []

    for x in resp.json():
        history.append(tuple((int(int(x["date"]) / 1000), int(x["sgv"]))))
        #print (x["dateString"])
        #print (str(int(x["date"] / 1000)) + ":" + str(int(x["sgv"])))

    #print (history)

    nightscout_data = {
        "sgv_current": str(int(sgv_current)),
        "sgv_delta": str(int(sgv_delta)),
        "latest_reading_date_string": latest_reading_date_string,
        "trend": trend,
        "direction": direction,
        "history": history,
    }

    cache.set(key, json.encode(nightscout_data), ttl_seconds = CACHE_TTL_SECONDS)

    return nightscout_data, resp.status_code

def display_failure(msg):
    return render.Root(
        child = render.WrappedText(
            width = 64,
            content = msg,
            color = COLOR_NIGHT,
            font = "tom-thumb",
        ),
    )

ARROWS = {
    "None": "",
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

EXAMPLE_DATA = {
    "sgv_current": "85",
    "sgv_delta": "-2",
    "latest_reading_date_string": time.now().format("2006-01-02T15:04:05.999999999Z07:00"),
    "trend": "0",
    "direction": "Flat",
    "history": [(1658171112, 141), (1658170812, 133), (1658170512, 129), (1658170212, 125), (1658169912, 121), (1658169612, 116), (1658169312, 114), (1658169012, 109), (1658168712, 105), (1658168412, 103), (1658168112, 107), (1658167812, 114), (1658167512, 119), (1658167212, 123), (1658166912, 127), (1658166612, 126), (1658166312, 124), (1658166012, 108), (1658165712, 103), (1658165412, 100), (1658165112, 96), (1658164812, 93), (1658164512, 93), (1658164212, 95), (1658163911, 93), (1658163612, 92), (1658163311, 91), (1658163011, 87), (1658162712, 86), (1658162412, 87), (1658162112, 88), (1658161812, 87), (1658161512, 87), (1658161212, 85), (1658160912, 84), (1658160612, 83), (1658160312, 80), (1658160012, 83), (1658159712, 88), (1658159412, 90), (1658159111, 88), (1658158812, 87), (1658158512, 85)],
}
