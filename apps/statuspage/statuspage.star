"""
Applet: StatusPage
Summary: A statuspage status
Description: Shows the status of a page from StatusPage.io.
Author: Ricky Smith (DigitallyBorn)
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    page_url = config.get("page_url", "https://status.atlassian.com/")
    page_data = get_statuspage_data(page_url)

    title = page_data["page"]["name"]

    if page_data["status"]["indicator"] == "none":
        bgcolor = "#0f0"
        fgcolor = "#fff"
        display = "Operational"
    elif page_data["status"]["indicator"] == "major":
        bgcolor = "#f00"
        fgcolor = "#fff"
        display = "Major"
    else:
        bgcolor = "#ff0"
        fgcolor = "#000"
        display = "Minor"

    return render.Root(
        delay = 20,
        child = render.Stack(
            children = [
                render.Box(
                    width = 64,
                    height = 32,
                    color = bgcolor,
                    child = render.Box(
                        width = 60,
                        height = 28,
                        color = "#000",
                    ),
                ),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [
                                render.Text(
                                    content = title,
                                    color = fgcolor,
                                ),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [
                                render.Text(
                                    content = display,
                                    color = fgcolor,
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_statuspage_data(url):
    raw_data = cache.get(url)
    if raw_data == None:
        response = http.get(
            url,
            headers = {
                "Accept": "application/json",
            },
        )
        raw_data = response.body()
        cache.set(url, raw_data, 120)
    return json.decode(raw_data)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "page_url",
                name = "Status Page Url",
                desc = "The URL of a status page hosted by statuspage.io.",
                icon = "desktop",
                default = "https://status.atlassian.com/",
            ),
        ],
    )
