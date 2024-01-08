"""
Applet: TF Key Price
Summary: Key price via backpack.tf
Description: Keeps track of key price in refined from backpack.tf api.
Author: Trevor Underwood
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("secret.star", "secret")

KEY_PRICE_URL = secret.decrypt("AV6+xWcE05t1fBwRx2M0Zf3N2JINCILmJd7WuZg6u44qlJo+MclcPQ6ow2czfSgPkNh2kUFXDyR2EyfgIBRgBvcg2IhkTA5eNzx7YNXXb6YqjJnbPV5lDr3AYtq55tm62RCPG6SAvQZKOQ8YOD2A+QzAh2Y34pP86XLzF7/6gzhAje9dpyP8oGn8T6yCXPkIjyIfjyc=")

TF2_ICON = base64.decode("""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
""")

def main():
    rep = http.get(KEY_PRICE_URL, ttl_seconds = 240)
    if rep.status_code != 200:
        fail("Bakcpack.tf request failed with status %d", rep.status_code)

    rate = rep.json()["response"]["currencies"]["keys"]["price"]["value_raw"]

    return render.Root(
        child = render.Row(
            children = [
                render.Image(src = TF2_ICON),
                render.Column(
                    children = [
                        render.Marquee(
                            width = 32,
                            child = render.Text("Mann Co. Supply Crate Key"),
                        ),
                        render.Text("%d REF" % rate),
                    ],
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
            main_align = "space_between",
            cross_align = "center",
        ),
    )
