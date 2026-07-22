"""
Bloomberg News - a Tidbyt app.

Cycles the latest Bloomberg News headlines under a Bloomberg-style ticker
banner, with the dual-monitor Terminal logo as a wipe between headlines.

Two display modes:
  - "individual": one headline at a time, with the terminal logo sweeping
    across as a wipe between headlines.
  - "continuous": all headlines scroll smoothly, ticker-style.

Data source: Bloomberg's public RSS feeds (feeds.bloomberg.com), no API key.

Author: built for Mike
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

# --- Feeds ----------------------------------------------------------------

FEEDS = {
    "markets": "https://feeds.bloomberg.com/markets/news.rss",
    "business": "https://feeds.bloomberg.com/business/news.rss",
    "technology": "https://feeds.bloomberg.com/technology/news.rss",
    "economics": "https://feeds.bloomberg.com/economics/news.rss",
    "politics": "https://feeds.bloomberg.com/politics/news.rss",
    "wealth": "https://feeds.bloomberg.com/wealth/news.rss",
    "green": "https://feeds.bloomberg.com/green/news.rss",
    "industries": "https://feeds.bloomberg.com/industries/news.rss",
}

# Section display names, matching the Section dropdown's labels below.
CATEGORY_LABELS = {
    "markets": "Markets",
    "business": "Top News",
    "technology": "Technology",
    "economics": "Economics",
    "politics": "Politics",
    "wealth": "Wealth",
    "green": "Green",
    "industries": "Industries",
}

DEFAULT_CATEGORY = "markets"
DEFAULT_COUNT = "5"
DEFAULT_SLOT_COUNT = "3"  # default headline count for the optional Section 2/3 slots
DEFAULT_SPEED = "medium"
DEFAULT_HEADER = "logo_right"
DEFAULT_MODE = "individual"
DEFAULT_TRANSITION = "fade"
DEFAULT_TZ = "America/New_York"
DEFAULT_THEME = "mode1"
DEFAULT_REFRESH = "300"  # seconds; how often headlines are re-fetched

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

# Color themes: banner background/foreground, headline text, timestamp text,
# and the divider under the banner.
THEMES = {
    # White header w/ black text; amber headlines; gray timestamp.
    "mode1": {
        "bg": "#ffffff",
        "fg": "#000000",
        "head": "#ff9900",
        "stamp": "#8a8a8a",
        "divider": "#3a3a3a",
    },
    # Amber header w/ black text; white headlines; blue timestamp.
    "mode2": {
        "bg": "#ff9900",
        "fg": "#000000",
        "head": "#ffffff",
        "stamp": "#3aa0ff",
        "divider": "#332200",
    },
}

# Pace presets: frame delay (ms) + base hold (frames) per headline.
SPEED = {
    "slow": {"delay": 120, "hold": 55},
    "medium": {"delay": 80, "hold": 40},
    "fast": {"delay": 50, "hold": 26},
}

WIPE_FRAMES = 22

TZ_LABELS = {
    "America/New_York": "ET",
    "America/Chicago": "CT",
    "America/Denver": "MT",
    "America/Los_Angeles": "PT",
    "UTC": "UTC",
    "Europe/London": "UK",
    "Europe/Berlin": "CET",
    "Asia/Tokyo": "JST",
    "Asia/Hong_Kong": "HKT",
    "Australia/Sydney": "AEST",
}

# Body geometry (below the 7px banner + 1px divider).
BODY_H = 24
BODY_W = 64
LINE_H = 6  # tom-thumb line height
WRAP_CHARS = 13  # leaves room for the "> " marker

# --- Terminal logo (two screens on a stand, built from pixels) ------------

def terminal_logo(color, screen_w, screen_h, gap, neck_w, neck_h, base_w):
    screen = render.Box(width = screen_w, height = screen_h, color = color)
    return render.Column(
        cross_align = "center",
        children = [
            render.Row(children = [
                screen,
                render.Box(width = gap, height = 1),
                render.Box(width = screen_w, height = screen_h, color = color),
            ]),
            render.Box(width = neck_w, height = neck_h, color = color),  # neck / stand post
            render.Box(width = base_w, height = 1, color = color),  # base
        ],
    )

def banner_logo(color):
    # total width 9 (odd): 1px neck + 5px base center exactly on the gap.
    return terminal_logo(color, 4, 3, 1, 1, 1, 5)  # ~9x5

def wipe_logo(color):
    # Big, dominant logo for the sweep. Width 31 (odd): 3px neck centers on gap.
    return terminal_logo(color, 14, 11, 3, 3, 5, 15)  # ~31x17, narrower base

# --- Data fetching --------------------------------------------------------

def fetch_headlines(url, count, show_time, tz, section, refresh_seconds):
    body = cache.get(url)
    if body == None:
        resp = http.get(url, headers = {"User-Agent": USER_AGENT})
        if resp.status_code != 200:
            return []
        body = resp.body()
        cache.set(url, body, ttl_seconds = refresh_seconds)

    doc = xpath.loads(body)
    titles = doc.query_all("/rss/channel/item/title")
    dates = doc.query_all("/rss/channel/item/pubDate")

    label = TZ_LABELS.get(tz, "")
    out = []
    for i, title in enumerate(titles):
        if i >= count:
            break
        title = title.strip()
        if not title:
            continue
        stamp = ""
        if show_time and i < len(dates):
            stamp = format_stamp(dates[i], tz, label)
        out.append({"title": title, "stamp": stamp, "section": section})
    return out

def format_stamp(pub_date, tz, label):
    """Military-time stamp like '14:26 ET' for an RSS pubDate.

    RSS pubDates end either with a numeric offset ("... -0400") or a named
    zone ("... GMT"); parse_time needs a matching layout for each."""
    if not pub_date:
        return ""
    pub_date = pub_date.strip()
    tzpart = pub_date.split(" ")[-1]
    if tzpart.startswith("+") or tzpart.startswith("-"):
        fmt = "Mon, 02 Jan 2006 15:04:05 -0700"
    else:
        fmt = "Mon, 02 Jan 2006 15:04:05 MST"

    parsed = time.parse_time(pub_date, format = fmt)
    if parsed == None:
        return ""
    local = parsed.in_location(tz)
    hhmm = local.format("15:04")
    return hhmm + " " + label if label else hhmm

# --- Text helpers ---------------------------------------------------------

def wrap(text, max_chars):
    lines = []
    cur = ""
    for word in text.split(" "):
        if len(cur) + (1 if cur else 0) + len(word) <= max_chars:
            cur = (cur + " " + word) if cur else word
        else:
            if cur:
                lines.append(cur)
            cur = ""
            for start in range(0, len(word), max_chars):
                chunk = word[start:start + max_chars]
                if len(chunk) == max_chars:
                    lines.append(chunk)
                else:
                    cur = chunk
    if cur:
        lines.append(cur)
    return lines

def headline_widget(item, head_color, stamp_color):
    """A headline with a leading '>' marker and an optional colored timestamp.

    Returns (widget, line_count)."""
    wrapped = wrap(item["title"], WRAP_CHARS)
    if not wrapped:
        wrapped = [""]

    marker_lines = ["> " + wrapped[0]] + ["  " + ln for ln in wrapped[1:]]
    children = [
        render.Text(content = ln, font = "tom-thumb", color = head_color)
        for ln in marker_lines
    ]
    n = len(marker_lines)
    if item["stamp"]:
        children.append(render.Text(content = "  " + item["stamp"], font = "tom-thumb", color = stamp_color))
        n += 1

    return render.Column(children = children), n

# --- Color interpolation (for the fade transition) ------------------------

_HEXD = "0123456789abcdef"

def _to_hex2(n):
    if n < 0:
        n = 0
    if n > 255:
        n = 255
    return _HEXD[n // 16] + _HEXD[n % 16]

def lerp_hex(a, b, t):
    """Interpolate between two #rrggbb colors; t in [0,1]."""
    ar, ag, ab = int(a[1:3], 16), int(a[3:5], 16), int(a[5:7], 16)
    br, bg, bb = int(b[1:3], 16), int(b[3:5], 16), int(b[5:7], 16)
    r = int(ar + (br - ar) * t)
    g = int(ag + (bg - ag) * t)
    bl = int(ab + (bb - ab) * t)
    return "#" + _to_hex2(r) + _to_hex2(g) + _to_hex2(bl)

