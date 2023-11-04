load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def rowbar(w, h, c):
    return render.Row(
        expanded = True,
        children = [
            render.Box(width = w, height = h, color = c),
        ],
    )

def rowtext(w, h, text):
    if w < 32:
        return render.Row(
            expanded = True,
            children = [
                render.Box(width = w, height = h),  #, color="#FFF"),
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

def main(config):
    timezone = "America/Los_Angeles"
    location = config.get("location")
    if location:
        timezone = json.decode(location)["timezone"]

    birthyear = 1990
    birthyearstr = config.get("birthyear")
    if birthyearstr:
        birthyear = int(birthyearstr)

    now = time.now().in_location(timezone)

    monthstr = ["NUL", "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    daystr = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    year = now.year
    month = now.month
    day = now.day
    weekday = humanize.day_of_week(now)
    hour = now.hour
    minute = now.minute
    second = now.second

    lifew = int(64 * (year - birthyear) / 90)  #year/life
    monthw = int(64 * month / 12)  #month/year
    dayw = int(64 * day / 31)  #day/month
    weekdayw = int(64 * weekday / 7)  #weekday/week
    hourw = int(64 * hour / 24)  #hour/day
    minutew = int(64 * minute / 60)  #minute/hour
    secondw = int(64 * second / 60)  #second/minute

    lifebar = rowbar(lifew, 1, "#400")
    monthbar = rowbar(monthw, 7, "#040")
    daybar = rowbar(dayw, 8, "#440")
    weekdaybar = rowbar(weekdayw, 8, "#004")
    hourbar = rowbar(hourw, 6, "#404")
    minutebar = rowbar(minutew, 1, "#044")
    secondbar = rowbar(secondw, 1, "#444")

    monthtext = rowtext(monthw, 8, monthstr[month])
    daytext = rowtext(dayw, 8, str(day))
    weekdaytext = rowtext(weekdayw, 8, daystr[weekday])
    hourtext = rowtext(hourw, 8, now.format("3:04 PM"))

    return render.Root(
        child = render.Stack(
            children = [
                render.Column(
                    children = [
                        lifebar,
                        monthbar,
                        daybar,
                        weekdaybar,
                        hourbar,
                        minutebar,
                        secondbar,
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
