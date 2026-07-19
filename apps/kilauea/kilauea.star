"""
Applet: Kīlauea
Summary: Live Kīlauea activity
Description: A data-driven pixel-art view of Kīlauea using official USGS updates.
Author: Dave Shilobod
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEVICE_WIDTH = 64
DEVICE_HEIGHT = 32

HANS_URL = "https://volcanoes.usgs.gov/hans-public/api/volcano/newestForVolcano/332010"
HTTP_CACHE_TTL_SECONDS = 5 * 60
LAST_GOOD_TTL_SECONDS = 30 * 24 * 60 * 60
LAST_GOOD_CACHE_KEY = "kilauea-hans-last-good-v1"

FRAME_DELAY_MS = 100
SCENE_PHASE_FRAME_COUNT = 18
SCENE_HOLD_FRAMES = 4
INFO_FRAME_COUNT = 35
INFO_SCROLL_DELAY_FRAMES = 4

CYCLE_STATES = ["quiet", "building", "erupting", "warning", "unknown"]
CYCLE_SCENE_PHASE_FRAME_COUNT = 6
CYCLE_SCENE_HOLD_FRAMES = 2
CYCLE_INFO_FRAME_COUNT = 12

COLOR_BLACK = "#02020a"
COLOR_SKY_TOP = "#050518"
COLOR_SKY_MID = "#09092a"
COLOR_SKY_LOW = "#14103a"
COLOR_HAZE = "#251650"
COLOR_RIDGE = "#09091d"
COLOR_ROCK = "#0b0814"
COLOR_ROCK_MID = "#171027"
COLOR_ROCK_LIGHT = "#28183f"
COLOR_TEXT = "#f7f5ff"
COLOR_SUPPORT_TEXT = "#e2dfed"
COLOR_MUTED = "#b8b4cc"
COLOR_STEAM_DARK = "#4a4768"

ALERT_COLORS = {
    "GREEN": "#34c759",
    "YELLOW": "#f6d32d",
    "ORANGE": "#ff8a1f",
    "RED": "#ff3b30",
    "UNASSIGNED": COLOR_MUTED,
    "UNKNOWN": COLOR_MUTED,
}

ALERT_SCALE = ["RED", "ORANGE", "YELLOW", "GREEN"]
ALERT_DIM_COLORS = {
    "GREEN": "#12351f",
    "YELLOW": "#403a10",
    "ORANGE": "#43220c",
    "RED": "#421015",
}

MONTHS = [
    ("JANUARY", "JAN"),
    ("FEBRUARY", "FEB"),
    ("MARCH", "MAR"),
    ("APRIL", "APR"),
    ("MAY", "MAY"),
    ("JUNE", "JUN"),
    ("JULY", "JUL"),
    ("AUGUST", "AUG"),
    ("SEPTEMBER", "SEP"),
    ("OCTOBER", "OCT"),
    ("NOVEMBER", "NOV"),
    ("DECEMBER", "DEC"),
]

FIXTURE_PAYLOADS = {
    "quiet": {
        "noticeId": "normal-visual-fixture",
        "noticeType": "Daily Update",
        "noticeTypeCd": "DU",
        "sentUtc": "2026-07-19",
        "sent_unixtime": 1784488015,
        "noticeSections": [{
            "vnum": "332010",
            "vName": "Kilauea",
            "alertLevel": "NORMAL",
            "colorCode": "GREEN",
            "synopsis": "HVO Kilauea GREEN/NORMAL - Kīlauea is not erupting. Monitoring parameters are at background levels.",
        }],
    },
    "building": {
        "noticeId": "DOI-USGS-HVO-2026-07-19T18:28:36+00:00",
        "noticeType": "Daily Update",
        "noticeTypeCd": "DU",
        "sentUtc": "2026-07-19",
        "sent_unixtime": 1784488015,
        "noticeHighestAlertLevel": "ADVISORY",
        "noticeHighestColorCode": "YELLOW",
        "noticeSections": [{
            "vnum": "332010",
            "vName": "Kilauea",
            "alertLevel": "ADVISORY",
            "colorCode": "YELLOW",
            "synopsis": "HVO Kilauea YELLOW/ADVISORY - The Halemaʻumaʻu eruption is paused. The next fountain episode is likely between July 24 and July 30.",
        }],
    },
    "erupting": {
        "noticeId": "DOI-USGS-HVO-2026-07-15T20:15:42+00:00",
        "noticeType": "Volcano Notice for Aviation",
        "noticeTypeCd": "VV",
        "sentUtc": "2026-07-15",
        "sent_unixtime": 1784147784,
        "noticeSections": [{
            "vnum": "332010",
            "vName": "Kilauea",
            "alertLevel": "WATCH",
            "colorCode": "ORANGE",
            "synopsis": "HVO Kilauea ORANGE/WATCH - Episode 51 of the ongoing Halemaʻumaʻu eruption continues at 10:20 a.m. HST on July 15.",
        }],
    },
    "warning": {
        "noticeId": "DOI-USGS-HVO-2026-04-10T03:31:42+00:00",
        "noticeType": "Volcano Notice for Aviation",
        "noticeTypeCd": "VV",
        "sentUtc": "2026-04-10",
        "sent_unixtime": 1775791902,
        "noticeSections": [{
            "vnum": "332010",
            "vName": "Kilauea",
            "alertLevel": "WATCH",
            "colorCode": "RED",
            "synopsis": "HVO Kilauea RED/WATCH - Episode 44 of the ongoing Halemaʻumaʻu eruption continues as of 5:00 p.m. HST on April 9, but with reduced ground hazards.",
        }],
    },
}

def main(config):
    mock_state = config.get("fixture") or config.get("mock_state")
    if mock_state and str(mock_state).lower() == "cycle":
        return cycle_demo()
    if mock_state:
        status = mock_status(mock_state)
    else:
        status = fetch_status()

    preview = config.get("preview")
    if preview == "scene":
        phase = int(config.get("preview_phase", "3")) % 6
        return render.Root(child = scene_frame(status, phase))
    if preview == "info":
        return render.Root(
            child = info_animation(status, False),
            delay = FRAME_DELAY_MS,
            show_full_animation = True,
        )
    if preview == "detail":
        return render.Root(
            child = info_animation(status, True),
            delay = FRAME_DELAY_MS,
            show_full_animation = True,
        )

    return render.Root(
        child = render.Sequence(
            children = [
                scene_animation(status),
                info_animation(status, False),
                info_animation(status, True),
            ],
        ),
        delay = FRAME_DELAY_MS,
        max_age = HTTP_CACHE_TTL_SECONDS,
        show_full_animation = True,
    )

def cycle_demo():
    labels = {
        "quiet": "QUIET",
        "building": "BUILDING",
        "erupting": "ERUPTING",
        "warning": "WARNING",
        "unknown": "NO DATA",
    }
    children = []
    for state_name in CYCLE_STATES:
        status = mock_status(state_name)
        status["headline"] = labels[state_name]
        children.append(
            scene_animation(
                status,
                phase_frame_count = CYCLE_SCENE_PHASE_FRAME_COUNT,
                hold_frames = CYCLE_SCENE_HOLD_FRAMES,
            ),
        )
        children.append(info_animation(status, False, CYCLE_INFO_FRAME_COUNT))

    return render.Root(
        child = render.Sequence(children = children),
        delay = FRAME_DELAY_MS,
        max_age = HTTP_CACHE_TTL_SECONDS,
        show_full_animation = True,
    )

def fetch_status():
    now_unix = time.now().unix
    response = http.get(
        HANS_URL,
        headers = {"Accept": "application/json"},
        ttl_seconds = HTTP_CACHE_TTL_SECONDS,
    )
    if response.status_code == 200:
        status = normalize_notice(response.json(), now_unix)
        if status != None and not status.get("expired", True):
            status["cached"] = False
            cache.set(
                LAST_GOOD_CACHE_KEY,
                json.encode(status),
                ttl_seconds = LAST_GOOD_TTL_SECONDS,
            )
            return status

    cached = cache.get(LAST_GOOD_CACHE_KEY)
    if cached:
        status = json.decode(cached)
        refresh_freshness(status, now_unix)
        if not status.get("expired", True):
            status["cached"] = True
            return status

    return unavailable_status()

def refresh_freshness(status, now_unix):
    sent_unix = status.get("sent_unix")
    freshness = freshness_state(sent_unix, now_unix)
    status["age_seconds"] = age_seconds(sent_unix, now_unix)
    status["freshness"] = freshness
    status["stale"] = freshness == "stale"
    status["expired"] = freshness == "expired"

def unavailable_status():
    return {
        "synopsis": "USGS status is temporarily unavailable.",
        "alert_level": "UNKNOWN",
        "color_code": "UNKNOWN",
        "sent_date": "",
        "sent_unix": 0,
        "mode": "unknown",
        "phase": "unknown",
        "headline": "NO DATA",
        "freshness": "expired",
        "stale": False,
        "expired": True,
        "cached": False,
    }

def mock_status(mock_state):
    state = str(mock_state).lower()
    if state == "paused":
        state = "building"
    payload = FIXTURE_PAYLOADS.get(state)
    if payload == None:
        return unavailable_status()

    fixture_time = int(payload.get("sent_unixtime", 0))
    status = normalize_notice(payload, fixture_time)
    if status == None:
        return unavailable_status()
    status["cached"] = False
    return status

def scene_frame(status, frame_index):
    mode = status.get("mode", "unknown")
    phase = frame_index % 6
    accent = alert_color(status.get("color_code", "UNKNOWN"))

    layers = base_scene()
    layers.extend(activity_layers(mode, phase))
    layers.extend(scene_alert_ladder(status.get("color_code", "UNKNOWN")))

    if mode == "warning" and phase % 2 == 0:
        layers.extend([
            rect(0, 0, 64, 1, accent),
            rect(0, 31, 64, 1, accent),
            rect(0, 0, 1, 32, accent),
            rect(63, 0, 1, 32, accent),
        ])

    return render.Stack(children = layers)

def scene_animation(
        status,
        phase_frame_count = SCENE_PHASE_FRAME_COUNT,
        hold_frames = SCENE_HOLD_FRAMES):
    frames = []
    for frame_index in range(phase_frame_count):
        frame = scene_frame(status, frame_index)
        for _ in range(hold_frames):
            frames.append(frame)
    return render.Animation(children = frames)

def scene_alert_ladder(color_code):
    active = color_code.upper()
    layers = [rect(59, 1, 4, 9, COLOR_ROCK_MID)]
    for index in range(len(ALERT_SCALE)):
        code = ALERT_SCALE[index]
        color = ALERT_COLORS[code] if code == active else ALERT_DIM_COLORS[code]
        layers.append(rect(60, 2 + index * 2, 2, 1, color))
    return layers

def base_scene():
    return [
        rect(0, 0, 64, 32, COLOR_SKY_TOP),
        rect(0, 7, 64, 5, COLOR_SKY_MID),
        rect(0, 12, 64, 4, COLOR_SKY_LOW),
        rect(0, 15, 64, 2, COLOR_HAZE),

        # Stars and thin clouds.
        rect(7, 4, 1, 1, "#77738f"),
        rect(18, 2, 1, 1, "#4d496d"),
        rect(46, 5, 1, 1, "#817c91"),
        rect(55, 3, 1, 1, "#4d496d"),
        rect(3, 9, 8, 1, "#12113a"),
        rect(9, 8, 7, 1, "#12113a"),
        rect(45, 10, 10, 1, "#191543"),
        rect(50, 9, 7, 1, "#191543"),

        # Distant caldera walls.
        rect(0, 14, 11, 1, COLOR_RIDGE),
        rect(0, 15, 17, 2, COLOR_RIDGE),
        rect(47, 14, 17, 1, COLOR_RIDGE),
        rect(42, 15, 22, 2, COLOR_RIDGE),
        rect(0, 17, 23, 2, COLOR_ROCK),
        rect(39, 17, 25, 2, COLOR_ROCK),

        # Crater rim and bowl.
        rect(13, 16, 38, 1, COLOR_ROCK_LIGHT),
        rect(9, 17, 46, 1, COLOR_ROCK_MID),
        rect(7, 18, 50, 1, COLOR_ROCK_LIGHT),
        rect(11, 19, 42, 1, COLOR_ROCK_MID),
        rect(14, 18, 36, 1, COLOR_BLACK),
        rect(12, 19, 40, 2, COLOR_BLACK),
        rect(16, 21, 32, 1, "#07050c"),

        # Near slopes and foreground texture.
        rect(0, 19, 12, 3, COLOR_ROCK),
        rect(52, 19, 12, 3, COLOR_ROCK),
        rect(0, 22, 64, 10, COLOR_ROCK),
        rect(0, 22, 10, 2, COLOR_ROCK_MID),
        rect(54, 22, 10, 2, COLOR_ROCK_MID),
        rect(4, 24, 14, 1, COLOR_ROCK_LIGHT),
        rect(46, 24, 14, 1, COLOR_ROCK_LIGHT),
        rect(10, 26, 14, 1, COLOR_ROCK_MID),
        rect(41, 27, 12, 1, COLOR_ROCK_MID),
        rect(2, 29, 16, 1, "#211431"),
        rect(23, 30, 18, 1, "#130d20"),
        rect(48, 30, 13, 1, "#211431"),
        rect(6, 31, 9, 1, COLOR_BLACK),
        rect(50, 31, 9, 1, COLOR_BLACK),
    ]

def activity_layers(mode, phase):
    if mode == "quiet":
        return quiet_layers(phase)
    if mode == "building":
        return building_layers(phase)
    if mode == "erupting":
        return erupting_layers(phase)
    if mode == "warning":
        return warning_layers(phase)
    return unknown_layers(phase)

def quiet_layers(phase):
    drift = phase // 2
    return [
        rect(31, 19, 2, 1, "#4c1d20"),
        rect(31 + drift, 15, 2, 2, COLOR_STEAM_DARK),
        rect(32 + drift, 12, 2, 2, "#34314d"),
        rect(34 + drift, 10, 2, 1, "#282640"),
    ]

def building_layers(phase):
    pulse = ["#7a2418", "#b33b18", "#ed6a1f", "#ff9f24", "#ed6a1f", "#b33b18"][phase]
    drift = phase // 2
    return [
        rect(27, 20, 10, 1, "#32121a"),
        rect(29, 19, 6, 1, pulse),
        rect(31, 18, 2, 1, "#ffd45a" if phase == 3 else pulse),
        rect(31 + drift, 14, 3, 3, COLOR_STEAM_DARK),
        rect(33 + drift, 11, 3, 3, "#5d5876"),
        rect(36 + drift, 9, 3, 2, COLOR_STEAM_DARK),
        rect(38 + drift, 7, 2, 2, "#34314d"),
    ]

def erupting_layers(phase):
    sway = [-1, 0, 1, 0, -1, 0][phase]
    top = [9, 8, 7, 8, 6, 8][phase]
    return [
        rect(22, 19, 20, 1, "#5c1714"),
        rect(25, 20, 14, 2, "#2d1014"),
        rect(28, 18, 8, 2, "#ff5a14"),
        rect(30, top, 4, 10, "#e83b10"),
        rect(31, top + 2, 2, 9, "#ffad24"),
        rect(32 + sway, top - 1, 1, 2, "#ffe66b"),
        rect(27 + sway, 11, 2, 2, "#ff6a14"),
        rect(36 - sway, 12, 2, 2, "#ff7a18"),
        rect(25 - sway, 8, 1, 2, "#ef4514"),
        rect(39 + sway, 9, 1, 2, "#ef4514"),
        rect(35, 6 + (phase % 2), 1, 2, "#ff9a1f"),
        rect(36, 4 + (phase % 3), 3, 3, COLOR_STEAM_DARK),
        rect(39, 2 + (phase % 2), 4, 3, "#5d5876"),
        rect(43, 1, 5, 3, "#353249"),
    ]

def warning_layers(phase):
    sway = [-1, 0, 1, 1, 0, -1][phase]
    return [
        rect(0, 14, 64, 3, "#3d0c23"),
        rect(9, 17, 46, 1, "#6f141c"),
        rect(18, 19, 28, 2, "#641313"),
        rect(24, 20, 18, 2, "#371011"),
        rect(27, 15, 11, 5, "#ef3510"),
        rect(29, 5, 7, 12, "#ff4f10"),
        rect(31, 3, 3, 15, "#ffc52d"),
        rect(32 + sway, 1, 2, 5, "#fff078"),
        rect(24 + sway, 9, 3, 3, "#ff6010"),
        rect(21 - sway, 6, 2, 2, "#ec3210"),
        rect(39 - sway, 7, 3, 3, "#ff6010"),
        rect(43 + sway, 4, 2, 2, "#ec3210"),
        rect(36, 1, 5, 4, "#55213d"),
        rect(40, 0, 7, 4, "#40203f"),
        rect(45, 1, 8, 5, "#2e1c3c"),
    ]

def unknown_layers(phase):
    blink = COLOR_MUTED if phase % 2 == 0 else COLOR_STEAM_DARK
    return [
        rect(30, 17, 4, 4, blink),
        rect(31, 12, 2, 4, blink),
        rect(31, 23, 2, 2, blink),
    ]

def info_frame(status, show_detail):
    mode = status.get("mode", "unknown")
    accent = alert_color(status.get("color_code", "UNKNOWN"))
    fallback_label = {
        "quiet": "QUIET",
        "building": "BUILDING",
        "erupting": "ERUPTING",
        "warning": "WARNING",
        "unknown": "NO DATA",
    }.get(mode, "NO DATA")
    label = status.get("headline", fallback_label)
    if label not in ["QUIET", "PAUSED", "BUILDING", "ERUPTING", "WARNING", "NO DATA"]:
        label = fallback_label

    if show_detail:
        bottom = detail_line(status)
    else:
        bottom = alert_line(status)

    return render.Box(
        width = DEVICE_WIDTH,
        height = DEVICE_HEIGHT,
        color = COLOR_BLACK,
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        alert_ladder(status.get("color_code", "UNKNOWN")),
                        render.Box(width = 1, height = 7),
                        render.Text(content = "USGS", font = "tom-thumb", color = COLOR_SUPPORT_TEXT),
                        render.Box(width = 2, height = 7),
                        render.Text(content = "KĪLAUEA", color = COLOR_TEXT),
                    ],
                ),
                render.Text(content = label, font = "6x13", color = accent),
                render.Marquee(
                    width = 60,
                    align = "center",
                    delay = INFO_SCROLL_DELAY_FRAMES,
                    child = render.Text(
                        content = bottom,
                        font = "5x8",
                        color = COLOR_SUPPORT_TEXT,
                    ),
                ),
            ],
        ),
    )

def info_animation(status, show_detail, frame_count = INFO_FRAME_COUNT):
    card = info_frame(status, show_detail)
    return render.Animation(children = [card for _ in range(frame_count)])

def alert_ladder(color_code):
    active = color_code.upper()
    children = []
    for index in range(len(ALERT_SCALE)):
        code = ALERT_SCALE[index]
        color = ALERT_COLORS[code] if code == active else ALERT_DIM_COLORS[code]
        children.append(render.Box(width = 2, height = 1, color = color))
        if index < len(ALERT_SCALE) - 1:
            children.append(render.Box(width = 2, height = 1))
    return render.Box(
        width = 4,
        height = 9,
        color = COLOR_ROCK_MID,
        child = render.Padding(
            pad = 1,
            child = render.Column(children = children),
        ),
    )

def alert_line(status):
    color = status.get("color_code", "UNKNOWN")
    alert = status.get("alert_level", "UNKNOWN")
    if color == "UNKNOWN" or alert == "UNKNOWN":
        return "STATUS UNKNOWN"
    line = "%s %s" % (color, alert)
    if len(line) <= 15:
        return line
    return alert[:15]

def detail_line(status):
    mode = status.get("mode", "unknown")
    if mode == "building":
        forecast = forecast_window(status.get("synopsis", ""))
        if forecast:
            return "NEXT %s" % forecast

    sent = short_date(status.get("sent_date", ""))
    if sent:
        if status.get("stale", False):
            prefix = "STALE"
        elif status.get("cached", False):
            prefix = "CACHED"
        else:
            prefix = "UPDATED"
        return "%s %s" % (prefix, sent)

    if mode == "erupting":
        return "SUMMIT ERUPTION"
    if mode == "warning":
        return "FOLLOW USGS"
    if mode == "quiet":
        return "NO ERUPTION"
    return "TRY AGAIN LATER"

def forecast_window(synopsis):
    text = synopsis.upper()
    marker = "LIKELY BETWEEN "
    start = text.find(marker)
    if start == -1:
        marker = "FORECAST WINDOW "
        start = text.find(marker)
    if start == -1:
        return ""

    tail = text[start + len(marker):]
    end = tail.find(".")
    if end != -1:
        tail = tail[:end]

    for full, short in MONTHS:
        tail = tail.replace(full, short)

    tokens = tail.replace(",", "").split()
    if len(tokens) < 2:
        return ""

    first_month = tokens[0]
    first_day = tokens[1]
    if len(tokens) == 2 or "-" in first_day:
        return "%s %s" % (first_month, first_day)

    if len(tokens) >= 4 and tokens[2] in ["AND", "TO", "THROUGH", "-"]:
        if tokens[3] == first_month and len(tokens) >= 5:
            return "%s %s-%s" % (first_month, first_day, tokens[4])
        if len(tokens) >= 5:
            return "%s %s-%s %s" % (first_month, first_day, tokens[3], tokens[4])

    return ""

def short_date(sent_utc):
    parts = sent_utc.split("-")
    if len(parts) != 3:
        return ""

    month_number = int(parts[1])
    if month_number < 1 or month_number > 12:
        return ""
    return "%s %d" % (MONTHS[month_number - 1][1], int(parts[2]))

def alert_color(color_code):
    return ALERT_COLORS.get(color_code.upper(), COLOR_MUTED)

def get_schema():
    return schema.Schema(version = "1", fields = [])

def rect(x, y, width, height, color):
    return render.Padding(
        pad = (
            x,
            y,
            DEVICE_WIDTH - x - width,
            DEVICE_HEIGHT - y - height,
        ),
        child = render.Box(width = width, height = height, color = color),
    )

# Pure normalization and activity classification for USGS HANS notices.
KILAUEA_VNUM = "332010"

FRESH_SECONDS = 48 * 60 * 60
EXPIRED_SECONDS = 7 * 24 * 60 * 60
FUTURE_TOLERANCE_SECONDS = 6 * 60 * 60

_BUILDING_PHRASES = (
    "precursory",
    "forecast",
    "imminent",
    "likely to begin",
    "likely between",
    "likely within",
    "another episode is likely",
    "another fountaining episode is likely",
    "forecast window",
    "inflation",
    "re-inflation",
    "re-inflating",
    "inflating",
    "heightened unrest",
    "escalating unrest",
    "increased unrest",
    "unrest is increasing",
)

_ENDED_PHRASES = (
    " ended",
    " stopped",
    " ceased",
    " paused",
    "not erupting",
    "not currently erupting",
    "no eruption",
    "no eruptive activity",
)

_QUIET_PHRASES = (
    "background level",
    "background state",
    "no significant activity",
    "remains quiet",
    "is quiet",
)

_ACTIVE_PHRASES = (
    "eruption is underway",
    "eruption continues",
    "currently erupting",
    "is erupting",
    "began erupting",
    "fountaining is underway",
    "fountaining activity is currently",
    "eruptive activity is occurring",
)

_ACTIVE_EPISODE_VERBS = (
    " began",
    " started",
    " continues",
    " resumed",
)

def _contains_any(text, phrases):
    for phrase in phrases:
        if phrase in text:
            return True
    return False

def _status(value):
    if type(value) != "string":
        return "UNASSIGNED"
    value = value.strip().upper()
    return value or "UNASSIGNED"

def _string(value, default = ""):
    if type(value) == "string":
        return value.strip()
    return default

def _integer(value):
    if type(value) == "int":
        return value
    if type(value) == "float":
        converted = int(value)
        if value == converted:
            return converted
    return None

def matches_vnum(value, target_vnum = KILAUEA_VNUM):
    """Return whether a JSON string or integral number identifies Kilauea."""
    if type(value) == "string":
        return value.strip() == target_vnum
    numeric = _integer(value)
    return numeric != None and str(numeric) == target_vnum

def select_volcano_section(payload, target_vnum = KILAUEA_VNUM):
    """Select the requested volcano section without trusting notice-wide maxima."""
    if type(payload) != "dict":
        return None

    sections = payload.get("noticeSections")
    if type(sections) != "list":
        return None

    for section in sections:
        if type(section) == "dict" and matches_vnum(section.get("vnum"), target_vnum):
            return section
    return None

def clean_synopsis(value):
    """Normalize whitespace and remove HANS's leading status prefix."""
    if type(value) != "string":
        return ""

    text = value.replace("\r", " ").replace("\n", " ").strip()
    delimiter = text.find(" - ")
    if delimiter >= 0 and delimiter < 96:
        prefix = text[:delimiter].lower()
        if "kilauea" in prefix or "kīlauea" in prefix:
            return text[delimiter + 3:].strip()
    return text

