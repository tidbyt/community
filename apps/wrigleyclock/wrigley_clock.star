"""
Applet: Wrigley Clock
Summary: Wrigley Scoreboard Clock
Description: Clock that shows the current time as seen on the old Wrigley Field scoreboard.
Author: Garrett W
"""

load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

def main(config):
    timezone = config.get("$tz") or "America/Chicago"
    now = time.now().in_location(timezone)

    dev_width = 64
    dev_height = 32

    # Clock radius
    radius = min(dev_width, dev_height) // 2 - 1

    # Get current time
    hour = now.hour % 12
    minute = now.minute

    # Calculate angles (in radians)
    pi = math.pi
    hour_angle = (pi / 2) - (2 * pi) * ((hour + minute / 60.0) / 12.0)
    minute_angle = (pi / 2) - (2 * pi) * (minute / 60.0)

    # Hand lengths
    hour_len = 0.6
    min_len = 1
    back_len = -0.2

    hour_hand = render.Plot(
        x_lim = (-1, 1),
        y_lim = (-1, 1),
        width = int(radius * 2.0),
        height = int(radius * 2.0),
        data = [
            (math.cos(hour_angle) * hour_len, math.sin(hour_angle) * hour_len),
            (math.cos(hour_angle) * back_len, math.sin(hour_angle) * back_len),
        ],
        color = "#FFFFFF",
    )

    minute_hand = render.Plot(
        x_lim = (-1, 1),
        y_lim = (-1, 1),
        width = int(radius * 2.0),
        height = int(radius * 2.0),
        data = [
            (math.cos(minute_angle) * min_len, math.sin(minute_angle) * min_len),
            (math.cos(minute_angle) * back_len, math.sin(minute_angle) * back_len),
        ],
        color = "#FFFFFF",
    )

    lower_scoreboard = render.Plot(
        x_lim = (-31, 32),
        y_lim = (0, 31),
        width = dev_width,
        height = dev_height,
        data = [
            (-31, 0),
            (-31, 3),
            (-31, 4),
            (32, 4),
            (32, 3),
            (32, 0),
        ],
        color = "#008800",
        fill = True,
        fill_color = "#008800",
    )

    # Background Design
    if now.hour >= 20:
        c = "000"
        starcolor = "CCC"
        cloudcolor = "000"
    elif now.hour <= 6:
        c = "000"
        starcolor = "CCC"
        cloudcolor = "000"
    else:
        c = "07F"
        starcolor = "07F"
        cloudcolor = "CCC"

    return render.Root(
        delay = 500,
        child = render.Box(
            width = 64,
            height = 32,
            color = c,
            child = render.Stack(
                children = [

                    # Stars in Background
                    render.Plot(
                        data = [
                            (-25, 12),
                            (-25, 12),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-20, 0),
                            (-20, 0),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-28, 2),
                            (-28, 2),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-22, -8),
                            (-22, -8),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-26, -6),
                            (-26, -6),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-19, 5),
                            (-19, 5),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-20, 13),
                            (-20, 13),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-30, 15),
                            (-30, 15),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-29, 9),
                            (-29, 9),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-23, 7),
                            (-23, 7),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-29, -7),
                            (-29, -7),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-14, 14),
                            (-14, 14),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (22, 1),
                            (22, 1),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (12, 15),
                            (12, 15),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (30, 8),
                            (30, 8),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (27, 13),
                            (27, 13),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (17, -7),
                            (17, -7),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (27, -8),
                            (27, -8),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (26, 4),
                            (26, 4),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (29, -4),
                            (29, -4),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (23, -4),
                            (23, -4),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (19, 7),
                            (19, 7),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (20, 12),
                            (20, 12),
                        ],
                        width = 64,
                        height = 32,
                        color = starcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),

                    # Clouds in Background
                    render.Plot(
                        data = [
                            (-27, 6),
                            (-24, 6),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-29, 5),
                            (-22, 5),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-30, 4),
                            (-20, 4),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-20, 12),
                            (-18, 12),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-22, 11),
                            (-17, 11),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-24, 10),
                            (-16, 10),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-25, -2),
                            (-21, -2),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-26, -3),
                            (-20, -3),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (-27, -4),
                            (-19, -4),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (25, 2),
                            (27, 2),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (24, 1),
                            (29, 1),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (22, 0),
                            (31, 0),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (22, 11),
                            (23, 11),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (20, 10),
                            (24, 10),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (19, 9),
                            (25, 9),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (18, -7),
                            (20, -7),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (17, -8),
                            (22, -8),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    render.Plot(
                        data = [
                            (16, -9),
                            (23, -9),
                        ],
                        width = 64,
                        height = 32,
                        color = cloudcolor,
                        x_lim = (-31, 32),
                        y_lim = (-15, 16),
                    ),
                    lower_scoreboard,

                    # Clock Face
                    render.Box(
                        width = 64,
                        height = 32,
                        child = render.Circle(
                            color = "FFF",
                            diameter = 32,
                            child = render.Circle(
                                color = "#008800",
                                diameter = 30,
                                child = render.Stack(
                                    children = [
                                        render.Plot(
                                            data = [
                                                (-14, 1),
                                                (-13, 1),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-14, 0),
                                                (-13, 0),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (11, 1),
                                                (12, 1),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (11, 0),
                                                (12, 0),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-1, 14),
                                                (-.5, 14),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-1, 13),
                                                (-.5, 13),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-1, -12),
                                                (-.5, -12),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-1, -11),
                                                (-.5, -11),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (4, 11.99),
                                                (5, 11.99),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (4, 10.99),
                                                (5, 10.99),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (4, -8.99),
                                                (5, -8.99),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (4, -9.99),
                                                (5, -9.99),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-6, -8.99),
                                                (-7, -8.99),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-6, -9.99),
                                                (-7, -9.99),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-6, 10.99),
                                                (-7, 10.99),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-6, 11.99),
                                                (-7, 11.99),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (8.99, -4.5),
                                                (9.99, -4.5),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (8.99, -5.5),
                                                (9.99, -5.5),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (8.99, 6),
                                                (9.99, 6),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (8.99, 7),
                                                (9.99, 7),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-10.99, 7),
                                                (-11.99, 7),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-10.99, 6),
                                                (-11.99, 6),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-10.99, -4),
                                                (-11.99, -4),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-10.99, -5),
                                                (-11.99, -5),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-1.5, 0),
                                                (-0.5, 0),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        render.Plot(
                                            data = [
                                                (-1.5, 1),
                                                (-0.5, 1),
                                            ],
                                            width = 32,
                                            height = 32,
                                            color = "FFF",
                                            x_lim = (-15, 15),
                                            y_lim = (-15, 15),
                                        ),
                                        hour_hand,
                                        minute_hand,
                                    ],
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        ),
    )
