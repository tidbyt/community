"""
Applet: FFXIV Character
Summary: Show your FFXIV Character
Description: Shows the latest details about your Final Fantasy XIV character from the lodestone.
Author: mrburrito
"""

load("bsoup.star", "bsoup")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

NOT_FOUND = "Not Found"
LOAD_ERROR = "Load Error"

ROLE_COLORS = {
    "dps": "#7E3A3B",
    "tank": "#4155B9",
    "healer": "#487B39",
    "crafter": "#6447A8",
    "gatherer": "#B89A40",
}

JOB_ROLES = {
    "Paladin / Gladiator": "tank",
    "Warrior / Marauder": "tank",
    "Dark Knight": "tank",
    "Gunbreaker": "tank",
    "White Mage / Conjurer": "healer",
    "Scholar": "healer",
    "Astrologian": "healer",
    "Sage": "healer",
    "Monk / Pugilist": "dps",
    "Dragoon / Lancer": "dps",
    "Ninja / Rogue": "dps",
    "Samurai": "dps",
    "Reaper": "dps",
    "Viper": "dps",
    "Bard / Archer": "dps",
    "Machinist": "dps",
    "Dancer": "dps",
    "Black Mage / Thaumaturge": "dps",
    "Summoner / Arcanist": "dps",
    "Red Mage": "dps",
    "Pictomancer": "dps",
    "Blue Mage (Limited Job)": "dps",
    "Carpenter": "crafter",
    "Blacksmit": "crafter",
    "Armorer": "crafter",
    "Goldsmith": "crafter",
    "Leaterworker": "crafter",
    "Weaver": "crafter",
    "Alchemist": "crafter",
    "Culinarian": "crafter",
    "Miner": "gatherer",
    "Botanist": "gatherer",
    "Fisher": "gatherer",
}

def load_character_profile(lodestone_id):
    url = "https://na.finalfantasyxiv.com/lodestone/character/%s/#profile" % (lodestone_id)
    return get_raw_url(url)

def get_raw_url(url):
    res = http.get(url, ttl_seconds = 3600)
    if res.status_code == 404:
        return NOT_FOUND
    elif res.status_code >= 400:
        return "%s: %d" % (LOAD_ERROR, res.status_code)
    return res.body()

def extract_character_info(profile):
    soup = bsoup.parseHtml(profile)

    # Extract the character face
    face_tag = soup.find("div", {"class": "frame__chara__face"}).find("img")
    face_src = face_tag.attrs()["src"] if face_tag else ""

    # Extract the character image
    image_tag = soup.find("div", {"class": "character__detail__image"}).find("img")
    image_src = image_tag.attrs()["src"] if image_tag else ""

    # Extract the character name
    title_tag = soup.find("p", {"class": "frame__chara__title"})
    name_tag = soup.find("p", {"class": "frame__chara__name"})
    home_world_tag = soup.find("p", {"class": "frame__chara__world"})
    title = title_tag.get_text() if title_tag else ""
    name = name_tag.get_text() if name_tag else "???"
    home_world = home_world_tag.get_text().split(" ")[0] if home_world_tag else "???"

    # Class data
    class_data = soup.find("div", {"class": "character__class__data"})
    level = class_data.find("p").get_text().strip().split(" ")[-1]
    class_icon = class_data.find("div", {"class": "character__class_icon"}).find("img").attrs()["src"]
    class_name_img = class_data.find("img", {"class": "character__classjob"}).attrs()["src"]
    class_icon_images = soup.find_all("img", {"src": class_icon})
    class_name = ""
    for img in class_icon_images:
        class_name = img.attrs().get("data-tooltip")
        if class_name:
            break

    return {
        "name": name,
        "title": title,
        "home_world": home_world,
        "face_url": face_src,
        "image_url": image_src,
        "job_level": level,
        "job_icon_url": class_icon,
        "job_name": class_name or "",
        "job_name_url": class_name_img,
    }

def make_error(msg):
    return render.Root(child = render.WrappedText(content = msg, color = "#ff0000"))

def main(config):
    lodestone_id = config.get("lodestone_id")
    if not lodestone_id:
        return make_error("No Lodestone ID provided")

    profile = load_character_profile(lodestone_id)

    if profile == NOT_FOUND:
        return make_error("Character %s not found..." % lodestone_id)
    elif profile.startswith(LOAD_ERROR):
        return make_error(profile)

    character_data = extract_character_info(profile)
    job_color = ROLE_COLORS.get(JOB_ROLES.get(character_data["job_name"]), "#ffffff")

    return render.Root(
        delay = 100,
        child = render.Row(
            children = [
                render.Column(
                    children = [
                        render.Image(src = get_raw_url(character_data["image_url"]), height = 32),
                    ],
                    main_align = "center",
                    expanded = True,
                ),
                render.Column(
                    children = [render.Box(width = 1)],
                ),
                render.Column(
                    main_align = "space_around",
                    expanded = True,
                    children = [
                        render.Marquee(child = render.Text(content = character_data["title"] + " " + character_data["name"], color = job_color), width = 40),
                        render.WrappedText(content = character_data["home_world"]),
                        render.Row(
                            cross_align = "center",
                            children = [
                                render.Image(src = get_raw_url(character_data["face_url"]), height = 12),
                                render.Padding(
                                    pad = (1, 0, 1, 0),
                                    child = render.Image(src = get_raw_url(character_data["job_icon_url"]), width = 12),
                                ),
                                render.Text(content = character_data["job_level"], color = job_color),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "lodestone_id",
                name = "Lodestone ID",
                desc = "The Lodestone Character ID",
                icon = "circleUser",
            ),
        ],
    )
