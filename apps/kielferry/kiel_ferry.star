"""
Applet: Kiel Ferry
Summary: Kiel Ferry Departures
Description: Next scheduled ferry departure time for any stop and direction in the Kiel harbor ferry system.
Author: hloeding
"""

# ################################
# ###### App module loading ######
# ################################

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")

# Required modules
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ###########################
# ###### App constants ######
# ###########################

# Base64 ferry icon data
FERRY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABUAAAARCAYAAAAyhueAAAAESElEQVQ4T11Ue0yVdRh+ft/lXDk
HucgBooNHFBnQRRiQUitjpDNbNOcfzsq5UNZMlmSLP5q6trZqloPJCk27zf7IzWSgbhybmVp/AC
kq2ykjOGd4DsgQKjiX7/br/b5Dtnr3/b7r+3u+53lvDP+zl44EOWMMgsisL4wvOogcrwhH8KujE
SlNx0CyEpynP372akPaedHuP2zvusAh0MEEWuZrDutiIQPPlj+I/l9i6Cw9hd2hzdbPTFBzGaYD
2fGWp60b67Tj4yAXBAIT0i9MpuYSCdg0W7YD2pwCg+uoFkK4rK3CCpuKqGInZ8EC1smXGwxHd61
Lc2np7k9LJlSRlukkCCYog+LR4FwwUPVALupK85HhdkHXdSiqalLFR/0jECBB44a1r6u5gbHdBJ
hmacpOMzMIUDIAyWVAVxm4omJ05CcM/XABst2J6fEwbLKCwMYXsa6uwdKj6+m9Ou1jrcfSLEVKj
E0QLRmMwOt4EkOCCwYjBsS57PoZ9BTVYGrgOzjUJGLRuygIlKDYH4CvrBYGgRl0MkPAXv/0vMVU
FEVs6mzDudZDJHcGdl8R1s6EMbe6FonZeXikJNbU14AlF6BpmhVzzRAwOjGNvpuRdNII0LyyfSf
Oc1O1KApoD5zBh7EtqMhxouPAXrz19kEsKw5AVXVcvnIJJdMxPN72BmmkjFPSlJSOmT9mcWowTP
KJqRUIYrrv2FkuLmb7sTvvYDBwAE+W5KJv8CZ2Na3HU9taYNwZw8Xe01heXIg4xbd9/348VFuHk
kI/wlMTWFVahf6xGOT5lJk7Au3u5WbGd1ZlwfdXJ3rG6hEcGIV3aRZe3rwFjCjIdhtJ1uF0Z6Iw
10NcOKLTs5AkEbJgoKtnAA7HEqhMgUp+rK2rh1NoUO/3oKggDzLF9p/yMgN/9Isv8dqenXAyGxT
NgMsuQVEUuFwuyLIIm0SbyW61vodv69ZajcC6vzrJr8278Xx5ATwuD073fgO7x4vD3cfRUFONlQ
8/iovBPsg2Jz7v6IDb5YTNRkBiBlWLRjUqQ5Y0iruGrv6fMTkXB/M3vclVLY6TB/eiIEtC6HYIF
WXlCI1HkeN14933P8CNsIZE4h7mIgMwlCQk2UGZ1uErLMLdyRg0KjEqcqzY2EoxJ6Ym9fz1O7j0
5xQWknG4qT4XUgoEchRECQU5Xvw2Nm6VipZMwNCoXZOpdO/LEjEmEJ1KzOmEv34rxvo+SbdpZfN
hHjp7CHb6h6YacGS4kbkkGylVsdpW0VLw+XIw8uNVanVKE7WNtdNuh8ubhfi9aRQ+sRXt21/Anm
1N9+cQKp5r4ZsaKzE4fBuJmVkIWTI83jw8UrYMl65cRfjWMJYu9yNyfZhqUsOamnrciI5jITKOz
EAAcZoPM9eG/p1SVvoWLX9DM+fJJKpXryTJDJHfI3BICeRlZ2AiOokNzzTCQZNJoQFyLhhETmYe
vv/62H/m6d9sgNcoHPJZ/AAAAABJRU5ErkJggg==
""")

# Mapping from ferry stop IDs to stop names
FERRY_STOP_IDS = {
    360901: "Bahnhof",
    360902: "Seegarten",
    703599: "Reventloubrücke",
    360905: "Mönkeberg",
    360907: "Möltenort, Heikendorf",
    360908: "Friedrichsort",
    370909: "Falckenstein",
    360910: "Laboe",
    360911: "Schilksee",
    360912: "Strande",
}

# Default ferry stop ID
DEFAULT_FERRY_STOP_ID = str(FERRY_STOP_IDS.keys()[0])

# Terminus ferry stop IDs (ferry directions)
FERRY_DIRECTION_IDS = [
    360910,  # Laboe
    360901,  # Bahnhof
    703599,  # Reventloubrücke
]

# Default ferry direction ID
DEFAULT_FERRY_DIRECTION_ID = str(FERRY_DIRECTION_IDS[0])

# Maximum look ahead time (7 days in minutes)
FERRY_MAX_LOOKAHEAD_MIN = 7 * 24 * 60

# Cache time to live
FERRY_CACHE_TTL = 30

# Cacke keys
FERRY_CACHE_DATA_KEY = "next_ferry_data_%s_%s"
FERRY_CACHE_STATUS_CODE = "next_ferry_query_status_code_%s_%s"

# Clean REST wrapper around the Deutsche Bahn public API
# See https://github.com/derhuerst/db-rest
FERRY_QUERY_URL = \
    "https://v6.db.transport.rest/stops/%s/departures" + \
    "?direction=%s" + \
    "&duration=%d" + \
    "&nationalExpress=false" + \
    "&national=false" + \
    "&regionalExpress=false" + \
    "&regional=false" + \
    "&suburban=false" + \
    "&bus=false" + \
    "&ferry=true" + \
    "&subway=false" + \
    "&tram=false" + \
    "&taxi=false"

# ##############################################
# ###### Functions for caching ferry data ######
# ##############################################

# Get cached ferry departure data
# for given ferry stop and direction
def getCachedFerryData(
        ferryStopID,
        ferryDirectionID):
    return cache.get(
        FERRY_CACHE_DATA_KEY % (
            ferryStopID,
            ferryDirectionID,
        ),
    )

# Cache ferry departure data for
# given ferry stop and direction
def setCachedFerryData(
        ferryStopID,
        ferryDirectionID,
        ferryData):
    cache.set(
        FERRY_CACHE_DATA_KEY % (
            ferryStopID,
            ferryDirectionID,
        ),
        ferryData,
        FERRY_CACHE_TTL,
    )

# Get cached API query status code
# (avoid spamming API with bad requests)
def getCachedFerryStatusCode(
        ferryStopID,
        ferryDirectionID):
    ret = cache.get(
        FERRY_CACHE_STATUS_CODE % (
            ferryStopID,
            ferryDirectionID,
        ),
    )
    if ret != None:
        ret = int(ret)
    return ret

# Cache API query status code
# (avoid spamming API with bad requests)
def setCachedFerryStatusCode(
        ferryStopID,
        ferryDirectionID,
        value):
    cache.set(
        FERRY_CACHE_STATUS_CODE % (
            ferryStopID,
            ferryDirectionID,
        ),
        str(value),
        FERRY_CACHE_TTL,
    )

# ####################################################
# ###### Function for retrieving API ferry data ######
# ####################################################

# Function to retrieve next ferry data.
# Returns a tripple of
# - validity: Indicates if data is usable
# - next ferry: Timestamp string or None
# - status code: Status code of last query

def getNextFerry(ferryStopID, ferryDirectionID):
    nextFerry = getCachedFerryData(
        ferryStopID,
        ferryDirectionID,
    )
    queryStatusCode = getCachedFerryStatusCode(
        ferryStopID,
        ferryDirectionID,
    )

    # Check if cached data has expired
    if nextFerry == None or queryStatusCode == None:
        query = FERRY_QUERY_URL % (
            ferryStopID,
            ferryDirectionID,
            FERRY_MAX_LOOKAHEAD_MIN,
        )
        response = http.get(query)

        # Set query status code.
        queryStatusCode = response.status_code

        # Set next ferry according to response,
        # or to an empty string to denote
        # no scheduled ferry departure in cache
        # (can't cache None).
        if queryStatusCode == 200:
            response = response.json()

            # Check if there is a next ferry
            # scheduled. If so, extract the
            # ferry departure time.
            # If not, set empty string to denote
            # no ferry departure data in cache
            if "departures" in response and len(response["departures"]) > 0:
                nextFerry = response["departures"][0]["when"]
            else:
                nextFerry = ""
        else:
            nextFerry = ""

        # Update cached ferry departure data
        setCachedFerryData(
            ferryStopID,
            ferryDirectionID,
            nextFerry,
        )

        # Update cached query status code
        setCachedFerryStatusCode(
            ferryStopID,
            ferryDirectionID,
            queryStatusCode,
        )

    # Return (a) validity of data (status code 200),
    # (b) next ferry departure data or None,
    # (c) status code
    return (
        queryStatusCode == 200,
        nextFerry if len(nextFerry) > 0 else None,
        queryStatusCode,
    )

# ################################################
# ###### Function to render an error screen ######
# ################################################

# Function to render an error screen given a query
# status code, to be used if no valid ferry departure
# data can be retrieved from the API
def renderError(statusCode):
    return render.Root(
        child = render.Row(
            children = [
                render.Column(
                    children = [
                        render.Text(
                            content = "No data",
                            color = "#990000",
                            font = "CG-pixel-4x5-mono",
                        ),
                        render.Image(src = FERRY_ICON),
                        render.Text(
                            content = "HTTP %d" % statusCode,
                            color = "#3399ff",
                            font = "CG-pixel-4x5-mono",
                        ),
                    ],
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
            expanded = True,
            main_align = "center",
        ),
    )

# ######################################################
# ###### Functions to render ferry departure data ######
# ######################################################

# Format given ferry departure time string as hh:mm
def formatDepartureTime(nextFerry):
    departureTime = time.parse_time(nextFerry)
    return departureTime.format("15:04")

# Format duration from now to given ferry departure
# time as (a) day of week, if the departure is not
# today, or (b) as number of minutes, if the departure
# time is at least 1 minute away, ot (c) as "now"
# if the departure time is this minute
def formatWaitDuration(nextFerry):
    departureTime = time.parse_time(nextFerry)
    now = time.now()
    if departureTime.day != now.day or \
       departureTime.month != now.month or \
       departureTime.year != now.year:
        waitDurationStr = departureTime.format("Monday")
    else:
        waitDuration = departureTime - now
        minutes = math.floor(waitDuration.minutes)
        if minutes > 0:
            waitDurationStr = "%d min" % minutes
        else:
            waitDurationStr = "now"
    return waitDurationStr

# Get all required ferry departure strings for rendering.
# Returns a tuple of
# - The route, consisting of stop and direction
# - The formatted departure time
# - The formatted wait duration
def getFerryDataStrings(ferryStop, ferryDirection, nextFerry):
    route = "%s --> %s" % (ferryStop, ferryDirection)
    departureTimeStr = "-:-"
    waitDurationStr = "No service"
    if nextFerry != None:
        departureTimeStr = formatDepartureTime(nextFerry)
        waitDurationStr = formatWaitDuration(nextFerry)
    return (route, departureTimeStr, waitDurationStr)

# Render ferry departure data
def renderFerryData(ferryStop, ferryDirection, nextFerry):
    route, departureTime, waitDuration = getFerryDataStrings(
        ferryStop,
        ferryDirection,
        nextFerry,
    )
    return render.Root(
        child = render.Box(
            child = render.Column(
                children = [
                    render.Marquee(
                        child = render.Text(
                            content = route,
                            color = "#3399ff",
                        ),
                        width = 62,
                    ),
                    render.Row(
                        children = [
                            render.Image(src = FERRY_ICON),
                            render.Column(
                                children = [
                                    render.Text(
                                        content = departureTime,
                                        font = "6x13",
                                    ),
                                    render.Text(
                                        content = waitDuration,
                                        color = "#ff6600",
                                        font = "tom-thumb",
                                    ),
                                ],
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                            ),
                        ],
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                    ),
                ],
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
            ),
            padding = 1,
        ),
    )

# #############################
# ###### App entry point ######
# #############################

# Main entrypoint
def main(config):
    # Get ferry stop and ferry direction names and IDs from config
    ferryStopID = config.str(
        "ferry_stop_id",
        DEFAULT_FERRY_STOP_ID,
    )
    ferryStop = FERRY_STOP_IDS[int(ferryStopID)]
    ferryDirectionID = config.str(
        "ferry_direction_id",
        DEFAULT_FERRY_DIRECTION_ID,
    )
    ferryDirection = FERRY_STOP_IDS[int(ferryDirectionID)]

    # Retrieve data for next ferry departure
    valid, nextFerry, statusCode = getNextFerry(ferryStopID, ferryDirectionID)

    # If ferry departure data is valid, render it
    if valid:
        return renderFerryData(ferryStop, ferryDirection, nextFerry)

    # Otherwise, render an error
    return renderError(statusCode)

# ###############################################
# ###### Functions to construct app schema ######
# ###############################################

# Construct ferry stop options
def getFerryStopOptions():
    ret = []
    for stop in FERRY_STOP_IDS:
        ret.append(
            schema.Option(
                display = FERRY_STOP_IDS[stop],
                value = str(stop),
            ),
        )
    return ret

# Construct ferry direction options
def getFerryDirectionOptions():
    ret = []
    for direction in FERRY_DIRECTION_IDS:
        ret.append(
            schema.Option(
                display = FERRY_STOP_IDS[direction],
                value = str(direction),
            ),
        )
    return ret

# Construct schema
def get_schema():
    ferryStopOptions = getFerryStopOptions()
    ferryDirectionOptions = getFerryDirectionOptions()
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "ferry_stop_id",
                name = "Ferry Stop",
                desc = "Display next departure for this ferry stop.",
                icon = "ferry",
                default = ferryStopOptions[0].value,
                options = ferryStopOptions,
            ),
            schema.Dropdown(
                id = "ferry_direction_id",
                name = "Ferry Direction",
                desc = "Display next departure for this ferry direction.",
                icon = "compass",
                default = ferryDirectionOptions[0].value,
                options = ferryDirectionOptions,
            ),
        ],
    )
