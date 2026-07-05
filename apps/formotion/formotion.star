"""
Formotion - the five platonic solids in eased, tumbling 3D motion.

Each solid rotates through a segment of the loop (with a fade between
solids), rendered either as a wireframe with depth-shaded edges (closer
edges brighter) or as a shaded solid with flat-lit facets. Color drifts
through a selectable palette across the loop, or a fixed color can be set.

Rendering approach: vertices are rotated and perspective-projected,
edges are rasterized with a DDA line drawer into a 64x32 pixel buffer,
and each buffer row is emitted as horizontal runs of 1px boxes.
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

W = 64
H = 32
CX = 31.5
CY = 15.5
CAM_DIST = 3.0

# Max vertical offset for a unit-sphere vertex is FOCAL * 0.354
# (maximizing y/(z+CAM_DIST) on the sphere), so 40 -> 14.1px, inside H/2.
FOCAL = 40.0

# The full animation stays under pixlet's 15s max duration (also the
# device's default per-app dwell), which keeps the app publishable to
# the community repo without special render flags.
FRAME_DELAY = 50  # ms
FRAMES_CYCLE = 58  # per-solid segment: 5 x 58 x 50ms = 14.5s
FRAMES_SINGLE = 290  # single-solid loop: 290 x 50ms = 14.5s
FADE_FRAMES = 8

PHI = 1.61803398875
DEFAULT_ACCENT = "#00FFC8"

# Shaded mode: unit vector from a surface toward the light, which sits
# to the screen's top right and slightly toward the viewer (screen +y
# points down, hence the negative y; camera looks along +z).
LIGHT = (0.597, -0.696, -0.398)
AMBIENT = 0.18

# Drift palettes: RGB stops sampled cyclically across the loop. Stop
# lists are ping-pong ordered (out and back) so the wrap point is as
# smooth as every other transition.
PALETTES = {
    "heat": [
        (140, 0, 0),
        (255, 60, 0),
        (255, 160, 0),
        (255, 235, 80),
        (255, 255, 220),
        (255, 235, 80),
        (255, 160, 0),
        (255, 60, 0),
    ],
    "synthwave": [
        (255, 40, 170),
        (180, 60, 255),
        (60, 130, 255),
        (180, 60, 255),
    ],
    "ocean": [
        (0, 70, 190),
        (0, 180, 255),
        (130, 255, 210),
        (0, 180, 255),
    ],
    "aurora": [
        (20, 255, 130),
        (0, 210, 190),
        (150, 90, 255),
        (0, 210, 190),
    ],
}

def make_solids():
    tetra = [
        (1.0, 1.0, 1.0),
        (1.0, -1.0, -1.0),
        (-1.0, 1.0, -1.0),
        (-1.0, -1.0, 1.0),
    ]

    cube = []
    for sx in [-1.0, 1.0]:
        for sy in [-1.0, 1.0]:
            for sz in [-1.0, 1.0]:
                cube.append((sx, sy, sz))

    octa = [
        (1.0, 0.0, 0.0),
        (-1.0, 0.0, 0.0),
        (0.0, 1.0, 0.0),
        (0.0, -1.0, 0.0),
        (0.0, 0.0, 1.0),
        (0.0, 0.0, -1.0),
    ]

    dodeca = list(cube)
    for s1 in [-1.0, 1.0]:
        for s2 in [-1.0, 1.0]:
            dodeca.append((0.0, s1 / PHI, s2 * PHI))
            dodeca.append((s1 / PHI, s2 * PHI, 0.0))
            dodeca.append((s1 * PHI, 0.0, s2 / PHI))

    icosa = []
    for s1 in [-1.0, 1.0]:
        for s2 in [-1.0, 1.0]:
            icosa.append((0.0, s1, s2 * PHI))
            icosa.append((s1, s2 * PHI, 0.0))
            icosa.append((s1 * PHI, 0.0, s2))

    solids = []
    for name, verts in [
        ("tetrahedron", tetra),
        ("cube", cube),
        ("octahedron", octa),
        ("dodecahedron", dodeca),
        ("icosahedron", icosa),
    ]:
        nv = normalize(verts)
        solids.append((name, nv, build_edges(nv), build_faces(nv)))
    return solids

def normalize(verts):
    """Scale every vertex onto the unit sphere."""
    out = []
    for x, y, z in verts:
        n = math.sqrt(x * x + y * y + z * z)
        out.append((x / n, y / n, z / n))
    return out

def build_faces(verts):
    """Find faces as supporting planes: for every vertex triple, if all
    other vertices sit on one side of its plane, that plane is a face of
    the (convex) solid. Dedup by normal, then collect each face's ring."""
    faces = []
    normals = []
    for i in range(len(verts)):
        for j in range(i + 1, len(verts)):
            for k in range(j + 1, len(verts)):
                nrm = triangle_normal(verts[i], verts[j], verts[k])
                if nrm == None:
                    continue

                # Orient outward (the origin is inside the solid).
                d = nrm[0] * verts[i][0] + nrm[1] * verts[i][1] + nrm[2] * verts[i][2]
                if d < 0:
                    nrm = (-nrm[0], -nrm[1], -nrm[2])
                    d = -d

                dots = [v[0] * nrm[0] + v[1] * nrm[1] + v[2] * nrm[2] for v in verts]
                if max(dots) > d + 0.001:
                    continue  # plane slices the solid: not a face

                dup = False
                for e in normals:
                    if e[0] * nrm[0] + e[1] * nrm[1] + e[2] * nrm[2] > 0.999:
                        dup = True
                        break
                if dup:
                    continue
                normals.append(nrm)

                ring = [v_i for v_i in range(len(verts)) if dots[v_i] > d - 0.001]
                faces.append(orient_face(verts, order_face(verts, ring)))
    return faces

