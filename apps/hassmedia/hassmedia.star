load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

PLACEHOLDER_DATA = {
    "entity_id": "media_player.spotify",
    "state": "playing",
    "attributes": {
        "media_title": "blown a wish",
        "media_artist": "my bloody valentine",
        "media_album_name": "loveless",
    },
}

ICONS = {
    "ha": base64.decode("""
PHN2ZyB3aWR0aD0iMjQwIiBoZWlnaHQ9IjI0MCIgdmlld0JveD0iMCAwIDI0MCAyNDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxwYXRoIGQ9Ik0yNDAgMjI0Ljc2MkMyNDAgMjMzLjAxMiAyMzMuMjUgMjM5Ljc2MiAyMjUgMjM5Ljc2MkgxNUM2Ljc1IDIzOS43NjIgMCAyMzMuMDEyIDAgMjI0Ljc2MlYxMzQuNzYyQzAgMTI2LjUxMiA0Ljc3IDExNC45OTMgMTAuNjEgMTA5LjE1M0wxMDkuMzkgMTAuMzcyNUMxMTUuMjIgNC41NDI1IDEyNC43NyA0LjU0MjUgMTMwLjYgMTAuMzcyNUwyMjkuMzkgMTA5LjE2MkMyMzUuMjIgMTE0Ljk5MiAyNDAgMTI2LjUyMiAyNDAgMTM0Ljc3MlYyMjQuNzcyVjIyNC43NjJaIiBmaWxsPSIjRjJGNEY5Ii8+CjxwYXRoIGQ9Ik0yMjkuMzkgMTA5LjE1M0wxMzAuNjEgMTAuMzcyNUMxMjQuNzggNC41NDI1IDExNS4yMyA0LjU0MjUgMTA5LjQgMTAuMzcyNUwxMC42MSAxMDkuMTUzQzQuNzggMTE0Ljk4MyAwIDEyNi41MTIgMCAxMzQuNzYyVjIyNC43NjJDMCAyMzMuMDEyIDYuNzUgMjM5Ljc2MiAxNSAyMzkuNzYySDEwNy4yN0w2Ni42NCAxOTkuMTMyQzY0LjU1IDE5OS44NTIgNjIuMzIgMjAwLjI2MiA2MCAyMDAuMjYyQzQ4LjcgMjAwLjI2MiAzOS41IDE5MS4wNjIgMzkuNSAxNzkuNzYyQzM5LjUgMTY4LjQ2MiA0OC43IDE1OS4yNjIgNjAgMTU5LjI2MkM3MS4zIDE1OS4yNjIgODAuNSAxNjguNDYyIDgwLjUgMTc5Ljc2MkM4MC41IDE4Mi4wOTIgODAuMDkgMTg0LjMyMiA3OS4zNyAxODYuNDEyTDExMSAyMTguMDQyVjEwMi4xNjJDMTA0LjIgOTguODIyNSA5OS41IDkxLjg0MjUgOTkuNSA4My43NzI1Qzk5LjUgNzIuNDcyNSAxMDguNyA2My4yNzI1IDEyMCA2My4yNzI1QzEzMS4zIDYzLjI3MjUgMTQwLjUgNzIuNDcyNSAxNDAuNSA4My43NzI1QzE0MC41IDkxLjg0MjUgMTM1LjggOTguODIyNSAxMjkgMTAyLjE2MlYxODMuNDMyTDE2MC40NiAxNTEuOTcyQzE1OS44NCAxNTAuMDEyIDE1OS41IDE0Ny45MzIgMTU5LjUgMTQ1Ljc3MkMxNTkuNSAxMzQuNDcyIDE2OC43IDEyNS4yNzIgMTgwIDEyNS4yNzJDMTkxLjMgMTI1LjI3MiAyMDAuNSAxMzQuNDcyIDIwMC41IDE0NS43NzJDMjAwLjUgMTU3LjA3MiAxOTEuMyAxNjYuMjcyIDE4MCAxNjYuMjcyQzE3Ny41IDE2Ni4yNzIgMTc1LjEyIDE2NS44MDIgMTcyLjkxIDE2NC45ODJMMTI5IDIwOC44OTJWMjM5Ljc3MkgyMjVDMjMzLjI1IDIzOS43NzIgMjQwIDIzMy4wMjIgMjQwIDIyNC43NzJWMTM0Ljc3MkMyNDAgMTI2LjUyMiAyMzUuMjMgMTE1LjAwMiAyMjkuMzkgMTA5LjE2MlYxMDkuMTUzWiIgZmlsbD0iIzE4QkNGMiIvPgo8L3N2Zz4K
"""),
    "spotify": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAMAAABhEH5lAAAAIGNIUk0AAHomAACAhAAA+gAAAIDo
AAB1MAAA6mAAADqYAAAXcJy6UTwAAAJ8UExURQAAABfYYBjYYQDYNBDSXRnaYhjZYRjZYhjYYhnZ
YRjYYz3sdBjYXRj/fx39cQYAADr/7iP/oQtVKAMIBCr/uR7/mAkuEgcyFR//fRv0bQoUChjYYhja
YhjYYRjZYBfZYBjYYRjZYBnaYBnYYhbYXxjYYRfYYRfYYBfYYBfYYBjYYRnaYRjaYRnaYhfYYBfY
YBfYYBjYYRnXZBnZYRfYYBfYYRfYYhjaYhfZYRfYYRfYYhfWXxfbYRfYYBjWYBfYYBfaYRfbYRjW
YBfYYRfcYhjYYBjZYRjXYBfVXxfYYBfSXhbHWRXBVxSzURfVXxfTXhi5VRWzUhbJWhbGWROuThKN
QRbJWhbLWhKYQw+BOhXHWBfWXxbHWBCAORCQPxOtTRbKWxfXYBfXYBfXYBfXYBbIWhKoSxGVQgc+
HhKjSRCFPRCPQBKlShOkShGNPxGJPRKjSQAAABfYYBfZYBfbYRfdYhfeYxfeYhfcYhfaYRfSXRaq
TRWHPxV6ORR3OBV4ORWBPBaaRhbBVxfZYRa0URRQKBMwGxITDxIICxIGChIHChIODRMiFhNEIxRa
LBV5ORbDVxa5UxRiLxVxNhaWRRabRxWZRxWJQBRTKhIUEBIVEBM5HxatTxfWXxfJWhfGWRe5Uxac
RxWQQxWdSBa8VBfOXBazURWKQBM2HhagSRWTRBMrGRMpGBMuGxM6IBWNQRfIWhfCVxfRXRavTxWN
Qha/VhfIWRfHWRa+VhM+IRMmFxNAIhasThapTRakSxWYRhWQQhWWRRauTxRyNhayURamSxRLJhNI
JRNKJhNLJhM8IBRPKBadSBfVXxa6UxRtNBVuNRa7VBfXYP///8Pj+cQAAABydFJOUwAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAABM9pvH+7ps1EQU2rfz++qIqAwVZ3MxGAzreyygUsqARRP35MLP8
+4v2/uL48+X9x4ZjK+3gIg2KdgkYqJ4UH6D6lxkXYcr5+vv4wVYTBSA+ZYWDYDsdAzpjJq4AAAAB
YktHRNOX354mAAAAB3RJTUUH6QIWAC0s4N+NxQAAAUtJREFUGNNjYGBkYpaWkZWTl1dQVFJmYWVj
YGBjU1FVU1cvKirSUNfU0tZh52Dg1NXTL4IDA0MjLgZuY5PiktKysrLyikqgmKkZD4O5RWVVdU1t
XX1DY1NFaXORpRWDtU1La1t7R2dXd09vX/+EEls7BnuHiZMmT5k6deq06TNmzpo9x9GJwblo7rz5
CxYuWrxkadOy5StWurgyFBVVrFrdtnrN6ra169Zv2Lip2I1Bvqhk85at27Zv3zF9567deyqK3Bk8
NJq37923/8DBfdVbDx0+UuLpxeCtXnH02PETJ08cP3X6zLziInUfBl+/orlnSyoqKkrOnb9wsbLI
P4AhMKgY6pnKikogMziEgTc0rBjhx+LwCD4GfoHIqEswkeiYWEEGBiFhkbj4hMSk5OSklNS0dFEG
MQYGcQaJjMys7JzcvPyCQkkGKQYAf6OGXhCsTzcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDIt
MjJUMDA6NDU6MDErMDA6MDCQupEVAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTAyLTIyVDAwOjQz
OjI0KzAwOjAw/ORxNAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNS0wMi0yMlQwMDo0NTo0NCsw
MDowMGCAKSsAAAAASUVORK5CYII=
"""),
}

def main(config):
    if not config.str("ha_instance") or not config.str("ha_entity") or not config.str("ha_token"):
        print("Using placeholder data, please configure the app")
        data = PLACEHOLDER_DATA
        error = None
    else:
        data, error = get_entity_data(config)

    if data == None:
        return render_error_message("Error: received status " + str(error))

    if data["state"] == "playing":
        return render_app(config, data)
    else:
        return []

def get_entity_data(config):
    url = config.str("ha_instance") + "/api/states/" + config.str("ha_entity")
    headers = {
        "Authorization": "Bearer " + config.str("ha_token"),
        "Content-Type": "application/json",
    }

    rep = http.get(url, ttl_seconds = 10, headers = headers)
    if rep.status_code != 200:
        return None, rep.status_code

    data = rep.json()
    return (data, None) if data else ({}, None)

def get_image(url, config):
    url = config.str("ha_instance") + url
    headers = {
        "Authorization": "Bearer " + config.str("ha_token"),
        "Content-Type": "application/json",
    }

    rep = http.get(url, ttl_seconds = 240, headers = headers)
    if rep.status_code != 200:
        return None, rep.status_code

    return base64.encode(rep.body()), None

def render_app(config, data):
    if "entity_picture" in data.get("attributes", {}):
        image_url = data["attributes"]["entity_picture"]
        image, _ = get_image(image_url, config)
        image_element = render.Image(src = base64.decode(image), width = 20, height = 20)
    else:
        image_element = render.Image(src = ICONS["spotify"], width = 17, height = 17)

    return render.Root(
        render.Row(
            children = [
                render.Column(
                    children = [
                        render.Padding(
                            child = image_element,
                            pad = (0, 0, 1, 0),
                        ),
                    ],
                    expanded = True,
                    main_align = "center",
                ),
                render.Column(
                    children = [
                        render.Marquee(
                            align = "start",
                            child = render.Text(content = data["attributes"]["media_title"], font = "tb-8"),
                            width = 46,
                        ),
                        render.Marquee(
                            align = "start",
                            child = render.Text(color = "#1d9e03", content = data["attributes"]["media_artist"], font = "tb-8"),
                            width = 46,
                        ),
                        render.Marquee(
                            align = "start",
                            child = render.Text(color = "#8905da", content = data["attributes"]["media_album_name"], font = "tb-8"),
                            width = 46,
                        ),
                    ],
                    expanded = True,
                    main_align = "center",
                ),
            ],
        ),
    )

def render_error_message(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(child = render.Image(src = ICONS["ha"], width = 15, height = 15), height = 15),
                render.WrappedText(
                    align = "center",
                    font = "tom-thumb",
                    content = message,
                    color = "#FF0000",
                    width = 64,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_instance",
                desc = "Home Assistant URL. The address of your HomeAssistant instance, as a full URL.",
                icon = "globe",
                name = "Home Assistant URL",
            ),
            schema.Text(
                id = "ha_token",
                desc = "Home Assistant token. Navigate to User Settings > Long-lived access tokens.",
                icon = "key",
                name = "Home Assistant Token",
            ),
            schema.Text(
                id = "ha_entity",
                desc = "Entity name of the Spotify media player e.g. 'media_player.spotify'.",
                icon = "ruler",
                name = "Entity name",
            ),
        ],
    )
