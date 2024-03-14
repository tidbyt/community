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

default_location = """
{
	"lat": "28.53933",
	"lng": "-81.38325",
	"description": "Orlando, FL, USA",
	"locality": "Orlando",
	"place_id": "???",
	"timezone": "America/New_York"
}
"""

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

rocket_icon_f = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABWGlDQ1BJQ0MgcHJvZmlsZQAAKJFtkL9LQlEcxY9lCCbh4CQFL2iosIinQ9FkDhE0vOx32/VqKj3t8t6Tag6a2oLGqKVaagpsrK29qOgfcIkggreU3L5XK7W6ly/nw5dzL4cDtHmZEKYXQKHoWMnJCW1peUXzVRBAD/wII8S4LeKGMU0WfGvrce/hUXo7pP7auRt38+d6+PX0ubR2lj756285/nTG5qQfNINcWA7g6Sc2NhyheJM4ZFEo4l3F2TofKk7V+aLmmUsmiG+IgzzH0sSPxJFU0z7bxAWzxL8yqPSBTHF+lrSLphsG4tARwyhmsEDd/O+N1bwJrENgCxbyyCIHBxq9FnRNZIinUATHMCLEOkZooqrj3901dmIbGNsjeGnsmAlcUvfBg8aur0Jxe4HrI8Es9tOox/Xaq1G9zp1loGNfyrdFwDcAVB+kfC9LWT0G2p+AK/cTJspkFpxq0b4AAAAGYktHRAD/AP8A/6C9p5MAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAHdElNRQfoAQQQDQLDRzG5AAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAAoJJREFUOMuN00tME1EUBuB/7gylTrE8phEEsSQQwBakPIXSOBglKooQwwZcmUBw40YTd4agG0OiC5eycgOJwRggoEHRtlCQCAUVasSABFTA0kJpO6XozLiRhqd4tn++/57FPRT+c5Izi8vTc09djtOmGVRqLp4OU0aU9d5nmf0gRRFSXtfYos/jy9L1KQfVahYKZRgIIejGDR+zH75U29iSbSq9yJ/OV9E0CWXeVQG/g4G9CyiKkIq6O63ZpjMXTv7FrW2DAChUVxVibW0dPs/SN/Kvlw2bcCiDDADwePzy/MwnOwMAhGYUqaaa26qo2KOuufGBnBP8uayiktLtuLqqCAAgihK+OKZ9n+3mZwyhGYWx+m6X9liBMTYunhUD7iuaGJYy8cfJ9rU3sKV3WHCMWLq/OoZeMNnlNx9rkrJK0nR6RvS7oFBF0EaTHrutLYoSrK+HhVFbT2dHc0MNANCu2Y8WQsLCOc3hgqjIcFJs0oNm6BDO1CUiQ5cYwvb+ns6ORw01sixJAEDWhdUl56S1lVXSRJ+RtAVvjChKsLx65x/p24oBgABAfObZeqcnGBwacGBl2bcD26wf5PdD5pedzVtxqCApJa8yOuZQeITmCAb6xkMloijhrW0CTrdfGh20PN+OAYAYOa6sdrr9wMqPGcrtXsVGiWvJg0HbBAK/aBAlR3OJusLd/gyp1Gprc/KT2aarXrhnp+B0LssLbiFos47Lc99dIsNy+Lk4HxA8i7O7FdDXU1ObEhISIuUJJ2LsZuGNFO2dHDM/6X/6oN617PUHqcj8+Sl7/1jXw2uyLIk7Grp5fqGd52fuGQxtRRx3fnOmYNWa3IpbLYRmFHvdzB9eQho77MS9ewAAAABJRU5ErkJggg==
""")

rocket_icon_g = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABWGlDQ1BJQ0MgcHJvZmlsZQAAKJFtkL9LQlEcxY9lCCbh4CQFL2iosIinQ9FkDhE0vOx32/VqKj3t8t6Tag6a2oLGqKVaagpsrK29qOgfcIkggreU3L5XK7W6ly/nw5dzL4cDtHmZEKYXQKHoWMnJCW1peUXzVRBAD/wII8S4LeKGMU0WfGvrce/hUXo7pP7auRt38+d6+PX0ubR2lj756285/nTG5qQfNINcWA7g6Sc2NhyheJM4ZFEo4l3F2TofKk7V+aLmmUsmiG+IgzzH0sSPxJFU0z7bxAWzxL8yqPSBTHF+lrSLphsG4tARwyhmsEDd/O+N1bwJrENgCxbyyCIHBxq9FnRNZIinUATHMCLEOkZooqrj3901dmIbGNsjeGnsmAlcUvfBg8aur0Jxe4HrI8Es9tOox/Xaq1G9zp1loGNfyrdFwDcAVB+kfC9LWT0G2p+AK/cTJspkFpxq0b4AAAAGYktHRAD/AP8A/6C9p5MAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAHdElNRQfoAQQQEh2DFTLSAAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAAoJJREFUOMuN00tME1EUBuB/7gylTrE8phEEoSQQwBakPIXSOBglKooQwwbYQnDjRhN3hqAbY6ILd8rKDSQGY4CABkXbQnlEKKhQIwYkoAKWFgrtlKIz40YanuLZ/vn+exb3UPjPScooKkvLOX0lRptqUKm5WDpEGVbac59lDoIURUhZXWOzPpcvTdMnH1arWSiUISCEoAvXvcxB+HJtY3OWqeQSfyZPRdMkmK2tCvgd8O9fQFGElNfdbskynb146i9uaR0AQKGqsgDr6xvwepa+kX+9bNiCgxlkAIDH45PnZz7ZGQAgNKNIMVXfUkVEJ7jmxvuzT/LnMwuLS3biqspCAIAoSvjimPZ+tpufM4RmFMaqO53a4/nG6JhYVvS7azRRLGXiT5Cda29iS8+w4BixdH11DL1ksspuPNEkZhan6vSM6HNBoQqjjSY99lpbFCVY3wwLo7bujvamhmoAoF2zHy2EhIRymqP5EeGhpMikB83QQZyhi0e6Lj6I7X3dHe2PG6plWZIAgGwIq0vOSWsLq6SJPj1xG94cUZRgef3ON9K7HQMAAYDYjHP1Tk8gMNTvwMqydxe2WT/I74fMrzqatuNgQWJybkVk1JHQMM0x9PeOB0tEUcKgbQJOt08aHbC82IkBgBg5rrR2uu3Qyo8Zyu1exWaJa8mDAdsE/L9oECVHc/G6gr3+DKnQamuz85LYmrFHcM9OwelclhfcQsBmHZfnvrtEhuXwc3HeL3gWZ/cqoK+lpNyLi4sLj06IQZTdLLyVItcmx8xP+549qHctr/kCVHje/JS9b6zz4VVZlsRdDV08v9DG8zN3DYbWQo67sDVTsGpNTvnNZkIziv1u5g8mDxevHDczqgAAAABJRU5ErkJggg==""")

