"""
Applet: Patterson Times
Summary: Patterson SkyTrain Times
Description: Displays next train times for Patterson SkyTrain station in Vancouver. More stations coming soon.
Author: Aiden Mitchell
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

API_URL = "https://gist.githubusercontent.com/aidenmitchell/95184f9d8a352908afc118b08a537d3f/raw"

EXPO_ICON = base64.decode("""
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""")

def fetch_train_data():
    r = http.get(API_URL)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def get_local_time():
    # Get the current UTC time
    utc_time = time.now()

    # Convert the UTC time into total minutes since midnight
    utc_minutes_since_midnight = utc_time.hour * 60 + utc_time.minute

    # Offset for PDT (UTC-7 hours)
    offset_minutes = -7 * 60

    # Calculate local minutes since midnight
    local_minutes_since_midnight = (utc_minutes_since_midnight + offset_minutes) % (24 * 60)

    # Convert the total minutes back to hours and minutes for the local time
    local_hour = local_minutes_since_midnight // 60
    local_minute = local_minutes_since_midnight % 60

    # Construct a new time object for local time
    local_time = time.time(hour = local_hour, minute = local_minute)

    return local_time

def format_time_difference(time_diff):
    """Format the time difference. If it's 0, return 'now'."""
    return "now" if time_diff == 0 else "{} min".format(time_diff)

def parse_time_to_minutes(time_str):
    """Convert a time string in the format 'HH:MM:SS' to minutes since midnight."""
    hours, minutes, _ = [int(part) for part in time_str.split(":")]
    return hours * 60 + minutes

def time_difference_in_minutes(start, end):
    """Calculate the time difference in minutes, accounting for times that cross over midnight."""
    if end >= start:
        return end - start
    else:
        # Account for times that cross over midnight
        return (24 * 60 - start) + end

def get_towards_waterfront_times(train_data):
    """Retrieve the two nearest train times towards Waterfront."""
    current_time_minutes = get_local_time().hour * 60 + get_local_time().minute
    towards_waterfront_times = sorted([t for t, dest in train_data.items() if dest == "Waterfront" and parse_time_to_minutes(t) > current_time_minutes])
    two_nearest_towards_waterfront = towards_waterfront_times[:2]
    towards_waterfront_diff = [time_difference_in_minutes(current_time_minutes, parse_time_to_minutes(t)) for t in two_nearest_towards_waterfront]

    return towards_waterfront_diff

def get_away_from_waterfront_times(train_data):
    """Retrieve the nearest "away from Waterfront" destination and its two nearest departure times."""
    current_time_minutes = get_local_time().hour * 60 + get_local_time().minute
    away_from_waterfront_times = sorted([t for t, dest in train_data.items() if dest != "Waterfront" and parse_time_to_minutes(t) > current_time_minutes])
    nearest_away_destination = train_data[away_from_waterfront_times[0]]
    two_nearest_away_times_for_nearest_destination = sorted([t for t, dest in train_data.items() if dest == nearest_away_destination and parse_time_to_minutes(t) > current_time_minutes])[:2]
    away_from_waterfront_diff = [time_difference_in_minutes(current_time_minutes, parse_time_to_minutes(t)) for t in two_nearest_away_times_for_nearest_destination]

    return nearest_away_destination, away_from_waterfront_diff

def render_train_times():
    train_data = fetch_train_data()
    if not train_data:
        return render.Text("Failed to fetch train data.")

    # Retrieve times
    towards_waterfront_diff = get_towards_waterfront_times(train_data)
    nearest_away_destination, away_from_waterfront_diff = get_away_from_waterfront_times(train_data)

    # Convert times to relative format
    waterfront_relative_times = [format_time_difference(diff) for diff in towards_waterfront_diff]
    kg_pwu_relative_times = [format_time_difference(diff) for diff in away_from_waterfront_diff]

    return render.Root(
        child = render.Column(
            children = [
                # First row for "Waterfront"
                render.Row(
                    children = [
                        # Column 1
                        render.Image(src = EXPO_ICON, width = 14),
                        # Column 2
                        render.Column(
                            children = [
                                render.Marquee(width = 64, child = render.Text("Waterfront", font = "CG-pixel-4x5-mono")),
                                render.Box(height = 1),
                                render.Marquee(width = 64 - 10, child = render.Text(",".join(waterfront_relative_times), font = "CG-pixel-4x5-mono", color = "#B84")),
                            ],
                        ),
                    ],
                ),
                # Padding of 8 pixels between rows
                render.Box(height = 4),
                # Second row for the nearest away destination
                render.Row(
                    children = [
                        # Column 3
                        render.Image(src = EXPO_ICON, width = 14),
                        # Column 4
                        render.Column(
                            children = [
                                render.Marquee(width = 64 - 10, child = render.Text(nearest_away_destination, font = "CG-pixel-4x5-mono")),
                                render.Box(height = 1),
                                render.Marquee(width = 64 - 10, child = render.Text(",".join(kg_pwu_relative_times), font = "CG-pixel-4x5-mono", color = "#B84")),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def main():
    return render_train_times()
