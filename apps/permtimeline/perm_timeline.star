"""
Applet: PERM Timeline
Summary: Track PERM progress
Description: PERM Timeline offers a comprehensive view of the processing journey for PERM applications. Discover how many applications were completed today, calculate how long it's been since your submission, and get an estimate of how much time remains before your application is approved. The tool also provides an approximate approval date to help you plan ahead with confidence.
Author: Ihor Burenko
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

timezone = "America/New_York"
DATE_FORMAT = "2006-01-02"
PRINTABLE_DATE_FORMAT = "Jan 2 2006"

DATA_URL = "https://perm-parser.onrender.com/api/parse"
DEFAULT_APPLICATION_DATE = "2024-08-13T13:32:32.000Z"

CHECK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAACXBIWXMAAAsTAAALEwEAmpw
YAAAAiUlEQVR4nGNggIFpdlEMU+2qwRjERgFT7SsZptj/ZJhq/x+Mp9j/DNpeMwmhE1lyqv1
/z81l/3c+PPUXYtJUu2r9lUn/a07OAUvarc/7f/zF1f9KiyP/g62D2Gv/v+7kvP+r7uz/f+n
N3f/i8wOgpoEUQK1gm+4CVgSXBFkLdywWR4LFUAAObwIAn3hf+d8jSA0AAAAASUVORK5CYII=
""")

COLOR_GREEN = "#00953E"
COLOR_BLUE = "#0051ba"
CACHE_TIME = 300

def main(config):
    application_date = config.get("application_date", DEFAULT_APPLICATION_DATE)

    rep = http.get(DATA_URL, ttl_seconds = CACHE_TIME)
    if rep.status_code != 200:
        fail("Backend request failed with status %d", rep.status_code)

    today_completed = rep.json()["today_completed"]
    days_to_approval = rep.json()["days_to_approval"]["value"]

    calculated_dates = calculate_dates(days_to_approval, application_date)

    return render.Root(
        render.Box(
            child = render.Column(
                children = [
                    _get_today_completed(today_completed),
                    _get_padding(),
                    _get_chart(calculated_dates),
                    _get_approval_date(calculated_dates),
                ],
                main_align = "center",
            ),
        ),
    )

def _get_padding(pad = 0):
    return render.Padding(
        child = render.Box(
            width = 58,
            height = 1,
            color = "#000",
        ),
        pad = pad,
    )

def _get_limited_pixels(days_in_px, min_pixels = 11, max_pixels = 50):
    if days_in_px > 50:
        return max_pixels
    if days_in_px < 9:
        return min_pixels
    return days_in_px

def _get_chart_row(pixels_days_after, pixels_days_left):
    ROW_HEIGHT = 2
    return render.Row(
        children = [
            render.Box(
                width = _get_limited_pixels(pixels_days_after, 1, 63),
                height = ROW_HEIGHT,
                color = COLOR_GREEN,
            ),
            render.Box(
                width = _get_limited_pixels(pixels_days_left, 1, 63),
                height = ROW_HEIGHT,
                color = COLOR_BLUE,
            ),
        ],
    )

def _get_chart(calculated_dates):
    days_after_start = calculated_dates["days_after_start"]
    days_left = calculated_dates["days_left"]
    days_to_px = calculate_pixels(days_after_start, days_left)

    return render.Column(
        children = [
            _get_chart_row(days_to_px["pixels_days_after"], days_to_px["pixels_days_left"]),
            render.Row(
                children = [
                    render.Box(
                        width = _get_limited_pixels(days_to_px["pixels_days_after"]),
                        height = 6,
                        child = render.Text(
                            content = "{}".format(calculated_dates["days_after_start"]),
                            font = "5x8",
                        ),
                    ),
                    render.Box(
                        width = _get_limited_pixels(days_to_px["pixels_days_left"]),
                        height = 6,
                        child = render.Text(
                            content = "{}".format(calculated_dates["days_left"]),
                            font = "5x8",
                        ),
                    ),
                ],
                main_align = "space_between",
                expanded = True,
            ),
            _get_chart_row(days_to_px["pixels_days_after"], days_to_px["pixels_days_left"]),
        ],
    )

def _get_approval_date(calculated_dates):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = "Approximate approval date",
                            font = "tom-thumb",
                        ),
                        offset_start = 0,
                        offset_end = 0,
                    ),
                ],
            ),
            render.Row(
                children = [
                    render.Box(
                        width = 64,
                        height = 8,
                        color = "#004",
                        child = render.Text(
                            content = calculated_dates["approximate_approval_date"],
                            font = "5x8",
                        ),
                    ),
                ],
            ),
        ],
        main_align = "center",
        expanded = True,
    )

def _get_today_completed(today_completed):
    return render.Row(
        children = [
            render.Image(src = CHECK_ICON),
            render.Text(
                content = today_completed,
                font = "5x8",
            ),
            render.Text(
                content = " today",
                font = "5x8",
            ),
        ],
        main_align = "center",
        expanded = True,
    )

def calculate_dates(days_to_approval, start_date):
    now = time.now().in_location(timezone)
    parsed_start_date = time.parse_time(start_date).in_location("America/New_York")

    days_after_start = int((now - parsed_start_date).hours // 24)
    days_left = days_to_approval - days_after_start
    approximate_approval_date = (now + time.parse_duration(str(days_left * 24) + "h")).format(PRINTABLE_DATE_FORMAT)
    return {
        "days_after_start": days_after_start,
        "days_left": int(days_left),
        "approximate_approval_date": approximate_approval_date,
    }

def calculate_pixels(days_after_start, days_left, total_pixels = 64):
    total_days = days_after_start + days_left

    percent_days_after = days_after_start * 100 / total_days

    pixels_days_after = int(math.round((percent_days_after / 100) * total_pixels))
    pixels_days_left = total_pixels - pixels_days_after

    return {
        "pixels_days_after": pixels_days_after,
        "pixels_days_left": int(pixels_days_left),
    }

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "application_date",
                name = "Application Date",
                desc = "Date when your PERM was filed",
                icon = "gear",
            ),
        ],
    )
