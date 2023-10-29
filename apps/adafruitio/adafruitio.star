"""
Applet: AdafruitIO
Summary: Display AdafruitIO Feed
Description: Show value or graph of various Adafruit IO Feeds.
Author: tavdog
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

TTL_SECONDS = 300  # 5 minutes
DEFAULT_USER = ""
DEFAULT_KEY = ""
DEFAULT_FEED_ID = ""
JSON_DUMMY_DATA = """{
    "feed": {
        "id": 2635718,
        "name": "Sensor Voltage",
        "key": "mesh.gh-temp"
    },
    "parameters": {
        "start_time": "2023-10-25T23:19:40Z",
        "end_time": "2023-10-26T00:19:40Z",
        "hours": 1,
        "field": "avg"
    },
    "columns": [
        "date",
        "value"
    ],
    "storage": "raw",
    "data": [
        [
            "2023-10-25T23:25:04Z",
            "4.200011253357"
        ],
        [
            "2023-10-25T23:55:04Z",
            "3.74000000953674"
        ],
        [
            "2023-10-26T00:10:04Z",
            "3.54900007247925"
        ],
        [
            "2023-10-26T00:10:04Z",
            "4.04900007247925"
        ]
    ]
}"""
YELLOW = "#ffff00"  # Firefly palette color
GREEN = "#ADFF2F"  # Firefly palette color
ORANGE = "#FF4500"  # Firefly palette color
BLUE = "#0000FF"  # Firefly palette color
RED = "#FF0000"

def main(config):
    username = config.str("username", DEFAULT_USER)
    key = config.str("key", DEFAULT_KEY)
    feed_id = config.str("feed_id", DEFAULT_FEED_ID)
    hours = int(config.get("hours_history", 24))
    feed = get_feed(username, key, feed_id, hours)

    # check for feed2
    feed2 = None
    if config.get("feed2_id", None):
        feed2 = get_feed(username, key, config.get("feed2_id"), hours)

    #print(feed)

    if "error" in feed or (feed2 and "error" in feed2):  # if we have error key, then we display an error
        #debug_print("buoy_id: " + str(buoy_id))
        error_dict = dict()
        if ("error" in feed):
            error_dict = feed
        if (feed2 and "error" in feed2):
            error_dict = feed2
        error_string = error_dict["error"].split("-")[1]
        if ("username" in error_string or "invalid" in error_string):
            error_message = error_string
        else:
            error_message = "Feed not found"
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = [
                        render.Text(
                            content = "AIO Error",
                            font = "tb-8",
                            color = RED,
                        ),
                        render.WrappedText(
                            content = error_message,
                            font = "tb-8",
                            color = ORANGE,
                        ),
                        # render.Text(
                        #     content = "not found",
                        #     color = ORANGE,
                        # ),
                    ],
                ),
            ),
        )

    else:
        #FEED
        # build the feed_graph
        feed_graph = None
        print(feed)
        if config.bool("display_graph") and len(feed["data"]) > 3:  # only make the graph if we have more than 3 points
            # interate through the points and convert to float and stick them an array
            points = []
            for i in range(len(feed["data"])):
                points.append((i, float(feed["data"][i][1])))
            print("points " + str(points))
            y_lim = (None, None)
            min_max = config.get("y_min_max", None)
            if min_max and "," in min_max:
                (min, max) = min_max.split(",")
                y_lim = (float(min), float(max))
            feed_graph = render.Plot(
                data = points,
                width = 64,
                height = 32,
                color = config.str("graph_color", "#00c"),
                y_lim = y_lim,
            )

        # build feed2_graph
        feed2_graph = None
        if config.bool("display_graph2") and feed2 and len(feed2["data"]) > 3:  # only make the graph if we have more than 3 points
            # interate through the points and convert to float and stick them an array
            points = []
            for i in range(len(feed2["data"])):
                points.append((i, float(feed2["data"][i][1])))
            print("points " + str(points))
            y2_lim = (None, None)
            min_max = config.get("y2_min_max", None)
            if min_max and "," in min_max:
                (min, max) = min_max.split(",")
                y2_lim = (float(min), float(max))
            feed2_graph = render.Plot(
                data = points,
                width = 64,
                height = 32,
                color = config.str("graph2_color", "#00c"),
                y_lim = y2_lim,
            )
        if feed2:
            data_line = render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(
                        content = str(round(float(feed["data"][-1][1]), 1)) + config.get("feed_units", "") + " ",
                        font = "6x13",
                        color = config.str("feed_color", None) or ORANGE,
                    ),
                    render.Text(
                        content = str(round(float(feed2["data"][-1][1]), 1)) + config.get("feed2_units", ""),
                        font = "6x13",
                        color = config.str("feed2_color", None) or BLUE,
                    ),
                ],
            )
        else:  # just one data item
            data_line = render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(
                        content = str(round(float(feed["data"][-1][1]), 2)) + config.get("feed_units", ""),
                        font = "6x13",
                        color = config.str("feed_color", None) or ORANGE,
                    ),
                ],
            )

        return render.Root(
            child = render.Stack(
                children = [
                    feed_graph,
                    feed2_graph,
                    render.Box(
                        render.Column(
                            expanded = True,
                            main_align = "space_around",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "center",
                                    children = [
                                        render.WrappedText(
                                            content = config.str("feed_name", None) or feed["feed"]["name"],
                                            font = "tb-8",
                                            color = config.str("feed_color", None) or GREEN,
                                        ),
                                    ],
                                ),
                                data_line,
                            ],
                        ),
                    ),
                ],
            ),
        )

def get_feed(username, key, feed_id, hours):
    if not username or not key or not feed_id:
        return json.decode(JSON_DUMMY_DATA)

    # load the feed from adafruit io
    # curl -H "X-AIO-Key: {io_key}" 'https://io.adafruit.com/api/v2/{username}/feeds/{feed_key}/data/chart?hours=1'

    url = "https://io.adafruit.com/api/v2/%s/feeds/%s/data/chart?hours=%s" % (username, feed_id, hours)
    print("url:", url)
    res = http.get(url, headers = {"X-AIO-Key": key}, ttl_seconds = TTL_SECONDS)
    feed = res.json()
    print("feed is :" + str(feed))
    if ("data" in feed and len(feed["data"]) == 0):
        print("pulling bare data feed")

        url = "https://io.adafruit.com/api/v2/%s/feeds/%s/data" % (username, feed_id)
        print("url:", url)
        res = http.get(url, headers = {"X-AIO-Key": key}, ttl_seconds = TTL_SECONDS)
        dfeed = res.json()
        print("new feed is : " + str(dfeed))
        feed["data"] = [["0", dfeed[-1]["value"]]]

    return feed

def get_schema():
    fields = []
    fields.append(
        schema.Text(
            id = "username",
            name = "Username",
            desc = "AIO username",
            icon = "user",
        ),
    )
    fields.append(
        schema.Text(
            id = "key",
            name = "AIO Key",
            desc = "AIO Acess Key",
            icon = "key",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed_id",
            name = "Feed",
            desc = "AIO Feed",
            icon = "user",
        ),
    )
    fields.append(
        schema.Color(
            id = "feed_color",
            name = "Color",
            desc = "Feed Color",
            icon = "brush",
            default = "#7AB0FF",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed_name",
            name = "Feed Name",
            icon = "user",
            desc = "Optional Custom Label",
            default = "",
        ),
    )

    fields.append(
        schema.Text(
            id = "feed_units",
            name = "Feed Units",
            icon = "quoteRight",
            desc = "Feed height units preference",
        ),
    )
    fields.append(
        schema.Toggle(
            id = "display_graph",
            name = "Display Graph",
            desc = "A toggle to display the graph data in the background",
            icon = "compress",
            default = True,
        ),
    )
    fields.append(
        schema.Color(
            id = "graph_color",
            name = "Graph Color",
            desc = "Graph Color",
            icon = "brush",
            default = "#7AB0FF",
        ),
    )

    fields.append(
        schema.Text(
            id = "hours_history",
            name = "Graph history hours",
            desc = "",
            icon = "compress",
            default = "",
        ),
    )
    fields.append(
        schema.Text(
            id = "y_min_max",
            name = "Graph min,max",
            desc = "Scale the graph by setting min and max. Leave blank to disable",
            icon = "compress",
            default = "",
        ),
    )

    # fields.append(
    #     schema.Text(
    #         id = "y_min",
    #         name = "Graph min",
    #         desc = "Scale the graph by setting a minimum. Leave blank to disable",
    #         icon = "compress",
    #         default = "",
    #     ),
    #)
    fields.append(
        schema.Text(
            id = "feed2_id",
            name = "Feed 2",
            desc = "AIO Feed",
            icon = "user",
        ),
    )
    fields.append(
        schema.Color(
            id = "feed2_color",
            name = "Feed 2 Color",
            desc = "Feed Color",
            icon = "brush",
            default = "#7AB0FF",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed2_name",
            name = "Feed 2 Name",
            icon = "user",
            desc = "Optional Custom Label",
            default = "",
        ),
    )
    fields.append(
        schema.Text(
            id = "feed2_units",
            name = "Feed 2 Units",
            icon = "quoteRight",
            desc = "Feed height units preference",
        ),
    )
    fields.append(
        schema.Toggle(
            id = "display_graph2",
            name = "Show Graph 2",
            desc = "A toggle to display the graph data in the background",
            icon = "compress",
            default = False,
        ),
    )
    fields.append(
        schema.Color(
            id = "graph2_color",
            name = "Graph 2 Color",
            desc = "Graph 2 Color",
            icon = "brush",
            default = "#7AB0FF",
        ),
    )
    fields.append(
        schema.Text(
            id = "y2_min_max",
            name = "Graph 2 min,max",
            desc = "Scale the graph by setting min and max. Leave blank to disable",
            icon = "compress",
            default = "",
        ),
    )

    return schema.Schema(
        version = "1",
        fields = fields,
    )

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)
