"""
Applet: Reddit Images
Summary: Shuffle Subreddit Images
Description: Description: Show a random image post from a custom list of subreddits (up to 10) and/or a list of default subreddits. Use the ID displayed to access the post on a computer, at http://www.reddit.com/{id}. All fields are optional.
Author: Nicole Brooks
"""

load("render.star", "render")
load("schema.star", "schema")

def main(config):
    return render.Root(
        child = render.Box(height = 1, width = 1),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )