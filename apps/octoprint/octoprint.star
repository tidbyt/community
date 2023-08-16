"""
Applet: Octoprint
Summary: View Octoprint status
Description: Display current print's status and time remaining. Requires setting up port forwarding on octoprint server. API Key comes from Octoprint API settings.
Author: noahpodgurski
"""

load("animation.star", "animation")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

REFRESH_TIME = 60
C_DISPLAY_WIDTH = 64
C_BACKGROUND = [0, 0, 0]
C_TEXT_COLOR = [255, 255, 255]

C_MIN_WIDTH = 1
C_HEIGHT = 8

# colors
RED = "#FF0000"
WHITE = "#FFFFFF"
GREEN = "00FF00"

SAMPLE_JOB = {"job": {"averagePrintTime": None, "estimatedPrintTime": 22088.326056899437, "filament": {"tool0": {"length": 10523.5380859375, "volume": 25.312075423236383}}, "file": {"date": "1.689012611e + 0o9", "display": "benchy.gcode", "name": "benchy.gcode", "origin": "local", "path": "myfiles/gcode/benchy.gcode", "size": "1.5659901e + 0o7"}, "lastPrintTime": None, "user": "admin"}, "progress": {"filepos": "3.824944e + 0o6", "printTime": 6523.0, "printTimeLeft": 16016.0, "printTimeLeftOrigin": "genius", "completion": 24.42508416879519}, "state": "Printing"}
SAMPLE_PRINTER = {"sd": {"ready": False}, "state": {"error": "", "flags": {"printing": True, "ready": False, "sdReady": False, "resuming": False, "cancelling": False, "closedOrError": False, "error": False, "finishing": False, "operational": True, "paused": False, "pausing": False}, "text": "Printing"}, "temperature": {"W": {"actual": 0.0, "offset": 0.0, "target": None}, "bed": {"actual": 60.02, "offset": 0.0, "target": 60.0}, "tool0": {"actual": 199.81, "offset": 0.0, "target": 200.0}}}

def request(endpoint, serverIP, serverPort, apiKey):
    res = http.get("http://%s:%s%s" % (serverIP, serverPort, endpoint), headers = {"X-API-Key": apiKey}, ttl_seconds = REFRESH_TIME)
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    return res.json()

def requestSnapshot(snapshotURL):
    res = http.get(snapshotURL)
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    return res.body()

# convert color specification from JSON to hex string
def to_rgb(color, combine = None, combine_level = 0.5):
    # default to white color in case of error when parsing color
    (r, g, b) = (255, 255, 255)

    if str(type(color)) == "string":
        # parse various formats of colors as string
        if len(color) == 7:
            # color is in form of #RRGGBB
            r = int(color[1:3], 16)
            g = int(color[3:5], 16)
            b = int(color[5:7], 16)
        elif len(color) == 6:
            # color is in form of RRGGBB
            r = int(color[0:2], 16)
            g = int(color[2:4], 16)
            b = int(color[4:6], 16)
        elif len(color) == 4 and color[0:1] == "#":
            # color is in form of #RGB
            r = int(color[1:2], 16) * 0x11
            g = int(color[2:3], 16) * 0x11
            b = int(color[3:4], 16) * 0x11
        elif len(color) == 3 and color[0:1] != "#":
            # color is in form of RGB
            r = int(color[0:1], 16) * 0x11
            g = int(color[1:2], 16) * 0x11
            b = int(color[2:3], 16) * 0x11
    elif str(type(color)) == "list" and len(color) == 3:
        # otherwise assume color is an array of R, G, B tuple
        r = color[0]
        g = color[1]
        b = color[2]

    if combine != None:
        combine_color = lambda v0, v1, level: min(max(int(math.round(v0 + float(v1 - v0) * float(level))), 0), 255)
        r = combine_color(r, combine[0], combine_level)
        g = combine_color(g, combine[1], combine_level)
        b = combine_color(b, combine[2], combine_level)

    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

# render a single item's progress
def renderProgress(label, progress_value, padding):
    stack_children = [
        render.Box(width = C_DISPLAY_WIDTH, height = C_HEIGHT + padding, color = to_rgb(C_BACKGROUND)),
    ]

    color = "#64BFE5"

    if progress_value != None:
        progress = progress_value / 100.0
        progress_percent = int(math.round(progress_value))
        if label != "":
            label += ": "
        label += str(progress_percent) + "%"

        progress_width = C_MIN_WIDTH + int(math.round(float(C_DISPLAY_WIDTH - C_MIN_WIDTH) * progress))

        stack_children.append(
            render.Box(
                width = progress_width,
                padding = 1,
                color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.1),
                height = C_HEIGHT,
                child = render.Box(
                    color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.5),
                ),
            ),
        )

    # stack the progress bar with label
    stack_children.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text(
                    content = label,
                    color = to_rgb(color, combine = C_TEXT_COLOR, combine_level = 0.8),
                    height = C_HEIGHT,
                    offset = 1,
                    font = "tom-thumb",
                ),
            ],
        ),
    )

    # render the entire row
    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Stack(
                children = stack_children,
            ),
        ],
    )

