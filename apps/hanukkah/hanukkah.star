"""
Applet: Hanukkah
Summary: A Tidbyt Hanukkah Menorah
Description: Displays a Hanukkah Menorah during the holiday with the correct number of candles. Also displays a countdown to Hanukkah before the holiday!
Author: Bryan Slavin
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

# Defaults
DEFAULT_LOCATION = {
    "lat": 40.758896,
    "lng": -73.985130,
    "locality": "New York, New York USA",
    "timezone": "US/Eastern",
}

DEFAULT_FONT = "CG-pixel-4x5-mono"

ALT_FLAME_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAx0lEQVRoBe3RoQrCUBSA4XO36ZIKYrEMwxCjYDCbfQAfwCdQfIRFX8RqswzEsigGkQkigsFgUhiCu3OLewXvf+GEc9r/XREeAgggYLCAKtpfUTVSVvbY7GT8zXR3skgvppg466nftCvXoU5V0nHraR7uizyNAZDsLMHnYGsdi85u/dDzvIEpv190OsewNW/33iq+K9nuT6MkqbkmAZRag5k0SgcWBGS1tK18kEAAAQQQQAABBBBAAAEEEEAAAQQQQAABBP5C4AeI8S0Wa9XInwAAAABJRU5ErkJggg==
""")

FLAME_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAkklEQVRoBe3QIRKCQBSA4bcuK90xb/IAzhDInIUbEM1eSA5AZogGgxSHajAA88bg4kHe/9/g/0QIAQQQsC4w9/t+GcLNokPW1qeDD68y/ZxaBJBtlOv37lN6StqmcxdjLCxB7B7dsVk/wc3v3Km/VKqaWwLgFQEEEEAAAQQQQAABBBBAAAEEEEAAAQQQQAABQwJ/E1ggSHCAkpcAAAAASUVORK5CYII=
""")

CANDLE_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAeklEQVRoBe3UsQ2AIBRFUULopHACNnAS53QrOxoqncDoIwGXeJfkh9/eE0IIHAQQQAABBBCwFrjuWjS7I0Ia0YfuTbO6IcQR/Ope3OJ77wTI2h93AMf+/wVYxvfo+Qme2putAuEIIIAAAggggAACCCCAAAIIIICAk8AHfoQKv0cwj+IAAAAASUVORK5CYII=
""")

