HEIGHT = 32
WIDTH = 64
SAMPLE_CSV_QR_FRAMES = 150  # number of frames to show the QR code for if CSV is default
SAMPLE_PUBLISHED_SHEET = "https://bit.ly/tidbyt-csv-viewer"  # needed to create a bit.ly because QR's limit is 440 bytes
SAMPLE_PUBLISHED_CSV = "https://docs.google.com/spreadsheets/d/e/2PACX-1vSkZW0qyS1HpnPh5V51mBPZNjiNFJEZUjrLlwlfrscjDmMHqNyKQ1sjfj791t0f-_XE8g6d5MnSosLE/pub?gid=0&single=true&output=csv"

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/csv.star", "csv")
load("re.star", "re")
load("qrcode.star", "qrcode")

#################################################
# Fetch and parse the CSV data
#################################################

def get_csv_data(csv_url):
    rep = http.get(csv_url, ttl_seconds = 300)  # cache for 5 minutes
    if rep.status_code != 200:
        fail("HTTP GET request to specified CSV URL failed with status %d", rep.status_code)

    return csv.read_all(rep.body())

def parse_int_from_config(config, config_id, default_value):
    unparsed_value = config.str(config_id, "")

    if re.match(r"^[0-9]+$", unparsed_value):
        return int(unparsed_value)

    return default_value

def offset_data(data, row_offset, col_offset):
    """
    Offset the data by the specified values
    """

    # Use slicing to remove rows from the top
    data = data[row_offset:]

    # Use list comprehensions to remove columns from the left
    data = [row[col_offset:] for row in data]

    return data

def resize_data(data, target_height, target_width):
    """
    Resize the data based on the target height and width specified.
    In case we're not given enough data, fill in blanks.
    """

    # Get the current dimensions of the input dataay
    current_height = len(data)
    current_width = len(data[0]) if current_height > 0 else 0

    # Create a new empty 2D data set with the target dimensions
    resized_data = [["" for _ in range(target_width)] for _ in range(target_height)]

    # Copy values from the original data to the new data set
    for i in range(min(current_height, target_height)):
        for j in range(min(current_width, target_width)):
            resized_data[i][j] = data[i][j]

    return resized_data

def get_data_rows_cols(config):
    csv_url = config.str("csv_url", SAMPLE_PUBLISHED_CSV)
    csv_data = get_csv_data(csv_url)

    # Skip the offsets if specified
    row_offset = parse_int_from_config(config, "row_offset", 0)
    if row_offset >= len(csv_data):
        row_offset = 0
    col_offset = parse_int_from_config(config, "col_offset", 0)
    if col_offset >= max([len(row) for row in csv_data]):
        col_offset = 0
    csv_data = offset_data(csv_data, row_offset, col_offset)

    # If row/col counts have been specified, pull those. Default to size of data from URL
    default_row_count = len(csv_data)
    default_col_count = max([len(row) for row in csv_data])
    row_count = int(config.str("row_count", default_row_count))
    col_count = int(config.str("col_count", default_col_count))
    if row_count == 0:
        row_count = default_row_count
    if col_count == 0:
        col_count = default_col_count

    # In case the size of the data set is too large for the screen, scale it down
    if row_count > HEIGHT:
        row_count = HEIGHT
    if col_count > WIDTH:
        col_count = WIDTH

    # Scale up the data set if need be
    csv_data = resize_data(csv_data, row_count, col_count)

    return csv_data, row_count, col_count

#################################################
# Parse color (text, background) from data
#################################################

def extract_text_color_and_background(input_string):
    # TODO: move defaults to top
    DEFAULT_TEXT_COLOR = "#FFF"
    DEFAULT_BACKGROUND_COLOR = "#000F"

    text, background_color = extract_trailing_color(input_string)

    # Grab the text color as well if it's available
    text_color = DEFAULT_TEXT_COLOR
    if text != None:
        text, text_color = extract_trailing_color(text)

    if text_color == None:
        text_color = DEFAULT_TEXT_COLOR
    if background_color == None:
        background_color = DEFAULT_BACKGROUND_COLOR

    return text, text_color, background_color

def extract_trailing_color(input_string):
    # Define a regular expression pattern to match valid color strings
    # From docs: "Pixlet supports #rgb, #rrggbb, #rgba, and #rrggbbaa color specifications."
    color_pattern = r"#([A-Fa-f0-9]{3,4}|[A-Fa-f0-9]{6,8})$"

    color_match = re.match(color_pattern, input_string)

    # If there's no color part, return that
    if not color_match:
        return input_string, None

    match_text = color_match[0][0]

    # If it's just the color part, then return that
    if len(input_string) == len(match_text):
        return None, input_string

    return (input_string[:-len(match_text)], match_text)

#################################################
# Render to the screen
#################################################

def calculate_grid_sizes(row_count, col_count):
    # Calculate row height and column width based on available screen space
    row_height = HEIGHT // row_count
    col_width = WIDTH // col_count

    # Calculate any remaining space in case of uneven distribution
    remaining_height = HEIGHT % row_count
    remaining_width = WIDTH % col_count

    # Distribute the remaining space evenly among rows and columns
    row_heights = [row_height] * row_count
    col_widths = [col_width] * col_count

    # Distribute any remaining space
    for i in range(remaining_height):
        row_heights[i] += 1

    for i in range(remaining_width):
        col_widths[i] += 1

    return row_heights, col_widths

