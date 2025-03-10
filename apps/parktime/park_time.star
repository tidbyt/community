"""
Applet: Park Time
Summary: Live theme park information
Description: Display park hours, show times, boarding groups, and attraction wait times for top U.S. theme parks.
Author: beyondutility

Powered by data from The ThemePark Live Database (https://ThemeParks.wiki).

v1.1 - Removed redundant API calls; layout improvements
v1.0 - Initial Tidbyt release
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

THEME_PARKS_WIKI_URL = "https://api.themeparks.wiki/v1/entity/"
DEFAULT_COLOR = "#0d6efd"
DEFAULT_COLOR_BLACK = "#000000"
DEFAULT_COLOR_LIGHT_GRAY = "#888888"
DEFAULT_COLOR_DARK_GRAY = "#333333"
DEFAULT_COLOR_WHITE = "#FFFFFF"
DEFAULT_COLOR_DANGER = "#dc3545"
DEFAULT_COLOR_WARNING = "#ffc107"
DEFAULT_TTL = int(60 * 60 * 6)  # 4 hours
DEFAULT_TTL_LIVE = int(60 * 5)  # 5 minutes
DEFAULT_ENTITY = "75ea578a-adc8-4116-a54d-dccb60765ef9"  #"ff52cb64-c1d5-4feb-9d43-5dbd429bac81"  #
TIDY_NAMES = ["Universal's ", " Theme Park", " Water Park", " Park", "Disney's ", " Florida", "™", "©", "®", " – New!"]
MAIN_ENTITIES = [
    {"name": "Disneyland Resort", "id": "bfc89fd6-314d-44b4-b89e-df1a89cf991e", "entityType": "DESTINATION", "color": "#FFFFFF"},
    {"name": "Walt Disney World® Resort", "id": "e957da41-3552-4cf6-b636-5babc5cbc4e5", "entityType": "DESTINATION", "color": "#FFFFFF"},
    {"name": "Universal Studios", "id": "9fc68f1c-3f5e-4f09-89f2-aab2cf1a0741", "entityType": "DESTINATION", "color": "#FFFFFF"},
    {"name": "Universal Orlando Resort", "id": "89db5d43-c434-4097-b71f-f6869f495a22", "entityType": "DESTINATION", "color": "#FFFFFF"},
    {"name": "Disneyland Park", "id": "7340550b-c14d-4def-80bb-acdb51d49a66", "entityType": "PARK", "color": "#573eaf"},
    {"name": "Disney California Adventure Park", "id": "832fcd51-ea19-4e77-85c7-75d5843b127c", "entityType": "PARK", "color": "#8260c2"},
    {"name": "Magic Kingdom Park", "id": "75ea578a-adc8-4116-a54d-dccb60765ef9", "entityType": "PARK", "color": "#7236ba"},
    {"name": "EPCOT", "id": "47f90d2c-e191-4239-a466-5892ef59a88b", "entityType": "PARK", "color": "#ce019e"},
    {"name": "Disney's Hollywood Studios", "id": "288747d1-8b4f-4a64-867e-ea7c9b27bad8", "entityType": "PARK", "color": "#e90129"},
    {"name": "Disney's Animal Kingdom Theme Park", "id": "1c84a229-8862-4648-9c71-378ddd2c7693", "entityType": "PARK", "color": "#71a750"},
    {"name": "Disney's Typhoon Lagoon Water Park", "id": "b070cbc5-feaa-4b87-a8c1-f94cca037a18", "entityType": "PARK", "color": "#408297"},
    {"name": "Disney's Blizzard Beach Water Park", "id": "ead53ea5-22e5-4095-9a83-8c29300d7c63", "entityType": "PARK", "color": "#31b0f0"},
    {"name": "Universal's Volcano Bay", "id": "fe78a026-b91b-470c-b906-9d2266b692da", "entityType": "PARK", "color": "#0468d9"},
    {"name": "Universal Studios Florida", "id": "eb3f4560-2383-4a36-9152-6b3e5ed6bc57", "entityType": "PARK", "color": "#0468d9"},
    {"name": "Universal's Islands of Adventure", "id": "267615cc-8943-4c2a-ae2c-5da728ca591f", "entityType": "PARK", "color": "#0468d9"},
    {"name": "Universal Studios", "id": "bc4005c5-8c7e-41d7-b349-cdddf1796427", "entityType": "PARK", "color": "#0468d9"},
]

# Format the Schema Options
def entity_to_option(entity):
    if entity["entityType"] == "PARK":
        return schema.Option(
            display = "PARK HOURS - " + entity["name"],
            value = entity["id"],
        )
    elif entity["entityType"] == "SHOW":
        return schema.Option(
            display = "SHOW TIMES - " + entity["name"],
            value = entity["id"],
        )
    elif entity["entityType"] == "ATTRACTION":
        return schema.Option(
            display = "WAIT TIME - " + entity["name"],
            value = entity["id"],
        )
    else:
        return schema.Option(
            display = entity["name"],
            value = entity["id"],
        )

# Get the Schema Options for Destinations
def get_destination_options():
    return [entity_to_option(destination) for destination in MAIN_ENTITIES if destination["entityType"] == "DESTINATION"]

# Get the Schema Options for Entities
def get_entity_options(park):
    entity_children = http.get(THEME_PARKS_WIKI_URL + park + "/children", ttl_seconds = DEFAULT_TTL)
    if entity_children.status_code != 200:
        fail("request to %s failed with status code: %d" % (entity_children, entity_children.status_code))
    entity_children = entity_children.json()["children"]

    # Get Parks
    destination_children = [x for x in entity_children if (x["entityType"] == "PARK" or x["entityType"] == "SHOW" or x["entityType"] == "ATTRACTION")]

    # print(destination_children)
    return sorted([entity_to_option(entity) for entity in destination_children], key = lambda entity: entity.display)

# Generate the Entity Dropdown
def entity_options(destination):
    entities = get_entity_options(destination)
    return [
        schema.Dropdown(
            id = "entity",
            name = "Park, Show, or Attraction",
            desc = "Display today's park hours, show times, or current attraction wait time.",
            icon = "star",
            default = entities[0].value,
            options = entities,
        ),
    ]

destinations = get_destination_options()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "destination",
                name = "Destination",
                desc = "Select a park destination.",
                icon = "compass",
                default = destinations[0].value,
                options = destinations,
            ),
            schema.Generated(
                id = "generated_entities",
                source = "destination",
                handler = entity_options,
            ),
        ],
    )

def tidy_name(entity_name):
    display_name = entity_name
    for phrase in TIDY_NAMES:
        display_name = display_name.replace(phrase, "")
    return display_name.upper()

def tidy_time(time):
    display_time = humanize.time_format("K:mmaa", time)
    display_time = display_time.replace("AM", "A")
    display_time = display_time.replace("PM", "P")
    return display_time

def park_hours(timezone, entity_schedule, display_name, color, today, tomorrow):
    schedule_today = [x for x in entity_schedule["schedule"] if x["date"] == today and x["type"] == "OPERATING"]
    schedule_tomorrow = [x for x in entity_schedule["schedule"] if x["date"] == tomorrow and x["type"] == "OPERATING"]
    operating_hours_color = DEFAULT_COLOR_WHITE

    # Get today's schedule
    if schedule_today:
        opening_today = time.parse_time(schedule_today[0]["openingTime"])
        closing_today = time.parse_time(schedule_today[0]["closingTime"])
        opening_tomorrow = time.parse_time(schedule_tomorrow[0]["openingTime"])
        closing_tomorrow = time.parse_time(schedule_tomorrow[0]["closingTime"])

        # When park is closed
        if time.now().in_location(timezone) > closing_today.in_location(timezone):
            if schedule_tomorrow:
                park_hours_label = "OPEN TOMORROW"
                operating_hours = tidy_time(opening_tomorrow) + " - " + tidy_time(closing_tomorrow)
                operating_hours_color = DEFAULT_COLOR_WARNING
            else:
                park_hours_label = "PARK HOURS"
                operating_hours = "CLOSED TOMORROW"
                operating_hours_color = DEFAULT_COLOR_DANGER

            # When park is closing soon
        elif time.now().in_location(timezone) > closing_today.in_location(timezone) - time.parse_duration("2h"):
            park_hours_label = "CLOSING SOON"
            operating_hours = tidy_time(opening_today) + " - " + tidy_time(closing_today)

            # Normal park hours
        else:
            park_hours_label = "PARK HOURS"
            operating_hours = tidy_time(opening_today) + "-" + tidy_time(closing_today)
    else:
        park_hours_label = "PARK HOURS"
        operating_hours = "CLOSED"

    return [
        render.Marquee(
            child = render.WrappedText(content = display_name, align = "center", height = 13, font = "6x13", color = color),
            width = 64,
            align = "center",
        ),
        render.Box(width = 64, height = 2),
        render.Text(content = park_hours_label, font = "CG-pixel-4x5-mono", color = DEFAULT_COLOR_LIGHT_GRAY),
        render.Box(width = 64, height = 1),
        render.Text(content = operating_hours, font = "CG-pixel-3x5-mono", color = operating_hours_color),
        render.Box(width = 64, height = 4),
    ]

def show_times(showtimes_today, display_name, color):
    if showtimes_today:
        show_times = [tidy_time(time.parse_time(x["startTime"])) for x in showtimes_today]
        show_times_height = 12
        show_times = " ".join([show_times[n] if n % 3 != 2 else show_times[n] + " " for n in range(len(show_times))])
        show_times_color = DEFAULT_COLOR_WHITE
    else:
        show_times_height = 12
        show_times = "CLOSED"
        show_times_color = DEFAULT_COLOR_DANGER
    return [
        render.Marquee(
            child = render.WrappedText(content = display_name, align = "center", font = "Dina_r400-6", color = color),
            width = 64,
            align = "center",
        ),
        render.Box(width = 64, height = 4),
        render.Text(content = "SHOW TIMES", font = "CG-pixel-4x5-mono", color = DEFAULT_COLOR_LIGHT_GRAY),
        render.Box(width = 64, height = 1),
        render.Marquee(height = 12, scroll_direction = "vertical", align = "center", offset_start = 0, offset_end = 0, child = render.WrappedText(content = show_times, height = show_times_height, linespacing = 1, align = "center", font = "CG-pixel-3x5-mono", color = show_times_color)),
    ]

def boarding_groups(entity_live, display_name, color):
    group_start = str(int(entity_live["queue"]["BOARDING_GROUP"]["currentGroupStart"]))
    group_end = str(int(entity_live["queue"]["BOARDING_GROUP"]["currentGroupEnd"]))
    wait_time = group_start + "-" + group_end
    return [
        render.Marquee(width = 64, child = render.Text(content = display_name, font = "Dina_r400-6", color = color)),
        render.Text(content = "NOW BOARDING", font = "CG-pixel-4x5-mono", height = 6, color = DEFAULT_COLOR_LIGHT_GRAY),
        render.Text(content = "GROUPS", font = "CG-pixel-4x5-mono", height = 6, color = DEFAULT_COLOR_LIGHT_GRAY),
        render.Box(width = 64, height = 1),
        render.Text(content = wait_time, font = "CG-pixel-3x5-mono", height = 6, color = "#FFFFFF"),
        render.Box(width = 64, height = 3),
    ]

def wait_times(entity_live, display_name, color):
    wait_time_label = "WAIT TIME"
    wait_time = ""
    wait_time_units_color = DEFAULT_COLOR_LIGHT_GRAY
    if entity_live["status"] == "CLOSED":
        wait_time_units = "CLOSED"
        wait_time_units_color = DEFAULT_COLOR_DANGER
    elif entity_live["status"] == "DOWN":
        wait_time_units = "TEMP CLOSED"
        wait_time_units_color = DEFAULT_COLOR_WARNING
    elif "queue" in entity_live:
        if entity_live["queue"]["STANDBY"]["waitTime"]:
            minutes = str(int(entity_live["queue"]["STANDBY"]["waitTime"]))
            wait_time = minutes
        else:
            wait_time = "0"
        wait_time_units = "MINUTES"
    else:
        wait_time_units = "CLOSED"
        wait_time_units_color = DEFAULT_COLOR_DANGER
    return [
        render.Marquee(width = 64, align = "center", child = render.Text(content = display_name, font = "Dina_r400-6", color = color)),
        render.Text(content = wait_time_label, font = "CG-pixel-4x5-mono", height = 6, color = DEFAULT_COLOR_LIGHT_GRAY),
        render.Box(width = 64, height = 1),
        render.Box(
            width = 21,
            height = 9,
            color = DEFAULT_COLOR_DARK_GRAY,
            padding = 1,
            child = render.Box(
                width = 19,
                color = DEFAULT_COLOR_BLACK,
                child = render.Padding(child = render.Text(content = wait_time, font = "CG-pixel-3x5-mono", color = "#FFFFFF"), pad = (2, 1, 1, 1)),
            ),
        ),
        render.Text(content = wait_time_units, font = "CG-pixel-4x5-mono", height = 6, color = wait_time_units_color),
    ]

def no_data(display_name, color):
    return [
        render.Marquee(width = 64, align = "center", child = render.Text(content = display_name, font = "Dina_r400-6", color = color)),
        render.Box(width = 64, height = 6),
        render.Text(content = "NO DATA", font = "CG-pixel-4x5-mono", color = "#FF0000"),
        render.Box(width = 64, height = 8),
    ]

def main(config):
    display_widgets = []
    color = DEFAULT_COLOR
    timezone = config.get("$tz", "America/New_York")  # Utilize special timezone variable
    today = time.now().in_location(timezone).format("2006-01-02")
    tomorrow = (time.now().in_location(timezone) + time.parse_duration("24h")).format("2006-01-02")

    # Get entity if specified
    entity = DEFAULT_ENTITY
    if config.get("entity"):
        entity = config.get("entity")

    #Get the entity info
    entity_live = http.get(THEME_PARKS_WIKI_URL + entity + "/live", ttl_seconds = DEFAULT_TTL_LIVE)
    if entity_live.status_code != 200:
        fail("request to %s failed with status code: %d" % (entity_live, entity_live.status_code))
    entity_live = entity_live.json()["liveData"]
    entity_schedule = http.get(THEME_PARKS_WIKI_URL + entity + "/schedule", ttl_seconds = DEFAULT_TTL).json()
    display_name = tidy_name(entity_schedule["name"])

    # Check for liveData
    if entity_live:
        entity_live = entity_live[0]

        # Check for parkId
        if entity_live["parkId"]:
            color = [x["color"] for x in MAIN_ENTITIES if x["id"] == entity_live["parkId"]][0]
        else:
            color = DEFAULT_COLOR

        # -- PARK OPERATING HOURS -- #
        if entity_schedule["entityType"] == "PARK":
            display_widgets = park_hours(timezone, entity_schedule, display_name, color, today, tomorrow)

            # -- SHOW TIMES -- #
        elif entity_schedule["entityType"] == "SHOW":
            if "showtimes" in entity_live:
                if entity_live["showtimes"]:
                    if entity_live["showtimes"][0]["type"] == "Performance Time":
                        showtimes_today = [x for x in entity_live["showtimes"] if time.parse_time(x["startTime"]).in_location(timezone) > time.now().in_location(timezone) and entity_live["status"] == "OPERATING"]
                        display_widgets = show_times(showtimes_today, display_name, color)
                    else:
                        display_widgets = wait_times(entity_live, display_name, color)
                else:
                    showtimes_today = ""
                    display_widgets = show_times(showtimes_today, display_name, color)
            elif "showTimes" in entity_live:
                showtimes_today = [x for x in entity_live["showTimes"] if time.parse_time(x["startTime"]).in_location(timezone) > time.now().in_location(timezone) and entity_live["status"] == "OPERATING"]
                display_widgets = show_times(showtimes_today, display_name, color)
            else:
                display_widgets = no_data(display_name, color)

            # -- ATTRACTION WAIT TIMES -- #
        elif entity_schedule["entityType"] == "ATTRACTION":
            ## ADD: if off hours show "CLOSED"
            # Get boarding group or wait time
            if "queue" in entity_live and "BOARDING_GROUP" in entity_live["queue"] and entity_live["queue"]["BOARDING_GROUP"]["currentGroupStart"]:
                display_widgets = boarding_groups(entity_live, display_name, color)
            else:
                display_widgets = wait_times(entity_live, display_name, color)
    else:
        display_widgets = no_data(display_name, color)

    return render.Root(
        child = render.Column(
            display_widgets,
            expanded = True,
            main_align = "end",
            cross_align = "center",
        ),
    )
