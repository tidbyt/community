"""
Applet: Ski Report
Summary: Weather and Trails
Description: Weather and Trail status for Mountains that are part of the Epic Pass resort system.
Author: Colin Morrisseau
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

#Icons
MOUNTAIN_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAANCAYAAACgu+4kAAAA0ElEQVQoU4WRsQ0CMQxFkykogIaWHeBKGIEmBVtAdVRsgZQ0bIEQNZRsQMMUR74lR8bny/0mUhw//+94l9Vl4fRZOKVqNerRDQxkGAPkAAntAWKMXQiBuDVHPNhLGppRYMAQRLouAFymlNzlunTNauLaw8y15w+9PR3nxSkGSmdUwGQ0sgDQAsSK59ebJ9mWsgCL6Y2e6HhVAMe4P75/7nBfljjkABN5WrN9mfEAMh3sd+9iF4vEQ4boeD0AN/NvyN0gyihgbJl64WaE2ndqwA/LoG2en1wa6AAAAABJRU5ErkJggg==""")
GREEN_CIRCLE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAIElEQVQIW2NkAAKeNJX/IBoEvsy6w8iILACTIEEQm5kApvsMxdxRJEEAAAAASUVORK5CYII=""")
BLUE_SQUARE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAE0lEQVQIW2PkZP3+nwENMNJAEABZ6goan8O6FAAAAABJRU5ErkJggg==""")
BLACK_DIAMOND = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAI0lEQVQIW2NkgIL/QMAIBCAumAAJwCRBEozIAnAJrCqxmQkAWm4UAkSaUWwAAAAASUVORK5CYII=""")
SPACER = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAAFCAYAAACEhIafAAAAC0lEQVQIW2NgwAEAABkAAUGqWyUAAAAASUVORK5CYII=""")

#These are used for scraping the data from each site. most epic resort websites follow a similar structure. This doesn't work for the austrailian resorts
TERRAIN_URL_STUB = "the-mountain/mountain-conditions/terrain-and-lift-status.aspx"
TERRAIN_URL_STUB_ALT = "the-mountain/mountain-conditions/lift-and-terrain-status.aspx"
WEATHER_URL_STUB = "the-mountain/mountain-conditions/snow-and-weather-report.aspx"
WEATHER_URL_STUB_ALT = "the-mountain/mountain-conditions/weather-report.aspx"

RESORT_URLS = {
    "Vail": "https://www.vail.com/",
    "Beaver Creek": "https://www.beavercreek.com/",
    "Breckenridge": "https://www.breckenridge.com/",
    "Park City": "https://www.parkcitymountain.com/",
    "Keystone": "https://www.keystoneresort.com/",
    "Crested Butte": "http://www.skicb.com/",
    "Heavenly": "https://www.skiheavenly.com/",
    "Northstar": "https://www.northstarcalifornia.com/",
    "Kirkwood": "https://www.kirkwood.com/",
    "Stevens Pass": "https://www.stevenspass.com/",
    "Stowe": "https://www.stowe.com/",
    "Okemo": "https://www.okemo.com/",
    "Mount Snow": "https://www.mountsnow.com/",
    "Hunter": "https://www.huntermtn.com/",
    "Attitash": "https://www.attitash.com/",
    "Wildcat": "https://www.skiwildcat.com/",
    "Mount Sunapee": "https://www.mountsunapee.com/",
    "Crotched": "https://www.crotchedmtn.com/",
    "Liberty": "https://www.libertymountainresort.com/",
    "Roundtop": "https://www.skiroundtop.com/",
    "Whitetail": "https://www.skiwhitetail.com/",
    "Jack Frost and Big Boulder": "https://www.jfbb.com/",
    "Seven Springs": "https://www.7springs.com/",
    "Hidden Valley(PA)": "https://www.hiddenvalleyresort.com/",
    "Laurel Mountain": "https://www.laurelmountainski.com/",
    "Wilmot": "http://www.wilmotmountain.com/",
    "Afton Alps": "http://www.aftonalps.com/",
    "Mt Brighton": "http://www.mtbrighton.com/",
    "Alpine Valley": "http://alpinevalleyohio.com/",
    "Boston Mills and Brandywine": "https://www.bmbw.com/",
    "Mad River Mountain": "https://www.skimadriver.com/",
    "Hidden Valley(MO)": "https://www.hiddenvalleyski.com/",
    "Snow Creek": "https://www.skisnowcreek.com/",
    "Paoli Peaks": "https://www.paolipeaks.com/",
    "Whistler Blackcomb": "https://www.whistlerblackcomb.com/",
}

