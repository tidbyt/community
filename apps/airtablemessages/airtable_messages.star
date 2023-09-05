"""
Applet: Airtable Messages
Summary: Display Airtable messages
Description: Display a scrolling message sent via an Airtable form.
Author: Kyle Bolstad
"""

load("http.star", "http")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

AIRTABLE_API_URL = "https://api.airtable.com/v0"
AIRTABLE_DATE_FIELD = "Date"
AIRTABLE_MESSAGE_FIELD = "Message"
AIRTABLE_NAME_FIELD = "Name"

EMOJI_ICON_SIZE = 32
EMOJI_ICON_URL = "https://raw.githubusercontent.com/googlefonts/noto-emoji/main/png/%s/emoji_u%s.png"
UNICODE_API_URL = "https://ucdapi.org/unicode/latest/chars/%s/name"

DEFAULT_AIRTABLE_API_TOKEN = ""
DEFAULT_AIRTABLE_BASE_ID = ""
DEFAULT_AIRTABLE_TABLE_ID = ""
DEFAULT_AUTHOR_FONT = "tom-thumb"
DEFAULT_CHARACTER_WIDTH = 4
DEFAULT_COLOR = "#FFFFFF"
DEFAULT_DELAY = 120
DEFAULT_EMOJI_SIZE = 16
DEFAULT_LINE_HEIGHT = 6
DEFAULT_MAX_AGE = 60 * 60 * 24
DEFAULT_MESSAGE_FONT = "tom-thumb"
DEFAULT_OFFSET = 0
DEFAULT_PRINT_LOG = False
DEFAULT_RANDOM_MESSAGE = False
DEFAULT_SHOW_UNICODE = "Icon"
DEFAULT_TIMEZONE = "America/Chicago"

AIRTABLE_PARAMETERS = "sort%5B0%5D%5Bfield%5D=Date&sort%5B0%5D%5Bdirection%5D=desc"
AUTHOR_MAX_ROWS = 1
DIVIDER_HEIGHT = 1
EMOJI_RANGE = "\u00A9\u00AE\u203C\u2049\u2122\u2139\u2194-\u2199\u21A9\u21AA\u231A\u231B\u2328\u23CF\u23E9-\u23F3\u23F8-\u23FA\u24C2\u25AA\u25AB\u25B6\u25C0\u25FB-\u25FE\u2600-\u2604\u260E\u2611\u2614\u2615\u2618\u261D\u2620\u2622\u2623\u2626\u262A\u262E\u262F\u2638-\u263A\u2640\u2642\u2648-\u2653\u265F\u2660\u2663\u2665\u2666\u2668\u267B\u267E\u267F\u2692-\u2697\u2699\u269B\u269C\u26A0\u26A1\u26A7\u26AA\u26AB\u26B0\u26B1\u26BD\u26BE\u26C4\u26C5\u26C8\u26CE\u26CF\u26D1\u26D3\u26D4\u26E9\u26EA\u26F0-\u26F5\u26F7-\u26FA\u26FD\u2702\u2705\u2708-\u270D\u270F\u2712\u2714\u2716\u271D\u2721\u2728\u2733\u2734\u2744\u2747\u274C\u274E\u2753-\u2755\u2757\u2763\u2764\u2795-\u2797\u27A1\u27B0\u27BF\u2934\u2935\u2B05-\u2B07\u2B1B\u2B1C\u2B50\u2B55\u3030\u303D\u3297\u3299\U0001F004\U0001F0CF\U0001F170\U0001F171\U0001F17E\U0001F17F\U0001F18E\U0001F191-\U0001F19A\U0001F1E6-\U0001F1FF\U0001F201\U0001F202\U0001F21A\U0001F22F\U0001F232-\U0001F23A\U0001F250\U0001F251\U0001F300-\U0001F321\U0001F324-\U0001F393\U0001F396\U0001F397\U0001F399-\U0001F39B\U0001F39E-\U0001F3F0\U0001F3F3-\U0001F3F5\U0001F3F7-\U0001F4FD\U0001F4FF-\U0001F53D\U0001F549-\U0001F54E\U0001F550-\U0001F567\U0001F56F\U0001F570\U0001F573-\U0001F57A\U0001F587\U0001F58A-\U0001F58D\U0001F590\U0001F595\U0001F596\U0001F5A4\U0001F5A5\U0001F5A8\U0001F5B1\U0001F5B2\U0001F5BC\U0001F5C2-\U0001F5C4\U0001F5D1-\U0001F5D3\U0001F5DC-\U0001F5DE\U0001F5E1\U0001F5E3\U0001F5E8\U0001F5EF\U0001F5F3\U0001F5FA-\U0001F64F\U0001F680-\U0001F6C5\U0001F6CB-\U0001F6D2\U0001F6D5-\U0001F6D7\U0001F6DC-\U0001F6E5\U0001F6E9\U0001F6EB\U0001F6EC\U0001F6F0\U0001F6F3-\U0001F6FC\U0001F7E0-\U0001F7EB\U0001F7F0\U0001F90C-\U0001F93A\U0001F93C-\U0001F945\U0001F947-\U0001F9FF\U0001FA70-\U0001FA7C\U0001FA80-\U0001FA88\U0001FA90-\U0001FABD\U0001FABF-\U0001FAC5\U0001FACE-\U0001FADB\U0001FAE0-\U0001FAE8\U0001FAF0-\U0001FAF8"
TIDBYT_CYCLE_MIN = 5
TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64
OFFSET = int(TIDBYT_HEIGHT / 2)
OFFSET_RATIO = 2.75
WHITESPACE = ("\n", " ")

