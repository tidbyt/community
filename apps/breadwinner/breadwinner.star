# breadwinner.star
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("math.star", "math")
load("time.star", "time")
load("humanize.star", "humanize")

def get_height_color(height):
    # Return color based on height thresholds
    if height < 1.25:
        return "#ff0000"  # red
    elif height <= 2.0:
        return "#ffff00"  # yellow
    return "#00ff00"  # green

def main(config):
    # Get user and starter from config
    user_id = config.get("user_id", "fred")
    starter_id = config.get("starter_id", "breadberry")
    
    # Fetch data from Breadwinner API
    url = "https://breadwinner.life/api/v3/%s/starters/%s/tidbyt" % (user_id, starter_id)

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
    
    # Create height graph points and get max height
    heights = [p["height"] for p in data["points"]]
    max_height = max(heights) if heights else 0
    
    if heights:
        min_height = min(heights)
        # Scale heights to fit in 16 pixels to leave room for text and separator
        scaled_heights = [int(((h - min_height) / (max_height - min_height)) * 16) if h else 0 for h in heights]
    else:
        scaled_heights = []
    
    # Create graph points
    points = []
    for i, height in enumerate(scaled_heights):
        points.append((i, height))

    # Convert and format time
    fed_time = time.parse_time(data["fed_at"])
    now = time.now().in_location("America/New_York")
    relative_time = humanize.relative_time(fed_time, now)
    
    # Format temperature and max height
    temp_text = "%s°" % (math.round(data["temperature"] * 10) / 10)
    # Format max height to 2 decimal places using math.round
    max_height_text = "%sx" % (math.round(max_height * 100) / 100)
    
    # Get color for max height display
    height_color = get_height_color(max_height)
    
    # Combine name (capitalized) and feeding time for marquee
    status_text = "%s Fed %s ago" % (data["starter_name"].upper(), relative_time.strip())

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                # Graph section with temperature and max height overlay
                render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Column(
                            children = [
                                # Temperature and max height display at top
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    children = [
                                        render.Padding(
                                            pad = (2, 0, 0, 0),
                                            child = render.Text(
                                                content = temp_text,
                                                font = "tom-thumb",
                                            ),
                                        ),
                                        render.Padding(
                                            pad = (0, 0, 2, 0),
                                            child = render.Text(
                                                content = max_height_text,
                                                font = "tom-thumb",
                                                color = height_color
                                            ),
                                        ),
                                    ],
                                ),

                                # Graph below the separator
                                render.Box(
                                    height = 16,
                                    child = render.Plot(
                                        data = points,
                                        width = 64,
                                        height = 16,
                                        color = "#00ff00",
                                    ),
                                ),
                            ],
                        ),
                        # Scrolling status bar at bottom
                        render.Box(
                            height = 8,
                            child = render.Marquee(
                                width = 64,
                                child = render.Text(
                                    content = status_text,
                                    font = "tom-thumb",
                                    color = "#FFA500"
                                ),
                                offset_start = 32,
                                offset_end = 32,
                            ),
                        ),
                    ],
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
                default = "breadberry"
            ),
            schema.Text(
                id = "user_id",
                name = "Breadwinner ID",
                desc = "Breadwinner User ID.",
                icon = "calendar",
                default = "fred",
            ),
        ],
    )