"""
Applet: DigiByte Price
Summary: Display DigiByte Price
Description: Displays the current DigiByte price in one or two fiat currencies and/or in Satoshis. Data provided by CoinGecko. Updated every 10 minutes. If you would like an additional currency supported, pease let me know in the Tidbyt community Discord.
Author: Olly Stedall @saltedlolly
Thanks: drudge, inxi, whyamihere, Amillion Air
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("schema.star", "schema")
load("math.star", "math")

DGB_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAdVJREFUOE9dVFtSw0AMk4HhLNn0iyPRtB/ciBmSnomfNuUqDMSMLG+yIR+ZPNayJD8MvAwwB5wPee8Gd7gDZvA4wjswTw+2nVcsfxGiosRBAcQjMepj5mM2g5vjTsAmdn0prwvzZwoBrVdmDdpBgSzEf74QsDKCowwEMljIEZOIg+E2OvqT4ToCh1OghAGU2wAB3dFJOILnUdQpoTLfmKRtAPozSenM12R0wdANv/yE6ygq/LplTXY7HjKYYJR4vzyYlSMVRclUodTuFsXJq/ovmQ1h9IOKZfQmiqt7glGipzpDGTwrKHCChdVO7xhnsHJcZH/+YARNrW7zV8nDZBu9RAsCR0ABtRpNKVndK+lLflQpPY3327SXXIasPT1ilRRo+Hxf8PxkYB0Y2J8kt9p4m7JZ3VHOapfI31Ha2uk0k3Eyn72jGogq//EDGR6GzcMcEdDMVA/MH3Us1ISkSnPXLkUaHDOohFF+HoiudkfQroZoDmQkQ5xyBZ6jqBo5xyQaUhe9ksliQYPqNvj+WfDy9rh1Vc6PuQXIbtY69lP4Ki/YO2TYZ1UqwShCrhUmupPNukaaZRENGobWdmjCcmcxMvbSvwWxf2UruAa5XUytHy1AXWx/2vAhVoi8DZsAAAAASUVORK5CYII=
""")

