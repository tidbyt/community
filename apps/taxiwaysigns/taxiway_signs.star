"""
Applet: Taxiway Signs
Summary: Display taxiway signs
Description: Displays taxiway signs.
Author: Robert Ison
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

sign_font = "6x13"
signage_types = {1: "Location", 2: "Direction", 3: "Hold"}
sign_combinations = [[1, 3], [2, 1, 2], [1, 3], [2, 1, 2], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3]]

def main():
    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = get_random_combination_of_signs(),
                ),
            ],
        ),
    )

def get_random_combination_of_signs():
    sign_number = ["", "1", "2", "3", "4", "5"]
    direction_indicators = ["←", "↑", "↖"]
    right_direction_indicators = ["→", "➘", "➚"]
    sign_combination = sign_combinations[randomize(0, len(sign_combinations) - 1)]
    sections = len(sign_combination)
    taxiway_ids = get_set_of_taxiway_ids(sections)
    selected_direction_indicator = randomize(0, len(direction_indicators) - 1)
    remaining_width = 64
    children = []
    i = 0
    for type in sign_combination:
        width = int(math.round(64 / sections))
        if i == len(sign_combination) - 1:
            #Last item
            width = remaining_width

        #Get Text
        sign_text = ""
        if type == 1:  #Location
            sign_text = "%s%s" % (taxiway_ids[i], sign_number[randomize(0, len(sign_number) - 1)])
        elif type == 2:  #Direction
            if i == 0:
                sign_text = "%s%s" % (taxiway_ids[i], direction_indicators[selected_direction_indicator])
            else:
                sign_text = "%s%s" % (taxiway_ids[i], right_direction_indicators[selected_direction_indicator])
        elif type == 3:  #Hold
            sign_text = get_random_runway_designation(width)

        children.insert(i, get_single_box(signage_types[type], sign_text, width))
        remaining_width = remaining_width - width
        i = i + 1

    return children

def get_random_runway_designation(width):
    initial_runway = randomize(1, 18)
    padding = ""
    if initial_runway < 10:
        padding = "0"

    indicator = ""
    alt_indicator = ""

    random_number = randomize(0, 100)
    if random_number > 25:
        if random_number > 60:
            indicator = "L"
            alt_indicator = "R"
        else:
            indicator = "R"
            alt_indicator = "L"

    counter_runway = initial_runway + 18

    if width < 25:
        return "%s%s%s" % (padding, str(initial_runway), indicator)
    elif width > 45:
        if random_number > 60:
            return "← %s%s%s-%s%s →" % (padding, initial_runway, indicator, counter_runway, alt_indicator)
        elif random_number > 80:
            return "%s%s%s" % (padding, initial_runway, indicator)
        else:
            return "%s%s" % (counter_runway, indicator)
    else:
        return "%s%s-%s" % (padding, initial_runway, counter_runway)

def get_set_of_taxiway_ids(num):
    taxiway_ids = []
    starting_letter = 65 + randomize(0, 10)
    for i in range(num):
        taxiway_ids.insert(i, chr(starting_letter + i))

    return taxiway_ids

def get_single_box(type, text, width):
    if type == signage_types[1]:
        return render.Box(width = width, height = 32, color = "#ffbe02", child = render.Box(width = width - 2, height = 30, color = "#000", child = render.Text(text, color = "#ffbe02", font = sign_font)))
    elif type == signage_types[2]:
        return render.Box(width = width, height = 32, color = "#ffbe02", child = render.Text(text, color = "#000", font = sign_font))
    else:  #type == signage_types[3]:
        return render.Box(width = width, height = 32, color = "#d52124", child = render.Text(text, color = "#fff", font = sign_font))

def randomize(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max + 1 - min) + min)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
