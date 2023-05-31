"""
Applet: Json Display
Summary: Displays simple json data
Description: Takes values from a simple json file and outputs them.
Author: thickey256
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    feed_url_cached = cache.get("feed_url_cached")
    if feed_url_cached != None:
        #Turn the cache string into nice json
        json_contents = json.decode(cache.get("json_contents_cached"))
    else:
        feed_url = config.get("feed_url")

        #Load the json file
        rep = http.get(feed_url)

        #Turn the body into json
        json_contents = json.decode(rep.body())

        #Set the cache variables
        cache.set("json_contents_cached", str(rep.body()), ttl_seconds = 10)
        cache.set("feed_url_cached", json_contents["feed_url"], ttl_seconds = 10)

        if rep.status_code != 200:
            fail("Json URL didn't load %d", rep.status_code)

    #Set the font
    font = "tom-thumb"

    #Sort out the icon (10x10 png works well)
    icon_image = http.get(json_contents["title_image"])

    #This constructs the header, an image and a title
    children_array = [
        render.Box(
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = icon_image.body()),
                    render.Text(json_contents["title_text"]),
                ],
            ),
            height = 10,
        ),
        render.Box(width = 64, height = 1, color = "#555555"),
    ]

    #Loop through each line of data (no more than 3 will fit)
    for item in json_contents["data"]:
        children_array.append(render.Marquee(width = 64, child = render.Text("%s:%s" % (item["title"], item["value"]), font = font, color = item["color"])))
        children_array.append(render.Box(width = 64, height = 1, color = "#111111"))

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
                desc = "Url for your json data",
                icon = "link",
                default = "https://tidbyt-json-display.s3.eu-west-1.amazonaws.com/example.json",
            ),
        ],
    )
