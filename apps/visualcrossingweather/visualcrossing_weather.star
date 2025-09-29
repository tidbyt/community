"""
Applet: Visualcrossing Weather
Summary: Visualcrossing weather
Description: Display current temperature, humidity, and conditions for a user-specified location based on visualcrossing data.
Author: ryan-doucette
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# fetches weather from VisualCrossingWebServices
def fetch_weather(location):
    # Encode location for use in URL
    loc_encoded = location.replace(" ", "%20")
    url = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" + loc_encoded + "?unitGroup=us&key=5EX8LEP339SHUTGD5FCDZ2FT8&contentType=json"
    resp = http.get(url = url, ttl_seconds = 900)  # cache response for 15 minutes
    if resp.status_code != 200:
        return None
    return json.decode(resp.body())

def main(config):
    location_query = config.str("location_query", "1 Beacon St, Boston, MA 02108")
    display_name = config.str("display_name", "Boston, MA")

    weather = fetch_weather(location_query)
    if weather == None:
        return render.Root(
            child = render.Row(
                cross_align = "center",
                main_align = "center",
                expanded = True,
                children = [
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Text("Weather", color = "#FFA08A"),
                            render.Text("load", color = "#FFA08A"),
                            render.Text("error", color = "#FFA08A"),
                        ],
                    ),
                ],
            ),
        )

    current = weather["currentConditions"]
    temp_f = current["temp"]
    temp_c = (temp_f - 32) * 5 / 9
    humidity = current["humidity"]
    conditions = current["conditions"]

    return render.Root(
        child = render.Box(
            child = render.Column(
                cross_align = "center",
                main_align = "space_evenly",
                expanded = True,
                children = [
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(display_name, font = "tb-8"),
                    ),
                    render.Row(
                        main_align = "space_around",
                        expanded = True,
                        children = [
                            render.Text(str(int(temp_f)) + "°F", color = "#FFA08A"),
                            render.Text(str(int(temp_c)) + "°C", color = "#A3D4F7"),
                            render.Text(str(int(humidity)) + "%", color = "#A9EBC3"),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(conditions),
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
                id = "location_query",
                name = "Location Address",
                desc = "Enter full address (e.g., 1 Beacon St, Boston, MA 02108)",
                icon = "mapPin",
            ),
            schema.Text(
                id = "display_name",
                name = "Display Name",
                desc = "Label shown in widget (e.g., Boston, MA)",
                icon = "iCursor",
            ),
        ],
    )
