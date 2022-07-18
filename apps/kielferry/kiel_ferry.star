"""
Applet: Kiel Ferry
Summary: Kiel Ferry Departures
Description: Next scheduled ferry departure time for any stop and direction in the Kiel harbor ferry system.
Author: hloeding
"""
# Required includes
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("math.star", "math")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/base64.star", "base64")

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
        setCacheStr(
            FERRY_CACHE_DATA_KEY,
            nextFerry,
            FERRY_CACHE_TTL
        )
        setCacheBool(
            FERRY_CACHE_ERROR_KEY,
            queryError,
            FERRY_CACHE_TTL
        )
    return (
        not queryError,
        nextFerry if len(nextFerry) > 0 else None
    )

# Function to render an error screen, to be used
# if no valid ferry departure data can be retrieved
def renderError():
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
            render.Image(src=FERRY_ICON),
            render.Marquee(
              child = render.Text(
                content = "Something went terribly wrong...",
                color = "#3399ff",
                font = "CG-pixel-4x5-mono",
              ),
              width = 60,
            ),
          ],
          expanded = True,
          main_align = "space_evenly",
          cross_align = "center",
        ),
      ],
      expanded = True,
      main_align = "center",
    )
  )

def getFerryDataStrings(nextFerry):
    if nextFerry == None:
        # TODO
        return (
            "---",
            "---"
        )
    now = time.now()
    ferryDepartureTime = time.parse_time(nextFerry)
    # TODO

# Render ferry departure data
def renderFerryData(nextFerry):
    # DEBUG
    departure, waittime = getFerryDataStrings(None)
    # TODO
    # departure, waittime = getFerryDataStrings(nextFerry)
    return render.Root(
        child = render.Row(
            children = [
                render.Column(
                    children = [
                        render.Image(src=FERRY_ICON),
                    ],
                    expanded = True,
                    main_align = "center",
                ),
                render.Column(
                    children = [
                        render.Text(
                            content = "TODO",
                            color = "#3399ff",
                        ),
                        render.Text(
                            content = departure,
                            font = "6x13",
                        ),
                        render.Text(
                            content = waittime,
                            color = "#ff6600",
                            font = "tom-thumb",
                        ),
                    ],
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
            expanded = True,
            main_align = "space_evenly",
        )
    )

# Main entrypoint
def main(config):
    # Get ferry stop and ferry direction IDs from config
    ferryStopID = config.str(
        "ferry_stop_id",
        DEFAULT_FERRY_STOP_ID
    )
    ferryDirectionID = config.str(
        "ferry_direction_id",
        DEFAULT_FERRY_DIRECTION_ID
    )
    # Retrieve data for next ferry departure
    valid, nextFerry = getNextFerry(ferryStopID, ferryDirectionID)
    # If ferry departure data is valid, render it
    if valid:
        print("NextFerry: %s" % nextFerry)
        return renderFerryData(nextFerry)
    # Otherwise, render an error
    return renderError()

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