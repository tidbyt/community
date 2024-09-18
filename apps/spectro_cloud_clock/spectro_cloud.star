"""
Applet: Spectro Cloud Clock
Summary: Spectro Cloud images
Description: A collection of Spectro Cloud images with a clock.
Author: karl-cardenas-coding
"""

load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SPECTRO_FONT_COLOR_BLUE = "#3575CF"
PALETTE_FONT_COLOR_PURPLE = "#6a5d9d"

IMAGES = [
    base64.decode("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"),
    base64.decode("iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAYAAACpSkzOAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAGqADAAQAAAABAAAAGgAAAABMybYKAAAFB0lEQVRIDZWVD0zUZRjHv7+7447jDu44/tecFoa1MleGWrhllg5qTY1cAzS1MhL/hNAGthBbRaCEkpDElptYRsn6S1kuZhlqoNXWXJbDMtn4z/Efj/v363le+N3B3THl2X6/e3/P+zzv533+vO8BMxBZlvPcbtlFj5vGJfRIM3C/sSktWGh3uuXs963y/dvbxPPSwV7ZZmeefOBmgNPuaMK5yO6U83dW9+GXv8YC7mjB7VpUbLEgRCcdIoNtkiS5Axn6gSYAZTa7nL2jyopfW+yB/Px0d80KQtU2C4x61Qc0+aIvcAqIIJWjY3LW1ves+OPfwIDHE/VYOFeLNz4e8IOxIj5Og+odETAbVDUE26AYaZQBQapeq+nPPHHhuqIK+Nva7URkmCrgHCuvtDvx6K5OJCZon6U1jQRLZb3HQ5bx3I0gep2Eh+cHU0Q6rgn7TyvnL9sx5pBXKwYCRGT1tW5nkEdJaxykAiuy4DYtzpXFonFfLDatMGLp3Tr8TOOm/bFYcqdOMcPLq8JgCPZu4PcrdhWtHcwGSkT3ftXkTZlbBrr6XTj6SiSyV4fh8M4IXO10ImV3F5ovj6HN6sJjr3ZSHR2ozLJgT4ZZPIvnaTFqI+cJqWsc5dFSfimgzd/51IaLffbSGNYvN+DYjyNIK+kR8HCjGgZKW9+wG5vf7cXeukE8uViPWVFqpO/tgRcDNP0tjsQWBinNkNrR5+LvKcIQ65Ab6csMCDeqQM2CsBAJwdrx9OSsCUPGIwb0DLrB6fUV6mBQ7VeyXkQ0YpOjfY0soSrogiQ8UdiF8i8HkfKAHmffiUWMWS30Z0pjBeQ4pSe5oBMSsfnw+kq71WWkOklcrAhOka8smqeDwymDbgbUNIzg9WMDAvBflxN/XnOIqI40DKP40wHeNQZG3Fi1RO+7DL49L2o/myNaU9c44mdgoVRx6KYQFbKpm/LXhgmb9aU92FjWI8YZlNK8tSZEUPSc4jiL2m+d+mYBWidRRM0P5nQk8s5ZNGQbZVKjeGM47pnj6Xi46AZT07bYzuGEaGMeazXeduZOXbevB/0UHduzcEovlMe1aKiV71MgPFG/JxqXWh04emoYJZvCRY2URvmpJJbuMokWB5wuGbRBdhGHl89V7elRpFGU3DwP5Y7PcVrp3ozn/Xi3RE7JBV3CmV//pDhRnmnBM8XdMBlUAlL2+SC6B1x4myKeHa0B14zHborgyA/Dwrfi6yHPGmJABBWFllOQZpo6MfHFaZh7iwY8vzvdJNLx0akRnPzNxrskgBmZKaHipuAzFUieX2lEcJBUJKKhOjVuP2RNCtR9MeFqfEPp5FzzjqtPDItDmZoUgtynxhuk8MN+TBR9CusO2mRtftRFuljne9JGsOFleZ2Goev+/1tzYjQ4vitKwBioCHflZ2dGsf+LQUXl+Q2iotD9aCfzYAJ5//MJFEq37aBSRI8HDT7Jj0JWZS96qYUZxA/XhKX5QBwWZbePf0x6NxTFwGxURROkm9XKXUfO0hDdBMv5Ip0s3NKRJpWAsJ67SIHw9+mLNiTc6j0GrCt9IZwhTysQ1k1KBH/yQnJFZf3Q1sMnxztoXHvz7+SFery1wVxLkLTJXn4gniRYC7V0fEsbncwZCP/zfv9mTAdB4nzdpgOpKEP2pNwONdXN1yfgN6f4XFmcTL86Ajl8jQKC2Iii4mJddbpg8HUK9E1Xl430CQRpDTT/P8VcGm2OXW+ZAAAAAElFTkSuQmCC"),
    base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAAXCAYAAAALHW+jAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAAFwAAAAD1fYotAAADY0lEQVQ4Ea1UW0iUQRSe+ffmImahGwQG5lNeUNEXt4KS0tTVXXFdFYm0iz3lmr1IROCLSj1kai+VQkaGrhq6eGklKOjBwDKN0pciwS6Qbt7ytuu/pzP/Otu/KitBB/45Z75zzvfPnJk5lOwiNotNG7y8OophsBysTS7oLFgNlCIEcvYZWsuRbAVjDuMXzWzEWgLl0J2cw0X1kfr2yinmG8h8HAFU/IBmKJtvCgClxdn9Z9s5wLUf4UhxfdSGKLxHZzB+U+LqWvwxe9USC+4zPDRSoD1o+nIoQEnWYOkj5ucibfmjpVo9XNgwhmSf0cHImEQqtEE1XpOQ7P5Su2GgRABK7nKM6/tZvU+w1mo2F4YLG5sWhX3raCfwANTjezxzGn1HhZVhPZ3Oi/Zu5wVmZ/eXlOPhaNAcZ3MmQCBxblm9fi+rp0GJ08teWBqXPYQmHO2wspWSHpszhgrwFmOCAAjp7ZptEgWSnJcXPonuRFyVQsr6O1iRkAs9o++wtrGZzTat1QhavCrATlcuWoWHTNi7ZidDlpaSUs8dWpM7mS1giVtxa5ST9XbPGJCMXxUpHus2jMZraYIDLjZ6MSRk1d75K5NjXAv69opSNhktu3VcAj1kr6S9w7zgIRG55vAjpvxw/QalBxFe8PmpKI+VYOXI+booQaEcBwrfEPHfogpic0y675zAbA772t3tjFMCTHNsq1YKCgUeAG7iP0nAp/eP/1gTqCdGdso7pLvpuwHbj7isggMzzIu2zg3AGoWfUEoqL/XnOhgYmJCQ/W5B9RPv33MsCnUTctKPCYj0LDlZbbqjcTdCnn/K94C9yBRRQbzRpJMIa9OGjISC9M4DEuLjz8Gu8hQ5VJvMbkohxWjWSdu+mTkQIYoK7ETg60RKTGrEJCtfilwrAN4YLDp1b5fzKtbJYzSH3WH+6hMvlBq165UokhR5PP6sQUhqrqoIml9hj31M7pTbpvyw25wM61SnVrvcWFM52agrdEFzzZFxRdpybGe1CwmK5CRb7Zp0RxrW8Rni8qv2WyQk/sbQ6S88flsNTRZdG7YrLS7/AQ9iGsmGZHPs2FB03ZFhk2GSuY2QobmWsGYAaBkc/CQ1TXkSEjUjUZkck9s7ErIAiktExRqvV4BOuNyq5OqXqWsc2kn/AVFaMCANX62dAAAAAElFTkSuQmCC"),
    base64.decode("iVBORw0KGgoAAAANSUhEUgAAABMAAAARCAYAAAA/mJfHAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAE6ADAAQAAAABAAAAEQAAAABarwPGAAACmUlEQVQ4EYVTTWgTURB+L5vaUClWQQQvXhRNkzQKUhFE6EXJbo0KBgVFBBFEaL2Wmq1LdnPw5k0EQYqiCMUU0yQqOeixtVhlszUexINeqlUUSfAnu8/vbfYta1p1Dvtmvm/m25m3s5T8xxTDyjDG7lFCj5TU2IN/pdO/kem8uanl0Ffg1wdyln52fd9eHdv9NYD57goxTWOh2bBVpowc9LMI+QK/T8SMkMmKGj8jYnFSwhgmQClM0c2zjNAbgsTJHGJHH6rJ16mctQtpc8DCHo/C0IGS2l91Y+hQWa8xwsi58kTcFVFy5inAt7wCfrQIZXvL2cQ8D1K6ZaCDS9z37B2aGUFT022xNtqQiJ0oqsm3vFtZXyxCRBEVeGGd9XXvrIxu+5HRrDWNEFsglPT7PJygmMBnm/bHfU+0oZb3Eeoggvd1Bfc1xpM7R3fFcGmjmDUPvpcnuUaJWs7GDe6nDOskZex2m3Cfq45Ohw3z6Ew2UXCLcrXTlJLJQNEvTLynMhFbUPKmwhw6E+AcSXJixfEB3jkZNqxBMebnlm1HH2vJD/y+0Mk0diYdKPwG3+8ak1zDAl/g/CFtvscJR14yRraGvIINYUlawpet8Bh3cliyuzbCXfZ4IfS+adNeISQbtZu2FGlwIZ7HO3uBM+kVeQc9X1Zj13mg6FYa91mgDpFLl+OPOJYyzOOU0btw/aWHM+UGWNYolvU5yAhP9qwJkYGKmngjANlY3II1NhGLTjm13C1JOwrj0U++Mkdl3byIl13lfsCeNe21+3ukxlNggwEcfwA7VlIT9wX2hxgH+b85F7aqWNIhkdR5omiqpMYzq+CdUDtOa/XNLclexO+5LpDhjxTAfHdFZz7jOUqudgLz3OkcqTOPx78BgQUMlEb71ncAAAAASUVORK5CYII="),
    base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB0AAAAdCAYAAABWk2cPAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAHaADAAQAAAABAAAAHQAAAADeexZRAAAEK0lEQVRIDe2WW0wcZRTH/3PdGdhlB9jZCyywwHLtQgFbIYVgFzFCeoltWiC2Dz6VShqJsYnRxMT0wScviYkkfSDRGBWMibVNsQmmBW0kFFDaQktd2i6VRZCG2+6wu3R3x1mUiy1ZQtfEF87DzDfnfOf8vnO+78wMsC3bFdiuwP9RgWLje6L9ha4vY9+Z9OMLrxxpDXQkY0Rb81eleGb3fdObl/j0BPtgnkEQxsvUyMjh4dRRIXcEZzKCbUNTrfVjVebr4w9wsK7Teub3DJNuv7MwXivIpbGwZPM4lkijUEX8uKHzP8otZWpNaysJ5lcM3LUboLozmcup0kdyKQIL+RxkiwqWeBoWlsAYhxP/CdRmc2RmqrmBC4cSQGmJFturrmFjoh6BNBY30lXwKRlqOQJDLPzjZYQjamgMcpJMYmi0c188CAv3XdHL/Y2pO0TKa6LQa1RhzMQAGhJneUCmUREJGLZtuqdhYHnVeddgrQFEHvtR0fH+/Wa9j5r96TMwI/eQaZgDZ1B2SU1CZnEU7789FhV0FVhjwOKOmA9zTwy+lqaeodS3/oA2uQJuvwN8aQpiNIDu0tVdxLXpVpw6k/XU0PVAyRr6JPfk580iuimNcx4eTilnqg5kdTF6ZAIZzR2tYHb2y4U6N55jft4MSqybQFmEvRrnXNfcCvB6uQYpvZ2gh4cRF1QjaTYH80kCdEfy4aBZ3NyXCOMb979XFQq1tyr98JuTedgJ37qYGw6XoSZhT6Xd+EE3G1Rh4lGv1x8r8rw0C/UCjeCSBJmUoPVbloH6YwUYGbiBwbeqoXnlm5ai7Mqmi40iYKZLsZu4tiHlMeVyn+7Un6zrVfdBHLwJISabN/oMCAZYBegGF5DBymvA33r68GtVCuIUoLWsoumXAwKQQGcrwIhtsp5L4cV3rb44tCZOzVKUFwhIbrAUpwz8YAIAIxvgNgnQHy/AeI8TnntX4B3iWrOe3dM4eiABE3rerJTUuT7oZmMKd7tmFmqabHyItmlCajA+CmyIBBUgQCvARVEN8VAuZvo9SJ7yYrSmGGYhuyQMdIWBzxOuzSCP21cPEtn0Q1ueY6Y++fY8VB4vGK8BGbuMeChqIE2S0LklCDoa5yusmLPxTw0ML2D15RBqqW74M/CwXT/Ng6QtKH/Jign3I3hve6HzKAdJZDBVIEQN/Bc0/DB9panBQ3PtldVm9GkNkObnoSUDYGMXISRSuFxljirDMCMsT3xlzklHGoI+B6T0hHozH4ch17cI3JGQt1CCvS5x6dPDsVvew79Ra9fV8q6pgAvnshoedLa0X01zYslkAqNNwcSYhKPeRRZfO5SmjE6eyHQl3Gj/6Qac6gBBquuTmBCmU5W+FVWAaIn0U7DiHt2dbO5pKzh4WTrcMXeW6l6siy7aVrxPX9dvZfpmc/8ChDhcwhibTe4AAAAASUVORK5CYII="),
]

