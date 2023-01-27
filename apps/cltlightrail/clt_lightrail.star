"""
Applet: CLT Lightrail
Summary: Tracks CLT LYNX Lightrail Trains w/ Stations
Description: Displays in real-time when North & South lightrail trains will arrive in Charlotte's LYNX Lightrail System - All Stations available
Author: Kevin Connell
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#Load LYNX icon from base64 encoded data 29x13
lynx_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAB0AAAANCAYAAABVRWWUAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABmJLR0QA/wD/AP+gvaeTAAAAB3RJTUUH5gcTBA8P7Gvf3AAAA+5JREFUOMuNlG1o1XUUxz/n93+493+v29zj1dqcY8NppDhbLvNZSTIzJSIQekJ6YVmiEBXRu0oLIqigJKXyRRAEImhJ0oQm+DBEK3XlFs221jabd9Pr3b3/p9+vNxcpEvO8Oy++fM758j1HuM06eaILixyiUujiJSZObadq8d4aZXKttuO2GaNbE26i0UtOKbdt6y+jpScW91B+1orTqu+CmcyFLLinDQD5P9iF3nMMdn9O+Yx2JMzjpBtSJhxbpEzwUBSFbbZt1bkJhWM7FY5tVydcx1NKobUhNmrAj+wtSSc83DB7IyJya+iZ0/vxkrUYDFF+kHxgV0pUXKxsFgomLdr0RVpdTKQzIylPxr1kuYfO1ytTeERMtCWO/SlhHKFJHnJrVzymTM6f8cZ5AGzZcvA/QBMb1n3pkLBz9O+qcYd66xZGE1ebAy2jGS/6qLH92Mjre5fzW87jWqyxLPhko3D017h/0wOvHRvo2WkJ/g6FwaDN1JRD+7t9ABZgyz+gS4A2YNj48cHKCid5zTcbO+q5t8aTfJVn3lxWO5bbfKR6iShSJZdaStpzQBfQaCLu2trB3CAO3om1IVu09h44lt4qGX8RsBrotkuieuCDEvSli691xN39I03bDw8/e3wwXoIxo8C3+6S6RRSNQDfwHDAfyAD7RDiuNS9WTpGR1Q35+1793qV3zAbFGsn4bwHjwH6gR5VWfqEEPGRis3tWyzT9xKqGixPF+D2BQIQ6EXYAWWAncD/wHXCyNHSl1mywlNTu35CzahO5ta2VISgQYQbgAruAH4DABh4uTW2As2LJ0tS2b0YLw8UfpcZtLgnOA68APcCDJWfeBuYBGMNcS8nmbQsKQ93D+uXOSxW/nBpxvxbhGeBOYCVwBzAEYAPVwKdAXOpXOEp1mWnJAT/Sdsn2zhJQARXAxwbGMezHyOXpZVHmydbJpTUeTXvOlb3f12/vIbQuS21wBpgOhIADYHav50aQlMDMqS4DV0Oq0i6jQ9eQ8sS/Um0rSDuKR5sn2dwySGt9fWpoPLc20tHTGBmLrfIPO5Z3nq3esYFswdz0FG9An5pfw6Z5NfjRpNd0/atCLt1OEIVcyVl41nXSHkhUgLhAdvwL6jLPZ4RwmSFcB+LbibIDTlnTUZ373Q/L7sYKrtDxWR6ze/1NwQJw5GQfUyc7ydrz5iR1ttKV4h9+UJjIF5VJyCSJhPKMjqvFRM0oPVsZyYjwp1huV+jN/CkZDIR2qgET+2TDAmuWPX7LL2cDaGOYdOZQZgW9cRDORQcrhbAqaQeOZXzEJMpAFzFcNsgJbSd/toJs1igLhxBjVzFxPWL1qvXcTv0Nn8WovFgP3ZQAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjItMDctMTlUMDQ6MTQ6NDUrMDA6MDDsgdXVAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIyLTA3LTE5VDA0OjE0OjQ1KzAwOjAwndxtaQAAAABJRU5ErkJggg==
""")

LIGHTRAIL = "lightrail"
CACHE_TTL_SECONDS = 60

STATION_LIST = {
    "UNC Charlotte Main": "unccharlotte",
    "J.W. Clay Blvd./UNC Charlotte": "jwclay",
    "McCullough": "mccullough",
    "University City Blvd.": "universitycity",
    "Tom Hunter": "tomhunter",
    "Old Concord Road": "oldconcord",
    "Sugar Creek": "sugarcreek",
    "36th Street": "36thstreet",
    "25th Street": "25thstreet",
    "Parkwood": "parkwood",
    "9th Street": "9thstreet",
    "7th Street": "7thstreet",
    "CTC/Arena": "ctc",
    "3rd Street": "3rdstreet",
    "Stonewall": "stonewall",
    "Carson": "carson",
    "Bland": "bland",
    "East/West Blvd.": "eastwest",
    "New Bern": "newbern",
    "Scaleybark": "scaleybark",
    "Woodlawn": "woodlawn",
    "Tyvola": "tyvola",
    "Archdale": "archdale",
    "Arrowood": "arrowood",
    "Sharon Road West": "sharonroad",
    "I-485/South Blvd.": "i485",
}

