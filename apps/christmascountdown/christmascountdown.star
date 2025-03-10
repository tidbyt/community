"""
Applet: Christmas Countdown
Summary: Christmas Countdown
Description: Displays an animated tree and Merry Christmas and (optionally) the number of days until Dec. 25.
Author: Michael Creamer
"""

load("encoding/base64.star", "base64")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CHRISTMASTree = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABsAAAAgCAYAAADjaQM7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAG6ADAAQAAAABAAAAIAAAAAAg/t1uAAABmklEQVRIDb1TS05EMQwrnIMV4jhclhWnQkhcYGgedeu4TT8jNCON0jhxnKZ5KaV0O/2/frwfc4rGmRiEYA8b3RdTAfU3hPfEuPDtp3EY/zcxK+QKf357f+/tW5ezzpwQFY7woNZazAp+vbzVDVQB9QMh48/FtBB8WPDVBy52LmbJKASLAvBhgU/sXGy30GZeLHYVyFunnfLqc2xDcCymRPUhAhwLBB9xsb2YEthHUS7CccPVp1wvponqE9GNV/PULzwvxp0xgc8Xsbwl4zjDDhrzYpPEbjwnud3NmMxvw3gabCfHeVMZd2IIcLIlAB+MJH4zakj4cUFO5DMLM87nIOfvzVwidXaRBstguHF0EiyCHMLagjjBXIzfjQhufDNc6+XcJmbnQYLH9NY7nKbRxJZCjdTdzrh1EsHY681WQhpHYcb5bFOy9xTMA3hwJMHXcUc+eByvWD1MRqRE4zAvbIjet+S3m3EBE4h84LBoJvIJ998ZApHVJqI8xUtDbRtXHd4bBy/bXmyFoetVnsafM/Cw31NWsg/0Ib9fh3HVYaDkgSMAAAAASUVORK5CYII=""")

CHRISTMASTree1 = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABsAAAAgCAYAAADjaQM7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAG6ADAAQAAAABAAAAIAAAAAAg/t1uAAABiklEQVRIDb1UUW5DIQxjO0e/ph1nl+3XTlVN2gW6lw6D40cg9KOVqhBjxwHSllLKfff7cf3a1lSPPTMYIW42mjdTA80TxjmzqHCEB8Y5MxO7wt8/Ps+9fc7MGVHhCH/6ZFbwdvlsE6gGmgdGpp+fTAshR4Rec+AS52ZGRiFEFECOCHwS52bZQklebPYocEyddnr/HWsShjlhVAg4Bgi5Nljzs5kKOEdRLsb7hmtOXG+mRM1J6K5XeZpXnTfjzljAazZkHGtE5g3NJsTT9exwT2Ys5rdhvAymk/d5Uhl3ZoONx5tEuF5RxBM8nh4m8pqNGOd1wPkfEEfUq6q549QR52tjA6xF06dRNtw/PcQ7Uesd2m5m6wHBY3rqjKZ7dLOlURe5HzSabBMcXHs72cpotA8Ti7q23N5TdB7Ag4OEHAVXETrmNawtJlekQtOwLmyI3rfy+8m4gBlEOXBENBPlhPv7xkYUtYmIp3htqE/jqsNn96E74tlshaHrFU/33w/gZZ+3w8l+Iy/5/AE2Zc0Gd5UvqgAAAABJRU5ErkJggg==""")

