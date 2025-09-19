"""
Applet: Rainbows
Summary: Colorful wave animations.
Description: Choose between Rainbow Magic, Rainbow Smoke, Rainbow Drops (water ripples), or Random.
Author: andersheie
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "style",
                name = "Animation Style",
                desc = "Choose your preferred wave animation",
                icon = "palette",
                default = "flag",
                options = [
                    schema.Option(
                        display = "Rainbow Splats (Default)",
                        value = "flag",
                    ),
                    schema.Option(
                        display = "Rainbow Magic",
                        value = "magic",
                    ),
                    schema.Option(
                        display = "Rainbow Smoke",
                        value = "smoke",
                    ),
                    schema.Option(
                        display = "Rainbow Drops",
                        value = "drops",
                    ),
                    schema.Option(
                        display = "Rainbow Farts",
                        value = "farts",
                    ),
                    schema.Option(
                        display = "Random",
                        value = "random",
                    ),
                ],
            ),
        ],
    )

# Fast hex conversion
HEX_CHARS = "0123456789abcdef"

def to_hex_fast(val):
    """Fast hex conversion matching original"""
    return HEX_CHARS[val // 16] + HEX_CHARS[val % 16]

def get_cached_animation(style):
    """Get cached animation frames for the given style"""
    cache_key = "rainbows_pixels_%s" % style
    cached_pixels = cache.get(cache_key)

    if cached_pixels != None:
        # Reconstruct frames from cached pixel data
        pixel_data = json.decode(cached_pixels)
        return build_frames_from_pixels(pixel_data)

    # Generate new pixel data
    if style == "flag":
        pixel_data = rainbow_flag_pixels()
    else:
        # For other styles, use flag for now
        pixel_data = rainbow_flag_pixels()

    # Cache pixel data as JSON for 1 hour (3600 seconds)
    cache.set(cache_key, json.encode(pixel_data), ttl_seconds = 3600)
    return build_frames_from_pixels(pixel_data)

def build_frames_from_pixels(pixel_data):
    """Build render frames from pixel color data"""
    frames = []
    for frame_pixels in pixel_data:
        rows = []
        for row_pixels in frame_pixels:
            pixels_in_row = []
            for hex_color in row_pixels:
                pixels_in_row.append(render.Box(width = 1, height = 1, color = hex_color))
            rows.append(render.Row(children = pixels_in_row))
        frame_render = render.Column(children = rows)
        frames.append(frame_render)
    return frames

def rainbow_flag_pixels():
    """Generate Paint Splat pixel color data"""

    # Bright rainbow colors for paint
    paint_colors = ["#ff0000", "#ff8000", "#ffff00", "#00ff00", "#0080ff", "#8000ff", "#ff0080"]

    # Display dimensions
    width = 64
    height = 32

    # Pre-generate all paint splats
    splats = []

    # Create 25 main splats
    num_splats = 25

    for i in range(num_splats):
        # Randomization
        base_rand = i * 7919 + 1237
        rand1 = (base_rand * 139) % 9973
        rand2 = (base_rand * 277) % 8971
        rand3 = (base_rand * 419) % 7919
        rand4 = (base_rand * 563) % 6857
        rand5 = (base_rand * 701) % 5813

        # Staggered birth frames (0-35, ensuring 5+ frames to fade)
        birth_frame = rand5 % 35

        # Random position anywhere on screen (including borders)
        center_x = rand1 % width
        center_y = rand2 % height

        # Random color - use a different seed for better distribution
        color_idx = (rand3 + i * 13) % len(paint_colors)
        color = paint_colors[color_idx]
        r = int(color[1:3], 16)
        g = int(color[3:5], 16)
        b = int(color[5:7], 16)

        # Random splat size (3-12 pixels)
        splat_size = (rand4 % 10) + 3

        # Create irregular splat shape - each splat has unique pixels
        splat_pixels = []

        # Main oblong shape
        for dy in range(-splat_size, splat_size + 1):
            for dx in range(-splat_size, splat_size + 1):
                px = center_x + dx
                py = center_y + dy

                # Skip out of bounds
                if px < 0 or px >= width or py < 0 or py >= height:
                    continue

                # Simple smooth circular splats - no randomness to avoid lines
                distance = math.sqrt(dx * dx + dy * dy)

                # Single smooth gradient from center to edge - no tiers
                if distance <= splat_size:
                    intensity = 1.0 - (distance / splat_size)  # Smooth 1.0 to 0.0
                    if intensity > 0.1:  # Skip very dim pixels
                        splat_pixels.append([px, py, intensity])

        # Add a few side splats (2-4 small satellite splats)
        num_side_splats = (rand4 % 3) + 2
        for side_idx in range(num_side_splats):
            side_rand1 = (base_rand * (side_idx + 7)) % 8971
            side_rand2 = (base_rand * (side_idx + 11)) % 6857

            # Side splat position (3-8 pixels away from main)
            side_distance = (side_rand1 % 6) + 3
            side_angle = side_rand2 % 8  # 8 directions

            if side_angle == 0:
                side_dx, side_dy = side_distance, 0
            elif side_angle == 1:
                side_dx, side_dy = side_distance, side_distance
            elif side_angle == 2:
                side_dx, side_dy = 0, side_distance
            elif side_angle == 3:
                side_dx, side_dy = -side_distance, side_distance
            elif side_angle == 4:
                side_dx, side_dy = -side_distance, 0
            elif side_angle == 5:
                side_dx, side_dy = -side_distance, -side_distance
            elif side_angle == 6:
                side_dx, side_dy = 0, -side_distance
            else:
                side_dx, side_dy = side_distance, -side_distance

            side_center_x = center_x + side_dx
            side_center_y = center_y + side_dy

            # Small side splat (1-3 pixels)
            side_size = (side_rand1 % 3) + 1
            for sdy in range(-side_size, side_size + 1):
                for sdx in range(-side_size, side_size + 1):
                    spx = side_center_x + sdx
                    spy = side_center_y + sdy

                    if spx >= 0 and spx < width and spy >= 0 and spy < height:
                        side_dist = math.sqrt(sdx * sdx + sdy * sdy)
                        if side_dist <= side_size:
                            side_intensity = (1.0 - (side_dist / side_size)) * 0.7
                            splat_pixels.append([spx, spy, side_intensity])

        # Fade duration - early splats get longer fades, all finish at frame 40
        fade_duration = 40 - birth_frame  # Always fade to exactly frame 40

        splats.append([splat_pixels, r, g, b, birth_frame, fade_duration])

    frames = []

    # Create 40 frames
    for frame in range(40):
        # Create frame canvas
        canvas = []
        for y in range(height):
            row = []
            for x in range(width):
                row.append([0.0, 0.0, 0.0])  # RGB float values for better mixing
            canvas.append(row)

        # Draw all active splats
        for splat_pixels, splat_r, splat_g, splat_b, birth_frame, fade_duration in splats:
            # Calculate age and fade
            age = frame - birth_frame
            if age >= fade_duration or age < 0:
                continue  # Skip expired or not-yet-born splats

            # Fade factor (1.0 = full bright, 0.0 = transparent)
            fade_factor = 1.0 - (age / fade_duration)

            # Draw each pixel in the splat
            for px, py, intensity in splat_pixels:
                final_intensity = intensity * fade_factor

                # Mix colors (additive blending)
                current_r, current_g, current_b = canvas[py][px]

                # Simple additive blending - let colors mix naturally
                new_r = current_r + (splat_r * final_intensity * 0.6)
                new_g = current_g + (splat_g * final_intensity * 0.6)
                new_b = current_b + (splat_b * final_intensity * 0.6)

                # Clamp to 255
                new_r = min(255, new_r)
                new_g = min(255, new_g)
                new_b = min(255, new_b)

                canvas[py][px] = [new_r, new_g, new_b]

        # Convert canvas to hex color data
        frame_pixels = []
        for y in range(height):
            row_pixels = []
            for x in range(width):
                pixel_r, pixel_g, pixel_b = canvas[y][x]

                # Convert to integers
                final_r = int(pixel_r)
                final_g = int(pixel_g)
                final_b = int(pixel_b)

                if final_r > 0 or final_g > 0 or final_b > 0:
                    hex_color = "#" + to_hex_fast(final_r) + to_hex_fast(final_g) + to_hex_fast(final_b)
                else:
                    hex_color = "#000000"

                row_pixels.append(hex_color)

            frame_pixels.append(row_pixels)

        frames.append(frame_pixels)

    return frames

def main(config):
    style = config.get("style", "flag")
    original_style = style

    # Handle random selection
    if style == "random":
        # Use time-based selection - changes every minute
        now = time.now().unix
        minute_selector = int(now / 60) % 5  # 0, 1, 2, 3, or 4
        if minute_selector == 0:
            style = "flag"
        elif minute_selector == 1:
            style = "magic"
        elif minute_selector == 2:
            style = "smoke"
        elif minute_selector == 3:
            style = "drops"
        else:
            style = "farts"

    # Debug: Print which style is being used (visible in pixlet serve output)
    print("Config style:", original_style, "-> Running:", style)

    # Get cached animation frames
    frames = get_cached_animation(style)

    return render.Root(
        child = render.Animation(children = frames),
    )
