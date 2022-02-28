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
load("xpath.star", "xpath")
load("re.star","re")

def name_from_rss(xml):
    #re/Station\s+.*\s+\-\s+(.+),/
    string = xml.query("/rss/channel/item/title")
    name_match = re.match(r'Station\s+.*\s+\-\s+(.+),', string)
    if len(name_match) == 0:
        #try again
        name_match = re.match(r'Station\s+.*\s+\-\s+(.+)$', string)
        if len(name_match) == 0:
            return None
        else:
            return name_match[0][1]    
            
    else:
        return name_match[0][1]    

def fetch_data(buoy_id):
    data = dict()
    #url = "https://wildc.net/wind/noaa_buoy_api.pl?buoy_id=%s" % buoy_id
    url = "https://www.ndbc.noaa.gov/data/latest_obs/%s.rss" % buoy_id
    resp = http.get(url)
    if resp.status_code != 200:
        #fail("request failed with status %d", resp.status_code)
        data['name'] = buoy_id
        data['error'] = "ID not valid"
        return data
    else:
        data['name'] = name_from_rss(xpath.loads(resp.body())) or buoy_id
        #print_rss(xpath.loads(resp.body()))
        data_string = xpath.loads(resp.body()).query("/rss/channel/item/description")
        #data_string = xpath.loads(xml).query("/rss/channel/item/description")
        # continue with parsing build up the list
        re_dict = dict()
        
        # coordinates, not used for anything yet
        re_dict['location'] = r'Location:</strong>\s+(.*)<b'

        # swell data
        re_dict['WVHT'] = r'Significant Wave Height:</strong> (\d+\.?\d+?) ft<br'
        re_dict['DPD'] = r'Dominant Wave Period:</strong> (\d+) sec'
        re_dict['MWD'] = r'Mean Wave Direction:</strong> ([ENSW]+ \(\d+)&#176;'
        # wind data
        re_dict['WSPD'] = r'Wind Speed:</strong>\s+(\d+\.?\d+?)\sknots'
        re_dict['GST'] = r'Wind Gust:</strong>\s+(\d+\.?\d+?)\sknots'
        re_dict['WDIR'] = r'Wind Direction:</strong> ([ENSW]+ \(\d+)&#176;'
        # temperatures
        re_dict['ATMP'] = r'Air Temperature:</strong> (\d+\.\d+?)&#176;F'
        re_dict['WTMP'] = r'Water Temperature:</strong> (\d+\.\d+?)&#176;F'
        # misc other data
        re_dict['DEW'] = r'Dew Point:</strong> (\d+\.\d+?)&#176;F'
        re_dict['VIS'] = r'Visibility:</strong>  (\d\.?\d? nmi)'
        re_dict['TIDE'] = r'<strong>Tide:</strong> (-?\d+\.\d+?) ft'


        for field in re_dict.items():
            #print(field[0],end='')
            #print(field[1])

            field_data = re.match(field[1], data_string)
            if len(field_data) == 0:
                #print(field[0] + "  : no match")
                None
            else:
                #print(field[0] + " : " + field_data[0][1])
                
                data[field[0]] = field_data[0][1].replace('(','')
        print(data)
    return data

def main(config):

    data = dict()
    # colors based on swell size
    color_small = "#00AAFF"  #blue
    color_medium = "#AAEEDD"  #cyanish
    color_big = "#00FF00"  #green
    color_huge = "#FF0000"  # red
    swell_color = color_medium

    buoy_id = config.get("buoy_id", "51201")
    buoy_name = config.get("buoy_name", "")
    h_unit_pref = config.get("h_units", "feet")
    t_unit_pref = config.get("t_units","F")
    min_size = config.get("min_size", "")
    cache_key = "noaa_buoy_%s" % (buoy_id)
    cache_str = cache.get(cache_key)  #  not actually a json object yet, just a string
    if cache_str != None:
        data = json.decode(cache_str)
    #data = '{"name":"Pauwela", "height": "25.0", "period": "25", "direction": "SSE 161"}'   # test swell
    #data = '{"error" : "bad parse"}'   # test error
    if len(data) == 0:
        data = fetch_data(buoy_id)
        if data != None:
            cache.set(cache_key, json.encode(data), ttl_seconds = 600)  # 10 minutes

    if buoy_name == "" and "name" in data:
        print("setting buoy_name to : " + data["name"])
        buoy_name = data["name"]

        # trim to max width of 14 chars or two words
        if len(buoy_name) > 14:
            buoy_name = buoy_name[:13]
            buoy_name = buoy_name.strip()
    #SWELL###########################################################
    height = ""
    if ('DPD' in data and 'WVHT' in data) and config.get("display_swell",True) == "true":
        print("in display swell for " + data["name"])
        height = float(data['WVHT'])
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
        if "WTMP" in data and config.get("display_temps") == "true":
            wt = data["WTMP"]
            wt = int(float(wt) + 0.5)
            wtemp = " %s%s" % (str(wt),t_unit_pref)

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
                            content = "%s°%s" % (data["MWD"],wtemp),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
    #WIND#################################################
    elif 'WSPD' in data and 'WDIR' in data and config.get("display_wind",False) == "true":
        gust = ""
        avg = data["WSPD"]
        avg = int(avg * 10)
        avg = avg / 10.0
        if "GST" in data:
            gust = "g" + data["GST"]
            gust = data["WSPD"]
            gust = int(gust * 10)
            gust = gust / 10.0


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
                            content = "%s%s kts" % (avg,gust),
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s°" % (data["WDIR"]),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
    #TEMPS#################################################
    elif ('ATMP' in data or 'WTMP' in data) and config.get("display_temps",False) == "true":
        air = "--"
        if "ATMP" in data:
            air = data["ATMP"]
        water = "--"
        if "WTMP" in data:
            water = data["WTMP"]

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
                            content = "Air : %s°%s" % (air,t_unit_pref),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Water : %s°%s" % (water,t_unit_pref),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
    elif "error" in data:  # if we have error key, then we got no good swell data, display the error
        print("buoy_id: " + str(buoy_id))
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
                            color = "#FF0000"
                        ),
                        render.Text(
                            content = data["error"],
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
                            content = buoy_id,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Nothing to",
                            font = "tb-8",
                            color = "#FF0000"
                        ),
                        render.Text(
                            content = "Display",
                            color = "#FF0000",
                        ),
                    ],
                ),
            ),
        )

