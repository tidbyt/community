"""
Applet: VIE Publ. Transp.
Summary: RT data VIE Publ. Transp
Description: Show real time departures for desired  Public Transport stops in Vienna.
Author: Lukas Peer
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STOPPS = "4111,4118,4906,4911"  # Stephansplatz
N_DISPLAYED_STOPPS = 3
DEFAULT_SWITCH_SPEED = "5000"

# Wiener Linien Logo
WL_ICON_8_x_8 = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAIJJREFUKFNjZICC12KyTUz/mWrB3P8M74XfPBQCMRlhCt6Kyv+Hsf8z/XeBscEKkCVhEiBa+PVDRkZkSUYGhtb/DAySDAwMSSBJFCsYLLJAVlxiYGDgZGBgUEWxAiqJbDqEfWIaIyODcRo/XIaV5QOcfWIaVisg8v//6zOcnA6yjgEAusskDjQfi6cAAAAASUVORK5CYII="""

# Execute API request for given stopps (stopIDs) and store data in lists
def get_data(stopps):
    BASE_URL = "https://www.wienerlinien.at/ogd_realtime/monitor?stopId="
    WL_API_URL = BASE_URL + ",".join(stopps)

    rep = http.get(WL_API_URL, ttl_seconds = 30)
    if rep.status_code != 200:
        fail("WL request failed with status %d", rep.status_code)
    n_monitors = len(rep.json()["data"]["monitors"])
    linien = []
    haltestellen = []
    endstationen = []
    abfahrten = []

    # get data for every available monitor
    for i in range(n_monitors):
        linien.append(rep.json()["data"]["monitors"][i]["lines"][0]["name"])
        haltestellen.append(rep.json()["data"]["monitors"][i]["locationStop"]["properties"]["title"])
        endstationen.append(rep.json()["data"]["monitors"][i]["lines"][0]["towards"])

        n_abfahrten_available = len(rep.json()["data"]["monitors"][i]["lines"][0]["departures"]["departure"])
        n_abfahrten_shown = min(2, n_abfahrten_available)

        # Sometimes, if there is only one more departure for the day, only one departure time is shown
        # Hence, the necessary distinction to avoid out of bounds errors
        if n_abfahrten_shown == 2:
            af1 = str(int(float(rep.json()["data"]["monitors"][i]["lines"][0]["departures"]["departure"][0]["departureTime"]["countdown"])))
            af2 = str(int(float(rep.json()["data"]["monitors"][i]["lines"][0]["departures"]["departure"][1]["departureTime"]["countdown"])))
            out = af1 + " " + af2
        else:
            out = str(int(float(rep.json()["data"]["monitors"][i]["lines"][0]["departures"]["departure"][0]["departureTime"]["countdown"])))

        abfahrten.append(out)

    # cosmetics
    linien = [s.strip() for s in linien]
    linien = [s.strip() for s in linien]
    haltestellen = [s.strip() for s in haltestellen]
    haltestellen = [s.upper() for s in haltestellen]
    endstationen = [s.strip() for s in endstationen]
    endstationen = [s.title() for s in endstationen]
    data = [linien, haltestellen, endstationen, abfahrten, n_monitors]
    return data

