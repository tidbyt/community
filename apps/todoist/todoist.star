"""
Applet: Todoist
Summary: Integration with Todoist
Description: Shows the number of tasks you have due today.
Author: zephyern
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

TODOIST_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xh
BQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAA
hGVYSWZNTQAqAAAACAAFARIAAwAAAAEAAQAAARoABQAAAAEAAABKARsABQAAAAEA
AABSASgAAwAAAAEAAgAAh2kABAAAAAEAAABaAAAAAAAAAEgAAAABAAAASAAAAAEA
A6ABAAMAAAABAAEAAKACAAQAAAABAAAAEKADAAQAAAABAAAAEAAAAADHbxzxAAAA
CXBIWXMAAAsTAAALEwEAmpwYAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAA
PHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1Q
IENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cu
dzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRl
c2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJo
dHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9y
aWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2Ny
aXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgoZXuEHAAACsElEQVQ4
EX2TXUiTURjH/8/7Tje3vZtrTcIsCKSsrpS+LsS07KKC7ruoi5AK7MILvyiFFLyQ
gjC6KPDCqLsgqYSCjPWJUGYFBZlYZE5nm23OObfp+z6d827opI8D5+W85zy//3PO
c/6HJmrKjylEvQB8orPoJHq2iV9SxFhMsZEzacaEDOY6RQH1ahZVwnomMhvHArba
MwKpRFbIXJMJdMnIxAryrb75ZV3CqrksQUse4HDBGHwFnnoj9lYCTi8KkZXNqVnG
p/D4EMOuqVAtmSxONzj8HfrAM1g7O7FhKIr1V24wkvNCXwjkiIgJVvJPtJEM5kTM
PKf+4CnUilr4Rj+jqLUdqbExzDafI3J4TB5yh6uNiEVLfHiPyMVmcPAr3N290Kqq
sRSc5lBrA2F5CXkVe5HqvwmSNVkrAAqeb2Rv0wWoTidYlELWO3z9GiUbGlHofwKt
+gCSX0Y5fPIwkebNCOSIKAWV+3nK40H07h3M+wfxw2YjRdNQIsTse/Yh1N3FM9vK
iOyFApanXnMEKM6Dh2hTKsVL38axOPgIxb9m4T11GnP3+jngcMBSupW8L18wL85J
OreIZiUsgS02uG89pqKWNjnBiXcjmN7tpfzjLVQcjUJ1uRB7OAAo2VtaNZQpQOmZ
oBFubyaORUHudTAmxuC92gdbaSkSI2850tFE+n0/1NpdgLHiRhOWH0p8+sgFO3Zi
Yfg19HgcLlG0dGCSIz2XkbrUQ0rldlBhESCv2XTwCmsOaELoWrs6yHO2HqqtgCO3
+7Bwpp6UMhFeWg0kF4Rxl/84e1aGKXC0ig3/cx2bhZWdG8HDAShHKgUk3J1O/guU
vGl/mqwp/+lyar5YMqmLTCpswiwy61+2m81qwuIxyfcQUkRZ6mLxeAiGrgqfC8+L
l/d/WBrBhOVz/g1OHB6agdqc6AAAAABJRU5ErkJggg==
""")

DEFAULT_NAME = "Todoist"
DEFAULT_FILTER = "today | overdue"

TODOIST_URL = "https://api.todoist.com/rest/v1/tasks"

OAUTH2_CLIENT_ID = secret.decrypt("AV6+xWcEUOwEpNv5Vn/Coy6B/SnuptrA60tHR7jbVeT9dQLQB4V5CGlOx66GgcqXskc7t4cWoOH7WoTHTIo0gsoz5V+5WcfUCux96fsiB5Ge39UVXLuW/z4dF9S0cHE95xdQH1GlNz3DXqd6zhNeO/7Lvj2Mc+2tH+C8744EOytMDiMvQ/c=")
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcER7v3TINY0cQYhjRa28LOMhbLiSLo7cLKhisGf7mhZI7Py98s4whuqaZxCqya1OS12NDRMWACweNU+o0GNiMfHomvQnDElUQMdNIS2bsydB9wEbkQvapceyoGlmMPnB0RqFhnHstOnecRjlL0fJDHNmU47D7e2/53+j4s2vj/qKk=")

def main(config):
    token = config.get("auth")
    if token:
        filter_name = "%s" % (config.get("name") or DEFAULT_NAME)

        # TODO: Is there a good way to cache this per user?
        rep = http.get(TODOIST_URL, headers = {"Authorization": "Bearer %s" % token}, params = {"filter": config.get("filter") or DEFAULT_FILTER})

        if rep.status_code == 200:
            tasks = rep.json()
            num_tasks = len(tasks)
            content = "%s" % humanize.plural(int(num_tasks), "Task")
        elif rep.status_code == 204:
            content = "No Tasks :)"
        else:
            content = "Error"
    else:
        # This is used to display the app preview image
        # when the user isn't logged in.
        filter_name = "Todoist"
        content = "4 Tasks"
        print("User is not logged in. Displaying preview image.")

    return render.Root(
        delay = 500,
        max_age = 86400,
        child =
            render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    children = [
                        render.Image(src = TODOIST_ICON),
                        render.Column(
                            children = [
                                render.Marquee(child = render.Text(content = filter_name), width = 40),
                                render.Text(content = content),
                            ],
                        ),
                    ],
                ),
            ),
    )

def oauth_handler(params):
    params = json.decode(params)
    res = http.post(
        url = "https://todoist.com/oauth/access_token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            code = params["code"],
            client_id = OAUTH2_CLIENT_ID,
            client_secret = OAUTH2_CLIENT_SECRET,
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
                icon = "square-check",
                handler = oauth_handler,
                client_id = OAUTH2_CLIENT_ID or "fake-client-id",
                authorization_endpoint = "https://todoist.com/oauth/authorize",
                scopes = [
                    "data:read",
                ],
            ),
            schema.Text(
                id = "name",
                name = "Name",
                desc = "Name to display",
                icon = "input-text",
                default = DEFAULT_NAME,
            ),
            schema.Text(
                id = "filter",
                name = "Filter",
                desc = "Filter to apply to tasks.",
                icon = "filter-list",
                default = DEFAULT_FILTER,
            ),
        ],
    )
