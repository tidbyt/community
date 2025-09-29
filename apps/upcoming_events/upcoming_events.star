"""
Applet: Events List
Summary: List of upcoming events
Description: Displays a list of upcoming events from a Google Calendar iCal URL.
Author: jblaker
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEBUG_URL = ""

def main(config):
    url = config.str("calendar_url", "")
    if url == "":
        return render.Root(
            render.Padding(
                pad = (1, 1, 1, 1),
                child = render.WrappedText("Enter a Google Calender iCal URL", font = "tom-thumb"),
            ),
        )
    rep = http.get(url)
    if rep.status_code != 200:
        fail("Google Calender request failed with status %d", rep.status_code)
    lines = rep.body().split("\n")

    events = []
    event = {}
    creatingEvent = False

    for line in lines:
        if line.startswith("BEGIN:VEVENT"):
            creatingEvent = True
            event = {}

        if line.startswith("END:VEVENT"):
            creatingEvent = False
            date = event.get("date")
            if date != None:
                if date >= time.now():
                    events.append(event)

        if creatingEvent:
            if line.startswith("SUMMARY:"):
                event["name"] = line.split(":")[1]

            if line.startswith("DTSTART:"):
                timestamp = line.split(":")[1].replace("\x0d", "")

                dateFormat = "20060102T150405Z"
                timezone = config.get("timezone") or "America/New_York"
                eventDate = time.parse_time(timestamp, dateFormat, timezone)

                event["date"] = eventDate
                event["formattedDate"] = eventDate.in_location(timezone).format("01/02")

    maxEvents = int(config.get("number_of_events", "5"))
    events = sorted(events, key = lambda x: x["date"])[:maxEvents]

    layout = []

    counter = 0

    if len(events) > 0:
        for event in events:
            rowColor = "#ffc300" if ((counter % 2) == 0) else "#a2d9ce"
            layout.append(
                render.Padding(
                    pad = (0, 0, 0, 3),
                    child = render.Row(
                        children = [
                            render.Column(
                                children = [
                                    render.WrappedText(content = event["name"], font = "tom-thumb", color = str(rowColor), width = 42),
                                ],
                            ),
                            render.Column(
                                children = [
                                    render.Padding(
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(content = event["formattedDate"], font = "tom-thumb"),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            )
            counter += 1

    else:
        return render.Root(
            render.Padding(
                pad = (1, 1, 1, 1),
                child = render.WrappedText("Could not parse calender data.", font = "tom-thumb"),
            ),
        )

    scroll_opt = config.str("speed", "100")
    return render.Root(
        delay = int(scroll_opt),  #speed up scroll text
        show_full_animation = True,
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Marquee(
                scroll_direction = "vertical",
                width = 60,
                height = 30,
                child = render.Column(
                    children = layout,
                ),
            ),
        ),
    )

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slow", value = "200"),
        schema.Option(display = "Normal (Default)", value = "100"),
        schema.Option(display = "Fast", value = "30"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "calendar_url",
                name = "Calendar URL",
                desc = "Your Google Calendar iCal URL",
                icon = "calendar",
            ),
            schema.Text(
                id = "number_of_events",
                name = "Number of Events",
                desc = "The number of events you want to see.",
                icon = "gear",
                default = "5",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Change speed that text scrolls.",
                icon = "gear",
                default = scroll_speed[1].value,
                options = scroll_speed,
            ),
        ],
    )
