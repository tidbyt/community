"""
Applet: Roon
Summary: Roon now playing info
Description: Connects to the http api extension for roon and serves info about the currently playing zone's song, album and artist.
Author: jboulter11
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

SECONDS_TO_MS = 1000

def main(config):
    hostname = "%s:%s/roonAPI" % (config.get("server", "http://192.168.1.4"), config.get("port", "3001"))

    activeZone = getActiveZone(hostname)
    if activeZone == None:
        return []

    now_playing = parseNowPlaying(activeZone)
    if now_playing == None:
        return []

    time_remaining = parseTimeRemaining(activeZone)

    return render.Root(
        max_age = time_remaining * SECONDS_TO_MS,
        child = render.Column(
            children = [
                render.Marquee(child = render.Text(now_playing["song"]), width = 64),
                render.Marquee(child = render.Text(now_playing["album"]), width = 64),
                render.Marquee(child = render.Text(now_playing["artist"]), width = 64),
            ],
        ),
    )

def getActiveZone(hostname):
    response = http.get(hostname + "/listZones")
    for zone in response.json()["zones"]:
        if zone["state"] == "playing":
            return zone
    return None

def parseNowPlaying(zone):
    lines = zone["now_playing"]["three_line"]
    return {
        "artist": lines["line2"],
        "album": lines["line3"],
        "song": lines["line1"],
    }

def parseTimeRemaining(zone):
    total_length = zone["now_playing"]["length"]
    current_position = zone["now_playing"]["seek_position"]
    return math.ceil(total_length - current_position)

# SCHEMA

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "hostname",
                name = "Hostname",
                desc = "Server IP or hostname, starts with http://, defaults to http://192.168.1.4",
                icon = "server",
            ),
            schema.Text(
                id = "port",
                name = "Port",
                desc = "The port to direct your request to, defaults to 3001",
                icon = "server",
            ),
        ],
    )
