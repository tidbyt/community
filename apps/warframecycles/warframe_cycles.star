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

def time_dict_conversion(timedict):
    if timedict.get("h") == None and timedict.get("m") == None:
        return "0s"
    if timedict.get("h") == None and timedict.get("m") != None:
        timedict["m"] = str(int(timedict["m"]) - 1)
        if len(timedict["m"]) == 1 and int(timedict["m"]) > 0:
            timedict["m"] = "0" + timedict["m"]
            return "0:%s" % timedict["m"]
        else:
            return "0:00"
    else:
        timedict["m"] = str(int(timedict["m"]) - 1)
        if len(timedict["m"]) == 1 and int(timedict["m"]) > 0:
            timedict["m"] = "0" + timedict["m"]
        if int(timedict["m"]) < 0:
            timedict["h"] = str(int(timedict["h"]) - 1)
            timedict["m"] = str(60 + int(timedict["m"]))
        return "%s:%s" % (timedict["h"], timedict["m"])
    return ""

def main(config):
    platform = config.str("platform", "pc")

    _wf_status_url = "https://api.warframestat.us/%s" % platform

    REFRESH_CACHE = True

    cetus_active_cache_key = "wf_%s_cetus_active_cached" % platform
    cetus_active_cached = cache.get(cetus_active_cache_key)
    earth_active_cache_key = "wf_%s_earth_active_cached" % platform
    earth_active_cached = cache.get(earth_active_cache_key)
    cambion_active_cache_key = "wf_%s_cambion_active_cached" % platform
    cambion_active_cached = cache.get(cambion_active_cache_key)
    vallis_active_cache_key = "wf_%s_vallis_active_cached" % platform
    vallis_active_cached = cache.get(vallis_active_cache_key)
    cetus_remaining_cache_key = "wf_%s_cetus_remaining_cached" % platform
    cetus_remaining_cached = cache.get(cetus_remaining_cache_key)
    earth_remaining_cache_key = "wf_%s_earth_remaining_cached" % platform
    earth_remaining_cached = cache.get(earth_remaining_cache_key)
    cambion_remaining_cache_key = "wf_%s_cambion_remaining_cached" % platform
    cambion_remaining_cached = cache.get(cambion_remaining_cache_key)
    vallis_remaining_cache_key = "wf_%s_vallis_remaining_cached" % platform
    vallis_remaining_cached = cache.get(vallis_remaining_cache_key)

    if cetus_active_cached != None and cetus_remaining_cached != None:
        print("Hit! Displaying cached data.")
        cetusactive = cetus_active_cached
        cetusremaining = cetus_remaining_cached
    else:
        REFRESH_CACHE = True

    if earth_active_cached != None and earth_remaining_cached != None:
        print("Hit! Displaying cached data.")
        earthactive = earth_active_cached
        earthremaining = earth_remaining_cached
    else:
        REFRESH_CACHE = True

    if cambion_active_cached != None and cambion_remaining_cached != None:
        print("Hit! Displaying cached data.")
        cambionactive = cambion_active_cached
        cambionremaining = cambion_remaining_cached
    else:
        REFRESH_CACHE = True

    if vallis_active_cached != None and vallis_remaining_cached != None:
        print("Hit! Displaying cached data.")
        vallisactive = vallis_active_cached
        vallisremaining = vallis_remaining_cached
    else:
        REFRESH_CACHE = True

    if REFRESH_CACHE == True:
        rep = http.get(_wf_status_url)
        if rep.status_code != 200:
            fail("Warframe request failed with status %d", rep.status_code)
        cetusactive = rep.json()["cetusCycle"]["state"].title()
        cetusremaining = rep.json()["cetusCycle"]["timeLeft"].split()
        cache.set(cetus_active_cache_key, str(cetusactive), ttl_seconds = 60)
        cache.set(cetus_remaining_cache_key, str(cetusremaining), ttl_seconds = 60)

        earthactive = rep.json()["earthCycle"]["state"].title()
        earthremaining = rep.json()["earthCycle"]["timeLeft"].split()
        cache.set(earth_active_cache_key, str(earthactive), ttl_seconds = 60)
        cache.set(earth_remaining_cache_key, str(earthremaining), ttl_seconds = 60)

        cambionactive = rep.json()["cambionCycle"]["active"].title()
        cambionremaining = rep.json()["cambionCycle"]["timeLeft"].split()
        cache.set(cambion_active_cache_key, str(cambionactive), ttl_seconds = 60)
        cache.set(cambion_remaining_cache_key, str(cambionremaining), ttl_seconds = 60)

        vallisactive = rep.json()["vallisCycle"]["state"].title()
        vallisremaining = rep.json()["vallisCycle"]["timeLeft"].split()
        cache.set(vallis_active_cache_key, str(vallisactive), ttl_seconds = 60)
        cache.set(vallis_remaining_cache_key, str(vallisremaining), ttl_seconds = 60)

    cetustime = {}
    for part in cetusremaining:
        if "s" in part:
            cetustime["s"] = part.replace("s", "")
        if "m" in part:
            cetustime["m"] = part.replace("m", "")
        if "h" in part:
            cetustime["h"] = part.replace("h", "")
    cetusremaining = time_dict_conversion(cetustime)
    cetus = "%s - %s" % (cetusremaining, cetusactive)

    earthtime = {}
    for part in earthremaining:
        if "s" in part:
            earthtime["s"] = part.replace("s", "")
        if "m" in part:
            earthtime["m"] = part.replace("m", "")
        if "h" in part:
            earthtime["h"] = part.replace("h", "")
    earthremaining = time_dict_conversion(earthtime)
    earth = "%s - %s" % (earthremaining, earthactive)

    cambiontime = {}
    for part in cambionremaining:
        if "s" in part:
            cambiontime["s"] = part.replace("s", "")
        if "m" in part:
            cambiontime["m"] = part.replace("m", "")
        if "h" in part:
            cambiontime["h"] = part.replace("h", "")
    cambionremaining = time_dict_conversion(cambiontime)
    cambion = "%s - %s" % (cambionremaining, cambionactive)

    vallistime = {}
    for part in vallisremaining:
        if "s" in part:
            vallistime["s"] = part.replace("s", "")
        if "m" in part:
            vallistime["m"] = part.replace("m", "")
        if "h" in part:
            vallistime["h"] = part.replace("h", "")
    vallisremaining = time_dict_conversion(vallistime)
    vallis = "%s - %s" % (vallisremaining, vallisactive)

    color_toggle = config.bool("warframe_cycles_color", False)
    if color_toggle:
        cetuscolor = "#02f" if cetusactive == "Night" else "#ff0"
        earthcolor = "#04f" if earthactive == "Night" else "#fd0"
        cambioncolor = "#f70" if cambionactive == "Fass" else "#0ff"
        valliscolor = "#b0f" if vallisactive == "Cold" else "#f20"
    else:
        cetuscolor = "#fff"
        earthcolor = "#fff"
        cambioncolor = "#fff"
        valliscolor = "#fff"

    return render.Root(
        child = render.Column(
            children = [
                render.Text(
                    content = "C: %s" % cetus,
                    font = "tb-8",
                    color = cetuscolor,
                ),
                render.Text(
                    content = "E: %s" % earth,
                    font = "tb-8",
                    color = earthcolor,
                ),
                render.Text(
                    content = "D: %s" % cambion,
                    font = "tb-8",
                    color = cambioncolor,
                ),
                render.Text(
                    content = "V: %s" % vallis,
                    font = "tb-8",
                    color = valliscolor,
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "PC",
            value = "pc",
        ),
        schema.Option(
            display = "Playstation 4",
            value = "ps4",
        ),
        schema.Option(
            display = "XBox",
            value = "xb1",
        ),
        schema.Option(
            display = "Nintendo Switch",
            value = "swi",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "warframe_cycles_color",
                name = "Color Display",
                icon = "eye",
                desc = "Toggle on to display in color",
            ),
            schema.Dropdown(
                id = "platform",
                name = "Platform",
                desc = "Choose the platform you play Warframe on.",
                icon = "gamepad",
                default = options[0].value,
                options = options,
            ),
        ],
    )
