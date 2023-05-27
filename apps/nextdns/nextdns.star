"""
Applet: NextDNS
Summary: NextDNS Account Stats
Description: Displays NextDNS account total query & total blocked query counts + 7-day activity graph.
Author: ndhotsky
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

# Endpoints
BASE_URL = "https://api.nextdns.io"
TIME_SERIES_URL = ";series?"
ANALYTICS_STATUS_ENDPOINT = "/profiles/{}/analytics/status"

# STYLING
GREEN = "#00cc00"
RED = "#ff4136"

def build_get_request(endpoint, api_key, **kwargs):
    """
    Builds the URL and headers component of an HTTP GET request

    Args:
        endpoint: NextDNS endpoint
        api_key: NextDNS account api key
        **kwargs: optionally specify additional arggs to append to the url for time series requests

    Returns:
        URL string and headers dictionary containing NextDNS API key
    """
    suffix = ""

    if kwargs.get("since"):
        suffix = TIME_SERIES_URL + "from={}".format(kwargs["since"])
        if kwargs.get("interval"):
            suffix = suffix + "&interval={}".format(kwargs["interval"])
        if kwargs.get("limit"):
            suffix = suffix + "&limit={}".format(kwargs["limit"])

    url = BASE_URL + endpoint + suffix
    headers = {"X-Api-Key": api_key}

    return url, headers

def query_nextdns(api_key, profile_id, endpoint, **kwargs):
    """
    Queries NextDNS' API with caching enabled

    Args:
        api_key: NextDNS API key
        profile_id: NextDNS profile id
        endpoint: NextDNS API endpoint
        **kwargs: Used to specify NextDNS API url parameters when applicable

    Returns:
        New or cached JSON response from NextDNS
    """
    endpoint = endpoint.format(profile_id)
    url, headers = build_get_request(endpoint, api_key, since = kwargs.get("since", None), interval = kwargs.get("interval", None), limit = kwargs.get("limit", None))

    resp = http.get(url, headers = headers, ttl_seconds = 240)
    if resp.status_code != 200:
        fail("NextDNS %s request failed with status %d", endpoint, resp.status_code)

    return resp.json()

def create_plot(datapoints):
    """
    Generates plot data from supplied datapoints

    Args:
        datapoints: list of floats

    Returns:
        list of tuples (index, datapoint_to_display)
    """
    plot = []
    index = 0

    for query_ct in datapoints:
        plot.append((index, query_ct))
        index += 1

    return plot

def get_secrets(config):
    """
    Loads secrets from configuration entries

    Fatal error is raised if either secret returns a blank value

    Args:
        config: user-defined config values from the Tidbyt interface

    Returns:
        Dictionary containing `profile_id` and `api_key` secrets
    """
    profile_id = config.get("profile_id").strip()
    api_key = config.get("api_key").strip()

    if profile_id == "" or api_key == "":
        fail("Missing NextDNS profile id or api key value: please restart app with both values supplied")

    return {
        "profile_id": profile_id,
        "api_key": api_key,
    }

def main(config):
    """
    Queries the analytics status NextDNS for total queries and total blocked, and plots the last 7 days of activity

    Args:
        config: user-defined config values from the Tidbyt interface

    Returns:
        Rendered pixlet
    """
    secrets = get_secrets(config)

    # get stats
    analytics = query_nextdns(secrets["api_key"], secrets["profile_id"], ANALYTICS_STATUS_ENDPOINT)
    total_queries = humanize.float("#,###.", math.round(analytics["data"][0]["queries"]))
    total_blocked = humanize.float("#,###.", math.round(analytics["data"][1]["queries"]))

    # get plots
    graph = query_nextdns(secrets["api_key"], secrets["profile_id"], ANALYTICS_STATUS_ENDPOINT, since = "-7d", interval = "10800", limit = 7)
    total_queries_plot = create_plot(graph["data"][0]["queries"])
    blocked_queries_plot = create_plot(graph["data"][1]["queries"])

    return render.Root(
        render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Padding(
                    pad = (2, 1, 1, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Column(
                                children = [
                                    render.Text("NEXT", font = "5x8"),
                                    render.Row(
                                        children = [
                                            render.Text("DNS", font = "5x8"),
                                            render.Image(NEXTDNS_LOGO, width = 7),
                                        ],
                                    ),
                                ],
                            ),
                            render.Column(
                                cross_align = "end",
                                children = [
                                    render.Text(str(total_queries)),
                                    render.Text(str(total_blocked), color = RED),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Row(
                    expanded = True,
                    children = [
                        render.Stack(
                            children = [
                                render.Plot(
                                    data = total_queries_plot[1:],
                                    width = 64,
                                    height = 14,
                                    color = GREEN,
                                    fill = True,
                                    y_lim = (0, max(graph["data"][0]["queries"])),
                                ),
                                render.Plot(
                                    data = blocked_queries_plot[1:],
                                    width = 64,
                                    height = 14,
                                    color = RED,
                                    fill = True,
                                    fill_color = "#660500",
                                    y_lim = (0, max(graph["data"][1]["queries"]) * 3),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "profile_id",
                name = "Profile ID",
                desc = "NextDNS profile ID value",
                icon = "user",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "NextDNS API key value",
                icon = "key",
            ),
        ],
    )

# Assets
NEXTDNS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAHIAAACFCAYAAACHSqzcAAAAAXNSR0IArs4c6QAAAFBlWElmTU0AKgAAAAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAA
ABAAAAcqADAAQAAAABAAAAhQAAAACYtzBFAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4w
LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogIC
AgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRm
OkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgoZXuEHAAAWZElEQVR4Ae1dfdAdZ1U/mzdvEgIptDSILQMyCFW+/pCZwlg+FBVGhRmRqTOtiqHUBgZaO6UmgyMYBG1Nh1oLWC
lIA0mTEApKiyI6UGxhhIozWOyAFFAhDR9tbGklpcmbu57f7nvunj13n2fPs7v3vvfN9Jm5756P3/md8zzn3b179+69N6MTcey4eQMtnPQrlI1eSnn2kzzFRX58i0bZp2hx6Ub6g+cePtGmnZ1oE6I9
+bk8p7fz48mUN8wup/9l65X0IO2krdmxBsSqNJ04jXxPvkgb6V2U0fncwDUT3Zhs6s2MO5t+Jzsh9s4To5F/nW+i9bSPG/OrjgaS2lPvoBG9jF6d/fdE3CozrP5GXpc/hhbok7wnnllb+8k9UDewgu
Z0Fzf2F7mZX62Mq0+aPAStpjkcyB/NpzH7a01EA20T47bT+UD8t/S+HCdFq3as3kbuyp9BD9Et3LSXFqsfb1bVIIuDPqIzeK/+LH0g/+UKuLqk1XdovS7nlxa0hffCnbzUmyb2Pqw/mqOH1eGztlJf
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
""")
