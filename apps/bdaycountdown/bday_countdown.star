"""
Applet: Bday Countdown
Summary: Create a bday countdown
Description: Create a bday countdown!
Author: Jared Brockmyre
"""

load("encoding/base64.star", "base64")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CAKE_FRAME1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAO1JREFUOE9jZKAQMFKon4E2Bvz/b/CfkfECIzqNzbVYXfA/w+A/44wLjOg0UQYY/Df4fz6TgcFQ+jzD+aeGDAwnrBkYLI4yGE5nYNj7uZRBmC8axVI4x6D5//+9+cvAlgiVdTO86yrFoMFydscY3h2yghsENuDtp6X/kZ2HzwCYOueJUQwXahkZwQb8N8j+DzKVVADyDlYXEGOQM283wwXGCxADvn6/8N+aIwEcSIQAyOmgsOJg1Wbg5jRAGADTyGU5GxxIMIUgm0AGwwIPpBEGsBpAyAXI8tQzABYOpNoOUo+RlEEBis8gkLOR5QECa3kRTskN4gAAAABJRU5ErkJggg==
""")
CAKE_FRAME2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAO1JREFUOE9jZKAQMFKonwGrAf//G/xnZLzAiE5js4xGBmQY/GeccYHxPxpNlAsM/hv8P5/JwGAofZ7h/FNDBoYT1gwMFkcZDKczMOz9XMogzBeN4mo4x6D5//+9+cvAlgiVdTO86yrFoMFydscY3h2yghsENuDtp6X/kZ2HzwCYOueJUQwXahkZwQb8N8j+DzKVVADyDlYXEGOQM283wwXGCxADvn6/8N+aIwEcSIQAyOmgsOJg1Wbg5jRAGADTyGU5GxxIMIUgm0AGwwIPpBEGsBpAyAXI8tQzABYOpNoOUo+RF0ABis8gkLOR5QE07oUR5KDQZwAAAABJRU5ErkJggg==
""")

def main(config):
    timezone = config.get("$tz", "America/New_York")
    now = time.now().in_location(timezone)
    bday = time.time(year = now.year, month = int(config.get("birthMonth", "1"), 10), day = int(config.get("birthDay", "1"), 10), location = timezone)
    name = config.str("name", "Name")
    days_until = bday - now
    days = math.ceil(days_until.hours / 24)

    if (days < 0):
        days = (365 - (days * -1))

    c = config.get("nameColor", "#0000ff")

    if (days == 0):
        row1Text = "Happy"
        row2Text = "Birthday"
        row3Text = str(name) + "!"
        row4Text = ""
    else:
        row1Text = str(days) + " days"
        row2Text = "until"
        row3Text = str(name) + "'s"
        row4Text = "birthday!"

    displayChildren = [
        render.Text(content = row1Text, font = "tom-thumb"),
        render.Text(content = row2Text, font = "tom-thumb"),
        render.Text(content = row3Text, font = "tom-thumb", color = c),
        render.Text(content = row4Text, font = "tom-thumb"),
    ]

    displayChildren = [
        render.Row(
            children = [
                render.Image(src = CAKE_FRAME1, width = 24, height = 24),
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    expanded = True,
                    children = displayChildren,
                ),
            ],
        ),
        render.Row(
            children = [
                render.Image(src = CAKE_FRAME2, width = 24, height = 24),
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    expanded = True,
                    children = displayChildren,
                ),
            ],
        ),
    ]

    return render.Root(
        delay = 800,
        child = render.Animation(children = displayChildren),
    )

def get_schema():
    dayOptions = [
        schema.Option(
            display = "1",
            value = "1",
        ),
        schema.Option(
            display = "2",
            value = "2",
        ),
        schema.Option(
            display = "3",
            value = "3",
        ),
        schema.Option(
            display = "4",
            value = "4",
        ),
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = "6",
            value = "6",
        ),
        schema.Option(
            display = "7",
            value = "7",
        ),
        schema.Option(
            display = "8",
            value = "8",
        ),
        schema.Option(
            display = "9",
            value = "9",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
        schema.Option(
            display = "11",
            value = "11",
        ),
        schema.Option(
            display = "12",
            value = "12",
        ),
        schema.Option(
            display = "13",
            value = "13",
        ),
        schema.Option(
            display = "14",
            value = "14",
        ),
        schema.Option(
            display = "15",
            value = "15",
        ),
        schema.Option(
            display = "16",
            value = "16",
        ),
        schema.Option(
            display = "17",
            value = "17",
        ),
        schema.Option(
            display = "18",
            value = "18",
        ),
        schema.Option(
            display = "19",
            value = "19",
        ),
        schema.Option(
            display = "20",
            value = "20",
        ),
        schema.Option(
            display = "21",
            value = "21",
        ),
        schema.Option(
            display = "22",
            value = "22",
        ),
        schema.Option(
            display = "23",
            value = "23",
        ),
        schema.Option(
            display = "24",
            value = "24",
        ),
        schema.Option(
            display = "25",
            value = "25",
        ),
        schema.Option(
            display = "26",
            value = "26",
        ),
        schema.Option(
            display = "27",
            value = "27",
        ),
        schema.Option(
            display = "28",
            value = "28",
        ),
        schema.Option(
            display = "29",
            value = "29",
        ),
        schema.Option(
            display = "30",
            value = "30",
        ),
        schema.Option(
            display = "31",
            value = "31",
        ),
    ]
    monthOptions = [
        schema.Option(
            display = "1",
            value = "1",
        ),
        schema.Option(
            display = "2",
            value = "2",
        ),
        schema.Option(
            display = "3",
            value = "3",
        ),
        schema.Option(
            display = "4",
            value = "4",
        ),
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = "6",
            value = "6",
        ),
        schema.Option(
            display = "7",
            value = "7",
        ),
        schema.Option(
            display = "8",
            value = "8",
        ),
        schema.Option(
            display = "9",
            value = "9",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
        schema.Option(
            display = "11",
            value = "11",
        ),
        schema.Option(
            display = "12",
            value = "12",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "name",
                name = "Birthday Person's Name",
                desc = "Birthday Person's Name (Max 9 characters)",
                icon = "gear",
                default = "Your",
            ),
            schema.Color(
                id = "nameColor",
                name = "Name Color",
                desc = "Color of the name.",
                icon = "brush",
                default = "#0000FF",
            ),
            schema.Dropdown(
                id = "birthDay",
                name = "Birth day",
                desc = "The birth day.",
                icon = "gear",
                default = dayOptions[0].value,
                options = dayOptions,
            ),
            schema.Dropdown(
                id = "birthMonth",
                name = "Birth month",
                desc = "The birth month.",
                icon = "gear",
                default = monthOptions[0].value,
                options = monthOptions,
            ),
        ],
    )
