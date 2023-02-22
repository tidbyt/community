"""
Applet: ISS Tracker
Summary: Tracks the ISS Position
Description: Tracks the position of the International Space Station using LAT/LONG coordinates.
Author: Chris Jones (@IPv6Freely)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ISS_URL = "http://api.open-notify.org/iss-now.json"

ISS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAqdJREFUOE99VEty
2kAQ7ckZyApSkZ0T4B1ibW4DlGFpvDZexCwhS5MzBJ8ACYqPyJqPRElaGY6AOtXdI2mUUJmFLTGjN69f
v9cKzKUAAAHon+P5WKveKP5JASjkLdnkh+tLXTvgeAds95fwEcUQOA8EIYAZWPrwLzofTq8ldGe9x9bL
Ck5hCL7TUc7aR/tOM83O0oOUkiSInxQXUtjlTWdNzFbwEUXMzF352HxZwJnfuwq5VPoj3yeY4NwL4G2y
g1HvnoSRHdZsfcAmMcvA6H0JpzCGo/NAFRcEJGazTQDjyRZGvQZzpAsZkMBa/RWc4hACKnPlY5vAohD8
aScrRzAVYHJB1zvC+H0Ho8cGQeWyWfUBlsplOMUxHKcdNWUNl3AOI9aQy9D8iAEmCc42R12mgJm94qIt
+xWJmbv2sdVfiIZTasgB7bvbjCEiorvx4eevHQyfGnyPWEnXKzwJE+FrfYCfKxUp0+lkh13vgLXqrUJM
cOYFMH7fcwOkQYaumYfT+xHAqr8iMctvlFPUgPlvH8aTPQwf76UBuXMAxf5F26SJYMaI2sQKcmZbGHID
iiutoOhDLlzabq6Cz54arLFdvcks5LI7SHMjUUI2NaSoTO8JXnDO1thqa8hVFMta9ZtyvD22n8Vq/rSr
6He6LOWWEaMLiFnaANKsQFsninx7NuLZ7i/YegagcE19RsyGPa2ZMWZIs2afEkRx7CjX87H5vIBzHHEI
8uGgEJILmZbitIMfvYbWKncHZ/15CSf+uKt4kBDTSBLGeREXUpmkmYBRNtMxkHrBqg2w9KXCHxOTjFkU
g08jruBDBKCOvU3EtMVe57PPsr9j4FKiDtiihugQmOe1Jf83hs2RiWz+UrmSaVYcQkT0GpaRzb+NTFuW
PUAu01zaw38Ao/D6Ej70wa4AAAAASUVORK5CYII=
""")

def get_ISS():
    resp = http.get(ISS_URL)

    if resp.status_code != 200:
        return "API Error"

    data = resp.json()

    timestamp = time.from_timestamp(int(data["timestamp"])).format("15:04:03")
    lat = data["iss_position"]["latitude"]
    lon = data["iss_position"]["longitude"]

    return timestamp, lat, lon

def main():
    timestamp, lat, lon = get_ISS()

    return render.Root(
        child = render.Box(
            color = "#0b0e28",
            child = render.Row(
                children = [
                    render.Box(
                        width = 22,
                        child = render.Image(width = 20, height = 20, src = ISS_LOGO),
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(lat)),
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(lon)),
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(timestamp)),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