period_options = [
    schema.Option(value = "1", display = "1 hour"),
    schema.Option(value = "2", display = "2 hours"),
    schema.Option(value = "3", display = "3 hours"),
    schema.Option(value = "4", display = "4 hours"),
    schema.Option(value = "5", display = "5 hours"),
    schema.Option(value = "6", display = "6 hours"),
    schema.Option(value = "12", display = "12 hours"),
    schema.Option(value = "24", display = "1 day"),
    schema.Option(value = "48", display = "2 days"),
    schema.Option(value = "72", display = "3 days"),
    schema.Option(value = "168", display = "1 week"),
    schema.Option(value = "0", display = "Always Display Next Sighting if known"),
]

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

                    #If the JSON feed updates to include the seconds, or if the fix above did it,
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

                # TODO: Determine if this cache call can be converted to the new HTTP cache.
                cache.set(ROCKET_LAUNCH_CACHE_NAME, json.encode(rocket_launch_data), ttl_seconds = cache_time_seconds)
                # Filter out any providers in ignoredProviders

    return (rocket_launch_data)

def filter_rocket_launches(rocket_launch_data, filter_for_providers_string, filter_for_countries_string):
    """ Filter Included Providers and Countries
    Args:
        rocket_launch_data: the rocket launch data with all the info on future launches
        filter_for_providers_string: comma separated list of providers to filter for
        filter_for_countries_string: comma separated list of countries to filter for
    Returns:
        rocket_launch_data but only with the included providers & countries
    """
    included_providers = [provider.strip().lower() for provider in filter_for_providers_string.split(",")] if filter_for_providers_string.strip() else []
    included_countries = [country.strip().lower() for country in filter_for_countries_string.split(",")] if filter_for_countries_string.strip() else []

    if not included_providers and not included_countries:  # if both lists are empty, return all data
        return rocket_launch_data

    filtered_data = [
        launch
        for launch in rocket_launch_data["result"]
        if (not included_providers or launch["provider"]["name"].lower() in included_providers) and
           (not included_countries or launch["pad"]["location"]["country"].lower() in included_countries)
    ]

    rocket_launch_data["result"] = filtered_data
    return rocket_launch_data

