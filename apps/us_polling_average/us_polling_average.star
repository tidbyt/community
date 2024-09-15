"""
Applet: US PollingAverage
Summary: Election polls from 538
Description: Shows current polling averages from FiveThirtyEight
Author: jwoglom
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

JSON_URL_TEMPLATE = "https://projects.fivethirtyeight.com/polls/{poll_type}/{poll_cycle}/{poll_state}/{file_name}.json"

POLL_TYPES = [
    "president-general",
]

POLL_STATES = [
    "national",
    "alabama",
    "alaska",
    "american-samoa",
    "arizona",
    "arkansas",
    "california",
    "colorado",
    "connecticut",
    "delaware",
    "district-of-columbia",
    "florida",
    "georgia",
    "guam",
    "hawaii",
    "idaho",
    "illinois",
    "indiana",
    "iowa",
    "kansas",
    "kentucky",
    "louisiana",
    "maine",
    "maryland",
    "massachusetts",
    "michigan",
    "minnesota",
    "mississippi",
    "missouri",
    "montana",
    "nebraska",
    "nevada",
    "new-hampshire",
    "new-jersey",
    "new-mexico",
    "new-york",
    "north-carolina",
    "north-dakota",
    "northern-mariana-islands",
    "ohio",
    "oklahoma",
    "oregon",
    "pennsylvania",
    "puerto-rico",
    "rhode-island",
    "south-carolina",
    "south-dakota",
    "tennessee",
    "texas",
    "us-virgin-islands",
    "utah",
    "vermont",
    "virginia",
    "washington",
    "west-virginia",
    "wisconsin",
    "wyoming",
]

POLL_CYCLES = [
    "2024",
]

FONT = "tom-thumb"

PERIOD = "period"
DEFAULT_PERIOD = "30"

POLL_TYPE = "poll_type"
DEFAULT_POLL_TYPE = "president-general"

POLL_STATE = "poll_state"
DEFAULT_POLL_STATE = "national"

POLL_CYCLE = "poll_cycle"
DEFAULT_POLL_CYCLE = "2024"

PARTY_COLORS = {
    "REP": "#eb4034",
    "DEM": "#1018eb",
    "OTHER": "#e7eb10",
}

def main(config):
    period = config.get(PERIOD, DEFAULT_PERIOD)
    poll_type = config.get(POLL_TYPE, DEFAULT_POLL_TYPE)
    poll_state = config.get(POLL_STATE, DEFAULT_POLL_STATE)
    poll_cycle = config.get(POLL_CYCLE, DEFAULT_POLL_CYCLE)

    url = JSON_URL_TEMPLATE.format(
        poll_type = poll_type,
        poll_state = poll_state,
        poll_cycle = poll_cycle,
        file_name = "polling-average",
    )

    results = http.get(url, ttl_seconds = 3600)
    if results.status_code != 200:
        return render.Root(
            child = render.WrappedText("Error loading " + poll_type + " " + poll_state + " " + poll_cycle),
        )

    data = postprocess(results.json())
    results_summary = make_results_summary(data)

    return render.Root(
        child = render.Stack(
            children = [
                draw_chart(data, int(period)),
                draw_title(poll_type, poll_state, poll_cycle, results_summary),
            ],
        ),
    )

def postprocess(results):
    candidates = {}
    for result in results:
        if result["candidate"] == "Kennedy":
            continue
        if not result["candidate"] in candidates.keys():
            candidates[result["candidate"]] = []
        final_result = result
        final_result["date_parsed"] = time.parse_time(result["date"], "2006-01-02")
        candidates[result["candidate"]].append(final_result)

    return candidates

def make_results_summary(data):
    results = []
    for candidate in data.keys():
        last = data[candidate][0]
        results.append([
            last["pct_estimate"],
            last["candidate"],
            PARTY_COLORS.get(last["party"], "OTHER"),
        ])

    results = sorted(results, reverse = True)

    return render.Row(
        children = [
            render.Text(
                content = "%s" % (math.round(10 * row[0]) / 10) + "%  ",
                font = FONT,
                color = row[2],
            )
            for row in results
        ],
    )

def draw_chart(data, days):
    return render.Stack(
        children = [
            draw_series(data[candidate], data[candidate][0]["party"], days)
            for candidate in data.keys()
        ],
    )

# Plot the polling average for a given party over the given time period
def draw_series(data, party, days):
    now = time.now()
    today = time.time(year = now.year, month = now.month, day = now.day)
    series = sorted([((row["date_parsed"] - today) // (24 * time.hour), row) for row in data if row], reverse = True)

    newest_day = series[0][0]
    oldest_day = max(series[-1][0], -days)
    days = newest_day - oldest_day
    days_per_pixel = max(1, days // 32)
    newest = newest_day // days_per_pixel
    oldest = oldest_day // days_per_pixel

    polls_by_pixel = {}
    for day, poll in series:
        pixel = day // days_per_pixel
        if pixel in polls_by_pixel:
            polls_by_pixel[pixel].append(poll["pct_estimate"])
            continue
        polls_by_pixel[pixel] = [poll["pct_estimate"]]
    averages = [(pixel, sum(polls) / len(polls)) for pixel, polls in polls_by_pixel.items()]

    return render.Plot(
        data = averages,
        chart_type = "line",
        width = 64,
        height = 32,
        x_lim = (oldest, newest),
        y_lim = (40, 55),
        color = PARTY_COLORS.get(party, PARTY_COLORS["OTHER"]),
    )

def pretty_fmt(txt):
    p = " ".join([i[0].upper() + i[1:] for i in txt.split("-")])
    p = p.replace(" General", "")
    return p

def draw_title(poll_type, poll_state, poll_cycle, results_summary):
    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Marquee(
            width = 64,
            child = render.Row(
                children = [
                    render.Text(
                        content = "{poll_cycle} {poll_type} ({poll_state}): ".format(
                            poll_cycle = poll_cycle,
                            poll_type = pretty_fmt(poll_type),
                            poll_state = pretty_fmt(poll_state),
                            results_summary = results_summary,
                        ),
                        font = FONT,
                    ),
                    results_summary,
                ] * 3,
            ),
            offset_start = 8,
        ),
    )

def sum(list):
    total = 0
    for item in list:
        total += item
    return total

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = PERIOD,
                name = "Period",
                desc = "Show polls from the most recent",
                icon = "calendar",
                default = "30",
                options = [
                    schema.Option(
                        display = "One week",
                        value = "7",
                    ),
                    schema.Option(
                        display = "Two weeks",
                        value = "14",
                    ),
                    schema.Option(
                        display = "30 days",
                        value = "30",
                    ),
                    schema.Option(
                        display = "90 days",
                        value = "90",
                    ),
                    schema.Option(
                        display = "180 days",
                        value = "180",
                    ),
                ],
            ),
            schema.Dropdown(
                id = POLL_TYPE,
                name = "Poll Type",
                desc = "Type for which polls are shown",
                icon = "pencil",
                default = DEFAULT_POLL_TYPE,
                options = [
                    schema.Option(
                        display = pretty_fmt(item),
                        value = item,
                    )
                    for item in POLL_TYPES
                ],
            ),
            schema.Dropdown(
                id = POLL_STATE,
                name = "Poll State",
                desc = "State for which polls are shown",
                icon = "flagUsa",
                default = DEFAULT_POLL_STATE,
                options = [
                    schema.Option(
                        display = pretty_fmt(item),
                        value = item,
                    )
                    for item in POLL_STATES
                ],
            ),
            schema.Dropdown(
                id = POLL_CYCLE,
                name = "Poll Cycle",
                desc = "Election cycle",
                icon = "calendarDays",
                default = DEFAULT_POLL_CYCLE,
                options = [
                    schema.Option(
                        display = item,
                        value = item,
                    )
                    for item in POLL_CYCLES
                ],
            ),
        ],
    )
