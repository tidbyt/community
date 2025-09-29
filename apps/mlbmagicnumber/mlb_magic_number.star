"""
Applet: MLB Magic Number
Summary: Display magic number
Description: Displays the magic number or the elimination number of your favorite MLB team.
Author: Jake Manske
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MLB_STANDINGS_URL = "https://statsapi.mlb.com/api/v1/standings"

DEFAULT_TEAM = "158"  # Milwaukee Brewers
COMMON_FONT = "CG-pixel-3x5-mono"
BIG_NUMBER_FONT = "10x20"
BRIGHT_RED = "#FF0000"
DARK_RED = "#8B0000"
HTTP_OK = 200

def main(config):
    team_id = get_team_to_follow(config)

    info = http_get_number(team_id)

    if info.Clinched or info.Magic or info.Eliminated or not info.HasData:
        background_color = TEAM_INFO[team_id].BackgroundColor
        if info.Clinched or info.Magic:
            delay = 100
        else:
            delay = 0
    else:  # if you are in danger of being eliminated, get black background
        background_color = "#000000"
        delay = 100

    return render.Root(
        delay = delay,
        child = render.Row(
            children = [
                render_logo(team_id, 32),
                render.Box(
                    height = 32,
                    width = 32,
                    color = background_color,
                    child = render_number_info(team_id, info),
                ),
            ],
        ),
    )

def render_number_info(team_id, info):
    children = []
    center = False
    if not info.Success:
        children = render_failure(team_id, info.ResponseCode)
        center = True
    elif info.Clinched:
        children = render_clinched()
        center = True
    elif info.Magic:
        children = render_magic(info.Number)
        center = True
    elif info.Eliminated:
        children = render_record(team_id, info.Wins, info.Losses, info.DivisionRank)
        center = False
    elif not info.HasData:
        children = render_no_data(team_id)
        center = True
    else:
        children = render_elim(info.Number)
        center = True
    return render.Column(
        cross_align = "center" if center else "start",
        main_align = "space_between",
        children = children,
    )

def render_no_data(team_id):
    color = TEAM_INFO[team_id].ForegroundColor

    # send back good luck message for upcoming season
    phrase = ["good", "luck", "in", str(time.now().year)]
    widgets = []
    for i in range(len(phrase)):
        widgets.append(
            render.Text(
                content = phrase[i],
                font = COMMON_FONT,
                color = color,
            ),
        )
        widgets.append(
            render.Box(
                height = 1,
            ),
        )
    return widgets

def render_failure(team_id, error_code):
    color = TEAM_INFO[team_id].ForegroundColor
    return [
        render.Image(
            src = MLB_LEAGUE_IMAGE,
            width = 32,
        ),
        render.Text(
            content = "HTTP",
            font = COMMON_FONT,
            color = color,
        ),
        render.Text(
            content = "error",
            font = COMMON_FONT,
            color = color,
        ),
        render.Box(
            height = 1,
        ),
        render.Text(
            content = str(error_code),
            font = COMMON_FONT,
            color = color,
        ),
    ]

def render_magic(number):
    widgets = [
        render.Animation(
            children = render_rainbow_word("magic", COMMON_FONT),
        ),
        render.Box(
            height = 1,
            width = 1,
        ),
        render.Animation(
            children = render_rainbow_word("#", "tb-8"),
        ),
        render.Animation(
            children = render_rainbow_word(str(number), BIG_NUMBER_FONT),
        ),
    ]
    return widgets

def render_clinched():
    widgets = [
        render.Animation(
            children = render_rainbow_word("clinched", COMMON_FONT),
        ),
        render.Box(
            height = 1,
            width = 1,
        ),
        render.Image(
            src = CHECKMARK,
        ),
    ]
    return widgets

def get_team_to_follow(config):
    return int(config.str("team", DEFAULT_TEAM))

def is_response_OK(request):
    return request.status_code == HTTP_OK

def render_logo(team_id, size):
    return render.Image(
        src = TEAM_INFO[team_id].Logo,
        width = size,
    )

def render_rainbow_word(word, font):
    colors = ["#e81416", "#ffa500", "#faeb36", "#79c314", "#487de7", "#4b369d", "#70369d"]
    colors_length = len(colors)
    widgets = []
    for j in range(colors_length):
        rainbow_word = []
        for i in range(len(word)):
            letter = render.Text(
                content = word[i],
                font = font,
                color = colors[(j + i) % colors_length],
            )
            rainbow_word.append(letter)
        widgets.append(
            render.Row(
                children = rainbow_word,
            ),
        )
    return widgets

def render_record(team_id, wins, losses, division_rank):
    win_counter = []
    loss_counter = []
    div_rank_array = []
    text_color = TEAM_INFO[team_id].ForegroundColor
    bg_color = TEAM_INFO[team_id].BackgroundColor

    build_record_arrays(team_id, wins, 0, win_counter, loss_counter, div_rank_array)
    build_record_arrays(team_id, losses, wins, loss_counter, win_counter, div_rank_array)

    # add frames for the division rank
    for j in range(100):
        win_counter.append(
            render.Text(
                content = str(wins),
                font = COMMON_FONT,
                color = text_color,
            ),
        )
        loss_counter.append(
            render.Text(
                content = str(losses),
                font = COMMON_FONT,
                color = text_color,
            ),
        )
        div_rank_array.append(
            render.Text(
                content = str(division_rank),
                color = text_color if j % 30 < 15 else bg_color,
                font = BIG_NUMBER_FONT,
            ),
        )
    widgets = [
        render.Row(
            children = [
                render.Text(
                    content = "W: ",
                    font = COMMON_FONT,
                    color = text_color,
                ),
                render.Animation(
                    children = win_counter,
                ),
            ],
        ),
        render.Box(
            height = 1,
        ),
        render.Row(
            children = [
                render.Text(
                    content = "L: ",
                    font = COMMON_FONT,
                    color = text_color,
                ),
                render.Animation(
                    children = loss_counter,
                ),
            ],
        ),
        render.Box(
            height = 1,
        ),
        render.Stack(
            children = [
                render.Text(
                    content = "div rank",
                    font = COMMON_FONT,
                    color = text_color,
                ),
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Box(
                            height = 3,
                        ),
                        render.Animation(
                            children = div_rank_array,
                        ),
                    ],
                ),
            ],
        ),
    ]
    return widgets

def build_record_arrays(team_id, total, static_number, incr_array, static_array, rank_array):
    text_color = TEAM_INFO[team_id].ForegroundColor
    bg_color = TEAM_INFO[team_id].BackgroundColor

    for j in range(total + 1):
        incr_array.append(
            render.Text(
                content = str(j),
                font = COMMON_FONT,
                color = text_color,
            ),
        )
        static_array.append(
            render.Text(
                content = str(static_number),
                font = COMMON_FONT,
                color = text_color,
            ),
        )
        rank_array.append(
            render.Text(
                content = "0",
                color = bg_color,
                font = BIG_NUMBER_FONT,
            ),
        )

def render_elim(number):
    bright = render_elim_with_hue(number, BRIGHT_RED, DARK_RED)
    dark = render_elim_with_hue(number, DARK_RED, BRIGHT_RED)

    widgets = []
    for _ in range(10):
        widgets.append(bright)
    for _ in range(10):
        widgets.append(dark)
    return [
        render.Animation(
            children = widgets,
        ),
    ]

def render_elim_with_hue(number, on_hue, off_hue):
    return render.Column(
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Text(
                content = "elim",
                font = COMMON_FONT,
                color = on_hue,
            ),
            render.Box(
                height = 1,
                width = 1,
            ),
            render.Text(
                content = "#",
                color = off_hue,
            ),
            render.Text(
                content = number,
                font = BIG_NUMBER_FONT,
                color = on_hue,
            ),
        ],
    )

######################
## HTTP REQUEST API ##
######################
def http_get_number(team_id):
    query_params = {
        "fields": "records,division,id,teamRecords,team,magicNumber,eliminationNumberDivision,clinched,clinchIndicator,divisionRank,wins,losses",
        "leagueId": str(TEAM_INFO[team_id].LeagueId),
        "season": str(time.now().year),
    }

    # cache response for 5 minutes
    response = http.get(MLB_STANDINGS_URL, params = query_params, ttl_seconds = 300)

    number = "0"
    magic = False
    clinched = False
    division_rank = "0"
    eliminated = False
    wins = 0
    losses = 0
    has_data = True

    # keep track of where we are, we might need to get the NEXT record to fully calculate our magic number
    index = 0
    if is_response_OK(response):
        for record in response.json().get("records"):
            # if it matches our division, loop through teams to find our team
            if int(record.get("division").get("id")) == TEAM_INFO[team_id].DivisionId:
                for team_record in record.get("teamRecords"):
                    index += 1
                    if int(team_record.get("team").get("id")) == team_id:
                        wins = int(team_record.get("wins"))
                        losses = int(team_record.get("losses"))
                        division_rank = int(team_record.get("divisionRank"))

                        # see if we have clinched and our clinch indicator tells us we have the division
                        clinched = team_record.get("clinched")
                        if clinched:
                            indicator = team_record.get("clinchIndicator")

                            # indicator of y means division
                            # indicator of z means best record in league
                            # an indicator of x means we have clinched a wild card
                            # but we care about division winners here
                            clinched = True if indicator == "y" or indicator == "z" else False

                        # if team did not yet clinch division, see if it has a magic number
                        if not clinched:
                            number = team_record.get("magicNumber")

                            # if we do not have a magic number, we will have elimination number
                            # or be actually eliminated from division contention
                            if number == None:
                                number = team_record.get("eliminationNumberDivision")
                                eliminated = True if number == "E" else False
                            else:
                                magic = True

                                # if we have not clinched yet our magic number is a dash
                                # it means we need the elimination number of the team right after us
                                # MLB API stops displaying magic number for division leader after they clinch wild card
                                if number == "-":
                                    number = record.get("teamRecords")[index].get("eliminationNumberDivision")

                                    # if the second place team is eliminated, it means we have indeed clinched the division
                                    # there is a short window of time where the clinch indicator has yet to be updated
                                    # we can override the clinched flag here
                                    if number == "E":
                                        clinched = True

                        break  # we found our team
                break  # we found our division
    else:
        return struct(Number = number, Magic = magic, Clinched = clinched, DivisionRank = division_rank, Eliminated = eliminated, Wins = wins, Losses = losses, Success = False, ResponseCode = response.status_code, HasData = False)

    # if we got nothing, it is probably because the season has not yet started
    # use this to render the "good luck" image
    if wins == 0 and losses == 0:
        has_data = False
    return struct(Number = number, Magic = magic, Clinched = clinched, DivisionRank = division_rank, Eliminated = eliminated, Wins = wins, Losses = losses, Success = True, ResponseCode = response.status_code, HasData = has_data)

CHECKMARK = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAACAAAAAZCAYAAABQDyyRAAAAAXNSR0IArs4c6QAAAO5JREFUSEvNl90NwjAMhNsR6BYwA0xfZoAtYARQKgUZ1z/n2kX0pS9J7sv14rjjEHwOt/NLm/I8XcfgcgM0wRLNwrgAW8Q7FOKICpAR5q5YICJApbjnxgpgD3EL4r8A9tj94zgvBkz3y/LmefhyoBqgi0MAvxCXsvBxoBJA2jk9mvQzlAN44jwHpQCIOAzA0+tdMqh4GIAmWIOIiMMAbSCyMDLGuhvcOmAJZMUbmAugObFF3K2EbYBWD6ggtbSXWC+kkvjKAQuAO4GEE+kLwv1A9HiG+4E+obI0hzsial0GJNUTZiEQcTGEXpqr/wveV96dGgbVDdkAAAAASUVORK5CYII=""",
)

