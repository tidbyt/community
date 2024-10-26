"""
Applet: Rachio
Summary: Rachio sprinkler system
Description: View schedules and data for a Rachio sprinkler system.
Authors: Matt Fischer and Rob Ison
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

RACHIO_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAKMWlDQ1BJQ0MgcHJvZmlsZQAASImdlndUU9kWh8+9N71QkhCKlNBraFICSA29SJEuKjEJEErA
kAAiNkRUcERRkaYIMijggKNDkbEiioUBUbHrBBlE1HFwFBuWSWStGd+8ee/Nm98f935rn73P3Wfvfda6AJD8gwXCTFgJgAyhWBTh58WIjYtnYAcBDPAAA2wA
4HCzs0IW+EYCmQJ82IxsmRP4F726DiD5+yrTP4zBAP+flLlZIjEAUJiM5/L42VwZF8k4PVecJbdPyZi2NE3OMErOIlmCMlaTc/IsW3z2mWUPOfMyhDwZy3PO
4mXw5Nwn4405Er6MkWAZF+cI+LkyviZjg3RJhkDGb+SxGXxONgAoktwu5nNTZGwtY5IoMoIt43kA4EjJX/DSL1jMzxPLD8XOzFouEiSniBkmXFOGjZMTi+HP
z03ni8XMMA43jSPiMdiZGVkc4XIAZs/8WRR5bRmyIjvYODk4MG0tbb4o1H9d/JuS93aWXoR/7hlEH/jD9ld+mQ0AsKZltdn6h21pFQBd6wFQu/2HzWAvAIqy
vnUOfXEeunxeUsTiLGcrq9zcXEsBn2spL+jv+p8Of0NffM9Svt3v5WF485M4knQxQ143bmZ6pkTEyM7icPkM5p+H+B8H/nUeFhH8JL6IL5RFRMumTCBMlrVb
yBOIBZlChkD4n5r4D8P+pNm5lona+BHQllgCpSEaQH4eACgqESAJe2Qr0O99C8ZHA/nNi9GZmJ37z4L+fVe4TP7IFiR/jmNHRDK4ElHO7Jr8WgI0IABFQAPq
QBvoAxPABLbAEbgAD+ADAkEoiARxYDHgghSQAUQgFxSAtaAYlIKtYCeoBnWgETSDNnAYdIFj4DQ4By6By2AE3AFSMA6egCnwCsxAEISFyBAVUod0IEPIHLKF
WJAb5AMFQxFQHJQIJUNCSAIVQOugUqgcqobqoWboW+godBq6AA1Dt6BRaBL6FXoHIzAJpsFasBFsBbNgTzgIjoQXwcnwMjgfLoK3wJVwA3wQ7oRPw5fgEVgK
P4GnEYAQETqiizARFsJGQpF4JAkRIauQEqQCaUDakB6kH7mKSJGnyFsUBkVFMVBMlAvKHxWF4qKWoVahNqOqUQdQnag+1FXUKGoK9RFNRmuizdHO6AB0LDoZ
nYsuRlegm9Ad6LPoEfQ4+hUGg6FjjDGOGH9MHCYVswKzGbMb0445hRnGjGGmsVisOtYc64oNxXKwYmwxtgp7EHsSewU7jn2DI+J0cLY4X1w8TogrxFXgWnAn
cFdwE7gZvBLeEO+MD8Xz8MvxZfhGfA9+CD+OnyEoE4wJroRIQiphLaGS0EY4S7hLeEEkEvWITsRwooC4hlhJPEQ8TxwlviVRSGYkNimBJCFtIe0nnSLdIr0g
k8lGZA9yPFlM3kJuJp8h3ye/UaAqWCoEKPAUVivUKHQqXFF4pohXNFT0VFysmK9YoXhEcUjxqRJeyUiJrcRRWqVUo3RU6YbStDJV2UY5VDlDebNyi/IF5UcU
LMWI4kPhUYoo+yhnKGNUhKpPZVO51HXURupZ6jgNQzOmBdBSaaW0b2iDtCkVioqdSrRKnkqNynEVKR2hG9ED6On0Mvph+nX6O1UtVU9Vvuom1TbVK6qv1eao
eajx1UrU2tVG1N6pM9R91NPUt6l3qd/TQGmYaYRr5Grs0Tir8XQObY7LHO6ckjmH59zWhDXNNCM0V2ju0xzQnNbS1vLTytKq0jqj9VSbru2hnaq9Q/uE9qQO
VcdNR6CzQ+ekzmOGCsOTkc6oZPQxpnQ1df11Jbr1uoO6M3rGelF6hXrtevf0Cfos/ST9Hfq9+lMGOgYhBgUGrQa3DfGGLMMUw12G/YavjYyNYow2GHUZPTJW
Mw4wzjduNb5rQjZxN1lm0mByzRRjyjJNM91tetkMNrM3SzGrMRsyh80dzAXmu82HLdAWThZCiwaLG0wS05OZw2xljlrSLYMtCy27LJ9ZGVjFW22z6rf6aG1v
nW7daH3HhmITaFNo02Pzq62ZLde2xvbaXPJc37mr53bPfW5nbse322N3055qH2K/wb7X/oODo4PIoc1h0tHAMdGx1vEGi8YKY21mnXdCO3k5rXY65vTW2cFZ
7HzY+RcXpkuaS4vLo3nG8/jzGueNueq5clzrXaVuDLdEt71uUnddd457g/sDD30PnkeTx4SnqWeq50HPZ17WXiKvDq/XbGf2SvYpb8Tbz7vEe9CH4hPlU+1z
31fPN9m31XfKz95vhd8pf7R/kP82/xsBWgHcgOaAqUDHwJWBfUGkoAVB1UEPgs2CRcE9IXBIYMj2kLvzDecL53eFgtCA0O2h98KMw5aFfR+OCQ8Lrwl/GGET
URDRv4C6YMmClgWvIr0iyyLvRJlESaJ6oxWjE6Kbo1/HeMeUx0hjrWJXxl6K04gTxHXHY+Oj45vipxf6LNy5cDzBPqE44foi40V5iy4s1licvvj4EsUlnCVH
EtGJMYktie85oZwGzvTSgKW1S6e4bO4u7hOeB28Hb5Lvyi/nTyS5JpUnPUp2Td6ePJninlKR8lTAFlQLnqf6p9alvk4LTduf9ik9Jr09A5eRmHFUSBGmCfsy
tTPzMoezzLOKs6TLnJftXDYlChI1ZUPZi7K7xTTZz9SAxESyXjKa45ZTk/MmNzr3SJ5ynjBvYLnZ8k3LJ/J9879egVrBXdFboFuwtmB0pefK+lXQqqWrelfr
ry5aPb7Gb82BtYS1aWt/KLQuLC98uS5mXU+RVtGaorH1futbixWKRcU3NrhsqNuI2ijYOLhp7qaqTR9LeCUXS61LK0rfb+ZuvviVzVeVX33akrRlsMyhbM9W
zFbh1uvb3LcdKFcuzy8f2x6yvXMHY0fJjpc7l+y8UGFXUbeLsEuyS1oZXNldZVC1tep9dUr1SI1XTXutZu2m2te7ebuv7PHY01anVVda926vYO/Ner/6zgaj
hop9mH05+x42Rjf2f836urlJo6m06cN+4X7pgYgDfc2Ozc0tmi1lrXCrpHXyYMLBy994f9Pdxmyrb6e3lx4ChySHHn+b+O31w0GHe4+wjrR9Z/hdbQe1o6QT
6lzeOdWV0iXtjusePhp4tLfHpafje8vv9x/TPVZzXOV42QnCiaITn07mn5w+lXXq6enk02O9S3rvnIk9c60vvG/wbNDZ8+d8z53p9+w/ed71/LELzheOXmRd
7LrkcKlzwH6g4wf7HzoGHQY7hxyHui87Xe4Znjd84or7ldNXva+euxZw7dLI/JHh61HXb95IuCG9ybv56Fb6ree3c27P3FlzF3235J7SvYr7mvcbfjT9sV3q
ID0+6j068GDBgztj3LEnP2X/9H686CH5YcWEzkTzI9tHxyZ9Jy8/Xvh4/EnWk5mnxT8r/1z7zOTZd794/DIwFTs1/lz0/NOvm1+ov9j/0u5l73TY9P1XGa9m
Xpe8UX9z4C3rbf+7mHcTM7nvse8rP5h+6PkY9PHup4xPn34D94Tz+3EBhusAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAHdElNRQfoChQBGDl/1JFAAAAAGXRF
WHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAAcBJREFUKM9jYMAB2NnZsYozovH1EysY1MylxKWYmBgfPnvCfOf0xXnt2DWoe4Sy+ObfEZT7j2qE
wZdnr9f03d+1CsJlhqv+EV7/kEcMro6F4b8Y4/8vDIwv2Hj5tCwFv735cPcqAwMDE1TaN/85Ox9c9WFrgSeBUrMNoCJP2XilwkoYGRmhNugnlt/SdmVgYBBg
/D9NjUufg8lZkbfk8Juq+z/gRjxj5TEQ4X1+9iALAwMDg5oFxN3sjAzmirw+XMz8HCyf/6GHx0c5Q6iTxMUkIUIv/zFq73xlt/kZAwODNAdjoyz7bHUuuAYl
GTkGBgYWBgYGVmYmZJO+/f/PwMAwyUmcgYHhz///aTe//mdgZGBg+AcNDAaGh8+eMihIoDng9KPPk6983vLx939YwLx/9RzqpH83T2DG6MP3v1Z+/PuVAWH5
3zunoRquLew0/PKMAS8w/fHq4qwmRDy8WtMr8+szLtUiPz8/Wt71//9/hIb7u1b/Xdqgj80e8x+vWJY1Pt6NmjQYGBg+3rv2bPMcYxFedob/7rJcd1+8v3bl
mtTFbafqYz7evYrTrczMzMzMzJC0zcLCwsLCgpJUGRkBSgGWGpO9IcIAAAAASUVORK5CYII=
""")

