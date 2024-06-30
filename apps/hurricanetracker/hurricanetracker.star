"""
Applet: HurricaneTracker
Summary: Hurricane Tracking Info
Description: Displays the latest information from NHC on the nearest tropical item.
Author: Robert Ison
"""

load("cache.star", "cache")  #Caching
load("encoding/base64.star", "base64")  #Used to read encoded image
load("encoding/json.star", "json")
load("http.star", "http")  #HTTP Client
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")  #XPath Expressions to read XML RSS Feed

#Constants
BASIN_URLS = {
    "atlantic": "https://www.nhc.noaa.gov/index-at.xml",
    "eastern_pacific": "https://www.nhc.noaa.gov/index-ep.xml",
    "central_pacific": "https://www.nhc.noaa.gov/index-cp.xml",
}
DEFAULT_LOCATION = """
{
	"lat": "28.53985",
	"lng": "-81.38380",
	"description": "Orlando, FL, USA",
	"locality": "Orlando",
	"place_id": "???",
	"timezone": "America/New_York"
}
"""

# Animations - list of base64 encoded images
TROPICAL_STORM_ANIMATION = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAABbtAAAW7QG3yuVvAAAAB3RJTUUH5gQaBAYqTAWFiAAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAACf0lEQVQ4y3WRX0hTYRjGn2/n7Gw7zaw5coYXTkG9SMiCSbNIpKBNFhiIM/pDiRmVmIQoqRiE0EXkRRIVKBaGxoLqIhXKpCxCiZQUBRUVFHNuc/4d287O+bqQ6XZW79X3Pd/3/Hje9yWQ1WznCxhLLoPSStLwyGwUwJ52gy0d8WvTRKJQ7EOAprG+xTNKb9thZv09wT+K9lbz54ZyugZYQ75XYveIRIkUwYtcbrUVRHIoRdFpFLeC9r1rDBs2PbZYUNHTg8H2jlTzYPz4DzZJBSoBBMiRnJ7u9PljCefLp8L/F5wrSE7UISpBsP9N0tEB7fAoo08EpB1dTUUYGMFjJ4stD2rt96xXm9HdVgUA0QB746uvXVzGiUhzdG9Ac9xsS1VlcUXw13dwR3K3AR8cL7E0PJ91U533288oIy0iACZS2C8FxEaDN/N22dlpAFAAQEHRJXRyGWaZeRJ1JhZAPIBgWPQqOMbp9l0I3xXhg8CqTLLADwEAdaZ1AL27MsGiUmONAcRJfvlKawEATUN6AAWRDyylvhiANuTrk800FU1DFIArcg4MKA7SoCMK0P36OTrVHe/SAy75YmJKRag/iRd7ogDW4msgdz9uNdBRS7Kw5gdR/HeNdm75841bJTMxLZw6VIiL92t665mxLMvW5JRaCsncBHmMZ6z1jr4wUt0BfBp7CwAozyR/jhtUpdnC0vJ2EgKOijATz3j/gYmT5dU/g5vu1V3s1LMn1yc2WPcENHHTIp/dF9JZl6FO24QSoCJM8FJbQqCmPsP3lOSXbMi7ItPf+nVtX+bKRkRtEedbN5KQEOJ5DcNr+RmbnjpsV2zthGhcK3ML0KUkx4zlL1id64Cem2W0AAAAAElFTkSuQmCC"
HURRICANE_ANIMATION = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAABbtAAAW7QG3yuVvAAAAB3RJTUUH5gQaBAgACT1h0AAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAACVklEQVQ4y42RX0hTYRjGn2/n7Gw7zf5MyS28cA2cFwlZoDSLRAraYoGBOKM/lJhRiUmIEYpBN13lRRIhOCwMjQXVRZtQNkojjEhJWZGigrLcdE6Xjm1n53xdyMw5S5+r73t5nx/v+7wE6zTR9Rj6igugtJY03TfpBbDH58BWDkXUBpHIZDsRpQY27D0hD9r3M6FXBBuI9tTzpz8Xdvex2pKgxG4TiRzZQhBF3EI7iOSQi6JPLy7HbNsXGTZhemA2o8blwkBH517TwA7PJ1anAJUAAhRKvoAzZ+pQ+pnq0UT/tG8eWZkaJE0Qcz/XHexTDw4zGZmAtFpXUhFaRgjYiLf13i3bHculFjjtdQCQDLA1P/3QzRmPrDUn7wa0pE201tWW18S+fgR3oGgF8NrxBDODU3nXlMXfIowc/9MuKSo2a4O5N6pOjQGADABOlp1HF2c0bWYGgKCMY3xz4bOJvyzxEFhFAbYkAq9cZUkBpEkRgi2KpTScAlDHw73rMt1QDCj20JgjCeB81oYuZefLnOgsNoMoCI3oeNGVBLCUXwa5/Wa5iQ6bs4TFCIjsn2e0cf53V69XjKescGxfKc7dbehpZEbyzMs/R5VSPCW8YiYw0n4zo3RtdRXwduQFAKA6l/w6rFVU5gsz/pVJCDgqwkQCHvfu70er67/EluYW/mJH2x5e+RFiAx6o1GMin98b11j8UBqWIAeoiAIEqTU92tBoDD8iJRW/U4461u/W2N9PVg2J6jIuHNKTuBDneRXDq/lxawZ1WC9aOwhRzc5PTkOTnZUSyx+Njd99IfHU5wAAAABJRU5ErkJggg=="
NHC_ICON = "iVBORw0KGgoAAAANSUhEUgAAABEAAAAQCAYAAADwMZRfAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAABbtAAAW7QG3yuVvAAAAB3RJTUUH5gQZEzQr3a77dAAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAADQ0lEQVQ4y3WSbUxTdxTGn/O/t1ygtNJWZqRh1dZNXoLEL0pYdGbJEDIliyOC2wyLiSUGtxjf2CSGLy6LL9lIZoDBFqZMRJ1ubHWLMSw0MjVmsjk7izKcEKCBonS0Bdre+//vAxWSiefrec7vnDznoaPNXajeuQEAsGFno2TkOqsvGP5gZDRUHJji2TFNRYoiT5sMUneOw9x6t/fJtw87D8wQk8X2/afQeqIChHg5D7VZbvw1un/EH/owOKOBQKB4l5MAOAHQkGFJ+SdzmXmvq774R9JZtcb2X2YhJZXNSz0PxxtHA9ESVQOICIDAQiUEIVlBLNdhqna37q4jIsFcVzoZ16KvBMKxkqgm4tsXBgAAYwKJCbLXrFeuEZEAABb09fF9VRu/W+WwVJr1uqh4/jwAQGZicseml8u+/8L52zH331tqr/Za2AW5wOCNRERXa1WT1ayvVnQ0vdAwkQZBhFyH+cuPD5T2vvGNp+K0J3ixa0RbxgaDuHHOG9kGAD0de+psi1PaGT0L0YQMYyIFfm17v2ZXR99q77h62DMeQ2qyvI71jGs5f/h5w+std94BANfnb+2zWvSXScw7IwQgE4fVKFWdGhhbfHUg1DAY1hyQJAw/iaQzQYRQjAy3/drJ4tPeKpvdNpHxOLg102ZsViSAc4IsEbIyDM1rnG+m11wacj8KirVqPB0GmRRmX0QxjQP/xii1czB8Mq/+95uFde+V91zas/ft11bkv2TVHc9fkbL13cqifkHS5mmV7CqPP1AAio76aF3LnxeuDcVK55IlABkCNiOQl5bYXZSVWnvm7uT64YnIR/0BNUFIbE5nUjg2Zpry5TwLnbgzitJJdd7E1CTw7LSk9jDkwSPusbPDIf6CNmvMnFGMAJNCl8d8/vtUeLafqdGpr7uHo9ujfP4aPA0MEfD/bwlgSTKm1qbLZT9sW+ViV8rt/NXlhhq7UfqZwGf1FF/FngWQABYlENZnJHzSUZ7701M5AKD9ni+t6Za//rpPLZ3Rnp9YaxKfKcvR7/60KOsrAEDF+VnIsesDOFhgAwDU3XxUft4Tcj6YiKx5HCG9gIAiQSxNloZeTOQtbufKz4j0gV2ue2jYlA0A+A+C/VhVky79jQAAAABJRU5ErkJggg=="
NHC_COLOR_MAIN = "#003087"
NHC_COLOR_ALT = "#0085ca"
CACHE_TTL = 60 * 60 * 1  #1 Hour
DEBUG_MODE = False  #Set to False before final commit
BASIN_OPTIONS = [
    schema.Option(value = "atlantic", display = "Atlantic Basin"),
    schema.Option(value = "eastern_pacific", display = "Eastern Pacific Basin"),
    schema.Option(value = "central_pacific", display = "Central Pacific Basin"),
]

