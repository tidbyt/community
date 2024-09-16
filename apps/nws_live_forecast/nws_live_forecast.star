"""
Applet: NWS Live Forecast
Summary: Weather forecast from NWS
Description:  National Weather Service data showing the current temperature and weather forecast for today and tomorrow.
Author: Andrey Goder
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Free API from National Weather Service
WEATHER_URL = "https://api.weather.gov/points/"

# This is how many fit comfortaly on the screen
MAX_DAYS_TO_SHOW = 3

DEFAULT_LOCATION = """
{
  "lat": "37.27",
  "lng": "-121.9272",
  "timezone": "America/Los_Angeles"
}
"""

DAY_LABELS = [
    "Sun",
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
]

def main(config):
    # Config
    location = json.decode(config.get("location") or DEFAULT_LOCATION)

    response = http.get(WEATHER_URL + location["lat"] + "," + location["lng"], ttl_seconds = 300)
    if response.status_code != 200:
        fail("failed to fetch weather %d", response.status_code)

    forecast = http.get(response.json()["properties"]["forecastHourly"], ttl_seconds = 300)
    if forecast.status_code != 200:
        fail("failed to fetch forecast %d", forecast.status_code)

    periods = forecast.json()["properties"]["periods"]
    now = time.now()

    days = []
    rightNow = None
    prevDay = None
    for period in periods:
        if rightNow == None and time.parse_time(period["endTime"]) > now:
            rightNow = period
        day = time.parse_time(period["startTime"]).format("2006-01-02")
        if prevDay == None or day != prevDay:
            days.append([])
            prevDay = day
        days[len(days) - 1].append(period)

    nowTemp = int(math.round(rightNow["temperature"]))
    cols = [render.Column(
        cross_align = "center",
        children = [
            render.Text("Now"),
            render.Image(src = get_icon(rightNow["shortForecast"])),
            render.Text(" %d\u00B0" % nowTemp),
        ],
    )]

    for day in days:
        if len(cols) >= MAX_DAYS_TO_SHOW:
            break
        dayStart = time.parse_time(day[0]["startTime"])
        temps = [p["temperature"] for p in day]
        high = int(math.round(max(temps)))
        forecast = mode([p["shortForecast"] for p in day])

        if dayStart < now:
            # Only show today's temp if it's higher, e.g. in the morning
            if high <= nowTemp:
                continue
            label = "Today"
        else:
            label = DAY_LABELS[humanize.day_of_week(dayStart)]

        cols.append(render.Column(
            cross_align = "center",
            children = [
                render.Text(label),
                render.Image(src = get_icon(forecast)),
                render.Text(" %d\u00B0" % high),
            ],
        ))

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = cols,
        ),
    )

def mode(lst):
    count = {}
    for item in lst:
        if item not in count:
            count[item] = 0
        count[item] += 1
    m = 0
    mitem = None
    for item in count:
        if count[item] > m:
            m = count[item]
            mitem = item
    return mitem

def get_icon(fc):
    if fc == "Partly Sunny" or fc == "Partly Cloudy":
        return PARTLY_SUNNY
    if fc.find("Sunny") >= 0 or fc == "Clear":
        return SUNNY
    if fc.find("Cloudy") >= 0:
        return CLOUDY
    if fc.find("Fog") >= 0 or fc.find("Haze") >= 0:
        return FOG
    if fc.find("Rain") >= 0:
        return RAINY
    if fc.find("Snow") >= 0 or fc.find("Frost"):
        return SNOWY
    if fc.find("storm") >= 0:
        return STORMY
    return SUNNY  # not ideal as the default

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather data.",
                icon = "locationDot",
            ),
        ],
    )

# Weather icons from https://www.flaticon.com/free-icons/weather
# (free with attribution)
SUNNY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAF6SURBVDiNjZOxTltBEEXPzLpAhEAavgKbKgWiAYUOkh4J+AEKRBslFJEQDQ0dP0BPRRmgQREWomCfxUcg5AYk4+edSfF4BNsvhml292rv7J0jLYwoj7rlUbdG3dFKYyusvUfrq9TSfb9hAcCzsDrU4FnzGxZSS/eHEqjZiYtsA/Q6Pptfyn3vWp5S1EfL5Ax4BHCRbTU7KX0y+FJ+xR/PmQvjioSBFMJemLEfrzUB8Bg2EPJex2e9a991XNDaUO/C4PIN4SNOkEY66ruVN2ljfAoTlWzLHGda9y/lqeaZbuK4NOzQjSkN1S+/yvAZnNJXQxgbJjGyvOhT+PpHuKSNvznCqdZ96SUP9EGc8a79fAPiV4TJSogA3SYXJObDB0UGgjjshrrtVAeLLFqUY4B0pb96Te7StXRS1AfL5LfHsAJgUY49slj6auXGVJc12QGAjsmt1JkueBXMPGO1GMEPLOgK2Pn/McWwXqz/fmOpDVYlbmmko/doAH8Bl/eooBsr6RcAAAAASUVORK5CYII=
""")

