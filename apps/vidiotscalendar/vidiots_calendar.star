"""
Applet: Vidiots Calendar
Summary: Showtimes for Vidiots (LA)
Description: Movie showtimes for the next 7 days at Vidiots in Los Angeles, CA.
Author: Buzz Andersen
"""

load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VIDIOTS_URL = "https://vidiotsfoundation.org/coming-soon/"
ANIMATION_DELAY = 50
SEVEN_DAY_DURATION = "168h"
THIRTY_DAY_DURATION = "720h"
MOVIE_PAGE_SIZE = 5
TITLE_CHARACTER_LIMIT = 32

def main(config):
    response = http.get(VIDIOTS_URL, ttl_seconds = 240)

    if response.status_code != 200:
        fail("Vidiots request failed with status %d", response.status_code)

    date_limit_config = config.str(DATE_LIMIT_CONFIG_KEY, SEVEN_DAYS_CONFIG_KEY)
    if date_limit_config == THIRTY_DAYS_CONFIG_KEY:
        date_limit_duration = THIRTY_DAY_DURATION
    else:
        date_limit_duration = SEVEN_DAY_DURATION

    movies = parse_movie_html(response.body(), date_limit_duration)
    movie_count = len(movies)

    pages = []
    if movie_count >= MOVIE_PAGE_SIZE and config.bool(RANDOM_PAGINATION_CONFIG_KEY, False):
        page_count = math.floor(movie_count / MOVIE_PAGE_SIZE)

        for i in range(math.floor(page_count)):
            index = MOVIE_PAGE_SIZE * i
            pages.append(range(index, index + MOVIE_PAGE_SIZE))

        last_segment_index = movie_count - MOVIE_PAGE_SIZE
        pages.append(range(last_segment_index, last_segment_index + MOVIE_PAGE_SIZE))
    else:
        pages.append(range(0, movie_count))

    page_selection = pages[random.number(0, len(pages) - 1)]

    selected_movies = []
    for i in page_selection:
        selected_movies.append(movies[i])

    return render_animation_for_movies(selected_movies, config.bool(FULL_ANIMATION_CONFIG_KEY, False))

def parse_movie_html(html_body, date_limit_duration):
    movie_list = html(html_body).find("#upcoming-films").children_filtered(".show-list").children_filtered(".show-details")

    date_now = time.now()
    date_limit = date_now + time.parse_duration(date_limit_duration)

    movies = []

    for i in range(movie_list.len()):
        details = movie_list.eq(i)
        title = details.find(".title").text()
        dates = details.find(".single-show-showtimes").children_filtered(".showtimes-container").children_filtered(".showtimes").children_filtered("li")

        valid_dates = {}

        for i in range(dates.len()):
            date_info = dates.eq(i)

            epoch = int(date_info.attr("data-date"))
            date = time.from_timestamp(epoch)

            showtime = date_info.children_filtered(".showtime")

            showtime_extra_text = showtime.children_filtered(".extra").text().strip()
            showtime_text = showtime.text().replace("\n", "").replace("\t", "").replace(showtime_extra_text, "").strip()

            is_past = (date.month < date_now.month) or ((date.month == date_now.month) and (date.day < date_now.day))
            is_beyond_limit = (date.month > date_limit.month) or ((date.month == date_limit.month) and (date.day > date_limit.day))

            if is_past == False and is_beyond_limit == False:
                if valid_dates.get(epoch) == None:
                    valid_dates[epoch] = []
                valid_dates[epoch].append(struct(date = date.format("Mon, Jan 2") + " - " + showtime_text, extra = showtime_extra_text.replace("*", "")))

        if len(valid_dates) > 0:
            current_movie = struct(title = title, dates = valid_dates)
            movies.append(current_movie)

    return movies

