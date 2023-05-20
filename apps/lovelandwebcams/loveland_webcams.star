"""
Applet: Loveland Webcams
Summary: Loveland Ski Area Webcams
Description: Displays random webcam images from Loveland Ski Area.
Author: John Sprunger
"""

load("cache.star", "cache")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

def main():
    addresses = [
        "https://photosskiloveland.com/Report/15minutes/data.jpg",
        "https://photosskiloveland.com/ptarmigan/ptarmigan.jpg",
        "https://photosskiloveland.com/chair9/image0001.jpg",
        "https://photosskiloveland.com/Single/chairone00001.jpg",
        "https://photosskiloveland.com/basin/single/Basin00001.jpg",
    ]

    #pulling images from here with a time stamp appended https://skiloveland.com/webcams/

    rand = random.number(0, 4)
    cache_key = addresses[rand]

    current_time_x = time.now().unix * 1000

    url = addresses[rand] + "?time=" + str(current_time_x)
    print(url)

    cached_img = cache.get(cache_key)
    if cached_img == None:
        print("cache miss for img " + cache_key)
        cached_img = http.get(url).body()
        cache.set(cache_key, cached_img, ttl_seconds = 300)
    else:
        print("cache hit for img " + cache_key)

    img = cached_img

    #if it's image #1 scroll vertical, else scroll horizontal
    if (rand == 0):
        return render.Root(
            delay = 500,
            child = render.Box(
                child = render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    offset_start = 0,
                    offset_end = 32,
                    child = render.Image(
                        src = img,
                        width = 64,
                        height = 64,
                    ),
                ),
            ),
        )
    else:
        return render.Root(
            delay = 750,
            child = render.Box(
                child = render.Marquee(
                    scroll_direction = "horizontal",
                    width = 64,
                    offset_start = 0,
                    offset_end = 64,
                    child = render.Image(
                        src = img,
                        width = 95,
                        height = 35,
                    ),
                ),
            ),
        )
