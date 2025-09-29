"""
Applet: NOAA Buoy
Summary: Display buoy weather data
Description: Display swell,wind,temperature,misc data for user specified buoy. Find buoy_id's here : https://www.ndbc.noaa.gov/obs.shtml
Author: tavdog
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

print_debug = True

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

def swell_over_threshold(thresh, units, data, use_wind_swell):  # assuming threshold is already in preferred units
    if use_wind_swell:
        height = data.get("WIND_WVHT", "0")
    else:
        height = data.get("WVHT", "0")
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
    url = "https://www.ndbc.noaa.gov/mobile/station.php?station=%s" % buoy_id.lower()
    debug_print("url: " + url)
    resp = http.get(url, ttl_seconds = 600)  # 10 minutes http cache time
    debug_print(resp)
    if resp.status_code != 200 or "Invalid Station ID" in resp.body():
        if len(last_data) != 0:
            if "stale" not in last_data:
                last_data["stale"] = 1
            else:
                last_data["stale"] = last_data["stale"] + 1
            debug_print("stale counter to :" + str(last_data["stale"]))
            return last_data
        elif resp.status_code == 404:
            data["name"] = buoy_id
            data["error"] = "No Data"
            return data
        elif "Invalid Station ID" in resp.body():
            data["name"] = buoy_id
            data["error"] = "Invalid Station"
            return data
        else:
            data["name"] = buoy_id
            data["error"] = "Code: " + str(resp.status_code)
            return data

    html = resp.body()
    data["name"] = buoy_id  # fallback, no name in mobile page

    # Weather Conditions section (Starlark re does not support DOTALL, so do manual search)
    weather_start = html.find("<h2>Weather Conditions</h2>")
    weather_p_start = html.find("<p>", weather_start)
    weather_p_end = html.find("</p>", weather_p_start)
    if weather_start != -1 and weather_p_start != -1 and weather_p_end != -1:
        weather = html[weather_p_start + 3:weather_p_end]

        # Seas (WVHT)
        seas = re.match(r".*<b>Seas:</b> ([0-9.]+) ft.*", weather)
        if len(seas) > 0:
            data["WVHT"] = seas[0][1]

        # Peak Period (DPD)
        peak = re.match(r".*<b>Peak Period:</b> ([0-9.]+) sec.*", weather)
        if len(peak) > 0:
            data["DPD"] = peak[0][1]

        # Water Temp (WTMP)
        wtmp = re.match(r".*<b>Water Temp:</b> ([0-9.]+) &#176;F.*", weather)
        if len(wtmp) > 0:
            data["WTMP"] = wtmp[0][1]

        # Air Temp (ATMP)
        atmp = re.match(r".*<b>Air Temp:</b> ([0-9.]+) &#176;F.*", weather)
        if len(atmp) > 0:
            data["ATMP"] = atmp[0][1]

    # Wave Summary section
    wave_start = html.find("<h2>Wave Summary</h2>")
    wave_p_start = html.find("<p>", wave_start)
    wave_p_end = html.find("</p>", wave_p_start)
    wave_summary_found = False
    if wave_start != -1 and wave_p_start != -1 and wave_p_end != -1:
        wave_summary_found = True
        wave = html[wave_p_start + 3:wave_p_end]

        # Swell (WVHT, override if present)
        swell_match = re.match(r"<b>Swell:</b> ([0-9.]+) ft", wave)
        if len(swell_match) > 0:
            data["WVHT"] = swell_match[0][1]

        # Parse periods and directions by splitting on <br> and matching each line
        lines = wave.split("<br>")
        swell_period = None
        swell_dir = None
        wind_wave = None
        wind_period = None
        wind_dir = None
        for i in range(len(lines)):
            line = lines[i].strip()

            # Swell period
            m = re.match(r"<b>Period:</b> ([0-9.]+) sec", line)
            if m and swell_period == None:
                swell_period = m[0][1]

            # Swell direction
            m = re.match(r"<b>Direction:</b> ([A-Z]+)", line)
            if m and swell_dir == None:
                swell_dir = m[0][1]

            # Wind wave
            m = re.match(r"<b>Wind Wave:</b> ([0-9.]+) ft", line)
            if m:
                wind_wave = m[0][1]

            # Wind period (after wind wave)
            if wind_wave != None and wind_period == None:
                m = re.match(r"<b>Period:</b> ([0-9.]+) sec", line)
                if m:
                    wind_period = m[0][1]

            # Wind direction (after wind period)
            if wind_period != None and wind_dir == None:
                m = re.match(r"<b>Direction:</b> ([A-Z]+)", line)
                if m:
                    wind_dir = m[0][1]

        if swell_period:
            data["DPD"] = swell_period
        if swell_dir:
            data["MWD"] = swell_dir
        if wind_wave:
            data["WIND_WVHT"] = wind_wave
        if wind_period:
            data["WIND_DPD"] = wind_period
        if wind_dir:
            data["WIND_MWD"] = wind_dir

    # Wind Wave (not mapped, but could be added)
    # Air Temp (not present in mobile page)
    # Wind Speed, Gust, Direction (not present in mobile page)

    # Fallback to last_data for missing fields
    # If Wave Summary section was not found, mark data as stale and use last_data for swell fields
    if not wave_summary_found and len(last_data) != 0:
        if "stale" not in data:
            data["stale"] = 1
        else:
            data["stale"] = data["stale"] + 1
        debug_print("Wave Summary missing, using last data. Stale counter: " + str(data.get("stale", 0)))

        # Use last_data for swell-related fields when wave summary is missing
        for k in ["WVHT", "DPD", "MWD", "WIND_WVHT", "WIND_DPD", "WIND_MWD"]:
            if k not in data or data[k] == None:
                data[k] = last_data.get(k)

    # General fallback for all fields
    for k in ["WVHT", "DPD", "MWD", "WTMP", "WIND_WVHT", "WIND_DPD", "WIND_MWD"]:
        if k not in data or data[k] == None:
            data[k] = last_data.get(k)

    return data

def main(config):
    debug_print("##########################")
    data = dict()

    buoy_id = config.get("buoy_id", "")

    if buoy_id == "none" or buoy_id == "":  # if manual input is empty load from local selection
        local_selection = config.get("local_buoy_id", '{"display": "Station 51213 - South Lanai", "value": "51213"}')  # default is Waimea
        local_selection = json.decode(local_selection)
        if "value" in local_selection:
            buoy_id = local_selection["value"]
        else:
            buoy_id = "51213"

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
            if "stale" in data and data["stale"] > 2:
                debug_print("expring stale cache")

                # Custom cacheing determines if we have very stale data. Can't use http cache
                cache.set(cache_key, json.encode(data), ttl_seconds = 1)  # 1 sec expire almost immediately
            else:
                debug_print("Setting cache with : " + str(data))

                # Custom cacheing determines if we have very stale data. Can't use http cache
                cache.set(cache_key, json.encode(data), ttl_seconds = 1800)  # 30 minutes, should never actually expire because always getting re set

                # Custom cacheing determines if we have very stale data. Can't use http cache
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
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Text(
                            content = "Buoy:" + str(buoy_id),
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

    elif (data.get("DPD") and config.bool("display_swell", True)):
        # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
        show_wind_swell = config.bool("wind_swell", False)
        use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
        if use_wind:
            height = data["WIND_WVHT"]
            period = data["WIND_DPD"]
            mwd = data.get("WIND_MWD", "--")
        else:
            height = data["WVHT"]
            period = data["DPD"]
            mwd = data.get("MWD", "--")
        if type(height) == type(""):
            if height.replace(".", "", 1).isdigit():
                height_f = float(height)
            else:
                height_f = 0.0
        else:
            height_f = float(height)
        if (height_f < 2):
            swell_color = color_small
        elif (height_f < 5):
            swell_color = color_medium
        elif (height_f < 12):
            swell_color = color_big
        elif (height_f >= 13):
            swell_color = color_huge

        unit_display = "f"
        if h_unit_pref == "meters":
            unit_display = "m"

            # Only convert if height is a number
            if type(height) == type("") and height.replace(".", "", 1).isdigit():
                height = float(height) / 3.281
                height = int(height * 10)
                height = height / 10.0
            elif type(height) != type(""):
                height = float(height) / 3.281
                height = int(height * 10)
                height = height / 10.0

        wtemp = ""
        if (data.get("WTMP") and config.bool("display_temps", True)):
            wt = data["WTMP"]
            if (t_unit_pref == "C"):
                wt = FtoC(wt)
            wt = int(float(wt) + 0.5)
            wtemp = " %s%s" % (str(wt), t_unit_pref)

        if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
            return []

        period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)
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
                            content = "%s%s %ss" % (height, unit_display, period_display),
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

    elif (data.get("WSPD") and data.get("WDIR") and config.bool("display_wind", True)):
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

    elif (config.bool("display_temps", False)):
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

    elif (config.bool("display_misc", False)):
        # MISC ################################################################
        # DEW with PRES with ATMP    or  TIDE with WTMP with SAL  or
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
            # Even if no misc data, check if we have swell data to display instead of "Nothing to Display"

        elif data.get("DPD"):
            # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
            show_wind_swell = config.bool("wind_swell", False)
            use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
            if use_wind:
                height = data["WIND_WVHT"]
                period = data["WIND_DPD"]
                mwd = data.get("WIND_MWD", "--")
            else:
                height = data["WVHT"]
                period = data["DPD"]
                mwd = data.get("MWD", "--")
            if type(height) == type(""):
                if height.replace(".", "", 1).isdigit():
                    height_f = float(height)
                else:
                    height_f = 0.0
            else:
                height_f = float(height)
            if (height_f < 2):
                swell_color = color_small
            elif (height_f < 5):
                swell_color = color_medium
            elif (height_f < 12):
                swell_color = color_big
            elif (height_f >= 13):
                swell_color = color_huge

            unit_display = "f"
            if h_unit_pref == "meters":
                unit_display = "m"

                # Only convert if height is a number
                if type(height) == type("") and height.replace(".", "", 1).isdigit():
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0
                elif type(height) != type(""):
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0

            wtemp = ""
            if (data.get("WTMP") and config.bool("display_temps", True)):
                wt = data["WTMP"]
                if (t_unit_pref == "C"):
                    wt = FtoC(wt)
                wt = int(float(wt) + 0.5)
                wtemp = " %s%s" % (str(wt), t_unit_pref)

            if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
                return []

            period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)

            # Add stale indicator if data is stale
            buoy_display_name = buoy_name
            if "stale" in data and data["stale"] > 0:
                buoy_display_name = buoy_name + "*"

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_display_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s%s %ss" % (height, unit_display, period_display),
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
        # Check if we have swell data to display instead of "Nothing to Display"
        if data.get("DPD"):
            # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
            show_wind_swell = config.bool("wind_swell", False)
            use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
            if use_wind:
                height = data["WIND_WVHT"]
                period = data["WIND_DPD"]
                mwd = data.get("WIND_MWD", "--")
            else:
                height = data["WVHT"]
                period = data["DPD"]
                mwd = data.get("MWD", "--")
            if type(height) == type(""):
                if height.replace(".", "", 1).isdigit():
                    height_f = float(height)
                else:
                    height_f = 0.0
            else:
                height_f = float(height)
            if (height_f < 2):
                swell_color = color_small
            elif (height_f < 5):
                swell_color = color_medium
            elif (height_f < 12):
                swell_color = color_big
            elif (height_f >= 13):
                swell_color = color_huge

            unit_display = "f"
            if h_unit_pref == "meters":
                unit_display = "m"

                # Only convert if height is a number
                if type(height) == type("") and height.replace(".", "", 1).isdigit():
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0
                elif type(height) != type(""):
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0

            wtemp = ""
            if (data.get("WTMP") and config.bool("display_temps", True)):
                wt = data["WTMP"]
                if (t_unit_pref == "C"):
                    wt = FtoC(wt)
                wt = int(float(wt) + 0.5)
                wtemp = " %s%s" % (str(wt), t_unit_pref)

            if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
                return []

            period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)

            # Add stale indicator if data is stale
            buoy_display_name = buoy_name
            if "stale" in data and data["stale"] > 0:
                buoy_display_name = buoy_name + "*"

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_display_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s%s %ss" % (height, unit_display, period_display),
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
                id = "wind_swell",
                name = "Display Wind Swell",
                desc = "instead of ground swell.",
                icon = "gear",
                default = False,
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
