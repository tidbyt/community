load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    # Capture inputs via Tidbyt app schema
    target_time = config.get("target_time", "00:00:00")
    event_name = config.get("event_name", "Event In:")

    # Get current time
    now = time.now()

    # Parse target time
    target_parts = target_time.split(":")
    target_hour = int(target_parts[0])
    target_minute = int(target_parts[1])
    target_second = int(target_parts[2])

    # Calculate target timestamp
    target = time.time(year = now.year, month = now.month, day = now.day, hour = target_hour, minute = target_minute, second = target_second)

    # If target time is in the past, add one day
    if target < now:
        target = time.time(
            year = now.year,
            month = now.month,
            day = now.day + 1,
            hour = target_hour,
            minute = target_minute,
            second = target_second,
        )

    # Calculate time remaining
    time_remaining = target - now
    total_seconds_remaining = int(time_remaining.seconds)

    def pad_with_zero(number):
        if number < 10:
            return "0" + str(number)
        return str(number)

    # Render display
    hours = total_seconds_remaining // 3600
    minutes = (total_seconds_remaining % 3600) // 60
    seconds = total_seconds_remaining % 60
    countdown_text = pad_with_zero(hours) + ":" + pad_with_zero(minutes) + ":" + pad_with_zero(seconds)

    return render.Root(
        delay = 1000,  # Update every 1000ms (1 second)
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(event_name, font = "5x8"),
                    render.Text(countdown_text, font = "6x13"),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "event_name",
                name = "Event Name",
                desc = "Name of the event",
                icon = "font",
            ),
            schema.Text(
                id = "target_time",
                name = "Target Time",
                desc = "Time of the event (HH:MM:SS)",
                icon = "clock",
            ),
        ],
    )
