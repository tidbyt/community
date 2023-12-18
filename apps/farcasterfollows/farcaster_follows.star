load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# 1. Copy logo from Figma as SVG: https://www.figma.com/file/E1RJ5DNTM8eHZpJI1bcaP3/Public-logo?node-id=1-2&t=4PuwjeL9pH70lnxv-0
# 2. Crop & revert the colors (for dark), export to PNG.
# 2. Resize to 19x19, using nearest neighbour (looks better than then the fuzzyness of bilinear)
# 3. Copy to clipboard and convert to base64 using: https://onlineimagetools.com/convert-image-to-base64
FARCASTER_ICON_DARK_BG = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAE6ADAAQAAAABAAAAEwAAAAAgb1CmAAAAm0lEQVQ4EdVUwQ2AIAyUxnFcyw0cww1cy3nQ1FBzFIoofPQh7aW9uxKtG8LjvT8kfnsSkeOe69VCJMJM6HoQCeEoAZ7rvGOajZdtSnBKkAYgGrPGkdZCh12dZe8M1VH5yXnRGRKxgM5RlGOTzGq08CKZVq3JTWc1zbrmh2TWZ2DhPPI9ZqlI3w3m2Bf9Tlj0Je67z8RBy16TTXsCeUMxD3VSGfcAAAAASUVORK5CYII=""")
FARCASTER_ICON_LIGHT_BG = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAE6ADAAQAAAABAAAAEwAAAAAgb1CmAAAAmklEQVQ4EdVUyQ2AMAyjiHlYih0Ygh1YioVAQRi5URMC7Qce5JBjO1UhddezTNuO/G2c1zHJzPmqIYKwEKYWRCAckHCEbe7pvGSi16CaOlsz4kiLscOmzopnxuqs/OTcdcZEIqBrFpXcJLMGrb5LplUjteksMqwxPySzroHVl5XvNT2QPhuueS77nBj0JW/7P4MD7zICY0WsegA7BTRetiWv/QAAAABJRU5ErkJggg==""")

def main(config):
    # https://gist.github.com/danromero/87be7035aab27bf6a603b2c956022370
    # pixlet encrypt farcasterfollows $KEY
    api_key = secret.decrypt("AV6+xWcE3RYzxZ92Z9lOT0XBWIqjOpZ4hExHXbCOIC8XwninH1mJouAfj+JQTGcXuibmG/DhzhBxhlf7P6EjpEbzGcZmElq+jGX+aq8hvcZaLNawjsYIGWyQ93U36rvsdBoDr1VnTvLJDqshmWvdcZ9AZjYOTWYZ84vvEvXTNyOPnpcdTi3jDHRnWxu5LcyopG0OHRlCAveDeYxmPjfP95zT9N39O/YieSZyktJyd9TwC2+ORAgCve2otB7LfbkbvA==") or config.get("dev_api_key")

    username = config.str("who", "nix")
    count = get_followercount(username, api_key)

    scheme = config.str("scheme", "default")

    if scheme == "purple":
        # purple (works with different bg)
        bg = "#8a63d2"
        textColor = "#fff"
        textColorLabel = "#ffffff"
        textColorUsername = "#ffffff88"
        icon = FARCASTER_ICON_DARK_BG
    else:
        bg = "#000"
        textColor = "#8a63d2"
        textColorLabel = textColor
        textColorUsername = "#ffffff66"
        icon = FARCASTER_ICON_LIGHT_BG

    # make the count bigger if we have the space, but left-align
    # if larger number, make the font smaller, and center-align
    if count < 100000:
        count_font = "6x13"
        count_align = "left"
    else:
        count_font = "tb-8"
        count_align = "center"

    top_row = render.Row(
        children = [
            render.Image(src = icon),
            render.Column(
                cross_align = count_align,
                children = [
                    render.Text(humanize.comma(count), font = count_font, color = textColor),
                    render.Text("followers", font = "tom-thumb", color = textColorLabel),
                ],
            ),
        ],
        main_align = "space_around",
        cross_align = "center",
        expanded = True,
    )

    child = render.Column(
        children = [
            top_row,
            render.Marquee(
                width = 64,
                child = render.Text("@" + username, font = "tb-8", color = textColorUsername),
                align = "center",
                offset_start = 1,
                offset_end = 1,
            ),
        ],
        main_align = "space_between",
        expanded = True,
    )

    box = render.Box(child = render.Padding(child = child, pad = (0, 2, 0, 2)), padding = 0, color = bg)

    return render.Root(child = box)

def get_followercount(username, api_key):
    key = "followercount:" + username
    cached = cache.get(key)
    if cached != None:
        print("Hit! Displaying cached data.")
        count = int(cached)
    else:
        print("Miss! Calling Warpcaster API.")
        rep = http.get(
            "https://api.warpcast.com/v2/user-by-username?username={username}".format(username = username),
            headers = {
                "authorization": "Bearer {token}".format(token = api_key),
            },
        )
        if rep.status_code != 200:
            fail("warpcaster request failed with status %d", rep.status_code)
        count = int(rep.json()["result"]["user"]["followerCount"])

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(key, str(int(count)), ttl_seconds = 240)

    return count

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "who",
                name = "Who?",
                desc = "Farcaster profile to display.",
                icon = "user",
            ),
            schema.Dropdown(
                id = "scheme",
                name = "Style",
                desc = "Pick a color scheme to use",
                icon = "user",
                default = "default",
                options = [
                    schema.Option(
                        display = "Default",
                        value = "default",
                    ),
                    schema.Option(
                        display = "Purple",
                        value = "purple",
                    ),
                ],
            ),
        ],
    )