#################
## TEAM CONFIG ##
#################
LAA_TEAM_ID = 108  #Los Angeles Angels
ARI_TEAM_ID = 109  #Arizona Diamondbacks
BAL_TEAM_ID = 110  #Baltimore Orioles
BOS_TEAM_ID = 111  #Boston Red Sox
CHC_TEAM_ID = 112  #Chicago Cubs
CIN_TEAM_ID = 113  #Cincinnati Reds
CLE_TEAM_ID = 114  #Cleveland Guardians
COL_TEAM_ID = 115  #Colorado Rockies
DET_TEAM_ID = 116  #Detroit Tigers
HOU_TEAM_ID = 117  #Houston Astros
KC_TEAM_ID = 118  #Kansas City Royals
LAD_TEAM_ID = 119  #Los Angeles Dodgers
WAS_TEAM_ID = 120  #Washington Nationals
NYM_TEAM_ID = 121  #New York Mets
ATH_TEAM_ID = 133  #Athletics
PIT_TEAM_ID = 134  #Pittsburgh Pirates
SD_TEAM_ID = 135  #San Diego Padres
SEA_TEAM_ID = 136  #Seattle Mariners
SF_TEAM_ID = 137  #San Francisco Giants
STL_TEAM_ID = 138  #St. Louis Cardinals
TB_TEAM_ID = 139  #Tampa Bay Rays
TEX_TEAM_ID = 140  #Texas Rangers
TOR_TEAM_ID = 141  #Toronto Blue Jays
MIN_TEAM_ID = 142  #Minnesota Twins
PHI_TEAM_ID = 143  #Philadelphia Phillies
ATL_TEAM_ID = 144  #Atlanta Braves
CWS_TEAM_ID = 145  #Chicago White Sox
MIA_TEAM_ID = 146  #Miami Marlins
NYY_TEAM_ID = 147  #New York Yankees
MIL_TEAM_ID = 158  #Milwaukee Brewers

MLB_LEAGUE_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAQKADAAQAAAABAAAAIAAAAADfYzX9AAACDElEQVRoBeVXvUoEMRDenHsrWIj4BxanNnY2FjYKp6iVpeDbWAvWtj6AjfoAKqgP4AtcJYKIHgda2FisZnWO7GTiJrlNNrcuHNl8O0nm+2YyybF4fiuNAn4+H64l727GNyTMFmjYDvQ1rrmwLS21+X4rYbZA8AJwYgdHJxI/Fo9ImA3AqtgCVFqD81TE+TdqTBlbwXsGUESAPBClbChh2q+X4lCrd68CUMRUXlO2WITGaKIaro17FUDbq19DSoTW6n5umkELojcBKDI5Jpqd55eeZNlImhKmC3gTQNchbPd0f4ahCG+FdvdKstEFghdgZmqC5IJFWD49JO2KQOcC3J0fk0dYkWM63+dW9vpm07vr/XeTl9jE2NS2rH2vWrfbe4vSNI0YY5kJL4imdwOnAuA0tREEz4HFSBZ3Bsow51sAO+yiL4pkeizWQgAuKs8EeEwKorf/AjbpD4T+aiH61Pw69cCbAECCchS+uWiLRKjNFrAVr/YC8KKYzE4q9XF6DIqr+k59ce3o55qQg6DjJQMqJf/NdK1zAXyl1nkRrJo8ZoyLojIDuOPww5MMcx9flEgBcNRwX1cA23G685dhRwpQxsQhzyFmgTMBQo/+2FIrixEpAFwvIYq4D/gwtx+dx8x95T2gjqSpgJEZQBnWCROPwn8ngEieB9X5RQgyx2dRxCTBB6r1lgGh1pQvQzmLGvG9jN0AAAAASUVORK5CYII=
""")

#id: 108 - Los Angeles Angels
LAA_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB0klEQVRYCa2WMU4DMRBFdxEVouEKIFEjoExDAWego8kFaDlA2lwgp6AMBRJKCRE1EmegoV/2m/xomNiesY0ba70z85/H49ntl93x0DWM6+Gze+pPqiPsVXuOjhDvL6Zhro1TDUBxCLdAVAFI8eX6OWy+FqIIAMJSfPb9HsQ1BGy8Y99rKIVXi/sdt9VmBZnAGJzF6QKguBSeTOcdMnD58RUEb86vOrynDUA8ECaAFIcohxTHGo5h8rv5YAIQD4RZA7jjw9tiDD7f7o4QqRnisIef1SN6byOSmXi5vdumXkMcrB/d4vA1j4ACIRObxjPj4ji/nh79gfHunCHMI6Bhan44PAsQqffWehWArHyccwuEG4A1wOaT2hluQ0lXdAOkBFvXXQBy9zr9vKbyGEqyYALExD279kJkAWrFCeiByALE0svgnhnfB6sbZgEgEoPQgaUNwbQN1/VsAmgH6xmdsWS4W3EsKGqkdVQD8MejFcD8GrbcBE8dFGfAe8ZsWFaGigHQ8axhfS+kfzEAnHG3U6O0NrIAufPH3ddD3wp2wtzP6b/3AQ1lPSczIHePIN7ioyDtUQ+5v+MoAMURzFN0FOUc80lB7PQBfY4MGptlHdT6/QCZ3x5vRz7hxwAAAABJRU5ErkJggg==
""")