def _activity_signals(alert_level, color_code, synopsis):
    alert = _status(alert_level)
    color = _status(color_code)
    text = synopsis.lower() if type(synopsis) == "string" else ""

    warning = (
        alert == "WARNING" or
        color == "RED" or
        " red/warning - " in (" " + text) or
        " red/watch - " in (" " + text)
    )
    building = _contains_any(text, _BUILDING_PHRASES)
    ended = _contains_any(text, _ENDED_PHRASES)
    quiet = ended or _contains_any(text, _QUIET_PHRASES)
    active = _contains_any(text, _ACTIVE_PHRASES)
    if "episode" in text and _contains_any(text, _ACTIVE_EPISODE_VERBS):
        active = True

    return {
        "alert": alert,
        "color": color,
        "warning": warning,
        "building": building,
        "ended": ended,
        "paused": " paused" in text,
        "quiet": quiet,
        "active": active,
        "precursory": "precursory" in text,
    }

def classify_activity(alert_level, color_code, synopsis):
    """Map official status plus concise HANS language to a visual mode."""
    signals = _activity_signals(alert_level, color_code, synopsis)

    if signals["warning"]:
        return "warning"
    if signals["active"] and not signals["ended"] and not signals["precursory"]:
        return "erupting"
    if signals["building"]:
        return "building"
    if signals["quiet"]:
        return "quiet"
    if signals["alert"] == "WATCH" or signals["color"] == "ORANGE":
        return "building"
    if signals["alert"] == "NORMAL" or signals["color"] == "GREEN":
        return "quiet"
    return "unknown"

