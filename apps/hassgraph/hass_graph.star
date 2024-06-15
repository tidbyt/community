load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ICONS = {
    "thermometer": base64.decode("""
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/Pg0KPCEtLSBVcGxvYWRlZCB0bzogU1ZHIFJlcG8sIHd3dy5zdmdyZXBvLmNvbSwgR2VuZXJhdG9yOiBTVkcgUmVwbyBNaXhlciBUb29scyAtLT4NCjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgDQoJIHZpZXdCb3g9IjAgMCA1MTIgNTEyIiB4bWw6c3BhY2U9InByZXNlcnZlIj4NCjxwb2x5Z29uIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiBwb2ludHM9IjQxMS44MjYsMjc4LjI2IDM3OC40MSwyNzguMjYgMzc4LjQxLDI0NC44NyAzNDUuMDE5LDI0NC44NyAzNDUuMDE5LDMzLjM5MSAzMTEuNjI4LDMzLjM5MSANCgkzMTEuNjI4LDAgMjAwLjMyMywwIDIwMC4zMjMsMzMuMzkxIDE2Ni45MzIsMzMuMzkxIDE2Ni45MzIsMjQ0Ljg3IDEzMy41NDEsMjQ0Ljg3IDEzMy41NDEsMjc4LjI2IDEwMC4xNzQsMjc4LjI2IDEwMC4xNzQsNDQ1LjIxNiANCgkxMzMuNTQxLDQ0NS4yMTYgMTMzLjU0MSw0NDUuMjE3IDEzMy41NDEsNDc4LjYwOSAxNjYuOTMyLDQ3OC42MDkgMTY2LjkzMiw1MTIgMzQ1LjAxOSw1MTIgMzQ1LjAxOSw0NzguNjA5IDM3OC40MSw0NzguNjA5IA0KCTM3OC40MSw0NDUuMjE3IDQxMS44MDIsNDQ1LjIxNyA0MTEuODAyLDQ0NS4yMTYgNDExLjgyNiw0NDUuMjE2ICIvPg0KPHJlY3QgeD0iMTMzLjU2NSIgeT0iMjQ0Ljg3IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSIvPg0KPHJlY3QgeD0iMTMzLjU2NSIgeT0iNDQ1LjIxNyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiLz4NCjxyZWN0IHg9IjE2Ni45NTciIHk9IjQ3OC42MDkiIHdpZHRoPSIxNzguMDg3IiBoZWlnaHQ9IjMzLjM5MSIvPg0KPHJlY3QgeD0iMTAwLjE3NCIgeT0iMjc4LjI2MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIxNjYuOTU3Ii8+DQo8cmVjdCB4PSIzNDUuMDQzIiB5PSIyNDQuODciIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIi8+DQo8cmVjdCB4PSIzNDUuMDQzIiB5PSI0NDUuMjE3IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSIvPg0KPHJlY3QgeD0iMzc4LjQzNSIgeT0iMjc4LjI2MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIxNjYuOTU3Ii8+DQo8cmVjdCB4PSIyMDAuMzQ4IiB3aWR0aD0iMTExLjMwNCIgaGVpZ2h0PSIzMy4zOTEiLz4NCjxyZWN0IHg9IjE2Ni45NTciIHk9IjMzLjM5MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIyMTEuNDc4Ii8+DQo8cmVjdCB4PSIzMTEuNjUyIiB5PSIzMy4zOTEiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMjExLjQ3OCIvPg0KPHBvbHlnb24gc3R5bGU9ImZpbGw6I0ZGMEMzODsiIHBvaW50cz0iMzExLjY1MiwzMTEuNjUyIDMxMS42NTIsMjc4LjI2MSAyNzguMjYxLDI3OC4yNjEgMjc4LjI2MSw2Ni43ODMgMjMzLjczOSw2Ni43ODMgDQoJMjMzLjczOSwyNzguMjYxIDIwMC4zNDgsMjc4LjI2MSAyMDAuMzQ4LDMxMS42NTIgMTY2Ljk1NywzMTEuNjUyIDE2Ni45NTcsNDExLjgyNiAyMDAuMzQ4LDQxMS44MjYgMjAwLjM0OCw0MTEuODI2IA0KCTIwMC4zNDgsNDQ1LjIxNyAzMTEuNjUyLDQ0NS4yMTcgMzExLjY1Miw0MTEuODI2IDMxMS42NTIsNDExLjgyNiAzNDUuMDQzLDQxMS44MjYgMzQ1LjA0MywzMTEuNjUyICIvPg0KPC9zdmc+
"""),
    "wind": base64.decode("""
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/Pg0KPCEtLSBVcGxvYWRlZCB0bzogU1ZHIFJlcG8sIHd3dy5zdmdyZXBvLmNvbSwgR2VuZXJhdG9yOiBTVkcgUmVwbyBNaXhlciBUb29scyAtLT4NCjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgDQoJIHZpZXdCb3g9IjAgMCA1MTIgNTEyIiB4bWw6c3BhY2U9InByZXNlcnZlIj4NCjxwYXRoIHN0eWxlPSJmaWxsOiMwMDZERjA7IiBkPSJNMCwwdjI1Nmg0MTEuODI2di0zMy4zOTFoMzMuMzkxVjI1NmgtMzMuMzkxdjMzLjM5MUgwdjMzLjM5MWg0NDUuMjE3djMzLjM5MUgwdjY2Ljc4M2gyODkuMzkxDQoJdjMzLjM5MUgwVjUxMmg1MTJWMEgweiBNNDExLjgyNiwxMDAuMTc0VjY2Ljc4M0gzMTEuNjUydjMzLjM5MWgtMzMuMzkxdjg5LjA0M2g2Ni43ODN2MzMuMzkxaC02Ni43ODN2LTMzLjM5MUgyNDQuODd2LTg5LjA0Mw0KCWgzMy4zOTFWNjYuNzgzaDMzLjM5MVYzMy4zOTFoMTAwLjE3NHYzMy4zOTFoMzMuMzkxdjMzLjM5MUg0MTEuODI2eiBNMzc4LjQzNSw0NDUuMjE3aC0zMy4zOTF2LTU1LjY1MmgzMy4zOTFWNDQ1LjIxN3oNCgkgTTQ3OC42MDksNDQ1LjIxN2gtMzMuMzkxdjMzLjM5MWgtNjYuNzgzdi0zMy4zOTFoNjYuNzgzdi04OS4wNDNoMzMuMzkxVjQ0NS4yMTd6IE00NzguNjA5LDIyMi42MDloLTMzLjM5MVYxMDAuMTc0aDMzLjM5MVYyMjIuNjA5DQoJeiIvPg0KPGc+DQoJPHJlY3QgeD0iMzQ1LjA0MyIgeT0iMzg5LjU2NSIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iNTUuNjUyIi8+DQoJPHJlY3QgeD0iMzc4LjQzNSIgeT0iNDQ1LjIxNyIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSI2Ni43ODMiIGhlaWdodD0iMzMuMzkxIi8+DQoJPHJlY3QgeD0iNDQ1LjIxNyIgeT0iMzU2LjE3NCIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iODkuMDQzIi8+DQoJPHJlY3QgeT0iMzIyLjc4MyIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSI0NDUuMjE3IiBoZWlnaHQ9IjMzLjM5MSIvPg0KCTxyZWN0IHk9IjQyMi45NTciIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiB3aWR0aD0iMzIyLjc4MyIgaGVpZ2h0PSIzMy4zOTEiLz4NCgk8cmVjdCB4PSI0MTEuODI2IiB5PSI2Ni43ODMiIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSIvPg0KCTxyZWN0IHg9IjI3OC4yNjEiIHk9IjY2Ljc4MyIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIi8+DQoJPHJlY3QgeD0iMjc4LjI2MSIgeT0iMTg5LjIxNyIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSI2Ni43ODMiIGhlaWdodD0iMzMuMzkxIi8+DQoJPHJlY3QgeD0iNDExLjgyNiIgeT0iMjIyLjYwOSIgc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIi8+DQoJPHJlY3QgeD0iMjQ0Ljg3IiB5PSIxMDAuMTc0IiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI4OS4wNDMiLz4NCgk8cmVjdCB4PSIzMTEuNjUyIiB5PSIzMy4zOTEiIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiB3aWR0aD0iMTAwLjE3NCIgaGVpZ2h0PSIzMy4zOTEiLz4NCgk8cmVjdCB4PSI0NDUuMjE3IiB5PSIxMDAuMTc0IiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIxMjIuNDM1Ii8+DQoJPHJlY3QgeT0iMjU2IiBzdHlsZT0iZmlsbDojRkZGRkZGOyIgd2lkdGg9IjQxMS44MjYiIGhlaWdodD0iMzMuMzkxIi8+DQo8L2c+DQo8L3N2Zz4=
"""),
    "ha": base64.decode("""
PHN2ZyB3aWR0aD0iMjQwIiBoZWlnaHQ9IjI0MCIgdmlld0JveD0iMCAwIDI0MCAyNDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxwYXRoIGQ9Ik0yNDAgMjI0Ljc2MkMyNDAgMjMzLjAxMiAyMzMuMjUgMjM5Ljc2MiAyMjUgMjM5Ljc2MkgxNUM2Ljc1IDIzOS43NjIgMCAyMzMuMDEyIDAgMjI0Ljc2MlYxMzQuNzYyQzAgMTI2LjUxMiA0Ljc3IDExNC45OTMgMTAuNjEgMTA5LjE1M0wxMDkuMzkgMTAuMzcyNUMxMTUuMjIgNC41NDI1IDEyNC43NyA0LjU0MjUgMTMwLjYgMTAuMzcyNUwyMjkuMzkgMTA5LjE2MkMyMzUuMjIgMTE0Ljk5MiAyNDAgMTI2LjUyMiAyNDAgMTM0Ljc3MlYyMjQuNzcyVjIyNC43NjJaIiBmaWxsPSIjRjJGNEY5Ii8+CjxwYXRoIGQ9Ik0yMjkuMzkgMTA5LjE1M0wxMzAuNjEgMTAuMzcyNUMxMjQuNzggNC41NDI1IDExNS4yMyA0LjU0MjUgMTA5LjQgMTAuMzcyNUwxMC42MSAxMDkuMTUzQzQuNzggMTE0Ljk4MyAwIDEyNi41MTIgMCAxMzQuNzYyVjIyNC43NjJDMCAyMzMuMDEyIDYuNzUgMjM5Ljc2MiAxNSAyMzkuNzYySDEwNy4yN0w2Ni42NCAxOTkuMTMyQzY0LjU1IDE5OS44NTIgNjIuMzIgMjAwLjI2MiA2MCAyMDAuMjYyQzQ4LjcgMjAwLjI2MiAzOS41IDE5MS4wNjIgMzkuNSAxNzkuNzYyQzM5LjUgMTY4LjQ2MiA0OC43IDE1OS4yNjIgNjAgMTU5LjI2MkM3MS4zIDE1OS4yNjIgODAuNSAxNjguNDYyIDgwLjUgMTc5Ljc2MkM4MC41IDE4Mi4wOTIgODAuMDkgMTg0LjMyMiA3OS4zNyAxODYuNDEyTDExMSAyMTguMDQyVjEwMi4xNjJDMTA0LjIgOTguODIyNSA5OS41IDkxLjg0MjUgOTkuNSA4My43NzI1Qzk5LjUgNzIuNDcyNSAxMDguNyA2My4yNzI1IDEyMCA2My4yNzI1QzEzMS4zIDYzLjI3MjUgMTQwLjUgNzIuNDcyNSAxNDAuNSA4My43NzI1QzE0MC41IDkxLjg0MjUgMTM1LjggOTguODIyNSAxMjkgMTAyLjE2MlYxODMuNDMyTDE2MC40NiAxNTEuOTcyQzE1OS44NCAxNTAuMDEyIDE1OS41IDE0Ny45MzIgMTU5LjUgMTQ1Ljc3MkMxNTkuNSAxMzQuNDcyIDE2OC43IDEyNS4yNzIgMTgwIDEyNS4yNzJDMTkxLjMgMTI1LjI3MiAyMDAuNSAxMzQuNDcyIDIwMC41IDE0NS43NzJDMjAwLjUgMTU3LjA3MiAxOTEuMyAxNjYuMjcyIDE4MCAxNjYuMjcyQzE3Ny41IDE2Ni4yNzIgMTc1LjEyIDE2NS44MDIgMTcyLjkxIDE2NC45ODJMMTI5IDIwOC44OTJWMjM5Ljc3MkgyMjVDMjMzLjI1IDIzOS43NzIgMjQwIDIzMy4wMjIgMjQwIDIyNC43NzJWMTM0Ljc3MkMyNDAgMTI2LjUyMiAyMzUuMjMgMTE1LjAwMiAyMjkuMzkgMTA5LjE2MlYxMDkuMTUzWiIgZmlsbD0iIzE4QkNGMiIvPgo8L3N2Zz4K
"""),
}

