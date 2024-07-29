"""
Applet: Olympic Medals
Summary: Olympics medal standings
Description: View the top 3 countries in the Olympics medal standings.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

RINGS_LOGO = base64.decode("""
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
""")

API_URL = "https://api.olympics.kevle.xyz/medals"
CACHE_TTL = 3600
FLAG_TTL = 3600 * 24 * 30  # 30 days

DEFAULT_DISPLAY = "standings"

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    # get config
    display = config.str("display", DEFAULT_DISPLAY)
    country_code = config.str("country", None)

    # call api
    res = http.get(API_URL, ttl_seconds = CACHE_TTL)

    # check for errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(str(res.status_code))

    # get data
    data = res.json()

    # render according to selected display
    if display == DEFAULT_DISPLAY:
        return render_standings(data)
    else:
        return render_country(country_code, data)

def render_standings(data):
    """Renders the standings (top 3) display.

    Args:
        data (dict): Dictionary with standings data.

    Returns:
        render.Root: Root widget tree.
    """

    # build widgets for the top 3 countries
    first = build_row(data["results"][0], 1)
    second = build_row(data["results"][1], 2)
    third = build_row(data["results"][2], 3)

    return render.Root(
        child = render.Column(
            children = [
                render_header(),
                first,
                second,
                third,
            ],
        ),
    )

def render_country(country_code, data):
    """Renders the display for a specific country.

    Args:
        country_code (str): The country code (ie: FRA).
        data (dict): Dictionary with standings data.

    Returns:
        render.Root: Root widget tree.
    """

    # extract country from the array based on the country code
    country_data = [result for result in data["results"] if result["country"]["code"] == country_code][0]

    # get flag image
    res = http.get("https://gstatic.olympics.com/s1/t_original/static/noc/oly/3x2/180x120/%s.png" % country_code, ttl_seconds = FLAG_TTL)

    flag_image = res.body()

    # get medal counts
    gold = str(int(country_data["medals"]["gold"]))
    silver = str(int(country_data["medals"]["silver"]))
    bronze = str(int(country_data["medals"]["bronze"]))
    total = str(int(country_data["medals"]["total"]))

    # get country ranking
    rank = country_data["rank"]

    if rank == 1:
        rank = "1st"
    elif rank == 2:
        rank = "2nd"
    elif rank == 3:
        rank = "3rd"
    else:
        rank = "%dth" % rank

    return render.Root(
        child = render.Column(
            children = [
                render_header(),
                render.Box(height = 1, color = "#000"),
                render.Row(
                    children = [
                        render.Padding(
                            pad = (1, 0, 1, 0),
                            child = render.Image(src = flag_image, height = 11),
                        ),
                        render.Column(
                            children = [
                                render.Marquee(width = 46, child = render.Text(country_data["country"]["name"], font = "tom-thumb")),
                                render.Text("Rank: %s" % rank, font = "tom-thumb"),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 16, height = 8, color = "#f4ca72", child = render.Text(gold, font = "tom-thumb", color = "#333333", offset = -1)),
                        render.Box(width = 16, height = 8, color = "#e5e5e5", child = render.Text(silver, font = "tom-thumb", color = "#333333", offset = -1)),
                        render.Box(width = 16, height = 8, color = "#d5b58c", child = render.Text(bronze, font = "tom-thumb", color = "#333333", offset = -1)),
                        render.Box(width = 16, height = 8, color = "#333333", child = render.Text(total, font = "tom-thumb", offset = -1)),
                    ],
                ),
            ],
        ),
    )

def build_row(data, position):
    """Builds a Row widget tree to represent country medals.

    Args:
        data (dict): Country and medal data.
        position (number): Position in ranking (ie: 1, 2, 3)

    Returns:
        widget: Widget tree.
    """

    # select color based on position
    color = ["#3b3b3b", "#000000"][position % 2]

    # get country and medal data
    code = data["country"]["code"]
    gold = int(data["medals"]["gold"])
    silver = int(data["medals"]["silver"])
    bronze = int(data["medals"]["bronze"])
    total = str(gold + silver + bronze)

    return render.Row(
        main_align = "center",
        cross_align = "center",
        expanded = True,
        children = [
            render.Box(width = 14, height = 7, color = color, child = render.Text(code, font = "tom-thumb", offset = -1)),
            render.Box(width = 12, height = 7, color = color, child = render.Text(str(gold), color = "#f4ca72", font = "tom-thumb", offset = -1)),
            render.Box(width = 12, height = 7, color = color, child = render.Text(str(silver), color = "#e5e5e5", font = "tom-thumb", offset = -1)),
            render.Box(width = 12, height = 7, color = color, child = render.Text(str(bronze), color = "#d5b58c", font = "tom-thumb", offset = -1)),
            render.Box(width = 14, height = 7, color = color, child = render.Text(total, font = "tom-thumb", offset = -1)),
        ],
    )

def render_header():
    """Renders the app header.

    Returns:
        render.Row: Widgets holding the app header.
    """

    return render.Row(
        children = [
            render.Padding(
                pad = (1, 1, 1, 0),
                child = render.Image(
                    height = 10,
                    src = RINGS_LOGO,
                ),
            ),
            render.Box(
                height = 11,
                child = render.Text(
                    content = "PARIS 2024",
                    font = "tom-thumb",
                    offset = -1,
                    color = "#d4c482",
                ),
            ),
        ],
    )

def render_error(status_code):
    """Renders an API error.

    Args:
        status_code (str): The status code returned by the API.

    Returns:
        render.Root: Root widget tree.
    """
    return render.Root(
        child = render.Column(
            children = [
                render_header(),
                render.Box(
                    height = 10,
                    child = render.Text(
                        content = "API ERROR",
                        color = "#f00",
                    ),
                ),
                render.Box(
                    height = 10,
                    child = render.Text(
                        content = "CODE %s" % status_code,
                        color = "#ff0",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display",
                name = "Display Mode",
                desc = "What should be displayed?",
                icon = "medal",
                options = [
                    schema.Option(display = "Top 3 Countries", value = "standings"),
                    schema.Option(display = "Specific Country", value = "country"),
                ],
                default = DEFAULT_DISPLAY,
            ),
            schema.Generated(
                id = "generated",
                source = "display",
                handler = handle_display,
            ),
        ],
    )

def handle_display(display):
    """Handles the display options supported by the app.
       When "country" is selected, returns a dynamic list of the supported countries.

    Args:
        display (str): The display type chosen by the app user.

    Returns:
        list: List of schema fields to show.
    """

    # for the default display (standings), there are no additional schema fields
    if display == DEFAULT_DISPLAY:
        return []

    # build list of countries based on the API result
    res = http.get(API_URL, ttl_seconds = CACHE_TTL)

    data = res.json()

    countries = []

    # iterate through each country and build a list of schema.Option objects
    for result in sorted(data["results"], key = sort_country):
        display = "%s (%s)" % (result["country"]["name"], result["country"]["code"])

        countries.append(
            schema.Option(display = display, value = result["country"]["code"]),
        )

    return [
        schema.Dropdown(
            id = "country",
            name = "Country",
            desc = "Select the country.",
            icon = "flag",
            options = countries,
            default = countries[0].value,
        ),
    ]

def sort_country(countries):
    """Used to sort a list of countries based on the name.

    Args:
        countries (list): List of country objects.

    Returns:
        str: The country name.
    """

    return countries["country"]["name"]
