load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("time.star", "time")

# Entur API endpoint for real-time departures
ENTUR_API_URL = "https://api.entur.io/journey-planner/v3/graphql"

def minutes_until_departure(current_time, departure_time):
    # Extract HH:MM from ISO format strings
    current_hours = int(current_time[11:13])
    current_minutes = int(current_time[14:16])
    departure_hours = int(departure_time[11:13])
    departure_minutes = int(departure_time[14:16])
    
    # Convert to total minutes
    current_total = current_hours * 60 + current_minutes
    departure_total = departure_hours * 60 + departure_minutes
    
    # Calculate difference
    minutes_until = departure_total - current_total
    
    # Handle next day case
    if minutes_until < 0:
        minutes_until = minutes_until + (24 * 60)
    
    return minutes_until


def main(config):
    # Get the stop ID from config, default to Valøyvegen if not set
    stop_id = config.get("stop_id", "NSR:StopPlace:6286")
    quay_id = config.get("quay_id", "NSR:Quay:11544")
    stop_name = config.get("stop_name", "Colletts gate")

    # Create the header box
    header = render.Box(
        width = 64,
        height = 8,
        color = "#333333",
        child = render.Text(
            content = stop_name,
            font = "5x8",
        ),
    )

    # GraphQL query for departures
    query = """{
      stopPlace(id: "%s") {
        name
        quays {
          id
          publicCode
          estimatedCalls(timeRange: 72000, numberOfDepartures: 3) {
            expectedDepartureTime
            destinationDisplay {
              frontText
            }
            serviceJourney {
              line {
                publicCode
              }
            }
          }
        }
      }
    }""" % stop_id

    # Set up headers
    headers = {
        "ET-Client-Name": "atb-tidbyt-display",
        "Content-Type": "application/json",
    }

    # Make the request to Entur API
    rep = http.post(
        ENTUR_API_URL,
        json_body = {"query": query},
        headers = headers,
    )

    if rep.status_code != 200:
        return render.Root(
            child = render.Column(
                children = [
                    header,
                    render.Text("Error fetching data"),
                ],
            ),
        )

    # Parse the JSON response
    response_data = rep.json()
    departures = []

    # Extract departure information
    if "data" in response_data and "stopPlace" in response_data["data"]:
        stop_place = response_data["data"]["stopPlace"]
        if "quays" in stop_place:
            for quay in stop_place["quays"]:
                if quay["id"] == quay_id and "estimatedCalls" in quay:
                    for call in quay["estimatedCalls"]:
                        line = call["serviceJourney"]["line"]["publicCode"]
                        departure_time = call["expectedDepartureTime"]

                        # Get current time in the same format as departure_time
                        current_time = time.now().format("2006-01-02T15:04:05-07:00")

                        # Calculate minutes until departure
                        minutes_left = minutes_until_departure(current_time, departure_time)
                        
                        # Determine the time string to display
                        if minutes_left <= 1:
                            time_str = "Nå"
                        else:
                            time_str = str(minutes_left) + " min"

                        # Create a more compact display with proper spacing
                        departures.append(
                            render.Box(
                                width = 64,
                                height = 8,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 16,
                                            child = render.Text(
                                                content = line,
                                                font = "5x8",
                                                color = "#C44536",
                                            ),
                                        ),
                                        render.Box(
                                            width = 32,
                                            child = render.Text(
                                                content = time_str,
                                                font = "5x8",
                                                color = "#197278",
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        )
    else:
        print("No stop place data found")

    if not departures:
        departures.append(render.Text("No departures"))

    return render.Root(
        child = render.Column(
            children = [header] + departures,
        ),
    )
