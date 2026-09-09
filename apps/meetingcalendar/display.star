"""Native settings, meeting classification, and 64x32 calendar presentation."""

load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAX_ACTIVE_PAGES = 150

DEFAULT_SETTINGS = {
    "displayEnabled": True,
    "normalTheme": "midnight",
    "activeTheme": "red-alert",
    "frameDurationMs": 3000,
    "timeFormat": "12h",
    "showCallBadge": True,
    "maxEvents": 20,
    "activeLabel": "LIVE",
}

NORMAL_COLORS = {
    "midnight": ["#070e1d", "#122d50", "#ebf0ff", "#ffcc33", "#7896be", "#ebf0ff"],
    "ocean": ["#122d50", "#28466e", "#ffffff", "#75ebb4", "#7896be", "#ffffff"],
    "forest": ["#04261c", "#188056", "#ffffff", "#75ebb4", "#7896be", "#ffffff"],
}
ACTIVE_COLORS = {
    "red-alert": ["#6c1224", "#d61840", "#ffffff", "#75ebb4", "#ebf0ff", "#ffffff"],
    "amber": ["#6c1224", "#ffcc33", "#ffffff", "#ffcc33", "#ebf0ff", "#000000"],
    "magenta": ["#5e2070", "#e640aa", "#ffffff", "#75ebb4", "#ebf0ff", "#000000"],
}

# Order is intentionally identical to the private edition when a field has several providers.
PROVIDERS = [
    ("Zoom", r"(?i)\bzoom(?:gov)?\.us/|\bzoom meeting\b"),
    ("Google Meet", r"(?i)\bmeet\.google\.com/|\bhangouts\.google\.com/|\bgoogle meet\b"),
    ("Microsoft Teams", r"(?i)\bteams\.microsoft\.com/|\bteams\.live\.com/|\bmicrosoft teams\b"),
    ("FaceTime", r"(?i)\bfacetime\.apple\.com/|\bfacetime:|\bface ?time\b"),
    ("Webex", r"(?i)\bwebex\.com/|\bwebex\.gov/|\bwebex meeting\b"),
    ("Slack Huddle", r"(?i)\bapp\.slack\.com/huddle|\bslack huddle\b"),
    ("Discord", r"(?i)\bdiscord\.gg/|\bdiscord\.com/channels/"),
    ("Jitsi", r"(?i)\bmeet\.jit\.si/|\bjitsi meet\b"),
    ("Whereby", r"(?i)\bwhereby\.com/"),
    ("GoTo", r"(?i)\b(?:meet|global)\.gotomeeting\.com/|\bgoto meeting\b"),
    ("RingCentral", r"(?i)\b(?:v|meetings)\.ringcentral\.com/"),
]

# Compile once when loading the module, rather than for every calendar occurrence.
COMPILED_PROVIDERS = [(name, re.compile(pattern)) for name, pattern in PROVIDERS]

def parse_settings(config):
    """Return (validated settings, None), or (None, safe error message)."""
    settings = dict(DEFAULT_SETTINGS)
    choices = {
        "normalTheme": NORMAL_COLORS,
        "activeTheme": ACTIVE_COLORS,
        "timeFormat": ["12h", "24h"],
        "activeLabel": ["LIVE", "ON AIR"],
    }
    for key in DEFAULT_SETTINGS:
        value = config.get(key, DEFAULT_SETTINGS[key])
        if key in ["displayEnabled", "showCallBadge"]:
            if type(value) == "string" and value.lower() in ["true", "false"]:
                value = value.lower() == "true"
            if type(value) != "bool":
                return None, "Invalid setting: " + key
        elif key in ["frameDurationMs", "maxEvents"]:
            if type(value) == "string" and value.isdigit() and len(value) <= 5:
                value = int(value)
            if type(value) != "int":
                return None, "Invalid setting: " + key
            if key == "frameDurationMs" and (value < 1000 or value > 10000 or value % 250 != 0):
                return None, "Invalid setting: " + key
            if key == "maxEvents" and (value < 1 or value > 20):
                return None, "Invalid setting: " + key
        elif value not in choices[key]:
            return None, "Invalid setting: " + key
        settings[key] = value
    for key, limit in [("calendarUrl", 8192), ("timezoneOverride", 128)]:
        value = config.get(key, "")
        if type(value) != "string" or len(value) > limit:
            return None, "Invalid setting: " + key
        settings[key] = value.strip()
    return settings, None

