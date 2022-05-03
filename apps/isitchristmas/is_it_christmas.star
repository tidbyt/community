"""
Applet: Is It Christmas
Summary: Is it christmas: yes/no
Description: Is it christmas: yes/no.
Author: Austin Fonacier
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

TREE_IMG_NO_LIGHTS = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAExJREFUKFNjZMACfNYH/N8SuIERXQpDAKQQpghdA/mKkU3FZjqKyUQrxqYQ3XS4yUQrxqcQ2XSwySQpRg/8ylCP/+2rdxCOFJBGXIoBe08sDMFoReYAAAAASUVORK5CYII=
""")

TREE_IMG_1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAGtJREFUKFNjZMACfNYH/N8SuIERXQpDAKQQpghdA/mKkU2dmy/MkDzxLQOy6SgmIyvG5hS4YmwK0TVgKIZZv/nlBgZf8QCwephTwIrxmYpsOopiZNNgipA9ihF0IEWVoR7/21fvIBwp+BQDAKXIOwz136MKAAAAAElFTkSuQmCC
""")

TREE_IMG_2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAHRJREFUKFNjZMACfNYH/N8SuIERXQpDAKQQpghdA4biOeob/m/oWABWj1cxiqm8LQw+n2tQNKCYjKwYm1PgirEpRNeAoXgL1PqAigQGdLeDFYNMRZbEFpwgz8IVY1UAtQUWMhhBB5KoDPX43756B+FIwacYADxMPQxwP73/AAAAAElFTkSuQmCC
""")
TREE_IMG_3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAIRJREFUKFNjZMACfNYH/N8SuIERXQpDAKQQpghdA4biOeob/m/oWABWj1cxsqlz84UZkie+RdGAYjKyYmxOgSvGphBdA4ZimPWbX25g8BUPQHE7WDHI1ICKBAaYx7AFJ8izcMUgBcimgUODt4XhZVI/3KMYQQdSVBnq8b999Q7CkYJPMQBqdkIMUVjCigAAAABJRU5ErkJggg==
""")

TREE_IMG_4 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAIlJREFUKFNjZMACfNYH/N8SuIERXQpDAKQQpghdA1bFW3hbGP7zhTAwmt1AkUfhIJuKzXQMxZulbzD4PtWAOxfZKXDFKG7lbWHw+VzDANMI04CieLPQdgbfd54Y4YOiGJtbQTpAHgXZAGYHbmAEmwxTjCyJbgtcMbq9laEe/9tX7yAcKSCNuBQDAG5kQwwkXuh1AAAAAElFTkSuQmCC
""")

DEFAULT_LOCATION = {
    "lat": 34.0522,
    "lng": -118.2437,
    "locality": "Los Angeles",
    "timezone": "US/Pacific",
}

CHRISTMAS_GREEN = "#1E792C"
CHRISTMAS_RED = "#C30F16"
CHRISTMAS_YES = "Yes!"
CHRISTMAS_NO = "No"

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    day = now.day
    month = now.month

    if day == 25 and month == 12:
        is_christmas = CHRISTMAS_YES
    else:
        is_christmas = CHRISTMAS_NO
    print(is_christmas)

    return render.Root(
        delay = 500,
        child = render.Column(
            expanded = True,
            children = [
                render.Box(
                    height = 8,
                    child = render.Text("Is It", font = "tb-8", color = CHRISTMAS_GREEN),
                ),
                render.Box(
                    height = 8,
                    child = render.Text("Christmas?", font = "tb-8", color = CHRISTMAS_GREEN),
                ),
                render.Box(
                    height = 4,
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Animation(
                            children = get_tree_frames(is_christmas),
                        ),
                        render.Box(
                            height = 15,
                            width = 20,
                            child = is_christmas_text(is_christmas),
                        ),
                        render.Animation(
                            children = get_tree_frames(is_christmas),
                        ),
                    ],
                ),
            ],
        ),
    )

def is_christmas_text(is_christmas):
    color = CHRISTMAS_RED
    if is_christmas == CHRISTMAS_YES:
        color = CHRISTMAS_GREEN
    return render.Text(is_christmas, color = color)

def get_tree_frames(is_christmas):
    if is_christmas == CHRISTMAS_YES:
        return [
            render.Image(
                src = TREE_IMG_1,
                width = 11,
                height = 12,
            ),
            render.Image(
                src = TREE_IMG_2,
                width = 11,
                height = 12,
            ),
            render.Image(
                src = TREE_IMG_3,
                width = 11,
                height = 12,
            ),
            render.Image(
                src = TREE_IMG_4,
                width = 11,
                height = 12,
            ),
        ]
    else:
        return [
            render.Image(
                src = TREE_IMG_NO_LIGHTS,
                width = 11,
                height = 12,
            ),
        ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "place",
            ),
        ],
    )
