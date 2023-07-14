"""
Applet: Pittsburgh Buses
Summary: Show times for any PRT stop
Description: Display time of the next buses for any Pittsburgh PRT bus stop.
Author: ckingsford
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# Set to true to work on this locally; should be False for deployment.
LOCAL_DEV = False

DEFAULT_STOP = "7117"

# use a short TTL for the stop times, since they change every minute or so.
TIMES_TTL_SECONDS = 15

# use a long TTL for the stop name since they change very rarely
STOP_NAME_TTL_SECONDS = 600

BUS_OUT_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABEAAAAHCAYAAADu4qZ8AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAg
IQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABA
AAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAARoAMABAAAAAEAAAAHAAAAAHPu3z0AAAIvaVR
YdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4Onht
cHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvM
Tk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCi
AgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICA
gICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBp
eGVsWURpbWVuc2lvbj43PC9leGlmOlBpeGVsWURpbWVuc2lvbj4KICAgICAgICAgPGV4aWY6UGl4ZWxYRGltZ
W5zaW9uPjE3PC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICAgICAgICAgPGV4aWY6Q29sb3JTcGFjZT4xPC9leG
lmOkNvbG9yU3BhY2U+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiA
gICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgqD0JU7AAAAgUlEQVQY
GWNsKCv7H9bXx0ARuMbC8j80cTUYk8NmmXvlPxNFLoBqZgTZfomREczV+/+fgVS23swLDGBDQCacnjQJai4Dg
2leHpyNzsCmjkXrzx/GNCam/9ZA1QeOHmVwsLZmmPDvH7peOB+bOhaQ7Kx//xiBkv9BBsD4YAYWAps6AKC9Xl
1Gw1UZAAAAAElFTkSuQmCC
""")

