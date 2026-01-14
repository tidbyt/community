"""
Applet: Diya
Summary: Indian Diya Lamp
Description: Indian Diya Lamp that flickers slowly.
Author: aneeshsimha
"""

load("math.star", "math")
load("render.star", "render")

# Color palette - warm terracotta and flame colors
FLAME_WHITE = "#FFFACD"
FLAME_YELLOW = "#FFD700"
FLAME_LIGHT_ORANGE = "#FFB347"
FLAME_ORANGE = "#FF8C00"
FLAME_RED = "#FF4500"

# Clay/terracotta colors
CLAY_LIGHT = "#E07B53"
CLAY_MID = "#CD5C39"
CLAY_DARK = "#8B4513"
CLAY_SHADOW = "#5D3A1A"
CLAY_RIM = "#D2691E"

# Oil
OIL_SURFACE = "#FFB347"
OIL_DARK = "#CC8400"

BACKGROUND = "#0d0805"

def draw_diya_left():
    """Draw shallow diya on the left side"""
    x = 0
    y = 24  # Near bottom

    return [
        # Shallow bowl - wide and flat
        # Base
        render.Padding(
            pad = (x + 4, y + 4, 0, 0),
            child = render.Box(width = 14, height = 1, color = CLAY_SHADOW),
        ),
        # Lower body
        render.Padding(
            pad = (x + 3, y + 3, 0, 0),
            child = render.Box(width = 16, height = 1, color = CLAY_DARK),
        ),
        # Main body (wide, shallow)
        render.Padding(
            pad = (x + 2, y + 2, 0, 0),
            child = render.Box(width = 18, height = 1, color = CLAY_MID),
        ),
        # Upper rim
        render.Padding(
            pad = (x + 1, y + 1, 0, 0),
            child = render.Box(width = 20, height = 1, color = CLAY_LIGHT),
        ),
        # Top rim
        render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = 22, height = 1, color = CLAY_RIM),
        ),

        # Spout extending right
        render.Padding(
            pad = (x + 20, y + 1, 0, 0),
            child = render.Box(width = 4, height = 1, color = CLAY_LIGHT),
        ),
        render.Padding(
            pad = (x + 22, y, 0, 0),
            child = render.Box(width = 3, height = 1, color = CLAY_RIM),
        ),

        # Oil surface
        render.Padding(
            pad = (x + 3, y + 1, 0, 0),
            child = render.Box(width = 16, height = 1, color = OIL_DARK),
        ),
        render.Padding(
            pad = (x + 4, y + 1, 0, 0),
            child = render.Box(width = 14, height = 1, color = OIL_SURFACE),
        ),

        # Wick - 80 degree angle (almost vertical, slight lean right)
        render.Padding(
            pad = (x + 23, y - 3, 0, 0),
            child = render.Box(width = 2, height = 4, color = CLAY_SHADOW),
        ),
        render.Padding(
            pad = (x + 24, y - 4, 0, 0),
            child = render.Box(width = 1, height = 2, color = CLAY_SHADOW),
        ),
    ]

def draw_diya_right():
    """Draw shallow diya on the right side (mirrored)"""
    x = 42
    y = 24

    return [
        # Shallow bowl - wide and flat
        # Base
        render.Padding(
            pad = (x + 4, y + 4, 0, 0),
            child = render.Box(width = 14, height = 1, color = CLAY_SHADOW),
        ),
        # Lower body
        render.Padding(
            pad = (x + 3, y + 3, 0, 0),
            child = render.Box(width = 16, height = 1, color = CLAY_DARK),
        ),
        # Main body
        render.Padding(
            pad = (x + 2, y + 2, 0, 0),
            child = render.Box(width = 18, height = 1, color = CLAY_MID),
        ),
        # Upper rim
        render.Padding(
            pad = (x + 1, y + 1, 0, 0),
            child = render.Box(width = 20, height = 1, color = CLAY_LIGHT),
        ),
        # Top rim
        render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = 22, height = 1, color = CLAY_RIM),
        ),

        # Spout extending left
        render.Padding(
            pad = (x - 2, y + 1, 0, 0),
            child = render.Box(width = 4, height = 1, color = CLAY_LIGHT),
        ),
        render.Padding(
            pad = (x - 3, y, 0, 0),
            child = render.Box(width = 3, height = 1, color = CLAY_RIM),
        ),

        # Oil surface
        render.Padding(
            pad = (x + 3, y + 1, 0, 0),
            child = render.Box(width = 16, height = 1, color = OIL_DARK),
        ),
        render.Padding(
            pad = (x + 4, y + 1, 0, 0),
            child = render.Box(width = 14, height = 1, color = OIL_SURFACE),
        ),

        # Wick - 80 degree angle (almost vertical, slight lean left)
        render.Padding(
            pad = (x - 3, y - 3, 0, 0),
            child = render.Box(width = 2, height = 4, color = CLAY_SHADOW),
        ),
        render.Padding(
            pad = (x - 4, y - 4, 0, 0),
            child = render.Box(width = 1, height = 2, color = CLAY_SHADOW),
        ),
    ]

