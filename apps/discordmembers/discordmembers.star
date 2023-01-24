"""
Applet: Discord Members
Summary: Discord Members Count
Description: Display the approximate member count for a given Discord server (via Invite ID).
Author: Dennis Zoma (https://zoma.dev)
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

DISCORD_API_URL = "https://discord.com/api/v9/invites/%s?with_counts=true"

TWITTER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAC1ElEQVQ4Ec1Tz4vNURQ/59z7/b433pvhMUjIjwhZIJGMxSSxwqSepiSKbKysKKW3VHZWkiSTjbdRFhZCSlYiCbuJMmg05pdmvt/vu/cen/vG+JE/gLP43vv93HM+95zPOZfofzOeTajRUHn9YXyFqNlLwgfV0YDJKvcnk5FSZ2tBnlVGFpY4vRjUD5pQuv3Njr28e3XJNBFr5GgT9TbULv44eoLUXmLihEhTVZpiVq+qwthoUGLhKkK8cFqo+nuifObWtTkfIpHEz+KhydVM6Xlh0wmScsQRG4PmMgsw7mKRLqzRPwlaVCQp9eXaOlCvq4kc0turNgQ9YjhZhlsi9sN+Vj0L/LGqy20i5nRHLVsaD2TJ1k/zRPgobmlHIgMypkQiKY5/kTEb4GXgqBwGrUhseX3m8h3UaIi4iepOYbsKWlAkgRiZ9/nT4Iu38EeKM2TI9qv32WPgg5E0moZCwNzf++5YKgjdp2hRO4AN6PSxz4vDPrhTcEVQJOIsqF7OWr4PDueVwngki1IIU08tJBWs3BPZY0AIhcf/o+bN7qHm9flP0NfXIMapfsu9u37nRm2sSKYfwnEwlhirgDqLrKnuEeyXR6IIWlMSDWFH/K+fyNZgQtbxTGMrZbGHIm5deZMyr56pIiIBWnEf95+cyCFDVLatEUScQlbPcRdaTxtI2eKaeDyM5Q3mD10yayPBrCGHzxb1opz2OCFjH6cuTdLqNvXOQnTBeVs+4aQb3eyBLsG5qQi2g9AgTA8NWWyugOgU1rInX6AVD4ps4iVU3IIbNzJpTT3ngVvvQ3DP4DuKjI5geJfDp/Cu9cJQcYHr9eGq1NKdpHIOAm73oTWmTP1Ena8sTSZWWCx0zZ13gX2VXHoW83TcuekvEuSqMdM38tHu4dkh4f0HPnV0Leza5UVX+vHqQLPJeJB/W/3k2FZDsjmxnXez3TTSPMy/P4e/A/4Z8h28+06zjQXyTQAAAABJRU5ErkJggg==
""")

def main(config):
    invite_id = config.get("invite_id", "r45MXG4kZc")

    cache_key_members_count = "discord_members_%s" % invite_id
    formatted_members_count = cache.get(cache_key_members_count)

    cache_key_server_name = "discord_server_%s" % invite_id
    server_name = cache.get(cache_key_server_name)

    if formatted_members_count == None or server_name == None:
        url = DISCORD_API_URL % invite_id
        response = http.get(url)

        if response.status_code != 200:
            fail("Discord request failed with status %d", response.status_code)

        body = response.json()

        if body == None or len(body) == 0 or body["guild"] == None or len(body["guild"]) == 0:
            formatted_members_count = "Not Found"
            server_name = "Check your invite ID"
        else:
            formatted_members_count = "%s members" % humanize.comma(int(body["approximate_member_count"]))
            server_name = body["guild"]["name"]
            cache.set(cache_key_members_count, formatted_members_count, ttl_seconds = 240)
            cache.set(cache_key_server_name, server_name, ttl_seconds = 240)

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(TWITTER_ICON),
                            render.WrappedText(formatted_members_count),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        offset_start = 10,
                        child = render.Text(
                            color = "#3c3c3c",
                            content = server_name,
                        ),
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
                id = "invite_id",
                name = "Invite ID",
                icon = "userPlus",
                desc = "Valid Discord Server Invite ID (Important: Set expiration to infinite)",
            ),
        ],
    )
