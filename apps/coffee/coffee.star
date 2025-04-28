load("encoding/base64.star", "base64")
load("render.star", "render")

ICON_COFFEE_1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAc9JREFUOE91VNu27CAIA/3/T67skwvoPJyuNdPWCoQkkpFRWRmRFRWJ16iIyAi9l974z8Xf7+FLO7CHT4loJ8XNabMTRhSz4UIZ3IhEz37HC2sKjWExuTYqiRACKVe9xJIukgLH3rBEhOq6m9XHiSYVTwAiDGWoYEaVZCHmMk94FgKn7B60W62aFiH64d6fyNflsdvsKiooukWSHh00/Qwj+GARh2hBf4SQgv/h+LfDEeF8x0jGOK2jUYgblN+5jLDxsnlrZA3qHKISf73YBI+7DOd6JNdmKvqwqknNOPWNkR5tncCJZaRYayGYv1zSwCpjUeHf+egJ8Wn9rqevGBFKmBXnq9gbyBzHmyRWwja3jTueHG8J8F7bCE9kbjH76ggODjm0AeHFrnpPtEUBQlAkd2QucTi0us2PCdXqXKzaa8J7j6NahxhefY8EckEUux80zDmVEH22ezrBOvY5XZFJ27RP0DIyPCMLKvoUdWAX2ctdeIj0uW4tPZiUVFy4zWdOaCpV7LUGbItod2A4vJNF+2CF9kgPXfSGQuDsjlCPtctsFsfWzFiNsvrkR8rxqI64tZet5YHRAo7KM4JEn7gwtS2FxrRDNe+Gs7bDv4U/i8M+LfEMu3cAAAAASUVORK5CYII=
""")
ICON_COFFEE_2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAelJREFUOE9dVQuuwjAMc8a5BmdnnKvNU2yn3R5CqOvys+OEQCAjgQSA6B9dRPg+o8xk8/iUQ8rNrsuynOmxojxd9SqRPNS3UqiGShVZl9nuKpOVxq6GJ5YlQ6TqbItw8n1XSSPk4yzE77yE7cJVluAlq+GjqTJs0SQrlW3IAK7vhfN9moLE7/fDeb4NdOesCO3LPHxuRutV3Zqd6/ri837Tu5yu34XP+SnkNmnu2sOIOmqDNwGLcOEQFazmpobVeSqhK2QzlDXn9NkkkY8bry2PDBzHISL9KXTuPplkxDG7o5XEHXVAyqZc0ppsrSXwquB31alxgTHGhtT9N2R2zxWV7VEBA5gzeVZPS2otj3qYwyKyLxGHkwg9XcOQkZhzIlhh2T1mKjBzSvsdhForGtaAdVQcIZgV8Dhe3bAbqwBGDnaIQ5A9pzVJLf5NVFU1c5Cqhr/0rvz/K9xbY02Qeb3P/HFIMkvYGhW1n3x4BdHM3Wd3t5k0FsArBPU2mtwT2mEVcEzx1dK7LS3FNpYAdciOMpn8XanaL84Co6rsmCuw1NtbsZrQu7C1qbXWQ9IPPXBzL9Tn5isRVzAnoI72ovW2aZmoCYUqR4/UYmjtkKiArYDW3X3FSGOP/ev9uEE1T8/R87+G92MV+wegl0IrY/MGAAAAAABJRU5ErkJggg==""")
ICON_COFFEE_3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAfxJREFUOE9VVQG2wyAIAz1Xu7PXnkv5Lwlo/7a3rhZDSMC5uYUHv8zCzJwfC/52wzJeeUH4DuKaAg2Bjre7BdfyBTAECO+gRSVSOm4uwALZgFYMT5hhbbyP3dePBJB1vK/9rotwIhWsokiDbd3ywb+MZvY+j933D9hkNcaw+75TBoEKM5RE+MzDAlhIPhzPsN997UTveOwCWG5UktpHCfPeaQlLhDG4Q6pwJyOAlsRjvLrPGEXKE11ACKxzQXZKbprAJNJqs8dzdkTCZdnSlICkJfLYSAESIO3f5bGzWDSr6a2fhkqqXzoMnAv4UpewiVZttNuOBFJDN2sOcGzTPjmGfEss8SBtp550UF872Js0m3NZb00WlwSlwYwpfVInuS7BNRhKhlWWHGFrLWu9/WeoZg1bc50sSJceC796TRr3hrLdYk0C4rf0TdNxmbGy85NXzSXB067qud7IDjlblZy1JV3oAZ3Sy+yOI/MBPe3l1qBlTXhJXyfKAqNkVRVXqXu2imu49S63qTKJqLX26My1dESUL9V5zPyVwc07tstWaVca7oMhVVoSiaOYU/4tEdDd205as0ereDjUiXqmyRZAvyPJeZeDAKvpLanqoFAjfI409Rp0mdXXu78Sky1Co+qQyFMa/ZmlC5F/A5uWdCmQcyrvztx/F+kRCfwBig1fM8D/OLsAAAAASUVORK5CYII=
""")
ICON_COFFEE_4 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAgNJREFUOE9tVAGOwzAIM8m7lr292bsa7rCB9aSrJnVJgRjbxGDmgAMwWLzjZ+Db8h1/3CPm72P/7OdeFIuaDndjIR0BXHtjraXDAOy98Yo1D868jHa4YBFIVhAog7nj2h+s92pY+7qw3m8Wi4cFmGA6/VuQKxYNJIo3fD4b67W0Nse+tgpWMX3oDK7YXXOlgHiuSF6vWuLD9Vvksq0iJUsGVYWQgvC7OOQZZlCLK3kVwtcKhFKsOur/pjynEAE8qHhI3BQE+Wwv6ei4p5BySFbK3h04J3aLxWSLgfWU3sCYoxls8wWHElvsnHP+WCgWKSB5K7s8y0cnc0xJaWlscmcuhOqVdihPSurvAET4tMm4cx/YiPyI7yEo69yZV+YQlpyj9FrujUHEtx+MMendppuEm+EcFdRJ2RjB63u5Ib4MGzzq9psts7FomY6nusDx852ClqLHXbOebrUx4H7ovhFoxaH8IkMYjt8pcqpZ6KJpToFuD41cumHOVJsc0s19tdy3bFPzWobhZJTPHsXmjLaFuuZMYVE3bdMy1FVG/4pDZSs9fFiC5YesRA7rlBAmvFiocz+X1cwImzCnZkNeJrSU5TEODr8P15UgnhUSnqtrq+5AQS3b9IWaN0lQn1y2qtluFAjPFe99URFtXlxlWvEonqh7D3tCK4g5NWERlinVfxN/AHCkVywDeaBxAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "ready": {
        "de": "Fertig!",
        "en": "Ready!",
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
                            render.Image(src = ICON_COFFEE_1),
                            render.Text(LOCALIZED_STRINGS["ready"][lang]),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_COFFEE_2),
                            render.Text(LOCALIZED_STRINGS["ready"][lang]),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_COFFEE_3),
                            render.Text(LOCALIZED_STRINGS["ready"][lang]),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_COFFEE_4),
                            render.Text(LOCALIZED_STRINGS["ready"][lang]),
                        ],
                    ),
                ],
            ),
        ),
    )
