"""
Applet: Mars Clock
Author: Adam Henson
Summary: Mars Time at a Glance
Description: Experience Martian timekeeping with Mars Clock, showcasing the current Mars Coordinated Time and Sol Date.
"""

load("encoding/base64.star", "base64")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_SHOWSOL = False
DEFAULT_SHOWLOC = False
DEFAULT_SHOWEARTH = True

FONT1 = "tb-8"
FONT2 = "tom-thumb"

# Image blob
MARS_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAKXUExURQAAAAICAg8SEh8lIjA4OD5MVDdHUh8rNAYLDQAAAQ0SFio2OE5cYWx2eoyRlpKXnIeLjHR/e0xXTBkgGQECAhYaHkBTZVtzhHaJl4qVmpqOgKqIZ6qFXKqEWJ59VGxjSCouJQICAw4RD0NHRF1iXWprYH11ZJh9X6+AVMSHUsGGUs2NVdCRVrGDUoRuTScoHwQEBDE0Ll1dUG1nVHpsVKd6VMmBTdaJTuWWVOyeWe6jXOmiW9aUVreFVWtfRgwODBYZGFpZUnZsXX5vWpN5XcWFV9qLUuqYVfqpW/ysXfqsXvapX+ihXLKFV2toTy0yKDAwLnhpXZt8YrSHYsGJX8+MWOCTVe+eVvytXf2xX/2wYPuuX/WsYMKRWmFlTkdPQUNBQIZtW6R9X7mGXauAWseLW9qTWuaXVvSlW/yyYfqxYdKaX3ZzVlxlU0NDRHloWI92XZZ4Wp18WsCKXbCDWLGAU9+cWvmwYPmwYfy0YvOqYMCSXXpzV2ZuXTI4O2FeVHdrWHhpVYVwVqSAW35sUHlmSqB5ULWGVrWIV9acXeGiX62KXYh/YF5mWx0lKVdeXG1nWHRrVnxtVZN4WJt5U6F8VKqBVq+EVqiBVaeEWruQXqeKYJWJZTk8MggLDERRVGNpYHNvW4BzWot2WaB8VrSHWcCOW8WTXbiOXJ6BWZV+Wp2LZHVwVA4PDCAqMVtrbmxsXXhwW4JyWI51VpR3VJR3U5t7VpB3VIh2VpqHYpOKaS8yKQIDBTA/THJ/goJ+cYh2W4tzVIZuT4RtTolwUIVxVI+AX5WKZ0FCNQIDAys1QnSEnJWhsZWVlJCKfJGIdYyFcIeAaXFqUy8vJhEVGz9JV2lyfn+GjYOJkG91ekFEQg8QDv///+fl0v0AAAABYktHRNwHYIO3AAAAB3RJTUUH4QUDEjQelR77kwAAAEZ0RVh0UmF3IHByb2ZpbGUgdHlwZSBhcHAxMgAKYXBwMTIKICAgICAgMTUKNDQ3NTYzNmI3OTAwMDEwMDA0MDAwMDAwNjQwMDAwCo97YnMAAABSdEVYdFJhdyBwcm9maWxlIHR5cGUgZXhpZgAKZXhpZgogICAgICAyMgo0NTc4Njk2NjAwMDA0OTQ5MmEwMDA4MDAwMDAwMDAwMDAwMDAwMDAwMDAwMAr5oEG6AAABDklEQVQY02NgAAJGJmYWVjZ2DgYI4OTi5uHl4xcQFBIWAQuIiolLSEpJy8jKySsoAvlKyiqqauoamlraOrp6+gwMBoZGxiamZuYWllbWNrZ29gwOjk7OLq5u7h6eXt4+vn7+DAGBQcEhoWHhEZFR0TGxcfEMCYlJySmpaekZkVGZWdk5uQx5+QWFRcUlpWXlFZVV1TW1DHX1DY1NzS2tbe0dnV3dPb0Mff0TJk6aPGXqtOkzZs6aPWcuw7z5CxYuWrxk6bLlK1auWr1mLQPDuvUbNm7avGXrtu07du7aDXTpnr379h84eOjwkaPHjp84CfLLnlOnz5w9d/7CxUuXT0L9e+Xqtes3bt66DWIDAJewYFOQtEy3AAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDE3LTA1LTAzVDE4OjUyOjMwKzAyOjAwnsrZywAAACV0RVh0ZGF0ZTptb2RpZnkAMjAxNy0wNS0wM1QxODo1MjozMCswMjowMO+XYXcAAABXelRYdFJhdyBwcm9maWxlIHR5cGUgaXB0YwAAeJzj8gwIcVYoKMpPy8xJ5VIAAyMLLmMLEyMTS5MUAxMgRIA0w2QDI7NUIMvY1MjEzMQcxAfLgEigSi4A6hcRdPJCNZUAAAAASUVORK5CYII=""")

