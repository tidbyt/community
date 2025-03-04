"""
Applet: Shipping Forecast
Summary: Bespoke shipping forecasts
Description: Provides the weather for a location in a nice, pleasant, calming, shipping forecast style. All the vibes without the shortwave static. Displays wind, conditions, and visability.
Author: lumberbarons
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

LH1_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAgCAYAAAAi7kmXAAAAAXNSR0IArs4c6QAA
AURJREFUOI3FVDFKxEAUfRPGym5bG9lKBNnOdlgic4EFJ+gB7PYMOYPdlhaRRPAC
i7KktVtstBFPsBcw+C2SmZ1ks8lkEH3w4Sf/PebP/y8BPMEoCcvk+tm8VEqRTcqy
jOnc8CkJCQADgMvbVwTHUwKANE0BAFEUAQC+P1fsYX5m9IFOANDp0SFskZ1XNaoC
ASzEs/G2xfuLMtpqTeEQ1ITzu3czBFw9ldFWgzWc+PEDbwfntXaaOPl6YfFsDAAE
SkIzYqUU7YNekeZze38u0HxzRyFEr8jmGGGe571Cm8ObxdVo1K6SsvZoRqyUopvl
svPEhZTGt79jgMEQQnTu0N6lnmwAuE1UQ3P//o4McFuFhl6Jf6sTvmOeXkw4R7Au
isHCdVFsvTrdbJxEi+qv5+8cF8e0Ocj7RA50fIP7IOU/WM5b+AMpMdn34i/QuwAA
AABJRU5ErkJggg==
""")

LH2_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAgCAYAAAAi7kmXAAAAAXNSR0IArs4c6QAA
AVZJREFUOI3FVDFqw0AQnBNK5c6tm6AqGIK7tMIo6AOCnIgekE5v0BvSuXShIAXy
ARNh1KYzaeIm5AX+QEQ2hXTrs2NL8gWSgYM7aYbdmx0JMISg1Ks3UcEPpZSkk/I8
F2rPfP1wc/8K63xKAJBlGQAgDEMAwNfHUjzGl1zEotQjACSiAuPRALpI349HA9UV
UeqRpbVASeBsW3y4rleDJHCoKQIAYOGpYKGIChHP12wCbp/r1SCer4WICn7P5iRP
73g7u9pxcx8Xny8iCZz6rpR67KqUko5BjUjxbX1+faD4fEfXdTtFOoeFZVl2CnWO
vf9yORweVvn+zpHtlVLS3WLRWnHm+5zb3wfACK7rts5Qn6Vy1gL6OaqguH9/RwH0
G4WCGol5qxP7R3g6MbFtWKuqOlm4qqptVqebTS/RrPnrmSenT2IOJci4og20fIPH
4Pv/EDlj4Tc0MOYrtz5hhQAAAABJRU5ErkJggg==
""")

LH3_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAgCAYAAAAi7kmXAAAAAXNSR0IArs4c6QAA
AUpJREFUOI3FVDFOwzAUfYnMBTp3oJlYUDdWq0rlAzQSP4IDMJUrNGfo1gMEJUgs
jBWoyspWsTAhTtALEGGGxMZp0iQYib4ldvJe/s/7LwYs4cjYLxbXz/omEUmTlKap
o9aab24ul69wTycSAJIkAQCEYQgA+PrYOPe357UiAIDFbAQikvsgIrmYjSpcJmO/
0lb4WC7upsX16gkAEAWejAJP89xOF/pgLoYHW52LYYWrzYke3vF2ciEb31ji7PPF
iQKvMEfGvna1qZpZVRWRsQ9Ws7YDiq/N4Zx3ikyOFmZZ1ik0OWz/4WYwaFYJUdnq
DBKRvFmvWyuuhNC5tQ7A35LDOW+doTlL5awL9HNUQXH//xsdoN8oFNRI7Fsds1p4
OjFmDO42z38t3Ob5T1Ynu10v0ao89eyT0ycxTQmyrsiAln/wEIQ4QuSshd9T5Pgu
NiIMJwAAAABJRU5ErkJggg==
""")

