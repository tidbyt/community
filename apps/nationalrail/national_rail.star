"""
Applet: National Rail
Summary: Live UK train departures
Description: Realtime departure board information from National Rail Enquiries.
Author: dinosaursrarr
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("xpath.star", "xpath")

# Used to query Darwin to get live train information.
# Allows 5000 requests per hour (~1.38 qps) for free. Can buy more if needed.
ENCRYPTED_DARWIN_APP_KEY = "AV6+xWcEpjb3YSvq0m3DedNFUrniZqd3qLkIUYz5+HhnX5/bJa681u67XiPHyzH0uBBMcNXh7LJGYtRIcJLKAwWByZ3VOL0VP5jRhX4KY4aq1/sMwKr7X+VokgXMYE2Ci6gqAGdd9xWPejcnVa9F3lIpwRIutikv0TVmY0PJXCqQejyYiEHwozEl"
DARWIN_SOAP_URL = "https://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb9.asmx"

# Used to query KnowledgeBase to get static information about stations.
ENCRYPTED_KNOWLEDGE_BASE_USERNAME = "AV6+xWcEITId2BBWFxznz5VvqMYyVPKnplrKpwm0+5g1Y5sOK5cpb4H3UQsGnmdK04arbBRitSg9Qvu6PnlVc3MS2Fr7c4aqp2E2e96TMF/w6qA+Yg3X5BmwzrGP4nYc0Y0xoLHLMq4+y6dpI8VGAssh4GVvumKtLrO/9Ivlbw=="
ENCRYPTED_KNOWLEDGE_BASE_PASSWORD = "AV6+xWcEGkM04GW0i2uEq8M+9j4Yq79Nm/tiB/ZBgs2rA53OAJpZE0PKP8Yess0y2TXz3klJUEIdYYAdKIlnMlF1Q8TOf1ifuhK2q743JsT65bHwouBMoRTRGoUqEYqKAUAgPuKwsSBXDXF1sDzKHMmG+tDp76aH/I8="
KNOWLEDGE_BASE_AUTHENTICATE_URL = "https://opendata.nationalrail.co.uk/authenticate"
STATION_FEED_URL = "https://opendata.nationalrail.co.uk/api/staticfeeds/4.0/stations"

# Filters for trains that call at a given station, if selected. This is an excerpt
# to be added into a request XML.
DEPARTURES_FILTER = """
         <ldb:filterCrs>%s</ldb:filterCrs>
         <ldb:filterType>to</ldb:filterType>
"""

# Basic request. I know with SOAP you're meant to generate code based on a description
# file, but it's hideous and there don't seem to be any solutions for starlark, and the
# options for golang are poor too. So, just hook this together because we're only ever
# asking for something simple.
DEPARTURES_REQUEST = """
<soap:Envelope
    xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
    xmlns:typ="http://thalesgroup.com/RTTI/2013-11-28/Token/types"
    xmlns:ldb="http://thalesgroup.com/RTTI/2016-02-16/ldb/">
   <soap:Header>
      <typ:AccessToken>
         <typ:TokenValue>%s</typ:TokenValue>
      </typ:AccessToken>
   </soap:Header>
   <soap:Body>
      <ldb:GetDepBoardWithDetailsRequest>
         <ldb:numRows>%s</ldb:numRows>
         <ldb:crs>%s</ldb:crs>%s
      </ldb:GetDepBoardWithDetailsRequest>
   </soap:Body>
