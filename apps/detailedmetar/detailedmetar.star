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

DEFAULT_AIRPORT = "KBOS"

def main(config):
    airport = config.str("airport", DEFAULT_AIRPORT)
    f_selector=config.bool("fahrenheit_temperatures", False)

    apiURL = "https://www.aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=csv&mostrecentforeachstation=constraint&hoursBeforeNow=2&stationString=%s"

    cacheName = "metar/" + airport

    metarData_cached = cache.get(cacheName)

    if metarData_cached != None:
        metarData = metarData_cached
        print("Found cached data! Not calling NOAA API / " + cacheName)
    else:
        print("No cached data; calling NOAA API / " + cacheName)
        rep = http.get(apiURL % airport)

        if rep.status_code != 200:
            fail("FA API failed with status %d", rep.status_code)

        metarData = rep.body()
        cache.set(cacheName, metarData, ttl_seconds = 120)

    lines = metarData.strip().split("\n")

    itemLine = None
    infoLine = None

    if lines[4] != "1 results":
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

    decodedMetar = {}

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

    decodedObservationMetar = decodedMetar["observation_time"]

    decodedMetar["layerCount"] = int(skyCoverCount) - 1

    year = int(decodedObservationMetar[0:4])
    month = int(decodedObservationMetar[5:7])
    day = int(decodedObservationMetar[8:10])
    hour = int(decodedObservationMetar[11:13])
    minute = int(decodedObservationMetar[14:16])
    second = int(decodedObservationMetar[17:19])

    observationDate = time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "Etc/UTC")

    humanizedTime = humanize.time(observationDate)

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
                                                render.Text(getStationID(decodedMetar), color = getTextColor(decodedMetar), font = "5x8"),
                                                #render.Text(getFlightCategory(decodedMetar), color = getTextColor(decodedMetar), font = "CG-pixel-3x5-mono"),
                                                #render.Marquee(
                                                #    width = 21,
                                                #    child = render.Text(humanizedTime, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                #),
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
                                            color = getTextColor(decodedMetar),
                                            diameter = 12,
                                        ),
                                        #child = render.PieChart(
                                        #    colors = getWindDiagram(decodedMetar),
                                        #    weights = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, #10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
                                        #    diameter = 13,
                                        #),
                                        #child = render.Image(
                                        #    src=image(),
                                        #    rotation=45
                                        #)
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
                                                render.Text(getTempDP(decodedMetar, f_selector), color = getTextColor(decodedMetar), font = "CG-pixel-3x5-mono"),
                                                render.Marquee(
                                                    width = 21,
                                                    child = render.Text(humanizedTime, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
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
                                                render.Box(
                                                    child = render.Text(getWindSpeed(decodedMetar), color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono"),
                                                    height = 5,
                                                ),
                                                render.Box(
                                                    child = render.Text(getWindDirection(decodedMetar), color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono"),
                                                    height = 5,
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
                                                render.Box(
                                                    child =
                                                        render.Animation(
                                                            children = getCloudCover(decodedMetar, "cover"),
                                                        ),
                                                    height = 5,
                                                ),
                                                render.Box(
                                                    child =
                                                        render.Animation(
                                                            children = getCloudCover(decodedMetar, "levels"),
                                                        ),
                                                    height = 5,
                                                ),
                                            ],
                                        ),
                                        width = 31,
                                        height = 17,
                                    ),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Box(height = 1, width = 64, color = getTextColor(decodedMetar)),
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
            )
        ],
    )

def getStationID(decodedMetar):
    stationID = decodedMetar["station_id"]
    return stationID

def getTemperature(decodedMetar):
    result = decodedMetar["temp_c"]
    return result

def getDewpoint(decodedMetar):
    result = decodedMetar["dewpoint_c"]
    return result

