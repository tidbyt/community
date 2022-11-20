"""
Applet: NASCAR Next Race
Summary: Next NASCAR Race Time and Location - select series
Description: Shows Time date and location of Next NASCAR Race - Cup, Xfinity, Trucks - original version based heavily on F1 Next Race from AMillionAir
Author: jvivona
"""

load("render.star", "render")
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

REGULAR_FONT = "tom-thumb"
DATETIME_FONT = "tb-8"
ANIMATION_FRAMES = 30

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
    date_str = date_and_time3.format("Jan 02" if config.bool("is_us_date_format", True) else "02 Jan").title()  #current format of your current date str
    time_str = "TBD" if date_and_time.endswith("T00:00:00-0500") else date_and_time3.format("15:04 " if config.bool("is_24_hour_format", False) else "3:04pm")[:-1]
    tv_str = NASCAR_DATA["Race_TV_Display"] if NASCAR_DATA["Race_TV_Display"] != "" else "TBD"

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 12,
                    color = series_bkg_color,
                    child = render.Padding(
                        pad = (0, 0, 0, 0),
                        child = render.WrappedText(series_title, color = series_txt_color, font = REGULAR_FONT, align = "center", height = 12, width = 64),
                    ),
                ),
                render.Animation(
                    children =
                        createfadelist(NASCAR_DATA["Race_Name"], ANIMATION_FRAMES, REGULAR_FONT) +
                        createfadelist(NASCAR_DATA["Track_Name"], ANIMATION_FRAMES, REGULAR_FONT) +
                        createfadelist("%s %s\nTV: %s" % (date_str, time_str, tv_str), ANIMATION_FRAMES, DATETIME_FONT),
                ),
            ],
        ),
    )

def createfadelist(text, cycles, text_font):
    cycle_list = []

    # this is a pure genius technique and is borrowed from @CubsAaron countdown_clock
    # need to ponder if there is a different way to do it if we want something other than grey
    for x in range(0, 10, 2):
        c = "#" + str(x) + str(x) + str(x) + str(x) + str(x) + str(x)
        cycle_list.append(render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = text_font, color = c, align = "center", width = 64)]))
    for x in range(cycles):
        cycle_list.append(render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = text_font, color = "#fff", align = "center", width = 64)]))
    for x in range(8, 0, -2):
        c = "#" + str(x) + str(x) + str(x) + str(x) + str(x) + str(x)
        cycle_list.append(render.Column(main_align = "center", cross_align = "center", expanded = True, children = [render.WrappedText(text, font = text_font, color = c, align = "center", width = 64)]))
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
                default = "cup",
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
                        display = "Craftsman Truck Series",
                        value = "trucks",
                    ),
                ],
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format.",
                icon = "calendarDays",
                default = True,
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
