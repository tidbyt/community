"""
Applet: Weight Gurus
Summary: Displays recent weigh-ins
Description: Displays the most recent weigh-ins from your Weight Gurus scale.
Author: grantmd
"""

load("render.star", "render")
load("schema.star", "schema")

DEFAULT_WHO = "world"

def main(config):
    who = config.str("who", DEFAULT_WHO)
    message = "Hello, {}!".format(who)
    return render.Root(
        child = render.Text(message),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "who",
                name = "Who?",
                desc = "Who to say hello to.",
                icon = "user",
            ),
        ],
    )
