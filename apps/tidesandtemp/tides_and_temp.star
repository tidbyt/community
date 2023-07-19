"""
Applet: Tides & Temp
Summary: Display tides / water temp
Description: Display predicted tides from NOAA tide stations and water temperature from NDBC buoy stations. See https://tidesandcurrents.noaa.gov/tide_predictions.html for NOAA tide station IDs. See https://www.ndbc.noaa.gov/obs.shtml for NDBC buoy station IDs.
Author: sudeepban
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

NOAA_TIDES_URL = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?station={station_id}&product=predictions&datum=MLLW&time_zone=gmt&interval=hilo&units=english&application=DataAPI_Sample&format=json&range=48&begin_date={begin_date}"
NOAA_TIDES_STATION_ID_DEFAULT = 8533071

NDBC_BUOY_URL = "https://www.ndbc.noaa.gov/data/realtime2/{station_id}.txt"
NDBC_BUOY_STATION_ID_DEFAULT = 44091

LOW_TIDE_COLOR_DEFAULT = "#088F8F"
HIGH_TIDE_COLOR_DEFAULT = "#1F51FF"
WATER_TEMPERATURE_COLOR_DEFAULT = "#EEDC82"

TIMEZONE_DEFAULT = "America/New_York"
TIMEZONE_GMT = "GMT"

DATE_FORMAT = "20060102"
DATETIME_FORMAT = "2006-01-02 15:04"
TIME_FORMAT = "03:04 PM"

def main(config):
    location = config.get("location")
    timezone = json.decode(location).get("timezone") if location else TIMEZONE_DEFAULT
    noaaTidesStationID = config.str("noaaTidesStationID", str(NOAA_TIDES_STATION_ID_DEFAULT))
    ndbcBuoyStationID = config.str("ndbcBuoyStationID", str(NDBC_BUOY_STATION_ID_DEFAULT))
    lowTideColor = config.str("lowTideColor", LOW_TIDE_COLOR_DEFAULT)
    highTideColor = config.str("highTideColor", HIGH_TIDE_COLOR_DEFAULT)
    waterTempColor = config.str("waterTempColor", WATER_TEMPERATURE_COLOR_DEFAULT)

    now = time.now().in_location(TIMEZONE_GMT)
    prevdate = (now - time.parse_duration("12h")).format(DATE_FORMAT)

    resp = http.get(NOAA_TIDES_URL.format(begin_date = prevdate, station_id = noaaTidesStationID), ttl_seconds = 3600)
    if resp.status_code != 200:
        fail("NOAA tides request failed with status", resp.status_code)

    resp_predictions = resp.json()["predictions"]
    data_predictions = []
    prev_tide = {}
    curr_tide_pct = None

    # Process NOAA predicted tides for the specified station ID
    # Extract previous high / low and next high / low to compute current estimated tide percentage
    # Extract next two high / low for display
    for resp_prediction in resp_predictions:
        prediction = {}
        prediction_time = time.parse_time(resp_prediction["t"], format = DATETIME_FORMAT, location = TIMEZONE_GMT).in_location(timezone)
        if prediction_time.unix - now.unix < 0:
            prev_tide["time"] = prediction_time
            prev_tide["height"] = float(resp_prediction["v"])
            water_temp = str(prev_tide["height"])
            continue

        if not curr_tide_pct:
            next_tide = {}
            next_tide["time"] = prediction_time
            next_tide["height"] = float(resp_prediction["v"])

            # Estimate current tide based on linear interpolation between previous high / low and next high / low
            slope = (next_tide["height"] - prev_tide["height"]) / (next_tide["time"].unix - prev_tide["time"].unix)
            curr_tide = prev_tide["height"] + slope * (now.unix - prev_tide["time"].unix)

            # Compute current tide percentage based on estimated current tide and previous / next high / low
            curr_tide_pct = int(100 * abs(curr_tide - min(next_tide["height"], prev_tide["height"])) / abs(next_tide["height"] - prev_tide["height"]))

        time_diff = prediction_time.unix - now.unix
        prediction["time"] = prediction_time.format(TIME_FORMAT)
        prediction["type"] = "HI" if resp_prediction["type"] == "H" else "LO"
        prediction["color"] = highTideColor if resp_prediction["type"] == "H" else lowTideColor
        prediction["hours"] = int(time_diff / 60 / 60)
        prediction["minutes"] = int((time_diff - prediction["hours"] * 60 * 60) / 60)

        data_predictions.append(prediction)
        if len(data_predictions) == 2:
            break

    disp_predictions = []

    disp_predictions.append(render.Box(height = 1, width = 1))
    for data_prediction in data_predictions:
        disp_predictions.append(render.Text(data_prediction["type"] + " " + data_prediction["time"], color = data_prediction["color"]))
        disp_predictions.append(render.Text(str(data_prediction["hours"]) + " hr " + str(data_prediction["minutes"]) + " min", font = "tom-thumb", color = "#ffffff"))
        disp_predictions.append(render.Box(height = 1, width = 1))

    resp = http.get(NDBC_BUOY_URL.format(station_id = ndbcBuoyStationID), ttl_seconds = 600)
    if resp.status_code != 200:
        fail("NDBC buoy request failed with status", resp.status_code)

    # Process NDBC buoy data for the specified station ID
    # Extract water temperature in Celsius and convert to Fahrenheit
    water_temp = int(9 / 5 * float(resp.body().splitlines()[2].split()[14]) + 32)

    img = base64.decode("""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""")

    return render.Root(
        delay = 350,
        child = render.Row(
            [
                render.Column(
                    children = disp_predictions,
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                ),
                render.Column(
                    children = [
                        render.Image(src = img, width = 20, height = 10),
                        # Variable box height based on current tide percentage
                        render.Box(height = 1 + int(16 * curr_tide_pct / 100), color = "#99ccff"),
                        render.Row(
                            children = [
                                render.Text(str(water_temp) + "F", color = waterTempColor, font = "tom-thumb"),
                                render.Box(height = 1, width = 1),
                            ],
                        ),
                    ],
                    main_align = "end",
                    cross_align = "end",
                    expanded = True,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for timezone",
                icon = "locationDot",
            ),
            schema.Text(
                id = "noaaTidesStationID",
                name = "NOAA Tides Station ID",
                desc = "Station ID for predicted tides",
                icon = "gear",
                default = str(NOAA_TIDES_STATION_ID_DEFAULT),
            ),
            schema.Text(
                id = "ndbcBuoyStationID",
                name = "NDBC Buoy Station ID",
                desc = "Station ID for water temperature",
                icon = "gear",
                default = str(NDBC_BUOY_STATION_ID_DEFAULT),
            ),
            schema.Color(
                id = "highTideColor",
                name = "High tide color",
                desc = "Color for the high tide time",
                icon = "brush",
                default = HIGH_TIDE_COLOR_DEFAULT,
            ),
            schema.Color(
                id = "lowTideColor",
                name = "Low tide color",
                desc = "Color for the low tide time",
                icon = "brush",
                default = LOW_TIDE_COLOR_DEFAULT,
            ),
            schema.Color(
                id = "waterTempColor",
                name = "Water temperature color",
                desc = "Color for the water temperature",
                icon = "brush",
                default = WATER_TEMPERATURE_COLOR_DEFAULT,
            ),
        ],
    )
