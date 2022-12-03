"""
Applet: PagerDuty
Summary: Show PagerDuty Stats
Description: Show PagerDuty incident stats and on-call status.
Author: drudge
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("http.star", "http")
load("time.star", "time")
load("schema.star", "schema")
load("secret.star", "secret")
load("render.star", "render")

DEFAULT_TIMEZONE = "US/Eastern"
DEFAULT_ONLY_LEVEL_1 = False
DEFAULT_SHOW_ONCALL_BAR = True
DEFAULT_SHOW_ONCALL_BAR_ME_ONLY = False
DEFAULT_SHOW_ICON = True
DEFAULT_HIDE_WHEN_NOT_ONCALL = False
DEFAULT_CACHE_TTL = 120
DEFAULT_TEAM_ID = "all"

PAGERDUTY_BASE_URL = "https://api.pagerduty.com"
PAGERDUTY_CLIENT_ID = "85d49cda-f774-438e-9f13-12cf5b644dba"
PAGERDUTY_CLIENT_SECRET = secret.decrypt("""
AV6+xWcEtYmJAnDtS6Eppriq/Rmq7bouK7h8Pbzq93fhw5UuGlS3/CGz+Iehxx9IIqsSWaTFw8ZSYtqe
e7si79zwvaVujMsIxVaWikJl+lni6rYLiWE0uS4poSsLVuNnpl5JOpiAzVhzo+q5JCNuGukH188iMfw3
suxf4nTNuaCKHMz/8sNhxqQZE1NuimjgRQ==
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
    return render.Column(
        cross_align = "center",
        children = [
            render.Text(
                content = str(count),
                font = "6x13",
                color = "#fff",
            ),
            render.Text(
                content = label.upper(),
                font = "CG-pixel-3x5-mono",
                color = color,
            ),
        ],
    )

# buildifier: disable=function-docstring
def pagerduty_api_call(config, url, use_cache = True):
    access_token = config.get("auth")

    if not access_token:
        return fail("No access token")

    cache_key = "%s|%s" % (access_token, url)
    cached_res = cache.get(cache_key) if use_cache else None

    if not cached_res:
        res = http.get(
            url,
            headers = {
                "Authorization": "Bearer %s" % access_token,
                "Accept": "application/vnd.pagerduty+json;version=2",
            },
        )

        if res.status_code < 200 or res.status_code >= 300:
            # buildifier: disable=print
            print("pagerduty_api_call failed: %s - %s " % (res.status_code, res.body()))
            return None
        elif len(res.body()) > 0:
            cached_res = res.body()
        else:
            cached_res = '{"status": %i}' % res.status_code

        if use_cache:
            cache.set(cache_key, cached_res, DEFAULT_CACHE_TTL)

    return json.decode(cached_res)

# buildifier: disable=function-docstring
def get_pagerduty_counts(config, profile = None, teams_supported = True):
    received_data = False
    counts = dict(
        total = 0,
        triggered = 0,
        acknowledged = 0,
    )
    team_param = ""
    team_id = config.get("team_id", DEFAULT_TEAM_ID)

    if teams_supported and profile != None:
        if team_id != "all":
            team_param = "&team_ids[]=%s" % team_id
        elif len(profile["teams"]) > 0:
            for team in profile["teams"]:
                team_param += "&team_ids[]=%s" % team["id"]

    triggered = pagerduty_api_call(config, "%s/incidents?total=true&limit=1&statuses[]=triggered%s" % (PAGERDUTY_BASE_URL, team_param))

    if triggered:
        counts["triggered"] = int(triggered["total"])
        received_data = True

    acknowledged = pagerduty_api_call(config, "%s/incidents?total=true&limit=1&statuses[]=acknowledged%s" % (PAGERDUTY_BASE_URL, team_param))

    if acknowledged:
        counts["acknowledged"] = int(acknowledged["total"])
        received_data = True

    counts["total"] = counts["acknowledged"] + counts["triggered"]

    return counts if received_data else None

# buildifier: disable=function-docstring
def get_current_user(config):
    data = pagerduty_api_call(config, "%s/users/me" % PAGERDUTY_BASE_URL)

    if data and "user" in data:
        return data["user"]

    return None

def sort_by_level(shift):
    return shift["escalation_level"]

def parse_shifts(oncalls = []):
    shifts = []
    for oncall in oncalls:
        start = None
        end = None
        if oncall["start"]:
            start = oncall["start"]
        if oncall["end"]:
            end = oncall["end"]
        parsed_shift = dict(
            escalation_policy = dict(
                id = oncall["escalation_policy"]["id"],
                name = oncall["escalation_policy"]["summary"],
            ),
            start = start,
            end = end,
            escalation_level = oncall["escalation_level"],
            user = dict(
                id = oncall["user"]["id"],
                name = oncall["user"]["summary"],
            ),
        )
        shifts.append(parsed_shift)
    return shifts

