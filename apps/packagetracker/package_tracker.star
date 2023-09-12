"""
Applet: Package Tracker
Summary: Track packages
Description: Track packages from Amazon/DHL/FedEx/UPS/USPS. (Free) pkge.net API key required.
Author: Kyle Bolstad
"""

load("cache.star", "cache")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_COLOR = "#ffffff"
DEFAULT_FONT = "tom-thumb"
DEFAULT_OFFSET = 0
DEFAULT_SCROLL = True
DEFAULT_WRAP = False

FONTS = {
    "tb-8": {"offset": 1},
    "5x8": {"offset": 1},
    "tom-thumb": {},
    "CG-pixel-3x5-mono": {},
}

PADDING = 1

PKGE_API_URL = "https://api.pkge.net/v1"
PKGE_DELIVERY_SERVICES_TTL_SECONDS = 60 * 60 * 24
PKGE_TTL_SECONDS = 30
PKGE_UPDATE_TTL_SECONDS = 60

STATUS_DELIVERED_COLOR = "#00ff00"
STATUS_ERROR_COLOR = "#ff0000"
STATUS_NORMAL_COLOR = DEFAULT_COLOR

STATUS_COLORS = {
    "0": STATUS_NORMAL_COLOR,
    "1": STATUS_NORMAL_COLOR,
    "2": STATUS_NORMAL_COLOR,
    "3": STATUS_NORMAL_COLOR,
    "4": STATUS_DELIVERED_COLOR,
    "5": STATUS_DELIVERED_COLOR,
    "6": STATUS_ERROR_COLOR,
    "7": STATUS_ERROR_COLOR,
    "8": STATUS_NORMAL_COLOR,
    "9": STATUS_NORMAL_COLOR,
}

TIDBYT_WIDTH = 64

def main(config):
    pkge_api_key = config.str("pkge_api_key").replace(" ", "") if config.str("pkge_api_key") else None
    font = config.str("font", DEFAULT_FONT)

    def check_response_headers(method, response, ttl_seconds):
        if response.headers.get("Tidbyt-Cache-Status") == "HIT":
            print("displaying cached data for %s" % humanize.plural(ttl_seconds, "second"))

        else:
            print("calling api")

        print(method, response.url)

    def _pkge_response(method = "GET", path = "/packages", parameters = None, ttl_seconds = PKGE_TTL_SECONDS):
        response = {}
        url = "%s%s" % (PKGE_API_URL, path)
        if parameters:
            url += "?%s" % parameters
        headers = {"X-Api-Key": "%s" % pkge_api_key}
        method = method.upper()

        http_methods = {
            "GET": http.get,
            "POST": http.post,
            "PUT": http.put,
            "DELETE": http.delete,
        }

        response = http_methods.get(method)(url, headers = headers, ttl_seconds = ttl_seconds)

        check_response_headers(method, response, ttl_seconds)

        if (response.status_code != 200):
            print("response to %s %s failed with status %d: %s" % (method, url, response.status_code, response.body()))

        return response

    def get_delivery_service(courier_id):
        pkge_response = _pkge_response(path = "/couriers", ttl_seconds = PKGE_DELIVERY_SERVICES_TTL_SECONDS)
        payload = pkge_response.json().get("payload")

        for courier in payload:
            if str(int(courier.get("id"))) == str(int(courier_id)):
                return "%s" % courier.get("name")

        return "Unknown Delivery Service"

    def render_text(content, offset = FONTS[font].get("offset", DEFAULT_OFFSET), color = DEFAULT_COLOR, scroll = config.bool("scroll", DEFAULT_SCROLL), wrap = config.bool("scroll", DEFAULT_WRAP)):
        if not content:
            return render.Text("")

        print(content)

        if scroll:
            return render.Marquee(
                child = render.Text(
                    content = content,
                    font = font,
                    offset = offset,
                    color = color,
                ),
                width = TIDBYT_WIDTH,
            )
        elif wrap:
            return render.WrappedText(
                content = content,
                font = font,
                color = color,
            )
        else:
            return render.Text(
                content = content,
                font = font,
                offset = offset,
                color = color,
            )

    def get_package_status():
        cache_name = ""
        courier_id = config.str("courier_id") if config.str("courier_id") != "None" else None
        tracking_number = config.str("tracking_number", None)

        pkge_response = {}
        payload = {}

        last_checkpoint_date = ""
        last_checkpoint_location = ""
        last_checkpoint_title = ""
        last_checkpoint_title_color = DEFAULT_COLOR

        children = []

        if pkge_api_key:
            if tracking_number:
                tracking_number = tracking_number.replace(" ", "")
                cache_name = "package_tracker_%s" % tracking_number
                pkge_update_ttl_seconds = PKGE_UPDATE_TTL_SECONDS if cache.get(cache_name) else 0

                pkge_response = _pkge_response(method = "POST", path = "/packages/update", parameters = "trackNumber=%s" % tracking_number, ttl_seconds = pkge_update_ttl_seconds)

                pkge_response = _pkge_response(parameters = "trackNumber=%s" % tracking_number)

                if (pkge_response.status_code != 200):
                    if courier_id:
                        pkge_response = _pkge_response(method = "POST", parameters = "trackNumber=%s&courierId=%s" % (tracking_number, courier_id))
                    else:
                        pkge_response = _pkge_response(path = "/couriers/detect", parameters = "trackNumber=%s" % tracking_number)

            if pkge_response:
                payload = pkge_response.json().get("payload")
                pkge_courier_id = str(int(payload.get("courier_id"))) if payload and hasattr(payload, "get") else ""

                if cache.get(cache_name):
                    if cache.get(cache_name) != pkge_courier_id:
                        pkge_response = _pkge_response(method = "DELETE", parameters = "trackNumber=%s" % tracking_number)
                        payload = pkge_response.json().get("payload")

                        pkge_response = _pkge_response(method = "POST", path = "/packages/update", parameters = "trackNumber=%s" % tracking_number, ttl_seconds = 0)
                else:
                    cache.set(cache_name, str(courier_id), PKGE_TTL_SECONDS)

                if payload and hasattr(payload, "update"):
                    payload.update(last_checkpoint = payload.get("checkpoints")[0])

                    status = str(int(payload.get("status"))) if payload.get("status") else None

                    last_checkpoint_date = payload.get("last_checkpoint").get("date")
                    last_checkpoint_location = payload.get("last_checkpoint").get("location")
                    last_checkpoint_status = payload.get("last_checkpoint").get("status")
                    last_checkpoint_title = payload.get("last_checkpoint").get("title")

                    label = config.str("label", None) if config.str("label") else get_delivery_service(courier_id) if courier_id else None

                    last_checkpoint_date = humanize.time(time.parse_time(last_checkpoint_date))

                    last_checkpoint_title_color = STATUS_DELIVERED_COLOR if STATUS_DELIVERED_COLOR in [STATUS_COLORS.get(status), STATUS_COLORS.get(last_checkpoint_status)] or last_checkpoint_title.upper().count("DELIVERED") else DEFAULT_COLOR

                    children.append(render_text(content = label))
                    children.append(render_text(content = last_checkpoint_date))
                    children.append(render_text(content = last_checkpoint_location))
                    children.append(render_text(content = last_checkpoint_title, color = last_checkpoint_title_color))
                elif type(payload) == "string":
                    children.append(
                        render_text(content = payload),
                    )
        else:
            children.append(render_text(content = "Get your (free) API key at:", scroll = False, wrap = True))
            children.append(render_text(content = "https://business.pkge.net", scroll = True))

        if children:
            return render.Root(
                render.Box(
                    child = render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        children = children,
                    ),
                    padding = PADDING,
                ),
            )
        else:
            return []

    return get_package_status()

