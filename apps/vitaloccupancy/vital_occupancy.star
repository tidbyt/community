"""
Applet: Vital Occupancy
Summary: Vital Gym Current Occupancy
Description: The Current Occupancy of Vital Climbing's Brooklyn, NY location.
Author: flip-z
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")

GYM_URL = "https://display.safespace.io/value/live/a7796f34"

# Pixel Art version of Vital Logo
LOGO_URL = "https://i.imgur.com/6RBuVuM.png"

def main():
    # Cache Current Occupancy
    cached_currocc = cache.get("currocc")
    if cached_currocc != None:
        print("Hit! Displaying cached data.")
        currocc = cached_currocc
    else:
        print("Miss! Grabbing count from GYM_URL")
        req = http.get(GYM_URL)
        if req.status_code != 200:
            fail("Gym Request failed with status %d", req.status_code)

        currocc = req.body()
        cache.set("curocc", currocc, ttl_seconds = 60)

    # Cache Logo Image
    cached_logo = cache.get("logo")
    if cached_logo != None:
        print("Hit! Displaying cached data.")
        logo = cached_logo
    else:
        print("Miss! Grabbing logo image from LOGO_URL")
        logo = http.get(LOGO_URL).body()
        cache.set("logo", logo, ttl_seconds = 3600)

    color = "#cd0800"  # red
    if int(currocc) < 120:
        color = "#26ff7b"  # green
    elif int(currocc) < 150:
        color = "#ffd766"  # yellow

    if int(currocc) == 69:
        currocc_child = render.Animation(
            children = [
                render.Text(currocc, font = "10x20", color = color),
                render.Text(currocc, font = "10x20", color = "#aa39d3"),
                render.Text(currocc, font = "10x20", color = "#d2b1ea"),
                render.Text(currocc, font = "10x20", color = "#d6daff"),
            ],
        )
    else:
        currocc_child = render.Text(currocc, font = "10x20", color = color)

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    currocc_child,
                    render.Image(src = logo),
                ],
            ),
        ),
    )
