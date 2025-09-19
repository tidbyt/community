"""
Applet: Rainbows
Summary: Colorful wave animations.
Description: Choose between Rainbow Magic, Rainbow Smoke, Rainbow Drops (water ripples), or Random.
Author: andersheie
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIDTH = 64
HEIGHT = 32

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "style",
                name = "Animation Style",
                desc = "Choose your preferred wave animation",
                icon = "palette",
                default = "drops",
                options = [
                    schema.Option(
                        display = "Rainbow Magic",
                        value = "magic",
                    ),
                    schema.Option(
                        display = "Rainbow Smoke",
                        value = "smoke",
                    ),
                    schema.Option(
                        display = "Random",
                        value = "random",
                    ),
                    schema.Option(
                        display = "Rainbow Drops (Default)",
                        value = "drops",
                    ),
                    schema.Option(
                        display = "Rainbow Farts",
                        value = "farts",
                    ),
                ],
            ),
        ],
    )

# ============================================================================
# RAINBOW MAGIC (V3) - Original optimized version
# ============================================================================

# Pre-calculated base multipliers to maintain exact original calculations

def get_precalc_bases():
    """Pre-calculate the base spatial multipliers used in original"""
    h_base1 = [x * 0.08 for x in range(WIDTH)]
    h_base2 = [x * 0.12 for x in range(WIDTH)]
    v_base1 = [y * 0.1 for y in range(HEIGHT)]
    v_base2 = [y * 0.15 for y in range(HEIGHT)]
    spatial_y = [y * 0.04 for y in range(HEIGHT)]
    spatial_x = [x * 0.03 for x in range(WIDTH)]
    brightness_y = [y * 0.08 for y in range(HEIGHT)]
    brightness_x = [x * 0.1 for x in range(WIDTH)]

    return h_base1, h_base2, v_base1, v_base2, spatial_y, spatial_x, brightness_y, brightness_x

# Exact color palette from original (with both bright and dark versions preserved)
COLOR_PALETTE_MAGIC = [
    ["#ff2222", "#cc1111"],  # Deep Red
    ["#ff4444", "#cc3333"],  # Red
    ["#ff5533", "#cc4422"],  # Red-Scarlet
    ["#ff6644", "#cc5533"],  # Red-Orange
    ["#ff7755", "#cc6644"],  # Orange-Red
    ["#ff8844", "#cc6633"],  # Orange
    ["#ff9933", "#cc7722"],  # Bright Orange
    ["#ffaa44", "#cc8833"],  # Orange-Yellow
    ["#ffbb33", "#cc9922"],  # Golden
    ["#ffcc44", "#ccaa33"],  # Yellow
    ["#ffdd33", "#ccbb22"],  # Bright Yellow
    ["#ffee44", "#cccc33"],  # Light Yellow
    ["#ffff66", "#cccc44"],  # Pale Yellow
    ["#ffffff", "#dddddd"],  # White
    ["#eeff88", "#bbcc66"],  # Cream
    ["#ddff44", "#bbcc33"],  # Yellow-Green
    ["#ccff44", "#aacc33"],  # Light Yellow-Green
    ["#bbff55", "#99cc44"],  # Yellow-Green
    ["#aaff66", "#88cc55"],  # Green-Yellow
    ["#88ff44", "#66cc33"],  # Light Green
    ["#77ff55", "#55cc44"],  # Green
    ["#66ff66", "#55cc55"],  # Pure Green
    ["#55ff77", "#44cc66"],  # Green
    ["#44ff88", "#33cc66"],  # Green-Cyan
    ["#33ff99", "#22cc77"],  # Green-Cyan
    ["#44ffaa", "#33cc88"],  # Cyan-Green
    ["#33ffbb", "#22cc99"],  # Cyan-Green
    ["#44ffcc", "#33ccaa"],  # Cyan
    ["#55ddff", "#44bbcc"],  # Light Cyan
    ["#66ccff", "#55aacc"],  # Cyan-Blue
    ["#44aaff", "#3388cc"],  # Sky Blue
    ["#5599ff", "#4477cc"],  # Light Blue
    ["#4488ff", "#3366cc"],  # Blue
    ["#5577ff", "#4455cc"],  # Blue
    ["#6666ff", "#5555cc"],  # Blue-Indigo
    ["#6644ff", "#5533cc"],  # Blue-Purple
    ["#7744ff", "#6633cc"],  # Purple-Blue
    ["#8844ff", "#6633cc"],  # Purple
    ["#9955ff", "#7744cc"],  # Purple
    ["#aa44ff", "#8833cc"],  # Purple-Magenta
    ["#bb55ff", "#9944cc"],  # Magenta-Purple
    ["#cc44ff", "#aa33cc"],  # Magenta
    ["#dd55ff", "#bb44cc"],  # Bright Magenta
    ["#ee66ff", "#cc55cc"],  # Pink-Magenta
    ["#ff44dd", "#cc33aa"],  # Magenta-Pink
    ["#ff55cc", "#cc4499"],  # Pink
    ["#ff66bb", "#cc5588"],  # Light Pink
    ["#ff4499", "#cc3377"],  # Pink-Red
    ["#ff4488", "#cc3366"],  # Pink
    ["#ff4466", "#cc3355"],  # Pink-Red
    ["#ff3355", "#cc2244"],  # Red-Pink
]

HEX_CHARS = "0123456789abcdef"

def to_hex_fast(val):
    """Fast hex conversion matching original"""
    return HEX_CHARS[val // 16] + HEX_CHARS[val % 16]

def rainbow_magic_main():
    """Rainbow Magic - Original optimized version"""

    # Get pre-calculated base values
    h_base1, h_base2, v_base1, v_base2, _, _, brightness_y, brightness_x = get_precalc_bases()

    # Get current time for animation - EXACT SAME as original
    now = time.now().unix

    # Changes every minute for slow randomness
    base_seed = int(now / 60) % 1000

    # EXACT frame count from original for identical visual behavior
    frames = []
    for frame in range(240):  # Exactly 240 frames like original
        # EXACT time normalization from original
        t_norm = frame / 240.0

        pixels = []
        for y in range(HEIGHT):
            row = []
            for x in range(WIDTH):
                # EXACT wave cycle calculations from original
                horizontal_cycle = t_norm * 2 * math.pi * (240 / 16) * 0.5
                vertical_cycle = t_norm * 2 * math.pi * (240 / 20) * 0.5

                # EXACT direction calculations from original
                base_direction_angle = t_norm * 2 * math.pi * 0.05 * 0.25
                random_offset_x = math.sin(base_seed * 0.1) * 2.0
                random_offset_y = math.cos(base_seed * 0.13) * 2.0

                direction_angle = base_direction_angle + random_offset_x
                direction_x = math.cos(direction_angle) + \
                              math.sin(random_offset_y) * 0.3
                direction_y = math.sin(direction_angle) + \
                              math.cos(random_offset_x) * 0.3

                # EXACT wave calculations using pre-calculated bases (this is the optimization)
                horizontal_wave1 = math.sin(h_base1[x] + horizontal_cycle) * 6
                horizontal_wave2 = math.sin(
                    h_base2[x] + horizontal_cycle * 1.3,
                ) * 4
                vertical_wave1 = math.sin(v_base1[y] + vertical_cycle) * 6
                vertical_wave2 = math.sin(
                    v_base2[y] + vertical_cycle * 1.2,
                ) * 4

                # EXACT flow calculations from original
                combined_horizontal = horizontal_wave1 + horizontal_wave2
                combined_vertical = vertical_wave1 + vertical_wave2
                flow_x = combined_horizontal * direction_x + \
                         combined_vertical * direction_y * 0.5
                flow_y = combined_vertical * direction_y + \
                         combined_horizontal * direction_x * 0.5

                # EXACT color calculations from original
                spatial_color = (y + flow_y) * 0.04 + (x + flow_x) * 0.03
                color_cycle = t_norm * len(COLOR_PALETTE_MAGIC) * 0.5
                color_offset = color_cycle % len(COLOR_PALETTE_MAGIC)
                band_position = (math.sin(spatial_color) *
                                 0.5 + 0.5) * len(COLOR_PALETTE_MAGIC)
                final_position = (
                    band_position + color_offset
                ) % len(COLOR_PALETTE_MAGIC)

                color1_idx = int(final_position) % len(COLOR_PALETTE_MAGIC)
                color2_idx = (color1_idx + 1) % len(COLOR_PALETTE_MAGIC)
                blend_factor = final_position - int(final_position)

                # EXACT PERPENDICULAR brightness waves from original
                brightness_horizontal_wave1 = math.sin(
                    brightness_y[y] + horizontal_cycle * 0.7,
                ) * 6
                brightness_horizontal_wave2 = math.sin(
                    brightness_y[y] + horizontal_cycle * 0.9,
                ) * 4
                brightness_vertical_wave1 = math.sin(
                    brightness_x[x] + vertical_cycle * 0.8,
                ) * 6
                brightness_vertical_wave2 = math.sin(
                    brightness_x[x] + vertical_cycle * 1.1,
                ) * 4

                # EXACT perpendicular flow for brightness
                brightness_combined_horizontal = brightness_horizontal_wave1 + \
                                                 brightness_horizontal_wave2
                brightness_combined_vertical = brightness_vertical_wave1 + brightness_vertical_wave2
                brightness_flow_x = brightness_combined_horizontal * \
                                    direction_y + brightness_combined_vertical * direction_x * 0.5
                brightness_flow_y = brightness_combined_vertical * direction_x + \
                                    brightness_combined_horizontal * direction_y * 0.5

                brightness_spatial = (x + brightness_flow_x) * \
                                     0.04 + (y + brightness_flow_y) * 0.03
                brightness_wave_pos = brightness_spatial + t_norm * 1.0
                brightness_multiplier = math.sin(
                    brightness_wave_pos,
                ) * 0.3 + 0.65
                brightness_multiplier = max(
                    0.35,
                    min(1.0, brightness_multiplier),
                )

                # EXACT color selection from original (using bright version always as base)
                if blend_factor < 0.5:
                    base_color = COLOR_PALETTE_MAGIC[color1_idx][0]
                else:
                    base_color = COLOR_PALETTE_MAGIC[color2_idx][0]

                # EXACT brightness application from original
                r = int(int(base_color[1:3], 16) * brightness_multiplier)
                g = int(int(base_color[3:5], 16) * brightness_multiplier)
                b = int(int(base_color[5:7], 16) * brightness_multiplier)

                r = max(0, min(255, r))
                g = max(0, min(255, g))
                b = max(0, min(255, b))

                color = "#" + to_hex_fast(r) + to_hex_fast(g) + to_hex_fast(b)
                row.append(color)
            pixels.append(row)

        # Same render structure as original
        columns = []
        for x in range(WIDTH):
            column_pixels = []
            for y in range(HEIGHT):
                column_pixels.append(pixels[y][x])
            columns.append(render.Column(
                children = [
                    render.Box(width = 1, height = 1, color = color)
                    for color in column_pixels
                ],
            ))

        frames.append(render.Row(children = columns))

    return render.Root(
        delay = 50,  # EXACT delay from original
        child = render.Animation(children = frames),
    )

# ============================================================================
# RAINBOW SMOKE (ULTRA FAST) - Optimized array slicing version
# ============================================================================

# Compact color array designed for 3-4 visible bands across 64 pixels
COMPACT_COLORS_SMOKE = [
    # Band 1: Red to Orange to Yellow (16 colors - smoother steps)
    "#ff0000",
    "#ff1000",
    "#ff2000",
    "#ff3000",
    "#ff4000",
    "#ff5000",
    "#ff6000",
    "#ff7000",
    "#ff8000",
    "#ff9000",
    "#ffa000",
    "#ffb000",
    "#ffc000",
    "#ffd000",
    "#ffe000",
    "#fff000",

    # Band 2: Yellow to Green to Cyan (16 colors)
    "#ffff00",
    "#f0ff00",
    "#e0ff00",
    "#d0ff00",
    "#c0ff00",
    "#b0ff00",
    "#a0ff00",
    "#90ff00",
    "#80ff00",
    "#70ff00",
    "#60ff00",
    "#50ff00",
    "#40ff00",
    "#30ff00",
    "#20ff00",
    "#10ff00",

    # Band 3: Green to Cyan to Blue (16 colors)
    "#00ff00",
    "#00ff10",
    "#00ff20",
    "#00ff30",
    "#00ff40",
    "#00ff50",
    "#00ff60",
    "#00ff70",
    "#00ff80",
    "#00ff90",
    "#00ffa0",
    "#00ffb0",
    "#00ffc0",
    "#00ffd0",
    "#00ffe0",
    "#00fff0",

    # Band 4: Cyan to Blue to Purple (16 colors)
    "#00ffff",
    "#00f0ff",
    "#00e0ff",
    "#00d0ff",
    "#00c0ff",
    "#00b0ff",
    "#00a0ff",
    "#0090ff",
    "#0080ff",
    "#0070ff",
    "#0060ff",
    "#0050ff",
    "#0040ff",
    "#0030ff",
    "#0020ff",
    "#0010ff",

    # Band 5: Blue to Purple to Magenta (16 colors)
    "#0000ff",
    "#1000ff",
    "#2000ff",
    "#3000ff",
    "#4000ff",
    "#5000ff",
    "#6000ff",
    "#7000ff",
    "#8000ff",
    "#9000ff",
    "#a000ff",
    "#b000ff",
    "#c000ff",
    "#d000ff",
    "#e000ff",
    "#f000ff",

    # Band 6: Purple to Magenta to Red (16 colors - completing the cycle)
    "#ff00ff",
    "#ff00f0",
    "#ff00e0",
    "#ff00d0",
    "#ff00c0",
    "#ff00b0",
    "#ff00a0",
    "#ff0090",
    "#ff0080",
    "#ff0070",
    "#ff0060",
    "#ff0050",
    "#ff0040",
    "#ff0030",
    "#ff0020",
    "#ff0010",
]

# Create extended array - copy colors 5 times for bounds safety
EXTENDED_COLORS_SMOKE = COMPACT_COLORS_SMOKE + COMPACT_COLORS_SMOKE + \
                        COMPACT_COLORS_SMOKE + COMPACT_COLORS_SMOKE + COMPACT_COLORS_SMOKE

# Extended vibrant color palette for Rainbow Farts
COLORS_FARTS = [
    "#ff4444",  # Red
    "#ff5544",  # Red-Orange
    "#ff6644",  # Orange-Red
    "#ff7744",  # Orange
    "#ff8844",  # Orange
    "#ff9944",  # Orange-Yellow
    "#ffaa44",  # Orange-Yellow
    "#ffbb44",  # Golden
    "#ffcc44",  # Yellow-Gold
    "#ffdd44",  # Yellow
    "#ffee44",  # Bright Yellow
    "#ffff44",  # Pure Yellow
    "#eeff44",  # Yellow-Green
    "#ddff44",  # Yellow-Green
    "#ccff44",  # Light Green-Yellow
    "#bbff44",  # Green-Yellow
    "#aaff44",  # Green-Yellow
    "#99ff44",  # Green
    "#88ff44",  # Light Green
    "#77ff44",  # Green
    "#66ff44",  # Green
    "#55ff55",  # Pure Green
    "#44ff66",  # Green
    "#44ff77",  # Green-Cyan
    "#44ff88",  # Green-Cyan
    "#44ff99",  # Cyan-Green
    "#44ffaa",  # Cyan-Green
    "#44ffbb",  # Cyan-Green
    "#44ffcc",  # Cyan
    "#44ffdd",  # Light Cyan
    "#44ffee",  # Light Cyan
    "#44ffff",  # Pure Cyan
    "#44eeff",  # Cyan-Blue
    "#44ddff",  # Light Blue
    "#44ccff",  # Light Blue
    "#44bbff",  # Blue
    "#44aaff",  # Sky Blue
    "#4499ff",  # Blue
    "#4488ff",  # Blue
    "#4477ff",  # Blue-Indigo
    "#4466ff",  # Blue-Purple
    "#4455ff",  # Purple-Blue
    "#5544ff",  # Purple-Blue
    "#6644ff",  # Purple
    "#7744ff",  # Purple
    "#8844ff",  # Purple
    "#9944ff",  # Purple-Magenta
    "#aa44ff",  # Purple-Magenta
    "#bb44ff",  # Magenta-Purple
    "#cc44ff",  # Magenta
    "#dd44ff",  # Bright Magenta
    "#ee44ff",  # Pink-Magenta
    "#ff44ee",  # Magenta-Pink
    "#ff44dd",  # Pink
    "#ff44cc",  # Pink
    "#ff44bb",  # Light Pink
    "#ff44aa",  # Pink
    "#ff4499",  # Pink-Red
    "#ff4488",  # Pink-Red
    "#ff4477",  # Pink-Red
    "#ff4466",  # Red-Pink
    "#ff4455",  # Red-Pink
]

def render_row_ultra_fast_smoke(base_color_start, horizontal_offset, _):
    """ULTRA FAST: Direct array slicing instead of per-pixel calculations"""

    # Calculate start position in extended array
    start_pos = base_color_start + horizontal_offset

    # Extract exactly 64 consecutive colors - PURE ARRAY SLICING!
    raw_colors = EXTENDED_COLORS_SMOKE[start_pos:start_pos + WIDTH]

    # Return raw colors for maximum speed (skip brightness calculations)
    return raw_colors

def rainbow_smoke_main():
    """Rainbow Smoke - Ultra-fast array slicing optimization with compact color bands"""

    # Get time-based seed for variation
    now = time.now().unix
    time_seed = (now // 30) % 1000  # Changes every 30 seconds

    total_frames = 480
    frames = []

    # Start in the MIDDLE of the extended array with room for movement
    middle_of_array = len(EXTENDED_COLORS_SMOKE) // 2
    initial_color_start = middle_of_array + \
                          ((time_seed * 7) % len(COMPACT_COLORS_SMOKE))

    # Track base color position and horizontal offset for each row
    row_base_colors = []
    row_horizontal_offsets = []

    for y in range(HEIGHT):
        # Each row moves ONE color in the OPPOSITE direction
        row_base_color = initial_color_start - y

        # Keep within safe bounds (at least 64 pixels from either end)
        row_base_color = max(
            64,
            min(len(EXTENDED_COLORS_SMOKE) - 64, row_base_color),
        )
        row_base_colors.append(row_base_color)
        row_horizontal_offsets.append(0)

    # Create first frame
    display_rows = []
    for y in range(HEIGHT):
        row_colors = render_row_ultra_fast_smoke(
            row_base_colors[y],
            row_horizontal_offsets[y],
            0,
        )
        display_rows.append(row_colors)

    columns = []
    for x in range(WIDTH):
        column_colors = [display_rows[y][x] for y in range(HEIGHT)]
        columns.append(render.Column(
            children = [
                render.Box(width = 1, height = 1, color = c)
                for c in column_colors
            ],
        ))
    frames.append(render.Row(children = columns))

    for frame in range(1, total_frames):
        # Scroll vertically every 2 frames
        if frame % 2 == 0:
            # Back to original rightward drift with bounds checking
            new_bottom_color = row_base_colors[-1] - 1

            # Keep within safe bounds
            new_bottom_color = max(
                64,
                min(len(EXTENDED_COLORS_SMOKE) - 64, new_bottom_color),
            )
            row_base_colors = row_base_colors[1:] + [new_bottom_color]
            row_horizontal_offsets = row_horizontal_offsets[1:] + [0]

        # Update horizontal offsets with moderate amplitudes for visible wave motion
        for y in range(HEIGHT):
            # Halved frame speed for 480 frames
            wave_phase = (frame * 0.04) + (y * 0.12)

            # This is properly centered around 0
            sine_value = math.sin(wave_phase)

            row_seed = (time_seed + y * 31) % 1000
            amplitude_factor = 1.0 + (math.sin(row_seed * 0.1) * 0.3)

            # Moderate amplitudes for visible wave motion with compact bands
            time_amplitude = 3 + (math.sin(frame * 0.0075) *
                                  2)  # 1 to 5 base range
            final_amplitude = time_amplitude * amplitude_factor

            wave_offset = int(sine_value * final_amplitude)

            # Moderate asymmetric clamping for visible waves
            if wave_offset < 0:
                # Leftward motion - allow up to -8
                wave_offset = max(-8, wave_offset)
            else:
                # Rightward motion - limit to +4
                wave_offset = min(4, wave_offset)
            row_horizontal_offsets[y] = wave_offset

        # Render all rows - ULTRA FAST with array slicing
        display_rows = []
        for y in range(HEIGHT):
            row_colors = render_row_ultra_fast_smoke(
                row_base_colors[y],
                row_horizontal_offsets[y],
                frame,
            )
            display_rows.append(row_colors)

        columns = []
        for x in range(WIDTH):
            column_colors = [display_rows[y][x] for y in range(HEIGHT)]
            columns.append(render.Column(
                children = [
                    render.Box(width = 1, height = 1, color = c)
                    for c in column_colors
                ],
            ))
        frames.append(render.Row(children = columns))

    return render.Root(
        delay = 40,
        child = render.Animation(children = frames),
    )

# ============================================================================
# RAINBOW FARTS (VERTICAL V1) - Cloud-like blending version
# ============================================================================

def generate_wave_patterns_farts():
    """Pre-calculate VERY SUBTLE oscillating wave patterns that loop perfectly"""
    patterns = []
    total_frames = 120
    total_length = HEIGHT + total_frames

    for pattern_id in range(4):
        pattern = []
        freq = (0.02 + pattern_id * 0.01) * (2 * math.pi / total_length)
        amp = 2 + pattern_id * 1  # 2 to 5 pixels amplitude
        phase = pattern_id * 1.57

        for i in range(total_length):
            offset = math.sin(i * freq + phase) * amp
            pattern.append(offset)

        patterns.append(pattern)

    return patterns

def generate_color_bands_farts():
    """Generate wider, spaced color bands to avoid chaos"""
    bands = []

    # Use colors from across the full spectrum - every 5th color for variety
    active_colors = [COLORS_FARTS[i] for i in range(0, len(COLORS_FARTS), 5)]

    # Overlapping band spacing for cloud-like blending
    band_spacing = 15

    for band_id in range(len(active_colors)):
        wave_pattern_id = band_id % 4
        wave_start_pos = band_id * 30
        horizontal_start = (band_id * band_spacing) + (band_id * 5)
        band_width = 40 + (band_id % 3) * 10  # 40-60 pixels wide

        bands.append({
            "color": active_colors[band_id],
            "wave_pattern_id": wave_pattern_id,
            "wave_pos": wave_start_pos,
            "horizontal_offset": horizontal_start,
            "width": band_width,
            "brightness_phase": band_id * 0.8,
            "color_shift_phase": band_id * 0.4,
        })

    return bands

def rgb_to_hsv_farts(r, g, b):
    """Convert RGB to HSV color space"""
    r, g, b = r / 255.0, g / 255.0, b / 255.0
    max_val = max(r, g, b)
    min_val = min(r, g, b)
    diff = max_val - min_val

    # Hue
    if diff == 0:
        h = 0
    elif max_val == r:
        h = (60 * ((g - b) / diff) + 360) % 360
    elif max_val == g:
        h = (60 * ((b - r) / diff) + 120) % 360
    else:
        h = (60 * ((r - g) / diff) + 240) % 360

    # Saturation
    s = 0 if max_val == 0 else diff / max_val

    # Value
    v = max_val

    return h, s, v

def hsv_to_rgb_farts(h, s, v):
    """Convert HSV to RGB color space"""
    c = v * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = v - c

    if h < 60:
        r, g, b = c, x, 0
    elif h < 120:
        r, g, b = x, c, 0
    elif h < 180:
        r, g, b = 0, c, x
    elif h < 240:
        r, g, b = 0, x, c
    elif h < 300:
        r, g, b = x, 0, c
    else:
        r, g, b = c, 0, x

    r = int((r + m) * 255)
    g = int((g + m) * 255)
    b = int((b + m) * 255)

    return max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b))

def blend_colors_farts(color1, color2, factor):
    """Blend two hex colors using HSV for better transitions"""

    # Parse hex colors
    r1 = int(color1[1:3], 16)
    g1 = int(color1[3:5], 16)
    b1 = int(color1[5:7], 16)

    r2 = int(color2[1:3], 16)
    g2 = int(color2[3:5], 16)
    b2 = int(color2[5:7], 16)

    # Convert to HSV
    h1, s1, v1 = rgb_to_hsv_farts(r1, g1, b1)
    h2, s2, v2 = rgb_to_hsv_farts(r2, g2, b2)

    # Handle hue wraparound
    hue_diff = h2 - h1
    if hue_diff > 180:
        h2 -= 360
    elif hue_diff < -180:
        h2 += 360

    # Blend in HSV space
    h = h1 + (h2 - h1) * factor
    s = s1 + (s2 - s1) * factor
    v = v1 + (v2 - v1) * factor

    # Ensure hue is in valid range
    h = h % 360

    # Convert back to RGB
    r, g, b = hsv_to_rgb_farts(h, s, v)

    # Convert to hex
    def to_hex(val):
        hex_chars = "0123456789abcdef"
        return hex_chars[val // 16] + hex_chars[val % 16]

    return "#" + to_hex(r) + to_hex(g) + to_hex(b)

def extract_viewport_farts(extended_rows, viewport_offsets):
    """Extract viewport from extended canvas for farts animation"""
    display_rows = []
    for y in range(HEIGHT):
        extended_row = extended_rows[y]
        center_of_canvas = 64
        half_viewport = WIDTH // 2
        viewport_start = center_of_canvas - half_viewport + viewport_offsets[y]
        viewport_start = max(0, min(64, viewport_start))
        viewport_end = viewport_start + WIDTH
        display_row = extended_row[viewport_start:viewport_end]
        display_rows.append(display_row)
    return display_rows

def render_row_farts(bands, wave_patterns, row_y, frame):
    """Render a single row using color anchor points with blending"""
    extended_row = []

    # Calculate anchor positions for each band
    anchors = []
    for band in bands:
        pattern = wave_patterns[band["wave_pattern_id"]]
        wave_offset = pattern[(band["wave_pos"] + frame) % len(pattern)]

        row_offset = row_y * band["wave_pattern_id"] * 1
        anchor_pos = (band["horizontal_offset"] +
                      wave_offset + row_offset) % (WIDTH * 2)

        brightness_factor = 0.75 + 0.25 * math.sin(
            (row_y * 0.3) + (frame * 0.1) + band["brightness_phase"],
        )
        brightness_factor = max(0.5, min(1.0, brightness_factor))

        # Apply both brightness AND hue shifting
        base_color = band["color"]
        base_r = int(base_color[1:3], 16)
        base_g = int(base_color[3:5], 16)
        base_b = int(base_color[5:7], 16)

        # Convert to HSV for hue shifting
        h, s, v = rgb_to_hsv_farts(base_r, base_g, base_b)

        # Add hue shift
        hue_shift = math.sin((row_y * 0.2) + (frame * 0.08) +
                             band["color_shift_phase"]) * 30
        new_h = (h + hue_shift) % 360

        # Apply brightness factor
        new_v = v * brightness_factor

        # Convert back to RGB
        r, g, b = hsv_to_rgb_farts(new_h, s, new_v)

        def to_hex(val):
            hex_chars = "0123456789abcdef"
            return hex_chars[val // 16] + hex_chars[val % 16]

        final_color = "#" + to_hex(r) + to_hex(g) + to_hex(b)

        anchors.append({
            "pos": anchor_pos,
            "color": final_color,
            "influence": 80,
        })

    # For each pixel in the extended row, blend based on distance to anchors
    for x in range(WIDTH * 2):
        # Find the two closest anchors
        distances = []
        for anchor in anchors:
            direct_dist = abs(x - anchor["pos"])
            wrap_dist = min(direct_dist, (WIDTH * 2) - direct_dist)
            distances.append((wrap_dist, anchor))

        # Find the two closest anchors manually
        closest = distances[0]
        second_closest = distances[1]

        for dist_anchor in distances:
            if dist_anchor[0] < closest[0]:
                second_closest = closest
                closest = dist_anchor
            elif dist_anchor[0] < second_closest[0] and dist_anchor != closest:
                second_closest = dist_anchor

        if closest[0] == 0:
            pixel_color = closest[1]["color"]
        elif closest[0] > closest[1]["influence"]:
            fade_factor = max(
                0.3,
                1.0 - (closest[0] / (closest[1]["influence"] * 2)),
            )
            pixel_color = blend_colors_farts(
                "#000000",
                closest[1]["color"],
                fade_factor,
            )
        else:
            dist1 = closest[0]
            dist2 = second_closest[0]

            total_dist = dist1 + dist2
            if total_dist > 0:
                blend_factor = dist1 / total_dist
            else:
                blend_factor = 0.5

            if dist2 <= second_closest[1]["influence"]:
                pixel_color = blend_colors_farts(
                    closest[1]["color"],
                    second_closest[1]["color"],
                    blend_factor,
                )
            else:
                fade_factor = 1.0 - (dist1 / closest[1]["influence"])
                pixel_color = blend_colors_farts(
                    "#000000",
                    closest[1]["color"],
                    max(0.4, fade_factor),
                )

        extended_row.append(pixel_color)

    return extended_row

def rainbow_farts_main():
    """Rainbow Farts - Cloud-like blending version"""

    # Get time-based seed for variation
    now = time.now().unix
    time_seed = (now // 30) % 1000

    # Pre-calculate all wave patterns
    wave_patterns = generate_wave_patterns_farts()

    # Generate color bands with time-based variation
    bands = generate_color_bands_farts()

    # Modify bands based on time seed for variation
    for i, band in enumerate(bands):
        band["horizontal_offset"] = (
            band["horizontal_offset"] + time_seed * (i + 1)
        ) % (WIDTH * 2)
        band["wave_pos"] = (band["wave_pos"] + time_seed // 2) % 150

    total_frames = 480
    frames = []

    # For frame 0: Calculate all HEIGHT rows
    initial_extended_rows = []
    for y in range(HEIGHT):
        extended_row = render_row_farts(bands, wave_patterns, y, 0)
        initial_extended_rows.append(extended_row)

    # Keep track of the viewport position within the extended canvas
    viewport_offsets = [0] * HEIGHT

    # Create first frame by extracting viewport from extended rows
    first_frame_pixels = extract_viewport_farts(
        initial_extended_rows,
        viewport_offsets,
    )

    # Convert to render format
    columns = []
    for x in range(WIDTH):
        column_colors = [first_frame_pixels[y][x] for y in range(HEIGHT)]
        columns.append(render.Column(
            children = [
                render.Box(width = 1, height = 1, color = c)
                for c in column_colors
            ],
        ))
    frames.append(render.Row(children = columns))

    # For subsequent frames: Move viewport within extended canvas
    current_extended_rows = initial_extended_rows[:]
    current_viewport_offsets = viewport_offsets[:]

    for frame in range(1, total_frames):
        # Scroll vertically every 2 frames for faster motion
        if frame % 2 == 0:
            new_extended_row = render_row_farts(
                bands,
                wave_patterns,
                HEIGHT - 1 + frame // 2,
                frame,
            )
            current_extended_rows = current_extended_rows[1:] + [
                new_extended_row,
            ]
            current_viewport_offsets = current_viewport_offsets[1:] + [0]

        # Apply horizontal motion ONLY when vertical moves (sync them)
        if frame % 2 == 0:
            for row_idx in range(len(current_viewport_offsets)):
                wave_phase = (frame * 0.2) + (row_idx * 0.3)
                wave_offset = int(math.sin(wave_phase) * 12)
                max_offset = WIDTH // 2
                current_viewport_offsets[row_idx] = max(
                    -max_offset,
                    min(max_offset, wave_offset),
                )

        # Extract viewport from extended canvas
        display_rows = extract_viewport_farts(
            current_extended_rows,
            current_viewport_offsets,
        )

        # Convert to render format
        columns = []
        for x in range(WIDTH):
            column_colors = [display_rows[y][x] for y in range(HEIGHT)]
            columns.append(render.Column(
                children = [
                    render.Box(width = 1, height = 1, color = c)
                    for c in column_colors
                ],
            ))
        frames.append(render.Row(children = columns))

    return render.Root(
        delay = 40,
        child = render.Animation(children = frames),
    )

# ============================================================================
# RAINBOW DROPS - Water ripple effect with growing drops
# ============================================================================

def distance(x1, y1, x2, y2):
    """Calculate distance between two points"""
    return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))

def abs_val(x):
    """Absolute value function"""
    if x < 0:
        return -x
    return x

def create_drop_trail(center_x, drop_y, _, drop_size, speed_factor, first_ring_color):
    """Create single pixel drop with dynamic comet tail based on speed"""
    drop_pixels = []

    # Use the first ring color as the drop color
    drop_color = first_ring_color

    # Main drop - size based on drop_size parameter (for growth effect)
    if drop_size > 0:
        drop_intensity = min(1.0, drop_size)

        # Apply intensity to the base color
        r = int(int(drop_color[1:3], 16) * drop_intensity)
        g = int(int(drop_color[3:5], 16) * drop_intensity)
        b = int(int(drop_color[5:7], 16) * drop_intensity)

        r = max(0, min(255, r))
        g = max(0, min(255, g))
        b = max(0, min(255, b))

        def to_hex(val):
            hex_chars = "0123456789abcdef"
            return hex_chars[val // 16] + hex_chars[val % 16]

        main_drop_color = "#" + to_hex(r) + to_hex(g) + to_hex(b)
        drop_pixels.append((center_x, drop_y, main_drop_color))

        # Dynamic comet tail - grows with speed during falling phase
        if drop_size >= 1.0:  # Only show tail when fully formed and falling
            # Calculate tail length based on speed (1 to 4 pixels max)
            # Always at least 1 pixel when falling
            tail_length = max(1, int(speed_factor * 4 + 1))

            for i in range(tail_length):
                trail_y = drop_y - i - 1
                if trail_y >= 0:
                    # More visible trail with better intensity
                    # Fade based on distance
                    distance_fade = 1.0 - (i / max(1, tail_length - 1))
                    base_intensity = 0.8  # Higher base intensity for visibility
                    trail_intensity = distance_fade * base_intensity

                    # Apply intensity to the base color
                    r = int(int(drop_color[1:3], 16) * trail_intensity)
                    g = int(int(drop_color[3:5], 16) * trail_intensity)
                    b = int(int(drop_color[5:7], 16) * trail_intensity)

                    r = max(0, min(255, r))
                    g = max(0, min(255, g))
                    b = max(0, min(255, b))

                    trail_color = "#" + to_hex(r) + to_hex(g) + to_hex(b)
                    drop_pixels.append((center_x, trail_y, trail_color))

    return drop_pixels

def create_ripple_ring(center_x, center_y, ring_num, ring_age, ring_colors, ring_widths):
    """Create a single ripple ring with provided color scheme"""
    if ring_age < 0:
        return []

    ring_pixels = []

    # Ring starts at radius 1, expands at 0.6 pixels per frame
    ring_radius = 1 + (ring_age * 0.6)

    # Ring fades out over time
    ring_life = 40  # Ring lasts 40 frames (optimized for file size)
    if ring_age >= ring_life:
        return []

    age_fade = 1.0 - (ring_age / ring_life)

    # First ring 100%, second 95%, third 90%, fourth barely visible
    ring_brightness_multipliers = [1.0, 0.95, 0.90, 0.2]

    # Use ring-specific width
    ring_width = ring_widths[ring_num]

    # Calculate all pixels in this ring
    for y in range(HEIGHT):
        for x in range(WIDTH):
            dist = distance(x, y, center_x, center_y)
            distance_from_ring = abs_val(dist - ring_radius)

            # Check if pixel is within ring
            if ring_radius < 1:
                ring_match = distance_from_ring <= 0.8
            else:
                ring_match = distance_from_ring <= ring_width

            if ring_match:
                # Calculate ring intensity - ALL rings should fade over time
                if ring_radius < 1:
                    if ring_num == 0:
                        ring_intensity = age_fade * 1.0  # First ring starts at 100% but fades with age
                    else:
                        ring_intensity = age_fade * 0.9  # Others start at 90%
                else:
                    # Normal rings: fade from center to edges AND fade with age
                    fade_position = distance_from_ring / ring_width

                    if ring_num == 0:
                        # First ring: edge fade AND age fade
                        # Full brightness with both fades
                        ring_intensity = (1.0 - fade_position) * age_fade * 1.0
                    else:
                        # Other rings: edge fade AND age fade
                        base_intensity = (1.0 - fade_position) * age_fade
                        ring_intensity = base_intensity * 0.9

                # Apply ring-specific brightness multiplier
                final_ring_intensity = ring_intensity * \
                                       ring_brightness_multipliers[ring_num]

                if final_ring_intensity > 0.05:
                    base_color = ring_colors[ring_num]

                    r = int(int(base_color[1:3], 16) * final_ring_intensity)
                    g = int(int(base_color[3:5], 16) * final_ring_intensity)
                    b = int(int(base_color[5:7], 16) * final_ring_intensity)

                    r = max(0, min(255, r))
                    g = max(0, min(255, g))
                    b = max(0, min(255, b))

                    def to_hex(val):
                        hex_chars = "0123456789abcdef"
                        return hex_chars[val // 16] + hex_chars[val % 16]

                    pixel_color = "#" + to_hex(r) + to_hex(g) + to_hex(b)
                    ring_pixels.append(
                        (x, y, pixel_color, final_ring_intensity),
                    )

    return ring_pixels

def blend_colors(color1, color2, weight1, weight2):
    """Blend two colors based on their weights"""
    total_weight = weight1 + weight2
    if total_weight == 0:
        return "#000000"

    # Parse colors
    r1 = int(color1[1:3], 16)
    g1 = int(color1[3:5], 16)
    b1 = int(color1[5:7], 16)

    r2 = int(color2[1:3], 16)
    g2 = int(color2[3:5], 16)
    b2 = int(color2[5:7], 16)

    # Weighted blend
    r = int((r1 * weight1 + r2 * weight2) / total_weight)
    g = int((g1 * weight1 + g2 * weight2) / total_weight)
    b = int((b1 * weight1 + b2 * weight2) / total_weight)

    r = max(0, min(255, r))
    g = max(0, min(255, g))
    b = max(0, min(255, b))

    def to_hex(val):
        hex_chars = "0123456789abcdef"
        return hex_chars[val // 16] + hex_chars[val % 16]

    return "#" + to_hex(r) + to_hex(g) + to_hex(b)

def create_drops_frame(drops, current_frame):
    """Create a single frame with multiple overlapping drops and ripples"""

    # Initialize black screen
    pixels = [["#000000" for _ in range(WIDTH)] for _ in range(HEIGHT)]
    pixel_weights = [[0 for _ in range(WIDTH)] for _ in range(HEIGHT)]

    for drop_id, drop in enumerate(drops):
        drop_start_frame = drop["start_frame"]
        growth_frames = drop["growth_frames"]
        fall_frames = drop["fall_frames"]
        center_x = drop["x"]
        center_y = drop["y"]

        # Drop growth phase - slowly growing at top of screen
        if current_frame >= drop_start_frame and current_frame < drop_start_frame + growth_frames:
            growth_frame = current_frame - drop_start_frame
            drop_size = growth_frame / growth_frames  # 0.0 to 1.0
            drop_y = 0  # Always at top during growth

            # Add growing drop pixels (no tail during growth)
            drop_pixels = create_drop_trail(
                center_x,
                drop_y,
                drop_id,
                drop_size,
                0.0,
                drop["ring_colors"][0],
            )
            for px, py, color in drop_pixels:
                if px >= 0 and px < WIDTH and py >= 0 and py < HEIGHT:
                    pixels[py][px] = color
                    pixel_weights[py][px] = 1.0  # Drop always wins

            # Drop falling phase - gentler gravity acceleration with dynamic tail
        elif current_frame >= drop_start_frame + growth_frames and current_frame < drop_start_frame + growth_frames + fall_frames:
            fall_frame = current_frame - (drop_start_frame + growth_frames)

            # Gentler physics: start slow, accelerate more gradually
            normalized_time = fall_frame / fall_frames

            # Apply gentler acceleration (less aggressive than pure quadratic)
            linear_component = normalized_time * 0.3  # 30% linear motion
            gravity_component = normalized_time * normalized_time * 0.7  # 70% gravity
            total_progress = linear_component + gravity_component

            drop_y = int(center_y * total_progress)

            # Calculate speed factor for comet tail (0.0 to 1.0)
            speed_factor = normalized_time * normalized_time  # Quadratic speed buildup

            # Add drop trail pixels with dynamic comet tail
            drop_pixels = create_drop_trail(
                center_x,
                drop_y,
                drop_id,
                1.0,
                speed_factor,
                drop["ring_colors"][0],
            )
            for px, py, color in drop_pixels:
                if px >= 0 and px < WIDTH and py >= 0 and py < HEIGHT:
                    pixels[py][px] = color
                    pixel_weights[py][px] = 1.0  # Drop always wins

            # Ripple phase
        elif current_frame >= drop_start_frame + growth_frames + fall_frames:
            ripple_start_frame = drop_start_frame + growth_frames + fall_frames
            ripple_frame = current_frame - ripple_start_frame

            # Create all 4 rings for this drop
            for ring_num in range(4):
                ring_birth_frame = ring_num * 8  # New ring every 8 frames
                ring_age = ripple_frame - ring_birth_frame

                if ring_age >= 0:
                    ring_pixels = create_ripple_ring(
                        center_x,
                        center_y,
                        ring_num,
                        ring_age,
                        drop["ring_colors"],
                        drop["ring_widths"],
                    )

                    # Blend ring pixels with existing pixels
                    for px, py, color, intensity in ring_pixels:
                        if px >= 0 and px < WIDTH and py >= 0 and py < HEIGHT:
                            current_weight = pixel_weights[py][px]

                            if current_weight > 0:
                                # Blend the colors additively for overlapping effects
                                pixels[py][px] = blend_colors(
                                    pixels[py][px],
                                    color,
                                    current_weight,
                                    intensity,
                                )
                                pixel_weights[py][px] = min(
                                    1.0,
                                    current_weight + intensity * 0.7,
                                )
                            else:
                                # No existing color, use this one
                                pixels[py][px] = color
                                pixel_weights[py][px] = intensity

    return pixels

def find_valid_x_position(preferred_x, existing_positions, min_spacing):
    """Helper function to find valid X position with minimum spacing"""

    # Try the preferred position first
    valid = True
    for existing_x in existing_positions:
        if abs_val(preferred_x - existing_x) < min_spacing:
            valid = False
            break
    if valid:
        return preferred_x

    # If preferred position conflicts, try nearby positions
    for offset in range(1, 32):  # Try up to 32 pixels away
        # Try right side first
        test_x = preferred_x + offset
        if test_x < WIDTH:
            valid = True
            for existing_x in existing_positions:
                if abs_val(test_x - existing_x) < min_spacing:
                    valid = False
                    break
            if valid:
                return test_x

        # Try left side
        test_x = preferred_x - offset
        if test_x >= 0:
            valid = True
            for existing_x in existing_positions:
                if abs_val(test_x - existing_x) < min_spacing:
                    valid = False
                    break
            if valid:
                return test_x

    # Fallback: return preferred position anyway
    return preferred_x

def rainbow_drops_main():
    """Rainbow Drops - Water ripple effect with growing drops"""

    # Get time-based seed for variation
    now = time.now().unix
    time_seed = (now // 30) % 1000

    # Define all available color schemes
    color_schemes = [
        # Fire gradient: Red to Orange to Yellow
        (["#ff0000", "#ff4000", "#ff8000", "#ffcc00"], [6.0, 4.5, 3.5, 2.5]),
        # Water gradient: Cyan to Blue to Purple
        (["#00ffff", "#0099ff", "#0066ff", "#6600ff"], [4.0, 4.0, 4.0, 4.0]),
        # Monochrome: White to Silver to Gray
        (["#ffffff", "#cccccc", "#999999", "#666666"], [7.0, 5.5, 4.0, 2.5]),
        # Nature: Green to Lime to Yellow-Green
        (["#00ff00", "#66ff00", "#99ff00", "#ccff00"], [3.5, 5.0, 3.5, 5.0]),
        # Sunset: Purple to Pink to Rose
        (["#8a2be2", "#da70d6", "#ff69b4", "#ff1493"], [5.0, 3.0, 6.0, 4.0]),
    ]

    # Create randomized list of color scheme indices
    scheme_indices = [0, 1, 2, 3, 4]

    # Simple shuffle using time_seed
    for i in range(5):
        j = (time_seed * (i + 13)) % 5
        scheme_indices[i], scheme_indices[j] = scheme_indices[j], scheme_indices[i]

    # Create five drops with growth and consistent fall speeds
    drops = []
    drop_positions = []  # Track X positions to ensure spacing

    # All drops fall at same speed (12 frames)
    consistent_fall_frames = 12

    # Create 5 drops with randomized colors and spacing
    for i in range(5):
        drop_delay = i * 2 + ((time_seed * (i + 7)) % 6)  # Staggered delays
        preferred_x = (8 + i * 12) + ((time_seed * (i + 3)) %
                                      8)  # Spread across width
        drop_x = find_valid_x_position(preferred_x, drop_positions, 3)
        drop_positions.append(drop_x)
        drop_y = 8 + ((time_seed * (i + 5)) % 20)  # Random heights
        growth_frames = 6 + ((time_seed * (i + 11)) %
                             8)  # Variable growth times
        drop_colors, drop_widths = color_schemes[scheme_indices[i]]
        drops.append({
            "x": drop_x,
            "y": drop_y,
            "start_frame": drop_delay,
            "growth_frames": growth_frames,
            "fall_frames": consistent_fall_frames,
            "ring_colors": drop_colors,
            "ring_widths": drop_widths,
        })

    # Calculate total animation length - optimized for Tidbyt limits
    total_frames = 120  # Reduced for file size limits

    frames = []

    for frame in range(total_frames):
        pixels = create_drops_frame(drops, frame)

        # Convert to render format
        columns = []
        for x in range(WIDTH):
            column_colors = [pixels[y][x] for y in range(HEIGHT)]
            columns.append(render.Column(
                children = [
                    render.Box(width = 1, height = 1, color = c)
                    for c in column_colors
                ],
            ))
        frames.append(render.Row(children = columns))

    return render.Root(
        delay = 50,  # Slightly faster for more dynamic feel
        child = render.Animation(children = frames),
    )

# ============================================================================
# MAIN FUNCTION
# ============================================================================

def main(config):
    style = config.get("style", "drops")
    original_style = style

    # Handle random selection
    if style == "random":
        # Use time-based selection - changes every minute
        now = time.now().unix
        minute_selector = int(now / 60) % 4  # 0, 1, 2, or 3
        if minute_selector == 0:
            style = "magic"
        elif minute_selector == 1:
            style = "smoke"
        elif minute_selector == 2:
            style = "drops"
        else:
            style = "farts"

    # Debug: Print which style is being used (visible in pixlet serve output)
    print("Config style:", original_style, "-> Running:", style)

    if style == "smoke":
        return rainbow_smoke_main()
    elif style == "drops":
        return rainbow_drops_main()
    elif style == "farts":
        return rainbow_farts_main()
    else:
        return rainbow_magic_main()
