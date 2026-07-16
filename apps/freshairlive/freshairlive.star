load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

APP_NAME = "FreshAir Live"
DEFAULT_TITLE = "Littleton AQI"
DEFAULT_LAT = "39.6133"
DEFAULT_LON = "-105.0166"

AQI_COLORS = {
    1: "#64D832",
    2: "#FFD21A",
    3: "#FF8A18",
    4: "#F23838",
    5: "#A85BE8",
}

AQI_LABELS = {
    1: "GOOD",
    2: "FAIR",
    3: "MOD",
    4: "POOR",
    5: "V POOR",
}

THRESHOLDS = {
    "so2": [20, 80, 250, 350],
    "no2": [40, 70, 150, 200],
    "pm10": [20, 50, 100, 200],
    "pm2_5": [10, 25, 50, 75],
    "o3": [60, 100, 140, 180],
    "co": [4400, 9400, 12400, 15400],
}

DISPLAY_NAMES = {
    "pm2_5": "PM2.5",
    "pm10": "PM10",
    "o3": "O3",
    "no2": "NO2",
    "so2": "SO2",
    "co": "CO",
    "no": "NO",
    "nh3": "NH3",
}

MOUNTAIN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAADCAYAAABBCiV2AAAAGklEQVR4nGNgQAM7duz4jy6GIoGL
xhTAohEAxZwcYGS1JUEAAAAASUVORK5CYII=
""")
PIN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHCAYAAADAp4fuAAAAJ0lEQVR4nGNggIL/////Z0AGUIH/
MAkmJAm4IiYGfADZTKwqsQoCABnkE/Vyf7hwAAAAAElFTkSuQmCC
""")
PIN_HALO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHCAYAAADAp4fuAAAAMklEQVR4nG2MsQ0AMAjDrP5/DkO+
SwcoQqIeHTkASArblhRMAfgNhyJ90nKxPkfe/Te/ZPspFy4Zpe8AAAAASUVORK5CYII=
""")

LEAF_LARGE_1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAuklEQVR4nK1UwRHEIAiUm+slvmNL
sarYUnzHariXDhJAJnP7coBdFyGBYOC4d+SxEitYHFFEElrlXIVajMeBJnkLnjYp7+NxeG7X0v0Q
k1x5UWKFLv5w1hPUDUWPS+6Au9La68gtTa4ob3LGb8stDTI9a/XiAN5CFVu9mYSvlsgtTcR+5q1S
QAjzakhTOrdLFKGcEiv8/83o4nmXl7saYlrhSsiE9t0houuvsRTlQpaIafe4d+STtFr8AXUsogH3
W/LBAAAAAElFTkSuQmCC
""")
LEAF_SMALL_1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAAVElEQVR4nI2QsQ2AMAwEj4hdoE5W
ClPBSlA70zyVETJEylXWW/ZZhkC1rJjNsbkvJ1gRwLFeE0CKU12qZf3h2x/d1gqu89oZ0qX3gZFe
jqTPC4Z0N9sVLnAM0587AAAAAElFTkSuQmCC
""")
LEAF_LARGE_2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAuUlEQVR4nK1UwRGAMAgDzyl0Brv/
HDqDXQMfWgUEyp3y6gFJE8QiBEHrRDqHpWKEMUksol4t1ejldB55UVvI2OS40VMoEssOsM2iZs1u
8FRlA0vFdsHgqlp2G33lzRFoVaLJIrzsNlUcJ5S9btvmB8zPTv/L5pfwyTozs8JcDQA4LXFgOyur
PBBArob5q7A9E2CGwVLx/5nxxcsur1Z1k3mNPaIw3FeDKPVqdEk1UUQSyqV1Iv0lI4sHm5GfdFU/
cY8AAAAASUVORK5CYII=
""")
LEAF_SMALL_2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAATUlEQVR4nGNgQAP/L0n9RxdjxJDU
fcrAcFkaIqn3jJGBgYGBCV0XTvD/ktR/rABqOgtcJdQKZOtggCjrmJAdiA5wiTP8//8fIwiIsg4A
MhkrzmB5OKAAAAAASUVORK5CYII=
""")
LEAF_LARGE_3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAuElEQVR4nK1UwRGAMAgDzyF0UDuE
Dmq3wIdWAYFyp7x6QNIEsQhB0DqRzmGpGGFMEouoV0s1ejmdR17UFjI2OW70FIrEsgNss6hZsxs8
VdnAUrFdMLiqlt1GX3lzBFqVaLIIL7tNFccJZa/btvkB87PT/7L5JXyyzsysMFcDAE5LHNjOyioP
BJCrYf4qbM8EmGGwVPx/ZnzxssurVd1kXmOPKAz31SBKvRpdUk0UkYRyaZ1If8nI4gHwO5n2wtWP
mQAAAABJRU5ErkJggg==
""")
LEAF_SMALL_3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAAT0lEQVR4nI2QwQkAIQwER7EILfSu
CC1Uu9j7eCJRwXmFDcmEgEE5ymZhaT4VkQTg3uYAvJ06ohy1pW8fOkri1426c6Xz84GWU46k5QVX
ug/wZCywG6oxRwAAAABJRU5ErkJggg==
""")
LEAF_LARGE_4 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAtUlEQVR4nK1USRLEIAiUqbnG98j/
D/Ke+ADnpIUMW6XSJwvothESKA7u1qaMVSLwOKqIJhTlUoVWTMaBJ2ULmTY575NxePUeut9imqss
KhEs8T9nK8HdcKy45g6kK6u9hYF4uOK8w5m8bSBuMj9b9eoAnsIUi95Mw9dKDMSDuM6yVQ4o5VwN
bUpX76oI51QieP/N+OJll1e62mJWYSTkwvru5pypv0YoKoU8Edfu3dqUk/Ra/AHn8KEFEKiLMQAA
AABJRU5ErkJggg==
""")
LEAF_SMALL_4 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAAT0lEQVR4nI2Quw3AIAwFD0SbzGP2
L2AeMoBTWUIPkLjy+XOWQRhmrlnS4tMaX60AvL0ngKxTR4aZ74jtJRpDMeuCK12eD1ROOe6+vOBK
9wMVXi281KS7BwAAAABJRU5ErkJggg==
""")
LEAF_LARGE_5 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAwUlEQVR4nK1UQQ7EIAiEZv9Qf1aT
9nk1aX/WvoI9bGxGFtBkl5MiM84gkSmIY71E53JJHGFMEouodzZU6OV0nvFQWxixibiXpxD3yz7T
ud3NmdW7yVM1GrkkrhdMnqpln01wzVstYK0KiyzCareqQlyjTN92bvcDxrVX/2Xzl3DJej2zwhwN
oo8tBNa1torBRO1oWK+Ec4aBmFwS/79nOHijw6tVPWReYY8oDO/XEJGhX6NLqokiklDusV6iXzKy
+AaUZ6l0VNEOGwAAAABJRU5ErkJggg==
""")
LEAF_SMALL_5 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAAUUlEQVR4nGNgQAMrol/8RxdjQZcM
XyLOwMAAYUcslWBkYGBgYELXhROsiH7xHxuAmQ63bmXMSwaYdTA2DBBlHROyA9EBLnGG////YwQB
UdYBAJBBLsrUTpQdAAAAAElFTkSuQmCC
""")
LEAF_INFO_1 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAaElEQVR4nI2QwQ3AIAwDDWIXeMNK
dCpYCd4wTfqiAmrU+hXFF0sOQBSbF7Y3DEq2AC0IAGRX1fD1Vxrdx+aFaYYVu0624OphCcuuKrND
+zwfLfAwWPJTcG7MdPRH0dN3XhIRCuq/IADcWS9Lrt3Hq8cAAAAASUVORK5CYII=
""")
LEAF_INFO_2 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAYklEQVR4nI2Q0RGAMAhDQ88p6gx2
/znqDHaN+GHl0Kan+eLghSMAQqyZqm8S2g5gXy+gNGfS1zbZZ82UCrBJdzjDwdJsGaB3HUxP+B6I
zUAPGBMrTecedPKd0UBKMP0FAeAEfu5IgyiI/nIAAAAASUVORK5CYII=
""")
LEAF_INFO_3 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAY0lEQVR4nI2Q0Q2AIBBD3xmGgEFl
CBwUtzh/xICUaL9I+3pJASEv0ZUfJLRXnOQAlk9r+fZ1Tfpeokt1sMn2XuFIg2X5tDBB73dXGuEW
iMtwD+wXKy3zZ+jid+aCuwS3vyDABdzHSIfVzsaLAAAAAElFTkSuQmCC
""")
LEAF_INFO_4 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAYUlEQVR4nI2QQQ7AIAgEF9NrfQ/+
/yDvsQ+gJwy1a9o5GRgIK0AYqs7qwqSzd1ytAQCq2XTK1zZaH6rOyLKw6XxGUM3kWKX1nYcecjTY
5hkwJ2Zs+xF09zsv3J2K5a8IADcGXUrWJ8kCWwAAAABJRU5ErkJggg==
""")
LEAF_INFO_5 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAZ0lEQVR4nI2Q0QnAIBBDo7iDbqZg
x1Owm+kU149iURtp83Vc3gVyAFGJVdjeMMgnC+CeQ3aq+/orje5LrMI0wopd+2RxHm0KC9kps0Lr
PB5NcDdY8lNwbMy09XvR3XdeEhEK6r8gAFzEiE1/6ky50wAAAABJRU5ErkJggg==
""")

