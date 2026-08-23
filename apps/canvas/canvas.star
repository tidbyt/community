load("encoding/base64.star", "base64")
load("http.star", "http")

#Add in the needed code bases
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_CANVAS_BASE_URL = "https://canvas.instructure.com"
COURSES_CACHE_TTL_SECONDS = 3000
ASSIGNMENTS_CACHE_TTL_SECONDS = 300
DEFAULT_DUE_DATE_CUTOFF_DAYS = "8"
MAX_DUE_DATE_CUTOFF_DAYS = 365
PAGE_MIN_FRAME_COUNT = 60
FRAME_DELAY_MS = 50

#Code for the canvas logo
CanvasLogo = base64.decode(
    """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""",
)

#Method to make an event
def showEvent(event, page_label = ""):
    date_children = [
        render.Text(event[0][5:10], color = "#d52e3a", font = "5x8"),
    ]
    if page_label != "":
        date_children.append(render.Text(page_label, color = "#aaaaaa", font = "tom-thumb"))

    return render.Row(
        cross_align = "center",
        children = [
            render.Padding(
                pad = (2, 0, 2, 0),
                child = render.Image(src = CanvasLogo, width = 13),
            ),
            render.Column(
                children = [
                    render.Marquee(
                        width = 40,
                        child = render.Text(event[1]),
                    ),
                    render.Box(
                        width = 47,
                        height = 8,
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = date_children,
                        ),
                    ),
                ],
            ),
        ],
    )

#Show an error
def makeError(type):
    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Marquee(
                    width = 60,
                    scroll_direction = "horizontal",
                    offset_start = 10,
                    offset_end = 10,
                    child = render.Text(type),
                ),
            ],
        ),
    )

def normalize_base_url(base_url):
    base_url = base_url.strip().rstrip("/")
    if base_url == "":
        return DEFAULT_CANVAS_BASE_URL
    if not base_url.startswith("http://") and not base_url.startswith("https://"):
        return "https://" + base_url
    return base_url

def get_courses(api_token, base_url):
    response = http.get(
        base_url + "/api/v1/courses",
        headers = {"Authorization": "Bearer " + api_token},
        params = {
            "enrollment_state": "active",
            "per_page": "100",
        },
        ttl_seconds = COURSES_CACHE_TTL_SECONDS,
    )
    if response.status_code == 401:
        return [], "Invalid access token."
    if response.status_code != 200:
        return [], "Can not Connect to Canvas"

    data = response.json()
    if type(data) != "list":
        return [], "Invalid Canvas response"

    courses = []
    for course in data:
        if type(course) != "dict":
            continue
        course_id = course.get("id")
        if type(course_id) == "int" or type(course_id) == "float":
            courses.append(str(int(course_id)))
        elif type(course_id) == "string" and course_id != "":
            courses.append(course_id)
    return courses, 0

def get_remote_assignments(api_token, base_url, course_id, due_date_cutoff_hours):
    response = http.get(
        base_url + "/api/v1/courses/" + str(course_id) + "/assignments",
        headers = {"Authorization": "Bearer " + api_token},
        params = {
            "bucket": "future",
            "order_by": "due_at",
            "per_page": "100",
        },
        ttl_seconds = ASSIGNMENTS_CACHE_TTL_SECONDS,
    )
    if response.status_code == 401:
        return [], "Invalid access token."
    if response.status_code != 200:
        return [], "Can not Connect to Canvas"

    data = response.json()
    if type(data) != "list":
        return [], "Invalid Canvas response"

    assignments = []
    now = time.now()
    for assignment in data:
        if type(assignment) != "dict":
            continue

        due_at = assignment.get("due_at")
        if type(due_at) != "string" or due_at == "":
            continue

        due_time = time.parse_time(due_at)
        if due_time <= now or (due_time - now).hours > due_date_cutoff_hours:
            continue

        name = assignment.get("name")
        if type(name) != "string" or name == "":
            name = "Untitled Assignment"
        assignments.append((due_at, name))

    return assignments, 0

def get_events(api_token, base_url, course_id, due_date_cutoff_hours):
    return get_remote_assignments(api_token, base_url, course_id, due_date_cutoff_hours)

def get_due_date_cutoff_hours(config):
    cutoff_days = str(config.get("due_date_cutoff_days", DEFAULT_DUE_DATE_CUTOFF_DAYS)).strip()
    if not cutoff_days.isdigit() or int(cutoff_days) < 1:
        cutoff_days = DEFAULT_DUE_DATE_CUTOFF_DAYS
    return min(int(cutoff_days), MAX_DUE_DATE_CUTOFF_DAYS) * 24

def make_assignment_page(assignments, page_number, total_pages):
    page_label = "{}/{}".format(page_number, total_pages)
    children = [
        showEvent(assignments[0], page_label if len(assignments) == 1 else ""),
        render.Box(width = 100, height = 1, color = "#ffffff"),
    ]
    if len(assignments) == 2:
        children.append(showEvent(assignments[1], page_label))
    return render.Column(children = children)

def render_assignment_pages(assignments):
    assignments = sorted(assignments, key = lambda assignment: time.parse_time(assignment[0]).unix)
    total_pages = (len(assignments) + 1) // 2
    pages = [
        make_assignment_page(assignments[index:index + 2], index // 2 + 1, total_pages)
        for index in range(0, len(assignments), 2)
    ]

    if len(pages) == 1:
        return render.Root(child = pages[0])

    page_animations = [
        render.Animation(children = [page] * max(PAGE_MIN_FRAME_COUNT, page.frame_count()))
        for page in pages
    ]
    return render.Root(
        child = render.Sequence(children = page_animations),
        delay = FRAME_DELAY_MS,
        show_full_animation = True,
    )

def fake_events():
    first = ["2024-04-21T03:59:59Z", "Example Assigment #1"]
    second = ["2024-11-23T03:59:59Z", "Fake Homework #4"]
    return render_assignment_pages([first, second])

def main(config):
    api_token = config.get("msg", "")
    base_url = normalize_base_url(config.get("base_url", DEFAULT_CANVAS_BASE_URL))
    due_date_cutoff_hours = get_due_date_cutoff_hours(config)

    if api_token == "":
        return fake_events()

    classes, error_code = get_courses(api_token, base_url)

    if error_code != 0:
        return makeError(error_code)

    canvas_data = []
    for course in classes:
        event, error_code = get_events(api_token, base_url, course, due_date_cutoff_hours)
        if error_code != 0:
            return makeError(error_code)
        canvas_data = canvas_data + event

    if len(canvas_data) > 0:
        return render_assignment_pages(canvas_data)
    elif len(canvas_data) == 0:
        if config.bool("no_assigment", False):
            return None
        else:
            return makeError("No More Assignments")
    else:
        return makeError("There was an unknown problem")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "msg",
                name = "Canvas API key",
                desc = "",
                icon = "compress",
                default = "",
            ),
            schema.Text(
                id = "base_url",
                name = "Canvas URL",
                desc = "Your institution's Canvas URL",
                icon = "globe",
                default = DEFAULT_CANVAS_BASE_URL,
            ),
            schema.Text(
                id = "due_date_cutoff_days",
                name = "Due within (days)",
                desc = "Show assignments due within 1-365 days",
                icon = "calendar",
                default = DEFAULT_DUE_DATE_CUTOFF_DAYS,
            ),
            schema.Toggle(
                id = "no_assigment",
                name = "Show Nothing",
                desc = "Show nothing when there are no assignments",
                icon = "gear",
                default = False,
            ),
        ],
    )
