load("html.star", "html")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

DUMMY_DATA = [
    ["Harry Potter and the Philosopher's Stone", "J.K. Rowling", "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1170803558l/72193.jpg", 0.6],
    ["A Game of Thrones", "George R.R. Martin", "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1562726234i/13496.jpg", 0.15],
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "user_id",
                name = "User ID",
                desc = "Navigate your Goodreads profile and get this from the URL",
                icon = "key",
            ),
        ],
    )

def request_data(user_id):
    challenge_page = http.get("https://www.goodreads.com/user/show/" + user_id, ttl_seconds = 1800)

    if challenge_page.status_code != 200:
        fail("Request failed with status %d", challenge_page.status_code)

    return challenge_page.body()

def parse_data(body):
    root = html(body)

    currently_reading_heading = None
    headings = root.find(".brownBackground").find("a")

    for i in range(headings.len()):
        heading = headings.eq(i)
        if ("is Currently Reading" in heading.text()):
            currently_reading_heading = heading
            break

    if not currently_reading_heading:
        fail("Unable to find currently reading section for user")

    section = currently_reading_heading.parent().parent().parent()
    titles = section.find(".bookTitle")
    authors = section.find(".authorName")
    progresses = section.find(".progressGraph")
    images = section.find(".firstcol").find("img")

    rows = []

    for i in range(titles.len()):
        title = titles.eq(i).text().strip()
        author = authors.eq(i).text().strip()
        image = images.eq(i).attr("src")
        progress_element = progresses.eq(i)

        if progress_element and progress_element.attr("style"):
            total_progress = int(re.findall(r"\d+", progress_element.attr("style"))[0])
            current_progress = int(re.findall(r"\d+", progress_element.find(".graphBar").attr("style"))[0])
            progress = current_progress / total_progress
        else:
            progress = None

        rows.append([title, author, image, progress])

    return rows

def render_row(row):
    title = row[0]

    author = row[1]

    progress = row[3]

    title_widget = render.Text(
        content = title,
    )

    author_widget = render.Text(
        content = author,
        color = "#8A8A8A",
    )

    title_animation = render.Padding(
        pad = (0, 0, 0, 1),
        child = render.Marquee(
            width = 46,
            child = title_widget,
            offset_start = 0,
            delay = 50,
        ),
    )

    author_animation = render.Padding(
        pad = (0, 0, 0, 1),
        child = render.Marquee(
            width = 46,
            offset_start = 0,
            child = author_widget,
            delay = 150,
        ),
    )

    children = [
        title_animation,
        author_animation,
    ]

    if progress:
        children.append(
            render.Stack(
                children = [
                    render.Box(
                        width = 46,
                        height = 6,
                        color = "#f4f1ea",
                    ),
                    render.Box(
                        width = int(46 * progress),
                        height = 6,
                        color = "#927f64",
                    ),
                ],
            ),
        )

    image_widget = render.Image(
        src = http.get(row[2], ttl_seconds = 86400).body(),
        height = 23,
        width = 15,
    )

    content_widget = render.Box(
        width = 46,
        child = render.Column(
            main_align = "start",
            children = children,
        ),
    )

    return render.Box(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                image_widget,
                content_widget,
            ],
        ),
    )

def main(config):
    USER_ID = config.str("user_id")

    if USER_ID:
        body = request_data(USER_ID)
        rows = parse_data(body)
    else:
        rows = DUMMY_DATA

    header = render.Box(
        height = 7,
        color = "#684a27",
        child = render.Text(
            content = "Now Reading",
            font = "CG-pixel-3x5-mono",
        ),
    )

    children = []

    for i in range(len(rows)):
        children.append(render_row(rows[i]))

    sequence = render.Sequence(children = children)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                header,
                sequence,
            ],
        ),
    )
