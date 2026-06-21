"""
Sky Today - a living pixel diorama of the actual sky above you.

Layers (back to front):
  1. Sky gradient   - palette driven by real sun elevation (dawn/day/dusk/night)
  2. Stars          - twinkle at night
  3. Sun or Moon    - positioned along a real arc; moon shows current phase
  4. Weather sprites- drifting clouds, falling rain/snow (fog greys the sky)
  5. Wind effects   - streaks/debris/cloud-race that stack as wind climbs
  6. Temperature    - tiny optional readout + wind flag on a ground bar

APIs: Open-Meteo (free, no key) for current weather.
Sun math: pixlet's built-in sunrise module (no network needed).
Moon phase: computed locally from the date.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

WIDTH = 64
HEIGHT = 32
N_FRAMES = 60  # ~7.2s loop @ FRAME_DELAY; longer loop = gentler cloud drift
FRAME_DELAY = 120  # ms per frame

DEFAULT_LOCATION = """
{
    "lat": "37.0298687",
    "lng": "-76.3452218",
    "description": "Hampton, VA, USA",
    "locality": "Hampton",
    "place_id": "",
    "timezone": "America/New_York"
}
"""

WEATHER_URL = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=weather_code,temperature_2m,wind_speed_10m,wind_direction_10m,precipitation,snowfall,cloud_cover&hourly=weather_code&forecast_hours=4&temperature_unit=%s&windspeed_unit=%s"

# US National Weather Service active alerts (free, no key, US-only). Filtered to
# the serious tiers server-side; requires a User-Agent per NWS policy.
NWS_ALERTS_URL = "https://api.weather.gov/alerts/active?status=actual&severity=Severe,Extreme&point=%s,%s"
NWS_USER_AGENT = "SkyToday Tidbyt app (github.com/evan-vandyke/SkyToday)"
NWS_HEADERS = {"User-Agent": NWS_USER_AGENT, "Accept": "application/geo+json"}

# NWS current-observation crawl: point -> nearest station -> latest observation.
# US-only; gives real station (METAR) conditions instead of a forecast nowcast.
NWS_POINTS_URL = "https://api.weather.gov/points/%s,%s"
NWS_OBS_URL = "https://api.weather.gov/stations/%s/observations/latest"

# ===========================================================================
# LOCAL PREVIEW FALLBACK -- MUST BE False IN PRODUCTION.
# `pixlet serve` auto-fills schema.Location with a fixed Brooklyn default when
# nothing is chosen, which bypasses DEFAULT_LOCATION. When this flag is True we
# detect that exact sentinel and substitute the Hampton home default so local
# previews aren't stuck on New York. In PROD this MUST be False, otherwise real
# Brooklyn users sitting on those coordinates would be silently moved to
# Hampton. Run `bash tests/check_prod_ready.sh` before publishing -- it fails
# if this is still True.
# ===========================================================================
LOCAL_PREVIEW_FALLBACK = False

PIXLET_DEFAULT_LAT = 40.6781784
PIXLET_DEFAULT_LNG = -73.9441579

def _is_pixlet_sentinel(lat, lng):
    return abs(lat - PIXLET_DEFAULT_LAT) < 0.0005 and abs(lng - PIXLET_DEFAULT_LNG) < 0.0005

def _use_home_fallback(lat, lng):
    """Only swap in the home default when the local-preview flag is on AND the
    incoming coords are pixlet serve's Brooklyn sentinel. In prod the flag is
    False, so real locations (Brooklyn included) are always respected."""
    return LOCAL_PREVIEW_FALLBACK and _is_pixlet_sentinel(lat, lng)

# ---------------------------------------------------------------------------
# Sky palettes: 4 bands, top -> bottom, chosen by sun elevation (degrees).
# ---------------------------------------------------------------------------

PALETTES = [
    # (min_elevation, [top, upper-mid, lower-mid, bottom])
    (25, ["#1d6ee0", "#2f83ec", "#4a9bf5", "#7cc0ff"]),  # high day
    (10, ["#2a72d8", "#3f8be8", "#65a8f2", "#9ccdff"]),  # day
    (3, ["#3a6bbf", "#6f86c9", "#d98a5f", "#f2b25c"]),  # golden hour
    (-3, ["#2b3a6e", "#6e4a7e", "#c95f63", "#e8975a"]),  # sunset/sunrise
    (-9, ["#141b3d", "#2a2a5e", "#54356b", "#7c4a63"]),  # civil twilight
    (-15, ["#0a0e24", "#13183b", "#1d1f4a", "#2a2750"]),  # nautical twilight
    (-90, ["#04061a", "#070a23", "#0a0e2b", "#0e1233"]),  # night
]

# Fog/whiteout: the sky color is gone, so the whole background goes flat grey
# (light by day, dark by night) instead of a colored gradient with haze lines.
# FOG_DAY is a bright whiteout (like OVERCAST_DAY, a touch lighter/flatter); the
# warm sun_glow_widget still blends through it, so foggy mornings keep a soft sun.
FOG_DAY = ["#eceef0", "#e4e6e9", "#dcdfe3", "#d4d8dd"]
FOG_NIGHT = ["#363b45", "#31363f", "#2c3139", "#282c34"]

# Overcast: a flat, light grey so the dark storm clouds read clearly against it
# (the contrast lives in the sky being light, not in bright cloud rims).
OVERCAST_DAY = ["#e6e9ed", "#dde0e5", "#d4d8de", "#cbd0d7"]
OVERCAST_NIGHT = ["#1f222a", "#22252e", "#252934", "#282c37"]

# Daytime snow (blizzard / heavy snow under a grey sky): the fog/overcast skies
# are bright whiteouts, so white flakes would vanish. A darker steel-grey backdrop
# gives the snow something to read against. (Night snow already shows on the dark
# night/fog skies, so this is day-only.)
SNOWSTORM_DAY = ["#8b95a6", "#838d9e", "#7b8595", "#737d8d"]

def pick_palette(elev):
    for min_elev, colors in PALETTES:
        if elev >= min_elev:
            return colors
    return PALETTES[-1][1]

def sky_palette(elev, is_day, fog, clouds, storm, precip):
    """Choose the background palette: daytime-snow steel > fog whiteout > overcast
    grey > the normal elevation-driven gradient. Overcast/storm flatten the blue
    so a fully clouded sky reads grey rather than sunny; daytime snow gets a
    darker backdrop so white flakes don't vanish into a bright whiteout."""
    if is_day and precip == "snow" and (fog or clouds >= 4 or storm):
        return SNOWSTORM_DAY
    if fog:
        return FOG_DAY if is_day else FOG_NIGHT
    if clouds >= 4 or storm:
        return OVERCAST_DAY if is_day else OVERCAST_NIGHT
    return pick_palette(elev)

def sky_background(colors):
    return render.Column(
        children = [
            render.Box(width = WIDTH, height = 8, color = colors[0]),
            render.Box(width = WIDTH, height = 8, color = colors[1]),
            render.Box(width = WIDTH, height = 8, color = colors[2]),
            render.Box(width = WIDTH, height = 8, color = colors[3]),
        ],
    )

# ---------------------------------------------------------------------------
# Stars (night only): fixed scatter, gentle twinkle.
# ---------------------------------------------------------------------------

STARS = [
    (4, 3),
    (11, 9),
    (17, 4),
    (24, 12),
    (30, 2),
    (36, 7),
    (43, 11),
    (49, 5),
    (55, 9),
    (60, 3),
    (8, 15),
    (27, 17),
    (46, 16),
    (58, 14),
    (20, 20),
    (38, 21),
]

def star_layer(frame, brightness):
    # brightness 0.0-1.0 fades stars in through twilight
    if brightness <= 0:
        return render.Box(width = 1, height = 1)
    dots = []
    for i, pos in enumerate(STARS):
        x, y = pos

        # each star twinkles on its own cycle
        on = (frame + i * 3) % 12 < 9
        if not on:
            continue
        c = "#ffffff" if brightness > 0.7 else "#9aa3c0"
        dots.append(render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = 1, height = 1, color = c),
        ))
    if len(dots) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = dots)

# ---------------------------------------------------------------------------
# Sun and moon
# ---------------------------------------------------------------------------

def arc_position(fraction):
    """Map progress (0..1) across the sky to an (x, y) pixel position."""
    x = int(2 + fraction * (WIDTH - 11))
    y = int(24 - 18 * math.sin(math.pi * fraction))
    return x, max(2, y)

