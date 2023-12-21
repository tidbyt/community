load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

FRAME_DELAYS = {"Normal": "100", "Fast": "60"}
DURATION = 15100
ROCKET_SPEED = 8  # px/sec
ROCKET_COUNT = 14
ROCKET_FLARE_SPEED = 8  # px/sec
ROCKET_FLARES_COUNT = 120
ROCKET_FLARES_RADIUS = 8
ROCKET_FLARES_DECAY = 500  # ms to fully fade out
ROCKET_FUSE_SPACING = 750  # ms between rockets
DEFAULT_FRAME_DELAY = FRAME_DELAYS["Normal"]

def compile_cells():
    # Create transparency levels for each color:
    cells = []
    firework_colors = ("#F00", "#0F0", "#00F", "#FF0", "#F80", "#A0F", "#FFF")
    for c in firework_colors:
        color_group = []
        for i in range(16):
            color_group.append(render.Box(width = 1, height = 1, color = c + "%X" % i))
        cells.append(color_group)
    return cells

FIREWORK_CELLS = compile_cells()

def summon_fireworks():
    rockets = []
    max_altitude = 32 - ROCKET_FLARES_RADIUS
    min_altitude = max_altitude - 3
    for rocket_i in range(ROCKET_COUNT):
        rockets.append({
            "cells": FIREWORK_CELLS[random.number(0, len(FIREWORK_CELLS) - 1)],
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

def render_rocket(timestamp_ms, frame_delay, rocket):
    cells = []
    if rocket["fuse"] > 0:
        rocket["fuse"] = max(0, rocket["fuse"] - frame_delay)
    elif rocket["fades_done"]:
        pass
    elif rocket["altitude"] < rocket["max_altitude"]:
        # Draw the rocket
        rocket["altitude"] += frame_delay / 1000 * ROCKET_SPEED
        rocket["altitude"] = min(rocket["altitude"], rocket["max_altitude"])
        r_pad = (
            rocket["position_x"],
            32 - int(rocket["altitude"]),
            0,
            0,
        )
        cells.append(render.Padding(child = rocket["cells"][15], pad = r_pad))
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
            if rocket["flares_done"]:
                # Start/continue fading:
                fade_idx = 1 - min(1, (timestamp_ms - rocket["flares_done_frame_ms"]) / ROCKET_FLARES_DECAY)
                fade_idx = fade_idx * 15
                fade_idx = int(fade_idx)
                rocket["fades_done"] = fade_idx == 0
                cell = rocket["cells"][fade_idx]

            else:
                cell = rocket["cells"][15]

            flare_distance = burst_percent * flare["max_dist"]
            flare_pad = (
                int(rocket["position_x"] + flare["cos"] * flare_distance),
                int(32 - rocket["altitude"] + flare["sin"] * flare_distance),
                0,
                0,
            )

            if not rocket["fades_done"]:
                cells.append(render.Padding(child = cell, pad = flare_pad))

    return render.Stack(children = cells)

def main(config):
    random.seed(time.now().unix // 10)
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)

    newyears_year = now.year + 1
    new_years = time.time(year = newyears_year, month = 1, day = 1, hour = 0, minute = 0, location = timezone)
    time_until_new_year_in_days = math.ceil(time.parse_duration(new_years - now).seconds / 86400)

    msg = ("%s Days till New Year's!" % time_until_new_year_in_days)

    widget_message = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Marquee(
                width = 64,
                child = render.Text(msg),
                offset_start = 64,
                offset_end = 64,
            ),
        ],
    )

    frame_delay = int(config.get("frame_delay", DEFAULT_FRAME_DELAY))
    timestamp_ms = 0
    frame_count = int(DURATION / frame_delay)
    frames = []
    rockets = summon_fireworks()
    for _ in range(frame_count):
        frame_stack = []
        frame_stack.append(widget_message)
        for r in rockets:
            frame_stack.append(render_rocket(timestamp_ms, frame_delay, r))
        frames.append(render.Stack(children = frame_stack))
        timestamp_ms += frame_delay

    return render.Root(
        delay = frame_delay,
        child = render.Animation(frames),
    )
