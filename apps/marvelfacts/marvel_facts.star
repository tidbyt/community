"""
Applet: Marvel Facts
Summary: Character Info
Description: Gives you the description or number of comics a random character has been in.
Author: Kaitlyn Musial
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("time.star", "time")
load("hash.star", "hash")
load("random.star", "random")
load("secret.star", "secret")
load("schema.star", "schema")

PUB_KEY = secret.decrypt("AV6+xWcE0v4YH9lODOCdmDnspLyu06WQZeQcmaZtFxVySRVeC1izFlH9+gFHQSrvNGzTg9Y012GqV7wI0v2Exo6vys6Qqxvtt6cGLUhz6WX82Oymia7zlrrr5VoSICD27SFLBOZ0YhxlmUj7nskxekYezPXMS7gHpA8pkE1MiuxWNKZOb+w=")
PRIV_KEY = secret.decrypt("AV6+xWcEU31fHtInxsumnOP76pedrmT/hciDjVkoMogu8XxcoUmI3ATBHYmsPafR6Bhi1UzARytoR5eIEz2LKdgSLwR0LaMbYC/St+F4EF/0QXgsraPfNzzDfvMAobYEE/YEagahrdKuGuQji6zN7lo2kxd75Rc0U5Gt+cEFi9lhpcZAZ6758tA2JaQgQA==")
BASE_URL = "https://gateway.marvel.com:443/v1/public/characters?apikey=422c32a7c4c3f9adfe3f4aef0db1a1e8"
LIMIT = "50"

def main():
    rate_cached = cache.get("new-char")
    if rate_cached != None:
        print("Hit! Displaying cached data.")
        char_name = cache.get("char_name")
        char_desc = cache.get("char_desc")
        char_comics = cache.get("char_comics")
        char_series = cache.get("char_series")
    else:
        print("Miss! Calling Marvel API.")
        char = getNew()
        char_name = char[0]
        char_desc = char[1]
        char_comics = char[2]
        char_series = char[3]
        cache.set("new-char", "got", ttl_seconds = 1800)

    if char_desc == "":
        next_text = "Comics: " + str(char_comics) + "\nSeries: " + str(char_series)
    else:
        next_text = char_desc

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    color = "#a31212",
                    child = render.Box(
                        width = 62,
                        height = 30,
                        color = "#000000",
                    ),
                ),
                render.Column(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [render.Marquee(
                                width = 62,
                                height = 8,
                                align = "center",
                                child = render.Text(str(char_name), font = "Dina_r400-6"),
                                scroll_direction = "horizontal",
                            )],
                        ),
                        render.Row(
                            main_align = "space_evenly",
                            cross_align = "center",
                            expanded = True,
                            children = [
                                render.Marquee(
                                    width = 60,
                                    height = 22,
                                    align = "center",
                                    child = render.WrappedText(content = str(next_text), width = 64, font = "tb-8", align = "center"),
                                    scroll_direction = "vertical",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

# Gets new character from the database
def getNew():
    now = str(time.now()).split(" ")[1]
    digest = str(now) + PRIV_KEY + PUB_KEY
    FULL_KEY = hash.md5(digest)

    MAX_OFFSET = 1562 - int(LIMIT) - 1
    OFFSET = random.number(0, MAX_OFFSET)

    FINAL_URL = BASE_URL + "&limit=" + LIMIT + "&offset=" + str(OFFSET) + "&ts=" + str(now) + "&hash=" + FULL_KEY

    full_list = http.get(FINAL_URL).body()
    full_json = json.decode(full_list)

    CHOICE = random.number(0, int(LIMIT) - 1)

    CHARACTER = full_json["data"]["results"][CHOICE]

    char_name = CHARACTER["name"]
    char_desc = CHARACTER["description"]
    char_comics = CHARACTER["comics"]["available"]
    char_series = CHARACTER["series"]["available"]

    cache.set("char_name", char_name)
    cache.set("char_desc", char_desc)
    cache.set("char_comics", str(char_comics))
    cache.set("char_series", str(char_series))

    if char_name == "None":
        return getNew()
    else:
        return [char_name, char_desc, char_comics, char_series]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
