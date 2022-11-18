"""
Applet: Should I Deploy
Summary: Display shouldideploy.today
Description: Display shouldideploy.today answer.
Author: humbertogontijo
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("cache.star", "cache")

SHOULD_I_DEPLOY_URL = "https://shouldideploy.today/api?tz="
DEFAULT_TIMEZONE = "UTC"

def main(config):
    tz = config.get("tz", DEFAULT_TIMEZONE)
    resp_cache = cache.get("api_message")
    if resp_cache != None:
        msg_txt = resp_cache
    else:
        resp = http.get(SHOULD_I_DEPLOY_URL + tz)
        if resp.status_code != 200:
            fail("Request failed with status %d", resp.status_code)
        msg_txt = resp.json()["message"]
        cache.set("api_message", msg_txt, ttl_seconds = 120)

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = "Should I Deploy Today?",
                            color = "#D2691E",
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 60,
                            child = render.Text(
                                content = msg_txt,
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "tz",
                name = "Timezone",
                desc = "Timezone to send with the request for shouldideploy.today.",
                icon = "businessTime",
                default = DEFAULT_TIMEZONE,
            ),
        ],
    )
