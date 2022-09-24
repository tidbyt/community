"""
Applet: NOAA Tides
Summary: Display NOAA Tides
Description: Display daily tides from NOAA stations.
Author: tavdog
"""

production = True
debug = False
print_debug = False

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("xpath.star", "xpath")
load("re.star", "re")
load("humanize.star", "humanize")

default_location = """
  {
	"lat": "20.89",
	"lng": "-156.50",
	"description": "Wailuku, HI, USA",
	"locality": "Maui",
	"timezone": "America/Honolulu"
}
"""

def debug_print(arg):
    if print_debug:
        print(arg)

def get_stations(location):  # assume we have a valid location dict
    location = json.decode(location)

    stations_json = {}
    station_options = list()
    url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/tidepredstations.json?lat=%s&lon=%s&radius=50" % (humanize.float("#.##", float(location["lat"])), humanize.float("#.##", float(location["lng"])))
    debug_print(url)
    if not debug:
        req_result = http.get(url)
        if req_result.status_code == 200:
            stations_json = req_result.body()
    else:
        stations_json = """{
  "stationList": [
    {
      "name": "KAHULUI, KAHULUI HARBOR",
      "state": "HI",
      "region": "Maui Island",
      "timeZoneCorr": "-10",
      "stationName": "Kahului, Kahului Harbor",
      "commonName": "Kahului, Kahului Harbor",
      "distance": 1.5085605251089405,
      "stationFullName": "KAHULUI, KAHULUI HARBOR, MAUI ISLAND",
      "etidesStnName": "KAHULUI",
      "stationId": "1615680",
      "lat": 20.895,
      "lon": -156.4766944444444,
      "refStationId": null,
      "stationType": "R",
      "parentGeoGroupId": "1734",
      "seq": "0",
      "geoGroupId": "1734",
      "geoGroupName": null,
      "level": "7",
      "geoGroupType": "ETIDES",
      "abbrev": null
    },
    {
      "name": "Kihei, Maalaea Bay",
      "state": null,
      "region": "Maui Island",
      "timeZoneCorr": "-10",
      "stationName": "Kihei, Maalaea Bay",
      "commonName": "Kihei, Maalaea Bay",
      "distance": 7.714681369437793,
      "stationFullName": "KIHEI, MAALAEA BAY",
      "etidesStnName": "Kihei, Maalaea Bay",
      "stationId": "TPT2797",
      "lat": 20.78333333333299,
      "lon": -156.46666666667008,
      "refStationId": null,
      "stationType": "S",
      "parentGeoGroupId": "1734",
      "seq": "3",
      "geoGroupId": "1734",
      "geoGroupName": null,
      "level": "7",
      "geoGroupType": "ETIDES",
      "abbrev": null
    }
  ]
  }"""
    stations = json.decode(stations_json)

    if "stationList" in stations and stations["stationList"] != None:
        stations = stations["stationList"]
        debug_print("Found %s stations" % len(stations))
        for station in stations:
            #debug_print("%s : %s" % (station["stationId"],station["name"]))
            station_options.append(
                schema.Option(
                    display = station["name"],
                    value = station["stationId"],
                ),
            )
    else:
        debug_print("no stations in json")
        station_options.append(
            schema.Option(
                display = "No Results",
                value = "",
            ),
        )

    return station_options

# return decode json object of tide data
def get_tides(station_id):
    tides = {}
    url = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&date=today&range=48&datum=MLLW&station=%s&time_zone=LST_LDT&units=english&interval=hilo&format=json&application=NOS.COOPS.TAC.TidePred"
    url = url % (station_id)
    debug_print("Url : " + url)
    if not debug:
        resp = http.get(url)
        if resp.status_code != 200:
            return None
        else:
            tides = json.decode(resp.body())
            debug_print(tides)
    else:
        tides_json = """{"predictions": [{"t": "2022-03-04 05:00", "v": "1.630", "type": "H"}, {"t": "2022-03-04 11:05", "v": "0.032", "type": "L"}, {"t": "2022-03-04 17:10", "v": "1.285", "type": "H"}, {"t": "2022-03-04 22:52", "v": "0.058", "type": "L"}]}"""
        tides = json.decode(tides_json)
    return tides

