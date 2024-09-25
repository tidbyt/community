"""
Applet: Life Counter
Summary: Lifespan elapsed/remaining
Description: Visually represents the months elapsed since DOB and remaining before reaching a user-selected age.
Author: danceforheaven
"""

# This is total spaghetti, but it does work.

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

COLUMN_HEIGHT = 24

DEFAULT_YEARS_DISPLAYED = "100"
DEFAULT_DATE_OF_BIRTH = "1990-01-01T03:35:25.000Z"
DEFAULT_LOCATION = json.encode({"timezone": "America/Chicago"})

def find_months_alive(current_time, date_of_birth):
    years_alive = current_time.year - date_of_birth.year
    months_offset = current_time.month - date_of_birth.month
    return max(1, (years_alive * 12) + months_offset)  # does not include current month

def plot_filler(plot_list, num_columns, months_remaining):
    for i in range(0, num_columns * COLUMN_HEIGHT):
        if months_remaining[0] > 0:
            plot_list.append((i // COLUMN_HEIGHT, -(i % COLUMN_HEIGHT)))
            months_remaining[0] -= 1

def create_months_plot(months_alive, years_displayed):
    # empty list will contain plot, int is number of columns in plot
    months_plot = {"filled": [[], 0], "halffull": [[], 0], "halfempty": [[], 0], "empty": [[], 0]}

    months_remaining = [years_displayed * 12]  # in list so can be passed by reference

    total_columns = years_displayed * 12 // COLUMN_HEIGHT
    if months_remaining[0] % COLUMN_HEIGHT != 0:
        total_columns += 1
    months_plot["filled"][1] = min(months_alive // COLUMN_HEIGHT, total_columns)
    months_plot["halffull"][1] = 0 if months_alive % COLUMN_HEIGHT == 0 or months_plot["filled"][1] >= total_columns else 1
    months_plot["halfempty"][1] = months_plot["halffull"][1]
    months_plot["empty"][1] = max(0, total_columns - (months_plot["filled"][1] + months_plot["halffull"][1]))

    plot_filler(months_plot["filled"][0], months_plot["filled"][1], months_remaining)
    if months_plot["halffull"][1] == 1:
        for i in range(0, months_alive % COLUMN_HEIGHT):
            if months_remaining[0] > 0:
                months_plot["halffull"][0].append((0, -(i)))
                months_remaining[0] -= 1
        for i in range(0, COLUMN_HEIGHT - (months_alive % COLUMN_HEIGHT)):
            if months_remaining[0] > 0:
                months_plot["halfempty"][0].append((0, -(i)))
                months_remaining[0] -= 1
    plot_filler(months_plot["empty"][0], months_plot["empty"][1], months_remaining)

    print("halffull", months_plot["halffull"][0])
    print("halfempty", months_plot["halfempty"][0])
    return months_plot

def render_workaround(months_plot, key, color):
    if len(months_plot[key][0]) == 1:
        return render.Box(
            width = 1,
            height = 1,
            color = color,
        )
    else:
        return render.Plot(
            data = months_plot[key][0],
            width = months_plot[key][1],
            height = len(months_plot[key][0]),
            color = color,
        )

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    timezone = json.decode(location)["timezone"]
    date_of_birth = time.parse_time(config.get("date of birth", DEFAULT_DATE_OF_BIRTH))
    years_displayed = int(config.get("years displayed", DEFAULT_YEARS_DISPLAYED))
    if years_displayed % 2 == 1:
        years_displayed -= 1
    if years_displayed > 120:
        years_displayed = 120

    current_time = time.now().in_location(timezone)
    print(current_time)
    print(date_of_birth)
    print(timezone)

    months_alive = find_months_alive(current_time, date_of_birth)
    print(months_alive)
    months_plot = create_months_plot(months_alive, years_displayed)
    months_plot_flash = create_months_plot(months_alive + 1, years_displayed)

    return render.Root(
        delay = 1000 - (28 * current_time.day),
        child = render.Animation(children = [
            render.Column(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Plot(
                                data = months_plot["filled"][0],
                                width = months_plot["filled"][1],
                                height = COLUMN_HEIGHT,
                                color = "#ff0000",
                                # chart_type = 'scatter'
                            ),
                            render.Column(
                                children = [
                                    render_workaround(months_plot, "halffull", "#ff0000"),
                                    render_workaround(months_plot, "halfempty", "#ffffff"),
                                ],
                            ),
                            render.Plot(
                                data = months_plot["empty"][0],
                                width = months_plot["empty"][1],
                                height = COLUMN_HEIGHT,
                                color = "#ffffff",
                                # chart_type = 'scatter'
                            ),
                        ],
                    ),
                ],
            ),
            render.Column(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Plot(
                                data = months_plot_flash["filled"][0],
                                width = months_plot_flash["filled"][1],
                                height = COLUMN_HEIGHT,
                                color = "#ff0000",
                                # chart_type = 'scatter'
                            ),
                            render.Column(
                                children = [
                                    render_workaround(months_plot_flash, "halffull", "#ff0000"),
                                    render_workaround(months_plot_flash, "halfempty", "#ffffff"),
                                ],
                            ),
                            render.Plot(
                                data = months_plot_flash["empty"][0],
                                width = months_plot_flash["empty"][1],
                                height = COLUMN_HEIGHT,
                                color = "#ffffff",
                                # chart_type = 'scatter'
                            ),
                        ],
                    ),
                ],
            ),
        ]),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "years displayed",
                name = "Years Displayed",
                desc = "The number of years displayed in dots. Max 120, even numbers only.",
                icon = "clock",
            ),
            schema.DateTime(
                id = "date of birth",
                name = "Date of birth",
                desc = "The date on which you were born.",
                icon = "calendar",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location, used to find your timezone.",
                icon = "map",
            ),
        ],
    )
