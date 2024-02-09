load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

DEFAULT_DIRECTION = "all"
DEFAULT_MAPID = "41320"

def get_color(line):
    if (line == "Pink"):  # pink line , FF99AA
        return "#ff8599"
    if (line == "Red"):  # red line
        return "#FF0000"
    if (line == "Brn"):  # brown line
        return "#a86929"
    if (line == "P"):  # purple line
        return "#51087E"
    if (line == "Blue"):  # blue line
        return "#0000FF"
    if (line == "G"):  # green line
        return "#00FF00"
    if (line == "Org"):  # orange line
        return "#FFA500"
    if (line == "Y"):  # yellow line
        return "#FFFF00"
    return "#000000"

def calculate_minutes_away(item):
    arrival_time_str = item["arrT"]
    prediction_time_str = item["prdt"]
    is_due = item["isApp"]
    if (is_due == 1):
        return "Due"
    timezone = "US/Central"
    arrival_time = time.parse_time(arrival_time_str, "2006-01-02T15:04:05", timezone)
    prediction_time = time.parse_time(prediction_time_str, "2006-01-02T15:04:05", timezone)
    time_difference_seconds = arrival_time - prediction_time
    minutes_away = time_difference_seconds.minutes

    return str(int(minutes_away))

def map_to_train_estimates(response, train_dir):
    next_train_estimates = [{
        "color": item["rt"],
        "minutes_away": calculate_minutes_away(item),
        "arrival_time": item["arrT"],
        "destination": item["destNm"],
        "is_due": int(item["isApp"]),
        "direction": int(item["trDr"]),
    } for item in response.json()["ctatt"]["eta"]]

    if (train_dir == "inbound"):
        next_train_estimates = [obj for obj in next_train_estimates if obj["direction"] == 5]
    if (train_dir == "outbound"):
        next_train_estimates = [obj for obj in next_train_estimates if obj["direction"] == 1]

    sorted_combined_properties = sorted(next_train_estimates, key = lambda x: x["arrival_time"])
    return sorted_combined_properties

def map_to_render(combined_properties):
    output = []
    for item in combined_properties:
        output.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Marquee(
                        width = 48,
                        child = render.Text(
                            content = item["destination"],
                            color = get_color(item["color"]),
                        ),
                    ),
                    render.Text(
                        content = item["minutes_away"],
                    ),
                ],
            ),
        )

    return output

def main(config):
    train_dir = config.str("directions", DEFAULT_DIRECTION)
    map_id = int(config.get("mapId", DEFAULT_MAPID))

    api_key = secret.decrypt("AV6+xWcET06sVKAXgeOgTHYDXPjOUJcUOkKg5NBwW+wdTuqieIHvNmFAnr0DJqI6OPSszMgPmsbZwJA55FL/ZVrPa6anbi2eabBTwHHNq/CzaRzMcyYljU3IuD3Umc9xRyq1saX5p2qVeOsO0oFZT1z3JxGE5R2Hv3CprWqzdFp6GSqgcMU=")

    if api_key == None:
        fail("api key not found")

    arrival_estimate_url = "http://api.transitchicago.com/api/1.0/ttarrivals.aspx"

    estimates_response = http.get(
        arrival_estimate_url,
        params = {
            "key": api_key,
            "mapid": str(map_id),
            "outputType": "JSON",
        },
    )

    if (estimates_response.status_code != 200):
        fail("request failed with code %d", estimates_response.status_code)

    next_arrivals = map_to_train_estimates(estimates_response, train_dir)
    children_to_render = map_to_render(next_arrivals)

    return render.Root(
        child = render.Column(
            children = children_to_render[:4],
        ),
    )

