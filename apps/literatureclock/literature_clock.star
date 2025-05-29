"""
Applet: Literature Clock
Summary: Quotes containing the time
Description: Displays the time using a quote from a piece of literature. Based on work and idea by Jaap Meijers and Jene Voldsen.
Author: Alysha Kwok
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"
JSON_ENDPOINT = "https://raw.githubusercontent.com/JohannesNE/literature-clock/refs/heads/master/docs/times/"
QUOTE_FIRST = "quote_first"
QUOTE_TIME = "quote_time_case"
QUOTE_LAST = "quote_last"
TITLE = "title"
AUTHOR = "author"
SFW = "sfw"
DEFAULT_FONT = "tb-8"
SMALL_FONT = "tom-thumb"
EMPTY = ""
CACHE_TIME = 86460

def get_data(fileTime, config):
    file = JSON_ENDPOINT
    if fileTime.hour < 10:
        file += "0"
    file += str(fileTime.hour) + "_"
    if fileTime.minute < 10:
        file += "0"
    file += str(fileTime.minute) + ".json"

    # check if quotes request succeeded, else one min back
    request = http.get(file, ttl_seconds = CACHE_TIME)
    if request.status_code != 200:
        quotes = get_data(fileTime - time.minute, config)
    else:
        quotes = request.json()

    if config.bool("sfw"):
        quotes = filter_sfw(quotes)
        if len(quotes) == 0:
            quotes = get_data(fileTime - time.minute, config)

    return quotes

def filter_sfw(quotes):
    sfwQuotes = []
    for i in range(len(quotes)):
        if quotes[i][SFW] == "yes":
            sfwQuotes.append(quotes[i])
    return sfwQuotes

def clean_string(text):
    return text.replace("<br>", "\n").replace("<br/>", "\n").lstrip(" ").rstrip(" ")

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)

    fileTime = time.now().in_location(timezone)

    quotes = get_data(fileTime, config)

    # select a random quote from file
    index = random.number(0, len(quotes) - 1)
    quote = quotes[index]

    timeColor = config.get("color", colorOptions[5].value)
    if config.bool("smallFont"):
        fontFace = SMALL_FONT
    else:
        fontFace = DEFAULT_FONT

    return render.Root(
        delay = 65,
        show_full_animation = True,
        child = render.Marquee(
            height = 32,
            width = 64,
            offset_start = 25,
            offset_end = 25,
            scroll_direction = "vertical",
            child =
                render.Column(
                    children = [
                        render.WrappedText(clean_string(quote[QUOTE_FIRST]), font = fontFace),
                        render.WrappedText(quote[QUOTE_TIME], color = timeColor, font = fontFace),
                        render.WrappedText(clean_string(quote[QUOTE_LAST]), font = fontFace),
                        render.WrappedText(" "),
                        render.WrappedText(quote[TITLE] + ",", font = fontFace),
                        render.WrappedText(quote[AUTHOR], font = fontFace),
                    ],
                ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "color",
                name = "Color of time text",
                desc = "Select color used to display time text part of quote.",
                icon = "gear",
                default = colorOptions[5].value,
                options = colorOptions,
            ),
            schema.Toggle(
                id = "sfw",
                name = "Skip NSFW quotes",
                desc = "Skip quotes with profanities or explicit content",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "smallFont",
                name = "Use a smaller font",
                desc = "Display quote in a smaller font",
                icon = "font",
                default = False,
            ),
        ],
    )

colorOptions = [
    schema.Option(
        display = "White",
        value = "#FFFFFF",
    ),
    schema.Option(
        display = "Red",
        value = "#FF0000",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FFFF00",
    ),
    schema.Option(
        display = "Green",
        value = "#008000",
    ),
    schema.Option(
        display = "Blue",
        value = "#0000FF",
    ),
    schema.Option(
        display = "Indigo",
        value = "#4B0082",
    ),
    schema.Option(
        display = "Violet",
        value = "#EE82EE",
    ),
    schema.Option(
        display = "Pink",
        value = "#FC46AA",
    ),
]
