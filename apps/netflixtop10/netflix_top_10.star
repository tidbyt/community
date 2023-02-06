"""
Applet: Netflix Top 10
Summary: Top shows on Netflix
Description: Shows the top 10 charts for movies or TV shows on Netflix.
Author: Matt Broussard
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll_direction",
                name = "Scroll Direction",
                desc = "The direction to scroll text. If horizontal, you'll see a fixed number of entries but the titles will scroll. If vertical, you can see all of the top 10, but the titles will be truncated.",
                icon = "arrowsUpDownLeftRight",
                default = "vertical",
                options = [
                    schema.Option(display = "Vertical", value = "vertical"),
                    schema.Option(display = "Horizontal", value = "horizontal"),
                    schema.Option(display = "Off", value = "off"),
                ],
            ),
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "The region for which to show the Netflix chart.",
                icon = "globe",
                default = "global",
                options = get_region_options(),
            ),
            schema.Generated(
                id = "category_gen",
                source = "region",
                handler = gen_category_dropdown,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Font size. Small allows 5 rows on screen; large only allows 4.",
                icon = "font",
                default = "tb-8",
                options = [
                    schema.Option(display = "Large", value = "tb-8"),
                    schema.Option(display = "Small", value = "tom-thumb"),
                ],
            ),
        ],
    )

def main(config):
    region = config["region"] if "region" in config else "global"
    category = config["category"] if "category" in config else default_category_for_region(region)
    font = config["font"] if "font" in config else "tb-8"
    scroll_direction = config["scroll_direction"] if "scroll_direction" in config else "vertical"

    n = 10 if scroll_direction == "vertical" else 4 if font == "tb-8" else 5
    rows = get_rows_for_display(region, category)[:n]

    # workaround: when changing regions, can have a category setting left over from previous region
    # that matches nothing in the current region
    if len(rows) == 0:
        rows = get_rows_for_display(region, default_category_for_region(region))[:n]

    def h_marquee(child):
        if scroll_direction == "horizontal":
            left_col_width = 10
            return render.Marquee(child = child, width = 64 - left_col_width)
        else:
            return child

    def v_marquee(child):
        if scroll_direction == "vertical":
            return render.Marquee(child = child, scroll_direction = "vertical", height = 32)
        else:
            return child

    col_spacer = render.Box(width = 2, height = 32) if scroll_direction != "vertical" else None

    return render.Root(
        child = v_marquee(
            render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                "%d:" % (i + 1,),
                                color = "#f00",
                                font = font,
                            )
                            for i in range(len(rows))
                        ],
                    ),
                    col_spacer,
                    render.Column(
                        children = [
                            h_marquee(render.Text(get_title(row), font = font))
                            for row in rows
                        ],
                    ),
                ],
            ),
        ),
        delay = 100,
    )

def get_regions():
    val = cache.get("regions")
    if val != None:
        return json.decode(val)

    table = load_countries_table()
    regions = {row["country_iso2"]: row["country_name"] for row in table}

    cache.set("regions", json.encode(regions), ttl_seconds = 60 * 60)
    return regions

def get_region_options():
    regions = get_regions()

    return [
        schema.Option(display = "Global", value = "global"),

        # for convenience, list US at top of the list instead of bottom
        schema.Option(display = "United States", value = "US"),
    ] + [
        schema.Option(display = region_name, value = region_iso)
        for region_iso, region_name in regions.items()
        if region_iso != "US"
    ]

def get_categories(region):
    table = load_global_table() if region == "global" else load_countries_table()
    cat_set = {row["category"]: True for row in table}
    return cat_set.keys()

def default_category_for_region(region):
    return "TV (English)" if region == "global" else "TV"

def gen_category_dropdown(region):
    categories = get_categories(region)
    return [schema.Dropdown(
        id = "category",
        name = "Category",
        desc = "The category of content to display the chart for",
        default = default_category_for_region(region),
        icon = "cameraMovie",
        options = [
            schema.Option(display = category, value = category)
            for category in categories
        ],
    )]

def get_title(row):
    season = row["season_title"] if "season_title" in row else ""
    if season == "" or season == "N/A":
        return row["show_title"]
    return season

def load_url_cached(url):
    cache_key = "url-%s" % (url,)

    val = cache.get(cache_key)
    if val != None:
        return val

    resp = http.get(url)
    if resp.status_code != 200:
        return None

    val = resp.body()
    cache.set(cache_key, val, ttl_seconds = 60 * 60)
    return val

def load_countries_table():
    body = load_url_cached("https://top10.netflix.com/data/all-weeks-countries.tsv")
    return parse_tsv(body)

def load_global_table():
    body = load_url_cached("https://top10.netflix.com/data/all-weeks-global.tsv")
    return parse_tsv(body)

def get_rows_for_display(region, category):
    data = load_global_table() if region == "global" else load_countries_table()
    if data == None:
        return [{"show_title": "Error loading chart"}]

    latest_week = data[0]["week"]

    def matches(row):
        return row["category"] == category and \
               row["week"] == latest_week and \
               (region == "global" or row["country_iso2"] == region)

    filtered = [row for row in data if matches(row)]
    rows = sorted(filtered, key = lambda row: int(row["weekly_rank"]))

    return rows

def parse_tsv(tsvString):
    if tsvString == None:
        return None

    header = None
    rows = []

    for line in tsvString.split("\n"):
        parts = line.split("\t")
        if header == None:
            header = parts
            continue

        rows.append({k: v for k, v in zip(header, parts)})

    return rows
