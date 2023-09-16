"""
Applet: Divvy
Summary: Divvy Bike availability
Description: Shows the availability of bikes and e-bikes at a Divvy Bike station.
Author: Andy Day (@adayNU)
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

STATIONS_URL = "https://gbfs.lyft.com/gbfs/1.1/chi/en/station_information.json"
STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/1.1/chi/en/station_status.json"
DEFAULT_STATION = '{"id":"1789242536879942642","name":"Halsted St & Fulton St"}'
LYFT_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAADIAAAAiCAYAAAAd6YoqAAAAAXNSR0IArs4c6QAAA4RJREFUWEf
tmEtoE1EUhv8zqW3TSaqgmRQEX1ARFEHt1kWhYgURsStRKIjoQhExY3WjC3etE1BRsIjgQhFEty
pCRdy40IpYxUUVbRZqZyw+p7WPzJFJOyVN53EnSR9gZ5fMeX3n3HPvmUu6nP4I8Cq4PAx0JU21y
e1dOf/T5Y5mQHrgZZNAmYSZWunnk+YSxIilG5n5sWhSGBhJmmqVm/ycgejxjq2wpKeiEPlyiqlS
od6cgPTLF5KEsa/FQNg6DMokC5baHIFobwhYXyyIrRchacPSPyfeOjZmHcSQtZsM7CsFYjL4aLY
28e3Ub/v3rIIw7kQMOTMWADFEwGsGFgNY57tTAV2JiV1VCESXNfYz6DSfIWujDFS47ipA2mLuJa
KrPrY+K6a63HnfL2vbCHgkUr1ZBWFQI8CbvQOj64qZOui8ZzAZctqajyAtXofvRLDHFVO9mB940
GoI1exBxkSXFoP+FxDqJvATJ8sJU1WDkjhfKzKlHexKL4Dkp8SZfoOyUsYeCV0Rx/dsb79Bzb4A
slCR/DWQMFdUfY9+qRuTRvu8TmEC0kHnCIMHCFJuCLQfxUytNmrOn2Gic76ne8RaW5aKCI0QAiA
App3sxrL2OA9FfgX5sPfplwA2uQvSJzsrQbtWkJPcmC0EYm1SzLZXhfZ0+fwDgJp9J2FD1toZaP
MSCnMo+ToSAEmY8UrC4dFCO/0xbQ8x7gXYB/wyTtFsLQ9FMgCWiGS+2B4h4FbCVPd76eux9Acwr
/GxHwACdFG11GoNW+/AiBcL47e0CBjpM+OxBpdqTJ2E088BbnCLIXcboddol0E44re8cnKyNggg
WgwMMZ9lkg64j/H0UDFTO0TsesU6ea3SH0u3EPNdj6bvydLo3gqrMmpJ2Z3EUmt+QAzcAHEfMZ0
G4HrvxLC2EyKdBSC9YDquDKbui0A4MkaNtoUl7AZjF4CNE5vJVBNu+7Yzz7xA5yKv8uuy9t2vj3
6aldWLa/+uAKOOQWPJ3yefhQneT7YXl6qmXXT5KeiyZn8/bwPQA2DAvmIiUJzHP18lT13Ce+WPW
l+uwD17RNRBHoioyrhcxFqr/GrrDacUTrrYioTy4nbFGcqAgPDMgzCuKIPqUYFYShKZURC7wetx
bLikCAWVZwzEYj5UN3jymmAcJYuFAskdirUd9chKtwFsKfD+gyrQlPipdpccVREG/gEqbUdcVOb
8sQAAAABJRU5ErkJggg==
""")

def main(config):
    resp = http.get(STATION_STATUS_URL, ttl_seconds = 60)
    if resp.status_code != 200:
        fail("gbfs status request failed with status %d", resp.status_code)

    station_data = resp.json()["data"]["stations"]
    station = json.decode(config.get("station_id", DEFAULT_STATION))

    text = ""

    for _index, value in enumerate(station_data):
        if value["station_id"] == station["id"]:
            text = "Bikes:" + str(int(value["num_bikes_available"] - value["num_ebikes_available"])) + "\nE-Bikes:" + str(int(value["num_ebikes_available"]))
            break

    return render.Root(
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(station["name"]),
                        ),
                        render.Box(width = 64, height = 1, color = "#4338ca"),
                    ],
                ),
                render.Box(
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = LYFT_ICON, width = 20),
                            render.WrappedText(content = text, font = "tb-8"),
                        ],
                    ),
                ),
            ],
        ),
    )

def toOption(station):
    return schema.Option(
        display = station["name"],
        value = '{"id":"' + station["station_id"] + '", "name":"' + station["name"] + '"}',
    )

def get_schema():
    resp = http.get(STATIONS_URL, ttl_seconds = 60 * 60 * 24)
    if resp.status_code != 200:
        fail("gbfs station request failed with status %d", resp.status_code)

    options = sorted([toOption(x) for x in resp.json()["data"]["stations"]], key = lambda x: x.display)

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station_id",
                name = "Station",
                desc = "Which station's data to show",
                icon = "bicycle",
                default = options[0].value,
                options = options,
            ),
        ],
    )