def get_schema():
    station_options = [
        schema.Option(display = key, value = value)
        for key, value in STATION_LIST.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "LYNX Blue Line",
                desc = "Lightrail Stations",
                icon = "trainSubway",
                default = station_options[0].value,
                options = station_options,
            ),
        ],
    )

def main(config):
    station_id = config.get("station")

    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)

    #Fixes Day format
    dayDisplay = now.format("Mon")
    if dayDisplay == "Tue":
        dayDisplay = "Tues"

    if dayDisplay == "Thu":
        dayDisplay = "Thur"

    dayAPI = now.format("Monday")

    if dayAPI == "Saturday":  #Saturday API Schedule
        unccAPI = "https://wirelesscats.ridetransit.org/BusSchedules/Search/Schedule?routeCode=7545&routeDirection=Inbound&bookingId=93&routeType=Saturday"
        i485API = "https://wirelesscats.ridetransit.org/BusSchedules/Search/Schedule?routeCode=7545&routeDirection=Outbound&bookingId=93&routeType=Saturday"

    elif dayAPI == "Sunday":  #Sunday API Schedule
        unccAPI = "https://wirelesscats.ridetransit.org/BusSchedules/Search/Schedule?routeCode=7545&routeDirection=Inbound&bookingId=93&routeType=Sunday"
        i485API = "https://wirelesscats.ridetransit.org/BusSchedules/Search/Schedule?routeCode=7545&routeDirection=Outbound&bookingId=93&routeType=Sunday"

    else:  #Weekday API Schedule
        unccAPI = "https://wirelesscats.ridetransit.org/BusSchedules/Search/Schedule?routeCode=7545&routeDirection=Inbound&bookingId=93&routeType=Weekday"
        i485API = "https://wirelesscats.ridetransit.org/BusSchedules/Search/Schedule?routeCode=7545&routeDirection=Outbound&bookingId=93&routeType=Weekday"

    unccTrain = {LIGHTRAIL: unccAPI}
    i485Train = {LIGHTRAIL: i485API}

    #Arrays that have lightrail times
    unccTime = get_times(unccTrain)
    i485Time = get_times(i485Train)

    #Gets train schedule based on what station is selected in schema
    if station_id == "i485":
        iN = 0
        iS = 25
        station_name = "I-485/South Blvd. "

    elif station_id == "jwclay":
        iN = 24
        iS = 1
        station_name = "J.W. Clay Blvd.   "

    elif station_id == "mccullough":
        iN = 23
        iS = 2
        station_name = "McCullough        "

    elif station_id == "universitycity":
        iN = 22
        iS = 3
        station_name = "Univ. City Blvd.  "

    elif station_id == "tomhunter":
        iN = 21
        iS = 4
        station_name = "Tom Hunter        "

    elif station_id == "oldconcord":
        iN = 20
        iS = 5
        station_name = "Old Concord Road  "

    elif station_id == "sugarcreek":
        iN = 19
        iS = 6
        station_name = "Sugar Creek       "

    elif station_id == "36thstreet":
        iN = 18
        iS = 7
        station_name = "36th Street       "

    elif station_id == "25thstreet":
        iN = 17
        iS = 8
        station_name = "25th Street       "

    elif station_id == "parkwood":
        iN = 16
        iS = 9
        station_name = "Parkwood          "

    elif station_id == "9thstreet":
        iN = 15
        iS = 10
        station_name = "9th Street        "

    elif station_id == "7thstreet":
        iN = 14
        iS = 11
        station_name = "7th Street        "

    elif station_id == "ctc":
        iN = 13
        iS = 12
        station_name = "CTC/Arena         "

    elif station_id == "3rdstreet":
        iN = 12
        iS = 13
        station_name = "3rd Street        "

    elif station_id == "stonewall":
        iN = 11
        iS = 14
        station_name = "Stonewall         "

    elif station_id == "carson":
        iN = 10
        iS = 15
        station_name = "Carson            "

    elif station_id == "bland":
        iN = 9
        iS = 16
        station_name = "Bland             "

    elif station_id == "eastwest":
        iN = 8
        iS = 17
        station_name = "East/West Blvd.   "

    elif station_id == "newbern":
        iN = 7
        iS = 18
        station_name = "New Bern          "

    elif station_id == "scaleybark":
        iN = 6
        iS = 19
        station_name = "Scaleybark        "

    elif station_id == "woodlawn":
        iN = 5
        iS = 20
        station_name = "Woodlawn          "

    elif station_id == "tyvola":
        iN = 4
        iS = 21
        station_name = "Tyvola            "

    elif station_id == "archdale":
        iN = 3
        iS = 22
        station_name = "Archdale          "

    elif station_id == "arrowood":
        iN = 2
        iS = 23
        station_name = "Arrowood          "

    elif station_id == "sharonroad":
        iN = 1
        iS = 24
        station_name = "Sharon Road West  "

    else:  #Default: UNC Charlotte Main
        iN = 25
        iS = 0
        station_name = "UNC Charlotte Main"

    currentDate = now.format("2006-01-02")  #Default date

    #---------------------------------------------- North ----------------------------------------------

    #Removes times that don't exist / re-arranges times to have first train be in [i][0]
    rearrangeUNCCtimes(unccTime)

    convertTimeBack = ""

    #---North First Lightrail time---
    if " AM" in unccTime[iN][0]:  #AM Times
        changeFormat = unccTime[iN][0].replace(" AM", "")
        changeFormat = changeFormat.split(":")
        convertHourToInt = int(changeFormat[0])

        #For between 1AM (T05) & 5AM (T09) times - First Train
        convertTimeBack = "T0" + str(convertHourToInt + 4) + ":" + changeFormat[1] + "Z"

    nFirstTrain = time.parse_time(str(currentDate) + convertTimeBack, format = "2006-01-02T15:04Z").in_location(timezone)  #First Lightrail

    lrFirstNorth_Time = nFirstTrain - now
    nFirstDays = math.floor(lrFirstNorth_Time.hours / 24)
    nFirstHours = math.floor(lrFirstNorth_Time.hours - nFirstDays * 24)
    nFirstMinutes = math.floor(lrFirstNorth_Time.minutes - (nFirstDays * 24 * 60 + nFirstHours * 60))
    nMinTotalTime = (nFirstHours * 60) + nFirstMinutes

    nFirstTrainMin = nMinTotalTime
    nText = ""

    #Goes through each North (UNCC) Train Time to find which is closest to the current time
    for i in range(0, len(unccTime[iN])):
        if " AM" in unccTime[iN][i]:  #AM Times
            changeFormat = unccTime[iN][i].replace(" AM", "")
            changeFormat = changeFormat.split(":")
            convertHourToInt = int(changeFormat[0])

            if convertHourToInt > 5 and convertHourToInt < 12:  #4-27: For between 6AM (T10) and 11AM (T15) times
                convertTimeBack = "T" + str(convertHourToInt + 4) + ":" + changeFormat[1] + "Z"

            elif convertHourToInt < 6:  #0-3, 71, 72: For between 1AM (T05) & 5AM (T09) times
                convertTimeBack = "T0" + str(convertHourToInt + 4) + ":" + changeFormat[1] + "Z"

            else:  #69, 70: For 12AM times (T04)
                convertTimeBack = "T0" + str(convertHourToInt - 8) + ":" + changeFormat[1] + "Z"

        else:  #PM Times
            changeFormat = unccTime[iN][i].replace(" PM", "")
            changeFormat = changeFormat.split(":")
            convertHourToInt = int(changeFormat[0])

            if convertHourToInt > 7 and convertHourToInt < 12:  #60-68: For between 8PM (T00) & 11PM (T03)
                convertTimeBack = "T0" + str(convertHourToInt - 8) + ":" + changeFormat[1] + "Z"

            elif convertHourToInt < 8:  #32-59: For between 1PM (T17) & 7PM (T23)
                convertTimeBack = "T" + str(convertHourToInt + 16) + ":" + changeFormat[1] + "Z"

            else:  #28-31: For 12PM times (T16)
                convertTimeBack = "T" + str(convertHourToInt + 4) + ":" + changeFormat[1] + "Z"

        nTrain = time.parse_time(str(currentDate) + convertTimeBack, format = "2006-01-02T15:04Z").in_location(timezone)  #Each Lightrail

        lrNorth_Time = nTrain - now
        nDays = math.floor(lrNorth_Time.hours / 24)
        nHours = math.floor(lrNorth_Time.hours - nDays * 24)
        nMinutes = math.floor(lrNorth_Time.minutes - (nDays * 24 * 60 + nHours * 60))
        nTimeTotal = (nHours * 60) + nMinutes

        if nTimeTotal < nMinTotalTime:
            nMinTotalTime = (nTimeTotal + 1)  #Add 1 min to fix rounding

            #Fixes spacing based on if min. is single/double digit - Displays upcoming train time
            if int(nMinTotalTime) < 10:
                nText = "Train to  UNCC:  " + str(nMinTotalTime) + "min."
            else:
                nText = "Train to  UNCC: " + str(nMinTotalTime) + "min."

        if (nFirstTrainMin == nMinTotalTime):  #Resets to First Lightrail - if array index is at end
            if int(nMinTotalTime) < 10:
                nText = "Train to  UNCC:  " + str(nMinTotalTime + 1) + "min."
            else:
                nText = "Train to  UNCC: " + str(nMinTotalTime + 1) + "min."

    #---------------------------------------------- South ----------------------------------------------

    #Removes times that don't exist / re-arranges times to have first train be in [i][0]
    rearrangeI485times(i485Time)

    #---South First Lightrail time---
    if " AM" in i485Time[iS][0]:  #AM Times
        changeFormat = i485Time[iS][0].replace(" AM", "")
        changeFormat = changeFormat.split(":")
        convertHourToInt = int(changeFormat[0])

        #For between 1AM (T05) & 5AM (T09) times - First Train
        convertTimeBack = "T0" + str(convertHourToInt + 4) + ":" + changeFormat[1] + "Z"

    sFirstTrain = time.parse_time(str(currentDate) + convertTimeBack, format = "2006-01-02T15:04Z").in_location(timezone)  #First Lightrail

    lrFirstSouth_Time = sFirstTrain - now
    sFirstDays = math.floor(lrFirstSouth_Time.hours / 24)
    sFirstHours = math.floor(lrFirstSouth_Time.hours - sFirstDays * 24)
    sFirstMinutes = math.floor(lrFirstSouth_Time.minutes - (sFirstDays * 24 * 60 + sFirstHours * 60))
    sMinTotalTime = (sFirstHours * 60) + sFirstMinutes

    sFirstTrainMin = sMinTotalTime
    sText = ""

    #Goes through each South (I-485) Train Time to find which is closest to the current time
    for i in range(0, len(i485Time[iS])):
        if " AM" in i485Time[iS][i]:  #AM Times
            changeFormat = i485Time[iS][i].replace(" AM", "")
            changeFormat = changeFormat.split(":")
            convertHourToInt = int(changeFormat[0])

            if convertHourToInt > 5 and convertHourToInt < 12:  #4-27: For between 6AM (T10) and 11AM (T15) times
                convertTimeBack = "T" + str(convertHourToInt + 4) + ":" + changeFormat[1] + "Z"

            elif convertHourToInt < 6:  #0-3, 71, 72: For between 1AM (T05) & 5AM (T09) times
                convertTimeBack = "T0" + str(convertHourToInt + 4) + ":" + changeFormat[1] + "Z"

            else:  #69, 70: For 12AM times (T04)
                convertTimeBack = "T0" + str(convertHourToInt - 8) + ":" + changeFormat[1] + "Z"

        else:  #PM Times
            changeFormat = i485Time[iS][i].replace(" PM", "")
            changeFormat = changeFormat.split(":")
            convertHourToInt = int(changeFormat[0])

            if convertHourToInt > 7 and convertHourToInt < 12:  #60-68: For between 8PM (T00) & 11PM (T03)
                convertTimeBack = "T0" + str(convertHourToInt - 8) + ":" + changeFormat[1] + "Z"

            elif convertHourToInt < 8:  #32-59: For between 1PM (T17) & 7PM (T23)
                convertTimeBack = "T" + str(convertHourToInt + 16) + ":" + changeFormat[1] + "Z"

            else:  #28-31: For 12PM times (T16)
                convertTimeBack = "T" + str(convertHourToInt + 4) + ":" + changeFormat[1] + "Z"

        sTrain = time.parse_time(str(currentDate) + convertTimeBack, format = "2006-01-02T15:04Z").in_location(timezone)  #Each Lightrail

        lrSouth_Time = sTrain - now
        sDays = math.floor(lrSouth_Time.hours / 24)
        sHours = math.floor(lrSouth_Time.hours - sDays * 24)
        sMinutes = math.floor(lrSouth_Time.minutes - (sDays * 24 * 60 + sHours * 60))
        sTimeTotal = (sHours * 60) + sMinutes

        if sTimeTotal < sMinTotalTime:
            sMinTotalTime = (sTimeTotal + 1)  #Add 1 min to fix rounding

            #Fixes format based on if time is single/double digit - Displays upcoming train
            if int(sMinTotalTime) < 10:
                sText = "Train to I-485:  " + str(sMinTotalTime) + "min."
            else:
                sText = "Train to I-485: " + str(sMinTotalTime) + "min."

        if (sFirstTrainMin == sMinTotalTime):  #Resets to First Lightrail - if array index is at end
            if int(sMinTotalTime) < 10:
                sText = "Train to I-485:  " + str(sMinTotalTime + 1) + "min."
            else:
                sText = "Train to I-485: " + str(sMinTotalTime + 1) + "min."

    return render.Root(
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Box(
                    width = 29,
                    height = 32,
                    child = render.Column(
                        children = [
                            render.Column(
                                children = [
                                    render.Box(
                                        #Lynx Logo
                                        width = 29,
                                        height = 15,
                                        child = render.Image(src = lynx_ICON),
                                    ),
                                    render.Box(
                                        #Current date
                                        width = 29,
                                        height = 8,
                                        child = render.Text(content = now.format("1/2")),
                                    ),
                                    render.Box(
                                        #Gold Line
                                        width = 29,
                                        height = 1,
                                        color = "#a39160",
                                    ),
                                    render.Box(
                                        #Days of the week (Sun, Mon, Tues, Wed, Thur, Fri, Sat)
                                        width = 29,
                                        height = 8,
                                        child = render.Text(content = dayDisplay),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Box(
                    #Station Name
                    child = render.Column(
                        main_align = "end",
                        children = [
                            render.Column(
                                children = [
                                    render.Box(
                                        width = 35,
                                        height = 15,
                                        child = render.Row(
                                            expanded = True,
                                            main_align = "start",
                                            children = [
                                                render.Marquee(
                                                    child = render.Text(content = station_name, font = "6x13"),
                                                    width = 42,
                                                    offset_start = 0,
                                                ),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                            render.Box(
                                #North: UNCC Lightrail times
                                width = 35,
                                height = 8,
                                color = "#003ca7",
                                child = render.Row(
                                    expanded = True,
                                    main_align = "start",
                                    children = [
                                        render.Circle(
                                            #N Circle
                                            child = render.Text("N", font = "5x8"),
                                            diameter = 8,
                                            color = "#008752",
                                        ),
                                        render.Marquee(
                                            child = render.Text(content = nText, font = "5x8"),
                                            width = 40,
                                            offset_start = 0,
                                        ),
                                    ],
                                ),
                            ),
                            render.Box(
                                #Gold Line
                                width = 35,
                                height = 1,
                                color = "#a39160",
                            ),
                            render.Box(
                                #South: I-485 Lightrail times
                                width = 35,
                                height = 8,
                                color = "#003ca7",
                                child = render.Row(
                                    expanded = True,
                                    main_align = "start",
                                    children = [
                                        render.Circle(
                                            #S Circle
                                            child = render.Text("S", font = "5x8"),
                                            diameter = 8,
                                            color = "#d31245",
                                        ),
                                        render.Marquee(
                                            child = render.Text(content = sText, font = "5x8"),
                                            width = 40,
                                            offset_start = 0,
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
        delay = 100,
    )

def get_times(urls):
    alltimes = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        alltimes.extend(decodedata["stationStops"])
        all([i, alltimes])

    return alltimes

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = ttl_seconds)

    return res.body()

def rearrangeUNCCtimes(unccTime):
    #Time doesn't exist so it's removed
    unccTime[0].remove("12:00 AM")
    unccTime[15].remove("12:00 AM")

    unccTime[0].append(unccTime[0].pop(unccTime[0].index("12:30 AM")))
    unccTime[0].append(unccTime[0].pop(unccTime[0].index("1:00 AM")))

    unccTime[1].append(unccTime[1].pop(unccTime[1].index("12:02 AM")))
    unccTime[1].append(unccTime[1].pop(unccTime[1].index("12:32 AM")))
    unccTime[1].append(unccTime[1].pop(unccTime[1].index("1:02 AM")))

    unccTime[2].append(unccTime[2].pop(unccTime[2].index("12:04 AM")))
    unccTime[2].append(unccTime[2].pop(unccTime[2].index("12:34 AM")))
    unccTime[2].append(unccTime[2].pop(unccTime[2].index("1:04 AM")))

    unccTime[3].append(unccTime[3].pop(unccTime[3].index("12:07 AM")))
    unccTime[3].append(unccTime[3].pop(unccTime[3].index("12:37 AM")))
    unccTime[3].append(unccTime[3].pop(unccTime[3].index("1:07 AM")))

    unccTime[4].append(unccTime[4].pop(unccTime[4].index("12:09 AM")))
    unccTime[4].append(unccTime[4].pop(unccTime[4].index("12:39 AM")))
    unccTime[4].append(unccTime[4].pop(unccTime[4].index("1:09 AM")))

    unccTime[5].append(unccTime[5].pop(unccTime[5].index("12:11 AM")))
    unccTime[5].append(unccTime[5].pop(unccTime[5].index("12:41 AM")))
    unccTime[5].append(unccTime[5].pop(unccTime[5].index("1:11 AM")))

    unccTime[6].append(unccTime[6].pop(unccTime[6].index("12:13 AM")))
    unccTime[6].append(unccTime[6].pop(unccTime[6].index("12:43 AM")))
    unccTime[6].append(unccTime[6].pop(unccTime[6].index("1:13 AM")))

    unccTime[7].append(unccTime[7].pop(unccTime[7].index("12:15 AM")))
    unccTime[7].append(unccTime[7].pop(unccTime[7].index("12:45 AM")))
    unccTime[7].append(unccTime[7].pop(unccTime[7].index("1:15 AM")))

    unccTime[8].append(unccTime[8].pop(unccTime[8].index("12:18 AM")))
    unccTime[8].append(unccTime[8].pop(unccTime[8].index("12:48 AM")))
    unccTime[8].append(unccTime[8].pop(unccTime[8].index("1:18 AM")))

    unccTime[9].append(unccTime[9].pop(unccTime[9].index("12:20 AM")))
    unccTime[9].append(unccTime[9].pop(unccTime[9].index("12:50 AM")))
    unccTime[9].append(unccTime[9].pop(unccTime[9].index("1:20 AM")))

    unccTime[10].append(unccTime[10].pop(unccTime[10].index("12:21 AM")))
    unccTime[10].append(unccTime[10].pop(unccTime[10].index("12:51 AM")))
    unccTime[10].append(unccTime[10].pop(unccTime[10].index("1:21 AM")))

    unccTime[11].append(unccTime[11].pop(unccTime[11].index("12:23 AM")))
    unccTime[11].append(unccTime[11].pop(unccTime[11].index("12:53 AM")))
    unccTime[11].append(unccTime[11].pop(unccTime[11].index("1:23 AM")))

    unccTime[12].append(unccTime[12].pop(unccTime[12].index("12:25 AM")))
    unccTime[12].append(unccTime[12].pop(unccTime[12].index("12:55 AM")))
    unccTime[12].append(unccTime[12].pop(unccTime[12].index("1:25 AM")))

    unccTime[13].append(unccTime[13].pop(unccTime[13].index("12:27 AM")))
    unccTime[13].append(unccTime[13].pop(unccTime[13].index("12:57 AM")))
    unccTime[13].append(unccTime[13].pop(unccTime[13].index("1:27 AM")))

    unccTime[14].append(unccTime[14].pop(unccTime[14].index("12:28 AM")))
    unccTime[14].append(unccTime[14].pop(unccTime[14].index("12:58 AM")))
    unccTime[14].append(unccTime[14].pop(unccTime[14].index("1:28 AM")))

    unccTime[15].append(unccTime[15].pop(unccTime[15].index("12:30 AM")))
    unccTime[15].append(unccTime[15].pop(unccTime[15].index("1:00 AM")))
    unccTime[15].append(unccTime[15].pop(unccTime[15].index("1:30 AM")))

    unccTime[16].append(unccTime[16].pop(unccTime[16].index("12:02 AM")))
    unccTime[16].append(unccTime[16].pop(unccTime[16].index("12:32 AM")))
    unccTime[16].append(unccTime[16].pop(unccTime[16].index("1:02 AM")))
    unccTime[16].append(unccTime[16].pop(unccTime[16].index("1:32 AM")))

    unccTime[17].append(unccTime[17].pop(unccTime[17].index("12:04 AM")))
    unccTime[17].append(unccTime[17].pop(unccTime[17].index("12:34 AM")))
    unccTime[17].append(unccTime[17].pop(unccTime[17].index("1:04 AM")))
    unccTime[17].append(unccTime[17].pop(unccTime[17].index("1:34 AM")))

    unccTime[18].append(unccTime[18].pop(unccTime[18].index("12:06 AM")))
    unccTime[18].append(unccTime[18].pop(unccTime[18].index("12:36 AM")))
    unccTime[18].append(unccTime[18].pop(unccTime[18].index("1:06 AM")))
    unccTime[18].append(unccTime[18].pop(unccTime[18].index("1:36 AM")))

    unccTime[19].append(unccTime[19].pop(unccTime[19].index("12:09 AM")))
    unccTime[19].append(unccTime[19].pop(unccTime[19].index("12:39 AM")))
    unccTime[19].append(unccTime[19].pop(unccTime[19].index("1:09 AM")))
    unccTime[19].append(unccTime[19].pop(unccTime[19].index("1:39 AM")))

    unccTime[20].append(unccTime[20].pop(unccTime[20].index("12:12 AM")))
    unccTime[20].append(unccTime[20].pop(unccTime[20].index("12:42 AM")))
    unccTime[20].append(unccTime[20].pop(unccTime[20].index("1:12 AM")))
    unccTime[20].append(unccTime[20].pop(unccTime[20].index("1:42 AM")))

    unccTime[21].append(unccTime[21].pop(unccTime[21].index("12:16 AM")))
    unccTime[21].append(unccTime[21].pop(unccTime[21].index("12:46 AM")))
    unccTime[21].append(unccTime[21].pop(unccTime[21].index("1:16 AM")))
    unccTime[21].append(unccTime[21].pop(unccTime[21].index("1:46 AM")))

    unccTime[22].append(unccTime[22].pop(unccTime[22].index("12:18 AM")))
    unccTime[22].append(unccTime[22].pop(unccTime[22].index("12:48 AM")))
    unccTime[22].append(unccTime[22].pop(unccTime[22].index("1:18 AM")))
    unccTime[22].append(unccTime[22].pop(unccTime[22].index("1:48 AM")))

    unccTime[23].append(unccTime[23].pop(unccTime[23].index("12:21 AM")))
    unccTime[23].append(unccTime[23].pop(unccTime[23].index("12:51 AM")))
    unccTime[23].append(unccTime[23].pop(unccTime[23].index("1:21 AM")))
    unccTime[23].append(unccTime[23].pop(unccTime[23].index("1:51 AM")))

    unccTime[24].append(unccTime[24].pop(unccTime[24].index("12:24 AM")))
    unccTime[24].append(unccTime[24].pop(unccTime[24].index("12:54 AM")))
    unccTime[24].append(unccTime[24].pop(unccTime[24].index("1:24 AM")))
    unccTime[24].append(unccTime[24].pop(unccTime[24].index("1:54 AM")))

    unccTime[25].append(unccTime[25].pop(unccTime[25].index("12:27 AM")))
    unccTime[25].append(unccTime[25].pop(unccTime[25].index("12:57 AM")))
    unccTime[25].append(unccTime[25].pop(unccTime[25].index("1:27 AM")))
    unccTime[25].append(unccTime[25].pop(unccTime[25].index("1:57 AM")))

def rearrangeI485times(i485Time):
    #Time doesn't exist so it's removed
    i485Time[17].remove("12:00 AM")

    i485Time[0].append(i485Time[0].pop(i485Time[0].index("12:20 AM")))
    i485Time[0].append(i485Time[0].pop(i485Time[0].index("12:50 AM")))

    i485Time[1].append(i485Time[1].pop(i485Time[1].index("12:23 AM")))
    i485Time[1].append(i485Time[1].pop(i485Time[1].index("12:53 AM")))

    i485Time[2].append(i485Time[2].pop(i485Time[2].index("12:26 AM")))
    i485Time[2].append(i485Time[2].pop(i485Time[2].index("12:56 AM")))

    i485Time[3].append(i485Time[3].pop(i485Time[3].index("12:29 AM")))
    i485Time[3].append(i485Time[3].pop(i485Time[3].index("12:59 AM")))

    i485Time[4].append(i485Time[4].pop(i485Time[4].index("12:02 AM")))
    i485Time[4].append(i485Time[4].pop(i485Time[4].index("12:32 AM")))
    i485Time[4].append(i485Time[4].pop(i485Time[4].index("1:02 AM")))

    i485Time[5].append(i485Time[5].pop(i485Time[5].index("12:05 AM")))
    i485Time[5].append(i485Time[5].pop(i485Time[5].index("12:35 AM")))
    i485Time[5].append(i485Time[5].pop(i485Time[5].index("1:05 AM")))

    i485Time[6].append(i485Time[6].pop(i485Time[6].index("12:09 AM")))
    i485Time[6].append(i485Time[6].pop(i485Time[6].index("12:39 AM")))
    i485Time[6].append(i485Time[6].pop(i485Time[6].index("1:09 AM")))

    i485Time[7].append(i485Time[7].pop(i485Time[7].index("12:11 AM")))
    i485Time[7].append(i485Time[7].pop(i485Time[7].index("12:41 AM")))
    i485Time[7].append(i485Time[7].pop(i485Time[7].index("1:11 AM")))

    i485Time[8].append(i485Time[8].pop(i485Time[8].index("12:14 AM")))
    i485Time[8].append(i485Time[8].pop(i485Time[8].index("12:44 AM")))
    i485Time[8].append(i485Time[8].pop(i485Time[8].index("1:14 AM")))

    i485Time[9].append(i485Time[9].pop(i485Time[9].index("12:16 AM")))
    i485Time[9].append(i485Time[9].pop(i485Time[9].index("12:46 AM")))
    i485Time[9].append(i485Time[9].pop(i485Time[9].index("1:16 AM")))

    i485Time[10].append(i485Time[10].pop(i485Time[10].index("12:19 AM")))
    i485Time[10].append(i485Time[10].pop(i485Time[10].index("12:49 AM")))
    i485Time[10].append(i485Time[10].pop(i485Time[10].index("1:19 AM")))

    i485Time[11].append(i485Time[11].pop(i485Time[11].index("12:21 AM")))
    i485Time[11].append(i485Time[11].pop(i485Time[11].index("12:51 AM")))
    i485Time[11].append(i485Time[11].pop(i485Time[11].index("1:21 AM")))

    i485Time[12].append(i485Time[12].pop(i485Time[12].index("12:23 AM")))
    i485Time[12].append(i485Time[12].pop(i485Time[12].index("12:53 AM")))
    i485Time[12].append(i485Time[12].pop(i485Time[12].index("1:23 AM")))

    i485Time[13].append(i485Time[13].pop(i485Time[13].index("12:24 AM")))
    i485Time[13].append(i485Time[13].pop(i485Time[13].index("12:54 AM")))
    i485Time[13].append(i485Time[13].pop(i485Time[13].index("1:24 AM")))

    i485Time[14].append(i485Time[14].pop(i485Time[14].index("12:26 AM")))
    i485Time[14].append(i485Time[14].pop(i485Time[14].index("12:56 AM")))
    i485Time[14].append(i485Time[14].pop(i485Time[14].index("1:26 AM")))

    i485Time[15].append(i485Time[15].pop(i485Time[15].index("12:27 AM")))
    i485Time[15].append(i485Time[15].pop(i485Time[15].index("12:57 AM")))
    i485Time[15].append(i485Time[15].pop(i485Time[15].index("1:27 AM")))

    i485Time[16].append(i485Time[16].pop(i485Time[16].index("12:28 AM")))
    i485Time[16].append(i485Time[16].pop(i485Time[16].index("12:58 AM")))
    i485Time[16].append(i485Time[16].pop(i485Time[16].index("1:28 AM")))

    i485Time[17].append(i485Time[17].pop(i485Time[17].index("12:30 AM")))
    i485Time[17].append(i485Time[17].pop(i485Time[17].index("1:00 AM")))
    i485Time[17].append(i485Time[17].pop(i485Time[17].index("1:30 AM")))

    i485Time[18].append(i485Time[18].pop(i485Time[18].index("12:02 AM")))
    i485Time[18].append(i485Time[18].pop(i485Time[18].index("12:32 AM")))
    i485Time[18].append(i485Time[18].pop(i485Time[18].index("1:02 AM")))
    i485Time[18].append(i485Time[18].pop(i485Time[18].index("1:32 AM")))

    i485Time[19].append(i485Time[19].pop(i485Time[19].index("12:04 AM")))
    i485Time[19].append(i485Time[19].pop(i485Time[19].index("12:34 AM")))
    i485Time[19].append(i485Time[19].pop(i485Time[19].index("1:04 AM")))
    i485Time[19].append(i485Time[19].pop(i485Time[19].index("1:34 AM")))

    i485Time[20].append(i485Time[20].pop(i485Time[20].index("12:07 AM")))
    i485Time[20].append(i485Time[20].pop(i485Time[20].index("12:37 AM")))
    i485Time[20].append(i485Time[20].pop(i485Time[20].index("1:07 AM")))
    i485Time[20].append(i485Time[20].pop(i485Time[20].index("1:37 AM")))

    i485Time[21].append(i485Time[21].pop(i485Time[21].index("12:09 AM")))
    i485Time[21].append(i485Time[21].pop(i485Time[21].index("12:39 AM")))
    i485Time[21].append(i485Time[21].pop(i485Time[21].index("1:09 AM")))
    i485Time[21].append(i485Time[21].pop(i485Time[21].index("1:39 AM")))

    i485Time[22].append(i485Time[22].pop(i485Time[22].index("12:11 AM")))
    i485Time[22].append(i485Time[22].pop(i485Time[22].index("12:41 AM")))
    i485Time[22].append(i485Time[22].pop(i485Time[22].index("1:11 AM")))
    i485Time[22].append(i485Time[22].pop(i485Time[22].index("1:41 AM")))

    i485Time[23].append(i485Time[23].pop(i485Time[23].index("12:14 AM")))
    i485Time[23].append(i485Time[23].pop(i485Time[23].index("12:44 AM")))
    i485Time[23].append(i485Time[23].pop(i485Time[23].index("1:14 AM")))
    i485Time[23].append(i485Time[23].pop(i485Time[23].index("1:44 AM")))

    i485Time[24].append(i485Time[24].pop(i485Time[24].index("12:16 AM")))
    i485Time[24].append(i485Time[24].pop(i485Time[24].index("12:46 AM")))
    i485Time[24].append(i485Time[24].pop(i485Time[24].index("1:16 AM")))
    i485Time[24].append(i485Time[24].pop(i485Time[24].index("1:46 AM")))

    i485Time[25].append(i485Time[25].pop(i485Time[25].index("12:19 AM")))
    i485Time[25].append(i485Time[25].pop(i485Time[25].index("12:49 AM")))
    i485Time[25].append(i485Time[25].pop(i485Time[25].index("1:19 AM")))
    i485Time[25].append(i485Time[25].pop(i485Time[25].index("1:49 AM")))
