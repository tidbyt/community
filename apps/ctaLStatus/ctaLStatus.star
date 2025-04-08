"""
Applet: CTA 'L' Status
Summary: CTA L Status
Description: View the latest status of CTA 'L' Trains and any alerts associated with that line.
Author: sgomez72
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# URLs for CTA Alerts and Status
CTA_STATUS_API_URL = "https://www.transitchicago.com/api/1.0/routes.aspx"
CTA_ALERTS_API_URL = "https://www.transitchicago.com/api/1.0/alerts.aspx"

# Declare Constants
DEFAULT_LINE = "red"
DEFAULT_DISPLAY = "headline"
DEFAULT_IS_ACTIVE = True
DEFAULT_IS_ACCESSIBLE = False
DEFAULT_IS_PLANNED = True
DEFAULT_IS_RECENT = True
DEFAULT_SPEED = "75"

# Cache Data for 5 mins
CACHE_TTL = 300
CACHE_KEY = "ctaL::{}::{}{}{}::{}"

# When there are no alerts, use the default alert
DEFAULT_ALERT = {
    "Alert": [
        {
            "Headline": "NO ALERT",
            "ShortDescription": "NO ALERT",
        },
    ],
}

# Options for Configuration
RAIL_LINES = [
    schema.Option(display = "Red Line (Howard to 95th/Dan Ryan via downtown subway)", value = "red"),
    schema.Option(display = "Blue Line (Forest Park to O'Hare via downtown subway)", value = "blue"),
    schema.Option(display = "Brown Line (Kimball to Loop)", value = "brn"),
    schema.Option(display = "Green Line (Harlem to Ashland/63rd and Cottage Grove via Loop)", value = "g"),
    schema.Option(display = "Orange Line (Midway to Loop)", value = "org"),
    schema.Option(display = "Purple Line (Linden to Howard local shuttle service)", value = "p"),
    schema.Option(display = "Purple Line Express (Linden to Loop express service)", value = "pexp"),
    schema.Option(display = "Pink Line (54th/Cermak to Loop)", value = "pink"),
    schema.Option(display = "Yellow Line (Howard to Skokie via Skokie Swift)", value = "y"),
]

DISPLAY_OPTIONS = [
    schema.Option(display = "Headline", value = "headline"),
    schema.Option(display = "Short Description", value = "shortDescription"),
]

SCROLL_SPEEDS = [
    schema.Option(display = "Very Fast", value = "25"),
    schema.Option(display = "Fast", value = "50"),
    schema.Option(display = "Medium", value = "75"),
    schema.Option(display = "Slow", value = "100"),
]

def main(config):
    line = config.get("line", DEFAULT_LINE)
    displayOption = config.get("display", DEFAULT_DISPLAY)
    isActive = config.bool("activeOnly", DEFAULT_IS_ACTIVE)
    isAccessibility = config.bool("accessibility", DEFAULT_IS_ACCESSIBLE)
    isPlanned = config.bool("planned", DEFAULT_IS_PLANNED)
    isRecent = config.bool("isRecent", DEFAULT_IS_RECENT)
    speed = config.get("scrollSpeed", DEFAULT_SPEED)

    ctaData = get_cta_data(line, isActive, isAccessibility, isPlanned, isRecent)

    return render.Root(
        delay = int(speed),
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    height = 16,
                    width = 64,
                    child = render.Row(
                        children = [
                            render_route_symbol(ctaData["routeColorCode"], ctaData["serviceId"]),
                            render.Box(height = 16, width = 1),
                            render.Column(
                                children = render_route_status(ctaData["route"], ctaData["routeStatus"], ctaData["routeStatusColor"]),
                            ),
                        ],
                    ),
                ),
                render.Box(width = 64, height = 1, color = "#565a5c"),
                render.Box(
                    height = 15,
                    width = 64,
                    child = render_alert_data(ctaData["alerts"], displayOption),
                ),
            ],
        ),
    )

# Render the route symbol (this is the color or symbol associated with the route)
def render_route_symbol(colorCode, serviceId):
    stripe_symbol = render.Box(
        height = 3,
        width = 18,
        color = "fff" if serviceId == "Pexp" else colorCode,
    )

    return render.Box(
        height = 16,
        width = 20,
        child = render.Box(
            height = 12,
            width = 18,
            color = colorCode,
            child = render.Column(
                children = [
                    stripe_symbol,
                    render.Box(height = 2, width = 18),
                    stripe_symbol,
                ],
            ),
        ),
    )

# Render the route status (this is the name of the route and its current status)
def render_route_status(route, routeStaus, routeStatusColor):
    # If the status is Normal, use the default orange color, else use the CTA Alert Color
    if routeStatusColor == "404040":
        statusColor = "fa0"
    elif routeStatusColor == "000000":
        statusColor = "06f"
    else:
        statusColor = routeStatusColor

    return [
        render.Box(
            height = 8,
            width = 43,
            child = render.Marquee(
                width = 43,
                offset_start = 0,
                offset_end = 0,
                child = render.Text(content = route.upper(), font = "Dina_r400-6"),
            ),
        ),
        render.Box(
            height = 8,
            width = 43,
            child = render.Marquee(
                width = 43,
                offset_start = 0,
                offset_end = 0,
                child = render.Text(content = routeStaus, font = "5x8", color = statusColor),
            ),
        ),
    ]

# Renders alerts based on the user's display perference (headlines or short descriptions)
def render_alert_data(alerts, displayOption):
    if alerts[0][displayOption] == "NO ALERT":
        return render.WrappedText(
            content = "No active alerts.",
            width = 64,
            font = "tom-thumb",
            color = "fff",
        )

    alert_content = []

    for eachAlert in alerts:
        alert_content.append(render.WrappedText(content = eachAlert[displayOption], width = 64, color = "fa0", font = "tom-thumb"))
        alert_content.append(render.Box(width = 64, height = 2))

    return render.Marquee(
        height = 15 if len(alerts) <= 2 else 32,
        width = 64,
        offset_start = 0,
        offset_end = 0,
        scroll_direction = "vertical",
        child = render.Column(
            main_align = "space_evenly",
            children = alert_content,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "line",
                name = "Rail Line",
                desc = "Select which CTA line to display the status of.",
                icon = "trainSubway",
                default = RAIL_LINES[0].value,
                options = RAIL_LINES,
            ),
            schema.Dropdown(
                id = "display",
                name = "Alert Display",
                desc = "Select which line to display the status of. Headline displays the headline of the alert. Short Description displays the short description of the alert.",
                icon = "display",
                default = DISPLAY_OPTIONS[0].value,
                options = DISPLAY_OPTIONS,
            ),
            schema.Dropdown(
                id = "scrollSpeed",
                name = "Scroll Speed",
                desc = "Select the speed at which the display scrolls through data.",
                icon = "display",
                default = SCROLL_SPEEDS[2].value,
                options = SCROLL_SPEEDS,
            ),
            schema.Toggle(
                id = "activeOnly",
                name = "Display Active Alerts",
                desc = "Display alerts where the start time is in the past and the end time is in the future or unknown.",
                icon = "info",
                default = True,
            ),
            schema.Toggle(
                id = "accessibility",
                name = "Display Accessibility Alerts",
                desc = "Display alerts that affect accesible paths in stations.",
                icon = "accessibleIcon",
                default = False,
            ),
            schema.Toggle(
                id = "planned",
                name = "Display Planned Alerts",
                desc = "Display common planned alerts.",
                icon = "calendar",
                default = True,
            ),
            schema.Toggle(
                id = "isRecent",
                name = "Display Recent Alerts",
                desc = "Display alerts that have started within the past week.",
                icon = "clock",
                default = True,
            ),
        ],
    )

def get_cta_data(line, isActive, isAccessibility, isPlanned, isRecent):
    recentDays = 7 if isRecent else 0

    # Check the cache for data
    key = CACHE_KEY.format(line, str(isActive), str(isAccessibility), str(isPlanned), str(recentDays))
    data = cache.get(key)

    if data == None:
        # No data found in cache for the key, retrieve data from CTA status and alerts API
        print("Key {} not found in cache, retrieving data from CTA Status and Alerts API...".format(key))

        # Call APIs to get data
        ctaStatus = get_data_from_cta_status_api(line)
        ctaAlerts = get_data_from_cta_alerts_api(line, isActive, isAccessibility, isPlanned, recentDays)

        # Create a dictionary of items needed for the display
        ctaInfo = {
            "route": ctaStatus["Route"],
            "serviceId": ctaStatus["ServiceId"],
            "routeColorCode": ctaStatus["RouteColorCode"],
            "routeStatus": ctaStatus["RouteStatus"],
            "routeStatusColor": ctaStatus["RouteStatusColor"],
            "alerts": ctaAlerts,
        }

        # Cache the data
        cache.set(key, json.encode(ctaInfo), CACHE_TTL)
    else:
        print("Key {} found in cache.".format(key))
        ctaInfo = json.decode(data)

    return ctaInfo

def get_data_from_cta_status_api(line):
    print("Calling CTA Status API at ", CTA_STATUS_API_URL)

    response = http.get(CTA_STATUS_API_URL, params = {
        "routeid": line,
        "outputType": "JSON",
    })
    if response.status_code != 200:
        fail("Could not retrieve alerts from CTA API. Request failed with status {}".format(response.status_code))

    return response.json()["CTARoutes"]["RouteInfo"]

def get_data_from_cta_alerts_api(line, isActive, isAccessibility, isPlanned, recentDays):
    print("Calling CTA Alerts API at ", CTA_ALERTS_API_URL)

    response = http.get(CTA_ALERTS_API_URL, params = {
        "routeid": line,
        "activeonly": str(isActive),
        "accessibility": str(isAccessibility),
        "planned": str(isPlanned),
        "recentdays": str(recentDays),
        "outputType": "JSON",
    })

    if response.status_code != 200:
        fail("Could not retrieve alerts from CTA API. Request failed with status {}".format(response.status_code))

    if response.json()["CTAAlerts"]["ErrorCode"] == "50":
        jsonData = DEFAULT_ALERT
    else:
        jsonData = response.json()["CTAAlerts"]

    # return an array of just the alert headlines and short descriptions
    alerts = []
    for eachAlert in jsonData["Alert"]:
        alertData = {
            "headline": eachAlert["Headline"].replace("’", "'").replace("/", " / "),
            "shortDescription": eachAlert["ShortDescription"].replace("’", "'").replace("/", " / "),
        }
        alerts.append(alertData)

    return alerts
