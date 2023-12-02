"""
Applet: Armageddon Trackr
Summary: Closest Near Earth Object
Description: Provides information from NASA about the nearest Near Earth Object on a given date.
Author: flynnt
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

BASE_URL = "https://api.nasa.gov/neo/rest/v1/feed"
API_KEY = secret.decrypt("AV6+xWcEChnmX1GoWd9y78+eys+Z3IWB8fEhAih/LN4Rfxlu1wMRhqi2O07GoDccB3ommPUMen2XV0Ijb9Gn2aCfOmfoyZV5wdKQeNwDqWvWhkv2CRsU8310wm1gHrlHMZjWAyMss6ISNUdrvs+p6PIuhUc2syErX3X8MnYd3E1Gcu6ZLXaLHmuOSmNtSg==")
DEFAULT_UNIT = "miles"
TERMINAL_TEXT_COLOR = "#33ff00"
DINO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABoAAAAYCAYAAADkgu3FAAAACXBIWXMAAAsTAAALEwEAmpwYAAAF0mlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgOS4xLWMwMDEgNzkuMTQ2Mjg5OTc3NywgMjAyMy8wNi8yNS0yMzo1NzoxNCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI1LjEgKE1hY2ludG9zaCkiIHhtcDpDcmVhdGVEYXRlPSIyMDIzLTExLTEyVDEzOjQ1OjM2LTA2OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMy0xMS0xMlQxMzo0NjozNS0wNjowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMy0xMS0xMlQxMzo0NjozNS0wNjowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6ZWIwOTM0NzQtZGFhMS00MGEyLTg4MTYtNjZlZjUyNWY4YmUxIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6Y2RkOGZlZTktN2IzNC03MTQ1LWExYWQtYTMxNDU5ZmI0ZmI1IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6MTJiNGExMDQtNGQ2NC00NWUyLWE4OWYtNGIwMWVmYzkwNzJiIj4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDoxMmI0YTEwNC00ZDY0LTQ1ZTItYTg5Zi00YjAxZWZjOTA3MmIiIHN0RXZ0OndoZW49IjIwMjMtMTEtMTJUMTM6NDU6MzYtMDY6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyNS4xIChNYWNpbnRvc2gpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDplYjA5MzQ3NC1kYWExLTQwYTItODgxNi02NmVmNTI1ZjhiZTEiIHN0RXZ0OndoZW49IjIwMjMtMTEtMTJUMTM6NDY6MzUtMDY6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyNS4xIChNYWNpbnRvc2gpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Ptyk6HcAAAFkSURBVEiJ3ZUxTsMwFIa/tD1AZyQYyAFgQSzlBKbtWBRGEOrEAXqAHqATQl1BdKStTwALYoEDpAsSrL0AMgNymqS2Y0dM/IvlyPH33vP77QiH9h9Plen7aLbm8v45cv1bVuTaUCvtLQCI510AVv1lEASg4bPo8Pi2MJ8mHWdgRlBVNgBvL1eF+XjQDoZFPiCTQsvnVTqTQjOqDQotX6OqBGlvwaQ5zDqvLqwFMGkOEUIgpdwaAYQQ1g2q/KR7IFuklLJGJqXk+vvGupnJwPkmW/WXUXZGOvr8GM+7xPOuEwLbJSxDChnZ2nx89P4b9euBE6YzGw/a2Tx//pVe+CuftWwLp0lH6ejS3oLZ1x7gl5lJQe5++NxVIbB8VkGGPdv5iGBzbiGqfTP8H5AuX5XKXRf8UmrZ2t52d3qBfL3kuqArSzdNOmo0W/twnLIaVkMALu6e4PwEoHDFhMirdBpYhoQ85z9sdZQssI4UFAAAAABJRU5ErkJggg==""")

