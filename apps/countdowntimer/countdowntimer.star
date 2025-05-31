load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    # Default to 7 days from now
    default_deadline = time.now() + time.parse_duration("168h")  # 7 days = 168 hours
    default_deadline_str = default_deadline.format("2006-01-02T15:04:05Z")

    deadline_str = config.get("deadline", default_deadline_str)
    title = config.get("title", "Countdown")
    granularity = config.get("granularity", "days")
    dot_color = config.get("dot_color", "#00FF00")
    title_color = config.get("title_color", "#FFFFFF")
    time_color = config.get("time_color", "#FFFF00")
    date_color = config.get("date_color", "#888888")

    # Row visibility settings
    show_title = config.bool("show_title", True)
    show_time = config.bool("show_time", True)
    show_dots = config.bool("show_dots", True)
    show_date = config.bool("show_date", True)

    # Parse deadline with timezone
    if not deadline_str.endswith("Z") and not "+" in deadline_str and not "-" in deadline_str[-6:]:
        deadline_str = deadline_str + "Z"  # Add UTC timezone if missing

    deadline = time.parse_time(deadline_str)

    # Create animation frames for real-time countdown and effects
    frames = []
    for i in range(60):  # 60 frames for 1 minute of animation
        # Calculate current time for this frame (simulate time passing)
        frame_time = time.now() + time.parse_duration("%ds" % (i // 2))  # Update every 2 frames
        frames.append(render_frame(deadline, title, granularity, dot_color, title_color, time_color, date_color, show_title, show_time, show_dots, show_date, i, frame_time))

    return render.Root(
        delay = 500,  # Update every 500ms for smoother animation
        child = render.Animation(
            children = frames,
        ),
    )

def render_frame(deadline, title, granularity, dot_color, title_color, time_color, date_color, show_title, show_time, show_dots, show_date, frame_num, current_time):
    # Use the passed current_time instead of time.now()
    now = current_time

    # Calculate time difference
    diff = deadline - now
    total_seconds = int(diff.seconds)

    if total_seconds <= 0:
        # Deadline has passed
        return render.Box(
            color = "#FF0000",
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = title,
                        font = "tom-thumb",
                        color = "#FFFFFF",
                    ),
                    render.Text(
                        content = "TIME'S UP!",
                        font = "6x13",
                        color = "#FFFFFF",
                    ),
                ],
            ),
        )

    # Calculate time units
    days = total_seconds // 86400
    hours = (total_seconds % 86400) // 3600
    minutes = (total_seconds % 3600) // 60
    seconds = total_seconds % 60

    # Create time display
    time_text = ""
    if days > 0:
        h_str = "%s" % hours
        m_str = "%s" % minutes
        s_str = "%s" % seconds

        if hours < 10:
            h_str = "0" + h_str
        if minutes < 10:
            m_str = "0" + m_str
        if seconds < 10:
            s_str = "0" + s_str

        time_text = "%s" % days + "d " + h_str + ":" + m_str + ":" + s_str
    else:
        # Format hours:minutes:seconds
        h_str = "%s" % hours
        m_str = "%s" % minutes
        s_str = "%s" % seconds

        if hours < 10:
            h_str = "0" + h_str
        if minutes < 10:
            m_str = "0" + m_str
        if seconds < 10:
            s_str = "0" + s_str

        time_text = h_str + ":" + m_str + ":" + s_str

    # Calculate dots based on granularity
    dot_count = 0
    unit_label = ""

    if granularity == "days":
        # Dots should exactly match the days shown in countdown display
        if days > 0:
            dot_count = int(days)  # Exact match with display
        else:
            dot_count = 1  # If less than 1 day, show 1 dot
        unit_label = "D"
    elif granularity == "weeks":
        # Dots should match weeks remaining
        weeks = days // 7
        if days % 7 > 0:
            weeks = weeks + 1
        dot_count = int(weeks)
        unit_label = "W"
    elif granularity == "hours":
        # Dots should match hours remaining
        dot_count = int((days * 24) + hours)
        if minutes > 0 or seconds > 0:
            dot_count = dot_count + 1
        unit_label = "H"
    elif granularity == "minutes":
        # Dots should match minutes remaining
        total_minutes = (days * 24 * 60) + (hours * 60) + minutes
        if seconds > 0:
            total_minutes = total_minutes + 1
        dot_count = int(min(total_minutes, 300))
        unit_label = "M"

    # Limit dots to what can fit on screen
    max_dots = 400
    if dot_count > max_dots:
        dot_count = max_dots
        unit_label = unit_label + "+"

    # Filling animation - dots progressively fill up then unfill
    fill_speed = 2  # How fast the filling happens
    cycle_length = dot_count * 2  # Full cycle: fill up + unfill
    fill_position = (frame_num * fill_speed) % cycle_length

    # Use the user's selected dot color
    current_wave_color = dot_color

    # Keep text colors consistent
    final_title_color = title_color
    final_time_color = time_color

    # Format deadline date (shorter format)
    deadline_formatted = deadline.format("Jan 2")

    # Just show the target date
    description = deadline_formatted

    # Build children list based on visibility settings
    children = []

    # Count visible rows to determine font sizes
    visible_rows = 0
    if show_title:
        visible_rows += 1
    if show_time:
        visible_rows += 1
    if show_dots:
        visible_rows += 1
    if show_date:
        visible_rows += 1

    # Choose appropriate fonts based on visible rows
    title_font = "CG-pixel-3x5-mono"
    time_font = "tom-thumb"
    date_font = "CG-pixel-3x5-mono"

    # Adjust fonts for better space usage when fewer elements
    # Time should be the most prominent when space allows
    if visible_rows == 1:
        # Single element - use large font
        if show_time:
            time_font = "6x13"  # Biggest font for time
        else:
            title_font = "5x8"
            date_font = "5x8"
    elif visible_rows == 2:
        # Two elements - prioritize time
        if show_time:
            time_font = "6x13"  # Big font for time
            title_font = "tom-thumb"  # Smaller for other elements
            date_font = "tom-thumb"
        else:
            # No time shown, use medium fonts
            title_font = "5x8"
            date_font = "5x8"
    elif visible_rows == 3:
        # Three elements - time still prominent
        if show_time:
            time_font = "5x8"  # Medium-large for time
            title_font = "tom-thumb"  # Compact for others
            date_font = "tom-thumb"
        else:
            # No time shown
            title_font = "5x8"
            date_font = "tom-thumb"

    # Add visible elements
    if show_title:
        # Use WrappedText for title to prevent overflow
        if visible_rows <= 2:
            children.append(render.WrappedText(
                content = title,
                font = title_font,
                color = final_title_color,
                width = 64,
                align = "center",
            ))
        else:
            children.append(render.Text(
                content = title,
                font = title_font,
                color = final_title_color,
            ))

    if show_time:
        # Check if time text might overflow with current font
        if time_font == "6x13" and len(time_text) > 9:
            # Use smaller font for longer time strings
            time_font = "5x8"

        # Center the time text
        children.append(render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(
                    content = time_text,
                    font = time_font,
                    color = final_time_color,
                ),
            ],
        ))

    if show_dots:
        # Center the dot grid
        children.append(render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render_dot_grid(dot_count, current_wave_color, fill_position),
            ],
        ))

    if show_date:
        # Center the date text
        children.append(render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(
                    content = description,
                    font = date_font,
                    color = date_color,
                ),
            ],
        ))

    # Return empty box if no elements are visible
    if len(children) == 0:
        return render.Box(
            width = 64,
            height = 32,
            color = "#000000",
        )

    return render.Column(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = children,
    )

