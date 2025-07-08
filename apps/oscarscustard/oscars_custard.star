"""
Applet: Oscar's Custard
Summary: Today's Oscar's flavors
Description: Get today's flavors at Oscar's Frozen Custard.
Author: Josiah Winslow
"""

load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")

WIDTH = 64
HEIGHT = 32

DELAY = 30
ERROR_DELAY = 45
SCROLL_SPEED = 2
TTL_SECONDS = 60 * 30  # 30 minutes

OSCARS_ICON_WIDTH = 64
OSCARS_ICON_HEIGHT = 23
OSCARS_ICON = base64.decode("""
UklGRjYFAABXRUJQVlA4WAoAAAAQAAAAPwAAFgAAQUxQSH4BAAABkCvbtmlb89q2bdu2zQjP70W2/VL
btm1H17Ztc+8ZbNW56wciYgKAr7jLns8Nzf/2aAChpifbKETEpfNyItMr3JOlKiy+FDnHAkRl+Y3Ghb
dBYgLSepF7IU1UJ5DZv0mal2sT8pwKFpHsNxacjOMjex/5tpoypNX01KQYErouvk5aqhYG4gDKRuaas
T1seJRLNe3GNK/m1eYSdluel9aVPNlgIhNxtWpwsr/sf3vt4cRT/5raKgeQ842zJEvk1zkUSNXfaUH2
iqejyE3NokC675QxAOT3IcFf7SC6H4l+pP0TyW5fMUdY6Uskmz7UQBje6yCtp5E0+jVpVMEMYR0qTwi
7BLb/lt3UPJ8GVwDLW1McM73L48FpimskDwBALvZicc/oUMOLXN/vNGP+w46SRRaq/sDNflpAuYfC7m
4WqjxTnAEgruPq62UuC2B8qLiv9cNaTTDb+LF1sPX7HnuQ8d95+/Xr169f3Lpx48aNm0edAMT8zlUMd
P7ebQkAVlA4IJIDAAAQEgCdASpAABcAPpE+mkkloyKhLAgAsBIJbACdM0dBt7neL2qg1G2o52PTYPQl
8s79gPhO/cD0gKxByA+HPZzKSMEf+A/JTgCeKfzr/bflHzGaSCZ945fpD/r+4Z/Jv7H/yuxAKZoGJtr
uNwrpGwLGvPLNYjAiqPJzc5bOEoZACJN0ZMp/B7mHL/mapiow0508+9IHs6rlsyAA/uvjCd+kNHvgXV
l08dJjQIrF/NBhBXXmnaH4bg7gSzcqhvcrOsjALSONTZMcs4tjyxtHNK2nozYqK/2QB+QIo6Hrg3lCu
nCS5CFeQRgRe0wMNnFgvt9zaBH/zuapPv7TDxVeHUpJjU8x3kGEB0kDiXrqvdNNjzrt7EfP5Plv/rGP
GSPZRKqoIlG+QtvTeKX+g0C7SiAm8dqn+LXqgb1/Ikt2V//fVe5ZNC6k3w6nxvOvzPy+Pr30Jqf+cK6
i/pBZlnW1AC2QOa7ofgzH8f9f+MzzL2K+e2vy4zIcQvgXxMSw17dJ6ijqd1LR4Zy+ODP+UzygLOsCiQ
uhsv90G82Ym4jNytEWBf/v/WrZ2uPMORS/349tZg0Fyf2y+lS/TRl0Qv/6+1iX0DIjcctVyslv9p/+D
hNQWChmPBRLPmiYym4PtQvIHtEuvWLL/TIk8O//woK1oOZv1YkCyNsdzojqYRvANFgZiVluFrHBWzn6
KGfM/JrlB/ZvZdjUyVNh+aJJuUH9y26zIdzYqYHShF70hwV7PTDhwyjJ0XtMbUREEaD3n4IO3/76O3u
c7UCqBeH4nFJYLwmLol2l/y2H5QWGEF9dTvoI/UArOhNramTHZ3Kl/z/ZtG+T0nwO1w+HCa/7/l3FHQ
dF0gLcueiUgCWD9dkFOgCzwb4Q6wqDLx4X/+h4y97IC2cBHvaeb/3/4fNN86af3q/pq++z/+PwVGUxQ
BPkXo5xf2gyp/8TDNgfdD3l30cfuauCcF/81Oe/nF9PCRU8y/30QubrqY/X0UJuGWSQAT3DSVjIJsgQ
AAqy2L14IbZGOPGT3fG6LepLm8geOQ9+fkW61jjOH+f+Xmza46B2ZsCQbPAqFQg3TaIEpQ2qNLBSl3Y
AFQF0IkHDgezHGOt+p3f9mlbxq/devA4gRy5380rqWMR2k6nPiD8aoWWLW/YFDDl7RF7zGsHlnCi2cE
gqAfXoNL+fLMNL+4HPQL3my73+/+t3b62ghSXrIzSj/In5a2uEAA==
""")
OSCARS_HOMEPAGE_EXCERPT_URL = (
    "https://www.oscarscustard.com/index.php/wp-json/wp/v2/pages/41?_fields=" +
    "excerpt"
)

