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

DEFAULT_COLOR_TITLE = COLORS["light_blue"]
DEFAULT_COLOR_COMPOSER = COLORS["white"]
DEFAULT_COLOR_ENSEMBLE_AND_PEOPLE = COLORS["medium_gray"]

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

    children = []
    should_show_ensemble = config.bool("show_ensemble")
    should_show_people = config.bool("show_people")

    if title:
        children.append(render.Marquee(width = 64, child = render.Text(content = title, font = "tb-8", color = config.str("color_title", DEFAULT_COLOR_TITLE))))
    if composer:
        children.append(render.Marquee(width = 64, child = render.Text(content = composer, font = "tom-thumb", color = config.str("color_composer", DEFAULT_COLOR_COMPOSER))))
    if should_show_ensemble and ensemble:
        children.append(render.Marquee(width = 64, child = render.Text(content = ensemble, font = "tom-thumb", color = config.str("color_ensemble_and_people", DEFAULT_COLOR_ENSEMBLE_AND_PEOPLE))))
    if should_show_people and people:
        children.append(render.Marquee(width = 64, child = render.Text(content = people, font = "tom-thumb", color = config.str("color_ensemble_and_people", DEFAULT_COLOR_ENSEMBLE_AND_PEOPLE))))

    return render.Root(
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

    if conductor:
        output.append("%s, conductor" % (conductor))

    if soloists:
        soloist_parts = []
        for soloist in soloists:
            soloist_parts.append("%s, %s" % (soloist["musician"]["name"], soloist["instruments"][0]))
        output.append(", ".join(soloist_parts))

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
                default = False,
            ),
            schema.Toggle(
                id = "show_people",
                name = "Show conductor and soloists",
                desc = "Show the conductor and/or soloist(s), if applicable",
                icon = "wandMagicSparkles",
                default = True,
            ),
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
                id = "color_ensemble_and_people",
                name = "Color: Ensemble and Conductor/Soloists",
                desc = "Choose your own color for the ensemble and conductor/soloists",
                icon = "palette",
                default = DEFAULT_COLOR_ENSEMBLE_AND_PEOPLE,
                palette = [
                    COLORS["white"],
                    COLORS["light_gray"],
                    COLORS["medium_gray"],
                    COLORS["dark_gray"],
                ],
            ),
        ],
    )
