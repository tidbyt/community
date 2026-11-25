load("random.star", "random")
load("render.star", "render")

CELL = 2
PALETTE = {
    "Y": "#FFD54F",
    "K": "#352600",
    "R": "#F4516C",
    "W": "#FFFFFF",
    "B": "#42A5F5",
}

EMOJIS = [
    {
        "pixels": [
            "   YYYYYY   ",
            "  YYYYYYYY  ",
            " YYYYYYYYYY ",
            "YYYYYYYYYYYY",
            "YYYYYYYYYYYY",
            "YYYKYYKYYYYY",
            "YYYKYYKYYYYY",
            "YYYYYYYYYYYY",
            "YYYKKKKYYYYY",
            "YYYYKKYYYYYY",
            "YYYYKKYYYYYY",
            "   YYYYYY   ",
        ],
    },
    {
        "pixels": [
            "   YYYYYY   ",
            "  YYYYYYYY  ",
            " YYYYYYYYYY ",
            "YYYYYYYYYYYY",
            "YYYYYYYYYYYY",
            "YYKKYYYKKYYY",
            "YYKKYYYKKYYY",
            "YYYYYYYYYYYY",
            "YYYKKKKYYYYY",
            "YYYKWWKYYYYY",
            "YYYYRRYYYYYY",
            "   YYYYYY   ",
        ],
    },
    {
        "pixels": [
            "   YYYYYY   ",
            "  YYYYYYYY  ",
            " YYYYYYYYYY ",
            "YYYYYYYYYYYY",
            "YYYYYYYYYYYY",
            "YRRYYRRYYYYY",
            "YRRYYRRYYYYY",
            "YYYYYYYYYYYY",
            "YYYKKKKYYYYY",
            "YYYYKKYYYYYY",
            "YYYYKKYYYYYY",
            "   YYYYYY   ",
        ],
    },
    {
        "pixels": [
            "   YYYYYY   ",
            "  YYYYYYYY  ",
            " YYYYYYYYYY ",
            "YYYYYYYYYYYY",
            "YYYYYYYYYYYY",
            "YYKKKKKKYYYY",
            "YYKKKKKKYYYY",
            "YYYYYYYYYYYY",
            "YYYYKKYYYYYY",
            "YYYKKKKYYYYY",
            "YYYYYYYYYYYY",
            "   YYYYYY   ",
        ],
    },
    {
        "pixels": [
            "   YYYYYY   ",
            "  YYYYYYYY  ",
            " YYYYYYYYYY ",
            "YYYYYYYYYYYY",
            "YYYYYYYYYYYY",
            "YYYKYYKYYYYY",
            "YYYKYYKYYYYY",
            "YYYYBYYYYYYY",
            "YYYYBYYYYYYY",
            "YYYYKKYYYYYY",
            "YYYKKKKYYYYY",
            "   YYYYYY   ",
        ],
    },
]

def emoji_pixels(pixels):
    rows = []
    for line in pixels:
        cells = []
        for i in range(len(line)):
            pixel = line[i]
            color = PALETTE.get(pixel, "#000000")
            cells.append(render.Box(width = CELL, height = CELL, color = color))
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

def main():
    index = int(random.number(0, 100000)) % len(EMOJIS)
    emoji = EMOJIS[index]
    return render.Root(
        delay = 1000,
        max_age = 15,
        child = render.Box(
            color = "#000000",
            child = emoji_pixels(emoji["pixels"]),
        ),
    )
