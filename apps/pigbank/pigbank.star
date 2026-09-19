"""
Applet: PigBank
Summary: O cofrinho da criança
Description: Mostra o cofrinho da criança no PigBank, uma tela por porquinho e lembra o dia da mesada.
Author: PigBank
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Endereco publico do PigBank (a rota repassa para o backend)
API_URL = "https://pigbank.com.br/api/panel/cofrinho"
CACHE_SECONDS = 60

# Quadros de 0,6 s: 25 quadros = 15 s, o tempo de um app na rotacao do painel
FRAME_MS = 600
TOTAL_FRAMES = 25

WHITE = "#F4F1EA"
EMERALD = "#1FD19A"
AMBER = "#FFB020"
DIM = "#6E6862"
OFF = "#3A3530"

SMALL = "tom-thumb"
BIG = "5x8"

# Sprites desenhados LED a LED (mesmos do canvas): porquinho 16x14 nas tres cores,
# acordado e dormindo, e o "Zz" de quem tem moedas dormindo
PIG_PINK = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAAs0lEQVR42mNggIL/USv+/49a8Z+BAEBXxwgThKswkMFvwoUncCbjsghGFnyaNi5bxsDAwMDgHxXFgNWCZQwMjP+7jhB0Nj7AhMxhLLNhJKQBXQ0TA4UA4YULTxD+u3oHu2ptFQZ0tUwYgXP1DkP1jkUYeqt3LEIYjBSQmIGIy3Z0V6CkAzJjgrHMBpoO8KQBGEBJC+guIMcVsOiEu+Dh3mMMDAwMDAo7y/CmhQfuXf+pmg4AvYxCrbhbE0wAAAAASUVORK5CYII=")
PIG_PINK_SLEEPY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAAtklEQVR42mNggIL/USv+/49a8Z+BAEBXxwgThKswkMFvwoUncCbjsghGFnyaNi5bxsDAwMDgHxXFgNWCZQwMjP+7jhB0Nj7AxEAhYEF3LoaTsXgJWQ3CCxeeIPx39Q5267RVGNDVMmEEztU7DNU7FmHord6xCGEwUkBiBiIu29FdgZIOyIwJxjIbRhZcksgBhi9gGeFJlERXMJbZMKJE48O9xxgYGBgYFHaWMeLT+MC96z9VExIAU9ZHR40nGSsAAAAASUVORK5CYII=")
PIG_AMBER = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAAt0lEQVR42mNggIKv87j/f53H/Z+BAEBXxwgThAlwqRvhNeDbzXNwNnfSV0ZGBgYGhv9HbbHaPHvqYQYGBgaG1GxbrIYxWh9mZMSlmVjAhG4iIQ3oapgYKARwL3y7eQ4egD/u3sOqmENZiQFdLRN66P+4e4+hZMZTDM0lM57CDUaOKYxAxGU7uitQ0gG5McFofZiRBZckLA3AAM60AGOQ6gpYdMJd8PAoxEaFMga8aeFBF8N/qqYDAARDSgMDbrq3AAAAAElFTkSuQmCC")
PIG_AMBER_SLEEPY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAAuElEQVR42mNggIKv87j/f53H/Z+BAEBXxwgThAlwqRvhNeDbzXNwNnfSV0ZGBgYGhv9HbbHaPHvqYQYGBgaG1GxbrIYxWh9mZMSlmVjAxEAhYEF3Lj4nY1MD98K3m+fgAfjj7j2sBnAoKzGgq2VCD/0fd+8xlMx4iqG5ZMZTuMHIMYURiLhsR3cFSjogNyYYrQ8zsuCSRA4wvGkBxiDVFYzWhxlRovHhUYiNCmUIQ7GBB10M/6makAArnU4FFOcFYwAAAABJRU5ErkJggg==")
PIG_LILAC = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAAtklEQVR42mNggILunG//u3O+/WcgANDVMcIEYQJ6Zpx4Dbh06jucXTqFi5EFn6bJ3QsZGBgYGHJL4xlwWcC4c9F/gs7GB5iQOe5xjIyENKCrYWKgEMC9cOnUd7j/Ht/7jVWxrBIrA7paJvTAeXzvN8P0BSUYmqcvKIEbjByQGIGIy3Z0V6CkA3Jjwj2OEZIO8KUBGEBOCxguIMcVsOiEu+DwrucMDAwMDC1LpPCmhZqYZ/+pmg4AWItJCvEJd1wAAAAASUVORK5CYII=")
PIG_LILAC_SLEEPY = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAAuElEQVR42mNggILunG//u3O+/WcgANDVMcIEYQJ6Zpx4Dbh06jucXTqFi5EFn6bJ3QsZGBgYGHJL4xlwWcC4c9F/gs7GB5gYKAQs6M5FdzI2LyGrgXvh0qnvcP89vvcbqwGySqwM6GqZ0APn8b3fDNMXlGBonr6gBG4wckBiBCIu29FdgZIOyI0J9zhGRhZcksgBhi9gGWEMUl3hHsfIiBKNh3c9Z2BgYGBoWSLFiE9jTcyz/1RNSAAmx02+sqOfuAAAAABJRU5ErkJggg==")
ZZ = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAM0lEQVR42mNkQAM9U///ZyAEeqb+/8/QM/X/fxhG182ILFCSzciIYSxOe/A5gAmmAJsiAJAIJlrSy+g8AAAAAElFTkSuQmCC")
PIGS = {
    "pink": (PIG_PINK, PIG_PINK_SLEEPY),
    "amber": (PIG_AMBER, PIG_AMBER_SLEEPY),
    "lilac": (PIG_LILAC, PIG_LILAC_SLEEPY),
}
PIG_TOP = {"pink": "#FF8AC4", "amber": "#FFC53D", "lilac": "#B9A2FF"}
PINK = "#FF6FB0"

# Area a direita do porquinho
RIGHT_X = 20
RIGHT_W = 44

ACCENTS = {
    "Á": "A",
    "À": "A",
    "Â": "A",
    "Ã": "A",
    "É": "E",
    "Ê": "E",
    "Í": "I",
    "Ó": "O",
    "Ô": "O",
    "Õ": "O",
    "Ú": "U",
    "Ü": "U",
    "Ç": "C",
}

def main(config):
    key = config.str("key", "").strip()
    if not key:
        return message("COLE A", "CHAVE", AMBER)

    response = http.get(
        config.str("api", API_URL),
        headers = {"Authorization": "Bearer " + key},
        ttl_seconds = CACHE_SECONDS,
    )
    if response.status_code == 401:
        error = response.json().get("error", "invalid")
        return message("CHAVE", "REVOGADA" if error == "revoked" else "INVALIDA", AMBER)
    if response.status_code != 200:
        return message("SEM", "CONEXAO", DIM)

    data = response.json()
    name = display_name(data.get("name"))

    if data.get("firstTime"):
        return render.Root(child = render.Stack(children = [
            pig(),
            centered("OI " + name + "!" if name else "OI!", 9, WHITE),
            centered("PIGBANK", 17, EMERALD),
            centered("CONECTADO", 23, DIM),
        ]))

    piggies = data.get("piggies") or []
    screens = 1 + len(piggies)

    # Cofrinho: no dia da mesada o lembrete ocupa a linha de baixo, de ponta a ponta,
    # e pisca (aceso 1,2 s, apagado 0,6 s)
    top = centered(name, 3, WHITE) if name else centered("COFRINHO", 3, EMERALD)
    base = [pig(PIG_PINK), top, balance(data["balance"], 12)]
    mesada = data.get("mesada")
    if mesada:
        reminder = "MESADA HOJE!" if mesada == "today" else "E A MESADA?"
        lit = render.Stack(children = base + [at(0, 25, render.Box(width = 64, height = 6, child = render.Text(reminder, font = SMALL, color = AMBER)))])
        cofrinho = [lit, lit, render.Stack(children = base)] * 3
    else:
        cofrinho = [render.Stack(children = base + [dots(screens, 0, 28)])] * 9

    if not piggies:
        if not mesada:
            return render.Root(child = cofrinho[0])
        return render.Root(delay = FRAME_MS, child = render.Animation(children = cofrinho))

    # Depois do cofrinho, uma tela por porquinho; tudo cabe em uns 15 s de rotacao
    per_piggy = max(4, min(8, (TOTAL_FRAMES - len(cofrinho)) // len(piggies)))
    frames = list(cofrinho)
    for i, piggy in enumerate(piggies):
        frames += [porquinho(piggy, i + 1, screens)] * per_piggy
    return render.Root(delay = FRAME_MS, child = render.Animation(children = frames))

# Tela de um porquinho: nome, quanto tem guardado e os filhotinhos da proxima mesada
def porquinho(piggy, index, screens):
    color = piggy.get("color", "pink")
    sprites = PIGS.get(color, PIGS["pink"])
    sleeping = piggy.get("sleeping", False)
    children = [
        pig(sprites[1] if sleeping else sprites[0]),
        at(21, 2, render.Box(width = 43, height = 6, child = render.Text(piggy.get("label", ""), font = SMALL, color = PIG_TOP.get(color, WHITE)))),
        balance(piggy.get("value", 0), 10),
        dots(screens, index, 30),
    ]
    if sleeping:
        children.append(at(10, 1, render.Image(src = ZZ)))
    upcoming = piggy.get("next", 0)
    if upcoming > 0:
        # Filhotinhos da proxima mesada, em rosa. "PROX" cabe ate 6 caracteres ("+24,69")
        text = "+" + format_brl(upcoming)
        line = [render.Text(text, font = SMALL, color = PINK)]
        if len(text) <= 6:
            line.append(render.Padding(pad = (3, 0, 0, 0), child = render.Text("PROX", font = SMALL, color = DIM)))
        children.append(at(RIGHT_X, 23, render.Box(width = RIGHT_W, height = 6, child = render.Row(children = line))))
    return render.Stack(children = children)

def at(x, y, child):
    return render.Padding(pad = (x, y, 0, 0), child = child)

def pig(src = None):
    return at(2, 9, render.Image(src = src or PIG_PINK))

def centered(text, y, color):
    return at(RIGHT_X, y, render.Box(width = RIGHT_W, height = 6, child = render.Text(text, font = SMALL, color = color)))

def balance(value, y):
    text = format_brl(value)

    # Com quatro digitos ou mais o "R$" sai para o valor caber ao lado do porquinho
    children = [render.Text(text, font = BIG, color = WHITE)]
    if value < 1000:
        children = [
            render.Padding(pad = (0, 0, 2, 1), child = render.Text("R$", font = SMALL, color = EMERALD)),
        ] + children
    return at(RIGHT_X, y, render.Box(width = RIGHT_W, height = 8, child = render.Row(cross_align = "end", children = children)))

# Pontinhos: quantas telas o app mostra e qual esta na frente
def dots(count, active, y):
    if count < 2:
        return render.Box(width = 1, height = 1)
    row = []
    for i in range(count):
        if i:
            row.append(render.Box(width = 2, height = 1))
        row.append(render.Box(width = 1, height = 1, color = EMERALD if i == active else OFF))
    return at(RIGHT_X, y, render.Box(width = RIGHT_W, height = 1, child = render.Row(children = row)))

def message(line1, line2, color):
    return render.Root(child = render.Stack(children = [
        pig(),
        centered("PIGBANK", 6, EMERALD),
        centered(line1, 14, WHITE),
        centered(line2, 21, color),
    ]))

# "Laura" -> "LAURA"; tira acentos (a fonte de LED so tem ASCII) e corta para caber
def display_name(name):
    if not name:
        return None
    upper = name.upper()
    for accented, plain in ACCENTS.items():
        upper = upper.replace(accented, plain)
    return upper[:11]

# 62.5 -> "62,50"; 1234.5 -> "1.234,50"; de 10 mil para cima, sem centavos
def format_brl(value):
    cents = int(value * 100 + (0.5 if value >= 0 else -0.5))
    negative = cents < 0
    cents = -cents if negative else cents
    reais = cents // 100
    rest = cents % 100

    digits = str(reais)
    groups = []
    for _ in range(6):
        if len(digits) <= 3:
            break
        groups.insert(0, digits[-3:])
        digits = digits[:-3]
    groups.insert(0, digits)
    text = ".".join(groups)

    if reais < 10000:
        text = text + "," + ("0" + str(rest) if rest < 10 else str(rest))
    return "-" + text if negative else text

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "Chave do PigBank",
                desc = "Gere a chave no app PigBank, em Ajustes.",
                icon = "key",
            ),
        ],
    )
