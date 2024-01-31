"""
Applet: Melbourne Trains
Summary: Melbourne Train Departures
Description: Real time train departures for your preferred station in Melbourne, Australia.
Author: bendiep
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
