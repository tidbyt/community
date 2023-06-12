"""
Applet: Json Display
Summary: Displays simple json data
Description: Takes values from a simple json file and outputs them.
Author: thickey256
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    feed_url = config.get("feed_url")
    feed_refresh = config.get("feed_refresh")
    feed_refresh = int(feed_refresh)

    #Load the json file
    rep = http.get(url = feed_url, ttl_seconds = feed_refresh)

    #Turn the body into json
    json_contents = json.decode(rep.body())

    if rep.status_code != 200:
        fail("Json URL didn't load %d", rep.status_code)

    #Set the font
    font = "tom-thumb"

    #Sort out the icon (10x10 png works well)
    icon_image = http.get(json_contents["title_image"], ttl_seconds = 7200)

    #This constructs the header, an image and a title
    children_array = [
        render.Box(
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "start",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Box(
                        width = 11,
                        child = render.Image(src = icon_image.body()),
                    ),
                    render.Marquee(width = 64, child = render.Text(json_contents["title_text"])),
                ],
            ),
            height = 10,
        ),
        render.Padding(
            pad = (0, 0, 0, 1),
            child = render.Box(width = 64, height = 1, color = "#555555"),
        ),
    ]

    #Loop through each line of data (no more than 3 will fit)
    for item in json_contents["data"]:
        children_array.append(
            render.Padding(
                pad = (1, 0, 1, 1),
                child = render.Marquee(width = 64, child = render.Text("%s:%s" % (item["title"], item["value"]), font = font, color = item["color"])),
            ),
        )

    #Render it all out
    return render.Root(
        child = render.Column(children = children_array),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "feed_url",
                name = "JSON URL",
                desc = "URL for your json data",
                icon = "link",
                default = "https://tidbyt-json-display.s3.eu-west-1.amazonaws.com/example.json",
            ),
            schema.Text(
                id = "feed_refresh",
                name = "Refresh Time",
                desc = "Number of seconds between data refreshes.",
                icon = "clock",
                default = "120",
            ),
        ],
    )
