load("animation.star", "animation")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

DEV_SERVER_ID = ""
DEV_PTERO_URL = "https://www.example.com"
DEV_API_KEY = ""

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
        return "ERROR: %d" % res.status_code
    name = res.json()["attributes"]["name"]
    return name

def get_status(url, server, key):
    state = ""
    disk = 0
    cpu = 0
    mem = 0
    uptime = 0

    stats = {
        "uptime": uptime,
        "cpu": cpu,
        "mem": mem,
        "disk": disk,
        "state": state,
    }

    res = http.get(
        url + "/api/client/servers/" + server + "/resources",
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer " + key,
        },
    )
    if res.status_code != 200:
        return stats
    stats["state"] = res.json()["attributes"]["current_state"]
    stats["disk"] = convert_bytes(res.json()["attributes"]["resources"]["disk_bytes"])
    stats["cpu"] = math.ceil(res.json()["attributes"]["resources"]["cpu_absolute"] * 100) / 100
    stats["mem"] = convert_bytes(res.json()["attributes"]["resources"]["memory_bytes"])
    stats["uptime"] = convert_ms(res.json()["attributes"]["resources"]["uptime"])

    return stats

def convert_bytes(bytes):
    gb = math.ceil((bytes / math.pow(1024, 3)) * 100) / 100
    return gb

def convert_ms(millis):
    seconds = millis // 1000
    minutes = seconds // 60
    hours = minutes // 60
    minutes %= 60
    return str("%dh %dm") % (int(hours), int(minutes))

def render_stat(stat, v):
    if stat == "uptime":
        return render.Text("Up: %s" % v)
    if stat == "cpu":
        return render.Text("CPU: " + str(v) + " %")
    if stat == "mem":
        return render.Text("Mem: %sGB" % v)
    if stat == "disk":
        return render.Text("Disk: %sGB" % v)
    else:
        return render.Text("No info..")

def build_anim(k, v):
    return animation.Transformation(
        height = 32,
        width = 54,
        duration = 120,
        origin = animation.Origin(0.5, 0.5),
        wait_for_child = True,
        child = render_stat(k, v),
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(0, 32)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 0.2,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 0.8,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(0, 32)],
                curve = "ease_in_out",
            ),
        ],
    )

def build_display(url, server, key):
    name = get_details(url, server, key)
    stats = get_status(url, server, key)

    if stats["state"] != "running":
        status = render.Box(width = 8, height = 32, color = "#b10")
    else:
        status = render.Box(width = 8, height = 32, color = "#0f0")

    return render.Row(
        main_align = "space_between",
        cross_align = "center",
        expanded = True,
        children = [
            render.Column(
                main_align = "center",
                children = [
                    render.Row(
                        children = [
                            render.Marquee(
                                width = 54,
                                child = render.Text("%s" % name),
                            ),
                        ],
                    ),
                    render.Box(
                        height = 1,
                        width = 54,
                        color = "#333",
                    ),
                    render.Sequence(
                        children = [
                            build_anim(k, v)
                            for k, v in stats.items()[:-1]
                        ],
                    ),
                ],
            ),
            render.Column(
                children = [
                    status,
                ],
            ),
        ],
    )

def main(config):
    server = config.str("server", DEV_SERVER_ID)
    url = config.str("url", DEV_PTERO_URL)
    key = config.str("api_key", DEV_API_KEY)

    return render.Root(
        show_full_animation = True,
        child = render.Box(
            child = build_display(url, server, key),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "The client API key for your server.",
                icon = "key",
            ),
            schema.Text(
                id = "url",
                name = "Pterodactyl FQDN",
                desc = "The URL for your Pterodactyl implementation. ex. https://www.example.com",
                icon = "link",
            ),
            schema.Text(
                id = "server",
                name = "Server ID",
                desc = "The ID of your server. ex. be6a9hy7",
                icon = "idCard",
            ),
        ],
    )
