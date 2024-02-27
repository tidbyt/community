"""
Applet: Select Live
Summary: Selectronic Remote
Description: A remote display for Selectronic's SP PRO inverters via select.live.
Author: Simon Holmes à Court
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_USERNAME = "demo@demo.com"
DEFAULT_PASSWORD = "secret"
DEFAULT_NUMBER = "58"

# icons from https://www.splitbrain.org/_static/ico/
# load weather_sun icon from base64 encoded data
WEATHER_SUN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFn
ZVJlYWR5ccllPAAAAg9JREFUeNp8U01ME1EQ/t5uWVx/oFAIBFfowYsxKkYTTnjx1Kg3bx48ecCoUUzk
aLxZDRpLQjiRaOTGxQAx8e6NxGpCTJSYJa6IodXWFrZ2u/uc2S7tImtfMnmZme+bN39PSCkhhEDUkU+6
hiBdE0JNivFfa1EYJYI0KV+OSPmw/R66k1lcewW+Wfft5A/jY/8GKJb/DHaOPQI2VtOIkTu3AJy/HUet
lkb/URQfpwbDeLFTgnzaPQmn2oPk2Ss4bqjwJKVDpVW+AvuOMJLyJX3FcmEuz6FNy4k7P+82Azw/LXFh
ArALgDUPeE7wBJEIUy+4DTAuA3ocWEpDXH0nGiW8z37KnOpL34KuB60Rgcid7pBUgC8v6BHbxzdKwLPe
Ie9A4oNybLgDthki72lxXfQkvI/Z38pW/mR9ClKayonRDlTzgOMGUouQwEc4H8885o/Nb19yl5dKKPxo
QQ4FIRzjmecHmHlrv1lZs2fhtYPG1ToA+wnHeOY1pzBtSPQmALfa7HrU4amoGrCZh7huNaew+t2e0zet
+EBCS4nOg0pkEH6oWPbW89XXdg2FXYtEx+DN/PagZ2rAOHQRnlufRGMPeJFUrFulxcP3czfJQLXACv8F
i8RUY2LDn/PncsbdqpTgOOCbdbb7fsIFeA6+J1XO5AxJ/41z+1My0yf5Zj2wG7tXo1XDAC0gaf8D/BVg
AJbuIPtS0owhAAAAAElFTkSuQmCC
""")

# load house icon from base64 encoded data
HOUSE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFn
ZVJlYWR5ccllPAAAAnlJREFUeNqMU11okmEUfl5/prX1Y4xFVLAYjKg1spouGkm521SkCwdRjGL9YEXQ
lRdBBV0WRauL3Q1i3rQk10VMGYsMYYNBsItdWI0NnBpNnZ9++v31vq8iEw06cPjOd85zfr5zno9omgZC
CFpJyA8NKuB5AzLxLjyFct6nI/LH66PX3CzOcnX4hwRHoVlOuGHpv4TgFWhiRfO5XFZUJNW1HWeod7uH
EFHBK+eywL7+YQyNhcBmixQcEMMuqJ5fkNXGnvW3chnuXpsTqQ2g86QT5++GIQrrXB0PZtFlG8Knq91Q
9O1oOQEtgLnpKA7anbDfCkLcWsO5p2keiz0SYfd/QEzxQpm53HoCNvb+gYuw3phAIbuBkpDF8spvqhmU
CpsQcimcGptEp+0Cxj10uTUhbJMvPfRx4Az8bxfwc3WRXkUPo9EIc5ueg8SKAkmSoKkqjnSfxvjtASC5
iPshjfBP+JNHpMsTGM7l16FoBGvv72BzKQ5d7boq7WexDuKw9zUYxmAPID3pjdR38GQON1/5iomtfBrs
sql4HM7AFPSm3byAUs4j+mwEh7w6MIxaKfKcx9uW+EMpl+giiwDdskTJU8knsTw9woPHvc+5r7rsIhiW
5TRcQVXKdFSZqkLJAshCEm27qhMwm/lYDAxDsU1nVBS5qkTmYEnIwGTew2PM5kVVGfoarrmArOBo71lo
pB1RGtfENMw7q6RhtkR9x3oG6dkEzMjfmwswzs5/m6U72MGmhEHOoKPDVAVRm/m+xD/TTiWObSpQLBbm
F2IJB9EZsdr3EC+W9HW2cHyfA/LXFcoFiWKF+QYi1X7nHqp78X9CeYsEy/0rwABJ0zkOe1qN3QAAAABJ
RU5ErkJggg==
""")

# load battery_low icon from base64 encoded data
BATTERY_LOW_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFn
ZVJlYWR5ccllPAAAAhVJREFUeNp8U01rE1EUPTOTN20y41gStSFGbFGwERcFF25cuJIu2o0UBfEHKEQX
uq4J3YqIVnDjqhsXRXRRcGWhpbsS0JVg00XUiuNMMLHYcT6f902oJmOnFy5v3p17zv04PIlzjj2TJOnv
99LLV9yyrDhWLBbxdmUl9/TxI0f8G8AkCer1+rznedevzF49NT52Eq7nYX1tHY3GRjOXy76o1Wr3+zEZ
9BmB+fTMDCqVs1hdXcNvx0FzawutVgu371RPm+b3Oc6jOVFrX4IoilAqHcfHzU3kC/k4VqlMxG7bP1Au
n4B+yOiHDBKI1lRVhWEYGKFENsTAGKMYg++HcF0nLpJKIPpynF18/rKNjtYBzUwVNWiaDh5xhGE4sEBh
8sCNlugFIWQ6xUJlWY5p99QJgmBAqf8JRJLvx0TJRHEXBEnL7JskKgtXlH+OiEaIDibgYgRxDucQaQY4
zQ9dg5QdAkKOoPuzR5xKQJWy7zagLy4g02qCU7JHS7OpKzZxDuxGFVKGHUAgKzgTAr8mL8HLjyOyzN6i
jo2CketugM7OTjqBTAT2m+c4cvkmtItTFKDZpZ4S4fYHmMtPoEzOphMotPjXI2OYWlpE2RuG226g2/6E
XRLm21Hg/YVrBEiok3hM56t37906XChMQ2WjQmWJOiBRwX3P7NrW8sLDB88I00h9jWQl8gK5mlBMCNQm
/9qP+SPAAH170SRxhZ4vAAAAAElFTkSuQmCC
""")

