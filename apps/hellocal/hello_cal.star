"""
my_calendar.star — Tidbyt/Pixlet app

Shows the next relevant event from a private Google Calendar iCal feed,
with a pixel-precise three-row layout on the 64x32 display.

LAYOUT (64x32, origin top-left)
  ROW 1  calendar3.png icon (8x8) at x=2,y=2  +  date in magenta
  ROW 2  event title (white, as written), marquee-scrolled full width
  ROW 3  time in yellow ("H:MM am/pm" or "All day"), near the bottom

  All text uses the standard Tidbyt font "tb-8" (baseline = box top + 7,
  lowest glyph pixel = box top + 6).

  Static content keeps a 3px margin on every edge; the Row 2 title marquee is
  exempt and runs full width edge to edge.
    - Icon: 8x8 at x=3, y=3                            -> icon bottom edge y=11
    - Date: x=14 (3px gap), baseline 1px above icon bottom edge (y=10) -> box top y=3
    - Row 2 title: full-width marquee                  -> y=14
    - Row 3 bottom: lowest pixel at row 28 (3px gap)   -> text box top y=22

  Note: Pixlet runs in a sandbox with no filesystem access, so the
  8x8 "calendar3.png" in this folder is embedded below as base64 and
  decoded at render time for render.Image.
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# The private iCal feed URL is NOT stored in this file. It is supplied at
# runtime via Pixlet config: config.get("ical_url"). In CI, push.sh passes it
# from the ICAL_URL GitHub Secret. For local preview, pass it on the command
# line, e.g.:  pixlet render my_calendar.star ical_url="https://..."

LOCATION = "America/Los_Angeles"

# Colors
PINK = "#FF69B4"
WHITE = "#FFFFFF"
YELLOW = "#FFD700"
BLACK = "#000000"

FONT = "tb-8"

MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

TTL_SECONDS = 300  # cache the iCal fetch for 5 minutes

# Two-line phrases shown on days with zero events scheduled.
# Selected by date ordinal (stable all day, changes at midnight).
QUIET_PHRASES = [
    ["Today is", "a blank page"],
    ["Time to", "breathe"],
    ["The day is", "wide open"],
    ["No agenda,", "no rush."],
    ["Let the good", "times roll"],
    ["Room to", "wander"],
]
PREPARATION_TIME = 15 * 60  # seconds: show next event this early before it starts
PERSISTENCE_TIME = 10 * 60  # seconds: extended events show for this long before deferring
EXTENDED_THRESHOLD = 4 * 60 * 60  # seconds: events longer than this are "extended" (flights, etc.)

# tb-8 per-character advance widths in pixels (measured empirically). Used to
# decide whether a title fits without scrolling. A rendered string's pixel
# width = sum(advances) - 1.
CHAR_ADV = {"!": 2, "'": 2, ".": 2, ":": 2, " ": 3, "(": 3, ")": 3, ",": 3, "+": 4, "-": 4, "?": 4, "I": 4, "J": 4, "T": 4, "c": 4, "i": 4, "j": 4, "l": 4, "s": 4, "v": 4, "&": 5, "/": 5, "0": 5, "1": 5, "2": 5, "3": 5, "4": 5, "5": 5, "6": 5, "7": 5, "8": 5, "9": 5, "A": 5, "B": 5, "C": 5, "D": 5, "E": 5, "F": 5, "G": 5, "H": 5, "K": 5, "L": 5, "N": 5, "O": 5, "P": 5, "Q": 5, "R": 5, "S": 5, "U": 5, "X": 5, "Z": 5, "a": 5, "b": 5, "d": 5, "e": 5, "f": 5, "g": 5, "h": 5, "k": 5, "n": 5, "o": 5, "p": 5, "q": 5, "r": 5, "t": 5, "u": 5, "x": 5, "y": 5, "z": 5, "M": 6, "V": 6, "W": 6, "Y": 6, "m": 6, "w": 6}
DEFAULT_ADV = 6  # unknown chars: assume widest, so we never under-estimate & clip
TITLE_STATIC_MAX = 58  # px; title <= this fits at x=3 with 3px right margin -> static

def text_width(s):
    if len(s) == 0:
        return 0
    w = 0
    for i in range(len(s)):
        w += CHAR_ADV.get(s[i], DEFAULT_ADV)
    return w - 1

# DEV ONLY: set True to preview the Dec 31 easter egg without waiting for the
# actual date. Must be False before committing — will break the easter egg for
# all real users if left True.
TEST_FORCE_DEC31 = False

def is_new_years_eve(now):
    # New Year's Eve easter egg trigger (Dec 31). TEST_FORCE_DEC31 forces it on
    # for previewing regardless of the real date.
    if TEST_FORCE_DEC31:
        return True
    return now.month == 12 and now.day == 31

# 8x8 calendar3.png (same image as the file in this folder), base64-encoded.
CALENDAR_PNG = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAQElEQVQYlWP8//8/AwQw/mdg+M+IzmaC8EECUBqZDVMKNQIrYAERDx88wCopr6AAtQIPoFwBI9ibMJejg///GQEXFxYMoIno4wAAAABJRU5ErkJggg==")

# 23x23 fireworks easter-egg sprite frames (fw_fw1..fw_fw4.png in this folder),
# base64-encoded. Cycled by render.Animation on the New Year's Eve screen.
FW1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABcAAAAXCAYAAADgKtSgAAAAJElEQVR42mNgGAWjYBQME/D/ddN/mhkMBrS0YDT+RsEoGC4AANDQEalSyfH5AAAAAElFTkSuQmCC")
FW2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABcAAAAXCAYAAADgKtSgAAAAOklEQVR42mNgGAWjYBQw/P+06j8hNlUsQKep64vXTf+pHixgDDQYDEA0VGxwu5ymYU7z1DIKRsEQBwCfH0tJQ7rxqQAAAABJRU5ErkJggg==")
FW3 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABcAAAAXCAYAAADgKtSgAAAAfUlEQVR42mNgGBHgV+aW/0PT8P+fVlFu+P9puv9JMTzqxLP/FFuAzXCSDUY3jBBNlXDGxabY5eiYehGMZgjJhoIiEIyxuBLu0tdNOH0CwhWXKsCYvi4fkDCnS2qhajrHFjHYDCO5MMMV47hcSpXSkiqpBBcgu5AacMMHFQAALWftMOh4WMAAAAAASUVORK5CYII=")
FW4 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABcAAAAXCAYAAADgKtSgAAAAV0lEQVR42mNgGCyg1iTqxNA0nGJQ7y1Glut0U4pP0MQCog0eBcMAgFIHuUkQHdhk2pwA4dFQHSkAV2zXV4aeoKgoJjYZoRdWZJX1dKsgQK6lVmYb3OU2ANIcIx0TOc/2AAAAAElFTkSuQmCC")

def main(config):
    tz = LOCATION
    location_str = config.get("location")
    if location_str and location_str.startswith("{"):
        loc = json.decode(location_str)
        if loc != None:
            tz_from_loc = loc.get("timezone")
            if tz_from_loc and tz_from_loc != "":
                tz = tz_from_loc

    now = time.now().in_location(tz)

    ical_url = config.get("ical_url")
    if not ical_url:
        return render_no_url()

    alert_enabled = config.get("alert_enabled") != "false"
    alert_window_mins = int(config.get("alert_window") or "3")

    events = fetch_events(tz, ical_url, now)
    event = select_event(events, now)

    if event == "EMPTY_DAY":
        return render_empty_day(now)
    if event == None:
        return render_no_events(tz)

    return render_event(event, now, alert_enabled, alert_window_mins)

def get_schema():
    # Exposes the iCal URL as a config field. In `pixlet serve`, this renders an
    # input box in the browser preview. The field id "ical_url" matches the key
    # the app reads (config.get("ical_url")) and the value push.sh passes in CI
    # (ical_url="$ICAL_URL"), so serve and the workflow stay in sync.
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ical_url",
                name = "iCal URL",
                desc = "Enter your Google calendar's secret address in iCal format. You can find it in your calendar settings.",
                icon = "calendar",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Used to show dates and times in your local timezone.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "alert_enabled",
                name = "Meeting alert",
                desc = "Flash the time row when a meeting is about to start",
                icon = "bell",
                default = True,
            ),
            schema.Dropdown(
                id = "alert_window",
                name = "Alert timing",
                desc = "How many minutes before a meeting starts to show the alert",
                icon = "clock",
                default = "3",
                options = [
                    schema.Option(display = "1 minute", value = "1"),
                    schema.Option(display = "2 minutes", value = "2"),
                    schema.Option(display = "3 minutes", value = "3"),
                    schema.Option(display = "4 minutes", value = "4"),
                    schema.Option(display = "5 minutes", value = "5"),
                ],
            ),
        ],
    )

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def title_row(title, top = 14):
    # The Row 2 title. If it fits within the static width, render plain text at
    # the 3px left margin (like the other static rows). Only when it's too wide
    # do we fall back to a full-width, edge-to-edge scrolling marquee.
    # top: vertical offset from display origin; default 14; pass 13 when the
    # title should be raised 1px (alert state).
    if text_width(title) <= TITLE_STATIC_MAX:
        return render.Padding(
            pad = (3, top, 0, 0),
            child = render.Text(content = title, color = WHITE, font = FONT),
        )
    return render.Padding(
        pad = (3, top, 0, 0),
        child = render.Marquee(
            width = 58,
            # 3px margins on both sides are in the Padding above; offset_start = 0.
            # delay = 10 holds the text still for ~500ms before scrolling starts.
            offset_start = 0,
            delay = 10,
            child = render.Text(content = title, color = WHITE, font = FONT),
        ),
    )

def render_event(event, now, alert_enabled, alert_window_mins):
    date_str = format_date(event["start"])
    title = event["summary"]  # preserved exactly as in the calendar

    if event["all_day"]:
        time_str = "All day"
    else:
        time_str = format_time(event["start"])

    # Alert state: fire when we are within alert_window_mins of an upcoming event.
    alert = (
        alert_enabled and
        not event["all_day"] and
        event["start"] > now and
        now >= add_seconds(event["start"], -alert_window_mins * 60)
    )

    if alert:
        # Shared top rows (icon, date, title raised 1px).
        icon_row = render.Padding(
            pad = (3, 3, 0, 0),
            child = render.Image(src = CALENDAR_PNG, width = 8, height = 8),
        )
        date_row = render.Padding(
            pad = (14, 4, 0, 0),
            child = render.Text(content = date_str, color = PINK, font = FONT),
        )

        # Normal phase: yellow text on black (title raised 1px).
        nf = render.Stack(children = [
            render.Box(width = 64, height = 32, color = BLACK),
            icon_row,
            date_row,
            title_row(title, top = 13),
            render.Padding(
                pad = (3, 22, 0, 0),
                child = render.Text(content = time_str, color = YELLOW, font = FONT),
            ),
        ])

        # Inverted phase: full-width yellow bar (2px gap at bottom), black text.
        inv = render.Stack(children = [
            render.Box(width = 64, height = 32, color = BLACK),
            icon_row,
            date_row,
            title_row(title, top = 13),
            render.Padding(
                pad = (0, 22, 0, 0),
                child = render.Box(width = 64, height = 8, color = YELLOW),
            ),
            render.Padding(
                pad = (3, 22, 0, 0),
                child = render.Text(content = time_str, color = BLACK, font = FONT),
            ),
        ])

        # 20 × 50ms = 1 second per phase. Pixlet collapses identical frames and
        # accumulates their delays, so static titles produce 2 stored frames × 1s.
        frames = [nf for _ in range(20)] + [inv for _ in range(20)]
        return render.Root(
            child = render.Animation(children = frames),
            delay = 50,
        )

    return render.Root(
        child = render.Stack(
            children = [
                # Background fixes the canvas at 64x32 so the Padding offsets
                # below are measured from the true top-left corner.
                render.Box(width = 64, height = 32, color = BLACK),

                # ROW 1 — calendar icon at (2, 2)
                render.Padding(
                    pad = (3, 3, 0, 0),
                    child = render.Image(src = CALENDAR_PNG, width = 8, height = 8),
                ),
                # ROW 1 — date text, 2px right of the icon
                render.Padding(
                    pad = (14, 4, 0, 0),
                    child = render.Text(content = date_str, color = PINK, font = FONT),
                ),

                # ROW 2 — title. Static with a 3px left margin if it fits;
                # full-width scrolling marquee only when it's too long.
                title_row(title),

                # ROW 3 — time, 2px from the left
                render.Padding(
                    pad = (3, 22, 0, 0),
                    child = render.Text(content = time_str, color = YELLOW, font = FONT),
                ),
            ],
        ),
    )

def render_no_url():
    return render.Root(
        child = render.Stack(
            children = [
                render.Box(width = 64, height = 32, color = BLACK),

                # ROW 1 — calendar icon + greeting
                render.Padding(
                    pad = (3, 3, 0, 0),
                    child = render.Image(src = CALENDAR_PNG, width = 8, height = 8),
                ),
                render.Padding(
                    pad = (14, 4, 0, 0),
                    child = render.Text(content = "Hello :)", color = PINK, font = FONT),
                ),

                # ROW 2 — empty

                # ROW 3 — scrolling instruction, same pause-then-scroll as title_row
                render.Padding(
                    pad = (0, 22, 0, 0),
                    child = render.Marquee(
                        width = 64,
                        offset_start = 3,
                        delay = 10,
                        child = render.Text(content = "Enter your calendar URL", color = WHITE, font = FONT),
                    ),
                ),
            ],
        ),
    )

def render_empty_day(now):
    date_str = format_date(now)
    idx = days_from_civil(now.year, now.month, now.day) % 6
    phrase = QUIET_PHRASES[idx]
    return render.Root(
        child = render.Stack(
            children = [
                render.Box(width = 64, height = 32, color = BLACK),

                # ROW 1 — calendar icon + date
                render.Padding(
                    pad = (3, 3, 0, 0),
                    child = render.Image(src = CALENDAR_PNG, width = 8, height = 8),
                ),
                render.Padding(
                    pad = (14, 4, 0, 0),
                    child = render.Text(content = date_str, color = PINK, font = FONT),
                ),

                # ROW 2 — first line of phrase
                render.Padding(
                    pad = (3, 14, 0, 0),
                    child = render.Text(content = phrase[0], color = WHITE, font = FONT),
                ),

                # ROW 3 — second line of phrase
                render.Padding(
                    pad = (3, 22, 0, 0),
                    child = render.Text(content = phrase[1], color = WHITE, font = FONT),
                ),
            ],
        ),
    )

def render_no_events(tz):
    # Same 3-row layout as the main display: icon + today's date on top, then
    # two static yellow lines (no marquee).
    now = time.now().in_location(tz)
    date_str = format_date(now)

    # New Year's Eve easter egg: same middle line, year-stamped bottom line
    # (year pulled dynamically from today's date, e.g. "FOR 2026").
    nye = is_new_years_eve(now)
    middle_line = "ALL DONE"
    bottom_line = "FOR " + str(now.year) + "!!" if nye else "FOR TODAY :)"

    kids = [
        render.Box(width = 64, height = 32, color = BLACK),

        # ROW 1 — calendar icon at (2, 2) + today's date
        render.Padding(
            pad = (3, 3, 0, 0),
            child = render.Image(src = CALENDAR_PNG, width = 8, height = 8),
        ),
        render.Padding(
            pad = (14, 4, 0, 0),
            child = render.Text(content = date_str, color = PINK, font = FONT),
        ),

        # ROW 2 — static line, 2px from the left
        render.Padding(
            pad = (3, 14, 0, 0),
            child = render.Text(content = middle_line, color = YELLOW, font = FONT),
        ),

        # ROW 3 — static line, 2px from the left
        render.Padding(
            pad = (3, 22, 0, 0),
            child = render.Text(content = bottom_line, color = YELLOW, font = FONT),
        ),
    ]

    # Easter egg flourish: an animated fireworks burst on the right side,
    # nudged slightly above center (23x23 sprite at x=42, y=2 -> center ~(53,13)).
    # The text keeps its 3px margins; the firework is decorative and may run to
    # the right edge. Frames cycle spark -> small burst -> big burst -> fading,
    # with a short blank gap, then loop.
    if nye:
        kids.append(render.Padding(
            pad = (42, 2, 0, 0),
            child = render.Animation(children = [
                render.Image(src = FW1, width = 23, height = 23),
                render.Image(src = FW2, width = 23, height = 23),
                render.Image(src = FW3, width = 23, height = 23),
                render.Image(src = FW3, width = 23, height = 23),
                render.Image(src = FW4, width = 23, height = 23),
                render.Image(src = FW4, width = 23, height = 23),
                render.Box(width = 23, height = 23),
                render.Box(width = 23, height = 23),
            ]),
        ))

    return render.Root(child = render.Stack(children = kids), delay = 150)

# ---------------------------------------------------------------------------
# Event selection
# ---------------------------------------------------------------------------

def all_day_sort_key(e):
    start_ord = days_from_civil(e["start"].year, e["start"].month, e["start"].day)
    end_ord = days_from_civil(e["end"].year, e["end"].month, e["end"].day)
    return (
        end_ord - start_ord,  # 1. duration ascending (shortest first)
        -start_ord,  # 2. start descending (most recently started first)
        e["summary"],
    )  # 3. alphabetical by title

def is_extended(e):
    return e["end"].unix - e["start"].unix > EXTENDED_THRESHOLD

def synthesize_event(group):
    # Given events sharing the same start time: return the single event unchanged,
    # or synthesize a display event highlighting the shortest with "+ N other(s)".
    if len(group) == 1:
        return group[0]
    best = group[0]
    for e in group[1:]:
        dur_best = best["end"].unix - best["start"].unix
        dur_e = e["end"].unix - e["start"].unix
        if dur_e < dur_best or (dur_e == dur_best and e["summary"] < best["summary"]):
            best = e
    n = len(group) - 1
    suffix = "other" if n == 1 else "others"
    return {
        "summary": best["summary"] + " + " + str(n) + " " + suffix,
        "start": best["start"],
        "end": best["end"],
        "all_day": False,
    }

def select_event(events, now):
    timed = [e for e in events if not e["all_day"]]

    # Step 1 — Current event: most recently started wins; synthesize same-start group.
    current_candidates = [e for e in timed if e["start"] <= now and e["end"] > now]
    current = None
    if len(current_candidates) > 0:
        raw_best = current_candidates[0]
        for e in current_candidates[1:]:
            if e["start"] > raw_best["start"]:
                raw_best = e
            elif e["start"].unix == raw_best["start"].unix:
                dur_e = e["end"].unix - e["start"].unix
                dur_best = raw_best["end"].unix - raw_best["start"].unix
                if dur_e < dur_best or (dur_e == dur_best and e["summary"] < raw_best["summary"]):
                    raw_best = e
        same_start = [e for e in current_candidates if e["start"].unix == raw_best["start"].unix]
        current = synthesize_event(same_start)

    # Step 2 — Next upcoming timed event: synthesize same-start group.
    upcoming = [e for e in timed if e["start"] > now]
    next_timed = None
    if len(upcoming) > 0:
        min_start = upcoming[0]["start"]
        for e in upcoming[1:]:
            if e["start"] < min_start:
                min_start = e["start"]
        next_group = [e for e in upcoming if e["start"].unix == min_start.unix]
        next_timed = synthesize_event(next_group)

    # Step 3 — Dispatch.
    if current != None:
        # 3a. Prep check: always first; applies to all event types; overrides persistence.
        if next_timed != None:
            if now >= add_seconds(next_timed["start"], -PREPARATION_TIME):
                return next_timed

        # 3b. Extended persistence: after PERSISTENCE_TIME elapses, defer to regular events.
        if is_extended(current):
            if now >= add_seconds(current["start"], PERSISTENCE_TIME):
                # i. Regular event currently in progress?
                reg_ip = [e for e in current_candidates if not is_extended(e)]
                if len(reg_ip) > 0:
                    reg_best = reg_ip[0]
                    for e in reg_ip[1:]:
                        if e["start"] > reg_best["start"]:
                            reg_best = e
                        elif e["start"].unix == reg_best["start"].unix:
                            dur_e = e["end"].unix - e["start"].unix
                            dur_best = reg_best["end"].unix - reg_best["start"].unix
                            if dur_e < dur_best or (dur_e == dur_best and e["summary"] < reg_best["summary"]):
                                reg_best = e
                    reg_same_start = [e for e in reg_ip if e["start"].unix == reg_best["start"].unix]
                    return synthesize_event(reg_same_start)

                # ii. Regular event upcoming today?
                reg_up = [e for e in upcoming if not is_extended(e) and same_day(e["start"], now)]
                if len(reg_up) > 0:
                    reg_min = reg_up[0]["start"]
                    for e in reg_up[1:]:
                        if e["start"] < reg_min:
                            reg_min = e["start"]
                    reg_next_group = [e for e in reg_up if e["start"].unix == reg_min.unix]
                    return synthesize_event(reg_next_group)

                # iii. No regular alternatives: extended event continues showing.

        return current

    # No event currently in progress.
    if next_timed != None and same_day(next_timed["start"], now):
        return next_timed

    # No timed event active or upcoming today.
    timed_today_existed = False
    for e in timed:
        if same_day(e["start"], now):
            timed_today_existed = True

    # Fall back to today's all-day events (e.g. holidays) when no timed events today.
    if not timed_today_existed:
        all_day_today = [e for e in events if e["all_day"] and same_day(e["start"], now)]
        n = len(all_day_today)
        if n == 1:
            return all_day_today[0]
        if n > 1:
            all_day_today = sorted(all_day_today, key = all_day_sort_key)
            return all_day_today[(now.unix // 60) % n]

    if now.hour < 20:
        if not timed_today_existed:
            return "EMPTY_DAY"  # zero events ever scheduled today
        return None  # had events but they're all finished

    # Easter egg: on Dec 31, stay on the no-events screen through midnight
    # instead of jumping ahead to tomorrow's (next year's) first event.
    if is_new_years_eve(now):
        return None

    # At or after 8 PM: show the first timed event of tomorrow (with synthesis).
    tomorrow = add_seconds(now, 24 * 60 * 60)
    tomorrow_timed = [e for e in timed if same_day(e["start"], tomorrow) and e["start"] > now]
    if len(tomorrow_timed) == 0:
        return None
    min_start = tomorrow_timed[0]["start"]
    for e in tomorrow_timed[1:]:
        if e["start"] < min_start:
            min_start = e["start"]
    tomorrow_group = [e for e in tomorrow_timed if e["start"].unix == min_start.unix]
    return synthesize_event(tomorrow_group)

# ---------------------------------------------------------------------------
# iCal parsing
# ---------------------------------------------------------------------------

def fetch_events(tz, ical_url, now):
    resp = http.get(ical_url, ttl_seconds = TTL_SECONDS)
    if resp.status_code != 200:
        return []
    return parse_ical(resp.body(), tz, now)

def collect_recurrence_overrides(lines, tz):
    # Pre-scan: find VEVENTs that carry RECURRENCE-ID (exception overrides).
    # Returns {uid: [overridden_occurrence_time, ...]} so that expand_rrule can
    # suppress the original occurrence that was replaced by the exception event.
    overrides = {}
    in_event = False
    uid = ""
    rec_id = None
    rec_id_params = ""
    for line in lines:
        if line == "BEGIN:VEVENT":
            in_event = True
            uid = ""
            rec_id = None
            rec_id_params = ""
        elif line == "END:VEVENT":
            if uid != "" and rec_id != None:
                if uid not in overrides:
                    overrides[uid] = []
                overrides[uid].append(parse_dt(rec_id, rec_id_params, tz))
            in_event = False
        elif in_event:
            name, params, value = split_property(line)
            if name == "UID":
                uid = value.strip()
            elif name == "RECURRENCE-ID":
                rec_id = value
                rec_id_params = params
    return overrides

def parse_ical(body, tz, now):
    lines = unfold(body)

    # Pre-scan for RECURRENCE-ID overrides before expanding any RRULEs.
    uid_overrides = collect_recurrence_overrides(lines, tz)

    # We only ever care about events occurring today or tomorrow, so recurring
    # events are expanded into just those two candidate days.
    today_ord = days_from_civil(now.year, now.month, now.day)
    window = [today_ord, today_ord + 1]

    events = []
    in_event = False
    uid = ""
    summary = ""
    start = None
    end = None
    all_day = False
    rrule = ""
    exdates = []
    status = ""

    for line in lines:
        if line == "BEGIN:VEVENT":
            in_event = True
            uid = ""
            summary = ""
            start = None
            end = None
            all_day = False
            rrule = ""
            exdates = []
            status = ""
        elif line == "END:VEVENT":
            if start != None and status != "CANCELLED":
                if end == None:
                    end = add_seconds(start, 60 * 60)  # default 1h
                title = summary if summary != "" else "(no title)"
                if rrule != "":
                    # Recurring: emit only the occurrences that land in our window,
                    # skipping any that have been overridden via RECURRENCE-ID.
                    rid_overrides = uid_overrides.get(uid, [])
                    for occ in expand_rrule(start, end, all_day, rrule, exdates, rid_overrides, tz, window):
                        occ["summary"] = title
                        events.append(occ)
                else:
                    events.append({
                        "summary": title,
                        "start": start,
                        "end": end,
                        "all_day": all_day,
                    })
            in_event = False
        elif in_event:
            name, params, value = split_property(line)
            if name == "UID":
                uid = value.strip()
            elif name == "SUMMARY":
                summary = unescape(value)
            elif name == "DTSTART":
                start = parse_dt(value, params, tz)
                all_day = is_date_only(value, params)
            elif name == "DTEND":
                end = parse_dt(value, params, tz)
            elif name == "RRULE":
                rrule = value
            elif name == "EXDATE":
                for v in value.split(","):
                    v = v.strip()
                    if v != "":
                        exdates.append(parse_dt(v, params, tz))
            elif name == "STATUS":
                status = value.strip().upper()

    return events

# ---------------------------------------------------------------------------
# Recurrence (RRULE) expansion — only enough to detect whether a recurring
# event has an occurrence on the candidate days (today / tomorrow).
# ---------------------------------------------------------------------------

BYDAY_INDEX = {"MO": 0, "TU": 1, "WE": 2, "TH": 3, "FR": 4, "SA": 5, "SU": 6}

def days_from_civil(y, m, d):
    # Days since 1970-01-01 (Howard Hinnant's algorithm). Pure integer math, so
    # day counts and weekdays are exact regardless of DST.
    yy = y - 1 if m <= 2 else y
    era = (yy if yy >= 0 else yy - 399) // 400
    yoe = yy - era * 400
    doy = (153 * (m - 3 if m > 2 else m + 9) + 2) // 5 + d - 1
    doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return era * 146097 + doe - 719468

def civil_from_days(z):
    z = z + 719468
    era = (z if z >= 0 else z - 146096) // 146097
    doe = z - era * 146097
    yoe = (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365
    y = yoe + era * 400
    doy = doe - (365 * yoe + yoe // 4 - yoe // 100)
    mp = (5 * doy + 2) // 153
    d = doy - (153 * mp + 2) // 5 + 1
    m = mp + 3 if mp < 10 else mp - 9
    return (y + 1 if m <= 2 else y, m, d)

def weekday_mon0(ordinal):
    return (ordinal + 3) % 7  # 0 = Monday

def to_int(s, default):
    # Defensive integer parse: returns default for anything that isn't a clean
    # (optionally signed) integer, so a malformed RRULE value can never crash
    # the whole render.
    if s == None:
        return default
    s = s.strip()
    neg = False
    if len(s) > 0 and (s[0] == "-" or s[0] == "+"):
        neg = s[0] == "-"
        s = s[1:]
    if len(s) == 0:
        return default
    for i in range(len(s)):
        if s[i] < "0" or s[i] > "9":
            return default
    v = int(s)
    return -v if neg else v

def int_list(s):
    # Parse a comma-separated list of ints (e.g. BYMONTHDAY="28,29"), skipping
    # any non-integer parts.
    out = []
    for p in s.split(","):
        v = to_int(p, None)
        if v != None:
            out.append(v)
    return out

def days_in_month(y, m):
    if m == 12:
        return days_from_civil(y + 1, 1, 1) - days_from_civil(y, 12, 1)
    return days_from_civil(y, m + 1, 1) - days_from_civil(y, m, 1)

def parse_rrule(s):
    out = {}
    for part in s.split(";"):
        kv = part.split("=", 1)
        if len(kv) == 2:
            out[kv[0].strip().upper()] = kv[1].strip()
    return out

def byday_set(rr):
    out = []
    if "BYDAY" not in rr:
        return out
    for code in rr["BYDAY"].split(","):
        code = code.strip().upper()
        if len(code) >= 2:
            day = code[-2:]  # drop any ordinal prefix like "2" in "2WE"
            if day in BYDAY_INDEX:
                out.append(BYDAY_INDEX[day])
    return out

def parse_byday_ordinals(rr):
    # For MONTHLY rules: parses BYDAY codes that carry an ordinal prefix (e.g.
    # "3MO" = 3rd Monday, "-1TU" = last Tuesday) into (ordinal, weekday_index)
    # pairs.  Codes without a prefix (plain "MO") are ignored here — they have
    # no ordinal semantics in a MONTHLY rule.
    out = []
    if "BYDAY" not in rr:
        return out
    for code in rr["BYDAY"].split(","):
        code = code.strip().upper()
        if len(code) >= 2:
            day = code[-2:]
            prefix = code[:-2]
            if day in BYDAY_INDEX and prefix != "":
                n = to_int(prefix, None)
                if n != None:
                    out.append((n, BYDAY_INDEX[day]))
    return out

def nth_weekday_match(d, d_ord, dim, specs):
    # True if day d/d_ord is the Nth occurrence of the target weekday within
    # its month (dim = days in that month).  Positive n counts from the start
    # (1 = first); negative n counts from the end (-1 = last).
    wd = weekday_mon0(d_ord)
    for n, target_wd in specs:
        if wd != target_wd:
            continue
        if n > 0:
            if (d - 1) // 7 + 1 == n:
                return True
        elif n < 0:
            if (dim - d) // 7 + 1 == -n:
                return True
    return False

def monthday_match(bymonthdays, y, m, d):
    # True if day d matches any BYMONTHDAY value (negatives count from the end
    # of the month: -1 = last day).
    dim = days_in_month(y, m)
    for target in bymonthdays:
        t = target
        if t < 0:
            t = dim + t + 1
        if d == t:
            return True
    return False

def rrule_matches(freq, interval, bydays, bymonthdays, byday_ordinals, s_ord, sy, sm, d_ord, y, m, d):
    if freq == "DAILY":
        return (d_ord - s_ord) % interval == 0
    if freq == "WEEKLY":
        if len(bydays) > 0:
            if weekday_mon0(d_ord) not in bydays:
                return False
            mon_d = d_ord - weekday_mon0(d_ord)
            mon_s = s_ord - weekday_mon0(s_ord)
            return ((mon_d - mon_s) // 7) % interval == 0
        return (d_ord - s_ord) % (7 * interval) == 0
    if freq == "MONTHLY":
        if len(byday_ordinals) > 0:
            # BYDAY with ordinal (e.g. 3MO): match the Nth weekday of the month.
            dim = days_in_month(y, m)
            if not nth_weekday_match(d, d_ord, dim, byday_ordinals):
                return False
        elif not monthday_match(bymonthdays, y, m, d):
            return False
        return ((y - sy) * 12 + (m - sm)) % interval == 0
    if freq == "YEARLY":
        return m == sm and monthday_match(bymonthdays, y, m, d) and (y - sy) % interval == 0
    return False

def rrule_within_count(freq, interval, bydays, count, s_ord, d_ord):
    if count < 0:
        return True
    if freq == "DAILY":
        return (d_ord - s_ord) // interval <= count - 1
    if freq == "WEEKLY" and len(bydays) == 0:
        return (d_ord - s_ord) // (7 * interval) <= count - 1
    return True  # weekly+byday / monthly / yearly counts not enforced

def expand_rrule(start, end, all_day, rrule_str, exdates, recurrence_id_overrides, tz, window):
    rr = parse_rrule(rrule_str)
    freq = rr.get("FREQ", "")
    interval = to_int(rr.get("INTERVAL", "1"), 1)
    if interval < 1:
        interval = 1
    bydays = byday_set(rr)
    byday_ordinals = parse_byday_ordinals(rr)
    until = parse_dt(rr["UNTIL"], "", tz) if "UNTIL" in rr else None
    count = to_int(rr["COUNT"], -1) if "COUNT" in rr else -1
    dur = end - start

    sy = start.year
    sm = start.month
    sd = start.day
    shour = start.hour
    smin = start.minute
    ssec = start.second
    s_ord = days_from_civil(sy, sm, sd)
    if "BYMONTHDAY" in rr:
        bymonthdays = int_list(rr["BYMONTHDAY"])
        if len(bymonthdays) == 0:
            bymonthdays = [sd]
    else:
        bymonthdays = [sd]

    ex = {}
    for e in exdates:
        ex[(e.year, e.month, e.day)] = True

    # Build a precise (y, m, d, h, min, sec) set for RECURRENCE-ID suppression.
    # Keyed by local-timezone components to match occ_start computed below.
    rid_ex = {}
    for t in recurrence_id_overrides:
        rid_ex[(t.year, t.month, t.day, t.hour, t.minute, t.second)] = True

    occs = []
    for d_ord in window:
        if d_ord < s_ord:
            continue
        ymd = civil_from_days(d_ord)
        y = ymd[0]
        m = ymd[1]
        d = ymd[2]
        if not rrule_matches(freq, interval, bydays, bymonthdays, byday_ordinals, s_ord, sy, sm, d_ord, y, m, d):
            continue
        occ_start = time.time(year = y, month = m, day = d, hour = shour, minute = smin, second = ssec, location = tz)
        if until != None and occ_start > until:
            continue
        if not rrule_within_count(freq, interval, bydays, count, s_ord, d_ord):
            continue
        if (y, m, d) in ex:
            continue
        if (y, m, d, shour, smin, ssec) in rid_ex:
            continue
        occs.append({"start": occ_start, "end": occ_start + dur, "all_day": all_day})
    return occs

def unfold(body):
    # iCal folds long lines: a continuation begins with a space or tab.
    out = []
    for line in body.split("\n"):
        line = line.rstrip("\r")
        if len(line) > 0 and (line[0] == " " or line[0] == "\t"):
            if len(out) > 0:
                out[-1] = out[-1] + line[1:]
        else:
            out.append(line)
    return out

def split_property(line):
    # "NAME;params:value" or "NAME:value" -> (NAME, params, value)
    colon = line.find(":")
    if colon < 0:
        return (line, "", "")
    left = line[:colon]
    value = line[colon + 1:]
    semi = left.find(";")
    if semi < 0:
        return (left, "", value)
    return (left[:semi], left[semi + 1:], value)

def is_date_only(value, params):
    return "VALUE=DATE" in params or len(value.strip()) == 8

def parse_dt(value, params, tz):
    # Three iCal forms:
    #   20260618T123000Z   (UTC)
    #   20260618T123000    (floating / TZID in params)
    #   20260618           (all-day, VALUE=DATE)
    value = value.strip()

    if len(value) == 8:
        t = time.parse_time(value, format = "20060102", location = tz)
        return t.in_location(tz)

    if value.endswith("Z"):
        t = time.parse_time(value, format = "20060102T150405Z", location = "UTC")
        return t.in_location(tz)

    loc = tz
    tzid = extract_tzid(params)
    if tzid != "":
        loc = tzid
    t = time.parse_time(value, format = "20060102T150405", location = loc)
    return t.in_location(tz)

def extract_tzid(params):
    for part in params.split(";"):
        if part.startswith("TZID="):
            return part[len("TZID="):]
    return ""

def unescape(s):
    s = s.replace("\\n", " ").replace("\\N", " ")
    s = s.replace("\\,", ",").replace("\\;", ";")
    s = s.replace("\\\\", "\\")
    return s.strip()

# ---------------------------------------------------------------------------
# Formatting helpers
# ---------------------------------------------------------------------------

def add_seconds(t, secs):
    return t + time.parse_duration("%ds" % secs)

def same_day(a, b):
    return a.year == b.year and a.month == b.month and a.day == b.day

def format_date(t):
    # e.g. "JUN 19" — month abbreviation, then day number.
    return MONTHS[t.month - 1] + " " + str(t.day)

def format_time(t):
    hour = t.hour
    minute = t.minute
    suffix = "am"
    if hour >= 12:
        suffix = "pm"
    h12 = hour % 12
    if h12 == 0:
        h12 = 12
    mm = str(minute)
    if minute < 10:
        mm = "0" + mm
    return str(h12) + ":" + mm + " " + suffix
