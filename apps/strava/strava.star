"""
Applet: Strava
Summary: Displays athlete stats
Description: Displays your YTD or all-time athlete stats recorded on Strava.
Author: Rob Kimball
"""

load("http.star", "http")
load("math.star", "math")
load("time.star", "time")
load("cache.star", "cache")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("humanize.star", "humanize")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

STRAVA_BASE = "https://www.strava.com/api/v3"
CLIENT_ID = "79662"
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcE+oJPK08TUWRIoZPgneZiZsTciGafVUjbKA7elXuSDBS9h4koiu0kak1WthqS5W/HvXQtBM5kF7k8BMSgyIPNTBNEgep8BwAph7naog0GdcWLGKo2/eoQlXUSSVYtnBGc9EoxSp7soyw6BdMTOQgrnzOips7RKsI92CcSt4wzfQj/QTkSp6IyeA==")
DEFAULT_UNITS = "imperial"
DEFAULT_SPORT = "ride"
DEFAULT_PERIOD = "all"

PREVIEW_DATA = {
    "count": 108,
    "distance": 56159815,
    "moving_time": 2318919,
    "elapsed_time": 2615958,
    "elevation_gain": 11800,
}

CACHE_TTL = 60 * 60 * 1  # updates once hourly

STRAVA_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACgAAAAICAYAAACLUr1bAAAAAXNSR0IArs4c6QAAAJ1JREFUOE+
lVEEOgCAMg9/6JH+LwVhTm3Us4gUZk3VtZ2/PM8428D7XfrQ+V40jZ55HZ/hO79X8aI96fMcvEG
ggAx8B5IYZoJJhAWr3zCjAcI7G3D5iPQPICloGM6kq7ET2iGzjrIT4DXDlQ5XG5TNTuwDB4ofBz
AuZxDvD5YYtBMiF2AcrBldFlE3kZ5P8qlGRtwLQ/ZKc76YiFYAXQTytNejult0AAAAASUVORK5C
YII=
""")

RUN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAG9JREFUGFd
jZMAO/kOFGWHScAaS+v//LzaAuYz6DagK/////5+RkZHxf1fD/+PzVjB8/PIFrNDzyROwGGNZAy
M2Exm2y8iArebn4WGwunEDrAZD4TENjf/IJmJ1Y9l/5v+dDH8YQM4AsbsY/8INAgB44ioHVKqHv
gAAAABJRU5ErkJggg==
""")

RIDE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAGpJREFUGFd
jZICCkLyq/zD2mkltjCB2Qm03XAwsAAPHNDTgEjAxqxs3GEEawAr//////7imJgNIEMQHabC8fp
0BJAaiGUEApAhEI0uCNCBrBqtBVggyDWYqTBxmI9xqkADIZGQ3gxRDxRkAODJIzA34xRoAAAAAS
UVORK5CYII=
""")

SWIM_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAFpJREFUGFd
jZCASMMLU/f///z+MzcjICBaHiYH4jMgcdEkUhcg2I5vKsuorw99wHriNGFYrTf/C8EiYkUHu7X
+G+2oPGRhcdMBqwITitM//YZJwRVm8cENAagAl0DAHMC2dNAAAAABJRU5ErkJggg==
""")

CLOCK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAGRJREFUGFdj
ZGBg+M8ABf//w5lgEUZGRpgUA4gFlgUrmgmRSDqZyDDPfD4DQ/p/uGKsCp1XOTHsFX3AwLDiLnaF
SUlJDA8fPmS4f/8+wz0zRtwKGSKU4W4CM7CZCHcnklJkzwAAzHgtAXQJ+34AAAAASUVORK5CYII=
""")

ELEV_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAIBJREFUGFd
jZICCN+8//hcR5GeE8dFpuARIIUgSpvjXr1//2djY4PJgBkzRl4/vwQZJSUkxPHv2jKGkbxbDmk
ltYDVgomLCnP8v3r5ngCkEiakoKYE13bl3D6yYEaQIJABSCAIwxSCFyGKM0nEKYIUw4CqfDVd8/
MMysLClQBQDADOaPH3ku/SjAAAAAElFTkSuQmCC
""")

