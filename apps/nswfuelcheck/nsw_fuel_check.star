"""
Applet: NSW Fuel Check
Summary: Shows NSW fuel prices
Description: Enter your location and fuel type, then find the cheapest fuel in a 3km radius.
Author: M0ntyP

v1.1
Added more fuel types
Changed fuel icon
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_PREFIX = "https://api.onegov.nsw.gov.au/FuelCheckApp/v1/fuel/prices/bylocation?"

DEFAULT_LOCATION = """
{
    "lat": "-33.9082007",
    "lng": "151.1815529",
    "description": "Alexandria, NSW, Australia",
	"locality": "Alexandria",
	"timezone": "Australia/Sydney"
}
"""

def main(config):
    LocationDetails = config.get("location", DEFAULT_LOCATION)
    FuelType = config.get("FuelType", "U91")
    Price = ""

    DecodeLoc = json.decode(LocationDetails)
    Lat = DecodeLoc["lat"]
    Long = DecodeLoc["lng"]

    API_CALL = API_PREFIX + "Latitude=" + str(Lat) + "&" + "Longitude=" + str(Long) + "&fueltype=" + FuelType + "&brands=SelectAll&radius=3"

    #print(API_CALL)
    Cached = get_cachable_data(API_CALL, 300)
    FuelData = json.decode(Cached)

    Outlet = FuelData[0]["Name"]
    Price = FuelData[0]["Price"]
    ListFuel = Type_to_Fuel(FuelType)

    mainFont = "CG-pixel-3x5-mono"
    priceFont = "Dina_r400-6"
    Price = "$" + str(Price)

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
                        render.Box(width = 64, height = 7, color = "#147cbb", child = render.Text(content = "NSW FUEL CHECK", color = "#fff", font = mainFont)),
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
                        Outlet_Name(Outlet),
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

def Outlet_Name(Outlet):
    if len(Outlet) > 15:
        Outlet_Resp = render.Marquee(width = 64, height = 10, child = render.Text(content = Outlet, color = "#FFF", font = "CG-pixel-3x5-mono"))

    else:
        Outlet_Resp = render.Box(width = 64, height = 5, child = render.Text(content = Outlet, color = "#fff", font = "CG-pixel-3x5-mono"))

    return Outlet_Resp

def Type_to_Fuel(type_id):
    Type = ""

    if type_id == "U91":
        Type = "Unleaded 91"
    elif type_id == "P95":
        Type = "Premium 95"
    elif type_id == "P98":
        Type = "Premium 98"
    elif type_id == "DL":
        Type = "Diesel"
    elif type_id == "LPG":
        Type = "LPG"
    elif type_id == "E10":
        Type = "Ethanol 94"
    elif type_id == "E85":
        Type = "Ethanol 105"
    elif type_id == "PDL":
        Type = "Premium Diesel"

    else:
        Type = ""

    return Type

FuelOptions = [
    schema.Option(
        display = "Unleaded 91",
        value = "U91",
    ),
    schema.Option(
        display = "Premium Unleaded 95",
        value = "P95",
    ),
    schema.Option(
        display = "Premium Unleaded 98",
        value = "P98",
    ),
    schema.Option(
        display = "Diesel",
        value = "DL",
    ),
    schema.Option(
        display = "Premium Diesel",
        value = "PDL",
    ),
    schema.Option(
        display = "LPG",
        value = "LPG",
    ),
    schema.Option(
        display = "Ethanol 94",
        value = "E10",
    ),
    schema.Option(
        display = "Ethanol 105",
        value = "E85",
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
                icon = "gasPump",
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
