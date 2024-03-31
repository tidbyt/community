"""
Applet: Buienradar
Summary: Buienradar (BE/NL)
Description: Shows the rain radar of Belgium or The Netherlands.
Author: PMK (@pmk)
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_COUNTRY = "NL"
DEFAULT_DISPLAYING = "radar"
DEFAULT_LOCATION = "{\"value\": \"2757783\"}"

COLOR_DIMMED = "#fff6"
DAYS_SHORT = ["Zo", "Ma", "Di", "Wo", "Do", "Vr", "Za"]

def day_of_week(date):
    num = humanize.day_of_week(time.parse_time(date + "Z"))
    return DAYS_SHORT[num]

def is_outside_benl(location):
    lat = float(location["lat"])
    lng = float(location["lng"])
    return lat <= 49.49 or lat >= 53.57 or lng <= 2.57 or lng >= 7.20

def convert_locations_to_options(locations):
    filtered_locations = []
    for location in locations:
        if (location["countrycode"] != "BE" or location["countrycode"] != "NL") and ("hidefromsearch" in location and location["hidefromsearch"] == "False"):
            filtered_locations.append(location)

    options = []
    for option in filtered_locations:
        options.append(
            schema.Option(
                display = "{}, {}".format(option["name"], option["country"]),
                value = "{}".format(int(option["id"])),
            ),
        )
    return options

def location_handler(place):
    location = json.decode(place)
    if is_outside_benl(location):
        return [
            schema.Option(
                display = "Locatie is buiten België en Nederland",
                value = "error",
            ),
        ]

    data = get_locations(humanize.url_encode(location.get("locality")))
    return convert_locations_to_options(data) or []

def get_data(url, ttl_seconds):
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Buienradar request failed with status %d @ %s", response.status_code, url)
    return response

def get_locations(query, ttl_seconds = 60 * 60):
    url = "https://location.buienradar.nl/1.1/location/search?query={}".format(query)
    response = get_data(url, ttl_seconds)
    return response.json()

def get_forecast(location_id, ttl_seconds = 60 * 60):
    url = "https://forecast.buienradar.nl/2.0/forecast/{}".format(location_id)
    response = get_data(url, ttl_seconds)
    return response.json()

def get_radar(country = DEFAULT_COUNTRY, ttl_seconds = 60 * 15):
    url = "https://image.buienradar.nl/2.0/image/animation/RadarMapRainWebMercator{}?width=64&height=64&renderBackground=True&renderBranding=False&renderText=False".format(country)
    response = get_data(url, ttl_seconds)
    return response.body()

def get_weather_news_page(ttl_seconds = 60 * 15):
    url = "https://www.buienradar.nl/nederland/weerbericht/weerbericht#readarea"
    response = get_data(url, ttl_seconds)
    return response.body()

def get_rain_data(lat, lon, ttl_seconds = 60 * 5):
    # url = "https://graphdata.buienradar.nl/2.0/forecast/geo/RainEU3Hour?lat={}&lon={}".format(lat, lon)
    url = "https://graphdata.buienradar.nl/2.0/forecast/geo/RainHistoryForecast?lat={}&lon={}".format(lat, lon)
    response = get_data(url, ttl_seconds)
    return response.json()

def render_radar(country):
    radar = get_radar(country)
    radar_image = render.Image(
        src = radar,
        width = 64,
        height = 64,
    )

    return render.Root(
        delay = radar_image.delay,
        child = render.Stack(
            children = [
                render.Box(
                    child = radar_image,
                ),
                render.Padding(
                    pad = (1, 1, 1, 1),
                    child = render.WrappedText(
                        width = 24,
                        linespacing = 1,
                        content = "Buien- radar",
                        color = "#fff",
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
            ],
        ),
    )

def render_today(location):
    forecast = get_forecast(location)
    today = forecast["days"][0]

    page = get_weather_news_page()
    message = html(page).find("#readarea > p:first-child").text().strip()

    return render.Root(
        show_full_animation = True,
        delay = 33,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 3, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(
                                src = get_icon(today["iconcode"]),
                                width = 19,
                                height = 19,
                            ),
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Text(
                                        content = "{}°".format(int(today["maxtemperature"])),
                                        font = "tb-8",
                                        color = "#ff8164",
                                        offset = -1,
                                    ),
                                    render.Text(
                                        content = "{}°".format(int(today["mintemperature"])),
                                        font = "tb-8",
                                        color = "#59bfff",
                                        offset = -1,
                                    ),
                                ],
                            ),
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Row(
                                        cross_align = "center",
                                        children = [
                                            render.Text(
                                                content = "{}".format(int(today["beaufort"])),
                                                font = "tom-thumb",
                                                color = "#00ffc0",
                                            ),
                                            render.Image(
                                                src = get_wind_icon(today["winddirection"]),
                                                width = 11,
                                                height = 11,
                                            ),
                                        ],
                                    ),
                                    render.Text(
                                        content = "{}%".format(int(today["humidity"])),
                                        font = "tom-thumb",
                                        color = "#ff00cc",
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (0, 26, 0, 0),
                    child = render.Marquee(
                        child = render.Text(
                            content = message,
                            font = "tom-thumb",
                            color = "#bbb",
                        ),
                        width = 64,
                        offset_start = 64,
                        offset_end = 64,
                    ),
                ),
            ],
        ),
    )

def render_forecast(location):
    forecast = get_forecast(location)

    return render.Root(
        child = render.Row(
            children = [
                render_weather_column(forecast["days"][0]),
                animation.Transformation(
                    child = render.Row(
                        children = [render_weather_column(forecast["days"][i + 1]) for i in range(4)],
                    ),
                    duration = 60,
                    delay = 60,
                    origin = animation.Origin(0, 0),
                    height = 32,
                    width = 83,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(-41, 0)],
                            curve = "ease_in_out",
                        ),
                    ],
                ),
            ],
        ),
    )

def render_rain_graph(location):
    forecast = get_forecast(location)
    rain_data = get_rain_data(lat = forecast["location"]["lat"], lon = forecast["location"]["lon"])

    rain = []
    for idx, d in enumerate(rain_data["forecasts"]):
        rain.append((idx, d["value"]))

    return render.Root(
        child = render.Stack(
            children = [
                # Graph
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Plot(
                        width = 62,
                        height = 24,
                        color = rain_data["color"],
                        fill = True,
                        fill_color = rain_data["color"],
                        y_lim = (0, 100),
                        data = rain,
                    ),
                ),
                # Grid line vertical left
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 24,
                        color = "#666",
                    ),
                ),
                # Grid line vertical middle-left
                render.Padding(
                    pad = (21, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 24,
                        color = "#fff6",
                    ),
                ),
                # Grid line vertical middle-right
                render.Padding(
                    pad = (42, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 24,
                        color = "#fff6",
                    ),
                ),
                # Grid line vertical right
                render.Padding(
                    pad = (63, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 24,
                        color = "#666",
                    ),
                ),
                # Grid line horizontal middle
                render.Padding(
                    pad = (1, 12, 0, 0),
                    child = render.Box(
                        width = 62,
                        height = 1,
                        color = "#fff6",
                    ),
                ),
                # Grid line horizontal top
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        width = 64,
                        height = 1,
                        color = "#666",
                    ),
                ),
                # Grid line horizontal bottom
                render.Padding(
                    pad = (0, 23, 0, 0),
                    child = render.Box(
                        width = 64,
                        height = 1,
                        color = "#666",
                    ),
                ),
                # Now line
                render.Padding(
                    pad = (8, 6, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 18,
                        color = "#e88504",
                    ),
                ),
                # Now text
                render.Padding(
                    pad = (8, 0, 0, 0),
                    child = render.Text(
                        content = "nu",
                        font = "tom-thumb",
                        color = "#e88504",
                    ),
                ),
                # Time text bottom
                render.Padding(
                    pad = (0, 27, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Text(
                                content = "{}".format(humanize.time_format("HH:mm", time.parse_time(rain_data["forecasts"][0]["datetime"] + "Z"))),
                                font = "tom-thumb",
                                color = "#666",
                            ),
                            render.Text(
                                content = "t/m",
                                font = "tom-thumb",
                                color = "#666",
                            ),
                            render.Text(
                                content = "{}".format(humanize.time_format("HH:mm", time.parse_time(rain_data["forecasts"][len(rain_data["forecasts"]) - 1]["datetime"] + "Z"))),
                                font = "tom-thumb",
                                color = "#666",
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_weather_column(data):
    border = render.Box(
        width = 1,
        height = 32,
        color = COLOR_DIMMED,
    )

    column = render.Box(
        width = 20,
        height = 32,
        color = "#000",
        child = render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Column(
                expanded = True,
                main_align = "center",
                children = [
                    render.Image(
                        src = get_icon(data["iconcode"]),
                        width = 19,
                        height = 19,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(
                                content = "{}".format(day_of_week(data["date"])),
                                font = "tb-8",
                                color = "#fff",
                                offset = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(
                                content = "{}".format(int(data["maxtemperature"])),
                                font = "tom-thumb",
                                color = "#ff8164",
                            ),
                            render.Padding(
                                pad = (0, 0, 1, 0),
                                child = render.Text(
                                    content = "|",
                                    font = "tb-8",
                                    color = COLOR_DIMMED,
                                    offset = 2,
                                ),
                            ),
                            render.Text(
                                content = "{}".format(int(data["mintemperature"])),
                                font = "tom-thumb",
                                color = "#59bfff",
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

    return render.Row(
        children = [column, border],
    )

def main(config):
    country = config.str("country", DEFAULT_COUNTRY)
    displaying = config.str("displaying", DEFAULT_DISPLAYING)
    location_id = config.get("location", DEFAULT_LOCATION)
    location = int(json.decode(location_id)["value"])

    if displaying == "radar":
        return render_radar(country)
    elif displaying == "today":
        return render_today(location)
    elif displaying == "forecast":
        return render_forecast(location)
    elif displaying == "rain_graph":
        return render_rain_graph(location)
    else:
        return []

def get_schema():
    options_countries = [
        schema.Option(
            display = "Nederland",
            value = "NL",
        ),
        schema.Option(
            display = "België",
            value = "BE",
        ),
    ]

    options_displaying = [
        schema.Option(
            display = "Buienradar map",
            value = "radar",
        ),
        schema.Option(
            display = "Weerbericht van vandaag",
            value = "today",
        ),
        schema.Option(
            display = "Verwachting komende dagen",
            value = "forecast",
        ),
        schema.Option(
            display = "Verwachte neerslag",
            value = "rain_graph",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "country",
                name = "Land",
                desc = "Welk land weergegeven moet worden.",
                icon = "globe",
                default = DEFAULT_COUNTRY,
                options = options_countries,
            ),
            schema.LocationBased(
                id = "location",
                name = "Locatie",
                desc = "Locatie weerbericht.",
                icon = "locationDot",
                handler = location_handler,
            ),
            schema.Dropdown(
                id = "displaying",
                name = "Weergave",
                desc = "Wat weer te geven.",
                icon = "sun",
                default = DEFAULT_DISPLAYING,
                options = options_displaying,
            ),
        ],
    )

def get_icon(icon_code):
    if icon_code == "ww":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAgFJREFUeNqM1E9IVEEcwPHfykbRP0jCLLtoFGgYEpGUikRkIBRERIdAWEIWVKhDINIhEqJTdUk7RARFpRKdFuqwLf2jlaLSIg0jqIMaS10igsV1p+/wfsuOu+/tOvBh570385uZ3/u9DRljpEyrRwMWMI2vgSNtsBLa8Ri/kcIj7AsaXyrQZeO1DBJ4ZvKtaznB9uIGPuikMWx0nm9BXJ8dKBXsjLPyFEYCdrwKf/EuKNhRZyfVZfJo3dPxSbS4wTrwA7N+E+8iVnx/FwbxR4N25ILlEn21MNAJ7EYjzvvvsEYDzqC1gupIa5WsdkvmPr6jGe14jovFlTWLm9iOYzZYHF9wCmtzo7bqRVakh2rds43+jH+p1ujvnA32Cmd17lM0YaUO6MaQXdlu4drSIBvQg5MYxUP3/BGnNFIfjalrpVCjxnxDFXlb54y1RZvWsa+x3t4POyvdRgKnsemFSEulSMymgO0nP4lcoT+MNfisaU3iFhZtgJDfhz4AJptacv7P+8Iv3BFpo/sT19GPycJ5Fe7FLxzCe5GRWi/IOAM650X6NNAbHNYTHCkMFm7TzoLWhn1rK0Tecj1B91yKNSLeSxD9C9oPbsuTomA7fd511stPLw5yzOiO/KNLmjP75jOF80LR4D/HQdi1jttsv5TyLVzi2QNbb/b4m2V57b8AAwC7CDvBDo350QAAAABJRU5ErkJggg==
""")
    if icon_code == "vv":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAVFJREFUeNrM1M8rhEEcx/GdtYq4yMGqjTgrJ6UccOG+yp+wN9yEHJBfSZz9C1LK0W1rc5Wj8jslkk17ITTeU5/haTOPte3B1Kv2mfl+vzvP9H3GWGsTtRrJRA1HqoKYYXTDvcI58sFI95oBBrN4sN/jHtOhnFChVhypwAVWsY5rzR2gPq5YHXLI41lJM0hFYlyBJa2thIplcKygJ5xhMeYI/K47y4u5sylocUr/nowp5IwrvoiJaLERLWz9UiAqjW1cKXfHF9vQROYPxTx3nvvKH3BN26QueamiT98xqd9ZV6ygh7EqG//t6wNge8141Fb7A6+zjN7A2q5yR/1EH0qaPMQaGtGl5w817Lzi27CJU+XslTdtjybdeEU7GnAS+ZyykVirDSz4VjI/XEFpGNzpeQ5DOuwcbjXfgSJKPtFUcJ8NKqkFl7gJBZp/ezl+CjAARliQVBqkW2kAAAAASUVORK5CYII=