def sun_widget():
    return render.Stack(
        children = [
            # soft glow
            render.Padding(pad = (0, 0, 0, 0), child = render.Circle(diameter = 7, color = "#ffdf80")),
            render.Padding(pad = (1, 1, 0, 0), child = render.Circle(diameter = 5, color = "#ffd23f")),
            render.Padding(pad = (2, 2, 0, 0), child = render.Circle(diameter = 3, color = "#fff3b0")),
        ],
    )

def sun_glow_widget():
    """A diffuse sun behind fog: concentric translucent discs (~11px) that fade
    outward, so the sun reads as a soft glowing patch rather than a hard disc."""
    return render.Stack(
        children = [
            # warmer amber outward (holds its color over the bright fog instead of
            # washing to white), fading to a hot near-white core
            render.Padding(pad = (0, 0, 0, 0), child = render.Circle(diameter = 11, color = "#ffc06a30")),
            render.Padding(pad = (1, 1, 0, 0), child = render.Circle(diameter = 9, color = "#ffc87852")),
            render.Padding(pad = (2, 2, 0, 0), child = render.Circle(diameter = 7, color = "#ffd5917e")),
            render.Padding(pad = (3, 3, 0, 0), child = render.Circle(diameter = 5, color = "#ffe6b2aa")),
            render.Padding(pad = (4, 4, 0, 0), child = render.Circle(diameter = 3, color = "#fff3d0cc")),
        ],
    )

def _rnd(v):
    """Round to nearest int, away from zero on .5 (Starlark int() truncates)."""
    return int(v + 0.5) if v >= 0 else int(v - 0.5)

def sun_rays_layer(frame, cx, cy, n, base, amp):
    """A shimmering warm sunburst radiating from the sun center (cx, cy). Drawn
    behind the sun disc. `n` rays, `base` reach, `amp` shimmer breadth are set by
    the caller from sun elevation + the Off/Subtle/Bold mode: low sun -> short
    soft orb, high sun -> longer beaming. Each ray's length 'breathes' on its own
    phase so the burst feels alive (gentle shimmer) without spinning."""
    start = 4  # begin just outside the 7px disc
    step = 2.0 * math.pi / N_FRAMES  # one cycle per loop (slowest seamless rate)
    rays = []
    for k in range(n):
        ang = 2.0 * math.pi * k / n
        ca = math.cos(ang)
        sa = math.sin(ang)

        # smaller phase spread -> rays breathe more together (less busy flicker)
        length = base + _rnd(amp * math.sin(frame * step + k * 0.35))
        for r in range(start, start + length):
            px = cx + _rnd(r * ca)
            py = cy + _rnd(r * sa)
            if px < 0 or px >= WIDTH or py < 0 or py >= HEIGHT:
                continue
            t = (r - start) / float(length)  # 0 at sun, ~1 at tip
            if t < 0.4:
                col = "#ffe9a8d8"
            elif t < 0.72:
                col = "#ffd591a0"
            else:
                col = "#ffc06a66"
            rays.append(render.Padding(pad = (px, py, 0, 0), child = render.Box(width = 1, height = 1, color = col)))
    if len(rays) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = rays)

def _hex2(n):
    """Clamp 0-255 and format as a 2-digit hex byte (Starlark % has no %02x)."""
    n = 0 if n < 0 else (255 if n > 255 else n)
    d = "0123456789abcdef"
    return d[n // 16] + d[n % 16]

def sunrise_orb_widget(strength, big):
    """A soft warm glow bloom around a low sun (sunrise/sunset). Concentric warm
    discs fading outward; overall opacity scales with `strength` (1 at the
    horizon -> 0 by mid-sky), so the sun reads as a big radiant orb low and hands
    off to the beaming rays as it climbs. `big` = the Bold mode (wider, warmer)."""
    if big:
        specs = [(15, "#ff9866", 0x30), (13, "#ffa86a", 0x48), (11, "#ffbc78", 0x68), (9, "#ffd28e", 0x92), (7, "#ffe6b4", 0xbe)]
    else:
        specs = [(13, "#ff9e6b", 0x33), (11, "#ffac6a", 0x4d), (9, "#ffc07a", 0x70), (7, "#ffd594", 0x99), (5, "#ffe7b8", 0xc2)]
    outer = specs[0][0]
    kids = []
    for d, rgb, a in specs:
        inset = (outer - d) // 2
        alpha = _rnd(a * strength)
        if alpha <= 0:
            continue
        kids.append(render.Padding(pad = (inset, inset, 0, 0), child = render.Circle(diameter = d, color = rgb + _hex2(alpha))))
    if len(kids) == 0:
        return None
    return render.Stack(children = kids)

def sky_body_kind(is_day, fog, clouds, precip):
    """What to render for the celestial body: a crisp 'sun', a diffuse 'glow'
    (sun behind fog), the 'moon', or 'none' (hidden by overcast/fog/heavy snow)."""
    if is_day:
        # heavy daytime snow (blizzard / snowstorm) is a whiteout -- hide the sun
        if precip == "snow" and (fog or clouds >= 4):
            return "none"
        if fog:
            return "glow"
        if clouds >= 4:
            return "none"
        return "sun"
    if fog or clouds >= 4:
        return "none"
    return "moon"

def moon_phase_fraction(now):
    """0 = new moon, 0.5 = full, approaching 1 = back to new."""

    # Reference new moon: 2000-01-06 18:14 UTC
    ref = time.time(year = 2000, month = 1, day = 6, hour = 18, minute = 14, location = "UTC")
    days = (now.unix - ref.unix) / 86400.0
    synodic = 29.530588
    frac = (days % synodic) / synodic
    return frac

def moon_widget(phase, sky_color):
    """Pixel moon with a shadow disc offset to suggest the phase. The shadow is
    painted in `sky_color` (the sky band behind the moon) so the unlit part
    blends into the background instead of reading as a black disc."""
    base = render.Circle(diameter = 7, color = "#e8e8d8")
    crater = render.Padding(pad = (2, 3, 0, 0), child = render.Box(width = 1, height = 1, color = "#c9c9b8"))

    # true illuminated fraction: 0 at new, 1 at full
    lit = (1 - math.cos(2 * math.pi * phase)) / 2
    if lit > 0.92:
        return render.Stack(children = [base, crater])  # essentially full

    # the shadow disc slides aside just far enough to leave a lit sliver
    # `shadow_off` pixels wide, so the offset tracks illumination
    shadow_off = min(6, max(1, int(lit * 7 + 0.5)))
    if phase < 0.5:
        # waxing: lit on the right, shadow shifted left
        shadow = _shadow_disc(-shadow_off, sky_color)
    else:
        # waning: lit on the left, shadow shifted right
        shadow = _shadow_disc(shadow_off, sky_color)
    return render.Stack(children = [base, crater, shadow])

def _shadow_disc(offset, color):
    """Sky-colored circle shifted horizontally by offset pixels to carve the
    crescent (can't pad negative, so negative offsets are simulated with column
    slicing). `color` matches the sky band so the unlit moon blends in."""
    if offset >= 0:
        return render.Padding(pad = (offset, 0, 0, 0), child = render.Circle(diameter = 7, color = color))

    # negative offset: draw boxes column by column approximating a shifted circle
    cols = []
    for x in range(7):
        sx = x - offset  # source column in the un-shifted circle
        h = _circle_col_height(sx)
        if h <= 0:
            cols.append(render.Box(width = 1, height = 1))
        else:
            cols.append(render.Padding(
                pad = (0, (7 - h) // 2, 0, 0),
                child = render.Box(width = 1, height = h, color = color),
            ))
    return render.Row(children = cols)

def _circle_col_height(x):
    """Height of column x in a 7px circle."""
    if x < 0 or x > 6:
        return 0
    heights = [3, 5, 7, 7, 7, 5, 3]
    return heights[x]

# ---------------------------------------------------------------------------
# Weather sprites
# ---------------------------------------------------------------------------

# Cloud sprite variants as box templates: (x, y, w, h, kind, leans).
#   kind  "h" = highlight, "c" = main color
#   leans  True = top puff shifts with the wind `lean`
CLOUD_SHAPES = [
    # 0: small (~9x5)
    [(2, 0, 5, 2, "h", True), (0, 2, 9, 3, "c", False), (1, 1, 3, 1, "h", True)],
    # 1: medium (~13x6)
    [(3, 0, 7, 3, "h", True), (0, 2, 13, 4, "c", False), (2, 1, 4, 2, "h", True)],
    # 2: large (~18x7)
    [(4, 0, 9, 3, "h", True), (0, 3, 18, 4, "c", False), (2, 1, 6, 2, "h", True), (11, 1, 5, 2, "h", True)],
]

def _cloud_boxes(shape, color, highlight, lean):
    """Boxes (x, y, w, h, color) for a shape, with `lean` applied to the top
    puffs (clamped >= 0 so left padding never goes negative)."""
    boxes = []
    for bx, by, bw, bh, kind, leans in CLOUD_SHAPES[shape]:
        x = max(0, bx + lean) if leans else bx
        boxes.append((x, by, bw, bh, highlight if kind == "h" else color))
    return boxes

def _draw_cloud(x, y, shape, color, highlight, lean):
    """Render a cloud whose left edge is at x (may be negative when entering
    from the left). Boxes are clipped against the left edge — Padding can't be
    negative — so clouds slide in smoothly instead of freezing at x=0. The right
    edge is clipped by the display."""
    children = []
    for bx, by, bw, bh, c in _cloud_boxes(shape, color, highlight, lean):
        ax = x + bx
        w = bw
        if ax < 0:
            w = bw + ax  # drop the columns left of the screen
            ax = 0
        if w <= 0 or ax >= WIDTH:
            continue
        children.append(render.Padding(pad = (ax, y + by, 0, 0), child = render.Box(width = w, height = bh, color = c)))
    if len(children) == 0:
        return None
    return render.Stack(children = children)

# A pool of candidate cloud placements: (home_x on-screen, y, shape index).
# More slots than max clouds so the set + arrangement can vary day to day.
CLOUD_SLOTS = [
    (4, 4, 1),
    (40, 6, 2),
    (22, 13, 0),
    (52, 3, 0),
    (14, 9, 2),
    (34, 2, 1),
]
CLOUD_MARGIN = 18  # widest shape; off-screen margin so clouds enter/exit cleanly
CLOUD_WRAP = WIDTH + CLOUD_MARGIN

def build_cloud_plan(count, seed):
    """Pick `count` slots from the pool, rotated by `seed`, so the chosen
    clouds (positions + shapes) shift over time instead of always the same one.
    Returns a list of (home_x, y, shape)."""
    n = len(CLOUD_SLOTS)
    if count > n:
        count = n
    plan = []
    for i in range(count):
        plan.append(CLOUD_SLOTS[(seed + i) % n])
    return plan

def _cloud_x(frame, home_x, speed, wraps, dx):
    """Cloud left-edge x for a frame. With wraps == 0 (calm) the cloud sits
    still at home_x. Otherwise it advances exactly speed*wraps full wraps over
    the loop, so frame 0 == frame N_FRAMES (seamless) and it crosses the screen;
    a moving cloud's frame 0 also lands on home_x."""
    if wraps <= 0:
        return home_x
    travel = frame * speed * wraps * CLOUD_WRAP // N_FRAMES
    if dx >= 0:
        return (home_x + CLOUD_MARGIN + travel) % CLOUD_WRAP - CLOUD_MARGIN
    return (home_x + CLOUD_MARGIN - travel) % CLOUD_WRAP - CLOUD_MARGIN

def cloud_layer(frame, plan, color, highlight, wraps, lean, dx):
    """Draw the planned clouds: static when wraps == 0 (calm), else drifting in
    the wind direction (dx), faster at higher tiers, with a sideways lean."""
    children = []
    for home_x, y, shape in plan:
        x = _cloud_x(frame, home_x, 1, wraps, dx)
        c = _draw_cloud(x, y, shape, color, highlight, lean * dx)
        if c != None:
            children.append(c)
    if len(children) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = children)

# Drop columns by intensity level (1 light/drizzle, 2 moderate, 3 heavy/downpour).
# Denser at higher levels.
PRECIP_COLS = {
    1: [8, 26, 44, 60],
    2: [5, 13, 22, 30, 39, 47, 56, 61],
    3: [2, 8, 14, 20, 26, 32, 38, 44, 50, 56, 61],
}

def precip_layer(frame, kind, level):
    """Falling rain or snow, scaled by intensity `level` (1-3): higher = more
    drops, faster, longer rain streaks."""
    if level < 1:
        return render.Box(width = 1, height = 1)
    if level > 3:
        level = 3
    cols = PRECIP_COLS[level]
    drops = []
    if kind == "snow":
        speed = 1 if level < 3 else 2
        color = "#dfe9ff" if level == 1 else "#eef4ff"
        flake = 1 if level == 1 else 2  # fine specks for a flurry, fat flakes for heavier snow
        for i, x in enumerate(cols):
            # scatter each column's start height (not a linear i*offset) so the
            # flakes fall evenly across the sky instead of forming a diagonal line
            off = (x * 7 + i * 13) % HEIGHT
            y = (frame * speed + off) % HEIGHT
            drops.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = flake, height = flake, color = color)))
    else:
        speed = 2 if level < 3 else 3
        length = level  # 1px drizzle, 2px rain, 3px downpour streaks
        color = "#9fd1ff" if level == 1 else "#6fb7ff"
        for i, x in enumerate(cols):
            y = (frame * speed + i * 7) % HEIGHT
            drops.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = length, color = color)))
    return render.Stack(children = drops)

