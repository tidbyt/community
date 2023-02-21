"""
Applet: Todoist Next
Summary: Todoist next due/overdue
Description: Displays the next due or overdue task from todoist.
Author: alisdair(https://discuss.tidbyt.com/t/todoist-integration/502/5), Updated by: akeslo
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TODOIST_API_BASE_URL = "https://api.todoist.com/rest/v1"

TODOIST_API_TASKS_URL = TODOIST_API_BASE_URL + "/tasks?filter=(overdue|today)"

MODEL_KEY_TEXT = "text"
MODEL_KEY_DUE = "due"
MODEL_KEY_ZEN = False

CACHE_KEY_MODEL = "todoist_model"

# Load Icon as Base 64
ZEN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAAFAAAAACy3fD9AAADrElEQVQ4EY2UW2hcVRSGv33OmZNJZ9Imk6mpM2mmpG16UyqNWkmpSqEWb0+C1icFI0EDxTdFURAVFB+CSgWV4kPFpNRCKBRNDVWkBS1prKkBE5M0qbZNTJrJZdJJ5rZde5KTaWy0Lljn7Mva/16Xf20FqAW1WLfOofQuP7ufjbBx77sEVjxOWnZvlCKZxCeaOH3oA4Z+muDc0VlZyYrmRLUBs0Utwrv8PN+0g8idb6FzFrZbg89ZnTcTg0WxZJRODZFJD2HZc/za9hKtbwwx0pWSnZwB87FhZzFPNd1HxcbnWFnyGMpXhbIC6EWYwsCs2XYpjhvDdtYTCFlU3XGZgfNxro8awNXF1H96NxWb6ikvfxpzz/+QoKOpKYW1keA9OeVPzoS3XuHcd3GHoF1MtPZtgsE65iQJDQU09UlhvGQkGdsZgWMPwaoizcPtlQdOpt3iHMlXLPYdqCabtsksOXLLSVpCT2RMCQRUacJWMsgTr1U71DW8iRvYcEuEGwyU4Dii83DwwhbNyly47nNVXyY0Ce3Le7dQgH8N0wMUGm2r0DxaBQGfWVQ8EFF0XAvE+DMQc27imXdwub+kZXtY8+oOeHK959+8YTojHqUVznLn8msLHntjS/hQWQLv79LsrZTiiWdLIeeRlgW0xbLMr/MhaQE2umYF4pnifgkPSeJyYAbyZkBpIEc41rBZ6BAzbWG8Ab94uK0Misxt/yEOpjdNv+Y7ESoCmvfuzfFITBnK/0O8PBRAtbhvqu668hEsi96OFhKTf3kxBH2KB6OWgBUOXZmBpi7Nyz9Cb9yAesD56PmyT3Gm+3Kf7jnbbNHceITZyRHPFWOayb8ZBcDhJBzsVnzUqeif8iy9v+LoALRd+KM3+0Vji8Vw77hspTwPc4I4ldLMSCvMGiqImLVpmSfnNGkz8UTCNXSZkP6/nmaWq93XpOWy5Yz1D1AadYnEahLizfFBxaEexWxWsft2TbnkZr/00ovbDQ8V7kJhsoK955Ti569bD8+deOcYo33DUrtcCSO/pcgkJ3HLdC5avWlaHolxeTYvjGumZLwnCiG/olzUgLX0w+ud8Jlc2nH8yOFE28GT/P79oDg+aWgjKZf6dH7VI5W25Z1zZV7Mmi2bR1X4NpOfIlvjEwaZYM3uD12XBtt/uTggKUlmv/nwWy6evSRbJrszJvMhUekBVgkDQ7j+ENW1UfZ//Axrt9YqoZQlVoslkvD1+fYT2ebGVuJXx0hNj8nZiQVN/A1hXkA63HVM/QAAAABJRU5ErkJggg==
""")

def dateStringToTime(dateString):
    return time.parse_time(dateString, "2006-01-02")

def renderDate(dateString):
    return dateStringToTime(dateString).format("Jan-02")

def isOverdue(date):
    current = time.now()
    currentDay = time.time(year = current.year, month = current.month, day = current.day)
    return date < currentDay

def main(config):
    # Download tasks

    TOKEN = config.get("TodoistAPIToken", "False")
    resp = http.get(TODOIST_API_TASKS_URL, headers = {"Authorization": "Bearer " + TOKEN})

    if resp.status_code == 200:
        parsed = resp.json()

        # Compute model to display
        model = None
        for task in parsed:
            due = dateStringToTime(task["due"]["date"])
            thisModel = {MODEL_KEY_TEXT: task["content"]}
            if isOverdue(due):
                thisModel.update([(MODEL_KEY_DUE, task["due"]["date"])])
            if model == None:
                model = thisModel
                continue
            if model.get(MODEL_KEY_DUE) == None:
                if thisModel.get(MODEL_KEY_DUE) != None:
                    model = thisModel
                    continue
            elif due < dateStringToTime(model[MODEL_KEY_DUE]):
                model = thisModel
                continue
        if model == None:
            model = {
                MODEL_KEY_TEXT: "Todoist Zero!",
                MODEL_KEY_ZEN: True,
            }

        # Render model
        HEADER = "#f00"
        CLR = "#fa0"
        if model.get(MODEL_KEY_ZEN) == True:
            CLR = "#fff"

        children = [
            render.WrappedText(
                content = model[MODEL_KEY_TEXT],
                color = CLR,
            ),
        ]

        if model.get(MODEL_KEY_DUE) != None:
            children.append(
                render.Text(
                    content = "Late: " + renderDate(model.get(MODEL_KEY_DUE)),
                    color = "#f00",
                    font = "CG-pixel-4x5-mono",
                ),
            )

        if model.get(MODEL_KEY_ZEN) == True:
            children.append(
                render.Image(src = ZEN_ICON),
            )
        else:
            children.insert(
                0,
                render.WrappedText(
                    content = "Todoist",
                    color = HEADER,
                ),
            )
    else:
        children = [
            render.WrappedText(
                content = "Config Error",
            ),
        ]

    return render.Root(
        render.Row(
            children = [render.Column(
                children = children,
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
            )],
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
        ),
        max_age = 600,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "TodoistAPIToken",
                name = "Todoist API Token",
                desc = "Enter Token",
                icon = "key",
            ),
        ],
    )
