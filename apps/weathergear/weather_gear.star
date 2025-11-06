"""
Applet: Weather Gear
Summary: Weather outfit info
Description: What you need to wear for the weather today.
Author: @rubencodes
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

LOCATION = {
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York",
}

SHORTS_TEMPERATURE_THRESHOLD_F = "65"
LIGHT_JACKET_TEMPERATURE_THRESHOLD_F = "65"
JACKET_TEMPERATURE_THRESHOLD_F = "50"
COAT_TEMPERATURE_THRESHOLD_F = "35"
SUN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAAMCAYAAABm+U3GAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAADAAAAAA2cbx5AAABrElEQVQ4EY1SOywEYRD+5h65O4eIeDUoNBoajUQjuct5NWq9BiFRkSiuI0qVQohCpRIXrygEheYaKqJBQeQEyd567o7Zvfsv/+1d4jaZnfkeM/vv7AIVXmwM3HF24KxCOwJeI3N/GJ+BJoQjGaJd06vrmF+GalH1U4fw6yNR+kfXfDpwazMUg+W/Q/Z7tETzEiFrIudt7vRKpYMtugVoCYQONhJz3gYHOyd1NULI9eLruZyvLCc73ZJgJUq9IcOWHcwf8TZHY2NwUellMxvDLdJ0KeYZZWAz0Sp8l8J6Zu4JOhobsWbFS++RxKbCxR+P0egOi/IN0f6DmJwAZwcXwDzuNhGmiQ53pL5yNXd4qAmwgq6ev5EOcjsleT1/N1XvXQlekx3GxVMvUZP3ZiRnQTxF0aNUbh08B7/VTpHj+7zH87v5/CewrXk53ZOcchtsj4gxosz53CC5AUzrMnRW8gHIfocZfNN9RSdWAnPSB/PiVB7Qp7iymWkS1b2rREnbq5MsfKtAEq6lToORKnD/F++wfzvgC6xo1kPn441pxLnUaQ1XVgYpCkufw5k/A5Sui16kTE4AAAAASUVORK5CYII=
""")
RAIN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAMCAYAAABvEu28AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAADAAAAABFeZu2AAABv0lEQVQoFY1SSyhEYRQ+/713NCnlkYWESRaSlbBRpJS8jWJj4y0rGxuh/oXH7IbZkDRjYWfBDElJc5FSNhY2kszILMhjQYi59/jPPLi3Ib7F/c/5vu+c7jkdBgKD3otSnUnHGmKhuyX/jDhCa71nmAHMRjMYXdvqdsRi4BwlqFIlXl0dJk6izzviDQK4kjT9kfLWOo/LXu/RDU2IniHO3uAeoeS6JOAMPdk+KCYIrxn2Bs8KIHSaWVOGDJgjfbDSLzGpfLHZNkWqErdwzqWTo7xc0DEFWEL/uI1e0QdS7+b3zte3u3fiwldFe+1SeliW7+PCf97Hl6BFVXlkR19/BJqmoSxfJTRAMQmBMbFGMzIzi7Bv43JZKFlsaDOYZn2R3pwdOa9mWzTrKS1GMYrLfXw6/JPe7wscAGCuEtb1hyer7hKmH43G4i7/pVV5xkblQ99faCu4NWoKMmyXAc6N5G+x9VnJ0DC8ihZLjfDskk/UT4i5kxNrxE4GfIGxXm+wgkQaraeseC5iFBqtgvv937uNdUgguKrKIbBNygzGhecw5os+YuHzAJGjNfEiiVy2kaSTz04JWBab8qaN/F/xJztVmdWA68rUAAAAAElFTkSuQmCC
""")
SNOW_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAMCAYAAABiDJ37AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAADAAAAADiTSy+AAAB4UlEQVQoFY1TPUhbYRQ99yWmaXWwliDUoVBwieJWkIK0QwWJcS20pYijTrrpLugidpA4O+jg2kTETZDSoYVSk0LpZEoHhQqK4A+Y6zkvvvAiDrnwve/ec8+93/nuew9owYoV/6nVAhXJOGnrjz+4vkL3OXD8ts/O4rm7/mbFOx4CXYkUDnO9dhnlg8jRzmYvzHHwqIaPcfw+XxxxVRPPNykMDH9rjkULkClVfNZSWI6frkLdwq8w40DKyVVNU8PPZV8wYNYNz0azdsDkHOdVIHkydYJVxo3rqLDtBOnLNBZgWB3rtylhPPw9+etw5AM+fvC0DathuLTvwyJcJzDPeICFOzxwRZhMvjDlxBGmZqihJ+wR4B/F1a1Ydqmr5vttqIFV/AsPfMpYS1alsqN8n72shwDrKA4bVPtBWGOGnMUEM8953SKvX6CKN2EzQyf3ttsGj+knS2V/R24PArymunxAZdEBDYUCtn75IF/KNosuGHZwtQungnHtJK9pp/0Pn4Yk1XaG/u2j6bPJZe3rtyy62OE782p2ylVlXF/y69gT3mIp5BKIm3HQ6xFghgyLwxcjjMoWORu99fAvoZqB6KuIajS/yGf9b9NQI+DuTsIusW0yppVj/InbCONXiu+xvRu1csHd652LSwAAAABJRU5ErkJggg==
""")
FULL_MOON_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAANCAYAAACdKY9CAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADQAAAAAubNPtAAABGUlEQVQoFX1QO07DUBDcfdhxoKCBIFHQpMgNAu4QB6CkgJILROIkNCmQKGkipU1JQ2OHIDgAQnwKCkoosB+2h12b2CEET/F2ZnZWu3pMMwDGa6nFXWmBHp2mv1tqIc5UJPH4KIvRIqatqUeGvMSGx0jNs7u8fak+65NEwT4xXwhdVf0XmMCYnuvuBCZvMp9J/SesCe5yhhNlxtrrrtSGilowrSOatDmJwxcJVnfXTTH1i5PqQnM9A6KBeJ9z/iL5REBQ/FIcvkpic1Fqxhs6nn+QnyRbzqVRs4UfiDHS4XyDki8bnjJoQ+ih6h+8Sx2Kf7vU9PvqlQMqgKtWahtvyhWy+d71/E6hivfXQB7CzUoV+MiY96JKE30DwMNTXB9JNBwAAAAASUVORK5CYII=
""")
FIRST_QUARTER_MOON_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAABLUlEQVQoFWNgQALbN89wfvt6358L51Z/S05OfgzEC5CkwUxmmMDhQ4sW8fBxBSgqiCl8+fKD9eixm3xAOVYjIyMGExMThnPnzj0DqQVrOLh/0RQzU5UUGWkheZDg+/dfGYAaQEwxIPb+//+/uLGx8TWgppdMIFEDfflMFhYwE8TFBvyAmjxBEkx7ds2tZWFhZsSmCk1MJyUlRZzJ0FCxnp2dhRgNMf/+/TPC6w40G8BcpuvXnq799esPNjl0sR1AgZtMNvax4b9///2HLouFf2DevHn3wE66cPHh9D9/8OrZxMjIuB1kCAuIsHeMywFGHB8bG6uCsaGiLUgMCq4C6WlMTEynZ8+efQkkBtYAYtjaxcWBksbHT992fvv+6xdQ6C0Qn5k7d+40kDwMAAAAFGl/vkPOJgAAAABJRU5ErkJggg==
""")
LAST_QUARTER_MOON_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADAAAAAATDPpdAAABKklEQVQoFWNkQALJyckqQO5+fj4u5uqqQLGnT9490DMMAYnBAQuMlZSUlPr//39ZRkZGGUZGBgagJoafIr9ljhxatOLr9z/b3d2TFoLUMoEIoMlRQIWTgbgWxIcBMTF+dgtztXB5WeGObdtmh4DEwRqA9EQgZgcJgMD//xAaRqooi0sICXAlgfhMQKd4Amm4YpAgyEnogJubQ2PLuuk6TEBnzAJK8iIrQLcBJKepIa3IwcMWCHMSsnq8bJANHUAV35BVYXPSvfuv3vz68fcQ05w5c6aia8DmpHfvPp/28ks7CHNSPlDTT5gt6DbcufvyxbsP3+aB5JlBxPnz5y8bGhq+BDIvAJ1oz8HByuDqosfw6tXHn5evPFr7+u3XGZ6eKctBalECkJikAQDcW1+0vM3o9wAAAABJRU5ErkJggg==
""")
NEW_MOON_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAANCAYAAACdKY9CAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAADKADAAQAAAABAAAADQAAAAAubNPtAAABB0lEQVQoFWNkQAJxcXHCrKys55GE7s+dO9ceic/ACOMkJydHAdmiQDwBJvb///9XjIyMlUD+Q6DGvSBxsAagYl8gewkQ84EE0QFQ42mgWP68efOOM0ElZwJprIpB8kBbTIFUEZidmppq+u/fv+1AjjBIAA84ALQpmdnQ0PAEUJEEHoUwKQUggwXmJJggQRqkYSXQjd8JqmRgeABUcxwWSs+AHEl8moDuXwMMpVCwk4CcOQRsuQs0bCvIQGYQcf78+f1Az4sCNd4HatQFiUHBJyC9FCi2Hhhxs0Fi8JgGcRITE0WZmJhegdhQcBuoUA3GAdEooTR//vzXzMzM3DD89+9fPWTFIDYADVhNeszTqIEAAAAASUVORK5CYII=
""")

