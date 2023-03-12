"""
Applet: AC Film Showtimes
Summary: Movie showtimes
Description: Displays movie showtimes for American Cinematheque theaters in Los Angeles.
Author: Platt Thompson & Jim Cummings
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ---------------------------------------------------------------------------- #
#                                   CONSTANTS                                  #
# ---------------------------------------------------------------------------- #

CAMERA_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABUAAAAXCAYAAADk3wSdAAAAAXNSR0IArs4c6QAAAR1JREFUSEtjZGBgYFAwrPsPokEgszoMTJeH6DASkoPpQacZkQ1EN3h66yoMfeiWYjMYq6HqJppgtTfPXMfQA5PbOTsS7JMhbih6ZKB7DznMifE6yDyc4YIrvGDiIMsWrSokPkzRVd6/v43BI7QYLgyLQJChgQ5RcHFeMVMGkBg49j+/Oo3TYSCFIG9jSwmg5NWVX8qw/sAysOEgtSAxuKEgAXQAsowYQ0284hjObFuE3VBkF4MMI9ZQmGOwuhSfoci+gAUFzPtUMRSW22BZFmveh3kTX5jiikls2ZXo2CfZUEIJHZaTsKnD6lJkhcLSnvByFST+9ul2snIciiZkQ0HJ48H5pkFuKCWuxCilYMUcKGLwleyEIhYlzAa1oQARYMFWHZmc4wAAAABJRU5ErkJggg==")

CINEMATHEQUE_SHOWTIMES_URL = "https://www.americancinematheque.com/wp-json/wp/v2/algolia_get_events?environment=production&startDate={start_time}&endDate={end_time}"

THEATER_CODES = {
    "los feliz 3": 102,
    "aero theatre": 54,
    "other": 68,
}

# Showtimes will change color as they approach and gradually become more red.
# Once the time has passed, they will be grayed out.
# This also gives a more implicit understanding of AM and PM since the times are in twelve hour format
# and there's no room for an AM/PM suffix.
SHOWTIME_COLORS = {
    1: "#FF3333",
    2: "#FF4444",
    3: "#FF5555",
    4: "#FF6666",
    5: "#FF7777",
    6: "#FF8888",
    7: "#FF9999",
    8: "#FFAAAA",
    9: "#FFBBBB",
    10: "#FFCCCC",
    11: "#FFDDDD",
    12: "#FFEEEE",
    13: "#FFFFFF",
    14: "#FFFFFF",
    15: "#FFFFFF",
    16: "#FFFFFF",
    17: "#FFFFFF",
    18: "#FFFFFF",
    19: "#FFFFFF",
    20: "#FFFFFF",
    21: "#FFFFFF",
    22: "#FFFFFF",
    23: "#FFFFFF",
    24: "#FFFFFF",
}

DAY_IN_SECONDS = 86400
HOUR_IN_SECONDS = 3600
MINUTE_IN_SECONDS = 60
PT_TO_GMT_TIME_DIFFERENCE_IN_SECONDS = 28800

# ---------------------------------------------------------------------------- #
#                                    HELPERS                                   #
# ---------------------------------------------------------------------------- #

def get_showtime_color(movie_start_time, current_time):
    start_time_hour = time.parse_time(movie_start_time, "15:04:05").hour
    hours_until_movie = int(start_time_hour) - current_time.hour

    return SHOWTIME_COLORS.get(hours_until_movie, "#222222")

def calculate_time_query_params(current_time):
    hours_to_seconds = int(current_time.hour) * HOUR_IN_SECONDS
    minutes_to_seconds = int(current_time.minute) * MINUTE_IN_SECONDS
    seconds = int(current_time.second)
    seconds_since_midnight = hours_to_seconds + minutes_to_seconds + seconds

    # The AmCin API uses the GMT time zone. It doesn't base the showtime window strictly on the Unix timestamp params
    # e.g. 12:01AM - 11:59PM won't work even though it should be capturing basically the same movie showtimes as below.
    # In other words, its flexibility only extends to capturing a whole day's showtimes.
    # In accordance with that, the time window used here is 12:00AM GMT - 11:59PM GMT.
    beginning_of_current_day_gmt_unix = current_time.unix - seconds_since_midnight - PT_TO_GMT_TIME_DIFFERENCE_IN_SECONDS
    end_of_current_day_gmt_unix = current_time.unix - seconds_since_midnight - PT_TO_GMT_TIME_DIFFERENCE_IN_SECONDS + DAY_IN_SECONDS - 1

    return [beginning_of_current_day_gmt_unix, end_of_current_day_gmt_unix]

def show_error_fetching_data():
    print("Error fetching data")
    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Padding(
                            child = render.Image(src = CAMERA_ICON),
                            pad = 1,
                        ),
                        render.Column(
                            children = [
                                render.Text("Sorry -", font = "tb-8", color = "#FF2222"),
                                render.Text("we can't", font = "tom-thumb", color = "#FF2222"),
                                render.Text("connect to", font = "tom-thumb", color = "#FF2222"),
                                render.Text("American", font = "tom-thumb", color = "#FF2222"),
                            ],
                            cross_align = "end",
                        ),
                    ],
                ),
                render.Padding(
                    child = render.Text("Cinematheque :(", font = "tom-thumb", color = "#FF2222"),
                    pad = (3, 0, 0, 0),
                ),
            ],
        ),
    )

# ---------------------------------------------------------------------------- #
#                                     MAIN                                     #
# ---------------------------------------------------------------------------- #

def main(config):
    local_theater = config.get("theater") or "Los Feliz 3"
    local_theater_code = THEATER_CODES[local_theater.lower()]

    timezone = config.get("timezone") or "America/Los_Angeles"
    current_time = time.now().in_location(timezone)

    beginning_of_current_day_unix, end_of_current_day_unix = calculate_time_query_params(current_time)

    showtimes_url = CINEMATHEQUE_SHOWTIMES_URL.format(
        start_time = str(beginning_of_current_day_unix),
        end_time = str(end_of_current_day_unix),
    )

    all_locations_movie_list = cache.get("showtimes_data")

    if all_locations_movie_list == None:
        res = http.get(showtimes_url)
        if res.status_code != 200:
            return show_error_fetching_data()
        all_locations_movie_list = res.json()["hits"]
        cache.set("showtimes_data", json.encode(all_locations_movie_list), ttl_seconds = HOUR_IN_SECONDS)
    else:
        all_locations_movie_list = json.decode(all_locations_movie_list)

    # Exclude showtimes from other AC theaters as well as those with incomplete data
    single_location_movie_list = [movie for movie in all_locations_movie_list if local_theater_code in movie["event_location"]]
    unsorted_movie_list = [movie for movie in single_location_movie_list if movie["title"] and movie["event_start_time"]]

    # Sort movie list by showtime and truncate (the device can only display four showtimes before running out of screen space)
    movie_list = sorted(unsorted_movie_list, key = lambda x: x["event_start_time"])[:4]

    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    main_align = "end",
                    expanded = True,
                    children = [
                        render.Column(
                            main_align = "end",
                            children = [
                                render.Marquee(
                                    width = 45,
                                    child = render.Text(movie["title"], font = "tom-thumb", color = "#89ACD4"),
                                    offset_start = 0,
                                    offset_end = 0,
                                    align = "start",
                                )
                                for movie in movie_list
                            ],
                        ),
                        render.Column(
                            main_align = "end",
                            cross_align = "end",
                            children = [
                                render.Text(
                                    time.parse_time(movie["event_start_time"], "15:04:05").format("3:04"),
                                    font = "tom-thumb",
                                    color = get_showtime_color(movie["event_start_time"], current_time),
                                )
                                for movie in movie_list
                            ],
                        ),
                    ],
                ),
                render.Column(
                    main_align = "end",
                    expanded = True,
                    children = [
                        render.Column(
                            main_align = "end",
                            expanded = True,
                            children = [
                                render.Padding(
                                    child = render.Text(local_theater.upper(), font = "CG-pixel-4x5-mono", color = "#FFDD48"),
                                    pad = 1,
                                    color = "#222",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Los Feliz 3",
            value = "Los Feliz 3",
        ),
        schema.Option(
            display = "Aero Theatre",
            value = "Aero Theatre",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "theater",
                name = "Theater",
                desc = "Theater for which to display showtimes.",
                icon = "film",
                default = options[0].value,
                options = options,
            ),
        ],
    )