def getTempDP(decodedMetar, f_selector):
    temperature = getTemperature(decodedMetar)
    dewPoint = getDewpoint(decodedMetar)

    #temperature = temperature[0:2]
    #dewPoint = dewPoint[0:2]

    temperature = int(float(temperature))
    dewPoint = int(float(dewPoint))

    if(f_selector == True):
        temperature = (temperature * 9/5) + 32
        dewPoint = (dewPoint * 9/5) + 32

        temperature = int(float(temperature))
        dewPoint = int(float(dewPoint))

    result = str(temperature) + "/" + str(dewPoint)

    return result

def getSkyCover(decodedMetar):
    skyCover = decodedMetar["sky_cover0"]
    return skyCover

def getCloudBaseLevel(decodedMetar):
    if (decodedMetar["cloud_base_ft_agl0"] == ""):
        baseLevel = ""
    else:
        baseLevel = decodedMetar["cloud_base_ft_agl0"] + "ft"

    return baseLevel

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
        layerZero = render.Text(decodedMetar["sky_cover0"], color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")
        layerOne = render.Text(decodedMetar["sky_cover1"], color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")
        layerTwo = render.Text(decodedMetar["sky_cover2"], color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")
        layerThr = render.Text(decodedMetar["sky_cover3"], color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")

        if(decodedMetar["sky_cover0"] == "CLR"):
            layerZero = render.Text("Clear", color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")

    if (type == "levels"):
        layerZero = render.Text(decodedMetar["cloud_base_ft_agl0"] + "'", color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")
        layerOne = render.Text(decodedMetar["cloud_base_ft_agl1"] + "'", color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")
        layerTwo = render.Text(decodedMetar["cloud_base_ft_agl2"] + "'", color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")
        layerThr = render.Text(decodedMetar["cloud_base_ft_agl3"] + "'", color = getSecondaryTextColor(decodedMetar), font = "CG-pixel-3x5-mono")

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
        if(layerCount == 2):
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

def getWindSpeed(decodedMetar):
    if decodedMetar["wind_speed_kt"] == "0":
        windSpeed = "Calm"
    else:
        windSpeed = decodedMetar["wind_speed_kt"] + "kts"

    return windSpeed

def getWindDirection(decodedMetar):
    if decodedMetar["wind_speed_kt"] == "0":
        windDirection = "Var"

        if decodedMetar["wind_dir_degrees"] == "0":
            windDirection = ""
        else:
            windDirection = decodedMetar["wind_dir_degrees"]
    else:
        windDirection = "@ " + decodedMetar["wind_dir_degrees"]

    return windDirection

def getAltimeterSetting(decodedMetar):
    alt = decodedMetar["altim_in_hg"][0:5]

    return alt

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

def getTextColor(decodedMetar):
    if decodedMetar["flight_category"] == "VFR":
        return "#87fa8b"
    elif decodedMetar["flight_category"] == "MVFR":
        return "#8d87fa"
    elif decodedMetar["flight_category"] == "IFR":
        return "#f5737c"
    elif decodedMetar["flight_category"] == "LIFR":
        return "#e88bf0"
    else:
        return "#f5737c"

def getSecondaryTextColor(decodedMetar):
    if decodedMetar["flight_category"] == "VFR":
        #return "#adffad"
        return "#8CADA7"
    elif decodedMetar["flight_category"] == "MVFR":
        return "#afabf7"
    elif decodedMetar["flight_category"] == "IFR":
        return "#f79ea4"
    elif decodedMetar["flight_category"] == "LIFR":
        return "#e8abed"
    else:
        return "#f5737c"

def getBackgroundColor(decodedMetar):
    if decodedMetar["flight_category"] == "VFR":
        return "#62f55f"
    elif decodedMetar["flight_category"] == "MVFR":
        return "#73b8f5"
    elif decodedMetar["flight_category"] == "IFR":
        return "#db3d5d"
    elif decodedMetar["flight_category"] == "LIFR":
        return "#f25ce3"
    else:
        return "#f5737c"

def getCloudCover_textColor(cover):
    color = None

    if (cover == "FEW"):
        color = "#87fa8b"
    if (cover == "SCT"):
        color = "#87fa8b"
    if (cover == "BKN"):
        color = "#75d1bf"
    if (cover == "OVC"):
        color = "#73b8f5"

    return color
