"""
Applet: Hex Color Clock
Summary: Shows a hex color clock
Description: This app shows a clock and a hex number. The background will change colors to match the hex code shown.
Author: gabe565
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_LOCATION = {
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": DEFAULT_TIMEZONE,
}

DEFAULT_24_HOUR_FORMAT = True
DEFAULT_HIDE_CLOCK = False
DEFAULT_HIDE_HEX_CODE = False
DEFAULT_HIDE_SECONDS = False
DEFAULT_USE_MORE_COLORS = True
DEFAULT_FLASHING_SEPARATOR = True

def main(config):
    # Get current time
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))  # Utilize special timezone variable
    now = time.now().in_location(timezone)

    # Add a format with colon separator
    formats = [get_time_format(config, ":")]
    if config.bool("flashing_separator", DEFAULT_FLASHING_SEPARATOR):
        # Add a format with space separator
        formats.append(get_time_format(config, " "))

        # Separator flashes once per second, so cut delay in half
        # and generate twice as many frames
        delay = 500
    else:
        delay = 1000

    brighten_colors = config.bool("use_more_colors", DEFAULT_USE_MORE_COLORS)
    hide_clock = config.bool("hide_clock", DEFAULT_HIDE_CLOCK)
    hide_hex_code = config.bool("hide_hex_code", DEFAULT_HIDE_HEX_CODE)
    frames = []

    # Generate frames for the next 30 seconds
    for _ in range(30):
        bg_color, fg_color = get_color(now, brighten_colors)

        for format in formats:
            children = []
            if not hide_clock:
                children.append(render.Text(
                    content = now.format(format),
                    font = "6x13",
                    color = fg_color,
                ))
            if not hide_hex_code:
                children.append(render.Text(
                    content = bg_color,
                    font = "Dina_r400-6",
                    color = fg_color,
                ))

            frames.append(render.Box(
                color = bg_color,
                child = render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = children,
                ),
            ))

        now += time.second

    return render.Root(
        delay = delay,
        max_age = 120,
        child = render.Animation(
            children = frames,
        ),
    )

def get_time_format(config, sep = ":"):
    hide_seconds = config.bool("hide_seconds", DEFAULT_HIDE_SECONDS)

    if config.bool("24h_format", DEFAULT_24_HOUR_FORMAT):
        return "15" + sep + "04" + ("" if hide_seconds else sep + "05")
    else:
        return "3" + sep + "04" + ("" if hide_seconds else sep + "05") + " PM"

def get_color(now, use_more_colors = DEFAULT_USE_MORE_COLORS):
    bg_color = "#"
    if use_more_colors:
        # Scale 0-60 to 0-255
        min_dec = now.minute / 60
        sec_dec = now.second / 60
        red = int((now.hour + min_dec + sec_dec / 60) / 24 * 0xFF)
        green = int((now.minute + sec_dec) / 60 * 0xFF)
        blue = int(now.second / 60 * 0xFF)

        # Add numbers as hex to bg_color
        bg_color += pad_0("%X" % red)
        bg_color += pad_0("%X" % green)
        bg_color += pad_0("%X" % blue)
    else:
        red = now.hour
        green = now.minute
        blue = now.second

        # Add numbers directly to bg_color
        bg_color += pad_0(red)
        bg_color += pad_0(green)
        bg_color += pad_0(blue)

    # Determine foreground color
    if red * 0.28 + green * 0.48 + blue * 0.24 > 80:
        fg_color = "#000"
    else:
        fg_color = "#fff"

    return bg_color, fg_color

def pad_0(num):
    return ("0" + str(num))[-2:]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time",
            ),
            schema.Toggle(
                id = "hide_clock",
                name = "Hide Clock",
                icon = "eyeSlash",
                desc = "Hide the clock",
                default = DEFAULT_HIDE_CLOCK,
            ),
            schema.Toggle(
                id = "24h_format",
                name = "24 Hour Format",
                icon = "clock",
                desc = "Toggle 24 hour format.",
                default = DEFAULT_24_HOUR_FORMAT,
            ),
            schema.Toggle(
                id = "hide_seconds",
                name = "Hide Seconds",
                icon = "eyeSlash",
                desc = "Toggle seconds.",
                default = DEFAULT_HIDE_SECONDS,
            ),
            schema.Toggle(
                id = "flashing_separator",
                name = "Flashing Separator",
                icon = "gear",
                desc = "Toggle flashing number separator.",
                default = DEFAULT_FLASHING_SEPARATOR,
            ),
            schema.Toggle(
                id = "hide_hex_code",
                name = "Hide Hex Code",
                icon = "eyeSlash",
                desc = "Hide the hex code",
                default = DEFAULT_HIDE_HEX_CODE,
            ),
            schema.Toggle(
                id = "use_more_colors",
                name = "Use More Colors",
                desc = "Use full range of colors instead of making the hex code match the time exactly",
                icon = "palette",
                default = DEFAULT_USE_MORE_COLORS,
            ),
        ],
    )
