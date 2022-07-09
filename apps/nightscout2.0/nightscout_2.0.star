"""
Applet: Nightscout 2.0
Summary: Shows Nightscout CGM Data
Description: Displays Continuous Glucose Monitoring (CGM) data from the Nightscout Open Source project (https://nightscout.github.io/).
Author: Jeremy Tavener, Paul Murphy
"""


load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("re.star", "re")
load("humanize.star", "humanize")
    
COLOR_RED = "#C00"
COLOR_DARK_RED = "#911"
COLOR_YELLOW = "#ff8"
COLOR_ORANGE = "#d61"
COLOR_GREEN = "#2b3"
COLOR_GREY = "#777"
COLOR_WHITE = "#fff"

DEFAULT_NORMAL_HIGH = 180
DEFAULT_NORMAL_LOW = 100
DEFAULT_URGENT_HIGH = 200
DEFAULT_URGENT_LOW = 70

DEFAULT_SHOW_GRAPH = True
GRAPH_WIDTH = 41

CACHE_TTL_SECONDS = 60

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

DEFAULT_NSID = ""

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    nightscout_id = config.get("nightscout_id", DEFAULT_NSID)
    normal_high = int(config.get("normal_high", DEFAULT_NORMAL_HIGH))
    normal_low = int(config.get("normal_low", DEFAULT_NORMAL_LOW))
    urgent_high = int(config.get("urgent_high", DEFAULT_URGENT_HIGH))
    urgent_low = int(config.get("urgent_low", DEFAULT_URGENT_LOW))
    show_graph = config.get("show_graph", DEFAULT_SHOW_GRAPH)


    if nightscout_id != None:
        nightscout_data_json, status_code = get_nightscout_data(nightscout_id)
    else:
        nightscout_data_json, status_code = EXAMPLE_DATA, 0

    if status_code == 503:
        print("Page not found for nightscout ID '" + nightscout_id + "' - is this ID correct?")
        return display_failure("Page not found for nightscout ID '" + nightscout_id + "' - is this ID correct?")
    elif status_code > 200:
        return display_failure("Failed to retieve the Nightscout details with status " + str(status_code))

    # Pull the data from the cache
    sgv_current = int(nightscout_data_json["sgv_current"])
    sgv_delta = int(nightscout_data_json["sgv_delta"])
    latest_reading_dt = time.parse_time(nightscout_data_json["latest_reading_date_string"])
    trend = nightscout_data_json["trend"]
    direction = nightscout_data_json["direction"]
    history = nightscout_data_json["history"]
    
    graph_data = []
        
    for reading in history:
        graph_data.append(tuple((reading[0], reading[1] - urgent_low)))

    print (history)
    
    reading_mins_ago = int((time.now().in_location("UTC") - latest_reading_dt).minutes)
    print (reading_mins_ago)
    # reading_mins_ago = 22
    
    if (reading_mins_ago < 1):
        human_reading_ago = "< 1 min ago"
    else:
        human_reading_ago = (humanize.relative_time(time.now().in_location("UTC"),latest_reading_dt, "from now", "ago")).replace("ute", "")
    
    print (human_reading_ago)
    
    if (reading_mins_ago < 6):
        ago_dashes = "-"*reading_mins_ago
    else:
        ago_dashes = str(reading_mins_ago) + "min"
    
    print (ago_dashes)
    
    # Used for finding the icon later. Default state is yellow to make the logic easier
    font_color = COLOR_YELLOW
    color_str = "Yellow"

    if (reading_mins_ago > 5):
        # The information is stale (i.e. over 5 minutes old) - overrides everything.
        color_str = "Grey"
        font_color = COLOR_GREY
        direction = "Dash"
    elif (sgv_current <= normal_high and sgv_current >= normal_low):
        # We're in the normal range, so use green.
        font_color = COLOR_GREEN
        color_str = "Green"
    elif (sgv_current >= urgent_high or sgv_current <= urgent_low):
        # We're in the urgent range, so use red.
        font_color = COLOR_RED
        color_str = "Red"
    
    # Delta
    str_delta = str(sgv_delta)
    if (sgv_delta < 1):
        str_delta = str_delta
    else:
        str_delta = "+" + str_delta


    if show_graph == "False":
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
                            children = [
                                render.Row(
                                cross_align = "center",
                                main_align = "space_evenly",
                                expanded = True,
                                children = [
                                 render.Text(
                                    content = str(int(sgv_current)),
                                    font = "6x13",
                                    color = font_color,
                                ),
                                render.Text(
                                    content = str_delta,
                                    font = "tom-thumb",
                                    color = COLOR_GREY,
                                    offset = -1,
                                ),
                                render.Text(
                                    content = ARROWS[direction],
                                    font = "6x13",
                                    color = font_color,
                                    offset = 1,
                                ),
                                ]),
                                render.Text(
                                    content = human_reading_ago,
                                    font = "CG-pixel-3x5-mono",
                                    color = COLOR_GREY,
                                ),
                                render.Animation(
                                    children = [
                                        render.Text(
                                            content = now.format("3:04 PM"),
                                            font = "6x13",
                                            color = COLOR_ORANGE,
                                        ),
                                        render.Text(
                                            content = now.format("3 04 PM"),
                                            font = "6x13",
                                            color = COLOR_ORANGE,
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
    else:
        history_min = min(history,key=lambda x:x[1])[1]
        history_max = max(history,key=lambda x:x[1])[1]
        left_row_width = 20

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
                                            color = font_color,
                                            width = left_row_width,
                                            align = "center",
                                        ),
                                    ]
                                ),
                                render.Row(
                                    children = [
                                        render.Text(
                                            content = str_delta,
                                            font = "tom-thumb",
                                            color = COLOR_GREY,
                                            offset = 0,
                                        ),
                                        render.Text(
                                            content = ARROWS[direction],
                                            font = "5x8",
                                            color = font_color,
                                            offset = 2,
                                        ),
                                    ]
                                ),
                                render.Row(
                                    children = [
                                        render.Animation(
                                            children = [
                                                render.WrappedText(
                                                    content = now.format("3:04"),
                                                    font = "tom-thumb",
                                                    color = COLOR_ORANGE,
                                                    width = left_row_width,
                                                    align = "center"
                                                ),
                                                render.WrappedText(
                                                    content = now.format("3 04"),
                                                    font = "tom-thumb",
                                                    color = COLOR_ORANGE,
                                                    width = left_row_width,
                                                    align = "center"
                                                ),
                                            ],
                                        ),
                                    ]
                                ),
                                render.Row(
                                    children = [
                                        render.WrappedText(
                                        content = ago_dashes,
                                        font = "tom-thumb",
                                        color = COLOR_GREY,
                                        width = left_row_width,
                                        align = "center"
                                    ),
                                    ]
                                ),
                            ]
                        ),
                        
                        render.Column(
                            cross_align = "start",
                            main_align = "start",
                            expanded = False,
                            children = [
                                render.Stack(
                                    children=[
                                        render.Plot(
                                          data = [
                                            (0,normal_low - urgent_low),
                                            (1,normal_low - urgent_low),
                                            ],
                                          width = GRAPH_WIDTH,
                                          height = 32,
                                          color = COLOR_GREY,
                                          color_inverted = COLOR_GREY,
                                          fill = False,
                                          x_lim = (0, 1),
                                          y_lim = (40 - urgent_low, 250 - urgent_low),
                                        ),
                                        render.Plot(
                                          data = [
                                            (0,normal_high - urgent_low),
                                            (1,normal_high - urgent_low),
                                            ],
                                          width = GRAPH_WIDTH,
                                          height = 32,
                                          color = COLOR_GREY,
                                          color_inverted = COLOR_GREY,
                                          fill = False,
                                          x_lim = (0, 1),
                                          y_lim = (40 - urgent_low, 250 - urgent_low),
                                        ),
                                        render.Plot(
                                          data = graph_data,
                                          width = GRAPH_WIDTH,
                                          height = 32,
                                          color = COLOR_GREEN,
                                          color_inverted = COLOR_RED,
                                          fill = False,
                                          x_lim = (0, GRAPH_WIDTH-1),
                                          y_lim = (40 - urgent_low, 250 - urgent_low),
                                        ),
                                     ],
                                )
                                
                               ],
                        ),
                    ],
                ),
            ),
            delay = 500,
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "place",
            ),
            schema.Text(
                id = "nightscout_id",
                name = "Nightscout URL",
                desc = "Your Nightscout URL (i.e. abc123.herokuapp.com)",
                icon = "user",
            ),
            schema.Text(
                id = "normal_high",
                name = "Normal High Threshold",
                desc = "Anything above this is displayed yellow unless it is above the Urgent High Threshold (default " + str(DEFAULT_NORMAL_HIGH) + ")",
                icon = "inputNumeric",
            ),
            schema.Text(
                id = "normal_low",
                name = "Normal Low Threshold",
                desc = "Anything below this is displayed yellow unless it is below the Urgent Low Threshold (default " + str(DEFAULT_NORMAL_LOW) + ")",
                icon = "inputNumeric",
            ),
            schema.Text(
                id = "urgent_high",
                name = "Urgent High Threshold",
                desc = "Anything above this is displayed red (Default " + str(DEFAULT_URGENT_HIGH) + ")",
                icon = "inputNumeric",
            ),
            schema.Text(
                id = "urgent_low",
                name = "Urgent Low Threshold",
                desc = "Anything below this is displayed red (Default " + str(DEFAULT_URGENT_LOW) + ")",
                icon = "inputNumeric",
            ),
            schema.Text(
                id = "show_graph",
                name = "Show Graph",
                desc = "Show graph along with reading",
                icon = "inputNumeric",
            ),
        ],
    )

