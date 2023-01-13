"""
Applet: Movie Night
Summary: Marquee for a Movie Night
Description: Displays a marquee for a movie title along with a countdown to the movie night.
Author: Piper Gillman
"""

load("encoding/base64.star", "base64")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CAMERA_GIF = base64.decode("""
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
""")

DOTTED_LINE = base64.decode("""
R0lGODlhQAABAPEAAAAAAP///yZFySZFySH5BAEAAAIALAAAAABAAAEAAAIJDIynyesNn4wFADs=
""")

DEFAULT_TITLE = "Coming Soon"

def main(config):
    # current time
    now = time.now()

    # default movie start time
    showTime = now

    # user config for movie start time
    userTime = config.get("time")
    if userTime:
        showTime = time.parse_time(userTime)

    # time duration difference
    timeDiff = showTime - now

    # user config for display title
    showTitle = config.get("title") or DEFAULT_TITLE

    # default time font
    timeFont = "CG-pixel-4x5-mono"

    # colors
    headlineColor = "#a42413"
    titleColor = "#FFB319"
    timeDaysColor = "#636363"
    timeHoursColor = "#9f9f9f"
    timeMinutesColor = "#fff"
    nowPlayingColor = headlineColor

    # Countdown Display
    if timeDiff.hours >= 24:
        # if over 24 hrs away, set a day count
        # get formatted time difference
        timeLeft = humanize.relative_time(showTime, now)
        timeColor = timeDaysColor

    elif timeDiff.minutes >= 60:
        # otherwise show hours and minutes left
        timeLeft = str(int(timeDiff.hours)) + "H " + str(int(timeDiff.minutes % 60)) + "M"
        timeColor = timeHoursColor

    elif timeDiff.minutes > 0:
        # show only minutes if less than an hour left
        timeLeft = str(int(timeDiff.minutes % 60)) + "M"
        timeColor = timeMinutesColor

    else:
        # show message when past movie start time
        timeLeft = "Showtime!"

        # update font to preserve space
        timeFont = "CG-pixel-3x5-mono"
        timeColor = nowPlayingColor

    return render.Root(
        child = render.Column(
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Image(
                    src = DOTTED_LINE,
                    width = 64,
                ),
                render.Padding(
                    child = render.Text(
                        content = "MOVIE NIGHT",
                        font = "CG-pixel-4x5-mono",
                        color = headlineColor,
                    ),
                    pad = (0, 1, 0, 1),
                ),
                render.Image(
                    src = DOTTED_LINE,
                    width = 64,
                ),
                render.Padding(
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = showTitle,
                            font = "Dina_r400-6",
                            color = titleColor,
                        ),
                        align = "center",
                    ),
                    pad = (0, 1, 0, 2),
                ),
                render.Row(
                    cross_align = "center",
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Text(
                            content = timeLeft,
                            font = timeFont,
                            color = timeColor,
                        ),
                        render.Image(
                            src = CAMERA_GIF,
                            width = 16,
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
                id = "title",
                name = "Movie Title",
                desc = "The show name to display",
                icon = "film",
            ),
            schema.DateTime(
                id = "time",
                name = "Show Time",
                desc = "The scheduled start time",
                icon = "clock",
            ),
        ],
    )
