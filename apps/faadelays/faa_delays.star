"""
Applet: FAA Delays
Summary: Air traffic delay info
Description: Displays FAA ground stop and delay programs for specified airports.
Author: Matt Broussard
"""

load("animation.star", "animation")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

API_URL = "https://nasstatus.faa.gov/api/airport-status-information"
MIN_PAGE_DURATION = 60  # 60 frames * 50ms = 3000ms

demo_data = [
    {
        "type": "departure_delay",
        "airport": "SFO",
        "reason": "fog",
        "min_minutes": 30,
        "max_minutes": 60,
    },
    {
        "type": "ground_stop",
        "airport": "OAK",
        "reason": "bird strike",
        "end_time": "4:00pm",
    },
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "favorites",
                name = "Favorite airports",
                desc = "A comma-separated list of favorite airports' 3-letter IATA codes. If empty, will display all US airports with FAA delays.",
                icon = "plane",
                default = "SFO",
            ),
            schema.Dropdown(
                id = "mode",
                name = "Favorites Mode",
                desc = "How the favorite airports list should be handled",
                icon = "gear",
                default = "favorites_first",
                options = [
                    schema.Option(display = "Favorites Only", value = "favorites_only"),
                    schema.Option(display = "Favorites First", value = "favorites_first"),
                    schema.Option(display = "Demo", value = "demo"),
                ],
            ),
            schema.Text(
                id = "max_airports",
                name = "Maximum airports",
                desc = "Maximum number of airports to show. Enter 0 for no maximum.",
                icon = "arrowRightToBracket",
                default = "0",
            ),
        ],
    )

def main(config):
    favorites = config.get("favorites", "")
    mode = config.get("mode", "demo")
    max_airports = validate_int(config.get("max_airports", 0))
    if max_airports < 0:
        max_airports = 0

    info = demo_data
    if mode != "demo":
        info = load_filtered(favorites, mode, max_airports)

    rendered_info = [render_entry(e) for e in info]

    if len(rendered_info) == 0:
        return []

    return render.Root(
        child = render.Sequence(
            children = rendered_info,
        ),
        show_full_animation = True,
    )

def render_entry(delay):
    delay_type_str = ({
        "ground_stop": "GND STOP",
        "ground_delay": "GND DELAY",
        "departure_delay": "DEP DELAY",
        "arrival_delay": "ARR DELAY",
    })[delay["type"]]

    top_row = render.Row(
        children = [
            render.Text(content = delay["airport"], color = "#ff0000", font = "6x13"),
            render.Text(content = delay_type_str, color = "#A2A2A2", font = "tb-8"),
        ],
        cross_align = "center",
        main_align = "space_between",
        expanded = True,
    )
    top_row_height = 9

    if delay["type"] == "ground_stop":
        middle_row = render.Row(
            children = [
                render.Padding(
                    child = render.Text(content = "til", font = "tom-thumb"),
                    pad = (0, 0, 3, 1),
                ),
                render.Text(content = delay["end_time"], font = "6x13"),
            ],
            cross_align = "end",
        )
    else:
        # TODO: for now we take midpoint of min and max, but FAA website just displays
        # minimum as "average" https://nasstatus.faa.gov/ -- should we do same?
        duration = delay["avg_minutes"] if delay["type"] == "ground_delay" else midpoint(delay["min_minutes"], delay["max_minutes"])

        unit = "min"
        if duration > 75:
            duration = format_float(duration / 60)
            unit = "hrs"

        middle_row = render.Row(
            children =
                replace_decimal(str(duration)) +
                [
                    render.Padding(
                        child = render.Text(content = unit, font = "tom-thumb"),
                        pad = (3, 0, 0, 1),
                    ),
                ],
            cross_align = "end",
        )
    middle_row = render.Marquee(
        child = middle_row,
        width = 64,
        scroll_direction = "horizontal",
        align = "center",
    )

    bottom_row = render.Marquee(
        child = render.Text(
            content = "due to " + delay["reason"],
            font = "CG-pixel-3x5-mono",
            color = "#A2A2A2",
        ),
        width = 64,
        scroll_direction = "horizontal",
        align = "center",
    )

    anim = render.Stack(
        children = [
            top_row,
            render.Column(
                children = [
                    # manually offset the height of the top row, since letting
                    # it lay itself out in a column takes too much vertical space
                    render.Box(width = 0, height = top_row_height),
                    middle_row,
                    bottom_row,
                ],
                main_align = "space_between",
                expanded = True,
            ),
        ],
    )

    return MinDuration(anim, MIN_PAGE_DURATION)

# I don't like the decimal in 6x13 font, so this function replaces that one character
# with a different font
def replace_decimal(text):
    parts = text.split(".")
    result = []
    for i, part in enumerate(parts):
        result.append(render.Text(content = part, font = "6x13"))
        if i != len(parts) - 1:
            result.append(render.Text(content = ".", font = "tom-thumb", offset = 1))
    return result

# get only one decimal place since we can't write %.1f in starlark
def format_float(n):
    whole = math.floor(n)
    first_dec = math.fabs(math.round((n - whole) * 10))
    if first_dec >= 10:
        whole += 1
        first_dec -= 10
    return "%d.%d" % (whole, first_dec)

