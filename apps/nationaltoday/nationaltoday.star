"""
Applet: National Today
Summary: Get National Today holidays
Description: Displays today's holidays from National Today.
Author: rs7q5
"""

#nationalToday.star
#Created 20220130 RIS
#Last Modified 20230210 RIS

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

BASE_URL = "https://nationaltoday.com/what-is-today/"

QR_CODE = qrcode.generate(
    url = BASE_URL,
    size = "large",
    color = "#fff",
    background = "#000",
)
QR_IMAGE = render.Box(width = 32, height = 32, child = render.Image(src = QR_CODE))

def main(config):
    font = "tb-8"  #set font

    #check for cached data
    holidays_cached = cache.get("holiday_rate")
    if holidays_cached != None:  #if any are None then all(title_cached)==False
        print("Hit! Displaying cached data.")

        holiday_txt = json.decode(holidays_cached)
    else:
        print("Miss! Calling NationalToday data.")  #error code checked within each function!!!!

        #get the data
        rep = http.get(BASE_URL)
        if rep.status_code != 200:
            holiday_txt = ["Error", "Could not get holidays!!!!"]
        else:
            holidays_list = re.findall('holiday-title">(.*?)<', rep.body())  #finds the holiday titles for the current day

            #get the date text too
            date = re.findall('meta name="description" content=(.*?)-', rep.body())[0]  #(.*?)/>',rep.body())
            date = re.sub('meta name="description" content="| -', "", date)

            #parse through and set up text for each holiday
            holiday_txt = []
            for _, holiday in enumerate(holidays_list):
                holiday_txt.append(re.sub('holiday-title">|<', "", holiday))

            if holiday_txt == []:
                holiday_txt = ["No holidays today :("]

            #shorten month name and add text to holidays
            date_split = date.split(" ")
            if date_split[0] in ("June", "July", "September"):
                date_split[0] = date_split[0][:4]
            else:
                date_split[0] = date_split[0][:3]

            holiday_txt.insert(0, " ".join(date_split))

            #cache the data
            cache.set("holiday_rate", json.encode(holiday_txt), ttl_seconds = 1800)  #cache for 30 minutes

    if config.bool("qrcode", False):
        date_fmt = render.WrappedText(holiday_txt[0], color = "#ff8c00", font = "tom-thumb", width = 32)
        display_tmp = render.Row(
            children = [
                render.Column(
                    children = [
                        render.Text("National", color = "#0ac6e9", font = "tom-thumb"),
                        render.Text("Today", color = "#c9232f", font = "tom-thumb"),
                        date_fmt,
                    ],
                ),
                QR_IMAGE,
            ],
        )
    else:
        holiday_fmt = format_text(holiday_txt, font)
        display_tmp = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Text("National", color = "#0ac6e9", font = "tb-8"),
                        render.Text("Today", color = "#c9232f", font = "tb-8"),
                    ],
                ),
                holiday_fmt[0],  #displays the date
                render.Marquee(
                    height = 32,
                    scroll_direction = "vertical",
                    child = render.Column(
                        main_align = "space_between",
                        children = holiday_fmt[1:],
                    ),
                ),
            ],
        )

    return render.Root(
        delay = 100,  #speed up scroll text
        show_full_animation = True,
        child = display_tmp,
    )

def get_schema():
    return [
        schema.Toggle(
            id = "qrcode",
            name = "Display QR code?",
            desc = "Enable to display a QR code to today's holidays.",
            icon = "qrcode",
            default = False,
        ),
    ]

def format_text(x, font):
    #formats color and font of text
    text_vec = [render.Text(x[0], color = "#ff8c00", font = "tom-thumb")]
    for i, holiday in enumerate(x[1:]):
        if i % 2 == 0:
            ctmp = "#c8c8fa"
        else:
            ctmp = "#fff"

        holiday_tmp = split_sentence(holiday, 12, join_word = True)  #combine and split words correctly
        text_vec.append(render.WrappedText(holiday_tmp, font = font, color = ctmp, linespacing = -1))
    return (text_vec)

######################################################
#functions
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

def pad_text(text):
    #format strings so they are all the same length (leads to better scrolling)
    if type(text) == "dict":
        max_len = max([len(x) for x in text.values()])  #length of each string

        #add padding to shorter titles
        for key, val in text.items():
            text_new = val + " " * (max_len - len(val))
            text[key] = text_new
    else:
        max_len = max([len(x) for x in text])  #length of each string

        #add padding to shorter titles
        for i, x in enumerate(text):
            text[i] = x + " " * (max_len - len(x))
    return text

######################################################
