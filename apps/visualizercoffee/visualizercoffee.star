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

VISUALIZER_CLIENT_ID = secret.decrypt("AV6+xWcEs7GK6+4UJs55eLPgTYImEf3CNXkn+VrlNeQMEvp5cp93NZ+5TzUN1uEChPSdopm1TzpgE3vfcZC3SDIRs7aJbipw3ZRGaC84QvtAJOOOMATn3lI6cWtyD4GjKQ9AIQOednje/pPgwOV2LL+B065eC8PfzUfDs6+CDlzEsCtfdI/mYVAp8AA0Ztzh6Q==")
VISUALZER_CLIENT_SECRET = secret.decrypt("AV6+xWcEU2Y6ROm1F7rraW1/mQ/1uAI0RNaxKWyCFqkJJi+yzToyn1VmbU95ItbY2XKs7wYBhAi0QH48P1oFR3k3BRkxGKbJQl7zP1dQYLrHo/9PXrYq2drXKsvdbNi+LTQ1ZLYrffbZsAzu0AiZzM2zBsn3kpBSJ0i1Wnd1DB7WqKIp2JOU/3E/jlHfGwbFwQ==")

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
            time.from_timestamp(latest_shot.get("clock", 1)),
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
    resp = http.get(
        "https://visualizer.coffee/api/shots/",
        headers = {
            "Authorization": "Bearer " + auth_token,
        },
        ttl_seconds = 600,  # 10 mins.
    )
    if resp.status_code != 200:
        if DEBUG:
            print("DEBUG: %s failed to get shots token." % resp.status_code)
        return None

    return json.decode(resp.data)

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
        timestamp = time.from_timestamp(shot.get("clock", 1))
        if timestamp > time.from_timestamp(latest_shot.get("clock", 1)):
            latest_shot = shot

    return latest_shot

def get_todays_shots(my_shots):
    """ Returns a list of shots from today (starting at midnight).

    Args:
      my_shots: data returned from getting shots
    Returns:
        list of todays shots
    """
    n = time.now()
    today_ts = time.time(year = n.year, month = n.month, day = n.day)

    todays_shots = []
    for shot in my_shots.get("data"):
        ts = time.from_timestamp(shot.get("clock", 1))
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

    auth_resp = http.post(
        url = "https://visualizer.coffee/oauth/access_token",
        params = params,
        headers = {
            "Accept": "application/json",
        },
    )

    if auth_resp.status_code != 200:
        if DEBUG:
            print("DEBUG: %s failed to get auth token." % auth_resp.status_code)
        return None
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
    if auth_token == None and not DEBUG:
        return render_problem("auth malfunction")  # display if auth is missing

    if DEBUG:
        my_shots = json.decode(MY_SHOTS_EXAMPLE_DATA)
    else:
        my_shots = get_my_shots(auth_token)
        if my_shots == None and not DEBUG:
            return render_problem("could not get shots from vizulizer...")

    return render_root(get_todays_shots(my_shots), get_latest_shot(my_shots))

MY_SHOTS_EXAMPLE_DATA = """{
  "data": [
    {
      "clock": 1707601287,
      "id": "904eee96-bbef-43cf-8bcc-e3a721dd555e"
    },
    {
      "clock": 1707601287,
      "id": "8357da14-6459-467f-adf3-6faa059b156f"
    },
    {
      "clock": 1636023818,
      "id": "b079731e-5de6-4aed-a5fe-4d41b9e40463"
    },
    {
      "clock": 1636011257,
      "id": "7ecd9c2e-7725-495d-a97f-a8d70d59f9b3"
    },
    {
      "clock": 1636010515,
      "id": "11b77777-48d4-421a-9405-818ea78547fb"
    },
    {
      "clock": 1635944542,
      "id": "afbefcfb-e694-4697-9fdc-1c6c16979c28"
    },
    {
      "clock": 1635923878,
      "id": "e1585fc3-0ddb-43aa-84e0-5a2768690472"
    },
    {
      "clock": 1635922810,
      "id": "68f38711-f26e-4073-9807-e20cf601d01e"
    },
    {
      "clock": 1635844997,
      "id": "39df6e88-6b01-434b-891b-4a4d8f574e43"
    },
    {
      "clock": 1635781298,
      "id": "e0296025-6639-4b60-b938-003d1b15e6e6"
    }
  ],
  "paging": {
    "count": 74,
    "page": 1,
    "items": 10,
    "pages": 8
  }
}"""