# load battery_half icon from base64 encoded data
BATTERY_HALF_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFn
ZVJlYWR5ccllPAAAAh5JREFUeNp8U01rE1EUPe9NMpOmmUmaIo4xResHGIVu/Alu241IFy6CW8GKG5c1
wa2Logj+glJBxI1bAw1FEM1Cl7YVIiaYpI0xY2bG6cw870xtyUSTB4cZ3n3n3HPfvY8JIXC0GGPH/y9e
vhKdTifc03UdbyqV5NPHa1YQi3BGBcrl8kPHcW5ev7F8fv7sGfx2HGxVt1Crvd9JJqc2SqXSg2FODEOL
yGJxaQmFwmVsblZhWxZ2dndRr9excvfOhVarvSqEvxrk+q+A7/vI5U7j8/Y2srPZcK9QuBRib+8H8vk5
pFRtmBIVCKzJsgItnUFGyyCuxCDH44QYDlwftm2GScYKgHFYjotvrZ/oW5yypTCtylA54LmcRALnfIIA
p0yNdzDXl2HsmxDBebov3wPU/AwuFp8DUmySAwknlB6Mc1dgZxsw283wtpQZjZCH5jXheWySQAx24wP0
hWvEmqOK2OFsMAG39xV28yMG1qnJAsaXChT5E6apCWZfhdUBBm0DNA5Izy+A81vjBRjncO1fUBII6/ct
Ay7NHo8T6C48ipFC9NoQtQDf7iJ0zQ7HhfG/X4JndSPj/o9AGBv0QKUf46hxAXyKRekjAhIOUFWK6Hsq
piiSoNOJoAtkfyCpeJsqhmciSUce09WVe/dvpzP6IpPkk4IsBSUw6oLvOq1+9/vrJ2uPnhGnNvY10soR
ZgnyiFvqA/YJzWHOHwEGAC9R0QaUyMGMAAAAAElFTkSuQmCC
""")

# load battery_full icon from base64 encoded data
BATTERY_FULL_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFn
ZVJlYWR5ccllPAAAAdhJREFUeNp8Uz1LK0EUPbObhBBJDH4GP1AQG20eaKtiZ2EjWFnY22glKmhABUEE
UUTeT7AQsbHWwg8QyeuejUajhahRVxHN7uxuxjtJjNmNyYXDDHPnnHtm7gwTQuA7GGP5+fbOrkgmk5m1
SCSC/f2DwMb6akrmHBy3wPz80oLFrZGh4eG21pYmGJzj6PAE/2Kxy0DAvzUXnYmWFFhcWBbdfSrqGoGn
eA/CwRrEr+JIJC7QO6jj4x04O7AwG53KW/WgINI2Q7j9BDfaEZ5Ck7ilNaUdqCUk9ArUBPqRFj2FFKeA
NNMYGoDf04A/zZ2wLRVpC7A4OdLOUVfZiVOhlRagE+HNuMb/x014vYD+AfBPGgmfZL+3Y5p2VDkYipPO
YJqvUOiEqgRlVTU3EjjlUNCpIgEpwS0NDNl9mTE3l6K6oWWKlHbAFBj2i7tInpLilHPVLHJgWC/4LaSo
TgJljyDVua25TP6EzrXyDiQx44D97iDFi3NFclxQF9ScUwX5m6TrgUFdYOUEmGri7ngU5nsQqp9a58tC
8UprQaRuRknAdDpzfaauifHJsXAoMuhRfPXZ0rK6gG3zB+3tfm9tfeUvcWIlfyNFA6Ga4HNdAz1oPBPu
CjlfAgwAjG22corgI3EAAAAASUVORK5CYII=
""")