""")
    if icon_code == "uu":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAWhJREFUeNqs1D0sBEEUwPGdCzmRyLnoiEJEIzS+TkTCtbjiKBRUCoXiSoVcIxrRKZyESqEQpW4jUZArfLYXBRGJj0JzR6GQ9R95K+Oyt2fZSX7J5M3M2zc7s6scx7HCajV/XBdDD+pxjOJ/kvUhiUYU3GSW3mZAK87PNuSOVausGzNogQ2FLA4xigzy37N9Ktgwnv5i9PPolH6HuaY8gZ6UxZVMXkOrjA3gAK+YQAk7lZItGk9/w1KFiu9wgjQ+YGMVk3qwFnOSJIc2xH22Py9zd3FhFLCuB6dQxNkvT7NLL8S9JDlCwt1mToILAa9IAx6x78YiHOi7HGw84MUtYQsp+SK+KhvBNZ6gPCqIyXv0qs6Wa1Nnnma/bPUZs8b9GcQeLjEtsai8o01Zk/G6GuO4lQkPEhszTmtbYkkjtux3aS351nql34RzSZ4ytj2M9vK1qsr/rBkJRHGDU7/JKsyfY8QKsX0KMADqnMjNM/x5rQAAAABJRU5ErkJggg==
""")
    if icon_code == "tt":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYRJREFUeNqs1M8rhEEYwHG71m75tdqLiFJ7pLY2Dg5EsYd1cXFQyoWLP4DiyEEJB0q5OFmU9kjJ2Ul+FXKirNQe0G5E5PUdPW9er5lXWzv1ad99Zp7nnXfemddnWVZJsZr/n/4+HOAZWaQQM45WMzOYt37aKW7k+h0Duhx3IIZJ7EtiGlWO/jZcSV+7V7FF63dLG2ZcL/17umIRzMiAbTQhjHKPJdiQ8VuodRabM93JQz8uJC+PDruYvbC9BRSzxSX3HEkVyEqg2ZCgHtfnUXBK8lNqnx3JLklqdk4EK4h67MU3+a1QlRM4kerdjjv24BI5XGNQM6tKZOTphuxgC+6l4CGm0Yhdial1jTqKtGITL9I/7N5ndViXzkf5P4YF2TpqzKhs1i4Zl5E3qz0BSjVq5Npe+BDW8IpbjLtOxjfdQc/hCSNYcixyECE04AF5d2LA8IYmMCvXcSSwgzDKcFzIV6MTH7IuyxLzI4CgPPafPNPM7rCKUpxJ7FMYm6+YX9ovAQYAWckHK4D1LLIAAAAASUVORK5CYII=
""")
    if icon_code == "ss":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAkpJREFUeNqElEtIVGEYht8ZJygTBVFGXAzJMF2gSCg1sow2tYgWERZEENHFRTcMjKSIFkUto8VsGhCqXZCJFBUWCRVFt0VEZkQRIgWRFFnGVKfnn/nOzDjMGX94zvkv3/ee/7twQp7nqcyYDe2QgF9wH94FWjuxACpgP3zw8qMfmoN8goSq4KEJjMNFuFkgun0msQhshaswZk49RQ4xeGVn7UFiYbhnRhMmdjzg1jGzGywlloA+MzhRlLOgNAyY/SNYVCjmCyXLOBezAlLml4Y1vtgn21zuG0/CZuiGeE4gVkq0Cf7CC+gIF3aJP1kN7uAzfMwdu9kc2FXYWe/hAjTDBuczZAc73OM5VEjVddKWGqmhclpXLoFrELL+zQzf5Ke76lJrh0y5XYhtnnesK5uI1kuZcDohTu+1dcBaasN72PmuM79bsMyPvRHOu7Kfod86mSB2F1ENZc5roOUsQl4W0dCjsiJ8t9zJz9k4HOwlMbel+VGpj3USHoxIC6SmemnqgNn+k6K7petu3g2NljtF7vAgN5mjpyRyIclIS60sD+O1cp/LhUZOka/KfCUSR6Tefso0wB1yGQ2fNvmXgFASgblMq2dR1K9Sj5Rq4FZ7lQtC86T0KsTfSoemlSfUlf8Fud/NE+CLWjwsjb6Wjkr1hBltkapOsh+HG7AxGy6x6E/+ZgXCU1b737Dpm/Qsu/3ljVT3w4RSrp+yQsXuxavs2EaIjyekK7au5TuuMc/BnnJ/0kiJvfVj0uTOzHTQlafW0npZM4z/AgwAfmd0HqqvitcAAAAASUVORK5CYII=
""")
    if icon_code == "qq":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhFJREFUeNqM1E1IFGEcx/H/rhOGBZZIKnWoFAvMQAnCw6Js1AZ72EOEBF0rvNSlYEMQhbBLlpFGBwVB7ZXohZBeIG8FbVuRhxYi6O3isiFi9ILp9H3Y/7DjOjP6wIeZeeaZ3zzPM888Idu2ZYWyF434jSm8921pwgIkkLLz5Q+eI+7XPijosobMYgRjdqGcWU3YPozigz40gHWu+5WY0HvRoLBebTSHNAZ9emxpb996hZXgiAaNo3yFeRTXkDPY7w4zQ/uCb14PMmZ5tLy+CUl819CYE3ZCK64VBx1GMxrR6d3DKuTwEa1hVseirpIN7iVzHZ91kbUihWPILl1Z07iFOuw2YW/wEoewxWllTtaLhHhTcl4kUs91DpHlS7UBC/hhwtI4CUs7EMNWbXgK51FNoFRhcyFkBzq141cwaemN1ziAm3hsKjaK1BMQ5/QdXmi7uhKRPZp5Qese4LTpXajo3yRDEtg+yL/4FDX5abiDJNo/0fNnIgc5b8ErTDgPW0Xjn8HIWaaLP3pum0gXvTtO3Sad+xjzco7jE7WkhN0X/WjLf5H7BP0l6DaX/9CBNeguE+np99k0LOfrLOpE7My/YZggRipX8RA/cc80WUv4V5+wcIN+W7NhVRSCb3AwqyGKUozqPpYt10+e8QoL2BR34S4u4SKO6pClFn1ewwwIG8IvzOtayzk3ynTLLS7/BRgAwNcIdksnIggAAAAASUVORK5CYII=
""")
    if icon_code == "rr":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAATZJREFUeNrk1LtKA0EUxvGsRBG8FGIjBsUiRhFEOyWNdoKSvIGV5A2ChW1AsLIQH0AstLCws5CUoiBYCFZCbEVjBGPIjaz/gXPkoLkpwcaBHyxnZ7497Myu5/t+oFOjK9DB8edhPZjEuKmFcYwbbGkx2EbYCqJ4wxHusYYYenH5OdNtQAOzuPW/j3OU5foFU7qmXsg8kjI5jzhGZNGO1DM4w5Nda0MiuDId5DBd52GbqOFAOtvHKsI6IYRXCUlgDsNNXsE7CtKhjl29eSiFaJMAK4UHWVPBBsbsky7aDFIDEurGgn1nbnfSPwxTzzhxnemhvcYyBn9x8LvdCUNN0xel3TvMoL+FPgxhT9YtwbPtxs3OZKX9bAOPKMrcbc3wvvyCRrGOCZRafNNVpHGqRe9//M8+BBgA9QZUewZHVh4AAAAASUVORK5CYII=
""")
    if icon_code == "pp":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARNJREFUeNpi/P//PwO1ABMDFQFVDWMhIC8FxIlA7A7Ef4F4HRAvBuIPWFWDwgwPzgXih/8R4DoQR+NSj8sQaSBeAzXgNBAXA3EdED+GitUSY1gmEN9AckkVFk0LoHLO+AybAVV0G4hnAXEeHu9/h6oTwWZYGtSgbgJhCMNToOr/AnE+umEgW14RaRAIiwOxPxCfhRoahmwYyIY9JBgGw4xA/BKIb4L4sET7BIg1yEinoLx4B4hVkdNZKZ7Yw4eloPqOgfiM0IzOCMTzgDgBiPcB8TYg/oMnh/wCYiEgrgZiViC2BOIT6DbVAPG7/8SDS0DsANOPbvMKIBYAYjNoXvyHw2XM0PBaD8QHYYKMI6M8AwgwAABQTOIMFVI+AAAAAElFTkSuQmCC
