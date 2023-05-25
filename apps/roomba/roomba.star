"""
Applet: Roomba
Summary: Shows status of Roomba
Description: Shows status of Roomba and Braava (i7/i7+, 980, 960, 900, e5, 690, 675, m6, etc).
Author: noahpodgurski
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

REFRESH_TIME = 1800  # every half hour
APP_DURATION_MILLISECONDS = 15000
REFRESH_MILLISECONDS = 75

WHITE = "#ffffff"
BLACK = "#000000"
RED = "#ff0000"
GREEN = "#00ff00"
ORANGE = "#db8f00"
LOGO_GREEN = "#64A70B"

rIcon = "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAACXBIWXMAAAsTAAALEwEAmpwYAAAE82lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDUgNzkuMTYzNDk5LCAyMDE4LzA4LzEzLTE2OjQwOjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ0MgMjAxOSAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIzLTA1LTI0VDE1OjIyOjU4LTA0OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIzLTA1LTI0VDE1OjIyOjU4LTA0OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMy0wNS0yNFQxNToyMjo1OC0wNDowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NTE0NGM3OTEtOGNiZi0yNDRlLTk4OGUtOTRlOTU0NTE4ZWExIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOjUxNDRjNzkxLThjYmYtMjQ0ZS05ODhlLTk0ZTk1NDUxOGVhMSIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOjUxNDRjNzkxLThjYmYtMjQ0ZS05ODhlLTk0ZTk1NDUxOGVhMSIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyI+IDx4bXBNTTpIaXN0b3J5PiA8cmRmOlNlcT4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNyZWF0ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6NTE0NGM3OTEtOGNiZi0yNDRlLTk4OGUtOTRlOTU0NTE4ZWExIiBzdEV2dDp3aGVuPSIyMDIzLTA1LTI0VDE1OjIyOjU4LTA0OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgQ0MgMjAxOSAoV2luZG93cykiLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+PTWgagAAAE1JREFUGJVjTFnOzYAbsDAwMMyO+MLAwJC6ggfCgIDUFTwMDAxMuPRBlDJiNRxuHk7dCLvhypEBwm64HEQImcGEphzNMHS74YrwuRwOAFB5G1gX+2oKAAAAAElFTkSuQmCC"

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

def requestStatus(serverIP, serverPort, roombaIP):
    if roombaIP:
        res = http.get("http://%s:%d/status?ip=%s" % (serverIP, serverPort, roombaIP))
    else:
        res = http.get("http://%s:%d/status" % (serverIP, serverPort))
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
    serverPort = config.str("serverPort", 6565)
    roombaIP = config.str("roombaIP")

    if not serverIP:
        fail("Server IP must be configured")

    if type(int(serverPort)) != "int":
        fail("Server Port must be an integer")
    serverPort = int(serverPort)

    data = cache.get("data")
    if data != None:
        print("Cached - Displaying cached data.")
        data = json.decode(data)

        # print(data)
        # if not data["batPct"]: #invalid cached data, call again
        #     data = requestStatus(serverIP, serverPort, roombaIP)
        #     cache.set("data", json.encode(data), ttl_seconds = REFRESH_TIME)

    else:
        print("No data available - Calling Roomba API server")
        data = requestStatus(serverIP, serverPort, roombaIP)
        cache.set("data", json.encode(data), ttl_seconds = REFRESH_TIME)

    # print(data)
    if data and data["batPct"]:
        batPct = data["batPct"]
        name = data["name"]
        phase = data["cleanMissionStatus"]["phase"]
        # addr = data["netinfo"]["addr"]

    else:
        fail("Server did not respond correctly")

    # name = "MyRoomba"
    # phase = "charge"
    # batPct = 100
    # print(batPct, name, phase, addr)

    batFriendly = ""
    phaseFriendly = ""
    friendlyColor = WHITE
    statusOffset = 7
    if phase == "charge":
        batFriendly = "%d%%" % batPct
        phaseFriendly = "charging"
        friendlyColor = GREEN
        if batPct == 100:
            batFriendly = "%d%%" % batPct
            phaseFriendly = "ready"
    elif phase == "chargeerror":
        phaseFriendly = "error charging"
        statusOffset = 0
        friendlyColor = RED
    elif phase == "run":
        batFriendly = "%d%%" % batPct
        phaseFriendly = "cleaning"
        friendlyColor = GREEN
    elif phase == "error":
        batFriendly = "%d%%" % batPct
        phaseFriendly = "error"
        friendlyColor = RED
    elif phase != "charge" and batPct <= 5:
        phaseFriendly = "please charge"
        statusOffset = 0
        friendlyColor = RED
    elif phase == "stop":
        batFriendly = "%d%%" % batPct
        phaseFriendly = "stopped"
        friendlyColor = RED

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
                                                child = render.WrappedText(batFriendly, font = "5x8"),
                                            ),
                                            render.Padding(
                                                pad = (13, statusOffset, 1, 1),
                                                child = render.Column(
                                                    expanded = True,
                                                    children = [
                                                        render.WrappedText(phaseFriendly, font = "5x8", color = friendlyColor),
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
                id = "roombaIP",
                name = "Roomba IP (optional)",
                desc = "Ex: (192.168.1.123)",
                icon = "gear",
            ),
        ],
    )
