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

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]

    now = time.now().in_location(timezone)
    now_date = now.format("2 JAN 2006")
    day = now.format("Monday")

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
                            content = now.format("3:04 PM"),
                            font = "6x13",
                        ),
                        render.Text(
                            content = now.format("3 04 PM"),
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
                icon = "place",
            ),
        ],
    )
