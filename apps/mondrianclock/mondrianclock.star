"""
Applet: Mondrian Clock
Summary: Mondrian-inspired clock
Description: Displays a Piet Mondrian inspired clock face, De Stijl.
Author: @theredwillow
"""

load("render.star", "render")
load("time.star", "time")
load("schema.star", "schema")

DEFAULT_TIMEZONE = "America/Chicago"

RED = "#FF0000"
BLUE = "#0000FF"
YELLOW = "#FFFF00"
WHITE = "#FFFFFF"
BLACK = "#000000"
GRAY = "#808080"

black_outline_block = render.Box(width=2, height=2, color=BLACK)

def draw_hour(hour, minute, show_clock):
    hour_blocks = []

    def draw_no_hour_block():
        return render.Box(width=4, height=20, color=WHITE)

    def draw_one_hour_block():
        return render.Box(width=10, height=20, color=WHITE)

    def draw_two_hour_block():
        return render.Column(
            children = [
                render.Box(width=10, height=9, color=WHITE),
                black_outline_block,
                render.Box(width=10, height=9, color=WHITE),
            ],
        )

    def draw_three_hour_block():
        return render.Column(
            children = [
                render.Box(width=10, height=5, color=WHITE),
                black_outline_block,
                render.Box(width=10, height=6, color=WHITE),
                black_outline_block,
                render.Box(width=10, height=5, color=WHITE),
            ],
        )

    def write_time(hour, minute):
        if hour == 0:
            hour = 12
        elif hour < 10:
            hour = "0%d" % hour
        if minute < 10:
            minute = "0%d" % minute
        return render.Text("%s:%s" % (hour, minute), color=BLACK)

    def draw_red_block(white_blocks):
        white_width = 67 - (white_blocks * 13)
        if white_blocks == 0:
            white_width -= 9
        red_block = render.Box(width=white_width, height=20, color=RED)
        if show_clock:
            red_block = render.Stack(
                children = [
                    red_block,
                    write_time(hour, minute)
                ],
            )
        return red_block
    
    if hour == 0:
        hour_blocks.append(draw_no_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_red_block(0))
    elif hour == 1:
        hour_blocks.append(draw_one_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_red_block(1))
    elif hour == 2:
        hour_blocks.append(draw_two_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_red_block(1))
    elif hour == 3:
        hour_blocks.append(draw_three_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_red_block(1))
    elif hour == 4:
        hour_blocks.append(draw_three_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_one_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_red_block(2))
    elif hour == 5:
        hour_blocks.append(draw_three_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_two_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_red_block(2))
    elif hour == 6:
        hour_blocks.append(draw_red_block(0))
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_no_hour_block())
    elif hour == 7:
        hour_blocks.append(draw_red_block(1))
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_one_hour_block())
    elif hour == 8:
        hour_blocks.append(draw_red_block(1))
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_two_hour_block())
    elif hour == 9:
        hour_blocks.append(draw_red_block(1))
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_three_hour_block())
    elif hour == 10:
        hour_blocks.append(draw_red_block(2))
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_three_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_one_hour_block())
    elif hour == 11:
        hour_blocks.append(draw_red_block(2))
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_three_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_two_hour_block())
    else:
        hour_blocks.append(draw_red_block(2))
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_three_hour_block())
        hour_blocks.append(black_outline_block)
        hour_blocks.append(draw_three_hour_block())

    return render.Row(
        children=hour_blocks,
        expanded=True,
    )

def draw_minute_left(minute):
    def draw_five_minute_block(color=WHITE):
        return render.Box(width=5, height=4, color=color)

    unused_five_minute_row = render.Row(
        children = [
            render.Box(width=8, height=4, color=WHITE),
            black_outline_block,
            draw_five_minute_block(),
            black_outline_block,
            draw_five_minute_block(),
            black_outline_block,
            draw_five_minute_block(),
            black_outline_block,
            draw_five_minute_block(GRAY),
            black_outline_block,
            draw_five_minute_block(GRAY),
            black_outline_block,
        ]
    )

    def draw_used_five_minute_row(minute):
        if minute >= 30:
            minute -= 30
        minute //= 5
        minute *= 7
        blocks = [
            render.Box(width=8 + minute, height=4, color=BLUE),
            black_outline_block
        ]
        if minute < 33:
            blocks.append(render.Box(width=33 - minute, height=4, color=WHITE))
            blocks.append(black_outline_block)
        return render.Row(
            children=blocks,
        )

    if minute < 30:
        five_minute_display = [
            draw_used_five_minute_row(minute),
            black_outline_block,
            unused_five_minute_row
        ]
    else:
        five_minute_display = [
            unused_five_minute_row,
            black_outline_block,
            draw_used_five_minute_row(minute)
        ]

    return render.Column(
        children=five_minute_display,
    )

def draw_minute_right(minute):
    modulus = minute % 5
    return render.Row(
        children = [
            render.Box(width=7, height=10, color=YELLOW if modulus == 0 else WHITE),
            black_outline_block,
            render.Column(
                children=[
                    render.Box(width=4, height=4, color=YELLOW if modulus == 1 else WHITE),
                    black_outline_block,
                    render.Box(width=4, height=4, color=YELLOW if modulus == 3 else WHITE),
                ],
            ),
            black_outline_block,
            render.Column(
                children=[
                    render.Box(width=4, height=4, color=YELLOW if modulus == 2 else WHITE),
                    black_outline_block,
                    render.Box(width=4, height=4, color=YELLOW if modulus == 4 else WHITE),
                ],
            ),
        ],
    )

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    hour = now.hour
    # if config.get("hour"):
    #     hour = int(config.get("hour"))
    if hour > 12:
        hour -= 12
    minute = now.minute
    # if config.get("minute"):
    #     minute = int(config.get("minute"))
    show_clock = config.bool("clock", False)
    return render.Root(
        child = render.Column(
            children = [
                draw_hour(hour, minute, show_clock),
                render.Row(
                    children=[
                        render.Box(width=10, height=2, color=BLACK),
                    ],
                    expanded=True,
                ),
                render.Row(
                    children=[
                        draw_minute_left(minute),
                        draw_minute_right(minute),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "clock",
                name = "Display digital clock",
                desc = "Whether to display the digital clock or not",
                icon = "clock",
                default = True,
            ),
            # schema.Text(
            #     id = "hour",
            #     name = "Hour",
            #     desc = "A test tool for seeing hours.",
            #     icon = "vials",
            #     default = "00",
            # ),
            # schema.Text(
            #     id = "minute",
            #     name = "Minute",
            #     desc = "A test tool for seeing minutes.",
            #     icon = "vials",
            #     default = "00",
            # )
        ],
    )