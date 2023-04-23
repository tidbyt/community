"""
Applet: Colorful Clock
Summary: Colorful Clock
Description: Shows the time like on an old wall clock.
Author: LukiLeu
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Define some constants
DEFAULT_LOCATION = {
    "lat": 46.94668030086369,
    "lng": 7.421647969798374,
    "locality": "Bern",
}

DEFAULT_COLORS = {
    "Black": "#000",
    "Red 100%": "#f00",
    "Green 20%": "#020",
    "Blue 100%": "#00f",
    "Yellow 100%": "#ff0",
    "Cyan 100%": "#0ff",
    "Magenta 100%": "#f0f",
}

DEFAULT_TIMEZONE = "Europe/Zurich"

# This function renders a single pixel
def set_pixel(image, x, y, color):
    # Check boundaries
    if (x > 63) or (x < 0):
        return
    if (y > 31) or (y < 0):
        return

    # Set the pixel
    image[x][y] = color

# Renders a line
def render_line_angle(image, x, y, r, a, colorborder, colorfill, widthborder):
    for rad in range(0, int((r - widthborder) * 10)):
        cx = int(math.round(x + (rad / 10.0 * math.cos(math.radians(a)))))
        cy = int(math.round(y + (rad / 10.0 * math.sin(math.radians(a)))))
        set_pixel(image, cx, cy, colorfill)
    for rad in range(int((r - widthborder) * 10), int(r * 10)):
        cx = int(math.round(x + (rad / 10.0 * math.cos(math.radians(a)))))
        cy = int(math.round(y + (rad / 10.0 * math.sin(math.radians(a)))))
        set_pixel(image, cx, cy, colorborder)
    return image

# This function renders a filled circle
def render_circle(image, x, y, r, colorborder, colorfill, widthborder):
    for a in range(0, 360):
        render_line_angle(image, x, y, r, a, colorborder, colorfill, widthborder)

    # return image

# Renders the final image
def render_image(image):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(
                        height = 1,
                        width = 1,
                        color = image[x][y],
                    )
                    for x in range(64)
                ],
            )
            for y in range(32)
        ],
    )

def render_clock(current_time, color_background, color_border, color_clock, color_marks, color_hour, color_minute, color_second):
    image = [[color_background for y in range(32)] for x in range(64)]
    render_circle(image, 31.5, 15.5, 15.5, color_border, color_clock, 1)
    for h in range(1, 13):
        render_line_angle(image, 31.5, 15.5, 15.5, 360 / 12 * h - 1, color_marks, color_clock, 1)

    hh = int(current_time.format("15"))
    mm = int(current_time.format("04"))
    ss = int(current_time.format("05"))

    render_line_angle(image, 31.5, 15.5, 7, 360 / 12 * (hh % 12) + 270, color_hour, color_hour, 0)
    render_line_angle(image, 31.5, 15.5, 9, 360 / 60 * (mm % 60) + 270, color_minute, color_minute, 0)
    render_line_angle(image, 31.5, 15.5, 11, 360 / 60 * (ss % 60) + 270, color_second, color_second, 0)

    return render_image(image)

def main(config):
    # Get the colors
    color_background = config.get("color_background", DEFAULT_COLORS.get("Black"))
    color_border = config.get("color_border", DEFAULT_COLORS.get("Red 100%"))
    color_clock = config.get("color_clock", DEFAULT_COLORS.get("Green 20%"))
    color_marks = config.get("color_marks", DEFAULT_COLORS.get("Blue 100%"))
    color_hour = config.get("color_hour", DEFAULT_COLORS.get("Magenta 100%"))
    color_minute = config.get("color_minute", DEFAULT_COLORS.get("Yellow 100%"))
    color_second = config.get("color_second", DEFAULT_COLORS.get("Cyan 100%"))

    # Get the current time in 24 hour format
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))  # Utilize special timezone variable

    # Get the current time
    current_time = time.parse_time(time.now().in_location(timezone).format("2006-01-02 15:04:05"), format = "2006-01-02 15:04:05", location = timezone)

    # Initialize the empty list
    clock_frames = []

    # Render 30 seconds
    for _ in range(0, 30):
        clock_frames.append(
            render_clock(current_time, color_background, color_border, color_clock, color_marks, color_hour, color_minute, color_second),
        )
        current_time = current_time + time.second

    # Return the clock
    return render.Root(
        delay = 1000,
        max_age = 120,
        child = render.Box(
            child = render.Animation(
                children = clock_frames,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location defining the timezone.",
                icon = "locationDot",
            ),
            schema.Color(
                id = "color_background",
                name = "Color Background",
                icon = "brush",
                desc = "Color of the background",
                default = DEFAULT_COLORS.get("Black"),
            ),
            schema.Color(
                id = "color_border",
                name = "Color Border",
                icon = "brush",
                desc = "Color of the border",
                default = DEFAULT_COLORS.get("Red 100%"),
            ),
            schema.Color(
                id = "color_clock",
                name = "Color Clock",
                icon = "brush",
                desc = "Color of the clock",
                default = DEFAULT_COLORS.get("Green 20%"),
            ),
            schema.Color(
                id = "color_marks",
                name = "Color Hour Markers",
                icon = "brush",
                desc = "Color of the hour markers",
                default = DEFAULT_COLORS.get("Blue 100%"),
            ),
            schema.Color(
                id = "color_hour",
                name = "Color Hour Finger",
                icon = "brush",
                desc = "Color of the hour finger",
                default = DEFAULT_COLORS.get("Cyan 100%"),
            ),
            schema.Color(
                id = "color_minute",
                name = "Color Minute Finger",
                icon = "brush",
                desc = "Color of the minute finger",
                default = DEFAULT_COLORS.get("Yellow 100%"),
            ),
            schema.Color(
                id = "color_second",
                name = "Color Second Finger",
                icon = "brush",
                desc = "Color of the second finger",
                default = DEFAULT_COLORS.get("Magenta 100%"),
            ),
        ],
    )
