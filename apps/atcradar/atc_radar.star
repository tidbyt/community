"""
Applet: ATC Radar
Summary: Display local air traffic
Description: Display local air traffic.
Author: Robert Ison
"""

# Notes:
# Each initial green dot has a progress indicator next to it that flashes (unless it's heading off the screen).
# The flashing green dot indicates the direction the plane is going
# The brighter the flashing green dot, the closer to the ground
# The Yellow dot indicates YOUR location
# The Yellow dot is not always in the center, it will move to make better use of the available screen.
# You control how far to look for planes with the "Distance" selection.
# The screen will be optimized to best display the planes that are returned from the API
# The optional Information Bar:
# When displayed, you'll see some dots across the bottom of the screen. This represents the distance of the nearest plan as a percentage of the search area.
# So if your search area was 100km, and the nearest plane was 23km away, you'd see 23% of the dots lit up across the bottom of the screen.
# Also, green indicates newer data, yellow a little stale and red very stale data.
# More specifically, green will be displayed for the first third of the cache period, yellow for the second third, and red for the final third.

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = json.encode({
    "lat": "28.53985",
    "lng": "-81.38380",
    "description": "Orlando, FL, USA",
    "locality": "Orlando",
    "place_id": "???",
    "timezone": "America/New_York",
})

#Constants
TESTMODE = False  # Set to False for production -- saves calls to the API during testing
DELAY = 225  # Delay between frames (milliseconds)
N_FRAMES = int(10 * 1000 / DELAY)  # Number of frames to equate to 10 seconds based on delay
DEFAULT_DISTANCE = "10"
WHITE_COLOR = "#FFF"
GREEN_COLOR = "#1C8E61"
YELLOW_COLOR = "#FFFF00"
RED_COLOR = "#FF0000"
FLIGHT_RADAR_URL = "https://flight-radar1.p.rapidapi.com/flights/list-in-boundary"
WIDTH = 64  # Radar width

RADAR_X = 0  # x-position
RADAR_Y = 1  # y-position
RADAR_hue = 2  # hue
RADAR_LIGHTNESS = 3  # lightness
PI = 3.1415926535897932384626  # pi
SCALE = 10000  # Scale value for generating random numbers to a specific decimal place [10 -> 0.1, 100 -> 0.01, 1000 -> .001]

def deg_to_rad(num):
    return num * (math.pi / 180)

def rad_to_deg(num):
    return (180 * num) / math.pi

def get_bounding_box(centrePoint, distance):
    distance = int(distance)
    if distance < 0:
        fail("Distance must be greater than 0")

    # coordinate limits
    MIN_LAT = deg_to_rad(-90)
    MAX_LAT = deg_to_rad(90)
    MIN_LON = deg_to_rad(-180)
    MAX_LON = deg_to_rad(180)

    # earth's radius (km)
    R = 6378.1

    # angular distance in radians on a great circle
    radDist = distance / R

    # centre point coordinates (deg)
    degLat = centrePoint[0]
    degLon = centrePoint[1]

    # centre point coordinates (rad)
    radLat = deg_to_rad(degLat)
    radLon = deg_to_rad(degLon)

    # minimum and maximum latitudes for given distance
    minLat = radLat - radDist
    maxLat = radLat + radDist

    # minimum and maximum longitudes for given distance
    minLon = 0
    maxLon = 0

    # define deltaLon to help determine min and max longitudes
    deltaLon = math.asin(math.sin(radDist) / math.cos(radLat))
    if (minLat > MIN_LAT) and (maxLat < MAX_LAT):
        minLon = radLon - deltaLon
        maxLon = radLon + deltaLon
        if minLon < MIN_LON:
            minLon = minLon + 2 * math.pi
        if maxLon > MAX_LON:
            maxLon = maxLon - 2 * math.pi
    else:
        minLat = math.max(minLat, MIN_LAT)
        maxLat = math.min(maxLat, MAX_LAT)
        minLon = MIN_LON
        maxLon = MAX_LON
    return [
        str(rad_to_deg(minLat)),
        str(rad_to_deg(minLon)),
        str(rad_to_deg(maxLat)),
        str(rad_to_deg(maxLon)),
    ]

def reduce_accuracy(coord):
    coord_list = coord.split(".")
    coord_remainder = coord_list[1]
    if len(coord_remainder) > 3:
        coord_remainder = coord_remainder[0:3]
    return ".".join([coord_list[0], coord_remainder])

