"""
Applet: Tidbyt Clocks
Summary: Displays Tidbyt clock apps
Description: Displays clock apps available on the Tidbyt. Apps that have "clock" in the app name or description are listed. A clock is also displayed in the background.
Author: rs7q5
"""
#tidbyt_clocks.star
#Created 20230128 RIS
#Last Modified 20230210 RIS

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

BASE_URL = "https://api.tidbyt.com/v0/apps"
FONT = "tom-thumb"
DEFAULT_TIMEZONE = "America/New_York"

def main(config):
    #get list of apps
    cached_data = cache.get("app_list")
    if cached_data != None:
        print("Hit! Using cached app list data.")
        data = json.decode(cached_data)
    else:
        print("Miss! Refreshing app list data.")

        #get the data
        rep = http.get(BASE_URL)
        if rep.status_code != 200:
            data = None
        else:
            data = [(x["id"], (x["name"], x["description"])) for x in rep.json()["apps"]]
            data = dict(data)
            cache.set("app_list", json.encode(data), ttl_seconds = 3600)  #refresh app list every hour

    #find the apps that have clock in the name or description
    if data == None:
        clock_list = ["Error getting list of apps!!!!"]  #error in getting data
    else:
        clock_list = []
        for app_val in data.values():
            clock_logic = app_val[0].lower().rfind("clock") != -1 or app_val[1].lower().rfind("clock") != -1
            if clock_logic:
                clock_list.append(app_val[0])  #get app name

    #get total number of clocks
    clock_cnt = "" if data == None else len(clock_list)
    final_list = format_text(clock_list, FONT)

    #get current time
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    time_text = [render.Text(content = now.format("15:04"), font = "10x20")] * 5  #mulitply by 5 so the time animation is actually as if delay=500
    time_text.extend([render.Text(content = now.format("15 04"), font = "10x20")] * 5)
    time_frame = render.Box(
        width = 64,
        height = 26,
        child = render.Animation(
            children = time_text,
        ),
    )

    final_frame = render.Column(
        children = [
            render.Marquee(
                width = 64,
                child = render.Text("Clock Apps:" + str(clock_cnt), font = "CG-pixel-3x5-mono"),
            ),
            render.Box(width = 64, height = 1, color = "#c993d5"),
            render.Stack(
                [
                    time_frame,
                    render.Box(width = 64, height = 64, color = "#000000bf"),  #this is to make the clock visible in the back
                    render.Marquee(
                        height = 26,
                        scroll_direction = "vertical",
                        offset_start = 32,
                        offset_end = 32,
                        child = render.Column(
                            main_align = "space_between",
                            children = final_list,
                        ),
                    ),
                ],
            ),
        ],
    )
    return render.Root(
        delay = 100,  #speed up scroll text
        max_age = 120,
        show_full_animation = True,
        child = final_frame,
    )

######################################################
#functions
def format_text(x, font):
    #formats color and font of text
    text_vec = []
    for i, word in enumerate(x):
        if i % 2 == 0:
            ctmp = "#c8c8fa"
        else:
            ctmp = "#fff"

        word_tmp = split_sentence(word, 14, join_word = True)  #combine and split words correctly
        text_vec.append(render.WrappedText(word_tmp, font = font, color = ctmp))
    return (text_vec)

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