def weather_kind(code):
    """Map WMO weather code -> sprite plan. `storm` adds the lightning layer."""
    if code == None:
        return struct(clouds = 0, precip = None, fog = False, storm = False)
    if code == 0:
        return struct(clouds = 0, precip = None, fog = False, storm = False)
    if code in [1, 2]:
        return struct(clouds = 1 if code == 1 else 2, precip = None, fog = False, storm = False)
    if code == 3:
        return struct(clouds = 3, precip = None, fog = False, storm = False)
    if code in [45, 48]:
        return struct(clouds = 1, precip = None, fog = True, storm = False)
    if code >= 51 and code <= 67:
        return struct(clouds = 2, precip = "rain", fog = False, storm = False)
    if code >= 71 and code <= 77:
        return struct(clouds = 2, precip = "snow", fog = False, storm = False)
    if code >= 80 and code <= 82:
        return struct(clouds = 3, precip = "rain", fog = False, storm = False)
    if code in [85, 86]:
        return struct(clouds = 3, precip = "snow", fog = False, storm = False)
    if code >= 95:
        return struct(clouds = 3, precip = "rain", fog = False, storm = True)
    return struct(clouds = 1, precip = None, fog = False, storm = False)

def clouds_from_cover(pct):
    """Map real cloud-cover percent to the 0-4 sprite count."""
    if pct < 10:
        return 0
    if pct < 30:
        return 1
    if pct < 55:
        return 2
    if pct < 80:
        return 3
    return 4

def precip_from_obs(base_precip, precip_mm, snow_mm):
    """Turn precip ON from actual observed amounts (mm rain / cm snow), since
    the weathercode nowcast lags real precipitation. Snow wins when present;
    otherwise any measurable precip is rain. Never removes code-based precip."""
    if snow_mm > 0:
        return "snow"
    if precip_mm > 0:
        return "rain"
    return base_precip

def _level_from_code(code):
    """Fallback precip intensity from WMO code when no amount is available."""
    if code == None:
        return 2
    if code in [51, 53, 56, 71, 80, 85]:  # drizzle / light / light showers
        return 1
    if code in [55, 65, 67, 75, 82, 86, 95, 96, 99]:  # heavy / violent
        return 3
    return 2

def precip_level(precip, precip_mm, snow_mm, code):
    """Intensity 1-3 (light/drizzle, moderate, heavy/downpour), 0 if no precip.
    Prefers measured amounts (preceding-hour mm rain / cm snow); falls back to
    the WMO code when the amount is unknown."""
    if precip == None:
        return 0
    if precip == "snow":
        if snow_mm > 0:
            return 1 if snow_mm < 0.5 else (2 if snow_mm < 2.0 else 3)
    elif precip_mm > 0:
        return 1 if precip_mm < 0.5 else (2 if precip_mm < 4.0 else 3)
    return _level_from_code(code)

# NWS METAR cloud-cover codes -> 0-4 sprite count.
_NWS_CLOUD_RANK = {"CLR": 0, "SKC": 0, "FEW": 2, "SCT": 2, "BKN": 3, "OVC": 4, "VV": 4}
_NWS_SNOW = ["snow", "snow_showers", "snow_grains", "ice_pellets", "ice_crystals", "blowing_snow"]
_NWS_RAIN = ["rain", "rain_showers", "drizzle", "freezing_rain", "freezing_drizzle", "hail"]
_NWS_FOG = ["fog", "freezing_fog", "mist", "haze", "smoke", "dust", "sand"]

def _intensity_level(inten):
    """NWS presentWeather intensity string -> 1-3."""
    if inten == "light":
        return 1
    if inten == "heavy":
        return 3
    return 2

