"""
Applet: Surf Forecast
Summary: Daily surf forecast
Description: Daily surf forecast for any spot on Surfline.
Author: smith-kyle
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

SURFLINE_RATING_URL = "https://services.surfline.com/kbyg/spots/forecasts/rating?spotId={spot_id}&days=1&intervalHours=1&correctedWind=False"
SURFLINE_WAVE_URL = "https://services.surfline.com/kbyg/spots/forecasts/wave?spotId={spot_id}&days=1&intervalHours=1"
SURFLINE_WIND_URL = "https://services.surfline.com/kbyg/spots/forecasts/wind?spotId={spot_id}&days=1&intervalHours=1&corrected=False"
SURFLINE_QUERY_URL = "https://services.surfline.com/onboarding/spots?query={query}&limit=5&offset=0&camsOnly=false"

COLOR_BY_SURFLINE_RATING = {
    "FLAT": "#A2ACB9",
    "VERY_POOR": "#A2ACB9",
    "POOR": "#429CFF",
    "POOR_TO_FAIR": "#2FD2E8",
    "FAIR": "#18D64C",
    "FAIR_TO_GOOD": "#FFD100",
    "GOOD": "#FF8F00",
    "EPIC": "#DD452D",
}

COLORS = {
    "MAX_BAR": "#66b5fa",
    "MIN_BAR": "#0058b0",
    "BLACK": "#000000",
    "DAYLIGHT": "#ffffff28",
    "DUSK": "#ffffff22",
}

DEFAULT_SPOT = {
    "display": "Banyans",
    "value": "5842041f4e65fad6a770889d",
}

TIDBYT_WIDTH = 64
TIDBYT_HEIGHT = 32
FONT_BIG = "tb-8"
FONT_SMALL = "CG-pixel-3x5-mono"
DUSK_WIDTH = 1
LONG_CACHE_TTL = 60 * 60
SHORT_CACHE_TTL = 60 * 15

ICON_S = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAGCAYAAAAL+1RLAAAAAXNSR0IArs4c6QAAAClJREFUGFdjZICC/////2dkZGQEccEECBAWBKmAqYbRYO3IEiBzsZoJABkvGANjBbRdAAAAAElFTkSuQmCC")
ICON_SW = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAACpJREFUGFdjZEAD/////88IJhgZGUFyMDZcEFkSLAhSBVMNZsMEYUaDJAFiBBwCWd8MxQAAAABJRU5ErkJggg==")
ICON_W = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAYAAAAFCAYAAABmWJ3mAAAAAXNSR0IArs4c6QAAACVJREFUGFdjZICC/////2dkZGSE8cEMkCCIRpGACcJUEtaByw4ASr0UAvY3+sgAAAAASUVORK5CYII=")
ICON_NW = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAAClJREFUGFdj/P///38GJMAIAjBBEBsmBxaEScIk4IIgVTAFcC0wrSAJALtFHAJ+HdxnAAAAAElFTkSuQmCC")
ICON_N = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAGCAYAAAAL+1RLAAAAAXNSR0IArs4c6QAAACpJREFUGFdjZICC/////2dkZGQEccEESAAmCZJgRBaAS+DUDjMCxUx0QQAY2xgDTjk8gQAAAABJRU5ErkJggg==")
ICON_NE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAACtJREFUGFdNjEEKAAAIwtz/H20YGHWxlook2Xa0wz/6PBgAsNp4wO11/JoBWA8b9g+V3gQAAAAASUVORK5CYII=""")
ICON_E = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAYAAAAFCAYAAABmWJ3mAAAAAXNSR0IArs4c6QAAACdJREFUGFdjZEAC/////8/IyMgIEgITMACSAAuCAIyDrAC/Dlx2AADqrhQC9wOdGgAAAABJRU5ErkJggg==")
ICON_SE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAACdJREFUGFdj/P///39GRkZGBiQA5iBLgNkwBTAJFEGYDhAN145sJgABbhv21OuJ2wAAAABJRU5ErkJggg==")
ICONS_AND_DIRECTIONS = [
    (ICON_S, 0),
    (ICON_SW, 45),
    (ICON_W, 90),
    (ICON_NW, 135),
    (ICON_N, 180),
    (ICON_NE, 225),
    (ICON_E, 270),
    (ICON_SE, 315),
]

TIME_INDEXES = [1, 4, 7, 10, 13, 16, 19, 22]

def get_state(config):
    now = time.now()
    return {
        "now": now,
        "spot_id": get_spot_id_from_config(config),
        "display_name": get_display_name_from_config(config),
        "wave_response": get_wave_response(config),
        "rating_response": get_rating_response(config),
        "wind_response": get_wind_response(config),
    }

