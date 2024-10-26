"""
Applet: API text
Summary: API text display
Description: Display text from an API endpoint.
Author: Michael Yagi
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    random.seed(time.now().unix // 10)

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

        if output_content != None and (output_type == "text" or (output_type == "json" and (len(heading_response_path) > 0 or len(body_response_path) > 0 or len(image_response_path) > 0))):
            # api_url_array = api_url.split("/")
            # if len(api_url_array) > 2:
            #     base_url = api_url_array[0] + "//" + api_url_array[2]
            output = json.decode(output_content, None)
            output_body = None
            output_heading = None
            output_image = None

            if output != None:
                if debug_output:
                    outputStr = str(output)
                    outputLen = len(outputStr)
                    if outputLen >= 200:
                        outputLen = 200

                    outputStr = outputStr[0:outputLen]
                    if outputLen >= 200:
                        outputStr = outputStr + "..."
                        print("Decoded JSON truncated: " + outputStr)
                    else:
                        print("Decoded JSON: " + outputStr)

                # Parse response path for JSON
                response_path_data_body = parse_response_path(output, body_response_path, debug_output, ttl_seconds)
                output_body = response_path_data_body["output"]
                body_parse_failure = response_path_data_body["failure"]
                body_parse_message = response_path_data_body["message"]
                if debug_output:
                    print("Getting text body. Pass: " + str(body_parse_failure == False))

                # Get heading
                response_path_data_heading = parse_response_path(output, heading_response_path, debug_output, ttl_seconds)
                output_heading = response_path_data_heading["output"]
                heading_parse_failure = response_path_data_heading["failure"]
                heading_parse_message = response_path_data_heading["message"]
                if debug_output:
                    print("Getting text heading. Pass: " + str(heading_parse_failure == False))

                # Get image
                response_path_data_image = parse_response_path(output, image_response_path, debug_output, ttl_seconds)
                output_image = response_path_data_image["output"]
                image_parse_failure = response_path_data_image["failure"]
                image_parse_message = response_path_data_image["message"]
                if debug_output:
                    print("Getting image. Pass: " + str(image_parse_failure == False))

                if (body_parse_failure == False and output_body != None) or (heading_parse_failure == False and output_heading != None) or (image_parse_failure == False and output_image != None):
                    if type(output_body) == "string":
                        output_body = output_body.replace("\n", "").replace("\\", "")
                    if type(output_heading) == "string":
                        output_heading = output_heading.replace("\n", "").replace("\\", "")

                    children = []
                    img = None
                    image_endpoint = ""

                    # Process image data
                    if output_image != None and type(output_image) == "string":
                        if output_image.startswith("http") == False and (base_url == "" or base_url.startswith("http") == False):
                            message = "Base URL required"
                            if debug_output:
                                print("Invalid URL. Requires a base_url")
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
                                print("Could not retrieve image")

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
                        elif image_placement == 4:
                            rendered_image = render.Column(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [
                                    render.Image(src = img, width = 22),
                                ],
                            )

                    # Append heading
                    heading_lines = 0
                    if output_heading != None and type(output_heading) == "string":
                        if rendered_image != None:
                            output_heading = wrap(output_heading, 9)
                            heading_lines = calculate_lines(output_heading, 10)
                            children.append(render.WrappedText(content = output_heading, font = "tom-thumb", color = heading_font_color, width = 41))
                        else:
                            heading_lines = calculate_lines(output_heading, 17)
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
                            output_body = wrap(output_body, 9)
                            body_lines = calculate_lines(output_body, 10)
                            children.append(render.WrappedText(content = output_body, font = "tom-thumb", color = body_font_color, width = 41))
                        else:
                            body_lines = calculate_lines(output_body, 17)
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
                    if img != None and image_placement != 4:
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
                            else:
                                print("No image URL found")

                    height = 32 + ((heading_lines + body_lines) - ((heading_lines + body_lines) * 0.52))

                    if debug_output:
                        print("heading_lines: " + str(heading_lines))
                        print("body_lines: " + str(body_lines))
                        print("Marquee height: " + str(int(height)))

                    if rendered_image != None and image_placement == 4:
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
                        delay = 100,
                        show_full_animation = True,
                        child = render.Row(
                            children = children_content,
                        ),
                    )
                else:
                    message = "Could not parse data. Check response paths."

            else:
                return render.Root(
                    delay = 100,
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
            message = "Oops! Check URL and header values. URL must return JSON or text."
            if debug_output:
                print(message)

    if message == "":
        message = "Could not get text"

    row = render.Row(children = [])
    if debug_output == True:
        row = render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.WrappedText(content = message, font = "tom-thumb"),
            ],
        )

    return render.Root(
        child = render.Box(
            row,
        ),
    )

def calculate_lines(text, length):
    words = text.split(" ")
    currentlength = 0
    breaks = 0

    for word in words:
        if len(word) + currentlength >= length:
            breaks = breaks + 1
            currentlength = 0
        currentlength = currentlength + len(word) + 1

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

    for word in words:
        # If adding the new word to the current line would be too long,
        # then put it on a new line (and split it up if it's too long).
        if (cur_line_length + len(word)) > line_length:
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

    return str_builder

def parse_response_path(output, responsePathStr, debug_output, ttl_seconds):
    message = ""
    failure = False

    if (len(responsePathStr) > 0):
        responsePathArray = responsePathStr.split(",")

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
                        message = "Response path has empty list for " + item + "."
                        if debug_output:
                            print("responsePathArray for " + item + " invalid. Response path has empty list.")
                        break

                    if debug_output:
                        print("Random index chosen " + str(item))
                else:
                    failure = True
                    message = "Response path invalid for " + item + ". Use of [rand] only allowable in lists."
                    if debug_output:
                        print("responsePathArray for " + item + " invalid. Use of [rand] only allowable in lists.")
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
        return cached_index
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

        if contentType.find("gif") != -1 or contentType.find("json") != -1 or contentType.find("text/plain") != -1 or contentType.find("image") != -1:
            if contentType.find("json") != -1:
                contentType = "json"
            elif contentType.find("gif") != -1:
                contentType = "gif"
            elif contentType.find("image") != -1:
                contentType = "image"
            else:
                contentType = "text"

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
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_url",
                name = "API URL",
                desc = "The API URL. Supports JSON or text types.",
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
                name = "JSON response path for heading",
                desc = "A comma separated path to the heading from the response JSON. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_heading`",
                icon = "code",
                default = "",
            ),
            schema.Text(
                id = "body_response_path",
                name = "JSON response path for body",
                desc = "A comma separated path to the main body from the response JSON. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_body`",
                icon = "code",
                default = "",
            ),
            schema.Text(
                id = "image_response_path",
                name = "JSON response path for image URL",
                desc = "A comma separated path to an image from the response JSON. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_image_url, [rand2|rand]`",
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
