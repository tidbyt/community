# breadwinner.star
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("math.star", "math")
load("time.star", "time")
load("humanize.star", "humanize")

def main(config):
    # Get user and starter from config
    user_id = config.get("user_id", "jefflac")
    starter_id = config.get("starter_id", "levain-james")
    
    # Fetch data from Breadwinner API
    url = "https://breadwinner.life/api/v3/%s/starters/%s/tidbyt" % (user_id, starter_id)
    print(url)
    res = http.get(url)
    if res.status_code != 200:
        return render.Root(
            child = render.Text("Error fetching data")
        )
    
    data = res.json()
    
    if "error" in data:
        return render.Root(
            child = render.Text(data["starter_name"] + "\nNo data")
        )
    
    # Create height graph points
    heights = [p["height"] for p in data["points"]]
    if heights:
        max_height = max(heights)
        min_height = min(heights)
        # Scale heights to fit in 20 pixels
        scaled_heights = [int(((h - min_height) / (max_height - min_height)) * 20) if h else 0 for h in heights]
    else:
        scaled_heights = []
    
    # Create graph points
    points = []
    for i, height in enumerate(scaled_heights):
        points.append((i, height))  # Plot height directly for correct orientation

    # Convert and format time
    fed_time = time.parse_time(data["fed_at"])
    now = time.now().in_location("America/New_York")
    relative_time = humanize.relative_time(fed_time, now)
    
    # Format temperature to one decimal place using math.round
    temp_text = "%s°" % (math.round(data["temperature"] * 10) / 10)
    
    # Combine name and feeding time for marquee
    status_text = "%s Fed %s ago" % (data["starter_name"], relative_time.strip())

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                # Graph section with temperature overlay
                render.Box(
                    height = 24,
                    child = render.Stack(
                        children = [
                            render.Plot(
                                data = points,
                                width = 64,
                                height = 24,
                                color = "#00ff00",
                            ),
                            # Temperature display in top right
                            render.Padding(
                                pad = (2, 0, 0, 0),  # Minimal left padding
                                child = render.Text(
                                    content = temp_text,
                                    font = "tom-thumb",
                                    color = "#ffff00"  # Yellow text like NYC air quality
                                ),
                            ),
                        ],
                    ),
                ),
                # Scrolling status bar
                render.Box(
                    height = 8,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = status_text,
                            font = "tom-thumb"
                        ),
                        offset_start = 32,
                        offset_end = 32,
                    ),
                ),
            ]
        )
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "starter_id",
                name = "Starter Name",
                desc = "Name of the Breadwinner starter.",
                icon = "locationDot",
                default = "levain-james"
            ),
            schema.Text(
                id = "user_id",
                name = "Breadwinner ID",
                desc = "Breadwinner User ID.",
                icon = "calendar",
                default = "jefflac",
            ),
        ],
    )