# --- Banner ---------------------------------------------------------------

def build_banner(style, theme, category):
    def word(text):
        return render.Padding(
            pad = (3, 1, 0, 0),
            child = render.Text(content = text, font = "CG-pixel-4x5-mono", color = theme["fg"]),
        )

    logo_right_w = render.Padding(pad = (1, 1, 3, 0), child = banner_logo(theme["fg"]))
    logo_left_w = render.Padding(pad = (3, 1, 0, 0), child = banner_logo(theme["fg"]))

    if style == "logo_left":
        section = CATEGORY_LABELS.get(category, "News")
        row = render.Row(expanded = True, cross_align = "center", children = [logo_left_w, word(section)])
    elif style == "wordmark":
        row = render.Row(expanded = True, cross_align = "center", children = [word("Bloomberg")])
    else:  # logo_right: push wordmark left, logo right
        row = render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_between",
            children = [word("Bloomberg"), logo_right_w],
        )

    return render.Box(width = 64, height = 7, color = theme["bg"], child = row)

def _framed(banner, divider, content):
    """Bundle a per-headline banner with the divider and body content into one
    full 64x32 frame, so the header's category can swap in lockstep with the
    body — each Sequence segment carries its own banner rather than the app
    having one banner fixed above an independently-animating body."""
    return render.Column(children = [
        banner,
        divider,
        render.Box(width = BODY_W, height = BODY_H, child = content),
    ])

