"""
Applet: National Parks
Summary: National park info and pics
Description: Displays interesting facts and pictures of various national parks in the United States.
Author: hklim1
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

NPS_URL = "http://developer.nps.gov/api/v1/parks"
ENCRYPTED_API_KEY = "AV6+xWcEnRp1RyHCmAyC7qmEbynYn5U71Xtp12D94MFpDphg3+bMl+NxPbjaAqx02vWkjpKi0PPymac57nBi9sTHgZUva2dJ0H16B509IGMAtUYgc5EMMqVrgTAcncMvgn3vA1V6teqg4E9MPErRtagbf2TMxplyssfd7ORMSRNeghXVfxCyDds/e8Lt/A=="

def getData():
    api_key = secret.decrypt(ENCRYPTED_API_KEY)
    params = {
        # 'q':'National Park',
        "limit": "471",
    }
    res = http.get(NPS_URL, headers = {"X-Api-Key": "%s" % api_key}, ttl_seconds = 3600, params = params)  # cache for 1 hour
    return res.json()

def getImgData(imgUrl):
    return http.get(imgUrl).body()

def getRandomPark():
    num = random.number(0, 470)
    return num

def shortenDescription(desc):
    finalString = ""
    descSplit = desc.split(".")
    for sentence in descSplit:
        if len(finalString) < 200:
            finalString += sentence
            finalString += ". "
        else:
            break
    return finalString

def main(config):
    randomNumber = getRandomPark()
    park = int(config.get("park", str(randomNumber)))
    data = getData()
    if "error" in data:
        return []
    parkName = data["data"][park]["fullName"]
    parkDescription = data["data"][park]["description"]
    parkImage = data["data"][park]["images"][0]["url"]

    header = render.Padding(
        child = render.Marquee(
            width = 64,
            child = render.Text(content = parkName, color = "#ffffff", font = "tom-thumb"),
            offset_start = 1,
            offset_end = 2,
        ),
        pad = (0, 2, 0, 0),
    )

    underline = render.Row(
        children = [
            render.Box(width = 64, height = 2, color = "#f28482"),
        ],
    )

    image = render.Padding(
        child = render.Image(
            src = getImgData(parkImage),
            width = 25,
            height = 20,
        ),
        pad = (1, 1, 0, 0),
    )

    description = render.Padding(
        child = render.Marquee(
            height = 32,
            child = render.WrappedText(
                content = shortenDescription(parkDescription),
                width = 35,
                color = "#f6bd60",
                font = "tom-thumb",
            ),
            offset_start = 0,
            scroll_direction = "vertical",
        ),
        pad = (1, 1, 1, 1),
    )

    imageAndDescription = render.Row(
        children = [image, description],
    )

    return render.Root(
        render.Column(
            children = [header, underline, imageAndDescription],
        ),
        delay = 7,
    )

def get_schema():
    randomNumber = getRandomPark()

    # FINDING INDEX VALUES FOR EACH NATIONAL PARK FOR DROPDOWN OPTIONS:
    # ================================================================
    # strings = []
    # for idx, park in enumerate(data["data"]):
    #     if "National Park" in park["fullName"]:
    #         strings.append('''schema.Option(display = "%s", value = "%s"),''' % (park["fullName"], idx))
    # for s in strings:
    #     print(s)
    options = [
        schema.Option(display = "Random", value = "%s" % randomNumber),
        schema.Option(display = "Acadia National Park", value = "1"),
        schema.Option(display = "Arches National Park", value = "24"),
        schema.Option(display = "Badlands National Park", value = "29"),
        schema.Option(display = "Big Bend National Park", value = "35"),
        schema.Option(display = "Biscayne National Park", value = "42"),
        schema.Option(display = "Black Canyon Of The Gunnison National Park", value = "43"),
        schema.Option(display = "Bryce Canyon National Park", value = "54"),
        schema.Option(display = "Canyonlands National Park", value = "64"),
        schema.Option(display = "Capitol Reef National Park", value = "71"),
        schema.Option(display = "Carlsbad Caverns National Park", value = "75"),
        schema.Option(display = "Channel Islands National Park", value = "86"),
        schema.Option(display = "Congaree National Park", value = "102"),
        schema.Option(display = "Crater Lake National Park", value = "106"),
        schema.Option(display = "Cuyahoga Valley National Park", value = "111"),
        schema.Option(display = "Death Valley National Park", value = "115"),
        schema.Option(display = "Denali National Park & Preserve", value = "117"),
        schema.Option(display = "Dry Tortugas National Park", value = "121"),
        schema.Option(display = "Everglades National Park", value = "135"),
        schema.Option(display = "Gates Of The Arctic National Park & Preserve", value = "173"),
        schema.Option(display = "Gateway Arch National Park", value = "174"),
        schema.Option(display = "Glacier Bay National Park & Preserve", value = "184"),
        schema.Option(display = "Glacier National Park", value = "185"),
        schema.Option(display = "Grand Canyon National Park", value = "192"),
        schema.Option(display = "Grand Teton National Park", value = "195"),
        schema.Option(display = "Great Basin National Park", value = "197"),
        schema.Option(display = "Great Sand Dunes National Park & Preserve", value = "200"),
        schema.Option(display = "Great Smoky Mountains National Park", value = "201"),
        schema.Option(display = "Guadalupe Mountains National Park", value = "204"),
        schema.Option(display = "Haleakalā National Park", value = "208"),
        schema.Option(display = "Hawaiʻi Volcanoes National Park", value = "216"),
        schema.Option(display = "Hot Springs National Park", value = "225"),
        schema.Option(display = "Indiana Dunes National Park", value = "231"),
        schema.Option(display = "Isle Royale National Park", value = "232"),
        schema.Option(display = "Joshua Tree National Park", value = "242"),
        schema.Option(display = "Katmai National Park & Preserve", value = "247"),
        schema.Option(display = "Kenai Fjords National Park", value = "248"),
        schema.Option(display = "Kobuk Valley National Park", value = "256"),
        schema.Option(display = "Lake Clark National Park & Preserve", value = "259"),
        schema.Option(display = "Lassen Volcanic National Park", value = "263"),
        schema.Option(display = "Mammoth Cave National Park", value = "280"),
        schema.Option(display = "Mesa Verde National Park", value = "290"),
        schema.Option(display = "Mount Rainier National Park", value = "303"),
        schema.Option(display = "National Park of American Samoa", value = "311"),
        schema.Option(display = "National Parks of New York Harbor", value = "312"),
        schema.Option(display = "New River Gorge National Park & Preserve", value = "320"),
        schema.Option(display = "North Cascades National Park", value = "326"),
        schema.Option(display = "Olympic National Park", value = "332"),
        schema.Option(display = "Petrified Forest National Park", value = "348"),
        schema.Option(display = "Pinnacles National Park", value = "351"),
        schema.Option(display = "Rocky Mountain National Park", value = "373"),
        schema.Option(display = "Saguaro National Park", value = "379"),
        schema.Option(display = "Sequoia & Kings Canyon National Parks", value = "398"),
        schema.Option(display = "Shenandoah National Park", value = "399"),
        schema.Option(display = "Theodore Roosevelt National Park", value = "417"),
        schema.Option(display = "Virgin Islands National Park", value = "442"),
        schema.Option(display = "Voyageurs National Park", value = "443"),
        schema.Option(display = "White Sands National Park", value = "452"),
        schema.Option(display = "Wind Cave National Park", value = "456"),
        schema.Option(display = "Wolf Trap National Park for the Performing Arts", value = "458"),
        schema.Option(display = "Wrangell - St Elias National Park & Preserve", value = "462"),
        schema.Option(display = "Yellowstone National Park", value = "465"),
        schema.Option(display = "Yosemite National Park", value = "467"),
        schema.Option(display = "Zion National Park", value = "470"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "park",
                name = "National Park",
                desc = "The national park to be displayed.",
                icon = "landmark",
                default = options[0].value,
                options = options,
            ),
        ],
    )
