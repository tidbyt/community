load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Optional test date in YYYY-MM-DD format; leave empty for the live date.
# Example: TEST_DATE = "2026-11-27"
TEST_DATE = ""

# Default location
DEFAULT_LOCATION = """
{
    "lat": 51.5074,
    "lng": -0.1278,
    "timezone": "Europe/London"
}
"""

# Sunrise Icon: golden sun above a blue horizon
SUNRISE_ICON = """
<svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 11 11">
  <!-- rays -->
  <rect x="1" y="5" width="1" height="1" fill="#FF9F59"/>
  <rect x="0" y="5" width="1" height="1" fill="#FF9F59"/>
  <rect x="3" y="3" width="1" height="1" fill="#FF9F59"/>
  <rect x="2" y="2" width="1" height="1" fill="#FF9F59"/>
  <rect x="1" y="1" width="1" height="1" fill="#FF9F59"/>
  <rect x="5" y="0" width="1" height="1" fill="#FF9F59"/>
  <rect x="5" y="1" width="1" height="1" fill="#FF9F59"/>
  <rect x="5" y="2" width="1" height="1" fill="#FF9F59"/>
  <rect x="7" y="3" width="1" height="1" fill="#FF9F59"/>
  <rect x="8" y="2" width="1" height="1" fill="#FF9F59"/>
  <rect x="9" y="1" width="1" height="1" fill="#FF9F59"/>
  <rect x="9" y="5" width="1" height="1" fill="#FF9F59"/>
  <rect x="10" y="5" width="1" height="1" fill="#FF9F59"/>
    <!-- half sun -->
  <rect x="4" y="3" width="3" height="1" fill="#FF9F59"/>
  <rect x="2" y="4" width="7" height="1" fill="#FF9F59"/>
  <rect x="2" y="5" width="7" height="1" fill="#FF9F59"/>
  <rect x="2" y="6" width="7" height="1" fill="#FF9F59"/>
  <!-- horizon -->
  <rect x="0" y="7" width="11" height="1" fill="#36B7E8"/>
  <rect x="0" y="8" width="11" height="1" fill="#36B7E8"/>
</svg>
"""

# Moon Icon: based on the SVG moon icon in the Font Awesome SVG repository
MOON_ICON = """
<svg xmlns="http://www.w3.org/2000/svg" width="9" height="11" viewBox="0 0 9 11">
  <path fill="#858D98" d="M6.8 1.2C5.8 1.2 4.8 1.6 4 2.4C2.4 4 2.4 6.6 4 8.2C4.8 9 5.8 9.4 6.8 9.4C5.9 10.0 4.8 10.3 3.7 10.3C1.1 10.3 0 8.2 0 5.9C0 3.5 1.6 1.1 4.3 1.1C5.2 1.1 6.1 1.1 6.8 1.2Z"/>
</svg>
"""

# Daylight Icon: full yellow sun
DAYLIGHT_ICON = """
<svg xmlns="http://www.w3.org/2000/svg" width="10" height="11" viewBox="0 0 9 11">
  <!-- rays -->
  <rect x="4" y="0" width="1" height="1" fill="#FFC54F"/>
  <rect x="4" y="1" width="1" height="1" fill="#FFC54F"/>
  <rect x="4" y="9" width="1" height="1" fill="#FFC54F"/>
  <rect x="4" y="10" width="1" height="1" fill="#FFC54F"/>
  <rect x="0" y="5" width="1" height="1" fill="#FFC54F"/>
  <rect x="8" y="5" width="1" height="1" fill="#FFC54F"/>
  <rect x="0" y="1" width="1" height="1" fill="#FFC54F"/>
  <rect x="1" y="2" width="1" height="1" fill="#FFC54F"/>
  <rect x="8" y="1" width="1" height="1" fill="#FFC54F"/>
  <rect x="7" y="2" width="1" height="1" fill="#FFC54F"/>
  <rect x="0" y="9" width="1" height="1" fill="#FFC54F"/>
  <rect x="1" y="8" width="1" height="1" fill="#FFC54F"/>
  <rect x="8" y="9" width="1" height="1" fill="#FFC54F"/>
  <rect x="7" y="8" width="1" height="1" fill="#FFC54F"/>
  <!-- disk -->
  <rect x="3" y="2" width="3" height="1" fill="#FFC54F"/>
  <rect x="2" y="3" width="5" height="5" fill="#FFC54F"/>
  <rect x="3" y="8" width="3" height="1" fill="#FFC54F"/>
  <rect x="1" y="4" width="1" height="3" fill="#FFC54F"/>
  <rect x="7" y="4" width="1" height="3" fill="#FFC54F"/>
</svg>
"""