MIN_CONTRAST = 4.5

# Palette from https://lospec.com/palette-list/brilliance-32
PURPLE = "8658d1"
PINK = "e883ff"
PEACH = "ffd4c9"
LIGHT_RED = "ff6f7a"
RED = "d02a48"
DARK_RED = "762b25"
MAROON = "441d26"
CRIMSON = "781122"
BRIGHT_RED = "ad0707"
ORANGE = "ca5624"
GOLD = "d68622"
LIGHT_ORANGE = "ffb537"
YELLOW = "ffef85"
LIGHT_GREEN = "9dfa87"
GREEN = "7cca71"
LEAF_GREEN = "469e4a"
FOREST_GREEN = "376527"
DARK_GREEN = "263a21"
TEAL = "0a2526"
NAVY = "1f3d6a"
STEEL_BLUE = "3d5a7d"
SKY_BLUE = "559fbc"
CYAN = "6dd7ff"
PALE_CYAN = "9cffff"
WHITE = "ffffff"
LIGHT_GRAY = "b0b5c3"
GRAY = "79757a"
DARK_GRAY = "474347"
BLACK = "000000"
BROWN = "3a231a"
TAN = "895d45"
BEIGE = "dba68d"
PALETTE = [
    PURPLE,
    PINK,
    PEACH,
    LIGHT_RED,
    RED,
    DARK_RED,
    MAROON,
    CRIMSON,
    BRIGHT_RED,
    ORANGE,
    GOLD,
    LIGHT_ORANGE,
    YELLOW,
    LIGHT_GREEN,
    GREEN,
    LEAF_GREEN,
    FOREST_GREEN,
    DARK_GREEN,
    TEAL,
    NAVY,
    STEEL_BLUE,
    SKY_BLUE,
    CYAN,
    PALE_CYAN,
    WHITE,
    LIGHT_GRAY,
    GRAY,
    DARK_GRAY,
    BLACK,
    BROWN,
    TAN,
    BEIGE,
]

# NOTE Certain words in the flavor names suggest certain colors should
# be used. I call these "palette hints".
PALETTE_HINTS = {
    "BADGER": WHITE,
    "BANANA": YELLOW,
    "BLACK": BLACK,
    "BLUE": TEAL,
    "BROWNIE": TAN,
    "BURGER": BLACK,
    "BUTTERFINGER": LIGHT_ORANGE,
    "CARAMEL": ORANGE,
    "CHERRY": RED,
    "CHOCOLATE": TAN,
    "CLAW": BRIGHT_RED,
    "COOKIE": PEACH,
    "CUSTARD": WHITE,
    "GRAND": WHITE,
    "HEATH": ORANGE,
    "HOG": PINK,
    "LEMON": YELLOW,
    "MINT": LIGHT_GREEN,
    "MOON": PALE_CYAN,
    "MONKEY": BROWN,
    "MUDD": BEIGE,
    "MUDDER": BEIGE,
    "-N-": WHITE,
    "OL'": RED,
    "OSCAR'S": PEACH,
    "PEANUTBUTTER": TAN,
    "PISTACHIO": GREEN,
    "RASPBERRY": LIGHT_GRAY,
    "RED": CRIMSON,
    "ROAD": GRAY,
    "SNICKERS": BROWN,
    "STRAWBERRY": LIGHT_RED,
    "TOFFEE": BEIGE,
    "TROPICAL": PALE_CYAN,
    "TURTLE": FOREST_GREEN,
    "TWIX": GOLD,
}

