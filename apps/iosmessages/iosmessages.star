load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_MSG = "Message goes here"
DEFAULT_SENDER = "Sender's Name"
IMSG_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAEFUExURQAAAOgeFgD/AAj4AZNoBugZEegfF+ceFOgcFGiaCrlMEegbE+gbEugZEQD/AAD/AAD/AMU8D+krI+s4MOgdFQD/AAD/AAD/AAD/AAD/AFGvBuggGAD/AAD/AOgvJeotJugeFgD/AAD/AGKeCPYKEQD/AAD/AAL/AgD/AAD/AAD/AAD/AAD/AAD/AOs6M+pIP+9fWu1PSQD/AB7/Hjv/OzD/MAr/DBfmALFZFgn/CXf/d9z/3PT/9O7/7rf/tzP/NGH/Yfv/+////8X/xRP/FKb/pvX/9Tz/PIz/jOj/6Cv/Kyn/Kcn/yXv/ewP/A0f/R7j/uKH/oZL/kkv/Swb/BhH/EQ//DxS1mnQAAAAudFJOUwAAAAAAAAAAAAAAKmAyBQkHKdHfM0qywL++0WEW0P7RKiTmrSHlieWLjG6zFQHi3SMVAAAAAWJLR0RCENc99AAAAAd0SU1FB+cFExIfIKRPr9MAAACqSURBVBjTZY/VEsIwEEVDcC1WGhyKFidIcSnuzv9/ChHKC+dp75k7s7sA6Bg4ZIIco8npcpsNLHsEgtfnrwWCTIghCSEUjtQbzaiFiFgc41a701V7iWSKNtJyfzAcjSdTNZO12qjIzeYaYbHM2x2sUVjRrK03RQgBa2yZ2O1/4nCkhdNZFzK+XG/3xxMrXJC1rzemlLiAYpkeJiGl8hX8dEGoQib05xjgnw87sBiYIsy+tgAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMy0wNS0xOVQxODozMTozMSswMDowMMhnsOYAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjMtMDUtMTlUMTg6MzE6MzErMDA6MDC5OghaAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDIzLTA1LTE5VDE4OjMxOjMyKzAwOjAw38czGAAAAABJRU5ErkJggg==
""")

def main(config):
    sent_from = config.str("sent_from", DEFAULT_SENDER)
    msg = config.str("msg", DEFAULT_MSG)

    if config.bool("hide_app", False):
        return []

    return do_render(sent_from, IMSG_ICON, msg)

def do_render(sent_from, msg):
    return render.Root(
        render.Column(
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            child = render.Image(
                                src = IMSG_ICON,
                                height = 20,
                                width = 20,
                            ),
                            width = 20,
                            height = 20,
                            padding = 2,
                        ),
                        render.Marquee(
                            width = 42,
                            child = render.Text(
                                content = sent_from,
                                font = "tb-8",
                            ),
                        ),
                    ],
                ),
                render.Marquee(
                    width = 58,
                    align = "center",
                    child = render.Text(
                        content = msg,
                        font = "tb-8",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "sent_from",
                name = "Sent From",
                desc = "Sender's Name",
                icon = "user",
            ),
            schema.Text(
                id = "msg",
                name = "Message",
                desc = "Message from sender",
                icon = "user",
            ),
            schema.Toggle(
                id = "hide_app",
                name = "Hide message?",
                desc = "",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )

def display_failure(msg):
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
        ),
    )
