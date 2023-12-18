"""
Applet: NJ Transit Departure Vision
Summary: Shows the next departing trains of a station
Description: Shows the departing NJ Transit Trains of a selected station

The user can now decide to have the output filtered. 
For each trainline one can select 'all/none/even/odd'
all -> all trains from this line (the default)
none -> dont show trains from this line 
even -> dont show odd numbered trains
odd -> dont even numbered trains

The actual words used by the user to configure for even/odd are by train line.
For most train lines they are:  even = "Inbound Only",           odd = "Outbound Only"
For AMTK they are:              even = "North/Eastbound Only",   odd = "South/Westbound Only"
For Atlanitic City line:        even = "Towards Atlantic City",  odd = "Away from Atlantic City"
 
** It is not clear that Amtrak completly follows this convention

For example, if the user selected NY Penn Station, there are a ton of trains which dont go
where the user is interested in. So, the user can decide to only have the trains that run 
on the train lines they are interested in displayed

Likewise, if the user seleted "Montclair State University Station" they could decide to only have 
Inbound (towards NYC) trains on the MOBO line listed, since they only go in that direction.

 - Kurt-Gluck

Author: jason-j-hunt
"""

# Fixed a bug where trains (amtrak) with > 4 letter names would not display their train number.
# Fixed a bug (which I made worse) where if there were less than 2 trains to display the app would crash.

# Refrences on train numbering
#https://docs.google.com/spreadsheets/d/1p_uvF6KlDS0QpfI-3pmvhCOOfE5y6rtm0TyBfauuDAs/edit#gid=0
#https://www.quora.com/How-can-you-use-Amtrak-train-numbers-to-decipher-the-direction-or-route-that-a-train-is-taking
#Even numbered trains are inbound direction(towards NYC, or Atlantic City, or northbound/eastbound AMTRAK)
#odd numbered trans are outbound

load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

#URL TO NJ TRANSIT DEPARTURE VISION WEBSITE
NJ_TRANSIT_DV_URL = "https://www.njtransit.com/dv-to"
NJ_TRANSIT_STATIONS_URL = "https://www.njtransit.com/station-park-ride-to"
DEFAULT_STATION = "DEFAULT_STATION"

STATION_CACHE_KEY = "stations"
STATION_CACHE_TTL = 604800  #1 Week

DEPARTURES_CACHE_KEY = "departures"
DEPARTURES_CACHE_TTL = 60  # 1 minute

TIMEZONE = "America/New_York"

#DISPLAYS FIRST 3 Departures by default
DISPLAY_COUNT = 2

#If a line doesnt have a mapping - we use "AMTK" (amtrak)

# Extended the COLOR dictionary to include information needed by the Schema.
# The icon's were chosen from the limited icon set to be what I saw in most cases
# to be close to the official lines icons. The icons are used for the smart phone.
# https://www.njtransit.com/first-run/have-you-ever-wondered-what-our-rail-icons-mean
# https://fontawesome.com/search?q=building&o=r&m=free
#

LINE_DICT = {
    "ACRL": struct(
        color = "#2e55a5",
        name = "Atlantic City Line",
        icon = "water",
        default = "all",
        desc = "ACRL",
        even = "Towards Atlantic City",
        odd = "Away from Atlantic City",
    ),
    "AMTK": struct(
        color = "#ffca18",
        name = "Amtrak",
        icon = "rocket",
        default = "all",
        desc = "AMTK",
        even = "North/Eastbound Only",
        odd = "South/Westbound Only",
    ),
    "BERG": struct(
        color = "#c3c3c3",
        name = "Bergen Line",
        icon = "buildingWheat",
        default = "all",
        desc = "BERG",
        even = "Inbound Only",
        odd = "Outbound Only",
    ),
    "MAIN": struct(
        color = "#fbb600",
        name = "Main Bergen Line",
        icon = "industry",
        default = "all",
        desc = "MAIN",
        even = "Inbound Only",
        odd = "Outbound Only",
    ),
    "MOBO": struct(
        color = "#c26366",
        name = "Montclair-Boonton Line",
        icon = "dove",
        default = "all",
        desc = "MOBO",
        even = "Inbound Only",
        odd = "Outbound Only",
    ),
    "M&E": struct(
        color = "#28943b",
        name = "Morris & Essex",
        icon = "horse",
        default = "all",
        desc = "M&E",
        even = "Inbound Only",
        odd = "Outbound Only",
    ),
    "NEC": struct(
        color = "#f54f5e",
        name = "Northeast Corridor",
        icon = "landmarkDome",
        default = "all",
        desc = "NEC",
        even = "Inbound Only",
        odd = "Outbound Only",
    ),
    "NJCL": struct(
        color = "#339cdb",
        name = "North Jersey Coast",
        icon = "sailboat",
        default = "all",
        desc = "NJCL",
        even = "Inbound Only",
        odd = "Outbound Only",
    ),
    "PASC": struct(
        color = "#a34e8a",
        name = "Pascack Valley",
        icon = "tree",
        default = "all",
        desc = "PASC",
        even = "Inbound Only",
        odd = "Outbound Only",
    ),
    "RARV": struct(
        color = "#ff9315",
        name = "Raritan Valley",
        icon = "monument",
        default = "all",
        desc = "RARV",
        even = "Inbound Only",
        odd = "Outbound Only",
    ),
}

