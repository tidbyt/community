"""
Applet: House of Commons
Summary: Predicted election results
Description: Predicted seat and vote shares for the UK's House of Commons based on opinion polls.
Author: dinosaursrarr
"""

load("bsoup.star", "bsoup")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

SOURCE = "source"
CARDS = "cards"
CATEGORY = "category"
TEXT = "text"
VOTE_SHARE = "vote_share"
SEATS = "seats"

LABOUR = "Lab"
CONSERVATIVE = "Con"
GREEN = "Grn"
LIBDEM = "LDem"
REFORM = "Ref"
SCOTTISH_NATIONAL_PARTY = "SNP"
PLAID_CYMRU = "PC"
OTHER = "Oth"

SIZE_OF_HOUSE_OF_COMMONS = 650
NORTHERN_IRELAND_SEATS = 18

WHITE = "#ffffff"
BLACK = "#000000"
PARTY_COLOURS = {
    LABOUR: ("#e4003b", WHITE),
    CONSERVATIVE: ("#0087dc", WHITE),
    GREEN: ("#02a95b", WHITE),
    LIBDEM: ("#faa61a", BLACK),
    REFORM: ("#12b6cf", BLACK),
    SCOTTISH_NATIONAL_PARTY: ("#fdf38e", BLACK),
    PLAID_CYMRU: ("#005b54", WHITE),
    OTHER: ("#cccccc", BLACK),
}

NEW_STATESMAN = "New Statesman"
ELECTORAL_CALCULUS = "Electoral Calculus"
ELECTION_POLLING = "Election Polling"
URL = "url"
NAMES = "names"
DISPLAY = "display"

SOURCES = {
    NEW_STATESMAN: {
        DISPLAY: "New Statesman",
        URL: "https://flo.uri.sh/visualisation/18073501/embed?auto=1",
    },
    ELECTORAL_CALCULUS: {
        DISPLAY: "ElectoralCalculus",
        URL: "https://www.electoralcalculus.co.uk/prediction_main.html",
        NAMES: {
            "CON": CONSERVATIVE,
            "LAB": LABOUR,
            "LIB": LIBDEM,
            "Reform": REFORM,
            "Green": GREEN,
            "SNP": SCOTTISH_NATIONAL_PARTY,
            "PlaidC": PLAID_CYMRU,
            "Other": OTHER,
        },
    },
    ELECTION_POLLING: {
        DISPLAY: "electionpolling",
        URL: "https://www.electionpolling.co.uk/forecasts/uk-parliament",
        NAMES: {
            "Labour": LABOUR,
            "Conservative": CONSERVATIVE,
            "Reform UK": REFORM,
            "Liberal Democrat": LIBDEM,
            "Green": GREEN,
            "SNP": SCOTTISH_NATIONAL_PARTY,
            "Plaid Cymru": PLAID_CYMRU,
        },
    },
}

SEAT_HEIGHT = 13
FONT = "tom-thumb"
SIX_HOURS = 60 * 60 * 6

def extract_int(s):
    return int("".join([c for c in s.elems() if c.isdigit()]))

def extract_percentage(s):
    return float(s.strip().removesuffix("%").strip()) / 100.0

def divmod(x, a):
    return x // a, x % a

def compute_outcome(predictions):
    total_seats = NORTHERN_IRELAND_SEATS  # these aren't included in prediction
    biggest_party = None
    biggest_seats = 0
    for party, prediction in predictions.items():
        total_seats += prediction[SEATS]
        if prediction[SEATS] > biggest_seats:
            biggest_party = party
            biggest_seats = prediction[SEATS]
    opposition_seats = total_seats - biggest_seats

    if biggest_seats > opposition_seats:
        return "{} win by {}".format(biggest_party, biggest_seats - opposition_seats), biggest_party
    return "Hung parliament", biggest_party

def render_seat_count(party, seats):
    return render.Box(
        color = PARTY_COLOURS[party][0],
        height = 9,
        width = 16,
        child = render.WrappedText(
            str(seats),
            align = "center",
            height = 8,
            width = 13,
            color = PARTY_COLOURS[party][1],
        ),
    )

