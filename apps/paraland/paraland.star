"""
Applet: Paraland
Summary: Shows hand drawn landscapes
Description: See cool hand drawn pixel art landscapes from your Tidbyt.
Author: yonodactyl
"""

# CONFIG
SEATTLE_MORNING = "https://user-images.githubusercontent.com/18172931/209709787-a0de07b4-73b6-4b07-9dca-bb3afdac0ec9.gif"  # Seattle - Morning GIF
ARIZONA_DAY = "https://user-images.githubusercontent.com/18172931/209717878-52336c10-d1f6-43fb-b2e1-87e3f35f4f96.gif"  # Arizona Desert - Day GIF
NORTH_CAROLINA_MORNING = "https://user-images.githubusercontent.com/18172931/209722206-59e215d5-b25c-44f9-9f31-37171fd6fe6e.gif"  # NC Blue Ridge Mountain - Morning GIF
DEFAULT_MORNING = "https://user-images.githubusercontent.com/18172931/209724120-57b351d1-79e6-47fc-b32d-73a23c371758.gif"  # Default Image

DEFAULT_DELAY = "150"
TTL = 86400

# LOAD MODULES
load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("cache.star", "cache")

# MAIN
def main(config):
    # Grab the configuration information and adjust variables
    selected_img = config.get("image", DEFAULT_MORNING)
    selected_speed = int(config.get("scroll_delay", DEFAULT_DELAY))

    # Grab the URL and fetch/cache the `.gif`
    img_src = get_cached(selected_img)

    if img_src == None:
        # Render an image with a slight delay
        return render.Root(
            child = render.Box(
                child = render.Marquee(
                    width = 64,
                    child = render.Text("Unable to render the data"),
                ),
            ),
        )
    else:
        # Render an image with a slight delay
        return render.Root(
            delay = selected_speed,
            child = render.Image(src = img_src),
        )

def get_schema():
    # Speed options for the parallax
    speed_options = [
        schema.Option(
            display = "Default",
            value = "150",
        ),
        schema.Option(
            display = "Slow",
            value = "400",
        ),
        schema.Option(
            display = "Fast",
            value = "10",
        ),
    ]

    # Landscape options
    options = [
        schema.Option(
            display = "Default - Morning",
            value = DEFAULT_MORNING,
        ),
        schema.Option(
            display = "North Carolina - Morning",
            value = NORTH_CAROLINA_MORNING,
        ),
        schema.Option(
            display = "Seattle - Morning",
            value = SEATTLE_MORNING,
        ),
        schema.Option(
            display = "Arizona - Day",
            value = ARIZONA_DAY,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "image",
                name = "Landscape",
                desc = "The Landscape GIF to be looped",
                icon = "image-landscape",
                default = options[0].value,
                options = options,
            ),
            schema.Dropdown(
                id = "scroll_delay",
                name = "Delay",
                desc = "The speed to scroll the landscape at",
                icon = "gauge",
                default = speed_options[0].value,
                options = speed_options,
            ),
        ],
    )

# HELPER
def get_cached(url, ttl_seconds = TTL):
    # Attempt to grab the cache
    data = cache.get(url)

    if data:
        # Cache exist - returning this data
        return data

    # No cache - continuing to the web
    res = http.get(url)

    # An error occured
    if res.status_code != 200:
        # In the event of a failure, we should return an empty string
        return None

    # Grab responses body
    data = res.body()

    # Set cache and dont try again until the next day
    cache.set(url, data, ttl_seconds = ttl_seconds)

    # Return the data we got from the web
    return data
