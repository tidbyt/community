"""
Applet: Year Progress
Summary: Year progress bar
desc: The only progress bar you wish was slower.
Author: chrisbateman
"""

load("animation.star", "animation")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_COLOR = "#47a"

def main(config):
    progress_bar_color = config.get("color", DEFAULT_COLOR)
    milestones_only = config.bool("milestones_only", False)
    display_decimal = not milestones_only

    timezone = config.get("timezone", "America/New_York")
    now = time.now().in_location(timezone)

    yearstart = time.time(location = timezone, year = now.year, month = 1, day = 1, hour = 0, minute = 0, second = 0).unix
    yearend = time.time(location = timezone, year = now.year, month = 12, day = 31, hour = 23, minute = 59, second = 59).unix
    year_progress = (now.unix - yearstart) / (yearend - yearstart)

    progress_box_width = 62
    progress_bar_width = min(int(math.round(year_progress * progress_box_width)), progress_box_width - 1)
    str_format = "#,###.#" if display_decimal == True else "#,###."
    year_progress_str = humanize.float(str_format, min(year_progress * 100, 99.9 if display_decimal == True else 99.0))

    year = now.year

    if year_progress < (1 / 365 / 24):  # 60 minutes to celebrate
        year -= 1
        year_progress_str = "100"
        progress_bar_width = progress_box_width
    elif milestones_only:
        first_decimal = str((year_progress * 100) % 1)[2]
        if first_decimal != "0" and first_decimal != "1":
            # don't display the app
            return []

    progress_bar = None

    if progress_bar_width > 0:
        progress_bar = render.Box(width = progress_bar_width, color = progress_bar_color)

    pulseDuration = 3.333 + (30 * year_progress) - (13.333 * math.pow(year_progress, 2))

    pulseAnimation = None
    if pulseDuration > 8.5:
        pulseAnimation = render.Box(
            animation.Transformation(
                child = render.Box(
                    render.Box(
                        render.Box(width = 1, height = 10, color = "#ffffff11"),
                        width = 3,
                        height = 10,
                        color = "#ffffff22",
                    ),
                    width = 7,
                    height = 10,
                    color = "#ffffff22",
                ),
                duration = int(pulseDuration),
                delay = 20,
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [animation.Translate(-7, 0)],
                    ),
                    animation.Keyframe(
                        percentage = 1,
                        transforms = [animation.Translate(progress_bar_width, 0)],
                    ),
                ],
            ),
            width = progress_bar_width,
        )

    return render.Root(
        render.Column(
            expanded = True,
            children = [
                render.Box(
                    render.Text(str(year), font = "6x13"),
                    height = 11,
                ),
                render.Box(height = 1),
                render.Box(
                    render.Box(
                        render.Stack(
                            children = [
                                render.Row(expanded = True, children = [progress_bar]),
                                pulseAnimation,
                            ],
                        ),
                        width = progress_box_width,
                        height = 10,
                        color = "#222",
                    ),
                    padding = 1,
                    height = 12,
                    color = "#ccc",
                ),
                render.Box(height = 2),
                render.Box(
                    render.Text("%s%% complete" % (year_progress_str), font = "tom-thumb"),
                    height = 7,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color",
                name = "Progress bar color",
                desc = "The progress bar fill color",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
            schema.Toggle(
                id = "milestones_only",
                name = "Display only on milestone days",
                desc = "Every 3-4 days when we hit 1%, 2%, etc.",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )
