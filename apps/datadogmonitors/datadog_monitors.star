"""
Applet: DataDog Monitors
Summary: View your DataDog Monitors
Description: By default displays any monitors that are in the status alert but allows for customizing the query yourself based on DataDog's syntax.
Author: Cavallando
"""
# I'm new to starlark, sorry if this looks bad :)

load("render.star", "render")
load("animation.star", "animation")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("cache.star", "cache")

CHECK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAANwAAAC0CAYAAAD//UK2AAADoUlEQVR4nO3dQVIbMRCGUXMJ77hGzsApcyrOg7MgLCEtevKrZ3ivanYqypb0jTYqc7sBAAAAAAAAAAAAAAAAAAAAAMAVPG5P99+/3irP7o8K5/ce3KPwCA7aBAdBgoMgwUGQ4CBIcBAkOAgSHAQJDo5RDen59eVReN6ECV8QHAQJDoIEB0GCgyDBQZDgIEhwECQ4CBIcdC38Bsnz68uWp/r5dk8l/Fv97mPl1Hr8jeTQcU5CrkNwECQ4CBIcBAkOggQHQYKDIMFBkOD4cHfD4PtOcIPk6Md+afJma1j49aziSbPthHMShpjABsHZL6tMYIPg7JdVJrBBcPbLKhPYIDj7ZZUJbBCc/bLKBDYIzn5ZZQIbBGe/rDKBDYKzXz7cD74BUf17u7/3Idwg+Xx9H7en0vPTFN9E5Tdq9e/t/t6HOP7kGn/CObmaBNcgOMGtElyD4AS3SnANghPcKsE1CE5wqwTXIDjBrRJcg+AEt0pwDYIT3CrBNQhOcB/uw29AVD/flslzg2TWepzBwSfX0W/U0mfbHNyOk2vbCTd6Pc5AcA2Cm7UeZyC4BsHNWo8zEFyD4GatxxkIrkFws9bjDATXILhZ63EGgmsQ3Kz1OAPBNQhu1nqcgeAaBDdrPXa6uwHx/RsQbpD4DZJVm06uw0+46t+rft/S5M0/uXbN3887uaoEJzjBBQlOcIILEpzgBBckOMEJLkhwghNckOAEJ7ggwQlOcEGCE5zgkoo3Au5uVPi+QsrZdBIe/oaujr3IyXX49929D38MwQlOcEGCE5zgggQnOMEFCU5wggsSnOAEFyQ4wQkuSHCCE1yQ4AQnuIEODnNbcMMDKY+rrsfufcM3CW7WOMFdnOBmjRPcxQlu1jjBXZzgZo0T3MUJbtY4wV2c4GaNE9zFCW7WOMFdnOBmjRPcxQlu1jjBXZ3fSIk81fnbvR0YovjmdcL1Ti7B8U5wgiNIcIIjSHCCI0hwgiNIcIIjSHCCI0hwgiNIcIJjmvq/g7pMcEJiH8EJjiDBCY4gwQmOIMEJjiDBCY4gwQmOIMEJjiDBCY4gwQmOoOLvo5zhN1Kqn2/3lENJ9WTYdcI5ubgUwUGQ4CBIcBAkOAgSHAQJDoIEB0GCg2n+w1UxIcFnBAdBgoMgwUGQ4CBIcBAkOAgSHAQJDoIEBzMJCYIEB0GCgyDBQZDgIEhwECQ4CBIcBAkOggQHSdX/3AMAAAAAAAAAAAAAAAAAAAAA5/YHxKLaWfZG2RgAAAAASUVORK5CYII=
""")
ALERT_ICON = base64.decode("""
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
""")

CACHE_KEY_PREFIX = "monitors_cached"
DEFAULT_QUERY = "status:alert"

def main(config):
    DD_API_KEY = config.str("api_key", "")
    DD_APP_KEY = config.str("app_key", "")
    CACHE_KEY = "{}-{}-".format(CACHE_KEY_PREFIX, DD_API_KEY, DD_APP_KEY)
    monitors_query = config.str("custom_query", DEFAULT_QUERY)

    monitors_cached = cache.get(CACHE_KEY)

    if monitors_cached != None:
        data = json.decode(monitors_cached)
    else:
        data = http.get(
            "https://api.datadoghq.com/api/v1/monitor/search",
            params = {"query": monitors_query},
            headers = {"DD-API-KEY": DD_API_KEY, "DD-APPLICATION-KEY": DD_APP_KEY, "Accept": "application/json"},
        ).json()
        cache.set(CACHE_KEY, json.encode(data), ttl_seconds = 240)

    success_image = render.Image(src = CHECK_ICON, height = 20, width = 20)
    error_image = render.Image(width = 18, height = 18, src = ALERT_ICON)

    if (data.get("monitors") == None):
        child = render.Row(
            cross_align = "center",
            main_align = "center",
            children = [
                error_image,
                render.WrappedText(align = "center", content = "Could not connect to DataDog"),
            ],
        )
    else:
        monitors = list(data.get("monitors"))

        child = render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "center",
            children = [
                render.Box(child = success_image, width = 18),
                render.Text(content = "No issues!"),
            ],
        )

        if (len(monitors) > 0):
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(0, -100)],
                    curve = "linear",
                ),
                animation.Keyframe(
                    percentage = 0.25,
                    transforms = [animation.Translate(0, 0)],
                    curve = "linear",
                ),
                animation.Keyframe(
                    percentage = 0.75,
                    transforms = [animation.Translate(0, 0)],
                    curve = "linear",
                ),
                animation.Keyframe(
                    percentage = 1,
                    transforms = [animation.Translate(0, 100)],
                    curve = "linear",
                ),
            ]
            children = []
            for monitor in monitors:
                children.append(
                    animation.Transformation(
                        duration = 150,
                        child = render.WrappedText(width = 25, content = monitor.get("name", "Monitor Triggered")),
                        # wait_for_child = True,
                        keyframes = keyframes,
                    ),
                )
            child = render.Row(
                expanded = False,
                main_align = "center",
                children = [
                    render.Box(width = 18, height = 18, child = render.Image(width = 18, height = 18, src = ALERT_ICON)),
                    render.Sequence(
                        children = children,
                    ),
                ],
            )

    return render.Root(child = child)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "DataDog API Key",
                desc = "API Key from your settings",
                icon = "lock",
            ),
            schema.Text(
                id = "app_key",
                name = "DataDog Application Key",
                desc = "A DataDog user account Application Key generated by the user",
                icon = "lock",
            ),
            schema.Text(
                id = "custom_query",
                name = "Override Query",
                desc = "Override completely searching for monitors",
                icon = "magnifyingGlass",
                default = DEFAULT_QUERY,
            ),
        ],
    )
