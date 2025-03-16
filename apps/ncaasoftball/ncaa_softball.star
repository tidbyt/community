"""
Applet: NCAA Softball
Summary: Shows NCAA Softball Scores
Description: Displays current NCAA Softball Scores.
Author: Jake Manske
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/Chicago"
DEFAULT_RELATIVE = "relative"
FIVE_WIDE_FONT = "CG-pixel-4x5-mono"
SMALL_FONT = "CG-pixel-3x5-mono"
MEDIUM_FONT = "5x8"
LARGE_FONT = "6x13"
DEFAULT_HOUR_TO_SWITCH = "10"
SMALL_FONT_COLOR = "#39FF14"
INNING_COLOR = "#ffd500"
GRAY_COLOR = "808080"
DEFAULT_TEAM = "514"
LIME_GREEN = "32CD32"
LOGO_TTL = 604800  # cache logos and team information for a week

LEAGUE_IMAGE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACSElEQVRYCcVWO0sDQRDeM0HBUkTQRq1UbIKN4DOFpLCzszCiiAQLwQcWlqkMqKS1iaJiSGcjCFqIMRECSiIIlr4IFvkDFkLcuTDL3t3u3d7l4BbCPmbm+76dnd0LIQE3zY6/Tpud3atNow1jwziQ9Vr8RmbytF4/jxniWgyzACYsFSLuQI+Akj9rQ/MiXU2t1d9yqzyANAOwezsBFEjHsfPhiWAMMXwBwppjEYKTuelAPmXHdRH6SQ4bcy0AgkAE/PxoUgEf1ZoF/z6zSdycuQVAsCAUAAXYP7MucG/sfmvv2LWQ9O6ipQCBQHgLZDcAMjA1NioUBov5xxKzzyZS5DpfYb567XBPMBo83QIM9uM4hEeABHa9H+SA70rA9EpaTzMEjo8MQNd0EwrIXhUdgQsXSUcfFQdLEcoKEMF+K2ekra0Vp0q34e81S8LhkIULQIQZYOimAdwCJIeK/67+KD1IoZCcRvkW5PYTTA4W4MPJNnn//Gp8ZDx+G+TSGF1j0N3Rrg+QHCaTy4cECrNYeiKQHS/Ps1IGABwakInaxNKBvlw43XGdDUNh0AKM0h3e8SRALiPm/fjxRjxG5qLDLI5m5oU+ghHeB8dmAYY/IV7IERh72ROMdmkN+EGOJHa9bQbsAlVtThlQKkIkiwz2kfJlCqd6z98Kg0FxoiSAu141WkxdPDa8nDA/yt2StWSGNymNmQDzE8yRCv9IIDoVxI4RxWBWens6wW0BfUW9JRideGBcU+1RCPgr4/BBqkROfhSz7OQTuP0fIQDMDdlHqmUAAAAASUVORK5CYII=""")
LEAGUE_IMAGE_SMALL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAAFAAAAACy3fD9AAABGUlEQVQ4EaVUsRHCMAy0OY6DUZiAOwrosgANDRUTMAkT0EABDQukg4I7KjrYhJKQd5BjFFlJQEVsSa/3y/LFGmZZbizU2LW5dSW0XaRSWI1lu8TlLUf9qhDqwCUrHM75OaqfPQ4+3/G7fAN1lpEBHBaEeGkvKiQgiPgBlIutXwolUBt1qFcVAnBMr2LLpPwzC0Cd1RLOkpHa9uu+NzRhMKotny/X4tgWX08oTZh42tyjJ6RiaYXSpqTROzxtVmYyLu8PfpNnJCpEMYwmif10uXY+5RBzB7AxVxSiAMUxQy4k5Tj/c9CGwovIjyqMkT1vWzPo91x92D4RSmulZYBoouGDxaHI1RG7lgmMAlhIVETKb4jVcGXFn7s3edJn78il6MYAAAAASUVORK5CYII=""")
TBD = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAcITNaAAACMElEQVQ4Ea1VS08aURg9DJLgAjSlO2lCYFU3ulGsVVxJF3bThzzs71Ns4iNtd1i7aH0EKivazVSQPQseC0QkofN94d7OzL3UadKbMHO/c849nHtn+PABGFmf/z6m3I4Xl5e4uWm4YQQCAQyHQ4xGao5nK0nE43HHGp9VsfLg4BB3gwGTqfU1RKNRh3BSUSqVUavXmQ4Gg3jz+hXPZWIy3cnnGLyqVPD129kkLwf+fHUVyeQyY3uFfckZcjaefPj4Cab5yw1PrFvtlpZTjHu9nlaoA+fnn2JxYQGnp18UWh6FYHQPR3D2uzg22v70dNBO8VxJrCg0ACWlIc709ravqJTEisIF2JO6KEfJiU3TdICTCndSna7T6TDMib9fVTA7M4NWu63TMuYlqWEYKBZPWC/PeM36UZyfX2iNvSSt1epYsd7nwf290zgcCqHb7SrGlJReKfGgFMEYKJXLiMVikpaJJWKbeEkq5IaPusOfIY0pEaXz+/3Mek1K4kjkEXK5LO9qaryejd/t5Nms0Wggm9nGvySlhS/SaVxf19gjm83wXXY3qnb3CgxS2ofOlIThcAgvt7akVgQkzmFMwOHRMfr9vux0ui/wWeeZt7ZOg/gnVotNpda5FhfFmAjRm5PLS0gkEtzcC/vveQ3thka1WkX1x09E5+awsZFizH7RGguBOJrHkQjS6U2Gj45pR3ewN3Wht9//akzCZrOJ4sln+xpktt/yX5UDdBUPGrv0nsvfi8q9TL/nAOUAAAAASUVORK5CYII=""")
OK = 200
DATA_URL = "https://site.api.espn.com/apis/site/v2/sports/baseball/college-softball/scoreboard"
TEAMS_URL = "https://site.api.espn.com/apis/site/v2/sports/baseball/college-softball/teams/{0}"
TEAM_SCHED_URL = "https://site.api.espn.com/apis/site/v2/sports/baseball/college-softball/teams/{0}/schedule"
LOGO_BASE_URL = "https://a.espncdn.com/i/teamlogos/ncaa/500-dark/{0}.png"

