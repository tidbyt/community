"""
Applet: NYC Air Quality
Summary: PM2.5 Readings in NYC
Description: View real-time air quality readings from the NYS DEC.
Author: theterg
"""

load("encoding/base64.star", "base64")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

HAPPY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAdnJLH8AAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAADxJREFUCNd1jsENACAIA68sw/7jOE19EI2RcD9awiEAsJODtAB96e3Czlp5UzuDAfU7RVzbJ6fLa9T07gZq2RcwVyfDZwAAAABJRU5ErkJggg==
""")
SAD_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAdnJLH8AAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAEBJREFUCNd1jsENACAMAo8uYxzegZwGH8ZqNPKCKwkVANiFJakDuui+JbXL6QOozSeqzUDwkbI7NzPGzO+4fu8O/zogbgaWd6IAAAAASUVORK5CYII=
""")
ANGRY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAdnJLH8AAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAD5JREFUCNd1jsENACAIAw/jekzrgPioEoKxzystNQAInCtjAdZoeiNwnVQa+FAiPVHA3h5p1od9SAudqt/cDR/gE/FK3R00AAAAAElFTkSuQmCC
""")
FIRE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAdnJLH8AAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAEpJREFUCNeFjbENgEAMxKwsk2myAdv9CCz1LROYIoCeBlydpbsEbqRYCL6Rcrx2sYoUY2+NFoAtr9CNPqLpMT2mpgOp+P+s+dSBE/M3KoxuP5uzAAAAAElFTkSuQmCC
""")
CHECK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAdnJLH8AAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAFdJREFUCNdjZMAE7YEMCaxMWCQSWBkYGJiwKGdgYFjwG0P58zCoHMPzMIbnYRiiDMwMImoMBswMImoMS/QYGBgYPNfCJPbeYBBRg1jIsOA3w94buIyGAgBh6xStspz3cgAAAABJRU5ErkJggg==
""")

CLOUDS = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAWCAYAAABwvpo0AAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAdnJLH8AAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dEAP8A/wD/oL2nkwAAAJ5JREFUWMPtV0EOgCAMo3soj9tH9URiPAADNmBZz0ppaSemFAg0kXN+vGqjE8VbckK6CWaGpnBmRuHW5GoacNKpWxgRWHmSNw1N0oyxphHF6FkOaPd3VYclQiV8dEuttJ5Hz0K7p/BozHv23XUP8PwZgtRlb2ZgNGIjRnwrZVmvWprJupf/d3f/a8Ca0LparSs2ThC/c764T0AgEKjiBY++aaOgJgMNAAAAAElFTkSuQmCC
""")

# This source is derived from a public dashboard provided by the NYS DOH
# https://a816-dohbesp.nyc.gov/IndicatorPublic/beta/key-topics/airquality/realtime/
# It's updated every hour, so there's no need to hit it very often.
NYC_DATA_URL = "https://azdohv2staticweb.blob.core.windows.net/$web/nyccas_realtime_DEC.csv"

def hex_2B(val):
    nibble = (val & 0xF0) >> 4
    if nibble < 10:
        ret = chr(ord("0") + nibble)
    else:
        ret = chr(ord("a") + (nibble - 10))
    nibble = (val & 0x0F)
    if nibble < 10:
        ret += chr(ord("0") + nibble)
    else:
        ret += chr(ord("a") + (nibble - 10))
    return ret

def rgb(r, g, b):
    return "#" + hex_2B(r) + hex_2B(g) + hex_2B(b)

def main(config):
    rep = http.get(NYC_DATA_URL, ttl_seconds = 60 * 30)  # cache for 30 minutes
    if rep.status_code != 200:
        fail("Data request failed with status %d", rep.status_code)
    data = csv.read_all(rep.body())

    # The first row is a CSV header: SiteName, Operator, starttime, timeofday, Value
    # We'll use the first entry as the default location
    default_loc = data[1][0]
    loc = config.str("location", "")

    # While debugging it's possible to supply a blank string
    # So let's reject it and use the default if so:
    if len(loc) == 0:
        loc = default_loc

    # Read through the dataset and only extract data points matching the location
    vals = []
    idx = 0
    for row in data:
        if row[0] == loc:
            # NOTE: subtracting 35 to place 35um at the y axis crossing
            # This will format the plot such that values over the limit are colored red
            vals.append((idx, float(row[4]) - 35.0))
            idx = idx + 1

    # for development purposes: check if result was served from cache or not
    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling API.")

    # Allow users to specify a number of points to plot
    # It looks nicer to be zoomed out, but gives less resolution
    # default of 64 should be one pixel per datapoint - perfect!
    window_str = config.get("window", "63")

    # Also gracefully handle invalid window values
    if len(window_str) == 0 or not window_str.isdigit():
        window_str = "63"
    window = int(window_str)
    start = len(vals) - window
    end = len(vals)
    if start < 0:
        start = 0

    # If we retrieved good data...
    if len(vals) > 0:
        # Render the background accordfing to the most recent value
        val = float(vals[-1][1]) + 35.0  # Adding 35 back to compensate for shift applied above
        if val < 35.0:
            # Below 35 is all good
            icon = render.Image(src = HAPPY_ICON)
            color = "#00FF00"
            cloudcolor = rgb(0, 0, 70)
        elif val < 70.0:
            # fade to white background
            icon = render.Image(src = SAD_ICON)
            color = "#FFFF00"
            cloudcolor = rgb(int(val - 35) * 2, int(val - 35) * 2, 70)
        elif val < 105.0:
            # fade to red background
            icon = render.Image(src = ANGRY_ICON)
            color = "#FF6F00"
            cloudcolor = rgb(70 + int(val - 70) * 2, 70, 70)
        else:
            # red background, angry, bad
            icon = render.Image(src = FIRE_ICON)
            color = "#FF0000"
            cloudcolor = rgb(110, 35, 35)
        plot = render.Plot(
            data = vals,
            width = 64,
            height = 24,
            color = "#f00",
            color_inverted = "#0f0",
            x_lim = (start, end),
        )

        # Overlay plot on top of clouds and colored background
        plot = render.Stack(
            children = [
                render.Box(color = cloudcolor, width = 64, height = 24),
                render.Image(src = CLOUDS),
                plot,
            ],
        )
        value_text = render.Text("{}".format(int(val)), color = color)
    else:
        # If no data is available, we cannot draw the plot
        # Display error text
        plot = render.Text("No Data")
        value_text = render.Text("??")
        icon = render.Image(src = SAD_ICON)

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    plot,
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text("PM2.5:"),
                            value_text,
                            icon,
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    # Pull the data so we can populate the list of lcoations
    rep = http.get(NYC_DATA_URL, ttl_seconds = 60 * 30)  # cache for 30 minutes
    if rep.status_code != 200:
        fail("Data request failed with status %d", rep.status_code)
    data = csv.read_all(rep.body())

    # Iterate over all rows, extract each unique SiteName
    locs = {}
    for row in data[1:]:
        locs[row[0]] = schema.Option(
            display = row[0].replace("_", " "),
            value = row[0],
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "location",
                name = "Site Name",
                desc = "Display this location from within the NYC dataset",
                icon = "locationDot",
                default = locs.keys()[-1],
                options = locs.values(),
            ),
            schema.Text(
                id = "window",
                name = "Window Size",
                desc = "Number of datapoints to display",
                icon = "chartSimple",
            ),
        ],
    )
