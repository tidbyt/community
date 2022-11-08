"""
Applet: Xtrabyt
Summary: Display Xtrabyt.com View
Description: Display a custom drawing or integration view from Xtrabyt.com.
Author: vmitchell85
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")

BASE_URL = "https://xtrabyt.com"

def main(config):
    key = config.get("key") or None

    if (key == None):
        return renderWelcome()
    else:
        response = http.get(BASE_URL + "/views/" + key)

    if response.status_code == 200:
        data = response.json()
        if (data["type"] == "image"):
            return renderImage(data["content"])
        else:
            return renderError(key, data["type"])
    elif response.status_code == 503:
        return renderMaintenance()
    else:
        return renderError(key, response.status_code)

def renderError(key, status):
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "Xtrabyt Error",
                        font = "CG-pixel-3x5-mono",
                    ),
                    render.Text(
                        content = str(status),
                        font = "6x13",
                    ),
                    render.Text(
                        content = "KEY: " + key,
                        font = "tom-thumb",
                    ),
                ],
            ),
        ),
    )

def renderWelcome():
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "Welcome To",
                        font = "CG-pixel-4x5-mono",
                    ),
                    render.Text(
                        content = "XTRABYT",
                        font = "6x13",
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = "Get started at Xtrabyt.com",
                            font = "CG-pixel-3x5-mono",
                        ),
                    ),
                ],
            ),
        ),
    )

def renderMaintenance():
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "Xtrabyt.com is ",
                        font = "CG-pixel-4x5-mono",
                    ),
                    render.Text(
                        content = "down for",
                        font = "6x13",
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = "maintnenace",
                            font = "CG-pixel-3x5-mono",
                        ),
                    ),
                ],
            ),
        ),
    )

def renderImage(imgUrl):
    response = http.get(imgUrl)
    if response.status_code == 200:
        img = response.body()
    else:
        img = "https://xtrabyt.com/images/logo.png"
    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Image(
                        src = img,
                        width = 64,
                        height = 32,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "Xtrabyt Key",
                desc = "The Xtrabyt.com key for your view",
                icon = "key",
            ),
        ],
    )