def render_text(text, color, max_text_height, max_text_width, avoid_scrolling_text):
    """
    Try our best to fit the text without scrolling by calculating the first available
    font that fits vertically.

    If avoid_scrolling_text is selected, continue trying smaller fonts to fit the text so it
    doesn't scroll even if it fits vertically. If we can't avoid scrolling, use the
    largest possible text that fits vertically.
    """

    fonts_and_heights_to_try = [
        ["10x20", 20],
        ["10x20", 19],
        ["10x20", 18],
        ["10x20", 17],
        ["10x20", 16],
        ["10x20", 15],
        ["10x20", 14],
        ["6x13", 13],
        ["6x13", 12],
        ["6x13", 11],
        ["Dina_r400-6", 10],
        ["Dina_r400-6", 9],
        ["tb-8", 8],
        ["tb-8", 7],
        ["tom-thumb", 7],
        ["tom-thumb", 6],
        ["CG-pixel-4x5-mono", 5],
        ["CG-pixel-3x5-mono", 5],
    ]

    saved_fits_vertically = None

    for font, height in fonts_and_heights_to_try:
        rendered_text = render.Text(content = text, font = font, height = height, color = color)
        text_width, text_height = rendered_text.size()

        # Skip if this font doesn't fit vertically
        if text_height > max_text_height:
            continue

        # Save the first font that fits vertically
        if saved_fits_vertically == None:
            saved_fits_vertically = [font, height]

        # Keep searching if it doesn't fit horizontally (but only if we're to avoid scrolling text)
        if avoid_scrolling_text and text_width > max_text_width:
            continue

        return rendered_text

    # If we haven't found anything that fits vertically, default to the smallest possible font
    if saved_fits_vertically == None:
        saved_fits_vertically = fonts_and_heights_to_try[-1]

    # Default to the smallest text that will fit vertically if it must scroll
    return render.Text(content = text, font = saved_fits_vertically[0], height = saved_fits_vertically[1], color = color)

def render_cell(value, height, width, avoid_scrolling_text):
    text, text_color, background_color = extract_text_color_and_background(value)
    background_box = render.Box(width = width, height = height, color = background_color)

    if text == None:
        return background_box
    else:
        rendered_text = render_text(text, text_color, height, width, avoid_scrolling_text)

        return render.Stack(
            children = [
                background_box,
                render.Marquee(
                    width = width,
                    height = height,
                    child = rendered_text,
                    align = "center",
                ),
            ],
        )

def render_grid(data, row_count, col_count, config):
    row_heights, col_widths = calculate_grid_sizes(row_count, col_count)
    avoid_scrolling_text = config.bool("avoid_scrolling_text")

    rows = []

    for r in range(row_count):
        row_height = row_heights[r]
        cols = []

        for c in range(col_count):
            col_width = col_widths[c]

            rendered_cell = render_cell(data[r][c], row_height, col_width, avoid_scrolling_text)

            # Place the rendered cel in a box with the given size to get everything to fit nicely
            holding_box = render.Box(
                color = "#000",
                child = rendered_cell,
                width = col_width,
                height = row_height,
            )

            cols.append(holding_box)

        row = render.Row(children = cols)

        rows.append(row)

    return rows

#################################################
# Main, schema, and show QR code of sample CSV
#################################################

def switch_between_sample_and_qr(main_display):
    qr_code = qrcode.generate(
        url = SAMPLE_PUBLISHED_SHEET,
        size = "large",
        color = "#fff",
        background = "#000",
    )
    qr_box = render.Box(width = 32, height = 32, child = render.Image(src = qr_code))

    qr_animation = render.Animation(
        children = [qr_box] * SAMPLE_CSV_QR_FRAMES,
    )

    return render.Root(
        render.Sequence(
            children = [
                main_display,
                qr_animation,
            ],
        ),
    )

def main(config):
    data, row_count, col_count = get_data_rows_cols(config)

    main_display = render.Column(
        children = render_grid(data, row_count, col_count, config),
    )

    # If no URL has been set, show a QR code
    if config.str("csv_url", SAMPLE_PUBLISHED_CSV) == SAMPLE_PUBLISHED_CSV:
        return switch_between_sample_and_qr(main_display)

    return render.Root(
        child = main_display,
    )

def get_schema():
    scale_to_data_option = [
        schema.Option(
            display = "Scale to data",
            value = str(0),
        ),
    ]

    row_count_options = scale_to_data_option + [
        schema.Option(
            display = str(n),
            value = str(n),
        )
        for n in range(1, HEIGHT + 1)
    ]

    col_count_options = scale_to_data_option + [
        schema.Option(
            display = str(n),
            value = str(n),
        )
        for n in range(1, WIDTH + 1)
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "csv_url",
                name = "CSV Url",
                desc = "The link to download ths CSV file",
                icon = "link",
            ),
            schema.Dropdown(
                id = "row_count",
                name = "Row count",
                desc = "The number of rows to display",
                icon = "table_rows",
                default = row_count_options[0].value,
                options = row_count_options,
            ),
            schema.Dropdown(
                id = "col_count",
                name = "Column count",
                desc = "The number of columns to display",
                icon = "table_columns",
                default = col_count_options[0].value,
                options = col_count_options,
            ),
            schema.Text(
                id = "row_offset",
                name = "Row offset",
                desc = "The number of rows at the top of the CSV to skip",
                icon = "forward_fast",
            ),
            schema.Text(
                id = "col_offset",
                name = "Column offset",
                desc = "The number of columns on the left of the CSV to skip",
                icon = "forward_fast",
            ),
            schema.Toggle(
                id = "avoid_scrolling_text",
                name = "Avoid scrolling text",
                desc = "Reduce font size to avoid scrolling text when possible",
                icon = "text_size",
                default = False,
            ),
        ],
    )
