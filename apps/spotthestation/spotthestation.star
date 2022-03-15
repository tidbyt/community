"""
Applet: SpotTheStation
Summary: Next ISS visit overhead
Description: Displays the next time the International Space Station will appear.
Author: Robert Ison
"""

load("render.star", "render")
load("http.star", "http")  #HTTP Client
load("encoding/base64.star", "base64")  #Used to read encoded image
load("xpath.star", "xpath")  #XPath Expressions
load("cache.star", "cache")  #Caching
load("schema.star", "schema")
load("time.star", "time")

#Requires the RSS feed for your location from spotthestation.nasa.gov
#Use the map tool to find the nearest location, click the blue marker then the "View sighting opportunities"
#From this page click "RSS" to get the needed XML Feed for your location
#Pass that into this app to have the next approach to your location listed on  your Tidbyt

# Load icon from base64 encoded data
ISS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAA1ElEQVQ4y5WTOw7DIBBEhygn4ThL7T5ufYmQ82xtWt/Eck4yKQLIBvzbBgkxTzs7C1AXcaMetdgfQQ7hBDxJEvBsPKYT4R5kI25A6ESoqhyGYQNJFgzgYcwH5DufyY4TwavvMU0TAMCJZDumNYMEATxK8XdZMIaQtWbHziVxCeDqjlfE6xlQVaGqGTSG0BDXET/L/iMEANB1HZxIFv9nA8SEKvuc55mqythRiuss4i0giVcA3IakTo4g6f5RpGCstbDWtrY1L1scpjn7aHt7f+u3ntYP6dzKrlS3n+0AAAAASUVORK5CYII=
""")

def twoCharacterTimeDatePart(number):
    if len(str(number)) == 1:
        return "0" + str(number)
    else:
        return number

def twoCharacterNumericMonthFromMonthString(month):
    dict = {
        "Jan": "01",
        "Feb": "02",
        "Mar": "03",
        "Apr": "04",
        "May": "05",
        "Jun": "06",
        "Jul": "07",
        "Aug": "08",
        "Sep": "09",
        "Oct": "10",
        "Nov": "11",
        "Dec": "12",
    }

    return dict.get(month)

def getTimestampFromItem(item):
    description = item.replace("\n", "").replace("\t", "").split("<br/>")
    itemDate = description[0].replace("Date: ", "").split(" ")
    itemTime = description[1].replace("Time: ", "").split(" ")
    return itemDate[3] + "-" + twoCharacterNumericMonthFromMonthString(itemDate[1]) + "-" + twoCharacterTimeDatePart(itemDate[2].replace(",", "")) + "T" + getTimeStampTime(itemTime[0], itemTime[1]) + ":00Z"

def getTimeStampTime(time, meridiem):
    time = time.split(":")
    if meridiem == "PM":
        time[0] = int(time[0]) + 12

    return str(time[0]) + ":" + time[1]

def main(config):
    #Defaults
    location = "Invalid Location Data"
    row1 = ""
    row2 = ""
    row3 = ""

    #Get Station Selected By User
    ISS_FLYBY_XML_URL = config.get("SpotTheStationRSS") or "https://spotthestation.nasa.gov/sightings/xml_files/United_States_Florida_Orlando.xml"

    #Get the current GMT Time
    now = time.now().in_location("GMT")

    issxmlBody = cache.get(ISS_FLYBY_XML_URL)  # cache key based on url
    if issxmlBody == None:
        print("Loading New XML Data")
        issxml = http.get(ISS_FLYBY_XML_URL)
        if issxml.status_code != 200:
            print("Error Getting ISS Flyby Data")
        else:
            issxmlBody = issxml.body()
            cache.set(ISS_FLYBY_XML_URL, issxmlBody, ttl_seconds = 6000)

    else:
        print("Got XML Data From Cache")

    numberFutureSightings = issxmlBody.count("<item>")

    if issxmlBody == None:
        row1 = "Invalid Data from spotthestation.nasa.gov"
        description = None
    elif numberFutureSightings == 0:
        row1 = "The station will not appear overhead for at least several days"
        description = ""
        location = xpath.loads(issxmlBody).query("/rss/channel/description").replace("Satellite Sightings Information for ", "")
    else:
        #Find the next pass, and skip past times
        itemNumberToDisplay = 0
        for i in range(1, numberFutureSightings + 1):
            currentQuery = "//item[" + str(i) + "]/description"
            currentDescription = xpath.loads(issxmlBody).query(currentQuery)
            if time.parse_time(getTimestampFromItem(currentDescription)) > now:
                itemNumberToDisplay = i
                break

        description = xpath.loads(issxmlBody).query("/rss/channel/item[" + str(itemNumberToDisplay) + "]/description")
        location = xpath.loads(issxmlBody).query("/rss/channel/description").replace("Satellite Sightings Information for ", "")

    if description == None:
        description = "None"
        row1 = "Error getting Data from spotTheStation.nasa.gov"
    else:
        description = description.split("<br/>")
        i = 0
        for item in description:
            i += 1
            item = item.replace("\n", "").replace("\t", "")

            if (i < 2):
                row2 += item.replace("Date: ", "").replace("Monday", "Mon").replace("Tuesday", "Tue").replace("Wednesday", "Wed").replace("Thursday", "Thu").replace("Friday", "Fri").replace("Saturday", "Sat").replace("Sunday", "Sun").replace(", 20", " '")
            elif (i < 3):
                row1 += item.replace("Time: ", "")
            else:
                row3 += item.replace("Duration: ", "").replace("Maximum", "Max").replace("Departure", "Depart.").replace("minute", "min")

    return render.Root(
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Image(src = ISS_ICON),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(location, color = "#ff0"),
                                        ),
                                        render.Marquee(
                                            width = 35,
                                            child = render.Text(row1, color = "#fff"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(row2, color = "#fff"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(row3, color = "#ff0"),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "SpotTheStationRSS",
                name = "Spot the Station RSS",
                icon = "location",
                desc = "Go to spotthestation.nasa.gov Use the map tool to find the nearest location, click the blue marker then 'View sighting opportunities' then get the RSS feed URL.",
                #From this page click "RSS" to get the needed XML Feed for your location",
            ),
        ],
    )
