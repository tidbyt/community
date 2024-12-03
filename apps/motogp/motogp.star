"""
Applet: MotoGP
Summary: Display MotoGP schedule
Description: Display MotoGP racing schedule and standings.
Author: adilansari
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# API
CATEGORIES_URL = "https://api.pulselive.motogp.com/motogp/v1/results/categories?seasonUuid={season_id}"
CALENDAR_URL = "https://api.pulselive.motogp.com/motogp/v1/events?seasonYear={year}"
STANDINGS_URL = "https://api.pulselive.motogp.com/motogp/v1/results/standings?seasonUuid={season_id}&categoryUuid={category_id}"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"

# Constants
DEFAULT_TIMEZONE = "America/New_York"
ONE_HOUR = 60 * 60
ONE_DAY = 24 * ONE_HOUR
BROADCAST_TIME_FORMAT = "2006-01-02T15:04:00-0700"  # 2024-04-14T15:45:00-0500
EVENT_TIME_FORMAT = "2006-01-02T15:04:00-07:00"  # 2024-09-29T20:00:00+08:00

# Styling
WHITE_COLOR = "#FFFFFF"
RED_LOGO_COLOR = "#EE4B2B"
LOGO_FONT = "tb-8"
CAPS_FONT = "CG-pixel-3x5-mono"

# Config
DISPLAY_PRACTICE_KEY = "with_practice"
DISPLAY_QUALIFYING_KEY = "with_qualifying"

SESSION_KIND_TO_STR = {
    "FP1": "Free Practice 1",
    "FP2": "Free Practice 2",
    "FP3": "Free Practice 3",
    "FP4": "Free Practice 4",
    "Q1": "Qualifying 1",
    "Q2": "Qualifying 2",
    "SPR": "Sprint Race",
    "RAC": "Race",
}

SEASONS_YEAR_ID = {
    2024: "dd12382e-1d9f-46ee-a5f7-c5104db28e43",
    2025: "ae6c6f0d-c652-44f8-94aa-420fc5b3dab4",
}

def main(config):
    display_fn = display_next_race_event
    if time.now().second % 2 == 0:
        display_fn = display_current_standings
    return display_fn(config)

def display_next_race_event(config):
    tz = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(tz)
    show_practice = config.bool(DISPLAY_PRACTICE_KEY, True)
    show_qualifying = config.bool(DISPLAY_QUALIFYING_KEY, True)

    race, broadcast, broadcast_end_time = None, None, now + time.parse_duration("17000h")
    sessions_to_display = ["SPR", "RAC"]
    if show_practice:
        sessions_to_display += ["FP1", "FP2", "FP3", "FP4"]
    if show_qualifying:
        sessions_to_display += ["Q1", "Q2"]

    # sort all broadcasts by date and select the first one that is closest in future
    for event in fetch_calendar(now.year):
        for brd in event["broadcasts"]:
            if not brd["category"]["name"] == "MotoGP":
                continue
            if not brd["shortname"] in sessions_to_display:
                continue
            end_ts = time.parse_time(brd["date_end"], BROADCAST_TIME_FORMAT).in_location(tz)
            if end_ts >= now and end_ts < broadcast_end_time:
                race, broadcast, broadcast_end_time = event, brd, end_ts
    print("rendering race {}, broadcast {}, end time {}".format(race["name"], broadcast["name"], broadcast_end_time))

    start_time = time.parse_time(broadcast["date_start"], BROADCAST_TIME_FORMAT).in_location(tz)
    race_display_name = race["circuit"]["country"]

    return render.Root(
        child = render.Column(
            main_align = "start",
            cross_align = "start",
            children = [
                render_motogp_header(),
                render_text_row(race_display_name, scroll = False),
                render_text_row(SESSION_KIND_TO_STR[broadcast["shortname"]]),
                render_text_row(start_time.format("Monday")),
                render_text_row(start_time.format("Jan 2 3:04 PM")),
            ],
        ),
    )

def display_current_standings(config):
    tz = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(tz)
    standings = fetch_standings(now.year)
    rider_rows = [render_rider_row(r["rider"]["full_name"], r["points"]) for r in standings["classification"]]
    return render.Root(
        render.Column(
            main_align = "start",
            cross_align = "start",
            children = [
                render_motogp_header(),
                rider_rows[0],
                rider_rows[1],
                rider_rows[2],
                rider_rows[3],
            ],
        ),
    )

def render_motogp_header(title = "MotoGP"):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = [
            render.Box(
                width = 64,
                height = 8,
                color = RED_LOGO_COLOR,
                child = render.Text(content = title, color = WHITE_COLOR, font = LOGO_FONT),
            ),
        ],
    )

def render_text_row(text, scroll = False):
    content_cols = padded_text_row(text)
    if scroll:
        content_cols = [
            render.Marquee(
                offset_start = 32,
                offset_end = 32,
                align = "center",
                width = 64,
                child = render.Row(
                    main_align = "start",
                    children = content_cols,
                ),
            ),
        ]
    return render.Padding(
        pad = (0, 0, 0, 0),
        child = render.Box(
            height = 6,
            child = render.Row(
                main_align = "center",
                expanded = True,
                children = content_cols,
            ),
        ),
    )

def render_rider_row(full_name, points):
    ns = full_name.split(" ")
    name = "{}. {}".format(ns[0][0], " ".join(ns[1:]))
    name_cols = padded_text_row(name)
    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Row(
            children = [
                render.Marquee(
                    offset_start = 64,
                    offset_end = 64,
                    width = 46,
                    child = render.Row(children = name_cols),
                ),
                padded_text_row("-")[0],
                render.Text(content = "{}".format(points), color = "#FFCE00", font = CAPS_FONT),
            ],
        ),
    )

def padded_text_row(text, color = WHITE_COLOR, font = CAPS_FONT):
    content_cols = []
    for s in text.split(" "):
        content_cols.append(
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Text(content = s, color = color, font = font),
            ),
        )
    return content_cols

def fetch_calendar(year):
    url = CALENDAR_URL.format(year = year)

    # schedule can be cached for a day
    data = get_cachable_data(url, 24 * ONE_HOUR)
    return data

def fetch_standings(year):
    season_id = SEASONS_YEAR_ID[int(year)]

    # categories list changes only once per year, a 3 day cache is good enough
    categories = get_cachable_data(CATEGORIES_URL.format(season_id = season_id), 3 * ONE_DAY)
    category_id = None
    for category in categories:
        if "motogp" in category["name"].lower():
            category_id = category["id"]
            break
    url = STANDINGS_URL.format(season_id = season_id, category_id = category_id)
    data = get_cachable_data(url, 1 * ONE_HOUR)
    return data

def get_cachable_data(url, timeout):
    res = http.get(url = url, headers = {"User-Agent": USER_AGENT}, ttl_seconds = timeout)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    return json.decode(res.body())

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = DISPLAY_PRACTICE_KEY,
                name = "Display Free Practice Schedule",
                desc = "Toggle to show/hide practice session schedule",
                default = True,
                icon = "flagCheckered",
            ),
            schema.Toggle(
                id = DISPLAY_QUALIFYING_KEY,
                name = "Display Qualifying Schedule",
                desc = "Toggle to show/hide qualifying session schedule",
                default = True,
                icon = "flagCheckered",
            ),
        ],
    )
