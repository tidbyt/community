load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STOP_ID = "NSR:StopPlace:6286"
QUAY_ID = "NSR:Quay:11544"
ENDPOINT = "https://api.entur.io/journey-planner/v3/graphql"
CLIENT_NAME = "jakobbbbbbb-tidbyt-colletts"
TIMEZONE = "Europe/Oslo"
HTTP_TTL = 30
STALE_TTL = 600
QUERY = """
query Departures($stopId: String!, $n: Int!) {
    stopPlace(id: $stopId) {
        id name
        quays {
            id name publicCode
            estimatedCalls(numberOfDepartures: $n, timeRange: 7200,
                arrivalDeparture: departures, includeCancelledTrips: true) {
                aimedDepartureTime expectedDepartureTime realtime cancellation predictionInaccurate
                destinationDisplay { frontText }
                serviceJourney { line { id publicCode transportMode presentation { colour textColour } } }
            }
        }
    }
}
"""
FIXTURE_JSON = """{
    "stopPlace": {"id": "NSR:StopPlace:6286", "name": "Colletts gate", "quays": [
        {"id": "NSR:Quay:11544", "name": "Colletts gate", "publicCode": "1", "situations": [],
         "estimatedCalls": [
            {"expectedDepartureTime": "2026-09-24T12:02:30+02:00", "aimedDepartureTime": "2026-09-24T12:02:30+02:00", "realtime": true, "destinationDisplay": {"frontText": "Helsfyr"}},
            {"expectedDepartureTime": "2026-09-24T12:08:00+02:00", "aimedDepartureTime": "2026-09-24T12:08:00+02:00", "realtime": true, "destinationDisplay": {"frontText": "Helsfyr"}},
            {"expectedDepartureTime": "2026-09-24T12:18:00+02:00", "aimedDepartureTime": "2026-09-24T12:18:00+02:00", "realtime": true, "destinationDisplay": {"frontText": "Helsfyr"}},
            {"expectedDepartureTime": "2026-09-24T12:25:00+02:00", "aimedDepartureTime": "2026-09-24T12:25:00+02:00", "realtime": true, "destinationDisplay": {"frontText": "Helsfyr"}}
         ]}
    ]}
}"""

WHITE = "#f2f2e8"
GREY = "#939b98"
AMBER = "#e8b85c"
RED = "#ff4545"
BUS_RED = "#e60000"
ROW_FONT = "tom-thumb"
NUMBER_FONT = "CG-pixel-3x5-mono"
PANEL_WIDTH = 64
HEADER_HEIGHT = 8
ROW_HEIGHT = 8
BADGE_WIDTH = 11
DEST_WIDTH = 26
TIME_WIDTH = 20
FOCUS_FONT = "tb-8"
LARGE_FONT = "6x13"
FRAME_DELAY = 150
MAX_FRAMES = 96

def mapping(value):
    return value if type(value) == "dict" else {}

def sequence(value):
    return value if type(value) == "list" else []

def string(value, default = ""):
    return value if type(value) == "string" else default

def digits(value):
    return bool(value) and all([char in "0123456789" for char in value.elems()])

def integer(value, default, low, high):
    value = str(value).strip()
    unsigned = value[1:] if value.startswith("-") else value
    if not digits(unsigned) or len(unsigned) > 6:
        return default
    return max(low, min(high, int(value)))

def boolean(value, default = False):
    value = str(value).lower()
    if value in ["true", "1", "yes", "on"]:
        return True
    if value in ["false", "0", "no", "off"]:
        return False
    return default

def nsr_id(value, prefix, default):
    value = string(value)
    return value if value.startswith(prefix) and digits(value[len(prefix):]) else default

def stop_value(value):
    if type(value) == "string" and value.startswith("{"):
        value = mapping(json.decode(value, default = {})).get("value")
    elif type(value) == "dict":
        value = value.get("value")
    return nsr_id(value, "NSR:StopPlace:", STOP_ID)

def settings(config):
    stop = stop_value(config.get("stop", STOP_ID))
    default_quay = QUAY_ID if stop == STOP_ID else "all"
    quay = config.get("quay", default_quay)
    return {
        "stop": stop,
        "quay": "all" if quay == "all" else nsr_id(quay, "NSR:Quay:", default_quay),
        "rows": integer(config.get("rows", "3"), 3, 2, 4),
        "layout": "board" if config.get("layout") == "board" else "lounge",
        "walk": integer(config.get("walk_minutes", "2"), 2, 0, 15),
        "lang": "en" if config.get("lang") == "en" else "no",
        "clock": boolean(config.get("show_clock", "false")),
        "lines": [part.strip().lower() for part in string(config.get("lines", "")).split(",") if part.strip()],
        "destination": string(config.get("destination_filter", "")).strip().lower(),
    }

