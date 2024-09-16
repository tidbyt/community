"""
Applet: CellarTrackerRtd
Summary: Shows a ready to drink wine
Description: Displays a random wine from your CellarTracker Ready to Drink report.
Author: Matt Kent
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

CACHE_TTL_SECONDS = 600

DEFAULT_TOP_N_VALUE = 10

WHITE_WINE_GLASS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAWCAYAAAD5Jg1dAAAAAXNSR0IArs4c6QAAAH1JREFUOE9jPPvi138GIgAjS
KGROCtepede/mYYfgr12boZmAWrGP6+b8Pw/ZMHVxjeSi2E+Jo2CnGFOIbV1FMIMgnmIXRTYdYaS7AxMsIkQYqFn8
WjqAUFC0gRSBCuEGYyTDGyIgyFMMUgGmYSzAoUEwdIIa68A/c1sZkLAHHel5t001MXAAAAAElFTkSuQmCC
""")

SPARKLING_WINE_GLASS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAWCAYAAAASEbZeAAAAAXNSR0IArs4c6QAAAJtJREFUOE9jZGBgYDj74td/E
I0NGEuwMTLCFBmJs2KoOffyNwPxikBWYTMFZizINMYBUKTP1o3V+08eXGF4K7UQ4iaQImbBKoa/79vgikH8h+ejUB
XBZJEVY5iEzb6Bsg4WwejBAHMPPIJhCoWfxcPdDwofkAKQAJiAAVCYgRQiK8BQBDMRZgJMM4pJ1FOEnNaRrQRHMK5
MABMHACiPoD+N8QF/AAAAAElFTkSuQmCC
""")

ROSE_WINE_GLASS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAWCAYAAAD5Jg1dAAAAAXNSR0IArs4c6QAAAIFJREFUOE9jPPvi138GIgAjS
KGROCtepede/mYYfgr1O1YzMPdHMfwtXIbh+8/7DjPc2zUJ4mvaKMQV4hhWU08hyCSYh9BNhVlrLMHGyAiTBClWcs
tDUQsKFpAikCBcIcxkmGJkRRgKYYpBNMwkmBUoJg6gQvT8g+xOsBsJZTCQBgBCkp7t6fyTqwAAAABJRU5ErkJggg==
""")