""")
    if icon_code == "nn":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARVJREFUeNpi/P//PwO1ABMDFQELEWqMgDgaiFWA+CsQVwLxQ6wqQd7Eg+WB+MR/VGCJSz0+g2SA+D7UgPdQeg0QC5Jj2ByoAQVAvAmIfwGxED6f4JLgAuLvQHwXyj8PxB8IBAnO2OQFYg4gvgvlPwdifiA2xBtVOGxhAeKnSK6xgnr5HhC7ArEsqWGWDTVgBpQfjRSjH4G4Fl0PcjoTA2JvIOYC4m9Qb/0F4nQg1gbiNUB8HYg1gZgPiCOA+B6U/QeIDyCbXPafMrCSESlvggLdCYgZoS4iFrADsSQQHwcZpghkyEAl3pKYHdmA+DY0m4Ej4CyF3jsNxIywCGiGph9QQP4iwVWMUJcdhQsM2vKMqoYBBBgA5QchzsCO0ZUAAAAASUVORK5CYII=
""")
    if icon_code == "oo":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAUtJREFUeNrM1L8rhVEcx/F7XAYZ/EoMMim/iq6BwWSy25VBFsW1+R/uQhZlUAwWq0VkkeEyULckix8xeer6XajjffR5OHTvdR/d4tSrnuf8/D7nfJ9jrLWxUpWyWAnLn09WhVmc4ACtHy1uzyKox779LEeoCdvLC0RQiwkMwGBDz21IIYlRZH+KrAs3Wn0PW3jV+xx69dzpj/MnqMS4BrpyhYTXXo00njGEAKu5JmtCRpOcYQfdOSKuwy2WMKxor7GNKdehH5uaaLCIQ0ip77q2IPyKpGtcUcVkkSfagGmcatyatuD9MwNVNv8iTVyZD+tc0p7rYNsjJm+ANPr81BjDHQ4jRtaoyBbDOqNbYwTLuMQCLgr8bk9owYwSO6Hf6kueuZM81mqPuMdDHlZ9e/xozbf7rEO/TIVbJ89exfGCXWT8BvNvL8c3AQYAlBRZu9NjtdUAAAAASUVORK5CYII=
""")
    if icon_code == "mm":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZlJREFUeNqs1M0rRFEYx/F7vSbEwsIIkyRZTGRLeS1KGlZYTFZSEll4K3+ArGwUK+UPQBZWLJRSipJYyCSkjMzCxkteju/pPre5ce9taE59ujPnPs9vzr1zOqZSykjVyEiipgZB6F+9wNV/w/LQjpCEHeAeL67V+jE99CCufo87NLj1/JzIksIxaXxAGHnIxyBe8IFqv7CwNNvjHmUuKwjJ/T2vsE4piCGCVpT7vIJVqZ9CjjOsC7d4QsAnwKkb1xJ4iSo7bFMmJ5IM0kwUold6z9GibxzIRJtb4yga5eoRPCf9G2nsjqjsko6f2+YLO6jDGabd9+KhXEt02DJOMYl6Z5W+WYR3lOLRPWxErnu6fh8RWcgRFjGAXHt1enyiIBFQjEFsIYwVLDmfvRLbjn1Wq+ebMKzUeL9SzTOJ2j5H3YKdYbqcGkFZVZR39HZjGL2saP3VMGZZ5fyaVZODCsQRsxtNryOIEGMI5eyedOv9FZ3QPMbnvr+eGsd4Rqa1oiPEs/ke+M95lo906w/Y9TvDnMNM5Un7LcAAcQgryByHp3UAAAAASUVORK5CYII=
""")
    if icon_code == "ll":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhFJREFUeNqM1E1IFGEcx/H/rhOGBZZIKnWoFAvMQAnCw6Js1AZ72EOEBF0rvNSlYEMQhbBLlpFGBwVB7ZXohZBeIG8FbVuRhxYi6O3isiFi9ILp9H3Y/7DjOjP6wIeZeeaZ3zzPM888Idu2ZYWyF434jSm8921pwgIkkLLz5Q+eI+7XPijosobMYgRjdqGcWU3YPozigz40gHWu+5WY0HvRoLBebTSHNAZ9emxpb996hZXgiAaNo3yFeRTXkDPY7w4zQ/uCb14PMmZ5tLy+CUl819CYE3ZCK64VBx1GMxrR6d3DKuTwEa1hVseirpIN7iVzHZ91kbUihWPILl1Z07iFOuw2YW/wEoewxWllTtaLhHhTcl4kUs91DpHlS7UBC/hhwtI4CUs7EMNWbXgK51FNoFRhcyFkBzq141cwaemN1ziAm3hsKjaK1BMQ5/QdXmi7uhKRPZp5Qese4LTpXajo3yRDEtg+yL/4FDX5abiDJNo/0fNnIgc5b8ErTDgPW0Xjn8HIWaaLP3pum0gXvTtO3Sad+xjzco7jE7WkhN0X/WjLf5H7BP0l6DaX/9CBNeguE+np99k0LOfrLOpE7My/YZggRipX8RA/cc80WUv4V5+wcIN+W7NhVRSCb3AwqyGKUozqPpYt10+e8QoL2BR34S4u4SKO6pClFn1ewwwIG8IvzOtayzk3ynTLLS7/BRgAwNcIdksnIggAAAAASUVORK5CYII=
""")
    if icon_code == "kk":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAbRJREFUeNqs1E8og2EcwPFnNiy50C5THPwrJDdK/hwmDszBmSgHJ4UcHRTlwHEHyUG5+FOccZAoWRElISKRiz+nmSGv77P91ubttdE89dm7PX9+z+99398zm2EY6r+aI4W1TSjAEfZTCVYOD/KQHg2m9G3+UbvxvS1Gx2xJnlkhvHBjF3fw4xR2UYVAssx8hnULoQhHmI1fYw7gRh2WZeEcaqS/FX7p92AVj3CYg+nbHTNlMGmRbQbOcSXBA1hDJ6qik+YkwBKa0ZDg9ltk7gRG4jbf0YP18sP3y7fpwqmsecUnDnUCenBGOhx/KI8cVONagpbq/jReaDFC+DDXxT16UYab70PPUiIduiBQqzt1sAM4kW8O1oMn1KHNug7PYJOEwsGmZWAe2fEzK5Al58VpHWxUrhvRYBcYQKNU+BTalQT5FJmxALrq+7GGYaxgy3wCvDiWB7qg+/rQZRjdXMdrYvOy8YA3KQ97orPp0mdtT6ngEP8KlZFsL2+VKhlkb0/kGeUiiJf4hWkWz+FBTzzhI0epLunrZQdjNvJd7/5oDvRTsHDbjKSos1rH9ruknKh9CTAAhf82BeKVt4IAAAAASUVORK5CYII=
""")
    if icon_code == "jj":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAWJJREFUeNqs1MErBGEYx/EZxkE4iOKGiBPKblxwkLj5A3DeixvFzX8gKyfJxdFJcpKDUEoiUm5sSm1cKJQs4/vmt3n3ZdtZ7VOf5p2ZZ57emfeZ1w/D0CtVlHkljKDIfB9jiGkimzj5TzHz8DymUItyvNvFPPPNIvCxFX7Hk46PiNt5UYvNqcA0JjQed/MKFWlAC15xrmuLKlbj5udbzSEcI41rVOLSWgQT9b+ecqp3YCb8iXWsIKXzSXRrvJrvNfuwbxW5Q6uVWIcL3WvEslWwV/erTGIzXnRzDbPo/OP79ShnDwNY0nkGb9g2SRu6OFJgMQLsWLNfwLPGV0iYpHucRWyRQL11qyIPSKI6+83S1rJHle21Ubc1DtCF/iJ+rZiOqZwfl4rt6qEKJHGk/87twU9kMIyE8gZ1LafPzPKehtFjF03u6/vW5mi6PI42fOTZNUzyDQ41U899zZJtjl8CDAAF2p2vrAvO5QAAAABJRU5ErkJggg==
""")
    if icon_code == "ii":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAgtJREFUeNqU1E9IFHEUwPGnuwsdsg4VYYJZXSyC/qEbZnjw0h8wKOgiKEIlVpfAQ6DrYTtEhyIIhBYvYpFFUHQSCbqssBVFFIR6SyootcBqCf+9vr/muTtuM6v94LPM/ObN29/vzZspUVVZPrZjI0olYFzABiTzU5ncUcAdc1iQkNGMtrCLAcmymMJ7fD0pEjvtu/gcI77zFpGDV4skm8YHnMOuapH0fZGJuEjEXXyMexZYhn5U5W51NQtRgTOqv56p9rYylVKNLKqWM10/phpvRoP/nrBEN9Qb3/DGO8zg9h7VS5Wq25ir4zy+JiyZW0knRi1RN3ZgJ5JgVdrixcaw9xPJLtsK+af4iajt9iie4AcmcRZ9vkL2YK3VaFBkYFakndjqTZx/wQyibkW7bSV3sblIDbdY3E/0Erqgun9f4TavI1skiV8jBrycgw9Uy/iDutKl6yX83GGJW3FYVj+GERM5wOuSfSeynn7MzLo+m8Chv3vOD/c+JXDRXp/C8R3rKPUVGnwud689sXk8tfq5ufOaH6cKtnrM5m+pJiSoNWoxZUEp15WYwThcKSIWN2wxj0CPdS1LtrS1F6hEq7VGGhXeVqQTTXiF10jhYWAlQ57aNRy347StZvrfuC5Z6XVK+OpVgyPuiaNjpWTRgMW+xW98xke8xNBq+iUomfuQ3bSP2uR/9J78EWAALCleC3HHZPEAAAAASUVORK5CYII=
""")
    if icon_code == "hh":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAglJREFUeNqU1E9IVEEcwPHfqiWKHZLIRFdEWQkkEzyFHfQkgQcVRREpiKCiKEHwIOhBoxJkA/8cxBT0ogdR8aBoeOgQ4UHptBFZRBpUdFHUkGrX77z3ezTq7uIOfHbmvZn5zczvvbe+SCQiCZZyPEQRfqIRO06PCZYAP1YiR0uW159osJAG+KZ1F1JOE6wOC9jBKqY0QD0msXd8TrQgPvTrxE8Yw7J1LDNmUReJGawc8/iukzrsI6ACBwjikY5pjhbsjnZuYATtMY7epuNu4ZW2zfG70WgGBPTm/CkeQK513BU9qlfWzIAnenHWnvgOmRg+GbAY9xDGX2zjmdmU6RzH/vFdXMFtXMdg9F126iauefeSeG/fIw2X7Nf8As6I5JeKpM7RLjn5JWxpve7dMMFe4jfeIMfrSBZpofr4R6QwQOOcufgfKBe9+IADO9gv1KJAV3uN4n8ifdRfEArzkyrizxO5SnMCm7r5FnurPutDN6s9MEFXRdaeiqRnuwvVoYfGTKXILAO2zTwE8TVWMKeMsyI+85fQyuVNnMfbfZG75DAwKrIR6+8kxb547OYlWOSmKKTHeYFScleTEyeQs7MmfaS7IE9CXqrC7pHvYwgNJgUEKzHnm44TLCmDn3Rc1KQRaInKjzJk4QYGeABOsp7HC5bsvgYOq/zQfI2g2tTmiV7GXJxghwIMAG8XfuNeCNoaAAAAAElFTkSuQmCC