def localized(options, norwegian, english):
    return english if options["lang"] == "en" else norwegian

def parse_timestamp(value):
    value = string(value)
    if len(value) < 20 or value[4:5] != "-" or value[7:8] != "-" or value[10:11] != "T" or value[13:14] != ":" or value[16:17] != ":":
        return None
    parts = [value[:4], value[5:7], value[8:10], value[11:13], value[14:16], value[17:19]]
    if not all([digits(part) for part in parts]):
        return None
    year, month, day, hour, minute, second = [int(part) for part in parts]
    if month < 1 or month > 12 or hour > 23 or minute > 59 or second > 59:
        return None
    leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
    days = [31, 29 if leap else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if day < 1 or day > days[month - 1]:
        return None
    suffix = value[19:]
    if suffix.startswith("."):
        fraction = suffix[1:-1] if suffix.endswith("Z") else suffix[1:-6]
        if not digits(fraction):
            return None
        suffix = "Z" if suffix.endswith("Z") else suffix[-6:]
    if suffix != "Z":
        if len(suffix) != 6 or suffix[0] not in ["+", "-"] or suffix[3] != ":" or not digits(suffix[1:3] + suffix[4:6]):
            return None
        if int(suffix[1:3]) > 23 or int(suffix[4:6]) > 59:
            return None
    return time.parse_time(value).in_location(TIMEZONE)

def graphql(query, variables):
    response = http.post(
        ENDPOINT,
        headers = {"ET-Client-Name": CLIENT_NAME, "Content-Type": "application/json"},
        body = json.encode({"query": query, "variables": variables}),
        ttl_seconds = HTTP_TTL,
    )
    if response.status_code != 200:
        return None
    payload = mapping(json.decode(response.body(), default = {}))
    return None if payload.get("errors") else payload.get("data")

def valid_data(data, options):
    stop = mapping(mapping(data).get("stopPlace"))
    return stop.get("id") == options["stop"] and type(stop.get("quays")) == "list"

def fetch_departures(options, now):
    variables = {"stopId": options["stop"], "n": max(20, options["rows"] * 4)}
    key = "collettsbus:v2:" + json.encode(variables)
    data = graphql(QUERY, variables)
    if valid_data(data, options):
        cache.set(key, json.encode({"data": data, "saved": now.unix}), ttl_seconds = STALE_TTL)
        return data, False
    snapshot = mapping(json.decode(cache.get(key) or "{}", default = {}))
    if valid_data(snapshot.get("data"), options) and now.unix - snapshot.get("saved", 0) <= STALE_TTL:
        return snapshot["data"], True
    return None, False

def fixture(name):
    if name == "http_error":
        return None
    data = json.decode(FIXTURE_JSON)
    quay = data["stopPlace"]["quays"][0]
    calls = quay["estimatedCalls"]
    for call in calls:
        call["serviceJourney"] = {"line": {"id": "RUT:Line:37", "publicCode": "37", "transportMode": "bus", "presentation": {"colour": "E60000", "textColour": "FFFFFF"}}}
    if name == "crowded":
        for index in range(len(calls)):
            calls[index]["destinationDisplay"]["frontText"] = ["Jernbanetorget", "Helsfyr via sentrum", "Nydalen via Jernbanetorget", "Helsfyr"][index]
    elif name == "realtime_missing":
        for call in calls:
            call["realtime"] = False
    elif name == "cancellation":
        calls[0]["cancellation"] = True
    elif name == "all_cancelled":
        for call in calls:
            call["cancellation"] = True
    elif name == "delay":
        calls[0]["aimedDepartureTime"] = "2026-09-24T11:58:00+02:00"
    elif name == "disruption":
        quay["situations"] = [{"summary": [{"language": "no", "value": "Forsinkelser i sentrum"}, {"language": "en", "value": "Delays downtown"}]}]
    elif name == "empty":
        quay["estimatedCalls"] = []
    elif name == "now":
        calls[0]["expectedDepartureTime"] = "2026-09-24T12:00:30+02:00"
    elif name == "malformed":
        calls.insert(0, {"expectedDepartureTime": "2026-02-30T12:00:00+02:00"})
        calls[1]["serviceJourney"]["line"]["presentation"] = {"colour": "invalid"}
    elif name == "multimodal":
        for index in range(len(calls)):
            calls[index]["serviceJourney"]["line"].update({"publicCode": ["RE10", "B1", "1", "12"][index], "transportMode": ["rail", "water", "metro", "tram"][index], "presentation": {}})
    elif name == "typography":
        data["stopPlace"]["name"] = "\u00c5ndalsnes stasjon"
        for index in range(len(calls)):
            calls[index]["destinationDisplay"]["frontText"] = ["\u00c5s", "Gj\u00f8vik", "Lillestr\u00f8m", "Bod\u00f8 via Mosj\u00f8en"][index]
            calls[index]["serviceJourney"]["line"]["publicCode"] = ["RE10", "F6", "R14", "F7"][index]
    return data

def colour(value, fallback):
    value = string(value).lstrip("#")
    if len(value) != 6 or not all([char.lower() in "0123456789abcdef" for char in value.elems()]):
        return fallback
    return "#" + value

def selected_quays(data, options):
    quays = [mapping(quay) for quay in sequence(mapping(mapping(data).get("stopPlace")).get("quays"))]
    selected = [quay for quay in quays if options["quay"] == "all" or quay.get("id") == options["quay"]]
    if selected or options["stop"] == STOP_ID:
        return selected
    return quays

def parse_calls(data, options, now):
    parsed = []
    for quay in selected_quays(data, options):
        for raw in sequence(quay.get("estimatedCalls")):
            raw = mapping(raw)
            expected = parse_timestamp(raw.get("expectedDepartureTime")) or parse_timestamp(raw.get("aimedDepartureTime"))
            if expected == None:
                continue
            seconds = expected.unix - now.unix
            if seconds < options["walk"] * 60 or seconds > 7200:
                continue
            line = mapping(mapping(raw.get("serviceJourney")).get("line"))
            code = string(line.get("publicCode"), "?") or "?"
            if options["lines"] and code.lower() not in options["lines"] and string(line.get("id")).lower() not in options["lines"]:
                continue
            destination = string(mapping(raw.get("destinationDisplay")).get("frontText"), "?")
            if options["destination"] not in destination.lower():
                continue
            aimed = parse_timestamp(raw.get("aimedDepartureTime")) or expected
            presentation = mapping(line.get("presentation"))
            parsed.append({
                "expected": expected,
                "seconds": seconds,
                "code": code,
                "destination": destination,
                "cancelled": raw.get("cancellation") == True,
                "realtime": raw.get("realtime") == True and raw.get("predictionInaccurate") != True,
                "delay": expected.unix - aimed.unix > 120,
                "background": colour(presentation.get("colour"), BUS_RED),
                "foreground": colour(presentation.get("textColour"), WHITE),
            })
    return sorted(parsed, key = lambda call: call["expected"].unix)

def select_calls(calls, count):
    selected = calls[:count]
    if selected and all([call["cancelled"] for call in selected]):
        upcoming = [call for call in calls if not call["cancelled"]]
        if upcoming:
            selected[-1] = upcoming[0]
    return selected

def format_countdown(call, options):
    if call["seconds"] < 60:
        return localized(options, "n\u00e5", "now")
    if call["seconds"] < 900:
        return "%dm" % (call["seconds"] // 60)
    return call["expected"].format("15:04")

def abbreviate(value):
    return value.replace("Jernbanetorget", "Jernbanetorg.").replace(" bussterminal", " bst.").replace(" stasjon", " st.")

def text(value, color = WHITE, font = ROW_FONT):
    return render.Text(value, font = font, color = color)

def cell(child, width, height = ROW_HEIGHT, align = "start", color = "#0000"):
    return render.Box(
        width = width,
        height = height,
        color = color,
        child = render.Row(expanded = True, main_align = align, children = [child]),
    )

def fit(value, width, font = ROW_FONT):
    if text(value, font = font).size()[0] <= width:
        return value
    for length in range(len(value), -1, -1):
        candidate = value[:length] + "."
        if text(candidate, font = font).size()[0] <= width:
            return candidate
    return ""

def badge(code, background = BUS_RED, foreground = WHITE, height = 7, width = BADGE_WIDTH):
    return render.Box(
        width = width,
        height = height,
        color = background,
        child = render.Padding(
            pad = (0, 0, 1, 0),
            child = render.Row(expanded = True, main_align = "end", children = [text(fit(code, width - 1, NUMBER_FONT), foreground, NUMBER_FONT)]),
        ),
    )

def bus_icon(color = AMBER):
    return render.Column(children = [
        render.Box(width = 5, height = 1, color = color),
        render.Row(children = [render.Box(width = 1, height = 2, color = color), render.Box(width = 3, height = 2, color = "#000000"), render.Box(width = 1, height = 2, color = color)]),
        render.Box(width = 5, height = 1, color = color),
        render.Row(children = [render.Box(width = 1, height = 1, color = color), render.Box(width = 3, height = 1), render.Box(width = 1, height = 1, color = color)]),
    ])

def header(options, now, data, stale):
    label = string(mapping(mapping(data).get("stopPlace")).get("name"), localized(options, "AVGANGER", "DEPARTURES")).upper()
    if options["stop"] == STOP_ID and options["quay"] == QUAY_ID:
        label = "C.GT>S" if options["clock"] else "COLL.>SENTRUM"
    label_width = 31 if options["clock"] else 51
    children = [cell(bus_icon(), 7, HEADER_HEIGHT), cell(text(fit(label, label_width), AMBER), label_width, HEADER_HEIGHT)]
    children.append(cell(text("~" if stale else "", AMBER), 4, HEADER_HEIGHT))
    if options["clock"]:
        children.append(cell(text(now.format("15:04"), GREY, NUMBER_FONT), TIME_WIDTH, HEADER_HEIGHT, "end"))
    return render.Row(children = children)

def row(call, options, animate, badge_width):
    height = 6 if options["rows"] == 4 else ROW_HEIGHT
    destination_width = DEST_WIDTH - (badge_width - BADGE_WIDTH)
    color = GREY if call["cancelled"] else WHITE
    destination = abbreviate(call["destination"])
    if animate:
        destination_widget = render.Marquee(width = destination_width, child = text(destination[:24], color), delay = 10)
    else:
        destination_widget = text(fit(destination, destination_width), color)
    countdown = format_countdown(call, options)
    time_color = AMBER if call["seconds"] <= (options["walk"] + 1) * 60 else WHITE
    if not call["realtime"]:
        time_color = GREY
    if call["cancelled"]:
        countdown = "X"
        time_color = RED
    content = render.Row(
        cross_align = "center",
        children = [
            cell(badge(call["code"], call["background"] if not call["cancelled"] else "#552222", call["foreground"] if not call["cancelled"] else GREY, min(7, height - 1), badge_width), badge_width, height),
            render.Box(width = 2, height = 1),
            cell(destination_widget, destination_width, height),
            cell(render.Box(width = 1, height = 1, color = RED if call["delay"] else "#000000"), 2, height),
            cell(text(countdown, time_color, NUMBER_FONT), TIME_WIDTH, height, "end"),
        ],
    )
    if call["cancelled"]:
        content = render.Stack(children = [content, render.Padding(pad = (badge_width + 2, height // 2, 0, 0), child = render.Box(width = destination_width, height = 1, color = GREY))])
    return content

def error_screen(options, empty = False, stale = False):
    message = localized(options, "Ingen avganger", "No departures") if empty else localized(options, "Ingen data", "No data")
    detail = localized(options, "Neste 2 timer", "Next 2 hours") if empty else localized(options, "Pr\u00f8v igjen", "Try again")
    if stale:
        detail = localized(options, "Gamle data ~", "Stale data ~")
    return render.Box(width = 62, height = 24, child = render.Column(cross_align = "center", children = [text(message), render.Box(height = 2, width = 1), text(detail, GREY)]))

def placed(child, left, top):
    return render.Padding(pad = (left, top, 0, 0), child = child)

def lounge_header(options, now, data, stale, index, count):
    name = string(mapping(mapping(data).get("stopPlace")).get("name"), localized(options, "AVGANGER", "DEPARTURES"))
    name = name.upper().replace(" GATE", " GT").replace(" STASJON", " ST.")
    width = 24 if options["clock"] else 45
    children = [placed(text(fit(name, width), GREY), 0, 1)]
    if options["clock"]:
        children.append(placed(text(now.format("15:04"), GREY, NUMBER_FONT), 25, 1))
    children.append(placed(text("~" if stale else "", AMBER, NUMBER_FONT), 46, 1))
    if count:
        children.append(placed(text("%d/%d" % (index + 1, count), GREY, NUMBER_FONT), 51, 1))
    return render.Stack(children = children)

def lounge_page(call, options, now, data, stale, index, count, budget):
    heading = lounge_header(options, now, data, stale, index, count)
    cancelled = call["cancelled"]
    route_width = min(26, max(13, text(call["code"], font = FOCUS_FONT).size()[0] + 2))
    route = render.Box(
        width = route_width,
        height = 10,
        color = "#552222" if cancelled else call["background"],
        child = text(fit(call["code"], route_width - 2, FOCUS_FONT), GREY if cancelled else call["foreground"], FOCUS_FONT),
    )
    countdown = format_countdown(call, options)
    if call["seconds"] >= 60 and call["seconds"] < 900:
        countdown = "%d min" % (call["seconds"] // 60)
    time_color = AMBER if call["seconds"] <= (options["walk"] + 1) * 60 else WHITE
    if not call["realtime"]:
        time_color = GREY
    if cancelled:
        countdown = localized(options, "INNSTILT", "CANCELLED")
        time_color = RED
    time_font = LARGE_FONT
    available = 62 - route_width - 3
    if text(countdown, font = time_font).size()[0] > available:
        countdown = format_countdown(call, options) if not cancelled else localized(options, "AVLYST", "CANCEL")
    if text(countdown, font = time_font).size()[0] > available:
        time_font = FOCUS_FONT
    number = text(fit(countdown, available, time_font), time_color, time_font)
    destination = fit(abbreviate(call["destination"]), 62 + budget - 13, FOCUS_FONT)
    destination_text = text(destination, GREY if cancelled else WHITE, FOCUS_FONT)
    scroll = destination_text.size()[0] > 62
    destination_widget = render.Marquee(width = 62, child = destination_text, delay = 12, offset_end = 124) if scroll else destination_text
    children = [
        heading,
        placed(route, 0, 9),
        placed(number, 62 - number.size()[0], 7 if time_font == LARGE_FONT else 10),
        placed(destination_widget, 0, 22),
    ]
    if call["delay"] and not cancelled:
        children.append(placed(render.Box(width = 1, height = 2, color = RED), route_width + 1, 13))
    page = render.Stack(children = children)
    return page if scroll else render.Animation(children = [page for _ in range(min(24, budget))])

def lounge_content(selected, options, now, data, stale):
    heading = lounge_header(options, now, data, stale, 0, 0)
    if not selected:
        empty = data != None and not stale
        message = localized(options, "Ingen", "No")
        detail = localized(options, "avganger", "departures") if empty else "data"
        return render.Stack(children = [heading, placed(text(message, WHITE, FOCUS_FONT), 0, 10), placed(text(detail, GREY, FOCUS_FONT), 0, 22)])
    budget = MAX_FRAMES // len(selected)
    pages = [lounge_page(call, options, now, data, stale, index, len(selected), budget) for index, call in enumerate(selected)]
    return render.Sequence(children = pages)

def main(config):
    options = settings(config)
    now = time.now().in_location(TIMEZONE)
    fixture_name = config.get("debug_fixture", "")
    snapshot = mapping(json.decode(config.get("debug_snapshot", "{}"), default = {}))
    stale = False
    if fixture_name:
        now = time.parse_time("2026-09-24T12:00:00+02:00").in_location(TIMEZONE)
        data = fixture(fixture_name)
        stale = fixture_name == "stale"
    elif snapshot:
        saved = snapshot.get("saved", 0)
        age = now.unix - saved if type(saved) in ["int", "float"] else STALE_TTL + 1
        data = snapshot.get("data") if age >= 0 and age <= STALE_TTL and valid_data(snapshot.get("data"), options) else None
        stale = data != None
    elif boolean(config.get("debug_offline", "false")):
        data = None
    else:
        data, stale = fetch_departures(options, now)
        if data != None and not stale and boolean(config.get("debug_export", "false")):
            print("COLLETTS_SNAPSHOT=" + json.encode({"data": data, "saved": now.unix}))
    heading = header(options, now, data, stale)
    calls = parse_calls(data, options, now)
    selected = select_calls(calls, options["rows"])
    badge_width = min(19, max([BADGE_WIDTH] + [text(call["code"], font = NUMBER_FONT).size()[0] + 1 for call in selected]))
    children = [heading]
    marquee_used = False
    for call in selected:
        animate = not marquee_used and text(abbreviate(call["destination"])).size()[0] > DEST_WIDTH - (badge_width - BADGE_WIDTH) and not call["cancelled"]
        children.append(row(call, options, animate, badge_width))
        marquee_used = marquee_used or animate
    if not selected:
        children.append(error_screen(options, empty = data != None and not stale, stale = stale))
    content = render.Column(children = children)
    if options["layout"] == "lounge":
        content = lounge_content(selected, options, now, data, stale)
    return render.Root(
        delay = FRAME_DELAY,
        max_age = 60,
        child = render.Padding(pad = (1, 0, 1, 0), child = content),
    )

def search_stops(pattern):
    if not string(pattern).strip():
        return [schema.Option(display = "Colletts gate, Oslo", value = STOP_ID)]
    response = http.get(
        "https://api.entur.io/geocoder/v1/autocomplete",
        params = {"text": pattern, "layers": "venue", "size": "10"},
        headers = {"ET-Client-Name": CLIENT_NAME},
        ttl_seconds = 300,
    )
    if response.status_code != 200:
        return []
    payload = mapping(json.decode(response.body(), default = {}))
    options = []
    for feature in sequence(payload.get("features")):
        properties = mapping(mapping(feature).get("properties"))
        identifier = nsr_id(properties.get("id"), "NSR:StopPlace:", "")
        if identifier:
            options.append(schema.Option(display = string(properties.get("label"), identifier), value = identifier))
    return options

def quay_fields(stop):
    selected_stop = stop_value(stop)
    data = mapping(graphql(QUERY, {"stopId": selected_stop, "n": 3}))
    quays = sequence(mapping(data.get("stopPlace")).get("quays"))
    options = [schema.Option(display = "All platforms / alle plattformer", value = "all")]
    for quay in quays:
        quay = mapping(quay)
        identifier = nsr_id(quay.get("id"), "NSR:Quay:", "")
        if not identifier:
            continue
        destinations = [string(mapping(mapping(call).get("destinationDisplay")).get("frontText")) for call in sequence(quay.get("estimatedCalls"))]
        hint = destinations[0] if destinations else string(quay.get("name"), identifier)
        platform = string(quay.get("publicCode")) or {QUAY_ID: "1", "NSR:Quay:11545": "2"}.get(identifier, identifier.split(":")[-1])
        options.append(schema.Option(display = "%s - %s" % (platform, hint), value = identifier))
    if len(options) == 1 and selected_stop == STOP_ID:
        options.extend([schema.Option(display = "1 - Helsfyr via Sentrum", value = QUAY_ID), schema.Option(display = "2 - Nydalen T", value = "NSR:Quay:11545")])
    return [schema.Dropdown(
        id = "quay",
        name = "Platform / plattform",
        desc = "Choose one direction or all platforms.",
        icon = "trainSubway",
        default = QUAY_ID if selected_stop == STOP_ID else "all",
        options = options,
    )]

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Typeahead(id = "stop", name = "Station / holdeplass", desc = "Search Norway. Default: Colletts gate, Oslo.", icon = "locationDot", handler = search_stops),
        schema.Generated(id = "platform_options", source = "stop", handler = quay_fields),
        schema.Text(id = "lines", name = "Lines / linjer", desc = "Optional comma-separated numbers or IDs, e.g. 37,RE10.", icon = "trainSubway", default = ""),
        schema.Text(id = "destination_filter", name = "Destination / retning", desc = "Optional destination substring.", icon = "filter", default = ""),
        schema.Dropdown(id = "layout", name = "Display / visning", desc = "Large departure pages or a compact board.", icon = "display", default = "lounge", options = [schema.Option(display = "Living room / stue", value = "lounge"), schema.Option(display = "Departure board / tavle", value = "board")]),
        schema.Dropdown(id = "rows", name = "Departures / avganger", desc = "Number of pages, or rows on the board.", icon = "list", default = "3", options = [schema.Option(display = str(count), value = str(count)) for count in [2, 3, 4]]),
        schema.Text(id = "walk_minutes", name = "Walk / gangtid", desc = "Walking minutes, 0 to 15.", icon = "personWalking", default = "2"),
        schema.Dropdown(id = "lang", name = "Language / spr\u00e5k", desc = "Display language.", icon = "language", default = "no", options = [schema.Option(display = "Norsk", value = "no"), schema.Option(display = "English", value = "en")]),
        schema.Toggle(id = "show_clock", name = "Clock / klokke", desc = "Show Oslo time in the header.", icon = "clock", default = False),
    ])