# Configuration

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "title",
                name = "Display title",
                desc = "Header shown on the Tidbyt.",
                icon = "gear",
                default = DEFAULT_TITLE,
            ),
            schema.Text(
                id = "latitude",
                name = "Latitude",
                desc = "Location latitude.",
                icon = "locationDot",
                default = DEFAULT_LAT,
            ),
            schema.Text(
                id = "longitude",
                name = "Longitude",
                desc = "Location longitude.",
                icon = "locationDot",
                default = DEFAULT_LON,
            ),
            schema.Text(
                id = "api_key",
                name = "OpenWeather API key",
                desc = "Leave blank to use sample data.",
                icon = "key",
            ),
            schema.Toggle(
                id = "show_source",
                name = "Show likely source",
                desc = "Show an inferred pollution source.",
                icon = "magnifyingGlass",
                default = True,
            ),
            schema.Toggle(
                id = "animate_pin",
                name = "Animate marker",
                desc = "Pulse the white pollutant marker.",
                icon = "locationPin",
                default = True,
            ),
            schema.Dropdown(
                id = "regional_marker",
                name = "Regional marker",
                desc = "Small location marker in the header.",
                icon = "mountain",
                default = "mountain",
                options = [
                    schema.Option(display = "Mountain", value = "mountain"),
                    schema.Option(display = "None", value = "none"),
                ],
            ),
        ],
    )

