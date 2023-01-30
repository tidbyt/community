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

def main():
    img = http.get("https://images.squarespace-cdn.com/content/v1/5a01fd2db1ffb6985b2a9ac5/1546498497668-Q2EBX5HB7KB1FRF81IVV/VITAL+-+Clean+DARK+GREY.png?format=1500w").body()

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
        cache.set("curocc", currocc, ttl_seconds = 240)

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = img, width = 30),
                render.Text(currocc),
            ],
        ),
    )
