load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

#SCHEMA

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time",
                icon = "locationDot",
            ),
            schema.Text(
                id = "weatherkey",
                name = "Weatherstack API Key",
                desc = "Get key at weatherstack.com",
                icon = "cloud",
            ),
            schema.Toggle(
                id = "weatherpaid",
                name = "Weatherstack API Paid",
                desc = "Use paid weatherstack.com subscription to allow display of forecasts",
                icon = "cloudRain",
                default = False,
            ),
            schema.Toggle(
                id = "showlife",
                name = "Show Life Bar",
                desc = "Display bar optimistically approximating progress through life",
                icon = "skullCrossbones",
                default = False,
            ),
            schema.Text(
                id = "birthyear",
                name = "Birth Year",
                desc = "Year used to estimate progress through life",
                icon = "baby",
                default = "1990",
            ),
            schema.Toggle(
                id = "showmoon",
                name = "Show Moon Phase",
                desc = "Display phase of the moon for each day of the month",
                icon = "moon",
                default = True,
            ),
            schema.Toggle(
                id = "showsun",
                name = "Show Sun Rise and Set",
                desc = "Display bar showing sunrise and set relative to current hour",
                icon = "sun",
                default = True,
            ),
            schema.Toggle(
                id = "showminute",
                name = "Show Minute Dot",
                desc = "Display dot walking across the bottom corresponding to minute of the hour",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "showsecond",
                name = "Show Second Dot",
                desc = "Display dot corresponding to second of the minute",
                icon = "stopwatch",
                default = True,
            ),
            schema.Toggle(
                id = "dialsecond",
                name = "Second Dot Rotates",
                desc = "Display second dot rotating around the clock rather than walking across the bottom",
                icon = "rotate",
                default = False,
            ),
        ],
    )

#/SCHEMA

#UTILS

def drawrect(x, y, w, h, c):
    if w <= 0:
        return render.Box(width = 1, height = 1)
    if h <= 0:
        return render.Box(width = 1, height = 1)
    if x == 0:
        if y == 0:
            return render.Box(width = w, height = h, color = c)
        else:
            return render.Column(
                children = [
                    render.Box(width = 1, height = y),
                    render.Box(width = w, height = h, color = c),
                ],
            )
    if y == 0:
        return render.Row(
            children = [
                render.Box(width = x, height = 1),
                render.Box(width = w, height = h, color = c),
            ],
        )
    return render.Column(
        children = [
            render.Box(width = 1, height = y),
            render.Row(
                children = [
                    render.Box(width = x, height = 1),
                    render.Box(width = w, height = h, color = c),
                ],
            ),
        ],
    )

def drawrectcoords(x0, y0, x1, y1, c):
    return drawrect(x0, y0, x1 - x0, y1 - y0, c)

def drawtext(x, y, text):
    if text == "":
        return render.Box(width = 1, height = 1)
    if x == 0:
        if y == 0:
            return render.Row(
                children = [
                    render.Text(text),
                ],
            )
        else:
            return render.Column(
                children = [
                    render.Box(width = 1, height = y),
                    render.Row(
                        children = [
                            render.Text(text),
                        ],
                    ),
                ],
            )
    if y == 0:
        return render.Row(
            children = [
                render.Box(width = x, height = 1),
                render.Text(text),
            ],
        )
    return render.Column(
        children = [
            render.Box(width = 1, height = y),
            render.Row(
                children = [
                    render.Box(width = x, height = 1),
                    render.Text(text),
                ],
            ),
        ],
    )

def drawrtext(x, y, text):
    if text == "":
        return render.Box(width = 1, height = 1)
    x = x + 2
    if x >= 64:
        if y == 0:
            return render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Text(text),
                ],
            )
        else:
            return render.Column(
                children = [
                    render.Box(width = 1, height = y),
                    render.Row(
                        expanded = True,
                        main_align = "end",
                        children = [
                            render.Text(text),
                        ],
                    ),
                ],
            )
    if y == 0:
        return render.Row(
            expanded = True,
            main_align = "end",
            children = [
                render.Text(text),
                render.Box(width = 64 - x, height = 1),
            ],
        )
    return render.Column(
        children = [
            render.Box(width = 1, height = y),
            render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Text(text),
                    render.Box(width = 64 - x, height = 10),
                ],
            ),
        ],
    )

