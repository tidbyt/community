"""
Applet: FlightTracker
Summary: FlightAware API + Tidbyt
Description: Tracks flights via given Flight Number or airport code.
Author: samuelsagarino
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

OUTPUT_FORMATS = {
    "departures": "departures",
    "arrivals": "arrivals",
    "flight": "flight",
}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "displayMode",
                name = "Display Mode",
                desc = "What should be displayed?",
                icon = "list",
                default = "Departures",
                options = [
                    schema.Option(
                        display = format,
                        value = format,
                    )
                    for format in OUTPUT_FORMATS
                ],
            ),
            schema.Text(
                id = "airportCode",
                name = "Airport Code",
                desc = "Airport Code to Track",
                icon = "planeArrival",
            ),
            schema.Text(
                id = "flightNumber",
                name = "Flight Number",
                desc = "Flight Number to Track",
                icon = "planeLock",
            ),
            schema.Text(
                id = "apiKey",
                name = "FA API Key",
                desc = "Flight Aware API Key",
                icon = "code",
            ),
        ],
    )

def main(config):
    DEFAULTAIRPORT = "KATL"
    DEFAULTDISPLAY = "arrivals"
    DEFAULTAPI = "noKey"

    # User inputted data.
    displayMode = config.get("displayMode") or DEFAULTDISPLAY
    flightNumber = config.get("flightNumber")
    faAPIKey = config.get("apiKey") or DEFAULTAPI
    airportCode = config.get("airportCode") or DEFAULTAIRPORT

    # Date utilities for the API calls. These dates are not utilized in the render.
    now = time.now().in_location("America/New_York")
    deptDate = humanize.time_format("yyyy-MM-dd", now)
    duration = time.parse_duration("24h")
    tomorrow = now + duration
    endDate = humanize.time_format("yyyy-MM-dd", tomorrow)

    # Determine which api to call upon based upon selected display mode.

    # Defualt API url
    apiURL = "https://aeroapi.flightaware.com/aeroapi/airports/" + airportCode + "/flights/departures?type=Airline"

    if displayMode == "departures":
        apiURL = "https://aeroapi.flightaware.com/aeroapi/airports/" + airportCode + "/flights/departures?type=Airline"
    if displayMode == "arrivals":
        apiURL = "https://aeroapi.flightaware.com/aeroapi/airports/" + airportCode + "/flights/arrivals?type=Airline"
    if displayMode == "flight":
        apiURL = "https://aeroapi.flightaware.com/aeroapi/flights/" + flightNumber + "?ident_type=fa_flight_id&start=" + deptDate + "&end=" + endDate + "&max_pages=1"

    ## MARQUEE FORMATTING & DATA TO DISPLAY
    time_color = "#ffffff"
    departureSecondary = "deptSecondary"
    arrivalSecondary = "arrvSecondary"
    departureSecondaryColor = "#f5be00"
    arrivalSecondaryColor = "#f5be00"
    marquee = "marquee"

    if faAPIKey != "noKey":
        # Initial API call using above URL + API key
        if displayMode == "flight":
            cacheName = "flight/" + flightNumber
        else:
            cacheName = displayMode + "/" + airportCode

        flightawareData_cached = cache.get(cacheName)

        if flightawareData_cached != None:
            flightawareData = json.decode(flightawareData_cached)
            print("Found cached data! Not calling FA API / " + cacheName)
        else:
            print("No cached data; calling FA API / " + cacheName)
            rep = http.get(apiURL, headers = {"x-apikey": faAPIKey})

            if rep.status_code != 200:
                fail("FA API failed with status %d", rep.status_code)
            flightawareData = rep.json()
            cache.set(cacheName, json.encode(flightawareData), ttl_seconds = 120)

        # Determine how to read data based upon above selection.
        # Default flights
        flights = "null"

        if displayMode == "departures":
            flights = flightawareData["departures"]
        if displayMode == "arrivals":
            flights = flightawareData["arrivals"]
        if displayMode == "flight":
            flights = flightawareData["flights"]

        flight_number = flights[0]["ident"]  # Flight #
        registration = flights[0]["registration"]  # Aircraft Registration Number
        aircraftType = flights[0]["aircraft_type"]  # Aircraft Type
        status = flights[0]["status"]  # Flight Status
        operator = flights[0]["operator"]  # Flight Operator
        #operator_iata = flights[0]["operator_iata"]  # Operator IATA Code

        origin = flights[0]["origin"]  # Set origin header for data collection within origin list.
        originICAO = origin["code"]  # Origin ICAO code
        originTimezone = origin["timezone"]  # Origin timezone
        deptCity = origin["city"]  # Origin City

        destination = flights[0]["destination"]  # Set destination header for data collection within origin list.
        destinationICAO = destination["code"]  # Destination ICAO code
        destinationTimezone = destination["timezone"]  # Destination timezone
        arrvCity = destination["city"]  # Destination city

        completetionPerecent = flights[0]["progress_percent"]  # Flight completion %
        progressBarWidth = completetionPerecent / 1.5625  # Competion / 1.5625 (get value 1-64)
        progressBarWidth = int(progressBarWidth)  # Set progress bar width 1-64
        if progressBarWidth < 1:
            progressBarWidth = 1

        ######  TIME OPERATIONS  #####
        ## SCHEDULED DEPARTURE TIME ##
        scheduledDept = flights[0]["scheduled_off"] or "0000000000000000000"

        scheduledDept_year = int(scheduledDept[0:4])
        scheduledDept_month = int(scheduledDept[5:7])
        scheduledDept_day = int(scheduledDept[8:10])
        scheduledDept_h = int(scheduledDept[11:13])
        scheduledDept_m = int(scheduledDept[14:16])
        scheduledDept_s = int(scheduledDept[17:19])

        scheduledDept = time.time(year = scheduledDept_year, month = scheduledDept_month, day = scheduledDept_day, hour = scheduledDept_h, minute = scheduledDept_m, second = scheduledDept_s, location = "Europe/London")

        scheduledDept_humanized = humanize.time(scheduledDept)

        scheduledDept_time = humanize.time_format("HH:mm", scheduledDept.in_location(originTimezone))

        ## SCHEDULED ARRIVAL TIME
        scheduledArrival = flights[0]["scheduled_on"] or "0000000000000000000"

        scheduledArrival_year = int(scheduledArrival[0:4])
        scheduledArrival_month = int(scheduledArrival[5:7])
        scheduledArrival_day = int(scheduledArrival[8:10])
        scheduledArrival_h = int(scheduledArrival[11:13])
        scheduledArrival_m = int(scheduledArrival[14:16])
        scheduledArrival_s = int(scheduledArrival[17:19])

        scheduledArrival = time.time(year = scheduledArrival_year, month = scheduledArrival_month, day = scheduledArrival_day, hour = scheduledArrival_h, minute = scheduledArrival_m, second = scheduledArrival_s, location = "Europe/London")

        #scheduledArrival_humanized = humanize.time(scheduledArrival)

        scheduledArrival_time = humanize.time_format("HH:mm", scheduledArrival.in_location(destinationTimezone))

        ## ESTIMATED ARRIVAL TIME ##

        estimatedArrival = flights[0]["estimated_on"] or "0000000000000000000"

        year = int(estimatedArrival[0:4])
        month = int(estimatedArrival[5:7])
        day = int(estimatedArrival[8:10])
        hour = int(estimatedArrival[11:13])
        minute = int(estimatedArrival[14:16])
        second = int(estimatedArrival[17:19])

        estimatedArrival = time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "Europe/London")

        estimatedArrival_humanized = humanize.time(estimatedArrival)

        estimatedArrival_time = humanize.time_format("HH:mm", estimatedArrival.in_location(destinationTimezone))

        ## ESTIMATED DEPARTURE TIME ##

        estimatedDeparture = flights[0]["estimated_off"] or "0000000000000000000"

        year = int(estimatedDeparture[0:4])
        month = int(estimatedDeparture[5:7])
        day = int(estimatedDeparture[8:10])
        hour = int(estimatedDeparture[11:13])
        minute = int(estimatedDeparture[14:16])
        second = int(estimatedDeparture[17:19])

        estimatedDeparture = time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "Europe/London")

        estimatedDeparture_humanized = humanize.time(estimatedDeparture)

        estimatedDeparture_time = humanize.time_format("HH:mm", estimatedDeparture.in_location(originTimezone))

        ## ACTUAL DEPARTURE TIME ##

        actualDeparture = flights[0]["actual_off"] or "0000000000000000000"

        year = int(actualDeparture[0:4])
        month = int(actualDeparture[5:7])
        day = int(actualDeparture[8:10])
        hour = int(actualDeparture[11:13])
        minute = int(actualDeparture[14:16])
        second = int(actualDeparture[17:19])

        actualDeparture = time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "Europe/London")

        #actualDeparture_humanized = humanize.time(actualDeparture)

        actualDeparture_time = humanize.time_format("HH:mm", actualDeparture.in_location(originTimezone))

        ## ACTUAL ARRIVAL TIME ##

        actualArrival = flights[0]["actual_on"] or "0000000000000000000"

        year = int(actualArrival[0:4])
        month = int(actualArrival[5:7])
        day = int(actualArrival[8:10])
        hour = int(actualArrival[11:13])
        minute = int(actualArrival[14:16])
        second = int(actualArrival[17:19])

        actualArrival = time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "Europe/London")

        actualArrival_humanized = humanize.time(actualArrival)

        actualArrival_time = humanize.time_format("HH:mm", actualArrival.in_location(destinationTimezone))

        #######

        logo_cacheName = operator + "-logo"
        logo_cached = cache.get(logo_cacheName)

        if logo_cached != None:
            logo = json.decode(logo_cached)
            logoBase64 = base64.decode(logo, encoding = "standard")
            print("Found cached data! Not calling FA API for logo / " + logo_cacheName)

            base64.encode(logo, encoding = "standard")
        else:
            print("No cached data; calling FA API for logo / " + logo_cacheName)
            logo = http.get("https://flightaware.com/images/airline_logos/90p/" + operator + ".png").body()

            logoBase64Encoded = base64.encode(logo, encoding = "standard")
            logoBase64 = base64.decode(logoBase64Encoded, encoding = "standard")

            cache.set(logo_cacheName, json.encode(logoBase64Encoded), ttl_seconds = 86400)

        #logo = http.get("https://flightaware.com/images/airline_logos/90p/" + operator + ".png").body()  # Get logo to display.

        lowerMarquee = flight_number + " | " + registration + " | " + aircraftType  # Lower marquee layout.

        if status == "Scheduled":
            time_color = "#19d172"
            marquee = "Scheduled to Depart " + scheduledDept_humanized
            departureSecondary = scheduledDept_time
            arrivalSecondary = scheduledArrival_time
            departureSecondaryColor = "#f5be00"  # Orange
            arrivalSecondaryColor = "#f5be00"  # Orange
        if status == "En Route / On Time":
            time_color = "#19d172"
            marquee = "Enroute | Arriving " + estimatedArrival_humanized
            departureSecondary = actualDeparture_time
            arrivalSecondary = estimatedArrival_time
            departureSecondaryColor = "#19d172"  # Green
            arrivalSecondaryColor = "#f5be00"  # Orange
        if status == "Arrived / Gate Arrival":
            time_color = "#19d172"
            marquee = "At the Gate | Arrived " + actualArrival_humanized
            departureSecondary = actualDeparture_time
            arrivalSecondary = actualArrival_time
            departureSecondaryColor = "#19d172"  # Green
            arrivalSecondaryColor = "#19d172"  # Green
        if status == "Cancelled":
            time_color = "#C5283D"
            marquee = "Cancelled"
            departureSecondary = scheduledDept_time
            arrivalSecondary = scheduledArrival_time
            departureSecondaryColor = "#C5283D"  # Red
            arrivalSecondaryColor = "#C5283D"  # Red
        if status == "En Route":
            time_color = "#FFC857"
            marquee = "Enroute | Arriving " + estimatedArrival_humanized
            departureSecondary = actualDeparture_time
            arrivalSecondary = estimatedArrival_time
            departureSecondaryColor = "#19d172"  # Green
            arrivalSecondaryColor = "#f5be00"  # Orange
        if status == "En Route / Delayed":
            time_color = "#FFC857"
            marquee = "En Route / Delayed | Arriving " + estimatedArrival_humanized
            departureSecondary = actualDeparture_time
            arrivalSecondary = estimatedArrival_time
            departureSecondaryColor = "#C5283D"  # Red
            arrivalSecondaryColor = "#f5be00"  # Orange
        if status == "Scheduled / Delayed":
            time_color = "#FFC857"
            marquee = "Delayed | Departing " + estimatedDeparture_humanized
            departureSecondary = estimatedDeparture_time
            arrivalSecondary = estimatedArrival_time
            departureSecondaryColor = "#C5283D"  # Red
            arrivalSecondaryColor = "#f5be00"  # Orange
        if status == "Taxiing / Delayed":
            time_color = "#FFC857"
            marquee = "Taxiing / Delayed | Departing " + estimatedDeparture_humanized
            departureSecondary = estimatedDeparture_time
            arrivalSecondary = estimatedArrival_time
            departureSecondaryColor = "#C5283D"  # Red
            arrivalSecondaryColor = "#f5be00"  # Orange
        if status == "Arrived":
            time_color = "#19d172"
            marquee = "Arrived " + actualArrival_humanized
            departureSecondary = actualDeparture_time
            arrivalSecondary = actualArrival_time
            departureSecondaryColor = "#19d172"  # Green
            arrivalSecondaryColor = "#19d172"  # Green
        if status == "Landed / Taxiing":
            time_color = "#19d172"
            marquee = "Arrived " + actualArrival_humanized
            departureSecondary = actualDeparture_time
            arrivalSecondary = actualArrival_time
            departureSecondaryColor = "#19d172"  # Green
            arrivalSecondaryColor = "#19d172"  # Green

    else:
        progressBarWidth = 64
        deptCity = "Orlando"
        departureSecondary = "00:00"
        arrvCity = "Atlanta"
        arrivalSecondary = "00:00"
        originICAO = "KMCO"
        destinationICAO = "KATL"
        logoBase64 = http.get("https://avatars.githubusercontent.com/u/57181397").body()
        marquee = "Missing FlightAware API Key!"
        lowerMarquee = "Please add your FlightAware API key to the app!"
        status = "noAPI"

    return render.Root(
        child = render.Row(
            children = [
                render.Box(
                    child = render.Column(
                        expanded = True,
                        children = [
                            render.Row(
                                children = [
                                    render.Box(height = 2, width = progressBarWidth, color = time_color),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                render.Marquee(
                                                    width = 22,
                                                    child = render.Text(deptCity + " / " + originICAO, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                ),
                                                render.Animation(children = [
                                                    render.Text(departureSecondary, color = departureSecondaryColor, font = "CG-pixel-3x5-mono"),
                                                ]),
                                            ],
                                        ),
                                        width = 22,
                                        height = 17,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                render.Image(src = logoBase64, width = 16, height = 12),
                                            ],
                                        ),
                                        width = 16,
                                        height = 17,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                        height = 1,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                render.Marquee(
                                                    width = 22,
                                                    child = render.Text(arrvCity + " / " + destinationICAO, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                ),
                                                render.Animation(children = [
                                                    render.Text(arrivalSecondary, color = arrivalSecondaryColor, font = "CG-pixel-3x5-mono"),
                                                ]),
                                            ],
                                        ),
                                        width = 22,
                                        height = 17,
                                    ),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(marquee, color = time_color, font = "tom-thumb"),
                                        offset_start = 10,
                                        offset_end = 5,
                                    ),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                            ],
                                        ),
                                        width = 1,
                                    ),
                                    render.Box(
                                        child = render.Column(
                                            expanded = True,
                                            main_align = "space_evenly",
                                            cross_align = "center",
                                            children = [
                                                render.Marquee(
                                                    width = 62,
                                                    child = render.Text(lowerMarquee, color = "#8CADA7", font = "CG-pixel-3x5-mono"),
                                                    offset_start = 10,
                                                    offset_end = 5,
                                                ),
                                            ],
                                        ),
                                        width = 62,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
        delay = 100,
    )