def classify_phase(alert_level, color_code, synopsis):
    """Return a literal headline phase separately from the visual mode."""
    signals = _activity_signals(alert_level, color_code, synopsis)

    if signals["warning"]:
        return "warning"
    if signals["paused"]:
        return "paused"
    if signals["active"] and not signals["precursory"]:
        return "erupting"
    if signals["building"]:
        return "precursor"
    if signals["quiet"] or signals["alert"] == "NORMAL" or signals["color"] == "GREEN":
        return "quiet"
    if signals["alert"] == "WATCH" or signals["color"] == "ORANGE":
        return "precursor"
    return "unknown"

def phase_headline(phase):
    return {
        "warning": "WARNING",
        "erupting": "ERUPTING",
        "precursor": "BUILDING",
        "paused": "PAUSED",
        "quiet": "QUIET",
        "unknown": "UNKNOWN",
    }.get(phase, "UNKNOWN")

def age_seconds(sent_unix, now_unix):
    """Return clamped age, or None for invalid/excessively future timestamps."""
    sent = _integer(sent_unix)
    now = _integer(now_unix)
    if sent == None or now == None or sent <= 0 or now <= 0:
        return None
    if sent > now + FUTURE_TOLERANCE_SECONDS:
        return None
    if sent > now:
        return 0
    return now - sent

