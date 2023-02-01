"""
Applet: On This Day
Summary: Display event for this day
Description: Displays historical event that happened on this day
Author: Andrew Hefele
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

OTD_URL = "https://byabbe.se/on-this-day/{0}/{1}/events.json"
CACHE_TIMEOUT = 3600

#selection options
COLORS = [
    schema.Option(display = "Aqua", value = "#00ffff"),
    schema.Option(display = "Black", value = "#000000"),
    schema.Option(display = "Blue", value = "#0000ff"),
    schema.Option(display = "Gray", value = "#808080"),
    schema.Option(display = "Green", value = "#00ff00"),
    schema.Option(display = "Fuchsia", value = "#ff00ff"),
    schema.Option(display = "Lime", value = "#00ff00"),
    schema.Option(display = "Maroon", value = "#800000"),
    schema.Option(display = "Navy", value = "#000080"),
    schema.Option(display = "Olive", value = "#808000"),
    schema.Option(display = "Red", value = "#ff0000"),
    schema.Option(display = "Purple", value = "#800080"),
    schema.Option(display = "Silver", value = "#c0c0c0"),
    schema.Option(display = "Teal", value = "#008080"),
    schema.Option(display = "White", value = "#ffffff"),
    schema.Option(display = "Yellow", value = "#ffff00"),
]

def main(config):
    # get config
    backgroundColor = config.get("backgroundColor", COLORS[1].value)
    yearColor = config.get("yearColor", COLORS[2].value)
    dividerColor = config.get("dividerColor", COLORS[4].value)
    descriptionColor = config.get("descriptionColor", COLORS[12].value)

    # get event JSON
    eventJson = get_eventJson()

    # select random event from today's events
    index = random.number(0, len(eventJson["events"]) - 1)

    # render display
    return render.Root(
        child = render.Box(
            color = backgroundColor,
            child = render.Column(
                children = [
                    render.Padding(
                        pad = (0, 0, 0, 3),
                        child = render.Box(
                            width = 64,
                            height = 10,
                            child = render.Text(
                                content = str(get_event_year(eventJson, index)),
                                color = yearColor,
                                height = 0,
                                offset = 0,
                            ),
                        ),
                    ),
                    render.Box(
                        height = 1,
                        width = 64,
                        color = dividerColor,
                    ),
                    render.Marquee(
                        width = 64,
                        offset_start = 64,
                        child = render.Column(
                            expanded = True,
                            children = [
                                render.Padding(
                                    pad = (0, 4, 0, 0),
                                    child = render.Text(
                                        content = get_event_description(eventJson, index),
                                        color = descriptionColor,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        ),
    )

# extract event year from JSON
def get_event_year(eventJson, index):
    return eventJson["events"][index]["year"]

# extract event description from JSON
def get_event_description(eventJson, index):
    return eventJson["events"][index]["description"]

# get the event JSON from cache, if that fails hit the API endpoint
def get_eventJson():
    eventJson = cache.get("on_this_day_events")
    if eventJson:
        eventJson = json.decode(eventJson)
    else:
        eventJson = call_otd_api(OTD_URL)

    return eventJson

# make the API call to fetch the events for today, store in cache
def call_otd_api(url):
    # Return events of the day JSON
    now = time.now()
    response = http.get(url = OTD_URL.format(now.month, now.day))

    if response.status_code != 200:
        fail("status %d from %s: %s" % (response.status_code, url, response.body()))

    eventJson = response.json()
    cache.set("on_this_day_events", json.encode(eventJson), ttl_seconds = CACHE_TIMEOUT)

    return eventJson

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "yearColor",
                name = "Year color",
                desc = "The color of the event year",
                icon = "palette",
                default = COLORS[2].value,
                options = COLORS,
            ),
            schema.Dropdown(
                id = "dividerColor",
                name = "Divider color",
                desc = "The color of the content divider",
                icon = "palette",
                default = COLORS[4].value,
                options = COLORS,
            ),
            schema.Dropdown(
                id = "descriptionColor",
                name = "Event Color",
                desc = "The color of the event text",
                icon = "palette",
                default = COLORS[12].value,
                options = COLORS,
            ),
            schema.Dropdown(
                id = "backgroundColor",
                name = "Background color",
                desc = "The color of the background",
                icon = "palette",
                default = COLORS[1].value,
                options = COLORS,
            ),
        ],
    )
