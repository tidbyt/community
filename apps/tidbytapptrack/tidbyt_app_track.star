"""
Applet: Tidbyt App Track
Summary: Track apps on Tidbyt
Description: Track the Tidbyt app page and see new listings.
Author: UnBurn
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

API_URI = "https://api.tidbyt.com/v0"

ONE_DAY = 86400
TWELVE_HOURS = 43200

COL_1_WIDTH = 15
COL_2_WIDTH = 64 - COL_1_WIDTH

NEW_APPS_CACHE_KEY = "NEW_APPS_CACHE_KEY"
NEW_APPS_CACHE_TTL = ONE_DAY * 2

KNOWN_APPS_CACHE_KEY = "KNOWN_APPS_CACHE_KEY"
KNOWN_APPS_CACHE_TTL = ONE_DAY * 30

TEAL_COLOR = "#78DECC"
PINK_COLOR = "#FFB4F5"
PURPLE_COLOR = "#7E8AF8"

TIDBYT_LOGO = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAYAAAAICAYAAADaxo44AAAANElEQVQIW2Msv3f6PwMS6LimBeYx4pSAKa7r+gHW2VTGwQjWQb7Eg/X/wEYpBDKhGkW0BACjNCFX+QeJOwAAAABJRU5ErkJggg==")

fake_data = [
    {
        "id": "invalid-api-key",
        "name": "Invalid API Key",
        "description": "Your API key is not valid. Please try again!",
        "private": False,
        "organizationID": "",
        "version": "a476ac314b231c3bf520e3ca91e30f0d9ea7d0d5",
        "developer": "UnBurn",
    },
    {
        "id": "chesscom-elo",
        "name": "Chess.com ELO",
        "description": "Track your ELO from Chess.com from a variety of game types.",
        "private": False,
        "organizationID": "",
        "version": "8bc0d4454a6da80a67a85354ec24db2cd0bc9c32",
        "developer": "UnBurn",
    },
    {
        "id": "wiki-page-today",
        "name": "Wiki Page Today",
        "description": "Display Wikipedia's Featured Article of the Day in a Tidbyt format.",
        "private": False,
        "organizationID": "",
        "version": "d47a248c1b679fcc40352342adac075cd315a65e",
        "developer": "UnBurn",
    },
    {
        "id": "retro-game-goals",
        "name": "Retro Game Goals",
        "description": "Display RetroAchievements for a random game on a random console.",
        "private": False,
        "organizationID": "",
        "version": "8bc0d4454a6da80a67a85354ec24db2cd0bc9c32",
        "developer": "UnBurn",
    },
]

def get_apps(api_key):
    endpoint = "%s/apps" % (API_URI)
    response = http.get(endpoint, headers = {"Authorization": "Bearer %s" % api_key}, ttl_seconds = TWELVE_HOURS)
    if response.status_code != 200:
        return fake_data

    response_json = response.json()
    if "apps" not in response_json:
        return fake_data
    return response_json["apps"]

def shorten_description(extract):
    MAX_LENGTH = 75

    sentences = extract.split(".")
    ret = sentences[0] + "."
    if len(ret) > MAX_LENGTH + 3:
        return ret[:MAX_LENGTH - 3] + "..."
    for s in sentences[1:]:
        new_sentence = ret + s + "."
        if s != "" and len(new_sentence) <= MAX_LENGTH:
            ret = new_sentence
        else:
            break
    return ret

def render_n_random_apps(apps, n):
    renderable_apps = [app for app in apps]
    ret = []
    for _ in range(n):
        new_number = random.number(0, len(renderable_apps) - 1)
        app = renderable_apps[new_number]
        new_render = render_app_info(app)
        ret.append(new_render)
        renderable_apps.remove(app)
    return ret

def render_app_info(app):
    name = app["name"]
    description = shorten_description(app["description"])
    return render.Padding(render.Column(
        children = [
            render.WrappedText(name, font = "tom-thumb", color = TEAL_COLOR, width = COL_2_WIDTH - 3),
            render.WrappedText(description, font = "tom-thumb", color = PINK_COLOR, width = COL_2_WIDTH - 3),
        ],
    ), pad = (0, 0, 0, 1))

def get_new_apps(apps):
    new_apps = cache.get(NEW_APPS_CACHE_KEY)
    known_apps = cache.get(KNOWN_APPS_CACHE_KEY)

    if new_apps == None:
        new_apps = "[]"
    new_apps = json.decode(new_apps)

    if known_apps == None:
        known_apps = "[]"
    known_apps = json.decode(known_apps)

    hashed_known_apps = {}
    for app in known_apps:
        hashed_known_apps[app["id"]] = app

    hashed_new_apps = {}
    for app in new_apps:
        hashed_new_apps[app["id"]] = app

    unkwown_apps = [app for app in apps if app["id"] not in hashed_known_apps]
    total_new_apps = new_apps + [app for app in unkwown_apps if app["id"] not in hashed_new_apps]

    if len(total_new_apps) >= len(apps):
        total_new_apps = []

    if len(total_new_apps) > len(new_apps):
        cache.set(NEW_APPS_CACHE_KEY, json.encode(total_new_apps), ttl_seconds = NEW_APPS_CACHE_TTL)
    return total_new_apps

def update_known_apps(apps):
    cache.set(KNOWN_APPS_CACHE_KEY, json.encode(apps), ttl_seconds = KNOWN_APPS_CACHE_TTL)

def main(config):
    api_key = config.get("api_key")
    new_apps_first = config.bool("new_apps_first")
    apps = get_apps(api_key)

    new_apps = get_new_apps(apps)
    apps_count = len(apps)
    new_apps_count = len(new_apps)

    update_known_apps(apps)

    header = render.Stack(
        children = [
            render.Box(width = COL_1_WIDTH, height = 32, color = "#000000"),
            render.Column(
                children = [
                    render.Image(src = TIDBYT_LOGO, height = 8, width = 6),
                    render.WrappedText(content = "apps", font = "tom-thumb", width = COL_1_WIDTH),
                    render.WrappedText(content = "%s" % apps_count, font = "tom-thumb", width = COL_1_WIDTH, color = TEAL_COLOR),
                    render.WrappedText(content = "new", font = "tom-thumb", width = COL_1_WIDTH),
                    render.WrappedText(content = "%s" % new_apps_count, font = "tom-thumb", width = COL_1_WIDTH, color = TEAL_COLOR),
                ],
            ),
        ],
    )
    rendered_children = []
    if new_apps_first:
        rendered_children += render_n_random_apps(new_apps, len(new_apps))

    rendered_children += render_n_random_apps(apps, len(apps))

    body = render.Marquee(
        width = 44,
        height = 128,
        offset_start = 8,
        scroll_direction = "vertical",
        child = render.Column(
            children = rendered_children,
        ),
    )

    line = render.Padding(render.Box(
        width = 1,
        height = 32,
        color = PURPLE_COLOR,
    ), pad = (1, 0, 1, 0))

    return render.Root(
        delay = 1,
        child = render.Row(
            children = [header, line, body],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Tidbyt API key",
                desc = "Found in Settings > General > Get API Key",
                icon = "key",
            ),
            schema.Toggle(
                id = "new_apps_first",
                name = "New apps first",
                desc = "Display new apps at the top of the list",
                icon = "seedling",
                default = False,
            ),
        ],
    )
