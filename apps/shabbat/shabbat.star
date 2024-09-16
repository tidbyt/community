"""
Applet: Shabbat
Summary: Start and end of Shabbat
Description: Shows weekly shabbat start and end times.
Author: dinosaursrarr.  Updated by NudnikShpilkis
"""

load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

DEFAULT_LOCATION = """
{
    "lat": 40.704620,
    "lng": -74.010930,
    "locality": "New York, New York, USA",
    "timezone": "EST"
}
"""

DEFAULT_WEEKEND_ONLY = False
DEFAULT_USE_24_HOUR_CLOCK = True
DEFAULT_SHOW_PROGRESS_BAR = True
DEFAULT_METHOD = "halakhic_min"
DEFAULT_HALAKHIC_MINUTES = "34"
DEFAULT_DEGREES_BELOW_HORIZON = "-5.95"
FRIDAY = 5
SATURDAY = 6

def round_down(t):
    return time.time(year = t.year, month = t.month, day = t.day, hour = t.hour, minute = t.minute)

def round_up(t):
    return time.time(year = t.year, month = t.month, day = t.day, hour = t.hour, minute = t.minute + 1)

def calc_start_time(today, lat, lng):
    """Calculate shabbat start time.

    Args:
        today (time): Today's date.
        lat (float): latitiude.
        lng (float): longitude.

    Returns:
        time: Shabbat start time.
    """
    weekday = humanize.day_of_week(today)

    # Get date of upcoming Friday
    friday = today + (time.hour * 24 * (FRIDAY - weekday))

    # Friday sunset
    sunset = sunrise.sunset(lat, lng, friday)
    if sunset == None:
        return display_error()

    # Subtract 18 minutes
    start_time = sunset - (18 * time.minute)
    return start_time

def calc_relative_min(day, lat, lng, halakhic_min):
    """Calculate relative minutes for sunset.

    Args:
        day (time): Today's date.
        lat (float): latitiude.
        lng (float): longitude.
        halakhic_min (int): Halakhic Minutes to use.

    Returns:
        duration: Minutes to add to sunset.
    """

    # Saturday day length
    sat_sunrise = sunrise.sunrise(lat, lng, day)
    sat_sunset = sunrise.sunset(lat, lng, day)
    day_length = (sat_sunset - sat_sunrise).minutes

    # Relative minutes
    relative_min = (day_length / 720.0) * halakhic_min
    relative_min = time.parse_duration(str(relative_min) + "m")
    return relative_min

def calc_end_time(today, lat, lng, method, degrees_below_horizon, halakhic_min):
    """Calculate shabbat end time.

    Args:
        today (time): Today's date.
        lat (float): latitiude.
        lng (float): longitude.
        method (str): End method.
        degrees_below_horizon (float): Degrees below horizon to use.
        halakhic_min (int): Halakhic Minutes to use.

    Returns:
        time: Shabbat end time.
    """

    # Upcoming Saturday
    weekday = humanize.day_of_week(today)
    saturday = today + (time.hour * 24 * (SATURDAY - weekday))
    sat_sunset = sunrise.sunset(lat, lng, saturday)

    if method == "degrees_below_horizon":
        _, end_time = sunrise.elevation_time(lat, lng, degrees_below_horizon, saturday)
    elif method == "halakhic_min":
        relative_min = calc_relative_min(
            lat = lat,
            lng = lng,
            day = saturday,
            halakhic_min = halakhic_min,
        )

        # Add relative minutes to saturday sunset
        end_time = (sat_sunset + relative_min)
    elif method == "rabbeinu_tam":
        end_time = sat_sunset + (72 * time.minute)
    elif method == "fifty_minutes":
        end_time = sat_sunset + (50 * time.minute)
    else:
        end_time = None

    return end_time

def make_message(start, end, use_24_hour_clock):
    """Make message to display.

    Args:
        start (time): Shabbat start time.
        end (time): Shabbat end time.
        use_24_hour_clock (bool): Whether to use 24 hour clock.

    Returns:
        str: message.
    """
    time_format = "3:04 PM"
    if use_24_hour_clock:
        time_format = "15:04"

    message = "shabbat \n"
    message += "start: " + round_down(start).format(time_format) + "\n"
    message += "end: " + round_up(end).format(time_format)
    return render.WrappedText(
        content = message,
        align = "center",
        width = 64,
    )

def display_error():
    """Display Error Message

    Returns:
        render: Error Message
    """
    return render.Root(
        child = render.Padding(
            pad = (0, 4, 0, 4),
            child = render.WrappedText(
                content = "Can't Display Shabbat Times",
                font = "tb-8",
                align = "center",
                height = 64,
                width = 64,
            ),
        ),
    )

def make_progress_bar(now, shabbat_start, shabbat_end):
    """Show progress bar on shabbat.

    Args:
        now (time): Current time.
        shabbat_start (time): Shabbat start time.
        shabbat_end (time): Shabbat end time.

    Returns:
        render: Progress bar.
    """
    shabbat_len = (shabbat_end - shabbat_start).minutes
    shabbat_rem = (shabbat_end - now).minutes

    fill_width = math.floor(64 - ((shabbat_rem / shabbat_len) * 64))

    progress_bar = render.Stack(
        children = [
            render.Box(width = 64, height = 1, color = "#F000F0"),
            render.Box(width = fill_width, height = 1, color = "#4D8FAC"),
        ],
    )
    return progress_bar

