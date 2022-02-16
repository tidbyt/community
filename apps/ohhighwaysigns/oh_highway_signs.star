"""
Applet: OH Highway Signs
Summary: Displays OH highway messages
Description: Displays messages from overhead signs on Ohio highways.
Author: noahcolvin
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/json.star", "json")
load("secret.star", "secret")

URL = "https://publicapi.ohgo.com/api/v1/digital-signs?sign-type=dms"
DEFAULT_SIGN = "101"

def main(config):
    api_key = secret.decrypt("AV6+xWcEFT0/uO+MIF1nqdUV9MCnGUVFCtB+I9FD73Vpi9ABgHACrEHktSMnfcIif+AWJlw75vLAfjMBk+CimTjt/Mx303xuNk+hngvoPLYDmi4WiDPwSAMmRJSwEwCS73gxwPyf7GrY/UfglJRVBh52ufshdWelwJfUk4owaCDcWqcrXTE7tFCQ") or config.str("dev_api_key")
    sign_id = config.str("sign_id") or DEFAULT_SIGN

    text = get_sign_text(api_key, sign_id)
    print(text)

    return render.Root(
        child = render.Column(
            expanded=True,
            main_align="space_evenly",
            cross_align="center",
            children = [
                marquee_with_text(text[0]),
                marquee_with_text(text[1]),
                marquee_with_text(text[2]),
            ]
        ),
    )

def marquee_with_text(text):
    length = len(text) * 5
    if length > 64:
        length = 64

    return render.Marquee(
        width = length,
        child = render.Text(
            color = "#fa0",
            content = text,
            font = "5x8"
        )
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "sign",
                name = "Nearby Sign",
                desc = "A list of signs near you.",
                icon = "rectangleList",
                handler = get_signs,
            )
        ],
    )

def get_signs(location):
    loc = json.decode(location)

    return [
        schema.Option(
            display = "Grand Central",
            value = "grand_central",
        ),
    ]

def get_sign_text(api_key, sign_id):
    signs = load_signs(api_key)
    sign = find_sign(signs, sign_id)
    print(sign)

    return split_line(sign["messages"][0])

def split_line(line):
    # max 13 chars
    lines = line.split("\r\n")
    lines[0] = lines[0].lstrip().rstrip().replace("   ", " ")
    lines[1] = lines[1].lstrip().rstrip().replace("   ", " ")
    lines[2] = lines[2].lstrip().rstrip().replace("   ", " ")
    return lines

def headers(api_key):
    return {"Authorization": "APIKEY {}".format(api_key)}

def load_signs(api_key):
    resp = http.get(URL, headers = headers(api_key))

    if resp.status_code != 200:
        print("request failed with status {}".format(resp.status_code))
        return None
    print("success")
    data = resp.json()
    return data["results"]

def find_sign(results, sign_id):
    for result in results:
        if result["id"] == sign_id:
            return result

    return None