def get_config(config):
    return struct(
        Timezone = config.get("$tz", DEFAULT_TIMEZONE),
        Team = config.str("team", DEFAULT_TEAM),
        SwitchHour = int(config.str("hour", DEFAULT_HOUR_TO_SWITCH)),
        GameTime = config.str("game_time", DEFAULT_RELATIVE),
        Top25 = config.bool("top_25", True),
    )

def main(config):
    cfg = get_config(config)

    # figure out what date to filter to based on config
    current_hour = get_now(cfg.Timezone).hour
    if current_hour < cfg.SwitchHour:
        date = get_yesterday_date(cfg.Timezone)
    else:
        date = get_now(cfg.Timezone)

    # query_params: dates in YYYYMMDD
    date = str(humanize.time_format("yyyyMMdd", date))
    query_params = {
        "dates": date,
    }

    # this is the URL we get game information from, so cache for 20 seconds
    response = http.get(DATA_URL, params = query_params, ttl_seconds = 20)

    # check response quit with rest screen if we failed
    if response.status_code != OK:
        return render.Root(
            child = render_error(response),
        )

    # loop through events to find an event for our team
    events = []
    for event in response.json().get("events"):
        added = False
        for competitor in event.get("competitions")[0].get("competitors"):
            # if we are in top 25 mode, check if one of the competitors is ranked
            if cfg.Top25:
                if competitor.get("curatedRank") != None:
                    events.append(event)
                    added = True
                    break
                if added:
                    break
            elif cfg.Team == competitor.get("team").get("id"):
                events.append(event)
                break  # don't check the other competitor if we found ours

    # if we did not get an event for our team, get the next game from schedule
    # only do this if we are trying to get games for a specific team
    # it will be the first game where the difference between "now" and gametime is negative
    if len(events) == 0 and not cfg.Top25:
        response = http.get(TEAM_SCHED_URL.format(cfg.Team), ttl_seconds = 6000)

        # check response quit with rest screen if we failed
        if response.status_code != OK:
            return render.Root(
                child = render_error(response),
            )
        now = get_now(cfg.Timezone)
        for event in response.json().get("events"):
            game_time = get_game_time(event, cfg.Timezone)
            time_to_game = game_time - now
            if time_to_game > time.parse_duration("0s"):
                events.append(event)
                break

    # if we still have no event, there is nothing on the schedule
    # render zero-state
    if len(events) == 0:
        return render.Root(
            child = render_no_games(cfg),
        )

    children = []
    for event in events:
        children.append(render_event(cfg, event))

    # show each game for at least one second
    # in top 25 mode, there can be more than 15 games we want to show
    delay = int(15000 / len(children))
    delay = 1000 if delay < 1000 else delay
    return render.Root(
        delay = delay,
        show_full_animation = True,
        child = render.Animation(
            children = children,
        ),
    )

