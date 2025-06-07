"""
Applet: Greek Letters
Summary: Learn the Greek alphabet
Description: Help with learning Greek alphabet.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

LETTER_COLOR = "FFD700"
GREEK_LETTER_IMAGE_LOOKUP_URL = "https://assets.imgix.net/~text?w=150&h=150&txt-size=75&txt-color=%s&txt-align=left&txt-font=Arial&txt64=" % LETTER_COLOR

# These images not likely to ever be updated, so lets cache as long as possible
TTL_SECONDS = 31536000  #one year

GREEK_ALPHABET = [
    {"letter": "Α", "lowercase": "α", "name": "Alpha", "pronunciation": "AHL-fah"},
    {"letter": "Β", "lowercase": "β", "name": "Beta", "pronunciation": "VEE-tah"},
    {"letter": "Γ", "lowercase": "γ", "name": "Gamma", "pronunciation": "GHAH-mah"},
    {"letter": "Δ", "lowercase": "δ", "name": "Delta", "pronunciation": "THEL-tah"},
    {"letter": "Ε", "lowercase": "ε", "name": "Epsilon", "pronunciation": "EHP-see-lon"},
    {"letter": "Ζ", "lowercase": "ζ", "name": "Zeta", "pronunciation": "ZEE-tah"},
    {"letter": "Η", "lowercase": "η", "name": "Eta", "pronunciation": "EE-tah"},
    {"letter": "Θ", "lowercase": "θ", "name": "Theta", "pronunciation": "THEE-tah"},
    {"letter": "Ι", "lowercase": "ι", "name": "Iota", "pronunciation": "YO-tah"},
    {"letter": "Κ", "lowercase": "κ", "name": "Kappa", "pronunciation": "KAH-pah"},
    {"letter": "Λ", "lowercase": "λ", "name": "Lambda", "pronunciation": "LAHM-thah"},
    {"letter": "Μ", "lowercase": "μ", "name": "Mu", "pronunciation": "mee"},
    {"letter": "Ν", "lowercase": "ν", "name": "Nu", "pronunciation": "nee"},
    {"letter": "Ξ", "lowercase": "ξ", "name": "Xi", "pronunciation": "ksee"},
    {"letter": "Ο", "lowercase": "ο", "name": "Omicron", "pronunciation": "OH-mee-kron"},
    {"letter": "Π", "lowercase": "π", "name": "Pi", "pronunciation": "pee"},
    {"letter": "Ρ", "lowercase": "ρ", "name": "Rho", "pronunciation": "roe"},
    {"letter": "Σ", "lowercase": "σ", "name": "Sigma", "pronunciation": "SEEGH-mah"},
    {"letter": "Τ", "lowercase": "τ", "name": "Tau", "pronunciation": "tahf"},
    {"letter": "Υ", "lowercase": "υ", "name": "Upsilon", "pronunciation": "EWP-see-lon"},
    {"letter": "Φ", "lowercase": "φ", "name": "Phi", "pronunciation": "fee"},
    {"letter": "Χ", "lowercase": "χ", "name": "Chi", "pronunciation": "hee"},
    {"letter": "Ψ", "lowercase": "ψ", "name": "Psi", "pronunciation": "psee"},
    {"letter": "Ω", "lowercase": "ω", "name": "Omega", "pronunciation": "oh-MEH-ghah"},
]

def get_letter_by_name(name):
    for item in GREEK_ALPHABET:
        if item["name"] == name:
            return item
    return None  # Return None if not found

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_image_stack_for_letter(letter_info):
    items = []

    #Get Greek Letter image
    capital_greek_letter = GREEK_LETTER_IMAGE_LOOKUP_URL + base64.encode(letter_info["letter"])
    capital_greek_letter_src = http.get(capital_greek_letter, ttl_seconds = TTL_SECONDS).body()
    items.append(add_padding_to_child_element(render.Image(height = 65, width = 65, src = capital_greek_letter_src), -3, -10))

    #Get Greek Letter image
    capital_greek_letter = GREEK_LETTER_IMAGE_LOOKUP_URL + base64.encode(letter_info["lowercase"])
    capital_greek_letter_src = http.get(capital_greek_letter, ttl_seconds = TTL_SECONDS).body()
    items.append(add_padding_to_child_element(render.Image(height = 65, width = 65, src = capital_greek_letter_src), 23, -10))

    return render.Stack(
        children = items,
    )

def get_info_stack_for_letter(letter_info):
    message = "%s is %s or in lowercase %s and is pronounced '%s'." % (letter_info["name"], letter_info["letter"], letter_info["lowercase"], letter_info["pronunciation"])
    return render.Marquee(width = 64, child = render.Text(message, color = LETTER_COLOR, font = "5x8"))

def get_letter_options():
    letter_options = [
        schema.Option(
            display = "%s - %s %s" % (letter["name"], letter["letter"], letter["lowercase"]),
            value = letter["name"],
        )
        for letter in GREEK_ALPHABET
    ]

    letter_options.insert(
        0,
        schema.Option(
            display = "Random",
            value = "Random",
        ),
    )

    return letter_options

def main(config):
    show_info_bar = config.bool("show_info_bar", True)
    selected_letter = config.get("letter_selected")

    if selected_letter == "Random" or selected_letter == None:
        random_number = random.number(0, len(GREEK_ALPHABET) - 1)
        display_letter_item = GREEK_ALPHABET[random_number]
    else:
        display_letter_item = get_letter_by_name(selected_letter)

    display_items = []
    display_items.append(get_image_stack_for_letter(display_letter_item))

    if show_info_bar:
        display_items.append(add_padding_to_child_element(get_info_stack_for_letter(display_letter_item), 0, 24))

    return render.Root(
        render.Stack(
            children = display_items,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_schema():
    letter_options = get_letter_options()

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

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "letter_selected",
                name = "Selected Greek Letter",
                desc = "What Letter do you want to display?",
                icon = "z",  #"palette","paintbrush"
                options = letter_options,
                default = letter_options[len(letter_options) - 1].value,
            ),
            schema.Toggle(
                id = "show_info_bar",
                name = "Info Bar",
                desc = "Scroll information about the Greek Letter",
                icon = "scroll",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "car",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
