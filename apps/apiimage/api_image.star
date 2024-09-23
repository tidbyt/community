"""
Applet: API image
Summary: API image display
Description: Display an image from an endpoint.
Author: Michael Yagi
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    base_url = config.str("base_url", "")
    api_url = config.str("api_url", "")
    response_path = config.get("response_path", "")
    request_headers = config.get("request_headers", "")
    debug_output = config.bool("debug_output", False)
    fit_screen = config.bool("fit_screen", False)

    if debug_output:
        print("------------------------------")
        print("CONFIG - api_url: " + api_url)
        print("CONFIG - response_path: " + response_path)
        print("CONFIG - request_headers: " + request_headers)
        print("CONFIG - debug_output: " + str(debug_output))
        print("CONFIG - fit_screen: " + str(fit_screen))

    return get_image(base_url, api_url, response_path, request_headers, debug_output, fit_screen)

def get_image(base_url, api_url, response_path, request_headers, debug_output, fit_screen):
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

        output_body = get_cached(api_url, debug_output, headerMap)

        if output_body != None and type(output_body) == "string":
            output = json.decode(output_body, None)
            responsePathArray = []

            if debug_output:
                print("Decoded JSON length: " + str(len(str(output))))

            if failure == False or output_body != "":
                if response_path != "":
                    responsePathArray = response_path

                    responsePathArray = responsePathArray.split(",")

                    for item in responsePathArray:
                        item = item.strip()
                        if item.isdigit():
                            item = int(item)

                        if debug_output:
                            print("path array item: " + str(item) + " - type " + str(type(output)))

                        if (type(output) == "dict" and output.get(item) == None) or (type(output) == "list" and output[item] == None) or type(output) == "string":
                            failure = True
                            message = "Response path invalid. " + str(item) + " does not exist"
                            if debug_output:
                                print("responsePathArray invalid. " + str(item) + " does not exist")
                            break
                        elif output != None and (type(output) == "string" or (type(output) == "dict" and output.get(item) == None)):
                            failure = True
                            message = "Response path invalid. " + str(item) + " does not exist"
                            if debug_output:
                                print("responsePathArray invalid. " + str(item) + " does not exist")
                            break
                        elif output != None and output.get(item) != None:
                            output = output[item]

                if failure == False:
                    img = None
                    if output != None:
                        if len(responsePathArray) > 0:
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

                                img = get_cached(url, debug_output)

                                if debug_output:
                                    print("Image URL: " + url)
                            else:
                                message = "Bad path for JSON"
                                if debug_output:
                                    print(message)
                                failure = True
                        else:
                            message = "Missing path for JSON"
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
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [imgRender],
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
            message = "Something went wrong. Check URL and header values."
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

def get_cached(url, debug_output, headerMap = {}, ttl_seconds = 20):
    data = cache.get(url)
    if data:
        return data

    if headerMap == {}:
        res = http.get(url)
    else:
        res = http.get(url, headers = headerMap)

    headers = res.headers
    isValidContentType = False

    headersStr = str(headers)
    headersStr = headersStr.lower()
    headers = json.decode(headersStr, None)
    if headers != None and headers.get("content-type") != None:
        contentType = headers.get("content-type")

        if contentType.find("json") != -1 or contentType.find("image") != -1:
            isValidContentType = True

    if debug_output:
        print("isValidContentType for "+url+": " + str(isValidContentType))

    if res.status_code != 200 or isValidContentType == False:
        if debug_output:
            print("status: " + str(res.status_code))
            print("Requested url: " + str(url))
    else:
        data = res.body()

        cache.set(url, data, ttl_seconds = ttl_seconds)

        return data

    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_url",
                name = "URL",
                desc = "The API URL. Supports JSON or image types.",
                icon = "",
                default = "",
                # default = "https://dog.ceo/api/breeds/image/random",
            ),
            schema.Text(
                id = "base_url",
                name = "Base URL",
                desc = "The base URL if response JSON contain relative paths.",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "response_path",
                name = "JSON response path",
                desc = "A comma separated path to the image URL in the response JSON. eg. `json_key1, 2, key_to_image_url`",
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
                desc = "Toggle debug message output.",
                icon = "",
                default = False,
            ),
        ],
    )
