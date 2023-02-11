"""
Applet: PB Jelly Time
Summary: Banana Dancing
Description: The Peanut Butter Jelly Time Dancing Banana.
Author: jay-medina
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_SPEED = 80

def main(config):
    speed = config.get("speed", DEFAULT_SPEED)
    banana = get_banana()

    return render.Root(
        delay = int(speed),
        child = render.Image(base64.decode(banana)),
    )

def get_banana():
    return """
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
s=
"""

def get_schema():
    options = [
        schema.Option(
            display = "Normal",
            value = "100",
        ),
        schema.Option(
            display = "Fast",
            value = "80",
        ),
        schema.Option(
            display = "Fastest",
            value = "65",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Dance Speed",
                desc = "The speed in which the banana dances",
                icon = "bolt",
                default = options[1].value,
                options = options,
            ),
        ],
    )