def triangle_normal(a, b, c):
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    w = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    n = (
        u[1] * w[2] - u[2] * w[1],
        u[2] * w[0] - u[0] * w[2],
        u[0] * w[1] - u[1] * w[0],
    )
    ln = math.sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2])
    if ln < 0.000001:
        return None  # degenerate (collinear) triple
    return (n[0] / ln, n[1] / ln, n[2] / ln)

def order_face(verts, idxs):
    """Chain face vertices into a ring by walking nearest neighbors
    (in a regular polygon the nearest unvisited vertex is adjacent)."""
    ordered = [idxs[0]]
    remaining = list(idxs[1:])
    for _ in range(len(remaining)):
        last = verts[ordered[-1]]
        best = remaining[0]
        best_d2 = None
        for k in remaining:
            v = verts[k]
            dx = v[0] - last[0]
            dy = v[1] - last[1]
            dz = v[2] - last[2]
            d2 = dx * dx + dy * dy + dz * dz
            if best_d2 == None or d2 < best_d2:
                best = k
                best_d2 = d2
        ordered.append(best)
        remaining.remove(best)
    return ordered

def orient_face(verts, idxs):
    """Wind the ring so its normal points away from the origin."""
    nrm = face_normal(verts, idxs)
    cx, cy, cz = centroid(verts, idxs)
    if nrm[0] * cx + nrm[1] * cy + nrm[2] * cz < 0:
        return idxs[::-1]
    return idxs

def face_normal(verts, face):
    a = verts[face[0]]
    b = verts[face[1]]
    c = verts[face[2]]
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    w = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    n = (
        u[1] * w[2] - u[2] * w[1],
        u[2] * w[0] - u[0] * w[2],
        u[0] * w[1] - u[1] * w[0],
    )
    ln = math.sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2])
    return (n[0] / ln, n[1] / ln, n[2] / ln)

