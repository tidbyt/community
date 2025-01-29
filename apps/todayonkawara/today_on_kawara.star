"""
Applet: Today - On Kawara
Summary: Display today's date
Description: Shows today's date in multiple languages and formats inspired by On Kawara's date paintings.
Author: Joshua Nuesca
"""

load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

month_dict_en = {1: "JAN.", 2: "FEB.", 3: "MAR.", 4: "APR.", 5: "MAY", 6: "JUN.", 7: "JUL.", 8: "AUG.", 9: "SEPT.", 10: "OCT.", 11: "NOV.", 12: "DEC."}
month_dict_fr = {1: "JANV.", 2: "F\u00C3\u0089VR.", 3: "MARS.", 4: "AVRIL", 5: "MAI", 6: "JUIN", 7: "JUIL.", 8: "AO\u00C3\u009BT", 9: "SEPT.", 10: "OCT.", 11: "NOV.", 12: "D\u00C3\u0089C."}
month_dict_eo = {1: "JAN.", 2: "FEB.", 3: "MAR.", 4: "APR.", 5: "MAJ.", 6: "JUN.", 7: "JUL.", 8: "A\u00C5\u00ACG.", 9: "SEP.", 10: "OKT.", 11: "NOV.", 12: "DEC."}
month_dict_es = {1: "ENERO", 2: "FEB.", 3: "MARZO", 4: "ABR.", 5: "MAYO", 6: "JUN.", 7: "JUL.", 8: "AGOSTO", 9: "SEPT.", 10: "OCT.", 11: "NOV.", 12: "DIC."}
month_dict_it = {1: "GENN.", 2: "FEBBR.", 3: "MAR.", 4: "APR.", 5: "MAGG.", 6: "GIUGNO", 7: "LUGLIO", 8: "AG.", 9: "SETT.", 10: "OTT.", 11: "NOV.", 12: "DIC."}
month_dict_de = {1: "J\u00C3\u0084N.", 2: "FEB.", 3: "M\u00C3\u0084RZ.", 4: "APR.", 5: "MAI", 6: "JUNI", 7: "JULI", 8: "AUG.", 9: "SEPT.", 10: "OKT.", 11: "NOV.", 12: "DEZ."}
color_dict = {0: "#393A39", 1: "#204054", 2: "#000000", 3: "#2A4A3B"}

default_location = """{"timezone": "America/New_York"}"""

def main(config):
    timezone = json.decode(config.get("location", default_location))["timezone"]

    now = time.now().in_location(timezone)

    payload = ""

    if config.get("background") == "rd":
        bg_color = color_dict[random.number(0, 3)]
    else:
        bg_color = config.get("background", "#000000")
    lang_randomizer = random.number(0, 5)

    if config.get("region", "en") == "en" or (config.get("region") == "rd" and lang_randomizer == 0):
        payload = month_dict_en[now.month] + str(now.day) + "," + str(now.year)
    elif config.get("region") == "fr" or (config.get("region") == "rd" and lang_randomizer == 1):
        payload = str(now.day) + month_dict_fr[now.month] + str(now.year)
    elif config.get("region") == "eo" or (config.get("region") == "rd" and lang_randomizer == 2):
        payload = str(now.day) + month_dict_eo[now.month] + str(now.year)
    elif config.get("region") == "es" or (config.get("region") == "rd" and lang_randomizer == 3):
        payload = str(now.day) + month_dict_es[now.month] + str(now.year)
    elif config.get("region") == "it" or (config.get("region") == "rd" and lang_randomizer == 4):
        payload = str(now.day) + month_dict_it[now.month] + str(now.year)
    elif config.get("region") == "de" or (config.get("region") == "rd" and lang_randomizer == 5):
        payload = str(now.day) + month_dict_de[now.month] + str(now.year)

    return render.Root(
        child = render.Box(
            color = bg_color,
            child = render.Row(
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = payload,
                        font = "tb-8",
                    ),
                ],
            ),
        ),
    )

colors = [
    schema.Option(
        display = "Grey",
        value = "#393A39",
    ),
    schema.Option(
        display = "Blue",
        value = "#204054",
    ),
    schema.Option(
        display = "Black",
        value = "#000000",
    ),
    schema.Option(
        display = "Green",
        value = "#2A4A3B",
    ),
    schema.Option(
        display = "Random",
        value = "rd",
    ),
]

languages = [
    schema.Option(
        display = "English",
        value = "en",
    ),
    schema.Option(
        display = "French",
        value = "fr",
    ),
    schema.Option(
        display = "Esperanto",
        value = "eo",
    ),
    schema.Option(
        display = "Spanish",
        value = "es",
    ),
    schema.Option(
        display = "Italian",
        value = "it",
    ),
    schema.Option(
        display = "German",
        value = "de",
    ),
    schema.Option(
        display = "Random",
        value = "rd",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Language and date format",
                desc = "The language and format of the date to be displayed.",
                icon = "language",
                default = languages[0].value,
                options = languages,
            ),
            schema.Dropdown(
                id = "background",
                name = "Background color",
                desc = "The background color behind the displayed date.",
                icon = "bucket",
                default = colors[2].value,
                options = colors,
            ),
        ],
    )
