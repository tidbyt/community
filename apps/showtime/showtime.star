"""
Applet: ShowTime
Summary: Displays shows in your area
Description: Displays shows coming to your area.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

SAMPLE_DATA = """
{"events": {"11GOvO49aIkbv2": {"title": "Keith James - Unicef Syrian Children Appeal. the Music of Yusuf Cat ST", "image_url": "https://s1.ticketm.net/dam/c/779/d4bc7e11-1b50-4aa4-a2be-0a21569f5779_106531_EVENT_DETAIL_PAGE_16_9.jpg", "venue": "Backstage at The Green Hotel", "price_range": "", "display_date": "Thu 3 Oct 2024 at 8:00 PM", "event_time_utc": 9999999999}, "17GOvOG62AW0omu": {"title": "Soft Launch", "image_url": "https://s1.ticketm.net/dam/a/e22/d07aa5cc-916f-4fe0-b12c-a2bfc384be22_RECOMENDATION_16_9.jpg", "venue": "Attic Bar  - Glasgow Garage", "price_range": "", "display_date": "Wed 2 Oct 2024 at 7:00 PM", "event_time_utc": 9999999999}, "17GOvOG65SDMoLM": {"title": "Youngr", "image_url": "https://s1.ticketm.net/dam/a/0be/c9064803-7653-433d-9201-a23fe0fbf0be_RETINA_LANDSCAPE_16_9.jpg", "venue": "Stereo", "price_range": "", "display_date": "Thu 3 Oct 2024 at 7:00 PM", "event_time_utc": 9999999999}, "17GOvOG6CKwQwFr": {"title": "Glasgow Americana: Karen Jonas", "image_url": "https://s1.ticketm.net/dam/a/30a/421ef159-6394-4d6e-a3cd-6126075f330a_EVENT_DETAIL_PAGE_16_9.jpg", "venue": "Rum Shack", "price_range": "", "display_date": "Thu 3 Oct 2024 at 8:00 PM", "event_time_utc": 9999999999}, "17GOvOG6CKwh3Fl": {"title": "Glasgow Americana: Good Guy Hank Plus the Black Denims", "image_url": "https://s1.ticketm.net/dam/c/779/d4bc7e11-1b50-4aa4-a2be-0a21569f5779_106531_TABLET_LANDSCAPE_LARGE_16_9.jpg", "venue": "Glad Cafe", "price_range": "", "display_date": "Wed 2 Oct 2024 at 8:00 PM", "event_time_utc": 9999999999}, "17GOvOG6CNsIdUs": {"title": "Ben Poole", "image_url": "https://s1.ticketm.net/dam/c/fbc/b293c0ad-c904-4215-bc59-8d7f2414dfbc_106141_RETINA_LANDSCAPE_16_9.jpg", "venue": "Backstage at The Green Hotel", "price_range": "", "display_date": "Wed 2 Oct 2024 at 8:00 PM", "event_time_utc": 9999999999}, "17GOvOG6CRwJNEd": {"title": "A Play, a Pie & a Pint - Anna/Anastasia", "image_url": "https://s1.ticketm.net/dam/c/07d/fda8c807-42eb-4b81-9f16-f3a8367e107d_106371_TABLET_LANDSCAPE_LARGE_16_9.jpg", "venue": "Oran Mor", "price_range": "", "display_date": "Thu 3 Oct 2024 at 1:00 PM", "event_time_utc": 9999999999}, "17GOvOG6CRwPSN-": {"title": "A Play, a Pie & a Pint - Anna/Anastasia", "image_url": "https://s1.ticketm.net/dam/c/07d/fda8c807-42eb-4b81-9f16-f3a8367e107d_106371_TABLET_LANDSCAPE_LARGE_16_9.jpg", "venue": "Oran Mor", "price_range": "", "display_date": "Wed 2 Oct 2024 at 1:00 PM", "event_time_utc": 1727870400}, "17uOvOG62DxvvSi": {"title": "Stevie Bill - I Was A Platinum Blonde Tour", "image_url": "https://s1.ticketm.net/dam/a/572/e484d7a1-3159-4a9a-b3e6-c8435579b572_RETINA_PORTRAIT_16_9.jpg", "venue": "The Poetry Club SWG3", "price_range": "Ticket prices: £12.00", "display_date": "Thu 3 Oct 2024 at 7:00 PM", "event_time_utc": 1727978400}, "1AUZkv4GkeNG-gy": {"title": "Apocalyptica: Plays Metallica Vol. 2 Tour 2024", "image_url": "https://s1.ticketm.net/dam/a/681/f38d2463-65b2-455a-a3b3-66212caf9681_RETINA_PORTRAIT_16_9.jpg", "venue": "Galvanizers SWG3", "price_range": "Ticket prices: £29.50", "display_date": "Thu 3 Oct 2024 at 7:00 PM", "event_time_utc": 1727978400}, "1AdFZbdGkTGKsz0": {"title": "Tom Robinson", "image_url": "https://s1.ticketm.net/dam/a/460/e2f5c2fb-6f59-4e55-91f2-7bd785c90460_1076831_RETINA_PORTRAIT_16_9.jpg", "venue": "King Tuts Wah Wah Hut", "price_range": "", "display_date": "Thu 3 Oct 2024 at 7:30 PM", "event_time_utc": 1727980200}, "1AdbZb7GkSkx0vU": {"title": "Michael Aldag", "image_url": "https://s1.ticketm.net/dam/a/a70/d383cb3a-47b8-4a00-beb7-570f739aaa70_RETINA_PORTRAIT_16_9.jpg", "venue": "Stereo", "price_range": "Ticket prices: £15.00", "display_date": "Wed 2 Oct 2024 at 7:00 PM", "event_time_utc": 1727892000}, "1AdbZbFGkS_hNP6": {"title": "Ghost the Musical", "image_url": "https://s1.ticketm.net/dam/a/a82/5c6010ea-ca9b-4f42-afd4-76825f8eba82_SOURCE", "venue": "Alhambra Theatre", "price_range": "Ticket prices: £21.00", "display_date": "Wed 2 Oct 2024 at 7:30 PM", "event_time_utc": 1727893800}, "1AdbZbFGkS_hSPo": {"title": "Ghost the Musical", "image_url": "https://s1.ticketm.net/dam/a/a82/5c6010ea-ca9b-4f42-afd4-76825f8eba82_SOURCE", "venue": "Alhambra Theatre", "price_range": "Ticket prices: £21.00", "display_date": "Thu 3 Oct 2024 at 7:30 PM", "event_time_utc": 1727980200}, "1AdfZbaGkMvZNCF": {"title": "Rhys Nicholson: Huge Big Party Congratulations!", "image_url": "https://s1.ticketm.net/dam/a/7be/cb9a17ce-247a-4ca2-a98b-89aec200e7be_RETINA_LANDSCAPE_16_9.jpg", "venue": "The Stand Comedy Club", "price_range": "Ticket prices: £19.00", "display_date": "Wed 2 Oct 2024 at 8:30 PM", "event_time_utc": 1727897400}, "1AwZk7aGkdEldpo": {"title": "Glasgow Americana Festival Pass", "image_url": "https://s1.ticketm.net/dam/c/fbc/b293c0ad-c904-4215-bc59-8d7f2414dfbc_106141_RETINA_LANDSCAPE_16_9.jpg", "venue": "Glasgow Americana Festival", "price_range": "", "display_date": "Wed 2 Oct 2024 at 12:00 PM", "event_time_utc": 1727866800}, "1AwZkeAGkdb4kFv": {"title": "Duff McKagan + James and the Cold Gun", "image_url": "https://s1.ticketm.net/dam/a/1b4/e3b610ff-e873-46ed-8b5e-ee573e2301b4_RETINA_PORTRAIT_16_9.jpg", "venue": "Glasgow Garage", "price_range": "", "display_date": "Wed 2 Oct 2024 at 7:00 PM", "event_time_utc": 1727892000}, "1AwZkvyGkd8vP8J": {"title": "Cast", "image_url": "https://s1.ticketm.net/dam/c/fbc/b293c0ad-c904-4215-bc59-8d7f2414dfbc_106141_RETINA_LANDSCAPE_16_9.jpg", "venue": "La Belle Angèle", "price_range": "", "display_date": "Thu 3 Oct 2024 at 7:00 PM", "event_time_utc": 1727978400}, "G5dbZ9Sl5fdeg": {"title": "Les Miserables: The Arena Spectacular", "image_url": "https://s1.ticketm.net/dam/a/526/6539e373-394a-43a2-a543-cf2b45546526_RETINA_PORTRAIT_16_9.jpg", "venue": "OVO Hydro", "price_range": "Ticket prices: £30.00 to £120.00", "display_date": "Thu 3 Oct 2024 at 7:30 PM", "event_time_utc": 1727980200}, "G5dbZ9_d1sI87": {"title": "Ed Byrne: Tragedy Plus Time", "image_url": "https://s1.ticketm.net/dam/a/5c1/916301db-6ec2-43fa-95b1-636c9dde05c1_TABLET_LANDSCAPE_LARGE_16_9.jpg", "venue": "Aberdeen Music Hall", "price_range": "Ticket prices: £29.00", "display_date": "Wed 2 Oct 2024 at 7:30 PM", "event_time_utc": 9999999999}}, "Date_Downloaded": 9999999999}
"""
CONSUMER_KEY = ""  #Enter the key here while testing. Remove before publishing
CONSUMER_KEY_ENCRYPTED = "AV6+xWcEsMnO4WlomRWCWtAovi3S6VXNIOxmBQMbvUpdGWMBpdy2l2sEN13kw388sHElyrajBp1x9vX5uAl4sSOPISYneGtlZnsikHQm62nPrsr4pi+gHgtljQZuaANLelXEFJUrOcLZ4cW7u4mkGyTC6lvqwyiLiOQBvvNrxkRzoh7PqbA="
TICKET_MASTER_URL = "https://app.ticketmaster.com/discovery/v2/events.json"
NUMBER_OF_EVENTS_TO_DOWNLOAD = "30"
EVENT_DATA_CACHE_NAME_PREFIX = "ShowTimesData"
EVENT_DATA_CACHE_TIME_SECONDS = 12 * 60 * 60  #12 Hours
JSON_PROPERTY_DATA_DOWNLOADED_DATE = "Date_Downloaded"
FONT = "5x8"
MARKETS = {
    "USA": [
        {"ID": 1, "Market": "Birmingham & More"},
        {"ID": 2, "Market": "Charlotte"},
        {"ID": 3, "Market": "Chicagoland & Northern IL"},
        {"ID": 4, "Market": "Cincinnati & Dayton"},
        {"ID": 5, "Market": "Dallas - Fort Worth & More"},
        {"ID": 6, "Market": "Denver & More"},
        {"ID": 7, "Market": "Detroit, Toledo & More"},
        {"ID": 8, "Market": "El Paso & New Mexico"},
        {"ID": 9, "Market": "Grand Rapids & More"},
        {"ID": 10, "Market": "Greater Atlanta Area"},
        {"ID": 11, "Market": "Greater Boston Area"},
        {"ID": 12, "Market": "Cleveland, Youngstown & More"},
        {"ID": 13, "Market": "Greater Columbus Area"},
        {"ID": 14, "Market": "Greater Las Vegas Area"},
        {"ID": 15, "Market": "Greater Miami Area"},
        {"ID": 16, "Market": "Minneapolis/St. Paul & More"},
        {"ID": 17, "Market": "Greater Orlando Area"},
        {"ID": 18, "Market": "Greater Philadelphia Area"},
        {"ID": 19, "Market": "Greater Pittsburgh Area"},
        {"ID": 20, "Market": "Greater San Diego Area"},
        {"ID": 21, "Market": "Greater Tampa Area"},
        {"ID": 22, "Market": "Houston & More"},
        {"ID": 23, "Market": "Indianapolis & More"},
        {"ID": 24, "Market": "Iowa"},
        {"ID": 25, "Market": "Jacksonville & More"},
        {"ID": 26, "Market": "Kansas City & More"},
        {"ID": 27, "Market": "Greater Los Angeles Area"},
        {"ID": 28, "Market": "Louisville & Lexington"},
        {"ID": 29, "Market": "Memphis, Little Rock & More"},
        {"ID": 30, "Market": "Milwaukee & WI"},
        {"ID": 31, "Market": "Nashville, Knoxville & More"},
        {"ID": 33, "Market": "New England"},
        {"ID": 34, "Market": "New Orleans & More"},
        {"ID": 35, "Market": "New York/Tri-State Area"},
        {"ID": 36, "Market": "Phoenix & Tucson"},
        {"ID": 37, "Market": "Portland & More"},
        {"ID": 38, "Market": "Raleigh & Durham"},
        {"ID": 39, "Market": "Saint Louis & More"},
        {"ID": 40, "Market": "San Antonio & Austin"},
        {"ID": 41, "Market": "N. California/N. Nevada"},
        {"ID": 42, "Market": "Greater Seattle Area"},
        {"ID": 43, "Market": "North & South Dakota"},
        {"ID": 44, "Market": "Upstate New York"},
        {"ID": 45, "Market": "Utah & Montana"},
        {"ID": 46, "Market": "Virginia"},
        {"ID": 47, "Market": "Washington, DC and Maryland"},
        {"ID": 48, "Market": "West Virginia"},
        {"ID": 49, "Market": "Hawaii"},
        {"ID": 50, "Market": "Alaska"},
        {"ID": 52, "Market": "Nebraska"},
        {"ID": 53, "Market": "Springfield"},
        {"ID": 54, "Market": "Central Illinois"},
        {"ID": 55, "Market": "Northern New Jersey"},
        {"ID": 121, "Market": "South Carolina"},
        {"ID": 122, "Market": "South Texas"},
        {"ID": 123, "Market": "Beaumont"},
        {"ID": 124, "Market": "Connecticut"},
        {"ID": 125, "Market": "Oklahoma"},
    ],
    "Canada": [
        {"ID": 102, "Market": "Toronto, Hamilton & Area"},
        {"ID": 103, "Market": "Ottawa & Eastern Ontario"},
        {"ID": 106, "Market": "Manitoba"},
        {"ID": 107, "Market": "Edmonton & Northern Alberta"},
        {"ID": 108, "Market": "Calgary & Southern Alberta"},
        {"ID": 110, "Market": "B.C. Interior"},
        {"ID": 111, "Market": "Vancouver & Area"},
        {"ID": 112, "Market": "Saskatchewan"},
        {"ID": 120, "Market": "Montréal & Area"},
    ],
    "Europe": [
        {"ID": 202, "Market": "London (UK)"},
        {"ID": 203, "Market": "South (UK)"},
        {"ID": 204, "Market": "Midlands and Central (UK)"},
        {"ID": 205, "Market": "Wales and North West (UK)"},
        {"ID": 206, "Market": "North and North East (UK)"},
        {"ID": 207, "Market": "Scotland"},
        {"ID": 208, "Market": "Ireland"},
        {"ID": 209, "Market": "Northern Ireland"},
        {"ID": 210, "Market": "Germany"},
        {"ID": 211, "Market": "Netherlands"},
        {"ID": 500, "Market": "Sweden"},
        {"ID": 501, "Market": "Spain"},
        {"ID": 502, "Market": "Barcelona (Spain)"},
        {"ID": 503, "Market": "Madrid (Spain)"},
        {"ID": 600, "Market": "Turkey"},
    ],
    "Australia and New Zealand": [
        {"ID": 302, "Market": "New South Wales/Australian Capital Territory"},
        {"ID": 303, "Market": "Queensland"},
        {"ID": 304, "Market": "Western Australia"},
        {"ID": 305, "Market": "Victoria/Tasmania"},
        {"ID": 306, "Market": "Western Australia"},
        {"ID": 351, "Market": "North Island"},
        {"ID": 352, "Market": "South Island"},
    ],
    "Mexico": [
        {"ID": 402, "Market": "Mexico City and Metropolitan Area"},
        {"ID": 403, "Market": "Monterrey"},
        {"ID": 404, "Market": "Guadalajara"},
    ],
}

def main(config):
    #Get the market id to know which market to download events for, and to create a unique cache
    market_id = config.get("mymarket")
    event_data_cache_name = "%s_%s" % (EVENT_DATA_CACHE_NAME_PREFIX, market_id)
    consumer_key = secret.decrypt(CONSUMER_KEY_ENCRYPTED) or CONSUMER_KEY
    use_sample_data = consumer_key == None or consumer_key == ""

    if use_sample_data:
        #Note: If I set SAMPLE_DATA as actual json, it'll be immutable. Setting it as a string and using json.decode returns a mutable version
        events_data = json.decode(SAMPLE_DATA)
    else:
        #is there event data cached?
        events_data = cache.get(event_data_cache_name)
        if events_data != None:
            events_data = json.decode(events_data)

    #If the cached data is too old, we can try to refresh it, and fall back to it, if that fails
    refresh_data = False
    if use_sample_data == False and events_data != None:
        if events_data.get(JSON_PROPERTY_DATA_DOWNLOADED_DATE):
            if (int(events_data[JSON_PROPERTY_DATA_DOWNLOADED_DATE]) + EVENT_DATA_CACHE_TIME_SECONDS > int(time.now().unix)):
                print(events_data[JSON_PROPERTY_DATA_DOWNLOADED_DATE])
                refresh_data = True

    #if no cache (or sample data), or its deemed too old, we'll go to the server to get it
    if refresh_data == True or events_data == None:
        print("Getting new data from source")
        events_data = create_event_data(market_id, consumer_key)
        cache.set(event_data_cache_name, json.encode(events_data), ttl_seconds = EVENT_DATA_CACHE_TIME_SECONDS)

    # Let's pick a random future event to display this time round
    event = get_random_future_event(events_data)

    if event == None:
        return []

    display_items = []

    # do we display the event image?
    event_image_url = event["image_url"]
    if config.bool("artwork", True) and len(event_image_url) > 0:
        artwork = http.get(event_image_url, ttl_seconds = EVENT_DATA_CACHE_TIME_SECONDS).body()
        artwork_image = render.Image(src = artwork, width = 64, height = 32)
        display_items.append(artwork_image)

    # do we append black overlay?
    if config.bool("cc", False):
        black_box = render.Box(width = 64, height = 7, color = "#000000")
        display_items.append(black_box)
        black_box = add_padding_to_child_element(black_box, 0, 25)
        display_items.append(black_box)

    # append title
    display_items.append(render.Marquee(
        width = 64,
        offset_start = 10,
        child = render.Text(content = event["title"], color = config.get("color_1", "#ffffff"), font = FONT),
    ))

    # append description
    description = event["display_date"] + " " + event["price_range"]
    description = render.Marquee(
        width = 64,
        offset_start = 40,
        child = render.Text(content = description, color = config.get("color_2", "#ffffff"), font = FONT),
    )

    description = add_padding_to_child_element(description, 0, 24)
    display_items.append(description)

    return render.Root(
        render.Stack(
            children = display_items,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

def get_random_future_event(events_data):
    events = events_data["events"]
    valid_event_ids = []
    for i in list(events.keys()):
        if (events[i].get("event_time_utc")):
            if int(events[i]["event_time_utc"]) < int(time.now().unix):
                events.pop(i)
            else:
                valid_event_ids.append(i)
        else:
            events.pop(i)

    number_of_events = len(events)
    if number_of_events > 0:
        random_number = random.number(0, max(0, number_of_events - 1))

        #print("Random Number: %s" % random_number)
        return events[valid_event_ids[random_number]]
    else:
        return None

def create_event_data(market_id, consumer_key):
    # set up the dataset we'll cache and use for displaying
    events_data = {
        "events": {},
        JSON_PROPERTY_DATA_DOWNLOADED_DATE: time.now().unix,
    }

    rep = http.get(
        TICKET_MASTER_URL,
        params = {"apikey": consumer_key, "size": NUMBER_OF_EVENTS_TO_DOWNLOAD, "marketId": market_id, "includeTest": "no", "keyword": ""},
    )

    if rep.status_code != 200:
        fail("Failed to fetch data with status code:", rep.status_code)
    else:
        json_data = rep.json()

        if json_data.get("_embedded"):
            events = json_data["_embedded"]["events"]
            event_count = len(events)

            for i in range(event_count):
                image_url = ""
                for j in range(len(events[i]["images"])):
                    if events[i]["images"][j].get("ratio"):
                        if events[i]["images"][j]["ratio"] == "16_9":
                            image_url = events[i]["images"][j]["url"]
                            break

                venue = ""
                if events[i]["_embedded"].get("venues"):
                    venue = events[i]["_embedded"]["venues"][0]["name"]

                display_date = ""
                event_time = ""
                if events[i]["dates"].get("start"):
                    if events[i]["dates"]["start"].get("localDate") and events[i]["dates"]["start"].get("localTime"):
                        localtime = time.parse_time(events[i]["dates"]["start"]["localDate"] + "T" + events[i]["dates"]["start"]["localTime"] + "Z")

                        #display_date = humanize.time_format("EEE d MMM yyyy at HH:mm", localtime)
                        display_date = humanize.time_format("EEE d MMM yyyy at K:mm aa", localtime)  #Seriously, who would guess these formatting values?

                    if events[i]["dates"]["start"].get("dateTime"):
                        event_time = time.parse_time(events[i]["dates"]["start"]["dateTime"])
                        event_time = event_time.unix

                price_range = ""
                if events[i].get("priceRanges"):
                    for j in range(len(events[i]["priceRanges"])):
                        if events[i]["priceRanges"][j].get("type") and events[i]["priceRanges"][j]["type"] == "standard":
                            if events[i]["priceRanges"][j].get("type") and events[i]["priceRanges"][j].get("currency") and events[i]["priceRanges"][j].get("min") and events[i]["priceRanges"][j].get("max"):
                                currency_marker = ""
                                currency_suffix = ""
                                if events[i]["priceRanges"][j]["currency"] == "USD" or events[i]["priceRanges"][j]["currency"] == "CAD" or events[i]["priceRanges"][j]["currency"] == "AUD" or events[i]["priceRanges"][j]["currency"] == "NZD" or events[i]["priceRanges"][j]["currency"] == "MXN":
                                    currency_marker = "$"
                                elif events[i]["priceRanges"][j]["currency"] == "GBP":
                                    currency_marker = "£"
                                else:
                                    currency_suffix = events[i]["priceRanges"][j]["currency"]

                                min_price = float(events[i]["priceRanges"][j]["min"])
                                max_price = float(events[i]["priceRanges"][j]["max"])

                                price_range = ""
                                if (min_price == max_price):
                                    price_range = humanize.float("#.##", min_price)
                                else:
                                    price_range = "%s to %s%s" % (humanize.float("#.##", min_price), currency_marker, humanize.float("#.##", max_price))

                                price_range = "Ticket prices: %s%s%s" % (currency_marker, price_range, currency_suffix)

                events_data["events"][events[i]["id"]] = {"title": events[i]["name"].strip(), "image_url": image_url, "venue": venue, "price_range": price_range, "display_date": display_date, "event_time_utc": event_time}
    return events_data

def get_region_icon(geographic_market):
    if geographic_market == "USA" or geographic_market == "Canada" or geographic_market == "Mexico":
        return "earthAmericas"
    elif geographic_market == "Europe":
        return "earthEurope"
    else:
        return "earthOceania"

def get_region_options():
    markets = list(MARKETS.keys())
    market_options = []
    for i in markets:
        market_options.append(schema.Option(display = i, value = i))

    return market_options

def get_market_ids(geographic_market):
    regional_markets = [{"ID": item["ID"], "Market": item["Market"]} for item in MARKETS[geographic_market]]
    regional_markets = sorted(regional_markets, key = lambda x: x["Market"])

    market_options = []

    for market in regional_markets:
        market_options.append(schema.Option(display = market["Market"], value = str(market["ID"])))

    icon = get_region_icon(geographic_market)

    return [
        schema.Dropdown(
            id = "mymarket",
            name = "Region of %s" % geographic_market,
            desc = "Choose your regional market.",
            icon = icon,
            options = market_options,
            default = market_options[0].value,
        ),
    ]

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow",
            value = "60",
        ),
        schema.Option(
            display = "Medium",
            value = "45",
        ),
        schema.Option(
            display = "Fast",
            value = "30",
        ),
    ]

    region_options = get_region_options()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "artwork",
                name = "Display Event Artwork?",
                desc = "Displays the events artwork under the marquee information.",
                icon = "photoFilm",
                default = True,
            ),
            schema.Toggle(
                id = "cc",
                name = "Closed Caption Style?",
                desc = "Add black overlay over the background image to make text easier to read.",
                icon = "glasses",
                default = False,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Color(
                id = "color_1",
                name = "Event Title Color",
                desc = "Color of the text at the top displaying the event title.",
                icon = "brush",
                default = "#f4a306",
            ),
            schema.Color(
                id = "color_2",
                name = "Event Information Color",
                desc = "Color of the text at the bottom displaying the event information.",
                icon = "brush",
                default = "#ffffff",
            ),
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Select your region.",
                icon = "globe",
                options = get_region_options(),
                default = region_options[0].value,
            ),
            schema.Generated(
                id = "market_id",
                source = "region",
                handler = get_market_ids,
            ),
        ],
    )