#Since not all launches supply values for all these, this makes it easy to add items to a marquee
def get_launch_details(rocket_launch_data, locallaunch):
    """ Get Launch Details
    Args:
        rocket_launch_data: the rocket launch data with all the info on future launches
    Returns:
        Display info of launch details
    """

    #TEST CODE to test time display
    #locallaunch = locallaunch + time.parse_duration("%sh" % -11.5)
    #print(locallaunch)

    countdown = (locallaunch - time.now())
    countdownDisplay = ""

    if countdown.hours >= 1.5:
        countdownDisplay = ("In %s hours %s minutes, " % (int(math.round(countdown.hours)), int(math.round(countdown.minutes - math.round(countdown.hours) * 60))))
    elif countdown.minutes > 0:
        countdownDisplay = ("%s minutes from now, " % int(math.round(countdown.minutes)))

    #SpaceX has a launch pad called launch pad ... looks stupid to display that.
    pad_name = None if rocket_launch_data["pad"]["name"] == "Launch Pad" else rocket_launch_data["pad"]["name"]

    potential_display_items = [
        rocket_launch_data["provider"]["name"],
        pad_name,
        rocket_launch_data["pad"]["location"]["name"],
        rocket_launch_data["pad"]["location"]["state"],
        rocket_launch_data["pad"]["location"]["country"],
        locallaunch.format("Monday Jan 2 2006"),
        locallaunch.format("3:04 PM MST"),
    ]

    display_items_format = [
        "%s will launch",
        "from %s",
        "%s",
        "in %s",
        "%s",
        "on %s",
        "at %s",
    ]

    display_text = countdownDisplay

    for i in range(len(potential_display_items)):
        if (potential_display_items[i] != None):
            display_text += " " + (display_items_format[i] % potential_display_items[i]).strip()

    return display_text

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    instructions_1 = "Launch information is provided by RocketLaunch.live. You can filter these results by country or provider. "
    instructions_2 = "Examples of country include 'United States', 'Canada' and 'China'. Examples of provider include 'NASA', 'SpaceX', 'ABL Space' and 'Virgin Galactic'."
    instructions_3 = "The country and provider information should appear in the third row of information of each upcoming flight."
    app_title = "Launch Countdown"

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(app_title, color = "#65d0e6", font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(app_title) * 5,
                    child = render.Text(instructions_1, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#f4a306"),
                ),
            ],
        ),
        delay = int(config.get("scroll", 45)),
        show_full_animation = True,
    )

