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

PLEX_ICON = "/9j/4AAQSkZJRgABAQEAwADAAAD/4QBoRXhpZgAATU0AKgAAAAgABAEaAAUAAAABAAAAPgEbAAUAAAABAAAARgEoAAMAAAABAAIAAAExAAIAAAARAAAATgAAAAAAAADAAAAAAQAAAMAAAAABcGFpbnQubmV0IDUuMC4xMwAA/9sAQwABAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB/9sAQwEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB/8AAEQgACgAKAwESAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/aAAwDAQACEQMRAD8A/nv/AGavgD8JPiR+xD+2B8VPi/4T/wCFey/CVtHv/g1+0v8A2x4rk/4Sb4sXFrbNbfsvf8ID/bf/AAi3i/8A4TC1NjqH/CQ6FoFv4k+GH9vf8JT4y1e/8IzaZplt+a9fn/EPB+eZzxdwxxFl/Gub8PZZkUayzHIctjiKlDiL2k3KNHMI4vMq2Rxw8I3p8/8Aq5WzNQqVXRzShUjgp4L3MDmuDwmV5jga+UYXHYjGuLw+NxDpxngOVJOVB08PHFucmuZr69GheMb4eUXWVcor9APDP//Z"
PLEX_BANNER = "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"
PLEX_BANNER_PORTRAIT = "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"
MAX_TEXT_LENGTH = 1000
GET_TOP = 15

def main(config):
    random.seed(time.now().unix)

    plex_server_url = config.str("plex_server_url", "")
    plex_token = config.str("plex_token", "")
    show_heading = config.bool("show_heading", True)
    show_only_artwork = config.bool("show_only_artwork", False)
    heading_color = config.str("heading_color", "#FFA500")
    font_color = config.str("font_color", "#FFFFFF")
    show_summary = config.bool("show_summary", False)
    show_recent = config.bool("show_recent", True)
    show_added = config.bool("show_added", True)
    show_library = config.bool("show_library", True)
    filter_movie = config.bool("filter_movie", True)
    filter_tv = config.bool("filter_tv", True)
    filter_music = config.bool("filter_music", True)
    show_playing = config.bool("show_playing", False)
    fit_screen = config.bool("fit_screen", True)
    debug_output = config.bool("debug_output", False)

    if show_only_artwork:
        show_heading = False
        show_summary = False

    ttl_seconds = 5

    plex_endpoints = []

    if show_playing == True:
        plex_endpoints.append({"title": "Playing", "endpoint": "/status/sessions", "id": 1})

    if show_added == True:
        plex_endpoints.append({"title": "Added", "endpoint": "/library/recentlyAdded", "id": 2})

    if show_recent == True:
        plex_endpoints.append({"title": "Played", "endpoint": "/status/sessions/history/all?sort=viewedAt:desc", "id": 3})

    if show_library == True:
        plex_endpoints.append({"title": "Library", "endpoint": "/library/sections", "id": 4})

    endpoint_map = {"title": "None", "endpoint": "", "id": 0}
    if len(plex_endpoints) > 0:
        random_endpoint_index = random.number(0, len(plex_endpoints) - 1)
        endpoint_map = plex_endpoints[random_endpoint_index]

    if debug_output:
        print("------------------------------")
        print("CONFIG - plex_server_url: " + plex_server_url)
        print("CONFIG - plex_token: " + plex_token)
        print("CONFIG - ttl_seconds: " + str(ttl_seconds))
        print("CONFIG - debug_output: " + str(debug_output))
        print("CONFIG - endpoint_map: " + str(endpoint_map))
        print("CONFIG - show_summary: " + str(show_summary))
        print("CONFIG - show_recent: " + str(show_recent))
        print("CONFIG - show_added: " + str(show_added))
        print("CONFIG - show_playing: " + str(show_playing))
        print("CONFIG - filter_movie: " + str(filter_movie))
        print("CONFIG - filter_tv: " + str(filter_tv))
        print("CONFIG - filter_music: " + str(filter_music))
        print("CONFIG - show_heading: " + str(show_heading))
        print("CONFIG - show_only_artwork: " + str(show_only_artwork))
        print("CONFIG - heading_color: " + heading_color)
        print("CONFIG - font_color: " + font_color)
        print("CONFIG - fit_screen: " + str(fit_screen))

    return get_text(plex_server_url, plex_token, endpoint_map, debug_output, fit_screen, filter_movie, filter_tv, filter_music, show_heading, show_only_artwork, show_summary, heading_color, font_color, ttl_seconds)

