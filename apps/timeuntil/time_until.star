"""
Applet: Time Until
Summary: Track important events
Description: Got an important event coming up? Time Until keeps you on track!
Author: JeffLac (Recreation of Tidbyt Original)
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("humanize.star", "humanize")

def get_time_components(duration_seconds):
    """Calculate the two largest time components from seconds."""
    # Convert to absolute value for calculation
    abs_seconds = abs(duration_seconds)
    
    components = []
    
    # Calculate days
    days = abs_seconds // 86400
    if days > 0:
        components.append((days, "day" if days == 1 else "days"))
        abs_seconds %= 86400
    
    # Calculate hours
    hours = abs_seconds // 3600
    if hours > 0:
        components.append((hours, "hour" if hours == 1 else "hours"))
        abs_seconds %= 3600
    
    # Calculate minutes
    minutes = abs_seconds // 60
    if minutes > 0:
        components.append((minutes, "minute" if minutes == 1 else "minutes"))
    
    # Return the two largest components
    return components[:2]

def main(config):

    timezone = config.get("timezone") or "America/New_York"
    # Default values
    DEFAULT_EVENT = "HELLO WORLD"  # Changed to uppercase
    DEFAULT_TIME = time.now().in_location(timezone).format("2006-01-02T15:04:05Z07:00")

    # Get configuration values and convert event name to uppercase
    event_name = config.str("event_name", DEFAULT_EVENT).upper()
    event_time = time.parse_time(config.str("event_time", DEFAULT_TIME))
    now = time.now().in_location("America/New_York")
    
    # Calculate time difference in seconds
    time_diff = event_time.unix - now.unix
    
    # Get the two largest time components
    components = get_time_components(time_diff)
    
    # Handle case when no components (very small time difference)
    if not components:
        components = [(0, "mins")]
    
    
    # Helper function to format time component
    def format_component(comp):
        value, unit = comp
        # Replace "minutes" with "mins"
        if unit in ["minute", "minutes"]:
            unit = "min" if value == 1 else "mins"
        return "%d %s" % (value, unit)
    
    cellone = ""
    celltwo = ""
    cellthree = ""
    cellfour = ""
    lfWidth = 40
    rtWidth = 40

    # Check if event is in the future
    is_future = time_diff > 0

    if is_future:
        # Future event formatting
        cellone = "in"
        celltwo = format_component(components[0])
        cellthree = ""
        cellfour = format_component(components[1]) if len(components) > 1 else ""
        lfWidth = 20
        rtWidth = 40
    else:
        # Past event formatting
        cellone = format_component(components[0])
        celltwo = ""
        cellthree = format_component(components[1]) if len(components) > 1 else ""
        cellfour = "ago"
        lfWidth = 40
        rtWidth = 40

    return render.Root(
        child=render.Column(
            expanded=True,
            children=[
                # Event name with marquee in yellow/orange
                render.Marquee(
                    width=64,
                    child=render.Text(
                        event_name,
                        color="#ffa500",
                    ),
                ),
                # Light purple separator line with 1px padding on each side
                render.Row(
                    children=[
                        render.Box(width=1, height=1),  # Left padding
                        render.Box(width=62, height=1, color="#b156e3"),  # Separator
                        render.Box(width=1, height=1),  # Right padding
                    ],
                ),
                # Time display grid
                render.Column(
                    children=[
                        # Top row - fixed height of 10 pixels (half of 20)
                        render.Box(
                            height=10,
                            child=render.Row(
                                expanded=True,
                                main_align="space_between",
                                children=[
                                    # Top left cell
                                    render.Box(
                                        width=lfWidth,
                                        child=render.Row(
                                            expanded=True,
                                            main_align="end",
                                            children=[
                                                render.Box(width=1, height=1),  # Left padding
                                                render.Text(cellone, color="#fff"),
                                                render.Box(width=1, height=1),  # right padding
                                                ]
                                        ),
                                    ),
                                    # Top right cell
                                    render.Box(
                                        width=rtWidth,
                                        child=render.Row(
                                            expanded=True,
                                            main_align="start",
                                            children=[
                                                render.Box(width=1, height=1),  # Left padding
                                                render.Text(celltwo, color="#fff"),
                                                render.Box(width=1, height=1),  # right padding
                                                ]
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        # Bottom row - fixed height of 10 pixels
                        render.Box(
                            height=10,
                            child=render.Row(
                                expanded=True,
                                main_align="space_between",
                                children=[
                                    # Bottom left cell
                                    render.Box(
                                        width=lfWidth,
                                        child=render.Row(
                                            expanded=True,
                                            main_align="end",
                                            children=[
                                                render.Box(width=1, height=1),  # Left padding
                                                render.Text(cellthree, color="#fff"),
                                                render.Box(width=1, height=1),  # right padding
                                                ]
                                        ),
                                    ),
                                    # Bottom right cell
                                    render.Box(
                                        width=rtWidth,
                                        child=render.Row(
                                            expanded=True,
                                            main_align="start",
                                            children=[
                                                render.Box(width=1, height=1),  # Left padding
                                                render.Text(cellfour, color="#fff"),
                                                render.Box(width=1, height=1),  # right padding
                                                ]
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )


def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "event_name",
                name = "Event Name",
                desc = "Name of the event to track",
                icon = "gear",
            ),
            schema.DateTime(
                id = "event_time",
                name = "Event Time",
                desc = "Date and time of the event",
                icon = "calendar",
            ),
        ],
    )