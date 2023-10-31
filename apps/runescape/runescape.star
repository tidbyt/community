"""
Applet: OS Runescape Grand Exchange
Summary: Shows item information from OSRS's Grand Exchange
Description: Shows item information from Runescape using the Runescape API.
Author: blakekwehrle
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")

CACHE_TTL_SECONDS = 36604800  # 7 days in seconds.
RUNESCAPEAPI_ITEMLIST_URL = "https://secure.runescape.com/m=itemdb_oldschool/api/catalogue/items.json?category=1&alpha={0}&page={1}"
PAGE_LENGTH_BY_LETTER = {
    "a": 30,
    "b": 40,
    "c": 16,
    "d": 20,
    "e": 11,
    "f": 8,
    "g": 18,
    "h": 5,
    "i": 10,
    "j": 4,
    "k": 4,
    "l": 7,
    "m": 25,
    "n": 3,
    "o": 9,
    "p": 13,
    "r": 25,
    "s": 44,
    "t": 22,
    "u": 5,
    "v": 5,
    "w": 11,
    "x": 1,
    "y": 3,
    "z": 5,
}

UP_CARROT_ICON = base64.decode("""R0lGODdhBgAFAHcAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQFQAAAACwAAAAABgAFAIEAAABZwTXW8mQAAAACCQRkJoEX35KMBQAh+QQJQAAAACwAAAAABgAFAIEAAABZwTXW8mQAAAACCQRkJoEX35KMBQAh+QQFQAAAACwAAAAABgAFAIEAAABZwTXW8mQAAAACCoQiYMGp/5w6rgAAIfkECUAAAAAsAAAAAAYABQCBAAAAWcE11vJkAAAAAgqEImDBqf+cOq4AACH5BAVAAAAALAAAAAAGAAUAgQAAAFnBNdbyZAAAAAIJVC6gu9nhDAIFACH5BAlAAAAALAAAAAAGAAUAgQAAAFnBNdbyZAAAAAIJVC6gu9nhDAIFACH5BAVAAAAALAAAAAAGAAUAgQAAAFnBNdbyZAAAAAIJhG+CEgocGjoFACH5BAlAAAAALAAAAAAGAAUAgQAAAFnBNdbyZAAAAAIJhG+CEgocGjoFADs=""")
DOWN_CARROT_ICON = base64.decode("""R0lGODdhBgAFAHcAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQFBQAAACwAAAAABgAFAIEAAADuCwv4cHAAAAACCIQvoWLJeKIpACH5BAkFAAAALAAAAAAGAAUAgQAAAO4LC/hwcAAAAAIIhC+hYsl4oikAIfkEBQUAAAAsAAAAAAYABQCBAAAA7gsL+HBwAAAAAgkEZKkSjReekQUAIfkECQUAAAAsAAAAAAYABQCBAAAA7gsL+HBwAAAAAgkEZKkSjReekQUAIfkEBQUAAAAsAAAAAAYABQCBAAAA7gsL+HBwAAAAAgqEIqC2rRfQk6AAACH5BAkFAAAALAAAAAAGAAUAgQAAAO4LC/hwcAAAAAIKhCKgtq0X0JOgAAAh+QQFBQAAACwAAAAABgAFAIEAAADuCwv4cHAAAAACClQuAJa6DpVBoAAAIfkECQUAAAAsAAAAAAYABQCBAAAA7gsL+HBwAAAAAgpULgCWug6VQaAAADs=""")
LINE_ICON = base64.decode("""R0lGODdhBgAFAHcAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQFCgAAACwAAAAABgAFAIAAAABw2O4CCIQPoRbXCE8BACH5BAkKAAAALAAAAAAGAAUAgAAAAHDY7gIIhA+hFtcITwEAIfkEBQoAAAAsAAAAAAYABQCAAAAAcNjuAgeEb6Gw6F8AACH5BAkKAAAALAAAAAAGAAUAgAAAAHDY7gIHhG+hsOhfAAAh+QQFCgAAACwAAAAABgAFAIAAAABw2O4CB4R/EaaJbwoAIfkECQoAAAAsAAAAAAYABQCAAAAAcNjuAgeEfxGmiW8KACH5BAUKAAAALAAAAAAGAAUAgAAAAHDY7gIIhI9xocAIQQEAIfkECQoAAAAsAAAAAAYABQCAAAAAcNjuAgiEj3GhwAhBAQAh+QQFCgAAACwAAAAABgAFAIAAAABw2O4CB4SPGQHLeQoAIfkECQoAAAAsAAAAAAYABQCAAAAAcNjuAgeEjxkBy3kKACH5BAUKAAAALAAAAAAGAAUAgAAAAHDY7gIIhI8WtxCfTgEAIfkECQoAAAAsAAAAAAYABQCAAAAAcNjuAgiEjxa3EJ9OAQAh+QQFCgAAACwAAAAABgAFAIAAAABw2O4CB4SPFpGw3AoAIfkECQoAAAAsAAAAAAYABQCAAAAAcNjuAgeEjxaRsNwKACH5BAUKAAAALAAAAAAGAAUAgAAAAHDY7gIHhB+HqRDcCgAh+QQJCgAAACwAAAAABgAFAIAAAABw2O4CB4Qfh6kQ3AoAIfkEBQoAAAAsAAAAAAYABQCAAAAAcNjuAgeEH3GoC+0KACH5BAkKAAAALAAAAAAGAAUAgAAAAHDY7gIHhB9xqAvtCgAh+QQFCgAAACwAAAAABgAFAIAAAABw2O4CB4QfeRjrWwAAIfkECQoAAAAsAAAAAAYABQCAAAAAcNjuAgeEH3kY61sAADs=""")

def main():
    random_letter = "abcdefghijklmnoprstuvwxyz"[pick_letter()]
    item_list = get_item_list(random_letter)
    number_of_items = len(item_list["items"])
    random_item_index = random.number(0, number_of_items - 1)
    item_name = item_list["items"][random_item_index]["name"]
    item_trend = item_list["items"][random_item_index]["today"]["trend"]
    item_price = str(item_list["items"][random_item_index]["current"]["price"]) + " gp"
    sprite_url = item_list["items"][random_item_index]["icon"]
    sprite = get_cachable_data(sprite_url)
    if (item_trend == "positive"):
        selected_image = UP_CARROT_ICON
    elif (item_trend == "neutral"):
        selected_image = DOWN_CARROT_ICON
    else:
        selected_image = LINE_ICON
    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    children = [
                        render.Box(width = 32),
                        render.Box(render.Image(sprite)),
                    ],
                ),
                render.Column(
                    children = [
                        render.WrappedText(
                            content = item_name,
                            width = 64,
                            font = "tom-thumb",
                        ),
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Image(src = selected_image),
                                render.WrappedText(
                                    content = item_price,
                                    width = 64,
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def pick_letter():
    random_page_index = random.number(0, 344)
    mySum = 0
    for index, pageCount in enumerate(PAGE_LENGTH_BY_LETTER.values()):
        if random_page_index < mySum:
            return index
        else:
            mySum += pageCount
    return 0

def get_item_list(letter):
    url = RUNESCAPEAPI_ITEMLIST_URL.format(letter, random.number(0, PAGE_LENGTH_BY_LETTER[letter]))
    data = get_cachable_data(url)
    return json.decode(data)

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = ttl_seconds)

    return res.body()