def build_rows(linien, haltestellen, endstationen, abfahrten, linien_colors):
    # build boards

    # first box width depends on the longest linie
    nchar_longest_line = [len(s) for s in linien]
    nchar_longest_line = max(nchar_longest_line)
    first_box_width = nchar_longest_line * 6 - (nchar_longest_line - 1)

    nchar_longest_abfahrt = [len(s) for s in abfahrten]
    nchar_longest_abfahrt = max(nchar_longest_abfahrt)
    last_box_width = nchar_longest_abfahrt * 5 - (nchar_longest_abfahrt - 2)

    rows = []
    for i in range(len(linien)):
        # Calculate how wide each box must be
        width_line_box = len(linien[i]) * 6 - (len(linien[i]) - 1)
        width_zwibo_one = max(first_box_width - width_line_box + 1, 1)
        width_first_box = width_line_box + width_zwibo_one
        width_abfahrten_box = len(abfahrten[i]) * 5 - (len(abfahrten[i]) - 2)
        width_zwibo_two = max(last_box_width - width_abfahrten_box + 2, 1)
        width_marquee_box = 64 - (width_line_box + width_abfahrten_box + width_zwibo_one + width_zwibo_two)

        # Header Row: Logo and Stop-Name
        if i == 0:
            row = render.Row(
                children = [
                    render.Box(width = width_first_box, height = 8, child = render.Row(children = [
                        render.Image(src = base64.decode(WL_ICON_8_x_8)),
                    ])),
                    render.Box(width = 64 - (width_first_box), height = 8, child = render.Row(children = [
                        render.Text(haltestellen[i], font = "tb-8"),
                    ])),
                ],
            )
            rows.append(row)

        # Monitor Rows: Line, Destination, Next Departure-Times
        row = render.Row(
            children = [
                render.Box(width = width_first_box, height = 8, child = render.Row(children = [
                    render.Text(linien[i], color = linien_colors[i], font = "tb-8"),
                ])),
                render.Box(width = width_marquee_box, height = 8, child = render.Row(children = [
                    render.Marquee(render.Text(endstationen[i], font = "tb-8"), width = 30, align = "center", delay = 60),
                ])),
                render.Box(width = width_zwibo_two, height = 1),
                render.Box(width = width_abfahrten_box, height = 8, child = render.Row(children = [
                    render.Text(abfahrten[i], color = "#FF0000", font = "tb-8"),
                ])),
            ],
        )
        rows.append(row)

    return rows

def main(config):
    # Get all stopps from config
    stopps1 = config.get("stopps1", DEFAULT_STOPPS)
    stopps2 = config.get("stopps2", " ")
    stopps3 = config.get("stopps3", " ")
    stopps4 = config.get("stopps4", " ")

    # Get stopps into correct format so API request can properly deal with them
    combined = [stopps1, stopps2, stopps3, stopps4]
    combined_wo_empty = [value for value in combined if value != " "]
    final_stopps = ",".join(combined_wo_empty)
    stopps = final_stopps.split(",")

    # Get data for desired stopps
    data = get_data(stopps)

    linien = data[0]
    haltestellen = data[1]
    endstationen = data[2]
    abfahrten = data[3]
    linien_colors = get_linien_colors(linien)
    n_monitors = data[4]

    # Order alphabetically by Haltestelle
    combined_lists = list(zip(endstationen, abfahrten, linien_colors, linien, haltestellen))
    sorted_combined_lists = sorted(combined_lists, key = lambda x: x[4])
    endstationen, abfahrten, linien_colors, linien, haltestellen = zip(*sorted_combined_lists)

    # For each unique stop, store how many monitors are available
    monitors_per_stop = {}

    for hs in haltestellen:
        if hs not in monitors_per_stop:
            monitors_per_stop[hs] = 1
        else:
            monitors_per_stop[hs] += 1

    breaks = [0]
    for (_, value) in monitors_per_stop.items():
        breaks.append(value)

    cumulative_breaks = []
    cumulative_sum = 0
    for num in breaks:
        cumulative_sum += num
        cumulative_breaks.append(cumulative_sum)

    # Each display will show up to 3 departures but on each display, only one stop will be shown.
    Display = []

    for i in range(len(cumulative_breaks) - 1):
        first = cumulative_breaks[i]
        last = cumulative_breaks[i + 1]

        shown_lines = linien[first:last]
        show_haltestellen = haltestellen[first:last]
        shown_endtstationen = endstationen[first:last]
        schonw_abfahrten = abfahrten[first:last]
        shown_line_colors = linien_colors[first:last]

        n_shown_lines = len(shown_lines)

        for z in range(0, n_shown_lines, N_DISPLAYED_STOPPS):
            first = z
            last = min(z + (N_DISPLAYED_STOPPS - 1), n_monitors - 1) + 1
            Display.extend([
                render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children =
                        build_rows(shown_lines[first:last], show_haltestellen[first:last], shown_endtstationen[first:last], schonw_abfahrten[first:last], shown_line_colors[first:last]),
                ),
            ])

    return render.Root(
        show_full_animation = True,
        delay = int(config.get("switch_speed", DEFAULT_SWITCH_SPEED)),
        child = render.Animation(children = Display),
    )

