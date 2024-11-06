"""
Applet: Congress Watch
Summary: Updates from U.S. Congress
Description: Displays updates from U.S. Congress.
Author: Robert Ison
"""

load("cache.star", "cache")  #Caching
load("encoding/base64.star", "base64")  #Encoding Images
load("encoding/json.star", "json")  #JSON Data from congress.gov API site
load("http.star", "http")  #HTTP Client
load("render.star", "render")  #Render the display for Tidbyt
load("schema.star", "schema")  #Keep Track of Settings
load("secret.star", "secret")  #Encrypt the API Key
load("time.star", "time")  #Ensure Timely display of congressional actions

API_KEY = ""  #Remove before committing
API_KEY_ENCRYPTED = "AV6+xWcEONGMeP4KdGqCO9aQ5vhdBFz4VLyxinpFW+SIsoiYmqcCR33CU6kNEc01NR/ywxYUNJl0CeNkNTZ/lT8rDEjKlENdTMU8/A8YsYjnrUhnq6QLIeO6BRVtGRTwcILtm0fPZrEWId8Ta4cETXU09Ib6LO8AYeHorr0mvi2wNiNn776WxcF+UIkBXg=="  #
CONGRESS_API_URL = "https://api.congress.gov/v3/"
CONGRESS_SESSION_LENGTH_IN_DAYS = 720  #730, but we'll shorten it some to make sure we don't miss
CONGRESS_BILL_TTL = 12 * 60 * 60  #12 hours * 60 mins/hour * 60 seconds/min
MAX_ITEMS = 50
SAMPLE_CONGRESS_BODY = """{"congress": {"endYear": "2024", "name": "118th Congress", "number": 118, "sessions": [{"chamber": "House of Representatives", "endDate": "2024-01-03", "number": 1, "startDate": "2023-01-03", "type": "R"}, {"chamber": "Senate", "endDate": "2024-01-03", "number": 1, "startDate": "2023-01-03", "type": "R"}, {"chamber": "Senate", "number": 2, "startDate": "2024-01-03", "type": "R"}, {"chamber": "House of Representatives", "number": 2, "startDate": "2024-01-03", "type": "R"}], "startYear": "2023", "updateDate": "2023-01-03T17:43:32Z", "url": "https://api.congress.gov/v3/congress/118?format=json"}, "request": {"contentType": "application/json", "format": "json"}}"""
SAMPLE_CONGRESS_DATA = """{"bills":[{"congress":118,"latestAction":{"actionDate":"2024-09-10","text":"TEST DATA: Referred to the House Committee on Ways and Means."},"number":"9518","originChamber":"House","originChamberCode":"H","title":"TEST DATA: BRAVE Act of 2024","type":"HR","updateDate":"2024-11-05","updateDateIncludingText":"2024-11-05","url":"https://api.congress.gov/v3/bill/118/hr/9518?format=json"},{"congress":118,"latestAction":{"actionDate":"2024-09-10","text":"TEST DATA: Referred to the House Committee on Ways and Means."},"number":"9522","originChamber":"House","originChamberCode":"H","title":"TEST DATA: To amend the Internal Revenue Code of 1986 to modify the railroad track maintenance credit.","type":"HR","updateDate":"2024-11-05","updateDateIncludingText":"2024-11-05","url":"https://api.congress.gov/v3/bill/118/hr/9522?format=json"}],"pagination":{"count":88,"next":"https://api.congress.gov/v3/bill/118?sort=updateDate desc&fromDateTime=2024-11-04T00:00:00Z&offset=50&limit=50&format=json"},"request":{"congress":"118","contentType":"application/json","format":"json"}}"""
CONGRESS_ICON = base64.decode("""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""")

period_options = [
    schema.Option(
        display = "Today",
        value = "1",
    ),
    schema.Option(
        display = "This Week",
        value = "7",
    ),
    schema.Option(
        display = "This Month",
        value = "31",
    ),
    schema.Option(
        display = "Last 90 Days",
        value = "90",
    ),
]

source = [
    schema.Option(
        display = "House of Representatives",
        value = "House",
    ),
    schema.Option(
        display = "Senate",
        value = "Senate",
    ),
    schema.Option(
        display = "House and Senate",
        value = "Both",
    ),
]

scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def main(config):
    api_key = secret.decrypt(API_KEY_ENCRYPTED) or API_KEY

    #initialize
    senate_start = None
    house_start = None
    congress_number = ""

    if api_key == "":
        #test environment or app preview
        congress_session_body = json.decode(SAMPLE_CONGRESS_BODY)
        congress_data = json.decode(SAMPLE_CONGRESS_DATA)

        #Congress Session Info
        congress_number = congress_session_body["congress"]["number"]
    else:
        #Get the current congress
        congress_session_url = "%scongress/current?API_KEY=%s&format=json" % (CONGRESS_API_URL, api_key)
        congress_session_body = cache.get(congress_session_url)

        if congress_session_body == None:
            congress_session_body = http.get(url = congress_session_url).body()

        congress_session_body = json.decode(congress_session_body)

        if congress_session_body == None:
            #Error getting data
            fail("Error: Failed to get data from cache or http get calling")

        #Congress Session Info
        congress_number = congress_session_body["congress"]["number"]

        for i in range(0, len(congress_session_body["congress"]["sessions"])):
            current_start_date = time.parse_time(congress_session_body["congress"]["sessions"][i]["startDate"], format = "2006-01-02")

            if congress_session_body["congress"]["sessions"][i]["chamber"] == "House of Representatives":
                if house_start == None or house_start < current_start_date:
                    house_start = current_start_date
            elif congress_session_body["congress"]["sessions"][i]["chamber"] == "Senate":
                if senate_start == None or senate_start < current_start_date:
                    senate_start = current_start_date

        session_duration_days = (time.now() - senate_start).hours / 24

        cache_ttl = int((CONGRESS_SESSION_LENGTH_IN_DAYS - session_duration_days) * 60 * 60 * 24)

        #let's cache this for what should be the rest of the session
        cache.set(congress_session_url, json.encode(congress_session_body), ttl_seconds = cache_ttl)

        #Get Bill Data for past X days where X = the most days we search based on period options
        bill_data_from_date = (time.now() - time.parse_duration("%sh" % config.get("period", period_options[-1].value) * 24))
        congress_bill_url = "%sbill/%s?limit=%s&sort=updateDate+desc&api_key=%s&format=json&fromDateTime=%sT00:00:00Z" % (CONGRESS_API_URL, congress_number, MAX_ITEMS, api_key, bill_data_from_date.format("2006-01-02"))

        congress_data = json.decode(get_cachable_data(congress_bill_url, CONGRESS_BILL_TTL))

    #We have either live or test data, now display it.

    filtered_congress_data = filter_bills(congress_data, config.get("period", period_options[0].value), config.get("source", source[-1].value))

    number_filtered_items = len(filtered_congress_data)
    if (number_filtered_items == 0):
        return []

    #let's diplay a random bill from the filtered list
    random_number = randomize(0, number_filtered_items)

    row1 = filtered_congress_data[random_number]["originChamber"]
    row2 = "%s%s %s" % (filtered_congress_data[random_number]["type"], filtered_congress_data[random_number]["number"], filtered_congress_data[random_number]["title"])
    row3 = (filtered_congress_data[random_number]["latestAction"]["text"])

    #Fonts: 10x20 5x8 6x10-rounded 6x10 6x13 CG-pixel-3x5-mono CG-pixel-4x5-mono Dina_r400 tb-8 tom-thumb

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Marquee(
                            width = 47,
                            height = 8,
                            child = add_padding_to_child_element(render.Text(row1, font = "6x10", color = "#fff"), 1),
                        ),
                        render.Image(CONGRESS_ICON),
                        render.Box(width = 1, height = 16, color = "#000"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 15,
                            child = render.Text(row2, font = "5x8", color = "#ff0"),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = len(row2) * 5,
                            child = render.Text(row3, font = "5x8", color = "#f4a306"),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def filter_bills(data, period, source):
    filtered_data = [
        bill
        for bill in data["bills"]
        if (source == "Senate" and bill["originChamberCode"] == "S") or (source == "Both") or (source == "House" and bill["originChamberCode"] == "H")
        if ((time.now() - time.parse_time(bill["updateDate"], format = "2006-01-02")).hours / 24 < int(period))
    ]

    return filtered_data

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

def randomize(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max - min) + min)

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "period",
                name = "Period",
                desc = "Display Items",
                icon = "calendar",
                options = period_options,
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "source",
                name = "Source",
                desc = "Chamber",
                icon = "landmarkDome",
                options = source,
                default = source[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