# Embedded artwork

def _leaf(level, size_name):
    leaves = {
        "large_1": LEAF_LARGE_1,
        "large_2": LEAF_LARGE_2,
        "large_3": LEAF_LARGE_3,
        "large_4": LEAF_LARGE_4,
        "large_5": LEAF_LARGE_5,
        "small_1": LEAF_SMALL_1,
        "small_2": LEAF_SMALL_2,
        "small_3": LEAF_SMALL_3,
        "small_4": LEAF_SMALL_4,
        "small_5": LEAF_SMALL_5,
        "info_1": LEAF_INFO_1,
        "info_2": LEAF_INFO_2,
        "info_3": LEAF_INFO_3,
        "info_4": LEAF_INFO_4,
        "info_5": LEAF_INFO_5,
    }
    return leaves["%s_%d" % (size_name, level)]

# AQI and pollutant analysis

def _clamp(value, low, high):
    if value < low:
        return low
    if value > high:
        return high
    return value

def _severity(name, value):
    # Returns category (1-5) and normalized 0-1 position across the full bar.
    points = THRESHOLDS.get(name)
    if points == None:
        return (1, 0.05)
    bounds = [0] + points
    category = 5
    for i in range(4):
        if value < points[i]:
            category = i + 1
            break
    low = bounds[category - 1]
    if category < 5:
        high = points[category - 1]
        fraction = (value - low) / (high - low)
    else:
        # Cap the final category at 1.5x its threshold for display purposes.
        high = low * 1.5
        fraction = (value - low) / (high - low)
    fraction = _clamp(fraction, 0, 1)
    return (category, ((category - 1) + fraction) / 5.0)

