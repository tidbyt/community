"""
Applet: Kickstarter
Summary: Kickstarter project status
Description: Display the total amount raised and the number of backers for a Kickstarter project. The project must be publicly visible.
Author: sethvargo
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

KICKSTARTER_URL = "https://www.kickstarter.com/projects/{slug}/stats.json?v=1"
KICKSTARTER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAPCAYAAAA/I0V3AAAAwklEQVR4AWNw
L/Bh4DxXYcp6rnI767mKJ6znK3axna8IBYmzXqgxBPK3AcWfAvFxII4EiTNw
XKqwBHJ+A/F/ZMx2rnIJVvELFUUMQMZBEIcE/A2k6SuJmv4zgAiaa2I7V7GY
VE2nBe928JOi6Qfn+SppUJCTatMh8Qvd3OT4aRbZofeddE3nK46SqOknA/v5
agcg4x+mZOVGIP0XXRyYmKtBqRym8QgQfwSlZqDtiSBxjgvVNkD+YZA4MACu
AMXTQOIAaoOmULmqfxIAAAAASUVORK5CYII=
""")
KICKSTARTER_COLOR_GREEN = "#05ce78"
KICKSTARTER_COLOR_BLACK = "#222"
KICKSTARTER_CACHE_KEY = "kickstarter_{slug}"

def main(config):
    slug = config.get("slug", "elanlee/exploding-kittens")
    project = get_project_data(slug)

    backers = int(project.get("backers_count", 0))
    pledged = float(project.get("pledged", "0"))

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(
                                src = KICKSTARTER_ICON,
                                height = 14,
                            ),
                            render.WrappedText(
                                content = humanize.plural(backers, "backer", "backers"),
                                color = "#fff",
                            ),
                        ],
                    ),
                    render.Text(
                        content = "$ " + humanize.float("#,###.", pledged),
                        color = "#fff",
                    ),
                ],
            ),
        ),
    )

def get_project_data(slug):
    """data_for retrieves the Kickstarter data for the given slug.

    The Kickstarter slug must correspond to a publicly accessible Kickstarter
    project. If cached values exist, they are used. Otherwise the most recent data
    is fetched.

    Parameters
    ----------
    slug : str
      username/project_name to retrieve

    Returns
    -------
    dict
      Parsed JSON response as a dictionary
    """

    cache_key = KICKSTARTER_CACHE_KEY.format(slug = slug)

    cached = cache.get(cache_key)
    if cached:
        print("Using cached value for %s" % cache_key)
        return json.decode(cached)

    url = KICKSTARTER_URL.format(slug = slug)

    res = http.get(
        url = url,
        headers = {
            "accept": "application/json",
            "content-type": "application/json",
        },
    )
    if res.status_code != 200:
        fail("kickstarter request to %s failed with status code: %d - %s" %
             (url, res.status_code, res.body()))

    parsed = res.json()
    if not parsed or not parsed.get("project"):
        fail("bad response {body}".format(body = res.body()))

    project = parsed.get("project")
    cache.set(cache_key, json.encode(project))
    return project

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "slug",
                name = "Project slug",
                desc = "Slug of the project, in the format username/project_name.",
                icon = "gear",
            ),
        ],
    )
