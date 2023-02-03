"""
Applet: GitHub Unread
Summary: GitHub notifications count
Description: Displays the count of unread GitHub notifications.
Author: ElliottAYoung
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

GITHUB_IMAGE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAz1BMVEVAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMD///8e3z+UAAAAQ3RSTlMALZHU9JAsB5b9lQa+vZfPZ9Ht7NVoyZSZAxAPBPwrnZOOJhzT8ur1+wUC10lB3Cklki6FrbI2M7D6NLwVFNBLAf6AQ5ZiAAAAAAFiS0dERPm0mMEAAAAHdElNRQfmDAMUOiNHbbR3AAAArklEQVQY0z2P1xaCQAxEB0FhsVewVwR77535/39yQfC+bGayyZkAEiWhapqaTOGHbgiGCDMd6gz/ZAMnx3yhyFKZlWqNlpwXtFFvAM0WEmx3kCS70TL0yD4q5CA2huQIDjX8GdOBS28S66kruzNyHhsLUoVJLlc/vZbNDbZit/cOR+B0vsiwHcC4XO3bHXgEUa0w+vO1eMtCXnTTw2NMwZZ8P8LSo+2KH/zwlaD+AhuBGQTkgvNPAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIyLTEyLTAzVDIwOjQxOjQ2KzAwOjAwQzjB5gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMi0xMi0wM1QyMDozMjoxNiswMDowMLiJ2b4AAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjItMTItMDNUMjA6NTg6MzUrMDA6MDBjxr8LAAAAAElFTkSuQmCC")

def fetch_notifications(access_token):
    return http.get(
        "https://api.github.com/notifications",
        headers = {"Accept": "application/vnd.github+json", "Authorization": "Bearer {}".format(access_token), "X-GitHub-Api-Version": "2022-11-28"},
    )

def get_count(response):
    count = 0
    for obj in response:
        if (obj["unread"] == True):
            count += 1

    return count

def render_notifications(count):
    if count == 1:
        notification_word = "Notification"
    else:
        notification_word = "Notifications"

    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(GITHUB_IMAGE, height = 14),
                            ),
                            render.Text(str(count) + " Unread"),
                        ],
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 20, 0, 0),
                            child = render.Text(notification_word),
                        ),
                    ],
                ),
            ],
        ),
    )

def render_error(err):
    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(GITHUB_IMAGE, height = 14),
                            ),
                            render.WrappedText(str(err)),
                        ],
                    ),
                ),
            ],
        ),
    )

def main(config):
    """Main render function for the App
    Args:
        config: The schema config from TidByt
    Returns:
        A Root view to render to the app
    """
    access_token = config.get("access_token") or None
    CACHE_KEY = "github_notifications/{}".format(access_token)

    cache_results = cache.get(CACHE_KEY)

    if access_token:
        if cache_results:
            count = json.decode(cache_results)
        else:
            response = fetch_notifications(access_token)

            if response.status_code != 200:
                return render_error("Error with Access Token.")

            count = get_count(response.json())
            cache.set(CACHE_KEY, json.encode(count), ttl_seconds = 60)

        return render_notifications(count)
    else:
        return render_error("No Access Token.")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "access_token",
                name = "Github Personal Access Token",
                desc = "Personal Access token",
                icon = "lock",
            ),
        ],
    )