#id: 109 - Arizona Diamondbacks
ARI_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACe0lEQVRYCcVWsW7UQBDd9eWSlpYiEh+QJh0KBEh0kAAlafgGagqkk9ApQUip0vANVGkjoSASJSgpUtBcTwFSqOhSwfnwW+5Z492xvbZB2cK73puZ92bmrffs+5vLU3ONI7lGbAc99y8I3D0c1ob5/HBHtelM4Kr/ywVeXHqmAmDz23jfJFmjUxuadCKAoBsHIwNwgJRlCdik1zNpOgkYdNLAysehA0dUkChrBX67/eFVAI6N1hUA2L3NFy4osseoqoAzUB6tCSDW1+8/akuvYBa2WrUA2VN0VaUvIJW8tCLgx6ojkX3sSjXSmIDMnkTqTgDttLmRBnzwLuIjmWgCtr9AHyc8vEjVP7/8kv+OkseOaAJ3Dl66PmrlBjirAWBowidBHfj+URqQpfcFR/CzzTfmdH07NvHcLopAbj1b+CSw/TudmiRRPva+s/deS0BmT1+WkdmfDLaNbfmvolIDPjj7LMXnSCHz/0GAGWNm1txj9qfZPc/Ca9ct7TFrQixtgcy+DPzT4LWM79YXT3YdWRCMGZUtQAAfXAadt/3gCg7aIx2UtUpAZg/FSxIs/fmjtw4cLeBAK+DbZAQtkOAMpB27yXRijtd2zOoMkOB1FaAOSDQgQFBtZvZng79ZPzgaGlYAhwDgCHyyNorWQaEFWvYoP0ahFVm6sAUgKyAzt3M95xPzyAmUgY9Xd4M4BOcMA7kOHCo2HAEfnFlr4IzlA7L8mLcO98z80v3gQqKvnG0GNkV5MaqAU5uapz8vCidCBpLrx+fvzI1bK5UEqKe8BQAnERms6RqVAThGzMfIVaApCOyl6OgP8KbDZuey5TXSFEq3b/Qd0EN02/0DFm0usUeKTK8AAAAASUVORK5CYII=
""")

#id: 110 - Baltimore Orioles
BAL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAEJUlEQVRYCa1XbU8TQRCeuxaBvlElIcbEBkSjnwiamKhg1A8KaOJP8FcSQL/5gpj4AUOMEQ0Uo0ZiYrHXAgrtnfvs3tzt7d31SuJ86L7N7PPszOzs1SqXyx5liOM4UqNSqWRonnw538uEgXfmbanmOG5E/X8QSiUAcAaeeKqcVPeJgIW779HeXodyuRxlEeGD6OzZJpGACV5/YElbEKnPqb5dtOjrowEiO0+OcxSQiIF5LtXvWGQNKzsm0Wx2aWRkhCwzB0xwNkhqmQzWaksdsm2btmctsktRsCRbzI2vuFECWeDwxMQzEY5hkYyHKjF1EklAd98WqXEcJVQbcmnx2gGNL3cpCAHA6/eEqwYFiB9zfUMGRzu15tF+oUzFHNHUa6KNW23RlujQtWjYDi8VYD/NtunSqxJt3GwH202tlWTfE+EJCGAG4P1Iq9UiETrKCfWuwAP4ZwF02I1bX1kNwRkYhCGWnVME9MRJOj2U4Xr2AsAh7260ic+bBA7AzZkWXV5V+utCP6dutIw/boJMQhn7hVM0sXIsN876sQsV2pptpapNvymRy8yEFp+YDZCw1WpVDoMQ2EVUuV9UrZTpt5O++fZ9kSdWfB0latqPLXb+INzcQUcTJJ0wDq4sloJr6DSbtLOQS0xAbY/ULodFPy2umS5cfPS5wANgZornKT9aCWusyzoY6wDyjgs7Jsb6ZhsS8FdcV7AW10OkqOAUJwU1HZR1MLe7u0vVsbPy6kX03C51RFLk8wpOJypn9AKEapYlAGUS+gkLhQIN+eb8jiTthUeNSeQB/u3JZJJezzkmgVM1Gg2pOzo6KtvJlyhSKnyoFetaEYICyDEJ6YHOz7o0TKsBcjHlp9PpyNOAUFe4+f1MWPFgAh41fk39h0zfKi98GYxR1/shwe5nQz3zeQ4tPOEeiBKvAfPNCEJw/GM7sBlKzrnIBiCI07Lom/Mc2osCfOs26oXSZWCsMTj6+YFzkzS+dEw7Dwcob4XewCLklCxQqvBcFYWmPhd1sdKK/oJkfS4sVqh8OqiubcsF8ShA2uI1M2XTL7l4cMxkMnUxVuDRfXrdrOw752+KOPfKD6yBpBkSuD7t9CAcK0SYTBM9SfX7j8Cp0GSHx9w7RmCwWKa/+2H82KXchic8OZgJjrEMAVzEWfpRfFiYUhRfOfrpzXVzHITKUrllruvjaA74nwPhKZXq2LJqzXl9I+6zpzA+v/inZ/yhEzzHGOhvAsbBSTDw5fu8RUfx2ypXkYRclNijvRIQRhECmOiHBPRMqZ0p0fPr+8F0VvazYowAFkDiy+PT5B01WS9oUYz4iykpJP2enDdMJIBFkID0elalgv/jHnh04YWXGXPdBv3YNWQFjp35hxSEAGYXLHlz8AHDlY5teI9+2lQCbGxuqhMy19jmJO0/2V+5jCW73rQAAAAASUVORK5CYII=
""")

#id: 111 - Boston Red Sox
BOS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB70lEQVRYCc1XsU4DMQzNcfQkJBiAT4ABMSAxdYChMPAFfCoTqMDAzWyd+gkwdQAVjnK+47WOFV/cIxJk4BI79nuxHadk2wejhfvDsWnBnk0fmm07hxfedsghlHrIu76dBABwf3rW+JhNS8/X+GTosnzlAvp1iGRaCggcwB5qvVhUnx6w1F8+l85KYkMa83U2yB05k4OfWupoTcQRvZCeyzojQBvpJFo0JDkZMUskVgnktH6AIWpJlF5KQs6pBiQJ+NC+nSnQjDQ5EeVRsaTCTGA+/9BwfyU3E7CghGolFoWkBCwk5Z6kBGQNEFioWDmJpAS4Y+s8KYFQDcSIqH1AGhbFwBO1xeV3SdkDYuEnhyYC2skkoMfQuIimgMD7DDr91tF11FR9C6SlFgV0vsfhyH2JZpUsBZIMrQFMV4/G6+TOUZ3wtKBOsKfZKP6YaoBsQq2YO94/vmpcr/sgRWtAEE6+TEogVCdtGvRCTkqgT3iSEvh3b8H5+CZYvDxS5lsgWzF3grmsgWJvN/rrWCVAznDNXia3wFh+cceXgnrCewCXd83VTkgEMPo4tnRB8q9GgJR9gMmOwEONi3RyqAQo/KGuhhZcvb27Ks/dU/0G8AFwdEauC81VArQZJLgh6gIy/D+ItdRDrn3VGtAMUsu/AaALyHmdviL3AAAAAElFTkSuQmCC
""")

#id: 112 - Chicago Cubs
CHC_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACFElEQVRYCcVVO07DQBS0UZCgIRyCFkXKR+QCpOI4NFwAahpOQ0qkSIlTcAQakJAipaGhCDyTsWafd/12HUtEivZ95s2MnxeSnw3vd9k/fnop2tviLhreHz1EYXNrAyHRYjx2BEarlZMjsYw0GmDx780me53NwGuebKjJxFGIicXlaVPEhZM3xFxaz7sBDDCJHkzJsQ3fJmob6FpcjOJBwM3mHQMAYICBh8bghAb4kv4MMYSVIscJEeR8hmaqOwBnbUhYSGLN4RPHfXBegSbi3EfCfY4ZyzFjEJcbsJ7eIgFZ6ilbiL4DWCvMcI6YDQAnNd3nnvkKGMwCVgxRnIxfT6+qNHoD1URDALM+UfT0eKcGWFgLhnrmK9COm3IRhTAEJR/M5+UXs+hJnrwBHgYhTl8PNRgDFqe5ARD0zvuYiTq1IHhkmHvRGxg8z4PCTKhBTT3BlhvAv8XRcqnny5zdewEtim/v23LKfQV5HqRKMSFYfEOElzdPHgMh9L4eY0JjdK4lql9DaVi/CTw8XCyyvLe/QrtdVkwm3K7FfBfwygXkXEJpiAkBW87X02lNJKbwuflyYO4doBY7pnKrkLkurh8djpoBXg8POlMJCXMwNyicO4CinLgPqFmvBDicLCw1n7jUgwakKZ9UI7HCf+wRBgDURlBvOkNPzTPmBhgs8cfLbXZ6cqzLVR4jWoF/g2QDPNxF/AMGb9WCxchThAAAAABJRU5ErkJggg==
""")

#id: 113 - Cincinnati Reds
CIN_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABeElEQVRYCe1VTU/FIBAEYvTm3RifJl486+n5/6PvZ/jxM/zADsk0Wwrbra+EyyNpS+kwMwvL1r/4XXQdW+ionaRPBrqvwNl/cmD/+7447TXcLmIA8NZTcH595Z4+DybSHKSZMRmwRJyLlt5LRtQc2P+8ua3EYajEVTWQwN6XAnF+GLdcpcm5iWIS5iASQRRtyBsOqU/iY5wWW/BzO2YroIlfumAWp1GYpRHpljqTFeCgBKL/cLNbJZzPr5lI48MtrU9NHGSIAOAWLW1BL3EEFDTxFhHnnKGUIBL0eHcvXzfvp0r4HD9cflSkUvMcqGWpNNGqP9YBzYS2Oscam/2MtO1g9VorWkt08M0MgFwzge9WIzVhcDCvigYAWDIBTPz6doeL6SnRRDEHjeKpz0qYvmQ3mEDbKgd45GVVnfwLMv2x/GLisSZk1FJHNUCgPCFrjDBi8MioyYunyQCAJJCkGNca52gYswGSWEiJtTzHQmQBt8CcDHRfgT+MAX2rBfQkPwAAAABJRU5ErkJggg==
""")

#id: 114 - Cleveland Guardians
CLE_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACGUlEQVRYCe2XwUrDQBCGZ2NS21IFpaBGPAnSk2ctPoQvoBTBB/BNPEgfwKfwoogHfQFRoXorVRELKiqmTdbu6ki6zqTZWPFiDt3M7Mw/3252k62ApTUJGS95sqszxfJ6RgUAN0vm40EdxgolaIl5nS7lVR8IgqF2EqAVgBLuyA7cORV4QvVea4KgjSEKkINIBaBH1Am/CqGw2ZqFzX7KZgHmi+Nwub8D8vVlYGFKOK2PBTjf2/7VwgjIAnge26Vz/c+Fh0Kq5R5Bt8tvNLaKWjRh6xhu/Gq8BqjCzdt7clGpxUZBuK7o04gbTtww752ZKdOl7bnVLdJPOf3mEQmLsYkAGPSTNvBnE9MzAHQSBc3OHD/7OtQaIDIr/NBmF2EW3VBGvUV6CVEUQrsdQLlcBH9lI1HKGsABjxV0qzW2j+uwfgScUFb/P8D/DPz5DFhvwwj4N+HLYR0Ko6W+DcGdhDDIGiDpPQDS+/Y1TDqOKYjhPgLisy/fnnGwZDtcAKLEdX4RzFNyPIwFUEnU4SKebN57uRHTNdC2XgMKCv8HmOq2wCrfGkAlZSmk8qiLfQQqmDp4UiKDfFJ22RB2BnD/4nTbjtoPGgDex/hQi6JgATAYk4PoDFzhwLWoYBfZTssLcEIJYqVG9pvOgQCYkKtu6luckWcI4UEsaN9k1IB8D05dCKyNFD+pAVArXuCufQqFiRwUlmvYbd2+A57uksVWYazdAAAAAElFTkSuQmCC
""")