""")
    if icon_code == "gg":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAkNJREFUeNqclG9ojVEcx7/3du/SLDLzZyUpa+2+8Eq3UBIWb1hZ8gJDrUjJmiRJTEoKb2nszXLJnzJDKSVNa++Ufyt3eGW6i6FbZNzN9TnP83u2Z9fmjqc+z/md3+/8vud3znOeE8nn8/qPpxY2wHc4D+88rxP7R07mx54sVAexYonr4QY8NpFmGIY7JrYjPH4ykSh0WMI3yEDO+l2QMHvl38RWQwrSNvhAKBaB6+avh5dW4YRiLTZwCN7D7kmqfgLdsMXGf7IC6oMB2yxwagofoMHGPoNes19DowsmLZAuTPw4aveH/XNs43tM6Fp4mZvhK1wOnH1Q5wfV6vmcWQ6thVVmbIleP8pRG4QPkAhO5B4gULKCZrHnWQIVcAgi4cP7HJZDTH6OuuAMLIWdb3312kpO9Yi00M/JQWmJVDNdmjbThBbAOuiB4UDM/U9t0O4ct6FGuvJLGnC/Sa+X5wRG7mN8keKPTKzJ2hNBmVGNTb3LCd6Squb5s6Xg4n4vPNiAyBqMuFTZIW1yzkv+vHozKvaA10MDtXL2qBPltlJp7SuQbi6T+ls8HW/SuUnq3yhd6KOfDm9g7LQZLEuLpKOsJ0HG/BdkcR00+okVswn/BPYtx4Ynj0jn6O4dd5XEqsdfLRmEjtMeRiy11Sv4Kqz6LA2dxe/2izVGs9KPP+6laEHffdUZUEWg03xlCDXT3gW3b1l/HfGiYu4Z6JeO7ZOeSgfdCdjO6x7UFbsxYxP42llqZJZnus9T5k5H91Su398CDABlAE46vQz/7wAAAABJRU5ErkJggg==
""")
    if icon_code == "ff":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAbRJREFUeNqs1E8og2EcwPFnNiy50C5THPwrJDdK/hwmDszBmSgHJ4UcHRTlwHEHyUG5+FOccZAoWRElISKRiz+nmSGv77P91ubttdE89dm7PX9+z+99398zm2EY6r+aI4W1TSjAEfZTCVYOD/KQHg2m9G3+UbvxvS1Gx2xJnlkhvHBjF3fw4xR2UYVAssx8hnULoQhHmI1fYw7gRh2WZeEcaqS/FX7p92AVj3CYg+nbHTNlMGmRbQbOcSXBA1hDJ6qik+YkwBKa0ZDg9ltk7gRG4jbf0YP18sP3y7fpwqmsecUnDnUCenBGOhx/KI8cVONagpbq/jReaDFC+DDXxT16UYab70PPUiIduiBQqzt1sAM4kW8O1oMn1KHNug7PYJOEwsGmZWAe2fEzK5Al58VpHWxUrhvRYBcYQKNU+BTalQT5FJmxALrq+7GGYaxgy3wCvDiWB7qg+/rQZRjdXMdrYvOy8YA3KQ97orPp0mdtT6ngEP8KlZFsL2+VKhlkb0/kGeUiiJf4hWkWz+FBTzzhI0epLunrZQdjNvJd7/5oDvRTsHDbjKSos1rH9ruknKh9CTAAhf82BeKVt4IAAAAASUVORK5CYII=
""")
    if icon_code == "dd":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYlJREFUeNqs1M8rBGEYwPGdbVEWK4UcRCKJk1LsuhAnpfw4Sv4FB8rBcSVcpAgXNzmJXMhBTi5cSGRPrJRCdg+72Rjfdz3Da5rdluatTzO9z/u88/4cwzRNj1vF63Gx+P6ZF0QfUljCU7pWTfOPWnBvfpUYGq2YL4dlqEcAFyjHPvIlvofr79ZZRtCLqPlTkkjhFP1SF9JznDagAhM4QByDaMeMrLHKiUrb2l+ZWs/NiGgj2XIYbZfEprEm72NoQ7XVqBUJPGIE3SjLMH2rk3HcyLvKnVPBDpzgGf4cdjOIF20GcUyhQQXDUhm2JRkoRgAlGis+IHmL+gaUyvLFbRuxgBjucCvPV2xKfBvH6NRvgNq1IQxjVutsB29I4kOoM3dmO4cFemcqqRKr6MEhliX2gDxJKsQ8LiV3VEY1ab+b6zIldZqLEEKVTM0rHfplalZpwq58IF2MLL+gOtTgXbVDQt7VukWkLn1Uc7lOK6ZzOcqUk+2ib+BcRmR9Xa3bVaYEw80/7acAAwDmrvNw22kKOQAAAABJRU5ErkJggg==
""")
    if icon_code == "cc":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARNJREFUeNpi/P//PwO1ABMDFQFVDWMhIC8FxIlA7A7Ef4F4HRAvBuIPWFWDwgwPzgXih/8R4DoQR+NSj8sQaSBeAzXgNBAXA3EdED+GitUSY1gmEN9AckkVFk0LoHLO+AybAVV0G4hnAXEeHu9/h6oTwWZYGtSgbgJhCMNToOr/AnE+umEgW14RaRAIiwOxPxCfhRoahmwYyIY9JBgGw4xA/BKIb4L4sET7BIg1yEinoLx4B4hVkdNZKZ7Yw4eloPqOgfiM0IzOCMTzgDgBiPcB8TYg/oMnh/wCYiEgrgZiViC2BOIT6DbVAPG7/8SDS0DsANOPbvMKIBYAYjNoXvyHw2XM0PBaD8QHYYKMI6M8AwgwAABQTOIMFVI+AAAAAElFTkSuQmCC
""")
    if icon_code == "bb":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAUtJREFUeNrM1L8rhVEcx/F7XAYZ/EoMMim/iq6BwWSy25VBFsW1+R/uQhZlUAwWq0VkkeEyULckix8xeer6XajjffR5OHTvdR/d4tSrnuf8/D7nfJ9jrLWxUpWyWAnLn09WhVmc4ACtHy1uzyKox779LEeoCdvLC0RQiwkMwGBDz21IIYlRZH+KrAs3Wn0PW3jV+xx69dzpj/MnqMS4BrpyhYTXXo00njGEAKu5JmtCRpOcYQfdOSKuwy2WMKxor7GNKdehH5uaaLCIQ0ip77q2IPyKpGtcUcVkkSfagGmcatyatuD9MwNVNv8iTVyZD+tc0p7rYNsjJm+ANPr81BjDHQ4jRtaoyBbDOqNbYwTLuMQCLgr8bk9owYwSO6Hf6kueuZM81mqPuMdDHlZ9e/xozbf7rEO/TIVbJ89exfGCXWT8BvNvL8c3AQYAlBRZu9NjtdUAAAAASUVORK5CYII=
""")
    if icon_code == "aa":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAUNJREFUeNpi/P//PwO1AAseOQEg9gPiQCCWg4o9BeICIL5HqmEmQOwAxOZALAkVkwViVVyGMYC8iYaZgLj7P27QjEUPGGMTnIum+RsSey0QCxBrWACSxodAnAHEj6H8m0DMissgdMPMoRpA4A8QSwKxIpLh+fgMAmEmpOALBmI1KHs5ED8HYjck+RuEkgayYbZI7OVQ+jeRMY9hGC8S+w2UvoIkFkKKYZ+R2CJQ+jQQ34KyE4DYg1jDjiCxI2HJEIhrkMTXA3EVEPMDMTO+RGsCxFeQYtMUSW4SWtp7AcQXgXgrEKfiSmc+SBreAnE4kpw/ED/DkiOekZIDjgJxMRBHAvFJNLk7QByFzzBCeRMGjgCxOKG8CcMuQDwPzWugfLofms2Y0fXgS4hngFgKiAWRyrOv0Fg/CMR/0TUwUrOkBQgwAOdaY/oFZfBQAAAAAElFTkSuQmCC