def main(config):
    message = "Spectro"
    message2 = "Cloud"
    timezone = config.get("timezone") or "America/Phoenix"
    now = time.now().in_location(timezone)

    use_24hour = config.bool("24hour", False)
    time_format_colon = "3:04 PM"
    time_format_blank = "3 04 PM"
    if (use_24hour):
        time_format_colon = "15:04"
        time_format_blank = "15 04"

    return getDisplay(config.bool("clock"), message, message2, now, time_format_colon, time_format_blank)

def get_schema():
    return schema.Schema(
        fields = [
            schema.Toggle(
                id = "clock",
                name = "Display Clock",
                desc = "Display the clock",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "24hour",
                name = "24 Hour Time",
                icon = "clock",
                desc = "Choose whether to display 12-hour time (off) or 24-hour time (on). Requires Display Clock to be enabled.",
                default = False,
            ),
        ],
        version = "1",
    )

# This function returns a random image from the list of images
# The seed is by default updated every 15 seconds
def getRandomImage(images):
    num = random.number(0, len(images) - 1)
    return render.Image(src = images[num])

# This function returns the display based on the clock value
# If clock is true, it will display the clock
# If clock is false, it will not display the clock
# The message and message2 are the text that will be displayed
# The now is the current time
def getDisplay(clock, message, message2, now, time_format_colon, time_format_blank):
    img = getRandomImage(IMAGES)

    if (clock):
        return render.Root(
            delay = 500,
            child = render.Box(
                render.Row(
                    expanded = True,  # Use as much horizontal space as possible
                    main_align = "space_evenly",  # Controls horizontal alignment
                    cross_align = "center",  # Controls vertical alignment
                    children = [
                        img,
                        render.Column(
                            main_align = "space_around",
                            children = [
                                render.Text(
                                    message,
                                    font = "5x8",
                                    color = SPECTRO_FONT_COLOR_BLUE,
                                ),
                                render.Text(
                                    message2,
                                    font = "5x8",
                                    color = SPECTRO_FONT_COLOR_BLUE,
                                ),
                                render.Animation(
                                    children = [
                                        render.Text(
                                            content = now.format(time_format_colon),
                                            font = "CG-pixel-3x5-mono",
                                            color = PALETTE_FONT_COLOR_PURPLE,
                                        ),
                                        render.Text(
                                            content = now.format(time_format_blank),
                                            font = "CG-pixel-3x5-mono",
                                            color = PALETTE_FONT_COLOR_PURPLE,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        )
    else:
        return render.Root(
            delay = 500,
            child = render.Box(
                render.Row(
                    expanded = True,  # Use as much horizontal space as possible
                    main_align = "space_evenly",  # Controls horizontal alignment
                    cross_align = "center",  # Controls vertical alignment
                    children = [
                        img,
                        render.Column(
                            main_align = "space_around",
                            children = [
                                render.Text(
                                    message,
                                    font = "5x8",
                                    color = SPECTRO_FONT_COLOR_BLUE,
                                ),
                                render.Text(
                                    message2,
                                    font = "5x8",
                                    color = SPECTRO_FONT_COLOR_BLUE,
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        )
