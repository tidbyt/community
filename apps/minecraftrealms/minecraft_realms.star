"""
Applet: Minecraft Realms
Summary: Minecraft Realms Status
Description: Displays information about Minecraft Realms you're in.
Author: Michael Maxwell
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

dev_client_id = "1"
dev_client_secret = "1"

client_id = secret.decrypt("AV6+xWcE0oEENc8cYDYZaBTSmJzIIHVwew2bNOTqMpYZleaCzEJD24AQT+0NeWa5PG8NzbbE/xApiCMthSIMQ+LUkBJBq1UYL3v247iVuiWT2L/B0FLgztjU+7FYFFAlVmHH9d2oljpCxffuWmI1POCmZGRm3+thPtvNozmUaGVjnAy60iN/ayL9") or dev_client_id
client_secret = secret.decrypt("AV6+xWcEDo6NatcDWPyY8dzx/ryiqTN7yetHagu11g51G2MiePI8DUJtSgTqeUnZOdvTIJ0u0zb+91wZ7twSJ6Dr0NweZPoPg+TVvxaq+B97jCNVgYgdDYGdUi3yPoMW31Hv0e48KYJyiu7RWb6f6L7ds72K1gtK6Sec/FtZ6hk9TvL01e9KxNWp6JigAw==") or dev_client_secret

auth_endpoint = "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize"
token_endpoint = "https://login.microsoftonline.com/consumers/oauth2/v2.0/token"

# -------- MAIN TIDBYT FUNCTIONS --------

def main(config):
    access_token = refresh_access_token(config)
    if not access_token:
        return render_not_logged_in()

    xbox_live_token, user_hash = xbox_live_auth(access_token)
    xsts_token = get_xsts_token(xbox_live_token)

    if not (user_hash and xsts_token):
        return render_no_xbox()

    worlds_json = realms_worlds(user_hash, xsts_token)

    if not worlds_json["servers"]:
        return render_no_realms()
    server = sample(worlds_json["servers"])

    players_json = realms_players(user_hash, xsts_token)
    slot = int(server["activeSlot"]) - 1
    name = server["name"]
    players = len(get_players(players_json, server))
    max_players = int(server["maxPlayers"])
    motd = server["motd"]

    return render_realms(name, slot, players, max_players, motd)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Account",
                desc = "Connect your Microsoft account.",
                icon = "microsoft",
                handler = oauth_handler,
                client_id = client_id,
                authorization_endpoint = auth_endpoint,
                scopes = ["offline_access", "XboxLive.signin"],
            ),
        ],
    )

# -------- RENDER FUNCTIONS --------

def render_no_xbox():
    return render.Root(
        render.Text(content = "No Xbox / Minecraft"),
    )

def render_not_logged_in():
    return render.Root(
        render.Text(content = "Please login"),
    )

def render_no_realms():
    return render.Root(
        render.Text(content = "No Realms Found"),
    )

def render_realms(name, slot, players, max_players, motd):
    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Padding(
                            child = render.Circle(color = slot_map(slot), diameter = 6),
                            pad = (1, 1, 2, 1),
                        ),
                        render.Text(content = name),
                    ],
                    expanded = True,
                ),
                render.Row(
                    children = [
                        render.Text(content = "Online: " + str(players) + "/" + str(max_players)),
                    ],
                    main_align = "center",
                    expanded = True,
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = motd),
                    offset_start = 5,
                    offset_end = 32,
                ),
            ],
        ),
    )

# -------- HELPER FUNCTIONS --------

def seconds_between(before_str, after_str):
    before = time.parse_time(before_str)
    after = time.parse_time(after_str)
    seconds = int((after - before).seconds)
    return seconds

def get_players(res_json, server):
    for s in res_json["servers"]:
        if s["id"] == server["id"]:
            return s["players"]

    return []

def sample(servers):
    count = len(servers)
    index = 0 if count <= 1 else random.number(0, count - 1)
    return servers[index]

def slot_map(slot):
    if slot == 0:
        return "#0ff"
    if slot == 1:
        return "#f0f"
    return "#ff0"

# -------- AUTHENTICATION --------

def oauth_handler(params):
    params = json.decode(params)

    res = http.post(
        url = token_endpoint,
        form_body = {
            "client_id": params["client_id"],
            "code": params["code"],
            "redirect_uri": params["redirect_uri"],
            "grant_type": params["grant_type"],
            "scope": "offline_access XboxLive.signin",
            "client_secret": client_secret,
        },
    )
    if res.status_code != 200:
        fail("HTTP %d - %s" % (res.status_code, res.body()))

    res_json = res.json()

    cache.set(
        res_json["refresh_token"],
        res_json["access_token"],
        ttl_seconds = int(res_json["expires_in"]),
    )

    return res_json["refresh_token"]

def refresh_access_token(config):
    refresh_token = config.get("auth")
    if not refresh_token:
        return None

    access_token = cache.get(refresh_token)
    if access_token:
        return access_token

    res = http.post(
        url = token_endpoint,
        form_body = {
            "refresh_token": refresh_token,
            "client_id": client_id,
            "client_secret": client_secret,
            "grant_type": "refresh_token",
            "scope": "offline_access XboxLive.signin",
        },
    )
    if res.status_code != 200:
        fail("HTTP %d - %s" % (res.status_code, res.body()))

    res_json = res.json()

    cache.set(
        res_json["refresh_token"],
        res_json["access_token"],
        ttl_seconds = int(res_json["expires_in"]),
    )

    return res_json["access_token"]

def xbox_live_auth(access_token):
    xbox_live_token = cache.get("xbox_live_token")
    user_hash = cache.get("user_hash")
    if xbox_live_token and user_hash:
        return xbox_live_token, user_hash

    res = http.post(
        url = "https://user.auth.xboxlive.com/user/authenticate",
        json_body = {
            "Properties": {
                "AuthMethod": "RPS",
                "SiteName": "user.auth.xboxlive.com",
                "RpsTicket": "d=" + access_token,
            },
            "RelyingParty": "http://auth.xboxlive.com",
            "TokenType": "JWT",
        },
    )

    if res.status_code != 200:
        fail("HTTP %d - %s" % (res.status_code, res.body()))

    res_json = res.json()

    xbox_live_token = res_json["Token"]
    user_hash = res_json["DisplayClaims"]["xui"][0]["uhs"]

    ttl_seconds = seconds_between(res_json["IssueInstant"], res_json["NotAfter"])
    cache.set("xbox_live_token", xbox_live_token, ttl_seconds = ttl_seconds)
    cache.set("user_hash", user_hash, ttl_seconds = ttl_seconds)

    return xbox_live_token, user_hash

def get_xsts_token(xbox_live_token):
    xsts_token = cache.get("xsts_token")
    if xsts_token:
        return xsts_token

    res = http.post(
        url = "https://xsts.auth.xboxlive.com/xsts/authorize",
        json_body = {
            "Properties": {
                "SandboxId": "RETAIL",
                "UserTokens": [xbox_live_token],
            },
            "RelyingParty": "https://pocket.realms.minecraft.net/",
            "TokenType": "JWT",
        },
    )

    if res.status_code != 200:
        fail("HTTP %d - %s" % (res.status_code, res.body()))

    res_json = res.json()

    xsts_token = res_json["Token"]

    ttl_seconds = seconds_between(res_json["IssueInstant"], res_json["NotAfter"])
    cache.set("xsts_token", xsts_token, ttl_seconds = ttl_seconds)

    return xsts_token

# -------- MINECRAFT API CALLS --------

def realms_worlds(user_hash, xsts_token):
    res = http.get(
        url = "https://pocket.realms.minecraft.net/worlds",
        ttl_seconds = 300,
        headers = {
            "Authorization": "XBL3.0 x=" + user_hash + ";" + xsts_token,
            "Client-Version": "xxx",
            "User-Agent": "xxx",
        },
    )

    if res.status_code != 200:
        fail("HTTP %d - %s" % (res.status_code, res.body()))

    return res.json()

def realms_players(user_hash, xsts_token):
    res = http.get(
        url = "https://pocket.realms.minecraft.net/activities/live/players",
        ttl_seconds = 60,
        headers = {
            "Authorization": "XBL3.0 x=" + user_hash + ";" + xsts_token,
            "Client-Version": "xxx",
            "User-Agent": "xxx",
        },
    )

    if res.status_code != 200:
        fail("HTTP %d - %s" % (res.status_code, res.body()))

    return res.json()
