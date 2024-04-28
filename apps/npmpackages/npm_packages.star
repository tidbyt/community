"""
Applet: NPM Packages
Summary: View NPM package downloads
Description: Track the number of downloads of a NPM package on the last day, week or month.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

NPM_LOGO = base64.decode("""
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
""")
DOWNLOAD_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAERJREFUKFNjZCASMKKr+////3+QGCMjI4ocDRXCrER3CswJKFajK0Z2J1ghSAFMEN0zMDkMhdhCAWQIXCG+4IQrJCbMAVhpLAt4D3VAAAAAAElFTkSuQmCC
""")
SEARCH_URL = "https://www.npmjs.com/search?q=%s"
DATA_URL = "https://api.npmjs.org/downloads/range/last-%s/%s"
DEFAULT_PACKAGE = json.encode({"display": "axios", "value": "axios"})
DEFAULT_DOWNLOAD_PERIOD = "week"
DEFAULT_DOT_SEPARATOR = False
CACHE_TTL = 21600  # 6 hours

def main(config):
    """Main app function.

    Args:
        config (config): The app configuration options.

    Returns:
        render.Root: The root widget tree to render the app.
    """

    # get configs
    package = json.decode(config.get("package", DEFAULT_PACKAGE))
    download_period = config.get("download_period", DEFAULT_DOWNLOAD_PERIOD)
    dot_separator = config.bool("dot", DEFAULT_DOT_SEPARATOR)

    # get package data
    package_name = package["value"]
    url = DATA_URL % (download_period, humanize.url_encode(package_name))
    res = http.get(url, ttl_seconds = CACHE_TTL)

    # handle api response
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))

        data = res.json()
        if "error" in data:
            return render_error(res.status_code, data["error"])
        else:
            return render_error(res.status_code, res.body())

    data = res.json()

    # prepare chart data
    counter = 0
    total_downloads = 0
    chart_data = []

    for item in data["downloads"]:
        chart_data.append((float(counter), item["downloads"]))
        total_downloads += item["downloads"]
        counter += 1

    # check if needs to format downloads
    humanized_downloads = humanize.comma(total_downloads)
    if dot_separator:
        humanized_downloads = humanized_downloads.replace(",", ".")

    return render.Root(
        child = render.Column(
            main_align = "start",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 12,
                            width = 12,
                            child = render.Image(src = NPM_LOGO, height = 10),
                        ),
                        render.Marquee(
                            width = 52,
                            child = render.Text(content = package_name, color = "#f00"),
                        ),
                    ],
                ),
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 12,
                            width = 12,
                            child = render.Image(src = DOWNLOAD_LOGO, height = 12),
                        ),
                        render.Text(humanized_downloads),
                    ],
                ),
                render.Plot(
                    data = chart_data,
                    width = 64,
                    height = 8,
                    color = "#8258f6",
                    color_inverted = "#d96d66",
                    fill = True,
                    fill_color = "#e6defd",
                    fill_color_inverted = "#3e1f1c",
                ),
            ],
        ),
    )

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    download_options = [
        schema.Option(display = "Last day", value = "day"),
        schema.Option(display = "Last week", value = "week"),
        schema.Option(display = "Last month", value = "month"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "package",
                name = "Package name",
                desc = "Name of the NPM package.",
                icon = "cubes",
                handler = search_package,
            ),
            schema.Dropdown(
                id = "download_period",
                name = "Downloads",
                desc = "Download count period.",
                icon = "cloudArrowDown",
                default = DEFAULT_DOWNLOAD_PERIOD,
                options = download_options,
            ),
            schema.Toggle(
                id = "dot",
                name = "Dot separator",
                desc = "Use dots instead of commas.",
                icon = "toggleOn",
                default = DEFAULT_DOT_SEPARATOR,
            ),
        ],
    )

def search_package(name):
    """Searches NPM packages to populate the Typeahead widget.

    Args:
        name (str): The name of the package to search for.

    Returns:
        list of schema.Option: Options to be displayed for the user.
    """

    url = SEARCH_URL % humanize.url_encode(name)
    res = http.get(url, headers = {
        "X-Spiferack": "1",
    })

    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return []

    data = res.json()

    options = []

    if data.get("objects") == None:
        return []

    for object in data["objects"]:
        package_name = object["package"]["name"]
        package_desc = object["package"].get("description", "No description")

        if len(package_desc) > 30:
            package_desc = package_desc[:27] + "..."

        display = "{} ({})".format(package_name, package_desc)

        options.append(
            schema.Option(display = display, value = package_name),
        )

    return options

def render_error(code, message):
    """Creates a widget tree to render an error message.

    Args:
        code (int): The error code.
        message (str): The error message.

    Returns:
        render.Root: The root widget tree to be rendered.
    """

    return render.Root(
        child = render.Column(
            main_align = "start",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 12,
                            width = 12,
                            child = render.Image(src = NPM_LOGO, height = 10),
                        ),
                        render.Text(content = "Error :(", color = "#f00"),
                    ],
                ),
                render.Text(content = "code " + str(code), color = "#ff0"),
                render.Marquee(
                    width = 64,
                    child = render.Text(message),
                ),
            ],
        ),
    )
