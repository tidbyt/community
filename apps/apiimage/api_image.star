"""
Applet: API image
Summary: API image display
Description: Display an image from an API endpoint.
Author: Michael Yagi
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

BG_IMAGE = "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"

def main(config):
    random.seed(time.now().unix)

    api_url = config.str("api_url", "")
    response_path = config.get("response_path", "")
    request_headers = config.get("request_headers", "")
    debug_output = config.bool("debug_output", False)
    base_url = config.str("base_url", "")
    fit_screen = config.bool("fit_screen", False)
    ttl_seconds = config.get("ttl_seconds", 20)
    ttl_seconds = int(ttl_seconds)

    if debug_output:
        print("------------------------------")
        print("CONFIG - api_url: " + api_url)
        print("CONFIG - base_url: " + base_url)
        print("CONFIG - response_path: " + response_path)
        print("CONFIG - request_headers: " + request_headers)
        print("CONFIG - debug_output: " + str(debug_output))
        print("CONFIG - fit_screen: " + str(fit_screen))
        print("CONFIG - ttl_seconds: " + str(ttl_seconds))

    return get_image(api_url, base_url, response_path, request_headers, debug_output, fit_screen, ttl_seconds)

def get_image(api_url, base_url, response_path, request_headers, debug_output, fit_screen, ttl_seconds):
    failure = False
    message = ""
    row = render.Row(children = [])

    if debug_output == False:
        message = "API IMAGE"

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
                        render.Text(content = message, font = "tom-thumb", color = "#FFFFFF"),
                    ],
                ),
            ),
        ])

    if api_url == "":
        failure = True
        message = "API URL must not be blank"

        if debug_output:
            print(message)

    else:
        headerMap = {}
        if request_headers != "" or request_headers != {}:
            request_headers_array = request_headers.split(",")

            for app_header in request_headers_array:
                headerKeyValueArray = app_header.split(":")
                if len(headerKeyValueArray) > 1:
                    headerMap[headerKeyValueArray[0].strip()] = headerKeyValueArray[1].strip()

        output_map = get_data(api_url, debug_output, headerMap, ttl_seconds)
        output_body = output_map["data"]
        output_type = output_map["type"]

        if output_body != None and type(output_body) == "string":
            output = json.decode(output_body, None)

            if output_body != "":
                img = None

                if debug_output:
                    outputStr = str(output)
                    outputLen = len(outputStr)
                    if outputLen >= 200:
                        outputLen = 200

                    if output_type == "json":
                        outputStr = outputStr[0:outputLen]
                        if outputLen >= 200:
                            outputStr = outputStr + "..."
                            print("Decoded JSON truncated: " + outputStr)
                        else:
                            print("Decoded JSON: " + outputStr)

                if failure == False:
                    if output_type == "json":
                        failure = True

                        # Parse response path for JSON
                        output_map = parse_response_path(output, response_path, debug_output)
                        output = output_map["output"]
                        message = output_map["message"]
                        failure = output_map["failure"]

                        if debug_output:
                            print("Response content type JSON")

                        if type(output) == "string" and output.startswith("http") == False and (base_url == "" or base_url.startswith("http") == False):
                            failure = True
                            message = "Base URL required"
                            if debug_output:
                                print("Invalid URL. Requires a base_url")
                        elif type(output) == "string":
                            failure = False
                            if output.startswith("http") == False and base_url != "":
                                if output.startswith("/"):
                                    url = base_url + output
                                else:
                                    url = base_url + "/" + output
                            else:
                                url = output

                            output_map = get_data(url, debug_output, headerMap, ttl_seconds)
                            img = output_map["data"]

                            if debug_output:
                                print("Image URL: " + url)
                        else:
                            if message == "":
                                message = "Bad response path for JSON. Must point to an image URL."
                            if debug_output:
                                print(message)
                            failure = True
                    elif output_type == "xml":
                        failure = False

                        output = xpath.loads(output_body)

                        output_map = parse_response_path(output, response_path, debug_output, True)
                        output = output_map["output"]
                        message = output_map["message"]
                        failure = output_map["failure"]

                        if failure == False and type(output) == "string":
                            if output.startswith("http") == False and base_url != "":
                                if output.startswith("/"):
                                    url = base_url + output
                                else:
                                    url = base_url + "/" + output
                            else:
                                url = output

                            output_map = get_data(url, debug_output, headerMap, ttl_seconds)
                            img = output_map["data"]

                            if debug_output:
                                print("Image URL: " + url)
                        elif response_path == "":
                            message = "Missing response path for XML"
                            if debug_output:
                                print(message)
                            failure = True
                    elif output_type == "image":
                        if debug_output:
                            print("Response content type image")
                        img = output_body
                    else:
                        failure = True
                        message = "Invalid type: " + output_type
                        if debug_output:
                            print(message)

                if img != None:
                    imgRender = render.Image(
                        src = img,
                        height = 32,
                    )

                    if fit_screen == True:
                        imgRender = render.Image(
                            src = img,
                            width = 64,
                        )

                    return render.Root(
                        child = render.Box(
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [imgRender],
                            ),
                        ),
                    )

            else:
                message = "Invalid image URL"
                if debug_output:
                    print(message)
                    print(output)
                failure = True
                # return get_image(base_url, api_url, response_path, request_headers, debug_output)

        else:
            message = "Oops! Check URL and header values. URL " + api_url + " must return JSON or text."
            if debug_output:
                print(message)
            failure = True

    if message == "":
        message = "Could not get image"

    message = "API Image - " + message

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
        child = render.Box(
            row,
        ),
    )

def parse_response_path(output, responsePathStr, debug_output, is_xml = False):
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

                if valid_rand:
                    test_output = output.query_all(path_str)
                    if type(test_output) == "list" and len(test_output) > 0:
                        index = random.number(0, len(test_output) - 1)
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

                if valid_rand:
                    if type(output) == "list":
                        if len(output) > 0 and item == "[rand]":
                            item = random.number(0, len(output) - 1)
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

    if url.endswith("webp"):
        return {"data": res.body(), "type": "image"}

    headers = res.headers
    isValidContentType = False

    headersStr = str(headers)
    headersStr = headersStr.lower()
    headers = json.decode(headersStr, None)
    contentType = ""
    if headers != None and headers.get("content-type") != None:
        contentType = headers.get("content-type")

        if contentType.find("json") != -1 or contentType.find("image") != -1 or contentType.find("xml") != -1 or "webp" in url:
            if contentType.find("json") != -1:
                contentType = "json"
            elif contentType.find("image") != -1 or "webp" in url:
                contentType = "image"
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

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_url",
                name = "API URL",
                desc = "The API URL. Supports JSON, XML or image types.",
                icon = "globe",
                default = "",
            ),
            schema.Text(
                id = "response_path",
                name = "JSON response path",
                desc = "A comma separated path to the image URL in the response JSON or XML. Use `[rand]` to choose a random index. eg. `json_key_1, 0, [rand], json_key_to_image_url`",
                icon = "code",
                default = "",
                # default = "message",
            ),
            schema.Text(
                id = "request_headers",
                name = "Request headers",
                desc = "Comma separated key:value pairs to build the request headers. eg, `x-api-key:abc123,content-type:application/json`",
                icon = "code",
                default = "",
            ),
            schema.Dropdown(
                id = "ttl_seconds",
                name = "Refresh rate",
                desc = "Refresh data at the specified interval. Useful for when an endpoint serves random images.",
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
                id = "fit_screen",
                name = "Fit screen",
                desc = "Fit image on screen.",
                icon = "arrowsLeftRightToLine",
                default = False,
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
