#Shows current song being played on Capital Radio 604.
#
#by Craig J. Johnston
#email: ibanyan@gmail.com

load("http.star", "http")

# Import the required libraries
load("render.star", "render")

#Set the fonts
SMALLFONT = "tom-thumb"
FONT = "tb-8"
HFONT = "6x13"

#Set your IceCast JSON info URL.
icecast_json_url = "https://streaming.galaxywebsolutions.com/json/stream/capitalradio604"

# Main function to render the Tidbyt app

#Here we are calling the JSON info URL and including all the headers.  We check to make sure it returns a HTTP 200.
#If not, we fail the app which makes it stop.

#We can then retirieve the song playing right now plus the last 5 songs played.

def main():
    rep = http.get(icecast_json_url)
    if rep.status_code != 200:
        print("URL %s" % icecast_json_url)
        fail("The request failed with status %d", rep.status_code)

    now_playing = rep.json()["nowplaying"]
    # last_song_1 = rep.json()["trackhistory"][0]
    # last_song_2 = rep.json()["trackhistory"][1]
    # last_song_3 = rep.json()["trackhistory"][2]
    # last_song_4 = rep.json()["trackhistory"][3]
    # last_song_5 = rep.json()["trackhistory"][4]
    # station_name = rep.json()["servername"]
    # We are collecting the last 5 tracks played but not using them just yet ...

    #Simplest layout for version 1.

    return render.Root(
        child = render.Column(
            # Column is a vertical children layout
            children = [
                render.Stack(
                    children = [
                        render.Box(width = 64, height = 13, color = "#ffffff"),
                        render.Text("Capital 604", font = HFONT, height = 12, color = "#228ee9"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Text("Now Playing...", font = FONT, height = 10, color = "#03287c"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text("%s" % now_playing, font = FONT, height = 8),
                        ),
                    ],
                ),
            ],
        ),
    )
