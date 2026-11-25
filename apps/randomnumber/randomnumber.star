load("random.star", "random")
load("render.star", "render")

def main():
    number = int(random.number(1, 101))
    return render.Root(
        delay = 1000,
        max_age = 15,
        child = render.Box(
            color = "#000000",
            child = render.Text(
                content = str(number),
                font = "10x20",
                color = "#FFD54F",
            ),
        ),
    )
