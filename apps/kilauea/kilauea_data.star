"""Pure normalization and activity classification for USGS HANS notices."""

KILAUEA_VNUM = "332010"

FRESH_SECONDS = 48 * 60 * 60
EXPIRED_SECONDS = 7 * 24 * 60 * 60
FUTURE_TOLERANCE_SECONDS = 6 * 60 * 60

_BUILDING_PHRASES = (
    "precursory",
    "forecast",
    "imminent",
    "likely to begin",
    "likely between",
    "likely within",
    "another episode is likely",
    "another fountaining episode is likely",
    "forecast window",
    "inflation",
    "re-inflation",
    "re-inflating",
    "inflating",
    "heightened unrest",
    "escalating unrest",
    "increased unrest",
    "unrest is increasing",
)

_ENDED_PHRASES = (
    " ended",
    " stopped",
    " ceased",
    " paused",
    "not erupting",
    "not currently erupting",
    "no eruption",
    "no eruptive activity",
)

_QUIET_PHRASES = (
    "background level",
    "background state",
    "no significant activity",
    "remains quiet",
    "is quiet",
)

_ACTIVE_PHRASES = (
    "eruption is underway",
    "eruption continues",
    "currently erupting",
    "is erupting",
    "began erupting",
    "fountaining is underway",
    "fountaining activity is currently",
    "eruptive activity is occurring",
)

_ACTIVE_EPISODE_VERBS = (
    " began",
    " started",
    " continues",
    " resumed",
)

def _contains_any(text, phrases):
    for phrase in phrases:
        if phrase in text:
            return True
    return False

def _status(value):
    if type(value) != "string":
        return "UNASSIGNED"
    value = value.strip().upper()
    return value or "UNASSIGNED"

def _string(value, default = ""):
    if type(value) == "string":
        return value.strip()
    return default

def _integer(value):
    if type(value) == "int":
        return value
    if type(value) == "float":
        converted = int(value)
        if value == converted:
            return converted
    return None

def matches_vnum(value, target_vnum = KILAUEA_VNUM):
    """Return whether a JSON string or integral number identifies Kilauea."""
    if type(value) == "string":
        return value.strip() == target_vnum
    numeric = _integer(value)
    return numeric != None and str(numeric) == target_vnum

def select_volcano_section(payload, target_vnum = KILAUEA_VNUM):
    """Select the requested volcano section without trusting notice-wide maxima."""
    if type(payload) != "dict":
        return None

    sections = payload.get("noticeSections")
    if type(sections) != "list":
        return None

    for section in sections:
        if type(section) == "dict" and matches_vnum(section.get("vnum"), target_vnum):
            return section
    return None

def clean_synopsis(value):
    """Normalize whitespace and remove HANS's leading status prefix."""
    if type(value) != "string":
        return ""

    text = value.replace("\r", " ").replace("\n", " ").strip()
    delimiter = text.find(" - ")
    if delimiter >= 0 and delimiter < 96:
        prefix = text[:delimiter].lower()
        if "kilauea" in prefix or "kīlauea" in prefix:
            return text[delimiter + 3:].strip()
    return text

def _activity_signals(alert_level, color_code, synopsis):
    alert = _status(alert_level)
    color = _status(color_code)
    text = synopsis.lower() if type(synopsis) == "string" else ""

    warning = (
        alert == "WARNING" or
        color == "RED" or
        " red/warning - " in (" " + text) or
        " red/watch - " in (" " + text)
    )
    building = _contains_any(text, _BUILDING_PHRASES)
    ended = _contains_any(text, _ENDED_PHRASES)
    quiet = ended or _contains_any(text, _QUIET_PHRASES)
    active = _contains_any(text, _ACTIVE_PHRASES)
    if "episode" in text and _contains_any(text, _ACTIVE_EPISODE_VERBS):
        active = True

    return {
        "alert": alert,
        "color": color,
        "warning": warning,
        "building": building,
        "ended": ended,
        "paused": " paused" in text,
        "quiet": quiet,
        "active": active,
        "precursory": "precursory" in text,
    }

