"""
Applet: SpotTheStation
Summary: Next ISS visit overhead
Description: Displays the next time the International Space Station will appear.
Author: Robert Ison
"""

load("cache.star", "cache")  #Caching
load("encoding/base64.star", "base64")  #Used to read encoded image
load("encoding/json.star", "json")  #Used to figure out timezone
load("http.star", "http")  #HTTP Client
load("math.star", "math")  #Used to calculate duration between timestamps
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")  #Used to display time and calcuate lenght of TTL cache
load("xpath.star", "xpath")  #XPath Expressions to read XML RSS Feed

#Requires the RSS feed for your location from spotthestation.nasa.gov
#Use the map tool to find the nearest location, click the blue marker then the "View sighting opportunities"
#From this page click "RSS" to get the needed XML Feed for your location
#Pass that into this app to have the next approach to your location listed on  your Tidbyt

#Note on Timezones: The data from NASA on upcoming flyovers is in localtime but without timezone information.
#To know when that time has past, we need to know the tidbyts location.

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

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

def two_character_time_date_part(number):
    if len(str(number)) == 1:
        return "0" + str(number)
    else:
        return number

def two_character_numeric_month_from_month_string(month):
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

def get_local_time(config):
    timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
    local_time = time.now().in_location(timezone)
    return local_time

def get_local_offset(config):
    """ Get Local Offset

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The the local offset based on your location
    """
    timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
    local_time = time.now().in_location(timezone)
    offset = str(local_time).split(" ")

    if (offset[2][0:1] == "+"):
        the_sign = "-"
    else:
        the_sign = "+"

    if (len(offset) == 4):
        return time.parse_duration(the_sign + str(int("04")) + "h")
    else:
        return time.parse_duration("+0h")

def get_timestamp_from_item(item):
    """ Get Timestamp from item

    Args:
        item: The item from the XML that has a timestamp
    Returns:
        an actual timestamp
    """
    description = item.replace("\n", "").replace("\t", "").split("<br/>")
    item_date = description[0].replace("Date: ", "").split(" ")
    item_time = description[1].replace("Time: ", "").split(" ")
    timestamp = item_date[3] + "-" + two_character_numeric_month_from_month_string(item_date[1]) + "-" + two_character_time_date_part(item_date[2].replace(",", "")) + "T" + get_timestamp_time(item_time[0], item_time[1]) + ":00Z"  # + get_local_offset(config)
    return timestamp

