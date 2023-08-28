"""
Applet: Todoist Routines
Summary: Today's remaining tasks
Description: Shows today's remaining tasks and subtasks as rows or columns of dots. Great for people with recurring routines of tasks with subtasks to see what's left to do today and whether they've forgotten something. Helps me manage my ADHD symptoms. Can you make the screen go blank?
Author: shannonmoeller
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "token",
                name = "Todoist API token",
                desc = "Todoist > Settings > Integrations > Developer > API token",
                icon = "key",
            ),
            schema.Dropdown(
                id = "task_layout",
                name = "Task layout",
                desc = "Whether to render as rows or columns.",
                icon = "grip",
                default = "rows",
                options = [
                    schema.Option(
                        display = "Rows",
                        value = "rows",
                    ),
                    schema.Option(
                        display = "Columns",
                        value = "columns",
                    ),
                ],
            ),
            schema.Color(
                id = "task_color",
                name = "Task color",
                desc = "The color of the task dots.",
                icon = "check",
                default = "#FFFFFF",
            ),
            schema.Color(
                id = "subtask_color",
                name = "Subtask color",
                desc = "The color of the subtask dots.",
                icon = "checkDouble",
                default = "#FF0000",
            ),
            schema.Color(
                id = "background_color",
                name = "Background color",
                desc = "The color of the background.",
                icon = "fillDrip",
                default = "#000000",
            ),
            schema.PhotoSelect(
                id = "background_photo",
                name = "Background photo",
                desc = "A background photo to display.",
                icon = "image",
            ),
        ],
    )

def main(config):
    stack = []

    background_color = config.str("background_color")
    if background_color:
        stack.append(render.Box(width = 64, height = 32, color = background_color))

    background_photo = config.str("background_photo")
    if background_photo:
        stack.append(render.Image(base64.decode(background_photo)))

    stack.append(get_task_dots(config))

    return render.Root(child = render.Stack(children = stack))

def get_task_dots(config):
    token = config.str("token")

    if not token:
        return render_message("Todoist API token required")

    tasks = get_tasks(token, "filter=today")
    subtasks = get_tasks(token, "filter=subtask")

    nested_tasks = []
    grouped_subtasks = to_grouped_index(subtasks, lambda task: task["parent_id"])

    for task in tasks:
        nested_tasks.append({
            "task": task,
            "subtasks": grouped_subtasks.get(task["id"], []),
        })

    render_tasks = render.Column
    render_subtasks = render.Row

    task_layout = config.str("task_layout")
    if task_layout == "columns":
        render_tasks = render.Row
        render_subtasks = render.Column

    task_dots = [
        render.Box(width = 1, height = 1, color = "#0000"),
    ]

    for task in nested_tasks:
        subtask_dots = [
            render.Box(width = 1, height = 1, color = config.str("task_color")),
            render.Box(width = 1, height = 1, color = "#0000"),
        ]

        for _subtask in task["subtasks"]:
            subtask_dots.append(render.Box(width = 1, height = 1, color = config.str("subtask_color")))

        task_dots.append(render_subtasks(children = subtask_dots))
        task_dots.append(render.Box(width = 1, height = 1, color = "#0000"))

    return render_subtasks(
        expanded = True,
        main_align = "center",
        children = [
            render_tasks(
                expanded = True,
                main_align = "center",
                children = task_dots,
            ),
        ],
    )

def get_tasks(token, params):
    response = http.get(
        "https://api.todoist.com/rest/v2/tasks?" + params,
        headers = {"Authorization": "Bearer " + token},
    )

    if response.status_code != 200:
        fail("Todoist request failed:", response.status_code, response.body())

    return response.json()

def to_grouped_index(items, get_key):
    index = {}

    for item in items:
        key = get_key(item)

        if key not in index:
            index[key] = []

        index[key].append(item)

    return index

def render_message(message):
    return render.Stack(
        children = [
            render.Box(width = 64, height = 32, color = "#000"),
            render.WrappedText(message, color = "#FFF"),
        ],
    )
