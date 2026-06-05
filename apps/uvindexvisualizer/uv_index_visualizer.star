"""Multi-view UV exposure screen for Tidbyt."""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

YELLOW = "#fbdb4c"
SKY = "#8aaafb"
NAVY = "#31406d"
STEEL = "#5c74ab"
SAND = "#ccbcac"
TEAL = "#34696b"
WARM = "#ff8c3c"
ALERT = "#ff4d4d"
WHITE = "#ffffff"
BLACK = "#000000"

W = 64
H = 32
FRAMES = 8
FRAME_MS = 150

DEFAULT_LOCATION = {
    "lat": "21.2698",
    "lng": "-157.7886",
    "locality": "Kahala",
    "timezone": "Pacific/Honolulu",
}
API_URL = "https://currentuvindex.com/api/v1/uvi?latitude=%s&longitude=%s"
TIME_FORMAT = "2006-01-02T15:04:05Z"
DEFAULT_REFRESH_MINUTES = 30
ONE_DAY = time.parse_duration("24h")

SIN8 = [0, 1, 1, 1, 0, -1, -1, -1]
SIN16 = [0, 38, 70, 92, 100, 92, 70, 38, 0, -38, -70, -92, -100, -92, -70, -38]
SKIN_FACTOR = {"I": 100, "II": 150, "III": 200, "IV": 300, "V": 400, "VI": 500}

# MARKER:HELPERS

HEX = "0123456789abcdef"

def hex2(n):
    if n < 0:
        n = 0
    if n > 255:
        n = 255
    return HEX[(n >> 4) & 15] + HEX[n & 15]

def rgb(c):
    return (int(c[1:3], 16), int(c[3:5], 16), int(c[5:7], 16))

def from_rgb(r, g, b):
    return "#" + hex2(int(r)) + hex2(int(g)) + hex2(int(b))

def lerp(a, b, t):
    ar, ag, ab_ = rgb(a)
    br, bg, bb_ = rgb(b)
    return from_rgb(ar + (br - ar) * t, ag + (bg - ag) * t, ab_ + (bb_ - ab_) * t)

def darken(c, t):
    return lerp(c, BLACK, t)

def lighten(c, t):
    return lerp(c, WHITE, t)

def uv_category(uvi):
    if uvi < 3:
        return ("Low", TEAL)
    if uvi < 6:
        return ("Mod", SKY)
    if uvi < 8:
        return ("High", YELLOW)
    if uvi < 11:
        return ("V.Hi", WARM)
    return ("Ext", ALERT)

def build_palette(c):
    return [darken(c, 0.75), darken(c, 0.55), darken(c, 0.30), c, lighten(c, 0.20), lighten(c, 0.40)]

