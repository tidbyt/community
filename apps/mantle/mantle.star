"""
Applet: Mantle
Summary: Track SaaS revenue metrics
Description: Track important revenue metrics. Manage plans and pricing. Improve customer relationships. Focus on growing your business.
Author: Mantle Rev Ops
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

MANTLE_HOST = "https://app.heymantle.com"

MANTLE_CLIENT_ID = "94093fc7-586c-4e2e-b341-0dca7017e6c5"
MANTLE_API_SECRET = secret.decrypt("AV6+xWcE7zUeeYGCniv/L9khaO9xdb9JuEbPar/edlU8qoq/mtJCSwz7QrA7ud/5/CbKqKPUTjigf+qlNItaviy3b3nh++isj2B0Csqz6E+imrZFXkm+toWVAH+f31sabNcC5uOd6w5/AQnxFZOX/s0YpJY61Cn0S1ftbuPWaZbukOIQzQtFN340Qqv+EibVSFwjsMn6DnPyDvu7KP9Jzold3tjopA==")

CACHE_TTL_SECONDS = 60 * 30  # 30 minutes

COLOR_PRIMARY = "#FFC779"
COLOR_SECONDARY = "#4F4942"
COLOR_SUBDUED_TEXT = "#6B5F50"
COLOR_WHITE = "#FFFFFF"
COLOR_BLACK = "#000000"

METRICS = [
    {
        "id": "PlatformApp.digest",
        "title": "Digest",
        "supports_compare": True,
    },
    {
        "id": "PlatformApp.activeInstalls",
        "title": "Active installs",
        "supports_compare": True,
    },
    {
        "id": "PlatformApp.netInstalls",
        "title": "Total installs",
        "supports_compare": False,
    },
    {
        "id": "PlatformApp.charges",
        "title": "Revenue",
        "supports_compare": False,
        "format": "currency",
    },
    {
        "id": "PlatformApp.mrr",
        "title": "MRR",
        "supports_compare": True,
        "format": "currency",
    },
]

DATE_RANGES = [
    {
        "id": "last_24_hours",
        "title": "Last 24 hours",
        "interval": "hour",
    },
    {
        "id": "last_7_days",
        "title": "Last 7 days",
        "interval": "day",
    },
    {
        "id": "last_30_days",
        "title": "Last 30 days",
        "interval": "day",
    },
    {
        "id": "last_90_days",
        "title": "Last 90 days",
        "interval": "day",
    },
    {
        "id": "last_12_months",
        "title": "Last 12 months",
        "interval": "month",
    },
    {
        "id": "month_to_date",
        "title": "Month to date",
        "interval": "day",
    },
    {
        "id": "year_to_date",
        "title": "Year to date",
        "interval": "month",
    },
    {
        "id": "all_time",
        "title": "All time",
        "interval": "month",
    },
]

MANTLE_LOGO = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAADzUExURf/Ie//Hef/Iev/Hef/Hef/Hef/Hef/Hef/Hef/Hef/Hef/Hef7Hef7GeP7Gef3GeP/Jes2hZG1XOmtWOcCXXtGkZW9ZO2pVObyUXP/Ke7GMWBoYFhUTFGFONfjCdnpiQBYUFJV3TLKNWB4aGCskHc6iZOKxbTkvIxkXFhoXFpd4TR0aGCwlHiAcGYRpRJ18Ty0mHhsYF1pJMlRELzMqITwxJUI3KGdTOBcWFWhUOKiFVB4bGJJ0SoJnQxYVFWRRNum3cEs9LN6ua4FmQxIRE5Z3TMieYnJbPLSOWdSmZsygY8KZX3NcPbaPWv/Iev3FeP///3xR0csAAAALdFJOUwAABUem4voXke6vMi/hnwAAAAFiS0dEUONuTLwAAAAHdElNRQfnCBIRNyS8FdjtAAAAvElEQVQY02WPRxaCQBBEZ8jQKGMWMWAEA+accw73v40zLFxI7eq/111VCGHM8YIoSaLAcxgj6mVFBV+qIlOCZQ1+0mSMOAX0UJi5sKGDwiFeJZFoLE5IIplKE5VHApgZK5vLQ8G2iyYISASzVLYq1Zrj1hsmiEiioNny2h2vy4Dkg15/MByNJ1MfsBNrNl+4y5Xtn7Cn68125+wPxxN7SmPPl6t+u+uP54vF0mIGECAE3vBhxQLVA+P+538B3McUE/Dc/ekAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMDgtMThUMTc6NTU6MzYrMDA6MDBSrTDKAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTA4LTE4VDE3OjU1OjM2KzAwOjAwI/CIdgAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyMy0wOC0xOFQxNzo1NTozNiswMDowMHTlqakAAAAASUVORK5CYII="

def pad_left(in_str, width, character = "0"):
    out_str = in_str
    if len(in_str) < width:
        delta = width - len(in_str)
        out_str = (character * delta) + in_str
    return out_str

def pad_right(in_str, width, character = "0"):
    out_str = in_str
    if len(in_str) < width:
        delta = width - len(in_str)
        out_str = in_str + (character * delta)
    return out_str

def power(base, exponent):
    result = 1
    for _ in range(exponent):
        result *= base
    return result

def abs(value):
    if value < 0:
        return -value
    return value

def round(value, decimal_places = 0):
    multiplier = power(10, decimal_places)
    return int(value * multiplier + 0.5) / multiplier

def format_float(value, decimal_places):
    multiplier = power(10, decimal_places)
    rounded_value = int(round(value * multiplier))
    whole_part = str(rounded_value // multiplier)
    if decimal_places == 0:
        return whole_part
    else:
        decimal_part = pad_right(str(rounded_value % multiplier), decimal_places, "0")
        return whole_part + "." + decimal_part

def format_value(value):
    return format_float(value, 0)

def add_days(date, days):
    unix_time = date.unix
    seconds_in_days = days * 24 * 60 * 60
    new_unix_time = unix_time + seconds_in_days
    new_date = time.from_timestamp(new_unix_time)
    return new_date

def get_start_of_month(date):
    return time.time(year = date.year, month = date.month, day = 1)

def get_start_of_year(date):
    return time.time(year = date.year, month = 1, day = 1)

def format_date(date):
    return "{}-{}-{}".format(date.year, pad_left(str(date.month), 2), pad_left(str(date.day), 2))

def join_array(array, separator):
    if not array:
        return ""
    array = [str(item) for item in array]
    result = array[0]
    for item in array[1:]:
        result += separator + item
    return result

def api_request(access_token, path, params = {}):
    headers = {
        "Authorization": "Bearer {}".format(access_token),
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    rep = http.get(
        "{}/api/core/v1{}".format(MANTLE_HOST, path),
        params = params,
        headers = headers,
        ttl_seconds = CACHE_TTL_SECONDS,
    )
    if rep.status_code != 200:
        print("Mantle API request failed with status {}".format(rep.status_code))
        return None
    return rep.json()

def render_metric(config, metric, access_token, app_id, current_start_date, compare_previous_period):
    title = metric["title"]
    date_range = [d for d in DATE_RANGES if d["id"] == config.str("date_ranges")][0]

    includes = ["includeTotal"]
    if config.bool("include_annual_plans", False):
        includes.append("includeAnnual")
    if config.bool("include_usage_charges", False):
        includes.append("includeUsage")
    if config.bool("include_active_trials", False):
        includes.append("includeTrials")
    includes = join_array(includes, ",")

    metric_response = api_request(access_token, "/metrics", params = {
        "appId": app_id,
        "metric": metric["id"],
        "interval": date_range["interval"],
        "dateFormat": "YYYY-MM-DD",
        "startDate": format_date(current_start_date) if current_start_date else "",
        "endDate": format_date(add_days(time.now(), 1)),
        "includes": includes,
    })
    current_metric = metric_response[0]
    print("current_metric")
    print(current_metric)
    period_length = len(current_metric["data"])
    if date_range["id"] == "last_24_hours":
        period_length = 24
    elif date_range["id"] == "last_7_days":
        period_length = 7
    elif date_range["id"] == "last_30_days":
        period_length = 30
    elif date_range["id"] == "last_90_days":
        period_length = 90
    elif date_range["id"] == "last_12_months":
        period_length = 365 + 30
    elif date_range["id"] == "month_to_date":
        period_length = (time.now().day - 1)
    elif date_range["id"] == "year_to_date":
        period_length = (time.now().day - 1)
    elif date_range["id"] == "all_time":
        period_length = len(current_metric["data"])
    print("period_length")
    print(period_length)
    current_period_data = [(i, d["value"]) for i, d in enumerate(current_metric["data"][-period_length:])]
    # print(current_period_data)

    metric_options = current_metric.get("options")
    app = metric_options.get("app") if metric_options else None

    app_text = app["displayName"] if app else "All apps"
    date_range_text = date_range["title"]
    if len(current_metric["data"]) > 0:
        if (current_metric.get("formattedTotal")):
            value = current_metric.get("formattedTotal", current_metric["data"][-1]["formattedValue"])
        else:
            value = format_value(current_metric.get("total", current_metric["data"][-1]["value"]))

        percent_change = (current_period_data[-1][1] - current_period_data[0][1]) / current_period_data[0][1]
        percent_change_sign = "+" if percent_change > 0 else ""
        percent_change_str = "{}{}%".format(percent_change_sign, int(percent_change * 100))

        max_value = max([d[1] for d in current_period_data])
        min_value = max(min([d[1] for d in current_period_data]), 0)
        max_x = len(current_period_data) - 1
    else:
        # TODO: empty state
        value = "0"
        max_value = 1
        min_value = 0
        max_x = 1
        percent_change_str = None

    metric_label = render.Text(
        font = "tom-thumb",
        content = title.upper(),
        color = COLOR_WHITE,
    )

    app_label = render.Text(
        font = "tom-thumb",
        content = app_text.upper(),
        color = COLOR_WHITE,
    )

    date_range_label = render.Text(
        font = "tom-thumb",
        content = date_range_text.upper(),
        color = COLOR_WHITE,
    )

    divider_label = render.Text(
        font = "tom-thumb",
        content = " • ",
        color = COLOR_SUBDUED_TEXT,
    )

    if app_text == "All apps":
        marquee_label = [
            metric_label,
            divider_label,
            date_range_label,
            divider_label,
        ]
    else:
        marquee_label = [
            app_label,
            divider_label,
            metric_label,
            divider_label,
            date_range_label,
            divider_label,
        ]

    # This is a hack to get an "infinite scroll" effect on marquees
    marquee_content = []
    for _ in range(10):
        marquee_content += marquee_label

    metric_content = [
        render.Text(
            font = "tom-thumb",
            content = value,
            color = COLOR_PRIMARY,
        ),
    ]

    if compare_previous_period and percent_change_str != None:
        metric_content.append(
            render.Text(
                font = "tom-thumb",
                content = percent_change_str,
                color = COLOR_SUBDUED_TEXT,
            ),
        )

    return render.Root(
        render.Column(
            main_align = "space_between",
            children = [
                render.Box(
                    padding = 1,
                    height = 7,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Marquee(
                                width = 64,
                                offset_start = 0,
                                offset_end = 64,
                                child = render.Row(
                                    children = marquee_content,
                                ),
                            ),
                        ],
                    ),
                ),
                render.Box(
                    padding = 1,
                    height = 7,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = metric_content,
                    ),
                ),
                render.Stack(
                    children = [
                        render.Plot(
                            data = current_period_data,
                            width = 64,
                            height = 18,
                            color = COLOR_PRIMARY,
                            fill_color = COLOR_PRIMARY,
                            x_lim = (0, max_x),
                            y_lim = (min_value, max_value + (max_value - min_value) * 0),
                            fill = True,
                        ),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Plot(
                                data = current_period_data,
                                width = 64,
                                height = 18,
                                color = COLOR_BLACK,
                                fill_color = COLOR_BLACK,
                                x_lim = (0, max_x),
                                y_lim = (min_value, max_value + (max_value - min_value) * 0),
                                fill = True,
                            ),
                        ),
                        render.Padding(
                            pad = (0, 3, 0, 0),
                            child = render.Plot(
                                data = current_period_data,
                                width = 64,
                                height = 18,
                                color = COLOR_SECONDARY,
                                fill_color = COLOR_SECONDARY,
                                x_lim = (0, max_x),
                                y_lim = (min_value, max_value + (max_value - min_value) * 0),
                                fill = True,
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def render_digest(config, access_token, app_id, current_start_date, compare_previous_period):
    date_range = [d for d in DATE_RANGES if d["id"] == config.str("date_ranges")][0]
    includes = "includeTotal,includeAnnual,includeUsage,includeTrials"

    active_installs_response = api_request(access_token, "/metrics", params = {
        "appId": app_id,
        "metric": "PlatformApp.activeInstalls",
        "interval": date_range["interval"],
        "dateFormat": "YYYY-MM-DD",
        "startDate": format_date(current_start_date) if current_start_date else "",
        "endDate": format_date(add_days(time.now(), 1)),
        "includes": includes,
    })
    active_installs_metric = active_installs_response[0]
    print("[digest] active_installs_metric")
    print(active_installs_metric)
    active_installs_data = [(i, d["value"]) for i, d in enumerate(active_installs_metric["data"])]

    mrr_response = api_request(access_token, "/metrics", params = {
        "appId": app_id,
        "metric": "PlatformApp.mrr",
        "interval": date_range["interval"],
        "dateFormat": "YYYY-MM-DD",
        "startDate": format_date(current_start_date) if current_start_date else "",
        "endDate": format_date(add_days(time.now(), 1)),
        "includes": includes,
    })
    mrr_metric = mrr_response[0]
    print("[digest] mrr_metric")
    print(mrr_metric)
    mrr_data = [(i, d["value"]) for i, d in enumerate(mrr_metric["data"])]

    revenue_response = api_request(access_token, "/metrics", params = {
        "appId": app_id,
        "metric": "PlatformApp.charges",
        "interval": date_range["interval"],
        "dateFormat": "YYYY-MM-DD",
        "startDate": format_date(current_start_date) if current_start_date else "",
        "endDate": format_date(add_days(time.now(), 1)),
        "includes": includes,
    })
    revenue_metric = revenue_response[0]
    print("[digest] revenue_metric")
    print(revenue_metric)
    revenue_data = [(i, d["value"]) for i, d in enumerate(revenue_metric["data"])]

    active_installs_change = active_installs_data[-1][1] - active_installs_data[0][1]
    active_installs_change_sign = "+" if active_installs_change > 0 else "-"
    if active_installs_change == 0:
        active_installs_change_sign = ""
    active_installs_change_str = "{}{}".format(active_installs_change_sign, format_value(abs(active_installs_change)))

    mrr_change = mrr_data[-1][1] - mrr_data[0][1]
    mrr_change_sign = "+$" if mrr_change > 0 else "-$"
    if mrr_change == 0:
        mrr_change_sign = "$"
    mrr_change_str = "{}{}".format(mrr_change_sign, format_value(abs(mrr_change)))

    revenue_change = revenue_data[-1][1] - revenue_data[0][1]
    revenue_change_sign = "+$" if revenue_change > 0 else "-$"
    if revenue_change == 0:
        revenue_change_sign = "$"
    revenue_change_str = "{}{}".format(revenue_change_sign, format_value(abs(revenue_change)))

    metric_options = active_installs_metric.get("options")
    app = metric_options.get("app") if metric_options else None
    app_text = app["displayName"] if app else "All apps"
    date_range_text = date_range["title"]

    if len(active_installs_metric["data"]) > 0:
        if (active_installs_metric.get("formattedTotal")):
            active_installs_value = active_installs_metric.get("formattedTotal", active_installs_metric["data"][-1]["formattedValue"])
        else:
            active_installs_value = format_value(active_installs_metric.get("total", active_installs_metric["data"][-1]["value"]))
    else:
        active_installs_value = "0"
    if compare_previous_period:
        active_installs_text = "{} users".format(active_installs_change_str)
    else:
        active_installs_text = "{} users".format(active_installs_value)

    if len(mrr_metric["data"]) > 0:
        if (mrr_metric.get("formattedTotal")):
            mrr_value = mrr_metric.get("formattedTotal", mrr_metric["data"][-1]["formattedValue"])
        else:
            mrr_value = format_value(mrr_metric.get("total", mrr_metric["data"][-1]["value"]))
    else:
        mrr_value = "0"
    if compare_previous_period:
        mrr_text = "{} MRR".format(mrr_change_str)
    else:
        mrr_text = "{} MRR".format(mrr_value)

    if len(revenue_metric["data"]) > 0:
        if (revenue_metric.get("formattedTotal")):
            revenue_value = revenue_metric.get("formattedTotal", revenue_metric["data"][-1]["formattedValue"])
        else:
            revenue_value = format_value(revenue_metric.get("total", revenue_metric["data"][-1]["value"]))
    else:
        revenue_value = "0"
    if compare_previous_period:
        revenue_text = "{} rev".format(revenue_change_str)
    else:
        revenue_text = "{} rev".format(revenue_value)

    app_label = render.Text(
        font = "tom-thumb",
        content = app_text.upper(),
        color = COLOR_WHITE,
    )

    date_range_label = render.Text(
        font = "tom-thumb",
        content = date_range_text.upper(),
        color = COLOR_WHITE,
    )

    divider_label = render.Text(
        font = "tom-thumb",
        content = " • ",
        color = COLOR_SUBDUED_TEXT,
    )

    if app_text == "All apps":
        marquee_label = [
            date_range_label,
            divider_label,
        ]
    else:
        marquee_label = [
            app_label,
            divider_label,
            date_range_label,
            divider_label,
        ]

    # This is a hack to get an "infinite scroll" effect on marquees
    marquee_content = []
    for _ in range(10):
        marquee_content += marquee_label

    return render.Root(
        render.Column(
            main_align = "space_between",
            children = [
                render.Box(
                    padding = 1,
                    height = 7,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Marquee(
                                width = 64,
                                offset_start = 0,
                                offset_end = 64,
                                child = render.Row(
                                    children = marquee_content,
                                ),
                            ),
                        ],
                    ),
                ),
                render.Row(
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 18,
                            padding = 1,
                            child = render.Image(
                                src = base64.decode(MANTLE_LOGO),
                                width = 16,
                                height = 16,
                            ),
                        ),
                        render.Column(
                            children = [
                                render.Box(
                                    padding = 1,
                                    height = 7,
                                    child = render.Row(
                                        main_align = "space_between",
                                        children = [
                                            render.Text(
                                                font = "CG-pixel-3x5-mono",
                                                content = active_installs_text,
                                                color = COLOR_PRIMARY,
                                            ),
                                        ],
                                    ),
                                ),
                                render.Box(
                                    padding = 1,
                                    height = 7,
                                    child = render.Row(
                                        main_align = "space_between",
                                        children = [
                                            render.Text(
                                                font = "CG-pixel-3x5-mono",
                                                content = mrr_text,
                                                color = COLOR_PRIMARY,
                                            ),
                                        ],
                                    ),
                                ),
                                render.Box(
                                    padding = 1,
                                    height = 7,
                                    child = render.Row(
                                        main_align = "space_between",
                                        children = [
                                            render.Text(
                                                font = "CG-pixel-3x5-mono",
                                                content = revenue_text,
                                                color = COLOR_PRIMARY,
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def main(config):
    access_token = config.str("auth")
    app_id = config.str("app")
    metric_id = config.str("metric")
    compare_previous_period = config.bool("compare_previous_period", True)
    if not access_token or not app_id:
        return render.Root(
            child = render.Column(
                children = [
                    render.Box(
                        height = 2,
                        width = 1,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        children = [
                            render.Image(
                                src = base64.decode(MANTLE_LOGO),
                                width = 16,
                                height = 16,
                            ),
                        ],
                    ),
                    render.Box(
                        height = 5,
                        width = 1,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        children = [
                            render.Text(
                                content = "Connect account",
                                font = "tom-thumb",
                            ),
                        ],
                    ),
                ],
            ),
        )

    metric = [m for m in METRICS if m["id"] == metric_id][0]

    date_range = [d for d in DATE_RANGES if d["id"] == config.str("date_ranges")][0]

    current_start_date = add_days(time.now(), -30)
    if date_range["id"] == "last_24_hours":
        current_start_date = add_days(time.now(), -1)
    elif date_range["id"] == "last_7_days":
        current_start_date = add_days(time.now(), -7)
    elif date_range["id"] == "last_30_days":
        current_start_date = add_days(time.now(), -30)
    elif date_range["id"] == "last_90_days":
        current_start_date = add_days(time.now(), -90)
    elif date_range["id"] == "last_12_months":
        current_start_date = add_days(time.now(), -365 + 30)
    elif date_range["id"] == "month_to_date":
        current_start_date = get_start_of_month(time.now())
    elif date_range["id"] == "year_to_date":
        current_start_date = get_start_of_year(time.now())
    elif date_range["id"] == "all_time":
        current_start_date = None

    if metric_id == "PlatformApp.digest":
        result = render_digest(config, access_token, app_id, current_start_date, compare_previous_period)
    else:
        result = render_metric(config, metric, access_token, app_id, current_start_date, compare_previous_period)
    return result

def oauth_handler(params):
    params = json.decode(params)
    url = "{}/api/oauth/token".format(
        MANTLE_HOST,
    )
    request_params = {
        "client_id": params["client_id"],
        "client_secret": MANTLE_API_SECRET,
        "grant_type": "authorization_code",
        "code": params["code"],
        "redirect_uri": params["redirect_uri"],
    }
    rep = http.post(
        url,
        form_body = request_params,
        headers = {"Content-Type": "application/x-www-form-urlencoded"},
    )
    if rep.status_code != 200:
        print("Mantle OAuth token request failed with status {}".format(rep.status_code))
        return None
    response = rep.json()
    access_token = response["accessToken"]
    return access_token

def generate_app_toggles(access_token):
    if not access_token:
        return []
    apps_response = api_request(access_token, "/apps")
    apps = []
    for app in apps_response["apps"]:
        if app.get("development") != True:
            apps.append(app)

    # TODO: if there's only one production app, we shouldn't show an apps dropdown in the schema
    options = [
        schema.Option(
            display = app["name"],
            value = app["id"],
        )
        for app in apps
    ]

    options.insert(
        0,
        schema.Option(
            display = "All apps",
            value = "all_apps",
        ),
    )

    return [
        schema.Dropdown(
            id = "app",
            name = "App",
            desc = "Choose an app to show metrics from",
            icon = "puzzlePiece",
            default = "all_apps",
            options = options,
        ),
    ]

def get_metric_options(metric_id):
    if not metric_id:
        return []

    metrics = [m for m in METRICS if m["id"] == metric_id]
    if len(metrics) == 0:
        return []

    metric = metrics[0]

    print("get_metric_options metric: {}".format(metric))

    options = []

    if metric["supports_compare"]:
        options.append(
            schema.Toggle(
                id = "compare_previous_period",
                name = "Compare to previous date range",
                desc = "e.g. The previous 30 days, 90 days",
                icon = "compress",
                default = True,
            ),
        )

    if metric["id"] == "PlatformApp.mrr":
        options.append(
            schema.Toggle(
                id = "include_annual_plans",
                name = "Include annual plans",
                desc = "Include revenue from annual plans in the MRR metric",
                icon = "compress",
                default = True,
            ),
        )
        options.append(
            schema.Toggle(
                id = "include_usage_charges",
                name = "Include usage charges",
                desc = "Include revenue from usage charges charges in the MRR metric",
                icon = "compress",
                default = True,
            ),
        )
        options.append(
            schema.Toggle(
                id = "include_active_trials",
                name = "Include active trials",
                desc = "Include revenue from active trials in the MRR metric",
                icon = "compress",
                default = True,
            ),
        )

    return options

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Mantle Account",
                desc = "Connect your Mantle account.",
                icon = "usersGear",
                handler = oauth_handler,
                client_id = MANTLE_CLIENT_ID,
                authorization_endpoint = "{}/oauth/authorize".format(MANTLE_HOST),
                scopes = [
                    "read:apps",
                    "read:metrics",
                ],
            ),
            schema.Generated(
                id = "generated",
                source = "auth",
                handler = generate_app_toggles,
            ),
            schema.Dropdown(
                id = "metric",
                name = "Metric",
                desc = "Choose a metric to display",
                icon = "chartSimple",
                default = "PlatformApp.digest",
                options = [
                    schema.Option(
                        display = metric["title"],
                        value = metric["id"],
                    )
                    for metric in METRICS
                ],
            ),
            schema.Dropdown(
                id = "date_ranges",
                name = "Date range",
                desc = "Select a timeframe to show metrics from",
                icon = "calendarDays",
                default = "last_30_days",
                options = [
                    schema.Option(
                        display = date_range["title"],
                        value = date_range["id"],
                    )
                    for date_range in DATE_RANGES
                ],
            ),
            schema.Generated(
                id = "generated",
                source = "metric",
                handler = get_metric_options,
            ),
        ],
    )