def classify_activity(alert_level, color_code, synopsis):
    """Map official status plus concise HANS language to a visual mode."""
    signals = _activity_signals(alert_level, color_code, synopsis)

    if signals["warning"]:
        return "warning"
    if signals["active"] and not signals["ended"] and not signals["precursory"]:
        return "erupting"
    if signals["building"]:
        return "building"
    if signals["quiet"]:
        return "quiet"
    if signals["alert"] == "WATCH" or signals["color"] == "ORANGE":
        return "building"
    if signals["alert"] == "NORMAL" or signals["color"] == "GREEN":
        return "quiet"
    return "unknown"

def classify_phase(alert_level, color_code, synopsis):
    """Return a literal headline phase separately from the visual mode."""
    signals = _activity_signals(alert_level, color_code, synopsis)

    if signals["warning"]:
        return "warning"
    if signals["paused"]:
        return "paused"
    if signals["active"] and not signals["precursory"]:
        return "erupting"
    if signals["building"]:
        return "precursor"
    if signals["quiet"] or signals["alert"] == "NORMAL" or signals["color"] == "GREEN":
        return "quiet"
    if signals["alert"] == "WATCH" or signals["color"] == "ORANGE":
        return "precursor"
    return "unknown"

def phase_headline(phase):
    return {
        "warning": "WARNING",
        "erupting": "ERUPTING",
        "precursor": "BUILDING",
        "paused": "PAUSED",
        "quiet": "QUIET",
        "unknown": "UNKNOWN",
    }.get(phase, "UNKNOWN")

def age_seconds(sent_unix, now_unix):
    """Return clamped age, or None for invalid/excessively future timestamps."""
    sent = _integer(sent_unix)
    now = _integer(now_unix)
    if sent == None or now == None or sent <= 0 or now <= 0:
        return None
    if sent > now + FUTURE_TOLERANCE_SECONDS:
        return None
    if sent > now:
        return 0
    return now - sent

def freshness_state(sent_unix, now_unix):
    age = age_seconds(sent_unix, now_unix)
    if age == None or age >= EXPIRED_SECONDS:
        return "expired"
    if age > FRESH_SECONDS:
        return "stale"
    return "fresh"

def normalize_notice(payload, now_unix, target_vnum = KILAUEA_VNUM):
    """Validate a HANS payload and return a compact deterministic model."""
    section = select_volcano_section(payload, target_vnum)
    if section == None:
        return None

    sent_unix = _integer(payload.get("sent_unixtime"))
    now = _integer(now_unix)
    if sent_unix == None or now == None or sent_unix <= 0 or now <= 0:
        return None
    if sent_unix > now + FUTURE_TOLERANCE_SECONDS:
        return None

    raw_synopsis = section.get("synopsis")
    synopsis = clean_synopsis(raw_synopsis)
    if synopsis == "":
        return None

    alert = _status(section.get("alertLevel"))
    color = _status(section.get("colorCode"))
    mode = classify_activity(alert, color, raw_synopsis)
    phase = classify_phase(alert, color, raw_synopsis)
    freshness = freshness_state(sent_unix, now)

    return {
        "vnum": target_vnum,
        "volcano_name": _string(section.get("vName"), "Kilauea") or "Kilauea",
        "notice_id": _string(payload.get("noticeId")),
        "notice_type": _string(payload.get("noticeType")),
        "notice_type_code": _string(payload.get("noticeTypeCd")),
        "sent_unix": sent_unix,
        "sent_date": _string(payload.get("sentUtc")),
        "alert_level": alert,
        "color_code": color,
        "synopsis": synopsis,
        "mode": mode,
        "phase": phase,
        "headline": phase_headline(phase),
        "age_seconds": age_seconds(sent_unix, now),
        "freshness": freshness,
        "stale": freshness == "stale",
        "expired": freshness == "expired",
    }