</soap:Envelope>
"""

EMPTY_DATA_IN_CACHE = ""
NO_DESTINATION = "-"
ORIGIN_STATION = "origin_station"
DESTINATION_STATION = "destination_station"
DISPLAY_MODE = "display_mode"
DISPLAY_DETAILED = "display_detailed"
DISPLAY_COMPACT = "display_compact"

BLUE = "#1c355e"
RED = "#d3212c"
GREEN = "#69b34c"
GRAY = "#999"
ORANGE = "#ffa500"
FONT = "tom-thumb"
INFO_TOGGLE_FRAMES = 50

def darwin_app_key():
    return secret.decrypt(ENCRYPTED_DARWIN_APP_KEY)

def knowledge_base_username():
    return secret.decrypt(ENCRYPTED_KNOWLEDGE_BASE_USERNAME)

def knowledge_base_password():
    return secret.decrypt(ENCRYPTED_KNOWLEDGE_BASE_PASSWORD)

def fetch_knowledge_base_authentication_token():
    cached = cache.get(KNOWLEDGE_BASE_AUTHENTICATE_URL)
    if cached == EMPTY_DATA_IN_CACHE:
        return None
    if cached:
        return cached

    username = knowledge_base_username()
    if not username:
        return None
    password = knowledge_base_password()
    if not password:
        return None
    resp = http.post(
        url = KNOWLEDGE_BASE_AUTHENTICATE_URL,
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
        },
        form_body = {
            "username": username,
            "password": password,
        },
    )
    if resp.status_code != 200:
        cache.set(KNOWLEDGE_BASE_AUTHENTICATE_URL, EMPTY_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    if "token" not in resp.json():
        cache.set(KNOWLEDGE_BASE_AUTHENTICATE_URL, EMPTY_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    token = resp.json()["token"]
    cache.set(KNOWLEDGE_BASE_AUTHENTICATE_URL, token, ttl_seconds = 3540)  # Valid for 1h
    return token

def extract_stations(station_feed):
    feed = xpath.loads(station_feed)
    station_count = len(feed.query_all("/StationList/Station"))

    stations = {}
    for i in range(station_count):
        station = {}
        station["crs"] = feed.query("/StationList/Station[%s]/CrsCode" % (i + 1))

        # Ignore second CRS code for international facilities as they aren't used by Darwin.
        # https://wiki.openraildata.com/KnowledgeBase#Stations
        if station["crs"] in ["SPX", "ASI"]:
            continue

        station["name"] = feed.query("/StationList/Station[%s]/Name" % (i + 1))
        station["sixteen_char_name"] = feed.query("/StationList/Station[%s]/SixteenCharacterName" % (i + 1)).title()
        station["lat"] = feed.query("/StationList/Station[%s]/Latitude" % (i + 1))
        station["lng"] = feed.query("/StationList/Station[%s]/Longitude" % (i + 1))
        stations[station["crs"]] = station

    return stations

def fetch_stations():
    auth_token = fetch_knowledge_base_authentication_token()
    if not auth_token:
        return None
    cached = cache.get(STATION_FEED_URL)
    if cached == EMPTY_DATA_IN_CACHE:
        return None
    if cached:
        return json.decode(cached)

    resp = http.get(
        url = STATION_FEED_URL,
        headers = {
            "X-Auth-Token": auth_token,
        },
    )
    if resp.status_code != 200:
        cache.set(STATION_FEED_URL, EMPTY_DATA_IN_CACHE, ttl_seconds = 30)
        return None

    stations = extract_stations(resp.body())
    cache.set(STATION_FEED_URL, json.encode(stations), ttl_seconds = 86400)  # Stations don't move often
    return stations

def fetch_departures(station, via, display_mode):
    if len(via) > 0:
        filter = DEPARTURES_FILTER % via
    else:
        filter = ""

    if display_mode == DISPLAY_DETAILED:
        num_rows = 2
    elif display_mode == DISPLAY_COMPACT:
        num_rows = 4
    else:
        fail("Invalid config option for " + DISPLAY_MODE)

    app_key = darwin_app_key()
    if not app_key:
        return None
    request = DEPARTURES_REQUEST % (app_key, num_rows, station, filter)

    cached = cache.get(request)
    if cached == EMPTY_DATA_IN_CACHE:
        return None
    if cached:
        return cached

    resp = http.post(
        url = DARWIN_SOAP_URL,
        body = request,
        headers = {
            "Content-Type": "application/soap+xml; charset=utf-8",
        },
    )
    if resp.status_code != 200:
        cache.set(request, EMPTY_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    cache.set(request, resp.body(), ttl_seconds = 60)
    return resp.body()

def render_error(error):
    return render.Root(
        child = render.Column(
            main_align = "center",
            expanded = True,
            children = [
                render.WrappedText(
                    content = error,
                    width = 64,
                    align = "center",
                    color = ORANGE,
                ),
            ],
        ),
    )

def render_title(name):
    return render.Box(
        width = 64,
        height = 7,
        color = BLUE,
        child = render.Padding(
            pad = (1, 1, 1, 0),
            child = render.Marquee(
                width = 62,
                align = "center",
                child = render.WrappedText(
                    content = name,
                    height = 6,
                    align = "center",
                    font = FONT,
                ),
            ),
        ),
    )

def render_separator():
    return render.Box(height = 1)

def render_times(scheduled, expected):
    if expected == "On time":
        expected_colour = GREEN
    else:
        expected_colour = RED

    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.WrappedText(
                content = scheduled,
                width = 20,
                height = 6,
                font = FONT,
            ),
            render.WrappedText(
                align = "right",
                content = expected,
                width = 40,
                height = 6,
                font = FONT,
                color = expected_colour,
            ),
        ],
    )

def render_destination(destination):
    return render.WrappedText(
        content = destination,
        font = FONT,
        width = 62,
        height = 6,
        align = "left",
    )

def render_no_departures():
    return render.Column(
        expanded = True,
        main_align = "space_around",
        children = [
            render.WrappedText(
                content = "No departures",
                font = FONT,
                width = 62,
                height = 6,
                align = "center",
                color = GRAY,
            ),
        ],
    )

def render_detailed_train(scheduled, expected, operator, destination, length, platform, calling_at):
    messages = []
    if operator:
        messages.append("%s service" % operator)
    else:
        messages.append("Service")
    if destination:
        messages.append("to %s" % destination["name"])
    if length:
        messages.append("with %s carriages" % length)
    if platform:
        messages.append("on platform %s" % platform)
    messages.append("calling at " + " and ".join(", ".join(calling_at).rsplit(", ", 1)))
    message = " ".join(messages)
    # message = "Platform %s to %s" % (platform, calling)

    return render.Box(
        width = 62,
        height = 12,
        child = render.Column(
            children = [
                render.Animation(
                    children = [render_times(scheduled, expected)] * INFO_TOGGLE_FRAMES +
                               [render_destination(destination["sixteen_char_name"])] * INFO_TOGGLE_FRAMES,
                ),
                render.Marquee(
                    width = 62,
                    height = 6,
                    child = render.Text(
                        content = message,
                        font = FONT,
                        color = GRAY,
                    ),
                ),
            ],
        ),
    )

def render_compact_train(scheduled, expected, destination):
    return render.Box(
        width = 62,
        height = 6,
        child = render.Animation(
            children = [render_times(scheduled, expected)] * INFO_TOGGLE_FRAMES +
                       [render_destination(destination["sixteen_char_name"])] * INFO_TOGGLE_FRAMES,
        ),
    )

def render_train(departures, stations, index, display_mode):
    scheduled = departures.query("//lt5:trainServices/lt5:service[%s]/lt4:std" % index)
    expected = departures.query("//lt5:trainServices/lt5:service[%s]/lt4:etd" % index)
    destination_crs = departures.query("//lt5:trainServices/lt5:service[%s]/lt5:destination/lt4:location/lt4:crs" % index)
    destination = stations[destination_crs]

    if display_mode == DISPLAY_DETAILED:
        platform = departures.query("//lt5:trainServices/lt5:service[%s]/lt4:platform" % index)
        operator = departures.query("//lt5:trainServices/lt5:service[%s]/lt4:operator" % index)
        length = departures.query("//lt5:trainServices/lt5:service[%s]/lt4:length" % index)
        calling_at = departures.query_all("//lt5:trainServices/lt5:service[%s]//lt4:callingPoint/lt4:locationName" % index)
        return render_detailed_train(scheduled, expected, operator, destination, length, platform, calling_at)

    if display_mode == DISPLAY_COMPACT:
        return render_compact_train(scheduled, expected, destination)

    fail("Invalid display mode: %s" % display_mode)

def main(config):
    stations = fetch_stations()  # Cached, so can call here and get_schema cheaply.
    if not stations:
        return render_error("Station list not available")

    origin_option = config.get(ORIGIN_STATION) or NO_DESTINATION
    if origin_option == NO_DESTINATION:
        return render_error("Station list not available")
    if not origin_option:
        origin_station = stations["KGX"]  # default to London King's Cross
    else:
        origin_station = json.decode(origin_option)

    destination_option = config.get(DESTINATION_STATION)
    if destination_option and destination_option != NO_DESTINATION:
        filter_crs = json.decode(destination_option)["crs"]
    else:
        filter_crs = ""

    display_mode = config.get(DISPLAY_MODE) or DISPLAY_DETAILED

    resp = fetch_departures(origin_station["crs"], filter_crs, display_mode)
    if not resp:
        return render_error("Train times not available")
    departures = xpath.loads(resp)
    trains = departures.query_all("//lt5:trainServices/lt5:service")
    if len(trains) == 0:
        rendered_trains = [render_no_departures()]
    else:
        rendered_trains = [render_train(departures, stations, t + 1, display_mode) for t in range(len(trains))]

    return render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render_title(origin_station["sixteen_char_name"]),
                render_separator(),
            ] + rendered_trains,
        ),
    )

def get_schema():
    no_destination_option = schema.Option(
        display = NO_DESTINATION,
        value = NO_DESTINATION,
    )

    stations = fetch_stations()
    if not stations:
        default_station = NO_DESTINATION
        station_options = [no_destination_option]
    else:
        station_options = [
            schema.Option(
                display = station["name"],
                value = json.encode(station),
            )
            for station in sorted(stations.values(), key = lambda s: s["name"])
        ]
        default_station = station_options[0].value

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = ORIGIN_STATION,
                name = "Origin",
                desc = "Station to look up departure times for",
                icon = "train",
                default = default_station,
                options = station_options,
            ),
            schema.Dropdown(
                id = DESTINATION_STATION,
                name = "Destination",
                desc = "Only show trains going to this station (optional)",
                icon = "train",
                default = NO_DESTINATION,
                options = [no_destination_option] + station_options,
            ),
            schema.Dropdown(
                id = DISPLAY_MODE,
                name = "Display mode",
                desc = "Controls whether to show more trains or more details about each train",
                icon = "display",
                default = DISPLAY_DETAILED,
                options = [
                    schema.Option(
                        display = "Detailed",
                        value = DISPLAY_DETAILED,
                    ),
                    schema.Option(
                        display = "Compact",
                        value = DISPLAY_COMPACT,
                    ),
                ],
            ),
        ],
    )
