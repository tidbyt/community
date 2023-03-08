"""
Applet: Nearby Flight
Summary: Show a Nearby Flight
Description: Shows a nearby flight by querying airframes.io.
Author: kevinelliott
Homepage: https://github.com/airframesio & https://github.com/kevinelliott
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

AIRFRAMES_NEARBY_URL = "https://api.airframes.io/v1/tidbyt/nearby/flights"

# AIRFRAMES_NEARBY_URL = "http://localhost:3001/v1/tidbyt/nearby/flights"
AIRFRAMES_NEARBY_RADIUS = "5"
AIRFRAMES_NEARBY_LIMIT = "5"
AIRFRAMES_NEARBY_SORT = "distance"
AIRFRAMES_NEARBY_SORT_ORDER = "asc"
ENCRYPTED_API_KEY = ""

def main(config):
    api_key = secret.decrypt(ENCRYPTED_API_KEY) or config.get("api_key")
    location = json.decode(config.get("location"))
    print(location)

    flights = get_nearby_flights(api_key, location["lat"], location["lng"], AIRFRAMES_NEARBY_RADIUS)
    if flights == None or len(flights) == 0:
        fail("No nearby flights found")
    nearest = flights[0]

    return render.Root(
        delay = 6000,
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    children = [
                        render.Animation(
                            children = [
                                render.Row(
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Row(
                                                    children = [
                                                        render.Column(
                                                            expanded = False,
                                                            main_align = "space_evenly",
                                                            children = [
                                                                render.Row(
                                                                    expanded = True,
                                                                    main_align = "space_evenly",
                                                                    children = [
                                                                        render.Text("%s" % nearest["flight"], color = "#0F0", font = "tom-thumb"),
                                                                        render.Text("%s" % nearest["airframe"]["tail"], color = "#0FF", font = "tom-thumb"),
                                                                    ],
                                                                ),
                                                                render.Row(
                                                                    expanded = True,
                                                                    main_align = "space_evenly",
                                                                    children = [
                                                                        render.Text("Nearby", color = "#FF0", font = "tom-thumb"),
                                                                        render.Text("%s" % nearest["airframe"]["icao"], color = "#60F", font = "tom-thumb"),
                                                                    ],
                                                                ),
                                                            ],
                                                        ),
                                                    ],
                                                ),
                                                render.Row(
                                                    expanded = True,
                                                    main_align = "space_evenly",
                                                    children = [
                                                        render.Text("%d messages" % nearest["messagesCount"], color = "#aff", font = "tom-thumb"),
                                                    ],
                                                ),
                                                render.Row(
                                                    expanded = True,
                                                    main_align = "space_evenly",
                                                    children = [
                                                        render.Text("%d positions" % len(nearest["positions"]), color = "#06f", font = "tom-thumb"),
                                                    ],
                                                ),
                                                render.Row(
                                                    expanded = True,
                                                    main_align = "space_evenly",
                                                    children = [
                                                        render.Text("%s" % nearest["status"], color = "#F09", font = "tom-thumb"),
                                                    ],
                                                ),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = False,
                                    main_align = "start",
                                    cross_align = "end",
                                    children = [
                                        render.Column(
                                            expanded = True,
                                            main_align = "start",
                                            cross_align = "center",
                                            children = [
                                                render.Padding(
                                                    child = render.Text("%s" % nearest["flight"], color = "#0F0", font = "tom-thumb"),
                                                    pad = (0, 3, 0, 0),
                                                ),
                                                render.Text("", color = "#0F0", font = "tom-thumb"),
                                                render.Text("OPEN", color = "#666", font = "tom-thumb"),
                                                render.Text("FLIGHT", color = "#666", font = "tom-thumb"),
                                            ],
                                        ),
                                        render.Column(
                                            expanded = True,
                                            main_align = "start",
                                            cross_align = "center",
                                            children = [
                                                render.Padding(
                                                    child = render.Image(src = qr_code_for_flight(nearest)),
                                                    pad = (5, 1, 0, 0),
                                                ),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def qr_code_for_flight(flight):
    url = "https://app.airframes.io/flights/%s" % int(flight["id"])
    print("Generating QR code for %s" % url)
    code = qrcode.generate(
        url = url,
        size = "large",
        color = "#FFF",
        background = "#000",
    )
    return code

def get_nearby_flights(api_key, lat, lon, radius):
    cache_key = "nearby_%s_%s_%s" % (lat, lon, radius)
    nearby_cached = cache.get(cache_key)
    if nearby_cached != None:
        print("Hit! Displaying cached data.")
        return json.decode(nearby_cached)

    print("Miss! Calling Airframes API.")

    rep = http.get(AIRFRAMES_NEARBY_URL, params = {
        "lat": str(lat),
        "lon": str(lon),
        "radius": radius,
        "limit": AIRFRAMES_NEARBY_LIMIT,
        "sort": AIRFRAMES_NEARBY_SORT,
        "sort_order": AIRFRAMES_NEARBY_SORT_ORDER,
    }, headers = {
        "X-API-KEY": api_key or "none",
    })
    print(rep.url)
    if rep.status_code != 200:
        fail("Airframes API request failed with status %d" % rep.status_code)

    nearby = rep.json()
    cache.set(cache_key, json.encode(nearby), ttl_seconds = 60)
    return nearby

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Airframes API Key",
                desc = "Your Airframes API key. You can find this in your Airframes account settings.",
                icon = "key",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to search for nearby flights.",
                icon = "locationDot",
            ),
        ],
    )
