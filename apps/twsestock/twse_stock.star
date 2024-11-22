"""
Applet: TWSE Stock
Summary: Display TWSE stocks
Description: Configure up to 2 stocks to show.
Author: Mark Chu
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

TW_ICON = base64.decode("""
PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI5MDAiIGhlaWdodD0iNjAwIiBmaWxsPSIjZmZmIj48cGF0aCBkPSJNMCAwaDkwMHY2MDBIMHoiIGZpbGw9IiNmZTAwMDAiLz48cGF0aCBkPSJNMCAwaDQ1MHYzMDBIMHoiIGZpbGw9IiMwMDAwOTUiLz48cGF0aCBkPSJNMjI1IDM3LjVsLTU2LjI1IDIwOS45MjhMMzIyLjQyOCA5My43NSAxMTIuNSAxNTBsMjA5LjkyOCA1Ni4yNUwxNjguNzUgNTIuNTcyIDIyNSAyNjIuNWw1Ni4yNS0yMDkuOTI4TDEyNy41NzIgMjA2LjI1IDMzNy41IDE1MCAxMjcuNTcyIDkzLjc1IDI4MS4yNSAyNDcuNDI4IDIyNSAzNy41Ii8+PGNpcmNsZSBjeT0iMTUwIiBjeD0iMjI1IiByPSI2MCIgc3Ryb2tlPSIjMDAwMDk1IiBzdHJva2Utd2lkdGg9IjcuNSIvPjwvc3ZnPg==
""")

# cache stock info for 2 minutes
DEFAULT_API_CACHE_TTL = 120
DEFAULT_IMAGE_API_CACHE_TTL = 3600
IMAGE_LOOKUP_URL = "https://assets.imgix.net/~text?h=44&txt-color=fff&txt-align=left,center&txt-font=Futura%20Condensed%20Medium&txt-pad=0&txt-size=30"

EASE_IN_OUT = "ease_in_out"

def main(config):
    STOCK_LIST = []

    stock_no_1 = config.get("stock_no_1", "2330")
    STOCK_LIST.append("tse_" + stock_no_1 + ".tw")

    stock_no_2 = config.get("stock_no_2", "0050")
    STOCK_LIST.append("tse_" + stock_no_2 + ".tw")

    TW_STOCK_API_URL = "https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=" + "|".join(STOCK_LIST)

    rep = http.get(TW_STOCK_API_URL, ttl_seconds = DEFAULT_API_CACHE_TTL)
    if rep.status_code != 200:
        fail("stock API request failed with status %d", rep.status_code)

    response_json = rep.json()
    stock_array = response_json["msgArray"]
    api_updated_time = response_json["queryTime"]["sysTime"]

    return render.Root(
        delay = 2000,
        max_age = 60,
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Padding(
                                pad = (2, 0, 0, 0),
                                child = render.Image(TW_ICON, height = 5, width = 7),
                            ),
                            render.Text("%s" % api_updated_time, font = "CG-pixel-3x5-mono"),
                        ],
                    ),
                    render_line_separator(),
                    render.Sequence(
                        children = [
                            animation.Transformation(
                                child = render_stock_row(stock_array[0]),
                                duration = 1,
                                keyframes = keyframes(0),
                            ),
                            animation.Transformation(
                                child = render_stock_row(stock_array[1]),
                                duration = 1,
                                keyframes = keyframes(64),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_line_separator():
    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Box(
            width = 64,
            height = 1,
            color = "#000095",
        ),
    )

def keyframes(x):
    return [
        animation.Keyframe(
            percentage = 0.0,
            transforms = [animation.Translate(x, 0)],
            curve = EASE_IN_OUT,
        ),
        animation.Keyframe(
            percentage = 1.0,
            transforms = [animation.Translate(-64, 0)],
            curve = EASE_IN_OUT,
        ),
    ]

def render_stock_row(stock_info):
    if "@" not in stock_info:
        return (
            render.Row(
                cross_align = "start",
                children = [
                    render.Text(""),
                ],
            )
        )

    open_value = float(stock_info["o"])
    yesterday_close_value = float(stock_info["y"])
    traded_price = float(stock_info["z"])
    spread_value = traded_price - yesterday_close_value
    spread_percentage = spread_value / open_value * 100

    font = "CG-pixel-4x5-mono"

    color = "#a00"  # red
    if spread_value < 0:
        color = "#0a0"  #green
    elif spread_value == 0:
        color = "#fff"  #white

    image_src = get_text_image(stock_info["n"])

    return (
        render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Column(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Image(height = 16, width = 32, src = image_src),
                    ],
                ),
                render.Column(
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Text("%s" % humanize.ftoa(float(spread_value), 2), color = color, font = font),
                        render.Text("%s" % humanize.ftoa(spread_percentage, 2) + "%", color = color, font = font),
                        render.Padding(
                            pad = (0, 6, 0, 0),
                            child = render.Text("%s" % humanize.ftoa(float(stock_info["z"]), 1), font = font),
                        ),
                    ],
                ),
            ],
        )
    )

def get_text_image(text):
    image_url = IMAGE_LOOKUP_URL + "&txt64=" + base64.encode(text, encoding = "url")

    return http.get(image_url, ttl_seconds = DEFAULT_IMAGE_API_CACHE_TTL).body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stock_no_1",
                name = "stock_no",
                desc = "First TWSE stock no",
                icon = "gear",
                default = "2330",
            ),
            schema.Text(
                id = "stock_no_2",
                name = "stock_no",
                desc = "Second TWSE stock no",
                icon = "gear",
                default = "0050",
            ),
        ],
    )
