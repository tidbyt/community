load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://shouldideploy.today/api?tz="

DEFAULT_LOCATION = json.encode({"timezone": "UTC"})
DEFAULT_DESIGN = "thumbs"

DESIGNS = {
    "thumbs": {
        True: {
            "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f44d.png",
            "color": "#144E00",
        },
        False: {
            "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f44e.png",
            "color": "#B41414",
        },
    },
    "symbols": {
        True: {
            "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/2705.png",
            "color": "#000000",
        },
        False: {
            "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/274c.png",
            "color": "#000000",
        },
    },
    "error": {
        "url": "https://emoji.aranja.com/static/emoji-data/img-apple-160/2049-fe0f.png",
        "color": "#000000",
    },
}

def main(config):
    design = config.get("design-choice", DEFAULT_DESIGN)

    location_cfg = config.get("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg)
    timezone = location["timezone"]

    api_url_w_timezone = API_URL + timezone

    image_to_use = None
    color_to_use = None
    cached_response = cache.get(api_url_w_timezone)
    if not cached_response:
        resp = http.get(api_url_w_timezone)
        if resp.status_code != 200:
            if "does not exist" in resp.json()["error"]["message"]:
                image_to_use = DESIGNS["error"]["url"]
                color_to_use = DESIGNS["error"]["color"]
                resp = {}
                resp["shouldideploy"] = False
                resp["message"] = "Timezone '%s' is not supported" % timezone
            else:
                fail(
                    "shouldideploy.today request failed with status %d",
                    resp.status_code,
                )
        else:
            resp = resp.json()
            cache.set(api_url_w_timezone, json.encode(resp), ttl_seconds = 120)
    else:
        resp = json.decode(cached_response)

    shouldideploy = resp["shouldideploy"]
    message = resp["message"]
    image_to_use = image_to_use or DESIGNS[design][shouldideploy]["url"]
    color_to_use = color_to_use or DESIGNS[design][shouldideploy]["color"]

    cached_image = cache.get(image_to_use)
    if cached_image:
        image = cached_image
    else:
        image = http.get(image_to_use).body()
        cache.set(image_to_use, image, ttl_seconds = 86400)

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(
                        width = 24,
                        height = 24,
                        src = image,
                    ),
                    render.Marquee(
                        width = 64,
                        offset_start = 32,
                        offset_end = 32,
                        child = render.Text(
                            message,
                            font = "tom-thumb",
                        ),
                        align = "center",
                    ),
                ],
            ),
            color = color_to_use,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to determine ideal deployment.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "design-choice",
                name = "Thumbs or Symbols",
                desc = "Use thumbs with background color or Symbols with no background color",
                icon = "wandMagicSparkles",
                default = "thumbs",
                options = [
                    schema.Option(
                        display = "Thumbs",
                        value = "thumbs",
                    ),
                    schema.Option(
                        display = "Symbols",
                        value = "symbols",
                    ),
                ],
            ),
        ],
    )
