"""
Applet: Idle Gardener
Summary: Grow trees while you work
Description: The Idle Gardener is an Idle tree growing tycoon that takes absolutely no input from you!
Author: yonodactyl
"""

load("cache.star", "cache")

# LOAD MODULES
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# CONSTANTS
TREE_GROWN = "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAEFJREFUGJVjYCAAGGGM5GO+/5El5lptZmRgYGBgImQCC4xxfu0PrAqIN+H5qV8M0Uy/GBgYGBiW/mPDVIAuQTQAABWCDdre18jnAAAAAElFTkSuQmCC"
TREE_CHOPPED = "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAD5JREFUGJVjYBh4wAhjSNra/59vJMjAwMDAkHjuPcPzwwcZGRgYGFiQVe+58BLKYsNunKSt/X9JW/v/JLkBAH+gDKm0ZxVNAAAAAElFTkSuQmCC"
TREE_GROWING = "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAFZJREFUGJVjYCAGJB/z/Y+Pz8DAwMCwIz/gPzINA4wwHYKVbxhcDMThEh4TNzAyMDAwsDAwMDDMtdrMCBG2xDCaCcaQtLWHSy79x4bdsZK29v+RFRIFADSSGQajlomuAAAAAElFTkSuQmCC"

GROWN_STATE = "GROWN"
GROWING_STATE = "GROWING"
CHOPPED_STATE = "CHOPPED"

# MAIN
def main(config):
    garden_id = config.get("garden_id")
    updated_tree_list = return_tree_states(garden_id)

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(color = "#305d30"),
                render.Column(
                    children = [
                        return_trees(updated_tree_list),
                        return_chopped_count(config, garden_id),
                    ],
                ),
            ],
        ),
    )

# Tree State Method
def return_tree_states(id):
    cached_trees = cache.get("{id}-tree_list".format(id = id))
    chopped_count = cache.get("{id}-chopped_count".format(id = id))

    # No cache exist - set to zero
    if chopped_count == None:
        cache.set("{id}-chopped_count".format(id = id), "0", ttl_seconds = 86400)

    # No cache exist - generate a new list of trees
    if cached_trees == None:
        encoded_list = generate_tree_list()
        cache.set("{id}-tree_list".format(id = id), encoded_list, ttl_seconds = 86400)
        return encoded_list

    # Found a cache and will use this data.
    updated_tree_list = update_tree_states(cached_trees, id)
    cache.set("{id}-tree_list".format(id = id), updated_tree_list, ttl_seconds = 86400)
    return updated_tree_list

def return_trees(tree_list):
    """
    Decode a list of trees and render the content within a Column.
    Each Row will hold a tree, rendering the sprite on the object.
    """
    decoded_list = json.decode(tree_list)
    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Image(src = base64.decode(tree["sprite"]))
                    for tree in column
                ],
            )
            for column in decoded_list["list"]
        ],
    )

def return_chopped_count(config, id):
    chopped_count = cache.get("{id}-chopped_count".format(id = id))
    green_mode = config.bool("green_mode")

    return render.Box(
        color = "#000",
        height = 8,
        width = 64,
        child = render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Row(
                children = [
                    render.Image(src = base64.decode(TREE_GROWN), width = 8),
                    render.Marquee(
                        width = 56,
                        child = render.Row(
                            children = [
                                render.Text("{phrase}: {count}".format(phrase = "Chopped" if not green_mode else "Planted", count = int(chopped_count))),
                            ],
                        ),
                    ),
                ],
            ),
        ),
    )

def increment_chopped_count(garden_id):
    """
    Increment the counter by one each time we fire this method.
    In theory, this method should only fire when the tree has been `chopped`.
    We are storing the counter in a unique cache with the ID of the Tidbyt owners Garden ID (randomly generated when the schema is set).
    """
    chopped_count = cache.get("{id}-chopped_count".format(id = garden_id))

    if chopped_count == None:
        chopped_count = cache.set("{id}-chopped_count".format(id = garden_id), "0", ttl_seconds = 86400)
    else:
        temp_count = int(chopped_count)
        temp_count += 1
        cache.set("{id}-chopped_count".format(id = garden_id), str(temp_count), ttl_seconds = 86400)

