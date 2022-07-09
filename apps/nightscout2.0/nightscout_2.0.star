"""
Applet: Nightscout 2.0
Summary: Shows Nightscout CGM Data
Description: Displays Continuous Glucose Monitoring (CGM) data from the Nightscout Open Source project (https://nightscout.github.io/).
Author: Jeremy Tavener, Paul Murphy
"""
load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("re.star", "re")
load("humanize.star", "humanize")
    
COLOR_RED = "#C00"
COLOR_DARK_RED = "#911"
COLOR_YELLOW = "#ff8"
COLOR_ORANGE = "#d61"
COLOR_GREEN = "#2b3"
COLOR_GREY = "#777"
COLOR_WHITE = "#fff"

DEFAULT_NORMAL_HIGH = 150
DEFAULT_NORMAL_LOW = 100
DEFAULT_URGENT_HIGH = 200
DEFAULT_URGENT_LOW = 70

CACHE_TTL_SECONDS = 60

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

DEFAULT_NSID = ""

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = config.get("timezone") or "America/Denver"
    now = time.now().in_location(timezone)
    nightscout_id = config.get("nightscout_id", DEFAULT_NSID)
    normal_high = int(config.get("normal_high", DEFAULT_NORMAL_HIGH))
    normal_low = int(config.get("normal_low", DEFAULT_NORMAL_LOW))
    urgent_high = int(config.get("urgent_high", DEFAULT_URGENT_HIGH))
    urgent_low = int(config.get("urgent_low", DEFAULT_URGENT_LOW))


    if nightscout_id != None:
        nightscout_data_json, status_code = get_nightscout_data(nightscout_id)
    else:
        nightscout_data_json, status_code = EXAMPLE_DATA, 0

    if status_code == 503:
        print("Page not found for nightscout ID '" + nightscout_id + "' - is this ID correct?")
        return display_failure("Page not found for nightscout ID '" + nightscout_id + "' - is this ID correct?")
    elif status_code > 200:
        return display_failure("Failed to retieve the Nightscout details with status " + str(status_code))

    # Pull the data from the cache
    sgv_current = int(nightscout_data_json["sgv_current"])
    sgv_delta = int(nightscout_data_json["sgv_delta"])
    latest_reading_dt = time.parse_time(nightscout_data_json["latest_reading_date_string"])
    trend = nightscout_data_json["trend"]
    direction = nightscout_data_json["direction"]

    # Used for finding the icon later. Default state is yellow to make the logic easier
    font_color = COLOR_YELLOW
    color_str = "Yellow"

    if (time.parse_duration("15m") < (time.now().in_location("UTC") - latest_reading_dt)):
        # The information is stale (i.e. over 5 minutes old) - overrides everything.
        color_str = "Grey"
        font_color = COLOR_GREY
        direction = "Dash"
    elif (sgv_current <= normal_high and sgv_current >= normal_low):
        # We're in the normal range, so use green.
        font_color = COLOR_GREEN
        color_str = "Green"
    elif (sgv_current >= urgent_high or sgv_current <= urgent_low):
        # We're in the urgent range, so use red.
        font_color = COLOR_RED
        color_str = "Red"

    str_delta = str(sgv_delta)
    if (sgv_delta < 1):
        str_delta = str_delta
    else:
        str_delta = "+" + str_delta

    # Get the trend - one of DoubleDown, SingleDown, FortyFiveDown, Flat, FortyFiveUp, SingleUp, DoubleUp

    if (time.parse_duration("1m") > (time.now().in_location("UTC") - latest_reading_dt)):
        reading_ago = "< 1 min ago"
    else:
        reading_ago = humanize.relative_time(time.now().in_location("UTC"),latest_reading_dt, "from now", "ago")
        reading_ago = reading_ago.replace("ute", "")
    
    return render.Root(
        render.Box(
            render.Row(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Column(
                        cross_align = "center",
                        main_align = "space_between",
                        expanded = True,
                        children = [
                            render.Row(
                            cross_align = "center",
                            main_align = "space_evenly",
                            expanded = True,
                            children = [
                             render.Text(
                                content = str(int(sgv_current)),
                                font = "6x13",
                                color = font_color,
                            ),
                            render.Text(
                                content = str_delta,
                                font = "tom-thumb",
                                color = COLOR_GREY,
                                offset = -1,
                            ),
                            render.Text(
                                content = ARROWS[direction],
                                font = "6x13",
                                color = font_color,
                                offset = 1,
                            ),
                            ]),
                            render.Text(
                                content = reading_ago,
                                font = "CG-pixel-3x5-mono",
                                color = COLOR_GREY,
                            ),
                            render.Animation(
                                children = [
                                    render.Text(
                                        content = now.format("3:04 PM"),
                                        font = "6x13",
                                        color = COLOR_ORANGE,
                                    ),
                                    render.Text(
                                        content = now.format("3 04 PM"),
                                        font = "6x13",
                                        color = COLOR_ORANGE,
                                    ),
                                ],
                            ),
                           ],
                    ),
                ],
            ),
        ),
        delay = 500,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "place",
            ),
            schema.Text(
                id = "nightscout_id",
                name = "Nightscout URL",
                desc = "Your Nightscout URL (i.e. abc123.herokuapp.com)",
                icon = "user",
            ),
            schema.Text(
                id = "normal_high",
                name = "Normal High Threshold",
                desc = "Anything above this is displayed yellow unless it is above the Urgent High Threshold (default " + str(DEFAULT_NORMAL_HIGH) + ")",
                icon = "inputNumeric",
            ),
            schema.Text(
                id = "normal_low",
                name = "Normal Low Threshold",
                desc = "Anything below this is displayed yellow unless it is below the Urgent Low Threshold (default " + str(DEFAULT_NORMAL_LOW) + ")",
                icon = "inputNumeric",
            ),
            schema.Text(
                id = "urgent_high",
                name = "Urgent High Threshold",
                desc = "Anything above this is displayed red (Default " + str(DEFAULT_URGENT_HIGH) + ")",
                icon = "inputNumeric",
            ),
            schema.Text(
                id = "urgent_low",
                name = "Urgent Low Threshold",
                desc = "Anything below this is displayed red (Default " + str(DEFAULT_URGENT_LOW) + ")",
                icon = "inputNumeric",
            ),
        ],
    )

