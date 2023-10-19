load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

# https://www.base64encoder.io/image-to-base64-converter/
LOGO = base64.decode("""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""")

TWELVE_HOURS = 43200

# This is used whenever an error or invalid data appears.
EMPTY_DATA = {
    "total_games": "0 gs",
    "win_percent": "0% wr",
    "total_time": "0 hrs",
}

def winning_team(replay):
    """Returns which team won."""
    orange = replay["orange"].get("goals", 0)
    blue = replay["blue"].get("goals", 0)

    return "orange" if orange > blue else "blue"

def which_team(replay, name):
    """Return which team the uploader was on."""
    for team in ["orange", "blue"]:
        players = replay[team]["players"]
        for p in players:
            if p["name"] == name:
                return team
    return None

def win_percentage(replays, name):
    wins = 0
    total = 0
    for replay in replays["list"]:
        winner = winning_team(replay)
        color = which_team(replay, name)
        if color == None:
            continue
        total += 1

        if winner == color:
            wins += 1
    if total == 0:
        return 0, 0

    return total, wins / total

def total_duration(replays):
    duration = 0
    for replay in replays["list"]:
        duration += replay["duration"]

    # Seconds to hours.
    return duration / 60 / 60

def get_data(tag, token, playlist, since):
    params = {
        "player-name": tag,
        "count": "200",
    }

    if playlist != "all":
        params["playlist"] = playlist

    if since != None:
        params["replay-date-after"] = since

    API_ENDPOINT = "https://ballchasing.com/api/replays"

    res = http.get(
        API_ENDPOINT,
        headers = {"Authorization": token},
        params = params,
    )

    if res.status_code != 200:
        fail("Error calling Ballchasing API")

    replays = res.json()

    total_games, win_percent = win_percentage(replays, tag)
    total_time = total_duration(replays)

    data = {
        "total_games": str(total_games) + " gs",
        "win_percent": humanize.float("###.", win_percent * 100) + "% wr",
        "total_time": humanize.float("#,###.#", total_time) + " hrs",
    }

    return data

def render_data(data):
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Padding(child = render.Image(src = LOGO), pad = (1, 1, 1, 1)),
                    render.Column(children = [
                        render.Text(
                            data["total_games"],
                        ),
                        render.Text(
                            data["win_percent"],
                        ),
                        render.Text(
                            data["total_time"],
                        ),
                    ]),
                ],
            ),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "All",
            value = "all",
        ),
        schema.Option(
            display = "Unranked Duels",
            value = "unranked-duels",
        ),
        schema.Option(
            display = "Unranked Doubles",
            value = "unranked-doubles",
        ),
        schema.Option(
            display = "Unranked Standard",
            value = "unranked-standard",
        ),
        schema.Option(
            display = "Unranked Chaos",
            value = "unranked-chaos",
        ),
        schema.Option(
            display = "Ranked Duels",
            value = "ranked-duels",
        ),
        schema.Option(
            display = "Ranked Doubles",
            value = "ranked-doubles",
        ),
        schema.Option(
            display = "Ranked Standard",
            value = "ranked-standard",
        ),
        schema.Option(
            display = "Snowday",
            value = "ranked-snowday",
        ),
        schema.Option(
            display = "Hoops",
            value = "ranked-hoops",
        ),
        schema.Option(
            display = "Rumble",
            value = "ranked-rumble",
        ),
        schema.Option(
            display = "Dropshot",
            value = "ranked-dropshot",
        ),
        schema.Option(
            display = "Tournament",
            value = "tournament",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "token",
                name = "Ballchasing API Token",
                desc = "https://ballchasing.com/upload",
                icon = "key",
            ),
            schema.Text(
                id = "tag",
                name = "Player Tag",
                desc = "Ex: Flakes",
                icon = "user",
            ),
            schema.Dropdown(
                id = "playlist",
                name = "Playlist",
                desc = "Playlist to get data for",
                # All replays by default.
                default = options[0].value,
                options = options,
                icon = "gamepad",
            ),
            schema.DateTime(
                id = "since",
                name = "Games Since",
                desc = "Only use games played after the given date",
                icon = "clock",
            ),
        ],
    )

def main(config):
    tag = config.get("tag")
    token = config.get("token")
    playlist = config.get("playlist")
    since = config.get("since")

    if tag == None or token == None:
        print("error: tag or token is not set")
        return render_data(EMPTY_DATA)

    # Cache by config options.
    key = json.encode((tag, playlist, since))
    data_cached = cache.get(key)

    if data_cached == None:
        print("cache miss")
        data = get_data(tag, token, playlist, since)
        cache.set(key, json.encode(data), ttl_seconds = TWELVE_HOURS)
    else:
        print("cache hit")
        data = json.decode(data_cached)

    print(data)

    return render_data(data)
