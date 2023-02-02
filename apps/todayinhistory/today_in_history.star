load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIKIPEDIA_API = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&titles={}&redirects=true"
TTL = 12 * 60 * 60  # 12 hours for general day cache stuff
ITEMS = 5
SHOW_BIRTHS = True
SHOW_DEATHS = True
SHOW_EVENTS = True
FONT_TITLE = "tb-8"
FONT_BODY = "tom-thumb"
DEFAULT_TITLE = "On this day"

def main(config):
    # From config, get options.
    show_births = config.bool("show_births")
    show_deaths = config.bool("show_deaths")
    show_events = config.bool("show_events")
    if not (show_births or show_deaths or show_events):
        show_events = True  # You cannot ask for nothing!

    title = config.str("title") or DEFAULT_TITLE

    # What is today?
    date = humanize.time_format("MMMM_dd", time.now())
    nice_day = humanize.time_format("MMMM dd", time.now())

    # Obtain the information about today. This can record a fake record in the case of an error
    data = get_raw_day_data(date)

    # Filter based on config
    data = [
        d
        for d in data
        if (d[0] == "Events" and show_events) or
           (d[0] == "Births" and show_births) or
           (d[0] == "Deaths" and show_deaths)
    ]

    # This is nice and randomized, so choose a random entry
    to_show = data[random.number(0, len(data) - 1)]

    return render.Root(
        delay = 100,
        child = page_render(title, nice_day, to_show),
    )

# Given a day name, return the processed 'what happened today' data, or calculate this
# if it is not in the cache.

def get_raw_day_data(day_name):
    cache_key = "DAY_{}".format(day_name)
    data = cache.get(cache_key)
    if not data:
        page = http.get(WIKIPEDIA_API.format(day_name))
        if page.status_code != 200:
            # Fake a set of entries to inform the user, and back off for at least 30 seconds
            print("Wikipedia request failed with status ", page.status_code)
            error_data = [(x, "*", "There was an error fetching event data") for x in ["Births", "Deaths", "Events"]]
            cache.set(cache_key, json.encode(error_data), ttl_seconds = 30)
            return error_data

        body = json.decode(page.body())
        content = body["query"]["pages"]
        page = content[content.keys()[0]]
        extract = page["extract"]
        data = parse_wiki_page(extract)

        # If we are good here, this data is good for at least half a day in the cache (this is daily data after all, but maybe
        # it will get updated during the day)
        cache.set(cache_key, json.encode(data), ttl_seconds = TTL)
    else:
        data = json.decode(data)
    return data

def page_render(title, the_day, entry):
    part = render.Text(content = entry[0], font = FONT_BODY, color = "#F0F")
    quote = render.WrappedText(content = entry[2], font = FONT_BODY, color = "#FF0", align = "left")
    quote_scroll = render.Marquee(
        child = render.Column(children = [part, quote]),
        scroll_direction = "vertical",
        height = 18,
    )
    header = render.Row(
        children = [render.Text(content = title, font = FONT_TITLE, color = "#0F0")],
        main_align = "center",
        expanded = True,
    )
    footer = render.Row(
        children = [render.Text(content = the_day, font = FONT_BODY, color = "#0FF")],
        main_align = "center",
        expanded = True,
    )
    return render.Column(children = [header, quote_scroll, footer])

# Entries often have just too many spaces...
def fix_entry(content):
    return " ".join([x for x in content.split(" ") if len(x) > 0])

def parse_wiki_page(data):
    # The page has carriage returns which really help with the finding of information. Loop by line
    lines = data.split("\n")
    everything = []
    current_part = None
    current_section = None
    for line in lines:
        # This pattern matches the actual entry for a day - a single event/birth/death
        pattern = r"<li>(.+)</li>"
        matches = re.match(pattern, line)
        if len(matches) > 0 and current_section and current_part:
            # Insert it in a random place. This means our response will be randomized in case we want to show
            # multiple entries in one go, we won't get all births or deaths etc.
            everything.insert(random.number(0, len(everything)), (current_part, current_section, fix_entry(matches[0][1])))

        # This matches a classification/section (Births, Deaths, Events)
        pattern = r"<h2><span id=\"\S+\">([0-9A-Za-z\s–]+)</span>+</h2>"
        matches = re.match(pattern, line)
        if len(matches) > 0:
            current_part = matches[0][1]
            current_section = None

        # This matches a sub-area, usually time based.
        pattern = r"<span id=\"\S+\">([0-9A-Za-z\-–]*)</span></h3>$"
        matches = re.match(pattern, line)
        if matches:
            current_section = matches[0][1]

    return everything

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "title",
                name = "Title",
                desc = "An alternate title for the application",
                icon = "heading",
            ),
            schema.Toggle(
                id = "show_births",
                name = "Show Births",
                desc = "Pick from births when deciding what to show",
                icon = "baby",
                default = True,
            ),
            schema.Toggle(
                id = "show_deaths",
                name = "Show Deaths",
                desc = "Pick from deaths when deciding what to show",
                icon = "bookSkull",
                default = True,
            ),
            schema.Toggle(
                id = "show_events",
                name = "Show Events",
                desc = "Pick from events when deciding what to show",
                icon = "calendar",
                default = True,
            ),
        ],
    )