def main(config):
    serverIP = config.str("serverIP")
    serverPort = config.str("serverPort", "5000")
    apiKey = config.str("apiKey")
    showSnapshot = config.bool("showSnapshot")

    if not serverIP or not apiKey:
        # use sample data
        job = SAMPLE_JOB
        printer = SAMPLE_PRINTER

    else:
        job = request("/api/job", serverIP, serverPort, apiKey)
        printer = request("/api/printer", serverIP, serverPort, apiKey)

    completion = math.round(job["progress"]["completion"])
    name = job["job"]["file"]["display"].removesuffix(".gcode")

    # printTime = str(math.round(job["progress"]["printTime"] / 360) / 10)
    printTimeLeft = str(math.round(job["progress"]["printTimeLeft"] / 360) / 10)

    state = printer["state"]["text"]
    bed = int(printer["temperature"]["bed"]["actual"])
    tool = int(printer["temperature"]["tool0"]["actual"])
    stateColor = WHITE
    if printer["state"]["flags"]["closedOrError"] or printer["state"]["flags"]["error"] or printer["state"]["flags"]["cancelling"]:
        stateColor = RED
    if printer["state"]["flags"]["printing"] or printer["state"]["flags"]["finishing"]:
        stateColor = GREEN

    snapshotURL = None
    if serverIP and showSnapshot:
        settings = request("/api/settings", serverIP, serverPort, apiKey)
        snapshotURL = settings["webcam"]["snapshotUrl"]
    if snapshotURL:
        snapshot = requestSnapshot(snapshotURL)

        return render.Root(
            child = render.Stack(
                children = [
                    animation.Transformation(
                        child = render.Box(
                            width = 64,
                            height = 32,
                            child = render.Padding(
                                pad = (0, 1, 0, 0),
                                child = render.Column(
                                    main_align = "center",
                                    cross_align = "center",
                                    expanded = True,
                                    children = [
                                        render.Text("%s" % name, font = "tom-thumb"),
                                        render.WrappedText(state, color = stateColor),
                                        render.Text("%s hrs left" % printTimeLeft),
                                        renderProgress("Completion", completion, 1),
                                    ] if job["job"]["file"]["path"] else [
                                        render.Text("Octoprint"),
                                        render.WrappedText(state, color = stateColor),
                                    ],
                                ),
                            ),
                        ),
                        duration = 200,
                        delay = 0,
                        origin = animation.Origin(0, 0),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(-0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.9,
                                transforms = [animation.Translate(-0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(64, 0)],
                                curve = "ease_in_out",
                            ),
                        ],
                    ),
                    animation.Transformation(
                        child = render.Stack(
                            children = [
                                render.Image(src = snapshot, width = 64, height = 32),
                                render.Box(
                                    width = 64,
                                    height = 32,
                                    child = render.Row(
                                        expanded = True,
                                        main_align = "start",
                                        children = [render.Stack(
                                            children = [
                                                render.Column(
                                                    main_align = "start",
                                                    cross_align = "start",
                                                    expanded = True,
                                                    children = [
                                                        render.Text("tool %s°" % tool, color = WHITE, font = "tom-thumb"),
                                                    ],
                                                ),
                                                render.Column(
                                                    main_align = "end",
                                                    cross_align = "start",
                                                    expanded = True,
                                                    children = [
                                                        render.Text("bed %s°" % bed, color = WHITE, font = "tom-thumb"),
                                                    ],
                                                ),
                                            ],
                                        )],
                                    ),
                                ),
                            ],
                        ),
                        duration = 200,
                        delay = 180,
                        origin = animation.Origin(0, 0),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(-64, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.1,
                                transforms = [animation.Translate(-0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                        ],
                    ),
                ],
            ),
        )

    else:
        return render.Root(
            child = render.Box(
                width = 64,
                height = 32,
                child = render.Padding(
                    pad = (0, 1, 0, 0),
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Text("%s" % name, font = "tom-thumb"),
                            render.WrappedText(state, color = stateColor),
                            render.Text("%s hrs left" % printTimeLeft),
                            renderProgress("Completion", completion, 1),
                        ] if job["job"]["file"]["path"] else [
                            render.Text("Octoprint"),
                            render.WrappedText(state, color = stateColor),
                        ],
                    ),
                ),
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serverIP",
                name = "Server IP",
                desc = "Make sure to use the public IP",
                icon = "gear",
            ),
            schema.Text(
                id = "serverPort",
                name = "Server Port",
                desc = "Make sure to port forward your octoprint port",
                icon = "gear",
            ),
            schema.Text(
                id = "apiKey",
                name = "Octoprint API Key",
                desc = "Found in Octoprint API settings",
                icon = "gear",
            ),
            schema.Toggle(
                id = "showSnapshot",
                name = "Show snapshot",
                desc = "Show snapshot from webcam. (Requires configured webcam)",
                icon = "gear",
            ),
        ],
    )
