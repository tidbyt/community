"""
Applet: P(DOOM)
Summary: Countdown to daily doom
Description: A darkly humorous memento-mori countdown to local midnight, interleaved with real, sourced quotations about catastrophic AI risk.
Author: Phil Weldon
"""

load("encoding/json.star", "json")
load("quotes.star", "QUOTES")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ---------------------------------------------------------------------------
# Display and animation model
#
# A Tidbyt never runs this code. The Tidbyt cloud runs it, encodes the result
# as a WebP animation and ships that animation to the device, so what the
# device shows is always a pre-rendered film, not a live clock. The film is
# therefore built so that it ticks by itself: one second of countdown per
# FPS frames, for TOTAL_FRAMES frames. See LIMITATIONS.md.
#
# 60 frames * 250 ms = 15000 ms. That is also pixlet's default maximum
# animation duration (`--max_duration`), but note that the cap only bites
# when `show_full_animation` is false -- with it true, longer animations pass
# through intact. 15 s is kept because it is roughly how long a Tidbyt shows
# one app before rotating, so a longer film would mostly go unseen, and
# because it is the length every check in tests/ was run against.
# ---------------------------------------------------------------------------

FRAME_MS = 250
FPS = 4
TOTAL_FRAMES = 60

# Frame plan for a render that includes a quote.
# The countdown only needs long enough to be read before the cut; the quote
# needs as long as possible, because a three-page quote divides this budget
# by three.
CD_A_FRAMES = 16  # countdown, 4s
GLITCH_FRAMES = 4  # transition, 1s
QUOTE_FRAMES = 36  # quote + attribution, up to 9s (3s per page at worst)

# No single page needs longer than this to read, so a short quote hands its
# unused frames back to the countdown instead of sitting still for nine
# seconds.
MAX_PAGE_FRAMES = 20  # 5s

# How long a cached animation may still be shown. The countdown inside it
# goes stale in real time, so the device is told not to show it late.
MAX_AGE_SECONDS = 60

SECONDS_PER_DAY = 86400

# Quote rotation: a new quote every 5 minutes of wall clock, so the same one
# is never shown continuously. Starlark has no usable source of randomness
# here, and the Tidbyt cloud may render at any moment, so the rotation is a
# deterministic function of the clock instead.
QUOTE_ROTATE_SECONDS = 300

# Layout: the display is 64x32. Vertical bands, top to bottom.
WIDTH = 64
HEIGHT = 32
Y_WORDMARK = 0
H_WORDMARK = 8
Y_CLOCK = 9
H_CLOCK = 13
Y_CAPTION = 23
H_CAPTION = 6
Y_BAR = 30
H_BAR = 2

# Palette: black ground, ember reds and ambers, white for the one word that
# has to read from across the room.
C_BLACK = "#000000"
C_WHITE = "#ffffff"
C_DOOM = "#ff2d10"
C_DOOM_DIM = "#7a1408"
C_PAREN = "#8a2200"
C_CLOCK = "#ffa300"
C_CLOCK_URGENT = "#ff2d10"
C_CAPTION = "#8a3d00"
C_BAR_TRACK = "#1a0500"
C_BAR_FILL = "#b32200"
C_PIP_HOT = "#ff2d10"
C_PIP_COLD = "#3a0a04"
C_QUOTE = "#d9d2c6"
C_ATTRIB = "#ff5a33"

# Captions. Kept to 16 characters so they fit at 4px per glyph.
CAPTIONS = [
    "UNTIL p(DOOM)",
    "TIME REMAINING",
    "USE TODAY WISELY",
]
CAPTION_URGENT = "p(DOOM) IMMINENT"

# Inside this many seconds of midnight the countdown turns red.
URGENT_SECONDS = 300

# Quote text metrics: tom-thumb advances 4px per glyph and is 6px tall, so
# 15 glyphs fit in 60px with a 2px gutter, and 4 lines fit above the
# attribution row.
QUOTE_COLS = 15
QUOTE_ROWS = 4
QUOTE_LINE_H = 6
Y_ATTRIB = 26

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_QUOTE_FREQUENCY = "5"
DEFAULT_INTENSITY = "ominous"
DEBUG_NOW_LAYOUT = "2006-01-02T15:04:05"
DEFAULT_LOCATION = """
{
    "lat": "40.7128",
    "lng": "-74.0060",
    "description": "New York, NY, USA",
    "locality": "New York",
    "timezone": "America/New_York"
}
"""

