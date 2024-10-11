load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# nice-to-have:
# alternate colors for labels?
# Red "solaredge" / grey background banner at top
CACHE_TTL_SECONDS = 900
REGULAR_FONT = "tom-thumb"
DATETIME_FONT = "tb-8"
DEFAULT_TEXT_COLOR = "#dddddd"
DEFAULT_MEASURE_COLOR = "#00ff00"
MEASURE_FONT = "6x13"

LEFT_COL_SIZE = 31
RIGHT_COL_SIZE = 32

ANIMATION_FRAMES = 30
ANIMATION_HOLD_FRAMES = 75

DATA_BOX_BKG = "#000"
SLIDE_DURATION = 99

DATA_BOX_WIDTH = 64
DATA_BOX_HEIGHT = 20
TITLE_BOX_WIDTH = 64
TITLE_BOX_HEIGHT = 6
TITLE_BOX_BKG = "#222222"
TITLE_TEXT_COLOR = "#ff0000cc"

FOOTER_BOX_WIDTH = 64
FOOTER_BOX_HEIGHT = 6
FOOTER_BOX_BKG = "#111111"

WATT = "W"

V1DEMO_DATA = {
    "overview": {
        "lastUpdateTime": "2024-10-11 12:19:42",
        "lifeTimeData": {
            "energy": 7.01093E10,
        },
        "lastYearData": {
            "energy": 8447192.0,
        },
        "lastMonthData": {
            "energy": 240889.0,
        },
        "lastDayData": {
            "energy": 59918.0,
        },
        "currentPower": {
            "power": 9218.0,
        },
        "measuredBy": "INVERTER",
    },
}

def main(config):
    data = []
    if int(config.get("apiversion", "1")) == 1:
        data = v1api(config)

    widgetMode = config.bool("$widget", False)

    if data[11] == 200:
        return render.Root(
            max_age = CACHE_TTL_SECONDS * 2,
            show_full_animation = True,
            child = render.Column(
                children = [
                    titleBox(),
                    dataBox(data, widgetMode),
                    footerBox(data[10], data[12]),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                children = [
                    titleBox(),
                    render.WrappedText("{} ({})".format(data[11], data[12])),
                ],
            ),
        )

def titleBox():
    return render.Padding(
        pad = (0, 0, 0, 1),
        child = render.Box(
            width = TITLE_BOX_WIDTH,
            height = TITLE_BOX_HEIGHT,
            color = TITLE_BOX_BKG,
            child = render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text("solarEdge", font = REGULAR_FONT, color = TITLE_TEXT_COLOR),
            ),
        ),
    )

def footerBox(lastupdate, message):
    return render.Box(
        width = FOOTER_BOX_WIDTH,
        height = FOOTER_BOX_HEIGHT,
        color = FOOTER_BOX_BKG,
        child = render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Text("{}".format(lastupdate.format("Jan 2 3:04PM")[:-1] if message != "DEMO DATA" else message), font = REGULAR_FONT),
        ),
    )

def dataBox(data, widgetMode):
    return render.Row(
        expanded = True,
        children = [
            render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = "{}".format(data[2]), font = MEASURE_FONT, color = DEFAULT_MEASURE_COLOR, align = "center", width = LEFT_COL_SIZE), render.WrappedText(content = "{}Wh day".format(data[3]), font = REGULAR_FONT, color = DEFAULT_TEXT_COLOR, align = "center", width = LEFT_COL_SIZE)]),
            render.Box(width = 1, height = 18, color = "#333"),
            render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = "{}".format(data[0]), font = MEASURE_FONT, color = DEFAULT_MEASURE_COLOR, align = "center", width = RIGHT_COL_SIZE), render.WrappedText(content = "{}W now".format(data[3]), font = REGULAR_FONT, color = DEFAULT_TEXT_COLOR, align = "center", width = RIGHT_COL_SIZE)]) if widgetMode else fade_child(data[0], data[1], data[4], data[5], data[6], data[7], data[8], data[9]),
        ],
    )

def fade_child(now_power, now_unit, month_power, month_power_unit, year_power, year_power_unit, life_power, life_power_unit):
    return render.Animation(
        children =
            createfadelist(now_power, "{}W now".format(now_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, DEFAULT_TEXT_COLOR, DEFAULT_MEASURE_COLOR) +
            createfadelist(month_power, "{}Wh mnth".format(month_power_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, DEFAULT_TEXT_COLOR, DEFAULT_MEASURE_COLOR) +
            createfadelist(year_power, "{}Wh year".format(year_power_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, DEFAULT_TEXT_COLOR, DEFAULT_MEASURE_COLOR) +
            createfadelist(life_power, "{}Wh life".format(life_power_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, DEFAULT_TEXT_COLOR, DEFAULT_MEASURE_COLOR),
    )

def createfadelist(text, textline2, cycles, text_font, text_color, text_color2):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

    # use alpha channel to fade in and out

    # go from none to full color
    for x in alpha_values:
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color + x, text_color2 + x))
    for x in range(cycles):
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color, text_color2))

    # go from full color back to none
    for x in alpha_values[5:0]:
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color + x, text_color2 + x))
    return cycle_list

