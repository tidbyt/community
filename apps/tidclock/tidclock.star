load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

def rowbgbar(w, h, c):
    return render.Row(
        expanded = True,
        children = [
            render.Box(width = w, height = h, color = c),
        ],
    )

def rowfgbar(w, nw, h, c):
    if w == 0:
        if w == nw:
            return render.Row(
                expanded = True,
                children = [
                    render.Box(width = 1, height = h, color = c),
                ],
            )
        else:
            return render.Row(
                expanded = True,
                children = [
                    render.Box(width = 1, height = h, color = c),
                    render.Box(width = nw - 1, height = h),
                    render.Box(width = 1, height = h, color = c),
                ],
            )
    if w == nw:
        return render.Row(
            expanded = True,
            children = [
                render.Box(width = w - 1, height = h),
                render.Box(width = 1, height = h, color = c),
            ],
        )
    else:
        return render.Row(
            expanded = True,
            children = [
                render.Box(width = w - 1, height = h),
                render.Box(width = 1, height = h, color = c),
                render.Box(width = nw - w - 1, height = h),
                render.Box(width = 1, height = h, color = c),
            ],
        )

def rowtext(w, nw, h, text):
    if w < 32:
        return render.Row(
            expanded = True,
            children = [
                render.Box(width = nw, height = h),  #, color="#FFF"),
                render.Text(text),
            ],
        )
    elif w == 64:
        return render.Row(
            expanded = True,
            main_align = "end",
            children = [
                render.Text(text),
            ],
        )
    else:
        return render.Row(
            expanded = True,
            main_align = "end",
            children = [
                render.Text(text),
                render.Box(width = 64 - w, height = h),  #, color="#FFF"),
            ],
        )

