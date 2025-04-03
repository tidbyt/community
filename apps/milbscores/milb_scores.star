"""
Applet: MiLB Scores
Summary: Minor League scores
Description: Shows baseball scores for the Minor Leagues.
Author: M0ntyP

v1.0 - submitted

v1.1
Changed date logic from Eastern Time to Pacific Time as games were still being played when its the following day on the east coast
Added Double A leagues & team colors
Added team logos for both Triple-A and Double-A teams

v1.2
Changed the names on the league selection dropdown

v1.3
Changed date check to be Hawaii timezone - this will mean that the scores will not change to the following day until 6am ET, leaving the day's scores displayed on the Tidbyt for longer

v1.3.1
Updated status check for completed games

v1.4
Updated for 2025

Team changes and updated colors
- Mississippi Braves (MIS) are now Columbus Clingstones (COL) 
- Bowie Baysox (BOW) are now Chesapeake Baysox (CHE) 
- Tennessee Smokies (TNS) are now Knoxville Smokies (KNX) 

New Logos
- Oklahoma City Comets 
- Salt Lake Bees
- Corpus Christi Hooks

Added new logic to color lookup as there are 2 COL teams now - Clippers and Clingstones
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_PREFIX = "https://bdfed.stitch.mlbinfra.com/bdfed/transform-milb-scoreboard?stitch_env=prod&sortTemplate=4&sportId="
API_SUFFIX = "&gameType=R&&gameType=F&&gameType=D&&gameType=L&&gameType=W&&gameType=A&&gameType=C&season=2023&language=en&leagueId="
API_SUFFIX2 = "&contextTeamId=milb&teamId="

#LOGO_PREFIX = "https://www.mlbstatic.com/team-logos/"
#LOGO_SUFFIX = ".svg"

LOGO_PREFIX = "https://milbpng.blob.core.windows.net/milb/"
LOGO_SUFFIX = ".png"

PT_TIMEZONE = "America/Los_Angeles"
HAWAII_TIMEZONE = "Pacific/Honolulu"
DEFAULT_TIMEZONE = "Australia/Adelaide"

COLORS = """
{
    "BUF": "#060da4",
    "CLT": "#00a5ce",
    "COL1": "#204885",
    "DUR": "#0156a6",
    "GWN": "#74aa50",
    "IND": "#e31837",
    "IOW": "#005395",
    "JAX": "#ef3e42",
    "LHV": "#c41230",
    "LOU": "#ea1c2d",
    "MEM": "#d31245",
    "NAS": "#c8102e",
    "NOR": "#00984d",
    "OMA": "#004b8d",
    "ROC": "#000000",
    "SWB": "#062d5c",
    "STP": "#00539f",
    "SYR": "#f47d30",
    "TOL": "#d50032",
    "WOR": "#bd3039",
    "ABQ": "#494949",
    "ELP": "#d31245",
    "LV": "#ff4d00",
    "OKC": "#005596",
    "RNO": "#002a5c",
    "RR": "#9d2235",
    "SAC": "#000000",
    "SL": "#000",
    "SUG": "#002b5c",
    "TAC": "#002144",
    "AKR": "#1f7cc3",
    "ALT": "#a93338",
    "AMA": "#024b85",
    "ARK": "#d31245",
    "BLX": "#d95b73",
    "BNG": "#a3194a",
    "BIR": "#b3002a",
    "CHE": "#000",
    "CHA": "#ee3d42",
    "CC": "#5091cd",
    "ERI": "#d31145",
    "FRI": "#005295",
    "HBG": "#d31245",
    "HFD": "#004b8d",
    "MID": "#f3901d",
    "COL2": "#000",
    "MTG": "#d06f1a",
    "NH": "#e31837",
    "NWA": "#a40234",
    "PNS": "#002660",
    "POR": "#0d2b56",
    "REA": "#d31245",
    "RIC": "#d31245",
    "RCT": "#007dc3",
    "SA": "#002d62",
    "SOM": "#0d2240",
    "SPR": "#d31245",
    "KNX": "#005696",
    "TUL": "#005596",
    "WCH": "#f5002f"
}
"""

def main(config):
    Display = []
    Title = ""
    SportID = ""
    localtimezone = config.get("$tz", DEFAULT_TIMEZONE)
    SelectedLeague = config.get("League", "1")
    RotationSpeed = config.get("speed", "3")

    if SelectedLeague == "1":
        SelectedLeague = ""
        Title = "AAA"
        SportID = "11"
    if SelectedLeague == "2":
        SelectedLeague = ""
        Title = "AA"
        SportID = "12"
    elif SelectedLeague == "112":
        Title = "PCL"
        SportID = "11"
    elif SelectedLeague == "117":
        Title = "IL"
        SportID = "11"
    elif SelectedLeague == "113":
        Title = "EAST"
        SportID = "12"
    elif SelectedLeague == "111":
        Title = "SOUTH"
        SportID = "12"
    elif SelectedLeague == "109":
        Title = "TEXAS"
        SportID = "12"

    # Get the date in Hawaii
    now = time.now().in_location(HAWAII_TIMEZONE)
    strnow = str(now)
    date = strnow[:10]

    APIDate = "startDate=" + date + "&endDate=" + date
    API = API_PREFIX + SportID + "&" + APIDate + API_SUFFIX + SelectedLeague + API_SUFFIX2
    #print(API)

    teamFont = "Dina_r400-6"
    scoreFont = "Dina_r400-6"
    textFont = teamFont
    GameSituation = ""
    AwayScore = ""
    HomeScore = ""

    # hold 1 min cache for live scores
    CacheData = get_cachable_data(API, 60)
    API_JSON = json.decode(CacheData)

    TotalGames = len(API_JSON["dates"][0]["games"])
    GameList = API_JSON["dates"][0]["games"]

    # if we have a game on...
    if TotalGames > 0:
        for x in range(0, TotalGames, 1):
            HomeAbbr = GameList[x]["teams"]["home"]["team"]["abbreviation"]
            HomeID = GameList[x]["teams"]["home"]["team"]["id"]
            HomeLogoURL = LOGO_PREFIX + str(HomeID) + LOGO_SUFFIX
            AwayAbbr = GameList[x]["teams"]["away"]["team"]["abbreviation"]
            AwayID = GameList[x]["teams"]["away"]["team"]["id"]

            #print(AwayAbbr, AwayID)
            AwayLogoURL = LOGO_PREFIX + str(AwayID) + LOGO_SUFFIX

            DisplayHomeLogo = get_teamlogo(HomeLogoURL)
            DisplayAwayLogo = get_teamlogo(AwayLogoURL)

            Status = GameList[x]["status"]["statusCode"]

            if Status == "I":
                # In progress game
                InningState = GameList[x]["linescore"]["inningState"]
                Inning = GameList[x]["linescore"]["currentInningOrdinal"]
                GameSituation = InningState[:3] + " " + Inning
                HomeScore = str(GameList[x]["teams"]["home"]["score"])
                AwayScore = str(GameList[x]["teams"]["away"]["score"])
                scoreFont = "Dina_r400-6"
            elif Status.startswith("F"):
                # Game is finished
                if GameList[x]["linescore"]["currentInning"] > 9:
                    GameSituation = "FINAL/" + str(GameList[x]["linescore"]["currentInning"])
                else:
                    GameSituation = "FINAL"
                HomeScore = str(GameList[x]["teams"]["home"]["score"])
                AwayScore = str(GameList[x]["teams"]["away"]["score"])
                scoreFont = "Dina_r400-6"
            elif Status == "PW":
                # Warmup
                GameSituation = "WARMUP"
                HomeScore = str(GameList[x]["teams"]["home"]["score"])
                AwayScore = str(GameList[x]["teams"]["away"]["score"])
                scoreFont = "Dina_r400-6"
            elif Status == "S" or Status.startswith("P"):
                # Game is scheduled or preview
                # Display the start time of the game in your local time in the top right
                GameTime = GameList[x]["gameDate"]
                ParsedGameTime = time.parse_time(GameTime, format = "2006-01-02T15:04:00Z07:00").in_location(localtimezone)
                StartTime = ParsedGameTime.format("15:04")
                GameSituation = StartTime
                HomeScore = str(GameList[x]["teams"]["home"]["leagueRecord"]["wins"]) + "-" + str(GameList[x]["teams"]["home"]["leagueRecord"]["losses"])
                AwayScore = str(GameList[x]["teams"]["away"]["leagueRecord"]["wins"]) + "-" + str(GameList[x]["teams"]["away"]["leagueRecord"]["losses"])
                scoreFont = "CG-pixel-3x5-mono"
            elif Status == "IR":
                # Delayed - Rain
                InningState = GameList[x]["linescore"]["inningState"]
                Inning = GameList[x]["linescore"]["currentInningOrdinal"]
                GameSituation = InningState[:3] + " " + Inning + " D"
                HomeScore = str(GameList[x]["teams"]["home"]["score"])
                AwayScore = str(GameList[x]["teams"]["away"]["score"])
                scoreFont = "Dina_r400-6"
            elif Status.startswith("D"):
                # Postponed
                GameSituation = "PPD"
                HomeScore = ""
                AwayScore = ""
            elif Status.startswith("C"):
                # Cancelled
                GameSituation = "CNCLD"
                HomeScore = ""
                AwayScore = ""

            awayColor = get_teamcolor(AwayAbbr, AwayID)
            homeColor = get_teamcolor(HomeAbbr, HomeID)

            Display.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "start",
                        children = [
                            render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Box(width = 24, height = 8, color = "#000", child = render.Row(expanded = True, main_align = "start", children = [
                                        render.Padding(pad = (1, 0, 0, 0), child =
                                                                               render.Text(color = "#fff", content = Title, font = "tb-8")),
                                    ])),
                                    render.Box(width = 40, height = 8, color = "#000", child = render.Row(expanded = True, main_align = "end", children = [
                                        render.Text(color = "#fff", content = GameSituation, font = "CG-pixel-3x5-mono"),
                                    ])),
                                ],
                            ),
                            render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = [
                                            render.Box(width = 64, height = 12, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                render.Box(width = 16, height = 16, child = render.Image(src = DisplayAwayLogo, width = 16, height = 16)),
                                                render.Box(width = 24, height = 12, child = render.Text(content = AwayAbbr, color = "#fff", font = textFont)),
                                                render.Box(width = 24, height = 12, child = render.Text(content = AwayScore, color = "#fff", font = scoreFont)),
                                            ])),
                                            render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                render.Box(width = 16, height = 16, child = render.Image(src = DisplayHomeLogo, width = 16, height = 16)),
                                                render.Box(width = 24, height = 12, child = render.Text(content = HomeAbbr, color = "#fff", font = textFont)),
                                                render.Box(width = 24, height = 12, child = render.Text(content = HomeScore, color = "#fff", font = scoreFont)),
                                            ])),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            )

        # no games on
    else:
        Display.extend(
            [
                render.Column(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "start",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Box(width = 24, height = 8, color = "#000", child = render.Row(expanded = True, main_align = "start", children = [
                                    render.Padding(pad = (1, 0, 0, 0), child =
                                                                           render.Text(color = "#fff", content = Title, font = "tb-8")),
                                ])),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = [
                                        render.Box(width = 64, height = 12, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 64, height = 12, child = render.Text(content = "No Games", color = "#fff", font = textFont)),
                                        ])),
                                        render.Box(width = 64, height = 12, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 64, height = 12, child = render.Text(content = "Today", color = "#fff", font = textFont)),
                                        ])),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )

    return render.Root(
        delay = int(RotationSpeed) * 1000,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Animation(
                    children = Display,
                ),
            ],
        ),
    )

LeagueOptions = [
    schema.Option(
        display = "All Triple A",
        value = "1",
    ),
    schema.Option(
        display = "AAA - International League",
        value = "117",
    ),
    schema.Option(
        display = "AAA - Pacific Coast League",
        value = "112",
    ),
    schema.Option(
        display = "All Double A",
        value = "2",
    ),
    schema.Option(
        display = "AA - Eastern League",
        value = "113",
    ),
    schema.Option(
        display = "AA - Southern League",
        value = "111",
    ),
    schema.Option(
        display = "AA - Texas League",
        value = "109",
    ),
]

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

# Which COL? Clippers are 445 and Clingstones are 6325
def get_teamcolor(TeamAbbr, TeamID):
    if TeamID == 445:
        TeamAbbr = "COL1"
    elif TeamID == 6325:
        TeamAbbr = "COL2"

    colors = json.decode(COLORS)
    usecol = colors.get(TeamAbbr, "False")
    if usecol != "False":
        color = colors[TeamAbbr]
    else:
        color = "#000"
    return color

def get_teamlogo(LogoURL):
    DisplayLogo = get_cachable_data(LogoURL, 86400)
    return DisplayLogo

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "League",
                name = "League",
                desc = "Choose your league",
                icon = "baseball",
                default = LeagueOptions[0].value,
                options = LeagueOptions,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Rotation Speed",
                desc = "How many seconds each page is displayed",
                icon = "gear",
                default = RotationOptions[1].value,
                options = RotationOptions,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
