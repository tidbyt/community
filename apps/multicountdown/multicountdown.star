"""
Applet: MultiClountdown
Summary: Multi event countdown
Description: A clock that countsdown to a series of events, one time or daily.
Author: BestDistress
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    #Set up our clock/time/now:
    timezone = config.get("$tz", "America/New_York")  # Utilize special timezone variable
    now = time.now().in_location(timezone)

    eventCount = config.str("eventCount")
    eventArray = []

    #default color is blue
    color = "#0000FF"

    #defaults to green
    farColor = "#2BFF00"

    #defaults to yellow
    midColor = "#FFFF00"

    #defaults to red
    #closeColor = "#FF0000"

    #If we have events filled in
    if eventCount:
        if int(eventCount) > 0:
            if config.bool("daily"):
                for x in range(int(eventCount)):
                    if config.str("event_" + str(x) + "_time"):
                        eventTime = time.parse_time(config.str("event_" + str(x) + "_time")).in_location(timezone)

                        updatedEventTime = time.time(year = now.year, month = now.month, day = now.day, hour = eventTime.hour, minute = eventTime.minute, second = eventTime.second, location = "America/New_York")

                        dateDiff = updatedEventTime - time.now()

                        if dateDiff.seconds < 0:
                            updatedEventTime = time.time(year = now.year, month = now.month, day = now.day + 1, hour = eventTime.hour, minute = eventTime.minute, second = eventTime.second, location = "America/New_York")
                            dateDiff = updatedEventTime - time.now()

                        eventArray.append(dateDiff)

                        output = dateDiff
                    else:
                        break
            else:
                for x in range(int(eventCount)):
                    if config.str("event_" + str(x) + "_time"):
                        eventTime = time.parse_time(config.str("event_" + str(x) + "_time")).in_location(timezone)
                        dateDiff = eventTime - time.now().in_location(timezone)
                        eventArray.append(dateDiff)
                    else:
                        break

            #Let's find the closest  event:
            closestEventIndex = find_shortest_non_negative_time_index(eventArray)
            if closestEventIndex > -1:
                parsedTime = time.parse_duration(eventArray[closestEventIndex])
                days = int(parsedTime.hours / 24)
                hours = int(parsedTime.hours)
                minutes = int(parsedTime.minutes)

                #Let's set colors - this isn't very intuitive. If normal, set it to the defaults up top. If event reverse boolean is true, flip red and green for close and far.
                if config.bool("event_" + str(closestEventIndex) + "_reverse"):
                    #closeColor = "#2BFF00"
                    midColor = "#FFFF00"
                    farColor = "#FF0000"
                color = farColor

                #Disabling the intermediary step for colors.
                #if hours < 1 and minutes < 30 and minutes > 15:
                #    color = midColor
                if hours < 1 and minutes < 15:
                    color = midColor
                formatted_duration = format_duration(days, hours, minutes)
                output = formatted_duration + " until " + config.str("event" + str(closestEventIndex))
            else:
                output = "NO FUTURE EVENTS"
        else:
            output = "NO EVENTS"
    else:
        output = "WAITING FOR DATA"

    if len(output) < 11:
        eventWidget = render.Text(content = output, font = "6x13", color = color)
    else:
        eventWidget = render.Marquee(
            child = render.Text(content = output, font = "6x13", color = color),
            width = 64,
        )

    #Let's draw:
    return render.Root(
        delay = 150,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Animation(
                            children = [
                                render.Text(
                                    content = now.format("3:04 PM"),
                                    font = "6x13",
                                    color = color,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        eventWidget,
                    ],
                ),
            ],
        ),
    )

def more_options(eventCount):
    returnArray = []
    if int(eventCount) > 20:
        eventCount = "20"

    if int(eventCount) > 0:
        for x in range(int(eventCount)):
            returnArray.append(schema.Text(id = "event" + str(x), name = "Event " + str(x) + " Name", desc = "16 characters max", icon = "gear"))
            returnArray.append(schema.DateTime(id = "event_" + str(x) + "_time", name = "Event " + str(x) + " Time", desc = "The time event " + str(x) + ".", icon = "gear"))
            returnArray.append(schema.Toggle(id = "event_" + str(x) + "_reverse", name = "Event " + str(x) + " Reverse Color", desc = "Should we reverse the colors for this event?", icon = "gear", default = False))
        return returnArray
    else:
        return returnArray

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "eventCount",
                name = "Number of Events",
                desc = "How many different events are we counting down until? (20 max)",
                icon = "gear",
            ),
            schema.Toggle(
                id = "daily",
                name = "Daily Repeat?",
                desc = "Should we treat all events as today (i.e. ignore dates)?",
                icon = "gear",
            ),
            schema.Generated(
                id = "generated",
                source = "eventCount",
                handler = more_options,
            ),
        ],
    )

def find_shortest_non_negative_time_index(times):
    shortest_time = None
    shortest_index = -1

    for i, t in enumerate(times):
        if t >= time.parse_duration("0s"):  # Check if it's non-negative
            if shortest_time == None or t < shortest_time:
                shortest_time = t
                shortest_index = i

    return shortest_index

def format_duration(days, hours, minutes):
    formatted_duration = ""

    if days > 0:
        formatted_duration += str(days) + "d:"

    if hours > 0 or days > 0:
        hours_to_display = hours - (days * 24)
        formatted_duration += str(hours_to_display) + "h:"

    if minutes > 0 or hours > 0 or days > 0:
        minutes_to_display = minutes - (hours * 60)
        formatted_duration += str(minutes_to_display) + "m"

    if formatted_duration == "":
        formatted_duration = "0m"

    return formatted_duration
