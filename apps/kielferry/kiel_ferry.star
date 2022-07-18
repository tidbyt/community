"""
Applet: Kiel Ferry
Summary: Kiel Ferry Departures
Description: Next scheduled ferry departure time for any stop and direction in the Kiel harbor ferry system.
Author: hloeding
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("cache.star", "cache")

# Mapping from ferry stop names (to be used as config option)
# to stop IDs (to be used as API call parameters)
FERRY_STOP_IDS = {
    "Bahnhof": 360901,
    "Seegarten": 360902,
    "Reventloubrücke": 703599,
    "Mönkeberg": 360905,
    "Möltenort, Heikendorf": 360907,
    "Friedrichsort": 360908,
    "Falckenstein": 370909,
    "Laboe": 360910,
    "Schilksee": 360911,
    "Strande": 360912,
}
# Default ferry stop ID
DEFAULT_FERRY_STOP_ID = str(FERRY_STOP_IDS["Bahnhof"])

# Terminal ferry stop names (ferry directions)
FERRY_DIRECTIONS = [
    "Laboe",
    "Bahnhof",
]
# Default ferry direction ID
DEFAULT_FERRY_DIRECTION_ID = str(FERRY_STOP_IDS["Laboe"])

# Maximum look ahead time (7 days in minutes)
FERRY_MAX_LOOKAHEAD_MIN = 7 * 24 * 60

# Cache time to live
FERRY_CACHE_TTL = 30
# Cacke keys
FERRY_CACHE_DATA_KEY = "next_ferry_data"
FERRY_CACHE_ERROR_KEY = "next_ferry_query_error"

# Clean REST wrapper around the Deutsche Bahn public API
# See https://github.com/derhuerst/db-rest
FERRY_QUERY_URL = \
    "https://v5.db.transport.rest/stops/%s/departures" + \
    "?direction=%s" + \
    "&duration=%d" + \
    "&nationalExpress=false" + \
    "&national=false" + \
    "&regionalExp=false" + \
    "&regional=false" + \
    "&suburban=false" + \
    "&bus=false" + \
    "&ferry=true" + \
    "&subway=false" + \
    "&tram=false" + \
    "&taxi=false"

# Wrapper to cache boolean values
def setCacheBool(key, value, ttl):
    cache.set(key, "X" if value else "", ttl)

# Wrapper to cache string values (trivial, but 
# provided for common interface and readability)
def setCacheStr(key, value, ttl):
    cache.set(key, value, ttl)

# Wrapper to get boolean values from cache
def getCacheBool(key):
    ret = cache.get(key)
    if ret != None:
        ret = bool(ret)
    return ret

# Wrapper to get string values from cache
# (trivial, but provided for common interface
# and readability)
def getCacheStr(key):
    return cache.get(key)

# Function to retrieve next ferry data.
# Returns a tuple of
# - validity: Indicates if data is usable
# - next ferry: Timestamp string or None
def getNextFerry(ferryStopID, ferryDirectionID):
    nextFerry = getCacheStr(FERRY_CACHE_DATA_KEY)
    queryError = getCacheBool(FERRY_CACHE_ERROR_KEY)
    if nextFerry == None or queryError == None:
        query = FERRY_QUERY_URL % (
            ferryStopID, 
            ferryDirectionID, 
            FERRY_MAX_LOOKAHEAD_MIN
        )
        response = http.get(query)
        if response.status_code != 200:
            queryError = True
            nextFerry = ""
        else:
            queryError = False
            response = response.json()
            if len(response) != 0:
                nextFerry = response[0]["when"]
            else:
                nextFerry = ""
        setCacheStr(FERRY_CACHE_DATA_KEY, nextFerry, FERRY_CACHE_TTL)
        setCacheBool(FERRY_CACHE_ERROR_KEY, queryError, FERRY_CACHE_TTL)
    return (not queryError, nextFerry if len(nextFerry) > 0 else None)

# Main entrypoint
def main(config):
    ferryStopID = config.str(
        "ferry_stop_id",
        DEFAULT_FERRY_STOP_ID
    )
    ferryDirectionID = config.str(
        "ferry_direction_id",
        DEFAULT_FERRY_DIRECTION_ID
    )
    valid, nextFerry = getNextFerry(ferryStopID, ferryDirectionID)
    print("-----------")
    print("Data valid: %s" % "yes" if valid else "no")
    print("Next ferry: %s" % nextFerry)

    return render.Root(
        child = render.Box(height = 1, width = 1),
    )

# Construct ferry stop options
def getFerryStopOptions():
    ret = []
    for stop in FERRY_STOP_IDS:
        ret.append(
            schema.Option(
                display = stop,
                value = str(FERRY_STOP_IDS[stop]),
            )
        )
    return ret

# Construct ferry direction options
def getFerryDirectionOptions():
    ret = []
    for direction in FERRY_DIRECTIONS:
        ret.append(
            schema.Option(
                display = direction,
                value = str(FERRY_STOP_IDS[direction]),
            )
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
                options = ferryStopOptions
            ),
            schema.Dropdown(
                id = "ferry_direction_id",
                name = "Ferry Direction",
                desc = "Display next departure for this ferry direction.",
                icon = "compass",
                default = ferryDirectionOptions[0].value,
                options = ferryDirectionOptions
            ),
        ],
    )