def get_linien_colors(linien):
    # Hard-coded colors for each line
    linien_colors = []

    for linie in linien:
        if "N" in linie:
            linien_colors.append("#EADF17")
        elif "A" in linie:
            linien_colors.append("#000178")
        elif "S" in linie:
            linien_colors.append("#1DA4DE")
        elif linie == "U1":
            linien_colors.append("#FF0000")
        elif linie == "U2":
            linien_colors.append("#A02CEB")
        elif linie == "U3":
            linien_colors.append("#EF7B00")
        elif linie == "U4":
            linien_colors.append("#36A142")
        elif linie == "U5":
            linien_colors.append("#06DAED")
        elif linie == "U6":
            linien_colors.append("#862006")
        else:
            linien_colors.append("#FF0000")

    return linien_colors

# Gets all available Stopps of the Wiener Linien
def get_all_haltestellen():
    # get all stopps
    # This can be cached for a week as the stopps are not expected to change
    haltestellen = http.get("https://www.wienerlinien.at/ogd_realtime/doku/ogd/wienerlinien-ogd-haltepunkte.csv", ttl_seconds = 86400 * 7).body()

    # tidy up the data
    # data = [line.split(";") for line in haltestellen.strip().split("\r\n")]
    # columns = data[0]
    # rows = data[1:]

    # create a dictionary that stores all stopIDs for each haltestelle
    haltestellen_dict = {}

    for line in haltestellen.strip().split("\r\n"):
        columns = line.split(";")
        stopID = columns[0]
        diva = columns[1]
        haltestelle = columns[2]
        municipality = columns[3]

        # Some stopps are unnecessary or flawed
        if municipality != "Wien" or haltestelle == "" or diva == "" or haltestelle == "A2":
            continue

        if haltestelle not in haltestellen_dict:
            haltestellen_dict[haltestelle] = set()

        haltestellen_dict[haltestelle].add(stopID)

    # Sort dictionary alphabetically and add 'Keine' option
    haltestellen_dict = dict(sorted(haltestellen_dict.items(), key = lambda item: item[0]))
    haltestellen_dict["Keine"] = set()
    haltestellen_dict["Keine"].add(" ")

    # Create and return schema Options
    haltestellenOptions = [schema.Option(display = haltestellen_dict.keys()[i], value = ",".join(haltestellen_dict[haltestellen_dict.keys()[i]])) for i in range(len(haltestellen_dict))]
    return haltestellenOptions

def get_schema():
    haltestellenOptions = get_all_haltestellen()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "stopps1",
                name = "Haltestellen",
                desc = "Welche Haltestellen sollen angezeigt werden?",
                icon = "train",
                default = "4111,4118,4906,4911",  # Stephansplatz
                options = haltestellenOptions,
            ),
            schema.Dropdown(
                id = "stopps2",
                name = "Haltestellen",
                desc = "Welche Haltestellen sollen angezeigt werden?",
                icon = "train",
                default = " ",
                options = haltestellenOptions,
            ),
            schema.Dropdown(
                id = "stopps3",
                name = "Haltestellen",
                desc = "Welche Haltestellen sollen angezeigt werden?",
                icon = "train",
                default = " ",
                options = haltestellenOptions,
            ),
            schema.Dropdown(
                id = "stopps4",
                name = "Haltestellen",
                desc = "Welche Haltestellen sollen angezeigt werden?",
                icon = "train",
                default = " ",
                options = haltestellenOptions,
            ),
            schema.Dropdown(
                id = "switch_speed",
                name = "Animations-Geschwindigkeit",
                desc = "Wie schnell soll zwischen den Abzeigen gewechselt werden?",
                icon = "clock",
                default = "5000",
                options = [
                    schema.Option(display = "Langsam", value = "7000"),  # delay in milliseconds. How long until next departures are shown
                    schema.Option(display = "Normal", value = "5000"),
                    schema.Option(display = "Schnell", value = "3000"),
                ],
            ),
        ],
    )