def render_event(cfg, event):
    # get home and away competitors
    competition = event.get("competitions")[0]
    home = None
    away = None
    for team in competition.get("competitors"):
        if team.get("homeAway") == "home":
            home = team
        else:
            away = team

    return render.Stack(
        children = [
            render.Column(
                cross_align = "center",
                children = [
                    render_header(away, home),
                    render.Row(
                        children = [
                            render_team(away),
                            render.Box(
                                width = 20,
                                height = 20,
                            ),
                            render_team(home),
                        ],
                    ),
                    render_footer(event, home, away, cfg),
                ],
            ),
            render.Column(
                cross_align = "center",
                children = [
                    render.Box(
                        height = 5,
                    ),
                    render_state(competition),
                ],
            ),
        ],
    )

def render_no_games(cfg):
    widget = None
    if cfg.Top25:
        widget = render.WrappedText(
            align = "center",
            content = "TOP 25 TEAMS NOT ON SCHED TODAY",
            font = FIVE_WIDE_FONT,
            color = INNING_COLOR,
            linespacing = 1,
        )
    else:
        widget = render.Column(
            cross_align = "center",
            children = [
                render_team_from_id(cfg.Team, 27),
                render.Text(
                    color = INNING_COLOR,
                    font = SMALL_FONT,
                    content = "NO GAMES",
                ),
            ],
        )
    return render.Row(
        children = [
            render.Image(
                src = LEAGUE_IMAGE,
                width = 32,
            ),
            widget,
        ],
    )

def render_header(away, home):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render_team_and_rank(away),
            render_team_and_rank(home),
        ],
    )

def render_team_and_rank(team):
    rank = int(team.get("curatedRank").get("current")) if team.get("curatedRank") != None else 0
    abbrev = team.get("team").get("abbreviation") or "TBD"
    array = []
    if rank > 0:
        array.append(
            render.Text(
                content = str(rank),
                font = SMALL_FONT,
                color = LIME_GREEN,
            ),
        )
    array.append(
        render.Row(
            children = [
                render.Box(
                    width = 1 if rank == 0 else 3 * len(str(rank)) + 2,
                    height = 1,
                ),
                render.Text(
                    content = abbrev,
                    font = FIVE_WIDE_FONT,
                ),
            ],
        ),
    )
    return render.Stack(
        children = array,
    )

def render_error(response):
    msg = "HTTP ERROR CODE {0}".format(response.status_code)
    return render.Row(
        children = [
            render.Image(
                src = LEAGUE_IMAGE,
            ),
            render.WrappedText(
                align = "center",
                content = msg,
                font = SMALL_FONT,
                color = INNING_COLOR,
                linespacing = 1,
            ),
        ],
    )

