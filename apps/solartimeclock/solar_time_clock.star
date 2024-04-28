"""
Applet: Solar Time Clock
Summary: A solar time clock
Description: A clock that shows the current solar time and (optionally) the local time.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
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

SUN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAAAXNSR0IArs4c6QAAAH5JREFUKFNjZMABPlzO+S+gO4URmzRWQZAGTk5lhu/f7zJg0wjXhM9kkG3I8hg2gSTRnYRuG4ommLOQNbEpFzB8vJKL4kywJpjV2DSB5GF+g6ljhClkVymEs9GdB9P0807/fxCbPJuQTSXkPJhaykKPoniChSZRKQI9xPDZDAANlGs8ZqpPTQAAAABJRU5ErkJggg==
""")

DEBUG = False

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    # Based on the code at https://koch-tcm.ch/en/uhrzeit-sonnenzeit-rechner/
    # The JavaScript on the page was converted to Starlark code.

    location = json.decode(config.get("location", DEFAULT_LOCATION))
    use_24h_format = config.bool("use_24h_format", DEFAULT_24H_FORMAT)
    blink_time = config.bool("blink_time", DEFAULT_BLINK_TIME)
    show_local_time = config.bool("local_time", DEFAULT_LOCAL_TIME)

    now = time.now().in_location(location["timezone"])
    if DEBUG:
        print("now=" + str(now.format("15:04")))

    lng = float(location["lng"])
    if DEBUG:
        print("lng=" + str(lng))

    tz = int(now.format("-07"))
    if DEBUG:
        print("tz=" + str(tz))

    day_of_year = get_day_of_year(now)
    if DEBUG:
        print("day_of_year=" + str(day_of_year))

    local_time_dec = now.hour + now.minute / 60
    if DEBUG:
        print("local_time_dec=" + str(local_time_dec))

    equation_of_time = calculate_equation_of_time(day_of_year)
    if DEBUG:
        print("equation_of_time=" + str(equation_of_time))

    lng_correction = calculate_lng_correction(tz, lng)
    if DEBUG:
        print("lng_correction=" + str(lng_correction))

    solar_time_dec = calculate_solar_time(local_time_dec, equation_of_time, lng_correction)
    if DEBUG:
        print("solar_time_dec=" + str(solar_time_dec) + " (before catch_day_change)")

    solar_time_dec = catch_day_change(solar_time_dec)
    if DEBUG:
        print("solar_time_dec=" + str(solar_time_dec) + " (after catch_day_change)")

    solar_time = time_from_decimal(solar_time_dec)
    if DEBUG:
        print("solar_time={} ({})".format(solar_time.format("15:04"), solar_time.format("03:04PM")))

    display_time = solar_time.format("03:04 PM")
    display_time2 = solar_time.format("03 04 PM")
    if use_24h_format:
        display_time = solar_time.format("15:04")
        display_time2 = solar_time.format("15 04")

    local_time = now.format("03:04 PM")
    local_time2 = now.format("03 04 PM")
    if use_24h_format:
        local_time = now.format("15:04")
        local_time2 = now.format("15 04")

    return render.Root(
        delay = 500,
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
                            render.Image(src = SUN_ICON, width = 13, height = 13),
                            render.Text("Solar Time", color = "#f4e06b"),
                        ],
                    ),
                    render.Animation(
                        children = [
                            render.Text(display_time, color = "#e7a854", font = "6x13"),
                            render.Text(display_time2, color = "#e7a854", font = "6x13") if blink_time else None,
                        ],
                    ),
                    render.Box(height = 1) if show_local_time else None,
                    render.Animation(
                        children = [
                            render.Text(local_time, color = "#f4e06b", font = "CG-pixel-3x5-mono"),
                            render.Text(local_time2, color = "#f4e06b", font = "CG-pixel-3x5-mono") if blink_time else None,
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
                desc = "Location for which to display solar time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "use_24h_format",
                name = "Use 24h format",
                desc = "Show time in 24h format.",
                icon = "clock",
                default = DEFAULT_24H_FORMAT,
            ),
            schema.Toggle(
                id = "local_time",
                name = "Local time",
                desc = "Show local time.",
                icon = "clock",
                default = DEFAULT_LOCAL_TIME,
            ),
            schema.Toggle(
                id = "blink_time",
                name = "Blink time",
                desc = "Blinking time separator.",
                icon = "asterisk",
                default = DEFAULT_BLINK_TIME,
            ),
        ],
    )

def get_day_of_year(now):
    """Calculates the number of days elapsed in the current year.

    Args:
        now (time): Current time.

    Returns:
        int: Days elapsed in the current year.
    """
    year_start = time.time(
        year = now.year,
        month = 1,
        day = 1,
    )

    diff = now - year_start

    return math.ceil(diff.seconds / (60 * 60 * 24))

def calculate_equation_of_time(day_of_year):
    """Calculates the equation of time for a day of the year.

    Args:
        day_of_year (int): The day of the year.

    Returns:
        float: The equation of time for the given day.
    """
    x = math.radians((360 * (day_of_year - 1)) / 365.242)
    return 0.258 * math.cos(x) - 7.416 * math.sin(x) - 3.648 * math.cos(2 * x) - 9.228 * math.sin(2 * x)

def calculate_lng_correction(tz, lng):
    """Calculates a longitude correction.

    Args:
        tz (int): The time zone (eg: -3)
        lng (float): The longitude.

    Returns:
        float: The longitude correction.
    """
    return (15 * tz - lng) / 15

def calculate_solar_time(local_time_dec, equation_of_time, lng_correction):
    """Calculates the solar time.

    Args:
        local_time_dec (float): Local time represented as a decimal number.
        equation_of_time (float): Equation of time calculated in a previous step.
        lng_correction (float): Longitude correction calculated in a previous step.

    Returns:
        float: The calculated solar time.
    """
    return local_time_dec + (equation_of_time / 60) - lng_correction

def catch_day_change(solar_time):
    """Corrects a solar time when it overflows to the next day.

    Args:
        solar_time (float): The solar time to correct.

    Returns:
        float: The corrected solar time.
    """
    if solar_time < 0:
        return solar_time + 24

    if solar_time >= 24:
        return solar_time - 24

    return solar_time

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
