"""
Applet: NOAA Water Temp
Summary: Local water temp from NOAA
Description: Shows current water temperature from nearby NOAA/NDBC stations.
Author: Taylor Wilson
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

LATEST_OBS_URL = "https://www.ndbc.noaa.gov/data/latest_obs/latest_obs.txt"
ACTIVE_STATIONS_URL = "https://www.ndbc.noaa.gov/activestations.xml"

STN = 0
LAT = 1
LON = 2
YEAR = 3
MONTH = 4
DAY = 5
HOUR = 6
MINUTE = 7
WIND_SPEED = 9
WAVE_HEIGHT = 11
AIR_TEMP = 17
WATER_TEMP = 18

MAX_NEARBY_OPTIONS = 10

DEFAULT_LOCATION = """
{
    "lat": "40.583",
    "lng": "-73.999",
    "description": "New York Harbor, USA",
    "locality": "New York Harbor",
    "timezone": "America/New_York"
}
"""

DEFAULT_STATION = "44065"

def clean_station_id(station_id):
    if station_id == None:
        return ""
    return str(station_id).strip().upper()

def xml_attr(line, attr):
    marker = attr + "=\""
    parts = line.split(marker)
    if len(parts) < 2:
        return ""
    return parts[1].split("\"")[0]

def clean_xml(value):
    return value.strip().replace("&amp;", "&").replace("&quot;", "\"")

def clean_station_name(name):
    name = clean_xml(name)
    if name == "":
        return ""

    # Many fixed stations are named like "8573364 - Tolchester Beach, MD".
    # Strip the leading numeric station code when it is just catalog metadata.
    parts = name.split(" - ")
    if len(parts) > 1 and len(parts[0]) >= 6:
        name = parts[1]

    name = name.replace("  ", " ").strip()
    if len(name) > 40:
        name = name[:40]
    return name

def get_station_names():
    resp = http.get(ACTIVE_STATIONS_URL, ttl_seconds = 21600)
    names = {}
    if resp.status_code != 200:
        return names

    for raw in resp.body().split("\n"):
        line = raw.strip()
        if not line.startswith("<station "):
            continue

        station_id = clean_station_id(xml_attr(line, "id"))
        name = clean_station_name(xml_attr(line, "name"))
        if station_id != "" and name != "":
            names[station_id] = name

    return names

def get_latest_observations():
    resp = http.get(LATEST_OBS_URL, ttl_seconds = 300)
    observations = []
    if resp.status_code != 200:
        return observations

    for raw in resp.body().split("\n"):
        line = raw.strip()
        if line == "" or line.startswith("#"):
            continue

        cols = line.split()
        if len(cols) <= WATER_TEMP:
            continue
        if cols[WATER_TEMP] == "MM":
            continue

        obs = {
            "station": clean_station_id(cols[STN]),
            "lat": float(cols[LAT]),
            "lon": float(cols[LON]),
            "water_c": float(cols[WATER_TEMP]),
            "time": "%s:%sZ" % (cols[HOUR], cols[MINUTE]),
            "date": "%s-%s-%s" % (cols[YEAR], cols[MONTH], cols[DAY]),
            "air_c": None,
            "wave_m": None,
            "wind_mps": None,
        }

        if cols[AIR_TEMP] != "MM":
            obs["air_c"] = float(cols[AIR_TEMP])
        if cols[WAVE_HEIGHT] != "MM":
            obs["wave_m"] = float(cols[WAVE_HEIGHT])
        if cols[WIND_SPEED] != "MM":
            obs["wind_mps"] = float(cols[WIND_SPEED])

        observations.append(obs)

    return observations

def find_observation(station_id, observations):
    station_id = clean_station_id(station_id)
    for obs in observations:
        if obs["station"] == station_id:
            return obs
    return None

def distance_miles(lat1, lon1, lat2, lon2):
    lat_miles = (lat2 - lat1) * 69.0
    lon_factor = math.cos(((lat1 + lat2) / 2.0) * 0.01745329252)
    lon_miles = (lon2 - lon1) * 69.0 * lon_factor
    return math.sqrt((lat_miles * lat_miles) + (lon_miles * lon_miles))

def insert_by_distance(items, item):
    out = []
    inserted = False
    for current in items:
        if not inserted and item["distance"] < current["distance"]:
            out.append(item)
            inserted = True
        out.append(current)

    if not inserted:
        out.append(item)

    if len(out) > MAX_NEARBY_OPTIONS:
        return out[:MAX_NEARBY_OPTIONS]
    return out

def nearby_observations(location_json, observations = None):
    location = json.decode(location_json)
    lat = float(location["lat"])
    lon = float(location["lng"])
    if observations == None:
        observations = get_latest_observations()
    best = []

    for obs in observations:
        distance = distance_miles(lat, lon, obs["lat"], obs["lon"])
        best = insert_by_distance(best, {
            "distance": distance,
            "obs": obs,
        })

    return best

def round_int(value):
    if value >= 0:
        return int(value + 0.5)
    return int(value - 0.5)

def temp_f(temp_c):
    return (temp_c * 9.0 / 5.0) + 32.0

def temp_for_units(temp_c, units):
    if units == "c":
        return round_int(temp_c)
    return round_int(temp_f(temp_c))

def unit_label(units):
    if units == "c":
        return "C"
    return "F"

def fmt1(value):
    scaled = round_int(value * 10.0)
    whole = int(scaled / 10)
    frac = scaled - (whole * 10)
    if frac < 0:
        frac = frac * -1
    return "%d.%d" % (whole, frac)

def format_station_option(obs, names, distance):
    station_id = obs["station"]
    name = names.get(station_id, station_id)
    if len(name) > 28:
        name = name[:28]
    return "%s %s (%d mi, %dF)" % (
        station_id,
        name,
        round_int(distance),
        round_int(temp_f(obs["water_c"])),
    )

def get_nearby_stations(location):
    names = get_station_names()
    options = []

    for item in nearby_observations(location):
        obs = item["obs"]
        options.append(schema.Option(
            display = format_station_option(obs, names, item["distance"]),
            value = obs["station"],
        ))

    if len(options) == 0:
        options.append(schema.Option(
            display = "No nearby stations with water temp",
            value = "",
        ))

    return options

def config_station_id(config):
    manual = clean_station_id(config.get("station_id", ""))
    if manual != "":
        return manual

    selected = config.get("station")
    if selected == None or selected == "":
        return ""

    if str(selected).startswith("{"):
        selected = json.decode(selected)
        return clean_station_id(selected.get("value", ""))

    return clean_station_id(selected)

def selected_station_label(config, station_id):
    nickname = config.get("nickname", "").strip()
    if nickname != "":
        return nickname

    selected = config.get("station")
    if selected != None and str(selected).startswith("{"):
        selected = json.decode(selected)
        display = selected.get("display", "")
        prefix = station_id + " "
        if display.startswith(prefix):
            display = display[len(prefix):]
        display = display.split(" (")[0].strip()
        if display != "":
            return display

    names = get_station_names()
    return names.get(station_id, station_id)

def find_best_observation(config, observations):
    station_id = config_station_id(config)
    if station_id != "":
        return find_observation(station_id, observations)

    location_json = config.get("location", DEFAULT_LOCATION)
    nearby = nearby_observations(location_json, observations)
    if len(nearby) > 0:
        return nearby[0]["obs"]

    return find_observation(DEFAULT_STATION, observations)

def temp_status(temp_c):
    temp = temp_f(temp_c)
    if temp < 45:
        return "FRIGID"
    if temp < 55:
        return "COLD"
    if temp < 65:
        return "BRISK"
    if temp < 75:
        return "SWIM"
    if temp < 84:
        return "BALMY"
    return "HOT"

def auto_accent(temp_c):
    temp = temp_f(temp_c)
    if temp < 45:
        return "#88E6FF"
    if temp < 55:
        return "#38BDF8"
    if temp < 65:
        return "#2DD4BF"
    if temp < 75:
        return "#7EE787"
    if temp < 84:
        return "#FFB86B"
    return "#FF6B6B"

def palette(theme, temp_c, custom):
    accent = custom
    bg = "#02060A"
    dim = "#6E7F8D"
    water = "#094B66"

    if theme == "auto":
        accent = auto_accent(temp_c)
        if temp_f(temp_c) >= 75:
            water = "#5D2E46"
    elif theme == "ocean":
        accent = "#55D6BE"
        bg = "#001018"
        dim = "#79A7B7"
        water = "#075985"
    elif theme == "sunset":
        accent = "#FFB86B"
        bg = "#120912"
        dim = "#B48A84"
        water = "#703D57"
    elif theme == "neon":
        accent = "#D7FF4A"
        bg = "#05050A"
        dim = "#8AE9FF"
        water = "#7C3AED"
    elif theme == "mono":
        accent = "#FFFFFF"
        bg = "#000000"
        dim = "#999999"
        water = "#333333"

    return {
        "bg": bg,
        "accent": accent,
        "dim": dim,
        "water": water,
        "text": "#FFFFFF",
    }

def trend_for_station(station_id, temp_c):
    key = "noaa_water_temp_last_%s" % station_id
    previous = cache.get(key)
    cache.set(key, "%s" % temp_c, ttl_seconds = 86400)

    if previous == None or previous == "":
        return "--"

    delta_f = temp_f(temp_c) - temp_f(float(previous))
    if delta_f >= 0.4:
        return "UP"
    if delta_f <= -0.4:
        return "DN"
    return "--"

def detail_value(label, value):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(content = label, font = "tom-thumb", color = "#9AA7B2"),
            render.Text(content = value, font = "tom-thumb", color = "#FFFFFF"),
        ],
    )

def wave_strip(colors, phase):
    first = colors["water"]
    second = colors["accent"]
    blocks = []
    for i in range(8):
        color = first
        if (i + phase) % 3 == 0:
            color = second
        blocks.append(render.Box(width = 8, height = 4, color = color))

    return render.Padding(
        pad = (0, 28, 0, 0),
        child = render.Row(children = blocks),
    )

def label_marquee(label, colors):
    return render.Marquee(
        width = 62,
        child = render.Text(
            content = label,
            font = "tom-thumb",
            color = colors["dim"],
        ),
    )

def format_air(temp_c_value, units):
    if temp_c_value == None:
        return "--"
    return "%d%s" % (temp_for_units(temp_c_value, units), unit_label(units))

def format_wave(wave_m, units):
    if wave_m == None:
        return "--"
    if units == "c":
        return "%sm" % fmt1(wave_m)
    return "%sft" % fmt1(wave_m * 3.28084)

def format_wind(wind_mps, units):
    if wind_mps == None:
        return "--"
    if units == "c":
        return "%sm/s" % fmt1(wind_mps)
    return "%dmph" % round_int(wind_mps * 2.23694)

def render_details(obs, units):
    return render.Box(
        width = 25,
        child = render.Column(
            expanded = True,
            main_align = "center",
            children = [
                detail_value("AIR", format_air(obs["air_c"], units)),
                detail_value("WAV", format_wave(obs["wave_m"], units)),
                detail_value("WND", format_wind(obs["wind_mps"], units)),
            ],
        ),
    )

def render_temp_row(obs, colors, units, trend):
    temp_text = "%d" % temp_for_units(obs["water_c"], units)
    return render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "center",
        children = [
            render.Text(
                content = temp_text,
                font = "10x20",
                color = colors["accent"],
            ),
            render.Column(
                main_align = "center",
                children = [
                    render.Text(content = unit_label(units), font = "tb-8", color = colors["text"]),
                    render.Text(content = trend, font = "tom-thumb", color = colors["dim"]),
                ],
            ),
        ],
    )

def render_footer(obs, colors, show_details):
    status = temp_status(obs["water_c"])
    if show_details:
        status = status + " NOAA"

    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(content = status, font = "tom-thumb", color = colors["accent"]),
            render.Text(content = obs["time"], font = "tom-thumb", color = colors["dim"]),
        ],
    )

def render_big(obs, label, colors, units, trend, show_details, phase):
    children = [
        render.Box(width = 64, height = 32, color = colors["bg"]),
        wave_strip(colors, phase),
        render.Padding(
            pad = (1, 1, 1, 0),
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    label_marquee(label, colors),
                    render_temp_row(obs, colors, units, trend),
                    render_footer(obs, colors, show_details),
                ],
            ),
        ),
    ]
    return render.Stack(children = children)

def render_surf(obs, label, colors, units, trend, phase):
    children = [
        render.Box(width = 64, height = 32, color = colors["bg"]),
        wave_strip(colors, phase),
        render.Padding(
            pad = (1, 1, 1, 0),
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    label_marquee(label, colors),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Box(
                                width = 37,
                                child = render_temp_row(obs, colors, units, trend),
                            ),
                            render_details(obs, units),
                        ],
                    ),
                    render_footer(obs, colors, True),
                ],
            ),
        ),
    ]
    return render.Stack(children = children)

def render_minimal(obs, label, colors, units, trend):
    if len(label) > 18:
        label = label[:18]

    return render.Stack(children = [
        render.Box(width = 64, height = 32, color = colors["bg"]),
        render.Padding(
            pad = (0, 2, 0, 0),
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render_temp_row(obs, colors, units, trend),
                    render.Text(
                        content = label,
                        font = "tom-thumb",
                        color = colors["dim"],
                    ),
                ],
            ),
        ),
    ])

def render_error(title, message):
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = "#12080A",
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(content = title, font = "tb-8", color = "#FF6B6B"),
                    render.WrappedText(
                        content = message,
                        width = 60,
                        align = "center",
                        font = "tom-thumb",
                        color = "#FFFFFF",
                    ),
                ],
            ),
        ),
    )

def main(config):
    observations = get_latest_observations()
    if len(observations) == 0:
        return render_error("NOAA", "Latest observations unavailable")

    obs = find_best_observation(config, observations)
    station_id = config_station_id(config)
    if obs != None:
        station_id = obs["station"]

    if obs == None:
        if station_id == "":
            station_id = DEFAULT_STATION
        return render_error("NO TEMP", "No recent water temp for %s" % station_id)

    units = config.get("units", "f")
    mode = config.get("display_mode", "big")
    theme = config.get("theme", "auto")
    show_details = config.bool("show_details", True)
    custom_color = config.get("accent_color", "#38BDF8")
    colors = palette(theme, obs["water_c"], custom_color)
    trend = trend_for_station(obs["station"], obs["water_c"])
    label = selected_station_label(config, obs["station"])

    if mode == "minimal":
        frames = [
            render_minimal(obs, label, colors, units, trend),
        ]
    elif mode == "surf":
        frames = [
            render_surf(obs, label, colors, units, trend, 0),
            render_surf(obs, label, colors, units, trend, 1),
        ]
    else:
        frames = [
            render_big(obs, label, colors, units, trend, show_details, 0),
            render_big(obs, label, colors, units, trend, show_details, 1),
        ]

    return render.Root(
        delay = 800,
        max_age = 7200,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Used to suggest nearby NOAA stations.",
                icon = "locationDot",
            ),
            schema.LocationBased(
                id = "station",
                name = "Nearby Station",
                desc = "NOAA stations reporting water temperature near your location.",
                icon = "locationDot",
                handler = get_nearby_stations,
            ),
            schema.Text(
                id = "station_id",
                name = "Station ID Override",
                desc = "Optional NOAA station ID, such as 44065.",
                icon = "gear",
                default = "",
            ),
            schema.Text(
                id = "nickname",
                name = "Display Nickname",
                desc = "Optional short label, such as My Beach.",
                icon = "user",
                default = "",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Temperature units.",
                icon = "gear",
                default = "f",
                options = [
                    schema.Option(display = "Fahrenheit", value = "f"),
                    schema.Option(display = "Celsius", value = "c"),
                ],
            ),
            schema.Dropdown(
                id = "display_mode",
                name = "Display Mode",
                desc = "Choose the screen layout.",
                icon = "compress",
                default = "big",
                options = [
                    schema.Option(display = "Big Temp", value = "big"),
                    schema.Option(display = "Surf Check", value = "surf"),
                    schema.Option(display = "Minimal", value = "minimal"),
                ],
            ),
            schema.Dropdown(
                id = "theme",
                name = "Theme",
                desc = "Choose the color style.",
                icon = "brush",
                default = "auto",
                options = [
                    schema.Option(display = "Auto By Temp", value = "auto"),
                    schema.Option(display = "Ocean", value = "ocean"),
                    schema.Option(display = "Sunset", value = "sunset"),
                    schema.Option(display = "Neon", value = "neon"),
                    schema.Option(display = "Mono", value = "mono"),
                    schema.Option(display = "Custom Accent", value = "custom"),
                ],
            ),
            schema.Color(
                id = "accent_color",
                name = "Custom Accent",
                desc = "Used when theme is Custom Accent.",
                icon = "brush",
                default = "#38BDF8",
                palette = [
                    "#38BDF8",
                    "#2DD4BF",
                    "#7EE787",
                    "#FFB86B",
                    "#FF6B6B",
                    "#D7FF4A",
                ],
            ),
            schema.Toggle(
                id = "show_details",
                name = "Show NOAA Footer",
                desc = "Show the source tag in Big Temp mode.",
                icon = "compress",
                default = True,
            ),
        ],
    )
