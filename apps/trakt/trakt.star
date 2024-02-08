"""
Applet: Trakt
Summary: Trakt info on your Tidbyt
Description: Show your Trakt now watching, most recently watched, and stats, on your Tidbyt.
Author: cbattlegear
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

OAUTH2_CLIENT_ID = secret.decrypt("AV6+xWcEJDFhI/7+Al+nlujFD+sWG8e45sk6rBox8kDNs1Zcj9ZxHlNFMHq0C4531/9SSAT2RfeZme0ywPENdPVRcm1qppgyHxM65/YLorJsaLhV5lpg7IOcvajBPHKcaEbRcWSIbfFUzoxlKrqtLkEY6Ff64WsgoggqNValaG3aMXt6Doveq6860Q0q7hLLkSQBXhA+wjAQYZPaFJbT+ZFptNTt7A==")
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcEPPga5YWsxjwU7OgkZ5fBn5KA9oa97da3gPsHYhGo7Up/sVwk+Dvcle6VgBQEQw/MyB7IqMcE8wh2ulL0apzEaWM4T2gOhbz+XLtU2zgdjG2q9AfE6pOkejK9SFcBhnJQZxgO0aNs2zcefLJOXnwi0DgnT5BYIQeKQRa/oYHcOyyee4JBoBHTszVv5mELDn22gjwSdohtvPadddhDfcLZrw==")
TMDB_API_SECRET = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJlMDBiNTc2M2UyYTc3ZmVjZThmOTNkMzZjYmIxNTQ0NyIsInN1YiI6IjUwZTQ2ZjczMTljMjk1N2YxNzAxNjE2NyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.MtKo5SBb-MSWcwkLFZWcwdA7haTzjIgYEC9Dz6dFzl8"

#TMDB_API_SECRET = secret.decrypt("AV6+xWcEaUL5mYhwnNC0Hkz340gBEd+lurjYTguVZNLBzyiB6JliU7T6u5I7VIx36kg89zR4GxHPK79gSE7XzqEL1k1n+LCAtMp15hotuuhRmYjvcA35c1IHtJtwDGdZ1JcmvWjQoaPo8gNQeglGXVeB3Q+FMUJPkp4rOzryAXV7An33UpT8u+MosvBE0HSd0aIcdF5FjC4ZNqhUWrcbxa9S1V00mY9Nt2H7ojw7HPZnNCHGieyxavJzEBTXVo140oqgQ4/4FjhXFdoW4kP8LIf2Wp4IHAKspHNK+vm1fwZlx0gGgsMflMOLH/ZOdtJeyHO1OetUISuAe0VlEUaocFsz6AJXhLfrk0wld5XL+vP9qLeTmoQni+eMzAlcJPE6uWSomVrBmrWNWh5YA5jtOcxzHXAgAgHTaw==")
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/"
TMDB_POSTER_PATH = "w92"

def get_watching_watched(token, count):
    res_watching = http.get(
        url = "https://api.trakt.tv/users/me/watching",
        headers = {
            "Content-Type": "application/json",
            "trakt-api-version": "2",
            "trakt-api-key": OAUTH2_CLIENT_ID,
            "Authorization": "Bearer " + token,
        },
        ttl_seconds = 600,
    )

    if res_watching.status_code == 204:
        # Currently not watching anything, let's show most recently watched
        res_watched = http.get(
            url = "https://api.trakt.tv/users/me/history",
            headers = {
                "Content-Type": "application/json",
                "trakt-api-version": "2",
                "trakt-api-key": OAUTH2_CLIENT_ID,
                "Authorization": "Bearer " + token,
            },
            ttl_seconds = 600,
        )
        if res_watched.status_code == 200:
            media = {
                "success": True,
                "currently_watching": False,
                "media_info": res_watched.json()[0:count],
            }
            return media
        else:
            media = {
                "success": False,
            }
            return media
    elif res_watching.status_code == 200:
        media = {
            "success": True,
            "currently_watching": True,
            "media_info": [res_watching.json()],
        }
        return media
    else:
        media = {
            "success": False,
        }
        return media

def get_poster(info):
    tmdb_url = "https://api.themoviedb.org/3/"
    if info.get("type") != None and info["type"] == "episode":
        tmdb_url = tmdb_url + "tv/" + str(int(info["show"]["ids"]["tmdb"])) + "/season/" + str(int(info["episode"]["season"]))
    elif info.get("type") != None and info["type"] == "movie":
        tmdb_url = tmdb_url + "movie/" + str(int(info["movie"]["ids"]["tmdb"]))
    elif info.get("movie") != None:
        tmdb_url = tmdb_url + "movie/" + str(int(info["movie"]["ids"]["tmdb"]))
    elif info.get("show") != None:
        tmdb_url = tmdb_url + "tv/" + str(int(info["show"]["ids"]["tmdb"]))

    res_poster = http.get(
        url = tmdb_url,
        headers = {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + TMDB_API_SECRET,
        },
        ttl_seconds = 2592000,
    )
    if res_poster.status_code != 200:
        return "FAILED"
    tmdb_json = res_poster.json()
    poster_path = tmdb_json["poster_path"]
    poster_image_request = http.get(url = str(TMDB_IMAGE_BASE) + str(TMDB_POSTER_PATH) + poster_path, ttl_seconds = 2592000)
    if poster_image_request.status_code != 200:
        return "FAILED"
    return poster_image_request.body()

def current_media_display(media_info, show_posters):
    poster = ""
    line_one = ""
    line_two = ""
    last_watched = ""
    if media_info["type"] == "episode":
        if show_posters:
            poster = get_poster(media_info)
            if poster == "FAILED":
                show_posters = False
        episode_number = humanize.ftoa(media_info["episode"]["number"])
        if len(episode_number) < 2:
            episode_number = "0" + episode_number
        line_one = media_info["show"]["title"] + " " + humanize.ftoa(media_info["episode"]["season"]) + "x" + episode_number
        line_two = media_info["episode"]["title"]
    else:
        if show_posters:
            poster = get_poster(media_info)
            if poster == "FAILED":
                show_posters = False
        line_one = media_info["movie"]["title"]
        line_two = str(media_info["movie"]["year"])
    last_watched = humanize.time(time.parse_time(media_info["watched_at"]))
    marquee_width = 64
    output = []
    if show_posters:
        marquee_width = 43
        output.append(
            render.Column(
                children = [
                    render.Image(
                        src = poster,
                        height = 32,
                    ),
                ],
            ),
        )
    output.append(
        render.Column(
            children = [
                render.Text(
                    "Watched",
                    font = "tom-thumb",
                ),
                render.Marquee(
                    width = marquee_width,
                    child = render.Column(
                        children = [
                            render.Row(
                                children = [render.Text(line_one, font = "Dina_r400-6")],
                            ),
                            render.Row(
                                children = [render.Text(line_two, font = "tb-8")],
                            ),
                            render.Row(
                                children = [render.Text(last_watched, font = "tom-thumb")],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )
    return output

def draw_progress_bar(progress, remainder):
    if (progress == 0):
        return [
            render.Box(
                height = 3,
                width = remainder,
                color = "#000000",
            ),
        ]
    else:
        return [
            render.Box(
                height = 3,
                width = progress,
                color = "#FFFFFF",
            ),
            render.Box(
                height = 3,
                width = remainder,
                color = "#000000",
            ),
        ]

def currently_watching_display(media_info, show_posters):
    poster = ""
    line_one = ""
    line_two = ""
    if media_info["type"] == "episode":
        if show_posters:
            poster = get_poster(media_info)
            if poster == "FAILED":
                show_posters = False
        episode_number = humanize.ftoa(media_info["episode"]["number"])
        if len(episode_number) < 2:
            episode_number = "0" + episode_number
        line_one = media_info["show"]["title"] + " " + humanize.ftoa(media_info["episode"]["season"]) + "x" + episode_number
        line_two = media_info["episode"]["title"]
    else:
        if show_posters:
            poster = get_poster(media_info)
            if poster == "FAILED":
                show_posters = False
        line_one = media_info["movie"]["title"]
        line_two = humanize.ftoa(media_info["movie"]["year"])

    marquee_width = 64
    output = []
    if show_posters:
        marquee_width = 43
        output.append(
            render.Column(
                children = [
                    render.Image(
                        src = poster,
                        height = 32,
                    ),
                ],
            ),
        )

    # How much have they watched? Let's figure out the percent
    started_at = time.parse_time(media_info["started_at"])
    ends_at = time.parse_time(media_info["expires_at"])
    current_time = time.now()
    media_length = ends_at - started_at
    duration_watched = current_time - started_at
    percent_watched = duration_watched / media_length
    progress = int((marquee_width - 2) * (percent_watched))
    remainder = (marquee_width - 2) - progress

    output.append(
        render.Column(
            children = [
                render.Text(
                    "Watching",
                    font = "tom-thumb",
                ),
                render.Marquee(
                    width = marquee_width,
                    child = render.Column(
                        children = [
                            render.Row(
                                children = [render.Text(line_one, font = "Dina_r400-6")],
                            ),
                            render.Row(
                                children = [render.Text(line_two, font = "tb-8")],
                            ),
                        ],
                    ),
                ),
                render.Box(
                    height = 1,
                ),
                render.Row(
                    children = [render.Box(
                        child = render.Row(
                            children = draw_progress_bar(progress, remainder),
                            expanded = True,
                        ),
                        padding = 1,
                        height = 5,
                        color = "#FFFFFF",
                    )],
                ),
            ],
        ),
    )
    return output

def get_trending_media(media_type, count):
    # If the first half of the hour, show trending shows, last half movies
    trakt_trending_url = "https://api.trakt.tv/{}/trending"
    res_trending = http.get(
        url = trakt_trending_url.format(media_type),
        headers = {
            "Content-Type": "application/json",
            "trakt-api-version": "2",
            "trakt-api-key": OAUTH2_CLIENT_ID,
        },
        ttl_seconds = 1800,
    )
    if res_trending.status_code == 200:
        trending = res_trending.json()[0:count]
        return trending
    else:
        trending = []
        return trending

def create_trending_display(media_type, trend_json, show_posters):
    poster = ""
    if show_posters:
        poster = get_poster(trend_json)
        if poster == "FAILED":
            show_posters = False
    line_one = trend_json[media_type.rstrip("s")]["title"]
    line_two = "Watchers: {}".format(humanize.ftoa(trend_json["watchers"]))
    marquee_width = 64
    output = []
    if show_posters:
        marquee_width = 43
        output.append(
            render.Column(
                children = [
                    render.Image(
                        src = poster,
                        height = 32,
                    ),
                ],
            ),
        )
    output.append(
        render.Column(
            children = [
                render.Text(
                    "Trending",
                    font = "tom-thumb",
                ),
                render.Marquee(
                    width = marquee_width,
                    child = render.Column(
                        children = [
                            render.Row(
                                children = [render.Text(line_one, font = "6x13")],
                            ),
                            render.Row(
                                children = [render.Text(line_two, font = "Dina_r400-6")],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )
    return output

def create_display(token, show_posters, number_of_items):
    if (token):
        media_returned = get_watching_watched(token, number_of_items)
        if media_returned["success"]:
            if media_returned["currently_watching"]:
                media_info = media_returned["media_info"][0]
                return render.Row(children = currently_watching_display(media_info, show_posters))
            else:
                media_info = media_returned["media_info"]
                if len(media_info) > 1:
                    media_items = []
                    for media in media_info:
                        media_items.append(render.Row(children = current_media_display(media, show_posters)))
                    return render.Sequence(children = media_items)
                else:
                    return render.Row(children = current_media_display(media_info[0], show_posters))
        else:
            return render.Marquee(
                width = 64,
                child = render.Text("Unable to contact Trakt Servers, Please try again later."),
            )
    else:
        media_type = "shows"
        if time.now().minute >= 30:
            media_type = "movies"
        media_info = get_trending_media(media_type, number_of_items)
        if len(media_info) != 0:
            if len(media_info) > 1:
                media_items = []
                for media in media_info:
                    media_items.append(render.Row(children = create_trending_display(media_type, media, show_posters)))
                return render.Sequence(children = media_items)
            else:
                return render.Row(children = create_trending_display(media_type, media_info[0], show_posters))
        else:
            return render.Marquee(
                width = 64,
                child = render.Text("Unable to contact Trakt Servers, Please try again later."),
            )

def main(config):
    token = config.get("auth")
    show_posters = config.bool("show_posters", False)
    number_of_items = int(config.get("recent_items", "1"))
    return render.Root(
        child = create_display(token, show_posters, number_of_items),
    )

def oauth_handler(params):
    # deserialize oauth2 parameters, see example above.
    params = json.decode(params)

    # exchange parameters and client secret for an access token
    res = http.post(
        url = "https://api.trakt.tv/oauth/token",
        headers = {
            "Accept": "application/json",
        },
        json_body = dict(
            params,
            client_secret = OAUTH2_CLIENT_SECRET,
        ),
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

def get_schema():
    options = [
        schema.Option(
            display = "1",
            value = "1",
        ),
        schema.Option(
            display = "2",
            value = "2",
        ),
        schema.Option(
            display = "3",
            value = "3",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Trakt",
                desc = "Connect your Trakt account.",
                icon = "forwardFast",
                handler = oauth_handler,
                client_id = OAUTH2_CLIENT_ID,
                authorization_endpoint = "https://trakt.tv/oauth/authorize",
                scopes = [
                    "public",
                ],
            ),
            schema.Toggle(
                id = "show_posters",
                name = "Show Media Posters",
                desc = "Show media posters from TMDB.",
                icon = "imagePortrait",
                default = False,
            ),
            schema.Dropdown(
                id = "recent_items",
                name = "Number of Items to Show",
                desc = "How many media items you'd like to show.",
                icon = "listOl",
                default = options[0].value,
                options = options,
            ),
        ],
    )
