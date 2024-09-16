"""
Applet: EuroMillions
Summary: EuroMillions results
Description: Results for the most recent draw of the EuroMillions transnational lottery.
Author: dinosaursrarr
"""

load("cache.star", "cache")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

RESULTS_URL = "https://www.national-lottery.co.uk/results/euromillions/draw-history/csv"
TIMEZONE = "Europe/Paris"

WHITE = "#ffffff"
BLACK = "#000000"
RED = "#f00000"
YELLOW = "#fff100"

def parse_time(time_str):
    return time.parse_time(time_str, "02-Jan-2006", TIMEZONE)

def seconds_until_next_draw(latest_result):
    # Draws happen at 8.45pm on Tuesday and Friday in Paris so cache until then.
    last_draw = parse_time(latest_result[0])
    last_draw_weekday = humanize.day_of_week(last_draw)
    if last_draw_weekday == 2:
        next_draw_days = 3
    elif last_draw_weekday == 5:
        next_draw_days = 4
    else:
        return time.hour // time.second
    next_draw = last_draw + (((next_draw_days * 24) + 20) * time.hour) + (45 * time.minute)
    return (next_draw - time.now()) // time.second

def fetch_latest_result():
    cached = cache.get(RESULTS_URL)
    if cached:
        return csv.read_all(cached)[1]
    resp = http.get(RESULTS_URL)
    if resp.status_code != 200:
        return None
    results = csv.read_all(resp.body())

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(RESULTS_URL, resp.body(), ttl_seconds = seconds_until_next_draw(results[1]))
    return results[1]

def parse_result(result):
    draw_date = parse_time(result[0])
    balls = [int(b) for b in result[1:6]]
    lucky_stars = [int(b) for b in result[6:8]]
    millionaire_maker_codes = result[8].split(",") + result[9].split(",")
    return draw_date, balls, lucky_stars, millionaire_maker_codes

def render_ball(number, ball_colour, text_colour):
    return render.Circle(
        color = ball_colour,
        diameter = 9,
        child = render.Text(
            str(number),
            color = text_colour,
            font = "tom-thumb",
        ),
    )

def main():
    latest_result = fetch_latest_result()
    if not latest_result:
        return render.Root(render.Text("Cannot load results"))
    draw_date, balls, lucky_stars, millionaire_maker_codes = parse_result(latest_result)

    return render.Root(
        child = render.Column(
            children = [
                render.Padding(
                    pad = (0, 1, 0, 0),
                    color = YELLOW,
                    child = render.WrappedText(
                        content = "EUROMILLIONS",
                        width = 64,
                        align = "center",
                        color = BLACK,
                        font = "tom-thumb",
                    ),
                ),
                render.Padding(
                    pad = (0, 2, 0, 1),
                    child = render.WrappedText(
                        content = humanize.time_format("EEE d MMM yyyy", draw_date),
                        width = 64,
                        align = "center",
                        color = WHITE,
                        font = "tom-thumb",
                    ),
                ),
                render.Row(
                    children = [
                        render_ball(ball, RED, WHITE)
                        for ball in balls
                    ] + [
                        render_ball(ball, YELLOW, BLACK)
                        for ball in lucky_stars
                    ],
                ),
                render.Padding(
                    pad = (0, 1, 0, 0),
                    child = render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(
                            content = " ".join([c for c in millionaire_maker_codes if c]),
                            font = "tom-thumb",
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
