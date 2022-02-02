"""
Applet: National Today
Summary: Get National Today holidays
Description: Displays today's holidays from National Today.
Author: rs7q5 (RIS)
"""

#nationalToday.star
#Created 20220130 RIS
#Last Modified 20220201 RIS

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")

#load("time.star","time")
load("re.star", "re")

base_URL = "https://nationaltoday.com/what-is-today/"

def main():
    font = "tb-8"  #set font

    #check for cached data
    holidays_cached = cache.get("holiday_rate")
    if holidays_cached != None:  #if any are None then all(title_cached)==False
        print("Hit! Displaying cached data.")

        holiday_txt = json.decode(holidays_cached)
        holiday_fmt = format_text(holiday_txt, font)
    else:
        print("Miss! Calling NationalToday data.")  #error code checked within each function!!!!

        #get the data
        rep = http.get(base_URL)
        if rep.status_code != 200:
            holidays_list = re.findall('holiday-title">(.*?)<', rep.body())  #finds the holiday titles for the current day

            #get the date text too
            date = re.findall('meta name="description" content=(.*?)-', rep.body())[0]  #(.*?)/>',rep.body())
            date = re.sub('meta name="description" content="| -', "", date)

            #parse through and set up text for each holiday
            holiday_txt = []
            for i, holiday in enumerate(holidays_list):
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
            cache.set("holiday_rate", json.encode(holiday_txt), ttl_seconds = 1800)  # cache for 30 min
        else:
            holiday_txt = ["Error", "Could not get holidays!!!!"]

        holiday_fmt = format_text(holiday_txt, font)

    return render.Root(
        delay = 100,  #speed up scroll text
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Text("National", color = "#0ac6e9", font = "tb-8"),
                        render.Text("Today", color = "#c9232f", font = "tb-8"),
                    ],
                ),
                holiday_fmt[0],  #display's the date
                render.Marquee(
                    height = 32,
                    scroll_direction = "vertical",
                    child = render.Column(
                        main_align = "space_between",
                        children = holiday_fmt[1:],
                    ),
                ),
            ],
        ),
    )

def format_text(x, font):
    #formats color and font of text
    text_vec = [render.Text(x[0], color = "#ff8c00", font = "tom-thumb")]
    for i, holiday in enumerate(x[1:]):
        if i % 2 == 0:
            ctmp = "#c8c8fa"
        else:
            ctmp = "#fff"
        text_vec.append(render.WrappedText(holiday, font = font, color = ctmp, linespacing = -1))
    return (text_vec)

######################################################
#functions
def http_check(URL):
    rep = http.get(URL)
    if rep.status_code != 200:
        fail("ESPN request failed with status %d", rep.status_code)
    return rep

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
