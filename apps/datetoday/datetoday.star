"""
Applet: Date Today
Summary: Shows today's date
Description: A plain app to show today's date on the Tidbyt. No frills.
Author: Friedel Solutions
"""
# thanks

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# 5x7 bitmap font.
FONT = {
    "A": [
        "01110",
        "10001",
        "10001",
        "11111",
        "10001",
        "10001",
        "10001",
    ],
    "B": [
        "11110",
        "10001",
        "10001",
        "11110",
        "10001",
        "10001",
        "11110",
    ],
    "C": [
        "01111",
        "10000",
        "10000",
        "10000",
        "10000",
        "10000",
        "01111",
    ],
    "D": [
        "11110",
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "11110",
    ],
    "E": [
        "11111",
        "10000",
        "10000",
        "11110",
        "10000",
        "10000",
        "11111",
    ],
    "F": [
        "11111",
        "10000",
        "10000",
        "11110",
        "10000",
        "10000",
        "10000",
    ],
    "G": [
        "01111",
        "10000",
        "10000",
        "10111",
        "10001",
        "10001",
        "01111",
    ],
    "J": [
        "00111",
        "00010",
        "00010",
        "00010",
        "10010",
        "10010",
        "01100",
    ],
    "L": [
        "10000",
        "10000",
        "10000",
        "10000",
        "10000",
        "10000",
        "11111",
    ],
    "M": [
        "10001",
        "11011",
        "10101",
        "10101",
        "10001",
        "10001",
        "10001",
    ],
    "N": [
        "10001",
        "11001",
        "10101",
        "10011",
        "10001",
        "10001",
        "10001",
    ],
    "O": [
        "01110",
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "01110",
    ],
    "P": [
        "11110",
        "10001",
        "10001",
        "11110",
        "10000",
        "10000",
        "10000",
    ],
    "R": [
        "11110",
        "10001",
        "10001",
        "11110",
        "10100",
        "10010",
        "10001",
    ],
    "S": [
        "01111",
        "10000",
        "10000",
        "01110",
        "00001",
        "00001",
        "11110",
    ],
    "T": [
        "11111",
        "00100",
        "00100",
        "00100",
        "00100",
        "00100",
        "00100",
    ],
    "U": [
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "01110",
    ],
    "V": [
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "01010",
        "00100",
    ],
    "Y": [
        "10001",
        "10001",
        "01010",
        "00100",
        "00100",
        "00100",
        "00100",
    ],
    "0": [
        "01110",
        "10001",
        "10011",
        "10101",
        "11001",
        "10001",
        "01110",
    ],
    "1": [
        "00100",
        "01100",
        "00100",
        "00100",
        "00100",
        "00100",
        "01110",
    ],
    "2": [
        "01110",
        "10001",
        "00001",
        "00010",
        "00100",
        "01000",
        "11111",
    ],
    "3": [
        "11110",
        "00001",
        "00001",
        "01110",
        "00001",
        "00001",
        "11110",
    ],
    "4": [
        "00010",
        "00110",
        "01010",
        "10010",
        "11111",
        "00010",
        "00010",
    ],
    "5": [
        "11111",
        "10000",
        "10000",
        "11110",
        "00001",
        "00001",
        "11110",
    ],
    "6": [
        "01110",
        "10000",
        "10000",
        "11110",
        "10001",
        "10001",
        "01110",
    ],
    "7": [
        "11111",
        "00001",
        "00010",
        "00100",
        "01000",
        "01000",
        "01000",
    ],
    "8": [
        "01110",
        "10001",
        "10001",
        "01110",
        "10001",
        "10001",
        "01110",
    ],
    "9": [
        "01110",
        "10001",
        "10001",
        "01111",
        "00001",
        "00001",
        "01110",
    ],
}

def pixel_char(char, scale, date_color, small = False):
    pattern = FONT[char]
    pixels = []

    # Month glyphs are 8x10. Day glyphs are 10x14.
    # Keep every bitmap cell, with symmetric integer pixel sizes.
    column_widths = [2, 1, 2, 1, 2]
    row_heights = [1, 2, 1, 2, 1, 2, 1]

    for row_index in range(len(pattern)):
        row = pattern[row_index]
        row_pixels = []
        pixel_height = row_heights[row_index] if small else scale

        for i in range(len(row)):
            color = date_color if row[i] == "1" else "#000000"
            pixel_width = column_widths[i] if small else scale
            row_pixels.append(
                render.Box(
                    width = pixel_width,
                    height = pixel_height,
                    color = color,
                ),
            )

        pixels.append(render.Row(children = row_pixels))

    return render.Column(children = pixels)

def main(config):
    # Get selected color. Default is white.
    date_color = config.get("date_color", "#FFFFFF")

    # Pacific Time.
    now = time.now().in_location("America/Los_Angeles")

    # Example: OCT
    month = now.format("Jan").upper()

    # Example: 2 instead of 02
    day = now.format("2")

    text = month + " " + day

    # Each bitmap pixel becomes a 2x2 block.
    # 7 rows x 2 pixels = 14 pixels high.
    scale = 2

    chars = []

    for i in range(len(text)):
        char = text[i]

        if char == " ":
            # Space between month and day.
            chars.append(
                render.Box(
                    width = 4,
                    height = 14,
                    color = "#000000",
                ),
            )
        else:
            chars.append(
                pixel_char(
                    char,
                    scale,
                    date_color,
                    small = not (char >= "0" and char <= "9"),
                ),
            )

            # Gap between characters.
            chars.append(
                render.Box(
                    width = 2,
                    height = 14,
                    color = "#000000",
                ),
            )

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = "#000000",
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                children = chars,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "date_color",
                name = "Date Color",
                desc = "Choose the color of the date.",
                icon = "palette",
                default = "#FFFFFF",
            ),
        ],
    )
