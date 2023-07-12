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

DEFAULT_SHOWSOL = True

# Image blob
MARS_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAKXUExURQAAAAICAg8SEh8lIjA4OD5MVDdHUh8rNAYLDQAAAQ0SFio2OE5cYWx2eoyRlpKXnIeLjHR/e0xXTBkgGQECAhYaHkBTZVtzhHaJl4qVmpqOgKqIZ6qFXKqEWJ59VGxjSCouJQICAw4RD0NHRF1iXWprYH11ZJh9X6+AVMSHUsGGUs2NVdCRVrGDUoRuTScoHwQEBDE0Ll1dUG1nVHpsVKd6VMmBTdaJTuWWVOyeWe6jXOmiW9aUVreFVWtfRgwODBYZGFpZUnZsXX5vWpN5XcWFV9qLUuqYVfqpW/ysXfqsXvapX+ihXLKFV2toTy0yKDAwLnhpXZt8YrSHYsGJX8+MWOCTVe+eVvytXf2xX/2wYPuuX/WsYMKRWmFlTkdPQUNBQIZtW6R9X7mGXauAWseLW9qTWuaXVvSlW/yyYfqxYdKaX3ZzVlxlU0NDRHloWI92XZZ4Wp18WsCKXbCDWLGAU9+cWvmwYPmwYfy0YvOqYMCSXXpzV2ZuXTI4O2FeVHdrWHhpVYVwVqSAW35sUHlmSqB5ULWGVrWIV9acXeGiX62KXYh/YF5mWx0lKVdeXG1nWHRrVnxtVZN4WJt5U6F8VKqBVq+EVqiBVaeEWruQXqeKYJWJZTk8MggLDERRVGNpYHNvW4BzWot2WaB8VrSHWcCOW8WTXbiOXJ6BWZV+Wp2LZHVwVA4PDCAqMVtrbmxsXXhwW4JyWI51VpR3VJR3U5t7VpB3VIh2VpqHYpOKaS8yKQIDBTA/THJ/goJ+cYh2W4tzVIZuT4RtTolwUIVxVI+AX5WKZ0FCNQIDAys1QnSEnJWhsZWVlJCKfJGIdYyFcIeAaXFqUy8vJhEVGz9JV2lyfn+GjYOJkG91ekFEQg8QDv///+fl0v0AAAABYktHRNwHYIO3AAAAB3RJTUUH4QUDEjQelR77kwAAAEZ0RVh0UmF3IHByb2ZpbGUgdHlwZSBhcHAxMgAKYXBwMTIKICAgICAgMTUKNDQ3NTYzNmI3OTAwMDEwMDA0MDAwMDAwNjQwMDAwCo97YnMAAABSdEVYdFJhdyBwcm9maWxlIHR5cGUgZXhpZgAKZXhpZgogICAgICAyMgo0NTc4Njk2NjAwMDA0OTQ5MmEwMDA4MDAwMDAwMDAwMDAwMDAwMDAwMDAwMAr5oEG6AAABDklEQVQY02NgAAJGJmYWVjZ2DgYI4OTi5uHl4xcQFBIWAQuIiolLSEpJy8jKySsoAvlKyiqqauoamlraOrp6+gwMBoZGxiamZuYWllbWNrZ29gwOjk7OLq5u7h6eXt4+vn7+DAGBQcEhoWHhEZFR0TGxcfEMCYlJySmpaekZkVGZWdk5uQx5+QWFRcUlpWXlFZVV1TW1DHX1DY1NzS2tbe0dnV3dPb0Mff0TJk6aPGXqtOkzZs6aPWcuw7z5CxYuWrxk6bLlK1auWr1mLQPDuvUbNm7avGXrtu07du7aDXTpnr379h84eOjwkaPHjp84CfLLnlOnz5w9d/7CxUuXT0L9e+Xqtes3bt66DWIDAJewYFOQtEy3AAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDE3LTA1LTAzVDE4OjUyOjMwKzAyOjAwnsrZywAAACV0RVh0ZGF0ZTptb2RpZnkAMjAxNy0wNS0wM1QxODo1MjozMCswMjowMO+XYXcAAABXelRYdFJhdyBwcm9maWxlIHR5cGUgaXB0YwAAeJzj8gwIcVYoKMpPy8xJ5VIAAyMLLmMLEyMTS5MUAxMgRIA0w2QDI7NUIMvY1MjEzMQcxAfLgEigSi4A6hcRdPJCNZUAAAAASUVORK5CYII=""")

def time_on_mars():
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
    c1 = (24 * msd)
    mtc = math.mod(c1, 24)
    return (msd, mtc)

def hours_to_hms(decimal_hours, colons):
    total_seconds = int(decimal_hours * 3600)  # Convert hours to seconds
    hours = total_seconds / 3600
    minutes = math.mod(total_seconds, 3600) // 60
    seconds = math.mod(total_seconds, 60)

    hours_str = str(hours)
    minutes_str = str(minutes)
    seconds_str = str(seconds)

    # Add zero padding
    #if hours < 10:
    #  hours_str = "0" + hours_str
    if minutes < 10:
        minutes_str = "0" + minutes_str
    if seconds < 10:
        seconds_str = "0" + seconds_str

    hours_str = hours_str.rsplit(".")[0]
    minutes_str = minutes_str.rsplit(".")[0]
    seconds_str = seconds_str.rsplit(".")[0]

    if (colons):
        return hours_str + ":" + minutes_str
        #return hours_str + ":" + minutes_str + ":" + seconds_str

    else:
        return hours_str + " " + minutes_str
        #return hours_str + " " + minutes_str + " " + seconds_str

def mars_dt_strs(colons):
    # Get current MSD and MTC
    (msd, mtc) = time_on_mars()

    # Prettify MTC
    if (colons):
        marstime = str(hours_to_hms(mtc, 1)) + " MTC"
    else:
        marstime = str(hours_to_hms(mtc, 0)) + " MTC"

    # Strip decimal from Sols
    marssol = str(msd)
    marssol = marssol.rsplit(".")[0]
    marssol = "sol " + marssol
    return marssol, marstime

def main(config):
    (marssol, marstime) = mars_dt_strs(1)
    showsol = config.bool("showsol", DEFAULT_SHOWSOL)
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
            render.Text(
                content = marssol,
                font = "tom-thumb",
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
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Column(
                        children = [
                            render.Image(src = MARS_ICON),
                        ],
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "end",
                        children = clockblock,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "showsol",
                name = "Show Sols",
                desc = "Display current Mars Sol Date below the clock",
                icon = "calendar",
                default = True,
            ),
        ],
    )
