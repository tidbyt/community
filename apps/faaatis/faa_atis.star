"""
Applet: FAA ATIS
Summary: ATIS runway information
Description: Display FAA ATIS information (runways in use) for a given airport.
Author: Connick Shields
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# Theme
TEXT_COLOR = "#FFFFFF"
INFO_COLOR = "#4CAF50"
ARR_COLOR = "#2196F3"  # Blue for arrivals
DEP_COLOR = "#FFC107"  # Amber for departures
DEFAULT_FONT = "tom-thumb"

ATIS_CACHE_TTL = 300  # 5 minutes
AIRPORT_DB_CACHE_TTL = 28800  # 8 hours
API_URL = "https://datis.clowd.io/api/"
AIRPORT_DB_URL = "https://airportdb.io/api/v1/airport/{icao}?apiToken={token}"

AIRPORT_DB_API_TOKEN = secret.decrypt("AV6+xWcEQXjzZyOEHWUuwx3QFq57+plCzYbcCRaaDX0c6HkPPQDRqozjj6aSfiC+s23hwG4UavuLJ9+oJMqIsSXJyvtI78upbEqm12DZZSUjTzXfYQalOjY0rJHN/Rzm19uAwIPq+xSZVCfRk4HodnpoD5QNiV0ilGzliejPdyb15Pa+0lM7JUvO5yL4O9rmqL8EOGqbdyfK1Igre83QQ1kMU+OZaTtYRKsv0hHyBiLRyFabOrSKRs8cHGxaCzxzxrA9ieyM")

def debug_print(label, value):
    """Helper function to print debug info"""
    print("%s: %s" % (label, json.encode(value)))

def get_airport_runways(icao):
    """Fetch runway information from airport database."""

    url = AIRPORT_DB_URL.format(icao = icao, token = AIRPORT_DB_API_TOKEN)
    response = http.get(url, ttl_seconds = AIRPORT_DB_CACHE_TTL)

    if response.status_code != 200:
        debug_print("Error fetching airport data", response.status_code)
        return []

    data = response.json()
    if not data or "runways" not in data:
        debug_print("No runway data found", data)
        return []

    runways = []
    for rwy in data["runways"]:
        # Skip closed runways
        if rwy.get("closed") == "1":
            debug_print("Skipping closed runway", rwy.get("le_ident", "") + "/" + rwy.get("he_ident", ""))
            continue

        # Get both ends of the runway
        le_ident = rwy.get("le_ident", "")
        he_ident = rwy.get("he_ident", "")

        # Add both ends to our runway list
        runways.append(le_ident)
        runways.append(he_ident)

    debug_print("Airport runways", runways)
    return runways

def extract_number(runway):
    """Extract the numeric part of a runway designator."""
    if runway.isdigit():
        return int(runway)

    # For runways like "28R", take just the numeric part
    num = runway[:-1] if runway[-1] in ["L", "R", "C"] else runway
    return int(num)

def extract_runways(text, icao):
    # Get valid runways for this airport
    valid_runways = get_airport_runways(icao)
    if not valid_runways:
        return [], []

    # Split on NOTAM and take only the first part
    main_atis = text.split("NOTAM")[0].split("...ADVS")[0]
    debug_print("Main ATIS section", main_atis)

    runways = {}  # Use dict to track runway usage
    state = {
        "processed_arrivals": False,
        "processed_departures": False,
    }

    def is_valid_runway(word):
        """Check if a word is a valid runway number for this airport."""
        word = word.strip(",.").replace(",", "")

        # First check if it's a valid runway format
        if not ((word.isdigit() and (len(word) == 1 or len(word) == 2)) or
                (len(word) == 2 and word[0].isdigit() and word[1] in ["L", "R", "C"]) or
                (len(word) == 3 and word[0:2].isdigit() and word[2] in ["L", "R", "C"])):
            return False

        if len(word) == 1:
            word = "0" + word

        if len(word) == 2 and word[1] in ["L", "R", "C"]:
            word = "0" + word

        # Then check if it exists at this airport
        if word in valid_runways:
            return True
        return False

    def process_sentence(sentence):
        debug_print("Processing sentence", sentence)

        # Skip LAHSO and equipment information
        if "HOLD SHORT" in sentence or "PAPIS" in sentence or "EQUIPMENT" in sentence or "CONDITION" in sentence:
            return

        # Skip closures
        if "CLSD" in sentence or "CLOSED" in sentence or "OTS" in sentence:
            return

        sentence_upper = sentence.upper()

        # Track current state
        current_mode = None  # None, "ARR", or "DEP"
        arrival_runways = []
        departure_runways = []

        arrival_sentence = (
            "APCH" in sentence_upper or
            "APP" in sentence_upper or
            "APPROACH" in sentence_upper or
            "LNDG" in sentence_upper or
            "LAND" in sentence_upper or
            "ARR" in sentence_upper or
            "VISUAL" in sentence_upper or
            "VA" == sentence_upper or
            "ILS" in sentence_upper
        )

        current_mode = "ARR" if arrival_sentence else None

        # Process each word
        words = sentence.split()
        for word in words:
            word_upper = word.upper()

            # Check for mode changes
            is_arrival = (
                "APCH" in word_upper or
                "APP" in word_upper or
                "APPROACH" in word_upper or
                "LNDG" in word_upper or
                "LAND" in word_upper or
                "ARR" in word_upper or
                "VISUAL" in word_upper or
                "VA" == word_upper or
                "ILS" in word_upper
            )

            is_departure = (
                "DEP" in word_upper or
                "DEPG" in word_upper or
                "DEPS" in word_upper or
                "DEPART" in word_upper or
                "DEPARTURE" in word_upper
            )

            if is_arrival:
                debug_print("Found arrival indicator", word_upper)
                current_mode = "ARR"
                continue

            if is_departure:
                debug_print("Found departure indicator", word_upper)
                current_mode = "DEP"
                continue

            if is_valid_runway(word):
                if current_mode == "ARR":
                    arrival_runways.append(word.strip(",.").replace(",", ""))
                elif current_mode == "DEP":
                    debug_print("Adding departure runway", word)
                    departure_runways.append(word.strip(",.").replace(",", ""))
                else:
                    # If no previous mode, mark for both
                    debug_print("Adding runway for both", word)
                    arrival_runways.append(word.strip(",.").replace(",", ""))
                    departure_runways.append(word.strip(",.").replace(",", ""))

        if len(arrival_runways) > 0:
            state["processed_arrivals"] = True
            for rwy in arrival_runways:
                if rwy not in runways:
                    runways[rwy] = {"A": True, "D": False}
                else:
                    runways[rwy]["A"] = True

        if len(departure_runways) > 0:
            state["processed_departures"] = True
            debug_print("Processing departure runways", departure_runways)
            for rwy in departure_runways:
                if rwy not in runways:
                    runways[rwy] = {"A": False, "D": True}
                else:
                    runways[rwy]["D"] = True

    # Split into sentences and clean them
    sentences = []
    for s in main_atis.split("."):
        if s.strip():
            sentences.append(s.strip())

    # Process each sentence
    for sentence in sentences:
        process_sentence(sentence)

        # If we've processed both arrivals and departures, we can stop
        if state["processed_arrivals"] and state["processed_departures"]:
            debug_print("Found both arrivals and departures, stopping processing", "")
            break

    # Separate arrivals and departures
    arrivals = []
    departures = []

    # Sort runways by number first
    sorted_runways = sorted(runways.items(), key = lambda x: extract_number(x[0]))

    for rwy, usage in sorted_runways:
        if usage["A"]:
            arrivals.append(rwy)
        if usage["D"]:
            departures.append(rwy)

    debug_print("Arrivals", arrivals)
    debug_print("Departures", departures)
    return arrivals, departures

def main(config):
    # Load config settings from mobile app, or set default
    config_airport = config.str("airport", "KDCA")

    api_url = "{api}{airport}".format(
        api = API_URL,
        airport = config_airport,
    )

    # Get data from API
    response = http.get(api_url, ttl_seconds = ATIS_CACHE_TTL)
    if response.status_code != 200:
        return render.Root(
            child = render.Text("API Error", font = DEFAULT_FONT),
        )

    atis_data = response.json()[0]  # Get first ATIS entry

    # Extract key information
    airport = atis_data.get("airport", "")
    atis_code = atis_data.get("code", "")
    datis = atis_data.get("datis", "")

    # Extract active runways
    arrivals, departures = extract_runways(datis, airport)
    if len(departures) == 0:
        departures = arrivals

    # Format runway lists
    arr_runways = " ".join(arrivals) if arrivals else "NONE"
    dep_runways = " ".join(departures) if departures else "NONE"

    # Format header with right-aligned INFO code
    info_text = "%s" % atis_code

    return render.Root(
        child = render.Box(
            padding = 1,  # Add 1 pixel padding around all content
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Text(" ", font = DEFAULT_FONT),
                            render.Text(airport, color = TEXT_COLOR, font = DEFAULT_FONT),
                            render.Text("   INFO ", font = DEFAULT_FONT),  # Space between parts
                            render.Text(info_text, color = INFO_COLOR, font = DEFAULT_FONT),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Text(" ARR: ", color = ARR_COLOR, font = DEFAULT_FONT, height = 8),
                            render.Marquee(
                                width = 36,
                                child = render.Text(arr_runways, color = ARR_COLOR, font = DEFAULT_FONT, height = 8),
                                offset_start = 0,  # Start from right edge
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Text(" DEP: ", color = DEP_COLOR, font = DEFAULT_FONT, height = 8),
                            render.Marquee(
                                width = 36,
                                child = render.Text(dep_runways, color = DEP_COLOR, font = DEFAULT_FONT, height = 8),
                                offset_start = 0,  # Start from right edge
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "airport",
                name = "Airport",
                desc = "4-letter ICAO airport code",
                icon = "plane",
                default = "KDCA",
            ),
        ],
    )
