"""
Applet: Meeting Calendar
Summary: Events and live meetings
Description: Rotate today's timed events from an iCloud, Google, or Outlook ICS subscription. Highlight live meetings and when you are next free. No separate hosting or subscription required.
Author: Tassos Lambrou
"""

load("cache.star", "cache")
load("calendar.star", "local_day_bounds", "parse_calendar", "resolve_timezone")
load("display.star", "build_schema", "calculate_state", "classify_events", "next_display_boundary", "parse_settings", "render_state")
load("hash.star", "hash")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("time.star", "time")

MAX_FEED_BYTES = 10000000
FEED_TTL_SECONDS = 60

def normalize_calendar_url(value):
    """Accept provider subscription endpoints; never accept credentials or HTTP."""
    value = value.strip()
    if value.lower().startswith("webcal://"):
        value = "https://" + value[9:]
    if not re.match(r"^https://[^\s#@]+$", value):
        return {"url": "", "error": "Use an HTTPS calendar subscription link"}
    authority, separator, path = value[8:].partition("/")
    host = authority.lower()
    if not separator or ":" in host or "\\" in value:
        return {"url": "", "error": "Invalid calendar subscription link"}
    icloud = (host == "icloud.com" or host.endswith(".icloud.com")) and path.startswith("published/")
    google = host == "calendar.google.com" and path.startswith("calendar/ical/")
    outlook = host in ["outlook.live.com", "outlook.office365.com", "outlook.office.com"] and path.startswith("owa/calendar/")
    if not (icloud or google or outlook):
        return {"url": "", "error": "Use an iCloud, Google, or Outlook ICS link"}

    # Invalid percent escapes can make the native HTTP module throw before a response.
    for part in value.split("%")[1:]:
        if len(part) < 2 or not re.match(r"^[0-9a-fA-F]{2}", part):
            return {"url": "", "error": "Invalid calendar subscription link"}
    return {"url": "https://" + host + "/" + path, "error": ""}

def feed_cache_key(url, timezone):
    return "meetingcalendar:feed:v1:" + hash.sha256(url + "\n" + timezone)

def fetch_calendar(url, timezone, get_response, read_cache, write_cache):
    """Inject transport/cache for deterministic tests; production passes native APIs."""
    key = feed_cache_key(url, timezone)
    cached = read_cache(key)
    if cached != None:
        return {"source": cached, "error": ""}

    # Native network exceptions cannot be caught in Starlark. max_age on prior
    # renders bounds their lifetime; do not print the request or its response.
    # Ask for no additional HTTP caching; Tidbyt may impose a minimum proxy TTL.
    response = get_response(url, headers = {"Accept": "text/calendar"}, ttl_seconds = 0)
    if response.status_code != 200:
        return {"source": "", "error": "Calendar unavailable; check sharing link"}
    length = response.headers.get("Content-Length", "")
    if length.isdigit() and int(length) > MAX_FEED_BYTES:
        return {"source": "", "error": "Calendar exceeds 10 MB limit"}
    source = response.body()
    if len(source) > MAX_FEED_BYTES:
        return {"source": "", "error": "Calendar exceeds 10 MB limit"}
    if not source.lstrip().startswith("BEGIN:VCALENDAR"):
        return {"source": "", "error": "Link did not return an ICS calendar"}
    write_cache(key, source, ttl_seconds = FEED_TTL_SECONDS)
    return {"source": source, "error": ""}

def message_screen(message):
    return render.Root(
        delay = 1000,
        max_age = 60,
        child = render.Box(
            width = 64,
            height = 32,
            color = "#070e1d",
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("CALENDAR", font = "tom-thumb", color = "#ffcc33"),
                    render.WrappedText(message, width = 62, font = "tom-thumb", color = "#ebf0ff"),
                ],
            ),
        ),
    )

def calendar_screen(source, now, timezone, settings):
    """Render an ICS snapshot without IO; also used by fixture tests and previews."""
    bounds = local_day_bounds(now, timezone)
    if bounds["error"]:
        return message_screen("Check timezone setting")
    parsed = parse_calendar(source, bounds["start"], now + 21 * 86400, timezone)
    if parsed["error"]:
        return message_screen(parsed["error"])
    events = classify_events(parsed["events"])
    state = calculate_state(events, now, bounds["end"])
    boundary = next_display_boundary(events, now, bounds["end"])
    max_age = max(1, min(300, int(boundary - now)))
    return render_state(state, now, timezone, settings, max_age)

def main(config):
    settings, error = parse_settings(config)
    if error:
        return message_screen(error)
    if not settings["displayEnabled"]:
        return None
    url = settings["calendarUrl"]
    if not url:
        return message_screen("Add your ICS link in settings")
    normalized = normalize_calendar_url(url)
    if normalized["error"]:
        return message_screen(normalized["error"])
    timezone = settings["timezoneOverride"] or config.get("$tz") or "UTC"
    resolved = resolve_timezone(timezone)
    if resolved["error"]:
        return message_screen("Check timezone setting")
    timezone = resolved["timezone"]
    feed = fetch_calendar(normalized["url"], timezone, http.get, cache.get, cache.set)
    if feed["error"]:
        return message_screen(feed["error"])
    return calendar_screen(feed["source"], time.now().unix, timezone, settings)

def get_schema():
    return build_schema()
