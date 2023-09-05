"""
Applet: MiLB Scores
Summary: Minor League scores
Description: Shows baseball scores for the Minor Leagues.
Author: M0ntyP


"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_PREFIX = "https://bdfed.stitch.mlbinfra.com/bdfed/transform-milb-scoreboard?stitch_env=prod&sortTemplate=4&sportId=11&"
API_SUFFIX = "&gameType=R&&gameType=F&&gameType=D&&gameType=L&&gameType=W&&gameType=A&&gameType=C&season=2023&language=en&leagueId="
API_SUFFIX2 = "&contextTeamId=milb&teamId="
ET_TIMEZONE = "America/New_York"
DEFAULT_TIMEZONE = "Australia/Adelaide"

COLORS = """
{
    "BUF": "#060da4",
    "CLT": "#00a5ce",
    "COL": "#204885",
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
    "ABQ": "#fa742a",
    "ELP": "#d31245",
    "LV": "#ff4d00",
    "OKC": "#005596",
    "RNO": "#002a5c",
    "RR": "#9d2235",
    "SAC": "#95002a",
    "SL": "#fcb817",
    "SUG": "#41c4dd",
    "TAC": "#e51837"
}
"""

def main(config):
    Display = []
    Title = ""
    localtimezone = config.get("$tz", DEFAULT_TIMEZONE)
    SelectedLeague = config.get("League", "1")
    RotationSpeed = config.get("speed", "3")

    if SelectedLeague == "1":
        SelectedLeague = ""
        Title = "MiLB"
    elif SelectedLeague == "112":
        Title = "PCL"
    elif SelectedLeague == "117":
        Title = "IL"

    # Get the date on the East Coast of US, as all game times are listed as ET
    now = time.now().in_location(ET_TIMEZONE)
    strnow = str(now)
    date = strnow[:10]

    # date = "2023-08-06"
    API_DATE = "startDate=" + date + "&endDate=" + date
    API = API_PREFIX + API_DATE + API_SUFFIX + SelectedLeague + API_SUFFIX2
    # print(API)

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
            AwayAbbr = GameList[x]["teams"]["away"]["team"]["abbreviation"]
            Status = GameList[x]["status"]["statusCode"]

            if Status == "I":
                # In progress game
                InningState = GameList[x]["linescore"]["inningState"]
                Inning = GameList[x]["linescore"]["currentInningOrdinal"]
                GameSituation = InningState[:3] + " " + Inning
                HomeScore = str(GameList[x]["teams"]["home"]["score"])
                AwayScore = str(GameList[x]["teams"]["away"]["score"])
                scoreFont = "Dina_r400-6"
            elif Status == "F":
                # Game is finished
                if GameList[x]["linescore"]["currentInning"] > 9:
                    GameSituation = "FINAL/" + str(GameList[x]["linescore"]["currentInning"])
                else:
                    GameSituation = "FINAL"
                HomeScore = str(GameList[x]["teams"]["home"]["score"])
                AwayScore = str(GameList[x]["teams"]["away"]["score"])
                scoreFont = "Dina_r400-6"
            elif Status == "S" or Status == "P":
                # Game is scheduled or preview
                # Display the start time of the game in your local time in the top right
                GameTime = GameList[x]["gameDate"]
                ParsedGameTime = time.parse_time(GameTime, format = "2006-01-02T15:04:00Z07:00").in_location(localtimezone)
                StartTime = ParsedGameTime.format("15:04")
                GameSituation = StartTime
                HomeScore = str(GameList[x]["teams"]["home"]["leagueRecord"]["wins"]) + "-" + str(GameList[x]["teams"]["home"]["leagueRecord"]["losses"])
                AwayScore = str(GameList[x]["teams"]["away"]["leagueRecord"]["wins"]) + "-" + str(GameList[x]["teams"]["away"]["leagueRecord"]["losses"])
                scoreFont = "CG-pixel-3x5-mono"
            elif Status == "PW":
                # Warmup
                GameSituation = "WARMUP"
                HomeScore = str(GameList[x]["teams"]["home"]["score"])
                AwayScore = str(GameList[x]["teams"]["away"]["score"])
                scoreFont = "Dina_r400-6"
            elif Status == "IR":
                # Delayed - Rain
                InningState = GameList[x]["linescore"]["inningState"]
                Inning = GameList[x]["linescore"]["currentInningOrdinal"]
                GameSituation = InningState[:3] + " " + Inning + " D"
                HomeScore = str(GameList[x]["teams"]["home"]["score"])
                AwayScore = str(GameList[x]["teams"]["away"]["score"])
                scoreFont = "Dina_r400-6"
            elif Status == "DR" or Status == "DD" or Status == "DI":
                # Postponed
                GameSituation = "PPD"
                HomeScore = ""
                AwayScore = ""
            elif Status == "CO" or Status == "CR":
                # Cancelled
                GameSituation = "CNCLD"
                HomeScore = ""
                AwayScore = ""

            awayColor = get_teamcolor(AwayAbbr)
            homeColor = get_teamcolor(HomeAbbr)

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
                                    render.Box(width = 20, height = 8, color = "#000", child = render.Row(expanded = True, main_align = "start", children = [
                                        render.Text(color = "#fff", content = Title, font = "tb-8"),
                                    ])),
                                    render.Box(width = 44, height = 8, color = "#000", child = render.Row(expanded = True, main_align = "end", children = [
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
                                                render.Box(width = 32, height = 12, child = render.Text(content = AwayAbbr, color = "#fff", font = textFont)),
                                                render.Box(width = 32, height = 12, child = render.Text(content = AwayScore, color = "#fff", font = scoreFont)),
                                            ])),
                                            render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                render.Box(width = 32, height = 12, child = render.Text(content = HomeAbbr, color = "#fff", font = textFont)),
                                                render.Box(width = 32, height = 12, child = render.Text(content = HomeScore, color = "#fff", font = scoreFont)),
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
                                render.Box(width = 20, height = 8, color = "#000", child = render.Row(expanded = True, main_align = "start", children = [
                                    render.Text(color = "#fff", content = Title, font = "tb-8"),
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
        display = "Both",
        value = "1",
    ),
    schema.Option(
        display = "International League",
        value = "117",
    ),
    schema.Option(
        display = "Pacific Coast League",
        value = "112",
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

def get_teamcolor(TeamAbbr):
    colors = json.decode(COLORS)
    color = colors[TeamAbbr]
    return color

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
