"""
Applet: Indy Car
Summary: Indy Car Race & Standings
Description: Show Indy Car next race info and current driver standings. - F1 Next Race from AMillionAir was the original inspiration for my race apps.  Track images by @samhi113.
Author: jvivona
"""

# 20230407  v23097
#  changed to new color schema option
#  samhi113 provided all the track images
# 20230826 jvivona  v23238
#  add qualifing date/time to json on server for NRI
#  add display of qualifing date/time on app
# 20230904 jvivona
#  fix date display remove leading 0

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23247

IMAGES = {
    #Indycar track type logos
    "oval": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAeCAYAAAA2Lt7lAAAACXBIWXMAAC4jAAAuIwF4pT92AAABuElEQVRIibWWu06CQRCFD4rxgoWYqC/gpTA2lFRUhpZCSh8AKnwHQ2PD6ygmhgegQRJRn0CNgmIMiXAsOL+QZfn/XQKTTIbsnJlvgb3FSGKRtuSoOwVwDeBLXtVYtJEM8xjJCkc2kAdWkWZqjyjApRp1SV6Q3CCZ1OeucuVZARmSfZLfJNOWfFq5vrRegCWSTc2wGDKJojRN1TgDciq8n1Y4NpGGtDkfQFVF5xH/EaQhyRtbPsbJfbAF4AVAD8AugJ+Ihbgu/ar07fGkbR9kAaxorUc1hzRV1WTNpA2QUrxzaB5YoE2ZCRvgRLHhAWgataGAfcVHD0BL8cAFsKP44QF4N2r/zbaKCKAPIO4BAIBfAMsAYuODrqepq/XMARugo5kkPBonVNNxAbwpJj0A24qfLoAnxUMPwJHiswsgWP8TazrEjo3aUEBdMeMBCLR1MzGPw24NwCuGh90ejP1j+wZtADUAmwDOIpoDQF7amtkcwNT7ID/DhZP3uXDiJB9UWAgBFKRpqWYhl/6AZHZan6jrsKwZdkmWOHq2lDh6tlyF9YgCLPzhFXiWw0u9K78N+1nG3bYP5mp/F5vVkadWLcYAAAAASUVORK5CYII=",
    "road": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAACXBIWXMAAC4jAAAuIwF4pT92AAABnUlEQVRIieXWv2sUQRjG8c/pqWlSWBoEg42kCFrYWNmI2GmhsTIgtgEjaqU2CoIW/qqsAhYWkliksPAvsFMrEQSFU2yNkBAtdCzuVpa9d25vL8IVPrA7y/O+M999d2Z2t5VSMg5tGwsV7V57B0fwHRNION5wrJuYwi6s4wPuZbNTSlJKz1O/bvdidcdS0LfQu5TS1ahfUfHv4J5+DlHlWxwcEJ/BXcxivhzYyhy/qYGWdQ5P/gV4CYca9pnHwlbB5zP+Y9zAi0z8ZHHRziQM0q3A62BfxbuPxYp3rLgYpeLpwHuG3RXvEl4HuVdGBe8MvA6+Bf7nwJssg1tBQu5d+ivwJjK5UWEpFyi0mfF/BF5urWyvA0cvkD365w32B17uJrMqwF+D2Fn983YZR4Pch03BxSNaxMVKbAqf8BRfcBgXgjFeNYWWwbCC05X4NK7VjLEyCri8uM7oVthEqwZ9+oYEEy+cnF7i1CjQCEx3Ty/X9HuEE0OMH22n9t9ToLle+wB7sQMb+IjrQwALdXrte92CDmANWv/dz97YwH8ARhmjTPwdskgAAAAASUVORK5CYII=",
    "street": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAACXBIWXMAAC4jAAAuIwF4pT92AAABY0lEQVRIie3WsUtWURjH8Y+lmYomWJYNQoqCQ9Qg0haE/4yOgkO7k9GQk0GTBQ4uDU4ObkFD0CLUECIvRTQ0aCmI0ONwz4Xr2/WVq+Tb8P7gcJ/zPOfcL+e595zztEWEZuhKU6ingJ8gsNRg3h3cxhSO0vi3VcDtJb6r6Xm9JHYPXVhP9iFqGEH3ecHdGMeD1B/CfXxPsEEsY1K2wo/4gBfYqgIFEZG3iSjXYkS8LvQ3I2IlIgbq5m0U3nVmK0v1V7zENB5jPvk38AXPsFN5hXUqA3/CAn4kcK5XWKsb24nZZI9iDn24iVW8qwKuoluYSfYInhditUbg/2oft8Dn1VNsy771LzwsBi/6czVSf2q5rhWDl5nqsWaB32CiGeATaoFb4H+mtlRlvpdVHMPYx2fcTb5c3/ATHakfyT6xP89QTVbRPMrBu7J7dFd2wnTJirgDWVb+oMffJ13gdwVwL/Zw4xji9Z/+bRF76AAAAABJRU5ErkJggg==",
    "stPete": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAHtJREFUOE/NlEEOACEIA+X/j2YDCUbZCgQvevLglEIqNJqHmtx4DGRmllaI6OfsaFUgA9a7zQSCGaQu0FSvQWQRWvXDKIH+UQRtPbZApF6q2AJPymnFKxDlMcrpnGpkywS8uEYu68fSsolUoTXTyqwq1TUi3+2x1RFZ/wCQUYARqK44sAAAAABJRU5ErkJgggAA",
    "texas": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAGFJREFUOE/tVNEKABAQs///6BN1WgshSeLNbMY5Q5BhZsYQACgnzQvoAiW28CxMi62d3U0568IRt5or7hZyIaeO+oW1jibM3/3VqnJfT91xj/B8AvDvzuklqdYNK26W0XiMkZa4GRzWnwkAAAAASUVORK5CYIIA",
    "longBeach": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAI5JREFUOE+9k1EOwCAIQ8f9D83CkhpEwLpk82tmPIq1ykUsVVUREV86bfDDCu3bigFFuAQBxQZovoDZWFa8VazACNOK34DdmN5xM24a9V+QUfMGjVFfgafQkybII1pd5r3A4mrVYBu5LJf0s/Jwdf72PXbnTkPOGEWbE91OA8Dc67jH08CnIK3o08MYYzU3+PC0GUkYj9wAAAAASUVORK5CYIIA",
    "barber": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAJBJREFUOE/FlFEKwDAIQ+f9D+1wELBpdO2gbH9lPms01q6Fz93dzCyHDgeVAxDDAxg/A0b2HFyCKmgbjFu725+qsi4VjNJbjUiSG7IF5lL/A1EFRlUaIDdKmeA8mB01zZFnGnqWvKpAni3OrUZl9vOgWuKt5vCSy+3g1rdPR1USW21qTgW+auQAXupPGtXrdwOqMdwZW9CQFwAAAABJRU5ErkJgggAA",
    "indyRC": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAHJJREFUOE/tlMEOwCAIQ9f//2gWDl0qAzSc9aSGBwRt8cgyM/MjAOh9tv8CHCKg+yrBHGR72uJRxSpoB+OC9Ue4w2lU0g5HlRGlVoJRp2OQiZjgqGJWfQ56tmgbne8wdrEOAp2If+BuirGz1AbVh6q3fAHJvMAZ3WeM6AAAAABJRU5ErkJgggAA",
    "indyOval": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAFFJREFUOE9jZEAC/////4/MR2YzMjIyovBBHJgGdElshsLUgE0BacSnCWYAsjpGYjWhax7ViCVSYYE5GjijgUNcXhwE2YrsooOiwgrZ48QWjwDxJ7gZPmCViwAAAABJRU5ErkJgggAA",
    "detroit": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAFZJREFUOE9jZCAA/v///x+khJGRkRFZKQoHmxmDXCPMeTC/gfgE/YhN0SDUiM1JIH8SdOqoRjyJnKLAgeUQ5CRGMDpgmtAVjmpEKnDoHziwrIQtTmFiADRCrBngf9iaAAAAAElFTkSuQmCC",
    "roadAmerica": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAItJREFUOE+9VEEOwCAIk/8/mgUTSMeqY4Zst2lbbAPIOPzkkDeWRFVVFxWRifMz+6dEA+AdElygRMx2pjA9XLzEsX3ElTerlD3HUxnpAYZ0I+ac8E5o3mVAxA0BUZE2YlkIgRVSWGkhVoKhFT8RcVxoh5C+pb2KTc/C2o7VbQp+rZj94yrpX1Zv2+8CgXDv0YnHq+cAAAAASUVORK5CYIIA",
    "midOhio": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAHVJREFUOE/tk0EOgDAIBO3/H42BZM2KQrfGi4m9NdnpAG3HJi4zM0SHL4VziLOx70BYsqAFs4UF74C5LNmIYNVXWWpnuECYlgr5AcjGdagg55bAx0b0Gua751S9ptNMGJz1yld1GGdQruIHm1/+peGs/A5ueQcf4Mf5v6W72gAAAABJRU5ErkJgggAA",
    "toronto": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAJdJREFUOE+1lFEOwCAIQ8f9D82CCYZhC7rEfSqvQAfKQz5VVbsSEUEh8NAgB5hAC3q2KDYqQYo5CMEDtLJcwINQb1FwgsykfO7wf9AUWU8xW2zF2hiudiC6vwuiquYAnJZ7F6TmsHmsHP8MeVau+l62I6/U9j7uZm33kZXbgswgCObg9nfkbYjGLE9HtcCVw7TUOBTomXwB84TAGQAwGpsAAAAASUVORK5CYIIA",
    "iowa": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAGlJREFUOE/tlFEKwCAMQ5f7H7pioaVkOuKXKPPPmGdp0eChZWZWJQBgT9+nGAAbZ7qD/XB2c1RjjwxyASjVao/hPwDMXld7/MHRqy6aD/TiqW585GoCvD6yCg6jI2BPL0q1z7DiaFDisQELV7fxED1XUwAAAABJRU5ErkJgggAA",
    "nashville": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAIBJREFUOE/Fk1EOgDAIQ8f9D42BBFIXYc0W1T+TPXllVcbmI5vceBdUVZ3NqIkGikie9Xcm4z+gmYUurWpQ6MaiqIwB4lQKzCmw2SU4bzRuoQUryJWre3zSw7MtiG2hKtcplhkZKDNi+zu9W0ZsBAv5xCMwA0MzVr/bsjnVB74HLyauZAEbK5HEAAAAAElFTkSuQmCC",
    "gateway": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAGBJREFUOE9jZMAB/v///x8mxcjIyIiuDEMApACkCVkxOh+kBkMjNkXYDCNaI7rmoaoRV8DAogJZHsWPoxpRk+IABg6hqMCZVkc1QpI5WYkcPfCIKgGIKqxgTkIuDrEVjwABubgZl6U4GQAAAABJRU5ErkJgggAA",
    "portland": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAI9JREFUOE+1lEsOwCAIROv9D00DCYbqMGCbunLhY/iN4zo4IiL6fOjpcgr5e7v/CkY1FWoprlALRFAJUijragZNNQR2IJtlHAeDotoDPIEmWEGrmoFvoG8gSqPTMOsqG7bbaDVDWWMW1MAYrbsUmx+jyz0gUoVG3twOfgqoGNNNa2StZ8tBl7wN+kw9C/YL3kiIuAW8f8HdAAAAAElFTkSuQmCC",
    "lagunaSeca": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYCAYAAADKx8xXAAAAAXNSR0IArs4c6QAAAIFJREFUOE/lklEOgCAMQ+n9Dz2DSZcOBix8ql8G9+ragnb54JJrXwLNzJgDALeWelwN93PCASSgymPqhB2sQF0kgLpCpdd3XlUqkM9XQA3LE+ZLtu7O95QqEz35DqlqDSVwteauT+yU+S27SV6HVqE+x4rSK6cJZ0LhrFr69OcfgA8pHGwNCkuMBgAAAABJRU5ErkJgggAA",
}

