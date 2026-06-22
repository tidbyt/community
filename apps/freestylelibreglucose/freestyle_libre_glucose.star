"""
Freestyle Libre Glucose
Displays real-time glucose levels from Freestyle Libre via LibreLinkUp.
Shows current value, trend arrow, 4-hour history graph, and color-coded alerts.

Author: Bob (@Eserobe)
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ─── Configuración de la API ───────────────────────────────────────────────────

LLU_REGIONS = {
    "eu": "https://api-eu.libreview.io",
    "eu2": "https://api-eu2.libreview.io",
    "us": "https://api.libreview.io",
    "de": "https://api-de.libreview.io",
    "fr": "https://api-fr.libreview.io",
    "jp": "https://api-jp.libreview.io",
    "ap": "https://api-ap.libreview.io",
    "au": "https://api-au.libreview.io",
}

LLU_BASE_HEADERS = {
    "version": "4.17.0",
    "product": "llu.ios",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Connection": "keep-alive",
    "Pragma": "no-cache",
    "Cache-Control": "no-cache",
}

# Flechas de tendencia del sensor
TREND_ARROWS = {
    1: "↓↓",  # caída rápida
    2: "↓",  # caída
    3: "→",  # estable
    4: "↑",  # subida
    5: "↑↑",  # subida rápida
}

# ─── Helpers ───────────────────────────────────────────────────────────────────

def auth_headers(token, account_id):
    return {
        "version": "4.17.0",
        "product": "llu.ios",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Connection": "keep-alive",
        "Pragma": "no-cache",
        "Cache-Control": "no-cache",
        "Authorization": "Bearer " + token,
        "account-id": account_id,
    }

def glucose_color(value, low, high):
    if value < low:
        return "#f44"  # rojo — hipoglucemia
    elif value > high:
        return "#fa0"  # naranja — hiperglucemia
    else:
        return "#0d0"  # verde — rango normal

def error_screen(msg):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = msg,
                color = "#f44",
                width = 60,
                align = "center",
            ),
        ),
    )

def warning_screen(msg):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = msg,
                color = "#fa0",
                width = 60,
                align = "center",
            ),
        ),
    )

# ─── Llamadas a la API ─────────────────────────────────────────────────────────

LLU_DEFAULT_URL = "https://api.libreview.io"

def llu_login(email, password, base_url):
    """
    Devuelve (token, account_id, url_final, error).
    El login siempre empieza en LLU_DEFAULT_URL y sigue el redirect al servidor regional.
    """
    body = json.encode({"email": email, "password": password})
    rep = http.post(base_url + "/llu/auth/login", headers = LLU_BASE_HEADERS, body = body)

    if rep.status_code != 200:
        return None, None, base_url, "HTTP " + str(rep.status_code)

    data = rep.json()
    status = int(data.get("status", -1))

    # Rate limit
    if status == 429:
        return None, None, base_url, "Rate limit (429)"

    # Redirect al servidor regional correcto (status == 2)
    if status == 2:
        outer = data.get("data", {})
        shard = (
            outer.get("region") or
            outer.get("shard") or
            data.get("region") or
            data.get("shard") or
            ""
        )
        redirect = outer.get("redirect", {})
        if not shard and type(redirect) == "dict":
            shard = redirect.get("region") or redirect.get("shard") or ""

        if not shard:
            # Sin región en la respuesta: probar el endpoint global como fallback
            fallback = "https://api.libreview.io"
            if base_url != fallback:
                return llu_login(email, password, fallback)
            return None, None, base_url, "No region: " + str(data)

        new_url = "https://api-" + str(shard).lower() + ".libreview.io"
        if new_url == base_url:
            return None, None, base_url, "Redirect loop: " + shard
        return llu_login(email, password, new_url)

    if status != 0:
        err_msg = data.get("error", {}).get("message", "")
        return None, None, base_url, "status=" + str(status) + " " + err_msg

    inner = data.get("data", {})
    ticket = inner.get("authTicket", {})
    token = ticket.get("token", "")
    user_id = inner.get("user", {}).get("id", "")

    # account-id = SHA-256(user.id) — requerido por la API LibreLinkUp
    account_id = hash.sha256(user_id)

    if not token:
        return None, None, base_url, "Token vacío. inner=" + str(inner)

    return token, account_id, base_url, None

def llu_connections(token, account_id, base_url):
    rep = http.get(base_url + "/llu/connections", headers = auth_headers(token, account_id))
    if rep.status_code != 200:
        return None, "HTTP " + str(rep.status_code) + " " + rep.body()[:100]
    data = rep.json()
    conns = data.get("data", [])
    return conns, None

def llu_graph(token, account_id, patient_id, base_url):
    url = base_url + "/llu/connections/" + patient_id + "/graph"
    rep = http.get(url, headers = auth_headers(token, account_id))
    if rep.status_code != 200:
        return None, "HTTP " + str(rep.status_code)
    return rep.json().get("data", {}), None

# ─── App principal ─────────────────────────────────────────────────────────────

def main(config):
    email = config.get("email", "")
    password = config.get("password", "")
    low_str = config.get("low_threshold", "70")
    high_str = config.get("high_threshold", "180")

    if email == "" or password == "":
        return warning_screen("Configura tu cuenta LibreLinkUp")

    low = int(low_str) if low_str != "" else 70
    high = int(high_str) if high_str != "" else 180

    # ── Autenticación (caché 45 min) ─────────────────────────────────────────
    cache_key = "llu_token_" + email
    cache_key_aid = "llu_acct_" + email
    cache_key_url = "llu_url_" + email
    cache_key_rate = "llu_rate_" + email
    token = cache.get(cache_key)
    account_id = cache.get(cache_key_aid) or ""
    base_url = cache.get(cache_key_url) or LLU_DEFAULT_URL

    if token == None:
        if cache.get(cache_key_rate) != None:
            return error_screen("Rate limit. Espera 30 min.")

        token, account_id, base_url, err = llu_login(email, password, LLU_DEFAULT_URL)
        if err != None:
            if "429" in err or "Rate limit" in err:
                cache.set(cache_key_rate, "blocked", ttl_seconds = 1800)
            return error_screen("Login: " + err)
        cache.set(cache_key, token, ttl_seconds = 28800)  # 8 horas
        cache.set(cache_key_aid, account_id, ttl_seconds = 28800)
        cache.set(cache_key_url, base_url, ttl_seconds = 28800)

    # ── Conexiones (pacientes) ────────────────────────────────────────────────
    conns, err = llu_connections(token, account_id, base_url)
    if err != None:
        return error_screen("Conexión: " + err)
    if conns == None or len(conns) == 0:
        return warning_screen("Sin conexiones LibreLinkUp")

    conn = conns[0]
    patient_id = conn.get("patientId", "")
    glucose_m = conn.get("glucoseMeasurement", {})
    current = int(glucose_m.get("Value", 0))
    trend_id = int(glucose_m.get("TrendArrow", 3))
    arrow = TREND_ARROWS.get(trend_id, "→")

    # Minutos desde la última lectura (para los cuadraditos)
    n_dots = 0
    ts_str = glucose_m.get("FactoryTimestamp", "") or glucose_m.get("Timestamp", "")
    if ts_str != "":
        t = None
        formats = [
            "1/2/2006 3:04:05 PM",  # M/D/YYYY 12h (LibreLinkUp estándar)
            "1/2/2006 15:04:05",  # M/D/YYYY 24h
            "2006-01-02T15:04:05Z",  # ISO 8601 UTC
            "2006-01-02T15:04:05",  # ISO 8601 sin Z
        ]
        for fmt in formats:
            parsed = time.parse_time(ts_str, format = fmt, location = "UTC")
            if parsed != None and str(parsed) != "0001-01-01 00:00:00 +0000 UTC":
                t = parsed
                break
        if t != None:
            diff = time.now() - t
            n_dots = int(diff.seconds) // 60  # diff.minutes no funciona en Pixlet
            if n_dots < 0:
                n_dots = 0
            if n_dots > 9:
                n_dots = 9

    dot_widgets = []
    for i in range(n_dots):
        if i > 0:
            dot_widgets.append(render.Box(width = 1, height = 2))
        dot_widgets.append(render.Box(width = 2, height = 2, color = "#888"))

    # ── Datos históricos para la gráfica ─────────────────────────────────────
    graph_data, _ = llu_graph(token, account_id, patient_id, base_url)
    raw_history = []
    if graph_data != None:
        raw_history = graph_data.get("graphData", [])

    # Ventana fija de 4h (240 min). x = minutos desde "hace 4h" hasta "ahora"
    start = len(raw_history) - 48 if len(raw_history) > 48 else 0
    points = raw_history[start:]
    n_pts = len(points)

    plot_data = []
    for i, pt in enumerate(points):
        minutes = 240.0 - float(n_pts - 1 - i) * 5.0
        plot_data.append((minutes, float(pt.get("Value", current))))

    if len(plot_data) < 2:
        plot_data = [(235.0, float(current)), (240.0, float(current))]

    color = glucose_color(current, low, high)

    # ── Gráfica con color por zona y separadores horarios ────────────────────
    low_f = float(low)
    high_f = float(high)

    data_low = [pt for pt in plot_data if pt[1] < low_f]
    data_normal = [pt for pt in plot_data if pt[1] >= low_f and pt[1] <= high_f]
    data_high = [pt for pt in plot_data if pt[1] > high_f]

    plot_layers = []
    if len(data_low) >= 2:
        plot_layers.append(render.Plot(
            data = data_low,
            color = "#f44",
            width = 62,
            height = 17,
            x_lim = (0.0, 240.0),
            y_lim = (50.0, 250.0),
            fill = False,
        ))
    if len(data_normal) >= 2:
        plot_layers.append(render.Plot(
            data = data_normal,
            color = color,
            width = 62,
            height = 17,
            x_lim = (0.0, 240.0),
            y_lim = (50.0, 250.0),
            fill = False,
        ))
    if len(data_high) >= 2:
        plot_layers.append(render.Plot(
            data = data_high,
            color = "#fa0",
            width = 62,
            height = 17,
            x_lim = (0.0, 240.0),
            y_lim = (50.0, 250.0),
            fill = False,
        ))
    if len(plot_layers) == 0:
        plot_layers = [render.Plot(
            data = plot_data,
            color = color,
            width = 62,
            height = 17,
            x_lim = (0.0, 240.0),
            y_lim = (50.0, 250.0),
            fill = False,
        )]

    sep_row = render.Row(
        children = [
            render.Box(width = 16, height = 17),
            render.Box(width = 1, height = 17, color = "#555"),
            render.Box(width = 14, height = 17),
            render.Box(width = 1, height = 17, color = "#555"),
            render.Box(width = 15, height = 17),
            render.Box(width = 1, height = 17, color = "#555"),
        ],
    )

    graph_widget = render.Stack(children = plot_layers + [sep_row])

    # Marco de 1px con dimensiones fijas 64×32
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = color,
            padding = 1,
            child = render.Stack(
                children = [
                    render.Box(
                        width = 62,
                        height = 30,
                        color = "#000",
                    ),
                    render.Column(
                        children = [
                            render.Box(
                                width = 62,
                                height = 13,
                                child = render.Row(
                                    cross_align = "center",
                                    children = [
                                        render.Box(width = 2),
                                        render.Text(
                                            content = str(current),
                                            font = "6x13",
                                            color = color,
                                        ),
                                        render.Box(width = 2),
                                        render.Text(
                                            content = arrow,
                                            font = "tb-8",
                                            color = color,
                                        ),
                                        render.Box(width = 3),
                                    ] + dot_widgets,
                                ),
                            ),
                            graph_widget,
                        ],
                    ),
                ],
            ),
        ),
        max_age = 300,
    )

# ─── Esquema de configuración ──────────────────────────────────────────────────

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "email",
                name = "Email LibreLinkUp",
                desc = "Correo de tu cuenta LibreLinkUp",
                icon = "envelope",
            ),
            schema.Text(
                id = "password",
                name = "Contraseña LibreLinkUp",
                desc = "Contraseña de tu cuenta LibreLinkUp",
                icon = "lock",
            ),
            schema.Text(
                id = "low_threshold",
                name = "Umbral bajo (mg/dL)",
                desc = "Por debajo se muestra en rojo. Por defecto: 70",
                icon = "exclamation",
                default = "70",
            ),
            schema.Text(
                id = "high_threshold",
                name = "Umbral alto (mg/dL)",
                desc = "Por encima se muestra en naranja. Por defecto: 180",
                icon = "exclamation",
                default = "180",
            ),
        ],
    )