scroll_speed_options = [
    schema.Option(
        display = "Slow",
        value = "60",
    ),
    schema.Option(
        display = "Medium",
        value = "45",
    ),
    schema.Option(
        display = "Fast",
        value = "30",
    ),
]

def main(config):
    """ Main routine to display hurricane tracking info.

    Args:
        config: A decimal integer
    Returns:
        main display
    """

    #Get configuration Items
    basin = config.get("basin") or BASIN_OPTIONS[0].value
    hide_quiet = config.get("hide_quiet")
    location = json.decode(config.get("location", DEFAULT_LOCATION))

    #Get XML from cache
    basin_xml = cache.get(basin)

    #TEST DATA These lines should be commented out before release
    if DEBUG_MODE == False and rss_example != None:
        basin_xml = rss_example

    #If nothing from cache, then we go to nhc and download new data
    if basin_xml == None:
        rss_feed_for_selected_basin = BASIN_URLS[basin]
        res = http.get(url = rss_feed_for_selected_basin)
        if res.status_code == 200:
            basin_xml = res.body()

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(basin, basin_xml, ttl_seconds = CACHE_TTL)

    #load up the xml
    xml = xpath.loads(basin_xml)

    #How many active cyclones?
    querytext = "/rss/channel/item[nhc:Cyclone]"
    queryresult = xml.query_all(querytext)
    active_cyclone_count = len(queryresult)

    return getDisplay(active_cyclone_count, xml, hide_quiet, location, config)