def get_text(plex_server_url, plex_token, endpoint_map, debug_output, fit_screen, filter_movie, filter_tv, filter_music, show_heading, show_only_artwork, show_summary, heading_color, font_color, ttl_seconds):
    base_url = plex_server_url
    if base_url.endswith("/"):
        base_url = base_url[0:len(base_url) - 1]

    display_message_string = ""
    if plex_server_url == "" or plex_token == "":
        display_message_string = "Plex API URL and Plex API key must not be blank"
    elif endpoint_map["id"] == 0:
        display_message_string = "Select recent, added, library or playing"
    elif filter_movie == False and filter_music == False and filter_tv == False:
        display_message_string = "Select at least 1 filter"
    else:
        headerMap = {
            "Accept": "application/json",
            "X-Plex-Token": plex_token,
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
                valid_parent_map = False
                for key in output_keys:
                    if key == "MediaContainer":
                        valid_parent_map = True
                        break

                if valid_parent_map == True:
                    using_portrait_banner = False

                    marquee_text_array = [
                        {"type": "heading", "message": endpoint_map["title"], "color": heading_color},
                        {"type": "title", "message": "Not Available", "color": font_color},
                        {"type": "body", "message": "Not Available", "color": font_color},
                    ]

                    if show_summary:
                        img = base64.decode(PLEX_BANNER_PORTRAIT)
                    else:
                        img = base64.decode(PLEX_BANNER)

                    # Get media list and filter
                    if output["MediaContainer"]["size"] > 0:
                        # Check if has needed keys
                        valid_media_container_key = False
                        media_container_keys = output["MediaContainer"].keys()
                        for media_container_key in media_container_keys:
                            if endpoint_map["id"] == 4 and media_container_key == "Directory":
                                valid_media_container_key = True
                                break
                            elif (endpoint_map["id"] == 1 or endpoint_map["id"] == 2 or endpoint_map["id"] == 3) and media_container_key == "Metadata":
                                valid_media_container_key = True
                                break

                        if valid_media_container_key:
                            metadata_list = []
                            library_type = ""
                            if endpoint_map["id"] == 4:
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
                                                library_type = library["type"]
                                                library_key = library["key"]
                                                break

                                        #  1 = movie 2 = show 3 = season 4 = episode
                                        media_type = ""
                                        library_type_enum = 0
                                        if library_type == "movie":
                                            media_type = "Movie"
                                        elif library_type == "show":
                                            # Try to find episodes
                                            library_type_enum = 4
                                            media_type = "TV Show"
                                        elif library_type == "artist":
                                            media_type = "Music"

                                        library_url = base_url + "/library/sections/" + library_key + "/all"
                                        if library_type_enum > 0:
                                            library_url = base_url + "/library/sections/" + library_key + "/all?type=" + str(library_type_enum)

                                        library_content = get_data(library_url, debug_output, headerMap, ttl_seconds)
                                        library_output = json.decode(library_content, None)
                                        if library_output != None and library_output["MediaContainer"]["size"] > 0:
                                            metadata_list = library_output["MediaContainer"]["Metadata"]
                                        else:
                                            display_message_string = "No results for " + endpoint_map["title"] + " " + media_type
                                            return display_message(debug_output, [{"message": display_message_string, "color": font_color}])
                                    else:
                                        display_message_string = "No results for " + endpoint_map["title"]
                                        return display_message(debug_output, [{"message": display_message_string, "color": "#FF0000"}])
                                else:
                                    display_message_string = "All filters enabled"
                                    return display_message(debug_output, [{"message": display_message_string, "color": "#FF0000"}])
                            elif filter_movie and filter_music and filter_tv:
                                metadata_list = output["MediaContainer"]["Metadata"]
                                if endpoint_map["id"] != 4 and len(metadata_list) > GET_TOP:
                                    metadata_list = metadata_list[0:GET_TOP]
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
                                    if endpoint_map["id"] != 4 and len(metadata_list) > GET_TOP:
                                        break

                            # Process text
                            if len(metadata_list) > 0:
                                random_index = random.number(0, len(metadata_list) - 1)
                                if library_type == "artist":
                                    # Try to find albums
                                    library_content = get_data(base_url + metadata_list[random_index]["key"], debug_output, headerMap, ttl_seconds)
                                    library_output = json.decode(library_content, None)
                                    if library_output != None and library_output["MediaContainer"]["size"] > 0:
                                        metadata_list = library_output["MediaContainer"]["Metadata"]
                                        random_index = random.number(0, len(metadata_list) - 1)

                                metadata_keys = metadata_list[random_index].keys()

                                if debug_output:
                                    print("List size: " + str(len(metadata_list)))
                                    print("Random index: " + str(random_index))

                                is_clip = False
                                for key in metadata_keys:
                                    if key == "subtype" and metadata_list[random_index]["subtype"] == "clip":
                                        is_clip = True
                                        break

                                # Relabel
                                media_type = "Movie"
                                if is_clip:
                                    media_type = "Clip"
                                elif metadata_list[random_index]["type"] == "season" or metadata_list[random_index]["type"] == "episode" or metadata_list[random_index]["type"] == "show":
                                    media_type = "TV Show"
                                elif metadata_list[random_index]["type"] == "album" or metadata_list[random_index]["type"] == "track" or metadata_list[random_index]["type"] == "artist":
                                    media_type = "Music"
                                elif metadata_list[random_index]["type"] == "movie":
                                    media_type = "Movie"

                                # Find title
                                header_text = ""
                                if show_heading:
                                    header_text = media_type + " " + endpoint_map["title"]

                                header_text = header_text.strip()

                                if debug_output:
                                    print("header_text: " + header_text)

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

                                # Find summary
                                title_text = ""
                                if show_summary:
                                    title_text = grandparent_title + parent_title + title
                                    title_text = title_text.strip()
                                    contains_summary = False
                                    has_key = False
                                    for m_key in metadata_list[random_index].keys():
                                        if m_key == "summary" and len(metadata_list[random_index][m_key].strip()) > 0:
                                            contains_summary = True

                                        if m_key == "key":
                                            has_key = True

                                    # Check if summary exists
                                    if contains_summary == False and has_key:
                                        child_metadata = get_data(base_url + metadata_list[random_index]["key"], debug_output, headerMap, ttl_seconds)
                                        child_metadata_output = json.decode(child_metadata, None)

                                        if child_metadata_output != None:
                                            valid = False
                                            for m_key in child_metadata_output.keys():
                                                if m_key == "MediaContainer":
                                                    valid = True
                                                    break
                                            if valid and child_metadata_output["MediaContainer"]["size"] > 0:
                                                child_metadata_first = child_metadata_output["MediaContainer"]["Metadata"][0]
                                                for m_key in child_metadata_first.keys():
                                                    if m_key == "summary" and len(child_metadata_first[m_key].strip()) > 0:
                                                        metadata_list[random_index][m_key] = child_metadata_first[m_key].strip()
                                                        contains_summary = True
                                                        break

                                    body_text = ""
                                    if contains_summary:
                                        body_text = metadata_list[random_index]["summary"]
                                    else:
                                        body_text = grandparent_title + parent_title + title
                                        body_text = body_text.strip()
                                        show_summary = False
                                        if debug_output:
                                            print("body_text: " + body_text)
                                    if debug_output:
                                        print("title_text: " + title_text)

                                        output_str = body_text[0:len(body_text)]
                                        if len(output_str) > 200:
                                            output_str = output_str[0:200] + "..."

                                        print("body_text: " + output_str)
                                else:
                                    body_text = grandparent_title + parent_title + title
                                    body_text = body_text.strip()
                                    if debug_output:
                                        print("body_text: " + body_text)

                                if len(title_text) >= MAX_TEXT_LENGTH:
                                    title_text = title_text[0:MAX_TEXT_LENGTH] + "..."
                                    print("Title text truncated")

                                if len(body_text) >= MAX_TEXT_LENGTH:
                                    body_text = body_text[0:MAX_TEXT_LENGTH] + "..."
                                    print("Body text truncated")

                                # Find art
                                image_map = find_valid_image(metadata_list[random_index], base_url, debug_output, headerMap, show_summary, ttl_seconds)
                                img = image_map["img"]
                                art_type = image_map["art_type"]
                                img_url = image_map["img_url"]
                                validated_image = image_map["validated_image"]

                                # If art/thumb not found, try to look for specific metadata art/thumb
                                if (show_summary and (art_type == "art" or art_type == "parentArt" or art_type == "grandparentArt")) or (show_summary == False and (art_type == "thumb" or art_type == "parentThumb" or art_type == "grandparentThumb")):
                                    if debug_output:
                                        if show_summary:
                                            print("Only art found, looking further for thumbnails")
                                        else:
                                            print("Only thumbnails found, looking further for art")
                                    single_metadata = base_url + metadata_list[random_index]["key"]
                                    single_metadata_json = get_data(single_metadata, debug_output, headerMap, ttl_seconds)
                                    metadata_output = json.decode(single_metadata_json, None)

                                    if metadata_output != None:
                                        valid = False
                                        for m_key in metadata_output.keys():
                                            if m_key == "MediaContainer":
                                                valid = True
                                        if valid and metadata_output["MediaContainer"]["size"] > 0:
                                            sub_image_map = find_valid_image(metadata_output["MediaContainer"]["Metadata"][0], base_url, debug_output, headerMap, show_summary, ttl_seconds)
                                            sub_img = sub_image_map["img"]
                                            sub_art_type = sub_image_map["art_type"]
                                            sub_img_url = sub_image_map["img_url"]
                                            sub_validated_image = sub_image_map["validated_image"]

                                            if (show_summary == False and (sub_art_type == "art" or sub_art_type == "parentArt" or sub_art_type == "grandparentArt")) or (show_summary and (sub_art_type == "thumb" or sub_art_type == "parentThumb" or sub_art_type == "grandparentThumb")):
                                                if debug_output:
                                                    print("Identified art in metadata")
                                                img = sub_img
                                                art_type = sub_art_type
                                                img_url = sub_img_url
                                                validated_image = sub_validated_image

                                if img == None:
                                    if len(validated_image) > 0:
                                        img = validated_image
                                        if debug_output:
                                            print("Using image type " + art_type + ": " + img_url)
                                    else:
                                        if debug_output:
                                            print("Media image not detected, using Plex banner")
                                        if show_summary:
                                            using_portrait_banner = True
                                            img = base64.decode(PLEX_BANNER_PORTRAIT)
                                        else:
                                            img = base64.decode(PLEX_BANNER)
                                elif debug_output:
                                    print("Using image type " + art_type + ": " + img_url)

                                if show_summary:
                                    marquee_text_array = [
                                        {"type": "heading", "message": header_text, "color": "#FFFFFF"},
                                        {"type": "title", "message": title_text, "color": heading_color},
                                        {"type": "body", "message": body_text, "color": font_color},
                                    ]
                                else:
                                    marquee_text_array = [
                                        {"type": "heading", "message": header_text, "color": heading_color},
                                        {"type": "body", "message": body_text, "color": font_color},
                                    ]

                                if debug_output and show_summary == False:
                                    print("Full title: " + header_text + " " + body_text)
                        else:
                            display_message_string = "No results for " + endpoint_map["title"]
                            return display_message(debug_output, [{"message": display_message_string, "color": "#FF0000"}])

                    # img = base64.decode(PLEX_BANNER_PORTRAIT)
                    # using_portrait_banner = True

                    if show_summary and show_only_artwork == False:
                        rendered_image = render.Image(
                            width = 22,
                            src = img,
                        )
                    elif fit_screen and show_only_artwork == False:
                        rendered_image = render.Image(
                            width = 64,
                            src = img,
                        )
                    elif fit_screen and show_only_artwork == True:
                        rendered_image = render.Image(
                            height = 32,
                            src = img,
                        )
                    elif fit_screen == False and show_only_artwork == True:
                        rendered_image = render.Image(
                            width = 64,
                            src = img,
                        )
                    else:
                        rendered_image = render.Image(
                            height = (32 - 7),
                            src = img,
                        )

                    return render_marquee(show_only_artwork, marquee_text_array, rendered_image, show_summary, debug_output, using_portrait_banner)

                else:
                    display_message_string = "No valid results for " + endpoint_map["title"]
            else:
                display_message_string = "Possible malformed JSON for " + endpoint_map["title"]
        else:
            display_message_string = "Check API URL & key for " + endpoint_map["title"]

    return display_message(debug_output, [{"message": display_message_string, "color": "#FF0000"}])

def find_valid_image(metadata, base_url, debug_output, headerMap, show_summary, ttl_seconds):
    img = None
    art_type = ""
    img_url = ""

    metadata_keys = metadata.keys()

    # thumb if art not available
    img = None
    valid_image = {
        "art": False,
        "parentArt": False,
        "grandparentArt": False,
        "thumb": False,
        "parentThumb": False,
        "grandparentThumb": False,
    }

    for key in metadata_keys:
        if key == "art" or key == "parentArt" or key == "grandparentArt" or (key == "thumb" and metadata["thumb"].endswith("/-1") == False) or key == "parentThumb" or key == "grandparentThumb":
            valid_image[key] = True

    # if show_summary is true, prioritize thumbs
    if show_summary:
        if metadata["type"] == "album" or metadata["type"] == "track" or metadata["type"] == "artist":
            if valid_image["thumb"] == True:
                art_type = "thumb"
                img_url = base_url + metadata[art_type]
                img = get_data(img_url, debug_output, headerMap, ttl_seconds)

            if valid_image["parentThumb"] == True and img == None:
                art_type = "parentThumb"
                img_url = base_url + metadata[art_type]
                img = get_data(img_url, debug_output, headerMap, ttl_seconds)
        else:
            if valid_image["parentThumb"] == True:
                art_type = "parentThumb"
                img_url = base_url + metadata[art_type]
                img = get_data(img_url, debug_output, headerMap, ttl_seconds)

            if valid_image["thumb"] == True and img == None:
                art_type = "thumb"
                img_url = base_url + metadata[art_type]
                img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["grandparentThumb"] == True and img == None:
            art_type = "grandparentThumb"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["art"] == True and img == None:
            art_type = "art"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["parentArt"] == True and img == None:
            art_type = "parentArt"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["grandparentArt"] == True and img == None:
            art_type = "grandparentArt"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)
    else:
        if valid_image["art"] == True:
            art_type = "art"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["parentArt"] == True and img == None:
            art_type = "parentArt"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["grandparentArt"] == True and img == None:
            art_type = "grandparentArt"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["thumb"] == True and img == None:
            art_type = "thumb"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["parentThumb"] == True and img == None:
            art_type = "parentThumb"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

        if valid_image["grandparentThumb"] == True and img == None:
            art_type = "grandparentThumb"
            img_url = base_url + metadata[art_type]
            img = get_data(img_url, debug_output, headerMap, ttl_seconds)

    validated_image = ""
    if img != None:
        validated_image = img

    return {"img": img, "art_type": art_type, "img_url": img_url, "validated_image": validated_image}

