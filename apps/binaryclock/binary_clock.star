"""
Applet: Binary Clock
Summary: Shows a binary clock
Description: This app show the current date and time in a binary format.
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

DEFAULT_TIMEZONE = "Europe/Zurich"

MAX_VALUE = 2048

DEFAULT_COLORS = {
    "Black": "#000",
    "White 100%": "#fff",
    "White 50%": "#777",
    "White 20%": "#222",
    "Red 100%": "#f00",
    "Red 50%": "#700",
    "Red 20%": "#200",
    "Green 100%": "#0f0",
    "Green 50%": "#070",
    "Green 20%": "#020",
    "Blue 100%": "#00f",
    "Blue 50%": "#007",
    "Blue 20%": "#002",
    "Yellow 100%": "#ff0",
    "Yellow 50%": "#770",
    "Yellow 20%": "#220",
    "Cyan 100%": "#0ff",
    "Cyan 50%": "#077",
    "Cyan 20%": "#022",
    "Magenta 100%": "#f0f",
    "Magenta 50%": "#707",
    "Magenta 20%": "#202",
}

DEFAULT_BARWIDTH = {
    "1 Pixel": "1",
    "2 Pixel": "2",
    "3 Pixel": "3",
    "4 Pixel": "4",
    "5 Pixel": "5",
    "6 Pixel": "6",
    "7 Pixel": "7",
    "8 Pixel": "8",
    "9 Pixel": "9",
    "10 Pixel": "10",
}

DEFAULT_BARHEIGHT = {
    "1 Pixel": "1",
    "2 Pixel": "2",
    "3 Pixel": "3",
}

# Draw the color bar
def render_bar(value, color_dots, color_dots_bg, width_bar, height_bar):
    children_bar = []
    for _ in range(0, int(math.log(MAX_VALUE, 2))):
        if int(math.mod(value, 2)) == 1:
            children_bar.append(
                render.Box(width = width_bar, height = height_bar, color = color_dots),
            )
        else:
            children_bar.append(
                render.Box(width = width_bar, height = height_bar, color = color_dots_bg),
            )
        value = value / 2

    return render.Column(
        children = reversed(children_bar),
    )

# Render a single column
def render_col(value, text, color_text, color_dots, color_dots_bg, width_bar, height_bar, show_text):
    if (True == show_text) and (height_bar <= 2):
        return render.Column(
            children = [
                render.Box(
                    height = 20 if height_bar == 1 else 25,
                    width = 5 if width_bar <= 5 else width_bar,
                    child = render_bar(value, color_dots, color_dots_bg, width_bar, height_bar),
                ),
                render.Box(
                    height = 8 if height_bar == 1 else 7,
                    width = 6 if width_bar <= 5 else width_bar,
                    child = render.Text(
                        font = "tb-8",
                        content = text,
                        color = color_text,
                    ),
                ),
            ],
        )
    else:
        return render.Column(
            children = [
                render.Box(
                    height = 32,
                    width = 5 if width_bar <= 5 else width_bar,
                    child = render_bar(value, color_dots, color_dots_bg, width_bar, height_bar),
                ),
            ],
        )

# Render a single image
def render_image(current_time, color_text, color_dots, color_dots_bg, width_bar, height_bar, show_text):
    yy = int(current_time.format("2006"))
    mo = int(current_time.format("01"))
    dd = int(current_time.format("02"))
    hh = int(current_time.format("15"))
    mm = int(current_time.format("04"))
    ss = int(current_time.format("05"))

    # Render the six columns
    return render.Row(
        expanded = True if width_bar <= 9 else False,
        main_align = "space_evenly" if width_bar <= 7 else "space_between",
        children = [
            #render.Box(width=1, height=32),
            render_col(yy, "Y", color_text, color_dots, color_dots_bg, width_bar, height_bar, show_text),
            render_col(mo, "M", color_text, color_dots, color_dots_bg, width_bar, height_bar, show_text),
            render_col(dd, "D", color_text, color_dots, color_dots_bg, width_bar, height_bar, show_text),
            render_col(hh, "H", color_text, color_dots, color_dots_bg, width_bar, height_bar, show_text),
            render_col(mm, "M", color_text, color_dots, color_dots_bg, width_bar, height_bar, show_text),
            render_col(ss, "S", color_text, color_dots, color_dots_bg, width_bar, height_bar, show_text),
            #render.Box(width=1, height=32),
        ],
    )

def main(config):
    # Get the colors
    color_text = config.get("color_text", DEFAULT_COLORS.get("White 100%"))
    color_dots = config.get("color_dots", DEFAULT_COLORS.get("Red 100%"))
    color_dots_bg = config.get("color_dots_bg", DEFAULT_COLORS.get("White 20%"))
    width_bar = int(config.get("width_bar", DEFAULT_BARWIDTH.get("3 Pixel")))
    heigth_bar = int(config.get("heigth_bar", DEFAULT_BARHEIGHT.get("1 Pixel")))
    show_text = config.bool("show_text", True)

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
            render_image(current_time, color_text, color_dots, color_dots_bg, width_bar, heigth_bar, show_text),
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
            schema.Dropdown(
                id = "color_text",
                name = "Color Text",
                icon = "brush",
                desc = "Color of the text",
                options = [
                    schema.Option(display = color_name, value = color_value)
                    for (color_name, color_value) in DEFAULT_COLORS.items()
                ],
                default = DEFAULT_COLORS.get("White 100%"),
            ),
            schema.Dropdown(
                id = "color_dots",
                name = "Color Active Dots",
                icon = "brush",
                desc = "Color of the active dots",
                options = [
                    schema.Option(display = color_name, value = color_value)
                    for (color_name, color_value) in DEFAULT_COLORS.items()
                ],
                default = DEFAULT_COLORS.get("Red 100%"),
            ),
            schema.Dropdown(
                id = "color_dots_bg",
                name = "Color Inactive Dots",
                icon = "brush",
                desc = "Color of the inactive dots",
                options = [
                    schema.Option(display = color_name, value = color_value)
                    for (color_name, color_value) in DEFAULT_COLORS.items()
                ],
                default = DEFAULT_COLORS.get("White 20%"),
            ),
            schema.Dropdown(
                id = "width_bar",
                name = "Width Bar",
                icon = "textWidth",
                desc = "Width of the individual bars",
                options = [
                    schema.Option(display = width_name, value = width_value)
                    for (width_name, width_value) in DEFAULT_BARWIDTH.items()
                ],
                default = DEFAULT_BARWIDTH.get("3 Pixel"),
            ),
            schema.Dropdown(
                id = "heigth_bar",
                name = "Height Bar",
                icon = "textHeight",
                desc = "Height of the individual bars",
                options = [
                    schema.Option(display = height_name, value = height_value)
                    for (height_name, height_value) in DEFAULT_BARHEIGHT.items()
                ],
                default = DEFAULT_BARHEIGHT.get("1 Pixel"),
            ),
            schema.Toggle(
                id = "show_text",
                name = "Show Text",
                desc = "Show the text labels below the bars.",
                icon = "textSlash",
                default = True,
            ),
        ],
    )