def get_timestamp_time(time, meridiem):
    time = time.split(":")
    if meridiem == "PM":
        time[0] = int(time[0]) + 12

    return str(time[0]) + ":" + time[1]

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The display inforamtion for the Tidbyt
    """

    #Defaults
    current_local_time = get_local_time(config)
    found_sighting_to_display = False
    number_of_listed_sightings = 0
    item_number_to_display = 0
    time_of_next_sighting = None
    time_of_furthest_known_sighting = None
    location = "Invalid Location Data. You should have entered an RSS feed URL that looks like this: https://spotthestation.nasa.gov/sightings/xml_files/United_States_Florida_Orlando.xml"
    row1 = ""
    row2 = ""
    row3 = ""

    #Get Station Selected By User
    ISS_FLYBY_XML_URL = config.get("SpotTheStationRSS") or "https://spotthestation.nasa.gov/sightings/xml_files/United_States_Florida_Orlando.xml" or "https://spotthestation.nasa.gov/sightings/xml_files/China_None_Xian.xml"

    #cache is saved to the tidbyt server, not locally, so we need a unique key per location which is equivelent to the Flyby XML URL
    iss_xml_body = cache.get(ISS_FLYBY_XML_URL)
    set_cache = False
    if iss_xml_body == None:
        iss_xml = http.get(ISS_FLYBY_XML_URL)

        #print("Going to spotthestation.nasa.gov to get XML")
        if iss_xml.status_code == 200:
            iss_xml_body = iss_xml.body()

            #This XML Feed can have many sightings listed, both past and future
            #So Let's find the first future sighting and display that
            number_of_listed_sightings = iss_xml_body.count("<item>")
            set_cache = True
    else:
        #print("Using cached XML")
        number_of_listed_sightings = iss_xml_body.count("<item>")

    if iss_xml_body == None:
        row1 = "Invalid Data from spotthestation.nasa.gov. You should have entered an RSS feed URL that looks like this: https://spotthestation.nasa.gov/sightings/xml_files/United_States_Florida_Orlando.xml"
        description = None
    elif number_of_listed_sightings == 0:
        row1 = "The station will not appear overhead for at least several days"
        description = ""
        location = xpath.loads(iss_xml_body).query("/rss/channel/description").replace("Satellite Sightings Information for ", "")
    else:
        #Find the next pass, and skip past times
        for i in range(1, number_of_listed_sightings + 1):
            current_query = "//item[" + str(i) + "]/description"
            current_description = xpath.loads(iss_xml_body).query(current_query)
            current_time_stamp = get_timestamp_from_item(current_description)
            timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
            current_item_time = time.parse_time(current_time_stamp).in_location(timezone) + get_local_offset(config)

            if current_item_time > current_local_time:
                item_number_to_display = i
                time_of_next_sighting = current_time_stamp

                # This is the next sighting, let's check to see if they want it displayed based on settings
                hours_notice = int(config.get("notice_period", 0))
                hours_until_sighting = (current_item_time - current_local_time).hours
                if (hours_notice == 0 or hours_notice > hours_until_sighting):
                    found_sighting_to_display = True
                else:
                    found_sighting_to_display = False
                break

        #Only past events are in the XML, so we'll need to give an appropriate message
        if (item_number_to_display == 0):
            description = "The station will not appear overhead for at least several days"
        else:
            description = xpath.loads(iss_xml_body).query("/rss/channel/item[" + str(item_number_to_display) + "]/description")

        location = xpath.loads(iss_xml_body).query("/rss/channel/description").replace("Satellite Sightings Information for ", "")

    if (set_cache == True):
        #The current XML is valid until the last known future listing
        #So let's use that to figure our cache ttl
        if (number_of_listed_sightings > item_number_to_display):
            #Since there are more future sightings in the current XML
            #Let's cache this XML as long as we have good data
            current_query = "//item[" + str(number_of_listed_sightings) + "]/description"
            current_description = xpath.loads(iss_xml_body).query(current_query)
            current_time_stamp = get_timestamp_from_item(current_description)
            time_of_furthest_known_sighting = current_time_stamp
            date_diff = time.parse_time(time_of_furthest_known_sighting) - get_local_time(config)
        else:
            #No future Sightings so we can cache at least until the next sighting
            if (time_of_next_sighting == None):
                date_diff = time.now() - time.now()
            else:
                date_diff = get_local_time(config) - get_local_time(config)  # time.parse_time(time_of_next_sighting) - get_local_time(config)

        days = math.floor(date_diff.hours // 24)
        hours = math.floor(date_diff.hours - days * 24)
        minutes = math.floor(date_diff.minutes - (days * 24 * 60 + hours * 60))
        seconds_xml_valid_for = minutes * 60 + hours * 60 * 60 + days * 24 * 60 * 60

        #We have calculated the time this XML is good for, but to be cautious, we'll make sure it is within by setting max and min values
        if seconds_xml_valid_for < MINIMUM_CACHE_TIME_IN_SECONDS:
            seconds_xml_valid_for = MINIMUM_CACHE_TIME_IN_SECONDS
        elif seconds_xml_valid_for > MAXIMUM_CACHE_TIME_IN_SECONDS:
            seconds_xml_valid_for = MAXIMUM_CACHE_TIME_IN_SECONDS

        cache.set(ISS_FLYBY_XML_URL, iss_xml_body, ttl_seconds = seconds_xml_valid_for)

    if description == None:
        description = "None"
        row1 = "Error getting Data from spotTheStation.nasa.gov"
    else:
        i = 0
        for item in description.split("<br/>"):
            i += 1
            item = item.replace("\n", "").replace("\t", "")

            if (i < 2):
                row2 += item.replace("Date: ", "").replace("Monday", "Mon").replace("Tuesday", "Tue").replace("Wednesday", "Wed").replace("Thursday", "Thu").replace("Friday", "Fri").replace("Saturday", "Sat").replace("Sunday", "Sun").replace(", 20", " '")
            elif (i < 3):
                row1 += item.replace("Time: ", "")
            else:
                row3 += item.replace("Duration: ", "For ").replace("Maximum Elevation:", "Max").replace("Approach:", "from").replace("Departure:", "to").replace("minute", "min")

    if (found_sighting_to_display):
        return get_display(location, row1, row2, row3, config)
    else:
        return []

def get_display(location, row1, row2, row3, config):
    return render.Root(
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
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
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON4),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON3),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON2),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON2),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON2),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON2),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
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
    period_options = [
        schema.Option(value = "1", display = "1 hour"),
        schema.Option(value = "2", display = "2 hours"),
        schema.Option(value = "3", display = "3 hours"),
        schema.Option(value = "4", display = "4 hours"),
        schema.Option(value = "5", display = "5 hours"),
        schema.Option(value = "12", display = "12 hours"),
        schema.Option(value = "24", display = "1 day"),
        schema.Option(value = "48", display = "2 days"),
        schema.Option(value = "72", display = "3 days"),
        schema.Option(value = "168", display = "1 week"),
        schema.Option(value = "0", display = "Always Display Next Sighting if known"),
    ]

    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "SpotTheStationRSS",
                name = "Spot the Station RSS",
                icon = "locationArrow",
                desc = "Go to spotthestation.nasa.gov Use the map tool to find the nearest location, click the blue marker then 'View sighting opportunities' then get the RSS feed URL.",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location needed to calculate local time.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "notice_period",
                name = "Notice Period",
                desc = "Display when sighting is within...",
                icon = "userClock",
                options = period_options,
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