def display_message(debug_output, message_array = [], show_summary = False):
    if show_summary:
        img = base64.decode(PLEX_BANNER_PORTRAIT)
    else:
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
        if len(message_array) == 0:
            message_array.append({"message": "Oops, something went wrong", "color": "#FF0000"})

        rendered_image = render.Image(
            width = 64,
            src = img,
        )
        return render_marquee(False, message_array, rendered_image, show_summary, debug_output)

def render_marquee(show_only_artwork, message_array, image, show_summary, debug_output, using_portrait_banner = False):
    icon_img = base64.decode(PLEX_ICON)

    text_array = []
    index = 0
    max_length = 59
    string_length = 0
    full_message = ""
    for_break = False
    heading_lines = 0
    title_lines = 0
    body_lines = 0
    for message in message_array:
        if show_summary == False:
            if index == len(message_array) - 1 or len(message["message"]) > 0:
                marquee_message = message["message"]
                local_length = len(marquee_message)
                if local_length > 0:
                    local_length = local_length + 1

                string_length = string_length + local_length

                if index == len(message_array) - 1 and string_length > max_length:
                    # marquee_message = marquee_message[0:local_length-(string_length-max_length+3)] + "..."
                    for_break = True
                elif index == len(message_array) - 1 and string_length <= max_length:
                    marquee_message = marquee_message[0:local_length]
                    for_break = True
                elif len(message["message"]) > 0:
                    # Heading
                    marquee_message = marquee_message + " "

                full_message = full_message + marquee_message
                text_array.append(render.Text(marquee_message, color = message["color"], font = "tom-thumb"))
                if for_break:
                    break
        elif len(message["message"]) > 0:
            output_text = wrap(message["message"], 9)

            if message["type"] == "heading":
                heading_lines = calculate_lines(output_text, 10)
                if debug_output:
                    print("heading_lines: " + str(heading_lines))
            elif message["type"] == "title":
                title_lines = calculate_lines(output_text, 10)
                if debug_output:
                    print("title_lines: " + str(title_lines))
            elif message["type"] == "body":
                body_lines = calculate_lines(output_text, 10)
                if debug_output:
                    print("body_lines: " + str(body_lines))

            text_array.append(render.WrappedText(content = output_text, font = "tom-thumb", color = message["color"], width = 41))

        index = index + 1

    if show_summary == False and debug_output:
        print("Marquee text: " + full_message)

    if show_summary and show_only_artwork == False:
        marquee_height = 32 + ((heading_lines + title_lines + body_lines) - ((heading_lines + title_lines + body_lines) * 0.62))

        children = [
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [image],
            ),
        ]

        if using_portrait_banner == False:
            children.append(render.Image(src = icon_img, width = 7, height = 7))

        return render.Root(
            delay = 90,
            show_full_animation = True,
            child = render.Box(
                render.Row(
                    children = [
                        render.Stack(
                            children = children,
                        ),
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Stack(
                                children = [
                                    render.Marquee(
                                        offset_start = 32,
                                        offset_end = 32,
                                        height = int(marquee_height),
                                        scroll_direction = "vertical",
                                        width = 41,
                                        child = render.Column(
                                            children = text_array,
                                        ),
                                    ),
                                    # render.Row(
                                    #     expanded=True,
                                    #     cross_align="end",
                                    #     main_align="end",
                                    #     children=[render.Image(src = icon_img, width = 7, height = 7)]
                                    # )
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        )
    elif show_only_artwork == True:
        return render.Root(
            show_full_animation = True,
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    image,
                ],
            ),
        )
    else:
        marquee_width = 57 + ((len(full_message)) - ((len(full_message)) * 0.9))

        return render.Root(
            show_full_animation = True,
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
                                                width = int(marquee_width),
                                                offset_start = 64,
                                                offset_end = 57,
                                                child = render.Row(text_array),
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

def calculate_lines(text, length):
    words = text.split(" ")
    currentlength = 0
    breaks = 0

    for word in words:
        subwords = text.split("\n")
        if len(subwords) > 0 or len(word) + currentlength >= length:
            # subwords = word
            # if len(subwords) + currentlength >= length:
            if len(subwords) == 0:
                breaks = breaks + 1
            else:
                breaks = len(subwords)
            currentlength = 0
        currentlength = currentlength + len(subwords) + 1

    return breaks + 1

def wrap(string, line_length):
    lines = string.split("\n")

    b = ""
    for line in lines:
        b = b + wrap_line(line, line_length)

    return b

def wrap_line(line, line_length):
    if len(line) == 0:
        return "\n"

    if len(line) <= line_length:
        return line + "\n"

    words = line.split(" ")
    cur_line_length = 0
    str_builder = ""

    index = 0
    for word in words:
        # If adding the new word to the current line would be too long,
        # then put it on a new line (and split it up if it's too long).
        if (index == 0 or (cur_line_length + len(word)) > line_length):
            # Only move down to a new line if we have text on the current line.
            # Avoids situation where
            # wrapped whitespace causes emptylines in text.
            if cur_line_length > 0:
                str_builder = str_builder + "\n"
                cur_line_length = 0

            # If the current word is too long
            # to fit on a line (even on its own),
            # then split the word up.
            for _ in range(5000):
                if len(word) <= line_length:
                    word = word + " "
                    break
                else:
                    str_builder = str_builder + word[0:line_length - 1]
                    if word.strip().rfind("-") == -1 and word.strip().rfind("'") == -1:
                        str_builder = str_builder + "-"
                    word = word[line_length - 1:len(word)]
                    str_builder = str_builder + "\n"

            # Remove leading whitespace from the word,
            # so the new line starts flush to the left.
            word = word.lstrip(" ")

        if word.rfind(" ") == -1:
            str_builder = str_builder + " " + word.strip()
        else:
            str_builder = str_builder + word.strip()

        cur_line_length = cur_line_length + len(word)

        index = index + 1

    return str_builder

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
                name = "Plex server URL (required)",
                desc = "Your Plex server URL.",
                icon = "globe",
                default = "",
            ),
            schema.Text(
                id = "plex_token",
                name = "Plex token (required)",
                desc = "Your Plex token.",
                icon = "key",
                default = "",
            ),
            schema.Toggle(
                id = "show_heading",
                name = "Show heading",
                desc = "Display the media and library view type.",
                icon = "eye",
                default = True,
            ),
            schema.Text(
                id = "heading_color",
                name = "Heading color",
                desc = "Heading color using Hex color codes. eg, `#FFA500`. This is the title in summary view, otherwise the media and library view type.",
                icon = "paintbrush",
                default = "#FFA500",
            ),
            schema.Text(
                id = "font_color",
                name = "Font color",
                desc = "Main font color using Hex color codes. eg, `#FFFFFF`. This is the summary in summary view, otherwise the title.",
                icon = "paintbrush",
                default = "#FFFFFF",
            ),
            schema.Toggle(
                id = "show_summary",
                name = "Show summary",
                desc = "Show summary if available.",
                icon = "alignLeft",
                default = False,
            ),
            schema.Toggle(
                id = "show_only_artwork",
                name = "Show Only Artwork",
                desc = "Display only the artwork. Overrides 'Show summary' and 'Show heading' configurations.",
                icon = "eye",
                default = False,
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
                id = "show_library",
                name = "Show library",
                desc = "Show Plex library.",
                icon = "layerGroup",
                default = True,
            ),
            schema.Toggle(
                id = "show_recent",
                name = "Show played",
                desc = "Show last " + str(GET_TOP) + " recently played.",
                icon = "arrowTrendUp",
                default = True,
            ),
            schema.Toggle(
                id = "show_added",
                name = "Show added",
                desc = "Show last " + str(GET_TOP) + " recently added.",
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
                id = "filter_movie",
                name = "Filter by movies",
                desc = "Filter results by movies.",
                icon = "film",
                default = True,
            ),
            schema.Toggle(
                id = "filter_tv",
                name = "Filter by TV shows",
                desc = "Filter results by TV shows.",
                icon = "tv",
                default = True,
            ),
            schema.Toggle(
                id = "filter_music",
                name = "Filter by music",
                desc = "Filter results by music.",
                icon = "music",
                default = True,
            ),
        ],
    )