def format_one_decimal(v):
    tenths = int(v * 10 + 0.5)
    return "%d.%d" % (tenths // 10, tenths % 10)

def burn_minutes(uvi, skin):
    """Estimated minutes to first burn at this UV for the given skin type.
    Returns 0 when UV is effectively zero (no risk)."""
    if uvi < 0.5:
        return 0
    factor = SKIN_FACTOR.get(skin, 200)
    return int(factor / uvi)

def format_burn(mins):
    """Render a burn-minutes count: SAFE / 23M / 1H40."""
    if mins <= 0:
        return "SAFE"
    if mins < 60:
        return "%dM" % mins
    h = mins // 60
    m = mins % 60
    if m == 0:
        return "%dH" % h
    mstr = "%d" % m
    if m < 10:
        mstr = "0" + mstr
    return "%dH%s" % (h, mstr)

def parse_refresh_seconds(raw):
    if raw == None or raw == "":
        m = DEFAULT_REFRESH_MINUTES
    else:
        m = int(raw) if raw.isdigit() else DEFAULT_REFRESH_MINUTES
    if m < 5:
        m = 5
    if m > 1440:
        m = 1440
    return m * 60

def fetch_uv(lat, lng, ttl_seconds):
    key = "uv:%s:%s" % (lat, lng)
    cached = cache.get(key)
    if cached:
        return json.decode(cached)
    url = API_URL % (lat, lng)
    resp = http.get(url, ttl_seconds = ttl_seconds)
    if resp.status_code != 200:
        return None
    d = resp.json()
    cache.set(key, json.encode(d), ttl_seconds = ttl_seconds)
    return d

def all_points(data):
    pts = []
    for p in data.get("history", []):
        pts.append(p)
    if data.get("now"):
        pts.append(data["now"])
    for p in data.get("forecast", []):
        pts.append(p)
    return pts

def parse_pt(p, tz):
    t = time.parse_time(p["time"], format = TIME_FORMAT).in_location(tz)
    return (t, float(p["uvi"]))

def next_hours(data, tz, n):
    out = [(time.now().in_location(tz), float(data["now"]["uvi"]))]
    for p in data.get("forecast", []):
        if len(out) >= n:
            break
        out.append(parse_pt(p, tz))
    return out

def days_ahead(data, tz, n):
    today = time.now().in_location(tz)
    bucket = {}
    for p in all_points(data):
        t, uvi = parse_pt(p, tz)
        key = t.format("2006-01-02")
        if key not in bucket:
            bucket[key] = {
                "date_key": key,
                "label": t.format("Mon"),
                "hours": [0.0] * 24,
            }
        bucket[key]["hours"][t.hour] = uvi
    days = []
    cursor = today
    for _ in range(n):
        key = cursor.format("2006-01-02")
        if key in bucket:
            d = bucket[key]
        else:
            d = {"date_key": key, "label": cursor.format("Mon"), "hours": [0.0] * 24}
        peak_hour = 12
        peak_uvi = 0.0
        for h in range(24):
            if d["hours"][h] > peak_uvi:
                peak_uvi = d["hours"][h]
                peak_hour = h
        d["peak_uvi"] = peak_uvi
        d["peak_hour"] = peak_hour
        days.append(d)
        cursor = cursor + ONE_DAY
    return days

# Integer square root via precomputed table (builds at load).
def _build_isqrt():
    table = []

    # Full-screen baker: max dx=32, dy=16 => d^2 up to 32^2+16^2 = 1280.
    # Cover up to 1600 (40^2) to be safe.
    for n in range(1601):
        # binary search 0..40
        lo = 0
        hi = 40

        for _ in range(7):
            mid = (lo + hi + 1) // 2
            if mid * mid <= n:
                lo = mid
            else:
                hi = mid - 1
        table.append(lo)
    return table

ISQRT = _build_isqrt()

def isqrt(n):
    if n < 0:
        return 0
    if n >= len(ISQRT):
        # rough fallback for larger values
        return int(n / 20) + 2
    return ISQRT[n]

# Approximate angle bucket 0..15 (one octant per 2 buckets) for vector (dx,dy).
# Avoids atan2; good enough for ray patterns.
def angle16(dx, dy):
    if dx == 0 and dy == 0:
        return 0
    adx = dx if dx >= 0 else -dx
    ady = dy if dy >= 0 else -dy

    # octant: which 1/8 of the circle
    if adx >= ady:
        # closer to x axis
        frac = (ady * 2) // (adx if adx > 0 else 1)  # 0..1ish
    else:
        frac = 2 - (adx * 2) // (ady if ady > 0 else 1)

    # base octant
    if dx >= 0 and dy >= 0:
        base = 0
    elif dx < 0 and dy >= 0:
        base = 4
        frac = 2 - frac
    elif dx < 0 and dy < 0:
        base = 8
    else:
        base = 12
        frac = 2 - frac
    a = base + frac
    if a < 0:
        a = 0
    if a > 15:
        a = 15
    return a

def run_length_row(pixels):
    """pixels = list of color strings, length W. Returns a Row of Boxes."""
    cols = []
    prev = ""
    n = 0
    for c in pixels:
        if c == prev:
            n += 1
        else:
            if prev != "":
                cols.append(render.Box(width = n, height = 1, color = prev))
            prev = c
            n = 1
    if prev != "":
        cols.append(render.Box(width = n, height = 1, color = prev))
    return render.Row(children = cols)

# MARKER:MAIN

def main(config):
    loc_raw = config.get("location")
    loc = json.decode(loc_raw) if loc_raw else DEFAULT_LOCATION
    lat = loc.get("lat") or DEFAULT_LOCATION["lat"]
    lng = loc.get("lng") or DEFAULT_LOCATION["lng"]
    tz = loc.get("timezone") or DEFAULT_LOCATION["timezone"]
    view = config.get("view") or "baker"
    refresh_seconds = parse_refresh_seconds(config.get("refresh_minutes"))
    skin = config.get("skin_type") or "III"
    target_lo = float(config.get("target_lo") or "3")
    target_hi = float(config.get("target_hi") or "7")

    data = fetch_uv(lat, lng, refresh_seconds)
    if not data or not data.get("ok"):
        return render.Root(
            max_age = refresh_seconds,
            child = render.Box(color = BLACK, child = render.Text("UV n/a", font = "tb-8", color = ALERT)),
        )

    if view == "window":
        body = view_window(data, tz, target_lo, target_hi, skin)
    elif view == "burn":
        body = view_burn(data, skin)
    elif view == "week":
        body = view_week(data, tz)
    elif view == "arc":
        body = view_arc(data, tz)
    elif view == "arc1":
        body = view_arc1(data, tz)
    else:
        body = view_baker(data)

    return render.Root(
        delay = FRAME_MS,
        max_age = refresh_seconds,
        child = render.Box(color = BLACK, child = body),
    )

# MARKER:BAKER

# Solar Baker: full-screen sun disc centered on canvas. Radius scales with
# UV level — small but visible at low UV, fills the entire 64x32 at extreme.
# Swirling rays animate. UV value + category overlaid with solid black backing
# for legibility.

def view_baker(data):
    uvi = float(data["now"]["uvi"])
    cat_label, cat_color = uv_category(uvi)
    palette = build_palette(cat_color)

    # Sun center = screen center
    cx = W // 2
    cy = H // 2

    # Radius scales: low UV (~1) -> r=8, moderate (~5) -> r=18, extreme (11+) -> r=36 (fills screen)
    r_max = 6 + int((uvi / 11.0) * 30 + 0.5)
    if r_max < 6:
        r_max = 6
    if r_max > 36:
        r_max = 36
    n_rays = 4 + int(uvi / 2)
    if n_rays > 12:
        n_rays = 12
    amp = 1 + int((uvi / 11.0) * 4 + 0.5)  # 1..5 px

    frames = []
    for t in range(FRAMES):
        frames.append(baker_frame_full(cx, cy, r_max, n_rays, amp, palette, t, uvi, cat_label, cat_color))
    return render.Animation(children = frames)

def baker_frame_full(cx, cy, r_max, n_rays, amp, palette, t, uvi, cat_label, cat_color):
    pal_len = len(palette)
    rows = []
    for y in range(H):
        pixels = []
        for x in range(W):
            dx = x - cx
            dy = y - cy
            d2 = dx * dx + dy * dy
            ang = angle16(dx, dy)
            ray_phase = (ang * n_rays + t * 3) % 16
            ray_mod = SIN16[ray_phase]  # -100..100
            r_eff_x10 = r_max * 10 + ray_mod * amp // 10
            r_eff = r_eff_x10 // 10
            if r_eff < 1:
                r_eff = 1
            r_eff2 = r_eff * r_eff
            if d2 <= r_eff2:
                d = isqrt(d2)
                idx = (d + t) % pal_len
                pixels.append(palette[idx])
            else:
                pixels.append(BLACK)
        rows.append(run_length_row(pixels))
    sun_layer = render.Column(children = rows)

    # Text overlay: UV value + category with black box backing for legibility
    uvi_text = format_one_decimal(uvi)
    text_overlay = render.Box(
        width = W,
        height = H,
        child = render.Column(
            cross_align = "center",
            main_align = "center",
            expanded = True,
            children = [
                render.Box(
                    width = len(uvi_text) * 6 + 4,
                    height = 13,
                    color = BLACK,
                    child = render.Text(content = uvi_text, font = "6x13", color = cat_color),
                ),
                render.Box(width = 1, height = 1),
                render.Box(
                    width = len(cat_label) * 4 + 4,
                    height = 7,
                    color = BLACK,
                    child = render.Text(content = cat_label, font = "tom-thumb", color = cat_color),
                ),
            ],
        ),
    )

    return render.Stack(children = [sun_layer, text_overlay])

# MARKER:WINDOW

# Beach Window: next 5 hours, header verdict (TTB-aware), bars + absolute
# hour labels like "6P 7P". Tide-wash highlight sweeps across the bars.
# Verdict logic:
#   BURN <30M  - red, current burn time too short to be useful
#   GO NOW     - teal, current UV inside [lo, hi] band
#   OK SOON    - sky, acceptable within 1h
#   WAIT Nh    - orange, acceptable later today
#   TOO HOT    - red, current too high and no relief in window
#   SKIP       - red, never acceptable in window

WIN_N = 5

def view_window(data, tz, lo, hi, skin):
    hrs = next_hours(data, tz, WIN_N)
    now_uv = hrs[0][1]
    ttb = burn_minutes(now_uv, skin)

    if now_uv > 0.5 and ttb > 0 and ttb < 30:
        v_label = "BURN<%dM" % 30
        v_color = ALERT
    elif lo <= now_uv and now_uv <= hi:
        v_label = "GO NOW"
        v_color = TEAL
    else:
        wait_i = -1
        for i in range(1, len(hrs)):
            u = hrs[i][1]
            if lo <= u and u <= hi:
                wait_i = i
                break
        if wait_i == 1:
            v_label = "OK SOON"
            v_color = SKY
        elif wait_i > 1:
            v_label = "WAIT %dH" % wait_i
            v_color = WARM
        elif now_uv > hi:
            v_label = "TOO HOT"
            v_color = ALERT
        else:
            v_label = "SKIP"
            v_color = ALERT

    # Header row: verdict (left) + TTB readout (right). 11 px tall using 6x13.
    ttb_text = format_burn(ttb)
    ttb_color = TEAL if ttb == 0 else (ALERT if ttb < 30 else (WARM if ttb < 60 else SAND))
    header = render.Box(
        width = W,
        height = 11,
        color = BLACK,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(content = v_label, font = "tb-8", color = v_color),
                render.Text(content = ttb_text, font = "tb-8", color = ttb_color),
            ],
        ),
    )

    strip_frames = []
    for t in range(FRAMES):
        strip_frames.append(window_strip_frame(hrs, t))
    strip = render.Animation(children = strip_frames)

    # Absolute hour labels: 6P / 12P / 12A in tom-thumb. ~12px per cell, 5 cells = 60px,
    # center inside 64px (2px lead).
    labels = []
    labels.append(render.Box(width = 2, height = 6))
    for i in range(WIN_N):
        t_i = hrs[i][0]
        labels.append(render.Box(
            width = WIN_CELL_W,
            height = 6,
            child = render.Text(content = fmt_hour(t_i.hour), font = "tom-thumb", color = SAND),
        ))
    labels.append(render.Box(width = 2, height = 6))
    label_row = render.Row(children = labels)

    return render.Column(children = [header, strip, label_row])