def render_footer(event, home, away, cfg):
    # if the game is not in progress, tell them when it is going to happen
    # if we do not have stats, sometimes this will not update until the end of the game
    state = event.get("competitions")[0].get("status").get("type")
    desc = state.get("description")
    if desc == "Scheduled":
        time_to_game = get_time_to_game(event, cfg.Timezone, cfg.GameTime)

        return render.Text(
            content = time_to_game.Message,
            font = FIVE_WIDE_FONT,
            color = INNING_COLOR,
        )

    # if the game has been canceled or postponed
    if desc == "Canceled" or desc == "Postponed":
        return render.Text(
            content = desc,
            font = FIVE_WIDE_FONT,
            color = INNING_COLOR,
        )

    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render_linescore(away),
            render_linescore(home),
        ],
    )

##################
# TIME FUNCTIONS #
##################
def get_yesterday_date(timezone):
    return get_now(timezone) - time.parse_duration("86400s")

def get_now(timezone):
    return time.now().in_location(timezone)

def get_date(timestamp):
    month = str(timestamp.month)
    day = str(timestamp.day)
    month = "0" + month if len(month) == 1 else month
    day = "0" + day if len(day) == 1 else day
    return str(timestamp.year) + "-" + month + "-" + day

def get_game_time(event, timezone):
    return time.parse_time(event.get("date").replace("Z", ":00Z")).in_location(timezone)

def get_time_to_game(event, timezone, relative_or_absolute):
    # if start time is in the past, say "starting now"
    game_time = get_game_time(event, timezone)

    time_to_game = get_now(timezone) - game_time

    if time_to_game > time.parse_duration("0s"):
        return struct(Imminent = True, Message = "in progress")

    if relative_or_absolute == "relative":
        # otherwise say how close to the game we are
        relative = humanize.time(game_time).split(" ")

        # don't crash if we don't have the length we are expecting
        if len(relative) < 2:
            return struct(Imminent = True, Message = "in progress")
        return struct(Imminent = False, Message = "in " + relative[0] + " " + relative[1])
    else:
        nice_time = humanize.time_format("M/d K:mm", game_time)
        hour = game_time.hour
        if hour >= 12:
            meridiem = "PM"
        else:
            meridiem = "AM"
        return struct(Imminent = False, Message = str(nice_time + meridiem))

def render_state(competition):
    situation = competition.get("situation")
    status = competition.get("status")

    state = status.get("type")
    inning = int(status.get("period"))

    # if the game is over, indicate it is a final
    if state.get("completed"):
        return render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Text(
                content = "F/" + str(inning),
                font = LARGE_FONT if inning < 10 else MEDIUM_FONT,
                color = INNING_COLOR,
            ),
        )

    # if the game is suspended, indicate that
    if state.get("description") == "Suspended":
        return render.WrappedText(
            align = "center",
            content = "SUSP",
            font = FIVE_WIDE_FONT,
            width = 20,
            linespacing = 1,
            color = INNING_COLOR,
        )

    # otherwise render the current situation, if we have stats
    # not every game gets live updates, so we have to switch on whether we actually have them
    if situation == None:
        return render.Padding(
            pad = (0, 2, 0, 0),
            child = render.Image(
                src = LEAGUE_IMAGE_SMALL,
            ),
        )
    is_top = state.get("detail").split(" ")[0] == "Top"
    array = []
    array.append(
        render.Row(
            children = [
                render.Text(
                    content = str(inning),
                    font = MEDIUM_FONT,
                    color = INNING_COLOR,
                ),
                render.Padding(
                    pad = (0, 1 if is_top else 4, 0, 0),
                    child = render.Image(
                        src = TOP_INNING if is_top else BOTTOM_INNING,
                    ),
                ),
            ],
        ),
    )
    array.append(render_bases(situation))
    array.append(
        render.Box(
            width = 1,
            height = 1,
        ),
    )
    if situation.get("outs") != None:
        outs = int(situation.get("outs"))
    else:
        outs = 0
    array.append(
        render_current_outs(outs),
    )

    # TODO: conditionally render count if we are getting updates
    return render.Column(
        main_align = "end",
        cross_align = "center",
        children = array,
    )