# Tree Growth Methods
def has_finished_growth_cycle(tree):
    """
    Our trees will grow for the duration that is passed in from the dictionary.
    Returns a boolean letting the `perform_growth` function know that it has/has not completed.
    """
    planted_date = time.parse_time(tree["planted"], "2006-01-02T15:04:05Z07:00")
    plant_grow_duration = tree["grow_duration"]
    difference = planted_date + time.parse_duration("{dur}s".format(dur = plant_grow_duration))

    return difference < time.now()

def perform_growth(tree, garden_id):
    """
    Our tree will perform the growth in the event that the state has reached its peak.
    A duration is a random value to allow the saplings to grow at random.
    """
    new_tree = tree
    tree_state = new_tree["state"]

    if tree_state == GROWN_STATE:
        increment_chopped_count(garden_id)
        new_tree = update_tree_dict(new_tree, CHOPPED_STATE, TREE_CHOPPED, str(time.now().format("2006-01-02T15:04:05Z07:00")), random.number(5, 60))
    elif tree_state == GROWING_STATE:
        new_tree = update_tree_dict(new_tree, GROWN_STATE, TREE_GROWN, str(time.now().format("2006-01-02T15:04:05Z07:00")), random.number(30, 60))
    else:
        new_tree = update_tree_dict(new_tree, GROWING_STATE, TREE_GROWING, str(time.now().format("2006-01-02T15:04:05Z07:00")), random.number(60, 60 * 2))

    return new_tree

def update_tree_dict(new_tree, new_state, new_sprite, new_planted_date, new_duration):
    """
    To simplify the updating we use this helper method to make sure that we are DRY with our implementation.
    """
    new_tree["state"] = new_state
    new_tree["sprite"] = new_sprite
    new_tree["planted"] = new_planted_date
    new_tree["grow_duration"] = new_duration

    return new_tree

def update_tree_states(cached_trees, garden_id):
    """
    Take a decoded list of cached trees and attempt to update and increment the counter.
    The columns and rows are both dictionaries, so we can iterate and update them with new content.
    """
    decoded_list = json.decode(cached_trees)

    for row in decoded_list["list"]:
        for tree in row:
            if has_finished_growth_cycle(tree):
                new_tree = perform_growth(tree, garden_id)
                tree.update(new_tree)

    return json.encode(decoded_list)

# Tree Generation Method
def generate_tree_list():
    """
    The initial generation of the list of trees will spawn a dictionary with the default values.\
    On inception, a dictionary will have all grown trees, but will have a short `grow_duration` since they are already matured.
    This means that the chopping aspect will be quick for trees in this state.
    """
    column_array = []

    for _ in range(0, 3):  # The number of columns to iterate over (3 being the standard)
        row_array = []
        for _ in range(0, 8):  # The number of rows to iterate over (8 being the standard)
            tree = dict(id = random.number(9999, 999999), state = GROWN_STATE, sprite = TREE_GROWN, planted = str(time.now().format("2006-01-02T15:04:05Z07:00")), grow_duration = random.number(5, 60))  # create our dictionary
            row_array.append(tree)
        column_array.append(row_array)

    tree_list = dict(list = column_array)

    return json.encode(tree_list)

# SCHEMA CONFIG
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "green_mode",
                name = "Green Mode",
                desc = "Show a greener message",
                icon = "handPeace",
                default = False,
            ),
            schema.Text(
                id = "garden_id",
                name = "Garden ID",
                desc = "Your Garden ID is unique. WARNING: Changing this will erase your progress.",
                icon = "houseChimneyUser",
                default = "Garden #{id}".format(id = str(random.number(9999, 999999))),
            ),
        ],
    )
