"""
Applet: Big Clock
Summary: Display a large retro-style clock
Description: Display a large retro-style clock; the clock can change color
  at night based on sunrise and sunset times for a given location, supports
  24-hour and 12-hour variants and optionally flashes the separator.
  Sunrise/sunset times provided by sunrise-sunset.org.
Author: Joey Hoer
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")

# Default configuration values
DEFAULT_LOCATION = {
    "lat": 37.541290,
    "lng": -77.434769,
    "locality": "Richmond, VA",
}
DEFAULT_TIMEZONE = "US/Eastern"
DEFAULT_IS_24_HOUR_FORMAT = True
DEFAULT_HAS_LEADING_ZERO = False
DEFAULT_HAS_FLASHING_SEPERATOR = True
DEFAULT_COLOR_DAYTIME = "#fff"  # White
DEFAULT_COLOR_NIGHTTIME = "#fff"  # White

# Constants
TTL = 21600  # 6 hours
NUMBER_IMGS = [
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAqSURBVHgBY7B
/wDD/BMP5GQwPLPChAxIMDRwMYABkALn41QMNBBoLNBwAHrcge26o7fIAAAAASUVORK5CYII=
""",  # 0
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAZSURBVHgBYwA
BDgYGCQYGC7xIAqyMgVT1AOfwBOG2xNZsAAAAAElFTkSuQmCC
""",  # 1
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBY7B
/wCB/goF/BgODBV4kAVQGVAxC8w8wHGBgeIAXnW8AKgMqBgBzoBbH0MZ6/gAAAABJRU5ErkJggg==
""",  # 2
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAlSURBVHgBY7B
/wCB/goF/BgODBV4kAVQGVAxRD+TiVw80EKIeAJk5DfdkeUVkAAAAAElFTkSuQmCC
""",  # 3
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBYwC
CBg6GAxIMDyzwIJCC+ScY7B+AkPwJBgYJBgYLPAisgANoNgDVyhQd//DRbQAAAABJRU5ErkJggg==
""",  # 4
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAuSURBVHgBY7B
/wDD/AMP5BoYHDPjQAQagMqBiEJI/wcAgwcBggQ/xzwAqAyoGABq+Fsfy3SMpAAAAAElFTkSuQmCC
""",  # 5
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBY7R
fyDhfkfH8RsYHCvjQAQegMqBisHpNxgMRjA/wovMngcqAigEwiCIRDKuGtwAAAABJRU5ErkJggg==
""",  # 6
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAhSURBVHgBY7B
/wCB/goF/BgODBV4kwcDAwQAFHEAukeoB0jsHbnVM+9YAAAAASUVORK5CYII=
""",  # 7
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAmSURBVHgBY7B
/wDD/BMP5GQwPLPChAxJAZUDFEPVALn71QAMh6gHctSR33GtExAAAAABJRU5ErkJggg==
""",  # 8
    """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAuSURBVHgBY7B
/wDD/BMP5GQwPLPChAxJAZUDFICR/goFBgoHBAh/in8EgD1IPAMkGGTcArQUNAAAAAElFTkSuQmCC
""",  # 9
]

