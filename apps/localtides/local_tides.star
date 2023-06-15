"""
Applet: Local Tides
Summary: Local tides graph
Description: Display local tides graph and time of next two tide events.
Author: J. Keybl
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    # Define constants
    DEBUG = False
    DEFAULT_LOCATION = {
        "lat": 38.8951,
        "lng": -77.0364,
        "locality": "Washington, D.C.",
        "timezone": "America/New_York",
    }
    TTL_SECONDS = 60
    TIMECOLOR = "#ffffcc"
    TIDECOLOR = "#ffaa00"
    LINECOLOR = "#3399ff"
    FILLCOLOR = "#99ccff"
    VIEWPORT_WIDTH = 64
    AMPL = 14
    TEXT_FONT = "CG-pixel-3x5-mono"
    FONT_HEIGHT = 5
    N_INPUT_PTS = 72  # 24 per day
    N_GRAPH_PTS = 24
    N_HL_PTS = 12  # 4 per day
    TIME_ROW = 0
    GRAPH_ROW = TIME_ROW + FONT_HEIGHT + 1
    HL1_ROW = GRAPH_ROW + AMPL
    HL2_ROW = HL1_ROW + FONT_HEIGHT + 1
    HL1_ROW_HEIGHT = FONT_HEIGHT + 1
    HL2_ROW_HEIGHT = FONT_HEIGHT + 1

    # Initialize variables
    station = config.str("Station", "8594900")  # Washington, D.C.
    location = config.get("location")
    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    timezone = loc["timezone"]
    t_hl = []
    t_hl_s = []
    v_hl = []
    tp_hl = []
    t_h = []
    t_h_s = []
    v_h = []
    arr = []
    hl_string1 = ""
    hl_string2 = ""
    idx = 0
    high_low_fail = False
    hourly_fail = False
    now = time.now().in_location("UTC")

    start_date, end_date = get_start_end_dates(now)
    if DEBUG:
        print(start_date, end_date)

    high_low_url = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?begin_date=" + str(start_date) + "&end_date=" + str(end_date) + "&station=" + station + "&product=predictions&datum=MLLW&time_zone=gmt&interval=hilo&units=english&application=TidesData" + station + "&format=json"
    high_low = http.get(high_low_url, ttl_seconds = TTL_SECONDS)

    if high_low.status_code != 200:  # Status code of 200 means a response was received for the request
        high_low_fail = True
        if DEBUG:
            print("High/low request did not return a response!")
    elif "error" in high_low.json():
        high_low_fail = True
    else:
        high_low_fail = False
        for x in range(N_HL_PTS):
            t_hl_s.append(high_low.json()["predictions"][x]["t"])
            t_hl.append(NOAA_date_to_UTC_date(t_hl_s[x]))
            v_hl.append(float(high_low.json()["predictions"][x]["v"]))
            tp_hl.append(high_low.json()["predictions"][x]["type"])
            if DEBUG:
                print("H/L: ", x, t_hl_s[x], t_hl[x], v_hl[x], tp_hl[x])

    hourly_url = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?begin_date=" + str(start_date) + "&end_date=" + str(end_date) + "&station=" + station + "&product=predictions&datum=MLLW&time_zone=gmt&interval=h&units=english&application=TideData" + station + "&format=json"
    hourly = http.get(hourly_url, ttl_seconds = TTL_SECONDS)

    if hourly.status_code != 200:
        hourly_fail = True
        if DEBUG:
            print("Hourly request did not return a response!")
    elif "error" in hourly.json():
        hourly_fail = True
    else:
        hourly_fail = False
        for x in range(N_INPUT_PTS):
            t_h_s.append(hourly.json()["predictions"][x]["t"])
            t_h.append(NOAA_date_to_UTC_date(t_h_s[x]))
            v_h.append(float(hourly.json()["predictions"][x]["v"]))
            if DEBUG:
                print("HOURLY: ", x, t_h[x], v_h[x])

    if DEBUG:
        print("High/low fail: ", high_low_fail, "Hourly fail: ", hourly_fail)

    if high_low_fail == True:
        hl_string1 = "No data"
        hl_string2 = ""
    else:
        # Determine when the next 2 high/low times are based on current time
        for x in range(N_GRAPH_PTS - 1):
            if now > t_hl[x] and now <= t_hl[x + 1]:
                if tp_hl[x + 1] == "H":
                    hl_string = "H "
                else:
                    hl_string = "L "
                hl_string1 = hl_string + humanize.time_format("K:mm aa", t_hl[x + 1].in_location(timezone))
                if tp_hl[x + 2] == "H":
                    hl_string = "H "
                else:
                    hl_string = "L "
                hl_string2 = hl_string + humanize.time_format("K:mm aa", t_hl[x + 2].in_location(timezone))
                break

    if hourly_fail == True:
        if DEBUG:
            print("Using canned data")

        for x in range(N_GRAPH_PTS):
            arr.append((x, 1))
    else:
        # Normalize the NOAA v_h data based on the max at high tides from v_hl

        # Find the starting index based on current time
        for x in range(N_INPUT_PTS - 1):
            if now > t_h[x] and now <= t_h[x + 1]:
                idx = x
                break

        # Determine the max water level value for the next 24 hours to show relative heights during this period
        v_max = 0
        for x in range(idx, idx + N_GRAPH_PTS):
            if v_h[x] > v_max:
                v_max = v_h[x]

        # Create and normalize the output array
        for x in range(N_GRAPH_PTS):
            ampl = math.round(AMPL * (v_h[x + idx] / v_max))
            arr.append((x, ampl))
            if DEBUG:
                print(x, ampl)

    if DEBUG:
        print("")
        print("")

    # Render the plot
    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, TIME_ROW, 0, 0),
                    child = render.Box(
                        width = VIEWPORT_WIDTH,
                        height = FONT_HEIGHT,
                        child = render.WrappedText(
                            content = humanize.time_format("K:mm aa", now.in_location(timezone)),
                            font = TEXT_FONT,
                            color = TIMECOLOR,
                            align = "right",
                            width = VIEWPORT_WIDTH,
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, GRAPH_ROW, 0, 0),
                    child = render.Box(
                        width = VIEWPORT_WIDTH,
                        height = AMPL,
                        child = render.Plot(
                            data = arr,
                            width = VIEWPORT_WIDTH,
                            height = AMPL,
                            x_lim = (0, N_GRAPH_PTS - 1),
                            y_lim = (0, AMPL),
                            fill = True,
                            color = LINECOLOR,
                            fill_color = FILLCOLOR,
                            fill_color_inverted = FILLCOLOR,
                            chart_type = "line",
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, HL1_ROW, 0, 0),
                    child = render.Box(
                        width = VIEWPORT_WIDTH,
                        height = HL1_ROW_HEIGHT,
                        child = render.WrappedText(
                            content = hl_string1,
                            font = TEXT_FONT,
                            color = TIDECOLOR,
                            align = "left",
                            width = VIEWPORT_WIDTH,
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, HL2_ROW, 0, 0),
                    child = render.Box(
                        width = VIEWPORT_WIDTH,
                        height = HL2_ROW_HEIGHT,
                        child = render.WrappedText(
                            content = hl_string2,
                            font = TEXT_FONT,
                            color = TIDECOLOR,
                            align = "right",
                            width = VIEWPORT_WIDTH,
                        ),
                    ),
                ),
            ],
        ),
    )

def get_start_end_dates(now):
    date_str = humanize.time_format("yyyy-MM-dd HH:mm", now)  # UTC time
    hr = int(date_str[11:13])
    mn = int(date_str[14:16])
    yr = int(date_str[0:4])
    mo = int(date_str[5:7])
    dy = int(date_str[8:10])
    b = time.time(year = yr, month = mo, day = dy, hour = (hr - 24), minute = mn)  # UTC time
    e = time.time(year = yr, month = mo, day = dy, hour = (hr + 48), minute = mn)  # UTC time
    start_date = humanize.time_format("yyyyMMdd", b)
    end_date = humanize.time_format("yyyyMMdd", e)

    return start_date, end_date

def NOAA_date_to_UTC_date(date_str):
    hr = int(date_str[11:13])
    mn = int(date_str[14:16])
    yr = int(date_str[0:4])
    mo = int(date_str[5:7])
    dy = int(date_str[8:10])
    dt = time.time(year = yr, month = mo, day = dy, hour = hr, minute = mn)

    return (dt)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "Station",
                name = "Station ID",
                desc = "Enter station ID",
                icon = "locationCrosshairs",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time",
            ),
        ],
    )
