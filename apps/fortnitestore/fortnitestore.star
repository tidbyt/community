load("secret.star", "secret")
load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")
load("render.star", "render")
load("random.star", "random")

color_key = {
    "handmade": "#fff",
    "uncommon": "#31923b",
    "rare": "#4e51f4",
    "epic": "#9c4cb9",
    "legendary": "#f1af2c",
    "mythic": "#fcd03e",
    "exotic": "#0abfd0",
    "transcendent": "#da505d",
    "marvel series": "#fff",
    "dark series": "#fff",
    "dc series": "#fff",
    "icon series": "#fff",
    "frozen series": "#fff",
    "lava series": "#fff",
    "star wars series": "#fff",
    "shadow series": "#fff",
    "slurp series": "#fff",
    "gaming legends series": "#fff",
    "quality": "#fff",
    "fine": "#fff",
    "sturdy": "#fff",
    "icon": "#fff",
}

def main(config):
    api_key = secret.decrypt("AV6+xWcElvQO3RdOuUWg00KERqBYk1kWJ3oSxwg5nHIiyRIeO3kAcizfUsNLlw/TBEWvz2AqbzJtDqHZXzLOpa5fuyqfqUoGXydDZVXNB8yKlS9Iuy+u7eFqqEJqOPafNsCJLTu0LGL172n0phpyssLbh1+dDvRPPY/lZlarrscbZoqHVzEBCtNF") or config.get("dev_api_key")
    items = cache.get("items")
    if api_key:
        if items == None:
            store_api = "https://api.fortnitetracker.com/v1/store"
            items_resp = http.get(store_api, headers = {"TRN-Api-Key": api_key})
            items = items_resp.json()
            cache.set("items", str(items), ttl_seconds = 120)
        else:
            items = json.decode(items)

        picked = random.number(0, len(items) - 1)

        image_resp = http.get(items[picked]["imageUrl"])

        print(items[picked])

        return render.Root(
            render.Stack(
                children = [
                    render.Column(
                        main_align = "end",
                        children = [render.Image(src = image_resp.body(), height = 32)],
                    ),
                    render.Marquee(
                        width = 64,
                        offset_start = 32,
                        offset_end = 32,
                        align = "end",
                        child = render.Padding(
                            pad = (0, 2, 2, 0),
                            child = render.Text(
                                content = items[picked]["name"],
                                color = color_key[items[picked]["rarity"].lower()],
                            ),
                        ),
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "end",
                        children = [
                            render.Padding(
                                pad = (0, 0, 2, 2),
                                child = render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    children = [
                                        render.Text(content = "V", color = "#34c0eb"),
                                        render.Text(content = str(items[picked]["vBucks"])[0:-2]),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        )
