"""
Applet: BBC Sounds
Summary: BBC Radio Stations
Description: Shows what's currently playing on BBC Radio stations from BBC Sounds.
Author: Andrew Westling
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# BBC Station configurations - Colors matched to official BBC Sounds branding
BBC_STATIONS = {
    "bbc_radio_one": {
        "name": "BBC Radio 1",
        "display_name": "Radio 1",
        "color": "#707070",  # Gray
        "text_color": "#FFFFFF",
    },
    "bbc_1xtra": {
        "name": "BBC Radio 1Xtra",
        "display_name": "1Xtra",
        "color": "#606060",  # Gray
        "text_color": "#FFFFFF",
    },
    "bbc_radio_two": {
        "name": "BBC Radio 2",
        "display_name": "Radio 2",
        "color": "#FF6600",  # Orange
        "text_color": "#FFFFFF",
    },
    "bbc_radio_three": {
        "name": "BBC Radio 3",
        "display_name": "Radio 3",
        "color": "#FF0000",  # Red
        "text_color": "#FFFFFF",
    },
    "bbc_radio_three_unwind": {
        "name": "BBC Radio 3 Unwind",
        "display_name": "Radio 3 Unwind",
        "color": "#FF0000",  # Red (same as Radio 3)
        "text_color": "#FFFFFF",
    },
    "bbc_radio_fourfm": {
        "name": "BBC Radio 4",
        "display_name": "Radio 4",
        "color": "#0066FF",  # Blue
        "text_color": "#FFFFFF",
    },
    "bbc_radio_four_extra": {
        "name": "BBC Radio 4 Extra",
        "display_name": "Radio 4 Extra",
        "color": "#0066FF",  # Blue
        "text_color": "#FFFFFF",
    },
    "bbc_radio_five_live": {
        "name": "BBC Radio 5 Live",
        "display_name": "5 Live",
        "color": "#008888",  # Darker Cyan/Teal
        "text_color": "#FFFFFF",
    },
    "bbc_radio_five_live_sports_extra": {
        "name": "BBC Radio 5 Sports Extra",
        "display_name": "5 Sports Extra",
        "color": "#008888",  # Darker Cyan/Teal
        "text_color": "#FFFFFF",
    },
    "bbc_6music": {
        "name": "BBC Radio 6 Music",
        "display_name": "6 Music",
        "color": "#008800",  # Darker Green
        "text_color": "#FFFFFF",
    },
    "bbc_asian_network": {
        "name": "BBC Asian Network",
        "display_name": "Asian Network",
        "color": "#FF00CC",  # Pink/Magenta
        "text_color": "#FFFFFF",
    },
    "bbc_world_service": {
        "name": "BBC World Service",
        "display_name": "World Service",
        "color": "#CC0000",  # Dark Red
        "text_color": "#FFFFFF",
    },
    "bbc_radio_scotland_fm": {
        "name": "BBC Radio Scotland",
        "display_name": "Radio Scotland",
        "color": "#6600CC",  # Purple
        "text_color": "#FFFFFF",
    },
    "bbc_radio_ulster": {
        "name": "BBC Radio Ulster",
        "display_name": "Radio Ulster",
        "color": "#00AA00",  # Green
        "text_color": "#FFFFFF",
    },
    "bbc_radio_wales_fm": {
        "name": "BBC Radio Wales",
        "display_name": "Radio Wales",
        "color": "#FF6600",  # Orange
        "text_color": "#FFFFFF",
    },
    "bbc_radio_cymru": {
        "name": "BBC Radio Cymru",
        "display_name": "Radio Cymru",
        "color": "#0066FF",  # Blue
        "text_color": "#FFFFFF",
    },
}

DISPLAY_MODE_OPTIONS = [
    schema.Option(
        display = "Show Current Track",
        value = "segments",
    ),
    schema.Option(
        display = "Show Programme",
        value = "broadcasts",
    ),
]

SCROLL_DIRECTION_OPTIONS = [
    schema.Option(
        display = "Vertical",
        value = "vertical",
    ),
    schema.Option(
        display = "Horizontal",
        value = "horizontal",
    ),
]

SCROLL_SPEED_OPTIONS = [
    schema.Option(
        display = "Fast",
        value = "0",
    ),
    schema.Option(
        display = "Slower",
        value = "100",
    ),
    schema.Option(
        display = "Slowest",
        value = "200",
    ),
]

STATION_OPTIONS = [
    schema.Option(
        display = station_config["name"],
        value = station_id,
    )
    for station_id, station_config in BBC_STATIONS.items()
]

DEFAULT_STATION = "bbc_radio_three"
DEFAULT_DISPLAY_MODE = DISPLAY_MODE_OPTIONS[0].value
DEFAULT_SCROLL_DIRECTION = SCROLL_DIRECTION_OPTIONS[0].value
DEFAULT_SCROLL_SPEED = SCROLL_SPEED_OPTIONS[0].value
DEFAULT_USE_CUSTOM_COLORS = False

COLORS = {
    "white": "#FFFFFF",
    "light_gray": "#AAAAAA",
    "medium_gray": "#888888",
    "dark_gray": "#444444",
    "error_red": "#FF0000",
}

def get_header_bar(station_id):
    station_config = BBC_STATIONS.get(station_id, BBC_STATIONS[DEFAULT_STATION])
    return render.Stack(
        children = [
            render.Box(width = 64, height = 5, color = station_config["color"]),
            render.Text(
                content = station_config["display_name"],
                height = 6,
                font = "tom-thumb",
                color = station_config["text_color"],
            ),
        ],
    )

def get_error_content(station_id):
    station_config = BBC_STATIONS.get(station_id, BBC_STATIONS[DEFAULT_STATION])
    return render.Column(
        expanded = True,
        main_align = "space_around",
        children = [
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = "Can't connect to {} :(".format(station_config["name"]),
                    color = COLORS["error_red"],
                ),
            ),
        ],
    )

def main(config):
    # Get settings values
    station_id = config.str("station", DEFAULT_STATION)
    display_mode = config.str("display_mode", DEFAULT_DISPLAY_MODE)
    scroll_direction = config.str("scroll_direction", DEFAULT_SCROLL_DIRECTION)
    scroll_speed = int(config.str("scroll_speed", DEFAULT_SCROLL_SPEED))

    # Get station configuration
    if station_id not in BBC_STATIONS:
        station_id = DEFAULT_STATION

    station_config = BBC_STATIONS[station_id]

    # Choose endpoint based on display mode
    if display_mode == "broadcasts":
        endpoint = "https://rms.api.bbc.co.uk/v2/broadcasts/latest?service={}&on_air=now".format(station_id)

    else:
        endpoint = "https://rms.api.bbc.co.uk/v2/services/{}/segments/latest".format(station_id)

    # Get data
    whats_on = http.get(url = endpoint, ttl_seconds = 30)

    if (whats_on.status_code) != 200:
        return render.Root(
            child = render.Column(
                children = [
                    get_header_bar(station_id),
                    get_error_content(station_id),
                ],
            ),
        )

    # Parse data
    data = whats_on.json()
    has_data = data and "data" in data and len(data["data"]) > 0

    title = ""
    detail = ""
    should_fallback_to_broadcasts = False

    if has_data:
        if display_mode == "broadcasts":
            # Handle broadcast data
            broadcast = data["data"][0]
            programme = broadcast.get("programme", {})
            titles = programme.get("titles", {})

            # For broadcasts, use primary (programme name) and secondary (episode title)
            title = titles.get("primary", "") or ""
            detail = titles.get("secondary", "") or ""

            # Add tertiary information if available
            tertiary = titles.get("tertiary", "") or ""
            if tertiary and detail:
                detail = detail + " - " + tertiary
            elif tertiary and not detail:
                detail = tertiary

            # If no secondary/tertiary title, use synopsis short as subtitle
            if not detail:
                synopses = programme.get("synopses", {})
                detail = synopses.get("short", "") or ""
        else:
            # Handle segments data - look for currently playing item
            current_item = None
            for item in data["data"]:
                if item.get("offset", {}).get("now_playing", False):
                    current_item = item
                    break

            # If we found a currently playing item, use it
            if current_item:
                titles = current_item.get("titles", {})

                if current_item.get("segment_type") == "music":
                    # For music: primary is usually composer, secondary is piece title
                    detail = titles.get("primary", "") or ""
                    title = titles.get("secondary", "") or ""

                    # If no secondary title, use primary as title and clear detail
                    if not title and detail:
                        title = detail
                        detail = ""
                elif current_item.get("segment_type") == "speech":
                    # For speech segments: use primary as title, secondary as subtitle/description
                    title = titles.get("primary", "") or ""
                    detail = titles.get("secondary", "") or ""
                else:
                    # Fallback for unknown segment types
                    title = titles.get("primary", "") or titles.get("secondary", "") or ""
                    detail = ""
            else:
                # No currently playing item found, fallback to broadcasts
                should_fallback_to_broadcasts = True

    # If segments mode but no good data, fallback to broadcasts API
    if display_mode == "segments" and (not has_data or should_fallback_to_broadcasts or (not title and not detail)):
        broadcasts_endpoint = "https://rms.api.bbc.co.uk/v2/broadcasts/latest?service={}&on_air=now".format(station_id)
        broadcasts_response = http.get(url = broadcasts_endpoint, ttl_seconds = 30)

        if broadcasts_response.status_code == 200:
            broadcasts_data = broadcasts_response.json()
            if broadcasts_data and "data" in broadcasts_data and len(broadcasts_data["data"]) > 0:
                broadcast = broadcasts_data["data"][0]
                programme = broadcast.get("programme", {})
                titles = programme.get("titles", {})

                # Use broadcast data as fallback
                title = titles.get("primary", "") or ""
                detail = titles.get("secondary", "") or ""

                # Add tertiary information if available
                tertiary = titles.get("tertiary", "") or ""
                if tertiary and detail:
                    detail = detail + " - " + tertiary
                elif tertiary and not detail:
                    detail = tertiary

                # If no secondary/tertiary title, use synopsis short as subtitle
                if not detail:
                    synopses = programme.get("synopses", {})
                    detail = synopses.get("short", "") or ""

    # Handle colors
    color_title = station_config["color"]
    color_details = COLORS["white"]

    # These are just for putting the content into
    root_contents = None
    data_parts = []

    # Vertical scrolling
    if scroll_direction == "vertical":
        # For vertical mode, each child needs to be a WrappedText widget, so the text will wrap to the next line

        # (I also wrap each child in a Padding widget with appropriate spacing, so things can breathe a little bit)
        pad = (0, 4, 0, 0)  # (left, top, right, bottom)

        if title:
            # Don't pad the top one because it doesn't need it
            data_parts.append(render.Padding(pad = 0, child = render.WrappedText(align = "center", width = 64, content = title, font = "tb-8", color = color_title)))
        if detail:
            data_parts.append(render.Padding(pad = pad, child = render.WrappedText(align = "center", width = 64, content = detail, font = "tom-thumb", color = color_details)))

        root_contents = render.Marquee(
            scroll_direction = "vertical",
            height = 27,
            child = render.Column(children = data_parts),
        )

    # Horizontal scrolling
    if scroll_direction == "horizontal":
        # For horizontal mode, each child needs to be its own Marquee widget, so each line will scroll individually when too long
        if title:
            data_parts.append(render.Marquee(width = 64, child = render.Text(content = title, font = "tb-8", color = color_title)))
        if detail:
            data_parts.append(render.Marquee(width = 64, child = render.Text(content = detail, font = "tom-thumb", color = color_details)))

        root_contents = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = data_parts,
        )

    return render.Root(
        delay = scroll_speed,
        child = render.Column(
            children = [
                get_header_bar(station_id),
                root_contents,
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "BBC Radio Station",
                desc = "Choose which BBC Radio station to display",
                icon = "radio",
                options = STATION_OPTIONS,
                default = DEFAULT_STATION,
            ),
            schema.Dropdown(
                id = "display_mode",
                name = "Display Mode",
                desc = "Choose what to display: current track details or programme information",
                icon = "radio",
                options = DISPLAY_MODE_OPTIONS,
                default = DEFAULT_DISPLAY_MODE,
            ),
            schema.Dropdown(
                id = "scroll_direction",
                name = "Scroll direction",
                desc = "Choose whether to scroll text horizontally or vertically",
                icon = "alignJustify",
                options = SCROLL_DIRECTION_OPTIONS,
                default = DEFAULT_SCROLL_DIRECTION,
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll speed",
                desc = "Slow down the scroll speed of the text",
                icon = "gauge",
                options = SCROLL_SPEED_OPTIONS,
                default = DEFAULT_SCROLL_SPEED,
            ),
        ],
    )