def _dominant(components):
    preferred = ["pm2_5", "pm10", "o3", "no2", "so2", "co"]
    winner = "pm2_5"
    winner_score = -1
    winner_cat = 1
    winner_pos = 0
    for name in preferred:
        value = components.get(name, 0)
        cat, pos = _severity(name, value)
        score = cat * 10 + pos
        if score > winner_score:
            winner = name
            winner_score = score
            winner_cat = cat
            winner_pos = pos
    return {
        "name": winner,
        "value": components.get(winner, 0),
        "category": winner_cat,
        "position": winner_pos,
    }

def _likely_source(dominant, components):
    name = dominant["name"]
    if name == "pm2_5":
        if components.get("pm10", 0) > 0 and components.get("pm2_5", 0) / components.get("pm10", 1) > 0.45:
            return "LIKELY SMOKE"
        return "PARTICULATES"
    if name == "pm10":
        return "LIKELY DUST"
    if name == "o3":
        return "AFTERNOON OZONE"
    if name == "no2" or name == "co":
        return "TRAFFIC / BURN"
    return "CAUSE UNCLEAR"

# Data retrieval

def _sample_data():
    return {
        "current": {
            "dt": 0,
            "main": {"aqi": 2},
            "components": {
                "co": 300.0,
                "no": 1.1,
                "no2": 19.0,
                "o3": 74.0,
                "so2": 2.0,
                "pm2_5": 18.6,
                "pm10": 24.0,
                "nh3": 1.0,
            },
        },
        "plus6": {
            "dt": 21600,
            "main": {"aqi": 2},
            "components": {"pm2_5": 22.0, "pm10": 28.0, "o3": 83.0, "no2": 17.0, "so2": 2.0, "co": 350.0},
        },
        "plus12": {
            "dt": 43200,
            "main": {"aqi": 3},
            "components": {"pm2_5": 29.0, "pm10": 41.0, "o3": 108.0, "no2": 14.0, "so2": 2.0, "co": 370.0},
        },
    }

def _nearest_forecast(entries, target_dt):
    """Return the forecast entry whose timestamp is closest to target_dt."""
    best = entries[0]
    best_distance = abs(best["dt"] - target_dt)

    for entry in entries[1:]:
        distance = abs(entry["dt"] - target_dt)
        if distance < best_distance:
            best = entry
            best_distance = distance

    return best

def _fetch(config):
    api_key = config.str("api_key")
    if api_key == None or api_key == "":
        return _sample_data()

    lat = config.str("latitude", DEFAULT_LAT)
    lon = config.str("longitude", DEFAULT_LON)
    base = "https://api.openweathermap.org/data/2.5/air_pollution"
    current_url = "%s?lat=%s&lon=%s&appid=%s" % (base, lat, lon, api_key)
    forecast_url = "%s/forecast?lat=%s&lon=%s&appid=%s" % (base, lat, lon, api_key)

    current_rep = http.get(current_url)
    forecast_rep = http.get(forecast_url)
    if current_rep.status_code != 200 or forecast_rep.status_code != 200:
        return None

    current_json = current_rep.json()
    forecast_json = forecast_rep.json()
    if len(current_json.get("list", [])) == 0 or len(forecast_json.get("list", [])) < 13:
        return None

    current = current_json["list"][0]
    forecast = forecast_json["list"]
    current_dt = current["dt"]

    return {
        "current": current,
        "plus6": _nearest_forecast(forecast, current_dt + 21600),
        "plus12": _nearest_forecast(forecast, current_dt + 43200),
    }

