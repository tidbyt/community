"""
Applet: F1 Results
Summary: Qualifying and race results
Description: Shows F1 qualifying or race results for the latest race. Otherwise the app shows date & time of next race. This is not a live timing app
Author: M0ntyP

v1.0a
Updated caching function

v1.1
The API is a round behind with the cancellation of Round 6. Monaco should be Round 7 but its appearing as Round 6. Added 1 to the round number for the race preview

v1.2
Updating for changes to team colours for 2024 sesason

v1.3
Updated for new API, thanks to @jvivona :)

v1.4
Using different API lookup to check race calendar. This is to see how long since the last race ended, if less than 48hrs display the results, if more than 48hrs go to the next race
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "Australia/Adelaide"

#F1_URL = "http://ergast.com/api/f1/"
#F1_URL = "https://tidbyt.apis.ajcomputers.com/f1/api/"

# Alternate URL thanks to @jvivona for the hosting :)
F1_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/"
RACELIST_URL = "https://api.jolpi.ca/ergast/f1/2025/races.json"

def main(config):
    RotationSpeed = config.get("speed", "3")
    ShowGap = config.bool("ShowGapToggle", False)
    ShowGrid = config.bool("ShowGridToggle", False)

    renderCategory = []
    mainFont = "CG-pixel-4x5-mono"
    Session = ""
    F1_JSON = ""
    CurrentRound = ""
    CurrentRace = ""
    MyRaceDate = ""
    MyRaceTime = ""

    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    Year = now.format("2006")

    GetLast = get_cachable_data(RACELIST_URL, 86400)
    F1_LAST_JSON = json.decode(GetLast)

    # iterate through the race calendar
    for x in range(0, len(F1_LAST_JSON["MRData"]["RaceTable"]["Races"]), 1):
        LocalRaceDate = F1_LAST_JSON["MRData"]["RaceTable"]["Races"][x]["date"]
        LocalRaceTime = F1_LAST_JSON["MRData"]["RaceTable"]["Races"][x]["time"]
        RaceDate_Time = LocalRaceDate + " " + LocalRaceTime
        FormatRTime = time.parse_time(RaceDate_Time, format = "2006-01-02 15:04:00Z").in_location(timezone)
        RTimeDiff = FormatRTime - now
        #print(RTimeDiff.hours)

        # if we're more than 2hrs but less than 48hrs after the last race start get the race results, and break
        # or if time next race is more than 0hrs, lets look ahead, and break when we find something
        if RTimeDiff.hours < -2 and RTimeDiff.hours > -48:
            RaceRound = F1_LAST_JSON["MRData"]["RaceTable"]["Races"][x]["round"]
            F1_RACE_URL = F1_URL + Year + "/" + RaceRound + "/" + "results.json"
            GetResults = get_cachable_data(F1_RACE_URL, 60 * 60)
            F1_JSON = json.decode(GetResults)
            Session = "R"
            break

        elif RTimeDiff.hours > 0:
            F1_NEXT_URL = F1_URL + "/next.json"
            GetNext = get_cachable_data(F1_NEXT_URL, 86400)
            F1_NEXT_JSON = json.decode(GetNext)
            CurrentRound = F1_NEXT_JSON["MRData"]["RaceTable"]["Races"][0]["round"]
            CurrentRace = F1_NEXT_JSON["MRData"]["RaceTable"]["Races"][0]["raceName"]

            # What time is qualifying at your local time
            QualyDate = F1_NEXT_JSON["MRData"]["RaceTable"]["Races"][0]["Qualifying"]["date"]
            QualyTime = F1_NEXT_JSON["MRData"]["RaceTable"]["Races"][0]["Qualifying"]["time"]
            QualyDate_Time = QualyDate + " " + QualyTime
            FormatQTime = time.parse_time(QualyDate_Time, format = "2006-01-02 15:04:00Z").in_location(timezone)
            QTimeDiff = FormatQTime - now

            # What time is the race at your local time
            LocalRaceDate = F1_NEXT_JSON["MRData"]["RaceTable"]["Races"][0]["date"]
            LocalRaceTime = F1_NEXT_JSON["MRData"]["RaceTable"]["Races"][0]["time"]
            RaceDate_Time = LocalRaceDate + " " + LocalRaceTime
            FormatRTime = time.parse_time(RaceDate_Time, format = "2006-01-02 15:04:00Z").in_location(timezone)
            MyRaceDate = FormatRTime.format("Jan 2")
            MyRaceTime = FormatRTime.format("15:04")
            RTimeDiff = FormatRTime - now

            # Has qualifying completed? Allow for 2hrs post session
            if QTimeDiff.hours < -1:
                F1_QUALY_URL = F1_URL + Year + "/" + CurrentRound + "/" + "qualifying.json"
                GetQualy = get_cachable_data(F1_QUALY_URL, 60 * 60)
                F1_QUALY_JSON = json.decode(GetQualy)
                F1_JSON = F1_QUALY_JSON
                Session = "Q"

            # Has race completed? Allow for 3hrs post race. This to take precedence over qualifying
            # Might not actually get here depending how quickly "CurrentRound" advances to the next but if they do advance quickly then race results should still get picked up earlier (L38)
            if RTimeDiff.hours < -2:
                F1_RACE_URL = F1_URL + Year + "/" + CurrentRound + "/" + "results.json"
                GetRace = get_cachable_data(F1_RACE_URL, 60 * 60)
                F1_RACE_JSON = json.decode(GetRace)
                F1_JSON = F1_RACE_JSON
                Session = "R"
            break

    # if no Session defined show the next race details
    if Session == "":
        # API feed is one round behind, so bumping by 1 to match the official F1 round number
        CurrentRound = str(int(CurrentRound) + 1)

        # nothing has happened yet
        return render.Root(
            child = render.Column(
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 7, color = "#e10600", child = render.Text(content = "FORMULA 1", color = "#FFF", font = mainFont)),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 6, color = "#000", child = render.Text(content = "Next Race", color = "#FFF", font = mainFont)),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 7, child = render.Text(content = "Round " + CurrentRound, color = "#FFF", font = mainFont)),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Marquee(width = 64, height = 8, child = render.Text(content = CurrentRace, color = "#FFF", font = mainFont)),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 8, color = "#000", child = render.Text(content = MyRaceDate + " " + MyRaceTime, color = "#FFF", font = "CG-pixel-3x5-mono")),
                        ],
                    ),
                ],
            ),
        )

    if Session == "R":
        if ShowGap == True:
            if ShowGrid == True:
                for z in range(0, 20, 4):
                    renderCategory.extend([
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = getDriverGaps(z, F1_JSON, Session),
                                ),
                            ],
                        ),
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = getDriverGrid(z, F1_JSON, Session),
                                ),
                            ],
                        ),
                    ])
            elif ShowGrid == False:
                for z in range(0, 20, 4):
                    renderCategory.extend([
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = getDriverGaps(z, F1_JSON, Session),
                                ),
                            ],
                        ),
                    ])

        elif ShowGap == False:
            if ShowGrid == True:
                for z in range(0, 20, 4):
                    renderCategory.extend([
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = getDriverGrid(z, F1_JSON, Session),
                                ),
                            ],
                        ),
                    ])
            elif ShowGrid == False:
                for z in range(0, 20, 4):
                    renderCategory.extend([
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = getDriver(z, F1_JSON, Session),
                                ),
                            ],
                        ),
                    ])

    if Session == "Q":
        for z in range(0, 20, 4):
            renderCategory.extend([
                render.Column(
                    expanded = True,
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Column(
                            children = getDriver(z, F1_JSON, Session),
                        ),
                    ],
                ),
            ])

    return render.Root(
        show_full_animation = True,
        delay = int(RotationSpeed) * 1000,
        child = render.Animation(children = renderCategory),
    )

RotationOptions = [
    schema.Option(
        display = "2 seconds",
        value = "2",
    ),
    schema.Option(
        display = "3 seconds",
        value = "3",
    ),
    schema.Option(
        display = "4 seconds",
        value = "4",
    ),
    schema.Option(
        display = "5 seconds",
        value = "5",
    ),
]

def getDriver(z, F1_JSON, Session):
    output = []
    mainFont = "CG-pixel-4x5-mono"
    PosFont = "CG-pixel-3x5-mono"
    DriverFont = "#fff"
    SessionCode = ""

    if Session == "Q":
        SessionCode = "QualifyingResults"
    elif Session == "R":
        SessionCode = "Results"

    CurrentRace = F1_JSON["MRData"]["RaceTable"]["Races"][0]["raceName"]
    CurrentRace = CurrentRace.replace(" Grand Prix", "")
    CurrentRace = CurrentRace[:10]

    TitleRow = [render.Box(width = 64, height = 5, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = 5, child = render.Text(content = CurrentRace + " " + Session, color = "#fff", font = mainFont)),
    ]))]

    output.extend(TitleRow)

    for i in range(0, 4):
        if i + z < 20:
            DriverFont = "#fff"
            Pos = F1_JSON["MRData"]["RaceTable"]["Races"][0][SessionCode][i + z]["position"]

            # it doesn't display Perez's surname corrected so hardcoded him in
            if F1_JSON["MRData"]["RaceTable"]["Races"][0][SessionCode][i + z]["Driver"]["code"] == "PER":
                Driver = "Perez"
            else:
                Driver = F1_JSON["MRData"]["RaceTable"]["Races"][0][SessionCode][i + z]["Driver"]["familyName"]

            ConstructorID = F1_JSON["MRData"]["RaceTable"]["Races"][0][SessionCode][i + z]["Constructor"]["constructorId"]

            # If its a Haas, use black color
            if ConstructorID == "haas" or ConstructorID == "sauber":
                DriverFont = "#000"

            TeamColor = Team_Color(ConstructorID)

            driver = render.Row(
                children = [
                    render.Box(
                        height = 7,
                        width = 12,
                        color = TeamColor,
                        child = render.Text(
                            content = Pos + ".",
                            color = DriverFont,
                            font = PosFont,
                            offset = 0,
                        ),
                    ),
                    render.Box(
                        height = 7,
                        width = 64,
                        color = TeamColor,
                        child = render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Marquee(
                                width = 64,
                                child = render.Text(
                                    content = Driver,
                                    color = DriverFont,
                                    font = mainFont,
                                    offset = 0,
                                ),
                            ),
                        ),
                    ),
                ],
            )
            output.extend([driver])

    return output

def getDriverGaps(z, F1_JSON, Session):
    output = []
    mainFont = "CG-pixel-4x5-mono"
    PosFont = "CG-pixel-3x5-mono"
    DriverFont = "#fff"

    CurrentRace = F1_JSON["MRData"]["RaceTable"]["Races"][0]["raceName"]
    CurrentRace = CurrentRace.replace(" Grand Prix", "")
    CurrentRace = CurrentRace[:10]

    TitleRow = [render.Box(width = 64, height = 5, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = 5, child = render.Text(content = CurrentRace + " " + Session, color = "#fff", font = mainFont)),
    ]))]

    output.extend(TitleRow)

    for i in range(0, 4):
        if i + z < 20:
            DriverFont = "#fff"
            Pos = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["position"]
            DriverCode = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["Driver"]["code"]

            # if they retired show "DNF" or "DQ" if Disqualified
            if F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["status"] != "Finished":
                if F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["positionText"] == "R":
                    Time = "DNF"
                elif F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["positionText"] == "D":
                    Time = "DQ"
                else:
                    Time = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["status"]
                    Time = Time[:4]
                    Time = Time.replace(" ", "")

                # show the gap, trimmed to fit only 1 decimal place
            else:
                Time = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["Time"]["time"]
                Time = Time[:5]

            # dont show time for the winner
            if i + z == 0:
                Time = ""
            ConstructorID = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["Constructor"]["constructorId"]

            # If its a Haas, use black color
            if ConstructorID == "haas":
                DriverFont = "#000"

            TeamColor = Team_Color(ConstructorID)

            driver = render.Row(
                children = [
                    render.Box(
                        height = 7,
                        width = 12,
                        color = TeamColor,
                        child = render.Text(
                            content = Pos + ".",
                            color = DriverFont,
                            font = PosFont,
                            offset = 0,
                        ),
                    ),
                    render.Box(
                        height = 7,
                        width = 16,
                        color = TeamColor,
                        child = render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Text(
                                content = DriverCode,
                                color = DriverFont,
                                font = mainFont,
                                offset = 0,
                            ),
                        ),
                    ),
                    render.Box(
                        height = 7,
                        width = 40,
                        color = TeamColor,
                        child = render.Padding(
                            pad = (15, 0, 0, 0),
                            child = render.Marquee(
                                width = 40,
                                child = render.Text(
                                    content = Time,
                                    color = DriverFont,
                                    font = mainFont,
                                    offset = 0,
                                ),
                            ),
                        ),
                    ),
                ],
            )
            output.extend([driver])

    return output

def getDriverGrid(z, F1_JSON, Session):
    output = []
    mainFont = "CG-pixel-4x5-mono"
    PosFont = "CG-pixel-3x5-mono"
    DriverFont = "#fff"
    PosDiffStr = ""

    CurrentRace = F1_JSON["MRData"]["RaceTable"]["Races"][0]["raceName"]
    CurrentRace = CurrentRace.replace(" Grand Prix", "")
    CurrentRace = CurrentRace[:10]

    TitleRow = [render.Box(width = 64, height = 5, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = 5, child = render.Text(content = CurrentRace + " " + Session, color = "#fff", font = mainFont)),
    ]))]

    output.extend(TitleRow)

    for i in range(0, 4):
        if i + z < 20:
            DriverFont = "#fff"
            Pos = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["position"]
            DriverCode = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["Driver"]["code"]

            StartPos = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["grid"]
            StartPos = int(StartPos)
            FinishPos = int(Pos)
            PosDiff = StartPos - FinishPos
            if PosDiff > 0:
                PosDiffStr = "+" + str(PosDiff)
            if PosDiff < 0:
                PosDiffStr = str(PosDiff)
            if PosDiff == 0:
                PosDiffStr = "-"

            ConstructorID = F1_JSON["MRData"]["RaceTable"]["Races"][0]["Results"][i + z]["Constructor"]["constructorId"]

            # If its a Haas, use black color
            if ConstructorID == "haas":
                DriverFont = "#000"

            TeamColor = Team_Color(ConstructorID)

            driver = render.Row(
                children = [
                    render.Box(
                        height = 7,
                        width = 12,
                        color = TeamColor,
                        child = render.Text(
                            content = Pos + ".",
                            color = DriverFont,
                            font = PosFont,
                            offset = 0,
                        ),
                    ),
                    render.Box(
                        height = 7,
                        width = 16,
                        color = TeamColor,
                        child = render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Text(
                                content = DriverCode,
                                color = DriverFont,
                                font = mainFont,
                                offset = 0,
                            ),
                        ),
                    ),
                    render.Box(
                        height = 7,
                        width = 40,
                        color = TeamColor,
                        child = render.Padding(
                            pad = (25, 0, 0, 0),
                            child = render.Marquee(
                                width = 40,
                                child = render.Text(
                                    content = PosDiffStr,
                                    color = DriverFont,
                                    font = mainFont,
                                    offset = 0,
                                ),
                            ),
                        ),
                    ),
                ],
            )
            output.extend([driver])

    return output

def Team_Color(ConstructorID):
    if ConstructorID == "red_bull":
        return ("#161960")
    if ConstructorID == "ferrari":
        return ("#fe0000")
    if ConstructorID == "mercedes":
        return ("#00a19c")
    if ConstructorID == "alpine":
        return ("#0f1c2c")
    if ConstructorID == "mclaren":
        return ("#fd8000")
    if ConstructorID == "sauber":
        return ("#00df00")
    if ConstructorID == "aston_martin":
        return ("#015850")
    if ConstructorID == "haas":
        return ("#f7f7f7")
    if ConstructorID == "rb":
        return ("#022948")
    if ConstructorID == "williams":
        return ("#041e41")
    else:
        return ("#fff")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Rotation Speed",
                desc = "How many seconds each page is displayed",
                icon = "gear",
                default = RotationOptions[1].value,
                options = RotationOptions,
            ),
            schema.Toggle(
                id = "ShowGapToggle",
                name = "Time gap",
                desc = "Show gap to next car (race only)",
                icon = "toggleOn",
                default = False,
            ),
            schema.Toggle(
                id = "ShowGridToggle",
                name = "Show position change",
                desc = "Show change in position, from grid to finish (race only)",
                icon = "toggleOn",
                default = False,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
