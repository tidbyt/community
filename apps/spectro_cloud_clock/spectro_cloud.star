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
    base64.decode("iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAYAAACpSkzOAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAGqADAAQAAAABAAAAGgAAAABMybYKAAAFB0lEQVRIDZWVD0zUZRjHv7+7447jDu44/tecFoa1MleGWrhllg5qTY1cAzS1MhL/hNAGthBbRaCEkpDElptYRsn6S1kuZhlqoNXWXJbDMtn4z/Efj/v363le+N3B3THl2X6/e3/P+zzv533+vO8BMxBZlvPcbtlFj5vGJfRIM3C/sSktWGh3uuXs963y/dvbxPPSwV7ZZmeefOBmgNPuaMK5yO6U83dW9+GXv8YC7mjB7VpUbLEgRCcdIoNtkiS5Axn6gSYAZTa7nL2jyopfW+yB/Px0d80KQtU2C4x61Qc0+aIvcAqIIJWjY3LW1ves+OPfwIDHE/VYOFeLNz4e8IOxIj5Og+odETAbVDUE26AYaZQBQapeq+nPPHHhuqIK+Nva7URkmCrgHCuvtDvx6K5OJCZon6U1jQRLZb3HQ5bx3I0gep2Eh+cHU0Q6rgn7TyvnL9sx5pBXKwYCRGT1tW5nkEdJaxykAiuy4DYtzpXFonFfLDatMGLp3Tr8TOOm/bFYcqdOMcPLq8JgCPZu4PcrdhWtHcwGSkT3ftXkTZlbBrr6XTj6SiSyV4fh8M4IXO10ImV3F5ovj6HN6sJjr3ZSHR2ozLJgT4ZZPIvnaTFqI+cJqWsc5dFSfimgzd/51IaLffbSGNYvN+DYjyNIK+kR8HCjGgZKW9+wG5vf7cXeukE8uViPWVFqpO/tgRcDNP0tjsQWBinNkNrR5+LvKcIQ65Ab6csMCDeqQM2CsBAJwdrx9OSsCUPGIwb0DLrB6fUV6mBQ7VeyXkQ0YpOjfY0soSrogiQ8UdiF8i8HkfKAHmffiUWMWS30Z0pjBeQ4pSe5oBMSsfnw+kq71WWkOklcrAhOka8smqeDwymDbgbUNIzg9WMDAvBflxN/XnOIqI40DKP40wHeNQZG3Fi1RO+7DL49L2o/myNaU9c44mdgoVRx6KYQFbKpm/LXhgmb9aU92FjWI8YZlNK8tSZEUPSc4jiL2m+d+mYBWidRRM0P5nQk8s5ZNGQbZVKjeGM47pnj6Xi46AZT07bYzuGEaGMeazXeduZOXbevB/0UHduzcEovlMe1aKiV71MgPFG/JxqXWh04emoYJZvCRY2URvmpJJbuMokWB5wuGbRBdhGHl89V7elRpFGU3DwP5Y7PcVrp3ozn/Xi3RE7JBV3CmV//pDhRnmnBM8XdMBlUAlL2+SC6B1x4myKeHa0B14zHborgyA/Dwrfi6yHPGmJABBWFllOQZpo6MfHFaZh7iwY8vzvdJNLx0akRnPzNxrskgBmZKaHipuAzFUieX2lEcJBUJKKhOjVuP2RNCtR9MeFqfEPp5FzzjqtPDItDmZoUgtynxhuk8MN+TBR9CusO2mRtftRFuljne9JGsOFleZ2Goev+/1tzYjQ4vitKwBioCHflZ2dGsf+LQUXl+Q2iotD9aCfzYAJ5//MJFEq37aBSRI8HDT7Jj0JWZS96qYUZxA/XhKX5QBwWZbePf0x6NxTFwGxURROkm9XKXUfO0hDdBMv5Ip0s3NKRJpWAsJ67SIHw9+mLNiTc6j0GrCt9IZwhTysQ1k1KBH/yQnJFZf3Q1sMnxztoXHvz7+SFery1wVxLkLTJXn4gniRYC7V0fEsbncwZCP/zfv9mTAdB4nzdpgOpKEP2pNwONdXN1yfgN6f4XFmcTL86Ajl8jQKC2Iii4mJddbpg8HUK9E1Xl430CQRpDTT/P8VcGm2OXW+ZAAAAAElFTkSuQmCC"),
    base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAAXCAYAAAALHW+jAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAAFwAAAAD1fYotAAADY0lEQVQ4Ea1UW0iUQRSe+ffmImahGwQG5lNeUNEXt4KS0tTVXXFdFYm0iz3lmr1IROCLSj1kai+VQkaGrhq6eGklKOjBwDKN0pciwS6Qbt7ytuu/pzP/Otu/KitBB/45Z75zzvfPnJk5lOwiNotNG7y8OophsBysTS7oLFgNlCIEcvYZWsuRbAVjDuMXzWzEWgLl0J2cw0X1kfr2yinmG8h8HAFU/IBmKJtvCgClxdn9Z9s5wLUf4UhxfdSGKLxHZzB+U+LqWvwxe9USC+4zPDRSoD1o+nIoQEnWYOkj5ucibfmjpVo9XNgwhmSf0cHImEQqtEE1XpOQ7P5Su2GgRABK7nKM6/tZvU+w1mo2F4YLG5sWhX3raCfwANTjezxzGn1HhZVhPZ3Oi/Zu5wVmZ/eXlOPhaNAcZ3MmQCBxblm9fi+rp0GJ08teWBqXPYQmHO2wspWSHpszhgrwFmOCAAjp7ZptEgWSnJcXPonuRFyVQsr6O1iRkAs9o++wtrGZzTat1QhavCrATlcuWoWHTNi7ZidDlpaSUs8dWpM7mS1giVtxa5ST9XbPGJCMXxUpHus2jMZraYIDLjZ6MSRk1d75K5NjXAv69opSNhktu3VcAj1kr6S9w7zgIRG55vAjpvxw/QalBxFe8PmpKI+VYOXI+booQaEcBwrfEPHfogpic0y675zAbA772t3tjFMCTHNsq1YKCgUeAG7iP0nAp/eP/1gTqCdGdso7pLvpuwHbj7isggMzzIu2zg3AGoWfUEoqL/XnOhgYmJCQ/W5B9RPv33MsCnUTctKPCYj0LDlZbbqjcTdCnn/K94C9yBRRQbzRpJMIa9OGjISC9M4DEuLjz8Gu8hQ5VJvMbkohxWjWSdu+mTkQIYoK7ETg60RKTGrEJCtfilwrAN4YLDp1b5fzKtbJYzSH3WH+6hMvlBq165UokhR5PP6sQUhqrqoIml9hj31M7pTbpvyw25wM61SnVrvcWFM52agrdEFzzZFxRdpybGe1CwmK5CRb7Zp0RxrW8Rni8qv2WyQk/sbQ6S88flsNTRZdG7YrLS7/AQ9iGsmGZHPs2FB03ZFhk2GSuY2QobmWsGYAaBkc/CQ1TXkSEjUjUZkck9s7ErIAiktExRqvV4BOuNyq5OqXqWsc2kn/AVFaMCANX62dAAAAAElFTkSuQmCC"),
    base64.decode("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"),
    base64.decode("iVBORw0KGgoAAAANSUhEUgAAABMAAAARCAYAAAA/mJfHAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAE6ADAAQAAAABAAAAEQAAAABarwPGAAACmUlEQVQ4EYVTTWgTURB+L5vaUClWQQQvXhRNkzQKUhFE6EXJbo0KBgVFBBFEaL2Wmq1LdnPw5k0EQYqiCMUU0yQqOeixtVhlszUexINeqlUUSfAnu8/vbfYta1p1Dvtmvm/m25m3s5T8xxTDyjDG7lFCj5TU2IN/pdO/kem8uanl0Ffg1wdyln52fd9eHdv9NYD57goxTWOh2bBVpowc9LMI+QK/T8SMkMmKGj8jYnFSwhgmQClM0c2zjNAbgsTJHGJHH6rJ16mctQtpc8DCHo/C0IGS2l91Y+hQWa8xwsi58kTcFVFy5inAt7wCfrQIZXvL2cQ8D1K6ZaCDS9z37B2aGUFT022xNtqQiJ0oqsm3vFtZXyxCRBEVeGGd9XXvrIxu+5HRrDWNEFsglPT7PJygmMBnm/bHfU+0oZb3Eeoggvd1Bfc1xpM7R3fFcGmjmDUPvpcnuUaJWs7GDe6nDOskZex2m3Cfq45Ohw3z6Ew2UXCLcrXTlJLJQNEvTLynMhFbUPKmwhw6E+AcSXJixfEB3jkZNqxBMebnlm1HH2vJD/y+0Mk0diYdKPwG3+8ak1zDAl/g/CFtvscJR14yRraGvIINYUlawpet8Bh3cliyuzbCXfZ4IfS+adNeISQbtZu2FGlwIZ7HO3uBM+kVeQc9X1Zj13mg6FYa91mgDpFLl+OPOJYyzOOU0btw/aWHM+UGWNYolvU5yAhP9qwJkYGKmngjANlY3II1NhGLTjm13C1JOwrj0U++Mkdl3byIl13lfsCeNe21+3ukxlNggwEcfwA7VlIT9wX2hxgH+b85F7aqWNIhkdR5omiqpMYzq+CdUDtOa/XNLclexO+5LpDhjxTAfHdFZz7jOUqudgLz3OkcqTOPx78BgQUMlEb71ncAAAAASUVORK5CYII="),
    base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB0AAAAdCAYAAABWk2cPAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAHaADAAQAAAABAAAAHQAAAADeexZRAAAEK0lEQVRIDe2WW0wcZRTH/3PdGdhlB9jZCyywwHLtQgFbIYVgFzFCeoltWiC2Dz6VShqJsYnRxMT0wScviYkkfSDRGBWMibVNsQmmBW0kFFDaQktd2i6VRZCG2+6wu3R3x1mUiy1ZQtfEF87DzDfnfOf8vnO+78wMsC3bFdiuwP9RgWLje6L9ha4vY9+Z9OMLrxxpDXQkY0Rb81eleGb3fdObl/j0BPtgnkEQxsvUyMjh4dRRIXcEZzKCbUNTrfVjVebr4w9wsK7Teub3DJNuv7MwXivIpbGwZPM4lkijUEX8uKHzP8otZWpNaysJ5lcM3LUboLozmcup0kdyKQIL+RxkiwqWeBoWlsAYhxP/CdRmc2RmqrmBC4cSQGmJFturrmFjoh6BNBY30lXwKRlqOQJDLPzjZYQjamgMcpJMYmi0c188CAv3XdHL/Y2pO0TKa6LQa1RhzMQAGhJneUCmUREJGLZtuqdhYHnVeddgrQFEHvtR0fH+/Wa9j5r96TMwI/eQaZgDZ1B2SU1CZnEU7789FhV0FVhjwOKOmA9zTwy+lqaeodS3/oA2uQJuvwN8aQpiNIDu0tVdxLXpVpw6k/XU0PVAyRr6JPfk580iuimNcx4eTilnqg5kdTF6ZAIZzR2tYHb2y4U6N55jft4MSqybQFmEvRrnXNfcCvB6uQYpvZ2gh4cRF1QjaTYH80kCdEfy4aBZ3NyXCOMb979XFQq1tyr98JuTedgJ37qYGw6XoSZhT6Xd+EE3G1Rh4lGv1x8r8rw0C/UCjeCSBJmUoPVbloH6YwUYGbiBwbeqoXnlm5ai7Mqmi40iYKZLsZu4tiHlMeVyn+7Un6zrVfdBHLwJISabN/oMCAZYBegGF5DBymvA33r68GtVCuIUoLWsoumXAwKQQGcrwIhtsp5L4cV3rb44tCZOzVKUFwhIbrAUpwz8YAIAIxvgNgnQHy/AeI8TnntX4B3iWrOe3dM4eiABE3rerJTUuT7oZmMKd7tmFmqabHyItmlCajA+CmyIBBUgQCvARVEN8VAuZvo9SJ7yYrSmGGYhuyQMdIWBzxOuzSCP21cPEtn0Q1ueY6Y++fY8VB4vGK8BGbuMeChqIE2S0LklCDoa5yusmLPxTw0ML2D15RBqqW74M/CwXT/Ng6QtKH/Jign3I3hve6HzKAdJZDBVIEQN/Bc0/DB9panBQ3PtldVm9GkNkObnoSUDYGMXISRSuFxljirDMCMsT3xlzklHGoI+B6T0hHozH4ch17cI3JGQt1CCvS5x6dPDsVvew79Ra9fV8q6pgAvnshoedLa0X01zYslkAqNNwcSYhKPeRRZfO5SmjE6eyHQl3Gj/6Qac6gBBquuTmBCmU5W+FVWAaIn0U7DiHt2dbO5pKzh4WTrcMXeW6l6siy7aVrxPX9dvZfpmc/8ChDhcwhibTe4AAAAASUVORK5CYII="),
]

def main(config):
    message = "Spectro"
    message2 = "Cloud"
    timezone = config.get("timezone") or "America/Phoenix"
    now = time.now().in_location(timezone)

    return getDisplay(config.bool("clock"), message, message2, now)

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
def getDisplay(clock, message, message2, now):
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
                                            content = now.format("3:04 PM"),
                                            font = "5x8",
                                            color = PALETTE_FONT_COLOR_PURPLE,
                                        ),
                                        render.Text(
                                            content = now.format("3 04 PM"),
                                            font = "5x8",
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
