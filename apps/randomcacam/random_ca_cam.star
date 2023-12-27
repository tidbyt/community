"""
Applet: Random CA Cam
Summary: A Random CA Traffic Camera
Description: See a random traffic camera from the roads of California.
Author: quacksire
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

API_ENDPOINT = "https://caltrans-cameras.quacksire.workers.dev/?random"

def main():
    rep = http.get(API_ENDPOINT)

    if rep.status_code != 200:
        fail("Request failed with status %d", rep.status_code)

    data = rep.body()
    cams = json.decode(data)
    #print(cams)

    randomCam = random.number(0, len(cams) - 1)
    cam = cams[randomCam]

    print(cam)

    img = http.get(cam["cctv"]["imageData"]["static"]["currentImageURL"])
    imgData = img.body()

    simg = http.get(cam["cctv"]["imageData"]["static"]["referenceImage1UpdateAgoURL"])
    simgData = simg.body()

    ani = [
        render.Image(
            src = imgData,
            width = 75,
            height = 50,
        ),
        render.Image(
            src = simgData,
            width = 75,
            height = 50,
        ),
    ]

    # loop 13 times
    for i in range(2, 13):
        img_l = http.get(cam["cctv"]["imageData"]["static"]["referenceImage%sUpdatesAgoURL" % i])
        img_l_d = img_l.body()

        ani.append(
            render.Image(
                src = img_l_d,
                width = 75,
                height = 50,
            ),
        )

    return render.Root(
        delay = 201,
        child = render.Column(
            expanded = False,
            children = [
                render.Animation(
                    children = ani,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
