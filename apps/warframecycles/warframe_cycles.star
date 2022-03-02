"""
Applet: Warframe Cycles
Summary: Time in Warframe open areas
Description: Tells you the cycle that's active in each of the Warframe open areas and in Earth missions.
Author: grantmatheny
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("cache.star", "cache")

WF_STATUS_URL = "https://api.warframestat.us/pc"
REFRESH_CACHE = False

def time_dict_conversion(timedict):
    if timedict.get("h") == None and timedict.get("m") == None:
        return "%ss" % timedict["s"]
    if timedict.get("h") == None and timedict.get("m") != None:
        return "0:%s" % timedict["m"]
    else:
        return "%s:%s" % (timedict.get("h"), timedict.get("m"))
    return ""

def main(config):
    wf_cetus_cached = cache.get("cetus")
    wf_earth_cached = cache.get("earth")
    wf_cambion_cached = cache.get("cambion")
    wf_vallis_cached = cache.get("vallis")
    if wf_cetus_cached != None:
        print("Hit! Displaying cached data.")
        cetus = wf_cetus_cached
    else:
        REFRESH_CACHE = True

    if wf_earth_cached != None:
        print("Hit! Displaying cached data.")
        earth = wf_earth_cached
    else:
        REFRESH_CACHE = True

    if wf_cambion_cached != None:
        print("Hit! Displaying cached data.")
        cambion = wf_cambion_cached
    else:
        REFRESH_CACHE = True

    if wf_vallis_cached != None:
        print("Hit! Displaying cached data.")
        vallis = wf_vallis_cached
    else:
        REFRESH_CACHE = True

    if REFRESH_CACHE == True:
        rep = http.get(WF_STATUS_URL)
        if rep.status_code != 200:
            fail("Warframe request failed with status %d", rep.status_code)

        cetustime = {}
        cetusactive = rep.json()["cetusCycle"]["state"].title()
        cetusremaining = rep.json()["cetusCycle"]["timeLeft"].split()
        for part in cetusremaining:
            if "s" in part:
                cetustime["s"] = int(part.replace("s", ""))
            if "m" in part:
                cetustime["m"] = int(part.replace("m", ""))
            if "h" in part:
                cetustime["h"] = int(part.replace("h", ""))
        cetusremaining = time_dict_conversion(cetustime)
        cetus = "%s - %s" % (cetusremaining, cetusactive)
        cache.set("wf_cetus_cached", str(cetus), ttl_seconds = 60)

        earthtime = {}
        earthactive = rep.json()["earthCycle"]["state"].title()
        earthremaining = rep.json()["earthCycle"]["timeLeft"].split()
        for part in earthremaining:
            if "s" in part:
                earthtime["s"] = int(part.replace("s", ""))
            if "m" in part:
                earthtime["m"] = int(part.replace("m", ""))
            if "h" in part:
                earthtime["h"] = int(part.replace("h", ""))
        earthremaining = time_dict_conversion(earthtime)
        earth = "%s - %s" % (earthremaining, earthactive)
        cache.set("wf_earth_cached", str(earth), ttl_seconds = 60)

        cambiontime = {}
        cambionactive = rep.json()["cambionCycle"]["active"].title()
        cambionremaining = rep.json()["cambionCycle"]["timeLeft"].split()
        for part in cambionremaining:
            if "s" in part:
                cambiontime["s"] = int(part.replace("s", ""))
            if "m" in part:
                cambiontime["m"] = int(part.replace("m", ""))
            if "h" in part:
                cambiontime["h"] = int(part.replace("h", ""))
        cambionremaining = time_dict_conversion(cambiontime)
        cambion = "%s - %s" % (cambionremaining, cambionactive)
        cache.set("wf_cambion_cached", str(cambion), ttl_seconds = 60)

        vallistime = {}
        vallisactive = rep.json()["vallisCycle"]["state"].title()
        vallisremaining = rep.json()["vallisCycle"]["timeLeft"].split()
        for part in vallisremaining:
            if "s" in part:
                vallistime["s"] = int(part.replace("s", ""))
            if "m" in part:
                vallistime["m"] = int(part.replace("m", ""))
            if "h" in part:
                vallistime["h"] = int(part.replace("h", ""))
        vallisremaining = time_dict_conversion(vallistime)
        vallis = "%s - %s" % (vallisremaining, vallisactive)
        cache.set("wf_vallis_cached", str(vallis), ttl_seconds = 60)

    return render.Root(
        child = render.Column(
            children = [
                render.Text("C: %s" % cetus),
                render.Text("E: %s" % earth),
                render.Text("D: %s" % cambion),
                render.Text("V: %s" % vallis),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
