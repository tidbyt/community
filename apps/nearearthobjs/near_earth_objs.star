"""
Applet: Near Earth Objs
Summary: Show next near earth object
Description: Displays the name, speed, distance, and arrival of the next near Earth object from NeoWs.
Author: noahcolvin
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

URL = "https://www.neowsapp.com/rest/v1/feed?detailed=false&start_date={}"
CACHE_KEY = "neos"

# taken from https://pixabay.com/illustrations/planetarium-comet-falling-star-5636947/
IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAABfGlDQ1
BJQ0MgUHJvZmlsZQAAKM+VkblLA0EUh794EPEggoIWFot4NIl4QFALwYioICIxglez2VxCNll2E0
RsBVtBQbTxKvQv0FawFgRFEcTKwlrRRmV9mwgJQgpnmPe++c28x7w3UBZKarpV0Q16KmMGxwLK3P
yC4n6mGjdNDNKpapYxPD09ScnxcYfL8Tc+Jxf/GzWRqKWBq0p4SDPMjPC48ORKxnB4W7hRS6gR4V
NhrykPFL519HCeXxyO5/nLYTMUHJHa6oWVeBGHi1hLmLqwVE6bnsxqv+9xKqmNpmZnxLfKasEiyB
gBFCYYZQQ/PQyI9eOjly7ZUSK+Oxc/RVpiNbEGq5gsEydBBq+oWckeFR8TPSozyarT/799tWJ9vf
nstQGofLLtt3Zwb8H3pm1/Htr29xGUP8JFqhCfPoD+d9E3C1rbPnjW4eyyoIV34HwDmh8M1VRzUr
msslgMXk+gbh4arqF6Md+z33OO7yG0Jl91Bbt70CH3PUs/oLNoAE197gQAAAAJcEhZcwAADsMAAA
7DAcdvqGQAAALWSURBVDhPrVRNTBNBGP1mp92y/YNCKIZ60ZaVAwcxhnDRxMQDeCYmeDMhxMREY1
AkRI+eNB6MXtSzifGEchCPmngQNZI0gkVqBEqUn5af0m5/dsc3u4gCKqC+5O33zTfzvX0zs1lG/w
l39+vNCDP/JAiRCMIyeBPMdCcTvYqc+BtA7BjCefAl2ApeAWlXDiHiRwiDB8BHoAkGwR7wMRx+3L
FDiJ1EGALPgE9AH9xIMQFeQD6FSNsKTjTo6ouYfg/pQ050OKrQJUQehEKlsz/5vAbVgBz8UTDZoG
sIA1jctQdtrZzUOsR96DoILktvRKPgKVCVA+cdm5DSdWYIOoK0D2yXfZsXfkUxbtmpfN7B+Z2Tgy
0OkzFdgdhZpA/ADWJOv4MyGHImhsHLdgZsEMR5McFIntetAmORGcVFBnO60oxTnv1YXo9yTtBbpC
fgLu9UcbhrUZ4Xg5vbGca7FxTOFriLZEHay0Iso3AKW+V1twWikU+CjkMsvVayYc/DmZJn7P6o5j
39KlRFDQGDrKygsFGgsFkkS35tGFcLkzxCyG3NonIoOp5Iyf6fYTvsqK3rfx4K9Uz4vBT3+2icga
qP5twqtYayZCxhe2UFb2fkExZOhToh9sZW2ARlqLHJlfRqF1N+D035NBJwUCqVSSmWqCWzSAOFaq
rfa5LqEfZFQOwGxAad9q1QcHPR2qBZldACtIhz45yDCkXLRfpcqdGkWyN5L6UiM7C+F1y/0V9BXl
vVsuZCgIOySf7VHPlNkyaw3dfuAEW5QV9m+CiMNx/98P56bDwhr+q3kIKlYpGRZVkkZTuX5qljZZ
ZqsO0KzMZWVtPZFdbWPhYfszu2gYLdvIvM5wdbaJVcbk6Jaj+NeIM0r1VQW3rOqpw2uiA2ubZ+W9
ifzdPGJu5WRV+oRvSnFI93OqcKd8EcjuSMqxB7Zq/cIWzB74Cw/B1Fwem2sficXdwViL4B9lr4D1
NqhzUAAAAASUVORK5CYII=
""")

