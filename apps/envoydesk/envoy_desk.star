"""
Applet: Envoy Desk
Summary: Envoy Desk information
Description: Can be placed on an Envoy Desk to display its current status.
Author: Sam Kalum <skalum@envoy.com>
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

OAUTH_AUTH_URL = "https://app.envoy.com/a/auth/v0/authorize"
OAUTH_TOKEN_URL = "https://app.envoy.com/a/auth/v0/token"
OAUTH_CLIENT_ID = "e46a9a78-363b-11ee-9d88-4fb3c69edd7f"
OAUTH_SCOPES = [
    "locations.read",
    "reservations.read",
    "spaces.read",
    "employees.read",
]
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcEJh2+FimQ3RnzWZv10rlGletKaq0OLM8RcKK4yp7GX+Q5d5NyZqddwFTvHVprjYYC5VSF6kcGQX2a8pbbGtYUeUP9Ctbv2T+vaai/9TPkQ0/7gYYS3/fMp3+ovuRyrEUHWraFmOcYd+xWHS2U4hd3bZNhDOiD1fk3aOCE16g7mK8utGFCkemRTtuU5+1bTKy+T313EiIgEn/trBonRfR9CEGdojDqYjWGVNshYcAdF0cQYiZ1tshw+9Ov93cDl2XQekk8jk35VOWmoG/r38baHCfeSTQV2K4pDjjYH+B9Zi8=")

def getDeskInfo(config):
    envoy_token = config.get("envoy_token") or ""
    desk_id = config.get("desk_id") or ""
    floor_ids = config.get("floor_ids") or ""

    url = "https://api.envoy.com/v1/reservations"
    params = {
        "status": "ACTIVE",
        "floorIds": floor_ids,
    }
    headers = {
        "Authorization": "Bearer %s" % (envoy_token),
        "Accept": "*/*",
    }

    res = http.get(url, params = params, headers = headers)

    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())

    reservations = res.json()["data"]

    desk_reservation = None
    for reservation in reservations:
        if reservation["space"]["id"] == desk_id:
            desk_reservation = reservation
            break

    if desk_reservation != None:
        return {
            "is_available": False,
            "full_name": desk_reservation["reservedBy"]["name"],
            "desk_name": desk_reservation["space"]["name"],
        }

    url = "https://api.envoy.com/v1/spaces/%s" % (desk_id)
    headers = {
        "Authorization": "Bearer %s" % (envoy_token),
        "Accept": "*/*",
    }

    res = http.get(url, headers = headers)

    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())

    desk = res.json()["data"]

    print(desk)

    return {
        "is_available": desk["isAvailable"],
        "desk_name": desk["name"],
        "assigned": desk["assignedTo"] != "" and desk["assignedTo"] != None,
    }

def main(config):
    envoy_token = config.get("envoy_token") or "noToken"
    desk_id = config.get("desk_id") or ""

    if envoy_token == "noToken":
        return render.Root(
            child = render.Marquee(
                child = render.Text("Please authenticate to Envoy."),
                width = 64,
            ),
        )
    elif desk_id == "":
        return render.Root(
            child = render.Marquee(
                child = render.Text("Please enter a desk ID."),
                width = 64,
            ),
        )

    desk_info = getDeskInfo(config)

    if "full_name" in desk_info:
        return render.Root(
            child = render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                content = "Desk %s" % (desk_info["desk_name"]),
                            ),
                            render.Box(
                                child = render.Text(
                                    content = desk_info["full_name"],
                                    color = "#fb4338",
                                ),
                                height = 25,
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "center",
            ),
        )

    elif desk_info["assigned"] == True:
        return render.Root(
            child = render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                content = "Desk %s" % (desk_info["desk_name"]),
                            ),
                            render.Box(
                                child = render.Text(
                                    content = "Assigned",
                                ),
                                color = "#8b0000",
                                height = 25,
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "center",
            ),
        )

    elif desk_info["is_available"] == False:
        return render.Root(
            child = render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                content = "Desk %s" % (desk_info["desk_name"]),
                            ),
                            render.Box(
                                child = render.Text(
                                    content = "Not available",
                                ),
                                color = "#8b0000",
                                height = 25,
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "center",
            ),
        )

    else:
        return render.Root(
            child = render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                content = "Desk %s" % (desk_info["desk_name"]),
                            ),
                            render.Box(
                                child = render.Text(
                                    content = "Available",
                                ),
                                color = "#006400",
                                height = 25,
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "center",
            ),
        )

def oauth_handler(params):
    # deserialize oauth2 parameters, see example above.
    params = json.decode(params)

    # exchange parameters and client secret for an access token
    res = http.post(
        url = OAUTH_TOKEN_URL,
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            grant_type = "authorization_code",
            code = params["code"],
            client_id = OAUTH_CLIENT_ID,
            client_secret = OAUTH2_CLIENT_SECRET,
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
                id = "envoy_token",
                name = "Envoy",
                desc = "Connect your Envoy account.",
                icon = "code",
                handler = oauth_handler,
                client_id = OAUTH_CLIENT_ID,
                authorization_endpoint = OAUTH_AUTH_URL,
                scopes = OAUTH_SCOPES,
            ),
            schema.Text(
                id = "desk_id",
                name = "Desk ID",
                desc = "At what desk is the Tidbyt located?",
                icon = "locationDot",
            ),
            schema.Text(
                id = "floor_ids",
                name = "Floor ID",
                desc = "On what floor is the Tidbyt located?",
                icon = "locationDot",
            ),
        ],
    )