EARTH_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAD/AP8A/6C9p5MAAAAHdElNRQfpCh4UKiKmzV6HAAADPElEQVQ4y12TzWtcVRyGn3PunUlmMpNOJnEsTRNIu1EaNRtpMBu1mIXUUFFX4sdCCrryH9CdSxE3SlWQqhgUUSF+RgqCtgQxkoY0Wto0H9NM0qSZZObO3Lkf55yfiyqCz/59eDeP4j+ywJGxz7bvP3O8++FjRf/5lcD2A/ZITq99eaNzHlj68YnKArAJJADqn3H31LdbY6O9XS89d6IwcU9fpn+pKWVPnLedKil6pL2e1F1kGu8ttX+dvRl9cOWFwQUgAsgOvbN68sJ6e0ZE6iJiRZysBkY+2Ujkm61UvthM5c/biSRBYqUd19+8tDdz/N31k0BWA8MvjxbPPjqcn8C5kjWi1wJHNYJeT6EBDXhKaCRO11pSevW+wsTkcPYsMOyNn7v+9PunK896qMORFf1707EUgBHIaLCAccJoNxgH+xalhK4T/ZlDP4+8WPOHCv6kr72BZux0LYasCKWsInWCcRBY4YH8nRdGhENaaEWiR3r8gUeOdk/qfE9m/Lu2zl86sPRr4WgXDCjHQSoYcSRWKGgoavAVpA6sOKyQz2X0uF8seOXrgfVWGg5j4PRdimJe0TGOxbYjq+GXfXVHnlGUfQGl2Iutt3jgyr44MEZQiaPWcViXJTLCeNGjoh1vrCV4VrMbWR4saV4ZzKBxfLjjWAtTdHUzqItWFueYawqLDQMiaBGuth1B6DDGopwlShyCEFnNQ30Ze6+J67q20ZirhzaMU2iGjt/qln4fqh3L+bWYNBWCyJDGwnw9pc8TthLLTDUKb+225vyt6sHs2sr+WOHuYjFsdnTZz4LA61dCtluGXq3oiGCN0Igdry2HzLe1m/+rfrtnszHrBX981IgrU0PFY5WRRuq6n6r4ano95etqTMmHduzoJI527LDGcnHPyU6QNHqXN37YOHfqYw9oZYaerNVrzRF/sFLROa9rtR6rajPFpI4wsXRiS+SENr4jtQ1/4cZF1Wy91Vj89KoH2Pby9J4+/Pi19vpubin0S1XV5Zls1ousqNApiZRnooSWvVWveZevfa+D4O2b02cuA7H6X87D5anPT3l9+ccoFsYllys5cdDpHOhmZ063wp92vnrmArDxb85/A4iu4hxD8hsdAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTEwLTMwVDIwOjQyOjM0KzAwOjAwXmq1EgAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0xMC0zMFQyMDo0MjozNCswMDowMC83Da4AAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjUtMTAtMzBUMjA6NDI6MzQrMDA6MDB4IixxAAAAAElFTkSuQmCC""")

HEART_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAD/AP8A/6C9p5MAAAAHdElNRQfpCh4XGDMjS5RdAAAAQElEQVQI113IIRaAIAAE0Y9Jq1DNnsDu0ekcw8oj27BAccrODqSeS8UxNoUhO16saEu4rxNthvFB7Lk8iH5sUz5dABNlYFRV5gAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0xMC0zMFQyMzoyNDo0NiswMDowMJtRe+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMTAtMzBUMjM6MjQ6NDYrMDA6MDDqDMNUAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI1LTEwLTMwVDIzOjI0OjUxKzAwOjAwtBTcmwAAAABJRU5ErkJggg==""")

