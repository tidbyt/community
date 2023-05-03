"""
Applet: Shuffle Images
Summary: "Randomly display an image",
Description: "Randomly displays an image from a user-specified list.",
Author: rs7q5
"""

#shuffle_images.star
#Created 20220704 RIS
#Last Modified 20220824 RIS

load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

maxImages = 6  #max images that can be selected

def main(config):
    if config.bool("hide_app", False):
        return []

    #get images and count how many are actually chosen
    img_vec = get_images(config)
    img_cnt = len(img_vec)

    #select which images to display
    #img_cnt = 1
    if img_cnt == 0:
        img = render.Box(render.WrappedText(
            width = 64,
            align = "center",
            content = "No images selected!!!!",
        ))
    elif config.bool("shuffle", True) and img_cnt > 1:  #should only be greater than 1 once non-shuffling is implemented
        idx = random.number(0, img_cnt - 1)  #-1 becuase indices start at zero
        img = render.Image(base64.decode(img_vec[idx]))
    else:
        idx = (int(time.now().unix) // 60) % img_cnt  #new iamge every 60 seconds
        img = render.Image(base64.decode(img_vec[idx]))
        #print("Displaying Image %d!!!!" % (idx+1))

    #get image delay
    delay = 80  #default
    if type(img) == "Image":
        if img.delay > 0:
            delay = img.delay

    return render.Root(
        delay = delay,
        child = img,
    )

def get_schema():
    field_vec = [
        schema.Toggle(
            id = "hide_app",
            name = "Hide app?",
            desc = "",
            icon = "eyeSlash",
            default = False,
        ),
        schema.Toggle(
            id = "shuffle",
            name = "Shuffle images",
            desc = "Enable to shuffle the order images show up.",
            icon = "shuffle",
            default = True,
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
            img_vec.append(img)
            #img_vec.append(render.Image(base64.decode(img)))

    return img_vec

######################################################
