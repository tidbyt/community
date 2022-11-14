"""
Applet: Switchboard
Summary: Display Switchboard data
Description: Displays data from Switchboard on your Tidbyt.
Author: bguggs
"""

load("render.star", "render")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("cache.star", "cache")
load("schema.star", "schema")

BASE_API_URL = "https://secure.oneswitchboard.com/handle_tidbyt/"
SB_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAmVJREFUOE+dk11Ik2EUx3/P3tePTZ0zdeDCglmCIFjMlMxqFH4EJcMmXnelZakQRVT0hRFJEN1EN0oJGVQqFWWU2STCi4wM06lB2jQMb5rfa1tbvK/OmiFU5+45h//vOef/nEcQFhYdEbpMoJpAYBtCrF8qf0HQTVBcwy+9B8dsSCZ+6a1JSP46BOWAIRy8fJpB0IZPnIBXE0p2CWBNQva36/UxlmxLhkhLS6HUtpMEQ5yqvNvSidPpYmpqlg/9n4LT03P9+EWhAhFg0SFp6xEcqjlSJg5X7UeWJdalGtFoNCrA0dXL0NA4A4MuOjq6GXCOKlc34ZOrBBE7NhMMdCptt9yrQxsVRcfLHooLc9HHxaiAxpuPedMzyNy8B5frKx6PV0nPgNgjkPJvIKhQMg9aL9PbO8zZCw2rWLAiLcRtgZzfByjO/zsAJhXAt5DrtxpPUVyUy8iIavAfseDxUn+lmfan3cu1MEDOlgxqq8swxC+6vzI2pqfycXgMm/0kXq9PLSuAd8Cmvxm6ssKGvdSKvfw0bre6S+MCeftVCNb+FyBIgyAyL5OA5gVgTFyjJysrHZMpCVNKIgcrbSpXabe1rYs081qSkxPYW3JMeVI3QhQJsEYj+88BR81mk1yweyvZlnSMRgMl+/JUQCAQwDU2yfy8h+Y7z7l4qSlIkOv8WDgeWuVYZP8TSdLkGeJjJa02CrPZRE11mQr47vHy8NFrRkYncA5+Vlb5LX65ABzu3z6TRYesPQMcUMZZxZNJEM34pfOKePEVwsIaTaR3AwGNHdgF5CyV+yD4DCHdx6dxgsMTkv0Eyz3VGTMtt6oAAAAASUVORK5CYII=""")
LOGO_WIDTH = 16
LOGO_HEIGHT = 16
FULL_WIDTH = 64
FULL_HEIGHT = 32
JSON_VALUE_KEY = "value"

def render_failure():
    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Box(render.Text("Switchboard"), height = FULL_HEIGHT - LOGO_HEIGHT),
                    render.Stack(
                        children = [
                            render.Box(height = LOGO_HEIGHT, color = "#00054d"),
                            render.Row(expanded = True, main_align = "start", children = [render.Image(src = SB_ICON)]),
                            render.Row(
                                main_align = "end",
                                cross_align = "end",
                                expanded = True,
                                children = [
                                    render.Box(
                                        render.Marquee(
                                            align = "end",
                                            width = FULL_WIDTH - LOGO_WIDTH,
                                            child = render.Text("Raised: ???", color = "#FFF"),
                                        ),
                                        height = LOGO_HEIGHT,
                                        width = FULL_WIDTH - LOGO_WIDTH,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def main(config):
    sb_api_token = config.get("sb_api_token") or None
    if not sb_api_token:
        return render_failure()

    api_url = BASE_API_URL + "?sb_api_token=%s" % sb_api_token

    sb_cached_result = cache.get("sb_cached_result")
    if sb_cached_result != None:
        data = sb_cached_result
    else:
        res = http.get(api_url)
        if res.status_code != 200:
            fail("Failed with status code %d" % res.status_code)
            return render_failure()

        data = res.json()[JSON_VALUE_KEY]
        cache.set("sb_cached_result", data, ttl_seconds = 5)

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Box(render.Text("Switchboard"), height = FULL_HEIGHT - LOGO_HEIGHT),
                    render.Stack(
                        children = [
                            render.Box(height = LOGO_HEIGHT, color = "#00054d"),
                            render.Row(expanded = True, main_align = "start", children = [render.Image(src = SB_ICON)]),
                            render.Row(
                                main_align = "end",
                                cross_align = "end",
                                expanded = True,
                                children = [
                                    render.Box(
                                        render.Marquee(
                                            align = "end",
                                            width = FULL_WIDTH - LOGO_WIDTH,
                                            child = render.Text(data, color = "#FFF"),
                                        ),
                                        height = LOGO_HEIGHT,
                                        width = FULL_WIDTH - LOGO_WIDTH,
                                    ),
                                ],
                            ),
                        ],
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
                id = "sb_api_token",
                name = "Switchboard API Token",
                desc = "The API Token found in your Organization Settings",
                icon = "key",
            ),
        ],
    )
