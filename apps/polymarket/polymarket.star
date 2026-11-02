"""
Applet: Polymarket
Summary: Trending markets and movers
Description: Prediction market favorites, implied probabilities, and changes.
Author: Conor McLaughlin
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API = "https://gamma-api.polymarket.com"
BLUE = "#719eff"
WHITE = "#f2f5ff"
MUTED = "#929cab"
UP = "#6cd8cf"
DOWN = "#f5ad77"
CACHE_SECONDS = 300
STALE_SECONDS = 1800
POOL_SIZE = 8
MIN_CARD_FRAMES = 150
FRAME_DELAY = 50

# Broad tags, rather than individual teams, candidates, or ticker symbols.
TOPICS = [
    ("politics", "Politics & elections", ["politics", "elections", "election", "us-presidential-election", "midterms"]),
    ("sports", "Sports & esports", ["sports", "esports"]),
    ("crypto", "Crypto", ["crypto", "cryptocurrency", "bitcoin"]),
    ("finance", "Finance & economy", ["finance", "economy", "economics", "business"]),
    ("world", "World & geopolitics", ["geopolitics", "world", "foreign-policy"]),
    ("tech", "Technology & science", ["tech", "technology", "science", "ai"]),
    ("culture", "Culture & entertainment", ["culture", "pop-culture", "entertainment"]),
    ("weather", "Weather & climate", ["weather", "climate"]),
]

def get_schema():
    fields = [
        schema.Dropdown(
            id = "feed",
            name = "Feed",
            desc = "Trending ranks events by 24h volume. Breaking finds daily movers; rankings may differ from the website.",
            icon = "chartLine",
            default = "trending",
            options = [schema.Option(display = "Trending", value = "trending"), schema.Option(display = "Breaking", value = "breaking")],
        ),
        schema.Dropdown(
            id = "period",
            name = "Probability change",
            desc = "Change in the displayed outcome's probability, in percentage points.",
            icon = "clock",
            default = "day",
            options = [schema.Option(display = "Past 24 hours", value = "day"), schema.Option(display = "Past week", value = "week")],
        ),
    ]
    for key, name, _ in TOPICS:
        fields.append(schema.Toggle(
            id = "include_" + key,
            name = "Include " + name,
            desc = "Turn off to exclude events tagged with this topic, including events with overlapping topics.",
            icon = "filter",
            default = True,
        ))
    fields.append(schema.Toggle(
        id = "include_other",
        name = "Include other topics",
        desc = "Include events without any of the broad topic tags above.",
        icon = "filter",
        default = True,
    ))
    return schema.Schema(version = "1", fields = fields)

def number(value):
    # Parse untrusted price strings as JSON numbers, avoiding float() exceptions.
    if type(value) == "string":
        value = json.decode(value, default = None)
    if type(value) not in ["int", "float"]:
        return None
    if value != value or abs(value) > 1e30:
        return None
    return float(value)

def array(value):
    if type(value) == "string":
        value = json.decode(value, default = None)
    return value if type(value) == "list" else []

def text(value):
    if type(value) != "string":
        return ""

    # Normalize common punctuation for the small bitmap fonts. Bound display work.
    value = value.replace("’", "'").replace("“", '"').replace("”", '"').replace("–", "-").replace("—", "-")
    return " ".join(value.split())[:180]

def is_open(item):
    if type(item) != "dict" or item.get("active") != True or item.get("closed") != False or item.get("archived") == True:
        return False
    return item.get("resolved") != True and item.get("automaticallyResolved") != True and item.get("umaResolutionStatus") != "resolved" and item.get("ended") != True and not text(item.get("finishedTimestamp"))

def allowed(event, excluded):
    tags = array(event.get("tags"))
    matched = False
    for key, _, slugs in TOPICS:
        if any([type(tag) == "dict" and tag.get("slug") in slugs for tag in tags]):
            matched = True
            if key in excluded:
                return False
    return matched or "other" not in excluded

def outcome_prices(market):
    if type(market) != "dict":
        return None
    outcomes = array(market.get("outcomes"))
    prices = array(market.get("outcomePrices"))
    if len(outcomes) != 2 or len(prices) != 2:
        return None
    values = [number(p) for p in prices]
    if any([p == None or p < 0 or p > 1 for p in values]):
        return None
    if abs(values[0] + values[1] - 1) > 0.05:
        return None
    if any([not text(o) for o in outcomes]):
        return None
    return (outcomes, values)

def market_prices(market):
    if not is_open(market) or market.get("acceptingOrders") == False or end_date_passed(market):
        return None
    return outcome_prices(market)

def end_date_passed(market):
    # A conservative display cutoff, not evidence of formal resolution. Only
    # compare recognizable UTC timestamps; malformed/offset dates are ignored.
    end = text(market.get("endDate"))
    if len(end) < 19 or not (end.endswith("Z") or end.endswith("+00:00")):
        return False
    if end[4] != "-" or end[7] != "-" or end[10] != "T" or end[13] != ":" or end[16] != ":":
        return False
    if not (end[:4] + end[5:7] + end[8:10] + end[11:13] + end[14:16] + end[17:19]).isdigit():
        return False
    if not (int(end[5:7]) >= 1 and int(end[5:7]) <= 12 and int(end[8:10]) >= 1 and int(end[8:10]) <= 31 and int(end[11:13]) <= 23 and int(end[14:16]) <= 59 and int(end[17:19]) <= 60):
        return False
    now = time.now().in_location("UTC").format("2006-01-02T15:04:05Z")
    return end[:19] <= now[:19]

def near_certain(price):
    # Also hide 98.5–98.99% quotes: the whole-percent display would say 99%.
    return int(math.round(price * 100)) >= 99

def change_for(market, period, sign = 1):
    value = number(market.get("oneWeekPriceChange" if period == "week" else "oneDayPriceChange"))
    return value * sign if value != None and abs(value) <= 1 else None

def make_card(event, period):
    if not is_open(event) or not text(event.get("title")):
        return None
    markets = array(event.get("markets"))
    if event.get("negRisk") == True:
        for market in markets:
            parsed = outcome_prices(market)
            if parsed != None and parsed[0] == ["Yes", "No"] and near_certain(parsed[1][0]):
                # A closed/near-certain winner must not promote a losing runner-up.
                return None
    candidates = []
    for market in markets:
        if type(market) != "dict":
            continue
        parsed = market_prices(market)
        if parsed == None:
            continue
        outcomes, prices = parsed
        if event.get("negRisk") == True and outcomes == ["Yes", "No"]:
            # A candidate's No can be 99% without that candidate being the favorite.
            name = text(market.get("groupItemTitle"))
            if not name:
                continue
            candidates.append({"market": market, "name": name, "price": prices[0], "sign": 1})
        else:
            index = 0 if prices[0] >= prices[1] else 1
            if near_certain(prices[index]):
                continue
            candidates.append({"market": market, "name": text(outcomes[index]), "price": prices[index], "sign": 1 if index == 0 else -1})
    if not candidates:
        return None
    if event.get("negRisk") == True:
        favorite = sorted(candidates, key = lambda c: -c["price"])[0]
        title = text(event.get("title"))
    else:
        # Dates, thresholds, and sports props are separate questions, not candidates.
        favorite = sorted(candidates, key = lambda c: -(number(c["market"].get("volume24hr")) or 0))[0]
        title = text(favorite["market"].get("question")) or text(event.get("title"))
    market = favorite["market"]
    if near_certain(favorite["price"]):
        return None
    day_change = change_for(market, "day", favorite["sign"])
    series = text(event.get("seriesSlug"))
    if not series:
        for item in array(event.get("series")):
            if type(item) == "dict" and text(item.get("slug")):
                series = text(item.get("slug"))
                break
    return {
        "id": str(event.get("id", "")),
        "title": title,
        "favorite": favorite["name"],
        "price": favorite["price"],
        "change": change_for(market, period, favorite["sign"]),
        "day_change": day_change,
        "volume": number(event.get("volume24hr")) or 0,
        "series": series,
        "endDate": text(market.get("endDate")),
    }

def request_list(path, params):
    response = http.get(API + path, params = params, ttl_seconds = CACHE_SECONDS)
    if response.status_code != 200:
        return None
    body = response.body()
    if len(body) > 16000000:
        return None
    data = json.decode(body, default = None)
    return data if type(data) == "list" else None

def fetch_events(feed, excluded):
    params = {"active": "true", "closed": "false", "archived": "false", "limit": "30", "order": "volume24hr", "ascending": "false"}
    if feed != "breaking":
        return request_list("/events", params)

    # Both directions matter: a 30-point fall is as notable as a 30-point rise.
    params.update({"limit": "40", "order": "oneDayPriceChange", "include_tag": "true"})
    movers = []
    for ascending in ["false", "true"]:
        params["ascending"] = ascending
        markets = request_list("/markets", params)
        if markets == None:
            return None
        for market in markets:
            if type(market) != "dict" or market_prices(market) == None or not allowed(market, excluded):
                continue
            if change_for(market, "day") != None:
                movers.append(market)
    ids = []
    for market in sorted(movers, key = lambda m: -abs(change_for(m, "day"))):
        for event in array(market.get("events")):
            if not is_open(event):
                continue
            event_id = str(event.get("id", ""))
            if event_id.isdigit() and event_id not in ids:
                ids.append(event_id)
    if not ids:
        return []

    # Fetch complete candidate sets so the favorite isn't inferred from a partial list.
    return request_list("/events?" + "&".join(["id=" + i for i in ids[:24]]), {"limit": "24", "active": "true", "closed": "false"})

def select_pool(events, excluded, period, feed):
    cards = []
    for event in events:
        if type(event) != "dict" or not allowed(event, excluded):
            continue
        card = make_card(event, period)
        if card != None and (feed != "breaking" or card["day_change"] != None):
            cards.append(card)
    if feed == "breaking":
        cards = sorted(cards, key = lambda c: -(abs(c["day_change"])))
    else:
        cards = sorted(cards, key = lambda c: -c["volume"])
    pool = []
    seen = {}
    for card in cards:
        key = "series:" + card["series"] if card["series"] else "event:" + card["id"]
        if key in seen:
            continue
        seen[key] = True
        pool.append(card)
        if len(pool) == POOL_SIZE:
            break
    return pool

def load_pool(feed, excluded, period, now):
    key = "v2:" + feed + ":" + period + ":" + ",".join(excluded)
    saved = json.decode(cache.get(key) or "null", default = None)
    if type(saved) == "dict" and now - saved.get("at", 0) < CACHE_SECONDS:
        cards = cached_cards(saved.get("cards", []))
        if cards or not saved.get("cards"):
            return (cards, False)
    events = fetch_events(feed, excluded)
    if events != None:
        cards = select_pool(events, excluded, period, feed)
        cache.set(key, json.encode({"at": now, "cards": cards}), ttl_seconds = STALE_SECONDS)
        return (cards, False)
    if type(saved) == "dict" and now - saved.get("at", 0) < STALE_SECONDS:
        return (cached_cards(saved.get("cards", [])), True)
    return (None, False)

def cached_cards(cards):
    return [card for card in cards if type(card) == "dict" and number(card.get("price")) != None and not near_certain(card["price"]) and not end_date_passed(card)]

def rotation(pool, now, cards_per_render = 2):
    # Advance a full batch every five-minute slot. With a stable eight-event
    # pool, two cards give AB/CD/EF/GH and three give equal exposure over 8 slots.
    count = len(pool)
    start = ((now // CACHE_SECONDS) * cards_per_render) % count
    return [(start + i) % count for i in range(min(cards_per_render, count))]

def change_label(change):
    if change == None:
        return ("--", MUTED)
    points = int(math.round(abs(change) * 100))
    if points == 0:
        return ("0", MUTED)
    return (("+" if change > 0 else "-") + str(points), UP if change > 0 else DOWN)

def favorite_lines(name):
    # Thirteen CG4x5 glyphs have 64 visible pixels (last spacing pixel is blank).
    lines = []
    line = ""
    for word in name.split():
        if line and len(line) + 1 + len(word) > 13:
            lines.append(line)
            line = ""
        for start in range(0, len(word), 13):
            part = word[start:start + 13]
            if start + 13 < len(word):
                lines.append(part)
            else:
                line = line + " " + part if line else part
    if line:
        lines.append(line)
    return lines or [""]

def card_frame_count(card):
    # Complete title scroll + 1s end hold; each two-line name page gets >=3.5s.
    name_pages = (len(favorite_lines(card["favorite"])) + 1) // 2
    return max(MIN_CARD_FRAMES, 15 + max(0, len(card["title"]) * 5 - 64) + 20, name_pages * 70)

def card_widget(card, stale):
    label, color = change_label(card["change"])
    change = render.Text(label, font = "CG-pixel-4x5-mono", color = color)
    if stale:
        change = render.Column(
            cross_align = "end",
            children = [
                change,
                render.Box(width = 1, height = 1),
                render.Text("OLD", font = "CG-pixel-3x5-mono", color = DOWN),
            ],
        )
    metrics = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Text("{}%".format(int(math.round(card["price"] * 100))), font = "6x13", color = WHITE),
            change,
        ],
    )
    name_lines = favorite_lines(card["favorite"])
    name_pages = (len(name_lines) + 1) // 2
    duration = card_frame_count(card)
    frames = []
    title_text = render.Text(card["title"], font = "5x8", color = WHITE)

    # 5x8 has a five-pixel advance. Stop at the final viewport, never scroll away.
    overflow = max(0, len(card["title"]) * 5 - 64)
    for frame in range(duration):
        offset = min(overflow, max(0, frame - 14))
        title = render.Box(
            width = 64,
            height = 8,
            child = render.Stack(children = [
                render.Box(width = 64, height = 8),
                render.Padding(pad = (-offset, 0, offset, 0), child = title_text),
            ]),
        )
        start = min(name_pages - 1, (frame * name_pages) // duration) * 2
        name = render.Box(
            width = 64,
            height = 11,
            child = render.Stack(children = [
                render.Box(width = 64, height = 11),
                render.Column(children = [
                    render.Text(name_lines[start], font = "CG-pixel-4x5-mono", color = BLUE),
                    render.Box(width = 64, height = 1),
                    render.Text(name_lines[start + 1] if start + 1 < len(name_lines) else " ", font = "CG-pixel-4x5-mono", color = BLUE),
                ]),
            ]),
        )
        frames.append(render.Column(children = [title, name, metrics]))
    return render.Animation(children = frames)

def message_screen(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Text("POLYMARKET", font = "5x8", color = BLUE),
                render.Box(width = 64, height = 3),
                render.WrappedText(message, font = "5x8", color = WHITE, width = 64),
            ],
        ),
        max_age = CACHE_SECONDS,
    )

def main(config):
    feed = "breaking" if config.get("feed") == "breaking" else "trending"
    period = "week" if config.get("period") == "week" else "day"
    excluded = [key for key, _, _ in TOPICS if not config.bool("include_" + key, True)]
    if not config.bool("include_other", True):
        excluded.append("other")
    if len(excluded) == len(TOPICS) + 1:
        return message_screen("Enable a topic")
    now = time.now().unix
    pool, stale = load_pool(feed, excluded, period, now)
    if pool == None:
        return message_screen("Data unavailable")
    if not pool:
        return message_screen("No markets in this feed")
    pages = [card_widget(pool[i], stale) for i in rotation(pool, now)]
    return render.Root(
        child = render.Sequence(children = pages),
        delay = FRAME_DELAY,
        max_age = CACHE_SECONDS if stale else STALE_SECONDS,
        show_full_animation = True,
    )
