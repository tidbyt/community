"""
Applet: DiscoverCashback
Summary: Discover Cashback
Description: Displays the current Discover cash back category.
Author: Denton-L
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")

URL = "https://card.discover.com/cardissuer/public/rewards/offer/v1/offer-categories"
TTL_SECONDS = 60 * 60 * 24
WIDTH = 64
DISCOVER_PNG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IB2cksfwAAAARnQU1BAACx
jwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAABBtJREFU
OBEBEATv+wH///8BAAAAAAAAAAAAAAAAhi0LKAYAAFgIAgA+CAEAFgMAAf4AAgDm/gEAvgIDAaZh
yvPkAAAAAAAAAAAAAAAAAf///wEAAAAAhS0LBAYBAIIRAgFuFAMAChIGAQALBwIABQUCAAABAAD7
/f8A8fr+7un4/4JZy/OSAAAAAAAAAAAB////AYYtCwQHAQCoGwMBUhsJAQAVDgUACQoDAAMFAgAC
AgAAAQEAAAEBAQAA//8A9fn9AOnz/IQ6uvB+AAAAAAIAAAAABgEAgh0EAVIjDQIAHBYHAA0QBQAE
BwIAAgMAAAABAQD/AQEA/wIAAAEGAQAPEgUAJR8IfONhFlYAAAAAAYguCjkbAwHEKA0DAhYVBgAE
BgIAAAAAAAAAAQABAQAAAQIAAAADAAACAwAAAQQBAAEEAAACBAEAAgUA7AEEADQECQEBXBcGAQIU
EQUABQcDAP8AAAABAAAAAQIAAAECAAABAwAAAQQBAAEEAAABBAEAAgMAAAEFAAAABAAUAQUBUgQJ
AgAwEQkDAAcJAwAAAQAAAgEAAAEBAAABBAAAAQMAAAEEAQABBAEAAgQAAAEEAAAABAAAAgQBAAEF
AQAABAE0BAcCAQoMCQIAAgUBAP8AAQABA/8AAgMAAAEEAQABBAEAAQQAAAIEAAAABAAAAQQBAAEF
AQABBAAAAQQBAAEEARIE+gMG+AcGAAACBAEAAAEAAAEEAQABBAEAAQMAAAEEAAABBQAAAQQBAAEF
AQABBAAAAQQBAAEEAQABBAAAAQMA8AIEAPzQAAQBAAIGAAACBwAAAQYBAAIGAAACBwAAAggBAAIH
AQACCAEAAgcBAAIHAgACBwEAAgcAAAIGAQACBgLOAv4B/aj4AP8AAwYCAAEGAQADBwEAAgcBAAII
AQACCAEAAggCAAIIAgACCAEAAgcBAAIGAQACBgIAAQYC+gAEAbACYsj0wuz6/bYCBf8AAwgBAAII
AAACCQEAAggBAAIHAgACCAEAAgYBAAIGAQACBgEAAQYCAAEFAQABBACaB2Pf3AIAAAAA7fn/aPX8
/94ECQEAAggBAAIHAQACCAIAAgcBAAIGAQABBgAAAQYBAAEGAQABBQAAAAMAygABAHoAAAAAAgAA
AABQufHk+P4CRgIIAsYCBwIAAggCAAIGAQABBwAAAQYBAAIGAgABBQEAAAMAAAABALIAAABMBl/f
9AAAAAAB////AQAAAAAAAAAA+IweBv8FAV4BBQBgAQMBKAEEAQAAAwEAAAH//gAAANAAAACcBl/f
qgAAAAAAAAAAAAAAAAH///8BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAxe12zqdHpWoAAAAASUVORK5CYII=
""")

def main():
    res = http.get(URL, ttl_seconds = TTL_SECONDS)
    if res.status_code != 200:
        return []

    parsed = json.decode(res.body())

    category = None
    for quarter in parsed["quarters"]:
        if quarter["offerStatus"] == "qualification":
            category = quarter["title"]
            break

    if not category:
        return []

    return render.Root(
        render.Column([
            render.Padding(
                render.Row(
                    [
                        render.Image(src = DISCOVER_PNG),
                        render.WrappedText("5% Cash Back"),
                    ],
                    main_align = "space_between",
                    cross_align = "center",
                    expanded = True,
                ),
                pad = 4,
            ),
            render.Marquee(render.Text(category), width = WIDTH),
        ], main_align = "space_between", expanded = True),
    )