def draw_flame_left(frame):
    """Draw flame for left diya - teardrop shape, flickers to the right"""

    # Pseudo-random flicker using multiple prime-based cycles
    c1 = frame % 7
    c2 = (frame * 3) % 11
    c3 = (frame * 5) % 13
    flicker = (c1 + c2 + c3) % 8

    # Vary height more dramatically for randomness
    heights = [
        (12, 10, 7, 4),
        (10, 8, 5, 3),
        (11, 9, 6, 4),
        (9, 7, 5, 3),
        (13, 11, 8, 5),
        (10, 8, 6, 3),
        (11, 9, 7, 4),
        (9, 7, 5, 3),
    ]
    h1, h2, h3, h4 = heights[flicker]

    # Fluid sway with randomness
    sway = int(math.sin(float(frame) * 0.18) * 1.8 + math.sin(float(frame) * 0.07) * 0.8)

    base_x = 23
    base_y = 20

    # Teardrop flame shape - wide at bottom, pointed at top
    return [
        # Base of flame (widest) - red outer glow
        render.Padding(
            pad = (base_x + sway, base_y - 3, 0, 0),
            child = render.Box(width = 6, height = 3, color = FLAME_RED),
        ),
        # Lower-mid flame
        render.Padding(
            pad = (base_x + sway, base_y - 6, 0, 0),
            child = render.Box(width = 5, height = 4, color = FLAME_RED),
        ),
        # Mid flame - narrowing
        render.Padding(
            pad = (base_x + 1 + sway, base_y - h2, 0, 0),
            child = render.Box(width = 4, height = h2 - 2, color = FLAME_ORANGE),
        ),
        # Upper flame - narrower
        render.Padding(
            pad = (base_x + 1 + sway, base_y - h1, 0, 0),
            child = render.Box(width = 3, height = h1 - h2 + 2, color = FLAME_ORANGE),
        ),
        # Tip - pointed (1-2 pixels wide)
        render.Padding(
            pad = (base_x + 2 + sway, base_y - h1 - 2, 0, 0),
            child = render.Box(width = 2, height = 3, color = FLAME_LIGHT_ORANGE),
        ),
        # Inner glow - orange/yellow
        render.Padding(
            pad = (base_x + 1 + sway, base_y - 5, 0, 0),
            child = render.Box(width = 4, height = 4, color = FLAME_ORANGE),
        ),
        render.Padding(
            pad = (base_x + 1 + sway, base_y - h3, 0, 0),
            child = render.Box(width = 3, height = h3, color = FLAME_LIGHT_ORANGE),
        ),
        # Hot center - yellow
        render.Padding(
            pad = (base_x + 2 + sway, base_y - h4, 0, 0),
            child = render.Box(width = 2, height = h4, color = FLAME_YELLOW),
        ),
        # Hottest core - white
        render.Padding(
            pad = (base_x + 2 + sway, base_y - 3, 0, 0),
            child = render.Box(width = 2, height = 3, color = FLAME_WHITE),
        ),
    ]