def main(config):
    selected_station = config.get("station", DEFAULT_STATION)

    # create dictionary of lineoptions(all,none,inbound,outbound) by line
    lineoptions = {}
    for key in LINE_DICT:
        #fetch the default for each line
        defaultlineoption = LINE_DICT.get(key).default

        #fetch the setting from the schema/config
        lineoption = config.get(key, defaultlineoption)
        lineoptions[key] = lineoption
        #print("Loading options: line={} default={} option={} name={}".format(key,defaultlineoption,lineoption,LINE_DICT.get(key).name))

    departures = get_departures_for_station(selected_station)

    rendered_rows = render_departure_list(departures, lineoptions, selected_station)

    return render.Root(
        delay = 75,
        max_age = 60,
        child = rendered_rows,
    )

def render_departure_list(departures, lineoptions, station):
    """
    Renders a given lists of departures
    """

    render_count = 0

    rendered = []

    #print(" departures length = {}".format(len(departures)))

    for d in departures:
        # clean up train number to only be digits - needed for amtrak
        train_number_s = d.train_number
        train_number_t = re.sub("\\D", "", train_number_s)
        train_number = int(train_number_t)
        train_number_is_even = (train_number % 2) == 0

        #train_line = d.service_line
        filterpassed = True
        filterby = lineoptions.get(d.service_line, "nomatch")

        ##debugging
        #dict_entry = LINE_DICT.get(d.service_line)
        #linename = "Error fetching line='{}' from dictionary".format(d.service_line)
        #if dict_entry != None : linename= dict_entry.name

        if filterby == "none":
            filterpassed = False
        if filterby == "even" and not (train_number_is_even):
            filterpassed = False
        if filterby == "odd" and train_number_is_even:
            filterpassed = False

        #print("rdl() #={}={}={}={} even={} line={}={} filter={} filterpassed={} count={}".format(d.train_number,
        #                                                                                train_number_s,
        #                                                                                train_number_t,
        #                                                                                train_number,
        #                                                                                train_number_is_even,
        #                                                                                train_line,
        #                                                                                linename,
        #                                                                                filterby,
        #                                                                                filterpassed,
        #                                                                                render_count))

        if filterpassed:
            render_count = render_count + 1
            rendered.append(render_departure_row(d))
        if render_count >= DISPLAY_COUNT:
            break

    # If there are less then 2 trains to display - insert the station name above
    # If there are no trains to display - add a message as to that effect.
    # this fixes an obscure bug that I made worse by reducing the number of trains to display
    if render_count < DISPLAY_COUNT:
        rendered.insert(0, render_extra_row(station))
    if render_count == 0:
        rendered.append(render_extra_row("No Matching Trains"))

    return render.Column(
        expanded = True,
        main_align = "start",
        children = [
            rendered[0],
            render.Box(
                width = 64,
                height = 1,
                color = "#666",
            ),
            rendered[1],
        ],
    )

def render_extra_row(sometext):
    thetext = render.Marquee(
        width = 56,
        child = render.Text(sometext, font = "Dina_r400-6", offset = 2, height = 14),
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            thetext,
        ],
    )