def getDisplay(active_cyclone_count, xml, hide_quiet, location, config):
    """ Gets the display based on the nearest storm

    Args:
        active_cyclone_count: number of active cyclones
        xml: xml with cyclone data
        hide_quiet: boolean, if true and no storms, return nothing to skip the app
        location: location of the Tidbyt to calc direction and distance
        config: Configuration to figure out scroll speed
    Returns:
        render.root: The display info for the Tidbyt device
    """

    #default display
    querytext = "/rss/channel/title"

    #remove the extraneous "NHC" from "NHC Atlantic" for example. Makes it easier to read your Tidbyt
    row1 = xml.query(querytext).replace("NHC", "").replace("CPHC", "")
    row2 = ""
    row3 = ""
    images = [base64.decode(NHC_ICON)]

    count_of_storms_of_concern = 0

    # Load all items
    querytext = "/rss/channel/item"
    queryresult = xml.query_all(querytext)

    if active_cyclone_count == 0:
        if hide_quiet == True or hide_quiet == "true":
            return []
    else:
        i = 0
        distance_to_nearest_hurricane = -1

        # Keep track of all storms for a quick summary at the end of the nearest hurricane issue
        all_storms = []
        highlighted_storm_name = ""

        for item in queryresult:
            i = i + 1
            querytext = "/rss/channel/item[%s]/nhc:Cyclone/nhc:name" % i
            result = xml.query(querytext)

            if result != None:
                storm_name = result
                storm_type = xml.query("/rss/channel/item[%s]/nhc:Cyclone/nhc:type" % i)
                storm_movement = xml.query("/rss/channel/item[%s]/nhc:Cyclone/nhc:movement" % i)
                storm_pressure = xml.query("/rss/channel/item[%s]/nhc:Cyclone/nhc:pressure" % i)
                storm_wind = xml.query("/rss/channel/item[%s]/nhc:Cyclone/nhc:wind" % i)
                storm_headline = xml.query("/rss/channel/item[%s]/nhc:Cyclone/nhc:headline" % i)
                storm_center = xml.query("/rss/channel/item[%s]/nhc:Cyclone/nhc:center" % i)
                distance_in_miles = ""

                if storm_center != None and location != None:
                    count_of_storms_of_concern = count_of_storms_of_concern + 1

                    storm_coordinates = storm_center.replace(",", "").split(" ")
                    distance_in_miles = distance(location["lat"], location["lng"], storm_coordinates[0], storm_coordinates[1])
                    distance_in_miles_display = "%s miles " % distance_in_miles

                    #all_storms.append([[storm_name],[distance_in_miles],[storm_wind],[storm_type]])
                    all_storms.append([storm_name, distance_in_miles, storm_wind, storm_type])

                    if distance_to_nearest_hurricane < 0 or distance_in_miles < distance_to_nearest_hurricane:
                        highlighted_storm_name = storm_name

                        #This storm is the closest so far, let's update the data with this storm
                        distance_to_nearest_hurricane = distance_in_miles

                        # figure out the get_bearing -- in this case what direction the hurricane is from you:
                        bearing = get_bearing(location["lat"], location["lng"], storm_coordinates[0], storm_coordinates[1])
                        row2 = "%s %s with %s pressure and winds of %s is %s%s of you heading %s." % (storm_type, storm_name, storm_pressure, storm_wind, distance_in_miles_display, bearing, storm_movement)
                        row3 = "%s %s: %s" % (storm_type, storm_name, storm_headline)

                        if storm_type.lower() == "hurricane":
                            images = [base64.decode(HURRICANE_ANIMATION)]
                        elif storm_type == "tropical storm":
                            images = [base64.decode(TROPICAL_STORM_ANIMATION)]
                        else:
                            images = [base64.decode(NHC_ICON)]

        #row 3 now stores nearest storm warning.. let's append other storms info from nearest to furthest
        additional_info = ""
        all_storms = sorted(all_storms, key = lambda x: x[1], reverse = False)
        for item in all_storms:
            if highlighted_storm_name != item[0]:
                additional_info = additional_info + " %s %s: Winds: %s Dist: %s miles" % (item[3], item[0], item[2], item[1])

        if len(additional_info) > 0:
            row2 = row2 + " OTHER STORMS: " + additional_info
            row2 = row2.replace("  ", " ").replace("... ...", "... ")

    display_children = render.Column(
        children = [
            render.Row(
                children = [
                    render.Marquee(
                        width = 48,
                        child = render.Text(row1, color = NHC_COLOR_ALT),
                    ),
                    get_animation_items(images),
                ],
            ),
            render.Row(
                children = [
                    render.Marquee(
                        width = 64,
                        offset_start = len(row1) * 5,
                        child = render.Text(row2, color = "#fff"),
                    ),
                ],
            ),
            render.Row(
                children = [
                    render.Marquee(
                        width = 64,
                        offset_start = len(row2) * 5,
                        child = render.Text(row3, color = "#ff0"),
                    ),
                ],
            ),
        ],
    )

    return render.Root(
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
        child = render.Column(
            children = [
                display_children,
            ],
        ),
    )

