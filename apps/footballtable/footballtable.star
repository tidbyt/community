"""
Applet: FootballTable
Summary: Football league standings
Description: Displays league tables for various football leagues.
Author: plumbob86
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

leagueCode = "ELC"

RED = "#FFFFFF"
WHITE = "#FF0000"
GREEN = "#00FF00"
PLAYOFF = "#008000"

def main(config):
    relCount = 0
    clubCount = 0
    playCount = 0
    proCount = 0

    leagueCode = config.get("league", "PL")

    if (leagueCode == "PL"):
        relCount = 3
        clubCount = 20
    elif (leagueCode == "ELC"):
        proCount = 2
        playCount = 3
        relCount = 3
        clubCount = 24
    elif (leagueCode == "FL1"):
        relCount = 3
        clubCount = 18
    elif (leagueCode == "BL1"):
        relCount = 3
        clubCount = 18
    elif (leagueCode == "SA"):
        relCount = 3
        clubCount = 20
    elif (leagueCode == "DED"):
        relCount = 3
        clubCount = 18
    elif (leagueCode == "PPL"):
        relCount = 3
        clubCount = 18
    elif (leagueCode == "PD"):
        relCount = 3
        clubCount = 20
    elif (leagueCode == "BSA"):
        relCount = 4
        clubCount = 20

    TABLE_URL = "http://api.football-data.org/v4/competitions/" + leagueCode + "/standings"
    header = {"X-Auth-Token": "65e34372b55c43178a93468a09dbcd17"}
    rep = http.get(TABLE_URL, ttl_seconds = 1800, headers = header)  # cache for 30 minutes
    if rep.status_code != 200:
        fail("EPL Data request failed with status %d", rep.status_code)
    table = rep.json()["standings"][0]["table"]

    # for development purposes: check if result was served from cache or not
    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling API.")

    stackList = []
    usehue = "#FFFFFF"

    i = 0
    for i in range(len(table)):
        if i % 4 != 0:
            continue
        textList = []

        padNum = 0
        j = 0
        for j in range(4):
            if j + i < len(table):
                if i + j < proCount:
                    usehue = GREEN
                elif i + j > (clubCount - 1) - relCount:
                    usehue = WHITE
                elif (i + j >= proCount) and (i + j < proCount + playCount):
                    usehue = PLAYOFF
                else:
                    usehue = RED
                position = ""
                if (i + j + 1) < 10:
                    position = "0" + str(i + j + 1)
                else:
                    position = str(i + j + 1)
                textList.append(render.Padding(pad = (0, padNum, 0, 0), child = render.Text(color = usehue, content = "#" + position + " " + table[i + j].get("team").get("tla") + " Pts:" + str(int(table[i + j].get("points"))))))
                padNum += 8
        stackList.append(render.Stack(children = textList))
        i += 4

    return render.Root(
        delay = int(15000 / (clubCount / 4)),
        child =
            render.Animation(
                children = (
                    stackList
                ),
            ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "English Premier League",
            value = "PL",
        ),
        schema.Option(
            display = "English Championship",
            value = "ELC",
        ),
        schema.Option(
            display = "French Ligue 1",
            value = "FL1",
        ),
        schema.Option(
            display = "German 1. Bundesliga",
            value = "BL1",
        ),
        schema.Option(
            display = "Italian Serie A",
            value = "SA",
        ),
        schema.Option(
            display = "Dutch Eredivisie",
            value = "DED",
        ),
        schema.Option(
            display = "Portugese Primeira Liga",
            value = "PPL",
        ),
        schema.Option(
            display = "Spanish La Liga",
            value = "PD",
        ),
        schema.Option(
            display = "Brazilian Série A",
            value = "BSA",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "league",
                name = "League to Display",
                desc = "The football league table to display",
                icon = "addressCard",
                default = options[0].value,
                options = options,
            ),
        ],
    )