def centroid(verts, face):
    cx = 0.0
    cy = 0.0
    cz = 0.0
    for k in face:
        cx += verts[k][0]
        cy += verts[k][1]
        cz += verts[k][2]
    return (cx / len(face), cy / len(face), cz / len(face))

def build_edges(verts):
    """Edges = vertex pairs at the minimum pairwise distance."""
    pairs = []
    min_d2 = None
    for i in range(len(verts)):
        for j in range(i + 1, len(verts)):
            a = verts[i]
            b = verts[j]
            dx = a[0] - b[0]
            dy = a[1] - b[1]
            dz = a[2] - b[2]
            d2 = dx * dx + dy * dy + dz * dz
            pairs.append((d2, i, j))
            if min_d2 == None or d2 < min_d2:
                min_d2 = d2
    return [(i, j) for d2, i, j in pairs if d2 < min_d2 * 1.2]

def main(config):
    choice = config.get("solid", "all")
    palette = config.get("palette", "rainbow")
    if palette != "fixed" and palette not in PALETTES:
        palette = "rainbow"
    accent = config.get("accent", DEFAULT_ACCENT)
    shaded = config.bool("shaded", False)

    solids = make_solids()
    selected = [s for s in solids if s[0] == choice]
    cycle = len(selected) != 1
    if cycle:
        selected = solids

    n_seg = FRAMES_CYCLE if cycle else FRAMES_SINGLE
    fade = FADE_FRAMES if cycle else 0
    total = n_seg * len(selected)

    # Short cycle segments get partial turns; a single-solid loop gets
    # full turns so it wraps seamlessly.
    ax_turns = 0.5 if cycle else 1.0
    ay_turns = 1.0 if cycle else 2.0

    frames = []
    for g in range(total):
        seg = g // n_seg
        _, verts, edges, faces = selected[seg]
        f = g % n_seg
        env = envelope(f, n_seg, fade)
        t = g / total  # 0..1 drift position across the whole loop

        # Stagger each solid's starting orientation so nothing sits in a
        # flat, axis-aligned pose mid-segment. Skipped in single-solid
        # mode (seg 0), where the loop must wrap seamlessly.
        ax0 = 0.7 * seg + (0.35 if cycle else 0.0)
        ay0 = 1.3 * seg

        frames.append(draw_frame(verts, edges, faces, f, n_seg, ax0, ay0, ax_turns, ay_turns, env, t, palette, accent, shaded))

    return render.Root(
        delay = FRAME_DELAY,
        child = render.Animation(children = frames),
    )

def draw_frame(verts, edges, faces, f, n, ax0, ay0, ax_turns, ay_turns, env, t, palette, accent, shaded):
    p = ease_in_out(f / n)
    ax = ax0 + 2.0 * math.pi * ax_turns * p
    ay = ay0 + 2.0 * math.pi * ay_turns * p

    rv = [rotate(v, ax, ay) for v in verts]
    pv = [project(v) for v in rv]

    buf = [[None for x in range(W)] for y in range(H)]
    if shaded:
        draw_shaded(buf, rv, pv, faces, env, t, palette, accent)
    else:
        draw_wireframe(buf, rv, pv, edges, env, t, palette, accent)
    return buf_to_widgets(buf)

def draw_wireframe(buf, rv, pv, edges, env, t, palette, accent):
    # Painter's order: draw far edges first so near (brighter) edges win.
    order = sorted([(-(rv[i][2] + rv[j][2]), i, j) for i, j in edges])
    for _, i, j in order:
        z_avg = (rv[i][2] + rv[j][2]) / 2.0
        depth = 1.0 - 0.55 * (z_avg + 1.0) / 2.0  # near 1.0 -> far 0.45
        color = pick_color(palette, accent, t, depth * env)
        draw_line(buf, pv[i][0], pv[i][1], pv[j][0], pv[j][1], color)

