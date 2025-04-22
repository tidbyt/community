"""
Applet: Steam Top Sellers
Summary: Display Steam Top Sellers
Description: A simple app intended to render a random selection from Steam's Top Seller list.
Author: John Kalbac (@johnkalbac)
"""

load("animation.star", "animation")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

GLOBAL_HTTP_TTL_SECONDS = 600
GLOBAL_RESULT_LIMIT = 1  # Limit results to minimize rendered file size
FEATURED_CATEGORIES_RESOURCE = "https://store.steampowered.com/api/featuredcategories"
DEFAULT_REGION_CODE = "us"  #ISO 3166, alpha-2
MARQUEE_NAME_LENGTH = 60

def main(config):
    region = config.get("region", DEFAULT_REGION_CODE)
    response = call_steam_api(region)
    if response.status_code != 200:
        return handle_failure()

    top_sellers = parse_top_sellers(response)
    frames = build_frames(top_sellers)

    return render.Root(
        render.Sequence(frames),
        show_full_animation = True,
        delay = 90,
    )

def call_steam_api(region):
    # Fetch the featured games from the Steam API
    full_url = FEATURED_CATEGORIES_RESOURCE + "?cc=" + region
    return http.get(
        full_url,
        ttl_seconds = GLOBAL_HTTP_TTL_SECONDS,
    )

def parse_top_sellers(response):
    raw_data = response.json()

    # TODO handle json failures and inconsistent data
    #print("raw_data: %s" % (raw_data))
    top_sellers = raw_data["top_sellers"]["items"]

    #print("top_sellers: %s" % (top_sellers))
    return top_sellers

def build_frames(top_sellers):
    # Iterate top_sellers list and extract details
    frames = []
    counter = 0

    # Shuffle the results
    top_sellers_sorted = sorted(top_sellers, key = lambda x: random.number(0, 100))
    for item in top_sellers_sorted:
        name = item["name"]

        # Omit Steam Deck hardware entries
        if "Steam Deck" not in name and counter < GLOBAL_RESULT_LIMIT:
            print("name: %s, counter: %s" % (name, str(counter)))
            discount_percent = item["discount_percent"]
            final_price_formatted = format_price(
                item["final_price"],
            )
            image = fetch_image(item["small_capsule_image"])

            # Add Image Frame
            frames.append(get_image_widget(image))

            # Add Details Frame
            padded_name = pad_string(name, MARQUEE_NAME_LENGTH)
            frames.append(get_details_widget(padded_name, final_price_formatted, discount_percent))

            counter = counter + 1

    return frames

def pad_string(input, total_length):
    # LeftPad for better readability in the marquee
    input = "          " + input

    # If the input is already longer than total_length, just truncate it
    if len(input) >= total_length:
        return input[:total_length]

    # Repeat the input string enough times to exceed total_length
    repeated = input * ((total_length // len(input)) + 1)

    # Now truncate it to exactly total_length characters
    return repeated[:total_length]

def get_details_widget(name, final_price_formatted, discount_percent):
    return render.Stack(
        children = [

            # Header section
            render.Column(
                main_align = "start",
                expanded = True,
                children = [
                    render.Row(
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Text("Steam", color = "#132b8a", font = "5x8"),
                        ],
                    ),
                ],
            ),

            # Floating middle section for name marquee
            render.Column(
                main_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        main_align = "space_around",
                        expanded = True,
                        children = [
                            render.Box(
                                color = "#132b8a",
                                height = 15,
                                child = render.Marquee(
                                    height = 10,
                                    width = MARQUEE_NAME_LENGTH,
                                    #delay=10,
                                    child = render.Text(name, color = "#ffff"),
                                    offset_start = 0,
                                    offset_end = 32,
                                    align = "center",
                                ),
                            ),
                        ],
                    ),
                ],
            ),
            # Lower section for price and (optional) discount percentage
            render.Column(
                main_align = "end",  # bottom
                expanded = True,
                children = [
                    render.Row(
                        main_align = "space_evenly",
                        expanded = True,
                        children = [
                            render.Text(final_price_formatted, color = "#132b8a", font = "5x8"),
                            render.Text(get_discount(discount_percent), color = "#05a81e", font = "5x8"),
                        ],
                    ),
                ],
            ),
        ],
    )

def get_image_widget(image):
    # Randomize some of the animation values
    random_origin = random.number(1, 3) / 10.0
    random_translate_x = -random.number(20, 40)
    random_translate_y = -random.number(5, 20)
    directions = ["alternate", "alternate-reverse"]
    direction_choice = directions[random.number(0, 1)]

    return animation.Transformation(
        child = render.Image(
            src = image,
            width = 184,
            height = 69,
        ),
        duration = 20,
        delay = 0,
        origin = animation.Origin(0.0, random_origin),
        direction = direction_choice,
        fill_mode = "forwards",
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [
                    animation.Scale(.5, .5),
                    animation.Translate(random_translate_x, random_translate_y),
                ],
                curve = "ease_in_out",
            ),
        ],
    )

def fetch_image(image_url):
    print("    image: %s" % (image_url))
    response = http.get(
        image_url,
        ttl_seconds = GLOBAL_HTTP_TTL_SECONDS,
    )
    if response.status_code != 200:
        fail("GET %s failed with status %d: %s" % (image_url, response.status_code, response.body()))

    return response.body()

def format_price(amount):
    amount_str = str(amount)

    # Crude formatting; TODO clean this up.
    if (amount == 0):
        formatted_amount = "$0"
    elif len(amount_str) <= 3:
        formatted_amount = "$" + amount_str
    else:
        formatted_amount = ("$" + amount_str[:-4] + "." + amount_str[-4:-2])

    print("    price: %s" % (formatted_amount))
    return formatted_amount

def handle_failure():
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text("No data available or API failed!"),
        ),
    )

def get_discount(discount_percent):
    if discount_percent > 0:
        return "-%s" % str(discount_percent)[:-2] + "%"
    else:
        return ""

def get_schema():
    options = [
        schema.Option(display = "US", value = "us"),
        schema.Option(display = "Spain", value = "es"),
        schema.Option(display = "Germany", value = "de"),
        schema.Option(display = "France", value = "fr"),
        schema.Option(display = "New Zealand", value = "nz"),
        schema.Option(display = "Australia", value = "au"),
        schema.Option(display = "UK", value = "uk"),
        schema.Option(display = "Brazil", value = "br"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Steam country code for pricing details.",
                icon = "map",
                default = options[0].value,
                options = options,
            ),
        ],
    )
