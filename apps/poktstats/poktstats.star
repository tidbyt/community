load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

COINSTATS_PRICE_URL = "https://api.coinstats.app/public/v1/coins/pocket-network"
PNI_HEIGHT_URL = "https://supply.research.pokt.network:8192/height"
POKT_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAQBJREFUSEu1lTEOwjAMRZ0KFQmJjZF7MHADFnbgFtyHCbFxBwYQYuYKqAudEZUQRSlKCY5ju4Jma+y8Oj9ftsmyrATFGq27MOwDbKeFIhvAxMAWRK3T4g128eO8gMSEmSQ4BrXHMdjf8/FfYA7oDlFgHLPf7YI1V8cqSm9QVSwlaaG+JFGw09Ila/RvBOaAgx5AfgutZosSK5ZkouIVeLK6luc8CX7L2Qp7F8PbBcdc8XPFHFjrb1IKzsdcE+JsyLrCh2JPS96uwX4bxFVSUI1EdRPaXwwsd2lj28VuJnY3yR0qsE0ab1J4PD8jQQOm5BJH09/BsVbZSQwcZndxoL4AMITkTbi6GN8AAAAASUVORK5CYII=
""")

def main():
    cached_price = cache.get("pokt_price")
    cached_height = cache.get("pokt_height")

    if cached_price != None:
        print("cache hit! using cached price")
        price = float(cached_price)
    else:
        print("cache miss! calling coinstats API")
        rep = http.get(COINSTATS_PRICE_URL)
        if rep.status_code != 200:
            fail("Coinstats request failed with status %d", rep.status_code)
        price = rep.json()["coin"]["price"]

        # 2 hour cache for the price
        cache.set("pokt_price", str(float(price)), ttl_seconds = 7200)

    if cached_height != None:
        print("cache hit! using cached height")
        height = int(cached_height)
    else:
        print("cache miss! calling PNI API")
        rep = http.get(PNI_HEIGHT_URL)
        if rep.status_code != 200:
            fail("PNI Height request failed with status %d", rep.status_code)
        height = rep.body()

        # 10 minute cache for the height (15 minute block time)
        cache.set("pokt_height", str(int(height)), ttl_seconds = 600)

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Padding(
                        # Pad a LR border around the POKT logo
                        pad = (5, 0, 5, 0),
                        child = render.Image(src = POKT_ICON),
                    ),
                    render.Column(
                        # Arrange price above height beside the logo
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "start",  # Controls vertical alignment
                        children = [
                            render.Text(content = "POKT", font = "Dina_r400-6"),
                            render.Text("$%s" % price),
                            render.Text("%s" % height),
                        ],
                    ),
                ],
            ),
        ),
    )
