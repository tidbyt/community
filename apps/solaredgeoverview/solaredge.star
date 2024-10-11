load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("math.star", "math")
load("time.star", "time")

# we shouldn't need these with proper handling??

# TODO: Uncomment these before PR
#API_KEY = "XXXXXX"
#SITE_ID = "XXXX"

# TODO: DEMO ONLY - Remove before PR


# to-do:
# handle missing key
# limit calls to every 10 minutes

# nice-to-have:
# alternate colors for labels?
# Red "solaredge" / grey background banner at top
REGULAR_FONT = "tom-thumb"
DATETIME_FONT = "tb-8"
DEFAULT_TEXT_COLOR = "#ffffff"
MEASURE_COLOR = "#00ff00aa"
MEASURE_FONT = "6x13"

LEFT_COL_SIZE = 27
RIGHT_COL_SIZE = 36

ANIMATION_FRAMES = 30
ANIMATION_HOLD_FRAMES = 75

DATA_BOX_BKG = "#000"
SLIDE_DURATION = 99

DATA_BOX_WIDTH = 64
DATA_BOX_HEIGHT = 20
TITLE_BOX_WIDTH = 64
TITLE_BOX_HEIGHT = 6
TITLE_BOX_BKG = "#333333"
TITLE_TEXT_COLOR = "#ff0000cc"

FOOTER_BOX_WIDTH = 64
FOOTER_BOX_HEIGHT = 6
FOOTER_BOX_BKG = "#111111"

WATT = "W"
KILOWATTHOURS = "KWh"
MEGAWATTHOURS = "MWh"
GIGAWATTHOURS = "GWh"

V1DEMO_DATA = {
    "overview": {
        "lastUpdateTime": "2024-10-11 12:19:42", 
        "lifeTimeData": {
            "energy": 7.01093E10
        }, 
        "lastYearData": {
            "energy": 8447192.0
        }, 
        "lastMonthData": {
            "energy": 240889.0
        }, 
        "lastDayData": {
            "energy": 6918.0
        }, 
        "currentPower": {
            "power": 1218.0
        },
        "measuredBy": "INVERTER"
    }
}

def main(config):
    if int(config.get("apiversion", "1")) == 1:
        print("v1 api")

    data = v1api(config)

    return render.Root(
        render.Column(
            children = [
                titleBox(),
                dataBox(data),
                footerBox(data[8]),
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

def footerBox(lastupdate):
    return render.Box(
        width = FOOTER_BOX_WIDTH,
        height = FOOTER_BOX_HEIGHT,
        color = FOOTER_BOX_BKG,
        child = render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Text("{}".format(lastupdate.format("Jan 2 3:04PM")[:-1]), font = REGULAR_FONT),
        ),
    )

def dataBox(data):
    return render.Row(
        expanded = True,
        children = [
            render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = "{}".format(data[0]), font = MEASURE_FONT, color = MEASURE_COLOR, align = "center", width = LEFT_COL_SIZE), render.WrappedText(content = "{} now".format(data[1]), font = REGULAR_FONT, color = DEFAULT_TEXT_COLOR, align = "center", width = LEFT_COL_SIZE)]),
            #render.Box(width = 27, height = 20, child = render.WrappedText("{}\n{} now".format(current_power, current_power_unit), font = REGULAR_FONT, align = "center", width = 27)),
            render.Box(width = 1, height = 18, color = "#333"),
            #render.Box(width = 36, height = 20, child = render.WrappedText("{}\nkWh year".format(last_day_energy), font = REGULAR_FONT, align = "center", width = 36)),
            #render.Box(width = 1, height = 19, color = "#333"),
            #render.Box(width = 21, height = 20, child = render.WrappedText("Life\n{}\nMWh".format(lifeTimeData), font = REGULAR_FONT, align = "center", width = 21))
            fade_child(data[2], "KWh", data[3], data[4], data[5], data[6], data[7]),
        ],
    )

def fade_child(day_power, day_unit, month_power, month_power_unit, year_power, life_power, life_power_unit):
    return render.Animation(
        children =
            createfadelist(day_power, "{} day".format(day_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, "#dddddd") +
            createfadelist(month_power, "{} month".format(month_power_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, "#dddddd") +
            createfadelist(year_power, "MWh year", ANIMATION_HOLD_FRAMES, REGULAR_FONT, "#dddddd") +
            createfadelist(life_power, "{} life".format(life_power_unit), ANIMATION_HOLD_FRAMES, REGULAR_FONT, "#dddddd"),
    )

def createfadelist(text, textline2, cycles, text_font, text_color):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

    # use alpha channel to fade in and out

    # go from none to full color
    for x in alpha_values:
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color + x))
    for x in range(cycles):
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color))

    # go from full color back to none
    for x in alpha_values[5:0]:
        cycle_list.append(fadelistchildcolumn(text, textline2, text_font, text_color + x))
    return cycle_list

def fadelistchildcolumn(text, textline2, font, color):
    return render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = "{}".format(text), font = MEASURE_FONT, color = MEASURE_COLOR, align = "center", width = RIGHT_COL_SIZE), render.WrappedText(content = "{}".format(textline2), font = REGULAR_FONT, color = DEFAULT_TEXT_COLOR, align = "center", width = RIGHT_COL_SIZE)])

def v1api(config):
    #v1 api return codes
    #v1 documentation at: https://knowledge-center.solaredge.com/sites/kc/files/se_monitoring_api.pdf
    #403 security issue - key or site invalid
    #500 solaredge server issue
    #200 OK

    #before we go get the data - let's make sure we have an API key & Site ID
    if (config.get("apikey", "") == "" or config.get("siteid", "") == ""):
        # we don't have a key - so we're going to use the demo data
        json_data = V1DEMO_DATA

    else:
        # go get the data
        url = "https://monitoringapi.solaredge.com/site/" + config.str("siteid", "none") + "/overview?api_key=" + config.str("apikey", "none")
        response = http.get(url)
        if response.status_code != 200:
            result = "oops"
        else:
            # code in here to return error message if something is wrong depending on HTTP return code
            result = "good!"
        json_data = response.json()

    current_power = int(json_data["overview"]["currentPower"]["power"])
    current_power_unit = WATT
    if current_power > 1000:
        current_power = math.round(int(current_power) / 100) / 10
        current_power_unit = KILOWATTHOURS[:-1]  # strip off the h - current power is just meausured in G/M/K watts

    # convert to kWh already
    last_day_energy = toKW(json_data["overview"]["lastDayData"]["energy"])

    lastMonth_unit = KILOWATTHOURS
    lastMonthData = toKW(json_data["overview"]["lastMonthData"]["energy"])
    if lastMonthData > 1000:
        print("month to gw")
        lastMonthData = toMW(json_data["overview"]["lastMonthData"]["energy"])
        lastMonth_unit = MEGAWATTHOURS

    # convert to MWh
    lastYearData = toMW(json_data["overview"]["lastYearData"]["energy"])
    lifeTime_unit = MEGAWATTHOURS
    lifeTimeData = int(toMW(json_data["overview"]["lifeTimeData"]["energy"]))

    if lifeTimeData > 1000:
        lifeTimeData = math.round(int(lifeTimeData) / 100) / 10
        lifeTime_unit = GIGAWATTHOURS
    lastupdate = time.parse_time(json_data["overview"]["lastUpdateTime"], format = "2006-01-02 15:04:05")

    return current_power, current_power_unit, last_day_energy, lastMonthData, lastMonth_unit, lastYearData, lifeTimeData, lifeTime_unit, lastupdate

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
