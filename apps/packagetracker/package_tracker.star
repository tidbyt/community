"""
Applet: Package Tracker
Summary: Track packages
Description: Track packages from Amazon/DHL/FedEx/UPS/USPS and more. (Free) pkge.net API key required.
Author: Kyle Bolstad
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CHECKMARK = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAFCAYAAACJmvbYAAAAAXNSR0IArs4c6QAAAERlW
ElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAA
AAB6ADAAQAAAABAAAABQAAAACrlow2AAAAIklEQVQIHWNgwAHknoX9xyoFl4AzoMrQ+Qw
wARiNYRw2CQBc5RBwfuwjGAAAAABJRU5ErkJggg==
""")
CHECKMARK_RIGHT_PADDING = 9

COURIER_ID_UNKNOWN = -1

COURIERS = {
    "Unknown / Not Listed": {"courier_id": COURIER_ID_UNKNOWN},
    "Amazon": {"courier_id": 19},
    "Australia Post": {"courier_id": 75},
    "Canada Post": {"courier_id": 67},
    "China Post": {"courier_id": 7},
    "DHL": {"courier_id": 10},
    "FedEx": {"courier_id": 9},
    "Japan Post": {"courier_id": 42},
    "Korea Post": {"courier_id": 53},
    "Poste Italiane": {"courier_id": 48},
    "Singapore Post": {"courier_id": 18},
    "United Kingdom Royal Mail": {"courier_id": 41},
    "UPS": {"courier_id": 17},
    "USPS": {"courier_id": 1},
}

DEFAULT_ADDITIONAL_INFO = "last_status"
DEFAULT_COLOR = "#ffffff"
DEFAULT_FONT = "tom-thumb"
DEFAULT_OFFSET = 0
DEFAULT_SCROLL = True
DEFAULT_SHOW_DELIVERED_ICON = False
DEFAULT_WRAP = False

FONTS = {
    "tb-8": {"offset": 1},
    "5x8": {"offset": 1},
    "tom-thumb": {},
    "CG-pixel-3x5-mono": {},
}

ADDITIONAL_INFOS = {
    "last_status": {"display": "Last Status"},
    "est_delivery_date": {"display": "Estimated Delivery Date (If Available)"},
}

PADDING = 1

PKGE_API_URL = "https://api.pkge.net/v1"
PKGE_DELIVERY_SERVICES_TTL_SECONDS = 60 * 60 * 24
PKGE_TTL_SECONDS = 60

STATUS_COLOR_DELIVERED = "#00ff00"
STATUS_COLOR_ERROR = "#ff0000"
STATUS_COLOR_NORMAL = DEFAULT_COLOR

STATUS_COLORS = {
    "0": STATUS_COLOR_NORMAL,
    "1": STATUS_COLOR_NORMAL,
    "2": STATUS_COLOR_NORMAL,
    "3": STATUS_COLOR_NORMAL,
    "4": STATUS_COLOR_DELIVERED,
    "5": STATUS_COLOR_DELIVERED,
    "6": STATUS_COLOR_ERROR,
    "7": STATUS_COLOR_ERROR,
    "8": STATUS_COLOR_NORMAL,
    "9": STATUS_COLOR_NORMAL,
}

TIDBYT_WIDTH = 64

