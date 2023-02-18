load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ttls = 60

def get_resp_stations():
    data = cache.get("data_stations")
    if not data:
        print("Stations data not cached")
        url = "https://gbfs.citibikenyc.com/gbfs/en/station_information.json"
        resp = http.get(url)
        data = resp.json()["data"]
        print("Response Stations: ", resp.status_code)
        cache.set("data_stations", json.encode(data), ttl_seconds = ttls)
    else:
        print("Station data cached")
        data = json.decode(data)
    print("Stations Data returning as", type(data))
    return data

def get_resp_bikes():
    data = cache.get("data_bikes")
    if not data:
        print("Bike Data not cached")
        url_bikes = "https://gbfs.citibikenyc.com/gbfs/en/station_status.json"
        resp = http.get(url_bikes)
        data = resp.json()["data"]["stations"]
        print("Response Availability: ", resp.status_code)
        cache.set("data_bikes", json.encode(data), ttl_seconds = ttls)
    else:
        print("Bikes data cached")
        data = json.decode(data)
    print("Bikes Data returning as", type(data))
    return data

w = 15
h = int(w * 0.75)
img_bike_src = """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"""

img_bike = render.Image(src = base64.decode(img_bike_src), width = w, height = h)

img_park_src = """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"""
img_park = render.Image(src = base64.decode(img_park_src), width = w, height = h)

############ STATION IDs
def pop_stations(data):
    dic = {}
    for s in data:
        dic.update({s["name"]: {"ext_id": s["external_id"], "leg_id": s["legacy_id"]}})
    return dict(sorted(dic.items()))

###########

def get_info(stat_name, type, bike_data, station_list):
    stat_ids = station_list[stat_name]
    leg_id = stat_ids["leg_id"]
    info = [i for i in bike_data if i["legacy_id"] == leg_id][0]
    docs_avail = int(info["num_docks_available"])
    bikes_avail = int(info["num_bikes_available"])
    res = {
        "docks": "  Docks: " + str(docs_avail),
        "bikes": "  Bikes: " + str(bikes_avail),
    }
    return res[type]

def get_col_children(stat_name, bike_data, station_list):
    l = []
    l.append(render.Marquee(child = render.Text(stat_name, color = "#45b6fe"), width = 70, scroll_direction = "horizontal"))
    l.append(render.Row(children = [img_bike, render.Text(get_info(stat_name, "bikes", bike_data, station_list))], cross_align = "center"))
    l.append(render.Row(children = [img_park, render.Text(get_info(stat_name, "docks", bike_data, station_list))], cross_align = "center"))
    l.append(render.Text(""))
    return l

def get_stat_col(stat_name, bike_data, station_list):
    l = get_col_children(stat_name, bike_data, station_list)
    return render.Column(children = l)

def get_col_list(bike_data, station_list):
    col_list = [get_stat_col(s, bike_data, station_list) for s in station_list]
    return col_list

def main(config):
    data_stat = get_resp_stations()
    station_ids = pop_stations(data_stat["stations"])
    data_bikes = get_resp_bikes()
    default = station_ids.keys()[0]
    def_str = '{"display":"%s","value":"%s"}' % (default, default)
    option = config.get("search_station", def_str)
    station = json.decode(option)

    station_name = station["value"]
    info = get_stat_col(station_name, data_bikes, station_ids)
    return render.Root(
        child = info,
        delay = 80,
    )

def search_station(pattern):
    data_stat = get_resp_stations()
    station_ids = pop_stations(data_stat["stations"])
    pattern = pattern.lower()
    return [schema.Option(value = s, display = s) for s in station_ids.keys() if pattern in (s.lower())]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "search_station",
                name = "Station",
                desc = "The station for which you need availability",
                icon = "gear",
                # default = options[0].value,
                # options = options,
                handler = search_station,
            ),
        ],
    )
