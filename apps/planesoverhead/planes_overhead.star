"""
Applet: Planes Overhead
Summary: Show closest overhead plane
Description: Fetch the closest plane flying overhead from the OpenSky API and display its typecode, altitude, speed, heading, and relative position.
Author: Conor McLaughlin
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# planesoverhead
ENCRYPTED_API_KEY = "AV6+xWcEh+bIZuAShzxaiN6+d0VmDHBwKTzBRWhGzlklt96UKtoIkoMwtqC7w8oOCbbPAyBn94hirsp0TM2pQ9vzfhDM5I1BEL2wKdUs0HSwtuVLIPzcNgq/2QNc8ANvMK/DFYXM+mzi/vXTmoUmEe19B+Vxt28Jzs3qUL/+L5yYEHHp8n0/VwscJ6Z31WPNe/Z8WirghrFMQxAW"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "lat",
                name = "Latitude",
                desc = "Latitude to fetch planes overhead",
                icon = "locationDot",
                default = "32.023",
            ),
            schema.Text(
                id = "lng",
                name = "Longitude",
                desc = "Longitude to fetch planes overhead",
                icon = "locationDot",
                default = "-118.490",
            ),
            schema.Text(
                id = "radius",
                name = "Radius",
                desc = "Rough radius (miles) to search inside",
                icon = "ruler",
                default = "20",
            ),
            schema.Text(
                id = "user",
                name = "OpenSky Username",
                desc = "username of OpenSky account (optional, higher API access limits)",
                icon = "person",
            ),
            schema.Text(
                id = "pass",
                name = "OpenSky Password",
                desc = "password of OpenSky account (optional, higher API access limits)",
                icon = "lock",
            ),
            schema.Text(
                id = "dev_api_key",
                name = "(Not Required - DEV) API Key",
                desc = "for airplane db lookups",
                icon = "lock",
            ),
        ],
    )

def get_bounding_box(lat, lng, radius):
    R = 6371  # earth radius in km
    radius = radius * 1.609
    x1 = lng - math.degrees(radius / R / math.cos(math.radians(lat)))
    x2 = lng + math.degrees(radius / R / math.cos(math.radians(lat)))
    y1 = lat + math.degrees(radius / R)
    y2 = lat - math.degrees(radius / R)
    dict = {"lamin": y2, "lomin": x1, "lamax": y1, "lomax": x2}
    return dict

def get_haversine_distance(lat1, lng1, lat2, lng2):
    # Approximate radius of earth in km
    R = 6373.0

    lat1 = math.radians(lat1)
    lon1 = math.radians(lng1)
    lat2 = math.radians(lat2)
    lon2 = math.radians(lng2)

    dlon = lon2 - lon1
    dlat = lat2 - lat1

    a = math.pow(math.sin(dlat / 2), 2) + math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dlon / 2), 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    distance = R * c

    return math.round(distance * 10 / 1.609) / 10

def get_bearing(lat1, long1, lat2, long2):
    dLon = (long2 - long1)
    x = math.cos(math.radians(lat2)) * math.sin(math.radians(dLon))
    y = math.cos(math.radians(lat1)) * math.sin(math.radians(lat2)) - math.sin(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.cos(math.radians(dLon))
    brng = math.atan2(x, y)
    brng = math.degrees(brng)
    return (brng + 360) % 360

def get_heading(value):
    heading = ""

    if value == None:
        heading = "N/A"
    elif value < 11.25:
        heading = "N"
    elif value < 33.75:
        heading = "NNE"
    elif value < 56.25:
        heading = "NE"
    elif value < 78.75:
        heading = "ENE"
    elif value < 101.25:
        heading = "E"
    elif value < 123.75:
        heading = "ESE"
    elif value < 146.25:
        heading = "SE"
    elif value < 168.75:
        heading = "SSE"
    elif value < 191.25:
        heading = "S"
    elif value < 213.75:
        heading = "SSW"
    elif value < 236.25:
        heading = "SW"
    elif value < 258.75:
        heading = "WSW"
    elif value < 281.25:
        heading = "W"
    elif value < 303.75:
        heading = "WNW"
    elif value < 326.25:
        heading = "NW"
    elif value < 348.75:
        heading = "NNW"
    elif value >= 348.75:
        heading = "N"
    return heading

def get_arrow(heading):
    arrow = ""

    if (0 <= heading) and (heading < 22.5):
        arrow = "↑"
    elif (22.5 <= heading) and (heading < 67.5):
        arrow = "↗"
    elif (67.5 <= heading) and (heading < 112.5):
        arrow = "→"
    elif (112.5 <= heading) and (heading < 157.5):
        arrow = "↘"
    elif (157.5 <= heading) and (heading < 202.5):
        arrow = "↓"
    elif (202.5 <= heading) and (heading < 247.5):
        arrow = "↙"
    elif (247.5 <= heading) and (heading < 292.5):
        arrow = "←"
    elif (292.5 <= heading) and (heading < 337.5):
        arrow = "↖"
    elif (337.5 <= heading) and (heading <= 360):
        arrow = "↑"
    else:
        arrow = "·"

    return arrow

def get_typecode(icao24, api_key):
    print("Looking up ICAO24: " + icao24)

    DBOWNER = "cmcl"
    DBNAME = "aircraft.sqlite"
    URL = "https://api.dbhub.io/v1/query"

    query = """
  SELECT typecode 
  FROM aircraft 
  WHERE icao24 = '%s'
  """ % (icao24)

    query_base64 = base64.encode(query)

    params = {
        "apikey": api_key,
        "dbowner": DBOWNER,
        "dbname": DBNAME,
        "sql": query_base64,
    }

    query_post = http.post(
        url = URL,
        form_body = params,
    )

    print("Type Lookup HTTP Status:", +query_post.status_code)

    post_response = query_post.body()

    typecode = json.decode(post_response)[0][0]["Value"] if len(post_response) > 0 else ""

    return typecode

def render_error(status_code):
    screen = render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Image(src = http.get("https://cdn-icons-png.flaticon.com/256/683/683094.png").body(), height = 15),
                        render.Text(content = "     ", height = 15, offset = 1, font = "6x13", color = "#fcf7c5"),
                    ],
                ),
                render.WrappedText(content = "HTTP" + str(status_code), color = "#f7ba99"),
            ],
        ),
    )
    return screen

def process_states(state_list, your_coord):
    output = []
    if len(state_list) > 0:
        for item in state_list:
            temp = {}
            temp["icao24"] = item[0]
            temp["callsign"] = item[1].strip()
            temp["origin_country"] = item[2]
            temp["time_position"] = item[3]
            temp["last_contact"] = item[4]
            temp["lng"] = item[5]
            temp["lat"] = item[6]
            temp["dist_from_you"] = get_haversine_distance(item[6], item[5], your_coord[0], your_coord[1])
            temp["location_vs_you"] = get_heading(get_bearing(your_coord[0], your_coord[1], item[6], item[5]))
            temp["arrow"] = get_arrow(get_bearing(your_coord[0], your_coord[1], item[6], item[5]))
            temp["on_ground"] = item[8]
            temp["speed"] = None if item[9] == None else math.round(item[9] * 2.23694)
            temp["track"] = item[10]
            temp["heading"] = get_heading(item[10])
            temp["climb"] = None if item[11] == None else "ascending" if item[11] > 0.5 else "descending" if item[11] < -0.5 else "stable"
            temp["altitude"] = None if item[13] == None and item[7] == None else math.round((item[13] or item[7]) * 3.28)
            temp["category"] = None if item[17] == None else "H" if item[17] == 6 else "L" if item[17] == 5 else "M" if item[17] == 4 else "S" if item[17] == 4 else "-"
            if temp["callsign"] != None and temp["on_ground"] == False:
                output.append(temp)
        output = sorted(output, key = lambda i: i["dist_from_you"])
    return output

def render_empty():
    screen = render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Image(src = http.get("https://cdn-icons-png.flaticon.com/256/683/683094.png").body(), height = 15),
                        render.Text(content = "     ", height = 15, offset = 1, font = "6x13", color = "#fcf7c5"),
                    ],
                ),
                render.WrappedText(content = "No Planes Overhead", color = "#f7ba99"),
            ],
        ),
    )
    return screen

def render_plane(planes, api_key):
    print(planes[0])
    typecode = get_typecode(planes[0]["icao24"], api_key)
    print(typecode)
    screen = render.Root(
        render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Image(src = http.get("https://cdn-icons-png.flaticon.com/256/683/683094.png").body(), height = 15),
                        render.Text(content = " %s" % planes[0]["callsign"], height = 15, offset = 1, font = "6x13", color = "#fcf7c5"),
                    ],
                ),
                render.Text(content = "%s %s %s %s" % (typecode, planes[0]["dist_from_you"], planes[0]["arrow"], planes[0]["location_vs_you"])),
                render.Marquee(
                    child = render.Text(content = "Heading %s at %d mph, Altitude %d ft and %s" % (planes[0]["heading"], planes[0]["speed"], planes[0]["altitude"], planes[0]["climb"])),
                    scroll_direction = "horizontal",
                    offset_end = 64,
                    width = 64,
                    delay = 100,
                ),
            ],
        ),
    )
    return screen

def main(config):
    lat = float(config.str("lat", "34.023"))
    lng = float(config.str("lng", "-118.496"))
    your_coord = [lat, lng]

    username = str(config.get("user"))
    password = str(config.get("pass"))
    credentials = (username, password)

    radius = float(config.str("radius", "20"))
    bbox = get_bounding_box(lat, lng, radius)

    # for the later call to get airplane model
    airplane_db_api_key = secret.decrypt(ENCRYPTED_API_KEY) or config.get("dev_api_key")

    params = {
        "lamin": str(math.round(bbox["lamin"] / .001) * .001),
        "lomin": str(math.round(bbox["lomin"] / .001) * .001),
        "lamax": str(math.round(bbox["lamax"] / .001) * .001),
        "lomax": str(math.round(bbox["lomax"] / .001) * .001),
        "extended": "1",
    }

    api_result = http.get(
        url = "https://opensky-network.org/api/states/all",
        params = params,
        auth = credentials,
    )
    api_status_code = api_result.status_code
    api_response = api_result.json()

    # testing a non-good HTTP return code
    # api_status_code = 400

    # testing an empty states list
    # api_response["states"] = []

    if api_status_code != 200:
        return render_error(api_status_code)
    elif "states" not in api_response.keys():
        return render_empty()
    elif "states" in api_response.keys():
        state_list = [] if api_response["states"] == None or len(api_response["states"]) == 0 else api_response["states"]
        planes = process_states(state_list, your_coord)
        if len(planes) == 0:
            return render_empty()
        else:
            return render_plane(planes, airplane_db_api_key)
    else:
        return render_empty()
