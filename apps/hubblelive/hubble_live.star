"""
Applet: Hubble Live
Summary: Current Hubble Observation
Description: Displays the currently scheduled observation status of the Hubble Space Telescope.
Author: Brian McLaughlin (SpinStabilized)
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#-------------------------------------------------------------------------------
# Constants
#-------------------------------------------------------------------------------

# Configuration Constants
DEFAULT_DISPLAY_ON_SLEW = True
DEFAULT_DISPLAY_ON_CAL = True

# Cache, HTTP, and URL constants
HTTP_STATUS_OK = 200
DEFAULT_CACHE_TIMEOUT = 60
SPACE_TELESCOPE_LIVE_API = "https://api.spacetelescopelive.org/observation_timelines/latest"

# Color Constants
RED = "#ff0000"
GREEN = "#00ff00"
DARK_GREEN = "#00ff0030"
BLUE = "#0000ff"
ORANGE = "#ffa500"
YELLOW = "#ffff00"
CYAN = "#00ffff"
WHITE = "#ffffff"
OBS_STATE_COLORS = {
    "Acquiring New Target": ORANGE,
    "Observing": GREEN,
    "Calibrating": YELLOW,
}

# Screen Constants and Font Specifics
SCREEN_HEIGHT = 32
SCREEN_WIDTH = 64
SMALL_FONT = "tom-thumb"

# Constants for debugging. Set to true to override cache and force the api
# calls.
CACHE_OVERRIDE = False
# CACHE_OVERRIDE = True

#-------------------------------------------------------------------------------
# Utilities
#-------------------------------------------------------------------------------

def pad_left(in_str, width):
    """Add space padding to the left side of a string.

    Args:
        in_str: The input string to pad.
        width: The desired width of the output string.

    Returns:
       A string padded out to `width` characters by adding spaces to the left.
    """
    out_str = in_str
    if len(in_str) < width:
        delta = width - len(in_str)
        out_str = (" " * delta) + in_str
    return out_str

#-------------------------------------------------------------------------------
# Data Retrival
#-------------------------------------------------------------------------------

def get_hst_live():
    """Get the current Hubble observation.

    Retrieve's the current expexted Hubble observation based on the observation
    timeline.

    Data provided by:

    https://spacetelescopelive.org/

    Returns:
       A dictionary of information regarding the current Hubble observation.
    """
    data = cache.get("cached_observation")
    if data and not CACHE_OVERRIDE:
        obs = json.decode(data)
    else:
        api_reply = http.get(SPACE_TELESCOPE_LIVE_API)
        if api_reply.status_code == HTTP_STATUS_OK:
            obsjson_raw = api_reply.body()
        else:
            obsjson_raw = "{}"

        obs = json.decode(obsjson_raw)

        if obs.get("what_am_i_looking_at", None) == "Hubble is acquiring a new target":
            obs["state"] = "Acquiring New Target"
            obs["target_name"] = ""
            obs["ra"] = ""
            obs["dec"] = ""
            obs["science_instrument_acronym"] = ""
            obs["reference_image_url"] = ""
            obs["reference_image_base64"] = ""
            obs["proposal_id"] = ""
            obs["category"] = ""

        if obs.get("reference_image_url", None):
            obs["reference_image_base64"] = get_ref_image(obs["reference_image_url"])
        else:
            obs["reference_image_url"] = ""

        if obs.get("ra", None) == None or obs.get("ra") == "":
            obs["ra"] = ""
        else:
            obs["ra"] = humanize.float("+#.##", float(obs["ra"]))

        if obs.get("dec", None) == None or obs.get("dec") == "":
            obs["dec"] = ""
        else:
            obs["dec"] = humanize.float("+#.##", float(obs["dec"]))

        if obs.get("end_at", None) != None:
            cache_timeout = time.parse_time(obs["end_at"]) - time.now().in_location("UTC")
            cache_timeout = int(cache_timeout.seconds) if cache_timeout.seconds >= 0 else 0
        else:
            cache_timeout = DEFAULT_CACHE_TIMEOUT
        cache.set("cached_observation", json.encode(obs), ttl_seconds = cache_timeout)

    return obs

def get_ref_image(image_url):
    """Retrieve an image associated with the observation target.

    Args:
        image_url: The image URL from the api

    Returns:
        A base64 encoded version of the image or an empty string.
    """
    image_url = re.sub(r"&opt=LG", "", image_url, count = 1)
    image_src = ""

    api_reply = http.get(image_url)
    if api_reply.status_code == HTTP_STATUS_OK:
        image_src = base64.encode(api_reply.body())
    return image_src

#-------------------------------------------------------------------------------
# Render Functions
#-------------------------------------------------------------------------------

def render_image(obs, size):
    """Render the observation image.

    Render an associated observation skyfield image from the Sloan Digital Sky
    Survey. If no image is associated, place the frame with a "No Img" message.

    Args:
        obs: The observation data dictionary that contains the image info
        size: Size in pixels of one side of the square image to be displayed

    Returns:
        A `render.Box` object frame with a `render.Image` child or a
        `render.Text` object.
    """
    if obs.get("reference_image_base64", None):
        return render.Box(
            width = size,
            height = size,
            color = DARK_GREEN,
            padding = 1,
            child = render.Image(
                src = base64.decode(obs["reference_image_base64"]),
                width = size - 2,
                height = size - 2,
            ),
        )
    else:
        return render.Box(
            width = size,
            height = size,
            color = DARK_GREEN,
            padding = 1,
            child = render.WrappedText(
                "No Img",
                width = size - 2,
                height = size - 2,
                align = "center",
            ),
        )

def marquee_text(text, width = SCREEN_WIDTH, font = SMALL_FONT, color = WHITE):
    """Marquee object with an embedded text object.

    Args:
        text: String text content to display
        width: Integer width in pixels of the `render.Marquee` object
        font: String name of the font to use
        color: String hex color for the text

    Returns:
        A `render.Marquee` object with an embedded `render.Text` child object.
    """
    return render.Marquee(
        child = render.Text(
            text,
            font = font,
            color = color,
        ),
        width = width,
    )

#-------------------------------------------------------------------------------
# Render Display
#-------------------------------------------------------------------------------

def render_display(obs, img_size = 20):
    """Function that renders the display.

    Args:
       obs: Hubble observation data
       img_size: Size of side of square for display of starfield

    Returns:
        A `render.Root` object.
    """
    target_text = obs["target_name"]
    if obs["category"] and len(obs["category"]) > 0:
        target_text = "{} - {}".format(obs["category"], obs["target_name"])
    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    main_align = "space_between",
                    children = [
                        render.Column(
                            children = [
                                marquee_text(
                                    obs["state"],
                                    width = SCREEN_WIDTH,
                                    color = OBS_STATE_COLORS.get(obs["state"], WHITE),
                                ),
                                marquee_text(
                                    target_text,
                                    width = SCREEN_WIDTH,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    main_align = "space_between",
                    children = [
                        render.Column(
                            children = [
                                marquee_text(obs["science_instrument_acronym"], width = SCREEN_WIDTH - img_size),
                                render.Row(
                                    children = [
                                        render.Text(pad_left("RA=", 4), color = CYAN, font = SMALL_FONT),
                                        render.Text(pad_left(obs["ra"], 7), color = WHITE, font = SMALL_FONT),
                                    ],
                                ),
                                render.Row(
                                    children = [
                                        render.Text(pad_left("Dec=", 4), color = CYAN, font = SMALL_FONT),
                                        render.Text(pad_left(obs["dec"], 7), color = WHITE, font = SMALL_FONT),
                                    ],
                                ),
                            ],
                        ),
                        render_image(obs, img_size),
                    ],
                ),
            ],
        ),
    )

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

def main(config):
    """Main function body.

    Args:
       config: A Tidbyt configuration object

    Returns:
        A `render.Root` object or empty list `[]` if nothing to display.
    """
    display_on_slew = config.bool("display_on_slew", DEFAULT_DISPLAY_ON_SLEW)
    display_on_cal = config.bool("display_on_cal", DEFAULT_DISPLAY_ON_CAL)
    obs = get_hst_live()

    render_obj = []
    if (obs["state"] == "Acquiring New Target" and display_on_slew) or \
       (obs["state"] == "Calibrating" and display_on_cal) or \
       (obs["state"] != "Calibrating" and obs["state"] != "Acquiring New Target"):
        render_obj = render_display(obs)

    return render_obj

def get_schema():
    """Provide the schema for the Tidbyt app configuration.

    Returns:
        A `schema.Schema` object.
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "display_on_slew",
                name = "Display When Acquiring",
                desc = "Toggle to display while acuiring or hide.",
                icon = "crosshairs",
                default = DEFAULT_DISPLAY_ON_SLEW,
            ),
            schema.Toggle(
                id = "display_on_cal",
                name = "Display When Calibrating",
                desc = "Toggle to display while calibrating or hide.",
                icon = "ruler",
                default = DEFAULT_DISPLAY_ON_CAL,
            ),
        ],
    )
