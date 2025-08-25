# Muni Departures — 2 lines only, single page display
# Styles: bus = red box w/ white outline (centered + 1px right shift), rail = colored circle

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_KEY = ""  # Set by user in configuration
AGENCY = "SF"
PER_LINE = 3

# Rail colors
RAIL_COLORS = {"J": "#E18813", "K": "#549DBF", "L": "#932290", "M": "#008851", "N": "#004988", "T": "#D40843", "F": "#F0E68C"}

# Fine-tuning (increase TOP_* to push text DOWN; increase SHIFT_* to push RIGHT)
TOP_NUDGE_BUS = 1
SHIFT_RIGHT_BUS = 1
TOP_NUDGE_RAIL = 2
SHIFT_RIGHT_RAIL = 3

# ---------- small utils ----------
def _sorted_ints(a):
    # Use recursive merge sort since no loops allowed
    if len(a) <= 1:
        return a

    mid = len(a) // 2
    left = _sorted_ints(a[:mid])
    right = _sorted_ints(a[mid:])

    # Merge without loops - use recursion
    def merge(l, r, result = None):
        if result == None:
            result = []
        if not l:
            return result + r
        if not r:
            return result + l
        if l[0] <= r[0]:
            return merge(l[1:], r, result + [l[0]])
        else:
            return merge(l, r[1:], result + [r[0]])

    return merge(left, right)

def _sorted_by_key0(items):
    # Sort by first element using same approach
    if len(items) <= 1:
        return items

    mid = len(items) // 2
    left = _sorted_by_key0(items[:mid])
    right = _sorted_by_key0(items[mid:])

    def merge(l, r, result = None):
        if result == None:
            result = []
        if not l:
            return result + r
        if not r:
            return result + l
        if l[0][0] <= r[0][0]:
            return merge(l[1:], r, result + [l[0]])
        else:
            return merge(l, r[1:], result + [r[0]])

    return merge(left, right)

def _take_labels(arr_sorted, n):
    # Use list slicing and comprehension
    limited = arr_sorted[:n]
    return ["Due" if m < 1 else str(m) for m in limited]

# RFC3339 parse (strip fractional seconds; handle Z/offset)
def _parse_rfc3339(ts):
    if ts == None or ts == "":
        return None
    tpos = ts.find("T")
    if tpos >= 0:
        zpos = ts.find("Z", tpos + 1)
        plus = ts.find("+", tpos + 1)
        minus = ts.find("-", tpos + 1)
        tzpos = zpos if zpos >= 0 else (plus if plus >= 0 and (minus < 0 or plus < minus) else minus)
        if tzpos > 0:
            frac = ts.find(".", tpos + 1)
            if frac >= 0 and frac < tzpos:
                ts = ts[:frac] + ts[tzpos:]
    return time.parse_time(ts)

def _mins_until(now, iso_ts):
    t = _parse_rfc3339(iso_ts)
    if t == None:
        return None
    diff = t.unix - now.unix
    return 0 if diff <= 0 else int((diff + 30) / 60)

def _get_visits(data):
    sd = data.get("ServiceDelivery") or ((data.get("Siri") or {}).get("ServiceDelivery"))
    if sd == None:
        return []
    smd = sd.get("StopMonitoringDelivery")
    if smd == None:
        return []
    smd0 = smd[0] if (type(smd) == "list" and len(smd) > 0) else (smd if type(smd) != "list" else {})
    v = smd0.get("MonitoredStopVisit")
    return v if v != None else []

# ---------- visuals ----------
def _is_rail(code):
    return RAIL_COLORS.get(str(code or "?").upper()) != None

def _rail_color(code):
    c = RAIL_COLORS.get(str(code or "?").upper())
    return c if c != None else "#888888"

def _get_text_color(line_code):
    """Get the appropriate text color for prediction times based on line type"""
    if _is_rail(line_code):
        return _rail_color(line_code)
    else:
        return "#E85112"  # Bus red color to match the bus badge

