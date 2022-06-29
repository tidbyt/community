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

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("sunrise.star", "sunrise")

# Defaults
DEFAULT_LOCATION = {
    "lat": 53.79444,
    "lng": -2.245278,
    "locality": "Manchester, UK",
    "timezone": "GMT",
}
DEFAULT_24_HOUR = False
DEFAULT_ITEMS_TO_DISPLAY = "both"

# Images
sunriseImage = """iVBORw0KGgoAAAANSUhEUgAAAB4AAAAOCAYAAAA45qw5AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAHqADAAQAAAABAAAADgAAAACqoaCHAAAA9klEQVQ4EcVUvQoCMQzuieDkJK6Ck+DsIr6RD+TLODnILc6ugqvo4gNUvuoX0pLe9fCvS5rkS74kzZ1zXzr+svJNqfuRc+sDuJ7dIrOlLCejSttBVI33ka3J39PO0ntKijiQsku/G3h3PDjRjaKeFRZ2ahGmxQZSGOcLcVmTyI5GojpcLFKGp+Sd39jqmiPFeHOHGBYQE+eilL0+X8MC6gKYTDpWeF6JEZ2XT0khb33j12KBuOQzAk53C50H40RnmjzoxlYz5m3JN2SiNl22erq5N/5pmPC0HoaYUjzjKBlP/edSOk6ZdUesUttSPHQLR5uF/4vtARekdeCaFV5xAAAAAElFTkSuQmCC"""
sunsetImage = """iVBORw0KGgoAAAANSUhEUgAAAB4AAAAOCAYAAAA45qw5AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAHqADAAQAAAABAAAADgAAAACqoaCHAAAAyElEQVQ4EWNgGCDASAt7582b9x/Z3KSkJAx7MASQNVDKRnYAuuVMlBqOTz+6Zchq8Vr8/7U1SpAhaySGjexjdPUsyAIgixhFj+IMfkLyMLPQLcTnc5geBpgvQTQMgyRh4nCFFDKw+g5uybUzDAxaJmAr8IUEOW7AsBjFUpiJNLAcbvH/g+z/Ga7/hFmFm9ZkZ2C0/wnXh1shfhmwAYrTPpOceu9n8eLVi0seJo7fWTSUxRlksFCAuRDGx+cWkFp0dTD9+PTRVQ4Ar1hU6EpgkiwAAAAASUVORK5CYII="""

def main(config):
    # Get longditude and latitude from location
    location = config.get("location", DEFAULT_LOCATION)
    lat = float(location.get("lat"))
    lng = float(location.get("lng"))

    # Get sunset and sunrise times
    now = time.now()
    sunriseTime = sunrise.sunrise(lat, lng, now)
    sunsetTime = sunrise.sunset(lat, lng, now)

    # Get whether to display in 24h format
    display24Hour = config.bool("24_hour", DEFAULT_24_HOUR)
    itemsToDisplay = config.get("items_to_display", DEFAULT_ITEMS_TO_DISPLAY)

    if sunriseTime == None:
        sunriseText = "  None"
    elif display24Hour:
        sunriseText = "  %s" % sunriseTime.in_location(location["timezone"]).format("15:04")
    else:
        sunriseText = "%s" % sunriseTime.in_location(location["timezone"]).format("3:04 PM")

    if sunsetTime == None:
        sunsetText = "  None"
    elif display24Hour:
        sunsetText = "  %s" % sunsetTime.in_location(location["timezone"]).format("15:04")
    else:
        sunsetText = "%s" % sunsetTime.in_location(location["timezone"]).format("3:04 PM")

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
                    render.Padding(
                        pad = (-1, -1, 0, 0),
                        child = render.Text(sunriseText),
                    ),
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
                render.Padding(
                    pad = (-1, -1, 0, 0),
                    child = render.Text(sunsetText),
                ),
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
                icon = "place",
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
