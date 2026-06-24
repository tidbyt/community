"""IsClaudeUp — Live Anthropic/Claude.ai service status on your Tidbyt."""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

VERSION = "1.0"

STATUS_URL = "https://status.anthropic.com/api/v2/summary.json"

# Anthropic brand colors
CLAY = "#CC785C"
CLAY_MID = "#8C4C34"
CLAY_DIM = "#3D1E12"
BG_LEFT = "#100818"

# Status indicator colors
OK = "#00CC44"
WARN = "#FFAA00"
BAD = "#FF4400"
MAINT = "#4499FF"
UNK = "#666666"

STATUS_COLORS = {
    "none": OK,
    "minor": WARN,
    "major": BAD,
    "critical": BAD,
    "maintenance": MAINT,
}

STATUS_LABELS = {
    "none": "All OK",
    "minor": "Degraded",
    "major": "Outage",
    "critical": "Critical",
    "maintenance": "Maint.",
}

COMP_ICONS = {
    "operational": ("ok", OK),
    "degraded_performance": ("~", WARN),
    "partial_outage": ("!", WARN),
    "major_outage": ("X", BAD),
    "under_maintenance": ("M", MAINT),
}

def indicator_color(ind):
    return STATUS_COLORS.get(ind, UNK)

def indicator_label(ind):
    return STATUS_LABELS.get(ind, "Unknown")

def comp_icon_for(status):
    got = COMP_ICONS.get(status, None)
    return got if got != None else ("?", UNK)

def match_comp(name):
    """Map a Statuspage component name to a short display label."""
    low = name.lower()
    if "workspace" in low:
        return "WS"
    if "claude" in low:
        return "Web"
    if low == "api" or low.endswith(" api") or low.startswith("api "):
        return "API"
    return None

def fetch_status():
    resp = http.get(STATUS_URL, ttl_seconds = 300)
    if resp.status_code != 200:
        return None
    return resp.json()

# ---------------------------------------------------------------------------
# Logo animation — 16x32 pixel panel, Anthropic-inspired pulsing asterisk
# ---------------------------------------------------------------------------

PULSE = [CLAY, "#B86848", CLAY_MID, CLAY_DIM, CLAY_MID, "#B86848", CLAY, "#D08A6C"]

def logo_frame(i, dot_color):
    c = PULSE[i % len(PULSE)]
    diag = c if (i % 2 == 0) else CLAY_DIM
    dot = dot_color if (i % 2 == 0) else CLAY

    return render.Stack(children = [
        # Background
        render.Box(width = 16, height = 32, color = BG_LEFT),
        # Vertical rays
        render.Padding(pad = (7, 2, 0, 0), child = render.Box(width = 2, height = 9, color = c)),
        render.Padding(pad = (7, 21, 0, 0), child = render.Box(width = 2, height = 9, color = c)),
        # Horizontal rays
        render.Padding(pad = (1, 14, 0, 0), child = render.Box(width = 5, height = 2, color = c)),
        render.Padding(pad = (10, 14, 0, 0), child = render.Box(width = 5, height = 2, color = c)),
        # Diagonal corner accents (alternate frames)
        render.Padding(pad = (3, 5, 0, 0), child = render.Box(width = 2, height = 2, color = diag)),
        render.Padding(pad = (11, 5, 0, 0), child = render.Box(width = 2, height = 2, color = diag)),
        render.Padding(pad = (3, 25, 0, 0), child = render.Box(width = 2, height = 2, color = diag)),
        render.Padding(pad = (11, 25, 0, 0), child = render.Box(width = 2, height = 2, color = diag)),
        # Center 4x4 status dot — pulses between status color and clay
        render.Padding(pad = (6, 13, 0, 0), child = render.Box(width = 4, height = 4, color = dot)),
    ])

def logo_animation(dot_color):
    return render.Animation(
        children = [logo_frame(i, dot_color) for i in range(8)],
    )

# ---------------------------------------------------------------------------
# Right panel — status text, component health, incident scroll
# ---------------------------------------------------------------------------

def component_row(components):
    items = []
    seen = {}
    for c in components:
        if c.get("group", False):
            continue
        label = match_comp(c.get("name", ""))
        if label == None or label in seen:
            continue
        seen[label] = True
        icon, color = comp_icon_for(c.get("status", ""))
        items.append(render.Text(label + ":" + icon + " ", font = "CG-pixel-3x5-mono", color = color))

    if not items:
        return render.Box(height = 5)
    return render.Row(children = items, main_align = "start", cross_align = "center")

def incident_scroll(incidents, width):
    if not incidents:
        return None
    inc = incidents[0]
    title = inc.get("name", "Incident")
    updates = inc.get("incident_updates", [])
    body = updates[0].get("body", "") if updates else ""
    text = (title + "  " + body) if body else title
    return render.Marquee(
        child = render.Text(text, font = "CG-pixel-3x5-mono", color = WARN),
        width = width,
        scroll_direction = "horizontal",
        offset_start = width,
        offset_end = 0,
    )

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main(_):
    data = fetch_status()
    if data == None:
        return render.Root(
            child = render.Box(
                width = 64,
                height = 32,
                child = render.Text("Status unavailable", color = BAD, font = "CG-pixel-3x5-mono"),
            ),
        )

    overall = data.get("status", {})
    ind = overall.get("indicator", "unknown")
    components = data.get("components", [])
    incidents = data.get("incidents", [])

    s_color = indicator_color(ind)
    s_label = indicator_label(ind)

    right_w = 46

    status_row = render.Row(
        children = [
            render.Box(width = 4, height = 4, color = s_color),
            render.Padding(
                pad = (2, 0, 0, 0),
                child = render.Text(s_label, font = "tb-8", color = "#FFFFFF"),
            ),
        ],
        main_align = "start",
        cross_align = "center",
    )

    right_rows = [
        render.Padding(pad = (1, 2, 0, 0), child = render.Text("CLAUDE", font = "CG-pixel-3x5-mono", color = CLAY)),
        render.Padding(pad = (1, 1, 0, 0), child = status_row),
        render.Padding(pad = (1, 2, 0, 0), child = component_row(components)),
    ]

    scroll = incident_scroll(incidents, right_w - 1)
    if scroll:
        right_rows.append(render.Padding(pad = (0, 2, 0, 0), child = scroll))

    right_panel = render.Column(
        children = right_rows,
        main_align = "start",
        cross_align = "start",
    )

    return render.Root(
        delay = 120,
        child = render.Row(
            children = [
                logo_animation(s_color),
                render.Box(width = 1, height = 32, color = "#1A1A2E"),
                right_panel,
            ],
            main_align = "start",
            cross_align = "start",
            expanded = True,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