def pad2(n):
    """Display 0 to 99 with two digits."""
    return ("0" + str(n))[-2:]

def get_solar_days(lat, lng, tz, start_date, end_date):
    """Fetch yesterday and today from Sunrise-Sunset.org v2.
    A non-200 HTTP response or an unexpected JSON *shape* returns None.
    Pixlet/Starlark does not support Python try/except, so a transport
    exception or invalid JSON itself can still stop this render.
    """

    # Reduce coordinate precision to approximately 1 km
    api_lat = int(lat * 100) / 100.0
    api_lng = int(lng * 100) / 100.0
    url = (
        "https://api.sunrise-sunset.org/v2?lat=" + str(api_lat) +
        "&lng=" + str(api_lng) +
        "&tz=" + tz.replace("+", "%2B") +
        "&date_start=" + start_date +
        "&date_end=" + end_date +
        "&time_format=unix"
    )
    response = http.get(url, ttl_seconds = 86400)
    if response.status_code != 200:
        print("Sunrise-Sunset.org request failed:", response.status_code)
        return None

    payload = response.json()
    if type(payload) != "dict":
        return None
    days = payload.get("days")
    if type(days) != "list":
        return None

    result = {}
    for day in days:
        if type(day) == "dict" and type(day.get("date")) == "string":
            result[day["date"]] = day
    return result

def daylight_seconds(day, tz):
    """Return daylight duration from the API (or None if unavailable).
    On polar-circle transition days the API can have only sunrise or only
    sunset. Compute time spent above the horizon inside that local day.
    """
    if type(day) != "dict":
        return None

    duration = day.get("day_length")
    if type(duration) == "int" or type(duration) == "float":
        if duration >= 0 and duration <= 86400:
            return int(duration)
        return None

    status = day.get("sun_status")
    if status == "polar_night":
        return 0
    if status == "midnight_sun":
        return 86400

    rise = day.get("sunrise")
    setting = day.get("sunset")
    if (rise == None and setting == None or
        rise != None and setting != None):
        return None
    if (rise != None and type(rise) not in ["int", "float"] or
        setting != None and type(setting) not in ["int", "float"]):
        return None

    date_str = day.get("date")
    if type(date_str) != "string":
        return None

    noon = time.parse_time(
        date_str + "T12:00:00",
        format = "2006-01-02T15:04:05",
        location = tz,
    )
    start = time.time(
        year = noon.year,
        month = noon.month,
        day = noon.day,
        location = tz,
    ).unix

    # Advance local *noon* one day, then reconstruct local midnight.
    # Avoid day=noon.day+1 (unsafe at month/year boundaries).
    next_noon = (noon + time.parse_duration("24h")).in_location(tz)
    end = time.time(
        year = next_noon.year,
        month = next_noon.month,
        day = next_noon.day,
        location = tz,
    ).unix

    if rise != None:
        return max(0, min(86400, int(end - rise)))
    return max(0, min(86400, int(setting - start)))

def get_season_events(year):
    """Get USNO solstices/equinoxes for a UTC calendar year."""
    url = "https://aa.usno.navy.mil/api/seasons?year=" + str(year)
    response = http.get(url, ttl_seconds = 86400)
    if response.status_code != 200:
        print("USNO request failed:", response.status_code)
        return []

    payload = response.json()
    if type(payload) != "dict":
        return []
    data = payload.get("data")
    if type(data) != "list":
        return []
    return data

