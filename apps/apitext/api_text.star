"""
Applet: API text
Summary: API text display
Description: Display text from an API endpoint.
Author: Michael Yagi
"""

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
    body_font_color = config.get("body_font_color", "#FFFFFF")
    debug_output = config.bool("debug_output", False)
    image_placement = config.get("image_placement", 2)
    image_placement = int(image_placement)

    if debug_output:
        print("------------------------------")
        print("CONFIG - api_url: " + api_url)
        print("CONFIG - heading_response_path: " + heading_response_path)
        print("CONFIG - body_response_path: " + body_response_path)
        print("CONFIG - image_response_path: " + image_response_path)
        print("CONFIG - image_placement: " + str(image_placement))
        print("CONFIG - request_headers: " + request_headers)
        print("CONFIG - heading_font_color: " + heading_font_color)
        print("CONFIG - body_font_color: " + body_font_color)
        print("CONFIG - debug_output: " + str(debug_output))

    return get_text(api_url, heading_response_path, body_response_path, image_response_path, request_headers, debug_output, heading_font_color, body_font_color, image_placement)

def get_text(api_url, heading_response_path, body_response_path, image_response_path, request_headers, debug_output, heading_font_color, body_font_color, image_placement):
    random_indexes = {
        "[rand0]": -1,
        "[rand1]": -1,
        "[rand2]": -1,
        "[rand3]": -1,
        "[rand4]": -1,
        "[rand5]": -1,
        "[rand6]": -1,
        "[rand7]": -1,
        "[rand8]": -1,
        "[rand9]": -1,
    }

    base_url = ""
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
        output_map = get_data(api_url, debug_output, headerMap)
        output_content = output_map["data"]
        output_type = output_map["type"]

        if output_type == "text" or (output_type == "json" and (len(heading_response_path) > 0 or len(body_response_path) > 0 or len(image_response_path) > 0)):
            api_url_array = api_url.split("/")
            if len(api_url_array) > 2:
                base_url = api_url_array[0] + "//" + api_url_array[2]
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
                response_path_data_body = parse_response_path(output, body_response_path, random_indexes, debug_output)
                output_body = response_path_data_body["output"]
                body_parse_failure = response_path_data_body["failure"]
                body_parse_message = response_path_data_body["message"]
                if debug_output:
                    print("Getting text body. Pass: " + str(body_parse_failure == False))

                # Get heading
                response_path_data_heading = parse_response_path(output, heading_response_path, random_indexes, debug_output)
                output_heading = response_path_data_heading["output"]
                heading_parse_failure = response_path_data_heading["failure"]
                heading_parse_message = response_path_data_heading["message"]
                if debug_output:
                    print("Getting text heading. Pass: " + str(heading_parse_failure == False))

                # Get image
                response_path_data_image = parse_response_path(output, image_response_path, random_indexes, debug_output)
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
                    if output_image != None and type(output_image) == "string" and base_url.startswith("http"):
                        if output_image.startswith("http") == False:
                            if output_image.startswith("/"):
                                output_image = base_url + output_image
                            else:
                                output_image = base_url + "/" + output_image
                        image_endpoint = output_image
                        output_image_map = get_data(image_endpoint, debug_output, {})
                        img = output_image_map["data"]

                        if img == None and debug_output:
                            print("Could not retrieve image")

                    # Append heading
                    heading_lines = 0
                    if output_heading != None and type(output_heading) == "string":
                        heading_lines = calculate_lines(output_heading)
                        children.append(render.WrappedText(content = output_heading, font = "tom-thumb", color = heading_font_color))
                    elif debug_output and heading_parse_failure == True:
                        message = "Heading " + heading_parse_message
                        children.append(render.WrappedText(content = message, font = "tom-thumb", color = "#FF0000"))

                    # Append body
                    body_lines = 0
                    if output_body != None and type(output_body) == "string":
                        body_lines = calculate_lines(output_body)
                        children.append(render.WrappedText(content = output_body, font = "tom-thumb", color = body_font_color))
                    elif debug_output and body_parse_failure == True:
                        message = "Body " + body_parse_message
                        children.append(render.WrappedText(content = message, font = "tom-thumb", color = "#FF0000"))

                    # Insert image according to placement
                    if img != None:
                        test = render.Image(src = img, width = 64)
                        row = render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [test],
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

                        if image_parse_failure == True:
                            children.append(render.WrappedText(content = "Image " + image_parse_message, font = "tom-thumb", color = "#FF0000"))

                    height = 32 + ((heading_lines + body_lines) - ((heading_lines + body_lines) * 0.52))

                    if debug_output:
                        print("heading_lines: " + str(heading_lines))
                        print("body_lines: " + str(body_lines))
                        print("Marquee height: " + str(height))

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

def calculate_lines(text):
    words = text.split(" ")
    length = 17
    currentlength = 0
    breaks = 0

    for word in words:
        if len(word) + currentlength >= length:
            breaks = breaks + 1
            currentlength = 0
        currentlength = currentlength + len(word) + 1

    return breaks + 1

def parse_response_path(output, responsePathStr, random_indexes, debug_output):
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
                        elif random_indexes[item] == -1:  # Not set
                            random_indexes[item] = random.number(0, len(output) - 1)
                            item = random_indexes[item]
                        elif random_indexes[item] > -1:  # Already set
                            item = random_indexes[item]
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
    image_placement_options = [
        schema.Option(
            display = "First",
            value = "1",
        ),
        schema.Option(
            display = "After heading/Before body",
            value = "2",
        ),
        schema.Option(
            display = "Last",
            value = "3",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_url",
                name = "API URL",
                desc = "The API URL. Supports JSON or text types.",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "request_headers",
                name = "Request headers",
                desc = "Comma separated key:value pairs to build the request headers. eg, `x-api-key:abc123,content-type:application/json`",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "heading_response_path",
                name = "JSON response path for heading",
                desc = "A comma separated path to the heading from the response JSON. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_heading`",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "body_response_path",
                name = "JSON response path for body",
                desc = "A comma separated path to the main body from the response JSON. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_body`",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "image_response_path",
                name = "JSON response path for image URL",
                desc = "A comma separated path to an image from the response JSON. Use `[randX]` to choose a random index, where X is a number between 0-9 to use as a label across paths. eg. `json_key, [rand1], json_key_to_image_url, [rand2|rand]`",
                icon = "",
                default = "",
            ),
            schema.Dropdown(
                id = "image_placement",
                name = "Set the image placement",
                desc = "Determine where you see the image during scrolling.",
                icon = "",
                default = image_placement_options[1].value,
                options = image_placement_options,
            ),
            schema.Text(
                id = "heading_font_color",
                name = "Heading text color",
                desc = "Heading text color using Hex color codes. eg, `#FFA500`",
                icon = "",
                default = "#FFA500",
            ),
            schema.Text(
                id = "body_font_color",
                name = "Body text color",
                desc = "Body text color using Hex color codes. eg, `#FFFFFF`",
                icon = "",
                default = "#FFFFFF",
            ),
            schema.Toggle(
                id = "debug_output",
                name = "Toggle debug messages",
                desc = "Toggle debug messages. Will display the messages on the display if enabled.",
                icon = "",
                default = False,
            ),
        ],
    )
