"""
Applet: NH DES Data
Summary: Show select NH DES API data
Description: Gathers and displays select data from the public NH DES API.
Author: dmarcucci
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://nhdes.rtiamanzi.org/api"
TTL_SECONDS = 300

def generate_root(content):
    return render.Root(
        child = render.Row(
            children = [
                render.Box(
                    child = render.Text(content = content),
                    width = 64,
                    height = 32,
                ),
            ],
        ),
    )

def main(config):
    location_code = config.get("station", "WEIN3")

    if not location_code:
        return generate_root("No station")

    timeseries_api_url = "{}/timeseries/sparse/?location__code={}".format(BASE_URL, location_code)
    res = http.get(timeseries_api_url, ttl_seconds = TTL_SECONDS)

    if res.status_code != 200 or type(res.json()) != "list":
        return generate_root("No timeseries")

    timeseries_id = None

    for item in res.json():
        if type(item) == "dict" and item.get("name") == "Water Temperature":
            timeseries_id = item.get("id")
            break

    if not timeseries_id:
        return generate_root("No timeseries")

    end_unix = time.now().unix
    end_iso = time.from_timestamp(end_unix).in_location("UTC").format("2006-01-02T15:04:05")
    start_unix = end_unix - 10800
    start_iso = time.from_timestamp(start_unix).in_location("UTC").format("2006-01-02T15:04:05")

    data_api_url = "{}/timeseries/{}/values?start={}&end={}".format(BASE_URL, timeseries_id, start_iso, end_iso)
    res = http.get(data_api_url, ttl_seconds = TTL_SECONDS)

    if res.status_code != 200 or type(res.json()) != "list" or len(res.json()) == 0:
        return generate_root("No data")

    data = res.json()
    data = data[len(data) - 1]

    if type(data) != "dict" or not data.get("num_value"):
        return generate_root("No data")

    temperature = data.get("num_value")

    # Formatting to 6 decimal places
    temperature = str(int(math.round(temperature * 1000000)))
    temperature = (temperature[0:-6] + "." + temperature[-6:]) + " °F"

    return generate_root(temperature)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station",
                name = "Station Code",
                desc = "The station code to use (see https://nhdes.rtiamanzi.org/stations).",
                icon = "cloud",
                default = "WEIN3",
            ),
        ],
    )