#id: 115 - Colorado Rockies
COL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB2ElEQVRYCb2XPU4DMRCFd1c0oQ33oaPlFLQg0XIJoAQOQIWUKhIFEmcCpczCW/Ss8Xg89v6xUmSv53ne57HjKO32bNs3Fc/u/TNRXV6cJ2NjB1oPwDL1DKYAneQS0vx47JuuaweZNqAml6NmvLNETHxz9TiYw1ibY541ZuXzxhIAaf7wfO3NHWJzIRIAZMXK+cw1YJ5cGwFg9TSvWT2TzoGMAJiQ7ZjEY7TMj9YFkMK1+gGAh28to1zeAAAB9z8nXmM8AljDoJQzuglx8q0qTN2emoMZKuCJdQyQBEVMfrBixgBego8q4JWLEF5CxKBDS4jSfRIqQPP273dnSOCZUc82pwVILoa5EQDo75/K9z9Ndcsq6XHvPQKgkGW7u31x6an3VkhNrk0AuApAfH8dhnmegRfLmcrxBABBCUExjKaYsZrMo1sTACJAEERPst6pfdt/hDDNGQsB0Sl+DfVkXQUZZ6zv+6bGHBxFAAFrdmkqg+3vd1mCyZjuzwagEUB4+cAE74xpU/mePQNSNLX/utsXpy4GgNVy3+GKamw2p/8HQCcNYZ0RatEuVgEkq9lz6OSzKAASW1vhVWFxALm6mr7751QnyK3EKr2ltXTVFbASEtCKWWaW7gdaTqyfBlTt/QAAAABJRU5ErkJggg==
""")

#id: 116 - Detroit Tigers
DET_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABgElEQVRYCbWWUU7DMBBEE1SJn3IK+sMt4BQcl4twi37xBRpVT11Fnt11Q/wR27vjmck4lbqeX99/l8G4fn8tL5ePQed/S0+OTuIycfSwBhCWiVkjM2dWdwXRAGvN2bWMjGZ48ZUGBNIYkd869TMzUV4B9CLJiMDNzu0EIjFpYEh71uDAsNe8xajWTkBgDYghY3/r3p/075Xx6jQuj6tRLK47Yg7TTmAr6AjH1n21bcBT7OuUVxDf3EmBIRX2Dh/raQJdoijMmfXt8ycKuXWaAMQ6DLEjilhhzsvy7LCxniYAsBIH98icJnCkMGZTAwIRbWYm6yHk5tQA4u4wdYfrGGt9AwgdMacJOMHOm7mz2/pDCShyF/tWoNpPG0CYFNhXQq4/bcARVXUMb3Gtb0CH45tCFmuRmH6suXX7H1FFipkuDkMtAxUpZG7G3KhfXsEe8UwYM6mBKF6RRazIKzwGyl+BiDpkERPXCLnZfgN6oxkiJ1DVywQqgr19m8Be4u75P20Tima8EdwbAAAAAElFTkSuQmCC
""")

#id: 117 - Houston Astros
HOU_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACkklEQVRYCbVXwU4UQRCtgXUTQ/TkgAtEPelNE5GLJxJiwi9whX8gJJz9AD9A/Q0PmqiJJ4kJZy9KQiByEg0QQlj29fKamrJ6pmeFPmx1V796r6qY7mEKebzSl5Zjf+GDCKIKFThYl58WlSNv2smDiQTRC3D50RfKwVi9oqkDJPVE/y6/l6PdQry9ujidRLIDuQSaTM+ZVBPPmA7ivCmIuBxrE7Ex/ySQK472czCGa2vrkqgkQCIGWKL/WZOTGuSqJAAngQRcpfW4YwLIzAN4Cej2c99WRr+10NDY5ClgYH/rNacVu/drX269eRZ8d179CNa70Yonq5U4uwgdaFO9JRhlrbsQLiK25GbPq0Hkz8qm3J0sgxYqx2D1uIgwTje+ysHhqTx80Atr3aHgUD+MQSLxGcACG9xU+ChGH8W5hu28nI/iXJPPWmhxdHT7uQFfqhsMHMWSH7GYQyd2QBNiE1n3+/p1pxHt51pcRydPAQLePd2Uudu/K90Iz8L6z8gxEWf+5O3OrKx9f+RvDrzJBBCx9G14zNCqJiFPIVW1xtYmQCCIeD62d3bpdu29meEpyBEHQVYCWql7oxNOhXdaeCFpfGrOh38MmWLRZnjibeI11j0FGnDd86wE9PtgqizFa7X16Zi6IuL/hPybWHCKCFdt78V6gKcw2PReRlorqwM2qatcxw6AVGdGEb77+eA1HS/7QFu81ah0IHUicsWRtBVkIbBWHL5KAnBg6CogDtI64mHU5a/Gj19cYZrzEomPK+fTLIJH/NzSApFr4PSKcG9CAhHcHVRwUvkI1PR5c/J5aLcDGsgK7n9ekMOzcb2VnE93j2Xr+ZewXycOQGMCVGEiXFvipn3GWZudgA0cVdDynAMxjBOkRq7N3wAAAABJRU5ErkJggg==
""")

#id: 118 - Kansas City Royals
KC_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACIAAAAiCAYAAAA6RwvCAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIqADAAQAAAABAAAAIgAAAAACeqFUAAABnklEQVRYCdWXPU4DQQyFsxHHoOYgFHAIqkgcgpqG9GmROAai4RRp6ClyAtrAi/SiJ8sz9vxIQKTIP2v7fevZrJRldfN0XBU+x7eHwpX+9HK7dZsv3Kwk35835+j6/uXkezlc8PJe7jxQnLX4v+ouf+Vowo3oanVls/KcGYKg0IoypuUwxrQ2z9izKRA0cjgthzGmjfK8bm0aBI1WjMNa8+xT2wSijbP98D3Cd8dsYTsvBCm9Ce2gTFx7U/+fo+Gd2rvBpjQ3urn0RlRIfYDamPAtNg1SGjoDArO7QXAssyAAEv5qUGQ/NQh9btiXAe4CgYAHU8oRqGa7jgZ3iK/evfoqmNkG6rtAKGRhsqLsVzsEooNG/WEQu5VeoGEQFb5af2nY5KdB9GFUH2p8Nj5eH5vEtTj986WYNmd9gEf96Y1EohSy29rv7kIIzE5vJALBdQ+Guai/CoIhmbVaEU98ORw+f+oubS3j6h8sFnHdngBrajbTnwKhSOt2MgCc3QSCpszwTA0BaJtB2FgSQ77nCLtBLBDjHgj0DoMQYNR+A+VlpegIj++wAAAAAElFTkSuQmCC
""")

#id: 119 - Los Angeles Dodgers
LAD_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAA6UlEQVRYCe2WSwrDMAxE49JbtrteK931nileDBkUSViuQBiajWJbn9GTCWnbYz828Ryfl9g5l+35PhcJb7eEHD+lKBfQtBGgJR5FNnrUKCfwF1BO4I7LELV8QRE7c1HLCawpgPHPYMfIuk0lwMK4iPeeKsArZJ2tJ4AxY/6wVpfefjoBFugVxtn0hwgJPMtiLErpBDxB2tm0ANmRXGvFtL2QAEaqJcPeqF/3v/wRRYJRcMRahEIERgpFfcoFXEZgdcCjsXD22FE/1CknsIaACFYeD8cBubTlBNxL6HXAnaKrqH+PKydQLuAL5/o8FLivrBMAAAAASUVORK5CYII=
""")

#id: 120 - Washington Nationals
WAS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACaUlEQVRYCbVXTWtTQRSdl1fBdlWCQVxZEvo/+g8K3VjUteDOlb8ju0K3TaGl4P9RTOiyWBBBEARjzHnhDOfdd+e96asZCHdyP845c+9kSoubUK7Cltf0xVH4vPu8YjlbXNfYdmrftvDl/fhVuJ9fRuTRJAQVMYiRLWw+HJzUyEEBMRDFtVUB09tPYTR5Q65oVUTWCFRxRFlvtJX0I1f92KPtWDqKjSeEpAAl9QrtyZiP3NFhGcLfZRQCEYyTOFr8CvTzbPx6hU/bQtzWePldeYjXOgCV3mmjWmfTVlN1Q279/p9fDYR4CduAtAqt54xza1j/Y2eP22irDnhAdsY5nRlO3lbA3+ezSKAbXkjFqo2AyTmntKJBfr64qiCG67ZThB0DOWgHFkjJmUSbiik5c3NtvAMosATeS4Y8K7oM/f+c1ASgXQDn+j14wm1DHANWNP20XfHGHeDMAKCXhYDWLkNhXSHVEds5FA42N7P5XjdQMx0eiVfKzlQjUBEMaJHn07juvY5o3O7jCPgbhf348jir/Rasz/faJQQ51s/yaR+sqkbnr51LjSZ2IMWoIKkc+t+NT+MDRJ9nFbPWASSnlHpAbT4lAebdlws3vbMDbpU48eSOJpuHiM+vhOO2LDdnVWEIPloAQOzNV5KujjZGAMCupT9b5nqnt+QqjHW9BLCYVslBgmXJmWtt7xHw3bDP9bevs1AUzefZOz3E9O5A6oQPIYeAwvvXzIKzrSjg0pMjrt+Zwzo+cPSrzRqBB64g2JNM/W3EzHMFpObLIlqS5hCxxlpXAJK6RID8McQUkhSgIpis9n+QA+8fSCp7mb6idS4AAAAASUVORK5CYII=
""")

