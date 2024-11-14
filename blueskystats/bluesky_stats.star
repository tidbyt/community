"""
Applet: Bluesky Stats
Summary: Display Bluesky statistics
Description: Display Bluesky statistics like the total number of users. Data courtesy of https://bsky.jazco.dev/stats.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STAT = "total_users"
DEFAULT_STAT_COLOR = "#3a83f7"
DEFAULT_DOT_SEPARATOR = False
CACHE_TTL = 900
BSKY_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACYAAAAhCAYAAAC1ONkWAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAhGVYSWZNTQAqAAAACAAFARIAAwAAAAEAAQAAARoABQAAAAEAAABKARsABQAAAAEAAABSASgAAwAAAAEAAgAAh2kABAAAAAEAAABaAAAAAAAAAEgAAAABAAAASAAAAAEAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAJqADAAQAAAABAAAAIQAAAADF6JFIAAAACXBIWXMAAAsTAAALEwEAmpwYAAACNGlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+MTA2MDwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4xMjAwPC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICAgICAgICAgPGV4aWY6Q29sb3JTcGFjZT4xPC9leGlmOkNvbG9yU3BhY2U+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgry9SKfAAAG4klEQVRYCa1YW2icRRSeM/vvbm7aZBMVEUEEsVpRQXwQtVC0D+pjbbFPUgT7oFVEBW1MWZvEC14Qq2h8KIjYaNo++GB9qbQo6IMIXttSQaUK9dLcbG57+4/fd+bfZjfsJpvqIf+f2Zkz3/nmnDNnZldcIj2D5bvVy1Wi/mcXuc8mn5JpDl2R17Zf87JQ1fs//tdi9ryga1zZrVeJr5RYf5ociA7RhvDVM1x5Q9r8Q67inMborLg/MTJaLrrBf/Iy4V7XrNvhik5EqX/eoipuj8u4R6RwYV5zUcYNONWtmpJLxAM1BfsL8ZuT/amHpW9Qr66k3QlHkzFeAq5QkjSVdNyp7Jh8RkbdmKbcfujsB+3zkc2YvxkTt0ilZ6i81YnfI23SqyX0wRkgCLuwjb9Uya31sbjrSQKkqKJQULQVpNSlpFeybl/3cOVVAhopElyt2KIwHxjEkmxqH7HNBmyZTdoGB3IhJw/nZhM7DGt4NITYVTTWojrf7h/rGdZR0yNBrr5VoS7nQIhBLGIS2yCCrUXb6CQnr1o5a2E0rboXlRl51XmNpcPd1z0UHzCNMTg/rxxbXqhDXUj3sO4nBrHwkYnD+bRRLxghJ++8ToWpTQ3ZanROK75TNuWGKnuTTbAyMRrHhuEc3+HuJQZYVL1TT8g+gQNpg5MXjSZN3bK+gW7oMu8ZcKffBkPPuryU4bVM0xkcg47pYk5CqrGXqiCCVYA6OSGUbhpJx1IgWAtd3Eyq5NS1+V25Yd0Cw8WG5AKpoulAF6Sah65qzWyDA7NaF6Y9ihsL6Yw5eDlaAYDklPsXW+l9lpqEXFTFB9GIfX2DC1dTx/Z6yCnObS60HTRmXLlt2k+RlHNTVuACQPPJYQR5oGXJSFTxGjYDw8q9xMfa2HQ+c0CyElEX01rJR004TJGTJxDInkmmruyzQC6Cw0vSIdflhiuvWdeDOMj4QNjHMS2Yvxa9GeY2e6MumWfOkJOtBEv9Y5XE6PYIuRO7tH+0e0jXu3ekxMfa6LMx6DRj0aDfiBkXDAYXi5xK4ttAv0mXFUYkNZCwl0aqWtZGH9aOFFslKueJnuJsW5FqfFLIkTuj1WBytpMUQ+q7ZG1usPwAD2HplLXxDENoB51ptfRKKgKWc5L6RiwV+8NxuNgED7aEdE4piufQ9v5FLkrZTnCt1frLKziQC6fgyNDU+IAcx33nAyQsz8AA3Togaw/yQ3rtYZu+X53MmW1wMC7g5N2xEDwp+e06q78gFB3ALOAp4uERUj3blgtyILcyKWLwISaxaaNAm2YbHPDZkVNYGW8AuGdd8LL2pYtu1LW5Ozlum50Q1KrChXVweJUCECZKFYspzesWZcEdLmXc1rNPyBm7uYBLIMZB3gTyQhq8ntyDgW0qegt4tKOrjP9ZgHai3fqVh2CLUgHGLDAYDeb2Amx8iY27d7JfPja1Gg6LxDjCqy/2uyklrzXDpTu8RPdjbAO6LsVz/sScOw38I7govzvdL5/W2llqu54YNcNZV+56SS9OF+NX4PBNEkm73aJ49f4vgqszjx0t6zzeB0sZ//jMk/JX1WYtdD2xJNdyzxWu1Tj9OXZKjlsYq4kRAlaaev1apJDQ7GleckKdBIp4aQPsnE6IL90+sTN7rJpbVcgaEISRXzQQTtX0QWkHqXlch2z3w9jypFgucOm0Y7i5WwMGsFDHgW02YIs2w5ecZDPWrW4srDQ35DbiVrA2OYCbXwSrS8PC8cWC5eK0PWyzb2XJ0AZt5YbKG0094cD2oseOhTCpr/RZa3kP1Zote4bFyQiiPcI2hFedlYU2sAyNol5TTjiwvUjsXI6kvkMAl45ZR5MXzktsVXEfSlwcS+a2unO96cfu+wTbylW9cdYwJD9qyg9Y/iHEn6QDxSaM0F1GKDx22dHxnXJifCB7HNfCo+zjWPNpNsIcY74dMpvceEkd5Witx5xbF3JDivPbkZwzKBPMMX4Rbi7IJuTu7qoC8np3CxlWIrbZKC6EYyixXcWpJ0bGqGMT+Y7fY5UN8AS+GdvBwWq9NKEXcMZFWojfm+qXI/YTAg5fttnHMcxZ+mMMMQrEJDZt0FZSx86FkeQa16WkyOZ26zpN6ScwcrnOUp33d2IjZ0lqRr+dvEhudttxe+WWp/DkGNF0z9/6lXTJDTicy1BPLo3wEw419P2G0/CuiV3yY6PiSph6j7GHwi8U9BwmZjJyDUi9BbgCfgTBGeAjvCOAf5TJyq1GivlBQnzYBlGOUYe6mJfmXGAUdTZ+m5jLkSKFxh7jCIU/hiS/O/QO6WXqKrc5n+rC0f/N9NPytemQyNJfgGr61jyvN6XU3QifnXWl+S8sdEuwDWfJ619hymLHOSHM0wAAAABJRU5ErkJggg==
""")

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    stat = config.str("stat", DEFAULT_STAT)
    number_color = config.str("number_color", DEFAULT_STAT_COLOR)
    dot_separator = config.bool("dot_separator", DEFAULT_DOT_SEPARATOR)

    # get data
    res = http.get("https://bsky-search.jazco.io/stats", ttl_seconds = CACHE_TTL)

    # handle errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_api_error(str(int(res.status_code)))

    # transform to json
    data = res.json()

    # get humanized (comma separator) stat value
    stat_value = humanize.comma(int(data[stat]))

    # build stat name (just removes "total_" from the stat variables)
    stat_name = stat.replace("total_", "")

    # check and reformat to use dot separator
    if dot_separator:
        stat_value = stat_value.replace(",", ".")

    # render display
    return render.Root(
        child = render.Box(
            color = "#000000",
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Image(src = BSKY_LOGO, height = 10),
                            render.Box(width = 2, height = 1, color = "#000000"),
                            render.Text("Bluesky", font = "Dina_r400-6"),
                        ],
                    ),
                    render.Text(stat_value, color = number_color),
                    render.Text(stat_name, color = "#afbac7", font = "tom-thumb"),
                ],
            ),
        ),
    )

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    stats = [
        schema.Option(display = "Total Users", value = DEFAULT_STAT),
        schema.Option(display = "Total Posts", value = "total_posts"),
        schema.Option(display = "Total Follows", value = "total_follows"),
        schema.Option(display = "Total Likes", value = "total_likes"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "stat",
                name = "Statistic",
                desc = "Select the statistic you want to view.",
                icon = "hashtag",
                options = stats,
                default = stats[0].value,
            ),
            schema.Color(
                id = "number_color",
                name = "Number color",
                desc = "The color of the statistic number.",
                icon = "brush",
                default = DEFAULT_STAT_COLOR,
                palette = [DEFAULT_STAT_COLOR],
            ),
            schema.Toggle(
                id = "dot_separator",
                name = "Dot separator",
                desc = "Use dot as thousands separator.",
                icon = "circleDot",
                default = DEFAULT_DOT_SEPARATOR,
            ),
        ],
    )

def render_api_error(status_code):
    """Renders a view when there's an API error.

    Args:
        status_code (str): The http status code of the error.

    Returns:
        render.Root: Root widget tree.
    """
    return render.Root(
        child = render.Box(
            color = "#000000",
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Image(src = BSKY_LOGO, height = 10),
                            render.Box(width = 2, height = 1, color = "#000000"),
                            render.Text("Bluesky", font = "Dina_r400-6"),
                        ],
                    ),
                    render.Text("API ERROR", color = "#ff0000"),
                    render.Text("CODE %d" % status_code, color = "#ffff00"),
                ],
            ),
        ),
    )