def main(config):
    """
    App entrypoint.
    Retrieves the nearest earth objects from the NASA NeoWS.
    Returns rendered application root.
    """
    if API_KEY == None:
        return render.Root(
            child = render_static_dino(),
        )
    else:
        unit = config.get("distance_key", DEFAULT_UNIT)
        now = time.now()
        pretty_now = now.format("January 2, 2006")
        query_now = now.format("2006-01-02")

        neos = get_neos(query_now)
        if not neos:
            return render.Root(
                child = render.Box(
                    render.WrappedText("No asteroids today!", color = TERMINAL_TEXT_COLOR),
                ),
            )

        nearest_distance = get_shortest_distance(neos, unit)
        nearest_neo = get_nearest_neo(neos, nearest_distance, unit)
        pretty_distance = humanize.comma(int(nearest_distance))

        date_string = "On {}".format(pretty_now)
        asteroid_string = "Asteroid: \n {}".format(nearest_neo["name"])
        pre_proximity_string = "Will miss the Earth by..."
        distance_string = config.get("distance_key", DEFAULT_UNIT)
        proximity_string = "{} \n {}".format(pretty_distance, distance_string)

        static_dino = [
            render_static_dino()
            for frame in range(30)
        ]

        return render.Root(
            delay = 90,
            show_full_animation = bool(1),
            child = render.Row(
                children = [
                    render.Box(
                        width = 64,
                        child = render.Sequence(
                            children = [
                                render.Animation(generate_string_segments(date_string)),
                                render.Animation(generate_static_string_frames(date_string, 10)),
                                render.Animation(generate_string_segments(asteroid_string)),
                                render.Animation(generate_static_string_frames(asteroid_string, 10)),
                                render.Animation(generate_string_segments(pre_proximity_string)),
                                render.Animation(generate_static_string_frames(pre_proximity_string, 10)),
                                render.Animation(generate_string_segments(proximity_string)),
                                render.Animation(generate_static_string_frames(proximity_string, 10)),
                                animation.Transformation(
                                    child = render.Row(
                                        expanded = bool(1),
                                        cross_align = "end",
                                        main_align = "end",
                                        children = [
                                            render.Box(
                                                height = 32,
                                                width = 34,
                                                child = render.WrappedText("", font = "tom-thumb"),
                                            ),
                                            render.Box(
                                                height = 26,
                                                width = 28,
                                                child = render.Image(DINO),
                                            ),
                                        ],
                                    ),
                                    duration = 8,
                                    keyframes = [
                                        animation.Keyframe(
                                            percentage = 0.0,
                                            transforms = [animation.Translate(0, 32)],
                                            curve = "ease_out",
                                        ),
                                        animation.Keyframe(
                                            percentage = 1.0,
                                            transforms = [animation.Translate(0, 0)],
                                            curve = "ease_out",
                                        ),
                                    ],
                                ),
                                render.Animation(static_dino),
                            ],
                        ),
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "distance_key",
                name = "Distance Unit",
                desc = "Unit to use when displaying distances.",
                icon = "gear",
                default = DEFAULT_UNIT,
                options = [
                    schema.Option(
                        display = "Miles",
                        value = "miles",
                    ),
                    schema.Option(
                        display = "Kilometers",
                        value = "kilometers",
                    ),
                ],
            ),
        ],
    )

def get_neos(query_now):
    params = {
        "api_key": API_KEY,
        "start_date": query_now,
        "end_date": query_now,
    }
    req = http.get(BASE_URL, ttl_seconds = 3600, params = params)
    if req.status_code != 200:
        fail("API request failed with status:", req.status_code)

    data = req.json()
    if not data["element_count"]:
        return None

    neos = data["near_earth_objects"][query_now]

    return neos

def get_nearest_neo(neos, nearest_distance, unit):
    for neo in neos:
        if float(neo["close_approach_data"][0]["miss_distance"][unit]) == nearest_distance:
            return neo
    return None

def get_shortest_distance(neos, unit):
    distances = []
    for neo in neos:
        distances.append(float(neo["close_approach_data"][0]["miss_distance"][unit]))

    return min(*distances)

def generate_static_string_frames(string, duration):
    frames = []
    for _ in range(duration):
        frames.append(render_character(string, color = TERMINAL_TEXT_COLOR))

    return frames

def generate_string_segments(string):
    segments = []
    for i, _ in enumerate(string.elems()):
        segments.append(render_character(string[:i + 1], color = TERMINAL_TEXT_COLOR))

    return segments

def render_character(string, color):
    return render.WrappedText(string, color = color)

def render_static_dino():
    return render.Row(
        cross_align = "end",
        main_align = "space_between",
        expanded = bool(1),
        children = [
            render.Box(
                height = 32,
                width = 34,
                child = render.WrappedText("This is fine.", font = "tom-thumb"),
            ),
            render.Box(
                height = 26,
                width = 28,
                child = render.Image(DINO),
            ),
        ],
    )
