"""
Applet: Index Ticker
Summary: Displays ticker for indices
Description: Display ticker and stats for stock indices.
Author: M0ntyP

v1.1 - Added BSE and NIFTY indices
v1.2 - Added toggle for showing % change or pts change
v1.3 - Added NIKKEI, Europe 350, Global 100, Global 1200, NZX50 indices; support null indicator values in chart
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

COLOR_BITCOIN = "#ffa500"
COLOR_RED = "#f00"
COLOR_GREEN = "#0f0"
COLOR_DIMMED = "#fff9"

FONT = "tom-thumb"

INDEX_PREFIX = "https://query1.finance.yahoo.com/v8/finance/chart/%5E"
INDEX_SUFFIX = "?metrics=high?&interval="

INDEX_MAP = {
    "axjo": "ASX 200",
    "dji": "Dow Jones",
    "speup": "Europe 350",
    "spg100": "Global 100",
    "spg1200": "Global 1200",
    "ixic": "NASDAQ",
    "n225": "NIKKEI",
    "nz50": "NZX 50",
    "ftse": "FTSE",
    "gspc": "S&P 500",
    "BSESN": "BSE",
    "NSEI": "NIFTY",
}

def main(config):
    IndexSelection = config.get("Index", "axjo")
    RangeSelection = config.get("Range", "5m&range=1d")
    DisplaySelection = config.get("DiffDisplay", "true")
    Interval = "1D"

    #print(IndexSelection)
    INDEX_URL = INDEX_PREFIX + IndexSelection + INDEX_SUFFIX + RangeSelection
    # print(INDEX_URL)

    CacheData = get_cachable_data(INDEX_URL, 60)
    INDEX_JSON = json.decode(CacheData)
    DiffColor = "#00ff00"

    TotalTicks = len(INDEX_JSON["chart"]["result"][0]["indicators"]["quote"][0]["close"])
    LastClose = INDEX_JSON["chart"]["result"][0]["meta"]["chartPreviousClose"]
    Current = INDEX_JSON["chart"]["result"][0]["meta"]["regularMarketPrice"]

    PointsDiff = Current - LastClose
    PercentDiff = PointsDiff / LastClose
    StrPercentDiff = str(int(math.round(PercentDiff * 10000)))

    # if % greater than 0
    # elif % between 0 and -1
    # elif % less than 0

    if PercentDiff > 0:
        StrPercentDiff = (StrPercentDiff[0:-2] + "." + StrPercentDiff[-2:])
    elif PercentDiff > -0.01:
        StrPercentDiff = StrPercentDiff.replace("-", "-0")
        StrPercentDiff = (StrPercentDiff[0:-2] + "." + StrPercentDiff[-2:])
    elif PercentDiff < 0:
        StrPercentDiff = (StrPercentDiff[0:-2] + "." + StrPercentDiff[-2:])

    if StrPercentDiff.startswith("."):
        StrPercentDiff = "0" + StrPercentDiff
        DiffColor = "#00ff00"
    elif StrPercentDiff.startswith("-"):
        StrPercentDiff = StrPercentDiff[1:]
        StrPercentDiff = "-" + StrPercentDiff
        DiffColor = "#f00"

    if RangeSelection == "5m&range=1d":
        Interval = "1D"
    elif RangeSelection == "30m&range=5d":
        Interval = "5D"
    elif RangeSelection == "90m&range=1mo":
        Interval = "1M"
    elif RangeSelection == "1d&range=6mo":
        Interval = "6M"
    elif RangeSelection == "1d&range=1y":
        Interval = "1Y"
    elif RangeSelection == "1wk&range=ytd":
        Interval = "YTD"

    if DisplaySelection == "true":
        StrPercentDiff = StrPercentDiff + "%"
        DisplayDiff = StrPercentDiff
    else:
        DisplayDiff = str(PointsDiff)[:6]

    return render.Root(
        child = render.Column(
            expanded = True,
            children = [
                print_market(Current, DisplayDiff, DiffColor, IndexSelection, Interval),
                print_chart(INDEX_JSON, TotalTicks, LastClose, Interval),
            ],
        ),
    )

def print_chart(INDEX_JSON, TotalTicks, LastClose, Interval):
    TickList = []
    TickIndex = []
    Data = []

    previous_tick = LastClose

    for i in range(TotalTicks):
        CurrentTick = INDEX_JSON["chart"]["result"][0]["indicators"]["quote"][0]["close"][i]

        if CurrentTick == None:
            CurrentTick = previous_tick
        else:
            previous_tick = CurrentTick

        TickList.append(CurrentTick)
        TickIndex.append(i)

        Percentage_Change = (CurrentTick - LastClose) / LastClose * 100
        DataElement = TickIndex[i], Percentage_Change
        Data.append(DataElement)

    ChartWidth = min(len(Data), 64)

    if Interval == "YTD":
        ChartWidth = int(ChartWidth * 1.23)

    return render.Stack(
        children = [
            render.Plot(
                data = Data,
                width = ChartWidth,
                height = 20,
                color = COLOR_GREEN,
                color_inverted = COLOR_RED,
                fill = True,
            ),
            animation.Transformation(
                child = render.Box(
                    width = 64,
                    height = 20,
                    color = "#000",
                ),
                duration = 1500,
                delay = 0,
                origin = animation.Origin(0, 0),
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [animation.Translate(64, 0)],
                    ),
                    animation.Keyframe(
                        percentage = 0.001,
                        transforms = [animation.Translate(0, 0)],
                    ),
                    animation.Keyframe(
                        percentage = 0.042,
                        transforms = [animation.Translate(64, 0)],
                    ),
                    animation.Keyframe(
                        percentage = 1.0,
                        transforms = [animation.Translate(64, 0)],
                    ),
                ],
            ),
        ],
    )

def print_market(Current, DisplayDiff, DiffColor, IndexSelection, Interval):
    Title = getTitle(IndexSelection).upper()
    return render.Column(
        children = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Text(
                        content = Title,
                        font = FONT,
                        color = COLOR_BITCOIN,
                    ),
                    render.Text(
                        content = Interval,
                        font = FONT,
                    ),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Text(
                        content = str(Current),
                        font = FONT,
                    ),
                    render.Text(
                        content = DisplayDiff,
                        font = FONT,
                        color = DiffColor,
                    ),
                ],
            ),
        ],
    )

def getTitle(IndexSelection):
    return INDEX_MAP.get(IndexSelection, "")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "Index",
                name = "Index",
                desc = "Choose your index",
                icon = "dollarSign",
                default = IndexOptions[0].value,
                options = IndexOptions,
            ),
            schema.Dropdown(
                id = "Range",
                name = "Range",
                desc = "Choose your range",
                icon = "calendarDays",
                default = RangeOptions[0].value,
                options = RangeOptions,
            ),
            schema.Toggle(
                id = "DiffDisplay",
                name = "Percentage or Points",
                desc = "Toggle % or pts",
                icon = "toggleOn",
                default = True,
            ),
        ],
    )

IndexOptions = [
    schema.Option(display = title, value = value)
    for value, title in INDEX_MAP.items()
]

RangeOptions = [
    schema.Option(
        display = "1 day",
        value = "5m&range=1d",
    ),
    schema.Option(
        display = "5 days",
        value = "30m&range=5d",
    ),
    schema.Option(
        display = "1 month",
        value = "90m&range=1mo",
    ),
    schema.Option(
        display = "6 months",
        value = "1d&range=6mo",
    ),
    schema.Option(
        display = "1 year",
        value = "1d&range=1y",
    ),
    schema.Option(
        display = "YTD",
        value = "1wk&range=ytd",
    ),
]

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout, headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
    })

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
