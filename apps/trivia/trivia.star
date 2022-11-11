"""
Applet: Trivia
Summary: Random trivia question
Description: Displays a random trivia question with category and difficulty.
Author: Jack Sherbal
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("re.star", "re")
load("humanize.star", "humanize")
load("encoding/base64.star", "base64")
load("schema.star", "schema")

JSERVICE = "http://jservice.io/api/random"
CACHE_TTL_SECONDS = 15

def get_data():
    data = cache.get("data")

    if data != None:
        body = base64.decode(data)
    else:
        rep = http.get(JSERVICE)
        if rep.status_code != 200:
            fail("Jservice (Trivia) request failed with status %d", rep.status_code)

        body = rep.body()
        cache.set("data", base64.encode(body), ttl_seconds = CACHE_TTL_SECONDS)

    return json.decode(body)[0]

def remove_chars(strr):
    return re.compile(r"<[^>]+>").sub("", strr)

def calc_delay(question):
    Q_LEN = len(question)

    if Q_LEN < 20:
        return 160

    elif Q_LEN < 50:
        return 140

    return 100

def get_value(value):
    if value == None:
        return "FINAL"

    return humanize.comma(value)

def main():
    body = get_data()
    value = get_value(body["value"])
    question = remove_chars(body["question"])
    answer = remove_chars(body["answer"])
    category = remove_chars(body["category"]["title"])

    DELAY = calc_delay(question)

    return render.Root(
        child = render.Box(
            child = render.Column(
                children = [
                    render.Box(
                        child = render.WrappedText(
                            content = value,
                            color = "#d69f4c",
                            font = "CG-pixel-4x5-mono",
                            height = 6,
                            align = "center",
                        ),
                        height = 6,
                    ),
                    render.Box(
                        height = 1,
                        color = "#fff",
                    ),
                    render.Box(
                        height = 1,
                    ),
                    render.Box(
                        child = render.Marquee(
                            child = render.Column(
                                children = [
                                    render.WrappedText(
                                        content = "Category:\n%s\n----------\n \n%s\n----------\n \n \n \n%s" % (category, question, answer),
                                        font = "tom-thumb",
                                        align = "center",
                                    ),
                                ],
                            ),
                            height = 24,
                            offset_start = 22,
                            scroll_direction = "vertical",
                            align = "center",
                        ),
                    ),
                ],
            ),
            color = "#060CE9",
        ),
        delay = DELAY,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
