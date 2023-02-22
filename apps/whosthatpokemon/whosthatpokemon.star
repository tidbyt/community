"""
Applet: WhosThatPokemon
Summary: Pokemon Quiz Game
Description: Test your Pokemon Master knowledge with this rendition of "Who's That Pokemon?". Turn off classic mode to crank up the difficulty. Set your Tidbyt speed to ensure the animation takes up exactly half the time is has displayed.
Author: Nicole Brooks
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

ALL_POKEMON = 1008
CLASSIC_POKEMON = 386
POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon/{}"
IMGIX_URL = "https://pokesprites.imgix.net/{}.png?bri=-100"
CACHE_TTL_SECONDS = 3600 * 24 * 60  # 60 days in seconds.

def main(config):
    print("Let's play...WHO'S. THAT. POKEMON?!")

    allPokemon = howManyPokemon(config)
    chosenId = random.number(1, allPokemon)
    pokemon = json.decode(getPokemon(chosenId))
    speed = getSpeed(config)

    if pokemon == None:
        return []

    sprite_url = pokemon["sprites"]["front_default"]

    # Variables that will be used by the render.
    name = formatName(pokemon["name"])
    revealedImage = getCachedImage(sprite_url)
    silhouette = getCachedImage(IMGIX_URL.format(chosenId))
    bg = base64.decode(BACKGROUND)

    # If something went wrong with the API, skip the app completely.
    if revealedImage == None or silhouette == None:
        return []

    frames = compileFrames(name, silhouette, revealedImage, speed)
    print("The game is afoot. The secret Pokemon is: " + name)

    return render.Root(
        delay = 125,
        child = render.Stack(
            children = [
                render.Image(
                    src = bg,
                ),
                render.Animation(
                    children = frames,
                ),
            ],
        ),
    )

# Gets cache or pulls from API. Returns a Pokemon or None.
def getPokemon(id):
    url = POKEAPI_URL.format(id)
    cacheKey = base64.encode(url)

    # Check cache
    data = cache.get(cacheKey)
    if data != None:
        return base64.decode(data)

    return pullFromApi(url, cacheKey)

# Gets new Pokemon from API and caches.
def pullFromApi(url, key):
    res = http.get(url)
    if res.status_code != 200:
        print("ERROR: " + str(res.status_code))
        return None

    cache.set(key, base64.encode(res.body()), CACHE_TTL_SECONDS)
    return res.body()

# Formats all names. Removes all hyphens that don't belong for forms and spaces.
# Also capitalizes appropriately.
def formatName(name):
    namesWithSpaces = ["mr-mime", "mime-jr", "porygon-z", "type-null", "tapu-koko", "tapu-lele", "tapu-bulu", "tapu-fini", "mr-rime"]
    namesWithHyphens = ["ho-oh", "jangmo-o", "hakamo-o"]
    if name in namesWithHyphens:
        return name.capitalize()
    elif name in namesWithSpaces:
        return name.replace("-", " ").title()
    elif "-" in name:
        return name.split("-")[0].capitalize()
    else:
        return name.capitalize()

# Gets cached image or new one if cache isn't available.
# Returns image encoded and ready for use.
def getCachedImage(url):
    cacheKey = base64.encode(url)

    # Check cache
    data = cache.get(cacheKey)
    if data != None:
        return base64.decode(data)

    res = http.get(url)
    if res.status_code != 200:
        print("Failed to pull pokemon image: " + res.status_code)
        return None
    cache.set(cacheKey, base64.encode(res.body()), CACHE_TTL_SECONDS)

    return res.body()

# Returns the number of pokemon to pull from.
def howManyPokemon(config):
    allPokemon = ALL_POKEMON
    if config.bool("classics_only", False) == True:
        allPokemon = CLASSIC_POKEMON
    return allPokemon

# Returns the speed of the tidbyt in float format.
def getSpeed(config):
    strSpeed = float(config.get("speed", "15"))
    return strSpeed

# Gets all frames needed for the animation.
def compileFrames(name, silhouette, revealedImage, speed):
    frames = []
    frameCount = int(speed * 8)
    startTransition = frameCount / 2 - 4
    endTransition = frameCount / 2 + 4
    transitionFrame = 0
    for frame in range(1, frameCount):
        if frame < startTransition:
            frames.append(fullLayoutHidden(silhouette, 30))
        elif frame >= endTransition:
            frames.append(fullLayoutRevealed(revealedImage, 30, name))
        else:
            # if it's transitioning, get transition width
            width = getTransitionWidth(transitionFrame)
            if transitionFrame > 3:
                frames.append(fullLayoutRevealed(revealedImage, width, name))
            else:
                frames.append(fullLayoutHidden(silhouette, width))
            transitionFrame += 1

    return frames

# Layout function with text on side.
def fullLayoutHidden(image, width):
    return render.Row(
        expanded = True,
        main_align = "center",
        children = [
            render.Box(
                width = 30,
                height = 30,
                child = render.Padding(
                    pad = (5, 0, 0, 0),
                    child = render.Image(
                        src = image,
                        width = width,
                        height = 30,
                    ),
                ),
            ),
            render.Box(
                width = 32,
                height = 32,
                child = render.Column(
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = "Who's",
                            color = "#3B0301",
                            font = "tom-thumb",
                        ),
                        render.Box(
                            height = 3,
                        ),
                        render.Text(
                            content = "That",
                            color = "#3B0301",
                            font = "tom-thumb",
                        ),
                        render.Box(
                            height = 3,
                        ),
                        render.Text(
                            content = "Pokemon?",
                            color = "#3B0301",
                            font = "tom-thumb",
                        ),
                    ],
                ),
            ),
        ],
    )

# Layout function with text on bottom.
def fullLayoutRevealed(image, width, text):
    return render.Stack(
        children = [
            render.Box(
                width = 38,
                height = 30,
                child = render.Image(
                    src = image,
                    width = width,
                    height = 30,
                ),
            ),
            render.Padding(
                pad = (0, 24, 0, 0),
                child = render.Box(
                    height = 9,
                    child = render.Text(
                        content = text,
                        offset = 0,
                        color = "#240109",
                    ),
                ),
            ),
        ],
    )

# Gets the width the image has to be at this frame of the transition.
def getTransitionWidth(frame):
    widths = [18, 12, 6, 1, 1, 6, 12, 18]
    return widths[frame]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "classics_only",
                name = "Classic Mode",
                desc = "Only use Pokemon from generations 1-3. On by default.",
                icon = "dragon",
                default = True,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Speed of your Tidbyt. This determines how long the silhouette is displayed.",
                icon = "stopwatch",
                default = "15",
                options = [
                    schema.Option(
                        display = "Normal",
                        value = "15",
                    ),
                    schema.Option(
                        display = "Quick",
                        value = "10",
                    ),
                    schema.Option(
                        display = "Turbo",
                        value = "7.5",
                    ),
                    schema.Option(
                        display = "Plaid",
                        value = "5",
                    ),
                ],
            ),
        ],
    )

BACKGROUND = """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAASNXpUWHRSYXcgcHJvZmlsZSB0eXBlIGV4aWYAAH
japZpZchy9EYTfcQofobEDx0FhifANfHx/iR4yJEovv02GOMPpbixVWZlZoNz+z7+P+xdfKT+PS7m20kt5+Eo9
9TB40573a9yf/kn35/1Kn0v8/tvnLnxdCHwUeY3vr6187v/63H8P8L4M3uVfBmrzc8F+v9A/U4f2Y6DPzFEr0v
v1Gah/BorhveA/A4x3W0/prf66Bdvv6/raSXv/Of1I7fdl//F7JXorM08MYUcfH37G+FlA1L/g4uBN5GeIhRt9
7O/7+/NrSwTkb3H6/uqs6OxPKv686besfL/7ka2vxbuf2Urhc0v8EeTy/frXz53PPy7E7/nDb/hpn3fhx+fZf1
b0I/r6d85q5+6ZXYxUCHX5bOpri/cd9xlDaermWFp5Kv8yQ9T73fluoHoChfXMx/ievvtAuo5Pfvnhj9/3dfrJ
ElPYLlTehDBDvB+2WEMPMyp/Sd/+hEomV2xkcd60pxi+1+LvtP2Z7s7WmHl5bg2ewbxw8U+/3T994ByVgveKZX
tjxbpCULBZhjKnn9xGRvz5BDXfAH99//xSXiMZzIqySqQTWHuHsDeZL7biTXTkxszrW4O+rs8AhIipM4vxkQyQ
NR+zL/6pIVTvCWQjQYOlh5iCkQGfc1gsMqRIFdXQgqbmkervrSEHPnZ8DpmRiUx9VXJDrZGslDL4qamBoZFjTj
nnkmtuuedRYkkll1JqESmOGmtyNddSa22119FiSy230mprrbfRQ4+QZu6l195672Mw52DkwdODG8awYNGSZWfF
qjXrNibwmWnmWWadbfY5VlhxwR+rrLra6mtsv4HSTjvvsutuu+9xgNqJ7qSTTzn1tNPP+M7aJ61/fP+DrPlP1sL
NlG6s31nj01q/hvCik6yckbDgkifjVSkA0EE5e5pPKShzytnT4beYA4vMytnyyhgZTNuHfPxX7lx4M6rM/V95c
zX9lrfwv2bOKXX/MHN/5u1vWVuSoXkz9lahgvpEqm+PmeOsPq3Ru4dbxilW4s61lrLcanZ634WYzRLPWMXyCGy
Tj+euPs+dRzzd22lr9Vkt17QHseCNV9ziyjOytXFi2NOevdnNarrTl208Nc/Iie3t0ifJWdt64KN2EvNkg76Yf
i5o8eThemgjV4YiQXtbim1uotkfhDCd6stM6Sl77DJzq2fFdNjmrMUGw6zQTojE47gVjAyfnnYdnYzvxe7PMWY
jbCcNiz7bZnlzsZxiT6v+zHwEiRFmZfBAmlyvIQNcy/FpKbet+UYOaT1nrdONoVZIjQjcgSLvTy1EerFgfq2JX
fTRXQnEeBeGZUGtk9WoqNiI1vMJVs77e4+2+tm7TttGuAaAX4FspN3WztONNheXuGvnM7syZYxqAHDsUzerip5
FDDu1zs0Oi7EsRsehdaBmo7Gy41KY7Tyg6TlPLgtd9LPU3s0MimXWDRhaLFo2k6zRsu9zkbc9+9o8PAwKDQ4QE
J567IYvTW8ARpFhmQw4zz6R3+66P+FfdY9FzbBt0B9YL+Xg1sK/HISU3GV2V++0xhxCGN+hLLC1y+g+kSOG7Ix
5suC5vOr9OVSXe8BB0bRUbmToNgZVPAIZt07iNp/ulfMEEaevM+vFLBulQB/qLZ/WJoCMPGqN4qijUAg8VHdPF
Z+FhjysIwdKuHL/AuCrCB7vPZOcfhDlIf9JoDdcEAq3twG7bFiCSrcYRWasusNvpm2W6Fnc6KXBA6wNfJbdV6h
nTLfxB+SbyBEB4XGoFlNdnhHXk+EsaimFSljyeGqkTD1ArTm3RKGvKoim4qI9Z1BvYQDmQNor1TRCXxNmjY/CG
rJPOeA2SuhtKxZ1BT/KM0cCVlj8XpI78jMFoG0wasQXLusHyMau1FgkZz0bQVI6gQRsw0WIDZoNlrcJdLE5CiR
eJFezuoiMaCkSmjAoaibZfAgVpQeqJLZVe8+B5FOYT82xQ+SxV1dWBDrKBQgjs8ciNAkTxD1hP1TKEms5i4ppfj
/flemDEdLUC965WHBTcZ5rs53DNntYCZCwU+ZhjYX0iWkwaySZBW82HnmA7YD82KGI7fPwDptSqWoKdvEYFcuj
zGUYxKN1WqhTr5dTwB/PhcXSgRZFlCe34jXHcJQgaogPQB/WqczQMvRZY+k5HTgRjYCV2bSCnwFSnRNSPhfgYM
Y2iN2oyPJRM+KODtRrBHcHLtxA2E5QJf51JkwqtFFV7YVyWQdxHKd10p89u3dN3G9L+O4VOyyHrRaQsC+7U3C1
+jiozWATjup3q2mclMDggbi0cJfHfk4mPiQZmu43LmR8A57yQAOUWxirwWxBJbr5uPUCC0GQ7CsN3/oom+4Ig0
GNzJJ9XmcdD8pxBzDp3BenORtg9+grsETM2NOSqOGo8RSnbHgiFlfF0Tc/0vBASs5WArfQyazmoab14gs6m0mK1
09HShpBRO+xA80agDTfC7VfIVt0bcunsA7qePBU6SsKjmFAKEDqULTIH+YEHRiNDMM/fVMiiAQ3poGDkVhgYEc
gKahsLeOAijlm3c9iBtJuvkg66xGEIVICdIHbhxswL9MzPnSSkQ7p736IsHX2+Iw6ISmkwxQ0WKQUZAUdpGthC
ArlETl4l1rRq84Avl/zAyQLMQK/2C+pYgYXeIDhI/bgMUzaLWWsl4nld3GCHVXXWNjL+1iPQCykFitjBTbGbUt
TASXBC4oXoYze6vHgAl2SKKhoSfvamLm6N3VvcPNDCqIfMgO+o1bAfQzUhKIJpNRkiEECkY5kwONOsqOmDB0hC
jAfazxo25WUfQwmBReCxskS6QnN9qX5IkYS1ittG7Sg6Rx5x5kyHMXDtiPwQr1XowIIPw4TWGkoMsXbUkRtDyr
AHHZUPH5UlGA7CPN1amgZ1mdGLC81etA3SwGCAHbQSyFssGuhZuekzMvYIkfANWaRDDm2g/ub4xYi2i/dkQhe6
SHIE3qmDppSuKSZwBCK17rJGkBgDijoca08K864sOMZqoF+IEgZ3knOJ9Y8MCfM58lt/EUeF72unBo5pEStOvFl
olZRPhURFiOrieaBIivR0rgLGx6/qqKl2qnAAd/SOFdEDCmAE6rb6ZUZPHmU/UFFZFWb4en8nRrrKEf9mhq4NL
LGLZkNsWa0y1RcR0oLypsXRrDQ6OOLkYO8sERqPMnMUXGs7Llk33IGDoRvahN4uIkZcx/BHrHBv3tvgkMOqM2+
d35oEfCP8dYOTUt+64pG6Y9X93kDjDGn0GIp8LYB5E63RF3hBqnN2rH9NtRasEHyRPYNYO5IkxNnb8sZXrDgYk
E5TQyPjnoHzAhxAS5VEg5oM65DpsR/mRLqjW1gbn2DvR5H4eGgkKHWxSVFDYv26tmmckeODnkxGSGRHSBCu6kC6
F3cCv3NXup06kr0IItOKlxyi5Vr02jfgRekFDG3pBV8ocA7XyuA5hxUIGxWOL06GOc3AoHHaxLURR6FLuyoehz
JNWJUALF2GaGSSWUVNVnEC45kCBok5JaBcrpGH5OgLomeCczC7bAzeCZWRMOLVMMC5cAQmHemWa9kIaVJu2/OuJ
8KjJQeJv+oKg+LZCI6BJht0uYi1RT+NBpWOSnqa+G4Dr6OZsLQgY4cxQ8AJ0pUyXF7bitGuyR9gA/yJRU0OHVhG
o/83bHQ1srQJ9aJrhX1Y7ogjUYN1VmxP4VhqOyPBBgHutgB28c8QjcQz9MwvB0PFRLcMEQjVXK6Smbh0FfEKpHF
Dh3BdDdDYwMwOBo/DkSZilZs+Ymn94PoRxqk5sbVFtq+MZs8aRs6n/37a5rIRhfxAwVPqDuKJNdlJ7iP6wS6+GC
pWQiebAoEr5ucgOLEKxkWeQ7Qnk+rRdfe1bxhVAk2HxjV7UecEHWmwoYMGe0o9bIXukFPRteyaqKFm+ppCD6FjG
m3N1H03NnVLqMoYehK0+pdgpvEEfico3a5yHv03oxdTdKAb/HgcakLham8Gp3M1kDf9cBdPjMNBmtA87q4pZ4Pe
aFAK2JG6A380xnDDRC9XdelWTxG6zYKsyOEuKZ2aAgxzi2Oa7MBMJbqylHAJjW6PczUviLhl+oIwzjEr44Wv+pG
aRVBJ9qin9OisNNV5eq9eJyUY14TdSZ3ipT77R+adZi5+5EcJYnvPH5fkpGURO1nSQ7jXctSDJ6pJsa6BKnHKFU
ijL3VMGmjY4wOq/vdNw4Gj3g1Jc0SgaQfPu9SE6aAWsSnxXfKgHsrNIl42dBKxdY8WZ5riQ/ACrDSwoDatAnE5k
rw96higIWJjbiiInAcJJj8nKS+cdBBCng03xm5KPAEecEfICyBiKi8PjViYamTPLe9Q/FhdJ1O0BjSJWEWl7tpx
udRImwHWODxYE4a2+RJDP6QxtXoyUApaOsq4BWTRAD3EjrvAMzT8ZBfjd+z/iwyxOPCm2xhR9UG0HhJb1cISIbR
qkz1VNOc+Navfc9gqvhb0hd1TkOkP79iOH3AthDCe5qBB5GhnGidTGb0wNkReREQWJ2LxUU5CSss48l4BtoxeWC
0U8oEPRKhQpFgalfCZpa7OQqOrAHZdJ2mEascRV8ni62JW9ca97zIUSVuRjtXCWClXmWWumxC3OaMhuRO3tne3S
Ag88+NzPbhOhDBgXyIBL4aiYNlaJniHDqUIlB4yIqBQDxok1hW8+G2NfJwekQHZWyV8sUoNdK4R6EtocpVrpho7
JF2tNzGjQtS4Q1Dg5eflD8+GMxJLaLO7PqSyVQXEtUrU9oA3d4KJRmugVA8lzXdoRIqI0FmJIksRR2wTLuTQyb7
lvvetHHXionUasDRw1JuiL3oD8oxsS4YtqR2eM+8dfjC9n4aWfAYdeyO84RAU8KEIZA6k3rgCx1z0Q3ZxP0RXVw
tQ3esbjvzXNJWfcBJ1EaNRFWww8t3PqdrLc5s5WjSYkz0oEFFCPE5ZI3e1UCkzlq0ByMpnU3KMiBIt5taksKmq8
ulbEQMEBNPLGFUzxsbpFbRPXz1aHEqDf0xMo/UCBi7+JNyotGEe5AL+No1VWEtHgJoagbpLHmswXmCO6Pc7vKKr
U8JV40t9GpYKb4mE4ABp2q9kye570nYRNc+XuvrRCVR+/c0jqIyGgq8GJF6Q3rLN+tkzoxau5suedLIwYv0ngjc
GBMr8hQvW9SeKYXhLsBK6wwJTN5qB/iIrnKcNhzupVxLN+XLsuL3fa7mf7GfNE2m/oY1ICLU2hzhHh7W+WzE3+F
KKmVGw4sximrK83PTAedfD3k1BmfSyDTSylY6LlJ9OKShZh7kIhU0flRZZnVbR6+08E+nbYBnY2nh0A7j43VCTV
9Nq8bOrEM/8EO/goUUvxhwirFHkKXkrXdcrPg1mU5Qeszyg19HhsxtXj1ZvTrcrkeOqjviRfVf84Z/ut2DaHQSH
LwX+63vISm+JYEkHJvi9xFPrP3tL8UyGEv33QfJZX6/T4/pj7y05lPuDs98TyrNg24mnFyos3UaDVhLf96oOvOf
OhIhdafdE9/oIQEZE66DqsvK9Dg9wcb8rJ2mZENO9Mo66F2pEmIYkpjkEIIOVGL2K/I8G6n4JegMo2nrnlyusGg
hqV9TrXFn6jpSoNuDj7hKmzU+F8PcdMksgKgimIjTp+va92ad1H4OTeyh7Giwr80iCoPMubcBYKPsltSawP/SMs
byfCCoA2ydjhFGdizZ5sKVN22mtoYZhWpzN/CpVZWCWbj29UOLWGmz264/GrsfbVB/9+jQFEpG5zyTch7p+2kt4
Jo+P2MlyFslnRNQ9nDn6xO9bCgyQfAbjv3mfz+sd6UpICCQicjpwAewnQoVdEgD5Hf6OOzOSuJdAu6Rb5j0QkRY
yO9ZG8okD1Uc3gFhx8HjuzY2rN7jiwpz35MAulByhF3ALKk5xJ6opHXG+WQ45Wz2K4/isrrHQ8LBul03DT9jd1E
rDKVOgfFpEUKp0GaTr1xRcGOTNu+aJrvXigq0dE/N3r9a0GmZjj4PxSBvD1/qD0rzbWMYjX5nSXEWGaNFI4xgrw
HIreOh91gI9Pm72nHHqE1/JYByI6jFFEJ9YBCQV+BL+SO/snXzemQHUQJhLAfrl9QiluqwrmCQ/iU+x8ai7gyTE
8WrXpDd9XZj84Z6dBd11FG+PCf5AyqAGgbD/dDd6mk6f/1J6u22IBOSWWjFCwb4PeAO4IiiIyUGmB50NrMlFP89
WqU7+8UiJ4mx/sSC9OdnQLRt8kRQK6z/7vFfNua9lw2VFFEAAAGEaUNDUElDQyBwcm9maWxlAAB4nH2RPUjDQBz
FX1NFkUoHO0hxyFCdLIiK6KZVKEKFUCu06mBy6Rc0aUhSXBwF14KDH4tVBxdnXR1cBUHwA8TRyUnRRUr8X1JoEe
PBcT/e3XvcvQOERoVpVtcYoOm2mU4mxGxuVex5RRBRhCFgRmaWMSdJKfiOr3sE+HoX51n+5/4c/WreYkBAJJ5lh
mkTbxBPbdoG533iCCvJKvE58ahJFyR+5Lri8RvnossCz4yYmfQ8cYRYLHaw0sGsZGrEk8QxVdMpX8h6rHLe4qxV
aqx1T/7CUF5fWeY6zSEksYglSBChoIYyKrARp1UnxUKa9hM+/qjrl8ilkKsMRo4FVKFBdv3gf/C7W6swMe4lhRJ
A94vjfAwDPbtAs+4438eO0zwBgs/Ald72VxvA9Cfp9bYWOwLC28DFdVtT9oDLHWDwyZBN2ZWCNIVCAXg/o2/KAQ
O3QN+a11trH6cPQIa6St0AB4fASJGy133e3dvZ279nWv39AHBscqZYVQhuAAANHGlUWHRYTUw6Y29tLmFkb2JlL
nhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6
eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNC40LjAtRXhpdjIiPgo
gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj
4KICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZ
S5jb20veGFwLzEuMC9tbS8iCiAgICB4bWxuczpzdEV2dD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NU
eXBlL1Jlc291cmNlRXZlbnQjIgogICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjE
vIgogICAgeG1sbnM6R0lNUD0iaHR0cDovL3d3dy5naW1wLm9yZy94bXAvIgogICAgeG1sbnM6dGlmZj0iaHR0cD
ovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwL
zEuMC8iCiAgIHhtcE1NOkRvY3VtZW50SUQ9ImdpbXA6ZG9jaWQ6Z2ltcDo1MDRkNTBlYi00MGEzLTQ0OTMtYWVk
Yi1mYWExMjU4Yzk3ODQiCiAgIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6ZDM0MWM1NzctOThlOS00OWZjLWF
jY2MtMzJjYzgxZDg0YWNjIgogICB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6YTY5NDI1OWEtN2
FiYi00YTBlLWJiMGYtNTYyY2M2ZmY1MTkyIgogICBkYzpGb3JtYXQ9ImltYWdlL3BuZyIKICAgR0lNUDpBUEk9I
jIuMCIKICAgR0lNUDpQbGF0Zm9ybT0iTWFjIE9TIgogICBHSU1QOlRpbWVTdGFtcD0iMTY0ODMzNzE4NTY2NzI1
MyIKICAgR0lNUDpWZXJzaW9uPSIyLjEwLjMwIgogICB0aWZmOk9yaWVudGF0aW9uPSIxIgogICB4bXA6Q3JlYXR
vclRvb2w9IkdJTVAgMi4xMCI+CiAgIDx4bXBNTTpIaXN0b3J5PgogICAgPHJkZjpTZXE+CiAgICAgPHJkZjpsaQ
ogICAgICBzdEV2dDphY3Rpb249InNhdmVkIgogICAgICBzdEV2dDpjaGFuZ2VkPSIvIgogICAgICBzdEV2dDppb
nN0YW5jZUlEPSJ4bXAuaWlkOmJhOGQwYzQwLTUzZTItNDc2Zi1iNDRjLTIwODU4YTI4MmEwMiIKICAgICAgc3RF
dnQ6c29mdHdhcmVBZ2VudD0iR2ltcCAyLjEwIChNYWMgT1MpIgogICAgICBzdEV2dDp3aGVuPSIyMDIyLTAzLTI
2VDE5OjI2OjI1LTA0OjAwIi8+CiAgICA8L3JkZjpTZXE+CiAgIDwveG1wTU06SGlzdG9yeT4KICA8L3JkZjpEZX
NjcmlwdGlvbj4KIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI
CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA
gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgIC
AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI
CAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICA
gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC
AgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI
CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA
gICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC
AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgI
CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA
gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC
AKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI
CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA
gICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC
AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgI
CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA
gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgIC
AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI
CAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICA
gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC
AgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI
CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA
gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAKPD94cG
Fja2V0IGVuZD0idyI/PmFBRUcAAAAGYktHRAD/AP8A/6C9p5MAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNR
QfmAxoXGhm54nj6AAAP10lEQVRo3rWZS4xk51XHf+d73Fu3qvo9noc9DztWJokzSuK8BAlkhRBECiKKUHYIxCIS
rwW7sMgiEpBlJIRYgECCBQ8hiBASCJFESLFCiBNPHJOMx57M2NMe90xPd1XX8977PQ6LW93joBiFZDhSS1WtW1X
fOd85//M//yO/9eXr2hYlIJQGrmxVXBh4mqQ8vVWyUVj2lhFjhPODHtbAIiSMCH1viVkRwBkhqzJuE6rwN987wB
phq7BEVfrecqbn2FtGCiOICIdN5N6iZdZGplFBlbxccvGlb/OBr3+Ryy9/E1/PyTGTkpKCEgNoAmMgJCEmxQ8tw
7ddILWZ+Xdvo1ExAkZAFbICAs5078WA81BUgovOI6qICFFhvw48uVawUVgaFUrvOWcs05CwBgojmMIRsmIFVDrH
Q1aKVRAqa7iyVWGNYEUwAl6EgTc0qQtYabvThOQwIpRO2Z/XbO3tcvm5rzL47jUOa2E9QGEz1grOCWUFmkGzUom
QsxDbRHPtFuX5bbbefZH5jT3iUUNWEB4EIqTuvWTICWJQXDYG6KLjjTBqE+M2cbbvCVk7h5zFiCB05gSslZPPLa
PijDALiYGzzGPi8kYPAaJ2QYuqAAx9pme6oIRsERHWi8z10YJyfMj571zFHh5Qb25ixzCfLogZXKEYC8aCGAGEF
DOoYJ1Bcia9fogMJqw9ukFet8TJgpwgpc5hzV0gYur8yBncyicE6FuhMMLtWculYcGat7Q5U1pD5QwrH06ePzYj
0kU4K5UTrMBGz3c/ssqurEodMxve0HeGRcxsl5Y1b3hhtGQ5nbF273VSSjS+pImZCmVx4THaoyOKuqHtnef5K+8
hVYb1u3Bpfocz46vYdoIkoW1gPo3I6IDBE1uUZ07R3rqDTZHVPQNCTkqKXVDcsStJwYlwqucxAneXkY3CMguZwm
QqZ77f6zeYN7Jy3qKqDJyjNAICqt2HlC5I26WjzYo3wtBbXhwvuT9dMkgBmxM4R1v1uf2uD/LScB2/nHPm9g1uy
6O882fHfPytf0QbPLPFOrujn+TLBz9Pvu/ZfiXzEy/8FdXQ0NSJ5csjwoWW/lNPMH/5Lu2dCdaB94p1IBa8Bwe6
uilYps7RM5UjKSxiPknfJik9+4Mj0AGOUJgHgZTVoyLfHygrQtJM3xlujZeMFw0Do0wWSwoRDp64zK33fohoLNV
kRK+p+felsJhW/Mrlf6D0E6oC6vhTPH52yfue/Guy7vH5L/8+734245zQ61t6fSWN54TFDYZveZRms2J27R5h0W
HXcRavMqCDySYrkzby1vWSygpN6mpbgJgVtfIDk0AAb44B503SBFag2L1+8XCOxEioG/ZHU2LVZ375Cq0YTIpIS
sy3T5HFsMyZb37pJl984RN89Onf42Bymo/95ccZa+LPP/p2PvzkH+BdoE2WGBNNnfBOcF7wSeHmHXobffzbtlnc
PiLOY+eHeQMGGAGDMA+ZSUicq0ra3N38dmmwqzp/M//e3O03ZMqq1F4+qpEQubd/yEgt66e2GSDoKtMm0TNPmZw
yNkVOn7vAuc3rfO4/38Kzd/6QZbD80v41/mPzXNcTgcc3RhzsPM3OvWdBILWKNGAUrFN8PccPatbOlsS5JUxa2l
pxsioBkQ6ty9XNZ4XNwtJmRVXx9odx8X+3OmVuzxtCiByFjD11ivPOUlohK9yrI3uLQI4RVQWULAY3XOcd77wI/
/Ui6epdvK5jnrrE53/my1zY+QKvHP4yR1c3+eDkWyTb5bMioJByF4xmqXAUKQaJ3k5Bdaait2hxXe0KPSuse8N2
z7HhLUZg4Cx9IP8YTq84CEmV+3UgKVjv2HKOvjMUtusus5iQVavtMKRzwMWW3mzK5qnTbLwzY05t8YXRef71E5+
mdDd55nu/y6t/X/ILt/4Us2bI2aNJyVlJKqgKKSo5ZFKTWU6V5byhf6FgcG4d1908rDnD2X7BhYHnXN+xWTi8Mf
hVz/5RTd7QKtd8xyce7ftVlnU11aaM0hEp6NppzhlQovMs1zZIzuHahv3ru3zk7JTS3eRgcppn//Esn3zh88Rjf
mAMrrQY7epbVsWuWDQrqc2EJhH2WmazIxzKitYaNgrLurcMncUbwRnBGR6KCTD0lspZ5iFRrL63zZmjVrk5a7k5
adhvEnXKXQob15WCCKHsEXoV96TPpaJZERlDlSKhBV+ANSCaaaYZW1pULDmvmrDpyJstHa40VDmjmnEIJ2nnDfS
s4FdcXU8S+OGYN4IHCtNxgWmIjNvELCQMUDnDIGWSdrxCUYxmXGjZPNznzO5NXjoYcdU+zmf/+Y8pbc2p1CACKQ
KiFKWh7BtimxFRisIR1ZERQkxozggCuevZLiu0WZnHTJOUpA9uTB6i8//TsioxK0aEyhkq/6DToIqLgeF0zOnRf
c7f2+X8rWts3rzO18IV/HDMa7YPpo9Zh7YFZzuqm1OmqMCXhpwhNgFfZlQs6jwI5BTRlNHsuwAsk3K/7nqjKFiB
0nYH+/+wY+JkRKhjZm8Z2ZsH6hhxsWV9OmFzb5cLr77EEze+S28yoRLhyDiOcuCTVyb84ns/C8DffeM3OHz+XWz
dfR5jwK6C4EqlrCy+Zwl1xnmQnEjisN4jTokhdDwgKcyTkpYRVqm47i2FNVTW/Fgg+Gad4TjL4mqSXKbMNGQWUX
EY6rVtDi9epiz7PHH9OdZfuspwOue9zZS/+PrH+Mg7fpZZs4XaIS8/+X5+Wm8SFzWpjuRWyUmJTaQcGHxlCU3GG
EEk0MxaTFHgygL51DOv6PFhrBHWneFc3/PUZo8rWxU7pedhJ4ICy5iZhsQ8ZG7MGm7PWm7PW0Ztos2rIUoVGwPr
4wPO7e9y6dWXGL3wLH9y7yzrW+fYmd7jLUe7/OrZxMbQklMi10vC0RFpOkfrgKD4nlAOLSl1/MAaIYSMWHPMBDs
6fOxnz3YdwRshqXZI+ZAcTx1LIa+mx1EbsSLErFigJ0AKSGwoQk1/dsRw/z79vTsMXrzG+Tt3+Nz4WzyytF2rLi
3pviUclpjBALc2oLi4SdZEms8Ih2PSdMbyKFAOLSJKjOC8BTE4kxPZ2JND9qywUVgMwjJmBs4+tJuXVRRCVmYhc
dQmDpvEzVlLyB0AzzOo9agYVAXTT2wND9nxM6qqobDKQHr4cUtbRqgyvkiIieT5kjgdgyuwwwF+rU9x6QI5J/Lk
iDQaIanBWaVdBowX3OOv3GDuC462T6GDAYJlHrt54LGBxz5kANAVK1ymxOvzhjvLxLiJHDSRsAKHpIooZLFkdRy
5LfYH5+BiYKCJjf2XMYctYarMjhKiCVcIZd/gy4RIS54tiFOHOI/p97CDPu7iebSpyYsFpZ9ST1ocyznWeWzORI
Q2d+1po7D0rCErpBVyy0NI/6RKmzuwWyRlMp5gjyYMs3C3WuuYhwgqQnAe40s22xY7nTB45TX6t3fpmQY/MOg6a
FTSUmmXSj1PLCepmwIrQ1ElRAIslujiCDUOegVmMITtbarhIe704X2ee/IdNGUPUWG5oqiLmBm38UQK86tB6Ue1
lKHJmTpmDpvIfh25WycObMlkbZtydsTFg11SSMyHA4IrqX1F9AUHjzzKzv07bKQFmpXYQEJQI2hWULBFRswDwTS
nzHyUcT3BO0GswUiEukXrORiH9Ie4b77vw7Rl74TxicAsJG7NWnqmA6fNwlFa+yPzwmPAm6/q/l4d2Z23jOrQKc
w5EXoVd33RqUIKWQyimWq55OzuLd7+3FdY2/0eLrbEoKuJTxGxiDGoSYhNiHb5Zr3BFt0zGO1GuqydIioCKaGzF
hd6vQcgtVJPF3VDDgtec1tMo+tESSMMvMX9HyOQVs4vUye27i0D+3Vk0kbmsVMpj8HRAmIcohnT1rjQUk1nXPrO
1ykXR2hV0Y4C2nQHTUkQyRiTMaY7o7Mg2t24LYtOC5Tud05osCraBppFfqAJmhTpL+ecHR+wMxtx5+kPMJ4HTmc
4W7kTZeiHHX+1y0ziClPqFbDebxK785ZZSETtZHVRTkRVL4rJqWOlKbFx5xauXqDzhpSFqrQQhVivlF7Amk6zyB
mCEZxVSmOw2XUyMgKiiNWT4V6cwVfgyvmUc3fv8OS3vkZ/Mmb8ng/yjfd/mCKBTZnSdMA4biKbhaPnzInW/n0Ov
8FpWY20x9PetE0sUz4BwZS7BUqdu2eLlIjzBUYzXiNrzYKdvV12bl7n7PUXGO7vUqaGgkBZWXRYoDkSY+xG3HSs
OYBRhaTEtkUmbTcFeoP1DlM4XFVifIExDpsF93N/+2ecefYZ2vVNrv7a7/D85acwK9W2jplXZg2LmHnfTsXGaiF
yvAk6/tGoHXCGpBRWuv/lfFL7h03ifhPJ2pGt0hp61tCkhI2BcjJifXSAFeH8nVuce/VlhospVWgYTA9hMsdIQj
1Iv4fpVRTrJdIoYbZEZ3NyG0ghIxZsCQRQVVS6/UEKLbJsaaZzjBPs0OLXPe6xZ75E2D7FV3/901y7+CSy0v3ql
FlEWGbl8nqPDDQp066WCwNvaVI+4fPz2L3uY07S/VgIOWgj91fILysafLwwMSRaFVQc1guLwRBLwk7H1Blsv485
/QjlaJ+4jMzqObaaYyuHLdZgbYjubKMxUCwm6HhEVKgGghe7ynhB1ZDVoCKrvZqQRoLzO1v8229/hhfPP36S0Fm
h0W4DdLbnWKZMnZRxG1kmZad01HXoKOzq9qchY1dcYRIS9+sO5DaLjljdryOjOjJPmbRifTErJib6Omcj3Oeof5
bnn7jC7a0zfOiZf2Fz7w5TP2TDLqkeTagpyJOAthlMA3UDoyMyJbbvsS5j1jyEQAiZkDJOhcIbnOsuNqt0fxhUH
O6ffvMz3Hjs0htA7LiQhaEzLEJiFjOjJnLYwEZheX3RUqyEzMJ0IuqoTfhjvGgT0zbx2rxlVnnmMTMPHQ4so56I
HZKV6EoWgzPs+Z2uI1jD0XCDg9OPcuH6VQa7r6OaWThwGy3FpmCdYnpgvaIh0N5L5BoI3RQoqVOg1QhtUvIyYUh
YJ/jC4FzqVmvJ4G6dvYCKYFJCRVBjUMALhJRZSrfGuj0P9Jxhutr/daCXKW2nHI/aRFJl6AzLpEyXDaN5w7iJYE
wXhKREVZIqK60KmxK90MJiztZ0zHo9w2mkFOgNhwx3DKnOtNNMvCc0BxkpACvkKYgHKXK3hN2GYg2sAxNB5pBbQ
yBjgpJaWLQJ2ya8NxgD8qmv3NJevYCs1IPhAzVIhBKlX1h6RhhYwTtLn0xZeKYhsS4ZdZ5F6rpEWm2GoyqL2QK3
XDByPcqqZNppnF3r04yETntwsWXj3uucv/5tHrl9g9Cr0KJkOD7ADip6BJ549Rprh3vkuiU03Zo8rza8x7FcEcI
Odyy4CnwFZWlwA0MeZoyCOsgOZAG6VP4bKfFvl4YdbjEAAAAASUVORK5CYII=
"""
