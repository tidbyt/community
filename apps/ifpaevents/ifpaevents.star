"""
Applet: IFPAEvents
Summary: See Upcoming IFPA Events
Description: Display a list of upcoming International Flipper Pinball Association events based on location.
Author: coreyhulse
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

API_KEY = """
AV6+xWcExdMNUN6PYH+JotIsNKvKdvxNA5Efhe5DxwEfoTUjlS3lCzN/EwbIcxY2FmhuIBuf9d0oM8OFv54WMnQFWd50vQ6wT3kXCuGYwxCcicp2jtRvz7k3WeSnDlsVC5cOLDCTYEg6nU+/acQQvUwfsXC3Qd77EKrDAFi67BclFQTyyBA=
"""

CACHE_TIME_IN_SECONDS = 3600
DEFAULT_MAX_DISTANCE = 50

# Default location is the old PAPA Headquarters in Carnegie, PA
DEFAULT_LOCATION = json.encode({
    "lat": "40.400046",
    "lng": "-80.095728",
    "description": "Carnegie, PA, USA",
    "locality": "Carnegie",
    "place_id": "ChIJTR1tUdj3NIgRtGxUcq5Luk4",
    "timezone": "America/New_York",
})

def main(config):
    location_cfg = config.str("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg)
    max_distance = config.str("max_distance", DEFAULT_MAX_DISTANCE)

    apiKey = secret.decrypt(API_KEY) or config.get("dev_api_key")

    upcoming_events_url = "https://api.ifpapinball.com/v2/calendar/search?latitude=%s&longitude=%s&distance=%s&distance_type=Miles&api_key=%s" % (location["lat"], location["lng"], max_distance, apiKey)
    upcoming_events_data = http.get(upcoming_events_url, ttl_seconds = CACHE_TIME_IN_SECONDS)
    upcoming_events_breakout = []
    upcoming_events = []

    if upcoming_events_data.status_code != 200:
        print("IFPA request failed with status %d" % upcoming_events_data.status_code)
    else:
        print("Cache hit!" if (upcoming_events_data.headers.get("Tidbyt-Cache-Status") == "HIT") else "Cache miss!")

    #if (len(upcoming_events_data.json()["calendar"]) > 0):
    if (upcoming_events_data.json().get("calendar")):
        for i in range(3):
            upcoming_events_breakout.append(upcoming_events_data.json()["calendar"][i]["tournament_name"] + " in " + upcoming_events_data.json()["calendar"][i]["city"] + " on " + upcoming_events_data.json()["calendar"][i]["start_date"])

        for event in upcoming_events_breakout:
            upcoming_events.append(
                render.Row(
                    children = [
                        render.Marquee(
                            child = render.Text(event, font = "tom-thumb"),
                            width = 64,
                            offset_start = 32,
                            offset_end = 32,
                            align = "start",
                        ),
                    ],
                ),
            )
    else:
        upcoming_events.append(
            render.Row(
                children = [
                    render.Marquee(
                        child = render.Text("TILT! The API Key Is Missing!", font = "tom-thumb"),
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
                        render.Text("IFPA", font = "tom-thumb", color = "#ff0"),
                        render.Text(" %s " % location["locality"], font = "tom-thumb", color = "#c50"),
                    ],
                    main_align = "center",
                    expanded = True,
                ),
                render.Column(
                    children = upcoming_events,
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
