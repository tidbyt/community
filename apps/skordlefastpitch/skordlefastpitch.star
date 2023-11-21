"""
Applet: SkordleFastPitch
Summary: Displays FP Games
Description: The app gets fast pitch data from the Skordle website to display on the Tidbyt. A user can select the class of game and manually select which game to display.
Author: Woolycoin437420
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#Constants
DEFAULT_CLASS = "6A"
DEFAULT_GAME = "1"

#The following dictionary is used by the settings and some values in the main function.
#The ID numbers are used in the URL in the main function.

CLASSES = {"6A": 240, "5A": 241, "4A": 242, "3A": 243, "2A": 244, "A": 245, "B": 246, "Other": 453}

#This is the main function that runs after the settings. Returns display
def main(config):
    data = []
    sportClass = config.str("class", DEFAULT_CLASS)
    classID = CLASSES[sportClass]
    current_game = config.get("games", DEFAULT_GAME)
    total_games = cache.get("{}max".format(classID))

    if total_games == None:
        get_data(classID)
        total_games = cache.get("{}max".format(classID))

    #Type conversion from string to int
    current_game = int(current_game)
    total_games = int(total_games)

    data = cache.get("{}{}".format(classID, current_game))
    if data == None and total_games > 0:
        get_data(classID)
        data = cache.get("{}{}".format(classID, current_game))

    #The filtered data list is a temporary storage while the data variable is sorted.
    filtered_data = []

    if data != None:
        #Data is a list that was converted into a string.
        #The slice notation cuts off the [] and the split makes a new list
        data = data[1:-1].split(", ")

        #For some reason, the split caused escape characters to be added to each item.
        #This is where the filtered data list comes in.
        #The slice notation cuts off the escape characters and extra quotes.
        for item in data:
            filtered_data.append("{}".format(item[1:-1]))
        data = filtered_data

    first_icon_url = ""
    second_icon_url = ""
    first_team = ""
    second_team = ""
    first_score = ""
    second_score = ""
    progress = ""
    datetime = ""

    if total_games > 0:
        is_date = False

        #The following conditions are used to properly unpack the sorted game.
        #Please note that the score variables sometimes double as the date/time variables
        if len(data) == 7:
            first_icon_url, first_team, first_score, second_icon_url, second_team, second_score, progress = data
        elif len(data) == 6:
            first_icon_url, first_team, first_score, second_icon_url, second_team, second_score, progress = data
        elif len(data) == 5:
            first_icon_url, first_team, datetime, second_icon_url, second_team = data
            datetime = datetime.split(" @ ")
            first_score, second_score = datetime
            progress = "Scheduled"
            is_date = True
        elif len(data) == 4:
            first_icon_url, first_team, second_icon_url, second_team = data
            first_score, second_score = "N/A", "N/A"
            progress = "Coming Soon"

        if is_date:
            scores = "Date: " + first_score + " Time: " + second_score
        else:
            scores = "Scores: " + first_score + "/" + second_score

        return render.Root(
            child = render.Column(
                children = [
                    render.Box(
                        child = render.Text(
                            content = "Game {} of {}".format(current_game, total_games),
                            font = "CG-pixel-3x5-mono",
                        ),
                        width = 64,
                        height = 7,
                        padding = 1,
                        color = "#0000ff",
                    ),
                    render.Marquee(
                        child = render.Column(
                            children = [
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(first_icon_url).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = first_team + " vs",
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(second_icon_url).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = second_team,
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(first_icon_url).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = first_team + " vs",
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(second_icon_url).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = second_team,
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(first_icon_url).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = first_team + " vs",
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = http.get(second_icon_url).body(),
                                            width = 15,
                                            height = 15,
                                        ),
                                        render.WrappedText(
                                            content = second_team,
                                            width = 49,
                                            linespacing = 1,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ],
                                    cross_align = "center",
                                    expanded = True,
                                ),
                            ],
                        ),
                        scroll_direction = "vertical",
                        height = 15,
                    ),
                    render.Box(
                        child = render.Marquee(
                            child = render.Row(
                                children = [
                                    render.Text(
                                        content = "Status: " + progress + " | " + scores,
                                        font = "CG-pixel-3x5-mono",
                                    ),
                                ],
                                cross_align = "center",
                            ),
                            scroll_direction = "horizontal",
                            width = 64,
                            offset_start = 64,
                            offset_end = 64,
                            delay = 10,
                        ),
                        width = 64,
                        height = 11,
                        padding = 1,
                        color = "#a64800",
                    ),
                ],
                expanded = True,
            ),
        )

    else:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "No Events for {} Fast Pitch".format(sportClass),
                    width = 60,
                    linespacing = 1,
                    font = "CG-pixel-3x5-mono",
                ),
                width = 64,
                height = 32,
                padding = 1,
            ),
        )

#This function gets and stores the data for the desired sport class.
def get_data(classID):
    web = http.get("https://skordle.com/scores/?sportid=11&classid={}&clubid=1".format(classID), ttl_seconds = 60)
    if web.status_code != 200:
        fail("Failure code: %s", web.status_code)

    #The sort function breaks up the HTML data and returns a dictionary.
    #This dictionary contains lists of data for each game.
    sorted = sort(web.body())
    cache.set("{}max".format(classID), "{}".format(len(sorted)), ttl_seconds = 3600)
    for game in sorted:
        cache.set("{}{}".format(classID, game), "{}".format(sorted[game]), ttl_seconds = 3600)

#Sorts through HTML data and returns numbered games with their data
#It gets weird, but the slice notation helps.
def sort(body):
    sorted = {}
    tables = []
    counter = 0
    team = ""
    dt_jumble = ""
    team_jumble = ""
    has_games = False

    sections = body.split("<table")

    if len(sections) != 1:
        has_games = True

    if has_games:
        for section in sections:
            if "</table>" in section:
                tables.append(section)

        #The last item in tables contains the last table and the rest of the document.
        #To fix this, the program breaks the string at the end of the table.
        #It then replaces the final item with only the table.

        last_table = tables[-1].split("</table>")
        tables[-1] = last_table[0]

        for table in tables:
            counter += 1
            sorted[counter] = []
            elements = table.split("<td")

            #This is the loop that finds and stores relevant data.
            #Each cell of a table contains a class identifier for teams, scores, etc.
            #Their format is remarkably consistent, so slice notation is often enough.
            for element in elements:
                if "teamcell" in element:
                    #The teamcells are a little inconsistent, hence the many conditions.
                    sorting = element[:-5].split("<span")

                    if len(sorting) == 2:
                        team_jumble = sorting[0]
                        team = team_jumble.split(">")

                    elif len(sorting) == 3:
                        team_jumble = sorting[1]
                        team = team_jumble.split("</span>")

                    team = team[-1]

                    if team[0] == " ":
                        team = team[1:]

                    if team[-1] == " ":
                        team = team[:-1]

                    if team[0] == "@":
                        team = team[1:]

                    sorted[counter].append(team)

                if "scorecell" in element:
                    sorted[counter].append(element[19:-14])

                if "logocell" in element:
                    sorted[counter].append(element[28:-39])

                if "datetimecell" in element:
                    dt_jumble = element[34:-14]
                    dt_jumble = dt_jumble.replace("<br>", " ")
                    dt_jumble = dt_jumble.replace("</br>", " ")
                    sorted[counter].append(dt_jumble)

                if "progresscell" in element:
                    split = element.split("</td>")
                    sorted[counter].append(split[0][22:])

    return sorted

#Mobile settings function that returns the desired sport and class
def get_schema():
    class_options = [schema.Option(display = c, value = c) for c in CLASSES]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "class",
                name = "Classes",
                desc = "The class of sport whose games will be displayed",
                icon = "arrowUpShortWide",
                default = DEFAULT_CLASS,
                options = class_options,
            ),
            #A changing set of game options determined by the class selection.
            schema.Generated(
                id = "generated",
                source = "class",
                handler = game_options,
            ),
        ],
    )

#A function that determines what options should be displayed based on the sport class.
def game_options(c):
    classID = CLASSES[c]
    games = cache.get("{}max".format(classID))
    if games == None:
        get_data(classID)
        games = cache.get("{}max".format(classID))

    #List of Games to select
    if int(games) > 0:
        game_options = [schema.Option(display = "{}".format(game + 1), value = "{}".format(game + 1)) for game in range(int(games))]
    else:
        game_options = [schema.Option(display = "None", value = "0")]
    return [
        schema.Dropdown(
            id = "games",
            name = "Games",
            desc = "The various games to choose from",
            icon = "baseballBatBall",
            default = DEFAULT_GAME,
            options = game_options,
        ),
    ]
