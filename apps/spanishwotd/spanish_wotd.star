"""
Applet: Spanish WoD
Summary: Word of the day in Spanish
Description: Displays the spanish word of the day including definition and translation.
Author: logancornelius
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")

CACHE_KEY = "wotd"
CACHE_LLAVE = "pdd"
CACHE_TTL = 3600  # 1 hour
SPANISH_DICT_WOTD_URL = "https://www.spanishdict.com/wordoftheday"

def render_error():
    return render.Root(
        render.WrappedText("Something went wrong getting today's word!"),
    )

def fetch_word_of_the_day():
    wotd_resp = http.get(SPANISH_DICT_WOTD_URL)

    if wotd_resp.status_code != 200:
        return False

    resp_body = wotd_resp.body()

    pattern = r"window\.SD_COMPONENT_DATA\s*=(.*);"
    matches = re.findall(pattern, resp_body)

    if len(matches) == 0:
        print("Failed to find word or definition from page")
        return False

    match = matches[0]

    data = match.replace("window.SD_COMPONENT_DATA = ", "").replace(";", "")
    parsed_data = json.decode(data)

    wotd = parsed_data["wordOfTheDayData"]

    return {
        "word": wotd["wordDisplay"],
        "definition": wotd["translationText"],
    }

def main():
    print("Starting")

    cached_wotd_dict = cache.get(CACHE_KEY)

    if cached_wotd_dict != None:
        print("Cache hit")

        wotd_dict = json.decode(cached_wotd_dict)
        word = wotd_dict["word"]
        definition = wotd_dict["definition"]
    else:
        print("Cache miss")

        wotd_dict = fetch_word_of_the_day()

        if not wotd_dict:
            return render_error

        word = wotd_dict["word"]
        definition = wotd_dict["definition"]

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(CACHE_KEY, json.encode(wotd_dict), CACHE_TTL)

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    child = render.Column(
                        children = [
                            render.WrappedText(
                                content = word + ":",
                                color = "#00eeff",
                                font = "5x8",
                            ),
                            render.WrappedText(
                                content = definition,
                                font = "5x8",
                            ),
                        ],
                    ),
                    height = 25,
                    offset_start = 23,
                    scroll_direction = "vertical",
                ),
                render.Box(
                    height = 1,
                    color = "#fa0",
                ),
                render.Text(
                    content = "Palabra del Dia",
                    height = 6,
                    font = "CG-pixel-3x5-mono",
                ),
            ],
        ),
        delay = 140,
    )
