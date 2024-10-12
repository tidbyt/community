"""
Applet: Satoshi Radio
Summary: SR mining pool stats
Description: Show pool and user stats for the Satoshi Radio mining pool.
Author: @redboer
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

LOGO = base64.decode("""
UklGRi4EAABXRUJQVlA4WAoAAAAwAAAAGwAAHwAASUNDUMgBAAAAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADZWUDhMQAIAAC8bwAcQf+I2tm2lOs9yeqA1h2rcJSemDxr4LqE73gbr2LZd7HueXEDmjv6begE1+MNtZNtOc3AFeRcT0wBN0KBH0ht8A1Jsw/cLIMi2xT3BFwBtvHJOnwQGuJJkyZxDBz3dA55wSwigPlKw5zjQ7yUG/COFAAbXkowB78gxMAXIb/5tK4zyWOQFs0iR5yiw7vW+JwjAx8x7feQJI8koqLYKAZ/wZ13L66V2aZ7wM7Osp+DcHm71y7m7rIYWDGZeIgBYQk8sBjsvNWPj0AkYrLzUSeV7iQCrLHVSvRkwvMLbX6qX0Ut1Up1UJ2PXTzopyLJtW1Wjicfd3YWUVzxB43r63xx4Dyv5j+i/AkmSmRFPZs8nAAAAAAAAAAAAAAAAMDYQc4OkrcvCIPZJ5i8YxRyG+quVKhHbLOzv7+8s9GQ/GhFryhHR3qAXZ1E5jeZIOZqbEd968TVisREb5ahoxG4v1iI2plOUIsa71wqyERW7C+WoLMR+j/okpxH57EQ5KvuVYveU+VFImZSjcrUwYmx1fb3j+Ycvx2QbcZrQbKbXOrjpKOalzYRGqzm5wlxL0Y7CiqW2mRjVuM5M9tCsOpuYCccfz6sZmQ6HSJatNounEbkv708Pb5/5tuOlVtw6TGVRWf54rd893S5FzLCaNF3eFShM/Xp5vLu7//k7KqOJxpmLvQw3d3d3tfPa3d3d0/vneEqrRMfWzJRZyBi7+756lExLadzSv+3o3fwzOV0uR65YVCz2EAsAAAAA/8OnBA==
""")

DEFAULT_ADDRESS = ""
DEFAULT_SHOW_POOL_HASHRATE = True
DEFAULT_SHOW_POOL_WORKERS = False

def main(config):
    address = config.str("address", DEFAULT_ADDRESS)
    show_pool_hashrate = config.str("show_pool_hashrate", DEFAULT_SHOW_POOL_HASHRATE)
    show_pool_workers = config.str("show_pool_workers", DEFAULT_SHOW_POOL_WORKERS)

    info = []

    if address:
        user = user_data(address)
        if user.get("error"):
            render_info(info, False, "", user.get("error"))
        else:
            hashrate = user.get("hashrate1m", "0")
            render_info(info, True, re.sub(r"\D", "", hashrate), hash_unit(re.sub(r"\d", "", hashrate)))

    if show_pool_hashrate or show_pool_workers:
        pool = pool_data()

        if pool.get("error"):
            render_info(info, False, "", pool.get("error"))
        else:
            if show_pool_hashrate:
                hashrate = pool.get("hashrate1m", "0")
                render_info(info, (address == ""), re.sub(r"\D", "", hashrate), hash_unit(re.sub(r"\d", "", hashrate)))
            if show_pool_workers:
                render_info(info, False, humanize.ftoa(pool["Workers"]), "wrks")

    return render.Root(
        child = render.Row(
            children = [
                render.Image(src = LOGO),
                render.Column(
                    children = info,
                    main_align = "center",
                    expanded = True,
                ),
            ],
            expanded = True,
        ),
    )

def render_info(info, big, number, unit):
    if big:
        font_number = "Dina_r400-6"
        font_unit = "5x8"
        font_height = 9
    else:
        font_number = "tom-thumb"
        font_unit = "tom-thumb"
        font_height = 6

    info.append(
        render.Padding(
            child = render.Row(
                children = [
                    render.Text(number, font = font_number),
                    render.Box(width = 1, height = 1),
                    render.Text(unit, height = font_height, font = font_unit, color = "#abc"),
                ],
                main_align = "end",
                expanded = True,
            ),
            pad = (0, 0, 1, 0),
        ),
    )

def pool_data():
    res = http.get("https://pool.satoshiradio.nl/api/v1/pool", ttl_seconds = 3600)  # cache for 1 hour
    if res.status_code != 200:
        return {"error": "API error"}
    return res.json()

def user_data(address):
    res = http.get("https://pool.satoshiradio.nl/api/v1/users/%s" % address, ttl_seconds = 300)  # cache for 5 minutes
    if res.status_code != 200:
        return {"error": "no user"}
    return res.json()

def hash_unit(val):
    if val == "M":
        return "MH"
    if val == "G":
        return "GH"
    if val == "T":
        return "TH"
    if val == "E":
        return "EH"
    return "KH"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "address",
                name = "User bitcoin address",
                desc = "Leave empty for pool only",
                icon = "bitcoin",
                default = "",
            ),
            schema.Toggle(
                id = "show_pool_hashrate",
                name = "Pool hashrate",
                desc = "Show pool hashrate",
                icon = "gauge",
                default = True,
            ),
            schema.Toggle(
                id = "show_pool_workers",
                name = "Pool workers",
                desc = "Show pool workers",
                icon = "microchip",
                default = True,
            ),
        ],
    )
