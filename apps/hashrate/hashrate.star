"""
Applet: Hashrate
Summary: Bitcoin's hashrate
Description: Plotting the hashrate of Bitcoin.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

URL_HASHRATE = "https://mempool.space/api/v1/mining/hashrate"

def main(config):
    timeperiod = config.str("timeperiod", "3y")
    show_label = config.bool("showlabel", True)

    response_hashrate = http.get(url = "{}/{}".format(URL_HASHRATE, timeperiod), ttl_seconds = 60 * 60 * 12)
    if response_hashrate.status_code != 200:
        fail("Request failed with status %d", response_hashrate.status_code)
    hashrate = response_hashrate.json()

    label = "{}EH/s".format(int(int(hashrate["currentHashrate"]) / 10E17 * 10) / 10) if show_label else ""

    plot = render.Plot(
        data = [(int(h["timestamp"]), int(h["avgHashrate"])) for h in hashrate["hashrates"]],
        width = 64,
        height = 32,
        color = "#0f0",
        fill = True,
    )

    return render.Root(
        max_age = 60 * 60 * 12,
        child = render.Stack(
            children = [
                plot,
                render.Padding(
                    pad = (1, 0, 1, 0),
                    child = render.Text(
                        content = str(label),
                        color = "#fff",
                        font = "tb-8",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Three years to date",
            value = "3y",
        ),
        schema.Option(
            display = "Two years to date",
            value = "2y",
        ),
        schema.Option(
            display = "Year to date",
            value = "1y",
        ),
        schema.Option(
            display = "Half a year to date",
            value = "6m",
        ),
        schema.Option(
            display = "Season to date",
            value = "3m",
        ),
        schema.Option(
            display = "Month to date",
            value = "1m",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "timeperiod",
                name = "Time period",
                desc = "Choose a time period",
                icon = "clock",
                default = options[0].value,
                options = options,
            ),
            schema.Toggle(
                id = "showlabel",
                name = "Show label",
                desc = "Show the label?",
                icon = "tag",
                default = True,
            ),
        ],
    )