def drawimg(x, y, img):
    if x == 0:
        if y == 0:
            return render.Image(src = img)
        else:
            return render.Column(
                children = [
                    render.Box(width = 1, height = y),
                    render.Image(src = img),
                ],
            )
    if y == 0:
        return render.Row(
            children = [
                render.Box(width = x, height = 1),
                render.Image(src = img),
            ],
        )
    return render.Column(
        children = [
            render.Box(width = 1, height = y),
            render.Row(
                children = [
                    render.Box(width = x, height = 1),
                    render.Image(src = img),
                ],
            ),
        ],
    )

#/UTILS

#STATIC

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
WEATHERURLPRE = "http://api.weatherstack.com/forecast?access_key="
WEATHERURLPOSTWEEK = "&forecast_days=7"
WEATHERURLPOSTDAY = "&forecast_days=1&hourly=1&interval=1"
WEATHERURLFREE = "http://api.weatherstack.com/current?access_key="
LUNATION = 2551443  # lunar cycle in seconds (29 days 12 hours 44 minutes 3 seconds)
REF_NEWMOON = time.parse_time("30-Apr-2022 20:28:00", format = "02-Jan-2006 15:04:05").unix
MONTHSTRS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
MONTHSEASON = [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4]
DAYSOFMONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
WEEKDAYSTRS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
WEATHERICON_CLEAR = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHklEQVR42mP4/5+hAYj/Q3EDAwggCYAxXkFM7dgAAK7ULdUdcihQAAAAAElFTkSuQmCC")
WEATHERICON_PARTLYCLOUDY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAKElEQVR42mP4/5+hAYj/Q3EDAwhAOEBxKIAKIgTgEv+xAKhqOACbCQBJmUw3DPvOEwAAAABJRU5ErkJggg==")
WEATHERICON_CLOUDY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAH0lEQVR42mNgwAX+///f8B8KMATgEv+xAJhqGGgA8QExCz5EHxiM1gAAAABJRU5ErkJggg==")
WEATHERICON_PRECIPITATION = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAALElEQVR42mNgAIL///83/IcCBnQBuMR/LACsur4ewgkN/X+AAQL+N6DSDAwAMd8/LpL83qAAAAAASUVORK5CYII=")

#/STATIC

#CTX

#thisnow
#showweather
#weatherpayed
#dayweather
#hourlycloudweather
#hourlyrainweather
#weekweather
#suncolor
#lifecolor
#weekdaybgcolor
#weekdayfgcolor
#weekdaypredelimcolor
#weekdaypostdelimcolor
#hourbgcolor
#hourfgcolor
#cloudcolor
#raincolor
#hourcolor
#minutecolor
#secondcolor
#year
#month
#season
#day
#weekday
#hour
#minute
#second
#lifex
#seasonxs
#monthxs
#dayxs
#weekdayxs
#hourxs
#weekxs
#secondxs
#secondys
#sunxs
#mooncolors
#seasonsubgcolors
#seasonbgcolors
#seasonfgcolors

#/CTX

#FUNCS

def yforsun(sunrise, lat, lng, t):
    return (int)(sunrise.elevation(lat, lng, t) * 8 / 90.0)

def moonatday(monthtime, dayoff):
    cycleindex = ((monthtime + (time.hour * 24 * dayoff)).unix - REF_NEWMOON) % LUNATION
    moonp = (cycleindex / LUNATION)
    return ((-math.cos(moonp * 2 * math.pi)) + 1) / 2

def colorformoon(p):
    if p > 0.95:
        return "#888"
    if p > 0.85:
        return "#778"
    if p > 0.75:
        return "#667"
    if p > 0.65:
        return "#556"
    if p > 0.55:
        return "#445"
    if p > 0.45:
        return "#334"
    if p > 0.35:
        return "#223"
    if p > 0.15:
        return "#112"
    return "#001"

