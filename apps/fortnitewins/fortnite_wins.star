""" 
Fortnite Win Tracker by Hunter Berry

Applet/App Name: Fortnite Win Tracker
Author: Hunter Berry (https://www.github.com/HunBurry)
Summary: Tracks Fortnite wins. 
Description: Shows how many wins the user has in each main game mode (i.e., Solos, Duos, Trios, and Squads).

Example gif generated through the following command: 
    pixlet render fortnite_wins.star username="HunBurry05" show_kd=True show_win_rate=True --gif --magnify 10
"""

######################################################################################### Loads/Imports #########################################################################################

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

######################################################################################### Global Variables #########################################################################################

yellow = "#ffcc66"
blue = "#3399ff"

icon_left = base64.decode("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")
#icon_right = base64.decode("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")

default_username = None

######################################################################################### Helper Functions ########################################################################################

def float_to_string_without_trailing_decimal(f):
    if f % 1 == 0:
        return str(int(f))
    else:
        return str(f)

######################################################################################### Main Function #########################################################################################

def main(config):
    decrypted_key = secret.decrypt("AV6+xWcEV7GacJDEp2zeLrBSz3B9Zs7vJXr0DjyUa2llQTDRSYQEZjfunRXRXG7cWxeIEda9H1nskXpFtFw1KmcYAf09+wjpCZe+T1p9vFdbYO72NYHc5s0vpjj+MXuqsQDhgkMPOlLpYdkH/Md0/aBnAdmU4lq4qWLx+kTMbnJAmfqido+6g1c=")
    headers = {
        "Authorization": decrypted_key,
    }

    username = config.str("username", default_username)
    show_kd = config.bool("show_kd")
    win_rate = config.bool("show_win_rate")

    if username == None:  # Eror message prompting user to input a username into the app.
        message = "No username found... Input a username in the app to check your wins here!"
    else:
        primary_url = "https://fortniteapi.io/v1/lookup?username=" + username
        accountID_request = http.get(primary_url, headers = headers, ttl_seconds = 86400)

        if accountID_request.status_code != 200:  # Can't find the passed in username.
            message = "Couldn't find your Epic account information... Make sure to use your Epic account username and not your display name!"
            print("Fortnite player lookup request failed because the username can't be found..")
        else:  # Username can be found, proceed.
            accountID = accountID_request.json()["account_id"]
            secondary_url = "https://fortniteapi.io/v1/stats?account=" + accountID
            playerStats_request = http.get(secondary_url, headers = headers, ttl_seconds = 1200)

            if playerStats_request.status_code != 200:  #Something went wrong and we can't get the account associated with the ID.
                message = "We couldn't find a Fortnite account associated with the given Epic username."
                print("Fortnite player stats request failed because something went wrong...")

            if playerStats_request.json().get("code", None) == "PRIVATE_ACCOUNT":
                message = "Sorry, your account is private, so we can't view your stats! Make your account public to see stats."
                print("Fortnite player stats request failed because the user's account is private.")

            else:
                playerStats_request = playerStats_request.json()
                squad_wins = "Squads: " + float_to_string_without_trailing_decimal(playerStats_request["global_stats"]["squad"]["placetop1"])
                trio_wins = "Trios: " + float_to_string_without_trailing_decimal(playerStats_request["global_stats"]["trio"]["placetop1"])
                duo_wins = "Duos: " + float_to_string_without_trailing_decimal(playerStats_request["global_stats"]["duo"]["placetop1"])
                solo_wins = "Solos: " + float_to_string_without_trailing_decimal(playerStats_request["global_stats"]["solo"]["placetop1"])

                if show_kd:
                    squad_wins = squad_wins + " (K/D: " + str(playerStats_request["global_stats"]["squad"]["kd"]) + ")"
                    trio_wins = trio_wins + " (K/D: " + str(playerStats_request["global_stats"]["trio"]["kd"]) + ")"
                    duo_wins = duo_wins + " (K/D: " + str(playerStats_request["global_stats"]["duo"]["kd"]) + ")"
                    solo_wins = solo_wins + " (K/D: " + str(playerStats_request["global_stats"]["solo"]["kd"]) + ")"
                if win_rate:
                    squad_wins = squad_wins + " (W/L: " + str(playerStats_request["global_stats"]["squad"]["winrate"]) + ")"
                    trio_wins = trio_wins + " (W/L: " + str(playerStats_request["global_stats"]["trio"]["winrate"]) + ")"
                    duo_wins = duo_wins + " (W/L: " + str(playerStats_request["global_stats"]["duo"]["winrate"]) + ")"
                    solo_wins = solo_wins + " (W/L: " + str(playerStats_request["global_stats"]["solo"]["winrate"]) + ")"

                message = solo_wins + "    " + duo_wins + "    " + trio_wins + "    " + squad_wins

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Image(
                                    src = icon_left,
                                    width = 16,
                                    height = 16,
                                ),
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (4, 0, 0, 0),
                                            child = render.WrappedText(
                                                content = "Fortnite Win Tracker",
                                                color = yellow,
                                                align = "center",
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 48,
                    child = render.Text(
                        message,
                        color = blue,
                    ),
                ),
            ],
        ),
    )

########################################################################################### Schema ###########################################################################################

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Fortnite Username",
                desc = "Fortnite/Epic Games Username. Please note this may or may not be the same as your display name.",
                icon = "user",
            ),
            schema.Toggle(
                id = "show_kd",
                name = "Show K/D Ratio?",
                desc = "Turn on to show your K/D ratio for each game mode alongside your wins.",
                icon = "gun",
                default = False,
            ),
            schema.Toggle(
                id = "show_win_rate",
                name = "Show Win Rate?",
                desc = "Turn on to show your win/loss ratio for each game mode alongside your wins.",
                icon = "crown",
                default = False,
            ),
        ],
    )
