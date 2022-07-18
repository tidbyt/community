"""
Applet: Kiel Ferry
Summary: Kiel Ferry Departures
Description: Next scheduled ferry departure time for any stop and direction in the Kiel harbor ferry system.
Author: hloeding
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")

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

def getNextFerry(ferryStopID, ferryDirectionID):
    ret = (False, None)
    query = FERRY_QUERY_URL % (ferryStopID, ferryDirectionID, FERRY_MAX_LOOKAHEAD_MIN)
    response = http.get(query)
    if response.status_code != 200:
        return ret
    response = response.json()
    if len(response) == 0:
        return ret
    response = response[0]["when"]
    return (True, response)

# Main entrypoint
def main(config):
    # Get requested ferry stop an direction IDs
    ferryStopID = config.str("ferry_stop_id", DEFAULT_FERRY_STOP_ID)
    ferryDirectionID = config.str("ferry_direction_id", DEFAULT_FERRY_DIRECTION_ID)
    _, when = getNextFerry(ferryStopID, ferryDirectionID)
    print(when)

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