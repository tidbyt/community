load("render.star", "render")
load("schema.star", "schema")

colorOpt = [
    schema.Option(
        display = "Red",
        value = "#FF0000",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FFFF00",
    ),
    schema.Option(
        display = "Green",
        value = "#008000",
    ),
    schema.Option(
        display = "Blue",
        value = "#0000FF",
    ),
    schema.Option(
        display = "Indigo",
        value = "#4B0082",
    ),
    schema.Option(
        display = "Violet",
        value = "#EE82EE",
    ),
]
default_beers_on_tap = [
    {"name": "1", "type": "NEIPA", "ABV": "2.2%", "ABVColor": "#ffa500"},
    {"name": "2", "type": "Water", "ABV": "0%", "ABVColor": "#0000ff"},
    {"name": "3", "type": "Porter", "ABV": "6.2%", "ABVColor": "#ff0000"},
    {"name": "4", "type": "Porter", "ABV": "6.2%", "ABVColor": "#ff0000"},
]

def main(config):
    return render.Root(
        render.Row(
            children = [
                render.Column(
                    children = [
                        render.Text("Tap List", font = "tom-thumb", color = "#7695f5"),
                        render.Text("", height = 2),
                        render.Text(
                            "%s" % config.get("beer1Type", ""),
                            font = "CG-pixel-3x5-mono",
                            color = config.get("beer1Color", ""),
                        ),
                        render.Text(
                            "%s" % config.str("beer2Type", ""),
                            font = "CG-pixel-3x5-mono",
                            color = config.get("beer2Color", ""),
                        ),
                        render.Text(
                            "%s" % config.str("beer3Type", ""),
                            font = "CG-pixel-3x5-mono",
                            color = config.get("beer3Color", ""),
                        ),
                        render.Text(
                            "%s" % config.str("beer4Type", ""),
                            font = "CG-pixel-3x5-mono",
                            color = config.get("beer4Color", ""),
                        ),
                    ],
                ),
                render.Column(
                    children = [
                        render.Text("", font = "tom-thumb", color = "#7695f5"),
                        render.Text("", height = 2),
                        render.Text(
                            "%s" % config.get("beer1ABV", ""),
                            font = "CG-pixel-3x5-mono",
                            color = config.get("beer1Color", ""),
                        ),
                        render.Text(
                            "%s" % config.str("beer2ABV", ""),
                            font = "CG-pixel-3x5-mono",
                            color = config.get("beer2Color", ""),
                        ),
                        render.Text(
                            "%s" % config.str("beer3ABV", ""),
                            font = "CG-pixel-3x5-mono",
                            color = config.get("beer3Color", ""),
                        ),
                        render.Text(
                            "%s" % config.str("beer4ABV", ""),
                            font = "CG-pixel-3x5-mono",
                            color = config.get("beer4Color", ""),
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
            schema.Dropdown(
                id = "beer1Color",
                name = "Beer1Color",
                desc = "Color of beer 1.",
                icon = "brush",
                default = colorOpt[3].value,
                options = colorOpt,
            ),
            schema.Text(
                id = "beer1Type",
                name = "Beer1Type",
                desc = "The type of beer 1.",
                icon = "beerMugEmpty",
            ),
            schema.Text(
                id = "beer1ABV",
                name = "Beer1ABV",
                desc = "ABV of Beer 1",
                icon = "percent",
            ),
            schema.Dropdown(
                id = "beer2Color",
                name = "Beer2Color",
                desc = "Color of beer 2.",
                icon = "brush",
                default = colorOpt[3].value,
                options = colorOpt,
            ),
            schema.Text(
                id = "beer2Type",
                name = "Beer2Type",
                desc = "The type of beer 2.",
                icon = "beerMugEmpty",
            ),
            schema.Text(
                id = "beer2ABV",
                name = "Beer2ABV",
                desc = "ABV of Beer 2",
                icon = "percent",
            ),
            schema.Dropdown(
                id = "beer3Color",
                name = "Beer3Color",
                desc = "Color of beer 3.",
                icon = "brush",
                default = colorOpt[3].value,
                options = colorOpt,
            ),
            schema.Text(
                id = "beer3Type",
                name = "Beer3Type",
                desc = "The type of beer 3.",
                icon = "beerMugEmpty",
            ),
            schema.Text(
                id = "beer3ABV",
                name = "Beer3ABV",
                desc = "ABV of Beer 3",
                icon = "percent",
            ),
            schema.Dropdown(
                id = "beer4Color",
                name = "Beer4Color",
                desc = "Color of beer 4.",
                icon = "brush",
                default = colorOpt[3].value,
                options = colorOpt,
            ),
            schema.Text(
                id = "beer4Type",
                name = "Beer4Type",
                desc = "The type of beer 4.",
                icon = "beerMugEmpty",
            ),
            schema.Text(
                id = "beer4ABV",
                name = "Beer4ABV",
                desc = "ABV of Beer 4",
                icon = "percent",
            ),
        ],
    )