def format_time(hrs, mins, fmt24):
    # Common time formatting logic for both Mars and Earth time
    # Takes integer hours and minutes, returns (clockstr, suffix) tuple
    mins_str = str(mins)
    if mins < 10:
        mins_str = "0" + mins_str

    if fmt24:
        suffix = ""
        hrs_str = str(hrs)
        if hrs < 10:
            hrs_str = "0" + hrs_str
        clockstr = "{0}:{1}".format(hrs_str, mins_str)
        return (clockstr, suffix)
    else:
        suffix = "a" if hrs < 12 else "p"
        hrs = hrs % 12
        if hrs == 0:
            hrs = 12
        clockstr = "{0}:{1}".format(hrs, mins_str)
        return (clockstr, suffix)

def hours_to_hms(decimal_hrs, fmt24):
    # Convert decimal hours to HH:MM (suffix) notation
    hrs = int(decimal_hrs)
    mins = int((decimal_hrs - hrs) * 60)
    return format_time(hrs, mins, fmt24)

def earth_time_str(fmt24):
    # Get current Earth time and format as HH:MM with optional a/p suffix
    now = time.now()
    hrs = now.hour
    mins = now.minute
    return format_time(hrs, mins, fmt24)

def render_basic_clock(marstime, suffix, second_line = None, second_line_align = "right", time_color = "#FFF"):
    # Renders a basic clock display with optional second line (for sol date or location)
    clockblock = [
        render.Row(
            cross_align = "end",
            children = [
                render.Text(
                    content = marstime,
                    font = FONT1,
                    color = time_color,
                ),
                render.Text(
                    content = suffix,
                    font = FONT2,
                    color = time_color,
                ),
            ],
        ),
    ]

    if second_line:
        clockblock.append(
            render.Box(
                height = 2,
                width = 1,
                color = "#000",
            ),
        )
        clockblock.append(
            render.WrappedText(
                content = second_line,
                font = FONT2,
                align = second_line_align,
            ),
        )

    return clockblock

def mars_dt_strs(lon, fmt24, showearth = False):
    # Takes a POI longitude
    # Returns final Mars Sol Date (MSD) and Local Mars Time (LMT)
    ######
    # LMT
    # Compute current MSD and LMT for lon
    # Convert decimal LMT to HH:MM string
    # Append MTC if it's the MTC POI in 24H mode (but not when Earth is visible - too long)
    (msd, lmt) = time_on_mars(lon)
    (marstime, suffix) = hours_to_hms(lmt, fmt24)
    if lon == "0.0" and fmt24 and not showearth:
        marstime = "{0} MTC".format(marstime)

    ######
    # MSD
    # Strip decimal from MSD
    # Add "sol" prefix
    marssol = str(int(msd))
    marssol = "sol {0}".format(marssol)
    return marssol, marstime, suffix

def mtc_location_offset(mtc, lon):
    # Given MTC and a longitude, compute local mars time
    # Local time = MTC + (location's east longitude / 15) mars hours
    lcf = float(lon) / 15
    local_time = mtc + lcf
    local_time = math.mod(local_time, 24)
    return local_time

def render_locname(lon):
    # Returns Tidbyt-friendly location name for a given POI lon
    locnames = {
        "0.0": "Airy-0",
        "16.70": "Ares IV",
        "33.30": "Pathfinder",
        "70.5": "Hellas Basin",
        "77.43": "Percy",
        "109.7": "Zhurong",
        "134.26": "Viking 2",
        "137.38": "Curiosity",
        "226.20": "Olympus Mons",
        "312.05": "Viking 1",
        "339.26": "Ares III",
        "350.54": "Cydonia",
    }
    return locnames[lon]

