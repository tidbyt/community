"""
Applet: Trello
Summary: List cards from Trello
Description: List cards from the column of a Trello board.
Author: remh
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("schema.star", "schema")

TRELLO_API_URL = "https://api.trello.com/1/lists/"

def main(config):
    # Download tasks
    url = TRELLO_API_URL + config.get("TrelloListId", "False") + "/cards?key=" + config.get("TrelloApiKey", "False") + "&token=" + config.get("TrelloApiToken", "False")
    resp = http.get(url)
    if resp.status_code == 200:
        parsed = resp.json()
        c = 0
        tasks = ""
        for task in parsed:
            tasks += task["name"] + "\n"
            c += 1
            if c == 3:
                break

        children = [
            render.WrappedText(
                content = tasks,
                color = "#fa0",
            ),
        ]

        children.insert(
            0,
            render.WrappedText(
                content = "Trello",
                color = "#f00",
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
                id = "TrelloApiKey",
                name = "Trello API Key",
                desc = "Enter key",
                icon = "key",
            ),
            schema.Text(
                id = "TrelloApiToken",
                name = "Trello API Token",
                desc = "Enter Token",
                icon = "key",
            ),
            schema.Text(
                id = "TrelloListId",
                name = "Trello List ID",
                desc = "Enter ID",
                icon = "key",
            ),
        ],
    )
