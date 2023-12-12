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
DEFAULT_SHOWLOC = True

# Image blob
MARS_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAKXUExURQAAAAICAg8SEh8lIjA4OD5MVDdHUh8rNAYLDQAAAQ0SFio2OE5cYWx2eoyRlpKXnIeLjHR/e0xXTBkgGQECAhYaHkBTZVtzhHaJl4qVmpqOgKqIZ6qFXKqEWJ59VGxjSCouJQICAw4RD0NHRF1iXWprYH11ZJh9X6+AVMSHUsGGUs2NVdCRVrGDUoRuTScoHwQEBDE0Ll1dUG1nVHpsVKd6VMmBTdaJTuWWVOyeWe6jXOmiW9aUVreFVWtfRgwODBYZGFpZUnZsXX5vWpN5XcWFV9qLUuqYVfqpW/ysXfqsXvapX+ihXLKFV2toTy0yKDAwLnhpXZt8YrSHYsGJX8+MWOCTVe+eVvytXf2xX/2wYPuuX/WsYMKRWmFlTkdPQUNBQIZtW6R9X7mGXauAWseLW9qTWuaXVvSlW/yyYfqxYdKaX3ZzVlxlU0NDRHloWI92XZZ4Wp18WsCKXbCDWLGAU9+cWvmwYPmwYfy0YvOqYMCSXXpzV2ZuXTI4O2FeVHdrWHhpVYVwVqSAW35sUHlmSqB5ULWGVrWIV9acXeGiX62KXYh/YF5mWx0lKVdeXG1nWHRrVnxtVZN4WJt5U6F8VKqBVq+EVqiBVaeEWruQXqeKYJWJZTk8MggLDERRVGNpYHNvW4BzWot2WaB8VrSHWcCOW8WTXbiOXJ6BWZV+Wp2LZHVwVA4PDCAqMVtrbmxsXXhwW4JyWI51VpR3VJR3U5t7VpB3VIh2VpqHYpOKaS8yKQIDBTA/THJ/goJ+cYh2W4tzVIZuT4RtTolwUIVxVI+AX5WKZ0FCNQIDAys1QnSEnJWhsZWVlJCKfJGIdYyFcIeAaXFqUy8vJhEVGz9JV2lyfn+GjYOJkG91ekFEQg8QDv///+fl0v0AAAABYktHRNwHYIO3AAAAB3RJTUUH4QUDEjQelR77kwAAAEZ0RVh0UmF3IHByb2ZpbGUgdHlwZSBhcHAxMgAKYXBwMTIKICAgICAgMTUKNDQ3NTYzNmI3OTAwMDEwMDA0MDAwMDAwNjQwMDAwCo97YnMAAABSdEVYdFJhdyBwcm9maWxlIHR5cGUgZXhpZgAKZXhpZgogICAgICAyMgo0NTc4Njk2NjAwMDA0OTQ5MmEwMDA4MDAwMDAwMDAwMDAwMDAwMDAwMDAwMAr5oEG6AAABDklEQVQY02NgAAJGJmYWVjZ2DgYI4OTi5uHl4xcQFBIWAQuIiolLSEpJy8jKySsoAvlKyiqqauoamlraOrp6+gwMBoZGxiamZuYWllbWNrZ29gwOjk7OLq5u7h6eXt4+vn7+DAGBQcEhoWHhEZFR0TGxcfEMCYlJySmpaekZkVGZWdk5uQx5+QWFRcUlpWXlFZVV1TW1DHX1DY1NzS2tbe0dnV3dPb0Mff0TJk6aPGXqtOkzZs6aPWcuw7z5CxYuWrxk6bLlK1auWr1mLQPDuvUbNm7avGXrtu07du7aDXTpnr379h84eOjwkaPHjp84CfLLnlOnz5w9d/7CxUuXT0L9e+Xqtes3bt66DWIDAJewYFOQtEy3AAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDE3LTA1LTAzVDE4OjUyOjMwKzAyOjAwnsrZywAAACV0RVh0ZGF0ZTptb2RpZnkAMjAxNy0wNS0wM1QxODo1MjozMCswMjowMO+XYXcAAABXelRYdFJhdyBwcm9maWxlIHR5cGUgaXB0YwAAeJzj8gwIcVYoKMpPy8xJ5VIAAyMLLmMLEyMTS5MUAxMgRIA0w2QDI7NUIMvY1MjEzMQcxAfLgEigSi4A6hcRdPJCNZUAAAAASUVORK5CYII=""")