def team_is_tbd(id):
    return id == "1195" or id == "1196" or id == None

def render_team_from_id(id, dim):
    # handle TBD separately
    if team_is_tbd(id):
        logo = TBD
        color = "FFFFFF"
    else:
        info = TEAMS.get(id)
        logo_url = None

        # if it is not a curated team, hit the API to get team info
        if info == None:
            response = http.get(TEAMS_URL.format(id), ttl_seconds = LOGO_TTL)

            # if we fail here, return the TBD team
            if response.status_code != OK:
                logo = TBD
                color = "FFFFFF"
            else:
                info = response.json().get("team")
                color = info.get("color") or "000000"
                for logo in info.get("logos"):
                    for rel in logo.get("rel"):
                        if rel == "dark":
                            logo_url = logo.get("href")
        else:
            logo_url = LOGO_BASE_URL.format(info.Logo)
            color = info.Color

        if logo_url != None:
            response = http.get(logo_url, ttl_seconds = LOGO_TTL)

            # if we fail here, return the TBD team
            if response.status_code != OK:
                logo = TBD
                color = "FFFFFF"
            else:
                logo = response.body()
        else:
            logo = TBD
            color = "FFFFFF"

    return render.Box(
        height = dim,
        width = dim,
        color = color,
        child = render.Image(
            src = logo,
            width = dim,
        ),
    )

def render_team(team):
    id = team.get("id")
    return render_team_from_id(id, 22)

def get_linescore_item(team, item):
    obj = team.get(item)
    if type(obj) == "dict":
        return obj.get("displayValue")
    if obj == None:
        return "X"
    return str(int(obj))

def get_runs(team):
    return get_linescore_item(team, "score")

def get_hits(team):
    return get_linescore_item(team, "hits")

def get_errors(team):
    return get_linescore_item(team, "errors")

def render_linescore(team):
    runs = get_runs(team)
    hits = get_hits(team)
    errors = get_errors(team)

    # dynamically size linescore font based on whether runs OR hits are double digits
    if len(runs) >= 2 or len(hits) >= 2:
        font = SMALL_FONT
    else:
        font = FIVE_WIDE_FONT
    return render.Row(
        children = [
            render.Text(
                font = font,
                content = runs,
            ),
            render_separator(),
            render.Box(
                height = 1,
                width = 1,
            ),
            render.Text(
                font = font,
                content = hits,
                color = GRAY_COLOR if hits == "X" else "FFFFFF",
            ),
            render_separator(),
            render.Box(
                height = 1,
                width = 1,
            ),
            render.Text(
                font = font,
                content = errors,
                color = GRAY_COLOR if errors == "X" else "FFFFFF",
            ),
        ],
    )

def render_separator():
    return render.Box(
        height = 5,
        width = 1,
        color = "373737",
    )

NO_OUT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAABAAAAADFbP4CAAAAG0lEQVQIHWNgAIL/UABigzlgBpTNBOOg0MhaAHFBF+usLcu4AAAAAElFTkSuQmCC
""")
OUT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAABAAAAADFbP4CAAAAIElEQVQIHWNgAIL/UABis4DYD8XtQWywBBOYhU4gawEAqVoZJnsyPbsAAAAASUVORK5CYII=
""")
EMPTY_BASE_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABaADAAQAAAABAAAABQAAAAB/qhzxAAAAIUlEQVQIHWNggIL/QABjg2mYAIxmgDPQdcAkYDTcGGQBAIozH+GWL3b+AAAAAElFTkSuQmCC
""")
OCCUPIED_BASE_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABaADAAQAAAABAAAABQAAAAB/qhzxAAAAMElEQVQIHWNggIL/QABjM4EYIIGN6hAaxGeECYA4IOB/E0KDVW5QA0kjjABLIQsAANZAIZSR/thKAAAAAElFTkSuQmCC
""")
TOP_INNING = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAADCAYAAABbNsX4AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABaADAAQAAAABAAAAAwAAAADw6ulRAAAAHklEQVQIHWNggIL/yxj+w9iMIAaKQBQDIyOyAEwlACNfCEuRARSZAAAAAElFTkSuQmCC
""")

BOTTOM_INNING = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAADCAYAAABbNsX4AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABaADAAQAAAABAAAAAwAAAADw6ulRAAAAHUlEQVQIHWP8v4zhPwMaYATxkSUYoxjAYmB1yBIAI4kISyv4fA4AAAAASUVORK5CYII=
""")