def render_departure_row(departure):
    """
    Creates a Row and adds needed children objects
    for a single departure.
    """

    #If we cant find the line - we will use Amtrak's settings and options instead
    default_entry = LINE_DICT.get("AMTK")
    line_entry = LINE_DICT.get(departure.service_line, default_entry)
    use_color = line_entry.color

    background_color = render.Box(width = 22, height = 11, color = use_color)
    destination_text = render.Marquee(
        width = 36,
        child = render.Text(departure.destination, font = "Dina_r400-6", offset = -2, height = 7),
    )

    departing_in_text = render.Text(departure.departing_in, color = "#f3ab3f")

    #If we have a Track Number append and make it a scroll marquee
    if departure.track_number != None:
        depart = "{} - Track {}".format(departure.departing_in, departure.track_number)
        departing_in_text = render.Marquee(
            width = 36,
            child = render.Text(depart, color = "#f3ab3f"),
        )

    if departure.departing_in.startswith("at"):
        departing_in_text = render.Marquee(
            width = 36,
            child = render.Text(departure.departing_in, color = "#f3ab3f"),
        )

    child_train_number = render.Text(departure.train_number, font = "CG-pixel-4x5-mono")

    #KAG - fixed bug, the Marquee didnt work for trains with long numbers, it needed a width
    if len(departure.train_number) > 4:
        child_train_number = render.Marquee(width = 22, child = child_train_number)

    train_number = render.Box(
        color = "#0000",
        width = 22,
        height = 11,
        child = child_train_number,
    )

    stack = render.Stack(children = [
        background_color,
        train_number,
    ])

    column = render.Column(
        children = [
            destination_text,
            departing_in_text,
        ],
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            stack,
            column,
        ],
    )

def get_schema():
    options = getStationListOptions()

    fields = [
        schema.Dropdown(
            id = "station",
            name = "Departing Station",
            desc = "The NJ Transit Station to get departure schedule for.",
            icon = "train",
            default = options[0].value,
            options = options,
        ),
    ]

    # ADD OPTIONS FOR EACH TRAINLINE

    for key in LINE_DICT:
        entry = LINE_DICT.get(key)
        fields.append(
            schema.Dropdown(
                id = key,
                name = entry.name,
                desc = entry.desc,
                icon = entry.icon,
                default = entry.default,
                options = getLineOptions(entry.even, entry.odd),
            ),
        )

    #TODO - AM I SUPPOSED TO BUMP THE VERSION NUMBER?
    return schema.Schema(
        version = "1",
        fields = fields,
    )

def get_departures_for_station(station):
    """
    Function gets all depatures for a given station
    returns a list of structs with the following fields

    depature_item struct:
        departing_at: string
        destination: string
        service_line: string
        train_number: string
        track_number: string
        departing_in: string
    """
    #print("Getting departures for '%s'" % station)

    if station == DEFAULT_STATION:
        return []

    station_suffix = station.replace(" ", "%20")
    station_url = "{}/{}".format(NJ_TRANSIT_DV_URL, station_suffix)

    #print(station_url)

    nj_dv_page_response = http.get(station_url)

    if nj_dv_page_response.status_code != 200:
        #print("Got code '%s' from page response" % nj_dv_page_response.status_code)
        return None

    selector = html(nj_dv_page_response.body())
    departures = selector.find(".border.mb-3.rounded")

    #print("Found '%s' departures" % departures.len())

    result = []

    for index in range(0, departures.len()):
        departure = departures.eq(index)
        item = extract_fields_from_departure(departure)
        result.append(item)

        #since we dont know at this point if we are displaying any particular train
        #cant reduce the number of trains to the DISPLAY_COUNT here
        #if len(result) == DISPLAY_COUNT:
        #    return result

    return result

def extract_fields_from_departure(departure):
    """
    Function Extracts necessary data from HTML of a given depature
    """
    data = departure.find(".media-body").first()

    departure_time = get_departure_time(data)
    destination_name = get_destination_name(data)
    service_line = get_service_line(data)
    train_number = get_train_number(data)
    track_number = get_track_number(data)
    departing_in = get_real_time_estimated_departure(data, departure_time)

    #print(
    #    "{}\t{}\t{}\t{}\t{}\t{}\n".format(
    #        departure_time,
    #        destination_name,
    #        service_line,
    #        train_number,
    #        track_number,
    #        departing_in,
    #    ),
    #)

    return struct(
        departing_at = departure_time,
        destination = destination_name,
        service_line = service_line,
        train_number = train_number,
        track_number = track_number,
        departing_in = departing_in,
    )

