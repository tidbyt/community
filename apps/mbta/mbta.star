"""
Applet: MBTA
Summary: MBTA departures
Description: MBTA bus and rail departure times.
Author: marcusb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("secret.star", "secret")

URL = "https://api-v3.mbta.com/predictions"

API_KEY = secret.decrypt("AV6+xWcEFe8B+1zoMJpL7mvq/utSOtMw6qSGeCYZjUhKnv21BwCdrfQWjtr/mYvReXGmpd1Wf2SD+EjIZl+/Uh+VxTDZQhJpYqChzPvioRUmj2y6rnxTVuOl8llWXrShy9aXWkVFRsNRFuZ4XZre1Q4Mf6Qmd+DWNzVESSFONPh3Vv0Jieo=")

T_ABBREV = {
    "Orange": "OL",
    "Red": "RL",
    "Silver": "SL",
}

def main(config):
    option = config.get("stop", '{"display": "South Station", "value": "place-sstat"}')
    stop = json.decode(option)
    mintime = config.get("mintime", "0")

    params = {
        "sort": "arrival_time",
        "include": "route",
        "filter[stop]": stop["value"],
    }
    if API_KEY:
        params["api_key"] = API_KEY
    rep = http.get(URL, params = params)
    if rep.status_code != 200:
        fail("MBTA API request failed with status {}".format(rep.status_code))

    rows = []
    predictions = [
        p
        for p in rep.json()["data"]
        if p["attributes"]["schedule_relationship"] != "SKIPPED"
    ]
    for prediction in predictions:
        route = prediction["relationships"]["route"]["data"]["id"]
        route = find(rep.json()["included"], lambda o: o["type"] == "route" and o["id"] == route)
        r = renderSched(prediction, route)
        if r:
            tm = prediction["attributes"]["arrival_time"] or prediction["attributes"]["departure_time"]
            t = time.parse_time(tm)
            arr = t - time.now()
            if arr.minutes >= float(mintime):
                rows.extend(r)
                rows.append(render.Box(height = 1, width = 64, color = "#ccffff"))

    if rows:
        return render.Root(
            child = render.Column(children = rows[:3], main_align = "start"),
        )
    else:
        return render.Root(
            child = render.Marquee(
                width = 64,
                child = render.Text(
                    content = "No current departures",
                    height = 8,
                    offset = -1,
                    font = "Dina_r400-6",
                ),
            ),
        )

def renderSched(prediction, route):
    attrs = prediction["attributes"]
    if not attrs["departure_time"]:
        return []
    tm = attrs["arrival_time"] or attrs["departure_time"]
    t = time.parse_time(tm)
    arr = t - time.now()
    if arr.minutes < 0:
        return []
    dest = route["attributes"]["direction_destinations"][int(attrs["direction_id"])].upper()
    minutes = int(arr.minutes)
    short_name = route["attributes"]["short_name"] or T_ABBREV.get(route["id"], "")
    msg = "{} min".format(minutes) if minutes else "Now"
    first_line = dest
    if attrs["status"]:
        first_line = render.Row(
            children = [
                render.Text(
                    content = dest + " \\u00b7 ",
                    height = 8,
                    offset = -1,
                    font = "Dina_r400-6",
                ),
                render.Text(
                    content = attrs["status"],
                    height = 8,
                    offset = -1,
                    font = "Dina_r400-6",
                    color = "#df000f",
                ),
            ],
        )
    else:
        first_line = render.Text(
            content = dest,
            height = 8,
            offset = -1,
            font = "Dina_r400-6",
        )
    return [render.Row(
        main_align = "space_between",
        children = [
            render.Stack(
                children = [
                    render.Circle(
                        diameter = 12,
                        color = "#{}".format(route["attributes"]["color"] or "ffc72c"),
                        child = render.Text(
                            content = short_name,
                            color = "#{}".format(route["attributes"]["text_color"] or "000"),
                            font = "CG-pixel-3x5-mono" if len(short_name) > 2 else "tb-8",
                        ),
                    ),
                ],
            ),
            render.Box(width = 2, height = 5),
            render.Column(
                main_align = "start",
                cross_align = "left",
                children = [
                    render.Marquee(
                        width = 50,
                        child = first_line,
                    ),
                    render.Text(
                        content = msg,
                        height = 8,
                        offset = -1,
                        font = "Dina_r400-6",
                        color = "#ffd11a",
                    ),
                ],
            ),
        ],
        cross_align = "center",
    )]

def find(xs, pred):
    for x in xs:
        if pred(x):
            return x
    return None

def get_stops(location):
    loc = json.decode(location)
    params = {
        "page[limit]": "100",
        "filter[latitude]": loc["lat"],
        "filter[longitude]": loc["lng"],
        "sort": "distance",
    }
    if API_KEY:
        params["api_key"] = API_KEY

    rep = http.get("https://api-v3.mbta.com/stops", params = params)
    if rep.status_code != 200:
        fail("MBTA API request failed with status {}".format(rep.status_code))
    data = rep.json()
    stops = []
    for s in data["data"]:
        if s["type"] != "stop":
            continue
        if s["relationships"]["parent_station"]["data"]:
            continue
        stops.append(schema.Option(
            display = s["attributes"]["name"],
            value = s["id"],
        ))
    return stops

def get_schema():
    options = [
        schema.Option(display = "0 minutes", value = "0"),
        schema.Option(display = "1 minutes", value = "1"),
        schema.Option(display = "2 minutes", value = "2"),
        schema.Option(display = "3 minutes", value = "3"),
        schema.Option(display = "4 minutes", value = "4"),
        schema.Option(display = "5 minutes", value = "5"),
        schema.Option(display = "6 minutes", value = "6"),
        schema.Option(display = "7 minutes", value = "7"),
        schema.Option(display = "8 minutes", value = "8"),
        schema.Option(display = "9 minutes", value = "9"),
        schema.Option(display = "10 minutes", value = "10"),
        schema.Option(display = "15 minutes", value = "15"),
        schema.Option(display = "20 minutes", value = "20"),
        schema.Option(display = "25 minutes", value = "25"),
        schema.Option(display = "30 minutes", value = "30"),
        schema.Option(display = "45 minutes", value = "45"),
        schema.Option(display = "60 minutes", value = "60"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "stop",
                name = "Stop",
                desc = "The stop or station name.",
                icon = "bus",
                handler = get_stops,
            ),
            schema.Dropdown(
                id = "mintime",
                name = "Show arriving in",
                desc = "Minimum arrival time.",
                icon = "bus",
                default = options[0].value,
                options = options,
            ),
        ],
    )
