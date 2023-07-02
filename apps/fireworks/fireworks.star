load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FIREWORK_CELLS = [
    render.Box(width = 1, height = 1, color = "#F00"),  # r
    render.Box(width = 1, height = 1, color = "#0F0"),  # g
    render.Box(width = 1, height = 1, color = "#00F"),  # b
    render.Box(width = 1, height = 1, color = "#FF0"),  # y
    render.Box(width = 1, height = 1, color = "#F80"),  # o
    render.Box(width = 1, height = 1, color = "#A0F"),  # p
    render.Box(width = 1, height = 1, color = "#FFF"),  # w
]

FADE_CELLS = [
    render.Box(width = 1, height = 1, color = "#0000"),
    render.Box(width = 1, height = 1, color = "#0001"),
    render.Box(width = 1, height = 1, color = "#0002"),
    render.Box(width = 1, height = 1, color = "#0003"),
    render.Box(width = 1, height = 1, color = "#0004"),
    render.Box(width = 1, height = 1, color = "#0005"),
    render.Box(width = 1, height = 1, color = "#0006"),
    render.Box(width = 1, height = 1, color = "#0007"),
    render.Box(width = 1, height = 1, color = "#0008"),
    render.Box(width = 1, height = 1, color = "#0009"),
    render.Box(width = 1, height = 1, color = "#000A"),
    render.Box(width = 1, height = 1, color = "#000B"),
    render.Box(width = 1, height = 1, color = "#000C"),
    render.Box(width = 1, height = 1, color = "#000D"),
    render.Box(width = 1, height = 1, color = "#000E"),
    render.Box(width = 1, height = 1, color = "#000F"),
]

FRAME_DELAY = 100
DURATION = 15100
ROCKET_SPEED = 8  # px/sec
ROCKET_COUNT = 14
ROCKET_FLARE_SPEED = 8  # px/sec
ROCKET_FLARES_COUNT = 120
ROCKET_FLARES_RADIUS = 8
ROCKET_FLARES_DECAY = 500  # ms to fully fade out
ROCKET_FUSE_SPACING = 750  # ms between rockets
DEFAULT_MESSAGE = "CUSTOM MESSAGE HERE"

def summon_fireworks():
    rockets = []
    max_altitude = 32 - ROCKET_FLARES_RADIUS
    min_altitude = max_altitude - 3
    for rocket_i in range(ROCKET_COUNT):
        rockets.append({
            "cell": FIREWORK_CELLS[random.number(0, len(FIREWORK_CELLS) - 1)],
            "fuse": ROCKET_FUSE_SPACING * rocket_i,
            "position_x": random.number(ROCKET_FLARES_RADIUS, 64 - ROCKET_FLARES_RADIUS),
            "altitude": -1,
            "max_altitude": random.number(min_altitude, max_altitude),
            "burst_frame_ms": -1,
            "flares_done_frame_ms": -1,
            "flares": [],
            "flares_done": False,
            "fades_done": False,
        })

        radii_odds = 0
        layers_twist = []
        for r in range(ROCKET_FLARES_RADIUS):
            layers_twist.append(random.number(0, 0xFFFFFFFF) / 0xFFFFFFFF * 2 * math.pi)
            radii_odds += (r + 1) * (r + 1)

        for _ in range(ROCKET_FLARES_COUNT):
            rand_shell = random.number(1, radii_odds)
            shell = 0
            dist = 0

            # Alternative to a while loop
            for _ in range(rand_shell):
                dist += 1
                shell += dist * dist
                if shell >= rand_shell:
                    break

            new_flare = {
                "angle": layers_twist[dist - 1],
                "max_dist": dist,
            }
            rockets[-1]["flares"].append(new_flare)

        # spread flares
        for shell in range(1, ROCKET_FLARES_RADIUS + 1):
            count_in_shell = 0
            for flare in rockets[-1]["flares"]:
                if flare["max_dist"] == shell:
                    count_in_shell += 1

            for i, flare in enumerate(rockets[-1]["flares"]):
                if flare["max_dist"] == shell:
                    flare["angle"] += ((2 * math.pi) / count_in_shell) * i
                    flare["cos"] = math.cos(flare["angle"])
                    flare["sin"] = math.sin(flare["angle"])

    return rockets

