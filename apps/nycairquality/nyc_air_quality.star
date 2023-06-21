"""
Applet: NYC Air Quality
Summary: PM2.5 Readings in NYC
Description: View real-time air quality readings from the NYS DEC.
Author: theterg
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/csv.star", "csv")
load("encoding/base64.star", "base64")
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

NYC_DATA_URL = "https://azdohv2staticweb.blob.core.windows.net/$web/nyccas_realtime_DEC.csv"

def main(config):
    rep = http.get(NYC_DATA_URL, ttl_seconds = 60*30) # cache for 30 minutes
    if rep.status_code != 200:
        fail("Data request failed with status %d", rep.status_code)
    data = csv.read_all(rep.body())
    default_loc = data[-1][0]
    loc = config.str("location", "")
    if len(loc) == 0:
        loc = default_loc
    vals = []
    idx = 0
    for row in data:
        if row[0] == loc:
            vals.append((idx, float(row[4])-35.0))
            idx = idx + 1

    # for development purposes: check if result was served from cache or not
    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling API.")

    window = int(config.get("window", "64"))

    start = len(vals)-window
    end = len(vals)
    if start < 0:
        start = 0

    if len(vals) > 0:
        plot = render.Plot(
            data = vals,
            width = 64,
            height = 24,
            color = '#f00',
            color_inverted = '#0f0',
            x_lim = (start, end),
        )
        val = float(vals[-1][1])
        if val < 35.0:
            icon = render.Image(src=HAPPY_ICON)
            color = '#00FF00'
        elif val < 70.0:
            icon = render.Image(src=SAD_ICON)
            color = '#FFFF00'
        else:
            icon = render.Image(src=FIRE_ICON)
            color = '#FF0000'
        value_text = render.Text('{}'.format(int(vals[-1][1]+35.0)), color=color)
    else:
        plot = render.Text('No Data')
        value_text = render.Text('For '+loc)


    return render.Root(
        child = render.Box(
            render.Column(
                expanded=True,
                main_align="space_evenly",
                cross_align="center",
                children = [
                    plot,
                    render.Row(
                        expanded=True,
                        main_align="space_evenly",
                        cross_align="center",
                        children = [
                            render.Text('PM2.5:'),
                            value_text,
                            icon,
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    rep = http.get(NYC_DATA_URL, ttl_seconds = 60*30) # cache for 30 minutes
    if rep.status_code != 200:
        fail("Data request failed with status %d", rep.status_code)
    data = csv.read_all(rep.body())
    locs = {}
    for row in data[1:]:
        locs[row[0]] = schema.Option(
            display=row[0].replace('_', ' '),
            value=row[0],
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