def next_event(today, timezone):
    """Next equinox/solstice, counted by the user's local calendar date."""
    local = today.in_location(timezone)
    current_date = time.time(
        year = local.year,
        month = local.month,
        day = local.day,
        hour = 12,
        location = "UTC",
    )

    best_days = None
    best_label = None
    for year in [local.year, local.year + 1]:
        events = get_season_events(year)

        for event in events:
            if type(event) != "dict":
                continue

            # Be forgiving about capitalization and extra event descriptions.
            label = str(event.get("phenom", "")).lower()
            if "solstice" in label:
                event_label = "Solstice"
            elif "equinox" in label:
                event_label = "Equinox"
            else:
                continue

            # JSON number types may vary; do not require exact 'int' types.
            if (event.get("year") == None or event.get("month") == None or
                event.get("day") == None):
                continue
            year_num = int(event["year"])
            month_num = int(event["month"])
            day_num = int(event["day"])

            # Accept HH:MM and HH:MM:SS, with optional trailing timezone text.
            clock = str(event.get("time", "")).split(" ")[0]
            if len(clock) == 5 and clock[2] == ":":
                clock = clock + ":00"
            if len(clock) != 8 or clock[2] != ":" or clock[5] != ":":
                continue

            utc_event = time.parse_time(
                str(year_num) + "-" + pad2(month_num) + "-" +
                pad2(day_num) + "T" + clock,
                format = "2006-01-02T15:04:05",
                location = "UTC",
            )
            local_event = utc_event.in_location(timezone)
            event_date = time.time(
                year = local_event.year,
                month = local_event.month,
                day = local_event.day,
                hour = 12,
                location = "UTC",
            )
            days = int((event_date - current_date).seconds / 86400)
            if days >= 0 and (best_days == None or days < best_days):
                best_days = days
                best_label = event_label

    if best_days == None:
        return "Event N/A"
    return best_label + ":" + str(best_days) + "d"

