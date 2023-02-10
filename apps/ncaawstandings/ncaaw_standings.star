"""
Applet: NCAAW Standings
Summary: Displays NCAAW standings
Description: Displays live and upcoming NCAAW standings from a data feed.
Author: LunchBox8484
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 300
DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""
LEAGUE_DISPLAY = "NCAAW"
LEAGUE_DISPLAY_OFFSET = 7
SPORT = "basketball"
LEAGUE = "womens-college-basketball"
API = "https://site.api.espn.com/apis/v2/sports/" + SPORT + "/" + LEAGUE + "/standings"
ALT_COLOR = """
{
    "SYR" : "#000E54",
    "LSU" : "#461D7C",
    "WAKE" : "#000000",
    "UVA" : "#232D4B",
    "WVU" : "#002855",
    "CIN" : "#E00122",
    "WYO" : "#492F24",
    "SMU" : "#0033A0",
    "IOWA" : "#FFCD00",
    "PUR" : "#000000",
    "USC" : "#990000",
    "ARMY" : "#000000",
    "USM" : "#000000",
    "TOL" : "#15397F",
    "EIU" : "#004B83",
    "UNLV" : "#cf0a2c",
    "MRSH" : "#000000",
    "UNC" : "#13294B",
    "COLO" : "#000000",
    "IOWA" : "#000000",
    "RICE" : "#00205B"
}
"""
ALT_LOGO = """
{
    "WYO" : "https://i.ibb.co/Czv9k7H/wyoming-cowboys.png",
    "IOWA" : "https://storage.googleapis.com/hawkeyesports-com/2021/02/cf540990-logo.png",
    "DUQ" : "https://b.fssta.com/uploads/application/college/team-logos/Duquesne-alternate.vresize.50.50.medium.1.png",
    "UNC" : "https://b.fssta.com/uploads/application/college/team-logos/NorthCarolina-alternate.vresize.50.50.medium.1.png",
    "DUKE" : "https://b.fssta.com/uploads/application/college/team-logos/Duke-alternate.vresize.50.50.medium.1.png",
    "TEM" : "https://b.fssta.com/uploads/application/college/team-logos/Temple.vresize.50.50.medium.1.png",
    "CLEM" : "https://b.fssta.com/uploads/application/college/team-logos/Clemson-alternate.vresize.50.50.medium.1.png",
    "LSU" : "https://b.fssta.com/uploads/application/college/team-logos/LSU-alternate.vresize.50.50.medium.1.png",
    "WVU" : "https://b.fssta.com/uploads/application/college/team-logos/WestVirginia-alternate.vresize.50.50.medium.1.png",
    "PITT" : "https://b.fssta.com/uploads/application/college/team-logos/Pittsburgh-alternate.vresize.50.50.medium.1.png",
    "UVA" : "https://b.fssta.com/uploads/application/college/team-logos/Virginia.vresize.50.50.medium.1.png",
    "RUTG" : "https://b.fssta.com/uploads/application/college/team-logos/Rutgers-alternate.vresize.50.50.medium.1.png",
    "CIN" : "https://b.fssta.com/uploads/application/college/team-logos/Cincinnati-alternate.vresize.50.50.medium.1.png",
    "ARK" : "https://b.fssta.com/uploads/application/college/team-logos/Arkansas-alternate.vresize.50.50.medium.1.png",
    "HOU" : "https://b.fssta.com/uploads/application/college/team-logos/Houston-alternate.vresize.50.50.medium.1.png",
    "UNT" : "https://b.fssta.com/uploads/application/college/team-logos/NorthTexas-alternate.vresize.50.50.medium.1.png",
    "TCU" : "https://b.fssta.com/uploads/application/college/team-logos/TCU-alternate.vresize.50.50.medium.1.png",
    "OU" : "https://b.fssta.com/uploads/application/college/team-logos/Oklahoma-alternate.vresize.50.50.medium.1.png",
    "TEX" : "https://b.fssta.com/uploads/application/college/team-logos/Texas-alternate.vresize.50.50.medium.1.png",
    "KSU" : "https://b.fssta.com/uploads/application/college/team-logos/KansasState-alternate.vresize.50.50.medium.1.png",
    "ILL" : "https://b.fssta.com/uploads/application/college/team-logos/Illinois-alternate.vresize.50.50.medium.1.png",
    "NEB" : "https://b.fssta.com/uploads/application/college/team-logos/Nebraska-alternate.vresize.50.50.medium.1.png",
    "NU" : "https://b.fssta.com/uploads/application/college/team-logos/Northwestern-alternate.vresize.50.50.medium.1.png",
    "MSU" : "https://b.fssta.com/uploads/application/college/team-logos/MichiganState-alternate.vresize.50.50.medium.1.png",
    "WISC" : "https://b.fssta.com/uploads/application/college/team-logos/Wisconsin-alternate.vresize.50.50.medium.1.png",
    "IU" : "https://b.fssta.com/uploads/application/college/team-logos/Indiana-alternate.vresize.50.50.medium.0.png",
    "MINN" : "https://b.fssta.com/uploads/application/college/team-logos/Minnesota-alternate.vresize.50.50.medium.0.png",
    "MD" : "https://b.fssta.com/uploads/application/college/team-logos/Maryland-alternate.vresize.50.50.medium.0.png",
    "ND" : "https://b.fssta.com/uploads/application/college/team-logos/NotreDame-alternate.vresize.50.50.medium.0.png",
    "AAMU" : "https://b.fssta.com/uploads/application/college/team-logos/AlabamaA&M-alternate.vresize.50.50.medium.0.png",
    "USC" : "https://b.fssta.com/uploads/application/college/team-logos/USC-alternate.vresize.50.50.medium.0.png",
    "RICE" : "https://b.fssta.com/uploads/application/college/team-logos/Rice-alternate.vresize.50.50.medium.0.png",
    "NEV" : "https://b.fssta.com/uploads/application/college/team-logos/Nevada-alternate.vresize.50.50.medium.0.png",
    "USU" : "https://b.fssta.com/uploads/application/college/team-logos/UtahState-alternate.vresize.50.50.medium.0.png",
    "ARMY" : "https://b.fssta.com/uploads/application/college/team-logos/Army.vresize.50.50.medium.0.png",
    "TENN" : "https://b.fssta.com/uploads/application/college/team-logos/Tennessee-alternate.vresize.50.50.medium.0.png",
    "CMU" : "https://b.fssta.com/uploads/application/college/team-logos/CentralMichigan-alternate.vresize.50.50.medium.0.png",
    "TOL" : "https://b.fssta.com/uploads/application/college/team-logos/Toledo-alternate.vresize.50.50.medium.0.png",
    "EMU" : "https://b.fssta.com/uploads/application/college/team-logos/EasternMichigan-alternate.vresize.50.50.medium.0.png",
    "EKU" : "https://b.fssta.com/uploads/application/college/team-logos/EasternKentucky-alternate.vresize.50.50.medium.0.png",
    "UCLA" : "https://b.fssta.com/uploads/application/college/team-logos/UCLA-alternate.vresize.50.50.medium.0.png",
    "UK" : "https://b.fssta.com/uploads/application/college/team-logos/Kentucky-alternate.vresize.50.50.medium.0.png",
    "WASH" : "https://b.fssta.com/uploads/application/college/team-logos/Washington-alternate.vresize.50.50.medium.0.png",
    "UNLV" : "https://b.fssta.com/uploads/application/college/team-logos/UNLV-alternate.vresize.50.50.medium.0.png",
    "AFA" : "https://b.fssta.com/uploads/application/college/team-logos/AirForce-alternate.vresize.50.50.medium.1.png",
    "NAU" : "https://b.fssta.com/uploads/application/college/team-logos/NorthernArizona-alternate.vresize.50.50.medium.0.png",
    "ORE" : "https://b.fssta.com/uploads/application/college/team-logos/Oregon-alternate.vresize.50.50.medium.0.png",
    "UCD" : "https://b.fssta.com/uploads/application/college/team-logos/UCDavis-alternate.vresize.50.50.medium.0.png",
    "CAL" : "https://b.fssta.com/uploads/application/college/team-logos/California-alternate.vresize.50.50.medium.0.png",
    "COLG" : "https://b.fssta.com/uploads/application/college/team-logos/Colgate-alternate.vresize.50.50.medium.0.png",
    "STAN" : "https://b.fssta.com/uploads/application/college/team-logos/Stanford.vresize.50.50.medium.0.png",
    "WSU" : "https://b.fssta.com/uploads/application/college/team-logos/WashingtonState-alternate.vresize.50.50.medium.0.png",
    "SDSU" : "https://b.fssta.com/uploads/application/college/team-logos/SanDiegoState.vresize.50.50.medium.0.png",
    "SHSU" : "https://b.fssta.com/uploads/application/college/team-logos/SamHoustonState-alternate.vresize.50.50.medium.0.png",
    "AUB" : "https://b.fssta.com/uploads/application/college/team-logos/Auburn-alternate.vresize.50.50.medium.0.png",
    "NORF" : "https://b.fssta.com/uploads/application/college/team-logos/NorfolkState.vresize.50.50.medium.0.png",
    "UNC" : "https://b.fssta.com/uploads/application/college/team-logos/NorthCarolina.vresize.50.50.medium.0.png",
    "BAY" : "https://b.fssta.com/uploads/application/college/team-logos/Baylor-alternate.vresize.50.50.medium.0.png",
    "ALA" : "https://b.fssta.com/uploads/application/college/team-logos/Alabama-alternate.vresize.50.50.medium.0.png"
}
"""

def main(config):
    renderCategory = []
    rotationSpeed = config.get("rotationSpeed", "5")
    conferenceType = config.get("conferenceType", "top25")
    teamsToShow = int(config.get("teamsOptions", "3"))
    displayTop = config.get("displayTop", "league")
    timeColor = config.get("displayTimeColor", "#FFA500")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    if conferenceType == "top25":
        apiURL = "https://site.api.espn.com/apis/site/v2/sports/basketball/womens-college-basketball/rankings"
    elif conferenceType == "0":
        apiURL = API
    else:
        apiURL = API + "?group=" + conferenceType
    league = {LEAGUE: apiURL}
    standings = get_standings(league)
    if conferenceType == "top25":
        entries = standings["rankings"][0]["ranks"]
        divisionName = standings["rankings"][0]["name"]
        displayType = "top25"
    elif conferenceType.find("&") > 0:
        conferenceTypeArray = conferenceType.split("&")
        entries = standings["children"][int(conferenceTypeArray[1])]["standings"]["entries"]
        divisionName = displayTop == "gameinfo" and standings["children"][int(conferenceTypeArray[1])]["name"] or standings["children"][int(conferenceTypeArray[1])]["abbreviation"]
        displayType = "standings"
    else:
        entries = standings["standings"]["entries"]
        divisionName = displayTop == "gameinfo" and standings["shortName"] or standings["abbreviation"]
        displayType = "standings"
    if entries:
        entriesToDisplay = teamsToShow

        if conferenceType != "top25":
            sortOrder = {}

            for j, _ in enumerate(entries):
                stats = entries[j]["stats"]
                for l, m in enumerate(stats):
                    if m["name"] == "gamesBehind":
                        sortOrder[entries[j]["team"]["id"]] = stats[l]["value"]
            sortOrder = {k: v for k, v in sorted(sortOrder.items(), key = lambda item: item[1])}
            keysList = list(sortOrder.keys())
            entries = sorted(entries, key = lambda e: keysList.index(e["team"]["id"]))

        for x in range(0, len(entries), entriesToDisplay):
            renderCategory.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = get_team(x, entries, entriesToDisplay, displayType),
                            ),
                        ],
                    ),
                ],
            )

        return render.Root(
            delay = int(rotationSpeed) * 1000,
            show_full_animation = True,
            child = render.Column(
                children = get_top_column(displayTop, now, timeColor, divisionName, renderCategory),
            ),
        )
    else:
        return []

conferenceOptions = [
    schema.Option(
        display = "Top 25",
        value = "top25",
    ),
    schema.Option(
        display = "Division I",
        value = "50",
    ),
    schema.Option(
        display = "A 10",
        value = "3",
    ),
    schema.Option(
        display = "ACC",
        value = "2",
    ),
    schema.Option(
        display = "ASUN",
        value = "46",
    ),
    schema.Option(
        display = "Am. East",
        value = "1",
    ),
    schema.Option(
        display = "American",
        value = "62",
    ),
    schema.Option(
        display = "Big 12",
        value = "8",
    ),
    schema.Option(
        display = "Big East",
        value = "4",
    ),
    schema.Option(
        display = "Big Sky",
        value = "5",
    ),
    schema.Option(
        display = "Big South",
        value = "6",
    ),
    schema.Option(
        display = "Big Ten",
        value = "7",
    ),
    schema.Option(
        display = "Big West",
        value = "9",
    ),
    schema.Option(
        display = "C-USA",
        value = "11",
    ),
    schema.Option(
        display = "CAA",
        value = "10",
    ),
    schema.Option(
        display = "Horizon",
        value = "45",
    ),
    schema.Option(
        display = "Indep.",
        value = "43",
    ),
    schema.Option(
        display = "Ivy",
        value = "12",
    ),
    schema.Option(
        display = "MAAC",
        value = "13",
    ),
    schema.Option(
        display = "MAC",
        value = "14",
    ),
    schema.Option(
        display = "MEAC",
        value = "16",
    ),
    schema.Option(
        display = "MVC",
        value = "18",
    ),
    schema.Option(
        display = "Mountain West",
        value = "44",
    ),
    schema.Option(
        display = "NEC",
        value = "19",
    ),
    schema.Option(
        display = "OVC",
        value = "20",
    ),
    schema.Option(
        display = "Pac-12",
        value = "21",
    ),
    schema.Option(
        display = "Patriot",
        value = "22",
    ),
    schema.Option(
        display = "SEC",
        value = "23",
    ),
    schema.Option(
        display = "SWAC",
        value = "26",
    ),
    schema.Option(
        display = "Southern",
        value = "24",
    ),
    schema.Option(
        display = "Southland",
        value = "25",
    ),
    schema.Option(
        display = "Summit",
        value = "47",
    ),
    schema.Option(
        display = "Sun Belt",
        value = "27",
    ),
    schema.Option(
        display = "WAC",
        value = "30",
    ),
    schema.Option(
        display = "WCC",
        value = "29",
    ),
]

rotationOptions = [
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
    schema.Option(
        display = "6 seconds",
        value = "6",
    ),
    schema.Option(
        display = "7 seconds",
        value = "7",
    ),
    schema.Option(
        display = "8 seconds",
        value = "8",
    ),
    schema.Option(
        display = "9 seconds",
        value = "9",
    ),
    schema.Option(
        display = "10 seconds",
        value = "10",
    ),
    schema.Option(
        display = "11 seconds",
        value = "11",
    ),
    schema.Option(
        display = "12 seconds",
        value = "12",
    ),
    schema.Option(
        display = "13 seconds",
        value = "13",
    ),
    schema.Option(
        display = "14 seconds",
        value = "14",
    ),
    schema.Option(
        display = "15 seconds",
        value = "15",
    ),
]

teamsOptions = [
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "4",
        value = "4",
    ),
]

displayTopOptions = [
    schema.Option(
        display = "League Name",
        value = "league",
    ),
    schema.Option(
        display = "Current Time",
        value = "time",
    ),
    schema.Option(
        display = "League Name Only",
        value = "gameinfo",
    ),
]

colorOptions = [
    schema.Option(
        display = "White",
        value = "#FFF",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FF0",
    ),
    schema.Option(
        display = "Red",
        value = "#F00",
    ),
    schema.Option(
        display = "Blue",
        value = "#00F",
    ),
    schema.Option(
        display = "Green",
        value = "#0F0",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "conferenceType",
                name = "Conference",
                desc = "Which conference to display.",
                icon = "gear",
                default = conferenceOptions[0].value,
                options = conferenceOptions,
            ),
            schema.Dropdown(
                id = "rotationSpeed",
                name = "Rotation Speed",
                desc = "Amount of seconds each score is displayed.",
                icon = "gear",
                default = rotationOptions[2].value,
                options = rotationOptions,
            ),
            schema.Dropdown(
                id = "teamsOptions",
                name = "Teams Per View",
                desc = "How many teams it should show at once.",
                icon = "gear",
                default = teamsOptions[1].value,
                options = teamsOptions,
            ),
            schema.Dropdown(
                id = "displayTop",
                name = "Top Display",
                desc = "A toggle of what to display on the top shelf.",
                icon = "gear",
                default = displayTopOptions[0].value,
                options = displayTopOptions,
            ),
            schema.Dropdown(
                id = "displayTimeColor",
                name = "Top Display Color",
                desc = "Select which color you want the top display to be.",
                icon = "gear",
                default = colorOptions[5].value,
                options = colorOptions,
            ),
        ],
    )

def get_standings(urls):
    decodedata = []

    for _, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)

    return decodedata

def get_team_color(teamid):
    data = get_cachable_data("https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/teams/" + teamid)
    decodedata = json.decode(data)
    team = decodedata["team"]
    colorCheck = team.get("color", "NO")
    if colorCheck == "NO":
        color = "000000"
    else:
        color = team["color"]
    teamcolor = get_background_color(team["abbreviation"], color)
    return teamcolor

def get_team(x, s, entriesToDisplay, displayType):
    teamRecord = ""
    teamGB = ""
    output = []
    containerHeight = int(24 / entriesToDisplay)
    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            mainFont = "CG-pixel-3x5-mono"
            if displayType == "standings":
                teamID = s[i + x]["team"]["id"]
                stats = s[i + x]["stats"]
                teamName = s[i + x]["team"]["abbreviation"]
                teamColor = get_team_color(teamID)
                teamLogo = get_logoType(teamName, s[i + x]["team"]["logos"][0]["href"])
                for _, k in enumerate(stats):
                    if k["name"] == "vs. Conf.":
                        teamRecord = k["displayValue"]
                    if k["name"] == "gamesBehind":
                        teamGB = k["displayValue"]

                team = render.Column(
                    children = [
                        render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                            render.Box(width = 8, height = containerHeight, child = render.Image(teamLogo, width = 10, height = 10)),
                            render.Box(width = 18, height = containerHeight, child = render.Text(content = teamName[:4], color = "#fff", font = mainFont)),
                            render.Box(width = 24, height = containerHeight, child = render.Text(content = teamRecord, color = "#fff", font = mainFont)),
                            render.Box(width = 14, height = containerHeight, child = render.Text(content = teamGB, color = "#fff", font = mainFont)),
                        ])),
                    ],
                )
                output.extend([team])
            else:
                teamID = s[i + x]["team"]["id"]
                teamName = s[i + x]["team"]["abbreviation"]
                teamColor = get_team_color(teamID)
                teamLogo = get_logoType(teamName, s[i + x]["team"]["logo"])
                teamRecord = s[i + x]["recordSummary"]

                team = render.Column(
                    children = [
                        render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                            render.Box(width = 14, height = containerHeight, child = render.Text(content = str(i + x + 1), color = "#fff", font = "CG-pixel-4x5-mono")),
                            render.Box(width = 8, height = containerHeight, child = render.Image(teamLogo, width = 10, height = 10)),
                            render.Box(width = 20, height = containerHeight, child = render.Text(content = teamName[:4], color = "#fff", font = mainFont)),
                            render.Box(width = 22, height = containerHeight, child = render.Text(content = teamRecord, color = "#fff", font = mainFont)),
                        ])),
                    ],
                )
                output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])
    return output

def get_background_color(team, color):
    altcolors = json.decode(ALT_COLOR)
    usealt = altcolors.get(team, "NO")
    if usealt != "NO":
        color = altcolors[team]
    else:
        color = "#" + color
    if color == "#ffffff" or color == "#000000":
        color = "#222"
    return color

def get_logoType(team, logo):
    usealtlogo = json.decode(ALT_LOGO)
    usealt = usealtlogo.get(team, "NO")
    if usealt != "NO":
        logo = get_cachable_data(usealt, 36000)
    else:
        logo = logo.replace("500/scoreboard", "500-dark/scoreboard")
        logo = logo.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 36000)
        logo = get_cachable_data(logo + "&h=50&w=50")
    return logo

def get_top_column(displayTop, now, timeColor, divisionName, renderCategory):
    topColumn = []
    divisionName = divisionName.replace("AP ", "")
    if displayTop == "gameinfo":
        topColumn = [
            render.Box(width = 64, height = 8, child = render.Stack(children = [
                render.Box(width = 64, height = 8, color = "#000"),
                render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                    render.Text(color = timeColor, content = divisionName, font = "CG-pixel-3x5-mono"),
                ])),
            ])),
            render.Animation(children = renderCategory),
        ]
    else:
        timeBox = 20
        statusBox = 44
        if displayTop == "league":
            theTime = LEAGUE_DISPLAY
            timeBox += LEAGUE_DISPLAY_OFFSET
            statusBox -= LEAGUE_DISPLAY_OFFSET
        else:
            theTime = now.format("3:04")
            if len(str(theTime)) > 4:
                timeBox += 4
                statusBox -= 4
        topColumn = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "start",
                children = [
                    render.Box(width = timeBox, height = 8, color = "#000", child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                        render.Box(width = 1, height = 8),
                        render.Text(color = timeColor, content = theTime, font = "tb-8"),
                    ])),
                    render.Box(width = statusBox, height = 8, color = "#000", child = render.Stack(children = [
                        render.Box(width = statusBox, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                            render.Text(color = "#FFF", content = divisionName, font = "CG-pixel-3x5-mono"),
                        ])),
                    ])),
                ],
            ),
            render.Animation(children = renderCategory),
        ]

    return topColumn

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
