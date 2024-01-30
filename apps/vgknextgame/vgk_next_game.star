"""
Applet: VGK Next Game
Summary: Shows next VGK Game
Description: Shows the date of the next Vegas Golden Knights game.
Author: theimpossibleleap
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("time.star", "time")

timestamp = time.now().format("2006-01-02")

vgkNextGameWeek = "https://api-web.nhle.com/v1/club-schedule/VGK/week/" + timestamp

def main():

    response = http.get(vgkNextGameWeek)

    if response.status_code != 200:
        fail("Server request failed with status %d", response.status_code)

    if len(response.json()["games"]) == 0:
        nextStartDate = "> 1 week"
    else:
        nextStartDate = response.json()["games"][0]["gameDate"]

    img = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAAcCAYAAABh2p9gAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAAHAAAAACCrbs8AAABqklEQVRIDZWVu07GMAyFU8TIA/AQDEg8AJeBBXZuEjPsMLfMMANiB7FzkeApGBkQMwMbE4KfkFNxIsdO2hCpqmMff46TqHWucnjvXyql47Lbs22/sLgSmN6PqRuIS6K1vUt3d77Th9vrN3e0OVuSRv80rPX9q+igcX+xG2H0AYoBcC4nLM5NUSzfCPxMvqUrsQGGJjcMsGKbek4JaoDcs1x17eMWSH8C7LpOxqps3XoCbNu2CjIkSoBSmGtHxnHSuWtkgLwOFGuwBFErC/X3UDqwJxTCJhga2ozjRuhDNEAJZyLAS3Mz7uD40T2/vkeJhiFgWoZTnhzv5XIAnhyuIjw4DFDvWdM0EcAVw8FCMfhnGGC3Mf4BQC7a1cXhN0AuSLaNr07tMEAk6spou6Zd5GaBvB4Q5EapXWizQEJk2/SNvROgPNFSIk734emjD6MTuRUxJ6wEv4H4YM5H+mHDj/9LLicCQ9V5LWCy9mN+c7oVi1MXGF0E0tDJFOOtbeUL08KYfH2adoI0WRHmKP63gAJJuMPyKTYgwqARKXWmBv9rVUMlBHhI1sd+AVosEEWqHg24AAAAAElFTkSuQmCC")

    return render.Root(
        render.Box(
            child = render.Row(
                main_align="center",
                cross_align="center",
                children=[
                    render.Image(img),
                    render.Column(
                        children=[
                            render.Box(
                                child=render.Column(
                                    children=[
                                        render.Text(content=" Next Game:", font="tom-thumb", color="B4975A"),
                                        render.Text(content=" " + nextStartDate, font="tom-thumb")
                                    ]
                                )
                            ),
                        ]
                    )
                ]
            )
        )
    )