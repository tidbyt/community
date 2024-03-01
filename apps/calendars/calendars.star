"""
Applet: Calendars
Summary: Today's date but different
Description: Shows the current date converted into various other regular calendars.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = {
    "lat": 51.5072,
    "lng": -0.1276,
    "locality": "London",
}
DEFAULT_TIMEZONE = "Europe/London"

Y = "y"
J = "j"
M = "m"
N = "n"
R = "r"
P = "p"
Q = "q"
V = "v"
U = "u"
S = "s"
T = "t"
W = "w"
A = "A"
B = "B"
G = "G"
IS_GREGORIAN = "is_gregorian"
IS_SAKA = "is_saka"

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
}

def to_julian_day(day, month, year, calendar):
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
    if calendar.get(IS_GREGORIAN):
        g = 3 * ((year_ + calendar[A]) // 100) // 4 + calendar[G]
        return c + d + day_ - calendar[J] - g
    return c + d + day_ - calendar[J]

def to_calendar_date(julian_day, calendar):
    g = 0
    if calendar.get(IS_GREGORIAN):
        g = 3 * ((4 * julian_day + calendar[B]) // 146097) // 4 + calendar[G]
    j_ = julian_day + calendar[J] + g
    year_ = (calendar[R] * j_ + calendar[V]) // calendar[P]
    t_ = ((calendar[R] * j_ + calendar[V]) % calendar[P]) // calendar[R]
    s = calendar[S]
    w = calendar[W]
    day_ = ((calendar[U] * t_ + w) % s) // calendar[U]
    if calendar.get(IS_SAKA):
        x = t_ // 365
        z = t_ // 185 - x
        s = 31 - z
        w = -5 * z
        day_ = (6 * x + ((calendar[U] * t_ + w) % s)) // calendar[U]
    month_ = (calendar[U] * t_ + w) // s
    day = day_ + 1
    month = ((month_ + calendar[M] - 1) % calendar[N]) + 1
    year = year_ - calendar[Y] + ((calendar[N] + calendar[M] - 1 - month) // calendar[N])
    return day, month, year

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))  # Utilize special timezone variable
    now = time.now().in_location(timezone)

    julian = to_julian_day(now.day, now.month, now.year, CALENDARS["Gregorian"])
    day, month, year = to_calendar_date(julian, CALENDARS["Egyptian"])

    return render.Root(
        child = render.Text("{} / {} / {}".format(day, month, year)),
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
        ],
    )
