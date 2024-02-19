"""
Applet: LA Metro
Summary: LA Metro rail services
Description: Shows arrival times for LA Metro rail services.
Author: M0ntyP
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

LINE_COLORS = """
{
    "A": "#0072bc",
    "B": "#e3131b",
    "C": "#58a738",
    "D": "#a05da5",
    "E": "#fdb913",
    "K": "#e96bb0"
}
"""

BASE_API = "https://transitime-api.goswift.ly/api/v1/key/81YENWXv/agency/lametro-rail/command/predictions?rs=Metro%20"
CACHE_TTL_SECS = 60

def main(config):
    SelectedLine = config.get("MetroLine", "B")
    SelectedStop = config.get("StationList", "80202")
    ColorMapping = json.decode(LINE_COLORS)

    API_URL = BASE_API + SelectedLine + "%20Line," + SelectedStop
    #print(API_URL)

    NextSchedCacheData = get_cachable_data(API_URL, CACHE_TTL_SECS)
    NEXTSCHED_JSON = json.decode(NextSchedCacheData)
    StationData = NEXTSCHED_JSON["predictions"][0]
    DestinationCount = len(StationData["destinations"])
    #print(DestinationCount)

    HEADSIGN_LIST = []

    headsign1 = ""
    arrival_str1 = ""
    LineColor = "#000"

    for i in range(0, DestinationCount, 1):
        HEADSIGN_LIST.append(StationData["destinations"][i]["headsign"])

    # if we have trains going both directions
    if DestinationCount == 2:
        headsign0 = HEADSIGN_LIST.pop(0)
        headsign1 = HEADSIGN_LIST.pop(0)
        if len(StationData["destinations"][0]["predictions"]) > 1:
            headsign0_arr = str(StationData["destinations"][0]["predictions"][0]["min"])
            headsign0_arr1 = str(StationData["destinations"][0]["predictions"][1]["min"])
            arrival_str = " " + headsign0_arr + ", " + headsign0_arr1 + " mins"
            # else if 1 time only

        elif len(StationData["destinations"][0]["predictions"]) == 1:
            headsign0_arr = str(StationData["destinations"][0]["predictions"][0]["min"])
            arrival_str = " " + headsign0_arr + " mins"
        else:
            arrival_str = " No times"

        # if we have 2 times listed going one way
        if len(StationData["destinations"][1]["predictions"]) > 1:
            headsign1_arr = str(StationData["destinations"][1]["predictions"][0]["min"])
            headsign1_arr1 = str(StationData["destinations"][1]["predictions"][1]["min"])
            arrival_str1 = " " + headsign1_arr + ", " + headsign1_arr1 + " mins"
            # else if 1 time only

        elif len(StationData["destinations"][1]["predictions"]) == 1:
            headsign1_arr = str(StationData["destinations"][1]["predictions"][0]["min"])
            arrival_str1 = " " + headsign1_arr + " mins"
        else:
            arrival_str1 = " No times"

    else:
        headsign0 = HEADSIGN_LIST.pop(0)

        # if we have 2 times listed going one way
        if len(StationData["destinations"][0]["predictions"]) > 1:
            headsign0_arr = str(StationData["destinations"][0]["predictions"][0]["min"])
            headsign0_arr1 = str(StationData["destinations"][0]["predictions"][1]["min"])
            arrival_str = " " + headsign0_arr + ", " + headsign0_arr1 + " mins"
            # else if 1 time only

        elif len(StationData["destinations"][0]["predictions"]) == 1:
            headsign0_arr = str(StationData["destinations"][0]["predictions"][0]["min"])
            arrival_str = headsign0_arr + " mins"
        else:
            arrival_str = " No times"

    if SelectedLine in LINE_COLORS:
        LineColor = ColorMapping[SelectedLine]

    if DestinationCount == 2:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "start",
                children = [
                    next_arrival(headsign0, arrival_str, SelectedLine, LineColor),
                    next_arrival(headsign1, arrival_str1, SelectedLine, LineColor),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "start",
                children = [
                    next_arrival(headsign0, arrival_str, SelectedLine, LineColor),
                ],
            ),
        )

def next_arrival(headsign, arrival_str, SelectedLine, LineColor):
    headsign = headsign.replace(" Station", "")
    headsign = headsign.upper()
    return render.Row(
        expanded = True,
        main_align = "left",
        cross_align = "center",
        children = [
            render.Circle(
                color = LineColor,
                diameter = 14,
                child = render.Text(SelectedLine, font = "5x8"),
            ),
            render.Column(
                children = [
                    render.Marquee(
                        width = 52,
                        child = render.Text(" " + headsign, font = "5x8"),
                    ),
                    render.Text(arrival_str, color = "#fff"),
                ],
            ),
        ],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "MetroLine",
                name = "Select rail line",
                desc = "Show services by the next arrivals or route",
                icon = "train",
                default = LineOptions[0].value,
                options = LineOptions,
            ),
            schema.Generated(
                id = "generated",
                source = "MetroLine",
                handler = LineSelectionOptions,
            ),
        ],
    )

def LineSelectionOptions(MetroLine):
    if MetroLine == "A":
        return [
            schema.Dropdown(
                id = "StationList",
                name = "Select rail station",
                desc = "Choose your station",
                icon = "train",
                default = ALineStations[0].value,
                options = ALineStations,
            ),
        ]
    if MetroLine == "B":
        return [
            schema.Dropdown(
                id = "StationList",
                name = "Rail Station",
                desc = "Choose your station",
                icon = "train",
                default = BLineStations[0].value,
                options = BLineStations,
            ),
        ]
    elif MetroLine == "C":
        return [
            schema.Dropdown(
                id = "StationList",
                name = "Rail Station",
                desc = "Choose your station",
                icon = "train",
                default = CLineStations[0].value,
                options = CLineStations,
            ),
        ]
    elif MetroLine == "D":
        return [
            schema.Dropdown(
                id = "StationList",
                name = "Rail Station",
                desc = "Choose your station",
                icon = "train",
                default = DLineStations[0].value,
                options = DLineStations,
            ),
        ]
    elif MetroLine == "E":
        return [
            schema.Dropdown(
                id = "StationList",
                name = "Rail Station",
                desc = "Choose your station",
                icon = "train",
                default = ELineStations[0].value,
                options = ELineStations,
            ),
        ]
    elif MetroLine == "K":
        return [
            schema.Dropdown(
                id = "StationList",
                name = "Rail Station",
                desc = "Choose your station",
                icon = "train",
                default = KLineStations[0].value,
                options = KLineStations,
            ),
        ]
    else:
        return None

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

LineOptions = [
    schema.Option(
        display = "A Line",
        value = "A",
    ),
    schema.Option(
        display = "B Line",
        value = "B",
    ),
    schema.Option(
        display = "C Line",
        value = "C",
    ),
    schema.Option(
        display = "D Line",
        value = "D",
    ),
    schema.Option(
        display = "E Line",
        value = "E",
    ),
    schema.Option(
        display = "K Line",
        value = "K",
    ),
]

ALineStations = [
    schema.Option(
        display = "Downtown Long Beach Station",
        value = "80101",
    ),
    schema.Option(
        display = "Pacific Ave Station",
        value = "80102",
    ),
    schema.Option(
        display = "1st Street Station",
        value = "80153",
    ),
    schema.Option(
        display = "5th Street Station",
        value = "80154",
    ),
    schema.Option(
        display = "Anaheim Street Station",
        value = "80105",
    ),
    schema.Option(
        display = "Pacific Coast Hwy Station",
        value = "80106",
    ),
    schema.Option(
        display = "Willow Street Station",
        value = "80107",
    ),
    schema.Option(
        display = "Wardlow Station",
        value = "80108",
    ),
    schema.Option(
        display = "Del Amo Station",
        value = "80109",
    ),
    schema.Option(
        display = "Artesia Station",
        value = "80110",
    ),
    schema.Option(
        display = "Compton Station",
        value = "80111",
    ),
    schema.Option(
        display = "Willowbrook - Rosa Parks Station",
        value = "80112",
    ),
    schema.Option(
        display = "103rd Street / Watts Towers  Station",
        value = "80113",
    ),
    schema.Option(
        display = "Firestone Station",
        value = "80114",
    ),
    schema.Option(
        display = "Florence Station",
        value = "80115",
    ),
    schema.Option(
        display = "Slauson Station",
        value = "80116",
    ),
    schema.Option(
        display = "Vernon Station",
        value = "80117",
    ),
    schema.Option(
        display = "Washington Station",
        value = "80118",
    ),
    schema.Option(
        display = "San Pedro Street Station",
        value = "80119",
    ),
    schema.Option(
        display = "Grand / LATTC Station",
        value = "80120",
    ),
    schema.Option(
        display = "Pico Station",
        value = "80121",
    ),
    schema.Option(
        display = "7th St / Metro Center Station",
        value = "80122",
    ),
    schema.Option(
        display = "Grand Av Arts/Bunker Hill",
        value = "81401",
    ),
    schema.Option(
        display = "Historic Broadway",
        value = "81402",
    ),
    schema.Option(
        display = "Little Tokyo / Arts District Station",
        value = "81403",
    ),
    schema.Option(
        display = "Union Station",
        value = "80409",
    ),
    schema.Option(
        display = "Chinatown Station",
        value = "80410",
    ),
    schema.Option(
        display = "Lincoln Heights / Cypress Park Station",
        value = "80411",
    ),
    schema.Option(
        display = "Heritage Square ",
        value = "80412",
    ),
    schema.Option(
        display = "Southwest Museum Station",
        value = "80413",
    ),
    schema.Option(
        display = "Highland Park Station",
        value = "80414",
    ),
    schema.Option(
        display = "South Pasadena Station",
        value = "80415",
    ),
    schema.Option(
        display = "Fillmore Station",
        value = "80416",
    ),
    schema.Option(
        display = "Del Mar Station",
        value = "80417",
    ),
    schema.Option(
        display = "Memorial Park Station",
        value = "80418",
    ),
    schema.Option(
        display = "Lake Station",
        value = "80419",
    ),
    schema.Option(
        display = "Allen Station",
        value = "80420",
    ),
    schema.Option(
        display = "Sierra Madre Villa Station",
        value = "80421",
    ),
    schema.Option(
        display = "Arcadia Station",
        value = "80422",
    ),
    schema.Option(
        display = "Monrovia Station",
        value = "80423",
    ),
    schema.Option(
        display = "Duarte / City of Hope Station",
        value = "80424",
    ),
    schema.Option(
        display = "Irwindale Station",
        value = "80425",
    ),
    schema.Option(
        display = "Azusa Downtown Station",
        value = "80426",
    ),
    schema.Option(
        display = "APU / Citrus College Station",
        value = "80427",
    ),
]

BLineStations = [
    schema.Option(
        display = "North Hollywood Station",
        value = "80201",
    ),
    schema.Option(
        display = "Universal / Studio City Station",
        value = "80202",
    ),
    schema.Option(
        display = "Hollywood / Highland Station",
        value = "80203",
    ),
    schema.Option(
        display = "Hollywood / Vine Station",
        value = "80204",
    ),
    schema.Option(
        display = "Hollywood / Western Station",
        value = "80205",
    ),
    schema.Option(
        display = "Vermont / Sunset Station",
        value = "80206",
    ),
    schema.Option(
        display = "Vermont / Santa Monica Station",
        value = "80207",
    ),
    schema.Option(
        display = "Vermont / Beverly Station",
        value = "80208",
    ),
    schema.Option(
        display = "Wilshire / Vermont Station",
        value = "80209",
    ),
    schema.Option(
        display = "Westlake / MacArthur Park Station",
        value = "80210",
    ),
    schema.Option(
        display = "7th St / Metro Center Station",
        value = "80211",
    ),
    schema.Option(
        display = "Pershing Square Station",
        value = "80212",
    ),
    schema.Option(
        display = "Civic Center / Grand Park Station",
        value = "80213",
    ),
    schema.Option(
        display = "Union Station",
        value = "80214",
    ),
]

CLineStations = [
    schema.Option(
        display = "Redondo Beach Station",
        value = "80301",
    ),
    schema.Option(
        display = "Douglas Station",
        value = "80302",
    ),
    schema.Option(
        display = "El Segundo Station",
        value = "80303",
    ),
    schema.Option(
        display = "Mariposa Station",
        value = "80304",
    ),
    schema.Option(
        display = "Aviation / LAX Station",
        value = "80305",
    ),
    schema.Option(
        display = "Hawthorne / Lennox Station",
        value = "80306",
    ),
    schema.Option(
        display = "Crenshaw Station",
        value = "80307",
    ),
    schema.Option(
        display = "Vermont / Athens Station",
        value = "80308",
    ),
    schema.Option(
        display = "Harbor Freeway Station",
        value = "80309",
    ),
    schema.Option(
        display = "Avalon Station",
        value = "80310",
    ),
    schema.Option(
        display = "Willowbrook - Rosa Parks Station",
        value = "80311",
    ),
    schema.Option(
        display = "Long Beach Blvd Station",
        value = "80312",
    ),
    schema.Option(
        display = "Lakewood Blvd Station",
        value = "80313",
    ),
    schema.Option(
        display = "Norwalk Station",
        value = "80314",
    ),
]

DLineStations = [
    schema.Option(
        display = "Union Station",
        value = "80214",
    ),
    schema.Option(
        display = "Civic Center / Grand Park Station",
        value = "80213",
    ),
    schema.Option(
        display = "Pershing Square Station",
        value = "80212",
    ),
    schema.Option(
        display = "7th St / Metro Center Station",
        value = "80211",
    ),
    schema.Option(
        display = "Westlake / MacArthur Park Station",
        value = "80210",
    ),
    schema.Option(
        display = "Wilshire / Vermont Station",
        value = "80209",
    ),
    schema.Option(
        display = "Wilshire / Normandie Station",
        value = "80215",
    ),
    schema.Option(
        display = "Wilshire / Western Station",
        value = "80216",
    ),
]

ELineStations = [
    schema.Option(
        display = "Downtown Santa Monica Station",
        value = "80139",
    ),
    schema.Option(
        display = "17th St / SMC Station",
        value = "80138",
    ),
    schema.Option(
        display = "26th St / Bergamot Station",
        value = "80137",
    ),
    schema.Option(
        display = "Expo / Bundy Station",
        value = "80136",
    ),
    schema.Option(
        display = "Expo / Sepulveda Station",
        value = "80135",
    ),
    schema.Option(
        display = "Westwood / Rancho Park Station",
        value = "80134",
    ),
    schema.Option(
        display = "Palms Station",
        value = "80133",
    ),
    schema.Option(
        display = "Culver City Station",
        value = "80132",
    ),
    schema.Option(
        display = "La Cienega / Jefferson Station",
        value = "80131",
    ),
    schema.Option(
        display = "Expo / La Brea Station",
        value = "80130",
    ),
    schema.Option(
        display = "Farmdale Station",
        value = "80129",
    ),
    schema.Option(
        display = "Expo / Crenshaw Station",
        value = "80128",
    ),
    schema.Option(
        display = "Expo / Western Station",
        value = "80127",
    ),
    schema.Option(
        display = "Expo / Vermont Station",
        value = "80126",
    ),
    schema.Option(
        display = "Expo Park / USC Station",
        value = "80125",
    ),
    schema.Option(
        display = "Jefferson / USC Station",
        value = "80124",
    ),
    schema.Option(
        display = "LATTC / Ortho Institute Station",
        value = "80123",
    ),
    schema.Option(
        display = "Pico Station",
        value = "80121",
    ),
    schema.Option(
        display = "7th St / Metro Center Station",
        value = "80122",
    ),
    schema.Option(
        display = "Grand Av Arts/Bunker Hill",
        value = "81401",
    ),
    schema.Option(
        display = "Historic Broadway",
        value = "81402",
    ),
    schema.Option(
        display = "Little Tokyo / Arts District Station",
        value = "81403",
    ),
    schema.Option(
        display = "Pico / Aliso Station",
        value = "80407",
    ),
    schema.Option(
        display = "Mariachi Plaza",
        value = "80406",
    ),
    schema.Option(
        display = "Soto Station",
        value = "80405",
    ),
    schema.Option(
        display = "Indiana Station",
        value = "80404",
    ),
    schema.Option(
        display = "Maravilla Station",
        value = "80403",
    ),
    schema.Option(
        display = "East LA Civic Center Station",
        value = "80402",
    ),
    schema.Option(
        display = "Atlantic Station",
        value = "80401",
    ),
]

KLineStations = [
    schema.Option(
        display = "Westchester / Veterans Station",
        value = "80703",
    ),
    schema.Option(
        display = "Downtown Inglewood Station",
        value = "80704",
    ),
    schema.Option(
        display = "Fairview Heights Station",
        value = "80705",
    ),
    schema.Option(
        display = "Hyde Park Station",
        value = "80706",
    ),
    schema.Option(
        display = "Leimert Park Station",
        value = "80707",
    ),
    schema.Option(
        display = "Martin Luther King Jr Station",
        value = "80708",
    ),
    schema.Option(
        display = "Expo / Crenshaw Station",
        value = "80709",
    ),
]
