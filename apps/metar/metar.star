load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("secret.star", "secret")
load("schema.star", "schema")

ADDS_URL = "https://www.aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=csv&stationString=%s&mostrecentforeachstation=constraint&hoursBeforeNow=2"
DEFAULT_AIRPORT = "KJFK, KLGA, KBOS, KDCA"

# encryption, schema
# fail expired, add timeout to Root
# play with fonts

MAX_AGE = 60 * 10

def decoded_result_for_airport(config, airport):
    cache_key = "metar_cache_" + airport
    cached_result = cache.get(cache_key)
    if (cached_result != None):
        result = cached_result
    else:
        rep = http.get(ADDS_URL % airport)
        if rep.status_code != 200:
            return {
                "color": "#000000",
                "text": "Received error %s for %s" % (rep.status_code, airport),
                "flight_category": "ERR",
            }

        result = rep.body()

        cache.set(cache_key, result, ttl_seconds = 60)
        print("fetched for %s" % airport)

    lines = result.strip().split("\n")

    key_line = None
    data_line = None

    for line in lines:
        if line.startswith("raw_text"):
            key_line = line
        elif line.startswith(airport + " "):
            data_line = line

    if data_line == None:
        return {
            "color": "#000000",
            "text": "Invalid airport code %s" % airport,
            "flight_category": "ERR",
        }

    if key_line == None:
        return {
            "color": "#000000",
            "text": "Could not parse METAR",
            "flight_category": "ERR",
        }

    decoded = {}
    for label, value in zip(key_line.split(","), data_line.split(",")):
        decoded[label] = value

    response = {
        "color": color_for_state(decoded),
        "text": decoded["raw_text"],
        "flight_category": decoded["flight_category"],
    }
    return response

def color_for_state(result):
    category = result["flight_category"]
    if category == "VFR":
        return "#00FF00"
    elif category == "IFR":
        return "#FF0000"
    elif category == "MVFR":
        return "#0000FF"
    elif category == "LIFR":
        return "#FF00FF"
    elif category == "ERR" or category == "UNK":
        return "#000000"
    else:
        print("Unknown category %s" % category)
        return "#FFFFFF"

def render_single_airport(config, airport):
    use_small_font = config.get("use_small_font") or False

    result = decoded_result_for_airport(config, airport)
    text = result["text"]
    category = result["flight_category"].upper()
    color = result["color"]

    if use_small_font:
        text_widget = render.WrappedText(
            text,
            color = "#FFFFFF",
            font = "tom-thumb",
            linespacing = 0,
            width = 64,
        )

        return render.Root(
            child = render.Column([
                render.Box(height = 2, width = 64, color = color),
                render.Marquee(
                    text_widget,
                    offset_start = 8,
                    offset_end = 48,
                    scroll_direction = "vertical",
                    height = 32,
                ),
            ]),
            delay = 200,
            max_age = MAX_AGE,
        )
    else:
        text_widget = render.WrappedText(
            text,
            color = "#FFFFFF",
            font = "tb-8",
            linespacing = 0,
            width = 62,
        )

        return render.Root(
            child = render.Row([
                render.Marquee(
                    text_widget,
                    offset_start = 8,
                    offset_end = 48,
                    scroll_direction = "vertical",
                    height = 32,
                ),
                render.Box(height = 64, width = 2, color = color),
            ]),
            delay = 200,
            max_age = MAX_AGE,
        )

def render_four_airports(config, airports):
    row_widgets = []
    for airport in airports:
        result = decoded_result_for_airport(config, airport)
        color = result["color"]
        row_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = 24, height = 8),
                        render.Text(airport.upper() + " "),
                    ]),
                    render.Circle(color = color, diameter = 6),
                    render.Text(" %s" % result["flight_category"], color = color),
                ],
                cross_align = "center",
            ),
        )

    return render.Root(
        child = render.Marquee(
            render.Column(row_widgets),
            height = 32,
            offset_start = 32,
            scroll_direction = "vertical",
        ),
        delay = 100,
        max_age = MAX_AGE,
    )

def render_eight_airports(config, airports):
    left_widgets = []
    for airport in airports[:4]:
        result = decoded_result_for_airport(config, airport)
        color = result["color"]
        left_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = 24, height = 8),
                        render.Text(airport.upper() + " "),
                    ]),
                    render.Circle(color = color, diameter = 6),
                ],
                cross_align = "center",
            ),
        )
    right_widgets = []
    for airport in airports[4:]:
        result = decoded_result_for_airport(config, airport)
        color = result["color"]
        right_widgets.append(
            render.Row(
                [

                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = 24, height = 8),
                        render.Text(airport.upper() + " "),
                    ]),
                    render.Circle(color = color, diameter = 6),
                    render.Text(" %s" % result["flight_category"], color = color),
                ],
                cross_align = "center",
                expanded = True,
                main_align = "center",
            ),
        )

    return render.Root(
        child = render.Marquee(
            render.Row([
                render.Column(left_widgets),
                render.Box(width = 3, height = 32),
                render.Column(right_widgets),
            ]),
            height = 32,
            offset_start = 32,
            scroll_direction = "vertical",
        ),
        delay = 100,
        max_age = MAX_AGE,
    )

def render_fifteen_airports(config, airports):
    font = "tom-thumb"
    code_height = 6
    code_width = 12
    blob_diam = 4
    middle_spacer = 1

    left_widgets = []
    for airport in airports[:5]:
        result = decoded_result_for_airport(config, airport)
        color = result["color"]
        left_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = code_width, height = code_height),
                        render.Text(airport.upper(), font = font),
                    ]),
                    render.Circle(color = color, diameter = blob_diam),
                ],
                cross_align = "center",
            ),
        )
    mid_widgets = []
    for airport in airports[5:10]:
        result = decoded_result_for_airport(config, airport)
        color = result["color"]
        mid_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = code_width, height = code_height),
                        render.Text(airport.upper(), font = font),
                    ]),
                    render.Circle(color = color, diameter = blob_diam),
                ],
                cross_align = "center",
            ),
        )
    right_widgets = []
    for airport in airports[10:15]:
        result = decoded_result_for_airport(config, airport)
        color = result["color"]
        right_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = code_width, height = code_height),
                        render.Text(airport.upper(), font = font),
                    ]),
                    render.Circle(color = color, diameter = blob_diam),
                ],
                cross_align = "center",
            ),
        )

    return render.Root(
        child = render.Box(render.Marquee(
            render.Row([
                render.Column(left_widgets),
                render.Box(width = middle_spacer, height = 32),
                render.Column(mid_widgets),
                render.Box(width = middle_spacer, height = 32),
                render.Column(right_widgets),
            ]),
            height = 32,
            offset_start = 32,
            scroll_direction = "vertical",
        )),
        delay = 100,
        max_age = MAX_AGE,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "icao",
                name = "Airport(s)",
                desc = "Comma-separated list of ICAO airport codes. Use just one for METAR text.",
                icon = "plane",
            ),
            schema.Toggle(
                id = "use_small_font",
                name = "Use Small Font",
                desc = "When displaying a single airport, use compressed text.",
                icon = "compress",
                default = False,
            ),
        ],
    )

def main(config):
    airports = config.get("icao") or DEFAULT_AIRPORT
    airports = airports.upper()
    airports = [a.strip() for a in airports.split(",")]
    if len(airports) == 1:
        return render_single_airport(config, airports[0])
    elif len(airports) <= 4:
        return render_four_airports(config, airports)
    elif len(airports) <= 8:
        return render_eight_airports(config, airports)
    else:
        return render_fifteen_airports(config, airports)
