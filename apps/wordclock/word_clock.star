"""
Applet: Word Clock
Author: Jeffrey Lancaster
Summary: Accurate human readable time
Description: Display the accurate time in a human-readable way. Inspired by Max Timkovich's Fuzzy Clock.
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = {
    "lat": 40.7,
    "lng": -74.0,
    "locality": "Brooklyn",
}
DEFAULT_TIMEZONE = "US/Eastern"

# h is whether to use the subsequent hour word
# o is whether the text comes before (1) or after (2) the hour word

minutesObj = {
    "en-US": {
        "0": [
            {"text": ["hundred"], "h": 0, "o": 2, "military": True},
            {"text": ["o'clock"], "h": 0, "o": 2},
            {"text": [], "h": 0, "o": 1},
        ],
        "1": [
            {"text": ["zero one"], "h": 0, "o": 2, "military": True},
            {"text": ["oh one"], "h": 0, "o": 2},
            {"text": ["one", "past"], "h": 0, "o": 1},
            {"text": ["one", "after"], "h": 0, "o": 1},
        ],
        "2": [
            {"text": ["zero two"], "h": 0, "o": 2, "military": True},
            {"text": ["oh two"], "h": 0, "o": 2},
            {"text": ["two", "past"], "h": 0, "o": 1},
            {"text": ["two", "after"], "h": 0, "o": 1},
        ],
        "3": [
            {"text": ["zero three"], "h": 0, "o": 2, "military": True},
            {"text": ["oh three"], "h": 0, "o": 2},
            {"text": ["three", "past"], "h": 0, "o": 1},
            {"text": ["three", "after"], "h": 0, "o": 1},
        ],
        "4": [
            {"text": ["zero four"], "h": 0, "o": 2, "military": True},
            {"text": ["oh four"], "h": 0, "o": 2},
            {"text": ["four", "past"], "h": 0, "o": 1},
            {"text": ["four", "after"], "h": 0, "o": 1},
        ],
        "5": [
            {"text": ["zero five"], "h": 0, "o": 2, "military": True},
            {"text": ["oh five"], "h": 0, "o": 2},
            {"text": ["five", "past"], "h": 0, "o": 1},
            {"text": ["five", "after"], "h": 0, "o": 1},
        ],
        "6": [
            {"text": ["zero six"], "h": 0, "o": 2, "military": True},
            {"text": ["oh six"], "h": 0, "o": 2},
            {"text": ["six", "past"], "h": 0, "o": 1},
            {"text": ["six", "after"], "h": 0, "o": 1},
        ],
        "7": [
            {"text": ["zero seven"], "h": 0, "o": 2, "military": True},
            {"text": ["oh seven"], "h": 0, "o": 2},
            {"text": ["seven", "past"], "h": 0, "o": 1},
            {"text": ["seven", "after"], "h": 0, "o": 1},
        ],
        "8": [
            {"text": ["zero eight"], "h": 0, "o": 2, "military": True},
            {"text": ["oh eight"], "h": 0, "o": 2},
            {"text": ["eight", "past"], "h": 0, "o": 1},
            {"text": ["eight", "after"], "h": 0, "o": 1},
        ],
        "9": [
            {"text": ["zero nine"], "h": 0, "o": 2, "military": True},
            {"text": ["oh nine"], "h": 0, "o": 2},
            {"text": ["nine", "past"], "h": 0, "o": 1},
            {"text": ["nine", "after"], "h": 0, "o": 1},
        ],
        "10": [
            {"text": ["ten"], "h": 0, "o": 2},
            {"text": ["ten", "past"], "h": 0, "o": 1},
            {"text": ["ten", "after"], "h": 0, "o": 1},
        ],
        "11": [{"text": ["eleven"], "h": 0, "o": 2}],
        "12": [{"text": ["twelve"], "h": 0, "o": 2}],
        "13": [{"text": ["thirteen"], "h": 0, "o": 2}],
        "14": [{"text": ["fourteen"], "h": 0, "o": 2}],
        "15": [
            {"text": ["fifteen"], "h": 0, "o": 2},
            {"text": ["quarter", "past"], "h": 0, "o": 1},
            {"text": ["quarter", "after"], "h": 0, "o": 1},
        ],
        "16": [{"text": ["sixteen"], "h": 0, "o": 2}],
        "17": [{"text": ["seventeen"], "h": 0, "o": 2}],
        "18": [{"text": ["eighteen"], "h": 0, "o": 2}],
        "19": [{"text": ["nineteen"], "h": 0, "o": 2}],
        "20": [{"text": ["twenty"], "h": 0, "o": 2}],
        "21": [{"text": ["twenty-one"], "h": 0, "o": 2}],
        "22": [{"text": ["twenty-two"], "h": 0, "o": 2}],
        "23": [{"text": ["twenty-three"], "h": 0, "o": 2}],
        "24": [{"text": ["twenty-four"], "h": 0, "o": 2}],
        "25": [{"text": ["twenty-five"], "h": 0, "o": 2}],
        "26": [{"text": ["twenty-six"], "h": 0, "o": 2}],
        "27": [{"text": ["twenty-seven"], "h": 0, "o": 2}],
        "28": [{"text": ["twenty-eight"], "h": 0, "o": 2}],
        "29": [{"text": ["twenty-nine"], "h": 0, "o": 2}],
        "30": [
            {"text": ["thirty"], "h": 0, "o": 2},
            {"text": ["half", "past"], "h": 0, "o": 1},
            {"text": ["half"], "h": 0, "o": 1},
        ],
        "31": [{"text": ["thirty-one"], "h": 0, "o": 2}],
        "32": [{"text": ["thirty-two"], "h": 0, "o": 2}],
        "33": [{"text": ["thirty-three"], "h": 0, "o": 2}],
        "34": [{"text": ["thirty-four"], "h": 0, "o": 2}],
        "35": [{"text": ["thirty-five"], "h": 0, "o": 2}],
        "36": [{"text": ["thirty-six"], "h": 0, "o": 2}],
        "37": [{"text": ["thirty-seven"], "h": 0, "o": 2}],
        "38": [{"text": ["thirty-eight"], "h": 0, "o": 2}],
        "39": [{"text": ["thirty-nine"], "h": 0, "o": 2}],
        "40": [
            {"text": ["forty"], "h": 0, "o": 2},
            {"text": ["twenty", "til"], "h": 1, "o": 1},
            {"text": ["twenty", "to"], "h": 1, "o": 1},
        ],
        "41": [{"text": ["forty-one"], "h": 0, "o": 2}],
        "42": [{"text": ["forty-two"], "h": 0, "o": 2}],
        "43": [{"text": ["forty-three"], "h": 0, "o": 2}],
        "44": [{"text": ["forty-four"], "h": 0, "o": 2}],
        "45": [
            {"text": ["forty-five"], "h": 0, "o": 2},
            {"text": ["quarter", "til"], "h": 1, "o": 1},
            {"text": ["quarter", "to"], "h": 1, "o": 1},
        ],
        "46": [{"text": ["forty-six"], "h": 0, "o": 2}],
        "47": [{"text": ["forty-seven"], "h": 0, "o": 2}],
        "48": [{"text": ["forty-eight"], "h": 0, "o": 2}],
        "49": [{"text": ["forty-nine"], "h": 0, "o": 2}],
        "50": [
            {"text": ["fifty"], "h": 0, "o": 2},
            {"text": ["ten", "til"], "h": 1, "o": 1},
            {"text": ["ten", "to"], "h": 1, "o": 1},
        ],
        "51": [
            {"text": ["fifty-one"], "h": 0, "o": 2},
            {"text": ["nine", "til"], "h": 1, "o": 1},
            {"text": ["nine", "to"], "h": 1, "o": 1},
        ],
        "52": [
            {"text": ["fifty-two"], "h": 0, "o": 2},
            {"text": ["eight", "til"], "h": 1, "o": 1},
            {"text": ["eight", "to"], "h": 1, "o": 1},
        ],
        "53": [
            {"text": ["fifty-three"], "h": 0, "o": 2},
            {"text": ["seven", "til"], "h": 1, "o": 1},
            {"text": ["seven", "to"], "h": 1, "o": 1},
        ],
        "54": [
            {"text": ["fifty-four"], "h": 0, "o": 2},
            {"text": ["six", "til"], "h": 1, "o": 1},
            {"text": ["six", "to"], "h": 1, "o": 1},
        ],
        "55": [
            {"text": ["fifty-five"], "h": 0, "o": 2},
            {"text": ["five", "til"], "h": 1, "o": 1},
            {"text": ["five", "to"], "h": 1, "o": 1},
        ],
        "56": [
            {"text": ["fifty-six"], "h": 0, "o": 2},
            {"text": ["four", "til"], "h": 1, "o": 1},
            {"text": ["four", "to"], "h": 1, "o": 1},
        ],
        "57": [
            {"text": ["fifty-seven"], "h": 0, "o": 2},
            {"text": ["three", "til"], "h": 1, "o": 1},
            {"text": ["three", "to"], "h": 1, "o": 1},
        ],
        "58": [
            {"text": ["fifty-eight"], "h": 0, "o": 2},
            {"text": ["two", "til"], "h": 1, "o": 1},
            {"text": ["two", "to"], "h": 1, "o": 1},
        ],
        "59": [
            {"text": ["fifty-nine"], "h": 0, "o": 2},
            {"text": ["one", "til"], "h": 1, "o": 1},
            {"text": ["one", "to"], "h": 1, "o": 1},
        ],
    },
}

timeOfDayObj = {
    "en-US": [
        {"hourMin": 0, "hourMax": 12, "text": [["in the", "morning"], ["AM"]]},
        {"hourMin": 12, "hourMax": 17, "text": [["in the", "afternoon"], ["PM"]]},
        {"hourMin": 17, "hourMax": 21, "text": [["in the", "evening"], ["PM"]]},
        {"hourMin": 21, "hourMax": 24, "text": [["at night"], ["PM"]]},
    ],
}

hoursObj = {
    "en-US": {
        "0": ["twelve", "zero"],
        "1": ["one"],
        "2": ["two"],
        "3": ["three"],
        "4": ["four"],
        "5": ["five"],
        "6": ["six"],
        "7": ["seven"],
        "8": ["eight"],
        "9": ["nine"],
        "10": ["ten"],
        "11": ["eleven"],
        "12": ["twelve"],
        "13": ["one", "thirteen"],
        "14": ["two", "fourteen"],
        "15": ["three", "fifteen"],
        "16": ["four", "sixteen"],
        "17": ["five", "seventeen"],
        "18": ["six", "eighteen"],
        "19": ["seven", "nineteen"],
        "20": ["eight", "twenty"],
        "21": ["nine", "twenty-one"],
        "22": ["ten", "twenty-two"],
        "23": ["eleven", "twenty-three"],
    },
}

gameOfThronesObj = {
    "en-US": {
        "stem": "hour of the ",
        "0": "owl",
        "1": "owl",
        "2": "wolf",
        "3": "wolf",
        "4": "nightengale",
        "5": "nightengale",
        "6": "",
        "7": "",
        "8": "",
        "9": "",
        "10": "",
        "11": "",
        "12": "",
        "13": "",
        "14": "",
        "15": "",
        "16": "",
        "17": "",
        "18": "bat",
        "19": "bat",
        "20": "eel",
        "21": "eel",
        "22": "ghosts",
        "23": "ghosts",
    },
}

specialObj = {
    "en-US": {
        "0:0": [["midnight"], ["twelve"], ["twelve", "o'clock"]],
        "12:0": [["noon"], ["twelve"], ["twelve", "o'clock"]],
    },
}

def military_time(hour, min, hours, minutes):
    returnTime = []

    # add hour text
    hourText = ""
    if hour < 10 and hour > 0:
        hourText += "zero "
    hourText += hours[str(hour)][-1]
    returnTime.append(hourText)

    # add minutes text
    returnTime += minutes[str(min)][0]["text"]

    return returnTime

def display_time(hour, min, hours, minutes, special, config):
    returnTime = []

    if config.get("display", "random") == "random":
        # handle noon and midnight
        if hour % 12 == 0 and min == 0:
            specialKey = (":").join([str(hour), str(min)])
            specialIndex = random.number(0, len(special[specialKey]) - 1)
            for i in special[specialKey][specialIndex]:
                returnTime.append(i)
            return returnTime
        else:
            # handle all other times
            # get hour text options
            thisHourText = hours[str(hour)][0]
            nextHourIndex = 0 if hour == 23 else hour + 1
            nextHourText = hours[str(nextHourIndex)][0]

            # get a random entry of the minute (that isn't military time)
            minuteMinimum = 1 if min < 10 else 0
            minuteMaximum = len(minutes[str(min)]) - 1
            minuteIndex = random.number(minuteMinimum, minuteMaximum)
            minuteObj = minutes[str(min)][minuteIndex]

            # format the minuteObj according to its internal rules:
            # h is whether to use the subsequent hour word
            # o is whether the text comes before (1) or after (2) the hour word
            hourWord = thisHourText if minuteObj["h"] == 0 else nextHourText
            minuteWord = minuteObj["text"]
            if minuteObj["o"] == 1:
                if len(minuteWord) > 1:
                    minuteWord = [minuteWord[0], " ".join([minuteWord[1], hourWord])]
                    return minuteWord
                else:
                    return minuteWord + [hourWord] if minuteObj["text"] != "" else [hourWord]
            else:  # minuteObj["o"] == 2
                return [hourWord] + minuteWord if minuteObj["text"] != "" else [hourWord]

    else:
        # account for noon/midnight
        if hour % 12 == 0 and min == 0:
            specialKey = (":").join([str(hour), str(min)])
            timeText = special[specialKey][0]
            returnTime.append(timeText)

        else:
            # add hour text
            returnTime.append(hours[str(hour)][0])

            # add minutes text
            minIndex = 1 if min < 10 else 0  # avoid military times
            minutesTime = minutes[str(min)][minIndex]["text"]
            returnTime += minutesTime

        return returnTime

def game_of_thrones(hour, gameOfThrones, config):
    returnTime = []
    if len(gameOfThrones[str(hour)]) > 0:
        if config.get("dialect") == "en-US":
            returnTime = [gameOfThrones["stem"], gameOfThrones[str(hour)]]
    return returnTime

def time_of_day(hour, timeOfDay, config):
    returnTime = []

    if config.bool("military", False):  # don't show anything
        return returnTime
    elif config.get("display", False) == "basic":  # just show AM/PM
        # if dialect uses AM/PM
        if config.get("dialect") == "en-US":
            returnTime = ["am".upper()] if hour < 12 else ["pm".upper()]
        return returnTime
    else:  # pick random from list
        for timeRange in timeOfDay:
            if hour >= timeRange["hourMin"] and hour < timeRange["hourMax"]:
                rangeIndex = random.number(0, len(timeRange["text"]) - 1)
                returnTime += timeRange["text"][rangeIndex]
        return returnTime

def calculate_top_margin(showTime, subTime):
    fullHeight = 32
    bigH = 8
    littleH = 7

    topMargin = int(math.ceil((fullHeight - (bigH * len(showTime)) - (littleH * len(subTime))) / 2))

    return topMargin

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    # get the current time
    hour = now.hour
    min = now.minute

    # set the dialect globally
    dialect = config.get("dialect", "en-US")
    minutes = minutesObj[dialect]
    timeOfDay = timeOfDayObj[dialect]
    hours = hoursObj[dialect]
    gameOfThrones = gameOfThronesObj[dialect]
    special = specialObj[dialect]

    # apply the config rules
    showTime = []
    subTime = []
    if config.bool("military"):  # use Military Time
        showTime = military_time(hour, min, hours, minutes)
    else:  # basic vs. surprise me
        showTime = display_time(hour, min, hours, minutes, special, config)

    # add GoT description or add time of day
    if config.bool("game_of_thrones"):
        subTime = game_of_thrones(hour, gameOfThrones, config)
    if config.bool("time_of_day") and subTime == []:
        subTime = time_of_day(hour, timeOfDay, config)

    # apply lettercase styling
    if config.get("caps", "caps") == "caps":
        showTime = [i.upper() for i in showTime]
        subTime = [i.upper() for i in subTime]

    # render the words
    textTime = [render.Text(" " * i + s) for i, s in enumerate(showTime)]

    textTime += [render.Padding(
        pad = (0, 1, 0, 1),
        child = render.Text(" " * len(showTime) + " " * i + s, font = "CG-pixel-3x5-mono"),
    ) for i, s in enumerate(subTime)]

    # center the text vertically
    topMargin = calculate_top_margin(showTime, subTime)

    return render.Root(
        child = render.Padding(
            pad = (1, topMargin, 0, 1),
            child = render.Column(
                children = textTime,
            ),
        ),
    )

def get_schema():
    dialectOptions = [
        schema.Option(
            display = "American English",
            value = "en-US",
        ),
    ]

    displayOptions = [
        schema.Option(
            display = "Basic",
            value = "basic",
        ),
        schema.Option(
            display = "Random",
            value = "random",
        ),
    ]

    capsOptions = [
        schema.Option(
            display = "CAPS",
            value = "caps",
        ),
        schema.Option(
            display = "lowercase",
            value = "lower",
        ),
    ]

    # icons from: https://fontawesome.com/
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time",
            ),
            schema.Dropdown(
                id = "dialect",
                name = "Language",
                icon = "language",
                desc = "Language in which to display time",
                default = dialectOptions[0].value,
                options = dialectOptions,
            ),
            schema.Dropdown(
                id = "caps",
                name = "Text Case",
                icon = "font",
                desc = "CAPS vs. lowercase",
                default = capsOptions[0].value,
                options = capsOptions,
            ),
            schema.Dropdown(
                id = "display",
                name = "Display",
                icon = "shuffle",
                desc = "Basic times vs. surprise me",
                default = displayOptions[1].value,
                options = displayOptions,
            ),
            schema.Toggle(
                id = "time_of_day",
                name = "Time of Day",
                desc = "Indication of AM/PM",
                icon = "moon",
                default = False,
            ),
            schema.Toggle(
                id = "game_of_thrones",
                name = "Game of Thrones",
                desc = "Nighttime hour descriptions",
                icon = "chessRook",
                default = False,
            ),
            schema.Toggle(
                id = "military",
                name = "Military Time",
                desc = "24-hour times",
                icon = "jetFighter",
                default = False,
            ),
        ],
    )
