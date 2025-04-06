load("encoding/base64.star", "base64")
load("render.star", "render")

ICON_TRASH_CLOSED = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAgNJREFUOE9tVEmuwjAMddYtpwCORjlTy9HanoJ2na83OCnSRwiFDPYbbJeIqCUKfqJU/sFWYC9q1X8e4rzyRF9fLtjDhxfxDmF0mTG41qO8yvsZtO0ypR8wdxQ9i1pKiZo7vFQj9/zMKBi64RElBuDSOIFHVJCBCBlTiCVI/wio6FZGabS4TuJcMkjLEzFOD+kiIVuy47MLGX6IDlorrcEmwuogiVTYxVcM0qhEci5r0+9CSv5IiBLj697oX9j6WO7jwjGvaa4ckfaprPAi9PB60JTvvDbENCkijmVTwihck7hFxt6v7K6pcXry4DtvcZvu0t3ynp9NSWrE8dmkBoxzEf+YIiow48mL57zF+L67NPQQQZgEaOfdhX+pGXpk1tkxQICtY1ljwLrJJt2I0JKk2Lrj+k0Xs+1u05McUR4DDXLZ1AhQRhJAo8Pdy6is2WaKltgcJ7n8Xfa4vaChDEGS1BDqnMvuDpJU3ZQmupoRGqGMoOFgU7K14OzwRsH3svE0UBMw+aWNUPWkJJatp1VSuadGQELoT+1z5qgT3c0cEm65rK3e3K299MJlw3rqyqmws8eJSK0GWiotTRJiYhIlRfmkDGnmpbWNMcdQsmtlIK6cSzmAsz2oWJIG0tTwv7nrodCnimebx1uX1f1hs8Uxh55HlYeRRHfgNCoHuAeqFZNuf57vWy5dKYV9AAAAAElFTkSuQmCC
""")
ICON_TRASH_OPEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhBJREFUOE9lVMuxpDAMlM5AFDOEBhMTEBomCuDsXXW3DFXvAlX+yP2T3M2rWbXqZvh4NTePFYsli2+t+OOLxdiNFZ7gdnyw7xXFcs3N+unDg252LQcPVzf3anE4i+IRViYE7MWpxPN+qZp185iv2rnswJMoX0fFDnV1BgiDmhZwM0lV6+dvK3SuB6tKkmQnDViQFHiEKKp5TR2pa1xIxHHoXorV1Pv1OCizgPACnHRqvFQcyNy637cxuNddYJKyNAQ2aB8Ux7AKlqXowN8EfKXCzC4UZTbARzUbxH7+0OG12DCNpCaxzm23Yf4C1bmW5n7GR8HTBYCsNkx54bAonsrG8+dSVNDxIGOq7EY1sGr6Meb97wOq93pYh4J0LmQ4twJJQp6mn3wjbUdkqRXzQA0R6mLd/GVoEV5HHoeZMtyirAZjl/0JdlAOjaChEMIsIgyadDkoP2aoVwAEcSaCaJ8HYaDpfyO7WA6HEdma11YefbOL4HIjy6j0MuXeinWTKMdVr3A2YxUFKVW2XIZHQU536KwUVVtqmLSpAtO2ohajK+8+18iQKROHQoqdw0sDSojo+FOl7bJR0c/oX868blL+1OeUMfm5XcveJglTwMi1YDcdpGgOT3akTNEEfY8RtqtOR8BRV/xzBD0iP9M6hyiH30sOXs9l5RDzhlQxadr4lgw53mkBnFXe2Bk5vv5f/AdzJFkmDHdD4AAAAABJRU5ErkJggg==
""")
ICON_RECYCLE_OPEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAh1JREFUOE9tVFtSw0AMk8sRm5Sj0Md3X1dJyhGpGUnezTIDw6TJPmxZkh0AMoJP/gf4qo/+5JsP6Bzfva2fulp7QEREpg4kvxAJ7O/vupF4XXbDbe+nojhB+qPuClIkN507kMFFZ5+uDRWwnnm746nzDaIDElkAkVEZcqglnF4r851P5g18X3ixqCFcUVAUMVqniuV2XlxXUeX1SEw3o+ffejIVplUCVI2sUpSweuHQvhNvYhCEUjLw9e0SAbwYWMuuRhx2LAwQiT2RjGUUANNgAQfWsZZwjNQkch2Oh+n+o4+SH8vJB8Vl8xjRnT8G1V36JooUVhhxpWARWL8ShyeDA+sxMT8D6xE4PBKv887eHbRhFWLHaOwicQRg4cVnM3OqAxiUmecH8LoQ+V8aivWquGQlwpKnq0gky1dJjMSBAc+7zbtUonnY0lsac/j25fL8Z5Xs1muWSnxfPpqZS4BqPR0rdLw03X6wHG3Y+dGs49JIw/y0TcSh/Otm40l3W4ltLyb218R6AuZHlgDmcaEoTCC9EitV9lTZBoh92BAa5kR7uC+l/KryA/PdLmhTRgG34SO6+sAYUbLk1hVqwWotGbt6mm80dK307nOC1t8tXSRmenETdbtY3Uz+FPzvQBgnp3u4vP5/PxfpytNas7FXs1TGLksPg2GYNK0LamiIcHVHx18gbLkhoBWwOYvpNp5rZmmAVsAeb5i5hPELehlcK15Cc30AAAAASUVORK5CYII=
""")
ICON_RECYCLE_CLOSED = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAgxJREFUOE9VVFt26kAMk+kSKelSeH234S6lAZbYTo8l2cPlgyTzsGVZcgAxAgMjAhgDQCAin/qN/EZ9B8aolQHwTj+Q1yJ4xkGGAnAnn3kggzpBvjtLp2BQZSYQBsTQ4lA4fTKJ1mpfSOus4qgw3SOWrCf/eLXeMpOIMAUO3EhMQlMkhFlZl9y4jaB4I7dVE++8UMIESpq0JLCICC9NFEQ8BvarKShkDv24ZjolYm1ZMulxQNJkFO/rrw9OZNoL9kr8EhNX75e35jrRN4emgMdmUJW0nRXwsKrtLJvBdgpMqbjL3dSCH8DhK9thBCfgsArW/QQs/wLfx4HlBjwuu05AQGwKIptrCSegIMIsb2MAyym7HgPbUbwtt8D9Kn1Is6WJkm+rNhH+cHX6Q5e+T1PoH2uwZO3YAWRQEqaG2O7k8Kt4kxSWWzmnWicB3y8Sf/3kOBp3BssTiXA7qo8fFczkiz9aAs+zOEzZVGRZjxTSMoS//xy4n0X8dgosq/gpTks+j3N22TriTU+C4oCRR5b86+6Jx+wuka+yV/n5cdEAqcNTh/RtkRvYf/7Qk+WdiUIqKEzPdIyVXudbpoTrhAni3WWmMXs6+nSuPK8723iOr7ai1ChbyZsurXw2XftfeVqui55W9rSd/DpUp1+bNd5V8pJva9VTSKP6Zd7YOz2SCoSnpzrZsrRPehADf+vWRTHoQtxIAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "trash": {
        "de": "Müll",
        "en": "Trash",
    },
    "recycling": {
        "de": "Recycling",
        "en": "Recycling",
    },
    "trash_day": {
        "de": "rausbringen!",
        "en": "Day!",
    },
    "recycling_day": {
        "de": "Tag!",
        "en": "Day!",
    },
}

def main(config):
    lang = config.get("lang", "en")

    return render.Root(
        delay = 1000,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_TRASH_CLOSED),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["trash"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["trash_day"][lang]),
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
                            render.Image(src = ICON_TRASH_OPEN),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["trash"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["trash_day"][lang]),
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
                            render.Image(src = ICON_RECYCLE_CLOSED),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["recycling"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["recycling_day"][lang]),
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
                            render.Image(src = ICON_RECYCLE_OPEN),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["recycling"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["recycling_day"][lang]),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
