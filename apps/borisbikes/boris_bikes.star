"""
Applet: Boris Bikes
Summary: London street bikes
Description: Availability for a Santander bicycle dock in London.
Author: dinosaursrarr
"""

load("cache.star", "cache")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

BIKE_IMAGE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACgAAAAYCAYAAACIhL/AAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAKKADAAQAAAABAAAAGAAAAADbx94qAAACIElEQVRIDe2VMUrEQBSG4+IZFryCBxAsxAWt9BKC3kAWtLCyUFi8gYIXERQLYQ9gZWch2FvH+d/mn/0zyWRmXLYzEOfN5P/f++ZlslbV/+U7UPuoIBgVaP8knZ5f1bgbs40yT+ZcO+Ds7noDFA7K7iRRINgM5smp7p7FUybo4Ds+OoSU3UzZ7LntLkvpRAqnnlzQ56eXenKwX1RT6xTFKFZkcGJ4Sn1rP4N+Ezu39eTyzaYlkP1n0CXziRnMLzqvBoWyXllfPuZNjO2ikuj7695bx1tnPq4EtBiw8Zqv6SYST/d+LH/fWV4CNnAKtqRaRAR9vtn1j5IddHmR07wAdHP61asfoIIuADPgSPT++GAhkvMsaSHqbGzgEI8/PwzO1h1orPsEJaT/SIY6Z0ndHw+H1+OKR8FgGIBjPm6Qc4wEI6gB4gxgh3qrCTHhtk9Oq+RmmjcCX9g5rOEa2hwhoRuRFBO9CAswhVMN41YnQjiK5OPiEsaWVx+4GGzWQSUONDZF13DrxS+v1QmB069dfRq3vPrAxWTq/x1sxNydvaYgwTT8nzoAh83M5kGCzOkgIH/5ceDDfLNXt9Ksex1EkVcZ+jkf6iI0/iumYaVxAC521mP1vB6Bn8TUwXqpHvZSD/UjHkYuBCydaa6uYyyA7K2Bxd4HUilHI/JOmOMPNcv/xcEO2VlUUXBd7xBkLMRyxdZbgMyvYq6tCsY8HHNr/AIqRDFbkUuQeQAAAABJRU5ErkJggg==")

# Unceremoniously nicked from Martin Strauss's baywheels app
LIGHTNING_IMAGE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAp/sAAKf7ATxDYQ0AAAMySURBVFhHtZZPSFRRFMbPueMfjApcRH8giAiCqNSZ/mlWFGKBFZqaWBS1aRFtgmiXJW6kldCmRdEqcHTIEauFYFGZBTojmZuiIlpERASBWfGce/rezG3CZubNe+Prt3lzvufwnfvdc+/I9B+Q25vKpbS4Fx9XcnO8gpkk9SYTZZ6+IQMVa6S0ZJSJ61H+cDK38bUBHQ5tk0TgGWLdAFfbuCP1Jje+NSCRUCMF5CFWviIlyFNuiQ8nPzuw4AZEiHV/6LygBZgvMjIRUweScIzfZkFDKH2tAeG3Pcx8zkhJ4DqiWmJ1pnSk4AR0tGaJ0LtoFnNNCX3JlHkpKAEdrVpFFg/BPGikNCJyX7XGG0yZF88J6N7KCpg/z2pur57ksild4akB3R+spyL1GOarjTQfoUHVOjlhKle4bkAiwTN43MOkL00p88EpmCPFec/9v+RtAMdMwbwbp+06Vl5k5EyEIqp5YtpUrnEcQh3eUUbKuoXrtM1IWcHgzVGx2qgaJ14ZyTU5G9DhymUUUFFEXmOknCD+r/i7EVPmY1bYuqiapz7bRdYGdHjLelyrd/FynZF8A1uKk8K7VOvEmF1nzICOVO2mgB77T+a/SMuJP+Y28xLQfcHjxHwTe15qJN/AnHzB4wguqScpJUW6AekL1QoTzrjzYBYCLqg3ZKkG1T7+2khp0mZ6cPtysqyr8C8zkiOIsw7NlpsyJxjQUS7hJj4csxPIoKDV6iiGdE5Po9nc9wJAk2GeWXyKTz/6aaQMPP8WJLGk08kcxthy6ebp2DEncxvPCej+qs3EahJfzNo8jC3kflYdjd8wkiMFJKCu5DIH37CkQ27NbTwlIAPBkMzxeLaTgtQ/UIIOqrb4SyO5wlMCkqCuHMc0RkVS7dXcxnUDOhLaicAOmDINBm5IZq09qnHyo5E84SUBTP7f1eNysYf9GsvaJnVy6ruRPeNqBnQkuBfJPzClvd8J/KRcwLD1GKlg8iaAZdq73mVKe+UzEFr8MLfJ38CdrftZGPufXPkn/Fjt45ZYNPnSB/LPgCQ6kw+RabYS1fi3azyp+4RjA8n4icqw8mGkUMvtL96n3vgF0W/iaRpXqhpMFQAAAABJRU5ErkJggg==")

