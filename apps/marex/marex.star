"""
Applet: Marex
Summary: Tide times for a beach in Brazil.
Description: Shows today's tide table from tabuamare.devtu.qzz.io.
Author: Flavio
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_HARBOR_ID = "pb01"
DEFAULT_TIMEZONE = "America/Fortaleza"
API_BASE_URL = "https://tabuamare.devtu.qzz.io/api/v2/tabua-mare"
CACHE_TTL_SECONDS = 60 * 60

def main(config):
    harbor_id = config.str("harbor_id", DEFAULT_HARBOR_ID)
    timezone = config.str("timezone", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    tide_data = get_tide_data(harbor_id, now)
    harbor = tide_data["harbor"]
    day = tide_data["day"]
    tides = day["hours"]
    mean_level = tide_data["mean_level"]
    next = next_tide(tides, now)
    low = extreme_tide(tides, high = False)
    high = extreme_tide(tides, high = True)
    current_level = current_tide_level(tides, now)

    return render.Root(
        delay = 700,
        child = render.Stack(
            children = [
                render.Image(
                    src = wave_svg(tides, mean_level, now),
                    width = 64,
                    height = 32,
                ),
                render.Column(
                    expanded = True,
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 64,
                            height = 7,
                            child = render.Marquee(
                                height = 7,
                                scroll_direction = "vertical",
                                child = render.Column(
                                    children = [
                                        header_line(
                                            "%s %s/%s" % (
                                                short_harbor_name(harbor),
                                                zero_pad(day["day"]),
                                                now.format("01"),
                                            ),
                                        ),
                                        header_line(
                                            "CURRENT %s" %
                                            tide_level_value(current_level),
                                        ),
                                    ],
                                ),
                                offset_start = 0,
                                offset_end = -7,
                            ),
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                tide_card("L", low, next, "#ffcc66"),
                                tide_card("H", high, next, "#66ff99"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def header_line(content):
    return render.Box(
        width = 64,
        height = 7,
        child = render.Text(
            content = content,
            font = "tom-thumb",
            color = "#7fd8ff",
        ),
    )

def tide_card(label, tide, next, color):
    return render.Box(
        width = 32,
        height = 12,
        color = "#021b2cbb",
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        tide_marker(is_same_tide(tide, next), color),
                        render.Box(width = 1, height = 1),
                        render.Text(
                            content = "%s %s" % (label, tide_time(tide)),
                            font = "tom-thumb",
                            color = color,
                        ),
                    ],
                ),
                render.Text(
                    content = tide_level(tide),
                    font = "tom-thumb",
                    color = "#e8f8ff",
                ),
            ],
        ),
    )

def tide_marker(is_next, color):
    if not is_next:
        return render.Box(width = 2, height = 2)

    return render.Animation(
        children = [
            render.Circle(color = color, diameter = 2),
            render.Box(width = 2, height = 2),
        ],
    )

def wave_svg(tides, mean_level, now):
    points = tide_points(tides)
    now_point = current_tide_point(points, tides, now)
    fill_path = "M0 31 L%s %s" % (points[0][0], points[0][1])
    line_path = "M%s %s" % (points[0][0], points[0][1])

    for point in points[1:]:
        fill_path = "%s L%s %s" % (fill_path, point[0], point[1])
        line_path = "%s L%s %s" % (line_path, point[0], point[1])

    fill_path = "%s L63 31 Z" % fill_path
    markers = []

    for i in range(len(tides)):
        tide = tides[i]
        point = points[i]
        color = tide_color(tide["level"], mean_level)

        markers.append(
            '<circle cx="%s" cy="%s" r="1" fill="%s"/>' %
            (point[0], point[1], color),
        )

    markers.append(
        '<line x1="%s" y1="19" x2="%s" y2="31" stroke="#ffffff" stroke-width="1" opacity="0.75"/>' %
        (now_point[0], now_point[0]),
    )
    markers.append(
        '<circle cx="%s" cy="%s" r="2" fill="#ffffff"/>' %
        (now_point[0], now_point[1]),
    )

    return """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="32" shape-rendering="crispEdges">