DEBUG = False
RACHIO_BLUE = "#06a6e2"
ORANGE = "#e27306"
WHITE = "#fff"
ACCURACY_IN_MINUTES = 3  #We'll round to the nearest 3 minutes when calling Rachio API
LONG_TTL_SECONDS = 7200
SHORT_TTL_SECONDS = 600
SAMPLE_DATA = [{"type": "WEATHER_INTELLIGENCE_CLIMATE_SKIP", "date": "Thursday 04:31AM", "summary": "Water all zones was scheduled for 10/03 at 04:26 AM (EDT), but will be skipped based on weather and soil conditions."}, {"type": "WEATHER_INTELLIGENCE_SKIP", "date": "Sunday 04:31AM", "summary": "Water all zones was scheduled for 10/06 at 04:28 AM (EDT), but was skipped due to PLUS weather network which observed 0.00 in and predicted 0.16 in precipitation compared to schedules's threshold of 0.13 in."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:45PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:48PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:50PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:51PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:55PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "WEATHER_INTELLIGENCE_SKIP", "date": "Thursday 04:31AM", "summary": "Water all zones was scheduled for 10/10 at 04:30 AM (EDT), but was skipped due to PLUS weather network which observed 5.10 in and predicted 3.96 in precipitation compared to schedules's threshold of 0.13 in."}, {"type": "WEATHER_INTELLIGENCE_CLIMATE_SKIP", "date": "Sunday 04:36AM", "summary": "Water all zones was scheduled for 10/13 at 04:32 AM (EDT), but will be skipped based on weather and soil conditions."}, {"type": "WEATHER_INTELLIGENCE_CLIMATE_SKIP", "date": "Thursday 04:36AM", "summary": "Water all zones was scheduled for 10/17 at 04:34 AM (EDT), but will be skipped based on weather and soil conditions."}, {"type": "SCHEDULE_STARTED", "date": "Saturday 06:11PM", "summary": "Quick Run will run for 1 minutes."}]
RACHIO_URL = "https://api.rach.io/1/public"

