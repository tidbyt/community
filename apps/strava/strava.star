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
DEFAULT_SCREEN = "all"

PREVIEW_DATA = {
    "count": 1408,
    "distance": 56159815,
    "moving_time": 2318919,
    "elapsed_time": 2615958,
    "elevation_gain": 125800,
}

CACHE_TTL = 60 * 60 * 24  # updates once daily

STRAVA_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACgAAAAICAYAAACLUr1bAAAAAXNSR0IArs4c6QAAAJ1JREFUOE+
lVEEOgCAMg9/6JH+LwVhTm3Us4gUZk3VtZ2/PM8428D7XfrQ+V40jZ55HZ/hO79X8aI96fMcvEG
ggAx8B5IYZoJJhAWr3zCjAcI7G3D5iPQPICloGM6kq7ET2iGzjrIT4DXDlQ5XG5TNTuwDB4ofBz
AuZxDvD5YYtBMiF2AcrBldFlE3kZ5P8qlGRtwLQ/ZKc76YiFYAXQTytNejult0AAAAASUVORK5C
YII=
""")

STRAVA_ICON_GREY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACgAAAAICAYAAACLUr1bAAAAAXNSR0IArs4c6QAAAKZJREFUOE+l
lNERgCAMQ2UqR/DTWf10BKfSwzNe7CVFxR8ECn2kgTJc3zjNO/5ru61LqW0cR0ydV3NYF/eN8aqP
fLzHLwgcIINXgHxgBoxiWMB4elYUMBwTx1xfqZ4BcgWtglmp3qij7KFs46yE8ROw5cNYGhfPSvUC
QsWHgpkXshL3XC532SQgJ2IftBRsJYlqIj67yWC5S+yeGec3BZ09Ozz3BfAA4+Djoeo+ZzsAAAAA
SUVORK5CYII=
""")

RUN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAGpJREFUGFdj
ZMACKkM9/oOE21fvYIRJwxkwAZCithoLMJdRvwG7wv9dDf+Pz1vB8PHLF7BCzydPGEFijGUNjBgm
ghRsl5EBW83Pw8NgdeMGWA2GwmMaGv+RTcTqxrL/zP+7GP+CNSOzQXwAmAopB3+7+0kAAAAASUVO
RK5CYII=
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

PR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAGCAYAAADgzO9IAAAAAXNSR0IArs4c6QAAAERlWElmTU0
AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABqADAAQAAA
ABAAAABgAAAABrkD2lAAAAWUlEQVQIHWN8ukbpPwMIcDCDKRDx6t5zBkYQ4+kWVYjkj78Mr569Y
jDM+8LIBJIAA6jg9y9/wVy4BEglMgBLSPvcZgSpBGGrqu9g48HEnipGiB1QLS5t/xkBgJYlhpF+
DqcAAAAASUVORK5CYII=
""")

HEART_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAGCAYAAAAPDoR2AAAAAXNSR0IArs4c6QAAAERlWElmTU0
AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAB6ADAAQAAA
ABAAAABgAAAADsNvbmAAAAZklEQVQIHWNgAIIPvU3/QRjEfu5r8x+EQWxGkCCrpi7D7+uXGf48e
cjw+85Nhv/s3AyXX71kYAKpwCZx+/M3BkaQ5JvC5P/IOkASOedvMYIlQQqehbj/BxkFkwCJoYAp
hmpgh8AEAeNyQoGVq7nIAAAAAElFTkSuQmCC
""")

