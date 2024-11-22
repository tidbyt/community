"""
Applet: Better On-Call
Summary: See who's on call
Description: Show's whos currently on-call in Better Stack.
Author: tidbyt
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ONCALL_URL = "https://uptime.betterstack.com/api/v2/on-calls"
CACHE_TTL = 120

def render_on_call(first_name, last_name, email):
    return render.Column(
        expanded = True,
        main_align = "center",
        children = [
            render.Row(
                expanded = True,
                main_align = "left",
                children = [
                    render.Text("    On Call", color = "#ff8"),
                ],
            ),
            render.Marquee(
                width = 62,
                align = "center",
                child = render.Text("%s %s" % (first_name, last_name)),
            ),
            render.Marquee(
                width = 62,
                align = "center",
                child = render.Text(email),
            ),
        ],
    )

def main(config):
    # Mock graphic for preview if no token provided
    if "token" not in config or len(config["token"]) == 0:
        return render.Root(
            child = render.Box(
                child = render_on_call("John", "Doe", "john@example.com"),
            ),
        )

    # Fetch on-call data
    res = http.get(
        ONCALL_URL,
        headers = {
            "Authorization": "Bearer " + config["token"],
        },
        ttl_seconds = CACHE_TTL,
    )
    if res.status_code == 401:
        # Bad token
        return render.Root(
            child = render.Box(
                child = render.Text("Bad API Token", color = "#f00"),
            ),
        )
    if res.status_code != 200:
        fail("Failed to list rotations, code %d: %s" % (res.status_code, res.text))

    d = res.json()

    # Only support 1 rotation for now
    if len(d["data"]) == 0:
        return render.Root(
            child = render.Text("No one is on call"),
        )

    # Grab name and email
    users = []
    for user in d["data"][0]["relationships"]["on_call_users"]["data"]:
        user_id = user["id"]

        for inc in d["included"]:
            if inc["id"] == user_id:
                users.append((
                    inc["attributes"]["first_name"],
                    inc["attributes"]["last_name"],
                    inc["attributes"]["email"],
                ))

    if len(users) == 0:
        return render.Root(
            child = render_on_call("", "", "<nobody>"),
        )

    return render.Root(
        child = render.Box(
            child = render_on_call(*users[0]),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "token",
                name = "API token",
                desc = "Your Better Uptime API token.",
                icon = "key",
            ),
        ],
    )
