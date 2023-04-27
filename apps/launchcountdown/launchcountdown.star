"""
Applet: LaunchCountdown
Summary: Displays next world launch
Description: Displays the next rocket launch in the world.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#Constants
ROCKET_LAUNCH_URL = "https://fdo.rocketlaunch.live/json/launches/next/5"
ROCKET_LAUNCH_CACHE_NAME = "LaunchCountdownCache"
MINIMUM_CACHE_TIME_IN_SECONDS = 600
MAXIMUM_CACHE_TIME_IN_SECONDS = 400000

#Rocket Icons to loop through
rocket_icon = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAACY0lEQVQ4jY3P30tTYRzH8c/zPMdtHd2Za95oGYUU4Q+IIpk/iiSCsKSIFBOCAqM/oG6DcyXRXRdedhHFDOtuhRd5kaz9EEQpZ0RQ/kCRULd5zna2s/k8Txe1FXNi39svrzffL8F/zsPRUJ9SpdyglJ4SQjQIIWukkITsB3VdUutQLKA6q3qPNTW4NU2Fw1UFSik+TM6llf1wrj4WqNXUqx3drdWM0dLONCwQkL0Dui6p3RAb83jUK/4/eOxNFADBrZt+5HJ5UEZX6V44Vx8LuP/BxSGQAADDsKTgfJYAQL8+7rAL7keM0iNC7kRONnov19ZWXyrHxeFcYGpyzsykswOkXx93cK69c7vdnT7fQVXYKV7nVUnX+VZafnYRRz7GLdOwgo/vdQwqdr7mOVPIhabjTQrPbMFRrbLO7hZUOptzgWg4bpmmFXSt+YcAgJ24ODhFOXPSgtHu0Ry0q7sFTGEl3NbciNbmxhI2DCvoWvUP6ToRv+MAHoyGzxIqp7vOtRFfnVbx52gonkmZ1lt17S8GAAoAi+vG/URa2NORL0gl07twJDQvU0bmfTkuBZw8f13zeJ01dYcRCcVLEc4FYuEFbCQt8W15e6IcAwCN9fT0Dn8dO5BaWySJhIFiZGtzG9HwArIFBuLwMsqYf9dvACh1uYZbTh9Vn9w1kVj5jo3NlNwwCnY4tCBX15NcUX3YSiSyAF+pGIAQZ2ALiBfzuD0fsH4u/UgkU5mXfEe2r29mn87NftoxTTPCqDlSKaAIIZzLM5+XiZQzaqHw7NXItYnisk8PLhGb1judmTuv9YF8pcAvJgMvFQ4bgRAAAAAASUVORK5CYII=
""")