PLACEHOLDER_DATA = [
    {
        "attributes": {
            "unit_of_measurement": "°C",
        },
        "state": "23",
        "last_changed": "2024-01-06T12:00:00Z",
    },
    {
        "state": "18",
        "last_changed": "2024-01-06T13:00:00Z",
    },
    {
        "state": "22",
        "last_changed": "2024-01-06T14:00:00Z",
    },
    {
        "state": "24",
        "last_changed": "2024-01-06T15:00:00Z",
    },
    {
        "state": "12",
        "last_changed": "2024-01-06T16:00:00Z",
    },
]

MAX_TIME_PERIOD = 24

def main(config):
    if not config.str("ha_instance") or not config.str("ha_entity") or not config.str("ha_token"):
        print("Using placeholder data, please configure the app")
        data = PLACEHOLDER_DATA
        error = None
    else:
        time_period = get_time_period(config.str("time_period"))
        if time_period == None:
            return render_error_message("Invalid time period")

        start_time = time.now() - time.hour * time_period
        data, error = get_entity_data(config, start_time)

    if data == None:
        return render_error_message("Error: received status " + str(error))
    elif len(data) < 1:
        return render_error_message("No data available")

    unit = data[0]["attributes"]["unit_of_measurement"]
    points = calculate_hourly_average(data)
    current_value = data[-1]["state"]
    stats = calc_stats(data)

    return render_app(config, current_value, points, stats, unit)

