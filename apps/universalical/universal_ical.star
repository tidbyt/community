"""
Applet: Universal ICal
Summary: Displays Calendar from iCal
Description: Displays Calendar from iCal (.ics) files.
Author: quesurifn
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    location = config.str(P_LOCATION)
    location = json.decode(location) if location else {}
    usersTz = location.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )
    ics_url = config.str("ics_url", DEFAULT_ICS_URL)
    if (ics_url == None):
        fail("ICS_URL not set in config")

    now = time.now().in_location(usersTz)
    ics = http.post(
        url = LAMBDA_URL,
        json_body = {"icsUrl": ics_url, "tz": usersTz},
    )
    if (ics.status_code != 200):
        fail("Failed to fetch ICS file")

    event = ics.json()["data"]
    if not event:
        # no events in the calendar
        return build_calendar_frame(now, usersTz)
    if event["detail"]["thirtyMinuteWarning"]:
        return build_calendar_frame(now, usersTz, event)
    elif event["detail"]["tenMinuteWarning"]:
        return build_event_frame(event)
    elif event["detail"]["fiveMinuteWarning"]:
        return build_event_frame(event)
    elif event["detail"]["oneMinuteWarning"]:
        return build_event_frame(event)
    elif event["detail"]["inProgress"]:
        return build_event_frame(event)
    elif event["detail"]["isToday"]:
        return build_calendar_frame(now, usersTz)
    else:
        return build_calendar_frame(now, usersTz)

def build_calendar_frame(now, usersTz, event = None):
    month = now.format("Jan")

    # top half displays the calendar icon and date
    top = [
        render.Row(
            cross_align = "center",
            expanded = True,
            children = [
                render.Image(src = CALENDAR_ICON, width = 9, height = 11),
                render.Box(width = 2, height = 1),
                render.Text(
                    month.upper(),
                    color = "#ff83f3",
                    offset = -1,
                ),
                render.Box(width = 1, height = 1),
                render.Text(
                    str(now.day),
                    color = "#ff83f3",
                    offset = -1,
                ),
            ],
        ),
        render.Box(height = 2),
    ]

    # bottom half displays the upcoming event, if there is one.
    # otherwise it just shows the time.
    if event:
        eventStart = time.from_timestamp(int(event["start"])).in_location(usersTz)
        color = "#ff78e9"
        fiveMinuteWarning = event["detail"]["fiveMinuteWarning"] or False
        oneMinuteWarning = event["detail"]["oneMinuteWarning"] or False
        if fiveMinuteWarning:
            color = "#ff5000"
        if oneMinuteWarning:
            color = "#9000ff"

        baseChildren = [
            render.Marquee(
                width = 64,
                child = render.Text(
                    event["name"].upper(),
                ),
            ),
            render.Text(
                eventStart.format("at 3:04 PM"),
                color = color,
            ),
        ]

        if event["detail"]["minutesUntilStart"] <= 5:
            baseChildren.pop()
            baseChildren.append(
                render.Text(
                    "in %d min" % event["detail"]["minutesUntilStart"],
                    color = color,
                ),
            )

            baseChildren = [
                render.Column(
                    expanded = True,
                    children = [
                        render.Animation(
                            baseChildren,
                        ),
                    ],
                ),
            ]

        bottom = baseChildren
    else:
        bottom = [
            render.Column(
                expanded = True,
                main_align = "end",
                children = [
                    render.WrappedText(
                        "NO MORE MEETINGS :-)",
                        color = "#fff500",
                        height = 16,
                    ),
                ],
            ),
        ]

    return render.Root(
        delay = FRAME_DELAY,
        child = render.Box(
            padding = 2,
            color = "#111",
            child = render.Column(
                expanded = True,
                children = top + bottom,
            ),
        ),
    )

def build_event_frame(event):
    minutes_to_start = event["detail"]["minutesUntilStart"]
    minutes_to_end = event["detail"]["minutesUntilEnd"]
    hours_to_end = event["detail"]["hoursToEnd"]

    if minutes_to_start >= 1:
        tagline = ("in %d" % minutes_to_start, "min")
    elif hours_to_end >= 99:
        tagline = ("", "now")
    elif minutes_to_end >= 99:
        tagline = ("Ends in %d" % hours_to_end, "h")
    elif minutes_to_end > 1:
        tagline = ("Ends in %d" % minutes_to_end, "min")
    else:
        tagline = ("", "almost done")

    baseChildren = [
        render.WrappedText(
            event["name"].upper(),
            height = 17,
        ),
        render.Box(
            color = "#ff78e9",
            height = 1,
        ),
        render.Box(height = 3),
        render.Row(
            main_align = "end",
            expanded = True,
            children = [
                render.Text(
                    tagline[0],
                    color = "#fff500",
                ),
                render.Box(height = 1, width = 1),
                render.Text(
                    tagline[1],
                    color = "#fff500",
                ),
            ],
        ),
    ]
    return render.Root(
        child = render.Box(
            padding = 2,
            child = render.Column(
                main_align = "start",
                cross_align = "start",
                expanded = True,
                children = baseChildren,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = P_LOCATION,
                name = "Location",
                desc = "Location for the display of date and time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "ics_url",
                name = "iCalendar URL",
                desc = "The URL of the iCalendar file",
                icon = "calendar",
                default = DEFAULT_ICS_URL,
            ),
        ],
    )

P_LOCATION = "location"
DEFAULT_TIMEZONE = "America/New_York"
FRAME_DELAY = 500
LAMBDA_URL = "https://xmd10xd284.execute-api.us-east-1.amazonaws.com/ics-next-event"
CALENDAR_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAALCAYAAACtWacbAAAAAXNSR0IArs4c6QAAAE9JREFUKFNjZGBgYJgzZ87/lJQURlw0I0xRYEMHw/qGCgZ0GqSZ8a2Myv8aX1eGls27GXDRYEUg0/ABxv///xOn6OjRowzW1tYMuOghaxIAD/ltSOskB+YAAAAASUVORK5CYII=")
DEFAULT_ICS_URL = "https://www.phpclasses.org/browse/download/1/file/63438/name/example.ics"
