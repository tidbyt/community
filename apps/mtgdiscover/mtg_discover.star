load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    # Fetched card
    card = get_scryfall_card()

    # Config
    show_card_prices = config.bool("prices")
    show_card_rarity = config.bool("rarity")

    # Set the render for card text
    # WIP since the mix of images and text cant be wrapped around properly
    # render_card_text = []
    # for item in card["text"]:
    #     if '<svg' in item:
    #         render_card_text.append(
    #             render.Image(
    #                 src = item,
    #                 height = 8,
    #             )
    #         )
    #     else:
    #         render_card_text.append(
    #             render.Text(
    #                 content = item
    #             )
    #         )

    # Set render for creature power/toughness
    render_creature_properties = None
    if card["power"] or card["toughness"]:
        render_creature_properties = render.WrappedText(
            content = "(" + card["power"] + "/" + card["toughness"] + ")",
        )

    # Array of renders for the card name and cost
    render_card_name_cost = []
    for src in card["mana_cost"]:
        render_card_name_cost.append(
            render.Padding(
                pad = (0, 1, 2, 0),
                child = render.Image(
                    src = src,
                    height = 10,
                ),
            ),
        )
    render_card_name_cost.append(
        render.Padding(
            pad = (0, 2, 3, 2),
            child = render.Text(
                content = card["name"],
            ),
        ),
    )

    # Set the render for card rarity
    render_rarity = None
    if show_card_rarity != False:
        card_rarity_color = "#fff"

        if card["rarity"] == "uncommon":
            card_rarity_color = "#dedede"

        if card["rarity"] == "rare":
            card_rarity_color = "#d5d03a"

        if card["rarity"] == "mythic" or card["rarity"] == "bonus":
            card_rarity_color = "#d5623a"

        if card["rarity"] == "special":
            card_rarity_color = "#a03ad5"
        render_rarity = render.WrappedText(
            color = card_rarity_color,
            content = card["rarity"][0].upper() + card["rarity"][1:],
        )

    # Set the render for a normal price
    render_price = None
    if show_card_prices != False and card["price"] != None:
        render_price = render.Row(
            children = [
                render.Text(
                    color = "#4580ec",
                    content = "Normal: ",
                ),
                render.WrappedText(
                    content = card["price"],
                ),
            ],
        )

    # Set the render for a foil price
    render_price_foil = None
    if show_card_prices != False and card["price_foil"] != None:
        render_price_foil = render.Row(
            children = [
                render.Text(
                    color = "#4580ec",
                    content = "Foil: ",
                ),
                render.WrappedText(
                    content = card["price_foil"],
                ),
            ],
        )

    # Set the render for a etched price
    render_price_etched = None
    if show_card_prices != False and card["price_etched"] != None:
        render_price_etched = render.Row(
            children = [
                render.Text(
                    color = "#4580ec",
                    content = "Etched: ",
                ),
                render.WrappedText(
                    content = card["price_etched"],
                ),
            ],
        )

    # Set the render for no prices
    render_no_prices = None
    if show_card_prices != False and render_price == None and render_price_foil == None and render_price_etched == None:
        render_no_prices = render.Text(
            color = "#4580ec",
            content = "Prices N/A",
        )

    # Main root render
    return render.Root(
        delay = 100,
        max_age = 10,
        child = render.Box(
            child = render.Column(
                children = [
                    render.Column(
                        children = [
                            render.Padding(
                                pad = (1, 0, 1, 0),
                                child = render.Marquee(
                                    width = 64,
                                    child = render.Row(
                                        children = render_card_name_cost,
                                    ),
                                ),
                            ),
                            render.Padding(
                                pad = (1, 1, 1, 2),
                                child = render.Box(
                                    width = 62,
                                    height = 1,
                                    color = "#999",
                                ),
                            ),
                        ],
                    ),
                    render.Padding(
                        pad = (1, 0, 1, 1),
                        child = render.Marquee(
                            height = 18,
                            scroll_direction = "vertical",
                            child = render.Column(
                                children = [
                                    render.WrappedText(
                                        content = card["type"],
                                    ),
                                    render_creature_properties,
                                    render_rarity,
                                    render.WrappedText(
                                        content = card["set"],
                                    ),
                                    render_price,
                                    render_price_foil,
                                    render_price_etched,
                                    render_no_prices,
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        ),
    )

def get_scryfall_card():
    text = ""
    mana_cost = ""
    power = ""
    toughness = ""
    type_line = ""
    price_usd = None
    price_usd_foil = None
    price_usd_etched = None

    res = http.get("https://api.scryfall.com/cards/random", ttl_seconds = 0)
    card = res.json()

    if "oracle_text" in card:
        text = card["oracle_text"]

    if "type_line" in card:
        type_line = card["type_line"]

    if "mana_cost" in card:
        mana_cost = card["mana_cost"]

    if "power" in card:
        power = card["power"]

    if "toughness" in card:
        toughness = card["toughness"]

    if card["prices"]["usd"]:
        price_usd = "$" + card["prices"]["usd"]

    if card["prices"]["usd_foil"]:
        price_usd_foil = "$" + card["prices"]["usd_foil"]

    if card["prices"]["usd_etched"] != None:
        price_usd_etched = "$" + card["prices"]["usd_etched"]

    return {
        "name": card["name"],
        "type": type_line,
        "text": text,
        "rarity": card["rarity"],
        "set": card["set_name"],
        "power": power,
        "toughness": toughness,
        "price": price_usd,
        "price_foil": price_usd_foil,
        "price_etched": price_usd_etched,
        "mana_cost": transform_mana_cost(mana_cost),
    }

def transform_text(text):
    text_with_lines = text.splitlines()
    all_symbols = re.findall(r"{.*?}", text)
    clean_lines = []

    for line in text_with_lines:
        subbed_line = re.sub(r"{.*?}", "_mana$", line)
        split_line = subbed_line.split("$")

        if len(all_symbols) > 0:
            for line_idx, line in enumerate(split_line):
                if "_mana" in line:
                    manaless_line = line.split("_mana")[0]

                    if len(manaless_line) > 0:
                        clean_lines.append(manaless_line)

                    mana_line = transform_mana_cost(all_symbols[line_idx])[0]
                    clean_lines.append(mana_line)

                else:
                    clean_lines.append(line)

        else:
            clean_lines.append(text)

    return clean_lines

def transform_mana_cost(mana_cost):
    ttl_time = 60 * 10 * 24
    mana_symbols = re.findall(r"{.*?}", mana_cost)
    mana_symbols_svgs = []

    url = "https://api.scryfall.com/symbology"
    res = http.get(url, ttl_seconds = ttl_time)

    ret = res.json()["data"]

    for symbol_object in ret:
        for symbol in mana_symbols:
            if symbol == symbol_object["symbol"]:
                svg = http.get(symbol_object["svg_uri"], ttl_seconds = ttl_time).body()

                mana_symbols_svgs.append(svg)

    return mana_symbols_svgs

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "rarity",
                name = "Show rarity",
                desc = "A toggle to display the card rarity.",
                icon = "rankingStar",
                default = True,
            ),
            schema.Toggle(
                id = "prices",
                name = "Show prices",
                desc = "A toggle to display the card prices.",
                icon = "dollarSign",
                default = True,
            ),
        ],
    )
