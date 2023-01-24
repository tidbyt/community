"""
Applet: Last FM
Summary: Show Last.fm history
Description: Show title, artist and album art from most recently scrobbled song in your Last.fm history.
Author: Chuck
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    userName = config.get("lastFmUser") or "badUser"
    api_key = config.get("lastApiKey") or "badKey"
    clockShown = config.get("showClock") or True

    if (userName == "DemoUser" or api_key == "DemoKey"):
        print("in demo")
        return demoMode()

    # handle missing config data
    if (userName == "badUser"):
        print("bad user")
        return render.Root(
            child = render.WrappedText(
                content = "Last.fm Username missing in Tidbyt config. Use DemoUser for demo.",
                color = "#FF0000",
                font = "tom-thumb",
            ),
        )
    if (api_key == "badKey"):
        print("bad key")
        return render.Root(
            child = render.WrappedText(
                content = "Last.fm API key missing in Tidbyt config. Use DemoKey for demo.",
                color = "#FF0000",
                font = "tom-thumb",
            ),
        )

    lastFmUrl = "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=" + userName + "&api_key=" + api_key + "&format=json"

    rep = http.get(lastFmUrl)
    if rep.status_code != 200:
        return render.Root(
            child = render.WrappedText(
                content = "Could not reach Last.fm API.",
                color = "#FF0000",
                font = "tom-thumb",
            ),
        )

    track = rep.json()["recenttracks"]["track"][0]

    #print(track["image"][0])
    img = http.get(track["image"][0]["#text"])

    #if no image on last.fm, use a colored box - should be rare
    if (img == ""):
        albumWidget = render.Box(color = "#5F9", height = 32, width = 32)
    else:
        albumWidget = render.Image(src = img.body(), height = 32, width = 32)

    now = ""
    if (clockShown == "true"):
        now = time.now()

    return renderIt(now, albumWidget, track)

def renderIt(now, albumWidget, track):
    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (42, 1, 0, 0),
                    child = render.Text(
                        content = now.format("3:04"),
                        font = "tom-thumb",
                        color = "#777",
                    ),
                ),
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = albumWidget,
                ),
                render.Box(
                    color = "#00FF0000",
                    child = render.Padding(
                        pad = (0, 0, 0, 0),
                        color = "#FF000000",
                        child = render.Column(
                            cross_align = "end",
                            main_align = "start",
                            expanded = False,
                            children = [
                                render.Box(
                                    color = "#0000FF00",
                                    height = 6,
                                ),
                                render.Padding(
                                    pad = (1, 1, 0, 0),
                                    color = "#11111199",
                                    child = render.WrappedText("%s" % track["name"], font = "tom-thumb", color = "#FFFFFF"),
                                ),
                                render.Padding(
                                    pad = (1, 1, 0, 0),
                                    color = "#11111199",
                                    child = render.WrappedText("%s" % track["artist"]["#text"], font = "tom-thumb", color = "#FFF"),
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def demoMode():
    now = time.now()
    demoIcon = base64.decode("""/9j/2wBDAAoHBwgHBgoICAgLCgoLDhgQDg0NDh0VFhEYIx8lJCIfIiEmKzcvJik0KSEiMEExNDk7Pj4+JS5ESUM8SDc9Pjv/2wBDAQoLCw4NDhwQEBw7KCIoOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozv/wAARCAAmACYDAREAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDzOAfMB0z69q1sYs29Ngt4NQRgCXHPyyKFBz0rO7MZN2PZrNp5rVXuLc274+4zAkfXHFehCTa1OOUTPl8VaPCZI/tQeSPqApwfx6VnKvBLQuFNydjzvxNqk+t6mZ5JIVhiGyDaNylcnP1Oe9csqjlqzqUVDRHJYcqGKYBUkH1qrmjL2mSHBZgDGGAPQc9Rz1HSokRJHquteJbfTtAiijcTXE9qNpRhhRjGT+v5VtOpaKS6nPGF2eZXWoEWrRQ/MJAN+05Iz1Fc0Y63Z0KFjGE8iYySOOB6CtjSxp6fp0k8oN3I8dtEvzMCDsB9BTcZWbQuaN0n1Oi8nSbR447R4b21ZQrtIG2Ic7vl6E8/l61lq9yrK5ba5gXyp3hggZm8tGK8rwcdOah66Dgkita+GLzVtVS5tYrYuQCyKQy4A5POOetDmkrItRvqzIm0HUvPMn9mxTJjH7lzg+9WpLuQb76OLO7W0tGhuplG6dYyWUAdVJ6fl3qozfK76XM3HXvYr6tabZ1sYSLpfKLv5SsoUbc9x1A/nUrTVlJdiDVbdpbyPS7S7jmEMf2wlQRvCpuAGehKkjnvUp9S7W0Ov8KQLYaq/mzwi3vU2WcxJBn3LuBj/AjOfp1qJaoqKsyqQLW9ls9TljsZ4gPmkdwJR6gqDmi2l0L1LurzReD9Bgs9OVvPuCyidsZHGWb6+g6ClG8ndlNcq0JfAdgq6bLqDndJdOYxnnCqec/U/wAhSm9bDgtLmDpU4k8eLMI1HnXjKw2jleVx+VU17oluanjuzt4o7O4gjWIwN5RVFCgZ+ZSuOmCp/SlTe6HLY1tOFj4z0OCfU7QPLC7IzAlTuHUgjnByDj1qJXpyshr3lqf/2Q==""")

    albumWidget = render.Image(src = demoIcon, height = 32, width = 32)
    track = {}
    track["name"] = "Come Together"
    artist = {}
    artist["#text"] = "The Beatles"
    track["artist"] = artist

    return renderIt(now, albumWidget, track)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "lastFmUser",
                name = "Last.fm Username",
                desc = "Name of the Last.fm user to view.",
                icon = "user",
                default = "DemoUser",
            ),
            schema.Text(
                id = "lastApiKey",
                name = "Last.fm API Key",
                desc = "Get from Last.fm, used to authenticate.",
                icon = "key",
                default = "DemoKey",
            ),
            schema.Toggle(
                id = "showClock",
                name = "Show Clock?",
                icon = "clock",
                desc = "Displays a clock showing the local time.",
            ),
        ],
    )