rocket_icon_b = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAACY0lEQVQ4jY3P30tTYRzH8c/zPMdtHd2Za95oGYUU4Q+IIpk/iiSCsKSIFBOCAqM/oG6DcyXRXRdedhHFDOtuhRd5kaz9EEQpZ0RQ/kCRULd5zna2s/k8Txe1FXNi39svrzffL8F/zsPRUJ9SpdyglJ4SQjQIIWukkITsB3VdUutQLKA6q3qPNTW4NU2Fw1UFSik+TM6llf1wrj4WqNXUqx3drdWM0dLONCwQkL0Dui6p3RAb83jUK/4/eOxNFADBrZt+5HJ5UEZX6V44Vx8LuP/BxSGQAADDsKTgfJYAQL8+7rAL7keM0iNC7kRONnov19ZWXyrHxeFcYGpyzsykswOkXx93cK69c7vdnT7fQVXYKV7nVUnX+VZafnYRRz7GLdOwgo/vdQwqdr7mOVPIhabjTQrPbMFRrbLO7hZUOptzgWg4bpmmFXSt+YcAgJ24ODhFOXPSgtHu0Ry0q7sFTGEl3NbciNbmxhI2DCvoWvUP6ToRv+MAHoyGzxIqp7vOtRFfnVbx52gonkmZ1lt17S8GAAoAi+vG/URa2NORL0gl07twJDQvU0bmfTkuBZw8f13zeJ01dYcRCcVLEc4FYuEFbCQt8W15e6IcAwCN9fT0Dn8dO5BaWySJhIFiZGtzG9HwArIFBuLwMsqYf9dvACh1uYZbTh9Vn9w1kVj5jo3NlNwwCnY4tCBX15NcUX3YSiSyAF+pGIAQZ2ALiBfzuD0fsH4u/UgkU5mXfEe2r29mn87NftoxTTPCqDlSKaAIIZzLM5+XiZQzaqHw7NXItYnisk8PLhGb1judmTuv9YF8pcAvJgMvFQ4bgRAAAAAASUVORK5CYII=
""")

rocket_icon_c = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMRDhkvmYOhXgAAAmFJREFUOMuN0l1Ik1Ecx/HfOedxW49uc203WQYhRfgCRaTzpUgiCEuISDEhKDC66a5ug+cqorsCL7sIQsG6WyGRiLL2IoQSzoigTFEs1GePz7M989k853RRW7HWy//2z+d7zoFD8J9zezjaq1QpFymlR4QQdULIGikkIf+CmiapvTc5orqreg401Hl9PhUuTxUopZiamMso/8Lbe5IjtT71fHtXczVjtLSzTBsE5M8BTZPUqUuO+v3qufAPPPosAYDg8qUwtrfzoIyu0L+d7P0FF4dAAgBM05aC81kCAH3amMspeO8wSvcLuRM/XB84W1tbfaYcF4dzgemJOSubyfWTPm3Mxbnvhdfr7QgGd6vCMXgooJLOk820/NpFHH+dsi3Tjty73j6gOPmax0whpxoONig8uwlXtco6uppQ6dqcCyRiKduy7IhnNTwIAOzQ6YFpypmbFsxWv89FO7uawBRWwi2N9WhurC9h07QjnpXwoKYR8T0O4NZw7DihcqbzRAsJhnwV35yIprKGZT9XV39iAKAAsLhm3tAzwpmJv4ORzvyG49F5aZjZV+W4FHDz/AWfP+CuCe1DPJoqRTgXSMYWsJ62xYelrfFyDAA02d3dM/R+dJexukh03UQxsrmxhURsAbkCA3EFGGUsXOnPUOrxDDVNvVTvX7OgL3/E+oYh182CE4suyJW1NFfUIDZ1PQfw5YoBCHEMAMTRm7gyP2J//fxJTxvZJ3xHtq5t5B7Mzb7dsSwrzqh1t1KAfAkE5FJb2xKR8g0vFB61T06OF5e9WiREHPrQ7c5efar15ysFvgFRBSwZaopWfwAAAABJRU5ErkJggg==
""")

