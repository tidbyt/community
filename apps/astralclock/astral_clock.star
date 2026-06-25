"""
Applet: Astral Clock
Summary: Cosmic neon digital clock
Description: A unique creative digital clock featuring a deep space background, neon cyan time display with magenta chromatic aberration glow, twinkling stars, subtle planet orbs, and elegant decorative accents. Supports configurable timezone via location and 12/24-hour format toggle.
Author: gcrft123
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Color palette - cosmic neon theme
BG_COLOR = "#0a0a1f"
BG_ACCENT_TOP = "#120a2e"
BG_ACCENT_BOT = "#1a1433"
TIME_COLOR = "#00f0ff"  # Bright cyan
TIME_GLOW = "#006677"  # Deep glow
TIME_ALT = "#ff66cc"  # Magenta accent for chromatic
COLON_BRIGHT = "#ffffff"
COLON_DIM = "#008899"
DATE_COLOR = "#8899aa"
ACCENT = "#334466"
STAR_BRIGHT = "#aaddff"
STAR_DIM = "#334455"

def main(config):
    # Config
    location = config.get("location")
    loc = json.decode(location) if location else None
    timezone = loc["timezone"] if loc else config.get("$tz", "America/New_York")

    is_24_hour = config.bool("is_24_hour", True)

    now = time.now().in_location(timezone)

    # Format time
    if is_24_hour:
        time_format = "15:04"
        time_alt_format = "15 04"
    else:
        time_format = "3:04 PM"
        time_alt_format = "3 04 PM"

    time_str = now.format(time_format)
    time_alt_str = now.format(time_alt_format)

    # Date
    # e.g. "TUE 23"
    date_str = now.format("Mon").upper() + " " + now.format("2")

    # Build animation frames for lively feel (colon blink + star twinkle)
    frames = []

    # Precompute star positions (artistic scattered pattern, symmetric-ish)
    # list of (x, y)
    star_positions = [
        (4, 3),
        (59, 3),
        (8, 28),
        (55, 28),
        (20, 5),
        (43, 5),
        (12, 15),
        (51, 15),
        (4, 20),
        (59, 20),
    ]

    # 4 frames
    for frame_idx in range(4):
        show_colon = (frame_idx % 2 == 0)
        display_time = time_str if show_colon else time_alt_str

        # Build list of widgets for this frame explicitly
        frame_widgets = []

        # Background
        frame_widgets.append(render.Box(width = 64, height = 32, color = BG_COLOR))

        # Nebula tints
        frame_widgets.append(
            render.Padding(pad = (0, 0, 0, 0), child = render.Box(width = 64, height = 8, color = "#0b0a22")),
        )
        frame_widgets.append(
            render.Padding(pad = (0, 24, 0, 0), child = render.Box(width = 64, height = 8, color = "#0f0a28")),
        )

        # Stars with twinkle - vary  a subset
        for i, (sx, sy) in enumerate(star_positions):
            # Simple twinkle pattern
            if (frame_idx + i) % 3 == 0:
                scol = STAR_BRIGHT
            elif (frame_idx + i) % 2 == 0:
                scol = "#557788"
            else:
                scol = STAR_DIM
            frame_widgets.append(
                render.Padding(
                    pad = (sx, sy, 0, 0),
                    child = render.Box(width = 1, height = 1, color = scol),
                ),
            )

        # Side accents
        frame_widgets.append(
            render.Padding(pad = (0, 4, 0, 4), child = render.Box(width = 1, height = 24, color = ACCENT)),
        )
        frame_widgets.append(
            render.Padding(pad = (63, 4, 0, 4), child = render.Box(width = 1, height = 24, color = ACCENT)),
        )

        # Accent dots near center
        frame_widgets.append(
            render.Padding(pad = (18, 13, 0, 0), child = render.Box(width = 1, height = 1, color = "#225566")),
        )
        frame_widgets.append(
            render.Padding(pad = (45, 13, 0, 0), child = render.Box(width = 1, height = 1, color = "#225566")),
        )

        # Creative accent "planets" or orbs - unique flourish
        frame_widgets.append(
            render.Padding(
                pad = (2, 8, 0, 0),
                child = render.Circle(diameter = 3, color = "#334455"),
            ),
        )
        frame_widgets.append(
            render.Padding(
                pad = (59, 22, 0, 0),
                child = render.Circle(diameter = 2, color = "#445566"),
            ),
        )

        # Neon time with glow + chromatic layers (creative effect)
        # Use sized Box + Row center for accurate horizontal centering regardless of string width
        time_glow = render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Text(content = display_time, font = "6x13", color = TIME_GLOW),
        )
        time_chroma = render.Padding(
            pad = (0, 0, 1, 0),
            child = render.Text(content = display_time, font = "6x13", color = TIME_ALT),
        )
        time_main = render.Text(content = display_time, font = "6x13", color = TIME_COLOR)
        time_stack = render.Stack(children = [time_glow, time_chroma, time_main])

        time_centered = render.Box(
            width = 64,
            height = 13,
            child = render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [time_stack],
            ),
        )

        # Date centered
        date_text = render.Text(content = date_str, font = "tb-8", color = DATE_COLOR)
        date_centered = render.Box(
            width = 64,
            height = 8,
            child = render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [date_text],
            ),
        )

        centered_block = render.Padding(
            pad = (0, 5, 0, 0),
            child = render.Column(
                children = [
                    time_centered,
                    render.Box(width = 64, height = 2),
                    date_centered,
                ],
            ),
        )
        frame_widgets.append(centered_block)

        # Frame lines
        frame_widgets.append(
            render.Padding(pad = (10, 2, 10, 0), child = render.Box(width = 44, height = 1, color = "#223344")),
        )
        frame_widgets.append(
            render.Padding(pad = (10, 29, 10, 0), child = render.Box(width = 44, height = 1, color = "#223344")),
        )

        frames.append(render.Stack(children = frame_widgets))

    # end frames loop

    return render.Root(
        delay = 400,  # ms per frame - nice smooth blink
        max_age = 60,  # seconds before considered stale
        child = render.Box(
            child = render.Animation(children = frames),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Timezone to display time for.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "is_24_hour",
                name = "24-hour format",
                desc = "Display time in 24-hour format.",
                icon = "clock",
                default = True,
            ),
        ],
    )
