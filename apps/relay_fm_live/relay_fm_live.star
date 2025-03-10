"""
Applet: Relay Live
Summary: Relay Live
Description: Shows live stream information for the Relay podcast network.
Author: radiocolin
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

relay_logo = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB0AAAAdCAYAAABWk2cPAAAAAXNSR0IArs4c6QAAAOZlWElmTU0AKgAAAAgABgESAAMAAAABAAEAAAEaAAUAAAABAAAAVgEbAAUAAAABAAAAXgExAAIAAAAhAAAAZgEyAAIAAAAUAAAAiIdpAAQAAAABAAAAnAAAAAAAAAEsAAAAAQAAASwAAAABQWRvYmUgUGhvdG9zaG9wIDI2LjIgKE1hY2ludG9zaCkAADIwMjU6MDE6MjEgMjE6MTg6MzQAAASQBAACAAAAFAAAANKgAQADAAAAAQABAACgAgAEAAAAAQAAAB2gAwAEAAAAAQAAAB0AAAAAMjAyNTowMToyMCAxNDozMTowNQA6RYPfAAAACXBIWXMAAC4jAAAuIwF4pT92AAAK6GlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iCiAgICAgICAgICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIKICAgICAgICAgICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICAgICAgICAgIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iPgogICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3BuZzwvZGM6Zm9ybWF0PgogICAgICAgICA8eG1wOk1vZGlmeURhdGU+MjAyNS0wMS0yMVQyMToxODozNC0wNjowMDwveG1wOk1vZGlmeURhdGU+CiAgICAgICAgIDx4bXA6Q3JlYXRvclRvb2w+QWRvYmUgUGhvdG9zaG9wIDI2LjIgKE1hY2ludG9zaCk8L3htcDpDcmVhdG9yVG9vbD4KICAgICAgICAgPHhtcDpDcmVhdGVEYXRlPjIwMjUtMDEtMjBUMTQ6MzE6MDUtMDY6MDA8L3htcDpDcmVhdGVEYXRlPgogICAgICAgICA8eG1wOk1ldGFkYXRhRGF0ZT4yMDI1LTAxLTIxVDIxOjE4OjM0LTA2OjAwPC94bXA6TWV0YWRhdGFEYXRlPgogICAgICAgICA8eG1wTU06SGlzdG9yeT4KICAgICAgICAgICAgPHJkZjpTZXE+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgMjYuMiAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAyNS0wMS0yMFQxNDozMTowNS0wNjowMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDplM2RmYmZjOC1jNjYyLTQ1NDUtYjNkZS04ODBmMWRhOWY5ZTc8L3N0RXZ0Omluc3RhbmNlSUQ+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+Y3JlYXRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDpzb2Z0d2FyZUFnZW50PkFkb2JlIFBob3Rvc2hvcCAyNi4yIChNYWNpbnRvc2gpPC9zdEV2dDpzb2Z0d2FyZUFnZW50PgogICAgICAgICAgICAgICAgICA8c3RFdnQ6Y2hhbmdlZD4vPC9zdEV2dDpjaGFuZ2VkPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDI1LTAxLTIxVDIxOjE4OjIxLTA2OjAwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6aW5zdGFuY2VJRD54bXAuaWlkOjQ5ZTJiMTQzLTU2MDctNDY4Yy1hODY5LTZhOGZlZmZhOTJkNjwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmFjdGlvbj5zYXZlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDpzb2Z0d2FyZUFnZW50PkFkb2JlIFBob3Rvc2hvcCAyNi4yIChNYWNpbnRvc2gpPC9zdEV2dDpzb2Z0d2FyZUFnZW50PgogICAgICAgICAgICAgICAgICA8c3RFdnQ6Y2hhbmdlZD4vPC9zdEV2dDpjaGFuZ2VkPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDI1LTAxLTIxVDIxOjE4OjM0LTA2OjAwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6aW5zdGFuY2VJRD54bXAuaWlkOjJlNzEyNTU0LWMzZjAtNDAwMS04MDBjLTEzYWJlYzBmZWM3ZDwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmFjdGlvbj5zYXZlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L3htcE1NOkhpc3Rvcnk+CiAgICAgICAgIDx4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ+eG1wLmRpZDplM2RmYmZjOC1jNjYyLTQ1NDUtYjNkZS04ODBmMWRhOWY5ZTc8L3htcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD4KICAgICAgICAgPHhtcE1NOkRvY3VtZW50SUQ+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")
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
    api_key = secret.decrypt("AV6+xWcEnY5UuB8W2NQaqtqkr2GMPfE/DoUivwka6vFAePA48Hg5HVnevD4IG2uZ+vAQHZXGbGmeY2Ir0b4OiNty2wwKmY6BiJGY1EztPaBXvbfG1PKp4PgJ3rVK1t5CF46X7C0iFwXwQs/e3dtP9DBn2XC/TR+Lwk0t1vTxXwAsSZmR1Eslg11DVKXD") or config.get("dev_api_key") or ""
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
        display = "Display show art when live",
        value = "show_art",
    ),
    schema.Option(
        display = "Display QR when live: Relay website",
        value = live_page_url,
    ),
    schema.Option(
        display = "Display QR when live: Broadcasts app",
        value = live_broadcasts_url,
    ),
    schema.Option(
        display = "Display QR when live: m3u",
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
                name = "Artwork/QR code settings",
                desc = "Settings for how to display artwork.",
                icon = "qrcode",
                default = show_art_options[0].value,
                options = show_art_options,
            ),
            schema.Toggle(
                id = "live_only",
                name = "Only show app when live",
                desc = "Don't show this app when nothing is live.",
                icon = "towerBroadcast",
                default = False,
            ),
        ],
    )
