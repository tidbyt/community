"""
Applet: Rachio
Summary: Rachio sprinkler system
Description: View schedules and data for a Rachio sprinkler system.
Author: Matt Fischer
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

RACHIO_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABzklEQVQ4T42Uz0sbQRTHv7Ob7Ca
kaDRISYOlehAsHlIvBT1IDz0Ibei1iJdC/4NSvPTUSxUP3tubSHJqJFIRxIOIh15qDiVIT2lCGo
n4IxvdZLM/xsyEicg61nd6zJv5vDfzfW+I4zi03W6Dma7rKDc97n/+bWCteMn9uScRfJro4/5wW
IFlWdzXNA3ENE2qKApUVUWu2sbb/RMelFl6OoZUXIPruvA8rwsIBoNYLVn48OsMFw69E/AgQLA8
OYD5xzps2wYxDINun6t4//PUdzgSUHAw+xDfy00s5M97YAb5+nwQL6MuSPHCpmMb1Vuz/nkdR8V
08WKnJo2TrX9Nmto97m2YH4n0/MVkFI+yFemVcjNDIMnNKi3UbR/g3WgEU0M69ExZCnjaHwTR0q
VbX+1b546sGgF4lQhjr2ahbndlFvZfgNjoeBTjP45QunRuAkKZEu3EfCYqYLJmyyZqLReLhcaNC
hQCkJVDg348uJZIkATgbyejTKWlZ1G5jPcBMJlJpyXpeqXla6S7AKKR3iRC8laWAXytzCpg08Um
kVUihkkGYMPEMoszpNFoUD6WhPDFExLi7xjTVbBs7BEX8nV8SfZ312mLJ6OUgn0DV/QG/UIOZTh
SAAAAAElFTkSuQmCC
""")

# Rachio API key
DEFAULT_API_KEY = "ABCDEFG-46b0-47de-afb9-9f03adf468fc"

def main(config):
    api_key = config.str("api_key", DEFAULT_API_KEY)
    tz = config.get("$tz", "America/New_York")

    # Set up the headers with your API key for authentication
    headers = {}
    headers["Authorization"] = "Bearer %s" % api_key

    devices = getDevices(headers)

    # XXX - consider handling > 1 device later
    if devices == None:
        print("no devices found, giving up")
        parsedEvents = None
    else:
        events = getEvents(devices[0], headers, tz)
        parsedEvents = parseEvents(events)
        #print(parsedEvents)

    return renderRachio(parsedEvents)

def makeEventBoxes(events):
    children = []
    for event in events:
        child = render.Column(
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Image(src = RACHIO_ICON),
                        render.Box(height = 5, width = 5),
                        render.WrappedText(
                            content = event["date"],
                            font = "tom-thumb",
                            align = "left",
                            color = "#06a7e2",
                        ),
                    ],
                ),
                render.Row(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Marquee(width = 64, align = "start", child = render.Text(content = event["summary"], font = "tb-8")),
                    ],
                ),
            ],
        )
        children.append(child)
    return children

def renderRachio(events):
    if events == None:
        return render.Root(
            child = render.Column(
                children = [
                    render.Row(
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Image(src = RACHIO_ICON),
                            render.Text("no data available"),
                        ],
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Sequence(makeEventBoxes(events)),
        )

def getDevices(headers):
    info_url = "https://api.rach.io/1/public/person/info"

    # cache for 1 hour, this should never change
    response = http.get(url = info_url, headers = headers, ttl_seconds = 3600)

    if response.status_code != 200:
        print("Failed to retrieve person id: %d %s" % (response.status_code, response.text))
        return None
    else:
        data = response.json()
        person_id = data.get("id")
        if not person_id:
            print("Person ID not found in the response.")
            return None
        else:
            print("Person ID: %s" % person_id)
            person_url = "https://api.rach.io/1/public/person/%s" % person_id

            # cache for 1 hour, this should never change
            person_response = http.get(url = person_url, headers = headers, ttl_seconds = 3600)

            if person_response.status_code != 200:
                print("Failed to retrieve person data: %d %s" % (person_response.status_code, person_response.text))
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
                        device_ids.append(deviceId)

                # Print the list of device IDs
                print("Device IDs:", device_ids)
                return device_ids

def getEvents(deviceId, headers, tz):
    now = time.now().in_location(tz)
    yesterday = now + time.parse_duration("-24h")

    # Rachio uses MS from epoch, not seconds
    now_ms = now.unix * 1000
    yesterday_ms = yesterday.unix * 1000

    event_url = "https://api.rach.io/1/public/device/%s/event?startTime=%d&endTime=%d" % \
                (deviceId, yesterday_ms, now_ms)
    print(event_url)

    # cache for 10 minutes
    event_response = http.get(url = event_url, headers = headers, ttl_seconds = 600)

    if event_response.status_code != 200:
        print("GET %s failed with status %d: %s" % (event_url, event_response.status_code, event_response.body()))

        # XXX consider using fail() here
        return None

    return event_response.json()

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

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Rachio API Key",
                desc = "From the phone app or rachio.com you can acquire an API key. From the web app select Account Settings and GET API KEY",
                icon = "user",
            ),
        ],
    )
