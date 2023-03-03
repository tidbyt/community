"""
Applet: Airbnb Calendar
Summary: Calendar for Airbnb hosts
Description: A calendar that shows the coming week of occupancy for multiple Airbnb listings.
Author: Jed Schmidt
"""

load("cache.star", "cache")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SCREEN_HEIGHT = 32
SCREEN_WIDTH = 64
MAX_LISTING_COUNT = 5
DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_CHECKIN_HOUR = 15
DEFAULT_CHECKOUT_HOUR = 11
DEFAULT_HOURS_PER_PIXEL = 2

COLORS = {
    "PAST": ("#333", "#333"),
    "FUTURE": ("#aaa", "#666"),
    "PRESENT": ("#ff5a5f", "#ff5a5f"),
    "BLOCKED": ("#666", "#111"),
}

LETTERS = {
    "M": render.Stack([
        render.Box(width = 1, height = 3, color = "#666"),
        render.Padding(pad = (1, 0, 0, 0), child = render.Box(width = 1, height = 1, color = "#666")),
        render.Padding(pad = (2, 0, 0, 0), child = render.Box(width = 1, height = 3, color = "#666")),
    ]),
    "T": render.Stack([
        render.Box(width = 3, height = 1, color = "#666"),
        render.Padding(pad = (1, 1, 0, 0), child = render.Box(width = 1, height = 2, color = "#666")),
    ]),
    "W": render.Stack([
        render.Box(width = 1, height = 3, color = "#666"),
        render.Padding(pad = (1, 2, 0, 0), child = render.Box(width = 1, height = 1, color = "#666")),
        render.Padding(pad = (2, 0, 0, 0), child = render.Box(width = 1, height = 3, color = "#666")),
    ]),
    "F": render.Stack([
        render.Box(width = 3, height = 1, color = "#666"),
        render.Padding(pad = (0, 1, 0, 0), child = render.Box(width = 2, height = 1, color = "#666")),
        render.Padding(pad = (0, 2, 0, 0), child = render.Box(width = 1, height = 1, color = "#666")),
    ]),
    "S": render.Stack([
        render.Padding(pad = (1, 0, 0, 0), child = render.Box(width = 2, height = 1, color = "#666")),
        render.Padding(pad = (1, 1, 0, 0), child = render.Box(width = 1, height = 1, color = "#666")),
        render.Padding(pad = (0, 2, 0, 0), child = render.Box(width = 2, height = 1, color = "#666")),
    ]),
}

def listing(url, height):
    if not re.match(r"^https://www\.airbnb\.com/calendar/ical/", url):
        return render.Text(content = "Invalid URL", font = "tom-thumb")

    ical = cache.get(url)
    if ical == None:
        res = http.get(url)

        if res.status_code != 200:
            return render.Text(content = "HTTP error %d" % res.status_code, font = "tom-thumb")

        ical = res.body()
        cache.set(url, ical, ttl_seconds = 300)

    dtstart_list = re.match(r"DTSTART;VALUE=DATE:(.{4})(.{2})(.{2})", ical)
    dtend_list = re.match(r"DTEND;VALUE=DATE:(.{4})(.{2})(.{2})", ical)
    summary_list = re.match(r"SUMMARY:(.+)", ical)
    event_list = zip(dtstart_list, dtend_list, summary_list)
    now = time.now()

    children = []

    for [dtstart, dtend, summary] in event_list:
        start = time.time(year = int(dtstart[1]), month = int(dtstart[2]), day = int(dtstart[3]), hour = DEFAULT_CHECKIN_HOUR, location = DEFAULT_TIMEZONE)
        end = time.time(year = int(dtend[1]), month = int(dtend[2]), day = int(dtend[3]), hour = DEFAULT_CHECKOUT_HOUR, location = DEFAULT_TIMEZONE)
        offset = math.ceil((start - now).hours)
        duration = math.ceil((end - now).hours - offset)

        status = "BLOCKED" if summary[1] == "Airbnb (Not available)" else "PAST" if now > end else "FUTURE" if now < start else "PRESENT"

        left = offset // DEFAULT_HOURS_PER_PIXEL
        if left > SCREEN_WIDTH:
            continue

        width = duration // DEFAULT_HOURS_PER_PIXEL
        if left + width < 0:
            continue

        stroke, fill = COLORS[status]

        children.extend([
            render.Padding(
                pad = (left, 0, 0, 0),
                child = box(width, height - 1, stroke),
            ),
            render.Padding(
                pad = (left + 1, 1, 0, 0),
                child = box(width - 2, height - 3, fill),
            ),
        ])

    return render.Stack(children)