def update_display(text):
    return render.Row(
        children = [
            render.Box(
                child = render.Column(
                    children = text,
                ),
            ),
        ],
    )

def get_distance(lat_1, lng_1, lat_2, lng_2):
    #Haversine Formula
    lat_1 = math.radians(float(lat_1))
    lat_2 = math.radians(float(lat_2))
    lng_1 = math.radians(float(lng_1))
    lng_2 = math.radians(float(lng_2))

    d_lat = lat_2 - lat_1
    d_lng = lng_2 - lng_1

    # buildifier: disable=integer-division
    temp = (math.pow(math.sin(d_lat / 2), 2) + math.cos(lat_1) * math.cos(lat_2) * math.pow(math.sin(d_lng / 2), 2))
    distance = 3959.9986576 * (2 * math.atan2(math.sqrt(temp), math.sqrt(1 - temp)))
    return math.floor(distance)

def get_bearing(lat_1, lng_1, lat_2, lng_2):
    lat_1 = math.radians(float(lat_1))
    lat_2 = math.radians(float(lat_2))
    lng_1 = math.radians(float(lng_1))
    lng_2 = math.radians(float(lng_2))

    #Let ‘R’ be the radius of Earth,
    #‘L’ be the longitude,
    #‘θ’ be latitude,
    #‘β‘ be get_Bearing.
    #β = atan2(X,Y) where
    #X = cos θb * sin ∆L
    #Y = cos θa * sin θb – sin θa * cos θb * cos ∆L

    x = math.cos(lat_2) * math.sin((lng_2 - lng_1))
    y = math.cos(lat_1) * math.sin(lat_2) - math.sin(lat_1) * math.cos(lat_2) * math.cos((lng_2 - lng_1))
    bearing = math.degrees(math.atan2(x, y))

    # our compass brackets are broken up in 45 degree increments from 0 8
    # to find the right bracket we need degrees from 0 to 360 then divide by 45 and round
    # what we get though is degrees -180 to 0 to 180 so this will convert to 0 to 360
    if bearing < 0:
        bearing = 360 + bearing

    return bearing

def get_pixel_movement(deg):
    # have bearning in degrees, now convert pixel movements equivalent
    compass_brackets = [[0, -1], [1, -1], [1, 0], [1, 1], [0, 1], [1, -1], [-1, 0], [-1, -1], [0, -1]]
    return compass_brackets[int(math.round(deg / 45))]

def display_instructions():
    ##############################################################################################################################################################################################################################
    instructions_1 = "Get RapidAPI.com Key, click 'Apps', 'Add New App' find under 'Authorization'. Each green dot has flashing direction indicator. Brighter flashing means closer to ground. Yellow dot indicates your location."
    instructions_2 = "Information Bar: When displayed, dots across bottom represents distance of nearest plane as percentage of search area. Green line means first 3rd of Update Frequency period, yellow the middle third, red the last third."
    instructions_3 = "You can hide when the data is old, or update more or less frequently. Adjust to fit your budget and desire for current data."
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text("ATC Radar", color = "#65d0e6", font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(instructions_1, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#f4a306"),
                ),
            ],
        ),
        show_full_animation = True,
    )