# --- Overflow scroll (shared by the sweep and fade bodies) ----------------

def _line_count(item):
    n = max(len(wrap(item["title"], WRAP_CHARS)), 1)
    if item["stamp"]:
        n += 1
    return n

def _overflow(n_lines):
    overflow = n_lines * LINE_H - BODY_H
    return overflow if overflow > 0 else 0

# Headlines long enough to scroll get a bonus pause (as a fraction of the
# base hold) after the scroll finishes, so there's time to read the revealed
# bottom lines before fading out.
EXTRA_HOLD_FRACTION = 0.5

def _scroll_duration(hold, overflow):
    """Total hold duration for a headline, including its scroll bonus if any."""
    base = hold + overflow
    if overflow == 0:
        return base
    return base + int(hold * EXTRA_HOLD_FRACTION)

# A Transformation's child is rendered at its own natural (taller) size, and
# the Box that ultimately clips it (the BODY_H-tall body box) centers an
# oversized child before clipping rather than anchoring it to the top. So a
# child taller than BODY_H is already showing a vertically-centered slice at
# rest — the scroll has to run from +half to -half (not 0 to -overflow) to
# land on a top-aligned start and a bottom-aligned end.
def _overflow_keyframes(hold, overflow):
    """Keyframes for a scroll-down-then-pause reveal of text taller than BODY_H.

    The bonus hold from _scroll_duration is added entirely to the trailing
    pause (after the scroll completes) — the initial pause and the scroll
    itself keep the same pacing regardless of headline length.
    """
    if overflow == 0:
        return [
            animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
            animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(0, 0)]),
        ]
    half = overflow // 2
    base = hold + overflow
    total = _scroll_duration(hold, overflow)
    p1 = 0.18 * base / total
    p2 = 0.9 * base / total
    return [
        animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, half)]),
        animation.Keyframe(percentage = p1, transforms = [animation.Translate(0, half)], curve = "ease_in_out"),
        animation.Keyframe(percentage = p2, transforms = [animation.Translate(0, -half)], curve = "ease_in_out"),
        animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(0, -half)]),
    ]

# --- Body: individual (one headline at a time + logo wipe) ----------------

def build_individual(headlines, theme, hold, header):
    divider = render.Box(width = 64, height = 1, color = theme["divider"])
    segments = []
    for item in headlines:
        banner = build_banner(header, theme, item["section"])
        col, n_lines = headline_widget(item, theme["head"], theme["stamp"])
        overflow = _overflow(n_lines)

        text = animation.Transformation(
            child = render.Padding(pad = (1, 0, 0, 0), child = col),
            width = BODY_W,
            height = n_lines * LINE_H,
            duration = _scroll_duration(hold, overflow),
            keyframes = _overflow_keyframes(hold, overflow),
            fill_mode = "forwards",
        )
        segments.append(_framed(banner, divider, text))

        # The wipe carries the outgoing headline's banner — the header swaps
        # to the new category exactly when the new headline's content lands.
        wipe = animation.Transformation(
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [wipe_logo(theme["head"])],
            ),
            width = BODY_W,
            height = BODY_H,
            duration = WIPE_FRAMES,
            keyframes = [
                animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(-32, 0)]),
                animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(BODY_W, 0)]),
            ],
            fill_mode = "forwards",
        )
        segments.append(_framed(banner, divider, wipe))

    return render.Sequence(children = segments)

# --- Body: continuous (smooth vertical ticker) ----------------------------