# This method returns a tuple of a nightscout_data and a status_code. If it's
# served from cache, we return a status_code of 0.
def get_nightscout_data(nightscout_id):
    key = nightscout_id + "_nightscout_data"

    # Get the JSON object from the cache
    nightscout_data_cached = cache.get(key)
    if nightscout_data_cached != None:
        print("Hit - displaying cached data")
        return json.decode(nightscout_data_cached), 0

    # If it's not in the cache, construct it from a response.
    print("Miss - calling Nightscout API")
    nightscout_url = "https://" + nightscout_id + "/api/v1/entries.json?count="+str(GRAPH_WIDTH)
    print(nightscout_url)
    # Request latest entries from the Nightscout URL
    resp = http.get(nightscout_url)
    if resp.status_code != 200:
        return {}, resp.status_code

    latest_reading = resp.json()[0]
    previous_reading = resp.json()[1]
    latest_reading_date_string = latest_reading["dateString"]
    latest_reading_dt = time.parse_time(latest_reading_date_string)

    # Current sgv value
    sgv_current = latest_reading["sgv"]

    # Delta between the current and previous
    sgv_delta = int(sgv_current - previous_reading["sgv"])
    
    # Get the trend
    trend = latest_reading["trend"]
    direction = latest_reading["direction"]
    
    print ("%d %d %s" % (sgv_current, sgv_delta, ARROWS[direction]))
    
    history = []

    for x in range(GRAPH_WIDTH):
        history.append(tuple((x, int(resp.json()[GRAPH_WIDTH-1-x]["sgv"]))))

    print (history)
    
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
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
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
    "sgv_current": "333",
    "sgv_delta": "-4",
    "latest_reading_date_string": time.now().format("2006-01-02T15:04:05.999999999Z07:00"),
    "trend": "0",
    "direction": "Flat",
}