rocket_icon_d = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMRDhs0IdAKMAAAAmRJREFUOMuN0k1IFGEcx/Hf8zyzs9vozrrtXjQNQorwBboo60uRRBCWEJFinQoMu9c1GOgSHQMPHTp00dA6bSWRiLbui5c8tEoEIcmKxrrrOrMz6+z2PNOhdotty/7Xh8/3+T/wEPzn3J2IDEku6Qql9JQQokkIp94RDiEHQU1zqHUkMam4XYPHWpu8qqpA9rhAKcXC3EpeOgjvNyYmG1TlUk9/Rx1jtHJm6BYIyN8DmuZQuykx5fMpF0M/8dTzOACCa1dD2N8vgjKaov+62fsbLg+BAwDQdcsRnL8nADCsTct2yXuPUXpUON9iJ1v8Fxoa6s5X4/JwLrA4t2KY+cIIGdamZc7VV16vtzcQOKwIO8eDfoX0nemg1WuXcWwpaRm6FX5wq2dUsov1T5lEzrYeb5W4mYFcp7De/nbUWptzgXg0aRmGFfZshq4DADtxbnSRcuamJb3bp8q0r78dTGIV3NnWgo62lgrWdSvsSYWuaxoRP+IA7kxEuwh1lvtOd5JAUK355ngkaeYM66Wy+QsDAAWA9S19PJsX9nJsDbnd/B84Fvng5HTzbTWuBNy8eFn1+d31wWbEIslKhHOBRHQV6V1LfPqyN1uNAYAmBgYGxz5OHcptrpNsVkc5ktnZQzy6ikKJgch+RhkL1fozlHo8Y+0Lb5SHNw1kNz4jvZNz0nrJjkZWndTWLpeUADLZbAHgG7UC7H4m8wwAnMev0agUrHeuZsO0xbSqyOOptGVub33tKhbtJYkat9cWZnh1gGz7/Q4AbHR3v+Cl0pOe+fnZ8uGQFg4Smz5yu80bM9pIsdYG3wFGIiiy+bwJ8gAAAABJRU5ErkJggg==
""")

rocket_icon_e = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMRDhwXzPbthQAAAlpJREFUOMuNk81LVFEYh3/nnOvMdHXuOI0bLaOQIvyAWiTjR5FEEJYUoWJCUFC0aVfb4K4k2rXwDwhCw9pNIpELZZoPN2o4RgSliSLleOd678yduTOec1vUTDVN2W91Di/Pc94X3kPwn7k/Gu6TqqSrlNITQogGIZwaRziE7AWqqkOtA/Ex2V3Ve6SpwasoMlyeKlBKMTO9kJb2gnP18bFaRb7U0d1azRgt1UzDAgH5u0BVHWo3xMd9Pvli8Ac8/iIGgOBafxC5XB6U0XX6r5e9v8DFEDgAAMOwHMH5PAGAAXXCZRe8Dxilh4SzGz3e6L9QW1t9vhwuhnOB2ekFM5PODpIBdcLFuTLp9Xo7A4H9srB1XueXSdeZVlredhGOvklYpmGFHt7uGJLsfM0TJpGzTUebJJ7ZhqtaZp3dLajUNucCsUjCMk0r5NkIDgMAO3ZuaJZy5qYFo92nuGhXdwuYxEpwW3MjWpsbS7BhWCHPenBYVYn4LgdwbzRyilBnrut0GwnUKRVnjoUTGd20XsobP2EAoACwsmnc0dLCnou+g55K/wFHw0uObmRel8MlgZvnryg+v7um7iCi4URJwrlAPLKMrZQlPnzemSqHAYDGe3p6b70f36dvrBBNM1CUbCd3EIssI1tgIC4/o4wFK+0MPby4ONky80p+dNOEtvYRW0nd2TIKdiS87KxvprgkB7CtaVmAr1UUFA/i5F1cXxqzvqx+0lJ65infddo3k9nHC/Nvd03TjDJqjlQS/PYX5J2v/c9GLk8V731qaJXYtN7tztx4rg7mKwm+AeP6I6z2tLb7AAAAAElFTkSuQmCC
""")

scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

