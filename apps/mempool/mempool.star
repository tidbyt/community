"""
Applet: Mempool
Summary: Mempool stats of Bitcoin
Description: Showing details of the mempool of Bitcoin, such as the latest block and current fee rates.
Author: PMK (@pmk)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("time.star", "time")

DEFAULT_FIAT = "usd"
URL_BLOCK_TIP_HEIGHT = "https://mempool.space/api/blocks/tip/height"
URL_BLOCK_DETAILS = "https://mempool.space/api/v1/blocks"
URL_FEES = "https://mempool.space/api/v1/fees/recommended"

BOX_SIZE_WIDTH = 28
BOX_SIZE_HEIGHT = 27
BOX_ORANGE_IMG = base64.decode("""
R0lGODlhHAAbAJEDAC0oJUA4NKp9DwAAACH5BAEAAAMALAAAAAAcABsAAAJMjI+pNz2wonQAyotatRi/LYTiSJbiBpjqiq4u2b5yLLt0rd54qe9j7wsBg0NfcXfEJWvLGSjIe0J/0qmwav2krCLNliuggEOOwVhQAAA7
""")
BOX_PURPLE_IMG = base64.decode("""
R0lGODlhHAAbAJEDACklSDs5dFNL0wAAACH5BAEAAAMALAAAAAAcABsAAAJMjI+pNz2wonQAyotatRi/LYTiSJbiBpjqiq4u2b5yLLt0rd54qe9j7wsBg0NfcXfEJWvLGSjIe0J/0qmwav2krCLNliuggEOOwVhQAAA7
""")

LINE_IMG = base64.decode("""
R0lGODlhAQAVAIABAP///wAAACH5BAEAAAEALAAAAAABABUAAAIHhIMGGMpaAAA7
""")

def main():
    response_block_tip_height = http.get(url = URL_BLOCK_TIP_HEIGHT, ttl_seconds = 30)
    if response_block_tip_height.status_code != 200:
        fail("Mempool.space (block-height) request failed with status %d", response_block_tip_height.status_code)
    block_tip_height = int(response_block_tip_height.body())

    response_block_details = http.get(url = "{}/{}".format(URL_BLOCK_DETAILS, block_tip_height), ttl_seconds = 30)
    if response_block_details.status_code != 200:
        fail("Mempool.space (block-details) request failed with status %d", response_block_details.status_code)
    block_details = response_block_details.json()[0]

    response_fees = http.get(url = URL_FEES, ttl_seconds = 30)
    if response_fees.status_code != 200:
        fail("Mempool.space (block-details) request failed with status %d", response_fees.status_code)
    fees = response_fees.json()

    box_orange = render.Stack(
        children = [
            render.Image(src = BOX_ORANGE_IMG, width = BOX_SIZE_WIDTH, height = BOX_SIZE_HEIGHT),
            render.Padding(
                pad = (5, 5, 1, 1),
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 21,
                            child = render.Text(
                                content = "NO PRIO: {}s/vB".format(int(fees["minimumFee"])),
                                color = "#fff000",
                                font = "tom-thumb",
                            ),
                        ),
                        render.Marquee(
                            width = 21,
                            child = render.Text(
                                content = "HIGH PRIO: {}s/vB".format(int(fees["fastestFee"])),
                                color = "#fff",
                                font = "5x8",
                            ),
                        ),
                        render.Marquee(
                            width = 21,
                            child = render.Text(
                                content = "LOW PRIO: {}s/vB".format(int(fees["economyFee"])),
                                font = "tom-thumb",
                                color = "#fff",
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )

    box_purple = render.Stack(
        children = [
            render.Image(src = BOX_PURPLE_IMG, width = BOX_SIZE_WIDTH, height = BOX_SIZE_HEIGHT),
            render.Padding(
                pad = (5, 5, 1, 1),
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 21,
                            child = render.Text(
                                content = "~{}s/vB".format(int(block_details["extras"]["medianFee"])),
                                font = "tom-thumb",
                                color = "#fff000",
                            ),
                        ),
                        render.Marquee(
                            width = 21,
                            child = render.Text(
                                content = "{} ({} txs)".format(
                                    humanize.bytes(int(block_details["size"])),
                                    int(block_details["tx_count"]),
                                ),
                                font = "5x8",
                                color = "#fff",
                            ),
                        ),
                        render.Marquee(
                            width = 21,
                            child = render.Text(
                                content = str(humanize.time(time.from_timestamp(int(block_details["timestamp"])))),
                                font = "tom-thumb",
                                color = "#fff",
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )

    return render.Root(
        max_age = 30,
        child = render.Row(
            main_align = "space_between",
            cross_align = "end",
            children = [
                box_orange,
                render.Padding(
                    pad = (3, 1, 3, 1),
                    child = render.Image(
                        src = LINE_IMG,
                        width = 1,
                        height = 21,
                    ),
                ),
                render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = str(block_tip_height),
                            color = "#09a3ba",
                            font = "CG-pixel-3x5-mono",
                        ),
                        box_purple,
                    ],
                ),
            ],
        ),
    )
