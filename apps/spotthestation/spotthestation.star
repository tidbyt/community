"""
Applet: SpotTheStation
Summary: Next ISS visit overhead
Description: Displays the next time the International Space Station will appear.
Author: Robert Ison
"""

load("render.star", "render")
load("http.star", "http")  #HTTP Client
load("encoding/base64.star", "base64")  #Used to read encoded image
load("xpath.star", "xpath")  #XPath Expressions to read XML RSS Feed
load("cache.star", "cache")  #Caching
load("schema.star", "schema")
load("time.star", "time")  #Used to display time and calcuate lenght of TTL cache
load("math.star", "math")  #Used to calculate duration between timestamps

#Requires the RSS feed for your location from spotthestation.nasa.gov
#Use the map tool to find the nearest location, click the blue marker then the "View sighting opportunities"
#From this page click "RSS" to get the needed XML Feed for your location
#Pass that into this app to have the next approach to your location listed on  your Tidbyt

#Note on Timezones: Since the XML feed provided could be anywhere in the world, and the feed provides no timezone information I need to calculate times without timezone information.
#So I take the display times in the XML, year, month, day, hour, minute and second and add a "Z" (Zulu) to give it a valid timestamp.
#To make sure I'm not getting timezone differences introduced to mess up my math, I use getLocalTimeStamp() which takes the current year, month, day, hour, minute and second, adds "Z" to match

#We can calculate how long we can cache the XML, but let's set a minimum cache of 5 minutes just to be sure we aren't taxing servers
#and a maximum of one week in case of bad data
MINIMUM_CACHE_TIME_IN_SECONDS = 300
MAXIMUM_CACHE_TIME_IN_SECONDS = 600000

# Load icon from base64 encoded data
ISS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAA1ElEQVQ4y5WTOw7DIBBEhygn4ThL7T5ufYmQ82xtWt/Eck4yKQLIBvzbBgkxTzs7C1AXcaMetdgfQQ7hBDxJEvBsPKYT4R5kI25A6ESoqhyGYQNJFgzgYcwH5DufyY4TwavvMU0TAMCJZDumNYMEATxK8XdZMIaQtWbHziVxCeDqjlfE6xlQVaGqGTSG0BDXET/L/iMEANB1HZxIFv9nA8SEKvuc55mqythRiuss4i0giVcA3IakTo4g6f5RpGCstbDWtrY1L1scpjn7aHt7f+u3ntYP6dzKrlS3n+0AAAAASUVORK5CYII=
""")

ISS_ICON2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQAywFUG1eCAAAANpJREFUOMuVk7uNwzAQRB+Nq4TlkLHyc6omjlfPxlaqTgS7knFgkaAk6uNNCBCch52dJWxLfFG3rTgdQQ7hgiRJgqTGY8UQtAdZiBsQxRBkZur7fgHJFhwknPtH+itnthND4Pd+ZxxHAGIIxY5rzSBDILEWv55PHsNQtG7HziXxGqDqTlfE9QxkZphZAT2GoSHeRvyz7n+GANB1HTGEIv7MBuaENvY1TZPMTPp0lOM6i3gJmO3UAC5BVEFyJ0eQfH+r4hDgvPd471vbWpZtHqY7+2h7e//Vbz2tN1RXzK3nlhc3AAAAAElFTkSuQmCC
""")

ISS_ICON3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQAywYM2sy0QAAANpJREFUOMuVk7uNwzAQRB+Nq4TlkLHyc6omjlfPxlaqTgS7knFgkaAk6uNNCBCch52dJWxLfFG3rTgdQQ7hgiRJgqTGY8UQtAdZiBsQxRBkZur7fgHJFhwknPtH+itnthND4Pd+ZxxHAGIIxY5rzSBDILEWv55PHsNQtG7HziXxGqDqTlfE9QxkZphZAT2GoSHeRvyz7n+GANB1HTGEIv7MBuaENvY1TZPMTPp0lOM6i3gJyOIKwCWIKkju5AiS729VHAKc9x7vfWtby7LNw3RnH21v77/6raf1Bocyzax1x99PAAAAAElFTkSuQmCC
""")

ISS_ICON4 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQAywoFbICfQAAANhJREFUOMulkzsOwyAQRIfIJ/Fxltp93PoSIefZ2m59E+ScZFIYEAb/omyDQMzTzg4AdRE/1KMWuzPIKZyAI0kCjjuXaUV4BNmIdyC0IlRVDsOwgUQLBnAw5g3yldZox4rg2feY5xkAYEWSHbM3gwgBHErxZ1kwTlPSmgM7t8QlgNkZ74jzGVBVoaoJNE7TjriOuCn7DxAAQNd1sCJJvM4GCAlV9um9p6qSa0cxrquIt4AozgC4BQk7eu9TJ2eQeN5kcay+2pblLLLHxjCDoydQfRz++1sv6wttM9GjkfVivgAAAABJRU5ErkJggg==
""")

ISS_ICON5 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQAyw65gtzNQAAANlJREFUOMulkztuwzAQRB+DnMTHWdbq41aXMHOera1WNyGck4wLiwT1tYxsQ5DgPOzMkrAu8UF9rcXpCHIIFyRJEiRtXFY00x5kJt6AKJrJ3dX3/QxSLARIhPCLdKtrsRPN+LleGccRgGhW7YStDAoEEkvx3+PBfRiqNuzYOSVeAtSc6Yy4zUDujrtX0H0YNsTrEX8v+58gAHRdRzSr4lc2ME1oZV85Z7m79OqojOvdiOeAIm4AnIJMO+WcaydHkHLeZqAAgctFyyyax6Ypg70nsPo4+u9vfVtPbS/Ro5V9Dx8AAAAASUVORK5CYII=
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