def build_continuous(headlines, theme):
    blocks = []
    for item in headlines:
        col, _ = headline_widget(item, theme["head"], theme["stamp"])
        blocks.append(render.Padding(pad = (1, 0, 1, 3), child = col))
    blocks.append(render.Box(width = BODY_W, height = BODY_H, child = render.Box(width = 1, height = 1)))

    return render.Marquee(
        height = BODY_H,
        scroll_direction = "vertical",
        offset_start = BODY_H,
        offset_end = BODY_H,
        child = render.Column(children = blocks),
    )

# --- Body: individual with a dip-to-black FADE transition -----------------

BLACK = "#000000"
FADE_IN = 6  # frames to fade a headline / logo in
FADE_OUT = 6  # frames to fade out
LOGO_HOLD = 8  # frames the logo lingers at full color
SLIDE = 4  # px the headline slides while fading in/out

def _text_frame(item, head_color, stamp_color):
    col, _ = headline_widget(item, head_color, stamp_color)
    return render.Padding(pad = (1, 0, 0, 0), child = col)

def _logo_frame(color):
    return render.Box(width = BODY_W, height = BODY_H, child = wipe_logo(color))

def build_fade(headlines, theme, hold, header):
    head, stamp = theme["head"], theme["stamp"]
    divider = render.Box(width = 64, height = 1, color = theme["divider"])
    segments = []
    for item in headlines:
        banner = build_banner(header, theme, item["section"])
        n_lines = _line_count(item)
        overflow = _overflow(n_lines)
        content_h = n_lines * LINE_H
        half = overflow // 2

        # Fade the headline in from black while sliding up into its resting,
        # top-aligned position (matching where the hold's scroll begins).
        # Starts exactly at black (t=0) — the mirror of fade-out, which ends
        # exactly at black — so the logo-to-text switch happens while still
        # invisible instead of popping in already partly lit.
        in_frames = []
        for k in range(FADE_IN):
            t = float(k) / FADE_IN
            in_frames.append(_text_frame(item, lerp_hex(BLACK, head, t), lerp_hex(BLACK, stamp, t)))
        fade_in = animation.Transformation(
            child = render.Animation(children = in_frames),
            width = BODY_W,
            height = content_h,
            duration = FADE_IN,
            keyframes = [
                animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, half + SLIDE)]),
                animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(0, half)], curve = "ease_out"),
            ],
            fill_mode = "forwards",
        )
        segments.append(_framed(banner, divider, fade_in))

        # Hold (this is the readable pause) — scrolls through the headline if
        # it's taller than BODY_H, same as the sweep transition.
        hold_seg = animation.Transformation(
            child = _text_frame(item, head, stamp),
            width = BODY_W,
            height = content_h,
            duration = _scroll_duration(hold, overflow),
            keyframes = _overflow_keyframes(hold, overflow),
            fill_mode = "forwards",
        )
        segments.append(_framed(banner, divider, hold_seg))

        # Fade the headline back out to black while sliding down slightly from
        # the scrolled position the hold left off at, so it doesn't jump back
        # to the top mid-fade.
        out_frames = []
        for k in range(FADE_OUT):
            t = float(k + 1) / FADE_OUT
            out_frames.append(_text_frame(item, lerp_hex(head, BLACK, t), lerp_hex(stamp, BLACK, t)))
        fade_out = animation.Transformation(
            child = render.Animation(children = out_frames),
            width = BODY_W,
            height = content_h,
            duration = FADE_OUT,
            keyframes = [
                animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, -half)]),
                animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(0, -half - SLIDE)], curve = "ease_in"),
            ],
            fill_mode = "forwards",
        )
        segments.append(_framed(banner, divider, fade_out))

        # The logo fades in, holds, then fades out — crossing between
        # headlines. Carries the outgoing headline's banner, same as the
        # sweep transition's wipe — the header swaps to the new category
        # exactly when the new headline's content lands.
        logo_frames = []
        for k in range(FADE_IN):
            t = float(k) / FADE_IN
            logo_frames.append(_logo_frame(lerp_hex(BLACK, head, t)))
        for _k in range(LOGO_HOLD):
            logo_frames.append(_logo_frame(head))
        for k in range(FADE_OUT):
            t = float(k + 1) / FADE_OUT
            logo_frames.append(_logo_frame(lerp_hex(head, BLACK, t)))
        segments.append(_framed(banner, divider, render.Animation(children = logo_frames)))

    return render.Sequence(children = segments)

# --- Main -----------------------------------------------------------------

