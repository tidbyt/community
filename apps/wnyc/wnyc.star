"""
Applet: WNYC
Summary: WNYC What's On
Description: Shows what's currently playing on WNYC, New York's flagship public radio station.
Author: Andrew Westling
"""

load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

COLORS = {
    "red": "#DE1E3D",
    "white": "#FFFFFF",
    "light_gray": "#AAAAAA",
    "medium_gray": "#888888",
    "dark_gray": "#444444",
}

STREAM_OPTIONS = [
    schema.Option(
        display = "WNYC 93.9 FM",
        value = "wnyc-fm939",
    ),
    schema.Option(
        display = "WNYC AM 820",
        value = "wnyc-am820",
    ),
]

LAYOUT_OPTIONS = [
    schema.Option(
        display = "Name and Image",
        value = "with_image",
    ),
    schema.Option(
        display = "Name and Description",
        value = "with_description",
    ),
    schema.Option(
        display = "Name only",
        value = "with_name_only",
    ),
]

DEFAULT_STREAM = STREAM_OPTIONS[0].value
DEFAULT_LAYOUT = LAYOUT_OPTIONS[0].value
DEFAULT_USE_CUSTOM_COLORS = False
DEFAULT_COLOR_SHOW_TITLE = COLORS["white"]
DEFAULT_COLOR_DESCRIPTION = COLORS["medium_gray"]

RED_HEADER_BAR = render.Stack(
    children = [
        render.Box(width = 64, height = 6, color = COLORS["red"]),
        render.Text(content = "WNYC", height = 7, font = "tb-8"),
    ],
)

ERROR_CONTENT = render.Column(
    expanded = True,
    main_align = "space_around",
    children = [
        render.Marquee(width = 64, child = render.Text(content = "Can't connect to WNYC", color = COLORS["red"])),
    ],
)

def main(config):
    stream = config.str("stream", DEFAULT_STREAM)
    WHATS_ON = ("https://api.wnyc.org/api/v1/whats_on/%s" % stream)

    # Get settings values
    layout = config.str("layout", DEFAULT_LAYOUT)
    use_custom_colors = config.bool("use_custom_colors", DEFAULT_USE_CUSTOM_COLORS)
    if use_custom_colors:
        color_show_title = config.str("color_show_title", DEFAULT_COLOR_SHOW_TITLE)
        color_description = config.str("color_description", DEFAULT_COLOR_DESCRIPTION)
    else:
        color_show_title = DEFAULT_COLOR_SHOW_TITLE
        color_description = DEFAULT_COLOR_DESCRIPTION

    whats_on = http.get(url = WHATS_ON, ttl_seconds = 30)

    if (whats_on.status_code) != 200:
        return render.Root(
            child = render.Column(
                children = [
                    RED_HEADER_BAR,
                    ERROR_CONTENT,
                ],
            ),
        )

    # Parse data
    has_current_show = whats_on.json()["current_show"]
    has_show_title = has_current_show and "show_title" in whats_on.json()["current_show"]
    has_title = has_current_show and "title" in whats_on.json()["current_show"]  # In cases where there isn't a "show_title" key in the API response, we'll use "title"
    has_description = has_current_show and "description" in whats_on.json()["current_show"]
    has_list_image = has_current_show and "listImage" in whats_on.json()["current_show"]
    has_group_image = has_current_show and "group_image" in whats_on.json()["current_show"]

    show_title = ""
    description = ""
    image_src = ""

    if has_current_show:
        if has_title:
            show_title = whats_on.json()["current_show"]["title"]
        if has_show_title:
            show_title = whats_on.json()["current_show"]["show_title"]

        description = has_description and normalize_description(whats_on.json()["current_show"]["description"])

        if has_list_image:
            image_src = http.get(whats_on.json()["current_show"]["listImage"]["url"]).body()
        if has_group_image:
            image_src = http.get(whats_on.json()["current_show"]["group_image"]).body()

    if not has_current_show or not show_title:
        return []  # If there's no show playing, we shouldn't show an empty screen, just return nothing

    root_contents = []
    data_parts = []

    if layout == "with_description":
        if show_title:
            data_parts.append(render.Padding(pad = 0, child = render.WrappedText(align = "center", width = 64, content = show_title, font = "tb-8", color = color_show_title)))
        if description:
            data_parts.append(render.Padding(pad = (0, 4, 0, 0), child = render.WrappedText(align = "center", width = 64, content = description, font = "tom-thumb", color = color_description)))

        root_contents = render.Marquee(
            scroll_direction = "vertical",
            height = 27,
            child = render.Column(children = data_parts),
        )

    if layout == "with_image":
        marquee_width = 64

        if image_src:
            marquee_width = 37  # The marquee needs to be narrower if we are showing the image next to it
            data_parts.append(render.Column(children = [render.Image(src = image_src, height = 26, width = 26) if image_src else None]))

        if show_title:
            data_parts.append(render.Column(main_align = "center", expanded = True, children = [render.Marquee(width = marquee_width, scroll_direction = "horizontal", child = render.Text(content = show_title, font = "tb-8", color = color_show_title))]))

        root_contents = render.Row(expanded = True, main_align = "space_between", children = data_parts)

    if layout == "with_name_only":
        if show_title:
            data_parts.append(render.Padding(pad = 0, child = render.WrappedText(align = "center", width = 64, content = show_title, font = "tb-8", color = color_show_title)))

        root_contents = render.Marquee(
            scroll_direction = "vertical",
            height = 27,
            child = render.Column(children = data_parts),
        )

    return render.Root(
        delay = 100 if layout == "with_description" else 0,
        child = render.Column(
            children = [
                RED_HEADER_BAR,
                root_contents,
            ],
        ),
    )

def normalize_description(description):
    return re.sub("<.*?>", "", description)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "stream",
                name = "Stream",
                desc = "Choose which stream to show info for",
                icon = "radio",
                options = STREAM_OPTIONS,
                default = DEFAULT_STREAM,
            ),
            schema.Dropdown(
                id = "layout",
                name = "Layout",
                desc = "Choose which layout to use for the info",
                icon = "image",
                options = LAYOUT_OPTIONS,
                default = DEFAULT_LAYOUT,
            ),
            schema.Toggle(
                id = "use_custom_colors",
                name = "Use custom colors",
                desc = "Choose your own text colors",
                icon = "palette",
                default = DEFAULT_USE_CUSTOM_COLORS,
            ),
            schema.Generated(
                id = "custom_colors",
                source = "use_custom_colors",
                handler = custom_colors,
            ),
        ],
    )

def custom_colors(use_custom_colors):
    if use_custom_colors == "true":  # Not a real Boolean, it's a string!
        return [
            schema.Color(
                id = "color_show_title",
                name = "Color: Show title",
                desc = "Choose your own color for the current show's title",
                icon = "palette",
                default = DEFAULT_COLOR_SHOW_TITLE,
                palette = [
                    COLORS["white"],
                    COLORS["red"],
                ],
            ),
            schema.Color(
                id = "color_description",
                name = "Color: Description",
                desc = "Choose your own color for the description of the current show",
                icon = "palette",
                default = DEFAULT_COLOR_DESCRIPTION,
                palette = [
                    COLORS["light_gray"],
                    COLORS["medium_gray"],
                    COLORS["dark_gray"],
                ],
            ),
        ]
    else:
        return []
