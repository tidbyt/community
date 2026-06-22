load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

VERSION = "1.2"

DEFAULT_LAT = "47.60171996215939"
DEFAULT_LON = "-122.33195076343821"
DEFAULT_RADIUS = "5"
DEFAULT_ZIP = "98101"

def miles_to_lat_degrees(miles):
    return miles / 69.0

def miles_to_lon_degrees(miles):
    # Conservative estimate valid for ~30N-55N
    return miles / 53.0

def zip_to_coords(zip_code):
    url = "https://api.zippopotam.us/us/" + zip_code.strip()
    resp = http.get(url, ttl_seconds = 86400)
    if resp.status_code != 200:
        return None, None
    places = resp.json().get("places", [])
    if len(places) == 0:
        return None, None
    return float(places[0]["latitude"]), float(places[0]["longitude"])

def get_flights(lat, lon, radius_miles):
    lat_d = miles_to_lat_degrees(radius_miles)
    lon_d = miles_to_lon_degrees(radius_miles)

    url = (
        "https://opensky-network.org/api/states/all" +
        "?lamin=" + str(lat - lat_d) +
        "&lomin=" + str(lon - lon_d) +
        "&lamax=" + str(lat + lat_d) +
        "&lomax=" + str(lon + lon_d)
    )

    resp = http.get(url, ttl_seconds = 60)
    if resp.status_code != 200:
        print("OpenSky status:", resp.status_code)
        return None

    data = resp.json()
    return data.get("states", [])

CARDINAL_THRESHOLDS = [
    [22.5, "N"],
    [67.5, "NE"],
    [112.5, "E"],
    [157.5, "SE"],
    [202.5, "S"],
    [247.5, "SW"],
    [292.5, "W"],
    [337.5, "NW"],
]

def degrees_to_cardinal(deg):
    for threshold, label in CARDINAL_THRESHOLDS:
        if deg < threshold:
            return label
    return "N"

def format_flight_row(state):
    callsign = state[1]
    if callsign == None:
        callsign = "??????"
    callsign = callsign.strip()
    if callsign == "":
        callsign = state[0].upper()

    track = state[10]
    heading = degrees_to_cardinal(float(track)) if track != None else "?"

    alt_m = state[7]
    if alt_m != None:
        alt_ft = int(float(alt_m) * 3.28084)
        alt_str = str(alt_ft // 1000) + "Kft" if alt_ft >= 1000 else str(alt_ft) + "ft"
    else:
        alt_str = "---"

    vel_ms = state[9]
    if vel_ms != None:
        knots = int(float(vel_ms) * 1.944)
        vel_str = str(knots) + "kt"
    else:
        vel_str = "---"

    country = state[2] if state[2] != None else "?"

    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Text(callsign, font = "tb-8", color = "#00BFFF"),
                    render.Text(" " + heading, font = "tb-8", color = "#44FF88"),
                ],
            ),
            render.Row(
                children = [
                    render.Text(alt_str, font = "tb-8", color = "#FFFFFF"),
                    render.Text(" " + vel_str, font = "tb-8", color = "#FFD700"),
                ],
            ),
            render.Text(country, font = "tb-8", color = "#888888"),
            render.Box(height = 2),
        ],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "zip_code",
                name = "ZIP Code (US)",
                desc = "5-digit US ZIP code. Overrides lat/lon below if set.",
                icon = "mapPin",
                default = DEFAULT_ZIP,
            ),
            schema.Text(
                id = "lat",
                name = "Latitude",
                desc = "Decimal latitude — used only if ZIP is blank.",
                icon = "globe",
                default = DEFAULT_LAT,
            ),
            schema.Text(
                id = "lon",
                name = "Longitude",
                desc = "Decimal longitude — used only if ZIP is blank.",
                icon = "globe",
                default = DEFAULT_LON,
            ),
            schema.Text(
                id = "radius",
                name = "Radius (miles)",
                desc = "Search radius around your location.",
                icon = "expand",
                default = DEFAULT_RADIUS,
            ),
        ],
    )

def main(config):
    radius_miles = float(config.get("radius", DEFAULT_RADIUS))
    zip_code = config.get("zip_code", "").strip()

    if zip_code != "":
        lat, lon = zip_to_coords(zip_code)
        if lat == None:
            return render.Root(
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Text("Bad ZIP", font = "tb-8", color = "#FFD700"),
                        render.Text(zip_code, font = "tb-8", color = "#FF4444"),
                    ],
                ),
            )
    else:
        lat = float(config.get("lat", DEFAULT_LAT))
        lon = float(config.get("lon", DEFAULT_LON))

    states = get_flights(lat, lon, radius_miles)

    if states == None:
        return render.Root(
            child = render.Column(
                children = [
                    render.Text("OpenSky", font = "tb-8", color = "#FFD700"),
                    render.Text("API error", font = "tb-8", color = "#FF4444"),
                ],
            ),
        )

    airborne = [s for s in states if s[8] == False and s[6] != None and s[5] != None]

    if len(airborne) == 0:
        return render.Root(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Text("No planes", font = "tb-8", color = "#888888"),
                    render.Text("nearby", font = "tb-8", color = "#888888"),
                ],
            ),
        )

    count = len(airborne)
    label = "plane" if count == 1 else "planes"
    header_text = str(count) + " " + label + " nearby"

    rows = [format_flight_row(s) for s in airborne[:8]]

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    height = 10,
                    color = "#1A1A2E",
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(header_text, font = "tb-8", color = "#FFD700"),
                    ),
                ),
                render.Marquee(
                    width = 64,
                    height = 22,
                    scroll_direction = "vertical",
                    offset_start = 22,
                    offset_end = 22,
                    delay = 80,
                    child = render.Column(
                        children = rows,
                    ),
                ),
            ],
        ),
    )
