"""
Applet: NASCAR Next Race
Summary: Next NASCAR Race Time and Location - select series
Description: Shows Time date and location of Next NASCAR Race - Cup, Xfinity, Trucks - original version based heavily on F1 Next Race from AMillionAir
Author: jvivona
"""

load("render.star", "render")
load("animation.star", "animation")
load("http.star", "http")
load("encoding/json.star", "json")
load("time.star", "time")
load("schema.star", "schema")
load("cache.star", "cache")

# cache data for 15 minutes - cycle through with cache on the API side
CACHE_TTL_SECONDS = 900

DEFAULT_TIMEZONE = "America/New_York"

#we grab the current schedule from nascar website and cache it at this api location to prevent getting blocked by nascar website, data is refreshed every 30 minutes
NASCAR_API = "https://tidbyt.apis.ajcomputers.com/nascar/api/"
DEFAULT_SERIES = "cup"
DEFAULT_TIME_24 = False
DEFAULT_DATE_US = True

REGULAR_FONT = "tom-thumb"
DATETIME_FONT = "tb-8"

ANIMATION_FRAMES = 30
ANIMATION_HOLD_FRAMES = 75
DEFAULT_ANIMATION = "slide"

DATA_BOX_BKG = "#000"
SLIDE_DURATION = 99

DATA_BOX_WIDTH = 64
DATA_BOX_HEIGHT = 20
TITLE_BOX_WIDTH = 64
TITLE_BOX_HEIGHT = 12

# Easing
EASE_IN = "ease_in"
EASE_OUT = "ease_out"
EASE_IN_OUT = "ease_in_out"

CONST_VALUES = """
{
    "cup" : [ "cup", "#333333", "#fff", "NASCAR\nCup Series" ],
    "xfinity" : [ "xfinity", "#4427ad", "#fff", "NASCAR\nXfinity Series" ],
    "trucks" : [ "trucks", "#990000", "#fff", "Craftsman\nTruck Series" ]
}
"""

def main(config):
    #TIme and date Information
    #Get the current time in 24 hour format
    timezone = config.get("$tz", DEFAULT_TIMEZONE)  # Utilize special timezone variable to get TZ - otherwise assume US Eastern w/DST
    series = config.get("NASCAR_Series", DEFAULT_SERIES)

    NASCAR_DATA = json.decode(get_cachable_data(NASCAR_API + series))

    series_values = json.decode(CONST_VALUES)
    series_title = series_values[series][3]
    series_bkg_color = series_values[series][1]
    series_txt_color = series_values[series][2]

    date_and_time = NASCAR_DATA["Race_Date"]
    date_and_time3 = time.parse_time(date_and_time, "2006-01-02T15:04:05-0700").in_location(timezone)
    date_str = date_and_time3.format("Jan 02" if config.bool("is_us_date_format", DEFAULT_DATE_US) else "02 Jan").title()  #current format of your current date str
    time_str = "TBD" if date_and_time.endswith("T00:00:00-0500") else date_and_time3.format("15:04 " if config.bool("is_24_hour_format", DEFAULT_TIME_24) else "3:04pm")[:-1]
    tv_str = NASCAR_DATA["Race_TV_Display"] if NASCAR_DATA["Race_TV_Display"] != "" else "TBD"

    if config.get("fade_slide", DEFAULT_ANIMATION) == "slide":
        data_child = slideinout_child(NASCAR_DATA["Race_Name"], NASCAR_DATA["Track_Name"], "%s %s\nTV: %s" % (date_str, time_str, tv_str))
    else:
        data_child = fade_child(NASCAR_DATA["Race_Name"], NASCAR_DATA["Track_Name"], "%s %s\nTV: %s" % (date_str, time_str, tv_str))

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = TITLE_BOX_WIDTH,
                    height = TITLE_BOX_HEIGHT,
                    color = series_bkg_color,
                    child = render.Padding(
                        pad = (0, 0, 0, 0),
                        child = render.WrappedText(series_title, color = series_txt_color, font = REGULAR_FONT, align = "center", height = TITLE_BOX_HEIGHT, width = TITLE_BOX_WIDTH),
                    ),
                ),
                data_child,
            ],
        ),
    )

