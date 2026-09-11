"""Little Resident: stateless doghouse and reading arcs, using approved reusable sprite motions."""

load("assets.star", "ANCHORS", "ASSETS", "TRACKS")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STAGES = ["assembly", "painting", "completion"]
READ_STAGES = ["reading_choose", "reading_read", "reading_finish"]
BOOK_PALETTES = ["V4jEBAUGBwgJ", "lne4BAUGBwgJ", "YIdbBAUGBwgJ"]
DOGS = ["attentive", "eager", "sleepy"]
PALETTES = ["Q5OKKGVemtvE", "V4jENVZ+ttP0", "lne4Yk174sr6"]

def number(key, salt, limit):
    return int(hash.sha256(key + ":" + salt)[:8], 16) % limit

PROJECTS = ["doghouse", "reading", "meal", "garden", "exercise", "fetch", "bath", "paper_plane", "fireflies"]
SCENES = [STAGES, READ_STAGES, ["meal_prepare", "meal_eat", "meal_cleanup"], ["garden_plant", "garden_water", "garden_bloom"], ["single_exercise"], ["single_fetch"], ["single_bath"], ["single_paper_plane"], ["single_fireflies"]]
INGREDIENTS = ["qM9j", "tzk5", "79B5", "nGhU"]
FLOWERS = ["6a3M", "781l", "upzc"]

def weights_at(hour):
    if 6 <= hour and hour < 11:
        return [1, 1, 2, 2, 3, 1, 1, 1, 1]
    if 11 <= hour and hour < 17:
        return [2, 1, 2, 3, 1, 3, 1, 2, 1]
    if 17 <= hour and hour < 22:
        return [1, 2, 2, 1, 1, 1, 3, 1, 3]
    return [1, 3, 1, 1, 1, 1, 2, 1, 4]