FONTS = {
    "tb-8": {
        "width": 5,
        "height": 8,
    },
    "Dina_r400-6": {
        "width": 6,
        "height": 10,
    },
    "5x8": {
        "width": 5,
        "height": 8,
    },
    "6x13": {
        "width": 6,
        "height": 13,
    },
    "10x20": {
        "width": 10,
        "height": 20,
    },
    "tom-thumb": {
        "width": 4,
        "height": 6,
    },
    "CG-pixel-3x5-mono": {
        "width": 4,
        "height": 5,
    },
    "CG-pixel-4x5-mono": {
        "width": 5,
        "height": 5,
    },
}

def main(config):
    airtable_api_token = config.str("airtable_api_token", DEFAULT_AIRTABLE_API_TOKEN)
    airtable_base_id = config.str("airtable_base_id", DEFAULT_AIRTABLE_BASE_ID)
    airtable_table_id = config.str("airtable_table_id", DEFAULT_AIRTABLE_TABLE_ID)

    max_age = DEFAULT_MAX_AGE
    if config.get("max_age"):
        max_age = re.sub("\\D", "", config.get("max_age")) or DEFAULT_MAX_AGE
    max_age = int(max_age)

    random_message = config.bool("random_message", DEFAULT_RANDOM_MESSAGE)
    timezone = config.str("timezone", DEFAULT_TIMEZONE)

    author = []
    message = []
    author_text_color = config.str("author_text_color", DEFAULT_COLOR)
    separator_line_color = config.str("separator_line_color", DEFAULT_COLOR)
    message_text_color = config.str("message_text_color", DEFAULT_COLOR)

    show_unicode = config.str("show_unicode", DEFAULT_SHOW_UNICODE)
    author_font = config.str("author_font", DEFAULT_AUTHOR_FONT)
    message_font = config.str("message_font", DEFAULT_MESSAGE_FONT)

    emoji_size = int(config.get("emoji_size", DEFAULT_EMOJI_SIZE))

    delay = DEFAULT_DELAY
    if config.get("delay"):
        delay = re.sub("\\D", "", config.get("delay")) or DEFAULT_DELAY
    delay = int(delay)

    def print_log(statement):
        if config.bool("print_log", DEFAULT_PRINT_LOG):
            print(statement)

    def get_unicode_name(character):
        if character in WHITESPACE:
            return character

        unicode_url = UNICODE_API_URL % character
        unicode_response = http.get(unicode_url, ttl_seconds = DEFAULT_MAX_AGE)
        print_log(unicode_response.url)
        if unicode_response.status_code == 200:
            return unicode_response.json()[0]
        else:
            return ""

    def decimal_to_hex(decimal_value):
        hex_digits = "0123456789ABCDEF"

        if decimal_value < 16:
            return hex_digits[decimal_value]

        quotient = decimal_value // 16
        remainder = decimal_value % 16

        return decimal_to_hex(quotient) + hex_digits[remainder]

    def is_emoji(character):
        return re.findall(r"^[%s]" % EMOJI_RANGE, str(character))

    def replace_text(text, remove = False):
        replaced_text = []
        print_log("text: %s" % text)

        for character in list(text.codepoints()):
            codepoint = ord(character)

            print_log("character: %s with ord: %s and hex: %s" % (character, ord(character), decimal_to_hex(codepoint)))

            if is_emoji(character):
                print_log("emoji: %s" % character)

                if remove:
                    replaced_text.append("")
                elif show_unicode:
                    unicode_character_name = get_unicode_name(character).title()
                    unicode_character_hex = decimal_to_hex(codepoint)

                    print_log(unicode_character_name)

                    if show_unicode == "Icon":
                        unicode_character_icon = http.get(EMOJI_ICON_URL % (EMOJI_ICON_SIZE, unicode_character_hex.lower()), ttl_seconds = DEFAULT_MAX_AGE)
                        print_log(unicode_character_icon.url)

                        if unicode_character_icon.status_code == 200:
                            replaced_text.append(unicode_character_icon.body())
                        else:
                            print_log("failed to retrieve the image")

                    if show_unicode == "Name":
                        print_log("replaced %s with %s" % (character, unicode_character_name))

                        for unicode_character_name_character in list(unicode_character_name.elems()):
                            replaced_text.append(unicode_character_name_character)
            else:
                replaced_text.append(character)

        return replaced_text

    def is_image(text):
        return "".join(list(text.codepoints())[1:4]).lower() in ["gif", "jpg", "png"]

    def get_character_width(font):
        width = FONTS[font]["width"]
        return width or DEFAULT_CHARACTER_WIDTH

    def get_line_height(font):
        height = FONTS[font]["height"]
        return height + 1 or DEFAULT_LINE_HEIGHT

    def get_record(index):
        _author = []
        _message = []
        _date = ""
        airtable_fields = airtable_response and airtable_response[index]["fields"]
        if airtable_fields and AIRTABLE_NAME_FIELD in airtable_fields and AIRTABLE_MESSAGE_FIELD in airtable_fields:
            _author = replace_text(airtable_fields[AIRTABLE_NAME_FIELD], remove = True)
            _message = replace_text(airtable_fields[AIRTABLE_MESSAGE_FIELD])
            _date = time.parse_time(airtable_fields[AIRTABLE_DATE_FIELD])
        return {"author": _author, "message": _message, "date": _date}

    if airtable_base_id and airtable_table_id and airtable_api_token:
        airtable_url = "%s/%s/%s?%s" % (AIRTABLE_API_URL, airtable_base_id, airtable_table_id, AIRTABLE_PARAMETERS)
        airtable_headers = {"Authorization": "Bearer %s" % airtable_api_token}
        airtable = http.get(airtable_url, headers = airtable_headers, ttl_seconds = TIDBYT_CYCLE_MIN)
        airtable_json = airtable.json()

        print_log(airtable.url)
        print_log(airtable_json)

        if airtable.status_code != 200:
            if airtable_json.get("error"):
                message = airtable_json.get("error")
                if type(airtable_json.get("error")) == "dict" and airtable_json.get("error").get("message"):
                    message = airtable_json.get("error")["message"]

            print_log(message)

        else:
            airtable_response = airtable_json.get("records")
            record = get_record(0)
            if record and record.get("date"):
                ago = time.now().in_location(timezone) - record.get("date").in_location(timezone)

                if ago.seconds > max_age:
                    if random_message:
                        record = get_record(random.number(0, len(airtable_response) - 1))
                    else:
                        return []

            if record.get("author") and record.get("message"):
                author = record.get("author")
                message = record.get("message")
            else:
                return []

    def render_character(character, font = None, text_color = None, character_width = DEFAULT_CHARACTER_WIDTH, line_height = DEFAULT_LINE_HEIGHT, offset = DEFAULT_OFFSET):
        if is_image(character):
            return render.Box(
                child = render.Image(
                    src = character,
                    width = emoji_size,
                    height = emoji_size,
                ),
                width = emoji_size,
                height = emoji_size,
            )

        else:
            return render.Box(
                child = render.Text(
                    content = character,
                    font = font,
                    height = line_height,
                    offset = offset,
                    color = text_color,
                ),
                width = character_width,
                height = line_height,
            )

    def render_characters(characters, font = None, text_color = None, character_width = DEFAULT_CHARACTER_WIDTH, line_height = DEFAULT_LINE_HEIGHT, offset = DEFAULT_OFFSET):
        _characters = []
        for character in characters:
            _characters.append(render_character(character = character, font = font, text_color = text_color, character_width = character_width, line_height = line_height, offset = offset))
        return _characters

    def render_rows(characters, font, text_color, max_rows = None, character_width = DEFAULT_CHARACTER_WIDTH, line_height = DEFAULT_LINE_HEIGHT):
        rows = []
        row = []
        row_width = 0
        row_has_image = False

        def append_row():
            offset = DEFAULT_OFFSET
            _line_height = line_height

            if max_rows == None or len(rows) < max_rows:
                print_log(list(row))
                if row_has_image:
                    _line_height = emoji_size
                    offset = int(_line_height / OFFSET_RATIO)

                rows.append(
                    render.Row(
                        render_characters(characters = row, font = font, text_color = text_color, character_width = character_width, line_height = _line_height, offset = offset),
                    ),
                )

        def get_character_width(character):
            _character_width = character_width
            if is_image(character):
                _character_width = emoji_size
            return _character_width

        def is_iterable(value):
            return type(value) in ("list", "tuple")

        if is_iterable(characters):
            for i, character in enumerate(characters):
                next_character = characters[i + 1] if i < len(characters) - 1 else None

                if character == "\n" or row_width + get_character_width(character) > TIDBYT_WIDTH:
                    append_row()
                    row = []
                    row_width = 0
                    row_has_image = False

                if is_image(character):
                    row_has_image = True

                if not (next_character not in WHITESPACE and not (row) and character in WHITESPACE):
                    row.append(character)
                    row_width += get_character_width(character)

        if row:
            append_row()

        return render.Column(
            children = rows,
        )

    return render.Root(
        delay = delay,
        max_age = max_age,
        show_full_animation = True,
        child = render.Column(
            children = [
                render_rows(
                    characters = author,
                    font = author_font,
                    text_color = author_text_color,
                    max_rows = AUTHOR_MAX_ROWS,
                    character_width = get_character_width(author_font),
                    line_height = get_line_height(author_font) - 1,
                ),
                render.Box(
                    height = DIVIDER_HEIGHT,
                    width = TIDBYT_WIDTH,
                    color = separator_line_color,
                ),
                render.Box(
                    height = 1,
                    width = TIDBYT_WIDTH,
                ),
                render.Marquee(
                    height = TIDBYT_HEIGHT - get_line_height(author_font) - DIVIDER_HEIGHT,
                    offset_start = OFFSET,
                    offset_end = OFFSET,
                    child = render_rows(
                        characters = message,
                        font = message_font,
                        text_color = message_text_color,
                        character_width = get_character_width(message_font),
                        line_height = get_line_height(message_font),
                    ),
                    scroll_direction = "vertical",
                ),
            ],
        ),
    )

