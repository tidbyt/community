"""
Applet: Timer
Summary: Timer
Description: Counts down the inputted time.
Author: rwong2888
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

WIDTH = 64
HEIGHT = 32
DEFAULT_PROGRESS_HEIGHT = 1
ORANGE = "#FF3503"
GREEN = "#4AF626"
DEFAULT_HOUR = "0"
DEFAULT_MINUTE = "5"
DEFAULT_SECOND = "0"
DEFAULT_COLOR = ORANGE
DEFAULT_TEXT_COLOR = DEFAULT_COLOR
DEFAULT_PROGRESS_COLOR = DEFAULT_COLOR
DEFAULT_TIME_COLOR = DEFAULT_COLOR
DEFAULT_DISPLAY_PROGRESS = True

def get_hour(config):
    return int(config.str("hour", DEFAULT_HOUR))

def get_minute(config):
    return int(config.str("minute", DEFAULT_MINUTE))

def get_second(config):
    return int(config.str("second", DEFAULT_SECOND))

def get_seconds_from_hours(hours):
    return hours * 3600

def get_seconds_from_minutes(minutes):
    return minutes * 60

def get_refresh_rate(config):
    return 1000 if config.bool("display_seconds", True) else 60000

def get_text_color(config):
    return config.str("text_color", DEFAULT_TEXT_COLOR)

def get_progress_color(config):
    return config.str("progress_color", DEFAULT_PROGRESS_COLOR)

def get_time_color(config):
    return config.str("time_color", DEFAULT_TIME_COLOR)

def display_seconds(seconds, config):
    return config.bool("display_seconds", True) or seconds <= 60

def display_hours(seconds):
    return seconds >= 3600

def display_progress(config):
    return config.bool("display_progress", DEFAULT_DISPLAY_PROGRESS)

def leading_zero(i):
    if i < 10:
        return "0{}".format(i)
    return str(i)

def format_seconds(s, display_hour = False, display_minute = True, display_second = True):
    hours = int(math.floor(s / 3600))
    remaining = math.mod(s, 3600)
    minutes = int(math.floor(remaining / 60))
    seconds = int(math.mod(remaining, 60))
    formatted_hours = leading_zero(hours)
    formatted_minutes = leading_zero(minutes)
    formatted_seconds = leading_zero(seconds)
    t = [formatted_hours, formatted_minutes, formatted_seconds]
    if display_hour and display_minute and display_second:
        return ":".join(t)
    elif display_hour and display_minute and not display_second:
        return ":".join(t[0:1])
    elif not display_hour and display_minute and display_second:
        return ":".join(t[1:])
    elif not display_hour and display_minute and not display_second:
        return str(minutes)
    elif not display_hour and not display_minute and display_second:
        return str(seconds)
    elif display_hour and not display_minute and not display_second:
        return str(hours)
    return ":".join(t[1:])

def get_text(text, text_color):
    return render.Box(
        height = 6,
        child = render.Text(
            content = text,
            color = text_color,
        ),
    )

def get_progress(count, progress_color, height):
    progress = []
    progress_slice = []
    for _ in range(height):
        progress_slice.append(
            render.Circle(
                color = progress_color,
                diameter = 1,
            ),
        )
    for _ in range(count):
        progress.append(
            render.Column(
                children = progress_slice,
            ),
        )
    return render.Row(
        children = progress,
    )

def get_time(time, time_color):
    return render.Box(
        child = render.Text(
            content = time,
            color = time_color,
            font = "6x13",
        ),
    )

def get_frame(text, progress, time, text_color, progress_color, time_color, display_text = True, display_progress = True):
    frame = []
    text_frame = get_text(text, text_color)
    progress_frame = get_progress(progress, progress_color, DEFAULT_PROGRESS_HEIGHT)
    clock_frame = get_time(time, time_color)
    if display_text and display_progress:
        frame = render.Column(
            children = [
                text_frame,
                progress_frame,
                clock_frame,
            ],
        )
    elif display_text and not display_progress:
        frame = render.Column(
            children = [
                text_frame,
                clock_frame,
            ],
        )
    elif not display_text and not display_progress:
        frame = render.Column(
            children = [
                clock_frame,
            ],
        )
    elif not display_text and display_progress:
        frame = render.Column(
            children = [
                progress_frame,
                clock_frame,
            ],
        )
    return frame

def get_timer_animation(seconds, refresh_rate, text, text_color, progress_color, time_color, enable_hour, enable_text, enable_progress):
    frames = []
    n = 0
    for i in range(0, seconds + 1, int(refresh_rate / 1000)):
        n = int((i / seconds) * WIDTH)
        frames.append(get_frame(text, n, format_seconds(seconds - i, enable_hour), text_color, progress_color, time_color, enable_text, enable_progress))
    return render.Animation(
        children = frames,
    )

def get_timer_start(refresh_rate, text_color):
    frames = []
    seconds = 2
    text = render.Box(
        child = render.Column(
            children = [
                render.Text(
                    content = "timer".upper(),
                    color = text_color,
                    font = "6x13",
                ),
            ],
        ),
    )
    if refresh_rate == 1000:
        for _ in range(0, seconds + 1, int(refresh_rate / 1000)):
            frames.append(text)
    else:
        frames.append(text)
    return render.Animation(
        children = frames,
    )

def get_timer_end(refresh_rate, text_color):
    frames = []
    seconds = 10
    text = render.Box(
        child = render.Column(
            children = [
                render.Text(
                    content = "all".upper(),
                    color = text_color,
                ),
                render.Text(
                    content = "done!!!".upper(),
                    color = text_color,
                ),
            ],
        ),
    )
    if refresh_rate == 1000:
        for _ in range(0, seconds + 1, int(refresh_rate / 1000)):
            frames.append(text)
    else:
        frames.append(text)
    return render.Animation(
        children = frames,
    )

def get_animation(refresh_rate, config):
    sequence = []
    hour = get_seconds_from_hours(get_hour(config))
    minute = get_seconds_from_minutes(get_minute(config))
    second = get_second(config)

    total_seconds = hour + minute + second

    text_color = get_text_color(config)
    progress_color = get_progress_color(config)
    time_color = get_time_color(config)

    enable_progress = display_progress(config)
    enable_hour = display_hours(total_seconds)

    timer_animation = get_timer_animation(total_seconds, refresh_rate, " ", text_color, progress_color, time_color, enable_hour, enable_progress, enable_progress)

    timer_start = get_timer_start(refresh_rate, text_color)
    timer_end = get_timer_end(refresh_rate, text_color)

    sequence.append(timer_start)
    sequence.append(timer_animation)
    sequence.append(timer_end)

    return render.Sequence(
        children = sequence,
    )

def main(config):
    refresh_rate = get_refresh_rate(config)
    animation = get_animation(refresh_rate, config)

    return render.Root(
        delay = refresh_rate,
        show_full_animation = True,
        child = animation,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "hour",
                name = "Hours",
                default = DEFAULT_HOUR,
                desc = "Amount of hours to countdown",
                icon = "hourglass",
            ),
            schema.Text(
                id = "minute",
                name = "Minutes",
                default = DEFAULT_MINUTE,
                desc = "Amount of minutes to countdown",
                icon = "clock",
            ),
            schema.Text(
                id = "second",
                name = "Seconds",
                default = DEFAULT_SECOND,
                desc = "Amount of seconds to countdown",
                icon = "stopwatch",
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                default = DEFAULT_TEXT_COLOR,
                desc = "The color for text",
                icon = "brush",
            ),
            schema.Color(
                id = "progress_color",
                name = "Progress Color",
                default = DEFAULT_PROGRESS_COLOR,
                desc = "The color for the progress bar",
                icon = "paintbrush",
            ),
            schema.Color(
                id = "time_color",
                name = "Time Color",
                default = DEFAULT_TIME_COLOR,
                desc = "The color for the timer",
                icon = "palette",
            ),
            schema.Toggle(
                id = "display_progress",
                name = "Display Progress Bar",
                default = DEFAULT_DISPLAY_PROGRESS,
                desc = "Toggle progress bar on and off",
                icon = "palette",
            ),
            # schema.Toggle(
            #     id = "display_seconds",
            #     name = "Display Seconds",
            #     default = True,
            #     desc = "",
            #     icon = "",
            # ),
        ],
    )
