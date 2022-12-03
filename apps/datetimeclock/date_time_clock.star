"""
Applet: Date Time Clock
Summary: Shows full time and date
Description: Displays the full date and current time for user.
Author: Alex Miller/AmillionAir
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""
DEFAULT_IS_24_HOUR_FORMAT = False
DEFAULT_IS_US_DATE_FORMAT = False

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]

    now = time.now().in_location(timezone)

    is_us_date_format = config.bool("is_us_date_format", DEFAULT_IS_US_DATE_FORMAT)
    now_date = now.format("2 Jan 2006").upper()
    if is_us_date_format:
        now_date = now.format("Jan 2 2006").upper()

    day = now.format("Monday").upper()

    is_24_hour_format = config.bool("is_24_hour_format", DEFAULT_IS_24_HOUR_FORMAT)
    time_format_separator = "3:04 PM"
    time_format_no_separator = "3 04 PM"
    if is_24_hour_format:
        time_format_separator = "15:04"
        time_format_no_separator = "15 04"

    return render.Root(
        delay = 500,
        child = render.Column(
            expanded = True,
            cross_align = "center",
            children = [
                render.Box(width = 64, height = 1),
                render.Animation(
                    children = [
                        render.Text(
                            content = now.format(time_format_separator),
                            font = "6x13",
                        ),
                        render.Text(
                            content = now.format(time_format_no_separator),
                            font = "6x13",
                        ),
                    ],
                ),
                render.Text(
                    content = day,
                ),
                render.Text(
                    content = now_date,
                    font = "5x8",
                ),
                render.Box(width = 64, height = 1),
                render.Box(width = 64, height = 1),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format (default is Intl).",
                icon = "calendarDays",
            ),
        ],
    )
