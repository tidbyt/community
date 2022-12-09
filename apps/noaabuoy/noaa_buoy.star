"""
Applet: NOAA Buoy
Summary: Display buoy weather data
Description: Display swell,wind,temperature,misc data for user specified buoy. Find buoy_id's here : https://www.ndbc.noaa.gov/obs.shtml
Author: tavdog
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("xpath.star", "xpath")
load("re.star", "re")

print_debug = False

default_location = """
{
	"lat": "20.8911",
	"lng": "-156.5047",
	"description": "Wailuku, HI, USA",
	"locality": "Maui",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/Honolulu"
}
"""

def debug_print(arg):
    if print_debug:
        print(arg)

def swell_over_threshold(thresh, units, data):  # assuming threshold is already in preferred units
    height = data["WVHT"]
    if thresh == "" or float(thresh) == 0.0:
        return True
    elif units == "m":
        height = float(height) / 3.281
        height = int(height * 10)
        height = height / 10.0

    return float(height) >= float(thresh)

def FtoC(F):  # returns rounded to 1 decimal
    if F == "--":
        return "--"
    c = (float(F) - 32) * 0.55
    c = int(c * 10)
    return c / 10.0

def name_from_rss(xml):
    #re/Station\s+.*\s+\-\s+(.+),/
    string = xml.query("/rss/channel/item/title")
    name_match = re.match(r"Station\s+.*\s+\-\s+(.+),", string)
    if len(name_match) == 0:
        #try again
        name_match = re.match(r"Station\s+.*\s+\-\s+(.+)$", string)
        if len(name_match) == 0:
            return None
        else:
            return name_match[0][1]

    else:
        return name_match[0][1]

def fetch_data(buoy_id, last_data):
    debug_print("fetching....")
    data = dict()
    url = "https://www.ndbc.noaa.gov/data/latest_obs/%s.rss" % buoy_id.lower()
    debug_print("url: " + url)
    resp = http.get(url)
    debug_print(resp)
    if resp.status_code != 200:
        if len(last_data) != 0:  # try to return the last cached data if it exists to account for spurious api failures
            return last_data
        elif resp.status_code == 404:
            data["name"] = buoy_id
            data["error"] = "ID not valid"
            return data
        else:
            data["name"] = buoy_id
            data["error"] = "Code: " + str(resp.status_code)
            return data
    else:
        data["name"] = name_from_rss(xpath.loads(resp.body())) or buoy_id

        #print_rss(xpath.loads(resp.body()))
        data_string = xpath.loads(resp.body()).query("/rss/channel/item/description")

        #data_string = xpath.loads(xml).query("/rss/channel/item/description")
        # continue with parsing build up the list
        re_dict = dict()

        # coordinates, not used for anything yet
        re_dict["location"] = r"Location:</strong>\s+(.*)<b"

        # swell data
        re_dict["WVHT"] = r"Significant Wave Height:</strong> (\d+\.?\d+?) ft<br"
        re_dict["DPD"] = r"Dominant Wave Period:</strong> (\d+) sec"
        re_dict["MWD"] = r"Mean Wave Direction:</strong> ([ENSW]+ \(\d+)&#176;"

        # wind data
        re_dict["WSPD"] = r"Wind Speed:</strong>\s+(\d+\.?\d+?)\sknots"
        re_dict["GST"] = r"Wind Gust:</strong>\s+(\d+\.?\d+?)\sknots"
        re_dict["WDIR"] = r"Wind Direction:</strong> ([ENSW]+ \(\d+)&#176;"

        # temperatures
        re_dict["ATMP"] = r"Air Temperature:</strong> (\d+\.\d+?)&#176;F"
        re_dict["WTMP"] = r"Water Temperature:</strong> (\d+\.\d+?)&#176;F"

        # misc other data
        re_dict["DEW"] = r"Dew Point:</strong> (\d+\.\d+?)&#176;F"
        re_dict["VIS"] = r"Visibility:</strong> (\d\.?\d? nmi)"
        re_dict["TIDE"] = r"Tide:</strong> (-?\d+\.\d+?) ft"

        for field in re_dict.items():
            field_data = re.match(field[1], data_string)
            if len(field_data) == 0:
                #debug_print(field[0] + "  : no match, using " + str(last_data.get(field[0])) )
                data[field[0]] = last_data.get(field[0])  # use old cached data, None if non existant
            else:
                debug_print(field[0] + " : " + field_data[0][1])
                data[field[0]] = field_data[0][1].replace("(", "")

        #debug_print(data)
    return data

def main(config):
    debug_print("##########################")
    data = dict()

    buoy_id = config.get("buoy_id", "")

    if buoy_id == "none" or buoy_id == "":  # if manual input is empty load from local selection
        local_selection = config.get("local_buoy_id", '{"display": "Station 51202 - Waimea Bay", "value": "51201"}')  # default is Waimea
        local_selection = json.decode(local_selection)
        if "value" in local_selection:
            buoy_id = local_selection["value"]
        else:
            buoy_id = "51201"

    buoy_name = config.get("buoy_name", "")
    h_unit_pref = config.get("h_units", "feet")
    t_unit_pref = config.get("t_units", "F")
    min_size = config.get("min_size", "0")

    # ensure we have a valid numer for min_size
    if len(re.findall("[0-9]+", min_size)) <= 0:
        min_size = "0"

    # CACHING FOR MAIN DATA OBJECT
    cache_key = "noaa_buoy_%s" % (buoy_id)
    cache_str = cache.get(cache_key)  #  not actually a json object yet, just a string
    if cache_str != None:  # and cache_str != "{}":
        debug_print("cache :" + cache_str)
        data = json.decode(cache_str)

    # CACHING FOR USECACHE : use this cache item to control wether to fetch new data or not, and update the main data cache
    usecache_key = "noaa_buoy_%s_usecache" % (buoy_id)
    usecache = cache.get(usecache_key)  #  not actually a json object yet, just a string
    if usecache and len(data) != 0:
        debug_print("using cache since usecache_key is set")
    else:
        debug_print("no usecache so fetching data")
        data = fetch_data(buoy_id, data)  # we pass in old data object so we can re-use data if missing from fetched data
        if data != None:
            cache.set(cache_key, json.encode(data), ttl_seconds = 1800)  # 30 minutes, should never actually expire because always getting re set
            cache.set(cache_key + "_usecache", '{"usecache":"true"}', ttl_seconds = 600)  # 10 minutes

    if buoy_name == "" and "name" in data:
        debug_print("setting buoy_name to : " + data["name"])
        buoy_name = data["name"]

        # trim to max width of 14 chars or two words
        if len(buoy_name) > 14:
            buoy_name = buoy_name[:13]
            buoy_name = buoy_name.strip()

    # colors based on swell size
    color_small = "#00AAFF"  #blue
    color_medium = "#AAEEDD"  #cyanish
    color_big = "#00FF00"  #green
    color_huge = "#FF0000"  # red
    swell_color = color_medium

    # ERROR #################################################
    if "error" in data:  # if we have error key, then we got no good swell data, display the error
        #debug_print("buoy_id: " + str(buoy_id))
        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_id,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Error",
                            font = "tb-8",
                            color = "#FF0000",
                        ),
                        render.Text(
                            content = data["error"],
                            color = "#FF0000",
                        ),
                    ],
                ),
            ),
        )

        #SWELL###########################################################

    elif (data.get("DPD") and config.get("display_swell", True) == "true" and swell_over_threshold(min_size, h_unit_pref, data)):
        height = ""
        if "MWD" in data:
            mwd = data["MWD"]
        else:
            mwd = "--"
        height = float(data["WVHT"])
        if (height < 2):
            swell_color = color_small
        elif (height < 5):
            swell_color = color_medium
        elif (height < 12):
            swell_color = color_big
        elif (height >= 13):
            swell_color = color_huge

        height = data["WVHT"]
        unit_display = "f"
        if h_unit_pref == "meters":
            unit_display = "m"
            height = float(height) / 3.281
            height = int(height * 10)
            height = height / 10.0

        wtemp = ""

        if (data.get("WTMP") and config.get("display_temps") == "true"):  # we have some room at the bottom for wtmp if desired
            wt = data["WTMP"]
            if (t_unit_pref == "C"):
                wt = FtoC(wt)
            wt = int(float(wt) + 0.5)
            wtemp = " %s%s" % (str(wt), t_unit_pref)

        # don't render anything if swell height is below minimum
        if min_size != "" and float(height) < float(min_size):
            return []

        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s%s %ss" % (height, unit_display, data["DPD"]),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s°%s" % (mwd, wtemp),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
        #WIND#################################################

    elif (data.get("WSPD") and data.get("WDIR") and config.get("display_wind", False) == "true"):
        gust = ""
        avg = data["WSPD"]
        avg = str(int(float(avg) + 0.5))
        if "GST" in data:
            gust = data["GST"]
            gust = int(float(gust) + 0.5)
            gust = "g" + str(gust)

        atemp = ""
        if "ATMP" in data and config.get("display_temps") == "true":  # we have some room at the bottom for wtmp if desired
            at = data["ATMP"]
            if (t_unit_pref == "C"):
                at = FtoC(at)
            at = int(float(at) + 0.5)
            atemp = " %s%s" % (str(at), t_unit_pref)

        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s%s kts" % (avg, gust),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s°%s" % (data["WDIR"], atemp),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
        #TEMPS#################################################

    elif (config.get("display_temps", False) == "true"):
        air = "--"
        if data.get("ATMP"):
            air = data["ATMP"]
            air = int(float(air) + 0.5)
        water = "--"
        if data.get("WTMP"):
            water = data["WTMP"]

        if (t_unit_pref == "C"):
            water = FtoC(water)
            air = FtoC(air)

        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Air:%s°%s" % (air, t_unit_pref),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Water : %s°%s" % (water, t_unit_pref),
                            color = "#1166FF",
                        ),
                    ],
                ),
            ),
        )

        # MISC ################################################################
        # DEW with PRES with ATMP    or  TIDE with WTMP with SAL  or

    elif (config.get("display_misc", False) == "true"):
        if "TIDE" in data:  # do some tide stuff, usually wtmp is included and somties SAL?
            water = "--"
            if data.get("WTMP"):
                water = data["WTMP"]

            if (t_unit_pref == "C"):
                water = FtoC(water)

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Tide: %s %s" % (data["TIDE"], "ft"),
                                #font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Water : %s°%s" % (water, t_unit_pref),
                                color = "#1166FF",
                            ),
                        ],
                    ),
                ),
            )
        if data.get("DEW") or data.get("VIS"):
            lines = list()  # start with at least one blank
            if data.get("DEW"):
                dew = data["DEW"]
                if (t_unit_pref == "C"):
                    dew = FtoC(dew)

                lines.append("DEW: " + data["DEW"] + t_unit_pref)

            if data.get("VIS"):
                vis = data["VIS"]
                lines.append("VIS: " + vis)
                #debug_print("doing vis")

            if data.get("PRES"):
                lines.append("PRES: " + data["PRES"])

            if len(lines) < 2:
                lines.append("")
            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = lines[0],
                                #font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = lines[1],
                                color = "#1166FF",
                            ),
                        ],
                    ),
                ),
            )
        else:
            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Nothing to",
                                font = "tb-8",
                                color = "#FF0000",
                            ),
                            render.Text(
                                content = "Display",
                                color = "#FF0000",
                            ),
                        ],
                    ),
                ),
            )
    else:
        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Nothing to",
                            font = "tb-8",
                            color = "#FF0000",
                        ),
                        render.Text(
                            content = "Display",
                            color = "#FF0000",
                        ),
                    ],
                ),
            ),
        )

def get_stations(location):
    station_options = list()

    #https://www.ndbc.noaa.gov/rss/ndbc_obs_search.php?lat=20.8911&lon=-156.5047
    loc = json.decode(location)  # See example location above.
    url = "https://www.ndbc.noaa.gov/rss/ndbc_obs_search.php?lat=%s&lon=%s" % (loc["lat"], loc["lng"])

    #debug_print(url)
    resp = http.get(url)
    if resp.status_code != 200:
        return []
    else:
        # channel/item/title
        # parse Station KLIH1 - 1615680 - KAHULUI, KAHULUI HARBOR, HI

        rss_titles = xpath.loads(resp.body()).query_all("/rss/channel/item/title")

        #debug_print(rss_titles)
        for rss_title in rss_titles:
            matches = re.match(r"Station\ (\w+) \-\s+(.+)$", rss_title)

            #debug_print(matches)
            if len(matches) > 0:
                #debug_print(matches[0][1] + " : " ,matches[0][0] )#+ matches[2])
                station_options.append(
                    schema.Option(
                        display = matches[0][0],
                        value = matches[0][1],
                    ),
                )
    return station_options

def get_schema():
    h_unit_options = [
        schema.Option(display = "feet", value = "feet"),
        schema.Option(display = "meters", value = "meters"),
    ]
    t_unit_options = [
        schema.Option(display = "C", value = "C"),
        schema.Option(display = "F", value = "F"),
    ]

    #    stations_list = get_stations(default_location)
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "local_buoy_id",
                name = "Local Buoy",
                icon = "monument",
                desc = "Location Based Buoys",
                handler = get_stations,
            ),
            schema.Text(
                id = "buoy_id",
                name = "Buoy ID - optional",
                icon = "monument",
                desc = "",
            ),
            schema.Toggle(
                id = "display_swell",
                name = "Display Swell",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "display_wind",
                name = "Display Wind",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "display_temps",
                name = "Display Temperatures",
                icon = "gear",
                desc = "if available",
                default = True,
            ),
            schema.Toggle(
                id = "display_misc",
                name = "Display Misc.",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Dropdown(
                id = "h_units",
                name = "Height Units",
                icon = "quoteRight",
                desc = "Wave height units preference",
                options = h_unit_options,
                default = "feet",
            ),
            schema.Dropdown(
                id = "t_units",
                name = "Temperature Units",
                icon = "quoteRight",
                desc = "C or F",
                options = t_unit_options,
                default = "F",
            ),
            schema.Text(
                id = "min_size",
                name = "Minimum Swell Size",
                icon = "water",
                desc = "Only display if swell is above minimum size",
                default = "",
            ),
            schema.Text(
                id = "buoy_name",
                name = "Custom Display Name",
                icon = "user",
                desc = "Leave blank to use NOAA defined name",
                default = "",
            ),
        ],
    )
