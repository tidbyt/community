"""
Applet: BBC Radio
Summary: What's live now on the BBC
Description: Shows what programme is currently being broadcast on each of the BBC's radio stations.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STATIONS_URL = "https://www.bbc.co.uk/sounds/stations"
JSON_PREFIX = "window.__PRELOADED_STATE__ = "
USER_AGENT = "https://github.com/tidbyt/community/tree/main/apps/bbcradio"
TIMEZONE = "Europe/London"
RADIO_4 = "bbc_radio_four"
FONT = "tom-thumb"
GREEN = "#22ff7b"
ORANGE = "#ff7b22"
PURPLE = "#7b22ff"
LIGHT_GREY = "#b0b2b4"
DARK_GREY = "#3a3c3e"

def extract_station(station):
    result = {}
    network = station.get("network")
    if network:
        station_id = network.get("id")
        if station_id:
            result["id"] = station_id
        else:
            print("No station ID", station)
            return None

        name = network.get("short_title")
        if name:
            result["name"] = name
        else:
            print("No station name", station)
            return None
    else:
        print("No network", station)
        return None

    missing_info = False
    titles = station.get("titles")
    if titles:
        programme = titles.get("primary")
        if programme:
            result["programme"] = programme
        else:
            print("No programme title")
            missing_info = True

        timing = titles.get("secondary")
        if timing:
            result["timing"] = timing
        else:
            print("No programme timing")
            missing_info = True

    synopses = station.get("synopses")
    if synopses:
        synopsis = synopses.get("short")
        if synopsis:
            result["synopsis"] = synopsis
        else:
            print("No short synopsis")
            missing_info = True
    else:
        print("No synopses")
        missing_info = True

    if missing_info:
        print(station)
    return result

def extract_stations(page, index):
    raw = page["modules"]["data"][index]["data"]
    stations = [extract_station(s) for s in raw if s]
    return {s["id"]: s for s in stations if s}

def load_stations():
    resp = http.get(
        url = STATIONS_URL,
        headers = {
            "User-Agent": "USER_AGENT",
        },
        ttl_seconds = 60,
    )
    page = html(resp.body())
    raw = json.decode(page.find("div#main > script").text()[len(JSON_PREFIX):-2])
    return extract_stations(raw, 0), extract_stations(raw, 1)

def render_station(station):
    return render.Padding(
        pad = (1, 1, 1, 0),
        child = render.Marquee(
            width = 62,
            height = 6,
            scroll_direction = "horizontal",
            align = "center",
            child = render.Text(
                content = station["name"],
                font = FONT,
                color = LIGHT_GREY,
            ),
        ),
    )

def render_program(station, show_synopsis, colour):
    title = station.get("programme", "No programme info")
    synopsis = station.get("synopsis", "No synopsis info")
    timing = station.get("timing", "No timing info")
    if show_synopsis:
        content = title + " - " + synopsis
    else:
        content = title
    return render.Padding(
        pad = (1, 8, 1, 0),
        child = render.Column(
            children = [
                render.Marquee(
                    width = 62,
                    height = 14,
                    scroll_direction = "vertical",
                    align = "center",
                    child = render.WrappedText(
                        content = content,
                        width = 62,
                        font = FONT,
                        align = "center",
                        color = colour,
                    ),
                ),
                render.Box(
                    height = 2,
                    width = 1,
                ),
                render.WrappedText(
                    content = timing,
                    font = FONT,
                    color = LIGHT_GREY,
                    width = 62,
                    align = "center",
                ),
            ],
        ),
    )

def render_progress_bar(station, colour):
    # Can't trust the "progress" field in the API response to be up to date.
    timing = station.get("timing")
    if timing:
        start, _, end = timing.split(" ")
        start_hour, start_min = [int(x) for x in start.split(":")]
        end_hour, end_min = [int(x) for x in end.split(":")]
        now = time.now()
        begin = time.time(year = now.year, month = now.month, day = now.day, hour = start_hour, minute = start_min, location = TIMEZONE)
        finish = time.time(year = now.year, month = now.month, day = now.day, hour = end_hour, minute = end_min, location = TIMEZONE)
        if finish < begin:
            finish += 24 * time.hour  # Wrap past midnight
        duration = finish - begin
        elapsed = now - begin
        progress = int(64.0 * (elapsed / duration))
    else:
        progress = 0
    return render.Padding(
        pad = (0, 30, 0, 0),
        child = render.Row(
            children = [
                render.Box(
                    width = progress,
                    height = 2,
                    color = colour,
                ),
                render.Box(
                    width = 64 - progress,
                    height = 2,
                    color = DARK_GREY,
                ),
            ],
        ),
    )

def main(config):
    station = config.get("station", RADIO_4)
    colour = config.get("colour", GREEN)
    show_synopsis = config.bool("show_synopsis", False)
    national, local = load_stations()
    stations = dict(national, **local)
    station = stations[station]

    return render.Root(
        child = render.Stack(
            children = [
                render_station(station),
                render_program(station, show_synopsis, colour),
                render_progress_bar(station, colour),
            ],
        ),
    )

def get_schema():
    national, local = load_stations()
    stations = [
        schema.Option(
            display = v["name"],
            value = k,
        )
        for k, v in national.items()
    ] + [
        schema.Option(
            display = v["name"],
            value = k,
        )
        for k, v in local.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Which BBC radio station to show",
                icon = "radio",
                options = stations,
                default = RADIO_4,
            ),
            schema.Toggle(
                id = "show_synopsis",
                name = "Show synopsis",
                desc = "Show more info about programme",
                icon = "info",
                default = False,
            ),
            schema.Color(
                id = "colour",
                name = "Colour",
                desc = "Colour for programme info",
                icon = "brush",
                default = GREEN,
                palette = [
                    GREEN,
                    ORANGE,
                    PURPLE,
                    LIGHT_GREY,
                ],
            ),
        ],
    )