def recipe_at(seconds, resident, offset = 0):
    # Reconstruct today's bounded schedule; full arcs never cross the day boundary.
    local_seconds = seconds + offset
    day = local_seconds // 86400
    slot = (local_seconds % 86400) // 120
    recent = []
    ages = [0 for _ in PROJECTS]
    variants = [-1 for _ in PROJECTS]
    cursor = 0
    chosen = 0
    key = ""
    variant = 0
    for block in range(720):
        key = resident + ":" + str(day) + ":" + str(block)
        weights = weights_at(cursor // 30)
        candidates = [i for i in range(9) if i not in recent[-3:] and cursor + len(SCENES[i]) <= 720]
        if len(recent) >= 2 and (recent[-1] < 4) == (recent[-2] < 4):
            preferred = [i for i in candidates if (i < 4) != (recent[-1] < 4)]
            if preferred:
                candidates = preferred
        total = 0
        for i in candidates:
            total += weights[i] * (4 + ages[i])
        draw = number(key, "activity", total)
        for i in candidates:
            draw -= weights[i] * (4 + ages[i])
            if draw < 0:
                chosen = i
                break
        choices = [v for v in range(3) if v != variants[chosen]]
        variant = choices[number(key, "variant", len(choices))]
        variants[chosen] = variant
        if cursor + len(SCENES[chosen]) > slot:
            break
        cursor += len(SCENES[chosen])
        recent.append(chosen)
        ages = [0 if i == chosen else ages[i] + 1 for i in range(9)]
    return {
        "arc": str(day) + ":" + str(cursor),
        "key": key,
        "stage": SCENES[chosen][slot - cursor],
        "variant": variant,
        "book": number(key, "book", 3),
        "color": number(key, "paint", 3),
        "dog": DOGS[number(key, "dog", 3)],
        "smudge": number(key, "smudge", 2) == 1,
        "flower": number(key, "flower", 3),
        "tower": number(key, "tower", 8) == 0,
        "ingredients": [number(key, "ingredient" + str(i), 4) for i in range(7)],
    }

def frame_times(stage, key):
    # Vary pauses between milestones without changing their order or the 15s length.
    anchors = ANCHORS[stage]
    weights = [(anchors[i + 1] - anchors[i]) * (70 + number(key, stage + str(i), 66)) for i in range(len(anchors) - 1)]
    total = 0
    for weight in weights:
        total += weight
    ticks = [0.0]
    acc = 0
    for weight in weights:
        acc += weight
        ticks.append(acc * 149.0 / total)
    samples = []
    for n in range(150):
        segment = 0
        for i in range(len(ticks) - 1):
            if n >= ticks[i]:
                segment = i
        fraction = (n - ticks[segment]) / (ticks[segment + 1] - ticks[segment])
        samples.append(min(149, int(anchors[segment] + fraction * (anchors[segment + 1] - anchors[segment]) + 0.5)))
    return samples

def sprite(index, palette, memo):
    if index not in memo:
        data = base64.decode(ASSETS[index])

        # GIF global palette entries 1..3 are dedicated paint channels.
        data = data[:16] + palette + data[16 + len(palette):]
        memo[index] = render.Image(src = data)
    return memo[index]

def main(config):
    seconds = int(config.get("debug_seconds", str(time.now().unix)))
    location = json.decode(config.get("location", "{}"))
    zone = location.get("timezone", config.get("timezone", "Etc/UTC"))
    local = time.from_timestamp(seconds).in_location(zone)
    utc_offset = local.format("-0700")
    offset = (int(utc_offset[1:3]) * 3600 + int(utc_offset[3:5]) * 60) * (-1 if utc_offset[0] == "-" else 1)
    recipe = recipe_at(seconds, config.get("resident", "little-resident"), offset)
    stage = config.get("debug_stage", recipe["stage"])
    color = int(config.get("debug_color", str(recipe["color"])))
    dog = config.get("debug_dog", recipe["dog"])
    smudge = config.get("debug_smudge", str(recipe["smudge"])) == "True"
    memo = {}
    if stage.startswith("single_"):
        variant = int(config.get("debug_variant", str(recipe["variant"]))) if stage in ["single_paper_plane", "single_fireflies"] else 0
        palette = base64.decode("AQIDBAUGBwgJ")
        frames = [sprite(index, palette, memo) for index in TRACKS[stage + "_" + str(variant)]]
    elif stage.startswith("garden_"):
        flower = int(config.get("debug_flower", str(recipe["flower"])))
        frames = [sprite(index, base64.decode(FLOWERS[flower]), memo) for index in TRACKS[stage]]
    elif stage.startswith("meal_"):
        tower = config.get("debug_tower", str(recipe["tower"])) == "True"
        ingredients = [int(x) for x in config.get("debug_ingredients", ",".join([str(x) for x in recipe["ingredients"]])).split(",")]
        palette = base64.decode("".join([INGREDIENTS[i] for i in ingredients]))
        track = stage + ("_tower" if tower else "")
        layers = [TRACKS[track]] + [TRACKS[track + "_lettuce" + str(i)] for i in range(7 if tower else 3) if ingredients[i] == 0]
        frames = [render.Stack(children = [sprite(layer[n], palette, memo) for layer in layers]) for n in range(150)]
    elif stage in READ_STAGES:
        book = int(config.get("debug_book", str(recipe["book"])))
        palette = base64.decode(BOOK_PALETTES[book])
        frames = [sprite(index, palette, memo) for index in TRACKS[stage]]
    else:
        base = TRACKS["painting_smudge" if stage == "painting" and smudge else stage + "_base"]
        pet = TRACKS[stage + "_" + dog]
        palette = base64.decode(PALETTES[color])
        samples = range(150) if config.get("debug_fixed_timing", "false") == "true" else frame_times(stage, recipe["key"])
        frames = [render.Stack(children = [sprite(base[n], palette, memo), sprite(pet[n], palette, memo)]) for n in samples]
    print("arc=%s stage=%s color=%s dog=%s smudge=%s book=%s" % (recipe["arc"], stage, color, dog, smudge, recipe["book"]))
    return render.Root(child = render.Animation(children = frames), delay = 100)

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Location(id = "location", name = "Local time", desc = "Used only for gentle daytime and evening preferences. No location is sent to external services.", icon = "clock"),
        schema.Text(id = "resident", name = "Adventure word", desc = "Pick any word to change the mix of adventures. Leave the default to get started.", icon = "user", default = "little-resident"),
    ])
