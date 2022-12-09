"""
Applet: Trambyt
Summary: Departures for Västtrafik
Description: Show departures for Västtrafik stops.
Author: protocol7
"""

load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("cache.star", "cache")
load("schema.star", "schema")
load("secret.star", "secret")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")

API_KEY = "VS_fuDj3YZhsRzFBYdV7fLDMQcAa"
API_SECRET = "AV6+xWcExWH7Oc5Vn1VWhdnAoHLcQVt2ZkldnfOhYQCa6DBRbGzPTvi+pNO3dRm6DjE5Y+dEiudkyg+8wm6Dzn711OXmcydvnkPERtF8NlHfqZ+JAqa60q+i2y1FISJMJZINKZH0gFClVR69DGiQ+GfGwts/2FOpzR9vNAva9ugvmQ=="

STOPS_URL = "https://api.vasttrafik.se/bin/rest.exe/v2/location.nearbystops?format=json"
DEPARTURES_URL = "https://api.vasttrafik.se/bin/rest.exe/v2/departureBoard?format=json"
GRANT_URL = "https://api.vasttrafik.se/token"

def format_duration(d):
    if d.hours > 1:
        return str(int(d.hours + 0.5)) + " h"
    elif d.minutes > 1:
        return str(int(d.minutes + 0.5)) + " min"
    else:
        return "now"

def get_access_token(config):
    # refresh token
    access_token = cache.get("access_token")
    if access_token == None:
        print("Refresh access token")
        api_secret = secret.decrypt(API_SECRET) or config.get("dev_api_secret")
        if not api_secret:
            return None

        token_secret = base64.encode(API_KEY + ":" + api_secret)

        rep = http.post(GRANT_URL, headers = {"Authorization": "Basic " + token_secret}, form_body = {"grant_type": "client_credentials"})
        if rep.status_code != 200:
            fail("Access token request failed with status %d", rep.status_code)

        j = rep.json()
        access_token = j["access_token"]

        cache.set("access_token", access_token, ttl_seconds = int(int(j["expires_in"]) / 2))

    return access_token

def main(config):
    access_token = get_access_token(config)

    # get departures
    departures = cache.get("departures")
    if departures == None:
        print("Calling API")
        now = time.now()

        location = json.decode(config.get("location", '{"value": "9021014003780000"}'))
        location_id = location["value"]

        rep = http.get(
            DEPARTURES_URL,
            headers = {"Authorization": "Bearer " + access_token},
            params = {"time": now.format("15:04"), "date": now.format("2006-01-02"), "id": location_id},
        )
        if rep.status_code != 200:
            fail("API request failed with status %d", rep.status_code)

        # extract all deperaturs
        deps = []
        j = rep.json()["DepartureBoard"]
        if "Departure" in j:
            for dep in j["Departure"]:
                d = dep["date"]
                t = dep.get("rtTime") or dep["time"]

                dur = time.parse_time(d + "T" + t, "2006-01-02T15:04", "Europe/Stockholm") - now
                fmt_dur = format_duration(dur)

                deps.append((dur, fmt_dur, dep["sname"], dep["direction"], dep["bgColor"].lower()))
        else:
            return render.Root(render.WrappedText("Departures not available for location"))

        # sort on next departures and pick the next two
        departures = []
        for dep in sorted(deps)[0:2]:
            _, fmt_dur, sname, direction, color = dep

            departures.append("%s\t%s\t%s\t%s" % (fmt_dur, sname, direction, color))

        departures = "\n".join(departures)

        cache.set("departures", departures, ttl_seconds = 60)

    # render
    departures = departures.split("\n")

    max_width = 1
    for dep in departures:
        _, sname, _, _ = dep.split("\t")
        max_width = max(max_width, len(sname))

    badge_width = 6 + max_width * 5
    text_width = 60 - badge_width
    texts = []
    for dep in departures:
        dep_time, sname, direction, color = dep.split("\t")

        texts.append(
            render.Row(
                children = [
                    render.Box(
                        child = render.Text(sname, color = color, font = "6x13"),
                        width = badge_width,
                        height = 15,
                    ),
                    render.Column(
                        children = [
                            render.Marquee(child = render.Text(direction), width = text_width),
                            render.Text(dep_time, font = "tom-thumb", color = "#f2a93b"),
                        ],
                    ),
                ],
            ),
        )

    return render.Root(render.Column(children = texts))

def get_stops(location):
    loc = json.decode(location)
    lat = loc["lat"]
    lng = loc["lng"]

    access_token = get_access_token({})

    if access_token:
        rep = http.get(
            STOPS_URL,
            headers = {"Authorization": "Bearer " + access_token},
            params = {"originCoordLat": lat, "originCoordLong": lng},
        )
        if rep.status_code != 200:
            fail("API request failed with status %d", rep.status_code)

        options = []
        seen = {}
        for stop in rep.json()["LocationList"]["StopLocation"]:
            stop_name = stop["name"]
            stop_id = stop["id"]
            if len(stop_id) != 16:
                # only stops with long identifiers seems to have departures ¯\_(ツ)_/¯
                continue

            if stop_name in seen:
                continue
            seen[stop_name] = True

            options.append(
                schema.Option(
                    display = stop_name,
                    value = stop_id,
                ),
            )

        return options
    else:
        return [
            schema.Option(
                display = "Kaptensgatan, Göteborg",
                value = "9021014003780000",
            ),
        ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "location",
                name = "Västtrafik location ID",
                desc = "The stop for which to show departures",
                icon = "locationPin",
                handler = get_stops,
            ),
        ],
    )