def draw_shaded(buf, rv, pv, faces, env, t, palette, accent):
    for face in faces:
        nrm = face_normal(rv, face)
        cx, cy, cz = centroid(rv, face)

        # Backface cull: the camera sits at (0, 0, -CAM_DIST) looking
        # along +z, so a face is visible when its outward normal points
        # against the camera-to-face direction. Convex solids need no
        # painter's sort after culling.
        if nrm[0] * cx + nrm[1] * cy + nrm[2] * (cz + CAM_DIST) >= 0:
            continue

        diffuse = max(0.0, nrm[0] * LIGHT[0] + nrm[1] * LIGHT[1] + nrm[2] * LIGHT[2])
        color = pick_color(palette, accent, t, (AMBIENT + (1.0 - AMBIENT) * diffuse) * env)

        pts = [pv[k] for k in face]
        fill_polygon(buf, pts, color)

        # Outline in the same color to seal sliver gaps the scanline
        # fill can leave at glancing angles.
        for k in range(len(pts)):
            a = pts[k]
            b = pts[(k + 1) % len(pts)]
            draw_line(buf, a[0], a[1], b[0], b[1], color)

def pick_color(palette, accent, t, val):
    if palette == "rainbow":
        return hsv_to_hex(360.0 * t, 0.65, val)
    if palette == "fixed":
        return scale_color(accent, val)
    return rgb_to_hex(sample_palette(PALETTES[palette], t), val)

def rotate(v, ax, ay):
    x, y, z = v
    ca = math.cos(ax)
    sa = math.sin(ax)
    y2 = y * ca - z * sa
    z2 = y * sa + z * ca
    cb = math.cos(ay)
    sb = math.sin(ay)
    x2 = x * cb + z2 * sb
    z3 = -x * sb + z2 * cb
    return (x2, y2, z3)

def project(v):
    x, y, z = v
    s = FOCAL / (z + CAM_DIST)
    return (CX + x * s, CY + y * s)

def draw_line(buf, x0, y0, x1, y1, color):
    """DDA rasterizer (Starlark has no while loops; bounded for works)."""
    dx = x1 - x0
    dy = y1 - y0
    steps = int(max(math.fabs(dx), math.fabs(dy))) + 1
    for i in range(steps + 1):
        t = i / steps
        x = int(x0 + dx * t + 0.5)
        y = int(y0 + dy * t + 0.5)
        if x >= 0 and x < W and y >= 0 and y < H:
            buf[y][x] = color

def fill_polygon(buf, pts, color):
    """Convex scanline fill, sampling at pixel centers."""
    ys = [p[1] for p in pts]
    y_lo = max(0, int(math.ceil(min(ys) - 0.5)))
    y_hi = min(H - 1, int(math.floor(max(ys) - 0.5)))
    for y in range(y_lo, y_hi + 1):
        yc = y + 0.5
        xs = []
        for k in range(len(pts)):
            x0, y0 = pts[k]
            x1, y1 = pts[(k + 1) % len(pts)]
            if y0 == y1:
                continue
            if (y0 <= yc and yc < y1) or (y1 <= yc and yc < y0):
                xs.append(x0 + (yc - y0) * (x1 - x0) / (y1 - y0))
        if len(xs) < 2:
            continue
        x_lo = max(0, int(math.ceil(min(xs) - 0.5)))
        x_hi = min(W - 1, int(math.floor(max(xs) - 0.5)))
        for x in range(x_lo, x_hi + 1):
            buf[y][x] = color

def buf_to_widgets(buf):
    """Emit each buffer row as horizontal runs of same-colored boxes."""
    rows = []
    for y in range(H):
        children = []
        run_color = None
        run_len = 0
        for x in range(W):
            c = buf[y][x]
            if c == run_color:
                run_len += 1
            else:
                if run_len > 0:
                    children.append(run_box(run_len, run_color))
                run_color = c
                run_len = 1
        if run_len > 0:
            children.append(run_box(run_len, run_color))
        rows.append(render.Row(children = children))
    return render.Column(children = rows)

