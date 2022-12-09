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
load("encoding/json.star", "json")
load("time.star", "time")

BASE_API_URL = "https://secure.oneswitchboard.com/api/handle_tidbyt/"
SB_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAmVJREFUOE+dk11Ik2EUx3/P3tePTZ0zdeDCglmCIFjMlMxqFH4EJcMmXnelZakQRVT0hRFJEN1EN0oJGVQqFWWU2STCi4wM06lB2jQMb5rfa1tbvK/OmiFU5+45h//vOef/nEcQFhYdEbpMoJpAYBtCrF8qf0HQTVBcwy+9B8dsSCZ+6a1JSP46BOWAIRy8fJpB0IZPnIBXE0p2CWBNQva36/UxlmxLhkhLS6HUtpMEQ5yqvNvSidPpYmpqlg/9n4LT03P9+EWhAhFg0SFp6xEcqjlSJg5X7UeWJdalGtFoNCrA0dXL0NA4A4MuOjq6GXCOKlc34ZOrBBE7NhMMdCptt9yrQxsVRcfLHooLc9HHxaiAxpuPedMzyNy8B5frKx6PV0nPgNgjkPJvIKhQMg9aL9PbO8zZCw2rWLAiLcRtgZzfByjO/zsAJhXAt5DrtxpPUVyUy8iIavAfseDxUn+lmfan3cu1MEDOlgxqq8swxC+6vzI2pqfycXgMm/0kXq9PLSuAd8Cmvxm6ssKGvdSKvfw0bre6S+MCeftVCNb+FyBIgyAyL5OA5gVgTFyjJysrHZMpCVNKIgcrbSpXabe1rYs081qSkxPYW3JMeVI3QhQJsEYj+88BR81mk1yweyvZlnSMRgMl+/JUQCAQwDU2yfy8h+Y7z7l4qSlIkOv8WDgeWuVYZP8TSdLkGeJjJa02CrPZRE11mQr47vHy8NFrRkYncA5+Vlb5LX65ABzu3z6TRYesPQMcUMZZxZNJEM34pfOKePEVwsIaTaR3AwGNHdgF5CyV+yD4DCHdx6dxgsMTkv0Eyz3VGTMtt6oAAAAASUVORK5CYII=""")
LOGO_WIDTH = 16
LOGO_HEIGHT = 16
FULL_WIDTH = 64
FULL_HEIGHT = 32

DEFAULT_LOCATION = """
    {
        "lat": "40.6781784",
        "lng": "-73.9441579",
        "description": "Brooklyn, NY, USA",
        "locality": "Brooklyn",
        "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
        "timezone": "America/New_York"
    }
"""  # From https://github.com/tidbyt/pixlet/blob/main/examples/sunrise.star, works as a default for us too

def render_failure(failure_message, current_time_str):
    return render_layout(failure_message, current_time_str, FULL_WIDTH)

def render_top_row(top_text = ""):
    return render.Row(
        children = [
            render.Row(children = [render.Image(src = SB_ICON)]),
            render.Box(
                render.Row(
                    expanded = True,
                    children = [
                        render.Box(
                            render.Text(top_text),
                        ),
                    ],
                ),
                height = FULL_HEIGHT - LOGO_HEIGHT,
                width = FULL_WIDTH - LOGO_WIDTH,
            ),
        ],
    )

def render_bottom_row(marquee_text, thermometer_width):
    return render.Stack(
        children = [
            render.Box(height = LOGO_HEIGHT, color = "#00054d", width = thermometer_width),
            render.Row(
                children = [
                    render.Box(
                        render.Marquee(
                            align = "start",
                            width = FULL_WIDTH,
                            child = render.Text(marquee_text, color = "#FFF"),
                        ),
                        height = LOGO_HEIGHT,
                        width = FULL_WIDTH,
                    ),
                ],
            ),
        ],
    )

def render_layout(marquee_text, top_text, thermometer_width):
    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                cross_align = "start",
                children = [
                    render_top_row(top_text),
                    render_bottom_row(marquee_text, int(thermometer_width)),
                ],
            ),
        ),
    )

def main(config):
    # Load config values
    sb_api_token = config.get("sb_api_token") or ""
    location = config.get("location", DEFAULT_LOCATION)
    timezone = json.decode(location)["timezone"]

    # Format current time early for failure rendering
    current_time_str = time.now().in_location(timezone).format("3:04 PM")

    if not sb_api_token:
        return render_failure("API TOKEN REQUIRED", current_time_str)

    # Load layout data
    sb_cached_json = cache.get("sb_cached_json")

    if sb_cached_json != None:
        # Cache hit, use stored data
        res_json = json.decode(sb_cached_json)
    else:
        # Cache miss, re-retrieve from API
        res = http.get(BASE_API_URL, auth = ("Switchboard", sb_api_token))
        if res.status_code != 200:
            # Something went wrong with the API request
            return render_failure("REQUEST FAILED: " + str(res.status_code), current_time_str)

        # Store the retrieved data in cache
        res_json = res.json()
        cache.set("sb_cached_json", json.encode(res_json), ttl_seconds = 60)

    # Retrieve values from json blob
    marquee_text = res_json.get("marquee_text")
    top_text = res_json.get("top_text")
    thermometer_width = res_json.get("thermometer_width")

    # Use some sensible defaults
    if not top_text:
        # Show current time
        top_text = current_time_str
    if not thermometer_width:
        # Use full width
        thermometer_width = FULL_WIDTH
    if not marquee_text:
        marquee_text = "Welcome to your Tidbyt Switchboard display"

    return render_layout(marquee_text, top_text, thermometer_width)

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
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
        ],
    )
