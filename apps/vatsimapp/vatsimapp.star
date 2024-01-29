load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

ONLINE_ICON = base64.decode("""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""")
OFFLINE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAHNUlEQVR4nOWbWYxmRRXHf/9TdXt1ZmBkCIk6Eg0gLsHIYkBUojGaEcISCBiDzOCGPhkTTXAJM7igJia+GBITAxiiRDEiZsKDJvomKEg0CIHghgthBhlmptfvu1V/H75uZ6F7mO7pnm+6+5fch+9WfXXPOVW3TtW5deRLLmFOLIjK7tEuXQcDLoQ6uGRqIwLhIoSwClaAC3KQCzhMRwmC0zDnIp0DnGnYDJwCbAAGgQ4wBewFdgP/EDwd1Y9VeNSRduWpSWgrHh2hYHAlUTGBA6IUUkk4gzHYdIpY1xTWje7v6TIPed6SRWGEKZHOr+FLjd4LnIcYXFgr0IYQTCE/XHL+ZVLdKfsR5tdlUSyRAQx4uCpvq9INlbgAGXnxLc7oOYR9cW3yxW7YoerfCu4w3CXcOYbm/08cy5+FAYaq0s2F9NdK+m4lLhDHpvxLnuPesLa40OJ7RPpLVfqcUXOsz1mUATQ71BU3dpOerqSvA6fN3l9+/Oqq9C1HPGXpw3jGSItgwQYQpjg2d8kPFMX3Ma/iuCh9OAZ8elXcXVL+WY04dTGjYYEGqDji2kp+olofOD69fWRk44grOk08UYNLFzpHHrUBhGk1eGs35XsEIyeC8rP0hr83thG/KEpfWIhsR+0FWqU7TGyl97BFiLm8CMBQQl+DtJnKTUfjMjN1nloOen4dCH5SratPpF6fD9kUpU/WrOFQ9waiBRLMM0nmTlPmagaoIFPRDwRXL/H6Y1kRJqSPTNF0PTX6MZfe3bnI4+ufnbsRV6bqxttqHb0+3C6ftMtEojJF/ujU1IZ/h8stZZ6XXbuvPGfOgtoduKoy+NOe5U78oT8fBgbQFUNFP59LC+2//NxDb1ApTpvG6uiuoLKSlYfePkhWHeqwCfPC4fui7ImBg6uDCpPN4H3SylceQAbjmBj0fdn1XYeX5xHtOfDLZixtuL5N6aJU55ocVya9Ttc7VdN1qeieg0eB9lz2poNrNlM+6UU7jYh6nMVcZgS29o6MtydHsWeNkMfLqQdV0hdD3RFRmM9trFgMyBs6w/H5pvqbsy+3nvvgO2ZLB6u0FxYWvFhxSOMDak+Ser49mrYy0FZkf8LS6lYewB7tltjamW6Y7gwQqoZiqvSZ1TDrvywSSJ/NmqRhgshDu/DwvvNLNK/TEYKHqwZDQWcP5uk3vyKPEbUMU+q6D/U2OmtgBMxs8Ca9/tr9+WSim6GNZstiQ0orEQW0VVvqrglyt27YDHEWq83vHwmDgrdFzq+M1Oq8tfDqH4Ld+6iycfjCIDi73/L0B0Prt0ZJOmspY/grBWFK1ZmB2bw2Zv85EK8JYFO/5egXgk0BrOu3IP3CsC6AgZetuXoZDFbdvndhBL3DCWuV6QD29VuKPrIvgP/2W4o+8nwIP7NWpwHDM5EpT1atPQMYkeWnoiX+tBI+ei4Htv8YqZYH11IsYBZhVNKDIWK3iUf7LdDxxujRKp6PyHtpNLbTpH7LdNwwoqGzs2GcaGKMRhP39CJla2MyNEGOqR81zSQxUTbT8cY/J3UfXxPbYkGifbxtRx+f7m4kKqb0Tvd9p9+yHQ96sW99u1oUCz235aLZslQj7QOP9FG+ZcY457FctIGZKHCO0syWFWe+UlO5bbWGyGrKjD6/f8fo2HR1zHw033vZGTPFxlJMeNMenNevus/jiNJoz9BzuzemqQ6eWf3mjkcP1KnUBDcV8cM+SblsWDA80X7cJ59CNx84H6pn33/oqRGpUBp+I/TuVfMqCIrqr5vp8p6oOsTb5xEOOwpTwR1dNdnEbuNY6fsEC0SU9dO6qipecjY2ss3h10CpLzTuXokqK3pxNCN6dMrlteMXmRZMHXrlyTzHZGeRa3u/NbC9q9gur8wDUzVl0sTYjrRvbOf0PP2YXbpz3DZdC9epHcqDpxNp63xnbU9UqqDpljvXlaHtGml6ByPmILd1eu4WBJRKRGyrkYfB1y6fuEuP8Y9TYdtQ24AHmS+HJ0tHSBkQPX9pXyd7oqa0bTZ/58RFgO8S3mppRvEy71R2dAkTBpkbo9u9FXve4dRPZtb4yHVHULYerfM66oyRmhLN2Pgtg+MT1zhi8kQ7UxB4PFOuCer2hXjuBeUM2RClvXeg+I256IF+G8FSb6Vi7cwuZ2fae71At72wpCmJGiIV/t502y1y3Qb614LaWCIcQqU8MzDVXh/WpZb/uVDlYZF5g9ZMOq59p6hnCH8Z2IWWN6TSa1uA/5MrNw9Mt2ek6e7dszu7xXBMmaMzU+uU8FdVeV0UfzrM7+GI+coLppeOGYT9O+xPhcvrcynfEOrUY1Aelix3WBjGo+X2nMvtXfF21XQZ4n2G81nEetq9P3UgHk5M/yrUvZ925JEanhmBS2PhJc0eP9DrfigXHiqhLznqa2WdY/EW4A3A6cCpwCiQ6EVmusC4YJfhb+AnU+UxS3+w/GxyB6lDYZSlfsn+B5RvNWKm7mfGAAAAAElFTkSuQmCC""")