QUOTE_FREQUENCIES = [
    schema.Option(display = "Never", value = "0"),
    schema.Option(display = "Rarely (a few times an hour)", value = "15"),
    schema.Option(display = "Sometimes (every 5 minutes)", value = "5"),
    schema.Option(display = "Often (every other minute)", value = "2"),
    schema.Option(display = "Always", value = "1"),
]

INTENSITIES = [
    schema.Option(display = "Ominous (blink, pulse, glitch)", value = "ominous"),
    schema.Option(display = "Calm (steady, no glitch)", value = "calm"),
]

GLITCH_CHARS = "#%&@8*!?$"
ASCII_DIGITS = "0123456789"

# ---------------------------------------------------------------------------
# Time
# ---------------------------------------------------------------------------

def resolve_timezone(config):
    """Return the timezone to count down in.

    Order of preference: an explicit `timezone` config value (handy for
    `pixlet render timezone=...` and for `pixlet serve` query parameters),
    then the timezone that comes with the mobile app's location field, then
    a default so the app always renders.
    """
    tz = config.str("timezone")
    if tz:
        return tz

    raw = config.get("location") or DEFAULT_LOCATION
    parsed = json.decode(raw, None)
    if type(parsed) == "dict":
        tz = parsed.get("timezone")

        # A location payload is outside data. `is_valid_timezone` rejects a
        # non-string argument by aborting the render, so the type is checked
        # here rather than there.
        if tz and type(tz) == "string":
            return tz
        if tz:
            print("p(DOOM): location timezone is %s, not a string; ignoring" % type(tz))

    return DEFAULT_TIMEZONE

def days_in_month(year, month):
    if month == 2:
        leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
        return 29 if leap else 28
    if month == 4 or month == 6 or month == 9 or month == 11:
        return 30
    return 31

def is_valid_stamp(s):
    """Is `s` exactly YYYY-MM-DDTHH:MM:SS, and a real instant?

    Starlark has no exception handling, so a timestamp has to be validated
    before `time.parse_time` sees it: an unparseable string there aborts the
    whole render.
    """
    if len(s) != 19:
        return False
    if s[4] != "-" or s[7] != "-" or s[10] != "T" or s[13] != ":" or s[16] != ":":
        return False
    for i in (0, 1, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17, 18):
        if not s[i].isdigit():
            return False

    year = int(s[0:4])
    month = int(s[5:7])
    day = int(s[8:10])
    hour = int(s[11:13])
    minute = int(s[14:16])
    second = int(s[17:19])
    if month < 1 or month > 12:
        return False
    if day < 1 or day > days_in_month(year, month):
        return False
    if hour > 23 or minute > 59 or second > 59:
        return False
    return True

def resolve_now(config, tz):
    """The current time in `tz`.

    `debug_now` is a development aid only: it is not part of get_schema(),
    so it can never be set from the Tidbyt mobile app. It exists so the
    midnight rollover and daylight-saving days can be rendered and looked
    at without waiting for them, e.g.

        pixlet render output/pdoom debug_now=2026-09-16T23:59:55
    """
    override = config.str("debug_now")
    if override:
        if is_valid_stamp(override):
            return time.parse_time(override, DEBUG_NOW_LAYOUT, tz).in_location(tz)
        print("p(DOOM): ignoring debug_now=%r, expected %s" % (override, DEBUG_NOW_LAYOUT))
    return time.now().in_location(tz)

def same_local_date(a, b):
    return a.year == b.year and a.month == b.month and a.day == b.day

