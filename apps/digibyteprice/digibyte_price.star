"""
Applet: DigiByte Price
Summary: Display DigiByte Price
Description: Displays the current DigiByte price in one or two fiat currencies and/or in Satoshis. Data provided by CoinGecko. Updated every 10 minutes. If you would like an additional currency supported, pease let me know in the Tidbyt community Discord.
Author: Olly Stedall @saltedlolly
Thanks: drudge, inxi, whyamihere, Amillion Air
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

print("----------------------------------------------------------------------------------------")

DGB_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAdVJREFUOE9dVFtSw0AMk4HhLNn0iyPRtB/ciBmSnomfNuUqDMSMLG+yIR+ZPNayJD8MvAwwB5wPee8Gd7gDZvA4wjswTw+2nVcsfxGiosRBAcQjMepj5mM2g5vjTsAmdn0prwvzZwoBrVdmDdpBgSzEf74QsDKCowwEMljIEZOIg+E2OvqT4ToCh1OghAGU2wAB3dFJOILnUdQpoTLfmKRtAPozSenM12R0wdANv/yE6ygq/LplTXY7HjKYYJR4vzyYlSMVRclUodTuFsXJq/ovmQ1h9IOKZfQmiqt7glGipzpDGTwrKHCChdVO7xhnsHJcZH/+YARNrW7zV8nDZBu9RAsCR0ABtRpNKVndK+lLflQpPY3327SXXIasPT1ilRRo+Hxf8PxkYB0Y2J8kt9p4m7JZ3VHOapfI31Ha2uk0k3Eyn72jGogq//EDGR6GzcMcEdDMVA/MH3Us1ISkSnPXLkUaHDOohFF+HoiudkfQroZoDmQkQ5xyBZ6jqBo5xyQaUhe9ksliQYPqNvj+WfDy9rh1Vc6PuQXIbtY69lP4Ki/YO2TYZ1UqwShCrhUmupPNukaaZRENGobWdmjCcmcxMvbSvwWxf2UruAa5XUytHy1AXWx/2vAhVoi8DZsAAAAASUVORK5CYII=
""")