def get_dimmed_color(color):
    """Get a dimmed version of the given color"""
    if color == "#FF0000":
        return "#880000"
    elif color == "#FFFF00":
        return "#888800"
    elif color == "#00FF00":
        return "#008800"
    elif color == "#00FFFF":
        return "#008888"
    elif color == "#0000FF" or color == "#0088FF":
        return "#000088"
    elif color == "#FF00FF":
        return "#880088"
    elif color == "#FF8800":
        return "#884400"
    elif color == "#FF88FF":
        return "#884488"
    elif color == "#8800FF":
        return "#440088"
    elif color == "#FFFFFF":
        return "#888888"
    else:
        return "#888888"

def get_dot_fill_color(dot_index, color, fill_position, total_dots):
    """Get the color for a dot based on filling animation"""
    if fill_position < total_dots:
        # Filling phase - dots progressively light up (left to right)
        if dot_index <= fill_position:
            return color  # Full color for filled dots
        else:
            return get_dimmed_color(color)  # Dimmed for unfilled dots
    else:
        # Unfilling phase - dots progressively dim down (right to left)
        unfill_progress = fill_position - total_dots
        rightmost_lit_dot = total_dots - 1 - unfill_progress

        if dot_index <= rightmost_lit_dot:
            return color  # Full color for still filled dots
        else:
            return get_dimmed_color(color)  # Dimmed for unfilled dots

