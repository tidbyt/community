"""
Applet: Birdbyt
Summary: Show nearby bird sightings
Description: Displays a random bird sighting near a specific location.
Author: Becky Sweger
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

EBIRD_API_KEY = "AV6+xWcECVOVS+y/jlkVqyE0oxKa9Ql7M/h05Xh+ilG7K+8ELfdgmPX6FPFcDdDuEz5PSbWO1sNs+XjhuS8Bm4qbT00tO0A3DIG5mDo78bAg2dhYVIhPyp/AyiCDzVadqN2KKGduX2NKdihnCyn4NWHW"
EBIRD_URL = "https://api.ebird.org/v2"
MAX_API_RESULTS = "300"

# Config defaults
DEFAULT_LOCATION = {
    # Easthampton, MA
    "lat": "42.266",
    "lng": "-72.668",
    "timezone": "America/New_York",
}
DEFAULT_DISTANCE = "5"
DEFAULT_BACK = "2"
DEFAULT_PROVISIONAL = False

# When there are no birds
NO_BIRDS = {
    "bird": "No birds found",
    "loc": "Try increasing search distance",
}

def get_params(config):
    """Get params for e-birds request.

    Args:
      config: config dict passed from the app
    Returns:
      params: dict
    """

    params = {}

    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    params["lat"] = loc["lat"]
    params["lng"] = loc["lng"]
    params["tz"] = loc["timezone"] if time.is_valid_timezone(loc["timezone"]) else DEFAULT_LOCATION["timezone"]

    params["dist"] = config.get("distance") or DEFAULT_DISTANCE
    params["back"] = config.get("back") or DEFAULT_BACK
    params["includeProvisional"] = str(config.get("provisional") or DEFAULT_PROVISIONAL)
    params["maxResults"] = MAX_API_RESULTS

    return params

def get_notable_sightings(params, ebird_key):
    """Request a list of recent notable bird sightings.

    Args:
      params: dictionary of parameters for the ebird API call
      ebird_key: ebird API key

    Returns:
      a list of notable sightings species codes
    """

    notable_params = params
    notable_params.pop("maxResults", None)

    ebird_recent_notable_route = "/data/obs/geo/recent/notable"
    url = EBIRD_URL + ebird_recent_notable_route
    headers = {"X-eBirdApiToken": ebird_key}

    response = http.get(url, params = params, headers = headers, ttl_seconds = 10800)
    log(ebird_recent_notable_route + " cache status " + response.headers.get("Tidbyt-Cache-Status"))

    # e-bird API request failed
    if response.status_code != 200:
        return []

    notable_sightings = response.json()
    notable_list = [s.get("speciesCode") for s in notable_sightings]
    log("number of notable sightings: " + str(len(notable_list)))

    return notable_list

def get_recent_birds(params, ebird_key):
    """Request a list of recent birds.

    Args:
      params: dictionary of parameters for the ebird API call
      ebird_key: ebird API key

    Returns:
      ebird sightings data
    """

    ebird_recent_obs_route = "/data/obs/geo/recent"
    url = EBIRD_URL + ebird_recent_obs_route
    headers = {"X-eBirdApiToken": ebird_key}

    log(ebird_recent_obs_route + " params: " + str(params))
    response = http.get(url, params = params, headers = headers, ttl_seconds = 10800)
    log(ebird_recent_obs_route + " cache status " + response.headers.get("Tidbyt-Cache-Status"))

    # e-bird API request failed
    if response.status_code != 200:
        return [{
            "comName": "Bird error!",
            "locName": "API status code = " + str(response.status_code),
        }]

    sightings = response.json()
    return sightings

def parse_birds(sightings, tz):
    """Parse ebird response data.

    Args:
      sightings: list of ebird sightings
      tz: application's timezone

    Returns:
      a dictionary representing a single bird sighting
    """

    sighting = {}

    number_of_sightings = len(sightings)
    log("number of sightings: " + str(number_of_sightings))

    # request succeeded, but no birds found
    if number_of_sightings == 0:
        sighting = NO_BIRDS
        return sighting

    # grab a random bird sighting from ebird response
    random_sighting = random.number(0, number_of_sightings - 1)
    data = sightings[random_sighting]

    sighting["bird"] = data.get("comName") or "Unknown bird"
    sighting["loc"] = data.get("locName") or "Location unknown"
    sighting["species"] = data.get("speciesCode") or "Unknown species code"
    if data.get("obsDt"):
        sighting["date"] = time.parse_time(data.get("obsDt"), format = "2006-01-02 15:04", location = tz)

    return sighting

def main(config):
    """Update config.

    Args:
      config: config dict passed from the app

    Returns:
      rendered WebP image for Tidbyt display
    """
    random.seed(time.now().unix // 10)

    ebird_key = secret.decrypt(EBIRD_API_KEY) or config.get("ebird_api_key")
    if not ebird_key:
        ebird_key = "BIRDERROR-NO-API-KEY"
        log("unable to decrypt API key or retrieve from local config")

    params = get_params(config)
    timezone = params.pop("tz")
    response = get_recent_birds(params, ebird_key)
    sighting = parse_birds(response, timezone)
    bird_formatted, bird_font = format_bird_name(sighting.get("bird"))

    # if this is a notable sighting, render an excitable bird
    notable_list = get_notable_sightings(params, ebird_key)
    if sighting.get("species") in notable_list:
        bird_image = PURPLE_BIRD_JUMP
        sighting["notable"] = True
    else:
        bird_image = PURPLE_BIRD_IDLE

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                render.Box(
                                    width = 18,
                                    height = 25,
                                    child = render.Image(src = bird_image),
                                ),
                            ],
                        ),
                        render.Box(
                            height = 25,
                            padding = 1,
                            child = render.Marquee(
                                scroll_direction = "vertical",
                                align = "center",
                                height = 25,
                                child = render.WrappedText(
                                    align = "left",
                                    font = bird_font,
                                    content = bird_formatted,
                                ),
                            ),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    cross_align = "end",
                    children = [
                        render.Box(
                            color = "043927",
                            child = render.Marquee(
                                width = 64,
                                child = render.Text(
                                    color = "fefbbd",
                                    font = "tom-thumb",
                                    offset = -1,
                                    content = get_scroll_text(sighting),
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
    )

def get_schema():
    """Return the schema needed for Tidybyt community app installs.

    Returns:
      Tidbyt schema
    """

    list_back = ["1", "2", "3", "4", "5", "6"]
    options_back = [
        schema.Option(display = item, value = item)
        for item in list_back
    ]

    list_distance = ["1", "2", "5", "10", "25", "50"]
    options_distance = [
        schema.Option(display = item, value = item)
        for item in list_distance
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to search for bird sightings.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "distance",
                name = "Search radius (km)",
                desc = "Search radius from location (km)",
                icon = "feather",
                default = DEFAULT_DISTANCE,
                options = options_distance,
            ),
            schema.Dropdown(
                id = "back",
                name = "Days back",
                desc = "Number of days back to fetch bird sightings.",
                icon = "calendarDays",
                default = DEFAULT_BACK,
                options = options_back,
            ),
            schema.Toggle(
                id = "provisional",
                name = "Include unverified",
                desc = "Include sightings not yet reviewed.",
                icon = "clipboardCheck",
                default = DEFAULT_PROVISIONAL,
            ),
        ],
    )

#------------------------------------------------------------------------
# Formatting functions for display text
#------------------------------------------------------------------------

def get_scroll_text(sighting):
    """Return a text string to scroll in the bottom marquee.

    Args:
      sighting: a dictionary representing a single bird sighting

    Returns:
      text to scroll at the bottom of the Tidbyt display
    """

    days = {
        0: "Sun",
        1: "Mon",
        2: "Tues",
        3: "Wed",
        4: "Thur",
        5: "Fri",
        6: "Sat",
    }

    sighting_date = sighting.get("date")

    if sighting_date:
        day_of_week = humanize.day_of_week(sighting_date)

        # local timezone should = bird sighting timezone since both are derived from location config
        sighting_day = "Today" if day_of_week == humanize.day_of_week(time.now()) else days[day_of_week]
        scroll_text = sighting_day + ": " + sighting.get("loc")
    else:
        scroll_text = sighting.get("loc")

    if sighting.get("notable"):
        scroll_text = "!Notable sighting! " + scroll_text

    return scroll_text

def format_bird_name(bird):
    """Format bird name for display.

    Args:
      bird: name of the bird returned from API

    Returns:
      bird name modified for Tidbyt display
      Tidbyt font to use for bird name display
    """

    # Hard code hyphens into bird names that exceed a single
    # line on the Tidbyt display. This is an incomplete list.
    log("bird name: " + bird)
    bird = bird.replace("Apostlebird", "Apostle-bird")
    bird = bird.replace("Australasian", "Austra-lasian")
    bird = bird.replace("Australian", "Austra-lian")
    bird = bird.replace("Blackburnian", "Black-burnian")
    bird = bird.replace("Butcherbird", "Butcher-bird")
    bird = bird.replace("Currawong", "Curra-wong")
    bird = bird.replace("Honeyeater", "Honey-eater")
    bird = bird.replace("Hummingbird", "Humming-bird")
    bird = bird.replace("Mockingbird", "Mocking-bird")
    bird = bird.replace("Yellowthroat", "Yellow-throat")
    bird = bird.replace("catcher", "-catcher")
    bird = bird.replace("pecker", "-pecker")
    bird = bird.replace("thrush", "-thrush")

    # Wrapped text widget doesn't break on a hyphen, so force a newline
    # if a hyphenated bird name will exceed 9 characters
    bird_parts = bird.split()
    split_bird = [
        b.replace("-", "-\n", 1) if len(b) > 9 else b
        for b in bird_parts
    ]
    bird = " ".join(split_bird)

    # Setting an explicit bird name font here lays groundwork for a future
    # enhancement that can return a smaller font when bird names are long
    # (9 letters is max size of a word that displays w/o cutting off)
    font = "tb-8"

    return bird, font

def log(message):
    """Format "log" messages for debugging.

    Args:
      message: base message to print
    """

    print(time.now(), " - ", message)  # buildifier: disable=print

#------------------------------------------------------------------------
# Assets
# (until Tidbyt/pixlet has the concept of a separate assets folder,
# images and gifs are stored in the .star file as encoded binary data)
#------------------------------------------------------------------------
PURPLE_BIRD_IDLE = base64.decode("""
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
""")

PURPLE_BIRD_JUMP = base64.decode("""
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
""")
