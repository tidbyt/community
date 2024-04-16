"""
Applet: Octopus Agile
Summary: Octopus Energy Agile Rates
Description: Gets the latest Agile Rates for Octopus Energy and shows the current price.
Author: sandeepb1
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

def main(config):
    timezone = config.get("timezone") or "Europe/London"
    now = time.now().in_location("Etc/UTC")
    nowISO = now.format("2006-01-02T15:04:05Z")
    #2024-04-15T13:19:00Z

    OCTOPUS_AGILE_URL = "https://api.octopus.energy/v1/products/AGILE-24-04-03/electricity-tariffs/E-1R-AGILE-24-04-03-A/standard-unit-rates/?period_from=" + nowISO

    octo = http.get(OCTOPUS_AGILE_URL)

    if octo.status_code != 200:
        fail(nowISO + octo.body())

    data = octo.json()
    count = data["count"]
    count = int(count) - 1
    nextRate = data["results"][count]["value_inc_vat"]

    color = "#FFF"
    if nextRate < 4:
        color = "#A3BE8C"

    if nextRate > 17:
        color = "#BF616A"


    img = base64.decode("""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""")
    return render.Root(
        delay = 60000,
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(
                        src = img,
                        width = 16,
                        height = 16,
                    ),
                    render.Text(
                        content = str(nextRate) + "p",
                        font = "tb-8",
                        color = color
                    ),
                ],
            ),
        ),
    )
