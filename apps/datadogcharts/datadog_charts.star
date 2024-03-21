"""
Applet: DataDog Charts
Summary: View your DataDog Dashboard Charts
Description: By default, displays the first chart on your DataDog dashboard.
Author: Gabe Ochoa
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Set your DataDog API and App keys here for development
DEFAULT_APP_KEY = None
DEFAULT_API_KEY = None
DEFAULT_DASHBOARD_ID = ""

DATADOG_ICON = base64.decode("""
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPCEtLSBHZW5lcmF0b3I6IEFkb2JlIElsbHVzdHJhdG9yIDIzLjAuNCwgU1ZHIEV4cG9ydCBQbHVnLUluIC4gU1ZHIFZlcnNpb246IDYuMDAgQnVpbGQgMCkgIC0tPgo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IgoJIHZpZXdCb3g9IjAgMCA4MDAuNSA5MDcuNzciIHN0eWxlPSJlbmFibGUtYmFja2dyb3VuZDpuZXcgMCAwIDgwMC41IDkwNy43NzsiIHhtbDpzcGFjZT0icHJlc2VydmUiPgo8c3R5bGUgdHlwZT0idGV4dC9jc3MiPgoJLnN0MHtmaWxsOiNGRkZGRkY7fQo8L3N0eWxlPgo8cGF0aCBjbGFzcz0ic3QwIiBkPSJNMzAzLjM2LDIzOC42MWMzMS4zNi0yMS4zNyw3MS43Ni0xMi45Nyw2NS02LjUzYy0xMi44OSwxMi4yOCw0LjI2LDguNjUsNi4xMSwzMS4zMQoJYzEuMzYsMTYuNjktNC4wOSwyNS44OC04Ljc4LDMxLjExYy05Ljc5LDEuMjgtMjEuNjksMy42Ny0zNi4wMiw4LjMzYy04LjQ4LDIuNzYtMTUuODUsNS44Mi0yMi4zMSw4LjkKCWMtMS43LTEuMTEtMy41NS0yLjQ3LTUuNzQtNC4zNkMyNzkuNSwyODguMTksMjgwLjI0LDI1NC4zNywzMDMuMzYsMjM4LjYxIE00OTAuNjgsMzcwLjcyYzUuNjktNC40MSwzMS41NS0xMi43Miw1NS40OS0xNS41NQoJYzEyLjU3LTEuNDgsMzAuNDktMi4zNCwzNC4zMS0wLjJjNy41OSw0LjE5LDcuNTksMTcuMTYsMi4zOSwyOS4xNGMtNy41NywxNy40LTE4LjI3LDM2LjYzLTMwLjM5LDM4LjIxCgljLTE5Ljc3LDIuNjEtMzguNDYtOC4wOS01OS44LTI0LjAzQzQ4NS4wNiwzOTIuNTYsNDgwLjM4LDM3OC42OCw0OTAuNjgsMzcwLjcyIE01MjYuNzUsMjAxLjI3YzI5LjE5LDEzLjU4LDI1LjM3LDM5LjQyLDI2LjE4LDU0LjYKCWMwLjIyLDQuMzYsMC4xNSw3LjMtMC4yMiw5LjMyYy00LjA0LTIuMTktMTAuNDMtMy44LTIwLjU2LTMuMzVjLTIuOTYsMC4xMi01Ljg0LDAuNDctOC42MywwLjkxYy0xMC43Ny01Ljc3LTE3LjIxLTE3LjA2LTIzLjEtMjkuMDYKCWMtMC41NC0xLjExLTAuOTYtMi4xLTEuMzYtMy4wNmMtMC4xNy0wLjQ0LTAuMzUtMC45MS0wLjUyLTEuMzFjLTAuMDctMC4yMi0wLjEyLTAuMzktMC4yLTAuNTljLTMuMjMtMTAuMjUtMS4wNi0xMi4zLDAuMy0xNS40NgoJYzEuNDEtMy4yMyw2LjY4LTUuODktMS4xMS04LjU4Yy0wLjY3LTAuMjUtMS41LTAuMzktMi40NC0wLjU3QzUwMC4yNSwxOTcuNzIsNTE1LjcsMTk2LjE3LDUyNi43NSwyMDEuMjcgTTM2Ny42Miw1MTAuMjIKCWMtMzEuNDUtMjAuMTktNjMuOTktNDkuMTUtNzguMjItNjUuMThjLTIuMzktMS44LTItOS43OS0yLTkuNzljMTIuODQsOS45OCw2Ni4xMSw0OC4wNCwxMjIuNDQsNjUuNDIKCWMxOS44Nyw2LjE0LDUwLjM2LDguNDYsNzYuODEtNi41M2MyMC4yMS0xMS40Niw0NC41NC0zMS40Myw1OS4wNi01Mi4wMWwyLjY2LDQuNjFjLTAuMSwzLjA2LTYuNzgsMTcuOTctMTAuMTgsMjMuOTYKCWM2LjE0LDMuNTMsMTAuNzIsNC40OSwxNy41NSw2LjM2bDQ2LjY0LTcuMjdjMTYuNzQtMjcuMDQsMjguNzQtNzAuNjUsMTUuOTUtMTEyLjE2Yy03LjMtMjMuODEtNDUuMzYtNzEuMjItNDguMDktNzMuODMKCWMtOS41Ni05LjE5LDEuNi00NC42OS0xNy4zNS04My40MkM1MzIuODYsMTU5LjQxLDQ4MC42NywxMTYuNjksNDU4LDk4LjFjNi42OCw0Ljg4LDQ3LjgyLDIxLjQ3LDY3LDQ0LjYyCgljMS44LTIuMzksMi41NC0xNC44Miw0LjE5LTE3Ljk3Yy0xNi40Ny0yMS41Ny0xNy43NS01OS45NS0xNy43NS03MC4yMWMwLTE4LjgxLTkuNTYtNDAuMTMtOS41Ni00MC4xM3MxNi40NywxMy4wNCwyMC43MywzNS41CgljNS4wMywyNi42LDE1Ljc1LDQ3LjU1LDI5LjkzLDY1LjI4YzI2Ljg0LDMzLjQzLDUxLjA4LDUwLjU4LDYzLjMzLDM4LjIzQzYzMC41MywxMzguNTgsNjAxLDcyLjIsNTYzLjI4LDM1LjE1CglDNTE5LjI1LTguMDksNTA3Ljc0LTIuNTIsNDgxLjkxLDYuN2MtMjAuNjEsNy4zNS0zMS43NSw2NS44Ny04NS40Nyw2NC43MWMtOS4xLTEuMDYtMzIuNTQtMS42My00NC4xMy0xLjUzCgljNi4wNC04LjQzLDExLjIyLTE0Ljk0LDExLjIyLTE0Ljk0cy0xOC4wMiw3LjI1LTMzLjM4LDE2LjQ0bC0xLjE4LTEuNzdjNS4xOC0xMC45MiwxMC43NS0xNy44MiwxMC43NS0xNy44MnMtMTQuNCw4LjY1LTI3LjU0LDE5LjAxCgljMi4zOS0xMy4wMiwxMS40NC0yMS4yNywxMS40NC0yMS4yN3MtMTguMTksMy4yOC00MS4zNiwyOC43N2MtMjYuMzMsNy4yLTMyLjY2LDExLjkzLTUzLjY0LDIxLjIyCgljLTM0LjEyLTcuNDQtNTAuMjEtMTkuNDUtNjUuNTUtNDEuNTZjLTExLjY4LTE2Ljg5LTMyLjQ3LTE5LjQ1LTUzLjcxLTEwLjcyYy0zMC45NywxMi44LTcwLjE0LDMwLjMzLTcwLjE0LDMwLjMzCglzMTIuNzctMC41MiwyNi4wOCwwLjA1Yy0xOC4yMiw2LjktMzUuNzIsMTYuMzktMzUuNzIsMTYuMzlzOC41My0wLjMsMTkuMDYtMC4xMmMtNy4yNyw2LjA0LTExLjI5LDguOTItMTguMjIsMTMuNTEKCWMtMTYuNjYsMTIuMS0zMC4xNywyNi4wOC0zMC4xNywyNi4wOHMxMS4zMS01LjE1LDIxLjQ3LTguMDRjLTcuMSwxNi4yNy0yMS4xOCwyOC4yNS0xOC41OSw0OC4xNwoJYzIuNDksMTguMTksMjQuODIsNTUuNjYsNTMuNjQsNzguNjZjMi40OSwyLDQxLjg2LDM4LjQzLDcxLjU2LDIzLjQ3YzI5LjY4LTE0Ljk0LDQxLjM5LTI4LjI1LDQ2LjI3LTQ4LjY2CgljNS43NC0yMy40NCwyLjQ3LTQxLjE3LTkuNzktOTIuMDVjLTQuMDQtMTYuNzktMTQuNTctNTEuMzctMTkuNjUtNjcuOTFsMS4xMy0wLjgxYzkuNzEsMjAuNDksMzQuNTYsNzQuNSw0NC41NywxMTAuNzgKCWMxNS42Myw1Ni41NywxMC43NSw4NS4yNywzLjYsOTUuNzljLTIxLjU3LDMxLjczLTc2Ljg0LDM1LjkyLTEwMS45OCwxOC4zNGMtMy44NSw2MC45MSw5Ljc2LDg3LjczLDE0LjM3LDEwMS4yNAoJYy0yLjI5LDE1LjUzLDcuNzcsNDQuMzcsNy43Nyw0NC4zN3MxLjEzLTEzLjExLDUuNzQtMjAuMDJjMS4yMywxNS40MSw5LDMzLjcyLDksMzMuNzJzLTAuNDctMTEuMzEsMy4wNi0yMS4wOAoJYzQuOTgsOC40Myw4LjYzLDEwLjQzLDEzLjM0LDE2Ljc2YzQuNzEsMTYuNDcsMTQuMTUsMjguNSwxNC4xNSwyOC41cy0xLjUzLTguODMtMC42OS0xOC4wMmMyMy4wNSwyMi4xNCwyNy4wMiw1NC40NSwyOS4zMSw3OS4yOAoJYzYuNDYsNjguMjYtMTA3LjYzLDEyMi41NC0xMjkuNzQsMTY1LjI0Yy0xNi43NiwyNS4yOS0yNi44LDY1LjMsMS41OCw4OC44OWM2OC42LDU2Ljk3LDQyLjI1LDcyLjY1LDc2LjU5LDk3LjY5CgljNDcuMTEsMzQuMzQsMTA2LjA1LDE4Ljk2LDEyNi4xMS04Ljk3YzI3LjkzLTM4LjkyLDIwLjc2LTc1LjYzLDEwLjM4LTEwOS45N2MtOC4xMS0yNi44NS0zMC4xNS03MS40Ni01Ny40MS04OC43MgoJYy0yNy44Ni0xNy42NS01NC45NS0yMC45NS03Ny45LTE4LjU5bDIuMTItMi40NGMzMy4wMS02LjU2LDY3LjUyLTIuOTYsOTIuNDksMTMuMTRjMjguMzUsMTguMjIsNTQuMjgsNDkuNDcsNjcuODQsOTcuMzcKCWMxNS4zOC0yLjE5LDE3LjU1LTMuMTgsMzEuNjMtNS4xOGwtMzEuNy0yNDYuNzZMMzY3LjYyLDUxMC4yMnogTTM4NS45NCw4MTkuNTJsLTMuNjUtMzQuMjJsNzEuMjktMTA4Ljc0bDgwLjkzLDIzLjY0bDY5LjU5LTExNi4yMwoJTDY4Ny41Miw2MzlsNjMuMzgtMTMyLjkybDIyLjUzLDI0Mi4wN0wzODUuOTQsODE5LjUyeiBNNzc0LjI3LDQ1Ni41MWwtMjU0LjcyLDQ2LjE3Yy02LjMxLDguMTMtMjEuOTEsMjIuNDEtMjkuNDEsMjYuMTMKCWMtMzIuMTcsMTYuMi01My45MSwxMS41MS03Mi43LDYuNjNjLTEyLjA4LTMuMDYtMTkuMDgtNC43OC0yOS4xMS05LjI5bC02Mi4xNyw4LjUzbDM3Ljc0LDMxNC44N2w0MzYuMzUtNzguNjZMNzc0LjI3LDQ1Ni41MXoiLz4KPC9zdmc+Cg==
""")

def main(config):
    # Setup and validate config
    DD_SITE = config.get("site") or "datadoghq.com"
    DD_API_URL = "https://api.{}/api/v1".format(DD_SITE)
    DD_API_KEY = config.get("api_key") or DEFAULT_API_KEY
    DD_APP_KEY = config.get("app_key") or DEFAULT_APP_KEY
    DASHBOARD_ID = config.get("dashboard_id") or DEFAULT_DASHBOARD_ID
    SHOW_LAST_VALUE = config.bool("show_last_value", True)
    CHART_TIME_RANGE = config.get("chart_time_range") or "1h"
    CHART_NAME = config.get("chart_name")

    ## APIs
    DD_DASHBOARD_API = "{}/dashboard".format(DD_API_URL)
    DD_METRICS_QUERY_API = "{}/query".format(DD_API_URL)

    if DD_API_KEY == None or DD_APP_KEY == None:
        return renderer("Set Datadog API and APP Key", fake_chart_data())

    dashboard_json = http.get(
        "{}/{}".format(DD_DASHBOARD_API, DASHBOARD_ID),
        headers = {"DD-API-KEY": DD_API_KEY, "DD-APPLICATION-KEY": DD_APP_KEY, "Accept": "application/json"},
        ttl_seconds = 6000,
    ).json()

    if dashboard_json.get("errors") != None:
        child = render.Row(
            cross_align = "center",
            main_align = "center",
            children = [
                render.WrappedText(content = dashboard_json.get("errors")[0]),
            ],
        )
        return render.Root(child = child)

    # Select the wideget to display from the chart name
    widget = None
    for w in dashboard_json.get("widgets"):
        if w.get("definition").get("title") == CHART_NAME:
            widget = w
            break

    # If no chart name was provided, use the first widget
    if widget == None:
        widget = dashboard_json.get("widgets")[0]

    # check if the widget is a timeseries and if not, show an error
    if widget.get("definition").get("type") != "timeseries":
        child = render.Row(
            cross_align = "center",
            main_align = "center",
            children = [
                render.WrappedText(content = "First widget on dashboard is not a timeseries."),
            ],
        )
        return render.Root(child = child)

    # get the panel options
    title = widget.get("definition").get("title")
    query = widget.get("definition").get("requests")[0].get("queries")[0].get("query")

    # Query metrics API to get the list of points to plot

    # Compute the time range for the chart
    chart_time_range_seconds = time.parse_duration(CHART_TIME_RANGE).seconds
    to_time = time.now().unix
    from_time = to_time - chart_time_range_seconds

    print("Making query to DataDog API: ", query, str(from_time), str(to_time))
    query_response = http.get(
        DD_METRICS_QUERY_API,
        params = {"from": str(from_time), "to": str(to_time), "query": query},
        headers = {"DD-API-KEY": DD_API_KEY, "DD-APPLICATION-KEY": DD_APP_KEY, "Accept": "application/json"},
        ttl_seconds = 600,
    ).json()

    # Check if we got data, if not, show an error
    if len(query_response.get("series")) == 0:
        print("No data returned from query.")
        print(query_response)
        child = render.Row(
            cross_align = "center",
            main_align = "center",
            children = [
                render.WrappedText(content = "No data returned from query."),
            ],
        )
        return render.Root(child = child)
    elif query_response == None:
        # The Datadog API sometimes returns > 50MB of data which causes a context deadline exceeded error
        print("Error fetching data. Possibly too large of a response.")
        print(query_response)
        child = render.Marquee(
            width = 48,
            child = render.Text(content = "Error fetching data. Possibly too large of a response.", font = "6x13", color = "#fff"),
        )
        return render.Root(child = child)

    # Get the data from the response
    raw_points = query_response.get("series")[0].get("pointlist")

    # Convert datapoints into List[Tuple[float, float]]
    datapoints = []
    for point in raw_points:
        datapoints.append((point[0], point[1]))

    # Add the last value to the title
    if SHOW_LAST_VALUE:
        # convert scientific notation to decimal
        datapoint = "{}".format(datapoints[-1][1]).split(".")[0]
        title = "Last value: {}".format(datapoint)

    return renderer(title, datapoints)

def renderer(display_name, datapoints):
    logo = render.Image(src = DATADOG_ICON, width = 16, height = 16)
    text = render.Marquee(
        width = 48,
        child = render.Text(content = display_name, font = "6x13", color = "#fff"),
    )
    plot_row = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "end",
        children = [
            render.Plot(
                data = datapoints,
                fill = True,
                width = 60,
                height = 24,
                color = "#0f0",
                color_inverted = "#f00",
            ),
        ],
    )

    empty_row = render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = [],
    )

    top_row_columns_left = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [logo],
    )
    top_row_columns_right = render.Column(
        expanded = True,
        cross_align = "center",
        children = [text],
    )

    top_row = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [top_row_columns_left, top_row_columns_right],
    )
    bottom_row = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [empty_row, plot_row],
    )

    root = render.Stack(
        children = [bottom_row, top_row],
    )

    return render.Root(child = root)

def get_schema():
    dd_site_options = [
        schema.Option(
            display = "US1",
            value = "datadoghq.com",
        ),
        schema.Option(
            display = "US3",
            value = "us3.datadoghq.com",
        ),
        schema.Option(
            display = "US5",
            value = "us5.datadoghq.com",
        ),
        schema.Option(
            display = "EU",
            value = "datadoghq.eu",
        ),
        schema.Option(
            display = "Gov",
            value = "ddog-gov.com",
        ),
        schema.Option(
            display = "Japan",
            value = "ap1.datadoghq.com",
        ),
    ]

    chat_time_range_options = [
        schema.Option(
            display = "1 Hour",
            value = "1h",
        ),
        schema.Option(
            display = "4 Hours",
            value = "4h",
        ),
        schema.Option(
            display = "1 Day",
            value = "24h",
        ),
        schema.Option(
            display = "1 Week",
            value = "168h",
        ),
        schema.Option(
            display = "1 Month",
            value = "5040h",
        ),
        schema.Option(
            display = "3 Month",
            value = "15120h",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            # Datadog Site Options
            # https://docs.datadoghq.com/getting_started/site/
            schema.Dropdown(
                id = "dd_site",
                name = "Datadog Site",
                desc = "Datadog Site",
                icon = "globe",
                default = dd_site_options[0].value,
                options = dd_site_options,
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "DataDog API Key",
                icon = "key",
            ),
            schema.Text(
                id = "app_key",
                name = "App Key",
                desc = "DataDog App Key",
                icon = "key",
            ),
            schema.Text(
                id = "dashboard_id",
                name = "Dashboard ID",
                desc = "DataDog Dashboard ID",
                icon = "key",
            ),
            schema.Text(
                id = "chart_name",
                name = "Chart Name",
                desc = "Name of the chart. If not provided or not found, the first chart on the dashboard will be used.",
                icon = "chartLine",
            ),
            schema.Dropdown(
                id = "chart_time_range",
                name = "Chart Time Range",
                desc = "The time range to query for the chart",
                icon = "clock",
                default = chat_time_range_options[0].value,
                options = chat_time_range_options,
            ),
            schema.Toggle(
                id = "show_last_value",
                name = "Show Chart Last Value or Name",
                desc = "Toggle showing the chart last value or name in the scrolling text",
                icon = "dashcube",
                default = True,
            ),
        ],
    )

def fake_chart_data():
    return [(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8)]