def get_schema():
    station_options = [
        schema.Option(
            display = "18th",
            value = "40830",
        ),
        schema.Option(
            display = "35th-Bronzeville-IIT",
            value = "41120",
        ),
        schema.Option(
            display = "35th/Archer",
            value = "40120",
        ),
        schema.Option(
            display = "43rd",
            value = "41270",
        ),
        schema.Option(
            display = "47th (Green Line)",
            value = "41080",
        ),
        schema.Option(
            display = "47th (Red Line)",
            value = "41230",
        ),
        schema.Option(
            display = "51st",
            value = "40130",
        ),
        schema.Option(
            display = "54th/Cermak",
            value = "40580",
        ),
        schema.Option(
            display = "63rd",
            value = "40910",
        ),
        schema.Option(
            display = "69th",
            value = "40990",
        ),
        schema.Option(
            display = "79th",
            value = "40240",
        ),
        schema.Option(
            display = "87th",
            value = "41430",
        ),
        schema.Option(
            display = "95th",
            value = "40450",
        ),
        schema.Option(
            display = "Adams/Wabash",
            value = "40680",
        ),
        schema.Option(
            display = "Addison (Blue Line)",
            value = "41240",
        ),
        schema.Option(
            display = "Addison (Brown Line)",
            value = "41440",
        ),
        schema.Option(
            display = "Addison (Red Line)",
            value = "41420",
        ),
        schema.Option(
            display = "Argyle",
            value = "41200",
        ),
        schema.Option(
            display = "Armitage",
            value = "40660",
        ),
        schema.Option(
            display = "Ashland/63rd",
            value = "40290",
        ),
        schema.Option(
            display = "Ashland (Green, Pink Lines)",
            value = "40170",
        ),
        schema.Option(
            display = "Ashland (Orange Line)",
            value = "41060",
        ),
        schema.Option(
            display = "Austin (Blue Line)",
            value = "40010",
        ),
        schema.Option(
            display = "Austin (Green Line)",
            value = "41260",
        ),
        schema.Option(
            display = "Belmont (Red, Brown, Purple Lines)",
            value = "41320",
        ),
        schema.Option(
            display = "Belmont (Blue Line)",
            value = "40060",
        ),
        schema.Option(
            display = "Berwyn",
            value = "40340",
        ),
        schema.Option(
            display = "Bryn Mawr",
            value = "41380",
        ),
        schema.Option(
            display = "California (Pink Line)",
            value = "40440",
        ),
        schema.Option(
            display = "California (Green Line)",
            value = "41360",
        ),
        schema.Option(
            display = "California (Blue Line-O'Hare Branch)",
            value = "40570",
        ),
        schema.Option(
            display = "Central Park",
            value = "40780",
        ),
        schema.Option(
            display = "Central (Green Line)",
            value = "40280",
        ),
        schema.Option(
            display = "Central (Purple Line)",
            value = "41250",
        ),
        schema.Option(
            display = "Cermak-Chinatown",
            value = "41000",
        ),
        schema.Option(
            display = "Cermak-McCormick Place",
            value = "41690",
        ),
        schema.Option(
            display = "Chicago (Blue Line)",
            value = "41410",
        ),
        schema.Option(
            display = "Chicago (Brown Line)",
            value = "40710",
        ),
        schema.Option(
            display = "Chicago (Red Line)",
            value = "41450",
        ),
        schema.Option(
            display = "Cicero (Pink Line)",
            value = "40420",
        ),
        schema.Option(
            display = "Cicero (Blue Line-Forest Park Branch)",
            value = "40970",
        ),
        schema.Option(
            display = "Cicero (Green Line)",
            value = "40480",
        ),
        schema.Option(
            display = "Clark/Division",
            value = "40630",
        ),
        schema.Option(
            display = "Clark/Lake",
            value = "40380",
        ),
        schema.Option(
            display = "Clinton (Blue Line)",
            value = "40430",
        ),
        schema.Option(
            display = "Clinton (Green Line)",
            value = "41160",
        ),
        schema.Option(
            display = "Conservatory",
            value = "41670",
        ),
        schema.Option(
            display = "Cumberland",
            value = "40230",
        ),
        schema.Option(
            display = "Damen (Brown Line)",
            value = "40090",
        ),
        schema.Option(
            display = "Damen (Pink Line)",
            value = "40210",
        ),
        schema.Option(
            display = "Damen (Blue Line-O'Hare Branch)",
            value = "40590",
        ),
        schema.Option(
            display = "Davis",
            value = "40050",
        ),
        schema.Option(
            display = "Dempster",
            value = "40690",
        ),
        schema.Option(
            display = "Dempster-Skokie",
            value = "40140",
        ),
        schema.Option(
            display = "Diversey",
            value = "40530",
        ),
        schema.Option(
            display = "Division",
            value = "40320",
        ),
        schema.Option(
            display = "Cottage Grove",
            value = "40720",
        ),
        schema.Option(
            display = "Forest Park",
            value = "40390",
        ),
        schema.Option(
            display = "Foster",
            value = "40520",
        ),
        schema.Option(
            display = "Francisco",
            value = "40870",
        ),
        schema.Option(
            display = "Fullerton",
            value = "41220",
        ),
        schema.Option(
            display = "Garfield (Green Line)",
            value = "40510",
        ),
        schema.Option(
            display = "Garfield (Red Line)",
            value = "41170",
        ),
        schema.Option(
            display = "Grand (Blue Line)",
            value = "40490",
        ),
        schema.Option(
            display = "Grand (Red Line)",
            value = "40330",
        ),
        schema.Option(
            display = "Granville",
            value = "40760",
        ),
        schema.Option(
            display = "Halsted (Green Line)",
            value = "40940",
        ),
        schema.Option(
            display = "Halsted (Orange Line)",
            value = "41130",
        ),
        schema.Option(
            display = "Harlem (Blue Line-Forest Park Branch)",
            value = "40980",
        ),
        schema.Option(
            display = "Harlem (Green Line)",
            value = "40020",
        ),
        schema.Option(
            display = "Harlem (Blue Line-O'Hare Branch)",
            value = "40750",
        ),
        schema.Option(
            display = "Harold Washington Library-State/Van Buren",
            value = "40850",
        ),
        schema.Option(
            display = "Harrison",
            value = "41490",
        ),
        schema.Option(
            display = "Howard",
            value = "40900",
        ),
        schema.Option(
            display = "Illinois Medical District",
            value = "40810",
        ),
        schema.Option(
            display = "Indiana",
            value = "40300",
        ),
        schema.Option(
            display = "Irving Park (Blue Line)",
            value = "40550",
        ),
        schema.Option(
            display = "Irving Park (Brown Line)",
            value = "41460",
        ),
        schema.Option(
            display = "Jackson (Blue Line)",
            value = "40070",
        ),
        schema.Option(
            display = "Jackson (Red Line)",
            value = "40560",
        ),
        schema.Option(
            display = "Jarvis",
            value = "41190",
        ),
        schema.Option(
            display = "Jefferson Park",
            value = "41280",
        ),
        schema.Option(
            display = "Kedzie (Brown Line)",
            value = "41180",
        ),
        schema.Option(
            display = "Kedzie (Pink Line)",
            value = "41040",
        ),
        schema.Option(
            display = "Kedzie (Green Line)",
            value = "41070",
        ),
        schema.Option(
            display = "Kedzie-Homan (Blue Line)",
            value = "40250",
        ),
        schema.Option(
            display = "Kedzie (Orange Line)",
            value = "41150",
        ),
        schema.Option(
            display = "Kimball",
            value = "41290",
        ),
        schema.Option(
            display = "King Drive",
            value = "41140",
        ),
        schema.Option(
            display = "Kostner",
            value = "40600",
        ),
        schema.Option(
            display = "Lake",
            value = "41660",
        ),
        schema.Option(
            display = "Laramie",
            value = "40700",
        ),
        schema.Option(
            display = "LaSalle",
            value = "41340",
        ),
        schema.Option(
            display = "LaSalle/Van Buren",
            value = "40160",
        ),
        schema.Option(
            display = "Lawrence",
            value = "40770",
        ),
        schema.Option(
            display = "Linden",
            value = "41050",
        ),
        schema.Option(
            display = "Logan Square",
            value = "41020",
        ),
        schema.Option(
            display = "Loyola",
            value = "41300",
        ),
        schema.Option(
            display = "Main",
            value = "40270",
        ),
        schema.Option(
            display = "Midway",
            value = "40930",
        ),
        schema.Option(
            display = "Monroe (Blue Line)",
            value = "40790",
        ),
        schema.Option(
            display = "Monroe (Red Line)",
            value = "41090",
        ),
        schema.Option(
            display = "Montrose (Blue Line)",
            value = "41330",
        ),
        schema.Option(
            display = "Montrose (Brown Line)",
            value = "41500",
        ),
        schema.Option(
            display = "Morgan",
            value = "41510",
        ),
        schema.Option(
            display = "Morse",
            value = "40100",
        ),
        schema.Option(
            display = "North/Clybourn",
            value = "40650",
        ),
        schema.Option(
            display = "Noyes",
            value = "40400",
        ),
        schema.Option(
            display = "Oak Park (Blue Line)",
            value = "40180",
        ),
        schema.Option(
            display = "Oak Park (Green Line)",
            value = "41350",
        ),
        schema.Option(
            display = "Oakton-Skokie",
            value = "41680",
        ),
        schema.Option(
            display = "O'Hare",
            value = "40890",
        ),
        schema.Option(
            display = "Paulina",
            value = "41310",
        ),
        schema.Option(
            display = "Polk",
            value = "41030",
        ),
        schema.Option(
            display = "Pulaski (Pink Line)",
            value = "40150",
        ),
        schema.Option(
            display = "Pulaski (Blue Line-Forest Park Branch)",
            value = "40920",
        ),
        schema.Option(
            display = "Pulaski (Green Line)",
            value = "40030",
        ),
        schema.Option(
            display = "Pulaski (Orange Line)",
            value = "40960",
        ),
        schema.Option(
            display = "Quincy/Wells",
            value = "40040",
        ),
        schema.Option(
            display = "Racine",
            value = "40470",
        ),
        schema.Option(
            display = "Ridgeland",
            value = "40610",
        ),
        schema.Option(
            display = "Rockwell",
            value = "41010",
        ),
        schema.Option(
            display = "Roosevelt",
            value = "41400",
        ),
        schema.Option(
            display = "Rosemont",
            value = "40820",
        ),
        schema.Option(
            display = "Sedgwick",
            value = "40800",
        ),
        schema.Option(
            display = "Sheridan",
            value = "40080",
        ),
        schema.Option(
            display = "South Boulevard",
            value = "40840",
        ),
        schema.Option(
            display = "Southport",
            value = "40360",
        ),
        schema.Option(
            display = "Sox-35th",
            value = "40190",
        ),
        schema.Option(
            display = "State/Lake",
            value = "40260",
        ),
        schema.Option(
            display = "Thorndale",
            value = "40880",
        ),
        schema.Option(
            display = "UIC-Halsted",
            value = "40350",
        ),
        schema.Option(
            display = "Washington/Wabash",
            value = "41700",
        ),
        schema.Option(
            display = "Washington/Wells",
            value = "40730",
        ),
        schema.Option(
            display = "Washington (Blue Line)",
            value = "40370",
        ),
        schema.Option(
            display = "Wellington",
            value = "41210",
        ),
        schema.Option(
            display = "Western (Brown Line)",
            value = "41480",
        ),
        schema.Option(
            display = "Western (Pink Line)",
            value = "40740",
        ),
        schema.Option(
            display = "Western (Blue Line-Forest Park Branch)",
            value = "40220",
        ),
        schema.Option(
            display = "Western (Blue Line-O'Hare Branch)",
            value = "40670",
        ),
        schema.Option(
            display = "Western (Orange Line)",
            value = "40310",
        ),
        schema.Option(
            display = "Wilson",
            value = "40540",
        ),
    ]

    direction_options = [
        schema.Option(
            display = "All directions",
            value = "all",
        ),
        schema.Option(
            display = "Inbound only",
            value = "inbound",
        ),
        schema.Option(
            display = "Outbound only",
            value = "outbound",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "mapId",
                name = "Station",
                desc = "L Station",
                icon = "train",
                default = station_options[0].value,
                options = station_options,
            ),
            schema.Dropdown(
                id = "directions",
                name = "Direction of trains",
                desc = "Show trains going both directions or a single direction.",
                icon = "arrowsLeftRight",
                default = direction_options[0].value,
                options = direction_options,
            ),
        ],
    )