def run_box(width, color):
    if color:
        return render.Box(width = width, height = 1, color = color)
    return render.Box(width = width, height = 1)

def sample_palette(stops, t):
    """Cyclically interpolate RGB stops at loop position t (0..1)."""
    n = len(stops)
    pos = math.mod(t, 1.0) * n
    i = int(pos) % n
    frac = pos - int(pos)
    c1 = stops[i]
    c2 = stops[(i + 1) % n]
    return (
        c1[0] + (c2[0] - c1[0]) * frac,
        c1[1] + (c2[1] - c1[1]) * frac,
        c1[2] + (c2[2] - c1[2]) * frac,
    )

def rgb_to_hex(rgb, factor):
    out = "#"
    for ch in rgb:
        out += hex2(int(ch * factor + 0.5))
    return out

def ease_in_out(t):
    """Smoothstep: zero velocity at both ends, gentle peak in the middle,
    so each solid settles to a rest before fading to the next. Also makes
    the single-solid loop wrap with matching (near-zero) velocity."""
    return t * t * (3.0 - 2.0 * t)

def envelope(f, n, fade):
    """Fade-in/out brightness at segment boundaries."""
    if fade == 0:
        return 1.0
    if f < fade:
        return f / fade
    if f >= n - fade:
        return (n - 1 - f) / fade
    return 1.0

def hsv_to_hex(h, s, v):
    h = math.mod(h, 360.0)
    c = v * s
    x = c * (1.0 - math.fabs(math.mod(h / 60.0, 2.0) - 1.0))
    if h < 60:
        r, g, b = c, x, 0.0
    elif h < 120:
        r, g, b = x, c, 0.0
    elif h < 180:
        r, g, b = 0.0, c, x
    elif h < 240:
        r, g, b = 0.0, x, c
    elif h < 300:
        r, g, b = x, 0.0, c
    else:
        r, g, b = c, 0.0, x
    m = v - c
    return "#" + hex2(int((r + m) * 255)) + hex2(int((g + m) * 255)) + hex2(int((b + m) * 255))

def scale_color(hex_color, factor):
    c = hex_color.lstrip("#")
    if len(c) == 3:
        c = "".join([ch * 2 for ch in c.elems()])
    out = "#"
    for k in [0, 2, 4]:
        out += hex2(int(int(c[k:k + 2], 16) * factor))
    return out

def hex2(v):
    v = min(255, max(0, v))
    s = "%x" % v
    return s if len(s) == 2 else "0" + s

def get_schema():
    options = [schema.Option(display = "All five (cycle)", value = "all")]
    for name in ["tetrahedron", "cube", "octahedron", "dodecahedron", "icosahedron"]:
        options.append(schema.Option(display = name.title(), value = name))
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "solid",
                name = "Solid",
                desc = "Which form to display.",
                icon = "shapes",
                default = "all",
                options = options,
            ),
            schema.Toggle(
                id = "shaded",
                name = "Shaded solid",
                desc = "Fill the facets and light them from the top right.",
                icon = "lightbulb",
                default = False,
            ),
            schema.Dropdown(
                id = "palette",
                name = "Color drift",
                desc = "Palette the edge color drifts through.",
                icon = "rainbow",
                default = "rainbow",
                options = [
                    schema.Option(display = "Rainbow", value = "rainbow"),
                    schema.Option(display = "Heat map", value = "heat"),
                    schema.Option(display = "Synthwave", value = "synthwave"),
                    schema.Option(display = "Ocean", value = "ocean"),
                    schema.Option(display = "Aurora", value = "aurora"),
                    schema.Option(display = "Fixed color", value = "fixed"),
                ],
            ),
            schema.Color(
                id = "accent",
                name = "Fixed color",
                desc = "Edge color when the Fixed color palette is selected.",
                icon = "palette",
                default = DEFAULT_ACCENT,
            ),
        ],
    )