def render_animation_for_movies(movies, full_animation):
    movie_count = len(movies)

    movie_nodes = []

    for i in range(movie_count):
        current_movie = movies[i]

        time_nodes = []

        dates_count = len(current_movie.dates)
        for j in range(len(current_movie.dates)):
            current_date = current_movie.dates.items()[j]
            showtimes = current_date[1]
            first_time = showtimes[0]
            additional_count = len(showtimes) - 1

            time_string = first_time.date
            if additional_count > 0:
                time_string = time_string + " + " + str(additional_count) + " more"

            showtime_extra_text = ""
            if len(first_time.extra) > 0:
                showtime_extra_text = " (" + first_time.extra + ")"

            time_child_nodes = [
                render.Column(
                    children = [
                        render.Text(time_string),
                    ],
                ),
                render.Column(
                    children = [
                        render.Text(showtime_extra_text, color = "#ed1c24"),
                    ],
                ),
            ]

            if j < (dates_count - 1):
                time_child_nodes.append(
                    render.Text(" • "),
                )

            time_nodes.append(
                render.Row(
                    children = time_child_nodes,
                ),
            )

        current_title = current_movie.title
        if len(current_movie.title) > TITLE_CHARACTER_LIMIT:
            current_title = current_movie.title[:TITLE_CHARACTER_LIMIT] + "..."

        movie_nodes.append(
            render.Column(
                main_align = "center",
                children = [
                    render.Row(
                        children = [
                            render.Text(current_title, color = "#67bdee"),
                        ],
                    ),
                    render.Row(
                        children = time_nodes,
                    ),
                ],
            ),
        )

        if i < (movie_count - 1):
            movie_nodes.append(
                render.Padding(
                    pad = (4, 0, 4, 0),
                    child = render.Box(
                        width = 1,
                        height = 16,
                        color = "#ee7db8",
                    ),
                ),
            )

    return render.Root(
        delay = ANIMATION_DELAY,
        show_full_animation = full_animation,
        child = render.Padding(
            pad = (0, 0, 0, 2),
            child = render.Column(
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Box(
                        height = 14,
                        child = render.Row(
                            children = [
                                render.Box(
                                    width = 14,
                                    child = render.Image(src = VIDIOTS_LOGO, width = 14, height = 14),
                                ),
                                render.Box(
                                    height = 14,
                                    child = render.Text("Vidiots", height = 10),
                                ),
                            ],
                        ),
                    ),
                    render.Marquee(
                        offset_start = 64,
                        offset_end = 64,
                        width = 64,
                        child = render.Row(
                            children = movie_nodes,
                        ),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    date_limit_options = [
        schema.Option(
            display = "7 Days",
            value = SEVEN_DAYS_CONFIG_KEY,
        ),
        schema.Option(
            display = "30 Days",
            value = THIRTY_DAYS_CONFIG_KEY,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = DATE_LIMIT_CONFIG_KEY,
                name = "Date Limit",
                desc = "Include showtimes within the next...",
                icon = "calendar",
                default = date_limit_options[0].value,
                options = date_limit_options,
            ),
            schema.Toggle(
                id = FULL_ANIMATION_CONFIG_KEY,
                name = "Show Full List",
                desc = "Request that Tidbyt show the full movie list rather than being limited to the normal app cycle time.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = RANDOM_PAGINATION_CONFIG_KEY,
                name = "Random Pagination",
                desc = "Split the entire movie list into pages and show a random page each time.",
                icon = "shuffle",
                default = False,
            ),
        ],
    )

DATE_LIMIT_CONFIG_KEY = "date_limit"
SEVEN_DAYS_CONFIG_KEY = "7_days"
THIRTY_DAYS_CONFIG_KEY = "30_days"
FULL_ANIMATION_CONFIG_KEY = "full_animation"
RANDOM_PAGINATION_CONFIG_KEY = "random_pagination"

VIDIOTS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAEsWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS41LjAiPgogPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIKICAgIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIKICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIKICAgIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIgogICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgdGlmZjpJbWFnZUxlbmd0aD0iNDgiCiAgIHRpZmY6SW1hZ2VXaWR0aD0iNDgiCiAgIHRpZmY6UmVzb2x1dGlvblVuaXQ9IjIiCiAgIHRpZmY6WFJlc29sdXRpb249Ijk2LzEiCiAgIHRpZmY6WVJlc29sdXRpb249Ijk2LzEiCiAgIGV4aWY6UGl4ZWxYRGltZW5zaW9uPSI0OCIKICAgZXhpZjpQaXhlbFlEaW1lbnNpb249IjQ4IgogICBleGlmOkNvbG9yU3BhY2U9IjEiCiAgIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiCiAgIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIKICAgeG1wOk1vZGlmeURhdGU9IjIwMjQtMDgt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
""")