def main(config):
    tz = config.get("$tz", "America/New_York")
    now = time.now().in_location(tz)
    api_key = config.str("api_key", "")
    delay = int(config.get("scroll", 45))
    skip_when_empty = config.bool("skipwhenempty", False)

    if (api_key.strip() == ""):
        return display_error_screen(now, "Please enter your API Key", "It can be found in the Rachio App", delay)

    devices = getDevices(api_key)
    selected_device = config.str("device")

    if not DEBUG and (devices == None or selected_device == None or selected_device == ""):
        if devices == None:
            # No device selected, and no device available from the list, send an error
            return display_error_screen(now, "No devices found.", "Make sure you have entered the correct API key and selected your display device", delay)
        else:
            selected_device = devices[0]["id"]

    # we have a selected device; otherwise, they've already been sent to the display_error_screen

    #Find Past Events and Future Events (as available and as selected)
    time_preference = config.str("time_period", "both")
    now = time.now().in_location(tz)

    # If we use the time to the millisecond, nothing will ever be cached and we'll max our our rachio responses
    # So we'll round off to the nearest X minutes (They provide enough calls to give you 1 per minutes.)
    rounded_time = time.time(year = now.year, month = now.month, day = now.day, hour = now.hour, minute = round_to_nearest_X(now.minute, ACCURACY_IN_MINUTES), second = 0, location = tz)

    # The data they send is a little odd in that the there isn't a time stamp, but a time display.
    # So to get the 'last' and 'next' event, you could get all the data at once, and parse through their time display
    # OR, pull in past events and separate events to let them determine the cutoff on thier side
    # now I can grab the latest past event and the first next event.
    past_start = rounded_time + time.parse_duration("-160h")
    future_end = rounded_time + time.parse_duration("160h")

    #initialize
    past_events = None
    future_events = None

    if time_preference == "both" or time_preference == "past":
        if DEBUG:
            past_events = SAMPLE_DATA
        else:
            past_events = getEvents(selected_device, api_key, past_start, rounded_time)

    if time_preference == "both" or time_preference == "future":
        if DEBUG:
            future_events = SAMPLE_DATA
        else:
            future_events = getEvents(selected_device, api_key, rounded_time, future_end)

    return renderRachio(past_events, future_events, now, delay, skip_when_empty)