BUS_IN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABEAAAAHCAYAAADu4qZ8AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAY
dpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEaADAAQAAAABAAAABwAAAABhM/EjAAAA
fElEQVQYGWO8xsLyn4ECsKqoiIGBZe6V/yCDQhNXgzE5bCYKHAHXyghyyaV0A4ZLjIxgQb3//0lmM8LC5PSkSX
CTTfPy4Gx0BjZ1LBP+/QOrswaSB44eZXCwtmaAiaEbAOKjq5v17x8jC4iASv4HGQACMDEwB40AqsBQBwBXhV/r
O8Ek+wAAAABJRU5ErkJggg==
""")

DEV_API_KEY_ENCRYPTED = """AV6+xWcEouPEKOfwVyItDFMRElKdLncc6K1gEd9iMmv6b2c94olZ/qmL6hihs7lNK4E9zi44WmvPY/asRS/jhkCqrqlNAfulNWAJqo4TKJN7jUk/L8joLjWCE55Ly49eLx0fNZKXYyNoNVMLx1eOZFWPqxD+MpMgj9jHpkuCCA=="""

PRT_API_URL = "http://realtime.portauthority.org/bustime/api/v3/"
PTR_RT_LIMIT_URL = "&rt={rtlimit}"
PRT_API_COMMON_PARAMS = "&format=json&rtpidatafeed=Port%20Authority%20Bus&key={key}"
PRT_GET_TIMES_URL = "getpredictions?stpid={stopid}"
PRT_GET_STOPS_URL = "getstops?stpid={stopid}"

def render_header(stop_name, inbound = True):
    """
    Return the top row of the display that includes the stop name and a nice little
    icon. If the stop name is not too much bigger than the space available, we render
    it as a simple text item; if it is bigger, we render it as a marquee.
    """
    STOP_NAME_WIDTH = 47  # width of stop name field in pixels
    NAME_CHAR_WIDTH = int(STOP_NAME_WIDTH / 4)  # width in characters
    NAME_SPILL_CHAR = 3  # number of characters allowed to be truncated from stop name

    # Choose whether to use a Marquee or just text based on how many characters would
    # be truncated using text.
    if len(stop_name) - NAME_SPILL_CHAR > NAME_CHAR_WIDTH:
        stop_name_widget = render.Marquee(
            child = render.Text(stop_name, font = "CG-pixel-3x5-mono"),
            width = STOP_NAME_WIDTH,
            scroll_direction = "horizontal",
        )
    else:
        stop_name_widget = render.Text(stop_name[:NAME_CHAR_WIDTH], font = "CG-pixel-3x5-mono")

    # Pick the bus icon to show based on the direction of the stop.
    bus_icon = BUS_IN_ICON if inbound else BUS_OUT_ICON

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            stop_name_widget,
            render.Image(src = bus_icon),
        ],
    )

def render_line_time(line, time, full):
    """
    Return a render.Row that represents the LINE and TIME pairs. The time (in minutes)
    will be colored by how close it is to 0. Times greater than 999 minutes will be
    displayed as "?". The input types should both be strings. The returned row is 14
    pixels high and 28 pixels wide. If either line or time is None, we return an empty
    width of the same size.
    """
    ROW_HEIGHT = 7
    LINE_WIDTH = 14
    MIN_WIDTH = 14
    TIME_COLORS = ["#0F0", "#FF0", "#F00"]  # green, yellow, red
    ROUTE_COLORS = {
        "EMPTY": ["#090", "#FFF"],  # white on green
        "HALF_EMPTY": ["#FF0", "#222"],  # black on yellow
        "FULL": ["#F00", "#FFF"],  # white on red
        "N/A": ["#F00", "#FFF"],  # white on red
    }

    # If any of the information is missing, this is an "empty" item, and we
    # render a box of the right size to keep the spacing correct.
    if line == None or time == None:
        return render.Box(width = LINE_WIDTH + MIN_WIDTH, height = ROW_HEIGHT)

    # Contrary to the docs, full can be an empty string.
    if full == "":
        full = "N/A"

    # If time won't fit, put a ? since any time longer than 999 minutes probably
    # isn't worth showing anyway.
    t = int(time) if time != "DUE" else 0
    if t > 999:
        time = "?"

    # Color the time based on its magnitude.
    if t < 10:
        time_color = TIME_COLORS[0]
    elif t < 20:
        time_color = TIME_COLORS[1]
    else:
        time_color = TIME_COLORS[2]

    # Set the route background and foreground colors based on how full the bus is.
    route_color = ROUTE_COLORS[full]

    # Currently bus lines are all <= 3 characters. If we find one with >= 4 characters
    # we just truncate it to the first 3.
    line = line[:3]

    return render.Row(
        children = [
            render.Box(
                width = LINE_WIDTH - 1,
                height = ROW_HEIGHT,
                color = route_color[0],
                child = render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Text(
                        line,
                        font = "CG-pixel-3x5-mono",
                        color = route_color[1],
                    ),
                ),
            ),
            render.Box(width = 1, height = ROW_HEIGHT),
            render.Box(
                width = MIN_WIDTH,
                height = ROW_HEIGHT,
                child = render.Text(time, offset = -1, color = time_color),
            ),
        ],
    )

def build_display(lines_times, stop_name, inbound):
    """
    Return the render.Root object that is the complete display.
    """
    MAX_ITEMS = 6

    # render the header
    children = [render_header(stop_name, inbound)]

    # if there are no busses arriving to display, say so.
    if len(lines_times) == 0:
        children.extend([
            render.Box(
                width = 64,
                height = 23,
                child = render.Text("No buses now.", color = "#99C"),
            ),
        ])

        # If there is at least 1 bus arrival time to display, display them.
    else:
        # We can only display the first MAX_ITEMS times, so truncate if more than that.
        lines_times = lines_times[:MAX_ITEMS]

        # If we have fewer than MAX_ITEMS items, replace them with "empty" items.
        # We use "empty" items to keep the spacing and alignment correct even if we
        # have < 6 route times.
        if len(lines_times) < MAX_ITEMS:
            lines_times.extend([[None, None, None]] * (MAX_ITEMS - len(lines_times)))

        # Render each of the rows.
        children.extend([
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render_line_time(*lines_times[i]),
                    render_line_time(*lines_times[i + 1]),
                ],
            )
            for i in range(0, len(lines_times), 2)
        ])

    return render.Root(
        max_age = 60,
        child = render.Column(
            main_align = "space_evenly",
            expanded = True,
            children = children,
        ),
    )

def validate_prt_response(rep):
    """
    Return a pair `ok` and `json` by converting the given HTTP response into JSON. If all is well
    with the response status and PRT JSON, we return True, JSON. Otherwise, we return False, JSON.
    When returning False, no guarantees are made about the JSON object.
    """
    if rep.status_code != 200:
        return False, None
    json = rep.json()
    if "bustime-response" not in json:
        return False, json
    if "error" in json["bustime-response"]:
        return False, json
    return True, json

def get_stop_name(stop_id, api_key):
    """
    Get the stop name for the given stop ID. If the call fails for any reason, return the name
    "No stop name". This is only called if we have no predicted bus times (since otherwise we can
    get the stop name from the predicted times that are already returned).
    """
    if api_key == None:
        return "No API key"

    ok, json = validate_prt_response(
        http.get(
            (PRT_API_URL + PRT_GET_STOPS_URL + PRT_API_COMMON_PARAMS).format(
                key = api_key,
                stopid = stop_id,
            ),
            ttl_seconds = STOP_NAME_TTL_SECONDS,
        ),
    )
    if not ok:
        return "No stop name"

    return json["bustime-response"]["stop"]["stpnm"]

def get_times(stop_id, line_pattern, api_key):
    """
    Use the PRT API to get the predicted arrival times for buses at the given stop_id.
    Return three things: lines_times, stop_name, inbound. Here, lines_times is a list of
    (route, minutes, full) triples. Stop name is the human-readable name for the stop, and
    inbound is True if this is an inbound stop. When no predictions are available, inbound
    is always True (since this just controls the little bus graphic, it isn't a big deal).
    """
    if api_key == None:
        return [], "No API Key", True

    # Call to get predictions of stop times for the given stop. If line_pattern is not None,
    # then we add a parameter to limit the routes returned.
    if line_pattern != None and len(line_pattern) > 0:
        resp = http.get(
            (PRT_API_URL + PRT_GET_TIMES_URL + PTR_RT_LIMIT_URL + PRT_API_COMMON_PARAMS).format(
                key = api_key,
                stopid = stop_id,
                rtlimit = line_pattern,
            ),
            ttl_seconds = TIMES_TTL_SECONDS,
        )
    else:
        resp = http.get(
            (PRT_API_URL + PRT_GET_TIMES_URL + PRT_API_COMMON_PARAMS).format(
                key = api_key,
                stopid = stop_id,
            ),
            ttl_seconds = TIMES_TTL_SECONDS,
        )
    ok, json = validate_prt_response(resp)

    # If we failed, present some error message.
    if not ok:
        return [], "Failed to get times.", True

    # Parse the JSON to extract the predictions.
    bus_data = json["bustime-response"]["prd"]

    # If there was at least one prediction.
    if len(bus_data) > 0:
        # use the first record to get the stop name and direction
        stop_name = bus_data[0]["stpnm"]
        inbound = (bus_data[0]["rtdir"] == "INBOUND")

        # rtdd = route display name
        # prdctdn = minutes until bus arrives
        # psgld = EMPTY, HALF_EMPTY, FULL, or N/A depending on the number of people on the bus
        lines_times = [[d["rtdd"], d["prdctdn"], d["psgld"]] for d in bus_data]
        return lines_times, stop_name, inbound

    # Otherwise, if no predictions.
    return [], get_stop_name(stop_id, api_key), True

def ensure_valid_stop(stop_id):
    """
    Removes all non-digit characters from the stop number and truncates the stop to
    at most MAX_STOP_LEN digits.
    """
    MAX_STOP_LEN = 8
    if stop_id == None or len(stop_id) == 0:
        return DEFAULT_STOP
    s = "".join([x for x in stop_id.codepoints() if x.isdigit()])
    return s[:MAX_STOP_LEN]

def alphanum_only(s):
    """
    Return the string x after removing all non-alphanumeric and non-comma characters.
    """
    return "".join([x for x in s.codepoints() if x.isalnum() or x == ","])

def ensure_valid_route_pattern(routes):
    """
    The input `routes` should be a comma-separated string that lists the routes serving this stop that we want to display. We normalize this input by returning a comma-separated string
    where (a) non-alphanumeric characters have been removed, (b) every route is no more than
    MAX_ROUTE_LENGTH characters, (c) no more than MAX_ROUTES are listed, (d) everything
    is uppercase, and (e) the list is de-duped. If routes is None, we return None.
    """
    MAX_ROUTES = 10  # 10 is the limit in the API
    MAX_ROUTE_LENGTH = 4
    if routes == None:
        return None

    # remove non-letters/numbers, make uppercase, split on comma, and limit to MAX_ROUTES
    L = alphanum_only(routes).upper().split(",")[:MAX_ROUTES]

    # truncate each route name to 4 letters (they are, I believe, at most 3 now)
    L = [x[:MAX_ROUTE_LENGTH] for x in L]

    # De-dup, so that if the same route is listed twice in the input, it's only in our list
    # once. Curiously, the API has a "bug" that will return duplicate times if we list the
    # same route multiple times.
    L = {rt: True for rt in L}.keys()

    return ",".join(L)

def main(config):
    """
    The main routine to gather the data and then render it.
    """

    # Read and validate the configuration.
    stop_number = ensure_valid_stop(config.get("stop_number", DEFAULT_STOP))
    line_pattern = ensure_valid_route_pattern(config.get("line_pattern"))

    # Decrypt the API key.
    api_key = secret.decrypt(DEV_API_KEY_ENCRYPTED) or config.get("dev_api_key")

    # Gather the data from the web.
    lines_times, stop_name, inbound = get_times(stop_number, line_pattern, api_key)

    # Build the display from the data.
    return build_display(lines_times, stop_name, inbound)

def get_schema():
    """
    Entry point to define the setting's UI.
    If LOCAL_DEV global is true, then an extra field for the developer API key is included.
    """
    fields = [
        schema.Text(
            id = "stop_number",
            name = "Stop Number",
            desc = "Stop number to display",
            icon = "locationDot",
        ),
        schema.Text(
            id = "line_pattern",
            name = "Routes",
            desc = "Show only routes in this list (comma-separated)",
            icon = "bus",
        ),
    ]

    if LOCAL_DEV:
        fields.append(
            schema.Text(
                id = "dev_api_key",
                name = "PRT API Key",
                desc = "For local debugging",
                icon = "key",
            ),
        )

    return schema.Schema(
        version = "1",
        fields = fields,
    )
