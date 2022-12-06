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
iVBORw0KGgoAAAANSUhEUgAAAgAAAAIACAYAAAD0eNT6AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAOxAAADsQBlSsOGwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAArESURBVHic7d0xbjLJGkBR/MRGRk5MOoEjMpZA7pAFWPIqLHkBDp2zBDJHBC+F5NdbCrOBF1FoSq17Tl7qD2i6ryqp1QoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgHs8zR4Ayk6b/W32DDPtLkfPIJjkP7MHAAD+fQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJCzuGHAabO/jax/fWn/Bc/Xoa9vtbsc218gDLADAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABA0NPsAWCm02Z/G1n/+uIvNNP5OvTzrXaXox+QLDsAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAErWcPANzvfL1Nvf7ry9PU6wP3swMAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQw7xZtNNmfxtZP/s8+/N1aPzV8+/3gya5z5/tYWj90r//3eXoGcpi2QEAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBoPXsA2k6b/dCB7LPPk2fZRu+f02rs/t1djm5gprEDAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABA0Hr2ALBk5+vQcfCr59/vB00yx+j85+1haP3ry9PQeiizAwAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQNB69gAs22mzv42sd547SzZ6/55WY/+f3eXoD8Td7AAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABC0nj0AzHS+Dh3Hvnr+/X7QJE2j3995exha//ryNLQelswOAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQ7Djjtt9reR9Us/T/18Hfr4w+fZj3p/+5h6/a+fz6nXH/VnexhaP/v+H71/d5fjsv/ADLEDAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkLOgF+602Q8dCD77PPNRo+ehP/9+P2iS+7y/fQyt/2v794Mmuc//fv87tP7r5/NBk9znz/YwtL7+/9ldjsv+AuLsAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAELSePQBto+eRP/9+P2gSikbvn/P2MLT+9eVpaD2MsAMAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAEDQevYAdafN/jay3nniwL1Gnx+n1djza3c5eoBNZAcAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAICg9ewBWLbzdeg48NXz7/eDJoF/3+j9e94ehta/vjwNrafNDgAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEHr2QMs3Wmzv42sd543sFSjz6/Tauz5ubscPUAH2AEAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACAof5byaTN2HvXoedizna9DH3/1/Pv9oEm4x/vbx9Trf/18Tr1+3Z/tYWh9/fm1uxyX/QUMsgMAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAEDQevYAwP2+fj5nj8BEz7/fQ+vP28PQ+teXp6H1zGUHAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAoPXsAUadNvvbyPqln2d9vg59/OHzxJnr/e1j6vW/fj6nXp+20ef3aTX2/thdjot+gdgBAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgaD17gLrzdeg46tXz7/eDJmGG97ePofV/bf9+0CT3GZ3/6+fzQZNwj9Hnx3l7GFr/+vI0tJ4xdgAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAhazx7gtNnfRtY7TxqAe4y+P06rsffX7nKc+gKzAwAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQNDwWcSnzdh5yKPnMc92vg59/NXz7/eDJqHo/e1j6vW/fj6nXp9l+7M9DK2vvz92l+PQF2AHAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAoPXsAYD7ff18zh4BWCg7AAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABK1nD7B0ry9PQ+vP28ODJgFYltHnJ2PsAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAECQAACBIAABAkAAAgCABAABBAgAAggQAAAQJAAAIEgAAELSePUCd87ABmMEOAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQdMPoz9t9reR9a8v0z8CAEHn69Dra7W7HKe+wOwAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQJAAAIEgAAECQAACAIAEAAEECAACCBAAABAkAAAgSAAAQNPUs4kc4bfZjBzIDwB12l+Oi36F2AAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAACBIAABAkAAAgSAAAQJAAAIAgAQAAQQIAAIIEAAAECQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP6vfwCvytasA1520wAAAABJRU5ErkJggg==
""")

CACHE_KEY_PREFIX = "monitors_cached"
DEFAULT_QUERY = "status:alert"
DEFAULT_APP_KEY = None
DEFAULT_API_KEY = None

def main(config):
    DD_API_KEY = config.get("api_key") or DEFAULT_API_KEY
    DD_APP_KEY = config.get("app_key") or DEFAULT_APP_KEY

    CACHE_KEY = "{}-{}-{}".format(CACHE_KEY_PREFIX, DD_API_KEY, DD_APP_KEY)
    monitors_query = config.str("custom_query", DEFAULT_QUERY)

    monitors_cached = cache.get(CACHE_KEY)

    if monitors_cached != None:
        data = json.decode(monitors_cached)
    elif DD_API_KEY != None and DD_APP_KEY != None:
        data = http.get(
            "https://api.datadoghq.com/api/v1/monitor/search",
            params = {"query": monitors_query},
            headers = {"DD-API-KEY": DD_API_KEY, "DD-APPLICATION-KEY": DD_APP_KEY, "Accept": "application/json"},
        ).json()

        cache.set(CACHE_KEY, json.encode(data), ttl_seconds = 240)
    else:
        data = {"monitors": []}

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
                    transforms = [animation.Translate(-100, 0)],
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
                    transforms = [animation.Translate(100, 0)],
                    curve = "linear",
                ),
            ]
            children = []
            for monitor in monitors:
                children.append(
                    animation.Transformation(
                        duration = 150,
                        child = render.WrappedText(width = 25, height = 25, content = monitor.get("name", "Monitor Triggered")),
                        keyframes = keyframes,
                    ),
                )
            child = render.Row(
                expanded = False,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Box(width = 18, height = 18, child = render.Image(width = 18, height = 18, src = ALERT_ICON)),
                    render.Sequence(children = children),
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
                default = "",
            ),
            schema.Text(
                id = "app_key",
                name = "DataDog Application Key",
                desc = "A DataDog user account Application Key generated by the user",
                icon = "lock",
                default = "",
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
