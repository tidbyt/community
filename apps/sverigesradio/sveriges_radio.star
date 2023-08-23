"""
Applet: Sveriges Radio
Summary: What's currently playing
Description: See what's currently playing on any of the Sveriges Radio channels.
Author: Sebastian Ekström
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SCHEDULE_URL = "https://api.sr.se/api/v2/scheduledepisodes?format=json&pagination=false&channelid="
NOW_PLAYING_URL = "https://api.sr.se/api/v2/playlists/rightnow?format=json&channelid="
ICON_SIZE = 18
PADDING = 2
TIDBYT_PX_WIDTH = 64
TEXT_WIDTH = TIDBYT_PX_WIDTH - ICON_SIZE - (PADDING * 2)

P1_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAMUSURBVHgBvZdNTBNBGIbfGTeKgqR64O9iwZ8EL61UjFET20BMPKC9epC2FxNPQDybgIln6MUDHtri3TR6MoFULsYYWwtHQmQ1UaL4U0qFUpcZZ5YWum1td0nhSbadnZ2Zd2a+mW++ITCBOxSzZRQ4wdltzombg9tFti3/OUUISRLwJCd0Nn7XEzXTJqklmFYwBMaGi4RqoYLS8GENkbcBjwqrwq5IbIiDjVoQLO8AwVhisC8Ms8I9U7FxMa3DqAOUYOL9YN9ITWEhGhKiftQRQhCOD/YFivNoieh4vUUlnMN/cWpm3NCZXdEZPzhC2E8IRoTNJ7aTgsuhmD1HWUwk7fLd1WZcT3+3GOZX0uhoakC7eKCPgmAxtYb0plZR4/hhBedONunphV8ZrOX0cinGaGcy4Ekp8i1H4SuIysYnb/QYGln4ncGdl+/wYyOHR1fP40LrbsdeLC5jcm4Jy3+yhjoPes9i4HS7nh54/qYgbKNUX7SjeRubs2tOjPxJ8qMh79aZdjy+1m3IuyRmrCBagSGn8A/U9WzaWxitGRLfUljXjNPraD2B3iLzPLzSXa0Jm6JoTsoZccMiq9lyu55qbtT/vWIGOpqOVq0v7Oylws86YBFSwe1oYs8cOURxz9GJmvXBr1POuRMWkJotxxrK8qUJpHBrY0PNNjiIXS4uS774ZlebdIMGns4v4XN6HRawKVZKO1uacd/Zpaez2pbY26uILnzBq08rsIoUTsHkqJPf0/qerAMpMWtcxQEjAwcqDD2LA0Ys6DnhwZipUKWeEMZfUw1KEtt2PijUeKA/SuVJAYZg8Zevmazh+bmxabrV0rryMcIi8lffkbrTpmwJe4+vzKIKd+kRg1X10yk/6jHsN0IjmY88d0KfREBGBjyIfYMHhUa48Fbm7l2R6bDYYj7UUxI88sHX7y/Oo6WF4nqBeo6cB0tFKwpLEr7+YWEPGY6q2Dti3bARva0KVL3CiNUuji/NL64kOzGZScEggzKhL9r/QGASV2jayynchFBH/gzfvbSBqOK6M0sZj0qHVE2wwD8TYD6bV3G8cAAAAABJRU5ErkJggg==
""")