PARTLY_SUNNY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAB2AAAAdgFOeyYIAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAghJREFUOI2Vks1LlHEQxz/z7LO27eZqShhqqJfaJMnd5yGClTAo6RIdLDDoIMJ26NKloFt/QceOHRaiQ9cgsIgNfZ6KXAu0Ig2ESNJeDBfXt315poPubpEP0tzmNzOfmfnOD3xMXWtA3XiHX7xihn9I6tFA6L8AOm6PqJOsB6BQekZI5wB0LN6tjn12R4A+vBSoegtdaZJuXl/2dhI0Bsh7Q5rpiVFumJW+7NNqoz9qTFrnbqpjLUjfZJr2+Toc+y6iw4BgCpSkSPHbqCoXeN5vYK5cR+Z+AmkAAVA33iHJt5/VtR6gXP5nzs0ClMqPaJeLfA83yemJxapS1bFeWD14TPmJtdw0okttVz+V1CzsqSPVFZZXAKY6iZPs33zDMn1+xastV1hvuyZhOOx5kNsg81W1uVVkzfQrKkmYx9E7vC8fpROP/orqBoRMQrkczsyanq+t4NrHUJ2u+B/3DjERvQHAhzwMHIRYQ61B0YPVIj+Mrf2Pt0ky+w7kPsB6oJnZyGA1ORaBJ4vwZbUGCBogQqOhjnULzzyzhd2XAu4tBbo1F+iqJhsCTXUgUgPo1vtr0awVFHuyCKC6fZWxE51T9cO3C17kwFL01LQROdRiGoFfsSgzFUAZ5tvDjP4lnLqJVOUra6a3UbNWELa/8njinJ/gO5q69qA69pHd8nzPCLqCeBu7AX4DzuO/Myi46LkAAAAASUVORK5CYII=
""")

CLOUDY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAGISURBVDiNxZIxaxRRFIW/M29md8bNulliRgmsIKJgn1QB/Q0bgrVY+xf0ZwhWElIKInamsTGNRSyFEKIkhbAgGCwyuzPvXYtdJ+vuEjs93YN3v3fOuQ/+tzR9eHdkuYnnzYi1hmMQ4O23HjsPJf9XwPsvdqPwdnglVttFf9x5vdljW5ItAkQAe0f2tAp8iETbz1/b2j/l5f6JbSx0sHdsr4RtZ/HYTDCIBCFAZSCBE0SiBF4YfMoG7K6vqwSIR976VxsXVQgoKmO1BVkizOBHYfwckqSxnggocu4Dj35HkCbzZjD0xs0O5EtiOYVuBre6otcRRVXn69cdJOLj0MPIQyM2essiicCHi5ylhzQ21tqiCkbpOa4BZ7f1wAJvVlqU15egm0KrObZUTSBxNI5zrQX3ctndVT4Pzu2xmSV1+MPvoepkctMfoyghTRZ1P5GxM71xMbPC2eEwv+J+DYjduIvLNPIzEHFQOzazxtczdhPHncQhwRzOjOjckzcdAwcHgmeXP/kv9Av+h4p1BXbehgAAAABJRU5ErkJggg==
""")

