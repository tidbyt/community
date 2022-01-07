"""
Applet: Twitter Follows
Summary: Twitter Follower Count
Description: Display the follower count for a provided screen name.
Author: Nick Penree
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")

TWITTER_PROFILE_URL = "https://cdn.syndication.twimg.com/widgets/followbutton/info.json?screen_names="

TWITTER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAMCAYAAAC5tzfZAAABEUlEQVQoU42S
IU8DQRCFv9c70qS6VQg0WBCIVlMLkvZIEATBT6imGoGqIlxLgwGJ5xIUHotE
VEIF3d0hvRYC9EhZOfO+2Zk3I66syr5GFL3LyQ6ig0oVCBlvcYeyq4vUPUOU
kCj7wV28bxKXHgtq9cXAjTECsi6v8RnHGufCoevhOVqAzDLRdynQniU1IrJb
PPfALrC3ALmwJYbuHM8hUCmc63cwilbF9SRjovq/gGkn7agmBrZGCHfI1peC
Ro8kPlYuTH0fWWspFPwGB+WnOWQNFG7Aqn+Cpi5J1Mnt+hJNl+x9imgu2jxr
6zMuhv4Eb9ugZsFPY2SntFa63wvNjXAtUAOplidL9oK3B6K4V3RiH8hiZB6Z
gVtbAAAAAElFTkSuQmCC
""")

def main(config):
    screen_name = config.get("screen_name", "HelloTidbyt")
    cache_key = "twitter_follows_%s" % screen_name
    formatted_followers_count = cache.get(cache_key)
    message = "@%s" % screen_name

    if formatted_followers_count == None:
        url = "%s%s" % (TWITTER_PROFILE_URL, screen_name)
        response = http.get(url)

        if response.status_code != 200:
            fail("Twitter request failed with status %d", response.status_code)

        body = response.json()

        if body == None or len(body) == 0:
            formatted_followers_count = "Not Found"
            message = "Check your screen name. (%s)" % message
        else: 
            formatted_followers_count = body[0]["formatted_followers_count"]
            cache.set(cache_key, formatted_followers_count, ttl_seconds = 240)

    screen_name_child = render.Text(
        color = "#3c3c3c",
        content = message
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
                            render.Image(TWITTER_ICON),
                            render.WrappedText(formatted_followers_count),
                        ],
                    ),
                    screen_name_child,
                ],
            ),
        ),
    )

def get_schema():
    return [
        {
            "id": "screen_name",
            "name": "Screen Name",
            "icon": "user",
            "description": "Screen name for which to display follower count",
            "type": "text",
        },
    ]