def main(config):
    show_instructions = config.bool("instructions", True)
    if show_instructions:
        return display_instructions()

    api_key = config.get("key")

    if (api_key == "") or (api_key == None):
        text = [
            render.Text("Add RapidAPI"),
            render.Text("Flight Radar"),
            render.Text("Key"),
        ]
        return render.Root(
            child = update_display(text),
        )

    hide_when_nothing_to_display = config.bool("hide", True)
    hide_data_older_than_seconds = int(config.get("hideold", 600))

    location = json.decode(config.get("location", DEFAULT_LOCATION))
    cache_tty = int(config.get("cache", 60))

    orig_lat = location["lat"]
    orig_lng = location["lng"]

    lat = reduce_accuracy(orig_lat)
    lng = reduce_accuracy(orig_lng)

    search_distance = int(config.get("distance", DEFAULT_DISTANCE))

    if (config.bool("info_bar", True)):
        radar_height = 31
    else:
        radar_height = 32

    flights_cache_key = "_".join(["All", "Flight", "Data", lat, lng])
    flights = get_flights_from_cache(flights_cache_key)
    display_flights = []
    data_from_date = None

    if flights == None:
        #print("Contacting Flight Radar")
        centrePoint = [float(lat), float(lng)]
        boundingBox = get_bounding_box(centrePoint, 100)

        if TESTMODE:
            flights = [["32b96cff", "AAB100", 27.9, -88.5, 103.0, 5000.0, 552.0, "", "F-KMOB1", "B737", "N7883A", 1.69924097, "AUS", "MCO", "WN562", 0.0, 0.0, "SWA562", 0.0], ["32b96c79", "A8A4C7", 28.8316, -88.5084, 107.0, 33000.0, 535.0, "", "F-KMOB1", "B763", "N656UA", 1.699241512, "IAH", "GIG", "UA129", 0.0, 0.0, "UAL129", 0.0], ["32b9590f", "ADABFE", 28.723, -88.0323, 284.0, 30025.0, 413.0, "", "F-KMOB1", "A321", "N980JT", 1.699241512, "FLL", "SFO", "B6277", 0.0, 0.0, "JBU277", 0.0], ["32b9652c", "AD084E", 28.697, -87.9279, 284.0, 36025.0, 369.0, "", "F-KNEW1", "A20N", "N939NK", 1.699241512, "FLL", "SAT", "NK1738", 0.0, -64.0, "NKS1738", 0.0], ["32b96cff", "AAB100", 28.6329, -87.8272, 106.0, 39000.0, 550.0, "", "F-KNEW1", "B737", "N7883A", 1.699241512, "AUS", "MCO", "WN562", 0.0, 0.0, "SWA562", 0.0]]
            set_cache_flight_data(flights_cache_key, cache_tty, flights)
            data_from_date = time.now()
        else:
            rep = http.get(
                FLIGHT_RADAR_URL,
                params = {"bl_lat": boundingBox[0], "bl_lng": boundingBox[1], "tr_lat": boundingBox[2], "tr_lng": boundingBox[3], "altitude": "1000,60000"},
                headers = {"X-RapidAPI-Key": api_key, "X-RapidAPI-Host": "flight-radar1.p.rapidapi.com"},
            )

            if rep.status_code != 200:
                fail("Failed to fetch flights with status code:", rep.status_code)

            if rep.json()["aircraft"]:
                flights = rep.json()["aircraft"]
                set_cache_flight_data(flights_cache_key, cache_tty, flights)
                data_from_date = time.now()

            else:
                flights = []
    else:
        #print("Got flight data from cache")
        data_from_date = get_time_from_cache(flights_cache_key)

    # calculate the area of the map we want to display
    extremes = initialize_extremes(orig_lat, orig_lng)

    #calculate the nearest flight
    nearest_flight = 0

    if flights:
        for flight in flights:
            distance = get_distance(orig_lat, orig_lng, flight[2], flight[3])

            #update extremes with each flight we want to plot
            if distance < search_distance:
                nearest_flight = distance if nearest_flight == 0 else (distance if distance < nearest_flight else nearest_flight)
                extremes = update_extremes(flight[2], flight[3], extremes)
                display_flights.append(flight)

    if display_flights:
        #is it too old to display
        if (time.now() - data_from_date).seconds > hide_data_older_than_seconds:
            return []

        info_bar_length = int(WIDTH * min((nearest_flight / search_distance), 1))
        info_bar_color = get_stale_warning_color((time.now() - data_from_date).seconds, cache_tty)
        return get_flight_radar(display_flights, extremes, orig_lat, orig_lng, info_bar_length, info_bar_color, radar_height)
    elif hide_when_nothing_to_display == True:
        return []
    else:
        text = [
            render.Text("No Flights"),
            render.Text("Within"),
            render.Text("%s KM" % search_distance),
        ]

    return render.Root(
        child = update_display(text),
        show_full_animation = True,
    )

def get_stale_warning_color(seconds, max_seconds):
    percentage = seconds / max_seconds
    color = WHITE_COLOR
    if (percentage < .33):
        color = GREEN_COLOR
    elif (percentage < .66):
        color = YELLOW_COLOR
    else:
        color = RED_COLOR
    return color

def initialize_extremes(lat, lng):
    buffer = .1
    extremes = [-90, 90, 180, -180]
    lat = float(lat)
    lng = float(lng)
    extremes = update_extremes(lat, lng, extremes)

    # add a buffer
    extremes = update_extremes(lat + buffer, lng + buffer, extremes)
    extremes = update_extremes(lat - buffer, lng - buffer, extremes)

    return extremes

def get_flights_from_cache(key):
    cache_data = cache.get(key)
    if cache_data == None:
        return None
    else:
        cache_data = json.decode(cache_data)
        return cache_data[0]

