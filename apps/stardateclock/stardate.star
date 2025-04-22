"""
Applet: Stardate Clock
Summary: TNG stardate clock
Description: An LCARS-like clock displaying the current stardate in a TNG-style format.
Author: Christian Dannie Storgaard (Cybolic)
"""
# This is compatible with the system described my Mike and Denise Okuda in their book "Star Trek: Chronology"
# but based on current local time in order to be usable as a clock

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Constants
DEFAULT_TIMEZONE = "UTC"
TEXT_FONT = "tb-8"
STARDATE_FONT = "6x13"
STARDATE_FONT_SIZE = 13
DEFAULT_COLOR_TEXT = "#F5F6FA"
DEFAULT_COLOR_EPOCH = "#9944FF"
DEFAULT_COLOR_DATE = "#EE7F31"
DEFAULT_COLOR_FRACTION = "#33CC99"
IMAGE_COLOR_TOP = "#6e8fff"
IMAGE_COLOR_BOTTOM = "#7f7f7f"

DEFAULT_LOCATION = json.encode({
    "name": "Earth",
    "timezone": DEFAULT_TIMEZONE,
    "locality": "Earth",
})

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))

    timezone = location["timezone"]

    now = time.now().in_location(timezone)

    stardate = calculate_stardate(now)

    use_color = config.bool("use_color", True)

    color_text = config.get("color_text", DEFAULT_COLOR_TEXT)
    color_epoch = config.get("color_epoch", DEFAULT_COLOR_EPOCH)

    d_color_epoch = color_epoch if use_color else color_text
    d_color_date = config.get("color_date", DEFAULT_COLOR_DATE) if use_color else color_text
    d_color_dot = IMAGE_COLOR_BOTTOM if use_color else color_text
    d_color_fraction = config.get("color_fraction", DEFAULT_COLOR_FRACTION) if use_color else color_text

    stardate_display = render.Row(
        children = [
            render.Padding(pad = (1, int(STARDATE_FONT_SIZE / 2), 1, 0), child = render.Box(width = 2, height = 1, color = d_color_epoch)),
            render.Text(stardate[:3], font = STARDATE_FONT, color = d_color_epoch),
            render.Text(stardate[3:6], font = STARDATE_FONT, color = d_color_date),
            # render a small box to serve as the full stop separator
            render.Padding(pad = (0, STARDATE_FONT_SIZE - 3, 1, 0), child = render.Box(width = 1, height = 1, color = d_color_dot)),
            render.Text(stardate[7:], font = STARDATE_FONT, color = d_color_fraction),
        ],
    )

    location_text = config.get("location_text")
    if (not location_text):
        if "locality" in location:
            location_text = location["locality"]
        else:
            location_text = location["name"] if "name" in location else "Earth"

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(
                    src = BACKGROUND_IMG,
                ),
                render.Padding(
                    pad = (0, 1, 0, 1),
                    child = render.Box(
                        child = render.Column(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                # Stardate display
                                render.Padding(
                                    pad = (0, 9, 0, 0),
                                    child = stardate_display,
                                ),
                                # Location text
                                render.Row(
                                    main_align = "start",
                                    expanded = True,
                                    children = [render.Padding(
                                        pad = (6, 0, 0, 0),
                                        child = render.Text(location_text, font = TEXT_FONT, color = IMAGE_COLOR_BOTTOM),
                                    )],
                                ),
                            ],
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, 10, 0, 0),
                    child = render.Box(
                        width = 2,
                        height = STARDATE_FONT_SIZE,
                        color = color_epoch,
                    ),
                ),
            ],
        ),
    )

def calculate_stardate(now):
    # TNG-style stardate calculation
    base_year = 2323
    year = now.year
    day_of_year = calculate_day_of_year(now)
    days_in_year = 365 if not is_leap_year(year) else 366

    epoch = int(abs(year - base_year))
    fraction_of_year = day_of_year * 1000 // days_in_year
    fraction_of_day = (now.hour * 3600 + now.minute * 60 + now.second) * 1000 // 86400

    stardate = str(epoch) + zero_pad(fraction_of_year, 3) + "." + zero_pad(fraction_of_day, 3)

    return stardate

def zero_pad(number, width):
    return "0" * (width - len(str(number))) + str(number)

def calculate_day_of_year(date):
    days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if is_leap_year(date.year):
        days_in_month[1] = 29

    day_of_year = date.day
    for month in range(date.month - 1):
        day_of_year += days_in_month[month]

    return day_of_year

def is_leap_year(year):
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for the stardate calculation",
                icon = "locationDot",
            ),
            schema.Text(
                id = "location_text",
                name = "Location text",
                desc = "Custom location text (optional)",
                icon = "tag",
                default = "",
            ),
            schema.Toggle(
                id = "use_color",
                name = "Use Color Coding",
                desc = "Enable color coding for different parts of the stardate",
                icon = "paintbrush",
                default = True,
            ),
            schema.Color(
                id = "color_text",
                name = "Text Color",
                desc = "Color for texts",
                icon = "palette",
                default = DEFAULT_COLOR_TEXT,
            ),
            schema.Color(
                id = "color_epoch",
                name = "Epoch Color",
                desc = "Color for the epoch part of the stardate",
                icon = "palette",
                default = DEFAULT_COLOR_EPOCH,
            ),
            schema.Color(
                id = "color_date",
                name = "Date Color",
                desc = "Color for the date part of the stardate",
                icon = "palette",
                default = DEFAULT_COLOR_DATE,
            ),
            schema.Color(
                id = "color_fraction",
                name = "Fraction Color",
                desc = "Color for the fraction part of the stardate",
                icon = "palette",
                default = DEFAULT_COLOR_FRACTION,
            ),
        ],
    )

BACKGROUND_IMG = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAABIklEQVRo3u2UsW7CQAyG/1y753akUy7wCB2Yqhu78xqIudtRJjZeh27AVCEeAaQoUp7DXRoUIsIVkHKDbel0TuxE8uffTgDQ+OMLg5HDYPgObvbaLr467VAdN/hZex4AmsXvvxe9F35YEt4+k7NfW/NdO971HPrftXzMVkSzFdFkuiUAvZ7Dki7uLv/R+5ZfH1WDqI6baDK86EjPdgYQY+absrw1Il0j85/8UFzFXkIhCO1i780PxaMCCHWr1xGI2f1ndsC937ehJ3/bkK0pMDcBIAAEgAAQAAJAAAgAASAABIAA4AnAew/vvShAAHAH4JzjDcBayxNAWZYAAGMMSxW8aK3nSimkaYosy5DnObTWKIqCBYAEADnnYK2FMYadAn4B3tDB+yaBnyQAAAAASUVORK5CYII=""")

# vi:et:sw=4:ts=4