#id: 121 - New York Mets
NYM_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB30lEQVRYCe1XXU7DMAxOxp7gJgXtSkg7AsfhAQnOBDsJ4gko+aLacRI7IV0RQiJSW/fz3+fESTfvDnez+8Wxs3LP1w8Olxwa1tP3fLw2A/MUEnsZupb9yzEDS7KZEi9hnv0p9wG8x00blEAGJuxtetRcXNR/7N18uGc9+cSiGE2CugQaU7gQmcvTbYqwSJTIXbwLXWovK6ZKQESoRKuSyvCbwDAB9MaWJMYJoLINSQwR8M/HNLEbkRgiEIuX269LIhh0hnoOwIc6vvSPs4DEdEjtQteHrUddznjhyLukxNccRBUJ2m2tgo2DaHgJUMB8E05KBKTlQOIlOWOxUmIWX9Rbk0AeTCQMoSoSASvtkVHDgNNQCdB6kpF8VgE/U4h4PhhFWzG73wKZnGUkQSNiKeQARs0p8Iq00CX6AuyJWjWcZOmFXgzSryJAzuWTSZSKxvtqAjKZJTfysmo1AY5wpqAS6H3tND2wKy9/C4BZagjNBxbmLtC6mTFjq71OT4iZjZ6POgOyy7G+dFFkqdcwsufeCN8LzQe+5seIAreeVB0nahkbOnUGDNsfgf8J/K0ZkHuZGhCNkcn4VzUwzHPAiiGTSRvGjTNC2kp5aAnKvUz7XQYsbaROk886B7SAo9gXR3+qFEXscLkAAAAASUVORK5CYII=
""")

#id: 133 - Athletics
ATH_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAADvElEQVRYCe1XO28TQRCevbNjG/K4KOmQ8oKAQocQCKFISDwSCXD8BxC/gZIGAR0l/4MGE1EQFERBBUIKFKAQEZKCBhLZsazYTpw75tv13u05uTtHMaJhLe9jdh7fzM7O2oIunfPoHzbrMLZL9zcJ3262jgBow07+s7TdTRCpJG9grK+wSjZ/0JzCOvdNKtFJGnwyJGlH6WIjAOP9+RWyXZiQXctWIu6OMSVqqsxPhpSpCCASKxyFySNHIRGAGWZ19oiExfFIFA0Bj1rEHoFpPFCgRCwGkcuOBOTW7LAJGutGkrLM7CKV6sEx1B+nKHN1hfZyV8h+2JCQDtJhOhYJAILO7Aei7DCHG/7qpo5ArXo0UY6ulyM3xSo90BuyZsicQakTitUDnU77uRPoVfvhvmeIysVxpm2H6aEbEWxl2LBFv6lmt6zpLVGm6qsbvNpgHOo6661YAOX5CYm0Upxi/qaU8TyvBQpLl/puL/nVsSY2qfb2DvU+qEha3xxqBtHuwk0SdoOqb+7Szutp33vsRR6BeU5g9PgDv7ZeTGDJIEZlUbLtQblGt1vfpMFH/pJs8ZMXJyg9847SLktbDaovTktwWn9sBAJV8JVZW8+WFjb3MTfpmJeLl8l1WzljAX6WstfeM/BlP2qREWhXjlLsCigzm1o7cx85sc6HAIBr/GmFNnIXeSaoXPslIyYT2s36ShIjgNswMLcmBSoyIclHrxKUVYhhX6E5+XGvn+yZZ7Rr7SrywgV1m6zAkY4jAA26DJtGoubyGnOoPS9N6etL5FCdvB3kUWAcsocCoIxBAQKnR0UFuBKN+seAHCjRGbk5wA8aiQyXB6SyRRVOYJ0vsQBk+PPrJHD1XowqS229U/jOlFSbX4pJG8GjZTZNBy0WABgE7bHDqniYgtgDwCb7BCVxydQuB1nd4uQUDxt3W0VIC+kRiqvFU3rJObLqJ6gmAiS+US0SAISc/DcpVyl2+usnXGahYyC/HGVb0vcdgYnWtTIc2nDWQgo8ZlhRnoVAoVFN6+gtrNFWcUyTDxx9AFrIya+Ry1UrCA2/+zNfOaPxHqjm5L/w+qwEASAlGvOvaPiqKvAmWK1DjxIAjDu3PnFK9jN9j31OGQBcyuSOUUb+GIWYKx+jfUqNJ1dxNfm6JR+dHwGXjetKBwVmM71C9dtnHMyiyl2vL2Zx4emkidLzkdYTE35MTGF9PKAdaJzp4DnOCZe2stRoblPt5VQkr6lbdPOvWSdATeOYdxVAu/JO1kGyd8L9F3j+A/gD8NpGOtOs364AAAAASUVORK5CYII=
""")

#id: 134 - Pittsburgh Pirates
PIT_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABKElEQVRYCe2USw7CMAxEy6cScAlWCAmJU7HtcTgbRwFExaezsBQ5tpOWuOqi2Zg6zsyLE7I4HvbfymHcrpvq1DyTystkxYACmGNQtCTW1mSOgLW+re/dtL1HdfZfc4DV7S7ZBRGghHnYGUvPPIJQBL/f2091vrx4OvqWDCnHL2bUASqMVLvE6hGVS2Xm7ef6eYqijZ3kO6Vqno8AeAEtLBEl7QgARlJhCQBJQwQYE0IFkGg9cqMC8H8ANuQGIJnBkOddALgJjGnwC97rJYSIJU4mUuTGVOPSARKnqJlj3h3AMgdA7yNICUK0zzG5dIAgKQJKGy4AMMsxR50bAMRzxgwwd2C6HdAeEy2fc+Olmul2QKL1yKkd0F4yLT8UTgWAIDfj30NNw3U/QCBGzGkW/KwAAAAASUVORK5CYII=
""")

#id: 135 - San Diego Padres
SD_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABPElEQVRYCeVXMQ6CUAwFg4mjF3Bzl/Po4NlcPA9HcTRx0JSkSWna19JAGGT58Nu+9/r6wdhezqdvs+G125B7pO48AcPj4IXc/f7+dmNewHSgQk4ElTrXAVac6apCzPimAxxMr938cTF26AAnorW/vVAYxpZxAFLgYNqB6pyjM5R2IALy+oyEpx3QBJEgSTw8j01/tc9J2gEtIHqeCPz4H6jQAdmJJNX7E0KZGNybDlTASJAWFXCPYVMARSoiMoQ6B44gK6LSOQuBAjiJV0mUFce13uqOwCtYet90YI1OPeGbO4AF7Os/s17Heh8LAF8wDVR9Ns+ABJPnIbMvczL3pgNLvWJlAVQ4VwTlz60hHjgCDSjHoWMEVrnMEVSAqjWrCZBuIXFwBKgwS0AYaFxpB+YQSuGInPLav/93/AMr5kevP8pFOQAAAABJRU5ErkJggg==
""")

#id: 136 - Seattle Mariners
SEA_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACaUlEQVRYCa1WsU4bQRDdIwQp6BASNPxCIAUSEgXKB1BESpfKTuEiqZMKUaRIlSrQ0iAE+QQKPiChiIRCk/xFigjLEk6iy70xz1qP73ZnHMYyuzt7N+/tzNsxRfnkRRVmsP7mwvit8no4nnsn894XCByDap9epzBcBBAYwBen76Zi7r58H2JgzqceVI45tW5dpsDxEkiBXJyZ1mDRRmHRQBu4nDr0Q1l/4qwwGxYy5gzEADgAQcLmiqT+6ccP0bns0ywBnj4OSXCmnCeF32tZAtaAIAGyXhL/RQCAujTweWwmAlS8BmIptD+1nokAAuqTE4Sl4Do3ugk0qb2/8zDgC6NordlwdUIAfH67F0CiOjvDUqw6+iRj8boTykvf74I7A0AC+I9iS0D5B2sQuXcRsqb6eq1XV8QORbcbNjrrMsIJElYiplbcJjiAPTs+COe9N5hOmDSrWhfl5e8Jv16YNNAkPAbSmvjy7Tu3TKNJAyiDqPrrzxAWK9EAdBALUaNJr6hPnyuFiQCDlwtLklKovUmE0ILXXAQQXPQwKMLGq8cTWBAlyzGxkVlkCWhFQw9Skjq9yASNtQcJj2UJIJhcxbtOJ1q4Q4gVrq+plYSJgCUYMjULCTMBnJb9Pib0vDf6XzD2eeZmAm3X6vaPqZW0cjITQIS1lRGYvtv94c0UgHTCuiyxZqYeqh0uAieH+6OAf0cNZnxDtlfFn2rZTeDwufNHEC04+hHUeno3AYICLAZEIJoHHO9kfw2R5sWrX2HuwaNxX0/VFc+n9kmUo6kEg61leZ6BtQgZDCOfiX2peZZAU8AmXwoktfcPZQQOyKV6fAkAAAAASUVORK5CYII=
""")

#id: 137 - San Francisco Giants
SF_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABn0lEQVRYCcVVPU8DMQzNHWXuBiMTonRiQYgRiZ+NxFjxMTBB/wL8h+Y4p6R5jWLHSU5cpCqpYz8/Pye57uryYjAzjn7G3C71Ikfg63YwNRKt37octNsXFfisTE7IFKsZrAIxgLYijKN1Lo5VoF+ErRwIVlriS3GsAqvNMMqI0Pp1CQmWQCodypva52wSoaAzFz2BXSL+LwSkGtgWbO+MsfY4lKTEaiRpfST6exvOrALWhnucA0HAeE0kJaKd9C2oTdyNj+D16wQvocQ8rhT/D0E8NCfXogKpCFQlJri52Znlaejqw9OP+V6ep2AOtuB9MNUv7j9Ojvr9/HiWBZuUQDZbwoG9hpLUHoeuqhnPmt3tmx63xPtJM0tACvJ7eFW9rXRuakHf76/a31Sa2/k3KbB6IQzdfefYNSnAgZbYWQJ4oPBA5sBLfAkr+xCVAiJBLALtuGYV8E4aEO+LszZOdQgRDBVBOyYvWWcVKAGr8Z2dgKoFVBlK7yt1tvEVXr/XvwV6BQq+8Z6gZlYTcFUSiejXUj0RVLeAnFuTEUY8fgEFwWvalBhjtQAAAABJRU5ErkJggg==
""")