RAINY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAHASURBVDiNhZM/aFNRFMZ/5753814SWhvEQTBqi4ir4KBRlIo4CS7FoeCmIG4uDoKIuOroIG5ujkWU4r80oiJOLsXBJLUViyKISIvJe8k9DvXFl6Qv/aZzz/n47vnOPRdGYL6ucwsNvTmKI1mFF3WtONFa3kpkhP2VsnzdjGeyBDrCrdCKDxSc43wWr0+g2tBDvYPTwvYCGAERilsKPGvorDO8evtF9wEYK5e/rVEHFqIud7MEBODJJx33PP1c8KVkoFYpMy0imiY+buqeHLwM8hw+vlN+9HXgG+4FRkoCKJx4vcKZwZt8dD70mDIx94csOPS0n5qGwKU06Wldr1sjB2Tjzc6+WdaZnkB1ScPQMpEWQDiYhFVVX0Wv5FJ1Fe4sLmoOwExPSst1aY0FfR2vJEHc5HbOSGnA0e5fY8z2LHScPPgToUULQNvAjYTp0HPWG5wIOOHiP7sbeN7UGd9jKlAeHdkrH//nXZS3YlWHNOLVMvnMVU5QW3atbaEEa+2h0vrRMuOZq5yg3eV7uIkFlPci4rYUMCJXf7ZwO4oQ+r10B49rMOIzJTg1KQ/XYy6s/mYp7hKhfABOHtsl7wD+Ag7Vji5+gL5nAAAAAElFTkSuQmCC
""")

SNOWY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAINSURBVDiNnZG7T5NhFIef83639F6IEKLA4OKgJMbFgDFx8H9wkNGoq4P/jHFzI7K7qImp4CAJGgfkZvNRL7GAlUK/Xr7vPQ5tpZrWwbO8OZf3+Z38DvwjVNW8+KwXllSdUTNmVOPZji4//0TdS9g4u0e1tKcPh83JEFX/5S5rbdVLKVdwehKxhdjy6OZ5uTcS8PFAP/guF9MeJBa+1JWfTcF3ugCvC9sE7hjh7cKMRL8B24e6YkTns8Eps5PA9xNlvwGBI5g/920L3JfwQG91jD7O+JK12v2U8kAVYu2qRh0o15RWAr4R3FPnqrJ5aI9zgWScHr0Zg+/wt1rPH9j9obTjnjfChlElPXgj3x3ibN8wgdmiaEc5AF6pZVG2D20l5ck5b8SlEwtWYaD/bjItl/uJ6xq53op1GZFx12AFdBDgGGh3GHMMdSPsqOXBiAX/L2RlT8eBaGFGoq91nXCzNLcqeHWP1lyaVJCj/b6MIUN8JcC3Fjs2JrU3W5qPi6ioqlmtUMzm0KmAJ6ocTaZYBNxqxFOgMZHiNuDsRywpdL5VudvIklwdp+6uVihmPFq5Aok0CYGjUkhhOo9mAkKBqBSSLxRgyidUiOdmOVovk3ttyYqqmlJIwTE0HSGdKI35aVqArpcp1DLENyY4AVjbJd/MY90aEhfRa2c4BmBJ1VFV6b99g1TVDMsH678AV3n96aEPn+gAAAAASUVORK5CYII=
""")