def nws_scene(amounts, weathers):
    """Map NWS observation fields to our scene struct. `weathers` is a list of
    (weather, intensity) tuples. Thunderstorms set storm + rain; snow beats
    rain; `level` is the strongest precip intensity seen."""
    clouds = 0
    for a in amounts:
        v = _NWS_CLOUD_RANK.get(a, 0)
        if v > clouds:
            clouds = v
    precip = None
    fog = False
    storm = False
    level = 0
    for w, inten in weathers:
        lv = 0
        if w == "thunderstorms":
            storm = True
            if precip == None:
                precip = "rain"
            lv = 3
        elif w in _NWS_SNOW:
            if precip == None:
                precip = "snow"
            lv = _intensity_level(inten)
        elif w in _NWS_RAIN:
            if precip == None:
                precip = "rain"
            lv = 1 if w == "drizzle" else _intensity_level(inten)
        elif w in _NWS_FOG:
            fog = True
        if lv > level:
            level = lv
    return struct(clouds = clouds, precip = precip, fog = fog, storm = storm, level = level)

def _bolt():
    """A small jagged lightning bolt, drawn as stacked offset boxes."""
    segs = [
        (41, 1, 2, 4),
        (40, 5, 2, 3),
        (42, 7, 2, 4),
        (41, 11, 2, 3),
        (40, 14, 2, 4),
    ]
    cols = []
    for x, y, w, h in segs:
        cols.append(render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = w, height = h, color = "#fdf6c8"),
        ))
    return render.Stack(children = cols)

# frame -> translucent white overlay; the brightest frames also draw a bolt.
# Several strikes spread across the (longer) loop so storms stay lively.
LIGHTNING_FLASHES = {
    2: "#ffffffcc",
    3: "#ffffff99",
    4: "#ffffff44",
    18: "#ffffff88",
    19: "#ffffff33",
    34: "#ffffffcc",
    35: "#ffffff88",
    36: "#ffffff33",
    52: "#ffffff77",
    53: "#ffffff33",
}
LIGHTNING_BOLTS = [2, 3, 34, 35]

def lightning_layer(frame):
    """Quick double-flash with a bolt, overlaid on the whole scene."""
    if frame not in LIGHTNING_FLASHES:
        return render.Box(width = 1, height = 1)
    children = [render.Box(width = WIDTH, height = HEIGHT, color = LIGHTNING_FLASHES[frame])]
    if frame in LIGHTNING_BOLTS:
        children.append(_bolt())
    return render.Stack(children = children)

# ---------------------------------------------------------------------------
# Wind: one intensity scale (internal mph). Effects stack as the tier climbs:
#   0 calm   (<13)  - nothing extra; flag droops
#   1 breeze (13-24)- clouds race + lean
#   2 windy  (25-38)- + horizontal speed streaks
#   3 gale   (39-54)- + tumbling debris
#   4 hurricane(55+)- + rotating eye spiral
# ---------------------------------------------------------------------------

WIND_BREEZE = 13
WIND_WINDY = 25
WIND_GALE = 39
WIND_HURRICANE = 55

def wind_tier(mph):
    if mph >= WIND_HURRICANE:
        return 4
    if mph >= WIND_GALE:
        return 3
    if mph >= WIND_WINDY:
        return 2
    if mph >= WIND_BREEZE:
        return 1
    return 0

def wind_dx(direction):
    """Horizontal blow sign from a meteorological bearing (degrees the wind
    comes FROM): +1 = blows rightward (toward east), -1 = leftward."""
    if direction == None:
        return 1
    s = math.sin(direction * math.pi / 180.0)
    return 1 if s <= 0 else -1

# Cloud wraps-per-loop and lean magnitude per tier. Tier 0 (calm, <13 mph) =
# 0 wraps: clouds sit still, because a seamless loop can't drift slower than
# one full screen pass. Drift only begins at breeze and speeds up from there.
WIND_WRAPS = [0, 1, 2, 3, 4]
WIND_LEAN = [0, 1, 1, 2, 2]

STREAK_ROWS = [3, 9, 15, 20, 24]

def wind_streak_layer(frame, tier, dx):
    """Horizontal gust streaks blowing across the sky (tier >= 2)."""
    if tier < 2:
        return render.Box(width = 1, height = 1)
    n = 2 if tier == 2 else (4 if tier == 3 else 5)
    speed = 4 + tier * 2
    length = 6 + tier * 2
    streaks = []
    for i in range(n):
        y = STREAK_ROWS[i]
        travel = (frame * speed + i * 11) % (WIDTH + length)
        if dx >= 0:
            x = travel - length
        else:
            x = WIDTH - travel
        if x <= -length or x >= WIDTH:
            continue
        streaks.append(render.Padding(
            pad = (max(0, x), y, 0, 0),
            child = render.Box(width = length, height = 1, color = "#e6eeffaa"),
        ))
    if len(streaks) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = streaks)

DEBRIS_COLORS = ["#8a6a4a", "#6f5a3a", "#7a7f8c"]

def debris_layer(frame, tier, dx):
    """Small specks tumbling across at speed (tier >= 3)."""
    if tier < 3:
        return render.Box(width = 1, height = 1)
    count = 4 if tier == 3 else 7
    speed = 5 + tier
    bits = []
    for i in range(count):
        travel = (frame * speed + i * 13) % (WIDTH + 8)
        if dx >= 0:
            x = travel - 4
        else:
            x = WIDTH - travel
        if x < 0 or x > WIDTH - 2:
            continue
        base_y = (i * 9 + 2) % HEIGHT
        y = (base_y + (frame // 2 + i) % 5) % HEIGHT
        col = DEBRIS_COLORS[i % len(DEBRIS_COLORS)]
        bits.append(render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = 2, height = 1, color = col),
        ))
    if len(bits) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = bits)

def hurricane_spiral_layer(frame):
    """A rotating eye + spiral bands, drawn dot-by-dot (tier 4)."""
    cx0 = 31
    cy0 = 12
    children = [render.Padding(pad = (cx0 - 1, cy0 - 1, 0, 0), child = render.Box(width = 2, height = 2, color = "#20242e"))]
    arms = 3

    # 2 full rotations per loop, tied to N_FRAMES so the spin stays seamless
    spin = frame * 2.0 * math.pi * 2.0 / N_FRAMES
    for a in range(arms):
        for r in range(1, 6):
            ang = (a * 2.0 * math.pi / arms) + r * 0.6 + spin
            x = int(cx0 + r * math.cos(ang) * 1.3)
            y = int(cy0 + r * math.sin(ang))
            if x < 0 or x > WIDTH - 1 or y < 0 or y > HEIGHT - 1:
                continue
            shade = "#cfd6e0" if r < 3 else "#9aa6b8"
            children.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = 1, color = shade)))
    return render.Stack(children = children)

