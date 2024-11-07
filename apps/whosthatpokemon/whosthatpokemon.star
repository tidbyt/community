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
load("re.star", "re")

ALL_POKEMON =1025
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
    shinyOdds = getShinyOdds(config)
    isShiny = False if shinyOdds == 0 else random.number(0, shinyOdds - 1) == 0

    if pokemon == None:
        return []

    sprite_url = pokemon["sprites"]["front_shiny"] if (isShiny and "front_shiny" in pokemon["sprites"].keys()) else pokemon["sprites"]["front_default"]

    # Variables that will be used by the render.
    name = formatName(pokemon["name"])
    revealedImage = getCachedImage(sprite_url)
    silhouette = getCachedImage(IMGIX_URL.format(chosenId))
    bg = base64.decode(BACKGROUND)

    shinyAnimationFrames = [base64.decode(shiny_frame) for shiny_frame in SHINY_ANIMATION_FRAMES] if isShiny else []

    # If something went wrong with the API, skip the app completely.
    if revealedImage == None or silhouette == None:
        return []

    frames = compileFrames(name, silhouette, revealedImage, shinyAnimationFrames, speed)
    print("The game is afoot. The secret Pokemon is: " + name)

    return render.Root(
        delay = 25,
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

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(key, base64.encode(res.body()), CACHE_TTL_SECONDS)
    return res.body()

# Formats all names. Removes all hyphens that don't belong for forms and spaces.
# Also capitalizes appropriately.
def formatName(name):
    namesWithSpaces = ["mr-mime", "mime-jr", "type-null", "tapu-koko", "tapu-lele", "tapu-bulu", "tapu-fini", "mr-rime", "great-tusk", "scream-tail", "brute-bonnet", "flutter-mane", "slither-wing", "sandy-shocks", "iron-treads", "iron-bundle", "iron-hands", "iron-jugulis", "iron-moth", "iron-thorns", "roaring-moon", "iron-valiant", "walking-wake", "iron-leaves"]
    namesWithHyphens = ["ho-oh", "porygon-z", "jangmo-o", "hakamo-o", "kommo-o", "wo-chien", "chien-pao", "chi-yu"]
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
        print("Failed to pull pokemon image: " + str(res.status_code))
        return None

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
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

# Returns the shiny odds.
def getShinyOdds(config):
    shinyOdds = config.get("shiny_odds", "0")
    if not isParsableInteger(shinyOdds):
        fail("The shiny odds must be a positive whole number or 0 if you do not want any shiny pokemon")
    return int(shinyOdds)

def isParsableInteger(maybe_number):
    return not re.findall("[^0-9]", maybe_number)

# Gets all frames needed for the animation.
def compileFrames(name, silhouette, revealedImage, shinyAnimationFrames, speed):
    frames = []
    frameCount = int(speed * 40)
    startTransition = frameCount / 2 - 20
    endTransition = frameCount / 2 + 20
    transitionFrame = 0
    for frame in range(1, frameCount):
        shiny_frame = getShinyFrame(shinyAnimationFrames, frame, endTransition)
        if frame < startTransition:
            frames.append(fullLayoutHidden(silhouette, 30, shiny_frame))
        elif frame >= endTransition:
            frames.append(fullLayoutRevealed(revealedImage, 30, name, shiny_frame))
        else:
            # if it's transitioning, get transition width
            width = getTransitionWidth(transitionFrame)
            if transitionFrame > 3:
                frames.append(fullLayoutRevealed(revealedImage, width, name, shiny_frame))
            else:
                frames.append(fullLayoutHidden(silhouette, width, shiny_frame))
            transitionFrame += 1

    return frames

def getShinyFrame(shinyAnimationFrames, frameIndex, endTransitionFrame):
    # How many frames after the end of the transition animation to start displaying the shiny animation
    # This can be a negative number if we want the shiny animation to start while the sprite is "flipping"
    post_transition_animation_offset = 50
    shinyFrameIndex = int(endTransitionFrame + post_transition_animation_offset - frameIndex)
    if shinyFrameIndex >= 0 and shinyFrameIndex < len(shinyAnimationFrames):
        return render.Image(
            src = shinyAnimationFrames[shinyFrameIndex],
            width = 25,
            height = 25,
        )
    else:
        return render.Box()
        

# Layout function with text on side.
def fullLayoutHidden(image, width, shiny_frame):
    return render.Stack(
        children = [
            render.Stack(
                children=[
                    render.Box(
                        width = 38,
                        child=render.Image(
                            src = image,
                            width = width,
                            height = 30,
                        )
                    ),
                    render.Box(
                        width=38,
                        child=shiny_frame
                    )
                ]
            ),
            render.Padding(
                pad=(30, 0, 0, 0),
                child=render.Box(
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
            )
            
        ],
    )

# Layout function with text on bottom.
def fullLayoutRevealed(image, width, text, shiny_frame):
    return render.Stack(
        children = [
            render.Stack(
                children=[
                    render.Box(
                        width = 38,
                        child=render.Image(
                            src = image,
                            width = width,
                            height = 30,
                        )
                    ),
                    render.Box(
                        width=38,
                        child=shiny_frame
                    )
                ]
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
    widths = [18, 18, 18, 18, 18, 12, 12, 12, 12, 12, 6, 6, 6, 6, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 6, 6, 6, 6, 6, 12, 12, 12, 12, 12, 18, 18, 18, 18, 18]
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
                id = "shiny_odds",
                name = "Shiny odds",
                desc = "Odds of a shiny Pokemon appearing. By default, no shiny Pokemon will appear",
                icon = "star",
                default = "0",
                options = [
                    schema.Option(
                        display = "None",
                        value = "0",
                    ),
                    schema.Option(
                        display = "Guaranteed shiny",
                        value = "1",
                    ),
                    schema.Option(
                        display = "Very common (1/16)",
                        value = "16",
                    ),
                    schema.Option(
                        display = "Common (1/64)",
                        value = "64",
                    ),
                    schema.Option(
                        display = "Rare (1/256)",
                        value = "256",
                    ),
                    schema.Option(
                        display = "Super rare (1/2048)",
                        value = "2048",
                    ),
                    schema.Option(
                        display = "Full odds (1/8192)",
                        value = "8192",
                    ),
                ],
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
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
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
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
"""

SHINY_ANIMATION_FRAMES = [
  "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"
]
