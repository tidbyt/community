"""
Applet: Namnsdag
Summary: Show the Swedish name day
Description: Display todays name day in Sweden.
Author: sebastianekstrom
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

CACHE_TTL_SECONDS = 10 * 60
API_BASE_URL = "https://sholiday.faboul.se/dagar/v2.1"

Colors = {
    "error": "#E81E1E",
    "background": "#001122",
    "yellow": "#FFCD00",
    "white": "#FFFFFF",
    "lightBlue": "#1E9EE8",
}

Translations = {
    "months": {
        "January": "jan",
        "February": "feb",
        "March": "mar",
        "April": "apr",
        "May": "maj",
        "June": "jun",
        "July": "jul",
        "August": "aug",
        "September": "sep",
        "October": "okt",
        "November": "nov",
        "December": "dec",
    },
    "weekdays": {
        "Monday": "Måndag",
        "Tuesday": "Tisdag",
        "Wednesday": "Onsdag",
        "Thursday": "Torsdag",
        "Friday": "Fredag",
        "Saturday": "Lördag",
        "Sunday": "Söndag",
    },
}

def render_display(subtitle, subtitle_color, content):
    return render.Root(
        child = render.Box(
            color = Colors["background"],
            child = render.Padding(
                pad = (2, 2, 2, 2),
                child = render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Text("Namnsdag", font = "CG-pixel-4x5-mono", color = Colors["yellow"]),
                            ],
                        ),
                        render.Box(width = 1, height = 2),
                        render.Text(subtitle, font = "tom-thumb", color = subtitle_color),
                        render.Box(width = 1, height = 1),
                        render.Box(width = 56, height = 1, color = Colors["yellow"]),
                        render.Box(width = 1, height = 2),
                        render.Marquee(
                            width = 56,
                            child = content,
                        ),
                    ],
                ),
            ),
        ),
    )

def render_error(error_message):
    return render_display(
        "Error",
        Colors["error"],
        render.Text(error_message, font = "CG-pixel-4x5-mono", color = Colors["white"]),
    )

def main():
    now = time.now().in_location("Europe/Stockholm")
    date_str = now.format("2006/01/02")
    url = "{}/{}".format(API_BASE_URL, date_str)

    cache_key = "namnsdag_{}".format(date_str)
    cached_data = cache.get(cache_key)

    if cached_data != None:
        data = json.decode(cached_data)
    else:
        response = http.get(url)
        if response.status_code != 200:
            return render_error("Could not fetch data")

        data = json.decode(response.body())
        cache.set(cache_key, response.body(), ttl_seconds = CACHE_TTL_SECONDS)

    if not data.get("dagar") or len(data["dagar"]) == 0:
        return render_error("No data available")

    day_info = data["dagar"][0]
    name_days = day_info.get("namnsdag", [])

    if not name_days:
        return render_error("No name day today")

    if len(name_days) == 1:
        names_text = name_days[0]
    elif len(name_days) == 2:
        names_text = "{} & {}".format(name_days[0], name_days[1])
    else:
        # Join all names with commas and "&" for the last one
        names_text = ", ".join(name_days[:-1]) + " & " + name_days[-1]

    # Get day of week and month in Swedish
    weekday_name = now.format("Monday")
    weekday = Translations["weekdays"].get(weekday_name, "Okänd")
    month_name = now.format("January")
    month_abbr = Translations["months"].get(month_name, "")

    date_display = "{} {} {}".format(weekday, now.format("2"), month_abbr)

    return render_display(
        date_display,
        Colors["lightBlue"],
        render.Text(names_text, font = "CG-pixel-4x5-mono", color = Colors["white"]),
    )
