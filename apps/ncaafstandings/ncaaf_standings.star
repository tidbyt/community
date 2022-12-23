"""
Applet: NCAAF Standings
Summary: Displays NCAAF standings
Description: Displays live and upcoming NCAAF standings from a data feed.
Author: LunchBox8484
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("math.star", "math")

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
SPORT = "football"
LEAGUE = "college-football"
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
    conferenceType = config.get("conferenceType", "0")
    teamsToShow = int(config.get("teamsOptions", "3"))
    showDateTime = config.bool("displayDateTime")
    timeColor = config.get("displayTimeColor", "#FFF")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    if conferenceType == "top25":
        apiURL = "https://site.api.espn.com/apis/site/v2/sports/football/college-football/rankings"
    elif conferenceType == "0":
        apiURL = API
    else:
        apiURL = API + "?group=" + conferenceType
    league = {LEAGUE: apiURL}
    standings = get_standings(league)
    if conferenceType == "top25":
        entries = standings["rankings"][0]["ranks"]
        divisionName = standings["rankings"][0]["name"]
        divisionShortName = standings["rankings"][0]["shortName"]
        displayType = "top25"
    elif conferenceType.find("&") > 0:
        conferenceTypeArray = conferenceType.split("&")
        entries = standings["children"][int(conferenceTypeArray[1])]["standings"]["entries"]
        divisionName = standings["children"][int(conferenceTypeArray[1])]["abbreviation"]
        divisionShortName = standings["children"][int(conferenceTypeArray[1])]["shortName"]
        displayType = "standings"
    else:
        entries = standings["standings"]["entries"]
        divisionName = standings["abbreviation"]
        divisionShortName = standings["shortName"]
        displayType = "standings"
    mainFont = "CG-pixel-3x5-mono"
    if entries:
        cycleOptions = int(config.get("cycleOptions", 1))
        cycleCount = 0
        entriesToDisplay = teamsToShow

        for x in range(0, len(entries), entriesToDisplay):
            cycleCount = cycleCount + 1
            renderCategory.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = get_team(x, entries, entriesToDisplay, displayType, showDateTime and 24 or 28),
                            ),
                        ],
                    ),
                ],
            )

        return render.Root(
            delay = int(15000 / cycleOptions / cycleCount),
            child = render.Column(
                children = get_top_column(showDateTime, now, timeColor, divisionName, renderCategory, showDateTime and 8 or 5),
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
        display = "ACC - Atlantic",
        value = "1&0",
    ),
    schema.Option(
        display = "ACC - Costal",
        value = "1&1",
    ),
    schema.Option(
        display = "American",
        value = "151",
    ),
    schema.Option(
        display = "Big 12",
        value = "4",
    ),
    schema.Option(
        display = "Big Ten - East",
        value = "5&0",
    ),
    schema.Option(
        display = "Big Ten - West",
        value = "5&1",
    ),
    schema.Option(
        display = "C-USA",
        value = "12",
    ),
    schema.Option(
        display = "FBS Indep.",
        value = "18",
    ),
    schema.Option(
        display = "MAC - East",
        value = "15&0",
    ),
    schema.Option(
        display = "MAC - West",
        value = "15&1",
    ),
    schema.Option(
        display = "Mountain West - Mountain",
        value = "17&0",
    ),
    schema.Option(
        display = "Mountain West - West",
        value = "17&1",
    ),
    schema.Option(
        display = "Pac-12",
        value = "9",
    ),
    schema.Option(
        display = "SEC - East",
        value = "8&0",
    ),
    schema.Option(
        display = "SEC - West",
        value = "8&1",
    ),
    schema.Option(
        display = "Sun Belt - East",
        value = "37&0",
    ),
    schema.Option(
        display = "Sun Belt - West",
        value = "37&1",
    ),
]

cycleOptions = [
    schema.Option(
        display = "Once",
        value = "1",
    ),
    schema.Option(
        display = "Twice",
        value = "2",
    ),
    schema.Option(
        display = "Three",
        value = "3",
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
                id = "teamsOptions",
                name = "Teams Per View",
                desc = "How many teams it should show at once.",
                icon = "gear",
                default = teamsOptions[1].value,
                options = teamsOptions,
            ),
            schema.Dropdown(
                id = "cycleOptions",
                name = "Cycle Times",
                desc = "How many times should it cycle through?",
                icon = "gear",
                default = cycleOptions[0].value,
                options = cycleOptions,
            ),
            schema.Toggle(
                id = "displayDateTime",
                name = "Current Time",
                desc = "A toggle to display the Current Time rather than game time/status.",
                icon = "calendar",
                default = False,
            ),
            schema.Dropdown(
                id = "displayTimeColor",
                name = "Time Color",
                desc = "Select which color you want the time to be.",
                icon = "gear",
                default = colorOptions[0].value,
                options = colorOptions,
            ),
        ],
    )

def get_standings(urls):
    allstandings = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
    return decodedata

def get_team_color(teamid):
    data = get_cachable_data("https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/teams/" + teamid)
    decodedata = json.decode(data)
    team = decodedata["team"]
    altColorCheck = team.get("alternateColor", "NO")
    if altColorCheck == "NO":
        altColor = "000000"
    else:
        altColor = team["alternateColor"]
    teamcolor = get_background_color(team["abbreviation"], "color", team["color"], altColor)
    return teamcolor

def get_team(x, s, entriesToDisplay, displayType, colHeight):
    output = []
    containerHeight = int(colHeight / entriesToDisplay)
    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            mainFont = "CG-pixel-3x5-mono"
            if displayType == "standings":
                teamID = s[i + x]["team"]["id"]
                teamName = s[i + x]["team"]["abbreviation"]
                teamColor = get_team_color(teamID)
                teamLogo = get_logoType(teamName, s[i + x]["team"]["logos"][0]["href"])
                teamRecord = s[i + x]["stats"][11]["displayValue"]
                teamGB = s[i + x]["stats"][2]["displayValue"]

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

def get_background_color(team, displayType, color, altColor):
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

def get_top_column(showDateTime, now, timeColor, divisionName, renderCategory, colHeight):
    topColumn = []
    if showDateTime:
        divisionName = divisionName.replace("Playoff Committee Rankings", "CFP")
        theTime = now.format("3:04")
        if len(str(theTime)) > 4:
            timeBox = 24
            statusBox = 40
        else:
            timeBox = 20
            statusBox = 44
        topColumn = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "start",
                children = [
                    render.Box(width = timeBox, height = colHeight, color = "#000", child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                        render.Box(width = 1, height = colHeight),
                        render.Text(color = timeColor, content = theTime, font = "tb-8"),
                    ])),
                    render.Box(width = statusBox, height = colHeight, color = "#111", child = render.Stack(children = [
                        render.Box(width = statusBox, height = colHeight, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                            render.Text(color = "#FFF", content = divisionName, font = "CG-pixel-3x5-mono"),
                        ])),
                    ])),
                ],
            ),
            render.Animation(children = renderCategory),
        ]
    else:
        divisionName = divisionName.replace("Playoff Committee Rankings", "CFP Ranking")
        topColumn = [
            render.Box(width = 64, height = colHeight, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                render.Box(width = 64, height = colHeight, child = render.Text(content = divisionName, color = "#ff0", font = "CG-pixel-3x5-mono")),
            ])),
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

    cache.set(key, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)

    return res.body()
