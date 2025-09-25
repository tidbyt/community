"""
Applet: DetailedMETAR
Summary: Display detailed METAR
Description: Display detailed, decoded METAR information.
Author: SamuelSagarino
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_AIRPORT = "KORL"

def main(config):
    # Define schema options from the user.
    airport = config.str("airport", DEFAULT_AIRPORT)
    f_selector = config.bool("fahrenheit_temperatures", False)

    # API URL
    apiURL = "https://www.aviationweather.gov/api/data/metar?requestType=retrieve&format=json&ids=%s&mostrecentforeachstation=constraint&hoursBeforeNow=2"

    # Store cahces by airport. That way if two users are pulling the same airport's METAR it is only fetched once.
    cacheName = "metar/" + airport

    # Define cached data; if available.
    metarData_cached = cache.get(cacheName)

    # Check if cache has data.
    if metarData_cached != None:
        metarData = json.decode(metarData_cached)
        print("Cached metar data found for " + cacheName)
    else:
        print("No cached metar data found for " + cacheName)

        rep = http.get(apiURL % airport)

        if rep.status_code != 200:
            fail("API Error: Failure")

        metarData = rep.json()

        # Set cache to be alive for 120 seconds.
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cacheName, json.encode(metarData), ttl_seconds = 120)

    # Setup array
    decodedMetar = metarData[0]

    # Get observation time.
    decodedObservationMetar = decodedMetar["reportTime"]

    # Convert time to time object by parsing values from observation_time
    year = int(decodedObservationMetar[0:4])
    month = int(decodedObservationMetar[5:7])
    day = int(decodedObservationMetar[8:10])
    hour = int(decodedObservationMetar[11:13])
    minute = int(decodedObservationMetar[14:16])
    second = int(decodedObservationMetar[17:19])

    observationDate = time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "Etc/UTC")

    # Create "humanized" readout. Ex; "5 minutes ago"
    humanizedTime = humanize.time(observationDate)

    #Icon
    cacheName = getFlightCategory(decodedMetar) + "/" + str(getWindDirection_value(decodedMetar))
    cached = cache.get(cacheName)

    if cached != None:
        logo = json.decode(cached)
        logoBase64 = base64.decode(logo, encoding = "standard")
        print("Found cached image! " + cacheName)
    else:
        image = http.get("http://samuelsagarino.me/images/metar/" + getFlightCategory(decodedMetar) + "/" + str(getWindDirection_value(decodedMetar)) + ".png").body()
        print("No cached image! " + cacheName)

        logoBase64Encoded = base64.encode(image, encoding = "standard")
        logoBase64 = base64.decode(logoBase64Encoded, encoding = "standard")

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cacheName, json.encode(logoBase64Encoded), ttl_seconds = 86400)

    # Primary display
    return render.Root(
        child = render.Row(
            children = [
                render.Box(
                    child = render.Column(
                        expanded = True,
                        children = [
                            # Bottom line changes color based upon status.
                            render.Row(
                                children = [
                                    render.Box(height = 2, width = 64, color = getBackgroundColor(decodedMetar)),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                render.Text(getStationID(decodedMetar), color = getTextColor(decodedMetar), font = "tb-8"),
                                                render.Box(height = 1, color = "#1a1a1a"),
                                                wxDisplay(decodedMetar),
                                            ],
                                        ),
                                        width = 22,
                                        height = 14,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        width = 16,
                                        height = 14,
                                        #child = render.Circle(
                                        #    color = getBackgroundColor(decodedMetar),
                                        #    diameter = 12,
                                        #),
                                        child = render.Image(src = logoBase64, width = 13, height = 13),
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                # Temperature / dew point readout
                                                getTempDP(decodedMetar, f_selector),
                                                #getPresentWeather(decodedMetar),
                                                # Time of observation readout.
                                                render.Marquee(
                                                    width = 21,
                                                    child = render.Text(humanizedTime, color = "#8CADA7", font = "tom-thumb"),
                                                ),
                                            ],
                                        ),
                                        width = 22,
                                        height = 14,
                                    ),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                # Current wind speed.
                                                getWindDirection(decodedMetar),
                                                # Current wind direction.
                                                getWindSpeed(decodedMetar),
                                            ],
                                        ),
                                        width = 32,
                                        height = 16,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                # Present cloud cover layer animation.
                                                render.Box(
                                                    child =
                                                        render.Animation(
                                                            children = getCloudCover(decodedMetar, "cover"),
                                                        ),
                                                    height = 6,
                                                ),
                                                # Present ceiling animation.
                                                render.Box(
                                                    child =
                                                        render.Animation(
                                                            children = getCloudCover(decodedMetar, "levels"),
                                                        ),
                                                    height = 6,
                                                ),
                                            ],
                                        ),
                                        width = 32,
                                        height = 16,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "airport",
                name = "Airport",
                desc = "What airport to retrieve METAR from",
                icon = "planeArrival",
            ),
            schema.Toggle(
                id = "fahrenheit_temperatures",
                name = "Fahrenheit",
                desc = "Display temperatures in fahrenheit",
                icon = "thermometer",
                default = False,
            ),
        ],
    )

# Station ID; returns "KMCO", "KBOS", etc
def getStationID(decodedMetar):
    stationID = decodedMetar["icaoId"]
    return stationID

# Returns temperature in celsius.
def getTemperature(decodedMetar):
    result = decodedMetar["temp"]
    return result

# Returns dew point in celsius.
def getDewpoint(decodedMetar):
    result = decodedMetar["dewp"]
    return result

# Returns temperature / dewpoint display.
def getTempDP(decodedMetar, f_selector):
    temperature = getTemperature(decodedMetar)
    dewPoint = getDewpoint(decodedMetar)
    resultTextColor = getSecondaryTextColor(decodedMetar)

    temperature = int(float(temperature))
    dewPoint = int(float(dewPoint))

    # Determine dew point spread.
    temperature_h = temperature + 4
    temperature_l = temperature - 4

    # If dewpoint spread is +- 4 / display text orange.
    if (dewPoint >= temperature_l):
        if (temperature_h >= dewPoint):
            resultTextColor = "#f0a13a"

    if (dewPoint == temperature):
        resultTextColor = "#db3d5d"

    # If the user wants readouts in fahrenheit.
    if (f_selector == True):
        temperature = (temperature * 9 / 5) + 32
        dewPoint = (dewPoint * 9 / 5) + 32

        temperature = int(float(temperature))
        dewPoint = int(float(dewPoint))

    result = render.Text(str(temperature) + "/" + str(dewPoint), color = resultTextColor, font = "tom-thumb")

    return result

# Returns the cloud cover animation for the type designated. "Cover" or "levels".
def getCloudCover(decodedMetar, type):
    # This function returns the animation for the cloud layers.

    output = []
    layerZero = None
    layerOne = None
    layerTwo = None
    layerThr = None
    layerCount = len(decodedMetar["clouds"])

    # This function can be used to return either "cover" = sky cover or "levels" = base levels.

    if (type == "cover"):
        if (layerCount >= 1):
            layerZero = render.Text(decodedMetar["clouds"][0]["cover"], color = getCloudCeiling_textColor(decodedMetar["clouds"][0]["base"]), font = "tom-thumb")

        if (layerCount >= 2):
            layerOne = render.Text(decodedMetar["clouds"][1]["cover"], color = getCloudCeiling_textColor(decodedMetar["clouds"][1]["base"]), font = "tom-thumb")

        if (layerCount >= 3):
            layerTwo = render.Text(decodedMetar["clouds"][2]["cover"], color = getCloudCeiling_textColor(decodedMetar["clouds"][2]["base"]), font = "tom-thumb")

        if (layerCount >= 4):
            layerThr = render.Text(decodedMetar["clouds"][3]["cover"], color = getCloudCeiling_textColor(decodedMetar["clouds"][3]["base"]), font = "tom-thumb")

    if (type == "levels"):
        if (layerCount >= 1):
            if decodedMetar["clouds"][0]["base"] != None:
                layerZero = render.Text(str(int(decodedMetar["clouds"][0]["base"])), color = getCloudCeiling_textColor(decodedMetar["clouds"][0]["base"]), font = "tom-thumb")
            else:
                layerZero = None

        if (layerCount >= 2):
            layerOne = render.Text(str(int(decodedMetar["clouds"][1]["base"])), color = getCloudCeiling_textColor(decodedMetar["clouds"][1]["base"]), font = "tom-thumb")

        if (layerCount >= 3):
            layerTwo = render.Text(str(int(decodedMetar["clouds"][2]["base"])), color = getCloudCeiling_textColor(decodedMetar["clouds"][2]["base"]), font = "tom-thumb")

        if (layerCount >= 4):
            layerThr = render.Text(str(int(decodedMetar["clouds"][3]["base"])), color = getCloudCeiling_textColor(decodedMetar["clouds"][3]["base"]), font = "tom-thumb")

    if (layerCount >= 1):
        extendedOutput = [
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
            layerZero,
        ]

        output = extendedOutput

    if (layerCount >= 2):
        extendedOutput = [
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
            layerOne,
        ]

        # Fix for flicker issue that happens when you only have 2 values in the animation.
        if (layerCount == 2):
            output.extend(extendedOutput)
            output.extend(output)
        else:
            output.extend(extendedOutput)

    if (layerCount >= 3):
        extendedOutput = [
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
            layerTwo,
        ]

        output.extend(extendedOutput)

    if (layerCount >= 4):
        extendedOutput = [
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
            layerThr,
        ]

        output.extend(extendedOutput)

    return output

# Returns wind speed in knots
def getWindSpeed(decodedMetar):
    result = None
    resultTextColor = getSecondaryTextColor(decodedMetar)

    windSpeed = getWindSpeed_value(decodedMetar)

    # If wind speed is 0 return "Calm" otherwise - respond xx kts
    if windSpeed != 0:
        windSpeedText = str(windSpeed) + "kts"
    else:
        windSpeedText = "Calm"

    # Set wind gust variable
    if decodedMetar.get("wgst", None) != None:
        windGust = int(decodedMetar["wgst"])
        windSpeedText = str(windSpeed) + "-" + str(windGust) + "kts"

    # Wind speed color determinations
    if (windSpeed >= 20):
        resultTextColor = "#f0a13a"
        if (windSpeed >= 30):
            resultTextColor = "#f5737c"

    result = render.Text(windSpeedText, color = resultTextColor, font = "tom-thumb")

    return result

# Returns raw wind direction value.
def getWindSpeed_value(decodedMetar):
    return int(decodedMetar.get("wspd", 0))

# Returns wind direction in degrees
def getWindDirection(decodedMetar):
    resultTextColor = getSecondaryTextColor(decodedMetar)

    #Determine if wind speed is high. Will apply wind speed color to direction to match.
    windSpeed = int(getWindSpeed_value(decodedMetar))

    if (windSpeed >= 20):
        resultTextColor = "#f0a13a"
        if (windSpeed >= 30):
            resultTextColor = "#f5737c"

    if int(getWindDirection_value(decodedMetar)) == 0:
        windDirection = "Var @"
    else:
        windDirection = getWindDirection_value(decodedMetar) + " @"

    result = render.Text(str(windDirection), color = resultTextColor, font = "tom-thumb")

    return result

# Returns raw wind direction value.
def getWindDirection_value(decodedMetar):
    return str(int(decodedMetar.get("wdir", 0)))

# Returns current flight category.
def getFlightCategory(decodedMetar):
    visibility = None
    flightCategory = None
    cloudLayers = decodedMetar["clouds"]
    visibility = None
    cloudLayerCount = len(cloudLayers)

    if (decodedMetar["visib"] == "10+"):
        visibility = 10
    else:
        visibility = int(decodedMetar["visib"])

    baseClouds = int(12000)

    if (cloudLayerCount == 1):
        if cloudLayers[0]["cover"] == "BKN":
            baseClouds = cloudLayers[0]["base"]

        if cloudLayers[0]["cover"] == "OVC":
            baseClouds = cloudLayers[0]["base"]

    if (cloudLayerCount == 2):
        if cloudLayers[0]["cover"] == "BKN":
            baseClouds = cloudLayers[0]["base"]

        if cloudLayers[0]["cover"] == "OVC":
            baseClouds = cloudLayers[0]["base"]

        if cloudLayers[1]["cover"] == "BKN":
            baseClouds = cloudLayers[1]["base"]

        if cloudLayers[1]["cover"] == "OVC":
            baseClouds = cloudLayers[1]["base"]

    if (cloudLayerCount == 3):
        if cloudLayers[0]["cover"] == "BKN":
            baseClouds = cloudLayers[0]["base"]

        if cloudLayers[0]["cover"] == "OVC":
            baseClouds = cloudLayers[0]["base"]

        if cloudLayers[1]["cover"] == "BKN":
            baseClouds = cloudLayers[1]["base"]

        if cloudLayers[1]["cover"] == "OVC":
            baseClouds = cloudLayers[1]["base"]

        if cloudLayers[2]["cover"] == "BKN":
            baseClouds = cloudLayers[2]["base"]

        if cloudLayers[2]["cover"] == "OVC":
            baseClouds = cloudLayers[2]["base"]

    #IFR
    if baseClouds > 3000 and visibility >= 5:
        flightCategory = "VFR"

    if baseClouds <= 3000 or visibility <= 5:
        flightCategory = "MVFR"

    if baseClouds <= 1000 or visibility <= 3:
        flightCategory = "IFR"

    if baseClouds < 500 or visibility < 1:
        flightCategory = "LIFR"

    return flightCategory

# Returns primary text color based upon current flight category.
def getTextColor(decodedMetar):
    if getFlightCategory(decodedMetar) == "VFR":
        return "#87fa8b"
    elif getFlightCategory(decodedMetar) == "MVFR":
        return "#73b8f5"
    elif getFlightCategory(decodedMetar) == "IFR":
        return "#f5737c"
    elif getFlightCategory(decodedMetar) == "LIFR":
        return "#e88bf0"
    else:
        return "#f5737c"

# Returns secondary text color based upon current flight category.
def getSecondaryTextColor(decodedMetar):
    if getFlightCategory(decodedMetar) == "VFR":
        return "#8CADA7"
    elif getFlightCategory(decodedMetar) == "MVFR":
        return "#8CADA7"
    elif getFlightCategory(decodedMetar) == "IFR":
        return "#8CADA7"
    elif getFlightCategory(decodedMetar) == "LIFR":
        return "#8CADA7"
    else:
        return "#8CADA7"

# Returns current background color (shapes & lines) for current flight category.
def getBackgroundColor(decodedMetar):
    if getFlightCategory(decodedMetar) == "VFR":
        return "#62f55f"
    elif getFlightCategory(decodedMetar) == "MVFR":
        return "#8d87fa"
    elif getFlightCategory(decodedMetar) == "IFR":
        return "#db3d5d"
    elif getFlightCategory(decodedMetar) == "LIFR":
        return "#f25ce3"
    else:
        return "#f5737c"

# Returns cloud cover text color.
def getCloudCeiling_textColor(ceilingHeight):
    ceilingColor = "#8cada7"

    if ceilingHeight != None:
        ceilingHeight = int(ceilingHeight)
    else:
        ceilingHeight = 12000

    # Ceiling is less than or equal to 500
    if ceilingHeight <= 500:
        ceilingColor = "#e88bf0"

    # Ceiling is between 501 & 1000
    if ceilingHeight > 500:
        if ceilingHeight <= 999:
            ceilingColor = "#f5737c"

    # Ceiling is between 1000 & 3000
    if ceilingHeight > 999:
        if ceilingHeight <= 3001:
            ceilingColor = "#73b8f5"

    # Ceiling is above 3000
    return ceilingColor

def wxDisplay(decodedMetar):
    presentWeather = decodedMetar.get("wxString", None)

    result = "empty"
    color = getTextColor(decodedMetar)

    if presentWeather != None:
        if "BR" in presentWeather:
            result = "Mist"

        if "DU" in presentWeather:
            result = "Dust"

        if "FG" in presentWeather:
            result = "Fog"

        if "FU" in presentWeather:
            result = "Smoke"

        if "HZ" in presentWeather:
            result = "Haze"

        if "SA" in presentWeather:
            result = "Sand"

        if "VA" in presentWeather:
            result = "Volcanic Ash"

        if "DZ" in presentWeather:
            result = "Drizzle"

        if "GR" in presentWeather:
            result = "Hail"

        if "GS" in presentWeather:
            result = "Snow Pellets"

        if "IC" in presentWeather:
            result = "Ice Crystals"

        if "PL" in presentWeather:
            result = "Ice Pellets"

        if "RA" in presentWeather:
            result = "Rain"

        if "SG" in presentWeather:
            result = "Snow Grains"

        if "SN" in presentWeather:
            result = "Snow"

        if "UP" in presentWeather:
            result = "Unknown Precipitation"

        if "SH" in presentWeather:
            result = "Showers in Vicinity"

        if "TS" in presentWeather:
            result = "Thunderstorm in Vicinity"

        result = render.Marquee(width = 20, child = render.Text(result, color = color, font = "tom-thumb"))
    else:
        result = None

    return result