CHRISTMASTree2 = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABsAAAAgCAYAAADjaQM7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAG6ADAAQAAAABAAAAIAAAAAAg/t1uAAABpUlEQVRIDb1UQWrEMBBL+oB9QU+lzyn0rQuF/qY/KIV+YOtJLVujeJwJLLuwjCVrpHFisizLcjv7f7m+ne6pGefCEIR6ctB8mAYoTgTnwtj49tt7mL9bmBk5488fj3Pvvk85m8wFkXHEB17HYWb4/fzabqAGKA6CrH8epkbAqOhXDF7qPMzEMEKFATAq+Emdh2WNkro4bDMot04n5avPe4nAcZg2KkaI8oqhq3Ufpg2M+VbCiPeNUwxdqT5MhYpVD6w6xVXnw4yEEJU5mKOONMxBV6sPmwjbEDA4o92FRc2OH9xO3uebyrwLwwaLTQAep4mq09FAjp8ZspDXHMg8rwPN/ztzQppsa6rYaeqp9UlwiK2lp18Q2XBfejXJYPUrPT3M1gOB5/TUmZ6e0cMOg3rT7ntpve3rEjz2drKjIN2HMfO8tqdk71M4T+CFi2h3En38wKM+cKstvt4/7ISpX9E3HfrKgMt6afRwgb52VExQ1NtJIgweNau3KZwxDKJqeuzxGlxUa06/jRp8LwyfUvdhRxymP9Lp/lMhHvZbS5K9s4f8/gDfkrV46xxCcgAAAABJRU5ErkJggg==""")

CHRISTMASTree3 = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABsAAAAgCAYAAADjaQM7AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAG6ADAAQAAAABAAAAIAAAAAAg/t1uAAABmUlEQVRIDb1TQW4EIQyb9h17qvqcfranvmpVqR+YEorBMYSBarUrrUKMHQfCHMdxnLv/t8+PbU3x2DODEeJmo+tmaqD5gvGaGRc+f5qG8YeZWSEtrPnDzKLCER4YtysJCPlE99t7fYFqoHlUJ+FzMy2EHBF6zYFLnJsZGYUQUQA5IvBJnJutFlrkxWa5wNd3nRU65qcPzOKC4dhMhZrDBDgeEHLsS+zNVMA5inIR3jdcc+J6MyVqTkJ3vcrTvOi8GXfGAl5nYZkl41gjDhrzZhNidz073O5kLObZMD7otmsCnIHu72TY0GcNHAWi6Hj0uTjcxALUwTPOazZknNcBx58sk6gzzrWY5XoTbGJr0bQHIhsnz02LrORaL2mama0HBI/pqVc0zaOZXRo1UZ0rmjVtvYnBN1h4g5mVomzOaxjoTSjH5imYBzBwIXUnYUNej3QVq4vJFWkx07AODTIvr2m+hd9OxgWMHOXAEWES5YT7mWEjitpExFO8NNRe41WH/92HLsXe7ApD11c83X9NwNN+L8nJnvVTfr8gys0GTE1eTgAAAABJRU5ErkJggg==""")

def main(config):
    #-----------------------
    # Get Configured Values
    #-----------------------
    line1Text = "Merry"
    line2Text = "Christmas"
    line1Color = config.get("line1Color", "#ff0000")
    line2Color = config.get("line2Color", "#00ff00")
    line3Color = config.get("line3Color", "#0000ff")
    showCountdown = config.bool("showCountdown", True)
    maxCountdownValue = config.get("maxCountdownValue", 365)

    if maxCountdownValue == None or maxCountdownValue == "":
        maxCountdownValue = 365

    #--------------------------------
    # Calculate days until Christmas
    #--------------------------------
    timezone = config.get("$tz", "America/New_York")
    now = time.now().in_location(timezone)
    today = time.time(year = now.year, month = now.month, day = now.day, location = timezone)
    current_xmas = time.time(year = today.year, month = 12, day = 25, location = timezone)

    if today > current_xmas:
        current_xmas = time.time(year = today.year + 1, month = 12, day = 25, location = timezone)

    date_diff = current_xmas - now
    days = math.ceil(date_diff.hours / 24)

    line3Text = str(days) + " days"

    #---------------------------
    # Setup array of text lines
    #---------------------------
    displayChildren = [
        render.Text(content = line1Text, font = "tom-thumb", color = line1Color),
        render.Text(content = line2Text, font = "tom-thumb", color = line2Color),
    ]
    if showCountdown and days > 0:
        child = render.Padding(
            child = render.Text(content = line3Text, font = "tom-thumb", color = line3Color),
            pad = (0, 3, 0, 0),
        )
        displayChildren.append(child)

    #---------
    # Prepare
    #---------
    displayChildren = [
        render.Row(
            children = [
                render.Image(src = CHRISTMASTree),
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
                render.Image(src = CHRISTMASTree1),
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
                render.Image(src = CHRISTMASTree2),
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
                render.Image(src = CHRISTMASTree3),
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    expanded = True,
                    children = displayChildren,
                ),
            ],
        ),
    ]

    if days > int(maxCountdownValue):
        return []

    #--------
    # Render
    #--------
    return render.Root(
        delay = 4000,
        child = render.Animation(children = displayChildren),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "line1Color",
                name = "Line 1 Color",
                desc = "Line 1 Color",
                icon = "brush",
                default = "#FF0000",
            ),
            schema.Color(
                id = "line2Color",
                name = "Line 2 Color",
                desc = "Line 2 Color",
                icon = "brush",
                default = "#00FF00",
            ),
            schema.Color(
                id = "line3Color",
                name = "Line 3 Color",
                desc = "Line 3 Color",
                icon = "brush",
                default = "#0000FF",
            ),
            schema.Toggle(
                id = "showCountdown",
                name = "Show Remaining Count",
                desc = "Show Remaining Count",
                icon = "gear",
                default = True,
            ),
            schema.Text(
                id = "maxCountdownValue",
                name = "Max Remaining Value",
                desc = "Max Remaining Value",
                icon = "gear",
                default = "365",
            ),
        ],
    )
