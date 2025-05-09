"""
Applet: Custom Quotes
Summary: Display custom quotes
Description: Display quotes from a Google sheet with a quote and author column
Author: vipulchhajer
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Set default spreadsheet, API keys and supported range (1000)
default_spreadsheet_id = "default"
default_api_key = "default"
range = "Sheet1!A1:B1000"

# Set fonts
QUOTE_FONT = "tom-thumb"
AUTHOR_FONT = "CG-pixel-3x5-mono"
QUOTE_COLOR = "#FFFFFF"
AUTHOR_COLOR = "#DCDCDC"
BOX_COLOR = "#00000099"

# Set width and height
OUTER_HEIGHT = 32
OUTER_WIDTH = 64
PADDING = 2
INNER_HEIGHT = OUTER_HEIGHT - 2 * PADDING
INNER_WIDTH = OUTER_WIDTH - 2 * PADDING

#Set cache time
TTL_SECONDS = 3600  # Increased to 1 hour since we're using static image

def main(config):
    # Get spreadsheet and API key from user entry
    spreadsheet_id = config.str("spreadsheet_id", default_spreadsheet_id)
    api_key = config.str("api_key", default_api_key)
    url = "https://sheets.googleapis.com/v4/spreadsheets/{}/values/{}?key={}".format(spreadsheet_id, range, api_key)

    # Make a GET request to input data from Google Sheet
    r = http.get(url, ttl_seconds = TTL_SECONDS)

    # check the HTTP response code
    # if we fail, send back error message
    status_code = r.status_code
    if (status_code != 200):
        quote = "Check spreadsheet ID or API key"
        author = ""
    else:
        # Extract the values array from the response
        array = r.json()["values"]

        # Extracting rows and columns
        quotes = [item[0] if len(item) > 0 else "" for item in array]
        authors = [item[1] if len(item) > 1 else "" for item in array]

        # Randomly pick one quote-author
        quote_id = int(time.now().nanosecond / 1000) % len(quotes)
        if (quote_id == 0):
            quote_id = quote_id + 1
        quote = quotes[quote_id]
        author = authors[quote_id]

        # Display error if no quote
        if (quote == ""):
            quote = "No quote to display"

        # Add hyphen if there's an author
        if (author != ""):
            author = "-" + author

    image = base64.decode(get_image())

    return render.Root(
        show_full_animation = True,
        delay = 200,
        child = render.Stack(
            children = [
                render.Image(src = image, height = OUTER_HEIGHT, width = OUTER_WIDTH),
                render.Padding(
                    pad = PADDING,
                    child = render.Box(
                        color = BOX_COLOR,
                        height = INNER_HEIGHT,
                        width = INNER_WIDTH,
                        child = render.Marquee(
                            height = INNER_HEIGHT,
                            width = INNER_WIDTH,
                            child = render.Column(
                                main_align = "start",
                                cross_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = quote,
                                        font = QUOTE_FONT,
                                        color = QUOTE_COLOR,
                                        linespacing = 1,
                                        width = INNER_WIDTH,
                                    ),
                                    render.Box(width = INNER_WIDTH, height = 1),
                                    render.WrappedText(
                                        content = author,
                                        font = AUTHOR_FONT,
                                        color = AUTHOR_COLOR,
                                        linespacing = 2,
                                        width = INNER_WIDTH,
                                    ),
                                ],
                            ),
                            scroll_direction = "vertical",
                            offset_start = 16,
                            align = "end",
                        ),
                    ),
                ),
            ],
        ),
    )

# Define function to get random image
def get_image():
    # Return a minimal black background image (1x1 pixel)
    return "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAAAAgABSK+kcQAAAABJRU5ErkJggg=="

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "spreadsheet_id",
                name = "Spreadsheet ID",
                desc = "spreadsheet ID is in the URL of your Google Sheet",
                icon = "file",
            ),
            schema.Text(
                id = "api_key",
                name = "Google Sheets API Key",
                desc = "Google how to get API Key if you're not familiar",
                icon = "code",
            ),
        ],
    )