def get_schema():
    fonts = []

    for font in FONTS:
        fonts.append(
            schema.Option(
                display = font,
                value = font,
            ),
        )

    emoji_sizes = []

    for i in range(int(DEFAULT_EMOJI_SIZE / 2) - 1, int(DEFAULT_EMOJI_SIZE * 2)):
        emoji_sizes.append(schema.Option(display = "%d" % (i + 1), value = "%d" % (i + 1)))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "airtable_api_token",
                name = "Airtable API Token",
                desc = "Airtable API Token",
                icon = "table",
                default = DEFAULT_AIRTABLE_API_TOKEN,
            ),
            schema.Text(
                id = "airtable_base_id",
                name = "Airtable Base ID",
                desc = "Airtable Base ID",
                icon = "table",
                default = DEFAULT_AIRTABLE_BASE_ID,
            ),
            schema.Text(
                id = "airtable_table_id",
                name = "Airtable Table ID",
                desc = "Airtable Table ID",
                icon = "table",
                default = DEFAULT_AIRTABLE_TABLE_ID,
            ),
            schema.Color(
                id = "author_text_color",
                name = "Author Text Color",
                desc = "The text color of the author",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
            schema.Dropdown(
                id = "author_font",
                name = "Author Font",
                desc = "The font for the author",
                icon = "font",
                default = DEFAULT_AUTHOR_FONT,
                options = fonts,
            ),
            schema.Color(
                id = "separator_line_color",
                name = "Separator Line Color",
                desc = "The color of the separator line",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
            schema.Color(
                id = "message_text_color",
                name = "Message Text Color",
                desc = "The text color of the message",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
            schema.Dropdown(
                id = "message_font",
                name = "Message Font",
                desc = "The font for the message",
                icon = "font",
                default = DEFAULT_MESSAGE_FONT,
                options = fonts,
            ),
            schema.Text(
                id = "max_age",
                name = "Max Age",
                desc = "The number of seconds to consider a message to be recent",
                icon = "clock",
                default = str(DEFAULT_MAX_AGE),
            ),
            schema.Toggle(
                id = "random_message",
                name = "Random Message",
                desc = "Show a random message if no recent messages are found",
                icon = "shuffle",
                default = DEFAULT_RANDOM_MESSAGE,
            ),
            schema.Dropdown(
                id = "show_unicode",
                name = "Show Unicode",
                desc = "Show the Unicode icon or name (or nothing at all) for any unsupported characters (e.g. emoji)",
                icon = "code",
                default = DEFAULT_SHOW_UNICODE,
                options = [
                    schema.Option(display = "None", value = "None"),
                    schema.Option(display = "Icon", value = "Icon"),
                    schema.Option(display = "Name", value = "Name"),
                ],
            ),
            schema.Dropdown(
                id = "emoji_size",
                name = "Emoji Size",
                desc = "Set the size of emoji icons",
                icon = "ruler",
                default = str(DEFAULT_EMOJI_SIZE),
                options = emoji_sizes,
            ),
            schema.Dropdown(
                id = "delay",
                name = "Scrolling Speed",
                desc = "Set the speed of scrolling (when applicable)",
                icon = "rocket",
                default = str(DEFAULT_DELAY),
                options = [
                    schema.Option(display = "Fast", value = "60"),
                    schema.Option(display = "Medium", value = "120"),
                    schema.Option(display = "Slow", value = "180"),
                ],
            ),
        ],
    )
