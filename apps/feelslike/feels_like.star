"""
Applet: Feels Like
Summary: Shows "feels like" weather
Description: Displays the "feels like" temperature for the set location.
Author: skalum
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_LOCATION = """
{
	"lat": "37.7639316",
	"lng": "-122.4030647",
	"description": "451 Kansas St, San Francisco, CA 94107, USA",
	"locality": "San Francisco",
	"place_id": "ChIJSbhWnuF_j4ARbk1kioTNmEE",
	"timezone": "America/Los_Angeles"
}
"""

DEFAULT_API_KEY = "noKey"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apiKey",
                name = "API key",
                desc = "OpenWeather API key",
                icon = "key",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather",
                icon = "locationDot",
            ),
        ],
    )

def main(config):
    apiKey = config.get("apiKey", DEFAULT_API_KEY)

    location = json.decode(DEFAULT_LOCATION)
    lat, lng = float(location["lat"]), float(location["lng"])

    url = "https://api.openweathermap.org/data/3.0/onecall?lat={}&lon={}&appid={}&units=imperial".format(lat, lng, apiKey)
    weather = http.get(url).json()

    currentWeather = weather["current"]
    currentWeatherIcon = currentWeather["weather"][0]["icon"]

    logo = http.get("https://openweathermap.org/img/wn/%s@2x.png" % (currentWeatherIcon)).body()

    return render.Root(
        child = render.Row(
            children = [
                render.Padding(
                    child = render.Image(src = logo, width = 32, height = 32),
                    pad = (-3, -5, 0, 0),
                ),
                render.Column(
                    children = [
                        render.Marquee(
                            child = render.Text(
                                currentWeather["weather"][0]["description"],
                            ),
                            width = int(len(currentWeather["weather"][0]["description"]) * 4),
                        ),
                        render.Text(
                            "{}°".format(int(currentWeather["temp"])),
                        ),
                        render.Text(
                            "({}°)".format(int(currentWeather["feels_like"])),
                        ),
                    ],
                ),
            ],
        ),
    )
