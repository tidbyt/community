"""
Applet: Formula 1
Summary: Next F1 Race Location
Description: Shows Time date and location of Next F1 race.
Author: AmillionAir
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23067

# ############################
# Mods - jvivona - 2023-02-04
# - temp override URLs to bypass blacklist on API (will go back to original API after they unblock us )
# - remove location from schema - this was causing too many API hits - no need to use location anymore - use $tz now
# - only hit API endpoint we need to each time, instead of all 3
# - only execute render / vars needed for selected display option
# - change f1 API endpoints to https
# - added in US Date / Intl Date option - only triggered when showing Next Race
# - added in 24 hour / 12 hour display option - only triggered when showing Next Race
#
# jvivona - 2023-03-08
# - update Aston Martin logo
# - change WCC layout
# - added proper case names for constructors
# ############################

DEFAULTS = {
    "timezone": "America/New_York",
    "display": "NRI",
    "time_24": True,
    "date_us": False,
}

#30x24 track maps
F1_MAPS = dict(
    yas_marina = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAO1JREFUSEvNllsOxSAIRGX/i/YGEwyOiKgkt/3qQz0wDFYqpdTyh4s+D651FIaIY76/QhkLVGD4fIPfgleQV7gL5sVRUv3uBb4EW4vqOr/KboI9eRmIStxkPoEtedk8evFVCXhc1O0DOGqkSHA7p3ewJ5fVTqvMorIPYDSMSGfV1JM0Am9grB8CT8HaE1pyHSwJVWeL9zdgrDG2YgOvetLqW8nGkhr3c8vlXV0ER9rBc7WebwUiSkwZZ4K9lkoDR5w8GE2kPplo/ShOdq02tvfSwXaHtYuUB2Wf2mm31WV93x4EskBTxp8/7GVn/gMjGOn79JCBIwAAAABJRU5ErkJggg=="),
    red_bull_ring = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAS9JREFUSEullisOwkAQhrcHQHEEDEFxjRo4A3UIMG0QNMG1CSEIDLKcAQyX4AIk4NA4BAqyIUuWZTqvVjVtZ77557HTyBjzMsKrqqqvRZIkQuvP55EU7EMdUQMXgSGl7pkUzgbXpbcObJ9jwZBgrJ4YlCoDCqZUWuehKm4PgGDfeFxuh8/Lae8USDNQl5U/MNYsGLTfa+fTbFVAdYV8/oC1UKqzoYBZijkBYR1MKg7r6DuDjCml1h+7xlx4Eyh5ZGIqoVHyD20qMPYBEqZdWtNwk5BgrE7QWqKUOhsWmAvvdlqjWb7ZcRYGG0zBpTtaBMbgFrycZPH5cT9y/gzEYB9u78t1Opin60OxyOLrjQclx4mKXJpe359KcTivnGZSjROlXPO+sWINtHGNtVBr9wYhpcwBXE9y4wAAAABJRU5ErkJggg=="),
    albert_park = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAANVJREFUSEvtlkEOhCAMRetmXMwtORi3nIVuxjBJCWBpf1FjYsYdofSV/7EwEdGXbvgmCRxjrEoJIZxe2g7MUIa147MqqMA9yBXwDLaSW/NeJSqw5WWCWzFoAT8wuptngREJL9kxCk4eIrGW19ljNJl2HnhuWd80vz6ZLeV2g1M2CW71gFapIXAJLyXVVGvPh+t3snzT5ltFXA3kCJhVYlX+4KNqquvLAwbfTqMV9R4V4n3cg6BNhtdrzUZ8+khg9AZDoCkGBveahmaBppALPOqztO428AbVhp8B0Iv3ZQAAAABJRU5ErkJggg=="),
    baku = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMBJREFUSEvtlEsOwCAIRPGqHsyrtnFBg5SfFuOm3TSxDW8GBgsAXHDgKRq4tTbIqbWmynuBKRBheJYJH8AWIBv+gCOFI/9E5zGAvVYeA3c3He4JjLiecozg/tbgUjglIa8ZW0WxgNZyeu6NxVwnSam2YhLIgqsXiATlbYxcMhp8Cuy1WguVBF8C05AhzEs6hy+DufvZUH4GRwWkO+ZztVaNjiPNMRXA4anh8q5Fb9W2OI6s3Vaw1ZUf7GUm7fuxVt8+K40BrvuRmAAAAABJRU5ErkJggg=="),
    silverstone = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAO5JREFUSEvlllEOgzAMQ8tVOVivuolJmTJjN3ElvsYfofCI4xqOMcZrwDHnxNLn/DxPWt8pHgjO0ABF7VHw9fYM5MDZy6Mqt44zOBY7nbMxMaUoGOH5xlXnzphssBqFWy+lVoZSnXfrP2Ccz8rFruShSDzzC+44MTuz4/JrDfrjcbDakjfwyhwsmTpS46iyAnLGVUqhjDgGdr8Er/avynPWlcr1JdiFu+FCZ9ztKtblDtyZy+TKD2fSZVC1tdj1Eqyk74aNyocWuANXLsYvXJy3wbv7XDncArNvdfXbo/LABnfhVQBtgasuO9f/D/wGKEThAfM9liIAAAAASUVORK5CYII="),
    bahrain = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAO1JREFUSEvNlusNwjAMhN21kJiBHTKYd2AGJNYCBRHkGj8urqq2P6v6vtw5cbMQ0YsOeJZTgJn54721tnsGP8cDOogVeNdA61zwrHO5cAT+B+5FsyKyRWi7VmC5UhRugZDIXXCPGoF74KxVIRiBe9FmrlNwBo/AkWsIHMGjdnxdX4joqQcDDE6c35j5bsyAKzM/rOM1BR7CWbwyYu9b6Dh589NyYkVvbTQTjA4Bb0G63tILwVv/FNZAGu82RR0tTLdBuy5trmoSEm7+JKrCWV0IzmZsJp5tuKG/uvroy0AVgvT+HHeuPRx6moc5fgMOQ8kBS0aTsgAAAABJRU5ErkJggg=="),
    spa = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAPFJREFUSEutlksSwCAIQ+1VPZhXbccFMzTyCWp39fcMYPRprb3t8jfGWFbsvf/anptgC6hpGn4FjEBUJ/1XwUxYp2qEHynOlGKi53hRvQ2uQlH1FlhDMZ8aIIr1GJl7BGagCN8GWxUqi1uR8IqvpLgKjTZEgbOcYl6tFGCFp2AGGinz3JgGMyoqykMwq1YbAwt3wRVodF5nnxUtE7wDrcJDMDqO5UCiyNus176ArbOKk6sQ6lrUhVK52CvuNSP3U4w78/69gskqWq+3gCWPnj3i0bEMIkuFq9iq0J33oJW244cAsxHvZppzU8tkANEYL+wfPGPbtSObuxwAAAAASUVORK5CYII="),
    interlagos = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAUCAYAAACaq43EAAAAAXNSR0IArs4c6QAAAOBJREFUSEutllkOwzAIRJ2r+mC+aisiURE8w+ImnwbzWAzkGmN8xsG31tpuzTnLlq4O2MMsKJIhb0JwFJWViQNIV4AsCxs4M4CAzLjqIvkPXKkZMiRnKGKFqdyn+wZX64OM+AwIwOqxqB/g7FVGqdOIvA5yTHRbYI2GPRrmGIK3wRGc1RPdOQIzeFQKLzsGd+Gvgqvw12rse5L1t9ezXbP1cdZSbAtkcG+3Nbmi1VPpcXv/MavZnI6GPRsc2X6k26nrxF8RZ/VDcrsMKplRG60fAds+zMnq42yDWSvpeRX8BcU0yAEiV5CMAAAAAElFTkSuQmCC"),
    villeneuve = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAALJJREFUSEvtlFEOwCAIQ/WqHsyrbmEJi2GAVjH72PzX12JLTikd6YWTXwXXWk3PpZQt87gcE1gDsKAd8CEwWY6G3+B2nhLSfkWUgEe4PIiVhRkxaqoRh1KMJUK+6dYJDZfXDs4JB7nbYyvxsx2DwJGpHgYTNNI1DI5yDYHZdQQcBrdwKQDtPlWum2qZXq237ELWzxMEg1mItTi0LmtLZRq8+u9L4NklQvd+8Mr0oLvfG/UJCLWBAUc8CsQAAAAASUVORK5CYII="),
    zandvoort = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAQlJREFUSEvVlU0KwjAQhV9BCgquvGFAPIqLrtxJF7lDb1FvZCn+kEIhTGfSTBIVuyzNvHzvvSYVgBcKPtbaxTRjzOJdVVL4YhvscYAv5DbyceGZ9ifCVNR5rCameXED/PCorZLNbo2YMbWNs5E2ppgwJQwRuE1kC0t0XxGeaWNybu0VG9ST8zGNFjP2yWIo56w10bDlihH2nZDarm41FZZOVDaO8QFzOk5LkoSlH5/bhORQsjBXlhA99+9LMaweIJwQN0x74BS7naReqIk1V7SWNnhWa4Vpw9culGyrU2iLEHPZrtH+v7DfhxjaIsSaEvrfZpfrOYy49T26rsO5aabZ43BHvdsG9/QGIAHgAVrd/A4AAAAASUVORK5CYII="),
    ricard = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAL9JREFUSEvlllEOgCAMQ8dVOdiuqsEE0kxgMgZ86B+J8LrSTQMRXXTgCf8EM3MxO8a4xfjAzNU7Xi2ggBGEDuTyvYVUwei1FOElQAWvEvG002i4PK6i9LHVUuu+1wAZrT5fRc0F2ZeYj+bkmrHziwh1ZM4IkBXjWSq4tXmmrZKAYXASYs0B5sEElvC01iYfvmOuuJXkDM+O9NbminsTreUACnEB1xyQ4UsuLAP3PuRHwSjM1Wrt1wVDtxV8rGIE359WgYVHgSQxAAAAAElFTkSuQmCC"),
    hungaroring = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMBJREFUSEvFlUEOxSAIROlVPZhX/Y0LE2I+nUcDqWv0OeOAl5n9DKw5p40xQCUruQh4QffKwPe+f3vawOqyGLxuTe32SqM95eDT3nZwZG0p2EPODJ9BagdHaS8Hk7YqaSefapLulnZS4CelOxPpdlITjEDXGSkwmcLKjVeKKVi5klasAuMvpixPWb1tVHYq6CvF6rMg0DYwGS6lVlO1KcU+qdEbq7f34cOKFTijFitehV5N5luMeh8pJoMjW/MZ+AbpNu0BfO8cJwAAAABJRU5ErkJggg=="),
    imola = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAL1JREFUSEvtlkEOhTAIROlVezCuqsGEpGopg0L8i9+NidZ5nSk0bUS00Qej/cEVqTPzSbb3TqVRj0CByZB3EPi62mgiClSoPF2wQsefo2Cdf9Uyo66EymKm4GroElwR77hNN8dZbj2dKfitWw86jVr7LKt6LR3IcbSXkcRCYEQQTeq3weMZizry5p0cr6oRqVQPZvaxV9He90dgxFE6GIFm73Nj5uOyZ7XK7PYQidQ8QBS8EsvsX+WUXn1WZnbvLooBjuS0RwAAAABJRU5ErkJggq5CYII="),
    monza = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAALJJREFUSEvtlEESgCAIRfGqHsyr1rjQUYIAFdrUzgZ9/P/RBAAXfPAlDC6l9DZyzm4tdTAGtrUXfAKPkFBw9TUKPmVcVWJrqX8ngn+Ao1SL4NqIR97kdaLsxk7s2s3eY2+4Gnza8ge4AbiH41Tey+DdzM3g0XJqwLRPLAuWFI1vu2XCW2MkWMrZAmq1eDbCwFjMK1iy26JcrVgaIgt0rBUzXj1Yu4+1WnvAat0PXnXOvO8GDXd+AZeOFjMAAAAASUVORK5CYII="),
    suzuka = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAM5JREFUSEvllFESgCAIRPWqHoyr1uAMDe0AaqV+1GdSb3cBc0rpSBuevA1MRJfjUsoy73krmJ0SUXXruZbzqGYkrupYYBGcz0RgS1xPy25gVmw504JEgHanv9HvIwFXj7EIf6ZT0bVWSj1tqevkQayeoWMrAS85/b/bHnuRtYbGm5HI+fAF0uNQT74H/wSMwycJRdvyGhwNVzSEj8DYc2ttUBBGPgxuDZqcR/cB10wDty6jqeAIPh1swbkNS8AIn95j78rdAhYxy6JG9/8Dn3HOqh1POfEfAAAAAElFTkSuQmCC"),
    rodriguez = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAALlJREFUSEvdlt0KwCAIhe1VezBfdaNAsDOL3BJhu134efwvRHRRwlfSwcwcqrvWOtjvigWKP0950uw/wMzccxwFbbYxmo1VEKwfRTgj6odQS2gb0ArPidAPYMtgKnil8E0adBG7+9gqlJ0UYO24wQLxFiG27Guw14FQsO4KHX5rQH1WjPm1ICngWS0cVywjUtpttgf+CV5tvVDFaWC9Es1DYGfked7ggjEPgYibC1soBTybZiHFtZOWG3LFlgEHTQNtAAAAAElFTkSuQmCC"),
    miami = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMhJREFUSEvtk1sOhTAIROtWu7BuVYMJDdbCjPX54f0yF+UwAzOllOb0wm/6wU+5/h2rSym3ic45194bxQq1L1w1Rdv7MbAIELiK2u2YsXrUkRCMrD2zjlNgtUwHZNWHO0Zq27pdSzRAz6VLcmwt7A3fq78Lbi+Z3ZuqixR7x7gqth96cfKGia48qu3A3o68K/bUothRYGupPKt6rzmCSo8KZqIkQHQPDLSCGSiTWRZ6CNza3bPc/ofEDOcYWX4bGDVG9WHFqDGqLxWLkAEqukfRAAAAAElFTkSuQmCC"),
    monaco = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAP1JREFUSEvtlk0KAjEMhTMbN4KnE9y46r0MCJ5SEKWFliRN03Q6jAt1WTP98l5+ZhYAeMMXfssfvJfrTasRscohhLBZXhWYAimodb42EwbOl1vKPDGeZCqwhGogL1yWi95dwBYgK9Cs19zRyhLPmmBNbT7zKvfGMcUWOKr2uBLjpDOH4wmulzMrfRPcqmMPbiV/uz9geT1TAgksL+s1T+9/Kk1rsHhWwFYttfEYgcvnK/DokrDGxUo2WY2I6bUYFcuW9yyCHNNLWjqUwNTm2X2s7XhtD1RgOQ4jqkdimdV5VmdVexJgXT3TqR4YjWFzvJfNZYGMZrtF/O997H0A8I3DaSiMS50AAAAASUVORK5CYII="),
    sochi = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAMxJREFUSEvN1lkOwyAMBFC4KgfzVROBBGpGXjB2lfSvVdWXGcC0llKu8sKrfhYmotVHay2tGzPxL9zVLFyFJzoxfB+JL8Ickln7grHSmQarzcIHvIvOh8mo/AF7Nk4Ur0Q0BgiHak28Dp8esa3E0nGKpE6BT5Zqwdow0AaIllraI91KgzG1hg7YcztJwwM/3/meC+5PKl0aXEJt6rlhxE+HThiWZjpuVqz/CMaZbeHcmodgbs13jqV7V3M/ah0bqY1wYimhdW//Dbb+Ft15MaxpJXvIdQAAAABJRU5ErkJggg=="),
    jeddah = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAOVJREFUSEu9lUEOhCAMRfFKLOc4ZJaeh80kXMeNmStpIKmp2ELBgjsT4PF/f8tijDnMxC+EkGjLLDAAQeMUMECdc4kb/4eDc+gUMAUdCsb1BHtxfodZHQ+mgKB2SKo5ezFUHVyCWvtx6/pNTRzdUEs1l958NkEJVMBUn3JAlQFCpbdkN75Mt+KStVyiX4M5qPc/u+/bX/LmNCt+q7SrxlrQpj7WhLLg/O3ENYvBqc3irhrnUG7IwwSSQKg1t3DVelBD6SNcUqikRyUuJMUYWquv5FDJmhsYNmipKl3gqnHNaomKljUnNfqX0daDTRsAAAAASUVORK5CYII="),
    marina_bay = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAANRJREFUSEvtlkEOxCAMA+G0f+H/X+Exe6KCilUUGRza0F6Wa4UHO0khhhBKeGHFHeBSsJcYK+5cf7BLtWvUMtYe/XLUsmZy8+iULmDUKAy+Ddy6UnSodn4JzBxaYl8GW0Sru9GcSufm5rJCuziDm8AjqBbXdZ3BKbiI3RZh1tFoxOAcdzASlBuY+9mf5xZYNxWKcqm5rI5fBc9GiSWgfzrtWkQ1kBApmlL65Jy/uqa3wPpUowN5XGG/hwCa5UfA1vp5uIVPH3ZJbAN7CTOdLY89Bq3fD83XygEqsyObAAAAAElFTkSuQmCC"),
    catalunya = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAARdJREFUSEvtlbEOgjAQhq8xGAcGn47JRcJq9EkcTYhJVx18Ooy6IWmTkvN6xxFChAEnA/T/7v971xoA+MIEP7OA/5X6vKK21kbG8zwfNYwfxxiIQe45BV8fJayqJHoeqqPF0/UeLAGxCF3YtYZLzGlhDWOt9XPcFSV1HITdGvyfug2anHsP1qC0MKkQ/J1WUATWGsu9r54vOB0PUbNRmAR3RkUwlwInROkaPKTV7rGpa9gXhdfhuri83SH5vGGdprDLss7R4uB4v71j3NW0GehIaU2Iq5HGqXUcLgkpIiw25BCR3LMHyBBAn2PtUp5hk2z96EZndZ8G6gPhvsHa7CUhnTxDgdx2zet2GsOZprE41hIa7f1kUTey2b8BM0d25gAAAABJRU5ErkJggg=="),
    americas = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAATVJREFUSEvllTEOwjAMRdtzcAIWjsMBKrGzIBa2dmRDLCAyMSAOwYbUtRJi5QBcoQKUSEbG+k5TSGGgS6so6fv2t500SZJ78oMn/RuwMcbl9ysRE4w72imYA7Msc1y7Zr9bg5F6X20SkKD2HQwmlVxx20YgwSSkMWKZLvmDEAHoDATbjZvVdnQsD2uKlh/mGeBgTSSlVy0u6Z9NiwTSYe4drUmRCEh7XcSDfm82nuSFXZzn0+H5ct2H+IoiRIKQHQ6MPGgCy0wslqa41fWpqspdiO9Pj6VvPjDqzxAY9BiB+UatH9sCXzyWzc2LRRbTO+2keixBWoHEgsJLQvt5TKh6O6EBoQ2Njz1GE0gWVGiPhohRZ7VW5bHgXjCq6M7BqNJj+tx4LfIe9w39EF/V28l3OHY7PQCcyte14s6trgAAAABJRU5ErkJggg=="),
    losail = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAARFJREFUSEu9lkEOAiEMRSVu5qgmLnSnx9Cdt9WUWPLptLQww7gyAn39vy2YlvPyPTU+t8u9rL4/r9bWrrUUAROQE4jCMWHMiM9ncEsVrfFm/N7rkmSkx/W5shpVSTABPdWWO/h7AaOdHFwL4FkeWSdWBkuFCNbUtSwfBhOUA1uAiJVWD3DMymrePAts1hjB/F1avYdail3GSQNE6+vVlcuHE2GCWzXCACPQSnFkPrVSeOesxMqVGb2VIn2AboXAXvZdr8B/swvWGmAEpJ3R3Fy9TjOeQS2m+SxGurXHERnvMDBexWWcZOZ7q5WTkF8n/Acyo76WqGqOZ4yT1eXDF0hPY2mqD1fM5TRrvEWRd5aa6wcSQ//lot1eoAAAAABJRU5ErkJggg=="),
    vegas = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAK1JREFUSEvtlksKwCAMRPXchS4KnrslhUCM8TPiZ2N3YsybjElb75x73YbHH/Aq17NWhztEGq7ngjXJHPq8CdZQJqLwkvgsWEMoSQ+Yz7AIXk8Hk1sWfCqYoLpSXkNgqR7pNAuegHUQA3INhwiQlkfgUvsjgFoscX7wiJmtweR+AkbHBYEdcHTHy62Wg947q633bb5ArFkd6YLMD32dWquqxVEx59en5tKw/W1WfyNwf9lkVs6WAAAAAElFTkSuQmCC"),
    shanghai = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAAAXNSR0IArs4c6QAAAQJJREFUSEu1lbEOwjAMRFux5FORGGCDT4ANBiQ+tQsCGemQMbaT2Gm2Vkre3dlx5rIprym5lufSfcIcBe+3hx/Y5X7ugofAgAJ23J0+UPoumzK1JBAGEwRADoXtGjwNlhFzMRChlSEN1grLQSTk9rj+xR8G02Eti/phVbDsci5qSNQAcMfaPwJ7DdYdtQX2otcEhMASgjpaNU+DrUit/1yIhHc59pzx5tJiXw0Md5q4IVFbTeQ5Hg6Wd1cTlR4gkWskU+DOm5or0s18j+b6C/ZGHjVOS23lPcaeKhjDnB7zUYs7V6OuOc4IGfY6RUSkBkjtxeGCUC7rhWrqam/mRtzTnjdMAuQBNhV1ogAAAABJRU5ErkJggg=="),
)

F1_CONSTRUCTOR = dict(
    mercedes = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAHCAMAAAAPmYwrAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAz1BMVEUAAAD///8AGyt+jZW7xcWtuLumsrYtREwyTVgfPUkAGB4PHiavu7yhrrGfrK+bqKufq66aqKzDy8yrt7mUoqZ+j5Wst7mLmZ6JmJ6ElJp5i5LJ0dCaqKt7jJLCycuLmp9SanNXbndacHhebHFldnt6iY/Dy82os7ePnqK0vsDw8O5leX9TanIiP0hVbXWIl52FlptSaXFKYmt1iY+Qn6N8jJBHYGd4iZB8jZR0ho2DlJh8iYxncnaPnaORn6WZpqqQnqKCk5hld3wAAAD////BmiGlAAAARHRSTlMAAAAAAAAAAAAAAAArZnyDaTgBJmMaQ1sSWzcCXx5niQ5nCQhlCDfA0kgEYBUCYmGDWVCEYmwJKnkeE3A+LWlkYms6ARiX1DcAAAABYktHRAH/Ai3eAAAAB3RJTUUH5gIQFyEsgT6aNQAAAF5JREFUCNdjYGBgZOLh5eMXEBRiZgABFmERUTFxCUkpMI9BWkaWVU6eTUFRCcxVVlFVU9fQ1NLWAXN19fQNDI2MTUzNwFx2cwtLDk4raxtGMJeLwdbO3sHRyZmbgQEAbsMI6BPx2gMAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjItMDItMTZUMjM6MzM6NDMrMDA6MDAZnGoiAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIyLTAyLTE2VDIzOjMzOjQzKzAwOjAwaMHSngAAAABJRU5ErkJggg=="),
    red_bull = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAHCAMAAAAPmYwrAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAkFBMVEUAAAD7wibufDPtdTToWTn5syj6uyfraTbufTP2piv/5CL1pin0oSv1oyr0nyrmTzvqZjfrbDblSTzpXjjzniv8xCbvgDLscjXmTTz5tij6vSfpXzjpYDjwgzHscjXjPT7fKULufTPxijDgL0HhNEDraDbscTXmUDvmUjvxjDDzlC7nVTrlSTzqZzf0niz////6c/clAAAAL3RSTlMAAAAAAAAAAAAAAAAAAAAAAAAAAAAACgYXREodBwpLlsr2+dKdWig6Rm50STkvAU4tgvAAAAABYktHRC8j1CARAAAAB3RJTUUH5gIRAgEN+oKoNwAAAmR6VFh0UmF3IHByb2ZpbGUgdHlwZSB4bXAAADiNlVVbkpwwDPz3KXIEW5IlcxwG8F+q8pnjp9vszLLA1mZwFTaSrW69TPr7+0/6xaeZJ120R4vsxdUfXsMku3j18Mk3XUW2/ng8ugjkkxslNbTaqtnWyKbY23xK1mIOHKwas23VHDMMquKQiHbdJOsSTedojoO+EsyLZH774lsodYkIYGPeyUPnXfHaPph8moHswRP2OiG5NltrTkJyPYZIq2yaZQWfrI4V3wWyoqqmwSELpAJ9gb5jFryLSpIVU+iMrYJ35vHTkA/3BCxc5ypm5ifXJA0l3WthGFlnuNNjPLIFdsk2GMdAnjheTATvdQcAI/BFfhiRaHALCNR/ZQEKSBUSIT6NSE2IEHY89V4SAtYDgSWrPbDHXDDAtiLVF84DcPtMU8IHgu0r3GngxACWEXLIKL0Y17DKOjsFJN1Z/944KzHgHPZ0mgsd/ohrQikO+4zLnWM/O7XDpjvcp8mP+MzGrE1708DAYjShUVm2TJNNZqOy90OwbKObZpahqYk2xSe6JqPKiolVlGXBaGN2zNWKwq6VxBJUMVauXZjcIN8BAwpNK7BdYVkGD9nRsSL6BDxg2s5QraKmK7RsF5bkATgNZBaksiSdgasX5OkT+QBcj8DpPWQYY3VXJMfYOJXOd190TacrIeOS6mOTjlXm7VBVqduzRh1a8NVEX1xjJ7GLHFj4wJrlmA9VPPsP7qen/wi1vJvyY8bT8P+I/J8pP9daehdZeA+N6Eg/XjLpesuct+034kt6+Q3smnTzM6rMzXBH9v9I+gfI1olc/kDIjAAAAElJREFUCNdjYEAHjEzMLKxs7OwcnGAul5i4hKSUtIwshMstJ6+gqKSsosoD5vKqqWtoamnr6OqBuXzs/PwCgvxCwiJw40RFITQAzjUEhItFlQsAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjItMDItMTdUMDI6MDE6MTMrMDA6MDBe+17DAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIyLTAyLTE3VDAyOjAxOjEzKzAwOjAwL6bmfwAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAAASUVORK5CYII="),
    ferrari = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAHCAYAAAA4R3wZAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAESSURBVChTZZCxSgNBEIZnZnePBBUPwhVCMJXY2ci9Tmo7UcFGsLa28wkEsfMBLLSxEBsLEQXTJKLkgokmZPd2xr3jOAx+MOzO8v07MAgAEqrk6HAv082VmMQiAX8JkkLgHxby/ae7q7OL651KhToYRQC9hyhHEhRBvDxPRt/zWHW7L0tKsc4d+vaW1YVbQNUJ1oZGi2JBtX+8RvfPqjXIxrFpeB2+F2DhSi2pg8aUo9HmwQqXyYxgNEHwDtEzEi3zvFJL6qBzYSrwVEUMB7ufkG7PQGuGk9MEeu/Gh/BCcGE5Bf1XJegIBkODN7dN6axbm6ZT6Wz6Ru4rKfAvWCzp7VHlyEQfmRq2Erfa3vDh9S8Av/Yvb4PcL9m1AAAAAElFTkSuQmCC"),
    williams = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAHCAMAAAAPmYwrAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAflBMVEUAHz4AAAAAHj0AHDsAHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHj0AHz7///9gIEbQAAAAKHRSTlMAAAAACgwGAgdUvKEWBXgYoxSwiQlw9o0p2dN98KLvftVK7bK9IBAbf1SEUAAAAAFiS0dEKcq3hSQAAAAHdElNRQfmAhcCJQfO1P9TAAAAX0lEQVQI1w3MSQJAMBAF0e4vxhBiJuYQ7n9Cqd3bFIkwIkYcgykJBaWZzFEoVaCsspR0/TVt1/edGL5aE8ZpNsu6bvsxjSDQKS+rtb3k6cEIzP0Az20Cv2OGe+F7HZh/Fy4F0QjMFAkAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjItMDItMjNUMDI6Mzc6MDcrMDA6MDB1SXsLAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIyLTAyLTIzVDAyOjM3OjA3KzAwOjAwBBTDtwAAAABJRU5ErkJggg=="),
    alpine = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAHCAMAAAAPmYwrAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAsVBMVEUAAAAAb7oAb7kAbrkAbroAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7kAb7kAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7oAb7r///84cqsHAAAAOnRSTlMAAAAAADDVxQwzv/qKCgs+wY/eSR55G0haY9AXO8h7iOXJxtd/Yg8JU3R2y+SCb4vtl3NEAthWTdojOksy3AAAAAFiS0dEOk4JxPoAAAAHdElNRQfmAhcCKzoIP57MAAAAYklEQVQI12NggABGRlY2dg5GKI+JkZOLm4eRESTOy8fIyC8gKCTMCBIXERVjFGeXkJSSZmZkYJKRZZOTV1CUU1JWUVVjUNfQ1NLW0dXTNzA0MjZhYGFilDA1Y2Q0t7AEagUA2hUG0AyU3BoAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjItMDItMjNUMDI6NDM6NTgrMDA6MDDrMbB/AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIyLTAyLTIzVDAyOjQzOjU4KzAwOjAwmmwIwwAAAABJRU5ErkJggg=="),
    alphatauri = base64.decode("/9j/4AAQSkZJRgABAQAAAQABAAD/4QAuRXhpZgAATU0AKgAAAAgAAkAAAAMAAAABAFsAAEABAAEAAAABAAAAAAAAAAD/2wBDAAoHBwkHBgoJCAkLCwoMDxkQDw4ODx4WFxIZJCAmJSMgIyIoLTkwKCo2KyIjMkQyNjs9QEBAJjBGS0U+Sjk/QD3/wAALCAAHAA4BAREA/8QAFAABAAAAAAAAAAAAAAAAAAAABv/EACQQAAEDAwIHAQAAAAAAAAAAAAECAwUEESEGEwASFTJBUXGB/9oACAEBAAA/ADbjKkyVVQyrVb1Rp9bs3WJqAQ7Sg35UC/nGPn420dojTszNSsu1Rrcj1q2m2n1ElDoUdy2cjtsT7PH/2Q=="),
    aston_martin = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAICAYAAADJEc7MAAAACXBIWXMAAAsTAAALEwEAmpwYAAAFu2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4yLWMwMDAgNzkuMWI2NWE3OSwgMjAyMi8wNi8xMy0xNzo0NjoxNCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIzLjUgKFdpbmRvd3MpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyMy0wMy0wOFQwNjozNDozMS0wNTowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjMtMDMtMDhUMDY6NTc6NDgtMDU6MDAiIHhtcDpNZXRhZGF0YURhdGU9IjIwMjMtMDMtMDhUMDY6NTc6NDgtMDU6MDAiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIiBwaG90b3Nob3A6Q29sb3JNb2RlPSIzIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjYxNWY2OTAzLTU1YmItNWU0MC04YTczLWJjMmFhMjRkZDZiYiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpjY2IwMWEyNC00YThlLWE1NDItOTYwNC1mZTEyOTcyZjRmNGIiIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpjY2IwMWEyNC00YThlLWE1NDItOTYwNC1mZTEyOTcyZjRmNGIiPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmNjYjAxYTI0LTRhOGUtYTU0Mi05NjA0LWZlMTI5NzJmNGY0YiIgc3RFdnQ6d2hlbj0iMjAyMy0wMy0wOFQwNjozNDozMS0wNTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIzLjUgKFdpbmRvd3MpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo2MTVmNjkwMy01NWJiLTVlNDAtOGE3My1iYzJhYTI0ZGQ2YmIiIHN0RXZ0OndoZW49IjIwMjMtMDMtMDhUMDY6NTc6NDgtMDU6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMy41IChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5J6lChAAABKUlEQVQYlW3OvUrDcBQF8HOThjY2mBYUvwYHNxHE1UfwFbrVR5BWBGk72zngIl0MmVwcXHyG6KB0KyiIg4WamPKnIU2OU0siHrjDhd/hXiGJRQaDgWaapsySGJ+TMbN5ip21DTHLFSil2Gw2s4WVfFFE8PMdigCEiOiaDjKjQGTFtliw+cV13b1ypWwEkyAxjFIgIkiSec2u2UYcx0mj0RgtbAm5JOn8uGas3nyYmTGM3sazQGHf3l7fqmwm0XR6CmD070UA6HW6uwdHh1cET0ACxMPw5bXd7fXeC5DkcjzP0wDg/tqVy7Pzeqd9UX+8vRMA8DxPy9tCkSQcx9H95yc9JeWLqfi+rzuOo/91hVdbrZZUq1VGUSS2bQsAhGFIy7KolJJ+v7/Ev8qjr/Z7UtF/AAAAAElFTkSuQmCC"),
    haas = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAHCAMAAAAPmYwrAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAA7VBMVEUAAADxCTLzCzP4DTH0DDPzCzL/chz0DDDtCTHzCzTsCTHxDTT1CzH0CzP1CzP2CzLyCjTzCjTzCjPzCjP0CjTzCzP0CzP0CzPzCzTzCzPzCzP0CzP0CzPzCzLzCzL0CzP1CzP0CzPzCzP0CzP0CjP0CzP0CzP0CzLyDC/zCzTzCzL0CzLzCzTzCzP0CzP0CzP0CzP1CzPzCzL0CzL0CzDqCTHyCzTzCzP0CzPzCzP0CzP0CzPzCzP0CzP0CzP0CzP0CzP1CzH0CzP0DDPzCzPzCzPzCzTzCzP1CzPzCzPyDDPzDDTzCzT1CjT///81BFTPAAAATnRSTlMAAAAAAAAAAAAAAAAAAAAACxgaEAErcX50fYN8TAhCs00RPZtHnNWEBy+5t1RwwZ+ajU/RHQEoYcq+wlOdiziWiAcqdoV0fHwIChgaEQIaa17CAAAAAWJLR0ROGWFx3wAAAAd0SU1FB+YCFwMAFKNbBF0AAABrSURBVAjXY2BgYGRiFhAUEhZhYWUAATZRMXEJSSlpGVl2BgYOTjl5BUUlZRVVNXUNIFdTS1tHV0/fwNDI2ISBwdTM3MLSytrG1s7ewZGBgYuT28nZxdXNXVrBgwdkFC8fv6eXt48vHx8DAwAB9gwkpTV3fgAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMi0wMi0yM1QwMzowMDoyMCswMDowMFRj5gUAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjItMDItMjNUMDM6MDA6MjArMDA6MDAlPl65AAAAAElFTkSuQmCC"),
    mclaren = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAHCAMAAAAPmYwrAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAyVBMVEUAAAD/1QD/swD//wD/ugD/qQD/sQD/vAD/uwD+lwD/ygD6lQDKeAD/7gD/twDykAD6lQD8lgD9lgD9lwD8lgDujgDkhwD7lQD9lwD+lwD+lwD+lwD+lwD+lwD+lwD+lwD9lwDbggD7lQD9lwD+lwD+lwD+lwD+lwD8lgD8lgD9lwD9lwD8lgD9lwD+lwD+lwD+lwD+lwD9lgDwjwD6lQD+lwD+lwD+lwD7lgDxkAD9lwD+lwD9lwDoigD0kQD8lgD4lAD+lwD///825eDDAAAAQXRSTlMAAAAAAAAAAAAAAAAAAAAMIzxPUTYJBSRXj73c7vX26FwEH12k2PPXNTlbYUNEXK36xzoHJunvkB4CWK5FBA5BEc5qJCUAAAABYktHREIQ1z30AAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH5gIXAxQ5yCqPfQAAAGFJREFUCNdjYAACRiZmfgFBIWERUQYGZhYxcQlJKWkZWTl5BQZFJWUVVTVHMFDXYNDU0hbW0dXTN3B0NDRiYDBmYGVj5+A0MTUzt+BiYODmARlmaWVtY8vLAAN29g58IBoAFEcKP1yC9RAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjItMDItMjNUMDM6MjA6NTcrMDA6MDDDbWhTAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIyLTAyLTIzVDAzOjIwOjU3KzAwOjAwsjDQ7wAAAABJRU5ErkJggg=="),
    alfa = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAHCAMAAAAPmYwrAAAABGdBTUEAAK/INwWK6QAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAt1BMVEUAAADIx8epqKgNDA0ODQ4IBwjMy8zMy8uFg4S2tbW8u7usqquopqeKiIiVk5SzsrKrqqqhn5+lpKSIhoerqaq/vr6koqPCwcG4t7fGxcXm5eXEw8ORj5DY19jNzMzY2NjY19eQjo+Ni4vKycnX19fZ2NjIx8eMiorGxcaysLGLiYmpp6hyb3BXVVWura21s7RmY2SEgoNOS0yJh4jS0dGOjI3BwMFlYmOamZnp6Oja2trHxsf////yxuvBAAAAKHRSTlMAAAAAAAAAAByCw8OCHBq3/Py3G3T+dZ2edP51Grf8/LcbHILDw4IcXmehwgAAAAFiS0dEPKdqYc8AAAAHdElNRQfmAhcDGROmPzjmAAAAVElEQVQI12NgYGBg5ODk4ubhZWKAAD5+AQ1NQSFhZghXRFRLW0dXT4wFwhXXNzA0MjaRYIVwJaVMzcwtLKWhemVk5ays5RUUoVw2JWUVVTV1diATADtkBuuaie/6AAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIyLTAyLTIzVDAzOjI1OjE5KzAwOjAw8THWsAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMi0wMi0yM1QwMzoyNToxOSswMDowMIBsbgwAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAAElFTkSuQmCC"),
)

CONSTRUCTOR_NAMES = {
    "mercedes": "Mercedes",
    "red_bull": "Red Bull",
    "ferrari": "Ferrari",
    "williams": "Williams",
    "alpine": "Alpine",
    "alphatauri": "AlphaTauri",
    "aston_martin": "Aston Martin",
    "haas": "Haas",
    "mclaren": "McLaren",
    "alfa": "Alfa Romeo",
}

# we will go back to these at some point
#F1_URLS = {
#"NRI" : "https://ergast.com/api/f1/{}/next.json",
#"CS" : "https://ergast.com/api/f1/{}/constructorStandings.json",
#"DS" : "https://ergast.com/api/f1/{}/driverStandings.json",
#}

# temporary override
F1_URLS = {
    "NRI": "https://tidbyt.apis.ajcomputers.com/f1/api/next.json?year={}",
    "CS": "https://tidbyt.apis.ajcomputers.com/f1/api/constructorStandings.json?year={}",
    "DS": "https://tidbyt.apis.ajcomputers.com/f1/api/driverStandings.json?year={}",
}

F1_API_TTL = 1800

def main(config):
    #TIme and date Information
    timezone = config.get("$tz", DEFAULTS["timezone"])

    # get display option - default to Next Race
    display = config.get("F1_Information", DEFAULTS["display"])

    # Get Data
    Year = time.now().in_location(timezone).format("2006")
    f1_cached = get_f1_data(F1_URLS[display].format(Year))

    # return data is already at MRData

    if display == "NRI":
        #Next Race
        next_race = f1_cached["RaceTable"]["Races"][0]

        #code from @whyamihere to automatically adjust the date time sting from the API
        date_and_time = next_race["date"] + "T" + next_race["time"]
        date_and_time3 = time.parse_time(date_and_time, "2006-01-02T15:04:05Z", "UTC").in_location(timezone)

        # handle date & time display options here
        date_str = date_and_time3.format("Jan 02" if config.bool("date_us", DEFAULTS["date_us"]) else "02 Jan").upper()  #current format of your current date str
        time_str = date_and_time3.format("15:04" if config.bool("time_24", DEFAULTS["time_24"]) else "3:04pm")  #outputs military time but can change 15 to 3 to not do that. The Only thing missing from your current string though is the time zone, but if they're doing local time that's pretty irrelevant

        return render.Root(
            child = render.Column(
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text("Next Race: " + next_race["Circuit"]["Location"]["country"]),
                        offset_start = 5,
                        offset_end = 5,
                    ),
                    render.Box(width = 64, height = 1, color = "#a0a"),
                    render.Row(
                        children = [
                            render.Image(src = F1_MAPS.get(next_race["Circuit"]["circuitId"].lower(), F1_MAPS["americas"]), height = 23, width = 28),
                            render.Column(
                                children = [
                                    render.Text(date_str, font = "5x8"),
                                    render.Text(time_str),
                                    render.Text("Race " + next_race["round"]),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

    elif display == "CS":
        #Contructor
        standings = f1_cached["StandingsTable"]["StandingsLists"][0]
        Constructor1 = standings["ConstructorStandings"][0]["Constructor"]["constructorId"]
        Constructor2 = standings["ConstructorStandings"][1]["Constructor"]["constructorId"]
        Constructor3 = standings["ConstructorStandings"][2]["Constructor"]["constructorId"]

        Points1 = text_justify_trunc(3, standings["ConstructorStandings"][0]["points"], "right")
        Points2 = text_justify_trunc(3, standings["ConstructorStandings"][1]["points"], "right")
        Points3 = text_justify_trunc(3, standings["ConstructorStandings"][2]["points"], "right")

        return render.Root(
            child = render.Column(
                children = [
                    render.Text("WCC Standings"),
                    render.Box(width = 64, height = 1, color = "#a0a"),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(src = F1_CONSTRUCTOR.get(Constructor1, "Red Bull")),
                                    render.Text("1"),
                                ],
                            ),
                            render.Marquee(
                                width = 50,
                                child = render.Text(Points1 + " pts - " + text_justify_trunc(12, CONSTRUCTOR_NAMES[Constructor1], "left")),
                                offset_start = 64,
                                offset_end = 64,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(src = F1_CONSTRUCTOR.get(Constructor2, "Red Bull")),
                                    render.Text("2"),
                                ],
                            ),
                            render.Marquee(
                                width = 50,
                                child = render.Text(Points2 + " pts - " + text_justify_trunc(12, CONSTRUCTOR_NAMES[Constructor2], "left")),
                                offset_start = 64,
                                offset_end = 64,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(src = F1_CONSTRUCTOR.get(Constructor3, "Red Bull")),
                                    render.Text("3", font = "5x8"),
                                ],
                            ),
                            render.Marquee(
                                width = 50,
                                child = render.Text(Points3 + " pts - " + text_justify_trunc(12, CONSTRUCTOR_NAMES[Constructor3], "left")),
                                offset_start = 64,
                                offset_end = 64,
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        #Driver
        standings = f1_cached["StandingsTable"]["StandingsLists"][0]

        #F1_FNAME = standings["DriverStandings"][0]["Driver"]["givenName"]
        F1_LNAME = standings["DriverStandings"][0]["Driver"]["familyName"]
        F1_POINTS = text_justify_trunc(3, standings["DriverStandings"][0]["points"], "right")

        #F1_FNAME2 = standings["DriverStandings"][1]["Driver"]["givenName"]
        F1_LNAME2 = standings["DriverStandings"][1]["Driver"]["familyName"]
        F1_POINTS2 = text_justify_trunc(3, standings["DriverStandings"][1]["points"], "right")

        #F1_FNAME3 = standings["DriverStandings"][2]["Driver"]["givenName"]
        F1_LNAME3 = standings["DriverStandings"][2]["Driver"]["familyName"]
        F1_POINTS3 = text_justify_trunc(3, standings["DriverStandings"][2]["points"], "right")

        return render.Root(
            child = render.Column(
                children = [
                    render.Text("WDC Standings"),
                    render.Box(width = 64, height = 1, color = "#a0a"),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(width = 14, height = 7),
                                    render.Text(F1_POINTS, font = "5x8"),
                                ],
                            ),
                            render.Box(width = 2, height = 5),
                            render.Text(F1_LNAME),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(width = 14, height = 7),
                                    render.Text(F1_POINTS2, font = "5x8"),
                                ],
                            ),
                            render.Box(width = 2, height = 5),
                            render.Text(F1_LNAME2),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(width = 14, height = 7),
                                    render.Text(F1_POINTS3, font = "5x8"),
                                ],
                            ),
                            render.Box(width = 2, height = 5),
                            render.Text(F1_LNAME3),
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
                id = "F1_Information",
                name = "F1 Information",
                desc = "Select which info you want",
                icon = "flagCheckered",
                default = DEFAULTS["display"],
                options = [
                    schema.Option(
                        display = "Constructor Standings",
                        value = "CS",
                    ),
                    schema.Option(
                        display = "Driver Standings",
                        value = "DS",
                    ),
                    schema.Option(
                        display = "Next Race Information",
                        value = "NRI",
                    ),
                ],
            ),
            schema.Generated(
                id = "generated",
                source = "F1_Information",
                handler = nri_options,
            ),
        ],
    )

def nri_options(f1_option):
    if f1_option == "NRI":
        return [
            schema.Toggle(
                id = "time_24",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = DEFAULTS["time_24"],
            ),
            schema.Toggle(
                id = "date_us",
                name = "US Date format",
                desc = "Display the date in US format.",
                icon = "calendarDays",
                default = DEFAULTS["date_us"],
            ),
        ]
    else:
        return []

def get_f1_data(url):
    f1_details = cache.get(url)

    if f1_details == None:
        http_data = http.get(url)
        if http_data.status_code != 200:
            fail("HTTP request failed with status {} for URL {}".format(http_data.status_code, url))

        f1_details = http_data.body()
        if f1_details.startswith("Unable"):
            fail("API having database issues, check again later URL {}".format(url))

        cache.set(url, f1_details, ttl_seconds = F1_API_TTL)

    return json.decode(f1_details)["MRData"]

def text_justify_trunc(length, text, direction):
    #  thanks to @inxi and @whyamihere / @rs7q5 for the codepoints() and codepoints_ords() help
    chars = list(text.codepoints())
    textlen = len(chars)

    # if string is shorter than desired - we can just use the count of chars (not bytes) and add on spaces - we're good
    if textlen < length:
        for _ in range(0, length - textlen):
            text = " " + text if direction == "right" else text + " "
    else:
        # text is longer - need to trunc it get the list of characters & trunc at length
        text = ""  # clear out text
        for i in range(0, length):
            text = text + chars[i]

    return text
