"""
Applet: CharlestownFerry
Summary: Ferry Depature Times
Description: Displays three upcoming ferry depature times for the Charlestown, MA Ferry.
Author: jblaker
"""

load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("time.star", "time")
load("encoding/json.star", "json")

FERRY_SCHEDULE_URL = "https://api-v3.mbta.com/schedules?filter[route]=Boat-F4"

def main():
    response_data_cache = cache.get("response_data")
    if response_data_cache != None:
        print("Hit! Displaying cached data.")
        response_data = json.decode(response_data_cache)
    else:
        print("Miss! Calling MBTA API.")
        rep = http.get(FERRY_SCHEDULE_URL)
        if rep.status_code != 200:
            fail("MBTA API request failed with status %d", rep.status_code)
        response_data = rep.json()
        cache.set("response_data", json.encode(response_data), ttl_seconds = 240)

    ferry_schedule = response_data["data"]

    upcoming_ferries = []
    max_times = 3
    counter = 0
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
                if departure_time >= time.now():
                    # print("Departure Time %s", departureTime.format("3:04 PM"))
                    if counter < max_times:
                        upcoming_ferries.append(departure_time)
                        counter += 1

    if len(upcoming_ferries) > 0:
        next_departures = [render.Marquee(child = render.Text(content = "Upcoming Ferries", color = "#fa0"), width = 64), render.Box(height = 1, color = "#a00")]

        for ferry in upcoming_ferries:
            next_departures.append(render.Text(content = ferry.format("3:04 PM"), font = "CG-pixel-3x5-mono"))

        return render.Root(
            child = render.Padding(
                pad = 1,
                child = render.Column(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "start",
                    children = next_departures,
                ),
            ),
        )

    else:
        return render.Root(
            child = render.Padding(
                pad = 2,
                child = render.WrappedText(content = "There are no upcoming ferries for today.", color = "#fa0"),
            ),
        )
