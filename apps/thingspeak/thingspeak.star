load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Load Thingspeak icon from base64 encoded data
THINGSPEAK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAY9JREFUOE9VUzFWQkEMnFQ2XgRo7PgWwgUETmEFHoHPQzgBPA7ix2crVEBpI3IZ48skuyzN/r/Z7GQykxURgQIQVSgEvgNULJZ3jInYAX/9YzkWfZh/2F1AFTeAEoCRzUJQgn9Pn8ULAujUW91NKmfCCLH4b7xYJ5UG8LQ64XcxYCZJdGaNfk0qp2mtROUEku9auwr010ecF0OBcxB0agPo2p6Xr4165cSBcUkMCoB23ejeWvDMYEI6IbBDsmMCHHFZDkmHEQfo+mWXvySRJRcDVEF/fcB5MXINbG3NGt2PTYOwlDgO4q6wNxdVgd7qgMtyRH5iCa36XXfjx0wgqCXTsrWuuoYLSYOwkS5YVYOh/Kmd8DRbLOitwgWOntlYN/oXaruCbsT9HfD5UnHb25wc2I3DeT4QtzuSC/PchlCoPW10/1q5cG9GO+vLUU/TRPFjSZiZik2qnVvV8h1Q2Mw3esyzkEY5Hk97ttUfAtxyjbmLiUtnMUyZUcEu8AKmYJA8LkUMIa6a+GDEnPkD/geJa9gfs+euSAAAAABJRU5ErkJggg==
""")

# Learn more about error codes
# https://www.mathworks.com/help/thingspeak/error-codes.html
def renderErrorHelp(config, resp):
    errorMsg = "Something went wrong, check your settings."
    errorDetails = resp.data
    if errorDetails == -1:
        errorMsg = "Is your channel private? Did you provide an API key?"
    if config.str("channelId", None) == None:
        errorMsg = "Add a channelId to get started :)"

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = 64,
                    height = 32,
                    align = "start",
                    child = render.Text(errorMsg),
                ),
            ],
        ),
    )

# get data or used cached value for desired render
def getData(config):
    # get settings from user config
    config_channel_id = config.str("channelId", None)
    field_id = config.str("fieldId", "1")
    get_last = "" if config.bool("renderPlotView") else "/last"

    # api resonses are different based on if youre getting the last 'single' value or several
    cacheKey = "{}-{}{}".format(config_channel_id, field_id, get_last)

    # check for cached value
    cachedRespBody = cache.get(cacheKey)

    if cachedRespBody:
        return struct(status_code = 200, data = json.decode(cachedRespBody))

    # set up params for api call
    # see also: https://www.mathworks.com/help/thingspeak/rest-api.html
    THINGSPEAK_CHANNEL_URL_ENDPOINT = "https://api.thingspeak.com/channels/{}/fields/{}{}.json".format(config_channel_id, field_id, get_last)
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Tidbyt App: Thingspeak channel data",
    }

    params = {
        "api_key": config.str("apiKey", ""),
        "results": "6000",  # increases odds you will get some results if there's infrequent data in a field
        # some fields may only get data once a day. TODO consider exposing settings for api filters?
    }

    resp = http.get(THINGSPEAK_CHANNEL_URL_ENDPOINT, params = params, headers = headers)

    # cache it 💰
    if resp.status_code == 200:
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cacheKey, json.encode(resp.json()), ttl_seconds = 60)  # 10 minute cache

    return struct(status_code = resp.status_code, data = resp.json())

def renderBottomContent(config, resp):
    # get fieldKey for configured from config eg: field1
    fieldKey = "field{}".format(config.str("fieldId", "1"))

    if config.bool("renderPlotView", False):
        validResultValues = []

        # filter out null values that may exist in response
        for result in resp.data.get("feeds"):
            resultValue = result.get(fieldKey)
            if resultValue != None:
                validResultValues.append(float(resultValue))
                if len(validResultValues) > 64:
                    break  # bail 64 is enough of data for 64 px

        return render.Plot(
            data = enumerate(validResultValues),
            width = 64,
            height = 16,
            color = "#3584B2",  # thingspeak hex color 💬
            x_lim = (0, len(validResultValues) - 1),
            y_lim = (min(validResultValues), max(validResultValues)),
            fill = True,
        )

    return render.Marquee(
        width = 64,
        height = 16,
        align = "start",
        child = render.Text("{prepend} {value}".format(prepend = config.str("prepend"), value = resp.data.get(fieldKey))),
    )

def main(config):
    print("Running Thingspeak app")
    resp = getData(config)
    if resp.status_code != 200:
        print("Thingspeak API request failed with status", resp.status_code)
        return renderErrorHelp(config, resp)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Image(src = THINGSPEAK_ICON),
                        render.Marquee(
                            width = 48,
                            height = 16,
                            align = "start",
                            child = render.Text(config.str("title", "No value given")),
                        ),
                    ],
                    cross_align = "center",
                ),
                renderBottomContent(config = config, resp = resp),
            ],
        ),
    )

def get_schema():
    fieldOptions = [
        schema.Option(
            display = "Field 1",
            value = "1",
        ),
        schema.Option(
            display = "Field 2",
            value = "2",
        ),
        schema.Option(
            display = "Field 3",
            value = "3",
        ),
        schema.Option(
            display = "Field 4",
            value = "4",
        ),
        schema.Option(
            display = "Field 5",
            value = "5",
        ),
        schema.Option(
            display = "Field 6",
            value = "6",
        ),
        schema.Option(
            display = "Field 7",
            value = "7",
        ),
        schema.Option(
            display = "Field 8",
            value = "8",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "channelId",
                name = "Thingspeak Channel Id",
                desc = "The id of the thingspeak channel.",
                icon = "rss",
                default = "2203073",
            ),
            schema.Text(
                id = "apiKey",
                name = "Read API Key",
                desc = "A read API key if the channel is private.",
                icon = "key",
            ),
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Title text next to the Thingspeak logo",
                default = "Thingspeak",
                icon = "tag",
            ),
            schema.Toggle(
                id = "renderPlotView",
                name = "Render as a plot view",
                desc = "Should the app render as a plot view",
                icon = "chartLine",
                default = True,
            ),
            schema.Text(
                id = "prepend",
                name = "Text to add before the value",
                desc = "Text to add before the value",
                icon = "tag",
                default = "Your selected field value is",
            ),
            schema.Dropdown(
                id = "fieldId",
                name = "field",
                desc = "The field from your selected channel",
                icon = "tableCellsLarge",
                default = fieldOptions[0].value,
                options = fieldOptions,
            ),
        ],
    )
