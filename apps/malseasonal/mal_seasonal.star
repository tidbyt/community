"""
Applet: MAL Seasonal
Summary: Shows seasonal anime
Description: Shows seasonal anime for year and season set in the configuration.
Author: mikelikescode
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

CLIENT_SECRET = secret.decrypt("AV6+xWcEaGyzfB1xgu9kPoAmx7aYWWB6WFpBCmToFNT6l997TOUBS06sHFmdSZ+3TB7Pi0dXH1xn4gjWtxIxq2amyDZPELG/52NX47iDL4LcaGmUUkmzOziShMd9GooXs9J3YommzC92Uc1legPDv8m2lbcPRVnxSvS2u5dFBS+SZ3XDtic5OuZ4Au0kBszFr5coZnOsHdrsB7icaaDq6/ZR2xxjZQ==") or "client_secret"
CODE_VERIFIER = secret.decrypt("AV6+xWcEIb5CGlY7mUSlshT2F3P+qAhqSGNvocdetFt2+zkoUYVISYZXNJgmtUt0krc4j9kKMHDwRTwEn7HfWdK/JIPtOgP9S4vwDZR8m41Y71MGNwTJ7STJza4Sh0m3t8eSGFzz8j2t2wcgG5DcRpNdWjOWKampEsZ3F8IZ199kP8u7oWnEIVEJbzNfvg7AFJi3XYkcmV+hS0jO6i1HKMJKrg0xpD+YQK57aDZPDu2FaiUk") or "code_verifier"
CLIENT_ID = secret.decrypt("AV6+xWcEZhdwil//pOH8xZ+JNZ5zkYM5b4i+z6L7PMv8JIma53EWBjDoOczYJRZAqcQF9KQrxscc46Hm+CG5bDX0zSBbbWhfLbgszhqm71f4YdWP0i3O2MvzK6Cq7TfalUXDN69R9Ld/oDC91GlQhexiMXA9RCWnN9ORHWkdn9rQDEOo3jA=") or "client_id"

def main(config):
    token = config.get("auth")

    if token:
        pass
    else:
        return render.Root(
            render.Row(
                children = [
                    render.WrappedText(
                        content = "Please login to MyAnimeList",
                        width = 60,
                        height = 30,
                        color = "#ffffff",
                    ),
                ],
            ),
        )

    year = config.get("year")
    season = config.get("season")
    url = "https://api.myanimelist.net/v2/anime/season/%s/%s?sort=anime_num_list_users" % (year, season)
    MAL_DATA = get_data(url, token)

    return render.Root(
        render.Column(
            children = [
                render.Box(
                    child = render.WrappedText(
                        content = "MAL %s %s" % (season, year),
                        align = "start",
                        font = "CG-pixel-3x5-mono",
                        color = "#abc4ed",
                    ),
                    width = 65,
                    height = 6,
                ),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 70,
                            height = 26,
                            child = render.Box(
                                padding = 1,
                                child = render.Row(
                                    children = render_anime_titles(MAL_DATA),
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
    )

def get_data(url, token):
    res = http.get(url, headers = {
        "Authorization": "Bearer %s" % token,
    })
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())
    return res.json()

def oauth_handler(params):
    params = json.decode(params)
    res = http.post(
        url = "https://myanimelist.net/v1/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            code_verifier = CODE_VERIFIER,
            client_secret = CLIENT_SECRET,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

def render_anime_titles(MAL_DATA):
    animes = []

    for anime in MAL_DATA["data"]:
        animes.append(
            render.Row(
                main_align = "start",
                children = [
                    render.Image(
                        src = http.get(anime["node"]["main_picture"]["medium"]).body(),
                        width = 20,
                        height = 25,
                    ),
                    render.Box(
                        child = render.WrappedText(
                            content = anime["node"]["title"],
                            color = "#ffffff",
                            align = "start",
                            font = "CG-pixel-3x5-mono",
                            linespacing = 1,
                        ),
                        width = 50,
                        height = 25,
                    ),
                ],
            ),
        )

    return animes

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "MyAnimeList",
                desc = "Login with MyAnimeList for access to your anime list.",
                icon = "",
                handler = oauth_handler,
                client_id = CLIENT_ID,
                authorization_endpoint = "https://myanimelist.net/v1/oauth2/authorize?code_challenge=%s&client_id=%s&scope=read:user&redirect_uri=http://127.0.0.1:8080/oauth-callback&response_type=code&state=abc123" % (CODE_VERIFIER, CLIENT_ID),
                scopes = ["read:user"],
            ),
            schema.Dropdown(
                id = "season",
                name = "Season",
                desc = "Select the season you want to display",
                icon = "globe",
                default = "winter",
                options = [
                    schema.Option(
                        value = "winter",
                        display = "Winter",
                    ),
                    schema.Option(
                        value = "spring",
                        display = "Spring",
                    ),
                    schema.Option(
                        value = "summer",
                        display = "Summer",
                    ),
                    schema.Option(
                        value = "fall",
                        display = "Fall",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "year",
                name = "Year",
                icon = "globe",
                desc = "Select the year you want to display",
                default = "2021",
                options = [
                    schema.Option(
                        value = "2021",
                        display = "2021",
                    ),
                    schema.Option(
                        value = "2022",
                        display = "2022",
                    ),
                    schema.Option(
                        value = "2023",
                        display = "2023",
                    ),
                ],
            ),
        ],
    )
