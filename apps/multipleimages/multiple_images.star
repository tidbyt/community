"""
Applet: Multiple Images
Summary: Show multiple images
Description: Show up to six images.
Author: rs7q5
"""

#multiple_images.star
#Created 20240312 RIS
#Last Modified 20240312 RIS

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

maxImages = 6  #max images that can be selected

def main(config):
    if config.bool("hide_app", False):
        return []

    delay = int(config.str("delay", "500"))

    #get images
    img_vec = get_images(config)
    if len(img_vec) == 0:
        img = render.Box(render.WrappedText(
            width = 64,
            align = "center",
            content = "No images selected!!!!",
        ))
    else:
        img = render.Animation(img_vec)

    return render.Root(
        delay = delay,
        child = img,
        show_full_animation = True,
    )

def get_schema():
    delay_vec = [
        schema.Option(display = "%d msec" % x, value = str(x))
        for x in list(range(500, 5000 + 500, 500))
    ]
    field_vec = [
        schema.Toggle(
            id = "hide_app",
            name = "Hide app?",
            desc = "",
            icon = "eyeSlash",
            default = False,
        ),
        schema.Dropdown(
            id = "delay",
            name = "Delay between images",
            desc = "specify the delay between images.",
            icon = "stopwatch",
            default = delay_vec[0].value,
            options = delay_vec,
        ),
    ]

    #replicate photoSelect schema
    for i in range(maxImages):
        field_vec.append(
            schema.PhotoSelect(
                id = "image%d" % (i + 1),
                name = "Image %d" % (i + 1),
                desc = "",
                icon = "image",
            ),
        )

    return schema.Schema(
        version = "1",
        fields = field_vec,
    )

######################################################
#functions
def get_images(config):
    img_vec = []
    for i in range(maxImages):
        img = config.get("image%d" % (i + 1))
        if img != None:
            # img_vec.append(img)
            img_vec.append(render.Image(base64.decode(img)))

    return img_vec

######################################################