# Hackney is for cycling.
DEFAULT_DOCK_ID = "BikePoints_614"

# Allows 500 queries per minute
ENCRYPTED_APP_KEY = "AV6+xWcEJKHv8HrhH6FLyaWzsz0i+mcRr8QYac5oRBnj3Cruqdg/l/CuruDiOf4ILRyQPe5/7yoV3Wu8kdXr6WC4rK4FH/1FDuJksEGpdW9NKQj9m/mO3JH/s8B4ygGnPwstFgB/OWHTJh/92hu1hcpGVLhj4QHTY7Eai7HMqKg94x4Sk9I="
LIST_DOCKS_URL = "https://api.tfl.gov.uk/BikePoint"
DOCK_URL = "https://api.tfl.gov.uk/BikePoint/%s"

def app_key():
    return secret.decrypt(ENCRYPTED_APP_KEY) or ""  # Fall back to freebie quota

def fetch_docks():
    cached = cache.get(LIST_DOCKS_URL)
    if cached:
        return json.decode(cached)
    resp = http.get(
        LIST_DOCKS_URL,
        params = {
            "app_key": app_key(),
        },
    )
    if resp.status_code != 200:
        fail("TFL BikePoint query failed with status ", resp.status_code)
    cache.set(LIST_DOCKS_URL, resp.body(), ttl_seconds = 86400)  # Bike docks don't move often
    return resp.json()

def list_docks(location):
    loc = json.decode(location)
    docks = fetch_docks()
    options = []
    for dock in docks:
        id = dock["id"]
        name = dock["commonName"]
        lat = dock["lat"]
        lon = dock["lon"]
        if None in (id, name, lat, lon):
            fail("TFL Bikepoint query missing required field: ", dock)
        option = schema.Option(
            display = name,
            value = id,
        )
        distance = math.pow(lat - float(loc["lat"]), 2) + math.pow(lon - float(loc["lng"]), 2)
        options.append((option, distance))
    options = sorted(options, key = lambda x: x[1])
    return [option[0] for option in options]

def fetch_dock(dock_id):
    cached = cache.get(dock_id)
    if cached:
        return json.decode(cached)
    resp = http.get(
        DOCK_URL % dock_id,
        params = {
            "app_key": app_key(),
        },
    )
    if resp.status_code != 200:
        fail("TFL BikePoint request failed with status ", resp.status_code)
    cache.set(dock_id, resp.body(), ttl_seconds = 30)
    return resp.json()

def tidy_name(name):
    if not name:
        fail("TFL BikePoint request did not contain dock name")

    # Don't need the bit of town, user chose the location.
    comma = name.rfind(",")
    name = name[:comma].strip()

    # Abbreviate some common words to fit on screen better.
    words = name.split(" ")
    for i in range(len(words)):
        if words[i] == "Street":
            words[i] = "St"
        if words[i] == "Road":
            words[i] = "Rd"
        if words[i] == "Avenue":
            words[i] = "Ave"

    return " ".join(words)

def get_dock(dock_id):
    resp = fetch_dock(dock_id)
    name = tidy_name(resp["commonName"])
    acoustic_count = 0
    electric_count = 0
    for property in resp["additionalProperties"]:
        if property["key"] == "NbStandardBikes":
            acoustic_count = int(property["value"])
        if property["key"] == "NbEBikes":
            electric_count = int(property["value"])
    return name, acoustic_count, electric_count

def main(config):
    dock = config.get("dock")
    if dock:
        dock_id = json.decode(dock)["value"]
    else:
        dock_id = DEFAULT_DOCK_ID
    dock_name, acoustic_count, electric_count = get_dock(dock_id)

    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Marquee(
                        child = render.Text(dock_name),
                        scroll_direction = "horizontal",
                        width = 62,
                        height = 8,
                    ),
                ),

                # Bike picture
                render.Padding(
                    pad = (1, 7, 0, 0),
                    child = render.Image(BIKE_IMAGE),
                ),

                # Bike stats
                render.Padding(
                    pad = (44, 8, 0, 0),
                    child = render.Stack(
                        children = [
                            # Acoustic bikes
                            render.Padding(
                                pad = (9, 4, 0, 0),
                                child = render.WrappedText(
                                    content = "{}".format(acoustic_count),
                                    width = 10,
                                    align = "right",
                                ),
                            ),
                            # Electric bikes
                            render.Padding(
                                pad = (0, 14, 0, 0),
                                child = render.Image(
                                    src = LIGHTNING_IMAGE,
                                    width = 8,
                                    height = 8,
                                ),
                            ),
                            render.Padding(
                                pad = (9, 14, 0, 0),
                                child = render.WrappedText(
                                    content = "{}".format(electric_count),
                                    width = 10,
                                    align = "right",
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "dock",
                name = "Dock",
                desc = "The bike dock to check capacity for",
                icon = "bicycle",
                handler = list_docks,
            ),
        ],
    )
