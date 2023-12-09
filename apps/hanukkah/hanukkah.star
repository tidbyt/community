"""
Applet: Hanukkah
Summary: A Tidbyt Hanukkah Menorah
Description: Displays a Hanukkah Menorah during the holiday with the correct number of candles. Also displays a countdown to Hanukkah before the holiday!
Author: Bryan Slavin
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CANDLE_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAwElEQVRoBe3TMQrCMBTG8ZemsYNO4pzJAwgOnT2LN3B09kJ6gC4uxdHBQR2kLoJghSrBoYlPCR7C9wXCl/X/gxDhQAACEJAu0JSd8rExS4kO6Wo67Gtzyn2rnEQACgdavLba+z35UI0Ka+1YEkSyKwazZ21Uc82U0/OJcy6TBPBtvdXnNd+7uHAOTmJ04O1KBuhxfCsdQGL/7wuIjP9Ep7H8yHuJbwwEIAABCEAAAhCAAAQgAAEIQAACEIDAPwu8AYNcK2rAdvQuAAAAAElFTkSuQmCC
""")

MAIN_MENORAH_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAC4jAAAuIwF4pT92AAACTUlEQVRoBe1ZvUoDQRDeeMZAjGhiEKsDxcLCQhQJgo1gpY02voCNtaWNCHkAX8AXsDH6AGlEjBYWChb+IUZUNCZiNEdEL34T70I8EW4lmwlcBiZ7l539Zua73dn7EaIpfAzkU22p1wP/Fl8EQrRyOd9eGIho/quY+ekzuGJg9Vs6E/HikWaap8IsXQ8ndV0f5QiohcMp+TxJRpfecn5f/jHgM7TlScMwAlyxsPnN5tI70Ge2AOCYbQZYSZfQtnuZgBCS//Q0AZeZgs/LBIj+aJCWAZuw3QdYGZ+jvWfLHo5ZCZha26O9/5KTAO5doA3Jj3mZgCckb3qZAM7cy77LS2BkZSNB+lc0qvudflX7q8a3i+CQMwjHuep+hzuh2l8Fn7sIOhOv+3mTgLpT3mAOmzOgwS5I3cOxdwF6Igsr9N4riS1rLwkvIhiQo0H2EkjiOIz9cZP+VCBZYJK6FVl7t7jCypEuNuUsKs/iVscs/stDH6izSuieneT9u/n1+9/+fiBRDBcOxP/i2TB/je+BQQc0cbg6P0fGFQLoxCIhhsMCnddB+uCDZqGTAFWugwDet5NX5cQ1LgjPQlkfhuwi6DroGhumgVcuRjXGdQ1nF0HXA2psGALeS40xpeB+1ACpkRLGmObTMJ+BjkP1qqFdOKZ3gmdQKrz0fiADpRp0C13HepXZPTBETpQSgMQXEU4c2m2FRR9B7qD2i9BB6/gGLc0G+jpEFZxmpgalXecYJCh7a6SaAFrfndAPqB8qI0UY04dTmiUTIGFXZrBb2y9APpyWjITdDwAAAABJRU5ErkJggg==
""")

def main(config):
    timezone = config.get("timezone") or "US/Eastern"
    if (not time.is_valid_timezone(timezone)):
        timezone = "US/Eastern"
    current_time = time.now().in_location(timezone)
    # Used for testing
    # current_time = time.time(year = 2023, month = 12, day = 6, hour = 23, minute =0, second = 0, location = timezone)

    # First Day of Hanukkah
    # TODO: Look up for future years - hardcoded for 2023
    hanukkah_first_day = time.time(year = 2023, month = 12, day = 7, hour = 0, minute = 0, second = 0, location = timezone)
    hanukkah_last_day = hanukkah_first_day + time.parse_duration("192h")

    # Is it currently Hanukkah?
    # Check if it is after Hanukkah
    if (current_time > hanukkah_last_day):
        msg = render.Text(
            content = "Hanukkah is over for 2023. See you on December 24, 2024!",
            color = "#0000ff",
            font = "tb-8",
        )

        row = render.Row(
            children = [
                render.Image(src = MAIN_MENORAH_IMAGE),
                render.Box(width = 15),
                msg,
                render.Box(width = 15),
                render.Image(src = MAIN_MENORAH_IMAGE),
            ],
            main_align = "center",
            cross_align = "center",
        )

        main_child = render.Marquee(
            width = 64,
            child = row,
        )

        # Check if it is before Hanukkah
    elif (current_time < hanukkah_first_day):
        # How many days before Hanukkah begins?
        countdown_days = int((hanukkah_first_day - current_time).hours / 24) + 1
        if (countdown_days == 1):
            msg = render.Text("Hanukkah 2023 starts tomorrow!", font = "tb-8", color = "#0000ff")
        else:
            msg = render.WrappedText("Hanukkah 2023 starts in %d days!" % countdown_days, font = "tb-8", color = "#0000ff")

        row = render.Row(
            children = [
                render.Image(src = MAIN_MENORAH_IMAGE),
                render.Box(width = 15),
                msg,
                render.Box(width = 15),
                render.Image(src = MAIN_MENORAH_IMAGE),
            ],
            main_align = "center",
            cross_align = "center",
        )

        main_child = render.Marquee(
            width = 256,
            child = row,
        )

        # It's Hanukkah!
    else:
        # TODO: Figure out whether to show the candles being lit depending on time of day

        # Figure out how many candles to show
        num_candles = int((current_time - hanukkah_first_day).hours / 24) + 1
        candles = []

        # Magical Offsets for the candle images
        offset_widths = [184, 168, 152, 136, 112, 96, 80, 0]

        # Lay out the candles
        for i in range(0, num_candles):
            candles.append(render.Box(width = offset_widths[i], child = render.Image(src = CANDLE_IMAGE)))

        # Insert the base menorah
        candles.append(render.Image(src = MAIN_MENORAH_IMAGE))

        # Render as a flat stack
        main_child = render.Stack(children = candles)

    return render.Root(
        child = main_child,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
