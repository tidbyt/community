"""
VBB Transport — live departures from any stop in the VBB (Berlin/Brandenburg)
public-transport network. Data: https://v6.vbb.transport.rest
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VBB_API = "https://v6.vbb.transport.rest"

DEPARTURES_TTL = 20
STATIONS_TTL = 300
MAX_ROWS = 3
DIRECTION_MARQUEE_WIDTH = 36
HEADER_COLOR = "#00cccc"

# Colors roughly matching VBB product branding.
MODE_COLORS = {
    "suburban": "#006e34",
    "subway": "#0d4f9c",
    "tram": "#d12e26",
    "bus": "#a05a2c",
    "regional": "#f08000",
    "express": "#f08000",
    "ferry": "#0099cc",
}

# All VBB product codes accepted by the API as filter query params.
ALL_PRODUCTS = ["suburban", "subway", "tram", "bus", "regional", "express", "ferry"]

# Maps the user-facing mode selection to the API product codes to keep enabled.
# "all" → keep API defaults (all true), no filter sent.
MODE_FILTERS = {
    "all": None,
    "suburban": ["suburban"],
    "subway": ["subway"],
    "tram": ["tram"],
    "bus": ["bus"],
    "regional": ["regional", "express"],
    "ferry": ["ferry"],
}

MODE_OPTIONS = [
    schema.Option(display = "All modes", value = "all"),
    schema.Option(display = "S-Bahn", value = "suburban"),
    schema.Option(display = "U-Bahn", value = "subway"),
    schema.Option(display = "Tram", value = "tram"),
    schema.Option(display = "Bus", value = "bus"),
    schema.Option(display = "Regional train", value = "regional"),
    schema.Option(display = "Ferry", value = "ferry"),
]

def main(config):
    stop_id = _resolve_stop_id(config.get("stop_id", ""))
    if not stop_id:
        return _msg("Set a stop in the app config")
    mode = config.get("mode", "all")

    departures, err = _fetch_departures(stop_id, mode)
    if err != None:
        return _msg("VBB: " + err)
    if len(departures) == 0:
        return _msg("No departures")

    station_name = (departures[0].get("stop") or {}).get("name", "")
    rows = [_render_departure(d) for d in departures[:MAX_ROWS]]
    children = [_render_header(station_name)] + rows
    return render.Root(
        delay = 100,
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = children,
        ),
    )

def _render_header(name):
    return render.Marquee(
        width = 64,
        child = render.Text(name, font = "tom-thumb", color = HEADER_COLOR),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "stop_id",
                name = "Stop",
                desc = "Transit stop to show departures for.",
                icon = "bus",
                handler = _search_stations,
            ),
            schema.Dropdown(
                id = "mode",
                name = "Transport mode",
                desc = "Filter departures by transport type.",
                icon = "filter",
                default = "all",
                options = MODE_OPTIONS,
            ),
        ],
    )

def _mode_query(mode):
    keep = MODE_FILTERS.get(mode)
    if not keep:
        return ""
    parts = []
    for p in ALL_PRODUCTS:
        parts.append("{}={}".format(p, "true" if p in keep else "false"))
    return "&" + "&".join(parts)

def _resolve_stop_id(raw):
    if not raw:
        return ""
    raw = raw.strip()
    if raw.startswith("{"):
        decoded = json.decode(raw, default = None)
        if type(decoded) == "dict" and "value" in decoded:
            return str(decoded["value"])
    return raw

def _search_stations(query):
    query = query.strip() if query else ""
    if len(query) < 2:
        return []
    url = "{}/locations?query={}&results=8&poi=false&addresses=false&fuzzy=true&language=en".format(
        VBB_API,
        query,
    )
    resp = http.get(url, ttl_seconds = STATIONS_TTL)
    if resp.status_code != 200:
        return []
    options = []
    for r in resp.json():
        if r.get("type") not in ("stop", "station"):
            continue
        options.append(schema.Option(display = r["name"], value = r["id"]))
    return options

def _fetch_departures(stop_id, mode = "all"):
    url = "{}/stops/{}/departures?duration=60&results=8{}".format(
        VBB_API,
        stop_id,
        _mode_query(mode),
    )
    print("VBB GET stop_id={} mode={} url={}".format(stop_id, mode, url))
    resp = http.get(url, ttl_seconds = DEPARTURES_TTL)
    if resp.status_code != 200:
        print("VBB ERR stop_id={} status={} body={}".format(stop_id, resp.status_code, resp.body()))
        return [], "HTTP {}".format(resp.status_code)
    body = resp.json()
    if type(body) == "dict":
        deps = body.get("departures", [])
        print("VBB OK  stop_id={} departures={}".format(stop_id, len(deps)))
        return deps, None
    if type(body) == "list":
        print("VBB OK  stop_id={} departures={} (legacy list)".format(stop_id, len(body)))
        return body, None
    print("VBB ERR stop_id={} unexpected body type={} body={}".format(stop_id, type(body), resp.body()))
    return [], "bad response"

def _render_departure(dep):
    line = dep.get("line") or {}
    line_name = line.get("name") or "?"
    product = line.get("product") or ""
    color = MODE_COLORS.get(product, "#ffffff")
    direction = dep.get("direction") or ""
    eta, eta_color = _format_eta(dep.get("when") or dep.get("plannedWhen"))

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(line_name, font = "tom-thumb", color = color),
                    render.Box(width = 2, height = 1),
                    render.Marquee(
                        width = DIRECTION_MARQUEE_WIDTH,
                        child = render.Text(direction, font = "tom-thumb"),
                    ),
                ],
            ),
            render.Text(eta, font = "tom-thumb", color = eta_color),
        ],
    )

ETA_NEUTRAL = "#ffffff"
ETA_RED = "#ff3030"
ETA_YELLOW = "#ffd000"
ETA_GREEN = "#00d040"

def _format_eta(when_str):
    if not when_str:
        return "?", ETA_NEUTRAL
    t = time.parse_time(when_str)
    mins = int((t - time.now()) / time.minute)
    if mins <= 0:
        return "now", ETA_RED
    text = "{}m".format(mins)
    if mins <= 2:
        return text, ETA_RED
    if mins <= 10:
        return text, ETA_YELLOW
    return text, ETA_GREEN

def _msg(text):
    return render.Root(
        child = render.WrappedText(content = text, font = "tom-thumb"),
    )
