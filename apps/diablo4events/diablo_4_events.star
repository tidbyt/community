"""
Applet: Diablo 4 Events
Summary: Tracks Diablo 4 events
Description: Shows an countdown when the next Diablo 4 event starts.
Author: devfle
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

season_start = time.parse_time("2023-10-17T23:00:00.00Z")
event_times = {
    "boss": 60 * 60 * 3.5,
    "helltide": 60 * 135,
    "legion": 60 * 25,
}

event_short_names = {
    "boss": "WB",
    "helltide": "HT",
    "legion": "LG",
}

def main(config):
    event_dict = {
        "boss": config.bool("boss", True),
        "helltide": config.bool("helltide", False),
        "legion": config.bool("legion", False),
    }

    for event_name, is_active in event_dict.items():
        if (is_active == False):
            event_dict.pop(event_name)
            continue

        event_dict[event_name] = getNextEvent(event_times[event_name])

    next_event = {
        "time": "none",
        "icon": "",
    }

    display_content = []

    if (len(event_dict) > 0):
        next_event_key = min(event_dict, key = event_dict.get)
        next_event["time"] = create_countdown_from_unix(event_dict[next_event_key])
        next_event["icon"] = event_short_names[next_event_key]
        display_content.insert(0, render.Box(color = "#900", width = 14, height = 13, child = render.Text(content = next_event["icon"], font = "6x13")))

    display_content.append(render.Box(width = 34, height = 13, child = render.Text(content = next_event["time"], font = "6x13")))

    return render.Root(
        child = render.Box(
            child = render.Row(
                expanded = True,
                cross_align = "center",
                main_align = "center",
                children = display_content,
            ),
        ),
    )

def getNextEvent(event_interval, start_time = season_start.unix):
    event_time = start_time + event_interval
    current_time = time.now().in_location("UTC")

    if (event_time > current_time.unix):
        return int(event_time) - current_time.unix

    return getNextEvent(event_interval, event_time)

def format_countdown(hours, minutes):
    hours = str(hours if hours > 9 else "0" + str(hours))
    minutes = str(minutes if minutes > 9 else "0" + str(minutes))

    return "{0}:{1}".format(hours, minutes)

def create_countdown_from_unix(unix_time):
    hours_next_event = unix_time // 3600
    minutes_next_event = (unix_time % 3600) // 60
    return format_countdown(hours_next_event, minutes_next_event)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "boss",
                name = "World Boss Event",
                desc = "A toggle to display next world boss event.",
                icon = "crown",
                default = True,
            ),
            schema.Toggle(
                id = "helltide",
                name = "Helltide Event",
                desc = "A toggle to display next helltide event.",
                icon = "skull",
                default = False,
            ),
            schema.Toggle(
                id = "legion",
                name = "Legion Event",
                desc = "A toggle to display next legion event.",
                icon = "userGroup",
                default = False,
            ),
        ],
    )
