"""
Applet: Formula 1
Summary: Next F1 Race Location
Description: Shows Time date and location of Next F1 race.
Author: AmillionAir
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("schema.star", "schema")
load("cache.star", "cache")

def main(config):
    #Time information for date and timezones
    timezone = config.get("timezone") or "America/Chicago"
    now = time.now().in_location(timezone)
    Year = now.format("2006")

    #Add Caching
    f1_cached = cache.get("f1_rate")

    if f1_cached != None:
        print("Hit! Displaying cached data.")
        f1_data = json.decode(f1_cached)
    else:
        print("Miss! Calling F1 Track data.")

    #Set API URLS
    F1_URL = "http://ergast.com/api/f1/" + Year + "/next.json"

    F1_COUNTRY = http.get(F1_URL).json()["MRData"]["RaceTable"]["Races"][0]["Circuit"]["Location"]["country"]
    F1_LOC = http.get(F1_URL).json()["MRData"]["RaceTable"]["Races"][0]["Circuit"]["Location"]["locality"]
    F1_DATE = http.get(F1_URL).json()["MRData"]["RaceTable"]["Races"][0]["date"]
    F1_TIME = http.get(F1_URL).json()["MRData"]["RaceTable"]["Races"][0]["time"]
    F1_ROUND = http.get(F1_URL).json()["MRData"]["RaceTable"]["Races"][0]["round"]

    f1_data = dict(F1_COUNTRY = F1_COUNTRY, F1_LOC = F1_LOC, F1_DATE = F1_DATE, F1_TIME = F1_TIME, F1_ROUND = F1_ROUND)
    cache.set("f1_rate", json.encode(f1_data), ttl_seconds = 1600)

    #Zulu time offsets depending on selected Timezone only have US at the moment
    EST = int(F1_TIME[0:2]) - 4
    CST = int(F1_TIME[0:2]) - 5
    MST = int(F1_TIME[0:2]) - 6
    PST = int(F1_TIME[0:2]) - 7

    #Made for edge case that race falls on the first of the month in one time zone but the 30/31st in others
    RACE_DAY_1 = time.time(year = time.now().year, month = int(F1_DATE[5:7]), day = int(F1_DATE[8:10]) - 1)

    #Establish if a time needs to be added or subtracted from the informationn based on selected time zone
    if config.get("local_timezone") == "CST":
        if CST <= 0:
            TZ = str(CST + 24) + " CST"
            DAY = str(RACE_DAY_1)[8:10]
            ADJ_Month = str(RACE_DAY_1)[5:7]
        else:
            TZ = str(CST) + " CST"
            DAY = F1_DATE[8:10]
            ADJ_Month = F1_DATE[5:7]

    elif config.get("local_timezone") == "MST":
        if MST <= 0:
            TZ = str(MST + 24) + " MST"
            DAY = str(RACE_DAY_1)[8:10]
            ADJ_Month = str(RACE_DAY_1)[5:7]
        else:
            TZ = str(MST) + " MST"
            DAY = F1_DATE[8:10]
            ADJ_Month = F1_DATE[5:7]

    elif config.get("local_timezone") == "PST":
        if PST <= 0:
            TZ = str(PST + 24) + " PST"
            DAY = str(RACE_DAY_1)[8:10]
            ADJ_Month = str(RACE_DAY_1)[5:7]
        else:
            TZ = str(PST) + " PST"
            DAY = F1_DATE[8:10]
            ADJ_Month = F1_DATE[5:7]

    elif EST <= 0:
        TZ = str(EST + 24) + " EST"
        DAY = str(RACE_DAY_1)[8:10]
        ADJ_Month = str(RACE_DAY_1)[5:7]
    else:
        TZ = str(EST) + " EST"
        DAY = F1_DATE[8:10]
        ADJ_Month = F1_DATE[5:7]

    #find the month and display as text
    if ADJ_Month == "01":
        Month = "JAN"

    elif ADJ_Month == "02":
        Month = "FEB"

    elif ADJ_Month == "03":
        Month = "MAR"

    elif ADJ_Month == "04":
        Month = "APR"

    elif ADJ_Month == "05":
        Month = "MAY"

    elif ADJ_Month == "06":
        Month = "JUN"

    elif ADJ_Month == "07":
        Month = "JUL"

    elif ADJ_Month == "08":
        Month = "AUG"

    elif ADJ_Month == "09":
        Month = "SEP"

    elif ADJ_Month == "10":
        Month = "OCT"

    elif ADJ_Month == "11":
        Month = "NOV"

    else:
        Month = "DEC"

    #30x24 track maps
    Abu_Dhabi = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAO1JREFUSEvNllsOxSAIRGX/i/YGEwyOiKgkt/3qQz0wDFYqpdTyh4s+D651FIaIY76/QhkLVGD4fIPfgleQV7gL5sVRUv3uBb4EW4vqOr/KboI9eRmIStxkPoEtedk8evFVCXhc1O0DOGqkSHA7p3ewJ5fVTqvMorIPYDSMSGfV1JM0Am9grB8CT8HaE1pyHSwJVWeL9zdgrDG2YgOvetLqW8nGkhr3c8vlXV0ER9rBc7WebwUiSkwZZ4K9lkoDR5w8GE2kPplo/ShOdq02tvfSwXaHtYuUB2Wf2mm31WV93x4EskBTxp8/7GVn/gMjGOn79JCBIwAAAABJRU5ErkJggg==")
    Spielberg = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAS9JREFUSEullisOwkAQhrcHQHEEDEFxjRo4A3UIMG0QNMG1CSEIDLKcAQyX4AIk4NA4BAqyIUuWZTqvVjVtZ77557HTyBjzMsKrqqqvRZIkQuvP55EU7EMdUQMXgSGl7pkUzgbXpbcObJ9jwZBgrJ4YlCoDCqZUWuehKm4PgGDfeFxuh8/Lae8USDNQl5U/MNYsGLTfa+fTbFVAdYV8/oC1UKqzoYBZijkBYR1MKg7r6DuDjCml1h+7xlx4Eyh5ZGIqoVHyD20qMPYBEqZdWtNwk5BgrE7QWqKUOhsWmAvvdlqjWb7ZcRYGG0zBpTtaBMbgFrycZPH5cT9y/gzEYB9u78t1Opin60OxyOLrjQclx4mKXJpe359KcTivnGZSjROlXPO+sWINtHGNtVBr9wYhpcwBXE9y4wAAAABJRU5ErkJggg==")
    Melbourne = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAANVJREFUSEvtlkEOhCAMRetmXMwtORi3nIVuxjBJCWBpf1FjYsYdofSV/7EwEdGXbvgmCRxjrEoJIZxe2g7MUIa147MqqMA9yBXwDLaSW/NeJSqw5WWCWzFoAT8wuptngREJL9kxCk4eIrGW19ljNJl2HnhuWd80vz6ZLeV2g1M2CW71gFapIXAJLyXVVGvPh+t3snzT5ltFXA3kCJhVYlX+4KNqquvLAwbfTqMV9R4V4n3cg6BNhtdrzUZ8+khg9AZDoCkGBveahmaBppALPOqztO428AbVhp8B0Iv3ZQAAAABJRU5ErkJggg==")
    Baku = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMBJREFUSEvtlEsOwCAIRPGqHsyrtnFBg5SfFuOm3TSxDW8GBgsAXHDgKRq4tTbIqbWmynuBKRBheJYJH8AWIBv+gCOFI/9E5zGAvVYeA3c3He4JjLiecozg/tbgUjglIa8ZW0WxgNZyeu6NxVwnSam2YhLIgqsXiATlbYxcMhp8Cuy1WguVBF8C05AhzEs6hy+DufvZUH4GRwWkO+ZztVaNjiPNMRXA4anh8q5Fb9W2OI6s3Vaw1ZUf7GUm7fuxVt8+K40BrvuRmAAAAABJRU5ErkJggg==")
    Silverstone = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAO5JREFUSEvlllEOgzAMQ8tVOVivuolJmTJjN3ElvsYfofCI4xqOMcZrwDHnxNLn/DxPWt8pHgjO0ABF7VHw9fYM5MDZy6Mqt44zOBY7nbMxMaUoGOH5xlXnzphssBqFWy+lVoZSnXfrP2Ccz8rFruShSDzzC+44MTuz4/JrDfrjcbDakjfwyhwsmTpS46iyAnLGVUqhjDgGdr8Er/avynPWlcr1JdiFu+FCZ9ztKtblDtyZy+TKD2fSZVC1tdj1Eqyk74aNyocWuANXLsYvXJy3wbv7XDncArNvdfXbo/LABnfhVQBtgasuO9f/D/wGKEThAfM9liIAAAAASUVORK5CYII=")
    Sakhir = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAO1JREFUSEvNlusNwjAMhN21kJiBHTKYd2AGJNYCBRHkGj8urqq2P6v6vtw5cbMQ0YsOeJZTgJn54721tnsGP8cDOogVeNdA61zwrHO5cAT+B+5FsyKyRWi7VmC5UhRugZDIXXCPGoF74KxVIRiBe9FmrlNwBo/AkWsIHMGjdnxdX4joqQcDDE6c35j5bsyAKzM/rOM1BR7CWbwyYu9b6Dh589NyYkVvbTQTjA4Bb0G63tILwVv/FNZAGu82RR0tTLdBuy5trmoSEm7+JKrCWV0IzmZsJp5tuKG/uvroy0AVgvT+HHeuPRx6moc5fgMOQ8kBS0aTsgAAAABJRU5ErkJggg==")
    Spa = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAPFJREFUSEutlksSwCAIQ+1VPZhXbccFMzTyCWp39fcMYPRprb3t8jfGWFbsvf/anptgC6hpGn4FjEBUJ/1XwUxYp2qEHynOlGKi53hRvQ2uQlH1FlhDMZ8aIIr1GJl7BGagCN8GWxUqi1uR8IqvpLgKjTZEgbOcYl6tFGCFp2AGGinz3JgGMyoqykMwq1YbAwt3wRVodF5nnxUtE7wDrcJDMDqO5UCiyNus176ArbOKk6sQ6lrUhVK52CvuNSP3U4w78/69gskqWq+3gCWPnj3i0bEMIkuFq9iq0J33oJW244cAsxHvZppzU8tkANEYL+wfPGPbtSObuxwAAAAASUVORK5CYII=")
    São_Paulo = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAUCAYAAACaq43EAAAAAXNSR0IArs4c6QAAAOBJREFUSEutllkOwzAIRJ2r+mC+aisiURE8w+ImnwbzWAzkGmN8xsG31tpuzTnLlq4O2MMsKJIhb0JwFJWViQNIV4AsCxs4M4CAzLjqIvkPXKkZMiRnKGKFqdyn+wZX64OM+AwIwOqxqB/g7FVGqdOIvA5yTHRbYI2GPRrmGIK3wRGc1RPdOQIzeFQKLzsGd+Gvgqvw12rse5L1t9ezXbP1cdZSbAtkcG+3Nbmi1VPpcXv/MavZnI6GPRsc2X6k26nrxF8RZ/VDcrsMKplRG60fAds+zMnq42yDWSvpeRX8BcU0yAEiV5CMAAAAAElFTkSuQmCC")
    Montreal = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAALJJREFUSEvtlFEOwCAIQ/WqHsyrbmEJi2GAVjH72PzX12JLTikd6YWTXwXXWk3PpZQt87gcE1gDsKAd8CEwWY6G3+B2nhLSfkWUgEe4PIiVhRkxaqoRh1KMJUK+6dYJDZfXDs4JB7nbYyvxsx2DwJGpHgYTNNI1DI5yDYHZdQQcBrdwKQDtPlWum2qZXq237ELWzxMEg1mItTi0LmtLZRq8+u9L4NklQvd+8Mr0oLvfG/UJCLWBAUc8CsQAAAAASUVORK5CYII=")
    Zandvoort = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAQlJREFUSEvVlU0KwjAQhV9BCgquvGFAPIqLrtxJF7lDb1FvZCn+kEIhTGfSTBIVuyzNvHzvvSYVgBcKPtbaxTRjzOJdVVL4YhvscYAv5DbyceGZ9ifCVNR5rCameXED/PCorZLNbo2YMbWNs5E2ppgwJQwRuE1kC0t0XxGeaWNybu0VG9ST8zGNFjP2yWIo56w10bDlihH2nZDarm41FZZOVDaO8QFzOk5LkoSlH5/bhORQsjBXlhA99+9LMaweIJwQN0x74BS7naReqIk1V7SWNnhWa4Vpw9culGyrU2iLEHPZrtH+v7DfhxjaIsSaEvrfZpfrOYy49T26rsO5aabZ43BHvdsG9/QGIAHgAVrd/A4AAAAASUVORK5CYII=")
    Le_Castellet = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAL9JREFUSEvlllEOgCAMQ8dVOdiuqsEE0kxgMgZ86B+J8LrSTQMRXXTgCf8EM3MxO8a4xfjAzNU7Xi2ggBGEDuTyvYVUwei1FOElQAWvEvG002i4PK6i9LHVUuu+1wAZrT5fRc0F2ZeYj+bkmrHziwh1ZM4IkBXjWSq4tXmmrZKAYXASYs0B5sEElvC01iYfvmOuuJXkDM+O9NbminsTreUACnEB1xyQ4UsuLAP3PuRHwSjM1Wrt1wVDtxV8rGIE359WgYVHgSQxAAAAAElFTkSuQmCC")
    Budapest = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMBJREFUSEvFlUEOxSAIROlVPZhX/Y0LE2I+nUcDqWv0OeOAl5n9DKw5p40xQCUruQh4QffKwPe+f3vawOqyGLxuTe32SqM95eDT3nZwZG0p2EPODJ9BagdHaS8Hk7YqaSefapLulnZS4CelOxPpdlITjEDXGSkwmcLKjVeKKVi5klasAuMvpixPWb1tVHYq6CvF6rMg0DYwGS6lVlO1KcU+qdEbq7f34cOKFTijFitehV5N5luMeh8pJoMjW/MZ+AbpNu0BfO8cJwAAAABJRU5ErkJggg==")
    Imola = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMFJREFUSEvtlkEOwzAIBPFX/TC+2opISI4LZmlB7aG+REochl0D8iCiB31hjT+4w3VmvoWdc1Kr1StQYLLkHQTes806okCFyjMEK3T9OQvW/Xss1+pOqCRjgruhR3CHvesxvSiuUhvFMcGfqo2gptXaZ1XV68WBFGd7GXEsBUYCok79NnidsaiiaN9N8akakUqNYG4fRxUdfX8LjCgqByPQ6nMezHxd9rxWsW4PGUvdAbKDrWFR2b+ayFXVXapOzjwB3zqQAT+qvrQAAAAASUVORK5CYII=")
    Monza = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAALJJREFUSEvtlEESgCAIRfGqHsyr1rjQUYIAFdrUzgZ9/P/RBAAXfPAlDC6l9DZyzm4tdTAGtrUXfAKPkFBw9TUKPmVcVWJrqX8ngn+Ao1SL4NqIR97kdaLsxk7s2s3eY2+4Gnza8ge4AbiH41Tey+DdzM3g0XJqwLRPLAuWFI1vu2XCW2MkWMrZAmq1eDbCwFjMK1iy26JcrVgaIgt0rBUzXj1Yu4+1WnvAat0PXnXOvO8GDXd+AZeOFjMAAAAASUVORK5CYII=")
    Suzuka = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACcAAAAYCAYAAAB5j+RNAAAAAXNSR0IArs4c6QAAAOxJREFUSEvVlksShDAIBeNVc7BcdSwWTCE+wEQN0ZWfKtNpHuhWSvmVRY/tE3CttZO/Wmuq0785hiMgeZ5Jd4CTpiJAafotw9Ac2/IA6RlbtuCiDUZVOTQEehkypCOg4VB+CaTX8Klbrd3qBXkhNujZHo0AHCUWCCoDgkOGRgDdOWeVJ8qKtCrL2Qt4ewhrc7q8fK2Br2TwFTg0M0cMPg7ndTyao57BR+B0Br2GQOW1AG/DRc2BMng1f9PgCNIb6MjeVLhewOlwPYApcBagvE+5TIOLDKbDaVNLmbM+ddy5qWWVMxL9CS0Dh4b5DmaPxgGDzudvAAAAAElFTkSuQmCC")
    Mexico_City = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAALlJREFUSEvdlt0KwCAIhe1VezBfdaNAsDOL3BJhu134efwvRHRRwlfSwcwcqrvWOtjvigWKP0950uw/wMzccxwFbbYxmo1VEKwfRTgj6odQS2gb0ArPidAPYMtgKnil8E0adBG7+9gqlJ0UYO24wQLxFiG27Guw14FQsO4KHX5rQH1WjPm1ICngWS0cVywjUtpttgf+CV5tvVDFaWC9Es1DYGfked7ggjEPgYibC1soBTybZiHFtZOWG3LFlgEHTQNtAAAAAElFTkSuQmCC")
    Miami = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMhJREFUSEvtk1sOhTAIROtWu7BuVYMJDdbCjPX54f0yF+UwAzOllOb0wm/6wU+5/h2rSym3ic45194bxQq1L1w1Rdv7MbAIELiK2u2YsXrUkRCMrD2zjlNgtUwHZNWHO0Zq27pdSzRAz6VLcmwt7A3fq78Lbi+Z3ZuqixR7x7gqth96cfKGia48qu3A3o68K/bUothRYGupPKt6rzmCSo8KZqIkQHQPDLSCGSiTWRZ6CNza3bPc/ofEDOcYWX4bGDVG9WHFqDGqLxWLkAEqukfRAAAAAElFTkSuQmCC")
    Monte_Carlo = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAP1JREFUSEvtlk0KAjEMhTMbN4KnE9y46r0MCJ5SEKWFliRN03Q6jAt1WTP98l5+ZhYAeMMXfssfvJfrTasRscohhLBZXhWYAimodb42EwbOl1vKPDGeZCqwhGogL1yWi95dwBYgK9Cs19zRyhLPmmBNbT7zKvfGMcUWOKr2uBLjpDOH4wmulzMrfRPcqmMPbiV/uz9geT1TAgksL+s1T+9/Kk1rsHhWwFYttfEYgcvnK/DokrDGxUo2WY2I6bUYFcuW9yyCHNNLWjqUwNTm2X2s7XhtD1RgOQ4jqkdimdV5VmdVexJgXT3TqR4YjWFzvJfNZYGMZrtF/O997H0A8I3DaSiMS50AAAAASUVORK5CYII=")
    Sochi = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMxJREFUSEvN1lkOwyAMBFC4KgfzVROBBGpGXjB2lfSvVdWXGcC0llKu8sKrfhYmotVHay2tGzPxL9zVLFyFJzoxfB+JL8Ickln7grHSmQarzcIHvIvOh8mo/AF7Nk4Ur0Q0BgiHak28Dp8esa3E0nGKpE6BT5Zqwdow0AaIllraI91KgzG1hg7YcztJwwM/3/meC+5PKl0aXEJt6rlhxE+HThiWZjpuVqz/CMaZbeHcmodgbs13jqV7V3M/ah0bqY1wYimhdW//Dbb+Ft15MaxpJXvIdQAAAABJRU5ErkJggg==")
    Jeddah = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAOVJREFUSEu9lUEOhCAMRfFKLOc4ZJaeh80kXMeNmStpIKmp2ELBgjsT4PF/f8tijDnMxC+EkGjLLDAAQeMUMECdc4kb/4eDc+gUMAUdCsb1BHtxfodZHQ+mgKB2SKo5ezFUHVyCWvtx6/pNTRzdUEs1l958NkEJVMBUn3JAlQFCpbdkN75Mt+KStVyiX4M5qPc/u+/bX/LmNCt+q7SrxlrQpj7WhLLg/O3ENYvBqc3irhrnUG7IwwSSQKg1t3DVelBD6SNcUqikRyUuJMUYWquv5FDJmhsYNmipKl3gqnHNaomKljUnNfqX0daDTRsAAAAASUVORK5CYII=")
    Marina_Bay = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAANRJREFUSEvtlkEOxCAMA+G0f+H/X+Exe6KCilUUGRza0F6Wa4UHO0khhhBKeGHFHeBSsJcYK+5cf7BLtWvUMtYe/XLUsmZy8+iULmDUKAy+Ddy6UnSodn4JzBxaYl8GW0Sru9GcSufm5rJCuziDm8AjqBbXdZ3BKbiI3RZh1tFoxOAcdzASlBuY+9mf5xZYNxWKcqm5rI5fBc9GiSWgfzrtWkQ1kBApmlL65Jy/uqa3wPpUowN5XGG/hwCa5UfA1vp5uIVPH3ZJbAN7CTOdLY89Bq3fD83XygEqsyObAAAAAElFTkSuQmCC")
    Montmeló = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAARdJREFUSEvtlbEOgjAQhq8xGAcGn47JRcJq9EkcTYhJVx18Ooy6IWmTkvN6xxFChAEnA/T/7v971xoA+MIEP7OA/5X6vKK21kbG8zwfNYwfxxiIQe45BV8fJayqJHoeqqPF0/UeLAGxCF3YtYZLzGlhDWOt9XPcFSV1HITdGvyfug2anHsP1qC0MKkQ/J1WUATWGsu9r54vOB0PUbNRmAR3RkUwlwInROkaPKTV7rGpa9gXhdfhuri83SH5vGGdprDLss7R4uB4v71j3NW0GehIaU2Iq5HGqXUcLgkpIiw25BCR3LMHyBBAn2PtUp5hk2z96EZndZ8G6gPhvsHa7CUhnTxDgdx2zet2GsOZprE41hIa7f1kUTey2b8BM0d25gAAAABJRU5ErkJggg==")
    Austin = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAATVJREFUSEvllTEOwjAMRdtzcAIWjsMBKrGzIBa2dmRDLCAyMSAOwYbUtRJi5QBcoQKUSEbG+k5TSGGgS6so6fv2t500SZJ78oMn/RuwMcbl9ysRE4w72imYA7Msc1y7Zr9bg5F6X20SkKD2HQwmlVxx20YgwSSkMWKZLvmDEAHoDATbjZvVdnQsD2uKlh/mGeBgTSSlVy0u6Z9NiwTSYe4drUmRCEh7XcSDfm82nuSFXZzn0+H5ct2H+IoiRIKQHQ6MPGgCy0wslqa41fWpqspdiO9Pj6VvPjDqzxAY9BiB+UatH9sCXzyWzc2LRRbTO+2keixBWoHEgsJLQvt5TKh6O6EBoQ2Njz1GE0gWVGiPhohRZ7VW5bHgXjCq6M7BqNJj+tx4LfIe9w39EF/V28l3OHY7PQCcyte14s6trgAAAABJRU5ErkJggg==")

    #Tack maps selection
    if F1_LOC == "Abu_Dhabi":
        MAP = Sakhir

    elif F1_LOC == "Spielberg":
        MAP = Spielberg

    elif F1_LOC == "Melbourne":
        MAP = Melbourne

    elif F1_LOC == "Baku":
        MAP = Baku

    elif F1_LOC == "Silverstone":
        MAP = Silverstone

    elif F1_LOC == "Sakhir":
        MAP = Sakhir

    elif F1_LOC == "Spa":
        MAP = Spa

    elif F1_LOC == "São Paulo":
        MAP = São_Paulo

    elif F1_LOC == "Montreal":
        MAP = Montreal

    elif F1_LOC == "Zandvoort":
        MAP = Zandvoort

    elif F1_LOC == "Le Castellet":
        MAP = Le_Castellet

    elif F1_LOC == "Budapest":
        MAP = Budapest

    elif F1_LOC == "Imola":
        MAP = Imola

    elif F1_LOC == "Monza":
        MAP = Monza

    elif F1_LOC == "Suzuka":
        MAP = Suzuka

    elif F1_LOC == "Mexico City":
        MAP = Mexico_City

    elif F1_LOC == "Miami":
        MAP = Miami

    elif F1_LOC == "Monte-Carlo":
        MAP = Monte_Carlo

    elif F1_LOC == "Sochi":
        MAP = Sochi

    elif F1_LOC == "Jeddah":
        MAP = Jeddah

    elif F1_LOC == "Mariana Bay":
        MAP = Marina_Bay

    elif F1_LOC == "Montmeló":
        MAP = Montmeló

    else:
        MAP = Austin

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text("Next Race: " + F1_COUNTRY),
                    offset_start = 5,
                    offset_end = 5,
                ),
                render.Box(width = 64, height = 1, color = "#a0a"),
                render.Row(
                    children = [
                        render.Image(src = MAP),
                        render.Column(
                            children = [
                                render.Text(Month + " " + DAY, font = "5x8"),
                                render.Text(TZ),
                                render.Text("Race " + F1_ROUND),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "local_timezone",
                name = "Time Zone",
                desc = "Select your Time Zone",
                icon = "clock",
                default = "CST",
                options = [
                    schema.Option(
                        display = "EST",
                        value = "EST",
                    ),
                    schema.Option(
                        display = "CST",
                        value = "CST",
                    ),
                    schema.Option(
                        display = "MST",
                        value = "MST",
                    ),
                    schema.Option(
                        display = "PST",
                        value = "PST",
                    ),
                ],
            ),
        ],
    )
