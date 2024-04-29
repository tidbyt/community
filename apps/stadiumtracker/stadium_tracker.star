"""
Applet: Stadium Tracker
Summary: Track Stadiums and Ball Parks you've visted.
Description: Track stadiums and ball parks you've visted.
Author: Robert Ison
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

LEAGUE_OPTIONS = [
    schema.Option(value = "mlb", display = "Major League Baseball"),
    schema.Option(value = "nba", display = "National Basketball Association"),
    schema.Option(value = "nfl", display = "National Football League"),
    schema.Option(value = "nhl", display = "National Hockey League"),
]

# Tidbyt display is 64x32 -- these are coordinates for the map and each team
USAMAP = [[0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 9], [0, 10], [0, 11], [0, 12], [0, 13], [0, 14], [0, 15], [0, 16], [0, 17], [0, 18], [0, 19], [0, 20], [0, 21], [0, 22], [0, 23], [0, 24], [0, 25], [0, 26], [0, 27], [0, 28], [0, 29], [0, 30], [0, 31], [0, 32], [0, 33], [1, 0], [1, 2], [1, 33], [1, 34], [1, 35], [1, 36], [1, 37], [1, 38], [2, 0], [2, 1], [2, 2], [2, 38], [2, 39], [3, 0], [3, 39], [3, 40], [3, 41], [3, 61], [3, 62], [4, 0], [4, 1], [4, 41], [4, 42], [4, 43], [4, 60], [4, 61], [4, 62], [5, 1], [5, 43], [5, 44], [5, 45], [5, 59], [5, 60], [5, 62], [5, 63], [6, 1], [6, 45], [6, 56], [6, 57], [6, 58], [6, 59], [6, 63], [7, 0], [7, 45], [7, 53], [7, 54], [7, 55], [7, 56], [7, 62], [7, 63], [8, 0], [8, 45], [8, 46], [8, 53], [8, 60], [8, 61], [9, 0], [9, 46], [9, 50], [9, 51], [9, 52], [9, 53], [9, 60], [10, 0], [10, 46], [10, 47], [10, 48], [10, 49], [10, 50], [10, 60], [11, 0], [11, 58], [11, 59], [12, 0], [12, 56], [12, 57], [12, 58], [13, 0], [13, 56], [14, 0], [14, 1], [14, 55], [15, 1], [15, 54], [16, 2], [16, 54], [17, 2], [17, 3], [17, 53], [17, 54], [18, 3], [18, 53], [19, 3], [19, 4], [19, 53], [20, 4], [20, 5], [20, 51], [20, 52], [21, 5], [21, 6], [21, 7], [21, 50], [21, 51], [22, 7], [22, 8], [22, 49], [22, 50], [23, 8], [23, 9], [23, 10], [23, 11], [23, 12], [23, 13], [23, 49], [24, 13], [24, 14], [24, 15], [24, 16], [24, 17], [24, 18], [24, 19], [24, 48], [24, 49], [25, 19], [25, 20], [25, 21], [25, 22], [25, 48], [26, 22], [26, 23], [26, 24], [26, 25], [26, 33], [26, 34], [26, 35], [26, 36], [26, 37], [26, 39], [26, 40], [26, 41], [26, 42], [26, 43], [26, 48], [27, 25], [27, 33], [27, 37], [27, 38], [27, 39], [27, 43], [27, 44], [27, 45], [27, 48], [28, 26], [28, 32], [28, 46], [28, 49], [29, 27], [29, 30], [29, 31], [29, 46], [29, 49], [30, 28], [30, 30], [30, 47], [30, 49], [31, 29], [31, 30], [31, 48]]

MLB_TEAMS = [["Astros", [31, 27], "Minute Maid Park", "Houston"], ["Angels", [5, 18], "Angel Stadium", "Los Angeles"], ["Athletics", [3, 15], "Oakland Coliseum", "Oakland"], ["Blue Jays", [50, 7], "Rogers Center", "Toronto"], ["Braves", [44, 21], "Truist Park", "Atlanta"], ["Brewers", [39, 8], "American Family Field", "Milwaukee"], ["Cardinals", [36, 16], "Busch Stadium", "St. Louis"], ["Cubs", [38, 11], "Wrigley Field", "Chicago"], ["Diamondbacks", [12, 19], "Chase Field", "Arizona"], ["Dodgers", [4, 18], "Dodger Stadium", "Los Angeles"], ["Giants", [2, 15], "Oracle Park", "San Francisco"], ["Guardians", [47, 11], "Progressive Field", "Cleveland"], ["Mariners", [2, 3], "T-Mobile Park", "Seattle"], ["Marlins", [48, 30], "LoanDepot Park", "Miami"], ["Mets", [57, 11], "Citi Field", "New York"], ["Nationals", [52, 15], "Nationals Park", "Washington"], ["Orioles", [54, 14], "Camden Yards", "Baltimore"], ["Padres", [6, 20], "Petco Park", "San Diego"], ["Phillies", [55, 13], "Citizens Bank Park", "Philadelphia"], ["Pirates", [50, 13], "PNC Park", "Pittsburg"], ["Rangers", [30, 22], "Globe Life Field", "Texas"], ["Rays", [47, 28], "Tropicana Field", "Tampa Bay"], ["Red Sox", [59, 10], "Fenway Park", "Boston"], ["Reds", [44, 15], "Great American Ball Park", "Cinncinnati"], ["Rockies", [19, 11], "Coors Field", "Colorado"], ["Royals", [32, 15], "Kauffman Stadium", "Kansas City"], ["Tigers", [45, 10], "Comerica Park", "Detroit"], ["Twins", [34, 6], "Target Field", "Minnesota"], ["White Sox", [40, 12], "Guaranteed Rate Field", "Chicago"], ["Yankees", [56, 11], "Yankee Stadium", "New York"]]

NFL_TEAMS = [["Cardinals", [12, 19], "State Farm Stadium", "Arizona"], ["Falcons", [44, 21], "Mercedes-Benz Stadium", "Atlanta"], ["Ravens", [54, 14], "M&T Park", "Baltimore"], ["Bills", [52, 10], "Highmark Stadium", "Buffalo"], ["Panthers", [48, 18], "Bank of America Stadium", "Carolina"], ["Bears", [38, 11], "Soldier Field", "Chicago"], ["Bengals", [44, 15], "Paycor Stadium", "Cincinnati"], ["Browns", [47, 11], "Cleveland Browns Stadium", "Cleveland"], ["Cowboys", [30, 22], "AT&T Stadium", "Dallas"], ["Broncos", [19, 11], "Mile High Stadium", "Denver"], ["Lions", [45, 10], "Ford Field", "Detroit"], ["Packers", [39, 7], "Lambeau Field", "Green Bay"], ["Texans", [31, 27], "NRG Stadium", "Houston"], ["Colts", [41, 13], "Lucas Oil Field", "Indianapolis"], ["Jaguars", [47, 26], "EverBank Stadium", "Jacksonville"], ["Chiefs", [32, 15], "Arrowhead Stadium", "Kansas City"], ["Raiders", [10, 17], "Allegiant Stadium", "Las Vegas"], ["Chargers", [6, 20], "SoFi Stadium", "Los Angeles"], ["Rams", [5, 18], "SoFi Stadium", "Los Angeles"], ["Dolphins", [48, 30], "Hard Rock Stadium", "Miami"], ["Vikings", [34, 6], "US Bank Stadium", "Minnesota"], ["Patriots", [59, 10], "Gillette Stadium", "New England"], ["Saints", [38, 26], "Superdome", "New Orleans"], ["Giants", [56, 11], "MetLife Stadium", "New York"], ["Jets", [55, 11], "MetLife Stadium", "New York"], ["Eagles", [55, 13], "Lincoln Financial Field", "Philadelphia"], ["Steelers", [50, 13], "Acrisure Stadium", "Pittsburgh"], ["49ers", [2, 15], "Levi's Stadium", "San Francisco"], ["Seahawks", [2, 3], "Lumen Field", "Seattle"], ["Buccaneers", [47, 28], "Raymond James Stadium", "Tampa Bay"], ["Titans", [38, 18], "Nissan Stadium", "Tennessee"], ["Commanders", [52, 15], "Commanders Field", "Washington"]]

NBA_TEAMS = [["Hawks", [44, 21], "State Farm Arena", "Atlanta"], ["Celtics", [59, 10], "TD Garden", "Boston"], ["Nets", [56, 11], "Barclay's Center", "Brooklyn"], ["Hornets", [48, 20], "Spectrum Center", "Charlotte"], ["Bulls", [38, 11], "United Center", "Chicago"], ["Cavaliers", [47, 11], "Rocket Mortgage Fieldhouse", "Cleveland"], ["Mavericks", [30, 22], "American Airllines Center", "Dallas"], ["Nuggets", [19, 11], "Bail Arena", "Denver"], ["Pistons", [45, 10], "Little Ceasars Arena", "Detroit"], ["Warriors", [2, 15], "Chase Center", "Golden State "], ["Rockets", [31, 27], "Toyota Center", "Houston"], ["Pacers", [41, 13], "Gainbridge Fieldhouse", "Indiana"], ["Clippers", [4, 18], "Crypto.com Arena", "Los Angeles"], ["Lakers", [5, 18], "Crypto.com Arena", "Los Angeles"], ["Grizzlies", [36, 18], "FedEx Forum", "Memphis"], ["Heat", [48, 30], "Kaseya Center", "Miami"], ["Bucks", [39, 8], "Fiserv Forum", "Milwaukee"], ["Timberwolves", [34, 6], "Target Center", "Minnesota"], ["Pelicans", [38, 26], "Smoothie King Center", "New Orleans "], ["Knicks", [56, 11], "Madison Square Garden", "New York"], ["Thunder", [31, 20], "Paycom Center", "Oklahoma City"], ["Magic", [47, 28], "Kia Center", "Orlando"], ["76ers", [55, 13], "Wells Fargo Center", "Philadelphia"], ["Suns", [12, 19], "Footprint Center", "Phoenix"], ["Trail Blazers", [3, 7], "Moda Center", "Portland"], ["Kings", [5, 14], "Golden 1 Center", "Sacramento"], ["Spurs", [28, 27], "Frost Bank Center", "San Antonio"], ["Raptors", [50, 7], "Scotiabank Arena", "Toronto"], ["Jazz", [14, 10], "Delta Center", "Utah"], ["Wizards", [52, 15], "Capital One Arena", "Washington"]]

NHL_TEAMS = [["Ducks", [5, 18], "Honda Center", "Anaheim"], ["Coyotes", [14, 10], "Delta Center", "Utah"], ["Bruins", [59, 10], "TD Garden", "Boston"], ["Sabres", [52, 10], "Keybank Center", "Buffalo"], ["Flames", [12, 0], "Saddledome", "Calgary"], ["Hurricanes", [48, 18], "PNC Arena", "Carolina"], ["Blackhawks", [37, 11], "United Center", "Chicago"], ["Avalanche", [19, 11], "Ball Arena", "Colorado"], ["Blue Jackets", [45, 14], "Nationwide Arena", "Columbus"], ["Stars", [30, 22], "American Airlines Arena", "Dallas"], ["Red Wings", [45, 10], "Little Ceasar's Arena", "Detroit"], ["Oilers", [14, 0], "Rogers Place", "Edmonton"], ["Panthers", [48, 30], "Amerant Bank Arena", "Florida"], ["Kings", [5, 18], "Crypto.com Center", "Los Angeles"], ["Wild", [34, 6], "Xcel Energy Center", "Minnesota"], ["Canadiens", [55, 5], "Bell Center", "Montreal"], ["Predators", [40, 17], "Bridgestone Arena", "Nashville"], ["Devils", [55, 12], "Prudential Center", "New Jersey"], ["Islanders", [57, 10], "UBS Arena", "New York "], ["Rangers", [56, 11], "Madison Square Garden", "New York"], ["Senators", [53, 6], "Canadian Tire Center", "Ottawa"], ["Flyers", [55, 13], "Wells Fargo Center", "Philadelphia"], ["Penguins", [50, 13], "PPG Paints Arena", "Pittsburgh"], ["Sharks", [3, 16], "SAP Center", "San Jose"], ["Kraken", [2, 3], "Climate Pledge Arena", "Seattle"], ["Blues", [36, 16], "Enterprise Center", "St Louis"], ["Lightning", [47, 28], "Amalie Arena", "Tampa Bay "], ["Maple Leafs", [50, 7], "ScotiaBank Arena", "Toronto"], ["Canucks", [1, 1], "Rogers Arena", "Vancouver"], ["Golden Knights", [10, 17], "T-Mobile Arena", "Vegas"], ["Capitals", [52, 15], "Capital One Arena", "Washington"], ["Jets", [32, 0], "Canada Life Center", "Winnipeg"]]

#Constants
MAP_OUTLINE_COLOR = "#1C8E61"
VISITED_PARKS = "#FFFF00"
UNVISITED_PARKS = "#FFFF00"
WIDTH = 64  # width

COORDINATE_X = 0  # x-position
COORDINATE_Y = 1  # y-position
HUE = 2  # hue
LIGHTNESS = 3  # lightness

def main(config):
    teams = MLB_TEAMS
    if config.get("type") == "mlb":
        teams = MLB_TEAMS
    elif config.get("type") == "nfl":
        teams = NFL_TEAMS
    elif config.get("type") == "nba":
        teams = NBA_TEAMS
    elif config.get("type") == "nhl":
        teams = NHL_TEAMS

    return map_locations(config, teams)

def deg_to_rad(num):
    return num * (math.pi / 180)

def rad_to_deg(num):
    return (180 * num) / math.pi

def mark_location_on_map(x, y, color, lightness = 35):
    hue, _, _ = hex_rgb_to_hsl(color)
    return [x, y, hue, lightness]

def hex_rgb_to_hsl(hex_color):
    # Convert hex red, green blue values to hue, saturation, lightness values
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    hsl = rgb_to_hsl(r, g, b)
    return hsl

def hsl_to_hex_rgb(h, s, l):
    # Convert hue, saturation, lightness values to hex red, green blue values
    red, green, blue = hsl_to_rgb(h, s, l)
    return ("#" + int_to_hex(red) + int_to_hex(green) + int_to_hex(blue))

def rgb_to_hsl(r, g, b):
    # Convert red, green blue integer values to hue, saturation, lightness values
    r /= 255.0
    g /= 255.0
    b /= 255.0

    max_color = max(r, g, b)
    min_color = min(r, g, b)

    # Calculate lightness
    lightness = (max_color + min_color) / 2.0

    if max_color == min_color:
        hue = 0
        saturation = 0
    else:
        delta = max_color - min_color

        # Calculate saturation
        if lightness < 0.5:
            saturation = delta / (max_color + min_color)
        else:
            saturation = delta / (2.0 - max_color - min_color)

        # Calculate hue
        if max_color == r:
            hue = (g - b) / delta
        elif max_color == g:
            hue = (b - r) / delta + 2
        else:
            hue = (r - g) / delta + 4
        hue *= 60
        hue = hue if hue > 0 else hue + 360

    return hue, saturation, lightness

def hsl_to_rgb(h, s, l):
    # Convert hue, saturation, lightness values to integer red, green blue values
    h = h % 360
    s = max(0, min(1, s))
    l = max(0, min(1, l))

    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = l - c / 2

    if h >= 0 and h < 60:
        r, g, b = c, x, 0
    elif h >= 60 and h < 120:
        r, g, b = x, c, 0
    elif h >= 120 and h < 180:
        r, g, b = 0, c, x
    elif h >= 180 and h < 240:
        r, g, b = 0, x, c
    elif h >= 240 and h < 300:
        r, g, b = x, 0, c
    else:
        r, g, b = c, 0, x

    r = int((r + m) * 255)
    g = int((g + m) * 255)
    b = int((b + m) * 255)

    return r, g, b

def int_to_hex(value):
    # Convert integer to hex string
    d = int(value / 16)
    r = value % 16
    p1 = str(d) if d < 10 else chr(55 + d)
    p2 = str(r) if r < 10 else chr(55 + r)
    hex_string = p1 + p2
    return hex_string

def generate_screen(array):
    arr = [["#000000" for i in range(WIDTH)] for j in range(32)]
    for list in array:
        if list[LIGHTNESS] > 0:
            arr[int(list[COORDINATE_Y])][int(list[COORDINATE_X])] = hsl_to_hex_rgb(list[HUE], 1., list[LIGHTNESS] / 100)
    return arr

def render_frame(frame):
    return render.Stack(
        children = [
            render.Column(
                children = [render_row(row) for row in frame],
            ),
        ],
    )

def render_row(row):
    return render.Row(children = [render_cell(cell) for cell in row])

def render_cell(cell):
    return render.Box(width = 1, height = 1, color = cell)

def renderAnimation(frames, league):
    #Weird Quick, league comes through as none, even though there is a default, and only for a second
    if league == None:
        league = ""

    return render.Root(
        render.Stack(
            children = [
                render.Animation(
                    children = frames,
                ),
                render.Padding(
                    pad = (0, 27, 0, 0),
                    child = render.Text("%s" % league, color = VISITED_PARKS, font = "CG-pixel-3x5-mono"),
                ),
            ],
        ),
        show_full_animation = True,
        delay = 120,
    )

def sort_ballParks(ballParks):
    random.seed(time.now().unix)
    randomSortMethod = random.number(0, 5)
    if randomSortMethod == 0:
        #print("sort by y")
        return sorted(ballParks, key = lambda x: x[1][1])
    elif randomSortMethod == 1:
        #print(sort by "team name")
        return sorted(ballParks, key = lambda x: x[0])
    elif randomSortMethod == 2:
        #print("sort by x")
        return sorted(ballParks, key = lambda x: x[1][0])
    elif randomSortMethod == 3:
        #print("sort by stadium name")
        return sorted(ballParks, key = lambda x: x[2])
    elif randomSortMethod == 4:
        #print("sort by Location")
        return sorted(ballParks, key = lambda x: x[3])
    else:
        #print("sort by x + y")
        return sorted(ballParks, key = lambda x: x[1][0] + x[1][0])

def sort_maps(coordinates):
    random.seed(time.now().unix)
    randomSortMethod = random.number(0, 6)
    if randomSortMethod == 0:
        #print("sort by x")
        return sorted(coordinates, key = lambda x: x[0])
    elif randomSortMethod == 1:
        #print("sort by y")
        return sorted(coordinates, key = lambda x: x[1])
    elif randomSortMethod == 2:
        #print("sort by x+y")
        return sorted(coordinates, key = lambda x: x[1] + x[0])
    elif randomSortMethod == 3:
        #print("sort by -x")
        return sorted(coordinates, key = lambda x: -x[0])
    elif randomSortMethod == 4:
        #print("sort by -y")
        return sorted(coordinates, key = lambda x: -x[1])
    elif randomSortMethod == 5:
        #print("sort by X * Random * y * Random ")
        return sorted(coordinates, key = lambda x: x[1] * random.number(0, 6) - x[0] * random.number(0, 6))
    else:
        #print("sort by -x -y")
        return sorted(coordinates, key = lambda x: -x[0] - x[1])

def map_locations(config, teams):
    my_locations = []
    all_locations = []
    frames = []
    shuffleTeams = []

    type = config.get("type")

    # add each team to the shuffleTeams for use when randomzing
    for team in teams:
        shuffleTeams.append(team)

    # pick a way to sort these teams at random
    # who wants to see the dots appear the same each time?
    shuffleTeams = sort_ballParks(shuffleTeams)

    fullmap = USAMAP
    fullmap = sort_maps(fullmap)

    dotCount = 0
    for dot in fullmap:
        dotCount = dotCount + 1

        x = dot[0]
        y = dot[1]

        # NHL has canadian teams, let's move the border by a pixel to accomodate
        if (type == "nhl"):
            if (x == 0):
                x = 1

        all_locations.append(mark_location_on_map(y, x, MAP_OUTLINE_COLOR, 70))
        my_locations.append(mark_location_on_map(y, x, MAP_OUTLINE_COLOR, 70))

        # display 10 dots at a time
        if dotCount % 10 == 0:
            frames.append(render_frame(generate_screen(my_locations)))

    #make sure the last few are rendered
    frames.append(render_frame(generate_screen(my_locations)))

    # add all parks as unvisited one at a time
    for randomTeam in shuffleTeams:
        all_locations.append(mark_location_on_map(randomTeam[1][0], randomTeam[1][1], UNVISITED_PARKS, 20))
        my_locations.append(mark_location_on_map(randomTeam[1][0], randomTeam[1][1], UNVISITED_PARKS, 20))
        frames.append(render_frame(generate_screen(all_locations)))

    # Now let's keep the last frame for awhile
    for _ in range(15):
        frames.append(render_frame(generate_screen(all_locations)))

    # Now add all visited parks
    for team in teams:
        if config.get("%s%s" % (type, team[0])) == "true":
            my_locations.append(mark_location_on_map(team[1][0], team[1][1], VISITED_PARKS, 75))
            frames.append(render_frame(generate_screen(my_locations)))

    # blink a couple times
    for _ in range(5):
        frames.append(render_frame(generate_screen(all_locations)))
        frames.append(render_frame(generate_screen(my_locations)))

    # Now let's keep the last frame for awhile
    for _ in range(25):
        frames.append(render_frame(generate_screen(my_locations)))

    # blink a couple times
    for _ in range(5):
        frames.append(render_frame(generate_screen(all_locations)))
        frames.append(render_frame(generate_screen(my_locations)))

    return renderAnimation(frames, type)

def get_teams(type):
    # default
    teams = sorted(MLB_TEAMS, key = lambda x: x[0])
    icon = "baseball"

    if type == "mlb":
        teams = sorted(MLB_TEAMS, key = lambda x: x[0])
        icon = "baseball"
    elif type == "nba":
        teams = sorted(NBA_TEAMS, key = lambda x: x[0])
        icon = "basketball"
    elif type == "nfl":
        teams = sorted(NFL_TEAMS, key = lambda x: x[0])
        icon = "football"
    elif type == "nhl":
        teams = sorted(NHL_TEAMS, key = lambda x: x[0])
        icon = "hockeyPuck"

    return [
        schema.Toggle(id = "%s%s" % (type, team[0]), name = team[0], desc = "%s" % team[2], icon = icon)
        for team in teams
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "type",
                name = "League",
                desc = "Which league to map?",
                icon = "globe",
                options = LEAGUE_OPTIONS,
                default = LEAGUE_OPTIONS[0].value,
            ),
            schema.Generated(
                id = "teamlist",
                source = "type",
                handler = get_teams,
            ),
        ],
    )