""")

    if icon_code == "w":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAf9JREFUeNqM1E1IVFEUwPEzMlH0BUWYVhuLgopEJIr8QCIyCAohbCMEEjFgQS4EEReSEK2sTR+rUJRKJVoJtTApjUaMsg/6wAhqIcZQmwhB/Lj9D+8M3mbem/HCj7nvvXvPvfe88ybmnJM8bS/2YR6f8TVypAbLoQaP8RspPMKRqPG5Al1zQVvACJ655XZuJcEO4Q4mbdIgtnjPt2HYnh3NFeyyt/In9EfseA3+4nVUsNPeTory5FHds/FJVPrBavED02ET+zCUfb8UnfhjQWvTwdKJvp4ZqB7lOID28B1ut4BTqCqgOuasStb6JXMf33EYNXiOK9mVNY0e7EadBhvGFzRgfXrUDrtYEmmiWg/uoj8VXqpb7XdGg71As819ijKstgEXcEtX1i3c+D/IJjThLAbw0D9/o1caqffO7ayiUBPOfUMhedvgjdWinbOxL7FR78e9lboxgvO69VGRys0iQ5oCtp/8INJF/zbW4aOlNYm7WNQAsbAPvQ1MdiXkfDb4wjt6Rarp/sRNtOJd5rwC/+IXjuONSH9JEGScASdnRC5ZoAmcsBOcygwWr7bOvNWGvrVVIq+4fku3JcUajcFLEPsLqgC35UlWsP0h73opyM9FHOOYiT3Lj65azvTNL2TOiyWi/xw7oWud0WyPSf4Wz/HsgdabHr9YVtb+CTAAvIk7wVLR1UYAAAAASUVORK5CYII=
""")
    if icon_code == "v":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAVJJREFUeNrMlE0rRFEYx+eOUcRGFkZNxFpZKWWBDftRPsKUheyELJC3JNa+gmRhaTc12cpSeU+JZNJsKDp+p/5nnCbnGtMsnPrVPc/L/z7nuc89kTEmUa+VTNRxpaqIGYVesEe4hHww0h4zQATz8GS+1yPMhnJCQu1wIoErWIdNuJXtCBrjxBogB3l4VdIcpLwYK7Ai31pILAOnCnqBC1iOaYGrurtSzPamIOeM3p6MEbJMKr4I077YmBw7vwj4pGEXbpS758S2ZMj8Qcxh+3mo/CE7tC2akrca5vQDpvSctWIFbSZqHPyo/ANQXis8q9TBwHFWoT/g21fuuDMMQEnGY9iAZujR/lMDu6j4DtiGc+UcVA5tn4x2vUMnNMGZ9ztlvVijApbcKEU/XEFp9eFB+wUYUbNzcC97FxShVG5eFffZsJLa4Brugl/i316OXwIMACAfj1Q/8vxzAAAAAElFTkSuQmCC
""")
    if icon_code == "u":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAf1JREFUeNqs1M9LVFEUwPEzZiKWlJhJliZmUn+AP4iikGjRooLBctFCsDZu3FiL2WktAwNRtI0RBRURtJtNioIRWBYjZDmkVBC28sdkJqXH73XOy/H1JhO88GEe95573733nDchVZWtapl/d5VhDzKC4i/jFK6sdb3885SxyZcfRlW6wYDFJjGOReeIyLaKlMFdKFwfX3MJ+WkWc3f4GEv4WScy/EFklqNtd4M3cS4l+Dkeig2mOeYZxDB2T+T6a5F9+0VGON70E5HlXgaeotyCznJvU8l9kM0Ax/AWX/EOMdU2fk7fV82JqFbEVY8vq1bvTp0X8pWGS2MY3fiMLjv3VdvJBZH4M5GmndztBOFR+prt6J+8VQsRxYImWzRgtw9sjOcB5PSws0HUgu7qmNuZy8QrFOAGRvECM76L3Itv6EdEpPiOSF5cJPciySpdTT+LtdsbS9LcX6peJJLh7XOqB4r8dzbMqh9R/5+FG8KbZO00DFEd70W+dHml4aozexNfgUtICw5yRJKS6KRoT3qlcc2OWRNwrKPYEdB/G4vIUj3EvMri1aqw4DFb8BbCNiFstfYIVdZ3HnctttX/Eu8hGx0WNGR9bbrWKq2vD78QCUqQv2gz7f6+4wQaMWUlM49c/LAPd8P/s9+2kGsLGLDJXlzin2neyn/aFQEGANI+y/sV7qulAAAAAElFTkSuQmCC
""")
    if icon_code == "t":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYBJREFUeNqs1M8rhEEYwHHvWj/W0q5woJQoxQVl/wBcXVBuW+LgRBy4u3EgN8VF+QskksLBkQNJciOlkCxvLKV9faeeyfR657Vqpz697TMzzzsz7zPreJ5XVKgW+aO/D3tw8YxNpKyj1cos5ryfdoFL43c6aI4/0IIp7MikXdQb/W04lb7+sGTmSlQ7hBOwggQ+ZLW/kpVgUhLsoxWVKA85ggUZv4V2M9mEvOk8ZLJfL46NXQzrZAcSGP1HMq0Jj3jAiCqNuHzYW8sHr4Bj6bvGDOqQVsnOpGPAN1AnWJF6szVXnjG11C5sy1YHjS104ggZuJi2bPVE5s7qQK1RP+q5LPW1LrF3pHz1pvrudCLEzDdUY006c2iQwlzCKooxhiF0yLgXiQXeACWOpC+mincRr/jEPGr8c4Mu+hsycugbSKgrLKpQiiye8r3o48jKVq7QiG75UOqW9ORz0bVmKUR9ZSISj6JMHXbQvKildu5li0ncICfxLxHYnEL+034LMACt4QnjXQmzjQAAAABJRU5ErkJggg==
""")
    if icon_code == "s":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAllJREFUeNqElF9ozWEYx7/nty3/tmzaLImsdZxaKBfrkFjTuXGBJKKM5GIpaUtE/tyo3cwFLtwJSSRJmEWd2maFLJSig9XiUIvGWnKEvT7v+b3n3zq/s6c+5/e8f57v+7zP7zm/kDFGJWwmtEIDjMNj+Bi424oFMAM64bPx7TfchKagmCChOTDkRIbhIgyYnG2dTqwC2uAujLmgjikBSyHh1pqCxOryMhmFL3AkIOuI23epmFgUet2GTrfguUyDypDZH4dwvliPWzhZIngq6+Gai0u5hNJiX91k9oSfQIVFmmrMCiwuJrrSxQ7CKo/uCLku+ZdplzVgF0YLmsp6s2Bffme9hCsuZJnnJqzttj+voUKaXyttnytVzS7oyuVwx50/mJmsgV+Qsqmugz6XbuQA6e8x5nw7gxZjGq6mr7MNGispDXuj1KuM6/Xb2M0uztYvnLn7EuiGqpgxNftxELtNVXUuvV4PzRf8Oqdrfd2Yd3I9mYRqOxnK/292wSvuP0/ahduHf+iptEVaVMXN36YLIE1IIyukoyNSR7Wr9YRdKI/zQ23U41ehJYw7KUUZdvNsls7iJk9JCzNnfpLCJ6RjFM+7Lx3MJhNqJbM/OPWwQErg29M2ksODXun4B8XfSLEBXz9rL6TJHdLz9zRXTqw9d00r8gwuw9p+6Qn3Oi3VRThqtVTZ5Z+nG9AGf6Uh/+HMyzvtB0RckhvGfWHsW0KqLXNCZ2BnTsEraByvyCduE1d8+F165MYUK2ULR5Y6XOpLWl5kLpaUxvam3Xv29dj3Y4e3NI39F2AAgWB6Tc3PnNcAAAAASUVORK5CYII=
""")
    if icon_code == "r":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAaZJREFUeNrE1D9IQkEcB/CfGVhCkSCVBa1JSxCYUJFTky0RQro0RVM0FDRFo9DSUNGQLYkEbYUEtQQhEWkttkQIUuTQX6Ks7N+v7/XOukRNQejgo7zf3f3e7+69ezpmplK1MiphK8/d5YMRaFWDjeACP1xrob1CKjuHZ9CrwSaYhuZsM3T596wBrqaIbEai9wlcmGAbOiEJmxBFdeMF7FkCPHGi8BBRvJ0o5dAmkxN6ZNLY93BRWQ7DcAC7cMrs32euS6ErymxFqOuY2W5R52RbpljKMvTCIdxAFdhhhSjkIVroIIpguSbxhB6h/utJKJndcMI/zZlRqVfGW5gXca2PoLIgHAHC9nkxqAYm5UAsheegL8fSL+CMOYgbE5bc1q3F7XVgEAN8MtFsnv1LG4OkNnw9xmzpZ7YZ0/3i500mowKZYQk+mF34s6yqybjIZGmXzIkt5gq3miwkk3mKSFQp5wyocXE2R2EGAmCGsDgZUmZ7hWrwyldi51evzGqAgLzbE9zDQxZ32l7xLTgyK1Zf2loYBCu8/PHJ2oC1Ig/6P34cPwUYAK4bIjtHK1j2AAAAAElFTkSuQmCC
""")
    if icon_code == "q":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAgdJREFUeNqM1E9IFGEYx/FndDq4lNFCKaQRrSYi66GyQItgvYSHoMMShNglU0y6GYKUJAoRSHhQTIsOgVtiiqBIiIdCvEgdylNEKKLUkuTBLqZO37d9BnfXmbUXPsy/9/29z7zzMpbjOLJPi6AY6/iAr749TVgGN/HFSbQNjKDCr79fiI0pDVnCC7xxdtu1/wm7jnGs6KCWtOdFSZWG/MIsxLRTHPNo86m6UPu99Ao7hHbt8BCBfdbR+Kz936EsOaxZH8x6DWR6mdh7P4IObKtSN6xfwxrSg6I4gzDavCss17FjOJXF7tjSXXIkecsMYREXcBnzqEc8dWd9wiyqUWrC3uMXmpDj9irAQZHgjsj9PyIlp7n+iUt7t2oRlvHDhA2jEYWYQRWOacdudJgTAiUPxxP3bZSjH/l4ggVbB5nAwxjQsuNcnCXgKuevzKzarzJb5Kg54p7e68Ezdwa3DWIaNQiyRrVBkVZ9uxVE0YtN3NW1nsScG2Cnvf8i1fSdFzkXYs1PEMj1Y+5/1w90EjfwVqW0lDBTQp2IFWZGFv8bQR8lYRS5uLMtEvP7aVgX9RdkFjgAKrIOiNzmK65y2alrE9GjZSa8glseYXaZx1+JoKccX+sXK9EgU5HFZ3a6df+FM71mWsvXrfFcAx/oRP+2SMCrsgxhj/Sv+htdWEt+mO0x4K8AAwA0VAS8kF/V1gAAAABJRU5ErkJggg==
""")
    if icon_code == "p":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARNJREFUeNpi/P//PwO1ABMDFQFVDWMhIC8FxIlA7A7Ef4F4HRAvBuIPWFWDwgwPzgXih/8R4DoQR+NSj8sQaSBeAzXgNBAXA3EdED+GitUSY1gmEN9AckkVFk0LoHLO+AybAVV0G4hnAXEeHu9/h6oTwWZYGtSgbgJhCMNToOr/AnE+umEgW14RaRAIiwOxPxCfhRoahmwYyIY9JBgGw4xA/BKIb4L4sET7BIg1yEinoLx4B4hVkdNZKZ7Yw4eloPqOgfiM0IzOCMTzgDgBiPcB8TYg/oMnh/wCYiEgrgZiViC2BOIT6DbVAPG7/8SDS0DsANOPbvMKIBYAYjNoXvyHw2XM0PBaD8QHYYKMI6M8AwgwAABQTOIMFVI+AAAAAElFTkSuQmCC