def _badge(code):
    txt = str(code or "?").upper()

    # Rail: colored circle (12px) centered in 15x14; with nudges
    if _is_rail(txt):
        rail_bot = 12 - 10 - TOP_NUDGE_RAIL
        if rail_bot < 0:
            rail_bot = 0
        return render.Box(
            width = 15,
            height = 13,
            child = render.Circle(
                color = _rail_color(txt),
                diameter = 12,
                child = render.Column(children = [
                    render.Box(height = TOP_NUDGE_RAIL),
                    render.Row(children = [
                        render.Box(width = SHIFT_RIGHT_RAIL),
                        render.Text(content = txt, font = "6x10", color = "#FFFFFF", height = 10),
                    ]),
                    render.Box(height = rail_bot),
                ]),
            ),
        )

    # Bus: explicit two-layer white outline so it NEVER gets covered
    inner_w = 15 - 2
    inner_h = 13 - 2
    bus_bot = inner_h - TOP_NUDGE_BUS - 10
    if bus_bot < 0:
        bus_bot = 0

    return render.Box(
        width = 15,
        height = 13,
        child = render.Box(
            color = "#FFFFFF",
            padding = 1,
            child = render.Box(
                width = inner_w,
                height = inner_h,
                color = "#FFFFFF",
                child = render.Box(
                    width = inner_w,
                    height = inner_h,
                    color = "#E85112",
                    child = render.Column(children = [
                        render.Box(height = TOP_NUDGE_BUS),
                        render.Row(children = [
                            render.Box(width = SHIFT_RIGHT_BUS),
                            render.Text(content = txt, font = "6x10", color = "#FFFFFF", height = 10),
                        ]),
                        render.Box(height = bus_bot),
                    ]),
                ),
            ),
        ),
    )

# ---------- data + layout ----------

def _get_stop_name(stop_code, api_key):
    """Get stop name by parsing XML from 511.org API"""
    if not stop_code or not api_key:
        return "UNKNOWN"

    # Get stop info from the API
    url = "https://api.511.org/transit/stops?api_key=" + api_key + "&operator_id=" + AGENCY + "&format=xml"
    resp = http.get(url, ttl_seconds = 300)  # Cache for 5 minutes
    body = resp.body() or ""

    # Look for our specific stop in the XML
    stop_marker = 'id="' + str(stop_code) + '"'
    stop_start = body.find(stop_marker)
    if stop_start >= 0:
        # Find the <Name> tag after our stop ID
        name_start = body.find("<Name>", stop_start)
        if name_start >= 0:
            name_end = body.find("</Name>", name_start)
            if name_end >= 0:
                # Extract the name content from <Name>539 Corbett Ave</Name>
                name_content = body[name_start + 6:name_end]  # +6 to skip "<Name>"
                if name_content:
                    # Decode HTML entities and replace ampersand with slash, then make uppercase
                    name = str(name_content).replace("&amp;", "&").replace("&", "/").upper()
                    return name

    # If we couldn't find the stop name in API, return the stop code
    return str(stop_code)

def _process_visits(visits, route_filter, now):
    rf = (route_filter or "").upper()

    # Process all visits using functional approach
    def process_visit(visit):
        mvj = visit.get("MonitoredVehicleJourney") if visit else None
        if mvj == None:
            return None

        code = mvj.get("LineRef")
        label = code if (code != None and code != "") else (mvj.get("PublishedLineName") or "?")

        # Apply route filter (no more "ALL" option)
        if rf != "":
            if (code == None or code.upper() != rf) and label.upper() != rf:
                return None

        call = mvj.get("MonitoredCall")
        if call == None:
            return None

        etd = call.get("ExpectedDepartureTime")
        eta = call.get("ExpectedArrivalTime")

        mins = None
        if etd:
            mins = _mins_until(now, etd)
        if mins == None and eta:
            mins = _mins_until(now, eta)

        if mins == None:
            return None

        # Get direction information
        direction_ref = mvj.get("DirectionRef") or ""
        direction = ""
        if direction_ref:
            # DirectionRef is usually "IB" or "OB" for inbound/outbound
            # Or sometimes "Inbound"/"Outbound" or "0"/"1"
            dir_str = str(direction_ref).upper()
            if dir_str in ["IB", "INBOUND", "0"]:
                direction = "IN"
            elif dir_str in ["OB", "OUTBOUND", "1"]:
                direction = "OUT"

        return (label, mins, direction)

    # Process all visits and collect results
    results = [process_visit(v) for v in visits]
    valid_results = [r for r in results if r != None]

    # Group by label, keeping direction info
    def group_by_label(results):
        grouped = {}

        def add_to_group(result):
            label, mins, direction = result
            if label not in grouped:
                grouped[label] = {"times": [], "direction": direction}
            grouped[label]["times"].append(mins)

            # Use the first direction we encounter for this line
            if not grouped[label]["direction"] and direction:
                grouped[label]["direction"] = direction

        # Apply add_to_group to each result using proper for loop
        for r in results:
            add_to_group(r)
        return grouped

    return group_by_label(valid_results)

