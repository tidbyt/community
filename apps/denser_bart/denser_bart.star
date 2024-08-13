"""
Applet: Denser BART
Summary: Shows more BART routes
Description: Like the official BART applet but shows up to 8 routes for a station.
Author: scoobmx
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

PREDICTIONS_URL = "https://api.bart.gov/api/etd.aspx"
STATIONS_URL = "https://api.bart.gov/api/stn.aspx"
DEFAULT_ABBR = "WOAK"
DEFAULT_KEY = "MW9S-E7SL-26DU-VV8V"

def main(config):
    abbr = config.get("abbr")
    if abbr == None:
	abbr = DEFAULT_ABBR
    
    predictions = get_times(abbr, DEFAULT_KEY)
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
                    children = get_element(predictions[i], 50)
                )
            )
        return render.Root(
            delay = 100,
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
        for j in range(0, num_rows):
	    if len(predictions[i]["estimate"]) == 0:
		i += 1
		continue
	    left = []
	    if i < num_routes:
		left = get_element(predictions[i], 18)
	    i += 1
	    right = []
	    if i < num_routes:
		right = get_element(predictions[i], 18)
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
                    		children = left
			    )
                        ),
			render.Box(
                            height = 8,
                            width = 30,
			    child = render.Row(
				main_align = "start",
                    		cross_align = "end",
                    		expanded = True,
                    		children = right
			    )
                        ),
                    ]
                )
            )
        return render.Root(
            delay = 100,
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

def get_element(etd, size):
    element = []
    # Line colored box with first 2 letters of route abbreviation
    element.append(
        render.Box(
            width = 1,
	    height = 7,
	    color = etd["estimate"][0]["hexcolor"],
        )
    )
    element.append(
        render.Box(
            width = 10,
	    height = 7,
	    color = etd["estimate"][0]["hexcolor"],
            child = render.Text(etd["abbreviation"][:2], color = "#111", font = "CG-pixel-4x5-mono"),
        )
    )
    element.append(
        render.Box(
            width = 1,
	    height = 7,
        )
    )
    text = ""
    for i in range(0, len(etd["estimate"])):
	if (i > 0):
	    text += ", "
	string = etd["estimate"][i]["minutes"]
	# Replace the long "Leaving" string with just a dash
	if string == "Leaving":
	    text += "-"
	else:
	    text += string
    element.append(
        render.Marquee(
            width = size,
	    align = "end",
            child = render.Text(text, color = "#fff"),
        )
    )
    return element

def get_times(station, api_key):
    rep = http.get(PREDICTIONS_URL, params = {"cmd": "etd", "json": "y", "orig": station, "key": api_key})
    if rep.status_code != 200:
        fail("Predictions request failed with status ", rep.status_code)
    data = rep.json()
    if "root" not in data or "station" not in data["root"] or len(data["root"]["station"]) == 0 or data["root"]["station"][0]["abbr"] != station or "etd" not in data["root"]["station"][0]:
        predictions = []
    else:
        predictions = data["root"]["station"][0]["etd"]

    return predictions

def get_stations(api_key):
    rep = http.get(STATIONS_URL, params = {"cmd": "stns", "json": "y", "key": api_key})
    if rep.status_code != 200:
        fail("Stations request failed with status ", rep.status_code)
    data = rep.json()
    stations = []
    if "root" not in data or "stations" not in data["root"] or "station" not in data["root"]["stations"]:
	fail("Stations request failed")
    stationlist = data["root"]["stations"]["station"]
    for i in range(0, len(stationlist)):
	stations.append(
	    schema.Option(
		value = stationlist[i]["abbr"],
		display = stationlist[i]["name"],
	    )
	)

    return stations

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "abbr",
                name = "Station",
                desc = "Station Abbreviation",
                icon = "clock",
                default = DEFAULT_ABBR,
                options = get_stations(DEFAULT_KEY),
            ),
        ],
    )