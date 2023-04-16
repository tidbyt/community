load("encoding/base64.star", "base64")

# v2
#
load("render.star", "render")
load("time.star", "time")

SALONICON = base64.decode("""
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
""")

def main(config):
    # font = config.get("font", "tb-small")
    timezone = config.get("timezone") or "America/Chicago"

    now = time.now().in_location(timezone)

    w4 = time.parse_duration("672h")
    w6 = time.parse_duration("1008h")
    w8 = time.parse_duration("1344h")

    now4 = now + w4  # 4 weeks
    now6 = now + w6  # 6 weeks
    now8 = now + w8  # 8 weeks

    #appts = "Book Next Appointment ...
    appt4 = "4 Wk - " + now4.format("Jan 2")
    appt6 = "6 Wk - " + now6.format("Jan 2")
    appt8 = "8 Wk - " + now8.format("Jan 2")

    return render.Root(
        max_age = 120,
        show_full_animation = True,
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    # render.Image(src = SALONICON),
                    render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        children = [
                            render.Text(content = appt4, color = "#c01e30", font = "CG-pixel-4x5-mono"),
                            render.Text(content = appt6, color = "#c01e30", font = "CG-pixel-4x5-mono"),
                            render.Text(content = appt8, color = "#c01e30", font = "CG-pixel-4x5-mono"),
                            render.Marquee(width = 64, scroll_direction = "horizontal", child = render.Text("Book Next Appointment", color = "#ffffff", font = "tb-8")),
                        ],
                    ),
                ],
            ),
        ),
    )