def _dropdown(id, name, desc, choices, default, icon = "gear"):
    return schema.Dropdown(
        id = id,
        name = name,
        desc = desc,
        icon = icon,
        default = default,
        options = [schema.Option(display = label, value = value) for value, label in choices],
    )

def build_schema():
    """Called by the entrypoint's sole get_schema function."""
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "calendarUrl", name = "Calendar subscription URL", desc = "Paste an iCloud, Google, or Outlook ICS subscription link. Tidbyt stores this link and can read its calendar. Keep it private.", icon = "calendar"),
        schema.Text(id = "timezoneOverride", name = "Timezone override (optional)", desc = "Leave blank to use your device timezone. Otherwise enter an IANA name, such as America/New_York. Also used for calendar times without a timezone.", icon = "globe"),
        schema.Toggle(id = "displayEnabled", name = "Display calendar", desc = "Applies on the next render; this is not an immediate privacy switch.", icon = "eye", default = True),
        _dropdown("normalTheme", "Calendar theme", "Colors for today's events.", [("midnight", "Midnight"), ("ocean", "Ocean"), ("forest", "Forest")], "midnight", "palette"),
        _dropdown("activeTheme", "Meeting theme", "Colors during a recognized call.", [("red-alert", "Red alert"), ("amber", "Amber"), ("magenta", "Magenta")], "red-alert", "palette"),
        _dropdown("frameDurationMs", "Seconds per event", "How long each normal event is shown. The complete animation is requested before rotation.", [(str(ms), "%s seconds" % (ms / 1000.0)) for ms in range(1000, 10001, 250)], "3000", "clock"),
        _dropdown("timeFormat", "Time format", "Use a 12-hour or 24-hour clock.", [("12h", "12-hour"), ("24h", "24-hour")], "12h", "clock"),
        schema.Toggle(id = "showCallBadge", name = "Show call badge", desc = "Mark recognized calls in today's event list.", icon = "video", default = True),
        _dropdown("maxEvents", "Maximum events", "Limit normal event rotation. All active calls remain visible.", [(str(n), str(n)) for n in range(1, 21)], "20", "list"),
        _dropdown("activeLabel", "Active meeting label", "Label shown during calls in normal app rotation.", [("LIVE", "LIVE"), ("ON AIR", "ON AIR")], "LIVE", "video"),
    ])

def classify_events(events):
    result = []
    for source in events:
        event = dict(source)
        haystack = "\n".join([event.get(key, "") or "" for key in ["url", "location", "description", "conference"]])
        event["isCall"] = False
        event["callProvider"] = None
        for provider, pattern in COMPILED_PROVIDERS:
            if pattern.search(haystack) != None:
                event["isCall"] = True
                event["callProvider"] = provider
                break
        result.append(event)
    return result

def _event_key(event):
    return (event["start"], event["end"], event.get("occurrenceId", ""), event.get("title", ""))

def calculate_state(events, now, day_end):
    ordered = sorted(events, key = _event_key)
    active = [e for e in ordered if e.get("isCall", False) and e["start"] <= now and e["end"] > now]
    if active:
        next_free = now
        for event in ordered:
            if event["end"] <= event["start"] or not (event.get("busy", True) or event.get("isCall", False)):
                continue
            if event["start"] <= next_free:
                next_free = max(next_free, event["end"])
        return {"mode": "active", "event": active[0], "activeCalls": active, "nextFree": next_free}
    remaining = [e for e in ordered if e["end"] > now and e["start"] < day_end]
    return {"mode": "normal", "events": remaining} if remaining else {"mode": "empty"}

def next_display_boundary(events, now, day_end):
    boundaries = [day_end]
    for event in events:
        if event["end"] > now:
            boundaries.append(event["end"])
        if event.get("isCall", False) and event["start"] > now:
            boundaries.append(event["start"])
    return min(boundaries)

def wrap_title(title, cap = 240):
    clean = " ".join(re.sub(r"[^\x20-\x7e]", " ", title).split()) or "UNTITLED EVENT"
    if len(clean) > cap:
        clean = clean[:cap - 3].rstrip() + "..."
    lines = []
    for word in clean.split():
        for offset in range(0, len(word), 15):
            chunk = word[offset:offset + 15]
            if lines and len(lines[-1]) + 1 + len(chunk) <= 15:
                lines[-1] += " " + chunk
            else:
                lines.append(chunk)
    return lines