def wind_flag(frame, tier, dx):
    """Tiny flag on a pole for the ground bar. Flutters faster at higher tiers
    and streams in the wind direction (dx). At calm the flag just droops."""
    pole = render.Box(width = 1, height = 6, color = "#cfd6e8")
    flag_col = "#ff6a5a"
    if tier <= 0:
        # calm: the flag hangs straight down from the TOP of the pole.
        # Row cross-aligns to the top, so a flag column placed beside the pole
        # starts at the top and droops downward.
        hang = render.Box(width = 1, height = 4, color = flag_col)
        return render.Row(children = [pole, hang], cross_align = "start") if dx >= 0 else render.Row(children = [hang, pole], cross_align = "start")
    step = max(1, 6 - tier)  # smaller step = faster flutter
    ph = (frame // step) % 4
    lens = [4, 3, 2, 3]
    drop = [0, 1, 2, 1]
    flag = render.Padding(pad = (0, drop[ph], 0, 0), child = render.Box(width = lens[ph], height = 2, color = flag_col))
    if dx >= 0:
        return render.Row(children = [pole, flag], cross_align = "start")
    return render.Row(children = [flag, pole], cross_align = "start")

# ---------------------------------------------------------------------------
# Severe-weather alerts: a pulsing corner badge, color by level.
#   1 yellow - storm approaching (Open-Meteo hourly peek, no official alert)
#   2 orange - NWS "Severe" alert active
#   3 red    - NWS "Extreme" alert active
# ---------------------------------------------------------------------------

def alert_level_from_severity(severities):
    """Highest NWS severity -> level. Extreme=3, Severe=2, otherwise 0."""
    level = 0
    for s in severities:
        if s == "Extreme":
            return 3
        if s == "Severe" and level < 2:
            level = 2
    return level

def storm_incoming(codes):
    """True if any upcoming hourly WMO code is a thunderstorm (>= 95)."""
    for c in codes:
        if c != None and c >= 95:
            return True
    return False

def _fmt4(v):
    """Format a float to 4 decimal places. Starlark's % operator has no %.4f,
    and NWS rejects coordinates with more than 4 decimals (301 redirect)."""
    neg = v < 0
    if neg:
        v = -v
    scaled = int(v * 10000 + 0.5)
    whole = scaled // 10000
    frac_s = str(scaled % 10000)
    frac_s = "0" * (4 - len(frac_s)) + frac_s
    out = str(whole) + "." + frac_s
    if neg:
        return "-" + out
    return out

# API throttle: snap coordinates to a coarse grid before building weather/NWS
# URLs. Nearby or rapidly-dragged lat/lng then collapse to the same URL, which
# the http cache (ttl_seconds) already de-dupes -- so micro-adjustments don't
# each fire a fresh call. Grid step is 1/API_SNAP degrees: 100 -> ~1.1 km,
# 22 -> ~5 km (one cache entry per ~5 km tile), 10 -> ~11 km. Coarser = more
# neighbors share one fetch, at the cost of weather granularity.
API_SNAP = 22.0

def _snap(v):
    """Round a coordinate to the API grid (see API_SNAP) for cache-friendly URLs."""
    return float(int(v * API_SNAP + (0.5 if v >= 0 else -0.5))) / API_SNAP

ALERT_BRIGHT = [None, "#ffd23f", "#ff8a3d", "#ff3b30"]
ALERT_DIM = [None, "#8a7320", "#8a4a20", "#7a1d18"]

# triangle rows: (left_pad, width) centered in a 7px box, apex on top
_ALERT_TRI = [(3, 1), (2, 3), (2, 3), (1, 5), (1, 5), (0, 7)]

def alert_badge(frame, level):
    """A pulsing warning triangle (with !) for the top-right corner."""
    if level <= 0:
        return render.Box(width = 1, height = 1)
    col = ALERT_BRIGHT[level] if (frame % 12) < 8 else ALERT_DIM[level]
    rows = []
    for pad_l, w in _ALERT_TRI:
        rows.append(render.Padding(pad = (pad_l, 0, 0, 0), child = render.Box(width = w, height = 1, color = col)))
    triangle = render.Column(children = rows)
    exclaim = render.Stack(children = [
        render.Padding(pad = (3, 1, 0, 0), child = render.Box(width = 1, height = 2, color = "#2a1c00")),
        render.Padding(pad = (3, 4, 0, 0), child = render.Box(width = 1, height = 1, color = "#2a1c00")),
    ])
    return render.Stack(children = [triangle, exclaim])

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def _arc_fraction(now, rise, sett, is_day):
    """Progress 0..1 of the sun (day) or moon (night) across its arc."""
    if rise != None and sett != None and is_day:
        span = sett.unix - rise.unix
        frac = (now.unix - rise.unix) / span if span > 0 else 0.5
    elif rise != None and sett != None:
        # night: estimate progress between today's sunset and ~next sunrise
        night_len = 86400 - (sett.unix - rise.unix)
        if now.unix > sett.unix:
            frac = (now.unix - sett.unix) / night_len
        else:
            frac = (now.unix - (sett.unix - 86400)) / night_len
    else:
        frac = 0.5  # polar edge case: park it overhead
    return min(1.0, max(0.0, frac))

def _fetch_open_meteo(lat, lng):
    """Open-Meteo current= block + hourly storm peek. Fail-soft: ok=False.
    Always fetched in canonical metric (celsius/kmh) so the URL -- and thus the
    shared http cache entry -- is identical for °F and °C users; temp/wind are
    converted to display units by the caller (raw float carried out here)."""
    resp = http.get(WEATHER_URL % (lat, lng, "celsius", "kmh"), ttl_seconds = 600)
    if resp.status_code != 200:
        return struct(ok = False, code = None, temp = None, wind = None, wind_dir = None, cloud_pct = None, precip_mm = 0.0, snow_mm = 0.0, incoming = False)
    data = resp.json()
    code = None
    temp = None
    wind = None
    wind_dir = None
    cloud_pct = None
    precip_mm = 0.0
    snow_mm = 0.0
    cur = data.get("current")
    if cur != None:
        code = int(cur.get("weather_code", 0))
        temp = float(cur.get("temperature_2m", 0))  # raw °C; caller converts+rounds
        wind = float(cur.get("wind_speed_10m", 0))  # raw km/h; caller converts
        wind_dir = float(cur.get("wind_direction_10m", 0))
        cloud_pct = float(cur.get("cloud_cover", 0))
        precip_mm = float(cur.get("precipitation", 0))
        snow_mm = float(cur.get("snowfall", 0))
    incoming = False
    hourly = data.get("hourly")
    if hourly != None:
        incoming = storm_incoming(hourly.get("weather_code", [])[1:4])
    return struct(ok = True, code = code, temp = temp, wind = wind, wind_dir = wind_dir, cloud_pct = cloud_pct, precip_mm = precip_mm, snow_mm = snow_mm, incoming = incoming)

def _nws_val(obj):
    """NWS wraps measurements as {value, unitCode}; pull value, tolerate null."""
    if obj == None:
        return None
    return obj.get("value")

def _fetch_nws_obs(lat, lng, units):
    """US station observation (real conditions). Crawl point -> station ->
    latest. Returns a scene+temp+wind struct, or None to fall back."""
    pt = http.get(NWS_POINTS_URL % (_fmt4(lat), _fmt4(lng)), headers = NWS_HEADERS, ttl_seconds = 86400)
    if pt.status_code != 200:
        return None
    stations_url = pt.json().get("properties", {}).get("observationStations")
    if stations_url == None:
        return None
    st = http.get(stations_url, headers = NWS_HEADERS, ttl_seconds = 86400)
    if st.status_code != 200:
        return None
    feats = st.json().get("features", [])
    if len(feats) == 0:
        return None
    sid = feats[0].get("properties", {}).get("stationIdentifier")
    if sid == None:
        return None
    ob = http.get(NWS_OBS_URL % sid, headers = NWS_HEADERS, ttl_seconds = 300)
    if ob.status_code != 200:
        return None
    props = ob.json().get("properties")
    if props == None:
        return None

    t = _nws_val(props.get("temperature"))
    if t == None:
        return None  # no usable observation -> fall back to Open-Meteo
    temp = int(t * 9.0 / 5.0 + 32 + 0.5) if units == "fahrenheit" else int(t + 0.5)

    ws = _nws_val(props.get("windSpeed"))  # km/h
    wind = 0.0
    if ws != None:
        wind = ws * 0.621371 if units == "fahrenheit" else ws
    wd = _nws_val(props.get("windDirection"))
    wind_dir = wd if wd != None else 0.0

    amounts = []
    for cl in props.get("cloudLayers", []):
        a = cl.get("amount")
        if a != None:
            amounts.append(a)
    weathers = []
    for pw in props.get("presentWeather", []):
        w = pw.get("weather")
        if w != None:
            weathers.append((w, pw.get("intensity")))
    sc = nws_scene(amounts, weathers)
    return struct(clouds = sc.clouds, precip = sc.precip, fog = sc.fog, storm = sc.storm, level = sc.level, temp = temp, wind = wind, wind_dir = wind_dir)

def _live_inputs(config, units):
    """Real sky: sun math (local) + weather (network, fail-soft).
    Source is NWS station obs in the US (Auto/NWS), else Open-Meteo.
    Returns (elev, frac, is_day, wx, temp, phase)."""
    loc = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    tz = loc.get("timezone", "America/New_York")

    # local preview (pixlet serve) hands us the Brooklyn sentinel -> use home.
    # Gated by LOCAL_PREVIEW_FALLBACK so prod never moves real Brooklyn users.
    if _use_home_fallback(lat, lng):
        home = json.decode(DEFAULT_LOCATION)
        lat = float(home["lat"])
        lng = float(home["lng"])
        tz = home.get("timezone", "America/New_York")

    now = time.now().in_location(tz)

    elev = sunrise.elevation(lat, lng, now)
    rise = sunrise.sunrise(lat, lng, now)
    sett = sunrise.sunset(lat, lng, now)
    is_day = elev > 0
    frac = _arc_fraction(now, rise, sett, is_day)
    phase = moon_phase_fraction(now)

    source = config.get("weather_source", "auto")

    # Snap coords for all network calls so jittery lat/lng reuse cached requests
    # (sun/moon math above still uses the exact location).
    qlat = _snap(lat)
    qlng = _snap(lng)

    # Open-Meteo always runs: it's the global fallback and the source of the
    # hourly "storm approaching" peek (NWS observations don't forecast).
    om = _fetch_open_meteo(qlat, qlng)

    # official NWS alerts (US-only, fail-soft). Network errors -> no alert.
    alert = 0
    ar = http.get(NWS_ALERTS_URL % (_fmt4(qlat), _fmt4(qlng)), headers = NWS_HEADERS, ttl_seconds = 300)
    if ar.status_code == 200:
        sevs = []
        for ft in ar.json().get("features", []):
            sevs.append(ft.get("properties", {}).get("severity", ""))
        alert = alert_level_from_severity(sevs)
    if alert == 0 and om.incoming:
        alert = 1  # softer "storm approaching" cue

    # Scene/temp/wind: prefer real US station obs (NWS), else Open-Meteo.
    nws = None
    if source != "openmeteo":
        nws = _fetch_nws_obs(qlat, qlng, units)

    if nws != None:
        clouds = nws.clouds
        precip = nws.precip
        plevel = nws.level
        fog = nws.fog
        storm = nws.storm
        temp = nws.temp
        wind = nws.wind
        wind_dir = nws.wind_dir
    else:
        # Open-Meteo: weathercode classifies fog/storm/base; real observations
        # refine the cloud count and turn precip on when it's actually falling.
        base = weather_kind(om.code)
        clouds = clouds_from_cover(om.cloud_pct) if om.cloud_pct != None else base.clouds
        precip = precip_from_obs(base.precip, om.precip_mm, om.snow_mm)
        plevel = precip_level(precip, om.precip_mm, om.snow_mm, om.code)
        fog = base.fog
        storm = base.storm

        # convert canonical metric -> display units, rounding only after convert
        temp = None if om.temp == None else (int(om.temp * 9.0 / 5.0 + 32 + 0.5) if units == "fahrenheit" else int(om.temp + 0.5))
        wind = None if om.wind == None else (om.wind * 0.621371 if units == "fahrenheit" else om.wind)
        wind_dir = om.wind_dir

    # seed for cloud arrangement; changes hourly so the sky isn't always identical
    cloud_seed = (now.month * 31 + now.day) * 24 + now.hour
    wx = struct(clouds = clouds, precip = precip, precip_level = plevel, fog = fog, storm = storm, wind = wind, wind_dir = wind_dir, alert = alert, cloud_seed = cloud_seed)
    return elev, frac, is_day, wx, temp, phase

def _num(config, key, default):
    """Parse a numeric config string, returning `default` if blank/invalid.
    (Starlark float() raises on bad input, so we validate first.)"""
    s = config.get(key, "")
    if s == None:
        return default
    s = s.strip()
    if s == "":
        return default
    body = s[1:] if s[0] == "-" else s
    if len(body) == 0:
        return default
    dots = 0
    for i in range(len(body)):
        ch = body[i]
        if ch == ".":
            dots += 1
        elif ch < "0" or ch > "9":
            return default
    if dots > 1:
        return default
    return float(s)

# One-click recipes that fill every demo dial at once.
# Fields: elev (°), arc (0-100), phase (0-100), clouds (0-4),
#         precip ("none"/"rain"/"snow"), precip_level (1 light/2 mod/3 heavy),
#         fog, storm, temp (°F), wind (mph),
#         alert (0 none / 1 approaching / 2 severe / 3 extreme).
PRESETS = {
    "thunderstorm": struct(elev = 2, arc = 55, phase = 50, clouds = 4, precip = "rain", precip_level = 3, fog = False, storm = True, temp = 66, wind = 30, alert = 2),
    "night_thunderstorm": struct(elev = -16, arc = 55, phase = 50, clouds = 4, precip = "rain", precip_level = 3, fog = False, storm = True, temp = 61, wind = 28, alert = 2),
    "blizzard": struct(elev = 8, arc = 50, phase = 50, clouds = 4, precip = "snow", precip_level = 3, fog = True, storm = False, temp = 14, wind = 36, alert = 2),
    "gentle_snow": struct(elev = -18, arc = 50, phase = 30, clouds = 2, precip = "snow", precip_level = 1, fog = False, storm = False, temp = 27, wind = 6, alert = 0),
    "overcast_drizzle": struct(elev = 14, arc = 45, phase = 50, clouds = 4, precip = "rain", precip_level = 1, fog = False, storm = False, temp = 54, wind = 16, alert = 0),
    "foggy_morning": struct(elev = 5, arc = 18, phase = 50, clouds = 2, precip = "none", precip_level = 0, fog = True, storm = False, temp = 47, wind = 3, alert = 0),
    "sunrise": struct(elev = 1, arc = 10, phase = 50, clouds = 1, precip = "none", precip_level = 0, fog = False, storm = False, temp = 51, wind = 5, alert = 0),
    "golden_hour": struct(elev = 3, arc = 84, phase = 50, clouds = 1, precip = "none", precip_level = 0, fog = False, storm = False, temp = 72, wind = 7, alert = 0),
    "heatwave": struct(elev = 72, arc = 50, phase = 50, clouds = 0, precip = "none", precip_level = 0, fog = False, storm = False, temp = 101, wind = 4, alert = 0),
    "starry_night": struct(elev = -45, arc = 50, phase = 50, clouds = 0, precip = "none", precip_level = 0, fog = False, storm = False, temp = 44, wind = 2, alert = 0),
    "crescent_moon": struct(elev = -30, arc = 68, phase = 10, clouds = 0, precip = "none", precip_level = 0, fog = False, storm = False, temp = 49, wind = 3, alert = 0),
    "harvest_moon": struct(elev = -6, arc = 88, phase = 50, clouds = 1, precip = "none", precip_level = 0, fog = False, storm = False, temp = 58, wind = 5, alert = 0),
    "hurricane": struct(elev = 6, arc = 50, phase = 50, clouds = 4, precip = "rain", precip_level = 3, fog = False, storm = True, temp = 79, wind = 90, alert = 3),
}

def _demo_inputs(config, units):
    """Simulator: deterministic, offline overrides for every render input.
    Returns (elev, frac, is_day, wx, temp, phase).

    Three ways to drive the sky:
      * Preset: a named recipe fills every dial at once (overrides all below).
      * Manual dials: set sun elevation, arc position, moon phase, weather.
      * Real astronomy: fill demo_lat AND demo_lng and the sun/moon are
        computed for that place at demo_month / demo_hour (location + season).
    """
    preset = config.get("demo_preset", "custom")
    if preset != "custom" and preset in PRESETS:
        p = PRESETS[preset]
        frac = min(1.0, max(0.0, p.arc / 100.0))
        phase = min(1.0, max(0.0, p.phase / 100.0))
        precip = None if p.precip == "none" else p.precip

        # preset wind is stored in mph; show it in the user's display unit
        wind_disp = p.wind if units == "fahrenheit" else p.wind / 0.621371
        plevel = p.precip_level if precip != None else 0
        wx = struct(clouds = p.clouds, precip = precip, precip_level = plevel, fog = p.fog, storm = p.storm, wind = wind_disp, wind_dir = 270.0, alert = p.alert, cloud_seed = 0)
        return p.elev, frac, p.elev > 0, wx, p.temp, phase

    lat_s = config.get("demo_lat", "").strip()
    lng_s = config.get("demo_lng", "").strip()
    if lat_s != "" and lng_s != "":
        lat = _num(config, "demo_lat", 0.0)
        lng = _num(config, "demo_lng", 0.0)
        month = int(_num(config, "demo_month", 6.0))
        hour = int(_num(config, "demo_hour", 12.0))
        now = time.time(year = 2026, month = month, day = 15, hour = hour, minute = 0, second = 0, location = "UTC")
        elev = sunrise.elevation(lat, lng, now)
        rise = sunrise.sunrise(lat, lng, now)
        sett = sunrise.sunset(lat, lng, now)
        is_day = elev > 0
        frac = _arc_fraction(now, rise, sett, is_day)
        phase = moon_phase_fraction(now)
    else:
        elev = _num(config, "demo_elev", 20.0)
        frac = min(1.0, max(0.0, _num(config, "demo_arc", 50.0) / 100.0))
        is_day = elev > 0
        phase = min(1.0, max(0.0, _num(config, "demo_phase", 50.0) / 100.0))

    clouds = int(_num(config, "demo_clouds", 1.0))
    precip = config.get("demo_precip", "none")
    precip = None if precip == "none" else precip
    plevel = int(_num(config, "demo_precip_level", 2.0)) if precip != None else 0
    fog = config.bool("demo_fog", False)
    storm = config.bool("demo_storm", False)
    wind = _num(config, "demo_wind", 10.0)
    wind_dir = _num(config, "demo_wind_dir", 270.0)
    alert = int(_num(config, "demo_alert", 0.0))
    cloud_seed = int(_num(config, "demo_cloud_seed", 0.0))
    wx = struct(clouds = clouds, precip = precip, precip_level = plevel, fog = fog, storm = storm, wind = wind, wind_dir = wind_dir, alert = alert, cloud_seed = cloud_seed)
    temp = int(_num(config, "demo_temp", 63.0))
    return elev, frac, is_day, wx, temp, phase

def main(config):
    units = config.get("units", "fahrenheit")
    show_temp = config.bool("show_temp", True)
    show_wind = config.bool("show_wind", True)
    rays_mode = config.get("sun_rays", "subtle")  # off / subtle / bold
    demo = config.bool("demo_mode", False)

    if demo:
        elev, frac, is_day, wx, temp, phase = _demo_inputs(config, units)
    else:
        elev, frac, is_day, wx, temp, phase = _live_inputs(config, units)

    # wind: convert to mph (display unit may be km/h) and pick an intensity tier
    have_wind = show_wind and wx.wind != None
    if wx.wind != None:
        wind_mph = wx.wind if units == "fahrenheit" else wx.wind * 0.621371
    else:
        wind_mph = 0.0
    tier = wind_tier(wind_mph)
    dx = wind_dx(wx.wind_dir)
    cloud_wraps = WIND_WRAPS[tier]
    lean = WIND_LEAN[tier]
    cloud_plan = build_cloud_plan(wx.clouds, wx.cloud_seed)

    # star brightness fades in below the horizon
    star_bright = 0.0
    if elev < 0:
        star_bright = min(1.0, -elev / 12.0)

    # hide stars under heavy cloud, fog, OR any falling precip -- otherwise white
    # snow/rain at night reads as "falling stars" (you can't see stars through it)
    if wx.clouds >= 3 or wx.fog or wx.precip != None:
        star_bright = 0.0

    palette = sky_palette(elev, is_day, wx.fog, wx.clouds, wx.storm, wx.precip)
    cloud_color = "#e9edf2" if is_day else "#3c4258"
    cloud_hi = "#ffffff" if is_day else "#565e78"

    # Flat-grey-sky scenes (clouds >= 4 or storm -> see sky_palette): the sky is
    # light grey, so dark storm clouds with only a muted (non-white) highlight
    # read clearly without bright rims -- overcast/thunderstorm/blizzard/hurricane.
    if wx.clouds >= 4 or wx.storm:
        cloud_color = "#565d6b" if is_day else "#444b5a"
        cloud_hi = "#636b7a" if is_day else "#525a6b"
    elif wx.precip != None or wx.clouds >= 3:
        # rain/showers under a still-blue sky: moody darkened clouds
        cloud_color = "#8d96a6" if is_day else "#2e3346"
        cloud_hi = "#aab3c2" if is_day else "#454c64"

    # celestial body: hidden under overcast/fog; a diffuse glow when foggy
    cx, cy = arc_position(frac)
    body = None
    bx, by = cx, cy
    kind = sky_body_kind(is_day, wx.fog, wx.clouds, wx.precip)
    if kind == "sun":
        body = sun_widget()
    elif kind == "glow":
        body = sun_glow_widget()
        bx, by = max(0, cx - 2), max(0, cy - 2)  # center the wider glow on the sun
    elif kind == "moon":
        # match the shadow to the sky band the moon sits in (bands are 8px tall)
        moon_band = (cy + 3) // 8
        moon_band = 0 if moon_band < 0 else (3 if moon_band > 3 else moon_band)
        body = moon_widget(phase, palette[moon_band])

    # temperature readout sits on a translucent "ground" bar across the bottom,
    # so it reads as foreground instead of a label floating on the sky. Static
    # across frames, so build it once. The number is tinted by temperature
    # (cold blue -> mild white -> hot orange); the 1px top edge keeps the bar
    # legible even on a dark night sky.
    have_temp = show_temp and temp != None
    bar_static = None
    if have_temp or have_wind:
        bar_kids = [
            render.Padding(pad = (0, 25, 0, 0), child = render.Box(width = WIDTH, height = 7, color = "#0d1330e6")),
            render.Padding(pad = (0, 25, 0, 0), child = render.Box(width = WIDTH, height = 1, color = "#48568a")),
        ]
        if have_temp:
            unit_mark = "F" if units == "fahrenheit" else "C"
            label = "%d°%s" % (temp, unit_mark)
            tf = temp if units == "fahrenheit" else temp * 9.0 / 5.0 + 32
            if tf >= 90:
                tint = "#ff9e6b"
            elif tf >= 75:
                tint = "#ffd79e"
            elif tf >= 55:
                tint = "#ffffff"
            elif tf >= 35:
                tint = "#cfe7ff"
            else:
                tint = "#9fd1ff"
            bar_kids.append(render.Padding(pad = (2, 26, 0, 0), child = render.Text(label, font = "tom-thumb", color = tint)))
        if have_wind:
            wnum = str(int(wx.wind + 0.5))
            bar_kids.append(render.Padding(pad = (39, 26, 0, 0), child = render.Text(wnum, font = "tom-thumb", color = "#bcd0ee")))
        bar_static = render.Stack(children = bar_kids)

    # Sun rays: only on the crisp daytime sun, scaled by elevation so a low
    # sunrise/sunset sun is a short soft orb and a high midday sun beams. The
    # Off/Subtle/Bold mode sets ray count, base reach, and shimmer breadth.
    draw_rays = rays_mode != "off" and kind == "sun"
    ray_n, ray_base, ray_amp = 0, 0, 0
    orb = None
    orb_px, orb_py = 0, 0
    if draw_rays:
        ef = (elev - 5.0) / 50.0  # 0 near horizon -> 1 by ~55 degrees
        ef = 0.0 if ef < 0 else (1.0 if ef > 1 else ef)
        if rays_mode == "bold":
            ray_n = 16
            ray_base = 5 + _rnd(ef * 5)  # 5 (low orb) -> 10 (high beaming)
            ray_amp = 2
        else:  # subtle
            ray_n = 12
            ray_base = 3 + _rnd(ef * 3)  # 3 (low orb) -> 6 (high beaming)
            ray_amp = 1

        # low-sun warm orb: strongest at the horizon, gone by ~18 degrees
        og = (18.0 - elev) / 18.0
        og = 0.0 if og < 0 else (1.0 if og > 1 else og)
        if og > 0.04:
            orb = sunrise_orb_widget(og, rays_mode == "bold")
            outer = 15 if rays_mode == "bold" else 13
            orb_px = max(0, bx + 3 - outer // 2)  # center the orb on the sun disc
            orb_py = max(0, by + 3 - outer // 2)

    # --- build animation frames ---
    frames = []
    for f in range(N_FRAMES):
        layers = [
            sky_background(palette),
            star_layer(f, star_bright),
        ]
        if orb != None:
            layers.append(render.Padding(pad = (orb_px, orb_py, 0, 0), child = orb))
        if draw_rays:
            layers.append(sun_rays_layer(f, bx + 3, by + 3, ray_n, ray_base, ray_amp))
        if body != None:
            layers.append(render.Padding(pad = (bx, by, 0, 0), child = body))
        if wx.clouds > 0:
            layers.append(cloud_layer(f, cloud_plan, cloud_color, cloud_hi, cloud_wraps, lean, dx))
        if wx.precip != None:
            layers.append(precip_layer(f, wx.precip, wx.precip_level))
        if tier >= 2:
            layers.append(wind_streak_layer(f, tier, dx))
        if tier >= 3:
            layers.append(debris_layer(f, tier, dx))
        if tier >= 4:
            layers.append(hurricane_spiral_layer(f))
        if wx.storm:
            layers.append(lightning_layer(f))
        if bar_static != None:
            layers.append(bar_static)
        if have_wind:
            layers.append(render.Padding(pad = (33, 26, 0, 0), child = wind_flag(f, tier, dx)))
        if wx.alert > 0:
            layers.append(render.Padding(pad = (WIDTH - 8, 26, 0, 0), child = alert_badge(f, wx.alert)))
        frames.append(render.Stack(children = layers))

    return render.Root(
        delay = FRAME_DELAY,
        child = render.Animation(children = frames),
    )

def _demo_fields(demo_on):
    """Generated: reveal the simulator dials only when demo mode is on."""
    if demo_on != "true":
        return []
    return [
        schema.Dropdown(
            id = "demo_preset",
            name = "Preset",
            desc = "A one-click scene. Anything other than Custom overrides all the dials below.",
            icon = "wandMagicSparkles",
            default = "custom",
            options = [
                schema.Option(display = "Custom (use dials)", value = "custom"),
                schema.Option(display = "⛈ Thunderstorm", value = "thunderstorm"),
                schema.Option(display = "🌩 Night thunderstorm", value = "night_thunderstorm"),
                schema.Option(display = "❄ Blizzard", value = "blizzard"),
                schema.Option(display = "🌨 Gentle snow", value = "gentle_snow"),
                schema.Option(display = "🌧 Overcast drizzle", value = "overcast_drizzle"),
                schema.Option(display = "🌫 Foggy morning", value = "foggy_morning"),
                schema.Option(display = "🌅 Sunrise", value = "sunrise"),
                schema.Option(display = "🌇 Golden hour", value = "golden_hour"),
                schema.Option(display = "🔥 Heatwave", value = "heatwave"),
                schema.Option(display = "✨ Starry night", value = "starry_night"),
                schema.Option(display = "🌙 Crescent moon", value = "crescent_moon"),
                schema.Option(display = "🌕 Harvest moon", value = "harvest_moon"),
                schema.Option(display = "🌀 Hurricane", value = "hurricane"),
            ],
        ),
        schema.Text(
            id = "demo_elev",
            name = "Sun elevation (°)",
            desc = "Sky look: -90 deep night, 0 horizon, 90 high noon. Ignored if lat+lng set below.",
            icon = "solidSun",
            default = "20",
        ),
        schema.Text(
            id = "demo_arc",
            name = "Arc position (0-100)",
            desc = "Where the sun/moon sits along its arc. 0 = left edge, 50 = top, 100 = right edge.",
            icon = "arrowsLeftRight",
            default = "50",
        ),
        schema.Text(
            id = "demo_phase",
            name = "Moon phase (0-100)",
            desc = "0 = new, 50 = full, 100 = new again. Visible when elevation is below 0.",
            icon = "moon",
            default = "50",
        ),
        schema.Dropdown(
            id = "demo_clouds",
            name = "Cloud cover",
            desc = "How many clouds drift across.",
            icon = "cloud",
            default = "1",
            options = [
                schema.Option(display = "0 - clear", value = "0"),
                schema.Option(display = "1 - few", value = "1"),
                schema.Option(display = "2 - scattered", value = "2"),
                schema.Option(display = "3 - broken", value = "3"),
                schema.Option(display = "4 - overcast", value = "4"),
            ],
        ),
        schema.Text(
            id = "demo_cloud_seed",
            name = "Cloud arrangement",
            desc = "Changes which clouds/positions show (any number). Live, this shifts hourly.",
            icon = "shuffle",
            default = "0",
        ),
        schema.Dropdown(
            id = "demo_precip",
            name = "Precipitation",
            desc = "Falling rain or snow.",
            icon = "cloudRain",
            default = "none",
            options = [
                schema.Option(display = "None", value = "none"),
                schema.Option(display = "Rain", value = "rain"),
                schema.Option(display = "Snow", value = "snow"),
            ],
        ),
        schema.Dropdown(
            id = "demo_precip_level",
            name = "Precip intensity",
            desc = "How hard it's coming down.",
            icon = "cloudShowersHeavy",
            default = "2",
            options = [
                schema.Option(display = "1 - light / drizzle", value = "1"),
                schema.Option(display = "2 - moderate", value = "2"),
                schema.Option(display = "3 - heavy / downpour", value = "3"),
            ],
        ),
        schema.Toggle(
            id = "demo_fog",
            name = "Fog",
            desc = "Drifting haze bands.",
            icon = "smog",
            default = False,
        ),
        schema.Toggle(
            id = "demo_storm",
            name = "Lightning",
            desc = "Overlay a flashing lightning bolt (thunderstorm).",
            icon = "boltLightning",
            default = False,
        ),
        schema.Text(
            id = "demo_wind",
            name = "Wind speed",
            desc = "In the same units as temperature (mph / km/h). ~13 breeze, 25 windy, 39 gale, 55+ hurricane.",
            icon = "wind",
            default = "10",
        ),
        schema.Dropdown(
            id = "demo_wind_dir",
            name = "Wind direction",
            desc = "Which way it blows across the sky.",
            icon = "compass",
            default = "270",
            options = [
                schema.Option(display = "N", value = "0"),
                schema.Option(display = "NE", value = "45"),
                schema.Option(display = "E", value = "90"),
                schema.Option(display = "SE", value = "135"),
                schema.Option(display = "S", value = "180"),
                schema.Option(display = "SW", value = "225"),
                schema.Option(display = "W", value = "270"),
                schema.Option(display = "NW", value = "315"),
            ],
        ),
        schema.Dropdown(
            id = "demo_alert",
            name = "Severe-weather alert",
            desc = "Corner warning badge: storm approaching (yellow), severe (orange), extreme (red).",
            icon = "triangleExclamation",
            default = "0",
            options = [
                schema.Option(display = "None", value = "0"),
                schema.Option(display = "⚠ Storm approaching", value = "1"),
                schema.Option(display = "⚠ Severe", value = "2"),
                schema.Option(display = "⚠ Extreme", value = "3"),
            ],
        ),
        schema.Text(
            id = "demo_temp",
            name = "Temperature readout",
            desc = "Number shown in the corner (needs Show temperature on).",
            icon = "temperatureHalf",
            default = "63",
        ),
        schema.Text(
            id = "demo_lat",
            name = "Override latitude",
            desc = "Real astronomy mode: fill BOTH lat and lng to compute the real sky for a place/season instead of the dials above.",
            icon = "locationDot",
            default = "",
        ),
        schema.Text(
            id = "demo_lng",
            name = "Override longitude",
            desc = "Used with override latitude.",
            icon = "locationDot",
            default = "",
        ),
        schema.Dropdown(
            id = "demo_month",
            name = "Month (season)",
            desc = "Season for real-astronomy mode.",
            icon = "calendar",
            default = "6",
            options = [
                schema.Option(display = "Jan", value = "1"),
                schema.Option(display = "Feb", value = "2"),
                schema.Option(display = "Mar", value = "3"),
                schema.Option(display = "Apr", value = "4"),
                schema.Option(display = "May", value = "5"),
                schema.Option(display = "Jun", value = "6"),
                schema.Option(display = "Jul", value = "7"),
                schema.Option(display = "Aug", value = "8"),
                schema.Option(display = "Sep", value = "9"),
                schema.Option(display = "Oct", value = "10"),
                schema.Option(display = "Nov", value = "11"),
                schema.Option(display = "Dec", value = "12"),
            ],
        ),
        schema.Text(
            id = "demo_hour",
            name = "Hour (0-23 UTC)",
            desc = "Time of day for real-astronomy mode.",
            icon = "clock",
            default = "12",
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "The sky above this location.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Temperature units.",
                icon = "temperatureHalf",
                default = "fahrenheit",
                options = [
                    schema.Option(display = "Fahrenheit", value = "fahrenheit"),
                    schema.Option(display = "Celsius", value = "celsius"),
                ],
            ),
            schema.Toggle(
                id = "show_temp",
                name = "Show temperature",
                desc = "Display the current temperature.",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "show_wind",
                name = "Show wind",
                desc = "Display wind speed + a fluttering flag on the bottom bar.",
                icon = "wind",
                default = True,
            ),
            schema.Dropdown(
                id = "weather_source",
                name = "Weather source",
                desc = "Auto uses real US station observations (NWS) when available, else Open-Meteo.",
                icon = "satelliteDish",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (NWS in US, else Open-Meteo)", value = "auto"),
                    schema.Option(display = "NWS station obs (US only)", value = "nws"),
                    schema.Option(display = "Open-Meteo (global)", value = "openmeteo"),
                ],
            ),
            schema.Dropdown(
                id = "sun_rays",
                name = "Sun rays",
                desc = "Shimmering sunburst on clear days — short orb low, beaming high. Bold exaggerates it.",
                icon = "sun",
                default = "subtle",
                options = [
                    schema.Option(display = "Subtle", value = "subtle"),
                    schema.Option(display = "Bold", value = "bold"),
                    schema.Option(display = "Off", value = "off"),
                ],
            ),
            schema.Toggle(
                id = "demo_mode",
                name = "Demo / simulator mode",
                desc = "Override the real sky with manual dials to test every look.",
                icon = "flask",
                default = False,
            ),
            schema.Generated(
                id = "demo_generated",
                source = "demo_mode",
                handler = _demo_fields,
            ),
        ],
    )
