"""
Applet: Solea Tram
Summary: Mulhouse tram times
Description: Displays real-time tram departures for Solea network in Mulhouse, France. Shows next trams with line numbers, destinations and waiting times.
Author: Quentin Hattstadt
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# API URL
API_URL = "https://solea-tram-api.fly.dev"

# Couleurs officielles des lignes de tram Solea (depuis GTFS)
TRAM_COLORS = {
    "1": "#BE0013",  # Rouge - Ligne 1
    "2": "#FFD910",  # Jaune - Ligne 2
    "3": "#009234",  # Vert - Ligne 3
    "TT": "#B2C602",  # Vert clair - Tram-Train
}

# Couleur du texte selon la ligne
TEXT_COLORS = {
    "1": "#FFF",
    "2": "#000",
    "3": "#FFF",
    "TT": "#000",
}

# Toutes les stations de tram du réseau Solea
TRAM_STATIONS = [
    schema.Option(display = "Republique", value = "190967"),
    schema.Option(display = "Gare Centrale", value = "61967"),
    schema.Option(display = "Porte Jeune", value = "190958"),
    schema.Option(display = "Porte Haute", value = "190957"),
    schema.Option(display = "Cite Administrative", value = "190891"),
    schema.Option(display = "Coteaux", value = "190894"),
    schema.Option(display = "Nouveau Bassin", value = "190945"),
    schema.Option(display = "Musees", value = "190941"),
    schema.Option(display = "Musee de l'Auto", value = "190940"),
    schema.Option(display = "Universite", value = "190993"),
    schema.Option(display = "Illberg", value = "190919"),
    schema.Option(display = "Chataignier", value = "190887"),
    schema.Option(display = "Stade Bourtzwiller", value = "190982"),
    schema.Option(display = "Tour Nessel", value = "190988"),
    schema.Option(display = "Bel Air", value = "190871"),
    schema.Option(display = "Palais des Sports", value = "190949"),
    schema.Option(display = "Nations", value = "190942"),
    schema.Option(display = "Lefebvre", value = "190926"),
    schema.Option(display = "Daguerre", value = "190896"),
    schema.Option(display = "Grand Rex", value = "190914"),
    schema.Option(display = "Dornach Gare", value = "8745"),
    schema.Option(display = "Lutterbach Gare", value = "190854"),
    schema.Option(display = "Rattachement", value = "190965"),
    schema.Option(display = "Doller", value = "190897"),
    schema.Option(display = "Saint-Nazaire", value = "190973"),
    schema.Option(display = "Nordfeld", value = "192568"),
    schema.Option(display = "Tuilerie", value = "192586"),
    schema.Option(display = "Mairie (Lutterbach)", value = "192565"),
    schema.Option(display = "Thann St-Jacques", value = "190569"),
    schema.Option(display = "Thann Centre", value = "8789"),
    schema.Option(display = "Cernay", value = "190135"),
    schema.Option(display = "Vieux-Thann", value = "190571"),
    schema.Option(display = "Graffenwald", value = "192618"),
    schema.Option(display = "Zu Rhein", value = "191001"),
]

def get_departures(stop_id):
    """Recupere les prochains departs depuis l'API."""
    cache_key = "solea_departures_%s" % stop_id
    cached = cache.get(cache_key)

    if cached:
        return json.decode(cached)

    url = "%s/departures/%s?limit=4&tram_only=true" % (API_URL, stop_id)

    resp = http.get(url, ttl_seconds = 60)

    if resp.status_code != 200:
        return None

    data = resp.json()

    # Cache pour 60 secondes
    cache.set(cache_key, json.encode(data), ttl_seconds = 60)

    return data

def render_departure_row(dep):
    """Affiche une ligne de depart."""
    line = dep.get("line", "?")
    minutes = dep.get("minutes_until", 0)
    destination = dep.get("destination", "")

    # Couleurs de la ligne
    bg_color = TRAM_COLORS.get(line, "#666")
    txt_color = TEXT_COLORS.get(line, "#FFF")

    # Tronquer la destination
    if len(destination) > 10:
        destination = destination[:9] + "."

    # Formater le temps d'attente
    if minutes <= 0:
        time_str = "0'"
        time_color = "#0F0"
    elif minutes == 1:
        time_str = "1'"
        time_color = "#0F0"
    elif minutes <= 3:
        time_str = "%d'" % minutes
        time_color = "#FF0"
    else:
        time_str = "%d'" % minutes
        time_color = "#FFF"

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            # Badge de la ligne
            render.Box(
                width = 14,
                height = 8,
                color = bg_color,
                child = render.Row(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Text(
                            content = line,
                            font = "tb-8",
                            color = txt_color,
                        ),
                    ],
                ),
            ),
            render.Box(width = 1),
            # Destination
            render.Text(
                content = destination,
                font = "tom-thumb",
                color = "#CCC",
            ),
            # Temps d'attente
            render.Text(
                content = time_str,
                font = "tom-thumb",
                color = time_color,
            ),
        ],
    )

def main(config):
    """Point d'entree principal."""
    stop_id = config.get("stop_id", "190967")

    # Recuperer les donnees
    data = get_departures(stop_id)

    if not data or not data.get("departures"):
        return render.Root(
            child = render.Box(
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = "SOLEA",
                            font = "6x13",
                            color = "#BE0013",
                        ),
                        render.Box(height = 2),
                        render.Text(
                            content = "Pas de tram",
                            font = "tom-thumb",
                            color = "#666",
                        ),
                    ],
                ),
            ),
        )

    stop_name = data.get("stop_name", "Station")
    departures = data.get("departures", [])

    # Formater le nom de la station
    if stop_name:
        stop_name = stop_name.title()
        if len(stop_name) > 16:
            stop_name = stop_name[:15] + "."

    # En-tete avec nom de la station
    header = render.Box(
        height = 9,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = stop_name,
                    font = "tom-thumb",
                    color = "#FFD700",
                ),
            ],
        ),
    )

    # Ligne de separation
    separator = render.Box(
        height = 1,
        color = "#333",
    )

    # Lignes de depart (max 3)
    rows = []
    for dep in departures[:3]:
        rows.append(render_departure_row(dep))

    # Espacement entre les lignes
    departure_column = render.Column(
        expanded = True,
        main_align = "space_evenly",
        children = rows,
    )

    return render.Root(
        delay = 100,
        child = render.Column(
            children = [
                header,
                separator,
                departure_column,
            ],
        ),
    )

def get_schema():
    """Schema de configuration."""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "stop_id",
                name = "Station",
                desc = "Choisissez votre station de tram",
                icon = "trainSubway",
                default = "190967",
                options = TRAM_STATIONS,
            ),
        ],
    )
