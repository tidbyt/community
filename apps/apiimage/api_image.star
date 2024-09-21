"""
Applet: API image
Summary: API image display
Description: Display an image from an endpoint.
Author: Michael Yagi
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_API_URL = "https://dog.ceo/api/breeds/image/random"
DEFAULT_BASE_URL = ""
DEFAULT_APP_HEADERS = ""
DEFAULT_RESPONSE_PATH = "message"

def main(config):
    base_url = config.str("base_url", DEFAULT_BASE_URL)
    api_url = config.str("api_url", DEFAULT_API_URL)
    response_path = config.get("response_path", DEFAULT_RESPONSE_PATH)
    api_headers = config.get("api_headers", DEFAULT_APP_HEADERS)

    # print("api_url")
    # print(api_url)
    # print("response_path")
    # print(response_path)

    failure = False

    if api_url == "":
        failure = True
        # print("api_url must not be blank.")

    else:
        if api_headers != "" or api_headers != {}:
            api_headers = api_headers.split(",")
            headerMap = {}
            for app_header in api_headers:
                headerKeyValueArray = app_header.split(":")
                if len(headerKeyValueArray) > 1:
                    headerMap[headerKeyValueArray[0].strip()] = headerKeyValueArray[1].strip()

            rep = http.get(api_url, headers = headerMap)
        else:
            rep = http.get(api_url)

        if rep.status_code != 200:
            failure = True
            # print("Request failed with status %d", rep.status_code)

        else:
            json = rep.json()

            if json.get("status") == "fail":
                failure = True

            if failure == False or json != "" or response_path != []:
                responsePathArray = response_path

                responsePathArray = responsePathArray.split(",")

                for item in responsePathArray:
                    item = item.strip()
                    if item.isdigit():
                        item = int(item)

                    # print("item")
                    # print(item)
                    # print(type(json))
                    if (type(json) == "dict" and json.get(item) == None) or (type(json) == "list" and json[item] == None):
                        failure = True

                        # print("responsePathArray invalid. " + item + " does not exist")
                        break
                    else:
                        json = json[item]

                if type(json) == "string" and failure == False:
                    if json.startswith("http") == False and (base_url == "" or base_url.startswith("http") == False):
                        failure = True
                        # print("Invalide URL. Requires a base_url")

                    else:
                        if base_url != "":
                            img = http.get(base_url + json).body()
                        else:
                            img = http.get(json).body()

                        return render.Root(
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [render.Image(src = img, height = 32)],
                            ),
                        )
                else:
                    # print("Invalid path for image")
                    # print(json)
                    failure = True
            else:
                # print("Status failed")
                # print(json)
                failure = True

    # if failure == True:
    # fail()
    # print("Something went wrong")
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [render.Text("Could not get image.")],
        ),
    )

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
                default = "https://dog.ceo/api/breeds/image/random",
            ),
            schema.Text(
                id = "response_path",
                name = "Response path",
                desc = "A comma separated path to the image in the response JSON. eg. `json_key1, 2, key_to_image_url`",
                icon = "",
                default = "message",
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
