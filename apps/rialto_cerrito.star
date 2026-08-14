"""
Applet: Rialto Cerrito
Summary: Showtimes at Rialto Cinemas Cerrito
Description: Now-playing films and today's showtimes at Rialto Cinemas Cerrito, the
independent art deco movie house in El Cerrito, California. Bargain-priced showings
(the theater's discounted first show before 5:30pm) are shown in green. Rolls forward to
tomorrow once the last show of the day has started, and can flag upcoming one-off
special events such as National Theatre Live broadcasts.
Author: rialto-cerrito-showtimes
"""

load("animation.star", "animation")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

URL = "https://rialtocinemas.com/now-playing-cer/"
TZ = "America/Los_Angeles"  # the theater's clock, not the viewer's
TTL = 3600

RED = "#ff2d1a"
AMBER = "#ffb000"
GREEN = "#37d13f"
CYAN = "#2ec4d6"
WHITE = "#ffffff"
DIM = "#6b1e12"

TOTAL_FRAMES = 300
CHAR_W = 5  # CG-pixel-4x5-mono advances 5px per glyph (measured, not assumed)
CHARS_PER_LINE = 12  # 64 / CHAR_W
UPCOMING_MAX = 2
UPCOMING_HORIZON = 14  # days
MONDAY_TAG = "$9.50"  # "$9.50 MOVIES all day on MONDAYS", excludes special events

WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
MONTHS = {
    "Jan": 1,
    "Feb": 2,
    "Mar": 3,
    "Apr": 4,
    "May": 5,
    "Jun": 6,
    "Jul": 7,
    "Aug": 8,
    "Sep": 9,
    "Oct": 10,
    "Nov": 11,
    "Dec": 12,
}

ENTITIES = [
    ("&#8217;", "'"),
    ("&#8216;", "'"),
    ("&#8220;", "\""),
    ("&#8221;", "\""),
    ("&#8212;", "-"),
    ("&#8211;", "-"),
    ("&#8230;", "..."),
    ("&#038;", "&"),
    ("&amp;", "&"),
    ("&nbsp;", " "),
    ("&#160;", " "),
    ("&quot;", "\""),
    ("&#39;", "'"),
    ("&lt;", "<"),
    ("&gt;", ">"),
]

# ---------------------------------------------------------------- html helpers

def clean(s):
    """Strip tags and decode the entities WordPress actually emits."""
    s = re.sub("<[^>]*>", " ", s)
    for a, b in ENTITIES:
        s = s.replace(a, b)
    return " ".join(s.split())

def split_lines(raw):
    """The site pairs each date with its showtimes using <br> inside one element."""
    return [clean(p) for p in re.split("<br\\s*/?>", raw)]

# ------------------------------------------------------------------- date bits

def parse_daymonth(s):
    """'Fri, Aug 14' -> (8, 14). None if there's no month/day in there."""
    for hit in re.findall("[A-Z][a-z][a-z][a-z]*\\.?\\s+\\d{1,2}", s):
        parts = hit.replace(".", " ").split()
        if len(parts) < 2:
            continue
        mon = MONTHS.get(parts[0][0:3])
        if mon != None:
            return (mon, int(parts[1]))
    return None

def is_schedule_heading(s):
    """Headings like 'Monday, August 10 6:30pm' are a schedule, not a film title."""
    first = s.split(",")[0].strip()
    return first[0:3] in WEEKDAYS

# ------------------------------------------------------------------ time logic

def to_minutes(hour, minute):
    """The site omits am/pm. Cinema hours: 10 and 11 are morning, the rest afternoon."""
    if hour == 12:
        return 12 * 60 + minute
    elif hour >= 10:
        return hour * 60 + minute
    return (hour + 12) * 60 + minute