def calculate_hourly_average(data):
    hourly_averages = {}
    current_hour = None
    hour_total = 0
    hour_count = 0
    index = 0

    for entry in data:
        timestamp = entry["last_changed"]
        hour = int(timestamp.split("T")[1].split(":")[0])
        value = float(entry["state"])

        if hour != current_hour:
            if current_hour != None:
                hourly_averages[index] = hour_total / hour_count if hour_count != 0 else 0
                index += 1
            current_hour = hour
            hour_total = 0
            hour_count = 0

        hour_total += value
        hour_count += 1

    if current_hour != None:
        hourly_averages[index] = hour_total / hour_count if hour_count != 0 else 0

    return list(hourly_averages.items())

def calc_stats(data):
    highest_value = float("-inf")
    highest_timestamp = None
    lowest_value = float("inf")
    lowest_timestamp = None
    total_value = 0
    count = 0

    for entry in data:
        value = float(entry["state"])
        total_value += value
        count += 1
        if value < lowest_value:
            lowest_value = value
            lowest_timestamp = entry["last_changed"]
        if value > highest_value:
            highest_value = value
            highest_timestamp = entry["last_changed"]

    average_value = total_value / count if count else 0
    average_value = (average_value * 10) // 1 / 10
    return {
        "lowest_value": str(lowest_value),
        "lowest_time": lowest_timestamp.split("T")[1][:5] if lowest_value != float("inf") else "N/A",
        "highest_value": str(highest_value),
        "highest_time": highest_timestamp.split("T")[1][:5] if highest_value != float("-inf") else "N/A",
        "average": str(average_value),
    }

