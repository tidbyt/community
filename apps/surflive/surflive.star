"""
Applet: Surflive
Summary: Live surf conditions
Description: Shows the current surf conditions for a surf spot.
Author: rcarton
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#### CONFIG THINGS

# DISPLAY
WIDTH = 64
HEIGHT = 32

WAVE_ICON = base64.decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAJCAYAAAALpr0TAAAABGdBTUEAALGPC/xhBQAACklpQ0NQc1JHQiBJRUM2MTk2Ni0yLjEAAEiJnVN3WJP3Fj7f92UPVkLY8LGXbIEAIiOsCMgQWaIQkgBhhBASQMWFiApWFBURnEhVxILVCkidiOKgKLhnQYqIWotVXDjuH9yntX167+3t+9f7vOec5/zOec8PgBESJpHmomoAOVKFPDrYH49PSMTJvYACFUjgBCAQ5svCZwXFAADwA3l4fnSwP/wBr28AAgBw1S4kEsfh/4O6UCZXACCRAOAiEucLAZBSAMguVMgUAMgYALBTs2QKAJQAAGx5fEIiAKoNAOz0ST4FANipk9wXANiiHKkIAI0BAJkoRyQCQLsAYFWBUiwCwMIAoKxAIi4EwK4BgFm2MkcCgL0FAHaOWJAPQGAAgJlCLMwAIDgCAEMeE80DIEwDoDDSv+CpX3CFuEgBAMDLlc2XS9IzFLiV0Bp38vDg4iHiwmyxQmEXKRBmCeQinJebIxNI5wNMzgwAABr50cH+OD+Q5+bk4eZm52zv9MWi/mvwbyI+IfHf/ryMAgQAEE7P79pf5eXWA3DHAbB1v2upWwDaVgBo3/ldM9sJoFoK0Hr5i3k4/EAenqFQyDwdHAoLC+0lYqG9MOOLPv8z4W/gi372/EAe/tt68ABxmkCZrcCjg/1xYW52rlKO58sEQjFu9+cj/seFf/2OKdHiNLFcLBWK8ViJuFAiTcd5uVKRRCHJleIS6X8y8R+W/QmTdw0ArIZPwE62B7XLbMB+7gECiw5Y0nYAQH7zLYwaC5EAEGc0Mnn3AACTv/mPQCsBAM2XpOMAALzoGFyolBdMxggAAESggSqwQQcMwRSswA6cwR28wBcCYQZEQAwkwDwQQgbkgBwKoRiWQRlUwDrYBLWwAxqgEZrhELTBMTgN5+ASXIHrcBcGYBiewhi8hgkEQcgIE2EhOogRYo7YIs4IF5mOBCJhSDSSgKQg6YgUUSLFyHKkAqlCapFdSCPyLXIUOY1cQPqQ28ggMor8irxHMZSBslED1AJ1QLmoHxqKxqBz0XQ0D12AlqJr0Rq0Hj2AtqKn0UvodXQAfYqOY4DRMQ5mjNlhXIyHRWCJWBomxxZj5Vg1Vo81Yx1YN3YVG8CeYe8IJAKLgBPsCF6EEMJsgpCQR1hMWEOoJewjtBK6CFcJg4Qxwicik6hPtCV6EvnEeGI6sZBYRqwm7iEeIZ4lXicOE1+TSCQOyZLkTgohJZAySQtJa0jbSC2kU6Q+0hBpnEwm65Btyd7kCLKArCCXkbeQD5BPkvvJw+S3FDrFiOJMCaIkUqSUEko1ZT/lBKWfMkKZoKpRzame1AiqiDqfWkltoHZQL1OHqRM0dZolzZsWQ8ukLaPV0JppZ2n3aC/pdLoJ3YMeRZfQl9Jr6Afp5+mD9HcMDYYNg8dIYigZaxl7GacYtxkvmUymBdOXmchUMNcyG5lnmA+Yb1VYKvYqfBWRyhKVOpVWlX6V56pUVXNVP9V5qgtUq1UPq15WfaZGVbNQ46kJ1Bar1akdVbupNq7OUndSj1DPUV+jvl/9gvpjDbKGhUaghkijVGO3xhmNIRbGMmXxWELWclYD6yxrmE1iW7L57Ex2Bfsbdi97TFNDc6pmrGaRZp3mcc0BDsax4PA52ZxKziHODc57LQMtPy2x1mqtZq1+rTfaetq+2mLtcu0W7eva73VwnUCdLJ31Om0693UJuja6UbqFutt1z+o+02PreekJ9cr1Dund0Uf1bfSj9Rfq79bv0R83MDQINpAZbDE4Y/DMkGPoa5hpuNHwhOGoEctoupHEaKPRSaMnuCbuh2fjNXgXPmasbxxirDTeZdxrPGFiaTLbpMSkxeS+Kc2Ua5pmutG003TMzMgs3KzYrMnsjjnVnGueYb7ZvNv8jYWlRZzFSos2i8eW2pZ8ywWWTZb3rJhWPlZ5VvVW16xJ1lzrLOtt1ldsUBtXmwybOpvLtqitm63Edptt3xTiFI8p0in1U27aMez87ArsmuwG7Tn2YfYl9m32zx3MHBId1jt0O3xydHXMdmxwvOuk4TTDqcSpw+lXZxtnoXOd8zUXpkuQyxKXdpcXU22niqdun3rLleUa7rrStdP1o5u7m9yt2W3U3cw9xX2r+00umxvJXcM970H08PdY4nHM452nm6fC85DnL152Xlle+70eT7OcJp7WMG3I28Rb4L3Le2A6Pj1l+s7pAz7GPgKfep+Hvqa+It89viN+1n6Zfgf8nvs7+sv9j/i/4XnyFvFOBWABwQHlAb2BGoGzA2sDHwSZBKUHNQWNBbsGLww+FUIMCQ1ZH3KTb8AX8hv5YzPcZyya0RXKCJ0VWhv6MMwmTB7WEY6GzwjfEH5vpvlM6cy2CIjgR2yIuB9pGZkX+X0UKSoyqi7qUbRTdHF09yzWrORZ+2e9jvGPqYy5O9tqtnJ2Z6xqbFJsY+ybuIC4qriBeIf4RfGXEnQTJAntieTE2MQ9ieNzAudsmjOc5JpUlnRjruXcorkX5unOy553PFk1WZB8OIWYEpeyP+WDIEJQLxhP5aduTR0T8oSbhU9FvqKNolGxt7hKPJLmnVaV9jjdO31D+miGT0Z1xjMJT1IreZEZkrkj801WRNberM/ZcdktOZSclJyjUg1plrQr1zC3KLdPZisrkw3keeZtyhuTh8r35CP5c/PbFWyFTNGjtFKuUA4WTC+oK3hbGFt4uEi9SFrUM99m/ur5IwuCFny9kLBQuLCz2Lh4WfHgIr9FuxYji1MXdy4xXVK6ZHhp8NJ9y2jLspb9UOJYUlXyannc8o5Sg9KlpUMrglc0lamUycturvRauWMVYZVkVe9ql9VbVn8qF5VfrHCsqK74sEa45uJXTl/VfPV5bdra3kq3yu3rSOuk626s91m/r0q9akHV0IbwDa0b8Y3lG19tSt50oXpq9Y7NtM3KzQM1YTXtW8y2rNvyoTaj9nqdf13LVv2tq7e+2Sba1r/dd3vzDoMdFTve75TsvLUreFdrvUV99W7S7oLdjxpiG7q/5n7duEd3T8Wej3ulewf2Re/ranRvbNyvv7+yCW1SNo0eSDpw5ZuAb9qb7Zp3tXBaKg7CQeXBJ9+mfHvjUOihzsPcw83fmX+39QjrSHkr0jq/dawto22gPaG97+iMo50dXh1Hvrf/fu8x42N1xzWPV56gnSg98fnkgpPjp2Snnp1OPz3Umdx590z8mWtdUV29Z0PPnj8XdO5Mt1/3yfPe549d8Lxw9CL3Ytslt0utPa49R35w/eFIr1tv62X3y+1XPK509E3rO9Hv03/6asDVc9f41y5dn3m978bsG7duJt0cuCW69fh29u0XdwruTNxdeo94r/y+2v3qB/oP6n+0/rFlwG3g+GDAYM/DWQ/vDgmHnv6U/9OH4dJHzEfVI0YjjY+dHx8bDRq98mTOk+GnsqcTz8p+Vv9563Or59/94vtLz1j82PAL+YvPv655qfNy76uprzrHI8cfvM55PfGm/K3O233vuO+638e9H5ko/ED+UPPR+mPHp9BP9z7nfP78L/eE8/stRzjPAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAJcEhZcwAAAMUAAADFAR3NuqgAAACPSURBVBiVdc6xCQJBEAXQdyaioGhiZiooGJ0FmBqbaRcWYGIBYmgHZxUGphddZA/agChisgfLsS4M/Jl5DJvleSnxlriGvEHRSqA2LlF/xjAFHxiFvEMftyYco4cP9jiG+TyGM1QhVzhEu28MTxgkvgJquMbiH6rhCkXj2hR3bOtBluflG69Q8YEunuhg8gNcGBVcSWjadwAAAABJRU5ErkJggg==",
)
WAVE_ICON_WIDTH = 10

WIND_ICON = base64.decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAHCAYAAADam2dgAAAACXBIWXMAAADFAAAAxQEdzbqoAAAJVWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuYjBmOGJlOSwgMjAyMS8xMi8wOC0xOToxMToyMiAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdEV2dD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlRXZlbnQjIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCAyMy4yIChXaW5kb3dzKSIgeG1wOkNyZWF0ZURhdGU9IjIwMjItMDItMjRUMTg6NDk6MzUtMDg6MDAiIHhtcDpNZXRhZGF0YURhdGU9IjIwMjItMDItMjRUMTk6MTE6NDItMDg6MDAiIHhtcDpNb2RpZnlEYXRlPSIyMDIyLTAyLTI0VDE5OjExOjQyLTA4OjAwIiBkYzpmb3JtYXQ9ImltYWdlL3BuZyIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpiZjk2ZDZkYS01OTMwLTUwNDktOTEyMC0yYjlkZWNlMmFiMDEiIHhtcE1NOkRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDo5NmUwNDlmYy04MWUzLTMyNDktYjQ0My1hNTQ3NWNjYjgyMjkiIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDozNDU1MTY0Mi01YTI1LWI5NDAtOWNlNy0yY2FlOTJlNWJjMmYiIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjM0NTUxNjQyLTVhMjUtYjk0MC05Y2U3LTJjYWU5MmU1YmMyZiIgc3RFdnQ6d2hlbj0iMjAyMi0wMi0yNFQxODo0OTozNS0wODowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIzLjIgKFdpbmRvd3MpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDowZDQ5NTljMy1lNTU2LWI3NDYtOThjYy0yOTg5Mzc2ODJmMTciIHN0RXZ0OndoZW49IjIwMjItMDItMjRUMTg6NDk6NDItMDg6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMy4yIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY29udmVydGVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJkZXJpdmVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJjb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6YzQyMTM5MWUtYzFiNi0wMTQ2LThhYzUtMmExZWViMmYxNGUzIiBzdEV2dDp3aGVuPSIyMDIyLTAyLTI0VDE4OjQ5OjQyLTA4OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjMuMiAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmJmOTZkNmRhLTU5MzAtNTA0OS05MTIwLTJiOWRlY2UyYWIwMSIgc3RFdnQ6d2hlbj0iMjAyMi0wMi0yNFQxOToxMTo0Mi0wODowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIzLjIgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDowZDQ5NTljMy1lNTU2LWI3NDYtOThjYy0yOTg5Mzc2ODJmMTciIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6MzQ1NTE2NDItNWEyNS1iOTQwLTljZTctMmNhZTkyZTViYzJmIiBzdFJlZjpvcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6MzQ1NTE2NDItNWEyNS1iOTQwLTljZTctMmNhZTkyZTViYzJmIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+aKBFngAAADVJREFUGBlj+P//PwM6Xrly5X8ghvNxKkBWiE0RMgYrxKcIZiIDjIMNwxWjG4/dOjwmwU0DAPuIpNqXRUF9AAAAAElFTkSuQmCC",
)
WIND_ICON_WIDTH = 9

# FORECAST API
SURFLINE_FORECASTS_URL = "https://services.surfline.com/kbyg/spots/forecasts"
SEARCH_URL = "https://services.surfline.com/onboarding/spots?query={query}&limit=12&offset=0&camsOnly=false"

# 15 minutes
ENABLE_CACHE = True
CACHE_TTL_SECONDS = 60 * 15

# DEFAULTS
DEFAULT_SPOT_NAME = "Pacific Beach"
DEFAULT_SPOT_ID = "5842041f4e65fad6a7708841"

####

def main(config):
    if config.get("spot"):
        spot = json.decode(config.get("spot"))
        spot_name = spot["display"]
        spot_id = spot["value"]
    else:
        spot_name = DEFAULT_SPOT_NAME
        spot_id = DEFAULT_SPOT_ID

    if config.get("spot_name"):
        spot_name = config.get("spot_name")

    use_wave_height = (config.get("use_wave_height") == "true")

    conditions = get_conditions(spot_id)

    print("spot_name={} conditions={}".format(spot_name, json.encode(conditions)))

    if conditions != None:
        top_level = [
            render_spot_name(spot_name),
            render_surf_and_period(conditions["wave"], use_wave_height),
            render_wind(conditions["wind"]),
        ]
    else:
        top_level = [
            render_spot_name(spot_name),
            render.Row(expanded = True, main_align = "center", children = [render.Text(content = "ERROR", color = "#f00")]),
        ]

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = top_level,
        ),
    )

def render_spot_name(spot_name):
    return render.Row(expanded = True, main_align = "center", children = [render.Text(content = spot_name)])

def render_surf_and_period(wave, use_wave_height):
    if use_wave_height:
        content = "{min}-{max}{wave_height_unit} @ {period}s".format(**wave)
    else:
        content = "{swell_height}{wave_height_unit} @ {period}s".format(**wave)

    if size_str(content) >= WIDTH - WAVE_ICON_WIDTH - 1:
        render_content = render.Marquee(
            width = WIDTH - WAVE_ICON_WIDTH - 1,
            child = render.Text(content = content),
        )
    else:
        render_content = render.Text(content = content)

    row = render.Row(
        cross_align = "center",
        main_align = "center",
        expanded = True,
        children = [
            render.Padding(pad = (0, 0, 1, 0), child = render.Image(src = WAVE_ICON)),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render_content,
            ),
        ],
    )

    return render.Padding(
        pad = (0, 2, 0, 0),
        child = row,
    )

def render_wind(wind):
    row = render.Row(
        cross_align = "center",
        main_align = "center",
        expanded = True,
        children = [
            render.Padding(pad = (0, 0, 2, 0), child = render.Image(src = WIND_ICON)),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Text(
                    content = "{direction} {speed}kts".format(**wind),
                ),
            ),
        ],
    )

    return render.Padding(
        pad = (0, 2, 0, 0),
        child = row,
    )

def size_str(s):
    """Return the size in pixels for a given string. This depends on the font used."""
    return len(s) * 5

def get_cache_name(key):
    return "SURFLIVE_{key}".format(key = key)

def get_conditions(spot_id):
    cache_key = get_cache_name("conditions_{spot_id}".format(spot_id = spot_id))
    cached_conditions = cache.get(cache_key)

    if ENABLE_CACHE and cached_conditions != None:
        print("Using cached conditions, key={cache_key}".format(cache_key = cache_key))
        return json.decode(cached_conditions)

    wave = get_wave_forecast(spot_id)
    wind = get_wind_forecast(spot_id)

    if wave == None or wind == None:
        return None

    conditions = {
        "wave": wave,
        "wind": get_wind_forecast(spot_id),
    }

    cache.set(cache_key, json.encode(conditions), ttl_seconds = CACHE_TTL_SECONDS)
    return conditions

def get_wave_forecast(spot_id):
    wf = get_forecast("wave", spot_id)

    if wf == None:
        return None

    units = wf["units"]
    surf = wf["wave"]["surf"]

    # Find the dominant swells
    # Remove any height=0 swells, not sure why the forecast has these
    swells = [s for s in wf["wave"]["swells"] if s["height"]]

    if len(swells) == 0:
        dominant_swell = {
            "height": 0,
            "period": 0,
        }
    else:
        # Sort by optimalScore
        dominant_swell = sorted(swells, key = lambda s: -s["optimalScore"])[0]

    # Round to the first digit
    swell_height = math.round(dominant_swell["height"]) + math.round((dominant_swell["height"] - math.round(dominant_swell["height"])) * 10) / 10

    return dict(
        ts = int(math.round(wf["wave"]["timestamp"])),
        period = int(math.round(dominant_swell["period"])),
        min = int(math.round(surf["min"])),
        max = int(math.round(surf["max"])),
        swell_height = swell_height,
        wave_height_unit = units["waveHeight"].lower(),
    )

def get_wind_forecast(spot_id):
    wf = get_forecast("wind", spot_id)

    if wf == None:
        return None

    units = wf["units"]
    wind = wf["wind"]

    return {
        "ts": int(math.round(wind["timestamp"])),
        "score": wind["optimalScore"],
        "unit": units["windSpeed"].lower(),
        "speed": int(math.round(wind["speed"])),
        "direction": direction_to_human(wind["direction"]),
        "direction_deg": wind["direction"],
    }

def direction_to_human(num):
    """Convert a compass angle to a human wind or swell direction."""
    val = int((num / 22.5) + 0.5)
    arr = [
        "N",
        "NNE",
        "NE",
        "ENE",
        "E",
        "ESE",
        "SE",
        "SSE",
        "S",
        "SSW",
        "SW",
        "WSW",
        "W",
        "WNW",
        "NW",
        "NNW",
    ]
    return arr[(val % 16)]

def get_forecast(f_type, spot_id):
    """Return the forecast for a given type"""

    url = "{base_url}/{f_type}?spotId={spot_id}&intervalHours=1&days=2".format(
        base_url = SURFLINE_FORECASTS_URL,
        f_type = f_type,
        spot_id = spot_id,
    )
    r = http.get(url)

    if r.status_code != 200:
        print("Error fetching {f_type} forecast for spot_id={spot_id}".format(f_type = f_type, spot_id = spot_id))
        return None

    data = r.json()
    units = data["associated"]["units"]
    forecast = get_closest_forecast(data["data"][f_type])

    return {
        "units": units,
        f_type: forecast,
    }

def get_closest_forecast(forecasts):
    """Go through the forecasts until we find the closest timestamp."""

    ts_now = time.now().unix
    last_wf = None
    curr_min = None
    for wf in forecasts:
        ts = wf["timestamp"]
        ts_diff = math.fabs(ts_now - ts)
        if curr_min != None and ts_diff > curr_min:
            return last_wf
        curr_min = ts_diff
        last_wf = wf
    fail("No forecast found")

def search_spots(query):
    """Return a list of spots queried by name"""
    if len(query) < 3:
        return []

    url = SEARCH_URL.format(
        query = query,
    )

    r = http.get(url)

    if r.status_code != 200:
        fail("Error fetching spots, query={query}".format(query = query))

    return r.json()["spots"]

def search_handler(query):
    spots = search_spots(query)
    return [schema.Option(display = s["name"], value = s["_id"]) for s in spots]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "spot",
                name = "Spot Name",
                desc = "Spot Name in Surfline",
                icon = "compass",
                handler = search_handler,
            ),
            schema.Text(
                id = "spot_name",
                name = "Display Name",
                icon = "compass",
                desc = "Optional spot name to display",
                default = "",
            ),
            schema.Toggle(
                id = "use_wave_height",
                name = "Display Surf Height",
                desc = "Display the surf or swell height (off=swell)",
                icon = "gear",
                default = False,
            ),
        ],
    )
