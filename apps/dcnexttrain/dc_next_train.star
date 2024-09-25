"""
Applet: DC Next Train
Summary: Displays WMATA Next Train
Description: Displays Washington DC Metro train status with filtering options.
Author: cbromano
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

WMATA_BASE_URL = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/"
CACHE_TTL = 30

def main(config):

  # Get options from schemas
  selectedGroup = config.get("groupCode")
  selectedStop = config.get("stationCode") or "A01" #I think there is a race condition happening between this and the API call.  This prevents an error on first opening of the file
  selectedLine = config.get("metroLine")
  selectedCars = config.bool("displayCars")
  selectedView = config.get("viewOption")

  API_KEY = config.get("userAPI")
  if API_KEY == None:
    API_KEY = "e13626d03d8e4c03ac07f95541b3091b" #this is the public test API key


  # Call the WMATA API
  WMATA_URL = WMATA_BASE_URL + selectedStop

  response = http.get(WMATA_URL, headers = {"api_key": API_KEY}, ttl_seconds = CACHE_TTL)
  if response.status_code != 200:
      return render.Root(
          child = render.Text("Error!"),
      )

  trainListing = response.json()["Trains"]

  # Filter data to user constraints
  trainDestination = []
  trainArrival = []
  trainCars = []
  trainLine = []

  for train in trainListing:
    if train["Group"] == selectedGroup or selectedGroup == "ALL":
      if train["Line"] == selectedLine or selectedLine == "ALL":
        #TODO:  Add a filter here for minimum time to arrive
        trainDestination.append(train["Destination"]) #"DestinationName" Is the long form

        #Make the string the same number of characters since api returns "ARR","BRD","XX","X"
        if train["Min"].count("") == 4:
          trainArrival.append(train["Min"])
        elif train["Min"].count("") == 3:
          trainArrival.append(" " + train["Min"])
        elif train["Min"].count("") == 2:
          trainArrival.append("  " + train["Min"])

        #Setting this to be "" was easier than having two rendering variants.  It adds an extra padding, but it's fine.
        if selectedCars == True:
          trainCars.append(train["Car"])
        else:
          trainCars.append("")

        trainLine.append(train["Line"])

  selectedFont = "5x8" # 5x8 or tom-thumb

  # Select which view to create
  if selectedView == "5":
    finishedDisplay = generateDisplay5(trainDestination, trainArrival, trainCars, trainLine, selectedCars)
  elif selectedView == "4":
    finishedDisplay = generateDisplay4(trainDestination, trainArrival, trainCars, trainLine, selectedCars)
  elif selectedView == "3":
    selectedFont = "tom-thumb"
    finishedDisplay = generateDisplay3(trainDestination, trainArrival, trainCars, trainLine, selectedCars, selectedFont)
  elif selectedView == "3a":
    selectedFont = "5x8"
    finishedDisplay = generateDisplay3(trainDestination, trainArrival, trainCars, trainLine, selectedCars, selectedFont)
  elif selectedView == "2":
    finishedDisplay = generateDisplay2(trainDestination, trainArrival, trainCars, trainLine, selectedCars)
  else:
    finishedDisplay = render.Text("Hello")

  return render.Root(child=finishedDisplay)

def generateDisplay2(trainDestination, trainArrival, trainCars, trainLine, selectedCars):
  trainRows = 2
  circleDiameter = 11

  ColorMapping = json.decode(LINE_COLORS)
  TextColorMapping = json.decode(TEXT_COLORS)
  displayFont = "5x8" # 5x8 or tom-thumb

  if displayFont == "tom-thumb" and selectedCars == True:
    displayOffset = -1
    marqueeWidth = 32
  elif displayFont == "tom-thumb" and selectedCars != True:
    displayOffset = -1
    marqueeWidth = 40
  elif displayFont != "tom-thumb" and selectedCars == True:
    displayOffset = 0
    marqueeWidth = 32
  elif displayFont != "tom-thumb" and selectedCars != True:
    displayOffset = 0
    marqueeWidth = 34

  if trainRows > len(trainArrival):
    trainRows = len(trainArrival)

  # List to hold the Box objects for the current column
  rows = []

  #Title Row
  #if selectedCars == True:
  #  rows.append(render.Row(
  #    children=[
  #      render.Text("Car Dest     MIN", font = "CG-pixel-3x5-mono")
  #      ],
  #  ))
  #else:
  #  rows.append(render.Row(
  #    children=[
  #      render.Text("  Dest       MIN", font = "CG-pixel-3x5-mono")
  #      ],
  #  ))

  #rows.append(render.Row(
  #  expanded=True,
  #  main_align="space_between",
  #  cross_align="center",
  #  children=[
  #    render.Box(height=1, width=64, color="#aa0"),
  #  ],
  #))
  #rows.append(render.Row(
  #  expanded=True,
  #  main_align="space_between",
  #  cross_align="center",
  #  children=[
  #    render.Box(height=1, width=64, color="#000"),
  #  ],
  #))

  # Loop through each row
  for row in range(trainRows):

    Destination = trainDestination[row]
    Arrival = trainArrival[row]
    Cars = trainCars[row]
    Line = trainLine[row]

    if Line in LINE_COLORS:
      LineColor = ColorMapping[Line]
      TextColor = TextColorMapping[Line]
    else:
      LineColor = "#bf5abc"
      TextColor = "#000000"


    rows.append(render.Row(
      expanded=True,
      main_align="space_between",
      cross_align="center",
      children=[
        render.Circle(
            color=LineColor,
            diameter=circleDiameter,
            child = render.Text(
                Line,
                font = "tom-thumb",
                color = TextColor
                ),
            ),

        render.Text("%s" % Cars, font = displayFont, offset = displayOffset),

        #render.Text(Destination, font = displayFont, offset = displayOffset),

        render.Marquee(
            width = marqueeWidth,
            child = render.Text(Destination, font = displayFont, offset = displayOffset)
            ),
        render.Text(Arrival, font = displayFont, offset = displayOffset), #"%d" % test
      ],
    ))

  # Create the column object with all the rows
  display2 = render.Column(
    expanded=True,
    main_align="space_evenly",
    cross_align="center",
        children=rows,
    )

  return display2

def generateDisplay3(trainDestination, trainArrival, trainCars, trainLine, selectedCars, displayFont):
  trainRows = 3

  ColorMapping = json.decode(LINE_COLORS)
  TextColorMapping = json.decode(TEXT_COLORS)
  #displayFont = "tom-thumb" # 5x8 or tom-thumb

  if displayFont == "tom-thumb" and selectedCars == True:
    displayOffset = -1
    marqueeWidth = 32
  elif displayFont == "tom-thumb" and selectedCars != True:
    displayOffset = -1
    marqueeWidth = 40
  elif displayFont != "tom-thumb" and selectedCars == True:
    displayOffset = 0
    marqueeWidth = 32
  elif displayFont != "tom-thumb" and selectedCars != True:
    displayOffset = 0
    marqueeWidth = 34

  if trainRows > len(trainArrival):
    trainRows = len(trainArrival)

  # List to hold the Box objects for the current column
  rows = []

    # Loop through each row
  for row in range(trainRows):

    Destination = trainDestination[row]
    Arrival = trainArrival[row]
    Cars = trainCars[row]
    Line = trainLine[row]

    if Line in LINE_COLORS:
      LineColor = ColorMapping[Line]
      TextColor = TextColorMapping[Line]
    else:
      LineColor = "#bf5abc"
      TextColor = "#000000"


    rows.append(render.Row(
      expanded=True,
      main_align="space_between",
      cross_align="center",
      children=[
        render.Circle(
            color=LineColor,
            diameter=9,  #Also works with 9
            child = render.Text(
                Line,
                font = "tom-thumb",
                color = TextColor
                ),
            ),

        render.Text("%s" % Cars, font = displayFont, offset = displayOffset),

        #render.Text(Destination, font = displayFont, offset = displayOffset),

        render.Marquee(
            width = marqueeWidth,
            child = render.Text(Destination, font = displayFont, offset = displayOffset)
            ),
        render.Text(Arrival, font = displayFont, offset = displayOffset), #"%d" % test
      ],
    ))

  # Create the column object with all the rows
  display3 = render.Column(
    expanded=True,
    main_align="space_evenly",
    cross_align="center",
        children=rows,
    )

  return display3

def generateDisplay4(trainDestination, trainArrival, trainCars, trainLine, selectedCars):
  trainRows = 4
  boxHeight = 5
  boxWidth = 4

  ColorMapping = json.decode(LINE_COLORS)
  TextColorMapping = json.decode(TEXT_COLORS)
  displayFont = "tom-thumb" # tb-8 or tom-thumb
  displayOffset = 0

  if selectedCars == True:
    marqueeWidth = 40
  else:
    marqueeWidth = 45

  if trainRows > len(trainArrival):
    trainRows = len(trainArrival)

  # List to hold the Box objects for the current column
  rows = []

  #Title Row
  if selectedCars == True:
    rows.append(render.Row(
      children=[
        render.Text("Car Dest     MIN", font = "CG-pixel-3x5-mono")
        ],
    ))
  else:
    rows.append(render.Row(
      children=[
        render.Text("  Dest       MIN", font = "CG-pixel-3x5-mono")
        ],
    ))

  rows.append(render.Row(
    expanded=True,
    main_align="space_between",
    cross_align="center",
    children=[
      render.Box(height=1, width=64, color="#aa0"),
    ],
  ))
  rows.append(render.Row(
    expanded=True,
    main_align="space_between",
    cross_align="center",
    children=[
      render.Box(height=2, width=64, color="#000"),
    ],
  ))

  # Loop through each row
  for row in range(trainRows):

    Destination = trainDestination[row]
    Arrival = trainArrival[row]
    Cars = trainCars[row]
    Line = trainLine[row]

    if Line in LINE_COLORS:
      LineColor = ColorMapping[Line]
      TextColor = TextColorMapping[Line]
    else:
      LineColor = "#bf5abc"
      TextColor = "#000000"


    rows.append(render.Row(
      expanded=True,
      main_align="space_between",
      cross_align="center",
      children=[
        render.Box(height=boxHeight, width=boxWidth, color= LineColor),

        render.Text("%s" % Cars, font = displayFont, offset = displayOffset),

        #render.Text(Destination, font = displayFont, offset = displayOffset),

        render.Marquee(
            width = marqueeWidth,
            child = render.Text(Destination, font = displayFont, offset = displayOffset)
            ),
        render.Text(Arrival, font = displayFont, offset = displayOffset), #"%d" % test
      ],
    ))

  # Create the column object with all the rows
  display4 = render.Column(
    #expanded=True,
    #main_align="space_between",
    cross_align="center",
        children=rows,
    )

  return display4

def generateDisplay5(trainDestination, trainArrival, trainCars, trainLine, selectedCars):
  trainRows = 5
  boxHeight = 5
  boxWidth = 4

  ColorMapping = json.decode(LINE_COLORS)
  TextColorMapping = json.decode(TEXT_COLORS)
  displayFont = "tom-thumb"
  displayOffset = 0

  if selectedCars == True:
    marqueeWidth = 40
  else:
    marqueeWidth = 45

  if trainRows > len(trainArrival):
    trainRows = len(trainArrival)

  # List to hold the Box objects for the current column
  rows = []

  #Title row to give some padding
  rows.append(render.Row(
    expanded=True,
    main_align="space_between",
    cross_align="center",
    children=[
      render.Box(height=2, width=64, color="#000"),
    ],
  ))

  # Loop through each row
  for row in range(trainRows):

    Destination = trainDestination[row]
    Arrival = trainArrival[row]
    Cars = trainCars[row]
    Line = trainLine[row]

    if Line in LINE_COLORS:
      LineColor = ColorMapping[Line]
      TextColor = TextColorMapping[Line]
    else:
      LineColor = "#bf5abc"
      TextColor = "#000000"


    rows.append(render.Row(
      expanded=True,
      main_align="space_between",
      cross_align="center",
      children=[
        render.Box(height=boxHeight, width=boxWidth, color= LineColor),

        render.Text("%s" % Cars, font = displayFont, offset = displayOffset),

        #render.Text(Destination, font = displayFont, offset = displayOffset),

        render.Marquee(
            width = marqueeWidth,
            child = render.Text(Destination, font = displayFont, offset = displayOffset)
            ),
        render.Text(Arrival, font = displayFont, offset = displayOffset), #"%d" % test
      ],
    ))

  # Create the column object with all the rows
  display5 = render.Column(
      cross_align="center",
      children=rows,
    )

  return display5

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "stationCode",
                name = "Select Station",
                desc = "Filter services by station",
                icon = "trainSubway",
                default = StationsOptions[59].value,
                options = StationsOptions,
            ),

            schema.Dropdown(
                id = "viewOption",
                name = "Display Options",
                desc = "Maximum Number of Trains to Display",
                icon = "sliders",
                default = DisplayOptions[1].value,
                options = DisplayOptions,
            ),

            schema.Dropdown(
                id = "groupCode",
                name = "Select Direction",
                desc = "Filter trains by Direction",
                icon = "arrowRightArrowLeft",
                default = GroupOptions[0].value,
                options = GroupOptions,
            ),

            schema.Dropdown(
                id = "metroLine",
                name = "Select rail line",
                desc = "Filter services by line",
                icon = "codeMerge",
                default = LineOptions[0].value,
                options = LineOptions,
            ),

            schema.Toggle(
                id = "displayCars",
                name = "Display Cars",
                desc = "Display number of cars per train",
                icon = "compress",
                default = True,
            ),

            schema.Text(
                id = "userAPI",
                name = "WMATA API Key",
                desc = "Enter API key",
                icon = "certificate",
            ),

        ],
    )

GroupOptions = [
    schema.Option(
        display = "ALL - No Filter",
        value = "ALL",
    ),
    schema.Option(
        display = "Eastbound/Northbound",
        value = "1",
    ),
    schema.Option(
        display = "Westbound/Southbound",
        value = "2",
    ),
]

LineOptions = [
    schema.Option(
        display = "ALL - No Filter",
        value = "ALL",
    ),
    schema.Option(
        display = "Red",
        value = "RL",
    ),
    schema.Option(
        display = "Orange",
        value = "OR",
    ),
    schema.Option(
        display = "Blue",
        value = "BL",
    ),
    schema.Option(
        display = "Green",
        value = "GR",
    ),
    schema.Option(
        display = "Yellow",
        value = "YL",
    ),
    schema.Option(
        display = "Silver",
        value = "SV",
    ),
]

DisplayOptions = [
    schema.Option(
        display = "5 Trains (No Labels)",
        value = "5",
    ),
    schema.Option(
        display = "4 Trains (Has Labels)",
        value = "4",
    ),
    schema.Option(
        display = "3 Trains (Small Font)",
        value = "3",
    ),
    schema.Option(
        display = "3 Trains (Large Font)",
        value = "3a",
    ),
    schema.Option(
        display = "2 Trains",
        value = "2",
    ),
]

StationsOptions = [
    schema.Option(
        display = "Addison Road-Seat Pleasant",
        value = "G03",
    ),
    schema.Option(
        display = "Anacostia",
        value = "F06",
    ),
    schema.Option(
        display = "Archives-Navy Memorial-Penn Quarter",
        value = "F02",
    ),
    schema.Option(
        display = "Arlington Cemetery",
        value = "C06",
    ),
    schema.Option(
        display = "Ashburn",
        value = "N12",
    ),
    schema.Option(
        display = "Ballston-MU",
        value = "K04",
    ),
    schema.Option(
        display = "Benning Road",
        value = "G01",
    ),
    schema.Option(
        display = "Bethesda",
        value = "A09",
    ),
    schema.Option(
        display = "Braddock Road",
        value = "C12",
    ),
    schema.Option(
        display = "Branch Ave",
        value = "F11",
    ),
    schema.Option(
        display = "Brookland-CUA",
        value = "B05",
    ),
    schema.Option(
        display = "Capitol Heights",
        value = "G02",
    ),
    schema.Option(
        display = "Capitol South",
        value = "D05",
    ),
    schema.Option(
        display = "Cheverly",
        value = "D11",
    ),
    schema.Option(
        display = "Clarendon",
        value = "K02",
    ),
    schema.Option(
        display = "Cleveland Park",
        value = "A05",
    ),
    schema.Option(
        display = "College Park-U of Md",
        value = "E09",
    ),
    schema.Option(
        display = "Columbia Heights",
        value = "E04",
    ),
    schema.Option(
        display = "Congress Heights",
        value = "F07",
    ),
    schema.Option(
        display = "Court House",
        value = "K01",
    ),
    schema.Option(
        display = "Crystal City",
        value = "C09",
    ),
    schema.Option(
        display = "Deanwood",
        value = "D10",
    ),
    schema.Option(
        display = "Dulles Airport",
        value = "N10",
    ),
    schema.Option(
        display = "Dunn Loring-Merrifield",
        value = "K07",
    ),
    schema.Option(
        display = "Dupont Circle",
        value = "A03",
    ),
    schema.Option(
        display = "East Falls Church",
        value = "K05",
    ),
    schema.Option(
        display = "Eastern Market",
        value = "D06",
    ),
    schema.Option(
        display = "Eisenhower Avenue",
        value = "C14",
    ),
    schema.Option(
        display = "Farragut North",
        value = "A02",
    ),
    schema.Option(
        display = "Farragut West",
        value = "C03",
    ),
    schema.Option(
        display = "Federal Center SW",
        value = "D04",
    ),
    schema.Option(
        display = "Federal Triangle",
        value = "D01",
    ),
    schema.Option(
        display = "Foggy Bottom-GWU",
        value = "C04",
    ),
    schema.Option(
        display = "Forest Glen",
        value = "B09",
    ),
    schema.Option(
        display = "Fort Totten - Red Line Only",
        value = "B06",
    ),
    schema.Option(
        display = "Fort Totten - Green and Yellow Lines Only",
        value = "E06",
    ),
    schema.Option(
        display = "Franconia-Springfield",
        value = "J03",
    ),
    schema.Option(
        display = "Friendship Heights",
        value = "A08",
    ),
    schema.Option(
        display = "Gallery Pl-Chinatown - Red Line Only",
        value = "B01",
    ),
    schema.Option(
        display = "Gallery Pl-Chinatown - Green and Yellow Lines Only",
        value = "F01",
    ),
    schema.Option(
        display = "Georgia Ave-Petworth",
        value = "E05",
    ),
    schema.Option(
        display = "Glenmont",
        value = "B11",
    ),
    schema.Option(
        display = "Greenbelt",
        value = "E10",
    ),
    schema.Option(
        display = "Greensboro",
        value = "N03",
    ),
    schema.Option(
        display = "Grosvenor-Strathmore",
        value = "A11",
    ),
    schema.Option(
        display = "Herndon",
        value = "N08",
    ),
    schema.Option(
        display = "Huntington",
        value = "C15",
    ),
    schema.Option(
        display = "Innovation Center",
        value = "N09",
    ),
    schema.Option(
        display = "Judiciary Square",
        value = "B02",
    ),
    schema.Option(
        display = "King St-Old Town",
        value = "C13",
    ),
    schema.Option(
        display = "Landover",
        value = "D12",
    ),
    schema.Option(
        display = "Largo Town Center",
        value = "G05",
    ),
    schema.Option(
        display = "L'Enfant Plaza - Blue, Orange, and Silver Lines Only",
        value = "D03",
    ),
    schema.Option(
        display = "L'Enfant Plaza - Green and Yellow Lines Only",
        value = "F03",
    ),
    schema.Option(
        display = "Loudoun Gateway",
        value = "N11",
    ),
    schema.Option(
        display = "McLean",
        value = "N01",
    ),
    schema.Option(
        display = "McPherson Square",
        value = "C02",
    ),
    schema.Option(
        display = "Medical Center",
        value = "A10",
    ),
    schema.Option(
        display = "Metro Center - Red Line Only",
        value = "A01",
    ),
    schema.Option(
        display = "Metro Center - Blue, Orange, and Silver Lines Only",
        value = "C01",
    ),
    schema.Option(
        display = "Minnesota Ave",
        value = "D09",
    ),
    schema.Option(
        display = "Morgan Boulevard",
        value = "G04",
    ),
    schema.Option(
        display = "Mt Vernon Sq 7th St-Convention Center",
        value = "E01",
    ),
    schema.Option(
        display = "Navy Yard-Ballpark",
        value = "F05",
    ),
    schema.Option(
        display = "Naylor Road",
        value = "F09",
    ),
    schema.Option(
        display = "New Carrollton",
        value = "D13",
    ),
    schema.Option(
        display = "NoMa-Gallaudet U",
        value = "B35",
    ),
    schema.Option(
        display = "Pentagon",
        value = "C07",
    ),
    schema.Option(
        display = "Pentagon City",
        value = "C08",
    ),
    schema.Option(
        display = "Potomac Ave",
        value = "D07",
    ),
    schema.Option(
        display = "Prince George's Plaza",
        value = "E08",
    ),
    schema.Option(
        display = "Reston Town Center",
        value = "N07",
    ),
    schema.Option(
        display = "Rhode Island Ave-Brentwood",
        value = "B04",
    ),
    schema.Option(
        display = "Rockville",
        value = "A14",
    ),
    schema.Option(
        display = "Ronald Reagan Washington National Airport",
        value = "C10",
    ),
    schema.Option(
        display = "Rosslyn",
        value = "C05",
    ),
    schema.Option(
        display = "Shady Grove",
        value = "A15",
    ),
    schema.Option(
        display = "Shaw-Howard U",
        value = "E02",
    ),
    schema.Option(
        display = "Silver Spring",
        value = "B08",
    ),
    schema.Option(
        display = "Stadium-Armory",
        value = "D08",
    ),
    schema.Option(
        display = "Suitland",
        value = "F10",
    ),
    schema.Option(
        display = "Takoma",
        value = "B07",
    ),
    schema.Option(
        display = "Tenleytown-AU",
        value = "A07",
    ),
    schema.Option(
        display = "Twinbrook",
        value = "A13",
    ),
    schema.Option(
        display = "Tysons Corner",
        value = "N02",
    ),
    schema.Option(
        display = "U Street/African-Amer Civil War Memorial/Cardozo",
        value = "E03",
    ),
    schema.Option(
        display = "Union Station",
        value = "B03",
    ),
    schema.Option(
        display = "Van Dorn Street",
        value = "J02",
    ),
    schema.Option(
        display = "Van Ness-UDC",
        value = "A06",
    ),
    schema.Option(
        display = "Vienna/Fairfax-GMU",
        value = "K08",
    ),
    schema.Option(
        display = "Virginia Square-GMU",
        value = "K03",
    ),
    schema.Option(
        display = "Waterfront",
        value = "F04",
    ),
    schema.Option(
        display = "West Falls Church-VT/UVA",
        value = "K06",
    ),
    schema.Option(
        display = "West Hyattsville",
        value = "E07",
    ),
    schema.Option(
        display = "Wheaton",
        value = "B10",
    ),
    schema.Option(
        display = "White Flint",
        value = "A12",
    ),
    schema.Option(
        display = "Wiehle-Reston East",
        value = "N06",
    ),
    schema.Option(
        display = "Woodley Park-Zoo/Adams Morgan",
        value = "A04",
    ),
]

LINE_COLORS = """
  {
    "RD": "#E51937",
    "OR": "#F7941D",
    "BL": "#0077C0",
    "GR": "#00A950",
    "YL": "#FFD204",
    "SV": "#DBDBDB"
  }
"""

TEXT_COLORS = """
  {
    "RD": "#FFFFFF",
    "OR": "#000000",
    "BL": "#FFFFFF",
    "GR": "#FFFFFF",
    "YL": "#000000",
    "SV": "#000000"
  }
"""