RED_WINE_GLASS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAWCAYAAAD5Jg1dAAAAAXNSR0IArs4c6QAAAIFJREFUOE9jPPvi138GIgAjS
KGROCtepede/mYYfgp5g60ZVI+cYrhtY4bh+80fPjE47L0M8TVtFOIKcQyrqacQZBLMQ+imwqw1lmBjZIRJghQfcN
ZFUQsKFpAikCBcIcxkmGJkRRgKYYpBNMwkmBUoJg6gQvT8g+xOsBsJZTCQBgA6R5ftTBH+3wAAAABJRU5ErkJggg==
""")

def inventory_xml_to_dict_list(raw_xml_string):
    result = []
    rows = xpath.loads(raw_xml_string).query_all_nodes("/cellartracker/inventory/row")
    for row in rows:
        dict_row = {}
        dict_row["iWine"] = row.query("/iWine")
        dict_row["BottleNote"] = row.query("/BottleNote")
        result.append(dict_row)
    return result

def availability_xml_to_dict_list(raw_xml_string):
    result = []
    rows = xpath.loads(raw_xml_string).query_all_nodes("/cellartracker/availability/row")
    for row in rows:
        dict_row = {}
        dict_row["iWine"] = row.query("/iWine")
        dict_row["Type"] = row.query("/Type")
        dict_row["Category"] = row.query("/Category")
        dict_row["Vintage"] = row.query("/Vintage")
        dict_row["Wine"] = row.query("/Wine")
        dict_row["Producer"] = row.query("/Producer")
        dict_row["Designation"] = row.query("/Designation")
        dict_row["Varietal"] = row.query("/Varietal")
        result.append(dict_row)
    return result

# Get inventory report which includes private notes
# that we can use for filtering out excluded bottles
def get_inventory_xml(username, password):
    url = "https://www.cellartracker.com/xlquery.asp?User=%s&Password=%s&Format=xml&Table=Inventory" % (username, password)
    resp = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    if resp.status_code != 200:
        fail("API request failed with status %d", resp.status_code)
    return resp.body()

# Get availability report which is sorted by ready to drink
def get_availability_xml(username, password):
    url = "https://www.cellartracker.com/xlquery.asp?User=%s&Password=%s&Format=xml&Table=Availability" % (username, password)
    resp = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    if resp.status_code != 200:
        fail("API request failed with status %d", resp.status_code)
    return resp.body()

# Return a list of iWine ids for bottles to be excluded from the availability report
def select_excluded_wine_ids(inventory_list, exclusion_keyword_list):
    excluded_wine_ids = []
    for bottle in inventory_list:
        for keyword in exclusion_keyword_list:
            if keyword in bottle["BottleNote"]:
                excluded_wine_ids.append(bottle["iWine"])
    return excluded_wine_ids

def wine_display_text(bottle):
    display_text_components = [bottle["Vintage"], bottle["Wine"]]
    return " ".join(display_text_components)

# Use this command to generate base64 data of the image files
#
# python -c 'import base64; print(base64.b64encode(open("images/white-wine-glass.png", "rb").read()).decode("utf-8"))'
#
def get_wine_glass_icon(bottle):
    wine_type = bottle["Type"]
    if wine_type == "White":
        return WHITE_WINE_GLASS_ICON
    elif wine_type.endswith("Sparkling"):
        # CellarTracker has "Red - Sparkling", "White - Sparkling" etc but we only have one sparkling icon
        return SPARKLING_WINE_GLASS_ICON
    elif wine_type == "Rosé":
        return ROSE_WINE_GLASS_ICON
    else:
        return RED_WINE_GLASS_ICON

def select_displayable_bottles(availability_list, excluded_wine_ids):
    displayable_bottles = []
    for bottle in availability_list:
        bottle_id = bottle["iWine"]
        if bottle_id not in excluded_wine_ids:
            displayable_bottles.append(bottle)
    return displayable_bottles

def select_bottle_to_display(top_n_value, displayable_bottles):
    top_n_length = min(top_n_value, len(displayable_bottles))
    top_n_bottles = displayable_bottles[0:top_n_length]
    idx = random.number(0, len(top_n_bottles) - 1)
    return top_n_bottles[idx]

def render_widgets(wine_glass_icon, wine_display_name):
    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render.Box(
                    width = 14,
                    child = render.Image(
                        src = wine_glass_icon,
                    ),
                ),
                render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    offset_start = 30,
                    offset_end = 30,
                    align = "center",
                    child = render.WrappedText(
                        width = 50,
                        content = wine_display_name,
                        color = "#afafaf",
                    ),
                ),
            ],
        ),
    )

def main(config):
    username = config.get("cellartracker_username")
    password = config.get("cellartracker_password")
    exclusion_keywords_string = config.get("exclusion_keywords")
    top_n_value = int(config.get("top_n_value") or DEFAULT_TOP_N_VALUE)

    # These options are not exposed in the schema and are only
    # intended to be used in development
    bottle_id_override = config.get("bottle_id")

    exclusion_keyword_list = []
    if exclusion_keywords_string:
        exclusion_keyword_list = exclusion_keywords_string.split(",")

    if username and password:
        print("CellarTracker credentials found, fetching data from server")

        raw_inventory_xml = get_inventory_xml(username, password)
        raw_availability_xml = get_availability_xml(username, password)
    else:
        print("No CellarTracker credentials found")

        return render_widgets(RED_WINE_GLASS_ICON, "2023 Your Favorite Red Wine")

    inventory_list = inventory_xml_to_dict_list(raw_inventory_xml)
    availability_list = availability_xml_to_dict_list(raw_availability_xml)

    excluded_wine_ids = select_excluded_wine_ids(inventory_list, exclusion_keyword_list)
    displayable_bottles = select_displayable_bottles(availability_list, excluded_wine_ids)

    bottle = select_bottle_to_display(top_n_value, displayable_bottles)

    if bottle_id_override:
        bottle = [b for b in availability_list if b["iWine"] == bottle_id_override][0]

    wine_glass_icon = get_wine_glass_icon(bottle)
    wine_display_name = wine_display_text(bottle)

    return render_widgets(wine_glass_icon, wine_display_name)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "cellartracker_username",
                name = "CellarTracker username",
                desc = "CellarTracker username",
                icon = "user",
            ),
            schema.Text(
                id = "cellartracker_password",
                name = "CellarTracker password",
                desc = "CellarTracker password",
                icon = "key",
            ),
            schema.Text(
                id = "exclusion_keywords",
                name = "Exclusion keywords",
                desc = "Comma-separated list of keywords. If any keyword is found in the BottleNote then the wine is excluded from display.",
                icon = "ban",
            ),
            schema.Text(
                id = "top_n_value",
                name = "Top N bottles",
                desc = "This app displays a random bottle from the top N bottles of the ready-to-drink report. Set N to a larger number if you want more variety in the results displayed or if you have a lot of bottles in your cellar that will be ready to drink soon.",
                icon = "wineBottle",
                default = "10",
            ),
        ],
    )
