"""
Applet: HackneyBindicator
Summary: Upcoming refuse collections
Description: Tells you what bins to put out for people who live in the London Borough of Hackney.
Author: dinosaursrarr
"""

load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://hackney-bindicator.fly.dev"
ADDRESS_PATH = "/addresses/"
COLLECTION_PATH = "/property/"

DATE = "date"
BINS = "Bins"
BORDER = "border"
FILL = "fill"
TYPE = "Type"
DISPLAY = "display"

TOWN_HALL_POSTCODE = "E8 1EA"
SPURSTOWE_ARMS = "5f898d4790478c0067f8bb7c"

# https://design-system.hackney.gov.uk/developing/colours/
HACKNEY_GREEN = "#00664f"
WHITE = "#ffffff"
ERROR_RED = "#be3a34"
BLUE = "#0085ca"
BLACK = "#0b0c0c"
BORDER_GREY = "#bfc1c3"
LIGHT_GREEN = "#00b341"
BEIGE = "#f8e08e"
MAX_WIDTH = 16

SPACE = re.compile("\\s+")
POSTCODE = re.compile("^(?P<outer>[A-Z]{1,2}[0-9][A-Z0-9]?) ?(?P<inner>[0-9][A-Z]{2})$")
HACKNEY_POSTCODES = set(["E1", "E2", "E5", "E8", "E9", "E10", "E15", "E20", "N1", "N4", "N5", "N16"])

BIN_TYPES = {
    "food": {
        BORDER: BLUE,
        FILL: BLUE,
        DISPLAY: ["Food", "Food", "Food", "Fod"],
    },
    "recycling": {
        BORDER: LIGHT_GREEN,
        FILL: LIGHT_GREEN,
        DISPLAY: ["Recycling", "Recycle", "Recy", "Rec"],
    },
    "garden": {
        BORDER: BEIGE,
        FILL: BEIGE,
        DISPLAY: ["Garden", "Garden", "Gard", "Gdn"],
    },
    "rubbish": {
        BORDER: BORDER_GREY,
        FILL: BLACK,
        DISPLAY: ["Trash", "Trash", "Trsh", "Tsh"],
    },
}

def get_next_collection(property_id):
    resp = http.get(BASE_URL + COLLECTION_PATH + property_id)
    if resp.status_code != 200:
        print("Status code {} when fetching collections".format(resp.status_code))
        return None

    collections = {}
    for bin in resp.json()[BINS]:
        date = time.parse_time(bin["NextCollection"])
        if date not in collections:
            collections[date] = []
        collections[date].append(bin[TYPE])
    if not collections:
        print("No collections found")
        return None
    first_date = sorted(collections.keys())[0]
    collected = sorted(list(set(collections[first_date])))

    return {
        DATE: first_date,
        BINS: collected,
    }

def render_error(error):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = HACKNEY_GREEN,
                    child = render.Column(
                        children = [
                            render.Marquee(
                                width = 62,
                                align = "center",
                                child = render.Text(
                                    content = "Hackney bins",
                                    color = WHITE,
                                ),
                            ),
                        ],
                    ),
                ),
                render.Box(height = 1, width = 1),  # Spacing between box and text
                render.WrappedText(
                    width = 64,
                    height = 23,
                    align = "center",
                    content = error,
                    color = ERROR_RED,
                ),
            ],
        ),
    )

def render_bin(bin, width, count):
    bin_type = BIN_TYPES[bin]
    box_size = min(MAX_WIDTH, width)
    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        expanded = True,
        children = [
            render.Box(
                width = box_size,
                height = box_size,
                color = bin_type[BORDER],
                padding = 1,
                child = render.Box(
                    width = box_size - 2,
                    height = box_size - 2,
                    color = bin_type[FILL],
                ),
            ),
            render.WrappedText(
                bin_type[DISPLAY][count],
                width = width,
                align = "center",
                font = "tom-thumb",
            ),
        ],
    )

def render_bins(bins):
    width = 58 // len(bins)
    return render.Row(
        children = [render_bin(bin, width, len(bins) - 1) for bin in bins],
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
    )

def render_collection(date, bins):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = HACKNEY_GREEN,
                    child = render.Column(
                        children = [
                            render.Marquee(
                                width = 62,
                                align = "center",
                                child = render.Text(
                                    content = date.format("Mon 2 Jan"),
                                    color = WHITE,
                                ),
                            ),
                        ],
                    ),
                ),
                render.Box(height = 1, width = 1),  # Spacing between box and text
                render_bins(bins),
            ],
        ),
    )

def main(config):
    property_id = config.get("address", SPURSTOWE_ARMS)
    collection = get_next_collection(property_id)
    if not collection:
        return render_error("Could not get collection")
    return render_collection(collection[DATE], collection[BINS])

def get_addresses(postcode):
    tidy = SPACE.sub(" ", postcode.strip()).upper()
    match = POSTCODE.match(tidy)
    if not match:
        print("Not a valid postcode: ", postcode)
        return []
    outer = match[0][1]
    inner = match[0][2]
    if outer not in HACKNEY_POSTCODES:
        print("Postcode area not in Hackney: ", outer)
        return []
    canonical = "{} {}".format(outer, inner)

    resp = http.get(BASE_URL + ADDRESS_PATH + canonical)
    if resp.status_code != 200:
        print("Status code {} looking up addresses".format(resp.status_code))
        return []
    options = [
        schema.Option(
            display = item["Name"],
            value = item["Id"],
        )
        for item in resp.json()
    ]
    return [
        schema.Dropdown(
            id = "address",
            name = "Address",
            desc = "Property to check collections for",
            icon = "house",
            default = options[0].value,
            options = options,
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "postcode",
                name = "postcode",
                desc = "Postcode to look up address",
                icon = "map",
            ),
            schema.Generated(
                id = "address",
                source = "postcode",
                handler = get_addresses,
            ),
        ],
    )
