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

BILLBOARD_API_SECRET_KEY = "AV6+xWcEE5IuD+5cFvv5rCrVUi1xz8BdNKqeIMFXjoc86p8wGGQYP7+TdhlXTaHGAF8MDUel+AnqHVFzL+yMyXboV/qVCyKtV8WjoubvrzpKD4Gh14hQ233Jn0Sef6lUOQuiRfRS+2mh5ja4O0BHns65UWtfk4GHFgaTsza4w/d/EKocbPdRTOLi0FKlcXQEI0w0uZthE2k="
BILLBOARD_CACHED_TOP10_NAME = "BillboardCache"
BILLBOARD_ICON = """
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAICAIAAABVpBlvAAABVmlDQ1BJQ0MgcHJvZmlsZQAAKJFtkL8vxGAYx7+lcgnCDcTAUIkBOSJ1A7ZzgwhDnZ8VS69XPdKrN20Fs9UmMUot/gJRI4vYJYh/gMkiaSRc6nnv0Ds8b548nzz5vk+++QINosaYJQIo2Z6Tm5qUVtRVKfEMAd1oxwS6NN1lGUWZJQm+Z32Fd6Smuh3it9bUt3P7etO3VNnvnAkO/+rrqrlguDrND+pBnTkeIPQTKzse47xL3OGQKeIDzmaVfc75Kp9VNAu5LPENcVIvagXiB+JUvmZv1nDJ2ta/PHD3rYa9OE+zjboHCjKQkcYY5rBE2fyvTVe0WWyBYQ8ONmCiCA8S/Wb0LBjE07ChYxgpYhkj/C7P+Hd28Y7tA+M8t5d4p1nABWWfPI53fU9ktxe4OmGao/0kKoSiuz4qV7klAJqOouh1GUgMAOX7KHoPoqh8CjQ+ApfhJ3LYYwruNH3OAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH6AICFRMwu9G4AQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAACESURBVAjXY0xLTZWQlFy0YCEDDDCeOXPGyMhISUERLsQCoZpbWljZWGfNnHXv7l2GM2fO/IOB169fKykoMkFUFRUVbdu2TVhYODYuFiqkpaUlICDAwMDw89cvhjNnzvz9+/fv37///v27d/eugpw8Y1pqqriExKtXr2SkZebOmcPAwAAAlwg4Pp81GiUAAAAASUVORK5CYII=
"""
BILLBOARD_SAMPLE_DATA = """{"info": {"category": "Billboard", "chart": "HOT 100", "date": "2024-02-03", "source": "Billboard-API"}, "content": {"1": {"title": "Lovin On Me", "artist": "Jack Harlow", "weeks at no.1": "1", "last week": "2", "peak position": "1", "weeks on chart": "11", "detail": "up", "rank": "1"}, "3": {"weeks on chart": "19", "detail": "up", "rank": "3", "title": "Greedy", "artist": "Tate McRae", "last week": "4", "peak position": "3"}, "8": {"title": "Paint The Town Red", "artist": "Doja Cat", "last week": "7", "peak position": "1", "weeks on chart": "25", "detail": "down", "rank": "8"}, "10": {"peak position": "5", "weeks on chart": "2", "detail": "down", "rank": "10", "title": "Redrum", "artist": "21 Savage", "last week": "5"}, "2": {"weeks on chart": "38", "detail": "up", "rank": "2", "title": "Cruel Summer", "artist": "Taylor Swift", "last week": "3", "peak position": "1"}, "4": {"last week": "8", "peak position": "4", "weeks on chart": "24", "detail": "up", "rank": "4", "title": "Lose Control", "artist": "Teddy Swims"}, "5": {"detail": "up", "rank": "5", "title": "I Remember Everything", "artist": "Zach Bryan Featuring Kacey Musgraves", "last week": "6", "peak position": "1", "weeks on chart": "22"}, "6": {"weeks on chart": "2", "detail": "down", "rank": "6", "title": "Yes, And?", "artist": "Ariana Grande", "last week": "1", "peak position": "1"}, "7": {"detail": "up", "rank": "7", "title": "Agora Hills", "artist": "Doja Cat", "last week": "11", "peak position": "7", "weeks on chart": "18"}, "9": {"peak position": "2", "weeks on chart": "58", "detail": "same", "rank": "9", "title": "Snooze", "artist": "SZA", "last week": "9"}}}"""

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
    top10_data = cache.get(cache_name)

    if top10_data == None:
        #print("Fetching new data from API")
        top10_alive_key = secret.decrypt(BILLBOARD_API_SECRET_KEY) or "5927f78f43msh6f021523896b0ffp1db822jsn1d1a0b0e2fd4"
        top10_data = get_top10_information(top10_alive_key, selected_list)

        #this should only be called for demos that Tidbyt displays on their websites
        if top10_data == None:
            top10_data = json.decode(BILLBOARD_SAMPLE_DATA)

        # Add the fetch date to the dataset
        top10_data["DateFetched"] = time.now().format("2006-01-02T15:04:05Z07:00")

        # We want to make <20 calls per month to the API
        # We have three different possible list types we can pull
        # Therefore, 6 calls a month max each to keep us under the limit
        # If we cache each call for 5 days we should be good

        #cache Time 5 Days x 24 hours x 60 minutes x 60 seconds = 432000 seconds
        cache.set(cache_name, json.encode(top10_data), ttl_seconds = 432000)
    else:
        #print("Getting from cache")
        top10_data = json.decode(top10_data)

    row1 = "%s - Top 10" % getListDisplayFromListValue(selected_list)
    row2 = getDisplayInfo(top10_data["content"]["1"])
    row3 = getDisplayInfoMulti(top10_data["content"], 2, 5)
    row4 = getDisplayInfoMulti(top10_data["content"], 6, 10)

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
    url = "https://billboard-api2.p.rapidapi.com/%s" % list
    res = http.get(
        url = url,
        params = {"date": time.now().format("2006-01-02"), "range": "1-10"},
        headers = {
            "X-RapidAPI-Host": "billboard-api2.p.rapidapi.com",
            "X-RapidAPI-Key": top10_alive_key,
        },
    )

    if res.status_code == 200:
        print("Received Data from API")
        return res.json()
    else:
        return None

def getMovementIndicator(this, last):
    movementIndicator = ""
    if (last != ""):
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
    lastweek = int(item["last week"])
    display = "#%s%s \"%s\" by %s %s weeks on charts" % (item["rank"], getMovementIndicator(current, lastweek), item["title"], item["artist"], item["weeks on chart"])
    return display

def getDisplayInfoMulti(items, start, end):
    display = ""
    for i in range(10):
        if i + 1 >= start and i + 1 <= end:
            key = "%s" % (i + 1)
            item = items[key]
            print(item)
            current = int(item["rank"])
            print(current)
            print(item["last week"] == None )
            lastweek = "" if item["last week"] == "None" else int(item["last week"])
            display = display + "#%s%s \"%s\" by %s " % (item["rank"], getMovementIndicator(current, lastweek), item["title"], item["artist"])

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
