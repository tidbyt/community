"""
Applet: DetailedMETAR
Summary: Display detailed METAR
Description: Display detailed, decoded METAR information.
Author: SamuelSagarino
"""

load("cache.star", "cache")
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
    displayFailStatus = False
    failReason = None

    # API URL
    apiURL = "https://www.aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=csv&mostrecentforeachstation=constraint&hoursBeforeNow=2&stationString=%s"

    # Store cahces by airport. That way if two users are pulling the same airport's METAR it is only fetched once.
    cacheName = "metar/" + airport

    # Define cached data; if available.
    metarData_cached = cache.get(cacheName)

    # Check if cache has data.
    if metarData_cached != None:
        # If it does, set the "metarData" to be the cached data.
        metarData = metarData_cached
        print("Found cached data! Not calling NOAA API / " + cacheName)

    else:
        # If it does not, pull new data.
        print("No cached data; calling NOAA API / " + cacheName)
        rep = http.get(apiURL % airport)

        if rep.status_code != 200:
            displayFailStatus = True
            failReason = "API error"

        # Set "metarData" to be body of response.
        metarData = rep.body()

        # Set cache to be alive for 120 seconds.
        cache.set(cacheName, metarData, ttl_seconds = 120)

    # Split into individual lines for parsing.
    lines = metarData.strip().split("\n")

    itemLine = None
    infoLine = None

    # If line 4 of the result is not "1 results" display the error message.
    if lines[4] != "1 results":
        displayFailStatus = True
        failReason = "lines[4] != 1 results"

    # If the result returns more than one result; display an error message.
    if displayFailStatus == True:
        print("Fail status detected: " + failReason)
        return render.Root(
            child = render.Row(
                children = [
                    render.Box(
                        child = render.Column(
                            expanded = True,
                            children = [
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
                                                    render.Text("Error", color = "#f5737c", font = "tb-8"),
                                                ],
                                            ),
                                            width = 32,
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
                                            width = 32,
                                            height = 14,
                                            child = render.Circle(
                                                color = "#db3d5d",
                                                diameter = 12,
                                            ),
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
                                                    render.Box(
                                                        child = render.WrappedText("Could not fetch METAR data.", color = "#f5737c", font = "tb-8"),
                                                    ),
                                                ],
                                            ),
                                            width = 62,
                                            height = 17,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )

    for line in lines:
        if line.startswith("raw_text"):
            itemLine = line
        elif line.startswith(airport + " "):
            infoLine = line

    # Setup array
    decodedMetar = {}

    # Create count for when parsing sky conditions on multiple levels.
    skyCoverCount = "0"
    cloudBaseCount = "0"

    for label, value in zip(itemLine.split(","), infoLine.split(",")):
        if label == "sky_cover":
            labelName = "sky_cover" + skyCoverCount
            skyCoverCount = int(skyCoverCount) + 1
            skyCoverCount = str(skyCoverCount)

            label = labelName

        if label == "cloud_base_ft_agl":
            labelName = "cloud_base_ft_agl" + cloudBaseCount
            cloudBaseCount = int(cloudBaseCount) + 1
            cloudBaseCount = str(cloudBaseCount)
            label = labelName

        decodedMetar[label] = value

    # Add line to array with the number of cloud layers present.
    decodedMetar["layerCount"] = int(skyCoverCount) - 1

    # Get observation time.
    decodedObservationMetar = decodedMetar["observation_time"]

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
                                        child = render.Circle(
                                            color = getBackgroundColor(decodedMetar),
                                            diameter = 12,
                                        ),
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
                                                # Current wind speed.
                                                render.Box(
                                                    child = getWindSpeed(decodedMetar),
                                                    height = 6,
                                                ),
                                                # Current wind direction.
                                                render.Box(
                                                    child = getWindDirection(decodedMetar),
                                                    height = 6,
                                                ),
                                            ],
                                        ),
                                        width = 31,
                                        height = 17,
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
                                        width = 31,
                                        height = 17,
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
    stationID = decodedMetar["station_id"]
    return stationID

# Returns temperature in celsius.
def getTemperature(decodedMetar):
    result = decodedMetar["temp_c"]
    return result

