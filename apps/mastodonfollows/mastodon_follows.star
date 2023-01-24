"""
Applet: Mastodon Follows
Summary: Mastodon Follower Count
Description: Display your follower count from a Mastodon instance.
Author: Nick Penree
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

MASTODON_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAQCAYAAADJViUEAAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAA
AAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAAB
AAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAA+gAwAEAAAAAQAA
ABAAAAAAFry2WQAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAA
ADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4w
Ij4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1z
eW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAg
eG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpP
cmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAg
PC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KGV7hBwAAAwBJREFUKBVlU01oVFcU/u7Pm+fMmKRJ1JpYQrCU
aiJWXEnSihRBi7gQOpQ2baWCKOJGKULBha7cFBFciOI6KlkVFARFqA4KSlG0WVjRUBozmDgTk5k38967
P8fzxtn1wOXec8895zvnO+cKdOTAfjshtPxRa1ovBLqtpR7vRcjnSGs0st2mNO8hbtTr8vepKZGKzPfA
/nQyXwi+dxaozAFJAqxa41AsElotiYU3EjoABgaAXAhEkXmSLwZfqV9+ah4rFsJf6+/iJE0t9u7zGBv3
tLTo8HzaiaEhT/u+JRoZcfTyH+OiZWu6u8JPmo14jSbvJ9LYo9W0+vSZFWrjiG4Xsms34fy5Fg4eDkVv
r2xnuG3MypMnYhW3UoDcTqmE/3ihEmN8uxCZ49ycxaULEZaXPE78VgB5wuWLEWZmDIaHNXbuEph9ZREE
Li/hbdhcsuhfRW3Evx4mOHQkwp3brbZ+vxwzeoQHZSaCpa8faNYMhHeK07YGTBT5tg1SeQyClc4F8T7A
upKdB6xTyov9NLxLYSToAzBfesxxNCLXjpY5V1j3vqOzHQmfvbOaC09cIqFUB1kStjLSo3ILs/+mqMw6
jK/NUD8g8xzAvOVUGV874xrcM7yrWqpWDd7OG+rb4ES1QnjxOEV3v8BHg4TagkGtamhh3tieYRU403op
Jna/uh7kVu6J6nVb+8/r3nUKYYGyKpgRxsv4YBwTQ7BdrR7qQlj0SONoh+TanpMl5HKO1m0AwrxN4ZUI
REFLV9RaFHm4ijqfD9Xg50QqV3+WNpvfXLn12Z/aG1NmkOPOWqOoK/C2cZO0PUpJvN0LKgDCCdASQVel
UK8nb336ImOnVCLVnpzvdjx7sCLo2xabWsZEg3v49dW7Wx5nj/4vJEolSP4YHJTlhy+f9jrhr+d0zxgj
wRN3zzb/5p+UTUp/oFau56k+eO3eF5dLo9O5qelRnk9AnjpFcrK8efHavS3jsVn8OTHVG8Y0ZqSQm5i2
zdzn2Njlsx7uj8xhdHoqy64t7wG1QaJ1LoGzlAAAAABJRU5ErkJggg==
""")

INSTANCES_API_TOKEN = secret.decrypt("""
AV6+xWcEESKe4IHklOyhfJe+GyImzX1mrhiSoy11SLG0CKJ4nrD7RCHHu4W/m6KZsOoEb4JQobyXoUON
PmTM9yjERR4kBgHhSPx+BiOPbyhcjXiD2OlyRsKLsfOxkrp+2Dwjs8ofZ65ahzmTPBGJj11sB1m8rL31
1RVaMt/vWc+vghVLccwSsuazSI8HXrw26wEvwaaku+Cpru3SpaJz4R5VoQpCWKSwOBzXxmPX6ukOEOE5
fYB1msrF8ZaEXA8f9KnDauEtH/ke3K6Y2dhlxAA9tZN494CMGemWVjat5DuN+JkKLfU=
""")

def main(config):
    username = config.get("username", "donmelton")

    if username.startswith("@"):
        username = username[len("@"):]

    instance = json.decode(config.get("instance", "{\"display\":\"mstdn.social\",\"value\":\"mstdn.social\"}"))

    instance_name = instance["value"]

    cache_key = "mastodown_follows_%s_%s" % (instance_name, username)

    formatted_followers_count = cache.get(cache_key)
    message = "@%s@%s" % (username, instance_name)

    if formatted_followers_count == None:
        followers_count = get_followers_count(instance_name, username)

        if followers_count == None:
            formatted_followers_count = "Not Found"
            message = "Check your username. (%s)" % message
        else:
            formatted_followers_count = "%s %s" % (humanize.comma(followers_count), humanize.plural_word(followers_count, "follower"))
            cache.set(cache_key, formatted_followers_count, ttl_seconds = 240)

    username_child = render.Text(
        color = "#3c3c3c",
        content = message,
    )

    if len(message) > 12:
        username_child = render.Marquee(
            width = 64,
            child = username_child,
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
                            render.Image(MASTODON_ICON),
                            render.WrappedText(formatted_followers_count),
                        ],
                    ),
                    username_child,
                ],
            ),
        ),
    )

def get_followers_count(instance, username):
    response = http.get(
        "https://%s/users/%s/followers" % (instance, username),
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/activity+json",
        },
    )

    if response.status_code == 200:
        body = response.json()
        if body != None and len(body) > 0:
            return int(body["totalItems"])
    return None

def search_instances(pattern):
    matched_instances = []
    response = http.get(
        "https://instances.social/api/1.0/instances/search",
        params = {
            "name": "true",
            "q": pattern,
        },
        headers = {
            "Authorization": "Bearer %s" % INSTANCES_API_TOKEN,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )

    if response.status_code == 200:
        body = response.json()
        if body != None and len(body) > 0:
            if "instances" in body:
                instances = body["instances"]
                for instance in instances:
                    matched_instances.append(
                        schema.Option(
                            display = instance["name"],
                            value = instance["name"],
                        ),
                    )
    return matched_instances

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "instance",
                name = "Instance",
                desc = "Mastodon instances from instances.social",
                icon = "gear",
                handler = search_instances,
            ),
            schema.Text(
                id = "username",
                name = "User Name",
                icon = "user",
                desc = "User name for which to display follower count",
            ),
        ],
    )