LH4_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAgCAYAAAAi7kmXAAAAAXNSR0IArs4c6QAA
AVBJREFUOI3FVDFOw0AQnLOOBxBRUpBUNIgubRQZ3QMSibXIA6jIF+I30KWkMLKR
+EBEFLmlQzTQIF6QDxCxFM5dzolztq4II1m6vZvx3s6uDXhCcBIWi9HcbBIR26Qs
y4ReG74dXN+/IzjrMwCkaQoAiKIIAPD7vRBP44udJACAyaANIuJtEBFPBu0SN7CD
eNjZXPHxqnisM05C5iRkAJDrq5Zq2gcxmptapb1xp06B45PiJTcvJdH44VPYsTEn
fv7Cx1HXmfn851XEw05hDiehcbXKGNsgnYSTEHLH2vo6AViu9nq9WpHNMcI8z2uF
NkduHy5arWqVUqXQWExEfDubOTNOlTJzGziZDngLARRuuXpo91I7GwDNHNXQ3MPX
KIBmrdDQLTnsVS+l9BO+rVabWe0vl41E0/Vfz39ymkxM1QR5Z5SA4xvcB6X+YeS8
hX/UpuxXiqct0gAAAABJRU5ErkJggg==
""")

LH5_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAgCAYAAAAi7kmXAAAAAXNSR0IArs4c6QAA
AStJREFUOI3FlDFOwzAUhj9X5QBUHIB2YmFltaogH6CVcAQHYOsVmjOwdewQlCBx
gQpUZWVlgQVxgl4ACTMEu06TlpCi8EuW/Oz/5b33v+dAQwgTB/nm6tEdaq2NT0rT
VNi94/vGxc0zneOhAUiSBIAwDAH4fF+Ku8lpKQgA01EfrbXZhNbaTEf9ArfjG9F4
sE7x9jxfVXebjr9B1zcm81fB4VH+5csHSncenDjR/RsvB2eFdDZx8vEkovEgF8fE
gVO1ShhfIBvExAHdkrQ/wPIbi/M3qgIse71qplIF00mstTbXi8XOKDOl3Ny2XyMA
UsqdPfR7KaVcR8yyrHYQy22/RgH1WmFhW9J+qvvP6nC1quUw+/7rNZ+cOhNTNUH7
1bj1DW6DUv/QjsaOX8IH2YnmwUtoAAAAAElFTkSuQmCC
""")

API_KEY = "AV6+xWcEtpMtBn6PPh4L8DWUydu4O7uc1Zdb8ANbGmfkp0ASxOPrnmBHYs+cIj4y1JsZSPi5ASKPr69erzFRGqJCp01y7Qg9H9R1z4l4pK7xiFyVgnR7e++p5OGCXSCV3M8FPEBkXlAJQekEfVuhIYFGKCguD3F5YFV73KCGoGfEinMd1+Q="

FORECAST_URL = "https://weather.lmbrn.ca/v1/forecast"

DEFAULT_LAT = "57.5979648"
DEFAULT_LON = "-13.6939501"

DEFAULT_FORECAST = "North 0. Clear. Something is not right."

def is_proper_float(s):
    s = s.strip()
    if not s:
        return False
    if s.startswith("-"):
        s = s[1:]
    parts = s.split(".")
    if len(parts) not in [1, 2]:
        return False
    for part in parts:
        if not part.isdigit():
            return False
    return True

def round_to_two_decimals(number):
    return int(number * 100 + 0.5) / 100.0

def parse_location(location):
    splitLocation = location.split(",")

    if len(splitLocation) != 2:
        print("invalid location: " + location)
        return DEFAULT_LAT, DEFAULT_LON

    lat = splitLocation[0].strip()
    lon = splitLocation[1].strip()

    if not is_proper_float(lat):
        print("invalid lat: " + lat)
        return DEFAULT_LAT, DEFAULT_LON
    elif not is_proper_float(lon):
        print("invalid lon: " + lon)
        return DEFAULT_LAT, DEFAULT_LON

    print("latitude: " + lat + " longitude: " + lon)

    # reduce to 2 decimal places
    roundedLat = round_to_two_decimals(float(lat))
    roundedLon = round_to_two_decimals(float(lon))

    return roundedLat, roundedLon

def main(config):
    location = config.get("location", "")
    lat, lon = parse_location(location)

    api_key = secret.decrypt(API_KEY) or config.get("dev_api_key")

    if api_key != None:
        url = FORECAST_URL + "?lat=" + str(lat) + "&lon=" + str(lon)
        headers = {"authorization": "Bearer " + api_key}
        rep = http.get(url, headers = headers, ttl_seconds = 1200)
        if rep.status_code == 200:
            print("got forecast")
            forecast = rep.json()["forecast"]
        else:
            print("request failed with status %d, using default forecast", rep.status_code)
            forecast = DEFAULT_FORECAST
    else:
        print("no api key, using default forecast")
        forecast = DEFAULT_FORECAST

    return render.Root(
        delay = 140,
        child = render.Box(
            render.Row(
                main_align = "space_between",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Animation(
                        children = [
                            render.Image(src = LH1_ICON),
                            render.Image(src = LH1_ICON),
                            render.Image(src = LH2_ICON),
                            render.Image(src = LH2_ICON),
                            render.Image(src = LH3_ICON),
                            render.Image(src = LH3_ICON),
                            render.Image(src = LH4_ICON),
                            render.Image(src = LH4_ICON),
                            render.Image(src = LH5_ICON),
                            render.Image(src = LH5_ICON),
                            render.Image(src = LH4_ICON),
                            render.Image(src = LH4_ICON),
                            render.Image(src = LH3_ICON),
                            render.Image(src = LH3_ICON),
                            render.Image(src = LH2_ICON),
                            render.Image(src = LH2_ICON),
                        ],
                    ),
                    render.Marquee(
                        child = render.WrappedText(
                            content = forecast,
                            color = "#fff",
                            width = 49,
                            font = "tom-thumb",
                        ),
                        height = 32,
                        scroll_direction = "vertical",
                        align = "center",
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "location",
                name = "Location",
                desc = "The forecast location's coordinates in decimal degrees (latitude, longitude). For example: 57.59, -13.69",
                icon = "compass",
            ),
        ],
    )
