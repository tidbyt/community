"""
Applet: RAA Fuel Watch
Summary: Shows petrol prices
Description: Enter your location and fuel type, then find the cheapest fuel in a 5km radius.
Author: M0ntyP
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_PREFIX = "https://our.raa.com.au/assets/ajax/FuelPricesService.ashx?op=GetStationsByRadius&"

DEFAULT_LOCATION = """
{
    "lat": "-34.8789633",
    "lng": "138.5369358",
    "description": "Woodville, SA, Australia",
	"locality": "Woodville",
	"timezone": "Australia/Adelaide"
}
"""

def main(config):
    LocationDetails = config.get("location", DEFAULT_LOCATION)
    FuelType = config.get("FuelType", "2")
    Price = ""
    # LastUpdated = ""

    DecodeLoc = json.decode(LocationDetails)
    Lat = DecodeLoc["lat"]
    Long = DecodeLoc["lng"]
    #print(Lat)
    #print(Long)

    API_CALL = API_PREFIX + "Lon=" + str(Long) + "&" + "Lat=" + str(Lat) + "&Radius=5" + "&Brand=&FuelType=" + FuelType + "&Sort=true"

    Cached = get_cachable_data(API_CALL, 300)
    FuelData = json.decode(Cached)

    Outlet = FuelData["Result"][0]["name"]
    Fuel = FuelData["Result"][0]["fuel"]

    for z in range(0, len(Fuel), 1):
        if int(FuelType) == Fuel[z]["type_id"]:
            Price = Fuel[z]["price"]
            #LastUpdated = Fuel[z]["updated_at"]

    # if LastUpdated != "":
    #    LastUpdated = LastUpdated[:16]
    #    LastUpdated_Format = time.parse_time(LastUpdated, format = "2006-01-02T15:04")
    #   Diff = time.now() - LastUpdated_Format

    # print(Outlet)
    # print(Price)
    # print(int(Diff.minutes))

    mainFont = "CG-pixel-3x5-mono"
    priceFont = "Dina_r400-6"
    Price = "$" + str(Price)
    ListFuel = Type_to_Fuel(FuelType)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            main_align = "start",
            cross_align = "start",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 7, color = "#fee600", child = render.Text(content = "RAA FUEL WATCH", color = "#000", font = mainFont)),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 1, color = "#000"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Marquee(width = 64, height = 10, child = render.Text(content = Outlet, color = "#FFF", font = mainFont)),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 12, color = "#000", child = render.Text(content = Price, color = "#48a800", font = priceFont)),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 10, color = "#000", child = render.Text(content = ListFuel, color = "#FFF", font = mainFont)),
                    ],
                ),
            ],
        ),
    )

def Type_to_Fuel(type_id):
    Type = ""

    if type_id == "2":
        Type = "Unleaded 91"
    elif type_id == "5":
        Type = "Premium 95"
    elif type_id == "8":
        Type = "Premium 98"
    elif type_id == "3":
        Type = "Diesel"
    elif type_id == "4":
        Type = "LFG"
    elif type_id == "12":
        Type = "e10"
    elif type_id == "19":
        Type = "e85"
    else:
        Type = ""

    return Type

FuelOptions = [
    schema.Option(
        display = "Unleaded 91",
        value = "2",
    ),
    schema.Option(
        display = "Premium Unleaded 95",
        value = "5",
    ),
    schema.Option(
        display = "Premium Unleaded 98",
        value = "8",
    ),
    schema.Option(
        display = "Diesel",
        value = "3",
    ),
    schema.Option(
        display = "LPG",
        value = "4",
    ),
    schema.Option(
        display = "e10",
        value = "12",
    ),
    schema.Option(
        display = "e85",
        value = "19",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Enter Location",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "FuelType",
                name = "Select the fuel type",
                desc = "Select the fuel type",
                icon = "gear",
                default = FuelOptions[0].value,
                options = FuelOptions,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