# Rendering

def _header(title, level, regional_marker):
    marker = render.Image(src = MOUNTAIN) if regional_marker == "mountain" else render.Box(width = 1, height = 3)
    return render.Column(
        children = [
            render.Box(
                width = 64,
                height = 6,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = title.upper(),
                            font = "tom-thumb",
                            color = "#FFFFFF",
                        ),
                        marker,
                    ],
                ),
            ),
            render.Box(width = 64, height = 1, color = AQI_COLORS[level]),
        ],
    )

def _overview(title, data, marker):
    level = int(data["main"]["aqi"])
    return render.Column(
        children = [
            _header(title, level, marker),
            render.Box(
                width = 64,
                height = 25,
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(src = _leaf(level, "large")),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(
                                    content = AQI_LABELS[level],
                                    font = "tb-8",
                                    color = AQI_COLORS[level],
                                ),
                                render.Text(
                                    content = "LEVEL %d" % level,
                                    font = "tom-thumb",
                                    color = "#B8B8B8",
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ],
    )

def _pin_widget(pin_src, position):
    # 45-pixel gauge with generous left/right margins.
    x = 9 + int(_clamp(position, 0, 1) * 40)
    return render.Stack(
        children = [
            render.Padding(
                pad = (9, 4, 0, 0),
                child = render.Row(
                    children = [
                        render.Box(width = 9, height = 3, color = AQI_COLORS[1]),
                        render.Box(width = 9, height = 3, color = AQI_COLORS[2]),
                        render.Box(width = 9, height = 3, color = AQI_COLORS[3]),
                        render.Box(width = 9, height = 3, color = AQI_COLORS[4]),
                        render.Box(width = 9, height = 3, color = AQI_COLORS[5]),
                    ],
                ),
            ),
            render.Padding(
                pad = (x, 0, 0, 0),
                child = render.Image(src = pin_src),
            ),
        ],
    )

def _short_value(value):
    s = str(value)
    if len(s) > 5:
        return s[:5]
    return s

def _source_label(source):
    if source == "LIKELY SMOKE":
        return "LIKELY SMOKE"
    if source == "LIKELY DUST":
        return "LIKELY DUST"
    if source == "AFTERNOON OZONE":
        return "OZONE LIKELY"
    if source == "TRAFFIC / BURN":
        return "TRAFFIC LIKELY"
    if source == "PARTICULATES":
        return "PARTICULATES"
    return "CAUSE UNCLEAR"

def _pollutant(title, data, marker, show_source, pin_src):
    level = int(data["main"]["aqi"])
    dom = _dominant(data["components"])
    source = _source_label(_likely_source(dom, data["components"]))
    value_text = _short_value(dom["value"])
    location_title = title.upper().replace(" AQI", "")

    return render.Stack(
        children = [
            # Compact location header.
            render.Padding(
                pad = (1, 0, 0, 0),
                child = render.Text(
                    content = location_title,
                    font = "tom-thumb",
                    color = "#FFFFFF",
                ),
            ),
            render.Padding(
                pad = (54, 1, 0, 0),
                child = render.Image(src = MOUNTAIN) if marker == "mountain" else render.Box(width = 1, height = 3),
            ),
            render.Padding(
                pad = (0, 6, 0, 0),
                child = render.Box(
                    width = 64,
                    height = 1,
                    color = AQI_COLORS[level],
                ),
            ),

            # Tightly grouped pollutant row.
            render.Padding(
                pad = (4, 8, 0, 0),
                child = render.Image(src = _leaf(level, "info")),
            ),
            render.Padding(
                pad = (17, 10, 0, 0),
                child = render.Text(
                    content = DISPLAY_NAMES[dom["name"]],
                    font = "CG-pixel-3x5-mono",
                    color = "#FFFFFF",
                ),
            ),
            render.Padding(
                pad = (36, 10, 0, 0),
                child = render.Text(
                    content = value_text,
                    font = "CG-pixel-3x5-mono",
                    color = "#FFFFFF",
                ),
            ),

            # Gauge sits directly beneath the data row.
            render.Padding(
                pad = (0, 17, 0, 0),
                child = _pin_widget(pin_src, dom["position"]),
            ),

            # Full-width centered source label with compact lettering.
            render.Padding(
                pad = (0, 27, 0, 0),
                child = render.Box(
                    width = 64,
                    height = 5,
                    child = render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = source if show_source else "",
                                font = "CG-pixel-3x5-mono",
                                color = AQI_COLORS[dom["category"]],
                            ),
                        ],
                    ),
                ),
            ),
        ],
    )

