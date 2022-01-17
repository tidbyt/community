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
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

NUM_POKEMON = 386
POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon/{}"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

def main():
    id_ = int(NUM_POKEMON * random()) + 1
    pokemon = get_pokemon(id_)
    name = pokemon["name"].title()
    height = str(pokemon["height"] / 10) + "m"
    weight = str(pokemon["weight"] / 10) + "kg"
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

def random():
    """Return a pseudo-random number in [0, 1)"""
    return time.now().nanosecond / (1000 * 1000 * 1000)

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

    cache.set(key, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)

    return res.body()