<rect width="64" height="32" fill="#001522"/>
<rect x="0" y="19" width="64" height="13" fill="#00283d"/>
<path d="%s" fill="#064f79"/>
<path d="%s" fill="none" stroke="#40c7ff" stroke-width="1"/>
<path d="M0 30 L4 29 L8 30 L12 29 L16 30 L20 29 L24 30 L28 29 L32 30 L36 29 L40 30 L44 29 L48 30 L52 29 L56 30 L60 29 L64 30" fill="none" stroke="#0fa6d8" stroke-width="1" opacity="0.55"/>
%s
</svg>""" % (fill_path, line_path, "\n".join(markers))

def tide_points(tides):
    min_level = tides[0]["level"]
    max_level = tides[0]["level"]

    for tide in tides:
        if tide["level"] < min_level:
            min_level = tide["level"]

        if tide["level"] > max_level:
            max_level = tide["level"]

    level_range = max_level - min_level

    if level_range == 0:
        level_range = 1

    points = []

    for tide in tides:
        minutes = parse_minutes(tide["hour"])
        x = int(minutes * 63 / 1439)
        y = 29 - int((tide["level"] - min_level) * 9 / level_range)
        points.append((x, y))

    return points

def current_tide_point(points, tides, now):
    current_minutes = now.hour * 60 + now.minute
    current_x = int(current_minutes * 63 / 1439)

    if current_minutes <= parse_minutes(tides[0]["hour"]):
        return (current_x, points[0][1])

    for i in range(len(tides) - 1):
        start_minutes = parse_minutes(tides[i]["hour"])
        end_minutes = parse_minutes(tides[i + 1]["hour"])

        if current_minutes >= start_minutes and current_minutes <= end_minutes:
            span = end_minutes - start_minutes

            if span == 0:
                return (current_x, points[i][1])

            y = points[i][1] + int(
                (points[i + 1][1] - points[i][1]) *
                (current_minutes - start_minutes) / span,
            )
            return (current_x, y)

    return (current_x, points[len(points) - 1][1])

def current_tide_level(tides, now):
    current_minutes = now.hour * 60 + now.minute

    if current_minutes <= parse_minutes(tides[0]["hour"]):
        return tides[0]["level"]

    for i in range(len(tides) - 1):
        start_minutes = parse_minutes(tides[i]["hour"])
        end_minutes = parse_minutes(tides[i + 1]["hour"])

        if current_minutes >= start_minutes and current_minutes <= end_minutes:
            span = end_minutes - start_minutes

            if span == 0:
                return tides[i]["level"]

            return tides[i]["level"] + (
                (tides[i + 1]["level"] - tides[i]["level"]) *
                (current_minutes - start_minutes) / span
            )

    return tides[len(tides) - 1]["level"]

def next_tide(tides, now):
    current_minutes = now.hour * 60 + now.minute

    for tide in tides:
        if parse_minutes(tide["hour"]) >= current_minutes:
            return tide

    return tides[0]

def extreme_tide(tides, high):
    selected = tides[0]

    for tide in tides:
        if high and tide["level"] > selected["level"]:
            selected = tide

        if not high and tide["level"] < selected["level"]:
            selected = tide

    return selected

def is_same_tide(left, right):
    return left["hour"] == right["hour"] and left["level"] == right["level"]

def parse_minutes(hour):
    return int(hour[:2]) * 60 + int(hour[3:5])

def tide_time(tide):
    return tide["hour"][:5]

def tide_level(tide):
    return tide_level_value(tide["level"])

def tide_level_value(level):
    return "%sm" % (int(level * 10) / 10.0)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "harbor_id",
                name = "Harbor ID",
                desc = "Tide station identifier from the Tabua Mare API.",
                icon = "anchor",
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "IANA timezone used to choose today's tide table.",
                icon = "clock",
            ),
        ],
    )

def get_tide_data(harbor_id, now):
    month = now.format("01")
    day = str(now.day)
    cache_key = "%s-%s-%s" % (harbor_id, month, day)
    cached = cache.get(cache_key)

    if cached != None:
        data = json.decode(cached)
    else:
        url = "%s/%s/%s/%s" % (API_BASE_URL, harbor_id, month, day)
        rep = http.get(url)

        if rep.status_code != 200:
            fail("Tide API request failed with status %d" % rep.status_code)

        data = rep.json()
        cache.set(cache_key, json.encode(data), ttl_seconds = CACHE_TTL_SECONDS)

    if len(data["data"]) == 0:
        fail("Tide API returned no data for %s" % cache_key)

    station = data["data"][0]
    month_data = station["months"][0]

    if len(month_data["days"]) == 0:
        fail("Tide API returned no days for %s" % cache_key)

    return {
        "harbor": station["harbor_name"],
        "mean_level": station["mean_level"],
        "day": month_data["days"][0],
    }

def tide_color(level, mean_level):
    if level >= mean_level:
        return "#66ff99"

    return "#ffcc66"

def short_harbor_name(name):
    if name.startswith("PORTO DE "):
        name = name[9:]

    if " (" in name:
        name = name.split(" (")[0]

    return name

def zero_pad(value):
    if value < 10:
        return "0%s" % value

    return str(value)