def get_entity_data(config, start_time):
    start_time_str = start_time.format("2006-01-02T15:04:05Z")
    url = config.str("ha_instance") + "/api/history/period/" + start_time_str + "?filter_entity_id=" + config.str("ha_entity")
    headers = {
        "Authorization": "Bearer " + config.str("ha_token"),
        "Content-Type": "application/json",
    }

    rep = http.get(url, ttl_seconds = 240, headers = headers)
    if rep.status_code != 200:
        return None, rep.status_code

    data = rep.json()
    return (data[0], None) if data else ([], None)

def get_icon(config):
    icon = config.str("icon")
    return ICONS[icon] if icon in ICONS else ICONS["thermometer"]

def get_time_period(input_str):
    if not input_str.isdigit():
        return None
    time_period = int(input_str)
    if time_period < 2 or time_period > MAX_TIME_PERIOD:
        return None

    return time_period

def render_app(config, current_value, points, stats, unit):
    return render.Root(
        child = animation.Transformation(
            child = render.Row(
                children = [
                    render_graph_column(config, current_value, points, unit),
                    render_stats_column(stats, unit),
                ],
            ),
            width = 107,
            duration = 100,
            delay = 100,
            keyframes = [
                animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
                animation.Keyframe(curve = "ease_in", percentage = 0.2, transforms = [animation.Translate(-43, 0)]),
                animation.Keyframe(curve = "ease_in", percentage = 1.0, transforms = [animation.Translate(-43, 0)]),
            ],
        ),
    )

