"""
Applet: PGA Tour
Summary: Shows PGA Leaderboard
Description: This app displays the leaderboard for the current PGA Tour event, taken from ESPN data feed. The leaderboard will show the first 24 players. Players currently on course are shown in different shades of yellow - going from dark yellow for those players just starting to white for those who have completed their rounds. Players who have not started are shown in green.
Author: M0ntyP

Note - can easily make LPGA, European Tour or Korn Ferry versions if there is enough interest.

Big shoutout to LunchBox8484 for the NHL Standings app where this is heavily borrowed/stolen from

v1.1 
Added rotation speed options and slight formatting change to tournament title (removed "The")

v1.2 
Added ability to show opposite field events, for the 4 times a year this happens

v1.2b 
Bug fix - when there are multiple events on (opposite field events) the app is showing both leaderboards under the 1 tournament heading
This has been fixed
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API = "https://site.web.api.espn.com/apis/v2/scoreboard/header?sport=golf&league=pga"

CACHE_TTL_SECS = 60

def main(config):
    renderCategory = []
    i = 0
    RotationSpeed = config.get("speed", "3")
    OppField = config.bool("OppFieldToggle")
    CacheData = get_cachable_data(API, CACHE_TTL_SECS)
    leaderboard = json.decode(CacheData)

    mainFont = "CG-pixel-3x5-mono"
    Title = leaderboard["sports"][0]["leagues"][0]["name"]

    # Check if there is an opposite field event, happens 4 times a season
    # Get the ID of the first event listed in the API
    TournamentID = leaderboard["sports"][0]["leagues"][0]["events"][0]["id"]
    i = OppositeFieldCheck(TournamentID)

    # if user wants to see opposite event
    if i == 1 and OppField == True:
        i = 0

    TournamentName = leaderboard["sports"][0]["leagues"][0]["events"][i]["name"]
    Location = leaderboard["sports"][0]["leagues"][0]["events"][i]["location"]
    StartDate = leaderboard["sports"][0]["leagues"][0]["events"][i]["date"]
    EndDate = leaderboard["sports"][0]["leagues"][0]["events"][i]["endDate"]

    StartDateFormat = time.parse_time(StartDate, format = "2006-01-02T15:04:00Z")
    EndDateFormat = time.parse_time(EndDate, format = "2006-01-02T15:04:00Z")
    StartDate = StartDateFormat.format("Jan 2")
    EndDate = EndDateFormat.format("Jan 2")

    if (leaderboard):
        stage1 = leaderboard["sports"][0]["leagues"][0]["events"][i]["status"]

        # In progress or completed tournament
        if stage1 == "in" or stage1 == "post":
            entries = leaderboard["sports"][0]["leagues"][0]["events"][i]["competitors"]
            stage = leaderboard["sports"][0]["leagues"][0]["events"][i]["fullStatus"]["type"]["detail"]
            state = leaderboard["sports"][0]["leagues"][0]["events"][i]["fullStatus"]["type"]["state"]

            # shortening status messages
            stage = stage.replace("Final", "F")
            stage = stage.replace("Round 1", "R1")
            stage = stage.replace("Round 2", "R2")
            stage = stage.replace("Round 3", "R3")
            stage = stage.replace("Round 4", "R4")
            stage = stage.replace(" - In Progress", "")
            stage = stage.replace(" - Suspended", "")
            stage = stage.replace(" - Play Complete", "")
            stage = stage.replace(" - Playoff", "PO")
            stage = stage.replace("Playoff - Play Complete", "PO")

            if entries:
                # how many players per page?
                entriesToDisplay = 4

                # len(entries)-1 = 24 and divides into 4 nicely
                for x in range(0, len(entries) - 1, entriesToDisplay):
                    renderCategory.extend([
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_player(x, entries, entriesToDisplay, TournamentName, 5, stage, state),
                                ),
                            ],
                        ),
                    ])

            return render.Root(
                show_full_animation = True,
                delay = int(RotationSpeed) * 1000,
                child = render.Animation(children = renderCategory),
            )

        elif stage1 == "pre":
            # if there is no live tournament, show what event is coming up next
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
                                render.Box(width = 64, height = 5, color = "#0039A6", child = render.Text(content = Title, color = "#FFF", font = mainFont)),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 12, color = "#000", child = render.Text(content = "Next event...", color = "#FFF", font = mainFont)),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Marquee(width = 64, height = 12, child = render.Text(content = TournamentName + " - " + Location, color = "#FFF", font = mainFont)),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 10, color = "#000", child = render.Text(content = StartDate + " - " + EndDate, color = "#FFF", font = mainFont)),
                            ],
                        ),
                    ],
                ),
            )

    return []

def get_player(x, s, entriesToDisplay, Title, topcolHeight, stage, state):
    # Remove "The" if its in the title, but not for "The Open", its a major so we treat it with respect...and it will fit anyway
    if Title.startswith("The"):
        if Title != "The Open":
            Title = Title.replace("The ", "")

    # keep first 10 chars of the tournament name, then remove any extra " " at the end
    Title = Title[:10]
    Title = Title.rstrip()
    mainFont = "CG-pixel-3x5-mono"
    output = []

    topColumn = [render.Box(width = 64, height = topcolHeight, color = "#0039A6", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = topcolHeight, child = render.Text(content = Title + " - " + stage, color = "#fff", font = mainFont)),
    ]))]

    output.extend(topColumn)
    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            playerName = s[i + x]["lastName"]
            score = s[i + x]["score"]
            displayScore = str(score)

            # check if they've played at least 1 hole this round
            if (s[i + x]["status"]["thru"]) > 0:
                HolesCompleted = s[i + x]["status"]["thru"]
            else:
                HolesCompleted = 0

            # check if the entire round has been completed
            # once round is complete, "thru" resets to 0 so it can make it look like players have not started their round
            if state == "post":
                HolesCompleted = 18

            # Players who have completed their round are shown in white, in progress rounds are in yellow which slowly transitions to white as the round progresses.
            # This is the best thing I can think of at the moment as there is not enough room to fit the hole number on the screen as well as name & score
            # Maybe nested animations to show score then hole number in that box, not recommended according to the doco though
            playerFontColor = get_player_font_color(HolesCompleted)

            # if tournament is over, show winner in blue
            if (i + x) == 0 and stage == "F":
                playerFontColor = "#68f"

            player = render.Row(
                children = [
                    render.Box(
                        height = 7,
                        width = (52, 32)[0],
                        child = render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Marquee(
                                width = (52, 32)[0],
                                child = render.Text(
                                    content = playerName,
                                    color = playerFontColor,
                                    font = mainFont,
                                    offset = 0,
                                ),
                            ),
                        ),
                    ),
                    render.Box(
                        height = 7,
                        width = (12, 32)[0],
                        child = render.Text(
                            content = displayScore,
                            color = playerFontColor,
                            font = mainFont,
                            offset = 0,
                        ),
                    ),
                ],
            )
            output.extend([player])
    return output

def get_player_font_color(HolesCompleted):
    if HolesCompleted == 18:
        playerFontColor = "#fff"
    elif HolesCompleted == 17:
        playerFontColor = "#ffa"
    elif HolesCompleted == 16:
        playerFontColor = "#ff5"
    elif HolesCompleted == 14 or HolesCompleted == 15:
        playerFontColor = "#ff0"
    elif HolesCompleted == 12 or HolesCompleted == 13:
        playerFontColor = "#fe0"
    elif HolesCompleted == 10 or HolesCompleted == 11:
        playerFontColor = "#fd0"
    elif HolesCompleted == 8 or HolesCompleted == 9:
        playerFontColor = "#fc0"
    elif HolesCompleted == 6 or HolesCompleted == 7:
        playerFontColor = "#fb0"
    elif HolesCompleted == 4 or HolesCompleted == 5:
        playerFontColor = "#fa0"
    elif HolesCompleted == 2 or HolesCompleted == 3:
        playerFontColor = "#f90"
    elif HolesCompleted == 1:
        playerFontColor = "#f80"
    elif HolesCompleted == 0:
        playerFontColor = "#4ec9b0"
    else:
        playerFontColor = ""

    return playerFontColor

def OppositeFieldCheck(id):
    # check if the first tournament listed in the ESPN API is an opposite field event, one of the four below
    # and if it is, go to the second event in the API
    i = 0
    if id == "401465525":  # Puerto Rico Open
        i = 1
    elif id == "401465529":  # Puntacana
        i = 1
    elif id == "401465538":  # Barbasol
        i = 1
    elif id == "401465540":  # Barracuda
        i = 1
    else:
        i = 0
    return i

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
                id = "OppFieldToggle",
                name = "Show Opposite Field event",
                desc = "Show the opposite event",
                icon = "toggleOn",
                default = False,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        #print("Using cached data")
        return base64.decode(data)

    res = http.get(url = url)

    #print("Getting new data")
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = timeout)

    return res.body()
