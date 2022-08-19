"""
Applet: Giphy
Summary: Displays Giphy gifs
Description: Displays a random gif based on a search query. Powered by Giphy.com.
Author: Ricky Smith (DigitallyBorn)
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

SEARCH_URL = "https://api.giphy.com/v1/gifs/search?api_key={}&q={}&limit=25&offset=0&rating={}&lang=en"
API_TOKEN_ENCRYPTED = """
AV6+xWcEb+nOegkpKq3mN6quWDpiV42LsfTGMLbPlsHby8tluwCVlR8IPuNosXSUQoISRk1/RpjX
WgJvXoW4PTGUYW5MF+5Z8s2A6Oj+3TzBNNuvGaN8kUsF7GzcoDUnqux99vkvS7NADgVkvwiMDmEi
7nHMaTq20q9bFzgGY7FLfzM7Cyc=
"""

GIPHY_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAABlElEQVR4nMWXMU/CQBTHf70YExBi
mDoRDYsrA2F3YOQbMLBQdw2fwuAOLiz4BdjgGxhMjJsLO4NaU8LAUoe7SimlLbWcv+TS9u7d+99r
cu/eGSQjDzSBBlADKkBRjTnAHJgBU2AMrBL63YsJ9JRzN2Fz1BwzrWgHsA8QDDZb+UjMKTD6g2Cw
jZTPWNFJhqJem8SJZxlpWOS/GL73DjAIrsR1WntX+fzyQf2pDEBpOMRer6OCArCARwChOkzgPm5W
UPT17fOQKSgNEzYR94DbUFO3L5/GTfiwZW19J4j8AbgTyORgRVlmjAXkBTIjFbLy+tVu7/yFAAWg
KZBpUDeNE2TuTY0x2N4IrYs+5VyVkA3ipyaQCT8zyrkql2f1OLOKYHPKZEICUYCiiLc5DgJ5jOnG
EchDXDdzgawcdDMTyHJFN1OBrJGWGkWXwFggC7PI3Z4xA2DlnU4m8A6c75jN3HTur0vg2MHeb+AK
WHj7eAF00ykcRFdp7aCt9Anyb8WeJ669vPWjvaD3c7QrjBE16CPzS9sPWXwFXHChq40AAAAASUVO
RK5CYII=
""")

def main(config):
    API_TOKEN = secret.decrypt(API_TOKEN_ENCRYPTED) or config.get("dev_api_key")
    search_query = config.str("search_query", "do it")
    rating = config.str("rating", "g")

    results = search(search_query, rating, API_TOKEN)
    image_count = len(results["data"])

    if image_count == 0:
        return render.Root(
            render.Column(
                expanded = True,
                main_align = "center",
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = "No images found for {}".format(search_query)
                        )
                    )
                ]
            )
        )

    image_data = None
    for _ in range(25):
        image = results["data"][random.number(0, image_count - 1)]
        image_url = image["images"]["downsized"]["url"]
        image_data = get_giphy_url(image_url, image["id"], 240)
        if image_data != None:
            break

    return render.Root(
        delay = 60,
        child =
            render.Stack(
                children = [
                    render.Image(
                        height = 32,
                        width = 64,
                        src = image_data,
                    ),
                    render.Image(
                        height = 8,
                        width = 8,
                        src = GIPHY_LOGO,
                    ),
                ],
            ),
    )

def search(search_query, rating, api_key):
    raw_data = cache.get(search_query)
    if raw_data == None:
        print("Searching for \"{}\"".format(search_query))
        resp = http.get(
            SEARCH_URL,
            params = {
                "api_key": api_key,
                "q": search_query,
                "r": rating,
            },
        )
        raw_data = resp.body()
        cache.set(search_query, raw_data, 60)
    return json.decode(raw_data)

def get_giphy_url(url, cache_key, tls):
    raw_data = cache.get(cache_key)
    if raw_data == None:
        print("Fetching {}".format(url))
        resp = http.get(url)
        raw_data = resp.body()
        cache.set(cache_key, raw_data, tls)
    return raw_data

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "search_query",
                name = "Search Query",
                desc = "Search for a gif",
                icon = "user",
            ),
            schema.Dropdown(
                id = "rating",
                name = "Rating",
                desc = "Content Rating",
                icon = "baby",
                default = "g",
                options = [
                    schema.Option(
                        display = "G",
                        value = "g",
                    ),
                    schema.Option(
                        display = "PG",
                        value = "pg",
                    ),
                    schema.Option(
                        display = "PG 13",
                        value = "pg-13",
                    ),
                    schema.Option(
                        display = "R",
                        value = "r",
                    ),
                ],
            ),
        ],
    )
