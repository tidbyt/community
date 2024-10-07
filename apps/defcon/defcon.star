"""
Applet: DefCon
Summary: Displays DefCon Status
Description: Displays current DefCon status.
Author: Robert Ison
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEF_CON_URL = "https://www.defconlevel.com/current-level.php"
CACHE_TTL_SECONDS = 259200
FONT = "6x13"
DEF_CON_COLORS = ["#fff", "#e13426", "#ff0", "#21a650", "#298cc1"]

display_options = [
    schema.Option(value = "0", display = "Actual Defcon Level"),
    schema.Option(value = "1", display = "Defcon 1"),
    schema.Option(value = "2", display = "Defcon 2"),
    schema.Option(value = "3", display = "Defcon 3"),
    schema.Option(value = "4", display = "Defcon 4"),
    schema.Option(value = "5", display = "Defcon 5"),
]

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions()

    position = config.get("list", display_options[0].value)

    if position == "0":
        res = http.get(url = DEF_CON_URL, ttl_seconds = CACHE_TTL_SECONDS)
        if res.status_code != 200:
            fail("request to %s failed with status code: %d - %s" % (DEF_CON_URL, res.status_code, res.body()))

        text_to_find = "OSINT Defcon Level: "
        position = res.body().find(text_to_find) + len(text_to_find)
        position = res.body()[position:position + 1]
        if position.isdigit():
            position = int(position)
    else:
        position = int(position)

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(width = 64, height = 15, color = "#fff", child = render.Box(width = 64 - 2, height = 15 - 2, color = "#000", child = render.Text("DEFCON", color = "#fff", font = FONT))),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 1, color = "#000"),
                    ],
                ),
                render.Animation(
                    children = get_defcon_display(position),
                ),
            ],
        ),
        delay = 1000,
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

def get_defcon_display(position):
    children = []

    #add grey outlines of the 5 conditions
    temp_group_of_children = []
    for i in range(5):
        color = "#333"
        temp_group_of_children.insert(len(children), add_padding_to_child_element(render.Box(width = 12, height = 16, color = color, child = render.Box(width = 12 - 2, height = 16 - 2, color = "#000", child = add_padding_to_child_element(render.Text(str(i + 1), color = color, font = FONT), 1))), i * 13))

    grey_box = render.Stack(temp_group_of_children)
    children.insert(len(children), grey_box)

    color_box = None

    # Flash each condition until the current condition
    for i in range(4, -1, -1):
        temp_group_of_children = []
        color = "#333"
        if (i + 1 >= position):
            color = DEF_CON_COLORS[i]
            temp_group_of_children.insert(len(children), grey_box)
            temp_group_of_children.insert(len(children), add_padding_to_child_element(render.Box(width = 12, height = 16, color = color, child = render.Box(width = 12 - 2, height = 16 - 2, color = "#000", child = add_padding_to_child_element(render.Text(str(i + 1), color = color, font = FONT), 1))), i * 13))
            color_box = render.Stack(temp_group_of_children)
            children.insert(len(children), color_box)

    # flash current
    for _ in range(3):
        children.insert(len(children), grey_box)
        children.insert(len(children), color_box)

    # hold on current a while longer
    for _ in range(3):
        children.insert(len(children), color_box)

    return children

def display_instructions():
    ##############################################################################################################################################################################################################################
    instructions_1 = "For security reasons, the U.S. military does not release the current DEFCON level. "
    instructions_2 = "The source for this app is defconlevel.com which uses Open Source Intelligence to estimate the DEFCON level.  Default is to use the actual estimated DefCon level, but you can pick a level if you want. "
    instructions_3 = "Defcon level 5 is the lowest alert level. The highest level reached was level 2 during the Cuban Missle Crisis. This display is based on the movie War Games (1983)."
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text("DEFCON", color = "#65d0e6", font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(instructions_1, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#f4a306"),
                ),
            ],
        ),
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",  #"info",
                default = False,
            ),
            schema.Dropdown(
                id = "list",
                name = "Defcon List",
                desc = "Defcon Level",
                icon = "list",
                default = display_options[1].value,
                options = display_options,
            ),
        ],
    )
