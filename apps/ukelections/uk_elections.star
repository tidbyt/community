"""
Applet: UK Elections
Summary: Upcoming votes in your area
Description: Details about upcoming elections in the United Kingdom.
Author: dinosaursrarr
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

POSTCODE_API = "https://api.electoralcommission.org.uk/api/v1/postcode/%s/"
ADDRESS_API = "https://api.electoralcommission.org.uk/api/v1/address/%s/"

def api_key():
    return secret.decrypt("AV6+xWcEp1fWUXHSTLQxcsBgT05CObA/A0mymKkVv7XBM2J8LEjJyN91WINoUM3a+cVOne+b50W8lpRc/fd5lCxrXtojn4hzYrPoIf9DyY+GRn9SUhoy3vTZK8iAc5P+hrg89sHg2rfPASYGHg2KGuhNnN4hDLIzgwvnoDWT16LZQ59QuK3GEko6JSCe3g==") or ""

FONT = "tom-thumb"
BLUE = "#0000ff"
GREEN = "#00ff00"
ORANGE = "#ff8000"
YELLOW = "#ffff00"
WHITE = "#ffffff"

def render_header():
    return render.Box(
        color = BLUE,
        height = 6,
        child = render.WrappedText(
            "Remember to vote",
            width = 64,
            font = FONT,
            color = WHITE,
            align = "center",
        ),
    )

def render_date(date):
    result = date.format("Mon 2 Jan 2006")
    colour = WHITE

    today = time.now().in_location("Europe/London")
    if (today.year == date.year and today.month == date.month and today.day == date.day):
        result = "TODAY"
        colour = GREEN
    elif (date - today) < (24 * time.hour):
        result = "TOMORROW"
        colour = ORANGE
    elif (date - today) < (6 * 24 * time.hour):
        result = "On " + date.format("Monday")
        colour = YELLOW

    return render.WrappedText(
        result,
        width = 64,
        height = 7,
        align = "center",
        font = FONT,
        color = colour,
    )

def render_ballot(date, ballot):
    return render.Column(
        children = [
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render_date(date),
            ),
            render.WrappedText(
                ballot["ballot_title"],
                width = 64,
                align = "center",
                font = FONT,
            ),
        ],
    )

def render_error(message):
    return render.Root(
        child = render.Column(
            children = [
                render_header(),
                render.Padding(
                    pad = (1, 3, 0, 0),
                    child = render.WrappedText(
                        message,
                        width = 62,
                        align = "center",
                        font = FONT,
                    ),
                ),
            ],
        ),
    )

def fetch_slug(slug):
    resp = http.get(
        url = ADDRESS_API % slug.upper().replace(" ", ""),
        params = {
            "token": api_key(),
        },
        ttl_seconds = 86400,  # once a day is plenty
    )
    if resp.status_code != 200:
        print("Slug:", slug, "Status code:", resp.status_code)
        return None
    return resp.json()

def fetch_postcode(postcode):
    resp = http.get(
        url = POSTCODE_API % postcode.upper().replace(" ", ""),
        params = {
            "token": api_key(),
        },
        ttl_seconds = 86400,  # once a day is plenty
    )
    if resp.status_code != 200:
        print("Postcode:", postcode, "Status code:", resp.status_code)
        return None
    return resp.json()

# https://api.electoralcommission.org.uk/docs
def main(config):
    slug = config.str("address")
    if slug:
        json = fetch_slug(slug)
    else:
        postcode = config.str("postcode", "SW1A 1AA")
        json = fetch_postcode(postcode)

    if not json:
        return render_error("Could not fetch data from API")

    if "error" in json:
        print(json["error"])
        return render_error("Could not fetch data for post code %s" % config.str("postcode"))

    elections = []
    for d in json["dates"]:
        date = time.parse_time(d["date"], "2006-01-02", "Europe/London")
        for ballot in d["ballots"]:
            elections.append(render_ballot(date, ballot))

    # Only display when there is an upcoming election
    if not elections:
        if config.bool("hide_empty"):
            return []
        elections = [
            render.Padding(
                pad = (0, 3, 0, 0),
                child = render.WrappedText(
                    "No upcoming elections in your area",
                    width = 64,
                    align = "center",
                    font = FONT,
                ),
            ),
        ]

    return render.Root(
        delay = 2000,
        child = render.Column(
            children = [
                render_header(),
                render.Animation(
                    children = elections,
                ),
            ],
        ),
    )

# Some postcodes are split between different electoral areas. If so, then
# results for the postcode will contain an address picker. The user will
# need to make an additional selection and the main app will call a different
# end point.
def check_address_handler(postcode):
    json = fetch_postcode(postcode)
    if not json:
        return []
    if not json["address_picker"]:
        return []
    addresses = [
        schema.Option(
            display = address["address"],
            value = address["slug"],
        )
        for address in json["addresses"]
    ]
    return [
        schema.Dropdown(
            id = "address",
            name = "Address",
            desc = "The address where you are registered to vote, as your postcode is split between electoral areas.",
            icon = "houseFlag",
            options = addresses,
            default = addresses[0].value,
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "hide_empty",
                name = "Hide when empty?",
                desc = "Only show app when there is an election in your area.",
                icon = "eyeSlash",
                default = True,
            ),
            schema.Text(
                id = "postcode",
                name = "Postcode",
                desc = "The postcode where you are registered to vote. Case insensitive and space optional.",
                icon = "house",
                default = "SW1A 1AA",
            ),
            schema.Generated(
                id = "address",
                source = "postcode",
                handler = check_address_handler,
            ),
        ],
    )
