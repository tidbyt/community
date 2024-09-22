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

DEBUG = False

def main(config):
    base_url = config.str("base_url", "")
    api_url = config.str("api_url", "")
    response_path = config.get("response_path", "")
    api_headers = config.get("api_headers", "")

    if DEBUG:
        print("api_url")
        print(api_url)
        print("response_path")
        print(response_path)
        print("api_headers")
        print(api_headers)

    return get_image(base_url, api_url, response_path, api_headers)

def get_image(base_url, api_url, response_path, api_headers):
    failure = False

    if api_url == "":
        failure = True
        if DEBUG:
            print("api_url must not be blank.")

    else:
        headerMap = {}
        if api_headers != "" or api_headers != {}:
            api_headers_array = api_headers.split(",")

            for app_header in api_headers_array:
                headerKeyValueArray = app_header.split(":")
                if len(headerKeyValueArray) > 1:
                    headerMap[headerKeyValueArray[0].strip()] = headerKeyValueArray[1].strip()

        json_body = get_cached(api_url, headerMap)

        decoded_json = json.decode(json_body)

        if DEBUG:
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

                if DEBUG:
                    print("item")
                    print(item)
                    print(type(decoded_json))

                if (type(decoded_json) == "dict" and decoded_json.get(item) == None) or (type(decoded_json) == "list" and decoded_json[item] == None):
                    failure = True
                    if DEBUG:
                        print("responsePathArray invalid. " + item + " does not exist")
                    break
                else:
                    decoded_json = decoded_json[item]

            if type(decoded_json) == "string" and failure == False:
                if decoded_json.startswith("http") == False and (base_url == "" or base_url.startswith("http") == False):
                    failure = True
                    if DEBUG:
                        print("Invalide URL. Requires a base_url")

                else:
                    if base_url != "":
                        url = base_url + decoded_json
                    else:
                        url = decoded_json

                    img = get_cached(url)

                    if DEBUG:
                        print("URL: " + url)

                    return render.Root(
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [render.Image(src = img, height = 32)],
                        ),
                    )
            else:
                if DEBUG:
                    print("Invalid path for image")
                    print(decoded_json)
                failure = True
                return get_image(base_url, api_url, response_path, api_headers)
        else:
            if DEBUG:
                print("Status failed")
                print(decoded_json)
            failure = True

    return render.Root(
        child = render.Box(
            # render.Row(
            #     expanded=True,
            #     main_align="space_evenly",
            #     cross_align="center",
            #     children = [
            #         render.WrappedText(content = "Could not get image", font = "5x8"),
            #     ],
            # ),
        ),
    )

def get_cached(url, headerMap = {}, ttl_seconds = 20):
    data = cache.get(url)
    if data:
        return data

    if headerMap == {}:
        res = http.get(url)
    else:
        res = http.get(url, headers = headerMap)

    if res.status_code != 200:
        if DEBUG:
            print("status %d from %s: %s" % (res.status_code, url, res.body()))
        fail("status %d from %s: %s" % (res.status_code, url, res.body()))

    data = res.body()

    cache.set(url, data, ttl_seconds = ttl_seconds)

    return data

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
        ],
    )
