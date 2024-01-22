load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

OAUTH2_CLIENT_ID = secret.decrypt("AV6+xWcELnaSCpWCPDQA/KCTZ0CpXvc1NVJOUzH9lnt+Ia7LjFb0O4Y03u79TFSF9ypw/7nEpTf3iFwfIFPl4yJo1mj44ZAkjm/AEU+YPulBzmvdZidTGcABhs+axXGoixIkta30qpDW1UvrrQ0sP1dl34y4Z069sK4Ylk9GKMVb806Oj6QruXam15WjD8lBx4ZJb1GBUm4XsI3RNlvGjGAwEyVpAjBea7Q2e9XB")
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcEaSD7Pk37TTmkLE9xHWrlaG3FWEqX4wMUGzcMuPCTCc4TpR/NoN8DapxFXSc1dRe78zib8MbKZZ+rweDs4vvPZtml0CbC/wV+owR8n0iKdfHlwafu9qbfYu7ifOycnch3+AJr3ozyJGSi8XbV8OQs6AKYndSmlyID0KNV3gRcO0LO2z8=")
OAUTH2_TOKEN_URL = "https://oauth2.googleapis.com/token"
TASK_API_LISTS_URL = "https://www.googleapis.com/tasks/v1/users/@me/lists"
TASK_API_TASKS_URL = "https://tasks.googleapis.com/tasks/v1/lists"
DISPLAY_FONT = "CG-pixel-4x5-mono"
HEADERS = ["Due", " / ", "Tasks"]
HEADER_COLOR = "#3457D5"
MAX_PAST_DUE_DAY = -14
MAX_FUTURE_DAY = 7

TEST = False
TEST_CONFIG = dict(
    include_oversized_task = False,
    include_completed = True,
    include_future_task = True,
    include_past_due = True,
)

def main(config):
    auth = config.get("auth", None)
    task_list_name = config.get("task_list_name", None)
    task_colors = dict(
        overdue = config.get("overdue", "#E60808"),
        upcoming = config.get("upcoming", "#FAF593"),
        future = config.get("future", "#F9AEFD"),
        completed = config.get("completed", "#5AB808"),
    )
    task_render_options = dict(
        future = config.bool("show_future", True),
        completed = config.bool("show_completed", False),
        past_due = config.bool("show_past_due", True),
    )

    # Utilize special timezone variable
    timezone = config.get("$tz", "America/New_York")
    now = time.now().in_location(timezone)
    today = time.time(year = now.year, month = now.month, day = now.day, location = timezone)

    if TEST:
        tasks = get_mocked_data()
        filtered_tasks = filter_tasks(task_render_options, tasks, today)
    else:
        if auth == None:
            return render.Root(
                render.WrappedText("NEEDS AUTHENTICATION!"),
            )
        access_token = get_access_token(auth)
        task_list_id = get_task_list_id(access_token, task_list_name)
        if task_list_id == None:
            return get_applet_render(
                get_header(),
                render.WrappedText("NO TASK LIST WITH NAME: %s" % (task_list_name)),
            )

        tasks = get_tasks(access_token, task_list_id, task_render_options["completed"])
        filtered_tasks = filter_tasks(task_render_options, tasks, today)

    if len(filtered_tasks) == 0:
        return get_applet_render(get_header(), get_no_task_render())

    formatted_tasks = format_tasks(filtered_tasks, today, task_colors)

    return get_applet_render(get_header(), get_marquee(formatted_tasks))

def get_no_task_render():
    return render.WrappedText("NO TASKS DUE :)")

def get_applet_render(header_section, task_section):
    return render.Root(
        delay = 100,
        child = render.Column(
            children = [header_section, task_section],
            expanded = True,
        ),
    )

def get_header():
    return render.Row(
        children = [render.Text(header, color = HEADER_COLOR, font = DISPLAY_FONT) for header in HEADERS],
        main_align = "space_evenly",
        cross_align = "start",
        expanded = True,
    )

def get_marquee(tasks):
    text_height = get_max_text_height(tasks)

    days_until_due = []
    task_names = []
    for task in tasks:
        color = task["color"]
        days_until_due.append(render.WrappedText(task["due"], color = color, font = DISPLAY_FONT, height = text_height))
        task_names.append(render.WrappedText(task["title"], color = color, font = DISPLAY_FONT, height = text_height))

    return render.Marquee(
        scroll_direction = "vertical",
        height = 32,
        offset_start = 24,
        offset_end = 32,
        child = render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                render.Column(
                    children = days_until_due,
                ),
                render.Column(
                    cross_align = "end",
                    children = task_names,
                ),
            ],
        ),
    )

