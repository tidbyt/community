"""
Applet: Beli Feed
Summary: Displays activity from Beli
Description: Displays activity from your friends on Beli (beliapp.com).
Author: leoadberg
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def Text(text, **kwargs):
    return render.Text(content = str(text), **kwargs)

def WrappedText(text, **kwargs):
    return render.WrappedText(content = str(text), **kwargs)

def Marquee(child, **kwargs):
    return render.Marquee(child = child, **kwargs)

def Row(*children, **kwargs):
    return render.Row(children = list(children), **kwargs)

def Column(*children, **kwargs):
    return render.Column(children = list(children), **kwargs)

def Animation(*children):
    return render.Animation(children = list(children))

def Box(child):
    return render.Box(child = child)

def Stack(*children):
    return render.Stack(children = list(children))

def Pad(child, pad):
    return render.Padding(child = child, pad = pad)

DEFAULT_WHO = "lad"

modes = [
    schema.Option(
        display = "My Activity",
        value = "mine",
    ),
    schema.Option(
        display = "My Friends' Activity",
        value = "friends",
    ),
]

orderings = [
    schema.Option(
        display = "Most Recent",
        value = "recent",
    ),
    schema.Option(
        display = "Random",
        value = "random",
    ),
]

API = "https://beli.cleverapps.io/api/"

def get(path, ttl):
    data = cache.get(path)
    if data:
        return json.decode(data)

    data = http.get(API + path).body()

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(path, data, ttl_seconds = ttl)
    return json.decode(data)

def username_to_id(user):
    data = get("user/member/?&username__iexact=" + user, 10000000)  # Should literally never expire

    if "results" not in data or len(data["results"]) != 1 or "id" not in data["results"][0]:
        return None

    return data["results"][0]["id"]

def renderRating(rating):
    if rating == -1:
        s = "?"
        color = "#fff"
    else:
        rating = math.round(rating * 10) / 10
        s = str(rating)
        if s[:2] == "10":
            s = "10"
        if rating >= 6.7:
            color = "#0f0"
        elif rating >= 3.5:
            color = "#fe1"
        else:
            color = "#f00"

    return Stack(
        Pad(render.Circle(color = "#fff", diameter = 15), (49, 17, 0, 0)),
        Pad(render.Circle(color = "#111", diameter = 13), (50, 18, 0, 0)),
        Pad(Text(s, color = color), (51, 21, 0, 0)),
    )

def getFriendsActivity(id, cutoff, index):
    data = get("newsfeed-old/" + id + "/?max_items=30", 600)
    scores = get("newsfeed-scores/" + id, 600)
    scoremap = {}
    for score in scores:
        scoremap[score["user_id"] + str(score["business_id"])] = score["value"]

    results = [x for x in data["results"] if x["event_type"] == "ADD"]
    if cutoff > 0:
        results = [x for x in results if (time.now() - time.parse_time(x["sent_dt"])) < time.minute * cutoff]

    if len(results) == 0:
        return None

    item = results[index % len(results)]

    text = item["body"]
    user, business = text.split(" ranked ")

    key = item["user1"] + str(item["business"])
    rating = -1
    if key in scoremap:
        rating = scoremap[key]

    return Stack(
        Column(
            Marquee(Text(user, color = "#8ff"), width = 64),
            Text("ranked", color = "#aaa"),
            WrappedText(business, width = 52),
        ),
        renderRating(rating),
    )

def getMyActivity(id, cutoff, index):
    profile = get("user/member/?id=" + id, 10000000)["results"][0]
    data = get("rank-list/" + id, 600)
    data = sorted(data, key = lambda x: x["created_dt"], reverse = True)

    name = profile["first_name"] + " " + profile["last_name"]

    if cutoff > 0:
        data = [x for x in data if (time.now() - time.parse_time(x["created_dt"])) < time.minute * cutoff]

    if len(data) == 0:
        return None

    item = data[index % len(data)]
    return Stack(
        Column(
            Marquee(Text(name, color = "#8ff"), width = 64),
            Text("ranked", color = "#aaa"),
            WrappedText(item["business__name"], width = 52),
        ),
        renderRating(item["score"]),
    )

def main(config):
    user = config.str("user", DEFAULT_WHO)
    id = username_to_id(user)
    if not id:
        return render.Root(child = Text("Unknown user"))

    mode = config.str("mode", modes[0].value)
    order = config.str("order", orderings[0].value)
    cutoff_str = config.str("time", "0")
    cutoff = 0
    if cutoff_str.isdigit():
        cutoff = int(cutoff_str)

    indexkey = user + mode + order + cutoff_str
    index = int(cache.get(indexkey) or 0)

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(indexkey, str(index + 1), 600)  # Keep position in list for 10m

    if order == "random":
        index = random.number(0, 100000)

    if mode == "mine":
        frame = getMyActivity(id, cutoff, index)
    elif mode == "friends":
        frame = getFriendsActivity(id, cutoff, index)
    else:
        fail()

    if frame == None:
        return []

    return render.Root(delay = 100, child = frame)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "user",
                name = "Beli Username",
                desc = "Your username on Beli",
                icon = "user",
            ),
            schema.Dropdown(
                id = "mode",
                name = "Mode",
                desc = "Which activity to display",
                icon = "peopleGroup",
                default = modes[0].value,
                options = modes,
            ),
            schema.Dropdown(
                id = "order",
                name = "Ordering",
                desc = "Order to show activity",
                icon = "arrowUpWideShort",
                default = orderings[0].value,
                options = orderings,
            ),
            schema.Text(
                id = "time",
                name = "Time Cutoff",
                desc = "Only display ratings within the last N minutes. The app will be skipped if there are none. '0' or any non-number will show ratings from any time.",
                icon = "clock",
                default = "0",
            ),
        ],
    )