def get_images_from_image_list(image_list):
    images = []
    for encoding in image_list:
        images.append(base64.decode(encoding))

    return images

def get_animation_items(images):
    animation = []
    for image in images:
        animation.append(render.Image(src = image))

    return render.Animation(
        children = animation,
    )

# buildifier: disable=function-docstring
def get_bearing(lat_1, lng_1, lat_2, lng_2):
    lat_1 = math.radians(float(lat_1))
    lat_2 = math.radians(float(lat_2))
    lng_1 = math.radians(float(lng_1))
    lng_2 = math.radians(float(lng_2))

    #Let ‘R’ be the radius of Earth,
    #‘L’ be the longitude,
    #‘θ’ be latitude,
    #‘β‘ be get_Bearing.
    #β = atan2(X,Y) where
    #X = cos θb * sin ∆L
    #Y = cos θa * sin θb – sin θa * cos θb * cos ∆L

    # buildifier: disable=integer-division
    x = math.cos(lat_2) * math.sin((lng_2 - lng_1))

    # buildifier: disable=integer-division
    y = math.cos(lat_1) * math.sin(lat_2) - math.sin(lat_1) * math.cos(lat_2) * math.cos((lng_2 - lng_1))

    # buildifier: disable=integer-division
    bearing = math.degrees(math.atan2(x, y))

    # our compass brackets are broken up in 45 degree increments from 0 8
    # to find the right bracket we need degrees from 0 to 360 then divide by 45 and round
    # what we get though is degrees -180 to 0 to 180 so this will convert to 0 to 360
    if bearing < 0:
        bearing = 360 + bearing

    # have bearning in degrees, not convert to cardinal point
    compass_brackets = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest", "North"]

    # buildifier: disable=integer-division
    display_cardinal_point = compass_brackets[int(math.round(bearing / 45))]

    return display_cardinal_point

