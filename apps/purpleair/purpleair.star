"""
Applet: PurpleAir
Summary: Displays local air quality
Description: Displays the local air quality index from a nearby PurpleAir sensor. Choose a sensor close to you or provide a specific sensor id.
Author: posburn
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# DEFAULTS

DEFAULT_SENSOR_ID = "33997"  # Alcatraz Dock sensor
DEFAULT_LOCATION_BASED_SENSOR = '{"display": "SF Maritime NHP", "value": 70251}'
TEMP_UNIT_F = "F"
TEMP_UNIT_C = "C"
DEFAULT_TEMP_UNIT = TEMP_UNIT_F
DEFAULT_PARTICLE_SENSOR = "A and B sensors (avg)"
PARTICLE_SENSOR_A = "Sensor A"
PARTICLE_SENSOR_B = "Sensor B"

# MAIN APP

def main(config):
    api_key = secret.decrypt(API_READ_KEY) or config.get("api_key")
    sensor_id = get_sensor_id(config)
    show_title = get_cfg_value(config, "show_title", True)
    show_temp = get_cfg_value(config, "show_temp", True)
    show_name = get_cfg_value(config, "show_name", True)

    temp_unit = config.get("temp_unit")
    if temp_unit == None:
        temp_unit = DEFAULT_TEMP_UNIT

    particle_sensor = config.get("particle_sensor")
    if particle_sensor == None:
        particle_sensor = DEFAULT_PARTICLE_SENSOR

    temp = 0
    aqi = 0
    humidity = 0
    name = ""

    # Fetch the air info
    data = None
    if api_key != None:
        data = fetch_sensor_data(api_key, PUBLIC_SENSOR + sensor_id, {}, CACHE_KEY_DATA + "-" + sensor_id)  # [0] = data, [1] = was_cached

    if data == None:
        print("No data returned for sensor %s" % sensor_id)
        aqi = AQI_ERROR
        temp = 0
        humidity = 0
        name = ""

    elif len(data) != 2 or data[0] == None:
        print("Data in incorrect format or missing")

    else:
        name = data[0].get("name", "")
        temp = data[0].get("temperature", 0)
        humidity = data[0].get("humidity", 0)

        pm_a = data[0].get("pm_a", 0)
        pm_b = data[0].get("pm_b", 0)
        confidence = data[0].get("confidence", 0)
        confidenceAuto = data[0].get("confidenceAuto", -1)
        aqi = epa_AQI(pm_a, pm_b, humidity, particle_sensor, confidence, confidenceAuto)

        if data[0].get("locationType", 0) == 1:
            name = "%s\n(inside)" % name

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    width = 64,
                    height = 32,
                    color = BACKGROUND_COLOR,
                    child = render.Column(
                        children = [
                            render.Stack(
                                render_range(aqi),
                            ),
                            render.Padding(
                                pad = (2, 2, 0, 0),
                                child = render_animation(aqi, temp, humidity, name, show_title, show_temp, show_name, temp_unit),
                            ),
                        ],
                        expanded = True,
                        main_align = "space_evenly",
                    ),
                ),
            ],
        ),
    )

def get_cfg_value(config, key, default):
    value = config.get(key)
    value = json.decode(value) if value else default
    return value

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "sensor_id",
                name = "Sensors",
                desc = "Choose the sensor based on your location.",
                icon = "locationDot",
                handler = get_sensors,
            ),
            schema.Text(
                id = "sensor_id_direct",
                name = "Sensor ID (optional)",
                desc = "Specify the sensor if you know the ID",
                icon = "satelliteDish",
                default = "",
            ),
            schema.Toggle(
                id = "show_title",
                name = "Show title",
                desc = "Show AQI title",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "show_temp",
                name = "Show temp and humidity",
                desc = "Shows the temperature and humidity",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "show_name",
                name = "Show sensor name",
                desc = "Shows the name of the sensor",
                icon = "gear",
                default = True,
            ),
            schema.Dropdown(
                id = "temp_unit",
                name = "Temperature unit",
                desc = "Temperature unit",
                icon = "gear",
                default = DEFAULT_TEMP_UNIT,
                options = [
                    schema.Option(display = "Fahrenheit", value = TEMP_UNIT_F),
                    schema.Option(display = "Celsius", value = TEMP_UNIT_C),
                ],
            ),
            schema.Dropdown(
                id = "particle_sensor",
                name = "Particle sensor",
                desc = "Particle sensor(s) to use in calculation",
                icon = "gear",
                default = DEFAULT_PARTICLE_SENSOR,
                options = [
                    schema.Option(display = DEFAULT_PARTICLE_SENSOR, value = DEFAULT_PARTICLE_SENSOR),
                    schema.Option(display = PARTICLE_SENSOR_A, value = PARTICLE_SENSOR_A),
                    schema.Option(display = PARTICLE_SENSOR_B, value = PARTICLE_SENSOR_B),
                ],
            ),
        ],
    )

def get_sensors(location):
    default_options = [schema.Option(display = "Alcatraz Dock", value = DEFAULT_SENSOR_ID)]
    sensors = default_options

    if location == None or location == "":
        return sensors

    api_key = secret.decrypt(API_READ_KEY) or None
    if api_key == None:
        return sensors

    location_data = json.decode(location)
    if location_data == None:
        return sensors

    # Get latitude and longitude of location to use in the api call
    desc = location_data.get("description", None)
    latitude = float(location_data.get("lat", 0))
    longitude = float(location_data.get("lng", 0))

    # Truncate to protect the user's privacy
    latitude = float(humanize.float("#.##", latitude))
    longitude = float(humanize.float("#.##", longitude))

    # Get the sensor list constrained to a small area around this location
    delta = 0.035
    params = {
        "nwlng": str(longitude - delta),
        "nwlat": str(latitude + delta),
        "selng": str(longitude + delta),
        "selat": str(latitude - delta),
    }

    cache_key = None
    if desc != None:
        cache_key = CACHE_KEY_DATA + "-" + desc
        cache_key = cache_key.replace(" ", "")
    sensor_list = fetch_sensor_list(api_key, LIST_SENSORS, params, cache_key)

    if sensor_list == None:
        print("No data returned for sensor list")
        return sensors

    elif len(sensor_list) != 2 or sensor_list[0] == None:
        print("sensor_list in incorrect format or missing")

    else:
        sensor_data = sensor_list[0].get("data", [])
        count = len(sensor_data)
        if count > 0:
            sensors = []

        for i in range(len(sensor_data)):
            item = sensor_data[i]
            if len(item) != 5:
                continue

            # Calculate miles/km
            distance = distance_between(latitude, longitude, item[3], item[4])
            distance = int(distance * 100) / 100
            name = "(%f) %s" % (distance, item[1])

            name = name.replace("0000", "")
            value = str(item[0]).replace(".0", "")
            sensors.append(schema.Option(display = name, value = value))

        def sort_by_name(option):
            return option.display
    return sorted(sensors, key = sort_by_name)

# Use the haversine formula to calculate the distance between two points in miles
# https://www.movable-type.co.uk/scripts/latlong.html
def distance_between(lat1, lng1, lat2, lng2):
    distance = 1.0
    r = 6371e3
    la1 = lat1 * math.pi / 180
    la2 = lat2 * math.pi / 180
    delta_lat = (lat2 - lat1) * math.pi / 180
    delta_lng = (lng2 - lng1) * math.pi / 180

    a = math.pow(math.sin(delta_lat / 2), 2) + math.cos(la1) * math.cos(la2) * math.pow(math.sin(delta_lng / 2), 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    d = r * c  # d is in meters
    km = d / 1000
    miles = km / 0.621371
    return miles

# Return the sensor id to use based on configuration options
def get_sensor_id(config):
    sensor = DEFAULT_SENSOR_ID

    # User can specify the sensor id directly
    id_option = config.get("sensor_id_direct")
    if id_option != None and id_option != "":
        sensor = str(json.decode(id_option))
        print("Sensor direct: %s" % id_option)

    # If sensor not specified directly, use location to get sensor
    if id_option == None or id_option == "":
        local_selection = config.get("sensor_id", DEFAULT_LOCATION_BASED_SENSOR)
        local_selection = json.decode(local_selection)
        if "value" in local_selection:
            sensor = str(local_selection["value"])

    print("Using sensor: %s" % sensor)
    return sensor

# DATA

# Returns a tuple: (data, was_cached)
def fetch_sensor_data(api_key, url, params, cache_key):
    # Check cache first
    cached_data = None
    if cache_key != None:
        cached_data = cache.get(cache_key)

    if cached_data != None:
        # Use what's in the cache
        print("Found cached data")
        air_dict = json.decode(cached_data)
        return (air_dict, True)

    else:
        print("Cache miss")
        headers = {"X-API-Key": api_key}
        rep = http.get(url, params = params, headers = headers)
        if rep.status_code != 200:
            print("Request failed with status %d" % rep.status_code)
            return None
        else:
            data = rep.json()
            sensor = data.get("sensor", None)

            if sensor != None:
                name = sensor.get("name", "")

                temp = sensor.get("temperature", 0)
                temp = max(temp - 8, 0)  # Temp reported 8F higher so adjust

                humidity = sensor.get("humidity", 0)
                humidity = max(humidity + 4, 0)  # Humidity reported 4F lower so adjust

                pm_a = sensor.get("pm2.5_cf_1_a", 0)
                pm_b = sensor.get("pm2.5_cf_1_b", 0)
                confidence = sensor.get("confidence", 0)
                confidenceAuto = sensor.get("confidence_auto", -1)
                locationType = sensor.get("location_type", 0)

                air_dict = {
                    "name": name,
                    "temperature": temp,
                    "humidity": humidity,
                    "pm_a": pm_a,
                    "pm_b": pm_b,
                    "confidence": confidence,
                    "confidenceAuto": confidenceAuto,
                    "locationType": locationType,
                }

                air_cached = json.encode(air_dict)
                cache.set(cache_key, air_cached, ttl_seconds = 600)  # 10 minutes

            return (air_dict, False)

# Returns a tuple: (data, was_cached)
def fetch_sensor_list(api_key, url, params, cache_key):
    # Check cache first
    cached_data = None
    if cache_key != None:
        cached_data = cache.get(cache_key)

    if cached_data != None:
        # Use what's in the cache
        print("Found cached data")
        sensor_list = json.decode(cached_data)
        return (sensor_list, True)

    else:
        print("Cache miss")
        headers = {"X-API-Key": api_key}
        rep = http.get(url, params = params, headers = headers)
        if rep.status_code != 200:
            print("Request failed with status %d" % rep.status_code)
            return None
        else:
            sensors = rep.json()
            cache.set(cache_key, json.encode(sensors), ttl_seconds = 14400)  # 4 hours
            return (rep.json(), False)

# AQI & CALCULATIONS

def epa_AQI(pm25A, pm25B, humidity, particle_sensor, confidence, confidenceAuto):
    # By default, average both particle sensors
    pmValue = (pm25A + pm25B) / 2

    # If the sensor's confidence is 0 then one or both sensors isn't working. Try to
    # use the other 'good' sensor by detecting if the PM 2.5 value is out of range.
    # Note: Upper range of 1000 ug/m^3 comes from https://www.plantower.com/en/products_33/74.html
    if confidence == 0:
        if pm25A <= 0 or pm25A > 1000:
            pmValue = pm25B
        elif pm25B <= 0 or pm25B > 1000:
            pmValue = pm25A

    # If this is a device with only one sensor, the confidence_auto property will be
    # missing. In this case use the A sensor
    if confidenceAuto == -1 and pm25B == 0:
        pmValue = pm25A

    # The user can choose which sensor to use though so check that
    if particle_sensor == PARTICLE_SENSOR_A:
        pmValue = pm25A
    elif particle_sensor == PARTICLE_SENSOR_B:
        pmValue = pm25B

    # EPA adjustment for wood smoke and PurpleAir from https://cfpub.epa.gov/si/si_public_record_report.cfm?dirEntryId=349513
    # PM 2.5 corrected = 0.534*[PA_cf1(avgAB)] - 0.0844*RH +5.604 (Slide 25) - I'm using this one
    # PM 2.5 corrected = 0.52*[PA_cf1(avgAB)] - 0.085*RH +5.71 (Slide 8)
    pm25_corrected = 0.534 * pmValue - 0.0844 * humidity + 5.604

    return aqi_from_PM(pm25_corrected)

# From Jason Snell's AQI Widget and PurpleAir Google Doc
# https://github.com/jasonsnell/PurpleAir-AQI-Scriptable-Widget/blob/main/purpleair-aqi.js
def aqi_from_PM(pm):
    if pm > 350.5:
        return calculate_AQI(pm, 500.0, 401.0, 500.0, 350.5)
    elif pm > 250.5:
        return calculate_AQI(pm, 400.0, 301.0, 350.4, 250.5)
    elif pm > 150.5:
        return calculate_AQI(pm, 300.0, 201.0, 250.4, 150.5)
    elif pm > 55.5:
        return calculate_AQI(pm, 200.0, 151.0, 150.4, 55.5)
    elif pm > 35.5:
        return calculate_AQI(pm, 150.0, 101.0, 55.4, 35.5)
    elif pm > 12.1:
        return calculate_AQI(pm, 100.0, 51.0, 35.4, 12.1)
    elif pm >= 0.0:
        return calculate_AQI(pm, 50.0, 0.0, 12.0, 0.0)

    return 0

def calculate_AQI(Cp, Ih, Il, BPh, BPl):
    a = Ih - Il
    b = BPh - BPl
    c = Cp - BPl
    return math.round((a / b) * c + Il)

def aqi_index(aqi):
    index = 5
    if aqi == AQI_ERROR:
        index = AQI_ERROR
    elif aqi >= 0 and aqi <= 50:
        index = 0
    elif aqi >= 51 and aqi <= 100:
        index = 1
    elif aqi >= 101 and aqi <= 150:
        index = 2
    elif aqi >= 151 and aqi <= 200:
        index = 3
    elif aqi >= 201 and aqi <= 300:
        index = 4

    return index

def aqi_description(aqi, show_title = True):
    if show_title == False:
        return ""

    index = aqi_index(aqi)
    if index == AQI_ERROR:
        return "Select a PurpleAir sensor"
    return AQI_TITLE[index]

def aqi_color(aqi):
    index = aqi_index(aqi)
    if index == AQI_ERROR:
        return AQI_COLOR[0]
    return AQI_COLOR[aqi_index(aqi)]

def aqi_text_color(aqi):
    return AQI_TEXT_COLOR[aqi_index(aqi)]

# UI

rate = 100

# Calculates the number of frames required based on the duration and rate
def duration(seconds):
    return int((seconds * 1000) // rate)

# Adds the required number of frames based on the duration
def frames(f, child, duration):
    for _ in range(duration):
        f.append(child)

    return f

def decToHex(dec):
    hex = "#000"
    if dec < 16:
        hex = str("#00%x" % dec)
    elif dec < 256:
        hex = str("#0%x" % dec)
    else:
        hex = str("#%x" % dec)

    return hex

def decreasing_color(color = "FFFFFFFF", step = 4):
    clr = color.replace("#", "")
    dec = int(clr, 16)
    dec = max(0, dec - step)
    return decToHex(dec)

def display_aqi(aqi):
    index = aqi_index(aqi)
    if index == AQI_ERROR:
        return "AQI"
    return ("%s" % aqi).replace(".0", "")

def display_temp(temp, temp_unit = DEFAULT_TEMP_UNIT):
    if temp_unit == TEMP_UNIT_C:
        temp = int((temp - 32) * 0.5555555559)
    return ("%s°%s" % (temp, temp_unit)).replace(".0", "")

def display_humidity(humidity):
    return ("%s%%" % humidity).replace(".0", "")

def render_aqi_text(aqi):
    font = "tb-8"
    if aqi_index(aqi) == 1:
        return render.Text(
            display_aqi(aqi),
            font = font,
            color = "#000",
        )
    else:
        return render.Stack(children = [
            render.Padding(
                pad = (0, 0, 0, 1),
                child = render.Text(
                    display_aqi(aqi),
                    font = font,
                    color = "#000",
                ),
            ),
            render.Padding(
                pad = (0, -1, 0, 1),
                child = render.Text(
                    display_aqi(aqi),
                    font = font,
                    color = "#fff",
                ),
            ),
        ])

def render_range(aqi):
    if aqi == AQI_ERROR:
        aqi = 0

    # width / max_aqi, 64 / 301 -> 0.21262
    arrow_pad = min(63, max(0, int(0.21262 * aqi)))
    return [
        render.Image(RANGE),
        render.Padding(pad = (arrow_pad, 0, 0, 0), child = render.Box(width = 1, height = 4, color = "#fff")),
    ]

def render_simple_view(aqi, alternate_text = "", text_color = "#FFFFFFFF", offset = 50, show_title = True):
    return render.Box(
        child = render.Stack(
            children = [
                render.Circle(
                    diameter = 22,
                    color = aqi_color(aqi),
                    child =
                        render.Box(child = render_aqi_text(aqi)),
                ),
                render.Padding(
                    pad = (24, -1, 0, 0),
                    child =
                        render.Stack(
                            children = [
                                render.Box(
                                    width = 38,
                                    height = 25,
                                    child =
                                        render.WrappedText(
                                            content = aqi_description(aqi, show_title),
                                            color = text_color,
                                            font = "tom-thumb",
                                        ),
                                ),
                                render.Padding(
                                    pad = (offset, 0, 0, 0),
                                    child =
                                        render.Box(
                                            width = 38,
                                            height = 25,
                                            child =
                                                render.WrappedText(
                                                    content = alternate_text,
                                                    font = "tom-thumb",
                                                ),
                                        ),
                                ),
                            ],
                        ),
                ),
            ],
        ),
    )

def render_animation(aqi, temp, humidity, name, show_title = True, show_temp = True, show_name = True, temp_unit = DEFAULT_TEMP_UNIT):
    fr = []

    if show_title == False and show_temp == False and show_name == False:
        fr = frames(fr, render_simple_view(aqi, text_color = BACKGROUND_COLOR), duration(10))
        return render.Animation(fr)

    if aqi_index(aqi) == AQI_ERROR:
        return render_simple_view(aqi)

    # Show aqi and the title first and delay
    temp_hum = display_temp(temp, temp_unit) + " " + display_humidity(humidity)
    if show_title == True:
        fr = frames(fr, render_simple_view(aqi), duration(5))

        if show_temp == True:
            # Next, fade out the title and bring in the temp and humidity
            start = duration(2)
            step = 255 // start
            step_offset = math.ceil(50 // start)
            for i in range(start):
                fr = frames(
                    fr,
                    render_simple_view(
                        aqi,
                        alternate_text = temp_hum,
                        text_color = decreasing_color("FFFFFFFF", step = step * i),
                        offset = max(0, 35 - step_offset * i),
                    ),
                    1,
                )

    # Show the temp/humidity and delay
    if show_temp == True:
        fr = frames(
            fr,
            render_simple_view(
                aqi,
                alternate_text = temp_hum,
                text_color = "#00000000",
                offset = 0,
            ),
            duration(5),
        )

    if show_name == False:
        return render.Animation(fr)

    # Show the name
    if show_title == True or show_temp == True:
        # Next, fade out the title and bring in the temp and humidity
        start = duration(2)
        step = 255 // start
        step_offset = math.ceil(50 // start)
        for i in range(start):
            fr = frames(
                fr,
                render_simple_view(
                    aqi,
                    alternate_text = name,
                    text_color = BACKGROUND_COLOR,
                    offset = max(0, 35 - step_offset * i),
                ),
                1,
            )

    fr = frames(
        fr,
        render_simple_view(
            aqi,
            alternate_text = name,
            text_color = "#00000000",
            offset = 0,
        ),
        duration(5),
    )

    return render.Animation(fr)

# CONSTANTS

API_READ_KEY = "AV6+xWcE7hO0GOSye3S6fLtTsKex797gyaIfLQKc3t1oXawbQBTEVHciWK3ITe3um3dBzxDNau5bI3iNhYicAm3FFRWAj0hVL/nKmGrvphhvjzxbjynWIy2+g6IkGZw43GMf2wjIEnHcmuGVMicd779uABXs56OhMof9LFfiq7iuJ9e2PhN+h8x2"
PUBLIC_SENSOR = "https://api.purpleair.com/v1/sensors/"
LIST_SENSORS = "https://api.purpleair.com/v1/sensors?fields=name,location_type,latitude,longitude"
CACHE_KEY_DATA = "purpleAirData"
BACKGROUND_COLOR = "#21024D"

# Images
RANGE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEAAAAADCAYAAAAjpQkcAAAABHNCSVQICAgIfAhkiAAAAQ5JREFUKFONkm1ShDAQRHsS2I+r6bX0HHrMJYHENyGwYmHpj1SnZygq3fXs7eOl3segazTdhjPVc853oyTLUklFylV16tp9+eHbfjZVjkpYdemKLzP/wxfm1vy6zzUo2aiHuDeNymHQo0bmgyYNSvjJvSt7W4osZYV55o1ZcV7+9u+fr/UY3tYyCHtDrxEdnuVcAmE8bCI8Wr2E3VdKYcZu3/t3hNRCsJngqJ+9BC/j4Nd9JqCHSq72LXQLv/nIjiLwEyWJ4CFzunoJ293nmzfusXvbCLgQ9v4rAZEiVhIuvJ3XQcDS9IwAo5QDIacE8J8STwlwIlInYAvbCCDsSgJE+B7dCYCERkAP/V8CvgB8qhUiAN3IHAAAAABJRU5ErkJggg==")

# AQI
AQI_TITLE = ["Good", "Moderate", "Unhealthy for SG", "Unhealthy", "Very Unhealthy", "Hazardous"]
AQI_COLOR = ["#819E4A", "#DECA5B", "#D68149", "#CF575B", "#7A5E8A", "#911F51"]
AQI_TEXT_COLOR = ["#FFFFFF", "#000000", "#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF"]
AQI_ERROR = -1