# Similar to itertools.pairwise
def pairwise(first):
    second = first[1:] + first[:1]
    return zip(first, second)

def hex_to_rgb(hex):
    return [
        int(hex[i:i + 2], 16)
        for i in range(0, 6, 2)
    ]

def rgb_to_hex(rgb):
    return "%x%x%x%x%x%x" % (
        rgb[0] // 16,
        rgb[0] % 16,
        rgb[1] // 16,
        rgb[1] % 16,
        rgb[2] // 16,
        rgb[2] % 16,
    )

# https://www.w3.org/TR/2008/REC-WCAG20-20081211/#contrast-ratiodef
def contrast_ratio(color_1, color_2):
    l1 = relative_luminance(color_1)
    l2 = relative_luminance(color_2)

    # L1 should be the luminance of the lighter of the two colors
    if l1 < l2:
        l1, l2 = l2, l1
    return (l1 + 0.05) / (l2 + 0.05)

# https://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
def relative_luminance(color):
    def luminance_part(val):
        if val <= 10.0164:
            return val / 3294.6
        else:
            return math.pow(val / 269 + 0.0521327, 2.4)

    r, g, b = [luminance_part(val) for val in hex_to_rgb(color)]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def random_contrasting_color(color, palette = None, fallback = True):
    # Use full palette if not restricting the palette
    if not palette:
        palette = PALETTE
        fallback = False

    palette_index = random.number(0, len(palette) - 1)
    for _ in range(len(palette)):
        palette_index = (palette_index + 1) % len(palette)
        contrasting_color = palette[palette_index]
        if contrast_ratio(contrasting_color, color) >= MIN_CONTRAST:
            return contrasting_color

    # If we want to use full palette upon failure, try again
    if fallback:
        return random_contrasting_color(color, fallback = False)

    # Last resort: use pure black/white based on luminance
    color_is_dark = relative_luminance(color) < 0.5
    return "ffffff" if color_is_dark else "000000"

def palette_from_name(name, palette = None):
    # If palette is empty or not given, prefer using "palette hints"
    if not palette:
        palette = {}
        for part in name.split():
            if part in PALETTE_HINTS:
                palette[PALETTE_HINTS[part]] = True
        palette = list(palette) or PALETTE

    # First color is random palette color
    palette_index = random.number(0, len(palette) - 1)
    bg_color = palette[palette_index]
    palette = [p for i, p in enumerate(palette) if i != palette_index]

    # Second color is a random color that contrasts with the first one,
    # also from the palette if possible
    fg_color = random_contrasting_color(bg_color, palette)

    # Swap the colors with some probability
    if random.number(0, 9) >= 4:
        bg_color, fg_color = fg_color, bg_color
    return bg_color, fg_color

def normalize_flavor_name(name):
    name = name.strip().upper()

    # Replace special apostrophes
    name = re.sub(r"[‘’]", "'", name)

    # Replace accented characters
    name = re.sub(r"[ÁÀÂÄÃÅ]", "A", name)
    name = re.sub(r"[Ç]", "C", name)
    name = re.sub(r"[ÉÈÊË]", "E", name)
    name = re.sub(r"[ÍÌÎÏ]", "I", name)
    name = re.sub(r"[Ñ]", "N", name)
    name = re.sub(r"[ÓÒÔÖÕØ]", "O", name)
    name = re.sub(r"[ÚÙÛÜ]", "U", name)

    # Replace ellipses
    name = re.sub(r"[…]", "...", name)

    # Remove special characters
    name = re.sub(r"[^\w\d \-'&.!]", "", name)

    return name

