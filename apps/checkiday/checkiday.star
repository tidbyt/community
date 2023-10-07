"""
Applet: Checkiday
Summary: Celebrate today's holidays
Description: A complete list of today's holidays, most of which you won't find on a calendar!
Author: westy92
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

CHECKIDAY_API_URL = "https://api.checkiday.com/tidbyt"
DEFAULT_TIMEZONE = "America/Chicago"

# from `pixlet encrypt checkiday keyname`
ENCRYPTED_API_KEY = "AV6+xWcE7vUHwx7qLifXHUI2DXOMaxbhi2MfvmX3ncE9iKFUnMf7u+wSBa54WvraCPkV4H38FTLxMVHFkWtX/jrf9tfo62NgCQux3T+MnV3CEDaENGLvjCSs2IzUPl0Z4EvEnWJ32UvmJaH70GDj0O5r1drwK1vpJ0XEm4/X5Ue5uQ=="
DEFAULT_COLORS = ["#777", "#fff"]
CUSTOM_COLORS_BY_DATE = {
    (1, 1): ["#C0C0C0", "#D4AF37"],  # New Year's Day
    (2, 14): ["#970212", "#FFF9E3"],  # Valentine's Day
    (6, 1): ["#E40303", "#FF8C00", "#FFED00", "#008026", "#24408E", "#732982"],  # Pride Month
    (7, 4): ["#B32134", "#FFFFFF", "#3B3B6D"],  # Independence Day
    (10, 31): ["#F4831B", "#902EBB"],  # Halloween
    (12, 25): ["#C22323", "#215223"],  # Christmas
    (12, 31): ["#C0C0C0", "#D4AF37"],  # New Year's Eve
}
CUSTOM_COLORS_BY_ID = {
    "e2e3e6b51022c7e6b2298edb100fe474": ["#229454", "#A8DC00"],  # Spring
    "856b72bffa253340147345f842360312": ["#FFE141", "#ABD229"],  # Summer
    "bc773913b9d2bac29cb8c037c197c095": ["#BB1701", "#E98E08", "#803D0A"],  # Fall
    "5f5daecb0a55b46fae5236fb47a5f023": ["#952927", "#E76005", "#DDC001"],  # Thanksgiving
    "fe0eaf856243ba7aae05225e28fb0749": ["#29AAF2", "#214D6D"],  # Winter
}

def main(config):
    children = [
        render.WrappedText(
            "Checkiday",
            color = "#d95141",
            align = "center",
            width = 64,
        ),
    ]

    events = get_events(config)
    timezone = get_timezone(config)
    date = time.now().in_location(timezone)
    colors = get_colors(date, events)

    for i, event in enumerate(events):
        children.append(
            render.WrappedText(
                event["name"],
                color = colors[i % len(colors)],
            ),
        )

    return render.Root(
        delay = 100,  # ms between frames
        show_full_animation = True,
        child = render.Sequence(
            children = [
                render.Marquee(
                    height = 32,
                    delay = 5,  # number of frames to wait at beginning
                    scroll_direction = "vertical",
                    child = render.Column(
                        children = children,
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "adult",
                name = "NSFW Mode",
                desc = "A toggle to enable NSFW mode.",
                icon = "exclamation",
                default = False,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display events.",
                icon = "locationDot",
            ),
        ],
    )

def get_timezone(config):
    location = config.get("location")
    loc = json.decode(location) if location else {}
    return loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))

def get_events(config):
    timezone = get_timezone(config)
    adult = config.get("adult", "false")
    api_key = secret.decrypt(ENCRYPTED_API_KEY) or config.get("dev_api_key", "")
    url = CHECKIDAY_API_URL + "?apikey=" + api_key + "&adult=" + adult + "&timezone=" + timezone
    rep = http.get(url, ttl_seconds = 3600)  # 1 hour cache - TODO cache until midnight in TZ if less than hour
    if rep.status_code != 200:
        return [{"name": "Error loading holidays...", "id": ""}]

    return rep.json()["events"]

def get_colors(date, events):
    colors = CUSTOM_COLORS_BY_DATE.get((date.month, date.day))
    if colors:
        return colors
    for event in events:
        colors = CUSTOM_COLORS_BY_ID.get(event["id"])
        if colors:
            return colors
    return DEFAULT_COLORS
