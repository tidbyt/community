"""
Applet: Things Wife Says
Summary: Show phrases
Description: Enter phrases your wife says and app will cycle through them.
Author: vipulchhajer
"""

load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

default_phrase1 = "It's fineee"
default_phrase2 = "Is it really tho?"
default_phrase3 = "That's hella tight"
default_phrase4 = "I'm gonna sleep in"
default_phrase5 = "I'm taking a short nap mmmkay?"

#Load images
WIFE1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAAAAXNSR0IArs4c6QAAAXZJREFUSEvNlq0OAjEMgHcPgQAH4iyKN8ASFBJHUAgUr0CCQqAIjicgJCjeAIVFgAPBQxzpwpberu16ByHM3HEt/fq3bon58UqUvEypF7UXVTDGZGkztbzL7UJyA7loUxJaEEDcU4qScIq0LQKVacypIed+AwT6G6oG5hrkftyYRndkwicYhm94gR6zPDz0wteNMqhNcQDOMQphp800g0bB3tcfNct61J8kk5IjaDkgGEuGfQvKtrsClJNXBrr6ARC/u1A5uRboaxg2hLZ+2JH3u5xSyNwnDUMA4RPbpbZUXwaKEfo9SKV0312Z3nHisxv+ZvakLqVclABxC8MjA0BOqZuHXJQlgfEI8elQtlvxlKEGOTVg/fkHkYRTR9oe4SylhjgJdBPfATGEipgb2qWB1AmvBaIDOV7D6frMZm7WOhVki2un8O0wH7griQycrs/RCxOGUjBMX47bnwPBIEBjMND7GlA7zP8PqPW8qp7mIlzVNvm/F7LJ0x29lys8AAAAAElFTkSuQmCC")
WIFE2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAAACXBIWXMAAAsTAAALEwEAmpwYAAAF+mlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDUgNzkuMTYzNDk5LCAyMDE4LzA4LzEzLTE2OjQwOjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ0MgMjAxOSAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIzLTEwLTAxVDE4OjAzOjUwLTA0OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMy0xMC0wMVQxODowNToxNy0wNDowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMy0xMC0wMVQxODowNToxNy0wNDowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpkZmMyYjk4Zi0zMjNhLTE2NGUtYmFiNi1iYzI4MmQ5MDY1OWEiIHhtcE1NOkRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDo1OTFiNGM3ZS04ZTM4LTgxNDQtYWExMy05MjhlYjM4MWE4ZDgiIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpmNmQ1MGJlYy02MWQ2LTVlNDgtYjRhMS0zYzc3MDkwMzlhNmEiPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmY2ZDUwYmVjLTYxZDYtNWU0OC1iNGExLTNjNzcwOTAzOWE2YSIgc3RFdnQ6d2hlbj0iMjAyMy0xMC0wMVQxODowMzo1MC0wNDowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTkgKFdpbmRvd3MpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpkZmMyYjk4Zi0zMjNhLTE2NGUtYmFiNi1iYzI4MmQ5MDY1OWEiIHN0RXZ0OndoZW49IjIwMjMtMTAtMDFUMTg6MDU6MTctMDQ6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE5IChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5x/RTrAAAA50lEQVRIic3VzQ3CMAwF4KzCpWdGYwemgBMSE7AEdyYyaqVUTmS/PJw0AumJVkn9NT+QJCJpZsob/yNk7Id/BGU5LVs8qGoPg3sRhDloUYwGI7FGeiioUBosHn4/ruZ3vtbxXgCBxTrUBdlUIB5hBnUBeb62eIDVHgbXQvvUGKjXHga961Y7C4o1pZ3ryO3SgSDcpUeAeEoReEtneN81pQjNIX+H7SlFGycAtkfY82+jsVyHAvVxE8EUyK2hd+gyUBi0irCgeuE2eLl/3Fig1U8fxBBEmIW2+g4BM8r0Gway+S9wRqaDX+W4s0MYj2+tAAAAAElFTkSuQmCC")
WIFE3 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAAACXBIWXMAAAsTAAALEwEAmpwYAAAF+mlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDUgNzkuMTYzNDk5LCAyMDE4LzA4LzEzLTE2OjQwOjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ0MgMjAxOSAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIzLTEwLTAxVDE4OjAzOjUwLTA0OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMy0xMC0wMVQxODowNTo0OC0wNDowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMy0xMC0wMVQxODowNTo0OC0wNDowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDo3ZGEzOTFmZi1iNjE2LTQzNDUtYTVkYS0wMWRkMTRiOWM2ZGUiIHhtcE1NOkRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDoyZGNiZTYwZS0wNWIyLTk3NDMtOTJiOC1hM2NhMTY5OTJmM2YiIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDo4YzlkOTI4My1kOTI4LTZmNGUtYmY0YS01MmFmZjY2YjYwMTQiPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjhjOWQ5MjgzLWQ5MjgtNmY0ZS1iZjRhLTUyYWZmNjZiNjAxNCIgc3RFdnQ6d2hlbj0iMjAyMy0xMC0wMVQxODowMzo1MC0wNDowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTkgKFdpbmRvd3MpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo3ZGEzOTFmZi1iNjE2LTQzNDUtYTVkYS0wMWRkMTRiOWM2ZGUiIHN0RXZ0OndoZW49IjIwMjMtMTAtMDFUMTg6MDU6NDgtMDQ6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE5IChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5nmNajAAAA5klEQVRIic3VzQ3CMAwF4KzCpWcG48AQLAHXTsAoTGREpVROZL88nDQq0hOtkvprfiBJRNLMlDf+R8jYD/8JynJZtnhQ1R4G9yIIc9CiGA1GYo30UFChNFg8vD5u5ne+1vFeAIHFOtQF2VQgHmEGdQFZ31s8wGoPg79C+9QYqNceBr3rVjsLijWlnevI7dKBINylR4B4ShH4TFd43zWlCM0hf4ftKUUbJwC2R9jzb6OxXIcC9XETwRTIraF36DJQGLSKsKB64TZ4f33cWKDVTx/EEESYhbb6DgEzyvQbBrI5Fzgj08EvBBJ3d9v5UF0AAAAASUVORK5CYII=")
WIFE4 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAAACXBIWXMAAAsTAAALEwEAmpwYAAAF+mlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDUgNzkuMTYzNDk5LCAyMDE4LzA4LzEzLTE2OjQwOjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ0MgMjAxOSAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIzLTEwLTAxVDE4OjAzOjUwLTA0OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMy0xMC0wMVQxODoxMjoyOC0wNDowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMy0xMC0wMVQxODoxMjoyOC0wNDowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDo0NzM0MTRhMy02ZjU3LTg1NDgtYjExNS00NDdhZjVjMjgxOWMiIHhtcE1NOkRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDo3ZDliN2I2Yi1lMDM2LTBkNGYtYTk5NS1jZTdmZjM3OTBhYzYiIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDphZWI0ZGE0OS03NWQ3LTRlNGUtYTAxOS0zNDE5NDJmMTU3YTAiPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmFlYjRkYTQ5LTc1ZDctNGU0ZS1hMDE5LTM0MTk0MmYxNTdhMCIgc3RFdnQ6d2hlbj0iMjAyMy0xMC0wMVQxODowMzo1MC0wNDowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTkgKFdpbmRvd3MpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo0NzM0MTRhMy02ZjU3LTg1NDgtYjExNS00NDdhZjVjMjgxOWMiIHN0RXZ0OndoZW49IjIwMjMtMTAtMDFUMTg6MTI6MjgtMDQ6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE5IChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz6BSpw2AAAA/ElEQVRIib2WQQ4CIQxFOZIX8g6ewVto3HkC927d6xlMvEYNJGjF3/YPKJP8DJNCH5TSIYlImqnPD+O5X9ZCCo5fBMyOHtdtkQVq7H3A6ki/PYFJLQf2CK30r0C1Wg74Nfh8gO/a1rImYALb/Wodsmoz1wOmV6IoB3I8FVkAZO8GZkd5G8pWAKhlp4D5aYHZEWpHdnaFgkI6uI9+SEcTBiXObKAfUg+4Syv3eyikHrSKPIdxSL3E6QDGpW2k2qBCTgH176YHpos4Vbytny4D6gZCJyRQRSkGbvY3UwgI+71vCz7QgyFo2PcXwApl+oXHggWyCq8YU4EzNB34BO0OlT/PCU76AAAAAElFTkSuQmCC")

