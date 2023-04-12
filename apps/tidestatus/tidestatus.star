"""
Applet: TideStatus
Summary: Shows current ocean tide
Description: Shows the current tide height of the ocean based on the user location.
Author: k.wajdowicz
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

UP_ARROW = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAUCAYAAABWMrcvAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADaADAAQAAAABAAAAFAAAAADEOu1dAAAAcklEQVQ4Ee2QUQrAMAhDdfT+V3bLmCWL0sG+9jGhVOOLpbqZxXFKRIS5e9EhbJ0KAyJvZVqTQloXk07XGgNupg4ApPo0aQMwB/eniYGn/DTxFF0z18mNTLipL2UPLM5IQcGuTvb9n7qpK+1/6drOxxexA+GLKxZv85tuAAAAAElFTkSuQmCC
""")
DOWN_ARROW = base64.decode("""
/9j/4AAQSkZJRgABAQAASABIAAD/4QBYRXhpZgAATU0AKgAAAAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADaADAAQAAAABAAAAFAAAAAD/wAARCAAUAA0DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9sAQwABAQEBAQECAQECAwICAgMEAwMDAwQGBAQEBAQGBwYGBgYGBgcHBwcHBwcHCAgICAgICQkJCQkLCwsLCwsLCwsL/9sAQwECAgIDAwMFAwMFCwgGCAsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsL/90ABAAB/9oADAMBAAIRAxEAPwD8/P8Agyp/5Sm+Pv8AslWq/wDp30ev5Aq/0m/+DXT/AIJxfALwj8QoP+Cqv7G/je71H4e+OvBWq+ENV8HeIpba68ReGNfhvdLlkt57yxVLe7ikNrcTxu9rYTLazWjGBvNZk/li/wCCgn/BP39gX/gkX478P/suftM6j4q+N/xduNKg1vxR/wAIP4h07wxonh77ZHH5Gnf6XpWtXd1c7lmnaWaOwzay2rrBmRtoB//Q/nd/4N+v+CgXx9/YL/ap8dax8GXtLy0134a+Nr++0vVDcyafPdeFtCv9dsJngguIA0sdxZeTvYllt7i4SMo0u9fxB8WeLPFXj3xVqfjrx1qd3rWt61dzX+oahfzPc3V3dXLmSWaaWQs8ksjsXd3JZmJJJJr7f/4Jp/8AJxXiP/slXxY/9QjXa+AKAP/Z
""")

def main(config):
    stationId = config.get("station")

    today_data = get_tide_data(stationId, determine_date(), "10")

    points = get_data_points(today_data)
    max = 0
    min = 0
    for p in points:
        if p[1] > max:
            max = p[1]
        if p[1] < min:
            min = p[1]

    current_time = calc_hours(time.now().format("2006-01-02T15:04"))

    return render.Root(
        delay = 100,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Marquee(
                   width=64,
                    align="center",
                   child=render.Text(get_current_state(today_data)),
                ),
                # render.Text(get_current_state(today_data)),
                render.Row(
                    children = [
                        render.Box(
                            width=1,
                            color="#000",
                        ),
                        render.Stack(
                            children=[
                                render.Plot(
                                    data=points,
                                    width=62,
                                    height=26,
                                    color="#368BC1",
                                    fill_color="#123456",
                                    color_inverted="#800080",
                                    fill_color_inverted="#550A35",
                                    x_lim=(0, 24),
                                    y_lim=(min - 1, max + 1),
                                    fill=True,
                                ),
                                render.Plot(
                                    data=[(current_time, min), (current_time, max)],
                                    width=62,
                                    height=26,
                                    color="#FFF",
                                    color_inverted="#FFF",
                                    x_lim=(0, 24),
                                    y_lim=(min - 1, max + 1),
                                    fill=True,
                                ),
                            ]
                        ),
                        render.Box(
                            width=1,
                            color="#000",
                        ),
                        render.Column(
                            children = [
                                render.Box(
                                    height=3,
                                    color="#000",
                                ),
                                #render.Image(src=get_current_state(today_data)),
                            ]
                        ),
                        render.Box(
                            width=1,
                            color="#000",
                        ),
                    ]
                )
            ]
        )
    )

def get_schema():
    options = [
        schema.Option(
            display="San Francisco, CA",
            value="9414290"
        ),
        schema.Option(
            display="LONG BEACH, NEW YORK, NY",
            value="8516663"
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                 id = "station",
                 name = "Station",
                 desc = "NOAA Station",
                 icon = "globe",
                 default = options[0].value,
                 options = options,
             ),
        ],
    )

def get_tide_data(stationId, date, interval):
    url = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?begin_date=%s&end_date=%s&station=%s&product=predictions&datum=MLLW&time_zone=lst_ldt&interval=%s&units=english&application=DataAPI_Sample&format=json" % (date, date, stationId, interval)

    data = cache.get("%s-%s" % (stationId, date))
    if data != None:
        data = json.decode(data)
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling tide API: %s" % url)
        response = http.get(url)
        if response.status_code != 200:
            print("tide request failed with status %d" % response.status_code)
            return None
        data = response.json()
        cache.set("%s-%s" % (stationId, date), response.body(), ttl_seconds = 3600)

    return data

def determine_date():
    return time.now().format("20060102")

def get_data_points(today):
    data_points = []

    for p in today["predictions"]:
        time = p["t"][11:].split(":")
        hours = int(time[0]) + int(time[1]) / 60
        data_points.append((hours, float(p["v"])))

    return data_points

def get_current_state(data):
    current = None
    next = None
    for p in data["predictions"]:
        if p["t"][11:] < time.now().format("2006-01-02T15:04")[11:]:
            current = p["v"]
        else:
            if next == None:
                next = p["v"]

    if current > next:
        return "Dropping"
    else:
        return "Rising"

def calc_hours(timestamp):
    time = timestamp[11:].split(":")
    return int(time[0]) + int(time[1]) / 60

def get_station_name(id):
    url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/%s.json" % id
    name = cache.get(id)
    if name != None:
        print("Hit! Displaying cached data.")
        return name
    else:
        print("Miss! Calling station API: %s" % url)
        response = http.get(url)
        if response.status_code != 200:
            print("station request failed with status %d" % response.status_code)
            return None
        cache.set(id, response.json()["stations"][0]["name"], ttl_seconds=3600)
        return response.json()["stations"][0]["name"]
