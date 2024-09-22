"""
Applet: Exotic Clocks
Summary: Weird Clocks
Description: Weird but stylish way to tell the time.
Author: vzsky
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ZRO = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAQElEQVQoFWNgGPqAEd0L/4EAWYwRCJD5KGx0xSBJbGJgTTgl0DQxgVWTQJCsAcVsbM5CF8MIAQwF+EIJxTocHAA6px/vs8WNiAAAAABJRU5ErkJggg==")
ONE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAT0lEQVQoFdWPMQ4AIAgDwfj/LysdShqVgVEWIFzbYPZ/ub6wonTn7FGcs1cwAL3NVByHp2swQwWYK5BcCghqPKF2V5P7+7BTAO5MbydBsAHi6xwD+FkEXQAAAABJRU5ErkJggg==")
TWO = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAWElEQVQoFZ2PWw4AEAwES9z/yqhkGo8myv5s1E4XkR/VriiXo0Fyz0CBxOfnpa79PHIM1VUezPx40r4VGD8ANmlAYYL48gcvQBC3hnkzl55b5Q2ItHsF0gAKIC/8kAkwKgAAAABJRU5ErkJggg==")
THR = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAATUlEQVQoFdWPOw4AIAhDxfvfWenwCBqMiZtdWlo+2tr/ML4wHGixObKnOnIFQhguTnWnadmAWXAMFFlpxcD+hLIbk2YYPzPZ24W86aYn0Hkr6srXUPkAAAAASUVORK5CYII=")
FOU = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAXUlEQVQoFbWQ0Q5AEQxDuf//z2jkLLVELg/60um6MqW8QhtQ9nd7wdEA6UfhMguYKwXsTbQ6EDWFG91Af2GZBRensmrRz2Y10GDM21/SszDDGoplXCQt8+9ueUDnDrMGP9rLj+N6AAAAAElFTkSuQmCC")
FIV = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAYklEQVQoFbWQQQ6AMAzDGP//M8wgT2mFhDiQS1Y3LWzb9peOKXbvXz9QBtzSlzxyoe4QNbIeHvBsJB9T1uuQ4QwYLE4YJbxJZavfwzRkuuHySkKc3zKsX9xQQln317v1AeoTJ51LzmRQuS0AAAAASUVORK5CYII=")
SIX = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAXUlEQVQoFZ2QSw7AIAhEten9r2wZk5egaCOyAeYDaGkWJRGPtFlTN1yZTi6riNhQLajhhFEPWULFAFqzwmZN6DH1XwrsD/B6jinCtnevDN4o3vfh9Z5k2NE2xHP+AHlPP9uDhyGyAAAAAElFTkSuQmCC")
SEV = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAVklEQVQoFbXPMQ6AMAwDwIL4/5ehHi7qwECE6sWJGzvpGLtwTyT77C5oGy4brEx/TOhTmyn2SFh7NW6f9MkgPReUIWLgLOwPuAyEDK41Iy7DW7qhX/wAhwsr/8Q/cI8AAAAASUVORK5CYII=")
EGT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAV0lEQVQoFc2QSQ7AIAwDgf//mTKHQaaqBOoJXxLHzgKlXIM+wDHt5CLNeKsNWbSWsQ5MvjNP4+8kN2TOQDhw+PLoFDQQuV9taXiLn5yi3f6EHE2oyY/jA61NN+lglROsAAAAAElFTkSuQmCC")
NNE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAAAW0lEQVQoFbVPQQ4AIAiq/v/nihrMlrY6xEVUwErpF2oHssvrgRwZmMh97iAfFQIAzWSTLyI2FN6Itz/wtA1hsGq09Oa64C2VaIgMeIpn8mbDjwVgwkSjuQQn0gBTU0fOkXQb9gAAAABJRU5ErkJggg==")

BLANK = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAQAAAAMCAYAAABFohwTAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAADAAAAAD1HLXDAAAADElEQVQIHWNgGD4AAADMAAH30YzJAAAAAElFTkSuQmCC")
COLON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAQAAAAMCAYAAABFohwTAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAADAAAAAD1HLXDAAAAGUlEQVQIHWNgIA/8hwKQbibyjCBCF2m2AADUkw/1AKlPfQAAAABJRU5ErkJggg==")

num_to_digit = [ZRO, ONE, TWO, THR, FOU, FIV, SIX, SEV, EGT, NNE]

DEFAULT_LOCATION = {
    "lat": 13.7563,
    "lng": 100.5018,
    "locality": "Bangkok",
}
DEFAULT_TIMEZONE = "Asia/Bangkok"

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))

    current_time = time.now().in_location(timezone)

    clock = render_thai_clock(current_time)

    if config.get("clocktype") == "roman":
        clock = render_roman_clock(current_time)
    return render.Root(
        delay = 500,
        child = clock,
    )

def render_thai_clock(current_time):
    hh = current_time.format("15")
    mm = current_time.format("04")
    return render.Animation(
        children = [
            render.Box(
                child = render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Image(num_to_digit[int(hh[0])]),
                        render.Image(num_to_digit[int(hh[1])]),
                        render.Image(src = COLON),
                        render.Image(num_to_digit[int(mm[0])]),
                        render.Image(num_to_digit[int(mm[1])]),
                    ],
                ),
            ),
            render.Box(
                child = render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Image(num_to_digit[int(hh[0])]),
                        render.Image(num_to_digit[int(hh[1])]),
                        render.Image(src = BLANK),
                        render.Image(num_to_digit[int(mm[0])]),
                        render.Image(num_to_digit[int(mm[1])]),
                    ],
                ),
            ),
        ],
    )

def roman_numeral(num):
    numbers = [(50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    result = ""
    for val, str in numbers:
        for _ in range(10):
            if num >= val:
                result += str
                num -= val
    return result

def render_roman_clock(current_time):
    hh = int(current_time.format("15"))
    mm = int(current_time.format("04"))
    texts = [render.Text("H " + roman_numeral(hh), font = "6x13")]
    if mm != 0:
        texts.append(render.Text("M " + roman_numeral(mm), font = "6x13"))
    return render.Box(child = render.Column(children = texts))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the time",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "clocktype",
                name = "Clock Type",
                desc = "Type of the clock to display",
                icon = "language",
                default = "thai",
                options = [
                    schema.Option(
                        display = "Thai",
                        value = "thai",
                    ),
                    schema.Option(
                        display = "Roman",
                        value = "roman",
                    ),
                ],
            ),
        ],
    )
