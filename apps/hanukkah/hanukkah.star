load("encoding/base64.star", "base64")
load("render.star", "render")
load("time.star", "time")

CANDLE_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAwElEQVRoBe3TMQrCMBTG8ZemsYNO4pzJAwgOnT2LN3B09kJ6gC4uxdHBQR2kLoJghSrBoYlPCR7C9wXCl/X/gxDhQAACEJAu0JSd8rExS4kO6Wo67Gtzyn2rnEQACgdavLba+z35UI0Ka+1YEkSyKwazZ21Uc82U0/OJcy6TBPBtvdXnNd+7uHAOTmJ04O1KBuhxfCsdQGL/7wuIjP9Ep7H8yHuJbwwEIAABCEAAAhCAAAQgAAEIQAACEIDAPwu8AYNcK2rAdvQuAAAAAElFTkSuQmCC
""")

MAIN_MENORAH_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAC4jAAAuIwF4pT92AAACTUlEQVRoBe1ZvUoDQRDeeMZAjGhiEKsDxcLCQhQJgo1gpY02voCNtaWNCHkAX8AXsDH6AGlEjBYWChb+IUZUNCZiNEdEL34T70I8EW4lmwlcBiZ7l539Zua73dn7EaIpfAzkU22p1wP/Fl8EQrRyOd9eGIho/quY+ekzuGJg9Vs6E/HikWaap8IsXQ8ndV0f5QiohcMp+TxJRpfecn5f/jHgM7TlScMwAlyxsPnN5tI70Ge2AOCYbQZYSZfQtnuZgBCS//Q0AZeZgs/LBIj+aJCWAZuw3QdYGZ+jvWfLHo5ZCZha26O9/5KTAO5doA3Jj3mZgCckb3qZAM7cy77LS2BkZSNB+lc0qvudflX7q8a3i+CQMwjHuep+hzuh2l8Fn7sIOhOv+3mTgLpT3mAOmzOgwS5I3cOxdwF6Igsr9N4riS1rLwkvIhiQo0H2EkjiOIz9cZP+VCBZYJK6FVl7t7jCypEuNuUsKs/iVscs/stDH6izSuieneT9u/n1+9/+fiBRDBcOxP/i2TB/je+BQQc0cbg6P0fGFQLoxCIhhsMCnddB+uCDZqGTAFWugwDet5NX5cQ1LgjPQlkfhuwi6DroGhumgVcuRjXGdQ1nF0HXA2psGALeS40xpeB+1ACpkRLGmObTMJ+BjkP1qqFdOKZ3gmdQKrz0fiADpRp0C13HepXZPTBETpQSgMQXEU4c2m2FRR9B7qD2i9BB6/gGLc0G+jpEFZxmpgalXecYJCh7a6SaAFrfndAPqB8qI0UY04dTmiUTIGFXZrBb2y9APpyWjITdDwAAAABJRU5ErkJggg==
""")

def get_hanukkah_dates(year):
    hanukkah_dates = {
        2024: "2024-12-25T00:00:00Z",
        2025: "2025-12-14T00:00:00Z",
        2026: "2026-12-04T00:00:00Z",
        2027: "2027-12-24T00:00:00Z",
        2028: "2028-12-12T00:00:00Z",
        2029: "2029-12-01T00:00:00Z",
        2030: "2030-12-20T00:00:00Z",
    }
    hanukkah_first_day = time.parse_time(hanukkah_dates[year])
    hanukkah_last_day = hanukkah_first_day + time.parse_duration("192h")
    return hanukkah_first_day, hanukkah_last_day

def main(config):
    tz = config.get("$tz", "America/New_York")
    current_time = time.now().in_location(tz)
    current_year = current_time.year

    if current_year > 2030:
        return render.Root(
            child = render.WrappedText(
                content = "This app only supports years up to 2030.",
                color = "#ff0000",
                font = "CG-pixel-4x5-mono",
            ),
        )

    hanukkah_first_day, hanukkah_last_day = get_hanukkah_dates(current_year)

    if current_time > hanukkah_last_day:
        main_child = render.WrappedText(
            content = "Hanukkah is over for %d.See you next year!" % current_year,
            color = "#0000ff",
            font = "CG-pixel-4x5-mono",
        )
    elif current_time < hanukkah_first_day:
        countdown_days = int((hanukkah_first_day - current_time).hours / 24) + 1
        if countdown_days == 1:
            main_child = render.WrappedText("Hanukkah starts tomorrow!", font = "tb-8", color = "#0000ff")
        else:
            main_child = render.WrappedText("Hanukkah starts in %d days!" % countdown_days, font = "tb-8", color = "#0000ff")
    else:
        num_candles = int((current_time - hanukkah_first_day).hours / 24) + 1
        candles = []
        offset_widths = [0, 80, 96, 112, 136, 152, 168, 184]
        for i in range(0, num_candles):
            candles.append(render.Box(width = offset_widths[i], child = render.Image(src = CANDLE_IMAGE)))
        candles.append(render.Image(src = MAIN_MENORAH_IMAGE))
        main_child = render.Stack(children = candles)

    return render.Root(child = main_child)
