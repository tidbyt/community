"""
Applet: Vidiots Calendar
Summary: Showtimes for Vidiots (LA)
Description: Movie showtimes for the next 7 days at Vidiots in Los Angeles, CA.
Author: Buzz Andersen
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
