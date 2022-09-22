"""
Applet: NASCAR Next Race
Summary: Next NASCAR Race Time and Location - select series
Description: Shows Time date and location of Next NASCAR Race - Cup, Xfinity, Trucks - based heavily on F1 Next Race from AMillionAir
Author: jvivona
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("schema.star", "schema")
load("cache.star", "cache")

# cache data for 15 minutes - cycle through with cache on the API side
CACHE_TTL_SECONDS = 900

DEFAULT_TIMEZONE = "America/New_York"

#we grab the current schedule from nascar website and cache it at this api location to prevent getting blocked by nascar website, data is refreshed every 30 minutes
NASCAR_API = "https://tidbyt.apis.ajcomputers.com/nascar/api/"
DEFAULT_SERIES = "cup"

CONST_VALUES = """
{
    "cup" : [ "cup", "#000", "#fff", "NASCAR Cup Series" ],
    "xfinity" : [ "xfinity", "#4427ad", "#fff", "NASCAR Xfinity Series" ],
    "trucks" : [ "trucks", "#00669e", "#fff", "Camping World Truck Series" ]
}
"""

def main(config):
    #TIme and date Information
    # Get the current time in 24 hour format
    timezone = config.get("$tz", DEFAULT_TIMEZONE)  # Utilize special timezone variable to get TZ - otherwise assume US Eastern w/DST
    now = time.now().in_location(timezone)
    Year = now.format("2006")
    series = config.get("NASCAR_Series", DEFAULT_SERIES)

    NASCAR_DATA = json.decode(get_cachable_data(NASCAR_API + series))

    series_values = json.decode(CONST_VALUES)
    series_title = series_values[series][3]
    series_bkg_color = series_values[series][1]
    series_txt_color = series_values[series][2]

    date_and_time = NASCAR_DATA["Race_Date"]
    date_and_time3 = time.parse_time(date_and_time, "2006-01-02T15:04:05-0700").in_location(timezone)
    date_str = date_and_time3.format("Jan 02").upper()  #current format of your current date str
    time_str = date_and_time3.format("15:04")  #outputs military time but can change 15 to 3 to not do that. The Only thing missing from your current string though is the time zone, but if they're doing local time that's pretty irrelevant

    return render.Root(
        delay = 50,
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text("Next Race: " + NASCAR_DATA["Race_Name"] + "    Track: " + NASCAR_DATA["Track_Name"]),
                    offset_start = 5,
                    offset_end = 5,
                ),
                render.Box(width = 64, height = 1, color = "#a0a"),
                render.Row(
                    children = [
                        render.Box(width = 30, height = 24, color = series_bkg_color, child = render.WrappedText(series_title, color = series_txt_color, align = "center", font = "tom-thumb")),
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child =
                                render.Column(
                                    children = [
                                        render.Text(date_str, font = "5x8"),
                                        render.Text(time_str),
                                        render.Text("TV " + NASCAR_DATA["Race_TV_Display"]),
                                    ],
                                ),
                        ),
                    ],
                ),
            ],
        ),
    )

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
                        display = "Camping World Truck Series",
                        value = "trucks",
                    ),
                ],
            ),
        ],
    )

def get_cachable_data(url):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)

    return res.body()
