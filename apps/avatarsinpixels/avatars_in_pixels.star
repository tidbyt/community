"""
Applet: Avatars In Pixels
Summary: Show a pixel art character
Description: Displays a random pixel art character from https://www.avatarsinpixels.com/.
Author: Daniel Sitnik
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

CACHE_TTL = 3600
ERROR_ICON = base64.decode("""
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
""")

def main():
    img = get_avatar()

    if type(img) == "dict" and img["error"] != None:
        return render_error(img["error"])
    else:
        return render_animation(img)

def get_avatar():
    # check if we have a cached image
    cached_img = cache.get("minipix")

    if cached_img != None:
        return cached_img

    # first request, returns the URL of the generated avatar
    res = http.post("https://www.avatarsinpixels.com/minipix/Update", headers = {
        "accept": "application/json, text/javascript, */*; q=0.01",
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
        "referer": "https://www.avatarsinpixels.com/minipix/clothing/Body",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
    }, form_body = {
        "action": "actions",
        "Actions": "randomizeColors randomizeLayers",
    })

    if res.status_code != 200:
        print("Generate API error (%d): %s" % (res.status_code, res.body()))
        return {
            "error": res.status_code,
        }

    # extract the PHP session cookie to be used on the next request
    # format: PHPSESSID=6ofhdor04vlqm6b0m6fq0dh995; path=/
    res_headers = res.headers
    php_cookie = res_headers["Set-Cookie"].replace("; path=/", "")

    # retrieve the path to avatar image
    data = res.json()

    # remove the escaped slashes from the path
    src = data["src"].replace("\\", "")

    # request the avatar image
    res = http.get("https://www.avatarsinpixels.com" + src, headers = {
        "accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
        "referer": "https://www.avatarsinpixels.com/minipix/clothing/Body",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
        "cookie": php_cookie,
    })

    if res.status_code != 200:
        print("Image API error (%d): %s" % (res.status_code, res.body()))
        return {
            "error": res.status_code,
        }

    img = res.body()

    # cache the image for 1 hour
    cache.set("minipix", img, ttl_seconds = CACHE_TTL)

    return img

def render_animation(img):
    anim = animation.Transformation(
        child = render.Image(src = img, width = 64),
        duration = 120,
        delay = 10,
        direction = "alternate",
        fill_mode = "forwards",
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(0, -32)],
            ),
        ],
    )

    return render.Root(anim)

def render_error(error):
    return render.Root(
        render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(ERROR_ICON, width = 28),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Text("API", color = "#ff0"),
                            render.Text("ERROR", color = "#ff0"),
                            render.Text(str(error), color = "#f00"),
                        ],
                    ),
                ],
            ),
        ),
    )
