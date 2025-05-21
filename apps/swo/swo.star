load("http.star", "http")
load("render.star", "render")

DAY1OUTLOOK = "https://www.spc.noaa.gov/products/outlook/day1otlk.gif"
DAY2OUTLOOK = "https://www.spc.noaa.gov/products/outlook/day2otlk.gif"
DAY3OUTLOOK = "https://www.spc.noaa.gov/products/outlook/day3otlk.gif"

def main():
    img1 = http.get(DAY1OUTLOOK, ttl_seconds = 3600).body()
    img2 = http.get(DAY2OUTLOOK, ttl_seconds = 3600).body()
    img3 = http.get(DAY3OUTLOOK, ttl_seconds = 3600).body()

    return render.Root(
        delay = 1750,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Text(
                        content = "Day 1 SWO",
                        font = "6x13",
                    ),
                    render.Image(
                        src = img1,
                        width = 64,
                        height = 32,
                    ),
                    render.Text(
                        content = "Day 2 SWO",
                        font = "6x13",
                    ),
                    render.Image(
                        src = img2,
                        width = 64,
                        height = 32,
                    ),
                    render.Text(
                        content = "Day 3 SWO",
                        font = "6x13",
                    ),
                    render.Image(
                        src = img3,
                        width = 64,
                        height = 32,
                    ),
                ],
            ),
        ),
    )