def time_on_mars(lon):
    # Computes current MSD and MTC
    # Applies an offset appropriate for the provided longitude
    # Returns MSD and LMT in decimal hours
    # Math courtesy of marsclock.com
    t0 = time.from_timestamp(0)
    t1 = time.now()
    dn = t1 - t0
    millis = dn.milliseconds
    mday = millis / 8.64e7
    jd1 = mday + 2440587.5
    jd2 = jd1 + (37 + 32.184) / 86400
    dtj2k = jd2 - 2451545
    msd = (((dtj2k - 4.5) / 1.027491252) + 44796.0 - 0.00096)
    mtc = (24 * msd)  #aka C1

    # Apply offset to MTC to get our local mars time
    lmt = mtc_location_offset(mtc, lon)
    return (msd, lmt)

def main(config):
    # Pull config values from schema
    secondline = config.get("secondline", "showearth")
    if secondline == "showlocation":
        showloc = True
        showsol = False
        showearth = False
    elif secondline == "showsol":
        showloc = False
        showsol = True
        showearth = False
    elif secondline == "showearth":
        showloc = False
        showsol = False
        showearth = True
    elif secondline == "shownone":
        showloc = False
        showsol = False
        showearth = False
    else:
        showloc = DEFAULT_SHOWLOC
        showsol = DEFAULT_SHOWSOL
        showearth = DEFAULT_SHOWEARTH
    lon = config.get("location", "0.0")
    fmt24_mars = config.bool("fmt24_mars", False)
    fmt24_earth = config.bool("fmt24_earth", False)

    # Earth globe only available when Earth time is displayed
    show_earth_globe = showearth and config.bool("show_earth_globe", True)

    color_mars_time = config.bool("color_mars_time", False)
    color_earth_time = config.bool("color_earth_time", False)

    # Determine colors based on config
    mars_color = "#DA9A60" if color_mars_time else "#FFF"
    earth_color = "#79C5EC" if color_earth_time else "#FFF"

    # Compute MSD and LMT
    (marssol, marstime, suffix) = mars_dt_strs(lon, fmt24_mars, showearth)
    locname = render_locname(lon)

    # Initialize hearts flag (will be set to True if times match)
    show_hearts = False

    if showsol:
        clockblock = render_basic_clock(marstime, suffix, marssol, time_color = mars_color)
    elif showloc:
        clockblock = render_basic_clock(marstime, suffix, locname, time_color = mars_color)
    elif (showearth):
        # Get Earth time
        (earthtime, earthsuffix) = earth_time_str(fmt24_earth)

        # Easter egg: show hearts when Mars and Earth times match!
        show_hearts = marstime == earthtime

        clockblock = [
            # Mars time - shifted left
            render.Padding(
                pad = (0, 0, 3, 0),  # left, top, right, bottom
                child = render.Row(
                    cross_align = "end",
                    children = [
                        render.Text(
                            content = marstime,
                            font = FONT1,
                            color = mars_color,
                        ),
                        render.Text(
                            content = suffix,
                            font = FONT2,
                            color = mars_color,
                        ),
                    ],
                ),
            ),
            render.Box(
                height = 2,
                width = 1,
                color = "#000",
            ),
            # Earth time - shifted right
            render.Padding(
                pad = (3, 0, 0, 0),  # left, top, right, bottom
                child = render.Row(
                    cross_align = "end",
                    children = [
                        render.Text(
                            content = earthtime,
                            font = FONT1,
                            color = earth_color,
                        ),
                        render.Text(
                            content = earthsuffix,
                            font = FONT2,
                            color = earth_color,
                        ),
                    ],
                ),
            ),
        ]
    else:
        clockblock = render_basic_clock(marstime, suffix, time_color = mars_color)

    # Build the row children list (Mars icon, clock, optionally Earth icon)
    # Build Mars icon column (heart above planet if needed)
    mars_column_children = []
    if show_hearts and show_earth_globe:
        mars_column_children.append(
            render.Padding(
                pad = (10, 0, 0, 0),  # left, top, right, bottom - shift right toward center
                child = render.Image(src = HEART_ICON),
            ),
        )
    mars_column_children.append(render.Image(src = MARS_ICON))

    # Build Mars column with conditional positioning
    mars_column = render.Column(
        main_align = "start" if (show_hearts and show_earth_globe) else "center",
        cross_align = "center",
        children = mars_column_children,
    )

    row_children = [
        mars_column,
        render.Box(width = 1, color = "#000"),
        render.Column(
            main_align = "space_evenly",
            cross_align = "end",
            children = clockblock,
        ),
    ]

    # Add Earth globe if enabled
    if show_earth_globe:
        # Build Earth icon column (heart above planet if needed)
        earth_column_children = []
        if show_hearts:
            earth_column_children.append(
                render.Padding(
                    pad = (0, 0, 10, 0),  # left, top, right, bottom - shift left toward center with right padding
                    child = render.Image(src = HEART_ICON),
                ),
            )
        earth_column_children.append(render.Image(src = EARTH_ICON))

        row_children.append(render.Box(width = 1, color = "#000"))
        row_children.append(
            render.Padding(
                pad = (0, 0 if show_hearts else 2, 0, 0),  # left, top, right, bottom - no shift when hearts showing, down otherwise
                child = render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = earth_column_children,
                ),
            ),
        )

    return render.Root(
        delay = 500,
        child = render.Padding(
            pad = (0, 0, 1, 0),  # left, top, right, bottom - shift 1px left
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = row_children,
                    ),
                ],
            ),
        ),
    )