def get_spot_from_config(config):
    configured_spot = config.get("spot")
    if not configured_spot:
        return DEFAULT_SPOT
    return json.decode(configured_spot)

def get_spot_id_from_config(config):
    spot = get_spot_from_config(config)
    return spot["value"]

def get_display_name_from_config(config):
    display_name = config.str("display_name")
    if display_name:
        return display_name

    spot = get_spot_from_config(config)
    return spot["display"]

def get_display_name(state):
    return state["display_name"]

def get_lat(state):
    return state["wave_response"]["associated"]["location"]["lat"]

def get_lon(state):
    return state["wave_response"]["associated"]["location"]["lon"]

def get_sunrise_local(state):
    lat, lon = get_lat(state), get_lon(state)
    return sunrise.sunrise(lat, lon, state["now"])

def get_sunset_local(state):
    lat, lon = get_lat(state), get_lon(state)
    return sunrise.sunset(lat, lon, state["now"])

def get_utc_offset(state):
    wave = get_current_wave(state)
    return wave["utcOffset"]

def normalize_hour(hour):
    if hour > 24:
        return hour - 24
    if hour < 0:
        return 24 + hour
    return hour

def get_has_sunset(state):
    return (get_sunset_local(state) != None)

def get_has_sunrise(state):
    return (get_sunrise_local(state) != None)

def get_is_rise_before_set(state):
    has_sunset, has_sunrise = get_has_sunset(state), get_has_sunrise(state)
    if not has_sunrise or not has_sunset:
        return None
    rise_as_ratio_of_day = get_rise_as_ratio_of_day(state)
    set_as_ratio_of_day = get_set_as_ratio_of_day(state)
    return rise_as_ratio_of_day < set_as_ratio_of_day

def get_rise_as_ratio_of_day(state):
    sunrise_local = get_sunrise_local(state)
    utc_offset = get_utc_offset(state)
    return ((normalize_hour(sunrise_local.hour + utc_offset)) * 60 + sunrise_local.minute) / (24 * 60)

def get_set_as_ratio_of_day(state):
    sunset_local = get_sunset_local(state)
    utc_offset = get_utc_offset(state)
    return ((normalize_hour(sunset_local.hour + utc_offset)) * 60 + sunset_local.minute) / (24 * 60)

def get_sunlight_left_padding(state):
    rise_as_ratio_of_day = get_rise_as_ratio_of_day(state)
    return math.floor(TIDBYT_WIDTH * rise_as_ratio_of_day)

def get_sunlight_width(state):
    rise_as_ratio_of_day = get_rise_as_ratio_of_day(state)
    set_as_ratio_of_day = get_set_as_ratio_of_day(state)
    return math.floor(TIDBYT_WIDTH * (set_as_ratio_of_day - rise_as_ratio_of_day))

def get_first_light_width(state):
    set_as_ratio_of_day = get_set_as_ratio_of_day(state)
    return math.floor(TIDBYT_WIDTH * set_as_ratio_of_day)

def get_second_light_width(state):
    rise_as_ratio_of_day = get_rise_as_ratio_of_day(state)
    return math.floor(TIDBYT_WIDTH - (TIDBYT_WIDTH * rise_as_ratio_of_day))

def get_darkness_width(state):
    first_light_width = get_first_light_width(state)
    second_light_width = get_second_light_width(state)
    return TIDBYT_WIDTH - (first_light_width + second_light_width + DUSK_WIDTH * 2)

def get_all_wind(state):
    return state["wind_response"]["data"]["wind"]

def get_current_wind(state):
    all_wind = get_all_wind(state)
    now = state["now"]
    return get_most_current_element(all_wind, now)

def get_current_wind_icon(state):
    wind_direction = get_current_wind_direction(state)

    def distance_between(icon_and_direction):
        (_, d) = icon_and_direction
        return abs(wind_direction - d)

    closest_icon_and_direction = min(ICONS_AND_DIRECTIONS, key = distance_between)
    return closest_icon_and_direction[0]

def get_current_wind_direction(state):
    return get_current_wind(state)["direction"]

def get_current_wind_speed(state):
    return math.round(get_current_wind(state)["speed"])

def get_current_wind_direction_type(state):
    return get_current_wind(state)["directionType"]

def get_waves(state):
    all_waves = get_all_waves(state)
    return [all_waves[i] for i in TIME_INDEXES]

def get_all_waves(state):
    return state["wave_response"]["data"]["wave"]

