"""
Applet: Any Progressbar
Summary: AnyProgressbar
Description: Show any progress bar using config properties, which can be updated via third party tools and/or Tidbyt API.
Author: wojciechka
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

# number of items to render
NUM_ITEMS = 4

# display defaults and colors
C_DISPLAY_WIDTH = 64
C_ANIMATION_DELAY = 32
C_BACKGROUND = [0, 0, 0]
C_TEXT_COLOR = [255, 255, 255]

# number of animation frames
C_ANIMATION_FRAMES = 60
C_ITEM_FRAMES = 15
C_END_FRAMES = 15

# configuration for infinite (no progress information) animation
C_INFINITE_PROGRESS_PAD_FRAMES = 50
C_INFINITE_PROGRESS_PAD_SCALE = 10.0
C_INFINITE_PROGRESS_PAD_PIXELS = int(C_INFINITE_PROGRESS_PAD_FRAMES / C_INFINITE_PROGRESS_PAD_SCALE)
C_INFINITE_PROGRESS_FRAMES = C_INFINITE_PROGRESS_PAD_FRAMES * 2 - 2

C_MIN_WIDTH = 2
C_HEIGHT = 8
C_PADDING = 0

# convert color specification from JSON to hex string
def to_rgb(color, combine = None, combine_level = 0.5):
    # default to white color in case of error when parsing color
    (r, g, b) = (255, 255, 255)

    if str(type(color)) == "string":
        # parse various formats of colors as string
        if len(color) == 7:
            # color is in form of #RRGGBB
            r = int(color[1:3], 16)
            g = int(color[3:5], 16)
            b = int(color[5:7], 16)
        elif len(color) == 6:
            # color is in form of RRGGBB
            r = int(color[0:2], 16)
            g = int(color[2:4], 16)
            b = int(color[4:6], 16)
        elif len(color) == 4 and color[0:1] == "#":
            # color is in form of #RGB
            r = int(color[1:2], 16) * 0x11
            g = int(color[2:3], 16) * 0x11
            b = int(color[3:4], 16) * 0x11
        elif len(color) == 3 and color[0:1] != "#":
            # color is in form of RGB
            r = int(color[0:1], 16) * 0x11
            g = int(color[1:2], 16) * 0x11
            b = int(color[2:3], 16) * 0x11
    elif str(type(color)) == "list" and len(color) == 3:
        # otherwise assume color is an array of R, G, B tuple
        r = color[0]
        g = color[1]
        b = color[2]

    if combine != None:
        combine_color = lambda v0, v1, level: min(max(int(math.round(v0 + float(v1 - v0) * float(level))), 0), 255)
        r = combine_color(r, combine[0], combine_level)
        g = combine_color(g, combine[1], combine_level)
        b = combine_color(b, combine[2], combine_level)

    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

# render a single item's progress
def render_progress(item, padding, frame_info):
    stack_children = [
        render.Box(width = C_DISPLAY_WIDTH, height = C_HEIGHT + padding, color = to_rgb(C_BACKGROUND)),
    ]

    label = item[0]
    color = item[1]
    progress_value = item[2]

    if progress_value != None:
        progress = progress_value / 100.0
        progress_percent = int(math.round(progress_value))
        if label != "":
            label += ": "
        label += str(progress_percent) + "%"

        progress_width = C_MIN_WIDTH + int(math.round(float(C_DISPLAY_WIDTH - C_MIN_WIDTH) * progress * frame_info["progress"]))

        stack_children.append(
            render.Box(
                width = progress_width,
                padding = 1,
                color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.6),
                height = C_HEIGHT,
                child = render.Box(
                    color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.8),
                ),
            ),
        )
    else:
        # render an animated item without progress specified
        position = frame_info["frame"] % C_INFINITE_PROGRESS_FRAMES
        if position >= C_INFINITE_PROGRESS_PAD_FRAMES:
            position = C_INFINITE_PROGRESS_FRAMES - position
        position = int(math.round(position / C_INFINITE_PROGRESS_PAD_SCALE))
        stack_children.append(
            render.Box(
                width = C_DISPLAY_WIDTH,
                padding = 1,
                color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.6),
                height = C_HEIGHT,
                child = render.Padding(
                    pad = (C_INFINITE_PROGRESS_PAD_PIXELS - position, 0, position, 0),
                    color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.8),
                    child = render.Box(
                        color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.7),
                    ),
                ),
            ),
        )

    # stack the progress bar with label
    stack_children.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text(
                    content = label,
                    color = to_rgb(color, combine = C_TEXT_COLOR, combine_level = 0.8),
                    height = C_HEIGHT,
                    offset = 1,
                    font = "tom-thumb",
                ),
            ],
        ),
    )

    # render the entire row
    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Stack(
                children = stack_children,
            ),
        ],
    )

# render a single animation frame of a single item, calculating current frame for animation purposes
def render_frame_item(items, i, fr):
    # if 4 items are shown, reduce spacing between lines to show all 4
    padding = 2
    if len(items) >= 4:
        padding = 0

    relative_frame = max(0, min(fr - i * C_ITEM_FRAMES, C_ANIMATION_FRAMES))
    progress = math.pow(math.sin(0.5 * math.pi * relative_frame / C_ANIMATION_FRAMES), 2)
    return render_progress(items[i], padding, {
        "items": len(items),
        "frame": fr,
        "progress": progress,
    })

# render a single animation frame
def render_frame(items, fr):
    children = [
        render_frame_item(items, i, fr)
        for i in range(len(items))
    ]

    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = children,
    )

def main(config):
    items = get_progress_items(config)

    # determine number of frames so any items without progress are looping properly
    frames = C_END_FRAMES + C_ANIMATION_FRAMES + C_ITEM_FRAMES * (len(items) - 1)
    frames += (C_INFINITE_PROGRESS_FRAMES - (frames % C_INFINITE_PROGRESS_FRAMES)) % C_INFINITE_PROGRESS_FRAMES
    return render.Root(
        delay = C_ANIMATION_DELAY,
        child = render.Box(
            child = render.Animation(
                children = [
                    render_frame(items, fr)
                    for fr in range(frames)
                ],
            ),
        ),
    )

def get_progress_items(config):
    items = []
    for i in range(1, NUM_ITEMS + 1):
        label = config.get("label%d" % (i))
        color = config.get("color%d" % (i))
        progress = config.get("progress%d" % (i))
        if label != None and label != "":
            if color == None:
                color = ""
            if progress != None and progress != "":
                progress = float(progress)
                if progress < 0.0:
                    progress = 0.0
                elif progress > 100.0:
                    progress = 100.0
            else:
                progress = None
            items.append([label, color, progress])

        # show up to 4 items, regardless of how many were configured
        if len(items) >= 4:
            break
    return items

def get_schema():
    fields = []
    for i in range(1, NUM_ITEMS + 1):
        fields += [
            schema.Text(
                id = "label%d" % (i),
                name = "Label %d" % (i),
                desc = "Label for item %d" % (i),
                icon = "gear",
                default = "",
            ),
            schema.Text(
                id = "progress%d" % (i),
                name = "Progress %d" % (i),
                desc = "Progress for item %d" % (i),
                icon = "gear",
                default = "",
            ),
            schema.Text(
                id = "color%d" % (i),
                name = "Color %d" % (i),
                desc = "Color for item %d" % (i),
                icon = "gear",
                default = "#ccc",
            ),
        ]
    return schema.Schema(
        version = "1",
        fields = fields,
    )
