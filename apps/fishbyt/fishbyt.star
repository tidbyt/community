"""
Applet: Fishbyt
Summary: Fish facts
Description: Gaze upon glorious marine life.
Author: vlauffer
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 3600 * 24 * 7
FISH_WIDTH = 40
FISH_HEIGHT = 20

OFFSET = 39

FONTS = ["tb-8", "tom-thumb", "Dina_r400-6", "5x8"]
FONT_DEFAULT = FONTS[0]

FAIL_IMAGE = "iVBORw0KGgoAAAANSUhEUgAAAXwAAACqBAMAAABc2el/AAAAD1BMVEUAAAAAAACZAADEAAD/AAAd2XunAAAAAXRSTlMAQObYZgAAAQhJREFUeNrt3NENgyAUQFFXYIW3Qlfo/jP1ryYEyLNqo3LupxBz/BJJZFkkSZIkSZqgcrXw8fHx8fGfyC+llPI+o9eO0s+Aj4+Pj49/D/5Y3nqXdweqW1UDFas7uu0Z8PHx8fHxn8DPLiRa81qi9dp4dC0iIvDx8fHx8fF78xLABD++4ePj4+Pj4zfmjZcA+Pj4+Pj4+Fs2yLtTEh/eFb+1QR6N8PHx8fHxZ+Hv3gxPLBpiGD4+Pj4+/vT8LLXLj2T4+Pj4+Pj4+Pj4+Pj4+Ifxu381JaitffBKhI+Pj4+PPx8/u3LYc1pH/NaRZ5Tg4+Pj4+Nfhe88Tnx8fHx8/L/yJUmSJEm6cR+Kfy40dZeytgAAAABJRU5ErkJggg=="

CONTENT_TITLES = ["Species Name", "Biology", "Location", "Habitat", "Physical Description", "Texture", "Taste"]

FISH_WATCH_URL = "https://www.fishwatch.gov/api/species/"

def main():
    #get fish data and pick a random fish
    fish_barrel = get_fish_barrel()
    random_index = random(len(fish_barrel))
    fish = fish_barrel[random_index]

    # get specific fish
    # fishToGet=FISH_WATCH_URL+"pink-shrimp"
    # fish = http.get(fishToGet).json()[0]

    #check and set an available fish picture. If no picture is found, display FAIL_IMAGE
    fish_pic = fish["Species Illustration Photo"]["src"]
    if fish_pic == None:
        # print("No fish in this pond")
        fish_pic = base64.decode(FAIL_IMAGE)
    else:
        # print("Look at that fish!")
        fish_pic = get_fish_pic(fish_pic)

    #check to see if fish data is present
    if len(fish) == 0:
        fail("Not able to catch fish :(")

    #get a random fact from list
    fact = get_fact(fish, CONTENT_TITLES[1:])

    #modify speed of marquee based on length of fact
    delay_var = 80

    if len(fact[1]) > 80:
        delay_var = 60

    if len(fact[1]) > 109:
        delay_var = 45

    return render.Root(
        delay = delay_var,
        child = render.Marquee(
            width = 64,
            height = 32,
            offset_start = OFFSET,
            offset_end = OFFSET,
            scroll_direction = "vertical",
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.WrappedText(
                        content = fish[CONTENT_TITLES[0]],
                        font = FONT_DEFAULT,
                    ),
                    render.Image(
                        src = fish_pic,
                        width = FISH_WIDTH,
                        height = FISH_HEIGHT,
                    ),
                    render.WrappedText(
                        content = fact[0] + ":",
                        font = FONT_DEFAULT,
                    ),
                    #adding row with expanded = True alligns other children to middle
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.WrappedText(
                                content = fact[1],
                                font = FONT_DEFAULT,
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_fish_pic(url):
    key = base64.encode(url)
    fish_pic_cache = cache.get(key)

    if fish_pic_cache != None:
        # print("Caught one!")
        return base64.decode(fish_pic_cache)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("No fish here! Request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    # print("Let's catch this fish!")
    cache.set(key, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)
    return res.body()

def get_fish_barrel():
    fish_barrel_cached = cache.get("fish_barrel")
    fish_barrel = []
    if fish_barrel_cached != None:
        # print("My barrel is full of fish!")
        fish_barrel = json.decode(fish_barrel_cached)

    else:
        # print("Let's go fishing!")
        rep = http.get(FISH_WATCH_URL)
        if rep.status_code != 200:
            fail("FishWatch request failed with status %d", rep.status_code)
        fish_barrel = rep.json()
        cache.set("fish_barrel", json.encode(fish_barrel), ttl_seconds = CACHE_TTL_SECONDS)

    return fish_barrel

def get_fact(fish_info, content_titles_clone):
    #find a random fact
    for _ in (range(0, len(content_titles_clone))):
        random_index = random(len(content_titles_clone))
        random_attribute = content_titles_clone.pop(random_index)
        fish_facts = fish_info[random_attribute]

        if not fish_facts:
            # print("1: No facts at " + random_attribute)
            continue

        #checks to see if there are multiple facts available. If so, pick a random line
        #If just one fact is available, return if not empty or too long
        fish_facts_split = fish_facts.split("</li>")
        if len(fish_facts_split) == 1:
            fish_fact_sin_chars = remove_chars(fish_facts_split[0])
            if fish_facts_split[0] == "":
                # print("2: No facts at " + random_attribute)
                continue

            if not fact_length_check_by_char(fish_fact_sin_chars):
                # print("Fact is too long: "+fish_fact_sin_chars)
                continue

            return [random_attribute, fish_fact_sin_chars]

        #pick random fact from line
        fish_fact = pick_random_lines(fish_facts_split)
        if fish_fact == "no_valid_lines":
            continue

        return [random_attribute, fish_fact]

    # print("No facts found in get_fact")
    return ["error", "no facts found"]

def pick_random_lines(facts):
    #find a random fact from the array of split lines and return it
    for _ in range(0, len(facts) - 1):
        random_fact_index = random(len(facts))
        random_fact = facts.pop(random_fact_index)
        random_fact = remove_chars(random_fact)
        if random_fact == "":
            # print("blank fact found, picking another line")
            continue

        if not fact_length_check_by_char(random_fact):
            # print("Fact is too long: "+ random_fact)
            continue

        return random_fact

    return "no_valid_lines"

def fact_length_check_by_char(fact):
    if len(fact) > 140:
        return False
    return True

def remove_chars(sentance):
    regex_strings = ["\\<.*?\\>", "\n", "&nbsp;", "&amp;"]
    for re_string in regex_strings:
        sentance = re.sub(re_string, "", sentance)
    return sentance

def random(num):
    randSecond = time.now().nanosecond / 1000
    randNum = int(randSecond % num)
    return randNum

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
