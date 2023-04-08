"""
Applet: Adelaide Metro
Summary: Adelaide Transit
Description: Displays upcoming services for train stations and bus & tram stops around Adelaide.
Author: M0ntyP

Inspired by all the other great transit apps out there, I made one for my home town. I'd be surprised if anyone actually uses it :)

v1.0 - First release to Tidbyt
v1.1 - Fixed bug that showed same time for different services if over 120 mins away
v1.2 - Fixed bug that showed no time when its the last service for the day/for a while
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

NEXTSCHED1_URL = "https://api-cloudfront.adelaidemetro.com.au/stops/next-scheduled-services?stop="
STOPINFO_URL = "https://api-cloudfront.adelaidemetro.com.au/stops/info?stop="

CACHE_TTL_SECS = 60

def main(config):
    SelectedStation = config.get("StationList", "16490")
    TrainToCity = config.bool("TrainToCity", True)
    TrainOrTramOrBus = config.get("TrainOrTramOrBus", "Train")

    if TrainOrTramOrBus == "Tram":
        SelectedStation = config.get("TramStationList", "17753")

    if TrainOrTramOrBus == "Bus":
        SelectedStation = config.get("BusStop", 12471)

    if TrainOrTramOrBus == "Train":
        SelectedStation = config.get("StationList", "16490")

    if TrainToCity == False:
        SelectedStation = AwayStops(SelectedStation)

    STOP_ID = str(SelectedStation)

    NEXTSCHED_URL = NEXTSCHED1_URL + STOP_ID

    # Cache the next service times for 1 min
    NextSchedCacheData = get_cachable_data(NEXTSCHED_URL, 60)
    NEXTSCHED_JSON = json.decode(NextSchedCacheData)

    INFO_URL = STOPINFO_URL + STOP_ID

    # not caching this call as its just to check if Stop ID entered is valid. We don't want to cache the result of an incorrect ID and have the user wait for the cache to clear
    INFO_JSON = http.get(INFO_URL).json()

    # check its a valid stop, if not tell the user
    if "error" in INFO_JSON:
        Display = InvalidStop()

        return render.Root(
            delay = int(2000),
            child = render.Animation(children = Display),
        )

    # if its valid, then cache it
    # 24hrs is fine - this is just to get the stop name and what routes service this stop so it never really changes
    StopInfoCacheData = get_cachable_data(INFO_URL, 86400)
    INFO_JSON = json.decode(StopInfoCacheData)

    StopName = INFO_JSON["stop_data"]["stop_name"]

    # trim the stop names
    IsRailwayStation = StopName.endswith(" Railway Station")
    if IsRailwayStation == True:
        StopName = StopName.removesuffix(" Railway Station")

    IsTramStop = StopName.endswith(" Tram Stop")
    if IsTramStop == True:
        StopName = StopName.removesuffix(" Tram Stop")

    StopPrefix = StopName.startswith("Stop ")
    if StopPrefix == True:
        StopName = StopName.removeprefix("Stop ")

    # get how many routes there are for this stop
    StopRoutes = len(INFO_JSON["routes"])

    Routes = []
    RouteColors = []
    Display1 = []
    #zdump = []

    # loop through each route and get the ID and color
    for x in range(0, StopRoutes, 1):
        Routes.append(INFO_JSON["routes"][x]["route_id"])
        RouteColors.append(INFO_JSON["routes"][x]["route_color"])

    RouteLen = len(Routes)

    # keep it to 3 routes per page
    if RouteLen > 3:
        # for the number of routes for the stop, skip 3
        for z in range(0, RouteLen, 3):
            z = z
            Display1.extend([
                render.Column(
                    children = [
                        render.Column(
                            children = GetTimes(StopName, Routes, RouteColors, RouteLen, NEXTSCHED_JSON),
                        ),
                    ],
                ),
            ])
    else:
        Display1.extend([
            render.Column(
                children = [
                    render.Column(
                        children = GetTimes(StopName, Routes, RouteColors, RouteLen, NEXTSCHED_JSON),
                    ),
                ],
            ),
        ])

    return render.Root(
        delay = int(2500),
        child = render.Animation(children = Display1),
    )

def GetTimes(StopName, Routes, RouteColors, RouteLen, NEXTSCHED_JSON):
    MatchCount = 0
    TimeList = []
    Display = []
    Trains = []
    sdump = []

    Comma1 = ""
    Comma2 = ""
    Time1 = ""
    Time2 = ""
    Time3 = ""

    Title = [render.Marquee(width = 64, height = 8, child = render.Text(content = StopName, color = "#FFF", font = "tom-thumb"))]
    Display.extend(Title)

    # Get total number of scheduled services
    ServicesLookup = len(NEXTSCHED_JSON[2])

    # if there are more than 3, only do a max of 3
    if RouteLen > 3:
        RouteLen = 3

    # for each route

    for s in range(0, RouteLen, 1):
        sdump.append(s)

        # if no more routes, break out!
        if len(Routes) == 0:
            break

        MatchCount = 0
        TheRoute = Routes.pop(0)
        RouteColor = RouteColors.pop(0)
        RouteColor = "#" + RouteColor

        # look at the next scheduled services for that stop, extract max of 3 times for that specific line (MatchCount)
        for y in range(0, ServicesLookup, 1):
            if NEXTSCHED_JSON[2][y]["route_id"] == TheRoute:
                min = int(NEXTSCHED_JSON[2][y]["min"])

                # only append to the list if service is less than 2hrs away
                # but we still only want to check the next 3 times, hence the incrementing of MatchCount for both
                if min < 120:
                    TimeList.append(min)
                    MatchCount = MatchCount + 1
                    if MatchCount == 3:
                        MatchCount = 0
                        break
                elif min > 120:
                    MatchCount = MatchCount + 1
                    if MatchCount == 3:
                        MatchCount = 0
                        break

        # if we have some times	then we need to render them
        if TimeList != []:
            # formatting
            if len(TimeList) == 3:
                Time1 = str(TimeList.pop(0))
                Comma1 = ","
                Time2 = str(TimeList.pop(0))
                Comma2 = ","
                Time3 = str(TimeList.pop(0))
            if len(TimeList) == 2:
                Time1 = str(TimeList.pop(0))
                Comma1 = ","
                Time2 = str(TimeList.pop(0))
                Comma2 = ""
                Time3 = ""
            if len(TimeList) == 1:
                Time1 = str(TimeList.pop(0))
                Comma1 = ""
                Comma2 = ""
                Time2 = ""
                Time3 = ""

            Trains = render.Row(
                children = [
                    render.Box(width = 64, height = 8, child = render.Row(children = [
                        render.Box(width = 26, height = 7, color = RouteColor, child = render.Text(content = TheRoute, font = "CG-pixel-3x5-mono")),
                        render.Box(width = 40, height = 7, child = render.Text(content = Time1 + Comma1 + Time2 + Comma2 + Time3, color = "#fff", font = "CG-pixel-3x5-mono")),
                    ])),
                ],
            )

            # if we have no services < 120 mins away
        elif TimeList == []:
            Trains = render.Row(
                children = [
                    render.Box(width = 64, height = 8, child = render.Row(children = [
                        render.Box(width = 26, height = 7, color = RouteColor, child = render.Text(content = TheRoute, font = "CG-pixel-3x5-mono")),
                        render.Box(width = 40, height = 7, child = render.Text(content = "NO TIMES", color = "#fff", font = "CG-pixel-3x5-mono")),
                    ])),
                ],
            )

        Display.extend([Trains])

    return Display

StationOptions = [

    # Train Stations
    schema.Option(
        display = "Adelaide",
        value = "16490",
    ),
    schema.Option(
        display = "Adelaide Showground",
        value = "18104",
    ),
    schema.Option(
        display = "Albert Park",
        value = "16491",
    ),
    schema.Option(
        display = "Alberton",
        value = "16492",
    ),
    schema.Option(
        display = "Ascot Park",
        value = "16493",
    ),
    schema.Option(
        display = "Belair",
        value = "16494",
    ),
    schema.Option(
        display = "Blackwood",
        value = "16495",
    ),
    schema.Option(
        display = "Bowden",
        value = "16496",
    ),
    schema.Option(
        display = "Brighton",
        value = "16497",
    ),
    schema.Option(
        display = "Broadmeadows",
        value = "16498",
    ),
    schema.Option(
        display = "Cheltenham",
        value = "16499",
    ),
    schema.Option(
        display = "Chidda",
        value = "16500",
    ),
    schema.Option(
        display = "Christie Downs",
        value = "16501",
    ),
    schema.Option(
        display = "Clarence Park",
        value = "16502",
    ),
    schema.Option(
        display = "Coromandel",
        value = "16504",
    ),
    schema.Option(
        display = "Croydon",
        value = "16505",
    ),
    schema.Option(
        display = "Draper",
        value = "16506",
    ),
    schema.Option(
        display = "Dry Creek",
        value = "16507",
    ),
    schema.Option(
        display = "Dudley Park",
        value = "16508",
    ),
    schema.Option(
        display = "East Grange",
        value = "16509",
    ),
    schema.Option(
        display = "Eden Hills",
        value = "16510",
    ),
    schema.Option(
        display = "Edwardstown",
        value = "16511",
    ),
    schema.Option(
        display = "Elizabeth",
        value = "16512",
    ),
    schema.Option(
        display = "Elizabeth South",
        value = "16513",
    ),
    schema.Option(
        display = "Emerson",
        value = "16514",
    ),
    schema.Option(
        display = "Ethelton",
        value = "16515",
    ),
    schema.Option(
        display = "Evanston",
        value = "16516",
    ),
    schema.Option(
        display = "Flinders",
        value = "18934",
    ),
    schema.Option(
        display = "Gawler Central",
        value = "16518",
    ),
    schema.Option(
        display = "Gawler Oval",
        value = "16519",
    ),
    schema.Option(
        display = "Gawler",
        value = "16517",
    ),
    schema.Option(
        display = "Glanville",
        value = "16520",
    ),
    schema.Option(
        display = "Glenalta",
        value = "16521",
    ),
    schema.Option(
        display = "Goodwood",
        value = "16522",
    ),
    schema.Option(
        display = "Grange",
        value = "16523",
    ),
    schema.Option(
        display = "Greenfields",
        value = "16524",
    ),
    schema.Option(
        display = "Hallett Cove Beach",
        value = "16587",
    ),
    schema.Option(
        display = "Hallett Cove",
        value = "16525",
    ),
    schema.Option(
        display = "Hove",
        value = "16526",
    ),
    schema.Option(
        display = "Islington",
        value = "16527",
    ),
    schema.Option(
        display = "Kilburn",
        value = "16530",
    ),
    schema.Option(
        display = "Kilkenny",
        value = "16531",
    ),
    schema.Option(
        display = "Kudla",
        value = "16532",
    ),
    schema.Option(
        display = "Largs North",
        value = "16534",
    ),
    schema.Option(
        display = "Largs",
        value = "16533",
    ),
    schema.Option(
        display = "Lonsdale",
        value = "16535",
    ),
    schema.Option(
        display = "Lynton",
        value = "16536",
    ),
    schema.Option(
        display = "Marino",
        value = "16537",
    ),
    schema.Option(
        display = "Marino Rocks",
        value = "16538",
    ),
    schema.Option(
        display = "Marion",
        value = "16539",
    ),
    schema.Option(
        display = "Mawson Lakes",
        value = "17533",
    ),
    schema.Option(
        display = "Midlunga",
        value = "16540",
    ),
    schema.Option(
        display = "Mile End",
        value = "16542",
    ),
    schema.Option(
        display = "Millswood",
        value = "18719",
    ),
    schema.Option(
        display = "Mitcham",
        value = "16543",
    ),
    schema.Option(
        display = "Mitchell Park",
        value = "16544",
    ),
    schema.Option(
        display = "Munno Para",
        value = "16545",
    ),
    schema.Option(
        display = "Noarlunga",
        value = "16546",
    ),
    schema.Option(
        display = "North Adelaide",
        value = "16547",
    ),
    schema.Option(
        display = "North Haven",
        value = "16548",
    ),
    schema.Option(
        display = "Nurlutta",
        value = "16549",
    ),
    schema.Option(
        display = "Oaklands",
        value = "16550",
    ),
    schema.Option(
        display = "Osborne",
        value = "16551",
    ),
    schema.Option(
        display = "Outer Harbor",
        value = "16552",
    ),
    schema.Option(
        display = "Ovingham",
        value = "16553",
    ),
    schema.Option(
        display = "Parafield",
        value = "16554",
    ),
    schema.Option(
        display = "Parafield Gardens",
        value = "16555",
    ),
    schema.Option(
        display = "Peterhead",
        value = "16556",
    ),
    schema.Option(
        display = "Pinera",
        value = "16557",
    ),
    schema.Option(
        display = "Port Adelaide",
        value = "16578",
    ),
    schema.Option(
        display = "Salisbury",
        value = "16558",
    ),
    schema.Option(
        display = "Seacliff",
        value = "16559",
    ),
    schema.Option(
        display = "Seaford Meadows",
        value = "18678",
    ),
    schema.Option(
        display = "Seaford",
        value = "18680",
    ),
    schema.Option(
        display = "Seaton Park",
        value = "16560",
    ),
    schema.Option(
        display = "Smithfield",
        value = "16561",
    ),
    schema.Option(
        display = "St Clair",
        value = "18683",
    ),
    schema.Option(
        display = "Tambelin",
        value = "16562",
    ),
    schema.Option(
        display = "Taperoo",
        value = "16563",
    ),
    schema.Option(
        display = "Tonsley",
        value = "16503",
    ),
    schema.Option(
        display = "Torrens Park",
        value = "16565",
    ),
    schema.Option(
        display = "Unley Park",
        value = "16566",
    ),
    schema.Option(
        display = "Warradale",
        value = "16567",
    ),
    schema.Option(
        display = "West Croydon",
        value = "16568",
    ),
    schema.Option(
        display = "Womma",
        value = "16569",
    ),
    schema.Option(
        display = "Woodlands Park",
        value = "16570",
    ),
    schema.Option(
        display = "Woodville Park",
        value = "16572",
    ),
    schema.Option(
        display = "Woodville",
        value = "16571",
    ),
]

TramStationOptions = [

    # Tram Stations
    schema.Option(
        display = "Adelaide Railway Station (to Entertainment Centre)",
        value = "17753",
    ),
    schema.Option(
        display = "Adelaide Railway Station (to Botanic, Glenelg)",
        value = "18513",
    ),
    schema.Option(
        display = "Art Gallery (to Botanic)",
        value = "18849",
    ),
    schema.Option(
        display = "Art Gallery (to Ent Centre)",
        value = "18848",
    ),
    schema.Option(
        display = "Beckman St (to Festival, RAH/Ent Centre)",
        value = "16584",
    ),
    schema.Option(
        display = "Beckman St (to Glenelg)",
        value = "18526",
    ),
    schema.Option(
        display = "Black Forest (to Festival, RAH/Ent Centre)",
        value = "16629",
    ),
    schema.Option(
        display = "Black Forest (to Glenelg)",
        value = "18523",
    ),
    schema.Option(
        display = "Bonython Park (to Entertainment Centre)",
        value = "17990",
    ),
    schema.Option(
        display = "Bonython Park (to Botanic, Glenelg)",
        value = "18509",
    ),
    schema.Option(
        display = "Botanic Gardens",
        value = "18852",
    ),
    schema.Option(
        display = "Brighton Rd (to Festival, RAH/Ent Centre)",
        value = "16582",
    ),
    schema.Option(
        display = "Brighton Rd (to Glenelg)",
        value = "18534",
    ),
    schema.Option(
        display = "City South (to Festival, RAH/Ent Centre)",
        value = "16626",
    ),
    schema.Option(
        display = "City South (to Glenelg)",
        value = "18517",
    ),
    schema.Option(
        display = "City West (to Entertainment Centre)",
        value = "17752",
    ),
    schema.Option(
        display = "City West (to Botanic, Glenelg)",
        value = "18512",
    ),
    schema.Option(
        display = "Entertainment Centre",
        value = "18508",
    ),
    schema.Option(
        display = "Festival Plaza",
        value = "18847",
    ),
    schema.Option(
        display = "Forestville (to Festival, RAH/Ent Centre)",
        value = "16583",
    ),
    schema.Option(
        display = "Forestville (to Glenelg)",
        value = "18522",
    ),
    schema.Option(
        display = "Glandore (to Festival, RAH/Ent Centre)",
        value = "16630",
    ),
    schema.Option(
        display = "Glandore (to Glenelg)",
        value = "18525",
    ),
    schema.Option(
        display = "Glenelg East (to Festival, RAH/Ent Centre)",
        value = "16634",
    ),
    schema.Option(
        display = "Glenelg East (to Glenelg)",
        value = "18533",
    ),
    schema.Option(
        display = "Glengowrie (to Festival, RAH/Ent Centre)",
        value = "16633",
    ),
    schema.Option(
        display = "Glengowrie (to Glenelg)",
        value = "18532",
    ),
    schema.Option(
        display = "Goodwood Rd (to Festival, RAH/Ent Centre)",
        value = "16623",
    ),
    schema.Option(
        display = "Goodwood Rd (to Glenelg)",
        value = "18521",
    ),
    schema.Option(
        display = "Greenhill Rd (to Festival, RAH/Ent Centre)",
        value = "16585",
    ),
    schema.Option(
        display = "Greenhill Rd (to Glenelg)",
        value = "18519",
    ),
    schema.Option(
        display = "Jetty Rd (to Festival, RAH/Ent Centre)",
        value = "17111",
    ),
    schema.Option(
        display = "Jetty Rd (to Glenelg)",
        value = "14395",
    ),
    schema.Option(
        display = "Marion Rd (to Festival, RAH/Ent Centre)",
        value = "16575",
    ),
    schema.Option(
        display = "Marion Rd (to Glenelg)",
        value = "18528",
    ),
    schema.Option(
        display = "Morphett Rd (to Festival, RAH/Ent Centre)",
        value = "17756",
    ),
    schema.Option(
        display = "Morphett Rd (to Glenelg)",
        value = "18529",
    ),
    schema.Option(
        display = "Moseley Square",
        value = "16577",
    ),
    schema.Option(
        display = "Pirie St (to Festival, RAH/Ent Centre)",
        value = "17755",
    ),
    schema.Option(
        display = "Pirie St (to Glenelg)",
        value = "18515",
    ),
    schema.Option(
        display = "Plympton Park (to Festival, RAH/Ent Centre)",
        value = "16632",
    ),
    schema.Option(
        display = "Plympton Park (to Glenelg)",
        value = "18529",
    ),
    schema.Option(
        display = "Royal Adel Hospital (to Entertainment Centre)",
        value = "17989",
    ),
    schema.Option(
        display = "Royal Adel Hospital (to Botanic, Glenelg)",
        value = "18511",
    ),
    schema.Option(
        display = "Rundle Mall (to Festival, RAH/Ent Centre)",
        value = "17754",
    ),
    schema.Option(
        display = "Rundle Mall (to Glenelg)",
        value = "18514",
    ),
    schema.Option(
        display = "South Plympton (to Festival, RAH/Ent Centre)",
        value = "16631",
    ),
    schema.Option(
        display = "South Plympton (to Glenelg)",
        value = "18527",
    ),
    schema.Option(
        display = "South Rd (to Festival, RAH/Ent Centre)",
        value = "16574",
    ),
    schema.Option(
        display = "South Rd (to Glenelg)",
        value = "18524",
    ),
    schema.Option(
        display = "South Tce (to Festival, RAH/Ent Centre)",
        value = "16627",
    ),
    schema.Option(
        display = "South Tce (to Glenelg)",
        value = "18518",
    ),
    schema.Option(
        display = "Thebarton (to Entertainment Centre)",
        value = "17991",
    ),
    schema.Option(
        display = "Thebarton (to Botanic, Glenelg)",
        value = "18510",
    ),
    schema.Option(
        display = "University (to Botanic)",
        value = "18851",
    ),
    schema.Option(
        display = "University (to Ent Centre)",
        value = "18850",
    ),
    schema.Option(
        display = "Victoria Sq (to Festival, RAH/Ent Centre)",
        value = "16573",
    ),
    schema.Option(
        display = "Victoria Sq (to Glenelg)",
        value = "18516",
    ),
    schema.Option(
        display = "Wayville (to Festival, RAH/Ent Centre)",
        value = "16628",
    ),
    schema.Option(
        display = "Wayville (to Glenelg)",
        value = "185208",
    ),
]

TrainOrTramOrBusOptions = [
    schema.Option(
        display = "Train",
        value = "Train",
    ),
    schema.Option(
        display = "Tram",
        value = "Tram",
    ),
    schema.Option(
        display = "Bus",
        value = "Bus",
    ),
]

def InvalidStop():
    # {"error":"stop not found"}
    Display = []
    Title = [render.Marquee(width = 64, height = 8, child = render.Text(content = "Invalid Stop ID", color = "#FFF", font = "tom-thumb"))]
    Display.extend(Title)

    return Display

def AwayStops(SelectedStation):
    # Final Stops
    if SelectedStation == "16490":  # Adelaide, as this is terminus so show same results
        return ("16490")
    if SelectedStation == "18934":  # Flinders, as this is terminus so show same results
        return ("18934")
    if SelectedStation == "16523":  # Grange, as this is terminus so show same results
        return ("16523")
    if SelectedStation == "16517":  # Gawler, as this is terminus so show same results
        return ("16517")
    if SelectedStation == "18680":  # Seaford, as this is terminus so show same results
        return ("18680")
    if SelectedStation == "16552":  # Outer Harbour, as this is terminus so show same results
        return ("16552")
    if SelectedStation == "16494":  # Belair, as this is terminus so show same results
        return ("16494")
    if SelectedStation == "18104":
        return ("18583")
    if SelectedStation == "16491":
        return ("18454")
    if SelectedStation == "16492":
        return ("18463")
    if SelectedStation == "16493":
        return ("18591")
    if SelectedStation == "16495":
        return ("18573")
    if SelectedStation == "16496":
        return ("18442")
    if SelectedStation == "16497":
        return ("18596")
    if SelectedStation == "16498":
        return ("18553")
    if SelectedStation == "16499":
        return ("18461")
    if SelectedStation == "16500":
        return ("18547")
    if SelectedStation == "16501":
        return ("18603")
    if SelectedStation == "16502":
        return ("18584")
    if SelectedStation == "16504":
        return ("18574")
    if SelectedStation == "16504":
        return ("18574")
    if SelectedStation == "16505":
        return ("18444")
    if SelectedStation == "16506":
        return ("18476")
    if SelectedStation == "16507":
        return ("18542")
    if SelectedStation == "16508":
        return ("18539")
    if SelectedStation == "16509":
        return ("18459")
    if SelectedStation == "16510":
        return ("18575")
    if SelectedStation == "16511":
        return ("18586")
    if SelectedStation == "16512":
        return ("18551")
    if SelectedStation == "16513":
        return ("18550")
    if SelectedStation == "16514":
        return ("18585")
    if SelectedStation == "16515":
        return ("18467")
    if SelectedStation == "16516":
        return ("18558")
    if SelectedStation == "16519":
        return ("18560")
    if SelectedStation == "16520":
        return ("18469")
    if SelectedStation == "16521":
        return ("18572")
    if SelectedStation == "16522":
        return ("18580")
    if SelectedStation == "16524":
        return ("18544")
    if SelectedStation == "16587":
        return ("18601")
    if SelectedStation == "16525":
        return ("18600")
    if SelectedStation == "16526":
        return ("18595")
    if SelectedStation == "16527":
        return ("18540")
    if SelectedStation == "16530":
        return ("18541")
    if SelectedStation == "16531":
        return ("18448")
    if SelectedStation == "16524":
        return ("18544")
    if SelectedStation == "16587":
        return ("18601")
    if SelectedStation == "16525":
        return ("18600")
    if SelectedStation == "16526":
        return ("18595")
    if SelectedStation == "16527":
        return ("18540")
    if SelectedStation == "16530":
        return ("18541")
    if SelectedStation == "16531":
        return ("18448")
    if SelectedStation == "16532":
        return ("18556")
    if SelectedStation == "16534":
        return ("18474")
    if SelectedStation == "16533":
        return ("18473")
    if SelectedStation == "16535":
        return ("18602")
    if SelectedStation == "16536":
        return ("18576")
    if SelectedStation == "16537":
        return ("18598")
    if SelectedStation == "16538":
        return ("18599")
    if SelectedStation == "16539":
        return ("18592")
    if SelectedStation == "17533":
        return ("18543")
    if SelectedStation == "16540":
        return ("18481")
    if SelectedStation == "16542":
        return ("18582")
    if SelectedStation == "18719":
        return ("18720")
    if SelectedStation == "16543":
        return ("18578")
    if SelectedStation == "16544":
        return ("18588")
    if SelectedStation == "16545":
        return ("18555")
    if SelectedStation == "16546":
        return ("18604")
    if SelectedStation == "16547":
        return ("18538")
    if SelectedStation == "16548":
        return ("18485")
    if SelectedStation == "16549":
        return ("18549")
    if SelectedStation == "16550":
        return ("18593")
    if SelectedStation == "16551":
        return ("18483")
    if SelectedStation == "16553":
        return ("18500")
    if SelectedStation == "16555":
        return ("18545")
    if SelectedStation == "16554":
        return ("18546")
    if SelectedStation == "16556":
        return ("18471")
    if SelectedStation == "16557":
        return ("18571")
    if SelectedStation == "16558":
        return ("18465")
    if SelectedStation == "16558":
        return ("18548")
    if SelectedStation == "16559":
        return ("18597")
    if SelectedStation == "18678":
        return ("18677")
    if SelectedStation == "16578":
        return ("18465")
    if SelectedStation == "16560":
        return ("18457")
    if SelectedStation == "16561":
        return ("18554")
    if SelectedStation == "18683":
        return ("18684")
    if SelectedStation == "16562":
        return ("18557")
    if SelectedStation == "16563":
        return ("18479")
    if SelectedStation == "16503":
        return ("18589")
    if SelectedStation == "16565":
        return ("18577")
    if SelectedStation == "16566":
        return ("18579")
    if SelectedStation == "16567":
        return ("18594")
    if SelectedStation == "16568":
        return ("18447")
    if SelectedStation == "16569":
        return ("18552")
    if SelectedStation == "16570":
        return ("18587")
    if SelectedStation == "16572":
        return ("18450")
    if SelectedStation == "16571":
        return ("18452")
    return None

def MoreOptions(TrainOrTramOrBus):
    if TrainOrTramOrBus == "Train":
        return [
            schema.Dropdown(
                id = "StationList",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = StationOptions[0].value,
                options = StationOptions,
            ),
            schema.Toggle(
                id = "TrainToCity",
                name = "To Adelaide",
                desc = "Enable for travel to Adelaide Station, disable for opposite direction",
                icon = "toggle-on",
                default = True,
            ),
        ]

    elif TrainOrTramOrBus == "Tram":
        return [
            schema.Dropdown(
                id = "TramStationList",
                name = "Tram Station",
                desc = "Choose your station",
                icon = "trainTram",
                default = TramStationOptions[0].value,
                options = TramStationOptions,
            ),
        ]
    elif TrainOrTramOrBus == "Bus":
        return [
            schema.Text(
                id = "BusStop",
                name = "Bus Stop",
                desc = "Enter the Stop ID",
                icon = "bus",
            ),
        ]
    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "TrainOrTramOrBus",
                name = "Train, Tram or Bus",
                desc = "Which service?",
                icon = "gear",
                default = TrainOrTramOrBusOptions[0].value,
                options = TrainOrTramOrBusOptions,
            ),
            schema.Generated(
                id = "generated",
                source = "TrainOrTramOrBus",
                handler = MoreOptions,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        # print("Using cached data")
        return base64.decode(data)

    res = http.get(url = url)

    #print("Getting new data")
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    cache.set(key, base64.encode(res.body()), ttl_seconds = timeout)

    return res.body()
