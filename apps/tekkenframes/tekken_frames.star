"""
Applet: Tekken Frames
Summary: Tekken 8 frame data
Description: Displays random Tekken 8 move frame data as a study tool. Shows character, command, hit level, and frame data with color coding. Supports filtering by character and move type.
Author: mek01
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FONT = "tom-thumb"

COLOR_WHITE = "#FFFFFF"
COLOR_RED = "#FF4444"
COLOR_ORANGE = "#FF8800"
COLOR_YELLOW = "#FFFF00"
COLOR_GREEN = "#44FF44"
COLOR_BLUE = "#4488FF"
COLOR_TEAL = "#44DDDD"
COLOR_GRAY = "#888888"
COLOR_PURPLE = "#CC66FF"
COLOR_PINK = "#FF66AA"
COLOR_LIME = "#AAFF44"
COLOR_CYAN = "#44FFFF"
COLOR_GOLD = "#FFD700"

# Tag key -> (plain text name, color)
TAG_MAP = {
    "pc": ("Power Crush", COLOR_PURPLE),
    "he": ("Heat Engager", COLOR_ORANGE),
    "hom": ("Homing", COLOR_CYAN),
    "trn": ("Tornado", COLOR_LIME),
    "bbr": ("Balcony Break", COLOR_PINK),
    "hb": ("Heat Burst", COLOR_RED),
    "js": ("Jump State", COLOR_BLUE),
    "cs": ("Crouch State", COLOR_BLUE),
    "hw": ("High Wall", COLOR_GOLD),
    "fb": ("Floor Break", COLOR_GOLD),
    "el1": ("Elbow 1", COLOR_GRAY),
    "el2": ("Elbow 2", COLOR_GRAY),
    "el3": ("Elbow 3", COLOR_GRAY),
}

CHARACTERS = [
    "alisa",
    "anna",
    "armor-king",
    "asuka",
    "azucena",
    "bryan",
    "claudio",
    "clive",
    "devil-jin",
    "dragunov",
    "eddy",
    "fahkumram",
    "feng",
    "heihachi",
    "hwoarang",
    "jack-8",
    "jin",
    "jun",
    "kazuya",
    "king",
    "kuma",
    "lars",
    "law",
    "lee",
    "leo",
    "leroy",
    "lidia",
    "lili",
    "miary-zo",
    "nina",
    "panda",
    "paul",
    "raven",
    "reina",
    "shaheen",
    "steve",
    "victor",
    "xiaoyu",
    "yoshimitsu",
    "zafina",
]

CACHE_TTL = 21600  # 6 hours

API_BASE = "https://tekkendocs.com/api/t8"

def main(config):
    # Get enabled characters
    enabled = get_enabled_characters(config)
    if len(enabled) == 0:
        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text("NO CHARS", font = FONT, color = COLOR_RED),
                        render.Text("ENABLED", font = FONT, color = COLOR_RED),
                    ],
                ),
            ),
        )

    # Pick random character
    char_slug = enabled[random.number(0, len(enabled) - 1)]

    # Fetch frame data
    data = get_framedata(char_slug)
    if data == None:
        return render.Root(
            child = render.Box(
                render.Text("API ERROR", font = FONT, color = COLOR_RED),
            ),
        )

    moves = data.get("framesNormal", [])
    if len(moves) == 0:
        return render.Root(
            child = render.Box(
                render.Text("NO MOVES", font = FONT, color = COLOR_RED),
            ),
        )

    # Filter moves if any filters are active
    filtered = filter_moves(moves, config)
    if len(filtered) == 0:
        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text("NO MOVES", font = FONT, color = COLOR_YELLOW),
                        render.Text("MATCH", font = FONT, color = COLOR_YELLOW),
                    ],
                ),
            ),
        )

    # Pick random move
    move = filtered[random.number(0, len(filtered) - 1)]

    # Build display rows
    char_name = get_display_name(char_slug)
    command = move.get("command", "???")
    hit_level = move.get("hitLevel", "")
    startup = move.get("startup", "")
    block = move.get("block", "")
    hit = move.get("hit", "")
    counter_hit = move.get("counterHit", "")

    tags = move.get("tags", {})
    damage = move.get("damage", "")
    tags_widget = render_tags(tags)
    block_color = parse_block_color(block)

    # Row 1: Character name
    row1 = render.Text(char_name, font = FONT, color = COLOR_GREEN)

    # Row 2: Command (left) | Hit Level (right), 50/50 with 3px gap
    row2 = render_split_row(
        render.Text(command, font = FONT, color = COLOR_WHITE),
        render_hit_level(hit_level),
    )

    # Row 3: F (frames/startup) left | B (block) right
    row3 = render_labeled_split_row(
        "F",
        startup if startup != "" else "--",
        COLOR_WHITE,
        "B",
        block if block != "" else "--",
        block_color,
    )

    # Row 4: H (hit) left | CH (counter hit) right — CH has no space
    row4 = render_labeled_split_row(
        "H",
        hit if hit != "" else "--",
        COLOR_WHITE,
        "CH",
        counter_hit if counter_hit != "" else "--",
        COLOR_WHITE,
    )

    # Row 5: Damage (left) | Tags/properties (right), 50/50
    row5 = render_split_row(
        render.Text(damage if damage != "" else "--", font = FONT, color = COLOR_WHITE),
        tags_widget if tags_widget != None else render.Text("--", font = FONT, color = COLOR_GRAY),
    )

    quiz_mode = config.bool("quiz_mode", False)

    if quiz_mode:
        hidden_row3 = render_labeled_split_row(
            "F",
            "?",
            COLOR_GRAY,
            "B",
            "?",
            COLOR_GRAY,
        )
        hidden_row4 = render_labeled_split_row(
            "H",
            "?",
            COLOR_GRAY,
            "CH",
            "?",
            COLOR_GRAY,
        )

        frame_hidden = render_layout(row1, row2, hidden_row3, hidden_row4, row5)
        frame_revealed = render_layout(
            render.Text(char_name, font = FONT, color = COLOR_GREEN),
            render_split_row(
                render.Text(command, font = FONT, color = COLOR_WHITE),
                render_hit_level(hit_level),
            ),
            render_labeled_split_row(
                "F ",
                startup if startup != "" else "--",
                COLOR_WHITE,
                "B ",
                block if block != "" else "--",
                block_color,
            ),
            render_labeled_split_row(
                "H",
                hit if hit != "" else "--",
                COLOR_WHITE,
                "CH",
                counter_hit if counter_hit != "" else "--",
                COLOR_WHITE,
            ),
            render_split_row(
                render.Text(damage if damage != "" else "--", font = FONT, color = COLOR_WHITE),
                tags_widget if tags_widget != None else render.Text("--", font = FONT, color = COLOR_GRAY),
            ),
        )

        frames = []
        for _ in range(75):
            frames.append(frame_hidden)
        for _ in range(75):
            frames.append(frame_revealed)

        return render.Root(
            delay = 75,
            child = render.Animation(children = frames),
        )

    return render.Root(
        child = render_layout(row1, row2, row3, row4, row5),
    )

def get_framedata(character):
    cache_key = "tekken_fd_%s" % character
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    url = "%s/%s/framedata" % (API_BASE, character)
    resp = http.get(url)
    if resp.status_code != 200:
        return None

    body = resp.body()
    cache.set(cache_key, body, ttl_seconds = CACHE_TTL)
    return json.decode(body)

def render_split_row(left, right):
    """Render a 50/50 split row with 3px gap, both sides marquee."""
    half = 30  # (64 - 4) / 2 = 30, with 4px gap
    return render.Row(
        children = [
            render.Marquee(width = half, child = left),
            render.Box(width = 4, height = 5),
            render.Marquee(width = half, child = right),
        ],
    )

def render_labeled_split_row(left_label, left_val, left_color, right_label, right_val, right_color):
    """Render a split row where labels are fixed and values marquee."""
    left_label_w = len(left_label) * 4  # 4px per char in tom-thumb
    right_label_w = len(right_label) * 4
    gap = 4
    left_val_w = 30 - left_label_w
    right_val_w = 30 - right_label_w
    return render.Row(
        children = [
            render.Text(left_label, font = FONT, color = COLOR_GRAY),
            render.Marquee(width = left_val_w, child = render.Text(left_val, font = FONT, color = left_color)),
            render.Box(width = gap, height = 6),
            render.Text(right_label, font = FONT, color = COLOR_GRAY),
            render.Marquee(width = right_val_w, child = render.Text(right_val, font = FONT, color = right_color)),
        ],
    )

def render_tags(tags):
    """Render move tags as colored text widgets in a Row."""
    if tags == None or type(tags) != "dict":
        return None

    children = []
    for key in tags:
        entry = TAG_MAP.get(key, None)
        if entry != None:
            name, color = entry
        else:
            name = key.upper()
            color = COLOR_GRAY

        if len(children) > 0:
            children.append(render.Text(" | ", font = FONT, color = COLOR_GRAY))
        children.append(render.Text(name, font = FONT, color = color))

    if len(children) == 0:
        return None
    return render.Row(children = children)

def render_layout(row1, row2, row3, row4, row5):
    """Render the 5-row layout. 5 rows x 5px + 4 gaps x 1px = 29px, fits in 32."""
    return render.Column(
        children = [
            row1,
            render.Box(width = 64, height = 1),
            row2,
            render.Box(width = 64, height = 1),
            row3,
            row4,
            render.Box(width = 64, height = 1),
            row5,
        ],
    )

def get_enabled_characters(config):
    mode = config.str("chars_mode", "all")
    if mode == "all":
        return list(CHARACTERS)
    elif mode == "none":
        return []
    else:
        # "custom" — use individual toggles
        enabled = []
        for slug in CHARACTERS:
            key = "char_%s" % slug
            if config.bool(key, False):
                enabled.append(slug)
        return enabled

def get_display_name(slug):
    return slug.replace("-", " ").upper()

def filter_moves(moves, config):
    filters_mode = config.str("filters_mode", "off")

    if filters_mode == "off":
        return moves

    all_filters = filters_mode == "all"

    if not all_filters:
        # "custom" — check if any individual filter is on
        filter_keys = [
            "filter_launchers",
            "filter_plus",
            "filter_pc",
            "filter_he",
            "filter_hom",
            "filter_trn",
            "filter_bbr",
            "filter_lows",
            "filter_throws",
        ]
        any_active = False
        for key in filter_keys:
            if config.bool(key, False):
                any_active = True
                break
        if not any_active:
            return moves

    filtered = []
    for move in moves:
        if move_matches_filters(move, config, all_filters):
            filtered.append(move)
    return filtered

def move_matches_filters(move, config, all_filters):
    tags = move.get("tags", {})
    hit_level = move.get("hitLevel", "").lower()
    block_str = move.get("block", "")
    hit_str = move.get("hit", "")
    ch_str = move.get("counterHit", "")

    if all_filters or config.bool("filter_launchers", False):
        if is_launcher(hit_str, ch_str):
            return True

    if all_filters or config.bool("filter_plus", False):
        block_val = parse_frame_value(block_str)
        if block_val != None and block_val > 0:
            return True

    if all_filters or config.bool("filter_pc", False):
        if "pc" in tags:
            return True

    if all_filters or config.bool("filter_he", False):
        if "he" in tags:
            return True

    if all_filters or config.bool("filter_hom", False):
        if "hom" in tags:
            return True

    if all_filters or config.bool("filter_trn", False):
        if "trn" in tags:
            return True

    if all_filters or config.bool("filter_bbr", False):
        if "bbr" in tags:
            return True

    if all_filters or config.bool("filter_lows", False):
        if "l" in hit_level:
            return True

    if all_filters or config.bool("filter_throws", False):
        if "t" in hit_level:
            return True

    return False

def is_launcher(hit_str, ch_str):
    # Launch indicators in Tekken frame data
    launch_indicators = ["launch", "cs", "js", "w!", "knd"]
    combined = (hit_str + " " + ch_str).lower()
    for indicator in launch_indicators:
        if indicator in combined:
            return True
    return False

def parse_frame_value(frame_str):
    if frame_str == "" or frame_str == None:
        return None

    # Strip common suffixes like 'a', 'g', 'c', '~' stuff
    cleaned = frame_str.strip()

    # Handle leading +/- and extract number
    sign = 1
    start = 0

    if len(cleaned) == 0:
        return None

    if cleaned[0] == "+":
        sign = 1
        start = 1
    elif cleaned[0] == "-":
        sign = -1
        start = 1

    # Extract digits
    digits = ""
    for i in range(start, len(cleaned)):
        c = cleaned[i]
        if c >= "0" and c <= "9":
            digits += c
        else:
            break

    if digits == "":
        return None

    return sign * int(digits)

def parse_block_color(block_str):
    val = parse_frame_value(block_str)
    if val == None:
        return COLOR_WHITE

    if val <= -10:
        return COLOR_RED
    elif val < 0:
        return COLOR_ORANGE
    elif val == 0:
        return COLOR_YELLOW
    else:
        return COLOR_GREEN

def render_hit_level(hit_level_str):
    if hit_level_str == "" or hit_level_str == None:
        return render.Text("???", font = FONT, color = COLOR_WHITE)

    parts = hit_level_str.replace(" ", "").split(",")
    children = []

    for i, part in enumerate(parts):
        if i > 0:
            children.append(render.Text(",", font = FONT, color = COLOR_WHITE))

        p = part.lower().strip()
        color = COLOR_WHITE
        if p == "h":
            color = COLOR_RED
        elif p == "m":
            color = COLOR_YELLOW
        elif p == "l":
            color = COLOR_BLUE
        elif p == "t" or p == "th" or "throw" in p:
            color = COLOR_TEAL
        elif p == "sm":
            color = COLOR_YELLOW  # special mid

        children.append(render.Text(part, font = FONT, color = color))

    return render.Row(children = children)

def get_schema():
    # Character toggles
    char_fields = []
    for slug in CHARACTERS:
        char_fields.append(
            schema.Toggle(
                id = "char_%s" % slug,
                name = get_display_name(slug),
                desc = "Include %s in random selection" % get_display_name(slug),
                icon = "gamepad",
                default = False,
            ),
        )

    # Move type filter toggles
    filter_fields = [
        schema.Toggle(
            id = "filter_launchers",
            name = "Launchers",
            desc = "Show moves that launch on hit or counter hit",
            icon = "arrowUp",
            default = False,
        ),
        schema.Toggle(
            id = "filter_plus",
            name = "Plus on Block",
            desc = "Show moves that are plus on block",
            icon = "shieldHalved",
            default = False,
        ),
        schema.Toggle(
            id = "filter_pc",
            name = "Power Crush",
            desc = "Show Power Crush moves",
            icon = "burst",
            default = False,
        ),
        schema.Toggle(
            id = "filter_he",
            name = "Heat Engager",
            desc = "Show Heat Engager moves",
            icon = "fire",
            default = False,
        ),
        schema.Toggle(
            id = "filter_hom",
            name = "Homing",
            desc = "Show Homing moves",
            icon = "bullseye",
            default = False,
        ),
        schema.Toggle(
            id = "filter_trn",
            name = "Tornado",
            desc = "Show Tornado moves",
            icon = "tornado",
            default = False,
        ),
        schema.Toggle(
            id = "filter_bbr",
            name = "Balcony Break",
            desc = "Show Balcony Break moves",
            icon = "building",
            default = False,
        ),
        schema.Toggle(
            id = "filter_lows",
            name = "Lows",
            desc = "Show Low attacks",
            icon = "arrowDown",
            default = False,
        ),
        schema.Toggle(
            id = "filter_throws",
            name = "Throws",
            desc = "Show Throw moves",
            icon = "handFist",
            default = False,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "quiz_mode",
                name = "Quiz Mode",
                desc = "Hide frame data for the first half of the display cycle",
                icon = "graduationCap",
                default = False,
            ),
            schema.Dropdown(
                id = "filters_mode",
                name = "Move Filters",
                desc = "Filter which moves are shown",
                icon = "filter",
                default = "off",
                options = [
                    schema.Option(display = "Off (show any move)", value = "off"),
                    schema.Option(display = "All filters on", value = "all"),
                    schema.Option(display = "Custom", value = "custom"),
                ],
            ),
        ] + filter_fields + [
            schema.Dropdown(
                id = "chars_mode",
                name = "Characters",
                desc = "Which characters to include",
                icon = "users",
                default = "all",
                options = [
                    schema.Option(display = "All characters", value = "all"),
                    schema.Option(display = "None", value = "none"),
                    schema.Option(display = "Custom", value = "custom"),
                ],
            ),
        ] + char_fields,
    )
