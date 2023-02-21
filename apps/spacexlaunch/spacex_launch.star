"""
Applet: SpaceX Launch
Summary: Displays next SpaceX launch
Description: Displays information about an upcoming SpaceX rocket launch.
Author: rytrose
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Cache constants
UPCOMING_LAUNCH_CACHE_KEY = "upcoming_launch"
UPCOMING_LAUNCH_IMAGE_CACHE_KEY = "upcoming_launch_image"
CACHE_TTL_SECONDS = 300  # 5 minutes

# Development config options
DEV_CONFIG_KEY = "dev"
SKIP_CACHE_CONFIG_KEY = "skip_cache"

# Public config options
API_KEY_CONFIG_KEY = "api_key"
SEARCH_CONFIG_KEY = "search"

# Launch Library 2 API URL templates
DEV_DATA_SOURCE_URL_TEMPLATE = "https://lldev.thespacedevs.com/2.2.0/launch/upcoming?search={}&mode=normal&limit=1"
DATA_SOURCE_URL_TEMPLATE = "https://ll.thespacedevs.com/2.2.0/launch/upcoming?search={}&mode=normal&limit=1"

# Background image for error screen
ERROR_IMAGE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACsAAAAgCAMAAAC8RHExAAAAIGNIUk0AAHomAACAhAAA+gAAAIDo
AAB1MAAA6mAAADqYAAAXcJy6UTwAAAIrUExURcDAwMDAwcDAtb+/J8DAAL3AAzy/hADAwwDAwADAwgDAUwDAAADDAFRsVMIAwsAAwMAAw78A
g8AAAsAAAMMAAJcAKAoAtQAAwQAAwMDAJ5gAKL+/wL+/wb+/tb+/ALy/Azy+hAC/wwG/wAG/wgC/VAC/AADCAMEAwr8BwL8Bw74Bg78AA78A
AMIAAAsBtQABwQEBwEREwEREwUVFtk5OMVFRClBQDFFQD25Ih31Ew3xEwH1Ewj1LWwpRCQxQDAtQCSVjW0V8wkR8wER+w0hZh1AOD1AMDFAL
ClkkMnl2tnx8wXx8wAAAwgAAtwwMNxAQEA4OEREOFIoBicYAwsMAwMQAwMQAwWEIXxMQExQNEAlfXwDGwwDFwQDIxAONixAWFhATEw4RETY4
OLu7uMXFwsXFwQAEsgAEswEFqg0RORweHy8vLzIvMpgkmMoeysgfyLgLvK4AtbAAt1kJYBQRGxcRHRcRHhYRHBQQEgxVVQKsrAKrqwKurgd7
exIUFBISEhMTEzQ0NKOjo6ysrKurqwAdWgAdWQAbR1Bje+Hh4ePj4+Pi4/Hh8fjg+Pfg94ZTpUAAckMAdTcBaS4CXy4CYCsEWBcQHRIcGxEo
KA8fHwoKCg0NDRUVFRsbGx4eHicnJygoKAAhSwAdSVlui////31foS0AZzEAaTIAajIAay8CYhcQHxMTEhMSEhAPDwkJCQwMDB0dHQAhTFhu
iv3+/n5foS4AZy8CYRQUFAimUx8AAAABYktHRKRZvnq5AAAAB3RJTUUH5wILDg0M3NJKlwAAAUJJREFUOMtjYAACRiZmFiBgZWPn4ODg5OIG
Ah5ePn5+fgFBIWFhYRFRMXEJIGAYVTuqdlQtLrWSeNVKQdVKA4GMLLMcEMgrKCopKSmrqAKBGq+6hoaGppa2jo6OrqievgEQMBgCgZGxiamZ
mZm5haWVlZW1ja2dnZ29g6OTk5Ozi6ubm5u7h6eXNxAwiAOBj6+ff0BAQGBQcEhoWHC4f0RERGRUdExMTGxcfEJCQmJSckoqEDCkAUF6RmZW
dnZ2Tm5efkFhUXFJaVl5RWVVdXV1TW1dfUNDfWNTcwsQMLSCQFt7R2dXV3dPb1//hImTJk+ZMnXa9BkgMHPW7IY5c+fNXwACDAvBYNHiJRCw
dNnyFStXrly1es1aEFi3fkPDnI1z68GAYRMYLNq8BaJ267YVQLBy++o1DSDgD1G7A8wZzmoBr/8slG0y/HEAAAAldEVYdGRhdGU6Y3JlYXRl
ADIwMjMtMDItMTFUMTQ6MTI6MTIrMDA6MDCrZgI7AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAyLTExVDE0OjEyOjAxKzAwOjAwJ3mghAAA
ACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyMy0wMi0xMVQxNDoxMzoxMSswMDowMFME6vsAAAAASUVORK5CYII=""")