WIN_CELL_W = 12
WIN_CELL_H = 15
WIN_GAP = 0

def fmt_hour(h):
    """Compact am/pm hour like '6P' or '12A'."""
    if h == 0:
        return "12A"
    if h < 12:
        return "%dA" % h
    if h == 12:
        return "12P"
    return "%dP" % (h - 12)

def window_strip_frame(hrs, t):
    cells = []
    cells.append(render.Box(width = 2, height = WIN_CELL_H))
    for i in range(WIN_N):
        if i < len(hrs):
            u = hrs[i][1]
        else:
            u = 0.0
        _, c = uv_category(u)
        h = int((u / 11.0) * WIN_CELL_H + 0.5)
        if h < 1 and u > 0.1:
            h = 1
        if h > WIN_CELL_H:
            h = WIN_CELL_H
        empty_h = WIN_CELL_H - h
        cols = []

        # one-pixel left/right separator inside each cell so adjacent cells read
        # as separate bars even if same color
        for x in range(WIN_CELL_W):
            wave_phase = (i * WIN_CELL_W + x - t * 2) % 16
            bright = (wave_phase < 2)
            sep = (x == 0 or x == WIN_CELL_W - 1)
            col_pixels = []
            for y in range(WIN_CELL_H):
                if y < empty_h:
                    col_pixels.append(BLACK)
                elif sep and h < WIN_CELL_H:
                    # darker shoulder pixel
                    col_pixels.append(darken(c, 0.55))
                elif bright and y == WIN_CELL_H - 1:
                    col_pixels.append(WHITE)
                elif bright and y == WIN_CELL_H - 2:
                    col_pixels.append(lighten(c, 0.4))
                else:
                    col_pixels.append(c)

            # run-length collapse the column
            col_boxes = []
            prev = ""
            n = 0
            for px in col_pixels:
                if px == prev:
                    n += 1
                else:
                    if prev != "":
                        col_boxes.append(render.Box(width = 1, height = n, color = prev))
                    prev = px
                    n = 1
            if prev != "":
                col_boxes.append(render.Box(width = 1, height = n, color = prev))
            cols.append(render.Column(children = col_boxes))
        cells.append(render.Row(children = cols))
    cells.append(render.Box(width = 2, height = WIN_CELL_H))
    return render.Row(children = cells)

