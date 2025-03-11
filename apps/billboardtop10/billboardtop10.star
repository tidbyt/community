"""
Applet: BillboardTop10
Summary: Display top 10 songs
Description: Displays top 10 songs from Billboard.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

BILLBOARD_CACHED_TOP10_NAME = "BillboardCache"
BILLBOARD_ICON = """
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAICAIAAABVpBlvAAABVmlDQ1BJQ0MgcHJvZmlsZQAAKJFtkL8vxGAYx7+lcgnCDcTAUIkBOSJ1A7ZzgwhDnZ8VS69XPdKrN20Fs9UmMUot/gJRI4vYJYh/gMkiaSRc6nnv0Ds8b548nzz5vk+++QINosaYJQIo2Z6Tm5qUVtRVKfEMAd1oxwS6NN1lGUWZJQm+Z32Fd6Smuh3it9bUt3P7etO3VNnvnAkO/+rrqrlguDrND+pBnTkeIPQTKzse47xL3OGQKeIDzmaVfc75Kp9VNAu5LPENcVIvagXiB+JUvmZv1nDJ2ta/PHD3rYa9OE+zjboHCjKQkcYY5rBE2fyvTVe0WWyBYQ8ONmCiCA8S/Wb0LBjE07ChYxgpYhkj/C7P+Hd28Y7tA+M8t5d4p1nABWWfPI53fU9ktxe4OmGao/0kKoSiuz4qV7klAJqOouh1GUgMAOX7KHoPoqh8CjQ+ApfhJ3LYYwruNH3OAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6AICFRMwu9G4AQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAACESURBVAjXY0xLTZWQlFy0YCEDDDCeOXPGyMhISUERLsQCoZpbWljZWGfNnHXv7l2GM2fO/IOB169fKykoMkFUFRUVbdu2TVhYODYuFiqkpaUlICDAwMDw89cvhjNnzvz9+/fv37///v27d/eugpw8Y1pqqriExKtXr2SkZebOmcPAwAAAlwg4Pp81GiUAAAAASUVORK5CYII=
"""
BILLBOARD_SECRET_ENCRYPTED = "AV6+xWcEhIX2NmyIofzLupmsA47OTCfk/GVGYv2T8toDlq4koOD8ZP7nUaN30nB8nAZ4uIsrh3ziU6RHOzYzjvBc8jMgQovrxZqyrbwPag1jdj/RRM5K3sv2omEGvzUb8MEGPBC5i7ImuNa3dD9BLBXPKoRdh9C1VR+JAbrbz+K7dbLR+uv9Edouzovp5NQu4Fyon2MRNDE="
BILLBOARD_SAMPLE_DATA = """{"info": {"category": "Billboard", "chart": "HOT 100", "date": "1983-05-14", "source": "Billboard-API"}, "content": {"1": {"rank": "1", "title": "Beat It", "artist": "Michael Jackson", "weeks at no.1": "3", "last week": "1", "peak position": "1", "weeks on chart": "12", "detail": "same"}, "2": {"rank": "2", "title": "Let's Dance", "artist": "David Bowie", "last week": "3", "peak position": "2", "weeks on chart": "8", "detail": "up"}, "3": {"rank": "3", "title": "Jeopardy", "artist": "Greg Kihn Band", "last week": "2", "peak position": "2", "weeks on chart": "16", "detail": "down"}, "4": {"rank": "4", "title": "Overkill", "artist": "Men At Work", "last week": "6", "peak position": "4", "weeks on chart": "6", "detail": "up"}, "5": {"rank": "5", "title": "She Blinded Me With Science", "artist": "Thomas Dolby", "last week": "7", "peak position": "5", "weeks on chart": "13", "detail": "up"}, "6": {"rank": "6", "title": "Come On Eileen", "artist": "Dexy's Midnight Runners", "last week": "4", "peak position": "1", "weeks on chart": "17", "detail": "down"}, "7": {"rank": "7", "title": "Flashdance...What A Feeling", "artist": "Irene Cara", "last week": "13", "peak position": "7", "weeks on chart": "7", "detail": "up"}, "8": {"rank": "8", "title": "Little Red Corvette", "artist": "Prince", "last week": "9", "peak position": "8", "weeks on chart": "12", "detail": "up"}, "9": {"rank": "9", "title": "Solitaire", "artist": "Laura Branigan", "last week": "11", "peak position": "9", "weeks on chart": "9", "detail": "up"}, "10": {"rank": "10", "title": "Der Kommissar", "artist": "After The Fire", "last week": "5", "peak position": "5", "weeks on chart": "14", "detail": "down"}}}"""

DEFAULT_COLORS = ["#FFF", "#f41b1c", "#ffe400", "#00b5f8"]

list_options = [
    schema.Option(
        display = "U.S. Songs",
        value = "hot-100",
    ),
    schema.Option(
        display = "Global Songs",
        value = "billboard-global-200",
    ),
]

def main(config):
    # US, Global,
    selected_list = config.get("list", list_options[0].value)
    cache_name = "%s_%s" % (BILLBOARD_CACHED_TOP10_NAME, selected_list)

    top10_alive_key = secret.decrypt(BILLBOARD_SECRET_ENCRYPTED)

    print(top10_alive_key)

    top10_data = cache.get(cache_name)

    if top10_data == None:
        #print("Nothing in Cache, trying again")
        if top10_alive_key == None:
            #this should only be called for demos that Tidbyt displays on their websites
            top10_data = json.decode(BILLBOARD_SAMPLE_DATA)
        else:
            top10_data = get_top10_information(top10_alive_key, selected_list)

        top10_data["DateFetched"] = time.now().format("2006-01-02T15:04:05Z07:00")

        # We want to make <20 calls per month to the API
        # We have two different possible list types we can pull
        # Therefore, 10 calls a month max each to keep us under the limit
        # If we cache each call for 3 days we should be good
        #cache Time 3 Days x 24 hours x 60 minutes x 60 seconds = 259200 seconds
        cache.set(cache_name, json.encode(top10_data), ttl_seconds = 259200)
    else:
        #print("Fetched from cache")
        top10_data = json.decode(top10_data)

    fetched_time = None
    if ("DateFetched" in top10_data):
        fetched_time = time.parse_time(top10_data["DateFetched"])

    display_count = config.get("count", 10)

    row1 = "%s - Top %s" % (getListDisplayFromListValue(selected_list), display_count)
    row2 = getDisplayInfo(top10_data["content"]["1"])

    if (display_count == 10):
        row3 = getDisplayInfoMulti(top10_data["content"], 2, 5)
        row4 = getDisplayInfoMulti(top10_data["content"], 6, 10)
    else:
        row3 = getDisplayInfoMulti(top10_data["content"], 2, 3)
        row4 = getDisplayInfoMulti(top10_data["content"], 4, 5)

    if fetched_time != None:
        row4 = "%s -- %s" % (row4, fetched_time.format("Mon Jan 2 2006 15:04"))

    print(row1)
    print(row2)
    print(row3)
    print(row4)

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(src = base64.decode(BILLBOARD_ICON)),
                        render.Box(width = 1, height = 6, color = "#000000"),
                        render.Marquee(
                            width = 57,
                            height = 8,
                            child = render.Text(row1, font = "tb-8", color = config.get("color_1", DEFAULT_COLORS[0])),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 15,
                            child = render.Text(row2, font = "5x8", color = config.get("color_2", DEFAULT_COLORS[1])),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = len(row2) * 5,
                            child = render.Text(row3, font = "5x8", color = config.get("color_3", DEFAULT_COLORS[2])),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = (len(row2) + len(row3)) * 5,
                            child = render.Text(row4, font = "5x8", color = config.get("color_4", DEFAULT_COLORS[3])),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_top10_information(top10_alive_key, list):
    #print("get_top10_information")
    thetime = time.now().format("2006-01-02")
    url = "https://billboard-api2.p.rapidapi.com/%s" % list
    res = http.get(
        url = url,
        params = {"date": thetime, "range": "1-10"},
        headers = {
            "X-RapidAPI-Host": "billboard-api2.p.rapidapi.com",
            "X-RapidAPI-Key": top10_alive_key,
        },
    )

    if res.status_code == 200:
        return res.json()
    else:
        return None

def getMovementIndicator(this, last):
    movementIndicator = ""
    if (last != "" and last > 0):
        if this < last:
            movementIndicator = " (↑%s)" % (last - this)
        elif last < this:
            movementIndicator = " (↓%s)" % (this - last)

    return movementIndicator

def getListDisplayFromListValue(listValue):
    for item in list_options:
        if item.value == listValue:
            return item.display

    return ""

def getDisplayInfo(item):
    current = int(item["rank"])
    lastweek = item["last week"]
    if lastweek == "None":
        lastweek = 0
    else:
        lastweek = int(lastweek)

    display = "%s by %s #%s%s %s weeks on charts" % (item["title"], item["artist"], item["rank"], getMovementIndicator(current, lastweek), item["weeks on chart"])
    return display

def getDisplayInfoMulti(items, start, end):
    display = ""
    divider = " * "
    for i in range(10):
        if i + 1 >= start and i + 1 <= end:
            key = "%s" % (i + 1)
            item = items[key]
            current = int(item["rank"])
            lastweek = "" if item["last week"] == "None" else int(item["last week"])
            if i + 1 == end:
                divider = ""
            display = display + "%s by %s is #%s%s%s" % (item["title"], item["artist"], item["rank"], getMovementIndicator(current, lastweek), divider)

    return display

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow",
            value = "60",
        ),
        schema.Option(
            display = "Medium",
            value = "45",
        ),
        schema.Option(
            display = "Fast",
            value = "30",
        ),
    ]

    song_count_options = [
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "list",
                name = "Billboard List",
                desc = "",
                icon = "list",
                default = list_options[0].value,
                options = list_options,
            ),
            schema.Dropdown(
                id = "count",
                name = "Number of Songs",
                desc = "Number of songs to display",
                icon = "plusMinus",
                default = song_count_options[len(song_count_options) - 1].value,
                options = song_count_options,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Color(
                id = "color_1",
                name = "Color",
                desc = "Line 1 Color",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "color_2",
                name = "Color",
                desc = "Line 2 Color",
                icon = "brush",
                default = DEFAULT_COLORS[1],
            ),
            schema.Color(
                id = "color_3",
                name = "Color",
                desc = "Line 3 Color",
                icon = "brush",
                default = DEFAULT_COLORS[2],
            ),
            schema.Color(
                id = "color_4",
                name = "Color",
                desc = "Line 4 Color",
                icon = "brush",
                default = DEFAULT_COLORS[3],
            ),
        ],
    )