# This method returns a tuple of a nightscout_data and a status_code. If it's
# served from cache, we return a status_code of 0.
def get_nightscout_data(nightscout_id):
    key = nightscout_id + "_nightscout_data"

    # Get the JSON object from the cache
    nightscout_data_cached = cache.get(key)
    if nightscout_data_cached != None:
        print("Hit - displaying cached data")
        return json.decode(nightscout_data_cached), 0

    # If it's not in the cache, construct it from a response.
    print("Miss - calling Nightscout API")
    nightscout_url = "https://" + nightscout_id + "/api/v1/entries.json"
    print(nightscout_url)
    # Request latest entries from the Nightscout URL
    resp = http.get(nightscout_url)
    if resp.status_code != 200:
        return {}, resp.status_code

    latest_reading = resp.json()[0]
    previous_reading = resp.json()[1]
    latest_reading_date_string = latest_reading["dateString"]
    latest_reading_dt = time.parse_time(latest_reading_date_string)

    # Current sgv value
    sgv_current = latest_reading["sgv"]

    # Delta between the current and previous
    sgv_delta = int(sgv_current - previous_reading["sgv"])
    
    # Get the trend
    trend = latest_reading["trend"]
    direction = latest_reading["direction"]
    
    print ("%d %d %s" % (sgv_current, sgv_delta, ARROWS[direction]))
    
    nightscout_data = {
        "sgv_current": str(int(sgv_current)),
        "sgv_delta": str(int(sgv_delta)),
        "latest_reading_date_string": latest_reading_date_string,
        "trend": trend,
        "direction": direction,
    }

    cache.set(key, json.encode(nightscout_data), ttl_seconds = CACHE_TTL_SECONDS)

    return nightscout_data, resp.status_code

def display_failure(msg):
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
        ),
    )

ARROWS = {
    "None": "",
    "DoubleDown": "↓↓",
    "DoubleUp": "↑↑",
    "Flat": "→",
    "FortyFiveDown": "↘",
    "FortyFiveUp": "↗",
    "SingleDown": "↓",
    "SingleUp": "↑",
    "Error": "?",
    "Dash": "-",
    "NOT COMPUTABLE": "?",
}

EXAMPLE_DATA = {
    "sgv_current": "333",
    "sgv_delta": "-4",
    "latest_reading_date_string": time.now().format("2006-01-02T15:04:05.999999999Z07:00"),
    "trend": "0",
    "direction": "Flat",
}
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    return render.Root(
        child = render.Box(height = 1, width = 1),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )