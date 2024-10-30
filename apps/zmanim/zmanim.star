def get_current_date():
    now = time.now()
    days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    dow = now.format("Monday")  # Get full day name
    if dow == "Monday":
        weekday = 1
    elif dow == "Tuesday":
        weekday = 2
    elif dow == "Wednesday":
        weekday = 3
    elif dow == "Thursday":
        weekday = 4
    elif dow == "Friday":
        weekday = 5
    elif dow == "Saturday":
        weekday = 6
    else:
        weekday = 0

    return "%s %s %d" % (
        days[weekday],
        months[now.month - 1],
        now.day,
    )

def create_zman_row(title, time, title_font, time_font, first):
    row_children = [
        render.Text(content = clean_title(title) + ":", font = title_font),
        render.Box(height = 1),
        render.Text(content = time, font = time_font, color = "#ff0"),
    ]

    if not first:
        row_children.insert(0, render.Box(height = 4, width = 1))

    return render.Column(children = row_children)

def main(config):
    font = "tb-8"
    title_font = "tom-thumb"
    time_font = "CG-pixel-4x5-mono"
    zip_code = config.str("zip_code", DEFAULT_ZIP)
    current_date = get_current_date()

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
                        time = clean_time(full_title)
                        display_rows.append(create_zman_row(full_title, time, title_font, time_font, first))
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
