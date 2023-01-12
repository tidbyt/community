"""
Applet: Web 3 Counter
Summary: Expose web3 as a scam
Descrtion: Displays the total dollar value of lost assets due to crypto scams and crashes.
Author: Nick Kuzmik (github.com/kuzmik)
"""

load("cache.star", "cache")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

W3IGG_API = "https://web3isgoinggreat.com/api/griftTotal"

def main():
    total = get_total()

    return render.Root(
        child = render.Box(
            render.Column(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.WrappedText("Money lost to crypto so far", color = "#336699", align = "center"),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(width = 50, height = 8),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            # this will overflow when we hit 1 trillion... so like next week?
                            render.Text("$%s" % total, color = "#FF0000", font = "tom-thumb"),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_total():
    total_cached = cache.get("total_lost")
    if total_cached != None:
        total_lost = str(total_cached)
    else:
        resp = http.get(W3IGG_API)
        if resp.status_code != 200:
            fail("API request failed with status %d", resp.status_code)
        total_lost = resp.json()["total"]
        cache.set("total_lost", str(total_lost), ttl_seconds = 900)  # 15 minutes

    return humanize.comma(float(total_lost))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
