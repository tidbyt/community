"""
Applet: My Last Coffee
Summary: Show when your last espresso shot was pulled. 
Description: Display details and meta infomation about the last espresso shot you recorded.
Author: jeffbean
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

VISUALIZER_CLIENT_ID = secret.decrypt("AV6+xWcEmpNnOn5bdEhhlhz53Yz0qwomDILXMktc9nEVoXROf0S56lbUlR6BTlAe5Z7jiEGRB2QwPiCZb20nsdzXUZTFRtfKC+boIYCbDEqunKR85NyoOi0m51JVb7Q5+Qp2+/Tmf+8EZZzugPYkY+aRCWWsHQiN6CWwy1DHw5Vkb7MiYiORhpaT18sXj7C8Og==")
VISUALZER_CLIENT_SECRET = secret.decrypt("AV6+xWcE1qF0RYSlJXn4oBgRhSlfN/hWZz63gj2qfj/Y2bf8M+mdSQH7ZhRHsBKYC8FEAqJDAC3V3RAjs4TSpGo+Exu+3+S6WwcKcHQCVO4uXviLVmYWzVcPhs4tHOm7btcY/98E9j93Dkz4Ng+6XejhLtAo7rSE5dx4qKqH60jp6fH016rk9s3Ciu5Qjxxr5g==")

DEFAULT_TIMEZONE = "US/Pacific"

DEBUG = False

def render_root(todays_shots, latest_shot):
    """ Renders the root for the app while we have data for it 

    Args:
      todays_shots: list containing the shots that are timestamped today.
      latest_shot: the latest shot data we found.
    Returns:
        rendered root for the app
    """

    render_text = "{}".format(
        humanize.time(
            time.from_timestamp(latest_shot.get("clock", 1)).in_location(DEFAULT_TIMEZONE),
        ),
    )

    todays_text = "{}".format(len(todays_shots))

    return render.Root(
        child = render.Stack(
            children = [
                # column at the top of the screen
                render.Column(
                    main_align = "start",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.Row(
                                    main_align = "space_between",
                                    cross_align = "end",
                                    children = [
                                        render.Text(todays_text, color = "#DEB887", font = "10x20"),
                                        render.Padding(
                                            child = render.Text("/ today", font = "CG-pixel-4x5-mono"),
                                            pad = 4,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),

                # column to hold the stuff in the bottom of the screen
                render.Column(
                    main_align = "end",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.Padding(
                                    child = render.Text("last shot ...", color = "#DEB887", font = "tom-thumb"),
                                    pad = 1,
                                ),
                            ],
                        ),
                        render.Row(
                            main_align = "center",
                            expanded = True,
                            children = [
                                render.Marquee(
                                    width = 64,
                                    child = render.Text(render_text, font = "tom-thumb"),
                                    align = "center",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def render_problem(msg):
    return render.Root(
        render.Marquee(
            width = 64,
            child = render.Text(msg),
            align = "center",
        ),
    )

def get_my_shots(auth_token):
    """ Fetchs the list of shots for the OAuth user.

    Args:
        auth_token: the auth token from oauth exchange.
    Returns:
        list of shots for the authenticated user.
    """
    url = "https://visualizer.coffee/api/shots/"
    resp = http.get(
        url,
        headers = {
            "Authorization": "Bearer " + auth_token,
        },
        ttl_seconds = 600,  # 10 mins.
    )
    if resp.status_code != 200:
        if DEBUG:
            print("request to %s failed with status code: %d - %s" % (url, resp.status_code, resp.body()))
        return None

    return json.decode(resp.body())

def get_latest_shot(my_shots):
    """ Returns the latest shot by time.

    Args:
      my_shots: data returned from getting shots
    Returns:
        latest shot object
    """

    # im not sure we can assume its time sorted, simple
    # loop to find the latest shot from the list.
    latest_shot = {}
    for shot in my_shots["data"]:
        timestamp = time.from_timestamp(shot.get("clock", 1)).in_location(DEFAULT_TIMEZONE)
        if timestamp > time.from_timestamp(latest_shot.get("clock", 1)).in_location(DEFAULT_TIMEZONE):
            latest_shot = shot

    return latest_shot

def get_todays_shots(my_shots):
    """ Returns a list of shots from today (starting at midnight).

    Args:
      my_shots: data returned from getting shots
    Returns:
        list of todays shots
    """
    n = time.now().in_location(DEFAULT_TIMEZONE).unix
    today_ts = time.from_timestamp(n).in_location(DEFAULT_TIMEZONE)

    todays_shots = []
    for shot in my_shots.get("data"):
        ts = time.from_timestamp(shot.get("clock", 1)).in_location(DEFAULT_TIMEZONE)
        if ts > today_ts:
            todays_shots.append(shot)

    return todays_shots

def oauth_handler(params):
    """ Handles the login process for visulizer coffee.

    Args:
      params: the parmeters for sending the oauth aurhorize request.
    Returns:
      access token
    """
    params = json.decode(params)
    params["client_secret"] = VISUALZER_CLIENT_SECRET

    url = "https://visualizer.coffee/oauth/access_token"
    auth_resp = http.post(
        url = url,
        params = params,
        headers = {
            "Accept": "application/json",
        },
    )

    if auth_resp.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, auth_resp.status_code, auth_resp.body()))
    else:
        access_token = auth_resp.json()["access_token"]

    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Visualizer",
                desc = "Connect your Visualizer account.",
                icon = "",
                handler = oauth_handler,
                client_id = VISUALIZER_CLIENT_ID or "default-client-id",
                authorization_endpoint = "https://visualizer.coffee/oauth/authorize",
                scopes = [
                    "read",
                ],
            ),
        ],
    )

def main(config):
    """ The main function for the application

    todo:
    - config for colors?
    - thresholds where text color will change, like if < 1 by noon its red... lol

    Args:
      config: the passed in config object accessing fields set by the schema.
    Returns:
      a rendered root object
    """
    auth_token = config.get("auth", None)
    if auth_token == None:
        return render_problem("auth malfunction")  # display if auth is missing

    my_shots = get_my_shots(auth_token)
    if my_shots == None:
        return render_problem("could not get shots from vizulizer...")

    return render_root(get_todays_shots(my_shots), get_latest_shot(my_shots))