def get_schema():
    fonts = []

    for font in FONTS:
        fonts.append(
            schema.Option(display = font, value = font),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "pkge_api_key",
                name = "pkge.net API Key",
                desc = "pkge.net API Key",
                icon = "box",
                default = "",
            ),
            schema.Dropdown(
                id = "courier_id",
                name = "Delivery Service",
                desc = "Delivery Service",
                icon = "truck",
                default = "None",
                options = [
                    schema.Option(display = "Unknown", value = "-1"),
                    schema.Option(display = "Amazon", value = "19"),
                    schema.Option(display = "Australia Post", value = "75"),
                    schema.Option(display = "Canada Post", value = "67"),
                    schema.Option(display = "China Post", value = "7"),
                    schema.Option(display = "DHL", value = "10"),
                    schema.Option(display = "FedEx", value = "9"),
                    schema.Option(display = "Japan Post", value = "42"),
                    schema.Option(display = "Korea Post", value = "53"),
                    schema.Option(display = "Poste Italiane", value = "48"),
                    schema.Option(display = "United Kingdom Royal Mail", value = "41"),
                    schema.Option(display = "UPS", value = "17"),
                    schema.Option(display = "USPS", value = "1"),
                ],
            ),
            schema.Text(
                id = "tracking_number",
                name = "Tracking Number",
                desc = "Tracking Number",
                icon = "barcode",
                default = "",
            ),
            schema.Text(
                id = "label",
                name = "Label",
                desc = "Label",
                icon = "tag",
                default = "",
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Font",
                icon = "font",
                default = DEFAULT_FONT,
                options = fonts,
            ),
            schema.Toggle(
                id = "scroll",
                name = "Scroll Long Text",
                desc = "Scroll Long Text",
                icon = "scroll",
                default = DEFAULT_SCROLL,
            ),
        ],
    )