LOGIN_URL = "https://select-login-serv-simonahac.replit.app/login"
DATA_URL = "https://select.live/dashboard/hfdata/"

def get_readings(email, password, system_number):
    # print("fetching data for system '" + system_number + "' with user '" + email + "' and password '" + password + "'")

    login_req = http.post(LOGIN_URL, headers = {
        "user-agent": "Pixlet/2.0",
    }, form_body = {
        "email": email,
        "pwd": password,
    }, ttl_seconds = 60 * 5)

    if login_req.status_code != 200:
        return {
            "error": "login failed",
            "code": login_req.status_code,
        }

    # for development purposes: check if result was served from cache or not
    if login_req.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("login hit! using cached cookie.")
    else:
        print("login miss! refetched cookie.")

    if "Set-Cookie" in login_req.headers:
        cookie = login_req.headers["Set-Cookie"]
    else:
        return {
            "error": "no cookie",
        }

    # data
    data_req = http.get(DATA_URL + system_number, headers = {"Cookie": cookie}, ttl_seconds = 30)

    if data_req.status_code != 200:
        return {
            "error": "request failed",
            "code": data_req.status_code,
        }

    # for development purposes: check if result was served from cache or not
    if data_req.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("data hit! displaying cached data.")
    else:
        print("data miss! refetched data.")

    data = data_req.json()["items"]

    readings = {
        "solar_kw": data["solarinverter_w"] / 1000,
        "load_kw": data["load_w"] / 1000,
        "battery": data["battery_soc"],
    }
    return readings

def render_error(readings):
    print("ERROR: " + readings["error"])

    errorKids = [
        render.Text("select.live", font = "tb-8", color = "#888"),
        render.Text(readings["error"]),
    ]

    if "code" in readings:
        errorKids.append(render.Box(width = 16, height = 1))
        errorKids.append(render.Text("[" + str(readings["code"]) + "]", font = "tom-thumb", color = "#800"))

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Column(
                #expanded=True, # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = errorKids,
            ),
        ),
    )

def render_system(readings, system_number):
    # format the readings
    solar_str = humanize.float("#.#", readings["solar_kw"])
    load_str = humanize.float("#.#", readings["load_kw"])
    battery = readings["battery"]
    if battery >= 100:
        battery_str = humanize.int("#.", int(battery))
    else:
        battery_str = humanize.float("#.#", battery)

    # print a debug string
    time_now = time.now().in_location("UTC").format("2006-01-02T15:04:05Z07:00")
    debug_str = time_now + " [system " + str(system_number) + "] solar: " + solar_str + "kW, load: " + load_str + "kW, battery: " + battery_str + "%"
    print(debug_str)

    if battery <= 25:
        battery_icon = BATTERY_LOW_ICON
    elif battery <= 70:
        battery_icon = BATTERY_HALF_ICON
    else:
        battery_icon = BATTERY_FULL_ICON

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (0, 3, 0, 1),
                                child = render.Text(font = "tb-8", content = solar_str),
                            ),
                            render.Image(src = WEATHER_SUN_ICON),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (0, 3, 0, 1),
                                child = render.Text(font = "tb-8", content = load_str),
                            ),
                            render.Image(src = HOUSE_ICON),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (0, 3, 0, 1),
                                child = render.Text(font = "tb-8", content = battery_str),
                            ),
                            render.Image(src = battery_icon),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "email",
                name = "Email",
                desc = "Your select.live email.",
                icon = "envelope",
                default = DEFAULT_USERNAME,
            ),
            schema.Text(
                id = "pwd",
                name = "Password",
                desc = "Your select.live key.",
                icon = "key",
                default = DEFAULT_PASSWORD,
            ),
            schema.Text(
                id = "system_number",
                name = "System Id",
                desc = "The system number to display.",
                icon = "hashtag",
                default = DEFAULT_NUMBER,
            ),
        ],
    )

# weirdest thing! at ~50 minutes past the hour we get a 500 error code
# the vendor (selectronic) say this is 'normal'!
def can_ignore_error(err_code):
    # don't ignore any other error
    if (err_code != 500):
        return False

    # test the minutes
    current_time = time.parse_time(time.now().format("2006-01-02 15:04:05"), format = "2006-01-02 15:04:05")
    mins = int(current_time.format("04"))
    return mins >= 48 and mins <= 52

def main(config):
    email = config.get("email", DEFAULT_USERNAME)
    password = config.get("pwd", DEFAULT_PASSWORD)
    system_number = config.get("system_number", DEFAULT_NUMBER)

    # with default user and passwork, output dummy data
    if email == DEFAULT_USERNAME and password == DEFAULT_PASSWORD:
        readings = {
            "solar_kw": 5.7,
            "load_kw": 2.3,
            "battery": 66.6,
        }
    else:
        readings = get_readings(email, password, system_number)

    if "code" in readings and can_ignore_error(readings["code"]):
        fail("*** ignoring 500 code during the magic window!")

    if "error" in readings:
        rendering = render_error(readings)
    else:
        rendering = render_system(readings, system_number)

    return rendering
