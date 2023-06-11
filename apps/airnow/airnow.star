"""
Applet: AirNowAQI
Summary: Air Now AQI
Description: Displays the current AQI value and level by location using data provided by AirNow.gov.
Author: mjc-gh
"""

load("cache.star", "cache")
load("encoding/json.star", "json")

#load("hash.star", "hash")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

API_KEY = "EAC9C956-3EDE-4955-A5BE-53492091A0DE"
ACCURACY = "#.###"

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

def get_alert_colors(category_num):
    if category_num == 1:
        return ("#009966", "#FFF")
    elif category_num == 2:
        return ("#ffde33", "#000")
    elif category_num == 3:
        return ("#ff9933", "#000")
    elif category_num == 4:
        return ("#cc0033", "#FFF")
    elif category_num == 5:
        return ("#660099", "#FFF")
    else:
        return ("#7e0023", "#FFF")

def get_current_observation_url(lat, lng):
    return "https://www.airnowapi.org/aq/forecast/latLong/?format=application/json&latitude={lat}&longitude={lng}&&API_KEY={api_key}".format(
        lat = lat,
        lng = lng,
        api_key = API_KEY,
    )

def get_current_observation(lat, lng):
    cache_key = "current_observation:{lat},{lng}".format(lat = lat, lng = lng)
    body = cache.get(cache_key)

    if body == None:
        response = http.get(url = get_current_observation_url(lat, lng))
        body = response.body()

        cache.set(cache_key, body, ttl_seconds = 1800)

    data = json.decode(body)

    for obj in data:
        if obj["ParameterName"] == "PM2.5":
            return obj

    return None

def render_alert_circle(aqi, alert_colors):
    bg_color, txt_color = alert_colors
    font = "10x20"

    if aqi > 99:
        font = "6x13"

    return render.Box(
        width = 26,
        height = 32,
        padding = 1,
        child = render.Circle(
            color = bg_color,
            diameter = 24,
            child = render.Text("%d" % (aqi), font = font, color = txt_color),
        ),
    )

def render_category_text(category_name, reporting_area, alert_colors):
    bg_color, _ = alert_colors

    if category_name == "Unhealthy for Sensitive Groups":
        category_name = "Unhealthy for Sensitive"

    return render.Box(
        width = 38,
        height = 32,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.WrappedText(
                    category_name,
                    align = "center",
                    color = bg_color,
                    font = "tom-thumb",
                ),
                render.Marquee(
                    width = 30,
                    child = render.Text(
                        reporting_area,
                        color = "#DDD",
                        font = "tom-thumb",
                    ),
                ),
            ],
        ),
    )

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))

    lat = humanize.float(ACCURACY, float(location["lat"]))
    lng = humanize.float(ACCURACY, float(location["lng"]))

    observation = get_current_observation(lat, lng)

    category_num = observation["Category"]["Number"]
    category_name = observation["Category"]["Name"]
    reporting_area = observation["ReportingArea"]
    aqi = observation["AQI"]

    alert_colors = get_alert_colors(category_num)

    return render.Root(
        child = render.Row(
            main_align = "start",
            expanded = True,
            children = [
                render_alert_circle(aqi, alert_colors),
                render_category_text(category_name, reporting_area, alert_colors),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather radar.",
                icon = "locationDot",
            ),
        ],
    )
