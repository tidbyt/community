"""
Applet: API text
Summary: API text display
Description: Display text from an API endpoint.
Author: Michael Yagi
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

BG_IMAGE = "/9j/4AAQSkZJRgABAQEBLAEsAAD/4QDARXhpZgAATU0AKgAAAAgABgEaAAUAAAABAAAAVgEbAAUAAAABAAAAXgEoAAMAAAABAAIAAAExAAIAAAARAAAAZgEyAAIAAAAUAAAAeIdpAAQAAAABAAAAjAAAAAAAAAEsAAAAAQAAASwAAAABcGFpbnQubmV0IDUuMC4xMwAAMjAwOTowMzoyMCAxNjozNzo0OAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAFAKADAAQAAAABAAADIAAAAAAAAP/hB+xodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+DQo8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA0LjEtYzAzNiA0Ni4yNzY3MjAsIE1vbiBGZWIgMTkgMjAwNyAyMjo0MDowOCAgICAgICAgIj4NCiAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4NCiAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnhhcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eGFwTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIgeG1sbnM6ZXhpZj0iaHR0cDovL25zLmFkb2JlLmNvbS9leGlmLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgZGM6Zm9ybWF0PSJpbWFnZS9qcGVnIiB4YXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDUzMgV2luZG93cyIgeGFwOkNyZWF0ZURhdGU9IjIwMDktMDMtMjBUMTY6Mzc6NDgtMDQ6MDAiIHhhcDpNb2RpZnlEYXRlPSIyMDA5LTAzLTIwVDE2OjM3OjQ4LTA0OjAwIiB4YXA6TWV0YWRhdGFEYXRlPSIyMDA5LTAzLTIwVDE2OjM3OjQ4LTA0OjAwIiB4YXBNTTpEb2N1bWVudElEPSJ1dWlkOjY5RDEwQ0NDOEUxNURFMTFBQTM3RDcxMzFBMUIxNDBDIiB4YXBNTTpJbnN0YW5jZUlEPSJ1dWlkOjZBRDEwQ0NDOEUxNURFMTFBQTM3RDcxMzFBMUIxNDBDIiB0aWZmOk9yaWVudGF0aW9uPSIxIiB0aWZmOlhSZXNvbHV0aW9uPSIzMDAwMDAwLzEwMDAwIiB0aWZmOllSZXNvbHV0aW9uPSIzMDAwMDAwLzEwMDAwIiB0aWZmOlJlc29sdXRpb25Vbml0PSIyIiB0aWZmOk5hdGl2ZURpZ2VzdD0iMjU2LDI1NywyNTgsMjU5LDI2MiwyNzQsMjc3LDI4NCw1MzAsNTMxLDI4MiwyODMsMjk2LDMwMSwzMTgsMzE5LDUyOSw1MzIsMzA2LDI3MCwyNzEsMjcyLDMwNSwzMTUsMzM0MzI7NzAzMjBEMDYyQjUzNDhCODhDOTY5RDA1MzY3MzkyQjAiIGV4aWY6UGl4ZWxYRGltZW5zaW9uPSIxMjgwIiBleGlmOlBpeGVsWURpbWVuc2lvbj0iODAwIiBleGlmOkNvbG9yU3BhY2U9IjEiIGV4aWY6TmF0aXZlRGlnZXN0PSIzNjg2NCw0MDk2MCw0MDk2MSwzNzEyMSwzNzEyMiw0MDk2Miw0MDk2MywzNzUxMCw0MDk2NCwzNjg2NywzNjg2OCwzMzQzNCwzMzQzNywzNDg1MCwzNDg1MiwzNDg1NSwzNDg1NiwzNzM3NywzNzM3OCwzNzM3OSwzNzM4MCwzNzM4MSwzNzM4MiwzNzM4MywzNzM4NCwzNzM4NSwzNzM4NiwzNzM5Niw0MTQ4Myw0MTQ4NCw0MTQ4Niw0MTQ4Nyw0MTQ4OCw0MTQ5Miw0MTQ5Myw0MTQ5NSw0MTcyOCw0MTcyOSw0MTczMCw0MTk4NSw0MTk4Niw0MTk4Nyw0MTk4OCw0MTk4OSw0MTk5MCw0MTk5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"
MAX_TEXT_LENGTH = 1000

def main(config):
    random.seed(time.now().unix)

    api_url = config.str("api_url", "")
    heading_response_path = config.get("heading_response_path", "")
    body_response_path = config.get("body_response_path", "")
    image_response_path = config.get("image_response_path", "")
    request_headers = config.get("request_headers", "")
    heading_font_color = config.get("heading_font_color", "#FFA500")
    if heading_font_color == "":
        heading_font_color = "#FFA500"
    body_font_color = config.get("body_font_color", "#FFFFFF")
    if body_font_color == "":
        body_font_color = "#FFFFFF"
    debug_output = config.bool("debug_output", False)
    base_url = config.str("base_url", "")
    image_placement = config.get("image_placement", 2)
    image_placement = int(image_placement)
    ttl_seconds = config.get("ttl_seconds", 20)
    ttl_seconds = int(ttl_seconds)

    if debug_output:
        print("------------------------------")
        print("CONFIG - api_url: " + api_url)
        print("CONFIG - base_url: " + base_url)
        print("CONFIG - heading_response_path: " + heading_response_path)
        print("CONFIG - body_response_path: " + body_response_path)
        print("CONFIG - image_response_path: " + image_response_path)
        print("CONFIG - image_placement: " + str(image_placement))
        print("CONFIG - request_headers: " + request_headers)
        print("CONFIG - heading_font_color: " + heading_font_color)
        print("CONFIG - body_font_color: " + body_font_color)
        print("CONFIG - debug_output: " + str(debug_output))
        print("CONFIG - ttl_seconds: " + str(ttl_seconds))

    return get_text(api_url, base_url, heading_response_path, body_response_path, image_response_path, request_headers, debug_output, ttl_seconds, heading_font_color, body_font_color, image_placement)

def get_text(api_url, base_url, heading_response_path, body_response_path, image_response_path, request_headers, debug_output, ttl_seconds, heading_font_color, body_font_color, image_placement):
    message = ""
    row = render.Row(children = [])

    if debug_output == False:
        message = "API TEXT"

        row = render.Stack([
            render.Image(src = base64.decode(BG_IMAGE)),
            render.Box(
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 44,
                            height = 12,
                            color = "#FFFFFF",
                        ),
                    ],
                ),
            ),
            render.Box(
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 42,
                            height = 10,
                            color = "#000000",
                        ),
                    ],
                ),
            ),
            render.Box(
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(content = message, font = "tom-thumb", color = body_font_color),
                    ],
                ),
            ),
        ])

    if api_url == "":
        message = "API URL must not be blank"

        if debug_output:
            print(message)

    else:
        # Parse request headers
        headerMap = {}
        if request_headers != "" or request_headers != {}:
            request_headers_array = request_headers.split(",")

            for app_header in request_headers_array:
                headerKeyValueArray = app_header.split(":")
                if len(headerKeyValueArray) > 1:
                    headerMap[headerKeyValueArray[0].strip()] = headerKeyValueArray[1].strip()

        # Get API content
        output_map = get_data(api_url, debug_output, headerMap, ttl_seconds)
        output_content = output_map["data"]
        output_type = output_map["type"]
        children = []

        if output_content != None and (output_type == "text" or ((output_type == "json" or output_type == "xml") and (len(heading_response_path) > 0 or len(body_response_path) > 0 or len(image_response_path) > 0))):
            output = json.decode(output_content, None)
            output_body = None
            output_heading = None
            output_image = None

            if output != None or output_type == "xml":
                if debug_output:
                    outputStr = str(output)
                    outputLen = len(outputStr)
                    if outputLen >= 200:
                        outputLen = 200

                    outputStr = outputStr[0:outputLen]
                    if outputLen >= 200:
                        outputStr = outputStr + "..."
                        print("Decoded response JSON truncated: " + outputStr)
                    else:
                        print("Decoded response JSON: " + outputStr)

                # Parse response path for JSON
                if output_type == "xml":
                    response_path_data_body = parse_response_path(xpath.loads(output_content), body_response_path, debug_output, ttl_seconds, True)
                else:
                    response_path_data_body = parse_response_path(output, body_response_path, debug_output, ttl_seconds)
                output_body = response_path_data_body["output"]
                body_parse_failure = response_path_data_body["failure"]
                body_parse_message = response_path_data_body["message"]
                if debug_output:
                    print("Getting text body. Pass: " + str(body_parse_failure == False))
                    if body_parse_failure:
                        children.append(render.WrappedText(content = body_parse_message, font = "tom-thumb", color = "#FF0000"))
                    else:
                        bodyoutputStr = output_body
                        if bodyoutputStr != None:
                            if len(bodyoutputStr) >= 200:
                                print("Body text: " + str(bodyoutputStr)[0:200] + "...")
                            else:
                                print("Body text: " + str(bodyoutputStr))

                            if len(output_body) >= MAX_TEXT_LENGTH:
                                output_body = output_body[0:MAX_TEXT_LENGTH] + "..."
                                print("Body text truncated")

                # Get heading
                if output_type == "xml":
                    response_path_data_heading = parse_response_path(xpath.loads(output_content), heading_response_path, debug_output, ttl_seconds, True)
                else:
                    response_path_data_heading = parse_response_path(output, heading_response_path, debug_output, ttl_seconds)
                output_heading = response_path_data_heading["output"]
                heading_parse_failure = response_path_data_heading["failure"]
                heading_parse_message = response_path_data_heading["message"]
                if debug_output:
                    print("Getting text heading. Pass: " + str(heading_parse_failure == False))
                    if heading_parse_failure:
                        children.append(render.WrappedText(content = heading_parse_message, font = "tom-thumb", color = "#FF0000"))
                    else:
                        headingoutputStr = output_heading
                        if headingoutputStr != None:
                            if len(headingoutputStr) >= 200:
                                print("Header text: " + str(headingoutputStr)[0:200] + "...")
                            else:
                                print("Header text: " + str(headingoutputStr))

                            if len(output_heading) >= MAX_TEXT_LENGTH:
                                output_heading = output_heading[0:MAX_TEXT_LENGTH] + "..."
                                print("Heading text truncated")

                # Get image
                if output_type == "xml":
                    response_path_data_image = parse_response_path(xpath.loads(output_content), image_response_path, debug_output, ttl_seconds, True)
                else:
                    response_path_data_image = parse_response_path(output, image_response_path, debug_output, ttl_seconds)
                output_image = response_path_data_image["output"]
                image_parse_failure = response_path_data_image["failure"]
                image_parse_message = response_path_data_image["message"]
                if debug_output:
                    print("Getting image. Pass: " + str(image_parse_failure == False))
                    if image_parse_failure:
                        children.append(render.WrappedText(content = image_parse_message, font = "tom-thumb", color = "#FF0000"))

                if (body_parse_failure == False and output_body != None) or (heading_parse_failure == False and output_heading != None) or (image_parse_failure == False and output_image != None):
                    if type(output_body) == "string":
                        output_body = output_body.replace("\n", "").replace("\\", "")
                    if type(output_heading) == "string":
                        output_heading = output_heading.replace("\n", "").replace("\\", "")

                    img = None
                    image_endpoint = ""

                    # Process image data
                    if output_image != None and type(output_image) == "string":
                        if output_image.startswith("http") == False and (base_url == "" or base_url.startswith("http") == False):
                            message = "Base URL required for image"
                            if debug_output:
                                children.append(render.WrappedText(content = message, font = "tom-thumb", color = "#FF0000"))
                                print(message)
                        else:
                            if output_image.startswith("http") == False:
                                if output_image.startswith("/"):
                                    output_image = base_url + output_image
                                else:
                                    output_image = base_url + "/" + output_image
                            image_endpoint = output_image
                            output_image_map = get_data(image_endpoint, debug_output, headerMap, ttl_seconds)
                            img = output_image_map["data"]

                            if img == None and debug_output:
                                message = "Could not retrieve image. Recheck URL and headers."
                                print(message)
                                children.append(render.WrappedText(content = message, font = "tom-thumb", color = "#FF0000"))

                    # Insert image according to placement if image on left
                    rendered_image = None
                    if img != None:
                        if image_parse_failure == True:
                            children.append(render.WrappedText(content = "Image " + image_parse_message, font = "tom-thumb", color = "#FF0000"))
                        elif len(image_response_path) > 0 and output_image == None and debug_output:
                            if len(image_endpoint) > 0:
                                print("Image URL found but failed to render URL " + image_endpoint)
                            else:
                                print("No image URL found")
                        elif image_placement == 4 or image_placement == 5:
                            width = 21
                            if image_placement == 5:
                                width = 22
                            rendered_image = render.Box(
                                width = width,
                                height = 32,
                                child = render.Column(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Image(
                                            src = img,
                                            height = 32,
                                        ),
                                    ],
                                ),
                            )

                    # Append heading
                    heading_lines = 0
                    if output_heading != None and type(output_heading) == "string":
                        if rendered_image != None:
                            output_heading = wrap(output_heading, 10)
                            heading_lines = calculate_lines(output_heading, True, 11)
                            width = 43
                            if image_placement == 5:
                                width = 42
                            children.append(render.WrappedText(content = output_heading, font = "tom-thumb", color = heading_font_color, width = width))
                        else:
                            heading_lines = calculate_lines(output_heading, False, 17)
                            children.append(render.Padding(
                                pad = (0, 1, 0, 0),
                                child = render.Column(
                                    [render.WrappedText(content = output_heading, font = "tom-thumb", color = heading_font_color)],
                                ),
                            ))

                    elif debug_output and heading_parse_failure == True:
                        message = "Heading " + heading_parse_message
                        children.append(render.WrappedText(content = message, font = "tom-thumb", color = "#FF0000"))

                    # Append body
                    body_lines = 0
                    if output_body != None and type(output_body) == "string":
                        if rendered_image != None:
                            output_body = wrap(output_body, 10)
                            body_lines = calculate_lines(output_body, True, 11)
                            width = 43
                            if image_placement == 5:
                                width = 42
                            children.append(render.WrappedText(content = output_body, font = "tom-thumb", color = body_font_color, width = width))
                        else:
                            body_lines = calculate_lines(output_body, False, 17)
                            children.append(render.Padding(
                                pad = (0, 1, 0, 0),
                                child = render.Column(
                                    [render.WrappedText(content = output_body, font = "tom-thumb", color = body_font_color)],
                                ),
                            ))
                    elif debug_output and body_parse_failure == True:
                        message = "Body " + body_parse_message
                        children.append(render.WrappedText(content = message, font = "tom-thumb", color = "#FF0000"))

                    # If images are stacked
                    if img != None and image_placement != 4 and image_placement != 5:
                        image_render = render.Image(src = img, width = 64)
                        row = render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [image_render],
                        )

                        if image_placement == 1:
                            children.insert(0, row)
                        elif image_placement == 3:
                            children.append(row)
                        elif len(children) > 0:
                            children.insert(len(children) - 1, row)
                        elif len(children) == 0:
                            children.append(row)
                        elif len(image_response_path) > 0 and output_image == None and debug_output:
                            if len(image_endpoint) > 0:
                                print("Image URL found but failed to render URL " + image_endpoint)
                                children.append(render.WrappedText(content = "Image URL found but failed to render URL " + image_endpoint, font = "tom-thumb", color = "#FF0000"))
                            else:
                                print("No image URL found")
                                children.append(render.WrappedText(content = "No image URL found", font = "tom-thumb", color = "#FF0000"))

                    percent = 0.52
                    if image_placement == 4 or image_placement == 5:
                        percent = 0.62
                    height = 32 + ((heading_lines + body_lines) - ((heading_lines + body_lines) * percent))

                    if debug_output:
                        print("heading_lines: " + str(heading_lines))
                        print("body_lines: " + str(body_lines))
                        print("Marquee height: " + str(int(height)))

                    if rendered_image != None and (image_placement == 4 or image_placement == 5):
                        if image_placement == 4:
                            children_content = [
                                rendered_image,
                                render.Padding(
                                    pad = (1, 0, 0, 0),
                                    child = render.Column(
                                        children = [
                                            render.Marquee(
                                                offset_start = 32,
                                                offset_end = 32,
                                                height = int(height),
                                                scroll_direction = "vertical",
                                                width = 41,
                                                child = render.Column(
                                                    children = children,
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ]
                        else:
                            children_content = [
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            offset_start = 32,
                                            offset_end = 32,
                                            height = int(height),
                                            scroll_direction = "vertical",
                                            width = 41,
                                            child = render.Column(
                                                children = children,
                                            ),
                                        ),
                                    ],
                                ),
                                rendered_image,
                            ]
                    else:
                        children_content = [
                            render.Marquee(
                                offset_start = 32,
                                offset_end = 32,
                                height = int(height),
                                scroll_direction = "vertical",
                                width = 64,
                                child = render.Column(
                                    children = children,
                                ),
                            ),
                        ]

                    return render.Root(
                        delay = 90,
                        show_full_animation = True,
                        child = render.Row(
                            children = children_content,
                        ),
                    )
                else:
                    message = "Could not parse data. Check response paths."

            else:
                return render.Root(
                    delay = 90,
                    show_full_animation = True,
                    child = render.Marquee(
                        offset_start = 32,
                        offset_end = 32,
                        height = 32,
                        scroll_direction = "vertical",
                        width = 64,
                        child = render.WrappedText(output_content),
                    ),
                )

        else:
            message = "Oops! Check URL and header values. URL " + api_url + " must return JSON or text."
            if debug_output:
                print(message)

    if message == "":
        message = "Could not get text"

    message = "API Text - " + message

    if debug_output == True:
        row = render.Marquee(
            offset_start = 32,
            offset_end = 32,
            height = 32,
            scroll_direction = "vertical",
            width = 64,
            child = render.WrappedText(content = message, font = "tom-thumb", color = "#FF0000"),
        )

    return render.Root(
        delay = 90,
        show_full_animation = True,
        child = render.Box(
            row,
        ),
    )

def calculate_lines(text, wrapped, length):
    words = text.split(" ")
    currentlength = 0
    breaks = 0

    for subwords in words:
        if wrapped:
            subwords = text.split("\n")

        if (len(subwords) > 0) and wrapped:
            if len(subwords) == 0:
                breaks = breaks + 1
            else:
                breaks = len(subwords)
            currentlength = 0
        elif len(subwords) + currentlength >= length:
            breaks = breaks + 1
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

def parse_response_path(output, responsePathStr, debug_output, ttl_seconds, is_xml = False):
    message = ""
    failure = False

    if (len(responsePathStr) > 0):
        responsePathArray = responsePathStr.split(",")

        if is_xml:
            path_str = ""

            # last_item = ""
            for item in responsePathArray:
                item = item.strip()

                # test_output = None
                # if len(path_str) > 0:
                #     test_output = output.query_all(path_str)
                #     if type(test_output) == "list" and len(test_output) == 0:
                #         failure = True
                #         message = "Response path has empty list for " + last_item + "."
                #         if debug_output:
                #             print("responsePathArray for " + last_item + " invalid. Response path has empty list.")
                #         break

                index = -1
                valid_rand = False
                if item == "[rand]":
                    valid_rand = True

                for x in range(10):
                    if item == "[rand" + str(x) + "]":
                        valid_rand = True
                        break

                if valid_rand:
                    test_output = output.query_all(path_str)
                    if type(test_output) == "list" and len(test_output) > 0:
                        if item == "[rand]":
                            index = random.number(0, len(test_output) - 1)
                        else:
                            index = get_random_index(item, test_output, debug_output, ttl_seconds)
                    else:
                        failure = True
                        message = "Response path has empty list for " + item + "."
                        if debug_output:
                            print("responsePathArray for " + item + " invalid. Response path has empty list.")
                        break

                    if debug_output:
                        print("Random index chosen " + str(index))

                if type(item) != "int" and item.isdigit():
                    index = int(item)

                if index > -1:
                    path_str = path_str + "[" + str(index) + "]"
                else:
                    path_str = path_str + "/" + item

                # last_item = item

                if debug_output:
                    print("Appended path: " + path_str)

            if failure == False:
                output = output.query_all(path_str)
                if type(output) == "list" and len(output) > 0:
                    output = output[0]

                if type(output) != "string":
                    failure = True
                    message = "Response path result not a string, found " + type(output) + " instead reading path " + path_str + "."
                    if debug_output:
                        print(message)
            else:
                output = None
        else:
            for item in responsePathArray:
                item = item.strip()

                valid_rand = False
                if item == "[rand]":
                    valid_rand = True

                for x in range(10):
                    if item == "[rand" + str(x) + "]":
                        valid_rand = True
                        break

                if valid_rand:
                    if type(output) == "list":
                        if len(output) > 0:
                            if item == "[rand]":
                                item = random.number(0, len(output) - 1)
                            else:
                                item = get_random_index(item, output, debug_output, ttl_seconds)
                        else:
                            failure = True
                            message = "Response path has empty list for " + str(item) + "."
                            if debug_output:
                                print("responsePathArray for " + str(item) + " invalid. Response path has empty list.")
                            break

                        if debug_output:
                            print("Random index chosen " + str(item))
                    else:
                        failure = True
                        message = "Response path invalid for " + str(item) + ". Use of [rand] only allowable in lists."
                        if debug_output:
                            print("responsePathArray for " + str(item) + " invalid. Use of [rand] only allowable in lists.")
                        break

                if type(item) != "int" and item.isdigit():
                    item = int(item)

                if debug_output:
                    print("path array item: " + str(item) + " - type " + str(type(output)))

                if output != None and type(output) == "dict" and type(item) == "string":
                    valid_keys = []
                    if output != None and type(output) == "dict":
                        valid_keys = output.keys()

                    has_item = False
                    for valid_key in valid_keys:
                        if valid_key == item:
                            has_item = True
                            break

                    if has_item:
                        output = output[item]
                    else:
                        failure = True
                        message = "Response path invalid. " + str(item) + " does not exist"
                        if debug_output:
                            print("responsePathArray invalid. " + str(item) + " does not exist")
                        output = None
                        break
                elif output != None and type(output) == "list" and type(item) == "int" and item <= len(output) - 1:
                    output = output[item]
                else:
                    failure = True
                    message = "Response path invalid. " + str(item) + " does not exist"
                    if debug_output:
                        print("responsePathArray invalid. " + str(item) + " does not exist")
                    output = None
                    break
    else:
        output = None

    return {"output": output, "failure": failure, "message": message}

def get_random_index(item, a_list, debug_output, ttl_seconds):
    cached_index = cache.get(item)

    if cached_index:
        if debug_output:
            print("Using cached value: " + str(cached_index))
        return int(cached_index)
    else:
        random_index = random.number(0, len(a_list) - 1)
        if debug_output:
            print("Setting cached value for item " + item + ": " + str(random_index))
        cache.set(item, str(random_index), ttl_seconds = ttl_seconds)
        return random_index

def get_data(url, debug_output, headerMap = {}, ttl_seconds = 20):
    if headerMap == {}:
        res = http.get(url, ttl_seconds = ttl_seconds)
    else:
        res = http.get(url, headers = headerMap, ttl_seconds = ttl_seconds)

    headers = res.headers
    isValidContentType = False

    headersStr = str(headers)
    headersStr = headersStr.lower()
    headers = json.decode(headersStr, None)
    contentType = ""
    if headers != None and headers.get("content-type") != None:
        contentType = headers.get("content-type")

        if contentType.find("gif") != -1 or contentType.find("json") != -1 or contentType.find("text/plain") != -1 or contentType.find("image") != -1 or contentType.find("xml") != -1:
            if contentType.find("json") != -1:
                contentType = "json"
            elif contentType.find("gif") != -1:
                contentType = "gif"
            elif contentType.find("image") != -1:
                contentType = "image"
            elif contentType.find("text/plain") != -1:
                contentType = "text"
            else:
                contentType = "xml"

            isValidContentType = True

    if debug_output:
        print("isValidContentType for " + url + " content type " + contentType + ": " + str(isValidContentType))

    if res.status_code != 200 or isValidContentType == False:
        if debug_output:
            print("status: " + str(res.status_code))
            print("Requested url: " + str(url))
    else:
        data = res.body()

        return {"data": data, "type": contentType}

    return {"data": None, "type": contentType}

def get_schema():
    ttl_options = [
        schema.Option(
            display = "5 sec",
            value = "5",
        ),
        schema.Option(
            display = "20 sec",
            value = "20",
        ),
        schema.Option(
            display = "1 min",
            value = "60",
        ),
        schema.Option(
            display = "15 min",
            value = "900",
        ),
        schema.Option(
            display = "1 hour",
            value = "3600",
        ),
        schema.Option(
            display = "24 hours",
            value = "86400",
        ),
    ]

    image_placement_options = [
        schema.Option(
            display = "First",
            value = "1",
        ),
        schema.Option(
            display = "Middle",
            value = "2",
        ),
        schema.Option(
            display = "Last",
            value = "3",
        ),
        schema.Option(
            display = "Left",
            value = "4",
        ),
        schema.Option(
            display = "Right",
            value = "5",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_url",
                name = "API URL",
                desc = "The API URL. Supports JSON, XML or text types.",
                icon = "globe",
                default = "",
            ),
            schema.Text(
                id = "request_headers",
                name = "Request headers",
                desc = "Comma separated key:value pairs to build the request headers. eg, `x-api-key:abc123,content-type:application/json`",
                icon = "code",
                default = "",
            ),
            schema.Text(
                id = "heading_response_path",
                name = "JSON or XML response path for heading",
                desc = "A comma separated path to the heading from the response JSON or XML. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_heading`",
                icon = "code",
                default = "",
            ),
            schema.Text(
                id = "body_response_path",
                name = "JSON or XML response path for body",
                desc = "A comma separated path to the main body from the response JSON or XML. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_body`",
                icon = "code",
                default = "",
            ),
            schema.Text(
                id = "image_response_path",
                name = "JSON or XML response path for image URL",
                desc = "A comma separated path to an image from the response JSON or XML. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_image_url, [rand2|rand]`",
                icon = "image",
                default = "",
            ),
            schema.Dropdown(
                id = "image_placement",
                name = "Set the image placement",
                desc = "Determine where you see the image during scrolling.",
                icon = "image",
                default = image_placement_options[1].value,
                options = image_placement_options,
            ),
            schema.Text(
                id = "heading_font_color",
                name = "Heading text color",
                desc = "Heading text color using Hex color codes. eg, `#FFA500`",
                icon = "brush",
                default = "#FFA500",
            ),
            schema.Text(
                id = "body_font_color",
                name = "Body text color",
                desc = "Body text color using Hex color codes. eg, `#FFFFFF`",
                icon = "brush",
                default = "#FFFFFF",
            ),
            schema.Dropdown(
                id = "ttl_seconds",
                name = "Refresh rate",
                desc = "Refresh data at the specified interval. Useful for when an endpoint serves random texts.",
                icon = "clock",
                default = ttl_options[1].value,
                options = ttl_options,
            ),
            schema.Text(
                id = "base_url",
                name = "Base URL",
                desc = "The base URL if needed",
                icon = "globe",
                default = "",
            ),
            schema.Toggle(
                id = "debug_output",
                name = "Toggle debug messages",
                desc = "Toggle debug messages. Will display the messages on the display if enabled.",
                icon = "bug",
                default = False,
            ),
        ],
    )
