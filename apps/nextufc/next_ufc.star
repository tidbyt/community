"""
Applet: Next UFC
Summary: Next UFC event
Description: Shows next upcoming UFC event with date and time.
Author: Stephen So
"""

load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("encoding/base64.star", "base64")

url = "https://www.espn.com/mma/schedule"

ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABkAAAAICAYAAAAMY1RdAAAAAXNSR0IArs4c6QAAAWZJREFUOE91Ur1KA0EQ/mYWxIhIUtnZauDujGBpI9gJiuQFfAAbwdZGX0AQH8DCUgj4DPYmFyUvYKEk/hT+oJkZ2WMvXI7zir3dmW+/b+bbIYQvdc6yrZnFqpwyD0C07EMk0oqA7gSTXwr/OZH6J9EVmLdLqexIfukDq+bcXdA4S1QPi4SxCPWZzw3YqiKJVZtTBZgNchwBkon0mLtElGQJkaVr4LHtnORAL1JFXoxNRFQ7sdleMZddLlfdA3bJuU7o7DJR3f/PqqxL4MScO/b4scjGGnA7JWIA9Z3TzDuzi0j1IGX+AtGsj82L1D6AI3PuNGCGBowmXaqu9JhfiajuY1VdU8r8AqJGeOCdCLgpDMFvrDqTMj+AqOkxQ5HaJvBdaZXZc6y6WLbWiwiIOEzWyACXV2Vmb4lqo2xniYTS4ATMxgY85fkf1dY6MPQi7yBaqJya8OC5iKneJ2ZREVu0u8yRW/cHptSvjUBW6vcAAAAASUVORK5CYII=
""")

def main():
    rep = http.get(url, ttl_seconds = 3600)

    if rep.status_code != 200:
        fail("get failed with status %d", rep.status_code)

    doc = html(rep.body())

    def check_event(i):
        check = doc.find("tbody").children().find("a").eq(i)
        if "UFC" in check.text():
            #print(i)
            return check
        else:
            i += 1
            return check_event(i)

    event_node = check_event(1)
    event = event_node.text()

    date = event_node.parent().siblings().eq(0).text()
    time = event_node.parent().siblings().eq(1).text()

    return render.Root(
        child = render.Column(
            children = [            

                render.Row(
                    children = [
                        render.Padding(
                            render.Image(
                                src = ICON
                            ),
                            pad = (2,7,1,0)
                        ),
                        render.Padding(
                            render.Column(
                                children = [
                                    render.WrappedText(
                                        content = date,
                                        #width = 64,
                                        align = "center",
                                    ),
                                    render.WrappedText(
                                        content = time,
                                        #width = 64,
                                        align = "center",
                                    )
                                ]
                            ),
                            pad = (1,3,1,1)
                        )
                    ]
                ),
                render.Padding(
                    render.Box(
                        width = 64,
                        height = 9,
                        color = "#a61212",
                        child = render.Marquee(
                            width = 64,
                            offset_start = 9,
                            align = "center",
                            child = render.Text(
                                content = event,
                            ),
                        ),
                    ),
                    pad = (0, 0, 0, 0),
                )
            ]
        )
    )