#Get the json from cache, or download a new copy and save that in cache
def get_rocket_launch_json():
    """ Get the Rocket Launch json from the API call

    Returns:
        The json info
    """
    cached_encoded_json = cache.get(ROCKET_LAUNCH_CACHE_NAME)
    if (cached_encoded_json != None):
        rocket_launch_data = json.decode(cached_encoded_json)
    else:
        rocket_launch_data = None

    if (rocket_launch_data == None):
        rocket_launch_http = http.get(ROCKET_LAUNCH_URL)

        if rocket_launch_http.status_code != 200:
            fail("RocketLaunch.live feed failed: %d", rocket_launch_http.status_code)
        else:
            rocket_launch_data = rocket_launch_http.json()

            if (rocket_launch_data != None):
                window_open_text = rocket_launch_data["result"][0]["win_open"]
                cache_time_seconds = MINIMUM_CACHE_TIME_IN_SECONDS
                if window_open_text != None:
                    #Current Json doesn't include seconds and throws error when parsing
                    if (len(window_open_text) == 17):
                        window_open_text = window_open_text.replace("Z", ":00Z")

                    #If the JSON feed updates to include the seconds, or it the fix above did it,
                    #we'll parse the time now
                    window_open_time = None
                    if (len(window_open_text) == 20):
                        window_open_time = time.parse_time(window_open_text)

                    if (window_open_time != None):
                        date_diff = window_open_time - time.now().in_location("GMT")

                        days = math.floor(date_diff.hours // 24)
                        hours = math.floor(date_diff.hours - days * 24)
                        minutes = math.floor(date_diff.minutes - (days * 24 * 60 + hours * 60))
                        seconds_this_json_is_valid_for = minutes * 60 + hours * 60 * 60 + days * 24 * 60 * 60

                        cache_time_seconds = seconds_this_json_is_valid_for

                if (cache_time_seconds > MAXIMUM_CACHE_TIME_IN_SECONDS):
                    cache_time_seconds = MAXIMUM_CACHE_TIME_IN_SECONDS
                if (cache_time_seconds < MINIMUM_CACHE_TIME_IN_SECONDS):
                    cache_time_seconds = MINIMUM_CACHE_TIME_IN_SECONDS

                cache.set(ROCKET_LAUNCH_CACHE_NAME, json.encode(rocket_launch_data), ttl_seconds = cache_time_seconds)

    return (rocket_launch_data)

#Since not all launches supply values for all these, this makes it easy to add items to a marquee
def get_launch_details(rocket_launch_data):
    """ Get Launch Details

    Args:
        rocket_launch_data: the rocket launch data with all the info on future launches
    Returns:
        Display info of launch details
    """
    potential_display_items = [
        rocket_launch_data["result"][0]["pad"]["name"],
        rocket_launch_data["result"][0]["pad"]["location"]["name"],
        rocket_launch_data["result"][0]["pad"]["location"]["state"],
        rocket_launch_data["result"][0]["pad"]["location"]["country"],
    ]

    display_text = ""

    for i in range(len(potential_display_items)):
        if (potential_display_items[i] != None):
            display_text += potential_display_items[i] + " "

    return display_text

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The tidbyt display
    """
    rocket_launch_data = get_rocket_launch_json()
    rocket_launch_count = 0
    row1 = "Test"
    row2 = "Test2"
    row3 = "Test3"
    row4 = "Test4"

    if rocket_launch_data == None:
        row1 = "Failed to get data from Rocketlaunch.live feed"
    else:
        rocket_launch_count = rocket_launch_data["count"]

    if (rocket_launch_count == 0):
        row1 = "No upcoming launches.."
    else:
        row1 = rocket_launch_data["result"][0]["vehicle"]["name"]
        row2 = rocket_launch_data["result"][0]["date_str"]
        row3 = get_launch_details(rocket_launch_data)
        row4 = rocket_launch_data["result"][0]["launch_description"]

    return render.Root(
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(row1, color = "#0000FF"),
                                        ),
                                        render.Marquee(
                                            width = 35,
                                            child = render.Text(row2, color = "#fff"),
                                        ),
                                    ],
                                ),
                                render.Animation(
                                    children = [
                                        render.Image(src = rocket_icon),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon_d),
                                        render.Image(src = rocket_icon_e),
                                        render.Image(src = rocket_icon_d),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon),
                                        render.Image(src = rocket_icon_d),
                                        render.Image(src = rocket_icon_e),
                                        render.Image(src = rocket_icon_d),
                                        render.Image(src = rocket_icon),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(row3, color = "#fff"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(row4, color = "#ff0"),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