#/FUNCS

def main(config):
    ctx = {}
    gotweather = {}
    gotweather["yes"] = False
    unow = time.now()

    showlife = config.bool("showlife")
    showmoon = config.bool("showmoon")
    showsun = config.bool("showsun")
    showminute = config.bool("showminute")
    showsecond = config.bool("showsecond")
    dialsecond = config.bool("dialsecond")
    ctx["showweather"] = config.get("weatherkey") != None and config.get("weatherkey") != ""
    ctx["weatherpayed"] = config.bool("weatherpaid")

    delay = 1000
    if dialsecond:
        delay = 250
    frames = (int)((1000 / delay) * 60 + 1)

    def getctx(unow):
        #CONFIG

        location = json.decode(config.get("location", DEFAULT_LOCATION))
        locality = location["locality"]
        timezone = location["timezone"]
        lat = float(location["lat"])
        lng = float(location["lng"])

        thisnow = unow.in_location(timezone)
        ctx["thisnow"] = thisnow

        birthyear = 1990
        birthyearstr = config.get("birthyear")
        if birthyearstr:
            birthyear = int(birthyearstr)

        springsubgcolor = "#071807"
        springbgcolor = "#183018"
        springfgcolor = "#6A6"
        summersubgcolor = "#1C1C00"
        summerbgcolor = "#2C2C00"
        summerfgcolor = "#AA0"
        fallsubgcolor = "#210"
        fallbgcolor = "#420"
        fallfgcolor = "#C40"
        wintersubgcolor = "#161626"
        winterbgcolor = "#262636"
        winterfgcolor = "#AAF"

        if lat > 0.0:
            ctx["seasonsubgcolors"] = [
                wintersubgcolor,
                springsubgcolor,
                summersubgcolor,
                fallsubgcolor,
                wintersubgcolor,
            ]
            ctx["seasonbgcolors"] = [
                winterbgcolor,
                springbgcolor,
                summerbgcolor,
                fallbgcolor,
                winterbgcolor,
            ]
            ctx["seasonfgcolors"] = [
                winterfgcolor,
                springfgcolor,
                summerfgcolor,
                fallfgcolor,
                winterfgcolor,
            ]
        else:
            ctx["seasonsubgcolors"] = [
                summersubgcolor,
                fallsubgcolor,
                wintersubgcolor,
                springsubgcolor,
                summersubgcolor,
            ]
            ctx["seasonbgcolors"] = [
                summerbgcolor,
                fallbgcolor,
                winterbgcolor,
                springbgcolor,
                summerbgcolor,
            ]
            ctx["seasonfgcolors"] = [
                summerfgcolor,
                fallfgcolor,
                winterfgcolor,
                springfgcolor,
                summerfgcolor,
            ]

        ctx["suncolor"] = "#664"
        ctx["lifecolor"] = "#400"
        ctx["weekdaybgcolor"] = "#404"
        ctx["weekdayfgcolor"] = "#B0B"
        ctx["weekdaypredelimcolor"] = "#0008"
        ctx["weekdaypostdelimcolor"] = "#303"
        ctx["hourbgcolor"] = "#033"
        ctx["hourfgcolor"] = "#0AA"
        ctx["cloudcolor"] = "#333"
        ctx["raincolor"] = "#33A"
        ctx["hourcolor"] = "#B8B"
        ctx["minutecolor"] = "#ACC"
        ctx["secondcolor"] = "#AAA"

        #/CONFIG

        #PRECACHING

        #everything 0 indexed
        ctx["year"] = thisnow.year
        ctx["month"] = thisnow.month - 1
        ctx["season"] = MONTHSEASON[ctx["month"]]
        ctx["day"] = thisnow.day - 1
        ctx["weekday"] = humanize.day_of_week(thisnow)
        ctx["hour"] = thisnow.hour
        ctx["minute"] = thisnow.minute
        ctx["second"] = thisnow.second

        ctx["lifex"] = int(64 * (ctx["year"] - birthyear) / 90)

        ctx["seasonxs"] = [
            int(64 * 0 / 12),
            int(64 * 2 / 12),
            int(64 * 5 / 12),
            int(64 * 8 / 12),
            int(64 * 11 / 12),
            int(64 * 12 / 12),
        ]

        ctx["monthxs"] = []
        for i in range(13):
            ctx["monthxs"].append(int(64 * i / 12))
        ctx["monthxs"][12] = 63

        daysthismonth = DAYSOFMONTH[ctx["month"]]
        ctx["dayxs"] = []
        for i in range(32):
            ctx["dayxs"].append(int(64 * i / daysthismonth))
        ctx["dayxs"][daysthismonth] = 63

        ctx["weekdayxs"] = []
        for i in range(8):
            ctx["weekdayxs"].append(int(64 * i / 7))
        ctx["weekdayxs"][7] = 63

        ctx["hourxs"] = []
        for i in range(25):
            ctx["hourxs"].append(int(64 * i / 24))
        ctx["hourxs"][24] = 63

        firstsun = (ctx["day"] + (7 + 7 - ctx["weekday"])) % 7
        ctx["weekxs"] = []
        for i in range(5):
            ctx["weekxs"].append(int(64 * (firstsun + i * 7) / daysthismonth))
        if ctx["weekxs"][3] == 64:
            ctx["weekxs"][3] = 63
        if ctx["weekxs"][4] == 64:
            ctx["weekxs"][4] = 63

        ctx["secondxs"] = []
        ctx["secondys"] = []
        if dialsecond:
            starttheta = math.pi / 2 - 2 * math.pi * ctx["second"] / 60
            if starttheta < 0:
                starttheta = starttheta + math.pi * 2
            deltatheta = 2 * math.pi / (frames - 1)
            cornertheta = 0.463647609
            for i in range(frames):
                t = starttheta - i * deltatheta
                if t < 0:
                    t = t + math.pi * 2
                x = math.cos(t)
                y = math.sin(t)
                secondx = 0
                secondy = 0
                if t < cornertheta:  #right
                    secondx = 63
                    secondy = y * -32 / x + 16
                elif t < math.pi - cornertheta:  #top
                    secondx = x * 16 / y + 32
                    secondy = 0
                elif t < math.pi + cornertheta:  #left
                    secondx = 0
                    secondy = y * 32 / x + 16
                elif t < 2 * math.pi - cornertheta:  #bottom
                    secondx = x * -16 / y + 32
                    secondy = 31
                else:  #right
                    secondx = 63
                    secondy = y * -32 / x + 16

                ctx["secondxs"].append((int)(secondx))
                ctx["secondys"].append((int)(secondy))

        rise = sunrise.sunrise(lat, lng, thisnow).in_location(timezone)
        set = sunrise.sunset(lat, lng, thisnow).in_location(timezone)
        risem = rise.hour * 60 + rise.minute
        setm = set.hour * 60 + set.minute
        ctx["sunxs"] = [
            int(64 * risem / (24 * 60)),
            int(64 * setm / (24 * 60)),
        ]
        ctx["sunys"] = []
        thisdaystart = thisnow
        thisdaystart = thisdaystart - time.hour * ctx["hour"]
        thisdaystart = thisdaystart - time.minute * ctx["minute"]
        thisdaystart = thisdaystart - time.second * ctx["second"]
        for i in range(ctx["sunxs"][1] - ctx["sunxs"][0]):
            ctx["sunys"].append(yforsun(sunrise, lat, lng, thisdaystart + (time.minute * ((ctx["sunxs"][0] + i + 1) * (24 * 60)) / 64)))

        thismonthstart = thisnow
        thismonthstart = thismonthstart - time.hour * (ctx["day"] * 24)
        thismonthstart = thismonthstart - time.hour * ctx["hour"]
        thismonthstart = thismonthstart - time.minute * ctx["minute"]
        thismonthstart = thismonthstart - time.second * ctx["second"]
        sincemonthstart = thisnow - thismonthstart
        monthstart = unow - sincemonthstart
        ctx["mooncolors"] = []
        for i in range(32):
            ctx["mooncolors"].append(colorformoon(moonatday(monthstart, i)))

        if ctx["showweather"] and gotweather["yes"] == False:
            gotweather["yes"] = True

            if ctx["weatherpayed"]:
                weatherurlbase = WEATHERURLPRE + config.get("weatherkey") + "&query=" + humanize.url_encode(locality)
                weatherurlweek = weatherurlbase + WEATHERURLPOSTWEEK
                weatherurlday = weatherurlbase + WEATHERURLPOSTDAY

                #print(weatherurlday)
                #print(weatherurlweek)

                res = http.get(url = weatherurlday, ttl_seconds = 60 * 60)
                if res.status_code != 200:
                    ctx["showweather"] = False
                    print("Error getting weather " + str(res.status_code))
                else:
                    result = res.json()
                    if "success" in result and result["success"] == False:
                        ctx["showweather"] = False
                        if "error" in result and "code" in result["error"] and "type" in result["error"]:
                            print("Error getting paid weather " + str(result["error"]["code"]) + result["error"]["type"])
                        else:
                            print("Error getting paid weather; failed getting error code")
                    else:
                        formatteddate = (thisnow).format("2006-01-02")
                        if "current" in result and "weather_descriptions" in result["current"] and "forecast" in result and formatteddate in result["forecast"] and "hourly" in result["forecast"][formatteddate]:
                            ctx["dayweather"] = result["current"]["weather_descriptions"][0]
                            hourly = result["forecast"][formatteddate]["hourly"]
                            ctx["hourlycloudweather"] = []
                            ctx["hourlyrainweather"] = []
                            for i in range(24):
                                ctx["hourlycloudweather"].append(hourly[i]["cloudcover"])
                                ctx["hourlyrainweather"].append(hourly[i]["chanceofrain"])
                        else:
                            ctx["showweather"] = False
                            print("Error getting paid weather; unexpected json")

                dayformatted = (thisnow + time.hour * 24 * 6).format("2006-01-02")
                resgood = True
                res = cache.get(weatherurlweek)
                if res == None:
                    resgood = False
                else:
                    result = res.json()
                    resgood = "forecast" in result and dayformatted in result["forecast"]

                if resgood == False:
                    til_midnight_ttl = (int)((60 * 60 * 24) - (ctx["hour"] * 60 * 60 + ctx["minute"] * 60 + ctx["second"]))
                    res = http.get(url = weatherurlweek, ttl_seconds = til_midnight_ttl)
                    if res.status_code != 200:
                        print("Error getting weather " + str(res.status_code))
                    else:
                        result = res.json()
                        if "success" in result and result["success"] == False:
                            if "error" in result and "code" in result["error"] and "type" in result["error"]:
                                print("Error getting paid week weather " + str(result["error"]["code"]) + result["error"]["type"])
                            else:
                                print("Error getting paid week weather; failed getting error code")
                        elif "forecast" not in result:
                            resgood = False
                            print("Error getting paid week weather; unexpected json")
                        else:
                            cache.set(res, til_midnight_ttl)
                            resgood = True

                if resgood:
                    result = res.json()
                    forecast = result["forecast"]
                    ctx["weekweather"] = []
                    for i in range(7):
                        dayformatted = (thisnow + time.hour * 24 * i).format("2006-01-02")
                        if dayformatted in forecast:
                            ctx["weekweather"].append(forecast[dayformatted]["totalsnow"])
                        else:
                            ctx["weekweather"].append(0)
                else:
                    ctx["showweather"] = False

            else:
                weatherurlbase = WEATHERURLFREE + config.get("weatherkey") + "&query=" + humanize.url_encode(locality)

                res = http.get(url = weatherurlbase, ttl_seconds = 60 * 60)
                if res.status_code != 200:
                    ctx["showweather"] = False
                    print("Error getting weather " + str(res.status_code))
                else:
                    result = res.json()
                    if "success" in result and result["success"] == False:
                        ctx["showweather"] = False
                        if "error" in result and "code" in result["error"] and "type" in result["error"]:
                            print("Error getting free weather " + str(result["error"]["code"]) + result["error"]["type"])
                        else:
                            print("Error getting free weather; failed getting error code")
                    elif "current" in result and "weather_descriptions" in result["current"]:
                        ctx["dayweather"] = result["current"]["weather_descriptions"][0]
                    else:
                        ctx["showweather"] = False
                        print("Error getting free weather; unexpected json")

        #/PRECACHING

    #RENDERING

    def getstack(showlife, showmoon, showsun, showminute, showsecond, dialsecond, delay, noanimate):
        stack = []

        #get ctx for simplicity of typing
        thisnow = ctx["thisnow"]
        showweather = ctx["showweather"]
        weatherpayed = ctx["weatherpayed"]
        suncolor = ctx["suncolor"]
        lifecolor = ctx["lifecolor"]
        weekdaybgcolor = ctx["weekdaybgcolor"]
        weekdayfgcolor = ctx["weekdayfgcolor"]
        weekdaypredelimcolor = ctx["weekdaypredelimcolor"]
        weekdaypostdelimcolor = ctx["weekdaypostdelimcolor"]
        hourbgcolor = ctx["hourbgcolor"]
        hourfgcolor = ctx["hourfgcolor"]
        cloudcolor = ctx["cloudcolor"]
        raincolor = ctx["raincolor"]
        hourcolor = ctx["hourcolor"]
        minutecolor = ctx["minutecolor"]
        secondcolor = ctx["secondcolor"]
        month = ctx["month"]
        season = ctx["season"]
        day = ctx["day"]
        weekday = ctx["weekday"]
        hour = ctx["hour"]
        minute = ctx["minute"]
        second = ctx["second"]
        lifex = ctx["lifex"]
        seasonxs = ctx["seasonxs"]
        monthxs = ctx["monthxs"]
        dayxs = ctx["dayxs"]
        weekdayxs = ctx["weekdayxs"]
        hourxs = ctx["hourxs"]
        weekxs = ctx["weekxs"]
        secondxs = ctx["secondxs"]
        secondys = ctx["secondys"]
        sunxs = ctx["sunxs"]
        sunys = ctx["sunys"]
        mooncolors = ctx["mooncolors"]
        seasonsubgcolors = ctx["seasonsubgcolors"]
        seasonbgcolors = ctx["seasonbgcolors"]
        seasonfgcolors = ctx["seasonfgcolors"]

        frames = (int)((1000 / delay) * 60 + 1)
        frameinterval = time.millisecond * delay

        #month
        y0 = 0
        y1 = 6
        for i in range(5):
            if seasonxs[i + 1] < monthxs[month + 1]:
                stack.append(drawrectcoords(seasonxs[i], y0, seasonxs[i + 1], 2, seasonbgcolors[i]))
            elif seasonxs[i] > monthxs[month]:
                stack.append(drawrectcoords(seasonxs[i], y0, seasonxs[i + 1], y1 + 1, seasonbgcolors[i]))
            else:
                stack.append(drawrectcoords(seasonxs[i], y0, monthxs[month], 2, seasonbgcolors[i]))
                stack.append(drawrectcoords(monthxs[month] + 1, y0, seasonxs[i + 1], y1 + 1, seasonbgcolors[i]))
        stack.append(drawrect(monthxs[month], y0, 1, y1 - y0 + 1, seasonfgcolors[season]))
        stack.append(drawrect(monthxs[month + 1], y0, 1, y1 - y0, seasonfgcolors[season]))
        stack.append(drawrect(monthxs[month], y1, 1, 1, "#000"))
        stack.append(drawrect(monthxs[month + 1], y1, 1, 1, "#000"))
        for i in range(11):
            if i != month:
                if i < month:
                    stack.append(drawrect(monthxs[i + 1] - 1, 1, 1, 2, "#000"))
                else:
                    stack.append(drawrect(monthxs[i + 1] - 1, 6, 1, 2, "#000"))
        stack.append(drawrect(monthxs[12], 6, 1, 2, "#000"))  #shift final
        if monthxs[month + 1] >= 32:
            stack.append(drawrtext(monthxs[month] - 2, y0, MONTHSTRS[month]))
        else:
            stack.append(drawtext(monthxs[month + 1] + 2, y0, MONTHSTRS[month]))

        #day
        y0 = 8
        y1 = 15
        stack.append(drawrectcoords(0, y0, dayxs[day + 1], y1 + 1, seasonbgcolors[season]))
        stack.append(drawrect(dayxs[day], y0, 1, 8, seasonfgcolors[season]))
        stack.append(drawrect(dayxs[day + 1], y0, 1, 8, seasonfgcolors[season]))

        #weekstart
        for i in range(5):
            if True:
                stack.append(drawrect(weekxs[i], 13, 1, 3, seasonsubgcolors[season]))
                stack.append(drawrect(weekxs[i] - 1, 15, 1, 1, seasonsubgcolors[season]))
                stack.append(drawrect(weekxs[i] + 1, 15, 1, 1, seasonsubgcolors[season]))
        if dayxs[day + 1] >= 32:
            stack.append(drawrtext(dayxs[day] - 2, y0, str(day + 1)))
        else:
            stack.append(drawtext(dayxs[day + 1] + 2, y0, str(day + 1)))

        #weekday
        y0 = 16
        y1 = 23
        stack.append(drawrectcoords(0, y0, weekdayxs[weekday + 1], y1 + 1, weekdaybgcolor))
        if showweather:
            if weatherpayed:
                weekweather = ctx["weekweather"]
                for i in range(7):
                    stack.append(drawrectcoords(weekdayxs[(weekday + i) % 7], y0, weekdayxs[(weekday + i) % 7 + 1], y0 + (int)(weekweather[i] * (y1 - y0 + 1) / 20), raincolor))
            dayweather = ctx["dayweather"]
            if dayweather == "Clear":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_CLEAR))
            elif dayweather == "Sunny":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_CLEAR))
            elif dayweather == "Partly cloudy":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_PARTLYCLOUDY))
            elif dayweather == "Overcast":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_CLOUDY))
            elif dayweather == "Cloudy":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_CLOUDY))
            elif dayweather == "Fog":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_CLOUDY))
            elif dayweather == "Mist":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_CLOUDY))
            elif dayweather == "Light Rain":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_PRECIPITATION))
            elif dayweather == "Rainy":
                stack.append(drawimg(weekdayxs[weekday] + 2, y0 + 2, WEATHERICON_PRECIPITATION))
            else:
                stack.append(drawtext(weekdayxs[weekday] + 3, y0, dayweather[0]))
                print("Unknown weather summary: " + dayweather)
        for i in range(8):
            if i == weekday or i == weekday + 1:
                stack.append(drawrect(weekdayxs[i], y0, 1, 8, weekdayfgcolor))
            elif i < weekday:
                stack.append(drawrect(weekdayxs[i], y0 + 1, 1, 6, weekdaypredelimcolor))
            elif i > weekday:
                stack.append(drawrect(weekdayxs[i], y0 + 1, 1, 6, weekdaypostdelimcolor))
        if weekdayxs[weekday + 1] >= 32:
            stack.append(drawrtext(weekdayxs[weekday] - 2, y0, WEEKDAYSTRS[weekday]))
        else:
            stack.append(drawtext(weekdayxs[weekday + 1] + 2, y0, WEEKDAYSTRS[weekday]))

        #weekdayhour
        stack.append(drawrect((int)(64 * (weekday * 24 + hour) / (24 * 7)), 16, 1, 1, hourcolor))

        #hour
        y0 = 24
        y1 = 31
        stack.append(drawrectcoords(0, y0, hourxs[hour + 1], y1 + 1, hourbgcolor))

        #hourlyweather
        if showweather and weatherpayed:
            hourlycloudweather = ctx["hourlycloudweather"]
            hourlyrainweather = ctx["hourlyrainweather"]
            for i in range(24):
                stack.append(drawrectcoords(hourxs[i], y0, hourxs[i + 1], y0 + (int)(hourlycloudweather[i] * (y1 - y0) / 100), cloudcolor))
                stack.append(drawrectcoords(hourxs[i], y0, hourxs[i + 1], y0 + (int)(hourlyrainweather[i] * (y1 - y0) / 100), raincolor))

        #sunriseset
        if showsun:
            for i in range(sunxs[1] - sunxs[0]):
                stack.append(drawrect(sunxs[0] + i, 31 - sunys[i], 1, 1, suncolor))
        stack.append(drawrect(hourxs[hour], y0, 1, 8, hourfgcolor))
        stack.append(drawrect(hourxs[hour + 1], y0, 1, 8, hourfgcolor))

        #minute
        stack.append(drawrect((int)(64 * (hour * 60 + minute) / (24 * 60)), 24, 1, 1, minutecolor))

        if noanimate:
            if hourxs[hour + 1] >= 32:
                stack.append(drawrtext(hourxs[hour] - 2, y0, thisnow.format("3:04PM")))
            else:
                stack.append(drawtext(hourxs[hour + 1] + 2, y0, thisnow.format("3:04PM")))
        else:
            animation = []
            if hourxs[hour + 1] >= 32:
                for i in range(frames):
                    animation.append(drawrtext(hourxs[hour] - 2, y0, (thisnow + frameinterval * i).format("3:04PM")))
            else:
                for i in range(frames):
                    animation.append(drawtext(hourxs[hour + 1] + 2, y0, (thisnow + frameinterval * i).format("3:04PM")))
            stack.append(render.Animation(children = animation))

        #life
        if showlife:
            stack.append(drawrect(0, 0, lifex, 1, lifecolor))

        #moon
        if showmoon:
            for i in range(DAYSOFMONTH[month] + 1):
                stack.append(drawrect(dayxs[i], 8, 1, 1, mooncolors[i]))

        #minute
        if showminute:
            if noanimate:
                stack.append(drawrect(2 + minute, 31, 1, 1, minutecolor))
            else:
                animation = []
                framedelta = delay / 1000
                for i in range(frames):
                    animation.append(drawrect(2 + (minute + (int)((second + i * framedelta) / 60)), 31, 1, 1, minutecolor))
                stack.append(render.Animation(children = animation))

        #second
        if showsecond:
            if noanimate:
                stack.append(drawrect(2 + second, 31, 1, 1, secondcolor))
            else:
                animation = []
                framedelta = delay / 1000
                for i in range(frames):
                    if dialsecond:
                        if i == 0:
                            animation.append(drawrect(secondxs[i], secondys[i], 1, 1, "#ACA"))
                        else:
                            animation.append(drawrect(secondxs[i], secondys[i], 1, 1, secondcolor))
                    elif i == 0:
                        animation.append(drawrect((2 + (second + (int)(i * framedelta)) % 60), 31, 1, 1, "#ACA"))
                    else:
                        animation.append(drawrect((2 + (second + (int)(i * framedelta)) % 60), 31, 1, 1, secondcolor))
                stack.append(render.Animation(children = animation))

        return render.Stack(stack)

    #DEBUGGING

    #animationstacks = []
    #getctx(unow)
    #animationstacks.append(getstack(showlife,showmoon,showsun,showminute,showsecond,dialsecond,delay,True))
    #for i in range(300):
    #    getctx(unow+time.minute*60*i)
    #    animationstacks.append(getstack(showlife,showmoon,showsun,showminute,showsecond,dialsecond,delay,True))
    #stack = render.Animation(children = animationstacks)

    getctx(unow)
    stack = getstack(showlife, showmoon, showsun, showminute, showsecond, dialsecond, delay, False)

    return render.Root(
        #show_full_animation = True,
        max_age = 120,
        delay = delay,
        child = stack,
    )
