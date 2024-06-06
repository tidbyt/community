"""
Applet: UK Opinion Polls
Summary: Latest political polls
Description: Shows the current state of the political parties in the UK.
Author: dinosaursrarr
"""

load("bsoup.star", "bsoup")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BBC_URL = "https://www.bbc.co.uk/polltracker"
TABLE_DIV_ID = "responsive-embed-newsspec-38103-poll-tracker-2024-table"
DATE_SPAN = "table-header__date"
POLLSTER_SPAN = "table-header__firm"
SAMPLE_SIZE_SPAN = "table-header__sample"

DIV = "div"
SPAN = "span"
TABLE = "table"
TBODY = "tbody"
TR = "tr"
TH = "th"
TD = "td"

PERIOD = "period"
DATE = "date"
POLLSTER = "pollster"
SAMPLE_SIZE = "sample_size"
CONSERVATIVE = "con"
LABOUR = "lab"
LIBDEM = "ld"
GREEN = "grn"
REFORM = "ref"
SCOTTISH_NATIONAL_PARTY = "snp"
PLAID_CYMRU = "pc"

SHOWN = (LABOUR, CONSERVATIVE, GREEN, LIBDEM, REFORM)
OTHER = "other"

# https://en.wikipedia.org/wiki/Wikipedia:Index_of_United_Kingdom_political_parties_meta_attributes
# Original party colour + with saturation and lightness reduced 20%
PARTY_COLOURS = {
    LABOUR: ("#e4003b", "#a41238"),
    CONSERVATIVE: ("#0087dc", "#11689e"),
    GREEN: ("#02a95b", "#0e7947"),
    LIBDEM: ("#faa61a", "#c28319"),
    REFORM: ("#12b6cf", "#1d8696"),
    SCOTTISH_NATIONAL_PARTY: ("#fdf38e", "#e8db53"),
    PLAID_CYMRU: ("#005b54", "#07413d"),
    OTHER: ("#cccccc", "#cccccc"),
}

DATE_REGEX = r"(?:- )?(?P<day>\d+) (?P<month>\w+) (?P<year>\d+)$"

# Can't just parse it as is because Go doesn't recognise "Sept" as being "Sep".
def parse_date(text):
    matched = re.match(DATE_REGEX, text)
    day, month, year = matched[0][-3:]
    date = "{} {} 20{}".format(day, month[:3], year)
    return time.parse_time(date, "2 Jan 2006")

# Some polls didn't include Reform or other small parties so there's no data.
def parse_percentage(text):
    if not text.isdigit():
        return None
    return int(text)

# Extract data from a single row of the table
def parse_row(row):
    spans = row.child(TH).find_all(SPAN)
    cells = row.find_all(TD)
    data = {
        DATE: parse_date(spans[1].get_text()),
        POLLSTER: spans[2].get_text(),
        SAMPLE_SIZE: int(spans[3].get_text().replace(",", "")),
        CONSERVATIVE: parse_percentage(cells[0].get_text()),
        LABOUR: parse_percentage(cells[1].get_text()),
        LIBDEM: parse_percentage(cells[2].get_text()),
        GREEN: parse_percentage(cells[3].get_text()),
        REFORM: parse_percentage(cells[4].get_text()),
        SCOTTISH_NATIONAL_PARTY: parse_percentage(cells[5].get_text()),
        PLAID_CYMRU: parse_percentage(cells[6].get_text()),
    }

    shown = [value for party, value in data.items() if party in SHOWN and value]
    data[OTHER] = 100 - sum(shown)
    return data

# Extract data from the entire table
def parse_table(table):
    return [parse_row(row) for row in table.find(TBODY).find_all(TR)]

# Annoying that this isn't built in or in the math module.
def sum(list):
    total = 0
    for item in list:
        total += item
    return total

# Plot the polling average for a given party over the given time period
def draw_series(data, key, days):
    now = time.now()
    today = time.time(year = now.year, month = now.month, day = now.day)
    series = sorted([((row[DATE] - today) // (24 * time.hour), row[key]) for row in data if row[key]], reverse = True)

    newest_day = series[0][0]
    oldest_day = max(series[-1][0], -days)
    days = newest_day - oldest_day
    days_per_pixel = max(1, days // 32)
    newest = newest_day // days_per_pixel
    oldest = oldest_day // days_per_pixel

    polls_by_pixel = {}
    for day, poll in series:
        pixel = day // days_per_pixel
        if pixel in polls_by_pixel:
            polls_by_pixel[pixel].append(poll)
            continue
        polls_by_pixel[pixel] = [poll]
    averages = [(pixel, sum(polls) / len(polls)) for pixel, polls in polls_by_pixel.items()]

    return render.Plot(
        data = averages,
        chart_type = "line",
        width = 64,
        height = 32,
        x_lim = (oldest, newest),
        y_lim = (0, 60),
        color = PARTY_COLOURS[key][1],
    )

# Plot data for all parties.
def draw_chart(data, days):
    return render.Stack(
        children = [
            draw_series(data, party, days)
            for party in SHOWN
        ],
    )

# Give it some context
def draw_title(period):
    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.WrappedText(
            content = "UK polls".format(period),
            font = "tom-thumb",
            width = 64,
            align = "center",
        ),
    )

def main(config):
    wiki = http.get(BBC_URL, ttl_seconds = 60)
    if wiki.status_code != 200:
        return render.Root(
            child = render.Text("Could not load polling data"),
        )
    page = bsoup.parseHtml(wiki.body())
    table = page.find(DIV, id = TABLE_DIV_ID).find(TABLE)
    data = parse_table(table)

    period = config.get(PERIOD, "30")
    return render.Root(
        child = render.Stack(
            children = [
                draw_chart(data, int(period)),
                draw_title(period),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = PERIOD,
                name = "Period",
                desc = "Show polls from the most recent",
                icon = "calendar",
                default = "30",
                options = [
                    schema.Option(
                        display = "One week",
                        value = "7",
                    ),
                    schema.Option(
                        display = "Two weeks",
                        value = "14",
                    ),
                    schema.Option(
                        display = "30 days",
                        value = "30",
                    ),
                    schema.Option(
                        display = "90 days",
                        value = "90",
                    ),
                    schema.Option(
                        display = "180 days",
                        value = "180",
                    ),
                    schema.Option(
                        display = "One year",
                        value = "365",
                    ),
                    schema.Option(
                        display = "Two years",
                        value = "730",
                    ),
                    schema.Option(
                        display = "Three years",
                        value = "1095",
                    ),
                    schema.Option(
                        display = "Four years",
                        value = "1460",
                    ),
                    schema.Option(
                        display = "Five years",
                        value = "1825",
                    ),
                ],
            ),
        ],
    )
