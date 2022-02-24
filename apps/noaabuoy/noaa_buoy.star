"""
Applet: NOAA Buoy
Summary: Display buoy wave data
Description: Display swell data for user specified buoy. Find buoy_id's here : https://www.ndbc.noaa.gov/obs.shtml Buoy must have height,period,direction to display correctly
Author: tavdog
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")

def fetch_data(buoy_id):
    url = "https://wildc.net/wind/noaa_buoy_api.pl?buoy_id=%s" % buoy_id
    resp = http.get(url)
    if resp.status_code != 200:
        #fail("request failed with status %d", resp.status_code)
        return None
    else:
        print(resp.json())
        return resp.json()

def main(config):
    # color based on swell size
    color_small = "#00AAFF"  #blue
    color_medium = "#AAEEDD"  #??
    color_big = "#00FF00"  #green
    color_huge = "#FF0000"  # red
    swell_color = color_medium

    buoy1_id = config.get("buoy_1_id", 51201)
    buoy1_name = config.get("buoy_1_name", "")
    unit_pref = config.get("units", "feet")
    min_size = config.get("min_size", "")

    cache_key = "noaa_buoy_%s" % (buoy1_id)
    buoy1_json = cache.get(cache_key)  #  not actually a json object yet, just a string

    #buoy1_json = '{"name":"Pauwela", "height": "25.0", "period": "25", "direction": "SSE 161"}'   # test swell
    #buoy1_json = '{"error" : "bad parse"}'   # test error
    if buoy1_json == None:
        buoy1_json = fetch_data(buoy1_id)
        if buoy1_json != None:
            cache.set(cache_key, str(buoy1_json), ttl_seconds = 3600)  # swell doesnt change very quickly, 1 hour should be good.
    else:
        buoy1_json = json.decode(buoy1_json)

    height = ""
    if "error" not in buoy1_json:
        height = float(buoy1_json["height"])
        if (height < 2):
            swell_color = color_small
        elif (height < 5):
            swell_color = color_medium
        elif (height < 12):
            swell_color = color_big
        elif (height >= 13):
            swell_color = color_huge

        if buoy1_name == "":
            buoy1_name = buoy1_json["name"]

            # trim to max width of 14 chars or two words
            if len(buoy1_name) > 14:
                buoy1_name = buoy1_name[:13]
                buoy1_name = buoy1_name.strip()
        height = buoy1_json["height"]
        unit_display = "f"
        if unit_pref == "meters":
            unit_display = "m"
            height = float(height) / 3.281
            height = int(height * 10)
            height = height / 10.0

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
                            content = buoy1_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s%s %ss" % (height, unit_display, buoy1_json["period"]),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s°" % (buoy1_json["direction"]),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
    else:  # if we have error key, then we got no good swell data, display the error
        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy1_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = buoy1_json["error"],
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Error",
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )

def get_schema():
    unit_options = [
        schema.Option(display = "feet", value = "feet"),
        schema.Option(display = "meters", value = "meters"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "buoy_1_id",
                name = "Buoy ID",
                icon = "monument",
                desc = "Find the id of your buoy at https://www.ndbc.noaa.gov/obs.shtml?pgm=IOOS%20Partners",
            ),
            schema.Dropdown(
                id = "units",
                name = "Height Units",
                icon = "quoteRight",
                desc = "Wave height units preference",
                options = unit_options,
                default = "feet",
            ),
            schema.Text(
                id = "min_size",
                name = "Minimum Swell Size",
                icon = "poll",
                desc = "Only display if swell is above minimum size",
                default = "",
            ),
            schema.Text(
                id = "buoy_1_name",
                name = "Custom Display Name",
                icon = "user",
                desc = "Leave blank to use NOAA defined name",
                default = "",
            ),
        ],
    )
