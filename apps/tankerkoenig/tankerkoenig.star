load("render.star", "render")
load("schema.star", "schema")

TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64

GAS_TYPES = {
    "e5": "Super",
    "e10": "Super E10",
    "diesel": "Diesel",
}

def format_text(text):
    return text.replace("ß", "ss")

def main(config):
    selected_type = config.str("gas_type")
    selected_type = "diesel"

    results = [
        ["Anne-Walter-Straße 8", 1.109],
        ["Hauptstraße 1", 1.1],
        ["Johann-Georg-Halske-Straße 1", 1.34],
    ]

    return render.Root(
        render.Column(
            [
                render.Text(
                    GAS_TYPES[selected_type],
                ),
                render.Box(
                    width = TIDBYT_WIDTH,
                    height = 1,
                    color = "#ffffff",
                ),
                render.Column(
                    [
                        render.Padding(
                            render.Row(
                                [
                                    render.Marquee(
                                        render.Text(
                                            format_text(result[0]),
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                        scroll_direction = "horizontal",
                                        width = 40,
                                    ),
                                    render.Padding(
                                        render.Text(
                                            str(result[1]) + "€",
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                        pad = (3, 0, 0, 0),
                                    ),
                                ],
                                expanded = True,
                            ),
                            pad = 1,
                        )
                        for result in results
                    ],
                ),
            ],
        ),
    )


def get_schema():
    options = [
        schema.Option(
            display = gas_type[1],
            value = gas_type[0],
        )
        for gas_type in GAS_TYPES.items()
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "gas_type",
                name = "Gas Type",
                desc = "The type of gas you want to see prices for",
                icon = "gasPump",
                default = options[0].value,
                options = options,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display nearby gas prices.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "Tankerkönig API Key",
                desc = "API key for the Tankerkönig API (Request from creativecommons.tankerkoenig.de)",
                icon = "key",
            ),
        ],
    )