# buildifier: disable=function-docstring
def get_oncall_shifts(config, profile_id = None, offset = 0, limit = 100, shifts = []):
    access_token = config.get("auth")

    if not access_token:
        return None

    cached_shifts = cache.get("%s|shifts" % access_token)

    if cached_shifts:
        return json.decode(cached_shifts)

    tz = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(tz).format("2006-01-02T15:04:05Z07:00")
    url = "%s/oncalls?%searliest=true&since=%s&until=%s&overflow=true&offset=%i&limit=%i" % (
        PAGERDUTY_BASE_URL,
        "user_ids[]=%s&" % profile_id if profile_id else "",
        now,
        now,
        offset,
        limit,
    )

    # we disable caching here since we're going to cache our smaller parsed shifts
    data = pagerduty_api_call(config, url, use_cache = False)

    if not data:
        return None

    if "oncalls" in data:
        shifts = shifts + parse_shifts(data["oncalls"])

    # page through the results
    if "more" in data and data["more"]:
        return get_oncall_shifts(config, profile_id, offset + limit, limit, shifts)

    shifts = sorted(shifts, key = sort_by_level)
    cache.set("%s|shifts" % access_token, json.encode(shifts), DEFAULT_CACHE_TTL)
    return shifts

# buildifier: disable=function-docstring
def is_user_oncall(config, shifts, user_id):
    level_one_only = config.bool("only_lvl_1_oncall", DEFAULT_ONLY_LEVEL_1)

    if not shifts:
        return None

    is_user_oncall = False

    for shift in shifts:
        if shift["user"]["id"] == user_id:
            if level_one_only:
                is_user_oncall = (shift["escalation_level"] == 1)
            else:
                is_user_oncall = True
            if is_user_oncall:
                break

    return is_user_oncall

def are_teams_supported(config):
    result = pagerduty_api_call(config, "%s/abilities/teams" % PAGERDUTY_BASE_URL)

    if result != None and result["status"] != None:
        return result["status"] == 204
    else:
        return False

# buildifier: disable=function-docstring
def get_oncall_scroll_text(shifts, timezone = DEFAULT_TIMEZONE):
    scroll = ""
    unique_names = []

    for shift in shifts:
        if "user" in shift and shift["user"]["name"] not in unique_names:
            unique_names.append(shift["user"]["name"])

    scroll = " * %s *" % " | ".join([
        "%s: %s [L%s]" % (
            shift["escalation_policy"]["name"],
            shift["user"]["name"],
            shift["escalation_level"],
        )
        for shift in shifts
    ])

    if len(unique_names) == 1:
        ends = " "
        if shifts[0]["end"] != None:
            shift_ends = time.parse_time(shifts[0]["end"]).in_location(timezone)
            ends = " - Ends in %s" % humanize.relative_time(shift_ends, time.now())
        scroll = " * ON-CALL: %s%s*" % (unique_names[0], ends)
    return scroll

# buildifier: disable=function-docstring
def hide_app():
    return []

# buildifier: disable=function-docstring
def get_state(config):
    access_token = config.get("auth")
    is_preview = not access_token
    oncall = False
    show_icon = config.bool("show_icon", DEFAULT_SHOW_ICON)
    show_oncall_bar = config.bool("show_oncall_bar", DEFAULT_SHOW_ONCALL_BAR)
    hide_when_not_oncall = config.bool("hide_when_not_oncall", DEFAULT_HIDE_WHEN_NOT_ONCALL)
    level_one_only = config.bool("only_lvl_1_oncall", DEFAULT_ONLY_LEVEL_1)
    only_when_oncall = config.bool("only_when_oncall", DEFAULT_SHOW_ONCALL_BAR_ME_ONLY)
    team_id = config.get("team_id", DEFAULT_TEAM_ID)
    counts = None
    shifts = []
    profile = None

    if is_preview:
        oncall = True
        counts = dict(
            total = 42,
            triggered = 7,
            acknowledged = 0,
        )
    else:
        profile = get_current_user(config)

        if profile == None:
            return Error("Failed to get user profile")

        account_has_teams = are_teams_supported(config)
        counts = get_pagerduty_counts(config, profile, account_has_teams)

        if show_oncall_bar:
            shifts = get_oncall_shifts(config, profile["id"] if only_when_oncall else None)
            oncall = is_user_oncall(config, shifts, profile["id"])

            if oncall == None:
                return Error("Failed to get on-call status")

    return struct(
        oncall = oncall,
        shifts = shifts,
        counts = counts,
        profile = profile,
        is_preview = is_preview,
        show_icon = show_icon,
        show_oncall_bar = show_oncall_bar,
        hide_when_not_oncall = hide_when_not_oncall,
        level_one_only = level_one_only,
        only_when_oncall = only_when_oncall,
        team_id = team_id,
        teams_supported = account_has_teams,
    )