def mtc_location_offset(mtc, lon):
    # Given MTC and a longitude, compute local mars time
    # Local time = MTC + (location's east longitude / 15) mars hours
    lcf = float(lon) / 15
    local_time = mtc + lcf
    local_time = math.mod(local_time, 24)
    return local_time

def time_on_mars(lon):
    # Computes current MSD and MTC
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

    # Apply offset to MTC to get our local time
    lmt = mtc_location_offset(mtc, lon)
    return (msd, lmt)

def hours_to_hms(decimal_hours):
    # Convert decimal hours to hr:min:sec notation
    total_seconds = int(decimal_hours * 3600)  # Convert hours to seconds
    hours = total_seconds / 3600
    minutes = math.mod(total_seconds, 3600) // 60
    seconds = math.mod(total_seconds, 60)
    hours_str = str(hours)
    minutes_str = str(minutes)
    seconds_str = str(seconds)

    # Add zero padding to mins & secs
    if minutes < 10:
        minutes_str = "0" + minutes_str
    if seconds < 10:
        seconds_str = "0" + seconds_str
    hours_str = hours_str.rsplit(".")[0]
    minutes_str = minutes_str.rsplit(".")[0]
    seconds_str = seconds_str.rsplit(".")[0]
    return hours_str + ":" + minutes_str

def mars_dt_strs(lon):
    # Generates final MSD and Local Mars Time strings
    (msd, lmt) = time_on_mars(lon)
    if lon == "0.0":
        marstime = str(hours_to_hms(lmt)) + " MTC"
    else:
        marstime = str(hours_to_hms(lmt))

    # Strip decimal from Sols
    marssol = str(msd)
    marssol = marssol.rsplit(".")[0]
    marssol = "sol " + marssol
    return marssol, marstime

def render_locname(lon):
    locnames = {
        "0.0": "Airy-0",
        "16.70": "Schiap- arelli",
        "33.30": "Pathfinder",
        "70.5": "Hellas Basin",
        "77.43": "Percy",
        "109.7": "Tianwen-1",
        "134.26": "Viking 2",
        "137.38": "Curiosity",
        "226.20": "Olympus Mons",
        "312.05": "Viking 1",
        "339.26": "Acidalia Planitia",
        "350.54": "Cydonia",
    }
    return locnames[lon]

def main(config):
    # Pull config values from schema
    secondline = config.get("secondline")
    if secondline == "showlocation":
        showloc = True
        showsol = False
    elif secondline == "showsol":
        showloc = False
        showsol = True
    elif secondline == "shownone":
        showloc = False
        showsol = False
    else:
        showloc = DEFAULT_SHOWLOC
        showsol = DEFAULT_SHOWSOL
    lon = config.get("location", "0.0")

    # Compute local sol & time
    (marssol, marstime) = mars_dt_strs(lon)
    locname = render_locname(lon)

    if (showsol):
        clockblock = [
            render.Text(
                content = marstime,
                font = "tb-8",
            ),
            render.Box(
                height = 2,
                width = 1,
                color = "#000",
            ),
            render.WrappedText(
                content = marssol,
                font = "tom-thumb",
                align = "right",
            ),
        ]
    elif (showloc):
        clockblock = [
            render.Text(
                content = marstime,
                font = "tb-8",
            ),
            render.Box(
                height = 2,
                width = 1,
                color = "#000",
            ),
            render.WrappedText(
                content = locname,
                font = "tom-thumb",
                align = "right",
            ),
        ]
    else:
        clockblock = [
            render.Text(
                content = marstime,
                font = "tb-8",
            ),
        ]

    return render.Root(
        delay = 500,
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Column(
                            children = [
                                render.Row(
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Image(src = MARS_ICON),
                                        render.Box(
                                            width = 1,
                                            color = "#000",
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_evenly",
                            cross_align = "end",
                            children = clockblock,
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    locations = [
        schema.Option(
            display = "Mars Coordinated Time",
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
            display = "Tianwen-1 (2021)",
            value = "109.7",
        ),
        schema.Option(
            display = "Viking 1 (1976)",
            value = "312.05",
        ),
        schema.Option(
            display = "Viking 2 (1976)",
            value = "134.26",
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
            display = "None",
            value = "shownone",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "location",
                name = "Location on Mars",
                desc = "Show the time on Mars at this location",
                icon = "locationCrosshairs",
                default = locations[0].value,
                options = locations,
            ),
            schema.Dropdown(
                id = "secondline",
                name = "Show below clock",
                desc = "Show the location or Mars Sol Date below the clock",
                icon = "a",
                default = secondlines[0].value,
                options = secondlines,
            ),
        ],
    )