DEFAULTS = {
    "series": "car",
    "display": "nri",
    "timezone": "America/New_York",
    "time_24": False,
    "date_us": True,
    "api": "https://tidbyt.apis.ajcomputers.com/indy/api/{}/{}.json",
    "ttl": 1800,
    "positions": 16,
    "text_color": "#FFFFFF",
}

SIZES = {
    "regular_font": "tom-thumb",
    "datetime_font": "tom-thumb",
    "animation_frames": 30,
    "animation_hold_frames": 75,
    "data_box_bkg": "#000",
    "slide_duration": 99,
    "nri_data_box_width": 48,
    "drv_data_box_width": 64,
    "data_box_height": 26,
    "title_box_width": 64,
    "title_box_height": 7,
}

SERIES = {
    "car": ["NTT Indycar", "#0086bf80"],
    "nxt": ["Indy NXT Series", "#da291c80"],
}

def main(config):
    series = config.get("series", DEFAULTS["series"])
    displaytype = config.get("datadisplay", DEFAULTS["display"])
    data = json.decode(get_cachable_data(DEFAULTS["api"].format(series, displaytype)))
    if displaytype == "nri":
        displayrow = nextrace(config, data)
    else:
        displayrow = standings(config, data)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Text(SERIES[series][0], font = "tom-thumb"),
                    color = SERIES[series][1],
                ),
                displayrow,
            ],
        ),
    )

