"""
Applet: HRBFC
Summary: H&R Beavers' Live Scores
Description: Live scores and upcoming match details for the Hampton and Richmond Borough Football Club. Go Beavers!
Author: Jonathan Damico
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
	"lat": "51.41514071311692,",
	"lng": "-0.3631541244389484",
	"description": "Hampton & Richmond Borough Football Club Ground (Beveree Stadium)",
	"locality": "Hampton",
	"place_id": "ChIJq4On8EULdkgRYjjDaPfI-SQ",
	"timezone": "Europe/London"
}
"""

HRBFC_TEAM_ID = "4680"

BASE_API_URL = "https://26vyvv1b53.execute-api.us-east-1.amazonaws.com"
GAME_DATA_PATH = BASE_API_URL + "/getCurrentOrNextGame"
TEAM_NAMES_PATH = BASE_API_URL + "/getTeamNames"

BACKGROUND_IMAGE_URL = "https://hrbfc-png.s3.amazonaws.com/hrbfc-new-darken.png"

FONT = "tb-8"

GAME_STATUSES = {
    "TBD": ("TBD", "Time To Be Defined"),
    "NS": ("Not Started", "Not Started"),
    "1H": ("First Half", "First Half, Kick Off"),
    "HT": ("Halftime", "Halftime"),
    "2H": ("Second Half", "Second Half, 2nd Half Started"),
    "ET": ("Extra Time", "Extra Time"),
    "BT": ("Break Time", "Break Time"),
    "P": ("Penalty", "Penalty In Progress"),
    "SUSP": ("Suspended", "Match Suspended"),
    "INT": ("Interrupted", "Match Interrupted"),
    "FT": ("Full Time", "Match Finished"),
    "AET": ("Full Time", "Match Finished After Extra Time"),
    "PEN": ("Full Time", "Match Finished After Penalty"),
    "PST": ("Postponed", "Match Postponed"),
    "CANC": ("Cancelled", "Match Cancelled"),
    "ABD": ("Abandoned", "Match Abandoned"),
    "AWD": ("Tech Loss", "Technical Loss"),
    "WO": ("WalkOver", "WalkOver"),
    "LIVE": ("In Progress", "In Progress"),
}

def countdown_string(timeIn):
    duration = timeIn - time.now()

    days = math.floor(duration.hours / 24)
    hours = math.floor(duration.hours - days * 24)
    minutes = math.floor(duration.minutes - (days * 24 * 60 + hours * 60))
    if (days > 0):
        return str(days) + "d " + str(hours) + "h"
    elif (hours > 0):
        return str(hours) + "h " + str(minutes) + "m"
    else:
        return str(minutes) + "m"

def get_current_or_next_game_data():
    response = http.get(GAME_DATA_PATH, ttl_seconds = 55).json()

    print("Fetched new data")

    return response["message"]

def get_team_names_data():
    response = http.get(TEAM_NAMES_PATH, ttl_seconds = 600000).json()

    print("Fetched team names")

    team_data = response["message"]

    team_data[HRBFC_TEAM_ID] = {
        "long": "Beavers",
        "short": "HRB",
    }

    return team_data

def get_background_image_data():
    return http.get(BACKGROUND_IMAGE_URL, ttl_seconds = 600000).body()

def get_short_team_name(team_names, team_id, is_home):
    name = team_names[str(int(team_id))]["short"]

    if name == None:
        name = team_names[str(int(team_id))]["long"]

        if name == None:
            if is_home:
                name = "HOME"
            else:
                name = "AWAY"

        else:
            name = name[:3]

    return name.upper()

def get_long_team_name(team_names, team_id, is_home):
    name = team_names[str(int(team_id))]["long"]

    if name == None:
        if is_home:
            name = "Home"
        else:
            name = "Away"

    return name

def get_short_game_status(status):
    status_tuple = GAME_STATUSES[status]

    if status_tuple == None:
        return "UNK"
    else:
        return status_tuple[0]

def get_long_game_status(status):
    status_tuple = GAME_STATUSES[status]

    if status_tuple == None:
        return "Unknown"
    else:
        return status_tuple[1]

def main(config):
    location = config.str("location", DEFAULT_LOCATION)

    game_data = get_current_or_next_game_data()

    team_names = get_team_names_data()

    background_image = get_background_image_data()

    if game_data == None or team_names == None or background_image == None:
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Text(
                                    "Go Beavers!",
                                    font = FONT,
                                ),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.WrappedText(
                                    "Failed to fetch data",
                                    font = FONT,
                                    align = "center",
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        )

    elif game_data["fixture"]["status"]["short"] in ["NS", "CANC", "ABD", "AWD"]:
        return render.Root(
            child = render.Stack(
                children = [
                    render.Box(
                        render.Column(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Image(
                                            src = background_image,
                                            height = 35,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Box(
                        render.Column(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(
                                            get_short_game_status(game_data["fixture"]["status"]["short"]),
                                            font = FONT,
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(get_long_team_name(team_names, game_data["teams"]["home"]["id"], True), font = FONT),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(get_long_team_name(team_names, game_data["teams"]["away"]["id"], False), font = FONT),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(time.parse_time(game_data["fixture"]["date"]).in_location(
                                            location["timezone"],
                                        ).format("2 Jan 15:04"), font = FONT),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )

    else:
        return render.Root(
            child = render.Stack(
                children = [
                    render.Box(
                        render.Column(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Image(
                                            src = background_image,
                                            height = 35,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Box(
                        render.Column(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(
                                            get_short_game_status(game_data["fixture"]["status"]["short"]),
                                            font = FONT,
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(
                                            get_short_team_name(team_names, game_data["teams"]["home"]["id"], True),
                                            font = FONT,
                                        ),
                                        render.Text(
                                            get_short_team_name(team_names, game_data["teams"]["away"]["id"], False),
                                            font = FONT,
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(
                                            str(int(game_data["goals"]["home"])),
                                            font = FONT,
                                        ),
                                        render.Text(
                                            str(int(game_data["goals"]["away"])),
                                            font = FONT,
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(
                                            str(int(game_data["fixture"]["status"]["elapsed"])) + "'",
                                            font = FONT,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display game times.",
                icon = "locationDot",
            ),
        ],
    )
