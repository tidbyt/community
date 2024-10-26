"""
Applet: API text
Summary: API text display
Description: Display text from an API endpoint.
Author: Michael Yagi
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PLEX_ICON = "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"
PLEX_BANNER = "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"

def main(config):
    random.seed(time.now().unix)

    plex_server_url = config.str("plex_server_url", "")
    plex_api_key = config.str("plex_api_key", "")
    font_color = config.str("font_color", "#FFFFFF")
    show_recent = config.bool("show_recent", True)
    show_added = config.bool("show_added", True)
    show_library = config.bool("show_library", True)
    filter_movie = config.bool("filter_movie", True)
    filter_tv = config.bool("filter_tv", True)
    filter_music = config.bool("filter_music", True)
    show_playing = config.bool("show_playing", False)
    fit_screen = config.bool("fit_screen", True)
    debug_output = config.bool("debug_output", False)

    ttl_seconds = 5

    plex_endpoints = []

    if show_playing == True:
        plex_endpoints.append({"title": "Now Playing", "endpoint": "/status/sessions"})

    if show_added == True:
        plex_endpoints.append({"title": "Recently Added", "endpoint": "/library/recentlyAdded"})

    if show_recent == True:
        plex_endpoints.append({"title": "Recently Played", "endpoint": "/status/sessions/history/all?sort=viewedAt:desc"})

    if show_library == True:
        plex_endpoints.append({"title": "Plex Library", "endpoint": "/library/sections"})

    endpoint_map = {"title": "Plex", "endpoint": ""}
    if len(plex_endpoints) > 0:
        endpoint_map = plex_endpoints[int(get_random_index("rand", plex_endpoints, debug_output))]

    if debug_output:
        print("------------------------------")
        print("CONFIG - plex_server_url: " + plex_server_url)
        print("CONFIG - plex_api_key: " + plex_api_key)
        print("CONFIG - ttl_seconds: " + str(ttl_seconds))
        print("CONFIG - debug_output: " + str(debug_output))
        print("CONFIG - endpoint_map: " + str(endpoint_map))
        print("CONFIG - show_recent: " + str(show_recent))
        print("CONFIG - show_added: " + str(show_added))
        print("CONFIG - show_playing: " + str(show_playing))
        print("CONFIG - filter_movie: " + str(filter_movie))
        print("CONFIG - filter_tv: " + str(filter_tv))
        print("CONFIG - filter_music: " + str(filter_music))
        print("CONFIG - font_color: " + font_color)
        print("CONFIG - fit_screen: " + str(fit_screen))

    return get_text(plex_server_url, plex_api_key, endpoint_map, debug_output, fit_screen, filter_movie, filter_tv, filter_music, font_color, ttl_seconds)

def get_text(plex_server_url, plex_api_key, endpoint_map, debug_output, fit_screen, filter_movie, filter_tv, filter_music, font_color, ttl_seconds):
    base_url = plex_server_url
    if base_url.endswith("/"):
        base_url = base_url[0:len(base_url) - 1]

    display_message_string = ""
    if plex_server_url == "" or plex_api_key == "":
        display_message_string = "Plex API URL and Plex API key must not be blank"
    elif endpoint_map["title"] == "Plex":
        display_message_string = "Select recent, added or played"
    else:
        headerMap = {
            "Accept": "application/json",
            "X-Plex-Token": plex_api_key,
        }

        api_endpoint = plex_server_url
        if plex_server_url.endswith("/"):
            api_endpoint = plex_server_url[0:len(plex_server_url) - 1] + endpoint_map["endpoint"]
        else:
            api_endpoint = plex_server_url + endpoint_map["endpoint"]

        # Get Plex API content
        content = get_data(api_endpoint, debug_output, headerMap, ttl_seconds)

        if content != None and len(content) > 0:
            output = json.decode(content, None)

            if output != None:
                output_keys = output.keys()
                valid_map = False
                for key in output_keys:
                    if debug_output:
                        print("key: " + str(key))
                    if key == "MediaContainer":
                        valid_map = True
                        break

                if valid_map == True:
                    marquee_text = endpoint_map["title"]
                    img = base64.decode(PLEX_BANNER)

                    if output["MediaContainer"]["size"] > 0:
                        metadata_list = []
                        if endpoint_map["title"] == "Plex Library":
                            if filter_movie or filter_music or filter_tv:
                                # Get random library
                                library_list = output["MediaContainer"]["Directory"]
                                allowable_media = []
                                if filter_movie:
                                    allowable_media.append("movie")
                                if filter_tv:
                                    allowable_media.append("show")
                                if filter_music:
                                    allowable_media.append("artist")

                                library_key = 0
                                if len(allowable_media) > 0:
                                    allowed_media = allowable_media[random.number(0, len(allowable_media) - 1)]
                                    for library in library_list:
                                        if library["type"] == allowed_media:
                                            library_key = library["key"]
                                            break

                                    library_url = base_url + "/library/sections/" + library_key + "/all"
                                    library_content = get_data(library_url, debug_output, headerMap, ttl_seconds)
                                    library_output = json.decode(library_content, None)
                                    if library_output != None and library_output["MediaContainer"]["size"] > 0:
                                        metadata_list = library_output["MediaContainer"]["Metadata"]
                                    else:
                                        display_message_string = "Could not get library content"
                                else:
                                    display_message_string = "Could not get library content"
                            else:
                                display_message_string = "All filters enabled"
                        elif filter_movie and filter_music and filter_tv:
                            metadata_list = output["MediaContainer"]["Metadata"]
                            if endpoint_map["title"] != "Plex Library" and len(metadata_list) > 9:
                                metadata_list = metadata_list[0:9]
                        else:
                            m_list = output["MediaContainer"]["Metadata"]
                            for metadata in m_list:
                                keys = metadata.keys()
                                is_clip = False
                                for key in keys:
                                    if key == "subtype" and metadata["subtype"] == "clip":
                                        is_clip = True
                                        break

                                if filter_movie and metadata["type"] == "movie" and is_clip == False:
                                    metadata_list.append(metadata)
                                if filter_tv and is_clip:
                                    metadata_list.append(metadata)
                                if filter_music and (metadata["type"] == "album" or metadata["type"] == "track" or metadata["type"] == "artist"):
                                    metadata_list.append(metadata)
                                if filter_tv and (metadata["type"] == "season" or metadata["type"] == "episode" or metadata["type"] == "show"):
                                    metadata_list.append(metadata)
                                if endpoint_map["title"] != "Plex Library" and len(metadata_list) > 9:
                                    break

                        if len(metadata_list) > 0:
                            random_index = random.number(0, len(metadata_list) - 1)
                            metadata_keys = metadata_list[random_index].keys()

                            if debug_output:
                                print("List size: " + str(len(metadata_list)))
                                print("Random index: " + str(random_index))

                            img = None
                            art_type = ""
                            img_url = ""

                            is_clip = False
                            for key in metadata_keys:
                                if key == "subtype" and metadata_list[random_index]["subtype"] == "clip":
                                    is_clip = True
                                    break

                            # thumb if art not available
                            validated_image = ""
                            for key in metadata_keys:
                                if key == "art":
                                    art_type = key
                                    img_url = base_url + metadata_list[random_index][art_type]
                                    img = get_data(img_url, debug_output, headerMap, ttl_seconds)
                                    if debug_output:
                                        print(key + " lookup")
                                    if img != None:
                                        validated_image = img
                                        break
                                if key == "parentArt":
                                    art_type = key
                                    img_url = base_url + metadata_list[random_index][art_type]
                                    img = get_data(img_url, debug_output, headerMap, ttl_seconds)
                                    if debug_output:
                                        print(key + " lookup")
                                    if img != None:
                                        validated_image = img
                                        break
                                if key == "grandparentArt":
                                    art_type = key
                                    img_url = base_url + metadata_list[random_index][art_type]
                                    img = get_data(img_url, debug_output, headerMap, ttl_seconds)
                                    if debug_output:
                                        print(key + " lookup")
                                    if img != None:
                                        validated_image = img
                                        break
                                elif key == "thumb" and metadata_list[random_index]["thumb"].endswith("/-1") == False:
                                    art_type = key
                                    img_url = base_url + metadata_list[random_index][art_type]
                                    img = get_data(img_url, debug_output, headerMap, ttl_seconds)
                                    if debug_output:
                                        print(key + " lookup")
                                    if img != None:
                                        validated_image = img
                                elif key == "parentThumb":
                                    art_type = key
                                    img_url = base_url + metadata_list[random_index][art_type]
                                    img = get_data(img_url, debug_output, headerMap, ttl_seconds)
                                    if debug_output:
                                        print(key + " lookup")
                                    if img != None:
                                        validated_image = img
                                elif key == "grandparentThumb":
                                    art_type = key
                                    img_url = base_url + metadata_list[random_index][art_type]
                                    img = get_data(img_url, debug_output, headerMap, ttl_seconds)
                                    if debug_output:
                                        print(key + " lookup")
                                    if img != None:
                                        validated_image = img

                            if img == None:
                                if len(validated_image) > 0:
                                    img = validated_image
                                    if debug_output:
                                        print("Using thumbnail type " + art_type + ": " + img_url)
                                else:
                                    if debug_output:
                                        print("Media image not detected, using Plex banner")
                                    img = base64.decode(PLEX_BANNER)
                            elif debug_output:
                                print("Using thumbnail type " + art_type + ": " + img_url)

                            media_type = "Movie"
                            if is_clip:
                                media_type = "Clip"
                            elif metadata_list[random_index]["type"] == "season" or metadata_list[random_index]["type"] == "episode" or metadata_list[random_index]["type"] == "show":
                                media_type = "Show"
                            elif metadata_list[random_index]["type"] == "album" or metadata_list[random_index]["type"] == "track" or metadata_list[random_index]["type"] == "artist":
                                media_type = "Music"
                            elif metadata_list[random_index]["type"] == "movie":
                                media_type = "Movie"

                            header_text = endpoint_map["title"] + " " + media_type

                            if debug_output:
                                print(header_text)

                            title = ""
                            parent_title = ""
                            grandparent_title = ""
                            for key in metadata_keys:
                                if key == "title":
                                    title = metadata_list[random_index][key]
                                elif key == "parentTitle":
                                    parent_title = metadata_list[random_index][key]
                                elif key == "grandparentTitle":
                                    grandparent_title = metadata_list[random_index][key]

                            if len(grandparent_title) > 0:
                                grandparent_title = grandparent_title + " - "
                            if len(parent_title) > 0:
                                parent_title = parent_title + ": "

                            body_text = grandparent_title + parent_title + title

                            marquee_text = header_text.strip() + " - " + body_text.strip()
                            max_length = 59
                            if len(marquee_text) > max_length:
                                marquee_text = body_text
                                if len(marquee_text) > max_length:
                                    marquee_text = marquee_text[0:max_length - 3] + "..."

                            if debug_output:
                                print("Marquee text: " + marquee_text)
                                print("Full title: " + header_text + " - " + body_text)
                        else:
                            display_message_string = "No results for " + endpoint_map["title"]

                    if fit_screen == True:
                        rendered_image = render.Image(
                            width = 64,
                            src = img,
                        )
                    else:
                        rendered_image = render.Image(
                            height = (32 - 7),
                            src = img,
                        )

                    return render_marquee(marquee_text, rendered_image, font_color)

                else:
                    display_message_string = "No valid results for " + endpoint_map["title"]
            else:
                display_message_string = "Possible malformed JSON for " + endpoint_map["title"]
        else:
            display_message_string = "Check API URL & key for " + endpoint_map["title"]

    return display_message(debug_output, display_message_string)

def display_message(debug_output, message = ""):
    img = base64.decode(PLEX_BANNER)

    if debug_output == False:
        return render.Root(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = img, width = 64),
                ],
            ),
        )
    else:
        if message == "":
            message = "Oops, something went wrong"

        rendered_image = render.Image(
            width = 64,
            src = img,
        )
        return render_marquee(message, rendered_image, "#FF0000")

def render_marquee(message, image, font_color):
    icon_img = base64.decode(PLEX_ICON)

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = icon_img, width = 7, height = 7),
                            render.Padding(
                                pad = (0, 1, 0, 0),
                                child = render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Marquee(
                                            scroll_direction = "horizontal",
                                            width = 64,
                                            offset_start = 64,
                                            offset_end = 64,
                                            child = render.Text(content = message, font = "tom-thumb", color = font_color),
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [image],
                    ),
                ),
            ],
        ),
    )

def get_random_index(item, a_list, debug_output):
    random_index = random.number(0, len(a_list) - 1)
    if debug_output:
        print("Random number for item " + item + ": " + str(random_index))
    return random_index

def get_data(url, debug_output, headerMap = {}, ttl_seconds = 20):
    res = None
    if headerMap != {}:
        res = http.get(url, headers = headerMap, ttl_seconds = ttl_seconds)
    else:
        res = http.get(url, ttl_seconds = ttl_seconds)

    if res == None:
        return None

    if debug_output:
        print("status: " + str(res.status_code))
        print("Requested url: " + str(url))

    if res.status_code != 200:
        return None
    else:
        data = res.body()

        return data

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "plex_server_url",
                name = "Plex Server URL (required)",
                desc = "Your Plex Server URL.",
                icon = "globe",
                default = "",
            ),
            schema.Text(
                id = "plex_api_key",
                name = "Plex API Key (required)",
                desc = "Your Plex API key.",
                icon = "key",
                default = "",
            ),
            schema.Text(
                id = "font_color",
                name = "Font color",
                desc = "Font color using Hex color codes. eg, `#FFFFFF`",
                icon = "paintbrush",
                default = "#FFFFFF",
            ),
            schema.Toggle(
                id = "fit_screen",
                name = "Fit screen",
                desc = "Fit image on screen.",
                icon = "arrowsLeftRightToLine",
                default = True,
            ),
            schema.Toggle(
                id = "debug_output",
                name = "Toggle debug messages",
                desc = "Toggle debug messages. Will display the messages on the display if enabled.",
                icon = "bug",
                default = False,
            ),
            schema.Toggle(
                id = "show_recent",
                name = "Show played",
                desc = "Show 10 last recently played.",
                icon = "arrowTrendUp",
                default = True,
            ),
            schema.Toggle(
                id = "show_added",
                name = "Show added",
                desc = "Show 10 last recently added.",
                icon = "arrowTrendUp",
                default = True,
            ),
            schema.Toggle(
                id = "show_playing",
                name = "Show playing",
                desc = "Show now playing.",
                icon = "play",
                default = False,
            ),
            schema.Toggle(
                id = "show_library",
                name = "Show library",
                desc = "Show Plex library.",
                icon = "layerGroup",
                default = True,
            ),
            schema.Toggle(
                id = "filter_movie",
                name = "Filter by movies",
                desc = "Show recently played.",
                icon = "film",
                default = True,
            ),
            schema.Toggle(
                id = "filter_tv",
                name = "Filter by shows",
                desc = "Show recently added.",
                icon = "tv",
                default = True,
            ),
            schema.Toggle(
                id = "filter_music",
                name = "Filter by music",
                desc = "Show now playing.",
                icon = "music",
                default = True,
            ),
        ],
    )