def main(config):
    # Get longditude and latitude from location
    loc = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    tz = loc["timezone"]

    # Get todays date
    now = time.now().in_location(tz)
    today = time.time(
        year = now.year,
        month = now.month,
        day = now.day,
    )
    weekday = humanize.day_of_week(today)

    # Check if weekend only
    if config.bool("weekend_only", DEFAULT_WEEKEND_ONLY) and weekday != FRIDAY and weekday != SATURDAY:
        return []

    # Set 24 or 12 hour clock
    use_24_hour_clock = config.bool("use_24h", DEFAULT_USE_24_HOUR_CLOCK)

    # Set end method
    method = config.get("end_method", DEFAULT_METHOD)
    if method == "degrees_below_horizon":
        degrees_below_horizon = float(config.get("degrees_below_horizon", DEFAULT_DEGREES_BELOW_HORIZON))
        halakhic_min = None
    elif method == "EIGHT_AND_A_HALF_DEGREES_BELOW_HORIZON":
        degrees_below_horizon = -8.5
        halakhic_min = None
    elif method == "halakhic_min":
        degrees_below_horizon = None
        halakhic_min = int(config.get("halakhic_min", DEFAULT_HALAKHIC_MINUTES))
    elif method == "RABBEINU_TAM":
        # Catch old rabbeinu tam method
        method = "rabbeinu_tam"
        degrees_below_horizon = None
        halakhic_min = None
    elif method == "FIFTY_MINUTES_AFTER_SUNSET":
        # Catch old fifty minutes
        method = "fifty_minutes"
        degrees_below_horizon = None
        halakhic_min = None
    else:
        degrees_below_horizon = None
        halakhic_min = None

    # Get shabbat start
    shabbat_start = calc_start_time(
        today = today,
        lat = lat,
        lng = lng,
    )
    shabbat_start = shabbat_start.in_location(tz)

    # Get shabbat end
    shabbat_end = calc_end_time(
        today = today,
        lat = lat,
        lng = lng,
        method = method,
        degrees_below_horizon = degrees_below_horizon,
        halakhic_min = halakhic_min,
    )
    if shabbat_end == None:
        return display_error()
    shabbat_end = shabbat_end.in_location(tz)

    # Turn times to message
    message = make_message(
        start = shabbat_start,
        end = shabbat_end,
        use_24_hour_clock = use_24_hour_clock,
    )

    # Add progress bar
    show_progress_bar = config.bool("show_progress_bar", DEFAULT_SHOW_PROGRESS_BAR)
    if show_progress_bar and ((weekday == FRIDAY) and (now >= shabbat_start)) or ((weekday == SATURDAY) and (now < shabbat_end)):
        progress_bar = make_progress_bar(
            now = now,
            shabbat_start = shabbat_start,
            shabbat_end = shabbat_end,
        )

        return render.Root(
            render.Column(
                children = [
                    message,
                    progress_bar,
                ],
            ),
        )
    else:
        return render.Root(
            message,
        )

def get_schema():
    end_method_options = [
        schema.Option(
            display = "Degress below horizon",
            value = "degrees_below_horizon",
        ),
        schema.Option(
            display = "Halakhic Minutes",
            value = "halakhic_min",
        ),
        schema.Option(
            display = "Rabbeinu Tam",
            value = "rabbeinu_tam",
        ),
        schema.Option(
            display = "50 minutes after sunset",
            value = "fifty_minutes",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the times of shabbat",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "weekend_only",
                name = "Weekend only?",
                desc = "Enable to only display on Fridays and Saturdays",
                icon = "calendar",
                default = DEFAULT_WEEKEND_ONLY,
            ),
            schema.Toggle(
                id = "use_24h",
                name = "Use 24 hour clock?",
                desc = "Enable to display times using the 24 hour clock",
                icon = "clock",
                default = DEFAULT_USE_24_HOUR_CLOCK,
            ),
            schema.Toggle(
                id = "show_progress_bar",
                name = "Show progress bar?",
                desc = "Enable to display progress bar on shabbat",
                icon = "eye",
                default = DEFAULT_SHOW_PROGRESS_BAR,
            ),
            schema.Dropdown(
                id = "end_method",
                name = "Method",
                desc = "Method to calculate the end of shabbat",
                icon = "moon",
                default = end_method_options[1].value,
                options = end_method_options,
            ),
            schema.Text(
                id = "degrees_below_horizon",
                name = "Degrees below horizon",
                desc = "Degrees below horizon (If Method is degrees below horizon)",
                icon = "terminal",
                default = DEFAULT_DEGREES_BELOW_HORIZON,
            ),
            schema.Text(
                id = "halakhic_min",
                name = "Halakhic Minutes",
                desc = "Number of Halakhic Minutes (If Method is halakhic minutes)",
                icon = "terminal",
                default = DEFAULT_HALAKHIC_MINUTES,
            ),
        ],
    )
