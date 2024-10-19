"""
Applet: Martini
Summary: Displays your martini order
Description: Displays your martini order based on your preferences.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")  #Used to read encoded image
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

MARTINI_OLIVES = """
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
"""

MARTINI_LEMON = """
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
"""

MARTINI_ONIONS = """
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
"""

MARTINI_ORANGE = """
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YmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDQuNC4wLUV4aXYyIj4KIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIgogICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgIHhtbG5zOkdJTVA9Imh0dHA6Ly93d3cuZ2ltcC5vcmcveG1wLyIKICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICB4bXBNTTpEb2N1bWVudElEPSJnaW1wOmRvY2lkOmdpbXA6MzhlNDRjYTktZjdlZS00ZDJhLWE5NGMtYTIxYzc2OTZiMjlhIgogICB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOmNiMGViNTMwLTQ5YzQtNGM4OS04MTIxLWEzMGM5NTUxMmFkOSIKICAgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmRhOGE2NDE1LTc5NGUtNDQ2Yi1iZGJkLWQxZmYxNWY2ZTdlNSIKICAgR0lNUDpBUEk9IjIuMCIKICAgR0lNUDpQbGF0Zm9ybT0iTWFjIE9TIgogICBHSU1QOlRpbWVTdGFtcD0iMTcyODcwNDM4NzE1MTU5MiIKICAgR0lNUDpWZXJzaW9uPSIyLjEwLjM2IgogICBkYzpGb3JtYXQ9ImltYWdlL3BuZyIKICAgdGlmZjpPcmllbnRhdGlvbj0iMSIKICAgeG1wOkNyZWF0b3JUb29sPSJHSU1QIDIuMTAiCiAgIHhtcDpNZXRhZGF0YURhdGU9IjIwMjQ6MTA6MTFUMjM6Mzk6NDMtMDQ6MDAiCiAgIHhtcDpNb2RpZnlEYXRlPSIyMDI0OjEwOjExVDIzOjM5OjQzLTA0OjAwIj4KICAgPHhtcE1NOkhpc3Rvcnk+CiAgICA8cmRmOlNlcT4KICAgICA8cmRmOmxpCiAgICAgIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiCiAgICAgIHN0RXZ0OmNoYW5nZWQ9Ii8iCiAgICAgIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MDRiZWQ2OWUtOGNjNi00ZjExLThmMmQtM2EwMGZmMjBmMjc3IgogICAgICBzdEV2dDpzb2Z0d2FyZUFnZW50PSJHaW1wIDIuMTAgKE1hYyBPUykiCiAgICAgIHN0RXZ0OndoZW49IjIwMjQtMTAtMTFUMjM6Mzk6NDctMDQ6MDAiLz4KICAgIDwvcmRmOlNlcT4KICAgPC94bXBNTTpIaXN0b3J5PgogIDwvcmRmOkRlc2NyaXB0aW9uPgogPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgIAo8P3hwYWNrZXQgZW5kPSJ3Ij8+O6PqBQAAAAZiS0dEAAAAAAAA+UO7fwAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+gKDAMnL0X3pTMAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAADu0lEQVRIx62WfUybVRTGn3v7tuhoZGbRIUMsWWICGcxYN6Nh0X+Wza+kY2Qkc0vAry3qphgxxhllGZJAFt2ymPgZwz7MJtigU6aTuKARcTo22EdbWClrRz8oKxTatYy+ffwDaWBSaLQnOXmTe05+Ofe9zzn3AgD/j5tMpWxqOn7z+n8H6nQZPNtt5Q8/tqcPav6mlTabkwUFK5JBxQIQMcv31NbT7Q1x69ZnboqB4qe2Dubm3g0hAAGAEJBSQmo00CoaCKmBomgAQUhIUABCCChSCyElVDUGIQApNZBCYteu16BcG/ahqGglDh36DMPDQ1BjcRAECQgBAICUEgDx5FOlyMszQKvTotduRcvXTYhORBAMBrHzlWosylyEzt87IADBP/7sQXZ2NsKhMAhiumYAEJgi63Q6aBSJXlc3VuQ/BNegE9HrEShaCb3+NmRlZaGicjPaT7VBAsSrO7dDjamIRidQ2JWPwi7DP998FHQZ4PZ4oNPqUb//TZQUrsLp823QZ+rhcFwGCNyVswx1dTVoP9WGaSMAbtv2Eof8YfIIZvn6x57gBYuDZ7ovMhwIMBwI8MIlO788aubGsnK6ro7y/X0fUsw4qFmS2rv3AL3eECsqnyOPgO++U0uvN8yLNgf7+4fYfc7C03/10Nbn5tq162mxDPD71p8T6hDJdGo2t9Lu8HHTps10D47xK/OxRIWBkRgtVhdLN5Txt44zPHvOxiVL7phRoUgu/s7OHrrdY7RddiSAnxz+gD5fiMuX38uTJ3+htfcqVz/4cDJd/3vRaFzNS1Ynz/f1JqAed4gHDzezufk72u0emjZsnK9Z5g6Ulz9NpytAr3eCV5x+7j/wERsbj3Lgip8mU9nM/5c6FABfr36LvqHr3FPbwJqa9zg4GOSWLRWpzIX5Exoa9tHnC9PjCbFmd12qw2bhpL4+O1taviVEatNLIiUjIpHwdOcuaClBFUWDmKoiVUsJKqQCr9eXXmg0CgQCY+mECpCcGsbphEopEVfj6d1+RkbG1G2QXqgOUoo0n76QiE2mWVIAQDK90Hg8PnVNp2jKfMHnX3gRa0oegZQSJWsexUhwFJ9/+jEW6lcxV8aOHVWofHY7luXkwjHQj/FQELfekgnDPQaExsdx4sRxVFW9nBQ+C7pu3eOofuNt3G98ACOjo+js+BXRaCTxqtBILYzGVcjJzYPX7UJ9/W4cbPxi/u0XF63E0qV3wuNxg3GiuPg+qKqKmKpicvIGYjfiCFwLYNjvRxxxLF58+5yV/g0+mZrVgVW9KwAAAABJRU5ErkJggg==
"""

PHRASES = ["I would like %s.", "Pour me %s please.", "Fix me %s please.", "I'll have %s.", "Could I get %s please?", "I'm feeling %s."]

FONT = "5x8"

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

#handy little function that let's you print out a bunch of variables
#def display_variables(*args):
#    i = 0
#    for var in args:
#        i = i + 1
#        print("%s: %s" % (i, var))

def main(config):
    base = config.get("base", base_options[len(base_options) - 1].value)
    preparation = config.get("preparation", preparation_options[1].value)
    vermouth_type = config.get("vermouthtypeof", vermouth_options[2].value)
    garnish = config.get("garnish", garnish_options[0].value)
    dirty = " dirty " if garnish == "dirty" else ""
    drink = "Gibson" if garnish == "Onion" else "martini"
    garnish_description = "" if drink == "Gibson" or garnish == "dirty" else ", %s" % garnish
    vermouth_description = ", "

    if vermouth_type == "Sweet" or vermouth_type == "White":
        if vermouth_type == "Sweet":
            vermouth_description = " with sweet vermouth, "
        elif vermouth_type == "White":
            vermouth_description = " with white vermouth, " if random.number(0, 1) == 1 else " with bianco vermouth, "
        vermouth_type = ""
    else:
        vermouth_type = vermouth_type + " "

    #default image
    selected_image = render.Image(src = base64.decode(MARTINI_OLIVES))

    if "twist" in garnish or "peel" in garnish:
        if "orange" in garnish:
            selected_image = render.Image(src = base64.decode(MARTINI_ORANGE))
        else:
            selected_image = render.Image(src = base64.decode(MARTINI_LEMON))
    elif drink == "Gibson" or garnish == "au naturel":
        selected_image = render.Image(src = base64.decode(MARTINI_ONIONS))

    #display_variables(base, preparation, vermouth_type, garnish, dirty, drink, vermouth_description)

    if base == "Vesper":
        vermouth_type = ""
        vermouth_description = ", "

    if vermouth_type == "Dry":
        vermouth_type = ""

    spacer = " "
    if base == "Gin" and config.bool("oldschool"):
        base = ""
        spacer = ""

    article = "an" if vermouth_type == "Extra Dry " and dirty == "" else "a"

    if len(dirty) == 0:
        article = article + " "

    message = "%s%s%s%s%s%s%s%s%s" % (article, dirty.lower(), vermouth_type.lower(), base.lower(), spacer, drink.lower(), vermouth_description.lower(), preparation.lower(), garnish_description.lower())
    message = "     " + PHRASES[random.number(0, len(PHRASES) - 1)] % message

    return render.Root(
        render.Stack(
            children = [
                selected_image,
                add_padding_to_child_element(render.Marquee(width = 50, child = render.Text(content = message, color = "#fff", font = FONT)), 12, 20),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_vermouth_options(base):
    if base == "Vesper":
        return []
    else:
        return [
            schema.Dropdown(
                id = "vermouthtypeof",
                name = "Vermouth",
                desc = "Choose your type of vermouth for your martini.",
                icon = "wineBottle",  #guage, glassWater
                options = vermouth_options,
                default = vermouth_options[0].value,
            ),
        ]

scroll_speed_options = [
    schema.Option(display = "Slow", value = "60"),
    schema.Option(display = "Medium", value = "45"),
    schema.Option(display = "Fast", value = "30"),
]

base_options = [
    schema.Option(value = "Gin", display = "Gin"),
    schema.Option(value = "Vodka", display = "Vodka"),
    schema.Option(value = "Vesper", display = "Vesper (Gin, Vodka and Lillet Blanc)"),
]

vermouth_options = [
    schema.Option(value = "Naked", display = "None"),
    schema.Option(value = "Extra Dry", display = "Very little dry vermouth"),
    schema.Option(value = "Dry", display = "About 1/4 Ounce of dry vermouth"),
    schema.Option(value = "Wet", display = "Even more vermouth"),
    schema.Option(value = "Sweet", display = "Some sweet vermouth"),
    schema.Option(value = "Perfect", display = "Equal Mix of Sweet and Dry vermouth"),
    schema.Option(value = "White", display = "White (bianco) Vermouth"),
]

garnish_options = [
    schema.Option(value = "au naturel", display = "Nothing"),
    schema.Option(value = "with an olive", display = "Olive with no brine"),
    schema.Option(value = "dirty", display = "Olive with some brine"),
    schema.Option(value = "with a twist", display = "Twist of Lemon Peel"),
    schema.Option(value = "with an orange twist", display = "Twist of Orange Peel"),
    schema.Option(value = "with a lemon peel", display = "Larger piece of Lemon Peel"),
    schema.Option(value = "with an orange peel", display = "Larger piece of Orange Peel"),
    schema.Option(value = "with Caper Berries", display = "Caper Berries"),
    schema.Option(value = "Onion", display = "Cocktail Onion"),
]

preparation_options = [
    schema.Option(value = "Shaken", display = "Shaken in a mixing tin adding ice shards."),
    schema.Option(value = "Stirred", display = "Stirred in a mixing tin with ice shards less likely to appear."),
    schema.Option(value = "Up", display = "Chilled, but let the bartender decide to shake, stir or throw."),
    schema.Option(value = "Thrown", display = "Thrown from one mixing tin to another."),
    schema.Option(value = "On the Rocks", display = "Mixed with Ice Cubes in the glass."),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "oldschool",
                name = "Old School Bartender?",
                desc = "Is your bartender an experience 'old school' mixologist?",
                icon = "personChalkboard",  #"user", #"person",
                default = True,
            ),
            schema.Dropdown(
                id = "base",
                name = "Base Spirit",
                desc = "Choose your base spirit for your Martini.",
                icon = "flask",  #"martiniGlassEmpty",
                default = base_options[0].value,
                options = base_options,
            ),
            schema.Dropdown(
                id = "preparation",
                name = "Preparation",
                desc = "How would you like your martini prepared?",
                icon = "spoon",
                default = preparation_options[0].value,
                options = preparation_options,
            ),
            schema.Generated(
                id = "vermouthtype",
                source = "base",
                handler = get_vermouth_options,
            ),
            schema.Dropdown(
                id = "garnish",
                name = "Garnish",
                desc = "What would you like added to your Martini?",
                icon = "martiniGlassCitrus",
                default = garnish_options[0].value,
                options = garnish_options,
            ),
        ],
    )