def freshness_state(sent_unix, now_unix):
    age = age_seconds(sent_unix, now_unix)
    if age == None or age >= EXPIRED_SECONDS:
        return "expired"
    if age > FRESH_SECONDS:
        return "stale"
    return "fresh"

def normalize_notice(payload, now_unix, target_vnum = KILAUEA_VNUM):
    """Validate a HANS payload and return a compact deterministic model."""
    section = select_volcano_section(payload, target_vnum)
    if section == None:
        return None

    sent_unix = _integer(payload.get("sent_unixtime"))
    now = _integer(now_unix)
    if sent_unix == None or now == None or sent_unix <= 0 or now <= 0:
        return None
    if sent_unix > now + FUTURE_TOLERANCE_SECONDS:
        return None

    raw_synopsis = section.get("synopsis")
    synopsis = clean_synopsis(raw_synopsis)
    if synopsis == "":
        return None

    alert = _status(section.get("alertLevel"))
    color = _status(section.get("colorCode"))
    mode = classify_activity(alert, color, raw_synopsis)
    phase = classify_phase(alert, color, raw_synopsis)
    freshness = freshness_state(sent_unix, now)

    return {
        "vnum": target_vnum,
        "volcano_name": _string(section.get("vName"), "Kilauea") or "Kilauea",
        "notice_id": _string(payload.get("noticeId")),
        "notice_type": _string(payload.get("noticeType")),
        "notice_type_code": _string(payload.get("noticeTypeCd")),
        "sent_unix": sent_unix,
        "sent_date": _string(payload.get("sentUtc")),
        "alert_level": alert,
        "color_code": color,
        "synopsis": synopsis,
        "mode": mode,
        "phase": phase,
        "headline": phase_headline(phase),
        "age_seconds": age_seconds(sent_unix, now),
        "freshness": freshness,
        "stale": freshness == "stale",
        "expired": freshness == "expired",
    }
