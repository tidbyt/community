"""
Applet: Jokes JokeAPI
Summary: Displays jokes from JokeAPI
Description: Displays different jokes from JokeAPI.
Author: rs7q5
"""

# jokeAPI.star
# Created 20220130 RIS
# Last Modified 20230210 RIS

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

base_URL = "https://v2.jokeapi.dev/joke/Any"

def main(config):
    # get any flags
    full_URL = base_URL + "?safe-mode"

    font = "tb-8"  # set font

    # check for cached data
    joke_cached = cache.get("joke_rate")
    if joke_cached != None:  # if any are None then all(title_cached)==False
        print("Hit! Displaying cached data.")
        joke = json.decode(joke_cached)
        joke_txt = format_text(joke, font)
    else:
        # error code checked within each function!!!!
        print("Miss! Calling JokeAPI data.")

        # get the data
        rep = http.get(full_URL)

        if rep.status_code != 200:
            joke = ["Error, could not get jokes!!!!"]
        else:
            # get the joke strings
            if rep.json()["type"] == "twopart":
                joke = [re.sub('"\"|"\n"', "", rep.json()["setup"])]
                joke.append(re.sub('"\"|"\n"', "", rep.json()["delivery"]))
            else:
                joke = [re.sub('"\"|"\n"', "", rep.json()["joke"])]

            # cache the data
            cache.set(
                "joke_rate",
                json.encode(joke),
                ttl_seconds = 43200,
            )  # grabs it twice a day

        joke_txt = format_text(joke, font)  # render the text

    return render.Root(
        delay = int(config.get("speed", 200)),
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Text("JokeAPI", color = "#6600cc", font = font),
                render.Marquee(
                    height = 24,
                    scroll_direction = "vertical",
                    child = render.Column(
                        main_align = "space_between",
                        children = joke_txt,
                    ),
                    offset_start = 10,
                    offset_end = 10,
                ),
            ],
        ),
    )

def format_text(x, font):
    # formats color and font of text
    text_vec = []
    for i, xtmp in enumerate(x):
        if i % 2 == 0:
            ctmp = "#fff"
        else:
            ctmp = "#ff8c00"
        text_vec.append(render.WrappedText(
            xtmp,
            font = font,
            color = ctmp,
            linespacing = -1,
        ))
    return (text_vec)

######################################################
# Schema configuration

speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "200",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "100",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "75",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Scrolling speed",
                icon = "gear",
                default = speed_options[1].value,
                options = speed_options,
            ),
        ],
    )

######################################################
# functions

def http_check(URL):
    rep = http.get(URL)
    if rep.status_code != 200:
        fail("ESPN request failed with status %d", rep.status_code)
    return rep

def pad_text(text):
    # format strings so they are all the same length (leads to better scrolling)
    if type(text) == "dict":
        max_len = max([len(x) for x in text.values()])  # length of each string

        # add padding to shorter titles
        for key, val in text.items():
            text_new = val + " " * (max_len - len(val))
            text[key] = text_new
    else:
        max_len = max([len(x) for x in text])  # length of each string

        # add padding to shorter titles
        for i, x in enumerate(text):
            text[i] = x + " " * (max_len - len(x))
    return text

######################################################