def get_time_from_cache(key):
    cache_data = cache.get(key)
    #print("Cache_data: %s" % cache_data)

    if cache_data == None:
        return None
    else:
        cache_data = json.decode(cache_data)
        return time.from_timestamp(int(cache_data[1][0]))

def set_cache_flight_data(key, tty, flights):
    cache_data = []
    cache_data.append(flights)
    cache_data.append([time.now().unix])
    cache.set(key, json.encode(cache_data), ttl_seconds = tty)

def update_extremes(lat1, lng1, extremes):
    if (lat1 > extremes[0]):
        extremes[0] = lat1
    if (lat1 < extremes[1]):
        extremes[1] = lat1
    if (lng1 < extremes[2]):
        extremes[2] = lng1
    if (lng1 > extremes[3]):
        extremes[3] = lng1
    return extremes

def get_flight_radar(flights, extremes, home_lat, home_lng, info_bar_length, info_bar_color, radar_height):
    radar = []
    frames = []

    if len(flights) == 0:
        return []

    # Initialize variables from schema
    color = YELLOW_COLOR
    color_plane = GREEN_COLOR

    #put the house on the map
    radar.append(create_dot(radar_height, float(home_lat), float(home_lng), extremes, color, 70))

    # Create initial radar
    for flight in flights:
        radar.append(create_dot(radar_height, flight[2], flight[3], extremes, color_plane, 70))

    # Draw initial frames
    for _ in radar:
        # Draw radar into frame
        frames.append(render_frame(generate_screen(radar, radar_height)))

    # create updated radar (everyone moves one pixel based on heading)
    radar.append(create_dot(radar_height, float(home_lat), float(home_lng), extremes, color, 70))
    for flight in flights:
        adjustment = get_pixel_movement(flight[4])

        #radar.append(create_dot(flight[2], flight[3], extremes, color_plane, 70,3,3))
        radar.append(create_dot(radar_height, flight[2], flight[3], extremes, color_plane, get_brightness(flight), adjustment[0], adjustment[1]))

    # Draw frames
    for _ in radar:
        # Draw radar into frame
        frames.append(render_frame(generate_screen(radar, radar_height)))

    # Draw frames
    for _ in radar:
        # Draw radar into frame
        frames.append(render_frame(generate_screen(radar, radar_height)))

    return renderAnimation(frames, info_bar_length, info_bar_color)

def get_brightness(flight):
    #brightest for lower flights, dim for flights very high
    return max(math.floor(70 - flight[5] / 35000 * 60), 10)

def create_dot(radar_height, lng, lat, extremes, color, lightness = 35, dx = 0, dy = 0):
    hue, _, _ = hex_rgb_to_hsl(color)
    x = min(WIDTH - 1, get_coordinate(lat, extremes[2], extremes[3], WIDTH - 1) + dx)
    y = min(radar_height - 1, (radar_height - 1) - (get_coordinate(lng, extremes[0], extremes[1], radar_height - 1)) + dy)
    return [x, y, hue, lightness]

def get_coordinate(flight_coordinate, lower, upper, size):
    my_min = min(lower, upper)
    my_max = max(lower, upper)
    my_item = flight_coordinate
    answer = int(math.round(((my_item - my_min) / (my_max - my_min)) * (size)))
    return answer

def hex_rgb_to_hsl(hex_color):
    # Convert hex red, green blue values to hue, saturation, lightness values
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    hsl = rgb_to_hsl(r, g, b)
    return hsl

def hsl_to_hex_rgb(h, s, l):
    # Convert hue, saturation, lightness values to hex red, green blue values
    red, green, blue = hsl_to_rgb(h, s, l)
    return ("#" + int_to_hex(red) + int_to_hex(green) + int_to_hex(blue))

def rgb_to_hsl(r, g, b):
    # Convert red, green blue integer values to hue, saturation, lightness values
    r /= 255.0
    g /= 255.0
    b /= 255.0

    max_color = max(r, g, b)
    min_color = min(r, g, b)

    # Calculate lightness
    lightness = (max_color + min_color) / 2.0

    if max_color == min_color:
        hue = 0
        saturation = 0
    else:
        delta = max_color - min_color

        # Calculate saturation
        if lightness < 0.5:
            saturation = delta / (max_color + min_color)
        else:
            saturation = delta / (2.0 - max_color - min_color)

        # Calculate hue
        if max_color == r:
            hue = (g - b) / delta
        elif max_color == g:
            hue = (b - r) / delta + 2
        else:
            hue = (r - g) / delta + 4
        hue *= 60
        hue = hue if hue > 0 else hue + 360

    return hue, saturation, lightness

