"""
Applet: Abstract Clock
Summary: Shows Time
Description: Uses 60 Pixels to display time across width of Tidbyt.
Author: AmillionAir
"""

load("encoding/base64.star", "base64")
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

P_COLOR_MINUTE = "#0ff"  # Cyan
P_COLOR_MONTH = "#0f0"  # Green
P_COLOR_HOUR = "#f00"  # Red

def main(config):
    COLOR_MINUTE = config.get("color_minute", P_COLOR_MINUTE)
    COLOR_HOUR = config.get("color_hour", P_COLOR_HOUR)
    COLOR_MONTH = config.get("color_month", P_COLOR_MONTH)

    Top = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAALCAYAAADP9otxAAAAAXNSR0IArs4c6QAAALhJREFUSEvtVdsNwCAIhHm6/yjOQ0MTDCUKaP1pq38iD+88AeHnCyP8RESIWP14zzGeTWJmY+VOrRpSW+6h9+Kv69q76P0VO0oA+1tg1uYRoEH1crXsHhDOOXpea2wCAgai15ZwKztPxp60W/nktXTO3hfIKmFaAZke0AORkbZHgJa69csCf9wDWorI9IVZYD2gKwhgQoeb4CYgMQajf7yiB3jKWDoGoynx9vPbFygAdBhEBQC+bDsBXa855qlHHEIAAAAASUVORK5CYII=")

    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]

    now = time.now().in_location(timezone)
    Minute = now.format("4")
    Hour = now.format("3")
    Month = now.format("Jan")

    if config.bool("Day"):
        Day = now.format("Monday").upper()
        Day_Num = now.format("2")
    else:
        Day = " "
        Day_Num = " "

    if config.bool("Month_Icon"):
        MIcon = COLOR_MONTH
    else:
        MIcon = "#000"

    if Month == "Jan":
        MHand = 8

    elif Month == "Feb":
        MHand = 13

    elif Month == "Mar":
        MHand = 18

    elif Month == "Apr":
        MHand = 23

    elif Month == "May":
        MHand = 28

    elif Month == "Jun":
        MHand = 33

    elif Month == "Jul":
        MHand = 38

    elif Month == "Aug":
        MHand = 43

    elif Month == "Sep":
        MHand = 48

    elif Month == "Oct":
        MHand = 53

    elif Month == "Nov":
        MHand = 58

    else:
        MHand = 63

    if Hour == "1":
        Hand = 8

    elif Hour == "2":
        Hand = 13

    elif Hour == "3":
        Hand = 18

    elif Hour == "4":
        Hand = 23

    elif Hour == "5":
        Hand = 28

    elif Hour == "6":
        Hand = 33

    elif Hour == "7":
        Hand = 38

    elif Hour == "8":
        Hand = 43

    elif Hour == "9":
        Hand = 48

    elif Hour == "10":
        Hand = 53

    elif Hour == "11":
        Hand = 58

    else:
        Hand = 63

    return render.Root(
        max_age = 120,
        child = render.Column(
            children = [
                render.Image(Top),
                render.Stack(
                    children = [
                        render.Row(
                            children = [
                                render.Box(width = MHand, height = 11),
                                render.Box(width = 1, height = 13, color = MIcon),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Box(width = int(Minute) + 3, height = 9),
                                render.Box(width = 1, height = 11, color = COLOR_MINUTE),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Box(width = Hand, height = 9),
                                render.Box(width = 1, height = 9, color = COLOR_HOUR),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    cross_align = "end",
                    main_align = "space_between",
                    children = [
                        render.Text(Day),
                        render.Text(Day_Num),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    colors = [
        schema.Option(display = "White", value = "#fff"),
        schema.Option(display = "Red", value = "#f00"),
        schema.Option(display = "Green", value = "#0f0"),
        schema.Option(display = "Blue", value = "#00f"),
        schema.Option(display = "Yellow", value = "#ff0"),
        schema.Option(display = "Cyan", value = "#0ff"),
        schema.Option(display = "Magenta", value = "#f0f"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "Day",
                name = "Display Day of Week",
                desc = "A toggle to display current Day of the week.",
                icon = "compress",
                default = False,
            ),
            schema.Toggle(
                id = "Month_Icon",
                name = "Display Month",
                desc = "A toggle to display a line for the current month.",
                icon = "calendar",
                default = False,
            ),
            schema.Dropdown(
                id = "color_minute",
                icon = "palette",
                name = "Minute hand color",
                desc = "The color of the Minute hand.",
                options = colors,
                default = P_COLOR_MINUTE,
            ),
            schema.Dropdown(
                id = "color_month",
                icon = "palette",
                name = "Month hand color",
                desc = "The color of the Month hand.",
                options = colors,
                default = P_COLOR_MONTH,
            ),
            schema.Dropdown(
                id = "color_hour",
                icon = "palette",
                name = "Hour hand color",
                desc = "The color of the Hour hand.",
                options = colors,
                default = P_COLOR_HOUR,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
        ],
    )
