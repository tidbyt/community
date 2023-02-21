"""
Applet: GA Pilot Buddy
Summary: Local flight rules and wx
Description: See local aerodrome flight rules and current abbreviated METAR information.
Author: icdevin
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

AVWX_TOKEN = """
AV6+xWcExhV/86cLj2rRID9NtWmsaHrdquWQRdLMUDxsODRYS6rvPX++GlGbSkUtrxtHJGPdd+LaW62E
3kNxH7j9KB1ey9CPUI/ez81m7FaV7uyLdie5CLoV9ri5gSJ91dGnQ6cUsI2bBci073rKHTpwi+JLZdXV
0NkDAbU/WyV2nbl4cyJAwd20XI4XkBV5KA==
"""
DEFAULT_LOCATION = """
{
    "lat": "33.6295968",
    "lng": "-117.8862308",
    "description": "Newport Beach, CA, USA",
    "locality": "Newport Beach",
    "place_id": "ChIJ3whWdFnf3IARUV7GZxqUpjs",
    "timezone": "America/Los_Angeles"
}
"""
DEFAULT_FLIGHT_RULES_COLOR = "#C3C3C3"
ERROR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAATElEQVQoU2P8L8L8n/HNX0YGAgCmDq
yQkCZkebjJuDShi6M4BV0SmyEYbocpwmUjVs/i8xNlNpDkB5JCiaR4IKQYlgBQYppQskCWBwCgNlQN
phkLigAAAABJRU5ErkJggg==
""")
FLIGHT_RULES_COLOR_MAP = {
    "VFR": "#01CF00",
    "MVFR": "#0061E7",
    "IFR": "#EB0000",
    "LIFR": "#D300D3",
}

def get_avwx_headers(config):
    return {
        "Authorization": "Token {}".format(secret.decrypt(AVWX_TOKEN) or config.get("avwx_token")),
    }

def get_nearby_aerodromes(location, config):
    # Truncates the precise lat/lng for data privacy since this will be sent out
    # to a third party API
    lat = humanize.float("#.#", float(location["lat"]))
    lng = humanize.float("#.#", float(location["lng"]))
    str_geo = "{},{}".format(lat, lng)

    aerodromes = cache.get(str_geo)
    if aerodromes == None:
        url = "https://avwx.rest/api/station/near/{}".format(str_geo)

        # Although we only show three, this grabs extras in case some get filtered
        # out such as military or private aerodromes
        params = {"n": "10"}
        resp = http.get(url, params = params, headers = get_avwx_headers(config))
        if resp.status_code != 200:
            print(resp)
            return None
        aerodromes = resp.json()
    else:
        aerodromes = json.decode(aerodromes)

    # Caches the response for a week -- aerodromes *really* do not change often
    # This may even be too generous
    # Sets the cache before filtering in case the config changes
    cache.set(str_geo, json.encode(aerodromes), ttl_seconds = 86400)

    show_all_aerodromes = config.bool("show_all_aerodromes")
    return [aerodrome for aerodrome in aerodromes if show_all_aerodromes or aerodrome["station"].get("operator") == "PUBLIC"]

def get_aerodrome_metar(aerodrome, config):
    aerodrome_id = aerodrome["station"]["icao"]
    metar = cache.get(aerodrome_id)
    if metar == None:
        url = "https://avwx.rest/api/metar/{}".format(aerodrome_id)
        resp = http.get(url, params = {}, headers = get_avwx_headers(config))
        if resp.status_code != 200:
            print(resp)
            return None
        metar = resp.json()

        # METARs update once an hour, so cache it for one hour minus the
        # last updated time so ideally we get updated METARs as soon as they
        # are available
        # NOTE: Sometimes METARs are not updated before or on the hour, so only
        # cache for a few minutes if it's been over an hour since updating
        updated_time = time.parse_time(metar["time"]["dt"])
        time_ago = time.now() - updated_time
        ttl = int(3600 - time_ago.seconds)
        if ttl < 0:
            ttl = 180
        cache.set(aerodrome_id, resp.body(), ttl_seconds = ttl)
    else:
        metar = json.decode(metar)
    return metar

def format_weather_short(metar):
    wind = "Wind {}@{}".format(metar["wind_direction"]["repr"], metar["wind_speed"]["repr"])
    vis = "Vis {}".format(metar["visibility"]["repr"])
    alt = "Alt {}".format(humanize.float("##.##", metar["altimeter"]["value"]))
    return "{}, {}, {}".format(wind, vis, alt)

def render_aerodrome_row(aerodrome, config):
    metar = get_aerodrome_metar(aerodrome, config)
    if metar == None:
        return None
    return render.Padding(
        pad = (2, 2, 0, 0),
        child = render.Row(
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (0, 0, 2, 0),
                    child = render.Circle(
                        color = FLIGHT_RULES_COLOR_MAP[metar["flight_rules"]] or DEFAULT_FLIGHT_RULES_COLOR,
                        diameter = 6,
                    ),
                ),
                render.Padding(
                    pad = (0, 0, 2, 0),
                    child = render.Box(
                        width = 20,
                        height = 8,
                        child = render.Text(content = aerodrome["station"]["icao"]),
                    ),
                ),
                render.Marquee(
                    width = 50,
                    offset_start = 40,
                    offset_end = 50,
                    child = render.Text(content = format_weather_short(metar)),
                ),
            ],
        ),
    )

def render_error():
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = ERROR_ICON),
                    render.Text("Error :("),
                ],
            ),
        ),
    )

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    nearby_aerodromes = get_nearby_aerodromes(loc, config)

    if nearby_aerodromes == None:
        return render_error()
    else:
        nearby_aerodromes = nearby_aerodromes[0:3]

    rows = [render_aerodrome_row(aerodrome, config) for aerodrome in nearby_aerodromes]
    rows = [row for row in rows if row != None]
    if len(rows) == 0:
        return render_error()

    return render.Root(
        child = render.Column(
            children = rows,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display nearby aerodromes",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "show_all_aerodromes",
                name = "Show All Aerodromes",
                desc = "Enables showing all aerodromes including military, private, etc.",
                icon = "gear",
                default = False,
            ),
        ],
    )
