"""
Applet: ABC Radio
Summary: Now playing on ABC stations
Description: Shows the current playing song on various ABC stations in Australia.
Author: M0ntyP
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TIMEOUT = 120

NOWPLAYING_PREFIX_URL = "https://music.abcradio.net.au/api/v1/plays/"
NOWPLAYING_SUFFIX_URL = "/now.json?tz="
DEFAULT_TIMEZONE = "Australia/Adelaide"

def main(config):
    StationSelection = config.get("station", "triplej")
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    NOWPLAYING_URL = NOWPLAYING_PREFIX_URL + StationSelection + NOWPLAYING_SUFFIX_URL + timezone

    # Get song data every 2 mins
    MUSICDATA = get_cachable_data(NOWPLAYING_URL, CACHE_TIMEOUT)
    MUSIC = json.decode(MUSICDATA)

    # if there is no song playing then display the previous played song
    if MUSIC["now"] != {}:
        artist = MUSIC["now"]["recording"]["artists"][0]["name"]
        songtitle = MUSIC["now"]["recording"]["title"]
    else:
        artist = MUSIC["prev"]["recording"]["artists"][0]["name"]
        songtitle = MUSIC["prev"]["recording"]["title"]

    Title = displayStationTitle(StationSelection)

    return render.Root(
        delay = 75,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    padding = 0,
                    color = Title[1],
                    child = render.Text(content = Title[0], color = "#fff", font = "CG-pixel-4x5-mono", offset = 0),
                ),
                render.Box(
                    width = 64,
                    height = 8,
                    padding = 0,
                    color = "#000",
                    child = render.Text("NOW PLAYING...", color = "#fff", font = "CG-pixel-3x5-mono", offset = 0),
                ),
                render.Box(
                    width = 64,
                    height = 2,
                    padding = 0,
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = songtitle, color = "#42f545", font = "CG-pixel-3x5-mono"),
                ),
                render.Box(
                    width = 64,
                    height = 3,
                    padding = 0,
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = artist, color = "#fff", font = "CG-pixel-3x5-mono", offset = 0),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Choose your station",
                desc = "Choose the station",
                icon = "radio",
                default = StationOptions[0].value,
                options = StationOptions,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def displayStationTitle(StationValue):
    Title = []

    if StationValue == "triplej":
        Title = ["Triple J", "#e63228"]
    elif StationValue == "doublej":
        Title = ["Double J", "#000"]
    elif StationValue == "classic":
        Title = ["ABC Classic", "#0e6598"]
    elif StationValue == "classic2":
        Title = ["ABC Classic 2", "#5b7e81"]
    elif StationValue == "jazz":
        Title = ["ABC Jazz", "#015888"]
    elif StationValue == "country":
        Title = ["ABC Country", "#08686e"]
    elif StationValue == "h100":
        Title = ["Hottest 100", "#e17800"]
    else:
        Title = ["", "#000"]
    return Title

StationOptions = [
    schema.Option(
        display = "Triple J",
        value = "triplej",
    ),
    schema.Option(
        display = "Double J",
        value = "doublej",
    ),
    schema.Option(
        display = "Hottest 100",
        value = "h100",
    ),
    schema.Option(
        display = "Classic",
        value = "classic",
    ),
    schema.Option(
        display = "Classic 2",
        value = "classic2",
    ),
    schema.Option(
        display = "Jazz",
        value = "jazz",
    ),
    schema.Option(
        display = "Country",
        value = "country",
    ),
]
