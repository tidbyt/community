"""
Applet: Random Dogs
Summary: Shows pictures of dogs
Description: Shows random pictures of dogs from dog.ceo.
Author: mattmcquinn
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_IMAGE = base64.decode("""
/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAICAgICAQICAgIDAgIDAwYEAwMDAwcF
BQQGCAcJCAgHCAgJCg0LCQoMCggICw8LDA0ODg8OCQsQERAOEQ0ODg7/2wBDAQID
AwMDAwcEBAcOCQgJDg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4O
Dg4ODg4ODg4ODg4ODg7/wAARCAB3ALMDASIAAhEBAxEB/8QAHgAAAQQDAQEBAAAA
AAAAAAAABgAFBwgDBAkCAQr/xABCEAACAQMDAwIDBgQEAwcFAQABAgMEBREABiEH
EjETQSJRYQgUMnGBkRUjocEWUrHwJELRMzRiorLh8QkXQ4KSo//EABsBAAEFAQEA
AAAAAAAAAAAAAAIAAQMFBwQG/8QAMhEAAQMCBQIFBAEDBQAAAAAAAQACEQMEBRIh
MUFRYRNxgZGhFCKx4cEVMvAzQmKS8f/aAAwDAQACEQMRAD8Aj+TqLMpIh3Jaozj4
0SwP2/1XWmepl0Ldh301KucdtFYRGf6kaAUtKFTlOR+LK+dem28rVsRHHHnUU9kc
KUqHqnW0lR31G7a24wYBZJbWpyf1fRxTdYdnGlWWroa0zAd3fSwpETx8i5B1XeSx
yp3gR5wf6a0DbWjjbvUKQP7aIOhCWq0cXW7bS1UTRrXmBvC1ESMQflgNolousmwq
pVWtlekbOFLUTgL+ozqm4oC0EQbuVV7Rnxn6jX2SnXsZSHdQQoB44+mjkIYV4Iup
HTeoPcu56WIkjPqKy8Y+q63Y9zbAky/+LrWAwz/3xAf151QCQlY2Ks2R4Ungj++s
ETStG2QeQCOOSPrppalBXQes3Z02SldZt2Wx+PiC1Sk8flpil310qCMDuiklZ/JA
Y8Y9sDVGQ8gfv7SOckgfpr48rysR+Ejn4ODpZgllKurN1H6axsAt7laNTn/h6CaR
sjj2Xx9dY/8A7wdKJLjU2+CoutXc44w0lPFYqjuC/PLKFP6E6pnEyvGe6RlcjOcn
j/f76cKSGWsqYUqJGIP/AHeZGz2N9D+ft+uk0sJgpnBwEhTzu7rFt+ts0lv2rZK+
KSd1E9XXQLErAEHt7QSxB9+RnUR1dRX3bcdZc7lMKiqkYciMKiD2Cj2A+WtAFg5h
q2f1u4mT1ByT8/6af6ZD2dvYO0qCWJ8fQ6Yfa5PuEO1tIwLM0Yyw/wCYeeNG1gnS
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
3+kXyB8RYc8aWlpa4ZK6YC//2Q==
""")

def main(config):
    image = DEFAULT_IMAGE
    breed = config.get("breed")
    random = config.bool("random", True)
    if random:
        url = "https://dog.ceo/api/breeds/image/random"
    else:
        url = "https://dog.ceo/api/breed/" + breed + "/images/random"

    # cache the request for a new image for four minutes
    rep = http.get(url, ttl_seconds = 4 * 60)
    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Not fetching new image url.")
    else:
        print("Miss! Fetching new image url.")
    if rep.status_code == 200:
        response = rep.json()
        image_url = response["message"]
        print(image_url)

        # cache the actual image response for 24 hours
        # image data should not change frequently (if ever) so this TTL can be very long
        image_rep = http.get(image_url, ttl_seconds = 60 * 60 * 24)
        if image_rep.headers.get("Tidbyt-Cache-Status") == "HIT":
            print("Hit! Fetching image from cache.")
        else:
            print("Miss! Fetching image data.")
        if image_rep.status_code == 200:
            image = image_rep.body()

    return render.Root(
        child = render.Image(src = image, width = 64, height = 32),
    )

def get_schema():
    options = [
        schema.Option(display = "Affenpinscher", value = "affenpinscher"),
        schema.Option(display = "African", value = "african"),
        schema.Option(display = "Airedale", value = "airedale"),
        schema.Option(display = "Akita", value = "akita"),
        schema.Option(display = "Appenzeller", value = "appenzeller"),
        schema.Option(display = "Shepherd Australian", value = "australian/shepherd"),
        schema.Option(display = "Basenji", value = "basenji"),
        schema.Option(display = "Beagle", value = "beagle"),
        schema.Option(display = "Bluetick", value = "bluetick"),
        schema.Option(display = "Borzoi", value = "borzoi"),
        schema.Option(display = "Bouvier", value = "bouvier"),
        schema.Option(display = "Boxer", value = "boxer"),
        schema.Option(display = "Brabancon", value = "brabancon"),
        schema.Option(display = "Briard", value = "briard"),
        schema.Option(display = "Norwegian Buhund", value = "buhund/norwegian"),
        schema.Option(display = "Boston Bulldog", value = "bulldog/boston"),
        schema.Option(display = "English Bulldog", value = "bulldog/english"),
        schema.Option(display = "French Bulldog", value = "bulldog/french"),
        schema.Option(display = "Staffordshire Bullterrier", value = "bullterrier/staffordshire"),
        schema.Option(display = "Australian Cattledog", value = "cattledog/australian"),
        schema.Option(display = "Cavapoo", value = "cavapoo"),
        schema.Option(display = "Chihuahua", value = "chihuahua"),
        schema.Option(display = "Chow", value = "chow"),
        schema.Option(display = "Clumber", value = "clumber"),
        schema.Option(display = "Cockapoo", value = "cockapoo"),
        schema.Option(display = "Border Collie", value = "collie/border"),
        schema.Option(display = "Coonhound", value = "coonhound"),
        schema.Option(display = "Cardigan Corgi", value = "corgi/cardigan"),
        schema.Option(display = "Cotondetulear", value = "cotondetulear"),
        schema.Option(display = "Dachshund", value = "dachshund"),
        schema.Option(display = "Dalmatian", value = "dalmatian"),
        schema.Option(display = "Great Dane", value = "dane/great"),
        schema.Option(display = "Scottish Deerhound", value = "deerhound/scottish"),
        schema.Option(display = "Dhole", value = "dhole"),
        schema.Option(display = "Dingo", value = "dingo"),
        schema.Option(display = "Doberman", value = "doberman"),
        schema.Option(display = "Norwegian Elkhound", value = "elkhound/norwegian"),
        schema.Option(display = "Entlebucher", value = "entlebucher"),
        schema.Option(display = "Eskimo", value = "eskimo"),
        schema.Option(display = "Lapphund Finnish", value = "finnish/lapphund"),
        schema.Option(display = "Bichon Frise", value = "frise/bichon"),
        schema.Option(display = "Germanshepherd", value = "germanshepherd"),
        schema.Option(display = "Italian Greyhound", value = "greyhound/italian"),
        schema.Option(display = "Groenendael", value = "groenendael"),
        schema.Option(display = "Havanese", value = "havanese"),
        schema.Option(display = "Afghan Hound", value = "hound/afghan"),
        schema.Option(display = "Basset Hound", value = "hound/basset"),
        schema.Option(display = "Blood Hound", value = "hound/blood"),
        schema.Option(display = "English Hound", value = "hound/english"),
        schema.Option(display = "Ibizan Hound", value = "hound/ibizan"),
        schema.Option(display = "Plott Hound", value = "hound/plott"),
        schema.Option(display = "Walker Hound", value = "hound/walker"),
        schema.Option(display = "Husky", value = "husky"),
        schema.Option(display = "Keeshond", value = "keeshond"),
        schema.Option(display = "Kelpie", value = "kelpie"),
        schema.Option(display = "Komondor", value = "komondor"),
        schema.Option(display = "Kuvasz", value = "kuvasz"),
        schema.Option(display = "Labradoodle", value = "labradoodle"),
        schema.Option(display = "Labrador", value = "labrador"),
        schema.Option(display = "Leonberg", value = "leonberg"),
        schema.Option(display = "Lhasa", value = "lhasa"),
        schema.Option(display = "Malamute", value = "malamute"),
        schema.Option(display = "Malinois", value = "malinois"),
        schema.Option(display = "Maltese", value = "maltese"),
        schema.Option(display = "Bull Mastiff", value = "mastiff/bull"),
        schema.Option(display = "English Mastiff", value = "mastiff/english"),
        schema.Option(display = "Tibetan Mastiff", value = "mastiff/tibetan"),
        schema.Option(display = "Mexicanhairless", value = "mexicanhairless"),
        schema.Option(display = "Mix", value = "mix"),
        schema.Option(display = "Bernese Mountain", value = "mountain/bernese"),
        schema.Option(display = "Swiss Mountain", value = "mountain/swiss"),
        schema.Option(display = "Newfoundland", value = "newfoundland"),
        schema.Option(display = "Otterhound", value = "otterhound"),
        schema.Option(display = "Caucasian Ovcharka", value = "ovcharka/caucasian"),
        schema.Option(display = "Papillon", value = "papillon"),
        schema.Option(display = "Pekinese", value = "pekinese"),
        schema.Option(display = "Pembroke", value = "pembroke"),
        schema.Option(display = "Miniature Pinscher", value = "pinscher/miniature"),
        schema.Option(display = "Pitbull", value = "pitbull"),
        schema.Option(display = "German Pointer", value = "pointer/german"),
        schema.Option(display = "Germanlonghair Pointer", value = "pointer/germanlonghair"),
        schema.Option(display = "Pomeranian", value = "pomeranian"),
        schema.Option(display = "Medium Poodle", value = "poodle/medium"),
        schema.Option(display = "Miniature Poodle", value = "poodle/miniature"),
        schema.Option(display = "Standard Poodle", value = "poodle/standard"),
        schema.Option(display = "Toy Poodle", value = "poodle/toy"),
        schema.Option(display = "Pug", value = "pug"),
        schema.Option(display = "Puggle", value = "puggle"),
        schema.Option(display = "Pyrenees", value = "pyrenees"),
        schema.Option(display = "Redbone", value = "redbone"),
        schema.Option(display = "Chesapeake Retriever", value = "retriever/chesapeake"),
        schema.Option(display = "Curly Retriever", value = "retriever/curly"),
        schema.Option(display = "Flatcoated Retriever", value = "retriever/flatcoated"),
        schema.Option(display = "Golden Retriever", value = "retriever/golden"),
        schema.Option(display = "Rhodesian Ridgeback", value = "ridgeback/rhodesian"),
        schema.Option(display = "Rottweiler", value = "rottweiler"),
        schema.Option(display = "Saluki", value = "saluki"),
        schema.Option(display = "Samoyed", value = "samoyed"),
        schema.Option(display = "Schipperke", value = "schipperke"),
        schema.Option(display = "Giant Schnauzer", value = "schnauzer/giant"),
        schema.Option(display = "Miniature Schnauzer", value = "schnauzer/miniature"),
        schema.Option(display = "Italian Segugio", value = "segugio/italian"),
        schema.Option(display = "English Setter", value = "setter/english"),
        schema.Option(display = "Gordon Setter", value = "setter/gordon"),
        schema.Option(display = "Irish Setter", value = "setter/irish"),
        schema.Option(display = "Sharpei", value = "sharpei"),
        schema.Option(display = "English Sheepdog", value = "sheepdog/english"),
        schema.Option(display = "Shetland Sheepdog", value = "sheepdog/shetland"),
        schema.Option(display = "Shiba", value = "shiba"),
        schema.Option(display = "Shihtzu", value = "shihtzu"),
        schema.Option(display = "Blenheim Spaniel", value = "spaniel/blenheim"),
        schema.Option(display = "Brittany Spaniel", value = "spaniel/brittany"),
        schema.Option(display = "Cocker Spaniel", value = "spaniel/cocker"),
        schema.Option(display = "Irish Spaniel", value = "spaniel/irish"),
        schema.Option(display = "Japanese Spaniel", value = "spaniel/japanese"),
        schema.Option(display = "Sussex Spaniel", value = "spaniel/sussex"),
        schema.Option(display = "Welsh Spaniel", value = "spaniel/welsh"),
        schema.Option(display = "Japanese Spitz", value = "spitz/japanese"),
        schema.Option(display = "English Springer", value = "springer/english"),
        schema.Option(display = "Stbernard", value = "stbernard"),
        schema.Option(display = "American Terrier", value = "terrier/american"),
        schema.Option(display = "Australian Terrier", value = "terrier/australian"),
        schema.Option(display = "Bedlington Terrier", value = "terrier/bedlington"),
        schema.Option(display = "Border Terrier", value = "terrier/border"),
        schema.Option(display = "Cairn Terrier", value = "terrier/cairn"),
        schema.Option(display = "Dandie Terrier", value = "terrier/dandie"),
        schema.Option(display = "Fox Terrier", value = "terrier/fox"),
        schema.Option(display = "Irish Terrier", value = "terrier/irish"),
        schema.Option(display = "Kerryblue Terrier", value = "terrier/kerryblue"),
        schema.Option(display = "Lakeland Terrier", value = "terrier/lakeland"),
        schema.Option(display = "Norfolk Terrier", value = "terrier/norfolk"),
        schema.Option(display = "Norwich Terrier", value = "terrier/norwich"),
        schema.Option(display = "Patterdale Terrier", value = "terrier/patterdale"),
        schema.Option(display = "Russell Terrier", value = "terrier/russell"),
        schema.Option(display = "Scottish Terrier", value = "terrier/scottish"),
        schema.Option(display = "Sealyham Terrier", value = "terrier/sealyham"),
        schema.Option(display = "Silky Terrier", value = "terrier/silky"),
        schema.Option(display = "Tibetan Terrier", value = "terrier/tibetan"),
        schema.Option(display = "Toy Terrier", value = "terrier/toy"),
        schema.Option(display = "Welsh Terrier", value = "terrier/welsh"),
        schema.Option(display = "Westhighland Terrier", value = "terrier/westhighland"),
        schema.Option(display = "Wheaten Terrier", value = "terrier/wheaten"),
        schema.Option(display = "Yorkshire Terrier", value = "terrier/yorkshire"),
        schema.Option(display = "Tervuren", value = "tervuren"),
        schema.Option(display = "Vizsla", value = "vizsla"),
        schema.Option(display = "Spanish Waterdog", value = "waterdog/spanish"),
        schema.Option(display = "Weimaraner", value = "weimaraner"),
        schema.Option(display = "Whippet", value = "whippet"),
        schema.Option(display = "Irish Wolfhound", value = "wolfhound/irish"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "random",
                name = "Random Breed",
                desc = "Show any random breed",
                icon = "shuffle",
                default = True,
            ),
            schema.Dropdown(
                id = "breed",
                name = "Specific Breed",
                desc = "A specific breed to show (turn random off)",
                icon = "dog",
                options = options,
                default = "dachshund", # fits the dimensions of the Tidbyt well ;-)
            ),
        ],
    )
