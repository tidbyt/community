"""
Applet: Coffee
Summary: Displays Coffee Orders
Description: Displays Coffee Orders with explanations.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")  #Encoding Images
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

COFFEE_IMAGE_CACHE_TIME = 600  #10 Minutes
COFFEE_IMAGE_URL = "https://coffee.alexflipnote.dev/random.json"
COFFEE_DATA = [
    {
        "Coffee Drink": "Espresso",
        "Description": "A strong, concentrated coffee",
        "Ingredients": "Single or double shot of espresso",
        "Proportions": "1 shot (single) or 2 shots (double) espresso",
    },
    {
        "Coffee Drink": "Cappuccino",
        "Description": "Creamy and frothy, strong coffee flavor",
        "Ingredients": "1/3 espresso, 1/3 steamed milk, 1/3 milk foam",
        "Proportions": "1 shot espresso, equal parts steamed milk and milk foam",
    },
    {
        "Coffee Drink": "Flat White",
        "Description": "Smooth and velvety",
        "Ingredients": "Espresso, steamed milk (with little foam)",
        "Proportions": "1 shot espresso, 2/3 steamed milk, little foam",
    },
    {
        "Coffee Drink": "Latte",
        "Description": "Mild and creamy",
        "Ingredients": "Espresso, steamed milk, light milk foam",
        "Proportions": "1 shot espresso, 2/3 steamed milk, light milk foam",
    },
    {
        "Coffee Drink": "Americano",
        "Description": "Diluted espresso",
        "Ingredients": "Espresso, hot water",
        "Proportions": "1 shot espresso, 2/3 hot water",
    },
    {
        "Coffee Drink": "Macchiato",
        "Description": "Espresso with a dash of milk foam",
        "Ingredients": "Espresso, small amount of milk foam",
        "Proportions": "1 shot espresso, a dash of milk foam",
    },
    {
        "Coffee Drink": "Mocha",
        "Description": "Chocolate-flavored coffee",
        "Ingredients": "Espresso, steamed milk, chocolate syrup, whipped cream (optional)",
        "Proportions": "1 shot espresso, 2/3 steamed milk, 1-2 tablespoons chocolate syrup",
    },
    {
        "Coffee Drink": "Affogato",
        "Description": "Dessert-like coffee treat",
        "Ingredients": "Espresso, ice cream",
        "Proportions": "1 shot espresso, 1 scoop of ice cream",
    },
    {
        "Coffee Drink": "Café au Lait",
        "Description": "Classic French coffee drink",
        "Ingredients": "Brewed coffee, steamed milk",
        "Proportions": "1/2 brewed coffee, 1/2 steamed milk",
    },
    {
        "Coffee Drink": "Café Con Leche",
        "Description": "Spanish coffee with milk",
        "Ingredients": "Strong coffee or espresso, steamed milk",
        "Proportions": "1 shot espresso or strong coffee, 1/2 steamed milk",
    },
    {
        "Coffee Drink": "Coffee Nudge",
        "Description": "A warm coffee cocktail",
        "Ingredients": "Coffee, dark crème de cacao, brandy, whipped cream",
        "Proportions": "1 cup coffee, 1 oz dark crème de cacao, 1 oz brandy, whipped cream on top",
    },
    {
        "Coffee Drink": "Mochaccino",
        "Description": "A blend of cappuccino and mocha",
        "Ingredients": "Espresso, steamed milk, chocolate syrup, milk foam",
        "Proportions": "1 shot espresso, 1/2 steamed milk, 1-2 tablespoons chocolate syrup, milk foam on top",
    },
    {
        "Coffee Drink": "Cortado",
        "Description": "Espresso cut with a small amount of warm milk",
        "Ingredients": "Espresso, warm milk",
        "Proportions": "1 shot espresso, 1 shot warm milk",
    },
    {
        "Coffee Drink": "Breve",
        "Description": "Rich and creamy, made with half-and-half",
        "Ingredients": "Espresso, steamed half-and-half",
        "Proportions": "1 shot espresso, equal parts steamed half-and-half",
    },
    {
        "Coffee Drink": "Mocha Breve",
        "Description": "A rich mocha made with half-and-half",
        "Ingredients": "Espresso, steamed half-and-half, chocolate syrup",
        "Proportions": "1 shot espresso, 2/3 steamed half-and-half, 1-2 tablespoons chocolate syrup",
    },
    {
        "Coffee Drink": "Café Noisette",
        "Description": "French espresso with a hint of milk",
        "Ingredients": "Espresso, a dash of hot milk",
        "Proportions": "1 shot espresso, a dash of hot milk",
    },
    {
        "Coffee Drink": "Lungo",
        "Description": "A 'long' espresso with more water",
        "Ingredients": "Espresso, more water",
        "Proportions": "1 shot espresso, double the amount of water",
    },
    {
        "Coffee Drink": "Viennois",
        "Description": "Espresso topped with whipped cream",
        "Ingredients": "Espresso, whipped cream",
        "Proportions": "1 shot espresso, topped with whipped cream",
    },
    {
        "Coffee Drink": "Con Panna",
        "Description": "Espresso with whipped cream",
        "Ingredients": "Espresso, whipped cream",
        "Proportions": "1 shot espresso, a dollop of whipped cream",
    },
]
DEFAULT_COFFEE_IMAGE = base64.decode("""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""")

COFFEE_CUP_IMAGE = base64.decode("""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""")

COFFEE_PALETTE = {"Espresso": "#4B2E22", "Coffee Bean": "#6F4E37", "Latte": "#D3B499", "Cream": "#FFF5E1", "Mocha": "#3B2F2F", "Caramel": "#C68E51", "Warm Cinnamon": "#D2691E", "Foam White": "#FFFFF0"}
COFFEE_FONT = "tb-8"

def main(config):
    # this contains the display elements
    children = []

    # either display a random image, or a coffee recipe
    if config.get("display_type") == "image":
        children.append(get_coffee_image())
    else:
        # get the coffees they selected in the pick list
        selected_coffees = get_selected_coffees(config)

        # if they didn't pick anything, we'll pick from the full list
        if (len(selected_coffees) == 0):
            selected_coffees = COFFEE_DATA

        #Recipe Display
        random_coffee_id = random.number(0, len(selected_coffees) - 1)
        children.append(add_padding_to_child_element(render.Image(src = COFFEE_CUP_IMAGE, width = 20), -3))
        children.append(add_padding_to_child_element(render.Marquee(width = 44, child = render.Text(content = selected_coffees[random_coffee_id]["Coffee Drink"], color = COFFEE_PALETTE["Cream"], font = COFFEE_FONT)), 16))
        children.append(add_padding_to_child_element(render.Marquee(width = 64, child = render.Text(content = selected_coffees[random_coffee_id]["Description"], color = COFFEE_PALETTE["Warm Cinnamon"], font = COFFEE_FONT)), 0, 14))
        children.append(add_padding_to_child_element(render.Marquee(width = 64, offset_end = 64, offset_start = (4 * (len(selected_coffees[random_coffee_id]["Description"]))), child = render.Text(content = selected_coffees[random_coffee_id]["Proportions"], color = COFFEE_PALETTE["Caramel"], font = COFFEE_FONT)), 0, 23))

    return render.Root(
        render.Stack(
            children = children,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_selected_coffees(config):
    selected_coffees = []

    for coffee in COFFEE_DATA:
        if (config.bool(coffee["Coffee Drink"]) == True):
            selected_coffees.append(coffee)

    return selected_coffees

def get_coffee_image():
    rep = http.get(
        COFFEE_IMAGE_URL,
        headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.1", "Accept": "text/html,application/xhtml+xml,application/xml"},
    )

    if rep.status_code == 200 and rep.json():
        artwork = http.get(rep.json()["file"], ttl_seconds = COFFEE_IMAGE_CACHE_TIME).body()
        artwork_image = render.Image(src = artwork, width = 64, height = 32)
    else:
        artwork_image = render.Image(src = DEFAULT_COFFEE_IMAGE, width = 64, height = 32)

    return artwork_image

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    display_type = [
        schema.Option(display = "Display Random Coffee Image", value = "image"),
        schema.Option(display = "Display Random Coffee Order", value = "order"),
    ]

    def get_coffees(type):
        # default
        items = sorted(COFFEE_DATA, key = lambda x: x["Coffee Drink"])
        icon = "mugHot"

        if type == "order":
            return [
                schema.Toggle(id = item["Coffee Drink"], name = item["Coffee Drink"], desc = item["Description"], icon = icon, default = False)
                for item in items
            ]
        else:
            return []

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Dropdown(
                id = "display_type",
                icon = "tv",
                name = "What to display",
                desc = "What do you want this to display?",
                options = display_type,
                default = display_type[1].value,
            ),
            schema.Generated(
                id = "coffee_types",
                source = "display_type",
                handler = get_coffees,
            ),
        ],
    )
