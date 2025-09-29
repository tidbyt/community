load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", r = "render")
load("time.star", "time")

def main():
    res = http.get("https://h3eypycsyiyi5pyun5svwvlri40rltki.lambda-url.us-east-2.on.aws", ttl_seconds = 15)

    if res.status_code != 200:
        return r.Text(content = "HTTP error")

    decoded = json.decode(res.body())
    if not decoded or len(decoded) == 0:
        return r.Text(content = "No NEOs")

    neos = decoded[:10]
    index = time.now().second % len(neos)
    neo = neos[index]

    name = neo.get("name", "Unknown")
    if len(name) > 20:
        name = name[:17] + "..."

    img = http.get("https://upload.wikimedia.org/wikipedia/commons/f/ff/Vesta_Rotation.gif").body()

    raw_date = neo.get("date", "N/A")
    parts = raw_date.split("-")
    if len(parts) == 3:
        month = str(int(parts[1]))
        day = str(int(parts[2]))
        date = month + "/" + day
    else:
        date = raw_date  # fallback

    lunar = str(int(neo.get("miss_distance_lunar", 0) * 100 + 0.5) / 100.0)
    speed = str(int(neo.get("velocity_kph", 0)))

    #speed_mph = int(neo.get("velocity_mph", 0))
    hazard = "!" if neo.get("is_hazardous", False) else ""
    #nyc_la_trips = str(int(neo.get("miss_distance_nyc_to_la_trips", 0)))

    return r.Root(
        child = r.Stack(
            children = [
                r.Box(width = 64, height = 32, padding = 1, color = "#000000", child = r.Box(width = 63, height = 31, color = "#000000")),
                #r.Box(width=63, height=31, color="#000000"),
                r.Column(
                    children = [
                        r.Row(
                            children = [
                                r.Image(src = img, width = 9, height = 9),
                                r.Text(content = " " + hazard + name, color = "#8093f1", height = 10),
                            ],
                        ),
                        #r.Box(width=64, height = 1),
                        r.Box(width = 64, height = 1, color = "#5A5A5A"),
                        r.Text(content = " Date: " + date, font = "tom-thumb", height = 7, color = "#72ddf7"),
                        #r.Text(content=" Lunar: " + lunar, color="#72ddf7", , height=8),
                        r.Text(content = " " + speed + " kph", color = "#b388eb", font = "tom-thumb", height = 7),
                        r.Marquee(width = 64, offset_start = 5, offset_end = 32, height = 5, child = r.Text(content = " L Dist: " + lunar, color = "#f7aef8", font = "tom-thumb", height = 7)),
                    ],
                ),  #, r.Box(width=64, height=11, padding = 1, color="#5A5A5A", child=r.Box(width=63, height=10, color="#000000")),
            ],
        ),
    )
