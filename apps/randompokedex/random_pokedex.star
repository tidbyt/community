"""
Applet: Random Pokedex
Summary: Random Pokedex entry
Description: Display a random Pokemon along with its typing and optional shiny version.
Author: Kerry Bassett
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

NUM_POKEMON = 1010
POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon/{}"
SPRITE_URL = "https://img.pokemondb.net/sprites/home/normal/"
SHINY_SPRITE_URL = "https://img.pokemondb.net/sprites/home/shiny/"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.

TYPE_COLORS = {
    "normal": "#AA9",
    "fire": "#F40",
    "water": "#39F",
    "electric": "#FC3",
    "grass": "#7C5",
    "ice": "#6CF",
    "fighting": "#B54",
    "poison": "#A59",
    "ground": "#DB5",
    "flying": "#89F",
    "psychic": "#F59",
    "bug": "#AB2",
    "rock": "#BA6",
    "ghost": "#66B",
    "dragon": "#76E",
    "dark": "#754",
    "steel": "#AAB",
    "fairy": "#E9E",
    "": "#000",
}

def main(config):
    random.seed(time.now().unix // 15)
    id_ = random.number(1, NUM_POKEMON)
    pokemon = get_pokemon(id_)
    name = pokemon["name"].title()
    type1 = pokemon["types"][0]["type"]["name"].lower()
    type2 = ""
    numTypes = len(pokemon["types"])
    sprite_url = SPRITE_URL + name.lower() + ".png"
    shiny_sprite_url = SHINY_SPRITE_URL + name.lower() + ".png"

    if numTypes > 1:
        type2 = pokemon["types"][1]["type"]["name"].lower()

    if sprite_url == None or shiny_sprite_url == None:
        return []

    normal_sprite = get_cachable_data(sprite_url)
    shiny_sprite = get_cachable_data(shiny_sprite_url)

    if config.bool("shiny", False):
        sprite = shiny_sprite
    else:
        sprite = normal_sprite

    return render.Root(
        max_age = 5,
        child = render.Stack(
            children = [
                render.Row(
                    # Pokemon image
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Box(width = 43),
                        render.Column(
                            children = [
                                render.Box(height = 10),
                                render.Image(
                                    src = sprite,
                                    width = 20,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Column(
                    main_align = "space_between",
                    expanded = True,
                    children = [
                        render.Box(
                            # Pokemon name
                            width = 64,
                            height = 10,
                            color = config.str("titleBackground", "#999"),
                            child = render.Marquee(
                                scroll_direction = "horizontal",
                                width = 60,
                                child = render.Text(
                                    content = "# " + str(id_) + " | " + name.upper(),
                                    color = config.str("titleForeground", "#000"),
                                ),
                            ),
                        ),
                        render.Box(
                            # Pokemon type 1
                            width = 42,
                            height = 10,
                            padding = 1,
                            color = TYPE_COLORS[type1],
                            child = render.Text(
                                content = type1.upper(),
                                color = "#000",
                                font = "CG-pixel-3x5-mono",
                            ),
                        ),
                        render.Box(
                            # Pokemon type 2
                            width = 42,
                            height = 10,
                            padding = 1,
                            color = TYPE_COLORS[type2],
                            child = render.Text(
                                content = type2.upper(),
                                color = "#000",
                                font = "CG-pixel-3x5-mono",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "titleBackground",
                name = "Title Background",
                desc = "Color of title background.",
                icon = "brush",
                default = "#999",
            ),
            schema.Color(
                id = "titleForeground",
                name = "Title Foreground",
                desc = "Color of title foreground.",
                icon = "brush",
                default = "#FFF",
            ),
            schema.Toggle(
                id = "shiny",
                name = "Shiny Pokemon",
                desc = "Show shiny variant of Pokemon",
                icon = "star",
                default = False,
            ),
        ],
    )

def get_pokemon(id):
    url = POKEAPI_URL.format(id)
    data = get_cachable_data(url)
    return json.decode(data)

def get_cachable_data(url):
    res = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