# Returns dew point in celsius.
def getDewpoint(decodedMetar):
    result = decodedMetar["dewpoint_c"]
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
    layerCount = 0
    layerZero = None
    layerOne = None
    layerTwo = None
    layerThr = None

    # This function can be used to return either "cover" = sky cover or "levels" = base levels.

    if (type == "cover"):
        if (decodedMetar["sky_cover0"] != ""):
            layerCount = layerCount + 1

        if (decodedMetar["sky_cover1"] != ""):
            layerCount = layerCount + 1

        if (decodedMetar["sky_cover2"] != ""):
            layerCount = layerCount + 1

        if (decodedMetar["sky_cover3"] != ""):
            layerCount = layerCount + 1

    if (type == "levels"):
        if (decodedMetar["cloud_base_ft_agl0"] != ""):
            layerCount = layerCount + 1

        if (decodedMetar["cloud_base_ft_agl1"] != ""):
            layerCount = layerCount + 1

        if (decodedMetar["cloud_base_ft_agl2"] != ""):
            layerCount = layerCount + 1

        if (decodedMetar["cloud_base_ft_agl3"] != ""):
            layerCount = layerCount + 1

    if (type == "cover"):
        layerZero = render.Text(decodedMetar["sky_cover0"], color = getCloudCeiling_textColor(decodedMetar["cloud_base_ft_agl0"]), font = "tom-thumb")
        layerOne = render.Text(decodedMetar["sky_cover1"], color = getCloudCeiling_textColor(decodedMetar["cloud_base_ft_agl1"]), font = "tom-thumb")
        layerTwo = render.Text(decodedMetar["sky_cover2"], color = getCloudCeiling_textColor(decodedMetar["cloud_base_ft_agl2"]), font = "tom-thumb")
        layerThr = render.Text(decodedMetar["sky_cover3"], color = getCloudCeiling_textColor(decodedMetar["cloud_base_ft_agl3"]), font = "tom-thumb")

        if (decodedMetar["sky_cover0"] == "CLR"):
            layerZero = render.Text("Clear", color = getSecondaryTextColor(decodedMetar), font = "tom-thumb")

    if (type == "levels"):
        if (decodedMetar["cloud_base_ft_agl0"] != ""):
            layerZeroAGL = int(float(decodedMetar["cloud_base_ft_agl0"]))

            if (layerZeroAGL > 9999):
                layerZeroAGL = str(layerZeroAGL)[0:2] + "k"
            else:
                layerZeroAGL = str(layerZeroAGL) + "'"

            layerZero = render.Text(str(layerZeroAGL), color = getCloudCeiling_textColor(decodedMetar["cloud_base_ft_agl0"]), font = "tom-thumb")

        if (decodedMetar["cloud_base_ft_agl1"] != ""):
            layerOneAGL = int(float(decodedMetar["cloud_base_ft_agl1"]))

            if (layerOneAGL > 9999):
                layerOneAGL = str(layerOneAGL)[0:2] + "k"
            else:
                layerOneAGL = str(layerOneAGL) + "'"

            layerOne = render.Text(str(layerOneAGL), color = getCloudCeiling_textColor(decodedMetar["cloud_base_ft_agl1"]), font = "tom-thumb")

        if (decodedMetar["cloud_base_ft_agl2"] != ""):
            layerTwoAGL = int(float(decodedMetar["cloud_base_ft_agl2"]))

            if (layerTwoAGL > 9999):
                layerTwoAGL = str(layerTwoAGL)[0:2] + "k"
            else:
                layerTwoAGL = str(layerTwoAGL) + "'"

            layerTwo = render.Text(str(layerTwoAGL), color = getCloudCeiling_textColor(decodedMetar["cloud_base_ft_agl2"]), font = "tom-thumb")

        if (decodedMetar["cloud_base_ft_agl3"] != ""):
            layerThrAGL = int(float(decodedMetar["cloud_base_ft_agl3"]))

            if (layerThrAGL > 9999):
                layerThrAGL = str(layerThrAGL)[0:2] + "k"
            else:
                layerThrAGL = str(layerThrAGL) + "'"

            layerThr = render.Text(str(layerThrAGL), color = getCloudCeiling_textColor(decodedMetar["cloud_base_ft_agl3"]), font = "tom-thumb")

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
            rawOutput = output
            output.extend(extendedOutput)
            output.extend(output)
            output.extend(rawOutput)
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

    if decodedMetar["wind_speed_kt"] == "0":
        windSpeedText = "Calm"
    else:
        windSpeedText = decodedMetar["wind_speed_kt"] + "kts"

    windSpeed = int(decodedMetar["wind_speed_kt"])

    if (windSpeed >= 20):
        resultTextColor = "#f0a13a"
        if (windSpeed >= 30):
            resultTextColor = "#f5737c"

    result = render.Text(windSpeedText, color = resultTextColor, font = "tom-thumb")

    return result

# Returns wind direction in degrees
def getWindDirection(decodedMetar):
    resultTextColor = getSecondaryTextColor(decodedMetar)

    #Determine if wind speed is high. Will apply wind speed color to direction to match.
    windSpeed = int(decodedMetar["wind_speed_kt"])

    if (windSpeed >= 20):
        resultTextColor = "#f0a13a"
        if (windSpeed >= 30):
            resultTextColor = "#f5737c"

    if decodedMetar["wind_speed_kt"] == "0":
        windDirection = "Var"

        if decodedMetar["wind_dir_degrees"] == "0":
            windDirection = ""
        else:
            windDirection = decodedMetar["wind_dir_degrees"]
    else:
        windDirection = "@ " + decodedMetar["wind_dir_degrees"]

    result = render.Text(str(windDirection), color = resultTextColor, font = "tom-thumb")

    return result

# Returns current flight category.
def getFlightCategory(decodedMetar):
    if decodedMetar["flight_category"] == "VFR":
        return "VFR"
    elif decodedMetar["flight_category"] == "MVFR":
        return "MVFR"
    elif decodedMetar["flight_category"] == "IFR":
        return "IFR"
    elif decodedMetar["flight_category"] == "LIFR":
        return "LIFR"
    else:
        return "NA"

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

    if ceilingHeight == "":
        return "#8cada7"

    ceilingHeight = int(ceilingHeight)

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