def main(config):
    pkge_api_key = re.sub("\\s", "", config.str("pkge_api_key")) if config.str("pkge_api_key") else None
    font = config.str("font", DEFAULT_FONT)

    def check_response_headers(method, response, ttl_seconds):
        if response.headers.get("Tidbyt-Cache-Status") == "HIT":
            print("displaying cached data for %s" % humanize.plural(ttl_seconds, "second"))

        else:
            print("calling api")

        print(method, response.url)

    def validate_json(response):
        return json.decode(json.encode(response.json() if hasattr(response, "json") else {}), {})

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
        payload = validate_json(pkge_response).get("payload")

        for courier in payload:
            if str(int(courier.get("id"))) == str(int(courier_id)):
                return "%s" % courier.get("name")

        return "Unknown Delivery Service"

    def render_text(content = "", offset = FONTS[font].get("offset", DEFAULT_OFFSET), color = DEFAULT_COLOR, scroll = config.bool("scroll", DEFAULT_SCROLL), wrap = config.bool("scroll", DEFAULT_WRAP)):
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
        courier_id = config.str("courier_id") if config.str("courier_id") != "None" else None
        tracking_number = config.str("tracking_number", None)

        pkge_response = {}
        payload = {}

        last_checkpoint_date = ""
        last_checkpoint_location = ""
        last_checkpoint_title = ""
        last_checkpoint_title_color = DEFAULT_COLOR

        additional_info = config.str("additional_info")
        rendered_additional_info = ""

        children = []

        if pkge_api_key:
            if tracking_number:
                tracking_number = re.sub("[^a-zA-Z0-9]+", "", tracking_number)
                cache_name_prefix = "package_tracker_%s_" % tracking_number
                courier_cache = cache_name_prefix + "courier"
                next_check_cache = cache_name_prefix + "next_check"

                next_check = cache.get(next_check_cache)

                if not next_check:
                    pkge_response = _pkge_response(method = "POST", path = "/packages/update", parameters = "trackNumber=%s" % tracking_number, ttl_seconds = PKGE_TTL_SECONDS)

                    if validate_json(pkge_response).get("code") == 903:
                        payload = validate_json(pkge_response).get("payload")
                        payload_split = payload.split("Next check is possible on ")
                        payload_next_check = payload_split[1] if len(payload_split) > 1 else None

                        if payload_next_check:
                            utc_date = time.now().in_location("UTC")
                            next_check_date = time.parse_time(payload_next_check, format = "02.01.2006 15:04").in_location("UTC")
                            next_check_ttl_seconds = abs(int(time.parse_duration(next_check_date - utc_date).seconds))

                            cache.set(next_check_cache, payload_next_check, next_check_ttl_seconds)
                            print("set next check cache to %s" % humanize.plural(next_check_ttl_seconds, "second"))

                else:
                    print("current time:", time.now().in_location("UTC"))
                    print("waiting until", next_check, "UTC", "for next update")

                pkge_response = _pkge_response(parameters = "trackNumber=%s" % tracking_number)

                if pkge_response.status_code != 200:
                    if courier_id:
                        pkge_response = _pkge_response(method = "POST", parameters = "trackNumber=%s&courierId=%s" % (tracking_number, courier_id))
                    else:
                        pkge_response = _pkge_response(path = "/couriers/detect", parameters = "trackNumber=%s" % tracking_number)

                if pkge_response.status_code in [200, 400, 404]:
                    payload = validate_json(pkge_response).get("payload")

                pkge_courier_id = str(int(payload.get("courier_id", COURIER_ID_UNKNOWN))) if payload and hasattr(payload, "get") else ""

                if cache.get(courier_cache):
                    courier_id = cache.get(courier_cache)
                    if courier_id != pkge_courier_id:
                        pkge_response = _pkge_response(method = "DELETE", parameters = "trackNumber=%s" % tracking_number)

                        pkge_response = _pkge_response(method = "POST", path = "/packages/update", parameters = "trackNumber=%s" % tracking_number, ttl_seconds = 0)

                        if (pkge_response.status_code == 200):
                            payload = validate_json(pkge_response).get("payload")

                else:
                    cache.set(courier_cache, str(courier_id), PKGE_TTL_SECONDS)

                if payload and hasattr(payload, "update"):
                    status = str(int(payload.get("status"))) if payload.get("status") else None

                    last_status = payload.get("last_status") if payload.get("last_status") else None

                    last_status_color = STATUS_COLOR_DELIVERED if last_status and last_status.upper().count("DELIVERED") else DEFAULT_COLOR

                    label = config.str("label", None) if config.str("label") else get_delivery_service(pkge_courier_id) if pkge_courier_id else None

                    if not payload.get("last_checkpoint"):
                        payload.update(last_checkpoint = payload.get("checkpoints")[0] if payload.get("checkpoints") else None)

                    if payload.get("last_checkpoint"):
                        last_checkpoint_date = payload.get("last_checkpoint").get("date")
                        last_checkpoint_location = payload.get("last_checkpoint").get("location")
                        last_checkpoint_status = payload.get("last_checkpoint").get("status")
                        last_checkpoint_title = payload.get("last_checkpoint").get("title")

                        last_checkpoint_date = humanize.time(time.parse_time(last_checkpoint_date))

                        last_checkpoint_title_color = STATUS_COLOR_DELIVERED if STATUS_COLOR_DELIVERED in [STATUS_COLORS.get(status), STATUS_COLORS.get(last_checkpoint_status)] or last_checkpoint_title.upper().count("DELIVERED") else DEFAULT_COLOR

                    last_tracking_date = payload.get("last_tracking_date")
                    last_location = payload.get("last_location")

                    est_delivery_date_from = payload.get("est_delivery_date_from")
                    est_delivery_date_to = payload.get("est_delivery_date_to")

                    if est_delivery_date_from and est_delivery_date_to:
                        est_delivery_date_from = humanize.time(time.parse_time(est_delivery_date_from))
                        est_delivery_date_to = humanize.time(time.parse_time(est_delivery_date_to))

                    if additional_info == "est_delivery_date" and STATUS_COLOR_DELIVERED not in [last_checkpoint_title_color, last_status_color] and est_delivery_date_from and est_delivery_date_to:
                        rendered_additional_info = render_text(
                            content = "Estimated delivery is %s to %s" % (est_delivery_date_from, est_delivery_date_to),
                        )

                    else:
                        show_delivered_icon = config.bool("show_delivered_icon", DEFAULT_SHOW_DELIVERED_ICON)

                        rendered_additional_info = render_text(content = last_checkpoint_title or last_status, color = last_checkpoint_title_color or last_status_color)

                        if STATUS_COLOR_DELIVERED in [last_checkpoint_title_color, last_status_color] and show_delivered_icon:
                            rendered_additional_info = render.Stack(
                                children = [
                                    render.Image(src = CHECKMARK),
                                    render.Padding(
                                        pad = (CHECKMARK_RIGHT_PADDING, 0, 0, 0),
                                        child = rendered_additional_info,
                                    ),
                                ],
                            )

                    children.append(render_text(content = label))
                    children.append(render_text(content = last_checkpoint_date or last_tracking_date))
                    children.append(render_text(content = last_checkpoint_location or last_location))
                    children.append(rendered_additional_info or render_text())

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

    couriers = []

    for courier, value in COURIERS.items():
        couriers.append(
            schema.Option(display = courier, value = str(value["courier_id"])),
        )

    additional_infos = []

    for additional_info, value in ADDITIONAL_INFOS.items():
        additional_infos.append(
            schema.Option(display = value["display"], value = additional_info),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "pkge_api_key",
                name = "pkge.net API Key",
                desc = "business.pkge.net/settings/api-key",
                icon = "box",
                default = "",
            ),
            schema.Dropdown(
                id = "courier_id",
                name = "Delivery Service",
                desc = "",
                icon = "truck",
                default = "None",
                options = couriers,
            ),
            schema.Text(
                id = "tracking_number",
                name = "Tracking Number",
                desc = "",
                icon = "barcode",
                default = "",
            ),
            schema.Text(
                id = "label",
                name = "Label",
                desc = "",
                icon = "tag",
                default = "",
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "",
                icon = "font",
                default = DEFAULT_FONT,
                options = fonts,
            ),
            schema.Toggle(
                id = "scroll",
                name = "Scroll Long Text",
                desc = "",
                icon = "scroll",
                default = DEFAULT_SCROLL,
            ),
            schema.Toggle(
                id = "show_delivered_icon",
                name = "Show Delivered Icon",
                desc = "",
                icon = "check",
                default = DEFAULT_SHOW_DELIVERED_ICON,
            ),
            schema.Dropdown(
                id = "additional_info",
                name = "Additional Information",
                desc = "",
                icon = "info",
                default = DEFAULT_ADDITIONAL_INFO,
                options = additional_infos,
            ),
        ],
    )
