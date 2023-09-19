"""
Applet: Boulder BCycle
Summary: Boulder Bcycle availability
Description: Display how many BCycles are available for a given BCycle station in Boulder, Colorado. The user can choose which station they want to see bike availability for.
Author: MauricioZambrano
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("encoding/base64.star", "base64")

API_STATION_STATUS_URL = "https://gbfs.bcycle.com/bcycle_boulder/station_status.json"
API_STATION_INFORMATION_URL = "https://gbfs.bcycle.com/bcycle_boulder/station_information.json"

STRING_SEPARATOR = "/$*$/"
DEFAULT_STATION = "bcycle_boulder_4091" + STRING_SEPARATOR + "Timber Ridge @ Adams Circle"
COLORS = {
    "green": "#00FF00",
    "red": "#FF0000",
    "white": "#FFF",
    "black": "#000",
    "yellow": "#FFFF00",
    "aquamarine": "#7FFFD4",
}
ERROR_STRING = "ERR"

def getStationInfo():
    res = http.get(API_STATION_INFORMATION_URL, ttl_seconds = 12000)

    if res.status_code != 200:
        fail("API call failed with status %d", res.status_code)

    stations = res.json()["data"]["stations"]

    return stations

def getNumberBikes(station_id):
    res = http.get(API_STATION_STATUS_URL, ttl_seconds = 60)

    if res.status_code != 200:
        fail("API call failed with status %d", res.status_code)

    stations = res.json()["data"]["stations"]

    for station in stations:
        if station["station_id"] == station_id:
            return station["num_bikes_available"]

    return ERROR_STRING

def getTextColor(number):
    if number == ERROR_STRING:
        # In case number of bikes is not found, so ERR is printed
        return COLORS["white"]

    number = int(number)
    if number < 3:
        return COLORS["red"]
    elif number < 8:
        return COLORS["yellow"]
    else:
        return COLORS["green"]

def getIdAndName(config_string):
    return config_string.split(STRING_SEPARATOR)

def main(config):
    station_id, station_name = getIdAndName(config.get("station", DEFAULT_STATION))

    if not station_id or not station_name:
        fail("No station ID or station name found")
        return

    # Type parsing is a bit weird here so this is a quick hack
    available_bikes = str(int(getNumberBikes(station_id)))

    if not available_bikes:
        available_bikes = ERROR_STRING

    return render.Root(
        child = render.Row(
            expanded = True,
            children = [
                render.Column(
                    expanded = True,
                    children = [
                        render.Box(
                            width = 35,
                            color = COLORS["black"],
                            child = render.WrappedText(
                                content = station_name,
                                font = "tom-thumb",
                                color = COLORS["white"],
                            ),
                        ),
                    ],
                ),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 30,
                            color = config.get("color") or COLORS["aquamarine"],
                            child = render.Column(
                                main_align = "center",
                                cross_align = "center",
                                expanded = True,
                                children = [
                                    render.Circle(
                                        color = COLORS["black"],
                                        diameter = 14,
                                        child = render.Text(
                                            available_bikes,
                                            color = getTextColor(available_bikes),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    station_info = getStationInfo()

    options = []

    for station in station_info:
        string_value = station["station_id"] + STRING_SEPARATOR + station["name"]
        options.append(
            schema.Option(
                display = station["name"],
                value = string_value,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station Name",
                desc = "Name of the BCycle Station you want to track.",
                icon = "usersCog",
                default = DEFAULT_STATION,
                options = options,
            ),
            schema.Color(
                id = "color",
                name = "Background Color",
                desc = "Background color of the screen",
                icon = "brush",
                default = COLORS["aquamarine"],
            ),
        ],
    )
