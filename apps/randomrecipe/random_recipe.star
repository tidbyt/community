"""
Applet: Random Recipe
Summary: Get a random recipe idea
Description: Display a random recipe from themealdb.com.
Author: noahpodgurski
"""

load("http.star", "http")
load("render.star", "render")

SAMPLE_RESPONSE = {"meals": [{"idMeal": "53064", "strMeal": "Fettuccine Alfredo", "strDrinkAlternate": None, "strCategory": "Pasta", "strArea": "Italian", "strInstructions": "Cook pasta according to package instructions in a large pot of boiling water and salt. Add heavy cream and butter to a large skillet over medium heat until the cream bubbles and the butter melts. Whisk in parmesan and add seasoning (salt and black pepper). Let the sauce thicken slightly and then add the pasta and toss until coated in sauce. Garnish with parsley, and it's ready.", "strMealThumb": "https://www.themealdb.com/images/media/meals/0jv5gx1661040802.jpg", "strTags": None, "strYoutube": "https://www.youtube.com/watch?v=LPPcNPdq_j4", "strIngredient1": "Fettuccine", "strIngredient2": "Heavy Cream", "strIngredient3": "Butter", "strIngredient4": "Parmesan", "strIngredient5": "Parsley", "strIngredient6": "Black Pepper", "strIngredient7": "", "strIngredient8": "", "strIngredient9": "", "strIngredient10": "", "strIngredient11": "", "strIngredient12": "", "strIngredient13": "", "strIngredient14": "", "strIngredient15": "", "strIngredient16": "", "strIngredient17": "", "strIngredient18": "", "strIngredient19": "", "strIngredient20": "", "strMeasure1": "1 lb", "strMeasure2": "1/2 cup ", "strMeasure3": "1/2 cup ", "strMeasure4": "1/2 cup ", "strMeasure5": "2 tbsp", "strMeasure6": " ", "strMeasure7": " ", "strMeasure8": " ", "strMeasure9": " ", "strMeasure10": " ", "strMeasure11": " ", "strMeasure12": " ", "strMeasure13": " ", "strMeasure14": " ", "strMeasure15": " ", "strMeasure16": " ", "strMeasure17": " ", "strMeasure18": " ", "strMeasure19": " ", "strMeasure20": " ", "strSource": "https://www.delish.com/cooking/recipe-ideas/a55312/best-homemade-fettuccine-alfredo-recipe/", "strImageSource": None, "strCreativeCommonsConfirmed": None, "dateModified": None}]}
TITLE = "d95b52"
BLUE = "52c3d9"

REFRESH_TIME = 60

def request():
    res = http.get("https://www.themealdb.com/api/json/v1/1/random.php", ttl_seconds = REFRESH_TIME)
    if res.status_code != 200:
        return SAMPLE_RESPONSE
        # fail("request failed with status %d", res.status_code)

    return res.json()

def main():
    data = request()["meals"][0]

    imageUrl = data["strMealThumb"]
    imageSrc = http.get(imageUrl, ttl_seconds = REFRESH_TIME).body()

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Row(
                children = [
                    render.Column(
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.WrappedText(align = "center", content = data["strMeal"], color = TITLE) if len(data["strMeal"]) < 16 else render.Marquee(
                                offset_start = 32,
                                offset_end = 32,
                                width = 32,
                                height = 6,
                                child = render.Text(data["strMeal"], color = TITLE),
                            ),
                            render.Box(width = 32, height = 1, color = "ffffff"),
                            render.WrappedText(align = "center", content = data["strCategory"], font = "tom-thumb", color = BLUE) if len(data["strCategory"]) < 14 else render.Marquee(
                                offset_start = 32,
                                offset_end = 32,
                                width = 32,
                                height = 6,
                                child = render.Text(data["strCategory"], font = "tom-thumb", color = BLUE),
                            ),
                            render.WrappedText(align = "center", content = data["strArea"], font = "tom-thumb") if len(data["strArea"]) < 16 else render.Marquee(
                                offset_start = 32,
                                offset_end = 32,
                                width = 32,
                                child = render.Text(data["strArea"], font = "tom-thumb"),
                            ),
                        ],
                    ),
                    render.Image(height = 32, width = 32, src = imageSrc),
                ],
            ),
        ),
    )