def main(config):
    open_weather_api_key = config.str("open_weather_api_key", "")
    location = json.decode(config.get("location")) if config.get("location") != None else LOCATION
    thresholds = {
        "shorts": int(config.str("shorts_temp_threshold", SHORTS_TEMPERATURE_THRESHOLD_F)),
        "light_jacket": int(config.str("light_jacket_temp_threshold", LIGHT_JACKET_TEMPERATURE_THRESHOLD_F)),
        "jacket": int(config.str("jacket_temp_threshold", JACKET_TEMPERATURE_THRESHOLD_F)),
        "coat": int(config.str("coat_temp_threshold", COAT_TEMPERATURE_THRESHOLD_F)),
    }

    lat = location["lat"]
    lon = location["lng"]
    weather_url = weather_endpoint(lat, lon, open_weather_api_key)
    weather_response = http.get(weather_url)
    weather_data = weather_response.json()
    if "current" not in weather_data:
        return Error("Could not get weather data for {}.".format(location["locality"]))

    return App(
        Advice(weather_data, thresholds),
        Summary(location, weather_data),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "The location to get weather information for.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "shorts_temp_threshold",
                name = "Shorts Temperature Threshold (°F)",
                desc = "The temperature above which shorts are needed.",
                icon = "thermometer",
                default = SHORTS_TEMPERATURE_THRESHOLD_F,
            ),
            schema.Text(
                id = "light_jacket_temp_threshold",
                name = "Light Jacket Temperature Threshold (°F)",
                desc = "The temperature above which no jacket is needed.",
                icon = "thermometer",
                default = LIGHT_JACKET_TEMPERATURE_THRESHOLD_F,
            ),
            schema.Text(
                id = "jacket_temp_threshold",
                name = "Jacket Temperature Threshold (°F)",
                desc = "The temperature above which a light jacket is needed.",
                icon = "thermometer",
                default = JACKET_TEMPERATURE_THRESHOLD_F,
            ),
            schema.Text(
                id = "coat_temp_threshold",
                name = "Coat Temperature Threshold (°F)",
                desc = "The temperature above which a coat is needed.",
                icon = "thermometer",
                default = COAT_TEMPERATURE_THRESHOLD_F,
            ),
            schema.Text(
                id = "open_weather_api_key",
                name = "OpenWeather API Key",
                desc = "API key for OpenWeather (get one at https://openweathermap.org/api).",
                icon = "key",
                default = "",
            ),
        ],
    )