def clocksecond(second, offset):
    if (second + offset) % 60 == 0:
        if (second + offset) >= 60:
            return render.Box(width = 1, height = 1, color = "#FAA")
        else:
            return render.Box(width = 1, height = 1, color = "#AAA")
    if (second + offset) >= 60:
        return render.Row(
            children = [
                render.Box(width = (second + offset) % 60, height = 1),
                render.Box(width = 1, height = 1, color = "#FAA"),
            ],
        )
    else:
        return render.Row(
            children = [
                render.Box(width = (second + offset) % 60, height = 1),
                render.Box(width = 1, height = 1, color = "#AAA"),
            ],
        )

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
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    timezone = location["timezone"]
    lat = float(location["lat"])
    lng = float(location["lng"])
    tnow = time.now()
    now = tnow.in_location(timezone)
    rise = sunrise.sunrise(lat, lng, tnow).in_location(timezone)
    set = sunrise.sunset(lat, lng, tnow).in_location(timezone)

    birthyear = 1990
    birthyearstr = config.get("birthyear")
    if birthyearstr:
        birthyear = int(birthyearstr)

    monthstr = ["DEC", "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    daysofmonth = [31, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    daystr = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    year = now.year
    month = now.month
    day = now.day
    weekday = humanize.day_of_week(now)
    hour = now.hour

    #minute = now.minute
    second = now.second

    #year/life
    lifew = int(64 * (year - birthyear) / 90)

    #month/year
    monthw = int(64 * (month - 1) / 12)
    monthnw = int(64 * month / 12)

    #day/month
    dayw = int(64 * (day - 1) / daysofmonth[month])
    daynw = int(64 * day / daysofmonth[month])

    #weekday/week
    weekdayw = int(64 * weekday / 7)
    weekdaynw = int(64 * (weekday + 1) / 7)

    #hour/day
    hourw = int(64 * hour / 24)
    hournw = int(64 * (hour + 1) / 24)

    #minute/hour
    #minutew = int(64 * minute / 60)
    #minutenw = int(64 * (minute + 1) / 60)

    #second/minute
    #secondw = int(64 * second / 60)
    #secondnw = int(64 * (second + 1) / 60)

    springcolor = "#183018"
    summercolor = "#2C2C00"
    fallcolor = "#420"
    wintercolor = "#282838"

    springbcolor = "#8F8"
    summerbcolor = "#AA0"
    fallbcolor = "#F40"
    winterbcolor = "#AAF"

    season0color = wintercolor
    season1color = springcolor
    season2color = summercolor
    season3color = fallcolor
    season4color = wintercolor
    season0bcolor = winterbcolor
    season1bcolor = springbcolor
    season2bcolor = summerbcolor
    season3bcolor = fallbcolor
    season4bcolor = winterbcolor

    if lat < 0:
        season0color = summercolor
        season1color = fallcolor
        season2color = wintercolor
        season3color = springcolor
        season4color = summercolor
        season0bcolor = summerbcolor
        season1bcolor = fallbcolor
        season2bcolor = winterbcolor
        season3bcolor = springbcolor
        season4bcolor = summerbcolor

    season0w = int(64 * (3 - 1) / 12)
    season1w = int(64 * (6 - 1) / 12)
    season2w = int(64 * (9 - 1) / 12)
    season3w = int(64 * (12 - 1) / 12)
    season4w = int(64 * (13 - 1) / 12)

    weekstartcolor = "#333"

    firstsun = (day + (7 + 7 - weekday)) % 7
    if firstsun == 0:
        firstsun = 7
    weekstart0w = int(64 * (firstsun + 0 - 1) / daysofmonth[month])
    weekstart1w = int(64 * (firstsun + 7 - 1) / daysofmonth[month])
    weekstart2w = int(64 * (firstsun + 14 - 1) / daysofmonth[month])
    weekstart3w = int(64 * (firstsun + 21 - 1) / daysofmonth[month])
    weekstart4w = int(64 * (firstsun + 28 - 1) / daysofmonth[month])

    #weekendcolor = "#222"

    #weekend0w = int(64 * 1 / 7)
    #weekend1w = int(64 * 6 / 7)
    #weekend2w = int(64 * 7 / 7)

    suncolor = "#444"

    risem = rise.hour * 60 + rise.minute
    setm = set.hour * 60 + set.minute
    sun0w = int(64 * risem / (24 * 60))
    sun1w = int(64 * setm / (24 * 60))
    sun2w = int(64 * (24 * 60) / (24 * 60))

    monthbgbar = {}
    if monthnw <= season0w:
        monthbgbar = render.Row(
            expanded = True,
            children = [
                render.Box(width = monthnw, height = 8, color = season0color),
            ],
        )
    elif monthnw <= season1w:
        monthbgbar = render.Row(
            expanded = True,
            children = [
                render.Box(width = season0w, height = 8, color = season0color),
                render.Box(width = monthnw - season0w, height = 8, color = season1color),
            ],
        )
    elif monthnw <= season2w:
        monthbgbar = render.Row(
            expanded = True,
            children = [
                render.Box(width = season0w, height = 8, color = season0color),
                render.Box(width = season1w - season0w, height = 8, color = season1color),
                render.Box(width = monthnw - season1w, height = 8, color = season2color),
            ],
        )
    elif monthnw <= season3w:
        monthbgbar = render.Row(
            expanded = True,
            children = [
                render.Box(width = season0w, height = 8, color = season0color),
                render.Box(width = season1w - season0w, height = 8, color = season1color),
                render.Box(width = season2w - season1w, height = 8, color = season2color),
                render.Box(width = monthnw - season2w, height = 8, color = season3color),
            ],
        )
    elif monthnw <= season4w:
        monthbgbar = render.Row(
            expanded = True,
            children = [
                render.Box(width = season0w, height = 8, color = season0color),
                render.Box(width = season1w - season0w, height = 8, color = season1color),
                render.Box(width = season2w - season1w, height = 8, color = season2color),
                render.Box(width = season3w - season2w, height = 8, color = season3color),
                render.Box(width = monthnw - season3w, height = 8, color = season4color),
            ],
        )

    #rowbgbar(monthnw, 8, "#040")
    daybgbar = rowbgbar(daynw, 8, "#033")
    weekdaybgbar = rowbgbar(weekdaynw, 8, "#004")
    hourbgbar = rowbgbar(hournw, 8, "#404")

    monthfgbar = {}
    if monthnw <= season0w:
        monthfgbar = rowfgbar(monthw, monthnw, 8, season0bcolor)
    elif monthnw <= season1w:
        monthfgbar = rowfgbar(monthw, monthnw, 8, season1bcolor)
    elif monthnw <= season2w:
        monthfgbar = rowfgbar(monthw, monthnw, 8, season2bcolor)
    elif monthnw <= season3w:
        monthfgbar = rowfgbar(monthw, monthnw, 8, season3bcolor)
    elif monthnw <= season4w:
        monthfgbar = rowfgbar(monthw, monthnw, 8, season4bcolor)
    dayfgbar = rowfgbar(dayw, daynw, 8, "#0AA")
    weekdayfgbar = rowfgbar(weekdayw, weekdaynw, 8, "#00E")
    hourfgbar = rowfgbar(hourw, hournw, 8, "#B0B")

    lifeminibar = rowbgbar(lifew, 1, "#400")
    emptyminibar0 = render.Box(width = 64, height = 5)
    seasonminibar = render.Row(
        expanded = True,
        children = [
            render.Box(width = season0w, height = 2, color = season0color),
            render.Box(width = season1w - season0w, height = 2, color = season1color),
            render.Box(width = season2w - season1w, height = 2, color = season2color),
            render.Box(width = season3w - season2w, height = 2, color = season3color),
            render.Box(width = season4w - season3w, height = 2, color = season4color),
        ],
    )
    emptyminibar1 = render.Box(width = 64, height = 7)
    weekstartminibar = {}
    if weekstart4w <= 64:
        weekstartminibar = render.Row(
            expanded = True,
            children = [
                render.Box(width = weekstart0w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
                render.Box(width = weekstart1w - weekstart0w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
                render.Box(width = weekstart2w - weekstart1w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
                render.Box(width = weekstart3w - weekstart2w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
                render.Box(width = weekstart4w - weekstart3w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
            ],
        )
    else:
        weekstartminibar = render.Row(
            expanded = True,
            children = [
                render.Box(width = weekstart0w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
                render.Box(width = weekstart1w - weekstart0w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
                render.Box(width = weekstart2w - weekstart1w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
                render.Box(width = weekstart3w - weekstart2w - 1, height = 1),
                render.Box(width = 1, height = 1, color = weekstartcolor),
            ],
        )

    #weekendminibar = render.Row(
    #expanded = True,
    #children = [
    #render.Box(width = weekend0w,           height = 1, color = weekendcolor),
    #render.Box(width = weekend1w-weekend0w, height = 1),
    #render.Box(width = weekend2w-weekend1w, height = 1, color = weekendcolor),
    #],
    #)
    emptyminibar2 = render.Box(width = 64, height = 15)
    sunminibar = render.Row(
        expanded = True,
        children = [
            render.Box(width = sun0w, height = 1),
            render.Box(width = sun1w - sun0w, height = 1, color = suncolor),
            render.Box(width = sun2w - sun1w, height = 1),
        ],
    )
    #minuteminibar = rowbar(minutew, minutenw, 1, "#044","#044")
    #secondminibar = rowbar(secondw, secondnw, 1, "#444","#444")

    monthtext = rowtext(monthw - 1, monthnw + 1, 8, monthstr[month])
    daytext = rowtext(dayw - 1, daynw + 1, 8, str(day))
    weekdaytext = rowtext(weekdayw - 1, weekdaynw + 1, 8, daystr[weekday])
    hourtext = rowtext(hourw - 1, hournw + 1, 8, now.format("3:04PM"))

    animatedsecondbar = render.Column(
        children = [
            render.Box(width = 64, height = 31),
            render.Row(
                children = [
                    render.Animation(
                        children = [
                            clocksecond(second, 0),
                            clocksecond(second, 1),
                            clocksecond(second, 2),
                            clocksecond(second, 3),
                            clocksecond(second, 4),
                            clocksecond(second, 5),
                            clocksecond(second, 6),
                            clocksecond(second, 7),
                            clocksecond(second, 8),
                            clocksecond(second, 9),
                            clocksecond(second, 10),
                            clocksecond(second, 11),
                            clocksecond(second, 12),
                            clocksecond(second, 13),
                            clocksecond(second, 14),
                            clocksecond(second, 15),
                            clocksecond(second, 16),
                            clocksecond(second, 17),
                            clocksecond(second, 18),
                            clocksecond(second, 19),
                            clocksecond(second, 20),
                            clocksecond(second, 21),
                            clocksecond(second, 22),
                            clocksecond(second, 23),
                            clocksecond(second, 24),
                            clocksecond(second, 25),
                            clocksecond(second, 26),
                            clocksecond(second, 27),
                            clocksecond(second, 28),
                            clocksecond(second, 29),
                            clocksecond(second, 30),
                            clocksecond(second, 31),
                            clocksecond(second, 32),
                            clocksecond(second, 33),
                            clocksecond(second, 34),
                            clocksecond(second, 35),
                            clocksecond(second, 36),
                            clocksecond(second, 37),
                            clocksecond(second, 38),
                            clocksecond(second, 39),
                            clocksecond(second, 40),
                            clocksecond(second, 41),
                            clocksecond(second, 42),
                            clocksecond(second, 43),
                            clocksecond(second, 44),
                            clocksecond(second, 45),
                            clocksecond(second, 46),
                            clocksecond(second, 47),
                            clocksecond(second, 48),
                            clocksecond(second, 49),
                            clocksecond(second, 50),
                            clocksecond(second, 51),
                            clocksecond(second, 52),
                            clocksecond(second, 53),
                            clocksecond(second, 54),
                            clocksecond(second, 55),
                            clocksecond(second, 56),
                            clocksecond(second, 57),
                            clocksecond(second, 58),
                            clocksecond(second, 59),
                            clocksecond(second, 60),
                            clocksecond(second, 61),
                            clocksecond(second, 62),
                            clocksecond(second, 63),
                            clocksecond(second, 64),
                            clocksecond(second, 65),
                            clocksecond(second, 66),
                            clocksecond(second, 67),
                            clocksecond(second, 68),
                            clocksecond(second, 69),
                        ],
                    ),
                ],
            ),
        ],
    )

    return render.Root(
        delay = 1000,
        show_full_animation = False,
        child = render.Stack(
            children = [
                render.Column(
                    children = [
                        monthbgbar,
                        daybgbar,
                        weekdaybgbar,
                        hourbgbar,
                    ],
                ),
                render.Column(
                    children = [
                        monthfgbar,
                        dayfgbar,
                        weekdayfgbar,
                        hourfgbar,
                    ],
                ),
                render.Column(
                    children = [
                        lifeminibar,
                        emptyminibar0,
                        seasonminibar,
                        emptyminibar1,
                        weekstartminibar,
                        #weekendminibar,
                        emptyminibar2,
                        sunminibar,
                        #minuteminibar,
                        #secondbar,
                    ],
                ),
                render.Column(
                    children = [
                        monthtext,
                        daytext,
                        weekdaytext,
                        hourtext,
                    ],
                ),
                monthfgbar,
                lifeminibar,
                animatedsecondbar,
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "birthyear",
                name = "Birth Year",
                desc = "Year used to estimate progress through life",
                icon = "skullCrossbones",
            ),
        ],
    )
