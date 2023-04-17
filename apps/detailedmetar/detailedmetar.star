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

DEFAULT_AIRPORT = "KMCO"

def main(config):
    airport = config.str("airport", DEFAULT_AIRPORT)

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

    for line in lines:
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

        if line.startswith("raw_text"):
            itemLine = line
        elif line.startswith(airport + " "):
            infoLine = line

    decodedMetar = {}

    skyCoverCount = "0"
    cloudBaseCount = "0"
    statusColor = ""
    textColor = ""

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

    year = int(decodedObservationMetar[0:4])
    month = int(decodedObservationMetar[5:7])
    day = int(decodedObservationMetar[8:10])
    hour = int(decodedObservationMetar[11:13])
    minute = int(decodedObservationMetar[14:16])
    second = int(decodedObservationMetar[17:19])

    observationDate = time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "Etc/UTC")

    humanizedTime = humanize.time(observationDate)

    if decodedMetar["flight_category"] == "VFR":
        statusColor = "#62f55f"
        textColor = "#87fa8b"
    if decodedMetar["flight_category"] == "MVFR":
        statusColor = "#73b8f5"
        textColor = "#8d87fa"
    if decodedMetar["flight_category"] == "IFR":
        statusColor = "#db3d5d"
        textColor = "#f5737c"
    if decodedMetar["flight_category"] == "LIFR":
        statusColor = "#f25ce3"
        textColor = "#e88bf0"

    if decodedMetar["wind_speed_kt"] == "0":
        windSpeed = "Calm"
        windDirection = "Var"

        if decodedMetar["wind_dir_degrees"] == "0":
            windSpeed = "Calm"
            windDirection = ""
        else:
            windDirection = decodedMetar["wind_dir_degrees"]
    else:
        windSpeed = decodedMetar["wind_speed_kt"] + "kts"
        windDirection = "@ " + decodedMetar["wind_dir_degrees"]

    if (decodedMetar["cloud_base_ft_agl0"] == ""):
        cloud_base_ft_agl0 = ""
    else:
        cloud_base_ft_agl0 = decodedMetar["cloud_base_ft_agl0"] + "ft"

    sky_cover = decodedMetar["sky_cover0"]

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
                                                render.Text(decodedMetar["station_id"], color = statusColor, font = "CG-pixel-4x5-mono"),
                                                render.Marquee(
                                                    width = 21,
                                                    child = render.Text(humanizedTime, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                ),
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
                                            color = statusColor,
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
                                                render.Text(decodedMetar["flight_category"], color = statusColor, font = "CG-pixel-4x5-mono"),
                                                render.Text(decodedMetar["altim_in_hg"][0:5], color = "#8CADA7", font = "CG-pixel-3x5-mono"),
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
                                                    child = render.Text(windSpeed, color = textColor, font = "CG-pixel-3x5-mono"),
                                                    height = 5,
                                                ),
                                                render.Box(
                                                    child = render.Text(windDirection, color = textColor, font = "CG-pixel-3x5-mono"),
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
                                                    child = render.Text(sky_cover, color = textColor, font = "CG-pixel-3x5-mono"),
                                                    height = 5,
                                                ),
                                                render.Box(
                                                    child = render.Text(cloud_base_ft_agl0, color = textColor, font = "CG-pixel-3x5-mono"),
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
                                    render.Box(height = 1, width = 64, color = textColor),
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
        ],
    )
