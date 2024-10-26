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

PLEX_ICON = "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKBAMAAAB/HNKOAAAAGFBMVEUoKi1uVSCkdxfNkRBHPSfjnw2GZB1COihvAeTOAAAAIElEQVQI12NggADGFDAZBOaoCoBIZ3MECRaByEJUggAAU9YCzwgwGNcAAAAASUVORK5CYII="
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