P2_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAANPSURBVHgBvVfNS1RRFP+d2xSIWFPZtzRjn2CCUiERRRYUtFJ0IyZortqpf0CmRkRQ6CyrhWOkBqGMC9cqLmxRNhJRUOCM2cJMm8QP8GNu5935fO+N+mYc+8Gbue+cc8/v3Ln3nHuGYAGyBnasohASJfwUg+Dkb7tSEgL86VVPEEPUDY8Vn7Qp4TLq2Ko+SrQ5fPy4sQsd5Fbj5IhlpSJsSoIwUQDN1MVBWCWWd9DKhPVIBwht1IkGs9hM2s6kNUgnCG4mvxsvEgbS1rSTKseoUb51sUR0lYqwHdsJiQY+9W1RYj69Tj69Azx0ykOngZx8nT19HUCQdoLOXgkJVpYgJz9DzP5Qr0HHeVC2I2Y/NwV8G1FMBgT4tOfyaQ/Y1OsyqjVSNS4qB1U81gdafwJiehzSUQAqf4BIxBo5npWA/B8hL5ZClN2PTZr2QfY0gYY74l1p6akd2qbIHtfAAqi3GZifib3nnAO1vAMy7RA9jQgOv4oZH3CC7rkhb5uSo06rD0JWoTS62k0hIUf79aKsbNDV6lAgbxth+nnLWziwvfESVQUFl7liJAHiCaZwjuWFdDN+SP6JdfYZWZB5N/QTgigV7KkAW8XS31gQc79Narn7oF5AuKbtcSGSgLQfMclofDQ2ztxn1k99NziBUyRVi7UDk39TJ1p73weMdIf1DtDhkzCyYGLM6Mlug0XI/ccha1+AFmaB1WXAz84+9EEMvIzaBC9X6UuhNq/3Ief1L5M/m7pPLayaZiZAT26tqw/mXgCVNcYEiwEEPY8g+p8mMlcFxIck99kISVxOMvZAtpapZKKlOdDkJ4iFQOIJBK+NLYdSJZa1zwFHYdiXQRcNinWNl1gv45VjNt4UD+dVHVLB0TOgU0UbmqjSahQKDAreZW+4b/pf8NFreGzaTcFXoosFoer/5yfwZVBvurhOXP4xpAB1a0SuRTtWML6F/soqfLyt1+kNfCrttFWzoBnbj2aNVBtE8z3cGbiwfXDFd5yJmj2+RFGNdIK4x+7U3/nCZBMySOfKXUbShMSKvEu1J1o76kOqCJXihrCvBOoNICu4MxEq2lhPZo3QhUVu5D3r1weCRagWaY27FaEah0LDnzYtTYawg6vgPLwbEUbwDwytEF4Y7VeJAAAAAElFTkSuQmCC
""")

P3_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAARHSURBVHgBtVddTBxVFP7uMGwXuqULEUqhlLVKGsWk+JvWaEVTf56kjT/Ag2H75IsJ0Bb1TfpmKC3gkz40wJNZjClpo2mspqLxJ4K6CELb1DICC1haWGCRZX/m9twpO53ZXdrZZvkedu855977zbn3nDNnGCzAdabZGYkEKrgqVXHwSsa4i3M4hY0x+OnPCy55OdA3Vd3Sa2VPdi/CUCRQzzgaYkQWtlQg8S5bRO5Waj9W1p21nmFHT1M9eddsnTDxAeg0jvvePtGV1JpMWew51kbH1oA0gEFq91W3NCbq41DU09QJzt1IIxhjXeT5YaNOMgrC03STCnDas9jzfpvpYXTSniY3TejEBoLipXG6prVdJ3Z9/qErJEUvkslVllOAysLdpgWesQHYpUxUle7R5IgaxaXFGQzMKghzVdNts+dgX/4u5Gdt0eRrS7MYnJ/EjWDAuJXfZnM8qBxq9stCCsmROqhwifHjeTvRXPG6ifj85DAm/p/HzMoCPt33jq73Lc/jgz++xMXpy/gvuIjf5/7F2ZfeQ0FWjmYPhFdxpN+DryaHYkucoVBABG3z7TtWmRsWcG7iL4z6p3W5eHMuTj/rRgn9C0zQg3Re/Um3OzI3ofWpt7A1M8u4Tb2oD1KJ5+hBccSwiCH/pEnelCHjzdIndXnE8GACObYs7N9WZlQ5I8FAhaRyVCIF8CS6EkeePg5Gwwn2oBox78HYQQkS24MUwJLUnOsrS/q4KDux0F1amI4jxgvijiuQAnZuzkvQnR336uPXispNtpN/f6PdvRncJadSi0UQ7aWUMaJt+AJG1jx6d/d+vLrjMW0sIl6QepSBZFs5ZViEiMyGRw/g5+v/QGTuFQqir6eG8QvJMXx2+Qe8sr0cewt2aRF/6plqOvpctI1cSNhPFu9TK14vhFdwtP+Le03DuclBjTiGI+Uvw3PtN0wFF4zTqIBwKEjhnrdnbcXT+S5dpjKr5XcMomIZIZFnzxWWocdw5KTyEjHvo5Fl4ucpJ9voCGOIUsk0Eqs8MeFW41NMZYMS48xSqxLDt1OjplzOYBJyMu267HI8kLBmcM5cdCiPv5dke8S71jdZwlxoGS1D5026qpI7B3ag6BGT7RRFtrJ806BhiujLZOVQu7/Ic6yDNB8J9VW6o9NXfjQtXgwHTfIno9+hd/xPvFH6BJy2bDxMb7SHtuQjNzMb44Gb2vrZ1SX8Sm+v/htjprV0F90avfhxnWlwhsPy2P33V1bBFFXNeHGGmkDt7SS8puQ8jg0GI46Ztc5Tb3181BkwzjuwQaAg7vDV3uk4Eyo+9V1dFLV1SCdUdE/VtrqNKil+jq+61Z1Oz4Wn8aRJiTXympMNTGWHta+C+yW8XYobfTUnkvbnd/2EKaQmUELETXWvzmqXohFG0WGzO9pFU7fuPFiEaJFULlXSd5FoHCpMH22i3nPWR1fUK9sd3rsRxnALkQ+z5mkWFZ8AAAAASUVORK5CYII=
""")

