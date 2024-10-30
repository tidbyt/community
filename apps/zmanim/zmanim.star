load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_ZIP = "11367"

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
    "Candle Lighting": "Candle Lighting",          # Entry for Candle Lighting
    "Shabbat Ends": "Shabbat Ends",                # Entry for Shabbat Ends
    "Candle Lighting after": "Candle Lighting after",  # Entry for Candle Lighting after
    "Holiday Ends": "Holiday Ends"                 # Entry for Holiday Ends
}


def get_url(zip_code):
    return "https://www.chabad.org/tools/rss/zmanim.xml?locationid=" + zip_code + "&locationtype=2"

def clean_title(title):
    original = title.split(" - ")[0].split(" (")[0]
    for display_name, match_text in ZMANIM_MAP.items():
        if original.startswith(match_text):
            return display_name
    return original

def clean_time(time):
    return time.split(" - ")[1].split(" --")[0].strip()

def get_current_date():
    """Fetches the current date from an external API in 'Wed Oct 30' format."""
    date_response = http.get("http://worldtimeapi.org/api/timezone/Etc/UTC")
    if date_response.status_code == 200:
        date_data = date_response.json()
        datetime_str = date_data["datetime"]
        
        # Parse date in "YYYY-MM-DD" format
        date_str = datetime_str.split("T")[0]
        year, month, day = date_str.split("-")
        
        # Convert month and day_of_week to integers to avoid float issues
        month_index = int(month) - 1
        day_of_week_index = int(date_data["day_of_week"])
        
        months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        # Ensure that the values are integers
        month_str = months[month_index]
        day_of_week_str = days[day_of_week_index]
        
        return day_of_week_str + " " + month_str + " " + day
    else:
        return "Date Error"


def main(config):
    font = "tb-8"
    title_font = "tom-thumb"
    time_font = "CG-pixel-4x5-mono"
    zip_code = config.str("zip_code", DEFAULT_ZIP)

    # Get current date for static title
    current_date = get_current_date()

    rep = http.get(
        url=get_url(zip_code),
        ttl_seconds=14400,
        headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
        },
    )
    if rep.status_code != 200:
        display_rows = [
            render.Text("Error", font=title_font),
            render.Text("getting", font=title_font),
            render.Text("data!", font=title_font),
        ]
    else:
        body = rep.body()
        items = body.split("<item>")[1:]
        display_rows = [
            render.Text(current_date, font=title_font, color="#ff0"),  # Date in yellow
            render.Box(height=4)  # Spacing after date
        ]
        first = True
        for item in items:
            title_start = item.find("<title>") + 7
            title_end = item.find("</title>")
            if title_start > 6 and title_end > 0:
                full_title = item[title_start:title_end].strip()
                original_title = full_title.split(" - ")[0]
                for match_text in ZMANIM_MAP.values():
                    if original_title.startswith(match_text):
                        time = clean_time(full_title)
                        row_children = [
                            render.Text(
                                content=clean_title(full_title) + ":",
                                font=title_font,
                            ),
                            render.Box(height=1),
                            render.Text(
                                content=time,
                                font=time_font,
                                color="#ff0",
                            ),
                        ]
                        if not first:
                            row_children.insert(0, render.Box(height=4, width=1))
                        display_rows.append(render.Column(children=row_children))
                        first = False
                        break

    times_display = render.Marquee(
        height=32,
        scroll_direction="vertical",
        child=render.Column(children=display_rows),
        offset_start=32,
        offset_end=32,
    )

    return render.Root(
        delay=int(config.str("speed", "30")),
        show_full_animation=True,
        child=render.Row(
            expanded=True,
            children=[
                render.Column(
                    main_align="space_evenly",
                    expanded=True,
                    children=[
                        render.Text("Z", font=font, color="#00a"),
                        render.Text("T", font=font, color="#00a"),
                    ],
                ),
                times_display,
            ],
        ),
    )


def get_schema():
    scroll_speed = [
        schema.Option(display="Slower", value="100"),
        schema.Option(display="Slow", value="70"),
        schema.Option(display="Normal", value="50"),
        schema.Option(display="Fast (Default)", value="30"),
    ]
    return schema.Schema(
        version="1",
        fields=[
            schema.Text(
                id="zip_code",
                name="ZIP Code",
                desc="Enter your ZIP code for local zmanim",
                icon="locationDot",
                default=DEFAULT_ZIP,
            ),
            schema.Dropdown(
                id="speed",
                name="Scroll Speed",
                desc="Change the speed that text scrolls.",
                icon="gear",
                default=scroll_speed[-1].value,
                options=scroll_speed,
            ),
        ],
    )