def round_to_nearest_X(number_to_round, nearest_number):
    return int(nearest_number * math.round(number_to_round / nearest_number))

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def display_error_screen(time, line_1, line_2 = "", delay = 45):
    return render.Root(
        render.Column(
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Image(src = RACHIO_ICON),
                        render.Box(width = 1, height = 1, color = "#000"),
                        render.Stack(
                            children = [
                                render.Text(time.format("Jan 02"), color = RACHIO_BLUE),
                                add_padding_to_child_element(render.Text(time.format("3:04 PM"), color = RACHIO_BLUE), 0, 8),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(line_1, color = ORANGE),
                ),
                render.Marquee(
                    offset_start = len(line_1) * 5,
                    width = 64,
                    child = render.Text(line_2, color = ORANGE),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )

def renderRachio(past_events, future_events, now, delay, skip_when_empty = True):
    show_past_events = past_events != None and len(past_events) > 0
    show_future_events = future_events != None and len(future_events) > 0

    if (not show_past_events and not show_future_events):
        if skip_when_empty:
            return []
        else:
            return display_error_screen(now, "No Events within a week.", "", delay)

    # whew, made it with at least one event to display
    line_1 = ""
    line_2 = ""

    if show_past_events:
        latest_event = past_events[len(past_events) - 1]
        line_1 = "Last: %s" % latest_event["summary"]

    if show_future_events:
        next_event = future_events[0]
        display = next_event["summary"].strip()
        if len(display) > 0:
            display = "Next: %s" % display

        if line_1 == "":
            line_1 = display
        else:
            line_2 = display

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Image(src = RACHIO_ICON),
                        render.Box(width = 1, height = 1, color = "#000"),
                        render.Stack(
                            children = [
                                render.Text(now.format("Jan 02"), color = RACHIO_BLUE),
                                add_padding_to_child_element(render.Text(now.format("3:04 PM"), color = RACHIO_BLUE), 0, 8),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(line_1, color = ORANGE),
                ),
                render.Marquee(
                    offset_start = len(line_1) * 5,
                    width = 64,
                    child = render.Text(line_2, color = ORANGE),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )

def getEvents(deviceId, api_key, start, end):
    # Rachio uses MS from epoch, not seconds
    start_time = start.unix * 1000
    end_time = end.unix * 1000

    event_url = "%s/device/%s/event?startTime=%d&endTime=%d" % (RACHIO_URL, deviceId, start_time, end_time)

    event_response = http.get(url = event_url, headers = getHeaders(api_key), ttl_seconds = SHORT_TTL_SECONDS)

    if event_response.status_code != 200:
        print("GET %s failed with status %d: %s" % (event_url, event_response.status_code, event_response.body()))
        return None

    return parseEvents(event_response.json())

def parseEvents(events):
    SCHED_START = "SCHEDULE_STARTED"
    SCHED_STOP = "SCHEDULE_COMPLETED"
    WEATHER_SKIP = "WEATHER_INTELLIGENCE_SKIP"
    WEATHER_CLIMATE_SKIP = "WEATHER_INTELLIGENCE_CLIMATE_SKIP"

    usefulEvents = []
    for event in events:
        if "subType" in event.keys():
            #print(event)
            if event["subType"] == SCHED_START or \
               event["subType"] == SCHED_STOP or \
               event["subType"] == WEATHER_SKIP or \
               event["subType"] == WEATHER_CLIMATE_SKIP:
                eventDateSecs = time.from_timestamp(int(event["eventDate"] / 1000))
                parsedDate = eventDateSecs.format("Monday 03:04PM")
                newEvent = dict(type = event["subType"], date = parsedDate, summary = event["summary"])
                usefulEvents.append(newEvent)
    return usefulEvents

def getHeaders(api_key):
    headers = {}
    headers["Authorization"] = "Bearer %s" % api_key
    return headers

def getDevices(api_key):
    #Device Dictionary of IDs and names
    device_information = []

    info_url = "%s/person/info" % RACHIO_URL

    # cache for 1 hour, this should never change
    response = http.get(url = info_url, headers = getHeaders(api_key), ttl_seconds = LONG_TTL_SECONDS)

    if response.status_code != 200:
        print("Failed to retrieve person id: %d %s" % (response.status_code, response.body()))
        return None
    else:
        data = response.json()
        person_id = data.get("id")
        if not person_id:
            print("Person ID not found in the response.")
            return None
        else:
            print("Person ID: %s" % person_id)
            person_url = "%s/person/%s" % (RACHIO_URL, person_id)

            # cache for 1 hour, this should never change
            person_response = http.get(url = person_url, headers = getHeaders(api_key), ttl_seconds = LONG_TTL_SECONDS)

            if person_response.status_code != 200:
                print("Failed to retrieve person data: %d %s" % (person_response.status_code, person_response.body()))
                return None
            else:
                # Parse and print the response for the second call
                person_data = person_response.json()

                # Extract the 'devices' array
                devices = person_data.get("devices", [])

            if not devices:
                print("No devices found: %s" % person_data)
                return None
            else:
                # List to store device ids
                device_ids = []

                # Loop through each device and extract the 'id' field
                for device in devices:
                    deviceId = device.get("id")
                    if deviceId:
                        new_device = {"id": deviceId, "name": device.get("name")}
                        device_ids.append(deviceId)
                        device_information.append(new_device)

    return device_information

def generate_option_list_of_devices(api_key):
    devices = getDevices(api_key)

    if (devices == None or len(devices) == 0):
        return []

    options = [
        schema.Option(display = device["name"], value = device["id"])
        for device in devices
    ]

    return [
        schema.Dropdown(
            id = "device",
            name = "Device",
            desc = "Choose the device to display",
            icon = "sprayCan",  #guage, glassWater
            options = options,
            default = options[0].value,
        ),
    ]

def get_schema():
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

    display_options = [
        schema.Option(
            display = "Show Past Events Only",
            value = "past",
        ),
        schema.Option(
            display = "Show Future Events Only",
            value = "future",
        ),
        schema.Option(
            display = "Show Past and Future Events",
            value = "both",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Rachio API Key",
                desc = "From the phone app or rachio.com you can acquire an API key. From the web app select Account Settings and GET API KEY",
                icon = "key",
            ),
            schema.Dropdown(
                id = "time_period",
                name = "Display Items",
                desc = "Do you want to see, past events, future events or both?",
                icon = "stopwatch",
                options = display_options,
                default = display_options[len(display_options) - 1].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "truckFast",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "skipwhenempty",
                name = "Skip when nothing to display",
                desc = "Skip this app from the Tidbyt display if there are no Rachio events to display.",
                icon = "gear",
                default = True,
            ),
            schema.Generated(
                id = "device",
                source = "api_key",
                handler = generate_option_list_of_devices,
            ),
        ],
    )
