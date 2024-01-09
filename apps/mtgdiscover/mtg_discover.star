"""
Applet: MTG Discover
Summary: Discover random MTG cards
Description: Cycles through and displays information about random Magic: The Gathering cards.
Author: Staghouse
"""

load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

ONE_DAY_TTL = 60 * 10 * 24
APP_FONT = "tb-8"

# Main application function
def main(config):
    # Fetched card
    card = get_scryfall_card()

    # Schema config
    show_prices = config.bool("prices")
    show_rarity = config.bool("rarity")

    if card == False:
        return render.Root(
            child = render.Box(
                padding = 1,
                height = 28,
                child = render.Column(
                    children = [
                        render.WrappedText(
                            content = "MTG Discover",
                        ),
                        render_line_break(),
                        render.WrappedText(
                            color = "#999",
                            content = "No cards found...",
                        ),
                    ],
                ),
            ),
        )

    # Main root render
    return render.Root(
        delay = 100,
        max_age = 30,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Padding(
                            pad = (1, 0, 1, 0),
                            child = render.Marquee(
                                width = 62,
                                child = render_card_name_cost(card),
                            ),
                        ),
                        render_line_break("#999", (1, 0, 1, 1)),
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
                                    font = APP_FONT,
                                    content = card["type"],
                                ),
                                render_creature_properties(card),
                                render_line_break(),
                                render_rarity(card["rarity"], show_rarity),
                                render.WrappedText(
                                    font = APP_FONT,
                                    content = card["set"],
                                ),
                                render_prices(card, show_prices),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

# Render a line break
def render_line_break(color = "#333", padding = (0, 1, 0, 1)):
    return render.Row(
        expanded = True,
        main_align = "center",
        children = [
            render.Padding(
                pad = padding,
                child = render.Box(
                    color = color,
                    height = 1,
                ),
            ),
        ],
    )

# Set render for creature power/toughness
def render_creature_properties(card):
    creature_properties = None

    if card["power"] or card["toughness"]:
        creature_properties = render.WrappedText(
            font = APP_FONT,
            content = "(" + card["power"] + "/" + card["toughness"] + ")",
        )

    return creature_properties

# Render card name and cost
def render_card_name_cost(card):
    card_name_cost = []

    for src in card["mana_cost"]:
        card_name_cost.append(
            render.Padding(
                pad = (0, 1, 2, 0),
                child = render.Image(
                    src = src,
                    height = 10,
                ),
            ),
        )

    card_name_cost.append(
        render.Padding(
            pad = (0, 2, 3, 2),
            child = render.Text(
                font = APP_FONT,
                content = card["name"],
            ),
        ),
    )

    return render.Row(
        children = card_name_cost,
    )

# Render card prices
def render_prices(card, show):
    prices = []

    # Config wants no prices
    if show == False:
        return render.Column(
            children = prices,
        )

    prices.append(
        render_line_break("#333", (0, 2, 0, 2)),
    )

    # Set normal price
    if card["price"] != None:
        prices.append(render.Row(
            children = [
                render.Text(
                    font = APP_FONT,
                    color = "#4580ec",
                    content = "Normal: ",
                ),
                render.WrappedText(
                    font = APP_FONT,
                    content = card["price"],
                ),
            ],
        ))

    # Set foil price
    if card["price_foil"] != None:
        prices.append(render.Row(
            children = [
                render.Text(
                    font = APP_FONT,
                    color = "#4580ec",
                    content = "Foil: ",
                ),
                render.WrappedText(
                    font = APP_FONT,
                    content = card["price_foil"],
                ),
            ],
        ))

    # Set etched foil price
    if card["price_etched"] != None:
        prices.append(render.Row(
            children = [
                render.Text(
                    font = APP_FONT,
                    color = "#4580ec",
                    content = "Etched: ",
                ),
                render.WrappedText(
                    font = APP_FONT,
                    content = card["price_etched"],
                ),
            ],
        ))

    # Set no available prices
    if len(prices) == 0:
        prices.append(render.Row(
            children = [
                render.Text(
                    font = APP_FONT,
                    color = "#4580ec",
                    content = "Prices ",
                ),
                render.WrappedText(
                    font = APP_FONT,
                    content = "N/A",
                ),
            ],
        ))

    return render.Column(
        children = prices,
    )

# Rnder card rarity
def render_rarity(rarity, show):
    if show != False:
        rarity_color = "#fff"

        if rarity == "uncommon":
            rarity_color = "#dedede"

        if rarity == "rare":
            rarity_color = "#d5d03a"

        if rarity == "mythic" or rarity == "bonus":
            rarity_color = "#d5623a"

        if rarity == "special":
            rarity_color = "#a03ad5"

        return render.Column(
            children = [
                render.WrappedText(
                    font = APP_FONT,
                    color = rarity_color,
                    content = rarity[0].upper() + rarity[1:],
                ),
                render_line_break(),
            ],
        )

    else:
        return None

# Render card text
def render_text(card):
    card_text = []

    for item in card["text"]:
        if "<svg" in item:
            card_text.append(
                render.Image(
                    src = item,
                    height = 8,
                ),
            )
        else:
            card_text.append(
                render.Text(
                    content = item,
                ),
            )

    return card_text

# Fetch a random card from Scryfall and return wanted data
def get_scryfall_card():
    text = ""
    mana_cost = ""
    power = ""
    toughness = ""
    type_line = ""
    price_usd = None
    price_usd_foil = None
    price_usd_etched = None

    response = http.get("https://api.scryfall.com/cards/random", ttl_seconds = 0)

    if response.status_code != 200:
        return False

    card = response.json()

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

# Transform card text in to text and images
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

# Transform mana cost in to images
def transform_mana_cost(mana_cost):
    mana_symbols = re.findall(r"{.*?}", mana_cost)
    mana_symbols_svgs = []

    response = http.get("https://api.scryfall.com/symbology", ttl_seconds = ONE_DAY_TTL)

    if response.status_code != 200:
        return mana_symbols_svgs

    response_data = response.json()["data"]

    for symbol_object in response_data:
        for symbol in mana_symbols:
            if symbol == symbol_object["symbol"]:
                svg_response = http.get(symbol_object["svg_uri"], ttl_seconds = ONE_DAY_TTL)

                if svg_response.status_code != 200:
                    return mana_symbols_svgs

                mana_symbols_svgs.append(svg_response.body())

    return mana_symbols_svgs

# Schema config for the application
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
