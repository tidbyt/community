"""
Applet: ISS Location
Summary: Current ISS city/country 
Description: Current city/country/ocean the ISS is flying over.
Author: carmineguida
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

API_KEY = "AV6+xWcEoZ2Ghxo/Pq1V7vLvA85rHwn8myqaKgarAU7o8q+Jl3fXIJ4WeeR6AMvFbrgeUW4I2KPGG1/3pSwIscAPeNDLci4LPRpl4CbO+tc+fxhe1G6YKTkwNGaXfJrSWRZ3qhQS9oBEh/mRu/eA8sv4"
API_URL = "http://api.open-notify.org/iss-now.json"
GEO_URL = "http://api.geonames.org/findNearbyPlaceNameJSON?username="
OCEAN_URL = "http://api.geonames.org/oceanJSON?username="
FONT = "tom-thumb"
LOC_FONT = "tb-8"

################################################################################

def get_geo_info(geonames):
    city = ""
    country = ""
    adminName1 = ""
    countryCode = ""
    for g in geonames:
        if "countryCode" in g:
            countryCode = g["countryCode"]
        if "countryName" in g:
            country = g["countryName"]
        if "name" in g:
            city = g["name"]
        if "adminName1" in g:
            adminName1 = g["adminName1"]

    if (countryCode == "US"):
        country = adminName1

    return (city, country)

################################################################################

def get_lat_lon():
    rep = http.get(API_URL)
    if (rep.status_code != 200):
        fail("API failed wiht status %d", rep.status_code)
    lat = rep.json()["iss_position"]["latitude"]
    lon = rep.json()["iss_position"]["longitude"]

    if (len(lat) > 7):
        lat = lat[:7]
    if (len(lon) > 7):
        lon = lon[:7]

    return (lat, lon)

################################################################################

def get_ocean(api_key, lat, lon):
    temp_url = OCEAN_URL + api_key + "&lat=" + lat + "&lng=" + lon
    country = ""
    rep = http.get(temp_url)
    if (rep.status_code != 200):
        fail("API failed wiht status %d", rep.status_code)

    #print(str(rep.json()))
    if ("afraid" in str(rep.json())):
        city = "unknown location"
        color = "#444444"
    else:
        city = rep.json()["ocean"]["name"]
        color = "#33A2FF"

    return (city, country, color)

################################################################################

def get_iss_dict(api_key):
    cached = cache.get("iss_dict")
    if cached != None:
        return json.decode(cached)

    (lat, lon) = get_lat_lon()

    temp_url = GEO_URL + api_key + "&lat=" + lat + "&lng=" + lon
    rep = http.get(temp_url)
    if (rep.status_code != 200):
        fail("API failed with status %d", rep.status_code)

    geonames = rep.json()["geonames"]

    if len(geonames) == 0:
        (city, country, color) = get_ocean(api_key, lat, lon)
    else:
        (city, country) = get_geo_info(rep.json()["geonames"])
        color = "#E29315"

    iss_dict = {"lat": lat, "lon": lon, "city": city, "country": country, "color": color}

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set("iss_dict", str(iss_dict), ttl_seconds = 180)
    return iss_dict

################################################################################

def main(config):
    api_key = config.get("api_key") or secret.decrypt(API_KEY)
    if (api_key == None):
        return render.Root(child = render.Text("Need api_key."))

    iss_dict = get_iss_dict(api_key)

    content = iss_dict["city"] + " " + iss_dict["country"]
    content = content.strip()

    render_iss = render.Box(color = "#2D38BF", padding = 1, width = 15, height = 11, child = render.Text("ISS", font = "5x8", color = "#000000"))
    render_lat_lon = render.Column(children = [
        render.Text("Lat:%s" % iss_dict["lat"], font = FONT, color = "#888888"),
        render.Text("Lon:%s" % iss_dict["lon"], font = FONT, color = "#888888"),
    ])
    render_top = render.Padding(pad = (1, 1, 1, 0), child = render.Row(children = [render_iss, render.Box(color = "#000000", width = 1, height = 11), render_lat_lon]))
    render_sep = render.Box(color = "#222222", width = 64, height = 1)
    render_loc = render.Padding(pad = (1, 0, 1, 1), child = render.WrappedText(content = content, font = LOC_FONT, color = iss_dict["color"]))

    return render.Root(child = render.Column(children = [render_top, render_sep, render_loc]))

################################################################################

def get_schema():
    return schema.Schema(version = "1", fields = [])
