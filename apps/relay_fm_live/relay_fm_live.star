"""
Applet: Relay FM Live
Summary: Relay FM Live
Description: Shows live stream information for the Relay FM podcast network.
Author: radiocolin
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

relay_logo = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB0AAAAdCAIAAADZ8fBYAAAAmmVYSWZNTQAqAAAACAAGARIAAwAAAAEAAQAAARoABQAAAAEAAABWARsABQAAAAEAAABeASgAAwAAAAEAAgAAATEAAgAAABUAAABmh2kABAAAAAEAAAB8AAAAAAAAAEgAAAABAAAASAAAAAFQaXhlbG1hdG9yIFBybyAzLjMuMwAAAAKgAgAEAAAAAQAAAB2gAwAEAAAAAQAAAB0AAAAALh+MuQAAAAlwSFlzAAALEwAACxMBAJqcGAAACQVpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6UGl4ZWxtYXRvclRlYW09Imh0dHA6Ly93d3cucGl4ZWxtYXRvci5jb20veG1wLzEuMC9uYW1lc3BhY2UiCiAgICAgICAgICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIj4KICAgICAgICAgPFBpeGVsbWF0b3JUZWFtOlNpZGVjYXJEYXRhVmVyc2lvbj4xPC9QaXhlbG1hdG9yVGVhbTpTaWRlY2FyRGF0YVZlcnNpb24+CiAgICAgICAgIDxQaXhlbG1hdG9yVGVhbTpTaWRlY2FyV3JpdGVyQXBwbGljYXRpb24+cGl4ZWxtYXRvclBybzwvUGl4ZWxtYXRvclRlYW06U2lkZWNhcldyaXRlckFwcGxpY2F0aW9uPgogICAgICAgICA8UGl4ZWxtYXRvclRlYW06U2lkZWNhcldyaXRlckRldmljZT5NYWNCb29rQWlyMTAsMTwvUGl4ZWxtYXRvclRlYW06U2lkZWNhcldyaXRlckRldmljZT4KICAgICAgICAgPFBpeGVsbWF0b3JUZWFtOlNpZGVjYXJXcml0ZXJPUz4xMy4zLjE8L1BpeGVsbWF0b3JUZWFtOlNpZGVjYXJXcml0ZXJPUz4KICAgICAgICAgPFBpeGVsbWF0b3JUZWFtOlNpZGVjYXJFbmFibGVkPlRydWU8L1BpeGVsbWF0b3JUZWFtOlNpZGVjYXJFbmFibGVkPgogICAgICAgICA8UGl4ZWxtYXRvclRlYW06U2lkZWNhclVUST5jb20ucGl4ZWxtYXRvcnRlYW0ucGl4ZWxtYXRvci5kb2N1bWVudC1wcm8tc2lkZWNhci5iaW5hcnk8L1BpeGVsbWF0b3JUZWFtOlNpZGVjYXJVVEk+CiAgICAgICAgIDxQaXhlbG1hdG9yVGVhbTpTaWRlY2FyV3JpdGVyUGxhdGZvcm0+bWFjT1M8L1BpeGVsbWF0b3JUZWFtOlNpZGVjYXJXcml0ZXJQbGF0Zm9ybT4KICAgICAgICAgPFBpeGVsbWF0b3JUZWFtOlNpZGVjYXJWZXJzaW9uPjI8L1BpeGVsbWF0b3JUZWFtOlNpZGVjYXJWZXJzaW9uPgogICAgICAgICA8UGl4ZWxtYXRvclRlYW06U2lkZWNhcldyaXRlckJ1aWxkPmMyMWE1Zjg8L1BpeGVsbWF0b3JUZWFtOlNpZGVjYXJXcml0ZXJCdWlsZD4KICAgICAgICAgPFBpeGVsbWF0b3JUZWFtOlNpZGVjYXJJZGVudGlmaWVyPjMyMTMyNEFELTg0RkUtNDZFNi1CMzY1LThEOUQyQ0VGQUU5RjwvUGl4ZWxtYXRvclRlYW06U2lkZWNhcklkZW50aWZpZXI+CiAgICAgICAgIDxQaXhlbG1hdG9yVGVhbTpTaWRlY2FyTG9jYXRpb24+aUNsb3VkPC9QaXhlbG1hdG9yVGVhbTpTaWRlY2FyTG9jYXRpb24+CiAgICAgICAgIDxQaXhlbG1hdG9yVGVhbTpTaWRlY2FyQmFzZUZpbGVuYW1lPmFwcGxlLXRvdWNoLWljb24tMGVhNjg5NjYxODAzNDcxYTgyOGUwZTFmZjY3OTZhODBiMmJkNDJkZWZkZWY4MDBhNzc2ODJlZmZlMTUwMzU4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")
live_status_url = "https://www.relay.fm/live.json"
live_page_url = "https://www.relay.fm/live"
live_broadcasts_url = "https://www.relay.fm/addtobroadcasts"
live_discord_url = "https://discord.com/channels/620638957960691723/707667851745427666"
live_m3u_url = "http://stream.relay.fm:8000/stream.m3u"

def generate_qrcode(url):
    code = qrcode.generate(
        url = url,
        size = "large",
        color = "#fff",
        background = "#000",
    )
    return render.Image(src = code)

def check_live():
    r = http.get(live_status_url, ttl_seconds = 60)
    if r.json().get("live") == True:
        return True
    return False

def get_next_recording(api_key, live, timezone):
    if live:
        r = http.get(live_status_url, ttl_seconds = 60)
        header = render.Text("Live:")
        title = render.Text(r.json()["broadcast"]["title"])
        start_text = render.Text("Relay.fm", font = "tom-thumb")
    else:
        header = render.Text("Up next:")
        calendar_minimum_time = time.now().in_location("UTC").format("2006-01-02T15:04:05.000Z")
        calendar_url = "https://www.googleapis.com/calendar/v3/calendars/relay.fm_t9pnsv6j91a3ra7o8l13cb9q3o%40group.calendar.google.com/events?key=" + api_key + "&orderBy=startTime&singleEvents=true&timeMin=" + calendar_minimum_time
        r = http.get(calendar_url, ttl_seconds = 60)
        next = r.json()["items"][0]
        title = render.Text(next["summary"])
        start = time.parse_time(next.get("start").get("dateTime"), "2006-01-02T15:04:05-07:00", next.get("start").get("timeZone"))
        start_text = render.Text(start.in_location(timezone).format("Jan 2 3:04pm"), font = "tom-thumb")

    return render.Box(
        child = render.Padding(
            child = render.Column(
                children = [
                    header,
                    render.Marquee(
                        width = 35,
                        child = title,
                        offset_start = 35,
                        offset_end = 35,
                    ),
                    render.Marquee(
                        width = 35,
                        child = start_text,
                        offset_start = 35,
                        offset_end = 35,
                    ),
                ],
            ),
            pad = (1, 0, 0, 0),
        ),
        height = 29,
        color = "#333F48",
    )

def main(config):
    api_key = secret.decrypt("AV6+xWcEnY5UuB8W2NQaqtqkr2GMPfE/DoUivwka6vFAePA48Hg5HVnevD4IG2uZ+vAQHZXGbGmeY2Ir0b4OiNty2wwKmY6BiJGY1EztPaBXvbfG1PKp4PgJ3rVK1t5CF46X7C0iFwXwQs/e3dtP9DBn2XC/TR+Lwk0t1vTxXwAsSZmR1Eslg11DVKXD") or config.get("dev_api_key")
    timezone = config.get("timezone") or "America/New_York"
    img = render.Image(src = relay_logo)
    live = check_live()
    if not live and config.bool("live_only"):
        return []
    art = config.get("show_art") or live_page_url
    if live and art == "show_art":
        r = http.get(live_status_url, ttl_seconds = 60)
        img_url = r.json()["broadcast"]["show_art"]
        img_data = http.get(img_url, ttl_seconds = 60).body()
        img = render.Image(src = img_data, width = 29, height = 29)
    elif live and art == "relay_logo":
        img = render.Image(src = relay_logo)
    elif live:
        img = generate_qrcode(art)
    show = get_next_recording(api_key, live, timezone)
    main_content = render.Row(
        children = [
            img,
            show,
        ],
        expanded = True,
    )
    return render.Root(
        child = render.Column(
            children = [
                render.Box(height = 2, color = "#34657F"),
                main_content,
                render.Box(height = 1, color = "#34657F"),
            ],
        ),
    )

show_art_options = [
    schema.Option(
        display = "Show art when live",
        value = "show_art",
    ),
    schema.Option(
        display = "QR when live: Relay.fm website",
        value = live_page_url,
    ),
    schema.Option(
        display = "QR when live: Broadcasts app",
        value = live_broadcasts_url,
    ),
    schema.Option(
        display = "QR when live: m3u",
        value = live_m3u_url,
    ),
    schema.Option(
        display = "Always show Relay logo",
        value = "relay_logo",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "show_art",
                name = "Show art/QR code settings",
                desc = "Settings for how to display show art.",
                icon = "qrcode",
                default = show_art_options[0].value,
                options = show_art_options,
            ),
            schema.Toggle(
                id = "live_only",
                name = "Only show when live",
                desc = "Don't show this app when nothing is live.",
                icon = "towerBroadcast",
                default = False,
            ),
        ],
    )
