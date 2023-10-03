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
DEFAULT_SHOW_ORIGIN_DESTINATION = False
DEFAULT_WRAP = False

DELIVERED_NEXT_CHECK_TTL_SECONDS = 60 * 60 * 24 * 30
DELIVERED_NEXT_CHECK_DATETIME = time.now().in_location("UTC") + time.parse_duration("%ds" % DELIVERED_NEXT_CHECK_TTL_SECONDS)

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

STATUS_COLOR_DELIVERED = "#0f0"
STATUS_COLOR_ERROR = "#f00"
STATUS_COLOR_NORMAL = DEFAULT_COLOR

STATUS_TYPE_DELIVERED = "DELIVERED"
STATUS_TYPE_ERROR = "ERROR"

STATUSES = {
    0: {"color": STATUS_COLOR_NORMAL},
    1: {"color": STATUS_COLOR_NORMAL},
    2: {"color": STATUS_COLOR_NORMAL},
    3: {"color": STATUS_COLOR_NORMAL},
    4: {"color": STATUS_COLOR_DELIVERED, "type": STATUS_TYPE_DELIVERED},
    5: {"color": STATUS_COLOR_DELIVERED, "type": STATUS_TYPE_DELIVERED},
    6: {"color": STATUS_COLOR_ERROR, "type": STATUS_TYPE_ERROR},
    7: {"color": STATUS_COLOR_ERROR, "type": STATUS_TYPE_ERROR},
    8: {"color": STATUS_COLOR_NORMAL},
    9: {"color": STATUS_COLOR_NORMAL},
}

TIDBYT_WIDTH = 64

