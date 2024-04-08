"""
Applet: ClashClansTrophy
Summary: Displays Trophy Count
Description: Displays trophies for Clash of Clans.
Author: Brandon Marks
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

CLASH_URL = "https://cocproxy.royaleapi.dev/v1/players/%23"
ENCRYPTED_API_KEY = "AV6+xWcE5FDUpZ3lixi95BpuwknZJBVOeNXaWtI+7lW2qFaefOyA5P8pvAl9ySltp/p6oa3/5mWIHo45SKbb9QekOLY9dcb4HzwQgYilKk3LDfESq3CjOxss8qoCzV978CxAV1WajNtub6DWrCezVG2U606SOkQn/JuUjRWTPG5/hAMU0aCsgKj0g2ni+lGMl9MKPdpSWh+AZhoKa6mIFpPd0dFPsags0KQKlKOVM+CugV8XUEsSx+/27KCnqP2DqL5zXzDpZski4Ej6NltcxiOAHyoarsSwAs7YLWcWt1BvERFLE9S6OUC4lu0YEjyzkzzDmTh7J04HhNymIIOR3TMQKZRlYnAAGskDnojNQ3EP+8p/iRDAiHdihLbylEgouRShdWTlTZBgEPEM81BqDeLUO5mKTi3KsMsu0dd01SxSMd6qVJz2px88U22V1d8mf+Yx/v0sLa44rRa/nHC5Z/ULtFjmr70IDFJP46tyycLpjU48N2GcxJ4V7dIDcRDlFaU85zI00hxGbtZHnjma+9KdmUZUsHsk3UCNdzfrwbZWJs/gHArGquUvMRxt2MTObNq6Liro4Ac+zVvIfGbfq7ahQh1rOZ5WjaUEa64B+ghAjW2BvVXQg/F2Q1lo8sH7/b5jtoVuSxDVOEWTEozh0thxZiVfhdNGHFS+q7ZITk0fCxdrr/mdCYXJ6rZYZ6l1uPHFgxguKvoteSxG8+jfprjDC2KQwPTD0Ts8WDQe6Kuv4X2Yci6WwYwUTSCSyySn+2vpZU0+kCsIKFiBMarGE5dXa5cjwV7JmYINjbztxJFPfBdPum3dXL15yFVzx4FuN6bcIWkw98FTUXuilrf5hfO+DaIJAks7AoNSI7NOrT350BJWs1cTthPYbxfOWkQ="

def main(config):
    playerID = config.get("PlayerID", "")
    pictureChoice = config.get("pictureChoice", "Barbarian")
    nameScrollActive = config.bool("nameScrollActive", "False")

    decrypted_Token = secret.decrypt(ENCRYPTED_API_KEY) or "No_Key"

    #to be displayed in case of error
    trophy_Count = 0
    townHallLevel = 0
    player_Name = "N/A"

    #send request for data
    if (playerID != "" and decrypted_Token != "No_Key"):
        headers_clash = {
            "Authorization": decrypted_Token,
        }

        fullURL = CLASH_URL + playerID
        rep = http.get(fullURL, ttl_seconds = 200, headers = headers_clash)
        if rep.status_code != 200:
            print("\n\nClash API request failed with status %d", rep.status_code)

            # print("Printing below\n")
            # print(rep)
            # print('\n\nHere is the token\n')
            # print(decrypted_Token)
            player_Name = "Not Found"
            nameScrollActive = "True"
        else:
            trophy_Count = rep.json()["trophies"]
            player_Name = rep.json()["name"]
            townHallLevel = rep.json()["townHallLevel"]

    ##handles all rendering of images, delegates to functions for each item
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render_Picture(pictureChoice),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render_Name(player_Name, nameScrollActive),
                            render_TH_row(townHallLevel),
                            render_trophy_Count(trophy_Count),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_Name(name_passed, nameScrollActive):
    if nameScrollActive:
        #text will scroll accross the screen
        return render.Marquee(
            child = render.Text(
                font = "tb-8",
                content = name_passed,
            ),
            width = 34,
        )
    else:
        return render.Text("%s" % name_passed)

def render_Picture(pictureChoice):
    picSRC = determinePicture(pictureChoice)

    return render.Box(
        width = 28,  # Set the width of the box
        height = 28,  # Set the height of the box
        padding = 1,  #surrounds box with blank space
        child = render.Image(src = picSRC, width = 28),
    )

def determinePicture(pictureChoice):
    if (pictureChoice == "1"):
        return BARBARIAN_LOGO
    elif (pictureChoice == "2"):
        return ARCHER_LOGO
    elif (pictureChoice == "3"):
        return GOBLIN_LOGO
    elif (pictureChoice == "4"):
        return WIZARD_LOGO

    #defaults to barbarian
    return BARBARIAN_LOGO

def render_TH_row(townHallLevel):
    return render.Row(
        main_align = "space_evenly",
        cross_align = "center",
        expanded = True,
        children = [
            render.Image(src = CASTLE_ICON),
            render.Text("TH: %d" % townHallLevel),
        ],
    )

def render_trophy_Count(trophy_Count):
    return render.Row(
        main_align = "space_evenly",
        cross_align = "center",
        expanded = True,
        children = [
            render.Image(src = TROPHY_ICON),
            render.Text("%d" % trophy_Count),
        ],
    )

# Set up configuration options
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "PlayerID",
                name = "PlayerID",
                desc = "Account ID; Don't include '#'",
                icon = "user",
            ),
            schema.Toggle(
                id = "nameScrollActive",
                name = "Scrolling Name",
                desc = "A toggle to enable scrolling name.",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "pictureChoice",
                name = "Picture Selection",
                desc = "The choice of what picture to display",
                icon = "brush",
                default = picture_Options[0].value,
                options = picture_Options,
            ),
        ],
    )

picture_Options = [
    schema.Option(
        display = "Barbarian",
        value = "1",
    ),
    schema.Option(
        display = "Archer",
        value = "2",
    ),
    schema.Option(
        display = "Goblin",
        value = "3",
    ),
    schema.Option(
        display = "Wizard",
        value = "4",
    ),
]

BARBARIAN_LOGO = base64.decode("""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
""")
ARCHER_LOGO = base64.decode("""/9j/4AAQSkZJRgABAQAAAQABAAD/4gHYSUNDX1BST0ZJTEUAAQEAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADb/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAAcABwDASIAAhEBAxEB/8QAFgABAQEAAAAAAAAAAAAAAAAABwgJ/8QAKxAAAgEEAQQBAwMFAAAAAAAAAQIDBAUGERIABxMhFAgiQRUxQiMyUWKB/8QAGAEBAAMBAAAAAAAAAAAAAAAAAwAEBQb/xAAnEQABAgQFAwUAAAAAAAAAAAABAhEAAwQFBhIhMYFBkcEiMlFhov/aAAwDAQACEQMRAD8AmbLcMsuBXirskMkhEKh4vKec7qfbNpT92idfagACj2STpA+n3J8RxjIKM3Kjq4a6mrKapNcsM7GOA+XaGMJ7La9H3oRaA+7XU+UGayLebpfLxFVVU8geqramQSSMqmTi7ngjDiGKDbFQOSgb30xdt8d7kZNcrrk+H4JebpS/CpGDwGMiEwNMyl2DHQPk3xG3PA6Un0bNXgmw10sybvWqBOhAISwYkAFQL9BztHdW+rmBhJQCRvoTyW+Yd+7R7XZdl15r+3KbhmSGpq5I7XLSxxq22lM0ZgWWNxyRjvkzK5PFdAvKFTj7+U7jH/ekyyZJmsdmtd9rJ5qCx3S6SUtHUzW8yUdQ6S1240qY3478lKITDOsbhPHMiHZdVTth237XZBjbXDMbmYrh8l04+fh9gC69aP8Ak9BLs1BhinzW+cubKUWdbZgU76slwxG406RFqFSlJb2jpq8TL2pybF8c7lo2cWelqLJW6imhqADDTcyrrvQ0eJUHTN+HJGx1oP2brjac0vC2uilht9esQp4KOhBh0FJVvKzKn82J0p/uI5Egay4oeNzudyjdFhC09bUKYRoq8cHyVIJ2R/UY/t/H1+T1SvZHvd3GxC0/o9uvYmp0p4XjFTErmPnCshC61oAsQB+AAOlx7bwMtxSdzlI+9SD2Ddo1MM1ImJXRrS7gkHwfHMOX1532KbCcexGllpaeonvJuK0qKoeSOnpp2lkA164tJHs/7a/PRG1iuUJ4gSpv3oHXU81XdPOe8UlvzzPr29fc/nXOjhCoscNPThaRxGiKBoblYEnbEa2TrrSHvTjtnpM/rIqOhipovFERHCgRAeI/ZQNDoxLNotFNLPqKytR/EHIqpVdUqyggMG43fkx//9k=
""")
GOBLIN_LOGO = base64.decode("""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
""")
WIZARD_LOGO = base64.decode("""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
""")

TROPHY_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAEpJREFUKFNjZCAAGP8f4vsPV2PwCUM5WAGj3SeIQiQFjHwMjP8/MfxnBGmBm4JmAkgRWAFcEZoJIHHiFSCbAjIaZjKqG0CiaNYAACtEIungk1C/AAAAAElFTkSuQmCC
""")
CASTLE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAGJJREFUKFNjZGBg+M+ABzCCFMyJsmFIWXaEAUSDAIwNouEKsBmComDVGy6GvLw8hkmTJoHpF8s6wCbBTZCIqmBYsPMW2KBPN3cwhIl8Q1UAMoFP3QOsIMFdjQQTVjyTxetNAEUrPKzwqqGJAAAAAElFTkSuQmCC
""")
