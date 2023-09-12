"""
Applet: NflDivStandings
Summary: Show NFL division standings
Description: Displays NFL division standings for your favorite division.
Author: Jake Manske
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

STANDINGS_URL = "https://site.api.espn.com/apis/v2/sports/football/nfl/standings"
STANDINGS_TTL_SECONDS = 300  # 5 minutes
HTTP_OK = 200
RECORD_FONT = "CG-pixel-4x5-mono"

def main(config):
    division_id = config.get("division") or "10"  # NFC North default

    standings = get_standings(division_id)

    # if we get no standings at all
    # could be due to some HTTP failure or we just don't have data
    # just take the app out of the rotation so we don't display something weird
    if len(standings) == 0:
        return []

    # otherwise render it up
    return render.Root(
        delay = 80,
        show_full_animation = True,
        child = render.Row(
            children = [
                render.Box(
                    width = 5,
                    height = 32,
                    child = render_lefter(division_id),
                ),
                animation.Transformation(
                    duration = 180,
                    width = 236,
                    keyframes = [
                        build_keyframe(0, 0.0),
                        build_keyframe(-59, 0.33),
                        build_keyframe(-118, 0.66),
                        build_keyframe(-177, 1.0),
                    ],
                    child = render_division_standings(standings),
                    wait_for_child = True,
                ),
            ],
        ),
    )

def build_keyframe(offset, pct):
    return animation.Keyframe(
        percentage = pct,
        transforms = [animation.Translate(offset, 0)],
        curve = "ease_in_out",
    )

def get_standings(division_id):
    query_params = {
        "group": division_id,
    }

    # hit the endpoint and cache things for 5 minutes
    response = http.get(STANDINGS_URL, params = query_params, ttl_seconds = STANDINGS_TTL_SECONDS)

    standings = []

    # return nothing if endpoint failed
    if response.status_code != HTTP_OK:
        return []

    # get standings attribute from the response
    standings_raw = response.json().get("standings")

    # if there are no standings to display, return empty array
    if standings_raw == None:
        return []

    for team in standings_raw.get("entries"):
        standings.append(parse_team(team.get("team"), team.get("stats")))

    return standings

def render_logo(info):
    return render.Image(
        src = info.Logo,
    )

def render_division_standings(standings):
    cards = []
    rank = 1

    # sort by playoff seed, it seems to be the most accurate
    # the API endpoint appears to return the standings results in an indeterminate order
    # we have to do the sort ourselves
    for team in sorted(standings, get_rank):
        cards.append(render_team_card(team, rank))
        rank += 1
    return render.Row(
        children = cards,
    )

def get_rank(team):
    return team.Rank

def render_team_card(team, rank):
    info = TEAM_INFO[team.Id]
    logo_width = 59
    return render.Box(
        height = 32,
        width = logo_width,
        color = info.BackgroundColor,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, info.Offset, 0, 0),
                    child = render_logo(info),
                ),
                render.Column(
                    children = [
                        render.Box(
                            width = logo_width,
                            height = 26,
                        ),
                        render.Box(
                            width = logo_width,
                            height = 6,
                            color = info.BackgroundColor,
                            child = render.Row(
                                main_align = "space_evenly",
                                cross_align = "end",
                                expanded = True,
                                children = [
                                    render_div_position(rank, team.ClinchIndicator, info),
                                    render_team_record(team, info),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def render_team_record(team, info):
    return render.Text(
        content = team.Record,
        color = info.ForegroundColor,
        font = RECORD_FONT,
    )

def render_div_position(rank, clinchIndicator, info):
    if clinchIndicator != None and clinchIndicator != "e":
        div_position = [
            render_rainbow_word(str(rank), RECORD_FONT),
            render.Padding(
                pad = (3 if rank == 1 else 4, 0, 0, 0),
                child = render_rainbow_word("." + "(" + clinchIndicator + ")", RECORD_FONT),
            ),
        ]
    else:
        div_position = [
            render.Text(
                content = str(rank),
                color = info.ForegroundColor,
                font = RECORD_FONT,
            ),
            render.Padding(
                pad = (3 if rank == 1 else 4, 0, 0, 0),
                child = render.Text(
                    content = ".",
                    color = info.ForegroundColor,
                    font = RECORD_FONT,
                ),
            ),
        ]
    return render.Stack(
        children = div_position,
    )

def render_lefter(division_id):
    div = DIVISION_MAP.get(division_id)
    lefter = []
    for i in range(len(div)):
        lefter.append(
            render_american_word(div[i], RECORD_FONT),
        )
        lefter.append(
            render.Box(
                height = 1,
                width = 1,
            ),
        )
    return render.Box(
        height = 32,
        width = 5,
        child = render.Column(
            children = lefter,
        ),
    )

def render_rainbow_word(word, font):
    colors = ["#e81416", "#ffa500", "#faeb36", "#79c314", "#487de7", "#4b369d", "#70369d"]
    return render_flashy_word(word, font, colors, 1)

def render_american_word(word, font):
    colors = ["#B31942", "#FFFFFF", "#0A3161"]
    return render_flashy_word(word, font, colors, 4)

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

def parse_team(team_raw, stats_raw):
    abbrev = team_raw.get("abbreviation")
    id = int(team_raw.get("id"))

    # initialize variables
    # the API result is annoying and forces us to loop through
    record = None
    rank = None
    clincher = None
    for stat in stats_raw:
        record = get_element(stat, "overall") if record == None else record
        clincher = get_element(stat, "clincher") if clincher == None else clincher

        # this is what we will sort by to make sure the standings are in the right order
        rank = get_element(stat, "playoffSeed") if rank == None else rank

        # break the loop if we have everything we need
        if record != None and rank != None and clincher != None:
            break

    return build_team_struct(id, abbrev, record, rank, clincher)

def build_team_struct(id, abbrev, record, rank, clincher):
    # rank may be 0 if it is too early to rank teams
    # in which case sort those teams to the bottom
    if rank == "0":
        rank = "32"
    return struct(Id = id, Abbreviation = abbrev, Record = record, Rank = int(rank), ClinchIndicator = clincher)

def get_element(stat, element):
    name = stat.get("name")
    if name == element:
        return stat.get("displayValue")
    return None

def get_schema():
    options = [
        schema.Option(
            display = "AFC East",
            value = "4",
        ),
        schema.Option(
            display = "AFC North",
            value = "12",
        ),
        schema.Option(
            display = "AFC South",
            value = "13",
        ),
        schema.Option(
            display = "AFC West",
            value = "6",
        ),
        schema.Option(
            display = "NFC East",
            value = "1",
        ),
        schema.Option(
            display = "NFC North",
            value = "10",
        ),
        schema.Option(
            display = "NFC South",
            value = "11",
        ),
        schema.Option(
            display = "NFC West",
            value = "3",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "division",
                name = "Division",
                desc = "The division to display standings for.",
                icon = "football",
                default = "10",
                options = options,
            ),
        ],
    )

DIVISION_MAP = {
    "1": "EAST",
    "3": "WEST",
    "4": "EAST",
    "6": "WEST",
    "10": "NORTH",
    "11": "SOUTH",
    "12": "NORTH",
    "13": "SOUTH",
}

def team_ctor(fg, bg, logo, offset = -15):
    return struct(ForegroundColor = fg, BackgroundColor = bg, Logo = logo, Offset = offset)

# LOGOS
ATL_LOGO = base64.decode(
    """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""",
)
ARI_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABGNJREFUaEPtmj9oVDEcx3+pbUWE2jq4CXYT7HBFUHCQOrrZTXDxFuc6dmqHQseKoyDeIjgWHNw86CAoSG9wcBBacBA6eKcgYv9Ffu9eXvNySX6/vMu73p8Gil5fkuaT7ze//PJyAkaoiBFihTPYYVU7U1ZKKQGgIYSYHwXYBQCoI6gQYijtnYNK1VXCtoQQM8Oksg824RwmlUlYpewwQDth1bJtx62TMsjQHYFIrVs9RpnAg2pvr43NoFyv12FhAYN2vgyK2izYzck78GD/Q0a4sbEBS0tLtkDd1/u008ZaYEr+i8BYdGj8bLO4Ngt9tX15YWu1GlSr1WzsCtgGzQBX/TwTQjw9jf3bmimpINVqtWBmJp9X6MBqwKba6veE6j2P8l7YNOp2iGADxkp78h88OfjsFQ3XOq55Xykr4JGwLuDl8etwe+wy6caXRzvw9ugHWc/lgpjgzoTfyJMxbcwC1cfjn7B++DUXuEgao8Kbo++AP7ZS1r7OhtUVNm2M8ByVORNCRPtZIcQupx9bHR/sNQDYUY3MBMO1bosOxGz3/PAbvD/eS35trvOi1vaeW3Ur2464ZQMj6B84hEf7nxJo3d5FgMlDOgWMg+gFtLJ3s9mE6enpBD4UOAi20WjA/PzJWxs9q3p47irgD6eogV+EcXg9eYvTJKuj2iqVQ4BJ2NQ+2TlPt3NRRV1JCLc/bL+6ugorKytBCrNgfcCoDCoUWlzA3GWB7bU1zMrB2bD9DsyxcxCsD5iriOkAn8JUn6HrNxg2NjAFywHmBqvosEo5brDB+rasiZvEYNvt7W2oVCrkVlQIVlc3RnQ2gTWlcq73HS/TNrtCiFlXsOwaNt3ck/6LRmYXbGLhzU1YXFzMxu8C5lg5Kiy1vqjtSbezS11XH6XClp1s+GDxmbmmOWlkYWV9sGsTczAnpighrc8pdW2gqiPqoNAVbNnqpv3nJsVUVG61J1Xc/Z3867Nz17CxgTn7bqZkCqo+U8CxYJsA0D53tY9e3uhJ+ZsCVmra+kFgl7pRYFN1M2DcKnDLUCUkwTC3IdfEPL4/Aa+WL1gfu4Cjwca0M6WsSWiC9wTWBTw3dgnWxm9Q7s2e+2BtFq69O4Dq+t92gNICVhq5M0GjKpvC4tpFS3fshVfEeXgxcZOEDoXVO0xU3ZpKorO5dqPD6ur6vofiW8fdwOqRuaewpoQmPKqMautFf4Vqs4BuY7XVuKzSE1j1x81bhWzWjW8eUbeDPt9zLs/UW4xSbGxVxDIqXWkMYl+Of5HrWZvIjrrmqxkpJd6gVYQQ95IYwu49YkVdcdu1aIiSnHdPmaMiMgR1JaXEqxW8YkkK50t1VKJPDeBUlNUHpatsZl5GvexjiJq5bYmajV48l1J6L9G6VfTUbUwFMWVrvNfBg3lq9a6c2FXjMlQ3L9I4r1u44+g7WBy45dY/yjijdMKd2ZB6hsJRxhmlkxCIkLoIXDTy2v5OX8OGTAyn7hksZ5YGsc5IKfsfE9xLWkuYFI0AAAAASUVORK5CYII=""",
)
BAL_LOGO = base64.decode(
    """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""",
)
BUF_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABK9JREFUaEPtmX9olVUYx79Pa7QUnbJVyi2p2S9dIxAtf5D/CJUUCpoTxBZFRoqMESki26DCQP/IfomWNAsya/1w4HQsLyNRULBIWDQKCruKS8Ra+KMhxhPn5Z7Xs3Pf97zvufd97+629/61+95znvN8nu9znvO8Z4Qx9KExxIoEdrSqnSibKDsKIpCk8SgQ0RMhUTZRdhgjwMynADycdWEBgKNEVGbrUkmmMTNzGBAisvLfanAYB/Idw8yfA1ipzqfZb/ma+6tnHSZPrBC/Lyeib8KsO+ywqornLlxGavGHYfx2x/D3r4i/VxPR3qCJwwarQpoUDAIQv2eBxxHRv6bxRYeNElKC9X7RgIemV6ucvxHRvTp40WCZWVTP68KBQpU0qTdtygT80blGDvmPiG6WX4oCy8wXAFRPe2o3zpy/FCYzIxkj0lut2LHCMnMKwFk3sobqGgmdZiS7l13g2GDj2Ju2AYkdVkLuaD+F9dt6bP2LdHxssMx8H4Bf4yxAW9YtwOYXHs0JCA8OgiqcBgP1mzrxZdpxQx5J0aaxVNOmyra8OBevvzzfU8nL6TQyS5eGVnnmlSvO2E3vHcXWT07qDccjROQ8tNqzzHw/gK8A1Ome1Cz5COmdz6AmVekN0N2NzLJloQFsBkpYPdhW1djUkJ9vbsbF7dttfIptbMGwEvTn8eNjc9LGMJWXY8bAgDtl8Np13Dr/3SEpqyqrFydjGgvYYoOWVVXhgUzmBgADN83xf/NRg+WkrHKO6ynsCxu3qqm2NlSuvPE213Myg0VrRSmI5pNVdRUR7VMtehaoqFSVe0ku+HRTBw4e+z0aIh8rP7U/h9qaqiFtohyaA2urqg60uqULe7v6YgUyGfdKXyOsvlcr6+uR2rMnZw2bc7UY9G2tT+D5JbWequbs2aC7H/kGIcYVE1RWVhmwTw/14dnWLr15cL6b7qXcNGbmdgArgq44BKhox0Rbpn82NszB1sbHrEU0BU6AzpjX4tjsO/6Ga1vO2da4EBsaZhshfdPYuB+yt35enYqYJ51SHVMjzczfEtHjMoMuXb2GiQvfNwbHBOt1lpqMhW4XvfpfuZgKeXv1BBw5sFGs+QsRPei1eNhtoILqyip2JxHRP2HSKRBWQr605TB27+8dsk9USD81g2D1/SjH67Y79zVi+t23qeb+BDCLiPrDgOYUKH0SM4vbugqvtC0E1Ms53Z46puKWcvz4Xat4dGf25uMuInJvQKKCzam6QonmNzvw9YEf3DVk4QhzQ+9uB+U2XzzzC55bXCxv/70C4JvGYfbo1Dsq0dPxqrB7mojuCYowM4sW7jN1HDMfArDYZ+5FIhpyRxq0hnWBCgNqo2aYCg/gBBHNKwQmaK5vb+z1urTr4yN454O0Y1PAhknbIAeK+btXbywqwWsSVq2W+uE+GmCdfxeqsAJKprYAHomq+h49EuxEbz/m1k1101U8/3vgKiZPGjfiUth4znodEWKC0/1EcAwUc6+6x5ffosz8JIAuHYyZ3yaipuFwttA1je3iSFbRqqkoNIqlOD/wRaAUnc7XpwQ238iV+rxE2VJXKF//EmXzjVypz0uULXWF8vVvTCn7P6cs80vij/50AAAAAElFTkSuQmCC""",
)
CAR_LOGO = base64.decode(
    """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""",
)
CHI_LOGO = base64.decode(
    """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""",
)
CIN_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABB1JREFUaEPtmctLVFEcx3+/mauN4+iYjxoXuigQKshchEVEalCGUQpR2/4EW5W0LKJVK1u1CFpEVIoxLVM35qqgKFu0EFSy8pFOIVk+btyxM97HeY5zjzped+rvPD6/7/f8zuMi7KAf3EGsEMDmq9qBsoGyeZCBwMZ5ICIVIVB2Rytrmqa5BRPwHRETKvOSsrEddvBht6f/pqMN3DGH332AqR/zUvNqbznpjMMQ4KHjorYRRPwjChLC2kERveFtiULoayzljlPwYkY0j8z/ly5WSsV2pmqhe/CtIxZpE7RFSMMu/kxBUbzMMxGZycnCVkdCMH62XAqW9Nl79yZ0XL+dacMD5sKKVLVGyCWsTF/WmLTk2csKC5gJKwO6GbCtwynon16iqi8C9h22eSgFQ7P0ydlnnDxWCq17C4UW5i2JjoM10DsyTvqIIeKCvUMqrKyqMsrKrlcZC5ckZ2Fxlb8L8tTdVrAyiVOCVVFVp7IyoNZ8fk9NQqSqOu1ed6FyKGua5j0AuMZaOLRtTGQ/9ySZhzHThOWOPcw1Kws73/8M4i2XpGC5C8JX2P+Yy+1VVGAZWCvxRt80c88VHiqslsTamwUrC2rNNe9h7UuJwNIOFlteWZGqNFBacUr/TbiLa7Qxbb3yYB3FMVoCxuNRamEijNph3clVreakvYqi2xo2ZiDMtVU4ihHLusLjojv7vGr8oCEGV2sjWe+PPGVZFmapKgLesI1FpyiVAuPOGK0tKzm8LSdnNtYJm9gVgolW9uXeeP4FwFi7Ofmy9ajC8t7u3NXYrayomPl+qBDB/l0FKE6uv0GJHioJ8KdfK1A/MJdxtgwoCWZZWmnNWhOhraO6WBhGTu+WKlKysNmomnNYq0OVwuGOzwZWRdU0cNgAo+erZ+1mlDVN8w4AdPFOVMRiCysmlL2cdYTKbiFaYJ0XgqeIeMVzXBS9/NsLiFvdC4lC6GG8H9tjZQsUafPqRBxOVRbInGodMbZ1+x4Rj3hgrT/YgVl3S9KryrqiWf9NUxnUxw0qCIlXtrDl4s77gE2XSb/7ETF9aPYUKLe6KsCyViazuHUgCjfqojmHVarGKuq6CxALmKZscRhh/nwFE3b0TDnUFIU2YmHH4YL1ujgAAM1kFJG6dmBVdXnJycbCdlUB4Bsirr2+8e6zqupanUWTM7C0yv4korJlWbGqsOGuR4CN5zJO4L4uuv2SDTDPc37Dii4D0h+2LAgZO4sWmEoFF/VF/u+yLvUSwLUx6chvdVWtak+A8WQMIOKs5ll/snTvu+nfP76WTTg17vPYBExOrV8MRF/tM8Vl32GAaAlv7CpE5H71VroIbIjSp8air+32YaVgfZqn9m4DWO0p1zRgoKymRGsfJlBWe8o1DRgoqynR2ocJlNWeck0D/gMkmCdaV+q8OAAAAABJRU5ErkJggg==""",
)
CLE_LOGO = base64.decode(
    """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""",
)
DAL_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABLZJREFUaEPtWl2IVVUU/pbjNEIagqDlQ2I+GM2MJqJQpg/6oL1kiTSB3kkfbBoVf8D8QRtFfRgQxRLzD2qYKZqiaKAoe0lRGymUGdRBxYcJHyypEMwgHecu2duzD/vuOefc87PPuZfmnqfLvefstb7zfevb66xzCcPooGGEFRWw/1e2S8IsMzMRZR4784BCNRWwGdRO5swKVqvqGzF4uR1ZS7kkYKk2B+7rqIBNU82ZMiuNqTbn4sma3QrYtKSkmJWMlqBuM2NWl7ACK/fcDI2qAjYNGesSVutnLeVMmPWScCmkXFKwI+oaRZ+cWd1mClawKQ4lX/1zFq1j6mD9XNh1YqfJyMKVK2BturHpwma7aMi6iojyNuPra6XKbJCEVRKGK4sJxojUwTJzN4CXbAdSTOqg9BjmFmQ7PoDzRPSyVJC5uGDjwcBDbN7faSXuBx0/yq1FyXVIPO239bmFVmK2bmzAqJrqIc/LnjIWgP2Si5ONH6teUo6zvqkUmbvHQM+3Zpl5KoBrXoYSJyF9HT92k67rKOgFIrrqtVZRg2Lm3wBM0mtP723jJJjkGlUSuvKc7/qJ6LmgtYuClZs/8x8AJijAQiH5K+2+dZgETNC1CqhqM2Vuj2v+TyIaXyxuKLBubTHznqNdaDn0tfwqyHiKBY76uxlre9Ni7F23NNLQLhJYh+UC8/ro/RVofmtBaiwrkCe+OoV3dn5ceJMjvlWIDNYBvBhAl183FJU1v/O9lON810BEX0aNEwusJuteANNtm1eACfUS0YyoIF1DjXuhBngAwEgFeMyTo3D31xOxZa2APjV7Ff759z9dtnkiqkqSbyJm9cCiERHd0obWT90Ej37xE5p3fxI6vyMtK/Fuw3z5vCuOA1uWYWPjokgmFBTMGlinlu9QbW6scuqgRiKoTrWyuE1ET4e+W0VOtA1WTvxFj3tw63KXoSjJChlv2vc59rd9b31ckwrYJPuvObqxOa6xBjbMs6tras4bgZBSLr+aDQvWa1sxQac1ZrXCrHi/DOChmhqevXgd8xr3FmD4pXMXZtdPcbckBXpwMI+R094uOPeHY+9h0SvT9CnkGCK6F6X2vc61BTZPtTm5ltezqwJ2oa8fs95scfMQ24rYXsRhOrfB7gMiqikXsNKFF86px8njm93Ex40djb9+PjIEjHlD1M2Ys2w3untvuPv0a2sO4NvTPdZc2RazEqzXEFxnzfm9j4jqmPkygDq/VjMNV04M1u89jilNJ/ltRNTqujLzegAHg8arBQO7iE85puytg1UBVJKvL5iJbz7cELh9iBu2cvtxtHWddSVsriOlXy5glew++64by7c8rlNXiiGSNId8u9Yswc7VbxS4d0nBFnuPAyDyhN/zTyaW3gclkrFK7NlnxuHm73/rbCaa7JssPz95Iq7130rsylbA6m2gNKYQsi22ZzLzfQBP2PwrUWywutzmzpyKM+07rIAc0joy86tN+3Dy3CVXOXFvZmKwUUyoGJu+DwbaG4okrpwIrJPcYSJaGxdI2OvE7gRAjhczZdYxkEtEND1ssrbOY+YeAC/GARyL2VL9OVrrvAaIqDrqDYwFNmqQcjm/ArZcmLCdx7Bi9hHiCd9aWp7/ZwAAAABJRU5ErkJggg==""",
)
DEN_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAAA0RJREFUaEPtl71rFFEUxc/JRsEqk/wDyq6VTaIglpaCKFq4G1BrPxBsRG0sIjaCdoqorZiEWUEQQbCzTaMRrIxj8B9ItvMre2WW3fB2eTPv7uxMBjdvy503997fOffemSF20Y+7iBUedlzd9s56Z8dAAd/GY2CiFcE7650dAwV8G4+BiX5BFdLGrUbtjkDumfLKxMSR6eW1j2V2Ta6wm42qaGCCMMo1ryZnfCY1aatePT/VjBbNYDHQYLFayL6iJv/OBIs/NrSF5nEuFTY3sORK/wRhtDcPEE2MoWHjoElOTh2KKlxAezCxw/l2EEYVTbGjnnHCxglsM9aarx4VwQqBhakwumsWslE/MDfdXP/U1/712jwoy7aC2xWZnVn6/nlUGNf9qbACsNWodpxKWiqKeV0JwuhYWkekxXcBDHPduRUVMPZ8wstB89vzYYop+qwT1uVIr0Cb8yJyFsBrJUSb5PbsikjnMUZSVaMmhzqQzWEBXk6H0cVeIhG5BuCxJrHyzA0A7wF8Ial6hqfFTYTdrNcugfLMNU8iEjsXO1joLw+H+2Bd82m2aq/NCiW0BB8Fug+2Va8dFMpXS46tIIwm4//zgOwVLCIvAGyPgUO4pwCuGGeaJBvDiJ3YxlJHhU1sGfM48swYhd0k+dAsVCtiLFTW5aVaUNpCBlXO0nKaXEZnxAaskpzTOJz+UtFd/5pAvTNpgC6QAQhN2vgz8hSAwxphnc66CnRBishvAHs0lWeA7YTVtrYT1phZ6yMmSVER+QVgqC+arLDa8VHDDgYUkVckz9kc03aD7d68gOOXEZInzByZYZPaUgn6iOR1EVkDUEtyxhLrJ8l9rhzdtn4C4KrZebnDpj2LDdfuA7idNscp47H9zuyA/gDgeOGwtmezqz0H4RJAzpB8Y7tmxF8HsN+2OAtxdsgWXyR5QbOtLXsj8cvIEOQkyXedrZ0lSdZ7Bh3RPBtduboxT5N8axNjx9o4yYnu/7dIPnDBaK5rXx9LczYPVy1izpJcTRJoR2F7m7oIUE0HeFiNSv/jmR13tkyRPGyZ6heZ2ztbpLplxvbOlql+kbm9s0WqW2Zs72yZ6heZ2ztbpLplxvbOlql+kbn/AWvFW0tHCd4YAAAAAElFTkSuQmCC""",
)
DET_LOGO = base64.decode(
    """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""",
)
GB_LOGO = base64.decode(
    """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""",
)
HOU_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABPVJREFUaEPtmm2IlUUUx/9nt1XStbCIBZdeNovoBWJ7dTesWBKy7UtCJFIQJhYYFEFg7YcgM0z8kEEQGhmYGwUlgS1FJYIv5a4mK0pU0tYiS5ahrZvWru2JebzzOPfZmWdm7jx3dtO9H+89z8z5zf+cM2fmuYTz6EPnESsmYc9VtSeVNSnLzPcB+MJB+fVEtNTBLqqJVVlmng3gkOoVXXZvrpMvPvsoVnYsSW2IyDpPDOpcJ5iZpRM2wKyzzz+9EKtfekr9ejERbYgBZZrDCCtBfSD5920TTs2yiNStgi+ohJwo4eqs7LkKKhagLIyZuQfAbctXrMNrb3Ra0+v/omhad1SiSlSd6KFrzNlKYJPwiLC1MPMdALYSUb015AwG2TBOthrfChwDVvqvbocAmIhqXOGDYXd1vYmW22+Moq4KPPDWJvR1rMFdf+xLvnZZ8GBYMdF4FCqh8PGtu3Dw4WWomToFLQO7rdCFwIpZZl81C4d6zlRwl1V2Db08OwG889Lm1MSmshbWN2/LKnqpi4oBLPNXBW79bS+otka74GPaRd+KrFv5wb4uzKifFkXlrLpiUpPCRtgQddNCEqFX1sFK4Gx0aQ8CUt2pjfMwPDwSnF7VOiDowlh1ViisAufCFqGuLp+LKGI2UJ261iNe0cDqViUXwrWYqQ3Fv4ND+KZpbm7UlXL3FiJKNuOqHd5dYr993hxs6VylmjYR0c/MPB3AkG6M75csx9HNn7sMLwvVB0S00AqbqBBwW+HkUclIzWv1OXVb8RlPqcp1RHTaCTYL3H/4CK5sfsR3Xqu9DjYE1Ctns96pCi96cgXe//grK4CvQRY4OiwznwRwYVpMLDeLvoCmai2+D4HNbjvWMM4cp6xHvztvvR679343hlco5nJsLEpZ5w5KeqqC1ja0YXR01Em0BQ/ejY82vJzCXdPUiB+7N0WDzTsM5O2zOwG0VhK+pspqUzdE2Tm/7EBtvdixzKcu6029qvATz6zGO51dTgrrgKsBK5XMg0wFc/GcmQ8DaPRVWQc8MnIaU2aJV0ZjP6r9P/0D2NPcrrVTAV0gvWB1eeyrks7r7BgqrKkS2w7oeeJZwzhvvzUBZ19syTEuvrodgyf+0vqz7ZO1uKf15vQ3HWwIqHXrMa1SJQf89J7KsE+7FCfd3umShhWFcVkDUOqZbeEsn6mruwDDA18atyBbCIeqWrGy4kFm/hVAQzKIY1d1YPu7uGnu49biZAph16OgSW3vnA1RVzwrFBYVuWwc5fqmWqBBypbU7QdwuauyxhqQA1sK3+NENNMnP7XVP3SASoqVq6pF5Kk6V1AYl9T1fj+kg+1tW4Sh3rOHiKJBg8M4FNZUgasBOq6wf/70KS6acaZx93mFEZJ24xbGUtVYoMHKyuK0fuMWLH1ujfOiS9BvWxbg1A99yXPVCt1CCpQEfeGVdVi11v7/CzmpBB05egzd17UlX0+74Vo0b/+w6m//vMOYmUUnn7y1mn7F/Th56m9nRUWjLxr+E9292D//bCcV2vO6OuANmyqk3Ce3PrAMX/cctM45HnlaSBjroDtWvo1XX39PC50F9blhsK6io0HFymbHz7uJlKBHNm5Gw2MPyUfnE9Fnjn4WYlYYrKL0sOj3c7y7hIiOFeK95yCFw6rzl70nivBfKRt7VWFtk8f+fRI29orHmm9S2VgrHXue/wAds2BaT7JzNwAAAABJRU5ErkJggg==""",
)
IND_LOGO = base64.decode(
    """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"""
)
JAX_LOGO = base64.decode(
    """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""",
)
KC_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABNtJREFUaEPtmU1IVFEUx89R1ErRQhqsKRIyoo24sG9pVyBBCyEULBlBWuYHKAS6KLWFgh8rF20UIVS05WxahZRZCklJqyjMzI+RmKTJJp2JO/Veb+7cdz/ee1ODvrd8c99553f+5/7vfXcQdtGFu4gVXNidqrarrKvsDqiA28Y7QEQmgqusq+wOqIByG0ej0agsNyIqx5eNbWWcUjIqoJxkphHxnJVk7T5jCZYlWGZmJoTDYT0fUQP8D9VtwRIgn88HQ0ND0kXnFSHZBbAMW1NTI4Q0m7IjIyNQWVkpU6ACRFyRGSgzxjIsCS5qVbMEWEUQxHqAiLdkgHhjTGGj0egdALhPWos2pkgkAunp6ZZhtYQGBgZgamoKhoeHE3Jsb2+H1tbWhPt2Wp0JK+O6RB2ryqooPjExARUVFY5AJ8CagRI4r9cLi4uLsRcnA5YmotudLq6qyqawMvsB8nIy7tOhs0yxDi89ZymiPJ4OYhVaCCtqVa0oNLD38zSzzVnFIWNlDU97HyOvh4hYrWRQWhtzgkqpRava1dUFN/oexT17fPklfI9sK5usseuM0KK2NlW2qakJent7pUyIpZYR9kTGPnhysDgO6uTGPGxsbMTuDQ4OQm1tLeTl5cH6+nrM6UWXGfAfP2Ear+021syKbmMCy5vPm9EI7ME0LpPW3iT2lcBreBP+ljA+Kysrtk2lXZulchys0YlJoh6PB1ZWxBsYHpSW3XBoFW7u88Ql+3jzC1zec0AkYux3M1jtYda0o4GZsCrz1UxZLQnNqEjMZ54SOJaeFQd3ff0tPP0RjLtHxmYgwoeCM/r9c6uvYGFrk1sYEbApbF9fH9TX10tV3UxZ/706qKur09uZgH88dBbo5i1cfgHhSIRrfKdWZiC4vSXMhwdsCitacoxv5RkU/RsBZq3LvKXqfGYuTIe/wrbkuQENrLWzbVjRpqI59yg05nj12hDjWjrM/nY3AxbKSQ2gd3eOwh6l5qH2bjLHjGAEZmxsDO5W+5j5z/8MSS11rIdbWlqgu7s79pPZ2mtbWV7VyZIQKLwUN4S1heTF0DqHp7rWtoFAAPLz8/VwSXFjXrK+7AK4n1eoD7m4Ngfvf36X6kzjFLl94QiMj48zTaysrAwmJydpR0/YQzCVLS0thdnZWcstJTIv8jtRyu/3Q3l5ecKyQ24YTYylqpUtI3dToeLIMq0oJSc1iAbNzs6GUCikj7K8N6Z3UE7BksyqqqpgdHQUBvYXwbW9f+eVWQF4arLyEn0EkPcwlSWuRtyNd9kphOhbmVLLaDhAjoSo6x0iFsl0DbeNaRvXAv7rU4rm5mYgn4iUFygdFiYo+wdO+PdGsmBLSkpgbm6OOR8NoB5EXJNRkh4jdeBGnzA6BdvW1gYdHR0Jeff09EBjYyN9PwMRxZtjThWkW0Ezr4aGBujv77e1LLHmrJkHyBiPrMrKsFY+/+hkyEnE1hZfJCchda+RrQrrbCoYDEJxcTEsLCxIhcnJydGPYlgPJAMwztSksvy9uY4ZF92CaWlpQOZYZ2cnrK399Q2inOAsyY+IV2Xf78Q45TZ24KWnEXHGgTjKIaRhZZclu2uhMoHCA0qwCnFTcqgLm5KyOJCUq6wDRUzJEK6yKSmLA0m5yjpQxJQM4SqbkrI4kNSuUvYXJepaWog2CMIAAAAASUVORK5CYII=""",
)
LAC_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABC1JREFUaEPtmF1oFFcYht+v2hJBqbGYSP1BSeuFoRCtgsGC1UpRvAn0olgKFelNBa2CYCGIWin+0PaiXmgDQbRIc1NbbzTthW3AGv9SYkgjJYoRjX9UG9RY/+orZ3Ynnpmc2d3ZnF2nmzNXuztnv/M93/ue75wZwTC6ZBixwsGWqtpOWadsCVTA2bgERDQiOGWdsiVQAWfjEhDRNShnY2djixUgSS3cQRGpsxg+MlTRbExyEoBRItJNcgWAxlBW7QBq1G8iUpC8rAYleRTAvDgqyebWwHBurPW/nwYw2ya4Fdi0LXsBTPSUCQHEgdfHauDq5zEicjffWF5e+f6Z5CoA36j/v7HrDDpv3AuE+vr1BqydfCBj+K7+Kag+0eCN4cLFgbFypNmo+FCUzgvWbzAvbzuJ2w/+G0gqnHC+hdT/N/14I7rveYbB1nem4LO3Up/zgR4SrG/XQkCGC/VR1zrsu7Yo5YL0uo4LPCTY5nN9WLL/rNGGNlQ1xfDtfW71TFSVlz0CUCsibbnMFwuW5DgAN/Um9H5lC5qqt+Yyl7UxPfcrMe3Y3tgq5wxLUu0Rc9f9chFftV7JqGa4uURRfjdjBz6ccMR4W8XItjz8eXK1dU6wfkOKs0bDiSii1st3sKa5Byd7o3cQH7DyaBNuPBybtfmF5mkUkY+jipsVNi6oSdXQfunnotbZm/6XqL15/byJ2P672sJTl0ltDfiMiHinMON6z7SQcgU1Af65sgYzxo8KhDd1T5KHACzRB5pOVX33H6N8+6lIaM/2Wbp0pLIkDwNYHGXdqE0fgHfMS2d1TERiHR9J/gugTFdcd8bjJ8SLW457t3+uqce741KNeHfvUnzy16qMwJlg20Z83jrrCYPW0SHD9oy772Vrz2lnqe7/ihqr4ofdpltbs3OXiFSH4xth9YD+GjFAqpb8qm1AUwFIPgQwEkCTiHxAUtl+J4CqsPMy2XkQLMnRAO74Qe7Or8Polp9SzeHZE0lex7VsSsa9b+opmrrdIjI90AvCE6gAm367hM0tlwO3si3+uInaGu8Dz/y2A+3X+lE/9Xt80bPMF+aAiLw3sP5NsHo3TEP+AaBSRNQDeOIukl8CqJvd0FHVdrXfy6+8bCRurZ8TcGDAxqpK6n3JC+nn0aSqGVVtktcBVAys4421J0RkrlFZxaoN9MYUowHZtArJ28t+6B7T1Pm3Z2U9/0HKKti0oo9E5CWbiRQrFsnODb9eqt6yYLKa8lMR8V4yDIIdkLxAL72KAUyyAoCytLr+ERH1tPYMluSPapEDOC8irxUjqULOQXI5gD0AWkTk7TBs6nj4P1bUsLNcEJFpkVtPIav9vGNnfcR73gnanN/B2qxmkmI5ZZOkhs1cnLI2q5mkWE7ZJKlhMxenrM1qJimWUzZJatjMxSlrs5pJijWslH0KaD2oS5TnqEMAAAAASUVORK5CYII=""",
)
LAR_LOGO = base64.decode(
    """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""",
)
MIA_LOGO = base64.decode(
    """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""",
)
MIN_LOGO = base64.decode(
    """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""",
)
NE_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAAA3NJREFUaEPtWEtIVFEY/g4JmQxmmVFBQUJZhFkULgIjJDVooZuQsAwXLVoUpavARYvIFpU9IInCyKi1kUQEGViIJLTRahE90B4LG7FGwx7OH+cy93bmzH2cO7fsznjuSu/9X9///ec75wzDHHrYHMIKDTZb2dbMamazoAN6jLOARFsImlnNbBZ0QI9xFpCoBUqPsR7jv9ABIroBoDHNUNcYYwfT9DXc/tkYE9ERABfsimMb9vuumZ7fTPJhjPmu3beDU5VEROK38ctXED1z3tZ87YKtvsGKDhxnfLjLeqUKPG2wRFQJ4KGZMR6L4XVZuRKIoGDFJDLjcgFiI5TBEtFtAHvNYNNDwxit3aMEjhsVNDag6ERriv34l0kUbjukHMePIW+EJ1giug+gRg78qni9Uq5ITRWWd1x0tZ1X2oh4PGnylWKrGsUGryKSl+sM1lx373ZU4+fIqFLc1QN9yFla5Gr7YV8TvvUPWDZr3rxEOiIlJhnqbkNp3XEY7NkInsxqihoT0QiAlUooPYzcpqB48Alyth8NlEZcq8U1zXj7fiwpnidYP9nNKRg7eRoTnXz7dH9W3evG/HUlXmbKjNsJk8lw4tslxhjf/qxHWaCcqpS3HE80kkHd4Xbc6X3my80EysGJf5tB7FhNGWNfGX0Y84bMzMSRs/GADy91U3HdLl4YQbS/I0mYzEiBmVUpiYiqADywkqZxgnLLU1gQQXRi0jBxYnXWmBULJaI8AFP83fcfv5C7uUmlX8o2oQIrAe8BsNvougPb3WeTR7+u5Y8Y8m/i/9b6dTg3z8oYe9FCRJ8ALItNTSO/PPViYwKWgfK4/J2ozG7n5FCAtVQ0cZkQWV6xJB8fP3+FzLDpY4JVuQyECqwhMIk1XdnUhkdPX1ggOSg7wBkN1o5lO5At7T2ory7Dqc5eVwUWl1DomJUEzLgp8LF2YrWvqxUVW0ps91VZK0INNjHWKYCbz91FffUmtF1XZ/W/7LNeymz33TySigz7WauzeoJKB6DsYwe4dtdObjbMGCtVyRH6MZbXMGf3WEMF2m89VhamjGNWVOmk246PXxkzitmEYC0CMG4Ijg+gGSNQKutRxSbjmFUB5WSjwQbpXph9NbNhZidIbZrZIN0Ls69mNszsBKlNMxuke2H21cyGmZ0gtWlmg3QvzL5zitnf7P8vS1MsnBMAAAAASUVORK5CYII=""",
)
NO_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABO5JREFUaEPtmk1oXUUUx/9HTCWBJItgKxixIAGbRdRGilTUlXZTMQixiEGUYPSlhIZSE6IpeRKqIZRKMCV5CMGPt/BjEQqF+rEQESLWgNU0WoIgLrLRrPKFpsLIXO9cpvPm3jvz3tx50ry7enDn4/zO+Z8zM3ceYRc9tItYUYPNOtqMMUZE3h3tfULuyBps1nIC/Ocsj6rg8i1l7zKuwXqQMJ/Ca2TlqIZ8/xBRnSfW6sDyVUekrs+8rUpkb3pYxtgxAB+JvURbWxtWVla4gvcS0Z8+pOwtsiJf5Y2TbylXBfba1+/g3scGvOetF1g1qgI23DoGCvZRqGqwrosFj2xvby/m5ubAoyoeLuVCoYC+vr6bI7I6CcuwPqWcuYxl2OeefhSnT3RHkR0+8yEufHHZW6HKFJYx9jaAQbHcyBKOiW6eiN5wnUbRKSurgcUhPay0wTQGsJnmbsWRZYxNAzgO4A8i2ic7T5Zwx4G78cnsqRLfPvPKWfz0y+9aKTPGGgBshZ0WiOjhSoJTFqzm9JJoA5exLqqylKUzvRFPOeuyFawKqftmtry8jPb29sjgXC6H2dnZVNjR0VGMj49H/Xgf3ld9VKfYQBvDKl8YjLzPDRsYGMD09HQq7NjYGPL5PM9Z47GjwmPYyWhk3Sb+xy/P4bY9+nM33yyIZ3JyEkNDQ6mwPT09KBaLUb802YuGNoeJVFgB2traitXV1diqqguHDG1qfFI7eQ4xdl1dHXZ2doJXaZI2hk1aK5N0J4waf/VZdB89XNL0q4WryI0UrJwoF7ZwiascljH2EIBvywVVjUpaZ00jqnpLODOU85NEdDHO+YmRTdrXGlURqVH3y2fxaaF0nT36wpu4+N5rtsNF7RXYRClXDCvnpWxxuZHiY9iM6Q1WNkqqijdEyQZaHq+lpQVra2siF2OrtEvYBwF8r8tZdRJVh/LSZwKsc1zcmOqZWCpSDxDRlbJyNhwkuJuRgTWgPxDRQWntC/rMzMygv78/tdKK8ebn59HV1VVSWRljcwBeTLPD2dIjT8R/d3Z2YnFxkf+8TkR7VG/aFDcTKTLGfgOwf3BwEFNTU9F08vaxYlg5ujKwyc7FBNgEVFWMUJkNaGC7ac2PO+kkeVOGTdtB2ThPk8tGHEaN5MFNrhzDNrcDCL70Wx7xbgXAL7y0tpnMX3aBMo28KjW5nyWs3PUWIoour21tKVFApQPooi5fXKkVVJ1Pt4RldfFlLeM456jFqL6+Htvb22IZiV1+VNjm5masr68H7U3y2CZYTmAZY9y6RpFm+ZPHkD/38Q12pBUouXHu+SOY+eBz58CuYEs2HtxSETWbHZRoa7MkmUbXOWwS2PHX38X5My9Fth1+agQLF96KtdX1TZ9zWG656bk1KfL3P3ESf/193WneZgLLgbuOHMKdd7Tg/PuXYnNXPco9/sh9AeA3l3+O+rgsUk5gw8oZ5G1jYyM2Nzdjpak7segaNzQ0YGvrv+/jaXterzkrJkv6eL60tISOjo6SK8vh4WFMTEzE2usKNHCaqVdM2zHG7gHwq649X5r237UXnxVPY/7SdxiZKEY5qWl/gIiumc5r0s45rG7SXfU3Azmnd9W/ZZqamrCxseF8d/S/kXFSAXNZgNKAveSsbEQl59E0mLT33mFF/vqMqHBCVWDTIpDV+xpsVp6t9rj/ArmHxFrXn8ZdAAAAAElFTkSuQmCC""",
)
NYG_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAAAcxJREFUaEPtWctRxDAM1asAGmCgAzhz4UAdXGiMGQrhwIUzNMCnAmiAx2xmknGCN5K9STZ2tGdJq6f3LMsKZEM/bAirONha2XZmndkKKuAyroDEKISOWZJMBQmg8dd8W7swvuYTy2UYxxjjFcDVLt5BYBOL8wzgpvUxJtr7i5LA7hK/BvBiUUPpzDb5W6U/IdhPABdLy7jN/wnA7YIyPirYhl0Hq3S8zAb1n9nh/+RU3tqdM5PuzntiRzeB/RCRcw1AmDjJLxE5S/FJSTyzSNOAzR0WpvIzqs/B9tRHUpXxVAxZhwyXsdYgRFzGtcr4B8Bpb1yM3LO1nFkH6zIea3aFXD0uY5fxmmScuek4rozDAh6yptGHp8bCwS52Zp1Z8jfcYxslajJrj8rebz1zPvFizFqfeSZ0A6NVgp0L8GxgUxPOncJSGFbBpgSby5bko4jcxeKn7J6LAKsV0bhw61awRX+M3gxYkruPVe8a++GIOXb1fIvIiSXY2m3UM0vSwa6dxUh+9wAetIVbFcyG93j1Z3YzYIfTWc3MXgJ46z069jWckrtxbN4ebVAFdl015aLHRRXd8F2b6lCyvTNbMntjuTuzzmwFFdiUjP8AtNLqS6ckIlQAAAAASUVORK5CYII=""",
)
NYJ_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABkJJREFUaEPtmWtsFFUUx8/ZXR4lQJltgTS20BKqQlMVUCyUSFpaqzxEQci2iDZCYgCDJIh+ARE06QdfoCixGBFSygbFoo0ootRXU56SCB8UatoCTTW0u4CUbbszc80dO+Ps7MzszOxOsimzSbPJzr3n/n/3f+65904RbqMP3kas4MAOVLcdZx1nB8AMOGk8AExURXCcdZwdADPgpLEdJhJCNgHAVpXYzyFitR1jKmPa4iwhhMQpnkXEQXHGiOqeEFhCSB4AnI+ayXlTeWZEqsuo6JHDhrOtH9d7ouIgJkRnXEGUDq7c9ir7+fEfo8QahZW3o3y7nt/ILioslsc7hohzrMSjfSzByiE7Ap1s3uolCQHUgwj4G3gAkLIELbhtCpYQUgAATf2iOK+vyG11lq32C/gbpK5mgQ3Dyt30+oqsak1YPyvQMWEJIRsB4DWqcuTS2eBxGa43CQPTChT883cgpzqEx0Zc1oWVucl7fUXJQ6mgN+qyJqwIitPGEiZ3smo7+SCD5k7hw4fPChPS9c81yKycx4UONirXNPH6ijBC3P0ZhJzuwE+O1HGVZU+4cUYWkKbLcL0nRFKHpuC0F5bBme37JLysijlcN89H1YoF0wq5PRteF37XclkVQgRNX1YKPMeqZlHA30APDrRCCgN0BDu5DCbdnbd6Se/FK61D+r48JfT7reUie09OrlCtxbUuwnrL50Bg//difBqP6hG/hd+f3raF27tuswSnVy+Crc1Ajl/WTOsoWBF09FOlwLHqoDTayocfh4++PSR8v1/vhzULfNKkiL/T3YH+8TwvtBU/tA8ikl1H6rCnrw/Of3Cg94/2tsHL39qEz5Y8Bufamvn88RNdLpdL6Eu/6aGM/snjqLkQvNIK5JcWVeAIWELIdAA4gQWZwGTn2l5g7BqgcNK9bP3mbR5lOithaQoJ68qMkGCwK7K5CwF4muE6YejxmVb2GMfotLQxwPMchFkWMrzpvS8uWs5Tt2saDqc0njsNzKg0rWUW5a6khhBSDwDzreyh8oJDR0grL4au/cd058tIGxrAM28qsF/9qhtLSzPVJXdXDivcVMzCKkHVVE3yFUFqRqb0iK7Bu8dN6OnuCRG6pv0vVaXI+y2u2hDyuNzww7kzQ/6uORqx5VF9FbMfgR2rXpa66MHKq7NhWCpK7tb2ej+7tbbao3SQDhxrAuTi1NrGei4AlOYBkzZG13ExtuiuYVilKA2oiMO6lhIRxoUInYp0V7r0zop14WdKF6reba933+RzVizQPOwkBDZ/zVLur2DAfbX2uwgeb0UJBJS/6Zyj9VxVm9wP127ilswslvbcNw7uDVd9ulvzkt8fYy4ifi1kg1wt3WMr3n6F/ebkz1FXtlipiTPGAWm6pJlWOHM81FZVh8tnl0ni1lW/Gd6+Z4eHNLYKOoykr3wAvfrSf+ihGSwxqm09QjVVvllxuz1wdd9RVRihPSIEaqXTkNRuyqon2bM7P4t5373Q3hYuWF8pTYTL44HOGvXxmtvbuOnrKzWvlz29PXCrTriJrkXE90Qxmicos1VZbRZu3LgG7OGzhrfs0ctKgOM4w+21GirXqiYsfSAeGeMFVqZ+yuJZMHTwYLgWuArDU71AgMDNAz9Frvs478paoFFrVrl+hQOCr0g4mVv5KGHx0fuASWUgeD0Io0aOglt9vdBb1xRx8Lc6weh2Q9e+/wqmqVuPCCZd86bfAcyEO03z5qSPZc/s8Mdcr1KaFWQBkz3R9DjDPR7uUs1R3eudrrNKYGW1NKpIr7AZrax6Yxm9uBuC7V/D8wGAnp0BCzIJk51r6qJA+wVbLgI5cSVKN5blA8OkG507qd1Dd+Wzh7a8K2SNkVcyhmHVXMaSycCkjzUtMt4OwbZmQpou/793mnilatqhfqelmjVo4YMwImVYvAwx+wdbLgA50S61M+qmPLAlWDWn6Ssab3kxfaUQU7jRBjRSUPae2EzKqo0RF6wGtGA+FuYAk5VtOn4o1M2FvjgZdTqy4qQS2LSYWK4k4D944hCnEfGBWOOZeZ5wWOXghJBKANhtQNQsRGw00M5yE9thLSuzoaMDa8OkJkVIx9mksMEGEY6zNkxqUoR0nE0KG2wQ4Thrw6QmRUjH2aSwwQYR/wJPR2pa1MXBVAAAAABJRU5ErkJggg==""",
)
OAK_LOGO = base64.decode(
    """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""",
)
PHI_LOGO = base64.decode(
    """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""",
)
PIT_LOGO = base64.decode(
    """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""",
)
SEA_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAAA39JREFUaEPtmFtIFVEUhteyi0SkPfRUD120IiwkIrsYRgndoBsVBaFkYBcyMoosoigq6hBmZQ8SYWFF9tANKQrDeojAOJSZ9RQUQUX00kUKLFuxxzPnzIx7Zu+tRw/7nD1vZ85as9e3/n/W7BmEFDowhVjBwCar2kZZo2wSdMDYOAlE5CIYZY2ySdABY+MkENEMKGPjlLcxEREiau0EqeIZqEPtECLu1VF9aVjMKYJbZ8thReG0fueMl6OEsLaqDLa/j9LV8+D84Y3RZXsLLQWbCFBvY+n1ZetUb4ADYftCVbtoG+Zk7V3YU1kvZRpvrp0k2wBfWCJiN2c4Hqo6ixycuwH+/O10wXW8vASDBg7oUk7hdilZWQC1R0td1woCD4K1JrDK4jx5ovaThBDFV+8vhu3H6rhOcDaVB82FJaI8AGjuDWh7+AIMHZLeTa3y4kVQVbHeOj+/5Dg8evYG1pSlwbjJCKEtMcXzpmRBc/0hKy5zxib40f4bRI2wO+B3f/vB0qodZ+Dmw7DUveQMYvuOf21dnd8Zugqn6+5H//bec3YzK2q6LOyE9RtQvIJ4ovCAu8F6NhDKsC5wjnVdVguwtlPFtDSEzld86watx67htDMX9nlLK3z89LlHoNlZY2HSxAnR3KCuixawc/2msEjlSF46InZY88eZQETXAGBdw70HojqE/y9dsjAQWHiBSIAKqHegRnJbETGXB0vxALVB5s6ZDRkZw7oNKXbiyZUDkD815gBZeFGc00kR2K2IWNPnsGwBW2FOEdwmeGHeN1bB6JEjRIxcF/nes0TUAgC58VS2IH8WZGZmuJ7V3seHjE3ffvgC4xfv9p3qvCGVkz0K2u6c4A8oIhoDAO/iCctUPVJzGw5W37Dq4YGy3RTbVckcdv6ybaeg4fEL1zXZj+8/f8HwmZud55sQsdC+tndAWbumeAHzLCwDJRvTdHGftTFhx/XKMli765y7qZ6PDX36nJUtWjWu8WkbLCgN+aZ5HzlcZb3ZEWszewcd31SL7UE8q4F5fTkvlzf8pPfGPSgmYSnO11DRO6/w5T1hFJILWx8Cc4piwy/go6DWsET0FQCiD2HRS7zusPZXz+mIKHxF0xpW0unRMAOr2jFd4o2yuiilWqdRVrVjusQbZXVRSrVOo6xqx3SJN8rqopRqnUZZ1Y7pEm+U1UUp1TpTStn/uwlDS9BjCqkAAAAASUVORK5CYII=""",
)
SF_LOGO = base64.decode(
    """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""",
)
TB_LOGO = base64.decode(
    """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""",
)
TEN_LOGO = base64.decode(
    """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""",
)
WSH_LOGO = base64.decode(
    """iVBORw0KGgoAAAANSUhEUgAAADsAAAA7CAYAAADFJfKzAAAAAXNSR0IArs4c6QAABSdJREFUaEPtWW1sFEUYfuaux9njq3fFj0TTaAwWEyom/LMJ+JEYe4hoTPhaGmwpYPijNQSCNmj8p4nQoGiIpCHQBSG0hGjaiP5sIPEzgD80hqCkCbHQrYZryx1395rd69Ttdndn5q4x3HX31yWdmfd53ueZd2beMsyij80irgjIVqragbKBshWQgcDGFSCiK4VA2UDZCshAYOMKEDEoUFNsTH0JKkVVljRmZD37OqViAtDJkka7ycsbXK0C7eHCWF+yMuvdBjBqoTrMmoyt5pqTZGXm2yG7YJpWoPjia9czikTknoD6KQLSU8k6FdGa5WqhfqxgLp44vs5rrcy4cwcJWQmc60xT1srkl/E6hNmf5m9ZgH8NI/ttH1W5gcRCAP8AzZtZKp/HPBFYN5AWYQZom+QSdmA/DdUuwn0A3mdJ410e03U2z2Z2DkY2r2NxEUDz716KrNvAcPIEWRtGBuwxHelQnqLIUwN7ceQXu5Vlk++WMFdlOTFOWDqATkAeQJMRQn/C/IXde1h6cBBRHlxmrVwO+OK4u5Vl5rsl3lfZiWwOAnhQ1s4jI0DfV1OLOQfHya5ew7Bggdgnri4JAZomtnFrC6489yw9CuB3ljQes0fznc3V3aAxhELyIPlITjYWg/H5IUqgBtBWiwHrX1MWQ6gCw1MgnJ9I+BiAmAiFl4V9bWyp2x9/AsQu5oFMczObIwzErQzg/AV24+CnuJfPUbGy3YrOxAkxOKq5tLKqxaGmBuMHP6ZqN+vrJwnIAGvXM0QiIsj/FTwVstva8NvKlVQPwkW2ynjSGUXoKW7ll15mmD/fHyQRcLy7sG+dxSSfR/6ETiHTiNqrwrDQzSKVK8TrPYO/e3pZjShFfhYW2nhCWfPMrZMB2XWYEI0CvWcx2nOazXWCU7HyjWGkz/VRVLZA2q3vvMlxHOIU265sotIvIsP/LlPw/FzipvDSpbi2ZzfVAcixpGFdcJRtrLJvRWSXL8e1t96kuvFxZNq2+Rc8/QxlkULV/k6W+uHH4m5exZK9BKBhYACDnx1iD7ll7fElSHe8Q1Gz/moveBtGlJBSq7eXhaX2LA8uulGpkjCvkVWuZitElF3PHLtsGS7v2kkNALIsaXjWeqk9K2NlWXD19Rjb20Ex8/2irXIP/8zTZLRtQSKTQa5lCwuXWoWVCpRFtj/RDsK+1C3c2r6DTTmEtm+l8RUrUH3zJnJvtMuD8yp4solzWt7Pwko29lO3WHAzQbaxEX/seJ0etsg4OiVFFSjRvlUhGw5j6OgRMt+awCJAa5pq5ff2Ir14MUV/+hmjH+2bflZ7nd0iokUr+8GHoauXLtMj1gIM6D5KEFXhScuZY238nOqqJM5eyGacrJuViwXHyZdElvCr3k1LZCysrGypZNNpXDl9ynprAozOgtia69eR3bmLWYdQPI7bnxyge3A/oD0vPihEd+GS9uwE2QEAjd99H7p67ht6oONtqkYtoCXVwTnP7mJdImPhopS1q8szt3ETs/au6PPqUzk7GqI7uBknEsHgkS6ybnP/K1kZcJNPPHubtL/2FRD1mh3Irk6Wam2hebKNOVULz4yyYUDbKJZV7yFgTNBIByDzIlKtwtxxYpQe3pxsgseQBbP6iv7fKKy2jvBfJHPNfobE57Ge38zSyUrgsg9xIWv2IyTaedMDye7VkpVV5HhXDC9a2bsCvSKIgKxiwspmeKBs2UilCDRQVjFhZTM8ULZspFIEGiirmLCyGR4oWzZSKQKdVcr+C0wNZlp4JaOLAAAAAElFTkSuQmCC""",
)