# MARKER:BURN

# Burn Timer: explicit "TIME TO BURN" labelling, big readout, UV+skin row
# at the bottom. Heat-shimmer background gets more intense with UV.
#
# Layout (32 rows):
#   rows 0-5    TIME TO BURN header (tom-thumb, sand)
#   rows 6-18   Big readout (6x13)
#   rows 19-25  UV n.n  SKIN III   (tom-thumb, two-col row)
#   rows 26-31  Reserved for shimmer bleed-through

def view_burn(data, skin):
    uvi = float(data["now"]["uvi"])
    mins = burn_minutes(uvi, skin)
    big_text = format_burn(mins)

    if mins == 0:
        big_color = TEAL
    elif mins < 15:
        big_color = ALERT
    elif mins < 45:
        big_color = WARM
    elif mins < 120:
        big_color = YELLOW
    else:
        big_color = TEAL

    _, cat_color = uv_category(uvi)

    fg = render.Column(
        cross_align = "center",
        main_align = "start",
        children = [
            render.Box(
                width = W,
                height = 6,
                child = render.Text(content = "TIME TO BURN", font = "tom-thumb", color = SAND),
            ),
            render.Box(
                width = len(big_text) * 6 + 6,
                height = 15,
                color = BLACK,
                child = render.Text(content = big_text, font = "6x13", color = big_color),
            ),
            render.Box(
                width = W,
                height = 6,
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(content = "UV " + format_one_decimal(uvi), font = "tom-thumb", color = cat_color),
                    ],
                ),
            ),
        ],
    )

    frames = []
    for t in range(FRAMES):
        bg = burn_shimmer_frame(uvi, t)
        frames.append(render.Stack(children = [bg, fg]))
    return render.Animation(children = frames)

def burn_shimmer_frame(uvi, t):
    """Sparse per-pixel shimmer. Density and ember risk scale with UV.
    Skips rows 0..5 (header), 6..20 (big text), and 21..26 (uv row) so text stays legible."""
    _, c = uv_category(uvi)
    dim = darken(c, 0.5)
    dimmer = darken(c, 0.75)
    ember = uvi >= 8
    skip = 9 - int(uvi)
    if skip < 3:
        skip = 3
    rows = []
    for y in range(H):
        pixels = []

        # leave text bands clear
        if (y >= 0 and y < 6) or (y >= 21 and y < 27):
            for _x in range(W):
                pixels.append(BLACK)
            rows.append(run_length_row(pixels))
            continue
        for x in range(W):
            phase = (x * 7 + y * 3 + t * 2) % skip
            if phase == 0:
                wave = SIN8[(y + t) % 8]
                if ember and (x * 13 + y * 11 + t * 5) % 17 == 0:
                    pixels.append(ALERT)
                elif wave > 0:
                    pixels.append(dim)
                elif wave < 0:
                    pixels.append(dimmer)
                else:
                    pixels.append(c)
            else:
                pixels.append(BLACK)
        rows.append(run_length_row(pixels))
    return render.Column(children = rows)

# MARKER:WEEK

# 5-Day Peaks (bubbling thermometers):
#   rows 0-4    Peak UV value above each bar (tom-thumb, centered)
#   rows 5-25   Thermometer (20 px tall): dark column outline + rising bubbles
#               and a category-colored mercury fill column. Bubbles drift up
#               with a deterministic per-bar phase, wobbling left/right via SIN8.
#   row 26      Best-day indicator (white hat) or spacer
#   rows 27-31  Weekday label (Mon/Tue/...)

WEEK_BAR_W = 11
WEEK_GAP = 2
WEEK_PEAK_H = 5
WEEK_BARS_H = 20
WEEK_HAT_H = 1
WEEK_LABEL_H = 6

def view_week(data, tz):
    days = days_ahead(data, tz, 5)

    # Best beach day: lowest peak that's at least 3 ("enough to tan, not bake").
    # If nothing reaches 3, pick the highest of the low-UV days as a fallback.
    best_idx = 0
    best_score = 999.0
    for i, d in enumerate(days):
        p = d["peak_uvi"]
        if p >= 3:
            score = p
        else:
            score = 100 - p
        if score < best_score:
            best_score = score
            best_idx = i

    frames = []
    for t in range(FRAMES):
        col_children = []
        for i, d in enumerate(days):
            col_children.append(week_column(d, i == best_idx, t, i))
            if i < len(days) - 1:
                col_children.append(render.Box(width = WEEK_GAP, height = H))
        frames.append(render.Row(children = col_children))
    return render.Animation(children = frames)

# Short day-of-week labels to save space
WEEK_DAY_ABBR = {"Mon": "M", "Tue": "T", "Wed": "W", "Thu": "Th", "Fri": "F", "Sat": "Sa", "Sun": "Su"}

