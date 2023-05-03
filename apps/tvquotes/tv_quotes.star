"""
Applet: TV Quotes
Summary: Display Television Quotes
Description: Displays Television Quotes.
Author: rs7q5
"""

#tv_quotes.star
#Created 20220525 RIS
#Last Modified 20230210 RIS

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

font = "CG-pixel-3x5-mono"

def main(config):
    if config.bool("hide_app", False):
        return []

    #get the quote
    quote = get_quote(config)

    #format header text
    header_txt_raw = quote["show"]

    #check if character should be shown (will be shown if no name is the quote text)
    if quote["show"] != "Error" and (quote["text"].find("%s:" % quote["character"]) == -1 or config.bool("display_character", False)):  #character name doesn't show up
        header_txt_raw += " - %s" % quote["character"]

    #format header and quote text
    header_txt = render.Marquee(width = 64, child = render.Text(content = header_txt_raw, font = font, color = "#D2691E"))
    quote_format = format_quote(quote["text"])

    scroll_opt = config.str("speed", "50")
    return render.Root(
        delay = int(scroll_opt),  #speed up scroll text
        show_full_animation = True,
        child = render.Column(children = [header_txt, quote_format]),
    )

def get_schema():
    shows = [
        schema.Option(display = show, value = show)
        for show in get_shows()
    ]

    scroll_speed = [
        schema.Option(display = "Slowest", value = "200"),
        schema.Option(display = "Slower", value = "100"),
        schema.Option(display = "Slow", value = "70"),
        schema.Option(display = "Normal (Default)", value = "50"),
        schema.Option(display = "Fast", value = "30"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "show",
                name = "TV show",
                desc = "Select TV show.",
                icon = "tv",
                default = "Seinfeld",
                options = shows,
            ),
            schema.Toggle(
                id = "random_quote",
                name = "Random quote",
                desc = "Enable to display a random quote.",
                icon = "shuffle",
                default = True,
            ),
            schema.Toggle(
                id = "short_quote",
                name = "Short quote",
                desc = "Enable to display quotes from a single character.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "display_character",
                name = "Display character name?",
                desc = "Enable to always display character name.",
                icon = "eye",
                default = False,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll speed",
                desc = "Change the speed that the text scrolls.",
                icon = "gear",
                default = scroll_speed[3].value,
                options = scroll_speed,
            ),
            schema.Toggle(
                id = "hide_app",
                name = "Hide app?",
                desc = "",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )

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

######################################################
#functions to get data
def get_shows():
    #get list of shows for config
    SHOWS_URL = "https://quotes.alakhpc.com/quotes/shows"

    shows_cached = cache.get("tvquotes_shows")
    if shows_cached != None:
        print("Hit! Getting cached TV quotes shows list data.")
        shows_list = json.decode(shows_cached)
    else:
        print("Miss! Calling TV quotes shows list data.")
        rep = http.get(SHOWS_URL)
        if rep.status_code != 200:  #fall back on default list
            print("Error getting tv shows list, falling back to an old list!!!!")
            shows_list = [
                "How I Met Your Mother",
                "The Middle",
                "New Girl",
                "Suits",
                "3rd Rock from the Sun",
                "Arrested Development",
                "Malcolm in the Middle",
                "Monk",
                "The Fresh Prince of Bel-Air",
                "Parks And Recreation",
                "Home Improvement",
                "Cheers",
                "Modern Family",
                "Seinfeld",
                "The Office",
                "The Goldbergs",
                "Gilmore Girls",
                "Frasier",
                "Breaking Bad",
                "Scrubs",
                "Boy Meets World",
                "Everybody Loves Raymond",
                "The Good Place",
                "Brooklyn Nine-Nine",
                "Everybody Hates Chris",
                "Lucifer",
                "Schitt's Creek",
                "Derry Girls",
                "Friends",
                "Stranger Things",
                "The Golden Girls",
            ]
        else:
            shows_list = rep.json()["shows"]
            cache.set("tvquotes_shows", json.encode(shows_list), ttl_seconds = 1209600)  #cache list for 2 weeks

    return shows_list

def get_quote(config):
    #get tv quote
    QUOTE_URL = "https://quotes.alakhpc.com/quotes?short=%s" % str(config.bool("short_quote", False)).lower()
    show = config.str("show", "Seinfeld")

    #get cache key
    if config.bool("random_quote", True):
        cache_key = "random_tvquote"
        show_txt = "Random"
    else:
        show_txt = show
        cache_key = "tvquote_%s" % show
        QUOTE_URL += "&show=%s" % show.replace(" ", "%20")  #add "%20" so URL doesn't fail

    #change cache key to get short quotes
    if config.bool("short_quote", False):
        cache_key += "_short"

    quote_cached = cache.get(cache_key)
    if quote_cached != None:
        print("Hit! Getting cached %s TV quote data." % show_txt)
        quote = json.decode(quote_cached)
    else:
        print("Miss! Calling %s TV quote data." % show_txt)
        rep = http.get(QUOTE_URL)
        if rep.status_code != 200:
            print("TV Quote request failed with status %d" % rep.status_code)
            return {
                "show": "Error",
                "character": "",
                "text": "Could not get TV Quote!!!!",
            }
        else:
            quote = rep.json()
            cache.set(cache_key, json.encode(quote), ttl_seconds = 300)  #cache the quote for 5 minutes

    return quote

def format_quote(quote):
    #formats quote text
    frame_data = []
    for (idx, line) in enumerate(quote.splitlines()):
        if idx % 2 == 0:
            ctmp = "#fff"
        else:
            ctmp = "#c8c8fa"
        line_tmp = split_sentence(line, 12, join_word = True)  #combine and split words correctly
        line_format = render.WrappedText(content = line_tmp, width = 64, color = ctmp, font = font, linespacing = 1)
        frame_data.append(line_format)

    return render.Marquee(
        height = 32,
        offset_start = 32,
        offset_end = 32,
        scroll_direction = "vertical",
        child = render.Column(
            children = frame_data,
        ),
    )