TEAM_INFO = {
    # ATL
    1: team_ctor("#A71930", "#000000", ATL_LOGO, -10),
    # BUF
    2: team_ctor("#FFFFFF", "#00338D", BUF_LOGO),
    # CHI
    3: team_ctor("#C83803", "#0B162A", CHI_LOGO),
    # CIN
    4: team_ctor("#FB4F14", "#000000", CIN_LOGO),
    # CLE
    5: team_ctor("#FF3C00", "#311D00", CLE_LOGO),
    # DAL
    6: team_ctor("#869397", "#041E42", DAL_LOGO),
    # DEN
    7: team_ctor("#FB4F14", "#002244", DEN_LOGO),
    # DET
    8: team_ctor("#B0B7BC", "#0076B6", DET_LOGO),
    # GB
    9: team_ctor("#FFB612", "#203731", GB_LOGO, -17),
    # TEN
    10: team_ctor("#4B92DB", "#0C2340", TEN_LOGO, -19),
    # IND
    11: team_ctor("#FFFFFF", "#002C5F", IND_LOGO, -7),
    # KC
    12: team_ctor("#FFB81C", "#E31837", KC_LOGO, -17),
    # OAK
    13: team_ctor("#A5ACAF", "#000000", OAK_LOGO, -12),
    # LAR
    14: team_ctor("#FFA300", "#003594", LAR_LOGO),
    # MIA
    15: team_ctor("#FFFFFF", "#008E97", MIA_LOGO),
    # MIN
    16: team_ctor("#FFC62F", "#4F2683", MIN_LOGO),
    # NE
    17: team_ctor("#B0B7BC", "#002244", NE_LOGO, -17),
    # NO
    18: team_ctor("#D3BC8D", "#000000", NO_LOGO, -19),
    # NYG
    19: team_ctor("#FFFFFF", "#0B2265", NYG_LOGO),
    # NYJ
    20: team_ctor("#FFFFFF", "#125740", NYJ_LOGO, -17),
    # PHI
    21: team_ctor("#ACC0C6", "#004C54", PHI_LOGO, -19),
    # ARI
    22: team_ctor("#97233F", "#000000", ARI_LOGO, -19),
    # PIT
    23: team_ctor("#FFB612", "#101820", PIT_LOGO),
    # LAC
    24: team_ctor("#FFC20E", "#0080C6", LAC_LOGO, -17),
    # SF
    25: team_ctor("#B3995D", "#AA0000", SF_LOGO, -17),
    # SEA
    26: team_ctor("#A5ACAF", "#002244", SEA_LOGO, -16),
    # TB
    27: team_ctor("#D50A0A", "#0A0A08", TB_LOGO),
    # WSH
    28: team_ctor("#FFB612", "#5A1414", WSH_LOGO),
    # CAR
    29: team_ctor("#0085CA", "#101820", CAR_LOGO),
    # JAX
    30: team_ctor("#006778", "#101820", JAX_LOGO),
    # BAL
    33: team_ctor("#9E7C0C", "#000000", BAL_LOGO, -16),
    # HOU
    34: team_ctor("#A71930", "#03202F", HOU_LOGO),
}