# ##############################################
#            Next Race  Functions
# ##############################################
def nextrace(config, data):
    timezone = config.get("$tz", DEFAULTS["timezone"])  # Utilize special timezone variable to get TZ - otherwise assume US Eastern w/DST
    date_and_time = data["start"]
    date_and_time3 = time.parse_time(date_and_time, "2006-01-02T15:04:05-0700").in_location(timezone)
    date_str = date_and_time3.format("Jan 2" if config.bool("is_us_date_format", DEFAULTS["date_us"]) else "2 Jan").title()  #current format of your current date str
    time_str = "TBD" if date_and_time.endswith("T00:00:00-0500") else date_and_time3.format("15:04 " if config.bool("is_24_hour_format", DEFAULTS["time_24"]) else "3:04pm")[:-1]
    if data.get("qual", "TBD") == "TBD":
        qual_date_str = "TBD"
        qual_time_str = "TBD"
    else:
        qual_date_and_time = data.get("qual", "TBD")
        qual_date_and_time3 = time.parse_time(qual_date_and_time, "2006-01-02T15:04:05-0700").in_location(timezone)
        qual_date_str = qual_date_and_time3.format("Jan 2" if config.bool("is_us_date_format", DEFAULTS["date_us"]) else "2 Jan").title()  #current format of your current date str
        qual_time_str = "TBD" if qual_date_and_time.endswith("T00:00:00-0500") else qual_date_and_time3.format("15:04 " if config.bool("is_24_hour_format", DEFAULTS["time_24"]) else "3:04pm")[:-1]
    text_color = config.get("text_color", DEFAULTS["text_color"])

    return render.Row(expanded = True, children = [
        render.Box(width = 16, height = 26, child = render.Image(src = base64.decode(IMAGES[data["trackid"]]), height = 24, width = 14)),
        #render.Box(width = 16, height = 26, child = render.Image(src = base64.decode(IMAGES[data["type"]]), height = 24, width = 14)),
        fade_child(data["name"], data["track"], "Race\n{}\n{}\nTV: {}".format(date_str, time_str, data["tv"].upper()), "Qual\n{}\n{}".format(qual_date_str, qual_time_str), text_color),
    ])