def _trend_symbol(from_level, to_level):
    if to_level > from_level:
        return ">"
    if to_level < from_level:
        return "<"
    return "-"

def _forecast_column(label, item):
    level = int(item["main"]["aqi"])
    return render.Box(
        width = 17,
        height = 24,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(
                    content = label,
                    font = "tom-thumb",
                    color = "#FFFFFF",
                ),
                render.Image(src = _leaf(level, "small")),
                render.Text(
                    content = AQI_LABELS[level],
                    font = "tom-thumb",
                    color = AQI_COLORS[level],
                ),
            ],
        ),
    )

def _forecast(title, all_data, marker):
    current_level = int(all_data["current"]["main"]["aqi"])
    six_level = int(all_data["plus6"]["main"]["aqi"])
    twelve_level = int(all_data["plus12"]["main"]["aqi"])
    return render.Column(
        children = [
            _header(title, current_level, marker),
            render.Box(
                width = 64,
                height = 25,
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        _forecast_column("NOW", all_data["current"]),
                        render.Text(
                            content = _trend_symbol(current_level, six_level),
                            font = "tom-thumb",
                            color = "#B8B8B8",
                        ),
                        _forecast_column("+6H", all_data["plus6"]),
                        render.Text(
                            content = _trend_symbol(six_level, twelve_level),
                            font = "tom-thumb",
                            color = "#B8B8B8",
                        ),
                        _forecast_column("+12H", all_data["plus12"]),
                    ],
                ),
            ),
        ],
    )

def _error(title):
    return render.Column(
        children = [
            _header(title, 1, "none"),
            render.Box(
                width = 64,
                height = 25,
                child = render.Column(
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 6, 0, 0),
                            child = render.Text(
                                content = "DATA UNAVAILABLE",
                                font = "CG-pixel-3x5-mono",
                                color = "#FFFFFF",
                            ),
                        ),
                        render.Text(
                            content = "CHECK SETTINGS",
                            font = "CG-pixel-3x5-mono",
                            color = "#B8B8B8",
                        ),
                    ],
                ),
            ),
        ],
    )

def main(config):
    title = config.str("title", DEFAULT_TITLE)
    marker = config.str("regional_marker", "mountain")
    show_source = config.bool("show_source")
    if show_source == None:
        show_source = True
    animate_pin = config.bool("animate_pin")
    if animate_pin == None:
        animate_pin = True

    data = _fetch(config)
    if data == None:
        return render.Root(child = _error(title))

    pin_frames = [PIN, PIN_HALO, PIN] if animate_pin else [PIN]
    frames = [
        _overview(title, data["current"], marker),
    ]
    for pin_src in pin_frames:
        frames.append(_pollutant(title, data["current"], marker, show_source, pin_src))
    frames.append(_forecast(title, data, marker))

    return render.Root(
        delay = 1800,
        child = render.Animation(children = frames),
    )
