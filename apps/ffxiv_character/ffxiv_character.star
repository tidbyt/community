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

NAME_COLOR = "#ffffff"
WORLD_COLOR = "#B89A40"

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

def get_img_src(soup, parent_class, parent_elem = "div", default = ""):
    tag = soup.find(parent_elem, {"class": parent_class})
    img = tag.find("img") if tag else None
    return img.attrs()["src"] if img else default

def get_text(soup, class_, elem = "p", default = ""):
    tag = soup.find(elem, {"class": class_})
    return tag.get_text() if tag else default

def extract_character_info(profile):
    soup = bsoup.parseHtml(profile)

    # Extract the character face
    face_src = get_img_src(soup, "frame__chara__face")

    # Extract the character image
    image_src = get_img_src(soup, "character__detail__image")

    # Extract the character name and title
    char_info = soup.find("div", {"class": "frame__chara__box"}).find_all("p")
    name = " ".join([p.get_text().strip() for p in char_info if p.attrs().get("class") in ["frame__chara__name", "frame__chara__title"]])
    name = name or "???"
    home_world = get_text(soup, "frame__chara__world").split(" ")[0]

    # Class data
    job_data = soup.find("div", {"class": "character__class__data"})
    job_level = job_data.find("p").get_text().strip().split(" ")[-1]
    job_icon_src = get_img_src(job_data, "character__class_icon")
    job_icon_images = soup.find_all("img", {"src": job_icon_src})
    job_name = None
    for img in job_icon_images:
        job_name = img.attrs().get("data-tooltip")
        if job_name:
            break

    return {
        "name": name,
        "home_world": home_world,
        "face_url": face_src,
        "image_url": image_src,
        "job_level": job_level,
        "job_icon_url": job_icon_src,
        "job_name": job_name or "???",
    }

def make_error(msg):
    return render.Root(child = render.WrappedText(content = msg, color = "#ff0000"))

def portrait_layout(character_data, job_color):
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
                        render.Marquee(child = render.Text(content = character_data["name"], color = NAME_COLOR), width = 40),
                        render.WrappedText(content = character_data["home_world"], color = WORLD_COLOR),
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

def face_layout(character_data, job_color):
    return render.Root(
        delay = 100,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Marquee(child = render.Text(content = character_data["name"], color = NAME_COLOR), width = 64),
                    ],
                ),
                render.Row(
                    cross_align = "space_around",
                    expanded = True,
                    children = [
                        render.Column(
                            children = [
                                render.Padding(
                                    pad = (1, 1, 1, 0),
                                    child = render.Image(src = get_raw_url(character_data["face_url"]), width = 22),
                                ),
                            ],
                        ),
                        render.Column(
                            children = [render.Box(width = 1)],
                        ),
                        render.Column(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.Row(
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        render.Padding(
                                            pad = (0, 0, 1, 0),
                                            child = render.Image(src = get_raw_url(character_data["job_icon_url"]), width = 16),
                                        ),
                                        render.Text(content = character_data["job_level"], color = job_color),
                                    ],
                                ),
                                render.Padding(
                                    pad = (1, 0, 0, 0),
                                    child = render.Marquee(
                                        child = render.Text(content = character_data["home_world"], color = WORLD_COLOR),
                                        width = 40
                                    )
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

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

    return face_layout(character_data, job_color)

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
