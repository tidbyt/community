"""
Applet: Islamic Salah
Summary: Daily Islamic prayer times
Description: Display daily Islamic prayer times for a selected location, with a choice of calculation method and Standard/Shafi or Hanafi Asr.
Author: egemenuzunali
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Defaults are Amsterdam for local development. Community installations use the
# Location field in get_schema().
DEFAULT_LOCATION = {
    "lat": "52.3676",
    "lng": "4.9041",
    "locality": "Amsterdam",
    "timezone": "Europe/Amsterdam",
}
DEFAULT_METHOD = "3"  # Muslim World League
DEFAULT_SCHOOL = "0"  # Standard / Shafi. Use "1" for Hanafi.

PRAYERS = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
SHORT_NAMES = {
    "Fajr": "FAJR",
    "Dhuhr": "DHUHR",
    "Asr": "ASR",
    "Maghrib": "MAGHRIB",
    "Isha": "ISHA",
}

def message_screen(message):
    return render.Root(
        child = render.Box(
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Text("PRAYER TIMES", font = "CG-pixel-3x5-mono", color = "#4de3c1"),
                    render.Text(message, font = "CG-pixel-3x5-mono", color = "#f6b94a"),
                ],
            ),
        ),
    )

def truncate_coordinate(value):
    # Keep enough precision for useful timings (~1 km), without sending an
    # exact device location to the external prayer-times provider.
    parts = str(value).split(".")
    if len(parts) == 1:
        return parts[0]
    return parts[0] + "." + parts[1][0:2]

def prayer_line(name, prayer_times, highlighted):
    color = "#f6b94a" if highlighted else "#b6c1d4"
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(
                content = " " + SHORT_NAMES[name],
                font = "CG-pixel-3x5-mono",
                color = color,
            ),
            render.Text(
                content = prayer_times[name],
                font = "CG-pixel-3x5-mono",
                color = color,
            ),
        ],
    )

def main(config):
    location_value = config.get("location")
    location = json.decode(location_value) if location_value else DEFAULT_LOCATION
    latitude = truncate_coordinate(location["lat"])
    longitude = truncate_coordinate(location["lng"])
    timezone = location["timezone"]
    method = config.str("method", DEFAULT_METHOD)
    school = config.str("school", DEFAULT_SCHOOL)
    now = time.now().in_location(timezone)

    url = "https://api.aladhan.com/v1/timings/%s?latitude=%s&longitude=%s&method=%s&school=%s&timezonestring=%s" % (
        now.format("02-01-2006"),
        latitude,
        longitude,
        method,
        school,
        timezone,
    )
    response = http.get(url, ttl_seconds = 900)
    if response.status_code != 200:
        return message_screen("DATA UNAVAILABLE")

    timings = response.json()["data"]["timings"]
    prayer_times = {}
    for name in PRAYERS:
        # AlAdhan times may contain a timezone suffix; Tidbyt needs HH:MM only.
        prayer_times[name] = timings[name].split(" ")[0]

    current_time = now.format("15:04")
    next_index = 0
    found_next = False
    for index in range(len(PRAYERS)):
        if prayer_times[PRAYERS[index]] > current_time and not found_next:
            next_index = index
            found_next = True

    next_prayer = PRAYERS[next_index]
    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    prayer_line("Fajr", prayer_times, next_prayer == "Fajr"),
                    prayer_line("Dhuhr", prayer_times, next_prayer == "Dhuhr"),
                    prayer_line("Asr", prayer_times, next_prayer == "Asr"),
                    prayer_line("Maghrib", prayer_times, next_prayer == "Maghrib"),
                    prayer_line("Isha", prayer_times, next_prayer == "Isha"),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Choose the location for prayer times.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "method",
                name = "Calculation method",
                desc = "Choose the authority used to calculate prayer times.",
                icon = "calculator",
                default = DEFAULT_METHOD,
                options = [
                    schema.Option(display = "Muslim World League", value = "3"),
                    schema.Option(display = "Islamic Society of North America", value = "2"),
                    schema.Option(display = "Umm al-Qura", value = "4"),
                    schema.Option(display = "Diyanet (Turkey)", value = "13"),
                    schema.Option(display = "Moonsighting Committee", value = "15"),
                ],
            ),
            schema.Dropdown(
                id = "school",
                name = "Asr calculation",
                desc = "Choose the standard/Shafi or Hanafi school.",
                icon = "mosque",
                default = DEFAULT_SCHOOL,
                options = [
                    schema.Option(display = "Standard / Shafi", value = "0"),
                    schema.Option(display = "Hanafi", value = "1"),
                ],
            ),
        ],
    )
