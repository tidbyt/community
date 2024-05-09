"""
Applet: India News
Summary: Top India news
Description: Top 4 news headlines from India.
Author: vipulchhajer
"""

# Credit to jvivona's ESPN news app; borrowed ideas and code from them

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

#this is the API service for news
NEWS_URL = "http://newsapi.org/v2/top-headlines?sources=google-news-in&apiKey="

def main(config):
    # set default api key
    DEFAULT_API = secret.decrypt("AV6+xWcEX/4Xe45UOOKJO96fq/wjTvGwFn7rE8EUXwcONEWE7sG+eXYjEm5M+PmmS5GTV1NzbV3z3X5q7XWdN69xtfpB1KWMBedJf2kndTR6QWsBWZXizDHWDVMA5IUYO14Y7X2tlr+eKCuAZU7iri9BUTuBdO7+5sVRgPU3QoObSbsE9L8=")

    #intialize headline randomizer
    random.seed(time.now().unix // 60)
    shift = random.number(0, 5)

    #Display error if no API found
    if DEFAULT_API == None:
        return render.Root(
            child = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = 7,
                        padding = 0,
                        color = "#cccccc33",
                        child = render.Text("India News", color = "#FF9933", font = "tom-thumb", offset = -1),
                    ),
                    render.WrappedText(
                        content = "Missing API",
                        width = 36,
                    ),
                ],
            ),
        )
    else:
        #get data
        API = DEFAULT_API
        NEWS_API_URL = NEWS_URL + API
        rep = http.get(url = NEWS_API_URL, ttl_seconds = 3600)  #update every 1 hour
        if rep.status_code != 200:
            title = ["Error getting data!!!!", "", "", ""]
        else:
            #get top 3 newest headlines
            title = []
            for i in range(4):
                j = i + shift
                title.append((rep.json()["articles"][j]["title"]).split(" - ")[0])

            #format strings so they are all the same length (leads to better scrolling)
            max_len = max([len(x) for x in title])

            #add padding to shorter titles
            for i, x in enumerate(title):
                title[i] = x + " " * (max_len - len(x))

        #format output
        title_format = []

        # redo titles to make sure words don't get cut off
        for title_tmp in title:
            title_tmp2 = split_sentence(title_tmp.rstrip(), 12, join_word = True).rstrip()

            title_format.append(render.Padding(child = render.WrappedText(content = title_tmp2, color = "#FFFFFF", font = "tom-thumb", linespacing = 1), pad = (0, 0, 0, 6)))

        return render.Root(
            delay = int(config.str("speed", "70")),  #speed up scroll text
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = 7,
                        padding = 0,
                        color = "#cccccc33",
                        child = render.Text("India News", color = "#FF9933", font = "tom-thumb", offset = -1),
                    ),
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        child = render.Column(
                            #main_align="space_between",
                            cross_align = "start",
                            children = title_format,
                        ),
                        offset_start = 32,
                        offset_end = 32,
                    ),
                ],
            ),
        )

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slower", value = "100"),
        schema.Option(display = "Slow", value = "70"),
        schema.Option(display = "Normal", value = "50"),
        schema.Option(display = "Fast (Default)", value = "30"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Text scroll speed.",
                icon = "gear",
                default = scroll_speed[1].value,
                options = scroll_speed,
            ),
        ],
    )

def split_sentence(sentence, span, **kwargs):
    #split long sentences along with long words
    sentence_new = ""
    for word in sentence.split(" "):
        if len(word) >= span:
            sentence_new += split_word(word, span, **kwargs) + " "
        else:
            sentence_new += word + " "

    return sentence_new

def split_word(word, span, join_word = False):
    #split long words
    word_split = []

    for i in range(0, len(word), span):
        word_split.append(word[i:i + span])
    if join_word:
        return " ".join(word_split)
    else:
        return word_split