def render_dot_grid(count, color, fill_position = 0):
    if count == 0:
        return render.Box(width = 60, height = 4)

    # Single row for 1-2 dots
    if count <= 2:
        dots_with_spacing = []
        for i in range(count):
            dots_with_spacing.append(render.Box(
                width = 2,
                height = 2,
                color = color,
            ))
            if i < count - 1:
                dots_with_spacing.append(render.Box(width = 1, height = 1))

        return render.Row(
            main_align = "center",
            children = dots_with_spacing,
        )

    # Two rows for 3+ dots
    first_row_count = (count + 1) // 2

    # Build first row with filling animation
    first_row = []
    for i in range(first_row_count):
        dot_color_wave = get_dot_fill_color(i, color, fill_position, count)

        first_row.append(render.Box(
            width = 2,
            height = 2,
            color = dot_color_wave,
        ))
        if i < first_row_count - 1:
            first_row.append(render.Box(width = 1, height = 1))

    # Build second row with continuing filling animation
    second_row = []
    remaining_dots = count - first_row_count
    for i in range(remaining_dots):
        # Calculate overall dot index for this second row dot
        dot_index_overall = first_row_count + i
        dot_color_wave = get_dot_fill_color(dot_index_overall, color, fill_position, count)

        second_row.append(render.Box(
            width = 2,
            height = 2,
            color = dot_color_wave,
        ))
        if i < remaining_dots - 1:
            second_row.append(render.Box(width = 1, height = 1))

    return render.Column(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Row(
                main_align = "center",
                children = first_row,
            ),
            render.Box(height = 2),  # Vertical spacing between rows
            render.Row(
                main_align = "center",
                children = second_row,
            ),
        ],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Name of the countdown",
                icon = "heading",
                default = "Countdown",
            ),
            schema.DateTime(
                id = "deadline",
                name = "Deadline",
                desc = "Date and time to count down to",
                icon = "calendar",
            ),
            schema.Dropdown(
                id = "granularity",
                name = "Dot Granularity",
                desc = "What each dot represents",
                icon = "circle",
                default = "days",
                options = [
                    schema.Option(
                        display = "Days",
                        value = "days",
                    ),
                    schema.Option(
                        display = "Weeks",
                        value = "weeks",
                    ),
                    schema.Option(
                        display = "Hours",
                        value = "hours",
                    ),
                    schema.Option(
                        display = "Minutes",
                        value = "minutes",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "dot_color",
                name = "Dot Color",
                desc = "Color of the countdown dots",
                icon = "palette",
                default = "#00FF00",
                options = [
                    schema.Option(
                        display = "Green",
                        value = "#00FF00",
                    ),
                    schema.Option(
                        display = "Red",
                        value = "#FF0000",
                    ),
                    schema.Option(
                        display = "Blue",
                        value = "#0088FF",
                    ),
                    schema.Option(
                        display = "Cyan",
                        value = "#00FFFF",
                    ),
                    schema.Option(
                        display = "Magenta",
                        value = "#FF00FF",
                    ),
                    schema.Option(
                        display = "Yellow",
                        value = "#FFFF00",
                    ),
                    schema.Option(
                        display = "Orange",
                        value = "#FF8800",
                    ),
                    schema.Option(
                        display = "Pink",
                        value = "#FF88FF",
                    ),
                    schema.Option(
                        display = "Purple",
                        value = "#8800FF",
                    ),
                    schema.Option(
                        display = "White",
                        value = "#FFFFFF",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "title_color",
                name = "Title Color",
                desc = "Color of the countdown title",
                icon = "heading",
                default = "#FFFFFF",
                options = [
                    schema.Option(
                        display = "White",
                        value = "#FFFFFF",
                    ),
                    schema.Option(
                        display = "Yellow",
                        value = "#FFFF00",
                    ),
                    schema.Option(
                        display = "Cyan",
                        value = "#00FFFF",
                    ),
                    schema.Option(
                        display = "Green",
                        value = "#00FF00",
                    ),
                    schema.Option(
                        display = "Red",
                        value = "#FF0000",
                    ),
                    schema.Option(
                        display = "Blue",
                        value = "#0088FF",
                    ),
                    schema.Option(
                        display = "Magenta",
                        value = "#FF00FF",
                    ),
                    schema.Option(
                        display = "Orange",
                        value = "#FF8800",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "time_color",
                name = "Time Color",
                desc = "Color of the countdown numbers",
                icon = "clock",
                default = "#FFFF00",
                options = [
                    schema.Option(
                        display = "Yellow",
                        value = "#FFFF00",
                    ),
                    schema.Option(
                        display = "White",
                        value = "#FFFFFF",
                    ),
                    schema.Option(
                        display = "Cyan",
                        value = "#00FFFF",
                    ),
                    schema.Option(
                        display = "Green",
                        value = "#00FF00",
                    ),
                    schema.Option(
                        display = "Red",
                        value = "#FF0000",
                    ),
                    schema.Option(
                        display = "Blue",
                        value = "#0088FF",
                    ),
                    schema.Option(
                        display = "Magenta",
                        value = "#FF00FF",
                    ),
                    schema.Option(
                        display = "Orange",
                        value = "#FF8800",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "date_color",
                name = "Date Color",
                desc = "Color of the target date text",
                icon = "calendarDay",
                default = "#888888",
                options = [
                    schema.Option(
                        display = "Gray",
                        value = "#888888",
                    ),
                    schema.Option(
                        display = "White",
                        value = "#FFFFFF",
                    ),
                    schema.Option(
                        display = "Yellow",
                        value = "#FFFF00",
                    ),
                    schema.Option(
                        display = "Cyan",
                        value = "#00FFFF",
                    ),
                    schema.Option(
                        display = "Green",
                        value = "#00FF00",
                    ),
                    schema.Option(
                        display = "Red",
                        value = "#FF0000",
                    ),
                    schema.Option(
                        display = "Blue",
                        value = "#0088FF",
                    ),
                    schema.Option(
                        display = "Magenta",
                        value = "#FF00FF",
                    ),
                    schema.Option(
                        display = "Orange",
                        value = "#FF8800",
                    ),
                ],
            ),
            schema.Toggle(
                id = "show_title",
                name = "Show Title",
                desc = "Display the countdown title",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "show_time",
                name = "Show Time",
                desc = "Display the countdown time",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "show_dots",
                name = "Show Dots",
                desc = "Display the dot grid animation",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "show_date",
                name = "Show Date",
                desc = "Display the target date",
                icon = "eye",
                default = True,
            ),
        ],
    )
