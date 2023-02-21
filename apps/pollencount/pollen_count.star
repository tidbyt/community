"""
Applet: Pollen Count
Summary: Pollen count for your area
Description: Displays a pollen count for your area. Enter your location for updates every 12 hours on the current conditions in your town, as well as which types of pollen are in the air today.
Author: Nicole Brooks
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_LOC = {
    "lat": 40.63,
    "lng": -74.02,
    "locality": "",
}

COLORS = {
    "yellow": "#D19C21",
    "red": "#B31F0E",
    "green": "#338722",
}

API_URL_BASE = "https://api.tomorrow.io/v4/timelines?&fields=treeIndex,weedIndex,grassIndex&timesteps=1d&location="
SECRET_PROPERTY = "&apikey="

def main(config):
    print("Initializing Pollen Count...")
    # secret = secret.decrypt("AV6+xWcEKqQk8lv8vqNkwdwM++h3fRDmbM3vyizZBmHOwUXUUC5WmiN+FbU8lSwyYnQacojyuFmWiovZ8VmRyq+qQ9oa8CQzBcwmQ9YVyaFAc9ij/sV2Yh4wmr3b/4KPyG28wjhGGDj2E4YlvbFxlGoWCegZlY0GlylbTNozom5PrURH6lM=") or ""

    #Get lat and long from schema.
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOC

    #Round to 1 decimal place (1.1km)
    lat = roundToHalf(loc.get("lat"))
    lng = roundToHalf(loc.get("lng"))
    latLngStr = str(lat) + "," + str(lng)

    #Check cache for pollen for this lat/long
    cache = checkLatLngCache(latLngStr)
    if cache != None:
        print("Cache hit")
        todaysCount = cache
    else:
        print("Cache miss, calling API")

        #If not, make API call and cache result
        todaysCount = getTodaysCount(latLngStr)

    firstMixin = None
    secondMixin = None
    if "message" in todaysCount:
        print("Error! " + todaysCount["message"])
        average = ""

        # Custom message only for rate limit.
        skySrc = images["skyLowPollen"]
        groundSrc = images["groundBare"]
        if todaysCount["code"] == 429001:
            textOne = "RATE"
            textTwo = "LIMIT"
        else:
            textOne = "ERROR"
            textTwo = str(int(todaysCount["type"]))
        textColumn = [
            render.Text(
                content = textOne,
                color = "#FFFFFF",
                font = "tb-8",
            ),
            render.Padding(
                pad = (2, 2, 2, 2),
                child = render.Box(
                    height = 1,
                    color = "#fff",
                ),
            ),
            render.Text(
                content = textTwo,
                color = "#FFFFFF",
                font = "tb-8",
            ),
        ]
    else:
        indexes = getTopTwo(todaysCount)
        average = getAverage(indexes)

        # Graphics are three layers:
        # First, sky. Based on average pollen.
        # Second, ground. Bare if grass isn't high pollen, grassy if it is.
        # Thirds, mixins. Shows trees and weeds if those are high pollen.
        skySrc = getSky(average)
        groundSrc = getGround(indexes)
        mixins = getMixins(indexes)
        if len(mixins) == 2:
            firstMixin = mixins[0]
            secondMixin = mixins[1]
        elif len(mixins) == 1:
            firstMixin = mixins[0]
        textColumn = renderColumn(indexes)

    return render.Root(
        child =
            render.Column(
                children = [
                    render.Box(
                        color = COLORS["yellow"],
                        height = 8,
                        child = render.Text(
                            content = "POLLEN COUNT",
                            font = "tb-8",
                            color = "#3D1F01",
                        ),
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(
                                        src = skySrc,
                                        width = 31,
                                        height = 24,
                                    ),
                                    render.Image(
                                        src = groundSrc,
                                        width = 31,
                                        height = 24,
                                    ),
                                    firstMixin,
                                    secondMixin,
                                    render.Padding(
                                        pad = (17, 0, 0, 0),
                                        child = render.Text(
                                            font = "tb-8",
                                            content = str(average),
                                            color = "#3D1F01",
                                        ),
                                    ),
                                ],
                            ),
                            render.Box(
                                color = COLORS["yellow"],
                                height = 24,
                                width = 2,
                            ),
                            render.Box(
                                height = 24,
                                width = 31,
                                child = render.Column(
                                    main_align = "space_between",
                                    cross_align = "center",
                                    children = textColumn,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
    )

# Checking cache for data already stored.
def checkLatLngCache(latLng):
    print("checking cache for: " + latLng)
    cachedPollen = cache.get(latLng)
    if cachedPollen == None:
        return None
    return json.decode(cachedPollen)

# Rounds to the nearest 0.5.
def roundToHalf(floatNum):
    oneDecimal = float(int(floatNum * 10) / 10)
    noDecimal = int(floatNum)
    decimal = oneDecimal - noDecimal
    if decimal >= .3 and decimal <= .7:
        num = noDecimal + 0.5
    elif decimal < .3:
        num = noDecimal
    elif decimal > .7:
        num = noDecimal + 1
    else:
        num = None

    return num

# Make API call and process data.
def getTodaysCount(latLng):
    print("Getting API for: " + latLng + " for " + str(3600 * 12) + " seconds")
    rep = http.get(API_URL_BASE + latLng)
    data = rep.json()

    if "code" in data:
        return data

    pollenData = data["data"]["timelines"][0]["intervals"][0]["values"]

    # save in cache for 12 hours
    cache.set(latLng, json.encode(pollenData), 3600 * 12)
    return pollenData

# Get total average of pollen indexes to two decimal points.
def getAverage(indexes):
    total = 0
    for i in range(0, len(indexes)):
        total += indexes[i]["index"]
    average = float(int(total / len(indexes) * 10) / 10)
    return average

# Takes index values and turns it into a color/word pair.
def getTopTwo(indexes):
    aboveOnes = []
    for index in indexes:
        if indexes[index] > 1:
            aboveOnes.append({
                "name": getName(index),
                "index": indexes[index],
                "color": getColor(indexes[index]),
            })
    if len(aboveOnes) == 0:
        aboveOnes.append({
            "name": ":)",
            "color": COLORS["green"],
        })
    return aboveOnes

# Returns array of children to show in text column.
def renderColumn(topItems):
    layout = []
    if len(topItems) >= 1:
        layout.append(render.Text(
            content = topItems[0]["name"],
            color = topItems[0]["color"],
            font = "tb-8",
        ))
    if len(topItems) >= 2:
        layout.append(render.Padding(
            pad = (2, 2, 2, 2),
            child = render.Box(
                height = 1,
                color = "#fff",
            ),
        ))
        layout.append(render.Text(
            content = topItems[1]["name"],
            color = topItems[1]["color"],
            font = "tb-8",
        ))
    return layout

# Get color text should be based on index.
def getColor(index):
    if index >= 2 and index < 3:
        return COLORS["green"]
    elif index >= 3 and index < 4:
        return COLORS["yellow"]
    elif index >= 4:
        return COLORS["red"]
    else:
        return ""

# Get display text for index.
def getName(indexName):
    if indexName == "weedIndex":
        return "WEED"
    elif indexName == "grassIndex":
        return "GRASS"
    elif indexName == "treeIndex":
        return "TREE"
    else:
        return ""

# Returns appropriate sky image to show.
def getSky(average):
    if average < 2:
        return images["skyLowPollen"]
    elif average >= 2 and average < 3.5:
        return images["skyMedPollen"]
    elif average >= 3.5:
        return images["skyHighPollen"]
    else:
        return ""

# Returns appropriate ground image to show.
def getGround(topTwo):
    matches = False
    for i in range(0, len(topTwo)):
        if topTwo[i]["name"] == "GRASS":
            matches = True

    if matches == True:
        return images["groundGrass"]

    return images["groundBare"]

# Returns array of mixin children (weeds and trees)
def getMixins(topTwo):
    mixins = []
    for i in range(0, len(topTwo)):
        if topTwo[i]["name"] == "TREE":
            mixins.append(render.Image(src = images["trees"], width = 31, height = 24))
        elif topTwo[i]["name"] == "WEED":
            mixins.append(render.Image(src = images["weeds"], width = 31, height = 24))
    return mixins

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location required to find pollen count in your area.",
                icon = "mapLocation",
            ),
        ],
    )

images = {
    "skyLowPollen": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAYAAAACqyaBAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV/TSkUqBe1QxCFDdbIgKuIoVSyChdJWaNXB5NIvaGJIUlwcBdeCgx+LVQcXZ10dXAVB8APE0clJ0UVK/F9SaBHjwXE/3t173L0DhGaNqWZgHFA1y8gkE2K+sCIGXxHAAMKIQpCYqaeyCzl4jq97+Ph6F+dZ3uf+HP1K0WSATySeZbphEa8TT29aOud94girSArxOfGYQRckfuS67PIb57LDAs+MGLnMHHGEWCx3sdzFrGKoxFPEMUXVKF/Iu6xw3uKs1uqsfU/+wlBRW85yneYwklhECmmIkFFHFTVYiNOqkWIiQ/sJD/+Q40+TSyZXFYwc89iACsnxg//B727N0uSEmxRKAD0vtv0xAgR3gVbDtr+Pbbt1AvifgSut499oAjOfpDc6WuwICG8DF9cdTd4DLneA6JMuGZIj+WkKpRLwfkbfVAAGb4G+Vbe39j5OH4AcdbV0AxwcAqNlyl7zeHdvd2//nmn39wMs+XKLkemaAAAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+YEFAApD/LLtk0AAAOXSURBVEjHlZY9jxtVFIaf99w79iZmsywRKBKIgiIFEhL8ARoqhCgpKakpESUVDT0/AAIVEj0VSJRJz0qJxEqJFETY7MbeD3vmHIoZj+94vYa9kjXWmfP5nnPeOzo6/CJy9RKyjJQAGI9qUhLHpyO+OviIJuCGBa9Wzvt39rh3OGV5VP4ERpAUJIEBEWL9qBNliEIY5Bw0XjNvbqKUAREEpyEO54l7h1NEayWJlCvCG8IdInAJHFxQFXEHKUQr0PPnf0fjzq6+J9k54cHXB58wa8Rp7XhvGH3GS2dJkAWVGZWCDASBR+ABDRBdbV++ewcIjmZn+OKCyeQWOcJJZsz4lHD47ek5O7bg2bwuMBlmLgmTsO6/JEjCDNydpmkYCUbAh2/scnf/JtP5Aj+bYvNTLI+ZNzV6cvhHmCXGN28ha0M0HnxzcIJHi5BHEAQmkSWyQWXCiC4BMIThHM8bxsDnb9++1Gv3BrN2rpwgP5hW3B7B09kFu9n4/egCJHZyQmo77rEaqlgG6wL2jgHH2B2Lz97aY9NpEER0qIn84EzoDKDuIYXW+RLwsbUNSK1tH7KBQWtAOJCk/s3xvKYJB3fkTpiRzZbT3g8fJhgLdgzGtgoS3eDMHRZdUI/B4A7Oj3++4IPXbvDy2Gg8wJ28mCGvB9rZuqBJMOrWo7L2qa7SQIQCE1QBi2iDX0Qbfb36o9r56cmslySBqKhUUam1rQNyFJXVtMSQu3KsIAQQjQJ5a7yIFeZv7iQ+fn2CB3z76GRAJokWyUmCaolkwLO6CO7AfmrhTiXcrKqru4znvoI9BewlYxFBJTESjCWk6Llgx9YIR7CfQScn/wRdD395/IL3Xtnh4XTO4/O6T4Civ+3arXrdbsSKdKx4QvQkFV2rvJsZKIJvOkcXDb/+Ne1JxjuyLTmdK4iIQpcr9DJbzv7YBg5TbxpXOrwsvay7RC3/fHiy7GqJJP/T+9ZXsf1d2Mpetj3E4P67JI9rp9YGvKQY2yNfu/qrjnFNo23VXze1vGVIYs13o+UF0Ipq2m+GpZ/cGTeVmh9u55PvBKB+O1SkqbEtTvM7k4d37k7uz9bTjIHB8DovBmlNt7z3YuOnwKDndyf3p2WZsWFJ1ui7/CqLwmOhFnFFR2JDz9U5VHfj9glEuS7/MXNsKmJ9Gwp5WKzXuGFPo0NXQ6YltqCiQkcb5N03QwySjkJBvcPYAHmLlgoi3YTvNuL4F5zAoRoAGwheAAAAAElFTkSuQmCC"),
    "skyMedPollen": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAYAAAACqyaBAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV/TSkUqBe1QxCFDdbIgKuIoVSyChdJWaNXB5NIvaGJIUlwcBdeCgx+LVQcXZ10dXAVB8APE0clJ0UVK/F9SaBHjwXE/3t173L0DhGaNqWZgHFA1y8gkE2K+sCIGXxHAAMKIQpCYqaeyCzl4jq97+Ph6F+dZ3uf+HP1K0WSATySeZbphEa8TT29aOud94girSArxOfGYQRckfuS67PIb57LDAs+MGLnMHHGEWCx3sdzFrGKoxFPEMUXVKF/Iu6xw3uKs1uqsfU/+wlBRW85yneYwklhECmmIkFFHFTVYiNOqkWIiQ/sJD/+Q40+TSyZXFYwc89iACsnxg//B727N0uSEmxRKAD0vtv0xAgR3gVbDtr+Pbbt1AvifgSut499oAjOfpDc6WuwICG8DF9cdTd4DLneA6JMuGZIj+WkKpRLwfkbfVAAGb4G+Vbe39j5OH4AcdbV0AxwcAqNlyl7zeHdvd2//nmn39wMs+XKLkemaAAAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+YEFAApGp8WUqYAAAMzSURBVEjH5Za9bxxlEMZ/M+/unr9iE8ckSKFAwhVuSBXR0dLz51DyL9BTU1FTQgERAolPgXCkUCAkm0DOxHe3tzszFO+7d77kTIRISME0t9qdneeZ531m9uSDr+4ECE87AvA195Ulmkp4SV0fIjlVLuSECCYJEyXK871aeeuVA27f2EVkPfD1h1+vYFUhaS3vkMyxEjCEXhQJJ0QRAg1HgO2kXEmw3yi/PZxSJeWgSQjwa2uLLgWYV/vIBZVlPL4bv5zNuHllgwezjs9PzkqfQiJIqhhB746HLJhXIiSFw81qIfPMIucGWMDJ3EiAqhARizwi/1Znk5bKjfO2Y3+zYZQycATUqoS1uIxQMvAgmkVgBsfjMfO0hQgkUSwcEUECBKGPwmTd+Y+nc+Zm/H4+48FkxpsvX2MjKU0SUrRcP/0QJUi63hl702MamxABvTsR4B5YBB6Xe0kF5LOfvowzC0AQyQCZbL5nnotYBJ2vFpMLzv67EEAkK5FUUCCpUP3RBaqsADuBB3gEEYGTr1VASwEpObnD/O4AkkSBIEm2l6osnmkhIQJVUiEIzPO4D11bmZVYSCeoZB+kUiBKwYhcVCXXyqaSFUIq8tgiqIwgupa51PnlgM4dD0ilmBYglUENaJJQ67LgQh2EV3dqdmuld/j+rC1kLuyJYl5N1pLsPM+hOZ374pxskHxYMg7mwebkZ3ZPP6a1oLV8NIc7De7w2t6IvZSJj5JwuNNw6+oGNzdrEMmTUJSQj374IjpfdmTFQOGxTERIGrgHvWdCtU3xtMXR1Q32qiClhJvTW49ZT0RQ1U0GEV2Y00T5dtwOu0Jo0qMLdKmSF0O5gyOkJKSA0G0UuN/2jNyYhrIpDuG4JLoA5lZAvAgtnHq9XK/rRodikjyPhZQKTizWY5ST+9OCH00HS5ZPx6NxcYXbykfm0qhnpytzmkSKq4frMkL8s++iWvt45/9VqE2fDN5tvPhMwPvmhefX+bCRK6AHXIgeRANGTzrCSuzuQXXy/kvN8Tf/hkH1+vYnb6978N3kjXe7qI6G/wHXqvvv3Wju3WlkMnta7V8q+9HWp+88c+PxHOP/C/4Xn5yjOTBCIcYAAAAASUVORK5CYII="),
    "skyHighPollen": base64.decode("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"),
    "groundBare": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAYAAAACqyaBAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV/TSkUqBe1QxCFDdbIgKuIoVSyChdJWaNXB5NIvaGJIUlwcBdeCgx+LVQcXZ10dXAVB8APE0clJ0UVK/F9SaBHjwXE/3t173L0DhGaNqWZgHFA1y8gkE2K+sCIGXxHAAMKIQpCYqaeyCzl4jq97+Ph6F+dZ3uf+HP1K0WSATySeZbphEa8TT29aOud94girSArxOfGYQRckfuS67PIb57LDAs+MGLnMHHGEWCx3sdzFrGKoxFPEMUXVKF/Iu6xw3uKs1uqsfU/+wlBRW85yneYwklhECmmIkFFHFTVYiNOqkWIiQ/sJD/+Q40+TSyZXFYwc89iACsnxg//B727N0uSEmxRKAD0vtv0xAgR3gVbDtr+Pbbt1AvifgSut499oAjOfpDc6WuwICG8DF9cdTd4DLneA6JMuGZIj+WkKpRLwfkbfVAAGb4G+Vbe39j5OH4AcdbV0AxwcAqNlyl7zeHdvd2//nmn39wMs+XKLkemaAAAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+YEFAApMTOqq+YAAACDSURBVEjH7dHNCcJgDMbxX+vH3VMpvTqIczhCB+rJYZzBHSq8GwjW1st7sD0LRcwfHgIhyRMSgiAIgiD4dYpvDaq6psYTDxwxIqW2T4u6U2r768y86poLzrn5jgNqTLlkwC7HAXtsFjtMWSO2H/kBZdaIF25F1TXTWmcv1/x5mP+f+RuwGBxprnLdvQAAAABJRU5ErkJggg=="),
    "groundGrass": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAMAAAA1ddazAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV/TSkUqBe1QxCFDdbIgKuIoVSyChdJWaNXB5NIvaGJIUlwcBdeCgx+LVQcXZ10dXAVB8APE0clJ0UVK/F9SaBHjwXE/3t173L0DhGaNqWZgHFA1y8gkE2K+sCIGXxHAAMKIQpCYqaeyCzl4jq97+Ph6F+dZ3uf+HP1K0WSATySeZbphEa8TT29aOud94girSArxOfGYQRckfuS67PIb57LDAs+MGLnMHHGEWCx3sdzFrGKoxFPEMUXVKF/Iu6xw3uKs1uqsfU/+wlBRW85yneYwklhECmmIkFFHFTVYiNOqkWIiQ/sJD/+Q40+TSyZXFYwc89iACsnxg//B727N0uSEmxRKAD0vtv0xAgR3gVbDtr+Pbbt1AvifgSut499oAjOfpDc6WuwICG8DF9cdTd4DLneA6JMuGZIj+WkKpRLwfkbfVAAGb4G+Vbe39j5OH4AcdbV0AxwcAqNlyl7zeHdvd2//nmn39wMs+XKLkemaAAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+YEFAApOqR4cm4AAADDUExURQAAABeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxiTHBeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxeWGxiTHBeVGxeWGxiTHBiUHBiVGxiVHBmQHRmRHRmSHRqNHhqOHhqPHRqPHhuKHxuLHxyIHxyIIByJHxyJIByKH////yG5xVgAAAAsdFJOUwALIDIzNjxYWWdwdX6KmJ+iq7K+wMjKy83V2ODj5ujr7O3v9fb3+Pn8/f7+eXDxWAAAAAFiS0dEQP7ZXNgAAAC6SURBVBgZ7cFpUsJAFEbRz9kWZ8R5xinYtwkxJBD6xf3vypbyh8oKrPIc/fubWHJa4FaP9clJj1tIy9L+bgetSXIHK87v9DckrT+cb96fnrhOXxpsZ2fu+fqod/jK3ezm9qo32CPrkj3RvXi5FNQGVsH7MLd8BgS+1CA8bwQDPFBawCwHCihjjigCP9TWGDQRogXEZMJvBUyHEAiIpCRpRywICBhHkqlnbtQyV1UkAsaRb0JsSXzTFMAHK/ouxphVAe8AAAAASUVORK5CYII="),
    "trees": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAMAAAA1ddazAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV/TSkUqBe1QxCFDdbIgKuIoVSyChdJWaNXB5NIvaGJIUlwcBdeCgx+LVQcXZ10dXAVB8APE0clJ0UVK/F9SaBHjwXE/3t173L0DhGaNqWZgHFA1y8gkE2K+sCIGXxHAAMKIQpCYqaeyCzl4jq97+Ph6F+dZ3uf+HP1K0WSATySeZbphEa8TT29aOud94girSArxOfGYQRckfuS67PIb57LDAs+MGLnMHHGEWCx3sdzFrGKoxFPEMUXVKF/Iu6xw3uKs1uqsfU/+wlBRW85yneYwklhECmmIkFFHFTVYiNOqkWIiQ/sJD/+Q40+TSyZXFYwc89iACsnxg//B727N0uSEmxRKAD0vtv0xAgR3gVbDtr+Pbbt1AvifgSut499oAjOfpDc6WuwICG8DF9cdTd4DLneA6JMuGZIj+WkKpRLwfkbfVAAGb4G+Vbe39j5OH4AcdbV0AxwcAqNlyl7zeHdvd2//nmn39wMs+XKLkemaAAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+YEFAAqEFTu6HsAAAGtUExURQAAADN2KFtFJHVTID+yK0liJjN2KFtFJH9aJGZLJDN2KDN2KDN2KFtFJD+yKzN2KDN2KDN2KDR+KDeLKTaFKTaEKTlyKGNJJDhzKDN2KDN2KDWCKDN2KDN2KDN2KDiQKTymKltFJD6sK2xPJHtYJFtFJDN2KDN2KDyiKn5aJH9aJH9aJDaIKTN2KFtFJFtFJDV/KHxZJDN2KFtFJDZ0KDaGKTN2KFtFJHJTJDN2KDt5JzaGKTmUKjN2KDN2KDR6KDN2KDeHKTiQKTmYKjN2KDqcKjueKltFJDN2KDR6KDN2KFtFJDN2KDiSKVtFJDN2KDWBKTaFKDiIKTmVKTqYKjqZKjymKj2nKj2pKj6vK1tFJGtPJH5aJDN2KDR1JzR2JzR2KDR6KDR9KDR+KDV1KDWAKDWDKDaEKTaFKTaIKTeLKTeNKTiPKTiSKTlyKDmUKTmVKTmYKjmZKTqbKjufKjugKjyjKjylKj2pKj2qKz6sKz6tKz6uKz6vKz+wKz+xKz+yK0hkJk5dJlBgJlNVJVtFJGFIJGVLJGddImtOJG1QJHRUJHlXJH9aJP///3of50QAAABddFJOUwAZGRkkL0BAQERSZmdnbnB1dnx9foKDi4yNmJicp6mqrbK3vb6/wcLLy8zN0dTW19jZ3OXm5ufn6Ozu8PDy9PX29vf4+fn5+vv7/Pz9/f3+/v7+/v7+/v7+/v7+/lEP2ZUAAAABYktHRI6CBbNvAAABLUlEQVQYGeXBVVvCABgG0Bdj1hBsxe7u7sIO7EA/1FlMxUIUiW3GxNp/lg31Qh9uvPUc/AMGc05KNsJiasguSqsIg+kXHMQLUhqCTCx+MtIZHXHnN+NLiUC3mIpvUQjS9RHZPZJEvCACre4ZfClYjwfA0oGPJ+JcO8fDTLKLyMkgZESsAJBENEe2Lds8WeyL01fXkijooFlzlTEAmihon+d3ifOtEG3TUD4wOAp2wiE0AJ2kurj1+omcfiLO43WzugUPZdHyZS5g6jWTyjLQlmdIaDnd68pjgPJJY63l5LAHmui7x+dIqArltxhoWLKQ3euDKkIOvOuh0stKMUJ06fcPmUXQWF+VDKjan5RKfJKnNuIQYn1RSqCabZarqvHLWEBpRHil9XUdm7H4iw9t7k0FgbAqygAAAABJRU5ErkJggg=="),
    "weeds": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAYAAAACqyaBAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV/TSkUqBe1QxCFDdbIgKuIoVSyChdJWaNXB5NIvaGJIUlwcBdeCgx+LVQcXZ10dXAVB8APE0clJ0UVK/F9SaBHjwXE/3t173L0DhGaNqWZgHFA1y8gkE2K+sCIGXxHAAMKIQpCYqaeyCzl4jq97+Ph6F+dZ3uf+HP1K0WSATySeZbphEa8TT29aOud94girSArxOfGYQRckfuS67PIb57LDAs+MGLnMHHGEWCx3sdzFrGKoxFPEMUXVKF/Iu6xw3uKs1uqsfU/+wlBRW85yneYwklhECmmIkFFHFTVYiNOqkWIiQ/sJD/+Q40+TSyZXFYwc89iACsnxg//B727N0uSEmxRKAD0vtv0xAgR3gVbDtr+Pbbt1AvifgSut499oAjOfpDc6WuwICG8DF9cdTd4DLneA6JMuGZIj+WkKpRLwfkbfVAAGb4G+Vbe39j5OH4AcdbV0AxwcAqNlyl7zeHdvd2//nmn39wMs+XKLkemaAAAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+YEFAAqCEeCcC0AAAENSURBVEjH7ZKxSgNBEIYHw3TaiFHCuFP5BF5n5TPYWU067yEixDdQrLSwMpDWwso0aidoIT6ABBKIqHGyK4sKp5Vwgc15KGLhftXw8/P/MzAAkUgkEolE/hVW+e1uYHb+pLxzNn9LdcyKPCQ4/e0C73irMLyOaUFx4h2/T8itTSpc9o4bje2ZfadmmNOb+TDvuOIdb4QydGiuLi4XVkjwvuSRNXAjc+jUHDw9Gk+Ci4Frmp9zv0eD5xG/Bjzdk9NqFtCX+j3KSHBs4ePO3DUAALSPZm9IMCHB5KttSTAlwZeAfk6CDwF9nQT3fuPzK1Z51yqvlfCuWmVvlbt5feoH/ZsAkAJAq6QfAUDzwgciyGV/2hcqcgAAAABJRU5ErkJggg=="),
}
