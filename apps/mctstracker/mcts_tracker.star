"""
Applet: MCTS Tracker
Summary: Track MCTS buses
Description: View live tracking information for Milwaukee County Transit System buses. Note: it is recommended that you apply for an API key at https://realtime.ridemcts.com/bustime/newDeveloper.jsp.
Author: Josiah Winslow
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

WIDTH = 64
HEIGHT = 32

TTL_SECONDS_INFO = 60  # 1 minute
TTL_SECONDS_NAME = 60 * 60  # 1 hour
DEFAULT_STOP_ID = "743"

MCTS_ICON_WIDTH = 23
MCTS_ICON_HEIGHT = 32
MCTS_ICON = base64.decode("""
UklGRr4AAABXRUJQVlA4TLEAAAAvFsAHEKdgIG2bbVzmzV/CDaw2zLRtk3Sgxh/VvlVRI0lR73IbxH/
CFwmEFhAU+T9a/J2rAKoA5hOiSgoMbnFsGZj27k1CyA98qsYFjiRJchq2AQmzpmT+/9mdwcM5ov8TEP
dkrTFTy6dOMQJaC+yzZSUbkG3IR/5B3lK3YrBesj0pSPT9imEY2sYYwhRGz0V+hQM4GHwomZXGlnv8p
b/kSEj7bLvL77tJjBCXQzQ3e7oA
""")

INFO_COLOR = "#fff"
INFO_COLOR_NOKEY = "#f80"
ERROR_COLOR = "#f00"
BUS_COLORS = {
    "BLU": ("#21417e", "#fff"),
    "GOL": ("#fec110", "#332f2a"),
    "GRE": ("#008d75", "#fff"),
    "PUR": ("#543996", "#fff"),
    "RED": ("#c33529", "#fff"),
    "CN1": ("#0f4b91", "#fff"),
    "11": ("#039a01", "#fff"),
    "12": ("#93d400", "#fff"),
    "14": ("#0056b7", "#fff"),
    "15": ("#ff8400", "#fff"),
    "18": ("#01b3e3", "#fff"),
    "19": ("#ffd601", "#332f2a"),
    "20": ("#93d400", "#fff"),
    "21": ("#01b3e3", "#fff"),
    "22": ("#ec012c", "#fff"),
    "24": ("#a67cc6", "#fff"),
    "28": ("#ffd601", "#332f2a"),
    "30": ("#00af97", "#fff"),
    "31": ("#00b252", "#fff"),
    "33": ("#ec012c", "#fff"),
    "34": ("#a67cc6", "#fff"),
    "35": ("#863498", "#fff"),
    "40U": ("#008558", "#fff"),
    "44U": ("#008558", "#fff"),
    "49U": ("#008558", "#fff"),
    "51": ("#e30692", "#fff"),
    "52": ("#93d400", "#fff"),
    "53": ("#01b3e3", "#fff"),
    "54": ("#ec012c", "#fff"),
    "55": ("#ec012c", "#fff"),
    "56": ("#863498", "#fff"),
    "57": ("#0074cb", "#fff"),
    "58": ("#ff8400", "#fff"),
    "59": ("#21417e", "#fff"),
    "60": ("#ffd601", "#332f2a"),
    "63": ("#01b3e3", "#fff"),
    "66": ("#863498", "#fff"),
    "68": ("#93d400", "#fff"),
    "76": ("#b31782", "#fff"),
    "80": ("#e30692", "#fff"),
    "81": ("#ff8400", "#fff"),
    "88": ("#ff8400", "#fff"),
    "92": ("#b31782", "#fff"),
    "HF1": ("#c8c8c8", "#332f2a"),
    "HF2": ("#c8c8c8", "#332f2a"),
    "RR1": ("#0065fd", "#fff"),
    "RR2": ("#0000cb", "#fff"),
    "RR3": ("#039a01", "#fff"),
}

def get_stop_info_bustime(stop_id, api_key):
    url = (
        "https://realtime.ridemcts.com/bustime/api/v3/getpredictions?format=" +
        "json&key=%s&stpid=%s"
    ) % (api_key, stop_id)
    rep = http.get(url, ttl_seconds = TTL_SECONDS_INFO)
    if rep.status_code != 200:
        return {
            "error": "Bustime API status code: %s" % rep.status_code,
        }
    j = rep.json()

    # If response has an error
    if "error" in j["bustime-response"]:
        error = j["bustime-response"]["error"][0]
        message = error["msg"]

        # If error has stop ID associated with it
        if "stpid" in error:
            # This is probably something like "No arrival times"
            # NOTE In this case, the response will not contain the name
            # of the bus stop, so a backup method is used to get the
            # name.
            return {
                "name": get_stop_name_eta(stop_id),
                "info": message,
            }
        else:
            # Otherwise, this is an API error
            return {
                "error": message,
            }

    predictions = j["bustime-response"]["prd"]
    stop_info = {
        "name": predictions[0]["stpnm"],
        "buses": [],
    }

    # For each bus prediction
    for prd in predictions:
        # Only up to 4 can be displayed
        if len(stop_info["buses"]) >= 4:
            break

        # Route name for display
        bus_id = prd["rtdd"]

        # If prdctdn is a numeric string
        eta = prd["prdctdn"]
        if eta.isdigit():
            # It's an ETA in minutes
            bus_info = "%s MIN" % eta
        else:
            # Otherwise, it's a status like "DUE" or "DLY"
            bus_info = eta

        stop_info["buses"].append((bus_id, bus_info))

    return stop_info

def get_stop_info_eta(stop_id):
    url = (
        "https://realtime.ridemcts.com/bustime/eta/getStopPredictionsETA.jsp" +
        "?route=all&stop=%s"
    ) % stop_id
    rep = http.get(url, ttl_seconds = TTL_SECONDS_INFO)
    if rep.status_code != 200:
        return {
            "error": "ETA API status code: %s" % rep.status_code,
        }
    x = xpath.loads(rep.body())

    stop_name = get_stop_name_eta(stop_id)

    # If there is a message instead of a bus prediction, return it
    no_prediction_message = x.query("/stop/noPredictionMessage")
    if no_prediction_message != None:
        return {
            "name": stop_name,
            "info": no_prediction_message,
        }

    stop_info = {
        "name": stop_name,
        "buses": [],
    }

    # For each bus prediction
    for pre in x.query_all_nodes("/stop/pre"):
        # Only up to 4 can be displayed
        if len(stop_info["buses"]) >= 4:
            break

        # Route name for display
        bus_id = pre.query("rd")

        # "Prediction units"
        # NOTE: The units are almost always " MINUTES", but they can be
        # "APPROACHING" or "DELAYED" if the bus is in those states. It
        # can also be something like "3:04 PM SCH" if the bus is
        # scheduled to come later.
        pu = pre.query("pu")
        if pu == "APPROACHING":
            bus_info = "DUE"
        elif pu == "DELAYED":
            bus_info = "DLY"
        elif pu.endswith(" SCH"):
            pu = pu.removesuffix(" SCH")

            # Remove space, and remove "M" in "AM" or "PM"
            pu = pu.replace(" ", "").replace("M", "")
            bus_info = pu
        else:
            # Prediction time (in minutes)
            bus_info = "%s MIN" % pre.query("pt")

        stop_info["buses"].append((bus_id, bus_info))

    return stop_info

def get_stop_name_eta(stop_id):
    # Fallback stop name
    stop_name = "STOP %s" % stop_id

    # NOTE: This is the best way I know of to get a stop's name without
    # an API key. The webpage I request also has live tracking info, but
    # it's harder to parse.
    url = (
        "https://realtime.ridemcts.com/bustime/wireless/html/eta.jsp?route=" +
        "---&id=%s"
    ) % stop_id
    rep = http.get(url, ttl_seconds = TTL_SECONDS_NAME)
    if rep.status_code == 200:
        # Find stop name on page
        body = rep.body()
        stop_name_match = re.match(r"SELECTED STOP \| (.*?) \- ETA", body)
        if stop_name_match:
            stop_name = stop_name_match[0][1]

    return stop_name

def render_mcts_logo(stop_id = "MCTS"):
    return render.Stack(
        children = [
            # Bus logo, from MCTS bus stop signs
            render.Image(src = MCTS_ICON),
            # Stop ID
            render.Padding(
                pad = (1, MCTS_ICON_HEIGHT - 6, 0, 0),
                child = render.WrappedText(
                    content = stop_id,
                    font = "tom-thumb",
                    width = MCTS_ICON_WIDTH - 1,
                    color = "#332f2a",
                    align = "center",
                ),
            ),
        ],
    )

def render_stop_name_line(stop_name, has_api_key = False):
    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Marquee(
            offset_start = 0,
            offset_end = 0,
            width = WIDTH - MCTS_ICON_WIDTH,
            child = render.Text(
                content = stop_name,
                font = "tom-thumb",
                color = INFO_COLOR if has_api_key else INFO_COLOR_NOKEY,
            ),
        ),
    )

def render_bus_info_line(bus_id, bus_info):
    if bus_id in BUS_COLORS:
        # Get bus colors if they exist
        bg_color, fg_color = BUS_COLORS[bus_id]
    else:
        # Default is gray on white
        bg_color, fg_color = "#fff", "#332f2a"

    badge_width = 13
    info_width = WIDTH - MCTS_ICON_WIDTH - badge_width - 3

    return render.Padding(
        pad = (1, 1, 0, -1),
        child = render.Row(
            children = [
                # Bus ID badge
                render.Padding(
                    pad = (0, 0, 1, 0),
                    child = render.Box(
                        color = bg_color,
                        width = badge_width,
                        height = 6,
                        child = render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Text(
                                content = bus_id,
                                font = "tom-thumb",
                                color = fg_color,
                            ),
                        ),
                    ),
                ),
                # Bus info line
                render.Marquee(
                    offset_start = 0,
                    offset_end = 0,
                    width = info_width,
                    child = render.Text(
                        content = bus_info,
                        font = "tom-thumb",
                        color = INFO_COLOR,
                    ),
                ),
            ],
        ),
    )

def render_message(message, header = None, color = INFO_COLOR):
    children = []
    height = 0

    if header != None:
        # Add header if applicable
        children.append(render.Padding(
            pad = (1, 1, 1, 0),
            child = render.Text(
                content = header,
                font = "tom-thumb",
                color = INFO_COLOR,
            ),
        ))
        height += 7

    # Add message
    children.append(render.Marquee(
        height = HEIGHT - height,
        scroll_direction = "vertical",
        child = render.Padding(
            pad = 1,
            child = render.WrappedText(
                content = message,
                font = "tom-thumb",
                width = WIDTH - MCTS_ICON_WIDTH,
                color = color,
            ),
        ),
    ))

    return render.Column(children = children)

def render_app(stop_id, children):
    return render.Root(
        child = render.Row(
            children = [
                render_mcts_logo(stop_id),
                render.Column(children = children),
            ],
        ),
    )

def main(config):
    stop_id = config.get("stop", DEFAULT_STOP_ID)
    api_key = config.get("key", "")

    # If stop ID is not numeric
    if not stop_id.isdigit():
        return render_app("MCTS", [
            render_message(
                header = "CFG ERROR",
                message = "Invalid stop ID",
                color = ERROR_COLOR,
            ),
        ])

    # If API key is supplied
    if api_key:
        # Use Bustime API
        stop_info = get_stop_info_bustime(stop_id, api_key)
    else:
        # Otherwise, use fallback ETA API
        stop_info = get_stop_info_eta(stop_id)

    # If result has an error message
    if "error" in stop_info:
        return render_app(stop_id, [
            render_message(
                header = "APP ERROR",
                message = stop_info["error"],
                color = ERROR_COLOR,
            ),
        ])

    stop_name_line = None
    if "name" in stop_info:
        stop_name_line = render_stop_name_line(
            stop_info["name"],
            has_api_key = bool(api_key),
        )

    # If result has an info message
    if "info" in stop_info:
        return render_app(stop_id, [
            stop_name_line,
            render_message(stop_info["info"]),
        ])

    # Result has bus data
    return render_app(stop_id, [
        stop_name_line,
    ] + [
        render_bus_info_line(*bus_data)
        for bus_data in stop_info["buses"]
    ])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop",
                name = "Bus Stop ID",
                desc = "ID of bus stop to track.",
                icon = "bus",
                default = DEFAULT_STOP_ID,
            ),
            schema.Text(
                id = "key",
                name = "API key",
                desc = "MCTS Real-Time API key.",
                icon = "key",
            ),
        ],
    )
