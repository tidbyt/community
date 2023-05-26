load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def get_details(url, server, key):
    res = http.get(
        url + "/api/client/servers/" + server,
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer " + key,
        },
    )

    if res.status_code != 200:
        return render.Text("ERROR: %d" % res.status_code)
    name = res.json()["attributes"]["name"]
    return render.Text(name)

def get_status(url, server, key):
    res = http.get(
        url + "/api/client/servers/" + server + "/resources",
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer " + key,
        },
    )
    if res.status_code != 200:
        return render.Circle(color = "#B10", diameter = 6)
    status = res.json()["attributes"]["current_state"]

    if status != "running":
        return render.Circle(color = "#B10", diameter = 6)
    else:
        return render.Circle(color = "#0E3", diameter = 6)

def build_display(url, server, key):
    name = get_details(url, server, key)
    status = get_status(url, server, key)

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            name,
            status,
        ],
    )

def main(config):
    server = config.str("server", "")
    url = config.str("url", "https://www.example.com")
    key = config.str("api_key", "")

    return render.Root(
        child = render.Box(
            render.Column(
                children = [
                    build_display(url, server, key),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "The client API key for your server. ex. ptlc_***",
                icon = "gear",
            ),
            schema.Text(
                id = "url",
                name = "Pterodactyl FQDN",
                desc = "The URL for your Pterodactyl implementation. ex. https://www.example.com",
                icon = "gear",
            ),
            schema.Text(
                id = "server",
                name = "Server ID",
                desc = "The ID of your server. ex. be6a9hy7",
                icon = "gear",
            ),
        ],
    )