def get_schema():
    options = [schema.Option(display = resort, value = resort) for resort in RESORT_URLS.keys()]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "resort",
                name = "Ski Resort",
                icon = "mountain",
                desc = "The resort you want to show. North American Epic Pass Resorts only right now",
                default = options[0].value,
                options = options,
            ),
        ],
    )

def trimToJSON(js_command):
    js_command = js_command.split("= ", 1)[1]
    return js_command[:len(js_command) - 2]

def Getweather_data(resort):
    """Pulls weather info from the weather page associated with the given resort

    Args:
        resort (string): The Resort Name as listed in RESORT_URLS

    Returns:
        dict: a dict containing the temperature, snowfall and description attributes. description is not currently used. Returns None if their is an error fetching the results.
    """

    url = RESORT_URLS[resort] + WEATHER_URL_STUB
    if (cache.get(url) != None):
        cached_string = cache.get(url)
        return json.decode(cached_string)
    r = http.get(url)
    response = r.body()
    temperature = None
    snowfall = None
    weather_description = None
    for line in response.splitlines():
        if line.startswith("    FR.forecasts = "):
            temp_data = json.decode(trimToJSON(line))
            temperature = humanize.ftoa(temp_data[0]["CurrentTempStandard"])
            weather_description = temp_data[0]["ForecastData"][0]["WeatherIconStatus"]
        if line.startswith("    FR.snowReportData = "):
            snowfall = json.decode(trimToJSON(line))["TwentyFourHourSnowfall"]["Inches"]
    if temperature == None:
        url = RESORT_URLS[resort] + WEATHER_URL_STUB_ALT
        r = http.get(url)
        response = r.body()
        for line in response.splitlines():
            if line.startswith("    FR.forecasts = "):
                temp_data = json.decode(trimToJSON(line))
                temperature = humanize.ftoa(temp_data[0]["CurrentTempStandard"])
                weather_description = temp_data[0]["ForecastData"][0]["WeatherIconStatus"]
            if line.startswith("    FR.snowReportData = "):
                snowfall = json.decode(trimToJSON(line))["TwentyFourHourSnowfall"]["Inches"]
    if temperature == None or snowfall == None:
        return None

    results = dict(temperature = temperature, snowfall = snowfall, description = weather_description)
    url = RESORT_URLS[resort] + WEATHER_URL_STUB
    cache.set(url, json.encode(results), 600)
    return results