def next_local_midnight(tz, now):
    """The first instant of the next local day in `tz`, strictly after `now`.

    On almost every day that instant is 00:00:00. It is not always: a few
    zones move their clocks forward *at* midnight, so local midnight does not
    exist on that date at all. `America/Santiago`, `America/Havana` and
    `Atlantic/Azores` all do this, and in those zones 23:59:59 is followed
    directly by 01:00:00.

    Constructing `time.time(hour = 0, ...)` for such a date asks Go for an
    instant that never happened, and Go normalises it — in a direction it
    does not guarantee. Observed: `Africa/Cairo` and `Asia/Beirut` normalise
    forward to 01:00 (harmless), while `America/Havana`, `America/Santiago`
    and `Atlantic/Azores` normalise *backward* into the previous day, which
    made the countdown target 23:00 and then run negative for the last hour
    of the day.

    So the boundary is found by bisection on absolute time instead, which
    needs no assumption about normalisation direction: 26 hours ahead is
    always a later local date whatever the offset does, and the first instant
    whose local date differs from `now`'s is the answer. Exact to the second
    in 20 steps.
    """
    calendar_midnight = time.time(
        year = now.year,
        month = now.month,
        day = now.day,
        hour = 0,
        minute = 0,
        second = 0,
        location = tz,
    ) + time.parse_duration("36h")
    candidate = time.time(
        year = calendar_midnight.year,
        month = calendar_midnight.month,
        day = calendar_midnight.day,
        hour = 0,
        minute = 0,
        second = 0,
        location = tz,
    )

    # The fast path: a real midnight, after now, and the first moment of its
    # own day. That last condition is what rules out a normalised-away
    # midnight, which always lands inside a day that has already started.
    if candidate.hour == 0 and candidate.minute == 0 and candidate.second == 0:
        if int((candidate - now).seconds) > 0 and not same_local_date(candidate, now):
            return candidate

    lo = 0
    hi = 26 * 3600
    for _ in range(20):
        if hi - lo <= 1:
            break
        mid = (lo + hi) // 2
        probe = now + time.parse_duration("%ds" % mid)
        if same_local_date(probe, now):
            lo = mid
        else:
            hi = mid
    return now + time.parse_duration("%ds" % hi)

def seconds_until(later, earlier):
    return int((later - earlier).seconds)

def remaining_at(start_remaining, elapsed, next_day_seconds = SECONDS_PER_DAY):
    """Seconds to midnight `elapsed` seconds into the animation.

    Wraps through midnight so an animation that starts at 23:59:55 keeps
    counting on the far side of the rollover instead of going negative.

    The wrap only applies once the countdown has actually passed zero. It
    must not touch a value above 86400, which is legitimate on the day a
    daylight-saving shift makes the local day 25 hours long.

    `next_day_seconds` is how long the day on the far side of the rollover
    actually is. It is not always 86400: on the eve of a daylight-saving
    shift the countdown restarts into a 23- or 25-hour day, and assuming a
    flat day put the display an hour out for the few seconds of animation
    after the rollover.
    """
    r = start_remaining - elapsed
    if r > 0:
        return r
    return ((r - 1) % next_day_seconds) + 1

def pad2(n):
    """Zero-pad to two digits. Starlark's % has no width specifiers."""
    if n < 10:
        return "0" + str(n)
    return str(n)

