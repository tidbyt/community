"""
Applet: DetailedMETAR
Summary: Display detailed METAR
Description: Display detailed, decoded METAR information.
Author: SamuelSagarino
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

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
        if line.startswith("raw_text"):
            itemLine = line
        elif line.startswith(airport + " "):
            infoLine = line

    decodedMetar = {}

    skyCoverCount = "0"
    cloudBaseCount = "0"
    statusColor = ""

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

    #print(sky_cover1)

    if decodedMetar["flight_category"] == "VFR":
        statusColor = "#62f55f"
    if decodedMetar["flight_category"] == "MVFR":
        statusColor = "#73b8f5"
    if decodedMetar["flight_category"] == "IFR":
        statusColor = "#db3d5d"
    if decodedMetar["flight_category"] == "LIFR":
        statusColor = "#f25ce3"

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
                                                    child = render.Text(decodedMetar["observation_time"][11:16] + "Z", color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                ),
                                            ],
                                        ),
                                        width = 22,
                                        height = 16,
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
                                        height = 16,
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
                                        height = 16,
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
                                                    child = render.Text(windSpeed, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                    height = 5,
                                                ),
                                                render.Box(
                                                    child = render.Text(windDirection, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                    height = 5,
                                                ),
                                            ],
                                        ),
                                        width = 31,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                render.Box(
                                                    child = render.Text(decodedMetar["sky_cover0"], color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                    height = 5,
                                                ),
                                                render.Box(
                                                    child = render.Text(cloud_base_ft_agl0, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                    height = 5,
                                                ),
                                            ],
                                        ),
                                        width = 31,
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
        ],
    )