def render_bases(situation):
    first = OCCUPIED_BASE_IMG if situation.get("onFirst") else EMPTY_BASE_IMG
    second = OCCUPIED_BASE_IMG if situation.get("onSecond") else EMPTY_BASE_IMG
    third = OCCUPIED_BASE_IMG if situation.get("onThird") else EMPTY_BASE_IMG

    return render.Stack(
        children = [
            render.Row(
                children = [
                    render.Box(
                        height = 4,
                        width = 3,
                    ),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Image(
                                src = second,  # second base
                            ),
                        ],
                    ),
                ],
            ),
            render.Padding(
                pad = (0, 4, 0, 0),
                child = render.Row(
                    children = [
                        render.Image(
                            src = third,  # third base
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                        ),
                        render.Image(
                            src = first,  # first base
                        ),
                    ],
                ),
            ),
        ],
    )

def render_current_outs(number_of_outs):
    if number_of_outs == 0 or number_of_outs > 2:
        children = render_outs(NO_OUT, NO_OUT)
    elif number_of_outs == 1:
        children = render_outs(OUT, NO_OUT)
    else:
        children = render_outs(OUT, OUT)
    return render.Row(
        children = children,
    )

def render_outs(one_out, two_out):
    return [
        render.Image(
            src = one_out,
        ),
        render.Box(
            width = 1,
            height = 1,
        ),
        render.Image(
            src = two_out,
        ),
    ]

def render_rainbow_word(word, font):
    colors = ["#e81416", "#ffa500", "#faeb36", "#79c314", "#487de7", "#4b369d", "#70369d"]
    return render_flashy_word(word, font, colors, 1)

def render_flashy_word(word, font, colors, repeater):
    widgets = []
    flash_list = []

    # set up the color list
    for color in colors:
        for _ in range(repeater):
            flash_list.append(color)

    ranger = len(flash_list)

    for j in range(ranger):
        flashy_word = []
        for i in range(len(word)):
            letter = render.Text(
                content = word[i],
                font = font,
                color = flash_list[(j + i) % ranger],
            )
            flashy_word.append(letter)
        widgets.append(
            render.Row(
                children = flashy_word,
            ),
        )
    return render.Animation(
        children = widgets,
    )

def get_schema():
    hour_options = []
    for hour in [4, 5, 6, 7, 8, 9, 10, 11, 12]:
        hour_options.append(
            schema.Option(
                display = str(hour),
                value = str(hour),
            ),
        )
    team_options = []
    for team in TEAMS.items():
        # filter out "TBD"
        if not team_is_tbd(team[0]):
            team_options.append(
                schema.Option(
                    display = team[1].Name,
                    value = team[0],
                ),
            )
    game_time_options = []
    game_time_options.append(
        schema.Option(
            display = "Relative",
            value = "relative",
        ),
    )
    game_time_options.append(
        schema.Option(
            display = "Absolute",
            value = "absolute",
        ),
    )
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "top_25",
                name = "Top 25",
                desc = "Display today's games for the top 25 ranked teams.",
                icon = "mountain",
                default = False,
            ),
            # TODO: make this a generated field that only appears when top 25 mode is off
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "College Softball team to follow.",
                icon = "baseballBatBall",
                options = team_options,
                default = DEFAULT_TEAM,  # RUTGERS
            ),
            schema.Dropdown(
                id = "hour",
                name = "Hour of the Day",
                desc = "The hour of the day to switch from yesterday's result to upcoming game.",
                icon = "clock",
                options = hour_options,
                default = DEFAULT_HOUR_TO_SWITCH,
            ),
            schema.Dropdown(
                id = "game_time",
                name = "Relative or Absolute",
                desc = "Whether to display the upcoming game time in relative or absolute terms.",
                icon = "hourglass",
                options = game_time_options,
                default = DEFAULT_RELATIVE,
            ),
        ],
    )