def weather_endpoint(lat, lon, api_key, exclude = "minutely,hourly", units = "imperial"):
    return "https://api.openweathermap.org/data/3.0/onecall?lat={}&lon={}&exclude={}&units={}&appid={}".format(lat, lon, exclude, units, api_key)

def get_random_easter_egg():
    options = [
        "Too warm for a jacket, too cool for shorts. What's a girl to do?",
        "Perfect weather for a picnic!",
        "Enjoy it while it lasts!",
        "Wear that one outfit you can't ever wear because of the weather.",
    ]
    return options[random.number(0, 100) % len(options)]

def Summary(location, weather_data):
    now = weather_data["current"]
    today = weather_data["daily"][0]
    rounded_feels_like = int(math.round(now["feels_like"]))
    summary = "Feels like {}°F".format(rounded_feels_like)
    image = SUN_ICON

    # If it's night time, show moon icon
    timezone = location["timezone"]
    current_time = time.now().in_location(timezone)
    sunrise = time.from_timestamp(int(today["sunrise"]))
    sunset = time.from_timestamp(int(today["sunset"]))
    if current_time < sunrise or current_time > sunset:
        if today["moon_phase"] == 0 or today["moon_phase"] == 1:
            image = NEW_MOON_ICON
        elif today["moon_phase"] <= 0.25:
            image = FIRST_QUARTER_MOON_ICON
        elif today["moon_phase"] == 0.5:
            image = FULL_MOON_ICON
        else:
            image = LAST_QUARTER_MOON_ICON

    # Add precipitation chance if any
    precipitation_chance = today["pop"] if "pop" in today else 0
    precipitation_percent = int(math.round(precipitation_chance) * 100)
    if precipitation_percent > 0:
        if "snow" in today and "rain" not in today:
            image = SNOW_ICON
            summary += ". {}% chance of snow".format(precipitation_percent)
        elif "snow" in today:
            image = SNOW_ICON
            summary += ". {}% chance of mixed precipitation".format(precipitation_percent)
        else:
            image = RAIN_ICON
            summary += ". {}% chance of rain".format(precipitation_percent)

    return render.Marquee(
        child = render.Row(
            children = [
                render.WrappedText(
                    content = summary,
                    color = "#fff",
                ),
                render.Image(
                    src = image,
                    height = 8,
                ),
            ],
        ),
        scroll_direction = "horizontal",
        height = 12,
        width = 64,
        delay = 0,
    )