SEP = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAOAQAAAAAgEYC1AAAAAnRSTlMAAQGU/a4AAAAPSURBVHgBY0g
AQzQAEQUAH5wCQbfIiwYAAAAASUVORK5CYII=
""")

DEGREE = 0.01745329251

# It would be easier to use a custom font, but we can use images instead.
# The images have a black background and transparent foreground. This
# allows us to change the color dynamically.
def get_num_image(num, color):
    return render.Box(
        width = 13,
        height = 32,
        color = color,
        child = render.Image(src = base64.decode(NUMBER_IMGS[int(num)])),
    )

def get_time_image(t, color, is_24_hour_format = True, has_leading_zero = False, has_seperator = True):
    hh = t.format("03")  # Formet for 12 hour time
    if is_24_hour_format == True:
        hh = t.format("15")  # Format for 24 hour time
    mm = t.format("04")
    ss = t.format("05")

    seperator = render.Box(
        width = 4,
        height = 14,
        color = color,
        child = render.Image(src = SEP),
    )
    if not has_seperator:
        seperator = render.Box(
            width = 4,
        )

    hh0 = get_num_image(int(hh[0]), color)
    if int(hh[0]) == 0 and has_leading_zero == False:
        hh0 = render.Box(
            width = 13,
        )

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            hh0,
            get_num_image(int(hh[1]), color),
            seperator,
            get_num_image(int(mm[0]), color),
            get_num_image(int(mm[1]), color),
        ],
    )

def truncate_location(f, decimals = 1):
    p = math.pow(10, decimals)
    return math.round(f * p) / p

def main(config):
    # Get the current time in 24 hour format
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))  # Utilize special timezone variable
    now = time.now()

    # Fetch sunrise/sunset times
    sunrise, sunset = sunrise_sunset(truncate_location(float(loc.get("lat"))), truncate_location(float(loc.get("lng"))))

    # Because the times returned by this API do not include the date, we need to
    # strip the date from "now" to get the current time in order to perform
    # acurate comparissons.
    # Local time must be localized with a timezone
    current_time = time.parse_time(now.in_location(timezone).format("3:04:05 PM"), format = "3:04:05 PM", location = timezone)
    day_end = time.parse_time("11:59:59 PM", format = "3:04:05 PM", location = timezone)

    # Get config values
    is_24_hour_format = config.get("is_24_hour_format", DEFAULT_IS_24_HOUR_FORMAT)
    has_leading_zero = config.get("has_leading_zero", DEFAULT_HAS_LEADING_ZERO)
    has_flashing_seperator = config.get("has_flashing_seperator", DEFAULT_HAS_FLASHING_SEPERATOR)
    color_daytime = config.get("color_daytime", DEFAULT_COLOR_DAYTIME)
    color_nighttime = config.get("color_nighttime", DEFAULT_COLOR_NIGHTTIME)

    frames = []
    print_time = current_time

    # The API limit is ≈256kb (as reported by error messages).
    # However, sending a 256kb file doesn't seem to work.
    # Increase the duration to create an image containing multples minutes
    # of frames to smooth out potential network issues.
    # Currently this does not work, becasue app rotation prevents the animation
    # from progressing past a few seconds.
    duration = 1  # in minutes; 1440 = 24 hours
    for i in range(0, duration):
        # Set different color during day and night
        color = color_nighttime
        if sunrise == None or sunset == None:
            # Antarctica, north pole, etc.
            color = color_daytime
        elif now > sunrise and now < sunset:
            color = color_daytime
        frames.append(get_time_image(print_time, color, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = True))

        if has_flashing_seperator:
            # If the duration is greater than one minute,
            # generate one frame for each flash of the seperator for the whole minute
            number_of_frames = 1
            if duration > 1:
                # Two frames per second, minus one because first frame is created above
                number_of_frames = 60 * 2 - 1
            for j in range(0, number_of_frames):
                has_seperator = False
                if j % 2:
                    has_seperator = True
                frames.append(get_time_image(print_time, color, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = has_seperator))
        print_time = print_time + time.minute

        # If time is tomorrow, reset to today
        # This simplifies sunset/sunrise calculations
        if print_time > day_end:
            print_time = print_time - (time.hour * 24)

    return render.Root(
        delay = 500,  # in milliseconds
        child = render.Box(
            child = render.Animation(
                children = frames,
            ),
        ),
    )

def get_schema():
    colors = [
        schema.Option(display = "White", value = "#fff"),
        schema.Option(display = "Red", value = "#f00"),
        schema.Option(display = "Dark Red", value = "#200"),
        schema.Option(display = "Green", value = "#0f0"),
        schema.Option(display = "Blue", value = "#00f"),
        schema.Option(display = "Yellow", value = "#ff0"),
        schema.Option(display = "Cyan", value = "#0ff"),
        schema.Option(display = "Magenta", value = "#f0f"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location defining time to display and daytime/nighttime colors",
                icon = "place",
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                icon = "clock",
                desc = "Display the time in 24 hour format.",
            ),
            schema.Toggle(
                id = "has_leading_zero",
                name = "Add leading zero",
                icon = "creativeCommonsZero",
                desc = "Ensure the clock always displays with a leading zero.",
            ),
            schema.Toggle(
                id = "has_flashing_seperator",
                name = "Enable flashing separator",
                icon = "cog",
                desc = "Ensure the clock always displays with a leading zero.",
            ),
            schema.Dropdown(
                id = "color_daytime",
                icon = "sun",
                name = "Daytime color",
                desc = "The color to display in the daytime.",
                options = colors,
                default = DEFAULT_COLOR_DAYTIME,
            ),
            schema.Dropdown(
                id = "color_nighttime",
                icon = "moon",
                name = "Nighttime color",
                desc = "The color to display at night.",
                options = colors,
                default = DEFAULT_COLOR_NIGHTTIME,
            ),
        ],
    )

def julian_day(t):
    return (float(t.unix) / 86400) + 2440587.5

def julian_day_to_time(d):
    return time.from_timestamp(int((d - 2440587.5) * 86400)).in_location("UTC")

def mean_solar_noon(lon, year, month, day):
    s = "%d-%d-%dT12:00:00" % (year, month, day)
    t = time.parse_time(s, format = "2006-1-2T15:04:05", location = "UTC")

    return julian_day(t) - (lon / 360)

def solar_mean_anomaly(mean_solar_noon):
    v = math.remainder(357.5291 + 0.98560028 * (mean_solar_noon - 2451545), 360)
    return v if v >= 0 else v + 360

def equation_of_center(solar_mean_anomaly):
    anomaly_rad = solar_mean_anomaly * DEGREE
    anomaly_sin = math.sin(anomaly_rad)
    anomaly_sin2 = math.sin(2 * anomaly_rad)
    anomaly_sin3 = math.sin(3 * anomaly_rad)
    return 1.9148 * anomaly_sin + 0.0200 * anomaly_sin2 + 0.003 * anomaly_sin3

def ecliptic_longitude(solar_mean_anomaly, equation_of_center, mean_solar_noon):
    aop = 102.93005 + 0.3179526 * (mean_solar_noon - 2451545) / 36525
    return math.mod(solar_mean_anomaly + equation_of_center + 180 + aop, 360)

def solar_transit(mean_solar_noon, solar_mean_anomaly, ecliptic_longitude):
    eot = 0.0053 * math.sin(solar_mean_anomaly * DEGREE) - 0.0069 * math.sin(2 * ecliptic_longitude * DEGREE)
    return mean_solar_noon + eot

def declination(ecliptic_longitude):
    return math.asin(math.sin(ecliptic_longitude * DEGREE) * 0.39779) / DEGREE

def hour_angle(lat, declination):
    lat_rad = lat * DEGREE
    declination_rad = declination * DEGREE
    numerator = -0.01449 - math.sin(lat_rad) * math.sin(declination_rad)
    denominator = math.cos(lat_rad) * math.cos(declination_rad)

    result = numerator / denominator

    if result > 1 or result < -1:
        # sun never rises or never sets
        return None

    return math.acos(result) / DEGREE

def sunrise_sunset(lat, lon):
    t = time.now().in_location("UTC")

    msn = mean_solar_noon(lon, t.year, t.month, t.day)
    sma = solar_mean_anomaly(msn)
    eoc = equation_of_center(sma)
    el = ecliptic_longitude(sma, eoc, msn)
    st = solar_transit(msn, sma, el)
    dec = declination(el)
    ha = hour_angle(lat, dec)

    if not ha:
        return None, None

    sunrise = julian_day_to_time(st - ha / 360)
    sunset = julian_day_to_time(st + ha / 360)
    return sunrise, sunset