def main(config):
    PHRASES = [
        config.str("phrase1", default_phrase1),
        config.str("phrase2", default_phrase2),
        config.str("phrase3", default_phrase3),
        config.str("phrase4", default_phrase4),
        config.str("phrase5", default_phrase5),
    ]

    WIFE = None

    wifeSelect = config.str("wife-preset", 1)

    if (wifeSelect == "4"):
        WIFE = WIFE4
    elif (wifeSelect == "3"):
        WIFE = WIFE3
    elif (wifeSelect == "2"):
        WIFE = WIFE2
    else:
        WIFE = WIFE1

    random.seed(time.now().unix // 60)
    index = random.number(0, 4)
    phrase = PHRASES[index]

    return render.Root(
        child = render.Box(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Box(
                        color = "#333333",  #remove color background if picture is used
                        child = render.Image(src = WIFE),
                        width = 28,
                        height = 28,
                    ),
                    render.Box(
                        child = render.Marquee(
                            height = 30,
                            offset_start = 6,
                            offset_end = 6,
                            child = render.WrappedText(
                                content = phrase,
                                width = 30,
                                # color="#f44336"
                            ),
                            scroll_direction = "vertical",
                        ),
                        width = 34,
                        height = 32,
                        padding = 2,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "phrase1",
                name = "phrase 1",
                desc = "a thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase2",
                name = "phrase 2",
                desc = "another thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase3",
                name = "phrase 3",
                desc = "third thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase4",
                name = "phrase 4",
                desc = "fourth thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase5",
                name = "phrase 5",
                desc = "fifth thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "wife-preset",
                name = "Wife Preset (1-4)",
                desc = "Wife Preset",
                icon = "faceSmile",
            ),
        ],
    )
