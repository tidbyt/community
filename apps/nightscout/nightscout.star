"""
Applet: Nightscout
Summary: Shows Nightscout CGM Data
Description: Displays Continuous Glucose Monitoring (CGM) data from the Nightscout Open Source project (https://nightscout.github.io/).
Author: Jeremy Tavener
"""

load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("re.star", "re")

COLOR_RED = "#f00"
COLOR_YELLOW = "#ff0"
COLOR_GREEN = "#0f0"
COLOR_GREY = "#666"
COLOR_WHITE = "#fff"

DEFAULT_NORMAL_HIGH = 150
DEFAULT_NORMAL_LOW = 100
DEFAULT_URGENT_HIGH = 200
DEFAULT_URGENT_LOW = 70

CACHE_TTL_SECONDS = 300

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

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)

    nightscout_id = config.get("nightscout_id", None)
    normal_high = int(config.get("normal_high", DEFAULT_NORMAL_HIGH))
    normal_low = int(config.get("normal_low", DEFAULT_NORMAL_LOW))
    urgent_high = int(config.get("urgent_high", DEFAULT_URGENT_HIGH))
    urgent_low = int(config.get("urgent_low", DEFAULT_URGENT_LOW))

    if nightscout_id != None and re.match("[^a-zA-Z0-9]", nightscout_id):
        # Sanity check the Nightscout ID only consists of Alphanumeric characters
        print("Invalid Nightscout ID: " + nightscout_id)
        return display_failure("Nightscout ID contains invalid characters")

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

    # Used for finding the icon later. Default state is yellow to make the logic easier
    font_color = COLOR_YELLOW
    color_str = "Yellow"

    if (time.parse_duration("15m") < (time.now().in_location("UTC") - latest_reading_dt)):
        # The information is stale (i.e. over 5 minutes old) - overrides everything.
        color_str = "Grey"
        font_color = COLOR_GREY
    elif (sgv_current <= normal_high and sgv_current >= normal_low):
        # We're in the normal range, so use green.
        font_color = COLOR_GREEN
        color_str = "Green"
    elif (sgv_current >= urgent_high or sgv_current <= urgent_low):
        # We're in the urgent range, so use red.
        font_color = COLOR_RED
        color_str = "Red"

    str_delta = str(sgv_delta)
    if (sgv_delta < 0):
        str_delta = "-" + str_delta
    else:
        str_delta = "+" + str_delta

    # Get the trend - one of DoubleDown, SingleDown, FortyFiveDown, Flat, FortyFiveUp, SingleUp, DoubleUp
    icon_name = trend + "_" + color_str

    return render.Root(
        render.Box(
            render.Row(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Column(
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
                                content = "Updated:",
                                font = "tom-thumb",
                            ),
                            render.Marquee(
                                width = 32,
                                child = render.Text(
                                    content = latest_reading_dt.in_location(loc["timezone"]).format("2006-01-02 03:04:05 PM"),
                                    font = "tom-thumb",
                                ),
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = 2,
                                child = render.Image(
                                    src = IMAGES[icon_name],
                                    width = 14,
                                    height = 14,
                                ),
                            ),
                            render.Text(
                                content = str_delta,
                                color = COLOR_WHITE,
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
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "nightscout_id",
                name = "Nightscout ID",
                desc = "Your Nightscout ID (i.e. XXX in https://XXX.herokuapp.com/api/v1/entries.json)",
                icon = "user",
            ),
            schema.Text(
                id = "normal_high",
                name = "Normal High Threshold",
                desc = "Anything above this is displayed yellow unless it is above the Urgent High Threshold (default " + str(DEFAULT_NORMAL_HIGH) + ")",
                icon = "hashtag",
            ),
            schema.Text(
                id = "normal_low",
                name = "Normal Low Threshold",
                desc = "Anything below this is displayed yellow unless it is below the Urgent Low Threshold (default " + str(DEFAULT_NORMAL_LOW) + ")",
                icon = "hashtag",
            ),
            schema.Text(
                id = "urgent_high",
                name = "Urgent High Threshold",
                desc = "Anything above this is displayed red (Default " + str(DEFAULT_URGENT_HIGH) + ")",
                icon = "hashtag",
            ),
            schema.Text(
                id = "urgent_low",
                name = "Urgent Low Threshold",
                desc = "Anything below this is displayed red (Default " + str(DEFAULT_URGENT_LOW) + ")",
                icon = "hashtag",
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
    nightscout_url = "https://" + nightscout_id + ".herokuapp.com/api/v1/entries.json"

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

    nightscout_data = {
        "sgv_current": str(int(sgv_current)),
        "sgv_delta": str(int(sgv_delta)),
        "latest_reading_date_string": latest_reading_date_string,
        "trend": trend,
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

IMAGES = {
    "DoubleDown_Green": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEUA/wD///8A/wDGqXjlAAAAAnRSTlMAAHaTzTgAAAAqSURBVHjaY2BEAwyMDAxMTAxAcQg9mAWYwIARSmMTYADRDIwQGqsZaAAAdSQA8ZrFw6sAAAAASUVORK5CYII="),
    "DoubleDown_Grey": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEVmZmb///9mZmZ5cRRiAAAAAnRSTlMAAHaTzTgAAAAqSURBVHjaY2BEAwyMDAxMTAxAcQg9mAWYwIARSmMTYADRDIwQGqsZaAAAdSQA8ZrFw6sAAAAASUVORK5CYII="),
    "DoubleDown_Red": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX/AAD/////AACEEbvXAAAAAnRSTlMAAHaTzTgAAAAqSURBVHjaY2BEAwyMDAxMTAxAcQg9mAWYwIARSmMTYADRDIwQGqsZaAAAdSQA8ZrFw6sAAAAASUVORK5CYII="),
    "DoubleDown_Yellow": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX//wD//////wAxfkBDAAAAAnRSTlMAAHaTzTgAAAAqSURBVHjaY2BEAwyMDAxMTAxAcQg9mAWYwIARSmMTYADRDIwQGqsZaAAAdSQA8ZrFw6sAAAAASUVORK5CYII="),
    "DoubleUp_Green": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEUA/wD///8A/wDGqXjlAAAAAnRSTlMAAHaTzTgAAAArSURBVHjazYwFAQAwDMPS+vd85htYxogeENigGYu4gGZEbmjGt/H/CNx4yIv8APFQu1RUAAAAAElFTkSuQmCC"),
    "DoubleUp_Grey": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEVmZmb///9mZmZ5cRRiAAAAAnRSTlMAAHaTzTgAAAArSURBVHjazYwFAQAwDMPS+vd85htYxogeENigGYu4gGZEbmjGt/H/CNx4yIv8APFQu1RUAAAAAElFTkSuQmCC"),
    "DoubleUp_Red": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX/AAD/////AACEEbvXAAAAAnRSTlMAAHaTzTgAAAArSURBVHjazYwFAQAwDMPS+vd85htYxogeENigGYu4gGZEbmjGt/H/CNx4yIv8APFQu1RUAAAAAElFTkSuQmCC"),
    "DoubleUp_Yellow": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX//wD//////wAxfkBDAAAAAnRSTlMAAHaTzTgAAAArSURBVHjazYwFAQAwDMPS+vd85htYxogeENigGYu4gGZEbmjGt/H/CNx4yIv8APFQu1RUAAAAAElFTkSuQmCC"),
    "Flat_Green": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEUA/wD///8A/wDGqXjlAAAAAnRSTlMAAHaTzTgAAAAlSURBVHjaY2BEA9QRYIADJiYGBjQBJpAAEwrAEMDQgmkoTZwOAIR6APl9H3YYAAAAAElFTkSuQmCC"),
    "Flat_Grey": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEVmZmb///9mZmZ5cRRiAAAAAnRSTlMAAHaTzTgAAAAlSURBVHjaY2BEA9QRYIADJiYGBjQBJpAAEwrAEMDQgmkoTZwOAIR6APl9H3YYAAAAAElFTkSuQmCC"),
    "Flat_Red": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX/AAD/////AACEEbvXAAAAAnRSTlMAAHaTzTgAAAAlSURBVHjaY2BEA9QRYIADJiYGBjQBJpAAEwrAEMDQgmkoTZwOAIR6APl9H3YYAAAAAElFTkSuQmCC"),
    "Flat_Yellow": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX//wD//////wAxfkBDAAAAAnRSTlMAAHaTzTgAAAAlSURBVHjaY2BEA9QRYIADJiYGBjQBJpAAEwrAEMDQgmkoTZwOAIR6APl9H3YYAAAAAElFTkSuQmCC"),
    "FortyFiveDown_Green": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEUA/wD///8A/wDGqXjlAAAAAnRSTlMAAHaTzTgAAAAzSURBVHjaXcgBBgBBDMDAXv7/6EOsaAcw8x1FARODHUNjvCkaoymcoikcCqdwKJwdYBw/XBcArv/ktfsAAAAASUVORK5CYII="),
    "FortyFiveDown_Grey": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEVmZmb///9mZmZ5cRRiAAAAAnRSTlMAAHaTzTgAAAAzSURBVHjaXcgBBgBBDMDAXv7/6EOsaAcw8x1FARODHUNjvCkaoymcoikcCqdwKJwdYBw/XBcArv/ktfsAAAAASUVORK5CYII="),
    "FortyFiveDown_Red": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX/AAD/////AACEEbvXAAAAAnRSTlMAAHaTzTgAAAAzSURBVHjaXcgBBgBBDMDAXv7/6EOsaAcw8x1FARODHUNjvCkaoymcoikcCqdwKJwdYBw/XBcArv/ktfsAAAAASUVORK5CYII="),
    "FortyFiveDown_Yellow": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX//wD//////wAxfkBDAAAAAnRSTlMAAHaTzTgAAAAzSURBVHjaXcgBBgBBDMDAXv7/6EOsaAcw8x1FARODHUNjvCkaoymcoikcCqdwKJwdYBw/XBcArv/ktfsAAAAASUVORK5CYII="),
    "FortyFiveUp_Green": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEUA/wD///8A/wDGqXjlAAAAAnRSTlMAAHaTzTgAAAA2SURBVHjaZcjHAYBAEMSwgf57Juri+mfl2HogOt+AwPwdfDr4AT7p4IGfwAM/ge/gZzBgrcINXcAArufh9MkAAAAASUVORK5CYII="),
    "FortyFiveUp_Grey": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEVmZmb///9mZmZ5cRRiAAAAAnRSTlMAAHaTzTgAAAA2SURBVHjaZcjHAYBAEMSwgf57Juri+mfl2HogOt+AwPwdfDr4AT7p4IGfwAM/ge/gZzBgrcINXcAArufh9MkAAAAASUVORK5CYII="),
    "FortyFiveUp_Red": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX/AAD/////AACEEbvXAAAAAnRSTlMAAHaTzTgAAAA5SURBVHjaXMoBBgAwFMPQdPc/9FaYaMF/8clM4XQOsGE/HnGoabAh2CV2L8ZhHMbh20HOHYyFWwAAk6MBDA7Lw1gAAAAASUVORK5CYII="),
    "FortyFiveUp_Yellow": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX//wD//////wAxfkBDAAAAAnRSTlMAAHaTzTgAAAA2SURBVHjaZcjHAYBAEMSwgf57Juri+mfl2HogOt+AwPwdfDr4AT7p4IGfwAM/ge/gZzBgrcINXcAArufh9MkAAAAASUVORK5CYII="),
    "SingleDown_Green": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEUA/wD///8A/wDGqXjlAAAAAnRSTlMAAHaTzTgAAAAhSURBVHjaY2BEAwwQkoGJiYFhKAgwgQE+AQYQH6cZaAAAfxoA+VVpL+EAAAAASUVORK5CYII="),
    "SingleDown_Grey": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEVmZmb///9mZmZ5cRRiAAAAAnRSTlMAAHaTzTgAAAAhSURBVHjaY2BEAwwQkoGJiYFhKAgwgQE+AQYQH6cZaAAAfxoA+VVpL+EAAAAASUVORK5CYII="),
    "SingleDown_Red": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX/AAD/////AACEEbvXAAAAAnRSTlMAAHaTzTgAAAAhSURBVHjaY2BEAwwQkoGJiYFhKAgwgQE+AQYQH6cZaAAAfxoA+VVpL+EAAAAASUVORK5CYII="),
    "SingleDown_Yellow": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX//wD//////wAxfkBDAAAAAnRSTlMAAHaTzTgAAAAhSURBVHjaY2BEAwwQkoGJiYFhKAgwgQE+AQYQH6cZaAAAfxoA+VVpL+EAAAAASUVORK5CYII="),
    "SingleUp_Green": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEUA/wD///8A/wDGqXjlAAAAAnRSTlMAAHaTzTgAAAAkSURBVHjaY2BEAwwQkoGJiYEBWYAJCJAFmMAAQwDDjMEugAYAioYA+S5GwYkAAAAASUVORK5CYII="),
    "SingleUp_Grey": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEVmZmb///9mZmZ5cRRiAAAAAnRSTlMAAHaTzTgAAAAkSURBVHjaY2BEAwwQkoGJiYEBWYAJCJAFmMAAQwDDjMEugAYAioYA+S5GwYkAAAAASUVORK5CYII="),
    "SingleUp_Red": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX/AAD/////AACEEbvXAAAAAnRSTlMAAHaTzTgAAAAkSURBVHjaY2BEAwwQkoGJiYEBWYAJCJAFmMAAQwDDjMEugAYAioYA+S5GwYkAAAAASUVORK5CYII="),
    "SingleUp_Yellow": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAACVBMVEX//wD//////wAxfkBDAAAAAnRSTlMAAHaTzTgAAAAkSURBVHjaY2BEAwwQkoGJiYEBWYAJCJAFmMAAQwDDjMEugAYAioYA+S5GwYkAAAAASUVORK5CYII="),
}

EXAMPLE_DATA = {
    "sgv_current": "146",
    "sgv_delta": "-4",
    "latest_reading_date_string": time.now().format("2006-01-02T15:04:05.999999999Z07:00"),
    "trend": "Flat",
}
