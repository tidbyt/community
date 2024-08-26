"""
Applet: Military News
Summary: Display Military News
Description: Displays Military News from Military.com.
Author: Robert Ison
"""

load("http.star", "http")  #HTTP Client
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")  #XPath Expressions to read XML RSS Feed

CACHE_TTL_SECONDS = 86400  #1 Day

BRANCH_OPTIONS = [
    schema.Option(value = "air-force", display = "Air Force"),
    schema.Option(value = "army", display = "Army"),
    schema.Option(value = "coast-guard", display = "Coast Guard"),
    schema.Option(value = "marine-corps", display = "Marines"),
    schema.Option(value = "navy", display = "Navy"),
    schema.Option(value = "space-force", display = "Space Force"),
    schema.Option(display = "All Branches", value = "military"),
]

SCROLL_SPEED_OPTIONS = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

BRANCHES = [
    "air-force",
    "army",
    "coast-guard",
    "marine-corps",
    "navy",
    "space-force",
    "military",
]

BRANCH_COLOR_PALETTE = [
    ["#002b80", "#d2af39", "#00338f", "#00369e", "#b6860a"],
    ["#dad3c1", "#746b5a", "#a39976", "#555346", "#555346"],
    ["#f2531b", "#223c70", "#bb5949", "#ffffff", "#ffffff"],
    ["#a77c29", "#004481", "#cc101f", "#ffd500", "#757575"],
    ["#022a3a", "#e8b00f", "#c6ccd0", "#0076a9", "#0076a9"],
    ["#014b8b", "#9ca09f", "#792330", "#0f263a", "#792330"],
]

def main(config):
    selected_branch = config.get("branch", BRANCH_OPTIONS[6].value)
    branch_index = BRANCHES.index(selected_branch)

    if branch_index == (len(BRANCHES) - 1):
        #Pick a random branch
        branch_index = randomize(0, len(BRANCHES) - 2)

    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return show_instructions_screen(BRANCH_COLOR_PALETTE[branch_index], int(config.get("scroll", 45)))

    #Pick a news feed based on the branch
    rss_feed_url = ("https://www.military.com/rss-feeds/content?keyword=%s&type=news" % BRANCHES[branch_index])

    xml_data = get_military_news(rss_feed_url)
    colors = BRANCH_COLOR_PALETTE[branch_index]
    if (xml_data == None):
        number_of_items = 0
    else:
        number_of_items = xml_data.count("<item>")

    if number_of_items == 0:
        return []
    else:
        header = BRANCH_OPTIONS[branch_index].display
        thirds = int(math.round(number_of_items / 3))
        item_group_points = [
            [1, 1 if thirds == 0 else thirds],
            [thirds + 1, 2 * thirds],
            [2 * thirds + 1, number_of_items],
        ]

        display_text_lines = []
        for i in range(len(item_group_points)):
            #print(item_group_points[i][1] >= item_group_points[i][0])
            if (item_group_points[i][1] >= item_group_points[i][0]):
                current_query = "//item[" + str(randomize(item_group_points[i][0], item_group_points[i][1])) + "]/title"

                #print(xpath.loads(xml_data).query(current_query))
                display_text_lines.append(xpath.loads(xml_data).query(current_query))
            else:
                display_text_lines.append("")

        return render.Root(
            render.Column(
                children = [
                    render.Marquee(
                        width = 64,
                        offset_start = 15,
                        child = render.Text(header, color = colors[4], font = "5x8"),
                    ),
                    render.Marquee(
                        width = 64,
                        offset_start = len(header) * 5,
                        child = render.Text(display_text_lines[0], color = colors[0], font = "5x8"),
                    ),
                    render.Marquee(
                        offset_start = len(display_text_lines[0]) * 5,
                        width = 64,
                        child = render.Text(display_text_lines[1], color = colors[1], font = "5x8"),
                    ),
                    render.Marquee(
                        offset_start = (len(display_text_lines[0]) + len(display_text_lines[2])) * 5,
                        width = 64,
                        child = render.Text(display_text_lines[2], color = colors[2], font = "5x8"),
                    ),
                ],
            ),
            show_full_animation = True,
            delay = int(config.get("scroll", 45)),
        )

def get_military_news(rss):
    url = rss
    res = http.get(
        url = url,
        headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36", "Accept": "text/html"},
        ttl_seconds = CACHE_TTL_SECONDS,
    )

    if res.status_code == 200:
        return res.body()
    else:
        return None

def show_instructions_screen(colors, delay):
    ##############################################################################################################################################################################################################################
    header = "Military News"
    instructions_1 = "Military.com hosts RSS feeds on Military specific news items from around the country. You select the branch of interest, or pick 'All Branches' to get news across all branches."
    instructions_2 = "The color display is based on the color palette of the branch of the news being presented. 3 random headlines will be presented at a time."
    instructions_3 = "To get more information on the artice titles presented, go to Military.com. "

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    offset_start = 15,
                    child = render.Text(header, color = colors[4], font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(header) * 5,
                    child = render.Text(instructions_1, color = colors[0]),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = colors[1]),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = colors[2]),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )

def randomize(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max + 1 - min) + min)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "instructions",
                name = "Show Instructions",
                desc = "",
                icon = "book",
                default = False,
            ),
            schema.Dropdown(
                id = "branch",
                name = "Branch",
                desc = "Military Branch",
                icon = "globe",
                options = BRANCH_OPTIONS,
                default = BRANCH_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = SCROLL_SPEED_OPTIONS,
                default = SCROLL_SPEED_OPTIONS[0].value,
            ),
        ],
    )
