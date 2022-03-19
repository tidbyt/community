"""
Applet: Destiny 2 Stats
Summary: Display Destiny stats
Description: Gets the emblem, race, class, and light level of your most recently played Destiny 2 charact✗ Summary (what's the short and sweet of what this app does?): Gets the emblem, race, class, and light level of your most recently played Destiny 2 charact✗ Summary (what's the short and sweet of what this app does?): Gets the emblem, race, class, and light level of your most recently played Destiny 2 character.
Author: brandontod97
"""

load("render.star", "render")
load("time.star", "time")
load("http.star", "http")
load("schema.star", "schema")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("secret.star", "secret")

DEFAULT_DISPLAY_NAME = "CatLover"
DEFAULT_DISPLAY_NAME_CODE = "12345"

API_BASE_URL = "https://www.bungie.net/platform"
API_USER_PROFILE = API_BASE_URL + "/User/GetBungieNetUserById/"
API_SEARCH_BUNGIE_ID = API_BASE_URL + "/User/Search/GlobalName/0/"
API_SEARCH_BUNGIE_ID_NAME = API_BASE_URL + "/Destiny2/SearchDestinyPlayerByBungieName/-1/"

def main(config):
    display_name = config.str("display_name", DEFAULT_DISPLAY_NAME)
    display_name_code = config.str("display_name_code", DEFAULT_DISPLAY_NAME_CODE)
    displayed_character = ""

    api_key = secret.decrypt("""
        AV6+xWcEb6J6iGViuBbqg9hnO0qHwC/GoWFEAqTpZd7iLr+Qq9SQqBVZAVT9JiQRx/6OKVf7lrmRQxD7
        e+6BfIGQT3KnXSJyuamnrerYO0eBOTbJTXa+GtmArz0apudd8z2t9J8FslLrBYrDrNENrzlBo6wxy6TR
        z2L6Qszwv4oBhSwAj0A=
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

            #should fail but this is affecting things
            #substiuting garbage strings is enough to trigger the applet error handling if the data is wrong
            #fail("Required arguments were not provided.")

        apiResponse = http.post(
            API_SEARCH_BUNGIE_ID_NAME,
            headers = {"X-API-Key": api_key},
            json_body = {"displayName": display_name, "displayNameCode": display_name_code},
        )

        print(apiResponse.json())
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
            bungie_membership_id = apiResponse.json()["Response"][0]["membershipId"]
            bungie_membership_type = apiResponse.json()["Response"][0]["membershipType"]

            apiMembershipInfo = http.get(
                API_BASE_URL + "/Destiny2/" + str(int(bungie_membership_type)) + "/Profile/" + bungie_membership_id + "/",
                params = {"components": "Characters"},
                headers = {"X-API-Key": api_key},
            )

            displayed_character = apiMembershipInfo.json()["Response"]["characters"]["data"][get_last_played_character(apiMembershipInfo.json()["Response"]["characters"]["data"])]
            cache.set("character" + display_name + display_name_code, json.encode(displayed_character), ttl_seconds = 30)

    image = get_image("https://www.bungie.net" + displayed_character["emblemPath"])

    return render.Root(
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

def get_last_played_character(characters_list):
    most_recent_character = {
        "id": "",
        "date": {
            "year": 1111,
            "month": 0o0,
            "day": 0o0,
            "hour": 0o0,
            "minute": 0o0,
        },
    }

    for character in characters_list:
        date_string = characters_list[character]["dateLastPlayed"]

        year = int(date_string[0:4])
        month = int(date_string[5:7])
        day = int(date_string[8:10])

        hour = int(date_string[11:13])
        minute = int(date_string[14:16])

        if year > most_recent_character["date"]["year"]:
            most_recent_character["date"]["year"] = year
            most_recent_character["date"]["month"] = month
            most_recent_character["date"]["day"] = day
            most_recent_character["date"]["hour"] = hour
            most_recent_character["date"]["minute"] = minute

            most_recent_character["id"] = character

        elif year == most_recent_character["date"]["year"]:
            if month > most_recent_character["date"]["month"]:
                most_recent_character["date"]["year"] = year
                most_recent_character["date"]["month"] = month
                most_recent_character["date"]["day"] = day
                most_recent_character["date"]["hour"] = hour
                most_recent_character["date"]["minute"] = minute

                most_recent_character["id"] = character

            elif month == most_recent_character["date"]["month"]:
                if day > most_recent_character["date"]["day"]:
                    most_recent_character["date"]["year"] = year
                    most_recent_character["date"]["month"] = month
                    most_recent_character["date"]["day"] = day
                    most_recent_character["date"]["hour"] = hour
                    most_recent_character["date"]["minute"] = minute

                    most_recent_character["id"] = character

                elif day == most_recent_character["date"]["day"]:
                    if hour > most_recent_character["date"]["hour"]:
                        most_recent_character["date"]["year"] = year
                        most_recent_character["date"]["month"] = month
                        most_recent_character["date"]["day"] = day
                        most_recent_character["date"]["hour"] = hour
                        most_recent_character["date"]["minute"] = minute

                        most_recent_character["id"] = character

                    elif hour == most_recent_character["date"]["hour"]:
                        if minute > most_recent_character["date"]["minute"]:
                            most_recent_character["date"]["year"] = year
                            most_recent_character["date"]["month"] = month
                            most_recent_character["date"]["day"] = day
                            most_recent_character["date"]["hour"] = hour
                            most_recent_character["date"]["minute"] = minute

                            most_recent_character["id"] = character

                        elif minute == most_recent_character["date"]["minute"]:
                            pass
                            #if the minute is the same, which shouldnt be possible, then just let it be.

        return most_recent_character["id"]

def get_image(url):
    if url:
        print("Getting " + url)
        response = http.get(url)

        if response.status_code == 200:
            return response.body()
        else:
            return base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABKklEQVRYCe2VUY7DIAxEQ9UD9f6n6I3SDPCQMURVpUD6gbVbw2A8g4OTsG/b8XefPaEODCZ5Tv0Qn8gBZvCLiwNHASKdJcKSi7cImCHCk4uz3AFNZCMrQdkTU/ptBLD4YnCRf5/kqR7BScxQeAlYFQhHb+60h/p0hlm+tg13JyMc4RbTXNbDLP4tLibpvIgizuYcVGEiZh0PhtcGO/ZxJm9bATbLs/EXTLHeJEZm8yWk/hZkLAX6YD8/SVhy2EFvb17vt6EU8+8TcRpwJQdjrLknZY192f9XF9j2GPExIr8tQv8R2IjB4yVgVeD2ClTvAS58fnEyvcz7NhRP8y0Q6AOvUtDLXT2CXsBV5Mqjg4nDWhEwmhxSLyLeAS2OKjvE3lOJcgcAfODo+Qful09RLycDuQAAAABJRU5ErkJggg==""")

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

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "display_name",
                name = "Display Name",
                desc = "Your display name for your bungie account. This consists of your username before the #.",
                icon = "user",
            ),
            schema.Text(
                id = "display_name_code",
                name = "Display Code",
                desc = "Your display code for your bungie account. This consists of the numbers after the # in your bungie ID.",
                icon = "code",
            ),
        ],
    )