def fade_child(race, track, date_time_tv, qual_string, text_color):
    # IndyNXT doesn't name their races, so we're just going to flip back & forth between track & date/time/tv
    if race == track:
        return render.Animation(
            children =
                createfadelist(track, SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(qual_string, SIZES["animation_hold_frames"], SIZES["datetime_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(date_time_tv, SIZES["animation_hold_frames"], SIZES["datetime_font"], text_color, SIZES["nri_data_box_width"], "center"),
        )
    else:
        return render.Animation(
            children =
                createfadelist(race, SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(track, SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(qual_string, SIZES["animation_hold_frames"], SIZES["datetime_font"], text_color, SIZES["nri_data_box_width"], "center") +
                createfadelist(date_time_tv, SIZES["animation_hold_frames"], SIZES["datetime_font"], text_color, SIZES["nri_data_box_width"], "center"),
        )

# ##############################################
#            Standings  Functions
# ##############################################
# we're going to display 3 marquees, 9 total data elements, 3 on each line
def standings(config, data):
    standingformat = "{}\n{}\n{}\n{}"

    text_color = config.get("text_color", DEFAULTS["text_color"])
    text = drvrtext(data)

    return render.Animation(
        children =
            createfadelist(standingformat.format(text[0], text[1], text[2], text[3]), SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["drv_data_box_width"], "right") +
            createfadelist(standingformat.format(text[4], text[5], text[6], text[7]), SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["drv_data_box_width"], "right") +
            createfadelist(standingformat.format(text[8], text[9], text[10], text[11]), SIZES["animation_hold_frames"], SIZES["regular_font"], text_color, SIZES["drv_data_box_width"], "right"),
    )

def drvrtext(data):
    text = []  # preset 4 text strings

    # layout is:   1 digit position, 10 char driver last name, 4 digit points - with spaces between values
    # loop through drivers and parse the data

    positions = len(data) if len(data) <= DEFAULTS["positions"] else DEFAULTS["positions"]

    for i in range(0, positions):
        text.append("{} {} {}".format(text_justify_trunc(2, str(data[i]["RANK"]), "right"), text_justify_trunc(9, data[i]["DRIVER"].replace(" Jr.", "").split(" ")[-1], "left"), text_justify_trunc(3, str(data[i]["TOTAL"]), "right")))

    return text

# ##############################################
#            Text Display Functions
# ##############################################

def createfadelist(text, cycles, text_font, text_color, data_box_width, text_align):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

    # this is a pure genius technique and is borrowed from @CubsAaron countdown_clock
    # need to ponder if there is a different way to do it if we want something other than grey
    # use alpha channel to fade in and out

    # go from none to full color
    for x in alpha_values:
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color + x, data_box_width, text_align))
    for x in range(cycles):
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color, data_box_width, text_align))

    # go from full color back to none
    for x in alpha_values[5:0]:
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color + x, data_box_width, text_align))
    return cycle_list

