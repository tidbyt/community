"""
Applet: LOL Stats
Summary: Shows LOL summoner stats
Description: Displays League of Legends summoner wins/loss status, rank and recent match kda, champ, gold and minions. Also lists win/losses sequence of the most recent matches.
Author: thiagoss
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
