"""
Applet: AA Daily Reflections
Summary: Display the AA Daily Reflection
Description: Display AA Daily Refelection from the AA.org website
Author: jvivona
"""

load("render.star", "render")
load("time.star", "time")
load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")

APPTITLE_TEXT_COLOR = "#fff"
APPTITLE_BKG_COLOR = "#0000ff"
APPTITLE_FONT = "tom-thumb"
APPTITLE_HEIGHT = 5
APPTITLE_WIDTH = 64

REFLECTION_AREA_HEIGHT = 26
REFLECTION_SUB_TITLE_FONT = "tom-thumb"
REFLECTION_SUB_TITLE_COLOR = "#ff8c00"
REFLECTION_FONT = "tb-8"
REFLECTION_COLOR = "#00eeff"
SPACER_COLOR = "#000"
REFLECTION_LINESPACING = 0

# need to append the 2 digit month and 2 digit day to the end of this, do a GET and data is returned as json
API_STUB = "https://www.aa.org/api/reflections/"

#this only changes once per day so we can long term cache it
CACHE_TTL_SECONDS = 86399

TITLE_FINDER = "field--name-title field--type-string field--label-hidden"
TITLE_FINDER_END = "</span>"
TITLE_OFFSET = 2

TEASER_FINDER = "field--name-field-teaser field--type-text-long field--label-hidden field__item"
TEASER_FINDER_END = "</strong></p>"
TEASER_OFFSET = 13

REFERENCE_FINDER = "<strong>"
REFERENCE_FINDER_END = "</strong>"
REFERENCE_OFFSET = 0

def main(config):
    return render.Root(
        delay = 75,
        child = render.Column(
            children = [
                render.Marquee(
                    height = REFLECTION_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 16,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_text(config),
                        ),
                ),
                render.Box(
                    width = APPTITLE_WIDTH,
                    height = 1,
                    padding = 0,
                    color = APPTITLE_BKG_COLOR,
                ),
                render.Box(
                    width = APPTITLE_WIDTH,
                    height = APPTITLE_HEIGHT,
                    padding = 0,
                    color = "#000",
                    child = render.Text("Daily Reflection", color = APPTITLE_TEXT_COLOR, font = APPTITLE_FONT, offset = -1),
                ),
            ],
        ),
    )

def get_cachable_data(url):
    key = url

    data = cache.get(key)
    if data != None:
        return data

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, res.body(), ttl_seconds = CACHE_TTL_SECONDS)

    return res.body()

def render_text(config):
    current_month_day = time.now().in_location(config.get("$tz", "America/Chicago")).format("01/02/06")[:5]
    daily_reflection = json.decode(get_cachable_data(API_STUB + current_month_day))["data"]

    title = extract_text(daily_reflection, TITLE_FINDER, TITLE_FINDER_END, TITLE_OFFSET).title()

    # the structure is well known and consistent from day to day so split on the div tag and narrow the search
    teaser = extract_text(daily_reflection.split("<div")[2], TEASER_FINDER, TEASER_FINDER_END, TEASER_OFFSET)

    # same technique as above, but the reference is a <p> tag inside the div so use that to our advantage
    reference = extract_text(daily_reflection.split("<div")[2].split("<p>")[2], REFERENCE_FINDER, REFERENCE_FINDER_END, REFERENCE_OFFSET).title().replace("P.", "p.")

    if len(title) == 0 or len(teaser) == 0 or len(reference) == 0:
        return error()

    return [
        render.WrappedText(title, font = REFLECTION_SUB_TITLE_FONT, color = REFLECTION_SUB_TITLE_COLOR, linespacing = REFLECTION_LINESPACING),
        render.Box(width = 64, height = 3, color = SPACER_COLOR),
        render.WrappedText(teaser, font = REFLECTION_FONT, color = REFLECTION_COLOR, linespacing = REFLECTION_LINESPACING),
        render.Box(width = 64, height = 3, color = SPACER_COLOR),
        render.WrappedText(reference, font = REFLECTION_SUB_TITLE_FONT, color = REFLECTION_SUB_TITLE_COLOR, linespacing = REFLECTION_LINESPACING),
    ]

def extract_text(content, start_string, end_string, offset):
    text_start = content.find(start_string)
    text_end = content.find(end_string, text_start)
    if text_start == -1 or text_end == -1:
        return ""
    return content[text_start + len(start_string) + offset:text_end].replace("&quot;", "\"")

def error():
    return render.WrappedText("An error has occurred getting the daily reflection.", width = 64)
