load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# tidbyt-rtpi-rotter
KEY = "AV6+xWcE4VoXv5UpUq2c3zK5B5K1+sqEbwe94y0w0xjhMYBeLYdm0xyk8/baEAOvXDsbYHtageaL6hj7tknVAV9SQBS2Bz7v03TRSa7EVZ9p92dQCA3cAdYtCpPTM6FDwnxpi6MnoscsQ6/zsi7DKvf5t4vZYH90xZu57vwWHw=="

DEFAULT_LOCATION = """
{"lat":45.6,"lng":"-122.64","locality":"Portland, OR","timezone":"America/Los_Angeles"}
"""
DEFAULT_STOP = "13043"
URL = "https://developer.trimet.org/ws/V2/arrivals?locIDs={}&appID={}&json=true"
# URL = "https://developer.trimet.org/ws/V2/arrivals?locIDs={}&appID=3EE99DA9677E312D637CED197&json=true"

def main(config):
    api_key = secret.decrypt(KEY) or "3EE99DA9677E312D637CED197"
    # print("api_key: %s" % api_key)

    # font_sm = config.get("font-sm", "tom-thumb")
    font_sm = config.get("font-sm", "CG-pixel-3x5-mono")
    font_lg = config.get("font-lg", "6x13")
    stop = config.str("stop", DEFAULT_STOP)
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone).format("1/2 3:04 PM")

    print("stop: %s" % stop)

    stop_cached = cache.get("stop")
    if stop_cached != None:
        print("Hit! Displaying cached data.")
        rep = json.decode(stop_cached)
    else:
        print("Miss! Calling TriMet API with")
        response = http.get(URL.format(stop, api_key))
        if response.status_code != 200:
            fail("request failed with status %d", response.status_code)
        rep = response.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("stop", json.encode(rep), ttl_seconds = 30)

    # print(rep["resultSet"])
    # arrival_data = rep["resultSet"]["arrival"][0]["fullSign"]
    est = int(rep["resultSet"]["arrival"][0]["estimated"])
    conv = time.from_timestamp(est // 1000).in_location(timezone).format("3:04 PM")

    # print(int(rep["resultSet"]["arrival"][0]["estimated"]))
    stop = rep["resultSet"]["location"][0]["desc"]

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text(
                    content = "%s" % stop,
                    font = font_sm,
                ),
                render.Text(
                    content = "%s" % conv,
                    font = font_lg,
                ),
                render.Text(
                    content = "%s" % now,
                    font = font_sm,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop",
                name = "Stop ID",
                desc = "Enter a TriMet Stop ID",
                icon = "bus",
                default = DEFAULT_STOP,
            ),
            # schema.Location(
            #     id = "location",
            #     name = "Location",
            #     desc = "Location for which to display time.",
            #     icon = "locationDot",
            # ),
        ],
    )