#id: 138 - St. Louis Cardinals
STL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAC7UlEQVRYCbVXzW7TQBAeO0krgeACzYFSECqlqngDbr2gvAM/4gAH3oVHQKIqHHiEHpB64SGQSEiDEAd6qFBOtRuH/dZde/Zn1rFVRoq9npmd+XZmdnaTfL33ZEkCvUh3KBFkf3ozOsozQbo6ux9ThfPJ9CCocuPhfpDflpm2nXDV+lEACPP2g1eWT3y7PEuh5Uc0BcjxaDALmtxY3LdkXeshkYpwNFijoXIi1QBHhXqAriFEziUJYDACL1X1z8cHrg3xez4+FmUQxArWA4CVx5zfvfOM/l77rR02OYYS6uWokLerB4CHMsty2tt9Y6VhfX2g9z+AYmW7i006o9rMRX5Bs1+fNMCtzef0uT/VY+lRz1Qa7urhPJRPGKtz6jjolSHHQpqcw44FAAxDWB1CN+qtGVb1NgVaMZzBcEEl8MIRBD5FAAFdi9W0O2KFxw1FGxFX/F9jKwLIK6oWq0OFlx0vvKchQ33wXgHeBuV0SqpQI5XPF+NFYMmkBghj6SH6BIjvGM1QDzgHvU239bvpEeyEcNCU4ybDkCMiQxWRd8WJqB4EAO2rAgFbAHJYfMfQIxEANM1249EIVbfpiEZ2K9uik5+HlbPz85xuP37KekclkvsAVFCUodOwbkIlyNrcZYNKJrpLGmDonhJ5RSgptuUDpIlIbK61DY0iQt+GVnEk2fMAlOdBfbw2GefpkJzE+BYA1zkmmjxyIzxCLgAuC83ldjC2dgEmo7mgGSXqN/7xgZIEI5+WSunmzr4vUBzXcadtaFbCW23QWwMTzj+qHsA7LJ9ipYALTGjdbQiDvC/wOXy89+g1ZepyggYkOYe+CIAbc8cozNA5YPSuU0Hvi4n+RCRxgz4V/kl1AlBGJ9xaDQg3hYgcomkia/SiAMpTzz6OcQSHbknGIH+ffftC/b66oylC2gCCyAYeBVAUBc2nx5hfkVvhlaDjIAqgo01vmqkZfcF17olRAGmaXobNs7kyQ/tTWdDHseMcRv4BiiQh4Af6fuMAAAAASUVORK5CYII=
""")

#id: 139 - Tampa Bay Rays
TB_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABq0lEQVRYCeVXy1HDQAzVOlxCBVADUEXKAHowFw4UwIFThhYYymCGHhhqYIYC4BA7wRJokTWS195g+4AvliXt01v9MgnL04sdzPgUM8am0AdM4OPlgcXs9/rpDW7K60HnZ89AwB7g2+MNrKdcHUd1ymdoFmIJug6WqjxWmrVPZJwQ/qwEh2eXiVC2mQh4abWP+NocHCqBlVI/jG/JwYk94MPaFm5c29rWLk/OIRR2tW1t+7z5hemuqsq0aeXn6yMgYYt0dgYo3es7itU1prjnr8QYIwnZsNkEMDLXXI8g64kdElBjfNsQZ5/sEjB4n3ez7Fy3SQiEEOYl4EZvDJNkQHa/XvmjE9hs6pgAHRwNe01BRHYEvvm2ruH++T12vnQfLQMcHIMViwXgrkAdjqB8khmQQHiwXB0B/IDwLEtAluUPk1xUJIs94BLQgRkYINBt6FsA/dq/pRa5xs8j4RKQN9DgQ7+JjCLBGC6B1g3Ye4834umVjXCjNWFfrv+HgNfUk2RAB5cbkf4X9K2X9NOg0tYly+Do505BFwjacsdUT1d2BlIE+9on6YEuMl/j554SEbiiJgAAAABJRU5ErkJggg==
""")

#id: 140 - Texas Rangers
TEX_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABkUlEQVRYCWNkMKr4zzCAgAXZ7v9n25G5VGczGldimMmEIUJjgQP3VzCAMAzQ3QEwi2E0ShTABNFpRoNyBgZmqFv//WP4f74TRYmocwvDmw9f4WKkRCVeB8Di7MCjVXDDIQxUB4DEYMHK8v8vA6MxRBUxDsHpAJDlMEMhxhFH2ihFw/WBHELIETgdwPX/D9xGB8UIOJsBFAUIHlYWinqsKhCCOBPhN0acbkPoJoIFi0ZcSnE6AJcGaoujeJOQa8m1HJ+5KA4AWUAw4WFJADxcbATdhstckqPg/wXMLHh/cxkDKQkP2bWMpFRGhLIULOuS4hiSQgBfXEIsXw703H+GQ/eXIXsSLxsjDeBVDZRk1C9n+H8RNRoQljMAoyKSkBEo8iSFAFgnFh0iAtwohpLCwWIcKdopVzvqgNEQGIIhgKUuoCQvkFwQYasLXu+tATbDEG1CUhxEVF1AqA5AtxBWJ4DECdULQzANoHuXQj5RaQBfLUih/QxEOQBkCa4WDaUOIDoNEEpM5DqEqFxAruHE6AMA559km57PrhAAAAAASUVORK5CYII=
""")

#id: 141 - Toronto Blue Jays
TOR_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACN0lEQVRYCeVWO0oEQRDt2dlFxFBBAzUW/N3AyEhPIOgNRDDwFIJeQVDMDYxMPICBoOIBVpCFQREMRPfjvO55S29t98707MoGVjA93V1V79Wrnk80vXXSUWO0yhixNfT/IJBcH3qF/nMFAD6zfaowuohUvdSG3CAYwH9abU0CKUmI6UdGgIBMDGBaLa50q7fXsR9MQAIRZGrzWE1O+NOxDfTn6I+gRzYSWFZANx/413dTfd4caTdXbCECsm8ELTICvLG8oGaf6k73gQRk1Y2rAxVXY281EgHxAIdhTFISUoU+AgRF0MLqnqo/nOO2e4j0JJvLZLafa8+OxT18InwLbNC5pR1Vq/XyIon1jX319v6h83CNSTmyYkrOOfblGuZRJzVUOsgAlueD+Lv2bU8aAEgC9hzOmoCr6k76jXx5NPLbWe222Ou4l8nlvmve1wJZqU9qVzKshZDQLZD/A/Z5QEIQ8qmBfZcVIQFwHMLe05Zmk6c3yZ4CKpOniG6R6L0kSXCs6xZIB9ccyuSR4H6z2UrPz4WK02+ArQaAYXaRhQkgMJTE6/MlwrpmA3OxrwXcyBu11Fl76Du/squiKFJQAOAuQPpyDPohQUL7DFByJMNBDQVHXBABBPhILK6Zl1nRypELFkzAhJkrpIZRCahTRHYTba6lCFCFavZlRKoy4IgrRQCBo7LSBKgCiJStHrGlCSAYVonND4qZhV9LvwcABRWS+7Pgg2fTDHoT2oGjuh+6BcMSGTuBX++G/43JEvuGAAAAAElFTkSuQmCC
""")

#id: 142 - Minnesota Twins
MIN_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACPElEQVRYCcVXa07DMAx2JtbBL34hEEMcALY/cB0QQuJYPIS4BzcA8dgRAIE4AGr3CPFWp27iLG23QaSpduzP3zd7yzIFhyca/nGtVebudIpUlJyl8PNwDeuddrFvLNU7LfkxR3kdQKLRGPTzTQzbKK56ZwY3sdiWtZixKnKk0INbxgQQHYE6MC3dyNs/GgGMx0WBtTbop2vrB9ufJKAfr2weN7wO6IdLG1fHFwCYkaazFye3WRWMLINprTxVD+4syBNgI2gg8bKWqZVmpoPOEkcQauXrx1cJ3t/fK/no8Jx+d8cMvfiWrx+dAzjj8ARUJfeYhY3X90+729/dntk4DvyqKjUVN38EOZy/K1uxpuHVyDsTFeABaxLzdKmWNwICmAbBizNzjNlWUqLzdOMuKfo8J9gBlxxBHOjwBl0Jw0WJAngCVpaKBBmFgIQnDk8ABYQ6C21JIrBg6TMgkYeATdS454IVIBE3IYhi2KFEud4IKPBXz+kIqM1SJ3CP4ouKcutj3VIHlkUkCXXJKackADclEQjemhS3GAJXfUrkxOMJCIm4//zOf+nwjIyvTSMYieeRYxX/TshqD97fQKvypZOFp+ZED6FlctqTDIatxA17Pr1zCogdoGCv6//eU4yeSI6rCTni5grABFcx7jVZoTqlkzBUmMDSPEMY2ics+e6zkgACecWcW3FyeAJDvOnUWNER1KhVmxxrLySA/yfAYvy6jX6V1VhAiCy0HxLTSECMJBbnYuYeRDxxVfYvEfDAerpmv1QAAAAASUVORK5CYII=
""")

#id: 143 - Philadelphia Phillies
PHI_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABTUlEQVRYCe2WPQ7CMAyFEwRcgKGFmQF6A+5/B2AAMdIKoTICA4UMr0qK49RtJASiixPH9vvqpD86TxeV+uA1lGpX16tKywOblk/mSo9HbAwWWwMkxw1ygjY97+qYYrqsx9RgQDmbPom4NDcAoFUfccBwNdgtSI5r1AjaYprVMWRe9TrrWtcxGHg7wFEj2WdtGMQk+RZDx3oA3klNVjHLVOhQoToFgTXbkgBkC02WaWPkiwSIrMGWEwFIzkV1v7HCWBQBIKmNTc97J+yUrZw5JiSA76D5/CgGS52hR3nBsmM19zGyW26L236nmmdi5zZD2BcRl9gs5JuHapBb4Csm9YfETT22A1JBxLcRRmxUAIkwAKJtQRdxAxENAHcktX+Afwe+rwPS70DoqRB1ILa4gRMBhO6my/pvAHR9DYu3gPrV7iNuANg/oi57Ks15ApjLTyQeWo8UAAAAAElFTkSuQmCC
""")

