"""
Applet: Calendars
Summary: Today's date but different
Description: Shows the current date converted into various other regular calendars.
Author: dinosaursrarr
"""

# Parameters and algorithms are taken from Chapter 25 "The Conversion of
# Regular Calendars" from E. G. Richards' "Mapping Time: the calendar and
# its history", reprinted with corrections, 2000 by Oxford University Press.
# I have also checked the latest available version of the author's
# errata web page:
# https://web.archive.org/web/20090301230324/http://www.users.zetnet.co.uk/egrichards/book.htm

# To do:
# Add month names from earlier in the text (ch 18 - 21)
# Jewish calendar (ch 26)
# Mayan calendar (ch 27)
# Roman day name (end of ch 25)

load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = {
    "lat": 51.5072,
    "lng": -0.1276,
    "locality": "London",
}
DEFAULT_TIMEZONE = "Europe/London"

Y = "y"  # Computational year in which J_1 falls
J = "j"  # Number of days that J_c falls before day zero, that is j = -J_c
M = "m"  # Month number in a given calendar for which M' = 0
N = "n"  # Number of months in a year
R = "r"  # Number of years in a cycle of intercalation
P = "p"  # Number of days in a cycle of interacalation
Q = "q"  # Parameter required in calculating years
V = "v"  # Parameter required in calculating years
U = "u"  # Parameter required in calculating months
S = "s"  # Parameter required in calculating months
T = "t"  # Parameter required in calculating months
W = "w"  # Parameter required in calculating months
A = "A"  # Parameter used to handle Gregorian intercalation
B = "B"  # Parameter used to handle Gregorian intercalation
G = "G"  # Parameter used to handle Gregorian intercalation
IS_GREGORIAN = "is_gregorian"
IS_SAKA = "is_saka"

CHOOSE_RANDOM = "---"
CALENDARS = {
    "Egyptian": {
        Y: 3968,
        J: 47,
        M: 1,
        N: 13,
        R: 1,
        P: 365,
        Q: 0,
        V: 0,
        U: 1,
        S: 30,
        T: 0,
        W: 0,
    },
    "Armenian": {
        Y: 5268,
        J: 317,
        M: 1,
        N: 13,
        R: 1,
        P: 365,
        Q: 0,
        V: 0,
        U: 1,
        S: 30,
        T: 0,
        W: 0,
    },
    "Khwarizmian": {
        Y: 5348,
        J: 317,
        M: 1,
        N: 13,
        R: 1,
        P: 365,
        Q: 0,
        V: 0,
        U: 1,
        S: 30,
        T: 0,
        W: 0,
    },
    "Persian": {
        Y: 5348,
        J: 77,
        M: 10,
        N: 13,
        R: 1,
        P: 365,
        Q: 0,
        V: 0,
        U: 1,
        S: 30,
        T: 0,
        W: 0,
    },
    "Ethiopian": {
        Y: 4720,
        J: 124,
        M: 1,
        N: 13,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 1,
        S: 30,
        T: 0,
        W: 0,
    },
    "Coptic": {
        Y: 4996,
        J: 124,
        M: 1,
        N: 13,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 1,
        S: 30,
        T: 0,
        W: 0,
    },
    "French Republican": {
        Y: 6504,
        J: 111,
        M: 1,
        N: 13,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 1,
        S: 30,
        T: 0,
        W: 0,
        A: 396,
        B: 578797,
        G: -51,
        IS_GREGORIAN: True,
    },
    "Macedonian": {
        Y: 4405,
        J: 1401,
        M: 7,
        N: 12,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 5,
        S: 153,
        T: 2,
        W: 2,
    },
    "Syrian": {
        Y: 4405,
        J: 1401,
        M: 6,
        N: 12,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 5,
        S: 153,
        T: 2,
        W: 2,
    },
    "Julian Roman": {
        Y: 4716,
        J: 1401,
        M: 3,
        N: 12,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 5,
        S: 153,
        T: 2,
        W: 2,
    },
    "Gregorian": {
        Y: 4716,
        J: 1401,
        M: 3,
        N: 12,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 5,
        S: 153,
        T: 2,
        W: 2,
        A: 184,
        B: 274277,
        G: -38,
        IS_GREGORIAN: True,
    },
    "Islamic A": {
        Y: 5519,
        J: 7665,
        M: 1,
        N: 12,
        R: 30,
        P: 10631,
        Q: 14,
        V: 15,
        U: 100,
        S: 2951,
        T: 51,
        W: 10,
    },
    "Islamic B": {
        Y: 5519,
        J: 7664,  # Epoch is one day earlier than
        M: 1,
        N: 12,
        R: 30,
        P: 10631,
        Q: 14,
        V: 15,
        U: 100,
        S: 2951,
        T: 51,
        W: 10,
    },
    "Bahá'í": {
        Y: 6560,
        J: 1412,
        M: 20,
        N: 20,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 1,
        S: 19,
        T: 0,
        W: 0,
        A: 184,
        B: 274273,
        G: -50,
        IS_GREGORIAN: True,
    },
    "Saka": {
        Y: 4794,
        J: 1348,
        M: 2,
        N: 12,
        R: 4,
        P: 1461,
        Q: 0,
        V: 3,
        U: 1,
        S: 31,
        T: 0,
        W: 0,
        A: 184,
        B: 274073,
        G: -36,
        IS_GREGORIAN: True,
        IS_SAKA: True,
    },
}

