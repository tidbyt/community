"""
Applet: mal-countdown
Summary: Countdown to anime
Description: Shows a countdown of the time until next anime episode on MyAnimeList.
Author: mikelikescode
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

CLIENT_SECRET = secret.decrypt("AV6+xWcErTGIUXlUghv8iOZehvtQTDbIAMOGiPHBAVysEvhYGYX3ANz+cnaRNezEc8XHQEDmA8nGb+jqwBqYW2hXkF1MAVPdkPMX2kfr/+8DOukdktxE7ewaKwK9OF0CsOU5wVhDdwAvD+LA+Cbv4kSQ5MnQkVc1EkSc1rQAgA2A6tFzY4xu7F1wgPOEQq0IBiOgIR39ZdjCndzXJ9/c3AbfvAa9Qg==") or "client_secret"
CODE_VERIFIER = secret.decrypt("AV6+xWcEUfEy1x6iS350lnTdIuivvshFExlAS56/eEHV6YEbmXaCEriUZHPYjGfM5t79tAmHyCRXxwpx9CO476QnDogkErbZuvbBSp1EZ9okO4DR9J2XyEh567k6iwclOmoYQv53I1CrH/B4GUo6Kmi6INwkt3WmFV36H5lC3N0Ki8jJfDwTUNJ8oecSSQPlIPUEVgZ0B3RQd4+j+1SPbVm8ldylaNcu0Bgenx8wRFJ4rxKx") or "code_verifier"
CLIENT_ID = secret.decrypt("AV6+xWcE7cBjA+edeSqK8InIcwP/tODOr/zXh6YCPv/UUt3EhWpyqvFW+zY7A2p7p3ZuLhc1wHPwNHfR2SDAkF1Am5r0++6WykmIZxoENOQxxJ0VRZ+YPrYp5aEUm9YjGPcNURMlh18QGG8xf8dYHUwgyOAyf1DSkBkSs2P1DFxIM7BQ9l0=") or "client_id"

def main(config):
    token = config.get("auth")
    anime_id = config.get("anime_id") or "51009"
    location = config.get("location")
    location = json.decode(location) if location else {}
    timezone = location.get("timezone", "America/New_York")

    if token:
        pass
    else:
        return render.Root(
            render.Row(
                children = [
                    render.WrappedText(
                        content = "Please login to MyAnimeList",
                        width = 60,
                        height = 30,
                        color = "#ffffff",
                    ),
                ],
            ),
        )

    url = "https://api.myanimelist.net/v2/anime/%s?fields=id,title,broadcast,status,start_date,end_date,year,num_episodes" % anime_id
    MAL_DATA = get_data(url, token)

    anime_status = MAL_DATA["status"]
    time_until_next_episode = calculate_time_until_next_episode(MAL_DATA["broadcast"]["day_of_the_week"], MAL_DATA["broadcast"]["start_time"], timezone)

    rendered_countdown = ""
    if anime_status == "currently_airing":
        rendered_countdown = render.Marquee(
            render.Text(
                content = time_until_next_episode,
                color = "#ffffff",
            ),
            width = len(time_until_next_episode) * 2,
            height = 30,
        )
    elif anime_status == "not_yet_aired":
        rendered_countdown = render.Box(
            child = render.WrappedText(
                content = "Upcoming",
                color = "#ffffff",
            ),
        )
    elif anime_status == "finished_airing":
        rendered_countdown = render.Box(
            padding = 1,
            child = render.WrappedText(
                content = "Finished",
                color = "#ffffff",
            ),
        )
    else:
        rendered_countdown = render.Box(
            padding = 1,
            child = render.WrappedText(
                content = "Unknown",
                color = "#ffffff",
            ),
        )

    return render.Root(
        render.Box(
            padding = 2,
            child = render.Row(
                children = [
                    render.Image(
                        src = http.get(MAL_DATA["main_picture"]["medium"]).body(),
                        width = 20,
                        height = 34,
                    ),
                    render.Column(
                        children = [
                            render.Marquee(
                                child = render.WrappedText(
                                    content = MAL_DATA["title"],
                                    align = "start",
                                    font = "CG-pixel-3x5-mono",
                                ),
                                width = len(MAL_DATA["title"]) * 3 + 10,
                                height = 30,
                            ),
                            render.Box(
                                width = 20,
                                height = 7,
                            ),
                            render.Row(
                                children = [
                                    rendered_countdown,
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
        show_full_animation = True,
    )

def calculate_time_until_next_episode(next_episode_day, next_episode_time, timezone):
    res = http.post("https://time-api-mal.vercel.app/api/time-conversion", json_body = {
        "airingDay": next_episode_day,
        "airingTime": next_episode_time,
        "timezone": timezone,
    }).json()

    # We want to round these to be integers
    days = math.floor(res["days"])
    hours = math.floor(res["hours"])
    minutes = math.floor(res["minutes"])

    day_prefix = humanize.plural(days, "day", "days")
    hour_prefix = humanize.plural(hours, "hour", "hours")
    minute_prefix = humanize.plural(minutes, "minute", "minutes")

    return "%s, %s, %s" % (day_prefix, hour_prefix, minute_prefix)

def get_data(url, token):
    res = http.get(url, headers = {
        "Authorization": "Bearer %s" % token,
    })
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())
    return res.json()

def oauth_handler(params):
    params = json.decode(params)
    res = http.post(
        url = "https://myanimelist.net/v1/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            code_verifier = CODE_VERIFIER,
            client_secret = CLIENT_SECRET,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "MyAnimeList",
                desc = "Login with MyAnimeList for access to your anime list.",
                icon = "",
                handler = oauth_handler,
                client_id = CLIENT_ID,
                authorization_endpoint = "https://myanimelist.net/v1/oauth2/authorize?code_challenge=%s&client_id=%s&scope=read:user&redirect_uri=http://127.0.0.1:8080/oauth-callback&response_type=code&state=abc123" % (CODE_VERIFIER, CLIENT_ID),
                scopes = ["read:user"],
            ),
            schema.Text(
                id = "anime_id",
                name = "Anime ID",
                desc = "Anime ID from MyAnimeList.",
                icon = "gear",
                default = "51009",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Timezone to use for countdown.",
                icon = "globe",
            ),
        ],
    )
