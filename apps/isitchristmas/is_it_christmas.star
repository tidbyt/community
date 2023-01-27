"""
Applet: Is It Christmas
Summary: Is it christmas: yes/no
Description: Is it christmas: yes/no.
Author: Austin Fonacier
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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

    christmas_date = config.get("christmas_date", "12-25")
    christmas_month = int(christmas_date[:2])
    christmas_day = int(christmas_date[3:])

    if config.bool("december_only", False) and not is_christmas_runup(month, christmas_month):
        return []
    elif day == christmas_day and month == christmas_month:
        is_christmas = CHRISTMAS_YES
    elif config.bool("days_left", False):  #if not christmas and get days left
        is_christmas = get_daysleft(time.time(year = now.year, month = month, day = day, location = timezone), timezone, christmas_month, christmas_day)
    else:
        is_christmas = CHRISTMAS_NO

    #print(is_christmas)

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
                            width = 42,
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

def get_daysleft(today, timezone, christmas_month, christmas_day):
    if today.month == christmas_month and today.day > christmas_day:
        year = today.year + 1
    elif today.month > christmas_month:
        year = today.year + 1
    else:
        year = today.year

    christmas = time.time(year = year, month = christmas_month, day = christmas_day, location = timezone)

    days_left = (christmas - today).hours // 24

    days_left_text = "%d days" % days_left
    return days_left_text

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

def is_christmas_runup(month, christmas_month):
    if christmas_month == 12:
        return month == 12

    # For January Christmases, also show in January.
    # Another thought would be to use the 4 weeks of advent, prior to whatever date was chosen.
    return month == 12 or month == 1

def get_schema():
    # Christmas is only 25 December in certain branches of Christianity.
    # https://en.wikipedia.org/wiki/Christmas#Date_according_to_Julian_calendar
    date_options = [
        schema.Option(
            display = "24 December",
            value = "12-24",
        ),
        schema.Option(
            display = "25 December",
            value = "12-25",
        ),
        schema.Option(
            display = "6 January",
            value = "01-06",
        ),
        schema.Option(
            display = "7 January",
            value = "01-07",
        ),
        schema.Option(
            display = "19 January",
            value = "01-19",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "december_only",
                name = "December only?",
                desc = "Enable to only display in the month of December.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "days_left",
                name = "Display days left until Christmas?",
                desc = "Enable to display the number of days left until Christmas.",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "christmas_date",
                name = "Christmas date",
                desc = "When do you celebrate Christmas?",
                icon = "calendar",
                default = date_options[1].value,
                options = date_options,
            ),
        ],
    )
