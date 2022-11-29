"""
Applet: Swedish Name Day
Summary: Shows today's name in Sweden
Description: The app shows today's nameday names in Sweden.
Author: y34752
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("re.star", "re")
load("http.star", "http")
load("cache.star", "cache")

def getlistasstring(listin):
    ref = ""
    for k in listin:
        v = k
        ref = ref + "\n" + v

    return ref

def main(config):
    SCROLL_SPEED = config.str("scroll_speed", "60")
    rep_cache = cache.get("todaysnames")
    if rep_cache != None:
        print("Hit! Displaying cached data.")
        rep = json.decode(rep_cache)
        namelist = rep["dagar"][0]["namnsdag"]
        names = getlistasstring(namelist)
    else:
        print("Miss! Calling todays name API.")
        rep = http.get("https://sholiday.faboul.se/dagar/v2.1/")
        if rep.status_code != 200:
            fail("Todays name request failed with status:", rep.status_code)
        rep = rep.json()
        cache.set("todaysnames", json.encode(rep), ttl_seconds = 120)
        namelist = rep["dagar"][0]["namnsdag"]
        names = getlistasstring(namelist)
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
                                        content = names,
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
