"""
Applet: Destiny 2 Stats
Summary: Display Destiny stats
Description: Gets the emblem, race, class, and light level of your most recently played Destiny 2 charact✗ Summary (what's the short and sweet of what this app does?): Gets the emblem, race, class, and light level of your most recently played Destiny 2 charact✗ Summary (what's the short and sweet of what this app does?): Gets the emblem, race, class, and light level of your most recently played Destiny 2 character.
Author: brandontod97
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

DEFAULT_DISPLAY_NAME = secret.decrypt("""
AV6+xWcEj0nmtoLiblYJL8Tu387oZYnoFkMIzs29sUMlHtqDcNuaBDSg
7Mj273WhCIabva6fjNByv9oXUG5H4w37zN/Gx4zvft3gNUz78DA+EvU2I
yDSVa7edZ4GbA0C1AO23gtUDzQYoGXipSU/TZM2awA=
""") or "Placeholder"

DEFAULT_DISPLAY_NAME_CODE = secret.decrypt("""
AV6+xWcEW+/hIGws+9QhH2NgI0+0JougGvaPg7F/8xvI+ur1XLEQwVe0e
zt+7SSJi1TXsj2/CT3QoquSVwf7EVzQl+xsHfGq/iacJZ/gc1Pcp+fHje
/hvHBNx1wnsomBWLrKhIXi4yXOoA==
""") or "1234"

API_BASE_URL = "https://www.bungie.net/platform"
API_USER_PROFILE = API_BASE_URL + "/User/GetBungieNetUserById/"
API_SEARCH_BUNGIE_ID = API_BASE_URL + "/User/Search/GlobalName/0/"
API_SEARCH_BUNGIE_ID_NAME = API_BASE_URL + "/Destiny2/SearchDestinyPlayerByBungieName/-1/"

def main(config):
    display_name = config.get("display_name", DEFAULT_DISPLAY_NAME)
    display_name_code = config.get("display_name_code", DEFAULT_DISPLAY_NAME_CODE)
    show_id = config.bool("show_id", False)
    displayed_character = ""

    api_key = secret.decrypt("""
        AV6+xWcEJkWKqhbjZP7GMtxbpczsXzsEZTDdc8v4kQxRCXPYO6aVT6HktYA192wnXxYXpnbCOL3oBilA
        WOH0pjJxlI5mlmWRZHEbBC2IY7AZ2MM0DUe56sGlqI70M0Zo+2dO0umHJyNA08AXdYGmjIgZYc6OfPQh
        NyM95zq5qE69cen4TO0=
        """) or config.get("dev_api_key")

    character_cached = cache.get("character" + display_name + display_name_code)

    if character_cached != None:
        print("Displaying cached character data")
        displayed_character = json.decode(character_cached)

    else:
        print("No cached data. Hitting API")

        bungie_membership_id = ""
        bungie_membership_type = ""

        if api_key == None or display_name == None or display_name_code == None:
            api_key = "null value"
            display_name = "null value"
            display_name_code = "null value"

        apiResponse = http.post(
            API_SEARCH_BUNGIE_ID_NAME,
            headers = {"X-API-Key": api_key},
            json_body = {"displayName": display_name, "displayNameCode": display_name_code},
        )

        if apiResponse.json()["ErrorStatus"] == "ApiInvalidOrExpiredKey" or len(apiResponse.json()["Response"]) == 0:
            return render.Root(
                child = render.Column(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 8,
                            child = render.Text("Invalid API"),
                        ),
                        render.Box(
                            height = 8,
                            child = render.Text("or"),
                        ),
                        render.Box(
                            height = 8,
                            child = render.Text("Invalid ID"),
                        ),
                    ],
                ),
            )
        else:
            print("Recieved valid response")
            bungie_membership_id = apiResponse.json()["Response"][0]["membershipId"]
            bungie_membership_type = apiResponse.json()["Response"][0]["membershipType"]

            apiMembershipInfo = http.get(
                API_BASE_URL + "/Destiny2/" + str(int(bungie_membership_type)) + "/Profile/" + bungie_membership_id + "/",
                params = {"components": "Characters"},
                headers = {"X-API-Key": api_key},
            )

            displayed_character = apiMembershipInfo.json()["Response"]["characters"]["data"][get_last_played_character(apiMembershipInfo.json()["Response"]["characters"]["data"])]
            cache.set("character" + display_name + display_name_code, json.encode(displayed_character), ttl_seconds = 300)

    image = get_image("https://www.bungie.net" + displayed_character["emblemPath"])

    #TODO: Clean this up and send dictionary of values instead of all the needed values separately
    return get_view(show_id, image, displayed_character, display_name, display_name_code)

def get_last_played_character(characters_list):
    most_recent_character = {
        "id": "",
        "date": time.parse_time("1999-01-01T00:01:00.00Z"),
    }

    for character in characters_list:
        parsed_date = time.parse_time(characters_list[character]["dateLastPlayed"])

        if (parsed_date > most_recent_character["date"]):
            most_recent_character["date"] = parsed_date
            most_recent_character["id"] = character

    return most_recent_character["id"]

def get_image(url):
    if url:
        print("Getting " + url)
        response = http.get(url)

        if response.status_code == 200:
            return response.body()
        else:
            return base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABKklEQVRYCe2VUY7DIAxEQ9UD9f6n6I3SDPCQMURVpUD6gbVbw2A8g4OTsG/b8XefPaEODCZ5Tv0Qn8gBZvCLiwNHASKdJcKSi7cImCHCk4uz3AFNZCMrQdkTU/ptBLD4YnCRf5/kqR7BScxQeAlYFQhHb+60h/p0hlm+tg13JyMc4RbTXNbDLP4tLibpvIgizuYcVGEiZh0PhtcGO/ZxJm9bATbLs/EXTLHeJEZm8yWk/hZkLAX6YD8/SVhy2EFvb17vt6EU8+8TcRpwJQdjrLknZY192f9XF9j2GPExIr8tQv8R2IjB4yVgVeD2ClTvAS58fnEyvcz7NhRP8y0Q6AOvUtDLXT2CXsBV5Mqjg4nDWhEwmhxSLyLeAS2OKjvE3lOJcgcAfODo+Qful09RLycDuQAAAABJRU5ErkJggg==""")

    # Should never get here.
    return ""

