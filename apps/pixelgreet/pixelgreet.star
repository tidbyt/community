"""
Applet: PixelGreet
Summary: Customized Guest Greetings
Description: PixelGreet is an app that allows hosts to craft customized messages and images for each guest. Make your guests feel at home with a personal touch, creating memorable experiences. Elevate your hosting, nurture lasting connections, and boost guest satisfaction with this versatile tool.
Author: Justin Gerber
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_MESSAGE = "Please provide an API Key."
DEFAULT_PIXEL_GREET_IMAGE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAADAAAABACAYAAABcIPRGAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAylpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDcuMS1jMDAwIDc5LmVkYTJiM2ZhYywgMjAyMS8xMS8xNy0xNzoyMzoxOSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NTg5MzgxNEJCN0E3MTFFREI4QzlDNzNDQkJFODhBRDgiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NTg5MzgxNEFCN0E3MTFFREI4QzlDNzNDQkJFODhBRDgiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTkgKFdpbmRvd3MpIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6NzYyMDAwMEE2RjE4MTFFREE0QzJEMkEwMEU4QUQ0QzEiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6NzYyMDAwMEI2RjE4MTFFREE0QzJEMkEwMEU4QUQ0QzEiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz7YL6d3AAAE20lEQVR42uyaa2hUVxDHZze7JtmEaDRrNGg/1ESjiCIajfRDsVBoC7W19ItY6QcJFOoLNSCiaKD0Q1JdoS2llVTUPhEqmKq1vrCITWyiUkTjA5XEtIkbE/JodpO7u9eZ3YndbneTe+fefQh34Pcl5J4z/3PPnTMze2yvv/0Anmezw3NulgBLgCXAEpBec5g0ThGyAlmGzEVeRIqRSYgN6UW6kPvILaQJuYB0p1NAIfI+shqpYEfH+l+iHHmD/6YifyDfI4dYZEq20DSkDmlDPMjScZxPZDZ+lsZoR/Yj05MpgN7WFuQusg3JN3Er5yGbkDs8h8NsAaXI78hekx2PtXyeg+YqM0vAm0gLsiSFwYXmaua5DQlYhxxDCtIQIQt47nVSAVXIASQrjWE+i32o0itgJfKFMLqYbTb2ZaVWAbOQw2le+Xhv4jD7NqYACl8/IhMzMGuYyL45xhJAsXhxBqc+5NvGRKkEnbB79I64e8dUyHPZw3nBeBtZCajw4KECLdd8cP1PH6iqSEQN8h3SGStgq+SQml2WDYWTtH8uixbmwjtvFcCNm374+lAvtN4Zlhx25Gt19BaiROsDyXI0t/hEyzh/Xg58tLsY5pZnSx4nXydHC1gtTREaTvaLN7QLt972rW6YXJgleQtrowWslTpx7/4InDw9IBbhLnLAu6tEQW/NqIAiLkTE9lV9D/x26R/x8y8td0nzpSIS8IrRE3dEUaHW44WDR3qh63FAfzk3RVRXkc8r6MlKMwJ0KARw9Kc+OPHLACyYnwNlpRMgJ9sONg1L4x9WpdNWkoA5Zp40Q0MhaLwyFCYFVu7QWjhoKi5wQ1YsdsGyilyYUeKEnFy7ZtHbd3VKpiwlAW4znC+Z7oTN66eE47teUxTxFnI7zChWZs5wQs3OYphWLGtytHco4gTPcGPL6bRB9Wa32Hmy4z/LD0MS0G9EQOVSF5TOmiB+/nLjEJw5Pyh9vI8EeI0IeO1VeZOCEjrPp93SrJTM6+A+jzgSzSnTn4x1dgXgzLlBONbQB36/amT97pGA2/Bvu0+3HTjYE/4Onh2PeHKNHl52/sLCK6zSgRWCtkcKPMSawOcPmRH8WklAo5ERTp8dhDRaEwm4EFkfWT70uacE8vP/H8zoLXxc65UULFqNfD7v4I+4SZoTUfjMTXDiDo+oyVx96tx1j858RDqKkiD57PhLgQ75AaXFvo0uaH5ATN3MVOSMKEl7A+TrN9ECeqguMWv0K1gnnzg1kMzVJ1+fxPaF6iRvITbfv3rdB7X7vMle/bp4faFO7rnU6U2hydm2dgVO4bb5FQ+oYDCpH2/NaE8ovIAxlz2cHJEWQWbaNYj8LBWITub+E1S42h/IQOcH2bdAbDYaa/Qz6HtIMIOcD7Lzt+Kl03FTdORDPu3SbSr7cjxRPZDIvoTILyPBNK98FfsCegWQ1SOrjBY9QuvnuevHq8jGswaIdMGupjjaLOG5wagA4KKH2o/VZqcccSJNNYfKu1prYq1G4esTrt72mSyEumCfIbN5Ds39SUlXgk5B+oHhBYhcC2gWRiuVn6UxZiIbkL/1DmLktgrdLvEwU5GXkeUQuZFC122o653H/0uta7paQ9dtWiFyleAi8tjoqzPrvhA5cpRJqVlXziwBlgBLgCXAkD0VYAC/ZT2VR0DcHQAAAABJRU5ErkJggg==")
BASE_URL = "https://qa.api.app.pixelgreet.com/Messages"
DEFAULT_CACHE_DURATION = 300
INVALID_KEY_ERROR_NUMBER = 60062

def main(config):
    print("The application is starting...")
    api_key = config.get("key")

    #api_key = "TEST_API_KEY"
    image, message = get_image_and_message(api_key)

    # Setup the image and marquee
    image = render.Image(
        width = 24,
        height = 24,
        src = image,
    )
    text = render.Text(
        message,
        font = "tb-8",
    )
    marquee_horizontal = render.Marquee(
        width = 36,
        offset_start = 18,
        offset_end = 18,
        child = text,
        align = "center",
    )
    contents = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            image,
            marquee_horizontal,
        ],
    )
    return render.Root(
        child = render.Box(
            contents,
        ),
    )

# This function retrieves the image and message based on the provided API key and its validity.
# It checks the format of the provided API key and its presence in the cache.
# If the API key format is invalid, default values for the image and message are used.
# If the API key format is valid and the key is cached, the image and message are retrieved from the cache.
# If the API key format is valid and the key is not cached, the image and message are retrieved from the API and then are later cached.
#
# Args:
#   api_key (str): The API key to be used for the cache lookup and API call.
#   valid_api_key_format (bool): True if the API key has a valid format, False otherwise.
#
# Returns:
#   tuple: A tuple containing the image and message (both strings).

def get_image_and_message(api_key):
    if not is_valid_api_key_format(api_key):
        print("An invalid API key has been provided.")
        image = DEFAULT_PIXEL_GREET_IMAGE
        message = DEFAULT_MESSAGE
    elif is_api_key_cached(api_key):
        print("The API key is valid and is cached.")
        image, message = get_decoded_data_from_cache(api_key)
    else:
        print("The API key is valid and is not cached.")
        image, message = get_decoded_data_from_api(api_key)

    return image, message

# This function retrieves the decoded data from the cache using the provided API key.
# It checks if the API key is already in the cache and, if so, extracts the image and message
# from the cached data.
#
# Args:
#   api_key (str): The API key used to access the cache.
#
# Returns:
#   tuple: A tuple containing the decoded image and message (both strings) if the API key is in the cache.
def get_decoded_data_from_cache(api_key):
    decoded_data = json.decode(cache.get(api_key))
    image = base64.decode(decoded_data["image"])
    message = decoded_data["message"]
    return image, message

# This function retrieves the decoded data from the API using the provided API key.
# It sends an HTTP GET request to the API and checks the response for success.
#
# If the response is successful, the image and message are extracted from the response,
# and the data is cached for future use. If the response is unsuccessful, an error message
# is generated using the handle_api_error function, and default values are used for the image and message.
#
# Args:
#   api_key (str): The API key to be used in the API call.
#
# Returns:
#   tuple: A tuple containing the decoded image and message (both strings).
def get_decoded_data_from_api(api_key):
    response = http.get(BASE_URL, headers = {"x-api-key": api_key})

    if response.status_code != 200:
        fail("Failed to get a success response from the Pixel Greet API.", response.status_code)

    if response.json()["success"]:
        print("The API call was successful.")
        image = base64.decode(response.json()["base64Image"])
        message = response.json()["message"]
        data = {"image": response.json()["base64Image"], "message": message}
        cache.set(api_key, json.encode(data), ttl_seconds = DEFAULT_CACHE_DURATION)
    else:
        error_message = handle_api_error(response)
        image = DEFAULT_PIXEL_GREET_IMAGE
        message = error_message

    return image, message

# This function handles API errors based on the error number in the response.
# It is called when the API response is unsuccessful. The function extracts the error number
# from the response and prints an appropriate message based on the error number.
#
# Note: The returned error message string can be used by the calling function to handle the error further.
#
# Args:
#   response (object): The HTTP response object from the API call.
#
# Returns:
#   str: A string containing the error message based on the error number.
def handle_api_error(response):
    print("The API call was unsuccessful.")
    error_number = response.json()["error"]["errorNumber"]

    if error_number == INVALID_KEY_ERROR_NUMBER:
        print("An invalid API key has been provided.")
        return "An invalid API key has been provided."
    else:
        print("An unknown error has occurred.")
        return "An unknown error has occurred."

# This function checks if the provided API key has a valid format.
# A valid API key format must:
#   1. Not be an empty string or None.
#   2. Contain exactly 2 hyphens.
#
# Note: This function does not guarantee that the API key is valid, but it ensures
#       that the API key has the potential to be right based on the format.
#
# Args:
#   api_key (string): The API key to be validated.
#
# Returns:
#   bool: True if the API key has a valid format, False otherwise.
def is_valid_api_key_format(api_key):
    return api_key and api_key.count("-") == 2

# This function checks if the given API key is present in the cache.
# It also ensures that the value from the cache is not an empty string or None.
#
# Args:
#   api_key (string): The API key to be checked.
#
# Returns:
#   bool: True if the value from the cache is not empty or None, False otherwise.
def is_api_key_cached(api_key):
    cached_value = cache.get(api_key)
    return cached_value not in (None, "")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "API Key",
                desc = "Pixel Greet API Key",
                icon = "key",
            ),
        ],
    )