def get_max_text_height(tasks):
    max_len = max([task["title_length"] for task in tasks])

    if max_len == 30:
        return 17
    elif max_len <= 10:
        return 7
    else:
        return 12

def get_task_list_id(auth_token, task_list_name):
    task_list_id = cache.get("task_list_id")
    if not task_list_id:
        task_lists = make_request(TASK_API_LISTS_URL, auth_token)
        for tl in task_lists:
            if tl["title"] == task_list_name:
                cache.set("task_list_id", tl["title"], 300)
                return tl["id"]

    return task_list_id

def get_tasks(auth_token, task_list_id, show_completed):
    cached_tasks = cache.get("tasks")
    tasks = json.decode(cached_tasks) if cached_tasks else cached_tasks

    if not tasks:
        base_url = "%s/%s/tasks" % (TASK_API_TASKS_URL, task_list_id)
        params = "?showHidden=true&showCompleted=%s&maxResults=25" % (str(show_completed))
        url = base_url + params
        tasks = make_request(url, auth_token)
        cache.set("tasks", json.encode(tasks), 300)

    return tasks

def filter_tasks(task_render_options, tasks, today):
    past_due_day = MAX_PAST_DUE_DAY if task_render_options["past_due"] else 0
    future_day = MAX_FUTURE_DAY if task_render_options["future"] else 0
    filtered_tasks = []
    for task in tasks:
        date_diff = get_date_diff(task["due"], today)
        if date_diff >= past_due_day and date_diff <= future_day:
            filtered_tasks.append(task)

    return filtered_tasks

def get_date_diff(date_str, today):
    date_diff = time.parse_time(date_str) - today
    return math.ceil(date_diff.hours / 24)

def format_tasks(tasks, today, color_codes):
    formatted_tasks = [create_task_dict(task, today, color_codes) for task in tasks]
    return sorted(formatted_tasks, key = lambda x: x["due"])[:25]

def create_task_dict(task, today, color_codes):
    days_until_due = get_date_diff(task["due"], today)
    task_name = task["title"][:30]
    task_status = task["status"]
    color = get_color_code(days_until_due, color_codes, task_status)

    return dict(
        title = task_name,
        due = str(days_until_due),
        status = task_status,
        color = color,
        title_length = len(task_name),
    )

def get_color_code(days, color_codes, task_status):
    if task_status == "completed":
        return color_codes["completed"]
    elif days < 0:
        return color_codes["overdue"]
    elif days == 0:
        return "#FFFFFF"
    elif days <= 3:
        return color_codes["upcoming"]
    else:
        return color_codes["future"]

def make_request(url, auth_token):
    headers = {"Authorization": "Bearer %s" % (auth_token)}
    resp = http.get(url, headers = headers)

    if resp.status_code not in [200, 201]:
        fail("Request Failed: %d - %s" % (resp.status_code, resp.body()))

    return resp.json()["items"]

def get_customize_options(is_customized):
    custom_options = []
    if is_customized:
        for option_list in (get_custom_task_options(), get_custom_color_options()):
            for option in option_list:
                custom_options.append(option)

    return custom_options

def get_custom_color_options():
    return [
        schema.Color(
            id = "completed",
            name = "Completed Task Color",
            desc = "Color your completed tasks",
            icon = "brush",
            default = "#5AB808",
        ),
        schema.Color(
            id = "overdue",
            name = "Overdue Task Color",
            desc = "Color your overdue tasks",
            icon = "brush",
            default = "#E60808",
        ),
        schema.Color(
            id = "future",
            name = "Future Task Color",
            desc = "Color your future tasks",
            icon = "brush",
            default = "#F9AEFD",
        ),
        schema.Color(
            id = "upcoming",
            name = "Upcoming Task Color",
            desc = "Color your tasks due soon",
            icon = "brush",
            default = "#FAF593",
        ),
    ]

