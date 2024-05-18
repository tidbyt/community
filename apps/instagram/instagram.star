"""
Applet: Instagram
Summary: Instagram Follows
Description: Your Instagram followers count.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

IG_ICON = base64.decode("""
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
""")

CACHE_TTL = 14400

DEFAULT_USERNAME = "hellotidbyt"
DEFAULT_FOLLOWERS_COLOR = "#fff"
DEFAULT_USERNAME_COLOR = "#d6366b"

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    # get username from config
    username = config.str("username", DEFAULT_USERNAME)
    count_color = config.str("count_color", DEFAULT_FOLLOWERS_COLOR)
    username_color = config.str("username_color", DEFAULT_USERNAME_COLOR)

    # get user's page
    res = http.get("https://www.instagram.com/%s/" % username, ttl_seconds = CACHE_TTL, headers = {
        "accept-language": "en-US,en;q=1.0",
    })

    # handle api errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(str(res.status_code))

    # get html content
    html = res.body()

    # try to find number of followers
    matches = re.match("(\\w+) Followers,", html)

    # render user not found message if there are no RegEx matches
    if (len(matches) == 0):
        print("No matches returned from RegExp for username %s" % username)
        return render_user_not_found(username)

    # extract number from RegEx
    followers = matches[0][1]

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            children = [
                render.Box(
                    height = 22,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = IG_ICON, height = 18),
                            render.Column(
                                main_align = "space_around",
                                cross_align = "start",
                                children = [
                                    render.Text(content = followers, color = count_color),
                                    render.Text(content = "followers", font = "tb-8", color = count_color),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Box(
                    child = render.Marquee(
                        width = 60,
                        child = render.Text(
                            content = "@%s" % username,
                            font = "tb-8",
                            color = username_color,
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    color_palette = ["#405de6", "#5851d8", "#833ab4", "#c13584", "#e1306c", "#fd1d1d", "#f56040", "#f77737", "#fcaf45", "#ffdc80"]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Username name without @.",
                icon = "instagram",
                default = DEFAULT_USERNAME,
            ),
            schema.Color(
                id = "count_color",
                name = "Followers Color",
                desc = "Color for the number of followers.",
                icon = "brush",
                default = DEFAULT_FOLLOWERS_COLOR,
                palette = color_palette,
            ),
            schema.Color(
                id = "username_color",
                name = "Username Color",
                desc = "Color for the username.",
                icon = "brush",
                default = DEFAULT_USERNAME_COLOR,
                palette = color_palette,
            ),
        ],
    )

def render_user_not_found(username):
    """Renders a user not found message when the follower count
        is not found in the page's HTML.

    Args:
        username (string): The username to render.

    Returns:
        render.Root: Root widget tree.
    """

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            children = [
                render.Box(
                    height = 22,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = IG_ICON, height = 18),
                            render.Column(
                                main_align = "space_around",
                                cross_align = "start",
                                children = [
                                    render.Text(content = "user not", color = "#f00"),
                                    render.Text(content = "found", color = "#f00"),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Box(
                    width = 64,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text("@%s" % username, font = "tb-8", color = "#ff0"),
                    ),
                ),
            ],
        ),
    )

def render_error(status_code):
    """Renders the status code when there are API errors.

    Args:
        status_code (string): The http status code.

    Returns:
        render.Root: Root widget tree to show an error.
    """

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            children = [
                render.Box(
                    height = 22,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = IG_ICON, height = 18),
                            render.Column(
                                main_align = "space_around",
                                cross_align = "start",
                                children = [
                                    render.Text(content = "code", color = "#f00"),
                                    render.Text(content = status_code, color = "#f00"),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Box(
                    width = 64,
                    child = render.Text("API Error", font = "tb-8", color = "#ff0"),
                ),
            ],
        ),
    )
