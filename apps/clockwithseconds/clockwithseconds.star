"""
Applet: Morph Clock
Summary: A clock w/morphing digits
Description: A clock with digits that morph from one to the next.
Author: D. Segel
"""

# Morphing Clock
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

DEFAULT_COLOR = "#ED3209"
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
    loc = config.get("location", DEFAULT_LOCATION)
    location = json.decode(loc)
    timezone = location["timezone"]
    local_time = time.now().in_location(timezone)
    hour = local_time.hour
    minute = local_time.minute
    second = local_time.second

    min = minute
    hr = hour
    time_frames = []
    for sec in range(second + 1, second + 17):    # the +1 is to allow processing and loading time
        # print("Current sec = {}, second = {}, min = {}".format(sec, second, min))
        if sec > 59:
            sec -= 60
            min = minute + 1
        if min > 59:
            min -= 60
            hr = hour + 1
        if hr > 23 and time_format_24 == "true":
            hr -= 23
        elif hr > 12:
            hr -= 12
        hr_str = "0" + str(hr) if hr < 10 else str(hr)
        min_str = "0" + str(min) if min < 10 else str(min)
        sec_str = "0" + str(sec) if sec < 10 else str(sec)
        the_current_time = hr_str + ":" + min_str + ":" + sec_str
        time_frame = render.Padding(pad = (9, 9, 0, 0), child = render.Text(content = the_current_time, font = "6x13"))
        time_frames.append(time_frame)
    return render.Root(
        delay = 1000,
        max_age = 15,
        child = render.Animation(children = time_frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "24_hour_time",
                name = "Use a 24-hour clock",
                desc = "Toggle 12/24 hour clock",
                icon = "gear",
                default = False,
            ),
        ],
    )

def bitread(byte, index):
    if index < 0 or index > 7:
        return "Index out of range"
    return (byte >> index) & 1
