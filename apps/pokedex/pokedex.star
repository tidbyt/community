"""
Applet: Pokedex
Summary: Display a random Pokemon
Description: Display a random Pokemon along with its height and weight.
Author: Mack Ward
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

NUM_POKEMON = 386
POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon/{}"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "metric",
                name = "Use metric units",
                desc = "Which measurement system to use.",
                icon = "ruler",
                default = True,
            ),
        ],
    )

def main(config):
    id_ = random.number(1, NUM_POKEMON)
    pokemon = get_pokemon(id_)
    name = pokemon["name"].title()
    height = pokemon["height"] / 10
    weight = pokemon["weight"] / 10

    if config.bool("metric"):
        height = "%s m" % height
        weight = "%s kg" % weight
    else:
        height = "%s ft" % round(height * 3.281)
        weight = "%s lbs" % round(weight * 2.205)

    sprite_url = pokemon["sprites"]["versions"]["generation-vii"]["icons"]["front_default"]
    sprite = get_cachable_data(sprite_url)
    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    children = [
                        render.Box(width = 32),
                        render.Box(render.Image(sprite)),
                    ],
                ),
                render.Column(
                    children = [
                        render.Text(name),
                        render.Text("# " + str(id_)),
                        render.Text(height),
                        render.Text(weight),
                    ],
                ),
            ],
        ),
    )

def round(num):
    """Rounds floats to a single decimal place."""
    return float(int(num * 10) / 10)

def get_pokemon(id):
    url = POKEAPI_URL.format(id)
    data = get_cachable_data(url)
    return json.decode(data)

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = ttl_seconds)

    return res.body()