def _fetch(stop_code, route_filter, api_key):
    if not stop_code or not api_key:
        return {"ok": False, "line": "?", "labels": ["No", "Stop"], "stop_name": "NO STOP"}

    now = time.now()

    # StopMonitoring API uses JSON format
    url = "https://api.511.org/transit/StopMonitoring?api_key=" + api_key + "&agency=" + AGENCY + "&stopCode=" + stop_code + "&format=json"
    resp = http.get(url, ttl_seconds = 30)
    body = resp.body() or ""
    i = body.find("{")
    if i < 0:
        return {"ok": False, "line": "?", "labels": ["No", "Data"], "stop_name": "ERROR"}

    # Parse JSON response
    data = json.decode(body[i:])
    visits = _get_visits(data)

    # Get the stop name using the XML-based stops API
    stop_name = _get_stop_name(stop_code, api_key)

    grouped = _process_visits(visits, route_filter, now)

    rf = (route_filter or "").upper()
    if rf != "":
        # Handle filtered case (now all cases are filtered since no "ALL" option)
        lines = list(grouped.keys())
        if len(lines) > 0:
            line = lines[0]
            line_data = grouped.get(line)
            labels = _take_labels(_sorted_ints(line_data["times"]), PER_LINE)
            direction = line_data["direction"]
            if len(labels) > 0:
                return {"ok": True, "line": line, "labels": labels, "stop_name": stop_name, "direction": direction}
        return {"ok": False, "line": (route_filter or "?"), "labels": ["No", "Data"], "stop_name": stop_name, "direction": ""}

    # If no route filter specified, return no data
    return {"ok": False, "line": "?", "labels": ["No", "Filter"], "stop_name": stop_name, "direction": ""}

def _create_stop_name_widget(stop_name):
    """Create stop name widget with scrolling if needed"""
    if not stop_name:
        stop_name = "UNKNOWN"

    # Calculate approximate text width (tom-thumb font is about 4 pixels per character)
    text_width = len(stop_name) * 4
    container_width = 43  # Available width for text

    # If text fits, use static text left-aligned
    if text_width <= container_width:
        return render.Text(
            content = stop_name,
            font = "tom-thumb",
            color = "#FFFFFF",
        )

    # If text is too long, use basic marquee with slower speed
    return render.Marquee(
        width = container_width,
        child = render.Text(
            content = stop_name + "     ",  # Add spacing for loop
            font = "tom-thumb",
            color = "#FFFFFF",
        ),
        delay = 80,  # Milliseconds between scroll steps (higher = slower)
    )

def _row(line_label, labels, stop_name = None, direction = ""):
    times_str = " ".join(labels) if labels else "No Data"

    # Create the badge
    badge = _badge(line_label)

    # Get the appropriate color for the prediction times
    text_color = _get_text_color(line_label)

    # Create stop name display with left alignment and scrolling
    display_stop = stop_name or "UNKNOWN"
    stop_name_widget = _create_stop_name_widget(display_stop)

    # Create times display with direction in white and times in color
    times_widgets = []
    if direction:
        times_widgets.append(render.Text(
            content = direction + " ",
            font = "tom-thumb",
            color = "#FFFFFF",  # Direction in white
        ))
        times_widgets.append(render.Text(
            content = times_str,
            font = "tom-thumb",
            color = text_color,  # Times in line color
        ))
    else:
        times_widgets.append(render.Text(
            content = times_str,
            font = "tom-thumb",
            color = text_color,
        ))

    return render.Box(
        height = 15,  # Reduced height to fit two rows
        child = render.Row(children = [
            render.Box(width = 2, height = 15),  # left pad
            render.Box(width = 15, height = 15, child = badge),  # badge
            render.Box(width = 2, height = 15),  # gutter
            render.Box(
                width = 43,
                height = 15,
                child = render.Column(
                    main_align = "end",
                    cross_align = "start",  # Changed to "start" for left alignment
                    children = [
                        stop_name_widget,  # Now with marquee scrolling
                        render.Row(children = times_widgets),  # Direction + times in separate colors
                    ],
                ),
            ),
        ]),
    )

def _render_combo(stop_code, route_code, api_key):
    r = _fetch(stop_code, route_code, api_key)
    if r.get("ok"):
        return _row(r.get("line"), r.get("labels"), r.get("stop_name"), r.get("direction", ""))
    return _row(r.get("line") or (route_code or "?"), r.get("labels") or ["No", "Data"], r.get("stop_name"), "")

def main(config):
    # Get API key from config
    api_key = config.get("api_key") or ""

    # Check if API key is provided
    if not api_key:
        return render.Root(
            child = render.Column(children = [
                render.Box(height = 3),
                render.Text("API Key Required", font = "6x10", color = "#FFFFFF"),
                render.Box(height = 2),
                render.Text("Get free key at", font = "tom-thumb", color = "#CCCCCC"),
                render.Text("511.org/developers", font = "tom-thumb", color = "#CCCCCC"),
                render.Box(height = 2),
                render.Text("Add it in settings", font = "tom-thumb", color = "#CCCCCC"),
            ]),
        )

    # Extract configs for just 2 lines
    sc1 = config.get("stop_code_1") or ""
    rc1 = config.get("route_filter_1") or "F"
    sc2 = config.get("stop_code_2") or ""
    rc2 = config.get("route_filter_2") or "J"

    # Single page with 2 lines - no animation/rotation needed
    return render.Root(
        child = render.Column(children = [
            render.Box(height = 1),  # Top padding for even spacing
            _render_combo(sc1, rc1, api_key),
            render.Box(height = 1),  # Reduced spacing between the two rows
            _render_combo(sc2, rc2, api_key),
        ]),
    )