def main(config):
    metric = config.bool("metric") or False

    closest = get_soonest_neo()

    if closest == None:
        return render.Root(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Image(
                        src = IMAGE,
                        width = 15,
                        height = 10,
                    ),
                    render.WrappedText(
                        content = "No objects found... pfew!",
                        font = "5x8",
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Marquee(
                    child = render.Text(
                        content = closest["name"],
                        font = "tb-8",
                    ),
                    width = 64,
                    scroll_direction = "horizontal",
                ),
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Image(
                            src = IMAGE,
                            width = 15,
                            height = 10,
                        ),
                        render.Text(
                            content = str(neo_relative_time(closest)),
                            font = "tb-8",
                        ),
                    ],
                ),
                render.Marquee(
                    child = render.Row(
                        main_align = "start",
                        cross_align = "center",
                        expanded = False,
                        children = [
                            render.Text(
                                content = neo_distance(closest, metric),
                                font = "tb-8",
                            ),
                            render.Text(
                                content = " @ ",
                                font = "tb-8",
                            ),
                            render.Text(
                                content = neo_speed(closest, metric),
                                font = "tb-8",
                            ),
                        ],
                    ),
                    width = 64,
                    scroll_direction = "horizontal",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "metric",
                name = "Use Kilometers",
                desc = "Whether to display distance and speed in kilometers.",
                icon = "meteor",
                default = False,
            ),
        ],
    )

def get_soonest_neo():
    data = get_data()

    if data["element_count"] < 1:
        print("No near earth objects")
        return None

    dates = data["near_earth_objects"]
    next = find_soonest_starting(dates, time.now())

    return next

def get_data():
    neos_cached = cache.get(CACHE_KEY)
    if neos_cached != None:
        print("using cache")
        return json.decode(neos_cached)

    url = URL.format(format_date_padded(time.now()))
    print("fetching {}".format(url))
    resp = http.get(url)

    if resp.status_code != 200:
        print("request failed with status {}".format(resp.status_code))
        return None
    print("success")
    data = resp.json()

    cache.set(CACHE_KEY, json.encode(data), ttl_seconds = 43200)

    return data

def find_soonest_starting(neos, date):
    soonest = None

    one_day = time.parse_duration("24h")
    for day in range(8):
        date = date + one_day * day
        formatted_date = format_date_padded(date)
        if formatted_date in neos:
            soonest = find_next_from_now(neos[formatted_date])
        if soonest != None:
            break

    return soonest

def find_next_from_now(neos):
    now = time.now().unix

    soonest_neo = None
    for neo in neos:
        if neo_unix_date(neo) < now:
            continue  #skip passed times

        if soonest_neo == None:  #assume first is closest
            soonest_neo = neo
            continue

        if neo_unix_date(neo) < neo_unix_date(soonest_neo):
            soonest_neo = neo
        break

    return soonest_neo

def neo_speed(neo, metric):
    speed = format_number(int(float(neo["close_approach_data"][0]["relative_velocity"]["kilometers_per_hour" if metric else "miles_per_hour"])))
    return "{} {}".format(speed, "km/h" if metric else "mph")

def neo_distance(neo, metric):
    distance = format_number(int(float(neo["close_approach_data"][0]["miss_distance"]["kilometers" if metric else "miles"])))
    return "{} {}".format(distance, "km" if metric else "miles")

def neo_relative_time(neo):
    now = time.from_timestamp(time.now().unix)  # kills fractions of a second
    neo_time = time.from_timestamp(neo_unix_date(neo))

    diff = neo_time - now

    return diff

def neo_unix_date(neo):
    return convert_unix_to_seconds(neo["close_approach_data"][0]["epoch_date_close_approach"])

def convert_unix_to_seconds(time):
    return int(time / 1000)

def format_date_padded(date):
    return "{}-{}-{}".format(date.year, pad_if_needed(date.month), pad_if_needed(date.day))

def pad_if_needed(number):
    if len(str(number)) == 1:
        return "0{}".format(number)
    return number

def format_number(number):
    num = str(number)
    if len(num) < 4:
        return num

    count = 0
    result = ""
    for n in reversed(num.elems()):
        result = n + result
        count = count + 1

        if count == 3:
            result = "," + result
            count = 0

    return result.strip(",")