def fadelistchildcolumn(text, font, color, data_box_width, text_align):
    return render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(content = text, font = font, color = color, align = text_align, width = data_box_width)])

# ##############################################
#           Schema Funcitons
# ##############################################

dispopt = [
    schema.Option(
        display = "Next Race",
        value = "nri",
    ),
    schema.Option(
        display = "Driver Standings",
        value = "drv",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "series",
                name = "Series",
                desc = "Select which series to display",
                icon = "flagCheckered",
                default = DEFAULTS["series"],
                options = [
                    schema.Option(
                        display = "NTT Indycar",
                        value = "car",
                    ),
                    schema.Option(
                        display = "Indycar NXT Series",
                        value = "nxt",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "datadisplay",
                name = "Display Type",
                desc = "What data to display?",
                icon = "eye",
                default = "nri",
                options = dispopt,
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "The color for Standings / Race / Track / Time text.",
                icon = "palette",
                default = DEFAULTS["text_color"],
            ),
            schema.Generated(
                id = "nri_generated",
                source = "datadisplay",
                handler = show_nri_options,
            ),
        ],
    )

def show_nri_options(datadisplay):
    if datadisplay == "nri":
        return [
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = DEFAULTS["time_24"],
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format.",
                icon = "calendarDays",
                default = DEFAULTS["date_us"],
            ),
        ]
    else:
        return []

# ##############################################
#           General Funcitons
# ##############################################
def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = DEFAULTS["ttl"])
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def text_justify_trunc(length, text, direction):
    #  thanks to @inxi and @whyamihere / @rs7q5 for the codepoints() and codepoints_ords() help
    chars = list(text.codepoints())
    textlen = len(chars)

    # if string is shorter than desired - we can just use the count of chars (not bytes) and add on spaces - we're good
    if textlen < length:
        for _ in range(0, length - textlen):
            text = " " + text if direction == "right" else text + " "
    else:
        # text is longer - need to trunc it get the list of characters & trunc at length
        text = ""  # clear out text
        for i in range(0, length):
            text = text + chars[i]

    return text
