"""
Applet: G35
Summary: Clinton-Washington G
Description: Train arrival times for the Clinton-Washington station of NYC's G train.
Author: samdotdesign
"""

load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

MTA_API_URL = "https://mta-api-ochre.vercel.app/by-id/G35"
CACHE_TTL = 60  # Cache data for 1 minute

# Adjustable padding values
DIRECTION_PADDING = dict(top = 2, right = 0, bottom = 1, left = 2)
TIME_PADDING = dict(top = -2, right = 3, bottom = 0, left = 0)
TIMES_ROW_PADDING = dict(top = 0, right = 0, bottom = 0, left = 2)

def main():
    rep = http.get(MTA_API_URL, ttl_seconds = CACHE_TTL)
    if rep.status_code != 200:
        return render_error("HTTP Error: {}".format(rep.status_code))

    data = rep.json()
    if not validate_data(data):
        return render_error("Invalid data format")

    station_data = data["data"][0]
    northbound = get_next_trains(station_data.get("N", []), 3)
    southbound = get_next_trains(station_data.get("S", []), 3)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "start",
            children = [
                render.Column(
                    expanded = True,
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        direction_times("COURT SQ", northbound),
                        direction_times("CHURCH AV", southbound),
                    ],
                ),
                render_api_status(None),
            ],
        ),
    )

def validate_data(data):
    if type(data) != "dict":
        return False
    if "data" not in data or type(data["data"]) != "list":
        return False
    if len(data["data"]) == 0:
        return False
    if type(data["data"][0]) != "dict":
        return False
    if "N" not in data["data"][0] and "S" not in data["data"][0]:
        return False
    return True

def render_error(message):
    return render.Root(
        child = render.WrappedText(message, color = "#FF0000"),
    )

def render_api_status(error):
    if error:
        return render.Text("!", color = "#FF0000", font = "tb-8")
    else:
        return render.Text("", font = "tb-8")  # Empty text for normal operation

def get_next_trains(trains, count):
    future_trains = []
    for train in trains:
        minutes = format_time(train)
        if minutes > 0:
            future_trains.append((train, minutes))
        if len(future_trains) == count:
            break
    return future_trains

def format_time(train):
    arrival_time = time.parse_time(train["time"])
    current_time = time.now().in_location("America/New_York")
    minutes_until = int((arrival_time - current_time).minutes)
    return max(0, minutes_until)

def compact_text(text, font = "tb-8", color = "#FFF"):
    words = text.split()
    text_elements = []
    for i, word in enumerate(words):
        text_elements.append(render.Text(word, font = font, color = color))
        if i < len(words) - 1:  # Don't add space after the last word
            text_elements.append(render.Box(width = 2, height = 1))  # 2px wide space
    return render.Row(children = text_elements)

def direction_text(direction):
    return render.Padding(
        pad = (DIRECTION_PADDING["left"], DIRECTION_PADDING["top"], DIRECTION_PADDING["right"], DIRECTION_PADDING["bottom"]),
        child = compact_text(direction, font = "CG-pixel-4x5-mono", color = "#6CBE45"),
    )

def time_text(time):
    return render.Padding(
        pad = (TIME_PADDING["left"], TIME_PADDING["top"], TIME_PADDING["right"], TIME_PADDING["bottom"]),
        child = render.Row(
            children = [
                render.Text(
                    "{}".format(time),
                    color = "#FFF",
                    font = "Dina_r400-6",
                ),
                render.Padding(
                    pad = (0, 1, 0, 0),  # Move 'm' down by 1 pixel
                    child = render.Text(
                        "m",
                        color = "#FFF",
                        font = "tb-8",
                    ),
                ),
            ],
        ),
    )

def direction_times(direction, trains):
    return render.Column(
        children = [
            direction_text(direction),
            render.Padding(
                pad = (TIMES_ROW_PADDING["left"], TIMES_ROW_PADDING["top"], TIMES_ROW_PADDING["right"], TIMES_ROW_PADDING["bottom"]),
                child = render.Row(
                    children = [time_text(minutes) for _, minutes in trains],
                ),
            ),
        ],
    )