def parse_times(line):
    """'(11:00) 2:05, 5:10' -> showings. Parentheses mean the bargain price."""
    out = []
    for tok in re.findall("\\(?\\d{1,2}:\\d{2}\\)?", line):
        bare = tok.replace("(", "").replace(")", "")
        parts = bare.split(":")
        out.append({
            "show": bare,
            "minutes": to_minutes(int(parts[0]), int(parts[1])),
            "bargain": tok.startswith("("),
        })
    return out

# ---------------------------------------------------------------- page parsing

def fetch_films():
    """[{title, days: {(month, day): [showings]}}], or None if the page can't be read."""
    resp = http.get(URL, ttl_seconds = TTL)
    if resp.status_code != 200:
        return None

    body = resp.body()
    start = body.find("entry-content")
    end = body.find("<footer")
    if start > 0 and end > start:
        body = body[start:end]

    # Every schedule lives in a two-column block tagged with this class.
    chunks = body.split("is-not-stacked-on-mobile")
    if len(chunks) < 2:
        return None

    films = []
    for i in range(1, len(chunks)):
        cells = re.findall("(?s)<h2[^>]*>.*?</h2>|<p[^>]*>.*?</p>", chunks[i])
        if len(cells) < 2:
            continue

        date_lines = split_lines(cells[0])
        time_lines = split_lines(cells[1])

        days = {}
        for j in range(len(date_lines)):
            if j >= len(time_lines):
                break
            dm = parse_daymonth(date_lines[j])
            if dm == None:
                continue
            times = parse_times(time_lines[j])
            if times:
                days[dm] = times

        if not days:
            continue

        # A film's <h1> is the last real heading before its schedule block.
        title = ""
        for h in re.findall("(?s)<h1[^>]*>.*?</h1>", chunks[i - 1]):
            t = clean(h)
            if t and t != "Now Playing" and not is_schedule_heading(t):
                title = t
        if not title:
            continue

        # Regular runs sell through formovietickets; special events go elsewhere.
        # This matters because the Monday deal excludes special events.
        films.append({
            "title": title,
            "days": days,
            "regular": chunks[i].find("formovietickets.com") > 0,
        })

    return films

# ----------------------------------------------------------------- day picking

def day_series(now):
    """Ordered upcoming days: [{key, weekday, label}], starting today."""
    out = []
    for i in range(0, UPCOMING_HORIZON + 1):
        d = now + time.parse_duration("%dh" % (24 * i))
        out.append({
            "key": (int(d.format("1")), int(d.format("2"))),
            "weekday": d.format("Mon").upper(),
            "label": d.format("Mon Jan 2").upper(),
        })
    return out

def showings_for(films, key, after_minutes):
    """Films playing on `key`, keeping only showtimes still to come."""
    out = []
    for f in films:
        times = f["days"].get(key)
        if times == None:
            continue
        remaining = [t for t in times if t["minutes"] > after_minutes]
        if remaining:
            out.append({"title": f["title"], "times": remaining, "regular": f["regular"]})
    return out

def upcoming_for(films, days, showing_titles, from_index):
    """One-off events not on screen today: earliest future date for each film."""
    out = []
    for f in films:
        if f["title"] in showing_titles:
            continue
        for i in range(from_index, len(days)):
            if f["days"].get(days[i]["key"]) != None:
                out.append({"title": f["title"], "when": days[i]["label"], "sort": i})
                break
    return sorted(out, key = lambda e: e["sort"])[0:UPCOMING_MAX]

# ------------------------------------------------------------------ the screen

def pack(times, all_cheap):
    """Fit showtimes into two short lines. Colour, not punctuation, marks the deals."""
    toks = [{"text": t["show"], "cheap": all_cheap or t["bargain"]} for t in times]

    lines = []
    cur = []
    width = 0
    used = 0
    for tok in toks:
        add = len(tok["text"]) if not cur else len(tok["text"]) + 2
        if width + add <= CHARS_PER_LINE:
            cur.append(tok)
            width += add
            used += 1
        elif len(lines) == 0:
            lines.append(cur)
            cur = [tok]
            width = len(tok["text"])
            used += 1
        else:
            break
    if cur:
        lines.append(cur)

    # If showtimes didn't fit, say so rather than silently dropping them.
    if used < len(toks) and lines:
        last = lines[len(lines) - 1]
        tail = last[len(last) - 1]
        last[len(last) - 1] = {"text": tail["text"] + "+", "cheap": tail["cheap"]}
    return lines