def get_character_class(class_value):
    class_value = int(class_value)

    if (class_value == 0):
        return "Titan"

    elif (class_value == 1):
        return "Huntr"

    elif (class_value == 2):
        return "Wrlck"

    else:
        return "Unknown"

def get_character_race(race_value):
    race_value = int(race_value)

    if (race_value == 0):
        return "Human"

    elif (race_value == 1):
        return "Awokn"

    elif (race_value == 2):
        return "Exo"

    else:
        return "Unkn"

def get_view(show_id, image, displayed_character, display_name, display_name_code):
    no_username_view = render.Root(
        child = render.Row(
            cross_align = "center",
            children = [
                render.Image(src = image, width = 32, height = 32),
                render.Box(width = 1, height = 32, color = "#FFFFFF"),
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "right",
                    children = [
                        render.Box(
                            height = 6,
                            child = render.Text(get_character_race(displayed_character["raceType"])),
                        ),
                        render.Box(
                            height = 6,
                            child = render.Text(get_character_class(displayed_character["classType"])),
                        ),
                        render.Box(
                            height = 6,
                            child = render.Text(str(int(displayed_character["light"]))),
                        ),
                    ],
                ),
            ],
        ),
    )

    username_view = render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = image, width = 24, height = 24),
                        render.Box(width = 1, height = 22, color = "#FFFFFF"),
                        render.Column(
                            expanded = False,
                            main_align = "space_around",
                            cross_align = "right",
                            children = [
                                render.Box(
                                    height = 8,
                                    child = render.Text(get_character_race(displayed_character["raceType"])),
                                ),
                                render.Box(
                                    height = 8,
                                    child = render.Text(get_character_class(displayed_character["classType"])),
                                ),
                                render.Box(
                                    height = 8,
                                    child = render.Text(str(int(displayed_character["light"]))),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Box(width = 64, height = 1, color = "#FFFFFF"),
                render.Box(width = 64, height = 1),
                render.Marquee(
                    width = 64,
                    child = render.Row(
                        children = [
                            render.Text(
                                font = "CG-pixel-4x5-mono",
                                content = display_name,
                            ),
                            render.Text(
                                font = "CG-pixel-4x5-mono",
                                color = "#808080",
                                content = "#" + display_name_code,
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

    if show_id:
        return username_view
    else:
        return no_username_view

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "display_name",
                name = "Display Name",
                desc = "Your display name for your bungie account. This consists of your username before the # in your Bungie ID.",
                icon = "user",
            ),
            schema.Text(
                id = "display_name_code",
                name = "Display Code",
                desc = "Your display code for your bungie account. This consists of the numbers after the # in your Bungie ID.",
                icon = "code",
            ),
            schema.Toggle(
                id = "show_id",
                name = "Show ID",
                desc = "Show your Bungie ID.",
                icon = "idCard",
                default = False,
            ),
        ],
    )
