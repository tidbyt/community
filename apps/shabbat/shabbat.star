"""
Applet: Shabbat
Summary: Start and end of Shabbat
Description: Shows the start and end times of the current or upcoming Shabbat observance.
Author: dinosaursrarr
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
    "lat": 51.5682,
    "lng": -0.0742,
    "locality": "Stamford Hill, London, UK",
    "timezone": "Europe/London"
}
"""

DEFAULT_WEEKEND_ONLY = False
DEFAULT_USE_24_HOUR_CLOCK = True

EIGHT_AND_A_HALF_DEGREES_BELOW_HORIZON = "ASTRONOMICAL"
FIFTY_MINUTES_AFTER_SUNSET = "50_MINUTES_AFTER_SUNSET"
RABBEINU_TAM = "RABBEINU_TAM"

# Consistent with output of day_of_week
FRIDAY = 5
SATURDAY = 6

# Zeller's Congruence
# https://www.rfc-editor.org/rfc/rfc3339#page-14
# 0 is Sunday, 6 is Saturday
def day_of_week(year, month, day):
    month = month - 2
    if month < 1:
        month = month + 12
        year = year - 1

    century = math.floor(year / 100)
    year = math.mod(year, 100)

    return int(math.mod(math.floor((13 * month + 1) / 5) + day + year + math.floor(year / 4) + math.floor(century / 4) + 5 * century, 7))

def end_time(method, latitude, longitude, end_day, timezone):
    if method == EIGHT_AND_A_HALF_DEGREES_BELOW_HORIZON:
        morning, evening = sunrise.elevation_time(latitude, longitude, -8.5, end_day)
        return evening
    if method == FIFTY_MINUTES_AFTER_SUNSET:
        return sunrise.sunset(latitude, longitude, end_day) + (50 * time.minute)
    if method == RABBEINU_TAM:
        return sunrise.sunset(latitude, longitude, end_day) + (72 * time.minute)

def round_down(t):
    return time.time(year = t.year, month = t.month, day = t.day, hour = t.hour, minute = t.minute)

def round_up(t):
    return time.time(year = t.year, month = t.month, day = t.day, hour = t.hour, minute = t.minute + 1)

def make_message(now, start, end, use_24_hour_clock):
    time_format = "3:04 PM"
    if use_24_hour_clock:
        time_format = "15:04"

    if now < start:
        message = "Shabbat starts " + round_down(start).format(time_format)
        start_days = int(math.fabs(math.mod(start.day - now.day, 7)))
        if start_days == 1:
            message = message + " tomorrow"
        elif start_days > 1:
            message = message + " in " + humanize.plural(start_days, "day", "days")
        return message

    if now < end:
        message = "Shabbat ends at " + round_up(end).format(time_format)
        end_days = int(math.fabs(math.mod(end.day - now.day, 7)))
        if end_days > 0:
            message = message + " tomorrow"
        return message

    return "Shabbat ended at " + end.format(time_format)

def display_message(message):
    return render.Root(
        child = render.Padding(
            pad = (0, 4, 0, 4),
            child = render.WrappedText(
                content = message,
                align = "center",
                height = 32,
                width = 64,
            ),
        ),
    )

def main(config):
    # Get longditude and latitude from location
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    latitude = float(location["lat"])
    longitude = float(location["lng"])

    now = time.now().in_location(location["timezone"])
    today = time.time(year = now.year, month = now.month, day = now.day)
    weekday = day_of_week(now.year, now.month, now.day)

    if config.bool("weekend_only", DEFAULT_WEEKEND_ONLY) and weekday != FRIDAY and weekday != SATURDAY:
        return []

    # The start of Shabbat is 18 minutes before sunset on Friday
    start_day = today + (time.hour * 24 * (FRIDAY - weekday))
    sunset = sunrise.sunset(latitude, longitude, start_day)
    if sunset == None:
        return display_message("Cannot calculate Shabbat times")
    start = sunset.in_location(location["timezone"]) - (18 * time.minute)

    # The end of Shabbat is some time after sunset on Saturday. There is disagreement about how long after.
    end_day = start_day + (24 * time.hour)
    end_method = config.get("end_method", EIGHT_AND_A_HALF_DEGREES_BELOW_HORIZON)
    end = end_time(end_method, latitude, longitude, end_day, location["timezone"])
    if end == None:
        return display_message("Cannot calculate Shabbat times")
    end = end.in_location(location["timezone"])

    use_24_hour_clock = config.bool("use_24h", DEFAULT_USE_24_HOUR_CLOCK)
    message = make_message(now, start, end, use_24_hour_clock)

    return display_message(message)

def get_schema():
    # There are different methods for deciding when it's sufficiently nightfall
    end_method_options = [
        schema.Option(
            display = "8.5 degrees below horizon",
            value = EIGHT_AND_A_HALF_DEGREES_BELOW_HORIZON,
        ),
        schema.Option(
            display = "50 minutes after sunset",
            value = FIFTY_MINUTES_AFTER_SUNSET,
        ),
        schema.Option(
            display = "Rabbeinu Tam",
            value = RABBEINU_TAM,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the times of Shabbat",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "weekend_only",
                name = "Weekend only?",
                desc = "Enable to only display on Fridays and Saturdays.",
                icon = "gear",
                default = DEFAULT_WEEKEND_ONLY,
            ),
            schema.Toggle(
                id = "use_24h",
                name = "Use 24 hour clock",
                desc = "Enable to display times using the 24 hour clock",
                icon = "clock",
                default = DEFAULT_USE_24_HOUR_CLOCK,
            ),
            schema.Dropdown(
                id = "end_method",
                name = "End time",
                desc = "How to calculate the end time of Shabbat",
                icon = "hourglass",
                default = end_method_options[0].value,
                options = end_method_options,
            ),
        ],
    )
