"""
Applet: Todoist Routines
Summary: Today's remaining tasks
Description: Shows today's remaining tasks and subtasks as rows or columns of dots. Great for people with recurring routines of tasks with subtasks to see what's left to do today and whether they've forgotten something. Helps me manage my ADHD symptoms. Can you make the screen go blank?
Author: shannonmoeller
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""

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
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your location to determine when a new day begins.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "start_hour",
                name = "Start hour",
                desc = "The hour of the day to start showing today's tasks (0-23).",
                icon = "clock",
                default = "0",
            ),
        ],
    )

def main(config):
    background_color = config.str("background_color")
    background_photo = config.str("background_photo")

    stack = []

    if background_color:
        stack.append(render.Box(color = background_color))

    if background_photo:
        stack.append(render.Image(base64.decode(background_photo)))

    stack.append(get_task_dots(config))

    return render.Root(child = render.Stack(children = stack))

def get_task_dots(config):
    token = config.str("token")

    if not token:
        return render_message("Todoist\nAPI token\nrequired")

    task_layout = config.str("task_layout")
    task_color = config.str("task_color")
    subtask_color = config.str("subtask_color")
    padding_color = "#0000"

    location = json.decode(config.get("location", DEFAULT_LOCATION))
    current_hour = time.now().in_location(location["timezone"]).hour
    start_hour = int(config.str("start_hour", "0"))

    tasks = get_tasks(token, "filter=yesterday" if current_hour < start_hour else "filter=today")
    subtasks = to_grouped_index(get_tasks(token, "filter=subtask"), lambda task: task["parent_id"])

    nested_tasks = []

    for task in tasks:
        nested_tasks.append({
            "task": task,
            "subtasks": subtasks.get(task["id"], []),
        })

    render_tasks = render.Row if task_layout == "columns" else render.Column
    render_subtasks = render.Column if task_layout == "columns" else render.Row

    task_dots = [
        render.Box(width = 1, height = 1, color = padding_color),
    ]

    for task in nested_tasks:
        subtask_dots = [
            render.Box(width = 1, height = 1, color = task_color),
            render.Box(width = 1, height = 1, color = padding_color),
        ]

        for _subtask in task["subtasks"]:
            subtask_dots.append(render.Box(width = 1, height = 1, color = subtask_color))

        task_dots.append(render_subtasks(children = subtask_dots))
        task_dots.append(render.Box(width = 1, height = 1, color = padding_color))

    return render.Box(child = render_tasks(children = task_dots))

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
    return render.Box(color = "#000", child = render.WrappedText(message, color = "#FFF"))
