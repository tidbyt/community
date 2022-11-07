"""
Applet: Marvel Facts
Summary: Character Info
Description: Gives you the description or number of comics a random character has been in.
Author: Kaitlyn Musial
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("time.star", "time")
load("hash.star", "hash")
load("random.star", "random")
load("secret.star", "secret")
load("cache.star", "cache")

PUB_KEY = secret.decrypt("AV6+xWcE0v4YH9lODOCdmDnspLyu06WQZeQcmaZtFxVySRVeC1izFlH9+gFHQSrvNGzTg9Y012GqV7wI0v2Exo6vys6Qqxvtt6cGLUhz6WX82Oymia7zlrrr5VoSICD27SFLBOZ0YhxlmUj7nskxekYezPXMS7gHpA8pkE1MiuxWNKZOb+w=")
PRIV_KEY = secret.decrypt("AV6+xWcEU31fHtInxsumnOP76pedrmT/hciDjVkoMogu8XxcoUmI3ATBHYmsPafR6Bhi1UzARytoR5eIEz2LKdgSLwR0LaMbYC/St+F4EF/0QXgsraPfNzzDfvMAobYEE/YEagahrdKuGuQji6zN7lo2kxd75Rc0U5Gt+cEFi9lhpcZAZ6758tA2JaQgQA==")
BASE_URL = "https://gateway.marvel.com:443/v1/public/characters?apikey="+PUB_KEY
LIMIT = "50"

def main(config):
    rate_cached = cache.get("new-char")
    if rate_cached != None:
        print("Hit! Displaying cached data.")
        charName = cache.get("charName")
        charDesc = cache.get("charDesc")
        charComics = cache.get("charComics")
        charSeries = cache.get("charSeries")
    else:
        print("Miss! Calling Marvel API.")
        char = getNew()
        charName = char[0]
        charDesc = char[1]
        charComics = char[2]
        charSeries = char[3]
        cache.set("new-char", "got", ttl_seconds=1800)

    if charDesc == "":
        nextText = "Comics: "+str(charComics)+"\nSeries: "+str(charSeries)
    else:
        nextText = charDesc

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
            color="#a31212",
            child=render.Box(
                width=62,
                height=30,
                color="#000000"
            )
        ),render.Column(
            children = [
                render.Row(
                        expanded=True,
                        main_align="center",
                        children = [render.Marquee(
                                        width=62,
                                        height=8,
                                        align="center",
                                        child=render.Text(str(charName), font="Dina_r400-6"),
                                        scroll_direction="horizontal",
                                    )]
        ),
        render.Row(
            main_align="space_evenly",
            cross_align="center",
            expanded = True,
            children = [
                render.Marquee(
                    width=60,
                    height=22,
                    align="center",
                    child=render.WrappedText(content=str(nextText), width=64,font="tb-8",align="center"),
                    scroll_direction="vertical"
                ),
                
            ]
        )
        ],
        )
        ]
        )
    )
    

def getNew():
    now = str(time.now()).split(" ")[1]
    digest = str(now)+PRIV_KEY+PUB_KEY
    FULL_KEY = hash.md5(digest)

    MAX_OFFSET = 1562-int(LIMIT)-1
    OFFSET = random.number(0, MAX_OFFSET)

    FINAL_URL = BASE_URL+"&limit="+LIMIT+"&offset="+str(OFFSET)+"&ts="+str(now)+"&hash="+FULL_KEY
    
    fullList = http.get(FINAL_URL).body()
    fullJson = json.decode(fullList)
    
    CHOICE = random.number(0, int(LIMIT)-1)

    CHARACTER = fullJson["data"]["results"][CHOICE]

    charName = CHARACTER["name"]
    charDesc = CHARACTER["description"]
    charComics = CHARACTER["comics"]["available"]
    charSeries = CHARACTER["series"]["available"]
    charStories = CHARACTER["stories"]["available"]

    cache.set("charName", charName)
    cache.set("charDesc", charDesc)
    cache.set("charComics", str(charComics))
    cache.set("charSeries", str(charSeries))
    cache.set("charStories", str(charStories))

    if charName == "None":
        getNew()
    else:
        return [charName, charDesc, charComics, charSeries, charStories]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
