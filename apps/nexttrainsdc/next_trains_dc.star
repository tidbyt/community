"""
Applet: Next Trains DC
Summary: Shows next trains time
Description: Shows next trains times.
Author: Nehan Sikder
"""

load("http.star", "http")
load("render.star", "render")
load("secret.star", "secret")

WMATA_URL = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/K04"
CACHE_TTL = 240

def main(config):
    API_KEY = secret.decrypt("AV6+xWcEILMM+uHVPvdOv5xUbEvXNmNuMBk274sRjlrM/72nYAuT/2hNS8bwDQ3gm/P/Yo1N1cM2wmtOuX62jDdBTouMKmIlliI/zTP5uUzpWtRifxqD9cQlDkdXg2/pwyrZdwLhFu5vOWfjf5aZe0fsPIj32Zio4Udlme8zYgLydsReI70=") or config.get("dev_api_key")
    rep = http.get(WMATA_URL, headers = {"api_key": API_KEY}, ttl_seconds = CACHE_TTL)
    if rep.status_code != 200:
        fail("WMATA request failed with status %d", rep.status_code)
    ashburn_arrival_minutes = []
    dc_arrival_minutes = []
    trains = rep.json()["Trains"]
    for train in trains:
        station = train["DestinationName"]
        arrival_minutes = train["Min"]
        if station == "Ashburn":
            ashburn_arrival_minutes.append(arrival_minutes)
        elif station == "Downtown Largo":
            dc_arrival_minutes.append(arrival_minutes)
        elif station == "N Carrollton":
            dc_arrival_minutes.append(arrival_minutes)

    ashburn_str = " ".join(ashburn_arrival_minutes) + " min"
    dc_str = " ".join(dc_arrival_minutes) + " min"

    return render.Root(
        child = render.Column(
            children = [
                render.Box(width = 64, height = 1, color = "#000000"),
                render.Box(width = 64, height = 7, child = render.Marquee(
                    width = 64,
                    child = render.Text(content = "        Ashburn        ", color = "#FFFFFF", font = "Dina_r400-6"),
                    offset_start = 64,
                    offset_end = 64,
                )),
                render.Box(width = 64, height = 7, child = render.Text(content = ashburn_str, color = "#FFA500", font = "Dina_r400-6")),
                render.Box(width = 64, height = 1, color = "#FFA500"),
                render.Box(width = 64, height = 1, color = "#FFFFFF"),
                render.Box(width = 64, height = 1, color = "#000000"),
                render.Box(width = 64, height = 7, child = render.Marquee(
                    width = 64,
                    child = render.Text(content = "          DC           ", color = "#FFA500", font = "Dina_r400-6"),
                    offset_start = 64,
                    offset_end = 64,
                )),
                render.Box(width = 64, height = 7, child = render.Text(content = dc_str, color = "#FFFFFF", font = "Dina_r400-6")),
            ],
        ),
    )
