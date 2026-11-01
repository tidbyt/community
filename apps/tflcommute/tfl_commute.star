"""
Applet: TfL Commute
Summary: Bus times and line status
Description: Next buses at two London bus stops, and the status of up to three TfL lines.
Author: robcowie

Layout (64x32):
    [V] 3 15 | [H] 2  3        <- next two buses at each stop, any route, in minutes;
                                  the stop letter sits on a TfL-red flag
    MIL  Part Closure          <- one row per configured line: fixed 3-letter code in the
    NOR  Good                     line's colour, status scrolls beside it if it doesn't fit

Config (schema):
    stop1, stop2  Bus stops, picked from a list near a location in the Tidbyt app
                  (schema.LocationBased). Both required. On the command line pass
                  the TfL NaPTAN stop id directly, e.g. stop1=490020255S.
    line1..line3  Optional TfL lines (dropdown by name). With three, the layout
                  tightens to fit them.

Dev:
    pixlet serve tflcommute/                              # form for the schema fields
    pixlet render tflcommute/ stop1=... stop2=... line1=mildmay line2=northern
    pixlet render tflcommute/ fake=1                      # canned data, no TfL calls
    pixlet render tflcommute/ ... fail=1                  # every TfL call 404s: retry + degraded screen
    pixlet render tflcommute/ ... outage=1                # no TfL calls: the degraded screen

Failure handling: a non-200 from TfL is retried once immediately. If any call
still fails, the bus row keeps its layout with dashes for the affected stops
and the status area shows "TfL data unavailable" instead of line statuses.
Network-level errors (DNS, refused, timeout) abort the render, since Pixlet's
http.get raises and Starlark cannot catch them.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

STOP_FIELDS = ["stop1", "stop2"]  # schema ids; exactly two stops are shown
SHOW = 2  # buses per stop (two is all that fits in half a row in the normal font)

LINE_FIELDS = ["line1", "line2", "line3"]  # schema ids; three lines fit in the compact layout

# Dropdown options: display name -> TfL line id (from /Line/Mode/tube,overground,dlr,elizabeth-line,tram, plus Thameslink).
LINE_OPTIONS = [
    ("None", "none"),  # schema needs a non-empty value; treated as unset
    ("Bakerloo", "bakerloo"),
    ("Central", "central"),
    ("Circle", "circle"),
    ("District", "district"),
    ("DLR", "dlr"),
    ("Elizabeth line", "elizabeth"),
    ("Hammersmith & City", "hammersmith-city"),
    ("Jubilee", "jubilee"),
    ("Liberty (Overground)", "liberty"),
    ("Lioness (Overground)", "lioness"),
    ("Metropolitan", "metropolitan"),
    ("Mildmay (Overground)", "mildmay"),
    ("Northern", "northern"),
    ("Piccadilly", "piccadilly"),
    ("Suffragette (Overground)", "suffragette"),
    ("Thameslink", "thameslink"),  # national-rail mode; status only, TfL has no train times for it
    ("Tram", "tram"),
    ("Victoria", "victoria"),
    ("Waterloo & City", "waterloo-city"),
    ("Weaver (Overground)", "weaver"),
    ("Windrush (Overground)", "windrush"),
]

TFL_BASE = "https://api.tfl.gov.uk"
TFL_BASE_BROKEN = "https://api.tfl.gov.uk/nope"  # fail=1: everything 404s
ARRIVALS_PATH = "/StopPoint/%s/Arrivals"
STATUS_PATH = "/Line/%s/Status"
STOP_DISRUPTION_PATH = "/StopPoint/%s/Disruption"
STOP_PATH = "/StopPoint/%s"
STOP_SEARCH_PATH = "/StopPoint"  # ?lat=&lon=&radius=... for the location picker
STOP_SEARCH_RADIUS_M = 400
NO_STOP = "none"  # option value meaning "nothing usable here"; treated as unset
RETRIES = 1  # immediate retries after a non-200 response

# TfL returns 403 to Go's default User-Agent, which Pixlet sends.
HEADERS = {"User-Agent": "Tidbyt tfl_commute", "Accept": "application/json"}

# Optional TfL API key (https://api-portal.tfl.gov.uk/). Anonymous access works but has a
# lower rate limit shared by everyone rendering from Tidbyt's servers.
ENCRYPTED_APP_KEY = "AV6+xWcETlxWm859vwNU01+BiEvxim3e3nBzrAAZR8NJ1a87YqF8FWZ7Buxi0v+bV7GKuN5GxQJlNQibV2Ug7FNoM2lhcw8y0kc0ie5v8owLMvqW+5JcGlY+ABTBrfRwDn2A3L5XYRK3mULbxv5xTXR6Trp0iWWYMlF48y0uZk1hHm0fk/E="
ARRIVALS_CACHE_SECONDS = 30
STATUS_CACHE_SECONDS = 120
DISRUPTION_CACHE_SECONDS = 300
STOP_INFO_CACHE_SECONDS = 86400  # stop letters don't change
STOP_SEARCH_CACHE_SECONDS = 86400
MAX_AGE_SECONDS = 120  # blank the slot if nothing fresher

SOON_MINUTES = 2  # below this: alert colour
NEAR_MINUTES = 5  # below this: warning colour

# Red is reserved for the TfL-style stop flags, so problems are orange and warnings yellow.
COLOR_FLAG = "#dc241f"  # TfL red
COLOR_FLAG_TEXT = "#fff"
COLOR_DIVIDER = "#333"
COLOR_ALERT = "#f80"  # bus imminent, stop closed, line in trouble
COLOR_WARN = "#fd0"  # bus a few minutes away, minor delays
COLOR_FAR = "#fff"
COLOR_NONE = "#555"
COLOR_LINE_NAME = "#aaa"
COLOR_GOOD = "#3c3"
COLOR_SOON = COLOR_ALERT
COLOR_NEAR = COLOR_WARN

# The second bus time is drawn dimmer than the first so "20 22" reads as two numbers.
DIM = {COLOR_FAR: "#999", COLOR_WARN: "#a90", COLOR_ALERT: "#a50"}
COLOR_MINOR = COLOR_WARN
COLOR_BAD = COLOR_ALERT
COLOR_CLOSED = COLOR_ALERT

# Shorter wording for statuses, so a healthy line fits without scrolling.
STATUS_TEXT = {"Good Service": "Good"}

# Fixed three-character line codes.
# TfL has no official codes, so these are ours (the Overground ones especially).
# Any line missing here falls back to the first three letters of the name, upper-cased.
LINE_CODES = {
    "Bakerloo": "BKL",
    "Central": "CEN",
    "Circle": "CIR",
    "District": "DIS",
    "DLR": "DLR",
    "Elizabeth line": "ELZ",
    "Hammersmith & City": "H&C",
    "Jubilee": "JUB",
    "Liberty": "LIB",
    "Lioness": "LIO",
    "Metropolitan": "MET",
    "Mildmay": "MIL",
    "Northern": "NOR",
    "Piccadilly": "PIC",
    "Suffragette": "SUF",
    "Thameslink": "TLK",
    "Tram": "TRM",
    "Victoria": "VIC",
    "Waterloo & City": "W&C",
    "Weaver": "WEA",
    "Windrush": "WIN",
}
CODE_WIDTH = 19  # widest code ("W&C") is 18px in tb-8, plus a 1px gap before the status

# Line colours from the TfL Colour Standard. Used for the code.
# Northern is black in the standard, which is invisible here, so it uses white.
# Thameslink is not a TfL line so pink is taken from the operator's brand.
# Codes for lines not listed are drawn in the neutral grey.
LINE_COLORS = {
    "Bakerloo": "#8f5a2a",  # TfL is #b26300, which reads orange on LEDs; this is browner
    "Central": "#dc241f",
    "Circle": "#ffc80a",
    "District": "#007d32",
    "DLR": "#00afad",
    "Elizabeth line": "#60399e",
    "Hammersmith & City": "#f589a6",
    "Jubilee": "#838d93",
    "Liberty": "#5d6061",
    "Lioness": "#faa61a",
    "Metropolitan": "#9b0058",
    "Mildmay": "#0077ad",
    "Northern": "#ffffff",
    "Piccadilly": "#0019a8",
    "Suffragette": "#5bbd72",
    "Thameslink": "#e6007e",
    "Tram": "#5fb526",
    "Victoria": "#039be5",
    "Waterloo & City": "#76d0bd",
    "Weaver": "#823a62",
    "Windrush": "#ed1b00",
}

FAKE_STOPS = [{"id": "FAKE1", "label": "V"}, {"id": "FAKE2", "label": "H"}]
FAKE_ARRIVALS = {
    "FAKE1": [60, 7 * 60, 19 * 60],
    "FAKE2": [2 * 60, 3 * 60 + 30, 11 * 60],
}
FAKE_STATUS = [("Mildmay", 5, "Part Closure"), ("District", 10, "Good Service"), ("Northern", 9, "Minor Delays")]
FAKE_CLOSED = []  # add "FAKE2" to demo the closed-stop bar

# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "stop1",
                name = "First bus stop",
                desc = "Bus stops near a location; shown in the left column.",
                icon = "bus",
                handler = nearby_stops,
            ),
            schema.LocationBased(
                id = "stop2",
                name = "Second bus stop",
                desc = "Bus stops near a location; shown in the right column.",
                icon = "bus",
                handler = nearby_stops,
            ),
            schema.Dropdown(
                id = "line1",
                name = "Status line 1",
                desc = "Tube, Overground, DLR, Elizabeth line, Tram or Thameslink line to show the status of.",
                icon = "trainSubway",
                default = "none",
                options = [schema.Option(display = d, value = v) for d, v in LINE_OPTIONS],
            ),
            schema.Dropdown(
                id = "line2",
                name = "Status line 2",
                desc = "A second line, or None.",
                icon = "trainSubway",
                default = "none",
                options = [schema.Option(display = d, value = v) for d, v in LINE_OPTIONS],
            ),
            schema.Dropdown(
                id = "line3",
                name = "Status line 3",
                desc = "A third line, or None. With three lines the layout is tighter.",
                icon = "trainSubway",
                default = "none",
                options = [schema.Option(display = d, value = v) for d, v in LINE_OPTIONS],
            ),
        ],
    )

def nearby_stops(location):
    """LocationBased handler: bus stops within STOP_SEARCH_RADIUS_M of the chosen location.

    Called by the Tidbyt mobile app with a JSON location; returns schema.Options whose
    value is the TfL stop id. Nearest first. Display is "<letter> <name> (towards X)".
    """
    loc = json.decode(location)
    lat, lng = float(loc["lat"]), float(loc["lng"])
    if lat <= 49.9 or lat >= 58.7 or lng <= -11.05 or lng >= 1.78:
        # TfL errors on searches outside the UK. (pixlet serve starts in Brooklyn: set a
        # London latitude/longitude in its location form.)
        return [schema.Option(display = "No TfL bus stops here: choose a location in London", value = NO_STOP)]

    # round to ~100m so nearby requests share a cache entry
    lat, lng = math.round(lat * 1000) / 1000, math.round(lng * 1000) / 1000
    resp = http.get(
        TFL_BASE + STOP_SEARCH_PATH,
        params = {
            "lat": str(lat),
            "lon": str(lng),
            "radius": str(STOP_SEARCH_RADIUS_M),
            "stopTypes": "NaptanPublicBusCoachTram",
            "modes": "bus",
            "returnLines": "false",
            "categories": "Direction",
        },
        headers = HEADERS,
        ttl_seconds = STOP_SEARCH_CACHE_SECONDS,
    )
    if resp.status_code != 200:
        print("TfL stop search -> HTTP %d" % resp.status_code)
        return [schema.Option(display = "TfL stop search failed, try again", value = NO_STOP)]
    stops = [sp for sp in resp.json().get("stopPoints", []) if type(sp) == "dict" and sp.get("id")]
    if not stops:
        return [schema.Option(display = "No bus stops within %dm, try a nearer location" % STOP_SEARCH_RADIUS_M, value = NO_STOP)]
    options = []
    for sp in sorted(stops, key = lambda sp: sp.get("distance", 0)):
        props = {p.get("key"): p.get("value") for p in sp.get("additionalProperties", [])}
        letter = (sp.get("stopLetter") or "").replace("->", "")
        label = sp.get("commonName", sp["id"])
        if letter:
            label = "%s  %s" % (letter, label)
        if props.get("Towards"):
            label = "%s (towards %s)" % (label, props["Towards"])
        options.append(schema.Option(display = label, value = sp["id"]))
    return options

def config_value(raw):
    """A LocationBased field arrives as JSON {"display", "value"}; the command line gives the bare value."""
    raw = (raw or "").strip()
    if raw.startswith("{"):
        raw = (json.decode(raw).get("value") or "").strip()
    return "" if raw.lower() == NO_STOP else raw

def configured_lines(config):
    """TfL line ids chosen in config, in order, without blanks or duplicates."""
    ids = []
    for field in LINE_FIELDS:
        line_id = config.str(field, "").strip().lower()
        if line_id and line_id != "none" and line_id not in ids:
            ids.append(line_id)
    return ids

def configured_stops(config, fake, net):
    """[{"id", "label"}] for the two stops, or None if either is missing."""
    if fake:
        return FAKE_STOPS
    stops = []
    for field in STOP_FIELDS:
        stop_id = config_value(config.str(field, "")).upper()
        if not stop_id:
            return None
        stops.append({"id": stop_id, "label": stop_letter(stop_id, net)})
    return stops

def stop_letter(stop_id, net):
    """Up to two characters for the stop flag, or "" if TfL gives us nothing usable."""
    data = get_json(STOP_PATH % stop_id, STOP_INFO_CACHE_SECONDS, net) or {}

    # TfL sometimes answers with the parent stop group; the stop we asked for is then a child.
    if data.get("naptanId") != stop_id:
        for child in data.get("children", []):
            if child.get("naptanId") == stop_id:
                data = child
                break

    # Of TfL's ~32k bus stops: 29% have a 1-char letter, 15% 2 chars, 17% an arrow-style
    # direction like "->W" (outer London), 39% no letter at all, and ~30 have 3+ chars.
    letter = (data.get("stopLetter") or "").strip()
    if letter.startswith("->"):
        letter = letter[2:]
    elif letter.startswith(">"):
        letter = letter[1:]
    if not letter:
        # no letter: use the compass point TfL supplies, else the id's trailing letters
        props = {p.get("key"): p.get("value") for p in data.get("additionalProperties", [])}
        letter = (props.get("CompassPoint") or "").strip()
    if not letter:
        tail = ""
        for ch in reversed(stop_id.elems()):
            if not ch.isalpha():
                break
            tail = ch + tail
        letter = tail
    return letter[:2]  # a 3+ char bay code (A10, 40B) is truncated; the flag has room for two

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

def get_json(path, ttl, net):
    """GET a TfL endpoint as JSON. Retries once on a non-200; records failure in net["failed"].

    net is a per-render dict: {"base": url prefix, "app_key": str, "outage": bool, "failed": bool}.
    A network-level error (DNS, refused, timeout) raises out of http.get and cannot be
    caught here; the push script handles that case by re-rendering with outage=1.
    """
    if net["outage"]:
        net["failed"] = True
        return None
    url = net["base"] + path
    params = {"app_key": net["app_key"]} if net["app_key"] else {}
    for attempt in range(RETRIES + 1):
        resp = http.get(url, params = params, headers = HEADERS, ttl_seconds = ttl)
        if resp.status_code == 200:
            return resp.json()
        print("%s -> HTTP %d (attempt %d)" % (url, resp.status_code, attempt + 1))
    net["failed"] = True
    return None

def arrival_seconds(stop_id, fake, net):
    """Seconds to the next SHOW buses of any route, soonest first; None pads."""
    if fake:
        secs = FAKE_ARRIVALS[stop_id]
    else:
        data = get_json(ARRIVALS_PATH % stop_id, ARRIVALS_CACHE_SECONDS, net) or []
        secs = sorted([int(a["timeToStation"]) for a in data if type(a) == "dict" and "timeToStation" in a])
    return [secs[i] if i < len(secs) else None for i in range(SHOW)]

def closed_stops(stops, fake, net):
    """Set of stop ids with an active Closure disruption."""
    if fake:
        return {sid: True for sid in FAKE_CLOSED}
    ids = ",".join([stop["id"] for stop in stops])
    data = get_json(STOP_DISRUPTION_PATH % ids, DISRUPTION_CACHE_SECONDS, net) or []
    return {d.get("atcoCode"): True for d in data if type(d) == "dict" and d.get("type") == "Closure"}

def line_statuses(line_ids, fake, net):
    """[(line name, severity, description)] for the given TfL line ids, or None on failure."""
    if fake:
        # fake=1 shows all canned lines; with line fields set, only that many (for demos)
        return FAKE_STATUS[:len(line_ids)] if line_ids else FAKE_STATUS
    if not line_ids:
        return []
    data = get_json(STATUS_PATH % ",".join(line_ids), STATUS_CACHE_SECONDS, net)
    if data == None:
        return None
    by_id = {}
    for line in data:
        if type(line) != "dict" or not line.get("id"):
            continue
        statuses = [st for st in line.get("lineStatuses", []) if type(st) == "dict" and "statusSeverity" in st]
        if not statuses:
            continue

        # worst status first (lower severity number is worse)
        worst = sorted(statuses, key = lambda st: st["statusSeverity"])[0]
        by_id[line["id"]] = (line.get("name", line["id"]), worst["statusSeverity"], worst.get("statusSeverityDescription", ""))

    # TfL returns lines in its own order; show them in the order configured
    return [by_id[line_id] for line_id in line_ids if line_id in by_id]

# ---------------------------------------------------------------------------
# Presentation
# ---------------------------------------------------------------------------

def minutes_text(secs):
    m = secs // 60
    return "<1" if m < 1 else "%d" % m

def minutes_color(secs):
    m = secs // 60
    if m < SOON_MINUTES:
        return COLOR_SOON
    if m < NEAR_MINUTES:
        return COLOR_NEAR
    return COLOR_FAR

def status_color(severity):
    if severity >= 10:
        return COLOR_GOOD
    if severity == 9:
        return COLOR_MINOR
    return COLOR_BAD

def time_slot(widget, width):
    """Fixed-width, right-aligned cell so the times line up frame to frame."""
    return render.Box(
        width = width,
        height = 6,
        child = render.Row(expanded = True, main_align = "end", cross_align = "end", children = [widget]),
    )

FLAG_SIZE = 7  # stop flag is 7x7 (one letter) or 9x7 (two letters)
HALF_WIDTH = 30

def stop_flag(letter):
    """TfL-style stop flag: white letter(s) on a red square (blank square if no letter)."""
    width = FLAG_SIZE if len(letter) <= 1 else FLAG_SIZE + 2
    if not letter:
        return render.Box(width = width, height = FLAG_SIZE, color = COLOR_FLAG)
    return render.Box(
        width = width,
        height = FLAG_SIZE,
        color = COLOR_FLAG,
        # tom-thumb glyphs are 3x5 in a 4x6 cell; pad so they sit centred in the square
        child = render.Padding(pad = (1, 1, 0, 0), child = render.Text(letter, font = "tom-thumb", color = COLOR_FLAG_TEXT)),
    )

def stop_half(stop, times, closed):
    flag = stop_flag(stop["label"])

    # Time slots: a two-digit tb-8 time is 10px wide (9 of ink), so slots are 10 and the spare width
    # goes into gaps so adjacent numbers read as two. One-letter flag: 7 + 1 + 10 + 2 + 10 = 30.
    # Two-letter flag: 9 + 10 + 1 + 10 = 30.
    slot_width = 10
    if len(stop["label"]) <= 1:
        flag_gap, slot_gap = 1, 2
    else:
        flag_gap, slot_gap = 0, 1
    flag = render.Padding(pad = (0, 0, flag_gap, 0), child = flag)
    if closed:
        # Closed stop: a solid bar centred where the times would be, level with the digits.
        return render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                flag,
                # full flag height so the bar centres on the flag's middle row
                render.Box(
                    width = slot_width * SHOW + slot_gap * (SHOW - 1),
                    height = FLAG_SIZE,
                    child = render.Box(width = 11, height = 3, color = COLOR_CLOSED),
                ),
            ],
        )
    cells = []
    for i, secs in enumerate(times):
        if secs == None:
            text = render.Text("-", color = COLOR_NONE, height = 6, offset = -1)
        else:
            color = minutes_color(secs)
            if i > 0:
                color = DIM.get(color, color)
            text = render.Text(minutes_text(secs), color = color, height = 6, offset = -1)
        cell = time_slot(text, slot_width)
        if i > 0:
            cell = render.Padding(pad = (slot_gap, 0, 0, 0), child = cell)
        cells.append(cell)
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = [flag] + cells,
    )

BUS_BLOCK_HEIGHT = 10  # bus row block with 1-2 status lines; the 7px flag row is centred in it
BUS_BLOCK_HEIGHT_COMPACT = 8  # with 3 status lines

def bus_block(stops, arrivals, closed, height):
    """Bus row with a vertical divider that runs down to meet the horizontal rule."""

    def half(stop, left_pad, right_pad):
        # Box centres its child: the 7px flag row sits (height-7)/2 rows from the top, digits on its baseline.
        return render.Box(
            width = HALF_WIDTH + left_pad + right_pad,
            height = height,
            child = render.Padding(
                pad = (left_pad, 0, right_pad, 0),
                child = render.Box(width = HALF_WIDTH, height = FLAG_SIZE, child = stop_half(stop, arrivals[stop["id"]], stop["id"] in closed)),
            ),
        )

    return render.Column(children = [
        render.Box(
            width = 64,
            height = height,
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "start",
                children = [
                    half(stops[0], 1, 0),
                    render.Box(width = 1, height = height, color = COLOR_DIVIDER),
                    half(stops[1], 1, 1),
                ],
            ),
        ),
        render.Box(width = 64, height = 1, color = COLOR_DIVIDER),
    ])

def line_code(name):
    return LINE_CODES.get(name) or name.upper()[:3]

def status_line(name, severity, desc, compact):
    """Fixed line code on the left; only the status scrolls, in the space to its right."""

    # compact: 7 rows (caps + descender, no blank top row) so three lines fit
    kw = {"height": 7, "offset": 0} if compact else {}
    return render.Row(children = [
        render.Box(
            width = CODE_WIDTH,
            height = 7 if compact else 8,
            child = render.Row(expanded = True, main_align = "start", children = [render.Text(line_code(name), color = LINE_COLORS.get(name, COLOR_LINE_NAME), **kw)]),
        ),
        render.Marquee(
            width = 64 - CODE_WIDTH,
            child = render.Text(STATUS_TEXT.get(desc, desc), color = status_color(severity), **kw),
        ),
    ])

def status_lines(statuses, compact):
    return [status_line(name, sev, desc, compact) for name, sev, desc in (statuses or [])[:len(LINE_FIELDS)]]

def outage_lines():
    """Shown in the status area when any TfL call failed this render."""
    return [
        render.Text("TfL data", color = COLOR_LINE_NAME),
        render.Text("unavailable", color = COLOR_ALERT),
    ]

def setup_message(text):
    return render.Root(
        child = render.Padding(
            pad = 2,
            child = render.WrappedText(text, color = COLOR_LINE_NAME, font = "tom-thumb"),
        ),
    )

def main(config):
    fake = config.bool("fake", False)
    net = {
        "base": TFL_BASE_BROKEN if config.bool("fail", False) else TFL_BASE,
        "app_key": config.str("app_key", "") or (secret.decrypt(ENCRYPTED_APP_KEY) if ENCRYPTED_APP_KEY else "") or "",
        "outage": config.bool("outage", False),
        "failed": False,
    }
    stops = configured_stops(config, fake, net)
    if stops == None:
        return setup_message("Set two TfL bus stop IDs in the app settings")
    line_ids = configured_lines(config)

    # Fetch everything first so the layout can react to failures.
    arrivals = {stop["id"]: arrival_seconds(stop["id"], fake, net) for stop in stops}
    closed = closed_stops(stops, fake, net)
    statuses = line_statuses(line_ids, fake, net)

    compact = (len(line_ids) >= 3 or (fake and not line_ids and len(FAKE_STATUS) >= 3)) and not net["failed"]
    if compact:
        # rule on row 8, blank row 9, three 7-row lines on rows 10-16, 17-23, 24-30, blank row 31
        block = bus_block(stops, arrivals, closed, BUS_BLOCK_HEIGHT_COMPACT)
        pads = [1, 0, 0]
    else:
        # rule on row 10, status lines on rows 13-20 and 23-30, one blank row at the bottom
        block = bus_block(stops, arrivals, closed, BUS_BLOCK_HEIGHT)
        pads = [2, 2]
    lines = outage_lines() if net["failed"] else status_lines(statuses, compact)
    return render.Root(
        delay = 60,
        max_age = MAX_AGE_SECONDS,
        child = render.Column(
            children = [block] + [render.Padding(pad = (0, pads[i] if i < len(pads) else 0, 0, 0), child = line) for i, line in enumerate(lines)],
        ),
    )