def get_custom_task_options():
    return [
        schema.Toggle(
            id = "show_completed",
            name = "Show Completed Tasks",
            desc = "Show tasks marked completed",
            icon = "gear",
            default = False,
        ),
        schema.Toggle(
            id = "show_past_due",
            name = "Show Tasks past due date",
            desc = "Show Tasks incomplete in the last 14 days",
            icon = "gear",
            default = True,
        ),
        schema.Toggle(
            id = "show_future",
            name = "Show Tasks due > 3 days",
            desc = "Show Tasks not due for more than 3 days (Max 7 days away)",
            icon = "gear",
            default = True,
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Google Tasks",
                desc = "Connect your Google account.",
                icon = "google",
                handler = oauth_handler,
                client_id = "%s&prompt=consent&access_type=offline" % (OAUTH2_CLIENT_ID),
                authorization_endpoint = "https://accounts.google.com/o/oauth2/v2/auth",
                scopes = ["https://www.googleapis.com/auth/tasks.readonly"],
            ),
            schema.Text(
                id = "task_list_name",
                name = "Task List Name:",
                desc = "Task list name to fetch tasks for",
                icon = "listCheck",
                default = "My Tasks",
            ),
            schema.Toggle(
                id = "is_customized",
                name = "Customize Display",
                desc = "Set custom render options",
                icon = "gear",
                default = False,
            ),
            schema.Generated(
                id = "custom_options",
                source = "is_customized",
                handler = get_customize_options,
            ),
        ],
    )

def oauth_handler(params):
    # deserialize oauth2 parameters, see example above.
    params = json.decode(params)
    print(params)
    request_body = dict(
        code = params["code"],
        client_id = OAUTH2_CLIENT_ID,
        redirect_uri = params["redirect_uri"],
        grant_type = params["grant_type"],
        client_secret = OAUTH2_CLIENT_SECRET,
    )
    token_params = make_oauth_token_call(request_body)
    print(token_params)

    return token_params["refresh_token"]

def make_oauth_token_call(request_body):
    resp = http.post(
        url = OAUTH2_TOKEN_URL,
        headers = {
            "Content-type": "application/x-www-form-urlencoded",
        },
        form_body = request_body,
    )
    if resp.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (resp.status_code, resp.body()))

    return resp.json()

def refresh_access_token(token):
    request_body = dict(
        client_id = OAUTH2_CLIENT_ID,
        client_secret = OAUTH2_CLIENT_SECRET,
        grant_type = "refresh_token",
        refresh_token = token,
    )
    token_params = make_oauth_token_call(request_body)
    cache.set("access_token", token_params["access_token"], ttl_seconds = 3540)

    return token_params["access_token"]

def get_access_token(token):
    access_token = cache.get("access_token")
    return access_token if access_token else refresh_access_token(token)

#  ---------Data for Testing---------------#
NOW = time.now()

def get_mocked_data():
    # initiate with basic tasks due in 0,1 days
    mock_tasks = [task for task in get_basic_tasks(range(0, 2))]

    # make tasks due in 5, 6 days
    if TEST_CONFIG["include_future_task"]:
        mock_tasks.extend(get_basic_tasks(range(5, 7)))

    if TEST_CONFIG["include_oversized_task"]:
        oversized_title = str("Task Item " * 2)[:30]
        mock_tasks.append(dict(title = oversized_title, due = get_mock_date(0), title_length = len(oversized_title), status = "needsAction"))

    if TEST_CONFIG["include_past_due"]:
        past_due_title = str("Past Due")[:30]
        mock_tasks.append(dict(title = past_due_title, due = get_mock_date(-1), title_length = len(past_due_title), status = "needsAction"))

    if TEST_CONFIG["include_completed"]:
        completed_title = str("Completed")[:30]
        mock_tasks.append(dict(title = completed_title, due = get_mock_date(0), title_length = len(completed_title), status = "completed"))

    return mock_tasks

def get_basic_tasks(day_range):
    tasks = []
    for i in day_range:
        title = "Task %s" % (str(i))[:30]
        tasks.append(dict(title = title, due = get_mock_date(i), title_length = len(title), status = "needsAction"))
    return tasks

def get_mock_date(day_adjustment):
    return "%s-%s-%sT00:00:00-00:00" % (
        str(NOW.year),
        str("0%s" % (NOW.month)) if NOW.month < 10 else str(NOW.month),
        str("0%s" % (NOW.day + day_adjustment)) if (NOW.day + day_adjustment) < 10 else str(NOW.day + day_adjustment),
    )