def get_schema():
    h_unit_options = [
        schema.Option(display = "feet", value = "feet"),
        schema.Option(display = "meters", value = "meters"),
    ]
    t_unit_options = [
        schema.Option(display = "C", value = "C"),
        schema.Option(display = "F", value = "F"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "buoy_id",
                name = "Buoy ID",
                icon = "monument",
                desc = "Find the id of your buoy at https://www.ndbc.noaa.gov/obs.shtml?pgm=IOOS%20Partners",
            ),
            schema.Toggle(
                id = "display_swell",
                name = "Display Swell",
                desc = "if available",
                icon = "cog",
                default = True,
            ),
            schema.Toggle(
                id = "display_wind",
                name = "Display Wind",
                desc = "if available",
                icon = "cog",
                default = True,
            ),
            schema.Toggle(
                id = "display_temps",
                name = "Display Temperatures",
                icon = "cog",
                desc = "if available",
                default = False,
            ),
            schema.Toggle(
                id = "display_misc",
                name = "Display Misc.",
                desc = "if available",
                icon = "cog",
                default = False,
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
                icon = "poll",
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


# test rss data here
xml = """<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="/rss/ndbcrss.xsl"?>
<rss version="2.0" xmlns:georss="http://www.georss.org/georss" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>NDBC - Station 42002 - WEST GULF - 207 NM East of Brownsville, TX Observations</title>
    <description><![CDATA[This feed shows recent marine weather observations from Station 42002.]]></description>
    <link>https://www.ndbc.noaa.gov/</link>
    <pubDate>Sun, 27 Feb 2022 11:35:47 +0000</pubDate>
    <lastBuildDate>Sun, 27 Feb 2022 11:35:47 +0000</lastBuildDate>
    <ttl>30</ttl>
    <language>en-us</language>
    <managingEditor>webmaster.ndbc@noaa.gov (NDBC Webmaster)</managingEditor>
    <webMaster>webmaster.ndbc@noaa.gov (NDBC Webmaster)</webMaster>
    <image>
      <url>https://www.ndbc.noaa.gov/images/noaa_nws_xml_logo.gif</url>
      <title>NDBC - Station 42002 - WEST GULF - 207 NM East of Brownsville, TX Observations</title>
      <link>https://www.ndbc.noaa.gov/</link>
    </image>
    <atom:link href="https://www.ndbc.noaa.gov/data/latest_obs/42002.rss" rel="self" type="application/rss+xml" />
    <item>
      <pubDate>Sun, 27 Feb 2022 11:35:47 +0000</pubDate>
      <title>Station 42002 - WEST GULF - Brownsville, TX</title>
      <description><![CDATA[
        <strong>February 27, 2022 5:20 am CST</strong><br />
        <strong>Location:</strong> 26.055N 93.646W<br />
        <strong>Wind Direction:</strong> NNW (340&#176;)<br />
        <strong>Wind Speed:</strong> 9.7 knots<br />
        <strong>Wind Gust:</strong> 11.7 knots<br />
        <strong>Atmospheric Pressure:</strong> 30.16 in (1021.2 mb)<br />
        <strong>Air Temperature:</strong> 73.2&#176;F (22.9&#176;C)<br />
        <strong>Dew Point:</strong> 72.3&#176;F (22.4&#176;C)<br />
        <strong>Water Temperature:</strong> 73.9&#176;F (23.3&#176;C)<br />
        <strong>Tide:</strong> -0.31 ft<br />
        <strong>Significant Wave Height:</strong> 8.2 ft<br />
        <strong>Dominant Wave Period:</strong> 15 sec<br />
        <strong>Average Period:</strong> 8.9 sec<br />
        <strong>Mean Wave Direction:</strong> NNW (327&#176;) <br />
      ]]></description>
      <link>https://www.ndbc.noaa.gov/station_page.php?station=42002</link>
      <guid isPermaLink="false">NDBC-42002-20220227112000</guid>
      <georss:point>26.055 -93.646</georss:point>
    </item>
  </channel>
</rss>"""