#id: 144 - Atlanta Braves
ATL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACxUlEQVRYCcVWvW4UMRC2l1wEFBwJCXQUCAEpwt0+AQnQUYDEm/EUSEgJ0CAhhVDTXECKdBUFiCK55SQahIJyy3y+He/YXt9uLptgKfF4PDPf/Hlu9bW7T3P1H1dyXtjZ8LXK9rcDuIWA0zIDwFiD5U2VjncD62fmwLcvr9TlxY4BDlAF40wckFEzFqJfufeMj3ZvvQdGlPK/hyMn8hg4vGg1A4j8Y++J6n7/bSOsI1pzAOBotK6HOCt6iLZSAlPziYfc8NiKA8AarGwGkIg+z48DvmSc2gFOvTQq6dW15/IY0Kdy4LCoO1tNs3DQ8F1sn7sJTd19qzXhsI6cBzUqPoJ7RtfzQr3lSn+6gydWqrkc8I2l4w+qe+uBxFdKl8/Cl5eCczmQSwuG1qqzuORwJ8ULz4ZbDt8/nNgBRLPnpV7WlAESNVGQVXnijOUyL1PJuZuQgeK7doAhVzUV9Um+iLLhNhl9aDHT8Q7RZRJzlVN2ynsrGAHHfeMMHBA4dRZ07BosP7J0jPh1e0ltfNqq/CmGTq0Dpo4kKJ9cDEzyez/eqeTSRcOq6hGWnVkCgKPjZdOxIu/p+D2RHfqDpFv3qpqzHu/RDAD8iKT2RcezUp+GjKZqANKPLqOZIPuEdXjH+MZC50DXdBDAONXmtvjH4P6UQydAebXiE8vvE3whyZWQ158pqLx4jwmAY/VNsx3zdOS9Seta+G0nQZiGntu2dFMw9ujnG9j2DUE4yEJir9lm7Y7M9MXvAuxy2quUnR4wTnjKUqlHd37N5T3TftT6z5ENDhhymVcwojceGyAsfJ/AkY/qurNUuc8qLaTWhy/VwvUb0xJoLkyp71Co+wXiNAWHMjLlN680CnDI2DnA9fdTxEaapF4CMD21e0yN/tiw+l/fKH31ii2ldcBV4FP4zsub5tTu2xdq/c5NqyCDCRywUudE/AOmXf9uiiAIrwAAAABJRU5ErkJggg==
""")

#id: 145 - Chicago White Sox
CWS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB+klEQVRYCcWXwUoDQRBENxIERb/Bk/glIhj0KslV8a8ieFP0Iih+3SZSCy/UTnpmx13BgdA91d1VNbObQGYX52fb5h/XvFZ7/fqVbb2/W3Q19ZBnm5PCrOYGEM+RU4c710fd46AByJ00wiDdtvPm6f2j+iaKBiIhMAQVU3O+974oP4hAx1aLK992uQT4CMAUcW+gAAwaODrZf08lhBinTfcFzV5p0IC6IVeenlw1TBDVV7uqDCyvL3smRJ4aqRVM+6oMHJ8edoJ+ExBNNTL6W5C7bn8kmCzFogENcupUMIczk/bnTAw+Aoie3757HOAygpleQ+Vm8Aacx4XcAD2OkVPLxcEb8EGRQowZx7y3Nt//lclMIpgp74xRVz9mwaI4aMCFIXRy6tQikRKWNVAiTsXSfdu2zePqtqS7qxXfgZR4N2UJPRi2UpcKz9XUEN6ABkRcGnRh5fSDi9x5yIX7Cg2oAXEnZJAa+yi6IOaivvARaIBPOhSJg2G29vmLO3sDqXBuj6jX/fSY87rnv/ol9EGIIwP01fSEjwCCUkQYEUVyzZHTl+MabcAJh8So+wz5ZAO5EwrfbjbN+uUTrTBOfgnF6iY4rbCH5U0nChY5mHwDTloS8j7PJxnQKRHVPyItYY5Td1HPR38NnQQRCbPAtHecOvFPDEA2Jv4AwjQEsSFRgBwAAAAASUVORK5CYII=
""")

#id: 146 - Miami Marlins
MIA_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAADbUlEQVRYCa1WvW4TQRDeAysiEgUWokljvwEITENDzCtQoYSkp+InPAUgniHYRKKAgoIGKU4PBY/gNAiJoFhQgCDimG9uZ3Zub+/HKCOdd3d+dr75u3PmnMvpaaQ8L6tkWdaov4yw11U5mxyqKgCdFojOANj71pCXzM3daYFYDgDcv5g7R0AEBFipbHQtWysAjtSkHw4tCBxjZ+DZkrkzhU4KKLqp3GGw9qTOfeqFX1mRlZi8zXjnGUv2nzxMZqoWQMr55+u31M3ah33dpzbWMeSp6MFPliB2Lo67OsXFiBgkjpNl8uOMEuhDijnVWM/kXPdWL95TxDBVErkw3JTunJQfyEgvOMeemR7A/zi39/Fd4tj6ISAsIx6XgA4AwsTduzV0SDunfDr3Er9sDstnOs2ePnLSHaW7XtLLK9afzF2+OdDS9GAQjwyly60ZN+NPr/U00115AxAgATK7crvqHApoe0M8BQyC0FpHRocjtGe7l24X3pvZW9d/sJt2HkUPGy4BOpVB/CXUNv1yq1ljhxI57Bej9XrnuCOKXq5FA5A93dDSfOh06OpDDSZ0fO1mzp1u5XbvddXWyzgDxGwkiVqijZUl8t69kTuJhXIG7AS1AoBzdYyJiLoazoVOvh/J1tHMO3d3qOeLK+n8JwFg/CRqvUE2FgSB6cuYWmBwHvn79qcmBXSv1pT7AC8O4qHePy/fUBnXl2TM8zpsa/e4i86Lq1E/mBeP9Yc9fSgD8TRsDNz5vTkzV3f2gpB2OcmYVs4Fvo2csgGdPIo+KFd3JQAQA8SPOwP37n14+Viz1ccE6vcvZlXKRPlajMY0itNyr7QACmmmIEHJkXr1RccM5cFDKMJDqS9s11WP5Q3ph7ySAQ4t9YOoTbp1MqBbpP4S7UgJmLpTcgqS5tlZZlfSHpS/8vvg/m4JaDwNQT3sNI116acSFt9yWjX10v1+Tdq2pJ8gdCtBjrk2LxXGDth4B5iy9OPoWbH5p70H4KSOvHOKnj9EFbWW7hd9LkEyhUi9pJrSSQahBJDRU2vnbSGHXt3T3IRRiukSJjRiaQpE0JQt0YlWBgCQ8kVjOWpO6Tt+vu36kQEcpyYBuknaOEiyhYkqcZbsV02EFz4e6H835plmlCwUGRaL6ip/y6uSgqMAUgpJY4AAxVNRcJf+/Qd1lY9ijEsKygAAAABJRU5ErkJggg==
""")

#id: 147 - New York Yankees
NYY_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABv0lEQVRYCcWXz0oDQQzGd4ray/bgWVRQjz6E//DqAwv6Ih4E32CrYLF2NQtZvmQzk8xeWiiTTPJ9+WWKB1N7edM3e/ws9jh7GB0GWL+9NvT1PtE+9gkBRAazIZ9RjQsQNeLBeEa0LgAaUlwyLdW0D+cuwOrqlnurz4jWBKBNcBtttNskF0Zr0A/FE4BcI4q+Pl4wHeKSjmt8olgA6AbM9UZoomPs7dVr9RsxshEZCtkUIfiOTrzHuD27x7bmU71WWu5EXQBQpQRh1YTbf5KO5ACsW/oJAAmsRt6yPb1DTxEfXzyKnDXiUiUmgOoZUzJMy34EpJyHEPR28TP26mB1/qCvhrwKgBQ80HQrXR7+mtUQwMn1kxBrCOsnE4JCEgLovrvx2Qtes0ohAHau2VS/EnvoswqAxDUQPKykMQE8em3o9TOIdZoAVqN3NxfCBdDblkAQAnV4r/UugBZ4OQ1L2wOvbaxPAEq0o0oFuC2Vuvdn1ZFPJwD51nJFQ0QXEQBRUQ5FQ+T68F4AYIHiOYY5TW45AZATazAvr/ERALh1jYkFRPqIxwQAISxjutPPqXPUeRDxP1h0rYxLEGnf/57/ATjXmnGcbE8GAAAAAElFTkSuQmCC
""")

