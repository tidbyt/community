load("encoding/base64.star", "base64")
load("render.star", "render")

ICON_FILTER1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAghJREFUOE9VVAlyxDAIA/z/Jxs6OnC2mWmzjrEsJCAjYwLPZGROTCSXORORGX7FzGDJNX/g2GQwXB/5c1G+GKHzUO6ZRTWIGXwxoCEehB0cbN4iLPzzKpIscSCjqvh9SSEjfTBj8jPhniajOsdBAs3JuNP8BkCyMBvt+/rHEEpkRveNzMN3nXospofr2zdOiqFS24SknZgzEzphoMON7o7DSybyIAddeAr7Q3mKNGWKJOt3Ebx6QQMzsL5iuny0/uToO5EFtGTsoRzLFiTABgFgMx/DOkwk5nYkpHia6RscpRQ2hinD4NUOaSKddUvg0LCj6tgQ1RPAYNqKuIazlm9LblGfnwJG+k2hAIg9pFtOlyUbOA9Tja0PE+ek3gi2xNAHqU53pAFp4nRUljQEe2bFP6WMAzABLkIbGPCMsEkApBRQdeKrT5uFgmGDQQakBQO2r3tuVCpFPCwllA2Qtt8pzc8M2I5FCFNyzQ3BZARA8Nz5qcMreciEHKBrazgwg4R2l6IzdfSvhwPdr6NOca0h32tjXg2jz8VQPoEBSkD96gbTpusNFaBO0jACKLrjO4OyloZM+X5d+jPjXpfmlpTDOAZVMxxZNMougyvlYLGqyf8/W0Yepu4KFLAGg+IF6GZagDexEfZ2PUB3ZBJfUIR8c8wXoCDFcgUw058p/5G28svLnaKhMvEHcHOKIuh/fCgAAAAASUVORK5CYII=
""")
ICON_FILTER2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAg1JREFUOE9VVFGWxDAIQnP/I0f3gZjOzse0TYwBRANARwDdgYB/0YC/Go3oALim5cCsTawfexCBCO7rx8RflI7NEW3M1yblC1cm/UOCmAsD1ZdY39aAIaoPXeZZ4IbmSxmyGMPgb5UW8/D/J3E3qlogM5PaSCNhJnjjG5QkHFpH6xCRNk4k2jrWvTjn4NbFyTNJpLkF+ZVXEkicQN8LUmJy0s9IVJfWohtkwIQrTRwetsZ++rKpV5FyDlX+K8FJ0wrcpiSNoI5EcS8iU0lvE326Xi4TdZJ+DR0msrp8pm6oGgY2jZRnHA+QjYJcHPnwXlOqUmKbBE9DazlFGVu+2tkM3JiidKCrFCjoU75nI8nB85SAcURlbTepPMlC6RFjDdL7T22qnxHSlNGZPDG+lZ5ExwsP9WSIjbRVJCW+S0NZZcQmSr6/lqI/pSGQcWSzqXuM5eg/IpE+CBdkv5mQDMb048ERUlqvwck3IpoBRJCHnvssI/pBm7QqSsMzTlp7fbUWQiUOzRLTTCETNfexLsqU14iKKIlKuhEx2a0cds5LOP06QZ5Uo9/l1W0N3ausdalpx6vfcGAZGHTf6FLzq3+m5XcY8OA6ana/Abajb+YhpdaImNZ7U8xizwU+vuNTQ2LYKPXOzCnKm5w/M9h3if7vu7ts17+JPK0ncj/j/e0TyUK1x95oXmAOloUM6g8GXIMxu1UJdQAAAABJRU5ErkJggg==
""")
ICON_FILTER3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAglJREFUOE9VVEeSBDEII/z/yTZbCnh6Lx0wBiEEGRkTEZGRga+J4TffCdta4EUXPVNeNsSkzmlN222D1cGZxp4KtTcZAHFtEoRPwDP4/UZWMLoRUEZlOaav4ihVET3tNzMZM4fZq3BpBMQO51wGqjZeg3WNKhv0+CVsMwx274msCtKQGfcc2nUOTs0Ry0MsM24EGZn8xMXsJtHnTFRXzLlEdY8QNxJcwJ6obJO7cJGIHObkTIDDznpdvnOF1NzcGaLOEmP8f2VKIXDIzByUM/dGNvhLIsPFYVCgjjj3KCGpkpzuvVE41y/NUBMxi7vmG+USPJD70uAclKiVBmSNGqCbAhe0XFywJBD/ETiQQgni9TAZ1bACNmjAF8IEEhBdQSQFwo0EiLPIGVI2qQhTpCZS75aOhP7k0cwK3XU1y21ob1KlkwpXAtuAQ+vPQS3fzVi8zC6iSeyoLqgB+l7Rv7nj3LvRko272Cr1sssQ+UR38R9BCpVQPsMGSdYqlwoimEySg+521a80Eqwuo3wFhVabDdtk28ydOygHE8aLSLW62rTIzvI9HSxnV91oLN//zjLOkdHK+a0kzrP2n4rB5HgDmVsNi0XG6bGwuYYcYN/S1Sbatev1SHH/Ov7bTg64eT8bleSTD47pv10uNyfbhlDSb2N7RnVR0icGsqxV9jTIznK1eGvv/sz4AzlJjSv4gUIUAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "change": {
        "de": "Filter",
        "en": "Change",
    },
    "the": {
        "de": "",
        "en": "the",
    },
    "filters": {
        "de": "wechseln!",
        "en": "filters!",
    },
}

def main(config):
    lang = config.get("lang", "en")

    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_FILTER1),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 1, 0),
                                        child = render.Text(LOCALIZED_STRINGS["change"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 1, 0),
                                        child = render.Text(LOCALIZED_STRINGS["the"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 20, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["filters"][lang]),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_FILTER2),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 1, 0),
                                        child = render.Text(LOCALIZED_STRINGS["change"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 1, 0),
                                        child = render.Text(LOCALIZED_STRINGS["the"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 20, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["filters"][lang]),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_FILTER3),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 1, 0),
                                        child = render.Text(LOCALIZED_STRINGS["change"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 1, 0),
                                        child = render.Text(LOCALIZED_STRINGS["the"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 20, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["filters"][lang]),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
