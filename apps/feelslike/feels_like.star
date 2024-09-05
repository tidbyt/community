"""
Applet: Feels Like
Summary: A weather display
Description: An abstract weather display that communicates feeling in a natural way.
Author: eanplatter
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAX_COLOR_VALUE = 255
MAX_ROWS_S = 32
MAX_ROWS_L = 16
MAX_COLUMNS_S = 32
MAX_COLUMNS_L = 16
DEFAULT_ORIENTATION = "horizontal"
DEFAULT_SIZE = "s"
DEFAULT_API = None
DEFAULT_LAT = "40.730610"  # New York City
DEFAULT_LON = "-73.935242"  # New York City
DEFAULT_SPEED = 3
DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

def main(config):
    random.seed(time.now().unix // 30)
    API_KEY = config.get("api_key", DEFAULT_API)
    speed = DEFAULT_SPEED
    orientation = config.get("orientation", DEFAULT_ORIENTATION)
    size = config.get("size", DEFAULT_SIZE)
    shape = config.get("shape", "square")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)

    # Safely render without API key or location
    if API_KEY == None:
        return render.Root(
            child = render_rows([MAX_COLOR_VALUE, MAX_COLOR_VALUE, MAX_COLOR_VALUE], size, shape, DEFAULT_SPEED, 0, orientation),
        )

    url = "https://api.openweathermap.org/data/2.5/weather?lat={LAT}&lon={LON}&units=imperial&appid={API_KEY}".format(LAT = loc["lat"], LON = loc["lng"], API_KEY = API_KEY)
    weather_cached = cache.get("feels_like_weather_cache_{}_{}_{}".format(API_KEY, loc["lat"], loc["lng"]))
    if weather_cached != None:
        temp, precipitation, wind = [int(i) for i in weather_cached.split(",")]
    else:
        weather = http.get(url)
        if weather.status_code != 200:
            return render.Root(
                child = render_rows([MAX_COLOR_VALUE, MAX_COLOR_VALUE, MAX_COLOR_VALUE], size, shape, speed, 0, orientation),
            )
        weather_json = weather.json()
        temp = weather_json["main"]["feels_like"]
        wind = math.floor(weather_json["wind"]["speed"])
        precipitation = weather_json["rain"]["1h"] if "rain" in weather_json and "1h" in weather_json["rain"] else 0
        if wind < 3:
            speed = 3
        else:
            speed = wind

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("feels_like_weather_cache_{}_{}_{}".format(API_KEY, loc["lat"], loc["lng"]), "{},{},{}".format(int(temp), int(precipitation), int(wind)), ttl_seconds = 3600)

    return render.Root(
        child = render_rows(set_colors(math.floor(temp)), size, shape, speed, precipitation, orientation),
    )

def set_colors(temp):
    r = [i * 5 for i in range(50)]
    g = [i * 10 for i in range(30)]
    g = g + g[::-1]
    b = [MAX_COLOR_VALUE - (i * 4) for i in range(65)]

    color_map = []
    for i in range(120):
        red = r[i - 70] if i > 70 else 0
        green = g[i - 40] if i > 40 and i < 100 else 0
        blue = b[i] if i < 65 else 0
        color_map.append([red, green, blue])

    if temp < 0:
        return [0, 0, MAX_COLOR_VALUE]
    if temp > 99:
        return [MAX_COLOR_VALUE, 0, 0]
    return color_map[temp]

def create_hex_digits():
    hex_digit_pairs = []
    for i in range(MAX_ROWS_L):
        for j in range(MAX_ROWS_L):
            hex_digit_pairs.append(decimal_to_hex_single_digit(i) + decimal_to_hex_single_digit(j))
    return hex_digit_pairs

def decimal_to_hex_single_digit(decimal):
    if decimal < 10:
        return str(decimal)
    return chr(ord("a") + decimal - 10)

hex_digits = create_hex_digits()

def decimal_to_hex(decimal):
    return hex_digits[min(decimal, MAX_COLOR_VALUE)]

def render_rows(colors, size, shape, speed, precipitation, orientation):
    number_of_rows = MAX_ROWS_S if size == "s" else MAX_ROWS_L
    rows = [render.Row(children = render_columns(colors, size, shape, speed, precipitation, orientation)) for _ in range(number_of_rows)]
    return render.Column(children = rows)

def render_columns(colors, size, shape, speed, precipitation, orientation):
    number_of_columns = MAX_COLUMNS_S if size == "s" else MAX_COLUMNS_L
    columns = [
        render.Row(
            children = [
                render.Animation(render_node(random.number(0, colors[0]), random.number(0, colors[1]), random.number(0, colors[2]), size, shape, speed, precipitation, orientation)),
            ],
        )
        for _ in range(number_of_columns)
    ]
    return columns

def random_color(x, threshold):
    return math.floor((random.number(threshold, 10) / 10) * x)

def render_node(red, green, blue, size, shape, speed, precipitation, orientation):
    # Setting purple probability based on precipitation
    if precipitation == 0:  # No rain
        purple_probability = 0
    elif precipitation < 2.5:  # Light rain
        purple_probability = 0.1
    elif 2.5 <= precipitation and precipitation < 7.6:  # Moderate rain
        purple_probability = 0.2
    else:  # Heavy rain
        purple_probability = 0.3
    diameter = 4
    if size == "l":
        diameter = 8
    elif size == "s":
        diameter = 2
    unsorted_list = []
    frames = []
    for i in range(MAX_COLOR_VALUE):
        if i % speed == 0:
            unsorted_list.append(i + 1)

    random_starting_point = random.number(1, len(unsorted_list))
    last_half = unsorted_list[-random_starting_point:]
    first_half = unsorted_list[:-random_starting_point]
    sorted_list = last_half + list(reversed(last_half)) + list(reversed(first_half)) + first_half
    is_purple = random.number(0, 100) / 100.0 < purple_probability
    purple_shade = random.number(100, MAX_COLOR_VALUE)
    for x in sorted_list:
        if is_purple:
            purple_color = decimal_to_hex(purple_shade - x if purple_shade - x > 0 else 0)
            color = "#" + purple_color + "00" + purple_color
        else:
            r = abs(red - x)
            g = abs(green - x)
            b = abs(blue - x)
            if r > red:
                r = red
            if g > green:
                g = green
            if b > blue:
                b = blue
            color = "#" + decimal_to_hex(abs(r)) + decimal_to_hex(abs(g)) + decimal_to_hex(abs(b))

        node = render.Circle(diameter = diameter, color = color)
        if shape == "square":
            node = render.Box(height = diameter, width = diameter, color = color)
        elif shape == "rectangle":
            height_mod = 2
            width_mod = 2
            if orientation == "horizontal":
                height_mod = 1
                width_mod = 2
            elif orientation == "vertical":
                height_mod = 2
                width_mod = 1
            node = render.Box(height = diameter * height_mod, width = diameter * width_mod, color = color)
        frames.append(node)
    return frames

def more_options(shape):
    if shape == "rectangle":
        return [
            schema.Dropdown(
                id = "orientation",
                name = "Orientation",
                desc = "Orienation setting for rectangle shaped nodes.",
                icon = "arrows-rotate",
                default = orientation_options[1].value,
                options = orientation_options,
            ),
        ]
    else:
        return []

orientation_options = [
    schema.Option(
        display = "Horizontal",
        value = "horizontal",
    ),
    schema.Option(
        display = "Vertical",
        value = "vertical",
    ),
]

def get_schema():
    shape_options = [
        schema.Option(
            display = "Square",
            value = "square",
        ),
        schema.Option(
            display = "Circle",
            value = "circle",
        ),
        schema.Option(
            display = "Rectangle",
            value = "rectangle",
        ),
    ]

    size_options = [
        schema.Option(
            display = "Large",
            value = "l",
        ),
        schema.Option(
            display = "Medium",
            value = "m",
        ),
        schema.Option(
            display = "Small",
            value = "s",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location of where you want to feel the weather.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "Open Weathermap API Key",
                desc = "Api key from your personal Open Weathermap account",
                icon = "key",
            ),
            schema.Dropdown(
                id = "size",
                name = "Size",
                desc = "Size of the nodes.",
                icon = "downLeftAndUpRightToCenter",
                default = size_options[0].value,
                options = size_options,
            ),
            schema.Dropdown(
                id = "shape",
                name = "Shape",
                desc = "Shape of the nodes.",
                icon = "shapes",
                default = shape_options[1].value,
                options = shape_options,
            ),
            schema.Generated(
                id = "generated",
                source = "shape",
                handler = more_options,
            ),
        ],
    )
