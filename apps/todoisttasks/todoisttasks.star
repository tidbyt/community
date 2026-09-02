"""
Applet: Todoist Tasks
Summary: Integrates with Todoist
Description: Shows up to 3 tasks on your To-Do list, sorted by priority. Use the filter option to further sort your tasks by using parameters such as 'today', tomorrow', 'overdue' etc.
Author: Based on zephyern's code, rewritten by ChatGTP4 with directions from Noste. I have no idea how code works.
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

DEFAULT_FILTER = "today | overdue"
DEFAULT_SHOW_IF_EMPTY = True

NO_TASKS_CONTENT = "No Tasks :)"

TODOIST_URL = "https://api.todoist.com/api/v1/tasks/filter"
TODOIST_CACHE_VERSION = "api-v1-2026-09"

PRIORITY_COLORS = ["#9b9b9b", "#48a9e6", "#f8b43a", "#ed786c"]

OAUTH2_CLIENT_ID = secret.decrypt("AV6+xWcEQOfChp6DT4pbNdlJxTUzWzCkB+5yEIf8EP4/0PWuFsV+U1vNeV5LanJ12L/rnluXAeLQy9wki7zsxaOeeqGO1vLI47J1UR0um63dgzXTVj+Tdj9+m02XCPGWuhHE/oengWdSvjAVtfFW2qcUwMYFORNauBD1m7qH/fu4kzNWsnY=")
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcER6NHS+ZGzXEJ5a7JaRuCiTKmcifK5zlxUgjz3/HW0FkTq9LJSB+fsLPNjuOdnHQSfX3h5YPTcK7K7Onu1B2O3DV5F8T4edaIWTVg1FkMnfD7a4vrCXp74pxvwlvktrKQwjq9nsPGRw4MlKx/rBRKhfjadwx1xl0VKHMdH/dc2yQ=")

def priority_color(priority):
    priority = int(priority)
    if priority < 1 or priority > 4:
        priority = 1
    return PRIORITY_COLORS[priority - 1]

def fetch_model(token, filter):
    response = http.get(
        TODOIST_URL,
        headers = {"Authorization": "Bearer %s" % token},
        params = {
            "query": filter,
            "limit": "200",
        },
    )

    if response.status_code == 200:
        response_json = response.json()
        tasks = response_json.get("results") or []
        sorted_tasks = sorted(
            tasks,
            key = lambda task: task.get("priority") or 1,
            reverse = True,
        )
        display_tasks = []
        for task in sorted_tasks[:3]:
            display_tasks.append({
                "content": "%s" % task.get("content"),
                "priority": task.get("priority") or 1,
            })
        return {
            "status": "ok",
            "tasks": display_tasks,
        }

    if response.status_code == 204:
        return {
            "status": "ok",
            "tasks": [],
        }

    return {
        "status": "error",
        "tasks": [],
    }

def main(config):
    token = config.get("auth") or config.get("dev_api_key")
    model = None

    if token:
        filter = config.get("filter") or DEFAULT_FILTER
        cache_key = "%s/%s/%s" % (
            TODOIST_CACHE_VERSION,
            hash.sha256(token),
            hash.sha256(filter),
        )
        cached_model = cache.get(cache_key)
        if cached_model:
            model = json.decode(cached_model)
        else:
            model = fetch_model(token, filter)

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(cache_key, json.encode(model), ttl_seconds = 60)

    if not token:
        display_tasks = [{
            "content": "Please connect your Todoist account.",
            "priority": 1,
        }]
    elif model.get("status") == "error":
        display_tasks = [{
            "content": "Todoist API error",
            "priority": 1,
        }]
    elif not model.get("tasks"):
        if not config.bool("show"):
            # Don't display the app in the user's rotation.
            return []
        display_tasks = [{
            "content": NO_TASKS_CONTENT,
            "priority": 1,
        }]
    else:
        display_tasks = model["tasks"]

    children = []
    circle_children = []
    for task in display_tasks:
        children.append(render.Marquee(
            child = render.Text(content = task["content"]),
            offset_start = 2,
            width = 46,
        ))
        circle_children.append(render.Circle(
            diameter = 6,
            color = priority_color(task["priority"]),
            child = render.Circle(color = "#332726", diameter = 2),
        ))

    return render.Root(
        delay = 100,
        max_age = 86400,
        child = render.Box(
            width = 64,  # Set the width to match the screen width
            height = 31,  # Set the height to match the desired height of the content
            padding = -1,  # Align the content to the bottom
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Column(
                        expanded = True,
                        cross_align = "center",
                        main_align = "space_evenly",
                        children = circle_children,
                    ),
                    render.Column(
                        expanded = True,
                        cross_align = "center",
                        main_align = "space_evenly",
                        children = children,
                    ),
                ],
            ),
        ),
    )

def oauth_handler(params):
    params = json.decode(params)
    res = http.post(
        url = "https://api.todoist.com/oauth/access_token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            code = params["code"],
            client_id = OAUTH2_CLIENT_ID,
            client_secret = OAUTH2_CLIENT_SECRET,
            grant_type = "authorization_code",
            redirect_uri = params["redirect_uri"],
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Todoist",
                desc = "Connect your Todoist account.",
                icon = "squareCheck",
                handler = oauth_handler,
                client_id = OAUTH2_CLIENT_ID or "fake-client-id",
                authorization_endpoint = "https://app.todoist.com/oauth/authorize",
                scopes = [
                    "data:read",
                ],
            ),
            schema.Text(
                id = "filter",
                name = "Filter",
                desc = "Filter to apply to tasks.",
                icon = "filter",
                default = DEFAULT_FILTER,
            ),
            schema.Toggle(
                id = "show",
                name = "Show When No Tasks",
                desc = "Show this app when there are no tasks.",
                icon = "eye",
                default = DEFAULT_SHOW_IF_EMPTY,
            ),
        ],
    )