SATS_SYMBOL = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAHCAYAAAArkDztAAAAAXNSR0IArs4c6QAAAEJJREFUGFddjsENADEIwxL2nxlXQFv1zq8IxYC1SSAcluiJATr7VCQXM5nWiyH51Eu+htlSLZg8N37Ea5Dg+sq0tAAQLh4KW15wlwAAAABJRU5ErkJggg==
""")

#this list contains the currently supported fiat currencies
MAIN_CURRENCY_LIST = {
    "AUD": "aud",
    "CAD": "cad",
    "EUR": "eur",
    "GBP": "gbp",
    "USD": "usd",
    "SATS": "sats",
}

#this list contains the currently supported fiat currencies, plus the None option, for when the currency won't be displayed
ALT_CURRENCY_LIST = {
    "None": "none",
    "AUD": "aud",
    "CAD": "cad",
    "EUR": "eur",
    "GBP": "gbp",
    "USD": "usd",
    "SATS": "sats",
}

# Set applet defaults
DEFAULT_MAIN_CURRENCY = "USD"
DEFAULT_SECOND_CURRENCY = "EUR"
DEFAULT_THIRD_CURRENCY = "SATS"
DEFAULT_SHOW_COUNTRY = True

def get_schema():
    main_currency_options = [
        schema.Option(display = main_currency, value = main_currency)
        for main_currency in MAIN_CURRENCY_LIST
    ]

    alt_currency_options = [
        schema.Option(display = alt_currency, value = alt_currency)
        for alt_currency in ALT_CURRENCY_LIST
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "main_currency",
                name = "Main Currency",
                desc = "Choose the main currency to display the DigiByte price in.",
                icon = "moneyBill",
                default = DEFAULT_MAIN_CURRENCY,
                options = main_currency_options,
            ),
            schema.Dropdown(
                id = "second_currency",
                name = "Second Currency",
                desc = "Choose an additional currency to display the price in.",
                icon = "moneyBill",
                default = DEFAULT_SECOND_CURRENCY,
                options = alt_currency_options,
            ),
            schema.Dropdown(
                id = "third_currency",
                name = "Third Currency",
                desc = "Choose an additional currency to display the price in.",
                icon = "moneyBill",
                default = DEFAULT_THIRD_CURRENCY,
                options = alt_currency_options,
            ),
            schema.Toggle(
                id = "country_toggle",
                name = "Display Country",
                desc = "Toggle displaying country code. Useful when displaying two dollar currencies together (e.g. USD and AUD).",
                icon = "toggleOn",
                default = DEFAULT_SHOW_COUNTRY,
            ),
        ],
    )

def main(config):
    DIGIBYTE_PRICE_URL = "https://api.coingecko.com/api/v3/simple/price?ids=digibyte&vs_currencies=aud%2Ccad%2Ceur%2Cgbp%2Csats%2Cusd"

    main_currency = MAIN_CURRENCY_LIST.get(config.get("main_currency"), MAIN_CURRENCY_LIST[DEFAULT_MAIN_CURRENCY])
    second_currency = ALT_CURRENCY_LIST.get(config.get("second_currency"), ALT_CURRENCY_LIST[DEFAULT_SECOND_CURRENCY])
    third_currency = ALT_CURRENCY_LIST.get(config.get("third_currency"), ALT_CURRENCY_LIST[DEFAULT_THIRD_CURRENCY])
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

    # Format SATS price
    dgb_price_sats = str(int(math.round(dgb_price_sats * 100)))
    dgb_price_sats = (dgb_price_sats[0:-2] + "." + dgb_price_sats[-2:])

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

    # DISPLAY PRICES
    currency = ""
    currency_price = ""
    currency_symbol = ""
    currency_country = ""

    if data_available:
        # Setup each currency
        for i in range(3):
            if i == 0:
                currency = main_currency
                print("Main Currency:")
            if i == 1:
                currency = second_currency
                print("Second Currency:")
            if i == 2:
                currency = third_currency
                print("Third Currency:")

            # Setup currency price
            if currency == "none":
                print("None")
            elif currency == "aud":
                currency_price = dgb_price_aud
                currency_symbol = "$"
                currency_country = "AU"
                print("AUD")
            elif currency == "cad":
                currency_price = dgb_price_cad
                currency_symbol = "$"
                currency_country = "CA"
                print("CAD")
            elif currency == "eur":
                currency_price = dgb_price_eur
                currency_symbol = "€"
                currency_country = "EU"
                print("EUR")
            elif currency == "gbp":
                currency_price = dgb_price_gbp
                currency_symbol = "£"
                currency_country = "UK"
                print("GBP")
            elif currency == "usd":
                currency_price = dgb_price_usd
                currency_symbol = "$"
                currency_country = "US"
                print("USD")
            elif currency == "sats":
                currency_price = dgb_price_sats

            # Setup sats price (trim and format)
            if currency == "sats":
                display_currency_price = render.Row(
                    children = [
                        render.Image(src = SATS_SYMBOL),
                        render.Text("%s" % dgb_price_sats),
                    ],
                )
                display_vec.append(display_currency_price)
                print("SATS")

            elif currency == "none":
                display_currency_price = None
            else:
                # Setup currency price if not SATS

                # Round price to nearest whole number (used to decide how many decimal places to leave)
                currency_price_integer = str(int(math.round(float(currency_price))))

                # Trim and format price
                if len(currency_price_integer) <= 1:
                    currency_price = str(int(math.round(currency_price * 1000)))
                    if len(currency_price) < 4:
                        currency_price = "0" + currency_price
                    if len(currency_price) < 4:
                        currency_price = "0" + currency_price
                    if len(currency_price) < 4:
                        currency_price = "0" + currency_price
                    if len(currency_price) < 4:
                        currency_price = "0" + currency_price
                    currency_price = (currency_symbol + currency_price[0:-3] + "." + currency_price[-3:])
                elif len(currency_price_integer) == 2:
                    currency_price = str(int(math.round(currency_price * 1000)))
                    currency_price = (currency_symbol + currency_price[0:-3] + "." + currency_price[-3:])
                elif len(currency_price_integer) == 3:
                    currency_price = str(int(math.round(currency_price * 100)))
                    currency_price = (currency_symbol + currency_price[0:-2] + "." + currency_price[-2:])
                elif len(currency_price_integer) == 4:
                    currency_price = str(int(math.round(currency_price * 10)))
                    currency_price = (currency_symbol + currency_price[0:-1] + "." + currency_price[-1:])
                elif len(currency_price_integer) == 5 or 6:
                    currency_price = str(int(math.round(currency_price)))
                    currency_price = (currency_symbol + currency_price)
                elif len(currency_price_integer) >= 7:
                    currency_price = str(int(math.round(currency_price)))
                    currency_price = (currency_symbol + currency_price)
                    country_toggle = False

                if country_toggle:
                    display_currency_price = render.Row(
                        cross_align = "center",
                        children = [
                            render.Text("%s" % currency_price),
                            render.Box(width = 1, height = 1),
                            render.Text("%s" % currency_country, font = "CG-pixel-3x5-mono", color = "#2962fe"),
                        ],
                    )
                else:
                    display_currency_price = render.Text("%s" % currency_price)

                display_vec.append(display_currency_price)

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
