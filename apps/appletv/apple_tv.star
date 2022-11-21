"""
Applet: Apple TV
Summary: Apple TV \"Now Playing\"
Description: Shows Apple TV \"Now Playing\" on Tidbyt.
Author: tjmehta
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("schema.star", "schema")

THUMBNAIL_WIDTH = 22

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apple_tv_mac_address",
                name = "Apple TV MAC Address",
                desc = "Check your Apple TV network settings. Ex: a1:b2:c3:d4:e1:f2",
                icon = "networkWired",
            ),
            schema.Text(
                id = "apple_tv_now_playing_api_host",
                name = "Apple TV Now Playing API Host",
                desc = "This widget requires a local server running locally on your network (https://github.com/tjmehta/apple-tv-now-playing-server)",
                icon = "server",
            ),
        ],
    )

def main(config):
    apple_tv_mac_address = config.get("apple_tv_mac_address") or "58:D3:49:F2:CB:36"
    if not apple_tv_mac_address:
        return render_error("config missing: apple_tv_mac_address is required")

    apple_tv_now_playing_api_host = config.get("apple_tv_now_playing_api_host") or "http://nas.local:5005"
    if not apple_tv_now_playing_api_host:
        return render_error("config missing: apple_tv_now_playing_api_host is required")

    url = get_api_url(apple_tv_now_playing_api_host, "playing")
    params = {"mac": apple_tv_mac_address, "width": str(THUMBNAIL_WIDTH)}
    resp = http.get(url, params = params)
    json = resp.json()

    if not resp.status_code == 200:
        msg = json["message"] if "message" in json else "unknown"
        return render_error("api error (" + str(resp.status_code) + "):" + msg)

    if json["device_state"] == "DeviceState.Idle":
        # just render clock
        return render_clock_when_idle(config)

    if json["artist"] and "artwork" in json:
        return render_now_playing_full(json)
    else:
        return render_now_playing_half(json)

def get_api_url(host, path):
    return host + "/" + path

def render_now_playing_full(json):
    title = json["title"]
    artist = json["artist"] or ""
    album = json["album"] or ""
    thumbnail = base64.decode(json["artwork"]["bytes"]) if json["artwork"] else ""
    return render.Root(
        render.Column(
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
            children = [
                render.Row(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Marquee(
                            height = 6,
                            width = 64,
                            child = render.Text(
                                color = "#0FFD00",
                                content = title,
                                font = "tb-8",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    main_align = "start",
                    cross_align = "left",
                    expanded = True,
                    children = [
                        render.Column(
                            main_align = "space_around",
                            cross_align = "left",
                            expanded = True,
                            children = [
                                render.Box(
                                    height = THUMBNAIL_WIDTH,
                                    width = THUMBNAIL_WIDTH,
                                    child = render.Image(
                                        src = thumbnail,
                                        height = THUMBNAIL_WIDTH,
                                        width = THUMBNAIL_WIDTH,
                                    ),
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "left",
                            expanded = True,
                            children = [
                                render.Box(
                                    height = 1,
                                    width = 1,
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "left",
                            expanded = True,
                            children = [
                                render.Row(
                                    main_align = "start",
                                    cross_align = "left",
                                    expanded = True,
                                    children = [
                                        render.Marquee(
                                            height = 6,
                                            width = 64 - THUMBNAIL_WIDTH,
                                            child = render.Text(
                                                content = artist,
                                                font = "tb-8",
                                            ),
                                        ),
                                    ],
                                ),
                                render.Row(
                                    main_align = "start",
                                    cross_align = "left",
                                    expanded = True,
                                    children = [
                                        render.Marquee(
                                            height = 6,
                                            width = 64 - THUMBNAIL_WIDTH,
                                            child = render.Text(
                                                content = album,
                                                font = "tom-thumb",
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def render_now_playing_half(json):
    if json["artist"]:
        show = json["artist"]
        episode = json["title"]
    else:
        split = json["title"].split(" | ")
        if len(split) > 1:
            show = split[0]
            episode = " | ".join(split[1::])
        else:
            show = None
            episode = json["title"]

    return render.Root(
        render.Column(
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
            children = [
                render.Row(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Marquee(
                            height = 13,
                            width = 64,
                            child = render.Text(
                                content = show,
                                font = "6x13",
                            ),
                        ),
                    ],
                ) if show else None,
                render.Row(
                    main_align = "start",
                    cross_align = "left",
                    expanded = True,
                    children = [
                        render.Marquee(
                            height = 6,
                            width = 64,
                            child = render.Text(
                                content = episode,
                                font = "tb-8",
                            ),
                        ),
                    ],
                ) if episode else None,
            ],
        ),
    )

def render_clock_when_idle(config):
    timezone = config.get("timezone") or "America/Los_Angeles"
    now = time.now().in_location(timezone)

    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Text(
                        content = now.format("3:04 PM"),
                        font = "6x13",
                    ),
                    render.Text(
                        content = now.format("3 04 PM"),
                        font = "6x13",
                    ),
                ],
            ),
        ),
    )

def render_error(msg):
    return render.Root(
        render.Row(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Box(
                    height = 32,
                    width = 64,
                    child = render.Marquee(
                        height = 13,
                        width = 36,
                        child = render.Text(
                            content = msg,
                            font = "6x13",
                        ),
                    ),
                ),
            ],
        ),
    )
