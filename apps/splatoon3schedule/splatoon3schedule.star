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

def make_anarchy_battle_mode(bankara_mode):
    def get_bankara_match_setting(node):
        for setting in node["bankaraMatchSettings"]:
            if setting["bankaraMode"] == bankara_mode:
                return setting
        return None

    return struct(
        nodes_accessor = lambda x: x["bankaraSchedules"],
        title_color = "#F54910",
        subtitle_generator = lambda x: get_bankara_match_setting(x)["vsRule"]["name"],
        images_accessor = lambda x: get_bankara_match_setting(x)["vsStages"],
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
        title_color = "#EA4074",
        subtitle_generator = lambda x: x["leagueMatchSetting"]["leagueMatchEvent"]["name"],
        images_accessor = lambda x: x["leagueMatchSetting"]["vsStages"],
    )

MODES = {
    "Regular Battle": struct(
        nodes_accessor = lambda x: x["regularSchedules"],
        title_color = "#CFF622",
        subtitle_generator = lambda x: x["regularMatchSetting"]["vsRule"]["name"],
        images_accessor = lambda x: x["regularMatchSetting"]["vsStages"],
    ),
    "Anarchy Battle (Series)": make_anarchy_battle_mode("CHALLENGE"),
    "Anarchy Battle (Open)": make_anarchy_battle_mode("OPEN"),
    "X Battle": struct(
        nodes_accessor = lambda x: x["xSchedules"],
        title_color = "#0FDB9B",
        subtitle_generator = lambda x: x["xMatchSetting"]["vsRule"]["name"],
        images_accessor = lambda x: x["xMatchSetting"]["vsStages"],
    ),
    "Challenge": make_challenge_mode(),
    "Salmon Run": struct(
        nodes_accessor = lambda x: x["coopGroupingSchedule"]["regularSchedules"],
        title_color = "#FF5033",
        subtitle_color_map = {},
        subtitle_generator = lambda x: "%s (%s)" % (x["setting"]["coopStage"]["name"], x["setting"]["boss"]["name"]),
        images_accessor = lambda x: x["setting"]["weapons"],
    ),
}

def find_node(data, mode):
    now = time.now()
    nodes = mode.nodes_accessor(data["data"])["nodes"]
    for node in nodes:
        if time.parse_time(node["startTime"]) <= now and now <= time.parse_time(node["endTime"]):
            return node
    return None

def fetch_image(url):
    res = http.get(url, ttl_seconds = TTL_SECONDS)
    if res.status_code != 200:
        return None
    return res.body()

def main(config):
    mode_name = config.get("mode", MODES.keys()[0])
    mode = MODES[mode_name]

    res = http.get(API_URL, ttl_seconds = TTL_SECONDS)
    if res.status_code != 200:
        return []
    data = res.json()

    node = find_node(data, mode)
    if not node:
        return []

    image_urls = [image["image"]["url"] for image in mode.images_accessor(node)]
    images = [fetch_image(image_url) for image_url in image_urls]
    image_renders = [render.Image(image, height = ICON_HEIGHT) for image in images if image]

    return render.Root(
        render.Column([
            render.Marquee(render.Text(mode_name, color = mode.title_color), width = WIDTH),
            render.Marquee(render.Text(mode.subtitle_generator(node), color = "#FFFFFF"), width = WIDTH),
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
