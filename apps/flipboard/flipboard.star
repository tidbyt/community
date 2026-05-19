"""
Applet: Flipboard
Summary: Retro split-flap display
Description: Shows a custom or preset message in the style of a vintage train-station or airport split-flap board, with the signature scramble-and-settle animation.
Author: itschriswilliams
"""

load("render.star", "render")
load("schema.star", "schema")

# ---------- grid ----------
COLS = 10
ROWS = 3
TOTAL = COLS * ROWS

# ---------- typography ----------
FONT = "6x10"

# ---------- character sets ----------
ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
ALLOWED = ALPHABET + " .,!?:'-"
ALPHABET_LEN = len(ALPHABET)

# ---------- palette ----------
BG = "#000000"

THEMES = {
    "amber": "#ffb000",
    "white": "#f0f0f0",
    "green": "#00e676",
    "red": "#ff3344",
}

# (frame_delay_ms, scramble_length, stagger_frames)
SPEEDS = {
    "slow": (110, 11, 1),
    "normal": (70, 7, 1),
    "fast": (45, 5, 1),
}

PRESETS = [
    ("hello", "HELLO WORLD"),
    ("morning", "GOOD MORNING"),
    ("evening", "GOOD EVENING"),
    ("welcome", "WELCOME HOME"),
    ("brb", "BACK SOON"),
    ("oncall", "ON A CALL"),
    ("meeting", "IN A MEETING"),
    ("focus", "FOCUS TIME"),
    ("dnd", "DO NOT DISTURB"),
    ("lunch", "OUT TO LUNCH"),
    ("coffee", "COFFEE BREAK"),
    ("snack", "SNACK BREAK"),
    ("away", "BE RIGHT BACK"),
    ("tgif", "TGIF"),
    ("monday", "MONDAY BLUES"),
    ("weekend", "HAPPY WEEKEND"),
    ("birthday", "HAPPY BIRTHDAY"),
    ("love", "I LOVE YOU"),
    ("ontime", "ALL ON TIME"),
    ("delayed", "ALL DELAYED"),
]

def _sanitize(s):
    s = s.upper()
    out = ""
    for i in range(len(s)):
        c = s[i]
        if c in ALLOWED:
            out += c
        else:
            out += " "
    return out

def _wrap(text, width):
    # Greedy word-wrap. Words wider than the row are hard-broken into
    # width-wide chunks.
    lines = []
    current = ""
    for w in text.split(" "):
        if w == "":
            continue
        if len(w) > width:
            if current != "":
                lines.append(current)
                current = ""
            for ci in range(0, len(w), width):
                chunk = w[ci:ci + width]
                if len(chunk) == width:
                    lines.append(chunk)
                else:
                    current = chunk
        elif current == "":
            current = w
        elif len(current) + 1 + len(w) <= width:
            current = current + " " + w
        else:
            lines.append(current)
            current = w
    if current != "":
        lines.append(current)
    return lines

def _align(text, width, align):
    pad = width - len(text)
    if pad <= 0:
        return text[:width]
    if align == "right":
        return " " * pad + text
    if align == "center":
        left = pad // 2
        return " " * left + text + " " * (pad - left)
    return text + " " * pad

def _layout(text, align):
    lines = _wrap(_sanitize(text), COLS)[:ROWS]
    aligned = [_align(line, COLS, align) for line in lines]
    top = (ROWS - len(aligned)) // 2
    bot = ROWS - len(aligned) - top
    blocks = [" " * COLS] * top + aligned + [" " * COLS] * bot
    return "".join(blocks)

def _scramble_char(frame_idx, tile_idx):
    # Deterministic pseudo-random pick from ALPHABET. Two co-prime
    # multipliers ensure each tile takes a different walk through the set.
    n = (frame_idx * 17 + tile_idx * 113 + 7) % ALPHABET_LEN
    return ALPHABET[n]

def _resolve_message(config):
    typed = config.get("message") or ""
    if typed.strip() != "":
        return typed
    preset_id = config.get("preset") or "hello"
    for pid, ptext in PRESETS:
        if pid == preset_id:
            return ptext
    return "HELLO WORLD"

def _build_frame(chars, fg):
    rows = []
    for r in range(ROWS):
        rows.append(render.Text(
            content = chars[r * COLS:(r + 1) * COLS],
            font = FONT,
            color = fg,
        ))
    return render.Box(
        color = BG,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = rows,
        ),
    )

def main(config):
    target = _layout(_resolve_message(config), config.get("align") or "center")
    fg = THEMES.get(config.get("color") or "amber", THEMES["amber"])
    delay_ms, scramble_len, stagger = SPEEDS.get(config.get("speed") or "normal", SPEEDS["normal"])

    # Total frames: every tile must get a scramble window after its stagger
    # start, plus a few hold frames at the end for the board to "rest."
    total_frames = TOTAL * stagger + scramble_len + 6

    frames = []
    for f in range(total_frames):
        chars = ""
        for i in range(TOTAL):
            start = i * stagger
            tgt = target[i]
            if f < start:
                # tile hasn't started flipping yet
                chars += " "
            elif f >= start + scramble_len:
                # tile has settled on its target
                chars += tgt
            else:
                # mid-scramble: blanks stay blank, everything else cycles
                if tgt == " ":
                    chars += " "
                else:
                    chars += _scramble_char(f, i)
        frames.append(_build_frame(chars, fg))

    return render.Root(
        delay = delay_ms,
        child = render.Animation(children = frames),
    )

def get_schema():
    color_options = [
        schema.Option(display = "Amber (classic)", value = "amber"),
        schema.Option(display = "White (station)", value = "white"),
        schema.Option(display = "Green (departures)", value = "green"),
        schema.Option(display = "Red (alert)", value = "red"),
    ]
    align_options = [
        schema.Option(display = "Center", value = "center"),
        schema.Option(display = "Left", value = "left"),
        schema.Option(display = "Right", value = "right"),
    ]
    speed_options = [
        schema.Option(display = "Slow", value = "slow"),
        schema.Option(display = "Normal", value = "normal"),
        schema.Option(display = "Fast", value = "fast"),
    ]
    preset_options = [
        schema.Option(display = ptext, value = pid)
        for pid, ptext in PRESETS
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "message",
                name = "Message",
                desc = "Custom message (overrides preset). Up to %d characters." % TOTAL,
                icon = "keyboard",
            ),
            schema.Dropdown(
                id = "preset",
                name = "Preset",
                desc = "Shown when no custom message is set.",
                icon = "list",
                default = "hello",
                options = preset_options,
            ),
            schema.Dropdown(
                id = "color",
                name = "Color",
                desc = "Board color theme.",
                icon = "palette",
                default = "amber",
                options = color_options,
            ),
            schema.Dropdown(
                id = "align",
                name = "Alignment",
                desc = "How to align the message on the board.",
                icon = "alignCenter",
                default = "center",
                options = align_options,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Animation speed",
                desc = "How fast the tiles flip.",
                icon = "gauge",
                default = "normal",
                options = speed_options,
            ),
        ],
    )