def render_rocket(timestamp_ms, rocket):
    cells = []
    if rocket["fuse"] > 0:
        rocket["fuse"] = max(0, rocket["fuse"] - FRAME_DELAY)
    elif rocket["fades_done"]:
        pass
    elif rocket["altitude"] < rocket["max_altitude"]:
        # Draw the rocket
        rocket["altitude"] += FRAME_DELAY / 1000 * ROCKET_SPEED
        rocket["altitude"] = min(rocket["altitude"], rocket["max_altitude"])
        r_pad = (
            rocket["position_x"],
            32 - int(rocket["altitude"]),
            0,
            0,
        )
        cells.append(render.Padding(child = rocket["cell"], pad = r_pad))
    else:
        # Draw the explosion
        rocket["altitude"] = rocket["max_altitude"]
        burst_length_ms = ROCKET_FLARES_RADIUS / ROCKET_FLARE_SPEED * 1000
        if rocket["burst_frame_ms"] == -1:
            rocket["burst_frame_ms"] = timestamp_ms
        if rocket["burst_frame_ms"] > -1:
            burst_percent = min(1, (timestamp_ms - rocket["burst_frame_ms"]) / burst_length_ms)
        else:
            burst_percent = 0

        if burst_percent == 1 and rocket["flares_done_frame_ms"] == -1:
            rocket["flares_done_frame_ms"] = timestamp_ms
            rocket["flares_done"] = True

        for flare in rocket["flares"]:
            flare_distance = burst_percent * flare["max_dist"]
            flare_pad = (
                int(rocket["position_x"] + flare["cos"] * flare_distance),
                int(32 - rocket["altitude"] + flare["sin"] * flare_distance),
                0,
                0,
            )

            if rocket["flares_done"]:
                fade_idx = min(1, (timestamp_ms - rocket["flares_done_frame_ms"]) / ROCKET_FLARES_DECAY)
                fade_idx = fade_idx * (len(FADE_CELLS) - 1)
                fade_idx = int(fade_idx)
                rocket["fades_done"] = fade_idx == len(FADE_CELLS) - 1
                fade_cell = FADE_CELLS[fade_idx]

            else:
                fade_cell = FADE_CELLS[0]

            if not rocket["fades_done"]:
                cells.append(render.Stack(children = [
                    render.Padding(child = rocket["cell"], pad = flare_pad),
                    render.Padding(child = fade_cell, pad = flare_pad),
                ]))

    return render.Stack(children = cells)

def render_all(message_content):
    frame_count = int(DURATION / FRAME_DELAY)
    rockets = summon_fireworks()
    frames = []
    timestamp_ms = 0
    widget_text = render.Text(content = message_content, color = "#CCC", font = "5x8")
    message_length = len(message_content) * 5
    if message_length > 64:
        widget_message = render.Padding(
            pad = (0, 24, 0, 0),
            child = render.Marquee(
                width = 64,
                child = widget_text,
                offset_start = 64,
            ),
        )
    else:
        widget_message = render.Padding(
            pad = (int((64 - message_length) / 2), 24, 0, 0),
            child = widget_text,
        )

    for _ in range(frame_count):
        frame_stack = []
        frame_stack.append(widget_message)
        for r in rockets:
            frame_stack.append(render_rocket(timestamp_ms, r))
        frames.append(render.Stack(children = frame_stack))
        timestamp_ms += FRAME_DELAY
    return frames

def main(config):
    if config.bool("show_message", True):
        msg = config.get("message", DEFAULT_MESSAGE)
    else:
        msg = " "
    return render.Root(delay = FRAME_DELAY, child = render.Animation(render_all(msg)))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "message",
                name = "Message",
                desc = "Message to show under the fireworks",
                icon = "font",
            ),
            schema.Toggle(
                id = "show_message",
                name = "Show Message",
                desc = "Disable this to only show fireworks",
                icon = "eye",
                default = True,
            ),
        ],
    )