def get_most_current_element(xs, now):
    xs_and_secs_since = [(x, (now - time.from_timestamp(int(x["timestamp"]))).seconds) for x in xs]
    return list(sorted(xs_and_secs_since, lambda w_a_s: abs(w_a_s[1])))[0][0]

def get_current_wave(state):
    now = state["now"]
    return get_most_current_element(get_all_waves(state), now)

def get_current_displayed_wave(state):
    now = state["now"]
    return get_most_current_element(get_waves(state), now)

def get_current_min_height(state):
    wave = get_current_wave(state)
    return wave["surf"]["min"]

def get_current_max_height(state):
    wave = get_current_wave(state)
    return wave["surf"]["max"]

def get_ratings(state):
    all_ratings = state["rating_response"]["data"]["rating"]
    return [all_ratings[i] for i in TIME_INDEXES]

def get_wave_ft_to_pixel(state):
    waves = get_waves(state)
    biggets_wave = max([w["surf"]["raw"]["max"] for w in waves])
    if biggets_wave < 12:
        return 2
    if biggets_wave < 18:
        return 1.5
    if biggets_wave < 24:
        return 1
    return .5

def get_top_bar_height(wave, wave_ft_to_pixel):
    min_height = wave["surf"]["raw"]["min"]
    max_height = wave["surf"]["raw"]["max"]
    scaled_bar_height = int(math.round((wave_ft_to_pixel * (max_height - min_height))))
    return max(1, scaled_bar_height)

def get_bottom_bar_height(wave, wave_ft_to_pixel):
    min_height = wave["surf"]["raw"]["min"]
    scaled_bar_height = int(math.round(min_height * wave_ft_to_pixel))
    return max(1, scaled_bar_height)

def get_rating_color(rating):
    return COLOR_BY_SURFLINE_RATING[rating["rating"]["key"]]

def get_bar_data(state):
    ratings = get_ratings(state)
    waves = get_waves(state)
    current_displayed_wave = get_current_displayed_wave(state)
    wave_ft_to_pixel = get_wave_ft_to_pixel(state)

    return [
        {
            "MAX_BAR_HEIGHT": get_top_bar_height(w, wave_ft_to_pixel),
            "MIN_BAR_HEIGHT": get_bottom_bar_height(w, wave_ft_to_pixel),
            "RATING_COLOR": get_rating_color(r),
            "IS_CURRENT": w == current_displayed_wave,
        }
        for r, w in zip(ratings, waves)
    ]

def main(config):
    state = get_state(config)
    return render.Root(
        child = render.Stack(
            children = [
                render_sunlight(state),
                render_bars(state),
                render_text_info(state),
            ],
        ),
    )

