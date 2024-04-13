"""
Applet: Goose FM
Summary: Info on Goose.fm
Description: Info for the music service Goose.fm. Supports station overview and individual station data.
Author: jqr
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

MAX_WIDTH = 64
MAX_HEIGHT = 32
DEFAULT_TTL = 30

def main(config):
    callsign = config.str("callsign")
    if not callsign or len(callsign) == 0:
        return render_station_overview()
    else:
        return render.Root(render_station(callsign))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "callsign",
                name = "Station Callsign",
                desc = "Show detailed info about a single station.",
                icon = "towerBroadcast",
            ),
        ],
    )

def get_json(url, ttl_seconds = DEFAULT_TTL):
    response = http.get(url, headers = {"Accept": "application/json"}, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Request failed with status %i to %s" % (response.status_code, url))

    return response.json()

def render_station_overview():
    stations = list_stations()
    rows = []

    for station in stations:
        rows.append(render_station_with_listeners(station))

    return render.Root(
        render.Marquee(render.Column(rows), scroll_direction = "vertical", height = MAX_HEIGHT),
    )

def list_stations():
    results = []

    for station in get_json("https://goose.fm/stations/"):
        results.append({
            "callsign": station["callsign"],
            "listeners": station["listeners"],
        })

    return results

def render_station(callsign, width = MAX_WIDTH):
    station = get_station_info(callsign)
    return render.Column(
        [
            render_station_with_listeners(station),
            render.Marquee(render.Text(station["dj"], color = "c44"), width = width),
            render.Marquee(render.Text(station["song_title"], color = "#fff"), width = width),
            render.Marquee(render.Text(station["song_artist"], color = "#ccc"), width = width),
        ],
    )

def get_station_info(callsign):
    station = get_json("https://" + callsign.lower() + ".station.goose.fm/")
    if "PlayingSong" in station["currentItem"]:
        song = station["currentItem"]["PlayingSong"]["_0"]["song"]["proposals"]["allDetails"][0]
        song_title = song["title"]
        song_artist = song["artistName"]
    else:
        song_title = ""
        song_artist = ""

    return {
        "callsign": callsign.upper(),
        "dj": station["dj"]["name"],
        "song_title": song_title,
        "song_artist": song_artist,
        "listeners": station["listenerCount"],
    }

def render_station_with_listeners(station):
    callsign = station["callsign"]
    listeners = station["listeners"]

    station_color = ternary(listeners == 0, "#666", "#f66")
    listner_color = ternary(listeners == 0, "#666", "#3f3")
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(callsign, color = station_color),
            render.Text("%i" % listeners, color = listner_color),
        ],
    )

def ternary(condition, true_color, false_color):
    if condition:
        return true_color
    else:
        return false_color
