load("http.star", "http")
load("render.star", "render")

CHARS_PER_LINE = 13

def format_text(original_text):
    lines = []
    for line in original_text.split("\n"):
        new_line = []
        for word in line.split(" "):
            append = word
            if len(word) > CHARS_PER_LINE:
                append = word[:CHARS_PER_LINE] + " " + word[CHARS_PER_LINE:]
            new_line.append(append)
        lines.append(" ".join(new_line))
    return "\n".join(lines)

def main():
    resp = http.get("https://whatthecommit.com/index.json", headers = {"accept": "application/json"})
    data = resp.json()
    if not "commit_message" in data:
        return render.Root(
            render.WrappedText(
                "Error pulling funny commit msg :/",
                font = "5x8",
            ),
        )
    msg = data["commit_message"]
    return render.Root(
        render.Padding(
            render.Column(
                [
                    render.Padding(
                        render.Text(
                            "git commit -m",
                        ),
                        pad = 1,
                    ),
                    render.Padding(
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "#ffffff",
                        ),
                        pad = (0, 1, 0, 1),
                    ),
                    render.Marquee(
                        render.WrappedText(
                            format_text(msg),
                            font = "5x8",
                        ),
                        height = 22,
                        delay = 20,
                        scroll_direction = "vertical",
                    ),
                ],
            ),
            pad = 1,
        ),
    )