def active_summary_pages(active_calls):
    ordered = sorted(active_calls, key = _event_key)
    pages = []
    for index, event in enumerate(ordered):
        lines = wrap_title(event.get("title", ""))
        count = (len(lines) + 1) // 2
        for page in range(count):
            pages.append({"event": event, "eventIndex": index, "eventCount": len(ordered), "pageIndex": page, "pageCount": count, "lines": lines[page * 2:page * 2 + 2]})
    return pages

def _text(value, x, y, color):
    return render.Padding(pad = (x, y, 0, 0), child = render.Text(content = value.upper(), font = "CG-pixel-3x5-mono", color = color))

def _format_time(timestamp, timezone, format):
    local = time.from_timestamp(int(timestamp)).in_location(timezone)
    return local.format("15:04") if format == "24h" else local.format("3:04PM").replace("AM", "a").replace("PM", "p")

def _free_label(state, timezone, settings):
    free = time.from_timestamp(int(state["nextFree"])).in_location(timezone)
    start = time.from_timestamp(int(state["event"]["start"])).in_location(timezone)
    prefix = "" if free.format("2006-01-02") == start.format("2006-01-02") else free.format("Mon ")
    return ("FREE " + prefix + _format_time(state["nextFree"], timezone, settings["timeFormat"]))[:15]

def _normal_frame(event, index, total, timezone, settings):
    colors = NORMAL_COLORS[settings["normalTheme"]]
    children = [render.Box(width = 64, height = 32, color = colors[0]), render.Box(width = 64, height = 7, color = colors[1]), _text(_format_time(event["start"], timezone, settings["timeFormat"]), 2, 1, colors[3])]
    if event.get("isCall", False) and settings["showCallBadge"]:
        children.append(_text("CALL", 47, 1, "#75ebb4"))
    for line, title in enumerate(wrap_title(event.get("title", ""))[:2]):
        children.append(_text(title, 2, 10 + line * 7, colors[2]))
    counter = "%d/%d" % (index + 1, total)
    children.append(_text(counter, 64 - len(counter) * 4, 26, colors[4]))
    return render.Stack(children = children)

def _active_frame(state, page, timezone, settings, single):
    colors = ACTIVE_COLORS[settings["activeTheme"]]
    header = settings["activeLabel"] if single else "%d %s" % (page["eventCount"], settings["activeLabel"])
    children = [render.Box(width = 64, height = 32, color = colors[0]), render.Box(width = 64, height = 8, color = colors[1]), _text(header, 2, 1, colors[5])]
    if not single:
        counter = "%d/%d" % (page["eventIndex"] + 1, page["eventCount"])
        x = 64 - len(counter) * 4
        if x > 2 + len(header) * 4:
            children.append(_text(counter, x, 1, colors[5]))
    for line, title in enumerate(page["lines"]):
        children.append(_text(title, 2, 10 + line * 7, colors[2] if line == 0 else colors[4]))
    children.extend([render.Padding(pad = (0, 25, 0, 0), child = render.Box(width = 64, height = 7, color = "#000000")), _text(_free_label(state, timezone, settings), 2, 26, colors[3])])
    return render.Stack(children = children)

def render_state(state, _now, timezone, settings, max_age):
    """Render normalized state; timestamps are Unix seconds, timezone is validated upstream."""
    if not settings["displayEnabled"] or state["mode"] == "empty":
        return None
    if state["mode"] == "active":
        single = len(state["activeCalls"]) == 1
        pages = active_summary_pages(state["activeCalls"])
        if len(pages) > MAX_ACTIVE_PAGES:
            return render.Root(
                child = render.Box(width = 64, height = 32, color = "#070e1d", child = render.WrappedText("Too many active meeting pages", width = 60, font = "tom-thumb", color = "#ebf0ff")),
                max_age = 60,
            )

        # Preserve private edition's single-call screen; multi-call mode paginates every title.
        if single:
            pages = pages[:1]
        frames = [_active_frame(state, page, timezone, settings, single) for page in pages]
        delay = 5000 if single else 2000
    else:
        events = state["events"][:settings["maxEvents"]]
        frames = [_normal_frame(event, index, len(events), timezone, settings) for index, event in enumerate(events)]
        delay = settings["frameDurationMs"]
    return render.Root(child = render.Animation(children = frames), delay = delay, max_age = max(1, min(300, int(max_age))), show_full_animation = True)