def week_column(d, is_best, t, seed):
    """One vertical strip: peak text on top, thermometer middle, label bottom."""
    peak = d["peak_uvi"]
    _, c = uv_category(peak)
    peak_text = "%d" % int(peak + 0.5)
    peak_color = c if peak >= 1 else SAND

    peak_box = render.Box(
        width = WEEK_BAR_W,
        height = WEEK_PEAK_H,
        child = render.Text(content = peak_text, font = "tom-thumb", color = peak_color),
    )
    therm = week_thermometer(peak, c, t, seed)
    if is_best:
        hat = render.Box(width = WEEK_BAR_W, height = WEEK_HAT_H, color = WHITE)
    else:
        hat = render.Box(width = WEEK_BAR_W, height = WEEK_HAT_H, color = BLACK)
    label_color = WHITE if is_best else SAND
    day_abbr = WEEK_DAY_ABBR.get(d["label"][:3], d["label"][:2])
    label_box = render.Box(
        width = WEEK_BAR_W,
        height = WEEK_LABEL_H,
        child = render.Text(content = day_abbr, font = "tom-thumb", color = label_color),
    )
    return render.Column(children = [peak_box, therm, hat, label_box])

def week_thermometer(peak, c, t, seed):
    """Bubbling thermometer column WEEK_BAR_W x WEEK_BARS_H pixels.
    Mercury fill height = (peak/12)*H. Bubbles drift upward inside the fill.
    The empty (above-mercury) section is fully BLACK."""
    h = WEEK_BARS_H
    w = WEEK_BAR_W
    fill_h = int((peak / 12.0) * h + 0.5)
    if fill_h < 1 and peak > 0.1:
        fill_h = 1
    if fill_h > h:
        fill_h = h
    empty_h = h - fill_h

    # Mercury palette: dark base + bright surface
    base = darken(c, 0.55)
    mid = darken(c, 0.20)
    surface = lighten(c, 0.30)

    # Build occupancy grid w x h, then RLE per row.
    grid = []
    for y in range(h):
        row = []
        for x in range(w):
            row.append(BLACK)
        grid.append(row)

    # Fill mercury body (gradient: darker at bottom, lighter near surface)
    if fill_h > 0:
        for y in range(empty_h, h):
            for x in range(w):
                # column shoulder pixels are slightly darker so the cylinder reads
                if x == 0 or x == w - 1:
                    grid[y][x] = darken(c, 0.7)
                elif y == empty_h:
                    grid[y][x] = surface
                else:
                    # depth ramp
                    rel = (y - empty_h) * 3 // max(fill_h, 1)
                    if rel == 0:
                        grid[y][x] = surface
                    elif rel == 1:
                        grid[y][x] = mid
                    else:
                        grid[y][x] = base

    # Bubbles: 4 per bar, each drifts up. Phase = (seed offset + t) mod period.
    n_bubbles = 4
    period = fill_h if fill_h > 0 else 1
    bubble_color = lighten(c, 0.55)
    for b in range(n_bubbles):
        if fill_h <= 1:
            break

        # phase progresses with t; faster speed at higher UV
        speed = 1 + (b % 2)  # 1 or 2 rows per frame
        pos = (seed * 7 + b * (period // n_bubbles + 1) + t * speed) % period
        by = h - 1 - pos  # render bottom-up: pos 0 = at bottom
        if by < empty_h:
            continue

        # horizontal wobble via SIN8 (range -1..1 px)
        wob = SIN8[(by + seed * 3 + b) % 8]
        bx = (w // 2) + wob
        if bx < 1:
            bx = 1
        if bx > w - 2:
            bx = w - 2
        grid[by][bx] = bubble_color

        # trailing pixel directly below to suggest motion
        if by + 1 < h:
            grid[by + 1][bx] = lighten(c, 0.15)

    rows = []
    for y in range(h):
        rows.append(run_length_row(grid[y]))
    return render.Column(children = rows)

# MARKER:ARC

# Sun Arc Dual Day:
#   Row 0-5     "UV 2-day" header (tb-8, top-left)
#   rows 6-18   Today's arc with current-time marker and sunrise/sunset indicators
#   row 19      1px divider
#   rows 20-31  Tomorrow's arc with sunrise/sunset indicators
#   Sunrise/sunset shown as colored vertical markers (gold=rise, indigo=set)

# Approximate sunrise/sunset hours by latitude (rough model)
SUNRISE_COLOR = "#ffcc44"
SUNSET_COLOR = "#6644aa"

def estimate_sun_hours(lat):
    """Rough sunrise/sunset hour estimate. Returns (rise_hour, set_hour)."""
    lat_f = float(lat) if lat else 21.0

    # Simple model: near equator ~6/18, higher lat varies more
    if lat_f > 60:
        rise = 4
        sset = 22
    elif lat_f > 45:
        rise = 5
        sset = 21
    elif lat_f > 30:
        rise = 6
        sset = 19
    else:
        rise = 6
        sset = 18
    return (rise, sset)

def view_arc(data, tz):
    days = days_ahead(data, tz, 2)
    today = days[0]
    tomorrow = days[1]
    now_local = time.now().in_location(tz)
    cur_hour = now_local.hour
    cur_minute = now_local.minute

    # Estimate sunrise/sunset from UV data: first/last hour with UV > 0
    rise_h, set_h = arc_sun_hours(today["hours"])
    rise_h2, set_h2 = arc_sun_hours(tomorrow["hours"])

    header_h = 6
    top_h = 12
    bot_h = 12

    header = render.Box(
        width = W,
        height = header_h,
        color = BLACK,
        child = render.Text(content = "UV 2-day", font = "tom-thumb", color = SAND),
    )

    frames = []
    for t in range(FRAMES):
        top = arc_band(today, top_h, cur_hour, cur_minute, t, rise_h = rise_h, set_h = set_h)
        bot = arc_band(tomorrow, bot_h, -1, 0, t, rise_h = rise_h2, set_h = set_h2)
        frames.append(render.Column(children = [
            header,
            top,
            render.Box(width = W, height = 2, color = NAVY),
            bot,
        ]))
    return render.Animation(children = frames)

def arc_sun_hours(hours):
    """Find first and last hour with UV > 0 as sunrise/sunset proxy."""
    rise = 6
    sset = 18
    for i in range(24):
        if hours[i] > 0.1:
            rise = i
            break
    for i in range(23, -1, -1):
        if hours[i] > 0.1:
            sset = i
            break
    return (rise, sset)

def arc_band(day, h, cur_hour, cur_minute, t, rise_h = 6, set_h = 18):
    """Render a band of 24 hourly samples connected by an animated polyline.

    cur_hour >= 0 enables the vertical current-time line on this band.
    rise_h/set_h draw sunrise/sunset markers."""
    hours = day["hours"]

    # Compute (x, y) per hour. y is high (low row index) for high UV.
    pts_y = [0] * 24
    pts_x = [0] * 24
    for i in range(24):
        u = hours[i]

        # invert so high UV draws toward the top of the band
        norm = u / 12.0
        if norm > 1:
            norm = 1.0
        if norm < 0:
            norm = 0
        y = h - 1 - int(norm * (h - 2) + 0.5)
        if y < 0:
            y = 0
        if y > h - 1:
            y = h - 1
        pts_y[i] = y
        pts_x[i] = int((i * (W - 1)) / 23.0 + 0.5)

    # Pick peak hour (max UV); if everything is 0, no peak marker.
    peak_h_idx = 0
    peak_u = 0.0
    for i in range(24):
        if hours[i] > peak_u:
            peak_u = hours[i]
            peak_h_idx = i

    # Pick palette based on overall peak.
    _, peak_color = uv_category(peak_u)

    # Animated "draw" progress: 0..23, advancing two hours per frame, wrapping.
    draw_to = (t * 3) % 24

    grid = []
    for y in range(h):
        grid.append([BLACK] * W)

    # Draw connecting line segments up to draw_to (or all if peak_u == 0).
    if peak_u > 0.01:
        last_i = draw_to
    else:
        last_i = 23
    for i in range(last_i):
        x0 = pts_x[i]
        y0 = pts_y[i]
        x1 = pts_x[i + 1]
        y1 = pts_y[i + 1]
        u_seg = (hours[i] + hours[i + 1]) / 2.0
        _, seg_c = uv_category(u_seg)

        # if both endpoints are at the baseline (no UV) draw a dim line
        if hours[i] <= 0 and hours[i + 1] <= 0:
            seg_color = darken(STEEL, 0.6)
        else:
            seg_color = seg_c
        draw_line(grid, x0, y0, x1, y1, seg_color)

    # Always draw the dots themselves (small, brighter than line).
    for i in range(24):
        x = pts_x[i]
        y = pts_y[i]
        u = hours[i]
        if u <= 0.05:
            dot_color = darken(STEEL, 0.4)
        else:
            _, c = uv_category(u)
            dot_color = lighten(c, 0.2)
        if 0 <= x and x < W and 0 <= y and y < h:
            grid[y][x] = dot_color

    # Peak marker: bright pulsing 3-pixel cross.
    if peak_u > 0.5:
        px = pts_x[peak_h_idx]
        py = pts_y[peak_h_idx]
        pulse = (SIN16[(t * 2) % 16] + 100) // 50  # 0..4
        glow_color = lighten(peak_color, 0.4 if pulse > 2 else 0.2)
        for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
            gx = px + dx
            gy = py + dy
            if 0 <= gx and gx < W and 0 <= gy and gy < h:
                if dx == 0 and dy == 0:
                    grid[gy][gx] = WHITE
                else:
                    grid[gy][gx] = glow_color

    # Sunrise/sunset vertical markers: dashed style (every other pixel)
    rise_x = int((rise_h * (W - 1)) / 23.0 + 0.5)
    set_x = int((set_h * (W - 1)) / 23.0 + 0.5)
    for y in range(h):
        # sunrise marker: gold dashes
        if y % 2 == 0 and 0 <= rise_x and rise_x < W:
            if grid[y][rise_x] == BLACK:
                grid[y][rise_x] = SUNRISE_COLOR

        # sunset marker: indigo dashes
        if y % 2 == ((t // 2) % 2) and 0 <= set_x and set_x < W:
            if grid[y][set_x] == BLACK:
                grid[y][set_x] = SUNSET_COLOR

    # Vertical current-time line (today band only). Full-height, 1 px wide,
    # interpolated between hourly buckets.
    if cur_hour >= 0:
        line_x = int(((cur_hour + cur_minute / 60.0) * (W - 1)) / 23.0 + 0.5)
        if line_x < 0:
            line_x = 0
        if line_x >= W:
            line_x = W - 1
        line_color = WHITE
        for y in range(h):
            # don't paint over the peak white pixel
            if grid[y][line_x] == BLACK:
                grid[y][line_x] = line_color
            elif grid[y][line_x] == darken(STEEL, 0.4) or grid[y][line_x] == darken(STEEL, 0.6):
                grid[y][line_x] = line_color

    rows = []
    for y in range(h):
        rows.append(run_length_row(grid[y]))
    return render.Column(children = rows)

# MARKER:ARC1

# Sun Arc Single Day: full-width arc for today with:
#   - Numeric hour labels along the bottom (6A, 9A, 12, 3P, 6P)
#   - Peak UV value displayed on the curve at the peak point
#   - Current UV value shown in the top-right corner
#   - Sunrise/sunset dashed markers
#   - Current-time vertical line

ARC1_GRAPH_H = 22
ARC1_LABEL_H = 6
ARC1_HEADER_H = 4

# Hour tick positions for the x-axis labels (spread to avoid overlap)
ARC1_TICKS = [6, 10, 14, 18]
ARC1_TICK_LABELS = ["6A", "10", "2P", "6P"]

def view_arc1(data, tz):
    """Single-day arc with numeric indicators."""
    days = days_ahead(data, tz, 1)
    today = days[0]
    now_local = time.now().in_location(tz)
    cur_hour = now_local.hour
    cur_minute = now_local.minute
    cur_uvi = float(data["now"]["uvi"])

    rise_h, set_h = arc_sun_hours(today["hours"])

    # Find peak
    peak_uvi = 0.0
    peak_hour = 12
    for i in range(24):
        if today["hours"][i] > peak_uvi:
            peak_uvi = today["hours"][i]
            peak_hour = i

    _, cur_color = uv_category(cur_uvi)
    _, peak_color = uv_category(peak_uvi)

    frames = []
    for t in range(FRAMES):
        frame = arc1_frame(today, cur_hour, cur_minute, cur_uvi, cur_color, peak_uvi, peak_hour, peak_color, rise_h, set_h, t)
        frames.append(frame)
    return render.Animation(children = frames)

def arc1_frame(day, cur_hour, cur_minute, cur_uvi, cur_color, peak_uvi, peak_hour, peak_color, rise_h, set_h, t):
    """Build one frame of the arc1 view."""
    hours = day["hours"]
    graph_h = ARC1_GRAPH_H

    # Compute curve points
    pts_y = [0] * 24
    pts_x = [0] * 24
    for i in range(24):
        u = hours[i]
        norm = u / 12.0
        if norm > 1:
            norm = 1.0
        if norm < 0:
            norm = 0
        y = graph_h - 1 - int(norm * (graph_h - 2) + 0.5)
        if y < 0:
            y = 0
        if y > graph_h - 1:
            y = graph_h - 1
        pts_y[i] = y
        pts_x[i] = int((i * (W - 1)) / 23.0 + 0.5)

    # Build pixel grid for the graph area
    grid = []
    for y in range(graph_h):
        grid.append([BLACK] * W)

    # Draw all line segments (fully drawn, no animation on this view for clarity)
    for i in range(23):
        x0 = pts_x[i]
        y0 = pts_y[i]
        x1 = pts_x[i + 1]
        y1 = pts_y[i + 1]
        u_seg = (hours[i] + hours[i + 1]) / 2.0
        if hours[i] <= 0 and hours[i + 1] <= 0:
            seg_color = darken(STEEL, 0.6)
        else:
            _, seg_c = uv_category(u_seg)
            seg_color = seg_c
        draw_line(grid, x0, y0, x1, y1, seg_color)

    # Dots at each hour
    for i in range(24):
        x = pts_x[i]
        y = pts_y[i]
        u = hours[i]
        if u <= 0.05:
            dot_color = darken(STEEL, 0.4)
        else:
            _, c = uv_category(u)
            dot_color = lighten(c, 0.2)
        if 0 <= x and x < W and 0 <= y and y < graph_h:
            grid[y][x] = dot_color

    # Peak marker: pulsing cross
    if peak_uvi > 0.5:
        px = pts_x[peak_hour]
        py = pts_y[peak_hour]
        pulse = (SIN16[(t * 2) % 16] + 100) // 50
        glow_color = lighten(peak_color, 0.4 if pulse > 2 else 0.2)
        for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
            gx = px + dx
            gy = py + dy
            if 0 <= gx and gx < W and 0 <= gy and gy < graph_h:
                if dx == 0 and dy == 0:
                    grid[gy][gx] = WHITE
                else:
                    grid[gy][gx] = glow_color

    # Sunrise/sunset markers
    rise_x = int((rise_h * (W - 1)) / 23.0 + 0.5)
    set_x = int((set_h * (W - 1)) / 23.0 + 0.5)
    for y in range(graph_h):
        if y % 2 == 0 and 0 <= rise_x and rise_x < W:
            if grid[y][rise_x] == BLACK:
                grid[y][rise_x] = SUNRISE_COLOR
        if y % 2 == ((t // 2) % 2) and 0 <= set_x and set_x < W:
            if grid[y][set_x] == BLACK:
                grid[y][set_x] = SUNSET_COLOR

    # Current-time vertical line
    if cur_hour >= 0:
        line_x = int(((cur_hour + cur_minute / 60.0) * (W - 1)) / 23.0 + 0.5)
        if line_x < 0:
            line_x = 0
        if line_x >= W:
            line_x = W - 1
        for y in range(graph_h):
            if grid[y][line_x] == BLACK:
                grid[y][line_x] = WHITE
            elif grid[y][line_x] == darken(STEEL, 0.4) or grid[y][line_x] == darken(STEEL, 0.6):
                grid[y][line_x] = WHITE

    # Convert grid to render rows
    graph_rows = []
    for y in range(graph_h):
        graph_rows.append(run_length_row(grid[y]))
    graph_layer = render.Column(children = graph_rows)

    # Peak UV label: positioned near the peak point on the curve
    peak_text = "%d" % int(peak_uvi + 0.5)
    peak_px = pts_x[peak_hour]
    peak_py = pts_y[peak_hour]

    # Place peak label just above the peak point (shift left if near right edge)
    peak_label_x = peak_px - 2
    peak_label_y = peak_py - 6
    if peak_label_y < 0:
        peak_label_y = peak_py + 2
    if peak_label_x < 0:
        peak_label_x = 0
    if peak_label_x > W - 8:
        peak_label_x = W - 8

    # Current UV in top-right
    cur_text = "%d" % int(cur_uvi + 0.5)

    # Overlay: peak label near curve + current UV top-right
    overlay = render.Stack(children = [
        render.Box(width = W, height = graph_h),
        # Peak UV label on the curve
        render.Padding(
            pad = (peak_label_x, peak_label_y, 0, 0),
            child = render.Box(
                width = len(peak_text) * 4 + 3,
                height = 6,
                color = BLACK,
                child = render.Text(content = peak_text, font = "tom-thumb", color = peak_color),
            ),
        ),
        # Current UV top-right
        render.Padding(
            pad = (W - len(cur_text) * 4 - 4, 0, 0, 0),
            child = render.Box(
                width = len(cur_text) * 4 + 4,
                height = 7,
                color = BLACK,
                child = render.Text(content = cur_text, font = "tom-thumb", color = cur_color),
            ),
        ),
    ])

    # Hour labels along the bottom — placed at their exact x positions
    label_children = []
    prev_end = 0
    for i in range(len(ARC1_TICKS)):
        tick_h = ARC1_TICKS[i]
        tick_x = int((tick_h * (W - 1)) / 23.0 + 0.5)
        lbl = ARC1_TICK_LABELS[i]
        lbl_w = len(lbl) * 4 + 1
        lbl_x = tick_x - lbl_w // 2
        if lbl_x < 0:
            lbl_x = 0
        if lbl_x + lbl_w > W:
            lbl_x = W - lbl_w

        # Add spacer from previous label end to this label start
        gap = lbl_x - prev_end
        if gap > 0:
            label_children.append(render.Box(width = gap, height = ARC1_LABEL_H))
        elif gap < 0:
            # overlap — skip this label
            continue
        label_children.append(
            render.Text(content = lbl, font = "tom-thumb", color = SAND),
        )
        prev_end = lbl_x + lbl_w
    label_row = render.Row(children = label_children)

    # Combine: graph with overlay + labels
    graph_with_labels = render.Stack(children = [graph_layer, overlay])

    return render.Column(children = [
        render.Box(width = W, height = ARC1_HEADER_H),
        graph_with_labels,
        label_row,
    ])

def draw_line(grid, x0, y0, x1, y1, color):
    """Bresenham-ish line into the grid. Won't overwrite existing non-black
    pixels at the segment endpoints (so dots stay bright)."""
    dx = x1 - x0
    if dx < 0:
        dx = -dx
    dy = y1 - y0
    if dy < 0:
        dy = -dy
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    x = x0
    y = y0
    h = len(grid)
    w = len(grid[0]) if h > 0 else 0

    # Cap iterations to canvas perimeter
    for _ in range(2 * (W + H)):
        if 0 <= x and x < w and 0 <= y and y < h:
            if grid[y][x] == BLACK:
                grid[y][x] = color
        if x == x1 and y == y1:
            return
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x += sx
        if e2 < dx:
            err += dx
            y += sy

# MARKER:SCHEMA

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "view",
                name = "View",
                desc = "Which UV visualization to show.",
                icon = "image",
                default = "baker",
                options = [
                    schema.Option(display = "Solar Baker (now)", value = "baker"),
                    schema.Option(display = "Beach Window (next hours)", value = "window"),
                    schema.Option(display = "Burn Timer (now)", value = "burn"),
                    schema.Option(display = "5-Day Peaks", value = "week"),
                    schema.Option(display = "Sun Arc Dual Day", value = "arc"),
                    schema.Option(display = "Sun Arc Today", value = "arc1"),
                ],
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for UV index forecast.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "refresh_minutes",
                name = "Refresh interval",
                desc = "How often to fetch fresh UV data.",
                icon = "clock",
                default = "30",
                options = [
                    schema.Option(display = "15 minutes", value = "15"),
                    schema.Option(display = "30 minutes", value = "30"),
                    schema.Option(display = "1 hour", value = "60"),
                    schema.Option(display = "2 hours", value = "120"),
                    schema.Option(display = "4 hours", value = "240"),
                ],
            ),
            schema.Dropdown(
                id = "skin_type",
                name = "Skin type (Burn Timer)",
                desc = "Fitzpatrick scale, affects burn-time math.",
                icon = "user",
                default = "III",
                options = [
                    schema.Option(display = "I  - Very fair", value = "I"),
                    schema.Option(display = "II - Fair", value = "II"),
                    schema.Option(display = "III - Medium", value = "III"),
                    schema.Option(display = "IV - Olive", value = "IV"),
                    schema.Option(display = "V  - Brown", value = "V"),
                    schema.Option(display = "VI - Dark", value = "VI"),
                ],
            ),
            schema.Text(
                id = "target_lo",
                name = "Beach low UV (Window)",
                desc = "Lower bound of the 'safe to go' UV band.",
                icon = "sun",
                default = "3",
            ),
            schema.Text(
                id = "target_hi",
                name = "Beach high UV (Window)",
                desc = "Upper bound of the 'safe to go' UV band.",
                icon = "sun",
                default = "7",
            ),
        ],
    )