#id: 158 - Milwaukee Brewers
MIL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAFzUlEQVRYCZVXy28bRRj/zezDjp2kiZ02SWNIi6jECSHxEKiHXpAQ4syhoqC2aZqqF/4bFNqUFEEB9Y9A9NCqSKjqAcGhL2jakLh2WjcPe3dnd/lm17s7411DO5Z2Zr75XvM9x6z2xichXmK0L21AOAKmHRPVzzSiRXvlkcYlgWvAgo1ZACsERQJMH/WT89q5KlgVKuHqXiNSNi+kQPPiAyKxMHZqDv2LRyyEL2IhPgeMQGErlwKRchUO12GwfVK+by0VkQ1zQcW0sLZMgu1RjB/fB8tiKl26DhCCo/jM4TsoB2UY3MTa5U3YDkd9cX9KKxeken5McDsWTkejS1WQLgiYn0ckyNOVx4VwCSwFo6SeCUHGmf1iOhLeXmlq+HkF+D+4d+F+hDS1MAfDtbBFQlqrf6NibmnEjMwclHsxTOStsPnjmoYfb1y0r8b85V5ToAoPm8ss8tXkwkGEjKET+Z9cLGy0/QMaQ3k78JgFI9zBYe7mYVOn5xF2snjRFHi4uofpszMRH876R8H4IF9tz/fUsNSOCjee4cA3RHqWKvB4mfLY304P0kW4my3DgpJR8tLzF1mYoQnPHUlRUwXK5ghqi4fSg3RhltLloJlZYABsuAK+KA5cw6ao7o9UAaALI8x8kyDAHy4g5CSADS8ljBVYLGUcLzIFmIOAfoNjdmF+EBTtZf47bheuEaJ9oUNZ8jCCR1bpU3Ars14hEwKm6ougOJhcmf/uK1SQ4pQqoYz1lbtEShFOFvB2bMqdDly/hA1KV4tRgIU2ZdIszdVhchH4+8CNTqaASWkU1e9Th2TOaYT183TLFSosXQuPrkjhNrrGLuqnjlCx6YKzzKeS8MmlB4S/BuGVNT7JJqRgNgyDbKjUgahOU1CJoJPgabMPF08v36VLW2DHj6Bx8jBGQpETHpBlamfp9jSbpkDzu9+oTWSZJJnajOT43Yh/FgNySyY1rSpFQj54DLr1czJ//ewB1CqZkmFoaPicaA2/jMkzc5EbuNXAox+2YfYLlk8yJP9Kv5+nMRCpQ5+Ny03MnNQrnjyzz72OCqWVQR6XQzJxqUnsLv8V7eVnZmkeHnU9OZIGxXZE1EHdoEqwbVh8C75jwQnjS2gWkG6wQifVNuLU/4yJXiqckTvuXFnD9vJ9ON4T4OhteN4O1i/ei+JIjaDaYo06s4H1738hBcg+W+OwS1lwagpIWU7wjOIgn46qMi3qaBPdEey9fwulY3E3NI/dxfMPfocjBDrK64iFFdTPzVJcz8BlLlpXSeGgnbLLKVAKJ/Hwwl6KMLgQXgkea0Ic/RWjN98hR8TxInvRxPW3YB77mbKI3KQ8UGRtMMl9pb0xSvxAe5jkFJBuqJKfdneKrdD59h5C36ZwjMdgeTZA8UPuan+9nuouKK05ObB55Q6lpt7ccgokVL2fMgYJTM5u2YXNJ1RQbi049QhlGKFsy1KUgelFnbZQAWkFX+RTUfK0e1Qx+fASK8PHdBP7SAp6TVLRkXnjU+Mao1kdhQpMsgCC9V86Kjatxz97k4qIS3nQGjiJt12+SRIZKp/H7woJdX1KXnrAHlh4lRJRF6nv+iyfhhwlYwStr/7oQ7LJqj6GOerDvvYxepR+6vDeu4bqzQ/RKXOMJH8cCEGmrVlSkzOjKlRAHk8v1MBs3V8SzoSFqRN0O9MDu3EUoMiXw7n+Nvitd9ELXBz+9DUtC2SPYaLYbUOf5RFX+rS+uYHa6Y/IcAWvJTqP3v59ZPtEA2OK++WjtbWyga7w0Dh3OGGpzblSrJ3ShgWv0tP7T+xfOkItNG4gKk7UxPoAVbgEBT5ZUDzD3JczsnkXjqEuSLATAZvLt9ENhr+OEnx1bq4+oCo4BeYMv+f/uiBhGJm65KBL1ayxFDcr+WeFR92QkYuoJvbGwcrP0V6lPx/uOOpLij8SRgPzCyuQ0Kk+T2DpLPPdd2hr4uD5Bj3Z0pOhi5dWQOVUpEziMhXvv9b/AparAWFoF74ZAAAAAElFTkSuQmCC
""")

# league IDs
NAT_LEAGUE_ID = 104
AMER_LEAGUE_ID = 103

# division IDs
NL_WEST = 203
NL_CENTRAL = 205
NL_EAST = 204
AL_WEST = 200
AL_CENTRAL = 202
AL_EAST = 201

def struct_TeamDefinition(name, abbrev, logo, foreground_color, background_color, id, leagueId, divisionId):
    return struct(Name = name, Abbreviation = abbrev, Logo = logo, ForegroundColor = foreground_color, BackgroundColor = background_color, Id = id, LeagueId = leagueId, DivisionId = divisionId)

TEAM_INFO = {
    ARI_TEAM_ID: struct_TeamDefinition("Arizona DiamondBacks", "ARI", ARI_LOGO, "#E3D4AD", "#A71930", ARI_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    ATH_TEAM_ID: struct_TeamDefinition("Athletics", "ATH", ATH_LOGO, "#EFB21E", "#003831", ATH_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    ATL_TEAM_ID: struct_TeamDefinition("Atlanta Braves", "ATL", ATL_LOGO, "#FFFFFF", "#13274F", ATL_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    BOS_TEAM_ID: struct_TeamDefinition("Boston Red Sox", "BOS", BOS_LOGO, "#FFFFFF", "#0C2340", BOS_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    BAL_TEAM_ID: struct_TeamDefinition("Baltimore Orioles", "BAL", BAL_LOGO, "#DF4701", "#000000", BAL_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    CHC_TEAM_ID: struct_TeamDefinition("Chicago Cubs", "CHC", CHC_LOGO, "#CC3433", "#0E3386", CHC_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    CWS_TEAM_ID: struct_TeamDefinition("Chicago White Sox", "CWS", CWS_LOGO, "#C4CED4", "#27251F", CWS_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    CIN_TEAM_ID: struct_TeamDefinition("Cincinnati Reds", "CIN", CIN_LOGO, "#FFFFFF", "#C6011F", CIN_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    CLE_TEAM_ID: struct_TeamDefinition("Cleveland Guardians", "CLE", CLE_LOGO, "#FFFFFF", "#00385D", CLE_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    COL_TEAM_ID: struct_TeamDefinition("Colorado Rockies", "COL", COL_LOGO, "#C4CED4", "#333366", COL_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    DET_TEAM_ID: struct_TeamDefinition("Detroit Tigers", "DET", DET_LOGO, "#FFFFFF", "#0C2340", DET_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    HOU_TEAM_ID: struct_TeamDefinition("Houston Astros", "HOU", HOU_LOGO, "#EB6E1F", "#002D62", HOU_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    KC_TEAM_ID: struct_TeamDefinition("Kansas City Royals", "KC", KC_LOGO, "#BD9B60", "#004687", KC_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    LAA_TEAM_ID: struct_TeamDefinition("Los Angeles Angels", "LAA", LAA_LOGO, "#FFFFFF", "#BA0021", LAA_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    LAD_TEAM_ID: struct_TeamDefinition("Los Angeles Dodgers", "LAD", LAD_LOGO, "#FFFFFF", "#005A9C", LAD_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    MIA_TEAM_ID: struct_TeamDefinition("Miami Marlins", "MIA", MIA_LOGO, "#00A3E0", "#000000", MIA_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    MIL_TEAM_ID: struct_TeamDefinition("Milwaukee Brewers", "MIL", MIL_LOGO, "#FFC52F", "#12284B", MIL_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    MIN_TEAM_ID: struct_TeamDefinition("Minnesota Twins", "MIN", MIN_LOGO, "#FFFFFF", "#002B5C", MIN_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    NYM_TEAM_ID: struct_TeamDefinition("New York Mets", "NYM", NYM_LOGO, "#FF5910", "#002D72", NYM_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    NYY_TEAM_ID: struct_TeamDefinition("New York Yankees", "NYY", NYY_LOGO, "#C4CED3", "#0C2340", NYY_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    PHI_TEAM_ID: struct_TeamDefinition("Philadelphia Phillies", "PHI", PHI_LOGO, "#FFFFFF", "#E81828", PHI_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    PIT_TEAM_ID: struct_TeamDefinition("Pittsburgh Pirates", "PIT", PIT_LOGO, "#FDB827", "#27251F", PIT_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    SEA_TEAM_ID: struct_TeamDefinition("Seattle Mariners", "SEA", SEA_LOGO, "#C4CED4", "#0C2C56", SEA_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    SD_TEAM_ID: struct_TeamDefinition("San Diego Padres", "SD", SD_LOGO, "#FFC425", "#2F241D", SD_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    STL_TEAM_ID: struct_TeamDefinition("St. Louis Cardinals", "STL", STL_LOGO, "#FFFFFF", "#C41E3A", STL_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    SF_TEAM_ID: struct_TeamDefinition("San Francisco Giants", "SF", SF_LOGO, "#FD5A1E", "#27251F", SF_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    TB_TEAM_ID: struct_TeamDefinition("Tampa Bay Rays", "TB", TB_LOGO, "#8FBCE6", "#092C5C", TB_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    TEX_TEAM_ID: struct_TeamDefinition("Texas Rangers", "TEX", TEX_LOGO, "#FFFFFF", "#003278", TEX_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    TOR_TEAM_ID: struct_TeamDefinition("Toronto Blue Jays", "TOR", TOR_LOGO, "#FFFFFF", "#134A8E", TOR_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    WAS_TEAM_ID: struct_TeamDefinition("Washington Nationals", "WAS", WAS_LOGO, "#FFFFFF", "#AB0003", WAS_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
}

# SCHEMA

def get_schema():
    team_options = []
    for team in TEAM_INFO.values():
        team_options.append(
            schema.Option(
                display = team.Name,
                value = str(team.Id),
            ),
        )
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "MLB Team to follow.",
                icon = "baseballBatBall",
                options = team_options,
                default = "158",  # MILWAUKEE BREWERS
            ),
        ],
    )
