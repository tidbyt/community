"""
Applet: Formula 1
Summary: Next F1 Race Location
Description: Shows Time date and location of Next F1 race.
Author: AmillionAir
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 25072

# ############################
# Mods - jvivona - 2023-02-04
# - temp override URLs to bypass blacklist on API (will go back to original API after they unblock us )
# - remove location from schema - this was causing too many API hits - no need to use location anymore - use $tz now
# - only hit API endpoint we need to each time, instead of all 3
# - only execute render / vars needed for selected display option
# - change f1 API endpoints to https
# - added in US Date / Intl Date option - only triggered when showing Next Race
# - added in 24 hour / 12 hour display option - only triggered when showing Next Race
#
# jvivona - 2023-03-08
# - update Aston Martin logo
# - change WCC layout
# - added proper case names for constructors
# jvivona - 2023-05-12
# - new cache method
# jvivona - 2023-05-13
# - change scoll to show race name + locality
# - fix WCC standings alignment issue
# jvivona - 2023-05-14
# - fix trunc of am/pm - to not trunc when we're in 24 hour format
# jvivona - 20230904
# - fix date display - remove leading 0
# jvivona - 20230911 - handle end of season calendar - no upcoming races
# jvivona - 20231107 - cleanup code in for loop
# jvivona - 20240303 - added Kick Sauber & RB Honda logos - thanks to @AMillionAir
# - added code to handle missing time in API feed - updates are happening slower in 2024 & will stop for 2025 season - this is temp until we determine new plan
# jvivona - 20250313 - moved metadata to github for easier updates
# - fixed handling for beginning of season and no WCC or WDC standings yet
# - moved to new github infrastructure for data push
# ############################

# data for next race, standing all come from here: https://api.jolpi.ca/ergast/  as of 2025 - previous ergast API has been shut down and these folks took it over
# still using github for caching instead of hitting thier API directly - so we're in more control & won't get blocked potentially
# there's a shell script that goes and gets the data every so often and pushes changes into gihub

DEFAULTS = {
    "timezone": "America/New_York",
    "display": "NRI",
    "time_24": True,
    "date_us": False,
}

F1_URLS = {
    "NRI": "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/next.json",
    "CS": "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/constructorStandings.json",
    "DS": "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/driverStandings.json",
}
METADATA_URLS = {
    "TRACKS": "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/metadata/tracks.json",
    "NAMES": "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/metadata/constructor_names.json",
    "LOGOS": "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/metadata/constructor_logo.json",
}

F1_API_TTL = 1800
METADATA_TTL = 43200

def main(config):
    #TIme and date Information
    timezone = config.get("$tz", DEFAULTS["timezone"])

    # get display option - default to Next Race
    display = config.get("F1_Information", DEFAULTS["display"])

    # Get Data
    Year = time.now().in_location(timezone).format("2006")
    f1_cached = get_f1_data(F1_URLS[display].format(Year), F1_API_TTL)["MRData"]

    if display == "NRI":
        tracks = get_f1_data(METADATA_URLS["TRACKS"], METADATA_TTL)
        if len(f1_cached["RaceTable"]["Races"]) == 0:
            return []
        else:
            #Next Race
            next_race = f1_cached["RaceTable"]["Races"][0]

        # check to see if there's a time in the json, if not - set it to be TBD
        if (next_race.get("time", "TBD")) == "TBD":
            # no time - date is probably correct in UTC
            date_and_time = next_race["date"] + "T" + "12:00:00Z"
            date_and_time3 = time.parse_time(date_and_time, "2006-01-02T15:04:05Z", "UTC").in_location(timezone)
            time_str = "TBD"
        else:
            date_and_time = next_race["date"] + "T" + next_race["time"]

            #code from @whyamihere to automatically adjust the date time sting from the API
            date_and_time3 = time.parse_time(date_and_time, "2006-01-02T15:04:05Z", "UTC").in_location(timezone)
            time_str = date_and_time3.format("15:04" if config.bool("time_24", DEFAULTS["time_24"]) else "3:04pm").replace("m", "")  #outputs military time but can change 15 to 3 to not do that. The Only thing missing from your current string though is the time zone, but if they're doing local time that's pretty irrelevant

        # handle date & time display options here
        date_str = date_and_time3.format("Jan 2" if config.bool("date_us", DEFAULTS["date_us"]) else "2 Jan")  #current format of your current date str

        return render.Root(
            child = render.Column(
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text(" " + next_race["raceName"] + " - " + next_race["Circuit"]["Location"]["locality"] + " " + next_race["Circuit"]["Location"]["country"]),
                        offset_start = 5,
                        offset_end = 5,
                    ),
                    render.Box(width = 64, height = 1, color = "#a0a"),
                    render.Row(
                        children = [
                            render.Image(src = base64.decode(tracks[next_race["Circuit"]["circuitId"].lower()]), height = 23, width = 28),
                            render.Column(
                                children = [
                                    render.Text(date_str, font = "5x8"),
                                    render.Text(time_str),
                                    render.Text("Race " + next_race["round"]),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

    elif display == "CS":
        logos = get_f1_data(METADATA_URLS["LOGOS"], METADATA_TTL)
        names = get_f1_data(METADATA_URLS["NAMES"], METADATA_TTL)
        #Constructor

        if len(f1_cached["StandingsTable"]["StandingsLists"]) == 0:
            return []

        standings = f1_cached["StandingsTable"]["StandingsLists"][0]
        Constructor1 = standings["ConstructorStandings"][0]["Constructor"]["constructorId"]
        Constructor2 = standings["ConstructorStandings"][1]["Constructor"]["constructorId"]
        Constructor3 = standings["ConstructorStandings"][2]["Constructor"]["constructorId"]

        Points1 = text_justify_trunc(3, standings["ConstructorStandings"][0]["points"], "right")
        Points2 = text_justify_trunc(3, standings["ConstructorStandings"][1]["points"], "right")
        Points3 = text_justify_trunc(3, standings["ConstructorStandings"][2]["points"], "right")

        return render.Root(
            child = render.Column(
                children = [
                    render.Text("WCC Standings"),
                    render.Box(width = 64, height = 1, color = "#a0a"),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(src = base64.decode(logos[Constructor1])),
                                    render.Text("1", font = "5x8"),
                                ],
                            ),
                            render.Marquee(
                                width = 50,
                                child = render.Text(Points1 + " pts - " + text_justify_trunc(12, names[Constructor1], "left"), font = "5x8"),
                                offset_start = 64,
                                offset_end = 64,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(src = base64.decode(logos[Constructor2])),
                                    render.Text("2", font = "5x8"),
                                ],
                            ),
                            render.Marquee(
                                width = 50,
                                child = render.Text(Points2 + " pts - " + text_justify_trunc(12, names[Constructor2], "left"), font = "5x8"),
                                offset_start = 64,
                                offset_end = 64,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(src = base64.decode(logos[Constructor3])),
                                    render.Text("3", font = "5x8"),
                                ],
                            ),
                            render.Marquee(
                                width = 50,
                                child = render.Text(Points3 + " pts - " + text_justify_trunc(12, names[Constructor3], "left"), font = "5x8"),
                                offset_start = 64,
                                offset_end = 64,
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        #Driver
        if len(f1_cached["StandingsTable"]["StandingsLists"]) == 0:
            return []

        standings = f1_cached["StandingsTable"]["StandingsLists"][0]

        #F1_FNAME = standings["DriverStandings"][0]["Driver"]["givenName"]
        F1_LNAME = standings["DriverStandings"][0]["Driver"]["familyName"]
        F1_POINTS = text_justify_trunc(3, standings["DriverStandings"][0]["points"], "right")

        #F1_FNAME2 = standings["DriverStandings"][1]["Driver"]["givenName"]
        F1_LNAME2 = standings["DriverStandings"][1]["Driver"]["familyName"]
        F1_POINTS2 = text_justify_trunc(3, standings["DriverStandings"][1]["points"], "right")

        #F1_FNAME3 = standings["DriverStandings"][2]["Driver"]["givenName"]
        F1_LNAME3 = standings["DriverStandings"][2]["Driver"]["familyName"]
        F1_POINTS3 = text_justify_trunc(3, standings["DriverStandings"][2]["points"], "right")

        return render.Root(
            child = render.Column(
                children = [
                    render.Text("WDC Standings"),
                    render.Box(width = 64, height = 1, color = "#a0a"),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(width = 14, height = 7),
                                    render.Text(F1_POINTS, font = "5x8"),
                                ],
                            ),
                            render.Box(width = 2, height = 5),
                            render.Text(F1_LNAME),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(width = 14, height = 7),
                                    render.Text(F1_POINTS2, font = "5x8"),
                                ],
                            ),
                            render.Box(width = 2, height = 5),
                            render.Text(F1_LNAME2),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(width = 14, height = 7),
                                    render.Text(F1_POINTS3, font = "5x8"),
                                ],
                            ),
                            render.Box(width = 2, height = 5),
                            render.Text(F1_LNAME3),
                        ],
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "F1_Information",
                name = "F1 Information",
                desc = "Select which info you want",
                icon = "flagCheckered",
                default = DEFAULTS["display"],
                options = [
                    schema.Option(
                        display = "Constructor Standings",
                        value = "CS",
                    ),
                    schema.Option(
                        display = "Driver Standings",
                        value = "DS",
                    ),
                    schema.Option(
                        display = "Next Race Information",
                        value = "NRI",
                    ),
                ],
            ),
            schema.Generated(
                id = "generated",
                source = "F1_Information",
                handler = nri_options,
            ),
        ],
    )

def nri_options(f1_option):
    if f1_option == "NRI":
        return [
            schema.Toggle(
                id = "time_24",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = DEFAULTS["time_24"],
            ),
            schema.Toggle(
                id = "date_us",
                name = "US Date format",
                desc = "Display the date in US format.",
                icon = "calendarDays",
                default = DEFAULTS["date_us"],
            ),
        ]
    else:
        return []

def get_f1_data(url, ttl):
    http_data = http.get(url, ttl_seconds = ttl)
    if http_data.status_code != 200:
        fail("HTTP request failed with status {} for URL {}".format(http_data.status_code, url))

    f1_details = http_data.body()
    if f1_details.startswith("Unable"):
        fail("API having database issues, check again later URL {}".format(url))

    return json.decode(f1_details)

def text_justify_trunc(length, text, direction):
    #  thanks to @inxi and @whyamihere / @rs7q5 for the codepoints() and codepoints_ords() help
    chars = list(text.codepoints())
    textlen = len(chars)

    # if string is shorter than desired - we can just use the count of chars (not bytes) and add on spaces - we're good
    if textlen < length:
        for _ in range(length - textlen):
            text = " " + text if direction == "right" else text + " "
    else:
        # text is longer - need to trunc it get the list of characters & trunc at length
        text = ""  # clear out text
        for i in range(length):
            text = text + chars[i]

    return text
