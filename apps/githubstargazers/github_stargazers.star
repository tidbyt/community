"""
Applet: GitHub Stargazers
Summary: Display GitHub repo stars
Description: Display the GitHub stargazer count for a repo.
Author: fulghum
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

GITHUB_REPO_SEARCH_URL = "https://api.github.com/search/repositories?q=%s"

ENCRYPTED_GITHUB_API_KEY = "AV6+xWcEXitLhY/tkHLwCUQk61Alrl3buDOYETGNYRImonvfJuThu9OEhyj85Lm4bLq1m1upELNyMarn1azvCEMAUaj+bUDOultUpZNqnungGOothHhuPvapuZ9V7ImD+9zRdZXzYxYtgVO+N1xO1iJCTspEinHtzJHAxRD+n49eNJ5t3RnfYwIX4E2v1Q=="

GITHUB_IMAGE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAz1BMVEVAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMBAeMD///8e3z+UAAAAQ3RSTlMALZHU9JAsB5b9lQa+vZfPZ9Ht7NVoyZSZAxAPBPwrnZOOJhzT8ur1+wUC10lB3Cklki6FrbI2M7D6NLwVFNBLAf6AQ5ZiAAAAAAFiS0dERPm0mMEAAAAHdElNRQfmDAMUOiNHbbR3AAAArklEQVQY0z2P1xaCQAxEB0FhsVewVwR77535/39yQfC+bGayyZkAEiWhapqaTOGHbgiGCDMd6gz/ZAMnx3yhyFKZlWqNlpwXtFFvAM0WEmx3kCS70TL0yD4q5CA2huQIDjX8GdOBS28S66kruzNyHhsLUoVJLlc/vZbNDbZit/cOR+B0vsiwHcC4XO3bHXgEUa0w+vO1eMtCXnTTw2NMwZZ8P8LSo+2KH/zwlaD+AhuBGQTkgvNPAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIyLTEyLTAzVDIwOjQxOjQ2KzAwOjAwQzjB5gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMi0xMi0wM1QyMDozMjoxNiswMDowMLiJ2b4AAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjItMTItMDNUMjA6NTg6MzUrMDA6MDBjxr8LAAAAAElFTkSuQmCC")

def get_stargazers_count(org_name, repo_name, config):
    query_params = "repo:%s/%s" % (org_name, repo_name)
    res_json = send_github_request(GITHUB_REPO_SEARCH_URL, query_params, config)
    stargazers_count = res_json["items"][0]["stargazers_count"]
    print("stargazers_count: %s " % stargazers_count)
    return stargazers_count

def send_github_request(url, query_params, config):
    api_key = secret.decrypt(ENCRYPTED_GITHUB_API_KEY) or config.get("dev_api_key")

    headers = {}
    if api_key == None:
        print("warning: no api_key available; sending request without authentication")
    else:
        headers = {
            "Authorization": "token %s" % api_key,
        }

    res = http.get(
        url = url % humanize.url_encode(query_params),
        headers = headers,
    )
    if res.status_code != 200:
        print("GitHub API request failed: %s - %s " % (res.status_code, res.body()))
        return None

    return json.decode(res.body())

def main(config):
    org_name = config.get("org_name", "tidbyt")
    repo_name = config.get("repo_name", "community")

    print("Fetching GitHub stargazer count...")
    cache_key = "repo_stargazers_%s/%s" % (org_name, repo_name)
    stargazers_count = cache.get(cache_key)

    if stargazers_count == None:
        stargazers_count = get_stargazers_count(org_name, repo_name, config)
        cache.set(cache_key, str(stargazers_count), ttl_seconds = 300)

    image_size = 16
    msg = "%s stars" % humanize.comma(stargazers_count)

    display_name = "%s/%s" % (org_name, repo_name)
    username_child = render.Text(
        color = "#6cc644",
        content = display_name,
    )

    if len(display_name) > 12:
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
                        main_align = "space_evenly" if len(msg) > 5 else "center",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(GITHUB_IMAGE, height = image_size),
                            ),
                            render.WrappedText(msg, font = "tb-8" if len(msg) > 7 else "6x13"),
                        ],
                    ),
                    username_child,
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "org_name",
                name = "Org Name",
                icon = "user",
                desc = "Name of the organization, or account, containing the GitHub repository",
            ),
            schema.Text(
                id = "repo_name",
                name = "Repo Name",
                icon = "user",
                desc = "Name of the GitHub repository for which to display stargazer count",
            ),
        ],
    )
