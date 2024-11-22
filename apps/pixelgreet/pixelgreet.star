"""
Applet: PixelGreet
Summary: Customized Guest Greetings
Description: PixelGreet is an app that allows hosts to craft customized messages and images for each guest. Start scheduling greetings at pixelgreet.com. Elevate your hosting, nurture lasting connections, and boost guest satisfaction with this versatile tool.
Author: Justin Gerber
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_MESSAGE = "Welcome! Schedule guest greetings at Pixelgreet.com"
INVALID_API_KEY_MESSAGE = "An invalid API key has been provided."
DEFAULT_PIXEL_GREET_IMAGE = base64.decode("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")
BASE_URL = "https://api.app.pixelgreet.com/Messages"
DEFAULT_CACHE_DURATION = 40
INVALID_KEY_ERROR_NUMBER = 60062

def main(config):
    print("The application is starting...")
    api_key = config.get("key")

    #api_key = "INSERT_KEY_HERE"
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
        show_full_animation = True,
        child = render.Box(
            contents,
        ),
    )

# This function retrieves the image and message based on the provided API key and its validity.
# It checks the format of the provided API key.
# If the API key format is invalid, default values for the image and message are used.
# If the API key format is valid and the key is not cached, the image and message are retrieved from the API and then are later cached.
#
# Args:
#   api_key (str): The API key to be used for the lookup and API call.
#
# Returns:
#   tuple: A tuple containing the image and message (both strings).

def get_image_and_message(api_key):
    if is_api_key_blank(api_key):
        image = DEFAULT_PIXEL_GREET_IMAGE
        message = DEFAULT_MESSAGE
    elif not is_valid_api_key_format(api_key):
        print(INVALID_API_KEY_MESSAGE)
        image = DEFAULT_PIXEL_GREET_IMAGE
        message = INVALID_API_KEY_MESSAGE
    else:
        print("The API key could be valid.")
        image, message = get_decoded_data_from_api(api_key)

    return image, message

# This function retrieves the decoded data from the API using the provided API key.
# It sends an HTTP GET request to the API and checks the response for success. The http.get is cached.
#
# If the response is successful, the image and message are extracted from the response. If the response is unsuccessful, an error message
# is generated using the handle_api_error function.
#
# Args:
#   api_key (str): The API key to be used in the API call.
#
# Returns:
#   tuple: A tuple containing the decoded image and message (both strings).
def get_decoded_data_from_api(api_key):
    response = http.get(BASE_URL, headers = {"x-api-key": api_key}, ttl_seconds = DEFAULT_CACHE_DURATION)

    if response.status_code != 200:
        fail("Failed to get a success response from the Pixel Greet API.", response.status_code)

    if response.json()["success"]:
        print("The API call was successful.")
        image = base64.decode(response.json()["base64Image"])
        message = response.json()["message"]
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
        print(INVALID_API_KEY_MESSAGE)
        return INVALID_API_KEY_MESSAGE
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

# This function checks if the provided API key is blank.
#
# Args:
#   api_key (string): The API key to be validated.
#
# Returns:
#   bool: True if the API is blank, otherwise false
def is_api_key_blank(api_key):
    return api_key in (None, "")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "Key",
                desc = "Pixel Greet API Key",
                icon = "key",
            ),
        ],
    )