# ---------- Settings ----------

def get_schema():
    # Build options list using list comprehension (removed "All lines" option)
    line_data = [
        # Rail & historic
        ("F Market & Wharves", "F"),
        ("J Church", "J"),
        ("K Ingleside", "K"),
        ("L Taraval", "L"),
        ("M Ocean View", "M"),
        ("N Judah", "N"),
        ("T Third Street", "T"),
        # Cable cars
        ("California Cable Car", "C"),
        ("Powell–Hyde Cable Car", "PH"),
        ("Powell–Mason Cable Car", "PM"),
        # Buses (representative list)
        ("1 California", "1"),
        ("1X California Express", "1X"),
        ("2 Sutter", "2"),
        ("5 Fulton", "5"),
        ("5R Fulton Rapid", "5R"),
        ("6 Hayes/Parnassus", "6"),
        ("7 Haight/Noriega", "7"),
        ("8 Bayshore", "8"),
        ("8AX Bayshore A Express", "8AX"),
        ("8BX Bayshore B Express", "8BX"),
        ("9 San Bruno", "9"),
        ("9R San Bruno Rapid", "9R"),
        ("10 Townsend", "10"),
        ("12 Folsom/Pacific", "12"),
        ("14 Mission", "14"),
        ("14R Mission Rapid", "14R"),
        ("15 Bayview Hunters Point Express", "15"),
        ("18 46th Avenue", "18"),
        ("19 Polk", "19"),
        ("22 Fillmore", "22"),
        ("23 Monterey", "23"),
        ("24 Divisadero", "24"),
        ("25 Treasure Island", "25"),
        ("27 Bryant", "27"),
        ("28 19th Avenue", "28"),
        ("28R 19th Avenue Rapid", "28R"),
        ("29 Sunset", "29"),
        ("30 Stockton", "30"),
        ("30X Marina Express", "30X"),
        ("31 Balboa", "31"),
        ("33 Ashbury/18th Street", "33"),
        ("35 Eureka", "35"),
        ("36 Teresita", "36"),
        ("37 Corbett", "37"),
        ("38 Geary", "38"),
        ("38R Geary Rapid", "38R"),
        ("39 Coit", "39"),
        ("43 Masonic", "43"),
        ("44 O'Shaughnessy", "44"),
        ("45 Union/Stockton", "45"),
        ("47 Van Ness", "47"),
        ("48 Quintara/24th Street", "48"),
        ("49 Van Ness/Mission", "49"),
        ("52 Excelsior", "52"),
        ("54 Felton", "54"),
        ("55 Dogpatch", "55"),
        ("56 Rutland", "56"),
        ("57 Parkmerced", "57"),
        ("58 Lake Merced", "58"),
        ("66 Quintara", "66"),
        ("67 Bernal Heights", "67"),
        ("78X 16th St Arena Express", "78X"),
        ("90 San Bruno Owl", "90"),
        ("91 3rd St/19th Ave Owl", "91"),
        ("714 BART Early Bird", "714"),
    ]

    # Create options using list comprehension
    opts = [schema.Option(display = p[0], value = p[1]) for p in line_data]

    # Schema - API key first, then 2 lines
    fields = []

    # API Key (required)
    fields.append(schema.Text(
        id = "api_key",
        name = "511.org API Key",
        desc = "Free API key from 511.org/developers (required)",
        icon = "key",
    ))

    # Line 1
    fields.append(schema.Dropdown(
        id = "route_filter_1",
        name = "Line #1",
        desc = "Pick a specific line",
        icon = "bus",
        options = opts,
        default = "F",  # Default to F line instead of ALL
    ))
    fields.append(schema.Text(
        id = "stop_code_1",
        name = "Stop Code #1",
        desc = "Muni stop code (e.g., 16995)",
        icon = "mapPin",
    ))

    # Line 2
    fields.append(schema.Dropdown(
        id = "route_filter_2",
        name = "Line #2",
        desc = "Pick a specific line",
        icon = "bus",
        options = opts,
        default = "J",  # Default to J line instead of ALL
    ))
    fields.append(schema.Text(
        id = "stop_code_2",
        name = "Stop Code #2",
        desc = "Muni stop code (e.g., 16995)",
        icon = "mapPin",
    ))

    return schema.Schema(version = "1", fields = fields)