""")
    if icon_code == "o":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAb1JREFUeNrMlE8ow2EYx58tm/3xvyUOJEokDi5bDCmKGxfFTStk2UFESjmjHObk4qBdlxZ3JUVx0MhVtkhqmoXJn8f3t9/7a7/NfjO1g6d93u193uf3vM/3/b3PdMxM+TI95dEKfrrqgU1rnwFgBIGk6zhbshgoAsXgM33RDcpTk2WVWQ3ewD0w9GFoSwtQH3I/kWNKmei0X0ANCPuIGkexJ3SXRuBwSDuAQxFwAw4gtVdDpmIh6NzfIFrTQW47UXCIqHYY8r8wP0eAF4wDf7JmVJYBD3hi2R7BC/MmvlommS0zzK1xZmeQ2Z7ynFqmBTSBBTAidt4TspaExDqiaIioswruO6LCMfguQE9CusjaDcKiklfgzlAtKuFL+fcqMF2jMsTZp0EIuKSgBpHkCDSDSg3pgyJul9k3Ibs6uuQ1e0lCIYYtENNIoMYMkISv5JyeHdRhVMdIwynYziGZghXcMkf8mJ6humVlTS/uiuMPLfgMHtAIVqIKdELchcdNytVwirPw5liZEj/HvIi5rQxnpldkSsyLgA8Q/QXJAsDAvJKykdIB68AMZrN3RcJOxF18T3xUpvu3f47fAgwAhV/iG92mB4QAAAAASUVORK5CYII=
""")
    if icon_code == "n":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYZJREFUeNqslM8rRFEUx897oylFprGwECU/spXFSAoLVvbKapKVUn6UhRRrFhZKalL+AVESS8oCZWHBNNkoCys/FiJjxvE95vCONzEv3qlP795z7/3ec8899znMTGFZGVFHqTlR0A9OwU3x8NFXyw2wYQz0groAkZW0HjAJsuDkt4k2Mgc0gbhvTk6/Lz5/AxhBmmI/icnOx6De+DfBKFg2vkZwAFIqWiT2BhY1ul3jbwZp0Kr5E0sWchhZ1bFCNMyV2nwFFaAF+ck/obEDVsCAEb7X/G1ACLk83yZ68EalzjyWSMqOuQskMsyd4t4DSTDHXJNj7oYvMcQcx5z1b+t9YsK8CE5rd4r5zowtVOGDTSgLXP9ax7yAWk2snHCN6Ay5m+lD5xlE5BD0caatcaKLYYzNon/o+enKKqf474ZIecxGJlEN6k3kAz5HV08kN7ovYnLdbUBu8FbrLeC7pkdwbW9zgv9n7Z+pEnXUClWDcvN0glhUo7o0RRve/8ylEC1UsXcBBgD30UH/e/sT6gAAAABJRU5ErkJggg==
""")
    if icon_code == "m":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZlJREFUeNqs1M0rRFEYx/F7vSbEwsIIkyRZTGRLeS1KGlZYTFZSEll4K3+ArGwUK+UPQBZWLJRSipJYyCSkjMzCxkteju/pPre5ce9taE59ujPnPs9vzr1zOqZSykjVyEiipgZB6F+9wNV/w/LQjpCEHeAeL67V+jE99CCufo87NLj1/JzIksIxaXxAGHnIxyBe8IFqv7CwNNvjHmUuKwjJ/T2vsE4piCGCVpT7vIJVqZ9CjjOsC7d4QsAnwKkb1xJ4iSo7bFMmJ5IM0kwUold6z9GibxzIRJtb4yga5eoRPCf9G2nsjqjsko6f2+YLO6jDGabd9+KhXEt02DJOMYl6Z5W+WYR3lOLRPWxErnu6fh8RWcgRFjGAXHt1enyiIBFQjEFsIYwVLDmfvRLbjn1Wq+ebMKzUeL9SzTOJ2j5H3YKdYbqcGkFZVZR39HZjGL2saP3VMGZZ5fyaVZODCsQRsxtNryOIEGMI5eyedOv9FZ3QPMbnvr+eGsd4Rqa1oiPEs/ke+M95lo906w/Y9TvDnMNM5Un7LcAAcQgryByHp3UAAAAASUVORK5CYII=
""")
    if icon_code == "l":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhFJREFUeNqM1E1IFGEcx/H/rhOGBZZIKnWoFAvMQAnCw6Js1AZ72EOEBF0rvNSlYEMQhbBLlpFGBwVB7ZXohZBeIG8FbVuRhxYi6O3isiFi9ILp9H3Y/7DjOjP6wIeZeeaZ3zzPM888Idu2ZYWyF434jSm8921pwgIkkLLz5Q+eI+7XPijosobMYgRjdqGcWU3YPozigz40gHWu+5WY0HvRoLBebTSHNAZ9emxpb996hZXgiAaNo3yFeRTXkDPY7w4zQ/uCb14PMmZ5tLy+CUl819CYE3ZCK64VBx1GMxrR6d3DKuTwEa1hVseirpIN7iVzHZ91kbUihWPILl1Z07iFOuw2YW/wEoewxWllTtaLhHhTcl4kUs91DpHlS7UBC/hhwtI4CUs7EMNWbXgK51FNoFRhcyFkBzq141cwaemN1ziAm3hsKjaK1BMQ5/QdXmi7uhKRPZp5Qese4LTpXajo3yRDEtg+yL/4FDX5abiDJNo/0fNnIgc5b8ErTDgPW0Xjn8HIWaaLP3pum0gXvTtO3Sad+xjzco7jE7WkhN0X/WjLf5H7BP0l6DaX/9CBNeguE+np99k0LOfrLOpE7My/YZggRipX8RA/cc80WUv4V5+wcIN+W7NhVRSCb3AwqyGKUozqPpYt10+e8QoL2BR34S4u4SKO6pClFn1ewwwIG8IvzOtayzk3ynTLLS7/BRgAwNcIdksnIggAAAAASUVORK5CYII=
""")
    if icon_code == "k":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhRJREFUeNqs1E1IVFEYxvFnzD4srUUfKsIUKRGFURnMwkqCCmlVQSC0DWoRRbmKPhYFoW5aVEQEFUUuFPoUgwhqEWJcc9MmKgrc1GSbEiOa9O1/uufm3Jk7UeCB33juPcdzn/fcM5MyM01XKy++tRyLUJY0fw8+48nUrcE/vbL/fPgGrCo1mCouM4UqNLqL+dLE17zBnxjAZn+9EPNIN1IimVu8DwFjwR3p2z1pRjSvDe2+v8aXfPQveyb/4GBS6r0h3d0vDbOJdetJ3CrNZWzCfVT6lJ1TOSgzQRMeYRhDZi+emu2kW3vbrIr+RvqZY4j9X8KeaR+u4B0eh3uivciiRjrAn/unpfqTUm6Zi4k6fIhWXYwejFrYrhUkbfT3z4XXh1Dt0hE3040cHpT7NxL4w3Ueb3C1IO1LkERnMCStHA2D1r8nWAedHozIP821pSX2L9KA537uJPt2wWx1bI77CHAraYGB5EV3YNwsy1bMuUx5DdGYOz8/UFH4FqhFW3Gi+Nz04zWape/bpJkX849Gu4++KT/BQ2zBCryNJ6vx80+Ztc02SzfllznLl+radex2A4NoASdKY+HkJehAFp/CRbtiWxCVmfEV7UKrS3xJWsAh6stJ6yrDItzbPoxnWIuP0peCb2LCJh/BdrP+g/b73KdvlnzDx4uSxRpfSL1CWhon1dlqzk/3P/4+pabzl/aXAAMAn3Xp9dXAXpoAAAAASUVORK5CYII=
""")
    if icon_code == "j":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAeFJREFUeNqs1D1oE2Ecx/EnTSIlGAIhOEigJkKgvgwK5YoWugpSpy7iIJlKO9Qhgyh0EKwupVANBEGlLYWiLkWFogEdhFKUlFBKSBREg5MdSomvOPz9PnfPJddwxIB94HN57n/P/e7leS4BEUt10Q5hEK/R2HtovdnrUd21DK7jcKdB3Yb1wTJ32CnsGz8/vLUxXGsbV8VzfPbUDuApTz/jCdMX60UFG9hJKxW+Reem58QSRlD31B6ZWtUthJR6ZboFxPHwqlIvw0pFRakj7EcusLmCfnzBIvIoYoUJWGjGi0gH1pRIr+5uiiRmRc6sUWPfeqxXgaM13i8kjbuoi93eVUTeUJ9DFAPjhOrAyfawgJ3YmrEBPDH7S+ZljmIeWad8Cn94uQdjZsmcxzBqbmpOWu0rMp4rXjb1rLP/Aok8d7WNEB6YRy/rwZfM4Hs4gZjPo38yY26AgHCNk7fMe+OlWkcR0wM/4m3nibAvfccElkUiunTRbwIaKPwjzHXfyTs+LXLSdzaf4TuSXYQVsStym35cz2YJKfc4i1blzCp2Pxndgm2f00+kMOQs4CQ/vz6wOY1l849ih73HMUzjnLuWff4QfmPC+VT0txxcZXPWXMRu3nX2361H7WPb17C/AgwAhzfRU3ZsB24AAAAASUVORK5CYII=
""")
    if icon_code == "i":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYxJREFUeNqs1E0ohEEYwPFdCUmS9bFKaYskHxcuUpKj2pPswYGjA8rFSXEQ4eomaTcpHCQHcpJSkpYiF8SeJKxo5XPz+k89y6QZsZn69b7z9ey8M8+O23Ec13+VlCTnjSKMI3QkGlOTCLSAgFa//XxTn2lRjklEcY1xqTvyjGNMn2ML5He+yjKW8Cz1NWTLu98WzItR7MvAHfi0/jxs4An1stp1U7AmvEiQTczBY1hxGh4xgz4Zv4JulKoB7bjAPap+2MOEoAQ5wLa2HQOqMyKVhl8EUgoRwCleEcMs8lXnuwRz/VGubM1qok0lbUyyxGfIqWbUWPJN5dcuvHqeTWhHrv/yIC5xgk7DyorxhpB+mlnol4CH6EE1RrTNbdOCVKBXUkOVSlOeqQnnMmAYJZjCNDKlv1Y2X5Ww1H/8BxTIM11rG8INjtGFHNOhmG6NKxQhiBa5DOLwoAxR3JlOxHRrqEDzaEQr6rAop+bGnvU+seRQSPYlYvikFFvu2e6zLWTgDA/f+t5tC/sQYABhGwq0RRSPKgAAAABJRU5ErkJggg==
""")
    if icon_code == "h":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAm5JREFUeNp8lG1ojWEYx//H2QljHWZhkcIsjnJao0lCeQmt+EJKRK1ORIxSYr7IfNHkrSRT8vKBlPcPS0JTMyXsw2go8tLZh6EYx2y3332e+9l5jnO2q36ncz/3df+f6+1+QsYYZdsUKIEhymNrYRScyTxq6f8XyhULwUwYmU/sM5Q6J99wbPmh/K9/CFH4AB17pe7rUmS426yFmoDzTbjmL/KILYDHLog6hDrjUvMMRMdJqfFSn63DXGCt2XB1kDT7bR/EoExqeikdWCp9/Sn1/CLTSqn3GHs7gzWTFfuPMnhuPHsNrSZjJcbU4VO4zZj5LKvi3pmqyRAKiiTgmTvUCVMDe7MgCVe8dQJK2xCoh93wFxJ+zc7BafgODbAY3gZSJk3tgjWwSoqPkL5Qv3AX60dAo9Rq31rtotmcJ+UgY6DN+X4ikjfGlGf52J9GeB982A5LHMlc0ZWeXtdFY4q3GDMn5u/ZNAvgd7CNx93I2ulMQH12l+/CBWl0ubRsh5RsZlKG+XPGQmxooe89EcK0HcGNxd5JncoWjHkBROdR5trg0J51F+wB7IfKiFTRKx3tk4r4r0nutmLVTpc5UyP9oAHfznM8nZlN0U7tIjgCB2E6Hk8QueNeOK0HkWh6eNPR24u7Hi57Tc+YPxop2G6z4zVNr6QVpHeJ9UnYQFQN3NiP/K+AiCeUa1nXCc/IWOkPBbxBNE9dbe5zuvKetLVdg1tonWtpt/etKCqUNlGrCS6Cd3DIXmrCSu1xn4EBxWoCkYUDVxZuufp0wHIiVRJuDyJWEM59Zj8th+GEbQa8sA+HurvGN0mrBxD7J8AAVptpYKPh5AQAAAAASUVORK5CYII=
