"""
Applet: WiFi QR Code
Summary: Creates a WiFi QR code
Description: This app creates a scannable WiFi QR code. It is not compatible with Enterprise networks. Since there are display limitations with the Tidbyt, not all networks will be able to be encoded. Simply scan the QR code and your phone will join the WiFi network.
Author: misusage
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("qrcode.star", "qrcode")
load("schema.star", "schema")

WIFI_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAC2klEQVRYR+2Wv09aURTHDySAgCSQVFxoiykxUWkKYXHjLyCykQATKwv/AJN/g7sDuOripg5OjmAhhKQdWkJiZKgD0gCx9nyP3ubxeJVb2oaFm7y89+49734/58c779lowcO2YH1aAiwjME8E8MxrPhymAh7zfYePxz8p7HkAvDs7O30rkWazucrz9/8LIMrCH9XmLDalw+syx2vv+dTQAdGNgIc3F8+shE1CP9jWznZ+nv9uWBtZAVkBmHPsVp6/JO5wOCgUCpHdbqeVlZUprV6v9+H29hYRnKgRKwDLHM/yHOE/Ozuj1VWUweTgucdoNGqzqhEjAK4R6l8FBlGV11arRVtbW7Kz8VrZmMVtNht5PB66v3+qyZubG0qn00ghCAcqEkaANyz2Bcb7+/vk8/moVCrRyckJDYdDymQyVK1W6e7ujorFIh0cHJDb7aZCoSACh4eHcu1yueQe6YB9MpkkpOf4+Jj6/T7t7e0B4i2bfIWdEeAdA3xSHuHhXC5HjUZDABKJBF1dXdH6+jptbGwQPES+Hx4e6OjoSGDi8bh4ioE1zNXrdbHd3t4WEE4FACJs8vlFgEqlQvl8fgoAkUFazs/Pyev10u7urkQJIxaLiZfGgZpwOp3UbrdpbW1NHwDeWhUUvAGAWodHRgCI+/1+EQQg7AHQ6XQoGAzqA1xeXlIgEKDR6On1RfjG47G8Yi8B1Go1CX84HJbzXAAqZ8htNpsVABRmuVyWRgQArKHKUdmnp6dik0ql6Pr6eiIFkUhEInBxcSFvxMwixNMQURDq/YeosRcgvPASqQAIxmAwmEqbqgmd11A2YSHpVH/TeCZCwDe6jUg9N/HRUZNmINTE5uamWeu3991uN8Y9BPmZ2YqxiZsP1SPQHXs6UXmOoEAw8Cs+GT9G6H5TQ/dr6GeIb8anzRFRLftZ/J9/jo3aC/shURAL/yXTLjwdQ90a0NlrLpslwDICPwEtiFAw6YIxRAAAAABJRU5ErkJggg==
""")

def get_schema():
    options = [
        schema.Option(
            display = "WEP",
            value = "WEP",
        ),
        schema.Option(
            display = "WPA/WPA2/WPA3 - Personal",
            value = "WPA",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ssid",
                name = "SSID",
                desc = "What is your network name/SSID?",
                icon = "wifi",
                default = "",
            ),
            schema.Text(
                id = "password",
                name = "Password",
                desc = "What is your WiFi Password?",
                icon = "key",
                default = "",
            ),
            schema.Dropdown(
                id = "encryption",
                name = "Authentication Method",
                desc = "What is the authentication method for your WiFi?",
                icon = "lock",
                default = options[1].value,
                options = options,
            ),
        ],
    )

def main(config):
    ssid = config.str("ssid", None)
    password = config.str("password", "")
    encryption = config.get("encryption", "WPA")

    if (ssid == None):
        show = render.Stack(
            children = [
                render.Column(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.WrappedText(
                                    align = "center",
                                    content = "WiFi QR Code Generator",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )

    else:
        url = "WIFI:T:" + encryption + ";S:" + ssid + ";P:" + password + ";;"

        if (len(url) >= 56):
            show = render.Stack(
                children = [
                    render.Column(
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Row(
                                main_align = "space_around",
                                expanded = True,
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.WrappedText("ERROR: Your network is not compatible."),
                                        offset_start = 32,
                                        offset_end = 32,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            )

        else:
            qifi = qrcode.generate(
                url = url,
                size = "large",
                color = "#fff",
                background = "#000",
            )

            show = render.Stack(
                children = [
                    render.Column(
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Row(
                                main_align = "space_around",
                                expanded = True,
                                children = [
                                    render.Padding(
                                        pad = (0, 1, 0, 0),
                                        child = render.Image(src = qifi),
                                    ),
                                    render.Image(src = WIFI_ICON),
                                ],
                            ),
                        ],
                    ),
                ],
            )

    return render.Root(
        child = show,
    )