def main():
    ICAO = "WIEE"
    NUM_OF_DEP = 0
    NUM_OF_ARR = 0

    DEL_ACTIVE = False
    GND_ACTIVE = False
    TWR_ACTIVE = False
    APP_ACTIVE = False

    suffixes = ["_DEL", "_GND", "_TWR", "_APP"]

    response = http.get("https://data.vatsim.net/v3/vatsim-data.json")
    data = response.json()

    for pilot in data["pilots"]:
        if "flight_plan" in pilot and pilot["flight_plan"]:
            if "departure" in pilot["flight_plan"] and pilot["flight_plan"]["departure"] == ICAO:
                NUM_OF_DEP += 1
            if "arrival" in pilot["flight_plan"] and pilot["flight_plan"]["arrival"] == ICAO:
                NUM_OF_ARR += 1

    for controller in data["controllers"]:
        if ICAO in controller["callsign"]:
            for suffix in suffixes:
                if suffix in controller["callsign"]:
                    if suffix == "_DEL":
                        DEL_ACTIVE = True
                    elif suffix == "_GND":
                        GND_ACTIVE = True
                    elif suffix == "_TWR":
                        TWR_ACTIVE = True
                    elif suffix == "_APP":
                        APP_ACTIVE = True

    return render.Root(
        delay = 500,
        child = render.Box(
            padding = 1,
            child =
                render.Animation(
                    children = [
                        render.Column(children = [
                            render.Text(font = "tom-thumb", content = ICAO),
                            render.Text(font = "tom-thumb", content = "DEP:%s|ARR:%s" % (NUM_OF_DEP, NUM_OF_ARR)),
                            render.Text(font = "tom-thumb", content = "--------------------------------"),
                            render.Row(children = [
                                render.Text(font = "tom-thumb", content = "DEL"),
                                render.Image(height = 5, width = 5, src = ONLINE_ICON) if DEL_ACTIVE else render.Image(height = 5, width = 5, src = OFFLINE_ICON),
                                render.Text(font = "tom-thumb", content = "   "),
                                render.Text(font = "tom-thumb", content = "GND"),
                                render.Image(height = 5, width = 5, src = ONLINE_ICON) if GND_ACTIVE else render.Image(height = 5, width = 5, src = OFFLINE_ICON),
                            ]),
                            render.Row(children = [
                                render.Text(font = "tom-thumb", content = "TWR"),
                                render.Image(height = 5, width = 5, src = ONLINE_ICON) if TWR_ACTIVE else render.Image(height = 5, width = 5, src = OFFLINE_ICON),
                                render.Text(font = "tom-thumb", content = "   "),
                                render.Text(font = "tom-thumb", content = "APP"),
                                render.Image(height = 5, width = 5, src = ONLINE_ICON) if APP_ACTIVE else render.Image(height = 5, width = 5, src = OFFLINE_ICON),
                            ]),
                        ]),
                    ],
                ),
        ),
    )