def slideinout_child(race, track, time):
    return render.Sequence(
        children = [
            slidetransform(race, REGULAR_FONT),
            slidetransform(track, REGULAR_FONT),
            slidetransform(time, DATETIME_FONT),
        ],
    )

def slidetransform(text, font):
    return animation.Transformation(
        child = render.Box(width = DATA_BOX_WIDTH, height = DATA_BOX_HEIGHT, color = DATA_BOX_BKG, child = render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = font, color = "#fff", align = "center", width = DATA_BOX_WIDTH)])),
        duration = SLIDE_DURATION,
        delay = 0,
        origin = animation.Origin(0, 0),
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(-DATA_BOX_WIDTH, 0)],
                curve = EASE_IN_OUT,
            ),
            animation.Keyframe(
                percentage = 0.1,
                transforms = [animation.Translate(-0, 0)],
                curve = EASE_IN_OUT,
            ),
            animation.Keyframe(
                percentage = 0.9,
                transforms = [animation.Translate(-0, 0)],
                curve = EASE_IN_OUT,
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(DATA_BOX_WIDTH, 0)],
                curve = EASE_IN_OUT,
            ),
        ],
    )

# need to come back to this, this is just an up down slide - it should simulate a flip motion
#def flip(text, text_font):
#    return animation.Transformation(
#        child = render.Box(width = DATA_BOX_WIDTH, height = DATA_BOX_HEIGHT, color = DATA_BOX_BKG, child = render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = DATETIME_FONT, color = "#fff", align = "center", width = 64)])),
#        height = 20,
#        keyframes = [
#            animation.Keyframe(0.0, [animation.Translate(0, 0), animation.Scale(1, 1)], curve = "ease_in_out"),
#            animation.Keyframe(1.0, [animation.Translate(0, -DATA_BOX_HEIGHT), animation.Scale(1, 1)], curve = "ease_in_out"),
#        ],
#        duration = 20,
#        delay = 100,
#        direction = "alternate",
#        fill_mode = "backwards",
#    )

def fade_child(race, track, date_time_tv):
    return render.Animation(
        children =
            createfadelist(race, ANIMATION_HOLD_FRAMES, REGULAR_FONT) +
            createfadelist(track, ANIMATION_HOLD_FRAMES, REGULAR_FONT) +
            createfadelist(date_time_tv, ANIMATION_HOLD_FRAMES, DATETIME_FONT),
    )

def createfadelist(text, cycles, text_font):
    cycle_list = []

    # this is a pure genius technique and is borrowed from @CubsAaron countdown_clock
    # need to ponder if there is a different way to do it if we want something other than grey
    for x in range(0, 10, 2):
        c = "#" + str(x) + str(x) + str(x) + str(x) + str(x) + str(x)
        cycle_list.append(render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = text_font, color = c, align = "center", width = DATA_BOX_WIDTH)]))
    for x in range(cycles):
        cycle_list.append(render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = text_font, color = "#fff", align = "center", width = DATA_BOX_WIDTH)]))
    for x in range(8, 0, -2):
        c = "#" + str(x) + str(x) + str(x) + str(x) + str(x) + str(x)
        cycle_list.append(render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = text_font, color = c, align = "center", width = DATA_BOX_WIDTH)]))
    return cycle_list

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "NASCAR_Series",
                name = "Series",
                desc = "Select which series to display",
                icon = "flagCheckered",
                default = DEFAULT_SERIES,
                options = [
                    schema.Option(
                        display = "NASCAR Cup Series",
                        value = "cup",
                    ),
                    schema.Option(
                        display = "NASCAR Xfinity Series",
                        value = "xfinity",
                    ),
                    schema.Option(
                        display = "NASCAR Craftsman Truck Series",
                        value = "trucks",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "fade_slide",
                name = "Fade or Slide",
                desc = "Show Race / Track / Time via Fade or Slide",
                icon = "eye",
                default = DEFAULT_ANIMATION,
                options = [
                    schema.Option(
                        display = "Fade Race / Track / Time In and Out",
                        value = "fade",
                    ),
                    schema.Option(
                        display = "Slide Race / Track / Time In and Out",
                        value = "slide",
                    ),
                ],
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = DEFAULT_TIME_24,
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format.",
                icon = "calendarDays",
                default = DEFAULT_DATE_US,
            ),
        ],
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