def render_seats(predictions, source):
    mps = {
        party: render.Box(height = 1, width = 1, color = PARTY_COLOURS[party][0])
        for party in predictions
    }
    mps[None] = render.Box(height = 1, width = 1, color = BLACK)
    seats = sorted([(prediction[SEATS], prediction[VOTE_SHARE], party) for party, prediction in predictions.items()], reverse = True)

    seats.append((NORTHERN_IRELAND_SEATS, 0, OTHER))
    opposition = [[]]
    for seat_count, _, party in seats[:0:-1]:
        for _ in range(seat_count):
            current_col = opposition[-1]
            if len(current_col) == SEAT_HEIGHT:
                current_col = current_col[::-1]
                opposition.append([])
                current_col = opposition[-1]
            current_col.append(mps[party])
    opposition[-1] = [mps[None]] * (SEAT_HEIGHT - len(opposition[-1])) + opposition[-1]

    government = divmod(seats[0][0], SEAT_HEIGHT)
    return render.Column(
        cross_align = "center",
        children = [
            render.Stack(
                children = [
                    render.Box(
                        width = government[0],
                        height = SEAT_HEIGHT,
                        color = PARTY_COLOURS[seats[0][2]][0],
                    ),
                    render.Padding(
                        pad = (government[0], 0, 0, 0),
                        child = render.Box(
                            width = 1,
                            height = government[1],
                            color = PARTY_COLOURS[seats[0][2]][0],
                        ),
                    ),
                ] + [
                    render.Padding(
                        pad = (government[0] + 2 + i, 0, 0, 0),
                        child = render.Column(
                            children = opposition[-i - 1],
                        ),
                    )
                    for i in range(len(opposition))
                ],
            ),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Animation(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            children = [
                                render_seat_count(party, seat_count)
                                for seat_count, _, party in seats[i:i + 4]
                            ],
                        )
                        for i in range(0, len(seats) - 1, 4)
                    ] + [
                        render.Padding(
                            pad = (0, 1, 0, 0),
                            child = render.WrappedText(
                                SOURCES[source][DISPLAY],
                                align = "center",
                                width = 64,
                                font = FONT,
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )

def render_error(msg):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = PARTY_COLOURS[OTHER][0],
                    child = render.WrappedText(
                        "House of Commons",
                        font = FONT,
                        width = 64,
                        align = "center",
                        color = PARTY_COLOURS[OTHER][1],
                    ),
                ),
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.WrappedText(
                        msg,
                        width = 60,
                        align = "center",
                    ),
                ),
            ],
        ),
    )

def fetch_source(source):
    resp = http.get(SOURCES[source][URL], ttl_seconds = SIX_HOURS)
    if resp.status_code != 200:
        return None
    return resp

def new_statesman_predictions():
    resp = fetch_source(NEW_STATESMAN)
    if not resp:
        return None

    (data,) = re.match(r"_Flourish_data\s*=\s*({.+?}),\n", resp.body())
    (_, data) = data
    j = json.decode(data)

    predictions = {}
    for card in j[CARDS]:
        predictions[card[CATEGORY]] = {
            SEATS: extract_int(card[TEXT][2]),
            VOTE_SHARE: extract_percentage(card[TEXT][0]),
        }
    return predictions

def electoral_calculus_predictions():
    resp = fetch_source(ELECTORAL_CALCULUS)
    if not resp:
        return None
    page = bsoup.parseHtml(resp.body())
    rows = page.find("div", id = "seatpred").find("tbody").find_all("tr")[1:]  # ignore headers

    predictions = {}
    for row in rows:
        party, _, _, vote_share, _, seat_count, _ = row.find_all("td")
        if party.get_text() not in SOURCES[ELECTORAL_CALCULUS][NAMES]:
            continue
        predictions[SOURCES[ELECTORAL_CALCULUS][NAMES][party.get_text()]] = {
            SEATS: extract_int(seat_count.find("b").get_text()),
            VOTE_SHARE: extract_percentage(vote_share.get_text()),
        }
    return predictions

def election_polling_predictions():
    resp = fetch_source(ELECTION_POLLING)
    if not resp:
        return None
    page = bsoup.parseHtml(resp.body())
    rows = page.find("table").find_all("tr")[2:]

    total_seats = 0
    predictions = {}
    for row in rows:
        _, party, _, vote_share, _, _, seat_count, _, _, _ = [td.get_text() for td in row.find_all("td")]
        seat_count = extract_int(seat_count)
        total_seats += seat_count
        print(party, seat_count, extract_percentage(vote_share))
        predictions[SOURCES[ELECTION_POLLING][NAMES][party]] = {
            SEATS: seat_count,
            VOTE_SHARE: extract_percentage(vote_share),
        }
    predictions[OTHER] = {
        SEATS: SIZE_OF_HOUSE_OF_COMMONS - total_seats - NORTHERN_IRELAND_SEATS,
        VOTE_SHARE: 0,
    }
    return predictions

def main(config):
    source = config.get(SOURCE, NEW_STATESMAN)
    if source == NEW_STATESMAN:
        predictions = new_statesman_predictions()
    elif source == ELECTORAL_CALCULUS:
        predictions = electoral_calculus_predictions()
    elif source == ELECTION_POLLING:
        predictions = election_polling_predictions()
    else:
        return render_error("You must select a source")

    if not predictions:
        return render_error("Could not fetch data")

    outcome, winner = compute_outcome(predictions)

    return render.Root(
        delay = 2000,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = PARTY_COLOURS[winner][0],
                    child = render.WrappedText(
                        outcome,
                        font = FONT,
                        width = 64,
                        align = "center",
                        color = PARTY_COLOURS[winner][1],
                    ),
                ),
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render_seats(predictions, source),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = SOURCE,
                name = "Source",
                desc = "Which prediction to use?",
                icon = "book",
                default = NEW_STATESMAN,
                options = [
                    schema.Option(
                        display = key,
                        value = key,
                    )
                    for key in sorted(SOURCES, reverse = True)
                ],
            ),
        ],
    )
