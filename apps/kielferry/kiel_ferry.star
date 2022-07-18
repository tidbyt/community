"""
Applet: Kiel Ferry
Summary: Kiel Ferry Departures
Description: Next scheduled ferry departure time for any stop and direction in the Kiel harbor ferry system.
Author: hloeding
"""

load("render.star", "render")
load("schema.star", "schema")

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

# Main entrypoint
def main(config):
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