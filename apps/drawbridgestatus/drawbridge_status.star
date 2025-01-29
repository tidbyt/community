"""
Applet: Drawbridge Status
Summary: Display Drawbridge Status
Description: Shows whether a drawbridge is open or not, and when it is expected to rise again. For now, only the Saint-Louis-de-Gonzague bridge (QC) is supported.
Author: sumara523
"""

load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

BRIDGE_API_URL = "https://www.seaway-greatlakes.com/bridgestatus/detailsmai2?key=BridgeSBS"
BOAT_ICON_BASE64_STR = "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAhGVYSWZNTQAqAAAACAAFARIAAwAAAAEAAQAAARoABQAAAAEAAABKARsABQAAAAEAAABSASgAAwAAAAEAAgAAh2kABAAAAAEAAABaAAAAAAAAAEgAAAABAAAASAAAAAEAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAADgNpdeAAAACXBIWXMAAAsTAAALEwEAmpwYAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgoZXuEHAAAB6klEQVQoFWVQTWgTQRR+b3Z21zSbnzalpWIDhaiXKtocPEqqnpSKF/EknvRQDwpe2osLQo+C1EuOohcbRJBWhSILHsSKikilUGlCDWyXpInZpPnbv3Fmi1DxzWG+me9n3jyAA2UYBhXHawDjjDFygPofGgYLxUtfKpk7t2a/ccWEUOn6v8YwRedpuRx6T40fGbfffq2NjqeWPm4v7hswELzAokJwfx8DQ5rXYskjLau8k86kL64WnSeC0hF4hwwFJgZjFBGDF5/MucnssWlgQVNRIxG71nFHxuTry+uNPACyQqEQhtMcordS8i7LkqT/tsF2Cem1KA34LllV6NCodvPBq7WvV2fO5A3doOEzb+8+zMjP343smiu0dOPeFXV363z07EzTLpeL3Y2N4qj5qzqd+Pzm6If+VmiwZs/NDSWHF/acoCmB58uSPOB6nT0EwkBSok6719p+vHwhC/A97OvlqUtrHUepxFUtzmKHByN9T40HkRQm0sOKklAqx6fms4/yDfFpvL24eoKlT75PxYai1HeohwhqwPgckPUR+HzA6yqHelA31XJp/TR9tlkjcm0nVh3wEALfB4k7mMjiJRr2GQwSotntujNWb1CqWeZmktCpia7FaZcvAFmIef3FLr9xe3XWsKyffwC2k80ucjBLQQAAAABJRU5ErkJggg=="
LANGUAGE_LOCALES = {
    "not_200_error": {
        "fr": "Tenté de contacter l'API ayant l'info du pont, mais reçu un statut %d.",
        "en": "Tried to fetch the API for bridge information, but got status %d.",
    },
    "no_bridge_item_found_error": {
        "fr": "Aucune information sur le pont reçue dans la réponse.",
        "en": "No bridge item found when parsing the bridge information response",
    },
    "accept_language_header": {
        "fr": "fr-CA, fr-FR",
        "en": "en-CA, en-US",
    },
}

# Values should match the keys in the locales map above.
LANGUAGE_OPTIONS = [
    schema.Option(display = "Français", value = "fr"),
    schema.Option(display = "English", value = "en"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "lang",
                name = "Language",
                desc = "The language to display the information",
                icon = "language",
                default = LANGUAGE_OPTIONS[0].value,
                options = LANGUAGE_OPTIONS,
            ),
        ],
    )

def fetch_bridge_status(config):
    lang = config.get("lang", LANGUAGE_OPTIONS[0].value)
    accept_language_header = LANGUAGE_LOCALES["accept_language_header"][lang]
    response = http.get(
        BRIDGE_API_URL,
        headers = {"Accept-Language": accept_language_header},
        # Ensure that we issue at most one HTTP request every 10s.
        ttl_seconds = 10,
    )
    if response.status_code != 200:
        return None, LANGUAGE_LOCALES["not_200_error"][lang] % response.status_code

    doc = html(response.body())

    # Find the first bridge-item.
    first_bridge_item = doc.find("div.bridge-item").eq(1)
    if not first_bridge_item:
        return None, LANGUAGE_LOCALES["no_bridge_item_found_error"][lang]

    background_color = None

    # Extract all h1 tags with the class 'status-title' within the first bridge-item.
    status_titles_elems = first_bridge_item.find("h1.status-title")
    status_titles_len = status_titles_elems.len()
    status_titles = [status_titles_elems.eq(i).text().strip() for i in range(status_titles_len)]

    status_elems = first_bridge_item.find("p.item-data")
    status = status_elems.first().text().strip() if status_elems.len() > 0 else ""

    banner_elems = first_bridge_item.find("div.item-title-banner")
    if banner_elems.len() > 0 and banner_elems.attr("style"):
        # Split the style attribute to find the background-color value.
        style_attrs = {}
        for attr in banner_elems.attr("style").split(";"):
            style_attr_key, style_attr_val = attr.split(":")
            style_attrs[style_attr_key.strip()] = style_attr_val.strip()
        background_color = style_attrs["background-color"]

    return {
        "status_titles": status_titles,
        "status": status,
        "background_color": background_color,
    }, None

def render_view(bridge_status):
    # Decode the boat icon image from Base64.
    imgBase64 = base64.decode(BOAT_ICON_BASE64_STR)

    # Create banner_row list, with the boat icon image to start with.
    banner_row = [render.Image(src = imgBase64)]

    # Add availability status to the status column.
    status_column = [render.Text(content = bridge_status["status_titles"][0], font = "tom-thumb", color = bridge_status["background_color"])]

    # Add the optional 2nd status title to the status column.
    if len(bridge_status["status_titles"]) > 1:
        status_column.append(render.Marquee(width = 50, child = render.Text(content = bridge_status["status_titles"][1], font = "tom-thumb", color = bridge_status["background_color"])))

    # Append the status column to the banner_row.
    banner_row.append(render.Column(children = status_column))

    # Create the canvas list, starting with the banner_row.
    canvas = [render.Row(children = banner_row, expanded = True, main_align = "space_evenly")]

    # Add the anticipated status to the canvas.
    canvas.append(render.WrappedText(content = bridge_status["status"], linespacing = 0, font = "tom-thumb", align = "center"))

    # Render the composed canvas.
    return render.Root(
        child = render.Column(
            children = canvas,
            cross_align = "center",
            main_align = "space_evenly",
            expanded = True,
        ),
    )

def render_error(err):
    # Decode the boat icon image from Base64.
    imgBase64 = base64.decode(BOAT_ICON_BASE64_STR)

    # Create banner_row list, with the boat icon image to start with.
    banner_row = [render.Image(src = imgBase64)]

    status_column = [render.Marquee(width = 64, offset_start = 64, offset_end = 0, child = render.Text(content = err, font = "tom-thumb", color = "#F00"))]
    banner_row.append(render.Column(children = status_column))

    # Render the error.
    return render.Root(
        child = render.Column(
            children = banner_row,
            cross_align = "center",
            main_align = "space_evenly",
            expanded = True,
        ),
    )

def main(config):
    bridge_status, err = fetch_bridge_status(config)
    if err:
        return render_error(err)

    return render_view(bridge_status)
