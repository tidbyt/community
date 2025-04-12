# Show the 3 most recent machines in your area

# https://pinballmap.com/api/v1/locations/closest_by_lat_lon.json?lat=40.6781784;lon=-73.9441579;max_distance=10;send_all_within_distance=1;no_details=1

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TIME_IN_SECONDS = 600
DEFAULT_MAX_DISTANCE = 10
DEFAULT_LOCATION = json.encode({
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York",
})

PBM_LOGO = base64.decode("""
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
""")

def main(config):
    location_cfg = config.str("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg)
    max_distance = config.str("max_distance", DEFAULT_MAX_DISTANCE)

    most_recent_machines_url = "http://pinballmap.com/api/v1/location_machine_xrefs/most_recent_by_lat_lon.json?lat=%s;lon=%s;max_distance=%s" % (location["lat"], location["lng"], max_distance)
    most_recent_machines_data = http.get(most_recent_machines_url, ttl_seconds = CACHE_TIME_IN_SECONDS)
    most_recent_machines = []

    if most_recent_machines_data.status_code != 200:
        print("PBM request failed with status %d" % most_recent_machines_data.status_code)
    else:
        print("Cache hit!" if (most_recent_machines_data.headers.get("Tidbyt-Cache-Status") == "HIT") else "Cache miss!")

    if (len(most_recent_machines_data.json()["most_recently_added_machines"]) > 0):
        for machine in most_recent_machines_data.json()["most_recently_added_machines"]:
            most_recent_machines.append(
                render.Row(
                    children = [
                        render.Marquee(
                            child = render.Text(machine, font = "tom-thumb"),
                            width = 64,
                            offset_start = 32,
                            offset_end = 32,
                            align = "start",
                        ),
                    ],
                ),
            )

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(src = PBM_LOGO, width = 6),
                        render.Text(" %s " % location["locality"], font = "tom-thumb"),
                        render.Image(src = PBM_LOGO, width = 6),
                    ],
                    main_align = "center",
                    expanded = True,
                ),
                render.Column(
                    children = most_recent_machines,
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "max_distance",
                name = "Max Distance",
                desc = "The maximum number of miles away you want to monitor",
                icon = "user",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Monitor new machines from this location",
                icon = "locationDot",
            ),
        ],
    )
