"""
Applet: Sidereal Time
Summary: A sidereal time clock
Description: A clock that shows the current sidereal time and (optionally) the local time.
Author: Daniel Sitnik
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_24H_FORMAT = False
DEFAULT_BLINK_TIME = True
DEFAULT_LOCAL_TIME = False
DEFAULT_LOCATION = """
{
    "lat": "40.6969512",
    "lng": "-73.9538453",
    "description": "Brooklyn, NY, USA",
    "locality": "Tidbyt",
    "place_id": "ChIJr3Hjqu5bwokRmeukysQhFCU",
    "timezone": "America/New_York"
}
"""
DEFAULT_TITLE_COLOR = "#2a9df4"
DEFAULT_SIDEREAL_TIME_COLOR = "#d0efff"
DEFAULT_LOCAL_TIME_COLOR = "#1167b1"

DEBUG = False

# FORMULAS AND CALCULATIONS PORTED FROM https://www.localsiderealtime.com/

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    # get config values
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    use_24h_format = config.bool("use_24h_format", DEFAULT_24H_FORMAT)
    blink_time = config.bool("blink_time", DEFAULT_BLINK_TIME)
    show_local_time = config.bool("local_time", DEFAULT_LOCAL_TIME)
    title_color = config.str("title_color", DEFAULT_TITLE_COLOR)
    sidereal_time_color = config.str("sidereal_time_color", DEFAULT_SIDEREAL_TIME_COLOR)
    local_time_color = config.str("local_time_color", DEFAULT_LOCAL_TIME_COLOR)

    # get current time in user's location
    now = time.now().in_location(location["timezone"])
    dprint("now=" + str(now.format("15:04")))

    # get user's longitude
    lng = float(location["lng"])
    dprint("lng=" + str(lng))

    # calculate the julian date
    now_jd = julian_date(now)

    # convert time to decimal
    now_decimal = decimal_hours(now)

    # calculate sidereal time
    sidereal_time = time_from_decimal(local_sidereal_time(greenwich_sidereal_time(now_jd, now_decimal), lng))
    dprint("sidereal_time={} ({})".format(sidereal_time.format("15:04"), sidereal_time.format("03:04PM")))

    # format results for display
    display_time = sidereal_time.format("03:04 PM")
    display_time2 = sidereal_time.format("03 04 PM")
    if use_24h_format:
        display_time = sidereal_time.format("15:04")
        display_time2 = sidereal_time.format("15 04")

    local_time = now.format("03:04 PM")
    local_time2 = now.format("03 04 PM")
    if use_24h_format:
        local_time = now.format("15:04")
        local_time2 = now.format("15 04")

    return render.Root(
        delay = 1000,
        child = render.Box(
            height = 32,
            width = 64,
            child = render.Column(
                expanded = False,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text("Sidereal Time", color = title_color),
                        ],
                    ),
                    render.Animation(
                        children = [
                            render.Text(display_time, color = sidereal_time_color, font = "6x13"),
                            render.Text(display_time2, color = sidereal_time_color, font = "6x13") if blink_time else None,
                        ],
                    ),
                    render.Box(height = 1) if show_local_time else None,
                    render.Animation(
                        children = [
                            render.Text(local_time, color = local_time_color, font = "CG-pixel-3x5-mono"),
                            render.Text(local_time2, color = local_time_color, font = "CG-pixel-3x5-mono") if blink_time else None,
                        ],
                    ) if show_local_time else None,
                ],
            ),
        ),
    )

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display sidereal time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "use_24h_format",
                name = "Use 24h format",
                desc = "Shows the time in 24h format.",
                icon = "clock",
                default = DEFAULT_24H_FORMAT,
            ),
            schema.Toggle(
                id = "local_time",
                name = "Show local time",
                desc = "Shows the local (regular) time.",
                icon = "clock",
                default = DEFAULT_LOCAL_TIME,
            ),
            schema.Toggle(
                id = "blink_time",
                name = "Blinking separator",
                desc = "Shows a blinking time separator.",
                icon = "asterisk",
                default = DEFAULT_BLINK_TIME,
            ),
            schema.Color(
                id = "title_color",
                name = "Title color",
                desc = "Color of the app title.",
                icon = "brush",
                default = DEFAULT_TITLE_COLOR,
            ),
            schema.Color(
                id = "sidereal_time_color",
                name = "Sideral Time color",
                desc = "Color of the sidereal time.",
                icon = "brush",
                default = DEFAULT_SIDEREAL_TIME_COLOR,
            ),
            schema.Color(
                id = "local_time_color",
                name = "Local Time color",
                desc = "Color of the local time.",
                icon = "brush",
                default = DEFAULT_LOCAL_TIME_COLOR,
            ),
        ],
    )

def julian_date(datetime):
    """Calculates the Julian date.

    Args:
        datetime (Time): Time object with the desired date/time.

    Returns:
        float: The calculated julian date.
    """

    # convert to utc
    utc = datetime.in_location("UTC")

    # get components
    year = utc.year
    month = utc.month
    day = utc.day

    # if january or february
    if month <= 2:
        year = year - 1
        month = month + 12

    # calculate
    A = math.floor(year / 100)
    B = 2 - A + math.floor(A / 4)
    C = math.floor(365.25 * year)
    D = math.floor(30.6001 * (month + 1))

    julian_date = (B + C + D + day + 1720994.5)
    dprint("julian_date={}".format(julian_date))

    return julian_date

def decimal_hours(datetime):
    """Converts a time into a decimal representation.

    Args:
        datetime (Time): Time object with the desired time.

    Returns:
        float: The converted time.
    """

    # convert to utc
    utc = datetime.in_location("UTC")

    decimal_hours = (((utc.second / 60) + utc.minute) / 60) + utc.hour
    dprint("utc_decimal_hours={}".format(decimal_hours))

    return decimal_hours

def greenwich_sidereal_time(julian_date, decimal_hours):
    """Calculates the greenwich sidereal time.

    Args:
        julian_date (float): The current julian date.
        decimal_hours (float): The current UTC hour in decimal format.

    Returns:
        float: The calculated greenwich sidereal time.
    """
    S = julian_date - 2451545
    T = S / 36525

    T0 = 6.697374558 + (2400.051336 * T) + (0.000025862 * math.pow(T, 2))

    if T0 < 0:
        T0 = (T0 + (24 * abs(math.floor(T0 / 24))))
    else:
        T0 = (T0 - (24 * abs(math.floor(T0 / 24))))

    T0 = T0 + (decimal_hours * 1.002737909)

    if T0 < 0:
        T0 = T0 + 24

    if T0 > 24:
        T0 = T0 - 24

    return T0

def local_sidereal_time(gstime, longitude):
    """Calculates the local sidereal time.

    Args:
        gstime (float): The greenwich sidereal time.
        longitude (float): The user's longitude.

    Returns:
        float: The calculated sidereal time.
    """
    lstime = None
    utc_diff = abs(longitude / 15)

    if longitude < 0:
        lstime = gstime - utc_diff
    else:
        lstime = gstime + utc_diff

    if lstime > 24:
        lstime = lstime - 24

    if lstime < 0:
        lstime = lstime + 24

    dprint("sideral_time_decimal={}".format(lstime))

    return lstime

def time_from_decimal(decimal):
    """Converts a decimal number into the hours/minutes of a Time object.

    Args:
        decimal (float): The decimal number to converted.

    Returns:
        time: The time object representing the hours/minutes.
    """
    hour = int(decimal)
    minute = int(60 * (decimal - hour))

    return time.time(hour = hour, minute = minute)

def dprint(message):
    """Prints a message when in debug mode.

    Args:
        message (str): The message to print.
    """

    if DEBUG:
        print(message)