def _feed_slots(config):
    """The up-to-3 (section, count) pairs selected in the Section 1/2/3 slots."""
    slots = []

    s1 = config.get("section_1", DEFAULT_CATEGORY)
    if s1 not in FEEDS:
        s1 = DEFAULT_CATEGORY
    slots.append((s1, int(config.get("count_1", DEFAULT_COUNT))))

    # Each slot only counts if the one before it is active too, so a stale
    # Section 3 value can't linger in the config and re-apply after Section 2
    # gets set back to "(none)".
    s2 = config.get("section_2", "none")
    if s2 not in FEEDS:
        return slots
    slots.append((s2, int(config.get("count_2", DEFAULT_SLOT_COUNT))))

    s3 = config.get("section_3", "none")
    if s3 not in FEEDS:
        return slots
    slots.append((s3, int(config.get("count_3", DEFAULT_SLOT_COUNT))))

    return slots

def main(config):
    theme = THEMES.get(config.get("theme", DEFAULT_THEME), THEMES[DEFAULT_THEME])
    header = config.get("header", DEFAULT_HEADER)
    mode = config.get("mode", DEFAULT_MODE)
    transition = config.get("transition", DEFAULT_TRANSITION)
    speed = SPEED.get(config.get("speed", DEFAULT_SPEED), SPEED[DEFAULT_SPEED])
    show_time = config.bool("show_time", False)
    tz = config.get("tz", DEFAULT_TZ)
    refresh_seconds = int(config.get("refresh", DEFAULT_REFRESH))

    # A custom feed URL, if provided, overrides the Section slots entirely.
    custom_url = config.get("custom_url", "").strip()
    if custom_url:
        primary_category = DEFAULT_CATEGORY
        headlines = fetch_headlines(custom_url, int(config.get("count_1", DEFAULT_COUNT)), show_time, tz, "", refresh_seconds)
    else:
        slots = _feed_slots(config)
        primary_category = slots[0][0]
        headlines = []
        for section, count in slots:
            headlines.extend(fetch_headlines(FEEDS[section], count, show_time, tz, section, refresh_seconds))

    # "individual" mode swaps the header's category in step with the
    # headlines, so each of its segments already carries its own full
    # banner+divider+body frame. "continuous" mode and the empty state show
    # every headline at once / show no headline at all, so they keep one
    # static banner above the body instead.
    if not headlines:
        banner = build_banner(header, theme, primary_category)
        divider = render.Box(width = 64, height = 1, color = theme["divider"])
        body = render.Box(
            width = BODY_W,
            height = BODY_H,
            child = render.WrappedText(content = "No headlines available", font = "tom-thumb", color = theme["head"], align = "center"),
        )
        root_child = render.Column(children = [banner, divider, body])
    elif mode == "continuous":
        banner = build_banner(header, theme, primary_category)
        divider = render.Box(width = 64, height = 1, color = theme["divider"])
        body = build_continuous(headlines, theme)
        root_child = render.Column(children = [banner, divider, body])
    elif transition == "fade":
        root_child = build_fade(headlines, theme, speed["hold"], header)
    else:
        root_child = build_individual(headlines, theme, speed["hold"], header)

    return render.Root(
        delay = speed["delay"],
        show_full_animation = True,
        child = root_child,
    )

# --- Schema ---------------------------------------------------------------

def _section_options(include_none):
    opts = []
    if include_none:
        opts.append(schema.Option(display = "(none)", value = "none"))
    for value, label in CATEGORY_LABELS.items():
        opts.append(schema.Option(display = label, value = value))
    return opts

def _count_options():
    return [
        schema.Option(display = "1", value = "1"),
        schema.Option(display = "2", value = "2"),
        schema.Option(display = "3", value = "3"),
        schema.Option(display = "5", value = "5"),
        schema.Option(display = "8", value = "8"),
        schema.Option(display = "12", value = "12"),
    ]