def box(width, height, color):
    diameter = min(width, height)
    children = [render.Circle(diameter = diameter, color = color)]

    if width > height:
        children.extend([
            render.Padding(
                pad = (int(height / 2), 0, 0, 0),
                child = render.Box(
                    width = width - height,
                    height = height,
                    color = color,
                ),
            ),
            render.Padding(
                pad = (width - height, 0, 0, 0),
                child = render.Circle(
                    diameter = diameter,
                    color = color,
                ),
            ),
        ])

    if width < height:
        children.extend([
            render.Padding(
                pad = (0, int(width / 2), 0, 0),
                child = render.Box(
                    width = width,
                    height = height - width,
                    color = color,
                ),
            ),
            render.Padding(
                pad = (0, height - width, 0, 0),
                child = render.Circle(
                    diameter = diameter,
                    color = color,
                ),
            ),
        ])

    return render.Stack(children)

def grid(location):
    children = []

    now = time.now()
    pixels_per_day = math.ceil(24 / DEFAULT_HOURS_PER_PIXEL)
    day_count = math.ceil(SCREEN_WIDTH / pixels_per_day) + 1
    offset = math.ceil(now.in_location(location).hour / DEFAULT_HOURS_PER_PIXEL)

    for i in range(day_count):
        t = now + time.parse_duration("%sh" % (24 * i))
        letter = t.in_location(location).format("Mon")[0]

        children.append(
            render.Padding(
                pad = (i * pixels_per_day - offset, 0, 0, 0),
                child = render.Stack([
                    render.Box(
                        width = pixels_per_day,
                        height = 4,
                        child = LETTERS[letter],
                    ),
                    render.Box(
                        width = 1,
                        height = SCREEN_HEIGHT,
                        color = "#222",
                    ),
                ]),
            ),
        )

    return render.Stack(children)

def main(config):
    count = int(config.get("count", "0"))
    timezone = config.get("$tz", DEFAULT_TIMEZONE)

    stack = [grid(timezone)]

    urls = [config.get("ical_%s" % i, "") for i in range(count)]

    if count > 0:
        min_stay = 24 + DEFAULT_CHECKOUT_HOUR - DEFAULT_CHECKIN_HOUR
        max_height = math.ceil(min_stay / DEFAULT_HOURS_PER_PIXEL)
        height = min(math.floor((SCREEN_HEIGHT - 4) / count), max_height)

        listings = [listing(url, height) for url in urls]
        stack.append(
            render.Padding(
                pad = (0, 4, 0, 0),
                child = render.Column(
                    children = listings,
                    main_align = "space_evenly",
                    expanded = True,
                ),
            ),
        )

    return render.Root(render.Stack(stack))

def get_listing_schema(count):
    return [schema.Text(
        id = "ical_%s" % i,
        name = "%s listing" % humanize.ordinal(i + 1),
        desc = "The calendar url for your %s Airbnb listing" % humanize.ordinal(i + 1),
        icon = "calendar-days",
    ) for i in range(0, int(count))]

def get_schema():
    options = [schema.Option(
        display = str(x),
        value = str(x),
    ) for x in range(1, MAX_LISTING_COUNT)]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "count",
                name = "Count",
                desc = "The number of listings to display.",
                icon = "hashtag",
                default = "1",
                options = options,
            ),
            schema.Generated(
                id = "listing_list",
                source = "count",
                handler = get_listing_schema,
            ),
        ],
    )