def struct_team_def(name, abbrev, logo, color, id, conference):
    return struct(Name = name, Abbreviation = abbrev, Logo = logo, Color = color, Id = id, Conference = conference)

TEAMS = {
    "724": struct_team_def("Idaho State", "IDST", "304", "9E1B32", "724", "32"),
    "560": struct_team_def("Alabama Crimson Tide", "ALA", "333", "9E1B32", "560", "32"),
    "472": struct_team_def("Arizona Wildcats", "ARIZ", "12", "003366", "472", "47"),
    "471": struct_team_def("Arizona State Sun Devils", "ASU", "9", "8C1D40", "471", "47"),
    "470": struct_team_def("Arkansas Razorbacks", "ARK", "8", "9D2235", "470", "32"),
    "467": struct_team_def("Auburn Tigers", "AUB", "2", "0C2340", "467", "32"),
    "539": struct_team_def("BYU Cougars", "BYU", "252", "002E5D", "539", "45"),
    "533": struct_team_def("Baylor Bears", "BAY", "239", "154734", "533", "45"),
    "498": struct_team_def("Boston College Eagles", "BC", "103", "98002E", "498", "40"),
    "677": struct_team_def("Boston University Terriers", "BU", "104", "000000", "677", "31"),
    "477": struct_team_def("California Golden Bears", "CAL", "25", "003262", "477", "47"),
    "1140": struct_team_def("Clemson Tigers", "CLEM", "228", "F56600", "1140", "40"),
    "505": struct_team_def("Duke Blue Devils", "DUKE", "150", "003087", "505", "40"),
    "487": struct_team_def("Florida Gators", "FLA", "57", "0021A5", "487", "32"),
    "484": struct_team_def("Florida State Seminoles", "FSU", "52", "782F40", "484", "40"),
    "490": struct_team_def("Georgia Bulldogs", "UGA", "61", "BA0C2F", "490", "32"),
    "489": struct_team_def("Georgia Tech Yellow Jackets", "GT", "59", "003057", "489", "40"),
    "536": struct_team_def("Houston Cougars", "HOU", "248", "76232F", "536", "45"),
    "565": struct_team_def("Illinois Fighting Illini", "ILL", "356", "13294B", "565", "49"),
    "648": struct_team_def("Indiana Hoosiers", "IU", "84", "990000", "648", "49"),
    "579": struct_team_def("Iowa Hawkeyes", "IOWA", "2294", "000000", "579", "49"),
    "727": struct_team_def("Iowa State Cyclones", "ISU", "66", "C8102E", "727", "45"),
    "580": struct_team_def("Kansas Jayhawks", "KU", "2305", "0051BA", "580", "45"),
    "494": struct_team_def("Kentucky Wildcats", "UK", "96", "000066", "494", "32"),
    "497": struct_team_def("LSU Tigers", "LSU", "99", "461D7C", "497", "32"),
    "556": struct_team_def("Louisiana Ragin' Cajuns", "UL", "309", "CE181E", "556", "31"),
    "495": struct_team_def("Louisville Cardinals", "LOU", "97", "AD0000", "495", "40"),
    "499": struct_team_def("Maryland Terrapins", "MD", "120", "E03A3E", "499", "49"),
    "501": struct_team_def("Michigan Wolverines", "MICH", "130", "00274C", "501", "49"),
    "500": struct_team_def("Michigan State Spartans", "MSU", "127", "18453B", "500", "49"),
    "502": struct_team_def("Minnesota Golden Gophers", "MINN", "135", "7A0019", "502", "49"),
    "562": struct_team_def("Mississippi State Bulldogs", "MSST", "344", "660000", "562", "32"),
    "503": struct_team_def("Missouri Tigers", "MIZ", "142", "000000", "503", "32"),
    "507": struct_team_def("NC State Wolfpack", "NCSU", "152", "CC0000", "507", "40"),
    "511": struct_team_def("Nebraska Cornhuskers", "NEB", "158", "E41C38", "511", "49"),
    "508": struct_team_def("North Carolina Tar Heels", "UNC", "153", "7BAFD4", "508", "40"),
    "765": struct_team_def("Northwestern Wildcats", "NU", "77", "4E2A84", "765", "49"),
    "493": struct_team_def("Notre Dame Fighting Irish", "ND", "87", "0C2340", "493", "40"),
    "520": struct_team_def("Ohio State Buckeyes", "OSU", "194", "BB0000", "520", "49"),
    "524": struct_team_def("Oklahoma Sooners", "OU", "201", "841617", "524", "45"),
    "522": struct_team_def("Oklahoma State Cowgirls", "OKST", "197", "FF7300", "522", "45"),
    "504": struct_team_def("Ole Miss Rebels", "MISS", "145", "14213D", "504", "32"),
    "636": struct_team_def("Oregon Ducks", "ORE", "2483", "154733", "636", "47"),
    "525": struct_team_def("Oregon State Beavers", "ORST", "204", "DC4405", "525", "47"),
    "768": struct_team_def("Penn State Nittany Lions", "PSU", "213", "041E42", "768", "49"),
    "527": struct_team_def("Pittsburgh Panthers", "PITT", "221", "003594", "527", "40"),
    "601": struct_team_def("Purdue Boilermakers", "PUR", "2509", "373A36", "601", "49"),
    "514": struct_team_def("Rutgers Scarlet Knights", "RUTG", "164", "000000", "514", "49"),
    "605": struct_team_def("South Carolina Gamecocks", "SC", "2579", "000000", "605", "32"),
    "476": struct_team_def("Stanford Cardinal", "STAN", "24", "8C1515", "476", "47"),
    "793": struct_team_def("Syracuse Orange", "SYR", "183", "000E54", "793", "40"),
    "611": struct_team_def("Tennessee Lady Volunteers", "TENN", "2633", "FF8200", "611", "32"),
    "538": struct_team_def("Texas Longhorns", "TEX", "251", "BF5700", "538", "45"),
    "535": struct_team_def("Texas A&M Aggies", "TA&M", "245", "500000", "535", "32"),
    "559": struct_team_def("Texas State Wildcats", "TXST", "326", "501214", "559", "31"),
    "613": struct_team_def("Texas Tech Red Raiders", "TTU", "2641", "CC0000", "613", "45"),
    "572": struct_team_def("UCF Knights", "UCF", "2116", "BA9B37", "572", "45"),
    "478": struct_team_def("UCLA Bruins", "UCLA", "26", "2D68C4", "478", "47"),
    "540": struct_team_def("Utah Utes", "UTAH", "254", "CC0000", "540", "47"),
    "543": struct_team_def("Virginia Cavaliers", "UVA", "258", "232D4B", "543", "40"),
    "544": struct_team_def("Virginia Tech Hokies", "VT", "259", "630031", "544", "40"),
    "545": struct_team_def("Washington Huskies", "WASH", "264", "4B2E83", "545", "47"),
    "818": struct_team_def("Wisconsin Badgers", "WIS", "275", "C5050C", "818", "49"),
    "1195": struct_team_def("TBD", "TBD", "0", "FFFFFF", "1195", "0"),
    "1196": struct_team_def("TBD", "TBD", "0", "FFFFFF", "1196", "0"),
}
