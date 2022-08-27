"""
Applet: Instagram
Summary: Instagram follower count
Description: Show your Instagram follower count.
Author: Bruce Wayne
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("humanize.star", "humanize")

#
# Example:
#
# curl -A "Instagram 76.0.0.15.395 Android (24/7.0; 640dpi; 1440x2560; samsung; SM-G930F; herolte; samsungexynos8890; en_US; 138226743)" https://i.instagram.com/api/v1/users/web_profile_info/\?username\=arianagrande
#
# Derived From:
#
# https://stackoverflow.com/questions/63709996/how-to-get-instagram-follower-count-from-instagram-public-account-after-2020-ins
#

INSTAGRAM_PROFILE_URL = "https://i.instagram.com/api/v1/users/web_profile_info/?username="
INSTAGRAM_USER_AGENT = "Instagram 76.0.0.15.395 Android (24/7.0; 640dpi; 1440x2560; samsung; SM-G930F; herolte; samsungexynos8890; en_US; 138226743)"
INSTAGRAM_AT = "@"
CACHE_TTL = 60 * 60 * 24

#
# https://en.wikipedia.org/wiki/File:Instagram_logo_2022.svg
#

INSTAGRAM_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAhGVYSWZNTQAqAAAACAAFARIAAwAAAAEAAQAAARoABQAAAAEAAABKARsABQAAAAEAAABSASgAAwAAAAEAAgAAh2kABAAAAAEAAABaAAAAAAAAASwAAAABAAABLAAAAAEAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAACG1ed1AAAACXBIWXMAAC4jAAAuIwF4pT92AAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgoZXuEHAAACFElEQVQoFR2QvWsTYQCHf+9773u5u5DGXBPatDFGWymItoNSB7GLk4JDBkGXDkIWBRV0q5Pi5CqoFAUpugitioOIS61LIVKxCIUSauwHbT5s0kvuLvfxvh7y+wN+z/OQyeJyfz6lz7peeH7tux3P7AfKwK6PJEIkIIgBEWQmja5m0CVr3S+xCT+c5VWtqKpbuPEgB9Pk4ARQpAAVEr2GwytPNvTEbrb4d2Qf5O6Zj/Wk4aevvzgXENdh1mZTErsHEk3RY0gcNgnVtaA8vci8A9agtLwdv3AzB6Vns8+nnmPt0gKx1mukvfyb1F+Vib3TAhyHjd4qgP/aS7BBtJlpqrD/1OQwOuT06m2oOgdCAUkoNu+/A58+C6Nfg4EOp0NoSJ360JwWjj0ah65TVEfvoDo2E3mE0PIGFKcLhQrE4Eiax0/EFRdx7iKptyJyCRPz6MMPEEqhpfj/AEpUTUUHNDPxiWiKh1iSg72/BxbaSFcqGKx8APW68GdeQjE4iAjB4BCaPI6AOzXw4RzRchH645PAt9cQX97AnToRYSxCOzIA0WyDwg+I9XC8HjtkpNmVuUA6LpP1KmTHgfQAwQyQoQIk14O9a8+Y21YbpDd3cV4doUX0+oDCVUBNRTeAdAVEN0S41YT1NHJaLWAjqy0wNeuVpDIGpNUptN4mEAZM2hZkcweiugJvBYEglw+2jzpLra+k9A8ofd8QUkPQ/gAAAABJRU5ErkJggg==""")

def main(config):
    screen_name = config.get("screen_name", "hellotidbyt")

    if screen_name.startswith(INSTAGRAM_AT):
        screen_name = screen_name[len(INSTAGRAM_AT):]

    cache_key = "instagram_follows_%s" % screen_name
    formatted_followers_count = cache.get(cache_key)
    message = "%s%s" % (INSTAGRAM_AT, screen_name)

    if formatted_followers_count == None:
        url = "%s%s" % (INSTAGRAM_PROFILE_URL, screen_name)
        
        headers = {"User-Agent": INSTAGRAM_USER_AGENT}
        response = http.get(url, headers = headers)

        if response.status_code != 200:
            fail("Instagram request failed with status %d", response.status_code)

        body = response.json()

        if body == None or len(body) == 0:
            formatted_followers_count = "Not Found"
            message = "Check your screen name. (%s)" % message
        else:
            count = body["data"]["user"]["edge_followed_by"]["count"]
            comma_count = humanize.comma(int(count))
            formatted_followers_count = "%s followers" % comma_count
            cache.set(cache_key, formatted_followers_count, ttl_seconds = CACHE_TTL)

    screen_name_child = render.Text(
        color = "#3c3c3c",
        content = message,
    )

    if len(message) > 12:
        screen_name_child = render.Marquee(
            width = 64,
            child = screen_name_child,
        )

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(INSTAGRAM_ICON),
                            render.WrappedText(formatted_followers_count),
                        ],
                    ),
                    screen_name_child,
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "screen_name",
                name = "Screen Name",
                icon = "user",
                desc = "Screen name for which to display follower count",
            ),
        ],
    )