FOG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAB2AAAAdgFOeyYIAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAlZJREFUOI2dUzFoU1EUPe/lv7yfwSahH4VQCB1CS111MG0XcRCxSxc3oYgWnEpB54JOLi0OnZKGQl1FXSw4pFDsGBpE26FVpwzS/0lIfgL/vX+vg/0ltdTBCw8e555z3r33vSfwH7G/v/+RiO72+/3vznCi2WzejqJoPYqirenp6ZcAsLa2dhPAqrV2goh6juMsEdGjOI7HhRAdBwA2NjbKAFQcx1+Y+Q2AdwBQqVSKQohPALIAYIzx2u32252dnfnl5eX3ACBrtdo9Ippl5htHR0eB1nornU6/3tvb+1UqlRpKqWxSoVIK2WxWWmtXE0ycnjQHYAqALBQKS67rXs3n87DWIgxDHB8fn5tBu91GHMeB1npODCcajcaUEOLrMNbv99Hr9dBqtUBEZ3gUReh2u0EqAQ4PD69Ya9cBTAwbKKWglILWGp1O5wxPpVIYDAbKAQDf95eMMYsAJgeDAVzXheu6CMMQxhik02kopS5cp1LqZ8r3/Slm/iCl9DKZDIwx8DwPWmtorRGGIfL5PEZHRyGlRBAEAGCIqG6MeSpOTk42ATy8YP8niIhaUsqx0747hUIhN0xwANy5RAwAMhEDADMfJPtarTbLzNeE7/tjzDz5D5NEbDzP+1ytVu/jdNBCiEAAQLPZHGfm58wsLzMgoowx5sf29vaLYrF4a2FhYRcAEoFh5niIXwLwJFlxHD+21o4RUXdlZcVKKb8lxHMPqV6vuyMjI9ellA8APGNmCCEOoihyjDGvZmZmKn9Xdu435nK5eQBbibG1Ftba3XK5vHhZa78BCfAX2sADyUAAAAAASUVORK5CYII=
""")

STORMY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAB2AAAAdgFOeyYIAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAkhJREFUOI2Fk09IlFEUxX/3zThpaiK5kRCHyGigP2pTFtZCiIg2tugPIQi2EYIWLaJoNbUzcme1aFFJFOgypFBzkRQuFJPAoBQrbXQwGxvHb2b0e99tYZqY2l3e88555577nvCfigxqEMPVjBLa4qMzsk/ursZlM/KTz1qB0CFKsVUYT8Mvy5f8csoiIi6A2UxAlMeiFAP4BII5UOAjaIe494+DqOrW5Cw3MBSJS0tfjLhmEV0r6ioMJkgXBojc3i9NAjClmmsd3iBUWg/mF7E/M7SNznFxPWcZD8ZSIIZ2AZh09JrCneUDnkI8A4MzG4+nwNAcC8sZHFwNGoFcP1Ruh4LA6kw8Qs4zqn/cJMebIdtgTdTRZoULa2/I9i+Rg3l/e6WZbsJzzZTOviCt2/BDtwEaN7LpM+AT0kA70F6efBAns8B0bngsQdZlc4AzEnX0KVC3noBVUvOWW3u2SZP2HjqBeF04jkvA1ONkOuT0SEJU1cRSHLaGvLQlkO1jEVCj2LTlY2+UQiN8r4uFW4FaANIZcL0WOTV8xYiI9/IrUzuypfvtJBWvJxjqmWDnq3Hi72Lki6FhZBdJlE6QftB53IUkRTnX4c9LNFlURVSNQkIMhc4sjxp2y/tFj4AqHyIinhwfuE91fxWplMH4IxIecABM66ges0pPRMTzfDz0XM43hmURwFickgmer4TStbcW107KyeHmlZWXfKPvUplMA/gt9cYsEdpGtQDD0ZqapU+zVO45/N7ZjbZG6ycNbQgC2hU6srb3G3kg9TNtUQ5UAAAAAElFTkSuQmCC
""")
