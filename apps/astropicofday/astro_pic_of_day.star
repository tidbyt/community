"""
Applet: Astro Pic of Day
Summary: New pic from NASA each day
Description: Displays the astronomy picture of the day from NASA.
Author: Brian Bell
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

APOD_URL = "https://api.nasa.gov/planetary/apod"
DEVELOPER_API_KEY = "DEMO_KEY"  # Limited key for development

# Register with NASA for a key to encrypt for prod: https://api.nasa.gov
ENCRYPTED_API_KEY = "AV6+xWcE1JkVfhEFXybRNja7TAmjbWzFfELQXqrpnD4H+lbiuK6nbf4Issz7v5qig7IA0mxDCKcMa0vkLy4S4iw/AW6XVWiZXHh5cXdYT2vRvrqsIwz+0FdEhgMm8e53r69TJF+4Be9gAy8Uo2MFjocI7wHtp+G5psI0D99Wgv61sbX+ZjJwmmFwDbzuPA=="
NASA_LOGO = "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"
TTL_SECONDS = 3600

def main():
    apod = cache.get("astro_pic_of_day")
    if apod:
        apod = json.decode(apod)
    else:
        apod = get_apod(
            APOD_URL,
            secret.decrypt(ENCRYPTED_API_KEY) or DEVELOPER_API_KEY,
            TTL_SECONDS,
        )
    title = apod["title"]
    image_src = base64.decode(apod["image_src"])

    return render.Root(
        child = render.Stack(
            children = [
                render.Column(
                    cross_align = "center",
                    main_align = "space_between",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [
                                render.Image(
                                    src = image_src,
                                    height = 32,
                                ),
                            ],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Box(
                        child = render.Box(
                            color = "#00000099",
                            width = 64,
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Image(
                                        src = base64.decode(NASA_LOGO),
                                        height = 8,
                                    ),
                                    render.Padding(
                                        pad = (1, 2, 1, 0),
                                        child = render.WrappedText(
                                            align = "center",
                                            content = title,
                                            font = "tom-thumb",
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                    delay = 70,
                    direction = "alternate",
                    duration = 50,
                    fill_mode = "forwards",
                    origin = animation.Origin(0.5, 0.5),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_apod(url, api_key, ttl_seconds):
    # Return astronomy picture of the day
    params = {"api_key": api_key, "thumbs": "True"}
    response = http.get(url = url, params = params)
    if response.status_code != 200:
        fail("status %d from %s: %s" % (response.status_code, url, response.body()))
    apod = response.json()
    apod["image_src"] = base64.encode(get_image_src(apod["url"]))
    cache.set("astro_pic_of_day", json.encode(apod), ttl_seconds = ttl_seconds)
    return apod

def get_image_src(url):
    # Return and cache image data from url provided
    response = http.get(url)
    if response.status_code != 200:
        fail("status %d from %s: %s" % (response.status_code, url, response.body()))
    image_src = response.body()
    return image_src