def getTerrain(resort):
    """Gets the Trail status from a particular resort by scraping the website associated with the resort

    Args:
        resort (string): The Resort Name as listed in RESORT_URLS

    Returns:
        _type_: _description_
    """
    url = RESORT_URLS[resort] + TERRAIN_URL_STUB

    #Check the Cache
    if cache.get(url) != None:
        return json.decode(cache.get(url))

    # Pull an HTML response of the lift status page
    r = http.get(url)
    response = r.body()

    # filter out to just the JSON Object. It's a little wierd so it requires some string manipulation
    terrain_status_js_command = None
    for line in response.splitlines():
        if line.startswith("    FR.TerrainStatusFeed = "):
            terrain_status_js_command = line
            break
    if terrain_status_js_command == None:
        url = RESORT_URLS[resort] + TERRAIN_URL_STUB_ALT
        r = http.get(url)
        response = r.body()
        for line in response.splitlines():
            if line.startswith("    FR.TerrainStatusFeed = "):
                terrain_status_js_command = line
                break
    if terrain_status_js_command == None:
        print("error finding trail info on " + RESORT_URLS[resort])
        return None
    terrain_status_js = trimToJSON(terrain_status_js_command)

    # Turn it into JSON
    terrain_report = json.decode(terrain_status_js)

    # Filter it out just the trails
    trails = []
    for area in terrain_report["GroomingAreas"]:
        for trail in area["Trails"]:
            trails.append(trail)

    # generate a trail summary

    # 1 - Green; 2 - Blue; 3 - Black; 4 - Double Black; 5 - Terrain Park
    summary = {}

    for trail in trails:
        if repr(trail["Difficulty"]) not in summary.keys():
            summary[repr(trail["Difficulty"])] = dict(open = 0, total = 1)
        else:
            summary[repr(trail["Difficulty"])]["total"] += 1

        if trail["IsOpen"]:
            summary[repr(trail["Difficulty"])]["open"] += 1
    for x in ["1", "2", "3"]:
        if x not in summary.keys():
            summary[x] = dict(open = 0, total = 0)

    summary.pop(5, None)
    if "4" in summary.keys():
        summary["3"]["open"] += summary["4"]["open"]
        summary["3"]["total"] += summary["4"]["total"]
    summary.pop("4", None)

    #this turns everything into to strings because the json encoder is picky and needed for caching
    for x in summary.keys():
        for y in summary[x].keys():
            summary[x][y] = repr(summary[x][y])
    url = RESORT_URLS[resort] + TERRAIN_URL_STUB
    cache.set(url, json.encode(summary), 600)
    return summary

def titleRow(resort):
    return render.Row(
        children = [
            render.Image(src = MOUNTAIN_ICON),
            render.Marquee(render.Text(resort, font = "6x13", color = "#85c1e9"), width = 48),
        ],
    )

def trailStatus(image, open, total):
    """Converts the raw info for a difficulty's trail status into a Render object stating the info

    Args:
        image (string): the base_64 constaint associated with difficulty
        open (int): how many trails are open
        total (int): how many total trails there are

    Returns:
        render: a row of one difficulties trail info
    """
    if int(open) == 0:
        color = "#BB1111"  #Red
    elif int(open) // int(total) < 0.5:
        color = "#DFEF21"  #Yellow
    else:
        color = "#0FA700"  #Green
    return render.Row(
        children = [
            render.Image(src = image),
            render.Image(src = SPACER),
            render.Text(open, font = "CG-pixel-3x5-mono", color = color),
            render.Text("/", font = "CG-pixel-3x5-mono", color = color),
            render.Text(total, font = "CG-pixel-3x5-mono", color = color),
        ],
    )

def trailStatusColumn(resort):
    summary = getTerrain(resort)
    if summary == None:
        return render.Column(
            expanded = True,
            main_align = "space_around",
            children = [
                render.Text("Trail", font = "CG-pixel-3x5-mono"),
                render.Text("Error", font = "CG-pixel-3x5-mono"),
            ],
        )
    return render.Column(
        expanded = True,
        main_align = "space_around",
        children = [
            trailStatus(GREEN_CIRCLE, summary["1"]["open"], summary["1"]["total"]),
            trailStatus(BLUE_SQUARE, summary["2"]["open"], summary["2"]["total"]),
            trailStatus(BLACK_DIAMOND, summary["3"]["open"], summary["3"]["total"]),
        ],
    )

def lowerRow(resort):
    return render.Row(
        expanded = True,
        main_align = "space_around",
        children = [
            weather(resort),
            trailStatusColumn(resort),
        ],
    )

def weather(resort):
    weather_data = Getweather_data(resort)
    if weather_data == None:
        return render.Column(
            expanded = True,
            main_align = "space_around",
            children = [
                render.Text("Weather", font = "CG-pixel-3x5-mono"),
                render.Text("Error", font = "CG-pixel-3x5-mono"),
            ],
        )

    return render.Column(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Text(weather_data["temperature"] + "°"),
            render.Text("24h:" + weather_data["snowfall"] + "\"", font = "tom-thumb"),
        ],
    )

def main(config):
    resort = config.str("resort", "Vail")
    return render.Root(
        child = render.Column(
            children = [
                titleRow(resort),
                lowerRow(resort),
            ],
        ),
    )