""")
    if icon_code == "g":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAopJREFUeNqElFtIVFEUhv+ZnBKxzIhIlEzKSoXSCicjitBMKBIiKvTd6MHs8qAvQhHRvYegCLuAPRRU9JBCUQ8lFVigXYgCI5ykCLsYokzRoLtvzzkzHsfJFnwze5219n/2Za3jM8ZovD2BDbBMSWwtzIQ7Y4864yP/xPzP8Bt+QmpisBEOevwUadW0ScR2QBcEoWOnFO6QArPd4EW47I6tyFM4O4mYteVwFZrfSV9L2fomRPEj86TRXAYLoBiI6XFslm/imcWtDtbDQulhSDpUIPVl4n+TsjjQkeOMm7xnJiuWQADuGsdC0Alh1y825gg5aQ3GrMENFjhzgvMh0ytSBS/dSb+g1BPLhu/Q5vi7IecNAnvgHFjh9lhynSvyAk7BuiQr3uLm1BrTnsOjIWNWb3VWF9wHlTYJdTMMN5MIeEmHByZuFR3GFPm8OfanC0ZhcexhDaTGk2xOj1e00BHruY17lNWVx2K2NCIwGiuTbXKKIGPcxS6CFTHnLbRJ+ZRJRbXU3+its/Pu/Bb7YEgqyZJuEcgaE7MF3B2QBq0zFTY6lV1eSKc0edohWp3WqnidpkiHoYxpX9znlXDSqfiMzW5/WsET0jB/P7oTO8AK1rRKc+mbnk/SlV3SDamV3c46RmyplPdHagg5W1QefEiscn89P/thO93AqzuZPcCec/Oj4dN7pTklTmo2LdTC+dTSAQolaxm/PYV+mC5VI5TObczgcAKvol+IIsLhPic1wudkJau69q/2kz/NERIC97jSA/j1z1jhBalXus+lZNiU585WI68T73mcmGdsP2KDnFcvJ36GxsYdaOZVCKjMjU9qKQn+x/fc5vVo7V3CXcIWRx65dfhf+yvAAL0PoNuAd7yKAAAAAElFTkSuQmCC
""")
    if icon_code == "f":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhRJREFUeNqs1E1IVFEYxvFnzD4srUUfKsIUKRGFURnMwkqCCmlVQSC0DWoRRbmKPhYFoW5aVEQEFUUuFPoUgwhqEWJcc9MmKgrc1GSbEiOa9O1/uufm3Jk7UeCB33juPcdzn/fcM5MyM01XKy++tRyLUJY0fw8+48nUrcE/vbL/fPgGrCo1mCouM4UqNLqL+dLE17zBnxjAZn+9EPNIN1IimVu8DwFjwR3p2z1pRjSvDe2+v8aXfPQveyb/4GBS6r0h3d0vDbOJdetJ3CrNZWzCfVT6lJ1TOSgzQRMeYRhDZi+emu2kW3vbrIr+RvqZY4j9X8KeaR+u4B0eh3uivciiRjrAn/unpfqTUm6Zi4k6fIhWXYwejFrYrhUkbfT3z4XXh1Dt0hE3040cHpT7NxL4w3Ueb3C1IO1LkERnMCStHA2D1r8nWAedHozIP821pSX2L9KA537uJPt2wWx1bI77CHAraYGB5EV3YNwsy1bMuUx5DdGYOz8/UFH4FqhFW3Gi+Nz04zWape/bpJkX849Gu4++KT/BQ2zBCryNJ6vx80+Ztc02SzfllznLl+radex2A4NoASdKY+HkJehAFp/CRbtiWxCVmfEV7UKrS3xJWsAh6stJ6yrDItzbPoxnWIuP0peCb2LCJh/BdrP+g/b73KdvlnzDx4uSxRpfSL1CWhon1dlqzk/3P/4+pabzl/aXAAMAn3Xp9dXAXpoAAAAASUVORK5CYII=
""")
    if icon_code == "d":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAgVJREFUeNqs1E9IFGEYx/HfbmqaiCCagSn4p0PYIbJUCDx06OQpk0A9ScIepCjo1KFLeIgEJagIb3YpQsjoVJCSlNolMEMMEyOow5pFuqvpMn1f5117mXY2Agc+y8y87z7vO8/zzEQ8z9NuHTl/36pBKaKZ5l/GcXT8uTW5cxb9z8Vr0RQ2mCHYIuaxYZyQ9jQ6gz/h5uWQ1MxumwtCgpm5D5HC+mnp1ZQUb5DyzeAtnHUmT+Nq+iLyjwIclQauS+P3pKeFUtUgQdlF8VsWu8T4STwnb7PZgp3DTezFZ78ifZXSBIGjS9KXmJTLQtpPoG9hOyNH6sRFjGEY7Ejd/i7Vgpf8bR91MIvcxx204b1MMDRiDpuef9y2910jSPjnN3Bw2POanuA8tvDYTKrEGj7gDOozBDIO24WeodXzSleYes2dY36GkEROSBBXH777MQdZvDrPHTc5m7aN1eXkzuTmCH45b8qqzZE55rAgxei70WWqfIFCpMykLRwIVLPVvjJJe11oG/AdaAvdRS+VfSElejjvx0ezs5itSDseoQJFKMemDWYW/ISvtl1e24anwnW0TEmc/k2mn/cBupCPVaQQx4o14uSm0xbiVDCnwT7LwzG7arGzszW8cVJShplgp4e9AVdsI6ZzVmQfryNTkCzfs+2DCmk2UM0EfmR7kSO7+aX9LcAAKgJprtqAgPsAAAAASUVORK5CYII=
""")
    if icon_code == "c":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARNJREFUeNpi/P//PwO1ABMDFQFVDWMhIC8FxIlA7A7Ef4F4HRAvBuIPWFWDwgwPzgXih/8R4DoQR+NSj8sQaSBeAzXgNBAXA3EdED+GitUSY1gmEN9AckkVFk0LoHLO+AybAVV0G4hnAXEeHu9/h6oTwWZYGtSgbgJhCMNToOr/AnE+umEgW14RaRAIiwOxPxCfhRoahmwYyIY9JBgGw4xA/BKIb4L4sET7BIg1yEinoLx4B4hVkdNZKZ7Yw4eloPqOgfiM0IzOCMTzgDgBiPcB8TYg/oMnh/wCYiEgrgZiViC2BOIT6DbVAPG7/8SDS0DsANOPbvMKIBYAYjNoXvyHw2XM0PBaD8QHYYKMI6M8AwgwAABQTOIMFVI+AAAAAElFTkSuQmCC
""")
    if icon_code == "b":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAb1JREFUeNrMlE8ow2EYx58tm/3xvyUOJEokDi5bDCmKGxfFTStk2UFESjmjHObk4qBdlxZ3JUVx0MhVtkhqmoXJn8f3t9/7a7/NfjO1g6d93u193uf3vM/3/b3PdMxM+TI95dEKfrrqgU1rnwFgBIGk6zhbshgoAsXgM33RDcpTk2WVWQ3ewD0w9GFoSwtQH3I/kWNKmei0X0ANCPuIGkexJ3SXRuBwSDuAQxFwAw4gtVdDpmIh6NzfIFrTQW47UXCIqHYY8r8wP0eAF4wDf7JmVJYBD3hi2R7BC/MmvlommS0zzK1xZmeQ2Z7ynFqmBTSBBTAidt4TspaExDqiaIioswruO6LCMfguQE9CusjaDcKiklfgzlAtKuFL+fcqMF2jMsTZp0EIuKSgBpHkCDSDSg3pgyJul9k3Ibs6uuQ1e0lCIYYtENNIoMYMkISv5JyeHdRhVMdIwynYziGZghXcMkf8mJ6humVlTS/uiuMPLfgMHtAIVqIKdELchcdNytVwirPw5liZEj/HvIi5rQxnpldkSsyLgA8Q/QXJAsDAvJKykdIB68AMZrN3RcJOxF18T3xUpvu3f47fAgwAhV/iG92mB4QAAAAASUVORK5CYII=
""")
    if icon_code == "a":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAXZJREFUeNq0lL8vQ1EUx/tLJGIQm1FSpPEzEnQ1GC0MJBpBJAZ/gpaFwWghTSVE2sHAYjRYmzSRUNKgidEmBrGgz+fGt81Le7VVcZLP+96cd+65595z3/M6zpinhoVgDbYgV/k6XRr5PLWtC+akVa2eZO1lWlcyr7ZxAn6XPwPn0qL5FUd82PtTsjxMQdLlv4N5adGSistrXkWyAkzCoSpsgzi8wZM0Ln9OccSnC6VqqnTzXod+BZcwDIPwAN2/6WZCiWIwBEvSmPwJ2yRTmblHQWiFG23hHbIwYJlzDf3QpDvYB6/m/AI8NmBGgRcw6+qizTJKZq7KDozLf9xoZb3QbKssZ/lM9mEZorDp8kdV1R58fC+Yzv5LNwOWJAfwCKOwDYtKYra+q49+HTr1zno1zPgMFnQWL7ACLdAhXZU/pDjiwz5bMkeNOIWIy98DR9KiRRQX1LyKbTpasdxGYEJ6K98nTDfyP3su0z/9z0z3UtKq9iXAADwrZuhwE/QdAAAAAElFTkSuQmCC
