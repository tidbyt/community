"""
Applet: Happy Hour
Summary: Hourly Cocktail Generator
Description: Displays a new cocktail every hour, on the hour. Cheers to my mom for the color scheme, idea, AND name!
Author: Nicole Brooks
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ERROR_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACMAAAAjCAYAAAAe2bNZAAAAAXNSR0IArs4c6QAAAXJJREFUWEftlz1OAzEQhe1V
+tCQnoarUADHgQJqUoTjAAVXoaEPDemjNZpEI00Wz4+fttiVkjLOe/k8nhmPc5rQJ0+IJc0D5vZy+dTl/KJFri/l
+eNnt5briEbqq5Fh0+uuqKf41eckgRDN0LwKc7+6KAxy1f3n+e6P3xHQ2/b34IFommBqIGxAQDWYFk0Y5mahHxGb
fO5PI9OqOcPICMhohiJzt1o+5JQ3VtjJtKTy+L7dvZIpognBcHV4MFxJbEoV1apx+8wZJiX9bkJCjmhCx2Ql5DB5
2RDRhGCsvLHKU4uOpWEgc4RAjBHN/GBqOaDli5U3niYUGTka0G08vKm1YYfHiRYNebljp5xThjOMB8PrctTQNPOD
4bzhHcnLUdsloglFxgrr2GtuziC7RDRuZCZV2kg3RTShPoMYI5owDL2f5PPDa3yy4fGfeJoQDOeMfFlSA7PKG9GE
YOhHSGUgGreaxu4jnp/bZzyDMdcnBfMH+p/AM/kQywMAAAAASUVORK5CYII=
""")

def main():
    # Check cache for current hour. UTC
    hourlyCocktail = checkCache()

    # If cache thing returns None, run "get cocktail" function
    if hourlyCocktail == None:
        print("Cache miss, refreshing cocktail")
        hourlyCocktail = getNewCocktail()

    if "error" in hourlyCocktail:
        imgSrc = ERROR_IMG
        ingredients = []
        drinkName = hourlyCocktail

    else:
        imgSrc = http.get(hourlyCocktail["strDrinkThumb"] + "/preview").body()
        ingredients = formatIngredients(hourlyCocktail)
        drinkName = hourlyCocktail["strDrink"]
        print("Displaying Drink: " + drinkName)

    # Render
    return render.Root(
        child =
            render.Column(
                expanded = True,
                children = [
                    render.Row(
                        children = [
                            # Drink Image
                            render.Image(
                                src = imgSrc,
                                width = 25,
                                height = 25,
                            ),
                            # Ingredient List
                            render.Marquee(
                                width = 35,
                                height = 25,
                                scroll_direction = "vertical",
                                child = render.Column(
                                    children = ingredients,
                                ),
                            ),
                        ],
                    ),
                    # Drink Name
                    render.Box(
                        color = "#2E0854",
                        child = render.Marquee(
                            width = 64,
                            #height = 20,
                            child = render.Column(
                                expanded = True,
                                children = [
                                    render.Box(
                                        height = 1,
                                        width = 64,
                                    ),
                                    render.Padding(
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(
                                            content = drinkName,
                                            font = "tom-thumb",
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
    )

# Gets the current cocktail in the cache. Returns None if we need a new one.
def checkCache():
    hour = time.now().in_location("UTC").hour
    lastHourSeen = cache.get("lastHour")
    if lastHourSeen == None:
        return None
    if hour == int(lastHourSeen):
        print("Cache hit, returning cocktail")
        data = cache.get("cocktailData")
        if data == None:
            return None
        return json.decode(data)
    return None

# Stores cocktail and current hour for 75 minutes.
def updateCache(cocktail):
    hour = time.now().in_location("UTC").hour
    cache.set("lastHour", str(hour), 75 * 60)
    cache.set("cocktailData", json.encode(cocktail), 75 * 60)

# Gets the updated cocktail from the API.
def getNewCocktail():
    response = http.get("https://thecocktaildb.com/api/json/v1/1/random.php")

    # if the response isn't in json format
    if "application/json" not in response.headers.get("Content-Type"):
        print("error: " + str(response))
        return "error :("
        # if the API returns an error

    elif response.status_code != 200:
        print("error: " + str(response.status_code))
        return "error: " + str(response.status_code)
        # if the drink doesn't exist

    elif "drinks" not in response.json():
        print("error: " + str(response))
        return "error :("

    cocktail = response.json()["drinks"][0]
    print("Top of the hour! New cocktail: " + cocktail["strDrink"])
    updateCache(cocktail)
    return cocktail

# Creates ingredients list as a list of strings.
def formatIngredients(cocktail):
    list = []
    for index in range(1, 16):
        propertyName = "strIngredient" + str(index)
        if cocktail[propertyName] != None and len(cocktail[propertyName]) > 0:
            ingWords = cocktail[propertyName].split()
            for ind, ing in enumerate(ingWords):
                if len(ing) > 8 and "-" in ing:
                    ingWords[ind] = ing[0:ing.index("-")] + "\n" + ing[ing.index("-"):]
                elif len(ing) > 8:
                    ingWords[ind] = ing[0:8] + "\n" + ing[8:]
            fullIngredientName = " ".join(ingWords)
            bgColor = "#080808"
            if index % 2 == 1:
                bgColor = "#606060"
            height = rowHeight(fullIngredientName)
            list.append(
                render.Box(
                    height = height,
                    padding = 1,
                    color = bgColor,
                    child = render.Row(
                        expanded = True,
                        main_align = "start",
                        children = [
                            render.WrappedText(
                                content = fullIngredientName,
                                color = "#f0f0f0",
                                font = "tom-thumb",
                            ),
                        ],
                    ),
                ),
            )
    return list

# Returns the desired height of the ingredient row.
def rowHeight(str):
    height = 7
    if len(str) > 8:
        height = 14
    if len(str) > 16:
        height = 21
    return height

# No schema.
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
