"""
Applet: USGS Earthquakes
Summary: Recent nearby earthquakes
Description: Displays the most recent earthquakes based on location.
Author: Chris Silverberg (csilv)
"""

# USGS Earthquakes
# Version: 1.0.1 (2022/05/07)
#
# This app uses the USGS GeoJSON Summary Feed:
# https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php
#
# Copyright (c) 2022 Chris Silverberg
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("animation.star", "animation")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://earthquake.usgs.gov/fdsnws/event/1/query"

CACHE_TTL = 300
DELAY_MS = 20
MAX_QUAKES = 3

DEVICE_WIDTH = 64
DEVICE_HEIGHT = 32
ROW_HEIGHT = 10

DEFAULT_LOCATION = """
{
    "lat": "33.745571",
    "lng": "-117.867836",
    "locality": "Santa Ana, CA, USA",
    "timezone": "America/Los_Angeles"
}
"""
DEFAULT_MAGNITUDE = "3"
DEFAULT_RADIUS = "0"

ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAAAXNSR0IArs4c6QAAAD1JREFUKFNjZM
AC/jMw/GdkYGBElkLhgCRAikA0XoUwk/CaiCyJVSE2q9A1QZ2C6RtsTsDwDC4P4VSI7msAgYEaB3C6
FRsAAAAASUVORK5CYIIA
""")

def main(config):
    # Get latitude and longitude from location.
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    tz = loc.get("timezone")

    # Truncate to protect the user's privacy.
    lat = humanize.float("#.##", float(loc.get("lat")))
    lng = humanize.float("#.##", float(loc.get("lng")))

    # Get radius and minimum magnitude.
    radius = config.get("radius", DEFAULT_RADIUS)
    magnitude = config.get("magnitude", DEFAULT_MAGNITUDE)

    # Fetch earthquakes from the cache or network.
    earthquakes = fetch_earthquakes(lat, lng, radius, magnitude)
    if not earthquakes:
        return []

    # Get pages frames for the list of earthquakes.
    pages = [get_page_frames(q, tz) for i, q in enumerate(earthquakes)]
    if not pages:
        return []

    # Generate the list of frames to render.
    frames = []
    if len(pages) > 1:
        # Multiple pages to show, yay!
        for i, page_frames in enumerate(pages):
            next_page_frames = pages[(i + 1) % len(pages)]
            frames.extend(page_frames)
            frames.extend(get_scroll_frames(page_frames[0], next_page_frames[0]))
    else:
        # Just one page, but that's okay.
        frames.extend(pages[0])

    # Render the list of frames as an aniamtion.
    return render.Root(
        child = render.Animation(frames),
        delay = DELAY_MS,
    )

def get_page_frames(quake, timezone):
    properties = quake.get("properties")

    # Generate magnitude string and color.
    mag = properties.get("mag")
    mag_str = "Mag {}".format(mag)
    mag_color = color_from_magnitude(mag)

    # Get the place string from the response.
    place_str = properties.get("place")

    # Format a relative date string.
    time_utc = time.from_timestamp(int(properties.get("time") / 1000))
    time_in_location = time_utc.in_location(timezone)
    time_str = humanize.time(time_in_location)

    # Get the length of the place string.
    place_len = render.Text(place_str).size()[0]

    if place_len > DEVICE_WIDTH:
        # Place string requires scrolling, so generate the first set of frames.
        frames_a = [
            get_page_frame(mag_str, mag_color, place_str, place_x, time_str)
            for place_x in range(0, -place_len, -1)
        ]

        # Followup with the next set of frames.
        frames_b = [
            get_page_frame(mag_str, mag_color, place_str, place_x, time_str)
            for place_x in range(DEVICE_WIDTH, -1, -1)
        ]

        # Return the combination.
        return frames_a + frames_b
        #frames_a.extend(frames_b)

    else:
        place_x = int((DEVICE_WIDTH - place_len) / 2)
        return [
            get_page_frame(mag_str, mag_color, place_str, place_x, time_str),
        ] * DEVICE_WIDTH

def get_page_frame(mag_str, mag_color, place_str, place_x, time_str):
    return render.Box(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "start",
            children = [
                render.Row(
                    children = [
                        render.Image(ICON),
                        render.Box(width = 2, height = ROW_HEIGHT),
                        render.Text(mag_str, color = mag_color),
                    ],
                    expanded = True,
                    main_align = "center",
                ),
                render.Box(
                    child = animation.AnimatedPositioned(
                        child = render.Text(place_str),
                        curve = "linear",
                        duration = 0,
                        x_start = place_x,
                        x_end = place_x,
                    ),
                    width = DEVICE_WIDTH,
                    height = ROW_HEIGHT,
                ),
                render.Row(
                    children = [
                        render.Text(time_str),
                    ],
                    expanded = True,
                    main_align = "center",
                ),
            ],
        ),
        height = DEVICE_HEIGHT,
    )

def get_scroll_frames(item, next_item):
    # This function is derived from a similar function in the
    # BGG Hotness Applet by Henry So, Jr.
    # https://github.com/tidbyt/community/tree/main/apps/bgghotness
    return [
        render.Padding(
            pad = (0, offset, 0, 0),
            child = render.Stack([
                item,
                render.Padding(
                    pad = (0, DEVICE_HEIGHT, 0, 0),
                    child = next_item,
                ),
            ]),
        )
        for offset in range(-1, -DEVICE_HEIGHT - 1, -1)
    ]

def fetch_earthquakes(lat, lng, radius, magnitude):
    # For global earthquakes, the cache_key will just be the magnitude.
    cache_key = magnitude
    if radius != "0":
        cache_key = "%s_%s_%s_%s" % (lat, lng, radius, magnitude)
    cache_data = cache.get(cache_key)
    if cache_data:
        return json.decode(cache_data)

    params = {
        "format": "geojson",
        "minmagnitude": magnitude,
        "limit": str(MAX_QUAKES),
    }
    if radius != "0":
        geo_params = {
            "latitude": lat,
            "longitude": lng,
            "maxradiuskm": radius,
        }
        params.update(geo_params)

    resp = http.get(BASE_URL, params = params)

    if resp.status_code != 200:
        # buildifier: disable=print
        print("http.get failed: %s - %s" % (resp.status_code, resp.body()))
        return None

    features = resp.json().get("features")
    if not features:
        # buildifier: disable=print
        print("missing features: %s" & resp.body())
        return None

    cache.set(cache_key, json.encode(features), CACHE_TTL)
    return features

def color_from_magnitude(magnitude):
    mag = float(magnitude)
    if mag >= 5:
        return "#ff0000"
    elif mag >= 4:
        return "#ff8000"
    elif mag >= 3:
        return "#ffff00"
    elif mag >= 2:
        return "#80ff00"
    else:
        return "#00ffff"

def get_schema():
    radius_options = [
        schema.Option(display = "{}km".format(item), value = str(item))
        for item in [10, 25, 50, 100, 250, 500, 1000, 2500, 5000]
    ]
    radius_options.append(schema.Option(display = "Unlimited", value = "0"))

    magnitude_options = [
        schema.Option(display = str(item), value = str(item))
        for item in [1, 2, 3, 4, 5]
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to find nearby earthquakes.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "radius",
                name = "Radius",
                desc = "The radius from the location to find nearby earthquakes.",
                icon = "brush",
                default = DEFAULT_RADIUS,
                options = radius_options,
            ),
            schema.Dropdown(
                id = "magnitude",
                name = "Magnitude",
                desc = "The minimum magnitude to show.",
                icon = "brush",
                default = DEFAULT_MAGNITUDE,
                options = magnitude_options,
            ),
        ],
    )