DAY_MONTH_YEAR = "dmy"
MONTH_DAY_YEAR = "mdy"
YEAR_MONTH_DAY = "ymd"

def to_julian_day(day, month, year, calendar):
    """Algorithm E, page 323"""
    year_ = year + calendar[Y] - (calendar[N] + calendar[M] - 1 - month) // calendar[N]
    month_ = (month - calendar[M] + calendar[N]) % calendar[N]
    day_ = day - 1
    c = (calendar[P] * year_ + calendar[Q]) // calendar[R]
    s = calendar[S]
    t = calendar[T]
    if calendar.get(IS_SAKA):
        z = month_ // 6
        s = 31 - z
        t = 5 * z
    d = (s * month_ + t) // calendar[U]
    g = 0
    if calendar.get(IS_GREGORIAN):
        g = 3 * ((year_ + calendar[A]) // 100) // 4 + calendar[G]
    return c + d + day_ - calendar[J] - g

def to_calendar_date(julian_day, calendar):
    """Algorithm F, page 324"""
    g = 0
    if calendar.get(IS_GREGORIAN):
        g = (3 * ((4 * julian_day + calendar[B]) // 146097)) // 4 + calendar[G]
    j_ = julian_day + calendar[J] + g
    year_ = (calendar[R] * j_ + calendar[V]) // calendar[P]

    t_ = ((calendar[R] * j_ + calendar[V]) % calendar[P]) // calendar[R]
    s = calendar[S]
    w = calendar[W]
    if calendar.get(IS_SAKA):
        x = t_ // 365
        z = t_ // 185 - x
        s = 31 - z
        w = -5 * z
        day_ = (6 * x + ((calendar[U] * t_ + w) % s)) // calendar[U]
    else:
        day_ = ((calendar[U] * t_ + w) % s) // calendar[U]
    month_ = (calendar[U] * t_ + w) // s
    day = day_ + 1
    month = ((month_ + calendar[M] - 1) % calendar[N]) + 1
    year = year_ - calendar[Y] + ((calendar[N] + calendar[M] - 1 - month) // calendar[N])
    return day, month, year

def format_date(day, month, year, date_format):
    if date_format == DAY_MONTH_YEAR:
        return "{} / {} / {}".format(day, month, year)
    if date_format == MONTH_DAY_YEAR:
        return "{} / {} / {}".format(month, day, year)
    if date_format == YEAR_MONTH_DAY:
        return "{}-{}-{}".format(year, month, day)
    return "Unknown date format: {}".format(date_format)

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))  # Utilize special timezone variable
    now = time.now().in_location(timezone)

    calendar = config.get("calendar", CHOOSE_RANDOM)
    if calendar == CHOOSE_RANDOM:
        index = random.number(0, len(CALENDARS) - 1)
        calendar = CALENDARS.keys()[index]

    julian = to_julian_day(now.day, now.month, now.year, CALENDARS["Gregorian"])
    day, month, year = to_calendar_date(julian, CALENDARS[calendar])

    date_format = config.get("date_format", DAY_MONTH_YEAR)

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    color = "#1134A6",  # Egyptian blue
                    child = render.Padding(
                        pad = (0, 1, 0, 0),
                        child = render.WrappedText(
                            "Today's date",
                            font = "tom-thumb",
                            width = 64,
                            align = "center",
                        ),
                    ),
                ),
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = [
                        render.WrappedText(
                            format_date(day, month, year, date_format),
                            width = 62,
                            align = "center",
                        ),
                        render.WrappedText(
                            calendar,
                            width = 62,
                            align = "center",
                            font = "tom-thumb",
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location defining the timezone.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "calendar",
                name = "Calendar",
                desc = "The calendar to show today's date in.",
                icon = "calendar",
                default = CHOOSE_RANDOM,
                options = [
                    schema.Option(
                        display = "Random",
                        value = CHOOSE_RANDOM,
                    ),
                ] + [
                    schema.Option(
                        display = calendar,
                        value = calendar,
                    )
                    for calendar in CALENDARS
                ],
            ),
            schema.Dropdown(
                id = "date_format",
                name = "Date format",
                desc = "Order to show date components.",
                icon = "calendarXmark",
                default = DAY_MONTH_YEAR,
                options = [
                    schema.Option(
                        display = "day / month / year",
                        value = DAY_MONTH_YEAR,
                    ),
                    schema.Option(
                        display = "month / day / year",
                        value = MONTH_DAY_YEAR,
                    ),
                    schema.Option(
                        display = "year-month-day",
                        value = YEAR_MONTH_DAY,
                    ),
                ],
            ),
        ],
    )
