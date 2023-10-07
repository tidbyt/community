"""
Applet: ClockWithSeconds
Summary: A clock with seconds
Description: A clock with seconds
Author: D. Segel
"""

# Clock with Seconds
# Copyright (c) 2023 Daniel Segel
# MIT License
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

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_CLOCK_COLOR = "#09ED20"
DEFAULT_TIME_FORMAT = "false"
DEFAULT_LOCATION = """
{
    "lat": "38.5465",
    "lng": "-121.7465",
    "description": "Davis, CA",
    "locality": "Davis",
    "timezone": "America/Los_Angeles"
}
"""

def main(config):
    time_format_24 = config.get("24_hour_time", DEFAULT_TIME_FORMAT)
    am_pm_option = config.get("am_pm_option", "no_am_pm")
    clock_color = config.get("clock_color", DEFAULT_CLOCK_COLOR)
    time_offset = config.get("time_offset", 0)
    loc = config.get("location", DEFAULT_LOCATION)
    blink_colon = config.get("blink_colon", "false")
    location = json.decode(loc)
    timezone = location["timezone"]
    local_time = time.now().in_location(timezone)
    hour = local_time.hour
    minute = local_time.minute
    second = local_time.second
    second += int(time_offset)

    time_frames = []
    sec = second - 1
    min = minute
    hr = hour
    for x in range(120):
        x = x
        sec += 1
        if sec > 59:
            sec -= 60
            min += 1
        if min > 59:
            min -= 60
            hr += 1
        if hr > 12 and time_format_24 == "false":
            hr -= 12

        hr_str = "0" + str(hr) if hr < 10 else str(hr)
        min_str = "0" + str(min) if min < 10 else str(min)
        sec_str = "0" + str(sec) if sec < 10 else str(sec)
        if blink_colon == "true":
            if sec % 2 == 0:
                the_current_time = hr_str + ":" + min_str + ":" + sec_str
            else:
                the_current_time = hr_str + " " + min_str + " " + sec_str
        else:
            the_current_time = hr_str + ":" + min_str + ":" + sec_str

        left_margin = 9
        if time_format_24 == "false":
            left_margin = 3
            if am_pm_option == "am_pm":
                if hour > 12:
                    the_current_time = the_current_time + "pm"
                else:
                    the_current_time = the_current_time + "am"
            elif am_pm_option == "AM_PM":
                if hour > 12:
                    the_current_time = the_current_time + "PM"
                else:
                    the_current_time = the_current_time + "AM"
            else:
                left_margin += 5

        # print("Adding frame for {}".format(the_current_time))

        time_frame = render.Padding(pad = (left_margin, 10, 0, 0), child = render.Text(content = the_current_time, font = "6x13", color = clock_color))
        time_frames.append(time_frame)

    return render.Root(
        delay = 1000,
        max_age = 120,
        child = render.Animation(children = time_frames),
        # child = animation.Transformation(
        #     child =
        # )
    )

time_offset_options = [
    schema.Option(
        display = "-10",
        value = "-10",
    ),
    schema.Option(
        display = "-9",
        value = "-9",
    ),
    schema.Option(
        display = "-8",
        value = "-8",
    ),
    schema.Option(
        display = "-7",
        value = "-7",
    ),
    schema.Option(
        display = "-6",
        value = "-6",
    ),
    schema.Option(
        display = "-5",
        value = "-5",
    ),
    schema.Option(
        display = "-4",
        value = "-4",
    ),
    schema.Option(
        display = "-3",
        value = "-3",
    ),
    schema.Option(
        display = "-2",
        value = "-2",
    ),
    schema.Option(
        display = "-1",
        value = "-1",
    ),
    schema.Option(
        display = "0",
        value = "0",
    ),
    schema.Option(
        display = "+1",
        value = "1",
    ),
    schema.Option(
        display = "+2",
        value = "2",
    ),
    schema.Option(
        display = "+3",
        value = "3",
    ),
    schema.Option(
        display = "+4",
        value = "4",
    ),
    schema.Option(
        display = "+5",
        value = "5",
    ),
    schema.Option(
        display = "+6",
        value = "6",
    ),
    schema.Option(
        display = "+7",
        value = "7",
    ),
    schema.Option(
        display = "+8",
        value = "8",
    ),
    schema.Option(
        display = "+9",
        value = "9",
    ),
    schema.Option(
        display = "+10",
        value = "10",
    ),
]

def color_options(custom_colors):
    if custom_colors == "true":
        return [
            schema.Color(
                id = "clock_color",
                name = "Clock Color",
                desc = "Color of the Time",
                icon = "brush",
                default = DEFAULT_CLOCK_COLOR,
            ),
        ]
    else:
        return []

am_pm_options = [
    schema.Option(
        display = "Do not show AM or PM",
        value = "no_am_pm",
    ),
    schema.Option(
        display = "Show with lowercase: am/pm",
        value = "am_pm",
    ),
    schema.Option(
        display = "Show with uppercase: AM/PM",
        value = "AM_PM",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for time source",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "24_hour_time",
                name = "Use a 24-hour clock",
                desc = "Toggle 12/24 hour clock",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "am_pm_option",
                name = "AM/PM Option",
                desc = "Show AM/PM",
                icon = "gear",
                default = am_pm_options[0].value,
                options = am_pm_options,
            ),
            schema.Toggle(
                id = "blink_colon",
                name = "Blink the Colon",
                desc = "Blink the colon",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "time_offset",
                name = "Time Offset",
                desc = "Adjust + or - Seconds",
                icon = "clock",
                default = time_offset_options[5].value,
                options = time_offset_options,
            ),
            schema.Toggle(
                id = "custom_colors",
                name = "Use Custom Colors",
                desc = "A toggle to enable custom colors",
                icon = "gear",
                default = False,
            ),
            schema.Generated(
                id = "generated",
                source = "custom_colors",
                handler = color_options,
            ),
        ],
    )

def bitread(byte, index):
    if index < 0 or index > 7:
        return "Index out of range"
    return (byte >> index) & 1
