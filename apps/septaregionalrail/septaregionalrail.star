"""
Applet: SEPTA Regional Rail
Summary: SEPTA Regional Rail Departures
Description: Displays departure times for SEPTA regional rail trains.
Author: radiocolin
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def regional_rail_station_options():
    regional_rail_stations = [
        "30th Street Station",
        "49th Street",
        "9th Street",
        "Airport Terminal A",
        "Airport Terminal B",
        "Airport Terminal C D",
        "Airport Terminal E F",
        "Allegheny",
        "Ambler",
        "Angora",
        "Ardmore",
        "Ardsley",
        "Berwyn",
        "Bethayres",
        "Bridesburg",
        "Bristol",
        "Bryn Mawr",
        "Carpenter",
        "Chalfont",
        "Chelten Avenue",
        "Cheltenham",
        "Chester Transportation Center",
        "Chestnut Hill East",
        "Chestnut Hill West",
        "Churchmans Crossing",
        "Claymont",
        "Clifton–Aldan",
        "Colmar",
        "Conshohocken",
        "Cornwells Heights",
        "Crestmont",
        "Croydon",
        "Crum Lynne",
        "Curtis Park",
        "Cynwyd",
        "Darby",
        "Daylesford",
        "Delaware Valley University",
        "Devon",
        "Downingtown",
        "Doylestown",
        "East Falls",
        "Eastwick",
        "Eddington",
        "Eddystone",
        "Elkins Park",
        "Elm Street",
        "Elwyn",
        "Exton",
        "Fern Rock Transportation Center",
        "Fernwood–Yeadon",
        "Folcroft",
        "Forest Hills",
        "Fort Washington",
        "Fortuna",
        "Fox Chase",
        "Germantown",
        "Gladstone",
        "Glenolden",
        "Glenside",
        "Gravers",
        "Gwynedd Valley",
        "Hatboro",
        "Haverford",
        "Highland",
        "Highland Avenue",
        "Holmesburg Junction",
        "Ivy Ridge",
        "Jefferson Station",
        "Jenkintown Wyncote",
        "Langhorne",
        "Lansdale",
        "Lansdowne",
        "Lawndale",
        "Levittown",
        "Link Belt",
        "Main Street",
        "Malvern",
        "Manayunk",
        "Marcus Hook",
        "Meadowbrook",
        "Media",
        "Melrose Park",
        "Merion",
        "Miquon",
        "Morton",
        "Mount Airy",
        "Moylan-Rose Valley",
        "Narberth",
        "Neshaminy Falls",
        "New Britain",
        "Newark",
        "Noble",
        "Norristown TC",
        "North Broad",
        "North Hills",
        "North Philadelphia",
        "North Wales",
        "Norwood",
        "Olney",
        "Oreland",
        "Overbrook",
        "Paoli",
        "Penllyn",
        "Penn Medicine Station",
        "Pennbrook",
        "Philmont",
        "Primos",
        "Prospect Park",
        "Queen Lane",
        "Radnor",
        "Richard Allen Lane",
        "Ridley Park",
        "Rosemont",
        "Roslyn",
        "Rydal",
        "Ryers",
        "Secane",
        "Sedgwick",
        "Sharon Hill",
        "Somerton",
        "Spring Mill",
        "St. Davids",
        "St. Martins",
        "Stenton",
        "Strafford",
        "Suburban Station",
        "Swarthmore",
        "Tacony",
        "Temple University",
        "Thorndale",
        "Torresdale",
        "Trenton",
        "Trevose",
        "Tulpehocken",
        "Upsal",
        "Villanova",
        "Wallingford",
        "Warminster",
        "Washington Lane",
        "Wawa",
        "Wayne",
        "Wayne Junction",
        "West Trenton",
        "Whitford",
        "Willow Grove",
        "Wilmington",
        "Wissahickon",
        "Wister",
        "Woodbourne",
        "Wyndmoor",
        "Wynnefield Avenue",
        "Wynnewood",
        "Yardley",
    ]

    station_options = []
    for i in regional_rail_stations:
        station_options.append(
            schema.Option(
                display = i,
                value = i,
            ),
        )
    return station_options

API_BASE = "http://www3.septa.org/api"
API_ROUTES = API_BASE + "/Routes"
API_SCHEDULE = API_BASE + "/Arrivals"
DEFAULT_STATION = "Wayne Junction"
DEFAULT_DIRECTION = "S"

def call_schedule_api(direction, station):
    cache_string = cache.get(direction + "_" + station + "_" + "schedule_api_response")
    schedule = None
    if cache_string != None:
        schedule = json.decode(cache_string)
    if schedule == None:
        r = http.get(API_SCHEDULE, params = {"station": station, "direction": direction, "results": "4"})
        schedule_raw = r.json()
        schedule = schedule_raw.values()[0][0].values()[0]
        parsed_time = time.parse_time(schedule[0]["sched_time"], "2006-01-02 15:04:05.000", "America/New_York")
        expiry = int((parsed_time - time.now()).seconds)
        if expiry < 0:  #this is because septa's API returns tomorrow's times with today's date if the last departure for the day has already happened
            expiry = 30
        cache.set(direction + "_" + station + "_" + "schedule_api_response", json.encode(schedule), ttl_seconds = expiry)
    return schedule

def get_schedule(direction, station):
    schedule = call_schedule_api(direction, station)
    list_of_departures = []

    for i in schedule:
        parsed_departure = time.parse_time(i["sched_time"], "2006-01-02 15:04:05.000", "America/New_York").format("3:04")
        if int(time.parse_time(i["sched_time"], "2006-01-02 15:04:05.000", "America/New_York").format("15")) < 12:
            parsed_departure = parsed_departure + "a"
        else:
            parsed_departure = parsed_departure + "p"

        if len(list_of_departures) % 2 == 1:
            background = "#222"
            text = "#fff"
        else:
            background = "#000"
            text = "#ffc72c"
        if len(parsed_departure) == 5:
            departure = " " + parsed_departure
        else:
            departure = parsed_departure
        item = render.Box(
            height = 6,
            width = 64,
            color = background,
            child = render.Row(
                cross_align = "right",
                children = [
                    render.Box(
                        width = 25,
                        child = render.Text(
                            departure,
                            font = "tom-thumb",
                            color = text,
                        ),
                    ),
                    render.Marquee(
                        child = render.Text(
                            i["train_id"] + " " + i["service_type"] + " to " + i["destination"] + " - " + i["status"],
                            font = "tom-thumb",
                            color = text,
                        ),
                        width = 39,
                        offset_start = 40,
                        offset_end = 40,
                    ),
                ],
            ),
        )
        list_of_departures.append(item)

    if len(list_of_departures) < 1:
        return [render.Box(
            height = 6,
            width = 64,
            color = "#000",
            child = render.Text("Select a stop"),
        )]
    else:
        return list_of_departures

def main(config):
    station = config.str("station", DEFAULT_STATION)
    direction = config.str("direction", DEFAULT_DIRECTION)
    user_text = config.str("banner", "")
    schedule = get_schedule(direction, station)
    left_pad = 1

    if config.bool("use_custom_banner_color"):
        banner_bg_color = config.str("custom_banner_color")
    else:
        banner_bg_color = "#45637A"

    if config.bool("use_custom_text_color"):
        banner_text_color = config.str("custom_text_color")
    else:
        banner_text_color = "#FFFFFF"

    if user_text == "":
        banner_text = station
    else:
        banner_text = user_text

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = 6, width = 64, color = banner_bg_color),
                            render.Padding(pad = (left_pad, 0, 0, 0), child = render.Text(banner_text, font = "tom-thumb", color = banner_text_color)),
                        ]),
                    ],
                ),
                render.Padding(pad = (0, 0, 0, 2), color = banner_bg_color, child = render.Column(children = schedule)),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Select a station",
                icon = "signsPost",
                default = DEFAULT_STATION,
                options = regional_rail_station_options(),
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Select a direction",
                icon = "compass",
                default = DEFAULT_DIRECTION,
                options = [
                    schema.Option(
                        display = "N",
                        value = "N",
                    ),
                    schema.Option(
                        display = "S",
                        value = "S",
                    ),
                ],
            ),
            schema.Text(
                id = "banner",
                name = "Custom banner text",
                desc = "Custom text for the top bar. Leave blank to show the selected route.",
                icon = "penNib",
                default = "",
            ),
            schema.Toggle(
                id = "use_custom_banner_color",
                name = "Use custom banner color",
                desc = "Use a custom background color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_banner_color",
                name = "Custom banner color",
                desc = "A custom background color for the top banner.",
                icon = "brush",
                default = "#7AB0FF",
            ),
            schema.Toggle(
                id = "use_custom_text_color",
                name = "Use custom text color",
                desc = "Use a custom text color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_text_color",
                name = "Custom text color",
                desc = "A custom text color for the top banner.",
                icon = "brush",
                default = "#FFFFFF",
            ),
        ],
    )
