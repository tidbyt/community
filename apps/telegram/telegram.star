"""
Applet: Telegram
Summary: Group member count
Description: View your group/chat member count. Add @tidbytbot to your group/chat to get the Chat ID.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# dev bot token
DEV_BOT_TOKEN = ""

# production bot token
PROD_BOT_TOKEN = "AV6+xWcEm6x/cMdL/10i8G/yzrmrIgsz+i8I4h3TZzTPDR7NoOy66JgoPLJ2eGDyMMEmf0oRX2fC1R8bverW1JnMA/zdf9ZhGn/CgvFMN91ysxQhOJHDnu/mRoEYiVt9JHBzLjP3MqkIbwuTSeTbf0PhgASNG8P+3RQnprd90xU1BemlOXVO6FM6Xt0Ft+qjSoE7TA=="

# telegram logo
TG_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAMAAAC6V+0/AAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAIZUExURQAAACGW8yGV8iGV8SGX9CGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yGW8yCV8yGW8yGW8yCV8SGW8yGX9CGV8SGW8yGW8yGW8yGW8yGW8yGX9CGW8iGW8yGX9SGV8iGf/yGW8iGW8yGW8yGV8iGW8yGW8yGW8yGW8yGW8yGV8iGW8yGW8yGU8SGW8iGV8iGV8iGV8iGa+iGW8yCV8yGV8h6T8CCS7jWd7yuY7x+U8R2S7iaU61Wp7ZnL8+Dv/JfK8yCQ6iCV8h2S7yKS7D+f64G/8L/e9vL4/f///6nO6x6K3yGU8B+S7jCY62q07q3V9OLw+/T29/v8/HOq1RqF2iCV8SmV7ITB8dTp+fr8/v7//+3w8uPo6/7+/vD1+UePyByI3yGU8R2R7U+j5u30+vn6++Lo6tng5Pf4+dvo8TKGyB6N5SCR7CSH1lCQw3ykw6/E1ejt8Nvh5NLa3u/y9L3V5x9+yiGW8iCT7x6K4Bh6yBVssRpjnJKuw8/Y2+Hm6b/X6iCD0SCS7CCT7h+P5x6I3Rd3w2eZvsrT18DM0tvj6Z7D4B2C0xyH3DSCv5SwxE9+oTRsmLrN3Xqt1hmD1yCU7yCQ6R6B0CZ5uhhvtBZusylzrWKYxDWHyR2K4SGV8R+O5h2I3R6J3xuB0hh7yhyF2SCR6yCS7b/ZZuYAAAA9dFJOUwAAAAAAAwUBAidmqbaYUBgWhOX60loGHrj4hQf7gALvSLLoK2UFtnEFtgGY+1X62hyX+NnnT+/Z+9qXJwGygYTrAAAAAWJLR0RTemcdBgAAAAd0SU1FB+gCFQEBMWLDnM4AAAEWSURBVBgZPcFfS1NhAMDh3+89p50/2xgEhiCREWsXu/AjBPO7deFn6AtIN3rhVfeRSXQT6fCiwGjChKW4ZYp7feeBnkcSgVy8BSIgIIUJ6hVEEKSnQ5Lv6pSIyDP7NDzV30SlV/ZZCSZjPSNQ2CcpymJlKwTQshrSs4F6NJ/mOOy1TW6oXNT+tTvNc1+ZzHiqdrS7MSHftKu/4Ln686UekpFn1jpw5RsdP29/gDzYsXEIbUd7sxbh+Ox93RhBuy1ZRma5uBgPqjx5/efFk/rr3fF94Mr5cr969Kau68XJLQE8ny0Pqmq/XNkJN8QQmXr5bxKv3f3xLrz1CyBIsa4bcKd+WhIRENa6ZrSyzsdwH0ES+S+SPAD+s0oInvKGEAAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNC0wMi0yMVQwMTowMTozOCswMDowMNHpCWoAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjQtMDItMjFUMDE6MDE6MzgrMDA6MDCgtLHWAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI0LTAyLTIxVDAxOjAxOjQ5KzAwOjAwWxOSpAAAAABJRU5ErkJggg==
""")

# telegram api url
TG_URL = "https://api.telegram.org/bot%s/getChatMemberCount"

def main(config):
    # get configs
    chat_id = config.str("chat_id", None)
    group_name = config.str("group_name", "Your Channel")
    dot_separator = config.bool("dot_separator", False)

    # decrypt bot token or use dev value
    bot_token = secret.decrypt(PROD_BOT_TOKEN) or DEV_BOT_TOKEN

    # validate if token was provided
    if bot_token in (None, ""):
        fail("Please provide a bot token in the DEV_BOT_TOKEN variable!")

    if chat_id == None:
        return render_demo(dot_separator)

    # fetch member count
    res = http.get(TG_URL % bot_token, ttl_seconds = 3600, params = {
        "chat_id": chat_id,
    })

    # handle api errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(res.json())

    # check returned data
    data = res.json()

    if data["ok"] != True:
        return render_error(data)

    member_count = humanize.comma(data["result"])

    # change thousands separator if necessary
    if (dot_separator):
        member_count = member_count.replace(",", ".")

    # render result
    return render.Root(
        child = render.Box(
            render.Column(
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = TG_LOGO),
                            render.Column(
                                children = [
                                    render.Text(member_count),
                                    render.Text("members"),
                                ],
                            ),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(content = group_name, color = "#777"),
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
                id = "chat_id",
                name = "Chat ID",
                desc = "Chat ID given by the Tidbyt bot.",
                icon = "telegram",
            ),
            schema.Text(
                id = "group_name",
                name = "Group/chat name",
                desc = "Name of the group/chat.",
                icon = "signature",
                default = "Your Group",
            ),
            schema.Toggle(
                id = "dot_separator",
                name = "Use dot separator",
                desc = "Use dots for thousands separator.",
                icon = "toggleOn",
                default = False,
            ),
        ],
    )

def render_demo(dot_separator):
    member_count = "5,678"

    if dot_separator:
        member_count = member_count.replace(",", ".")

    return render.Root(
        child = render.Box(
            render.Column(
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = TG_LOGO),
                            render.Column(
                                children = [
                                    render.Text(member_count),
                                    render.Text("members"),
                                ],
                            ),
                        ],
                    ),
                    render.Text(content = "Tidbyt", color = "#777"),
                ],
            ),
        ),
    )

def render_error(error):
    error_code = int(error.get("error_code", "000"))
    error_desc = error.get("description", "No description :(")

    return render.Root(
        child = render.Box(
            render.Column(
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = TG_LOGO),
                            render.Column(
                                children = [
                                    render.Text(content = "API Error"),
                                    render.Text(content = str(error_code), color = "#f00"),
                                ],
                            ),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(content = error_desc, color = "#ff0"),
                    ),
                ],
            ),
        ),
    )
