"""
Applet: WooCommerce Stats
Summary: WooCommerce store stats
Description: Display the number of orders and sales from your WooCommerce store.
Author: Jeremy Launder
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

APP_ID = "woocommercestats"

# DEFAULT CONFIG OPTIONS
DEFAULT_CACHE_TTL = 900  # 15 minutes
DEFAULT_TIMEZONE = "America/New_York"
DEFUALT_REPORTING_PERIOD = "last_7_days"

# COLORS
COLOR_WC_PURPLE_50 = "#7F54B3"
COLOR_WC_PURPLE_80 = "#3C2861"
COLOR_ERROR = "#FF0033"
COLOR_WARNING = "#F0D504"
COLOR_BLACK = "#000"
COLOR_WHITE = "#FFF"
COLOR_LIGHT_GRAY = "#EEEAE8"
COLOR_GREEN = "#00FF00"

# FONTS
FONT_TB8 = "tb-8"  # Default font, 5x8
FONT_6X13 = "6x13"
FONT_10X20 = "10x20"
FONT_TOM_THUMB = "tom-thumb"  # Small 4x6 font
HEADING_FONT = FONT_TB8
SUBHEADING_FONT = FONT_TB8
DATA_FONT = FONT_6X13

# IMAGES
IMAGE_WOO_SQUARE_16X16 = """
UklGRpACAABXRUJQVlA4WAoAAAAgAAAADwAADwAASUNDUMgBAAAAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADZWUDggogAAAJACAJ0BKhAAEAABQCYlsAJ0OIAHKTdMngk0wLO8AP6JPwhphL110tdOSSPX2dkHK3oZdnfhjuMyMm+tNb+KWVLhTvEJYvzP3EmPguH2GojPUmvp3j86L5mRdNPL+sSkr6v6gYOnT/5g2xswwSpMkjSFNWjg/IFMe4utEr0rT/4Jtkcq/zv/GSrUtz5n7Ta9AE88CbxA3B6v3eupxI4bz+AAAA==
"""

def main(config):
    """Main function that renders the Tidbyt display

    Args:
        config: object
    Returns:
        Pixlet Root element
    """

    # Get the cache config value.
    cache_ttl = config.get("cacheTtl") or DEFAULT_CACHE_TTL

    # API key config options
    consumer_key = config.str("consumerKey") or None
    consumer_secret_key = config.str("consumerSecretKey") or None

    # Color options - TODO make them settable by user schema
    heading_color = config.str("headerColor") or COLOR_WC_PURPLE_50
    subheading_color = config.str("subheadingColor") or COLOR_WC_PURPLE_50
    data_color = config.str("dataColor") or COLOR_GREEN
    header_bgnd_color = config.str("headerBgndColor") or COLOR_BLACK
    data_bgnd_color = config.str("dataBgndColor") or COLOR_BLACK

    # Logo - TODO make it settable by user schema
    logo = config.str("logo") or IMAGE_WOO_SQUARE_16X16

    # Reporting related config options
    location = config.get("shopLocation")
    reporting_period = config.get("reportingPeriod") or DEFUALT_REPORTING_PERIOD

    # Get shop url config setting
    shop_url = config.str("shopUrl") or None

    # Demo mode flag set true when url and keys are not set (for Tidbyt App Store demo)
    if (shop_url == None) and (consumer_key == None) and (consumer_secret_key == None):
        demo_mode = True
    else:
        demo_mode = False

    # Shop URL not set but one or more API keys is set so show error
    if (demo_mode == False) and (shop_url == None):
        return error_view("Shop URL not provided.")

    # Shop URL set but one or more API keys is not set so show error
    if (demo_mode == False) and ((consumer_key == None) or (consumer_secret_key == None)):
        return error_view("API keys not provided.")

    # Set data for demo mode for Tidbyt App Store or get data from WooCommerce API
    if demo_mode:
        subheading = "demo"
        num_orders = 123
        sales = 123456
    else:
        # Get today's date based on shop location for the reporting end date
        location = json.decode(location) if location else {}
        timezone = location.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))
        end_date = time.now().in_location(timezone)
        end_date_str = end_date.format("2006-01-02")  # YYYY-MM-DD

        # Get the start date based on the reporting period
        start_date = get_reporting_period_start_date(reporting_period, end_date, timezone)
        if start_date == None:
            return error_view("Invalid reporting period.")

        start_date_str = start_date.format("2006-01-02")  # YYYY-MM-DD

        subheading = get_reporting_period_subheading(reporting_period)
        if subheading == None:
            return error_view("Invalid reporting period.")

        url = shop_url.strip("/ ") + "/wp-json/wc/v3/reports/sales"
        params = {"date_min": start_date_str, "date_max": end_date_str}

        resp = http.get(
            url,
            params = params,
            auth = (consumer_key, consumer_secret_key),
            ttl_seconds = int(cache_ttl),
        )

        if resp.status_code != 200:
            return error_view("Error connecting to your site.")

        # Returned as a list with one item
        report = resp.json()
        if report == []:
            return error_view("No data from site.")

        report = report[0]

        num_orders = int(report.get("total_orders"))
        if (num_orders < 0) or (num_orders == None):
            return error_view("Error retrieving orders.")

        # Convert float to int and round up
        sales = math.ceil(float(report.get("total_sales")))
        if (sales < 0) or (sales == None):
            return error_view("Error retrieving sales.")

    # ~20fps rate - 300 frame duration total resulted in about 15 seconds of total time
    return render.Root(
        child = render.Sequence(
            children = [
                animation.Transformation(
                    duration = 150,
                    delay = 0,
                    keyframes = keyframes_slide_left_to_right(),
                    child = render.Column(
                        expanded = True,
                        main_align = "start",
                        children = [
                            render_header_row(logo, "# Orders", heading_color, subheading, subheading_color, header_bgnd_color),
                            render_data_row(humanize.comma(num_orders), data_color, data_bgnd_color),
                        ],
                    ),
                ),
                animation.Transformation(
                    duration = 150,
                    delay = 0,
                    keyframes = keyframes_slide_left_to_right(),
                    child = render.Column(
                        expanded = True,
                        main_align = "start",
                        children = [
                            render_header_row(logo, "Sales", heading_color, subheading, subheading_color, header_bgnd_color),
                            render_data_row("$" + str(humanize.comma(sales)), data_color, data_bgnd_color),
                        ],
                    ),
                ),
            ],
        ),
    )

def error_view(message):
    """Output an error message

    Args:
        message: The error message to display
    Returns:
        Pixlet Root element
    """

    heading_color = COLOR_ERROR
    subheading_color = COLOR_ERROR
    data_color = COLOR_ERROR
    header_bgnd_color = COLOR_BLACK
    data_bgnd_color = COLOR_BLACK
    logo = IMAGE_WOO_SQUARE_16X16  # Use default for error

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                render_header_row(logo, "ERROR", heading_color, "", subheading_color, header_bgnd_color),
                render_data_row(message, data_color, data_bgnd_color),
            ],
        ),
    )

def render_header_row(logo, heading, heading_color, subheading, subheading_color, bgnd_color):
    """Render a header row

    Args:
        logo: (str) A base64 encoded image
        heading: (str) A heading to display
        heading_color: (str) Hex string for heading color
        subheading: (str) A subheading to display
        subheading_color: (str) Hex string for subheading color
        bgnd_color: (str) Hex string for background color
    Returns:
        Render object with the row
    """

    return render.Row(
        main_align = "start",
        cross_align = "start",
        expanded = True,
        children = [
            render.Image(
                src = base64.decode(logo),
                width = 16,
                height = 16,
            ),
            render.Box(
                height = 16,
                color = bgnd_color,
                child = render.Marquee(
                    width = 48,
                    height = 16,
                    align = "center",
                    child = render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = str(heading),
                                font = HEADING_FONT,
                                color = heading_color,
                            ),
                            render.Text(
                                content = str(subheading),
                                font = SUBHEADING_FONT,
                                color = subheading_color,
                            ),
                        ],
                    ),
                ),
            ),
        ],
    )

def render_data_row(content, data_color, bgnd_color):
    """Render the data row

    Args:
        content: (str) The data to display
        data_color: (str) Hex string for data color
        bgnd_color: (str) Hex string for background color
    Returns:
        Render object with the row
    """

    return render.Row(
        main_align = "center",
        cross_align = "center",
        expanded = True,
        children = [
            render.Box(
                height = 16,
                color = bgnd_color,
                child = render.Marquee(
                    width = 64,
                    align = "center",
                    offset_start = 32,
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Text(
                                content = str(content),
                                font = DATA_FONT,
                                color = data_color,
                            ),
                        ],
                    ),
                ),
            ),
        ],
    )

def keyframes_slide_left_to_right():
    """Keyframes list for sliding left to right animation

    Args: None

    Returns:
        (list) Array of keyframes
    """
    return [
        animation.Keyframe(
            percentage = 0.0,
            transforms = [animation.Translate(x = -64, y = 0)],
        ),
        animation.Keyframe(
            percentage = 0.05,
            transforms = [animation.Translate(x = 0, y = 0)],
        ),
        animation.Keyframe(
            percentage = 0.95,
            transforms = [animation.Translate(x = 0, y = 0)],
        ),
        animation.Keyframe(
            percentage = 1.0,
            transforms = [animation.Translate(x = 64, y = 0)],
        ),
    ]

def get_reporting_period_subheading(reporting_period_config):
    """Get display subheading based on reporting period config

    Args:
        reporting_period_config: (str) The reporting period config

    Returns:
        subheading: (str) The subheading display string or None if not found
    """

    switch_subheading = {
        "today": "Today",
        "last_7_days": "7 Days",
        "last_30_days": "30 Days",
        "last_90_days": "90 Days",
        "this_month": "This Month",
        "this_year": "This Year",
    }

    subheading = switch_subheading.get(reporting_period_config, "Invalid Reporting Period")

    if subheading == None:
        return None
    else:
        return subheading

def get_reporting_period_start_date(reporting_period_config, end_date, timezone):
    """Get hours to start date based on reporting period config

    Args:
        reporting_period_config: (str) The reporting period config
        end_date: (time.Time) End date of the reporting period
            YYYY-MM-DD format
        timezone: (str) The timezone to use for the start date

    Returns:
        (Time) The Start Date for the reporting period in YYYY-MM-DD format
    """

    end_date_str = end_date.format("2006-01-02")
    end_date_parts = end_date_str.rsplit("-", 3)

    if "today" == reporting_period_config:
        start_date = end_date
    elif "last_7_days" == reporting_period_config:
        start_date = end_date - time.parse_duration(str(7 * 24) + "h")
    elif "last_30_days" == reporting_period_config:
        start_date = end_date - time.parse_duration(str(30 * 24) + "h")
    elif "last_90_days" == reporting_period_config:
        start_date = end_date - time.parse_duration(str(90 * 24) + "h")
    elif "this_month" == reporting_period_config:
        start_date = time.parse_time(end_date_parts[0] + "-" + end_date_parts[1] + "-01", "2006-01-02", timezone)
    elif "this_year" == reporting_period_config:
        start_date = time.parse_time(end_date_parts[0] + "-01" + "-01", "2006-01-02", timezone)
    else:
        start_date = None

    return start_date

def get_schema():
    """Get the schema for the app options

    Args:
        None
    Returns:
        (schema.Schema) The schema for the app options
    """

    cache_options = [
        schema.Option(
            display = "5 minutes",
            value = "300",
        ),
        schema.Option(
            display = "10 minutes",
            value = "600",
        ),
        schema.Option(
            display = "15 minutes",
            value = "900",
        ),
        schema.Option(
            display = "30 minutes",
            value = "1800",
        ),
        schema.Option(
            display = "1 hour",
            value = "3600",
        ),
        schema.Option(
            display = "4 hours",
            value = "14400",
        ),
        schema.Option(
            display = "24 hours",
            value = "86400",
        ),
    ]

    reporting_options = [
        schema.Option(
            display = "Today",
            value = "today",
        ),
        schema.Option(
            display = "Last 7 Days",
            value = "last_7_days",
        ),
        schema.Option(
            display = "Last 30 Days",
            value = "last_30_days",
        ),
        schema.Option(
            display = "Last 90 Days",
            value = "last_90_days",
        ),
        schema.Option(
            display = "This Month",
            value = "this_month",
        ),
        schema.Option(
            display = "This Year",
            value = "this_year",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "shopUrl",
                name = "Shop URL",
                desc = "The fully qualified URL of your WooCommerce website home page (i.e. https://www.example.com)",
                icon = "link",
            ),
            schema.Text(
                id = "consumerKey",
                name = "Consumer Key",
                desc = "The consumer key for your WooCommerce API. Generate read only keys under WooCommerce > Settings > Advanced > Rest API.",
                icon = "key",
            ),
            schema.Text(
                id = "consumerSecretKey",
                name = "Consumer Secret Key",
                desc = "The consumer secret key for your WooCommerce API. Generate read only keys under WooCommerce > Settings > Advanced > Rest API.",
                icon = "key",
            ),
            schema.Location(
                id = "shopLocation",
                name = "Shop Location",
                desc = "Used for the timezone when calculating the reporting period",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "reportingPeriod",
                name = "Reporting Period",
                desc = "The time period for which to display stats",
                icon = "clock",
                default = reporting_options[1].value,
                options = reporting_options,
            ),
            schema.Dropdown(
                id = "cacheTtl",
                name = "Refresh Interval",
                desc = "How often to pull new data from your site",
                icon = "database",
                default = cache_options[2].value,
                options = cache_options,
            ),
        ],
    )