def getLocalTimeStamp():
    localTime = time.now()
    return str(localTime.year) + "-" + twoCharacterTimeDatePart(str(localTime.month)) + "-" + twoCharacterTimeDatePart(str(localTime.day)) + "T" + twoCharacterTimeDatePart(str(localTime.hour)) + ":" + twoCharacterTimeDatePart(str(localTime.minute)) + ":" + twoCharacterTimeDatePart(str(localTime.second)) + "Z"

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
    numberOfListedSightings = 0
    timeOfNextSighting = None
    timeOfFurthestKnownSighting = None
    location = "Invalid Location Data. You should have entered an RSS feed URL that looks like this: https://spotthestation.nasa.gov/sightings/xml_files/United_States_Florida_Orlando.xml"
    row1 = ""
    row2 = ""
    row3 = ""

    #Get Station Selected By User
    ISS_FLYBY_XML_URL = config.get("SpotTheStationRSS") or "https://spotthestation.nasa.gov/sightings/xml_files/United_States_Florida_Orlando.xml"

    #cache is saved to the tidbyt server, not locally, so we need a unique key per location which is equivelent to the Flyby XML URL
    issxmlBody = cache.get(ISS_FLYBY_XML_URL)
    setCache = False
    if issxmlBody == None:
        issxml = http.get(ISS_FLYBY_XML_URL)

        #print("Going to spotthestation.nasa.gov to get XML")
        if issxml.status_code != 200:
            print("Error Getting ISS Flyby Data")
        else:
            issxmlBody = issxml.body()

            #This XML Feed can have many sightings listed, both past and future
            #So Let's find the first future sighting and display that
            numberOfListedSightings = issxmlBody.count("<item>")
            setCache = True
    else:
        #print("Using cached XML")
        numberOfListedSightings = issxmlBody.count("<item>")

    if issxmlBody == None:
        row1 = "Invalid Data from spotthestation.nasa.gov. You should have entered an RSS feed URL that looks like this: https://spotthestation.nasa.gov/sightings/xml_files/United_States_Florida_Orlando.xml"
        description = None
    elif numberOfListedSightings == 0:
        row1 = "The station will not appear overhead for at least several days"
        description = ""
        location = xpath.loads(issxmlBody).query("/rss/channel/description").replace("Satellite Sightings Information for ", "")
    else:
        #Find the next pass, and skip past times
        itemNumberToDisplay = 0
        for i in range(1, numberOfListedSightings + 1):
            currentQuery = "//item[" + str(i) + "]/description"
            currentDescription = xpath.loads(issxmlBody).query(currentQuery)
            currentTimeStamp = getTimestampFromItem(currentDescription)
            if time.parse_time(currentTimeStamp) > time.parse_time(getLocalTimeStamp()):
                itemNumberToDisplay = i
                timeOfNextSighting = currentTimeStamp
                break

        description = xpath.loads(issxmlBody).query("/rss/channel/item[" + str(itemNumberToDisplay) + "]/description")
        location = xpath.loads(issxmlBody).query("/rss/channel/description").replace("Satellite Sightings Information for ", "")

    if (setCache == True):
        #The current XML is valid until the last known future listing
        #So let's use that to figure our cache ttl
        if (numberOfListedSightings > itemNumberToDisplay):
            #Since there are more future sightings in the current XML
            #Let's cache this XML as long as we have good data
            currentQuery = "//item[" + str(numberOfListedSightings) + "]/description"
            currentDescription = xpath.loads(issxmlBody).query(currentQuery)
            currentTimeStamp = getTimestampFromItem(currentDescription)
            timeOfFurthestKnownSighting = currentTimeStamp
            localTimeStamp = getLocalTimeStamp()
            dateDiff = time.parse_time(timeOfFurthestKnownSighting) - time.parse_time(getLocalTimeStamp())
        else:
            #No future Sightings so we can cache at least until the next sighting
            dateDiff = time.parse_time(timeOfNextSighting) - time.parse_time(getLocalTimeStamp())

        days = math.floor(dateDiff.hours / 24)
        hours = math.floor(dateDiff.hours - days * 24)
        minutes = math.floor(dateDiff.minutes - (days * 24 * 60 + hours * 60))
        secondsThisXMLIsValidFor = minutes * 60 + hours * 60 * 60 + days * 24 * 60 * 60

        #We have calculated the time this XML is good for, but to be cautious, we'll make sure it is within by setting max and min values
        if secondsThisXMLIsValidFor < MINIMUM_CACHE_TIME_IN_SECONDS:
            secondsThisXMLIsValidFor = MINIMUM_CACHE_TIME_IN_SECONDS
        elif secondsThisXMLIsValidFor > MAXIMUM_CACHE_TIME_IN_SECONDS:
            secondsThisXMLIsValidFor = MAXIMUM_CACHE_TIME_IN_SECONDS

        cache.set(ISS_FLYBY_XML_URL, issxmlBody, ttl_seconds = secondsThisXMLIsValidFor)

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
                                render.Animation(
                                    children = [
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON2),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON3),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON4),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON5),
                                    ],
                                ),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(location, color = "#0099FF"),
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
            ),
        ],
    )