DISTANCE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAEtJREFUGFd
jZCAAeN0X/v+8M56REZ86kKJPO+IY+DwWMYAV/g9X+g+iGVfeQ9EIUggziBGkCKYAnQ1SxPehng
Gr1eimwzTjdSOy+wFaLiTvmqj9hwAAAABJRU5ErkJggg==
""")

def main(config):
    refresh_token = config.get("auth")
    timezone = config.get("timezone") or "America/New_York"
    year = time.now().in_location(timezone).year
    sport = config.get("sport", DEFAULT_SPORT)
    units = config.get("units", DEFAULT_UNITS)
    period = config.get("period", DEFAULT_PERIOD)
    show_logo = config.get("show_logo", True)

    if not refresh_token:
        stats = ["count", "distance", "moving_time", "elapsed_time", "elevation_gain"]
        stats = {k: PREVIEW_DATA[k] for k in stats}
    else:
        access_token = cache.get(refresh_token)
        if not access_token:
            print("Generating new access token")
            access_token = get_access_token(refresh_token)

        headers = {
            "Authorization": "Bearer %s" % access_token,
        }

        cache_prefix = "%s/%s/%s/" % (refresh_token, sport, period)

        # Get logged in athlete
        athlete = cache.get("%s/athlete_id" % refresh_token)
        if not athlete:
            print("Getting athlete ID from API, access_token was cached.")
            url = "%s/athlete" % STRAVA_BASE
            response = http.get(url, headers = headers)
            if response.status_code != 200:
                print("Strava API call failed with status %d" % response.status_code)

            data = response.json()
            athlete = int(float(data["id"]))
            cache.set("%s/athlete_id" % refresh_token, str(athlete), ttl_seconds = CACHE_TTL)

        stats = ["count", "distance", "moving_time", "elapsed_time", "elevation_gain"]
        stats = {k: cache.get(cache_prefix + k) for k in stats}

        if None not in stats.values():
            print("Displaying cached data.")
        else:
            url = "%s/athletes/%s/stats" % (STRAVA_BASE, athlete)
            print("Calling Strava API: " + url)
            response = http.get(url, headers = headers)
            if response.status_code != 200:
                fail("Strava API call failed with status %d" % response.status_code)
            data = response.json()

            for item in stats.keys():
                stats[item] = data["%s_%s_totals" % (period, sport)][item]
                cache.set(cache_prefix + item, str(stats[item]), ttl_seconds = CACHE_TTL)
                #print("saved item %s "%s" in the cache for %d seconds" % (item, str(stats[item]), CACHE_TTL))

    ###################################################
    # Configure the display to the user"s preferences #
    ###################################################

    if units.lower() == "imperial":
        if sport == "swim":
            stats["distance"] = round(meters_to_ft(float(stats["distance"])), 0)
            distu = "ft"
        else:
            stats["distance"] = round(meters_to_mi(float(stats["distance"])), 1)
            distu = "mi"
            elevu = "ft"
        stats["elevation_gain"] = round(meters_to_ft(float(stats["elevation_gain"])), 0)
    else:
        if sport != "swim":
            stats["distance"] = round(meters_to_km(float(stats["distance"])), 0)
            distu = "km"
        else:
            distu = "m"
        elevu = "m"

    if sport == "all":
        if int(float(stats["count"])) != 1:
            actu = "activities"
        else:
            actu = "activity"
    else:
        actu = sport
        if int(float(stats["count"])) != 1:
            actu += "s"

    display_header = []
    if show_logo == "true":
        display_header.append(render.Image(src = STRAVA_ICON))
    if period == "ytd":
        display_header.append(
            render.Text(" %d" % year, font = "tb-8"),
        )

    SPORT_ICON = {
        "run": RUN_ICON,
        "ride": RIDE_ICON,
        "swim": SWIM_ICON,
    }[sport]

    # The number of activites and distance traveled is universal, but for cycling the elevation gain is a
    # more interesting statistic than speed so we"ll vary the third item:
    if sport == "ride":
        third_stat = [
            render.Image(src = ELEV_ICON),
            render.Text(
                " %s %s" % (humanize.comma(float(stats.get("elevation_gain", 0))), elevu),
            ),
        ]
    else:
        if float(stats.get("distance", 0)) > 0:
            split = float(stats.get("moving_time", 0)) / float(stats.get("distance", 0))
            split = time.parse_duration(str(split) + "s")
            split = format_duration(split)
        else:
            split = "N/A"

        third_stat = [
            render.Image(src = CLOCK_ICON),
            render.Text(
                " %s%s" % (split, "/" + distu),
            ),
        ]

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    cross_align = "center",
                    children = display_header,
                ),
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = SPORT_ICON),
                        render.Text(" %s " % humanize.comma(float(stats.get("count", 0)))),
                        render.Text(actu, font = "tb-8"),
                    ],
                ),
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = DISTANCE_ICON),
                        render.Text(" %s " % humanize.comma(float(stats.get("distance", 0)))),
                        render.Text(distu, font = "tb-8"),
                    ],
                ),
                render.Row(
                    cross_align = "center",
                    children = third_stat,
                ),
            ],
        ),
    )

def meters_to_mi(m):
    return m * 0.00062137

def meters_to_km(m):
    return m / 1000

def meters_to_ft(m):
    return m * 3.280839895

def round(num, precision):
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def format_duration(d):
    m = int(d.minutes)
    s = str(int((d.minutes - m) * 60))
    m = str(m)
    if len(s) == 1:
        s = "0" + s
    return "%s:%s" % (m, s)

def oauth_handler(params):
    params = json.decode(params)
    auth_code = params.get("code")
    return get_refresh_token(auth_code)

def get_refresh_token(auth_code):
    params = dict(
        code = auth_code,
        client_secret = OAUTH2_CLIENT_SECRET,
        grant_type = "authorization_code",
        client_id = CLIENT_ID,
    )

    res = http.post(
        url = "https://www.strava.com/api/v3/oauth/token",
        headers = {
            "Accept": "application/json",
        },
        params = params,
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    refresh_token = token_params["refresh_token"]
    access_token = token_params["access_token"]
    athlete = int(float(token_params["athlete"]["id"]))

    cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))
    cache.set("%s/athlete_id" % refresh_token, str(athlete), ttl_seconds = CACHE_TTL)

    return refresh_token

def get_access_token(refresh_token):
    params = dict(
        refresh_token = refresh_token,
        client_secret = OAUTH2_CLIENT_SECRET,
        grant_type = "refresh_token",
        client_id = CLIENT_ID,
    )

    res = http.post(
        url = "https://www.strava.com/api/v3/oauth/token",
        headers = {
            "Accept": "application/json",
        },
        params = params,
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))

    return access_token

def display_failure(msg):
    return render.Root(
        child = render.Column(
            children = [
                render.Image(src = STRAVA_ICON),
                render.Marquee(
                    width = 64,
                    child = render.Text(msg),
                ),
            ],
        ),
    )

def get_schema():
    units_options = [
        schema.Option(value = "imperial", display = "Imperial (US)"),
        schema.Option(value = "metric", display = "Metric"),
    ]

    period_options = [
        schema.Option(value = "all", display = "All-time"),
        schema.Option(value = "ytd", display = "YTD"),
    ]

    sport_options = [
        schema.Option(value = "ride", display = "Cycling"),
        schema.Option(value = "run", display = "Running"),
        schema.Option(value = "swim", display = "Swimming"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Strava Login",
                desc = "Connect to your Strava account",
                icon = "user",
                client_id = str(CLIENT_ID),
                handler = oauth_handler,
                authorization_endpoint = "https://www.strava.com/oauth/authorize",
                scopes = [
                    "read",
                    "activity:read",
                ],
            ),
            schema.Dropdown(
                id = "sport",
                name = "What activity type do you want to display?",
                desc = "Runs, rides or swims are all supported!",
                icon = "running",
                options = sport_options,
                default = "ride",
            ),
            schema.Dropdown(
                id = "units",
                name = "Which units do you want to display?",
                desc = "Imperial displays miles and feet, metric displays kilometers and meters.",
                icon = "pencilRuler",
                options = units_options,
                default = DEFAULT_UNITS,
            ),
            schema.Dropdown(
                id = "period",
                name = "Display your all-time stats or YTD?",
                desc = "YTD will also display the current year in the corner",
                icon = "userClock",
                options = period_options,
                default = DEFAULT_PERIOD,
            ),
            schema.Toggle(
                id = "show_logo",
                name = "Logo",
                desc = "Whether to display the Strava logo.",
                icon = "cog",
                default = True,
            ),
        ],
    )
