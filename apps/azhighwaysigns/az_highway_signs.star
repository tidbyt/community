"""
Applet: AZ Highway Signs
Summary: Mirrors AZ highway signs
Description: Uses the AZ 511 API to show the current message from any highway sign.
Author: CJ Sturgess
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

AZ_511_API_URL = "https://az511.com/api/v2/get/messagesigns"
AZ_511_API_KEY_ENC = "AV6+xWcElNUxy13PiZk50KSeRVpd8LanTKPhbBsOqWjCsGYoidZXDXWG2XxTbXZrXTSk8q4aqxWjXxwkITyHHD5P2oDFI1MP9eTfJqu5EPEYOcBRi/WboQgauip1dwKhNtCMtchXuygRw6xj/18Zy9zUgGQ9L+lneYKLO2TLssMkEc+Yt2U="

DEFAULT_SIGN = """{"value": "AZ--858d88ac-89d8-4760-97cc-642bfe3ca07c"}"""

def get_all_signs(api_key = secret.decrypt(AZ_511_API_KEY_ENC)):
    if api_key == None:
        return []

    # Returns a list of all AZ Highway signs from the 511 API.
    rep = http.get(AZ_511_API_URL + "?key=" + api_key, ttl_seconds = 300)
    if rep.status_code != 200:
        print("Failed to get message signs with status code %d.", rep.status_code)

    return rep.json()

def get_sign(api_key, id):
    # Returns a single sign from the AZ 511 API for a given ID.

    all_signs = get_all_signs(api_key)
    for sign in all_signs:
        if sign["Id"] == id:
            return sign
    return None

def get_sign_options(loc):
    # Gets all sign options to allow the user to choose one during app installation.

    loc = json.decode(loc)
    all_signs = get_all_signs()

    for sign in all_signs:
        sign["dist"] = math.sqrt(math.pow(sign["Latitude"] - float(loc["lat"]), 2) + math.pow(sign["Longitude"] - float(loc["lng"]), 2))

    all_signs = sorted(all_signs, key = lambda s: s["dist"])

    sign_options = []
    for sign in all_signs:
        sign_options.append(
            schema.Option(
                display = sign["Name"],
                value = sign["Id"],
            ),
        )

    return sign_options

def get_message_lines(sign):
    if sign == None:
        return []

    messages = sign["Messages"]
    message_idx = 0

    if len(messages) > 1:
        message_idx = random.number(0, len(messages) - 1)

    message = messages[message_idx]
    message_lines = message.split("\r\n")

    return message_lines

def render_message_default(lines):
    message_rows = []

    for line in lines:
        message_rows.append(
            render.Marquee(
                width = 64,
                align = "center",
                child = render.Text(line),
            ),
        )

    return message_rows

def render_message_minutesto(lines):
    message_rows = []

    # Render the first line as normal
    lines[0] = lines[0].replace("PHOENIX", "PHX")
    message_rows.append(
        render.Marquee(
            width = 64,
            align = "center",
            child = render.Text(lines[0]),
        ),
    )

    # Render the subsequent lines
    # Location name is left-adjusted, distance is right-adjusted
    for line in lines[1:]:
        msg_dist_to = line[:-3].strip()
        msg_dist = line[-3:].strip()

        message_rows.append(
            render.Row(
                children = [
                    render.Marquee(
                        width = 48,
                        delay = 16,
                        child = render.Text(msg_dist_to),
                    ),
                    render.Marquee(
                        width = 16,
                        align = "end",
                        child = render.Text(
                            content = msg_dist,
                            color = "#ff6",
                        ),
                    ),
                ],
            ),
        )

    return message_rows

def render_message_nomessage(sign):
    message_rows = []

    for idx, line in enumerate(sign["Name"].split("@")):
        if idx == 1:
            line = "@" + line

        message_rows.append(
            render.Marquee(
                width = 64,
                align = "center",
                child = render.Text(line.strip()),
            ),
        )

    message_rows.append(
        render.Marquee(
            width = 64,
            align = "center",
            child = render.Text(
                content = "NO MESSAGE",
                color = "#f00",
            ),
        ),
    )

    return message_rows

def render_message_apierror():
    return [
        render.Marquee(
            width = 64,
            align = "center",
            child = render.Text(
                content = "API Key Missing",
                color = "#f00",
            ),
        ),
    ]

def render_message(sign):
    if sign == None:
        return render_message_apierror()

    lines = get_message_lines(sign)

    # If this is a "minutes-to" message, render appropriately
    if "MIN" in lines[0]:
        return render_message_minutesto(lines)

    # If this message is "NO_MESSAGE", make it cleaner
    if lines[0] == "NO_MESSAGE":
        return render_message_nomessage(sign)

    # Otherwise, render using default method
    return render_message_default(lines)

def main(config):
    api_key = secret.decrypt(AZ_511_API_KEY_ENC) or config.get("dev_api_key")
    if api_key == None:
        print("An AZ 511 API Key must be provided.")

    SELECTED_SIGN = json.decode(config.get("sign", DEFAULT_SIGN))
    SIGN_ID = SELECTED_SIGN["value"]

    sign = get_sign(api_key, SIGN_ID)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = render_message(sign),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "sign",
                name = "Message Sign",
                desc = "The message sign to check.",
                icon = "car",
                handler = get_sign_options,
            ),
        ],
    )
