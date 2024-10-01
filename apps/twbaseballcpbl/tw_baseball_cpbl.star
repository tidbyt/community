"""
Applet: CPBL Score
Summary: CPBL scores
Description: Shows baseball scores for the CPBL.
Author: Mark Chu
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

DEFAULT_TEAM_ID = "ACN011"
CACHE_TTL_SECONDS = 86400
GAME_INFO_CACHE_TTL_SECONDS = 120
GAME_DETAIL_CACHE_TTL_SECONDS = 120
GAME_INFO_URL = "https://en.cpbl.com.tw/home/getdetaillist"
GAME_DETAIL_URL = "https://en.cpbl.com.tw/box/getlive"
REQUEST_VERIFICATION_TOKEN_KEY = "AV6+xWcEb38Fuvn45zBGeaXER8+obOwGCyqs7cLDGYoOogOukLu8ChiRVIps8XAlxodTDZVzDjLk4k7uWXp4SNekQ3dDrwzSD8diFEydKDzS4wnikJOPDFyrrLqb6dN+r1STQFAqx6LC+uVnT9kmVC1dqHTUjfUuVpQCHTrlyEUB8feYcJ03MurXv1dmzLqp8mMkzwdZNqhzIEjfiwIdECIxQ+AfD6l6D9hmA4gXuVW2BxMr5Efu20xSMZTs/DjuCKg="

def main(config):
    request_verification_token = secret.decrypt(REQUEST_VERIFICATION_TOKEN_KEY) or config.get("dev_api_token")
    target_team_id = config.str("target_team_id", DEFAULT_TEAM_ID)
    game_info = get_game_info(request_verification_token)

    if game_info["GameADetailJson"] == None:
        fail("Can't get games")

    games = json.decode(game_info["GameADetailJson"])

    if len(games) == 0:
        return []

    game_info = [game for game in games if game["HomeTeamCode"] == target_team_id or game["VisitingTeamCode"] == target_team_id][0]

    child = None
    if game_info["GameStatus"] == 1 or game_info["GameStatus"] == 4:
        child = render_upcoming_game(game_info)
    elif game_info["GameStatus"] == 2 or game_info["GameStatus"] == 8:
        child = render_live_game(game_info)
    elif game_info["GameStatus"] == 3:
        game_details = get_game_detail(request_verification_token, game_info["GameSno"])
        game_scoreboards = json.decode(game_details["ScoreboardJson"])

        child = render_final_game(game_info, game_scoreboards)

    if child == None:
        return []

    return render.Root(
        child = child,
    )

def get_schema():
    options = [
        schema.Option(
            display = "CTBC Brothers",
            value = "ACN011",
        ),
        schema.Option(
            display = "Uni-President 7-ELEVEn Lions",
            value = "ADD011",
        ),
        schema.Option(
            display = "Rakuten Monkeys",
            value = "AJL011",
        ),
        schema.Option(
            display = "Fubon Guardians",
            value = "AEO011",
        ),
        schema.Option(
            display = "Wei Chuan Dragons",
            value = "AAA011",
        ),
        schema.Option(
            display = "TSG Hawks",
            value = "AKP011",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "target_team_id",
                name = "team",
                desc = "Team to track",
                icon = "baseball",
                default = options[0].value,
                options = options,
            ),
        ],
    )

def get_team_color(team_id):
    if team_id == "ACN011":
        return "#fccf00"
    if team_id == "ADD011":
        return "#e06c00"
    if team_id == "AJL011":
        return "#710f14"
    if team_id == "AEO011":
        return "#004B90"
    if team_id == "AAA011":
        return "#c1020e"
    if team_id == "AKP011":
        return "#08453a"

    return "#FFF"

def get_team_background(team_id):
    if team_id == "ACN011":
        return "#0b1b3d"
    if team_id == "ADD011":
        return "#8C4300"
    if team_id == "AJL011":
        return "#C45B60"
    if team_id == "AEO011":
        return "#025"
    if team_id == "AAA011":
        return "#403D3B"
    if team_id == "AKP011":
        return "#35796E"

    return "#FFF"

def get_team_short_name(team_id):
    if team_id == "ACN011":
        return "BRO"
    if team_id == "ADD011":
        return "UL"
    if team_id == "AJL011":
        return "RAK"
    if team_id == "AEO011":
        return "FBG"
    if team_id == "AAA011":
        return "WCD"
    if team_id == "AKP011":
        return "TSG"

    return ""

def get_team_logo_by_id(team_id):
    if team_id == "ACN011":
        return "https://www.cpbl.com.tw/files/atts/0L021497108709222204/logo_brothers.png"
    if team_id == "ADD011":
        return "https://www.cpbl.com.tw/files/atts/0L021496162893869773/logo_lions.png"
    if team_id == "AJL011":
        return "https://www.cpbl.com.tw/files/atts/0L015574823122453305/2024_CPBL%E5%85%AD%E9%9A%8ALogo_R2_%E5%AE%98%E7%B6%B2.png"
    if team_id == "AEO011":
        return "https://www.cpbl.com.tw/files/atts/0L021495969510091777/logo_fubon.png"
    if team_id == "AAA011":
        return "https://www.cpbl.com.tw/files/atts/0L021497845061333235/logo_dragon.png"
    if team_id == "AKP011":
        return "https://www.cpbl.com.tw/files/atts/0M259522048557486065/%E5%96%AE%E8%89%B2T-100x100.png"

    return ""

def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    return res.body()

def get_game_info(request_verification_token):
    form_body = {
        "__RequestVerificationToken": request_verification_token or "",
    }

    res = http.post(url = GAME_INFO_URL, form_body = form_body, ttl_seconds = GAME_INFO_CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (GAME_INFO_URL, res.status_code, res.body()))
    return res.json()

def get_game_detail(request_verification_token, game_id):
    now = time.now().in_location("Asia/Taipei")

    form_body = {
        "__RequestVerificationToken": request_verification_token or "",
        "GameSno": str(game_id),
        "Year": humanize.time_format("yyyy", now),
        "SelectKindCode": "A",
        "KindCode": "A",
    }

    res = http.post(url = GAME_DETAIL_URL, form_body = form_body, ttl_seconds = GAME_DETAIL_CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (GAME_DETAIL_URL, res.status_code, res.body()))
    return res.json()

def render_live_game(game_info):
    if game_info["CurtBatting"] == None:
        # set default value
        game_info["CurtBatting"] = {
            "FirstBase": "",
            "SecondBase": "",
            "ThirdBase": "",
            "VisitingHomeType": "1",
            "InningSeq": 1,
            "BallCnt": 0,
            "StrikeCnt": 0,
            "OutCnt": 0,
        }

    return (
        render.Row(
            children = [
                render.Column(
                    children = [
                        render.Stack(
                            children = [
                                render.Box(width = 32, height = 16, color = get_team_background(game_info["VisitingTeamCode"])),
                                render.Padding(
                                    pad = (1),
                                    child = render.Image(
                                        get_cachable_data(get_team_logo_by_id(game_info["VisitingTeamCode"])),
                                        width = 14,
                                        height = 14,
                                    ),
                                ),
                                render.Padding(
                                    pad = (18, 1, 0, 0),
                                    child = render.Text(get_team_short_name(game_info["VisitingTeamCode"]), font = "tom-thumb", color = get_team_color(game_info["VisitingTeamCode"])),
                                ),
                                render.Padding(
                                    pad = (18, 7, 0, 0),
                                    child = render.Text(str(game_info["VisitingTotalScore"] or 0), font = "tb-8"),
                                ),
                            ],
                        ),
                        render.Stack(
                            children = [
                                render.Box(width = 32, height = 16, color = get_team_background(game_info["HomeTeamCode"])),
                                render.Padding(
                                    pad = (1),
                                    child = render.Image(
                                        get_cachable_data(get_team_logo_by_id(game_info["HomeTeamCode"])),
                                        width = 14,
                                        height = 14,
                                    ),
                                ),
                                render.Padding(
                                    pad = (18, 1, 0, 0),
                                    child = render.Text(get_team_short_name(game_info["HomeTeamCode"]), font = "tom-thumb", color = get_team_color(game_info["HomeTeamCode"])),
                                ),
                                render.Padding(
                                    pad = (17, 7, 0, 0),
                                    child = render.Text(str(game_info["HomeTotalScore"] or 0), font = "tb-8", color = "#FFF"),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 48,
                        color = "#737270",
                    ),
                ),
                render.Column(
                    children = [
                        render.Padding(
                            pad = (2, -1, 0, 1),
                            child = render_base_chart(
                                first_base = game_info["CurtBatting"]["FirstBase"] != "",
                                second_base = game_info["CurtBatting"]["SecondBase"] != "",
                                third_base = game_info["CurtBatting"]["ThirdBase"] != "",
                            ),
                        ),
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Row(
                                main_align = "space_between",
                                cross_align = "center",
                                children = [
                                    render.Row(
                                        cross_align = "center",
                                        children = [
                                            render.Padding(
                                                pad = (0, 2, 0, 0),
                                                child = render_inning_symbol(game_info["CurtBatting"]["VisitingHomeType"] == "1"),
                                            ),
                                            render.Padding(
                                                pad = (1, 0, 0, 0),
                                                child = render.Text(str(game_info["CurtBatting"]["InningSeq"])),
                                            ),
                                        ],
                                    ),
                                    render.Padding(
                                        pad = (3, 0, 0, 0),
                                        child = render.Column(
                                            children = [
                                                render.Text(
                                                    str(game_info["CurtBatting"]["BallCnt"]) + "-" + str(game_info["CurtBatting"]["StrikeCnt"]),
                                                    font = "CG-pixel-4x5-mono",
                                                ),
                                                render.Row(
                                                    children = [
                                                        render_out_symbol(game_info["CurtBatting"]["OutCnt"] > 0),
                                                        render_out_symbol(game_info["CurtBatting"]["OutCnt"] > 1),
                                                    ],
                                                ),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        )
    )

def render_final_game(game_info, scoreboards):
    visiting_total_hits = calc_total_count(scoreboards, "HittingCnt", game_info["VisitingTeamCode"])
    home_total_hits = calc_total_count(scoreboards, "HittingCnt", game_info["HomeTeamCode"])
    visiting_total_errors = calc_total_count(scoreboards, "ErrorCnt", game_info["VisitingTeamCode"])
    home_total_errors = calc_total_count(scoreboards, "ErrorCnt", game_info["HomeTeamCode"])

    return (
        render.Row(
            children = [
                render.Column(
                    children = [
                        render.Stack(
                            children = [
                                render.Box(width = 32, height = 16, color = get_team_background(game_info["VisitingTeamCode"])),
                                render.Padding(
                                    pad = (1),
                                    child = render.Image(
                                        get_cachable_data(get_team_logo_by_id(game_info["VisitingTeamCode"])),
                                        width = 14,
                                        height = 14,
                                    ),
                                ),
                                render.Padding(
                                    pad = (18, 1, 0, 0),
                                    child = render.Text(get_team_short_name(game_info["VisitingTeamCode"]), font = "tom-thumb", color = get_team_color(game_info["VisitingTeamCode"])),
                                ),
                                render.Padding(
                                    pad = (18, 7, 0, 0),
                                    child = render.Text(str(game_info["VisitingTotalScore"]), font = "tb-8"),
                                ),
                            ],
                        ),
                        render.Stack(
                            children = [
                                render.Box(width = 32, height = 16, color = get_team_background(game_info["HomeTeamCode"])),
                                render.Padding(
                                    pad = (1),
                                    child = render.Image(
                                        get_cachable_data(get_team_logo_by_id(game_info["HomeTeamCode"])),
                                        width = 14,
                                        height = 14,
                                    ),
                                ),
                                render.Padding(
                                    pad = (18, 1, 0, 0),
                                    child = render.Text(get_team_short_name(game_info["HomeTeamCode"]), font = "tom-thumb", color = get_team_color(game_info["HomeTeamCode"])),
                                ),
                                render.Padding(
                                    pad = (17, 7, 0, 0),
                                    child = render.Text(str(game_info["HomeTotalScore"]), font = "tb-8", color = "FFF"),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 48,
                        color = "#737270",
                    ),
                ),
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Text("FIN", color = "#088387"),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Column(
                                    expanded = True,
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        render.Text("H", color = "#737270"),
                                        render.Box(
                                            width = 9,
                                            height = 1,
                                            color = "#737270",
                                        ),
                                        render.Padding(
                                            pad = (0, 1, 0, 0),
                                            child = render.Text(str(visiting_total_hits), font = "CG-pixel-4x5-mono"),
                                        ),
                                        render.Padding(
                                            pad = (0, 1, 0, 0),
                                            child = render.Text(str(home_total_hits), font = "CG-pixel-4x5-mono"),
                                        ),
                                    ],
                                ),
                                render.Column(
                                    expanded = True,
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        render.Text("E", color = "#737270"),
                                        render.Box(
                                            width = 9,
                                            height = 1,
                                            color = "#737270",
                                        ),
                                        render.Padding(
                                            pad = (0, 1, 0, 0),
                                            child = render.Text(str(visiting_total_errors), font = "CG-pixel-4x5-mono"),
                                        ),
                                        render.Padding(
                                            pad = (0, 1, 0, 0),
                                            child = render.Text(str(home_total_errors), font = "CG-pixel-4x5-mono"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )
    )

def calc_total_count(scoreboards, key, team_id):
    if scoreboards == None:
        return 0

    total = 0
    for scoreboard in scoreboards:
        if scoreboard["TeamNo"] == team_id:
            total += scoreboard[key]

    return int(total)

def render_out_symbol(out = True):
    out_color = "#d02537" if out else "#000"

    return (
        render.Padding(
            pad = (1),
            child = render.Circle(
                color = "#FFF",
                diameter = 4,
                child = render.Circle(color = out_color, diameter = 2),
            ),
        )
    )

def render_inning_symbol(first_half = True):
    container = []
    width = 5

    start = 0
    end = 3
    step_size = 1

    if first_half == False:
        start = 2
        end = -1
        step_size = -1

    for row in range(start, end, step_size):
        children = []

        color_boxies = 2 * row + 1
        spaces = (width - color_boxies) // 2

        for _ in range(spaces):
            children.append(render.Box(
                width = 1,
                height = 1,
                color = "#000",
            ))

        for _ in range(color_boxies):
            children.append(render.Box(
                width = 1,
                height = 1,
                color = "#088387",
            ))

        container.append(render.Row(
            children = children,
        ))

    return (
        render.Column(
            children = container,
        )
    )

def render_base_chart(first_base = False, second_base = False, third_base = False):
    return (
        render.Stack(
            children = [
                # second base
                render.Padding(
                    pad = (6, 0, 0, 0),
                    child = render_base(second_base),
                ),
                # third base
                render.Padding(
                    pad = (0, 7, 0, 0),
                    child = render_base(third_base),
                ),
                # first base
                render.Padding(
                    pad = (12, 7, 0, 0),
                    child = render_base(first_base),
                ),
            ],
        )
    )

def render_base(on_base = False):
    size = 9
    center = size // 2

    on_base_color = "#ded012" if on_base else "#000"

    container = []
    for row in range(size):
        children = []

        for col in range(size):
            if abs(center - row) + abs(center - col) == center:
                children.append(
                    render.Box(
                        width = 1,
                        height = 1,
                        color = "#fff",
                    ),
                )
            elif abs(center - row) + abs(center - col) < center:
                children.append(
                    render.Box(
                        width = 1,
                        height = 1,
                        color = on_base_color,
                    ),
                )
            else:
                children.append(
                    render.Box(
                        width = 1,
                        height = 1,
                        color = "#0000",
                    ),
                )

        container.append(
            render.Row(
                children = children,
            ),
        )

    return (
        render.Box(
            width = 14,
            height = 14,
            child = render.Column(
                children = container,
            ),
        )
    )

def render_upcoming_game(game_info):
    stadium_string = get_stadium_name(game_info)
    starting_pitcher_string = "   SP: " + game_info["VisitingFirstMover"] + ", " + game_info["HomeFirstMover"]

    return (
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Stack(
                                    children = [
                                        render.Box(width = 23, height = 24, color = "#333"),
                                        render.Padding(
                                            pad = (0, 6, 0, 0),
                                            child = render.Column(
                                                main_align = "center",
                                                cross_align = "center",
                                                children = [
                                                    render.Text("START", font = "tom-thumb", color = "#777"),
                                                    render.Text(game_info["PreExeDate"][11:16], font = "tb-8"),
                                                ],
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Box(
                                width = 1,
                                height = 24,
                                color = "#737270",
                            ),
                        ),
                        render.Column(
                            children = [
                                render.Stack(
                                    children = [
                                        render.Box(width = 20, height = 24, color = get_team_background(game_info["VisitingTeamCode"])),
                                        render.Padding(
                                            pad = (3, 5, 3, 5),
                                            child = render.Image(
                                                get_cachable_data(get_team_logo_by_id(game_info["VisitingTeamCode"])),
                                                width = 14,
                                                height = 14,
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Column(
                            children = [
                                render.Stack(
                                    children = [
                                        render.Box(width = 20, height = 24, color = get_team_background(game_info["HomeTeamCode"])),
                                        render.Padding(
                                            pad = (3, 5, 3, 5),
                                            child = render.Image(
                                                get_cachable_data(get_team_logo_by_id(game_info["HomeTeamCode"])),
                                                width = 14,
                                                height = 14,
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Stack(
                            children = [
                                render.Box(height = 12, color = "#3d0108"),
                                render.Marquee(
                                    width = 64,
                                    child = render.Text(stadium_string + starting_pitcher_string),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )
    )

def get_stadium_name(game_info):
    if game_info["FieldAbbe"] == "INT":
        return "Intercontinental"
    if game_info["FieldAbbe"] == "TNN":
        return "Tainan"
    if game_info["FieldAbbe"] == "TYN":
        return "Taoyuan"
    if game_info["FieldAbbe"] == "XZG":
        return "Xinzhuang"
    if game_info["FieldAbbe"] == "HLN":
        return "Hualien"
    if game_info["FieldAbbe"] == "CCL":
        return "Cheng Ching Lake"
    if game_info["FieldAbbe"] == "DLU":
        return "Douliu"
    if game_info["FieldAbbe"] == "TMU":
        return "Tienmu"
    if game_info["FieldAbbe"] == "CYI":
        return "Chiayi"
    if game_info["FieldAbbe"] == "CYC":
        return "Chiayi City"
    if game_info["FieldAbbe"] == "HCU":
        return "Hsinchu"
    if game_info["FieldAbbe"] == "PTG":
        return "Pingtung"
    if game_info["FieldAbbe"] == "TCG":
        return "Taichung"
    if game_info["FieldAbbe"] == "TTG":
        return "Taitung"
    if game_info["FieldAbbe"] == "KLD":
        return "Kaohsiung Li De"
    if game_info["FieldAbbe"] == "CTP":
        return "CTBC Park"
    if game_info["FieldAbbe"] == "LDG":
        return "Loudong"
    if game_info["FieldAbbe"] == "TPE":
        return "Taipei"
    if game_info["FieldAbbe"] == "TPD":
        return "Taipei Dome"

    return ""
