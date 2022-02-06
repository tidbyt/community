"""
Applet: PagerDuty
Summary: Show PagerDuty Stats
Description: Show PagerDuty incident stats and on-call status.
Author: drudge
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("time.star", "time")
load("schema.star", "schema")
load("secret.star", "secret")
load("render.star", "render")

DEFAULT_TIMEZONE = "US/Eastern"
DEFAULT_ONLY_LEVEL_1 = False
DEFAULT_SHOW_ONCALL_BAR = True
DEFAULT_HIDE_WHEN_NOT_ONCALL = False

PAGERDUTY_BASE_URL = "https://api.pagerduty.com"
PAGERDUTY_CLIENT_ID = "703b64e6-0b2d-4c41-a627-237143138f2c"
PAGERDUTY_CLIENT_SECRET = secret.decrypt("""
AV6+xWcE5gWY+iJP9nCtJkcE7u4swgXsxS1LoCpFUeGLwge0ItolmYpucKB+Q3v3iRDc8pCw1+2tQHvM
zdcO690Y5lRj94fuk5Oc+C2PEb26mthyhemakMvDcFlU+h12eZxbuJYn76nn5ersHUJ+9ec+j0xfqsVL
BB/E0RQEYnXXp0z1PvmRCGCBVjYPqyv4oA==
""")

def Error(message = ""):
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "!",
                        font = "6x13",
                        color = "#FF0000",
                    ),
                    render.WrappedText(message),
                ],
            ),
        ),
    )

def Count(count = 0, label = "TOTAL", color = "#c3c3c3"):
    return render.Padding(
        pad = (1, 1, 1, 1),
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(
                    content = str(count),
                    font = "6x13",
                    color = "#fff",
                ),
                render.Text(
                    content = label.upper(),
                    font = "tom-thumb",
                    color = color,
                ),
            ],
        ),
    )

def pagerduty_api_call(config, url):
    access_token = config.get("auth")

    if not access_token:
        return fail("No access token")

    cache_key = "%s|%s" % (access_token, url)
    cached_res = cache.get(cache_key)

    if not cached_res:
        res = http.get(
            url,
            headers = {
                "Authorization": "Bearer %s" % access_token,
                "Accept": "application/vnd.pagerduty+json;version=2",
            },
        )

        if res.status_code != 200:
            print("pagerduty_api_call failed: " + str(res.status_code) + " - " + res.body())
            return None

        cached_res = res.body()
        cache.set(cache_key, cached_res, 120)

    return json.decode(cached_res)

def get_pagerduty_counts(config):
    received_data = False
    counts = dict(
        total = 0,
        triggered = 0,
        acknowledged = 0,
    )

    triggered = pagerduty_api_call(config, "%s/incidents?total=true&limit=1&statuses[]=triggered" % PAGERDUTY_BASE_URL)

    if triggered:
        counts["triggered"] = int(triggered["total"])
        received_data = True

    acknowledged = pagerduty_api_call(config, "%s/incidents?total=true&limit=1&statuses[]=acknowledged" % PAGERDUTY_BASE_URL)

    if acknowledged:
        counts["acknowledged"] = int(acknowledged["total"])
        received_data = True

    counts["total"] = counts["acknowledged"] + counts["triggered"]

    return counts if received_data else None

def get_current_user(config):
    token = config.get("auth")
    data = pagerduty_api_call(config, "%s/users/me" % PAGERDUTY_BASE_URL)

    if data and "user" in data:
        return data["user"]

    return None

def is_user_oncall(config, user_id):
    level_one_only = config.bool("only_lvl_1_oncall", DEFAULT_ONLY_LEVEL_1)
    tz = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(tz).format("2006-01-02T15:04:05Z07:00")
    url = "%s/oncalls?earliest=true&since=%s&until=%s&overflow=true" % (PAGERDUTY_BASE_URL, now, now)

    data = pagerduty_api_call(config, url)

    if not data:
        return None

    is_user_oncall = False

    if "oncalls" in data:
        for oncall in data["oncalls"]:
            if "user" in oncall and oncall["user"]["id"] == user_id:
                if level_one_only and "escalation_level" in oncall:
                    is_user_oncall = int(oncall["escalation_level"]) == 1
                else:
                    is_user_oncall = True
                if is_user_oncall:
                    break

    return is_user_oncall

def hide_app():
    return []

def main(config):
    access_token = config.get("auth")

    if not access_token:
        return Error("Grant access to PagerDuty")

    counts = get_pagerduty_counts(config)

    # don't show the app if we didn't get any data
    if not counts:
        return hide_app()

    show_oncall_bar = config.bool("show_oncall_bar", DEFAULT_SHOW_ONCALL_BAR)

    if show_oncall_bar:
        profile = get_current_user(config)

        if profile == None:
            return Error("Failed to get user profile")

        oncall = is_user_oncall(config, profile["id"])

        if oncall == None:
            return Error("Failed to get on-call status")
    else:
        oncall = False

    separator = render.Padding(
        pad = (0, 1, 0, 1),
        child = render.Box(
            width = 1,
            height = 22,
            color = "#3c3c3c",
        ),
    )
    pagerduty_logo = render.Box(
        height = 12,
        width = 12,
        color = "#00591E",
        child = render.Text(
            content = "P",
            font = "6x13",
            color = "#eee",
        ),
    )
    oncall_bar = None

    if show_oncall_bar and oncall:
        oncall_bar = render.Box(
            color = "#900000",
            height = 9,
            child = render.Text(
                content = "* ON-CALL *",
                color = "#efefef",
            ),
        )

    hide_when_not_oncall = config.bool("hide_when_not_oncall", DEFAULT_HIDE_WHEN_NOT_ONCALL)

    if hide_when_not_oncall and not oncall:
        return hide_app()

    return render.Root(
        child = render.Column(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = not oncall,
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        pagerduty_logo,
                        Count(counts["total"]),
                        separator,
                        Count(
                            label = "trig",
                            count = counts["triggered"],
                            color = "#ff0000",
                        ),
                    ],
                ),
                oncall_bar,
            ],
        ),
    )

def oauth_handler(params):
    params = json.decode(params)

    res = http.post(
        url = "https://app.pagerduty.com/oauth/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            client_secret = PAGERDUTY_CLIENT_SECRET,
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
                name = "PagerDuty",
                desc = "Connect your PagerDuty account.",
                icon = "pager",
                handler = oauth_handler,
                client_id = PAGERDUTY_CLIENT_ID,
                authorization_endpoint = "https://app.pagerduty.com/oauth/authorize",
                scopes = [
                    "read",
                ],
            ),
            schema.Toggle(
                id = "show_oncall_bar",
                name = "Show on-call details bar",
                desc = "Whether to show a bar at the bottom of the screen when you are on-call.",
                icon = "exclamationCircle",
                default = DEFAULT_SHOW_ONCALL_BAR,
            ),
            schema.Toggle(
                id = "hide_when_not_oncall",
                name = "Hide when not on-call",
                desc = "When enabled, the app will not be displayed when you are not on-call.",
                icon = "eyeSlash",
                default = DEFAULT_HIDE_WHEN_NOT_ONCALL,
            ),
            schema.Toggle(
                id = "only_lvl_1_oncall",
                name = "Only treat level 1 escalations as on-call",
                desc = "When enabled, only level 1 escalation levels will be treated as on-call.",
                icon = "filter",
                default = DEFAULT_ONLY_LEVEL_1,
            ),
        ],
    )