KUDOS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAGCAYAAAAPDoR2AAAAAXNSR0IArs4c6QAAAERlWElmTU0
AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAB6ADAAQAAA
ABAAAABgAAAADsNvbmAAAAXklEQVQIHWNgQAJfv379j8RlYELmoLOZKibM+Z9Q2w3W8fPnT4Z37
979B2GQQhaY6gcPHvz/9OkTjMuwd+/e/3BJPj4+uMT58+cZHj58iNApJCTEOG/ePLiDkpKSGAEl
ZyaSy2CBIgAAAABJRU5ErkJggg==
""")

ACHIEVEMENT_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAGCAYAAADgzO9IAAAAAXNSR0IArs4c6QAAAERlWElmTU0
AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABqADAAQAAA
ABAAAABgAAAABrkD2lAAAAMElEQVQIHWOcOnXqfwZcAFmyu7sbrJAJl2KcEnANICNgxoAEGUFEf
X09igMaGxsZAeczEWNoVg96AAAAAElFTkSuQmCC
""")

KCAL_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAGCAYAAAAPDoR2AAAAAXNSR0IArs4c6QAAAERlWElmTU0
AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAB6ADAAQAAA
ABAAAABgAAAADsNvbmAAAAZklEQVQIHWNgQAJfetj+gzBMiAnGAAlyOwcyfLn4DybEwAhigSX0m
Bh+v/zP8AuIn5/9y6C6/C8jXCdMAqTzzee/YN0sYJ1IRt1//4dB9DFIzz+IsSAFd/SZ/r+W/QeW
ULn4D2wdAPH3MeVIneA3AAAAAElFTkSuQmCC
""")

WATTS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAGCAYAAAAPDoR2AAAAAXNSR0IArs4c6QAAAERlWElmTU0
AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAB6ADAAQAAA
ABAAAABgAAAADsNvbmAAAARklEQVQIHWNgQAJ//x/6D8Jf77n/RxJmYAAJfv/+HUWCEaQCJAGif
zw7DqIYGH7uY+BW2gmWgwgAya9PO1F0EiGB7gCoFgC8DS5ePrnJYwAAAABJRU5ErkJggg==
""")

def main(config):
    refresh_token = config.get("auth")
    sport = config.get("sport", DEFAULT_SPORT)
    units = config.get("units", DEFAULT_UNITS)
    display_type = config.get("display_type", DEFAULT_SCREEN)

    if display_type in ("ytd", "all"):
        return athlete_stats(config, refresh_token, display_type, sport, units)
    elif display_type == "progress_chart":
        return progress_chart(config, refresh_token, sport, units)
    elif display_type == "last_activity":
        return last_activity(config, refresh_token, sport, units)
    else:
        print("Display type %s was invalid, showing the %s screen instead." % (display_type, DEFAULT_SCREEN))
        return athlete_stats(config, refresh_token, DEFAULT_SCREEN, sport, units)

