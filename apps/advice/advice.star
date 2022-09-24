"""
Applet: Advice
Summary: Random advice API
Description: Shows random advice from AdviceSlip.com.
Author: mrrobot245
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("re.star", "re")
load("http.star", "http")
load("cache.star", "cache")

def main(config):
    SCROLL_SPEED = config.str("scroll_speed", "60")
    rep_cache = cache.get("adviceapp")
    if rep_cache != None:
        print("Hit! Displaying cached data.")
        rep = json.decode(rep_cache)
    else:
        print("Miss! Calling Advice API.")
        rep = http.get("https://api.adviceslip.com/advice")
        if rep.status_code != 200:
            fail("Advice request failed with status:", rep.status_code)
        rep = rep.json()
        cache.set("adviceapp", json.encode(rep), ttl_seconds = 120)

    return render.Root(
        delay = int(SCROLL_SPEED),
        child = render.Column(
            children = [
                render.Marquee(
                    offset_start = 32,
                    offset_end = 32,
                    width = 64,
                    height = 32,
                    scroll_direction = "vertical",
                    child =
                        render.Column(
                            children = [
                                render.Padding(
                                    render.WrappedText(
                                        content = rep["slip"]["advice"],
                                        width = 60,
                                        color = "#fff",
                                    ),
                                    pad = (3, 0, 3, 2),
                                ),
                            ],
                        ),
                ),
            ],
        ),
    )

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slow", value = "200"),
        schema.Option(display = "Slower", value = "150"),
        schema.Option(display = "Normal (Default)", value = "100"),
        schema.Option(display = "Fast", value = "60"),
        schema.Option(display = "Faster", value = "30"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll speed",
                desc = "Text scrolling speed",
                icon = "personRunning",
                default = scroll_speed[2].value,
                options = scroll_speed,
            ),
        ],
    )