SATS_SYMBOL = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAHCAYAAAArkDztAAAAAXNSR0IArs4c6QAAAEJJREFUGFddjsENADEIwxL2nxlXQFv1zq8IxYC1SSAcluiJATr7VCQXM5nWiyH51Eu+htlSLZg8N37Ea5Dg+sq0tAAQLh4KW15wlwAAAABJRU5ErkJggg==
""")

#this list contains the currently supported fiat currencies
CURRENCY_LIST = {
    "AUD": "aud",
    "CAD": "cad",
    "EUR": "eur",
    "GBP": "gbp",
    "USD": "usd",
}

# Set applet defaults
DEFAULT_FIRST_CURRENCY = "USD"
DEFAULT_SECOND_CURRENCY = "EUR"
DEFAULT_SHOW_FIRST_CURRENCY = True
DEFAULT_SHOW_SECOND_CURRENCY = False
DEFAULT_SHOW_SATS = True
DEFAULT_SHOW_COUNTRY = True

def get_schema():
    currency_options = [
        schema.Option(display = currency, value = currency)
        for currency in CURRENCY_LIST
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "first_currency",
                name = "Currency A",
                desc = "Choose a fiat currency to display the price in.",
                icon = "circle-dollar",
                default = DEFAULT_FIRST_CURRENCY,
                options = currency_options,
            ),
            schema.Dropdown(
                id = "second_currency",
                name = "Currency B",
                desc = "Choose a second fiat currency to display the price in.",
                icon = "circle-dollar",
                default = DEFAULT_SECOND_CURRENCY,
                options = currency_options,
            ),
            schema.Toggle(
                id = "first_currency_toggle",
                name = "Display Currency A",
                desc = "Toggle displaying Currency A.",
                icon = "toggle-on",
                default = DEFAULT_SHOW_FIRST_CURRENCY,
            ),
            schema.Toggle(
                id = "second_currency_toggle",
                name = "Display Currency B",
                desc = "Toggle displaying Currency B.",
                icon = "toggle-on",
                default = DEFAULT_SHOW_SECOND_CURRENCY,
            ),
            schema.Toggle(
                id = "sats_toggle",
                name = "Display SATS",
                desc = "Toggle displaying price in SATS.",
                icon = "toggle-on",
                default = DEFAULT_SHOW_SATS,
            ),
            schema.Toggle(
                id = "country_toggle",
                name = "Display Country",
                desc = "Toggle displaying country code. Useful when displaying two dollar currencies together (e.g. USD and AUD).",
                icon = "toggle-on",
                default = DEFAULT_SHOW_COUNTRY,
            ),
        ],
    )

def main(config):
    DIGIBYTE_PRICE_URL = "https://api.coingecko.com/api/v3/simple/price?ids=digibyte&vs_currencies=aud%2Ccad%2Ceur%2Cgbp%2Csats%2Cusd"

    first_currency = CURRENCY_LIST.get(config.get("first_currency"), CURRENCY_LIST[DEFAULT_FIRST_CURRENCY])
    second_currency = CURRENCY_LIST.get(config.get("second_currency"), CURRENCY_LIST[DEFAULT_SECOND_CURRENCY])
    first_currency_toggle = config.bool("first_currency_toggle", DEFAULT_FIRST_CURRENCY)
    second_currency_toggle = config.bool("second_currency_toggle", DEFAULT_SECOND_CURRENCY)
    sats_toggle = config.bool("sats_toggle", DEFAULT_SHOW_SATS)
    country_toggle = config.bool("country_toggle", DEFAULT_SHOW_COUNTRY)

    # LOOKUP CURRENT PRICES (OR RETRIEVE FROM CACHE)

    # Get current prices from cache
    dgb_price_aud_cached = cache.get("dgb_price_aud")
    dgb_price_cad_cached = cache.get("dgb_price_cad")
    dgb_price_eur_cached = cache.get("dgb_price_eur")
    dgb_price_gbp_cached = cache.get("dgb_price_gbp")
    dgb_price_sats_cached = cache.get("dgb_price_sats")
    dgb_price_usd_cached = cache.get("dgb_price_usd")

    if dgb_price_usd_cached != None:
        print("Hit! Displaying cached data.")
        dgb_price_aud = float(dgb_price_aud_cached)
        dgb_price_cad = float(dgb_price_cad_cached)
        dgb_price_eur = float(dgb_price_eur_cached)
        dgb_price_gbp = float(dgb_price_gbp_cached)
        dgb_price_sats = float(dgb_price_sats_cached)
        dgb_price_usd = float(dgb_price_usd_cached)
    else:
        print("Miss! Calling CoinGecko API.")
        dgbquery = http.get(DIGIBYTE_PRICE_URL)
        if dgbquery.status_code != 200:
            fail("Coingecko request failed with status %d", dgbquery.status_code)

        dgb_price_aud = dgbquery.json()["digibyte"]["aud"]
        dgb_price_cad = dgbquery.json()["digibyte"]["cad"]
        dgb_price_eur = dgbquery.json()["digibyte"]["eur"]
        dgb_price_gbp = dgbquery.json()["digibyte"]["gbp"]
        dgb_price_sats = dgbquery.json()["digibyte"]["sats"]
        dgb_price_usd = dgbquery.json()["digibyte"]["usd"]

        # Store prices in cache
        cache.set("dgb_price_aud", str(dgb_price_aud), ttl_seconds = 600)
        cache.set("dgb_price_cad", str(dgb_price_cad), ttl_seconds = 600)
        cache.set("dgb_price_eur", str(dgb_price_eur), ttl_seconds = 600)
        cache.set("dgb_price_gbp", str(dgb_price_gbp), ttl_seconds = 600)
        cache.set("dgb_price_sats", str(dgb_price_sats), ttl_seconds = 600)
        cache.set("dgb_price_usd", str(dgb_price_usd), ttl_seconds = 600)

    #Setup price display variable
    display_vec = []

    # Check for catastrophic data failure (i.e. failed to get data from CoinGecko and no cache data is available to fall back on)
    if dgb_price_usd != None:
        data_available = True
    else:
        data_available = False
        display_error = render.Row(
            children = [
                render.Text("ERROR:", font = "CG-pixel-3x5-mono", color = "#FF0000"),
                render.Text("Coingecko", font = "CG-pixel-3x5-mono"),
                render.Text("unvailable!", font = "CG-pixel-3x5-mono"),
            ],
        )
        display_vec.append(display_error)
        print("Error: No price data available")

    # Setup first currency price
    if first_currency_toggle and data_available:
        if first_currency == "aud":
            first_currency_price = dgb_price_aud
            first_currency_symbol = "$"
            first_currency_country = "AU"
            print("Displaying AUD price (Currency A)")
        elif first_currency == "cad":
            first_currency_price = dgb_price_cad
            first_currency_symbol = "$"
            first_currency_country = "CA"
            print("Displaying CAD price (Currency A)")
        elif first_currency == "eur":
            first_currency_price = dgb_price_eur
            first_currency_symbol = "€"
            first_currency_country = "EU"
            print("Displaying EUR price price (Currency A)")
        elif first_currency == "gbp":
            first_currency_price = dgb_price_gbp
            first_currency_symbol = "£"
            first_currency_country = "UK"
            print("Displaying GBP price (Currency A)")
        elif first_currency == "usd":
            first_currency_price = dgb_price_usd
            first_currency_symbol = "$"
            first_currency_country = "US"
            print("Displaying USD price (Currency A)")

        # Round price to nearest whole number (used to decide how many decimal places to leave)
        first_currency_price_integer = str(int(math.round(float(first_currency_price))))

        # Trim and format price
        if len(first_currency_price_integer) <= 1:
            first_currency_price = str(int(math.round(first_currency_price * 1000)))
            if len(first_currency_price) < 4:
                first_currency_price = "0" + first_currency_price
            if len(first_currency_price) < 4:
                first_currency_price = "0" + first_currency_price
            if len(first_currency_price) < 4:
                first_currency_price = "0" + first_currency_price
            if len(first_currency_price) < 4:
                first_currency_price = "0" + first_currency_price
            first_currency_price = (first_currency_symbol + first_currency_price[0:-3] + "." + first_currency_price[-3:])
        elif len(first_currency_price_integer) == 2:
            first_currency_price = str(int(math.round(first_currency_price * 1000)))
            first_currency_price = (first_currency_symbol + first_currency_price[0:-3] + "." + first_currency_price[-3:])
        elif len(first_currency_price_integer) == 3:
            first_currency_price = str(int(math.round(first_currency_price * 100)))
            first_currency_price = (first_currency_symbol + first_currency_price[0:-2] + "." + first_currency_price[-2:])
        elif len(first_currency_price_integer) == 4:
            first_currency_price = str(int(math.round(first_currency_price * 10)))
            first_currency_price = (first_currency_symbol + first_currency_price[0:-1] + "." + first_currency_price[-1:])
        elif len(first_currency_price_integer) == 5 or 6:
            first_currency_price = str(int(math.round(first_currency_price)))
            first_currency_price = (first_currency_symbol + first_currency_price)
        elif len(first_currency_price_integer) >= 7:
            first_currency_price = str(int(math.round(first_currency_price)))
            first_currency_price = (first_currency_symbol + first_currency_price)
            country_toggle = False

        if country_toggle:
            display_first_currency_price = render.Row(
                cross_align = "center",
                children = [
                    render.Text("%s" % first_currency_price),
                    render.Box(width = 1, height = 1),
                    render.Text("%s" % first_currency_country, font = "CG-pixel-3x5-mono", color = "#2962fe"),
                ],
            )
        else:
            display_first_currency_price = render.Text("%s" % first_currency_price)

        display_vec.append(display_first_currency_price)

    # Setup second currency price (if there is data available)
    if second_currency_toggle and data_available:
        if second_currency == "aud":
            second_currency_price = dgb_price_aud
            second_currency_symbol = "$"
            second_currency_country = "AU"
            print("Displaying AUD price (Currency B)")
        elif second_currency == "cad":
            second_currency_price = dgb_price_cad
            second_currency_symbol = "$"
            second_currency_country = "CA"
            print("Displaying CAD price (Currency B)")
        elif second_currency == "eur":
            second_currency_price = dgb_price_eur
            second_currency_symbol = "€"
            second_currency_country = "EU"
            print("Displayimg EUR price (Currency B)")
        elif second_currency == "gbp":
            second_currency_price = dgb_price_gbp
            second_currency_symbol = "£"
            second_currency_country = "UK"
            print("Displaying GBP price (Currency B)")
        elif second_currency == "usd":
            second_currency_price = dgb_price_usd
            second_currency_symbol = "$"
            second_currency_country = "US"
            print("Displaying USD price (Currency B)")

        # Round price to nearest whole number (used to decide how many decimal places to leave)
        second_currency_price_integer = str(int(math.round(float(second_currency_price))))

        # Trim and format price
        if len(second_currency_price_integer) <= 1:
            second_currency_price = str(int(math.round(second_currency_price * 1000)))
            if len(second_currency_price) < 4:
                second_currency_price = "0" + second_currency_price
            if len(second_currency_price) < 4:
                second_currency_price = "0" + second_currency_price
            if len(second_currency_price) < 4:
                second_currency_price = "0" + second_currency_price
            if len(second_currency_price) < 4:
                second_currency_price = "0" + second_currency_price
            second_currency_price = (second_currency_symbol + second_currency_price[0:-3] + "." + second_currency_price[-3:])
        elif len(second_currency_price_integer) == 2:
            second_currency_price = str(int(math.round(second_currency_price * 1000)))
            second_currency_price = (second_currency_symbol + second_currency_price[0:-3] + "." + second_currency_price[-3:])
        elif len(second_currency_price_integer) == 3:
            second_currency_price = str(int(math.round(second_currency_price * 100)))
            second_currency_price = (second_currency_symbol + second_currency_price[0:-2] + "." + second_currency_price[-2:])
        elif len(second_currency_price_integer) == 4:
            second_currency_price = str(int(math.round(second_currency_price * 10)))
            second_currency_price = (second_currency_symbol + second_currency_price[0:-1] + "." + second_currency_price[-1:])
        elif len(second_currency_price_integer) == 5 or 6:
            second_currency_price = str(int(math.round(second_currency_price)))
            second_currency_price = (second_currency_symbol + second_currency_price)
        elif len(second_currency_price_integer) >= 7:
            second_currency_price = str(int(math.round(second_currency_price)))
            second_currency_price = (second_currency_symbol + second_currency_price)
            country_toggle == False

        if country_toggle:
            display_second_currency_price = render.Row(
                cross_align = "center",
                children = [
                    render.Text("%s" % second_currency_price),
                    render.Box(width = 1, height = 1),
                    render.Text("%s" % second_currency_country, font = "CG-pixel-3x5-mono", color = "#FF0000"),
                ],
            )
        else:
            display_second_currency_price = render.Text("%s" % second_currency_price)

        display_vec.append(display_second_currency_price)

    # Display message in log if Country toggle is enabled
    if country_toggle and (first_currency_toggle or second_currency_toggle):
        print("Displaying Country")

    # Setup sats price (trim and format)

    if sats_toggle and data_available:
        dgb_price_sats = str(int(math.round(dgb_price_sats * 100)))
        dgb_price_sats = (dgb_price_sats[0:-2] + "." + dgb_price_sats[-2:])
        display_sats_price = render.Row(
            children = [
                render.Image(src = SATS_SYMBOL),
                render.Text("%s" % dgb_price_sats),
            ],
        )
        display_vec.append(display_sats_price)
        print("Displaying SATS price")

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = DGB_ICON),

                    # Column to hold pricing text evenly distrubuted accross 1-3 rows
                    render.Column(
                        main_align = "space_evenly",
                        expanded = True,
                        children = display_vec,
                    ),
                ],
            ),
        ),
    )
