"""
Applet: Pomodoro
Summary: Pomodoro Timer
Description: A time management tool to break work into intervals.
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
DEFAULT_POMODORO = "25"
DEFAULT_SHORT_BREAK = "5"
DEFAULT_LONG_BREAK = "15"
DEFAULT_LONG_BREAK_INTERVAL = "4"
DEFAULT_POMODORO_TEXT = "focus".upper()
DEFAULT_SHORT_BREAK_TEXT = "break".upper()
DEFAULT_LONG_BREAK_TEXT = DEFAULT_SHORT_BREAK_TEXT
DEFAULT_COLOR = ORANGE
DEFAULT_TEXT_COLOR = DEFAULT_COLOR
DEFAULT_PROGRESS_COLOR = DEFAULT_COLOR
DEFAULT_TIME_COLOR = DEFAULT_COLOR

def get_pomodoro(config):
    return int(config.str("pomodoro", DEFAULT_POMODORO))

def get_short_break(config):
    return int(config.str("short_break", DEFAULT_SHORT_BREAK))

def get_long_break(config):
    return int(config.str("long_break", DEFAULT_LONG_BREAK))

def get_long_break_interval(config):
    return int(config.str("long_break_interval", DEFAULT_LONG_BREAK_INTERVAL))

def get_seconds(minutes):
    return minutes * 60

def get_refresh_rate(config):
    return 1000 if config.bool("display_seconds", True) else 60000

def get_pomodoro_text(config):
    return config.str("pomodoro_text", DEFAULT_POMODORO_TEXT)

def get_short_break_text(config):
    return config.str("short_break_text", DEFAULT_SHORT_BREAK_TEXT)

def get_long_break_text(config):
    return config.str("long_break_text", DEFAULT_LONG_BREAK_TEXT)

def get_text_color(config):
    return config.str("text_color", DEFAULT_TEXT_COLOR)

def get_progress_color(config):
    return config.str("progress_color", DEFAULT_PROGRESS_COLOR)

def get_time_color(config):
    return config.str("time_color", DEFAULT_TIME_COLOR)

def display_seconds(seconds, config):
    return config.bool("display_seconds", True) or seconds <= 60

def display_hours(minutes):
    return minutes >= 60

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
        height = 10,
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
            font = "10x20",
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

def get_timer_animation(seconds, refresh_rate, text, text_color, progress_color, time_color):
    frames = []
    n = 0
    for i in range(0, seconds + 1, int(refresh_rate / 1000)):
        n = int((i / seconds) * WIDTH)
        frames.append(get_frame(text, n, format_seconds(seconds - i), text_color, progress_color, time_color))
    return render.Animation(
        children = frames,
    )

def get_intermission_start(refresh_rate, text_color):
    frames = []
    seconds = 5
    text = render.Box(
        child = render.Column(
            children = [
                render.Text(
                    content = "time".upper(),
                    color = text_color,
                ),
                render.Text(
                    content = "for a".upper(),
                    color = text_color,
                ),
                render.Text(
                    content = "break!!!".upper(),
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

def get_intermission_end(refresh_rate, text_color):
    frames = []
    seconds = 5
    text = render.Box(
        child = render.Column(
            children = [
                render.Text(
                    content = "time".upper(),
                    color = text_color,
                ),
                render.Text(
                    content = "to".upper(),
                    color = text_color,
                ),
                render.Text(
                    content = "focus!!!".upper(),
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

def get_pomodori_start(refresh_rate, text_color):
    frames = []
    seconds = 2
    text = render.Box(
        child = render.Column(
            children = [
                render.Text(
                    content = "pomodoro".upper(),
                    color = text_color,
                    font = "6x13",
                ),
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

def get_pomodori_end(refresh_rate, text_color):
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
    pomodoro = get_seconds(get_pomodoro(config))
    pomodoro_text = get_pomodoro_text(config)

    short_break = get_seconds(get_short_break(config))
    short_break_text = get_short_break_text(config)

    long_break = get_seconds(get_long_break(config))
    long_break_text = get_long_break_text(config)

    text_color = get_text_color(config)
    progress_color = get_progress_color(config)
    time_color = get_time_color(config)

    long_break_interval = get_long_break_interval(config)

    pomodoro_animation = get_timer_animation(pomodoro, refresh_rate, pomodoro_text, text_color, progress_color, time_color)
    short_break_animation = get_timer_animation(short_break, refresh_rate, short_break_text, text_color, progress_color, time_color)
    long_break_animation = get_timer_animation(long_break, refresh_rate, long_break_text, text_color, progress_color, time_color)

    intermission_start = get_intermission_start(refresh_rate, text_color)
    intermission_end = get_intermission_end(refresh_rate, text_color)
    pomodori_start = get_pomodori_start(refresh_rate, text_color)
    pomodori_end = get_pomodori_end(refresh_rate, text_color)

    for i in range(long_break_interval):
        if i == 0:
            sequence.append(pomodori_start)
        sequence.append(pomodoro_animation)
        if i < long_break_interval - 1:
            sequence.append(intermission_start)
            sequence.append(short_break_animation)
            sequence.append(intermission_end)
        else:
            sequence.append(intermission_start)
            sequence.append(long_break_animation)
            sequence.append(pomodori_end)

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
                id = "pomodoro",
                name = "Pomodoro",
                default = DEFAULT_POMODORO,
                desc = "Duration in minutes to focus",
                icon = "appleWhole",
            ),
            schema.Text(
                id = "short_break",
                name = "Short Break",
                default = DEFAULT_SHORT_BREAK,
                desc = "Duration in minutes for a short break",
                icon = "stopwatch",
            ),
            schema.Text(
                id = "long_break",
                name = "Long Break",
                default = DEFAULT_LONG_BREAK,
                desc = "Duration in minutes for a long break",
                icon = "clock",
            ),
            schema.Text(
                id = "long_break_interval",
                name = "Long Break Interval",
                default = DEFAULT_LONG_BREAK_INTERVAL,
                desc = "Amount of pomodoros before a long break",
                icon = "hourglassEnd",
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
            # schema.Toggle(
            #     id = "display_seconds",
            #     name = "Display Seconds",
            #     default = True,
            #     desc = "",
            #     icon = "",
            # ),
        ],
    )
