"""
Applet: API image
Summary: API image display
Description: Display an image from an API endpoint.
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

    base_url = config.str("base_url", "")
    api_url = config.str("api_url", "")
    response_path = config.get("response_path", "")
    request_headers = config.get("request_headers", "")
    debug_output = config.bool("debug_output", False)
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

    return get_image(base_url, api_url, response_path, request_headers, debug_output, fit_screen, ttl_seconds)

def get_image(base_url, api_url, response_path, request_headers, debug_output, fit_screen, ttl_seconds):
    failure = False
    message = ""

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

        output_body = get_data(api_url, debug_output, headerMap, ttl_seconds)

        if output_body != None and type(output_body) == "string":
            output = json.decode(output_body, None)
            responsePathArray = []

            if output_body != "":
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

                if failure == False:
                    img = None

                    if output != None:
                        if response_path != "":
                            # Parse response path for JSON
                            if response_path != "":
                                responsePathArray = response_path

                                responsePathArray = responsePathArray.split(",")

                                for item in responsePathArray:
                                    item = item.strip()

                                    if item == "[rand]":
                                        if type(output) == "list":
                                            item = random.number(0, len(output) - 1)
                                            if debug_output:
                                                print("Random index chosen " + str(item))
                                        else:
                                            failure = True
                                            message = "Response path invalid. Use of [rand] only allowable in lists."
                                            if debug_output:
                                                print("responsePathArray invalid. Use of [rand] only allowable in lists.")
                                            break

                                    if type(item) != "int" and item.isdigit():
                                        item = int(item)

                                    if debug_output:
                                        print("path array item: " + str(item) + " - type " + str(type(output)))

                                    if output != None and type(output) == "dict" and type(item) == "string" and output.get(item) != None:
                                        output = output[item]
                                    elif output != None and type(output) == "list" and type(item) == "int" and item <= len(output) - 1 and output[item] != None:
                                        output = output[item]
                                    else:
                                        failure = True
                                        message = "Response path invalid. " + str(item) + " does not exist or value is null"
                                        if debug_output:
                                            print("responsePathArray invalid. " + str(item) + " does not exist or value is null")
                                        break

                            if debug_output:
                                print("Response content type JSON")

                            if type(output) == "string" and output.startswith("http") == False and (base_url == "" or base_url.startswith("http") == False):
                                failure = True
                                message = "Base URL required"
                                if debug_output:
                                    print("Invalid URL. Requires a base_url")
                            elif type(output) == "string":
                                if output.startswith("http") == False and base_url != "":
                                    url = base_url + output
                                else:
                                    url = output

                                img = get_data(url, debug_output, {}, ttl_seconds)

                                if debug_output:
                                    print("Image URL: " + url)
                            else:
                                if message == "":
                                    message = "Bad response path for JSON. Must point to an image URL."
                                if debug_output:
                                    print(message)
                                failure = True
                        else:
                            message = "Missing response path for JSON"
                            if debug_output:
                                print(message)
                            failure = True

                    else:
                        if debug_output:
                            print("Response content type image")
                        img = output_body

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
            message = "Oops! Check URL and header values. URL must return JSON or image."
            if debug_output:
                print(message)
            failure = True

    if message == "":
        message = "Could not get image"

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

        if contentType.find("json") != -1 or contentType.find("image") != -1:
            isValidContentType = True

    if debug_output:
        print("isValidContentType for " + url + " content type " + contentType + ": " + str(isValidContentType))

    if res.status_code != 200 or isValidContentType == False:
        if debug_output:
            print("status: " + str(res.status_code))
            print("Requested url: " + str(url))
    else:
        data = res.body()

        return data

    return None

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
                desc = "The API URL. Supports JSON or image types.",
                icon = "",
                default = "",
                # default = "https://dog.ceo/api/breeds/image/random",
            ),
            schema.Text(
                id = "base_url",
                name = "Base URL",
                desc = "The base URL if response JSON contains relative paths.",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "response_path",
                name = "JSON response path",
                desc = "A comma separated path to the image URL in the response JSON. Use `[rand]` to choose a random index. eg. `json_key_1, 0, [rand], json_key_to_image_url`",
                icon = "",
                default = "",
                # default = "message",
            ),
            schema.Text(
                id = "request_headers",
                name = "Request headers",
                desc = "Comma separated key:value pairs to build the request headers. eg, `x-api-key:abc123,content-type:application/json`",
                icon = "",
                default = "",
            ),
            schema.Dropdown(
                id = "ttl_seconds",
                name = "Refresh rate",
                desc = "Refresh data at the specified interval. Useful for when an endpoint serves random images.",
                icon = "",
                default = ttl_options[1].value,
                options = ttl_options,
            ),
            schema.Toggle(
                id = "fit_screen",
                name = "Fit screen",
                desc = "Fit image on screen.",
                icon = "",
                default = False,
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
