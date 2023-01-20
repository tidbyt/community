"""
Applet: CharlestownFerry
Summary: Ferry Depature Times
Description: Displays three upcoming ferry depature times for the Charlestown, MA Ferry.
Author: jblaker
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("time.star", "time")

FERRY_SCHEDULE_URL = "https://api-v3.mbta.com/schedules?filter[route]=Boat-F4"

def main():
    response_data_cache = cache.get("response_data")
    if response_data_cache != None:
        # print("Hit! Displaying cached data.")
        response_data = json.decode(response_data_cache)
    else:
        # print("Miss! Calling MBTA API.")
        rep = http.get(FERRY_SCHEDULE_URL)
        if rep.status_code != 200:
            fail("MBTA API request failed with status %d", rep.status_code)
        response_data = rep.json()
        cache.set("response_data", json.encode(response_data), ttl_seconds = 240)

    ferry_schedule = response_data["data"]

    upcoming_ferries = []
    max_times = 3
    counter = 0
    current_time = time.now()

    for schedule in ferry_schedule:
        relationships = schedule["relationships"]
        stop = relationships["stop"]
        stop_data = stop["data"]
        stop_id = stop_data["id"]

        # print("Stop ID = %s", stopId)
        if stop_id == "Boat-Charlestown":
            attributes = schedule["attributes"]
            departure_time_str = attributes["departure_time"]
            if departure_time_str != None:
                # print("Time String = %s", departureTimeStr)
                departure_time = time.parse_time(departure_time_str)
                if departure_time >= current_time:
                    # print("Departure Time %s", departureTime.format("3:04 PM"))
                    if counter < max_times:
                        upcoming_ferries.append(departure_time)
                        counter += 1
                    else:
                        break

    if len(upcoming_ferries) > 0:
        next_departures = [render.Marquee(child = render.Text(content = "Upcoming Ferries", color = "#fa0"), width = 58), render.Box(height = 1, color = "#fa0")]

        # "a{x}b{y}c{}".format(1, x=2, y=3)
        for ferry in upcoming_ferries:
            time_till_departure = humanize.relative_time(ferry, current_time)
            next_departures.append(
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.Row(
                        children = [
                            render.Text(
                                content = ferry.format("3:04 PM"),
                                font = "CG-pixel-3x5-mono",
                            ),
                            render.Padding(
                                pad = (2, 0, 0, 0),
                                child = render.Marquee(
                                    child = render.Text(
                                        content = "({time_till})".format(time_till = time_till_departure.strip()),
                                        font = "CG-pixel-3x5-mono",
                                        color = "#4885EE",
                                    ),
                                    width = 28,
                                ),
                            ),
                        ],
                    ),
                ),
            )

        return render.Root(
            child = render.Padding(
                # (left, top, right, bottom)
                pad = (3, 1, 3, 1),
                child = render.Column(
                    main_align = "space_around",
                    cross_align = "start",
                    children = next_departures,
                ),
            ),
        )

    else:
        return render.Root(
            child = render.Padding(
                pad = (3, 1, 3, 1),
                child = render.WrappedText(content = "There are no more ferries today.", color = "#fa0"),
            ),
        )