""")

    return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAYAAAByUDbMAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAXZJREFUeNq0lL8vQ1EUx/tLJGIQm1FSpPEzEnQ1GC0MJBpBJAZ/gpaFwWghTSVE2sHAYjRYmzSRUNKgidEmBrGgz+fGt81Le7VVcZLP+96cd+65595z3/M6zpinhoVgDbYgV/k6XRr5PLWtC+akVa2eZO1lWlcyr7ZxAn6XPwPn0qL5FUd82PtTsjxMQdLlv4N5adGSistrXkWyAkzCoSpsgzi8wZM0Ln9OccSnC6VqqnTzXod+BZcwDIPwAN2/6WZCiWIwBEvSmPwJ2yRTmblHQWiFG23hHbIwYJlzDf3QpDvYB6/m/AI8NmBGgRcw6+qizTJKZq7KDozLf9xoZb3QbKssZ/lM9mEZorDp8kdV1R58fC+Yzv5LNwOWJAfwCKOwDYtKYra+q49+HTr1zno1zPgMFnQWL7ACLdAhXZU/pDjiwz5bMkeNOIWIy98DR9KiRRQX1LyKbTpasdxGYEJ6K98nTDfyP3su0z/9z0z3UtKq9iXAADwrZuhwE/QdAAAAAElFTkSuQmCC
""")

def get_wind_icon(direction, ttl_seconds = 60 * 60):
    d = direction.upper()
    if d == "N":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAANdJREFUeNpi/P//PwO5gAnGYGQ4KAnEEvgUA+W5sWoGAm0gDgIqYMWhESQejVXzfwb7PUBKAYg347B4GRCbo4iA/AzDDP8PCAIxkHNgDpp4N1RcDFUciQNVOAmqsBfKb4HyT6CrZUQPbaDfzIDUSSj3IBDbADEzEMcAvbYURS22qAIacAFI6aMJCwI1f8AV2sigGY2/DV0jPs1bgfgnEn8C3kSCEgMM9j+A1HQo9yWQv5tozVAwD0rvIpg8sdh+GUg9B+KVuNSwEEj7YUD8EGdapyRXAQQYAHiRgZa9yBPCAAAAAElFTkSuQmCC
""")
    if d == "NO":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAMdJREFUeNpi/P//PwO5gAmXBCPDQXYg5iBLMxCYA7ECuZobgfg/yZqBzjUEUg5A/JQcm6Og9D98mhnRQxsUUEDqB5TL/Z/B/hspNhcjsf9j8RIPEHOC2CxYNIcgsY8CFf4E0jxArAXEIFcUAPECDGcDFboDqR04XLkBiNuA3jgNE0C3uQmHN6YDNX3HGWBAWyWA1HOo+Acgrgbi+dg0odgM1KgNpPqhYulAPAeo6R+htA1ztgoQHwfiQKCmr8RmDEZKchVAgAEAgkw480BZVgMAAAAASUVORK5CYII=
""")
    if d == "NNO":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAMRJREFUeNpi+P//PwM6Zvh/gBmbODpmYsAO7BmIALg0JzEyHOQlV3MIEEuTrBloozCQYgdiF3JsloDS4VgMVgTiCKgFDCxYNItAaRugIg4grQzEZkCcB8QGQOz3n8H+LS7N4lAaGGcMr4AYFnD/gFgOqPExTCE2zYZwVyI0HgNqsibGz3po/BnYNGJoBvqRE0ipIwlVADVm4gptdGerQQMIBLyBGrfhiyp0zX5QWh2o8Rap8XwOFC3EaAR7E5yLyAQAAQYATiZOzpDk8GwAAAAASUVORK5CYII=
""")
    if d == "O":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAMdJREFUeNpi/P//PwO5gImBAkCyZkaGg45AbABis5CoMRdI8QDxMaI0AzWoAqlgIG4H4odAbPifwf49Xs1ATbZAqgKIvaBCp4GazJDVsKBpUARSoUBcDMRiSFJbgRp9MCwARRVQkwqQvQSIzbE44hlQozS+0P4ExB1AvAiIX6CpkQAaPhmr17AlEqBiByBVBMS+SMKLgC6IJ6gZyRA+IOUBxAVAbAnER4DYEWjIH4Ka0QwSAFK9QHwLiDcDDbjGOHTSNjIACDAAsnY5duCOcP4AAAAASUVORK5CYII=
""")
    if d == "Z":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAMFJREFUeNpi/P//PwO5gAmXBCPDQW4gNiVLMxAIAPE6oAGs5Gh2B2IZILYhR3M6lC7E6TVsAQZ0qiCQeockJPGfwf4lsTanofGjSXF2Fhq/kijNQCerAyk5KPcZEP8BYhGguAsxNsMC6ijQn9JAuh3Kz8VQCQowZMzw/wCQceAWmtgkqLgCqjiqolggfo5uIFRuBxAvA2JOmBi6syWB2Apb4AC94AGk7gBxJEyMBU3NQaCi+3gSzmawOfgSCbEAIMAArc91/lmhBeUAAAAASUVORK5CYII=
""")
    if d == "ZO":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAMlJREFUeNpi/P//PwO5gAlEMDIctAXiJLI0AwEbEGcCDYgmRTMjzNlAjflAagIQvwbiBUDc8J/B/huxmlmA1CsgFoTK/YcashBoyEG8mqEG5AKpSVjUHQfiHiDeAjToFy7NnEDqMxAz43DpTyBuBXkPaMhnJmQZoMB3INWJJOQJxFxAzA3FskC8A6vNUNtBfn4H5VoBDTxOKKqQbX8PpLqQopCBaM1Q0Eu2ZqDtoCg7AsR6+DSz4JEDhaoouZr3AzE/USmMHAAQYAAUJECEsRAjTQAAAABJRU5ErkJggg==
""")
    if d == "ZZO":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAANBJREFUeNpi+P//PwMMM/w/II/MJ4SZGFCBAyPDQW0GIgG6ZlYgvgI0wJ4czQug9AGgAZUkaf7PYP8HSN2CctuABiwnxWYQeIHEjgAacB2I1YnVfAWNrwHEN4AGBBKj+SASezMQ7wPiv0C8DmjASiBmhEkyguMXCQAlpYHUE2gYMCKJuwCpRiB+CsSZQLm3GJqhCkGCv4AK2LHIgcTYgXKfWPAE5g5sgkBNP4HUT1x+BoFLUP8ykBpVIDAPFMKENONy9iIg/k1IM9YAIxYABBgAEBBjonNUSNYAAAAASUVORK5CYII=
""")
    if d == "W":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAL9JREFUeNpi/P//PwO5gImBAkC5ZkaGg4pAHEiuze+AmBdowEsgngLEesRoZkQOMKAmdyC1A8o9BsQ7gXjufwb7pwQ1Qw2wAlJH0dStA+LtQLwMaNA3nJqhBkgCqfNALI7FwhNAnAM05CwLDu+ATPyHRXwd1FWPQBwWLLZaA6kjSEIXgXgxEC8C2vYaWS0LmkbkAFsG9eNWvKEN1MQHZAcDcScQzwHifnRbsAGYzSJQfyoCNX0lNpEwDljGAAgwANakQaoOradRAAAAAElFTkSuQmCC
""")
    if d == "ZW":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAMVJREFUeNpi/P//PwO5gIlUDYwMB/WA2IhkzUBNQkCqHojdiNYM1CQLxOuAzLdAzAHEW8Hi+PwM1GACpPqB2AZJWOE/g/1DEIMFhyaQn+YDsR6a1EWYRhTNQA0yQCoJ6idc3mlDsQTkbKBGNiDbB4iDgfg5ED8B4n9A/BuIu4GYG4hvAm3VQDEKpBkfZvh/4BUQAzkHmtDliAltDijdT04i4QXiuUAnvyc3hS3BKkrAv7xAvBOXPCGbQbFQjjMRUZKrAAIMAB0uga0BB878AAAAAElFTkSuQmCC
""")
    if d == "ZZW":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAMBJREFUeNpi+P//PwMhzPD/ACc2cSYGAoCR4aANkIrCJkdQMxBsB+JQkjUDbS0BUjxA/IgkzUCN8kCqG8rlJ9XmHUhsSaI1A23tBFIaSEIaQDEmgpqBinSBVBmasCgQKxFj8wkovROIc5HEFdEVsqDZehZIcQBx6n8G+zlQMTMgFQvEQjg1AxWBFLwHYnagxj9IarKgmjUx3IiUBKXxJM+1QLwbZ/IE2vYUT7RlA/E5nDYTkTkk0MUYwRJkAoAAAwCpPJ+2KJduzgAAAABJRU5ErkJggg==
""")
    if d == "NW":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAM5JREFUeNpi/P//PwO5gAmfJCPDQU4gZiFLMxDwA7EtuZrfAHEN0HY2kjX/Z7D/A6ScgLiQHJtB4BMQF5Cr+T4QSwCd7oJVM1CCHYilCIRLM0ZsgOIZqJEXyI4H4koghhnyFuxtBgZBIGaGinkAw2EnimakeBUAUsFAXAzEmlhccRSo2QarZrQE4gqkEoA4Ck3KCGjAebyakQwRAlINQBwLxCCX7QdqdoLEJVAzsZjh/4EIIP4IxHEgPgspGQFo4wqgS4SBzM9EORsfAAgwAJ5QXvjlPoPoAAAAAElFTkSuQmCC
""")
    if d == "NNW":
        return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAANtJREFUeNpi/P//PwMxgJHhIDOQ4v7PYP8JJsbEQDzgBmI5ZAFSNNcDcT5WzUBn6QNxIh7NRUD8HatmoF8uAilJoAE/gFgWzb9tUOZVnM4GGgBStA+IHwE1TIVq5AdSlVAlH1EMxRbaQA2XgZQOEIPoR0DsDZWyAlpwHKaOBYf/XID4GRDrQjEI/AHiNwRDG2j6SyAVjSb8HIhfEhVVQANWAKl+JKGXyAmEYDwDFYOi5xKU+wpdnphE4gKlX5CsGWj7ayBVAsR/0eVYiEyaoDiXwIhSYnMVNgAQYAC4mTqquYVTngAAAABJRU5ErkJggg==
""")

    return base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAE1JREFUeNpi/P//PwO5gImBAjASNbPgkmBkOAiPhv8M9oxE2wzU+BCN/5oozUCF6kBKDsp9BsR/gFgEKO6CoRZXIiHG2YyjKYw0ABBgAL6sFmgosBmfAAAAAElFTkSuQmCC
""")
