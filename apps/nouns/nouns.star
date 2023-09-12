"""
Applet: Nouns
Summary: Show current Noun auction
Description: Displays the Noun currently under auction and bid details.
Author: miracle2k
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("time.star", "time")

def main():
    screen = render_screen()
    return render.Root(child = screen)

def render_screen():
    rep = http.post(
        "https://api.goldsky.com/api/public/project_cldf2o9pqagp43svvbk5u3kmo/subgraphs/nouns/0.1.0/gn",
        body = json.encode({
            "query": """
                query {
                    auctions(first:1, orderDirection: desc, orderBy: endTime) {
                        id,
                        amount,
                        startTime,
                        endTime,
                        bidder {
                            id,
                        },
                        settled
                        noun {
                            id,      
                        }
                    }
                }
            """,
        }),
        headers = {
            "content-type": "application/json",
        },
        ttl_seconds = 60,
    )
    if rep.status_code != 200:
        fail("nouns request failed with status %d", rep.status_code)
    auction = rep.json()["data"]["auctions"][0]

    img_data = http.get("https://noun.pics/{}.jpg".format(auction["noun"]["id"]), ttl_seconds = 3600 * 6).body()
    img = render.Image(src = img_data, width = 32)

    ether = int(auction["amount"]) / 1000000000000000000

    time_text = humanize.relative_time(time.now(), time.from_timestamp(int(auction["endTime"])))
    time_text = time_text.replace(" hours", "h")
    time_text = time_text.replace(" hour", "h")
    time_text = time_text.replace(" minutes", "m")
    time_text = time_text.replace(" minute", "m")
    time_text = time_text.replace(" seconds", "s")
    time_text = time_text.replace(" second", "s")

    # render two columns
    return render.Row(
        expanded = True,
        children = [
            img,
            render.Box(
                color = "#000000",
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    #main_align="space_around",
                    main_align = "space_evenly",
                    children = [
                        # Without this box, the text centering
                        # of the middle row depends on the length
                        # of the last row...
                        render.Box(
                            height = 6,
                            child = render.Text("{}".format(auction["noun"]["id"]), font = "tom-thumb", color = "#ffffff"),
                        ),
                        render.Row(
                            children = [
                                render.Text("Ξ", font = "5x8", color = "#ffffffcc"),
                                render.Text("{}".format(humanize.comma(ether)), font = "tb-8", color = "#ffffff"),
                            ],
                        ),
                        render.Text("{}".format(time_text), font = "tom-thumb", color = "#ffffff77"),
                    ],
                ),
            ),
        ],
    )