# buildifier: disable=function-docstring
def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    data = get_state(config)

    # don't show the app if we didn't get any data
    if not data.counts:
        return hide_app()

    separator = render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Box(
            width = 1,
            height = 22,
            color = "#3c3c3c",
        ),
    )
    pagerduty_logo = None
    if data.show_icon:
        pagerduty_logo = render.Padding(
            pad = (0, 2, 3, 0),
            child = render.Box(
                height = 14,
                width = 14,
                color = "#00591e",
                child = render.Stack(
                    children = [
                        render.Padding(
                            pad = (x, y, 0, 0),
                            child = render.Text(
                                content = "P",
                                font = "6x13",
                                color = "#eee",
                            ),
                        )
                        for (x, y) in [
                            (1, 0),
                            (1, 1),
                            (2, 0),
                            (2, 1),
                        ]
                    ],
                ),
            ),
        )

    if data.hide_when_not_oncall and not data.oncall:
        return hide_app()

    oncall_bar = None
    if data.show_oncall_bar:
        oncall_bar_color = "#3c3c3c"
        oncall_bar_content = None

        if data.oncall:
            oncall_bar_color = "#900000"
            oncall_bar_content = "* ON-CALL *"
        elif data.level_one_only and not data.only_when_oncall:
            oncall_bar_content = get_oncall_scroll_text([
                shift
                for shift in data.shifts
                if ((
                    shift["user"]["id"] == data.profile["id"] and
                    shift["escalation_level"] == 1
                ) or (shift["user"]["id"] != data.profile["id"]))
            ], timezone) if len(data.shifts) > 0 else None

        if oncall_bar_content:
            oncall_status = render.Text(
                content = oncall_bar_content,
                color = "#efefef",
            )
            if not data.oncall:
                oncall_status = render.Marquee(
                    width = 64,
                    child = oncall_status,
                )
            oncall_bar = render.Box(
                color = oncall_bar_color,
                height = 9,
                child = oncall_status,
            )

    return render.Root(
        child = render.Column(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = oncall_bar == None,
            children = [
                render.Padding(
                    pad = (1, 0, 0, 1),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            pagerduty_logo,
                            Count(data.counts["total"]),
                            separator,
                            Count(
                                label = " new ",
                                count = data.counts["triggered"],
                                color = "#ff0000",
                            ),
                        ],
                    ),
                ),
                oncall_bar,
            ],
        ),
    )

def build_teams(refresh_token):
    config = dict(auth = refresh_token)
    user = get_current_user(config)
    teams_supported = are_teams_supported(config)

    if not teams_supported:
        return None

    options = [
        schema.Option(
            display = "All",
            value = "all",
        ),
    ]

    if user != None and user["teams"] != None:
        for team in user["teams"]:
            options.append(
                schema.Option(
                    display = team["summary"],
                    value = team["id"],
                ),
            )

    return [
        schema.Dropdown(
            id = "team_id",
            name = "Team",
            desc = "Limit stats to a specific team",
            icon = "peopleGroup",
            options = options,
            default = options[0].value,
        ),
    ]

# buildifier: disable=function-docstring
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
            schema.Generated(
                id = "generated_teams",
                source = "auth",
                handler = build_teams,
            ),
            schema.Toggle(
                id = "show_icon",
                name = "Show icon",
                desc = "Whether to show the Pager Duty icon.",
                icon = "image",
                default = DEFAULT_SHOW_ICON,
            ),
            schema.Toggle(
                id = "show_oncall_bar",
                name = "Show on-call status",
                desc = "Whether to show bottom bar with current on-call status.",
                icon = "eye",
                default = DEFAULT_SHOW_ONCALL_BAR,
            ),
            schema.Toggle(
                id = "only_when_oncall",
                name = "Only show my status",
                desc = "When enabled, the bottom bar will only show if the user is on-call.",
                icon = "filter",
                default = DEFAULT_SHOW_ONCALL_BAR_ME_ONLY,
            ),
            schema.Toggle(
                id = "only_lvl_1_oncall",
                name = "Level 1 only",
                desc = "When enabled, only level 1 escalation levels will be treated as on-call.",
                icon = "medal",
                default = DEFAULT_ONLY_LEVEL_1,
            ),
            schema.Toggle(
                id = "hide_when_not_oncall",
                name = "Hide when off duty",
                desc = "When enabled, the app will not be displayed when you are not on-call.",
                icon = "eyeSlash",
                default = DEFAULT_HIDE_WHEN_NOT_ONCALL,
            ),
        ],
    )
