"""Little Resident: stateless doghouse and reading arcs, using approved reusable sprite motions."""

load("assets.star", "ANCHORS", "ASSETS", "TRACKS")
load("encoding/base64.star", "base64")
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

def recipe_at(seconds, resident):
    # Clock time replaces a per-user database. Missing a showing does not stall life.
    arc = seconds // 360
    key = resident + ":" + str(arc)
    return {
        "arc": arc,
        "key": key,
        "stage": (STAGES if arc % 2 == 0 else READ_STAGES)[(seconds // 120) % 3],
        "book": number(key, "book", 3),
        "color": number(key, "paint", 3),
        "dog": DOGS[number(key, "dog", 3)],
        "smudge": number(key, "smudge", 2) == 1,
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
        data = data[:16] + palette + data[25:]
        memo[index] = render.Image(src = data)
    return memo[index]

def main(config):
    seconds = int(config.get("debug_seconds", str(time.now().unix)))
    recipe = recipe_at(seconds, config.get("resident", "little-resident"))
    stage = config.get("debug_stage", recipe["stage"])
    color = int(config.get("debug_color", str(recipe["color"])))
    dog = config.get("debug_dog", recipe["dog"])
    smudge = config.get("debug_smudge", str(recipe["smudge"])) == "True"
    memo = {}
    if stage in READ_STAGES:
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
        schema.Text(id = "resident", name = "Adventure word", desc = "Pick any word to change the mix of adventures. Leave the default to get started.", icon = "user", default = "little-resident"),
    ])
