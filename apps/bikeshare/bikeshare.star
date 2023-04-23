"""
Applet: Bikeshare
Summary: Bikeshare availability
Description: Shows bike and parking availability for user selected bikeshare locations.
Author: snorremd
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/csv.star", "csv")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# URL to a CSV file containing the bikeshare providers supporting GBFS
BIKESHARE_STATION_START = '{"url": "https://gbfs.urbansharing.com/bergenbysykkel.no/station_status.json", "station": { "station_id": "368", "name": "Festplassen", "address": "Christies gate 3A", "rental_uris": {"android": "bergenbysykkel://stations/368", "ios": "bergenbysykkel://stations/368"}, "lat": 60.391123958982405, "lon": 5.325713785893413, "capacity": 25 } }'
BIKESHARE_STATION_STOP = '{"url": "https://gbfs.urbansharing.com/bergenbysykkel.no/station_status.json", "station": { "station_id": "1898", "name": "Kronstad", "address": "St. Olavs vei 15", "rental_uris": {"android": "bergenbysykkel://stations/1898", "ios": "bergenbysykkel://stations/1898"}, "lat": 60.3720506380196, "lon": 5.352659970408496, "capacity": 25 } }'

# Renders a cute little green bike
BIKE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAA0AAAAJCAYAAADpeqZqAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADaADAAQAAAABAAAACQAAAABcSr5uAAAAhElEQVQYGWNkIAJUhnr8hylrX72DkQXGAdHokjA5oTwmMLPUdhsjiAEmYJIguvuwF9xUmDhMMYyPQmPTgE0M7DxkZ6GYAuSAbAFpfDfpH1gK5Ce4P2AmohsA4sPkQLpAfIgPgRyYSWDj0AiQbciGwTWBrUVTjMxFlgeHHrIpyJIwTejyAJ4kPPvu7EtQAAAAAElFTkSuQmCC""")

# Used to fetch list of available Bikeshare companies and their general bikeshare feed specification APIs
GBFS_LIST = "https://raw.githubusercontent.com/NABSA/gbfs/master/systems.csv"

# User agent to identify this as a Tidbyt community app when making requests
USER_AGENT = "Tidbyt - Bikeshare (https://github.com/tidbyt/community/tree/main/apps/bikeshare)"

def fetch_status(station):
    station_json = cache.get(station["url"])
    if station_json == None:
        station_status_resp = http.get(
            url = station["url"],
            headers = {
                "Accept": "application/json",
                "User-Agent": USER_AGENT,
            },
        )

        if (station_status_resp.status_code != 200):
            print("Bikeshare request failed with status %d", station_status_resp.status_code)
            return []

        station_json = station_status_resp.body()
        cache.set(station["url"], station_json, ttl_seconds = 60)

    # Station status start
    statuses = json.decode(station_json)["data"]["stations"]
    return [s for s in statuses if s["station_id"] == station["station"]["station_id"]]

def main(config):
    start = json.decode(config.get("station_start", BIKESHARE_STATION_START))
    stop = json.decode(config.get("station_stop", BIKESHARE_STATION_STOP))

    # Fetch status for start and stop stations
    # We fetch twice (cached anyway) to guarantee that the defaulted url and station ids match
    start_status = fetch_status(start)
    stop_status = fetch_status(stop)
    if (len(start_status) == 0 or len(stop_status) == 0):
        return render_error()

    start["availability"] = start_status[0]["num_bikes_available"]
    stop["availability"] = stop_status[0]["num_docks_available"]

    return render.Root(
        render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Image(src = BIKE_ICON),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 0, 0, 0),
                            child = render.Marquee(
                                width = 48,
                                child = render.Text(content = start["station"]["name"], font = "tom-thumb"),
                            ),
                        ),
                        render.Padding(
                            pad = (0, 0, 2, 0),
                            child = render.Text(content = "%d" % start["availability"], font = "tom-thumb", color = "#8bc34a"),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 0, 2, 0),
                            child = render.Marquee(
                                width = 48,
                                child = render.Text(content = stop["station"]["name"], font = "tom-thumb"),
                            ),
                        ),
                        render.Padding(
                            pad = (0, 0, 2, 0),
                            child = render.Text(content = "%d" % stop["availability"], font = "tom-thumb", color = "#13b6ff"),
                        ),
                    ],
                ),
            ],
        ),
    )