P4_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAPpSURBVHgBvVZNbFtFEP52/eKYFKgJVCoosZxGIBpFYBR6qJSa5kbFoYFD01CJuDfEXxIOSAghmgMHOEAiekBCog4Sos6F9MKFgmmKqFQkMD9tVRK1r880CgUq9yepEz/vdva5fs7GjvMcOf0kW29nZ+fb2ZmdHQYP+DX8dfAm7AgTYq8EdgMsDMhgYZZlwJBiUqaExIloum/Si022JqGwB4lkqES0pkFTgscNbo/vNPvNKnqVcTI0QYQ45JWw0gaEZCPR9L74KvPlmAolPqaJIdQBZGe02+obriBfSTpxhEHGUEcwsHi3te/gchnXSZWn9SVVkGTzR7INbTNF0taJGGPyCDYQtIHhqLV/1CU+Ff4qnBc8SVcl7AgDPkfNhX3n2yhFRmbF6gwNdLi+FVEkG9KWGZv723rM5zOGIxPGACDCRZ0dp56Dvzngrjn/5mn8d+wS2t5+Ao/EHnNkucwS5o7O4NIHf9LSkn3W5EPXt3sQaGlyZYv/3sLvvd9j8e/5oCGWVNIe4gW3RQxV4ewW1kdnkF+wC04F/Wh9uQNt70Q0zdbXtmukCunD5xRpcTiYpPrAp1oTvcUjXgv2tRzmp69psodfanczJdB+L0KvdmjzWWsec1/MLBcFDWQjnBJqN2pA7kpWG3O/D0Zzo/P96Ic7yvT/eDGphcKBYL0cjD+JGlCWNMpONo+tB7Zh89NbNPnlz//CYnqh3AZjz6gYR1ADfMEGbZyl2DXc70fLK9vL5OlPzlW0ISXCnP491+JGSprNTz3kjkVOYObdX9Dy+uOUUJs0XWv0DBoebMSmzgfAneupIWjAI/g9PoTe6oR9w6YkW8LV5CzmvrwAO2uj88AuTXfumOnEtev4s8o//Nz9DR35vKZj0IFnvHgtbuUx/cZpTC+TSQp313d7dD2K9+yn59HxWXc1cxl11CbWia3929DUfp8msw6fxZa9obKj18BYio5anqCvmhKsCHshh4vvp9yxyEn8c/QCdp59ofpCKX4zwOUk3atBrAP/T6bLZEazn24oq87L2Q/cRiDlxPkugTGYUbNv0lAvxclQYoxk7xUnMz9dgREoJLx6lxYvL3g2LPMCV4/Plsb0s68vlcZSjDsbUH+qaBsyd7GWO70eKG9zTPT0UBPovE7Ka9rJCDYYgomRnjudp9v6FDoDOYYNgxyLmv3x4qhCs5eIk3AA9aSEGI9a/bHlMr5SKWr1xerrOXm6grQiscIua/8QxfygSgasF3RFqWMdVrYqTldbm6Qm0BCg7pMPqKcMHgnpTo3ZPDCqknZVNXjEVDjRywR1K4XGIeJePaf4UL2XVHqpCqqCVI2wiNt1wYXcpK13tgAAAABJRU5ErkJggg==
""")

def get_current_unix_time():
    return time.now().unix * 1000

def get_current_show_name(url):
    response = fetch_data(url)
    schedule_data = response["schedule"]
    current_time = get_current_unix_time()

    for episode in schedule_data:
        start_time = int(episode["starttimeutc"].replace("/Date(", "").replace(")/", ""))
        end_time = int(episode["endtimeutc"].replace("/Date(", "").replace(")/", ""))
        if start_time <= current_time and current_time <= end_time:
            return episode

    return None

def get_station_icon(station):
    if station == "132":
        return P1_ICON
    elif station == "163":
        return P2_ICON
    elif station == "164":
        return P3_ICON
    else:
        return P4_ICON

def fetch_data(url):
    cached_data = cache.get("sr-url=%s" % url)
    if cached_data != None:
        print("Hit! Using cached 'Sveriges Radio' data for", url)
        data = json.decode(cached_data)
    else:
        print("Miss! Fetching 'Sveriges Radio' data for", url)
        assets_resp = http.get(url)
        if (assets_resp.status_code != 200):
            fail("'Sveriges Radio' request failed with status", assets_resp.status_code)

        data = assets_resp.json()
        cache.set("sr-url=%s" % url, json.encode(data), ttl_seconds = 10)

    return data

def get_currently_playing(now_playing_data, station_selection):
    currently_playing = now_playing_data["playlist"]
    current_song = currently_playing.get("song")
    song_is_playing = current_song != None

    if song_is_playing:
        title = current_song["artist"]
        subtitle = current_song["title"]
    else:
        # If a song isn't playing, display the name of the show instead
        station_schedule_url = SCHEDULE_URL + station_selection
        current_episode = get_current_show_name(station_schedule_url)
        if current_episode == None:
            title = "Could not find"
            subtitle = "show information"
        title = current_episode.get("title") or "Now playing"
        subtitle = current_episode.get("subtitle") or current_episode.get("description")

    return title, subtitle

def main(config):
    station_selection = config.get("station", "132")
    station_now_playing = NOW_PLAYING_URL + station_selection
    station_image = get_station_icon(station_selection)

    response = fetch_data(station_now_playing)
    title, subtitle = get_currently_playing(response, station_selection)

    return render.Root(
        child = render.Box(
            padding = PADDING,
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Box(
                                width = ICON_SIZE,
                                height = ICON_SIZE,
                                child = render.Image(
                                    src = station_image,
                                    width = ICON_SIZE,
                                    height = ICON_SIZE,
                                ),
                            ),
                            render.Box(
                                child = render.Column(
                                    children = [
                                        render.Marquee(
                                            child = render.Text(
                                                content = " %s" % title,
                                                font = "5x8",
                                            ),
                                            width = TEXT_WIDTH,
                                        ),
                                        render.Marquee(
                                            child = render.Text(
                                                content = " %s" % subtitle,
                                                font = "5x8",
                                            ),
                                            width = TEXT_WIDTH,
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Choose the station",
                desc = "Choose the station",
                icon = "radio",
                default = StationOptions[0].value,
                options = StationOptions,
            ),
        ],
    )

StationOptions = [
    schema.Option(
        display = "P1",
        value = "132",
    ),
    schema.Option(
        display = "P2",
        value = "163",
    ),
    schema.Option(
        display = "P3",
        value = "164",
    ),
    schema.Option(
        display = "P4",
        value = "701",
    ),
]