# buildifier: disable=function-docstring
def distance(lat_1, lng_1, lat_2, lng_2):
    #Haversine Formula
    lat_1 = math.radians(float(lat_1))
    lat_2 = math.radians(float(lat_2))
    lng_1 = math.radians(float(lng_1))
    lng_2 = math.radians(float(lng_2))

    d_lat = lat_2 - lat_1
    d_lng = lng_2 - lng_1

    # buildifier: disable=integer-division
    temp = (math.pow(math.sin(d_lat / 2), 2) + math.cos(lat_1) * math.cos(lat_2) * math.pow(math.sin(d_lng / 2), 2))
    distance = 3959.9986576 * (2 * math.atan2(math.sqrt(temp), math.sqrt(1 - temp)))
    return math.floor(distance)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to calculate direction and distance to the nearest storm.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "basin",
                name = "Hurricane Basin",
                desc = "Which hurricane basin do you want to monitor?",
                icon = "globe",
                options = BASIN_OPTIONS,
                default = BASIN_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "hide_quiet",
                name = "Hide when no storms?",
                desc = "Do you want to skip displaying this app when there is nothing to report?",
                icon = "gear",
                default = True,
            ),
        ],
    )

rss_example = """
<rss xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:georss="http://www.georss.org/georss"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:nhc="http://www.nhc.noaa.gov" version="2.0">
    <channel>
        <pubDate>Thu, 30 May 2013 19:07:15 GMT</pubDate>
        <title>National Hurricane Center (Eastern Pacific)</title>
        <description>Active tropical cyclones in the Eastern Pacific</description>
        <link>http://www.nhc.noaa.gov/</link>
        <copyright>none</copyright>
        <managingEditor>nhcwebmaster@noaa.gov (nhcwebmaster)</managingEditor>
        <language>en-us</language>
        <webMaster>nhcwebmaster@noaa.gov (nhcwebmaster)</webMaster>
        <image>
            <url>http://www.nhc.noaa.gov/gifs/xml_logo_nhc.gif</url>
            <link>http://www.nhc.noaa.gov/</link>
            <title>National Hurricane Center (Eastern Pacific)</title>
            <description>NOAA logo</description>
            <width>95</width>
            <height>45</height>
        </image>
        <item>
            <title>Summary for Tropical Depression AAA (EP2/EP022013)</title>
            <guid>summary-ep022013-201305301523</guid>
            <pubDate>Thu, 30 May 2013 15:23:32 GMT</pubDate>
            <author>nhcwebmaster@noaa.gov (nhcwebmaster)</author>
            <link>http://www.nhc.noaa.gov/text/refresh/MIATCPEP2+shtml/301523.shtml</link>
            <description> ...AAA NEAR THE GULF COAST OF MEXICO BUT VERY ILL DEFINED..</description>
            <gml:Point>
                <gml:pos>18.5 -95.0</gml:pos>
            </gml:Point>
            <nhc:Cyclone>
                <nhc:center>29.3, -86.5</nhc:center>
                <nhc:type>TROPICAL STORM</nhc:type>
                <nhc:name>AAA</nhc:name>
                <nhc:wallet>AT1</nhc:wallet>
                <nhc:atcf>AL012013</nhc:atcf>
                <nhc:datetime>6:00 PM EDT Wed Jun 5</nhc:datetime>
                <nhc:movement>N at 3 mph</nhc:movement>
                <nhc:pressure>1002 mb</nhc:pressure>
                <nhc:wind>40 mph</nhc:wind>
                <nhc:headline> ...TROPICAL STORM FORMS IN THE EAST-CENTRAL GULF OF MEXICO... ...TROPICAL STORM WARNING ISSUED FOR PARTS OF THE FLORIDA WEST COAST...</nhc:headline>
            </nhc:Cyclone>
        </item>
        <item>
            <title>Summary for Tropical Depression BARBARA (EP2/EP022013)</title>
            <guid>summary-ep022013-201305301523</guid>
            <pubDate>Thu, 30 May 2013 15:23:32 GMT</pubDate>
            <author>nhcwebmaster@noaa.gov (nhcwebmaster)</author>
            <link>http://www.nhc.noaa.gov/text/refresh/MIATCPEP2+shtml/301523.shtml</link>
            <description> ...BARBARA NEAR THE GULF COAST OF MEXICO BUT VERY ILL DEFINED...  </description>
            <gml:Point>
                <gml:pos>18.5 -95.0</gml:pos>
            </gml:Point>
            <nhc:Cyclone>
                <nhc:center>25.2, -86.5</nhc:center>
                <nhc:type>TROPICAL STORM</nhc:type>
                <nhc:name>BARBARA</nhc:name>
                <nhc:wallet>AT1</nhc:wallet>
                <nhc:atcf>AL012013</nhc:atcf>
                <nhc:datetime>6:00 PM EDT Wed Jun 5</nhc:datetime>
                <nhc:movement>N at 3 mph</nhc:movement>
                <nhc:pressure>1002 mb</nhc:pressure>
                <nhc:wind>40 mph</nhc:wind>
                <nhc:headline> ...TROPICAL STORM FORMS IN THE EAST-CENTRAL GULF OF MEXICO... ...TROPICAL STORM WARNING ISSUED FOR PARTS OF THE FLORIDA WEST COAST...</nhc:headline>
            </nhc:Cyclone>
        </item>
        <item>
            <title>Summary for Tropical Depression Rob (EP2/EP022013)</title>
            <guid>summary-ep022013-201305301523</guid>
            <pubDate>Thu, 30 May 2013 15:23:33 GMT</pubDate>
            <author>nhcwebmaster@noaa.gov (nhcwebmaster)</author>
            <link>http://www.nhc.noaa.gov/text/refresh/MIATCPEP2+shtml/301524.shtml</link>
            <description> ...Rob NEAR THE GULF COAST OF MEXICO BUT VERY ILL DEFINED... ..</description>
            <gml:Point>
                <gml:pos>18.5 -90.0</gml:pos>
            </gml:Point>
            <nhc:Cyclone>
                <nhc:center>25.1, -90.5</nhc:center>
                <nhc:type>TROPICAL STORM</nhc:type>
                <nhc:name>Rob</nhc:name>
                <nhc:wallet>AT1</nhc:wallet>
                <nhc:atcf>AL012013</nhc:atcf>
                <nhc:datetime>6:00 PM EDT Wed Jun 5</nhc:datetime>
                <nhc:movement>N at 3 mph</nhc:movement>
                <nhc:pressure>1002 mb</nhc:pressure>
                <nhc:wind>40 mph</nhc:wind>
                <nhc:headline> ...TROPICAL STORM FORMS...</nhc:headline>
            </nhc:Cyclone>
        </item>
        <item>
            <title>Summary for Tropical Depression Zelda (EP2/EP022013)</title>
            <guid>summary-ep022013-201305301523</guid>
            <pubDate>Thu, 30 May 2013 15:23:33 GMT</pubDate>
            <author>nhcwebmaster@noaa.gov (nhcwebmaster)</author>
            <link>http://www.nhc.noaa.gov/text/refresh/MIATCPEP2+shtml/301524.shtml</link>
            <description> ...Zelda NEAR THE GULF COAST OF MEXICO BUT VERY ILL DEFINED... ...THREAT OF HEAVY RAINS AND FLOODING CONTINUES... As of 8:00 AM PDT Thu May 30 the center of BARBARA was located at 18.5, -95.0 with movement NW at 3 mph. The minimum central pressure was 1005 mb with maximum sustained winds of about 30 mph. </description>
            <gml:Point>
                <gml:pos>18.5 -90.0</gml:pos>
            </gml:Point>
            <nhc:Cyclone>
                <nhc:center>23.3, -79.5</nhc:center>
                <nhc:type>TROPICAL STORM</nhc:type>
                <nhc:name>Zelda</nhc:name>
                <nhc:wallet>AT1</nhc:wallet>
                <nhc:atcf>AL012013</nhc:atcf>
                <nhc:datetime>6:00 PM EDT Wed Jun 5</nhc:datetime>
                <nhc:movement>N at 3 mph</nhc:movement>
                <nhc:pressure>1002 mb</nhc:pressure>
                <nhc:wind>40 mph</nhc:wind>
                <nhc:headline> ...TROPICAL STORM FORMS IN THE EAST-CENTRAL GULF OF MEXICO... ...TROPICAL STORM WARNING ISSUED FOR PARTS OF THE FLORIDA WEST COAST...</nhc:headline>
            </nhc:Cyclone>
        </item>
    </channel>
</rss>
"""