MAIN_MENORAH_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAACXBIWXMAAC4jAAAuIwF4pT92AAACTUlEQVRoBe1ZvUoDQRDeeMZAjGhiEKsDxcLCQhQJgo1gpY02voCNtaWNCHkAX8AXsDH6AGlEjBYWChb+IUZUNCZiNEdEL34T70I8EW4lmwlcBiZ7l539Zua73dn7EaIpfAzkU22p1wP/Fl8EQrRyOd9eGIho/quY+ekzuGJg9Vs6E/HikWaap8IsXQ8ndV0f5QiohcMp+TxJRpfecn5f/jHgM7TlScMwAlyxsPnN5tI70Ge2AOCYbQZYSZfQtnuZgBCS//Q0AZeZgs/LBIj+aJCWAZuw3QdYGZ+jvWfLHo5ZCZha26O9/5KTAO5doA3Jj3mZgCckb3qZAM7cy77LS2BkZSNB+lc0qvudflX7q8a3i+CQMwjHuep+hzuh2l8Fn7sIOhOv+3mTgLpT3mAOmzOgwS5I3cOxdwF6Igsr9N4riS1rLwkvIhiQo0H2EkjiOIz9cZP+VCBZYJK6FVl7t7jCypEuNuUsKs/iVscs/stDH6izSuieneT9u/n1+9/+fiBRDBcOxP/i2TB/je+BQQc0cbg6P0fGFQLoxCIhhsMCnddB+uCDZqGTAFWugwDet5NX5cQ1LgjPQlkfhuwi6DroGhumgVcuRjXGdQ1nF0HXA2psGALeS40xpeB+1ACpkRLGmObTMJ+BjkP1qqFdOKZ3gmdQKrz0fiADpRp0C13HepXZPTBETpQSgMQXEU4c2m2FRR9B7qD2i9BB6/gGLc0G+jpEFZxmpgalXecYJCh7a6SaAFrfndAPqB8qI0UY04dTmiUTIGFXZrBb2y9APpyWjITdDwAAAABJRU5ErkJggg==
""")

MAIN_MENORAH_IMAGE_26 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAaCAYAAAAHfFpPAAAACXBIWXMAAC4jAAAuIwF4pT92AAACd0lEQVRYCeVYS0tbQRS+1zxErYqVKhKJZieujI9FN120brq0QhfSFqG/om5ExL3+A90Ktv4B1xGpqYsiuCpRS6HQhESbh9VrvxPnhHH0olecnEUOfMzrzHl8mXPn5jqOoJxsR1OnO5FNwRCcJinn35Z7ekMRL+m6zovLw5H2eDwekohFjIDEeH4JyTdHWy+6PDex5XlesqEIOP7e/qFUCDvFXMSpNL2bqFQqUQkCRH1mc0dfgUvJIMRKQCVNyZ81MgEdmWxJMn+5W0BlXR542lKQZCAs6Ry+j4CcZAyiBEwup54jeVeSAOmH4CmS7xAnYHR+vZvgF4jFdboBPNOvRX9VV7p9LoF1FcQrMxg1trXud/xt+eP0avaZgASv+LS21023tv3V7DMBN46hEZHtdcPdzbIwFB4tHumHoJFX/YcNTwCXAFEfsch/c0DbQfUDmq/m+o828Qn4g34M18ProJbuqd8KPYIpfrXsp2/uDzxWOcawkXK+egvD5Cj6q8AAsAHkAV2m1OCLPqn171p/o3Q/a3uo+xF4AqzQQBM/fVa5y5/feicMTAMZYDa98DbtskWQQKysAUnghOdVy3/ZWox5Hj50PQ4DFMMvNqTah9pjM3776a1zF5hB8j9JuUYADUACfZWh50K9PlJk4KsTwdiuebi5XfSHoINA6NW0bh8oQPhv+KvW4u3h2Z+9dgJsuUOifbA9BAwCXQDLHDp0XBcBKrsi8BegH6GAH2QPrVWxSgASf4no3wPDQD/QBlByXGLP0Cehk0BCt8KFQhntPnAAIj6htSK2CfiBqAe1yClxvcS49s8xHwLMeOiupveTMZCQRvvo8h+2raqd8MEEUAAAAABJRU5ErkJggg==
""")

def main(config):
    timezone = config.get("timezone") or "US/Eastern"
    if (not time.is_valid_timezone(timezone)):
        timezone = "US/Eastern"
    current_time = time.now().in_location(timezone)
    # Used for testing
    # current_time = time.time(year = 2023, month = 12, day = 15, hour = 23, minute =0, second = 0, location = timezone)

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
        location = config.get("location")
        loc = json.decode(location) if location else DEFAULT_LOCATION

        now = time.now().in_location(loc.get("timezone"))

        lat = float(loc.get("lat"))
        lng = float(loc.get("lng"))
        sunsetTime = sunrise.sunset(lat, lng, now).in_location(loc.get("timezone"))

        candles = []
        if sunsetTime == None:
            sunsetText = ""
        else:
            sunsetText = "%s" % sunsetTime.format("3:04 PM")
            #candles.append(render.Text(sunsetText))

        # Figure out how many candles to show
        num_candles = int((current_time - hanukkah_first_day).hours / 24) + 1

        # Magical Offsets for the candle images
        offset_widths = [184, 168, 152, 136, 112, 96, 80, 0]

        # Lay out the candles
        for i in range(0, num_candles):
            candles.append(render.Box(width = offset_widths[i], child = render.Image(src = FLAME_IMAGE)))
            candles.append(render.Box(width = offset_widths[i], child = render.Image(src = CANDLE_IMAGE)))

        # Insert the base menorah
        candles.append(render.Image(src = MAIN_MENORAH_IMAGE_26))

        # Render as a flat stack
        main_child = render.Stack(children = candles)

        if (sunsetTime != ""):
            sunset_row = render.Marquee(width = 64, child = render.Text(font = DEFAULT_FONT, color = "#0000ff", content = "Sunset tonight: " + sunsetText))
            main_child = render.Column(main_align = "start", cross_align = "start", children = [sunset_row, main_child])

    return render.Root(
        show_full_animation = True,
        delay = int(config.get("scroll", 64)),
        child = main_child,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the sun rise and set times.",
                icon = "locationDot",
            ),
        ],
    )
