"""
Applet: SF Bart Muni
Summary: Show Muni & Bart Estimates
Description: Shows the predicted arrival times for both Muni and Bart at the same time.
Author: Chris Hasson
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# Global config

CACHE_TTL = 60
MAX_AGE_SECS = 90

# Defaults and API keys

DEFAULT_BART_STOP_ID = "16th"
BART_PUBLIC_API_KEY = "MW9S-E7SL-26DU-VV8V"

DEFAULT_MUNI_STOP_ID = "15726"
MUNI_API_KEY_NAME = "muni_api_key"
MUNI_API_KEY_ENCRYPTED = """
AV6+xWcEFHNh6PsqmJYMRNJeYkNiOx8tUBB6Wns7QgKLc8HI2AS6LRhNuDrTWvyddBtUM24wUEhuIG42LGpefh6CmYkxBfVS7295Yz5OW7ygTXsEZZybB3U6ouO/Qvis8dpDwQX/ubai5jCjAqf/3XvG9e4XbWaK5a5WnOT81j5093JbVxI=
"""

# Test data used during app development
MUNI_FIXTURE = [
    {"mins": 4, "line": "K"},
    {"mins": 11, "line": "J"},
    {"mins": 15, "line": "M"},
    {"mins": 18, "line": "S"},
    {"mins": 36, "line": "K"},
]
BART_FIXTURE = [
    {"mins": 2, "color": "#339933"},
    {"mins": 4, "color": "#339933"},
    {"mins": 10, "color": "#0099cc"},
    {"mins": 12, "color": "#ffff33"},
    {"mins": 19, "color": "#0099cc"},
    {"mins": 73, "color": "#ffff33"},
]

# Color / stop configuration

COLORS_BY_LINE = {
    "BART": {"background": "#3F80DC", "text": "#FFF"},
    "F": {"background": "#f0e68c", "text": "#000"},
    "J": {"background": "#D7892A", "text": "#FFF"},
    "K": {"background": "#74A0BB", "text": "#FFF"},
    "L": {"background": "#8F338E", "text": "#FFF"},
    "M": {"background": "#338246", "text": "#FFF"},
    "N": {"background": "#234C89", "text": "#FFF"},
    "S": {"background": "#FFFF35", "text": "#000"},
    "T": {"background": "#BB3735", "text": "#FFF"},
}

BART_STOP_NAMES_BY_STOP_ID = {
    "12TH": "12th St. Oakland City Center",
    "16TH": "16th St. Mission",
    "19TH": "19th St. Oakland",
    "24TH": "24th St. Mission",
    "ANTC": "Antioch",
    "ASHB": "Ashby",
    "BALB": "Balboa Park",
    "BAYF": "Bay Fair",
    "BERY": "Berryessa",
    "CAST": "Castro Valley",
    "CIVC": "Civic Center/UN Plaza",
    "COLM": "Colma",
    "CONC": "Concord",
    "DALY": "Daly City",
    "DBRK": "Downtown Berkeley",
    "DUBL": "Dublin/Pleasanton",
    "DELN": "El Cerrito Del Norte",
    "PLZA": "El Cerrito Plaza",
    "EMBR": "Embarcadero",
    "FRMT": "Fremont",
    "FTVL": "Fruitvale",
    "GLEN": "Glen Park",
    "HAYW": "Hayward",
    "LAFY": "Lafayette",
    "LAKE": "Lake Merritt Daly City/Richmond",
    "MCAR": "MacArthur Richmond/Antioch",
    "MLBR": "Millbrae SFO/Antioch/Richmond",
    "MLPT": "Milpitas Daly City/Richmond",
    "MONT": "Montgomery St. East Bay",
    "NBRK": "North Berkeley Richmond",
    "NCON": "North Concord/Martinez Antioch",
    "COLS": "Oakland Coliseum - OAC Daly City/Richmond",
    "OAKL": "Oakland International Airport Coliseum",
    "ORIN": "Orinda Antioch",
    "PCTR": "Pittsburg Center Antioch",
    "PITT": "Pittsburg/Bay Point Antioch",
    "PHIL": "Pleasant Hill/Contra Costa Centre Antioch",
    "POWL": "Powell St. East Bay",
    "RICH": "Richmond Daly City/Millbrae/Berryessa",
    "ROCK": "Rockridge Antioch",
    "SBRN": "San Bruno Antioch/Richmond",
    "SFIA": "San Francisco International AirporSF/Antioch",
    "SANL": "San Leandro Daly City/Richmond",
    "SHAY": "South Hayward Daly City/Richmond",
    "SSAN": "South San Francisco Antioch/Richmond",
    "UCTY": "Union City Daly City/Richmond",
    "WCRK": "Walnut Creek",
    "WARM": "Warm Springs/South Fremont",
    "WDUB": "West Dublin/Pleasanton",
    "WOAK": "West Oakland",
}

def main(config):
    configure(config)
    all_transit_estimates = fetch_all_transit_estimates(config)
    return render.Root(child = render_all(all_transit_estimates), max_age = MAX_AGE_SECS)

def configure(config):
    # Get the muni api key from the secret if we can, falling back to using config
    maybe_muni_api_key = secret.decrypt(MUNI_API_KEY_ENCRYPTED) or config.str(MUNI_API_KEY_NAME)
    if maybe_muni_api_key:
        cache.set(
            MUNI_API_KEY_NAME,
            maybe_muni_api_key,
            ttl_seconds = 30 * 24 * 60 * 60,
        )

def get_schema():
    bart_station_options = [
        schema.Option(
            display = BART_STOP_NAMES_BY_STOP_ID[key],
            value = key,
        )
        for key in BART_STOP_NAMES_BY_STOP_ID.keys()
    ]
    bart_direction_options = [
        schema.Option(
            display = "North",
            value = "N",
        ),
        schema.Option(
            display = "South",
            value = "S",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "muni_stop_json",
                name = "Muni Stop Id",
                desc = "Show arrival estimates for this Muni stop",
                icon = "locationCrosshairs",
                handler = search_muni_stop,
            ),
            schema.Text(
                id = "muni_filter_below_mins",
                name = "Hide Muni below mins",
                desc = "Hide arrivals below this many mins",
                icon = "stopwatch",
                default = "1",
            ),
            schema.Dropdown(
                id = "bart_stop_id",
                name = "Bart stop",
                desc = "Show arrival estimates for this station",
                icon = "locationCrosshairs",
                default = bart_station_options[0].value,
                options = bart_station_options,
            ),
            schema.Dropdown(
                id = "bart_dir",
                name = "BART Direction",
                desc = "Bart Direction",
                icon = "compass",
                default = bart_direction_options[0].value,
                options = bart_direction_options,
            ),
            schema.Text(
                id = "bart_filter_below_mins",
                name = "Hide Bart below mins",
                desc = "Hide arrivals below this many mins",
                icon = "stopwatch",
                default = "1",
            ),
            schema.Text(
                id = MUNI_API_KEY_NAME,
                name = "Muni API key",
                desc = "Muni API key",
                icon = "key",
            ),
            schema.Toggle(
                id = "use_test_data",
                name = "Use example data",
                desc = "Display example data instead of real estimates",
                icon = "vial",
            ),
        ],
    )

def search_muni_stop(pattern):
    pattern_lower = pattern.lower()
    muni_api_key = cache.get(MUNI_API_KEY_NAME)
    if muni_api_key == None:
        return [schema.Option(display = "Failed. Need muni_api_key", value = 0)]
    get_all_stops_url = build_muni_get_all_stops_api_url(muni_api_key)
    all_muni_stops = fetch_data(get_all_stops_url, get_all_stops_url)

    stops = all_muni_stops["Contents"]["dataObjects"]["ScheduledStopPoint"]
    matching_stops = [
        stop
        for stop in stops
        if pattern or pattern_lower in stop["Name"].lower()
    ]
    return [
        schema.Option(display = "%s (%s)" % (stop["Name"], stop["id"]), value = stop["id"])
        for stop in matching_stops
    ]

def fetch_all_transit_estimates(config):
    bart_estimates = fetch_bart_data(config)
    muni_estimates = fetch_muni_data(config)

    print(
        "There are bart trains coming in " +
        ", ".join([str(est["mins"]) for est in bart_estimates]) +
        " mins",
    )
    print(
        "There are muni trains coming in " +
        ", ".join([str(est["mins"]) for est in muni_estimates]) +
        " mins",
    )

    all_transit_estimates = {
        "bart_estimates": bart_estimates,
        "muni_estimates": muni_estimates,
    }
    return all_transit_estimates

def fetch_bart_data(config):
    bart_stop_id = config.str("bart_stop_id")
    if bart_stop_id == None:
        bart_stop_id = DEFAULT_BART_STOP_ID

    bart_dir = config.str("bart_dir")
    if bart_dir == None:
        bart_dir = "N"

    if config.bool("use_test_data", False):
        bart_estimates = BART_FIXTURE
    else:
        bart_api_url = build_bart_api_url(bart_stop_id, bart_dir)
        bart_data = fetch_data(bart_api_url, bart_api_url)

        station_data = bart_data["root"]["station"][0]
        etds = station_data["etd"]
        all_estimates = []
        for etd in etds:
            for estimate in etd["estimate"]:
                all_estimates.append(estimate)

        unsorted_bart_trains_estimates_mins = [
            {"mins": int(est["minutes"]), "color": est["hexcolor"]}
            for est in all_estimates
            if est["minutes"].isdigit()
        ]
        bart_estimates = sorted(
            unsorted_bart_trains_estimates_mins,
            lambda x: x["mins"],
        )
    bart_filter_below_mins = int(config.get("bart_filter_below_mins", "0"))
    bart_estimates_filtered = [
        x
        for x in bart_estimates
        if x["mins"] >= bart_filter_below_mins
    ]
    return bart_estimates_filtered[0:3]

def build_bart_api_url(bart_stop_id, bart_dir):
    return "https://api.bart.gov/api/etd.aspx?cmd=etd&key=%s&orig=%s&dir=%s&json=y" % (
        BART_PUBLIC_API_KEY,
        bart_stop_id,
        bart_dir,
    )

def build_muni_stop_monitoring_api_url(muni_api_key, muni_stop_id):
    return (
        "http://api.511.org/transit/StopMonitoring?api_key=%s&agency=SF&format=json&stopCode=%s" %
        (muni_api_key, muni_stop_id)
    )

def build_muni_get_all_stops_api_url(muni_api_key):
    return "http://api.511.org/transit/stops?api_key=%s&operator_id=SF&format=json" % (
        muni_api_key
    )

def fetch_muni_data(config):
    muni_stop_json_str = config.get("muni_stop_json")
    if muni_stop_json_str:
        muni_stop_json = json.decode(muni_stop_json_str)
        muni_stop_id = muni_stop_json["value"]
    else:
        muni_stop_id = DEFAULT_MUNI_STOP_ID

    if config.bool("use_test_data", False):
        muni_estimates = MUNI_FIXTURE
    else:
        muni_api_key = cache.get(MUNI_API_KEY_NAME)
        if muni_api_key == None:
            return []
        muni_api_url = build_muni_stop_monitoring_api_url(muni_api_key, muni_stop_id)
        muni_data = fetch_data(muni_api_url, muni_api_url)
        stop_visits = muni_data["ServiceDelivery"]["StopMonitoringDelivery"]["MonitoredStopVisit"]
        muni_estimates = [
            extract_muni_stop_visit(stop_visit)
            for stop_visit in stop_visits
        ]

    muni_filter_below_mins = int(config.get("muni_filter_below_mins", "0"))
    muni_estimates_filtered = [
        est
        for est in muni_estimates
        if est["mins"] >= muni_filter_below_mins
    ]
    return muni_estimates_filtered[0:3]

def extract_muni_stop_visit(stop_visit):
    journey = stop_visit["MonitoredVehicleJourney"]
    expected_arrival_time = journey["MonitoredCall"]["ExpectedArrivalTime"]
    expected_arrival = time.parse_time(expected_arrival_time)
    duration = expected_arrival - time.now()
    mins = math.floor(duration.minutes)
    return {
        "line": journey["LineRef"],
        "mins": mins,
    }

def fetch_data(cache_key, url):
    data_json_str = cache.get(cache_key)
    if data_json_str != None:
        print("Hit! Using cached %s data." % cache_key)
    else:
        print("Miss! Fetching new %s data..." % cache_key)
        rep = http.get(url)
        if rep.status_code != 200:
            fail("Request failed with status %d" % rep.status_code)

        body_str = rep.body()
        start_idx = body_str.find("{")
        data_json_str = body_str[start_idx:]
        cache.set(cache_key, data_json_str, ttl_seconds = CACHE_TTL)
    return json.decode(data_json_str)

def render_all(transit_data):
    bart_estimates = transit_data["bart_estimates"]
    muni_estimates = transit_data["muni_estimates"]
    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render_muni_estimates(muni_estimates),
            render_bart_times(bart_estimates),
        ],
    )

def render_bart_times(bart_estimates):
    return render.Column(
        children = [render_bart_estimate(est) for est in bart_estimates],
        expanded = True,
        main_align = "center",
        cross_align = "start",
    )

def render_bart_estimate(est):
    return render.Padding(
        child = render.Row(
            children = [
                render.Padding(
                    child = render.Box(
                        width = 6,
                        height = 6,
                        color = est["color"],
                        child = render.Text(content = "", font = "tb-8"),
                    ),
                    pad = (0, 1, 1, 0),
                ),
                render.Text(content = str(est["mins"]), font = "tb-8"),
            ],
        ),
        pad = (2, 1, 0, 0),
    )

def render_muni_estimates(muni_estimates):
    items = [render_muni_estimate(muni_estimates[i], i) for i in range(len(muni_estimates))]
    return render.Column(
        children = items,
        expanded = True,
        main_align = "center",
        cross_align = "end",
    )

def render_muni_estimate(estimate, index):
    return render.Padding(
        child = render.Row(
            children = [
                render_muni_dot(estimate["line"]),
                render.Stack(children = [
                    render.Box(width = 10, height = 7),
                    render.Text(content = str(estimate["mins"])),
                ]),
            ],
        ),
        pad = (0, 2 if index > 0 else 0, 0, 0),
    )

def render_muni_dot(line):
    if line in COLORS_BY_LINE:
        use_circle = True
        colors = COLORS_BY_LINE[line]
        text_color = colors["text"]
        background_color = colors["background"]
    else:
        use_circle = False
        text_color = "#000"
        background_color = "#bde8ff"

    box_width = 1 + 5 * len(line)
    child = render.Circle(
        color = background_color,
        diameter = 8,
        child = render.Text(content = line, color = text_color, font = "tb-8"),
    ) if use_circle else render.Box(
        color = background_color,
        width = box_width,
        height = 7,
        padding = 0,
        child = render.Padding(
            child = render.Text(content = line, color = text_color, font = "CG-pixel-4x5-mono"),
            pad = (1, 0, 0, 0),
        ),
    )
    return render.Padding(
        child = child,
        pad = (0, 0, 1, 0),
    )
