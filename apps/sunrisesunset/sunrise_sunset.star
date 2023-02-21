"""
Applet: Sunrise Sunset
Summary: Shows sunrise and set times
Description: Displays with icon sunrise and sunset times.
Author: Alan Fleming
"""

# Sunrise Sunset App
#
# Copyright (c) 2022 Alan Fleming
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# See comments in the code for further attribution
#

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

# Defaults
DEFAULT_LOCATION = """
{
    "lat": 53.79444,
    "lng": -2.245278,
    "locality": "Manchester, UK",
    "timezone": "GMT"
}
"""

DEFAULT_24_HOUR = False
DEFAULT_ITEMS_TO_DISPLAY = "both"

# Images
sunriseImage = """iVBORw0KGgoAAAANSUhEUgAAAB0AAAAOCAYAAADT0Rc6AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAHaADAAQAAAABAAAADgAAAAD5O/sDAAAA8klEQVQ4Eb1UMQoCMRDMiWBlJdcKVoK1jfgjH+RnrrKQa6xtBVvRxgdEJjrLZkmOHHqmSXYzs5PZ5M65gYa/bX2u9DjaaHwAtstHlE4Fm/ms0nmIVPUxyuX2R3qjdG0FwYMg3fnDxLvzyUlsDvQ+WaHDlJg9aBBEcrWWLduBbDuE0WOREiRdC/e+05RbthEtzQ1iIB6L5hgq317v4bFpcboQpwrPJTGIf9peFBThzjv9PCIQSj4V4LRLxBxoIRxp4RCb10v81zPvjIW6YmnvYv/M/kFYCPNlNw2cUrzmar7NDx6LU6uknZS6S+GYs/X/Hr8A8WR14FqWMJkAAAAASUVORK5CYII="""
sunsetImage = """iVBORw0KGgoAAAANSUhEUgAAAB0AAAAOCAYAAADT0Rc6AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAHaADAAQAAAABAAAADgAAAAD5O/sDAAAAyElEQVQ4EWNgGADASAs7582b9x/Z3KSkJBR7UDjICqnBRrYc2WImahiOywxki5DV4LX0/2trlGBC1kgMG9mnyOpZkDkgSxhFj+IMckLyMLPQLcPlY5h6BpjvQDQMgyRh4nCFFDCw+gpuwbUzDAxaJmDj8YUAqfZjWIpiIcw0KlsMt/T/Qfb/DNd/wqzBTWuyMzDa/4Trw60QtwxYs+K0zySn0vtZvHj14pKHieN2Eo1kcAYTzPcwl8H4+NwBUouuDqYfnz66yAEAg+FU6JspIAwAAAAASUVORK5CYII="""

def main(config):
    # Get longditude and latitude from location
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(location["lat"])
    lng = float(location["lng"])

    # Get sunset and sunrise times
    now = time.now()
    sunriseTime = sunrise.sunrise(lat, lng, now).in_location(location["timezone"])
    sunsetTime = sunrise.sunset(lat, lng, now).in_location(location["timezone"])

    # Get whether to display in 24h format
    display24Hour = config.bool("24_hour", DEFAULT_24_HOUR)
    itemsToDisplay = config.get("items_to_display", DEFAULT_ITEMS_TO_DISPLAY)

    if sunriseTime == None:
        sunriseText = "  None"
    elif display24Hour:
        sunriseText = "  %s" % sunriseTime.format("15:04")
    else:
        sunriseText = "%s" % sunriseTime.format("3:04 PM")

    if sunsetTime == None:
        sunsetText = "  None"
    elif display24Hour:
        sunsetText = "  %s" % sunsetTime.format("15:04")
    else:
        sunsetText = "%s" % sunsetTime.format("3:04 PM")

    # Got what we need, render it.

    if itemsToDisplay == "both":
        top = render.Padding(
            pad = (0, 2, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Image(src = base64.decode(sunriseImage)),
                    render.Text(sunriseText),
                ],
            ),
        )
        middle = render.Box(
            width = 64,
            height = 1,
            color = "#a00",
        )

        bottom = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render.Image(src = base64.decode(sunsetImage)),
                render.Text(sunsetText),
            ],
        )

    else:
        if itemsToDisplay == "sunrise":
            title = "Sunrise"
            text = sunriseText
            image = sunriseImage

        else:
            title = "Sunset"
            text = sunsetText
            image = sunsetImage

        top = render.Padding(
            pad = (0, 2, 0, 4),
            child = render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(title),
                ],
            ),
        )
        middle = None

        bottom = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render.Image(src = base64.decode(image)),
                render.Text(text),
            ],
        )

    return render.Root(
        child = render.Column(
            children = [
                top,
                middle,
                bottom,
            ],
        ),
    )

def get_schema():
    show_options = [
        schema.Option(
            display = "Sunrise & Sunset",
            value = "both",
        ),
        schema.Option(
            display = "Sunrise",
            value = "sunrise",
        ),
        schema.Option(
            display = "Sunset",
            value = "sunset",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the sun rise and set times.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "items_to_display",
                name = "Items to display",
                desc = "Choose to show sunrise, sunset, or both.",
                icon = "sun",
                default = show_options[0].value,
                options = show_options,
            ),
            schema.Toggle(
                id = "24_hour",
                name = "24 hour clock",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
            ),
        ],
    )
