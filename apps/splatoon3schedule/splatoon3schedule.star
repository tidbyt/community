"""
Applet: Splatoon3Schedule
Summary: Splatoon 3 Schedules
Description: Displays Splatoon 3 schedule info, data courtesy of Splatoon3.ink.
Author: Denton-L
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_URL = "https://splatoon3.ink/data/schedules.json"
TTL_SECONDS = 3600

ICON_HEIGHT = 16

WIDTH = 64

MAX_AGE = 60

def get_vs_rule_name(setting):
    return setting["vsRule"]["name"]

def get_vs_stages(setting):
    return setting["vsStages"]

def make_anarchy_battle_mode(bankara_mode):
    def get_bankara_match_setting(settings):
        for setting in settings:
            if setting["bankaraMode"] == bankara_mode:
                return setting
        return None

    return struct(
        nodes_accessor = lambda x: x["bankaraSchedules"],
        setting_key = "bankaraMatchSettings",
        is_splatfest = False,
        title_color = "#F54910",
        subtitle_generator = lambda x: get_vs_rule_name(get_bankara_match_setting(x)),
        images_accessor = lambda x: get_vs_stages(get_bankara_match_setting(x)),
    )

def make_challenge_mode():
    def nodes_accessor(data):
        return {
            "nodes": [
                node | {
                    "startTime": time_period["startTime"],
                    "endTime": time_period["endTime"],
                }
                for node in data["eventSchedules"]["nodes"]
                for time_period in node["timePeriods"]
            ],
        }

    return struct(
        nodes_accessor = nodes_accessor,
        setting_key = "leagueMatchSetting",
        is_splatfest = False,
        title_color = "#EA4074",
        subtitle_generator = lambda x: x["leagueMatchEvent"]["name"],
        images_accessor = get_vs_stages,
    )

def make_salmon_run_mode(schedule_key, title_color):
    return struct(
        nodes_accessor = lambda x: x["coopGroupingSchedule"][schedule_key],
        setting_key = "setting",
        is_splatfest = False,
        title_color = title_color,
        subtitle_color_map = {},
        # TODO: how will the boss object be defined for Eggstra Work?
        subtitle_generator = lambda x: "%s (%s)" % (x["coopStage"]["name"], x["boss"]["name"]),
        images_accessor = lambda x: x["weapons"],
    )

def make_splatfest_mode(fest_mode):
    def get_fest_match_setting(settings):
        for setting in settings:
            if setting["festMode"] == fest_mode:
                return setting
        return None

    return struct(
        nodes_accessor = lambda x: x["festSchedules"],
        setting_key = "festMatchSettings",
        is_splatfest = True,
        title_color = None,
        subtitle_generator = None,
        images_accessor = lambda x: get_vs_stages(get_fest_match_setting(x)),
    )

def make_tricolor_turf_war():
    def nodes_accessor(data):
        current_fest = data["currentFest"]
        return {
            "nodes": [
                {
                    "startTime": current_fest["midtermTime"],
                    "endTime": current_fest["endTime"],
                    "setting": {
                        "tricolorStage": [current_fest["tricolorStage"]],
                    },
                },
            ] if current_fest else [],
        }

    return struct(
        nodes_accessor = nodes_accessor,
        setting_key = "setting",
        is_splatfest = True,
        title_color = None,
        subtitle_generator = None,
        images_accessor = lambda x: x["tricolorStage"],
    )

MODES = {
    "Regular Battle": struct(
        nodes_accessor = lambda x: x["regularSchedules"],
        setting_key = "regularMatchSetting",
        is_splatfest = False,
        title_color = "#CFF622",
        subtitle_generator = get_vs_rule_name,
        images_accessor = get_vs_stages,
    ),
    "Anarchy Battle (Series)": make_anarchy_battle_mode("CHALLENGE"),
    "Anarchy Battle (Open)": make_anarchy_battle_mode("OPEN"),
    "X Battle": struct(
        nodes_accessor = lambda x: x["xSchedules"],
        setting_key = "xMatchSetting",
        is_splatfest = False,
        title_color = "#0FDB9B",
        subtitle_generator = get_vs_rule_name,
        images_accessor = get_vs_stages,
    ),
    "Challenge": make_challenge_mode(),
    "Salmon Run": make_salmon_run_mode("regularSchedules", "#FF5033"),
    "Splatfest Battle (Open)": make_splatfest_mode("REGULAR"),
    "Splatfest Battle (Pro)": make_splatfest_mode("CHALLENGE"),
    "Tricolor Turf War": make_tricolor_turf_war(),
    "Big Run": make_salmon_run_mode("bigRunSchedules", "#B322FF"),
    "Eggstra Work": make_salmon_run_mode("teamContestSchedules", "#E4A500"),
}

def find_setting(data, mode):
    now = time.now()
    nodes = mode.nodes_accessor(data)["nodes"]
    for node in nodes:
        if time.parse_time(node["startTime"]) <= now and now < time.parse_time(node["endTime"]):
            return node[mode.setting_key]
    return None

def fetch_image(url):
    res = http.get(url, ttl_seconds = TTL_SECONDS)
    if res.status_code != 200:
        return None
    return res.body()

def render_splatfest(current_fest, mode_name):
    def color_to_rgb(color):
        def zero_pad(s, width):
            return "0" * (width - len(s)) + s

        return "#" + "".join([zero_pad("%X" % int(color[c] * 255), 2) for c in ("r", "g", "b")])

    return (
        render.Row([
            render.Text(mode_name_word + " ", color = color_to_rgb(team["color"]))
            for mode_name_word, team in zip(mode_name.split(" "), current_fest["teams"])
        ]),
        render.Text(current_fest["title"]),
    )

def main(config):
    mode_name = config.get("mode", MODES.keys()[0])
    mode = MODES[mode_name]

    res = http.get(API_URL, ttl_seconds = TTL_SECONDS)
    if res.status_code != 200:
        return []
    data = res.json()["data"]

    setting = find_setting(data, mode)
    if not setting:
        return []

    image_urls = [image["image"]["url"] for image in mode.images_accessor(setting)]
    images = [fetch_image(image_url) for image_url in image_urls]
    image_renders = [render.Image(image, height = ICON_HEIGHT) for image in images if image]

    if mode.is_splatfest:
        first_row, second_row = render_splatfest(data["currentFest"], mode_name)
    else:
        first_row = render.Text(mode_name, color = mode.title_color)
        second_row = render.Text(mode.subtitle_generator(setting))

    return render.Root(
        render.Column([
            render.Marquee(first_row, width = WIDTH),
            render.Marquee(second_row, width = WIDTH),
            render.Row(image_renders, main_align = "space_between", cross_align = "center"),
        ], main_align = "space_between", cross_align = "center"),
        max_age = MAX_AGE,
    )

def get_schema():
    mode_options = [
        schema.Option(
            display = name,
            value = name,
        )
        for name in MODES.keys()
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "mode",
                name = "Mode",
                desc = "The game mode to display. If the mode is not active, this app will be skipped.",
                icon = "gamepad",
                default = mode_options[0].value,
                options = mode_options,
            ),
        ],
    )
