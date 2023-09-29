"""
Applet: Catfact
Summary: A random fact about a cat
Description: Calls an external API and retrieves a random cat fact and renders it. Rotating every 4 minutes.
Author: broepke
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

CAT_URL = "https://catfact.ninja/fact"

# https://www.pixilart.com/art/tidycat-sr2866c333cb471
CAT_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAACKADAAQAAAABAAAACAAAAACVhHtSAAAAVElEQVQYGV1OwRGAMAwqPfdzAqfTBXTBmOQOyjWfUCAFxP3GyMF1ojaH/BQR0cZ6JxQ+aNgF8nA3Sd+KAFYFx4ro2OfrY6swZrrXqf+duDSJexdqPwAMIrIbCvXsAAAAAElFTkSuQmCC
""")

def main():
    """Main entry point of the applicaiton.  Returns the rendering for the Tidbyt applet.

    Returns:
        render.Root: The rendering for the Tidbyt applet.
    """

    fact_cached = cache.get("cat_fact_cached")
    if fact_cached != None:
        print("Hit! Displaying cached data.")
        print(fact_cached)
        response = fact_cached
    else:
        print("Miss! Calling Cat Fact API.")
        rep = http.get(CAT_URL)

        if rep.status_code != 200:
            fail("Request failed with status %d", rep.status_code)

        print(fact_cached)
        response = rep.json()["fact"]

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("cat_fact_cached", response, ttl_seconds = 240)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(
                            width = 8,
                            height = 8,
                            src = CAT_ICON,
                        ),
                        render.Text(
                            "Cat Fact:",
                            offset = 0,
                            height = 10,
                            color = "#FFFFFF",
                        ),
                    ],
                ),
                render.Marquee(
                    height = 24,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_text(response),
                        ),
                ),
            ],
        ),
    )

def render_text(fact_text):
    cat_text = []
    cat_text.append(render.WrappedText(fact_text))

    return (cat_text)
