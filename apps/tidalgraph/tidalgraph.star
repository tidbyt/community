"""
Applet: TidalGraph
Summary: Shows height of ocean tide
Description: Shows the tide height throughout the day of the ocean based on the selected NOAA tide station.
Author: k.wajdowicz
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TIDE_DATA_INTERVAL = "10"
TIMEZONE_MAP = {
    "HAST": "Pacific/Honolulu",
    "AKST": "America/Anchorage",
    "PST": "America/Los_Angeles",
    "CST": "America/Chicago",
    "EST": "America/New_York",
}

def main(config):
    station_id = config.get("stationid") or config.get("station")
    station_timezone = get_station_timezone(station_id)

    if station_timezone == None:
        return station_not_found(station_id)
    if station_timezone.startswith("unsupported_timezone:"):
        return unsupported_timezone(station_id, station_timezone.split(":")[1])

    current_time = time.now().in_location(station_timezone)
    calculated_hours = calculate_hours(current_time.format("15:04"))
    todays_data = get_tide_data(station_id, current_time.format("20060102"), TIDE_DATA_INTERVAL)

    if todays_data == None:
        return station_returned_nodata(station_id)

    data = get_data_points(todays_data)
    points = data["points"]
    min = data["min_val"]
    max = data["max_val"]

    return render.Root(
        delay = 100,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = 64,
                    align = "center",
                    child = render.Text(
                        content = current_time.format("01-02-06 15:04"),
                        font = "tom-thumb",
                    ),
                ),
                render.Marquee(
                    width = 64,
                    align = "center",
                    child = render.Text(
                        content = get_current_state(todays_data, current_time),
                        font = "tom-thumb",
                    ),
                ),
                render.Row(
                    children = [
                        render.Stack(
                            children = [
                                render.Plot(
                                    data = points,
                                    width = 64,
                                    height = 22,
                                    color = "#368BC1",
                                    fill_color = "#123456",
                                    color_inverted = "#800080",
                                    fill_color_inverted = "#550A35",
                                    x_lim = (0, 24),
                                    y_lim = (min - 1, max + 1),
                                    fill = True,
                                ),
                                render.Plot(
                                    data = [(calculated_hours, min), (calculated_hours, max)],
                                    width = 64,
                                    height = 22,
                                    color = "#626567",
                                    color_inverted = "#626567",
                                    x_lim = (0, 24),
                                    y_lim = (min - 1, max + 1),
                                    fill = True,
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Anchorage, AK",
            value = "9455920",
        ),
        schema.Option(
            display = "Juneau, AK",
            value = "9452210",
        ),
        schema.Option(
            display = "Monterey, CA",
            value = "9413450",
        ),
        schema.Option(
            display = "Port San Luis, CA",
            value = "9412110",
        ),
        schema.Option(
            display = "San Diego, CA",
            value = "9410170",
        ),
        schema.Option(
            display = "San Francisco, CA",
            value = "9414290",
        ),
        schema.Option(
            display = "Santa Barbara, CA",
            value = "9411340",
        ),
        schema.Option(
            display = "Santa Monica, CA",
            value = "9410840",
        ),
        schema.Option(
            display = "New Orleans, LA",
            value = "8761927",
        ),
        schema.Option(
            display = "Panama City, FL",
            value = "8729108",
        ),
        schema.Option(
            display = "Tampa, FL",
            value = "8726607",
        ),
        schema.Option(
            display = "Miami, FL",
            value = "8723214",
        ),
        schema.Option(
            display = "Honolulu, HI",
            value = "1612340",
        ),
        schema.Option(
            display = "Boston, MA",
            value = "8443970",
        ),
        schema.Option(
            display = "Annapolis, MD",
            value = "8575512",
        ),
        schema.Option(
            display = "Baltimore, MD",
            value = "8574680",
        ),
        schema.Option(
            display = "Portland, ME",
            value = "8418150",
        ),
        schema.Option(
            display = "Atlantic City, NJ",
            value = "8534720",
        ),
        schema.Option(
            display = "New York, NY",
            value = "8518750",
        ),
        schema.Option(
            display = "Astoria, OR",
            value = "9439040",
        ),
        schema.Option(
            display = "Charleston, SC",
            value = "8665530",
        ),
        schema.Option(
            display = "Galvetson, TX",
            value = "8771450",
        ),
        schema.Option(
            display = "Port Townsend, WA",
            value = "9444900",
        ),
        schema.Option(
            display = "Tacoma, WA",
            value = "9446484",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "NOAA Station",
                icon = "water",
                default = options[0].value,
                options = options,
            ),
            schema.Text(
                id = "stationid",
                name = "Station ID",
                desc = "NOAA Station ID",
                icon = "water",
            ),
        ],
    )

def get_tide_data(stationId, date, interval):
    url = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?begin_date=%s&end_date=%s&station=%s&product=predictions&datum=MLLW&time_zone=lst_ldt&interval=%s&units=english&application=DataAPI_Sample&format=json" % (date, date, stationId, interval)

    data = cache.get("%s-%s" % (stationId, date))
    if data != None:
        data = json.decode(data)
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling tide API: %s" % url)
        response = http.get(url)
        if response.status_code != 200 or "error" in response.json():
            print("tide request failed with status %d" % response.status_code)
            return None
        data = response.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("%s-%s" % (stationId, date), response.body(), ttl_seconds = 86400)

    return data

def get_date(current_offset_time):
    return current_offset_time.format("20060102")

def get_data_points(today):
    data_points = []
    max = 0
    min = 0

    for p in today["predictions"]:
        time = p["t"][11:].split(":")
        hours = int(time[0]) + (int(time[1]) / 60)
        value = float(p["v"])
        data_points.append((hours, value))
        if value > max:
            max = value
        if value < min:
            min = value

    return {"points": data_points, "max_val": max, "min_val": min}

def get_current_state(data, current_time):
    current = None
    next = None
    for p in data["predictions"]:
        if p["t"][11:] < current_time.format("15:04"):
            current = p["v"]
        elif next == None:
            next = p["v"]

    if current > next:
        return "%s Receding" % current
    else:
        return "%s Rising" % current

def calculate_hours(timestamp):
    time = timestamp.split(":")
    return int(time[0]) + (int(time[1]) / 60)

def get_station_timezone(id):
    url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/%s.json" % id
    zone = cache.get(id)
    if zone != None:
        print("Hit! Displaying cached data.")
        return zone
    else:
        print("Miss! Calling station API: %s" % url)
        response = http.get(url)
        if response.status_code != 200:
            print("station request failed with status %d" % response.status_code)
            return None
        zone = response.json()["stations"][0]["timezone"]
        if zone in TIMEZONE_MAP:
            tz = TIMEZONE_MAP[zone]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(id, str(tz), ttl_seconds = 86400)
            return tz
        else:
            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(id, str("unsupported_timezone:%s" % zone), ttl_seconds = 86400)
            return "unsupported_timezone:%s" % zone

def station_not_found(stationId):
    return render.Root(
        child = render.Row(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.WrappedText(
                    content = "Unknown station: %s" % stationId,
                    align = "center",
                ),
            ],
        ),
    )

def station_returned_nodata(stationId):
    return render.Root(
        child = render.Row(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.WrappedText(
                    content = "Station %s returned no tide data!" % stationId,
                    align = "center",
                ),
            ],
        ),
    )

def unsupported_timezone(stationId, timezone):
    return render.Root(
        child = render.Row(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.WrappedText(
                    content = "Unsupported station timezone: %s (%s)" % (stationId, timezone),
                    align = "center",
                ),
            ],
        ),
    )
