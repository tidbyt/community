"""
Applet: WantedPoster
Summary: Display Wanted Poster
Description: Displays a custom wanted poster based on an image you upload.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

WANTED_HEADER = "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"
DEFAULT_CRIMINAL = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gQWFhAKPofYMQAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAAJf0lEQVRYw22X2Y9cRxXGf1V1t957Nntsz4zHSzxODMYgI5LIeWCJACFCBEFIiO0JIfEP8IrEAwjxgPLAHxAEJEgJCMVYQGLFJBCDwcTxlvE2PZ6lZzzT03vfvvdWFQ+3Z3Nc0tHtuq2rU+ec73znK/H3v1+2QgiklAghdhmw9dxc6Tb931q79d4Yg7V2693OvbUWY8xu05YoinCUUrucSikBtp6pI5ASrLUIITAGjNEkcYJyFNYagiDAWojjeMd32wd42IdGo5TCkVI+MvrU0mjBgrVoramvrVCt3Ob2zSskcUyz06U0NEqhNExheC8zT5xgaGQMYzTGpM611ggh2AzWWgsWpNTbGdiOGISQg9QbhBD0eyFXLl6gvraC41gWKhW6rSZzi1USkzA2OsbduQpGGz7+8VOUR/bz9e99H6UkWustx7tLKnC0wflw/dlhik6zxZt/+i3X3rvM6HCZifG99Dstbs3NEUUxSaKp1TYIw5hsLsuf//YmSZJw6T+X+MkvXsRx/a0SbD63lnUfnQGwg73g7b/8kZvXr0Hc54WvfJmr712hVtvgQLmEGpSv0+vRCSOSRCN0gbVmm/v37/HGudd57oVvEkX9LXA+jAlnN+LlIHKLlIr/vvsO7//vXzRra/zohz9g+tRphLEEYYdCsYjn+ggp6ccRYdhjaWWV1XqDi9du0uhrXnvl13zxuRdQSu0C5M5DOFLuAB0WIUV6EODf/3wLYeELT59m4tgMuttmbylP4fQnMWEfrRMQhrAbEvZdCoHH0FAZz/N5/eJ/iaI+r7/2Ms9/41sYrbEDUG+C01qLTCMetIeSA+eC+sY6tbUHdHo9Dh89RtxsENZWwYDrSPxMhnwuTz5fxPU9PM8jn8tSzGUoFgvsHxtFCMWFN8/RatQRcjPDadlSE8i0/pvgG7SetXRaLd6/epXxsTGCICBqtUg6TayOcDIZVDaD8AOEF+BnC3iZDEKAYw35bJaxkREcpVhYXOLGtfdwXTd1uNX2g0NsttxOU45DrVZjbM9oivRYk0Q9dNjD6BilHKRSaJ2gtUYqgSMlWPBcRcYVZH0f11VYY3nj3Flcz9vClxApsQkhtkuw2YpSSpTjcH9+Hs91abW7tDttkALp+lghsEkMSQwmxooEo0OQFiHBywQEvksS9Wm3OijHYfb6FawxD7W6AATyUSyoHEWv0yYMo5SI+hHaGqQjcH0P5XsoJZEpigkyBaRUCMcBIdEactksWd8jjjVrtQ1uXH0fISU2JVWMMSRJst2GO811XO7fuk4plyfIuAg0ru8hpES5LgqFyAXE/Rgba5K4T2ws1XqTRr1BnGgKhSLZTEAsHJZXlnBdLyV1azDGorVBG4OzSY87+SDRms889SRz169wpVIhk83S6vapVZdZWlhibn4BoRNOPXGM4VyOyzdmeefyVYTncujgJI12j6A0QrlYoBPWGCkWCDIBcZygdRq5MYZ+GKVd8KExbC0jByY5sneYXOBSLBRYW15lY2mVq3eqhJElm2jazQ6lif18MHef00dnCPYdYbGu8RyX0VKO4VKRDIaTx4/jZ/LU6w0ajQbdTpduN6TXC9MS7J73AmsN45OH6F88z+ED+8nlMuQCQbS+weF900yOFHHbdYaP7sfzchydPsipmcf5lHSpzM2zoluMjxdYb3UYLeT4/Je+RqPZJOz1EELieR5KKXSiP4yBTb7ODY8yceQIjdUVon7M6EiBgzMTFFdqeEFA8fHHsUmMCft4rot2wc8pxo7uYdIbZ27hAYkVjJTL7Dk2Q6/bJY4jrCHVEUphLSkGHs4AgHA91PQRxrtNGq0OOdcwPL6PsX1TSAP9ZoNap4PvuXjKI+5HjE1O4bsbLC0vUalu4CJQ+SxrK1XKY+NAmt2wHw4khn10BoQQGGtYqbfYt2+MB72Ydi8h2+mhMi716gq16jKF8XFcz6dcLjFXWaToueSHiqw3ekTaEEV9Dn/iDNnySDpmrcViieOIuB9jrP1wBjaXFIKJU2c4/9KvmNxfZqhUYG15GU9Uqa08YM/Bxzj/1wsgEt69cZusgsnRIkEuINEGx1HsOXSMYPQAYRiilEIqBQP27EchxoC4e7dqd0a++dsYg9WGarXK0rV3mSxAd22d3kaNkYlDBNkCCYLl5SoIy8aDVZI4YbwUMLu8xmK9S27qcdxcmWKxSHloCD/wiKKYbrdLt9MliTXOw4Jx50pMQnloCO+jT9O5+RZ+4CKHi3wwO0sQOpSkTymbo7qwyEpjg1XTonT6BIk2SEcRG0HYauH7PnEc43re9ig2Jp0jDzvdJbONTesUZGm2OjieR75Y5MTMNDLRZKxHoLIU3QyeUkzvG8X3Jf1+iBYeyvGJ+n3iOEbrBGsNA6m5BUjnUdp/S7INWlJ5HhmliOKErOeQLeSY+tgBKpUlWrUV2qoHo5K9e4f43/XbRNqy3jbkpiRGb94F0ruBEALEtvRzNvt++yCpDBeko1IKyXq9gedIVldr5AoB416G8tAIxfwIawtVEGBUzOJ6jWq9y61795k6fhIl1da9AmsRQmKtRkiRTlUE8tFxb18HjDX89Gc/Z2G1zv5imesfVLh84xadMKIf9vBzWfxCjla3z435KrcryzxYq3H37l3m5ufIZDM4joN01EAHpEJEDcx5mIB27rP5LH/4zSv848IbfPXZH1MahhMHp3j3xiy379xnKJOlVm9irKHVDalUq7SbTY5PHSB34kle/v1vefbZL/DZT38O3/ORQmIwqfZIFcluHrDWopQiiiKq1SpnXz/Hiy/+Eiklq60ewSefZMJoPuVIKktVbi+usFpv0Gw00dbQ6/V44rFpTp75PLMPukRRj7Nn/8jNmzc488wznDhxglKpjOM4OMpBCrkNQtdxEFLy6quv8ruXX2b+XoVOt43nulirufTvf/Gtb3+boisZDd/Gn/aZPnKYjWaLxcVl5ucXsVHE3olphg99BFW7tKWw7t6d5c6dD/B9n6GhEQ4fPsxTT51hcnIaxxjD0tIS58+f56WXXmJpYRHHdVIAycE9Tkjuzd2j2WgytO8opfUV7P1ZVhstipkM61Jw6rFpxvcfYOTp56lUFul2u4NWG6Ce9OK6ulqlurLEhQtvMTo6hvPd73yHucoc7VYbIcH1XMCiTYLCGYBSsLb2gI16jXw+R/7kM+SOnsS/eZnanff5yMwRylMz6LEjaKGo1zfo9EI8zydOYrADkhMCazQCges61Os1/g9EmtGCKUERpAAAAABJRU5ErkJggg=="
WANTED_SIDE = "iVBORw0KGgoAAAANSUhEUgAAABEAAAAUCAYAAABroNZJAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gQXAyQXRPpB4QAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAADZUlEQVQ4yyWTWW5cVRQA6547vKm77bgd22mJICEBYaHsgN2wAX74AyKEQBHYGTwkbb9+3X3fHQ4f3kB9lKrMnz//qG3bc7l5xeE4c3p6yl9//IIxAkDJSikFVYMxFhFh8+p73t+84+pq4MPHf3DeN7T9guubT4gI1x8+smhbvG/w3mPFY4wFBIMg4pg54BaG3XGiEnB3D18QFxjHke/e/EDOmfc3v1PUggQqBlTJOVGyoqrYxUzooCZls/kGefPta4bWIGVivP8PMz9y3rQ8vb/h9t3fuHzEl5mHj/9y2D3w1WZN0ICZK04L+fiAuf/1J52mibu7O4ZhIKWEpD2+afC+QQ2osYTQYp3DGMuskVXfITVz/3CLhBDouo6rqyvOz89ZLpfkWun7Bf1ioCKA0LQt1gfGacc4jqgB1zSsTte4t2/fAuC9J4RASonTF2cc50gslb7vqWp4HHfUWnGh4bRv0WrZPu1x1uLOzs7w3iMipJRYLBZILYzxgGrGuoCxjjkmVAx9aJnjjqbpMK5BvMeJCCEERIRpmvDeU0tisVhRamV/jAQPL87XuNCQcyYeIKaMb1rEt4jqc0xd19E0Dc45MJZ+GOiGBapKQekXS7quIxVls9lgjGWcIl+2T7hSCtM0sVqtsNZSSsFaS0qFVDJqBFXDbrejIuz3e/ZOUFVWJydUQEJnuXi15vHxEaeBeVuY4gOfn97TLwxNyGjdYerEfvuRVQu5JIZOuL35DeI1Ms9Hcp5RCkYq1iltMyDGEo+ZNCuogDpqFaYpghqcC6zPLjg5WeOsE5RKzkfEKKUe2Vx+zW63x1oLGmhCy3K5RMyzWGMs0+7INCWm3S0OoNZK1YKaBGZmHA/EYyLnAzlXamcRiZRsmGNFNeGc42R1hqri5phom4pBcM7Stg1fPm+x1j8vII45ZtAD3gdELKoFeF4ANTjvBqx0GJMxRjDGEEJgGAZijHjfIOJAheVySYyRmJ6Ayna7RYzHDf0pTWiJhxmtSimVxBGlY04RYwzGFOZ5xjrDOI5gDpycrOm0YX12iUMdYsIz0YGzAWdABEpJKAEUUorEeGAcH/HNjN83PNw/4WyLM2bLON6TS8ItT2lsz+Fxwoln2a/xruXly5fc3n3g0+01FxcviGbAhsDl6zP288z/HKLIMeR5K9QAAAAASUVORK5CYII="
WANTED_BOTTOM = "iVBORw0KGgoAAAANSUhEUgAAAEAAAAACCAYAAADo+dq5AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gQXAyYqLqRvcgAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAABUklEQVQozwXBTZaUMBSA0S8/lQQKuqVroO3Eict0Wy7FqdPyHC0LJEAgIc971Y/v3+RiPTmNhNAS2gZRhlIqAvimJYTA/hwpnITeM8WJvu+JU8QpzzJFPn/9QowrxhhSOvAu0Pc90zRTSsE5h8hJXGag0HUdpcCnj+/kfPL8/UTMBiqjlEfpF7TyVJWoLEx/Fy6XC03TEEJARCilYIwhhMCybKS0sqWVnHesdbRNT3f9gPeBP79+0vU9zjnmJRKuLSklrEGo5eBfXAjtldfhhnOOcZp5PEe2fcQ3Lb09EQRtFAC1VqqciMqgDuZ5Y0+ZUjZKqdTGoPXOWRTHXhHJWGt5fXlDRBiGgfv9ToyJx+OBwjKPE9oc3N7eaX0gHcKZCxdvGIYbtVa0BqUBqVTZ2dPOmir5EHLOHEcBQCuDNQ5jDFprjDFYa+m6jjVteO+JMfIf57G9jZ1Q2q8AAAAASUVORK5CYII="

def main(config):
    photo = config.get("photo")

    #Use the uploaded photo if it exists, otherwise default to Steve
    if photo == None:
        print("Using Default")
        photo = base64.decode(DEFAULT_CRIMINAL)
    else:
        print("Using your photo")
        photo = base64.decode(config.get("photo"))

    sidewidth = 17
    picturewidth = 64 - 2 * sidewidth

    return render.Root(
        render.Column(
            children = [
                render.Image(src = base64.decode(WANTED_HEADER)),
                render.Row(
                    children = [
                        render.Image(src = base64.decode(WANTED_SIDE)),
                        render.Image(src = photo, width = picturewidth, height = 20),
                        render.Image(src = base64.decode(WANTED_SIDE)),
                    ],
                ),
                render.Row(
                    children = [
                        render.Image(src = base64.decode(WANTED_BOTTOM)),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.PhotoSelect(
                id = "photo",
                name = "Photo",
                desc = "Upload a photo you want displayed on the wanted poster.",
                icon = "user",
            ),
        ],
    )
