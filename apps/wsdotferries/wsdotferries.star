"""
WSDOT Ferries - shows the next two departures for a chosen Washington
State Ferries (WSF) terminal, plus a drive-up car space bar for each
sailing.

Data source: WSDOT Ferries API (terminalsailingspace endpoint).
Requires a free WSDOT Traveler API access code: https://wsdot.wa.gov/traffic/api/
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TIMEZONE = "America/Los_Angeles"
DEFAULT_TERMINAL = "7"  # Seattle

# WSF terminal id -> display name. Limited to the terminals the
# terminalsailingspace API actually serves (verified live) - the
# Fauntleroy/Southworth/Vashon triangle, Lopez, Shaw, Sidney B.C. and
# Tahlequah don't report drive-up space through this endpoint.
TERMINALS = [
    ("1", "Anacortes"),
    ("3", "Bainbridge Island"),
    ("4", "Bremerton"),
    ("5", "Clinton"),
    ("11", "Coupeville"),
    ("8", "Edmonds"),
    ("10", "Friday Harbor"),
    ("12", "Kingston"),
    ("14", "Mukilteo"),
    ("15", "Orcas Island"),
    ("16", "Point Defiance"),
    ("17", "Port Townsend"),
    ("7", "Seattle"),
]

BAR_WIDTH = 60

def terminal_name_for(tid):
    for t_id, name in TERMINALS:
        if t_id == tid:
            return name
    return "Terminal " + tid

def parse_wsdot_date(s):
    # WSDOT dates look like "/Date(1694912400000-0700)/". The milliseconds
    # are an absolute UTC instant, so the trailing offset can be ignored.
    inner = s[6:-2]
    sign_idx = -1
    for i in range(1, len(inner)):
        if inner[i] == "+" or inner[i] == "-":
            sign_idx = i
            break
    millis_str = inner if sign_idx == -1 else inner[:sign_idx]
    return time.from_timestamp(int(millis_str) // 1000)

def error_root(message):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = message,
                font = "tom-thumb",
                color = "#ff8800",
                align = "center",
            ),
        ),
    )

def render_bar(drive_up, max_space, show_bar):
    if show_bar and max_space > 0:
        pct = drive_up / max_space
        if pct < 0.0:
            pct = 0.0
        if pct > 1.0:
            pct = 1.0
        filled = int(pct * BAR_WIDTH)
        if pct > 0.3:
            bar_color = "#2ecc40"
        elif pct > 0.1:
            bar_color = "#ffcc00"
        else:
            bar_color = "#ff4136"
        return render.Row(
            children = [
                render.Box(width = filled, height = 2, color = bar_color),
                render.Box(width = BAR_WIDTH - filled, height = 2, color = "#333333"),
            ],
        )
    return render.Box(width = BAR_WIDTH, height = 2, color = "#333333")

def render_departure(dep_time, sailing):
    time_str = dep_time.in_location(TIMEZONE).format("3:04 PM")

    max_space = sailing.get("MaxSpaceCount", 0)
    drive_up = 0
    show_bar = False
    for arr in sailing.get("SpaceForArrivalTerminals", []):
        if arr.get("DisplayDriveUpSpace", False):
            drive_up += arr.get("DriveUpSpaceCount", 0)
            show_bar = True

    spaces_str = str(drive_up) if show_bar else "--"

    return render.Column(
        cross_align = "start",
        children = [
            render.Box(
                width = BAR_WIDTH,
                height = 6,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text(content = time_str, font = "tom-thumb", color = "#ffffff"),
                        render.Text(content = spaces_str, font = "tom-thumb", color = "#ffffff"),
                    ],
                ),
            ),
            render.Padding(
                pad = (0, 1, 0, 1),
                child = render_bar(drive_up, max_space, show_bar),
            ),
        ],
    )

def get_schema():
    options = [schema.Option(display = name, value = tid) for tid, name in TERMINALS]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "terminal",
                name = "Departure Terminal",
                desc = "WSF terminal to show the next departures from.",
                icon = "ferry",
                default = DEFAULT_TERMINAL,
                options = options,
            ),
            schema.Text(
                id = "api_key",
                name = "WSDOT API Key",
                desc = "Free access code from wsdot.wa.gov/traffic/api",
                icon = "key",
                default = "",
            ),
        ],
    )

def main(config):
    terminal_id = config.str("terminal", DEFAULT_TERMINAL)
    api_key = config.str("api_key", "")
    terminal_name = terminal_name_for(terminal_id)

    if api_key == "":
        return error_root("Set WSDOT API key in app settings")

    cache_key = "wsdotferries_%s" % terminal_id
    body = cache.get(cache_key)
    if body == None:
        url = "https://www.wsdot.wa.gov/ferries/api/terminals/rest/terminalsailingspace/%s?apiaccesscode=%s" % (terminal_id, api_key)
        rep = http.get(url)
        if rep.status_code != 200:
            return error_root("WSF API error %d" % rep.status_code)
        body = rep.body()
        cache.set(cache_key, body, ttl_seconds = 60)

    data = json.decode(body)
    sailings = data.get("DepartingSpaces", [])

    upcoming = []
    for sailing in sailings:
        if sailing.get("IsCancelled", False):
            continue
        dep_time = parse_wsdot_date(sailing["Departure"])
        upcoming.append((dep_time, sailing))
        if len(upcoming) == 2:
            break

    children = [
        render.Marquee(
            width = 64,
            child = render.Text(content = terminal_name.upper(), font = "tom-thumb", color = "#66ccff"),
        ),
    ]

    if len(upcoming) == 0:
        children.append(render.Text(content = "No sailings", font = "tom-thumb"))
    else:
        for dep_time, sailing in upcoming:
            children.append(render_departure(dep_time, sailing))

    return render.Root(
        child = render.Padding(
            pad = 1,
            child = render.Column(
                cross_align = "start",
                children = children,
            ),
        ),
    )