def render_error():
    return render.Root(
        render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = "Bikeshare status unavailable",
                            color = "#ff0000",
                            align = "center",
                        ),
                    ],
                ),
            ],
        ),
    )

# Configuration for the applet

def bikeshare_to_option(bikeshare):
    return schema.Option(
        display = bikeshare[1] + " - " + bikeshare[2],
        value = bikeshare[5],
    )

def get_bikeshare_providers():
    bikeshare_csv = cache.get("bikeshare_csv")
    if bikeshare_csv == None:
        resp = http.get(
            url = GBFS_LIST,
        )
        if resp.status_code != 200:
            return []
        bikeshare_csv = resp.body()
        cache.set("bikeshare_csv", bikeshare_csv, ttl_seconds = 60 * 60 * 24)

    bikeshares = csv.read_all(
        source = bikeshare_csv,
    )

    mapped = [bikeshare_to_option(bikeshare) for bikeshare in bikeshares]

    return mapped[1:]

# Look up discovery data for given gbfs url
def gbfs_discovery(gbfs_url):
    discovery_json = cache.get("gbfs_discovery_" + gbfs_url)
    if discovery_json == None:
        print("Fetching GBFS discovery data from " + gbfs_url)
        resp = http.get(
            url = gbfs_url,
        )
        if resp.status_code != 200:
            return None
        discovery_json = resp.body()
        cache.set("gbfs_discovery_" + gbfs_url, discovery_json, ttl_seconds = 60 * 60 * 24)
    return json.decode(discovery_json)

# Look up bikeshare locations for given url
def bikeshare_stations(url):
    resp_json = cache.get("bikeshare_stations_" + url)
    if resp_json == None:
        resp = http.get(
            url = url,
            headers = {
                "User-Agent": USER_AGENT,
            },
        )
        if resp.status_code != 200:
            return []
        resp_json = resp.body()
        cache.set("bikeshare_stations_" + url, resp_json, ttl_seconds = 60 * 60 * 24)

    return json.decode(resp_json)

# Given a bikeshare provider look up its stations for use as dropdown options
def locations(provider):
    discovery = gbfs_discovery(provider)
    if discovery == None:
        return []
    feeds = discovery["data"].values()[0]["feeds"]
    infoFeed = [f for f in feeds if f["name"] == "station_information"]
    statusFeed = [f for f in feeds if f["name"] == "station_status"]
    if (len(infoFeed) == 0 or len(statusFeed) == 0):
        return []

    stations = bikeshare_stations(infoFeed[0]["url"])

    # We append the status feed url to each option so we can fetch the status later
    options = [schema.Option(
        display = station["name"],
        value = json.encode({"station": station, "url": statusFeed[0]["url"]}),
    ) for station in stations["data"]["stations"]]

    if len(options) == 0:
        return []

    return [
        schema.Dropdown(
            id = "station_start",
            name = "Start station",
            desc = "Where to pick up bike",
            icon = "bicycle",
            options = options,
            default = options[0].value,
        ),
        schema.Dropdown(
            id = "station_stop",
            name = "Stop station",
            desc = "Where to drop off bike",
            icon = "squareParking",
            options = options,
            default = options[0].value,
        ),
    ]

def get_schema():
    providers = get_bikeshare_providers()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "provider",
                name = "Provider",
                desc = "A list of bikeshare providers.",
                icon = "building",
                options = providers,
                default = providers[7].value,
            ),
            schema.Generated(
                id = "locations",
                source = "provider",
                handler = locations,
            ),
        ],
    )
