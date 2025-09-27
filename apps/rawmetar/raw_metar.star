"""
Applet: Raw METAR
Summary: METAR text weather reports
Description: METAR text weather reports for pilots.
Author: tabrindle
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    station_id = config.str("station_id") or "KMCO"
    seconds = config.str("seconds") or "4"

    if not station_id:
        return render.Root(
            child = render.WrappedText(
                content = "Bad Station ID Configuration Needed",
                font = "tb-8",
                color = "#f00",
            ),
        )

    response = http.get("https://aviationweather.gov/api/data/metar?ids={}".format(station_id))
    content = response.body()

    if not content:
        return render.Root(
            child = render.WrappedText(
                content = "Bad Response From Server",
                font = "tb-8",
                color = "#f00",
            ),
        )

    max_line_width = 12
    lines_per_page = 4

    words = content.split()
    lines_to_display = []
    current_line = ""

    for word in words:
        if len(current_line) + len(word) + 1 > max_line_width and current_line:
            lines_to_display.append(current_line)
            current_line = word
        else:
            current_line = current_line + (" " + word if current_line else word)

    if current_line:
        lines_to_display.append(current_line)

    pages_to_display = [lines_to_display[i:i + lines_per_page] for i in range(0, len(lines_to_display), lines_per_page)]

    frames = []
    for page in pages_to_display:
        for _ in range(int(seconds) * 20):
            frames.append(page)

    return render.Root(
        child = render.Animation(
            children = [
                render.WrappedText(
                    content = "".join(text),
                    font = "tb-8",
                )
                for text in frames
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station_id",
                name = "Station ID to lookup",
                desc = "The station ID to get the METAR for",
                icon = "locationPin",
            ),
            schema.Text(
                id = "seconds",
                name = "Seconds per page of data",
                desc = "How long to display each METAR page for",
                icon = "clock",
            ),
        ],
    )