def render_text_info(state):
    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Column(
            cross_align = "center",
            main_align = "space_between",
            children = [
                render.Text(content = get_display_name(state), font = FONT_BIG),
                render.Padding(
                    pad = (0, 3, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        children = [
                            render_wave_height(state),
                            render_wind(state),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_wind(state):
    wind_speed = get_current_wind_speed(state)
    return render.Row(
        children = [
            render_wind_arrow(state),
            render.Text(
                content = ("%dkts" % (wind_speed)),
                font = FONT_SMALL,
            ),
        ],
    )

def render_wind_arrow(state):
    wind_icon = get_current_wind_icon(state)
    return render.Padding(
        pad = (0, 0, 1, 0),
        child = render.Image(src = wind_icon),
    )

def render_wave_height(state):
    min_height = get_current_min_height(state)
    max_height = get_current_max_height(state)
    return render.Text(
        content = ("%d-%dft" % (min_height, max_height)),
        font = FONT_SMALL,
    )

def render_sunlight(state):
    has_sunrise = get_has_sunrise(state)
    has_sunset = get_has_sunset(state)
    is_rise_before_set = get_is_rise_before_set(state)

    if not has_sunrise or not has_sunset:
        return None
    elif is_rise_before_set:
        return render_normal_sunlight(state)
    else:
        return render_weird_sunlight(state)

def render_normal_sunlight(state):
    sunlight_left_padding = get_sunlight_left_padding(state)
    sunlight_width = get_sunlight_width(state)
    return render.Padding(
        pad = (sunlight_left_padding, 0, 0, 0),
        child = render.Row(
            children = [
                render.Box(
                    height = TIDBYT_HEIGHT,
                    width = DUSK_WIDTH,
                    color = COLORS["DUSK"],
                ),
                render.Box(
                    height = TIDBYT_HEIGHT,
                    width = sunlight_width,
                    color = COLORS["DAYLIGHT"],
                ),
                render.Box(
                    height = TIDBYT_HEIGHT,
                    width = DUSK_WIDTH,
                    color = COLORS["DUSK"],
                ),
            ],
        ),
    )

def render_weird_sunlight(state):
    first_light_width = get_first_light_width(state)
    second_light_width = get_second_light_width(state)
    darkness_width = get_darkness_width(state)
    return render.Row(
        children = [
            render.Box(
                height = TIDBYT_HEIGHT,
                width = first_light_width,
                color = COLORS["DAYLIGHT"],
            ),
            render.Box(
                height = TIDBYT_HEIGHT,
                width = DUSK_WIDTH,
                color = COLORS["DUSK"],
            ),
            render.Box(
                height = TIDBYT_HEIGHT,
                width = darkness_width,
                color = COLORS["BLACK"],
            ),
            render.Box(
                height = TIDBYT_HEIGHT,
                width = DUSK_WIDTH,
                color = COLORS["DUSK"],
            ),
            render.Box(
                height = TIDBYT_HEIGHT,
                width = second_light_width,
                color = COLORS["DAYLIGHT"],
            ),
        ],
    )

def render_bars(state):
    return render.Padding(
        pad = (1, 0, 1, 0),
        child = render.Column(
            expanded = True,
            main_align = "end",
            children = [
                render.Row(
                    cross_align = "end",
                    main_align = "space_between",
                    expanded = True,
                    children = [render_bar(d) for d in get_bar_data(state)],
                ),
            ],
        ),
    )

def render_bar(data):
    if data["IS_CURRENT"]:
        return render_flashing_bar(data)

    return render.Column(
        cross_align = "center",
        children = [
            render.Box(width = 4, height = data["MAX_BAR_HEIGHT"], color = COLORS["MAX_BAR"]),
            render.Box(width = 4, height = data["MIN_BAR_HEIGHT"], color = COLORS["MIN_BAR"]),
            render.Box(width = 6, height = 2, color = data["RATING_COLOR"]),
        ],
    )

def render_flashing_bar(data):
    return render.Animation(
        children = [
            render.Column(
                cross_align = "center",
                children = [
                    render.Box(width = 4, height = data["MAX_BAR_HEIGHT"], color = transparent(COLORS["MAX_BAR"], p)),
                    render.Box(width = 4, height = data["MIN_BAR_HEIGHT"], color = transparent(COLORS["MIN_BAR"], p)),
                    render.Box(width = 6, height = 2, color = transparent(data["RATING_COLOR"], p)),
                ],
            )
            for p in get_animation_percentages()
        ],
    )

def get(url):
    rep = http.get(url)
    if rep.status_code != 200:
        fail("Surfline request failed with status %d", rep.status_code)
    return rep.json()

def get_response(url, cache_key, ttl_seconds):
    response_cached = cache.get(cache_key)
    if response_cached != None:
        return json.decode(response_cached)

    response = get(url)
    cache.set(cache_key, json.encode(response), ttl_seconds = ttl_seconds)
    return response

def get_wave_response(config):
    spot_id = get_spot_id_from_config(config)
    return get_response(SURFLINE_WAVE_URL.format(spot_id = spot_id), "wave_response" + spot_id, SHORT_CACHE_TTL)

def get_rating_response(config):
    spot_id = get_spot_id_from_config(config)
    return get_response(SURFLINE_RATING_URL.format(spot_id = spot_id), "rating_response" + spot_id, LONG_CACHE_TTL)

def get_wind_response(config):
    spot_id = get_spot_id_from_config(config)
    return get_response(SURFLINE_WIND_URL.format(spot_id = spot_id), "wind_response" + spot_id, SHORT_CACHE_TTL)

def get_animation_percentages():
    showing = [1 for _ in range(4)]
    dimming_out = [.1 * n for n in range(10, 2, -1)]
    dimming_in = [.1 * n for n in range(3, 11)]
    return showing + dimming_out + dimming_in

def transparent(color, p):
    hex_nums = [str(x) for x in range(10)] + ["a", "b", "c", "d", "e", "f"]
    two_digit_hex_nums = [x + y for x in hex_nums for y in hex_nums]
    res = color + two_digit_hex_nums[min(math.floor(p * len(two_digit_hex_nums)), 255)]
    return res

def search_handler(text):
    response = get(SURFLINE_QUERY_URL.format(query = text))
    return [schema.Option(display = s["name"], value = s["_id"]) for s in response["spots"]]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "spot",
                name = "Surfline spot",
                desc = "Find spot on Surfline",
                icon = "magnifyingGlass",
                handler = search_handler,
            ),
            schema.Text(
                id = "display_name",
                name = "Display Name",
                icon = "pencil",
                desc = "Optional spot name to display",
                default = "",
            ),
        ],
    )