def progress_chart(config, refresh_token, sport, units):
    show_logo = config.bool("show_logo", True)

    distance_conv = meters_to_mi
    if units == "metric":
        distance_conv = meters_to_km

    activities = get_activities(config, refresh_token)

    # This is duped from the get_activities function but we still need this info for this display
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    beg_curr_month = time.time(year = now.year, month = now.month, day = 1)
    _next_month = time.time(year = now.year, month = now.month, day = 32)
    end_curr_month = time.time(year = _next_month.year, month = _next_month.month, day = 1) - time.parse_duration("1ns")
    end_prev_month = beg_curr_month - time.parse_duration("1ns")
    beg_prev_month = time.time(year = end_prev_month.year, month = end_prev_month.month, day = 1)

    stat_keys = ("distance", "moving_time", "total_elevation_gain")
    graph_stat = stat_keys[0]

    # Iterate through each activity from the current and previous month and extract the relevant data, adding it
    # to our cumulative totals as we go, which are later used in our plot.
    included_current_activities = []
    cumulative_current = {k: 0 for k in stat_keys}
    for item in activities["current"]:
        if item["type"].lower() == sport:
            activity_time = time.parse_time(item["start_date"])
            activity_epoch = activity_time.unix
            activity_stats = {k: item.get(k, 0) for k in stat_keys}
            activity_stats["time"] = activity_time
            activity_stats["date_pct"] = (activity_epoch - beg_curr_month.unix) / (end_curr_month.unix - beg_curr_month.unix)
            cumulative_current = {k: cumulative_current.get(k, 0) + activity_stats.get(k, 0) for k in stat_keys}
            activity_stats.update({
                "cum_%s" % k: round(cumulative_current.get(k, 0), 2)
                for k in stat_keys
            })
            included_current_activities.append(activity_stats)
            print(activity_stats)
        else:
            print("Found non-%s activity (%s), skipping" % (sport, item["type"]))

    included_previous_activities = []
    cumulative_previous = {k: 0 for k in stat_keys}
    for item in activities["previous"]:
        if item["type"].lower() == sport:
            activity_time = time.parse_time(item["start_date"])
            activity_epoch = activity_time.unix
            activity_stats = {k: item.get(k, 0) for k in stat_keys}
            activity_stats["time"] = activity_time
            activity_stats["date_pct"] = (activity_epoch - beg_prev_month.unix) / (end_prev_month.unix - beg_prev_month.unix)
            cumulative_previous = {k: cumulative_previous.get(k, 0) + activity_stats.get(k, 0) for k in stat_keys}
            activity_stats.update({
                "cum_%s" % k: round(cumulative_previous.get(k, 0), 2)
                for k in stat_keys
            })
            included_previous_activities.append(activity_stats)
            print(activity_stats)
        else:
            print("Found non-%s activity (%s), skipping" % (sport, item["type"]))

    # Start both plots off at the origin and then add converted distance at each time stamp.
    # We use the percentage of the month here to align the axis of months that consist of a different number of days
    # Immediately before each activity we add the previous distance to create the "step" effect in the graph
    curr_plot = [(0.0, 0.0)]
    for item in included_current_activities:
        curr_plot.append((item["date_pct"] - .025, curr_plot[-1][1]))
        curr_plot.append((item["date_pct"], distance_conv(item["cum_%s" % graph_stat])))

    prev_plot = [(0.0, 0.0)]
    for item in included_previous_activities:
        prev_plot.append((item["date_pct"] - .025, prev_plot[-1][1]))
        prev_plot.append((item["date_pct"], distance_conv(item["cum_%s" % graph_stat])))

    # At the end of the current plot we want today's date as a percentage of the month,
    now_date_pct = (now.unix - beg_curr_month.unix) / (end_curr_month.unix - beg_curr_month.unix)
    curr_plot.append((now_date_pct, curr_plot[-1][1]))

    # ...and at the end of the previous plot we want 100% of the month to be our final cumulative number
    prev_plot.append((1.0, prev_plot[-1][1]))

    plot_height = max([prev_plot[-1][1], curr_plot[-1][1]])

    title_font = "CG-pixel-3x5-mono"

    total_time = time.parse_duration("%ss" % cumulative_current.get("moving_time", 0))
    if len(included_current_activities):
        total_time = format_duration(total_time, resolution = "hours")
    else:
        total_time = "0:00"

    logo = []
    if show_logo:
        sport_icon = {
            "run": RUN_ICON,
            "ride": RIDE_ICON,
            "swim": SWIM_ICON,
        }[sport]
        logo.append(
            render.Column(
                expanded = True,
                main_align = "end",
                cross_align = "end",
                children = [render.Image(src = sport_icon)],
            ),
        )
        graph_width = 54
    else:
        graph_width = 64

    if sport == "ride":
        value = cumulative_current["total_elevation_gain"]
        if units == "imperial":
            value = meters_to_ft(value)

        if value == 0 and len(curr_plot) > 0:
            # We can assume the athlete is using a trainer here and would rather not see elevation
            third_stat = {
                "title": sport + "s",
                "value": len(included_current_activities),
            }
        else:
            third_stat = {
                "title": "Elev",
                "value": int(value),
            }
    else:
        third_stat = {
            "title": sport + "s",
            "value": len(included_current_activities),
        }

    frames = []
    num_frames = len(prev_plot) + len(curr_plot)
    for i in range(num_frames):
        frames.append(
            render.Stack(
                children = [
                    # Using a column here so I can place the logo in the bottom corner
                    render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "start",
                        children = logo,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "end",
                        cross_align = "end",
                        children = [
                            render.Column(
                                expanded = True,
                                main_align = "end",
                                children = [
                                    render.Plot(
                                        data = prev_plot[0:i],
                                        width = graph_width,
                                        height = 22,
                                        color = "#787878",
                                        y_lim = (0.0, plot_height),
                                        x_lim = (0.0, 1.0),
                                        fill = False,
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "end",
                        cross_align = "end",
                        children = [
                            render.Column(
                                expanded = True,
                                main_align = "end",
                                children = [
                                    render.Plot(
                                        data = curr_plot[0:i - len(prev_plot)],
                                        width = graph_width,
                                        height = 22,
                                        color = "#fc4c02",
                                        y_lim = (0.0, plot_height),
                                        x_lim = (0.0, 1.0),
                                        fill = False,
                                    ),
                                ] if i > len(prev_plot) else [],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Text("Time", color = "#fc4c02", font = title_font),
                                    render.Text(total_time, color = "#FFF"),
                                ],
                            ),
                            render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text("Dist", color = "#fc4c02", font = title_font),
                                    render.Text(
                                        humanize.comma(int(distance_conv(cumulative_current["distance"]))),
                                        color = "#FFF",
                                    ),
                                ],
                            ),
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Text(third_stat["title"], color = "#fc4c02", font = title_font),
                                    render.Text(
                                        humanize.comma(third_stat["value"]),
                                        color = "#FFF",
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

    # Repeat last frame for a long time
    frames.extend([frames[-1]] * 400)

    return render.Root(
        delay = 50,
        child = render.Animation(
            children = frames,
        ),
    )

def athlete_stats(config, refresh_token, period, sport, units):
    show_logo = config.get("show_logo", True)
    timezone = config.get("timezone") or "America/New_York"
    year = time.now().in_location(timezone).year

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
                text = "code %d, %s" % (response.status_code, json.decode(response.body()).get("message", ""))
                return display_failure("Strava API failed, %s" % text)

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
                text = "code %d, %s" % (response.status_code, json.decode(response.body()).get("message", ""))
                return display_failure("Strava API failed, %s" % text)
            data = response.json()

            for per in ("ytd", "all"):
                for sport_code in ("ride", "run", "swim"):
                    this_cache_prefix = "%s/%s/%s/" % (refresh_token, sport_code, per)
                    for item in stats.keys():
                        if sport_code == sport:
                            stats[item] = data["%s_%s_totals" % (per, sport_code)][item]
                        cache.set(
                            this_cache_prefix + item,
                            str(data["%s_%s_totals" % (per, sport_code)][item]),
                            ttl_seconds = CACHE_TTL,
                        )

    # Configure the display to the user's preferences
    elevu = "m"
    if units.lower() == "imperial":
        if sport == "swim":
            stats["distance"] = round(meters_to_ft(float(stats["distance"])), 0)
            distu = "ft"
        else:
            stats["distance"] = round(meters_to_mi(float(stats["distance"])), 1)
            distu = "mi"
            elevu = "ft"
        stats["elevation_gain"] = round(meters_to_ft(float(stats["elevation_gain"])), 0)
    elif sport != "swim":
        stats["distance"] = round(meters_to_km(float(stats["distance"])), 0)
        distu = "km"
    else:
        distu = "m"

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

    sport_verb = {
        "run": "running",
        "ride": "cycling",
        "swim": "swim",
    }[sport]

    if period == "ytd":
        display_header.append(
            render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [render.Text(" %d %s" % (year, sport_verb.capitalize()), font = "tb-8")],
            ),
        )

    sport_icon = {
        "run": RUN_ICON,
        "ride": RIDE_ICON,
        "swim": SWIM_ICON,
    }[sport]

    # The number of activities and distance traveled is universal, but for cycling the elevation gain is a
    # more interesting statistic than speed so we"ll vary the third item:
    if sport == "ride" and float(stats.get("elevation_gain", 0)) > 0:
        third_stat = {
            "icon": ELEV_ICON,
            "text": "%s %s" % (humanize.comma(float(stats.get("elevation_gain", 0))), elevu),
        }
    else:
        if float(stats.get("distance", 0)) > 0:
            split = float(stats.get("moving_time", 0)) // float(stats.get("distance", 0))
            split = time.parse_duration(str(split) + "s")
            split = format_duration(split)
        else:
            split = "N/A"

        third_stat = {
            "icon": CLOCK_ICON,
            "text": "%s%s" % (split, "/" + distu),
        }

    return render.Root(
        delay = 0,
        child = render.Column(
            expanded = True,
            cross_align = "start",
            main_align = "space_evenly",
            children = [
                render.Row(
                    cross_align = "center",
                    children = display_header,
                ),
                render.Animation(
                    children = [
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Image(src = sport_icon),
                                render.Box(height = 8, width = max(64 - i, 1)),
                                render.Text("%s " % humanize.comma(float(stats.get("count", 0)))),
                                render.Text(actu, font = "tb-8"),
                            ],
                        )
                        for i in range(800)
                    ],
                ),
                render.Animation(
                    children = [
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Image(src = DISTANCE_ICON),
                                render.Box(height = 8, width = max(74 - i, 1)),
                                render.Text("%s " % humanize.comma(float(stats.get("distance", 0)))),
                                render.Text(distu, font = "tb-8"),
                            ],
                        )
                        for i in range(800)
                    ],
                ),
                render.Animation(
                    children = [
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Image(src = third_stat["icon"]),
                                render.Box(height = 8, width = max(84 - i, 1)),
                                render.Text(third_stat["text"]),
                            ],
                        )
                        for i in range(800)
                    ],
                ),
            ],
        ),
    )