def _count_field(id, name, default):
    return schema.Dropdown(
        id = id,
        name = name,
        desc = "How many of the latest headlines to pull from this section.",
        icon = "listOl",
        default = default,
        options = _count_options(),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "theme",
                name = "Color theme",
                desc = "Banner, headline and timestamp colors.",
                icon = "palette",
                default = DEFAULT_THEME,
                options = [
                    schema.Option(display = "White header / amber news", value = "mode1"),
                    schema.Option(display = "Amber header / white news", value = "mode2"),
                ],
            ),
            schema.Dropdown(
                id = "header",
                name = "Header",
                desc = "Style of the top banner.",
                icon = "heading",
                default = DEFAULT_HEADER,
                options = [
                    schema.Option(display = "Bloomberg + logo", value = "logo_right"),
                    schema.Option(display = "Logo + Section", value = "logo_left"),
                    schema.Option(display = "Bloomberg", value = "wordmark"),
                ],
            ),
            schema.Dropdown(
                id = "section_1",
                name = "Section 1",
                desc = "Which Bloomberg section to pull headlines from first.",
                icon = "newspaper",
                default = DEFAULT_CATEGORY,
                options = _section_options(False),
            ),
            _count_field("count_1", "Headlines from Section 1", DEFAULT_COUNT),
            schema.Dropdown(
                id = "section_2",
                name = "Section 2",
                desc = "Optional second section, added after Section 1. Order here sets play order. Set to (none) to leave unused.",
                icon = "newspaper",
                default = "none",
                options = _section_options(True),
            ),
            _count_field("count_2", "Headlines from Section 2", DEFAULT_SLOT_COUNT),
            schema.Dropdown(
                id = "section_3",
                name = "Section 3",
                desc = "Optional third section, added after Section 2. Ignored unless Section 2 is also set.",
                icon = "newspaper",
                default = "none",
                options = _section_options(True),
            ),
            _count_field("count_3", "Headlines from Section 3", DEFAULT_SLOT_COUNT),
            schema.Text(
                id = "custom_url",
                name = "Custom feed URL",
                desc = "Optional. Any RSS feed URL. Overrides all Section slots when set.",
                icon = "link",
                default = "",
            ),
            schema.Dropdown(
                id = "mode",
                name = "Display mode",
                desc = "One headline at a time (with logo wipe) or a continuous scroll.",
                icon = "film",
                default = DEFAULT_MODE,
                options = [
                    schema.Option(display = "One at a time", value = "individual"),
                    schema.Option(display = "Continuous scroll", value = "continuous"),
                ],
            ),
            schema.Dropdown(
                id = "transition",
                name = "Transition",
                desc = "How headlines change in 'one at a time' mode.",
                icon = "wandMagicSparkles",
                default = DEFAULT_TRANSITION,
                options = [
                    schema.Option(display = "Fade (logo dips in/out)", value = "fade"),
                    schema.Option(display = "Sweep (logo slides across)", value = "sweep"),
                ],
            ),
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "How fast headlines advance / scroll.",
                icon = "gaugeHigh",
                default = DEFAULT_SPEED,
                options = [
                    schema.Option(display = "Slow", value = "slow"),
                    schema.Option(display = "Medium", value = "medium"),
                    schema.Option(display = "Fast", value = "fast"),
                ],
            ),
            schema.Dropdown(
                id = "refresh",
                name = "Refresh interval",
                desc = "How often to fetch new headlines from Bloomberg.",
                icon = "arrowsRotate",
                default = DEFAULT_REFRESH,
                options = [
                    schema.Option(display = "5 minutes", value = "300"),
                    schema.Option(display = "10 minutes", value = "600"),
                    schema.Option(display = "15 minutes", value = "900"),
                    schema.Option(display = "30 minutes", value = "1800"),
                    schema.Option(display = "60 minutes", value = "3600"),
                ],
            ),
            schema.Toggle(
                id = "show_time",
                name = "Show timestamp",
                desc = "Append the publish time (military, e.g. 14:26) to each headline.",
                icon = "clock",
                default = False,
            ),
            schema.Dropdown(
                id = "tz",
                name = "Time zone",
                desc = "Zone for the timestamp, if 'Show timestamp' is on.",
                icon = "globe",
                default = DEFAULT_TZ,
                options = [
                    schema.Option(display = "Eastern (ET)", value = "America/New_York"),
                    schema.Option(display = "Central (CT)", value = "America/Chicago"),
                    schema.Option(display = "Mountain (MT)", value = "America/Denver"),
                    schema.Option(display = "Pacific (PT)", value = "America/Los_Angeles"),
                    schema.Option(display = "London (UK)", value = "Europe/London"),
                    schema.Option(display = "Frankfurt (CET)", value = "Europe/Berlin"),
                    schema.Option(display = "Tokyo (JST)", value = "Asia/Tokyo"),
                    schema.Option(display = "Hong Kong (HKT)", value = "Asia/Hong_Kong"),
                    schema.Option(display = "Sydney (AEST)", value = "Australia/Sydney"),
                    schema.Option(display = "UTC", value = "UTC"),
                ],
            ),
        ],
    )