def get_schema():
    """Returns the pixlet app schema.

    Returns:
        schema.Schema: The schema to use.
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = API_KEY_CONFIG_KEY,
                name = "API Key",
                desc = "(optional) An API key for the Lauch Library 2 API (https://thespacedevs.com/llapi).",
                icon = "key",
                default = "",
            ),
            schema.Text(
                id = SEARCH_CONFIG_KEY,
                name = "Search",
                desc = "(optional) ONLY USED IF AN API KEY IS PROVIDED. A search term for the upcoming launch API. The default search is \"spacex\".",
                icon = "magnifyingGlass",
                default = "",
            ),
        ],
    )

def main(config):
    """Runs the SpaceX Launch pixlet app.

    Args:
        config (AppletConfig): The pixlet config object.

    Returns:
        render.Root: The root object to render.
    """

    launch = get_upcoming_launch(config)
    if not launch:
        return render_error()

    image = get_launch_image(launch)
    if not image:
        return render_error()

    name, status, status_color, window_start_day, window_start_time = get_launch_text(launch)
    if not name or not status or not status_color or not window_start_day or not window_start_time:
        return render_error()

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    child = render.Text(name, font = "tom-thumb", color = "#005288"),
                    width = 64,
                    height = 5,
                ),
                render.Row(children = [
                    render.Box(
                        child = render.Image(src = image, width = 30, height = 24),
                        width = 32,
                        height = 27,
                        color = "#ffffff",
                    ),
                    render.Box(
                        child = render.Column(
                            children = [
                                render.Marquee(
                                    child = render.Text(status, font = "tom-thumb", color = status_color),
                                    width = 32,
                                    height = 5,
                                ),
                                render.Marquee(
                                    child = render.Text(window_start_day, font = "tom-thumb", color = "#a7a9ac"),
                                    width = 32,
                                    height = 5,
                                ),
                                render.Marquee(
                                    child = render.Text(window_start_time, font = "tom-thumb", color = "#a7a9ac"),
                                    width = 32,
                                    height = 5,
                                ),
                            ],
                            expanded = True,
                            main_align = "space_evenly",
                        ),
                    ),
                ]),
            ],
        ),
    )

def get_upcoming_launch(config):
    """Returns data about the next SpaceX launch. 

    Args:
        config (AppletConfig): The pixlet config object.

    Returns:
        dict: A dictionary of data from the Launch Library API.
    """
    skip_cache = config.get(SKIP_CACHE_CONFIG_KEY) or False

    # Check the cache
    launch = cache.get(UPCOMING_LAUNCH_CACHE_KEY)
    if launch and not skip_cache:
        return json.decode(launch)
    else:
        # Invalidate image cache
        cache.set(UPCOMING_LAUNCH_IMAGE_CACHE_KEY, "", ttl_seconds = 0)

    # Determine which API to hit, the real API has a 15 req/hr rate limit.
    # The dev API has no rate limit, but stale data.
    is_dev = config.get(DEV_CONFIG_KEY)
    if is_dev:
        url_template = DEV_DATA_SOURCE_URL_TEMPLATE
    else:
        url_template = DATA_SOURCE_URL_TEMPLATE

    # Permit a search if user provides their own API key, or if hitting the dev API.
    api_key = config.get(API_KEY_CONFIG_KEY)
    search = "spacex"
    custom_search = config.get(SEARCH_CONFIG_KEY)
    if (api_key or is_dev) and custom_search and custom_search.lower() != "spacex":
        print("Using custom search \"{}\"".format(custom_search))
        search = custom_search

    headers = {}
    if api_key:
        headers["Authorization"] = "Token {}".format(api_key)

    response = http.get(url_template.format(search, headers = headers))
    if response.status_code != 200:
        return None

    body = response.json()
    if not body:
        return None

    results = body.get("results")
    if not results or type(results) != "list" or len(results) != 1:
        return None

    launch = results[0]
    cache.set(UPCOMING_LAUNCH_CACHE_KEY, json.encode(launch), ttl_seconds = CACHE_TTL_SECONDS)

    return launch

def get_launch_image(launch):
    """Returns a binary string of the image associated with the launch.

    Args:
        launch (dict): A launch object as returned from the Launch Library API.

    Returns:
        str: A string of binary image data.
    """

    image = cache.get(UPCOMING_LAUNCH_IMAGE_CACHE_KEY)
    if image:
        return image

    image_url = launch.get("image")

    if not image_url or type(image_url) != "string":
        return None

    response = http.get(image_url)
    if response.status_code != 200:
        return None

    image = response.body()

    cache.set(UPCOMING_LAUNCH_IMAGE_CACHE_KEY, image, ttl_seconds = CACHE_TTL_SECONDS)

    return image

def get_launch_text(launch):
    """Returns text to display about the launch.

    Args:
        launch (dict): A launch object as returned from the Launch Library API.

    Returns:
        name (str): The name of the mission.
        status (str): An abbreviation for the current status of the mission.
        status_color (str): A hex color to display the status in.
        window_start_day (str): The date the launch window opens.
        window_start_time (str): The time the launch window opens.
    """

    name = launch.get("mission", {}).get("name", None)
    status = launch.get("status", {}).get("abbrev", None)
    status_color = "#a7a9ac"
    if status == "Go" or "Success":
        status_color = "#008f0c"
    elif status == "Failure":
        status_color = "#8f0926"

    window_start = launch.get("window_start", None)
    if not window_start:
        return None, None, None, None, None
    window_start_parsed = time.parse_time(window_start)
    window_start_day = window_start_parsed.format("01-02-06")
    window_start_time = window_start_parsed.format("15:04MST")

    return name, status, status_color, window_start_day, window_start_time

def render_error():
    """Returns an error screen.

    Returns:
       render.Root: The root object to render.
    """

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(ERROR_IMAGE, width = 64, height = 32),
                render.Box(
                    child = render.WrappedText("Houston, we have a problem...", font = "tom-thumb", color = "#000000", width = 56),
                    width = 64,
                    height = 22,
                ),
            ],
        ),
    )