def last_activity(config, refresh_token, sport, units):
    show_logo = config.bool("show_logo", True)
    title_font = "CG-pixel-3x5-mono"

    if units == "metric":
        distance_conv = meters_to_km
    else:
        distance_conv = meters_to_mi

    activities = get_activities(config, refresh_token)

    filtered = [a for a in activities["current"] if a["type"].lower() == sport.lower()]
    if not len(filtered):
        filtered = [a for a in activities["previous"] if a["type"].lower() == sport.lower()]
    if not len(filtered):
        # Skip display if the athlete has no activities in the past 2 months
        print("No recent %ss found" % sport)
        return []
    display_activity = filtered[-1]

    map_info = display_activity.get("map", {})
    polyline = map_info.get("summary_polyline", map_info.get("polyline", None))
    title = []
    title_width = 64
    if show_logo:
        sport_icon = {
            "run": RUN_ICON,
            "ride": RIDE_ICON,
            "swim": SWIM_ICON,
        }[sport]
        title_width -= 10
        title.append(
            render.Image(src = sport_icon),
        )

    total_time = format_duration(
        time.parse_duration("%ss" % display_activity.get("moving_time", 0)),
        resolution = "hours",
    )

    if display_activity.get("display_hide_heartrate_option", False) or (
        not display_activity.get("has_heartrate") or display_activity.get("average_heartrate", 0) == 0
    ):
        if sport == "ride" and display_activity.get("average_watts", 0) > 0:
            work_stat = {
                "icon": WATTS_ICON,
                "value": display_activity.get("average_watts"),
            }
        else:
            work_stat = {
                "icon": KCAL_ICON,
                "value": kj_to_calories(display_activity.get("kilojoules", 0)),
            }
    else:
        work_stat = {
            "icon": HEART_ICON,
            "value": int(display_activity.get("average_heartrate", 0)),
        }

    elev = display_activity.get("total_elevation_gain", 0)
    if sport == "ride":
        if units == "imperial":
            elev = meters_to_ft(elev)

    if float(display_activity.get("distance", 0)) > 0:
        distance = distance_conv(float(display_activity.get("distance", 1)))
        split = float(display_activity.get("moving_time", 0)) / distance
        split = time.parse_duration(str(split) + "s")
        split = format_duration(split)
    else:
        split = "N/A"

    pace_stat = render.Column(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text("Pace", color = "#fc4c02", font = title_font),
            render.Text(split, color = "#FFF"),
        ],
    )

    time_stat = render.Column(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text("Time", color = "#fc4c02", font = title_font),
            render.Text(total_time, color = "#FFF"),
        ],
    )

    top_row = [
        time_stat if sport == "ride" else pace_stat,
        render.Box(width = 1, height = 10, color = "#0000"),  # Force spacing + row height to 10px
        render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("Dist", color = "#fc4c02", font = title_font),
                render.Text(
                    humanize.comma(int(distance_conv(display_activity.get("distance", 0)))),
                    color = "#FFF",
                ),
            ],
        ),
    ]

    render_layers = []

    # This gives better spacing if there is no map
    stat_spacing = "space_around"

    if polyline:
        coordinates = decode_polyline(polyline)

        # Slight rotation helps certain routes fit better on the screen
        degrees_rotation = 15
        theta = math.radians(degrees_rotation)
        coordinates = [
            (
                math.cos(theta) * y + math.sin(theta) * x,
                math.cos(theta) * x - math.sin(theta) * y,
            )
            for x, y in coordinates
        ]

        render_layers.append(
            render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Stack(
                        children = [
                            render.Row(
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Plot(
                                        data = coordinates,
                                        width = 32,
                                        height = 32,
                                        color = "#6d6d7833",
                                    ),
                                ],
                            ),
                            render.Row(
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Animation(
                                        children = list([
                                            render.Plot(
                                                data = coordinates[i:i + 2],
                                                width = 32,
                                                height = 32,
                                                color = "#ffa078",
                                                x_lim = (min([x for x, _ in coordinates]), max([x for x, _ in coordinates])),
                                                y_lim = (min([y for _, y in coordinates]), max([y for _, y in coordinates])),
                                            )
                                            for i, _ in enumerate(coordinates)
                                        ]),
                                    ),
                                ],
                            ),
                            render.Row(
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Animation(
                                        children = list([
                                            render.Plot(
                                                data = coordinates[i - 1:i + 1],
                                                width = 32,
                                                height = 32,
                                                color = "#fc4c02",
                                                x_lim = (min([x for x, _ in coordinates]), max([x for x, _ in coordinates])),
                                                y_lim = (min([y for _, y in coordinates]), max([y for _, y in coordinates])),
                                            )
                                            for i, _ in enumerate(coordinates)
                                        ]),
                                    ),
                                ],
                            ),
                            render.Row(
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Animation(
                                        children = list([
                                            render.Plot(
                                                data = coordinates[0:i + 1],
                                                width = 32,
                                                height = 32,
                                                color = "#fc4c0277",
                                                x_lim = (min([x for x, _ in coordinates]), max([x for x, _ in coordinates])),
                                                y_lim = (min([y for _, y in coordinates]), max([y for _, y in coordinates])),
                                            )
                                            for i, _ in enumerate(coordinates)
                                        ]),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

        stat_spacing = "space_between"
    else:
        top_row.extend(
            [
                render.Box(width = 1, height = 10, color = "#0000"),  # Force spacing + row height to 10px
                pace_stat if sport == "ride" else time_stat,
            ],
        )

    render_layers.append(
        render.Column(
            expanded = True,
            main_align = "start",
            children = [
                # Top Row (Time/Distance)
                render.Row(
                    expanded = True,
                    main_align = stat_spacing,
                    cross_align = "center",
                    children = top_row,
                ),
                # Middle Row
                render.Row(
                    expanded = True,
                    main_align = stat_spacing,
                    cross_align = "center",
                    children = [
                        render.Row(
                            cross_align = "center",
                            main_align = stat_spacing,
                            children = [
                                render.Image(PR_ICON),
                                render.Text(" " + humanize.comma(display_activity.get("pr_count", 0))),
                            ] if display_activity.get("pr_count", 0) > 0 else [
                                render.Box(width = 1, height = 10, color = "#0000"),
                            ],
                        ),
                        render.Box(width = 1, height = 10, color = "#0000"),  # Force spacing & height to 10px
                        render.Row(
                            cross_align = "center",
                            main_align = stat_spacing,
                            children = [
                                render.Text(" " + humanize.comma(display_activity.get("kudos_count"))),
                                render.Image(KUDOS_ICON),
                            ] if display_activity.get("kudos_count", 0) > 0 else [
                                render.Box(width = 1, height = 10, color = "#0000"),
                            ],
                        ),
                    ],
                ),
                # Bottom Row
                render.Row(
                    expanded = True,
                    main_align = stat_spacing,
                    cross_align = "center",
                    children = [
                        render.Row(
                            cross_align = "center",
                            main_align = stat_spacing,
                            children = [
                                render.Image(ACHIEVEMENT_ICON),
                                render.Text(" " + humanize.comma(display_activity.get("achievement_count"))),
                            ] if display_activity.get("achievement_count", 0) > 0 else [
                                render.Image(ELEV_ICON),
                                render.Text(" " + humanize.comma(int(elev))),
                            ] if elev > 0 else [
                                render.Box(width = 1, height = 10, color = "#0000"),
                            ],
                        ),
                        render.Box(width = 1, height = 10, color = "#0000"),  # Force spacing & row height to 10px
                        render.Row(
                            cross_align = "center",
                            main_align = stat_spacing,
                            # This is either the avg HR or calories burned
                            children = [
                                render.Text(humanize.comma(int(work_stat["value"]))),
                                render.Image(work_stat["icon"]),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

    return render.Root(
        delay = 0,
        child = render.Stack(
            children = render_layers,
        ),
    )

def get_activities(config, refresh_token):
    max_activities = 200

    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    beg_curr_month = time.time(year = now.year, month = now.month, day = 1)
    _next_month = time.time(year = now.year, month = now.month, day = 32)

    end_prev_month = beg_curr_month - time.parse_duration("1ns")
    beg_prev_month = time.time(year = end_prev_month.year, month = end_prev_month.month, day = 1)

    if not refresh_token:
        activities = {
            "current": [],
            "previous": [],
        }
    else:
        access_token = cache.get(refresh_token)
        if not access_token:
            print("Generating new access token")
            access_token = get_access_token(refresh_token)

        headers = {
            "Authorization": "Bearer %s" % access_token,
        }

        # To help reduce the number of API calls we need, I'm querying both months together (current/prev commented)
        # The consequence here is if the athlete completed more than 200 activities in the last 2 months we'll miss some
        urls = {
            "last-2": "%s/athlete/activities?after=%s&per_page=%s" % (STRAVA_BASE, beg_prev_month.unix, max_activities),
            # "current": "%s/athlete/activities?after=%s&per_page=%s" % (STRAVA_BASE, beg_curr_month.unix, max_activities),
            # "previous": "%s/athlete/activities?after=%s&before=%s&per_page=%s" % (STRAVA_BASE, beg_prev_month.unix, end_prev_month.unix, max_activities),
        }

        activities = {}

        for query, url in urls.items():
            cache_id = "%s/xactivity/%s/%s-%s" % (refresh_token, query, now.year, now.month)
            data = cache.get(cache_id)

            if not data:
                print("Getting %s month activities. %s" % (query, url))
                response = http.get(url, headers = headers)
                if response.status_code != 200:
                    text = "code %d, %s" % (response.status_code, json.decode(response.body()).get("message", ""))
                    return display_failure("Strava API failed, %s" % text)
                data = response.json()
                cache.set(cache_id, json.encode(data), ttl_seconds = CACHE_TTL)
            else:
                print("Returning cached %s month activities." % query)
                data = json.decode(data)

            activities[query] = data

    # Sort each list chronologically
    for query in activities.keys():
        activities[query] = sorted(activities[query], key = lambda x: x["start_date"])

    # Per above, split list into current and previous month
    activities["current"] = [a for a in activities["last-2"] if time.parse_time(a["start_date"]) >= beg_curr_month]
    activities["previous"] = [a for a in activities["last-2"] if time.parse_time(a["start_date"]) < beg_curr_month]
    activities.pop("last-2", None)

    return activities

def decode_polyline(polyline_str):
    """
    Converts a compressed series of GPS coordinates (i.e. Polyline) back into coordinates that we can plot.

    Implementation borrowed from https://github.com/geodav-tech/decode-google-maps-polyline

    :param polyline_str: Compressed coordinates as a string
    :return: list of tuples: latitude, longitude
    """
    index, lat, lng = 0, 0, 0
    coordinates = []
    changes = {"latitude": 0, "longitude": 0}

    # Coordinates have variable length when encoded, so just keep
    # track of whether we've hit the end of the string. In each
    # pseudo-while loop iteration, a single coordinate is decoded.
    for _ in range(int(1e10)):
        if index >= len(polyline_str):
            break

        # Gather lat/lon changes, store them in a dictionary to apply them later
        for unit in ["latitude", "longitude"]:
            shift, result = 0, 0

            for _ in range(len(polyline_str)):
                if index >= len(polyline_str):
                    break
                byte = ord(polyline_str[index]) - 63
                index += 1
                result |= (byte & 0x1f) << shift
                shift += 5
                if not byte >= 0x20:
                    break

            if result & 1:
                changes[unit] = ~(result >> 1)
            else:
                changes[unit] = (result >> 1)

        lat += changes["latitude"]
        lng += changes["longitude"]

        coordinates.append((lat / 100000.0, lng / 100000.0))

    return coordinates

def kj_to_calories(kj):
    return float(kj) / 4.184

def meters_to_mi(m):
    return m * 0.00062137

def meters_to_km(m):
    return m // 1000

def meters_to_ft(m):
    return m * 3.280839895

def round(num, precision):
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def format_duration(d, resolution = "minutes"):
    if resolution == "minutes":
        m = int(d.minutes)
        s = str(int((d.minutes - m) * 60))
        m = str(m)
        if len(s) == 1:
            s = "0" + s
        return "%s:%s" % (m, s)

    elif resolution == "hours":
        h = int(d.hours)
        m = str(int((d.hours - h) * 60))
        m = str(m)
        if len(m) == 1:
            m = "0" + m
        return "%s:%s" % (h, m)

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

    screen_options = [
        schema.Option(value = "all", display = "All-time stats"),
        schema.Option(value = "ytd", display = "YTD stats"),
        schema.Option(value = "progress_chart", display = "Monthly progress"),
        schema.Option(value = "last_activity", display = "Last activity"),
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
                    "read,activity:read",
                ],
            ),
            schema.Dropdown(
                id = "sport",
                name = "Activity type",
                desc = "Runs, rides or swims are all supported!",
                icon = "running",
                options = sport_options,
                default = "ride",
            ),
            schema.Dropdown(
                id = "units",
                name = "Distance units",
                desc = "Imperial displays miles and feet, metric displays kilometers and meters.",
                icon = "pencilRuler",
                options = units_options,
                default = DEFAULT_UNITS,
            ),
            schema.Dropdown(
                id = "display_type",
                name = "Screen type",
                desc = "Show your cumulative stats or a progress chart.",
                icon = "userClock",
                options = screen_options,
                default = DEFAULT_SCREEN,
            ),
            schema.Toggle(
                id = "show_logo",
                name = "Logo/Icon",
                desc = "Whether to display the Strava logo, or the sport icon on progress charts.",
                icon = "cog",
                default = True,
            ),
        ],
    )