def at(x, y, child):
    return render.Padding(pad = (x, y, 0, 0), child = child)

def small(txt, color):
    return render.Text(content = txt, font = "CG-pixel-4x5-mono", color = color, height = 5)

def times_widget(toks):
    """Green for discounted showings, amber for full price."""
    kids = []
    for idx in range(len(toks)):
        if idx > 0:
            kids.append(small("  ", AMBER))
        kids.append(small(toks[idx]["text"], GREEN if toks[idx]["cheap"] else AMBER))
    return render.Row(children = kids)

def frame(title, tag, tag_color, rows):
    kids = [
        at(0, 1, small("RIALTO", RED)),
        at(64 - CHAR_W * len(tag), 1, small(tag, tag_color)),
        at(0, 7, render.Box(width = 64, height = 1, color = DIM)),
        at(0, 10, render.Marquee(
            width = 64,
            offset_start = 64,
            offset_end = 64,
            align = "center",
            child = render.Text(content = title, font = "tb-8", color = WHITE),
        )),
    ]
    for idx in range(len(rows)):
        kids.append(at(0, 20 + 6 * idx, rows[idx]))
    return render.Stack(children = kids)

def showing_card(entry, day_label, monday):
    """On Mondays every regular admission is $9.50, so the bargain star is moot."""
    deal = monday and entry["regular"]
    tag = MONDAY_TAG if deal else day_label
    rows = [times_widget(l) for l in pack(entry["times"], deal)]
    return frame(entry["title"], tag, GREEN if deal else DIM, rows)

def upcoming_card(entry):
    return frame(entry["title"], "SOON", CYAN, [small(entry["when"], CYAN)])

def notice(line1, line2):
    return render.Stack(children = [
        at(0, 1, small("RIALTO", RED)),
        at(0, 7, render.Box(width = 64, height = 1, color = DIM)),
        at(0, 12, render.Text(content = line1, font = "tb-8", color = WHITE)),
        at(0, 23, small(line2, AMBER)),
    ])

def hold(child, frames):
    return animation.Transformation(
        child = child,
        duration = frames,
        keyframes = [
            animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
            animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(0, 0)]),
        ],
    )

# ------------------------------------------------------------------------ main

def main(config):
    show_upcoming = config.bool("show_upcoming", True)

    now = time.now().in_location(TZ)
    films = fetch_films()
    if films == None:
        return render.Root(child = notice("Rialto", "SHOWTIMES OFFLINE"))

    days = day_series(now)
    day_index = 0
    showings = showings_for(films, days[0]["key"], now.hour * 60 + now.minute)
    if not showings:
        day_index = 1
        showings = showings_for(films, days[1]["key"], -1)

    monday = days[day_index]["weekday"] == "MON"
    cards = [showing_card(s, days[day_index]["weekday"], monday) for s in showings]

    if show_upcoming:
        titles = [s["title"] for s in showings]
        for u in upcoming_for(films, days, titles, day_index + 1):
            cards.append(upcoming_card(u))

    if not cards:
        return render.Root(child = notice("Rialto", "NO SHOWTIMES"))

    per = TOTAL_FRAMES // len(cards)
    return render.Root(
        delay = 50,
        child = render.Sequence(children = [hold(c, per) for c in cards]),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_upcoming",
                name = "Coming up",
                desc = "Also flag upcoming one-off events, like National Theatre Live broadcasts.",
                icon = "calendar",
                default = True,
            ),
        ],
    )
