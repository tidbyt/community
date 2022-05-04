# Simple National Pokédex
Display a random Pokémon with its name and dex number from Generations I - VII (Kanto through Alola). 

<p align="center">
  <img src="natdex.gif" alt="animated" />
</p>

## Features
- Dropdown menu in app settings allows you to choose random Pokémon based on region (Kanto, Johto, etc.)
- Default set to National Dex (all Gen I - VIII, range from 1 to 809)

### Feature Ideas

- Add functionality for Gen VIII (Galar) 
  - Issue: sprites pulled from API are of a different size in Gen VIII

## Shout Outs
Thanks to Kay Savetz ([@savetz](https://github.com/savetz)) for the idea of pulling from [random.org](random.org) for random number generation in the absence of a `random()` function in Starlark.

Credit to Max Timkovich ([@mtimkovich](https://github.com/mtimkovich)) for originally developing the code to pull from the [Pokemon API](https://pokeapi.co/).




