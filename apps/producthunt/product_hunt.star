"""
Applet: Product Hunt
Summary: Product Hunt top products
Description: View the daily top tech products from Product Hunt.
Author: Daniel Sitnik
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

UPVOTE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAFCAYAAAB8ZH1oAAAAAXNSR0IArs4c6QAAAC9JREFUGFd9ykEKADAIxEDz/0evtFCxi5hjGMKSJAD/3zjoAccFO5rwhRNyzIY6TswcFAbAvxbgAAAAAElFTkSuQmCC
""")

PH_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAACUElEQVR4nL2WPWsUURSG3xsXBC2yhdipk1+QTW3h5B8o7IpdslFBiKCFWI+lsbEJCBInVkpWcC20UXC2sFHIboqAVk4sxWJTKAhZbt4zH8lkdu7s1yQPnDvnDgwP98y5d0ZhCPTtWgU9vQCNCqdlRoUhdBhdKHg4pd6p5w2Z55Ir1PXrCxwdhoWhUD7DUe7GSxhQjD70nRsW/u+5TG2Mh4fTpbp69tpHij6hvlW10cNbpmXGJHRRUvPpMh8RRrLPTIujpOaS0gNhVMY20zKjSLos71xc3kNhvSors3E8eMp9M89rKNRLtUVo7TLN5kWDQw6bX4FPH4Dv25wYmJq6ptY2mqGwXvvJ0YKJQcKYtVXgi4dslK/cxowKNvWebvOOmaTwxzaHBBcs4MxZHPBwGfjzm0kG0kBc3VOu7h6nZpLCpRqHFDeXgcs2Aj6+B16tIxOFRxRWPQBXGGYGCc+dB1ZWmRCpwGMHBloibDOpMMwMEl60AOcJAvKFHRFqJvnkCWV1dx9QOsMJkXJKWQ2MLszj39+waeRqgMJah00zy9zMMEKRrDjALx9m1BaFIzaNvKM0m9/C/SfSfKRpCtgWwxJsi1E3/iRC2fi88Gir+gAuMbIpRrjDA9wKhaMc3uMKk4e3wFV6GNQ849Pi6myQQ2H4Ae4wnWYUyS4/wJW+D7Bwor8YMZG0yXSaMQm7lNlJmdAnFKLyrmP8d9piGRfjMibJFMZE3esgb8scZYfdeF+6kXkmucKY4HDo6av81bf5SJl3ZhGgtpjHv/rNdPmy2AeKXO+vf7/W8gAAAABJRU5ErkJggg==
""")

DEFAULT_DISPLAY = "top1"

CACHE_TTL = 1800

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    # get config
    config_display = config.get("display", DEFAULT_DISPLAY)

    # call product hunt API (graphql)
    res = http.post("https://ph-graph-api-explorer.herokuapp.com/graphql", ttl_seconds = CACHE_TTL, json_body = {
        "operationName": "Posts",
        "query": "query Posts {\nposts(featured: true, first: 3) {\nnodes {\nname\nvotesCount\nthumbnail {\ntype\nurl\n}\n}\n}\n}",
    })

    # handle api errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_api_error(res)

    data = res.json()

    # errors may happen even with 200 status code
    if data.get("errors") != None:
        return render_api_error(res)

    posts = data.get("data", {}).get("posts", {}).get("nodes", [])

    # check if we have content to display
    if len(posts) == 0:
        print("No data to display, API response: %s" % res.body())
        return render_empty()

    # list of frames showin product details
    frames = []

    if config_display == DEFAULT_DISPLAY:
        # display only top product
        product_name = posts[0]["name"]
        product_votes = posts[0]["votesCount"]
        product_image = get_image(posts[0]["thumbnail"]["url"])
        frames.append(render_frame(product_name, product_votes, product_image))
    else:
        # display top 3 products
        for post in posts:
            product_name = post["name"]
            product_votes = post["votesCount"]
            product_image = get_image(post["thumbnail"]["url"])
            frames.append(render_frame(product_name, product_votes, product_image))

    return render.Root(
        delay = 100,
        child = render.Column(
            children = [
                render_header(),
                render.Box(height = 1, width = 64, color = "#fdf0ee"),
                render.Sequence(
                    children = frames,
                ),
            ],
        ),
    )

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    screen_options = [
        schema.Option(display = "Top Product", value = "top1"),
        schema.Option(display = "Top 3 Products", value = "top3"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display",
                name = "Display",
                desc = "What the app should display.",
                icon = "rankingStar",
                options = screen_options,
                default = DEFAULT_DISPLAY,
            ),
        ],
    )

def get_image(url):
    """Downloads an image from an URL. Returns a default image on errors.

    Args:
        url (string): The URL to download the image from.

    Returns:
        blob: The image's binary content.
    """

    res = http.get(url)

    if res.status_code != 200:
        # use default image
        return PH_LOGO

    return res.body()

def render_header():
    """Renders the widgets that form the app's header.

    Returns:
        widget: The widget tree for the app's header.
    """

    return render.Box(
        width = 64,
        height = 8,
        child = render.Text(content = "Product Hunt", color = "#ed6c5c"),
    )

def render_frame(product_name, product_votes, product_image):
    """Renders the frames to show a product's details.

    Args:
        product_name (string): The product's name.
        product_votes (string): The product's number of votes.
        product_image (blob): The product's image.

    Returns:
        widget: The widget tree to show the product's details.
    """

    return animation.Transformation(
        duration = 50,
        delay = 0,
        keyframes = [],
        child = render.Row(
            main_align = "start",
            cross_align = "center",
            expanded = True,
            children = [
                render.Box(
                    height = 23,
                    width = 23,
                    padding = 1,
                    child = render.Image(src = product_image, height = 23),
                ),
                render.Column(
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Marquee(
                            width = 41,
                            child = render.Text(content = product_name, font = "Dina_r400-6"),
                        ),
                        render.Row(
                            children = [
                                render.Image(src = UPVOTE_ICON, height = 5, width = 10),
                                render.Text(content = str(int(product_votes)), font = "CG-pixel-3x5-mono"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def render_api_error(http_response):
    """Renders the status code and message when there are API errors.

    Args:
        http_response (response): The http response object.

    Returns:
        render.Root: Root widget tree to show an error.
    """

    data = http_response.json()
    message = "API Error"
    code = str(http_response.status_code)

    if data.get("errors") != None and len(data["errors"]) > 0:
        message = data["errors"][0].get("message", message)

    return render.Root(
        delay = 40,
        child = render.Column(
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
            children = [
                render_header(),
                render.Box(height = 1, width = 64, color = "#fdf0ee"),
                render.Text(content = "code %s" % code, color = "#f00"),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = message, color = "#ff0"),
                ),
            ],
        ),
    )

def render_empty():
    """Renders a default message when the API returns no data to display.

    Returns:
        render.Root: Root widget tree.
    """

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
            children = [
                render_header(),
                render.Box(height = 1, width = 64, color = "#fdf0ee"),
                render.Text(content = "No data", color = "#ff0"),
                render.Text(content = "to display!", color = "#ff0"),
            ],
        ),
    )
