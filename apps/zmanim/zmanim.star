"""
Zmanim app for Tidbyt displays Jewish prayer times.
Data provided by Chabad.org's Zmanim API.
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_ZIP = "11367"

# Maps the desired display name to the part of the title we'll match against
ZMANIM_MAP = {
    "Dawn": "Dawn (Alot",
    "Misheyakir": "Earliest Tallit",
    "Sunrise": "Sunrise",
    "Last Shema": "Latest Shema",
    "Last Shach": "Latest Shacharit",
    "Midday": "Midday",
    "Mincha Ged": "Earliest Mincha",
    "Mincha Ket": "Mincha Ketanah",
    "Plag": "Plag Hamincha",
    "Sunset": "Sunset",
    "Nightfall": "Nightfall",
    "Midnight": "Midnight",
}

def get_url(zip_code):
    """Creates the URL for the Chabad.org Zmanim API."""
    return "https://www.chabad.org/tools/rss/zmanim.xml?locationid=" + zip_code + "&locationtype=2"

def clean_title(title):
    """Extracts and maps the display title from the full title."""
    original = title.split(" - ")[0].split(" (")[0]
    for display_name, match_text in ZMANIM_MAP.items():
        if original.startswith(match_text):
            return display_name
    return original

def clean_time(time):
    """Extracts the time from the full time string."""
    return time.split(" - ")[1].split(" --")[0].strip()

def main(config):
    """Main function to create the Zmanim display."""
    font = "tb-8"  # Side font
    title_font = "tom-thumb"  # Clearer font for titles
    time_font = "CG-pixel-4x5-mono"  # Original font for times

    # Get zip code from config or use default
    zip_code = config.str("zip_code", DEFAULT_ZIP)

    # Get zmanim data
    rep = http.get(
        url = get_url(zip_code),
        ttl_seconds = 14400,
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
        },
    )

    if rep.status_code != 200:
        display_rows = [
            render.Text("Error", font = title_font),
            render.Text("getting", font = title_font),
            render.Text("data!", font = title_font),
        ]
    else:
        body = rep.body()
        items = body.split("<item>")[1:]

        # Parse items
        display_rows = []
        first = True
        for item in items:
            title_start = item.find("<title>") + 7
            title_end = item.find("</title>")
            if title_start > 6 and title_end > 0:
                full_title = item[title_start:title_end].strip()
                original_title = full_title.split(" - ")[0]

                # Check if this is one of our mapped zmanim
                for match_text in ZMANIM_MAP.values():
                    if original_title.startswith(match_text):
                        time = clean_time(full_title)
                        
                        row_children = [
                            render.Text(
                                content = clean_title(full_title) + ":",
                                font = title_font,
                            ),
                            render.Box(height = 1),  # Small space between title and time
                            render.Text(
                                content = time,
                                font = time_font,
                                color = "#ff0",
                            ),
                        ]

                        if not first:
                            row_children.insert(0, render.Box(height = 4, width = 1))

                        display_rows.append(render.Column(children = row_children))
                        first = False
                        break

    times_display = render.Marquee(
        height = 32,
        scroll_direction = "vertical",
        child = render.Column(children = display_rows),
        offset_start = 32,
        offset_end = 32,
    )

    return render.Root(
        delay = int(config.str("speed", "30")),
        show_full_animation = True,
        child = render.Row(
            expanded = True,
            children = [
                render.Column(
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Text("Z", font = font, color = "#00a"),
                        render.Text("T", font = font, color = "#00a"),
                    ],
                ),
                times_display,
            ],
        ),
    )

def get_schema():
    """Defines the configuration schema for the app."""
    scroll_speed = [
        schema.Option(display = "Slower", value = "100"),
        schema.Option(display = "Slow", value = "70"),
        schema.Option(display = "Normal", value = "50"),
        schema.Option(display = "Fast (Default)", value = "30"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "zip_code",
                name = "ZIP Code",
                desc = "Enter your ZIP code for local zmanim",
                icon = "locationDot",
                default = DEFAULT_ZIP,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Change the speed that text scrolls.",
                icon = "gear",
                default = scroll_speed[-1].value,
                options = scroll_speed,
            ),
        ],
    )
