"""
Applet: MoreTransit
Summary: See next transit arrivals
Description: See next transit arrivals from TransSee. Optimized for NYC Subway and more customizable than the default apps.
Author: gdcolella
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

MAX_SUBWAYS = 4
MIN_MINUTES = 10

SAMPLE_TITLE = "Manhattan"

# Takes the format arguments:
# TransSee Premium ID
# TransSee Service
# StopTag
# Route
BASE_URL = "http://transsee.ca/publicJSONFeed?command=predictions&premium={}&a={}&s={}&r={}"

# If no configuration is provided, then default to using some subways
# near DUMBO, Brooklyn.
sample_config_line1 = "mtasubway:A:A40N,mtasubway:C:A40N"
sample_config_line2 = "mtasubway:F:F18N"

# The real API has a lot more response data - this is only
# the fields that we actually read.
# This data is used if we don't have a premium TransSee key
# configured.
sample_response_data = {
    "A:A40N": {
        "predictions": [
            {"color": "0039a6", "stopTitle": "High St", "direction": [{"prediction": [{"minutes": "10"}, {"minutes": "12"}, {"minutes": "16"}]}]},
        ],
    },
    "C:A40N": {
        "predictions": [
            {"color": "0039a6", "stopTitle": "High St", "direction": [{"prediction": [{"minutes": "13"}, {"minutes": "15"}, {"minutes": "17"}]}]},
        ],
    },
    "F:F18N": {
        "predictions": [
            {"color": "ff6319", "stopTitle": "York St", "direction": [{"prediction": [{"minutes": "13"}, {"minutes": "15"}, {"minutes": "17"}]}]},
        ],
    },
}

def fetch_data(config):
    arrival_times = []

    raw_station = config.get("station1") or sample_config_line1
    parsed = [s.split(":") for s in raw_station.split(",")]
    stations = [parsed]

    if not config.bool("disableStation2"):
        raw_station2 = config.get("station2") or sample_config_line2
        stations.append([s.split(":") for s in raw_station2.split(",")])

    for combined_station in stations:
        station_name = None
        station_arrivals = []
        for service, route, station_code in combined_station:
            premiumKey = config.str("premium")
            data = None

            if premiumKey == None:
                data = sample_response_data[route + ":" + station_code]
            else:
                fetched = http.get(BASE_URL.format(premiumKey, service, station_code, route))
                if fetched.status_code != 200:
                    fail("Failed to get arrival data %d" % fetched.status_code)
                data = fetched.json()

            # This can happen if there are no scheduled trains.
            if "direction" not in data["predictions"][0]:
                continue

            color = "#" + data["predictions"][0]["color"]
            station_name = data["predictions"][0]["stopTitle"]
            station_arrivals.append((route, color, [int(p["minutes"]) for p in data["predictions"][0]["direction"][0]["prediction"]]))
        arrival_times.append((station_name, station_arrivals))
    return arrival_times

# Stacked renderer
def stack_subway(letter, color, arrival):
    return render.Padding(
        render.Column(children = [
            render.Circle(color, 8, render.Text(letter, "tb-8")),
            render.Text(str(arrival), "tom-thumb"),
        ], cross_align = "end"),
        1,
        False,
    )

# Overlaid renderer, less readable but prettier
def overlay_subway(letter, color, arrival):
    return render.Padding(
        render.Stack(children = [
            render.Circle(color, 8, render.Text(letter, "tb-8")),
            render.Padding(render.Text(str(arrival), font = "tom-thumb", color = "#bbbbbb"), (4, 5, 0, 0), False),
        ]),
        1,
        False,
    )

def main(config):
    arrival_data = fetch_data(config)

    stop_arrivals = []
    for stop, lines in arrival_data:
        renderable_subways = []
        all_arrivals_to_stop = []

        # Take the format
        #   (line name, color, [eta1, eta2, eta3])
        # to the format
        #   [(line name, color, eta1), (line name, color, eta2) ... ]
        #
        # This will make it easier to sort and interleave arrivals between lines.
        for (name, color, arrivals) in lines:
            all_arrivals_to_stop.extend([
                (eta, color, name)
                for eta in arrivals
            ])

        # Now we have all arrivals to this logical stop with the arrival time
        # as the first tuple element. So sorted() will sort by arrival time.
        all_arrivals_to_stop = sorted(all_arrivals_to_stop, key = lambda x: x[0])

        for (eta, color, name) in all_arrivals_to_stop:
            if eta > MIN_MINUTES and len(renderable_subways) < MAX_SUBWAYS:
                renderer = overlay_subway
                if config.bool("useStacked"):
                    renderer = stack_subway
                renderable_subways.append(renderer(name, color, eta))
        stop_arrivals.append((stop, renderable_subways))

    root_cols = []
    for stop, renderable_subways in stop_arrivals:
        root_cols.append(
            render.Row(
                children = [
                    # Marquee the name of the stop.
                    render.Marquee(render.Text(stop), width = 20),
                    # Then add a row of all the arrivals coming in.
                    render.Row(renderable_subways),
                ],
                main_align = "space_between",
                cross_align = "center",
            ),
        )

    title = config.str("title") or SAMPLE_TITLE
    root_cols.append(render.Row(children = [render.Text("    " + title, font = "tom-thumb")], main_align = "center"))
    return render.Root(render.Column(root_cols))

def getSchema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "premium",
                name = "TransSee Premium ID",
                desc = "ID for TransSee Premium. Used to call their API on your behalf.",
                icon = "user",
            ),
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Title for this page, displayed at the bottom. Good to diffentiate multiple instances of the app.",
                icon = "book",
            ),
            schema.Text(
                id = "station1",
                name = "Station1 Config",
                desc = "Config for the first station. Format: `service:line:stop,service2:line2:stop2`, etc. For example: `mtasubway:A:A40N,mtasubway:C:A40N` would combine arrivals to stop A40N (High St) for both the A and C lines into one line on the Tidbyt. Stop IDs can be found in TransSee.",
                icon = "gear",
            ),
            schema.Text(
                id = "station2",
                name = "Station2 Config",
                desc = "Config for the second station. Format: `service:line:stop,service2:line2:stop2`, etc. For example,  `mtasubway:A:A40N,mtasubway:C:A40N` would combine arrivals to stop A40N (High St) for both the A and C lines into one line on the Tidbyt.",
                icon = "gear",
            ),
            schema.Text(
                id = "minTime",
                name = "Minimum ETA",
                desc = "Omit vehicles closer than this ETA (in minutes), if that would make you sad that you couldn't walk to the station in time.",
                default = "9",
            ),
            schema.Toggle(
                id = "disableStation2",
                name = "Disable second station",
                default = False,
                desc = "Disable the second station, only show one line.",
            ),
            schema.Toggle(
                id = "useStacked",
                name = "Stack Times",
                default = False,
                desc = "Stack the arrival times under the line instead of overlaying them",
            ),
        ],
    )
