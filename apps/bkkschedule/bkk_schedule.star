"""
Applet: BKK Schedule
Summary: Budapest public transit
Description: Public transit display for Budapest, show upcoming BKK departures for a stop.
Author: tomzorz
"""

"""
dev: http://127.0.0.1:8080/?stop_id=F04039

TODO:
- add error return to meta

publish: https://tidbyt.dev/docs/publish/publishing-apps
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("math.star", "math")
load("schema.star", "schema")
load("time.star", "time")
load("humanize.star", "humanize")
load("secret.star", "secret")

# stop ID examples
# margit hid budai hidfo pesti iranyba: F00189
# moricz zsigmond korter eszaki iranyba: F02203

DEFAULT_STOP_ID = "F00189"

CACHE_TIMEOUT = 60  # will display inaccurate on-time performance if not 60 seconds.
WEEK_CACHE_TIMEOUT = 60 * 60 * 24 * 7

"""
https://editor.swagger.io/?url=https://opendata.bkk.hu/docs/futar-openapi.yaml
https://futar.bkk.hu/stop/BKK_F04039?routeIds=%7CBKK_3420
https://opendata.bkk.hu/data-sources
https://github.com/tidbyt/community/blob/main/apps/mtatraintime/mtatraintime.star
https://tidbyt.dev/docs/build/clock-app
"""

request_headers = {
    "user-agent": "bkk-tidbyt-service",
    "accept": "application/json, text/plain, */*",
    "accept-language": "en-US,en;q=0.9",
}

def get_meta(api_key, trip_id):
    route_cache_key = trip_id + "_route"
    route_color_cache_key = trip_id + "_color_route"
    route_color2_cache_key = trip_id + "_color2_route"

    cached_route = cache.get(route_cache_key)
    cached_color = cache.get(route_color_cache_key)
    cached_color2 = cache.get(route_color2_cache_key)

    if cached_route == None or cached_color == None:
        url = (
            "https://futar.bkk.hu/api/query/v1/ws/otp/api/where/trip-details.json?key=" +
            api_key +
            "&version=3&includeReferences=true&tripId=" +
            trip_id
        )
        print(url)
        rep = http.get(url, headers = request_headers, ttl_seconds = WEEK_CACHE_TIMEOUT)
        if rep.status_code != 200:
            fail("BKK API request failed with status %d", rep.status_code)
        trip_data = rep.json()
        if "vehicle" in trip_data["data"]["entry"]:
            cached_route = trip_data["data"]["entry"]["vehicle"]["routeId"]
            cached_color = trip_data["data"]["entry"]["vehicle"]["style"]["icon"]["color"]
            cached_color2 = trip_data["data"]["entry"]["vehicle"]["style"]["icon"]["secondaryColor"]
        else:
            # ref_key = trip_data["data"]["references"]["routes"].keys()[0]
            trip_key = trip_data["data"]["references"]["trips"].keys()[0]
            print("trips: " + str(len(trip_data["data"]["references"]["trips"].keys())))
            ref_key = trip_data["data"]["references"]["trips"][trip_key]["routeId"]
            cached_route = trip_data["data"]["references"]["routes"][ref_key]["id"]
            cached_color = trip_data["data"]["references"]["routes"][ref_key]["style"]["vehicleIcon"]["color"]
            cached_color2 = trip_data["data"]["references"]["routes"][ref_key]["style"]["vehicleIcon"]["secondaryColor"]
        cache.set(route_cache_key, cached_route, ttl_seconds = WEEK_CACHE_TIMEOUT)
        cache.set(route_color_cache_key, cached_color, ttl_seconds = WEEK_CACHE_TIMEOUT)
        cache.set(route_color2_cache_key, cached_color2, ttl_seconds = WEEK_CACHE_TIMEOUT)
        print("Cached route id " + cached_route + " for " + route_cache_key)
        print("Cached route color " + cached_color + " for " + route_color_cache_key)
        print("Cached route color 2 " + cached_color2 + " for " + route_color_cache_key)

    route_id = cached_route

    short_name_cache_key = route_id + "_short_name"
    short_name_cache_key = route_id + "_short_name"
    cached_short_name = cache.get(short_name_cache_key)

    if cached_short_name == None:
        url = (
            "https://futar.bkk.hu/api/query/v1/ws/otp/api/where/route-details.json?key=" +
            api_key +
            "&version=3&includeReferences=true&routeId=" +
            route_id
        )
        rep = http.get(url, headers = request_headers, ttl_seconds = WEEK_CACHE_TIMEOUT)
        if rep.status_code != 200:
            fail("BKK API request failed with status %d", rep.status_code)
        route_data = rep.json()
        cached_short_name = route_data["data"]["entry"]["shortName"]
        cache.set(
            short_name_cache_key,
            cached_short_name,
            ttl_seconds = WEEK_CACHE_TIMEOUT,
        )
        print("Cached short name " + cached_short_name + " for " + short_name_cache_key)

    return {
        "name": cached_short_name,
        "color": cached_color,
        "secondaryColor": cached_color2,
    }

def main(config):
    API_KEY = secret.decrypt(
        "AV6+xWcEIQHsKyCnPiVb5c4FBJEyGIGmHfqd7Y+zBfEds9TJH93h6MYU3irY2FhMkvZmlLmqR5nEIF+VOH4RZSPHtH4YPDVh+lg2FZwYAFgIt2OmvdRhD2b789q9OXjQFQCSpQHWWTnFx2hTxxe9q1jn/6bPHtK5HpqAhnepjjXn532Syei6+AzI",
    ) # or config.get("dev_api_key") # UNCOMMENT FOR DEV

    config_stop = "BKK_" + config.get("stop_id", DEFAULT_STOP_ID)

    cached_stop = cache.get(config_stop + "_timetable")

    timezone = config.get("timezone") or "Europe/Budapest"
    now = time.now().in_location(timezone)

    # today_date = now.format("20060102")
    epoch = now.unix

    if cached_stop != None:
        print("Displaying cached data.")  # TODO remove debug
        stop_data = json.decode(cached_stop)
    else:
        print("Calling BKK API.")  # TODO remove debug
        url = (
            "https://futar.bkk.hu/api/query/v1/ws/otp/api/where/arrivals-and-departures-for-stop.json?key=" +
            API_KEY +
            "&version=3&includeReferences=true&stopId=" +
            config_stop +
            "&onlyDepartures=true&limit=50&minutesBefore=0&minutesAfter=60"
        )
        print(url)  # TODO remove debug
        rep = http.get(url, headers = request_headers, ttl_seconds = CACHE_TIMEOUT)
        if rep.status_code != 200:
            fail("BKK API request failed with status %d", rep.status_code)
        stop_data = rep.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(config_stop + "timetable", rep.body(), ttl_seconds = CACHE_TIMEOUT)

    # print(stop_data) # TODO remove debug

    all_departures = []
    for stop_time in stop_data["data"]["entry"]["stopTimes"][:8]:
        meta = get_meta(API_KEY, stop_time["tripId"])
        print(meta["name"] + " " + stop_time["stopHeadsign"])
        time_diff = stop_time["departureTime"] - epoch
        if time_diff > 0:
            all_departures.append(
                {
                    "number": meta["name"],
                    "color": meta["color"],
                    "secondaryColor": meta["secondaryColor"] or "ffffff",
                    "name": stop_time["stopHeadsign"],
                    "time": str(int(math.round(time_diff / 60))),
                },
            )

    column_children = []
    for departure in all_departures:
        column_children.append(
            render.Row(
                children = [
                    render.Box(
                        child = render.Text(
                            content = departure["number"],
                            font = "tb-8",
                            color = "#" + departure["secondaryColor"],
                        ),
                        color = "#" + departure["color"],
                        width = 16,
                        height = 8,
                    ),
                    render.Box(
                        child = render.Text(
                            content = departure["time"] + "'",
                            font = "tb-8",
                            color = "#ffffff",
                        ),
                        color = "#309030",
                        width = 14,
                        height = 8,
                    ),
                    render.Box(width = 1, height = 8),
                    render.Marquee(
                        child = render.Text(content = departure["name"], font = "5x8"),
                        width = 33,
                    ),
                ],
            ),
        )

    return render.Root(child = render.Column(children = column_children))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "BKK Stop ID",
                desc = "The stop to display departures at.",
                icon = "train",
                default = DEFAULT_STOP_ID,
            ),
            # schema.Text(
            #     id = "dev_api_key",
            #     name = "BKK Developer API Key",
            #     desc = "Optional development API key.",
            #     icon = "key",
            #     default = "",
            # ), # UNCOMMENT FOR DEV
        ],
    )
