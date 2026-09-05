"""
Applet: Treasury Rates
Summary: U.S. Treasury yields
Description: Displays current U.S. Treasury yields for 2Y, 5Y, 10Y, and 30Y maturities, plus the 2s10s spread.
Author: John Hendrickson
"""

load("http.star", "http")
load("render.star", "render")

DATA_URL = "https://www.bema.my/tidbyt/treasury-rates.json"

FONT = "tom-thumb"
VALUE_FONT = "tb-8"
WHITE = "#f7f7ff"
MUTED = "#6b7c93"
BLUE = "#69b8ff"
GREEN = "#46e58f"
ORANGE = "#ff9f43"
RED = "#ff5d73"

def _fmt_rate(value):
    raw = int(float(value) * 100 + 0.5)
    whole = raw // 100
    cents = raw % 100
    if cents < 10:
        return "%d.0%d" % (whole, cents)
    return "%d.%d" % (whole, cents)

def _fmt_bps(value):
    raw = float(value) * 100
    bps = int(raw + 0.5) if raw >= 0 else int(raw - 0.5)
    if bps > 0:
        return "+%dbp" % bps
    return "%dbp" % bps

def _rate_cell(label, value, color):
    return render.Box(
        width = 31,
        height = 16,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(content = label, font = FONT, color = color, height = 6),
                render.Text(content = _fmt_rate(value), font = VALUE_FONT, color = WHITE, height = 7, offset = -1),
            ],
        ),
    )

def _status_line(as_of, source, stale):
    color = ORANGE if stale else MUTED
    label = "DAILY" if stale else source
    text = "%s %s" % (label, as_of[:5])
    return render.Text(content = text[:15], font = FONT, color = color, height = 6)

def _error_screen(message):
    return render.Root(
        max_age = 90,
        child = render.Column(
            children = [
                render.Text(content = "TREASURY", font = "tb-8", color = ORANGE, height = 7, offset = -1),
                render.WrappedText(content = message[:36], font = FONT, color = WHITE, width = 64, height = 18),
            ],
        ),
    )

def main():
    response = http.get(DATA_URL, ttl_seconds = 300)
    if response.status_code != 200:
        return _error_screen("rate feed failed %d" % response.status_code)

    data = response.json()
    rates = data["rates"]
    spread = data.get("spreads", {}).get("2s10s")
    if spread == None:
        spread = float(rates["10Y"]) - float(rates["2Y"])

    stale = data.get("stale", False)
    source = data.get("source", "RATES")
    as_of = data.get("as_of", "")
    if len(as_of) >= 16:
        as_of = as_of[5:16].replace("T", " ")

    rates_frame = render.Column(
        children = [
            render.Row(
                children = [
                    _rate_cell("2Y", rates["2Y"], BLUE),
                    _rate_cell("5Y", rates["5Y"], BLUE),
                ],
            ),
            render.Row(
                children = [
                    _rate_cell("10Y", rates["10Y"], GREEN),
                    _rate_cell("30Y", rates["30Y"], GREEN),
                ],
            ),
        ],
    )

    spread_frame = render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(content = "2s10s", font = FONT, color = ORANGE, height = 6),
                render.Text(content = _fmt_bps(spread), font = "tb-8", color = WHITE, height = 8),
                _status_line(as_of, source, stale),
            ],
        ),
    )

    return render.Root(
        max_age = 300,
        delay = 2500,
        show_full_animation = True,
        child = render.Animation(
            children = [
                rates_frame,
                spread_frame,
            ],
        ),
    )
