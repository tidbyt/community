"""
Applet: SolarWeatherClock
Summary: Grid power, weather & time
Description: Retrieves the output or input to the grid obtained from home assistant and displays this along with a weather icon and the time.
Author: shmauk
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CLOCK_FORMAT = "03:04 PM"
EXPORT = "iVBORw0KGgoAAAANSUhEUgAAAB4AAAALCAYAAABoKz2KAAAAAXNSR0IArs4c6QAAAO9JREFUOE9jZMACbt++/R9ZWFVVlRGbOkrEUAxEtxBkMDUsfSuj8l/4yR0Uu+AckKUgS2A0Id8obfT5f89/C8GQAFkKMwvZcrjGpqam/3V1dYwwGp/FIEtB8oQshlnKcaKC4YdFB9hImOUkWwyzFJvDkB2CbClMLbLlJFmMz1LkEMBmKbrlYIu3bNmCkoqRfePj44MSj8T6+OuTOTjN5JZJYYRb7G3nw7D10BYGdBrdYpCjiIljdIuXfPUD+yeGexMDisWEUjE2n+NLXCCLl8hMgVj2JIcBp8W4fAwTx+ZzfI5FtxhZLUU+JhRChCwGAPhhqzh/U+GiAAAAAElFTkSuQmCC"
IMPORT = "iVBORw0KGgoAAAANSUhEUgAAAB4AAAALCAYAAABoKz2KAAAAAXNSR0IArs4c6QAAAOpJREFUOE9jZMACbt++/R9ZWFVVlRGbOkrEUAxEtxBkMDUsfSuj8l/4yR0Uu+AckKUgS2A0Mb65xsD9X4vhK97QAFkKMwvZcrimpqam/3V1dYwwmliLQepwWQ6zlONEBcMPiw6wkTDLSbIY5ENcDkK3HNlSmB5ky6lmMbLPsVmKbjnY4i1btuD0iY+PD9xxpPj465M5OM3klklhhFvsbefDsPXQFgZ0Gtli9GCGOQRbHKNbvOSrH1h7DPcmBhSLCSUmbA7Al6pBFi+RmQKx7EkOA06LcfkYJo7P59gcjW4xshqKfYwvlAhZDAC0M6Q4/36UsAAAAABJRU5ErkJggg=="

def main(config):
    now = time.now()

    clock = now.format(CLOCK_FORMAT)

    if (config.str("hass", "") == "" or config.str("sol", "") == "" or config.str("attr", "") == "" or
        config.str("wthr", "") == "" or config.str("key", "") == ""):
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Text("0.0" + " " + "kW"),
                                render.Image(src = base64.decode(EXPORT)),
                            ],
                        ),
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "3AE",
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Image(src = getImage("sunny")),
                                render.Text(clock),
                            ],
                        ),
                    ],
                ),
            ),
        )

    headers = {
        "Authorization": config.str("key", ""),
    }

    solar = http.get(config.str("hass", "") + "/api/states/" + config.str("sol", ""), headers = headers, ttl_seconds = 60)
    solar_j = solar.json()
    uom = "kW"
    sol = solar_j["attributes"][config.str("attr", "")]

    sol_n = float(sol)
    sol_d = math.round(sol_n / 1000 * 10) / 10
    sol = str(sol_d)

    if sol_n > 0:
        sol_i = base64.decode(EXPORT)
    else:
        sol_i = base64.decode(IMPORT)

    weather = http.get(config.str("hass", "") + "/api/states/" + config.str("wthr", ""), headers = headers, ttl_seconds = 60)
    weather_j = weather.json()
    wth = weather_j["state"]

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Text(sol + " " + uom),
                            render.Image(src = sol_i),
                        ],
                    ),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = "3AE",
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Image(src = getImage(wth)),
                            render.Text(clock),
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
                id = "hass",
                name = "Hass URL",
                desc = "Where to find home assistant installation.",
                icon = "globe",
            ),
            schema.Text(
                id = "sol",
                name = "Solar Entity",
                desc = "The name of the entity to query for solar production.",
                icon = "sun",
            ),
            schema.Text(
                id = "attr",
                name = "Grid Attribute",
                desc = "The name of the attribute on the solar entity.",
                icon = "plug",
            ),
            schema.Text(
                id = "wthr",
                name = "Weather Entity",
                desc = "The name of the entity to query for the weather.",
                icon = "cloud",
            ),
            schema.Text(
                id = "key",
                name = "Bearer Token for Home Assistant",
                desc = "The long lasting token for home assistant authentication.",
                icon = "key",
            ),
        ],
    )

def getImage(weather):
    if weather == "clear-night":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAFtJREFUKFNjZEACbm5u/5H5ILaNjQ1DXV0dI4gNJkAApBAkYWRkhKJ+0qRJcA0oipFVIWuEaYArRrce3SaQBpyKYU7Ly8sDmzNAivG6GT2M8YYGSeEM8z2+GAQAixI5K1I4YcUAAAAASUVORK5CYII=")
    elif weather == "cloudy":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAGZJREFUKFONUUEOwDAIav+i/3+Q/mULzTDOaDYvVQIE615PmdnFXlU3+/weEEQRCdzdFwU0wbwrkQoIUDTBPJJrjEPuYgCjM92DTEF263aIrafseYcxRpv5y/Hl/IfMf48Y3cXqRW+KZE5sf1rybAAAAABJRU5ErkJggg==")
    elif weather == "fog":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAHRJREFUKFOFUcENACEIg2GMyzguyxiG8VISTIN3nh9JQ6G06u5LRKS1pvjxEptzJiRjDFUzW733AEFAIxOZHNNA2COo4CHo2atrMzZcZTDhTcpVBo7iYz9l1FsON6ruKuXXjSSEGxxK1uk5Wwobj1BqipzuA7AnWQ2rWwLMAAAAAElFTkSuQmCC")
    elif weather == "hail":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAG9JREFUKFNjZIACNze3/zD2rl27GGFsZBosCFKYl5cHF580aRIDTAPMEBCfEV0hTAdIAwjADAHxcSpGdwbpimFuxuYhZDGwm2ECvrmf/2+ezAvm42KTp5iQM0DycJNn3nz1P11dDMzHxcYaU7hsAQA2eEh/ny0tPAAAAABJRU5ErkJggg==")
    elif weather == "lightning":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAG1JREFUKFOdUcERgCAMaxdwjS7TcbsMa7gAXnrGg4rnKR/akIRQVM4VEZ21uyvrcU8QRDO78NaaUEAT9FqJVECARRP0j+Qa4zuZmVcPGrHMTKDvktPQTRKrfZ79Iq/cqvs0/Lcot5+CgLl5G/sDCMFGXQf36V0AAAAASUVORK5CYII=")
    elif weather == "lightning-rainy":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAIJJREFUKFOVkNENgCAMRNsBcA2WQTdxAr+dwE2UZVhDBsC08Uwhkmh/4I53pcB0V4yxYB9CYOztqqaA3vvHTykRAmgimlsQCQlIoYnoLtyO8R/GzG8Psp7ODGOcc9lXp5IH4lar34PFLyfpd0q4ghECMC2Zjs2xDVSd7eEnGLPiaqsv1TxZXf7YiPsAAAAASUVORK5CYII=")
    elif weather == "partlycloudy":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAH5JREFUKFOVkLERwCAIRWEB2ywgffYvs4YukNYFyH0TPOS0CB3w/ucfTIvSRsqJOK76IC53/VAboFfS7ng2grsXTqc8aBF8nAGXUl5HIsqHTHFN0M/Uu1DOeQC11iHAzgwYjh40BQQd+kzQb+H4tv8wHHZRfCQR4eU3YgSAmD2pNkus7FVgLgAAAABJRU5ErkJggg==")
    elif weather == "pouring":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAGZJREFUKFNjZIACNze3/zD2rl27GGFsZBosCFKYl5cHF580aRIDTAPMEBCfEV0hTAdIAwjADAHxcSpGdwbpimFuxuYhZDGwm0ECvrmf/2+ezMsIo2GK0MVRFONSBBNHCU9CNtDOGQCwWmh/jz7/swAAAABJRU5ErkJggg==")
    elif weather == "rainy":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAGVJREFUKFNjZICCLVu2/IexfXx8GGFsZBosCFKorq4OF7958yYDTAPMEBCfEV0hTAdIAwjADAHxcSpGdwbpimFuxuYhZDGwm2ECvrmf/2+ezIvBRxbHKwkyCKtidBvQbQLJ084ZABOGYF1W/WK/AAAAAElFTkSuQmCC")
    elif weather == "snowy":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAEtJREFUKFOlkVEKACAIQ939D71QGFgoKH1NXjplwcyMJAEg1xWD4Egrt24wVmvA1c/JzWKh/pDB63oZVc4d+3dub16lMcpXCW1+8AA6f7f8Csc6NgAAAABJRU5ErkJggg==")
    elif weather == "snowy-rainy":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAHhJREFUKFN9UUEOgDAIg7s+TX+ij9Gf6NP0juliF4a4XUZKU1pQEREzs3m95dxHRa2q9WcfWAWn5TKQfRM18SISlT2B9bENUpQB8NGCV6M9cBpvfgrVGqFIKApvFj81DQgrJIHwCRiD/HqmDY7vbiM7QrbzdM+9Cz4mcbT8zlTcvQAAAABJRU5ErkJggg==")
    elif weather == "sunny":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAGJJREFUKFNjZMAC/n9i+M/Ix8CILgUWQJfExYfrhin4f4jvP9hEg08MINORNaJYhawQ5gRk5yBMRjIRw61Q94OtAUte4IOoMfiEzc9gMdJMRjaGeDdDw5ZgaJAczijOwRGDAKiLQPzl4xRFAAAAAElFTkSuQmCC")
    elif weather == "windy":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAF5JREFUKFONUcENACEIg2HYfyCG0fRRUxFy97JAgRY9M5eZWUQ4MWLmiPG6BhPmkIesm2rzRQYRckBSzKaR3Ek6pnTipP2XwUdGNVbPeE73Zeya3DlvDTLZrdWfRH0DViU+TDZ+FYwAAAAASUVORK5CYII=")
    elif weather == "windy-variant":
        return base64.decode("aiVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAF5JREFUKFONUcENACEIg2HYfyCG0fRRUxFy97JAgRY9M5eZWUQ4MWLmiPG6BhPmkIesm2rzRQYRckBSzKaR3Ek6pnTipP2XwUdGNVbPeE73Zeya3DlvDTLZrdWfRH0DViU+TDZ+FYwAAAAASUVORK5CYII=")
    elif weather == "exceptional":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAQdJREFUKFNjZEACq1W0/zv9+Mmwj4Od4d0dVrBMOsMFRpgSOGMmg8H/tLoLDAwufHDt76LEGNY84YFrACuGK0S2BsR24WP4ptTHsERmClgDWDHI+pCoq3DJD8fugbWJvj8C1z4//RMDI8jUEJkvDELLXjH8vm4Al2SNPARm/15ux/DbO47hh0UHRHHaoXtg61i3LgJLcPGloDroAh/DmiRZhGIGg0/oLoabzPr0EMOaZdoQxSBRcEiUINQ/21HFIOXRxvDt0xwGrlkpDLOaDBgQoXEI4ikQePYih0FKYgrYaVz3isBis+yUIIphwSek8pshZN5jiMCeTwzv5qnAIwgedMiOxReLAAp7cILSbE4rAAAAAElFTkSuQmCC")
    else:
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAAAXNSR0IArs4c6QAAAGJJREFUKFNjZMAC/n9i+M/Ix8CILgUWQJfExYfrhin4f4jvP9hEg08MINORNaJYhawQ5gRk5yBMRjIRw61Q94OtAUte4IOoMfiEzc9gMdJMRjaGeDdDw5ZgaJAczijOwRGDAKiLQPzl4xRFAAAAAElFTkSuQmCC")
