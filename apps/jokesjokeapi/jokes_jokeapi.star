"""
Applet: Jokes JokeAPI
Summary: Displays jokes from JokeAPI
Description: Displays different jokes from JokeAPI.
Author: rs7q5 (RIS)
"""

#jokeAPI.star
#Created 20220130 RIS
#Last Modified 20220201 RIS

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")

#load("math.star","math")
#load("time.star","time")
load("re.star", "re")

base_URL = "https://v2.jokeapi.dev/joke/Any"
blacklist_flags = ["nsfw", "religious", "political", "racist", "sexist", "explicit"]

def main(config):
    #get any flags
    safe_mode = config.bool("safe_mode")
    if safe_mode:
        full_URL = base_URL + "?safe-mode"  #safe-mode overrides any other blacklist flags
    else:
        blacklist_full = ""
        for flag in blacklist_flags:
            if config.bool(flag + "_flag"):
                blacklist_full += flag
                if flag != "explicit":
                    blacklist_full += ","
        if blacklist_full != "":
            full_URL = base_URL + "?blacklistFlags=" + blacklist_full
        else:
            full_URL = base_URL
    font = "tb-8"  #set font

    #check for cached data
    joke_cached = cache.get("joke_rate")
    if joke_cached != None:  #if any are None then all(title_cached)==False
        print("Hit! Displaying cached data.")
        joke = json.decode(joke_cached)
        joke_txt = format_text(joke, font)
    else:
         print("Miss! Calling JokeAPI data.") #error code checked within each function!!!!
        #get the data
        rep = http.get(full_URL)

        if rep.status_code != 200:
            joke = ["Error, could not get jokes!!!!"]
        else:

            #get the joke strings
            if rep.json()["type"]=="twopart":
                joke = [re.sub('"\"|"\n"',"",rep.json()["setup"])]
                joke.append(re.sub('"\"|"\n"',"",rep.json()["delivery"]))
            else:
                joke =  [re.sub('"\"|"\n"',"",rep.json()["joke"])]

        #cache the data
        cache.set("joke_rate",json.encode(joke),ttl_seconds=43200) #grabs it twice a day
        joke_txt = format_text(joke,font) #render the text
    return render.Root(
        delay = 200,  #speed up scroll text
        child = render.Column(
            children = [
                render.Text("JokeAPI", color = "#6600cc", font = font),
                render.Marquee(
                    height = 32,
                    scroll_direction = "vertical",
                    child = render.Column(
                        main_align = "space_between",
                        children = joke_txt,
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "safe_mode",
                name = "Safe Mode",
                desc = "Only jokes that are considered safe for everyone are returned (If enabled this will override all other exclude flags, should filter dark jokes too).",
                icon = "triangle-exclamation",
                default = True,
            ),
            schema.Toggle(
                id = "nsfw_flag",
                name = "NSFW flag",
                desc = "NSFW jokes are excluded.",
                icon = "triangle-exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "religious_exclude",
                name = "Religious flag",
                desc = "Religious jokes are excluded.",
                icon = "triangle-exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "political_flag",
                name = "Political flag",
                desc = "Political jokes are excluded.",
                icon = "triangle-exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "racist_flag",
                name = "Racist flag",
                desc = "Racist jokes are excluded.",
                icon = "triangle-exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "sexist_flag",
                name = "Sexist flag",
                desc = "Sexist jokes are excluded.",
                icon = "triangle-exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "explicit_flag",
                name = "Explicit flag",
                desc = "Explicit jokes are excluded.",
                icon = "triangle-exclamation",
                default = False,
            ),
        ],
    )

def format_text(x, font):
    #formats color and font of text
    text_vec = []
    for i, xtmp in enumerate(x):
        if i % 2 == 0:
            ctmp = "#fff"
        else:
            ctmp = "#ff8c00"
        text_vec.append(render.WrappedText(xtmp, font = font, color = ctmp, linespacing = -1))
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