def get_departure_time(data):
    """
    Function gets depature time for a given depature
    """
    time_string = data.find(".d-block.ff-secondary--bold.flex-grow-1.h2.mb-0").first().text().strip()
    return time_string

def get_service_line(data):
    """
    Function gets the service line the train is running on
    """
    nodes = data.find(".media-body").first().find(".mb-0")
    string = nodes.eq(1).text().strip().split()
    service_line = string[0].strip()

    return service_line

def get_train_number(data):
    """
    Function gets the train number from a given depature
    """
    nodes = data.find(".media-body").first().find(".mb-0")
    srvc_train_number = nodes.eq(1).text().strip().split()
    train_number = srvc_train_number[2].strip()
    return train_number

def get_destination_name(data):
    """
    Function gets the destation froma  given depature
    """
    nodes = data.find(".media-body").first().find(".mb-0")
    destination_name = nodes.eq(0).text().strip().replace("\\u2708", "EWR").upper()
    return destination_name

def get_real_time_estimated_departure(data, scheduled_time):
    """
    Will attempt to get given departing time from nj transit
    If not availble will return the in X min via the scheduled
    Departure time - time.now()
    """
    nodes = data.find(".media-body").first().find(".mb-0")
    node = nodes.eq(2)

    departing_in = ""

    if node != None:
        departing_in = node.text().strip().removeprefix("in ")

    #If we cant get from NJT return scheduled Departure time
    if len(departing_in) == 0:
        departing_in = "at {}".format(scheduled_time)

    return departing_in

def get_track_number(data):
    """
    Returns the track number the train will be departing from.
    May not be availble until about 10 minutes before scheduled departure time.
    """
    node = data.find(".align-self-end.mb-0").first()

    if node != None:
        text = node.text().strip().split()
        if len(text) > 1:
            track = text[1].strip()
        else:
            track = None
    else:
        track = None

    return track

def fetch_stations_from_website():
    """
    Function fetches trains station list from NJ Transit website
    To be used for creating Schema option list
    """
    result = []

    nj_dv_page_response_body = cache.get(DEPARTURES_CACHE_KEY)

    if nj_dv_page_response_body == None:
        nj_dv_page_response = http.get(NJ_TRANSIT_STATIONS_URL)

        if nj_dv_page_response.status_code != 200:
            #print("Got code '%s' from page response" % nj_dv_page_response.status_code)
            return result

        nj_dv_page_response_body = nj_dv_page_response.body()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(DEPARTURES_CACHE_KEY, nj_dv_page_response.body(), DEPARTURES_CACHE_TTL)

    selector = html(nj_dv_page_response_body)
    stations = selector.find(".vbt-autocomplete-list.list-unstyled.shadow.w-100.list-main").children_filtered(".scrollable-items").children()

    #print("Got response of '%s' stations" % stations.len())

    for index in range(0, stations.len()):
        station = stations.eq(index)
        station_name = station.find("a").first().text()

        #print("Found station '%s' from page response" % station_name)
        result.append(station_name)

    return result

def getStationListOptions():
    """
    Creates a list of schema options from station list
    """
    options = []
    cache_string = cache.get(STATION_CACHE_KEY)

    stations = None

    if cache_string != None:
        stations = json.decode(cache_string)

    if stations == None:
        stations = fetch_stations_from_website()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(STATION_CACHE_KEY, json.encode(stations), STATION_CACHE_TTL)

    for station in stations:
        options.append(create_option(station, station))

    return options

def getLineOptions(evenwords, oddwords):
    """
    Creates a list of schema options for each train line
    """
    options = []

    options.append(create_option("All Trains", "all"))
    options.append(create_option("No Trains", "none"))
    options.append(create_option(evenwords, "even"))
    options.append(create_option(oddwords, "odd"))

    return options

def create_option(display_name, value):
    """
    Helper function to create a schema option of a given display name and value
    """
    return schema.Option(
        display = display_name,
        value = value,
    )