def hsl_to_rgb(h, s, l):
    # Convert hue, saturation, lightness values to integer red, green blue values
    h = h % 360
    s = max(0, min(1, s))
    l = max(0, min(1, l))

    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = l - c / 2

    if h >= 0 and h < 60:
        r, g, b = c, x, 0
    elif h >= 60 and h < 120:
        r, g, b = x, c, 0
    elif h >= 120 and h < 180:
        r, g, b = 0, c, x
    elif h >= 180 and h < 240:
        r, g, b = 0, x, c
    elif h >= 240 and h < 300:
        r, g, b = x, 0, c
    else:
        r, g, b = c, 0, x

    r = int((r + m) * 255)
    g = int((g + m) * 255)
    b = int((b + m) * 255)

    return r, g, b

def int_to_hex(value):
    # Convert integer to hex string
    d = int(value / 16)
    r = value % 16
    p1 = str(d) if d < 10 else chr(55 + d)
    p2 = str(r) if r < 10 else chr(55 + r)
    hex_string = p1 + p2
    return hex_string

def generate_screen(array, radar_height):
    arr = [["#000000" for i in range(WIDTH)] for j in range(radar_height)]
    for list in array:
        if list[RADAR_LIGHTNESS] > 0:
            arr[int(list[RADAR_Y])][int(list[RADAR_X])] = hsl_to_hex_rgb(list[RADAR_hue], 1., list[RADAR_LIGHTNESS] / 100)
    return arr

def render_frame(frame):
    return render.Stack(
        children = [
            render.Column(
                children = [render_row(row) for row in frame],
            ),
        ],
    )

def render_row(row):
    return render.Row(children = [render_cell(cell) for cell in row])

def render_cell(cell):
    return render.Box(width = 1, height = 1, color = cell)

def renderAnimation(frames, info_bar_length, info_bar_color):
    return render.Root(
        render.Column(
            children = [
                render.Animation(
                    children = frames,
                ),
                render.Box(width = info_bar_length, height = 1, color = info_bar_color),
            ],
        ),
    )

def get_schema():
    time_options = [
        schema.Option(
            display = "1 minute",
            value = "60",
        ),
        schema.Option(
            display = "2 minutes",
            value = "120",
        ),
        schema.Option(
            display = "3 minutes",
            value = "180",
        ),
        schema.Option(
            display = "4 minutes",
            value = "240",
        ),
        schema.Option(
            display = "5 minutes",
            value = "300",
        ),
        schema.Option(
            display = "10 minutes",
            value = "600",
        ),
        schema.Option(
            display = "15 minutes",
            value = "900",
        ),
        schema.Option(
            display = "20 minutes",
            value = "1200",
        ),
        schema.Option(
            display = "25 minutes",
            value = "1500",
        ),
        schema.Option(
            display = "30 minutes",
            value = "1800",
        ),
        schema.Option(
            display = "45 minutes",
            value = "2700",
        ),
        schema.Option(
            display = "1 hour",
            value = "3600",
        ),
    ]
    options_distance = [
        schema.Option(
            display = "1km",
            value = "1",
        ),
        schema.Option(
            display = "5km",
            value = "5",
        ),
        schema.Option(
            display = "10km",
            value = "10",
        ),
        schema.Option(
            display = "20km",
            value = "20",
        ),
        schema.Option(
            display = "50km",
            value = "50",
        ),
        schema.Option(
            display = "75km",
            value = "75",
        ),
        schema.Option(
            display = "100km",
            value = "100",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "RapidAPI FlightRadar Key",
                desc = "FlightRadar API key",
                icon = "key",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your Current Location",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "distance",
                name = "Distance",
                desc = "Airplane Search Radius",
                icon = "jetFighter",
                default = options_distance[1].value,
                options = options_distance,
            ),
            schema.Dropdown(
                id = "cache",
                name = "Update Frequency",
                desc = "",
                icon = "clock",
                default = time_options[4].value,
                options = time_options,
            ),
            schema.Dropdown(
                id = "hideold",
                name = "Hide when data older than:",
                desc = "",
                icon = "gear",
                default = time_options[6].value,
                options = time_options,
            ),
            schema.Toggle(
                id = "info_bar",
                name = "Information Bar",
                desc = "",
                icon = "barsStaggered",
                default = True,
            ),
            schema.Toggle(
                id = "hide",
                name = "Hide app when no flights nearby?",
                desc = "",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",  #"info",
                default = False,
            ),
        ],
    )