def draw_flame_right(frame):
    """Draw flame for right diya - teardrop shape, mirrored to flicker left"""

    # Pseudo-random flicker with offset for variety
    c1 = (frame + 4) % 7
    c2 = ((frame + 4) * 3) % 11
    c3 = ((frame + 4) * 5) % 13
    flicker = (c1 + c2 + c3) % 8

    # Same height variations
    heights = [
        (12, 10, 7, 4),
        (10, 8, 5, 3),
        (11, 9, 6, 4),
        (9, 7, 5, 3),
        (13, 11, 8, 5),
        (10, 8, 6, 3),
        (11, 9, 7, 4),
        (9, 7, 5, 3),
    ]
    h1, h2, h3, h4 = heights[flicker]

    # Mirrored sway - flickers to the LEFT
    sway = -int(math.sin(float(frame) * 0.18) * 1.8 + math.sin(float(frame) * 0.07) * 0.8)

    base_x = 37
    base_y = 20

    # Teardrop flame shape - mirrored (inner layers offset left)
    return [
        # Base of flame (widest) - red outer glow
        render.Padding(
            pad = (base_x + sway, base_y - 3, 0, 0),
            child = render.Box(width = 6, height = 3, color = FLAME_RED),
        ),
        # Lower-mid flame
        render.Padding(
            pad = (base_x + 1 + sway, base_y - 6, 0, 0),
            child = render.Box(width = 5, height = 4, color = FLAME_RED),
        ),
        # Mid flame - narrowing (offset left)
        render.Padding(
            pad = (base_x + 1 + sway, base_y - h2, 0, 0),
            child = render.Box(width = 4, height = h2 - 2, color = FLAME_ORANGE),
        ),
        # Upper flame - narrower (offset left)
        render.Padding(
            pad = (base_x + 2 + sway, base_y - h1, 0, 0),
            child = render.Box(width = 3, height = h1 - h2 + 2, color = FLAME_ORANGE),
        ),
        # Tip - pointed (offset left)
        render.Padding(
            pad = (base_x + 2 + sway, base_y - h1 - 2, 0, 0),
            child = render.Box(width = 2, height = 3, color = FLAME_LIGHT_ORANGE),
        ),
        # Inner glow - orange/yellow
        render.Padding(
            pad = (base_x + 1 + sway, base_y - 5, 0, 0),
            child = render.Box(width = 4, height = 4, color = FLAME_ORANGE),
        ),
        render.Padding(
            pad = (base_x + 2 + sway, base_y - h3, 0, 0),
            child = render.Box(width = 3, height = h3, color = FLAME_LIGHT_ORANGE),
        ),
        # Hot center - yellow
        render.Padding(
            pad = (base_x + 2 + sway, base_y - h4, 0, 0),
            child = render.Box(width = 2, height = h4, color = FLAME_YELLOW),
        ),
        # Hottest core - white
        render.Padding(
            pad = (base_x + 2 + sway, base_y - 3, 0, 0),
            child = render.Box(width = 2, height = 3, color = FLAME_WHITE),
        ),
    ]

def draw_glow_left(frame):
    """Glow for left flame"""
    cycle = frame % 10
    size = 10 if cycle < 5 else 8

    return [
        render.Padding(
            pad = (21, 20 - size, 0, 0),
            child = render.Box(width = size, height = size, color = "#FF450010"),
        ),
    ]

def draw_glow_right(frame):
    """Glow for right flame"""
    cycle = (frame + 5) % 10
    size = 10 if cycle < 5 else 8

    return [
        render.Padding(
            pad = (35, 20 - size, 0, 0),
            child = render.Box(width = size, height = size, color = "#FF450010"),
        ),
    ]

def main(_):
    """Main app entry point"""

    frames = []
    for i in range(32):
        frame_elements = [
            render.Box(width = 64, height = 32, color = BACKGROUND),
        ] + draw_glow_left(i) + draw_glow_right(i) + draw_diya_left() + draw_diya_right() + draw_flame_left(i) + draw_flame_right(i)

        frames.append(
            render.Stack(children = frame_elements),
        )

    return render.Root(
        delay = 150,
        child = render.Animation(children = frames),
    )