def replace_local_time_into_description(description, locallaunch, utclaunch):
    utc_time_display = ("%s at %s (%s)") % (utclaunch.format("Thursday, January 2, 2006"), utclaunch.format("3:04 PM"), utclaunch.format("MST"))
    local_time_display = ("%s at %s %s") % (locallaunch.format("Thursday, January 2, 2006"), locallaunch.format("3:04 PM"), locallaunch.format("MST"))

    #What the heck is this character being returned in the json for??
    description = description.replace(" ", " ")
    description = description.replace(utc_time_display, local_time_display)

    return description

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The tidbyt display
    """

    show_instructions = config.bool("instructions", False)
    hide_when_nothing_to_display = config.bool("hide", True)

    if show_instructions:
        return display_instructions(config)

    location = json.decode(config.get("location", default_location))

    rocket_launch_data = get_rocket_launch_json()

    initial_count = len(rocket_launch_data["result"]) if rocket_launch_data else 0

    rocket_launch_data = filter_rocket_launches(rocket_launch_data, config.get("filter_for_providers", ""), config.get("filter_for_countries", ""))

    rocket_launch_count = len(rocket_launch_data["result"]) if rocket_launch_data else 0

    if hide_when_nothing_to_display and rocket_launch_count == 0:
        return []

    row1 = ""
    row2 = ""
    row3 = ""
    row4 = ""

    if rocket_launch_data == None:
        row1 = "Failed to get data from Rocketlaunch.live feed"
    elif rocket_launch_count == 0:
        row1 = "All launches filtered.." if initial_count > 0 else "No upcoming launches.."
    else:
        rocket_launch_count = int(rocket_launch_count)
        for i in range(0, rocket_launch_count):
            localtime = time.now()
            locallaunch = time.parse_time(rocket_launch_data["result"][i]["t0"].replace("Z", ":00Z")).in_location(location["timezone"])

            if locallaunch > localtime.in_location(location["timezone"]):
                hours_notice = int(config.get("notice_period", 0))
                hours_until_sighting = (locallaunch - localtime.in_location(location["timezone"])).hours

                if (hours_notice == 0 or hours_notice > hours_until_sighting):
                    row1 = rocket_launch_data["result"][i]["vehicle"]["name"]
                    locallaunch = time.parse_time(rocket_launch_data["result"][i]["t0"].replace("Z", ":00Z")).in_location(location["timezone"])
                    row2 = locallaunch.format("Jan 2 '06")
                    row3 = get_launch_details(rocket_launch_data["result"][i], locallaunch)
                    row4 = replace_local_time_into_description(rocket_launch_data["result"][i]["launch_description"], locallaunch, time.parse_time(rocket_launch_data["result"][i]["t0"].replace("Z", ":00Z")))
                else:
                    return []
                break

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
                                            child = render.Text(row1, color = "#65d0e6"),
                                        ),
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(row2, color = "#FFFFFF"),
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
                                        render.Image(src = rocket_icon_f),
                                        render.Image(src = rocket_icon_g),
                                        render.Image(src = rocket_icon_f),
                                        render.Image(src = rocket_icon_d),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon_d),
                                        render.Image(src = rocket_icon_e),
                                        render.Image(src = rocket_icon_d),
                                        render.Image(src = rocket_icon_c),
                                        render.Image(src = rocket_icon_b),
                                        render.Image(src = rocket_icon),
                                        render.Image(src = rocket_icon),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(row1) * 5,
                    child = render.Text(row3, color = "#fff"),
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(row3) * 5,
                    child = render.Text(row4, color = "#ff0"),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to calculate local launch time.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "notice_period",
                name = "Notice Period",
                desc = "Display when launch is within...",
                icon = "userClock",
                options = period_options,
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Text(
                id = "filter_for_providers",
                name = "Only Show these providers",
                desc = "Comma Seperated List of Providers to Show",
                icon = "industry",
            ),
            schema.Text(
                id = "filter_for_countries",
                name = "Only Show these countries",
                desc = "Comma Seperated List of Countries to Show",
                icon = "globe",
            ),
            schema.Toggle(
                id = "hide",
                name = "Hide if no data?",
                desc = "",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",  #"info",
                default = False,
            ),
        ],
    )
