"""
Applet: Gitlab Pipeline
Summary: Shows Pipeline status
Description: Shows the status of the most recent pipeline in a selected Gitlab project.
Author: Sven Ringger
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

failed = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACEAAAAgCAYAAACcuBHKAAABDUlEQVRYR+2XMQ7CMAxFm4UTcAMYmZk6cHQGJmZGuAEnYAlqJEdO5STfEW4j1K5N25fv/+3UDR1crgOGIUA896OvwRzfNzNghwAQoBVIhDicPlkxXo9duGcOUfoAqWUOUfPEIkqsCsHTMfnCXe8xBdZloI0nEd0gSHaNElJ/aU1PUzn85eypd3BDl3pNrD/znMoTpeRMu9d0Xan7FpVA5korBO87VQhJBV4ODoF6Yh79AEEvnRszVwYTCC47shtzCKR98zWIJ2rRTw4qrS5HnuMKi57Q7j7XJ6RSSvPnJxC56C4OgapnqsQGoVUAWW/2L4HENpmiCK12DXI0pDX/rQRyDKBxbqaEpnxdQHwBC0kG3IXWTJ4AAAAASUVORK5CYII=""")
success = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACEAAAAgCAYAAACcuBHKAAABEklEQVRYR+2XzQ2DMAyFk5l6ZYUOwwZswDBdgWtnoqKJwaZO8hJhKargCCZ8tp9/8K6Dy3fA4ALE5NYizBRti4b1Bh4CoHONQHaI4TEmXVjec3hmDZH9AKXLHAJJ5X9DsOrYdLE856NsjdNAwRclekNQr6iKhNbgGoXblI7hNa5772BVles1ZCY0F29iELny3bxH2v75DBa1PAQyV1ohWAcuQyhREOngEKgmTqX/haBDf4SZSIMJhBjngDf2EMgM4TaAJkqlLzerVpUj7/EIa5qodT7VJ9R1QJs/V0AkV0JNT6YQaPhuiGM5Dpv81cKEMoFUjBhg0KmVRl1B5DpwBLX7DewiEsgaEAVrF4kKCXUB8QFyGqMdVzvXMAAAAABJRU5ErkJggg==""")
running = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACEAAAAgCAYAAACcuBHKAAABBElEQVRYR+2XQQ6EIAxF6Q3c6v3PpltvwERmSoop8EumEzKRrRUfv78tUphg0QQMIUHEGGIPhugd67EIAeAPe4FkiONYqodc1zM9c4dofYDVcodAcv3fELI6Ll9s25mrwDsN2fAPxEeKollZ0qH1l1HjDkHs+xK5d8iqavUajpOeM3miVb7X6S1dV+u+TSWQuTIKITtwF0JTQaZDQqCeuJd+guBN78aspcEFQsqOnMYdApkhMgbxRK/0i4vKqMuR96TCqiesp6/1CS2V2vz5CkStdH8OgarnqsQDYVUAiXf7l0DKtpiiCK01Brka5hjr5mj8FEog1wAe526eQBVLIJZgr9gXD1nhFa1vaLoAAAAASUVORK5CYII=""")
createdPendingSkipped = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACEAAAAgCAYAAACcuBHKAAABBElEQVRYR+2X4Q2EIAyFZSC2uLiPcQ5z+xi3YCAvktQUU+CVXD1y0b9W/Xh9r6AbOrhcBwxDhAgh7DUY770ZsEMACNAK5IRYtzUrxvga4z1ziNIHSC1ziJonblHipxA8HYcv5mk+U2DdBlp4EtEHgmTXKCHNl9b0NLVjeS87zQ5u6NKsoTruOZUnSsk5Vq+ZutL0LSqB7CutEHzuVCEkFXg7OATqiWv0IwS99GrMXBtMILjsyGrMIZDxzWsQT9SinxxUWl2OPMcVFj2hXX1uTkitlPafr0Dkons7BKqeqRIPhFYBpN7sXwKJbbKLIrTaGuRoSDX/rQRyDKDt3EwJTfu6gPgAs7cWEH3DHkAAAAAASUVORK5CYII=""")
canceled = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACEAAAAgCAYAAACcuBHKAAABEUlEQVRYR+2XwRnCIAyFYRmH8OLRNZzDAZzDNTx6cQiXoYoFk34BXvhM5dBem7Y/Ly8P6t0Alx+AwUWIcD2HFow/XcyAPQKQAK1AvhD7Q1mMxz3eM4eofSCpZQ7R8sQqSvwVgk3Hyxd+d8xTYN2GbPgNYpaCh5WiHVK+9E5PF0R43oKbs4MZupY1adXEcypP1CbnvXpN6krpW1UC2Vd6IWjuNCEkFWg7KATqieXofyBSjxfGLLXBBILKjqzGHAKJb1oDeaIx+uyg0uty5DmqsOgJ7epLOSG1Utp/fgJRGt3VIVD1TJXYILQKIPVm/xLI2LJdFKHV1iBHw1yjfTlaP4QSyDEgbedmnkAViyCaYqvaCbHH/oEngJdpAAAAAElFTkSuQmCC""")
manual = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACEAAAAgCAYAAACcuBHKAAABBUlEQVRYR+2X4RGDIAyFYY2O1jkco3N0tK6BVkSDF+CF6+txnv416peXlwS9G+DyAzC4FSK8XGjB+CnGMi6PAKQPs0AOiEclx0+8R4eofSCpRYdAan1tiKw7Fl/459EF7DLshr8hNinyYWUohzZfeo3bBRHey4TdZkfWVbVZk7IWnjN5ota+3+wtU1ebvlUlkL3SCyEncBNCU0GWQ0Kgnji3foRINT4Zs1QGCoSUHcmGDoHsEBkDeaLR+tlBpdflyHNSYdUT1uxLc0IrpbZ/fgJRat2/Q6DqUZW4IawKIPG0fwmkbbMtitBaY5Cj4R5jfTkaP4QSyDEgrXOaJ1DFVhBLMCt2BhiwvEkYq+zVAAAAAElFTkSuQmCC""")
pipeline_dict = dict([("invalid", [failed, "API CALL FAILED!"]), ("failed", [failed, "BUILD FAILED!"]), ("success", [success, "Success"]), ("running", [running, "Running"]), ("created", [createdPendingSkipped, "Created"]), ("pending", [createdPendingSkipped, "Pending"]), ("skipped", [createdPendingSkipped, "Skipped"]), ("canceled", [canceled, "Canc eled"]), ("manual", [manual, "Set to manual"])])

def main(config):
    token = config.get("api-token") or "example"
    projectId = config.get("project-id") or "example"
    print(token, projectId)
    branch = config.get("branch")
    status = get_pipeline_status(token, projectId, branch)
    ICON = render.Image(src = pipeline_dict.get(status)[0])
    padding = render.Box(width = 1, height = 12, color = "#000000")
    box = render.Column(
        children = [
            padding,
            render.WrappedText(content = pipeline_dict.get(status)[1], font = "tom-thumb"),
        ],
    )
    return render.Root(
        child = render.Row(
            children =
                [ICON, padding, box],
        ),
    )

def get_pipeline_status(accesstoken, id, ref):
    #simply as an example for preview in store, i know its really not elegant, might change it in the future
    if accesstoken == "example":
        if id == "example":
            return "success"

    # Set the GitLab API endpoint and access token
    api_endpoint = "https://gitlab.com/api/v4"

    # Specify the project and branch for which to check the pipeline status
    pipeline_url = "%s/projects/%s/pipelines?ref=%s&access_token=%s" % (api_endpoint, id, ref, accesstoken)

    #Gitlab request limit is 150 calls per user per minute, so caching is not needed
    pipeline_data = http.get(pipeline_url)
    if pipeline_data.status_code != 200:
        return "invalid"
    pipeline_data = pipeline_data.json()
    most_recent_pipeline = pipeline_data[0]
    return most_recent_pipeline["status"]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api-token",
                name = "Your Gitlab access token",
                desc = "Your Gitlab access token",
                icon = "gitlab",
                default = "",
            ),
            schema.Text(
                id = "project-id",
                name = "Project-Id",
                desc = "The id of the project you want to track.",
                icon = "hashtag",
                default = "",
            ),
            schema.Text(
                id = "branch",
                name = "Branch",
                desc = "The branch you want to track.",
                icon = "codeBranch",
                default = "main",
            ),
        ],
    )