def fadelistchildcolumn(text, textline2, text_font, color, color2):
    return render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = "{}".format(text), font = MEASURE_FONT, color = color2, align = "center", width = RIGHT_COL_SIZE), render.WrappedText(content = "{}".format(textline2), font = text_font, color = color, align = "center", width = RIGHT_COL_SIZE)])

def v1api(config):
    #v1 api return codes
    #v1 documentation at: https://knowledge-center.solaredge.com/sites/kc/files/se_monitoring_api.pdf
    #403 security issue - key or site invalid
    #500 solaredge server issue
    #200 OK

    message = ""

    #before we go get the data - let's make sure we have an API key & Site ID
    if (config.get("apikey", "") == "" or config.get("siteid", "") == ""):
        # we don't have a key - so we're going to use the demo data
        json_data = V1DEMO_DATA
        status_code = 200
        message = "DEMO DATA"
    else:
        # go get the data
        url = "https://monitoringapi.solaredge.com/site/" + config.str("siteid", "none") + "/overview?api_key=" + config.str("apikey", "none")
        response = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
        status_code = response.status_code
        if response.status_code != 200:
            if response.status_code == 403:
                message = "Key or Site ID Error"
            else if response.status_code == 500:
                message = "SolarEdge API Server problem"
            return 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, status_code, message
        else:
            json_data = response.json()
            message = "OK"

    current_power, current_power_unit = convertFromWatts(json_data["overview"]["currentPower"]["power"])
    last_day_energy, lastDay_unit = convertFromWatts(json_data["overview"]["lastDayData"]["energy"])
    lastMonthData, lastMonth_unit = convertFromWatts(json_data["overview"]["lastMonthData"]["energy"])
    lastYearData, lastYear_unit = convertFromWatts(json_data["overview"]["lastYearData"]["energy"])
    lifeTimeData, lifeTime_unit = convertFromWatts(json_data["overview"]["lifeTimeData"]["energy"])
    lastupdate = time.parse_time(json_data["overview"]["lastUpdateTime"], format = "2006-01-02 15:04:05")

    return current_power, current_power_unit, last_day_energy, lastDay_unit, lastMonthData, lastMonth_unit, lastYearData, lastYear_unit, lifeTimeData, lifeTime_unit, lastupdate, status_code, message

def convertFromWatts(value):
    if value > 1000000000:
        return toGW(value), "G"
    else if value > 1000000:
        return toMW(value), "M"
    else if value > 1000:
        return toKW(value), "K"

    return value, ""

def toKW(value):
    # 1 decimal point only
    return (math.round(value / 100) / 10)

def toMW(value):
    # 1 decimal point only
    return (math.round(value / 100000) / 10)

def toGW(value):
    # no decimal points
    return (math.round(value / 100000000) / 10)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            # this is in here for now - eventually we will add API v2 and allow users to go back & forth
            schema.Dropdown(
                id = "apiversion",
                name = "APIVersion",
                desc = "Select which API Version",
                icon = "hashtag",
                default = "1",
                options = [
                    schema.Option(
                        display = "API v1",
                        value = "1",
                    ),  #,
                    # we don't support v2 yet, but stub it out here for now
                    #schema.Option(
                    #    display = "API v1",
                    #    value = "1",
                    #)
                    #
                ],
            ),
            schema.Text(
                id = "siteid",
                name = "Site ID",
                desc = "Can be found in the mobile app under Site Details",
                icon = "eye",
            ),
            schema.Generated(
                id = "apiversion_key",
                source = "apiversion",
                handler = show_apikey_options,
            ),
        ],
    )

def show_apikey_options(apiversion):
    if apiversion == "1":
        return [
            schema.Text(
                id = "apikey",
                name = "v1 API KEY",
                desc = "Contact your solar installer if necessary to obtain an API key",
                icon = "key",
            ),
        ]
    else:
        return [
            schema.Text(
                id = "apikey",
                name = "v2 User KEY",
                desc = "Contact your solar installer if necessary to obtain an API key",
                icon = "key",
            ),
        ]