def earth_options(secondline):
    # Return Earth-related options only when Earth Time is selected
    if secondline == "showearth":
        return [
            schema.Toggle(
                id = "fmt24_earth",
                name = "24-hour Earth clock",
                desc = "",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "color_earth_time",
                name = "Color Earth time",
                desc = "Display Earth time in blue",
                icon = "palette",
                default = True,
            ),
            schema.Toggle(
                id = "show_earth_globe",
                name = "Show Earth globe",
                desc = "Display Earth globe on the right side",
                icon = "earthAmericas",
                default = True,
            ),
        ]
    else:
        return []

def get_schema():
    locations = [
        schema.Option(
            display = "Mars Coordinated Time (Airy-0 Crater)",
            value = "0.0",
        ),
        schema.Option(
            display = "Acidalia Planitia (The Martian - Ares III)",
            value = "339.26",
        ),
        schema.Option(
            display = "Curiosity Rover (2012)",
            value = "137.38",
        ),
        schema.Option(
            display = "Cydonia (The Face)",
            value = "350.54",
        ),
        schema.Option(
            display = "Hellas Basin",
            value = "70.5",
        ),
        schema.Option(
            display = "Mars Pathfinder (1997)",
            value = "33.30",
        ),
        schema.Option(
            display = "Olympus Mons",
            value = "226.20",
        ),
        schema.Option(
            display = "Perseverance Rover (2021)",
            value = "77.43",
        ),
        schema.Option(
            display = "Schiaparelli Crater (The Martian - Ares IV)",
            value = "16.70",
        ),
        schema.Option(
            display = "Viking 1 (1976)",
            value = "312.05",
        ),
        schema.Option(
            display = "Viking 2 (1976)",
            value = "134.26",
        ),
        schema.Option(
            display = "Zhurong (2021)",
            value = "109.7",
        ),
    ]

    secondlines = [
        schema.Option(
            display = "Location",
            value = "showlocation",
        ),
        schema.Option(
            display = "Mars Sol Date",
            value = "showsol",
        ),
        schema.Option(
            display = "Earth Time",
            value = "showearth",
        ),
        schema.Option(
            display = "None",
            value = "shownone",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "location",
                name = "Location",
                desc = "Show the time on Mars at this location",
                icon = "locationCrosshairs",
                default = locations[0].value,
                options = locations,
            ),
            schema.Dropdown(
                id = "secondline",
                name = "Show below clock",
                desc = "Display location or Mars Sol Date below the clock",
                icon = "a",
                default = secondlines[2].value,
                options = secondlines,
            ),
            schema.Toggle(
                id = "fmt24_mars",
                name = "24-hour Mars clock",
                desc = "",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "color_mars_time",
                name = "Color Mars time",
                desc = "Display Mars time in orange",
                icon = "palette",
                default = True,
            ),
            schema.Generated(
                id = "earth_options",
                source = "secondline",
                handler = earth_options,
            ),
        ],
    )
