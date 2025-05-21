"""
Applet: Denser BART
Summary: Shows more BART routes
Description: Like the official BART applet but shows up to 8 routes for a station.
Author: scoobmx
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

PREDICTIONS_URL = "https://api.bart.gov/api/etd.aspx"
STATIONS_URL = "https://api.bart.gov/api/stn.aspx"
DEFAULT_ABBR = "WOAK"
DEFAULT_KEY = "MW9S-E7SL-26DU-VV8V"
DECRYPT_KEY = "AV6+xWcEvAmJupxlFpNntfXPgT8ZeyIa0i/IID7UjyanaDbzrSwtt/aaPlx4/Rq4ElmV2e1VpXNjlFqk3szZYsznTluhr23AalHk3DxTgsC1M4BObGZOvKnu5r2a+j/Fps1XzTFwIZ5Zcu3jXREe/SRwhAZo1IazKg=="

def main(config):
    api_key = config.get("api_key")
    if api_key == "":
        api_key = secret.decrypt(DECRYPT_KEY)
    if api_key == None:
        api_key = DEFAULT_KEY

    abbr = config.get("abbr")
    if abbr == None:
        abbr = DEFAULT_ABBR

    viz = config.bool("long_abbr")

    predictions = get_times(abbr, api_key)
    num_routes = len(predictions)

    if num_routes == 0:
        return render.Root(
            child = render.Box(
                child = render.Text("No Data", font = "6x13", color = "#fff"),
            ),
        )
    elif num_routes < 5:
        # Show a single column
        train_rows = []
        for i in range(0, num_routes):
            if len(predictions[i]["estimate"]) == 0:
                continue
            train_rows.append(
                render.Row(
                    main_align = "center",
                    cross_align = "end",
                    expanded = True,
                    children = get_element_viz(predictions[i], True) if viz else get_element(predictions[i], True),
                ),
            )
        return render.Root(
            delay = 250 if viz else 125,
            child = render.Box(
                height = 32,
                width = 64,
                child = render.Column(
                    main_align = "space_between",
                    cross_align = "start",
                    expanded = True,
                    children = train_rows,
                ),
            ),
        )

    else:
        # Show dual columns
        train_rows = []
        num_rows = (num_routes + 1) // 2
        i = 0
        for _ in range(0, num_rows):
            if len(predictions[i]["estimate"]) == 0:
                i += 1
                continue
            left = []
            if i < num_routes:
                left = get_element_viz(predictions[i], False) if viz else get_element(predictions[i], False)
            i += 1
            right = []
            if i < num_routes:
                right = get_element_viz(predictions[i], False) if viz else get_element(predictions[i], False)
            i += 1
            train_rows.append(
                render.Row(
                    main_align = "space_around",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 8,
                            width = 30,
                            child = render.Row(
                                main_align = "start",
                                cross_align = "end",
                                expanded = True,
                                children = left,
                            ),
                        ),
                        render.Box(
                            height = 8,
                            width = 30,
                            child = render.Row(
                                main_align = "start",
                                cross_align = "end",
                                expanded = True,
                                children = right,
                            ),
                        ),
                    ],
                ),
            )
        return render.Root(
            delay = 250 if viz else 125,
            child = render.Box(
                height = 32,
                width = 64,
                child = render.Column(
                    main_align = "space_between",
                    cross_align = "start",
                    expanded = True,
                    children = train_rows,
                ),
            ),
        )

def get_element(etd, wide):
    element = []

    # Line colored box with first 2 letters of route abbreviation
    element.append(
        render.Box(
            width = 1,
            height = 7,
            color = etd["estimate"][0]["hexcolor"],
        ),
    )
    element.append(
        render.Box(
            width = 15 if wide else 10,
            height = 7,
            color = etd["estimate"][0]["hexcolor"],
            child = render.Text(etd["abbreviation"][:3] if wide else etd["abbreviation"][:2], color = "#111", font = "CG-pixel-4x5-mono"),
        ),
    )
    element.append(
        render.Box(
            width = 1,
            height = 7,
        ),
    )
    text = ""
    for i in range(0, len(etd["estimate"])):
        if (i > 0):
            text += ","
        string = etd["estimate"][i]["minutes"]

        # Replace the long "Leaving" string with 0
        if string == "Leaving":
            text += "0"
        else:
            text += string

    #text += ".  " + text + "."
    element.append(
        render.Marquee(
            width = 45 if wide else 18,
            align = "end",
            offset_start = 15,
            child = render.Text(text, color = "#fff"),
        ),
    )
    return element

def get_element_viz(etd, wide):
    element = []

    # Line colored box with 4 letters of route abbreviation
    element.append(
        render.Box(
            width = 1,
            height = 7,
            color = etd["estimate"][0]["hexcolor"],
        ),
    )
    element.append(
        render.Box(
            width = 20 if wide else 15,
            height = 7,
            color = etd["estimate"][0]["hexcolor"],
            child = render.Text(etd["abbreviation"] if wide else etd["abbreviation"][:3], color = "#111", font = "CG-pixel-4x5-mono"),
        ),
    )
    element.append(
        render.Box(
            width = 1,
            height = 8,
        ),
    )
    stack = []
    stack2 = []
    colors = [etd["estimate"][0]["hexcolor"], "#bbb", "#777", "#444"]
    j = 0
    for i in range(0, len(etd["estimate"])):
        string = etd["estimate"][i]["minutes"]
        if string == "Leaving":
            continue
        minutes = int(string)
        container = []
        layer = []
        if minutes // 7:
            container.append(
                render.Box(
                    width = minutes // 7,
                    height = 7,
                    color = colors[j],
                ),
            )
        if minutes % 7:
            container.append(
                render.Box(
                    width = 1,
                    height = minutes % 7,
                    color = colors[j],
                ),
            )
        if (minutes - 1) // 7:
            layer.append(
                render.Box(
                    width = (minutes - 1) // 7,
                    height = 7,
                ),
            )
        if (minutes - 1) % 7:
            layer.append(
                render.Column(
                    main_align = "start",
                    children = [
                        render.Box(
                            width = 1,
                            height = (minutes - 1) % 7,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = "#fff",
                        ),
                    ],
                ),
            )
        else:
            layer.append(
                render.Column(
                    main_align = "start",
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = "#fff",
                        ),
                    ],
                ),
            )
        j += 1
        stack.insert(0, render.Row(children = container, main_align = "start", cross_align = "start"))
        stack2.insert(0, render.Row(children = layer, main_align = "start", cross_align = "start"))
    stack.insert(0, render.Box(width = 40 if wide else 13, height = 7))
    element.append(
        render.Animation(
            children = [
                render.Stack(
                    children = stack,
                ),
                render.Stack(
                    children = stack + stack2,
                ),
            ],
        ),
    )
    return element

def get_times(station, api_key):
    rep = http.get(PREDICTIONS_URL, params = {"cmd": "etd", "json": "y", "orig": station, "key": api_key}, ttl_seconds = 10)
    if rep.status_code != 200:
        return []
    data = rep.json()
    if "root" not in data or "station" not in data["root"] or len(data["root"]["station"]) == 0 or data["root"]["station"][0]["abbr"] != station or "etd" not in data["root"]["station"][0]:
        predictions = []
    else:
        predictions = data["root"]["station"][0]["etd"]

    return predictions

def get_stations(api_key):
    if api_key == "":
        api_key = secret.decrypt(DECRYPT_KEY)
    if api_key == None:
        api_key = DEFAULT_KEY
    rep = http.get(STATIONS_URL, params = {"cmd": "stns", "json": "y", "key": api_key}, ttl_seconds = 30)
    if rep.status_code != 200:
        return []
    data = rep.json()
    if "root" not in data or "stations" not in data["root"] or "station" not in data["root"]["stations"]:
        return []
    stationlist = data["root"]["stations"]["station"]
    stations = []
    for i in range(0, len(stationlist)):
        stations.append(
            schema.Option(
                value = stationlist[i]["abbr"],
                display = stationlist[i]["name"],
            ),
        )

    return stations

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "Optional BART legacy API key",
                icon = "key",
                default = "",
            ),
            schema.Dropdown(
                id = "abbr",
                name = "Station",
                desc = "Station to show times for",
                icon = "trainSubway",
                default = DEFAULT_ABBR,
                options = get_stations(""),
            ),
            schema.Toggle(
                id = "long_abbr",
                name = "Visual timers",
                desc = "Show longer station abbreviations and visualize times",
                icon = "gear",
                default = False,
            ),
        ],
    )