def hms(total):
    """Format seconds as HH:MM:SS.

    The hour field can legitimately read 24 on the day a daylight-saving
    shift makes the local day 25 hours long.
    """
    return pad2(total // 3600) + ":" + pad2((total % 3600) // 60) + ":" + pad2(total % 60)

# ---------------------------------------------------------------------------
# Deterministic pseudo-randomness (Starlark has no rand)
# ---------------------------------------------------------------------------

def lcg(seed):
    return (seed * 1103515245 + 12345) % 2147483648

# ---------------------------------------------------------------------------
# Text wrapping
# ---------------------------------------------------------------------------

def hard_split(word, cols):
    """Break a word too long for one line, hyphenating the break.

    Only one word in the dataset needs this ("ultraintelligent", 16
    characters against a 15-character line), and splitting it silently
    rendered as "ultraintelligen" / "t machine", which reads as a typo.
    """
    pieces = []
    chunk = cols - 1
    for start in range(0, len(word), chunk):
        piece = word[start:start + chunk]
        if start + chunk < len(word):
            piece += "-"
        pieces.append(piece)
    return pieces

def wrap(text, cols):
    """Greedy word wrap to `cols` characters per line."""
    lines = []
    current = ""
    for raw_word in text.split(" "):
        if not raw_word:
            continue
        for word in (hard_split(raw_word, cols) if len(raw_word) > cols else [raw_word]):
            if not current:
                current = word
            elif len(current) + 1 + len(word) <= cols:
                current = current + " " + word
            else:
                lines.append(current)
                current = word
    if current:
        lines.append(current)
    return lines

def paginate(lines, rows):
    """Split lines into pages of at most `rows`, balanced.

    Filling each page to the brim leaves the last one nearly empty -- a
    five-line quote became a four-line page followed by a single orphan
    line. Using the same number of pages but spreading the lines evenly
    across them reads far better on a screen this small.
    """
    if not lines:
        return [[]]
    pages = (len(lines) + rows - 1) // rows
    base = len(lines) // pages
    extra = len(lines) % pages
    out = []
    start = 0
    for index in range(pages):
        take = base + (1 if index < extra else 0)
        out.append(lines[start:start + take])
        start += take
    return out

# ---------------------------------------------------------------------------
# Widgets
# ---------------------------------------------------------------------------

def band(y, height, child):
    """Place `child` centred in a full-width band whose top edge is at `y`."""
    return render.Padding(
        pad = (0, y, 0, 0),
        child = render.Box(width = WIDTH, height = height, child = child),
    )

def screen(children):
    """A 64x32 black canvas with absolutely placed children on top."""
    return render.Stack(
        children = [render.Box(width = WIDTH, height = HEIGHT, color = C_BLACK)] + children,
    )

def pip(hot):
    return render.Circle(diameter = 5, color = C_PIP_HOT if hot else C_PIP_COLD)

def wordmark(hot):
    """p(DOOM), with the DOOM carrying the colour."""
    return render.Row(
        main_align = "center",
        cross_align = "center",
        children = [
            pip(hot),
            render.Box(width = 3, height = 1),
            render.Text("p", color = C_WHITE),
            render.Text("(", color = C_PAREN),
            render.Text("DOOM", color = C_DOOM if hot else C_DOOM_DIM),
            render.Text(")", color = C_PAREN),
            render.Box(width = 3, height = 1),
            pip(hot),
        ],
    )

def day_bar(elapsed_fraction, blink):
    """How much of today is already gone, as a bar with a moving head."""
    filled = int(WIDTH * elapsed_fraction)
    if filled < 1:
        filled = 1
    if filled > WIDTH:
        filled = WIDTH
    head = filled - 1
    if head > WIDTH - 1:
        head = WIDTH - 1
    return render.Stack(
        children = [
            render.Box(width = WIDTH, height = H_BAR, color = C_BAR_TRACK),
            render.Box(width = filled, height = H_BAR, color = C_BAR_FILL),
            render.Padding(
                pad = (head, 0, 0, 0),
                child = render.Box(width = 1, height = H_BAR, color = C_WHITE if blink else C_DOOM),
            ),
        ],
    )

def countdown_frame(left, elapsed_fraction, caption, blink, hot):
    """The primary screen."""
    urgent = left <= URGENT_SECONDS
    text = hms(left)
    if blink:
        text = text.replace(":", " ")
    return screen([
        band(Y_WORDMARK, H_WORDMARK, wordmark(hot)),
        band(Y_CLOCK, H_CLOCK, render.Text(
            content = text,
            font = "6x13",
            color = C_CLOCK_URGENT if urgent else C_CLOCK,
        )),
        band(Y_CAPTION, H_CAPTION, render.Text(
            content = CAPTION_URGENT if urgent else caption,
            font = "tom-thumb",
            color = C_DOOM if urgent else C_CAPTION,
        )),
        render.Padding(pad = (0, Y_BAR, 0, 0), child = day_bar(elapsed_fraction, blink)),
    ])

def midnight_frame(flash):
    """The joke, delivered: at midnight p(DOOM) resolves to 1.00."""
    return screen([
        band(4, H_CLOCK, render.Text(
            content = "p(DOOM)",
            font = "6x13",
            color = C_WHITE if flash else C_DOOM,
        )),
        band(20, H_CAPTION, render.Text(
            content = "= 1.00",
            font = "tom-thumb",
            color = C_DOOM if flash else C_CLOCK,
        )),
        band(26, H_CAPTION, render.Text(
            content = "SEE YOU TOMORROW",
            font = "tom-thumb",
            color = C_CAPTION,
        )),
    ])

def glitch_frame(left, seed):
    """A brief corruption of the countdown on the way into a quote.

    Deterministic, but guaranteed to actually corrupt something: the digit
    at `forced` is always replaced, so the transition never renders as an
    ordinary countdown frame.
    """
    digits = hms(left)
    noise = lcg(seed)
    forced = (noise // 3) % 6
    digit_positions = [0, 1, 3, 4, 6, 7]
    corrupted = ""
    for i in range(len(digits)):
        noise = lcg(noise)
        is_digit = i != 2 and i != 5
        if is_digit and (i == digit_positions[forced] or noise % 3 == 0):
            corrupted += GLITCH_CHARS[(noise // 7) % len(GLITCH_CHARS)]
        else:
            corrupted += digits[i]
    shift = (noise // 11) % 7 - 3
    scan_y = (noise // 13) % (HEIGHT - 3)
    return screen([
        band(Y_WORDMARK, H_WORDMARK, wordmark(noise % 2 == 0)),
        render.Padding(
            pad = (8 + shift, Y_CLOCK, 0, 0),
            child = render.Text(content = corrupted, font = "6x13", color = C_DOOM),
        ),
        render.Padding(
            pad = (0, scan_y, 0, 0),
            child = render.Box(width = WIDTH, height = 2, color = C_DOOM_DIM),
        ),
        render.Padding(
            pad = ((noise // 17) % 40, Y_CAPTION, 0, 0),
            child = render.Box(width = 20, height = 3, color = C_PAREN),
        ),
    ])

def quote_frame(page, speaker_short):
    """One page of a quotation, with its attribution always on screen."""
    lines = []
    for line in page:
        lines.append(render.Text(content = line, font = "tom-thumb", color = C_QUOTE))

    # Centre the block vertically in the space above the attribution row, so
    # a short page does not sit awkwardly at the top.
    top = (Y_ATTRIB - len(page) * QUOTE_LINE_H) // 2
    if top < 0:
        top = 0
    return screen([
        render.Padding(
            pad = (2, top, 0, 0),
            child = render.Column(children = lines),
        ),
        render.Padding(
            pad = (2, Y_ATTRIB, 0, 0),
            child = render.Text(
                content = "- " + speaker_short,
                font = "CG-pixel-3x5-mono",
                color = C_ATTRIB,
            ),
        ),
    ])

# ---------------------------------------------------------------------------
# Frame assembly
# ---------------------------------------------------------------------------

def countdown_frames(count, first_frame, start_remaining, animated, next_day_seconds = SECONDS_PER_DAY):
    frames = []
    for i in range(count):
        frame_index = first_frame + i
        elapsed = frame_index // FPS
        left = remaining_at(start_remaining, elapsed, next_day_seconds)
        overshoot = start_remaining - elapsed

        if overshoot <= 0 and overshoot > -4:
            # The clock just struck midnight inside this animation.
            frames.append(midnight_frame(animated and frame_index % 2 == 0))
            continue

        caption = CAPTIONS[(start_remaining // 60) % len(CAPTIONS)]
        blink = animated and (frame_index % FPS) >= FPS // 2
        hot = (not animated) or (frame_index % FPS) < FPS // 2
        fraction = float(SECONDS_PER_DAY - left) / float(SECONDS_PER_DAY)
        frames.append(countdown_frame(left, fraction, caption, blink, hot))
    return frames

def quote_frames(quote):
    """Frames for one quotation: at most QUOTE_FRAMES, possibly fewer.

    A one-page quote returns a shorter list, and `main` gives the leftover
    frames to the closing countdown. Holding four lines of text on screen for
    nine seconds reads as the app having frozen.
    """
    pages = paginate(wrap(quote["display"], QUOTE_COLS), QUOTE_ROWS)
    per_page = QUOTE_FRAMES // len(pages)
    if per_page > MAX_PAGE_FRAMES:
        per_page = MAX_PAGE_FRAMES
    frames = []
    for page in pages:
        frames.extend([quote_frame(page, quote["speaker_short"])] * per_page)

    # Integer division can leave a frame or two over; hold the last page, but
    # never past the quote budget.
    spare = QUOTE_FRAMES - len(frames)
    if per_page == MAX_PAGE_FRAMES:
        spare = 0
    for _ in range(spare):
        frames.append(quote_frame(pages[-1], quote["speaker_short"]))
    return frames

def quote_index(unix_seconds):
    """Which quote to show at a given instant.

    A plain `(unix // 300) % len(QUOTES)` walks the list in step, which
    phase-locks against the "show a quote every N minutes" gate: at N = 15
    the index advanced by exactly 3 each time it was sampled and only ever
    reached a third of the dataset. Mixing the minute through an LCG first
    decorrelates the two, so every sampling interval reaches every quote.
    """
    return (lcg(unix_seconds // 60) // 977) % len(QUOTES)

def pick_quote(now):
    return QUOTES[quote_index(now.unix)]

def is_ascii_digits(value):
    if not value:
        return False
    for i in range(len(value)):
        if not ASCII_DIGITS.count(value[i]):
            return False
    return True

def quote_interval(config):
    """Minutes between quote appearances, 0 meaning never.

    Anything that is not a plain non-negative integer falls back to the
    default rather than failing the render. Pixlet's own guidance is that an
    app must always be able to render whatever config it is handed.
    """
    raw = config.str("quote_frequency", DEFAULT_QUOTE_FREQUENCY)

    # Not `.isdigit()`: that accepts Unicode digits such as U+0665 ARABIC-
    # INDIC DIGIT FIVE, which `int()` then refuses, aborting the render.
    if not is_ascii_digits(raw):
        if raw != DEFAULT_QUOTE_FREQUENCY:
            print("p(DOOM): bad quote_frequency %r, using %s" % (raw, DEFAULT_QUOTE_FREQUENCY))
        return int(DEFAULT_QUOTE_FREQUENCY)
    return int(raw)

def wants_quote(config, now):
    interval = quote_interval(config)
    if interval == 0:
        return False
    if interval <= 1:
        return True
    return now.minute % interval == 0

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main(config):
    tz = resolve_timezone(config)

    # "Local" and "UTC" are both accepted by is_valid_timezone, but "Local"
    # means "whatever timezone this process is in" -- in the Tidbyt cloud
    # that is a server, not the user, so it is treated as unusable.
    if tz == "Local" or not time.is_valid_timezone(tz):
        print("p(DOOM): unusable timezone %r, falling back to %s" % (tz, DEFAULT_TIMEZONE))
        tz = DEFAULT_TIMEZONE

    now = resolve_now(config, tz)
    midnight = next_local_midnight(tz, now)
    start_remaining = seconds_until(midnight, now)
    animated = config.str("intensity", DEFAULT_INTENSITY) != "calm"

    # How long the day on the far side of midnight is, so that an animation
    # which rolls over on the eve of a daylight-saving shift restarts at the
    # right number rather than at a flat 23:59:59.
    next_day = seconds_until(next_local_midnight(tz, midnight), midnight)

    if wants_quote(config, now):
        quote = pick_quote(now)
        frames = countdown_frames(CD_A_FRAMES, 0, start_remaining, animated, next_day)
        if animated:
            for i in range(GLITCH_FRAMES):
                left = remaining_at(start_remaining, (CD_A_FRAMES + i) // FPS, next_day)
                frames.append(glitch_frame(left, now.unix + i))
        else:
            frames.extend(countdown_frames(GLITCH_FRAMES, CD_A_FRAMES, start_remaining, animated, next_day))
        frames.extend(quote_frames(quote))

        # Whatever the quote did not use goes back to the countdown, so every
        # render is exactly TOTAL_FRAMES long however many pages the quote
        # needed.
        frames.extend(countdown_frames(
            TOTAL_FRAMES - len(frames),
            len(frames),
            start_remaining,
            animated,
            next_day,
        ))
    else:
        frames = countdown_frames(TOTAL_FRAMES, 0, start_remaining, animated, next_day)

    return render.Root(
        delay = FRAME_MS,
        max_age = MAX_AGE_SECONDS,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Sets the timezone whose midnight p(DOOM) counts down to.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "quote_frequency",
                name = "Quote frequency",
                desc = "How often a verified AI-risk quotation interrupts the countdown.",
                icon = "quoteLeft",
                default = DEFAULT_QUOTE_FREQUENCY,
                options = QUOTE_FREQUENCIES,
            ),
            schema.Dropdown(
                id = "intensity",
                name = "Animation",
                desc = "How much the display flickers, pulses and glitches.",
                icon = "wandMagicSparkles",
                default = DEFAULT_INTENSITY,
                options = INTENSITIES,
            ),
        ],
    )
