"""
Applet: Skybyt
Summary: Bluesky follower count
Description: Displays a Bluesky user's follower count.
Author: Alex Karp
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

BLUESKY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAABgGlDQ1BzUkdCIElFQzYxOTY2LTIuMQAAKJF1kc8rRFEUxz8zaMRMFMnC4qXBBjFKbJSZhJo0jVF+bd68+aVmxuu9J8lW2U5RYuPXgr+ArbJWikjJ2prYoOc8MzWSObd77ud+7zmne88Fdyyr5czqPsjlLSM6HlRm5+YVzzP1uGihC5+qmfpoJBKmor3fSazYTY9Tq3Lcv1afSJoauGqFRzTdsIQnhMOrlu7wtnCzllETwqfC3YZcUPjW0eNFfnY4XeRPh41YNATuRmEl/Yvjv1jLGDlheTn+XHZFK93HeYk3mZ+ZlrVdZhsmUcYJojDJGCEG6WdY/CA9BOiVHRXy+37yp1iWXE28zhoGS6TJYNEt6opUT8qaEj0pI8ua0/+/fTVTA4FidW8Qap5s+7UDPFvwVbDtj0Pb/jqCqke4yJfzlw9g6E30Qlnz70PDBpxdlrX4DpxvQuuDrhrqj1Ql051KwcsJ+Oag6RrqFoo9K51zfA+xdfmqK9jdg06Jb1j8BjmWZ9GqLiRsAAAACXBIWXMAAAsTAAALEwEAmpwYAAABP0lEQVQokX3RPWsUURjF8d9e1i5IBpImL5gtxMrK3sLC0jKpLARJo/gFhjSBgZSCEkEDNiEfwFJIikCaFDba2AkhZgvhohYhYZlY5BkYl5kcuDD3POf/cC4zKKr6NZ7gPXZymX65QUVVz+E51vFpUFT1b9yO+Qke5jL96IFHOMRSWH8SLluZZRwUVb3UAS9jvwXDRcJ4KjuKJfMteD7g0VR2nHDW0fYu3rTub8Ob1tmwo0GjtaKq9zDAak9mPMQxnvYE3vX4jY4TPuCoJ7AQp0tH2BlAUdVDPMY9PMP9HugrPuI7PucyTRLkMk2wgq0bYDHbwp1gNA0WcNoB/I3MTMdsMZfpZ4rLBOcdod040zoP5rpBtHjh+t83Xm495xtm4/sKL3OZtv9bEEsexJJLbOYyHYT/CBu4hVe5TF8a5h+53FrG27G36gAAAABJRU5ErkJggg==
""")

def main(config):
    handle = config.get("handle", "autistic.af")

    if handle.startswith("@"):
        handle = handle[len("@"):]

    cache_key = "bsky_follows_%s" % (handle)

    formatted_followers_count = cache.get(cache_key)
    message = "@%s" % handle

    if formatted_followers_count == None:
        followers_count = get_followers_count(handle)

        if followers_count == None:
            formatted_followers_count = "Not Found"
            message = "Check your handle. (%s)" % handle
        else:
            formatted_followers_count = "%s %s" % (humanize.comma(followers_count), humanize.plural_word(followers_count, "follower"))
            cache.set(cache_key, formatted_followers_count, ttl_seconds = 240)

    handle_child = render.Text(
        color = "#3c3c3c",
        content = message,
    )

    if len(message) > 12:
        handle_child = render.Marquee(
            width = 64,
            child = handle_child,
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
                            render.Image(BLUESKY_ICON),
                            render.WrappedText(formatted_followers_count),
                        ],
                    ),
                    handle_child,
                ],
            ),
        ),
    )

def get_followers_count(handle):
    response = http.get(
        "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=%s" % (handle),
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/activity+json",
        },
    )

    if response.status_code == 200:
        body = response.json()
        if body != None and len(body) > 0:
            return int(body["followersCount"])
    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "handle",
                name = "Handle",
                desc = "Bluesky handle for which to display follower count.",
                icon = "user",
            ),
        ],
    )