def render_graph_column(config, current_value, points, unit):
    return render.Column(
        children = [
            render.Box(
                child = render.Row(
                    children = [
                        render.Box(
                            child = render.Image(src = get_icon(config), width = 10, height = 10),
                            width = 12,
                            height = 12,
                        ),
                        render.Text(content = current_value + unit, font = "6x13"),
                    ],
                    expanded = True,
                    cross_align = "center",
                    main_align = "end",
                ),
                width = 64,
                height = 13,
            ),
            render.Plot(
                data = points,
                width = 64,
                height = 18,
                color = config.str("line_positive", "#FFA500"),
                color_inverted = config.str("line_negative", "#87CEFA"),
                fill = True,
            ),
        ],
    )

def render_stats_column(stats, unit):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(width = 1),
                    render.Box(color = "#525252", width = 1),
                    render.Box(width = 1),
                    render.Column(
                        children = [
                            render.Text(content = "Low " + stats["lowest_time"], font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["lowest_value"] + unit, font = "tom-thumb", color = "#b5a962"),
                            render.Text(content = "High " + stats["highest_time"], font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["highest_value"] + unit, font = "tom-thumb", color = "#b5a962"),
                            render.Text(content = "Average", font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["average"] + unit, font = "tom-thumb", color = "#b5a962"),
                        ],
                    ),
                ],
            ),
        ],
        expanded = True,
    )

def render_error_message(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(child = render.Image(src = ICONS["ha"], width = 15, height = 15), height = 15),
                render.WrappedText(
                    align = "center",
                    font = "tom-thumb",
                    content = message,
                    color = "#FF0000",
                    width = 64,
                ),
            ],
        ),
    )

def get_schema():
    icons = [
        schema.Option(
            display = "Thermometer",
            value = "thermometer",
        ),
        schema.Option(
            display = "Wind",
            value = "wind",
        ),
        schema.Option(
            display = "Home Assistant Icon",
            value = "ha",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_instance",
                desc = "Home Assistant URL. The address of your HomeAssistant instance, as a full URL.",
                icon = "globe",
                name = "Home Assistant URL",
            ),
            schema.Text(
                id = "ha_token",
                desc = "Home Assistant token. Navigate to User Settings > Long-lived access tokens.",
                icon = "key",
                name = "Home Assistant Token",
            ),
            schema.Text(
                id = "ha_entity",
                desc = "Entity name of the sensor to display, e.g. 'sensor.temperature'",
                icon = "ruler",
                name = "Entity name",
            ),
            schema.Text(
                id = "time_period",
                default = "24",
                desc = "In hours, how far back to look for data. Enter a number from 2 to " + str(MAX_TIME_PERIOD) + ".",
                icon = "timeline",
                name = "Time period",
            ),
            schema.Dropdown(
                id = "icon",
                default = icons[0].value,
                desc = "Icon to display for the entity",
                icon = "icons",
                name = "Icon",
                options = icons,
            ),
            schema.Color(
                id = "line_positive",
                default = "#FFA500",
                desc = "Colour of the graph line for positive values",
                icon = "chartLine",
                name = "Graph line for positive values",
            ),
            schema.Color(
                id = "line_negative",
                default = "#87CEFA",
                desc = "Colour of the graph line for negative values",
                icon = "chartLine",
                name = "Graph line for negative values",
            ),
        ],
    )
