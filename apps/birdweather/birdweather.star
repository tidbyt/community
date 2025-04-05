"""
Applet: Birdweather
Summary: Sightings from Birdweather
Description: Display recent sightings from a Birdweather station using their API. Requires an API token.
Author: marstonstudio
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_FONT = "tb-8"

BIRDWEATHER_ENDPOINT = "https://app.birdweather.com/api/v1"

def main(config):
    """Main entry point of app

    Args:
      config: config dict passed from the app

    Returns:
      rendered WebP image for Tidbyt display
    """
    log("main")

    token = config.str("birdweather_token", None)
    message = validate_token(token)
    if message != None:
        log(message)
        return render.Root(
            delay = 500,
            child = render.WrappedText(content = message, font = DEFAULT_FONT),
        )

    species_json = query(token)
    single_species = select_species(species_json)

    return render.Root(
        delay = 500,
        child = render_species(single_species),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "birdweather_token",
                name = "Birdweather API Token",
                desc = "Token for calling Birdweather API with a station.",
                icon = "userGear",
            ),
        ],
    )

def validate_token(token):
    """Validate token for Birdweather API.

    https://app.birdweather.com/api/v1#station-stats-station-stats-get

    Args:
      token: token for birdweather api

    Returns:
      Message to display
    """
    if token == None or len(token) == 0:
        return "No Birdweather API token defined"

    url = BIRDWEATHER_ENDPOINT + "/stations/" + token + "/stats"
    response = http.get(url, ttl_seconds = 3600)
    if response.status_code == 403:
        return "Invalid Birdweather API token"

    body = response.json()
    success = body.get("success")
    if not success:
        return "Problem calling Birdweather API"

    return None

def query(token):
    """Request a list of species for a station detected over the past 24 hours.

    https://app.birdweather.com/api/v1#station-species-station-species-get

    Args:
      token: token for birdweather api

    Returns:
      a list of species
    """
    url = BIRDWEATHER_ENDPOINT + "/stations/" + token + "/species?period=day"
    log("query: " + url)
    response = http.get(url, ttl_seconds = 300)
    if response.status_code != 200:
        log("error code: " + str(response.status_code))
        return []
    else:
        body = response.json()
        results = body.get("species")
        log("number of species: " + str(len(results)))
        return results

def select_species(species_json):
    """Select a species to use from the list. Use cache to keep track of which species have been rendered

    Args:
      species_json: list of all species json values

    Returns:
      single_species_json
    """
    count = len(species_json)
    if count == 0:
        log("empty species list")
        return None

    rendered_names_str = cache.get("rendered_names")
    if rendered_names_str == None or rendered_names_str == "":
        log("cache.get ''")
        rendered_names = set()
    else:
        log("cache.get '" + rendered_names_str + "'")
        rendered_names = set(json.decode(rendered_names_str))
        if len(rendered_names) >= count:
            rendered_names = set()

    for i in range(0, count):
        common_name = species_json[i].get("commonName")
        if common_name in rendered_names:
            continue
        else:
            rendered_names.add(common_name)
            rendered_names_str = json.encode(list(rendered_names))
            log("cache.set " + rendered_names_str)
            cache.set("rendered_names", rendered_names_str, ttl_seconds = 300)
            log("selecting item " + str(i) + " " + common_name)
            return species_json[i]

    log("selecting random item")
    cache.set("rendered_names", "", ttl_seconds = 300)
    return species_json[random.number(0, count - 1)]

def render_species(single_species_json):
    """Render the screen for a single species

    Args:
      single_species_json: json value for a single species

    Returns:
      render ready WebP image for Tidbyt display
    """
    if single_species_json == None:
        return render.WrappedText(content = "No results from Birdweather API", font = DEFAULT_FONT)

    common_name = single_species_json.get("commonName")

    detection_count = int(single_species_json.get("detections").get("total"))
    detection_count_str = humanize.plural(int(detection_count), "song")
    detection_time = time.parse_time(single_species_json.get("latestDetectionAt"))
    detection_time_str = humanize.relative_time(time.now(), detection_time, "", "")
    detection_time_str = detection_time_str.replace("minute", "min") + "ago"
    detection_message = detection_count_str + " " + detection_time_str

    img = http.get(single_species_json.get("thumbnailUrl"), ttl_seconds = 86400).body()

    log(common_name + " " + detection_message + " " + single_species_json.get("thumbnailUrl"))

    return render.Column(
        children = [
            render.Marquee(
                child = render.WrappedText(content = common_name, font = DEFAULT_FONT),
                width = 64,
                height = 8,
                offset_start = 2,
                offset_end = 2,
            ),
            render.Row(
                children = [
                    render.Image(src = img, width = 24, height = 24),
                    render.Padding(
                        child = render.WrappedText(detection_message, font = DEFAULT_FONT),
                        pad = (2, 0, 0, 0),
                    ),
                ],
            ),
        ],
    )

def log(message):
    """Format "log" messages for debugging.

    Args:
      message: base message to print
    """
    print(time.now(), " - ", message)  # buildifier: disable=print
