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
    api_headers = config.get("api_headers", "")
    debug_output = config.bool("debug_output", False)

    if debug_output:
        print("api_url")
        print(api_url)
        print("response_path")
        print(response_path)
        print("api_headers")
        print(api_headers)
        print("debug_output")
        print(debug_output)

    return get_image(base_url, api_url, response_path, api_headers, debug_output)

def get_image(base_url, api_url, response_path, api_headers, debug_output):
    failure = False
    message = ""

    if api_url == "":
        failure = True
        message = "API URL must not be blank"

        if debug_output:
            print("api_url must not be blank.")

    else:
        headerMap = {}
        if api_headers != "" or api_headers != {}:
            api_headers_array = api_headers.split(",")

            for app_header in api_headers_array:
                headerKeyValueArray = app_header.split(":")
                if len(headerKeyValueArray) > 1:
                    headerMap[headerKeyValueArray[0].strip()] = headerKeyValueArray[1].strip()

        json_body = get_cached(api_url, debug_output, headerMap)

        if json_body != None:
            decoded_json = json.decode(json_body)

            if debug_output:
                print("Decoded JSON")
                print(decoded_json)

            if decoded_json.get("status") == "fail":
                failure = True

            if failure == False or decoded_json != "" or response_path != []:
                responsePathArray = response_path

                responsePathArray = responsePathArray.split(",")

                for item in responsePathArray:
                    item = item.strip()
                    if item.isdigit():
                        item = int(item)

                    if debug_output:
                        print("item")
                        print(item)
                        print(type(decoded_json))

                    if (type(decoded_json) == "dict" and decoded_json.get(item) == None) or (type(decoded_json) == "list" and decoded_json[item] == None):
                        failure = True
                        message = "Response path invalid. " + item + " does not exist"
                        if debug_output:
                            print("responsePathArray invalid. " + item + " does not exist")
                        break
                    else:
                        decoded_json = decoded_json[item]

                if type(decoded_json) == "string" and failure == False:
                    if decoded_json.startswith("http") == False and (base_url == "" or base_url.startswith("http") == False):
                        failure = True
                        message = "Base URL missing"
                        if debug_output:
                            print("Invalide URL. Requires a base_url")

                    else:
                        if base_url != "":
                            url = base_url + decoded_json
                        else:
                            url = decoded_json

                        img = get_cached(url, debug_output)

                        if debug_output:
                            print("URL: " + url)

                        if img != None:
                            return render.Root(
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [render.Image(src = img, height = 32)],
                                ),
                            )
                else:
                    message = "Invalid image path"
                    if debug_output:
                        print("Invalid image path")
                        print(decoded_json)
                    failure = True
                    # return get_image(base_url, api_url, response_path, api_headers, debug_output)

            else:
                message = "Something went wrong."
                if debug_output:
                    print("Status failed")
                    print(decoded_json)
                failure = True
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
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.WrappedText(content = message, font = "5x8"),
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

    if res.status_code != 200:
        if debug_output:
            print("status %d from %s: %s" % (res.status_code, url, res.body()))
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
                id = "base_url",
                name = "Base URL",
                desc = "The base URL if URLs are relative paths.",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "api_url",
                name = "URL",
                desc = "The API url.",
                icon = "",
                default = "",
                # default = "https://dog.ceo/api/breeds/image/random",
            ),
            schema.Text(
                id = "response_path",
                name = "Response path",
                desc = "A comma separated path to the image in the response JSON. eg. `json_key1, 2, key_to_image_url`",
                icon = "",
                default = "",
                # default = "message",
            ),
            schema.Text(
                id = "api_headers",
                name = "Request headers",
                desc = "Comma separated key:value pairs to build the request headers. eg, `x-api-key:abc123,content-type:application/json`",
                icon = "",
                default = "",
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