def main(config):
    # Fetch inputs ------------------------------------------------------------
    # Location selected in the Tidbyt mobile app
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    tz = loc["timezone"]

    # Option to hide or show daylight change in Row 2
    show_delta = config.bool("show_delta", True)

    # Live local date, or a temporary override during testing
    if TEST_DATE:
        now = time.parse_time(
            TEST_DATE + "T12:00:00",
            format = "2006-01-02T15:04:05",
            location = tz,
        )
    else:
        now = time.now()
    local = now.in_location(tz)

    # Use local noon to select the correct local date
    today = time.time(
        year = local.year,
        month = local.month,
        day = local.day,
        hour = 12,
        location = tz,
    )
    yesterday = today - time.parse_duration("24h")
    today_date = today.format("2006-01-02")
    yesterday_date = yesterday.in_location(tz).format("2006-01-02")

    # Fetch yesterday and today in a single API request
    # Solar API errors must not hide the USNO countdown
    solar_days = get_solar_days(lat, lng, tz, yesterday_date, today_date)
    if solar_days == None:
        solar_days = {}
    solar_today = solar_days.get(today_date)
    solar_yesterday = solar_days.get(yesterday_date)
    seconds_today = daylight_seconds(solar_today, tz)
    seconds_yesterday = daylight_seconds(solar_yesterday, tz)

    # Row 1: sunrise and sunset -----------------------------------------------
    if type(solar_today) != "dict":
        row1 = render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(
                    "Solar data N/A",
                    font = "tom-thumb",
                    color = "#FF9477",
                ),
            ],
        )
    else:
        status = solar_today.get("sun_status")
        polar = status == "polar_night" or status == "midnight_sun"
        if polar:
            if status == "midnight_sun":
                polar_text = "Midnight Sun"
                polar_color = "#FFC54F"
            else:
                polar_text = "Polar Night"
                polar_color = "#858D98"
            row1 = render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(
                        polar_text,
                        font = "tom-thumb",
                        color = polar_color,
                    ),
                ],
            )
        else:
            rise = solar_today.get("sunrise")
            setting = solar_today.get("sunset")
            rise_text = (
                time.from_timestamp(int(rise)).in_location(tz).format("15:04") if type(rise) in ["int", "float"] else "--:--"
            )
            set_text = (
                time.from_timestamp(int(setting)).in_location(tz).format("15:04") if type(setting) in ["int", "float"] else "--:--"
            )
            row1 = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Row(
                        cross_align = "center",
                        children = [
                            render.Image(src = SUNRISE_ICON),
                            render.Box(width = 1, height = 1),
                            render.Text(
                                rise_text,
                                font = "tom-thumb",
                                color = "#FFFFFF",
                            ),
                        ],
                    ),
                    render.Row(
                        cross_align = "center",
                        children = [
                            render.Image(src = MOON_ICON),
                            render.Box(width = 1, height = 1),
                            render.Text(
                                set_text,
                                font = "tom-thumb",
                                color = "#FFFFFF",
                            ),
                        ],
                    ),
                ],
            )

    # Row 2: total daylight and daily change ----------------------------------
    if seconds_today == None:
        day_text = "--"
    else:
        hours = seconds_today // 3600
        str_hrs = str(hours) + "h" if hours > 0 else ""
        minutes = (seconds_today % 3600) // 60
        day_text = str_hrs + pad2(minutes) + "m"

    if seconds_today == None or seconds_yesterday == None:
        change_text = "N/A"
        change_color = "#858D98"
    else:
        delta = seconds_today - seconds_yesterday
        if delta > 0:
            sign = "+"
            change_color = "#80D69B"
        elif delta < 0:
            sign = "-"
            change_color = "#FF9477"
        else:
            sign = ""
            change_color = "#FFFFFF"
        delta_abs = abs(delta)
        if delta_abs > 3600:
            # Display ##h##m only for changes greater than one hour
            change_text = (sign + str(delta_abs // 3600) + "h" +
                           pad2((delta_abs % 3600) // 60) + "m")
        elif delta_abs == 0:
            change_text = "same"
        elif delta_abs < 60:
            # Display #s only for changes smaller than one minute
            change_text = sign + str(delta_abs) + "s"
        else:
            # Display #m##s for all other cases
            change_text = (sign + str(delta_abs // 60) + "m" +
                           pad2(delta_abs % 60) + "s")

    day_widget = render.Text(day_text, font = "tom-thumb", color = "#FFE8B0")

    # Row 2 always begins with the Sun icon and daylight duration
    row2_children = [
        render.Image(src = DAYLIGHT_ICON),
        render.Box(width = 1, height = 1),
        day_widget,
    ]
    row2_width = 8 + day_widget.size()[0]

    # Add the daily change only if requested
    if show_delta:
        change_widget = render.Text(
            "(" + change_text + ")",
            font = "tom-thumb",
            color = change_color,
        )
        row2_children.append(change_widget)
        row2_width = row2_width + change_widget.size()[0]

    row2_content = render.Row(
        cross_align = "center",
        children = row2_children,
    )

    if row2_width <= 64:
        # Static, horizontally centered row
        row2 = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = row2_children,
        )
    else:
        # Scrolling row
        overflow = row2_width - 64
        row2 = animation.Transformation(
            child = row2_content,
            width = 64,
            height = 11,
            duration = max(16, overflow),
            direction = "alternate",
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(0, 0)],
                    curve = "ease_in_out",
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(-overflow, 0)],
                ),
            ],
        )

    # Row 3: next solstice or equinox -----------------------------------------
    row3 = render.Column(
        children = [
            render.Box(width = 64, height = 1, color = "#34404A"),
            render.Box(width = 1, height = 2),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(
                        next_event(today, tz),
                        font = "CG-pixel-4x5-mono",
                        color = "#8FAFC4",
                    ),
                ],
            ),
        ],
    )

    # Create the complete render ----------------------------------------------
    return render.Root(
        delay = 150,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [row1, row2, row3],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Choose where to calculate daylight times.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "show_delta",
                name = "Show daily change",
                desc = "Display the change in daylight since yesterday.",
                icon = "clock",
                default = True,
            ),
        ],
    )
