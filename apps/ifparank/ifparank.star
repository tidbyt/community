load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("secret.star", "secret")

PIN_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAYAAADE6YVjAAAAAXNSR0IArs4c6QAAANJJREFUSEvV1tENhCAMBuBjI+ZgGIZhGOZgo7uUpKbWtoBUk7snc5p+/lUp4TPxizF+tctaa2FUwrwAi+ec1TqllH7OwkRkpjhXLeyCAGDd+ag1gPFUJ2QEpJRORq1VNDl0ICOAVpvBKHQLQZBiPNUFWUkh9QcxDepJdhGoIUGYJngAGgL/A+SGWGn+D8E09AVwb9driLSmuT4T6Rvq7fL6TjQAFsv3kCfSuC2Q1mwREc806jzBu9pdy4aTkUJwvDKGl2Y87fPMhuL2boU/0N191w+8LrYDiiRhIgAAAABJRU5ErkJggg==""")

def main(config):
    apiKey = secret.decrypt("AV6+xWcETfgDC5ODbmWAz3AAttG48nz7McLTUJ3hDTCLbX+HmRWVmh1macopHCDmzCdQ8uhTeBLQsVsBISoULTqjdf4k/mfRUYwRKyLsj3ffeKVZ6m4s7PXe07cvlBGxztMO9cF7pA/ycoJQFk/ZMSXx7Rdp2S7f1BMuBw+44fqk53lOvV0=") or config.get("dev_api_key")
    playerId = config.str("playerId", "1")  # Default to KME
    if not playerId:
        playerId = "1"  # If they enter nothing, API call will fail. This may only be a problem during dev
    IFPA_URL = "https://api.ifpapinball.com/v1/player/" + playerId + "?api_key=" + apiKey

    # Keep a cache of the JSON response from the IFPA servers. Key is the user ID, value is the response as a String
    ifpaCache = cache.get(playerId + "ifpaKey")
    if ifpaCache == None:
        #        print ("Calling IFPA API")
        res = http.get(IFPA_URL)
        if res.status_code != 200:
            fail("IFPA request failed: %d", res.status_code)
        ifpaCache = json.encode(res.json())  #res.json() converts to dict, but store in cache as a string
        cache.set(playerId + "ifpaKey", str(ifpaCache), ttl_seconds = 43200)  # every 12 hours

    #    else :
    #        print ("Using cache")

    j = json.decode(ifpaCache)  # need to turn cached string back into a dict
    ifpa_initial = j["player"]["initials"]
    ifpa_rank = j["player_stats"]["current_wppr_rank"]

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = PIN_ICON),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Text("IFPA", color = "#fc6203", font = "tb-8"),
                            render.Text("#%s" % ifpa_rank, color = "#fc6203", font = "6x13"),
                            render.Text(ifpa_initial, color = "#fc6203", font = "tb-8"),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "playerId",
                name = "Player ID",
                desc = "IFPA Player ID",
                icon = "user",
            ),
        ],
    )
