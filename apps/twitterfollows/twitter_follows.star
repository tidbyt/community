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
UklGRlQCAABXRUJQVlA4TEcCAAAvD0ADEB8EO5JtVdUcwd3y/yILioycp+eevVYajtw2ciS5enKe/z9u
zpuusburHDeSpEi5e8xgAHp9BuKXoburINfWdrx6Ytu2Zh6li5SgbtJJGvAoM6sA28a93/f/AQDgAByA
6zC9SgwYBoBhDGMgYMwSABlGHGNWmCOKIHOMOcjc7glZMab+HQ0vIvjGsHzN1pBOapCpioTGQMBtPURc
5WiNOJgPTV+Bk4kyRJHuQLeURCLqRyO5sQBp1FM8Hfbija3Hr/kfPzPAVUEjj1YeUUfKl90LYRkgGKdO
X329vrh79VWotzGJ5k/C0se7tdkpZ1puaj0a6k9nsyoQQ0ZkGk7Kbbh7ZtiiAI01mY6qukf7X9cWOkhr
OTL1mu8Bo9L7+8uTdNkbYdOt8Wx/KV5Mhuo/lOKoKCNabu5ZhSenfhHloR+tvy6b6CaI9i93fEt0funb
fbb5M7ZBS6XYXvLfdB1o6WWnLWKGxz8n79U6Y3dpozpdh0i/U1rltfLSHx29y/+0Ne7Gfy7X7+/7VZxv
pz0g2rZtujnBc+y82LZtG7Vt20376cE3RPR/Ao6W1mH6dWUw3Dy+PRyF8htT70GrwZGtnvcktsbXNgOK
Ygyh5J8Xl36hOdE+/fn4RxBEllx96KswrtIddyEIgujrk5aJQhY01iZPGQU+D7M0Xx6vooJ5vMAN7Fd8
nHmi9Dcwz+61xCxUfc0G5t/OXZg/RWoKbwC7pYhTRyIIJrXnfgFgrxzz0DRNe1PjNQAAxvPBVqfb7Syf
sGAaAA==
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
