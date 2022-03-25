"""
Applet: Snyk
Summary: Snyk project issue counts
Description: Shows medium/high/critical issue counts for the configured Snyk project.
Author: Andrew Powell
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("schema.star", "schema")
load("encoding/json.star", "json")
load("cache.star", "cache")

SNYK_API_BASE = "https://api.snyk.io/v3/"
SNYK_VERSION = "2022-03-11~experimental"

def main(config):
    SNYK_ORG_ID = config.get("orgId") or ""
    SNYK_PROJECT_ID = config.get("projectId") or ""
    SNYK_API_KEY = config.get("apiKey") or ""
    logo_cached = cache.get("snyk_logo")
    if logo_cached != None:
        imgSrc = logo_cached
    else:
        imgSrc = http.get("https://res.cloudinary.com/snyk/image/upload/v1537345891/press-kit/brand/avatar-transparent.png").body()
        cache.set("snyk_logo", imgSrc, ttl_seconds = 60)

    if SNYK_ORG_ID == "" or SNYK_PROJECT_ID == "" or SNYK_API_KEY == "":
        msg = render.Text("Please make sure Org ID, Project ID, and API Key are all defined.")
        return render.Root(
            child =
                render.Box(
                    color = "#0f0f0f",
                    child = render.Row(
                        children = [
                            render.Box(
                                color = "#712EA5",
                                width = 20,
                                child = render.Image(
                                    src = imgSrc,
                                    width = 25,
                                    height = 25,
                                ),
                            ),
                            render.Padding(
                                expanded = True,
                                pad = 1,
                                child = render.Column(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    children = [
                                        render.Marquee(
                                            width = 42,
                                            child = msg,
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
        )
    else:
        res = http.get(
            url = SNYK_API_BASE + "orgs/" + SNYK_ORG_ID + "/issues" + "?version=" + SNYK_VERSION + "&project_id=" + SNYK_PROJECT_ID,
            headers = {
                "Authorization": "token %s" % SNYK_API_KEY,
            },
        )

        project = http.get(
            url = SNYK_API_BASE + "orgs/" + SNYK_ORG_ID + "/projects/" + SNYK_PROJECT_ID + "?version=" + SNYK_VERSION,
            headers = {
                "Authorization": "token %s" % SNYK_API_KEY,
            },
        )

        if res.status_code != 200:
            fail("bad request for station infomation: %s %s" % (res.status_code, res.body()))

        body = res.json()
        projectName = project.json()["data"]["attributes"]["name"]

        low = 0
        medium = 0
        high = 0
        critical = 0
        issues = body["data"]
        if len(issues) > 0:
            for i in range(0, len(issues) + 1):
                if issues[i]["severity"] == "low":
                    low = low + 1
                if issues[i]["severity"] == "medium":
                    medium = medium + 1
                if issues[i]["severity"] == "high":
                    high = high + 1
                if issues[i]["severity"] == "critical":
                    critical = critical + 1

        return render.Root(
            child =
                render.Box(
                    color = "#0f0f0f",
                    child = render.Row(
                        children = [
                            render.Box(
                                color = "#712EA5",
                                width = 20,
                                child = render.Image(
                                    src = imgSrc,
                                    width = 25,
                                    height = 25,
                                ),
                            ),
                            render.Padding(
                                expanded = True,
                                pad = 1,
                                child = render.Column(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    children = [
                                        render.Marquee(
                                            width = 42,
                                            child = render.Text(
                                                content = projectName,
                                                font = "tom-thumb",
                                                color = "#FFFFFF",
                                            ),
                                        ),
                                        render.Text(
                                            content = "Medium: %d" % medium,
                                            font = "tom-thumb",
                                            color = "#D17D01",
                                        ),
                                        render.Text(
                                            content = "High: %d" % high,
                                            font = "tom-thumb",
                                            color = "#CB4F19",
                                        ),
                                        render.Text(
                                            content = "Crtical: %d" % critical,
                                            font = "tom-thumb",
                                            color = "#AD1A1A",
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apiKey",
                name = "Snyk API Key",
                desc = "API Key for authorization to Snyk",
                icon = "gears",
            ),
            schema.Text(
                id = "orgId",
                name = "Org ID",
                desc = "Organization ID in which the target project resides",
                icon = "sitemap",
            ),
            schema.Text(
                id = "projectId",
                name = "Project ID",
                desc = "Project ID to monitor for issues",
                icon = "diagram-project",
            ),
        ],
    )