def get_featured_items():
    items = {}

    # Request Oscar's homepage excerpt JSON
    # HACK There seems to be no way to get the featured items in a neat
    # format; the best way I can find is by using regexes to parse some
    # ugly smooshed-together lines of text, which look like this:
    # "Flavor of the DayTuesday, May 27: OSCAR'S DELIGHT -or- BLACK
    # RASPBERRYMay FeaturesQUESO BURGER ".
    rep = http.get(OSCARS_HOMEPAGE_EXCERPT_URL, ttl_seconds = TTL_SECONDS)
    if rep.status_code != 200:
        return {
            "error": "Oscar's status code: %s" % rep.status_code,
        }
    text = html(rep.json()["excerpt"]["rendered"]).text()

    # Extract the sandwich of the month
    sandwich_match = re.match(
        r"Features([A-Z !&'\-.ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜ‘’…]+) ",
        text,
    )
    if sandwich_match:
        items["sandwich"] = normalize_flavor_name(sandwich_match[0][1])
    else:
        items["sandwich"] = "Unrecognized sandwich"

    # Extract the flavor of the day
    flavor_match = re.match(
        r"FLAVOR OF THE DAY.+:\s+(.+)(?:January|February|March|April|May|" +
        r"June|July|August|September|October|November|December) ",
        text,
    )
    if flavor_match:
        items["flavors"] = [
            normalize_flavor_name(flavor)
            # There might be two flavors separated by an "or"
            for flavor in flavor_match[0][1].split(" -or- ")
        ]
    else:
        items["flavors"] = ["Unrecognized flavor"]

    return items

def render_scroll_frames(child, next_child):
    return [
        render.Stack(
            children = [
                render.Padding(
                    pad = (0, -offset, 0, 0),
                    child = child,
                ),
                render.Padding(
                    pad = (0, HEIGHT - offset, 0, 0),
                    child = next_child,
                ),
            ],
        )
        for offset in range(0, HEIGHT, SCROLL_SPEED)
    ]

def render_failure(text):
    return render.Root(
        # HACK This is the only way I know how to change the marquee
        # speed. But it also changes the speed of everything else.
        # Therefore, the obvious solution is to include nothing else.
        delay = ERROR_DELAY,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Image(src = OSCARS_ICON),
                render.Box(
                    height = HEIGHT - OSCARS_ICON_HEIGHT,
                    child = render.Marquee(
                        width = WIDTH,
                        offset_start = WIDTH,
                        offset_end = WIDTH,
                        align = "center",
                        child = render.Text(color = "#f00", content = text),
                    ),
                ),
            ],
        ),
    )

def main():
    # Get today's items of the day
    items = get_featured_items()

    # If failed to retrieve items
    if "error" in items:
        return render_failure(items["error"])

    # Output will be rendered as a series of frames
    # Frames will be rendered based on a series of screens
    frames = []
    screens = []

    # "Oscar's Frozen Custard" splash screen
    screens.append([
        render.Column(
            cross_align = "center",
            children = [
                render.Image(src = OSCARS_ICON),
                render.Box(
                    height = HEIGHT - OSCARS_ICON_HEIGHT,
                    child = render.Text(
                        color = "#fff",
                        font = "tom-thumb",
                        content = "FROZEN CUSTARD",
                    ),
                ),
            ],
        ),
    ] * 86)

    for flavor in items["flavors"]:
        # Calculate RNG seed based on flavor(s) of the day
        flavor_seed = 0x600df00d ^ hash(flavor)
        random.seed(flavor_seed)
        bg_color, fg_color = palette_from_name(flavor)

        # Flavor(s) of the day
        screens.append([
            render.Box(
                height = HEIGHT,
                color = bg_color,
                child = render.WrappedText(
                    align = "center",
                    color = fg_color,
                    width = WIDTH,
                    content = flavor,
                ),
            ),
        ] * 106)

    # Calculate RNG seed based on sandwich of the day
    sandwich = items["sandwich"]
    sandwich_seed = 0xbeefbeef ^ hash(sandwich)
    random.seed(sandwich_seed)
    bg_color, fg_color = palette_from_name(sandwich)

    # Burger of the month
    screens.append([
        render.Box(
            height = HEIGHT,
            color = bg_color,
            child = render.WrappedText(
                align = "center",
                color = fg_color,
                width = WIDTH,
                content = sandwich,
            ),
        ),
    ] * 106)

    for screen, next_screen in pairwise(screens):
        frames.extend(screen)
        frames.extend(render_scroll_frames(screen[-1], next_screen[0]))

    return render.Root(
        delay = DELAY,
        child = render.Animation(children = frames),
    )
