"""
Applet: Display My IP
Summary: Displays your public IP
Description: Displays the public IP of the network to which your Tidbyt is connected.
Author: Nick Kuzmik (github.com/kuzmik)
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

IPIFY_API = "https://api.ipify.org?format=json"

def main(config):
    use_cache = config.bool("use_cache", True)

    pub_ip = get_ip(use_cache)

    return render.Root(
        child = render.Box(
            render.Column(
                main_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text("Public IP:", color = "#FFFFFF"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text(pub_ip, color = "#AACCFF"),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_ip(use_cache):
    if not use_cache:
        resp = http.get(IPIFY_API)
        if resp.status_code != 200:
            fail("Ipify request failed with status %d", resp.status_code)
        pub_ip = resp.json()["ip"]
    else:
        ip_cached = cache.get("pub_ip")
        if ip_cached != None:
            pub_ip = str(ip_cached)
        else:
            resp = http.get(IPIFY_API)
            if resp.status_code != 200:
                fail("Ipify request failed with status %d", resp.status_code)
            pub_ip = resp.json()["ip"]
            cache.set("pub_ip", str(pub_ip), ttl_seconds = 300)
    return pub_ip

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "use_cache",
                name = "Cache API results",
                desc = "A toggle for caching the api value.",
                icon = "cog",
                default = True,
            ),
        ],
    )
