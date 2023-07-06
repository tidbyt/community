"""
Applet: WQXR
Summary: WQXR What's On
Description: Shows what's currently playing on WQXR, New York's Classical Music Radio Station.
Author: Andrew Westling
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

WHATS_ON = "https://api.wnyc.org/api/v1/whats_on/wqxr"

COLORS = {
    "dark_blue": "#12518A",
    "medium_blue": "#0162AB",
    "light_blue": "#00AEFF",
    "white": "#FFFFFF",
    "light_gray": "#AAAAAA",
    "medium_gray": "#888888",
    "dark_gray": "#444444",
    "red": "#FF0000",
}

DEFAULT_SHOW_ENSEMBLE = False
DEFAULT_SHOW_PEOPLE = True
DEFAULT_USE_CUSTOM_COLORS = False
DEFAULT_COLOR_TITLE = COLORS["light_blue"]
DEFAULT_COLOR_COMPOSER = COLORS["white"]
DEFAULT_COLOR_ENSEMBLE = COLORS["medium_gray"]
DEFAULT_COLOR_PEOPLE = COLORS["medium_gray"]

BLUE_HEADER_BAR = render.Stack(
    children = [
        render.Box(width = 64, height = 5, color = COLORS["dark_blue"]),
        render.Text(content = "WQXR", height = 6, font = "tom-thumb"),
    ],
)

ERROR_CONTENT = render.Column(
    expanded = True,
    main_align = "space_around",
    children = [
        render.Marquee(width = 64, child = render.Text(content = "Can't connect to WQXR :(", color = COLORS["red"])),
    ],
)

def main(config):
    whats_on = http.get(url = WHATS_ON, ttl_seconds = 30)

    if (whats_on.status_code) != 200:
        return render.Root(
            child = render.Column(
                children = [
                    BLUE_HEADER_BAR,
                    ERROR_CONTENT,
                ],
            ),
        )

    has_current_show = whats_on.json()["current_show"]
    has_playlist_item = whats_on.json()["current_playlist_item"]
    has_catalog_entry = has_playlist_item and whats_on.json()["current_playlist_item"]["catalog_entry"]

    title = ""
    composer = ""
    ensemble = ""
    people = ""

    if has_current_show:
        title = whats_on.json()["current_show"]["title"]

    if has_catalog_entry:
        title = has_catalog_entry and whats_on.json()["current_playlist_item"]["catalog_entry"]["title"]
        composer = has_catalog_entry and whats_on.json()["current_playlist_item"]["catalog_entry"]["composer"]["name"]

        # Ensemble
        has_ensemble = has_catalog_entry and whats_on.json()["current_playlist_item"]["catalog_entry"]["ensemble"]
        ensemble = has_ensemble and whats_on.json()["current_playlist_item"]["catalog_entry"]["ensemble"]["name"]

        # Conductor
        has_conductor = has_catalog_entry and whats_on.json()["current_playlist_item"]["catalog_entry"]["conductor"]
        conductor = has_conductor and whats_on.json()["current_playlist_item"]["catalog_entry"]["conductor"]["name"]

        # Soloists
        has_soloists = has_catalog_entry and len(whats_on.json()["current_playlist_item"]["catalog_entry"]["soloists"]) > 0
        soloists = has_soloists and whats_on.json()["current_playlist_item"]["catalog_entry"]["soloists"]

        people = build_people(conductor, soloists)

    use_custom_colors = config.bool("use_custom_colors", DEFAULT_USE_CUSTOM_COLORS)

    if use_custom_colors:
        color_title = config.str("color_title", DEFAULT_COLOR_TITLE)
        color_composer = config.str("color_composer", DEFAULT_COLOR_COMPOSER)
        color_ensemble = config.str("color_ensemble", DEFAULT_COLOR_ENSEMBLE)
        color_people = config.str("color_people", DEFAULT_COLOR_PEOPLE)
    else:
        color_title = DEFAULT_COLOR_TITLE
        color_composer = DEFAULT_COLOR_COMPOSER
        color_ensemble = DEFAULT_COLOR_ENSEMBLE
        color_people = DEFAULT_COLOR_PEOPLE

    children = []
    should_show_ensemble = config.bool("show_ensemble", DEFAULT_SHOW_ENSEMBLE)
    should_show_people = config.bool("show_people", DEFAULT_SHOW_PEOPLE)

    if title:
        children.append(render.Marquee(width = 64, child = render.Text(content = title, font = "tb-8", color = color_title)))
    if composer:
        children.append(render.Marquee(width = 64, child = render.Text(content = composer, font = "tom-thumb", color = color_composer)))
    if should_show_ensemble and ensemble:
        children.append(render.Marquee(width = 64, child = render.Text(content = ensemble, font = "tom-thumb", color = color_ensemble)))
    if should_show_people and people:
        children.append(render.Marquee(width = 64, child = render.Text(content = people, font = "tom-thumb", color = color_people)))

    return render.Root(
        max_age = 60,
        child = render.Column(
            children = [
                BLUE_HEADER_BAR,
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    children = children,
                ),
            ],
        ),
    )

def build_people(conductor, soloists):
    output = []

    if soloists:
        soloist_parts = []
        for soloist in soloists:
            soloist_parts.append("%s, %s" % (soloist["musician"]["name"], soloist["instruments"][0]))
        output.append(", ".join(soloist_parts))

    if conductor:
        output.append("%s, conductor" % (conductor))

    return ", ".join(output)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_ensemble",
                name = "Show ensemble",
                desc = "Show the ensemble, if applicable",
                icon = "peopleGroup",
                default = DEFAULT_SHOW_ENSEMBLE,
            ),
            schema.Toggle(
                id = "show_people",
                name = "Show conductor and soloists",
                desc = "Show the conductor and/or soloist(s), if applicable",
                icon = "wandMagicSparkles",
                default = DEFAULT_SHOW_PEOPLE,
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
                id = "color_title",
                name = "Color: Title",
                desc = "Choose your own color for the title of the current piece",
                icon = "palette",
                default = DEFAULT_COLOR_TITLE,
                palette = [
                    COLORS["white"],
                    COLORS["light_blue"],
                    COLORS["medium_blue"],
                ],
            ),
            schema.Color(
                id = "color_composer",
                name = "Color: Composer",
                desc = "Choose your own color for the composer of the current piece",
                icon = "palette",
                default = DEFAULT_COLOR_COMPOSER,
                palette = [
                    COLORS["white"],
                    COLORS["light_blue"],
                    COLORS["medium_blue"],
                    COLORS["dark_blue"],
                ],
            ),
            schema.Color(
                id = "color_ensemble",
                name = "Color: Ensemble",
                desc = "Choose your own color for the ensemble",
                icon = "palette",
                default = DEFAULT_COLOR_ENSEMBLE,
                palette = [
                    COLORS["white"],
                    COLORS["light_gray"],
                    COLORS["medium_gray"],
                    COLORS["dark_gray"],
                ],
            ),
            schema.Color(
                id = "color_people",
                name = "Color: Conductor/Soloists",
                desc = "Choose your own color for the conductor/soloists",
                icon = "palette",
                default = DEFAULT_COLOR_PEOPLE,
                palette = [
                    COLORS["white"],
                    COLORS["light_gray"],
                    COLORS["medium_gray"],
                    COLORS["dark_gray"],
                ],
            ),
        ]
    else:
        return []
