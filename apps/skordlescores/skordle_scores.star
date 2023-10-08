"""
Applet: Skordle Scores
Summary: Displays Skordle.com Scores
Description: This app gets the HTML form of Skordle.com for a specific sport and class. It then sorts through and displays the data of each game. This information is mostly relevant to high school games in the Oklahoma area.
Author: Woolycoin437420
"""

#Credit: 2014-2023 © All Rights Reserved. Skordle Advertising, LLC
#^They are the ones who post the information and keep their website so consistent.
#Before beginning, I should mention that I'm a high school student and not a professional.
#If anyone has suggestions, please inform me of any improvements.
#This is a project requested by my physics teacher and I hope it's approved.

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#Constants
DEFAULT_SPORT = "Football"
DEFAULT_CLASS = "6A-1"

#The following dictionaries are used by the settings and some values in the main function.
#The ID numbers are used in the URL in the main function.
SPORT_IDS = {
    "Football": 1,
    "Boy's Basketball": 2,
    "Girl's Basketball": 3,
    "High School Baseball": 4,
    "High School Slow Pitch": 5,
    "Volleyball": 7,
    "Fast Pitch": 11,
    "Fall Baseball": 12,
    "High School Cross Country": 21,
    "High School Softball": 29,
    "High School Men's Basketball": 30,
    "High School Women's Basketball": 31,
}

CLASS_IDS = {
    "Football": {"6A-1": 8, "6A-2": 19, "5A": 7, "4A": 6, "3A": 5, "2A": 4, "A": 1, "B": 2, "C": 3, "Other": 68},
    "Boy's Basketball": {"6A": 70, "5A": 71, "4A": 72, "3A": 73, "2A": 74, "A": 75, "B": 76, "Other": 119},
    "Girl's Basketball": {"6A": 77, "5A": 78, "4A": 79, "3A": 80, "2A": 81, "A": 82, "B": 83, "Other": 121},
    "High School Baseball": {"6A": 217, "5A": 218, "4A": 219, "3A": 220, "2A": 221, "A": 222, "B": 223, "Other": 224},
    "High School Slow Pitch": {"6A": 225, "5A": 226, "4A": 227, "3A": 228, "2A": 229, "A": 230, "Other": 231},
    "Volleyball": {"6A": 429, "5A": 430, "4A": 431, "3A": 432, "Other": 433},
    "Fast Pitch": {"6A": 240, "5A": 241, "4A": 242, "3A": 243, "2A": 244, "A": 245, "B": 246, "Other": 453},
    "Fall Baseball": {"A": 247, "B": 248},
    "High School Cross Country": {},
    "High School Softball": {},
    "High School Men's Basketball": {},
    "High School Women's Basketball": {},
}

#This list is used to generate the mobile options.
CLASSES = ["6A-1", "6A-2", "6A", "5A", "4A", "3A", "2A", "A", "B", "C", "Other"]

#This is the main function that runs after the settings. Returns display
def main(config):
    total_games = cache.get("max")
    current_game = cache.get("current")
    if current_game != None:
        data = cache.get(current_game)
    else:
        data = []
    stored_sportid = cache.get("sport")
    stored_classid = cache.get("class")

    sport = config.str("sport", DEFAULT_SPORT)
    sportID = SPORT_IDS[sport]
    sportClass = config.str("class", DEFAULT_CLASS)
    classID = "N/A"
    classAmount = len(CLASS_IDS[sport])

    if classAmount > 0:
        classInSport = False

        #Testing for the selected class in the sport's list.
        for c in CLASS_IDS[sport]:
            if c == sportClass:
                classInSport = True
                break

        if classInSport == False:
            #This loop gets the first class of the sport.
            for c in CLASS_IDS[sport]:
                sportClass = c
                break

        classID = CLASS_IDS[sport][sportClass]

    #The following conditional determines if the website data must be pulled again.
    if total_games == None or current_game == None or stored_sportid == None or stored_classid == None or int(stored_sportid) != SPORT_IDS[sport] or int(stored_classid) != classID and classAmount > 0:
        total_games, current_game, data = get_data(sportID, classID)

    #Type conversion from string to int
    total_games = int(total_games)
    current_game = int(current_game)

    #Resets the current game and associated data
    if current_game > total_games:
        current_game = 1
        data = cache.get("1")

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

        cache.set("current", "{}".format(current_game + 1), ttl_seconds = 360)

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
                        color = "#ff0000",
                    ),
                ],
                expanded = True,
            ),
        )

    elif classAmount > 0:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "No Events Currently for {} {}".format(sport, sportClass),
                    width = 60,
                    linespacing = 1,
                    font = "CG-pixel-3x5-mono",
                ),
                width = 64,
                height = 32,
                padding = 1,
            ),
        )
    else:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "No Events Currently for {}".format(sport),
                    width = 60,
                    linespacing = 1,
                    font = "CG-pixel-3x5-mono",
                ),
                width = 64,
                height = 32,
                padding = 1,
            ),
        )

#This function gets and stores the data for the desired sport and class.
def get_data(sportID, classID):
    if classID != "N/A":
        web = http.get("https://skordle.com/scores/?sportid={}&classid={}&clubid=1".format(sportID, classID), ttl_seconds = 60)
        if web.status_code != 200:
            fail("Failure code: %s", web.status_code)
    else:
        web = http.get("https://skordle.com/scores/?sportid={}&clubid=1".format(sportID), ttl_seconds = 60)
        if web.status_code != 200:
            fail("Failure code: %s", web.status_code)

    #The sort function breaks up the HTML data and returns a dictionary.
    #This dictionary contains lists of data for each game.
    sorted = sort(web.body())
    cache.set("max", "{}".format(len(sorted)), ttl_seconds = 1800)
    cache.set("current", "1", ttl_seconds = 240)
    cache.set("sport", "{}".format(sportID), ttl_seconds = 1800)
    cache.set("class", "{}".format(classID), ttl_seconds = 1800)
    for game in sorted:
        cache.set("{}".format(game), "{}".format(sorted[game]), ttl_seconds = 1800)

    if len(sorted) != 0:
        return "{}".format(len(sorted)), "1", "{}".format(sorted[1])
    else:
        return "0", "0", None

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
                    #The teamcells are a little incosistent, hence the many conditions.
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
    #I have to give credit to the author of the SkiReport app, Colin Morrisseau.
    #I took inspiration for the list comprehension as I forgot it existed.
    #It saved nearly 30 lines here.
    sportOptions = [schema.Option(display = sport, value = sport) for sport in SPORT_IDS]
    classOptions = [schema.Option(display = classes, value = classes) for classes in CLASSES]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "sport",
                name = "Sports",
                desc = "The sport whose games will be displayed",
                icon = "football",
                default = DEFAULT_SPORT,
                options = sportOptions,
            ),
            #If a class is selected that doesn't apply to the sport, it defaults to the first option for the sport.
            schema.Dropdown(
                id = "class",
                name = "Classes",
                desc = "The class of the selected sport\nPlease note that not all classes apply to each sport",
                icon = "arrowUpShortWide",
                default = DEFAULT_CLASS,
                options = classOptions,
            ),
        ],
    )
