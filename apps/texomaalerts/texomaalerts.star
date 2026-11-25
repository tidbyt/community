load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

HEADERS = {
    "User-Agent": "Texoma Alerts Tidbyt app",
    "Accept": "application/geo+json",
}

COUNTIES = ["Grayson", "Cooke", "Fannin", "Bryan", "Johnston", "Love", "Marshall"]
ALERT_URLS = [
    "https://api.weather.gov/alerts/active/zone/TXC097",
    "https://api.weather.gov/alerts/active/zone/TXC147",
    "https://api.weather.gov/alerts/active/zone/TXC181",
    "https://api.weather.gov/alerts/active/zone/OKC013",
    "https://api.weather.gov/alerts/active/zone/OKC069",
    "https://api.weather.gov/alerts/active/zone/OKC085",
    "https://api.weather.gov/alerts/active/zone/OKC095",
]
FORECAST_CITIES = [
    {"name": "GAINESVILLE", "lat": 33.6259, "lon": -97.1334},
    {"name": "BONHAM", "lat": 33.5773, "lon": -96.1783},
    {"name": "SHERMAN", "lat": 33.6357, "lon": -96.6089},
    {"name": "DURANT", "lat": 33.9939, "lon": -96.3708},
    {"name": "TISHOMINGO", "lat": 34.2362, "lon": -96.6783},
    {"name": "MARIETTA", "lat": 33.9370, "lon": -97.1167},
    {"name": "MADILL", "lat": 34.0904, "lon": -96.7717},
]

def truncate(text, limit):
    if text == None or text == "":
        return "--"
    if len(text) > limit:
        return text[:limit - 1] + "."
    return text

def active_alerts():
    alerts = []
    seen = {}
    for url in ALERT_URLS:
        response = http.get(url, headers = HEADERS, ttl_seconds = 300)
        if response.status_code != 200:
            return None
        for feature in response.json()["features"]:
            alert_id = feature["id"]
            if alert_id not in seen:
                alerts.append(feature)
                seen[alert_id] = True
    return alerts

def county_label(area):
    label = "TEXOMA"
    lower_area = area.lower()
    for county in COUNTIES:
        if county.lower() in lower_area:
            label = county.upper()
            break
    return label

def forecast_period(city):
    point_url = "https://api.weather.gov/points/%s,%s" % (city["lat"], city["lon"])
    point = http.get(point_url, headers = HEADERS, ttl_seconds = 86400)
    if point.status_code != 200:
        return None
    forecast_url = point.json()["properties"]["forecast"]
    forecast = http.get(forecast_url, headers = HEADERS, ttl_seconds = 1800)
    if forecast.status_code != 200:
        return None
    periods = forecast.json()["properties"]["periods"]
    if len(periods) == 0:
        return None
    return periods[0]

def driving_risk(period):
    summary = period["shortForecast"].lower()
    temperature = period["temperature"]
    precip = period["probabilityOfPrecipitation"]["value"]

    winter_words = "snow" in summary or "sleet" in summary or "freezing" in summary
    if winter_words:
        return "WX: WINTER HAZARD", "#4FC3F7"
    if temperature != None and temperature <= 32 and precip != None and precip >= 20:
        return "WX: ICE POSSIBLE", "#4FC3F7"
    if precip != None and precip >= 50:
        return "WX: WET ROADS", "#FFD54F"
    if "fog" in summary or "smoke" in summary:
        return "WX: LOW VISIBILITY", "#FFD54F"
    return "WX: NO MAJOR HAZARD", "#81C784"

def screen(title, location, detail, color, footer):
    return render.Root(
        delay = 1000,
        max_age = 60,
        child = render.Box(
            color = "#000000",
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(content = "TEXOMA ALERTS", font = "CG-pixel-3x5-mono", color = "#FFD54F"),
                    render.Text(content = truncate(title, 19), font = "CG-pixel-3x5-mono", color = color),
                    render.Text(content = truncate(location, 20), font = "CG-pixel-3x5-mono", color = "#FFFFFF"),
                    render.Text(content = truncate(detail, 20), font = "CG-pixel-3x5-mono", color = "#FFFFFF"),
                    render.Text(content = truncate(footer, 20), font = "CG-pixel-3x5-mono", color = "#AAB3C0"),
                ],
            ),
        ),
    )

def main():
    now = time.now().in_location("America/Chicago")
    alerts = active_alerts()
    if alerts == None:
        return screen("NWS UNAVAILABLE", "TEXOMA", "Try again shortly", "#FF8A65", "DriveTexas.org")

    if len(alerts) > 0:
        alert = alerts[int(now.format("04")) % len(alerts)]["properties"]
        event = alert["event"] or "Weather alert"
        area = alert["areaDesc"] or "Texoma"
        severity = alert["severity"] or "Unknown"
        color = "#FF5252" if severity == "Extreme" or severity == "Severe" else "#FFD54F"
        return screen(event.upper(), county_label(area), "ACTIVE NWS ALERT", color, "DriveTexas.org")

    city = FORECAST_CITIES[int(now.format("04")) % len(FORECAST_CITIES)]
    period = forecast_period(city)
    if period == None:
        return screen("NO ACTIVE ALERTS", "TEXOMA", "Forecast unavailable", "#81C784", "DriveTexas.org")

    risk, color = driving_risk(period)
    temp = str(period["temperature"]) + " F" if period["temperature"] != None else "-- F"
    condition = truncate(period["shortForecast"], 19)
    return screen(risk, city["name"], temp + "  " + condition, color, "DriveTexas.org")
