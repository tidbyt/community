"""
Applet: Last.fm
Summary: Display Last.fm scrobbles
Description: Displays your most recently scrobbled track from Last.fm. Displays Track, Artist, Album Art and an optional clock.
Author: Chuck Hannah
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("time.star", "time")
load("secret.star", "secret")



def main(config):

    userName = config.get("lastFmUser") or "badUser"
    api_key = config.get("lastApiKey") or "badKey"
    clockShown = config.get("showClock") or True

    # handle missing config data
    if(userName == 'badUser'):
        print('bad user')
        return render.Root(
            child = render.WrappedText(
                content="Last.fm Username missing in Tidbyt config.",
                color="#FF0000",
                font="tom-thumb"
            )
        )
    if(api_key == 'badKey'):
        print('bad key')
        return render.Root(
            child = render.WrappedText(
                content="Last.fm API key missing in Tidbyt config.",
                color="#FF0000",
                font="tom-thumb"
            )
        )


    lastFmUrl = "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user="+userName+"&api_key="+api_key+"&format=json" 

    rep = http.get(lastFmUrl)
    if rep.status_code != 200:
        return render.Root(
            child = render.WrappedText(
                content="Could not reach Last.fm API.",
                color="#FF0000",
                font="tom-thumb"
            )
        )

    track = rep.json()["recenttracks"]["track"][0]
    img = http.get(track["image"][0]["#text"])


    now = ''
    if(clockShown == 'true'):
        now = time.now()


    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad=(42,1,0,0),
                    child=render.Text(
                        content= now.format("3:04"),
                        font="tom-thumb",
                        color="#777"
                    )
                ), 
                render.Padding(
                    pad=(0,0,0,0),
                    child=render.Image(src=img.body(), height=32, width=32)
                ),
                render.Box(
                    color="#00FF0000",
                    child=render.Padding(
                        pad=(0,0,0,0),
                        color="#FF000000",
                        child=render.Column(
                            cross_align="end",
                            main_align="start",
                            expanded=False,
                            children=[
                                render.Box(
                                    color="#0000FF00",
                                    height=6
                                ),
                                render.Padding(
                                    pad=(1,1,0,0),
                                    color="#11111199",
                                    child=render.WrappedText("%s" % track["name"], font="tom-thumb", color="#FFFFFF")
                                ),
                                render.Padding(
                                    pad=(1,1,0,0),
                                    color="#11111199",
                                    child=render.WrappedText("%s" % track["artist"]["#text"], font="tom-thumb", color="#FFF")
                                )
                            ]
                        )
                    )
                )   
            ],
        )
    )



def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "lastFmUser",
                name = "Last.fm Username",
                desc = "Name of the Last.fm user to view.",
                icon = "user"
            ),
            schema.Text(
                id = "lastApiKey",
                name = "Last.fm API Key",
                desc = "Get from Last.fm, used to authenticate.",
                icon = "key"
            ),
            schema.Toggle(
                id = "showClock",
                name = "Show Clock?",
                icon = "clock",
                desc = "Displays a clock showing the local time."
            )
        ]
    )