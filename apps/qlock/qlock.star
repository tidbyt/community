"""
Applet: Qlock
Summary: Advanced clock
Description: Custom clock with time, binary, beats, and date; all with a custom font.
Author: craigerskine
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# contants
COLOR_LIGHT = "#FFF"
COLOR_MEDIUM = "#AAA"
COLOR_DARK = "#444"
COLOR_ACTIVE = "#60A5FA"
IMG_AT = "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAIAAAACDbGyAAAABnRSTlMARwBwAEyv7uYjAAAAHklEQVR4AWMAAvcCHwiCchhAAMoGYTQlCFUIPlwSACKBDShuPBCFAAAAAElFTkSuQmCC"
FONT_LG = {
    0: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAGklEQVR4AWMAAvcCHwhCcBBCcBla8hEI3T0ApgwoeZVEgsQAAAAASUVORK5CYII=",
    1: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAF0lEQVR4AWMAAvcCHyBiAAMoH11owPgAx6oVQCDcnwcAAAAASUVORK5CYII=",
    2: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAIUlEQVR4AWNwL/CBIwYgAFIoQnCAm4+iHl0zUcYgEDofAM6RI2oKctaHAAAAAElFTkSuQmCC",
    3: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAHUlEQVR4AWNwL/CBIwYgAFIoQnCAnY+unmL9aJoBSgkkbYNr508AAAAASUVORK5CYII=",
    4: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAHUlEQVR4AWNwL/ABIgYGKIM8PgIxAAEKHw7I4wMA0aohZCE1VpkAAAAASUVORK5CYII=",
    5: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAHklEQVR4AWNwL/BBRjj4DDCAjQ9H6HzCGjHtQ9MMAK81JG2nx/FMAAAAAElFTkSuQmCC",
    6: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAIklEQVR4AWMAAvcCHwiCcTD5DDCAycdUj4wQ6vHxEQjdPQC+XCRtb/kf7gAAAABJRU5ErkJggg==",
    7: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAG0lEQVR4AWNwL/BBRhh8OMDHR+hC4aCrJIMPAFA9HFUSvEi6AAAAAElFTkSuQmCC",
    8: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAHElEQVR4AWMAAvcCHwhCcBBCcBl8fASiVD+6ewBH8Sp/UnvjJQAAAABJRU5ErkJggg==",
    9: "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAKCAIAAADzWwNnAAAABnRSTlMARwBwAEyv7uYjAAAAIUlEQVR4AWMAAvcCHwhCcBBCcBm8fJxGMMABbj6mfgQHAAZGJG3IQD0FAAAAAElFTkSuQmCC",
}

FONT_SM = {
    0: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAD0lEQVR42mNAgP+oFFwcADLwAv4ksZ7pAAAAAElFTkSuQmCC",
    1: "iVBORw0KGgoAAAANSUhEUgAAAAIAAAAFCAQAAADFuvUXAAAADUlEQVR42mOAgP8YBAAp7wP9I6P5+wAAAABJRU5ErkJggg==",
    2: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAEElEQVR42mOAgf9ACARY+ABD3wP9H1yfMQAAAABJRU5ErkJggg==",
    3: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAEElEQVR42mOAgf9AyICVBwBH2wP9sY99VQAAAABJRU5ErkJggg==",
    4: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAE0lEQVR42mMAgv9ADKdg7P9wCgBUzgX7pCQQ2wAAAABJRU5ErkJggg==",
    5: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAD0lEQVR42mNAgP8M/7GyAUPfA/1fwkwYAAAAAElFTkSuQmCC",
    6: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAEklEQVR42mMAgv9ACKXgAIkNAHOvBPy7Y1D1AAAAAElFTkSuQmCC",
    7: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAEUlEQVR42mOAgf9AiEwxwPkAbbUH+SXwZucAAAAASUVORK5CYII=",
    8: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAD0lEQVR42mNAgP8MDFh5ACIBAf8m5PBAAAAAAElFTkSuQmCC",
    9: "iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAAEElEQVR42mNAgP8o7P9wCgA17QT8awBcmwAAAABJRU5ErkJggg==",
}

def zero_pad(number, width):
    return "0" * (width - len(str(number))) + str(number)

def to_binary(value, bits):
    lines = []
    for i in range(bits):
        color = COLOR_ACTIVE if value & (1 << (bits - 1 - i)) else COLOR_DARK
        lines.append(render.Box(width = 3, height = 1, color = color))
    return render.Column(children = lines)

def render_digits(value, width, font = FONT_SM, color = COLOR_MEDIUM, spacing = 1):
    padded_value = zero_pad(value, width)
    digits = [render_digit(padded_value[i], font, color) for i in range(width)]
    spaced_digits = []
    for i, digit in enumerate(digits):
        spaced_digits.append(digit)
        if i < len(digits) - 1:
            spaced_digits.append(render.Box(width = spacing, height = 1))
    return spaced_digits

def render_digit(digit, font, color):
    return render.Stack(children = [
        render.Box(width = 5 if font == FONT_LG else (2 if digit == "1" else 3), height = 10 if font == FONT_LG else 5, color = color),
        render.Image(src = base64.decode(font[int(digit)])),
    ])

def main(config):
    timezone = config.get("timezone") or "America/Chicago"
    now = time.now().in_location(timezone)
    bmt = time.now().in_location("Europe/Zurich")

    hours = now.hour % 12 or 12
    minutes = now.minute
    seconds = now.second
    month = now.month
    day = now.day

    # beats
    seconds_since_midnight = (bmt.hour * 3600) + (bmt.minute * 60) + bmt.second
    beats = int((seconds_since_midnight / 86.4))
    beats = beats % 1000

    time_digits = (
        render_digits(hours, 2, FONT_LG, COLOR_LIGHT, spacing = 2) +
        [render.Box(width = 10, height = 1)] +
        render_digits(minutes, 2, FONT_LG, COLOR_LIGHT, spacing = 2) +
        [render.Box(width = 10, height = 1)] +
        render_digits(seconds, 2, FONT_LG, COLOR_LIGHT, spacing = 2)
    )

    beats_render = render_digits(beats, 3)

    date_digits = (
        render_digits(month, 2) +
        [render.Padding(pad = (1, 2, 1, 0), child = render.Box(width = 2, height = 1, color = COLOR_DARK))] +
        render_digits(day, 2)
    )

    return render.Root(
        delay = 864,
        max_age = 120,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Row(children = time_digits),
                render.Row(
                    children = [
                        to_binary(hours // 10, 4),
                        render.Box(width = 4, height = 1),
                        to_binary(hours % 10, 4),
                        render.Box(width = 12, height = 1),
                        to_binary(minutes // 10, 4),
                        render.Box(width = 4, height = 1),
                        to_binary(minutes % 10, 4),
                        render.Box(width = 12, height = 1),
                        to_binary(seconds // 10, 4),
                        render.Box(width = 4, height = 1),
                        to_binary(seconds % 10, 4),
                    ],
                ),
                render.Padding(
                    pad = (4, 0, 4, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Row(children = date_digits),
                            render.Row(
                                children = [
                                    render.Stack(
                                        children = [
                                            render.Box(width = 5, height = 5, color = "#666"),
                                            render.Image(src = base64.decode(IMG_AT)),
                                        ],
                                    ),
                                    render.Box(width = 2, height = 1),
                                    render.Row(children = beats_render),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        # fields = [
        #   schema.Toggle(
        #     id = 'show_date',
        #     name = 'Display Date',
        #     desc = '',
        #     icon = 'calendar',
        #     default = True,
        #   ),
        #   schema.Toggle(
        #     id = 'show_beats',
        #     name = 'Display Beats',
        #     desc = '',
        #     icon = 'clock',
        #     default = True,
        #   ),
        # ],
    )
