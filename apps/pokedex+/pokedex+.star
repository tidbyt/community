"""
Applet: Pokedex+
Summary: Pokemon Pokedex
Description: Displays a random Pokedex entry from any generation. This includes its name, image, number, and a scrolling PokeDex entry description. Customizable font color and background color allows users to customize the app to their liking.
Author: Forrest Syrett
"""

load("http.star", "http")
load("render.star", "render")
load("random.star", "random")
load("encoding/base64.star", "base64")
load("schema.star", "schema")


DEFAULT_COLOR = "#000024"
DEFAULT_FONT_COLOR = "#FFFFFF"

def main(config):

    bgColor = config.str("bgColor", DEFAULT_COLOR)
    fontColor = config.str("fontColor", DEFAULT_FONT_COLOR)
    
    imageHeight = 32
    imageWidth = 32

    # Generate a random Pokémon ID between 1 and 898
    # random_pokemon_id = str(3)
    random_pokemon_id = str(random.number(0, 898))

    # Make an HTTP GET request to fetch the Pokémon information
    POKEMON_API = "https://pokeapi.co/api/v2/pokemon/" + random_pokemon_id
    response = http.get(POKEMON_API)
    if response.status_code != 200:
        fail("Pokemon API returned an error", response.status_code)
    
    spriteURL = response.json()["sprites"]["versions"]["generation-v"]["black-white"]["animated"]["front_default"]
    if spriteURL == None:
        spriteURL = response.json()["sprites"]["front_default"]
    else:
        imageHeight = 16
        imageWidth = 16
    
    # Make a request to fetch the Pokémon sprite image
    sprite_response = http.get(spriteURL)
    if sprite_response.status_code != 200:
         fail("Sprite GET returned an error", sprite_response.status_code)
    
    POKEMON_SPECIES_API = "https://pokeapi.co/api/v2/pokemon-species/" + random_pokemon_id
    speciesResponse = http.get(POKEMON_SPECIES_API)
    if speciesResponse.status_code != 200:
        fail("Pokemon Species API returned an error", speciesResponse.status_code)
    
    should_continue = True
    pokemonRawFlavorText = "flavorText"
    for flavor_entry in speciesResponse.json()["flavor_text_entries"]:
        if should_continue:
         if flavor_entry["language"]["name"] == "en":
            pokemonRawFlavorText = flavor_entry["flavor_text"]
            should_continue = False 
            
    pokemonName = response.json()["name"].capitalize()
    pokemonSprite = sprite_response.body()
    pokemonFlavorText = pokemonRawFlavorText.replace("\n", " ")
    
    # print(str(sprite_response))

    return render.Root(
        child = render.Box(
        child = render.Stack(
            children = [
               render.Column(
                children = [
                render.Marquee(width=64,child=render.Text(pokemonName, font="tb-8", color=fontColor)),
                render.Text("#" + random_pokemon_id, font="6x13", color=fontColor),
                ],
                expanded=True,
                main_align="start"
             ),
             render.Column(
             children = [
               render.Marquee(
                child = render.Text(pokemonFlavorText, font="5x8", color=fontColor), width=64,offset_start=32,offset_end=64)
             ],
             expanded=True,
             main_align="end"
             ),
                render.Row(
             children = [
                 render.Box(width=28,height=32), # used for padding
                render.Box(child = render.Image(src=pokemonSprite, width=imageWidth, height=imageHeight),width=30,height=30, padding=0),
                ],
                expanded=True,
                main_align="end" 
                ),
            ],
        ),
        padding=1,
         color=bgColor 
        ),
        show_full_animation=True
    )
    
    def get_schema():
        return schema.Schema(
            version = "1",
            fields = [
                schema.Color(
                    id = "bgColor",
                    name = "Background Color",
                    desc = "The background color of your Pokédex",
                    icon = "brush",
                    default = DEFAULT_COLOR,
                    palette = [
                    "#000019",
                    "#24000D",
                    "#000000"
                    ]
                ),
                schema.Color(
                id = "fontColor",
                name = "Font Color",
                desc = "The font color of your Pokédex",
                icon = "brush",
                default = DEFAULT_FONT_COLOR,
                palette = [
                "#FFFFFF",
                "#FECA1C"
                ]
               ),
            ],
        )