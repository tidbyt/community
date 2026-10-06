"""
Applet: Bridge of Lions
Summary: St. Augustine drawbridge
Description: Shows whether the Bridge of Lions in St. Augustine, FL is down (GO) or up (NO), based on its published USCG opening schedule (33 CFR 117.261).
Author: Steven Dack
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TZ = "America/New_York"
DEFAULT_WINDOW = "8"

SCHEDULE_START = 7
SCHEDULE_END = 18
WEEKDAY_SKIPS = [8, 12, 17]
DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

SCENE_W = 32
PANEL_W = 32
FRAMES = 48

GREEN = "#2ecc40"
GREEN_DIM = "#0b4d18"
RED = "#ff2b2b"
RED_DIM = "#5c0b0b"
AMBER = "#ffb000"
WHITE = "#ffffff"
GRAY = "#8a8f96"
DECK = "#a9aeb5"
DECK_DARK = "#5d6168"
CORAL = "#d9c9a3"
ROOF = "#b5482f"
GOLD = "#e8b923"
WATER = "#0b3a5c"
WAVE = "#3d8fc6"
CAR = "#39cccc"

def weekday(t):
    return DAYS.index(t.format("Mon"))

def ymd(t):
    return t.format("2006-01-02")

def day_at(year, month, day, hour = 12, minute = 0):
    return time.time(year = year, month = month, day = day, hour = hour, minute = minute, location = TZ)

def nth_weekday(year, month, wd, n):
    first = day_at(year, month, 1)
    return 1 + (wd - weekday(first)) % 7 + 7 * (n - 1)

def last_weekday(year, month, wd, last_day):
    last = day_at(year, month, last_day)
    return last_day - (weekday(last) - wd) % 7

def observed(year, month, day):
    t = day_at(year, month, day)
    wd = weekday(t)
    if wd == 5:
        t = t - time.hour * 24
    elif wd == 6:
        t = t + time.hour * 24
    return ymd(t)

def federal_holidays(year):
    return [
        observed(year, 1, 1),
        ymd(day_at(year, 1, nth_weekday(year, 1, 0, 3))),
        ymd(day_at(year, 2, nth_weekday(year, 2, 0, 3))),
        ymd(day_at(year, 5, last_weekday(year, 5, 0, 31))),
        observed(year, 6, 19),
        observed(year, 7, 4),
        ymd(day_at(year, 9, nth_weekday(year, 9, 0, 1))),
        ymd(day_at(year, 10, nth_weekday(year, 10, 0, 2))),
        observed(year, 11, 11),
        ymd(day_at(year, 11, nth_weekday(year, 11, 3, 4))),
        observed(year, 12, 25),
    ]

def openings_for(day):
    holidays = federal_holidays(day.year) + federal_holidays(day.year + 1)
    skip_rush = weekday(day) < 5 and ymd(day) not in holidays

    result = []
    for hour in range(SCHEDULE_START, SCHEDULE_END + 1):
        for minute in [0, 30]:
            if hour == SCHEDULE_END and minute > 0:
                continue
            if minute == 0 and skip_rush and hour in WEEKDAY_SKIPS:
                continue
            result.append(day_at(day.year, day.month, day.day, hour, minute))
    return result

def bridge_status(now, window):
    noon = day_at(now.year, now.month, now.day)
    openings = []
    for offset in [-1, 0, 1, 2]:
        openings += openings_for(noon + time.hour * 24 * offset)

    active = None
    upcoming = None
    for o in openings:
        mins = (o - now).minutes
        if active == None and -window <= mins and mins <= window:
            active = o
        if upcoming == None and mins > window:
            upcoming = o

    on_demand = now.hour < SCHEDULE_START or now.hour >= SCHEDULE_END
    if active != None:
        return struct(
            up = True,
            clear_in = int((active + time.minute * window - now).minutes) + 1,
            opening = active,
            on_demand = False,
        )
    return struct(
        up = False,
        next_in = int((upcoming - now).minutes) - window,
        opening = upcoming,
        on_demand = on_demand,
    )

def px(x, y, color, w = 1, h = 1):
    return render.Padding(pad = (x, y, 0, 0), child = render.Box(width = w, height = h, color = color))

def sprite(x0, y0, pixels):
    out = []
    for p in pixels:
        x = x0 + p[0]
        if x >= 0 and x < SCENE_W:
            out.append(px(x, y0 + p[1], p[2]))
    return out

def car_pixels():
    return [
        (1, 0, CAR),
        (2, 0, "#bdf3f3"),
        (0, 1, CAR),
        (1, 1, CAR),
        (2, 1, CAR),
        (3, 1, "#fff6a0"),
    ]

def boat_pixels():
    pixels = [(3, y, "#d0d0d0") for y in range(0, 7)]
    sail = [(2, 1), (2, 2), (1, 2), (2, 3), (1, 3), (0, 3), (2, 4), (1, 4), (0, 4), (2, 5), (1, 5)]
    pixels += [(p[0], p[1], WHITE) for p in sail]
    pixels.append((4, 2, RED))
    pixels += [(x, 7, "#8b5a2b") for x in range(0, 7)]
    pixels += [(x, 8, "#5e3a17") for x in range(1, 6)]
    return pixels

def water(frame):
    out = [px(0, 27, WATER, SCENE_W, 5)]
    for x in range(SCENE_W):
        if (x + frame // 2) % 7 == 0:
            out.append(px(x, 27, WAVE, 2, 1))
        if (x - frame // 3) % 9 == 0:
            out.append(px(x, 29, WAVE, 2, 1))
        if (x + frame // 4) % 11 == 0:
            out.append(px(x, 31, "#1f6b9a"))
    return out

def tower(x, light):
    return [
        px(x, 11, CORAL, 3, 16),
        px(x + 1, 13, "#7a6a4a", 1, 2),
        px(x, 10, ROOF, 3, 1),
        px(x - 1, 10, ROOF, 1, 1),
        px(x + 3, 10, ROOF, 1, 1),
        px(x + 1, 9, ROOF, 1, 1),
        px(x + 1, 8, light),
    ]

def leaves(up):
    if not up:
        return [
            px(11, 19, DECK, 10, 2),
            px(15, 19, DECK_DARK, 1, 2),
        ]
    out = []
    for i in range(9):
        dx = i // 3
        out.append(px(11 + dx, 20 - i, DECK, 2, 1))
        out.append(px(19 - dx, 20 - i, DECK, 2, 1))
    return out

def scene(status, frame):
    blink = (frame // 6) % 2 == 0
    if status.up:
        light = RED if blink else RED_DIM
    else:
        light = GREEN

    layers = water(frame)

    if status.up:
        boat_x = (frame * 2 // 3) % (SCENE_W + 8) - 7
        layers += sprite(boat_x, 18, boat_pixels())

    layers += [
        px(0, 19, DECK, 11, 2),
        px(21, 19, DECK, 11, 2),
        px(3, 21, DECK_DARK, 2, 6),
        px(26, 21, DECK_DARK, 2, 6),
        px(0, 21, DECK_DARK, 11, 1),
        px(21, 21, DECK_DARK, 11, 1),
    ]

    layers += sprite(0, 15, [
        (1, 0, GOLD),
        (0, 1, GOLD),
        (1, 1, GOLD),
        (2, 1, GOLD),
        (0, 2, GOLD),
        (2, 2, GOLD),
        (0, 3, GRAY),
        (1, 3, GRAY),
        (2, 3, GRAY),
    ])

    layers += leaves(status.up)

    if status.up:
        gate = RED if blink else WHITE
        layers += [px(5, 17, gate, 3, 1), px(24, 17, gate, 3, 1)]
    else:
        car_x = frame % (SCENE_W + 6) - 4
        layers += sprite(car_x, 17, car_pixels())
        car2_x = SCENE_W - 1 - (frame + 19) % (SCENE_W + 6) + 2
        layers += sprite(car2_x, 17, [
            (2, 0, "#ff851b"),
            (1, 0, "#ffc285"),
            (0, 1, "#fff6a0"),
            (1, 1, "#ff851b"),
            (2, 1, "#ff851b"),
            (3, 1, "#ff851b"),
        ])

    layers += tower(8, light)
    layers += tower(21, light)

    return render.Stack(
        children = [render.Box(width = SCENE_W, height = 32, color = "#000000")] + layers,
    )

def format_clock(t):
    return t.format("3:04")

def panel(status):
    if status.up:
        color = RED
        dim = RED_DIM
        word = "NO"
        label = "UP"
        detail = "CLR %dm" % status.clear_in
        detail_color = "#ff9a9a"
    else:
        color = GREEN
        dim = GREEN_DIM
        word = "GO"
        label = "DOWN"
        if status.on_demand:
            detail = "ON DEMAND"
            detail_color = AMBER
        elif status.next_in < 60:
            detail = "UP %dm" % max(status.next_in, 1)
            detail_color = "#a8f0b4"
        else:
            detail = "UP " + format_clock(status.opening)
            detail_color = "#a8f0b4"

    return render.Box(
        width = PANEL_W,
        height = 32,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(label, font = "tom-thumb", color = color),
                render.Box(
                    width = 28,
                    height = 15,
                    color = dim,
                    child = render.Box(
                        width = 26,
                        height = 13,
                        color = color,
                        child = render.Text(word, font = "6x13", color = "#000000"),
                    ),
                ),
                render.Marquee(
                    width = PANEL_W - 2,
                    align = "center",
                    child = render.Text(detail, font = "tom-thumb", color = detail_color),
                ),
            ],
        ),
    )

def main(config):
    window = int(config.get("window", DEFAULT_WINDOW))

    now = time.now().in_location(TZ)
    status = bridge_status(now, window)
    right = panel(status)

    frames = [
        render.Row(children = [scene(status, f), right])
        for f in range(FRAMES)
    ]

    return render.Root(
        delay = 90,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "window",
                name = "Warning window",
                desc = "Minutes before and after a scheduled opening to show the bridge as UP.",
                icon = "clock",
                default = DEFAULT_WINDOW,
                options = [
                    schema.Option(display = "5 minutes", value = "5"),
                    schema.Option(display = "8 minutes", value = "8"),
                    schema.Option(display = "10 minutes", value = "10"),
                    schema.Option(display = "15 minutes", value = "15"),
                ],
            ),
        ],
    )
