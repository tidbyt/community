load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    location = config.str(P_LOCATION)
    location = json.decode(location) if location else {}
    timezone = location.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )
    ics_url = config.str("ics_url", DEFAULT_ICS_URL)
    if (ics_url == None):
        fail("ICS_URL not set in config")

    now = time.now().in_location(timezone)
    ics = http.post(
        url = LAMBDA_URL,
        json_body = {"icsUrl": ics_url, "tz": usersTz},
    )
    if (ics.status_code != 200):
        fail("Failed to fetch ICS file")

    event = ics.json()["data"]

    if event["detail"]["inProgress"]:
        return build_event_frame(event)
    elif event["detail"]:
        return build_calendar_frame(now, usersTz, event)
    else:
        return build_calendar_frame(now, usersTz, event)

def get_calendar_text_color(event):
    DEFAULT = "#ff83f3"
    if event["detail"]["minutesUntilStart"] <= 5:
        return "#ff5000"
    elif event["detail"]["minutesUntilStart"] <= 2:
        return "#9000ff"
    else:
        return DEFAULT

def should_animate_text(event):
    return event["detail"]["minutesUntilStart"] <= 5

def get_calendar_text_copy(event, now, eventStart):
    DEFAULT = eventStart.format("at 3:04 PM")
    if not event["detail"] and not DEFAULT_SHOW_EXPANDED_TIME_WINDOW:
        return "DONE FOR THE DAY :-)"
    elif not event["detail"] and DEFAULT_SHOW_EXPANDED_TIME_WINDOW and event["detail"]["isTomorrow"]:
        return "Tomorrow at " + eventStart.format("3:04 PM")
    elif event["detail"] and DEFAULT_SHOW_EXPANDED_TIME_WINDOW:
        return "in %s" % humanize.relative_time(now, eventStart)
    elif event["detail"] and event["minutesUntilStart"] <= 5:
        return "in %d min" % event["detail"]["minutesUntilStart"]
    else:
        return DEFAULT

def get_calendar_render_data(now, usersTz, event):
    baseObject = {
        "currentMonth": now.format("Jan").upper(),
        "currentDay": humanize.ordinal(now.day),
        "now": now,
    }

    if not event:
        baseObject["hasEvent"] = False
        return baseObject

    startTime = time.from_timestamp(int(event["start"])).in_location(usersTz)
    eventObject = {
        "summary": event["name"].upper(),
        "eventStartTimestamp": startTime,
        "copy": get_calendar_text_copy(event, now, startTime),
        "textColor": get_calendar_text_color(event),
        "shouldAnimateText": should_animate_text(event),
        "hasEvent": True,
    }

    return dict(baseObject.items() + eventObject.items())

def render_calendar_base_object(top, bottom):
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

def get_calendar_top(data):
    return [
        render.Row(
            cross_align = "center",
            expanded = True,
            children = [
                render.Image(src = CALENDAR_ICON, width = 9, height = 11),
                render.Box(width = 2, height = 1),
                render.Text(
                    data["currentMonth"],
                    color = "#ff83f3",
                    offset = -1,
                ),
                render.Box(width = 1, height = 1),
                render.Text(
                    data["currentDay"],
                    color = "#ff83f3",
                    offset = -1,
                ),
            ],
        ),
        render.Box(height = 2),
    ]

def get_calendar_bottom(data):
    children = []
    if data["hasEvent"]:
        children.append(
            render.Marquee(
                width = 64,
                child = render.Text(
                    data["summary"],
                ),
            ),
        )
        children.append(
            render.Text(
                data["copy"],
                color = data["textColor"],
            ),
        )

    if not data["hasEvent"]:
        children.append(
            render.WrappedText(
                "DONE FOR THE DAY :-)",
                color = "#ff83f3",
            ),
        )

    elif data["shouldAnimateText"]:
        children = [
            render.Animation(
                children,
            ),
        ]

    return [
        render.Column(
            expanded = True,
            main_align = "end",
            children = children,
        ),
    ]

def build_calendar_frame(now, usersTz, event):
    data = get_calendar_render_data(now, usersTz, event)

    print(data)

    # top half displays the calendar icon and date
    top = get_calendar_top(data)
    bottom = get_calendar_bottom(data)

    # bottom half displays the upcoming event, if there is one.
    # otherwise it just shows the time.

    return render_calendar_base_object(
        top = top,
        bottom = bottom,
    )

def get_event_frame_copy_config(event):
    minutes_to_start = event["detail"]["minutesUntilStart"]
    minutes_to_end = event["detail"]["minutesUntilEnd"]
    hours_to_end = event["detail"]["hoursToEnd"]

    tagline = None
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

    return {
        "summary": event["name"],
        "tagline": tagline,
        "bgColor": "#ff78e9",
        "textColor": "#fff500",
    }

def build_event_frame(event):
    data = get_event_frame_copy_config(event)
    baseChildren = [
        render.WrappedText(
            data["summary"].upper(),
            height = 17,
        ),
        render.Box(
            color = data["bgColor"],
            height = 1,
        ),
        render.Box(height = 3),
        render.Row(
            main_align = "end",
            expanded = True,
            children = [
                render.Text(
                    data["tagline"][0],
                    color = data["textColor"],
                ),
                render.Box(height = 1, width = 1),
                render.Text(
                    data["tagline"][1],
                    color = data["textColor"],
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
                id = P_ICS_URL,
                name = "iCalendar URL",
                desc = "The URL of the iCalendar file.",
                icon = "calendar",
                default = DEFAULT_ICS_URL,
            ),
            schema.Toggle(
                id = P_SHOW_EXPANDED_TIME_WINDOW,
                name = "Show Expanded Time Window",
                desc = "Show events outside of a 24 hour window.",
                default = DEFAULT_SHOW_EXPANDED_TIME_WINDOW,
                icon = "clock",
            ),
        ],
    )

P_LOCATION = "location"
P_ICS_URL = "ics_url"
P_SHOW_EXPANDED_TIME_WINDOW = "show_expanded_time_window"

DEFAULT_SHOW_EXPANDED_TIME_WINDOW = True
DEFAULT_TIMEZONE = "America/New_York"
FRAME_DELAY = 500
LAMBDA_URL = "https://xmd10xd284.execute-api.us-east-1.amazonaws.com/ics-next-event"
CALENDAR_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAALCAYAAACtWacbAAAAAXNSR0IArs4c6QAAAE9JREFUKFNjZGBgYJgzZ87/lJQURlw0I0xRYEMHw/qGCgZ0GqSZ8a2Myv8aX1eGls27GXDRYEUg0/ABxv///xOn6OjRowzW1tYMuOghaxIAD/ltSOskB+YAAAAASUVORK5CYII=")

# DEFAULT_ICS_URL = "https://www.phpclasses.org/browse/download/1/file/63438/name/example.ics"
DEFAULT_ICS_URL = "https://outlook.office365.com/owa/calendar/0b5c32636665474191e0fdf787e3bf1e@ocvibe.com/ee48be8cb2124c6b88715a2503881e7f10382479269454683591/calendar.ics"