def main(config):
    debug_print("############################################################")
    data = dict()
    units_pref = config.get("h_units", "feet")
    time_format = config.get("time_format", "24HR")
    units = "ft"
    station_id = config.get("station_id", "")
    debug_print("station id from config.get: " + station_id)
    if station_id == "none" or station_id == "" or not station_id:  # if manual input is empty load from local selection
        debug_print("getting local_station_id")
        if production:
            local_selection = config.get("local_station_id", '{"display": "Station 1613198 - Example", "value": "1613198"}')  # default is
        else:
            local_selection = config.get("local_station_id", "1613198")  # default is Waimea

        if local_selection == "None Found":
            local_selection = "1613198"  # config.get bug ?
        debug_print("Local selection : " + local_selection)

        # this is needed for locationbased selection in production environment
        if "value" in local_selection:
            station_id = json.decode(local_selection)["value"]
        else:
            station_id = local_selection  # san fran

    debug_print("using station_id: " + station_id)

    # CACHINE CODE
    tides = {}
    cache_key = "noaa_tides_%s" % (station_id)
    cache_str = cache.get(cache_key)  #  not actually a json object yet, just a string
    if cache_str != None:
        debug_print("loading cached data")
        tides = json.decode(cache_str)

    if len(tides) == 0:
        debug_print("pulling fresh tide data")
        tides = get_tides(station_id)

        if tides != None:
            cache.set(cache_key, json.encode(tides), ttl_seconds = 14400)  # 4 hours minutes

    color_low = config.get("low_color", "#F00")  #cyanish
    color_high = config.get("high_color", "#0FF")

    line_color = color_low
    lines = list()
    lines_left = list()
    lines_right = list()
    if tides and "predictions" in tides:
        for pred in tides["predictions"]:
            if units_pref == "meters":
                v = int((float(pred["v"]) / 3 + 0.05) * 10) / 10.0  # round to 1 decimal
                units = "m"
            else:
                v = int((float(pred["v"]) + 0.05) * 10) / 10.0  # round to 1 decimal

            if v > 9:
                # chop off the decimal if we've got a huge tide
                v = int(v)
            t = pred["t"][11:]  # strip the date from the front = start to first occurence of a space
            if time_format == "AMPM":
                m = "a"
                hr = int(t[0:2])
                mn = t[3:5]
                if hr > 12:
                    m = "p"
                    hr = hr - 12
                if hr < 10:  # pad a space
                    hr = "0" + str(hr)

                left_side = "%s %s:%s%s" % (pred["type"], hr, mn, m)
                right_side = "%s%s" % (v, units)
            else:
                left_side = "%s %s" % (pred["type"], t)
                right_side = "%s%s" % (v, units)
            if "H" in pred["type"]:
                line_color = color_high
            else:
                line_color = color_low

            lines.append(
                render.Row(
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "start",
                            children = [render.Text(
                                content = left_side,
                                font = "tb-8",
                                color = line_color,
                            )],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "end",
                            children = [render.Text(
                                content = right_side,
                                font = "tb-8",
                                color = line_color,
                            )],
                        ),
                    ],
                ),
            )
    else:  # render an error message
        lines.append(render.WrappedText(
            content = "Invalid Station ID",
            font = "tb-8",
            color = "#FF0000",
            align = "center",
        ))
    return render.Root(
        child = render.Box(
            render.Column(
                main_align = "left",
                children = lines,
            ),
        ),
    )

COLOR_LIST = {
    "White": "#fff",
    "Red": "#a00",
    "Green": "#0a0",
    "Blue": "#00a",
    "Cyan": "#0ff",
    "Orange": "#D2691E",
}

def get_schema():
    colors = [
        schema.Option(display = key, value = value)
        for key, value in COLOR_LIST.items()
    ]
    h_unit_options = [
        schema.Option(display = "feet", value = "feet"),
        schema.Option(display = "meters", value = "meters"),
    ]
    time_formats = [
        schema.Option(display = "24HR", value = "24HR"),
        schema.Option(display = "AM/PM", value = "AMPM"),
    ]
    fields = []
    if not production:
        stations_list = get_stations(json.decode(default_location))  # locationbased schema don't work so use default loaction
        fields.append(
            schema.Dropdown(
                id = "local_station_id",
                name = "Local Tide Station",
                icon = "monument",
                desc = "Debug Location Stations",
                options = stations_list,
                default = "None Found",
            ),
        )
    else:  # in production, locationbased schema fields work
        fields.append(
            schema.LocationBased(
                id = "local_station_id",
                name = "Local Tide Station",
                icon = "monument",
                desc = "Location Based Stations",
                handler = get_stations,
            ),
        )
    fields.append(
        schema.Text(
            id = "station_id",
            name = "Station ID - optional",
            icon = "monument",
            desc = "",
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "high_color",
            name = "High Tide Color",
            icon = "brush",
            desc = "The color to use for high tides.",
            default = colors[0].value,
            options = colors,
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "low_color",
            name = "Low Tide Color",
            icon = "brush",
            desc = "The color to use for low tides.",
            default = colors[3].value,
            options = colors,
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "time_format",
            name = "Time Format",
            icon = "quoteRight",
            desc = "Use AM/PM or 24 hour time",
            options = time_formats,
            default = "24HR",
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "h_units",
            name = "Height Units",
            icon = "quoteRight",
            desc = "Tide height units preference",
            options = h_unit_options,
            default = "feet",
        ),
    )
    return schema.Schema(
        version = "1",
        fields = fields,
    )
