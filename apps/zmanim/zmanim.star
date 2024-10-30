load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_ZIP = "11367"

ZMANIM_MAP = dict(
    Dawn = "Dawn (Alot",
    Misheyakir = "Earliest Tallit",
    Sunrise = "Sunrise",
    Last_Shema = "Latest Shema",
    Last_Shach = "Latest Shacharit",
    Midday = "Midday",
    Mincha_Ged = "Earliest Mincha",
    Mincha_Ket = "Mincha Ketanah",
    Plag = "Plag Hamincha",
    Sunset = "Sunset",
    Nightfall = "Nightfall",
    Midnight = "Midnight",
    Candle_Lighting = "Candle Lighting",
    Shabbat_Ends = "Shabbat Ends",
    Candle_Lighting_after = "Candle Lighting after",
    Holiday_Ends = "Holiday Ends",
)

def get_url(zip_code):
    return "https://www.chabad.org/tools/rss/zmanim.xml?locationid=%s&locationtype=2" % zip_code

def clean_title(title):
    original = title.split(" - ")[0].split(" (")[0]
    for display_name, match_text in ZMANIM_MAP.items():
        if original.startswith(match_text):
            return display_name
    return original

def clean_time(zman_time):
    return zman_time.split(" - ")[1].split(" --")[0].strip()

def format_date(now):
    weekday = now.format("Monday")  # Get full weekday name
    month = now.format("January")  # Get full month name
    day = now.day

    days = {
        "Monday": "Mon",
        "Tuesday": "Tue",
        "Wednesday": "Wed",
        "Thursday": "Thu",
        "Friday": "Fri",
        "Saturday": "Sat",
        "Sunday": "Sun",
    }

    months = {
        "January": "Jan",
        "February": "Feb",
        "March": "Mar",
        "April": "Apr",
        "May": "May",
        "June": "Jun",
        "July": "Jul",
        "August": "Aug",
        "September": "Sep",
        "October": "Oct",
        "November": "Nov",
        "December": "Dec",
    }

    short_day = days[weekday]
    short_month = months[month]

    return "%s %s %d" % (short_day, short_month, day)

def create_zman_row(title, zman_time, title_font, time_font, first):
    row_children = [
        render.Text(content = clean_title(title) + ":", font = title_font),
        render.Box(height = 1),
        render.Text(content = zman_time, font = time_font, color = "#ff0"),
    ]

    if not first:
        row_children.insert(0, render.Box(height = 4, width = 1))

    return render.Column(children = row_children)

def main(config):
    font = "tb-8"
    title_font = "tom-thumb"
    time_font = "CG-pixel-4x5-mono"
    zip_code = config.str("zip_code", DEFAULT_ZIP)
    
    now = time.now()
    current_date = format_date(now)

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
        display_rows = [
            render.Box(height = 8),
            render.Text(current_date, font = title_font, color = "#ff0"),
            render.Box(height = 4),
        ]

        items = rep.body().split("<item>")[1:]
        first = True

        for item in items:
            title_start = item.find("<title>") + 7
            title_end = item.find("</title>")

            if title_start > 6 and title_end > 0:
                full_title = item[title_start:title_end].strip()
                original_title = full_title.split(" - ")[0]

                for match_text in ZMANIM_MAP.values():
                    if original_title.startswith(match_text):
                        zman_time = clean_time(full_title)
                        display_rows.append(create_zman_row(full_title, zman_time, title_font, time_font, first))
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
