"""
Applet: House of Commons
Summary: Predicted election results
Description: Predicted seat and vote shares for the UK's House of Commons according to the New Statesman.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

NEW_STATESMAN = "New Statesman"
NEW_STATESMAN_URL = "https://flo.uri.sh/visualisation/18073501/embed?auto=1"

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

SEAT_HEIGHT = 13
FONT = "tom-thumb"

def extract_number(s):
    return "".join([c for c in s.elems() if c.isdigit()])

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
                                source,
                                align = "center",
                                width = 64,
                                height = 8,
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

def new_statesman_predictions():
    resp = http.get(NEW_STATESMAN_URL, ttl_seconds = 60 * 60 * 24)
    if resp.status_code != 200:
        return render_error("Could not fetch data")

    (data,) = re.match(r"_Flourish_data\s*=\s*({.+?}),\n", resp.body())
    (_, data) = data
    j = json.decode(data)

    predictions = {}
    for card in j[CARDS]:
        predictions[card[CATEGORY]] = {
            SEATS: int(extract_number(card[TEXT][2])),
            VOTE_SHARE: float("0." + extract_number(card[TEXT][0])),
        }
    return predictions, NEW_STATESMAN

def main():
    predictions, source = new_statesman_predictions()

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
        fields = [],
    )
