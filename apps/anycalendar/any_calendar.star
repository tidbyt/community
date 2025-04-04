"""
Applet: Any Calendar
Summary: Display any ICS calendar
Description: Show current or upcoming events from a Google or Outlook calendar with just an ICS link - no login necessary. Can choose to show time or only the event title - perfect for scheduling announcements.
Author: Vik Boyechko
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def render_error(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Text("ERROR", color = "#DB4437"),
                render.Text(message, color = "#DB4437"),
            ],
            main_align = "center",
            expanded = True,
        ),
    )

def main(config):
    # Get configuration
    calendar_link = config.get("calendar_link", "")
    timezone = config.get("timezone", "America/New_York")
    text_only = config.bool("text_only", False)

    # Get color configuration with defaults
    time_bg_color = config.get("time_bg_color", "#1a73e8")  # Google blue
    time_text_color = config.get("time_text_color", "#ffffff")  # White
    event_bg_color = config.get("event_bg_color", "#000000")  # Black
    event_text_color = config.get("event_text_color", "#7FFF7F")  # Light green

    # Use tom-thumb font as it's the most readable for small text
    font = "tom-thumb"

    # If no calendar link provided, show instructions
    if not calendar_link:
        return render.Root(
            child = render.Column(
                children = [
                    # Time display
                    render.Box(
                        width = 64,
                        height = 10,
                        color = time_bg_color,
                        child = render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Text(
                                "5-6PM",
                                color = time_text_color,
                                font = font,
                            ),
                        ),
                    ),
                    # Event title
                    render.Box(
                        width = 64,
                        height = 22,
                        color = event_bg_color,
                        child = render.Column(
                            expanded = True,
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.WrappedText(
                                    content = "Enter Calendar Link to Get Started",
                                    color = event_text_color,
                                    font = font,
                                    width = 62,
                                    align = "center",
                                ),
                            ],
                        ),
                    ),
                ],
                main_align = "center",
                expanded = True,
            ),
        )

    # Fetch calendar data
    resp = http.get(calendar_link)
    if resp.status_code != 200:
        return render_error("Failed to fetch: {}".format(resp.status_code))

    # Extract calendar data
    ics_data = resp.body()

    # Get current time and date
    now = time.now().in_location(timezone)
    utc_now = time.now().in_location("UTC")

    # Calculate correct UTC offset (will be negative for times behind UTC)
    utc_offset = (now.hour - utc_now.hour)
    if utc_offset > 12:  # If offset is too large, adjust
        utc_offset -= 24
    elif utc_offset < -12:  # If offset is too small, adjust
        utc_offset += 24

    current_day = now.day
    current_month = now.month
    current_year = now.year
    current_hour = now.hour
    current_minute = now.minute

    # Calculate current time in minutes for easier comparisons
    current_time_in_minutes = current_hour * 60 + current_minute

    # Format today's date for comparisons
    today_date = "{}-{}-{}".format(current_year, format_number(current_month), format_number(current_day))

    # Extract events
    current_events = []
    all_day_events = []
    upcoming_events = []
    current_event = {
        "title": "",
        "start_time": "",
        "end_time": "",
        "time_display": "No time info",
        "is_all_day": False,
        "start_date": "",
        "start_hour": -1,
        "start_minute": -1,
        "end_hour": -1,
        "end_minute": -1,
        "is_today": False,
        "has_ended": False,
        "event_day": "",
        "end_date": "",
    }
    in_event = False

    lines = ics_data.split("\n")

    for line in lines:
        line = line.strip()

        # Start of an event
        if line == "BEGIN:VEVENT":
            current_event = {
                "title": "",
                "start_time": "",
                "end_time": "",
                "time_display": "No time info",
                "is_all_day": False,
                "start_date": "",
                "start_hour": -1,
                "start_minute": -1,
                "end_hour": -1,
                "end_minute": -1,
                "is_today": False,
                "has_ended": False,
                "event_day": "",
                "end_date": "",
            }
            in_event = True

            # End of an event
        elif line == "END:VEVENT" and in_event:
            if current_event["title"] and current_event["is_today"]:
                # If there are start and end times, use them
                if current_event["start_time"] and current_event["end_time"]:
                    current_event["time_display"] = "{}-{}".format(
                        current_event["start_time"],
                        current_event["end_time"],
                    )
                    # If it's an all-day event, display "ALL DAY"

                elif current_event["is_all_day"]:
                    current_event["time_display"] = "ALL DAY"
                    all_day_events.append(current_event)

                # Calculate if the event has ended
                if current_event["end_hour"] != -1:
                    end_time_in_minutes = current_event["end_hour"] * 60 + current_event["end_minute"]

                    # For events that cross midnight, don't mark as ended if they end tomorrow
                    if current_event["end_date"] > today_date:
                        current_event["has_ended"] = False
                    elif current_event["end_date"] == today_date and end_time_in_minutes < current_time_in_minutes:
                        current_event["has_ended"] = True

                # Add regular timed events to the appropriate list if they haven't ended
                if not current_event["is_all_day"] and current_event["start_hour"] != -1 and not current_event["has_ended"]:
                    # Check if event is current or upcoming
                    start_time_in_minutes = current_event["start_hour"] * 60 + current_event["start_minute"]

                    if start_time_in_minutes <= current_time_in_minutes:
                        # Current event (started but not ended)
                        current_events.append(current_event)
                    elif start_time_in_minutes > current_time_in_minutes:
                        # Upcoming event today
                        upcoming_events.append(current_event)
            in_event = False

            # Event title
        elif line.startswith("SUMMARY:") and in_event:
            event_title = line[8:].strip()
            current_event["title"] = event_title

            # Start date (for all-day events)
        elif line.startswith("DTSTART;VALUE=DATE:") and in_event:
            # This is an all-day event
            current_event["is_all_day"] = True

            # Extract date to check if it's today
            date_str = line.split(":")[-1].strip()
            if len(date_str) >= 8:
                year = int(date_str[0:4])
                month = int(date_str[4:6])
                day = int(date_str[6:8])

                # Check if this event is today
                if year == current_year and month == current_month and day == current_day:
                    current_event["is_today"] = True
                    month_str = str(month)
                    if month < 10:
                        month_str = "0" + month_str
                    day_str = str(day)
                    if day < 10:
                        day_str = "0" + day_str
                    current_event["start_date"] = str(year) + "-" + month_str + "-" + day_str

            # Start time
        elif line.startswith("DTSTART") and in_event and not current_event["is_all_day"]:
            # Extract date and time to check if event is today
            parts = line.split(":")
            if len(parts) > 1:
                date_time = parts[-1].strip()

                # Check if this has a date component
                if len(date_time) >= 8:
                    year = int(date_time[0:4])
                    month = int(date_time[4:6])
                    day = int(date_time[6:8])

                    # If the time is in UTC (ends with Z), we need to adjust the date based on UTC offset
                    if date_time.endswith("Z"):
                        # For negative UTC offsets (behind UTC), check if we need to adjust the date back
                        if utc_offset < 0:
                            # Calculate hours in UTC
                            utc_hours = int(date_time[9:11]) if len(date_time) > 10 else 0

                            # If the UTC time is late in the day and our offset would push it to previous day
                            if utc_hours + utc_offset < 0:
                                # Adjust the date forward one day as this UTC date represents our previous day
                                if day > 1:
                                    day -= 1
                                else:
                                    # Handle month rollover
                                    if month > 1:
                                        month -= 1

                                        # Get last day of previous month
                                        if month in [4, 6, 9, 11]:
                                            day = 30
                                        elif month == 2:
                                            # Simple leap year check
                                            day = 29 if year % 4 == 0 else 28
                                        else:
                                            day = 31
                                    else:
                                        # Handle year rollover
                                        year -= 1
                                        month = 12
                                        day = 31

                    # Strictly check if this event is specifically for today
                    if year == current_year and month == current_month and day == current_day:
                        current_event["is_today"] = True
                        month_str = format_number(month)
                        day_str = format_number(day)
                        current_event["start_date"] = "{}-{}-{}".format(year, month_str, day_str)

                if "T" in date_time and current_event["is_today"]:
                    time_part = date_time.split("T")[1]
                    if len(time_part) >= 4:
                        hours = int(time_part[0:2])
                        minutes = int(time_part[2:4])

                        # Account for timezone difference
                        if date_time.endswith("Z"):
                            hours = (hours + utc_offset) % 24
                        elif "-" in time_part or "+" in time_part:
                            # Handle explicit timezone offset
                            offset_str = time_part[-5:] if len(time_part) >= 5 else "+0000"
                            offset_hours = int(offset_str[1:3])
                            if offset_str[0] == "-":
                                offset_hours = -offset_hours

                            # Convert from event timezone to local timezone
                            total_offset = utc_offset + offset_hours
                            hours = (hours + total_offset) % 24

                        current_event["start_hour"] = hours
                        current_event["start_minute"] = minutes

                        # Format in 12 hour time
                        am_pm = "AM"
                        display_hours = hours
                        if display_hours >= 12:
                            am_pm = "PM"
                            if display_hours > 12:
                                display_hours -= 12
                        elif display_hours == 0:
                            display_hours = 12

                        # Format with or without minutes
                        if minutes == 0:
                            # For times on the hour (no minutes)
                            current_event["start_time"] = "{}{}".format(display_hours, am_pm)
                        else:
                            # Add a leading zero to minutes if needed
                            min_str = str(minutes)
                            if minutes < 10:
                                min_str = "0" + min_str

                            # For times with minutes
                            current_event["start_time"] = "{}:{}{}".format(display_hours, min_str, am_pm)

            # End time
        elif line.startswith("DTEND") and in_event and not current_event["is_all_day"]:
            # Extract time
            parts = line.split(":")
            if len(parts) > 1:
                date_time = parts[-1].strip()

                # Check if the end date is relevant
                if len(date_time) >= 8:
                    year = int(date_time[0:4])
                    month = int(date_time[4:6])
                    day = int(date_time[6:8])

                    # Store the end date for cross-midnight comparison
                    month_str = format_number(month)
                    day_str = format_number(day)
                    current_event["end_date"] = "{}-{}-{}".format(year, month_str, day_str)

                    # If the time is in UTC (ends with Z), we need to adjust the date based on UTC offset
                    if date_time.endswith("Z"):
                        # For negative UTC offsets (behind UTC), check if we need to adjust the date back
                        if utc_offset < 0:
                            # Calculate hours in UTC
                            utc_hours = int(date_time[9:11]) if len(date_time) > 10 else 0

                            # If the UTC time is early in the day and our offset would push it to previous day
                            if utc_hours + utc_offset < 0:
                                # Adjust the date back one day
                                if day > 1:
                                    day -= 1
                                else:
                                    # Handle month rollover
                                    if month > 1:
                                        month -= 1

                                        # Get last day of previous month
                                        if month in [4, 6, 9, 11]:
                                            day = 30
                                        elif month == 2:
                                            # Simple leap year check
                                            day = 29 if year % 4 == 0 else 28
                                        else:
                                            day = 31
                                    else:
                                        # Handle year rollover
                                        year -= 1
                                        month = 12
                                        day = 31
                                month_str = format_number(month)
                                day_str = format_number(day)
                                current_event["end_date"] = "{}-{}-{}".format(year, month_str, day_str)

                    # For events ending tomorrow, don't mark them as ended
                    tomorrow = current_day + 1
                    tomorrow_month = current_month
                    tomorrow_year = current_year

                    # Handle month rollover for tomorrow's date
                    if tomorrow > 28:
                        if current_month == 2:
                            # Check if it's a leap year
                            if (current_year % 4 == 0 and tomorrow > 29) or (current_year % 4 != 0 and tomorrow > 28):
                                tomorrow = 1
                                tomorrow_month = 3
                        elif current_month in [4, 6, 9, 11] and tomorrow > 30:
                            tomorrow = 1
                            tomorrow_month += 1
                        elif tomorrow > 31:
                            tomorrow = 1
                            tomorrow_month += 1

                    # Handle year rollover
                    if tomorrow_month > 12:
                        tomorrow_month = 1
                        tomorrow_year += 1

                    tomorrow_date = "{}-{}-{}".format(
                        tomorrow_year,
                        format_number(tomorrow_month),
                        format_number(tomorrow),
                    )

                    if current_event["end_date"] > today_date and current_event["end_date"] <= tomorrow_date:
                        current_event["has_ended"] = False
                    elif current_event["end_date"] < today_date:
                        current_event["has_ended"] = True
                        current_event["is_today"] = False

                if "T" in date_time and current_event["is_today"]:
                    time_part = date_time.split("T")[1]
                    if len(time_part) >= 4:
                        hours = int(time_part[0:2])
                        minutes = int(time_part[2:4])

                        # Account for timezone difference using same logic as start time
                        if date_time.endswith("Z"):
                            hours = (hours + utc_offset) % 24
                        elif "-" in time_part or "+" in time_part:
                            # Handle explicit timezone offset
                            offset_str = time_part[-5:] if len(time_part) >= 5 else "+0000"
                            offset_hours = int(offset_str[1:3])
                            if offset_str[0] == "-":
                                offset_hours = -offset_hours

                            # Convert from event timezone to local timezone
                            total_offset = utc_offset + offset_hours
                            hours = (hours + total_offset) % 24

                        # Store end time
                        current_event["end_hour"] = hours
                        current_event["end_minute"] = minutes

                        # Format in 12 hour time
                        am_pm = "AM"
                        display_hours = hours
                        if display_hours >= 12:
                            am_pm = "PM"
                            if display_hours > 12:
                                display_hours -= 12
                        elif display_hours == 0:
                            display_hours = 12

                        # Format with or without minutes
                        if minutes == 0:
                            # For times on the hour (no minutes)
                            current_event["end_time"] = "{}{}".format(display_hours, am_pm)
                        else:
                            # Add a leading zero to minutes if needed
                            min_str = str(minutes)
                            if minutes < 10:
                                min_str = "0" + min_str

                            # For times with minutes
                            current_event["end_time"] = "{}:{}{}".format(display_hours, min_str, am_pm)

    # Sort upcoming events by start time
    if len(upcoming_events) > 0:
        upcoming_events = sorted(upcoming_events, key = lambda e: e["start_hour"] * 60 + e["start_minute"])

    # Extra check: Filter all events again to make sure they're only from today
    today_date = str(current_year) + "-" + format_number(current_month) + "-" + format_number(current_day)

    # Filter all event lists to ensure no past days' events appear
    all_day_events = [e for e in all_day_events if e["start_date"] == today_date]

    # For upcoming events, ensure they start today
    upcoming_events = [
        e
        for e in upcoming_events
        if (
            e["start_date"] == today_date and
            (e["start_hour"] * 60 + e["start_minute"]) > current_time_in_minutes
        )
    ]

    # For current events, ensure they are happening right now
    current_events = [
        e
        for e in current_events
        if (
            not e["has_ended"] and
            (e["start_hour"] * 60 + e["start_minute"]) <= current_time_in_minutes
        )
    ]

    # If no events found for today, return empty to hide the app
    if len(current_events) == 0 and len(upcoming_events) == 0 and len(all_day_events) == 0:
        return []

    # Select which event to display (priority: current > upcoming > all-day)
    selected_event = None
    if len(current_events) > 0:
        selected_event = current_events[0]  # Show the current event
    elif len(upcoming_events) > 0:
        selected_event = upcoming_events[0]  # Show the next upcoming event
    elif len(all_day_events) > 0:
        selected_event = all_day_events[0]  # Show the all-day event

    # Display based on configuration
    if text_only:
        # Text-only display with vertical scrolling for long event titles - vertically centered
        # Determine if we need scrolling based on text length
        title = selected_event["title"]
        estimated_height = (len(title) // 10 + 1) * 6  # Rough estimate of text height
        needs_scrolling = estimated_height > 30

        if needs_scrolling:
            # Create a vertical repeating marquee with direct text
            # (no column nesting that might add extra space)
            return render.Root(
                child = render.Box(
                    width = 64,
                    height = 32,
                    color = event_bg_color,
                    child = render.Marquee(
                        width = 64,
                        height = 32,
                        scroll_direction = "vertical",
                        child = render.WrappedText(
                            content = selected_event["title"],
                            color = event_text_color,
                            font = font,
                            width = 62,
                            align = "center",
                        ),
                    ),
                ),
            )
        else:
            # If text doesn't need scrolling, just center it
            return render.Root(
                child = render.Box(
                    width = 64,
                    height = 32,
                    color = event_bg_color,
                    child = render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.WrappedText(
                                content = selected_event["title"],
                                color = event_text_color,
                                font = font,
                                width = 62,
                                align = "center",
                            ),
                        ],
                    ),
                ),
            )
    else:
        # Full display with time and event title
        # Determine if we need scrolling based on text length (rough estimate)
        title = selected_event["title"]
        estimated_height = (len(title) // 10 + 1) * 6  # Rough estimate of text height
        needs_scrolling = estimated_height > 20

        # Title display - either scrolling or static
        title_display = None
        if needs_scrolling:
            title_display = render.Marquee(
                width = 64,
                height = 22,
                scroll_direction = "vertical",
                child = render.WrappedText(
                    content = selected_event["title"],
                    color = event_text_color,
                    font = font,
                    width = 62,
                    align = "center",
                ),
            )
        else:
            title_display = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.WrappedText(
                        content = selected_event["title"],
                        color = event_text_color,
                        font = font,
                        width = 62,
                        align = "center",
                    ),
                ],
            )

        return render.Root(
            child = render.Column(
                children = [
                    # Time display with proper centering
                    render.Box(
                        width = 64,
                        height = 10,  # Increased height for better visibility
                        color = time_bg_color,
                        child = render.Padding(
                            pad = (2, 2, 2, 2),  # Even padding on all sides
                            child = render.Text(
                                content = selected_event["time_display"],
                                color = time_text_color,
                                font = font,
                            ),
                        ),
                    ),
                    # Event title - adjusted height to account for taller time display
                    render.Box(
                        width = 64,
                        height = 24,
                        color = event_bg_color,
                        child = title_display,
                    ),
                ],
                main_align = "center",
                expanded = True,
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "calendar_link",
                name = "Calendar Link",
                desc = "Paste an iCal URL (ending in .ics) from Google Calendar",
                icon = "calendar",
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "Your timezone (e.g. America/New_York)",
                icon = "clock",
                default = "America/New_York",
            ),
            schema.Toggle(
                id = "text_only",
                name = "Text Only",
                desc = "Show only the event text without time",
                icon = "textHeight",
                default = False,
            ),
            schema.Color(
                id = "time_bg_color",
                name = "Time Background Color",
                desc = "Background color for the time display",
                icon = "brush",
                default = "#1a73e8",  # Google blue
            ),
            schema.Color(
                id = "time_text_color",
                name = "Time Text Color",
                desc = "Text color for the time display",
                icon = "font",
                default = "#ffffff",  # White
            ),
            schema.Color(
                id = "event_bg_color",
                name = "Event Background Color",
                desc = "Background color for the event display",
                icon = "brush",
                default = "#000000",  # Black
            ),
            schema.Color(
                id = "event_text_color",
                name = "Event Text Color",
                desc = "Text color for the event display",
                icon = "font",
                default = "#7FFF7F",  # Light green
            ),
        ],
    )

def format_number(num):
    """Format a number with leading zero if less than 10."""
    if num < 10:
        return "0" + str(num)
    return str(num)