def Advice(weather_data, thresholds):
    now = weather_data["current"]
    today = weather_data["daily"][0]
    daily_max = today["temp"]["max"]
    daily_min = today["temp"]["min"]
    daily_average = (daily_max + daily_min) / 2
    feels_like = now["feels_like"]
    min_temp = min(daily_average, feels_like)
    rounded_min_temp = int(math.round(min_temp))
    max_temp = max(daily_average, feels_like)
    rounded_max_temp = int(math.round(max_temp))

    precipitation_chance = today["pop"] if "pop" in today else 0
    if precipitation_chance >= 0.5:
        if "snow" in today and "rain" not in today:
            precipitation_advice = "It's a snow day!"
        elif "rain" in today and "snow" not in today:
            precipitation_advice = "You need an umbrella."
        else:
            precipitation_advice = "It's gross out there."
    elif precipitation_chance >= 0.1:
        if "snow" in today and "rain" not in today:
            precipitation_advice = "Some snow is possible."
        elif "rain" in today and "snow" not in today:
            precipitation_advice = "You might need an umbrella."
        else:
            precipitation_advice = "It might be gross out there."
    else:
        precipitation_advice = ""

    # Warm weather.
    if rounded_min_temp > thresholds["light_jacket"]:
        # Prioritize rain advice.
        if precipitation_advice:
            advice = precipitation_advice
            color = "#babaff"

            # Then shorts advice.
        elif rounded_max_temp > thresholds["shorts"]:
            advice = "It's shorts season!"
            color = "#fffa8c"

            # Extra hot day bonus advice.
            if rounded_max_temp > 85:
                advice += " Stay hydrated out there!"
                color = "#ff3c2eff"

            # No jacket needed, no shorts needed, just vibes.
        else:
            advice = get_random_easter_egg()
            color = "#fff"

        # Cool weather.
    elif rounded_min_temp > thresholds["jacket"]:
        advice = "Bring a light jacket."
        color = "#babaff"
        if precipitation_advice:
            advice += " " + precipitation_advice

        # Cold weather.
    elif rounded_min_temp > thresholds["coat"]:
        advice = "You need a jacket."
        color = "#6868ff"
        if precipitation_advice:
            advice += " " + precipitation_advice

        # Very cold weather.
    else:
        advice = "Break out the winter coat!"
        color = "#00f"
        if precipitation_advice:
            advice += " " + precipitation_advice

    return render.Marquee(
        child = render.Padding(
            child = render.WrappedText(
                content = advice,
                color = color,
                align = "center",
            ),
            pad = (0, 4, 0, 4),
        ),
        scroll_direction = "vertical",
        height = 24,
        width = 64,
        delay = 50,
    )

def Error(message):
    return render.Root(
        child = render.Marquee(
            child = render.WrappedText(
                content = message,
                color = "#fa0",
            ),
            scroll_direction = "vertical",
            height = 36,
            delay = 50,
        ),
    )

def App(advice, summary):
    return render.Root(
        child = render.Column(
            children = [
                advice,
                render.Box(width = 64, height = 1, color = "#7e7e7e"),
                summary,
            ],
            cross_align = "center",
            main_align = "space_around",
            expanded = True,
        ),
        max_age = 60 * 60,  # 60 minutes
    )
