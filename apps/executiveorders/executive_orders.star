"""
Applet: Executive Orders
Summary: Latest executive order from Federal Register
Description: Shows the most recent executive order from the Federal Register with QR code link to full text.
Author: Anders Heie
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")


# Federal Register API endpoint for executive orders
FEDERAL_REGISTER_API = "https://www.federalregister.gov/api/v1/articles.json"
CACHE_TTL = 3600  # Cache for 1 hour
DEFAULT_COLOR = "#FFFFFF"
DEFAULT_SPEED = 45

def main(config):
    # Get configuration for randomization
    random_count = int(config.get("random_count", "5"))  # Default to 5 orders

    # Try to get cached data first
    cache_key = "executive_orders_%d" % random_count
    cached_data = cache.get(cache_key)

    orders = None
    if cached_data != None:
        print("Using cached executive orders data")
        orders = json.decode(cached_data)
    else:
        print("Fetching executive orders from Federal Register API")
        orders = fetch_executive_orders(random_count)
        if orders != None and len(orders) > 0:
            # Cache the successful response
            cache.set(cache_key, json.encode(orders), ttl_seconds = CACHE_TTL)
        else:
            # Return error display if API fails
            return render_error()

    # Ensure we have orders
    if orders == None or len(orders) == 0:
        return render_error()

    # Select a random order from the fetched orders
    # Use current time for pseudo-randomness in Starlark
    if len(orders) == 1:
        exec_order = orders[0]
    else:
        # Use time-based pseudo-randomness
        now = time.now()
        seed = int(now.unix) + int(now.nanosecond / 1000000)  # millisecond precision
        random_index = seed % len(orders)
        exec_order = orders[random_index]

    # Get configuration
    color = config.get("color", DEFAULT_COLOR)
    speed = int(config.get("speed", DEFAULT_SPEED))

    return render_display(exec_order, color, speed)

def fetch_executive_orders(count):
    """Fetch the most recent executive orders from Federal Register API"""

    # API parameters to get the latest executive orders
    params = {
        "conditions[presidential_document_type]": "executive_order",
        "order": "newest",
        "per_page": str(count),
    }

    response = http.get(FEDERAL_REGISTER_API, params = params)
    if response.status_code != 200:
        print("Federal Register API error: %d" % response.status_code)
        return None

    data = response.json()

    # Check if we got any results
    if not data.get("results") or len(data["results"]) == 0:
        print("No executive orders found in API response")
        return None

    # Extract all executive orders
    exec_orders = []
    for eo in data["results"]:
        exec_order = {
            "title": eo.get("title", "Executive Order"),
            "executive_order_number": eo.get("executive_order_number"),
            "document_number": eo.get("document_number"),
            "html_url": eo.get("html_url"),
            "pdf_url": eo.get("pdf_url"),
            "publication_date": eo.get("publication_date"),
            "signing_date": eo.get("signing_date"),
        }
        exec_orders.append(exec_order)

    print("Found %d executive orders" % len(exec_orders))
    return exec_orders

def render_display(exec_order, color, speed):
    """Render with seamless transition from static to scrolling"""

    title = exec_order["title"]
    signing_date = exec_order.get("signing_date", "")
    publication_date = exec_order.get("publication_date", "")

    # Use signing_date if available, otherwise publication_date
    date_to_format = signing_date if signing_date else publication_date

    # Format the date (assuming it comes in YYYY-MM-DD format)
    formatted_date = "No date"
    if date_to_format and len(str(date_to_format)) >= 10:
        # Convert YYYY-MM-DD to DD/MMM/YYYY
        parts = str(date_to_format).split("-")
        if len(parts) == 3:
            month_names = [
                "Jan",
                "Feb",
                "Mar",
                "Apr",
                "May",
                "Jun",
                "Jul",
                "Aug",
                "Sep",
                "Oct",
                "Nov",
                "Dec",
            ]
            month_num = int(parts[1]) - 1  # Convert to 0-based index
            if 0 <= month_num and month_num <= 11:
                formatted_date = "%s %s, %s" % (parts[2], month_names[month_num], parts[0])
            else:
                formatted_date = "%s/%s/%s" % (parts[2], parts[1], parts[0])
        else:
            formatted_date = str(date_to_format)

    # Create truly seamless patriotic line animation
    # Create multiple frames of the pattern shifting left
    patriotic_frames = []

    # Base pattern - red, white, blue repeating
    colors = ["#FF0000", "#FFFFFF", "#0000FF"]

    # Create 21 frames for smooth animation (7 pixels per color * 3 colors)
    for frame in range(21):
        frame_boxes = []
        for pixel in range(62):  # 62 pixels wide (64 - 2 for margins)
            color_index = (pixel + frame) // 7 % 3  # Each color is 7 pixels wide
            frame_boxes.append(render.Box(width = 1, height = 2, color = colors[color_index]))

        patriotic_frames.append(render.Row(children = frame_boxes))

    patriotic_line = render.Animation(children = patriotic_frames)

    # Create second identical patriotic line for bottom
    patriotic_line_bottom = render.Animation(children = patriotic_frames)

    # Horizontal scrolling title that starts from offscreen
    scrolling_title = render.Marquee(
        width = 62,  # 62 pixels wide (64 - 2 for margins)
        child = render.Text(
            content = title,
            color = color,
            font = "tb-8",
        ),
        offset_start = 62,  # Start completely offscreen to the right
        offset_end = 32,
        scroll_direction = "horizontal",
    )

    # Main display with 1 pixel margin all around
    return render.Root(
        delay = speed,  # Use configured speed for animations
        child = render.Padding(
            pad = (1, 1, 1, 1),  # 1 pixel margin on all sides
            child = render.Stack(
                children = [
                    # Executive Order header at top, centered
                    render.Box(
                        width = 62,
                        height = 6,
                        child = render.Row(
                            main_align = "center",
                            children = [
                                render.Text(
                                    content = "Executive Order",
                                    color = "#FFFFFF",
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ),
                    # Scrolling elements centered in middle
                    render.Padding(
                        pad = (0, 10, 0, 6),  # Push content down slightly
                        child = render.Column(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                patriotic_line,
                                scrolling_title,
                                patriotic_line_bottom,
                            ],
                        ),
                    ),
                    # Date centered at bottom, moved down 1 pixel
                    render.Padding(
                        pad = (0, 25, 0, 0),
                        child = render.Box(
                            width = 62,
                            height = 5,
                            child = render.Row(
                                main_align = "center",
                                children = [
                                    render.Text(
                                        content = formatted_date,
                                        color = "#00FF00",
                                        font = "tom-thumb",
                                    ),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        ),
    )

def render_error():
    """Render error display when API fails"""
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = "Unable to fetch latest executive order",
                color = "#FF0000",
                width = 64,
                font = "tb-8",
                align = "center",
            ),
        ),
    )

def get_schema():
    """Configuration schema for the app"""

    color_options = [
        schema.Option(
            display = "White",
            value = "#FFFFFF",
        ),
        schema.Option(
            display = "Blue",
            value = "#0099FF",
        ),
        schema.Option(
            display = "Green",
            value = "#00FF00",
        ),
        schema.Option(
            display = "Red",
            value = "#FF0000",
        ),
        schema.Option(
            display = "Yellow",
            value = "#FFFF00",
        ),
    ]

    speed_options = [
        schema.Option(
            display = "Slow",
            value = "60",
        ),
        schema.Option(
            display = "Medium",
            value = "45",
        ),
        schema.Option(
            display = "Fast",
            value = "30",
        ),
    ]

    random_options = [
        schema.Option(
            display = "Latest only (1)",
            value = "1",
        ),
        schema.Option(
            display = "Random from last 5",
            value = "5",
        ),
        schema.Option(
            display = "Random from last 10",
            value = "10",
        ),
        schema.Option(
            display = "Random from last 25",
            value = "25",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "random_count",
                name = "Order Selection",
                desc = "Show latest order or randomize from recent orders",
                icon = "dice",
                default = random_options[1].value,  # Default to "Random from last 5"
                options = random_options,
            ),
            schema.Dropdown(
                id = "color",
                name = "Text Color",
                desc = "Color of the executive order title text",
                icon = "palette",
                default = color_options[0].value,
                options = color_options,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Speed of text scrolling animation",
                icon = "gauge",
                default = speed_options[1].value,
                options = speed_options,
            ),
        ],
    )
