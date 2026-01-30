"""
CUMTD Bus Arrivals - Tidbyt App
Enter your address to see buses at nearby stops.
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_BASE = "https://developer.mtd.org/api/v2.2/json"
GEOCODE_URL = "https://nominatim.openstreetmap.org/search"
MTD_BLUE = "#1E88E5"

def main(config):
    api_key = config.str("api_key")
    address = config.str("address", "")
    routes_str = config.str("routes", "")

    if not api_key:
        return render_error("Set API key")

    if not address:
        return render_error("Enter address")

    # Get nearby stops from address
    stops = get_stops_from_address(api_key, address)

    if not stops:
        return render_error("No stops found")

    # Parse route filter
    route_filter = []
    if routes_str:
        route_filter = [r.strip().upper() for r in routes_str.split(",")]

    # Fetch departures for all stops (stops are ordered by distance, closest first)
    # Only keep the first occurrence of each route+direction (from closest stop)
    all_departures = []
    seen_routes = {}  # key: "route+direction", value: stop_name

    for stop in stops:
        departures = fetch_departures(api_key, stop["stop_id"], stop["name"], route_filter)
        for dep in departures:
            route_key = "%s%s" % (dep["route"], dep["direction"])
            if route_key not in seen_routes:
                seen_routes[route_key] = dep["stop_name"]
                all_departures.append(dep)

    # Sort by arrival time
    all_departures = sorted(all_departures, key = lambda d: d["mins"])

    return render.Root(
        delay = 120,  # Slower frame rate for easier reading
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                render_header(address),
                render_bus_list(all_departures[:5]),
            ],
        ),
    )

def render_error(msg):
    """Render error message."""
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = msg,
                font = "tom-thumb",
                color = "#ff6600",
            ),
        ),
    )

def get_stops_from_address(api_key, address):
    """Geocode address and find nearby CUMTD stops."""
    cache_key = "geo_%s" % address.replace(" ", "_").replace(",", "")[:30]
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    # URL encode the address - only add location hint if not already present
    addr_lower = address.lower()
    if "champaign" in addr_lower or "urbana" in addr_lower or "il" in addr_lower:
        encoded_addr = url_encode(address)
    else:
        encoded_addr = url_encode(address + ", Champaign, IL")

    geo_url = "%s?q=%s&format=json&limit=1" % (GEOCODE_URL, encoded_addr)
    geo_resp = http.get(
        geo_url,
        headers = {"User-Agent": "TidbytCUMTDApp/1.0"},
        ttl_seconds = 86400,
    )

    if geo_resp.status_code != 200:
        return []

    geo_data = geo_resp.json()
    if not geo_data:
        return []

    lat = geo_data[0]["lat"]
    lon = geo_data[0]["lon"]

    # Find nearby stops (get 5 to ensure good route coverage)
    stops_url = "%s/getstopsbylatlon?key=%s&lat=%s&lon=%s&count=5" % (API_BASE, api_key, lat, lon)
    stops_resp = http.get(stops_url, ttl_seconds = 300)

    if stops_resp.status_code != 200:
        return []

    stops_data = stops_resp.json()
    stops = []
    for stop in stops_data.get("stops", [])[:5]:
        stops.append({
            "stop_id": stop["stop_id"],
            "name": shorten_name(stop["stop_name"]),
        })

    cache.set(cache_key, json.encode(stops), ttl_seconds = 3600)
    return stops

def url_encode(s):
    """Simple URL encoding for address strings."""
    result = ""
    for c in s.elems():
        if c == " ":
            result += "%20"
        elif c == ",":
            result += "%2C"
        elif c == "&":
            result += "%26"
        elif c == "#":
            result += "%23"
        else:
            result += c
    return result

def shorten_name(name):
    """Shorten stop name for display."""
    name = name.replace("Transit Plaza", "Plaza")
    name = name.replace("Illinois Street Residence Hall", "ISR")
    name = name.replace("Krannert Center", "Krannert")
    name = name.replace("Chemical and Life Sciences", "Chem&Life")
    name = name.replace(" and ", " & ")
    name = name.replace("Street", "St")
    name = name.replace("Avenue", "Ave")
    name = name.replace("Drive", "Dr")
    name = name.replace("Road", "Rd")

    # Remove extra spaces
    parts = [p for p in name.split(" ") if p]
    name = " ".join(parts)

    return name

def fetch_departures(api_key, stop_id, stop_name, route_filter):
    """Fetch departures for a single stop."""
    cache_key = "cumtd_%s" % stop_id
    cached = cache.get(cache_key)
    if cached:
        deps = json.decode(cached)

        # Update stop name and apply filter
        for d in deps:
            d["stop_name"] = stop_name
        if route_filter:
            deps = [d for d in deps if d["route"].upper() in route_filter]
        return deps

    url = "%s/getdeparturesbystop?key=%s&stop_id=%s&pt=30" % (API_BASE, api_key, stop_id)
    rep = http.get(url, ttl_seconds = 60)

    if rep.status_code != 200:
        return []

    data = rep.json()
    departures = []

    for dep in data.get("departures", []):
        route = dep.get("route", {})
        route_color = route.get("route_color", "1E88E5")
        text_color = route.get("route_text_color", "FFFFFF")

        if not route_color.startswith("#"):
            route_color = "#" + route_color
        if not text_color.startswith("#"):
            text_color = "#" + text_color

        headsign = dep.get("headsign", "")
        direction = extract_direction(headsign)

        departures.append({
            "mins": dep.get("expected_mins", 0),
            "route": route.get("route_short_name", "?"),
            "direction": direction,
            "color": route_color,
            "text_color": text_color,
            "stop_name": stop_name,
        })

    cache.set(cache_key, json.encode(departures), ttl_seconds = 60)

    if route_filter:
        departures = [d for d in departures if d["route"].upper() in route_filter]

    return departures

def extract_direction(headsign):
    """Extract direction (N/S/E/W/U/C) from headsign."""

    # Headsigns look like "22N Illini", "2U Red", "21 Raven" (no dir)
    # Direction is right after route number if present
    for i in range(len(headsign)):
        c = headsign[i]
        if c in "NSEWUC" and i > 0 and headsign[i - 1].isdigit():
            # Check next char is space or end (confirms it's direction)
            if i == len(headsign) - 1 or headsign[i + 1] == " ":
                return c
    return ""

def render_header(address):
    """Render header with CUMTD on left, address on right."""

    # Extract just street address (remove city, state, zip)
    street = address.split(",")[0].strip()

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Text(
                content = "CUMTD",
                font = "tom-thumb",
                color = MTD_BLUE,
            ),
            render.Marquee(
                width = 38,
                delay = 30,
                child = render.Text(
                    content = street,
                    font = "tom-thumb",
                    color = "#aaa",
                ),
            ),
        ],
    )

def render_bus_row(departure):
    """Render a single bus departure row."""
    mins = departure["mins"]
    if mins == 0:
        time_text = "NOW"
    else:
        time_text = "%dm" % mins

    # Route with direction
    route_text = departure["route"]
    if departure["direction"]:
        route_text = "%s%s" % (departure["route"], departure["direction"])

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            # Left side: route badge
            render.Box(
                width = 18,
                height = 9,
                color = departure["color"],
                child = render.Text(
                    content = route_text,
                    font = "tom-thumb",
                    color = departure["text_color"],
                ),
            ),
            # Right side: time and stop
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(
                        content = time_text,
                        font = "tom-thumb",
                        color = "#fff",
                    ),
                    render.Box(width = 2, height = 1),
                    render.Marquee(
                        width = 28,
                        delay = 40,
                        child = render.Text(
                            content = departure["stop_name"],
                            font = "tom-thumb",
                            color = "#888",
                        ),
                    ),
                ],
            ),
        ],
    )

def render_bus_list(departures):
    """Render the list of bus departures with vertical scrolling."""
    if not departures:
        return render.Box(
            height = 20,
            child = render.Text(
                content = "No buses soon",
                font = "tom-thumb",
                color = "#666",
            ),
        )

    # Build rows for each departure
    children = []
    for dep in departures:
        children.append(render_bus_row(dep))
        children.append(render.Box(height = 1))

    bus_column = render.Column(
        main_align = "start",
        children = children,
    )

    # Vertical marquee to scroll through all buses
    return render.Marquee(
        height = 25,
        scroll_direction = "vertical",
        offset_start = 0,
        offset_end = 0,
        delay = 50,
        child = bus_column,
    )

def get_schema():
    """Define the configuration schema for the app."""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "CUMTD API Key",
                desc = "Get your key at developer.mtd.org",
                icon = "key",
            ),
            schema.Text(
                id = "address",
                name = "Address",
                desc = "Your address (e.g., 601 E John St)",
                icon = "locationDot",
                default = "",
            ),
            schema.Text(
                id = "routes",
                name = "Routes (optional)",
                desc = "Show only these routes (e.g., 22,1,13)",
                icon = "route",
                default = "",
            ),
        ],
    )
