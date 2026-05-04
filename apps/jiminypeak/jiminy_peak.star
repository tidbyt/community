load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEER = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAAOCAYAAAAvxDzwAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAARGVYSWZNTQAqAAAACAABh2kABAAAAAEAAAAaAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAUoAMABAAAAAEAAAAOAAAAAJiNf94AAAGdaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIj4KICAgICAgICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjUxMjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj41MTI8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KuC9IVwAAAYJJREFUOBHNUruKwlAQPYkRwQeIGkipQgQbbSysBBHsUohtOj/D3sI/yCdY22hhaWNlqVjZqIVioYXgY3buhdzNsrjLarMDlzvM48yZBwBQ8EWjUXJdl7LZ7Bd7MOYX/RMwl8vRYDCg2+1Gtm2/BKhzNSm6rqNeryOfzyMUCqHdbvuuP/0aRwsmSpLJJBaLBcQ/Go0wmUwwnU5xOBygaRrC4bDUBYFqtYpYLCZj9vu9wpCtZTIZqtVq1Gw2abPZUFDu9zudTic6n890uVxou93Sbrcjz/OoXC4TF1HjMdLpNBzHwXq9RjweR6lUwnA4lAx5MahUKhBshM8Xy7KkejwesVqtcL1efRe0VCpFpmliuVyi1WpJMF6KDDAMA8wAvCwkEgkIO18BOp2OLPR4PDAej9HtdjGfzxWoosszUjp7n+qiRZ4f9ft9ms1msnWeuR//PPEnUOGLRCLU6/WoWCwSsyTuQoC+DihyG42GXEqhUJCA385GVHhH1GG/AxLM/f+AH7yq7kUNe46+AAAAAElFTkSuQmCC")

OTS_URL = "https://www.onthesnow.com/massachusetts/jiminy-peak/skireport"
WEATHER_URL = (
    "https://api.open-meteo.com/v1/forecast" +
    "?latitude=42.574&longitude=-73.044" +
    "&current_weather=true&temperature_unit=fahrenheit"
)
CACHE_KEY = "jiminy_v2"
WEATHER_KEY = "jiminy_wx_v2"
CACHE_TTL = 900

TITLE_CLR = "#AADDFF"
WHITE = "#FFFFFF"
DIM = "#666666"
GREEN = "#00FF00"
BLUE = "#4499FF"
GOLD = "#FFD700"
ICE = "#AADDFF"

def first_int(s):
    digits = ""
    for ch in s.elems():
        if ch >= "0" and ch <= "9":
            digits += ch
        elif digits:
            break
    return int(digits) if digits else None

def get_temp(ttl):
    raw = cache.get(WEATHER_KEY)
    if raw:
        return int(json.decode(raw)["t"])
    res = http.get(WEATHER_URL)
    if res.status_code == 200:
        cw = json.decode(res.body()).get("current_weather", {})
        t = int(cw.get("temperature", 32))
        cache.set(WEATHER_KEY, json.encode({"t": t}), ttl_seconds = ttl)
        return t
    return 32

def find_json_ld(body):
    # Pull the JSON-LD block that contains additionalProperty (resort conditions)
    marker = '"additionalProperty"'
    idx = body.find(marker)
    if idx < 0:
        return None
    start = body.rfind("{", 0, idx)
    if start < 0:
        return None

    # Walk forward to find the matching closing brace
    depth = 0
    for i in range(start, len(body)):
        if body[i] == "{":
            depth += 1
        elif body[i] == "}":
            depth -= 1
            if depth == 0:
                return body[start:i + 1]
    return None

def prop(data, name):
    # Find a named value inside additionalProperty list
    key = '"' + name + '"'
    idx = data.find(key)
    if idx < 0:
        return None
    val_idx = data.find('"value"', idx)
    if val_idx < 0:
        return None
    colon = data.find(":", val_idx)
    if colon < 0:
        return None

    # Skip whitespace after colon
    i = colon + 1
    for i in range(colon + 1, len(data)):
        if data[i] not in (" ", "\n", "\r", "\t"):
            break

    # Read until comma, brace, or newline
    end = i
    for end in range(i, len(data)):
        if data[end] in (",", "}", "\n"):
            break
    raw = data[i:end].strip().strip('"')
    return raw

def get_data(ttl):
    raw = cache.get(CACHE_KEY)
    if raw:
        return json.decode(raw)

    d = {
        "status": "Unknown",
        "open_trails": 0,
        "open_lifts": 0,
        "snow": 0,
        "opens": "",
    }

    res = http.get(OTS_URL)
    if res.status_code == 200:
        body = res.body()
        block = find_json_ld(body)
        if block:
            status = prop(block, "Resort status")
            if status:
                d["status"] = status

            v = first_int(prop(block, "Open trails") or "0")
            if v != None:
                d["open_trails"] = v

            v = first_int(prop(block, "Open lifts") or "0")
            if v != None:
                d["open_lifts"] = v

            v = first_int(prop(block, "Last snowfall amount") or "0")
            if v != None:
                d["snow"] = v

            opens = prop(block, "Projected season opening date")
            if opens:
                d["opens"] = opens

    cache.set(CACHE_KEY, json.encode(d), ttl_seconds = ttl)
    return d

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "refresh",
                name = "Refresh frequency",
                desc = "How often to check for updated conditions",
                icon = "clock",
                default = "900",
                options = [
                    schema.Option(display = "Every 15 minutes", value = "900"),
                    schema.Option(display = "Once a day", value = "86400"),
                ],
            ),
        ],
    )

def main(config):
    ttl = int(config.get("refresh", "900"))
    d = get_data(ttl)
    temp = get_temp(ttl)

    is_open = d["status"] == "Open"

    if is_open:
        middle = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(
                    "{} Trails".format(int(d["open_trails"])),
                    font = "tom-thumb",
                    color = WHITE,
                ),
                render.Text(
                    "{} Lifts".format(int(d["open_lifts"])),
                    font = "tom-thumb",
                    color = WHITE,
                ),
            ],
        )
        bottom = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text("{}F".format(temp), font = "tom-thumb", color = GOLD),
                render.Text(
                    str(int(d["snow"])) + '" New Snow',
                    font = "tom-thumb",
                    color = ICE,
                ),
            ],
        )
    else:
        # Resort is closed — show status and projected opening
        opens = d["opens"]
        opens_short = opens[5:] if len(opens) >= 7 else opens  # "2026-11-27" → "11-27"
        middle = render.Text(
            "Closed",
            font = "tom-thumb",
            color = "#FF4444",
        )
        bottom = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text("{}F".format(temp), font = "tom-thumb", color = GOLD),
                render.Text("Opens " + opens_short, font = "tom-thumb", color = DIM),
            ],
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = DEER, width = 20, height = 14),
                        render.Text("JIMINY PEAK", font = "tom-thumb", color = TITLE_CLR),
                    ],
                ),
                middle,
                bottom,
            ],
        ),
    )
