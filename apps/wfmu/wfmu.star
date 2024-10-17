"""
Applet: WFMU
Summary: WFMU Now Playing
Description: Displays what's currently playing on the WFMU radio station. WFMU-FM 91.1/Jersey City, NJ; 90.1/Hudson Valley.
Author: Tom O'Dea
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_COLOR = "#6699FF"

WFMU_LOGO = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAADoAAAANBAMAAAAK6mAOAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAwUExURQEBARgYGCYmJjc3N0dHR1RUVGlpaXd3d4qKipeXl6ampra2tsjIyNnZ2efn5/39/UxwiA8AAAAJcEhZcwAALiMAAC4jAXilP3YAAAD8SURBVCjPfdAxSwNBEAXgt0mMp4gG0tjZKjZb29gp/oqkC1idAQ12QSzsYqFgdzZWFmdjpZIyARH9ASG5NgjqITFnsfucvUshChmm+3i8YTB9vAt4x1g7h6o1DurY3r/eW308QqEB1DQWDZa+sZkgR3KMkDSk1Z6FYjPVxGme9u1LtE/7wJs581ebUhQmavCpGKXqO11JtZBp5Pb547+eigYvmXq/tTLGIbsnZwgit+1YNCe6QF0xCEZKTmYyybbjWYui6Dwt2WOs7vl6d4vWJDvDq5Zo/t2FpDO7OdMwxoAcamD5qbvR7wCqVxXdvcSOjy0f6zR6yovLJeAHH3qZ6ZBOBtsAAAAASUVORK5CYII=""")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Color of the song title.",
                icon = "brush",
                default = DEFAULT_COLOR,
                palette = [
                    DEFAULT_COLOR,
                    "#FFFFFF",
                    "#FF00FF",
                    "#33FFFF",
                    "#00FF00",
                    "#FF6600",
                    "#FF0000",
                    "#FFFF00",
                ],
            ),
        ],
    )

WFMU_NOW_PLAYING_URL = "https://wfmu.org/wp-content/themes/wfmu-theme/library/php/includes/liveNow.php"

def api_error():
    print("Error connecting to the API")
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = WFMU_LOGO, width = 64),
                render.Text("No Connection", font = "tb-8", color = "#CC0000"),
            ],
        ),
    )

def main(config):
    color = config.str("color", DEFAULT_COLOR)
    rep = http.get(WFMU_NOW_PLAYING_URL, ttl_seconds = 30)
    if rep.status_code != 200:
        print("The json request failed with status %d", rep.status_code)
        return api_error()

    song = rep.json()["song"]
    show = rep.json()["show"]

    print("song=", song)

    # if song is empty, display the show name instead
    if song:
        now_playing = song
    else:
        now_playing = show
        show = ""

    print("playing=", now_playing)

    # check if result was served from cache or not
    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling WFMU API.")

    return render.Root(
        child = render.Column(
            children = [
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 14,
                            color = "#000",
                        ),
                        render.Marquee(
                            width = 64,
                            offset_start = 22,
                            child = render.Text(now_playing, color = color, font = "6x13"),
                        ),
                    ],
                ),
                render.Box(
                    width = 64,
                    height = 2,
                    color = "#000",
                ),
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 8,
                            color = "#000",
                        ),
                        render.Marquee(
                            width = 64,
                            offset_start = 0,
                            delay = 22,
                            child = render.Text(show, color = "#999", font = "tom-thumb"),
                        ),
                    ],
                ),
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "#333",
                        ),
                    ],
                ),
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "#000",
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 64,
                    child = render.Text("WFMU.ORG  91.1FM", color = "#666", font = "tom-thumb"),
                ),
            ],
        ),
    )
