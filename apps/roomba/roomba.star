"""
Applet: Roomba
Summary: Shows status of Roomba
Description: Shows status of Roomba and Braava (i7/i7+, 980, 960, 900, e5, 690, 675, m6, etc). Can setup custom API key or leave blank.
Author: noahpodgurski
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

REFRESH_TIME = 180  # every few minutes

WHITE = "#ffffff"
BLACK = "#000000"
RED = "#ff0000"
GREEN = "#00ff00"
ORANGE = "#db8f00"

rIcon = "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAACXBIWXMAAAsTAAALEwEAmpwYAAAJnGlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDUgNzkuMTYzNDk5LCAyMDE4LzA4LzEzLTE2OjQwOjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ0MgMjAxOSAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIzLTA1LTI0VDE1OjIyOjU4LTA0OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIzLTA1LTI1VDE4OjAwOjMzLTA0OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMy0wNS0yNVQxODowMDozMy0wNDowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MTMzNmZiZmItZGYxNi1hYjRmLTg4YzktMTk3NzMxZThmZTNjIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOmI0MTJlYTI4LWQ1NDQtYWE0Yy1iNjBmLTgyNThhMmQzYzVhMCIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOjUxNDRjNzkxLThjYmYtMjQ0ZS05ODhlLTk0ZTk1NDUxOGVhMSIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgdGlmZjpPcmllbnRhdGlvbj0iMSIgdGlmZjpYUmVzb2x1dGlvbj0iNzIwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSI3MjAwMDAvMTAwMDAiIHRpZmY6UmVzb2x1dGlvblVuaXQ9IjIiIGV4aWY6Q29sb3JTcGFjZT0iNjU1MzUiIGV4aWY6UGl4ZWxYRGltZW5zaW9uPSIxMCIgZXhpZjpQaXhlbFlEaW1lbnNpb249IjEwIj4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo1MTQ0Yzc5MS04Y2JmLTI0NGUtOTg4ZS05NGU5NTQ1MThlYTEiIHN0RXZ0OndoZW49IjIwMjMtMDUtMjRUMTU6MjI6NTgtMDQ6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE5IChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gaW1hZ2UvcG5nIHRvIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmI0MTJlYTI4LWQ1NDQtYWE0Yy1iNjBmLTgyNThhMmQzYzVhMCIgc3RFdnQ6d2hlbj0iMjAyMy0wNS0yNFQxNToyOTowOC0wNDowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTkgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJkZXJpdmVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJjb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MTMzNmZiZmItZGYxNi1hYjRmLTg4YzktMTk3NzMxZThmZTNjIiBzdEV2dDp3aGVuPSIyMDIzLTA1LTI1VDE4OjAwOjMzLTA0OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgQ0MgMjAxOSAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOmI0MTJlYTI4LWQ1NDQtYWE0Yy1iNjBmLTgyNThhMmQzYzVhMCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpiNDEyZWEyOC1kNTQ0LWFhNGMtYjYwZi04MjU4YTJkM2M1YTAiIHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDo1MTQ0Yzc5MS04Y2JmLTI0NGUtOTg4ZS05NGU5NTQ1MThlYTEiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4mXzX0AAAAWUlEQVQYlXWOwQ3AIAwDL4hXYUAGgKkYgAzYvumDtqoi4peVcyxLHQe+IgjQywk0zcsATRMQvL9eLkDqSDu2ylI0J6Pgsab5wb852Zhg4qbMLv9CK7Ff/mrejqcePdD1Ft0AAAAASUVORK5CYII="
SAMPLE_DATA = {
    "batPct": 84,
    "name": "MyRoomba",
    "cleanMissionStatus": {
        "rechrgM": 0,
        "error": 0,
        "expireTm": 0,
        "mssnStrtTm": 1689100000,
        "phase": "run",
        "mssnM": 0,
        "cycle": "null",
        "condNotReady": [],
        "operatingMode": 0,
        "expireM": 0,
        "notReady": 0,
        "rechrgTm": 0,
        "initiator": "manual",
        "nMssn": 449,
        "missionId": "82348DVK9CV9CM212K23CM",
    },
}

BATTERY_OUTLINE = [
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
]

BATTERY_CHARGING = [
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 1],
    [1, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
]

BATTERY_PLEASE_CHARGE = [
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
]

WIDTH = 8
HEIGHT = 16
HEIGHT_ADJ = 2

def requestStatus(serverIP, serverPort, apiKey, roombaIP):
    if roombaIP:
        res = http.get("http://%s:%d/status?ip=%s" % (serverIP, serverPort, roombaIP), headers = {"x-api-key": apiKey}, ttl_seconds = REFRESH_TIME)
    else:
        res = http.get("http://%s:%d/status" % (serverIP, serverPort), headers = {"x-api-key": apiKey}, ttl_seconds = REFRESH_TIME)
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    res = res.json()
    return res

def main(config):
    white_pixel = render.Box(
        width = 1,
        height = 1,
        color = WHITE,
    )
    green_pixel = render.Box(
        width = 1,
        height = 1,
        color = GREEN,
    )
    red_pixel = render.Box(
        width = 1,
        height = 1,
        color = RED,
    )
    orange_pixel = render.Box(
        width = 1,
        height = 1,
        color = ORANGE,
    )
    black_pixel = render.Box(
        width = 1,
        height = 1,
        color = BLACK,
    )

    serverIP = config.str("serverIP")
    serverPort = config.str("serverPort")
    roombaIP = config.str("roombaIP")
    apiKey = config.str("apiKey")

    if not serverIP or type(int(serverPort)) != "int":
        data = SAMPLE_DATA
    else:
        serverPort = int(serverPort)
        data = requestStatus(serverIP, serverPort, apiKey, roombaIP)

    # print(data)
    if data and data["batPct"]:
        batPct = data["batPct"]
        name = data["name"]
        phase = data["cleanMissionStatus"]["phase"]
        # addr = data["netinfo"]["addr"]

    else:
        fail("Server did not respond correctly")

    batLabel = ""
    phaseLabel = ""
    phaseLabelColor = WHITE
    statusOffset = 7
    if phase == "charge":
        batLabel = "%d%%" % batPct
        phaseLabel = "charging"
        phaseLabelColor = GREEN
        if batPct == 100:
            batLabel = "%d%%" % batPct
            phaseLabel = "ready"
    elif phase == "chargeerror":
        phaseLabel = "error charging"
        statusOffset = 0
        phaseLabelColor = RED
    elif phase == "run":
        batLabel = "%d%%" % batPct
        phaseLabel = "cleaning"
        phaseLabelColor = GREEN
    elif phase == "error":
        batLabel = "%d%%" % batPct
        phaseLabel = "error"
        phaseLabelColor = RED
    elif phase != "charge" and batPct <= 5:
        phaseLabel = "please charge"
        statusOffset = 0
        phaseLabelColor = RED
    elif phase == "stop":
        batLabel = "%d%%" % batPct
        phaseLabel = "stopped"
        phaseLabelColor = RED

    #render battery icon
    # why not just use separate images for batteries? - it's NOT AS FUN
    batteryIconRows = []
    if batPct < 100 and phase == "charge":
        for y in range(HEIGHT):
            row = []
            for x in range(WIDTH):
                if BATTERY_CHARGING[y][x] == 1:
                    row.append(white_pixel)
                else:
                    row.append(black_pixel)
            batteryIconRows.append(row)
    elif batPct < 5 and phase != "charge":
        for y in range(HEIGHT):
            row = []
            for x in range(WIDTH):
                if BATTERY_PLEASE_CHARGE[y][x] == 1:
                    row.append(white_pixel)
                else:
                    row.append(black_pixel)
            batteryIconRows.append(row)
    else:
        for y in range(HEIGHT):
            row = []
            for x in range(WIDTH):
                if x != 0 and x < WIDTH - 1 and y > 2 and y < HEIGHT - 1:
                    #draw filled up battery depending on batPct
                    #green
                    if batPct >= 70 and y - HEIGHT_ADJ >= ((HEIGHT - HEIGHT_ADJ) * (1 - batPct / 100)):
                        row.append(green_pixel)
                        #orange

                    elif batPct >= 35 and y - HEIGHT_ADJ >= ((HEIGHT - HEIGHT_ADJ) * (1 - batPct / 100)):
                        row.append(orange_pixel)
                        #red

                    elif batPct >= 15 and y - HEIGHT_ADJ >= ((HEIGHT - HEIGHT_ADJ) * (1 - batPct / 100)):
                        row.append(red_pixel)
                        #bottom line on almost empty

                    elif batPct >= 5 and y >= 14:
                        row.append(red_pixel)
                        #all empty

                    else:
                        row.append(black_pixel)

                    #draw battery outline
                elif BATTERY_OUTLINE[y][x] == 1:
                    row.append(white_pixel)
                else:
                    row.append(black_pixel)
            batteryIconRows.append(row)

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "start",
            children = [
                render.Column(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Stack(
                            children = [
                                render.Padding(
                                    pad = 1,
                                    child = render.Row(
                                        expanded = True,
                                        main_align = "space_around",
                                        children = [
                                            render.Stack(children = [
                                                render.Image(src = base64.decode(rIcon)),
                                            ]),
                                            render.Text(name),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = 1,
                            child = render.Row(
                                main_align = "space_around",
                                cross_align = "center",
                                expanded = True,
                                children = [
                                    render.Stack(
                                        children = [
                                            render.Padding(
                                                pad = (0, 0, 50, 0),
                                                child = render.Column(
                                                    expanded = True,
                                                    children = [
                                                        render.Row(children = row)
                                                        for row in batteryIconRows
                                                    ],
                                                ),
                                            ),
                                            render.Padding(
                                                pad = (9, 0, 0, 0),
                                                child = render.WrappedText(batLabel, font = "5x8"),
                                            ),
                                            render.Padding(
                                                pad = (13, statusOffset, 1, 1),
                                                child = render.Column(
                                                    expanded = True,
                                                    children = [
                                                        render.WrappedText(phaseLabel, font = "5x8", color = phaseLabelColor),
                                                    ],
                                                ),
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serverIP",
                name = "Server IP",
                desc = "Ex: (192.168.1.123)",
                icon = "gear",
            ),
            schema.Text(
                id = "serverPort",
                name = "Server Port (optional)",
                desc = "Ex: 6565",
                icon = "gear",
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key (optional)",
                desc = "API Key setup in index.js",
                icon = "gear",
            ),
            schema.Text(
                id = "roombaIP",
                name = "Roomba IP (optional)",
                desc = "Ex: (192.168.1.123)",
                icon = "gear",
            ),
        ],
    )