ZIPPOPOTAMUS_API_TTL_SECONDS = 60 * 60 * 24
ZIPPOPOTAMUS_API_URL = "http://api.zippopotam.us"

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

    def find_location(location = ""):
        if location and location.lower().count("united states"):
            postal_code = re.match(r"\d{5}", location) or None

            if postal_code and len(postal_code) > 0:
                postal_code = postal_code[0][0]

                zippopotamus_response = http.get("%s/us/%s" % (ZIPPOPOTAMUS_API_URL, postal_code), ttl_seconds = ZIPPOPOTAMUS_API_TTL_SECONDS)
                check_response_headers("GET", zippopotamus_response, ZIPPOPOTAMUS_API_TTL_SECONDS)
                places = zippopotamus_response.json().get("places")

                if places:
                    place = places[0]

                    return "%s, %s" % (place.get("place name"), place.get("state"))

        return location

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

        get_status_type = lambda status: STATUSES.get(status, STATUSES[0]).get("type")

        if pkge_api_key:
            if tracking_number:
                tracking_number = re.sub("[^a-zA-Z0-9]+", "", tracking_number)
                cache_name_prefix = "package_tracker_%s_" % tracking_number
                courier_cache_name = cache_name_prefix + "courier"
                next_check_cache_name = cache_name_prefix + "next_check"
                next_check_cache_datetime = cache.get(next_check_cache_name)
                utc_datetime_now = time.now().in_location("UTC")

                get_utc_datetime = lambda datetime_string, format = "2006-01-02 15:04:05 +0000 UTC": time.parse_time(datetime_string, format = format).in_location("UTC")

                if not next_check_cache_datetime or (next_check_cache_datetime and get_utc_datetime(next_check_cache_datetime) <= utc_datetime_now):
                    pkge_response = _pkge_response(method = "POST", path = "/packages/update", parameters = "trackNumber=%s" % tracking_number, ttl_seconds = PKGE_TTL_SECONDS)

                    if validate_json(pkge_response).get("code") == 903:
                        payload = validate_json(pkge_response).get("payload")
                        payload_split = payload.lower().split("next check is possible on ") if payload else None
                        next_check_payload_datetime = payload_split[1] if len(payload_split) > 1 else None

                        if next_check_payload_datetime:
                            next_check_datetime = get_utc_datetime(next_check_payload_datetime, format = "02.01.2006 15:04")
                            next_check_ttl_seconds = abs(int(time.parse_duration(next_check_datetime - utc_datetime_now).seconds))

                            cache.set(next_check_cache_name, str(next_check_datetime), ttl_seconds = next_check_ttl_seconds)
                            print("set next check cache to %s" % humanize.plural(next_check_ttl_seconds, "second"))

                else:
                    print("current time:", utc_datetime_now)
                    print("waiting until", next_check_cache_datetime, "for next update")

                pkge_response = _pkge_response(parameters = "trackNumber=%s" % tracking_number)

                if pkge_response.status_code != 200:
                    if courier_id:
                        pkge_response = _pkge_response(method = "POST", parameters = "trackNumber=%s&courierId=%s" % (tracking_number, courier_id))
                    else:
                        pkge_response = _pkge_response(path = "/couriers/detect", parameters = "trackNumber=%s" % tracking_number)

                if pkge_response.status_code in [200, 400, 404]:
                    payload = validate_json(pkge_response).get("payload")

                pkge_courier_id = str(int(payload.get("courier_id") or COURIER_ID_UNKNOWN)) if payload and hasattr(payload, "get") else COURIER_ID_UNKNOWN

                if cache.get(courier_cache_name):
                    courier_id = cache.get(courier_cache_name)
                    if courier_id != pkge_courier_id:
                        pkge_response = _pkge_response(method = "DELETE", parameters = "trackNumber=%s" % tracking_number)

                        pkge_response = _pkge_response(method = "POST", path = "/packages/update", parameters = "trackNumber=%s" % tracking_number, ttl_seconds = 0)

                        if (pkge_response.status_code == 200):
                            payload = validate_json(pkge_response).get("payload")

                else:
                    cache.set(courier_cache_name, str(courier_id), ttl_seconds = PKGE_TTL_SECONDS)

                if payload and hasattr(payload, "update"):
                    status = payload.get("status")

                    delivered = get_status_type(status) == STATUS_TYPE_DELIVERED

                    last_status = payload.get("last_status") if payload.get("last_status") else None

                    last_status_color = STATUS_COLOR_DELIVERED if delivered or last_status and last_status.upper().count(STATUS_TYPE_DELIVERED) else DEFAULT_COLOR

                    if get_status_type(status) == STATUS_TYPE_ERROR:
                        last_status_color = STATUS_COLOR_ERROR

                    label = config.str("label", None) if config.str("label") else get_delivery_service(pkge_courier_id) if pkge_courier_id else None

                    show_origin_destination = config.bool("show_origin_destination", DEFAULT_SHOW_ORIGIN_DESTINATION)

                    if show_origin_destination:
                        origin = payload.get("origin")
                        destination = payload.get("destination")

                        if origin and destination and origin != destination:
                            label += (" (from %s to %s)" % (origin, destination))

                    if not payload.get("last_checkpoint"):
                        payload.update(last_checkpoint = payload.get("checkpoints")[0] if payload.get("checkpoints") else None)

                    if payload.get("last_checkpoint"):
                        last_checkpoint = payload.get("last_checkpoint")
                        last_checkpoint_date = last_checkpoint.get("date")
                        last_checkpoint_location = last_checkpoint.get("location")
                        last_checkpoint_status = last_checkpoint.get("status")
                        last_checkpoint_title = last_checkpoint.get("title")

                        if last_checkpoint_date:
                            last_checkpoint_date = humanize.time(time.parse_time(last_checkpoint_date))

                        delivered = delivered or get_status_type(last_checkpoint_status) == STATUS_TYPE_DELIVERED or last_checkpoint_title and last_checkpoint_title.upper().count(STATUS_TYPE_DELIVERED)

                        last_checkpoint_title_color = STATUS_COLOR_DELIVERED if delivered else DEFAULT_COLOR

                        if get_status_type(last_checkpoint_status) == STATUS_TYPE_ERROR:
                            last_checkpoint_title_color = STATUS_COLOR_ERROR

                    last_tracking_date = payload.get("last_tracking_date")

                    if last_tracking_date:
                        last_tracking_date = humanize.time(time.parse_time(last_tracking_date))

                    last_location = payload.get("last_location")

                    est_delivery_date_from = payload.get("est_delivery_date_from") or ""
                    est_delivery_date_to = payload.get("est_delivery_date_to") or ""
                    separator = ""

                    if not delivered and additional_info == "est_delivery_date" and est_delivery_date_from:
                        pattern = r"\d+ (hour|minute)s?"
                        repl = "within 1 day"
                        est_delivery_date_from = humanize.time(time.parse_time(est_delivery_date_from))
                        est_delivery_date_from = re.sub(pattern, repl, est_delivery_date_from)

                        if est_delivery_date_to:
                            separator = " to "
                            est_delivery_date_to = humanize.time(time.parse_time(est_delivery_date_to))
                            est_delivery_date_to = re.sub(pattern, repl, est_delivery_date_to)

                        if est_delivery_date_to == est_delivery_date_from:
                            separator = ""
                            est_delivery_date_to = ""

                        rendered_additional_info = render_text(
                            content = "Estimated delivery: %s%s%s" % (est_delivery_date_from, separator, est_delivery_date_to),
                        )

                    else:
                        show_delivered_icon = config.bool("show_delivered_icon", DEFAULT_SHOW_DELIVERED_ICON)

                        rendered_additional_info = render_text(content = last_checkpoint_title or last_status, color = last_checkpoint_title_color or last_status_color)

                        if delivered:
                            delivered_next_check_ttl_seconds = DELIVERED_NEXT_CHECK_TTL_SECONDS
                            cache.set(next_check_cache_name, str(DELIVERED_NEXT_CHECK_DATETIME), ttl_seconds = delivered_next_check_ttl_seconds)
                            print("set next check cache to %s" % humanize.plural(delivered_next_check_ttl_seconds, "second"))

                            if show_delivered_icon:
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
                    children.append(render_text(content = find_location(last_checkpoint_location or last_location)))
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
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "pkge_api_key",
                name = "pkge.net API Key (Required)",
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
                options = [
                    schema.Option(display = courier, value = str(value["courier_id"]))
                    for courier, value in COURIERS.items()
                ],
            ),
            schema.Text(
                id = "tracking_number",
                name = "Tracking Number (Required)",
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
                options = [
                    schema.Option(display = font, value = font)
                    for font in FONTS
                ],
            ),
            schema.Toggle(
                id = "scroll",
                name = "Scroll Long Text",
                desc = "",
                icon = "scroll",
                default = DEFAULT_SCROLL,
            ),
            schema.Toggle(
                id = "show_origin_destination",
                name = "Show Origin and Destination Countries (If Available)",
                desc = "",
                icon = "globe",
                default = DEFAULT_SHOW_ORIGIN_DESTINATION,
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
                options = [
                    schema.Option(display = value["display"], value = additional_info)
                    for additional_info, value in ADDITIONAL_INFOS.items()
                ],
            ),
        ],
    )
