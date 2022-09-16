"""
Applet: Zoom Call Status
Summary: Show zoom call status
Description: Displays a live status based on whether the user is in a call or on Do Not Disturb. Please create a JWT based Zoom app (on the Zoom site) and add it in the settings to get started.
Author: CFitzsimons
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("encoding/base64.star", "base64")
load("cache.star", "cache")

CACHE_TTL = 15
PAGED_URL = "https://api.zoom.us/v2/contacts?page_size=100&query_presence_status=1"
RECORD_ICON = base64.decode("""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
""")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "email",
                name = "Zoom User Email",
                desc = "Your personal zoom email.",
                icon = "user",
            ),
            schema.Text(
                id = "token",
                name = "Zoom JWT Token",
                desc = "Please create a JWT Zoom app and paste your JWT token here.",
                icon = "key",
            ),
        ],
    )

def show_warning(message):
    return render.Root(
        child = center_children(
            [
                render.WrappedText(message),
            ],
        ),
    )

def get_user(expected_email, token):
    res = http.get(PAGED_URL, headers = {"Authorization": "Bearer " + token})
    if res.status_code != 200:
        return "Invalid token"
    foundUser = cache.get("status")
    if foundUser != None:
        return foundUser
    for item in res.json()["contacts"]:
        if expected_email == item["email"]:
            foundUser = item
            break
    if foundUser == None:
        return "Invalid email"
    status = foundUser["presence_status"]
    cache.set("status", status, CACHE_TTL)
    return status

def center_children(children):
    return render.Box(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = children,
        ),
    )

def offline():
    return render.Root(
        child = center_children(
            [
                render.Text("Off Air"),
            ],
        ),
    )

def online():
    return render.Root(
        child = center_children(
            [
                render.Text("On Air"),
                render.Image(src = RECORD_ICON, width = 20, height = 20),
            ],
        ),
    )

def main(config):
    user_email = config.str("email")
    token = config.str("token")
    if user_email == None or token == None:
        return show_warning("No email or token set")
    status_or_warning = get_user(user_email, token)
    if status_or_warning.startswith("Invalid"):
        return show_warning(status_or_warning)
    status = status_or_warning
    onAir = status == "In_Meeting" or status == "Presenting" or status == "In_Calendar_Event" or status == "Do_Not_Disturb"
    if not onAir:
        return offline()
    return online()