def load_raw():
    resp = http.get(API_URL, ttl_seconds = 60)
    if resp.status_code != 200:
        return []

    body = resp.body()
    xp = xpath.loads(body)
    result = []

    ground_delays = xp.query_all_nodes("/AIRPORT_STATUS_INFORMATION/Delay_type/Ground_Delay_List/Ground_Delay")
    result += [parse_ground_delay(gd) for gd in ground_delays]

    ground_stops = xp.query_all_nodes("/AIRPORT_STATUS_INFORMATION/Delay_type/Ground_Stop_List/Program")
    result += [parse_ground_stop(gs) for gs in ground_stops]

    general_delays = xp.query_all_nodes("/AIRPORT_STATUS_INFORMATION/Delay_type/Arrival_Departure_Delay_List/Delay")
    result += [parse_general_delay(d) for d in general_delays]

    return result

def parse_general_delay(xp):
    airport = xp.query("/ARPT")

    reason = parse_reason(xp.query("/Reason"))

    min_minutes = parse_duration(xp.query("/Arrival_Departure/Min"))
    max_minutes = parse_duration(xp.query("/Arrival_Departure/Max"))

    kind = xp.query("/Arrival_Departure/@Type").lower()

    return {
        "type": kind + "_delay",
        "min_minutes": min_minutes,
        "max_minutes": max_minutes,
        "airport": airport,
        "reason": reason,
    }

def parse_ground_stop(xp):
    airport = xp.query("/ARPT")
    reason = parse_reason(xp.query("/Reason"))
    end_time = parse_end_time(xp.query("/End_Time"))

    return {
        "type": "ground_stop",
        "airport": airport,
        "reason": reason,
        "end_time": end_time,
    }

def parse_ground_delay(xp):
    airport = xp.query("/ARPT")
    reason = parse_reason(xp.query("/Reason"))

    avg_minutes = parse_duration(xp.query("/Avg"))
    max_minutes = parse_duration(xp.query("/Max"))

    return {
        "type": "ground_delay",
        "airport": airport,
        "reason": reason,
        "avg_minutes": avg_minutes,
        "max_minutes": max_minutes,
    }

# strips out timezone specifier and spaces for brevity
def parse_end_time(end_time):
    end_time = end_time.lower()
    digits = "0123456789"

    parts = end_time.split(" ")
    result = []
    for part in parts:
        if part[0] in digits or part in ["am", "pm"]:
            result.append(part)

    return "".join(result)

def parse_reason(reason):
    reason = reason.upper()
    if not reason:
        return "Unknown"
    if "WIND" in reason:
        return "Wind"
    if "THUNDERSTORM" in reason or "TSTORM" in reason or "T-STORM" in reason:
        return "T-Storms"
    if "WX" in reason:
        reason = "Weather"
    if "VOLUME" in reason:
        return "Volume"
    if "STAFF" in reason:
        return "Staffing"
    if "CONSTRUCTION" in reason:
        return "Construction"
    return reason

def midpoint(a, b):
    return int((b - a) / 2 + a)

# parses strings like "1 hour and 15 minutes" into an integer number of minutes
def parse_duration(duration_string):
    # without an arg, Starlark's split function splits on runs of whitespace (after stripping leading + trailing)
    parts = duration_string.split()
    total_minutes = 0

    for i in range(len(parts)):
        if validate_int(parts[i], -1) == -1:
            continue

        if i + 1 >= len(parts):
            # unknown string format
            return -1

        value = int(parts[i])
        unit = parts[i + 1].lower()

        if "hour" in unit:
            total_minutes += value * 60
        elif "minute" in unit:
            total_minutes += value
        else:
            # unknown string format
            return -1

    return total_minutes

def load_filtered(favorites, mode, max_airports):
    raw = load_raw()

    # sort by worst delays first
    def sort_key(entry):
        # ground stops have an end time, not a duration
        # maybe we could compute a time difference but for now, just sort them first
        if entry["type"] == "ground_stop":
            return -10000
        if "avg_minutes" in entry:
            return -entry["avg_minutes"]
        return -midpoint(entry["min_minutes"], entry["max_minutes"])

    raw = sorted(raw, key = sort_key)

    # add favorites
    faves = [s.strip().upper() for s in favorites.split(",")]
    result = []
    for entry in raw:
        if entry["airport"] in faves:
            result.append(entry)

    # add non-favorites at the end if in "favorites first" mode
    if mode == "favorites_first" or len(faves) == 0:
        for entry in raw:
            if entry["airport"] not in faves:
                result.append(entry)

    if max_airports > 0:
        result = result[:max_airports]

    return result

# is there really no better way to do this? int() throws but Starlark has no try/except
def validate_int(num_str, fallback = 0):
    num_str = str(num_str)
    valid = "-0123456789"
    if len(num_str) == 0:
        return fallback
    for i in range(len(num_str)):
        c = num_str[i]
        if c not in valid:
            return fallback
    return int(num_str)

# hack, see https://github.com/tidbyt/pixlet/issues/823
def MinDuration(child, min_duration):
    return animation.Transformation(
        child = child,
        keyframes = [],
        duration = min_duration,
        wait_for_child = True,
    )
