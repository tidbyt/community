"""
Applet: Solar Elevation
Summary: How high is the sun
Description: A clock for when you cannot look out of the window or at an actual clock. How high is the sun above or below the horizon right now?
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

DEFAULT_LOCATION = """
 {
     "lat": 52.0406,
     "lng": -0.7594,
     "locality": "Milton Keynes, UK",
     "timezone": "Europe/London"
 }
 """

# Sunrise and sunset occur when the center of the sun is 50 arc minutes
# below the horizon, due to a) refraction and b) us caring about when
# the top is over the horizon, rather than the middle.
# https://en.wikipedia.org/wiki/Sunrise#Angle
SUNRISE_ELEVATION = -50.0 / 60.0

# Sun is about half a degree across in the sky.
SOLAR_ANGULAR_RADIUS = 0.25

def draw(elevation):
    rounded_elevation = str(int(math.round(math.fabs(elevation) * 100)))
    rounded_degrees = rounded_elevation[0:-2] + "." + rounded_elevation[-2:]

    direction = "above" if elevation >= 0 else "below"

    horizon_pad = 29 if elevation >= -SOLAR_ANGULAR_RADIUS else 0

    if elevation > SOLAR_ANGULAR_RADIUS:
        # There are 13 possible states between the sun being at its highest
        # and being entirely above the horizon.
        angle_per_frame = (90.0 - SOLAR_ANGULAR_RADIUS) / 12.0
        sun_pad = int(math.round((90.0 - elevation) / angle_per_frame))
    elif elevation >= -SOLAR_ANGULAR_RADIUS:
        # There are 16 possible states where the sun is partially overlapping
        # the horizon
        angle_per_frame = (2.0 * SOLAR_ANGULAR_RADIUS) / 16.0
        sun_pad = 13 + int(math.round((SOLAR_ANGULAR_RADIUS - elevation) / angle_per_frame))
    else:
        # There are 13 possible states where the sun is entirely below the horizon
        angle_per_frame = (-90.0 + SOLAR_ANGULAR_RADIUS) / 13.0
        sun_pad = 14 - int(math.round((-90.0 - elevation) / angle_per_frame))

    # TODO: Background colours? Blue during day, sunset/sunrise gradient, dark at night?
    return render.Padding(
        pad = (1, 1, 1, 1),
        child = render.Row(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Box(
                    width = 30,
                    height = 30,
                    color = "#000",
                    child = render.Stack(
                        children = [
                            render.Box(
                                width = 30,
                                height = 30,
                                color = "#000",
                            ),
                            render.Padding(
                                pad = (7, sun_pad, 0, 0),
                                child = render.Circle(
                                    diameter = 16,
                                    color = "#ff0",
                                ),
                            ),
                            render.Padding(
                                pad = (0, horizon_pad, 0, 0),
                                child = render.Box(
                                    width = 30,
                                    height = 1,
                                    color = "#fff",
                                ),
                            ),
                        ],
                    ),
                ),
                render.Box(
                    width = 2,
                    height = 30,
                    color = "#000",
                ),
                render.Box(
                    width = 30,
                    height = 30,
                    color = "#000",
                    child = render.Column(
                        main_align = "center",
                        children = [
                            render.WrappedText(
                                content = "{}° {}".format(rounded_degrees, direction),
                                width = 28,
                                align = "center",
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    latitude = float(location["lat"])
    longitude = float(location["lng"])

    now = time.now()
    elevation = sunrise.elevation(latitude, longitude, now)

    return render.Root(
        child = draw(elevation),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the solar elevation",
                icon = "locationDot",
            ),
        ],
    )
