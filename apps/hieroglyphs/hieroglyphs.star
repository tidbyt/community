"""
Applet: Hieroglyphs
Summary: Random Egyptian Hieroglyphs
Description: Displays Egyptian Hieroglyphs from Gardiner's Sign List plus details of pronunciation and use.
Author: dinosaursrarr
"""

load("encoding/base64.star", "base64")
load("hash.star", "hash")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FONT = "tom-thumb"

DESCRIPTION = "description"
PRONUNCIATION = "pronunciation"

# To match the Maya Glyphs app
GOLD = "#e79223"
TEAL = "#56a0a0"

def main():
    # Pick a new pseudorandom glyph every 15 seconds
    timestamp = time.now().unix // 15
    h = hash.md5(str(timestamp))
    index = int(h, 16) % len(GLYPHS)
    key = sorted(GLYPHS.keys())[index]

    key = "W25"

    glyph = GLYPHS[key]

    texts = [
        # Glyph ID from Gardiner's sign list
        render.Text(
            key,
            font = FONT,
            color = TEAL,
        ),
    ]

    if PRONUNCIATION in glyph:
        # How to pronounce, in Manuel de Codage convention
        # https://en.wikipedia.org/wiki/Manuel_de_Codage
        texts.append(
            render.Text(
                glyph[PRONUNCIATION],
                font = FONT,
            ),
        )

    if DESCRIPTION in glyph:
        used_height = 6
        for t in texts:
            used_height += t.size()[1]
        texts.append(
            render.Padding(
                pad = (0, 30 - used_height, 0, 0),
                child = render.Marquee(
                    scroll_direction = "horizontal",
                    width = 62,
                    child = render.Text(
                        glyph[DESCRIPTION],
                        font = FONT,
                        color = GOLD,
                    ),
                ),
            ),
        )

    return render.Root(
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Stack(
                children = [
                    render.Row(
                        main_align = "end",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Column(
                                main_align = "space_around",
                                cross_align = "center",
                                expanded = True,
                                children = [
                                    render.Image(base64.decode(glyph["src"])),
                                ],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "start",
                        expanded = True,
                        children = texts,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

# Many thanks to the WikiHiero project https://www.mediawiki.org/wiki/Extension:WikiHiero
# Sources are released under the GNU Public License and images under the GNU Free Documentation Licence.
GLYPHS = {
    "O6": {
        "description": "enclosure",
        "pronunciation": "Hwt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAAY0lEQVR4nGP8zwAHLAwnzkNYhhYM//Ohovn/mRg4oGwOBiaE8kHG/sHAwsDAwMDQosjIoAVlJ0r9YWCCqmFdwMZWDRVnYPjP8J+KbvjBwMDw/xfEDRHqDAy89tMYDBkYkcIWAO0bExNpp6JhAAAAAElFTkSuQmCC",
    },
    "T23": {
        "description": "arrowhead",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA90lEQVR4nAXBvU7CYBSA4benDVRtwoBGB2yqDA5OuOlGDO5ejIkxJrox6pUou07egmGgoWxERRyItnz9+Xp8Huglqpr08Cjse9L1CwTL6HKERShNFESmRLAWxFoEUJxaEYr1TqOdVwjZ6ijorlIEk/ruZmoQCuPhmQKhnrRb25MagR+olyDw8ev+LUDO+Uwl+6LvXV2/5a28f6vcqdVTLfWe6EmTw5k+H0Bv8dh8+D5BoNoQv1CEzm5skr19hCB71ZdsC8F1SkoEYd0MCf0cIZ4PGoN5jDAbh83OOAEYVsfVEASm9sxOQcDhxvFAoCbSEoRw4CIXIf8xN28pLy+r9wAAAABJRU5ErkJggg==",
    },
    "Aa22": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABdklEQVR4nKWRPUhCYRSG3+96r16xKJN+HKQflLYSsiHoZ8mCKCII2huDWpoKgqaGKCEiGoqC0FpcCmkoiChbHKIloikcRCstg3tRE+9pCL0q97b0buc83/tyzneACom0W1Fz+FP/w7y+sbMp/aSP7WfOxIp++LTzg63p49HU5HajfnjtRpi96buVOIwcD5Oty50phB8AAHkoJQwAPOyb7UajQ7lcfwdggtX1S4kNHUvEptpyp5mGE49G/L40yyKu+vvvbLdVipEBCuf6ivEgMAIHMxdhHeKANy9ErmQZDCQ+B5Y4EBiIAUwGAI6V5jfQTkU+D0ABFUuh6kZVexfUl1rYg9YavX8C+l+l/JEuH3yJz/goUKdN3Y/xYYhb5LNo0WCaKPmZkokS3mKv7KAt5hAgCSLZ+swa7rsoICyPA700oeEGg9U/lps7ENVWOS5Y/COrPXvZqObgt8mgvADHuXKohpfpmrLzDHCESBPfKIsGAGi+UPEP/rF55IF0Wr8AAAAASUVORK5CYII=",
    },
    "W10": {
        "description": "cup",
        "pronunciation": "iab",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAOCAAAAADlbQgSAAAAk0lEQVR4nG3PsQnCQBjF8X8Ox7AQg3Y6gCQgThCyzaWzOSErZIaEYJUmleAAukIyx7MwUe/wVY8ffPC9SPzJYlg2oeUDlcoAS1WmJw40pjcj+0B3jOBkPbRyGB6sPV3xBOj859QBkKn9wUYZAKmUfjCRDmDgVpB8lfP93bZSPWEtbYAIwDqm2TnFZT47tZpzPQK8ALo0NNDWBKU9AAAAAElFTkSuQmCC",
    },
    "S18": {
        "description": "menatnecklaceandcounterpoise",
        "pronunciation": "mnit",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAeCAAAAAATRYE5AAACTUlEQVR4nFWRTUjTcRyHn/32t2a+sGGmNpdvTVM0B0aolywSMszskPaCEB2SOhh0CMVetALLMPIQkYpZRGFNMouBt9BpmHooMcKpKOHUtGy6mrq5X4fNwuf04fNcvl8+sE5k0Dlp3iEnLmvZQMaX+qz2OOVu+1xDzAZR/r3SF86udAb/r2Or8/b4o7pUNoT+E0XSukkJoM2WB6LFUwzCJ3otDwLsnxI8BCWGeFsXK3b6aqXwwGZ0HY3psE9egNOyUgNAiHSfou5eGpAjrVXXWrxLCQBs6pLlrMxnADnSRzIAQp+iDTAZAHJkU7LReEsmC4DrI2W/3loLABwLB5022yJSABRuCUQJKgRYXQrVgBqVABKjADAYgKl+nQaEa0VA0kMBqDzh9dHgGEQAa2sCTcXeQiQsFeeXCaQTQOXxCtWZo7nDM89p+N1z7PwRcCFBPeAg9UcpTwaBb3e4YY8i37Ufcb9a8LQvctfPJsAyHhc7UkPC59uEdZ8A90ual2MAk/smH6YIMA9ichQhlEn0YhIYUyIYV3C7wlCCJWJ5BlTrs9hXYVEfEyE9iD9j2DECRu8sox54vfDxhToaodlG7XSDgaSW4WZ0aiILdBOd8yWHcdZDtmXoje2VCcyj5Lnex4dk9nYx2AZoj7ceCgb6OrjUHw+UzJM2nQv+7U/ORnDlMcDuGYKeWU3+m7KG6xQujmRC4KMFiO+erSnSh8eW1DrebYXEr7bs6KvSAmyvk86+ngG3t0oLkGadGpqrTAFQjGYpZWO8/8+w1HQj/AUn091psuOXcgAAAABJRU5ErkJggg==",
    },
    "B5": {
        "description": "woman suckling child",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAACOUlEQVR4nGWRXUhTARzFz73euemaI2FaJjdrWx8WK1quUSIp9KGhDyaUYEoUgyTwQTMysDChL8KkxGwEFmErYiaUkSUZQhsT/Fg1HFnZ1GzMbdLUqbvbvwcXKP0efxzOwzlAlHQnEb3SYQVxd8j26P7YB+UKe2yR7Bdjd3lb45dJyciweWzhDI6E9gMAG42KLLoSR46o35MKANySXRRb2oaZuRj3u3XLss9nayuS1GAi30TLe8v6Ipl/irnKmdvcP6coezvqD+hdWXzQR838Um964zbjEx/jFwnbnecLyhUnAwDQRT6jClDapFe7EXt6vgIA6ujNcXt/IjZ142YPsOGrWw2onD0mlZ7MSB0/0XsP+74QXQIuzO0lh22isy3jsouuSG2RAQog8f1DcY3L+7vO+X0Pr0nOnR3MdhM0lCeyCvq8ARNdA1BJ1XhA7JbpH5wuJmNQUtTqLpRDDxMcYa7cXyhmkNkRrjcPRXp9h3G0YTKEiOAJTz7r2+nL5fRNPwMCzQ97iLsueXnQ8LQ0PiFWsFrPxhmzWxZ4JQAkR4qaNR+7DKsBNL5gokuypFWHqlY1ddbLMaWURSdjzDO2uymbTxEVoPJTwtIXXJZYmrEjf3YjwENgWQAs0lra3dXuc6UVHcBWhNaLAHDyhsRcC73+DKQlBVNku6VrPABXrM23G1OCEC9o14IdCc/fMoyCrX08xATHvd5fSfz0FCccqMmxV7Gc4lAc/AAEHmEBknK5ILuRjpIJ+p+/4MX7ccYWvEUAAAAASUVORK5CYII=",
    },
    "W2": {
        "description": "oil-jar without ties",
        "pronunciation": "bAs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABVElEQVR4nFXO3ytDYRzH8ffznMcYsqXYSM2UKKz8qGnckZLc+wf8L9xy4Yq/QLngxoVaSK0RNpd+RZs6W2fLGjnM4+I5Trzvvq+bzxdMq1qv8q+V172915W/slzahd3SMgDi6dsVgZ6mqk13+PPF1QGpnqODX7mnhjXFecNqTaj7AsRP7AkgkwHG7dM4kof1rnlACGCua+0BAW0F9SEJU+W7udFbR8H72eKNQwOLzuThuxnd0JPml0m9KUCCPiBoKMi+BgnUmTE0Sx1DipQFYM2gPHLsUQWgRmzHo5ozIABEvFLzqJilHaCFTNEj95YFgCXuXI+QDAEMo/il/FcKYPoz59PxYwgg9Jj2qVQxi9WyT/+TALGIOSIxn8aiRYCXaMKnPi4BrkSfT72BC4BsU49Plk4DHGn5S+FkvgbwdpMMAQqIJctbGhAdA/3X5o9t7bcj4QfNe3SlW6ATjgAAAABJRU5ErkJggg==",
    },
    "Q4": {
        "description": "headrest",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAUCAAAAABQArkmAAAA8ElEQVR4nHWQsUrEQBRFTwSLVBmwnWr3A6bId4hlYCz9AP8ibQjYChK7VDb6BwNpLSwtBqxTDcTmgsVmJdndnOo9zn2PmZcB/hWAic9vgL0jB3h6ZOZOCt2uCTqQYjdILQvqUY3FOuecA1qpKZYeU0c9zLULChVneEUL0Cj6cwvYUSVEXbZArY5Sw5bGKvG8Hr9aNj9Tbq/52vR8cHOycu1/Aaptv4d37teXWWAkS1S/od2berDj5QO4alRfADaqtae29EmtOUajFLz5l8YnpX63iPsgKfjisDgpLtLHmSAln5mXW2C6+OCcIdPGZ2b+AHTQaA7HiIGrAAAAAElFTkSuQmCC",
    },
    "Y7": {
        "description": "harp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABY0lEQVR4nE2QTSjDcRjHv7/fVqYWaltT3hIpJ44rbYQSzeLiwM1hFyEODopojcnBW0pJXAiFy4oaSjhIbS0kb3lZshzGZvzN7P84/Nb8v6fn06eeb88D6OevLLQ1fl1bygDAfvBNIvFhPcAIxx4NMRDIhNFd1tcTPucMxFURd4OlG8ibf6yRt2buVy4CTscLRyAYPvt8efzoLrc2P0c4wJkaXMUo7l9PS3AoksWgZKNJJiVnF/8qPDFbyKf+54TO7glr/5nV5wY7oikmg8t7Y/WlOOEyjOnyl9WCZKmsfGp/8/BIeDnTyJ56KsyLb8LHKi1fvaq625NkP+XkzmwUtO1cJpljbxq2DC8BgNM7QKdF0EhuIR0PP1IjYI22i65Bon4A23cawRO0xAFzaFasaglHSwCsxvIBAENEXQCqXieFfvej2gI0GOaShxSORKShzodNbepy0xrFqEnxOG0rLaSL8Q+YR4r7JMky4wAAAABJRU5ErkJggg==",
    },
    "R16": {
        "description": "sceptre with feathers and string",
        "pronunciation": "wx",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA3ElEQVR4nKXGsUoCcQDH8e//791FSReYk4FYCIXQ0gu0BGFu9woSvUSQo8PR4nPk0JoRUVQQBOWoSKZDmRaSRODpryHfoM/0AQg+RsUEwO7tq9rhMnj3J6H6yluM99J7PmbOkvYHru0xtWTitZjbwli2/U9FUxbZe9RZ/aemc770J3ImvFVstLo/YOdiFEBBZciP69mVu6sUzB99d5qquMDaUFJnEwpPkqQSuRtJ0qTlZNd5WNgYN69JBgdbp93DRs7pV/GXTJhIASQv3z0cCwCGaDbg/zOzGTv04BeKcVxkWI0yWgAAAABJRU5ErkJggg==",
    },
    "S43": {
        "description": "walking stick",
        "pronunciation": "md",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAeCAAAAADBFYthAAAAg0lEQVR4nFXKMQqDQBhE4bfDspGUOYalnsHKHMPeJuBdcpMcwTsYIY2NEEihBJT9UygBm694M5TzZy7lu1vnhXs4BCcQ8NcAUwCC0khM97KtRftsC4U1ruHQdyMRaWCQ/MTklRmWHT+bCwsiv+Y4+87nBKsvtWlM3slI1d/7Cte8GvcDfNItZuey8awAAAAASUVORK5CYII=",
    },
    "O16": {
        "description": "gateway with serpents",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAaCAAAAAD+7nGkAAABMklEQVR4nN3RsUuUARjH8c/73lmmyUUSEbQ13CKFEEJb0JjgHhitt/kH9AfUFDQE0VA0uMk76NSgWDc4ujgILQ5OQp5RUnrXr+GGmu7e1p7pgefL9/fwPFS5yeRcqouzqa7D5epgTjtVS6OdtFBRJfdNbyYcbj+7gKX80txIuFMlt91NeJDElSQvfUuesJh80ElCkrQfJsel8NU5bujzmHv89Aozb7Gyv8FHrOdEKwmfky22k6uSHOsleSTJWsmOOOky5T0/oPflEp4Ku6vwqWTSGSvMG/ACjjTwWskeHL0r6brWscC6klvwxjL6nXOe63A6KAL6jYLTKX/X9+k/fXE2oUYVUYyFoqzjojmkRwbyTzYj9hsm1bT9B1hz3HGH87q2Qp1nNWkMxgeXDPRGET34Df/fgy0IS0VbAAAAAElFTkSuQmCC",
    },
    "M17": {
        "description": "reed",
        "pronunciation": "i",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAAwUlEQVR4nC3PrUqDYRgA0LPHCcOyOQVlIqI4ZUXQLiyY7EaNXoBNcCAYrQtehkGj2bpimFPR4MpgTPxjwrfXsKWTD647mwTZ+lVVQP0wgpzW0WooLz0fz++H6vJ9/303LMy+dTu1sFK4+32qhYJHaSpmdr4yRHHj4RtRXHv5Q1RKt0PEXr8NsdXtQ2y3XiEqvRGEnLHZxMVpiN7BKUTzo3EmyTdHJxefeZQbgzRMmDvvpQSly58ESjcpYNAef8RE/gGQNTovaEVG0gAAAABJRU5ErkJggg==",
    },
    "U18": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAdCAAAAADj60EcAAAAr0lEQVR4nK2Ryw3DIBBEH5bPKSUlRNpu3EMK2cgNpazJAX/AmM8hI3FBj2FmFwBJbnTl8hHyJX/bAOkC6JJP2fGgRboAyXukDGKRJumCVVu8BimLp0O69sJt8rC7IVWkO3WSll7ndglpX6+ku5BLPV1KFmXXwq5Uze6i+3QAYeCTAFOfinm2EVZzxBWoye2bmiHk08u0bOGDmNSoERABZpD4VN30OCoMZBts+t/x/gCQWLHI8ujOOgAAAABJRU5ErkJggg==",
    },
    "R2": {
        "description": "table with slices of bread",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABrUlEQVR4nH3QvU9TURzG8e859N7SFNAGKm1JBCSkiZAGxBcg6qjGBCd1MnExsjoyMzM48C8w6MwAphJCHDAxMeEGRROqNbFUIOGlpYWWe38OQGkhhyc5w/l9zsk5eeD2r9UQBD98bIaxdacBetamfDC7HgPg4f4kMJgfAR4UXgEv3etwf/s1aJidu2vD0vxNIBnoAzK557BQfws0kG64CoWtS4CND8jtdQFO0xHfsSxo7SoBIMBSWoFKuEfcgkC43aU2+nilRIF4qgIi1UdWtjOA/lnhoF8g4jtmdncAnQYO8YD+a2UIndzuASjKAdDJFQVWQEGYQ1ALnjdU+ArBxMoWROK55QMi8Y1vhBKbP7QSkot+G6RkafBK2ga3rG28/MBjGF0TYzKjinu9lR8Pv3j778az8ezJ3vlUU0TbF+dN6j3GTEhWnp5t7jTOxthm2syemzot9DwLdRexT2HVmbm7qXw5auaWelc1XvC2gDKyP7qaK3YrE7fH3/2eGQyauK3zc97pazRxq/2XTDhg5Owflouxqkn1P8Jzsem96KPkk5riKunYERGR71Wj/7jdqYUY+ZqCAAAAAElFTkSuQmCC",
    },
    "R20": {
        "description": "flower with horns",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAABTklEQVR4nNXQzSvDARzH8fd+Zow1hdk87iCtaeVhUiZkN07TSlKKQi4uDg5IOyhPBwcRNymShxPFSVGeLsoOuKlZJMU0DzO/9nWgWP4Cn+Prc3sDAIZjEZklbl2vInKp+00FFyIi0XX3D7m3VXkLqCKBQRugARo3kmFafTZ1arny+AEyt0SCY4x76DsV8ecB2YsiO07yT6Z1WOZFRvUKlvpY99GAKb+yLYXS9DlcqeBVJ3Ge325GHkpWw705N/5ilLmAGSpCch9RZd2gTMiw1lK4cNdQ5E5iJupLeE99nmmq0pbZprK6PUDui4ZW++HBnp3mZasup776TN5jslLn7ahx7LPbDqAPiogcGAFGFOM1wJBlKaKeunoAtqnQA9bDfufHY/nanhVI+opgdlArT2lGX0tcwToJZ6AkAmjjjlgMQOHv/pFp/pjyGvoOwicu0X63ncf9ngAAAABJRU5ErkJggg==",
    },
    "V27": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAHCAAAAABBpmDhAAAAc0lEQVR4nI2PsQmDUAAFL0QImBnc4ENmsA8EnMItJAul+fYZQQQ30F6bCFcIVqlMYq58HI/3UNWSL5TqqIRe1Sb7JGWNqn04QLje5xRYNtYRmNOqHqYEuvPl9g63nB7PDhIIefGjzaJ9DdOf24hx3H0a4wogK0V4moShzgAAAABJRU5ErkJggg==",
    },
    "Z94": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAKklEQVR4nGP8zwAFLNMZqAoY2+EsuB2MAlQxGW4KwmSWDmqYjGTHNEw7AN05Bmnn4mDVAAAAAElFTkSuQmCC",
    },
    "B8": {
        "description": "woman holding lotus flower",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAAB4ElEQVR4nE2QTUiTARzGf++7d3NtbR3ccNliRXP0MVhERokGFQnBSMFOEX1JCRqJxq5FENXNTPBSKCuK6BsPeSiiVl2qg8ZmYVgks7nBTJvTttr+Hd61fI6///P8eXigrG1hkakuI0vU8j19tTdSPLEEbUhIus/tfD5eU0ZKf/FlXD7vcP1oQi0x/97hLb2XvLXJHDqrbkC1Tx283Y/BYNKZpe1OuCJ0qNnqe/vQUsqZB0SiO1vzR56epXJG/2f3pa+tvvAoYrEWEPSs4rB77A3HjZHlCgAacLhqbHI3oXDMWGarjo2enCgccN9CABQ0Vg5Kxzi4l+Ugzzyg2c5tPBoDnjTVvjPsSm42Alun7+mNbp7hoyxKoh61y9Cjs6LK5fvGZOcbNG92plRdCL+vG7kL6rTZ+n8wk6ICal9Fa8mm/LuosQ/1+oqGDPwSADXRNj/gAWp8jv3BfTbRrd25U7Bu6Hfy59yiDAEKrLi+KVrw+/PP5rBtn9wzC8CalMiL8+0Apxc6QYNAS3F08PE3AGbVKoDgRLHHA40XG4HubAcorgd1jH0xmddXpj8tWAMEX6HZXPEbThV5HXe6lLV2aR7JaCKFr6liSjSXPUMWpb06pHiHvXkTeRGi8CcbcHDlL6ZRrLCTSJVdAAAAAElFTkSuQmCC",
    },
    "E18": {
        "description": "wolf on standard",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAABxklEQVR4nH2Tz2sTQRiGn9ndmk0D0RXBlEBRgiI1pKkVRU/+gB76D0hv3nIo4k1BKIhgvdki0pugePFQRKkiSC/RgyIoKEKRYmilRS2orak1Ncm+HlK7mzXpexhmeOb95ptvvgGAwu+TtJYFYGJuvA0HIFVSYSv/4F6cdt507OjwF6noteHfq1Vfkg62if+x4hiAC3ZLbjL9eQ0cBobutUuBzMi6NH82CaTy2WxvIuRvjNcuwtpSGbN9mzBrd8eWmyP0zqpJ80fc5g33FdF4EmCzLgvw45lvAdW+DMD56Udh/5hWhr0dnud5ydNzkqT3uxvEiTnAuBY2K5S+I0m6DIB9tfLmGFzXYl9QtElfUvkEQMcNqQgTKu0JTstLkqZdsPy3q6v7Ic2vuYC/mwI4dAqs+vNPjk+uhyehbP2bAN5QAgur7sKZzPpE+DofVqj7ZLuAzgf6eqWm5USg+K5zNd16Jf9hxsClERcoT3YajP8HMJWe4/Ai3Q0vDewcLHT4xooJavFomxiAblsbeR243VWfKT5urPaNJl5HtucWNZv693SJqae5CO//rFKwsu0WfW2CaX2j/7dQhBsT9v/Pfy7xrekr/gV+vLhxymp+BgAAAABJRU5ErkJggg==",
    },
    "S20": {
        "description": "necklace with seal",
        "pronunciation": "xtm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA0AAAAZCAAAAADPx/stAAABAUlEQVR4nE3OsSuEcRzH8ffz87sH4VIG9MSlCJ3LcKUMNoOB/wCjQW6wymYzUKRuP3IZlcioyCCD1KWYHg6DRbqn7rnzMTz34D19X3371hdg+EGSzgYdAFYkSSoMYSG387jXRnV8vnsGJlUdAGBbc3hbWifq5JTsbdAAy3cGdzNWmDEkKrG+MdTr/GaoL8azrZmvcl8s9xJnQU0RurQPvdqNlFMaONQEAPcX1sABPQDTab8GkH8BxnTVEl283+D6mgK7WtXrW/YZz0+NtDviX5anQmfjabuE8n+rsmV2LRmY5rBi3dYO5ziVDEZ17fVTSpQwwPkGGR2BAaAYfnyqCPwA+wRaUeJfhy0AAAAASUVORK5CYII=",
    },
    "T18": {
        "description": "crook with package attached",
        "pronunciation": "Sms",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAA7klEQVR4nCXBvyuEcQDH8ff363sXoQx0nQz8AzfoFGK1qVuuLDfI8qSu0FMG5QZlvFjEf2Dxa74YTMJokiIDg7seXbnre4/n+Ri8XpC/lw6KBpg/7ugiB9C30kjWMQCFrxY/Rw4GzsSz9gwEYuZFVQgEC81OmUBA5bc7WxXAWvf1VABsxJKjspwMGoBDKW5H3tKD/Yla1mH81e5kmkL9myWvxJEOP7R8xlpki49T2zhM73pntD+BekTJK3Yw0oiFc0Qf0zbLv7KXABbf23cC5t60uikYf1KNLZG/1UmGUJzrcghCoZsxIJQrfDYB8Qe4amlHBeeVyQAAAABJRU5ErkJggg==",
    },
    "M37": {
        "description": "bundle of flax",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAATCAAAAABAGfnZAAAAfklEQVR4nNWRsQ0CQQwER1cF6bfieujgr4Qv4VzGhXTwnxJCSuYSlsC80MNRALOBLa1WltYouSn0BqBAxTd3FirVN6eSSNhq4iVbjczQo6GDWjQAZo3ogEmhq6R9hjR3RR76kIyuy9ABpMKYM78c/tN5FDgWcM8XcPrKTPvyBIH8g9ajGMmCAAAAAElFTkSuQmCC",
    },
    "V19": {
        "pronunciation": "mDt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAXCAAAAADFQYt8AAAAYElEQVR4nNWOsQ2AMAwEj1SMk22cKTMPSpWSMhs8BUYKIRIVBSdZfv9bluEkZklSjtxwewxiUzXAqlofZBUDwIpy50vJVZIACD5vQ7/2RxmY8+6vXs6uKYueN77555/+AQjEQidTKwKSAAAAAElFTkSuQmCC",
    },
    "A5": {
        "description": "crouching man hiding behind wall",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAAB+0lEQVR4nE3RT0jTARjG8e/vt7k5CiwSbJagkWGL0CCzQ52KDoUdVOogQVpGkoeyKENIgjpo4KHaoSIJim5BmoH9AxMpmaSlGElCMpyx2pquqfhT93TY2nyOH14e3pfXWHo3KABlnbr1YMkgtgBgLJx77o4Dcnu3j80Y5mhjDDDmLuTUW4Aycg2A2cLfgB2bp6cTMOLWeiuaYYYjAHbQh04As/Gk+fQGidgBB0Bmb9lIuCmzZQUAE2FzAeVlGJUt1Z7EtGkaMbv3rHPjNdh5/FH25mSLvv44/z1+ujTad/BNsCewP8njUmhOU7s+TzcPSfEzSS6YkJZ/qq7Bv6Jv46H3hclV2vQ6eOltZENeYHIT+4LDLgBzOUQ0q2oos3ltZk+A/iueWgDWdUmKB2Lyyd8KjrZpD0DOR1UdjiiRdnD/aQcw6sd3UOxbkqxnA+FKB0F/MalcDSl0gFZdP7KoJ860V4TV530oK955O1ydZpqkqV+SdnN/elVNhTS47diA1UjB2GRKbR1S/EUeudlQs5hiR7ckTTSUAM7RNHdKUmwuWGvAcIqd/bo3oq49HdbLy14rxWsi84fK9QrX3u5Z62a6ZMFfmhEdKwSbO99YtV+XiW/+RPrzkH90Sx25F11FrpLH6Uu2ftH/3EmICTBj8ddXU3T3U2SmN8H/AFrq8aBlzPK0AAAAAElFTkSuQmCC",
    },
    "W16": {
        "description": "water jar with rack",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAAB5ElEQVR4nD3NO2hTYRiH8SdfrlVMKjTxENRCEkOT4A1clSIqxctScGoJxtIgrg7a6lgQBzfd3HRQNGtECBZBUysRGmrE6lDtqYUmoSUn13NOej6HJL7jj//LA+J8ri0H9xLnmbvvHZx4fKpYMOA6r2Fp//yN4C/sD838OYBCAWBB/rx9kqN/i0cAWFkB23z7vgLMNm8BeG622ylvujVnA+h+DABcMVdXjblvH3wA/FgcATzZL4nEUlW7AwD3OheBgDUDM/J3HACR0ZJOEF0NNPPZ9x5WCoftIMoqqJV3vW/RKAvAZrSgpat9dPkBusoYjCmyj9cuLxqg63GI63ofL/DJgk5xGIaLnT5W5TFALwWdzmBpsHxeveoEmkN2+1CT//VoCORGyOsNbQxC21/Dx4FK1OeLVvpLh2VSB1SHG4c6wNGz6mfco/6dGDv+6J9e6rR84yK9Va7V67XyVrq3nJBvTV/y0faDF0wvHEq+qgE8lROMa0qonEiUQ4o2DiB07ITVWqxRrTZiNTUMIDxIIpl2LFupZGPtTEQAwsbevsl1pjYta3OK9cmDgNhDjihr/nAJSmH/mhIAhADPcj5VykGulMovuwAHoLtn051pB90D6V23CfBEXgoaurR0w9AtqRsR4B+ygtJzDAb1ogAAAABJRU5ErkJggg==",
    },
    "G7": {
        "description": "falcon on standard",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABa0lEQVR4nGNgYGBgYKr7//9NEgMqYAx9seL+wT3mCBEmBgYGBhmhN3mXnBe4oirmyv84+2fdvceOqMJKt97ct9F6fMcBRZT99GUfHgbrG48UUITPnWRgYGDQeDRBFll02hUuBgYGBocXGciiLN9WsjEwMDC0/YhBEmUq+bskipmBQWzPh0gkYeX3/7/uy+RnEDjxRgshKnP665FZDx9lyupfm6+IcNui3csZIr/+fz9z1cdYBhao6K+nhvIWir+4HhiY/K66DVdc+u/fwzfVa576Jn/9/xAuWvTjyvtN0nw793G4P/8PF13wtH8HgyCzyes+hpLvjFGccxlMU7m4XDg+MJ7kO1kaPXE/rxrDr+3mp9/8////3+t3/////3vrcv/+g06My9yFbuz+z2inW7Lw0tbvjMz/Jt1hYGBgSNthxMDAYH7q54wVyAEjzMDAwMBgfv3/agZMYPBlLSKw4KwL3xmxiCID+ooCAN9/ih7iTsncAAAAAElFTkSuQmCC",
    },
    "A23": {
        "description": "king with staff and mace with round head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAAB8UlEQVR4nEXQTUjTYQDH8e//8dl06iJbRr5McUIsCY0oSu1FIoiBFEIHDUKE0EPlqUiHiYfo5VjgIYQxpAxBKeh10aFIMEQozSQlV5tvq226ZnObzj0dxPU7fviefhpbKztVb4g4B5dTIOp9aqBrRL04/J9aQz8n1eytPw5dykoWPEc7nKZA5KDYosXgHe9QeqfX15yqjsTdrorRaHWjHc7sAaDb3reqa924ZtQwf7EDkFMxVYd8lnBkCl2WBGDZvv6RxHDaOatEKQB21inzIoUxo0GABsCliKeK9IqvKAFJgJzzj3qum9v296JkUgmgtK343c3dQ3nhCYTI2hYraOx+evHem+/qxgA7gFH1yx2NDZ7Vm4a7KfjU4Dkuu/rk86BjFsoLmvBHK5dA9rdDebWRl/1QNvPBbZOJFZ+x07agm7PN9iYPWEq02xK9YSVRpM+oGZ/IZL4ktObjcmDsBIV52z83AbbQ1SKTbDOZWt7PcSz/dLkm9xqiXqgNzRQDJ13jSr19rNoBq/81gC5737TPUBvrAalPC4okrK+vZj6MzoctIOKxb0kAcnc9YSqggYiHN8+hcWSS+JIGIvBjM8pueLDMRiIDxFrED5DbMecCi+UvyDWvH0pbDtU4f1ubq8zTAFcq4a5Sr/K5ryZHLsA/OjPElZJigTEAAAAASUVORK5CYII=",
    },
    "S44": {
        "description": "walking stick with flagellum",
        "pronunciation": "Ams",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAeCAAAAAA9AKCrAAAAzElEQVR4nM3OL2tCcRjF8e997hUUlmYwWQwiIoyNVbEMbIJ/QNCgSTAZltYWljaMCoJBMGnSF2AxGUyOgcEiiElBmGJQeQze33vwpPMJBw5HVf3AzZfqMmoQXmvDdOxvDQAeG5DLnh14OmlAEASqhSQAn+qj+K+bFxDgmG0vhv6yhQD51rY0XWVeEZTmoTR7+Hl8RgCpjbDm/bhPgPcBnLO9RMDBogucKqHgkwAOYE/eSIn7Sn73mnNceKnHIgZj5y8UNBjCHLO5De8LVwxLNOqWoaspAAAAAElFTkSuQmCC",
    },
    "G11": {
        "description": "image of falcon",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAASCAAAAAAbVlOzAAAA8UlEQVR4nIXOP0tCURzG8eckYm7VIIHk4ia5uGQFRUtjOChOvoRW6T0EvQc1cHMJ+rdIS2UEEoFFrk7XKRTuXerb4L8L99z8Led5Dp/z40iSFM3e87mXNgqfzdYYrpv/kGgHwKMbTgrAKKlbnkJJHTiQ1Ke9HkJqwJUkPUDFTi5+4EWS1IGy3USADUmK3UDv0GqeITaNLajaSA53npvwdRQk21CcZZN0YSdozhguSsqBuwAxXdqLtnryBvVZW5ueJWj4nsRP4fvxWJLM+5YkGS8hKfPhX7x7vs/g0jMG36XzGp/nX9fJZyZ/8BP7rCwV+gNpFmb15h5YpgAAAABJRU5ErkJggg==",
    },
    "A49": {
        "description": "seated syrian holding stick",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAABs0lEQVR4nE3RT0iUcRDG8e+Ou+2buVttEdnqGpIXlUQJzKJMkCTBi0rqRU2yS1bWpQ2CoK5BEdSlDKLo0CGEIks6aVBpKQSKsLuCruRKIuby7h9feX8dXvd9m+OHZ2ZgBuyqG1bZpwcBl03lo5OzvvZvXVnEtjvB2Gbh0PH+/3LueZVebOw/UdmQsnNX9ZuRtiv5L0uO4c5ZcXQkmlwtn8PnzHsVqP2BccabH0L8d2sA+BsaeN21oO3x7EJuX9oHwNmiJv/9vlC9aGAMWr1Vk+d3x5RKqYdg9OaWyHO99dRP9dglmcPbFm+98OTt+AcySoYaApZpnclHsM4fOKqftKww9cIL4UQ9Evl0zrKSnWNZ8Mx8RdLxcDUAF7O/gRV3ARBWi0GApekiwD/fiLBFcADAG1sC8nZ4EdbM9OV7Gpg6AEohBBLVN7o/HqkzR+xToiUWnk1cG02uDjuv6Vj2AQ9UDwB7481AYKoTkBa/bcJapM8D5rsNq800EXhTUelM2lzZj8D76RbHDL1GAGqjFQ5e/3VIAMOTcex7WdANcODWl61tUqV5p11A6HNZyszlXNrcP4O1j1/SGsHbAAAAAElFTkSuQmCC",
    },
    "Aa25": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABYUlEQVR4nG3QP0gCcRQH8O897o4uScg8NNSsSGgwmqSxtmiLQKgpELccHJrciwYripYIiozmpmiQcApqrWxIFPMfmWYNFoF392vIpH7nd3m/9xnej/eAn8SZ9qmxeLsT2xWve7nRCDiVqgdlV1Bqd9SuRdkCi1zk1GAMjBmclhQJklLiNOv0wuvMctqoW2GtNzjVWwBaOqf/86tEBgyiv2rz7dypEiT1dnvMBkASIPhmwyMP166n1bjnJTCe3798BImRo0AitHijatAcV0vhk6njFVGMxbZSwQW4+rK96sRGGfen05t2oWbPPxcS+cpuT+jwK+IeXna7PVUxd3aRegcUgQTCRzp93j8zN4khAAIRrScHkmsCiAB4xAIAxoCGLMhvDAYAFDu7kcEM4ncDU0SFmVT3D/p1k6aqA9WUScs1qpVNCjjMlwSjeeryW9PR1GFKVIuaJyDTyHTRSqnSeX8D2nl4x4DZ8GAAAAAASUVORK5CYII=",
    },
    "E10": {
        "description": "ram",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAbCAAAAAA1sqIBAAAB7klEQVR4nH2TPWhTcRTFf+8lNWigSio1i9jFFhQULG6iARG1HRSxSxFqRYuDHRQURUSlSCkSnXRxUexW0EGbySR+lAZEbayDEXVqBgtNNDHERpMch5eP956NZ7rnvB/3f++FZwjIj855AKC8/6YBwKOjwiYvQPtYdlUptyxMs8eivr93UBjnK+DxtxUK434gFV7jBcO8VWFlDVQlSXtbfLbU8UM1nfoPFcyrpKLFnW5JefN6DMRKryeeSktdLbBOKXW8i7mLQERaHPSvdhEGgP9tDwBfNwsiBwH1F+oXafv4rUHnpVJa2sfW/F2O/C6UZdOU37SuSdEXG01N9/V+ydEfAeDsoSIA5eBOsttr3QIAM4qP6fY/k09Id0yrzAJcITRiVTWF+gAKEPTa0nimoxPDFrycDUyCCetNe/sy4LP56smHSRDsckxxQ5JeBBs+fO+P3nBGkv1RKgC7F9I+E6oyjQ1Ab/Sne6cTcmqyUTm5GSuc9rQHzl3ftJb4yljUCgfq/lkdc2xKhdwsvJpqrAqJPSH3bHzSE94pavNJYNDV7XI3z1lqXvhSNxkgDe7zzgO/6n4I7tu9pS0JxWBeOlwLlqUdsDGhRRt1TdIBxpu/V1I6BoSlB01q3Qdlhg2u6vMFAMyhYmbYAEa0sO0vHO8Sz+SJ1p4AAAAASUVORK5CYII=",
    },
    "R9": {
        "description": "combination of cloth on pole and bag",
        "pronunciation": "bd",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAeCAAAAAA9AKCrAAAA/0lEQVR4nK3QQStEYRTG8f+97zto7oLmKrpTNJNkKTGS1ezFN7CwlPARbCSZlbIhiZo9TbFjMTEpmSwkTYpsJ2x0a+7c91i47+QDOLtfp85zehwAVHo8NdpX0mQDZvJ+MeUet/XCmh8F6qRkFmP04fvqRxQ3YEqh/dfP5lcIaNCnsw/cHYXm0gG9NJnLqrEVp5ork8x08Uy20L+4ZQ5w7a7rL/gveIMAGFzwNm6WM8BwN1CIRa76N6UWAOmKiFxcS3UAYOJFRERqQwBk9psi7Wg9OZp/lp3HAxuxLd5u3Ya2yt/1Xgv9RKPHwhSIO7+F8yMtlXSAYu9Ndeq5F3P+A+xyU8x2XtyLAAAAAElFTkSuQmCC",
    },
    "E13": {
        "description": "cat",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABw0lEQVR4nGWQX0hTcRzFP/fXdTVUdFg6CXuouQIz8O/UB9PIomAPKxIRKjAjiEChehIffNEXhQhCJEQEB5EwCX1ZEfSwxLSIHio3hJG5cXVFbVcdc3R/PgjjXjqPHw7nfM8XQFSVelI3MUkFRLcrqBz+j1Z7r6jSTAXkP26PxfLysagqkpx1qf+eWbxnxtMj8TVWFYv1Q7i50AV3nluoDDkA3MGz5oTNU30dQDRxyextHwi88wG3VxssGfbOBaBwZclybzppALr/tNtMOaIAPAlMHzPTxBYAg465B2Uguh8WABR7xcHKqdTHFvB/KxfAnuc8AF97Lmqv7p1I70oA29xQrqcrEV5fdAIo/aHiHPb+lSGnAOR6ba6d+RmEVA+GVOi++Q0ouxtfq/3paAbghlyYlMuV8FRKudPkHwOgLZmVKeP7EIvDvRufuT8DQN5LKSeco8mI3svREjreCoBsBiOmPbpqL7Dx6zeRjACoacSIwfvrGgA/VgRApRs9Dix/6rTnvkO1th15DfCl9RogjgPUhLPGFACHokt1cPmP2lZU73NjjIB6QexqTYE32daMsmUrAj3Yo588d8ujlmxG7Wr8xT7DJZshWnUEEwAAAABJRU5ErkJggg==",
    },
    "O42": {
        "description": "fence",
        "pronunciation": "Szp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAATCAAAAAAy1ptvAAAArUlEQVR4nIXQIQ4CMRCF4X8TxLpdX8MtuAQOXYXiKtg9AI4EX8URuMb6lc2qB2I2NE068MxnXmY6hZIoJY8SnVP2KCUhtemskfu1x8/W0o9KlShyctiV2iqOHt8MdnKTkqQM8DLuxkPVN4yzdAVGg5otF0naA9GgxgY9NUeb3QSAoOVE0s1e1wAgLEuArAM42FUBojTgYFMnb1NZmOyMt6Ld1AA6wQrQtymt//kAKbG3z5BWAGoAAAAASUVORK5CYII=",
    },
    "V18": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAABMUlEQVR4nAXBO0hCYRiA4de/g+FQHUSJTpsYHLqISksNQptGWzi0pENJWLtbEFG2Bm2BkGNLEOEtaAmEgjYJQwLpQojlZRFSO1/PA5glkZIJqGizm053m1GljGOX6Lq4jqZsJ87fPeDM3la7rUA/FhsE2rsU43IBWYkXaVTEAx6pNOj3xAlO6fVVIckIjJAsaHOjWGCx4UVEfOATEVVNtddhvZ2qKs1+F4G1O7umDszHyRnT/Wge4Kmt1svl+mrNY7OdO/JZNiO9BOxYga1E0NpG8fBx+Pe3//4EaDnr63OY01AMb1+nZ99KQ4DlxullZwkAx7dI0wEKjPFMZsIABYuD+/IgAAqCrfzNjx80MKUBC6AYM57hxRhDEfJew5U3hKaF9ZV53Hq4iL9jiYhYHf8/8tN9Nhb4a/cAAAAASUVORK5CYII=",
    },
    "N31": {
        "description": "road with shrubs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAATCAAAAADZ4SBsAAAAlUlEQVR4nI2SsQ3CMBBFn91RMAASi3gBFJQdnPk8QSQWMIJxKOj4FGkcnx35l++e7JP+OQCxxVHG0KQIUWlnWRolkOJeszQpmsdaNMlaJXU/Z8c2fsgCyMpTfzq9lMFDeF5DXwuXdwAPPE5Hn51XNu32PdI+9/HdnPpGET9kNdIuxFqteuu0j8XsNrPAwlzhutL2IfMHwSREvh7mhAUAAAAASUVORK5CYII=",
    },
    "R11": {
        "description": "reed column",
        "pronunciation": "dd",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAeCAAAAAA9AKCrAAABMklEQVR4nE3LzyuDcRzA8ffzfb7iWXmyJWqWdpAfIzngMvPzIhcURbkoF2cpR0r5A+Ti5O5s5SAkF82BWkvI1MSWAy3zbPY8Hye29+11eBPoXy+LiEhmYYjR0ydPRESc5K12A2Gyz1Y+HIxcY0WPJbnYvXRW2osxmSqIfOcdz/3M6ZdMJ0dpf3Ggx76H1gP3cAS2PzbHjOhq26DxcfPTFbh0dbmjXx7fGjyfNf7KxGxaUnOxtZzEVwzhv5Kx/BXZ2L8wZKV3qwD0fc0Du3c2CnzUAb6ChfobrHi2Ap2nAk9VIeRVofBThcxwfQXlXhsFKBPQJQ8Fbu4BuHJNgJ1zACvRgoLpGgCzuQsFThnADU2g0EoBSFFQtDe9AzgnjTUav/k57hMc1d2gCdbOTJng2Qn9C738dVzSHIyNAAAAAElFTkSuQmCC",
    },
    "V12": {
        "pronunciation": "arq",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAASCAAAAACCrooGAAAA9UlEQVR4nH3PLUtDcRiG8WvqXFKL30ERPEnQcFCQhTWbxyoiwh8GgisDq804g80oR5MDBZMrbhiG4IImv4KC4EvYZTgTwR284/N7XngYnw2qtsJciaHM7KpX13dqWPmLhdYyvYNTiGobRQ5fikJh7OzxM2Pt/nS++pvt0kC3AJjeecrqSXX/WW1XAL48iWBpXU3jOE41gamLvm4Ctd5g130oAVQ0AZKurgET4bbTvumEn+urHy4AdT2fHH6RRS0D1Wx4KHWbAA0v8zR5dw+I+m95SmozAhoPuVrWAESNXKVtChDla6L5kEVjgJF8PWL+Hz1mFOAborh/jcikaEAAAAAASUVORK5CYII=",
    },
    "V39": {
        "description": "?stylized ankh(for isis)(?)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABcklEQVR4nJXHsUsbYRiA8ef77gZTE6pYeg2SCAULmVJQqrXQTC5xUXS0i9h/QKTILQ5Ch9LBoZ2KQ3HTNO2SLBV1UFAS4VAhkC02aK44XNQkiMf3urh07LM8/AAYy3tefgxAA5kfsa2tWO7tA7/8mQ/D+fpXQMHI7w9PsxT/fho/BFiophpDQ41UdQFsELGUoCwR0BBRRoEyKgIa9rpSp2F4muraAwUUG2dtHiWfZcEG5yT74g37j4uOD7w+9EVmZ0X8g1H0y43tjGt837iZnY20+h5zv9V6JigEA+8/XhOsrAbpI5GjdLC6EuhoNb472KzVmoO78WpUh21zEynU64XIjWmHGoVG8TDNP/0XbUSLATBaCdqyzt1uAel2zy1Ld2bWnKVbuF1y1mY69q93r2znQnOR2AwH1ulfvpNKolxOVORuuR9IXuU4PiZ3lQTo/SnTeB7Tku/F7vs8WXo+94S5vtJUc5FhkctWx5hO61Jk+B4pX5rgiuAM9wAAAABJRU5ErkJggg==",
    },
    "Aa1": {
        "description": "placenta or sieve",
        "pronunciation": "x",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAAlElEQVR4nG2QMQ6CUBiDv0dc3Ng0MJlnXDiL1/DnFuIRcOIYJp7FFScIziYw1sGgj8A3t01bALz1ktSbB3BAdt+RAxXP4wOAWCoBoJRicCTN68zIZZO2+FoTao/J+GOSuX6dE1INTsyY+ABTNBctGFfDLB4bq48DbKGqI2m64icqtmn7nX2dzobstucUhefAwd7BhR+Bb1upX0QHcwAAAABJRU5ErkJggg==",
    },
    "A35": {
        "description": "man building wall",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAACI0lEQVR4nE2SW0iTcRiHH//7dipatI5CWlouoQOZtSIzCsoLuzGMopCIMDIKQUqwi6Aija6iDMIuMkKMIjvcVASKkJlRKTOK6Tw0m1io6Nymmzu8Xewrey8f3t/LA7+Xe4HJClORN/JyMQDMfxqZlGoLIhKs84rI5RQALsj0i+ehzcjf+ZXc9zU3e3aIU10PhZ0OhycysfQYAHZvodRHwfokvgDcH6+G3iqAupZdY+LOxNgYt0OPy/pp6pQCnCIPQw0WDntn7PBtqrxAJvZhOO2Wm6pyYDXTErBDt0TWv5GhvI5ZCe1nj2zXrEkNTJz7kNYGxAxoaKqFpHfXZN8tAGzLALST93cDpsGyYWotYq6MRw80RBH1c8QApPgHwH+naR2ukoO5qZi17IwYkFiycdyRUbIJHvWNvtYoplP36ekVERm6xNbhuGf2N6JzkdjXa7lroDB2JrtV5nh7vhEg5Ww4jRuiunT/vkPvogCLyh+MAqqk3QwYfWUjei+OtjCg3IMaoMZckuSlPjckUGmpcUAWZur3Sls/gxWaJWiHbulcCcCGsKuq6ornP59cAPK/J1tVM3p+NgLA+72PifYHUSeGNMAQuNgLQCJgo2btbf71uELPLf8hq7R6UZpGFEQZda6lD4bSd0JNcGZbVlZvrN6W5DlylzzpmPurHABzwRc5SoU0zf3hFuDIs2mRV7V+KaZa5LypyC+N8+B4QCTRPy4izj+tryWGhnq3qgAAAABJRU5ErkJggg==",
    },
    "T27": {
        "description": "trap",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAPCAAAAACt9eKMAAAAqUlEQVR4nI2Ruw0CMRBE5whAVOKQlA42Jr3rgAa2DTIaID45oQZqICKADCTI0OkkDwE2H3t1MJE1evbOjiv8IWJkuPWW37KuugPJ8AuUHe9rmX1avsRkz+sij0afTzwXFqakZtTRyktKPI3djQNC9cQ2Dbp2ErqmfAtAolpSHQC9GDM1BXHkEgDge1/2/eqj5iqGDVpQ7z5OnEenFwtTYGjBJEFl/mux6AP1mqEKOrxlCAAAAABJRU5ErkJggg==",
    },
    "F21": {
        "description": "ear of bovine",
        "pronunciation": "sDm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAATCAAAAACv25LnAAAAsklEQVR4nG3PIRbCMBBF0VcOAiRLQLINJHIskiUga5FdAjZyKitZRpDIysiPRDSEtjQquZnJ/FQsLOO8yB6luP7jAEC3mrFCd7sReM5YNZiaWhP3gWVEzd2S3EBx4pDUO2BySio/bUnvR2iB3by+dwMYjxje8W84H3ssx1+DC7z4tXRO3ZRyeRS45JfBv6M8CXBJuoM1SrlVo99bI+XEVGnTwWGfr7rQ5l2FH/uBX08KwweVmW2+61WRgQAAAABJRU5ErkJggg==",
    },
    "O29": {
        "description": "horizontal wooden column",
        "pronunciation": "aA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAHCAAAAABBpmDhAAAAmUlEQVR4nH2PoQrCUBhGzw8Ts49gUnFYJjNYTDc4kNucuOi7WGxGjTNdwSAY9hiKVbCsajQMfoMGUdmJXzh8RwCmabLhEwO0oBJ4UHjFBAHsDkZ7MFClMe7yzdkXGwYGUbJTM3qN2yv3B3CEDLBhPc5RVQc4VV0s+z8iAJyKGXSicpvfjnMBZisu83X5N6A2TJPD7V9pj3fpE2IeNCUJpRoVAAAAAElFTkSuQmCC",
    },
    "M25": {
        "description": "combination of flowering sedge and mouth",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAABg0lEQVR4nJWQzyuDcRzHXw9jmkUza+3gsFAcVkpjysmJ45paLtzkSi5S/gIO8hf4ccKSljwhh5WarW3kx1Myz8pKUpNf27Mtvg5+PI+4+Fw+7159fvR+Q3MrLXNCKBP16DV9NbCobcmF0xEDbFq5zs1b62fEpgHa9sSaDRyZ429UUTHp2+jphbt7ocO3i6ngggWgaFiXPnsyok8idPlbSbV/QEP9C/b5jcDfB0DkAYBUCoCHCJiSqisn6WaknCvkNm0MOqqXYtF07g0amn1dzlLLOhAuyJdiP3B+HtgXl3IhDICctbQFD0qaVjoItlmyMqDsqBkJrKPPz6NWkDLqjiKNB9ot2/HDk7sEnQ5Pt3cgr4SA8EvoTESHFWU4Ks5CLx83d2/M7v7lcrFYXu53m292AbA7gZpVIVZrAKfdYM97e+v9nUIi8S1NX6KymsrXH9HVDSWzNls2OVT3EQBAx6w4icXxdnmkyaOvySqz9pgvl/OPmrlKf9I4pj6l00/qWCMA76MhlGL1rf4aAAAAAElFTkSuQmCC",
    },
    "W17": {
        "description": "water jar with rack",
        "pronunciation": "xnt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAACU0lEQVR4nF3RO0hbARTG8b/3XuOjzUsjxlelFvGFFNuidRWsVUHBwUWp+IKuOji0DnWwk4s4tO6io4PgIChUoWoLVQhGkmACPjFpqIleRWPu6eBNh37rj3M4nA+Aqfv4eS3d8ke6qT2P308BKMDT1tmBWJe9Z7V/tcfeFRuYbX3GQ1Z+ZtIZXYsWURRdi3aS+WPlAb5KIuA7FBG/zy8ihz5/QiZAg9/raeXurQPS8qq934TM12ffUcx1TAhAvdQDyCdSF+B4STvQRhvQzitHasK6dqfr/cwkrhIz9Ov63ZrVlN7EVEdwvSW6/HY52rIe7JhK9AKQMRRYyqI5chAooCBwEGkmaykwlAHquCGj4NqVBWBBdl0wKsa4qr0b/PUkBLeh5z7AR+gWQpHDgRNl5NFAxAUWB7lALg4LuCKDj0eQuWzvPFRchPeB/fBFBcx7s+dEIXx9VKJRiicnn/wcD6VoJUfXYRRUNjQLztCibsOmL4acWLQNVBRgL6eYmvCmUUGFsRmuoThnz/zOmbuM+sugWkedGrysp8x9ZsqprZiaWJwqqojHaii2nZpypefhOkkeF1J4nDxxkadfmXLrVYj78RgYHvxxFO+tKTcejZiPHUF28MXQPDemGAEFPci+IPsEdZSAkWouCWKQBJIYAsl/ndqEdCt2wI41HbGlRC0XrKVUqqiVlFqRctUUZ8MllkalSUdvUhotXDY4AWSasS07fdvD/mqq/cPbfdi3xpgWDcM6nD6p2F9MZr/X7gsnnW8aDPfwF4M0+Wx8TOO/yKTy4S/x5gAEpMO0YwAAAABJRU5ErkJggg==",
    },
    "T13": {
        "description": "joined pieces of wood",
        "pronunciation": "rs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAA50lEQVR4nHXNv0sCARjG8e+dScolCS6KCDkEIY4uzQ7SIp7gYINDtLZJ0H/Q6NJck+AUoWIQIoIRTkaKONWQ3BA2WBCFp2/Dcf6i3uHhwwvv84L+OU1gzalRf+gGLMuTP2OeWL7t77qaj0EAkl8Fjr5zCoB287q31XhxaPEwpMbnZD/y96MCeO/e9y9FqqGOAsmr52DT567kge2aXBzulOQMQBdjcn0gURVo0Qr7NFwqIPSGJqDCWrJqE2VuWdpPF3Z4UG1Him9j207jeGB7s11e3E6WepR//v7pHwA2AEiHnDPbsRgCv7GxQt00eFwpAAAAAElFTkSuQmCC",
    },
    "O14": {
        "description": "part of battlemented enclosure",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAABeUlEQVR4nH3RPUtCURwG8Ofcrm8XtSS7eMWLN5WE6D0KszBzSDEsiIaC6As0OCTRElG0tLQERYT0CaKXqbkv0CJEVJtDDVmSkmZ6GsJo8O9//fE8D4cDAAC6L1dwsmmSZwTD0YOj1QcwWRe2AMKvf6sqvLqvoIt1x8q55I4VvauKXfzzahVAkR+GjQeanN5WJITnxJSX1b3Ga+CGhH4xNIiOZZRL8FQKLG2GCACQ3HKbm2+YgH0JAPSyf/LTb5Y87wzQ2Xzx6RE0uLIBjGnx+QiQff0PpSIkE+Msb4G4nsm8cb7ZKF+/tTu+S5AAwHr9SEZFS1/X2NBwEx8db3kS+5vNA8fkvmgL9kOepftbbFGLKDcrd/l7zpq9L3tvN9L9QiihjaikC6xTKZzf0vnqxVXO2Uv7BFNjSoD2KcVozb9opJ/qaxWWSpKeBRAI0v1LknPFaiddsDsi7R9F0qEJJrPjiP6/vWiVM4ne37pZCNPtAATdQPqZ7P8BpANeBjXdlJYAAAAASUVORK5CYII=",
    },
    "G9": {
        "description": "falcon with sun on head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAABy0lEQVR4nGNkYHIN4Li8+DUDGmDL+H393J9t0ujiuh+WqMtH/Z+MJswi9qLyMcNDEw00caZ/bOwMDAwcf9HNUX20wUw361MtujjjjP8P7/z+pIpujoTCH7l709iWaqJJLPt/c+Y8jn3/e1lQxeO2fIhWU772/2comgbpGwcsr31JXPhaDk1i0Zv5e0q4+Q6flEC2l4HhEJ8Hp4HGp8g/i/RR1Cu/axFhYGBgkN5/zwJZnO1lE4Shtucm3LVMDAy/zkFtvJXGUMiMpMHzjh6UZfqyhQkhzrX9uBKExRj9NghJg8e3h/4cEGb/QzGEOPfO///3unMxMDAwMOw9KY6QWPD/38d3mzMVGBgYZB82IcQbnzQ89ko8fWmxLyOD3ekouLjuowMf1Bhks+++ulspmP5AgYEB4qyP/DcmSjB4TRG7cTXwBj/jFCGYS48f2TqVYcr53GvJ3G1P/v9fwQ+VWPn3/89TL4MZ4l+GMaju+/9/DVz80vtbc/gZGCdc5mQQOvr/P1T80AmWfRoMDAwMnCeXCzGov3zAwmDo+ZOB0+BlvWr+7f/9DN/zt087yfFMiUHpwv9///7+//////9/f1cwMDA43fr75+c5AKBcsYh74FdhAAAAAElFTkSuQmCC",
    },
    "S1": {
        "description": "white crown",
        "pronunciation": "HDt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAABXElEQVR4nGNgQAPen34EoItJbXhxby+64LQPoYZ30cSMPkxiML6FKsZ/+QmP0fX9KGLMNb9iGJa9tEYWk2x/0MvQ8sAcWUziwKckBr//UchiKWcuWjIwzt3KhxCSm/zzgigDA8uqaQgxma3/j3MzMDDYvPBA+GPT/z1CDAwMDO7XEHp3/N8lycDAwMCQdxkuuOn/XikoC2YkY/T3ZaIQJsuNRqhg7O9UJhjztS4DAwMDEwN31LP1/6CC4o9uQBhRj+OZoWJc+6dD9Kifmg0TY3B6m8jAwMDAwKTLuP4vTFCJ+zyE8aSTESYme2IDN0Ql17X/MEE189VfIYJ/rQLZIWKsNs/OQaXLD3xdI8DAwMDAIP92LhtMk1DKm34uDmYGxpY3zgwIkHtn79cSBoYLp0SRBPnEBSeHMzj/KWFAASptHNz3T/HCuCwQNyQyiSpUf0ZVyT799592VjgXAKgPZ9Jtv5u0AAAAAElFTkSuQmCC",
    },
    "M19": {
        "description": "heaped conical cakes between reed and club",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAeCAAAAAATRYE5AAACSklEQVR4nGWSTUiTcRzHP8+z/9TN5qampdN8ydK0TIUOWlBIh0hFtIKQQAqCCgrtUCjYK1aHoii16JIHwUMdlpKamGQEVoIGhaboYZovTJfJwk2f7fl3UGjS5/b7fE/fH1+gfTSNDUQODicDOGRParA3X9G0uzbAIWVdcJA55VoMHBSg6N8qyqPX5KqOaow7YXteLoi2j53rtPWjIldX91nxC0en78gBwQ77W7crrADAeirJ+qX13kuf6jdDqe+mqcsvwPxgUGo3klMG8qBsWpAc+s7rNEDx7RycJz/L3Z4lmFEFYYwh8ec0Jf7orHcDqgoCEZ7rCYAW35jYW/kTwKspoKjCuvP7MrranUV6i5GArs9HrILRKawpbzQwZDG3kooWY4FRuzMkdoZCWQFN8k9LBpDaIeea5YA5+2uvOOweAYWKNrBfLMl81TBb6ZeBaK/Inl4EhTYMNWe3tVX3e/YgQZcir2cSgITGouH8T8AygOGDiHPpIDlffNTTnp0L2An4dLVPoACSJrwrtet/zzgzYUMQWLt+V70PLYvddcgEm/PnTbpgq/ADDZckONJKTAx1FaKj4Fqpg2cSiKqdlHLuWgRtzaULOVx3aTU8lQr7P0opOwqAzhflQ1vEI6rueFTiTl+1jD9+PSWBgBFFEUuN8vITjWnwtY5n5Ril35DQJ0NUIPrWgtxIxPGOTQLcDy0X9KKAItdrpNeHqwvLAER1a0G72jtnPzYSrwL8mhDiX7B9fnbcbF8TSvASYyz3I8MKBP8hk6oh8y/ccvJrBIIUvAAAAABJRU5ErkJggg==",
    },
    "G23": {
        "description": "lapwing",
        "pronunciation": "rxyt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACHUlEQVR4nIWTXUhTcRjGn+3srG1s0YdDWB1mLa1d5HBGX2JfQkFhQl7IWNDFxMo0oouuCoO6KaguCoWyYBXGImZRuWbhNK0VWI2gaEaSi1nadDG348bc3q42dto59F79+T8/nvd9eXiBXHX5GYiVPP/Kbmb/R4jqgAIAoK7aqtmVkUAAsNWeX5MxSqukAK5z7OKWquOJr0pxfU93gFqYg+3G4C0JhxtzRAFrSWnp20GJLjKL43zQpQHb8fumfZPUKM1fOACNA3y8R18kygHg56o61tbTzr3oMPvOidroR97pPOSu0EB7KemrFyHkR9ItR8OPVQDg+JRsKylGmJPkPDV/ZykAlLvptlpkoxN8/+n3z6vlAJbYhj8fEMnZ8jLReoF/ogeAxddCQ9tzmcryyLpjbWf/2GUPR8Z/gN1tM732Bqb/tXk1UWbo4qNv7jpqtco+mn3UKPQAOGe4ObXC2tAUS8QZTqcAHxro9RcScHS7WmeB5ZUbk1GkanasUWfj3wSE8cEG71hSYZYvU0X9vR8X1e03zQSEk1wmIqJw00rL9fjUfStgn7gqJCpnUodrYz41oCjvjEw+PeOiiJDgIsHVuDKkBQDoDnlD454ahYBgM/3f8+vNOd1rs1NhIWGSDWdBoBwzisJ7AYCdykEgpRIEJyCM+5hp6Ncbygo/c10a6jVYMFQw9zLctgXzKIrrGRERpeeJPrj79hYqfwH9ZsGMUe3DbgAAAABJRU5ErkJggg==",
    },
    "Q1": {
        "description": "seatthrone",
        "pronunciation": "st",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAAAg0lEQVR4nK3Ouw3CQBCE4f8eki0RIHqgCwIKgJweaIHUsVP3gERMSg1UgUBkWLKx8ZJwqyW/yb5gRgMpJxERr/R9c8XwtT8bMlJYOrAkC30ZXJiU1a17bwogAjCbHz/yVAq7/6ky142MHBLjxQdYSuK6e0B7/zlSH7TZE9kulCucYPMFoFAftGrBuF0AAAAASUVORK5CYII=",
    },
    "S41": {
        "description": "sceptre",
        "pronunciation": "Dam",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAA2ElEQVR4nCXLsSuEYQCA8Z+3T5JzEhZFoihGk0ldp5QNo7L5D8xkUAzK6F+wslJnYDzXDUp3N5xB4joXus65XsO3PT09D4TVavyAvUqrdILTZiE/H9iOcRPmijGeBRz+XN2+LaH5ObvWOUfcN1qoZHjPsREPhIsSrfYXQzhqLIOp8nWfgInxuygg9p4I6AtZaVO8H07p8i8nIBn5/QYLtesBAfNjrx0B+exNuv/6TOFBLr1nys+pqdcGM2Cl0d2B4cfj3foiJuPWdFwPdNtJf+8n8F1MkurLP6H9SoWVOfvfAAAAAElFTkSuQmCC",
    },
    "N36": {
        "description": "canal",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAJCAAAAAB7rAGRAAAARklEQVR4nGP8z0AMYCJKFQMDA8Px/8c9cMt6HP9/nIGBiYHB8oSMJW5lljInLCGW7uLEZxnnLqjb3L7jU/bdjXi3MVI1QAATIRQLFEkhXwAAAABJRU5ErkJggg==",
    },
    "M29": {
        "description": "seed-pod",
        "pronunciation": "nDm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAeCAAAAADBFYthAAAAv0lEQVR4nAG0AEv/AAAAV6cABAAAUxEKAAAb5fdlAABs7r3lABPJdgbDAHvuHACsAlvn9RMcAt8eAzouApIDFxkJAuHqE/0AAgEBAebxBAkD7AfvBDUJ8OrjAv8GAgAABAAMGwsbAgAAAz0iAv4ACCDoAuf16gDxAj0F6u8jAljp9PMBAh/W+PwDAgDV/Q7bAgD1B0jcAvgQESm8AqdBHRzkApMILf/wAACR8/5LAgCe7wE8AAAATu7xAAAAAEjiPSQ80PjyYWgAAAAASUVORK5CYII=",
    },
    "O47": {
        "description": "enclosed mound",
        "pronunciation": "nxn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAALCAAAAACvnHkvAAAAqElEQVR4nG2QMQrCUBAFJ1/BD7H3AsZCK8HC3soq4BlSmiNYWXiLHEG8QWwCdmliZy3aG0TUPIskqJAphmUXHo8FrJ/on8S3gLWxpMv5uz9Liq0lyKTQ4xcvlLKAmyIANvdhJYBIN+OSAnCw60oAKa6pI44s+qUqDBQAnLaMStWXnEk5rZhWAsbkBJm0HDR0c2x7N4Nr4aBXy+jx7Joe7OcAHT95N/zgA78SZkadX0rNAAAAAElFTkSuQmCC",
    },
    "T12": {
        "description": "bowstring",
        "pronunciation": "rwd",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAbCAAAAACsSnu0AAABZUlEQVR4nG2RO2hUURBAj66QQiz9QCwugpVCQCyEkM54ZTtBiI1gQCSkTCOC1YKlSRpZAsLdxg8iLKi1kEohCItFqiWoaGEgGgtd3Ignxbv3rZFMNTNn/kNH7bCf6JePdg7Wdmy3a7J83c2zNUiaClnglk5V1sy6aszk51F6vgTgjqa2Og3QWnPranB4rAIGBrnegfBZ1Q2Y2daLTG8Ff52oil/5pjoR32kTmoMQvFYmeuGO20kvA82dFHw0WqvRs4z7ZxCSp0YolZF4bAiO1+C0dc4507/klWuxbyuvGLxbwAWNdPUwQPqty4V89T3ED84B8EPvZ3CputVzhwCs6FKj7LMKEDUeAnioTQDO+Kk6b1sBuKk3AHhqL3/HqtPxfr5C+Qh0c9KzHJtNYNYBAFPZNSJdv1fK+G0AnpRqpU8t876tlJav2SsOH0xCXNHze8GRVbW7oC7+l8LJtK7+fXNvbOTbBRsM3tTsjBF+AAAAAElFTkSuQmCC",
    },
    "O39": {
        "description": "stone",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAKCAAAAACLAsG0AAAAMElEQVR4nGP8z4AdMOEQZ2D4j1XL1/84dHzBZRQ7bjtIlfjJwMLAgM1Z3xgYcXkQAA2LCezNUopuAAAAAElFTkSuQmCC",
    },
    "N17": {
        "description": "land",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAGCAAAAACOD2N5AAAAN0lEQVR4nI3OsQ0AIAwDwYcZ2SKjOXuxAa0p6C2ufskG7eNki6FFkywau2JD2TMXz98cirdtiwt4Nkxg5Dqf6QAAAABJRU5ErkJggg==",
    },
    "G48": {
        "description": "three ducklings in nest",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAbCAAAAAAikDLIAAADBklEQVR4nGWTe2jWZRiGr+/bZnMqw8PY5jSwKeayzYHRQJxrDSycI4JRdlxLCZvrICGEWlGQzggKpUJigUSHzXWaIVhqsKYx2iGnNXVTckfHWstcO+S+qz++39yg+6/35r543+fheV6A1FN6OA6A0LKs/Db1eApRpWWvWpWZEJgQUFwFA0lRf2jx8AaAolqAwrGC1WOhOS/XMalCfWa3r0TNRaN6HSAmMF/cZGc363a8GnVlQf4aANWBy5+E11uzsyfVKwDMm/X0pj2qTwKwUM/UjerjTKlgMMUOCOWWDmbD7eqxaDD/643cetW+ZdPgquPYtahEHUuGYnXnVPiJ7guOsUDaxuxZpHWOAkVXoZSRSPquBMaGjV/w/oUYWEA8xCUMABy4AWUt1eFf/TcE1JrHkZ4rF/9U2xLR8xOqtiYAKQ4B0K7rAGotiL7qH6mA3kedei5MGBYxAhBOh/YoFQPAA2T1Qhj7WXvPCBkfJIfhOWJnApFSWA4QCdqZOdEFnCCUBD+sgS31sF79BoBiLQSOuB6AIjOBNt0EkK4y8xENPJ9rKyUGNYeU+bToqwCcUO48qtp/c9Y5m33z3R3BbC94/4/qUoA7lJxq9bIdAHRYSbn13T4PQKPOO6X27QD228TZMcczqDUPoHcijRdVfQEgy2bO69CEXZ3d+iXqwEcHc/UY3O0SKI8u2tASOGkm2z0AlWoUblAjan+fHwLfas2gOpKME0AoobwxomoNg/6WlzMc7G0SMPDSWkjdo73bzAWe6g7C8XxWv2EzJG97Rz0zuWkZu95TleLWUVUb/tbxuUCFfRuA3IO/+HtjS1NDU8vpa8Fl9Wrk48/umrtf3RoD8MQ5jz4EUOL/tPXZ22BhlX61Jvq7WfTWw5z99PAFZiT6WPb4ZDGxhy51RoDyffFDeysIYFi5rmzx7O+vv917SaZrJVtWrEis6Dx9kSkYoGLpg9C3NzYy43IVsHleOG75o9Czu3KSmAaTcG9ywazsNPjn5LXQLQVz/vrpxvXvhn9uvwn8B6Mx7fyfAIDLAAAAAElFTkSuQmCC",
    },
    "D1": {
        "description": "head",
        "pronunciation": "tp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAATCAAAAAC153JpAAAAqUlEQVR4nFWPsZUDQQhDf+ACrgW1cmXgUmhh2sCZS5g2LtwWCB3qgtmxvUS8L0ACANDTtjv4qmFXZl/wcAmAaI8305e+qFyXSwJIj8zPbNeCtt0bp7ekfPVYQlogRwTIrlcDckI57AMiKAM4CZe6YsUYH3j1VYtz5xzZ7vH+rBqgG6D25/IAOQDmsbOPHYvZ05Wr13QJbvDz+7jzOOoPgDsAc+a5atsHwD9Cr35StKt3bgAAAABJRU5ErkJggg==",
    },
    "I5": {
        "description": "crocodile with curved tail",
        "pronunciation": "sAq",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAUCAAAAAAv06vXAAABKklEQVR4nH2QIU+CURiFj86ifpFENOjIBoMjOhPX4g8wiBs0/8IbLFgtZIcUnGM2SDqnQQKNhIYbPoOF4TXpY0D0osBp732f3fecIwCCNyWaI6rOVbsBLDOHsjQ1ZTYMgs2lAJMIYNmZmPfe+5DKAEqz7lqaegdIArDiDAy8c5KkpOU9sczFGIFv884msFCPvuszyjApVwuBWvRQHB2Iuk2uJakGtYVJeyCNy9gFKZEE+39SSEY/JynnR4NJgknKpDPAt7rfTYNJNvxBrm7b9T6FnSjeuypAWdmnMXQYbZ+PmgAMb+CeU5U/l0bQyl5nIEnLnYs7SR8FSVrNn79sq6ckzjhFWz2QHpmDrLkGtPPZBg9TtusnvxabmxXg+D9Ueo2CDN7oXR4sfgFzs/98TC+WAAAAAABJRU5ErkJggg==",
    },
    "L7": {
        "description": "scorpion",
        "pronunciation": "srqt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAABjElEQVR4nFXQPUhbURjG8f+9XuUqtAED9YOIaIuCcctQUUES1ICR4tSh6tLBxck4qIODbbdWdBIHRUTcRATFTVFw0FLBBEEIxVSJrRi/yI3gV+7b4cbk5kzn/M7DeXkOANC0KAFHe5uD7Pp0+OeowXcSmfG8iOOHcRNwOyoORCJlaeuRBx9A8CQmAyoAjVfxgHWpuA/MTgB9V8YzD9f926oEdSSZ6ATdaeGsfANPWFYo7D4zwrs/24upl1ANQzFzwrciFxvbdyLHXczLHElJhUw5bUH7MDxmPE6O3t8iIiKPrdbcsEgyJdrvPCWhuPcBeKUa8ZIHk9LCIoLyBoDX0Wmto/ujdm6rjX79vA4qQNy0GhX83YS0re7lAVBUfJUxFJdlYmYsRR8AchbN5jTr24JGImNGuFwB8Opkc+uaAnicUZvdu3oBvz5ls+18bz68fdq3F1i4fE9t5Kud8D77+Wy+yzFXbK06tKTnGINyJ/3pvTUDp58EJWpO7IvsNC/Hqu1U8+u7i6qNXuv0H5F4kO3NIXdhAAAAAElFTkSuQmCC",
    },
    "V23": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAbCAAAAAA1sqIBAAABZ0lEQVR4nI2SzyvDYRzHX98VayaFiz120JaWHBQXSo5kDttBaqS1chGO/gK5iJM4Ui5ayFCcHFx2kbkoHHbkm2iEntFqH4fxzY/0fd7HT6/n/f583j0W3xRTqwAsXTxlPGXACtXkNYDlMItef6zhyAMwUCwWx32HRHWyOb31DFh9obaSx1dTCg0C64W8fUfkaXgMyOUmAKZXAOulFiBX/XaStzOOdcvb2iCcX86WbRoLYAn7u9dXj/xRf095DnUDwRvgXRb+Il/akNO9HgBrKtVVGa0XfqZ2B8INKdiLVy6tGgqEvf7eVoe9I6KjSefB6Ob3QuKBsNcfqzum0shrCUSCyzM8dNz+3iU+KSIisjgZ/5yciWT/391RQisZcceUKNs2sNO20vV43LDtJnzK3a1dlJ43SE1rJe6hZHwUDdyUVH6mm7JaIgZYp0jCxO5e0ibYvBgt126GocW9N+DAoF5gxyiTevkAGgyDJmoaSc4AAAAASUVORK5CYII=",
    },
    "C19": {
        "description": "mummy-shaped god",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAABL0lEQVR4nC3BzyuDcRzA8fc+e/ZsfkVEm5SpuXDwO0lpJCUHOUgujm7cXDhw8CeQg6M4OCo3UmpbXNZqssY2bH41a82vx+zZ83XxegFQdWhG3sMAzJmGfzYPDI5eKnWycIdtMrmidlctI0hHptSV2DxW6oFFVRoJKWUe3YoVStsT5Kbnz3A2ng95w6dNGwWtmKf48jYe/HDBQGbZb2z5W69hSeXje9B2Izioa49Ar1sIZ8Gn0+QEjl+2X5vZVAJmbkfz0oAA8WhgDRcC9PA0DAiOWjtJAxuC3QWBr/pnBBREramLvABPFH76078aZSsGMY+7WihlPVDQdEvgygepGm+FQItD+NT77oXOMb2SCZstJZSLju6Znn3TB/4LpZRx8KhYf1f/tG7nd1kQUy/+ARNegfObdR90AAAAAElFTkSuQmCC",
    },
    "O11": {
        "description": "palace",
        "pronunciation": "aH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAAyElEQVR4nG3PLUtDYQDF8d99eLhXMIhYZHIZgkmYinHFJIhYZhkMDa4N/AqajLYlMQiCVsMFv4CuisGvINaFKQuTx+LLgicdOH/O4Rg2B93uoDmMRbu2rdYusuRb6bQsy/IsRfMl5vxG0WWV1k8K0VNlpyDIre29vwjYr1/0BZ8zx85nBZPDheu3IFpsjW5kooOlh0cEK1n/w0Rk9LqpPj1xe4/djtSDXooaW2hMM1d3aB1FzxWWBTnkws+J/8wYxqLOKjb+Cr8A6O8xFOuBcCUAAAAASUVORK5CYII=",
    },
    "D2": {
        "description": "face",
        "pronunciation": "Hr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAASCAAAAACYkmqIAAAAfElEQVR4nGWNsQ0CQRADB0Q5iGQTKnJPpieCq2gI/uEROPJa3jEA1y519QpwATL3G3CD5wOAqDOZUQOAdgCYKpBaEiChNqhRQ3aHgegwbpY3jfcKVWe/Ry0klrXWWtRsD92axX7K2SFz8BrS743qBj00x+Jpj/zYM7/6T17K3mG71gZe4gAAAABJRU5ErkJggg==",
    },
    "R12": {
        "description": "standard",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAAAAACzJtCvAAAApElEQVR4nN3QIRLCQAyF4b94hhOgG4XAcA10BWfgIMzeZbnCqhoGyQmq1uzUId4gimJnutFEf0le0mFHeLxolI2SZC12Uhws55ZLApDSsCY7MQNbgHmFPQ+tWN9wWREYJMBGJYCiyllWKUXLFSYFoJSfpUB/2cP7tvwuXDnfKewaISZlq6bVZVJ0MIJkDsak6GG9JAej9zGSj5mPVQ/ZuLr+gX0AvWBQPG6eKjcAAAAASUVORK5CYII=",
    },
    "V7": {
        "description": "rope-(shape)",
        "pronunciation": "Sn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAaCAAAAABAuCn5AAAAqElEQVR4nE2OkR/CQBxH3+fosrI0nGaFw8P+hXB4OA3D4cKy/QnTw7DsdHjZb/YNFvTowYMHhGSWAtDJikktwSz62pQYlIBB5ta8gBverfjhJgDKjBvYAHs/sysZGJUgKULRFRpZPKicAMl63bdAL8s64/hHRakCoJciOODB571YBfPSmdSAgzDBEZbLkgMQLMeoscI/dfE+q6VRriHqSbEWIAvrAAj2BdvjXinRgFoPAAAAAElFTkSuQmCC",
    },
    "G45": {
        "description": "combination of quail chick and forearm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACEklEQVR4nHWRS0xTURCG/3N7K3jRtCgGlWpCKAmLUsGKLhSk6EKJCxITfABu1KXGGIILn1FUEhPFhUsxhpBiYsJG0EqigSYkPkK0IlHBtqkWvRVBbEvtvW3HRV9UT2czZ+abf+acOUDK1owHFtTDyGFlz7wHG3toD59ecCrN+uZi+4QuKy0k/bQefskid5Y0pMiKe1MDm9J1y86Hahm0we5UYpdKYXumj/b1B0Acn9yWjO/TrQFaMsfxFECdx53kI33i3nkhg9UilD2KtYl2CwCADUfDqgCgsMJozAd8Eo5tr3W0zV1JlMehYUBJ14j307v+QxqDq6nzIoBLP48AwOMz2Ckzpq8Wo+uvG8LO4I7gYugHUGoIOOOAKXRUY2PPzcGeUOREOb4UFtAfSRWJoIGqBbAY87N2qVQCYnH5K8PGuqGmVzrXDEzVDjcDE1xZK6yabbj8xtMLVIzd5SxevD2Js+GTAFqUDuF/XiPvRz4ALH/iKefo+6ZY4nAg8JDzt0Zftx4AkNcR+ciR36GJ9gKwlYbdb90cXElRen/uhl/5PHycg81000Y0fe20mQMBE+1b+4taUuG/r9uiKN97Mc+VAmzsgRbWSH0OvCHehbzB0aIcza2/X0BqtM/mUA86i2H1bU3HaXWVhQGbjXPyulb3y8xdEm7VqdbY6ILOVPPNVlk/M9TvyG56laK0xLyrk/m/u1fGVx/aLcsAAAAASUVORK5CYII=",
    },
    "P10": {
        "description": "rudder",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAABYUlEQVR4nHXSTyjDYRgH8O9+ybClOYiUPzUZqR0krORApnFwkD/LhVaaJaWkJFJOWpmLJOG80lpNKxe5bQcHyuxg6mU4aLbM1tqffo/Db4dl7/te3m/vp+d93qde0LMR4sVS7mGxTofoa1yoqqk4fVjE1XMJiprFbI3R24iYV4heR4Va6ydig0J2EtG1pvxcAgBUAGnzcaug1kU7iym6EGoP7Fnar+FroQWwZ+hczdPDrBaAI017Ek9lHQCsZmWXoC8AzLPksqpMj2hGCUM5ebtsblsmoARpo0C+/n/aHEkYlNR0T3nm0Rcfp2zRR92m0u/Tlz+w0O2ZvrS4N/zeraR6dgcMeNlSKXdONBTT7rcJqLYxTwdnOGh/TwCgL/7A/axr4S4AMMpXdRxtiwS1ANSu3CxHVeu0BQDtL6e8qyu9NCkBVZdBnsLkl50GNawhrkIToCf3mOOHr2hcuEnGEvIfeDV+1v7CTzAAAAAASUVORK5CYII=",
    },
    "T29": {
        "description": "butcher's block with knife",
        "pronunciation": "nmt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAACn0lEQVR4nH2RXUhTYQCG37Odc5Zu01IX5pYZjA1LbTZQggqqrWmwaUR4oVBIJv2AoF1EN4H9XSQU3bQiL4oYZUlhP/SjQWJY/qKtmZk4FVq63HTt6Nzc+bqYy5Mzz9Xh+Z7vfeH94KjKVlJY/aOmv086mr+Nh/nVpBANQg097BzwTYXJ/6z7rlB3F0cIeXXSoJCsXEypzh3/citQxqpUENttPf3TVCCmmYK6dv+0cQS7D07lbNsg735G99hd/ti0Qo8zj4n8Nb71BgipMxtSEkTCJEBUdpU53zQaAcWq3Gz1uuDTnx39YzMCCSiuyRq4ZB+N3rQckmbINXPWd9zM55Cg0txBWkzJ8Usgta5thhCu2iiOJgGQVZcr77i/+mlfS3SuIu2mVAt9wgrBMHuu5AMALrh5EICf83NTC9Y8VNqE61XUJeCDg5Zb2CiZn5AmUSinBZKaBW40AKWaEi1mmztpsWyrEcAp4V4PyGtnkwLAdqfD4z8GAGlnXIQEBU5uJzE+J5kAc5k7fZtci9BaQoigrkDXa2827BrkUy3Ox+6KuAi9KVF7BUnXyVla/qOeoczkEQ6Qe+IIlqYrBC+U4mpd2MyKgLXcXYSw1xzB3Jh7ScrStQ+hINHBgxex6LMpM/8eLUlmzTAHE90aJt64mvTJNpAVJBkzGCjRO4aArpYtWnzslsVKetNvJ78zod4H+Ebk+zDhXh8rZenq29foqUkCwC9Wwz2cxMZISeKR2Yv6T+/DwHwj0hND4wy1XBIr4UUa2+sBQPzQHoW7sCQqRRfn5S+fFOyAbTYCpRmwGTTLk4qODHM5ydCJAKCvSpyfwXs2ShYPo72V1lCQYRF88YYBmTMd5gMcIytt+KdOogDDAGCLLZGrovh4/JpfTPgDeg7+GOZ/e2YAAAAASUVORK5CYII=",
    },
    "M33": {
        "description": "3 grains horizontally",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAJCAAAAACQm7qSAAAAnklEQVR4nEWPsRHEIAwE1YGHVA08FbgNhz+kLuYzavjoayBjxqkLcaAGFO4HRoaIQ3s6Tjp4lTgZmOoH+b41ulMm1Y02qRitVDW28Z44dGKFUgfmviiWxuBA1CJHuaTdWMbSzhEpl6mcnsKzL8br3tvEUAm/qfIZHzA0uY/4WmaBBtWvITZMK+vAnN/TvwIWokCLNhm+DyVvOKfHof8BoCdscicK888AAAAASUVORK5CYII=",
    },
    "M44": {
        "description": "thorn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAA80lEQVR4nD3GPY/BABzA4V//aaWLNKigEQ0hXieiCeID3Oe4b3rDLQZN0ESQMjgdDoNINERv0PNMDwAdrwMgAGWz/H4z3Xy/GlX/b1S+K0b8bH6Wz8a37C/bip+5+bfM68p4+bMcKyCgNja/m4YKAnrPDd2eDgJGess2bYDA8LBjdxiCQOsUEJxaINDfBwT7PgiauX7yXJsaQi3nAm6uhmAnVsAqYSPU9Qkw0euIUvBDIPQLiiS7UwCm3aSkigsAFsUUzsMBwHk4UroeATheSzLyzgCcvZG0/QsAF78tg9kdgPtsINqcl7mmRp8fr1uREvH2B2H+S1Vytm0IAAAAAElFTkSuQmCC",
    },
    "S45": {
        "description": "flagellum",
        "pronunciation": "nxxw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAABZUlEQVR4nHXQP0jUcRjH8benp0haCEaBox5CWYPo5igkEU0uWoNLQy6WoYkSDQmCIuiBcNbQQRIuDaGCUNkfBB3FpQJx08jlCsHgEN8t9+d3P+/3TJ/n++L5fr88EKrePz2FHAtj36WL4aNCTeuXKGs/VQfLX9u8UQk0lB/M6OqZtpazWX1L9uPSZhmrVW/j4rCPzmOH3oXse/x+zlrUCkh/YtzRMC7oAvBSLrgVsqv6CuC5j0k5VGJNWa0H4GgMVvcgsITtOB+OAaiuhjfN44HBLj3MxeQksJ4pWuVnHcjlfhNwxwcFvK4n+XzfdmD9IN+3nfi3Kd9cPk4DNxzJ9VO6VHwj/RPo9kcdAFfUeBEXXZtcVh8C8FSfBH6eUt275Q5AQr8F9/FCs8lr3JwBeO2v2iCy7zxALAadAyT/lWAFjQBnwJy7lNazlXu5lNAxIqpx2N81UZjKOBFl6EykVX2Nv4vE/4BillPgv+HMAAAAAElFTkSuQmCC",
    },
    "R15": {
        "description": "spear, emblem of the east",
        "pronunciation": "iAb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABDElEQVR4nLXQr08CcRzG8ff3OCja+BEJBiEAwQtXZKdjo1tpZ2U7RvefcCMwNrWRCAQT221Uim4MCpBIbHfsBCfNfQy6u9M5m098hc+ezwMA5Lqbbo54+u6V24+DGbRpB2YEqueWKLk9BaABZMvejJlXzoaCKEAJkcTzm6TSqE/XFOkUGs1hZbcFYLurDJvg3NXGhfr84uRyXi+Ma/ctXX9dKBn1HoWb0ala7BOab66nRmOnHauXhjFdm/5XiVjUGcB7y4aH20Tk+tNSls96BJlOYIkVdDKhGL5jieX4RviFyODAYSACoAPsV9dvnB+t9tGh4sQTb1KMl8jbYue/96pK9cc+SZJ/LPZf8gHM/1fBnEvfbgAAAABJRU5ErkJggg==",
    },
    "O41": {
        "description": "double stairway",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAATCAAAAADZ4SBsAAAAaklEQVR4nKWSwQrAIAxDk032/7+6owfpLo6larGwXGwDvqYi4WX9pLcPpFQmh8L8Q7OhlnxKuz1BW6URPNGW+YqvW5CNLpa+lrOSm75XDcAV+GE7+X1o3UwrAebjKW0n2vhnlsQ8LaMk7QGGkhkAkstKPAAAAABJRU5ErkJggg==",
    },
    "Z92": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAPCAAAAAD1inGVAAAAFElEQVR4nGP8x4AATAyDFzDidCgA3HACA5k2uLsAAAAASUVORK5CYII=",
    },
    "S35": {
        "description": "sunshade",
        "pronunciation": "Swt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABFUlEQVR4nO2PvUrDYBiFn8QfHELFQaVWxB8CBX+CUBTrJBQ6ehEVHAptp+7xCnR06EWIOGpwEG3BPygdtLZFEUkknTJI7MfnkEKbinfgmc778B7O+wIAWtp0pXTNtBbMCsDC7vZWDID366uTZhdvHhvth8sXYG4nMfG4XwYg3hCWMR6EI4YlGnGAldprkj4l32rLsHRRTxDSRv18kcNOlgFlO0f4zdVgyDjOXuDWWj7yNBJQ17LamaD3TOIXAEjZJhzYKQAKviKfPwE5H73/Ymz9o6UAk7ryNDIEjE7jeGhT2D4gvrvleeGVYrMlT+RDN1VucuL2TuTKlRDWo2pRyqI6ow8+QbXa88M9K/tW1F+hf/wH/gG6xFrcGBFsoAAAAABJRU5ErkJggg==",
    },
    "L5": {
        "description": "centipede",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAANCAAAAADgPUOHAAAAuklEQVR4nIWRoXEEMRAE28DgmR2EQvkYBB9sCuaK4qJQAEbO4JmDOHRwcRucTq77d5WnFs22VqMVl/cXTorXj+834mySORwpIos0CWnSnFjVCtBkze5Vi8leKbEel2iFMLsPSu+hxD6z2/s6W7/ajftijngDaDxrtIC6qa4ArXXnnOOgKoS2njPQCVOzqYVwq8DiV9fb+Z2fg++QWQHYNuJpa+EeDgYFc5VxFHBlsejjn/yhoNj/x4CSPxnw4PzT+XcHAAAAAElFTkSuQmCC",
    },
    "O38": {
        "description": "corner of wall",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAAAAABXZoBIAAAAQklEQVR4nGP8z4AbMOGRY2BhYGDEIfUfv07yJVlg5pOsk+H/fwQJAxxk6yTKzlHJQSr5/////wyI6EcCjLBYxpa0AdolEDng4QUYAAAAAElFTkSuQmCC",
    },
    "Aa41": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABw0lEQVR4nHXSTUgUYRjA8f+7M5Oam8nuapqsENpUiwsJfpzaQ34cIjI8dOjgRS8G0alDBEEXLx5iLx08SHXotChi4WE1ohWkQCyoZA3ElQpbaRF1mp3ddqfD7rATO/OcHp7f+zzvBy/8F/f1RzKucWXb/DWuuGnjcvz2RqbVja8d9dH/86GLnogtnIKZHVEpeWzc2Rs7gtcSztzWfgh8zXY589WtLSBV96B80LN+YedzB2kgl2iuAQjEf6zdsGnwc1QGuLkZBBgr6pmkrbsj+P4vgBxQAUaN8edqReuj32oBGDafACSmiKQr3bVtWhaANc3rAYpJFCGDErpomBu7+YJRWlfYi5xPlntkgtPdp6n5nfikzpeG8+peKAVGWOSL4kKjJ5U/8zJMdcyLQbEeVuJZfcD/R/fP5krl1pGlFJhCYl9EpGavEEYhfWtCKpa498PAG2vvd9aooRdWtr3qt9LKxaSWkPUCPrOas8MT5exu6KD6nF1P9UkAxrSY03+S5w4HgTva7EkHBe/iWx8dmyuOCIT3L/PYvO7G3uWZ+rmPDbaK/bdwvNujeL4X3JiVvYC6pLnycUPTpS+4ck59lrHP5h/z5IcXucBxGAAAAABJRU5ErkJggg==",
    },
    "M18": {
        "description": "combination of reed and legs walking",
        "pronunciation": "ii",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA7ElEQVR4nC3OP0tCYRxH8eNPKgtyKO5ijv0Ta7oF0uJmIG5B0BZB0eQYtPYGauwlNLQWjUVEQ0U4BBo0lJEp3UC0IZPn2/C4fYYzHAAOohAMwE0cL3jB0lZ8oIf1GQOGp7s7oyUDguxd9LZiwPjU62d1zoAgOPl9zhgQujaKGcRyHxFgEJ9tdL0SizdNr+X+o/MKf+p4zX89eU3mOy2vQrqOVzZRG6j6t73m11JHrl1kX0C6fP++dyYAcpeSDOAlKefTzV7tXAaMrA5d32JAvqjTPgZsJBsXYwClbx1mKoJCpM7ulUS5KfVakv4BtcBVJa/12zAAAAAASUVORK5CYII=",
    },
    "G22": {
        "description": "hoopoe",
        "pronunciation": "Db",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAACVklEQVR4nHXRf0hTURQH8O9+1hqWw5quWSIDQXCukVBEzSKiIJShMciIGsOk6McfIWoE+UeYEoiTFKGRJjjEUCEq+6UokZUpuRDNcH+sqKU0HptNt/f2dvrDSW2+d/+599zz4ZzDvQAAwEaRldUItaRDaMnXNpaetB3UH7nG1YcFGQDAEmoEYJyiUqlANnFHkAGYaQiUbRItJDkefGbMVB/7Edwt3i2zjyKBySZvyC4XNfJK8r/omCCqETd5jhVfVUffGQ9rEiMZpV6KPs+ynYObyRMx2naacjcvjeqBtvglnTDqpq5s4ArfqULxDPVYs9QCaLQdAAzj3mLg5MAy9TYd3b4BbQUAqKv5OhTabi/Mv46Euss0wl3zp9/t6iCir0aH08M36wXRlloqL/G9GXJrgb291JmjElIFsyNpQx+K1ACQUTc8dlUpVOp84GlF4GwiMt+b7SoR+GuFPfTo1Ps761H54OJdy8ZfUl5Y7bcyA7U6GQBA07I0U78fACD5T222tw61vsJnf/jPvBSsuVzB+L4Pv51MQlA5bn1sjGU7VduCEkjSAAC/fzL9yR1VjsjLQeTusYbjsaUHp51zHFG8IT9lLtU00Xgb3EREv3r27Tx0w0dzG6avDH1bJU/IVXj44gj5XGZJTnXkUyq6Gb6eW0Rf0gGl1vSYFicsBXOUYkwLlIEyGluLNNb7THAxloKMHqqRyl1MRSKWqXecqLpsSDL5U/GABoboguzfnVSuWD/qHi4zDBOMslGGCfJ+S9LzJZailuc4juNYluU4juW9B5LSfwENv/tPYwp+DwAAAABJRU5ErkJggg==",
    },
    "O28": {
        "description": "column",
        "pronunciation": "iwn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAAlUlEQVR4nJWMsQnCQBRA330ukiCOcFVsnUBwgIClgrWVjUWwENwjE9i4QEbIDoIIapdCBJXzzBktBCsRfM2r3gPYz0F483EAQCCZRj0k4zqT7WJy0Ux91es2OS7Xz83qhB0mu2RghTAf5RECFHz5/WvlAa+0i/sQO+XOIdxauNQYkzpdlwcoa0EA+dF3xtB2qrINuEcvKYcuV7YdODwAAAAASUVORK5CYII=",
    },
    "O8": {
        "description": "combination of enclosure, flat loaf and wooden column",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABiUlEQVR4nM2QzyuDcRzH3893z56JtmlhahxIfozkQDsgt+XgSXHiosxFO+6iuOJCLhpGkliaUvsLHEysONC2i0LSkJKtPfbD8zxfB4/t2Tw5e18+P17f9+fb5wMo4mlBiz9NsPkMwfh3NEzit3jarWRE5SaFBxVKNKlMquGAzl6bvE6rOyq3ZF0/3TzfdojaGAujS05352q19nB7v/v48zDiG9DGvTY/AKBPG4evOQpQOeaSi/Cgy/MACZdhAKhosKBtxNzEQDIELhi90bEnX7lf+N3lG9NAj8gwjDX5pssAlcbEOLPTUn+0stZ231h3FoUcefwUjEHfArkDOprHh1iWk4Vcmi1jkU1RSfgQM3pIOQIgncgShrM4N15vZ275Le+dqb8rC5lY319JiqLKJE2wued9YcoTwxMOTqDjiLWxPBgKmFspRIM/lF+Bp/lz0HmtvQFg1s6AU126BI+1i0U1KcaIclyN9lGVj0H/cJfoH2PVYgIAGUBSG8/FARu8MGjjYQDAdNHwL73LhlgsQEssAAAAAElFTkSuQmCC",
    },
    "M28": {
        "description": "combination of flowering sedge and hobble",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAABb0lEQVR4nG3QP0tCURjH8e8Vg9DKGnLRIKzAxSUkCpuDcBKJpoiiJQqCSFCC3kFD9AqCphoiMGgQQRFEtH+WCAk3qdugVwoH8UbpadG8aM9yfufDeXgOD0xMMXkoRH7XQqf25cUT7eq6/rSqw7HTt4+jAcuBuNThSEScj8Bo8eGPDIa92Yu5eVA/RQebz6HlYxPAl65dap238c5LRCf2Jsn8D+rKAJKkB0kCA5zl9Jg7A+Pau31Qj4P2BRv3ol72OoC7O8DhLdfFPVZ3olGWs9vmmxvzdlYuNxJuKxAueQLp6qOqPlbTAU8pDOz4kkXAH202o36gmPTtkBKauuSE4UJhGJxLqiZSWJyxRkl5CQ1lMkOhF6XUiDktQKw2vRlR8pVKXolsTtdiAKwHgZmCEIUZILiu+/SGpm30LKEvm+1rZ2M7fP/w3bM6U3+/qad9RdNWus2lbG0prq72cVs8bhvvGlTDCLUufJWNyK+tyy96KYt4P+LiRwAAAABJRU5ErkJggg==",
    },
    "S34": {
        "description": "lifeankh, possibly representing a sandal-strap",
        "pronunciation": "anx",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAAA+UlEQVR4nI3PsWrCUBTG8f+9irkYwRYVCw6CJIvt5Ask0Ado6doXiX0NwambL9AhhQ5uXYqvIELtknZKV03wdLhBbrZ+0/mdM5xzABq3SxFZRg1sJntZv63la1I5kU2/299IYunnhxiID7kPQCSvF8BlKhFogI9fIH8H0KAoAVAo0HDk2gO8G44AtLJtCATbrAUailVwBzwEq8IujMtsxOinjKt71ELmPMlCVWa63z3uPqeck4jI3JaeMcYMUkkHxhjjqaKJk7L5DMDV/cu325/JzBa6+hm/5nP+6ROnmjt0ag4Jax4ydK3GjJVj3aOn3XmXrjtXbdrWfxi7Q7ueE7nnAAAAAElFTkSuQmCC",
    },
    "F30": {
        "description": "water-skin",
        "pronunciation": "Sd",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAbCAAAAAA1sqIBAAAA7ElEQVR4nK2SsXXDMAxEv/I8R8ZQpYouqZnAZw2gDbwFWCqVq4zhRS6FJUaFaKrwVXy8I3gHAABcgbfoANB2qOELgAR2ohoe6QBfb8cDmfUwL6Q+7okMzD9FFpY98yrjwP5NmpAMMFfVnMm4kCZgOlaEAW4ASEYwSW773gV3rXALxdvze/NdfOXfPuYIeYQOHGYWujCUrHlNqUzM8VoCS84BTIh/ylUZqpBTuEoxkL+UFwCuQ6UjJ2FCuNYNeS8daWwjQbioD3KDDCE1P+2B1NhtEJ1gbUgd6QbPe1MGcJ/ONAT4nEzQjvBI8IA/Cjlo40dBt9gAAAAASUVORK5CYII=",
    },
    "M6": {
        "description": "combination of palm branch and mouth",
        "pronunciation": "tr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAeCAAAAAA9AKCrAAAAyUlEQVR4nIXOzQoBURjG8f+ZD0nKbGZrISWlLGVrrVlauQO5F+UyuAVKSc1KspqFElOEFNMUMR0LxowS7+r8ztNzzgsA5Dq+lFIAkG3VveXxeU9rPy6K15nBvQGgAJDeTSOIwzqGyyUCz7ZCbL5AxpA3g3daGslRmCR6GycRQi/0V3qI4FQ13h1hzV8dAGrbSfT00NUjfHz6Y7e/0ABUDTUAFFKW7Zqma1spRLabmdk2lUr51NbU5PXs3/DP16QKRtPxFgvPaRo8AFGhPV1PzIfEAAAAAElFTkSuQmCC",
    },
    "S9": {
        "description": "shutitwo-featheradornment",
        "pronunciation": "Swty",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAABzklEQVR4nEXR0UtTYRjH8e95m6dyEluj4XApLUvIUisJh4aIULBlGLvpym4Eof9geWFdFYEVRHQhrJtaENGFCe4mNFDUKAjWOdmy0pFJR9xxbstNVm8XO5vP5Qee5/fwPFCuo1FZ6AF30L+/YoxtvTdfqM3PUvrtirmT+pGb6577MvxaVnA4fxn70rAWpe5T2URkBK5mv2sdECtji+GHh7J4DXy6KNneWx90kCzOQGPawur+iTTtQdYz4DQtvJJdhIPOwiMD0e+xRi5FgCH52wuu6bsl8yWawB2TY1XQlgqU9nnyDmgy5Bmg72uzDeBc4BJgd60ugwjkUgKgJ6EB58WoCVXHk1sAB94OAeqvuA84nR9EAH5nDOjzaD8BlzARwIXpFSBEfAe4uBxHgFrzGODY6lOAk1kDAd0NnwHU5ArQ3hZNI1CCcwCH9jwA8NpzEmj8FgII5+wAo8YJEJwqTgHURrYB6jZ0EDUDz01ArX/1D2jtmgTE9bNTEtj35gdArToPUEg07L5Z3Es4ADZ3Zsd7FevWjo+zDsDW6Q139BYzC9WT44oMtY6krabDd7b/alJKKeVmF4ACYLsRzuQjWYGy9vJPJaBl7cvAbhz/ARO7oLXzyvd5AAAAAElFTkSuQmCC",
    },
    "I9": {
        "description": "horned viper",
        "pronunciation": "f",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAAAtElEQVR4nIWOMQrCQBBF/4KggW0lWKb2CJaxFG0TvIE2gpsr2Bj7HCDgGQRrSwvBNrYbsFNYrb5FxGVF1t98Zni8GVSkkkqTCXyRmiSpc+nFEJckGf+hZE6SrOZeSqg1UgDbR/fu43h8t/GdbW2WBIBM6Fu9BzAMAWBx2T2do0gQGKyiLKcrGBx+WCujnLkkyXHb2prIU4QUgRlNHXrS1FV8NmrW6aEOz5bpW9pikMX3J9b8As81QHoOt78BAAAAAElFTkSuQmCC",
    },
    "D10": {
        "description": "eye of horus",
        "pronunciation": "wDAt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAeCAAAAABlfzOyAAACOUlEQVR4nH2SW0hUURSG/zPNeKHScQaknMhSpJJqyKKgixQVSBZWUpkJCvUSJlSQURS9RBA+ZUVEYSBqUaGID1H2EgjSVQucCqEwSY2MEnQyHefrYc6Z5hjO/7TXv77F2muvLUlzDwYxdc/v96fqfzml9JLiZCvc605yNL13d/yYhhlK78qQpoa/1zsUTqlMm0iQ1Nf0qy5hIBZzV15Ub3fVt6iz/tTvJN9aSe3XHGHTSzFyLrmbb0SCxZOEmRobD0v5WXmliXOipSHDqkjLL99juWfe8XRSMh6E/2zxSeq7bSbmV0cm/QAMR449mSmS5DQMl1W+EmiFjnKdHaTual0LAOPFSbZxMyDoFEhSAs8kaVGgH+CA5FmxNHezJKmGitkyMYVemcVph4HRAEC3JFWzS4piExamBX3Wcu7KtTHIF0nSAOcl1dIoqWhkaBio9/h8Pp8vK0dtQYBQS9uVVfDkYRBe3ImseH9+zPV7CSTXAPCVqMYn96V6bVN6JclbUBRFGpZtW64Z5fUkeiYAQmUzQ9bzYT5WPPUA7KwHf1zsM29hg1p4tC4e9onVo+yQ6w2UxMEG6YdCyeiF0zNjZQCFko79hCrTzF6SO50jGKBQktQZ7TsEDdOwLizM1QwnJKkCYI0dazCbSlI7HJHUBHBZjlhsVsx5+0vdKpVKWyWF7ZhNm26GGy8c1e6TYxqzZ+4DRf/CzI/wOHveIAvt2HXzO0eV+hzguOSMdc8582pt2MjWgkPSa+kvThVKMNteOskAAAAASUVORK5CYII=",
    },
    "B6": {
        "description": "woman on chair with child on lap",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAACPElEQVR4nFXSW0iTARxA8bPPeUnRORHNy1IouoFlBlZkUT5oWIJFSkYUlRmkg0gQekhDTboIiuiDIYREDSR1Xmgh9hCkEUVGmjLp4iV0W9O1dKbNff8eotDz+Hs+sKq0aZH+VEBZhRHGmOd3uaxnTcU+36uzm1zlazDa9rbHPptiXLqgAV181F8tHW6zpttzabHGa4NKMuefdM4ArmDT158aJzcspzjsEJFzAJqOodYBczABJjcl0rZnxbYF8Lvo+yZvNkKNKGO2nBO+6FDQVjSbNt5bHwoCnHaIiLkkLNElQ9H7ZpKgWkBplboKkYftToucN4w2l7+YUiHwmVzl5ci0jAV1uTaPqKOfrPch3Sl9uqYrZrHldXqbRI0E0N62Vf3O2ysysSLqsnyf3QEQ/37Av7EsYN6Vn1qnqgNZXwoAYl9/8E+ze8Q17fb55hM1vfaU3clQ4EmgYebm8Zzr9eOLCVSJLIhC18dafvl93pYRG6IE5tE2dtSEFsdkZmx0+B1Z59VpVR2FuqcHUCAgqHxn/va4iK2PFOJyT/ajBcif6OnTGWpquj3iFTFrqRaAXRUNVIp0qw+szmtherNVBVB6S+ldWbrlOLR/xIBBnRoHiFs+o19QPXPuI2FST4wUoQBRg+35NotfpWTMP87L/ndD6VzPlKVAwrOHM/QNtmQxAjDom1wuK5RYEnQokRvEiAJZiWU5dtGwwIQb1fkD0BYlHXN1NBq8UOvx+uHzDwFYFGk5+O5SVLH8z8gf3tQUP0fBAUcAAAAASUVORK5CYII=",
    },
    "F29": {
        "description": "cow's skin pierced by arrow",
        "pronunciation": "sti",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAABmUlEQVR4nHWQvUtCURjGn3O9foQWWVB4+7KGBitEi76gwSCCEEFoaIggWlpaGhzbpL8gImgwmiKigrJyaGgwGvqgsqgEa6okSEIN83ZOw73mVe59l/c874/zvM85AADA2BcTKWOM5dN+I5FmcvMuWw+fUkCFfYRbCOWhqMD5cIsOAGy9R5t6acZLTRc/lg6v7+m4CAAWnjN2VwB4a6yW7zePRRjQELj95FfGd2+A9qqaFADUjnfkfH2AbyC5ASbVVSsAoDMpa3bWD390QhCE4ds2EI8PXN3ojUsQhGCKZuUN85cNcL8xuxnO83oAcC3tF8Lv8fzxV+ZkGu4LASXhybc453mxDpnCuf+3cnIXm2d2TPnFzHoTLUPUGQ6HzAjOWlY5UoruH09XBqNJz8P0VqRoKf18JY+1wMEUQMyFHXKMXA6EUkYBlimPAYASUIWRAuls0NvUUbXzIupVR3zmOWZQR2CEMA1UXkVE9CB6dfSddfQk1FHq1NG1rWFoEH+1En5Mdl1rJBrMXvFKrRCJu4ioYfiTNZa4/AE+/IwsnXvIvwAAAABJRU5ErkJggg==",
    },
    "V29": {
        "description": "(fiber)swab(straw broom)",
        "pronunciation": "wAH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABN0lEQVR4nEXOv0sCcRjH8fcd5+Gd4BCUky0aCA26CQm2OpQOlTg5NQtuDf0JuTRqFCRIi9APCPsTWgJzFDUpvBJ/EEjZLU9D+u2zvXie4Q1gF4ciw6INgB4/H381m1/j87gO3sKrVHPhcK4qrwUvh32pmABmRfqHuE4eI3NzvWuQd1zDQyBWyL+zc3kawMOFI115SSZfpCvOBWaqLXIERyLtlKm7je0SPl33UdpuuACRt+nW1vQtwmIHn53OZA+1M5Gzv0QAjwG6oRiMQSwIYACEN6/Y3+gtGeSE/f9raPTBKKQomoYminNN0OaKrbUAay3F6eSYyVRFWXWRuqUyvgfQ/1a01yFkq+f0rFyepZfyP/dWV3vP/gUT8zRkfhIL3t77YeXh7k/RQRYg60QBqD1aANZTDX4BHIxy17AwToMAAAAASUVORK5CYII=",
    },
    "G49": {
        "description": "three ducklings in pool",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAUCAAAAADE5BDUAAABe0lEQVR4nI2SP0iUARiHn085WtxCiBuCssBFsSDakpYEG2pIEr2opcPFuaHOweOqoYbAwcCWGjQEwdBTi4L+DB0cYSL2ByMlLAQjTYxI+56G+8zLgq9neuF9+L3wvi8Alfsb55w+mACCvfV19UkIag5P6VorJQIg2dBWdQL676xVunGuZj0ojO4Iz+5snqjdVzzzOhLJ/lT96Ha+w6z5SKp9qGqSQ6XmMNyLvBx9urukjbryRe0F/bq0qB1cc/5C5uq85qbcqOY3j0ZmQjJ+ANqXzL8TgDeqJynnlMvaAjCm3gXgverRcmuXahg1J70FwIqa/SNsyAfdpgGynubtfYCMq2mfJ8qsOoUeX+whYT9QnB0GhSZ9vKVd10a4qJfPOwnwzM+d6z+AA+qVyOpSHc/fHFN1IU1DUdWX409Tx9U+4NiTb5tr3yw+hVunWFS9TRAGxHMJvRHjBDlf4UB82IAVq/8xcwZcjhtKhwWG/vqzf5DiyGAhTiqm+AWi8Uwqv5rBKQAAAABJRU5ErkJggg==",
    },
    "Y2": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAKCAAAAAD9OHM/AAAAU0lEQVR4nI2OsQ0AIQwDzesLBmANlvEUmYkxkVz7m29oQs5lTnaAkz6XtGZHyghteytGqoVMgFZkFmUCAC2eF1u3yG7On/15gXaVjKdUhuJose0D0Rg9B6BjnWkAAAAASUVORK5CYII=",
    },
    "Aa28": {
        "pronunciation": "qd",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAAiElEQVR4nIXNIQrCYBzG4Z8v+wSrIMMDCDLxLjuARg2exuIRPIPBZpBl2YILS4KKhoEY5PPb32ReeuIDrMxMoPrkBS5fXgX6XLyATlcCgBYCEI2IgaiEDHRku3GQ3hdMKuKs6CWVnrvx3KNweE8bRH4DxOPcB8F+2CBw1vr9CfVX8ErWA2BmZj/FfCsiMBHa0QAAAABJRU5ErkJggg==",
    },
    "S19": {
        "description": "sealwith necklace",
        "pronunciation": "sDAw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAcCAAAAAAlqeL+AAABOElEQVR4nHVSoVIDMRTcdhDlkHwHMwwmMxXwDXwATN0Rj+UbkK2rwFRdBeczIBgkAYPkAw65tYu4e8m1d6zIbfI2m83LTZAxPzu/AwCsPr7eMISLSohutMyy5SWHkicq+jz1UVz36+/S+mCH5PszehzAS+kUJw5DwSsaDbofuRWouRk0Y3U41S1Zapl9QwilTRrZ1xKUURKbG9jONrpodSqu3TLaBV0b0ymkVC/tDqUFTIELbDqD4vMKAHD823UtoARQmb5KvTPPUjWA2gQWGvC0EOqfmAgc+0sjAljrpSmAHYZY9PiYQ2h751RPKUAUKQH86QSb1mKBZ4gkSXVjso0AZo1wtCsm+TQWxl4vvwPmpytMhG0WXO9OOjZ7vC2AlQe0B2axz+9eqeqG/1BRg796Hw9KT36IP0kx0eaT+JRbAAAAAElFTkSuQmCC",
    },
    "A28": {
        "description": "man with hands raised on either side",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABiUlEQVR4nE3PPUibcRDH8W8ekqCitiYxIYVaKVbFlxYVEUyRtEiKQwcFseISxMmXyUEcVWzRdnRIZgXp0EURRAUHsVStDjURs6iNQ0qNeWx8eySm52BK/7fdh/sdd8ix3wzWTyKbJYBtRVgzbgdgcPd98NdCPnhF8GzLKmVnkUDFlLwEn5xrW2F0RiKB9Md4Ihsa2IP21LcHC99NDMfaCng+ZwTBsSH+lngH/n0fjfPyJQ/okq261Vhl6VL884EY7wAsi5I8/NNN2U+R5HQWAG9CIjMF2ENXsx4yVdIzL15sP0Y1/pdrvZmG6CsAMq4n7PQ/vm/M95SK18daBJWqa5yv5QY12PnCrbdFLerUZOmzVi5NKp2fLiadmlUNPmqKIeYqlYpPN0mbbCoV6jq5WaLsMg/Zx26qntwq/+SkRa5FPijB6wkCRSNiUkgcLJ+EpVIhzc4FiSuHQhZP9IjQb02htOtrlL+i0lMiBuXus393Ob21PlK87csJZ8ja3Ok2di56xx/urwBwByhMmFjNfsJbAAAAAElFTkSuQmCC",
    },
    "N3": {
        "description": "sky with sceptre",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABEUlEQVR4nL3Qv0vDUBDA8e8laRGHtltBFFycFF0cxJDFzT9ApFA3V4eCuzhLNys4iLuL4CB1EYrQyUmlUxGlRagQMohSYtNzqKYlL7Nvevd5x/14oqQdh6c7A70ltGrmVtUht3OQARA0tG3g+zCHqMrDm41mNCystbpCNLOsgmo9D8D63kZnCyBfV0UbxVHBM+1+lQAoNtRqlnsj7rP7YQPQKzcd96+9UrF/l+i4VjyV0JqKdxszg3ZgmaxWZVZMloFbezY3rml2HEzUnrxPcnrG/7MSpbzv9/Vm3lDPv7/6PJ5O8sXLAqfvq0n2L228YSnZMhsNCcX479uVObaD12SRzeD6xD8vSILlSPVxMQ5/AKtKV4BzzQtRAAAAAElFTkSuQmCC",
    },
    "R7": {
        "description": "bowl with smoke",
        "pronunciation": "snTr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAcCAAAAABNWmDGAAABFUlEQVR4nFXQvyvEcRzH8ed9EkoSGTi6cp3FTReLZDiTyKLkV1lssih/gTKYlE1uUJIcWVB2peiMUhfddjq+7izf5fh+Xwbf+34/3tP78+jVuz4vIPv9MoQ93W/a6v8n69LXiA2jdak2YMu1pMNgNwAx8swaKzHvcBtGAMY1uaJKwpKzUxztRjdwU2wyZSX2NMeFxiLYUYE+nQSvdhKO5D64KmUZZGZb9lRiwq81//xlY/WOFqpatK4vyKw+pS0wMPz4blXj3RsfL4I245jiQc9GCMtg3E+SIXRxCangV0BnSXHgWI3Sp6W4gTqNJlyQAVENIMPVB3CkuwwAS1IOYE1SuXxTfJV0ThPkWif8ZLoXvMLzPr8H3njLrKqmcQAAAABJRU5ErkJggg==",
    },
    "Z4": {
        "description": "dual stroke",
        "pronunciation": "y",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAAAAAADRMNWAAAAdklEQVR4nFXOsQnDQBBE0d+kwG5AiytQCQrsPlTC2bHgosPNGC5x8B1oZaFNFh7MMCwzMFnZrxswaNuhWYFRbwkXfQJVx5SiATQdUrRvz4ToFuCu5Qg9gGKPf0iAj9+EnBFHaNQKvPR6rll9c6qJbQEA1QmYlx9Ow05CGT34KwAAAABJRU5ErkJggg==",
    },
    "G31": {
        "description": "heron",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACJklEQVR4nG3RXUiTYRQH8P+7zVlWrjKd0bKBZitrWFZG0UoatBBtNxIRXoRWZF0ldJHuwgiKECpvgoI+oMiGpNUSFGZh2BeLCa7SbNkIXS6VtTlFt95/N22879y5O8+Pc55zOEAiim7xdblWgDTimap4f4UhJ+Zzjb7q/ylnYb1Qu7FID4SvVu7AxIjP3fY1zpoyo7lIsRwAhdg5t301ADHQOj74TAQgvN0VCkZCIkNvLLuBaFq8rb/iIwBVV8fn778DAAxHAaSJXX3aYysB/xNRNuPix09v8qW1LBsoNV+eizQoZbxpzGLl6Jn/E+XqchQyPsT6wiB544DsOZEoURV+jv6SOw8bDFgY5WTBER7M2ndxemDPQt78jc2GD1OXlmDtg2CHPpk3DHH+xDrbcG91Pmomh7YlcWaLc3hqO0q6OHDF0BgZOSu/DZatOkmnHkvP+zleUzo201KQ1EDdHJ2t1wA299z7L6QrL8nzXIx2N9UVZt/7RZKfatNlP2jtppgK8HoyMjX5acCsXaqCJeIweRnq9MY4Q5KklDMcbEQd+wDTCw9Jsl0lXX1L+BGIdKC3N/e4VlSMtkmrb9OZhdN0SZ4k91HvDF+fhBJ/U/NhY8AHDE6sUCNVXGO7ClB2itqU1cXz92OAIDA9VXHV9I98AEoH76ZQ4zueAgBFNwfWJJnG3OQhW3XAXnuQvJAAFQCoK63aYI+g2/qn2rbILaqjyvhy/wAq8uDPmgiSDgAAAABJRU5ErkJggg==",
    },
    "N28": {
        "description": "rays of sun over hill",
        "pronunciation": "xa",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAPCAAAAADSJPB9AAAA10lEQVR4nH2OoW5CQRRET5um33I9H4DDPr+4V/M+oN+A6koclQgMgvALXVdfT/LkilVLw+5ULLSENj1q7szcZKAxWYWjJEnHsJqczTsA7PmJT95bjUdeXz640AWVzTBrx2zYFIXukm2rgnGFBdVtkztF3zwzs9byUTuArhQHYC6klNKbMwBXSgfzmB1g60MuKaVU8mFtgMtxzklToM91XBiALcaae2CqE9ISfNb+e5LtlT0sJXyqY5SG67WDFMeaPNBXiRuk2l/UbXb27n/7Pzy03t/hv59fXUB0pizAtCQAAAAASUVORK5CYII=",
    },
    "D43": {
        "description": "forearm with flail",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAPCAAAAACt9eKMAAAA6UlEQVR4nIXQL0tDYRiG8WsyhAkromKQBdO+gzAEo0UxajDMJmOKRUyCgv2Af8L5BsLKG1UsFtPUoIhFhLVxkjAQzmUQFD2v7G4Pz48bngcAJp7yFsNT1dvycNZUX+OryaBpDYCyqnHWUHsJAIeaXXscZUHDV0VQ99GxGOvb5FFgTu3BlXsx5hG0HYEtUjKmTjloxNwDVGB8x6TmNKrPa5Vi2yrsyua9o5ddyFX9+I/ldpatw7qen2gonJBCWwZqBrDiYP7Ov3nXlEQ2Om/9bQAWC+Y7L6XSz/cXLjibiR3Lza9pqTsbVfAJxuqhmvbdb4sAAAAASUVORK5CYII=",
    },
    "F7": {
        "description": "ram head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAcCAAAAADDgCm6AAABpElEQVR4nIWTT0hUURjFz7wJg4gUFyYIStDCEJI2ooKK0M5MWkliYerCQTch/kcQlYgWrRooqM2EuXA2BZUSJVSbFMRcqBsFTUdQ0Y0pM5q/Fm/ezHvPN+PZ3HPu9/vuvXDv9S3lZulcGU+nz4c2fLo8WG+cZOR5FFnJkCRdGfCZE/4Q6GTvYsCQNNJ4TdLY8chqHPc7mos/wGqwoDgKUJJi+7vzwFtVYqrBE7pvFl8DRKcg4gV1QrhvqP8bAF/VDp/PQo/5VZBYMpIpBeCqG+qiw7Iz0C1JrfDdCfXQlvBBQqZphd83bFANh8kwxQPLTsJufqJQy3jmemTzz16L9JMvyY6yfxwUWaEcuwK2XQpjMGyFWzG4rua/AIvOI/dyWmX5bMKSVH1sa42rmbWEr7gpSfoED12UbwvD8j8WJElh9wuQLl3YN1xTE3POnPOOg8htufWGR7b0EqhzrySpPHkL/vewc8eDkbS9HDfBKGOlnoikZ5hjCJ6kYqQmXki6dwSjqSGVMSvVAc/TQNI4Xa9grjYtpDYOYT49I1VEYx+bnL/4P5cY1E9EvCQ0AAAAAElFTkSuQmCC",
    },
    "N30": {
        "description": "mound of earth",
        "pronunciation": "iAt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAQCAAAAABfdVLCAAAAwUlEQVR4nH2QMQ7CMBAENzVp+ACu3PkZ9Enrkp7PWKKMhJSWL1D7EzQnegvpFNoVDURO7LDN6fZGu7KBlQaKcFi7azmKc0L3j7H+piRJ6s3b/NJk0PnU4nl/A9gdD5iul0etThjDHGFDpFSqPVO36LFdoq9QZu2ZgjNaUoBJunRFKxRgVPK1Z1ejgI59tqVYp4CYvjN4jFo86SevI3yIEFI5blHASCUFdIHl/2RxZHBsiKkFpk2sBaYWTdpvJ816fQCeD1qtzOXA8QAAAABJRU5ErkJggg==",
    },
    "L2": {
        "description": "bee",
        "pronunciation": "bit",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAACfUlEQVR4nHWSbSyVcRiHryePHMVxhtDhhDOhpR1LTUiT6lPNNzmFspqtFsuq1VrL6iRt1iqhpZiUsVVLjalWM/PajKUyB/NWTV47XtLycnj6EM7jQ/e3365d2+9//29YOaogT/47PuWSUWGJ4kqzxKnKVbLkVXLoUOwd0lI7Y2FyVzgTsm9IGFxM2p3be+SqV99F1r6IBMA3raNtYkTuxsw/xX4DgHBFP5djezlJBpVT6eDavBf8crtj7V1qMwHQaADY8z0IgtsDiehqWY9d1XMRvJLskvIBOG90g8PvrI/03/fAOrNxM7Db6JJcCUDNbSDmzenhywKEmoIAcXpWMaZ0NIGHugYwh/plpktsy0ltBlDVHVf1+gIhvV7Anb4wwKH9xmLVozWeFfHA/gFriBtIAOyLGtRL62tOySoAsvME9KMGBXBoTLP8ztie+Hp3eJyOd9NVgIgfpyy/UD6kVwXAwoJj0Yc8rdZefa3y4SIVYeJC5S9nkKzOhZpLbaWRNcr4Wfn6C6Q0XCuGJqcn7m7dUWgKXwYiQEmCz1lDYb55Jjp0nW6TUaNrnZe5BzpNI/+K+EvSk4yyjsJg2VVEdQ4MqgBwkbrcsA7P77+5dpn6GaXSZ95K0Sbw3u/Z9u5HWOmbXjstUec6SfNeasgqmhy7tpAVXRcIus+vhMWr+519YrSaLUkHFxR2l3SBNjHwKVZ9UtbMv+t6a0X9VCq62rmfhgup7nFf1BaaWJ3X8LK/zRMUbhXzbcZvb4cjl+H6KsPHjNHxKADCxhPFiDYpBRFIDhDw3eGiXa1c1QhA3a0HDmVzf74iALkb5zFPi2bRLBwzAWC1a3oqvqP4z1+Z/+ONg4KkywAAAABJRU5ErkJggg==",
    },
    "C10": {
        "description": "goddess with feather",
        "pronunciation": "mAat",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABe0lEQVR4nD3OO0hbcRjG4d/5GxUbhyqJYhNtB9F6AfECLhYKWpS6BASXbCIdVISCIIKDiJs4BDKIDooX1EGkRQfBlrZIhw41LpZ4iVqNN0SM8ZgY4/kc4sm3Pby8Hy+YNxP+bbgspgorh9JLrpTJxiO9+/MfzaTH3xxtIZlyXbAFZtdakp2xkozwGEYg+TZ12Djbvdv/3p6gOyoTrnOReQDSp0VE7kMyAsD7kP7w76q/U3QAOqUn1+n7ULgjAFQcPPRVrf5kKkHqfBL4cuf2PhOHO9q1t7kkzyODv26Cy3nFYXOzwx5bsTk0RZYVwMbjufbConp9fu9LtEaJKyynXEa+yVyKNh8sr5G1UrVw2zHYXC/2aKzUmNjineFSo4Hqi68ZY+Em1MllkzGW88N+EXkdj6OOF1vz/g6k4qfIeAQ+3n6C1sECAtcNgHV9NrHk/8YrFPphLEFt+wRF/hsnAJmWsiK0t5O1+jhgddanLbWxL3pERETieui++gkHGJqOCY/36gAAAABJRU5ErkJggg==",
    },
    "U21": {
        "description": "adze-on-block",
        "pronunciation": "stp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAWCAAAAACN2WHiAAAAtElEQVR4nI2RMW7DMBAER/6AP+HySv8n/IQ61fyU+/Rq0zOtSsJwMSlowA5CUdnmQNxguXcHgE9t9DUB+Ov1V6dnd5qm7x2fBuXd7ptUgKwxgjJAbK4jqNVq3bfaSquz3nZscssDhJq60MOAaD9GtX70AzUBkNRbJ9f9HSKpfubBKgCiqFbH3Hluzl9lzEUqpai1dKd4cdmiuh7cNbKqaxpjXJaqzgdUG/aQur52OPL6D8SiPwTLhCwQ8R1zAAAAAElFTkSuQmCC",
    },
    "F33": {
        "description": "tail",
        "pronunciation": "sd",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAWCAAAAACN2WHiAAAA70lEQVR4nIXQMUtCARiF4VMSkT/AsKAwXAyatGgIGip0cGtws3BwCSQo4hL0A6ItqE0Hob9QQwV3TApqERqCaBEuIRi1BNLb4Pzd78zPcHj1erAwLm+D59aWi/pAWHHQZhOgNuew6vkn9BozDpt6Atjwni39AreeWrn7g7A84bDUA/CznnPYDgDfQXzcWhcAKrOxLBwphheJaVvNR8BjH6Btq8w7tKRrIFq0WQPaUvISuLLVIXRKUmYAHVsdAUVJ+/BxYqr0C7zVpTUgMFXyFOjdLO8Ce5MmK2wHwD3AsX1Myp6Nyn6NxSnli6uFtKJ/XOiMWPKlcd0AAAAASUVORK5CYII=",
    },
    "Aa30": {
        "pronunciation": "Xkr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAA3ElEQVR4nGXNsUsCYRiA8cfX+kxxcLqpI6Q0UAjPLXC9wSJod2wIwj9CXdqC6l+I9qDGWlsOHOK2FtHQ6bsDP1EJfBsce7bf9ABd1wXwIo08oLN6WXUQvNxtzkNM4/37o2E4tldc26ocmpgvcyStWYqdtSScJiTTUALrcDaQbLpkmWaF+YbNHMEBDmGbYADz33G5SLEcy1t9H7/+yrneXd7rGdUfVR1XxN97aD/mfXpJjVrS23GFi4OTgqM5UtVRUxal6GZYWjBYh7TXfSZPwPMko8PP393TIKPb3x8IhVANN/+95QAAAABJRU5ErkJggg==",
    },
    "N12": {
        "description": "crescent moon",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAANCAAAAADgPUOHAAABBklEQVR4nH2OoU7EQBRF71oUiE1WkTTYivkDcGsqUJVjRlbwB03G12BWrlhZRdZgKgZfXUcmwVSQDCT9gIOgwO4SOOrlvZP7rnTIygUACG51dFgczPbm9kJPetGlrvX2EHb6TdZOJGeNkSRjrEtMbXZqeThdZi34o43pCaUk4/wYY4yjd0ZSGejNj5VDK2XNHogxxhiBfZNJLeRf1tmAkzzQWbMuyrJYG9sBXnIMZ/PHRGM7GIeJ4HJJyl1gGkbobEP6zNsRWhhLSXXPTF9LKhO0HTtJywoAP0cX1SalTVXMdTwA1VL1APjvnqfkHhhqQdyWf0mSZLcRFo/P96/v/2k6X95dfQDst6MnW7HKoAAAAABJRU5ErkJggg==",
    },
    "F32": {
        "description": "animal's belly",
        "pronunciation": "X",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAJCAAAAAB7rAGRAAAAcUlEQVR4nI2QuQ2AMAxFH6OkZYywRdqMwQphDNMxghmBkpYRUkJnikARIaT8xof0DxsAkrlkyefEDzoA9e+4DqUGR1+6nWMuKzUTABY7VUQkWw1xXYh4pq1Q4yM715bhQnPF1fEbzKm1qjVma7605W83pU5lP8zOfaMAAAAASUVORK5CYII=",
    },
    "M40": {
        "description": "bundle of reeds",
        "pronunciation": "iz",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAApElEQVR4nI2OsQpBYRiGn/87J5IMdrORlEExuAKj3eoaXIEFk4lsJlYXwCpiMkkdSc4pKXSK/zMcO8/ybM/7AlNVfQuYsL8RAbk3ZwhgiCNE/GEL4OZK2ZcxsPBO+rQqmWX7sd5C47Y7pFpKYjg/rwKVQr4TpC3SOO7D4gCp+OWUH8e91OpXQLojz4nS44COCjjfnZiJbH79UkJcsMleFWCiqvoBbLo5mAY6XDoAAAAASUVORK5CYII=",
    },
    "U22": {
        "description": "clapper-(of-bell)tool/instrumentforked-staff, etc.",
        "pronunciation": "mnx",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAYCAAAAADrWUO2AAAAj0lEQVR4nI2MvQ2DMBhEnz5lB0agQZE7L+A2QhSZJoPQU9CYMRBiAAp6Cko2yKVwYiVUedWd7geg6KSuINEqRrVJB80wK4CBZ4MNDwaOCSYcQFh3gH0NGL4cAcbSYxdHD9DjACmdSlhF5mo1Q5IDN3tP0uhQ5jDORKnJRo0iwE/tT/N5e+Tkfoqqr81zAXgBZvI5HtQYB7sAAAAASUVORK5CYII=",
    },
    "D7": {
        "description": "eye with painted lower lid",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAANCAAAAADkyJO6AAABY0lEQVR4nF2QTyjkARzFP7+ZNWPXYJhFIgZJmUgZsgfJUaQ4OSiROCgpFwflosSB3IZJ0a7dKXFdh11/Gtsq5OCizAgpylz2sP7MGM9lfsjn8q33fe8dHpgU12zIZMPrLbe+fDASN7OxNc+bbqpPwZSr73vhd6asUwexJCKB3Go30SPXJ+XA0lbQCL325d9ppcChUBowqVWAUZ8kyec2PaXSAjjkAeCb2gCob5q/la7XfgYAKqRBIFOFAExryEz3RyVJQK3UDfBZEwBlWgegrmNbks79y/4PTs8OlLldB0TCIzun9n/DpOc5XX3qBA5/7QZvgBXp5k7S1FDPsd4SuxyvAEh1WYzm6t9/8OW28pYfUt8taSWLlQBOY8ZuM+7/ro/F4xZrMGoFFM/6Gq3qsmkACNs/XjQYc4WxIk+ioPcsCYxk+2w2AIH/KfOb5uLJGailXbJ9cQCETowH/76Fx4gS4WeRCaBhe/GDSAAAAABJRU5ErkJggg==",
    },
    "G10": {
        "description": "falcon in sokar barque",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACpklEQVR4nF2SW0jTARjFzy46b3kLbEWKDwaJWqgYahKIkKEklmlpeCUxAzPCLCXswQwU0yJYJVakzLCWecHMy1Ax07TwAulmpnnZTJ1zLs39ddvXw7zMnbfv/Djn4eMAKetNEY4AALj682GiSzF5ahJfD+QCgcMLLVYmOJOaFa3tzFwhK1BanrBRZoKdrqpoSb7+kZIr5i05OStBe3HnbBMjKxsLYK5xpEeBqsY99ezQjlCzdQ977oRYtxgG3OCf24OLnHWs5QYLFqOB0BNYKLrnZ8x9B4g089qTQ67wmnEHuEKFtVF6oXeTZsfXAGBxI4YFbfpquf0u5vmwSDnFYpMef4rTjwHq3LP+u/G61M9ERAEzgcBpRmINcDVdbgDYAID4EY1+uHYhgS4CvNrBzhS3A29IAJuD1dHmAHhJk8TUT4R/SwPwMuvQdxqcolm/YKmQKXMG2yWTC1rVR1d6AJBlyEuw6vJBKbIfjTBPLbFlTwtswYuVnXGP9QZG7Ry8u/frzBItInqsfvdHZgDI1Ut8OYrGF61ABS2pteJECvFQKJJ9dEueAOKZYiB34s7czeK1mrsyIXjd73qo8UiDWvUKQNaKOwBRW7iM6FMblQoqf1DvFV4BVb8mAPlqALCpa+CHSYmIiMYeOnLzBjXNh4MBVC2yACBEdR5OSXU1tW+zvRxCBpeP58iDwQU4AgIAsejWSMRmG4DpaUFcX9yQpH8AAN5vvbiw/rKh+8sJVZWzweMCv5SGVUWWquUAgEmtrmjGZHP7RF8td44HLcbIzBGI2vQ02sg4dsph0+iQ3/Hoyc+MqC2zPGjIKHz/b/vM9FPObdpWwfN2o7Qd7/EQvwfMM9oyOyR9F0QAABaAU5XKLr05/mm363icNHHYbnsMmUqXbSD/AdCRQ8O6mxhoAAAAAElFTkSuQmCC",
    },
    "S12": {
        "description": "collar of beads",
        "pronunciation": "nbw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAATCAAAAADZ4SBsAAAAzUlEQVR4nIXRwY0CMQxG4QeVuZKITpBcwzTAaURPnKPcXcDjMGEX2FmwEilxPv2JFICmWlVzPi1LtQFHaBc+1qUxs8p1n6zWzFM7zWVPLTa6Cs0wIe3xjqJvJ2HDogKIdxjdDCCKEhO3vtpPD3Ta7gKQFGOyqznUynOOUkd6nSxEJtMcnlVLPTtyxglPrA8sdI6S0XcYUMsvW+rR/cOAW1KSt6fWgxUvlfm6r332XgUeic8IIMD15W07JavYv7Mu68+n/Mt0PSAcvqRxuAO80cv3XPKjsgAAAABJRU5ErkJggg==",
    },
    "X5": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAAQUlEQVR4nL2PuRGAQAzE5Ov0mqCI7ZkRwRHbRCjW7EPCF/R/r8LlaG002HGrgmaojRYIVL+edZQ+7Y2ZP6xzZGA/JYM75cUelkUAAAAASUVORK5CYII=",
    },
    "G21": {
        "description": "guineafowl",
        "pronunciation": "nH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAACBklEQVR4nHXRXUiTYRQH8P/evdvSrTabNKWPZR+QbMpMzRsddaOyGQQlC4PuxIuKIjDQ2oKKKQgKRRR0kdCXJcM+GOjVUtsykiVkK6I1ayq+LkuGG9ucni7eanu39Vw9hx//wznPAwAS16XCoAm5jzEU8NB1eQ5Rdd/7SjdP2LhjTDaO0GKjTtK3w/W2IBsp/DM61mDGqVl1lrG2QGKv3n4Ykv8MhDqqwbmF7LYMAEaLJEh2RpwrKA9SJarfU9emHNi5TuVA+Q26n7ErA+xrJ7JAafBdqH15ICMnvhuzPX1TuTzjnWjuX7oiHKs0YEXrt+KpZyyA1olRYzpqWljIvWdNaxoA2PIwdDJzJs903rATAKBwfdiVgQVhc/N8EX8dnjMKkXW82Oh2yAAAW/v9dULV0SGDv5N/I2nP1DYByrqcOB7t4Atp73ONQM2harT9svJrbnY+Fnyg9t0g0LT8RAUA2DPtkKbrUACA8dXrWgCA3mtNx8FZRlUMC32vVwNAqd8kSuGjaPdk4rLhNq0uXGusEKEtfDSlD1qAVUkwyNzSmmtmxn6sHNmQSg4Q1/MxuU4WoOgOXW36EqF/pvT45BgP2a0KACW+SNl5GvprO+2JUWXJ508KvjzoXeI4vQjYfjqfUFUhTrrU+yMjnIh1D6xBu5toEsBFIiKKx+JEsTgR0YruT7vfMlXAp6HWR7AAAAAASUVORK5CYII=",
    },
    "T17": {
        "description": "chariot",
        "pronunciation": "wrrt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAZCAAAAAB4egMKAAABv0lEQVR4nIWRS0gUYBRGzwyoYSjlQkUCC8qVBUWiYA8iBkIiImohVFQkFC0kelAUpVEgQbsiF9FEkFpNhUXtLDcZBRHiIkgMGUaUirDHWA2Tp8WMMTM69a0u3z3c+/3/hdkq7XXqQNEcjWxVqK93lfwPW6bqtwuBLDeuujbTOe/3DXf1eijTXBMbitqf6dR8spTj7zV87WbX2eq/fsiurAWFIxZD0pSu1AdoDELwRyQnXpPJ1Q2qq9YNxk2U8bavgZC39lZlc0dUY23ehuUPPMPOYXe/jKk9tVncO7Wcfi8C7b8p3KifKWif1oHqDGxMreSYYeCUwD5fASWP1XPlM1SdahWVCbfBaQEWpFvdaneqDHxRHYAOn8BJs/LM69boitRLRy9bk9gBH2xm6nnOR6A+LIOnzl8sETfzzNYl3snFOKGOTNhHndRqbNyOiE2zMFgU13iAldZPp88wuXAODA5rD0dNakLVr3NjHNL1P9WDLap+zIOxSdVWOlNb9+fBaFEdepMOdz+YBwuPA486E/nGzKh4xBfQ6+T2xgnb8nNFo1ayx6tbBv1V8Y95BVEv3VNNbs0XDYClN8ZUh5vhDyeCGZimaMkMAAAAAElFTkSuQmCC",
    },
    "F18": {
        "description": "tusk",
        "pronunciation": "bH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAAgUlEQVR4nI3OMQrCQBCF4T82dmKRM+QEFjmCBHth2xxIUgqpEhD7LSzsche7gaSa7oFN7HTXx5QfP8Nd0kB2kqTuDxZN2mXUBpYSTrnaVc5FVuVcp8goC0lYQGyeR8bA/Ej3ovxMHSY3d7dvp9VpCqn/vQCg6g9bbr/dp7FvX0rtDUm1YyOJ/7jMAAAAAElFTkSuQmCC",
    },
    "Q3": {
        "description": "stool",
        "pronunciation": "p",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAPCAAAAAD1inGVAAAAH0lEQVR4nGP8z4AATEhsBhYGBkYo8z+qzIBwGHE6FACFpAMdt5sHMQAAAABJRU5ErkJggg==",
    },
    "F52": {
        "description": "excrement",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAUCAAAAAB3rDjOAAAA2UlEQVR4nE2OLUuDYQBFD88mYzAGW1sQ15yo0aLdZrAsaBoomgYuWAevv8Jg8QM1icWi/gLDMDiZLwgKIljEpAPhGN7HsdvOvZfL5bFTYUz5Wivfux4zVG/2pkd8+qHqwXrkSsdML7uLANSPPlU912LsdK+0x8Zg7X+k7E8BmkIAmLjlbAilrxhvmgCzflcBWPYEYFUvAjDlfVZb0MkAOzxnfLfENrDvStwppP0Ajr4Pk5kAOaqRa4cESNmK3KQP8GYCQFvnAIrvPqXp4FWPcwA0Ln9VH+ZL/AHfeV1UCzU/iwAAAABJRU5ErkJggg==",
    },
    "E22": {
        "description": "lion",
        "pronunciation": "mAi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAVCAAAAAAPuMNxAAABnUlEQVR4nH3RT2zLcRjH8XfNYi7TRBocCGkddthR4t9FMupgl4kDS8honBwwEkQ6CSIxDgvHJTsxkk4vgmQLE0dCIiFB4tCGLWPV1WR09O2yX/vroX2On7zyPPl+vgCsGFZHNrfQfBJldfZBe3O1zXdHTqlHm6on2scZuzfa2RitTauvEt/cjmON2d2CpSHAvfR7c10jpuWVwCGTnFYrVmd8fYgtaDf0aZy8k4uq5jLZexPq+VVVlnru684FjXHCEWiJRCKtwDLoylmKBSzCPtXHYKZ2I24cmHYwdDeZy/uGmLtD2TEjUNSeuof8lknDQYcXoKimwmnR+87x6GGw8OCopphWB+qZTjFv+UP++5/KYkHVdMl+675mVjX6UbXQe7z3VtAdWW/XVFR9X/mqqeimKMDPJbY/6USNpfQfn/VKEPzQyzPqOZ7aVe1OvcQX3REkBW2LzulFrjm+lG1I6ydOqrtqBf2CxFuHWf3M0Y5WYI/qYV5odf8dHQQyupUt6lVgwFL2wHLGdGYnAGtu/J0faofrWumh7exLp/4DWVcbuelEmoAAAAAASUVORK5CYII=",
    },
    "N39": {
        "description": "pool with water",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAKCAAAAAD9OHM/AAAAQklEQVR4nJWQsQ0AIAzD3Eo8xgX8ydKVhccYysABKZG8RUkUSyrykgsHmywBDmyNA4MQfGyTWfFsXWMJcJootdq9F9mPKeNIrm9bAAAAAElFTkSuQmCC",
    },
    "N41": {
        "description": "well with ripple of water",
        "pronunciation": "id",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAAAAABXO2kQAAAAdklEQVR4nLWNsQnDMBAAT17GI4RM8BtojXRuPEUm8BwpVQV7A08R8AKXQgRbSZPGBwfPPc8nSTRIxy8dBOFBQJ2/RPU179Y2emF31PT/3/PbQjQhWJgsTStOZB0OadAMsbl9zuucIO496xPg2rPeHnWdi5WSAd4LbVn6Cql83AAAAABJRU5ErkJggg==",
    },
    "T5": {
        "description": "combination of mace with round head and cobra",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAABgUlEQVR4nH3PWyiDYRgH8P/72T5CszZyKEZbWpbC3FAobhRy40rKaaKUlENIyoXClcMdN0K5UCRFUuTCKYm5cShqMjnEiI35vu1xgWza67l56/31fw6AT0U/r4UhcEUtEw2IAUnsd9b2ucp9v4IiNGoFAOgdk9DsWQUfa5Xd3m4AyKB8oOPtt6nQ2bTVYLNkAmCQAdknJVTFx6RM6NoAuNwl0Bbce37R2HV89UjnDAiflex2T4//giaiUQAwT9PDUKy/pRPlAqI+Idu5m6LTJxrUX/8KALlAXEOWUSVJYvKUKEDpPhje/86NEL3LROvlZS87pVXFOfVnEjUaAAagZvznXpJE2FaPHGmRRaeNVgYgolgFgXnAhMGzMRZiTjKvtDfn3NT5b/UwCyBYW31917v02uJvj/Nfb97tk2V3TkCg2qhQGt7/XPqTAypP9hw8C/ugy8A9gVAZFzwD4PzHDrnGPrjzIG4v8HNezz/ziGvEGM+cm6kZPHONawu5PRdnTJ+zkYMPqjUxXgAAAABJRU5ErkJggg==",
    },
    "A10": {
        "description": "seated man holding oar",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACmElEQVR4nFXSW0jTYRjH8e/+/tWpYabmIa3WweigoNIBy8hIL7pIMyhBAlGiKAgNDQqCSDTIsigqioroQEXDuqiwDK2wwkhNstlBJSVt5szMOd3m9n+6UHN7Lt/P++N9+PGijzMsjMVrltW4HVIbDsDixu6u01664pujvOBI7y0dgKHnck+lFxtl/OwcDkkGgKE3u+mMpyb03z9h6S0MbKwDFMWp6bzCmXrzvAzr5lF7LKBq4mP34rl+ldY/didaK6CgV733rnIaN2Ncezy0DCCmr6Da620yR2wp6hO5pwJK/NDBhS5PjbE+9NO7cq/mnJ8NWAbFXj6N6v7XIidCILTMbZwLFRaRrvLoSV1+wy7VqwMBuC55oCsSzSkN24OBiNJBEWmfOXH1uTydBbukL88k8uTAqvRXIvKpVp6pAHvHRVIg017PsgsD4v4xIGK9tjS4YXAjEPxRRI7CpqGn4JfcrIlo/fkBkCWlQJqlqlDrUQEFnM0b0ne2f63rBl5KfJCNJSF3Td0G2DRU411bQIs5CcokclGTKB7nfvtunwJcX6IiwAdbXxeehUdVBLGu4PP43RwAlzLcj2fa/ZcO64Pd/HSOQWC9HUFF001VPvw+q27PjksGfpiZk9ojgKpbMyPB0AWArSkrUb2vGd1j4e3pSZ0AhNY4xvMm47nyyxcuipga3fIuQLniUmYnn+tNm2QHIf7EvYAwR3VHoi422c1K2WpqmOR1v7STFZ1yp2i9nmPin/rboQo6tKndhiOKzaXNplHAF3dMKOqwNdKnbULDLxjeHm4eAUDxB1/aCHts7iuY4HK5+f9Pz//2Xbe+ZoE6dD31zSMA/5JiLPnx6kSP8+Nao+uzxyD6QwnAthYRsdllelq3wD/bYy6TFvlcEwAAAABJRU5ErkJggg==",
    },
    "D53": {
        "description": "phallus with emission",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAOCAAAAABmqTEpAAABA0lEQVR4nHXQsUoDQRDG8f8FRcRwFpLmbCxstxFEq7iQB7AwlSSChdU2qexTWyl5BMt0FyRFZNcHSBF9BEGCdkIOIcVncVFOudtuht83y0wEkLTiNsDw8/GN0hcB8cWZXZWBch4B51c2ALbQDv9wBKe9+ID6Iq+TVtz+DYQCrc98x0uS9878pI0LXpKkzF9uA3FPU+i8TF/z9h8NeClzRGbQvLkG2Olnh8ARmyNgzGxJNv8Ac2efm5iJiuGk61a/SUpdIx/oOH5Q+alcKqUOIJHH6KucAVI/31g1FuuVbMQSBzxRY2teycbsNQZhnxMwuq1kBHnJS24NNqrZZNeCfR/efwNItnpB+MPc+AAAAABJRU5ErkJggg==",
    },
    "K4": {
        "description": "elephant-snout fish",
        "pronunciation": "XA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAATCAAAAADD3cDiAAABSklEQVR4nI3Rv0sCcRzG8UcxGhpy6AdR9AMiiEDhstqEsFr6C6QgaL4igiKQsiGICFoicHDprzgaLYIghNaGrNGEQCIl7ce74brrTI2e5fh878XD53sn2QmMhsOhyRsAsMJqEJ/9GIwsB6r+z3lpRTqWlMxkGnF1pqAMlPKAIekMuNhtrZez12RM7VGRkQZIG9KSBbm533KdiilJWUzJ1mkjIKVeOaiBwVWe2iVJMbL2kbFvVwcBL81eAfD+Vi469Ls7bZq19o6fLDgfRNLIOYC1WHez4QcgSxUrYbjNl+Cd3fS73UX3dXAb7hvhMc8qTtuWd/AmCQz1xp69PP7hTLW2zb7x1IYXRzcbUTddR+4qCUMdLTuU6jd20l2AkJEACEvk+5pKyRd9nJZ6Bk5hLcLJH1JSW1CSNHFLofYPN49/5uW/VBo/zMX1BRkR7+fvc1sKAAAAAElFTkSuQmCC",
    },
    "S31": {
        "description": "combination of folded cloth and sickle",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABoUlEQVR4nGNggAGOFf9fBTAwMDAw8Bob6zGgAf72n/9/3wliYGBgcPj//w26tMPP34F9/5+wMTAweGxa9xwqygKT5mObuv6UrQkTAwMD24WfVlBRJpj0f4aVDE9PQ5hsbAzo0gwMTAwMjOhWMqELoIpilWbe/RmP9H/RQ5x5jKguRwKfvGN6cs0f33p47j026XNHpyrvSC//9eH5F2yGfwlLPfqlUEAxSoQXq9N+rfu6gv3js+c/WrF77M96GU0G9vLXu7HZzcDAIPr9A0N0QPx77Lq5oq4+0Jq7agP2YJGeebfK+uSpNvRgYWH4x8Cg3LD5VXTo+mlR95Fk3P9bMDAIagqbbH74LE999scSqHoGBgYGBhEZIwYzDm4p57BT3wp3W218bX2FgYGBgYHR3eQnM7O0gTkzAwPDsqc/Xs3VcLOWXtoHNZOxoESagWH/gg8mtZWnj7tbqPGr7b608xrMSkZ2PiVnDZv3f4WVrn/hFjx6b9/De78QLmJkYGBgYNPg+OHbEnuW/fvtf9iDicHrvy0WUbi/mbGGEPZApY80ALolg+RmuIFtAAAAAElFTkSuQmCC",
    },
    "K6": {
        "description": "fish scale",
        "pronunciation": "nSmt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAbCAAAAABZtPAEAAABJUlEQVR4nF3Rv0tCURjG8aergdVQQRAaOEQhbi0SDdlPW2qIoILG1pbaKoIKmpqCoP4JxyCIoHAxAgcbIsXFC10icIpKIvg2nHuvx97p4QPnPe95j2RqBWrZQbXXDHB3uDj0H+tAPW3jJERVAm/Awi0upcjmG954aP2QkaSJBsUQ5/kyIQc7jo8/VPx0y2efSXsQDw49sy5JSkI+7LRscqxCw574UVKPC0vWdGdEna5qQlMFCxtyTsoJHdsmR3oFntrWsItGt4FpG8tIStd4sGyWD0mK1fFaeMGVI6k5/BIvdQQ4onsTstDt2xrNYKUepyZk4LrTxxTfJtzAatCoF5KSVICD1p0eC5KK8J5o4Rzu2H4VjuxPzgHARtuDUy78nmcjkqQ/VxmJSxqt2VwAAAAASUVORK5CYII=",
    },
    "E25": {
        "description": "hippopotamus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAWCAAAAACJLLHfAAAB3ElEQVR4nH3Of2jMcRzH8ef3e7drLp2fk7UfSSxl+QN/+GNhEhtSp/lnmVaL+OPIj1YuWfwhLqPLUohLnOUPZyT+sVwua9kWWlh+1P1hrbSWa5Tv/fi+/HEzd9zu9dfr8+7Rq49BfsrKRXrbBQCr/Wk8NXU2csjqhankpq1JF9VVAHx9fWMi9g+rbS45nm1j9+yfNmAv3wPXuoZzhtZdkUZePo9G5+R9oW5oWKHNpX+eTulTOwWz/6NeeKZ6p24VRgAxdWZLvd6WzMyIaCNQFtR3s4gC6yEQ1ruiiCWahAbJF7xbjD2WnGSIPIr/KP01M3ODSZp4I7P9UB2F0zX/q8P1pFh0JrNiVBYQ0lL6tD6PDIYM7kuXaPmQcDU11gHSZ2OuRt25bKeijGtvOQmdz17WSJqY9V4OWPvXSe6bcmF6+AbzdzREBnnDvKMunj0ZGDg0vQa7emnFED1emsNAyx1Nj5x0mMKwalqBDb1dR/giVXBWkhdUMAu6+xdTe0JjAUlD4JQkS5IyMX+H77Yilvy+ZCCsJuCcJE1WQr+k4HVJOgbQoYRsSEvaDdB2dfxyJWyXpFUhSToFrJSkg3RL0hYAHB4TKkYkHSAs6ZUXWNZnx/Y5XIGeBxernL8BJ0n7SoFviwsAAAAASUVORK5CYII=",
    },
    "B3": {
        "description": "woman giving birth",
        "pronunciation": "msi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAAB8ElEQVR4nFWSXUhTARzFf/e6WRppMJdOIgUDS0HLCJJi5QoMrNFLaa+LmOtBrIdEKjKChGqQllDR+ngJapiFND8iofkQgiVronuo1NmkQtHEeW1s99+DrtF5/HE4Bw4HADC+FtHlfLZKSqdioWeTYfHkpVBRRMK3d1X0S1tmEikd2ovRJXd7eW2sMcm2hzw/jjVLaGTH1d5kYtlUa2WGocnS4y3/lmSGR/HOJxupmCjeEKz919ExIg4cESMdXli1TrvvaVZy8l/tHSgwr/lKPsUeVPJYwmO+2JlVZO4Sfwa0aPYmkWZUQDl7fH7PPggvB3TBbgGwyxfr8NtMHNFLz0V0G6CM/arh0J+t1M0+jMX9cgMwikdl/RsHWbt90lAy7gecszbgykAa6wKBzVzXVZTq7wPA0LYSskqHF1hUVA7YXgJMJ/JJW5lM5FYlyH0vZoCysI3quSNU6SsGlzUShayic3xmUzrKRaUX+emk+HL/XN9JcIozTeLlBvvMxy1e/eatod+QIF2faP9q6Ka+MXh6cW2MbGPAv2Sg/prat19VAI7SYmmcgqcr8p8+FKLUaAnyWgu1d/fd5uXw3RkJzq/G+Drrog0LLnOwAJLbi2n0zgVfV6kpB0AB4GD3eM/gzoITvS4tdY7Durg0aTMB8BeOgNY01PoU1gAAAABJRU5ErkJggg==",
    },
    "T24": {
        "description": "fishingnet",
        "pronunciation": "iH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAZCAAAAADoaXrFAAABjUlEQVR4nG3Rz0uUURSH8WemIcxGc5JBdCe2qCgwgjYiNUFhQYj2C1wELWogXPUPGOpKF0IQKBQMWTtDGLBN0CKCNmlG4qKipoWE1ASmM4xT8LR4e2Pyne/q3vu55xy4F4Ic+L6aojZ7j6Yg8XcTa02VaixD+435129D7Sc+N7jPGGz3nt48fBU4xUSoFbjwq6Z4bWF3x9nbAAzdTV5UdcUwpUOcUADGVF3PH+SjLj3J5+cKwWUAEkX1FTR+c/140Pna5tet0TagaSDzQs8ARSfYkQFV7wN93tuJ7Pmkfm4AfBhBYH7DFaDXrnraXbYfGjdKUeocV38DLf6I6rKqQJPFCMYLACTrTQSamzu45XNI16kFmHrvIjBja4TSwSMPQ6fTEd3fl73UM+kHYNjZtnq9H+sqUNYj/53HAM49BZZuLnJ+gdyDShyoXsm8y20DMBv8+FT28pd/3+9PfQbATGFkTF2zJqPt163GALqXyU7z8uSdhEB1sKthFwBb4fyhyqN0uE62HMu9UcvjfwAlBdPFt8QFawAAAABJRU5ErkJggg==",
    },
    "Aa3": {
        "description": "pustule with liquid issuing from it",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAUCAAAAABZ6RlcAAABOklEQVR4nF3QMUuCURTG8b9vKoSgBCk0JIW1hJG0BVG4vhBIRbQ0BA1N2dR6a2gu2gp06AMY2BJCROAUgRApFDqFBbmISxDS06DmtWe5nPu7h3s4HnqJRGY2oVDkuXfj6Z7B8PbyIkChkfkJPH72LTR+MLnYuAgMMbECUDm6aXWbRi/VlFwA15QkSdroWlqS8t3CNU3hqtypTqW2ZP6mikmUZXDApNE8VmpTKAw4+Hfg/Al8AxgG8G9Jb2CqdbvVlQzMXknHEM9bHwI5lYJOahre4atFyrbVSgK+pQcvkJRKNu7KOD54bXfKRMyyF+YcrAmrFt4Vvc7hNSMAw9Q8A3i/BM56HIC8XKQ+GvXfJTs7jvYWd2IZcVOVpFwSIOaq7rGQyN7YGiGyH7fhhX2y/EskepYrqynVM7FfJhaC+X/j4xYAAAAASUVORK5CYII=",
    },
    "T32": {
        "description": "combination of knife-sharpener and legs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAABPUlEQVR4nIXSTytEURjH8R+hJn82ykZYTUkoJYwszAuQaXYouzNspIl4B96BkhqazS0LFlZKzcJGqdlZjGjKQtOslJGkW1+Le+fOjHvGfVbPec6n8/wWRwCZhP4vByqVSJYHIMrlwbmIdCe8SIlMRLpdfiYiWY+BRUUyA2MKWDtnwKiJnVrZNjx6zHeV4w4rK5t677m0Rc1S3xmwfVuychNTwoHvVFitASXjuxHHAZYtj13RUq+3rIbRkgnA0UGV3CBsWHLB5qgfLQ4Sl52WjRqI+c3zvHsvTVlR7xNKSpIezhe+FAsLAztywDsNHeZuVsKoQFEah2RjZFv3LpVaBjbU/XcQRugtGvVp3cftUXau5jWuJYhfwwWqkvag2EZMT54BpONZAJvY4qP1AzSuuoLueibVHxxqd+5nA/0C23rcM7G8z5YAAAAASUVORK5CYII=",
    },
    "V13": {
        "description": "tethering rope",
        "pronunciation": "T",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAKCAAAAAD9OHM/AAAAV0lEQVR4nI2PoRGAQAwEl+8CRTPMfCER0BJ0gc4X8w6BQWEPgQ9ZvTN3C9UleSVkEDSYA6U964l0AwrZ4H/UJIsvfXRZyXhQEqPTlSmFfUmU+jGSKAV4AXlRZD6xbw2qAAAAAElFTkSuQmCC",
    },
    "E30": {
        "description": "ibex",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAACFklEQVR4nG2RW0gTYBTHf5ubw7xlRolpagha6EMmlYgoXihCzYG9+VLhQ5QQRQkFESgEEQUV1EOFXaALqxQRL0RKEIwWppVRCOkg8YJrbjpxm/bvwRnm/J6+7/87/3O+cw4AxD6VJisiCD9brnkXBv2OekM4OiF15z6W+0gYsTyRPN/tY5oyr5aNQGoejLVu93VuTlrrqpK85XQM1/RVr5ZNgB88bxg9lHV8bq2rXGqDmNqs/2UTsBPMRRl9tnW6+jE0ueBT6ToNX/dV2yRbVDgpGJdzVqoPA8bSpri+R+/sFFvC2C+13+hx7Hr1pyokpKelp0cCGMR0rIXEzNem3l4LBPdUgMFu6/LCS4+6viqFlG/uade0a9rt9Xo9cxo6bDYktBzYcawpadJ67pJxZSmLcef3/7ZCvpX80ToeavUPiqVny7e2Qe4FVzaSWV0UkSn9XH7ljZdfCJzK3gZArX+irNDXPxGKHBm9NTM4chAg9/KsPr517isJVT55G+B+bAJLWRkAwboXIVel5J6XpIXZu83zi5I6EkPIoZ6cRvm7r+ZkcTQwcmdAH5YLE+0aSKNEUwYg1aH2yL2yJxsBKNz4yYnzc3QkULA7+Dww82/8nYE84MpSFMR16ssmKkMJTQ1zw0C8TdnQ6A9aiW7X+60ARV6dBsoCKiLDpf4Yavy6aAK46W7eADSoNZ4zcp81mlsCD5L5C5145sIndzreAAAAAElFTkSuQmCC",
    },
    "F50": {
        "description": "combination of f46 and s29",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAABIElEQVR4nN2RMShEARjHf+/di8TwnSenq7vB5ESxyrMz6OhuMCkxKRlkNlAsDAYGk2J2i65snsVlVAZXUhalG3QkvXuf4T13l96VjP7T9/1/9f/6vg8asg70ZZZIdaxX1StnI9nAm85t60Msio3qMYlSzaobZoMpZzyXmoymEkwwaMF+6Jesyjt84tUNi+4FOygTLDlMsOMHrXtO+kKjVVnjRi/HRUREHJ0XOdIeERGJz9z6eJV8GN+vk7CrYRc/USvmFuxNAGxWp3E4DGhm7Bp17XTkvNMkRX8jvMWQZmH/OxOw9pKLXWUAUkz1McxyDbyPTsMAcq8tllADM9UWRGQKK0W28oMeGChg4T+G8e083XPVexd12hHN/ekP/5J9AZCOkxSFo0CGAAAAAElFTkSuQmCC",
    },
    "Z8": {
        "description": "oval",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAALCAAAAAA/jwDgAAAATElEQVR4nI2QQREAIQzEAm8E1QBKkIWbIiyngB55ZzKzC6QFCYzS0BxMzeBCpE7SfRMAtoleGwChTVqlIB3qCvTDqpTFeVn08Mv/ux8DAZSlxuaougAAAABJRU5ErkJggg==",
    },
    "O50": {
        "description": "threshing floor",
        "pronunciation": "zp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAA1UlEQVR4nFXQoU6CcRiF8R9OL0C9EgPbG9zIeBMECwYCzfDNP5uBjStgI5ko2JwzcAFuBpI3weZngcS3vYaPgO2Uc/Y8B0RpMjObEtBBvF+aYOL37hPIXLVhlQki9wGzIPYZRJ1Bn8O4N47IOpRcMZ9BlayyaNo6euh/ZCMLA9Wmqx4YbJQ8g63nn6/R1a2XB8gCU/O1A5Q8R/d++LgdcnEcbdK0hvmI0Vo2LQRkNdBCRJ1hUcE3kXUQuYvl0mKG2GUctV9PtTuIt2tPZ//OcVMOJxf+ATGDav07KZeKAAAAAElFTkSuQmCC",
    },
    "D45": {
        "description": "arm with wand",
        "pronunciation": "Dsr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAYCAAAAAC30wCSAAABkklEQVR4nIXSTUgTABTA8f9wA9kaYmFKEPYh4WR4Kyq6VZeIokMGefBoIAodgliXiCC8pUTrUBQesqDj2qEoiqhTGB0S+yBqFFOjFdaitum/gw6zbe7d3nu/w3uPB3Vj/7f6Zu/NQl2zS62LxlQIbFnNjFv8JbHzDm+raTr03Owfsr7yUy0TWrB/rffwDkc8UAP1mWC31zDNHp9UN2c8S7NuxTSMVl9yyPfESw4FMA1xj1dDGVtC8xoF70KXbyrJKQ0HixZbAVPA1LsKc0FPRHNmNwNoL/SY+M8MarLlp7YBkPM1oRkvriCtcxppmvZH+2J+6KFPu3V4WZy+MqdXw+s+Otu9VIr06YxOLmaxFy8n1AedNOf93rZkgvksrIfYpYaGhTW9AG8H7kP7szDXp8uICJDceHAAYOxzcSS2s3i4f9OGpuzlkfIAARof71jYPrGvNB+IfJ1KMN/TAUC+K8My4tgtSN2IED9aKP9M6sPk7Rz/IgZHgcIXCqVCMhMEGscrbgsn9XeV8srofO6j6Cr9v2KHtWYix7CYAAAAAElFTkSuQmCC",
    },
    "A33": {
        "description": "man with stick and bundle on shoulder",
        "pronunciation": "mniw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABvUlEQVR4nE3QTUgUcRgG8GdW0XSgg666gTCxCXow7UPUQElk0VZS0IsgEh60w5J5iQ5FeFhEQfbWqYjASEqFEjwsgR9t4BeiB3FR0YNru3401e6abv91Zh4PijPv8cfD+/C+AGB/G//9JBOWyR5Obqp8Btian984pzJx2FMd/FmMx0f84QQADBn6QcdTDo4dGzq/XweA1xSqrpGcefnrTeKzbAN6g8a6kHYE/nzZP56sKwSAkg+aofvur7G76yhCFwAgxblILwpVrc0XPawAAGS9J/uA27uLBYpDkjozoLlagGXvOCtGQ61hQCMNTgTJmAd4xU8ysJQkhzICHPSxEw1JrU1Cwzq5PLDHvqLQlnuEXFVQszo5RzLqhksI+r2JWsgFdseLiP4RQIArObf+PTi/vLQ9E0jzxzpQlai3PCl152saqhN1NpOacv0aJFwxSfL83zBwEH5k0r3K0AIgq/mpl3RXvjZgpLuVGXNV6S4pAuS0pfGmzu6rI8aUpdEh6ZF4/16eJTXF+XxkfaMlJbAfRfwvTCq/Q/UUSrFJuQ+z42MCVcplpnE6xmCO/V2Y0QtxbpMnHpTPBnrKzgD4s88JG5sKlgAAAABJRU5ErkJggg==",
    },
    "V14": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAKCAAAAAD9OHM/AAAAYElEQVR4nI2QuxGAIBQEF7owshlmoA9oyjKMHx3YhLmJHZwBiQmfje9mbg+iSbJIH0lOUCH0QzVAQXpbYUDGu3RJqsn1KIM5f25l/FrUT03z/rTxZjY0OGBuaucGLNwLfFwbgeFiLH3UAAAAAElFTkSuQmCC",
    },
    "U30": {
        "description": "kiln",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAWCAAAAADswUOgAAAAk0lEQVR4nMXLsQnCQBiG4feOiBtYnhOksLVKeUUKR9BCsLkh3CFdBEeQtIpLhAgO4ADpJXwWMeHMAj7d9/L/AMzXoZRUhgW99KZecBggrXmeO/PeZJz2wEra9Zde2gJHXZPv70EXmN0VeRkQsQTAjFNYJv4RPFh8FHKw5DzGkAFOKobtpIaq7ZZDqFoV6EfjJ6HgAznBWHDG/ZbtAAAAAElFTkSuQmCC",
    },
    "A29": {
        "description": "man upside down",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABfUlEQVR4nE2Pz0uTcRzHX9/n+zQfcEKEIRjE3GIT85Cg4CAatUMwEo8dKzwIIzxFl/If0IMdBHHMg7IuHbIORWApBf3AH63TcNCiCW0wQiXDx+3Zs0+H5va8jy/evF+fD8qytDZiGzfjsU4ATG4nftflwF06asylAeDK9L7IZt+8K8ucpv+LZNEvJQWAAew+J3Te/Y5qEfYANNImGhq43k61qmpEmh0T4NXarYnKUNNjApzYzLXMJoDh4/Gh8UTRzuyxH+x0e5nVsh9D4yGaaqv/n9B1p+k+JT+cqavieFwEfL3rM94L9f3uz7lH3r8a8yU7+cG7I59Wdmpv8CZ52MPZ+gIAChJjfaN/Qg77xdUzViFD8NlfEbHvMXAkIuJMmtdGO39tD18YX3/hL2XVpfBF8nYldu7rwchDkUUY2FozwlbhfXxoYssFIPe2xwSUjwf6Mmiwgo4JysyXo1GgBoPXfxqgO7afAhRT0KhH+Hac6aD77ruN1zeAwEf5B5+Phjn2fDrHAAAAAElFTkSuQmCC",
    },
    "P13": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAICAAAAACw8NI0AAAAmElEQVR4nHWOoRqCQBCE/zMR1+ZForaj6SPAI1n1LXyN4xGI0iQSjbuRdgbgCH5MmflmZ2fXKQyx7dlFqJszhKhJu3vYTXWakjrC4ybY8GF8/heVXK7YEN3cKmBTZMzXQ12Crwoxhtj2Lru+OhmCTQCoyZFienfzolsPvHx5LIQcwwv2HZtlrJpmrJx0k9k65H9lE1liC/8AsK1aFB1YpmYAAAAASUVORK5CYII=",
    },
    "S5": {
        "description": "pschent crown",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAAB9klEQVR4nGXRbUhTcRTH8e911/UwwQdUbKWWBGGBEZQiayIVEVETLYioBEGINPABwhdBSEJRQaEgvYqBCAohQZREVjCihDkwjShC0CYzacXapvdOpzu92N1t1nnz/53Piz/ncGBj5fmkB2rGVWVnfiLoT/Hm5goO5zmvr3Jo1O/3VabcGdWfhd78lKu8E2+/NBhsHU509CZEtCok0nJD6pJc0h7rrBdZkbvwXTvz/MUuAErfS0/x+OMfvkUnXAn2FWwDwP5K7tu63jbNLry0QN6gOAHI9cg9teyj5p+REYCy11otUDQmD7OompfoXNgFwI4pfzWVo+HWbDgejnRPfTamc8n8cCB6ElAfyMh5vTm1zbWEROoBCifjnd7ZwpTvnYtfAMCxNNQhNy0p79a/JMPtwIGh5SMAan5J8aXTVk9FFvH9Bxs8Oa7JDwCc+ra2vh7XNF3X10IT++7IOQCUUveMLxMUQVE/TahPVUccAMvAo7SznIh1JUNGBg6bybbGlSHDUfTE3yvWPVkwXLHkWk0/GhlYM6JyMXzW9K/eIjNXBBZr7fbtucBl6TN3hVbPkohMl5MzptekzUamyy3Lv9twxQY3saGsx9rCLdySRv4tt5TvDvwqMHvVGHxPbEu2vSloumK8Be3VqzZX6L9/2Nqv9aa1fwCN0sPc/fPiEwAAAABJRU5ErkJggg==",
    },
    "U32": {
        "pronunciation": "zmn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAABFUlEQVR4nD3OO0sDURAF4DN3HzFrjNkkhQFXUXERO+1CQMH/oYWFjYWVYCsitlrpP7CzUUEiioIQ0EbSuMEIEogSfEBcboyrZizujVN95wwMg/Gn6jz05M75bsnUwb/k9vL/5oFb+W6YZT62te0Dlh4AASAqIr6ojRA00PUzeNjSzn43p7LafuXWyCmLwbdaIq/sDtVvuFd5wimX2FD2J8Mqu8pjpmxGuk+/P6JFyqbBsDyCAKz0V4SXJEMATn+5gfsOIIBY4qSBX/Wb03MdIaZMndpPclrdIdslw5EEAcjUihgx6wxBkPEZXu0LQAgK2PkshVdWIaCjuY3DBe/1dHTrDJldvlhf26609zKAu/nBzLyfwh9E5V1QRLVkRQAAAABJRU5ErkJggg==",
    },
    "G42": {
        "description": "widgeon",
        "pronunciation": "wSA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAdCAAAAAD516GSAAACIklEQVR4nIXRS0hUYRjG8Wf0jLcauyCWWphRDSVk1GA1RoiZBrWoVZdFRZhBtupiLSwCWylpZthlYSAUFmRQ0FhhMpVIFCGBhJVddQymKJLQmnH+LY7WzNHJd/O95/l+vOf7zpHMcvYD9BckaLKadwQ8HvCunEymBBnYK5V1Qd5/YeyBICRJknbC1Kgub0PDQ+DlXPOxkV1R6RCj5dlWUj5NNi5FpabrMJf5Und9NGm8Cd2KGZnxzq1B48ZBv5qXZNS+jWJTJRnw/LLicl2V5vDSVc5ooyvIl2S4lmVnJl4Z+RkAtkwsHaHWyMB+D7onpIU8tkaJzTC8aAJ7Fse4zFYCHVPGxSfoGbXJ1TDgNn+H/Ta96eNsBb/NAddhGJ6MxnngW2y1x2G6JOmqf2NY7GiAM1br7MEjSeqkPTksz3gNW624lzZJ0rqvNIXnOZ/oq5Yk279sxbP7RZKUvX9B0asxzdAX544sBSqqIuYu7XthNrGbz2Ot7ZFnKMYrrSmXpBRHkvlCx+Fj9QDfkyPtcm7qIp9PrpUk9938/IJiSUqoh8YYy93O0Yq/FFpWS5sAaKmqO12Z0UT7LOt3+AYPNLvwI9fW10Lggg+AH4Nwx2ah7zPV6Zbsp8olVdX54nf/2pP1qD1uOCbeOvUDPJUkeYGF1t2wmlMDHDX7AOREbBpjzSEjGArWGJK6JCku3Xq0vzStLGssmilXWu6+hFgFUyPoH+nUEqdYfjWDAAAAAElFTkSuQmCC",
    },
    "T4": {
        "description": "mace with strap",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAABHElEQVR4nGXOTyiDcRzH8ffz89hI/pRJkqM4IKUcnB7lxMXRQbkgymEXTm4OymFTVpSDlZNEDnZZK06So1oLi5o/e/ZsFubPtmfP83N4Hkk+p1d9+36/HwCa80cenDTuS7nkUFl8nwm8DQPQkDqg/eYQgFZzHEIJEAAVqAACzMIobUM6AFVb5kPamnIO9e7KzFqT+6DjJVKHu3tfNj5+7Max/HWtx3JHymzUis97AfCVE8WnXAAEKLmV17PjEQCCn492MWVooC6bupRS2lddjN35F6SdzMZKQTGZ3K5B2Vs1Q34xEfuqX8/4wt0nEcGz3X9eIH/ZNy3QBjuvvR42vbp60bORvq2GeAkGonIOY8ep06KprlWyp3/7//c3AtZn8bqEdl0AAAAASUVORK5CYII=",
    },
    "Aa32": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAA7ElEQVR4nAXBvS8DYRzA8e/zu6c9GiIR8dJIDCKxWES9RSL8AY3ZIunWgc1CYmH3J1iFzSSipo4SORExiKSX1oXhBi11evf8fD7Qf9TT62nyu03V5JDVJ61WGnXqv3ujC+fP6E2hGkV3ArYzHhxbMEP327GA4SzGkrmsCcLUmJkAuShO5pZBLr+t+iC5PnAgYUucgjy+zXbzgqTpfGdxDkGzVARRDID4nvHUIStL8eBDgAz4Na8N4pK/ggHZabc2bkHKjfeRCARj3DBY1LmTmSub2F63eLDGaVjZLNcySsHXeun1hfzW50f4s/8PQhhYpZKzDC8AAAAASUVORK5CYII=",
    },
    "F47": {
        "description": "intestine",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAALCAAAAADQTWveAAAAV0lEQVR4nIWQsRGAMAzEdAzFnZdgFxoab5QNaDMAa2QCalFQJ1ate/sfwiUJ5FrRDtqCKdG0o3MDCH2LHEgt/oFdWff6cwpC21YoJ8+NqmPMzx1QTXjBB9vg1UuQ6NpKAAAAAElFTkSuQmCC",
    },
    "U9": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAWCAAAAACAxxGlAAAArUlEQVR4nK2RsQ3CMBBFf3aI6FwfCyCRkhIXzBEW8T5HASUNUpCyAIgNssSlcOzYAp8bfvWt+757PjfIRIfjZh9Pz+l2f+cBy/Iltk0a4ZO/CbywBXzHS9ZFhCm4ZTAHFyOEPAKKbvdxbVL45YzI1OoRdCJjJQLjrBbxJCqLJ9Ff1ImMKO1l2a45P67KdgNJ6Y8SEgCgnoe1PHBPGYkq42wtUtEKWx6SwJb0D9gZRJCl08OWBrsAAAAASUVORK5CYII=",
    },
    "G8": {
        "description": "falcon on collar of beads",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAAB4ElEQVR4nF3QT0iTARzG8ed9fffmps6EcrJiQ2YQiIoTLBaBYH8pirp6iCjMg0oeEoaFl04RxQKFqC3r0CGSxuoUlk6ZqzxYIdh6Maa1d662Qt1irW1Pl8p373P88IUf/AAATR+znLBAt2rv8oVR5Z5Nx+YHIcjN0dviJokA1t9WGnPvQ+3bdXnb8nDHwZ3BGzqWp8hHda7Fw6Vsmg13lkPqfuco4Yo34wCAoFfWsnFyrgwAbPm+kvxUZkAEYLi8sE/LQiTTCQCGu4GSvIvBWgCQIsOChlsLfGIBgKs/9mt4129yqgOAPBMwbvIWb1phasQOOKMXNXn/1xcMfYidcVQNZDUv7s+p7G1kMRY4Pfaw4p9umySpTrz0MLtyXu3+f7KY/0ly1KJeGvHfnLP+fb1IZQazz32J6PHXLS7ZCgA1DTvcfNzLHnsTjhTjEbJHgHDlqPlX/dZV1anGxWT+UBmg9AGDJFlYXPoWS6SSyc8FkikXWqY5fe1LeqgdAGDqylB5RY8QblX32MbtWPdFV6TdbSeBQd+zBpB+uEmSXNsgSbpxnSLyHiSW7gCAuRJAOmuAPy5BymHsfn2jesD09MT8avWtqnnkiuB3JwCxFsfOlp9zmOoAYG8MDFuhX/OnPzPz0NXehsg2AAAAAElFTkSuQmCC",
    },
    "D15": {
        "description": "diagonal marking of eye of horus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAOCAAAAACEdSpQAAAAzklEQVR4nGO4+nGqLANekHf72wT8KgQT/v/fgV8JQ9L//2f88StRmf7//3Yr/Gpm/v//v5sRuxxUuMHXiOFKy0o0yRxWxo/LYBzxnf///88SRlHg+v////81CL79g/////RzIamo///uy/87yHqq3/7/vz5JFcZlOva/hvHffxRjhbb+////f4M6lGv95jbDi/9oHgjWCDBkZpj+9fiRVwwMDEIT/yR8wOK9tj//////PzM0Ou7l////S7GoYLDu2nbg+/////////8ihQ0Af2Bb0lQlO/IAAAAASUVORK5CYII=",
    },
    "O1": {
        "description": "house",
        "pronunciation": "pr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAQCAAAAADLk/swAAAAKUlEQVR4nGP8z4AXMOGXZmBhYGDELfufoP5RecrkGZHiDx4RSGKE9AMALmIEH4o+nVkAAAAASUVORK5CYII=",
    },
    "A18": {
        "description": "child wearing red crown",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABpUlEQVR4nFXRQUiTcRjH8W+v73SRGyUbsoOQDtRDQUOwgiwEBTFUNExQCj1oBz0EgqAQpIeCJIIMnd46uPBgpHiZWBoISo65iESH00TZ7KCh9g7ndE+HF7e3//HD/+F5nt8D5684Ll2Q99OnJAnFNw53bRspsU57rdh9o2UpIvvbu6yGgwpDHfYBWfs7l2aQS+9Pvog8MAjlUc3lXcgw0nORTe2RUdJDa1uy6QRUfYBei9kx7xmaDJ3/ML8QcVeFlxODyaKKg6lbrpdnM293xgp1sXlHsyv9Er1Hj4yZUYD28r03Exb3roaD6iaAgiPRvrfmmj402X0/5OttFdoigf5AHFZNZltrY3MHYLmiT9LfnBO8eed4SYGjP6cA6flxQQmFT5NR5Lfc/3WCWHP8KsAF5drDskPPutN0Vrk/C8CNgT2Z7n42sjXj3O7Ud6zrIGarCqyufK51hFEB9Sq8fpXQEuBOuwhAblASTwHIXB/WMyyJxbR6PbTHFr3/8KLnd2kqTAXyWuaCu/7/qEbZuK7GDZlf7tsXf/ST8aArEnjyMVJkkH+ScJlcb1CckgAAAABJRU5ErkJggg==",
    },
    "F2": {
        "description": "charging ox head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACT0lEQVR4nIWTX0hTYRjGn7Ozpm7tmIUFS0WsdMsgONooLyoiCBQkaARZlGARCNJFQZrSRVigNxEGQhdF1K6K/tEkMZYXKcVQC7ZiqJUYi6ZhE7fc3DlPFztnbg7qvXrel9/3vd/75wNW7UrQgVwzZGi5svw/RBFcpn8TKo5vyCWMWbRSEl517ZIKiEvGqmA6FIX50LimpXanLc9gUNUoplrTBZyPsielzM3vkuTK8M1REgOJoVJBy9jPL7VAvnTSHw95B7dY801tsTlYnyRHyrRLbnG+Hvs95MKDEgBA5ZjaCxS/pSt1iTxKPmyc5eTzRu3Iwe/jVkC8yBEJAE6ESZLBPll/mHQvcUYEIE+zA5B7I4wlZrsv167Wu29peCOMQMBb0bmHu3Y8fhY2RN5n9Md8TL39GwCw+xPJ4JGitd0sm/bbNdmV4Ex5br93qh+qtbnc8CH2LZcQIQoaoV5bMUCoqM/OY2wS/qj6bJeomM8OeOqyiPwG9dWMTiwz7uirmgxlEcoPfo3qxOc4N+VNt01kEfG7Ysb2LASsh6vXvtTOfkt6gxTbgZcpVdi2TZlyz6ZqqSsP6PhP3tcKaE/GlhW/UwBQGvRXp/fUg9R4zT3dQ42nvdu954zAot/EdMq9dAMAWugrAYSOOV7ajILrbF2nE2a+NgGo8YeaBQA4FeZTB2oWJ7bqhMQREZaOjxGXFmgZo++CfWy5QdtQrJ//9eLRG4aP6kdER2eCQyHeKdAChqskI11VGd0wyoMk3Rbdz7PZbMWZ3wuA5PQkPYV/AYT847rIW2GDAAAAAElFTkSuQmCC",
    },
    "E11": {
        "description": "ram",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAbCAAAAAAxR3I8AAAB6ElEQVR4nHXRS0hUURzH8e84XmduVpbagFASbSJFHCiSoBc9oCKCWklR4iIp0VxEujFa9FhIIkEjQQVBi4haGLSZRbQQoY2ggYvogZOVkDYMTc2D6/hrcZu5Z5zxvzn3d8/n/Pmfe30C4F3vEgDYD5uBxKXnGOV71tIM8DbngC9Qnd0HMNbxuwixri8Ff5uuADB4MvxkpsoeSVGuHksff0nry266dW5SPzQXlyZXN23SmsDdMUl6374aeqDbUHNeM+OSBlrKo4juXZiS1MCByHfpRWtFsKYENSYlSXPuBdOSpMj+Y4cOhovYJqtfugyHjwN7F1LJjCRJTja2td7vuX59IKxO4+SZ8dezklTnvbKlppiMUwBYtcqEKgqxGvwhciuQEydw2kOLZ8ktFYGGbe56wkMkeTTCbgP1fW4r+RC1+rNZ08bka6VdIMVMJX2S9DV+lGAgSG9iVtJ2cpKJOlVa6ZeSfAaqXwBgKGkDqhy9OPh/o9JAVe4ykM/p/INxO4BhBzbmgwXTd1Zeb4McOyUV0HUtBumRYmanId6kbSPXkclw/yZT5tyShfE/O6RhoFGvvE5WFwnnljHvVZgARo0+oWXpCN+kLjf7J6R2YI/0tIBOLWejrVY02r3FzTf085ofdnzR/M5/sSfulGqPAGoAAAAASUVORK5CYII=",
    },
    "D27": {
        "description": "small breast",
        "pronunciation": "mnD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAOCAAAAAAKr2MsAAAAiElEQVR4nG3PLQ7CAAyG4XdDI7gAmySZ4A64JWSOhOCmuMguAhPgpnDY4YfBcpMXwZb9QF2fNO3XQH4r/GOg+RhyDSEbYwYUTrZqQVKZDi21SpjtrIdYuwd4eByeaUcal51FNkAA8Fod7tuY921zea47pA8Q9B9F5ZfO8SjdVbWafLso9TRvmw9OPi1In8H0wwAAAABJRU5ErkJggg==",
    },
    "R13": {
        "description": "falcon and feather on standard",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABT0lEQVR4nLWQTyjDARTHP/ttbCjKXEhkaYniwMHBZA2XHdxwkcOODv5dSeHAZbtSarXchJLtIqUU7bKGHNRizfhtQmb+jOE5mCYOLnwu771P7/DeFz4o3RW1je80pPaigY7PSclUvX55KOG2ZtcUDVD/eNVXHbipybh829w4oHGma6nwu40fdjqxelQFDCZN0PjkMgCQkpa5KaAz2Q/MHJQBIGKzeoEc720XGDddAMyqA6ZkN+ASdbiIxv12ACYuK32xXmg6E1mb7POpdoCS9Y3W8HU1bIuIPJ/KuQXAHAmrdwWwJSLx0JNIxA5gEfFD8WE8JGN43kT2AHLnZc3hWJDg0utxj/lBJAaAYST6IiJy/7wzqtR50s7M3zWLwcTFYXpAp0BxS2E2pBVn+UnztyRBqzNotD/sV/7WavKUn1a5W7/MtLqs1amO/7nhN/sO/h+CW9YfxsoAAAAASUVORK5CYII=",
    },
    "T31": {
        "description": "knife-sharpener",
        "pronunciation": "sSm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAUCAAAAADAEcDpAAAAq0lEQVR4nIXQLQ7CQBCG4eEQtSSA4QA1ewgEEk2ydk2vgMc16QE2vQSWC2DXb8IBsC+itFvC0PnUiCfzJwDeyXIi5GyyCIDlIsTedC1JxHljuwB7mwVwYjIPa5nYP+fBy4x1KgvwGNjH5VZvlvxYD+6oqJpx5sQarVmaMXEROPwqF75uiwy/UVlJuqmbFXZpnsQKTpoq2YAI/TKSmruQDCQdL/LKQNV5u7u+AWuumvAO6PGyAAAAAElFTkSuQmCC",
    },
    "X6": {
        "description": "loaf-with-decoration",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAASCAAAAABkh0FCAAAAm0lEQVR4nG2RsRHDIBAEF417eTWgUshoQvE7tIuhBCrBquacANIgXcAzdw8D+wDErItyBAiAf+BH1wrvLwC7VJJ131KR9ub7sAHMpR2i5ExyKZJVbA6sKCOl2YckoXo7AFa1wHEPDnj1vVoNrS7wdBUsrFvvDaG3byvjudK5WlEeH7wGLsWB5Awakg6xBydEcEm1tmlUXeA9DeoP8Vp7/nJWoYQAAAAASUVORK5CYII=",
    },
    "G20": {
        "description": "combination of owl and forearm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACh0lEQVR4nG3Tf0zMcRgH8Pf3x10/zlx3khIqrtS3rVhp+iVlIr8ZWhrDKtPazMj8CDvGVWv+QK6Y0BgmJia0MVeb69YsoulwJ1epVC5cXdfV9+OPu35d9/z12fPa8/k8n2d7KACA8EQ0D7DaAgMmBwsACN1Dt1JEmN2a75SjvFe/Z4h7eaiLxRnPEKSWlIV712yVdjhjHv2uCmisQWIHtkUecU0l+pAAvVLkjJe3rwvvUYJJH1bF2VP03qc3I+1nUf0d9vx2qa//okpdrC01p4mQFz52Vw4thqdu+PNxj3vN0QCALFJ3l4yW+2puYLNxv4yCj1Y3HwAUWn+uc+no61sG0xLbOABIMD8XAbhQDL9PsTQAgUQsrrwk76XP0ABUhTHrAVAWMAxh4bktjjOba1/HFGRczLneD5yWyNU/8G82eB4sLCbNW6/spJaBmE73c8kGALKgqzo+wm9towtF3ea6yvpJEQeMMJOH8bfTK54qFgfRhGeo9laZ6I+OEoYyjSahr2ezBSzbcmXC9NV1H6RwU5iVC7DMkjtlsq+O1BwCqLT6hjDIf4U5smrnro8+ACTPOvJnqksoR87ErXJAsFB0sO1RjnGHI+9DUg+H8G/FbhFNVRU6bkp1iukxJO1EjpDSLvJGPFGDvxqfVI90J8m+VJnXwO0+IQ9dJnCYwaToahwmA0aZ8qUUkQ2kL4MdZ66lDAmneHWFBgGGXGAVIb2x43zAHAVs6l45LQA4q58FwWFC8mgAK45uCAwMTnTl/TzmDf02fQeukUxYi06SCAAbB4k9TLWkz/adFH3WXExXVVNAYfKQ/X6aHbz8wLYn6ces76zxPylAIuLHGiBjayBbsltgLf8P34P7vXX8zAgAAAAASUVORK5CYII=",
    },
    "K5": {
        "description": "petrocephalus bane",
        "pronunciation": "bz",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAANCAAAAADgPUOHAAABTUlEQVR4nF2RzyvDcRjHX5/ZMj+azTDzqyg/DhZRtNQcl1KT7MSJk5+JohyUpJ0cXLZywsWfMNlBWk6yi1JSUnJgafJjhO/3cZh9+7b36ann/TzP+/1+FAbsHaprx8Ht3KNS2WsNM5RRjVRM/Dj9QEIrsr4cWOyHQgFq24JHUohGE8EKzLo3gKgGfC7Y8534vUEadKqa7kgPx0+7qQ8AfC1Z96SjH0gnS3Mk0YYfSIpc7I+z0lRnurG6HHtOmwUoIRlgcS8DS+nUlVlw/bYuwOuAD7iXaGVnGVsiIpKYchW6gxkRsYZC69Nk5vvhpvj6bug8A0BV1jluEQDbmedfSDwtIqKPBnIum0KBzcJwFEDr2EgfgB5zFaOHjXNrz5b28Letgcv8F/zH5QAn77bft0/hpzmoWyj5yrF74/lBVR35EDk1krd7vV6P1dj7B6sAmWeXodhtAAAAAElFTkSuQmCC",
    },
    "G39": {
        "description": "pintail",
        "pronunciation": "zA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB/UlEQVR4nHWSX0hTcRTHv/d6J8vacs5gbtzY1bIcwvrvjWIw2kMpxczqxR6EEDSiJoEgab4EYaw/FCFWFBE9WBBJxIj1EIMUyg0qEALJUNzc3ZQ2K5V1d3oZ63dp97yd8+H7PYdzDgBAekEUq0Xp2HwhlHg2p96uKMG4Ua5u13xg72yn6WTsf8z/dLtT1R2OWtXpKaEWzhjrdxzYL1sBg05zoPLIJ5r16mKYv1Booy7lnlBugNelZzMUrdKjfCBLqwFda3GFKN/N6VDh7px8b0ldfd/uNJfAdelhCJ6RiEr0tksWtFLAoK7hTySyodm5rWlYCT1/rVXXKGGAb+spR7m9+zMtX7No+WDmFGw0YQeAdaejiYWOahZLyR/t62c+Fuay7Buhd5oFn1hM+z2xV3IhNVzOJW6xBv7UcutRJfm0f+eWTQA4MU5hNwegsIzjj7jO0b6W/Fbb9FhZNp9oPQwMDq0V9S2TS0Ez4Lk6FHysxImIiK5X/vPfPkkfHjSWAUBjg7efiO4cMjL9XW+Ispl0fL7XarXY97ykb5fc7PzNefo+NkVMTHnZO4V9Ny5K/h4x+TALiLubgBR7gXGfUZi5aRlQrvwGOIfEa79zYtEHwJn+6iiWmAc7L/9aAWDKSceKNQEAXOcAmNogBqN8xUEbXKwnakKkjfvFgf8C4Y7LDLjgO+EAAAAASUVORK5CYII=",
    },
    "V2": {
        "pronunciation": "sTA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAQCAAAAABfdVLCAAAAlElEQVR4nI2OIQ4CMRREpytJEJuVazgAZwDDCbDYSi6AKo4DkaCqCAa3HAK5GxLCBvewtDS0T07e/zNSjAXsTxpRWwB8HcYm0tpbc5B2fbf6+83hJDl8GFeRttQgkZumM17y+HVOI2WY1yTbII0mvyPJ6ZGujdnfeW8KvHkPlwKvucKxwKu6sn1TYBYcJrXnVlp8Bx/PeDa3lddJywAAAABJRU5ErkJggg==",
    },
    "T7": {
        "description": "axe",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAAy0lEQVR4nGP8z4AARw5/myf64CMDJmD8j8rfxr76NudW7Mq27f/KzcDwO8ABJtr+bd4zVHULFt37/78Lwnb+jwR6dFAV6n36fwjKNP79/0l7MVzlKhSVYh8uQFlB/48wMDAwMMgu3wdVOVsFoS71/1wI48F/M5iYymwMhRb//8+1YGJk2P2/AtkWldn///z///9/DgMTAwMDA4PAXKjONYxoAQEx8701zLwJ///8+yvDgAlUZv///387TDsbHwPDv49/saiTz/NlUAAAl9B16o4pq8MAAAAASUVORK5CYII=",
    },
    "W18": {
        "description": "water jar with rack",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAAC90lEQVR4nG3SQWiTdxjH8e//ffMmSmyTt6barqVIG2haRVrrYQyGZpQdSinYyRQvTiKiCJ7GDjLpBnOMQS+rN28KehBFcOziEN4W5nrpxqppkrVJCDW1M/EVEpOYN2+eHXy7057Dc/nw8Dw8/ABYcCr5KBflTSNOvPFGLhLNV5wFAA2ITS6cd2e6Tj04t3qm88zquQenumbc8wuTMd6XZRmcfWkVIoxVnlTGiBSsl2cxLOs935RGJr0pIpn0hohspDMispnONOQm+KC0SGzfb3+j+of+sER1jm9Ygv+jf5YpeQuYF4BZ6QP6ZBZA5tm5j8gYcfDFmQFmiPsgzlhkZ9pcatbsk9xyqs5VrjpV5xYn7VpzyfQ80bh+ovBo+u2dqeX0p+nlqTtvpx8VTlxvJADYdSF7z89sKbuyl9EX6y9G2buSLc3iv5e9sAt8cyKXUAMpuYHyPZbHPsUNSQ0oLonM+dQXc6+GAxptzfdOR8TfVAo30GprtN+lu79Vf37wyS9qie5JKj9jfKbkvsN0B7++4mOZelJEbu/O3YXxVjkJWn27rkGy3BqHu7ndt0Vjq54zdaL2MyPEcO2v2jAh45kdRTdz9S00dJ76Dcz1h60gZvl+2STYerhuYvifoqMBa909jGwt+wc5VP29eohB//LWCD3da95/C/0HOFrOBg9zxMk7RzgczJaPcqC/4Hkx3MuIXfIPcbBRaRxkyF+yR+gNFz2vNrowi63tHvZvupv76dluFU26GlXPaylde51jFZpJkk1YJfda01M1z+spXbNzrCiaz3neRK2QszU9VffcyeianSelvHmVIm9resbZyYcL0sYFXK+3Bdz/8hMWAh2EQDMxNQjREUDCO24MihvuI6YIRIkGUDH6wq4MGp5HJirtPRN6vIJzTDvmUInrE3valYmIl9Nri0GuWJfXBjieTCSPM7B22bpCcPEa8+JDQgnnBz3y4aj2pU8b+j58+vPWvm86t2Nub+InQcl3xleK/y350fn6X822U05GmauhAAAAAElFTkSuQmCC",
    },
    "A59": {
        "description": "man threatening with stick",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABmElEQVR4nFXQSyhEURgH8P+9d5gxxqM8JiZWSgnlEVNKbEaaEiEyjIWFJEXYsDNLjbCxshALFpKEFAspgxUWoqtMno1k7owwHvd+Fu65c+dsvs6v73znfw6gXw7aKo/jAC5GE8XMk1Np+TwqratrI8aqKYXoqo4Z1/BK9FMJ3rGr0CbTohciogEAyW/X2wZVs9OA/1s6wu5DXtVPrHWGEAL6Zx+vtLtMizcWLznaRHos4TXFNFlLRZnotlaX1Ckup2CUnmcqdZgToBrYdiW7/k3GpYjUiLLgoLrnASDJ6+qeK0F66oFOBU//3ookG4b0x60euivEpP+AqJQZb7+gwDgM83Tp/ahmOnYr79h5xC348vIf+lhri7+960gB4tevEwSzqgZnJAgAnCBDMMms9ykIACioP0NFyi/rVWumxV3drcVi+g5X5AvaBLX0Yj13AFm6TwRgksiFJvq2xvTKvG8foTCUGLVZju/xKrEBas3n4gHSBv6r2YMPgEsQhGgyS5WzWBFNDT0Zl+/RAM0vCm1kDb8RTajyBwbrkqA2MDf7AAAAAElFTkSuQmCC",
    },
    "C4": {
        "description": "god with ram head",
        "pronunciation": "Xnmw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAACHklEQVR4nGWSXUhTcRjGn//c1/FsU9doubnK9SF+JIZUZiyFbSQRaBdBN14UJEEFQdAHdGEU2J0R0U1SakSRWRBlH7uopkj0qWa4kLZK/DgUuBxnO3Od83Yxtp3Vc/W+/N7n/fM+/BnNBgO7mu3xxdGnjV57+JHga7AKL5/5dzrZpdomDYU/mxsNSoqRAi41Eqt2M+XVBIOjnk/MTDvdpo5mxgiB7sj8Bhcnvp9DVqejoXZ/19zPKzzytaKP7rW6Af5CMliWj/rpsqnrIgAcpN48smnhhB7FDmx9uB8HBA8AQJtG2/nW9eZa859i29SdW4dbhgFAk0Z3Jc8+y/RYoQUilnvrLOqNPR92A7rn52PB41zLTIUaFa0BUD9aJRD1+aQtqoX4/R2AC7Ju/MsOjYFTIwCANbrED5yUK9NdHioNCJpVk4r3f6SvFBVtScroB/sXlWyW8fH1UoH+Vzxzsm2P9s0EAION0JAq1YeOjWemzxB9PQqgKrUXgFO4lnvL9Kmu89x1I9b+CAOAFMmh27x8s6PtSc26qRAAmRRk4/0mNU0O0tUHBWMKgJpCyrnEG14e949Yy2MygGo1oqB3GzB4KPRYAaCQOgVj/5ABQPpTdCZOqdKQXviKAIgAgApjQm2zv/Nk0xqKlqsz3OhIZtDqslBEZeIGFnSZemVw0Zu7S3u2bbZ7GcQIjIiz9LSPZAZd8/E4ZZWIJd+6AeAvTpvJvkPOAkAAAAAASUVORK5CYII=",
    },
    "Z1": {
        "description": "single stroke",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAQAAAAQCAAAAAAU3YEvAAAAE0lEQVR4nGNg+P+fgYmBgYFKBACfZQIdZFPp8QAAAABJRU5ErkJggg==",
    },
    "U28": {
        "description": "fire-drill",
        "pronunciation": "DA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAAA5klEQVR4nC3MvU4CQRSG4fecGRYCixppTCg0boy9CZ2xgYqeRi8AjV7Q3gO3QWeUgljb0NhIsYR19m8sZouTPMX7HQBJUwEs0Luglwf2r+nnoMDU2mkbxH/ELbtfdFtqhrZMlIQwm+/380CJN5tYQlA5qtB6BDwojLSudQQKiTkeTRIC3+BDMDZFYcZgQd0PTsGCiCLh703xjQsz25T4CBS8D2fBDy8ZBtrTK3NmwcJWZ+gWWDwO3uridfC0IDusoof7zuqQSfU8ufvl/PM91SZfrne79TJvrJucfHjk5dZJWXQAKKN/6XRMHmnA0cEAAAAASUVORK5CYII=",
    },
    "F26": {
        "description": "skin of goat",
        "pronunciation": "Xn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAZCAAAAACTTbgJAAABT0lEQVR4nH2SsVUDMRBEv3kOHF4LCiESdEDsDkQJpM720YEIKUHXAWT36MA4MpldwpKZbAhOdz5jwyaSRrMzs7qbEYA9/1R8Zx4/4Iu8hwCvmwusZcN8ye0mpNXi83oBqwZot3tC3cPX/R3M/O1hIr4EVs03C6DdQk9+xg8WK2V9MVaWQyxSiQDFL6eXAcTiyuPprJJS9Sru8S+W6Ri7KP/hOGFB1m6QPi0vnNDk0MXL4ae0jLpoZu5mLqmE86HWUio6SF4kFeukQzpjSfKsCJASYArd2VBJCt75MZhpJ2mncDKMCkkTA5PWpejEMkoRXD5pE1BkXI3YE+0GHmlGy4ZnYPsre+wFBoPUy9pUK9FuADI3FXnhcbgcWS+jdP1OqWlbflWshpg0AKGuxxl9uDz0aaLqsD60A1n1h/Da6hUwTZ4mKw8bDwCd90Ani/AD8uDRlR896DwAAAAASUVORK5CYII=",
    },
    "R10": {
        "description": "combination of cloth on pole, butcher's block and slope of hill",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAABdElEQVR4nNWQPUubYRSGr+fkIVGjNWqMg6LFbzqVKuiiIAEjIkoFRbCLS2cxk1QXQWpbiosKhdKl/0AUFD9xEVTUlqAUhICpkx9JNBA1b/J0iaaDf8AzXlz3fcNRgKvaYVD3vtGpyRQAGsqG3jqTykSK7HHDAxz4sH8jcrp2PpGnzAOUfW8cgPd2Hk2rxrdnk0iYdBg0JN3TIZHIifVqO9M5HyweciY9TYXcZsxgkGVtTG7h5/+GgL8ARLPSppA5zROQ5wY1KKUwmMfHidE4372+syVtBz/SzNt3CE1XZvzNV7PpYGVKoD5wERJbh/X7NJDYq+1GAS/Gs3svRTkW2jvq+rvdLYCxj/WPbIm8bLy33yQSVgDUrWn1f98QkYqa3arVi6zoNw+xHP+XpY/XAp2z5XOdjtgn33nPRtSsVYAOsDNW8mdQ/TxwLV8Ot7WWAvzSDYveyrBZb44fHc9YoK0uf60yVyn3WSzfHXIlwgpFqsDDPwcsg+tS8BWOAAAAAElFTkSuQmCC",
    },
    "O23": {
        "description": "double platform",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAAB/0lEQVR4nN2Sz0sbQRTHvzNdwoawBUEoopseTCz0RxTBopeAUKRgEKEizangUdSTB0XUP8CTJ/EU6sHGUy4Fe6g5BFaXsqfo9uCiIUUjXlJdqpk1m309bNaWltB73+n7+c533gxvBuBdQ4sGEdm5dJ8CAEpfOmcTkbE41MXB2t6+7ukWhW/ys5f2SfH4O9p6Et0Pv5gimpRPjj9lUbCJsmMRQJ1cOyciIjpfm1SByFiWyC4gc0AbMgAAbLwqpqZEdZz5LG/QQYavuBDkG1QDqlWgFrCAu4LlKzpN+Ub7zo2Xy3k3O+0+p07papnrFRQPfaOmC3d/3xV6zefDIio6ME8xNIvpZc7LOgs4RvOQ4MAJDKp7Hrw6BezAAQfD/Q5f/Y4MHP+o/y4wPBCogeFfrnSvXn24fHMHAHdPMo/Sn//qEF4Kx0cFAIjReHgp/GeATSfXQ8E/CK0np4OBN4+Q361uHwVpjqPt1R/vRTMyR1EMmvZex245ni8BpXy8vNuxZ5uDiNIcOACnc1OZGbnoNawQAIQso/diZEbZ7HSad6inEwtbjZhURIMAaqAoxRpbC4l0HQAwS8Y1mZpmUUW7dTXNvdUqZGmaSdcGzUICR3/pMqLAsyS1QipKTBVWSIVnPegHB17kzyZajXniLP+cmU/LH1s9iJd6/JVRi8WgfgKIceK6Fc2pzAAAAABJRU5ErkJggg==",
    },
    "T22": {
        "description": "arrowhead",
        "pronunciation": "sn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAA60lEQVR4nAXBr08CcRjA4c/3vXdwAXU2UUfAzWIhaDCR2K7Y0GCx+6+4+wtIFpPZRta5WTDB5hzhZEPHz3l+gbt7fR6IzcxilGV6z80SZTy55WKMsDawNcLEg5+gbGQb2aC40h5lRcldychQvB5akKJkhUCOYBRWFCgrC4U1yjw4JpgiLPMwyFOUvywIsl+UdFh1wxTFL4SFRyI+zD6JpNMcQdLsOEu+njnfPxDfrThX6Xp9e7qLuDo5cnH1uszqYUTUr0GtH8nrTwMa3y8yS1rQSuZwOQjDQRvYeT89623h4HHKbhug3uvV4R+rtWHyY6lNiAAAAABJRU5ErkJggg==",
    },
    "R17": {
        "description": "wig on pole",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA0AAAAeCAAAAADSwsuVAAABPElEQVR4nGXQPyiEcRzH8ffvd8/jnh5XyiKykKsjYlBSNiHyZ7hBiYFMdmVRwmI3mA03KIsbDCcmljulDP4kOneUu/Kv4/497mt4nkI+22v5fPp+gcCGFMJ4Caw8ihw1e+rJOpI63XKh1orz13NT6S4AbYVOopcprUwALY6YlukTAdDgAwyFK9+780VCaVf+zXyt86QUgNHU0Ga2Z0rugBGsW8hbS6/lMoBRcVqykY7OXP3weDzCyO1NH8ErOXwWGWA3F7OwFkVEZAKR0slqIikiEg8pScfsqk9jEiqz28h+NWAdiEi01cBvf0Ah2g+jYnhXmpDJjWlPh/cchy81xQ+Au3vss2UlyZ0SWuzpvcahgHqhYtnvX0oPph9Q3fnC+PrMud+8KLgNE2+9XpcGTO37pZ/8l/xRTcl7C9/39nzezmwVhAAAAABJRU5ErkJggg==",
    },
    "F40": {
        "description": "backbone and spinal cords",
        "pronunciation": "Aw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAAClklEQVR4nH3Rb0gTcRgH8Od3t9vlMjs37bzNWmagZYq4FpWkRlIT/2NvQhCzCOtFvSkDIwgLMiQi6EVkbCIiNCsiIn0xcq6S2BBCZ+TOuU1pWzMKrXPu310vxspm5/ft8+Hhy/MArAkxON/qn508zc+Odnz19t5f7kyB5CBThDEvkDKvGW47s5tibcqhUgAAwNagLOVNn9KJSpkZuvn7DyIWRYxsHdohf0NRhkj5Sl8a/YGjHW9zN4XXocuygBF3Yy1+/+alh0ga8NfNOpIRHnzgSOu0yNA517bVMFM2HmG+/EpGmUUAigjGZwTJyhm2sep9SeXEz2REkRYpZoqdDY3Lq6y45t1oRWbcrEWFJNeQimRXfKSEu0YzbIhhveuQjvx2cTm4X2EO59Bw6NhEutb0ORlJU/U+4lagBvULHRwUeV7lpk9w8ZHkD9IeIS8VH1xtJSoKqn2nKlJ1ZeGPiVckrl3ZmLeApCEc8TEJ4iXkSmiP58LMP2hrd/vrHhfBYyAIGPAI8Si278Zcl/1vZeLEgLBQD0nBjYKlhkhsSrnayrsLJ21+RBLxOR8LAZFzMoN3Dt4JxlHDs0BvdYb58G6wOXgEAFi64gB8sm457ttONr0AAIDaaXfXlP1oWvvyVL2SYRiGUeXVTS2dV6ganj/yTNcCAOSz0XtjVg0ApdOSiT6kVkcBgOFld5TNB5Do+Z5m297k1vEUW1ru8noJUF62xPrk/wbg8fVdTi+FaeT9IXpADD3V4X1yDRjd2W0utRhSz59RuY3gGKHYYUIMEcMsNeLAVHoF7YmIoYiHVuhVGM6VR4fEDMBQtJzDMUBq15g4GnOpEYAwxxnEDYCBmxPALiwWbIQKFgU7yipz24QNENLutPwGDxv6kq1WPgoAAAAASUVORK5CYII=",
    },
    "E26": {
        "description": "elephant",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAdCAAAAADj60EcAAACW0lEQVR4nG3QXWgNYBzH8e+ZMa0x5nWRiFnZmhnKyxBRUi40rqREXi8m0m6YbNFE3FBeanNBGSNrku3CNNqQi4WRl1heIkvGWXPYS18X55ydc5rn6nn5PP/n9/zJz58zDUgr7VO9n83/R21T43nI3PlRu9Uzhf9npzu0qUzdm7PAqjatGJM+WAUm7SgF+JU0OYiLWyq3wOeSNPr/9F9NlGfV9yycCa5lgWpnb09Im65fqSzIHh5lw9UqAFzLGjsu7ASoqK5tUG1eHGHpqq4GXEGdZ+MeynzwTX9Ni2NmgOfm6MLESGVv/D0vEGH327wBr73rsUG/3K5LwqwJXllDuX4aMbgbG20Is7swTpl472ZaXK+ik6X2AKnaCByyb0Z8jZTS5MhsuQJbtRlgn375MDrm8p8ksHLdBcBDdVWMjTA3np0yGF6O+qF56//ujrpWcwBYpEDe/vnh7XnqjD0adUVeBOCixod+rM7eru5iyJDAsMZnegkYawLL1Vte2GbCWALpGkyKsVpeDSWljy8Fp45XAWS9g3NZbOJkYfKAOjCdzmxCIVJaW+HdUQqXTYdZz0f20fksVuy7Pe36os6fAPTKbYtya3xU7+GYKlStr9YIswTrYEKHepiBbNeAltUPosvJ1O+hFb6dACCarSATOMEYCN+cxYZirgKp8SxwB+A2AeArkFHJQWgfiBRhQ8cDm3rpBS7DxJejgUUhIBTX2eRq1XR4pFYwtVt1LsDUr+qRCFunuhn4rV3zKVfNA2ClGhwZ+dZT7bo2BVIb9Abjr/Q31qwIHxXr2xL4B9aDYHhKlZNVAAAAAElFTkSuQmCC",
    },
    "G30": {
        "description": "three saddle-billed storks",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAeCAAAAACUdGg/AAAC/klEQVR4nHXSe0yNYRwH8O973nMqtpyOVC6xRqWkixHKcDa2piyXMNf+KDNmNq0sZhhtGGaMNX+YhA1zbdLcb8eI0ZHQkkvpFKcbXd5zvO95O19/uPTi7ffv89n3eZ7fvgAA+E5NS40Uk6/KK0Wj0WSA3ggAELY+3Zcva5NH+7+5LQiG78WVuhYY/ow7Mx6S6isXSZK79ZQBiCkZ75ayo4GOfUUq7NWAUTfQsk4iPST50aUqJL2U83XlpU7y7iNSOTbDSfLFRhtrI3QlaU9PbaS6K+qilx+WjcIFntS/PWVkAI5LbDIunH1UKQDmu5oC+/g5gNDbdABzZEc8RtrVFH1kBCDmT/MM2dGzwWfYlrvpCbCaxfbr+npwt2NxtoeUSfLMgu7O7uaS0hyTjsygMwYByzty8luo5sEcmniF7KmIGvAvNB2iNwWY0nYV4z+4Vxvgu8ThyDpMliX/I8McpC0YgQ/UbFgbmvP6hTdxJnw2f2LVrL9ldEtJER8PwsRGaRPGVfVUZuW5T2yLM8beZ1upVStHfSoUil32SMReaM4NnFDO9n3l9a08tzStjnyXPVxTwhXbISy4/nnPOCQeqVgSsPU95YOrr9nldoUkXx+YGx+KX/0MbAP8jy6qqyy9s3227XL1wUTX07LTY0LSw8wRALqcX+vFI73JcQ2ky1H9jfK1MpJSYaz/iIjUsydbf3a2XPPeXE9BVuFThXTWkLJEej2KR5a8JMm6NRrZv2szYNrrYlF4DWtX2amdzxGagintFYBn59RJg97Nu8WbtitDC179OfTr0GT6vR0LIO0bn1smux3Tkdk5TbtMzbIypC7AaDVDdGf6DVuMshdBfcg59+oBcxwQlp9kazUAFLWy953h0VUAaGg5v2Yb4mbFC4KghZrMkJBGAEnWtfshdNXUTbRIivx/ZlCM2jMGzmTBtEEMmATkRi4Lnt7RP+rLk14pAAguiEpQVB9Lq9cgDvR+6WfB6YRobwuDO903vp56rslNqih/zb6m+HfzfwC9ipr/ooL5wAAAAABJRU5ErkJggg==",
    },
    "A16": {
        "description": "man bowing down",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAABwElEQVR4nE3RT0iTcRzH8ffz20ZuYCvqsZk6Yc2Lq0tQkZeCKOigUXTw1sW6BF4i8NQfgwkS0aHLBA0S0lsRMa2wizr7g2BQuMoW5JLVyGct3IPb8zzfDs90+xxffL7w5fsF1N2fU2/edVCffeZMjz76wFtvHUWRl08WGuutueAsrkuhrd48G6n2kyk72RerggZqpHM5PBRt1YNfJtNbxR03Ja0DnWMfz2xPn9u8ooea/fju5Qd2Ve2aWKZIcj8k5JFCAexBa5i5Hp7Q2SR6y11qWBzp5VTh9aW12dO52wDExSmfhRti/4q2Zd4rwKej5fIQny71rwQ0UwGRHlg3wDKWnqF8aQVcbrL4/gM4UjQxViMKjvdnctZUBWLBz5B71aQIJey/oewE0Bd8qkChwpOHxk3vnX+AJSUHBDV8Ymm2a2QMYCe/AwG/ZiPl7ud/DgPEvkpq8cNCdo75xFFzCIDzIiKGyCda9naNuyfuFslfPZYUC/A1sGVzHuIiXqhUXBNh2caHeys3rVpp1H1GzRqxizBdyNY+7TlAeQ1WjHyt1iKSAS6U5rd7kUG4v7u996LfqcrDt99E5ODjVRF58R/HXbtDmCQExwAAAABJRU5ErkJggg==",
    },
    "S30": {
        "description": "combination of folded cloth and horned viper",
        "pronunciation": "sf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABS0lEQVR4nGNgQAJM7f9/5DAx4ABs2e///3uaw4ZDWv7T/6zc/5/kcUir/d/IwrrxvxqydUjs/wzb//zezvAfhzQDAyMDAyOKAE53EiXN4v/vwWUVNY7z97FLe2Q82GKn9ywSuzQDR9en///3GzAwMDCo/s9kYMj8r4pst7wV46tX2im47J7JFnX5v8PkG1MYGH4wfGdg+M7wB1la9KO79/+LsXN1b7yUZkgyZ9BmUEFyBqNmKNdPqbiO/fu/fGcR/P+fgZHx4an89z9QrIj8OlFfQMTsf4+NTc//s/9//yhTZWFjY2PjgoZhVLnoZl7msD9/GZhZvv5h4Gd4sZ6FgYFhCyyIFcNj/jLoXbvHoKx56Asjrw1E9AY8BhhF/6qcKJ/PENXg9oDxnwBEnB3ZBUr/0xnQogw5SpgZmBgYUKKbwggdItKM+KWxAAD1kmlvfqvMPAAAAABJRU5ErkJggg==",
    },
    "F6": {
        "description": "forepart of hartebeest",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACHUlEQVR4nF2STUhUYRSGn3tnFB1zcmZU1FqIlgZSC0lFbFFGULQZHVqYCCJDP4sIIghENCiIxCho00YjFxUKlcUY6UCmREJRFgbOWBNaWOGok6FO3jueFvPn9V29nIfznsP5Pkgq50ETm6U6i5W431adaWDMfnTF7V5pMfbdzu0qjXlBjOzpRKE7PeojW1lgnNOFAJjbtYiRaUPLmSYAlGKJ9qlxxvQYNgDSLMEfQNEhW4IFfTSrAEfKvoxz4Hxv3Xoytu7nUgHAJXl1+NqMfMjdNNIxKiN2sI5LaEZEb928TpZXxDfo8YmIiAwbb3NiSWRd10REZDAtWTcDbxez+r32cGUDzN4MY9SEv6AcUrpFhhsbyw2owN9y52UWabR7QyL+K656myWeWZEzsPJP29nTdzVvh+Xinra/GwF98n7mJ4CmKSsZuR7xOwBr0ZkLrZ+/fV8IuQDT4xuYmtZE/jgTG5r3+Z9YVcguvJvT0b3YO23dnxJjur5r91oEqJ1s80hnLVUPl6sS+zXKKRW4vCrhBoD0vnvbYyjbO5oNKF0ydzxaKRqoibHSSE8qKvmV/TWeaCUw50oBk1nBrrzWACVVTUzpmMyn5NlYZ+nQVNmW21W/CTg4KSJheRG7S0wVR8+F3FanG/R3vx4BiU/NsVslX0fGmg8Ca9d/L+TNPE/m+UQPzq9GH3h+YUULnk1kasuYHLDxPqiAGZGM+v9PqtlPYzl7+wAAAABJRU5ErkJggg==",
    },
    "D14": {
        "description": "right part of eye of horus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAQCAAAAABSayKFAAABHElEQVR4nHWPzSvDARzGP5tfI5kSNRInJBelOOxMlMJJ1FaKJKXUuDpx8QfIwXZYJjkstRoneYskZVfNbppdxoG0N4/D/NZ+Zs/p2/f5fF8eegLvMwMdVJWt0X2cSD2eZ06rM0uSpMPtvv5qRPuLEluStLOy8D8xru9Blycak3RzuTjSWwEYIQUANuLJtCTtels7u2ssiLJmtbmvok7mXAA2AOyFnKMEj7V4RgGIP6SCrmLProxloc//9rsnb57Ildnuyae8TBkANJE03S7n7Drw/GWvjd45qCt2z7QGgNPrk6TPg1VrzAndAw3DF5Kkq3B5QsOZmx5aJtzmK8w3Q+rj6DZinQ6V3lEh4nfwV0a0fgqA19j1Xjpb4fMDrluLOb1hjgwAAAAASUVORK5CYII=",
    },
    "I11": {
        "description": "two cobras",
        "pronunciation": "DD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAABi0lEQVR4nHXSTSjDYRwH8O//ZWNaMhvzdlpeTqzFRW5eD2MOK7ms5CBKIeepndQ/SS6iFOUiFmkoNaU4eIlIVhMyRqvlbfjv9XkcVrS/nu/pqU+/fr9vPYC2wRlz1QD1D5F2KGIYuXyioX1z4wGlO/kK3IvElodv6bWf9kq0O9P4x1hCmrdulVfAUAoLpxjt8p7TlOXFMz4Xp3K2citK3d6xMxNK3qmszgARQHA9t+fzFq254IsCShRbjuTjsloJUPvilABILUyGAHAAxCX/V3MjDxwGOS4eEVVEX60ZXEmBA8A7+xy7ncVJeaVMR1Q5d/dAXZv9auqEA4Aqd6EvSsBpTFlEEF+v5JldlG/u96eL6VpMDiMFEtNhAcRsy/4e2O5Ytv5epikxGo3F6bfO5vmQ8jwT/0qnkyMRu+uGgTBEFocSPAPDG6qoyEJc0CSYyHOEjUjxYSYSvckvsjDaVOdhTlJ1wSp7J/DMRAEQmBgA2FVOAcLEzzC07HNG6azyF/+lcu2NXcXvFn4Ave6KziM3FqMAAAAASUVORK5CYII=",
    },
    "A27": {
        "description": "hastening man",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAABmklEQVR4nFXQwUtUURTH8e+8MWdwIpwQsbGVUmAaJROYQWOLamHUbEoSoUgxqEVi/4KB7ZU2RUVIEYE7IcFaFOViCnMxSEQ+8w2mYzLmKL1pnPdrMe/l86wun3u45/wueNVwa0Uv9+OvuvGFojaHw34bkiT9OQ8YLgXjTna+RLjJ12a8zhw5ntPyYV+fk609ac2WHpgAAW+s9aVqxOkD4OPoAQBCC4+NRGnjAsCEfrQBgae5vYQs5TuA+vu2dTNK9+rXi5e7vkmpOiA0ICfRsaaN3Na6LRWuAnCjsPx3Kr4092Jbkt7UAnDb3Eoa6enImNKT32fLMwOtSY7l15980qNo/MpO5H2fNTdgfYju+piHxX7uzdTssvmZGO2LZ3x56TxoLmFHWv12bnsUfq85QIVn1cHTp4IF56jvtVhKymQks3rHuos/ky0t17Lq/U+Rcd0FSG6+rfTsUF5dAAyX+jw7ITUC0GRPx1x7rlduzGe6Xj7sWdUd9/aS3pV3bq6S6ZpNewUQSvSE36dcayQLxtmxX9KQFzudG/wHZw2oEFKVtaMAAAAASUVORK5CYII=",
    },
    "Z9": {
        "description": "crossed diagonal sticks",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAAAAAA6mKC9AAAAPUlEQVR4nJWPyw0AIAxCicsxMuPVi788vciJkhaoKtaCU8qhOBV5K4MuhYSrplkYN+emF3hC098+93Ps0wFPYlFB5i8jWQAAAABJRU5ErkJggg==",
    },
    "T20": {
        "description": "harpoon head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAeCAAAAADBFYthAAAAdElEQVR4nHXNIQ7BYQAH0Ocbgdm4gWIzTdE4gMhBSP4X0VUXoAqqTeQGkijYjJ8TKK8+WKbgpT6qDJi9359Qq61SF1Hgv2so1cRXOW4XLYb3xzlskjC+Jage0ez2binT6/xEZ5d76F8SzBO09yk8Dwoaf8cf5L8sG5kpEsYAAAAASUVORK5CYII=",
    },
    "M16": {
        "description": "clump of papyrus",
        "pronunciation": "HA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABiklEQVR4nE3Qv0sbcRjH8feFC4GoUVJDjC2iLuoSWm0FBbWDheJmFhddBCGIFNvNKaP9B4o4FAqlQ2sOKSVgKahDoFBqLSJEIigK/kajg6a5752Pw9m7e6YvL57vw4cPAMGJ5QMR2c11A+gAoalk/rOuPRva+MX/ScsbIHvQ4wrVplGtpc0BfJORuUn7nV9o2ZHDvw3OOwCkct9GZ1XiQ82nt08AeL4mpvyMFPdbXorcfKmDGaWMztVV8r95LYWiGHF9SO29OqvfxNYQ3i98T4k+PJoxcoksNsB4Wz2tQGZfKoOsrDEtItsjMYCOoj3mkDXf4YQojJdeOJHWZwoOkTcaAQ3WS/dR4UckgNUUt0/FpXwsWbESgyeLuHT1qK+smp8eb3mk6SHrVnF97RGSrDUr6iNu0WD1X9Jzs4Jvi3/RaF/4oa/BcFlERJZ8H2/VUVFFWhvrLt2tzlIaQpm9x96tVNU5VMpOQw49+PMV2I22e2SdmoBxEfTOB2O9YZFASDxq7jJ0RCIA3AG2/Z1rTANaSgAAAABJRU5ErkJggg==",
    },
    "Aa11": {
        "pronunciation": "mAa",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAHCAAAAABBpmDhAAAAQ0lEQVR4nGNgQICYXf9xAaIUIZTF7Pr/eFcMA3YAUxaz6/9/nIpgykJ2/f+ORxFEWebW798hDniJx22ZW7/jcToMAAC3AJEM/O0q1AAAAABJRU5ErkJggg==",
    },
    "S17": {
        "description": "pectoral",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAABc0lEQVR4nHXSz0rUcRQF8M/vO9iQmY1lIUNTzuCitDIUKdz0R1oVSb1Db9ADuKiNT9AjtCqEoEW0iGIqQjFKqil0amxmyGomYUpT59di2hjT2Rzu5XDuOXD5i7Hba9M52zFenL21nE9vX9543u98abI1RAUdzaDZ1ywnNzONutDc3Iri6iJsSbCZiJDrE0/9424qjuLi6xBBM0606Fh/9Lm7q7EBKT9ipKxscLpyDVwvnYCbhQHB+8pZkE8Nw5P0oGDo4ENwrjYPE8sLgh2JX2Dn1nqLfgvmP14C93tPwb3DJwXZAy/AyGoBxr4sCfZ3L4LsWhVyqyuC2cWrYKZ3HO7kRv+nbOvZ9nrbnG0bvS2fAY9Tx+FR+oigsd4D6h27oZbcJRjpnwEXvz6FyeKc4NO3YfCqKwcv9x0SlGtHwbvODLzpSQtGs3fB5ZU8XFmaFdR/tv6iktwL5c6U4EN1HDzbMwj5vgHBUOYBmPg+BxdKC/4Aw/WOJhSg3Q0AAAAASUVORK5CYII=",
    },
    "D19": {
        "description": "nose, eye and cheek",
        "pronunciation": "fnD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAaCAAAAABnFqgRAAABfUlEQVR4nG3RT0iTcRzH8fceHmNBQZgYjoiI2EOJaJGHnhWBc0FEJkYgdPBkKgplXTqIENRtxIggCg912I4DY1HhQPES+Ge0gnCHCHeSROZFeKSefTrskT378zn9+L74/H4/fj/wJRJNSVLKOkVtKnNJGgUCVTi0z0rSCFAmQd+ivzKnq95qUGr1wQV9aDkTDlvngS/q9UlRk78kSc+m2qN6WT3ncZw1p+Sah1uuGJifj900PTgR/3fUiZ10lSyfHdl2E5noQeWnemzXu/O9LnCeeDCsZaT4ceCupMsoU4GglOHSN5Vu3Xgrrb8PkFuoyKz2g0Bos+xqAICHDgCd0uu6l5qWAdDKjwnqYwC84VEDYAJL564tNwpgaa1xOC2Dzu/MNMpf6HiuT002SouxDXU0kaLY07smcEdbSPeB7mStSC+QloCsHvjho1ZP81XKj6el3QnbBsC2n+4p10YgdH0oeLGQ3+mNHDlorP4pvPpd/W3rNrF+gOwC8wXgP5+so9IXGReOAAAAAElFTkSuQmCC",
    },
    "D42": {
        "description": "forearm with palm down and straight upper arm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAAe0lEQVR4nGNkIAD+MzAwMLAQULSUYRkDQxQTIbMYoqMZGAirYmAYvKpYGBgYrMPlGBgYGB6tPIpbnfWk/zjBi/8v/i9duvQ/g/7y///3T2KY9P/////fsKv9/p/xot7GRyuP9hVeuvtk5Z2XDOIq4TIQt0qbQC078+IcALkmVurpUDqiAAAAAElFTkSuQmCC",
    },
    "C9": {
        "description": "goddess with horned sun-disk",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABjElEQVR4nD3OQUiTcRjH8e/ejeaiFpE5R8oOMxx6CcV5iLAwslcWLLyoh8REQYnoIHrYDh2iq9R5GUUXk1QiZBkND0JjUluBg2jptE1cg5mS2/u69f47vNt+tw8Pv+d5AHDE3dR7ZSsTuwAwt+r9JEpLd+NDutvVQtYj/xTBk7p5I+7DY+0Oku4nxfPg+jyPSXf0+VS+1jVdoBLnDyEWq6J+WRHioIVKf2/bHMpYvdX5qbfixtVUUKr4uiJ+PexTB8o0hbKvJ3PXPsQa9HvGjui7ldNOf7hVbxxPuF7M2ElvyZUFTeM7sWHjyy/l/0hY0nsn/v25VL1wWU1o5AxSc38dALd3dnvQYPYwdRNo2rzn2Q98W0d8XNm/AuNFe++RMttFJNLw6quNp2nkwnuQHnU4xrJdZzoDpLNrwIWNSVqXelWZnkwbgD95jpHM90YGDp0AF5M+eDAKvqIZgPUwUINlLiSBBIY8oGBzBzSQGHQGAfgrFMDgeVa38DtvOTaevRXrLkFKFZrQk7PBf5NrmWII+usmAAAAAElFTkSuQmCC",
    },
    "M30": {
        "description": "root",
        "pronunciation": "bnr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAA30lEQVR4nC3FvUpCYQDH4d/71/QQHV0Csy8qlZZoaa3JsSVaraEtaOgOuoEuwKELaI7GEIRQokALwiDdkgzyZMThHNFTb4vP8vDzWr21x1C9YLNfhKOvy8eKCxufoT0HzXzvPfgOYnQ4P4yI+4nSOIzQ9N92ewqUvq95eYOyA57zDlof007Nov2AxmoBZVr0JBQzDAEBZvICIGvJSshJseN9oP4KmbcO6saIewG6SlPogV5ybngD6q7l/CdQ4JwuLQInv++2bOCutFVvzMEuHERnBiBZHhQBcK9bALDc/AeO7UgrdVVpNQAAAABJRU5ErkJggg==",
    },
    "A50": {
        "description": "noble on chair",
        "pronunciation": "Sps",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAAByUlEQVR4nGNgQAGMASf/v6oWZkAHzk+/903/v1kGTVji2r/705TS/1eiiRf8P3p1zxbB3YdFUYSZ397ydk+cw5B4V54JReLj+ys7n1tJPRTiRRH/e9lsg+V93tnyArwoymt+nz3z9tTb/9/e6KCIJ0yS4Hz16dq/W94YHkj8Waz/sgZDWOzILQ6GS+UMDKjuYXC1XvyDgVUPXZzd6O1KBgYWSS40Y8QfHOJkYLj5ebMCXIiRnUvKe+n/JiYG6Yf//kfAhM0XvX939/L1yUIMDHEfkxY8YoEIy2z4v/z45bv/vjIwMEj92eQsC1We8b8BZkX+3d1SJ/9D1Xu92l4b9ZOJ4S8nlxRDkpgSVBHTk02R3/5DwSMNl//vIeoNeY7rMa6+y8DAwMAgFDG1jeEiRNziz47Cju5vEM0/4gwZNkCYc16qXjSAe+7et/9mTAwMDAyM0tckPr2Aib+cx8kACWjDh+mL+pnhXpf58/8IAwMDg+D+vzavnBChJPTz/0EGBnGLxb+qfQ6yw0TF+t/9/3+UofrK/w+hDNMOsMHEc/////FmKcP///9ftvXfPwQXN3zw/5i/DsPr////////KpQRHuDhH1sZGABwYbjoAJDJJQAAAABJRU5ErkJggg==",
    },
    "Y6": {
        "description": "game piece",
        "pronunciation": "ibA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAXCAAAAAAaD/FjAAAAfUlEQVR4nHWOsQ2EQAwEBxdBGSTomkC6XkhPZLRBQhV0QUpKEejiJTDI4qXfaMa2bAPAuhKRADCAEca33tbzrO0ji0rR4pwlkDJAJyVIUgfMmgCK5liL5KvffCUFJ8sh+TvWB/cGm+MGNkRnMNgddzA4XI7fo3A5VWj077cbAwwnF/IorkYAAAAASUVORK5CYII=",
    },
    "Aa21": {
        "pronunciation": "wDa",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAAlElEQVR4nNWKMQqCYABGnz85tNcmDQ6u4gkcxBO0eAdPUHuzBxIFBw8QOCsITTUFEviHX0NUZ+hND94DIFUKYPjxt76wfD0i+rRcd+XvK1e9r5UbIJtaD6+dMpzL1tXNtRvHXh2NZ/N8rFdLuEMFBMcAChlcwupUhbgYrF/Oh7n0Lajpxph47Boh9TEQ9xIaEgCSQS8lYTsHRxQ6ugAAAABJRU5ErkJggg==",
    },
    "I14": {
        "description": "snake",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAQCAAAAABfdVLCAAABIElEQVR4nIXPuyvFcRjH8TeHU3JJLnEiYpCFyWhQShkoKSlkIUqSolgNJplYz2LgL5DL5JaF2YkIHQalDOS45G34kRwOz/Lt6fvq8+khPKA+D/H3pPc2AZnd/zDuVPUw2IpKU7C25cAB1PTqXKq86ZmpqC4AO6qDf1Q/eAkEuWOp2YtXUK4zbLgPEMkrzvqNjcCxjzDpHtCp7v5QLQqc+gIkDoAzL3TvC6QDkAuAAIRfYbjqpPKBSDJ7+9gygERdiBLy2CKUXNqhwLH9wK0T+fcuUqmtSWlBYQXrQIjbgmzixK9Zbfie1qXzbGo1sGRs1KMc6FFXgv/84KlV43qTCdQ/qeMAUT8nlhbo2fYyiI2vAXT2na9uJ4DCxnBzJDj/HYeUkiA4iUPBAAAAAElFTkSuQmCC",
    },
    "L3": {
        "description": "fly",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAAB8ElEQVR4nE2SXUiTURjHf+/Zq7ZeXLoyWAqiEMRAKSpIKVoYI8QsaQhREWrQRQhJXUQ3BUENtBBEirophRhBMYToExs4pLQNCo0om+Va6Ebtovah+zhdnJV7bs7z//F/nv/hcKBxJpdd6tQoVEtYZi/qrL318Wzvo9C1qgKdnr00FmnlzHsnWM7LUSvA3rkBOxVuL7+HNIDTmS6gef66Dph85HvU9M1+sH+9o8S4iG9SnbdxI02auxAsBvbUAjARd1g6J8OKamI0vwOA5K/Beqcvo3BKRNOGakPlx6MBCUDdosgFd5sBmM2dexVUjnYDqgNHACh9G92pqPGkSxCZawJgJX5/WuFDzVOA65lSdbo6yx6/sADV3g0UV1vqJAC3rwBgLVd47OkaBJCzA+b9wWCDCajcci+tIha2giMp5Q8ncCOggQD8og3qzWDr0Gk4OiILIf3vaszjy1LKiI1Tfuu/7IPpzS45+dLzMHZs3XMXgA7wOdR3gG29X4LDDs14vXrVYSml3DfhvBv+5C4BFQmeCJDqi2VrSkYy/5ewlCC5kPzTAoshVt1CIzE0Y6ooRehFGKjK5kMPapH5Yrf8sLIe/SpTnmQRzpd1X2i3d/zs/hZTs+rvGZd3+Q8vV/ps21vfFL+xMfg9IaUMnzAp/Rc0966SQSR+3AAAAABJRU5ErkJggg==",
    },
    "A9": {
        "description": "man steadying basket on head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABy0lEQVR4nEXP30tTcRjH8ff57hyXzQQrQ1rCrJGYGCaSVIRpu4gYg2kZXUQQwRG96A8wiqAIIoTujC5SCi/sJgIvKhqBlZQ5slIwdfPCNMMNZ2VnunOeLvajz+WL53l4PpCNa1hEJsMn3eTjvrwiiejYx3hbgQ6sidz17T+fuFmgiIjM1FITa8/LaVsexSXWOZiuzEl5TPpLX8jqmlh7ctRpRbYzKguB29ZZUEDtVfeHpK7hvbe+WA060Oh1orhSo6vNNzQnu3dwSj63aNEgw5IJ5W6dWpbFPpnzBcUqyT/RkhRJRPeqfmegOG/nZq02D1Rct+9szZE6NJFtNzZXVag08gqgOZk2VZ5WSoEt3WVFRwpTDS+BUOrN0oICLj0+AzOGG3zbnk57Ac93We9TRekuMJ2OW6KgdTcus3eHVY5eaQ+l0WF61v9840pD6g/1poODDt/G/cvXKo4TKG7f+XtXPYAalE943ovYvzKp6q+iwIngr2uyM196TsSNMgOAsGxOyo+LPrwT8mDjpwIEfd/90MA8ol6PGHEdqOJv90PACNa0blrjGvie1c33oMHRLob0t71aoDF8mP9xnrzTzAvHAJha0gApaXL+ASX9uMSuRr/5AAAAAElFTkSuQmCC",
    },
    "O32": {
        "description": "gateway",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAABCElEQVR4nL3QrU/DYBDH8e91z0gFgmQZEJapJowAcmISi5ggBAkBBC+z/AtgERgSNG4SAQZFUCD5BwYOUbGOtX269kEU+oIgKM7dJ79c7k50MEWptK1Gly9RkaqrxzLearatnJLnt74ybNTf5ZvMbPPCKGTydJjnrhqCAoTNpTRpbkNAAXC0OBIgqbs6s/ChBzDdH0pmMASIKwJQWCNrSsYvJlFcgjgSS3ecIsZOR1vstoo/iFoHqHm5swtmP64nKuDHvPHfd/k/MwCEaZP+VBbOOHW2TVVyG6ztNM6XTwaha31ZQo/2fUW9rgR0U0tq+8JciEz2tKml1994fhB47kzX/wh87xo+ATiPVh0RCFXIAAAAAElFTkSuQmCC",
    },
    "W11": {
        "description": "jar stand",
        "pronunciation": "nzt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAAAAACRecryAAAAu0lEQVR4nGXQsW3CYBQE4C+uXHoLur9EpKVhg8iSWYI2A1DSegG8CmYJkNggG1yK30QonPR075307qQz5B3Dh3nj6gUb108k5UUsCY1/+KnUJnX5rpS0zxd4UoqGJWwwsFyN3h2cncFdr7H1gK9lPGyRuaBLNkmHMoeSCU6J5ARTStNXg4O9vUO16E0pGJNOl4zq95yO9q8YdJnltq5mSWrE+hZJMu1WSwur3ZQk2uNbvccWynj5Uy5jwS/yv4v8GIS4mwAAAABJRU5ErkJggg==",
    },
    "U15": {
        "description": "sled(sledge)",
        "pronunciation": "tm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAQCAAAAABfdVLCAAAAqUlEQVR4nIXSIY4CQRCF4X+QhANsSLhGn4gLzDougG+H4RgcAI8iGBKCQKxYMcAIRkDyI2AAMaGefPlSleo0ZJtMlAKEImI9+IVJOA6KrGUKUAKmRiG/XVXr9dy0eZmqWeEsAah/gH5uUmAv9Dl4mSZK9dTNto9qos4V/7vZ+lmlrGasu9mhrdIivhQY1KasHr+z7Jik0QtbMXZTBupHdRf+ktHSm8Pv5g4CzdJK067A9gAAAABJRU5ErkJggg==",
    },
    "O31": {
        "description": "door",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAJCAAAAAB7rAGRAAAAVElEQVR4nI3MMRGAQAxE0Z+B/kQhIK6QgYN4oIoJPDDnYCkY2oRttnnzbQ5+bJ3jPju0wZ6Kjk2Bp7xEuiTAlTVTBECTk95vch8jVQ8MwI+lyg3jAX0uPU/Muh2wAAAAAElFTkSuQmCC",
    },
    "D62": {
        "description": "three toes oriented rightward",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAcCAAAAADDgCm6AAAAn0lEQVR4nOWTyxGDMAwFF4bSVIKpITVRg9xBUleujwMWQxILuOddvIe1/BkJwCUHEorIkVtGAFNbC7xy2vdJ1qejBZJ1CWBsptvAI6WwytNPKG5fKSwphcVs8aAO7dbh0b80cif/YE0O4BDd90FLfJikt9LYbuUHSdGvF9bW/oOoqVWoBerc/DS47HuYOnFxQzP56dWPxS4t26bpuph8BW4Vs6k3YT4aAAAAAElFTkSuQmCC",
    },
    "E15": {
        "description": "lying canine",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAAB5klEQVR4nIXSX0hTURwH8O+5zTa3tc2m2wKnqE8ha5UKXiuayUSwl8BQwYLqIXroqacegowiCsR/1IMIFTTooQzKItApGgRGIviiERKGMuyfltNdd9v99uK08N7t93QOfM7vfDm/A6TrbPwW9EvaWtVbK8wGaAtPMBXO0qfKv/xnI4s5t+9mwuCutDlwSOlXhL4xAYDPVXXVf6PRumoct2ngfXKwFRF2Ggn/w3k+a3YAh6Px/QaBzpOceVRXDLTzni4RolRWJO1Igzl27fPLkva7xpFsFcfuz4UCE+uRcmME2H9EEVzkwkAALZOzH8eLJB30QjmO4h7y17cESf5c6svbYQYTbsCc53IXuJ17yg7WvEqN7bh4pPufTeEHqVphn+0/YfJ8vw0A2GVxFuSHo2tnPM8ZaxDYnAV27xX1d8QDwO7giUB1UPEBHaYEfBenlgAhp1TyaJspmHM94rWcqtOK7OnWKy78Pj1EiHcyQAEAwx5/XFFTb7ytOdsRHl9egag92ZQECQjz66cxlckv3q5KDQAoCq1YDk1DILd2HQAgMLp5trREIwBK4Usu9F5RM708bF0K1ZDBz0tX+RQ5lJvZOKKk5tQb3HatPfkKcSFzH8ifyIUsxvKWZBYDeZ7MnAdY3AD+AjP0qFjexoICAAAAAElFTkSuQmCC",
    },
    "U27": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAAbklEQVR4nJXOsQ2CQABA0XfHJSxgtKJlANFEF2AJ4wgWlMzjFLSU6CbUNFichS5A9buXHzJI3i/nk9zT56ikFMGmrKyS5qYRfnQ4errDNJEIG83/oIyoOuwrcdetn26nntt2rtMyPoyL4jIM1+ILhngZi6QFQCkAAAAASUVORK5CYII=",
    },
    "M22": {
        "description": "rush",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAAApElEQVR4nGNkkCpVYjy08DUDBEh2fPv//0mLApTb9/VWfNn75/lQ7rrrVgwMiX+OQLmMDAwMDLx3LkF4TP8ZGBgYPn+FSjIhqUFwGQY3N+L+wxZmBgYGBuaWh/cjGN48vfR/gefdu54L/l96+oahwZC3+sSLz59fnKjmNWxgYGBgYLB6/f//ayu4AYyT/v+fxIgw0OLVKwtkCy5cgNAsqNZT4mYAECQ5WkUecWsAAAAASUVORK5CYII=",
    },
    "P3": {
        "description": "sacred barque",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAAAAACzJtCvAAAB/0lEQVR4nHXTX0iTURjH8e/WpkucuK3oIkSRmFEr6WJBf6ToRmxXZTSIwsigMiFo2B+CrrrTBUUtuymhssiWRSCKUV2IXUQ2uvJiFWTQhMJm/6TN99fF+74bjPncnMN5Pu9zznk4LywdScnYa06d0Q1LMh845iz2YOr0UmyxOHXiim8vr4IGYNgM+gqZmsO3B3rqV4BvMHRuxAHUWRlJL2y1blaS9K0JT1r6NKTk9ESRyboOv2RspmVW+TqC0geXDrD1754Cu2SxnCIAV/QOsjL4qjbasvEITiTpol15vzkOq5pxqblB6iCc088WpN/qtVmrOfaolkrpNcQVg4P6jnTTyJpZV5fFV8mPT1I7jMvwNCuDdHK3+s30oMX8CsCEpIWP0pAnpWtIMTK6ZW4aMdlK1cK8JOmPl/ca8DKtOHzRyPJA5X0dMlm3ICopPx+j5rOeAuFR9UKHzDgC0JRVSpLUAFeVWgPgrr+hZ+A5esaEk8OSpB8nTvlxX54pNpULmtkGNK49a9U8HwyvBqoykmQ3E7x3lE4kSh5I4p6U1N1jegs4ANgyCaQdL0fdAA63Ap1VjfC4/XlofXLHw6j15S6Vj437NNWnV+ACwEm8wlmyKca/WOBR//FNVNsrXQulptDu1idvdlrVvNfprlhWihZz5GFsrLAQmit/NPv3g/96Ezbo4b4nSwAAAABJRU5ErkJggg==",
    },
    "D29": {
        "description": "combination of hieroglyphs d28 and r12",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABeklEQVR4nG3QPUhbURTA8f/Ny8dTtFFQHGzroNAOYu0gtm41IGIXJUMnEZG6Fbq2a4aie5vBUgqtUKkuTg5dBJcgqC2tSF1CmlAiecT6nby8dzrc99KHzVnOvT/OuR8HANo2FqnH0xdRQgDULkaGezVG+rqfDXgFLSuSXdLLns1fMkfYb721pnP0fiv+IcDVD52lBrV/rEydyznOsx4rUI5mK031ymMRrKLX1syXfY8vD/lz7rHw0/LYOcGo30IU/0oDVwhEvabJ54rm2EwSDG4+0fp4CiBsTL+utL8tSfhN8tjAiY92EAOGtgsZazaeOrsUERFxTvPjSqm1RHV5Prax29M1BsD+TqgQFUTkxJFg/D6wRb2/Nwh8y09QXE3ctdZt+3Px4SPM/ne2yPPOVKn8IO28ioQUYALNE59ethCZlI9bR3f++9PtrEjuRlBcgMJCKfDpQHyQXNv1mQAZu74L8rGrGnFg5EHeyzas/vq9IWMijbjs+g/8C9J9kEgxaMshAAAAAElFTkSuQmCC",
    },
    "V16": {
        "description": "cattlehobble(bil.)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAATCAAAAAAy1ptvAAAA4ElEQVR4nIWSPWrEMBSEvwTSreut9ga+i7oUbt0EfKBN8XQBHUu6gHkpU0wKW2v5BzI8RgOCgfdJsMr0BEz2yk8ZB/WSeoIGhTUvvpdpkmGZbDVrOpW5444LqWbHfb19X885kWbmSCw1J9J87GpbhJbZdd1vpEKJpG7q0ppjoSRu92U58+wW2u2WHDQoBPPs1r+JnzSWR2SMAOP3B9QcGcsjfnagCWDQtQaASU3X0rL579fW1ZtnWaDhvTnBlN1eT9Dy/pf9aS7Zn/ySfeMn9lDZN76w36vhvfOD6i89OgB/z3ISPgLJP6YAAAAASUVORK5CYII=",
    },
    "D17": {
        "description": "diagonal and vertical markings of eye of horus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAVCAAAAAACprM2AAABP0lEQVR4nH2QzyvkARiHn/lOrB8pW9qSUC4Oyjq52eJiDv4BDkJZJz9yUMphy0mz7MFhCzW2duOElOTix8VBbYiDSGn4BxTFmDwOM9ak+e7n9PZ5nt63XqD53kSEsARQVEJrY6gA/FIv/sObvD7TeCiv+ubQhKYrwoTlVIpZdTdM0EMWVKP5eQCLFLIBk6FChAI6fjM+FnZimCWp1rvivBsOqQW4bqf0b94NzdsP/BFo1dN3LBKF4LHomRTATg8NsVw8evOcPvhIca+dUwIEx7r/xgdVnYGYZ5dmulvdC16FuKrJgFLq67LCd/hy/iErFDIX+Uo1RHc1nS1jJ3rUnZlrns6nVxX48SYQXKl9mbkrqQq05QiUxbZ0c2vgMzCirgCVGe9fxlWdH0yoO5+AaP/6z/Lc97TE15KqXs1W8gIVzJy1EhVJhAAAAABJRU5ErkJggg==",
    },
    "U1": {
        "description": "sickle",
        "pronunciation": "mA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAABVUlEQVR4nGNgQAYc3////78WzmVCkWRgvjT9JxMuSdadWV9xSjKwMTAy4JREAaRK/scp+ZeBQYgFl6QY+wvbVnaslnD8++Dh/+H/4kBOLJLMO/4/1jdc/v/L8U4NZgxZ6Q1f/pyMM9r55cef11s80WVZnLd9+L/O2S5+w7l/zzCN5nHd9/8IAwOrw9vn2Jwlsv2pOgNDzd+VWB1t9dKVwfjlDxdsckrnHosYXv9Zic0/8hv/55rc/ZfFhkVOfP2rVLMb/yuwmel68aqD0pPrkVik5DKerDI2PjNXA1OKN+7yqwKOhofdmBEp3fz2QaeKw4ML4Rixoln0/8Ekaa/Dj+fpoUtJdN77UaPtv+b/TBt0Ke7Oa/87DCwOfJ1pwoouF/ru7nwJqxMPt6twocmIBLb++tkWte7zGiNM52/9/P////8PitwwpRgY/v////dShyo2KQYA5ZiCLrBK5vgAAAAASUVORK5CYII=",
    },
    "F20": {
        "description": "tongue",
        "pronunciation": "ns",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAcCAAAAAAot5K5AAAA0UlEQVR4nI2SPw8BQRTEh1CfQi40PoFErdRd7T6FApWCSiWU6qu0ol8FhcK/QpQSvoBQqbmM4kLj3M40m335Zea9twu4G7IHmwo9klYKOypm0KgUcV/8VEMg+5zhdP5imypwc/+YTNbOdv8CgPqUFg3LQCrWpQz/6Zfyn2t/FI9F6g4AXA5O7tFJHjAgG8lEpBWXGQEzygsBHukp3JRGwUxkl7Zg4+iwYZijLaYqmHcMpVmPNEJvuCpeQE3cMGmEUMy11Aqp/BIEbClYUdswmuEbDK9scVW7LYwAAAAASUVORK5CYII=",
    },
    "G33": {
        "description": "cattle egret",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB3klEQVR4nHXTT0gUURwH8O+uu+Iuqy56UFjQVaFBhfzTJTutDaQQYohFrCjqTS8lHoIIIbx0KkISZQnqYClZB7uooHWwjfyXsvgH/21q2ua2JkxsO9j47bAqM874Tt/H5/feb+bxHgAApaJv+iIMhgVAUa3ozEirCdCowOZdIilv+ExGmt4nk9ytfvPcbMTDSy9H+LvYEW40UjxwZS1LjXBv+zxJhgX10i3AXjkb/vSqxICvS51OAMmeVcqfL+m9k8GGXADWe+Pcv52o8+a3/FoEAKa2UfZ7de6oigTifdOrgvJ7UVeQ82PhQjxlzXO9QtehcGvoOGUv8qhL95OX9x4ep4IJcqD0rHfwqT2e3BPkxtkPME+yvyQn2WR1512ZiXH7jk3rnl0eBAef9ISiWx/3SXYJGrb2kSTZXvf4O0kycE3jN+S5KR56AbMwTZJc1rDI+8/oTwUAV/dfkpL6DtgqlCEH1g4BYKf1bgQYs6g4SZwK25V30fisdy7zaFXNQuELKSFBPpl+AaDevCb2OmqfX9echSpf3fwGm3/lHC4vWNk0Q91Nwy2WXpionMNOYdYPRcnQLLcASLmZz38fyoTuYqsr3/FoJDYTVZc0xUj++sNI6KdEMhxqO31P/wFPecjS2oHZdAAAAABJRU5ErkJggg==",
    },
    "E1": {
        "description": "bull",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAeCAAAAABlfzOyAAABaElEQVR4nH2TsY7VMBBFzy4V1fuKfMNqf4CSChR6IyFtu8VWRpFoKCnSIPEHpn89n0CLqChCF79qy0NhZ+O85WWKxLq+M3fm2qYP1OiVi6FzXSXTZRqj05Kww4LJUDT7XVotk/MO5Rp4z9z3+fBlvxiorqNcjORI0t1JoXeGXtV4s6dJHPidOpLm4bbdex2PFieSI8aCvptKn9mcXSNcgVy1+Tev7g+nw+nxK39+/AII3wCiEeIwFFIOPAsV4lIZYFzUAWpGKHtq6ggGzs51ypTeuwbthOhGMycAM22ygWl7SapC2tCSz+5S6T3i9Yq9RTB2De1EaW9jWVvq+88XH14eyvrjp43Ik+/ZrJqqVxP/oc0BYM5DaU71nDZ2c+svqFHThmZePis0Ug/rKXoHYG6haG2mMeQNj8Bnmgd297f8N36UOsuzBR5Ko2eaAoQGPFrImyMtZaYVrPubCaY6ouslOdoBmAP/AN7aEPwGL+CbAAAAAElFTkSuQmCC",
    },
    "H1": {
        "description": "head of pintail",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAUCAAAAACl/DKWAAAA/UlEQVR4nE3PPyiEcRzH8fejB93x9NAVi+Rk0V1JskjkDIZbDDLYziCDySLiViUZ1bPcaLQbr2ychXTbSd3VFdHhuKee+xie+/P7jK8+n/p+oZ3BrV/J3x/tAAN7D/qq6fW4vy3rzyqfFy5O6toBcNLzZ9IRLOzifBSIJLK3klRp1TdErqYw20kA7gLUTSMPk8rb18Pgz44A9C2dHi5TxQIg5rpur6ss0pwtAN4BkjRz3Dx2b2VCxXHdW4bMNLSaUcQQ21eGl6IhHMhjUQlDpvQX5ycA6GnRJl6JaGCUxt4E6NtopWKf4BCdBuyQmgx5T2tYlyudYaoUfn4F/ANn/28liIaLBQAAAABJRU5ErkJggg==",
    },
    "O18": {
        "description": "shrine in profile",
        "pronunciation": "kAr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAABCklEQVR4nGNkYGBgUPfz0fzHxflk07YLLxnggJGBgUF1o8TWM78ZGPRNjM7v33PhOUJW7tCHGAhL1rfr6bdTUVJwKYc3voxwjnLxmddPVwawQXhZrzgYkIFm/+XvC4N5GRgZxFfaL72CLPWXRcdT8OOuqQwM8b//YwXXWRgOXNW0ZkAHe3lX1TMwMGR8waLnrBIDIwMDw92fi9B1VW+E+OfROgwDn69gYGBiYGBgYMGQYmSASmEHo1IkSP3HIv6PgYGJgUGf/z8jBDAwwsAfJUkGRgb9pdoMrxgYGBgYGL/x8EM1sTBsSmc0miZ04B80HTLCjf7H7XmSZY7h+Sd/MO3i/+7NiM0NEAAAmL1xrGF/ehQAAAAASUVORK5CYII=",
    },
    "E14": {
        "description": "dog",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAACKElEQVR4nIWTT0jTYRjHP/O3OfPPkh1UjKiENTELChxFmto/CFGzwEqIQCo8BF3y0CGIOpgdKrBDUO1Qh6KQCnZoiV0qyqigP4QooUKFpgtaTtG5fTv8tt8WDn1O7/s8n/f5fh/e9wWgOvJtu5Nl4qgUOLgMUyJJMpaGeiRJu5ZkyiVNRlS7FLPijdTDDrVmLm87W1NE3nHFP12BmNyZmEZJt2l5pXrHYxhSSSboneajX5nWGQDy9cuVAfLr3jFlDYbXjWjOx3TOzJ/LixXbc4Pl2PIizafL1rC3D0eogM6R3NEXQKMrBoCiU7vPjZl8jZQP7PmhTNFlM6khz82TAKtz4obDRjwakxZmyHYFPIxtSUiXam6xac9mqJO6knvXgjak112u96HfUhN1GgC7mQzve/ZgUyxB3FhfXGGu/iLCFkQfFZUfX2+NGEbcCTAVj9lKWKCAaJpAg1R6ypymbaOvEmBAFfWSjqRRwwp91vdiDOth9cl7X9JFSw5jLW431yeIWccMnngBB1nJTI4dUhYT4QVoT91ps9T0UKpKQ56bFicKrU53YfAWrPy/lf8QFHVY25Dm4aXq04ig5Oaa1JtMVEp3oF/VKcYudYDzi3qTcoVwAmwcSEEOBvww9xNruv1MRmEGRwpq5el8ur/aoOSDw7PaaeUuyPxlHxKeGiRdhTZp1PoN3VIQsL2Veu0A4UfZw+fBMzvYPZ5gylYF4pegpbNqvN//D2QhBsvbWn4/AAAAAElFTkSuQmCC",
    },
    "M12": {
        "description": "one lotus plant",
        "pronunciation": "1000",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAv0lEQVR4nGNg4I98///3u2ITRon0jG9bv5R83cSw/8dqfaa2/4vVGP6flWIwf9/Jx8D0mkmM4eGBqMlSDOnvr+gLa+79v5yBJ+/PvVNnfi71ZGDgMN/x/2AtOwMDAwOD1X8rBgYGJgYGBmYGZigLAujMupHI8JvhN0PiDYaUx8HB/4ODHyczMCbdvP3/9s0kBgYG09f///1/bcrAwL/9e7pA+vft/Awhb5MYGBiS3oYwXhLd/IeBgcX3NeN/mHkAi9hGbMH6G9MAAAAASUVORK5CYII=",
    },
    "D48": {
        "description": "hand without thumb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAJCAAAAAB7rAGRAAAAx0lEQVR4nGNgYJCyPfwfBwhmgAIWBsYacyMGBgaGZYxMDAy/5OwZkIDRd77/zN82MDAwhvnGfFy8n43lwxaITCDnPwYGBgaG/8xxGvIQoWsnmxn/MP/kYMABylg8TOu5flj4H2X4/38aLlUMDAwMygwMDAb//zMxMPzGp+wuAwODFgMDy/SIvM8fu3FYyvOXkeEvZyXDdUYegzZbhmd1n5jRlPwOU5GQgrIftzEyMLC6uIZLoRvEwMDA8PTKr/0fGRkY/ux+BgDI3Ez/9kLKfAAAAABJRU5ErkJggg==",
    },
    "O46": {
        "description": "domed building",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAYCAAAAADSPvLtAAAA40lEQVR4nGXMLUtDcQCF8WfXuSQIQxAUFGyrTvYVtJhEFMEwMCg32gQ/gFFEDHbLogMRLCLIQPwEYlnQMBDEFzZkewzbvffP7kmH34EDwNT2j6qPK4uMstZS1e712RCmL/Wr04xP3r71fqcIbPk3Gmfv1AWo6FXywKGeM3PsC1mO7FN98CAgTo3mJtoXIbWg42so3Ig+B1BqKLqfQu1JFd1LJFbff0OKtTHPrsXsp05zE0pEqaxWB+tAIaB+0jOS23GCdp428lROqTdsXQYAPYpQWSoDn8sMar3JjwoFGU+UE/4BeUFlmVONJf0AAAAASUVORK5CYII=",
    },
    "Aa4": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAASCAAAAABtbOE4AAAAlElEQVR4nH3QsQ3CQAyF4V9QJxKiJSvQp2cCVqBnjkhX5Go6esQ0WSMFrQV6VDnlfAeubD19tmQA9pPYUtbmfIL5SfhUQiTdjzvpWgsfk6TbLF1qKcNLPwqAPvwJoTcFt3A0W9qgtwvNxqVt5Wg0a9IQ0okCQpfTaHZYjTnNoLuaXfTUwYwWcE0LCG36WwkhvdgiAF8V5oysHVhP+AAAAABJRU5ErkJggg==",
    },
    "Y8": {
        "description": "sistrum",
        "pronunciation": "zSSt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABU0lEQVR4nF2PsUsCARTGvzvOi0jRAifB6nRJRbjNRRBqKiMQbNHhUBclsM3+AmkxEMKWQBAEaYv0cJAWdXGRQDwCUXFr0nAoQ+41XMGdb3nv/fi+9/GY48flXFSuv7Bzd9TftaSYHvuwFG8AALd9S1pl+Vp4j0c+Hs+D3wvXeEjziNxUokBUacqRuQTnqGNHvQAU6rB3Rk52lnAVHYof8CuOoisxAxCiSrANtIMVCgEAkKNkA2gkKQeAAWB9Hp/c46olXHxqCkg0KJUGJAEA4y+tV/vVpzGEy9iM5zIQuj/U2pLTaXn7lVZdAcCZ0rNxqRRn672daifEYdmczZrLQ/EvBYfV6QvOD2IT/JdvoqoTH3SVIcrod7iJ3NrEaW3xjoUBqN9QDYDWIAPQ4vUKdUPBmsAaLbRhMVlhMgCPE54PzawBL8N4oQcBhgkYfpkSTbXpF1w1dO9SNrbwAAAAAElFTkSuQmCC",
    },
    "D57": {
        "description": "leg with knife",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAACVElEQVR4nH2Se0hTYRjGn52d1Y5lLHVplyFZdKHSshtoFkWSZtFAGplkhRZSuijoQkFEUWH9sTKhJELIAhXbiqKg7LIK0rTwMlyZ5TCpVpGcXXK4nfP2RzrOOZO9f33Py+97vuf9eIExave1uWO1paVv8l/VRUfYw0NeupcQlcl0fS3/SLaoL9U8WoMy8UMUJKH2RSKSbwXMkt50tQyJPR0sAa5QhzRPXfXRDImc2WbTweTu3SS9aOGpq6p40ahc0X8Q6X2UJzOfbCYisbt6yX9pFIpRyL/USBFmsKEZd4tce63PKjMAsMwwmFC9KB9ElfO7p8Cw/vI3GrDt0q6jC9jzfrZyWnazz2lkYgxlTvK3WsmelOs2qZQQM6vBWzUJbNycIy6RgvY6/31OyQDxtmDbUgBq/dbbPlEgoTI1wgnxx36GznIAwGywfAoRBQ5xTARV+oUuLYhhAGBe1UOeqHNnljaCauTp+vYZGgYASuztw+S7uDJGCRkbPdRrLkhJ1HEq4Iyjn+g8B0AebceBdBXe9f/iQ07eG5iwb5X+ZMWw0iq5ljqsXnrS2uWjB8ezygbpxPiIUGv9hWhu1kwxGM9VOz7nlXsoLYIxdqYmdpvHAQDmv3Fk7R88pVEyW1rilv0YXahtofbljoFMxUdxJkFI0Y/ebLqRVto3LV+OaGuDr7iKP+GNS3r997vglCE5VnLnMzWthnAn+y0RsWG5OHvhRt0dS4soBoRw87lpNRs7cs592tvjDwkWDshxP54q8VarR9JNvElERBTgPZ4hdxELWf0DnwfuQmy0A+gAAAAASUVORK5CYII=",
    },
    "U7": {
        "description": "hoe",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAASCAAAAAAWSCP0AAAAz0lEQVR4nIXSP0oDQRiG8WchiCewTGm1RAgkQiBYaJVUgpLGS1gMeAYvIEJSCuIFUmj+FBEEV2xiIRapPUKqxyJrodmdfZtvPvjNO80A136fUZUnXYx+l4lOtsmpsWxMYvSVJJ9p/3Kphi4AQUPJhQf1ZnO0vPr2S7OLCsT+h9qrQDBQsyrE+btmPT2IKl5UHcYRd6pOQyuqmusilvxTjzT2AJiN569liKtjOAHgebz6fCtGAJ2jdqNO7Q8sTCtM859wX9yUJ222D9Pd9U7yAzA8fnrvZSvbAAAAAElFTkSuQmCC",
    },
    "Z3": {
        "description": "plural strokes (vertical)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAAeCAAAAADI/isbAAAAIklEQVR4nGP4z8SAAjczMDAwMrxjQBb/wMDIwMCwiQFNLQDT4AZt/jn4VwAAAABJRU5ErkJggg==",
    },
    "D38": {
        "description": "forearm with rounded loaf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAAw0lEQVR4nH2OsQpBYQCFPzfEYFFGygOwk5TRIHkAmwegzAYZTBZZ1M1kUqabF5CUbMJktTEYJPkdgwzq53SWU1/nHCCcmaudxK6YJ7kJILWSLqMfVF7SsQ/xu3qVpcZ2ypM8iVhHZQjJ2KmTauxFbrEFaClipdSFupxBdvLOOXvZBsI46U+c/fgP4AdRzXL5wwBSE2OMMWZTtL13oS6kaRSoGquukktfPsGu638wDNqWHAAOvkahxBOA8xpuoW8HAFi8ABCCaF2dJA9HAAAAAElFTkSuQmCC",
    },
    "R14": {
        "description": "emblemof the west",
        "pronunciation": "imnt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAuklEQVR4nIXLPQtBYRyG8ev50yknu5SspMSsGFFiNppkYvJJbJJPgdWocwaDl7Iob2UQC4X0nGM4ZRJ33fVbLjAaq2tBAVK6bM9HA0TSbrVyDoCgmWjDAUGE8uwG4mgJMXNBnPGl+MopALG70WUWBMdOHq55ELAjnbgGIDhytwkQkDWDPShVazx34WCvT33YMjGbk7bazJeGeX+kMmqqE7djjIUPsGwsC/xejndv3+QHwPdR4aPT3/a33k95O1dUdG9HAAAAAElFTkSuQmCC",
    },
    "W22": {
        "description": "beer jug",
        "pronunciation": "Hnqt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAATCAAAAACBnrN1AAAAfklEQVR4nGWNMQ7CMBAEx4aXuTG/yCci5SfpjM4dFQUdBe/IL0KFI6qlMCaWmGI1q9XpHKLhjmSGDDUAJTABng4PygsslzdA0ggwyX4Ok8ypvym7b+ja/CbPs5X170+HXqFKLMKUajEZ4TvFokibTIYjPDhzYOB0B2ZJkmb4AFoYONvnyLsJAAAAAElFTkSuQmCC",
    },
    "A34": {
        "description": "man pounding in a mortar",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABzElEQVR4nFXRT0iTcRzH8ffz2x5dS33UVvinsYKQIGjiwYOHwEooIqm0CJROEeHVW3VKAi9lGQSBiSAZFJQQBMv+YAZjBRkNhJwaVGtPc7omtXDP8+zbYU+Un+Pr9OHzgf/TlpZE6wapHndEbm+gUyKpuW8KVJUrZZcgeRcF4RsuyUp2sKJ3s4K2oEvWkPY+vjsFKvI57FpTZuFQ5jU0m3ZXSXz3Vjs8k+8UBcvTDkDltdMzM05GAybkx4ABvqtFmd/B6CxwxBZ5u1+7bBWuR5sYmfXCr/Xz2YnHa3VW38tmrWaPrTC6ynYuxfx1XBkpNrRUb3fgnCO5RZGPA5WEEhcbE1EvC6uBqvTg4vMvNlgH/PU+0KbkybZSsVBccikHOGqdddvvzSSPdZoKXsTyLoW2PJhcRsHvZb0k+gXnFT1bFdTuK3eXqJ2LoSvwDUskqABaM8l6f0wYmy6KfLilgH6Rp89EEBk6eSIS14FRsbO2CFJoge6oDkZU5oPHV0Th8YJPAw6GWVp7NIb6d5lRzqccD021rv2lgCq8AdtRw3mBvBTBwJyGM43eqZ7DFcVOj7Oro53xr97ebgjc+Zn+nr7ZEClIvGbT/ZyYfwCp1MMJPrIfwQAAAABJRU5ErkJggg==",
    },
    "V25": {
        "description": "command staff",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAApUlEQVR4nIWOMQsBcRxA3/+H5E5JNrFYr0sGZbPcF+ADiC9kMkknu8TKB+ADKINbZLiSLLrE8f8bmJne8l49gPHFQwDQiF8HQHq++8AgA2fmprKQ6cfGDC2wVya4OkLSmvd0E9pxjVEglM4HtmUhHcaET0HnBDshnCp5qjdhs+8WvQkwjRamAbTuZlkA1PrRQcDsoiMCKKO+P/ykqI+nvnxp/bd7A55YM1yVIGS1AAAAAElFTkSuQmCC",
    },
    "M31": {
        "description": "rhizome",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAdCAAAAACGBrNjAAAAw0lEQVR4nIWQu0oDQRRAz14hVgmptxK7VCaV1mn3K2S7+ZD8h5BWu81XKJhKZNv06UPwWCw6GSNk4MKcw31wL3RCJ9gNgRYR/HnnIgFp+CcgVV4qYWXKkFzFjiaLhh21J120Ph87KXkSy1Iso2GTcUOD5VjZW2dRu49p2WMaMMo4goBDFl//3aM/pSN99MyymNEH5bbEJw+/XN3zwY22P6LVW8bv+SBHt2NA0xyo7pKHK4An9bl9fFHXQ+b8VVXfFtfwDQb7UlTAmITNAAAAAElFTkSuQmCC",
    },
    "V9": {
        "description": "shenring",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAAAAACo4kLRAAAAkklEQVR4nG2QsQ3CQAxFf24B3NJkK3dXULBA6iszRlggYoDI6yAGyAaPIkAOcr+ynvTlZ3fa4ldJt7uq+AwAs++sADFNAZQPGyCySZYDhi8rto02vqlXHWkElzQTtkMLZskh1yIXcAWL1dCCJUnPtYbrQympkST1p596r+OiDN5WastrgHL+O7P9kOPrOtqex7wA/FphTuG3eAsAAAAASUVORK5CYII=",
    },
    "B11": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAACDklEQVR4nGNggAHRymf//y9WZ0AGGvv+b+qd/30vJ5IY3/L/f3b7MuT+ykISdPl16srfn10MK7cwMDAwQcTYsi6xvYl8b87F+BohyMj563jdqtMrVE1/IwR/njIL4g8Q2M7wl4GBgYEFauYshsxVPw49MGT8j1DJ8PLxfXYBRsY/v1kRgky50eu/MnCxPtyvqwV3UeNp296//z9nM8S8SYOqZE4N6DEq+veYR4bhBwMLVFA9aw17N0P7bgZpbU02qF62yqdqn9dFzP7//9uNd7+iIIICRyvmbis59Dz20PvvPzv4IYKChy+bxzz7nxe1W//SRA5YCO3+f+XpowmRJ/RkHljBfPR5KpvigQUy5avuSv/7ChVklfC8VSmeI7O59+f//xZX/zAwsLBHejBvfDCV4ZfUyp8M7944Lv3CwMASPpfp/Zu8Odfliq8J6AoJSLMyMDCwmDG9vvA2+jZDkkKukT2H+PP/DAwMjGoBe6/85Iy29pB4f/M8c8gV/w8QJ4lH7H70/PGCVE0Ghr6jghDbTWu1H9Y8/HSegYGB4R/U6cZHXlVJMQglFOXrM0hePcTHwMDAqN/GJXj/ObuGCsvfu9f0TJ57XGJgYJhzUz7l6dsbTeG+8Zf/////f6sCAwMLI5PffS/eLyYGrALiD56yyrsumrqF0XqR+N/L/9h0Lr1hernoBnNGDeOXFgDbsczrHpAdxgAAAABJRU5ErkJggg==",
    },
    "G6": {
        "description": "combination of falcon and flaggellum",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACZklEQVR4nE3QW0iTYRgH8P/8dJZlc5Moy3OZSUyniWESgRRFF3WTSg0XlQURRrUOkhKMJLwoysywCA+LIu3CahWRitlBZFkKFmtrmomHmqd5aG4e+nfxfZM9V8/7/70Pz8sLIOjcAm2pWKzNxkhvq67oIdmUJh2VVz+6Dkh9YiNpPuPkjxgAgJ+RZKNk7zhwJRsGskAAgORRkr3iPUy5B+IhN9PDywD8a9jZRZaLll04XYdTbD/8bEID7Prj3vGIvOdd2D+SfzsrAhE91gRU8wNukqYg0UJaudBZW7ICCdZfdWM8iEJ6ZvYCgB+cLpCxe7JgOR+ZpWxvRADa5pNl4qDeWbxWFR4KKI4M8WkwztJ0v2+DaCkDGd5/MHA8DlGWoRfcLwaqwbteW1rNFlWgmWS9lOi6Fwe32PhSUUFyNlYM4udtiV7UeeaOhV0ru1WeJJ7l5fweJVnQQ46kQBDk/lKg6aNtt5+0soGVy+BTF92cK10nrRxmldLH1L9Jdt0IBwAhd4QFPhbWS/a0TA3qlQBQw6E0H+yYnzFAWfrXcUKjgvI1q3xW2mdMz0OAO+R4s16BelYAkF73IPDTyuNABxD8JafhsQd52xfnYlh8vXsNmmuN3Kk4+tVD2rZ6bT0H7ayNthaljY5tg+yCm2xeLVkcSS50ODKhdZtCIT/toqdEsmjO/qSlczIDyHFpAehJl2R5LNOxUkiXAUL1dBIQ+IRvgADFkthDDhpy/9lPhi33BzZ+dqiBGMsr2ar8VHdECtDtUgPmsb6iYWyqUVwS9qXPIdNKqZxvm1rb3msBaL5NTvQb0/8DeiAo1dM3pY4AAAAASUVORK5CYII=",
    },
    "M39": {
        "description": "basket of fruit or grain",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAQCAAAAAA+bXCAAAAAg0lEQVR4nGXMoQ3EMBBE0X+mJmHuY3G6cEFGqcUFBJo6pbiD5RNwucTKjTRgR0/LWqU6d6UKNLeGhVeWj94T4W8BbWk+0ya6bJ5MPTTyxFKmYd0nZt4tjBYflnJsA0wPM5cRGMfNUo7HACg3M1eBAPuPpRyP/cuLXJIkV7leWNeVbsAJ5LlQ5QjvjkoAAAAASUVORK5CYII=",
    },
    "N27": {
        "description": "sun over mountain",
        "pronunciation": "Axt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAWCAAAAADyCHMTAAAA5ElEQVR4nHWSPU7DQBCFnyU6KoTgIi5JQTcVLStZygE4iQ+DLAqqyA1llHpPgNI4i6IUIEMBHwXZ2Os1r9rRp/l7s4UG2e2dpOeXlWbkWo5qXU4rCCZJFqDKaV/Hd91PeQWLIVpM87eU47BkOw5rNmm1DbGVmcljkzXwMjPJAc4zHRXv4NupoQFyDDRfT1oH+XnstV+rD1LLtPc9tNL+XQRJTT75o6Qdf/ifvbuIU9duYJng1POPo6cDHl3scHJ8hFWe7r2Kc3QUvF3Fotlv6a6V3ibVK2e6fDifhz+fFyoyOxP9Ao3qo1rtxUgbAAAAAElFTkSuQmCC",
    },
    "N32": {
        "description": "lump of clay",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAYCAAAAAA5CUnuAAAA+0lEQVR4nIWPMUtCYRiFH797IQqESAouNFRODRehMpqaNSiaoqUgKMEh3BqCtsA/kJs4WC2hCHF/RENDU0NrQ1C5lXUlPQ5+itels73PezjveQHINg8TRLSmx4vFCFmV9D5tBwMgbo9nXxdGPCu6p6SnEY/B5YZUpo82Uy6+PPClOAB/CnavBJCTx1z+lIdQ0htAQpLUIR3I3y8CUFZbqpGs6NKeXDZbCpOwo/qgRfxXhRhMfWrPEk8fYGhVkSUdmmBgYkjAsZ0j+oe00RgJmAQD7jB5nQL9DxuW/NjVTKgTAOdI10AMWHpxzrrm+2CjeD5I3H6WpK+7eYAebdJbpxth2HsAAAAASUVORK5CYII=",
    },
    "D35": {
        "description": "arms in gesture of negation",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAICAAAAABbx2k3AAAAhUlEQVR4nIXPsQ2CUBSF4e8ZB8ARbB0DSjpLbB3BjlY6R7CF0g1wDFtH4G3wLAjEgIm3u//5c24uy6lStWI/pLTWNktQisq/XSm1KS1hgBrNZAlppF/Bttb0Oa7xBrnO49g/4ZJBXtTCkBW47+f2U1e18/I+o4/BkIHuNfJmuoTD+GzcfQAsKSRqcve9igAAAABJRU5ErkJggg==",
    },
    "W14": {
        "description": "water jar",
        "pronunciation": "Hz",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA4UlEQVR4nC3IMWrCcBxH8ZdvEhAERVxaUBTExUWFgKN4g47OnsPBW3gM6wl6hyIoBAQXIwiB/F1CTPx1sG/7PM/4L9jC59d38tbUpoCABo336u5s1wUI9/Zj+xBYpOuPdboANtcatesG4buS0vkIHSqqgxA8DHuAeM58/NkTcRu0aA1uiHPapp2eERfXo+cuiLyqU69yxD0fMcrviOI1ZvwqEGXSoZOUCGIgBsEpIzuBwAk5EBwDgiMIKsMqEDQ9vCYIhiHhEIQ3LyjmHjCJI6J4QqBlf7Wiv/wlyszMLIv+AJiTVnZ/oNwJAAAAAElFTkSuQmCC",
    },
    "A31": {
        "description": "man with hands raised behind him",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABfUlEQVR4nE3QTyiDcRgH8O/7p232h83r3y72Sqw04qDJCgeHuSolSgo3lJOLk1baQU5OSklSytG/WqYmLQtltBZqKzNeW/aiYbP35/Da3ve5PZ+enu/TAyjFX8/yo6Fi1zc1iJ5UwiN+yj3tTZHCUu356yQhLABgfuzUGp85uGxKxiw0AFgGUm/mxZT7W2KMmzQAdPFHCd1E+oWiOyp2AAD9gse4S5L1G4UnnwUAwLrF1WkSHr4jZKEYfr1uvyeEkFg35KxW7iYabLwNCL6zfxnkTmAQhqISIAvVxDzo+VhEvhYAqLJ3EYUrKCIJZYZ227dKcEntr1Xl1fJFOfNZjVrqtFudEYda7DjMi9UqYTkpgIxEKdLcdvuMC71OEd4q9nK23K/y8jmSE0KZoGoPA2k5WF5pkl8DgOHg9+qdVrY0Y3JhD1lBYy6J3pH3A2FjZ0kqLFv3wAdjKIppmAR+gBZWkjePuBoG0lFUjbtpIsfHCTke0mm3s48rNQCAP6iJhucJPbpfAAAAAElFTkSuQmCC",
    },
    "D13": {
        "description": "eyebrow",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAGCAAAAACK+rNEAAAAkElEQVR4nGNgYGDg05n3////////HzDR1RNjwAYYGRgEo5wtJSC87WycB/Zw3L+BqYxddK8aA8NrNgYGBkY2Dohg899575jZ3iArK8xQY/jY1YYQ0Zn/zY6BgYGB4XYyMyNUTIjh8v89NRxoVuh3TPz85cN/BPjIKMD4/Qemk5l4GbkqZP9ZSDEwMDAwfO0BAMJ0MiZ+Kl5LAAAAAElFTkSuQmCC",
    },
    "G12": {
        "description": "combination of image of falcon and flagellum",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAVCAAAAAAGU2MLAAABd0lEQVR4nIWPQWiSARiG3z/ZRJQybF06NIYg1HYM6TKiiKLLqJ06SSTIiA6ePHmQQZA0HEZ1qEUUdIsagdRhy6nJwG1sQdghCIJSKMEwyDb06fDr758b8z2938vD+32ftFvGs0d7pP+rsjWImId3x/cl0rz6C9f7UncqlRzv+MP81Bso9yEvAJZOS5I+EZSnChmnnTjH5v1ftGn45f7Ma0lxoGBHHkP0UMq/zI+z6zAlSR+BpzbkCdySpC8AVackxUm85GQPWYCKJB27DY3O0fWvQ2sELMTQJKabhbTpzrORYCfY6znDA9P4vsEpSdI9ynPwvEschHzXR+ChJClPEzjRzcPkrMajJTIOSWEAbljXfOdub20eIpIKkLX9fQHeWoPz4h+yIV1pxzw2RDdhtDcFgA+XfOaGWMtwug/wezguHalZjPfyRFSLxdyqZCC1VlxSs94ama7Zar2h4FU18sWkgfT+jts8weNydIHtsZmOu2agASr9AySKr5abQ2+cAAAAAElFTkSuQmCC",
    },
    "V6": {
        "description": "rope-(shape)",
        "pronunciation": "sS",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAWCAAAAAAzjzm/AAAAw0lEQVR4nCXIPyvEcQAH4KevwiCZdIrB3UgmZTLJJJuJdM4NCnkTFmVUvAMGSsqfUI5spjNbDUy32PTrY/CMj/6Z6zls5HykjK8sLWPaypTpp2TBfPI+pm+2ysti0gXtJMk60E1yjIIT3P630yS/k+Aoj4Of2YehXtq2kh2GN1ONcp+7Yc23HMBtms7yAQ5zVup+wJW6KnuglqoUPdCnlG8BFaWjARq+y4MWWNNRu8wN/dtJC2+52H1NnmuY6CT5Wh3wB6zwWSQe1ZB8AAAAAElFTkSuQmCC",
    },
    "A43": {
        "description": "king wearing white crown",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABcElEQVR4nFWOTyiDcRjHv+/vfWcvxiKtNCUmikSbA5uDPzUuUhyUpMmVNFFzUsqKm9yU7EIOcuJCcSApRiJbKMr8WXu9LZuNd3vfn8O7V/Ocns/3++npAbJnUvqH9X6ajdU3NJaF7XeRez9Rd52txLWv6zgPZ7rcre3oS1O56NLkvvRbBybkzoxv6BcfrtEQuM/Urd8rNOo62CnmVOb1BR7HGkbFjP/4fLEg4ieunWM8SV+cKsucFhTN/FBKhUZGCwzhUMIiTf8Js9K4s/BliGhsXd3ji8uu/li3j5TxeB4Oby0AdL2bjIdKPxCiwhQDzAXZlogyBGJOyItu8JU+mVCGAUHKHfCOlPYkQUEV4Izaanaj65IT9o/nOqA33I28DUqbYReDJpCjyzEmMbz1KgMgLEj0zJKDtGvgVn2DKKefBPg6/oJCARCcsE61MucrAAFyzCpX6BWAw2BVRZsegGwFxwL8Jo2FBUEQItLTkhG/VHKLfUEwBPIAAAAASUVORK5CYII=",
    },
    "T34": {
        "description": "butcher's knife",
        "pronunciation": "nm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAAyklEQVR4nC3NsUpCUQCH8e/8b9HNO7gIQqOXhDKhyaElIcegBzBfoSe44Cvc1TFoybl6hgbBKQSXOENdFRxy6AxXzmm4Tb/p44Oj8TYFcT3cA0pGpx5Q6+bRALo8fI4A3edFBOhqVgIoKg2AEJX8Gyq3aQDQT78eAM3PEg/o7TwJgD53VV+6EwAVxcgDWr30AiD/YQwg3hcCxPdTVH1ecXBwq3bt7subsD52td8mdtq96E4tuW3QsDmdTUa26RBPlg/LSQwDt3cD/gAAAjy1Vq1prgAAAABJRU5ErkJggg==",
    },
    "G29": {
        "description": "saddle-billed stork",
        "pronunciation": "bA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAAB5UlEQVR4nG3QTUgUARgG4HdmZ8RyW1yT1kIWA38w+10oLKNYSqFSyIikDmUFUbeiS176EQvbBInAWjq01NYlD8HipSDIkUgqFknsD91os13shy1G15l25u3ojDPf8Xt4Xz4+AABQEns50obFIwAAlkUCRoV+4M8iFAFgSW+e0fjGgCMKFIVHGF5fPfy7ymmhJ5x4qw4kcwedtuO7EQnsUfnUeQ9Q3b4Tnhh7y1wMANCqK0VuexEA9snPdTeUAOw+jGPF/KmMunjTF6omab64UePo3f4hM9vtL29+z19mV9COK0fN1Rcm/b5TyWhjgrM9W6xYn7oo+gfja/lJADoec7q/agGL6ySgk5HT6m0B8IbfcOJKha3bc9k4363dawAgt4yrhXM+G19LNx8ZyvdsBYATCd6vtWWvT22Tz3z8Fnv0oAOeAQ6tsap8JxuGd8MzNZdOTc2QqePrvMICD9d0fca/udTmxlCJIYiF8qUWrHtVCszPKEldMAGRDSetv7rLh3mdP6YnM9lsJsdEpyUZfCc2lcVXbMpQACBKuXlLMqodxVX2e+Aygb/KclzSd7kZbrEPUkZZ5Wahr+l6HGKfm/kGuRd4zZvWpYSW/UZBlCvbCu2tWuXcmC0SHCNJUtNIjp+1Pfw/VbnBd26GheIAAAAASUVORK5CYII=",
    },
    "E21": {
        "description": "lying set-animal",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAXCAAAAABYTIL0AAAB3UlEQVR4nIWQT0iTcRzGP6uNZbUKs9qh5C3EMrANKhsRXfqv/VGMhKgQD4IXUSGoLh06BFGHQUUEHVoojUyFCO0wiAjpENEgyYgOzcp1aRTUeje3p8P27nX5it/T8/z48Py+zxcAqKivXwZ0/jrIQuN/GWsHBhVZtRBqSFpJozRlOAPLbXlJesKAFHYm19+2dY3029ev/AkHrqN9U+L9LD8sSXIiGZP04XBbyfskKe/4e1SSdMtt+TCYXjlvCqSC05ZskrTrqxbNk9pnO+O7lOK+3jqhAxoHKMa8WfvxS5ghAjsdUD8/bNOoKACvFZtLdklNJVMlfbqRNh9tIa6IzSy5B8Bj3bXfIirO0sUppQ4A0DM9OaVvp8Gb0fYSuV/Ss70woY1UJ1Q28bawVAmAG1qGiF6ZADyIRNDXGsyActmZHoVebXuYpqvUqqH7aEF8Vm1Zn59i86Ckk3OrJq/NMn3dvdIwPJBOYS1gzb51k0ADytadc23YCkl/cyB+tiZk/p95RlrDheeFNubF3vPGakkBduhpAXCtqOzYnQH+tjCSP+Z5l76ZdGf/VHkPzbj21EGu/+qocWQMgOZx+zKxO9WFgFD5xa4Xa5pFnx497rGW6cxbVO7FyGV/BQD/AGhECuqs5p/NAAAAAElFTkSuQmCC",
    },
    "F25": {
        "description": "leg ofox",
        "pronunciation": "wHm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA4UlEQVR4nF3LsUpCYRyG8ed8fNQ5JgbZIOYiNAhBU0rR4Nbg5OoktHoBii0O3YDgVXQBDa6BIVY0JA7R2mBH9EAHNT/O3+F8Lm0/npcX8DYfrQwAXijy1HA1sP+wrF/OAU/uvPK7D7jhY5KOKDAvZxmcSIF5zqYRpYC+PgAUEJobq9n3FYICfsYXtgVvCSuC6Dhe+fotRLEmU7HrauNYCbvHSSqyOk3vWt6dO7EcJur/Y+/T6rA4wqCBXLF2dA5AT16HfwL63vhrGV6j24tRqSIdaIb9vFtd38JK/ME46CbZAnZ/TR3h8G5UAAAAAElFTkSuQmCC",
    },
    "O19": {
        "description": "shrine with fence",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAABfElEQVR4nKWRTyjDYRjHv+/2WtMKkbJa22n503KQwuQ0Ka6E3UiR1RJNXLgof6IcHFCGq5zmsBDZuGxZrg6K0uQgQmw/v9/P73GwtP16fyffnnp7n0/P932e5wVGqbyLGiCSSZj9N+T5F2Z3MIv5W6b0I+lhc29bI54kayVS5/sJAByUQ+6pTtvunPwsWSssviF/dOkGsAd/R3En3pddfyaulbeEG/yQ8K5ALQk3hY+ra3L9aXRUNhSeQHOEFkPkqSeF9LriI4+obQFXcT35md+5P5CcxWKavIN0t0f9hTM6aBx8+nZz5xMLHfgqhN+QYAIQuCTvAVghZGDgkQziynDpvGh9posmtFZhplu42/T23DohIwvhsAcDfXWrMaFtzwZWbHgNCuHLA6KtFB8R2sKEteRpSBNWArAUs7EtI8iA+6jY9vcwG1UaioPAWC7yxUCAM0ZfGikqkVIglWJOdlJ5ppmLZFj0D2jeJ+5LSUzJMnwouj+jbDsjGOsHNYyky8S7BRcAAAAASUVORK5CYII=",
    },
    "G40": {
        "description": "pintail flying",
        "pronunciation": "pA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACyElEQVR4nGWTb0gUZhzHP3feaZ56WleHtdXJ6tJIJGtl0YoSWrVY/0jSojEKQQyiWLRJRmMZ0cYGvmj0Iv8ExZKwXG1pVHZWlFb2B0oNMrpEh6nXnZq587zvXtz82/Pq93u+H57v7/eFB4Dw9R6p2M74Y1lcoyCANee5R4GOQxFj9UlZP9W3epuBpOLXf2xxV59oXzZan7KtXJ6/vz1VCZFng9nTk/fOTf1QFD4COM+p4cBaTJd+w5jRq+rGNzUnrg54Uob06IKHDXvnAl+0pBF29MWmrRnf+CTpiS0EfFUndzpA0q3yGLBNA5j5uyRlAZDp0fFPAKac71kyYhxXqrfdvdnR0fs7O/OtJiAi813totHDr/PvdrxUV0dfbRwAkyv78iaMWX/6nfIox+XHT/eE2ln3Xv4wPsFCLQf7p6Em8fntlPEA+z4cG66n1tyI/wggx9++esjxgjKGro3DQPJOs/27/2tzAv6PXphxJRgIBM4YAAjLDeYZxwEJd/tPpqf97P3FDID92qsZY4H4qp49gKVCh6MA+D5QONbiYmAXwCZJR4wAsx8oYRQQVSYXQFqdulr8hWkAZTpnGyGy/e6FEHewSWfWZrxRU74Zjg4oZxgwV+kAsKZbRROJdUnBq1kma6PaSpeEFjL/+m9BFCxtfL8sBmw1kuRrru6U1F7lAFje2eTAML8pmA5gc2nAK/kDkvfwX745GDGstB10Yz87+/QTAJOJtzdhexGe8NXeXhNGEte/98KWpAv5HsC4eZ5aN4Kla7DkeqKn72sTMUd00zonR39+BsBUlwZz+/XPl2v6G59pUB1OFrl69mXWq9IBgGGHT2qXLoZNK3lwPyDpR1PB58ENCyzHT7oBiFxqBTvvLg+27Z9oWOHsTo2npF6+ilVDH3LmCz3L86ohZEmE0RaPxbkrPXY4POej08nJLW0FMSOB/wdXbS1q8gm4twAAAABJRU5ErkJggg==",
    },
    "U16": {
        "description": "sled with jackal head",
        "pronunciation": "biA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAZCAAAAAB4egMKAAABIElEQVR4nIWSPUsDQRiEH0OwOFJZahkQKxuxSmVpaanVCdZa2Em2UKzEX+A/sRMrC20UxI9YiBgrJaAgBOSxiHtJLtk4zb7Hzjszxw5ELLZofpJApZjW6nzVlhK0ajGt4C2rVym9iFZQ/de0PkljqpgsfY9Xu4DNzX9yzeTX5jkhmQ2gkat5kLM07b77rZrjKbqTYFUfZmu95FMAlym16rKqrXlgYjRYCG1dh7YAFri7vyktBoWjEm3Mszwa2LdRsh6N4QfBp+3hq+8R2s0Pu9HptdMZtu4X6b3S35wtSXSKqabvKApKlmU9dyUbWJhWmj1KTBdpDLT3GAThTWKresfQX3Q9eTGJyKq7N6lHsZYbzGwdELIU7w/hXJ8P51LXv5obzj1h9kvSAAAAAElFTkSuQmCC",
    },
    "A36": {
        "description": "man kneading into vessel",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAACNElEQVR4nG3RXUiTYRjG8f9eN83vOZsIQpZhZUWglGL0JZaKhCB0YGIUEoV0ZIFUBiUiRloUFCRUdGASHRRsEAqhlFGCQ10WTMqvwqmh5sc7p5vv7g5cZfVeRw/8uB+47hvWpmRZHsegH1Nxp4jaZNXXlG9ysahZavV1r2ZPjE8f+6SLRpsEvE5/oE9XDeVe79mUUfmcpMtpC778iNwn4rwdqaPxdglMjmQlVWtPw3U49eaLcU8anPHbM/U+3+EaOb0PSt+7L8T9h8n9sjI/cd1Col1sxn/Q1CgiovnUXKLb5dnf02F1KzLukcpKz9zBhLYB9V7IWq3wS2uDp8tI2eLwa62kbrpgDZ6bkPZiRyAXKPWKKyrbc+W3WU6pMphzX15aANNbuUz2bHXQNlS0qVKbWiXOXQAWn7eApO6rqy0vOUQ+HAuvWXJuA8AstmhCbTVGxbzpRIlVYbZF7Uyn3gXAeXEsYDCYafgof/ImuP6e4Y0Q1fHOuG49jLtDDFpcsoIvWDwyrNwUSMzqxlg8JlOuoYHeL5o4DigA5PwQWVr0STvQoj3Yc+ikW5W7scEGD0UardbNHf1AxnQNQNXS/l+36JHJ3WB6Lgq4JQJgdK43qIXpWpMDjAoKTLTGAsR4l4OagPfG6ksBhpOB0Pxb/qDG41aBgAZAZrcZir7uXLUtZctyBCDilQBs9TfnHe2xRwJk1PfNSZcZ6+HCR6oAbP8uUzNT18IB4x0RmT8OeUMzIoM/AWzIAaAwRcDlAAAAAElFTkSuQmCC",
    },
    "A4": {
        "description": "seated man with hands raised",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAACE0lEQVR4nGXST0iTcRzH8feePZvLxcz8CxKzJ0FojcxWUGlZpFYHE4XoEtVFwgIPFp2SDnUoIsKikPAgBWGDKVlYGFpRTMyMxDLNNDTRx1yuP9qcm98Oe4yiz/F1ePPlxw/+3rL9A0E92r2af1cmZ3ZtqXpfqwLYK/fGNKFP2m8WUfpprWK1E8m4lQJAevZTZXOlozOQTG6rlt02WgPAWx+4p9w5j9KUHn/N4MiqfQAkRuCbfqpqcZbr3q+ebYFBAEqndsAJkSMKVUNyzNIeqQBQH8xcjc8c++AEiueb2Cp3EgFcP6SEy9KSAQ7vmzQ6ooWgVdztP5mENix1QHpLNfnSd87XG104wPLyi9MyC5CrF6mdIiIy33/fPy8yJwCmS8G8QyER/fGEiEjgQqMAoHUEXoREJrrCIjJaxu0Yk/Ql/PNlbzg6PRk+rZHQKksvuvOwhs0Wdz4IeOYeqjHOaXb0VLyCRUyCLe6ZEmOXgw0+D5gUwKr0G7zA592BpjXYhgU2MWmwGbVnY8sTt9ULFKMa7TFMFqlObtOvsc6ZORcyLskSPQUyJuTejY9BmVlvRFRkEb63UeDxHszT7UYkSkJ8/J7jKXUNflgxHmewhu2KU17XPwewm8N/mMLa+rEIANsXhmKqjIQaU5f+0Mq+5ljbXO1sOApAar6NctfALxPgOlti7eo2AZasAoDxZsD8Tv7bbx/m6EL+Y0IrAAAAAElFTkSuQmCC",
    },
    "D21": {
        "description": "mouth",
        "pronunciation": "rA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAAZ0lEQVR4nGNkQAIBus72UObBvZc3MGABAbV3/qOBO7UBaGqWvUUTh+p6uwwhsgOrVrjSHQEMDAwBp7GrQVZ5OoDh////d5K1sCtiYGBg0Eq+8///f2JNI9JtRPsURRxHuDGiKMUZCwAvSIcrzVOwZQAAAABJRU5ErkJggg==",
    },
    "A6": {
        "description": "seated man under vase from which water flows",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAACTklEQVR4nF3SXUiTYRTA8f9et1cUZ/nB+lALM7WyCKXEi5BBihgZQlHddBvkTaUoGJR4EdlFZJZpXUSIFtmXpElUCCGJZpGW86OZQwsx3YYznc1t7+niNbPO1eH8eM45DxxYFeprERG5HsL/seGT+Pp7/Y7sf6obr7Y0v9MC1UmbH0g5gHG5vvt2vCvo/akOeDSv5v77YN+49FREGbghommBWnUFshzBC6kAxY2TItN7V2CrXU7qWdjxWXf1eOO6P1IhL2LiVIA1E/L9Wd1ia7gOkWMDqelLtWuBayKiHWt+EgooUJo47Z3VigqAcWzlo5lqtw+AxBFby1B7UOpNEDnfRFXQX6I3y/3RVi7SLEubgLKFhrhxKQZQDIWWrj58xb2mZOA9e4Lt+AEUi0V6hgfVnHtc2X+i5s7UZc9zX7oKYLV/juXIwmiJU5xekQaI7uw3A0pmdLOTR6+SUm3EhDGRkoC7aXsGgFfygMROERGpz5SLCsn2cwAi+QApH0QmT0dE9g2sR3l8Xv8pAF+eQrRnfq4urRDtl3GV0PaV0Fs3Y92YQACMYtClryOJxVOWN0EBsx9QJlimt4s0XDpcZvBQap0D8MkBXUyjUmnMmJUhu0gRYFRZ0sWvoQbcPrbxcksYoNz17FrZwpdRY3HcP3OoIwIgZ6wrcnlxcTjk4c5waKoEjEHNrF+WNda3WNfyDQiJ+QgY08Nt+qC8KEfJTHyCIuRa+9NsMCpHAYhplcDUtMvlcjo18Q5XZRnyCxq6geyzB40zIwBo5h2hMPgbwl0KeRVlaAMAAAAASUVORK5CYII=",
    },
    "M21": {
        "description": "reeds with root",
        "pronunciation": "sm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAAB+klEQVR4nG3QO2iTYRTG8f/7fm/yGZsmtkmDqEsviJO00LQUOxTaDio46KAOtg4FB684uCpuDiK4FcQLHQXFRUERReLQVkSi4tDGGkldekvbNOmXr3mPQxqlpc94fhx4zlHUJUvjQP3FmR9piKhlaulLfz4ONL3PPYvCwNidnmgVAvdFngOn18W7DOdlOTcaA9AS2njS2QVRd9Y57FDhJt11ALoxPnlLOsGSeXcuiS6kvpYtgOloXyq9dUExujIQwsxkM00AaCf0Ih9WAG+WsYjrBKoFtDZfPADBNbSAUpudtaeCALoJvVZuwJkq6E0ZXPiNB+bgopfPK5xvq5tL+spStnVwBQJjc0aDmNoHtCsqniiDWrBIpX6o+E9ATWdDiGMIujaS9FAVW5OFj7tp6/VIRJT4YBurP0CsDir27l/HYcoH/Jb+qoSCtgJCMyXywgaiwwD6YexuT1HITl+60IpWugEPC8CuodKvzDCcWa3k5Eg4/Wf4gVyvtlMjntwzmBu+SC8ni2uFmsAjGd8H3BY5BWd9qYoG8pQrwFM4AC9f/7+0/SiH2gALIzEiDeAB4F5bFJGlidSHTyLyfWJeRH72x4Fj87JDZk+gmge791i2pJzoM7mrCgKhraI2Ol5FSBnwfbbFGujS26cA+TkI7gTwWCS74w4ZmPwLL9jaxnZQBJwAAAAASUVORK5CYII=",
    },
    "S15": {
        "description": "pectoral",
        "pronunciation": "tHn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAACUklEQVR4nHXRT0hUURTH8e99b/40vnkKM+hjdKTBSt1YRmWraNEfi0iSoBatglZFq0wictEyEoIIo02rihACwU2UKAijIZTkRBFE9E8bpxhHZ8Z8M2/mtHhPgrK7utwP59zfuRe2pEREZMyMfBAREbnK9YqIiNwPa3y5V04nZ/maX56h+OIdc895vPzr5dRSZbwAqLEH9bfSbZCYXN1xSQ4Bj4pnrVepOBqRyLh16lwy3diUHQ1dPPJxwYpHb9d07LOufEMN9OxmwyU3V5SSzMMVBKUAEUFpgAjKZzT3IjP1G9dCV1rDZ/5PTd3HWn5vS1UFAKiWlV8BkFs05nOOj+YbPVGYVQpKZjtvbB844bZsxk4ZiAyfF8m0xGKxxoY+ebvTaozFrG5bTp/8LPTt9zWJnTEAGFp9fQZAGy7axzBP+AbByA8dDhcBQqnpOEBw21MrQn5EA6zZO9pmgHj7nBdKf7/gAzTgaCFDLUBr60S1CqACBTE9NYKlrABoFLUaBYjuL/brruo51FYA//cZ7WAUMJzp6XLQVfUT/QJAZ7FEgwGYS89yZfFUR0UBo0uvVESAqkJX3r0AFffXCqOVwPoPOn/UPUAt5fzePrT1LwU0fb1ZuPNfded1G3lahSCgdE2FAxUAB4WXuRpCkgrW5uxNByIlwIl32Hi1TsSouyvgJOORurwDlBLHC8p7q0rILyWAsrmrPLIAKCSxNuVqoWuwNgNg2z17FquAnbO6Zd5Ntz0laQOg9olMJgCCE+nswHr4a9LvTnb5Ry8AqvvTZAT4DTRQ8fl/DIa4AAAAAElFTkSuQmCC",
    },
    "D32": {
        "description": "arms embracing",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABcUlEQVR4nFXQzS9jcRTG8W9/Y9Eq9S4UI8aCEmIMEdaasMTMciYmIxb2dhb8B0LEH6AR23bfMWFsEFEiNpKmqy76IiRKm9z7zOLOdXmWn5w85+QAQDQrSdkorxlPSpKUHHclnJCUy0lKhB3xb5T1tLowv/qk8kYAgM8ZKQ4QlzKjAMFNS1efAHpTsjaDQN+d9MupWJLSEajfsxWrdag2Ju3XsyIVRtzdIwVp2XTAYdal7CH0cKTSrHf0TEknFLXX4lFLTA+mofI351HuTzlksMSbyMLwPpJMKtBe5UnVx+CVOeNrxKPIAhfmhuamNxtbOTe3tI29iu9Lq31DzW8dd7nUeaRkDb7pYnHIpeH7h6gPGhLWtvNLArt2vBHgh13odqg7b38HYCqtuB/An1B6EoDBlLQI8FO6HHAaDqTLMHRcSwcBMPCch4E5+NYP+WcwwAt8qEDJB6X/10xktBaC0LoyEzhTp1vlukd4rK7snAL/AI5ko+x4tB3JAAAAAElFTkSuQmCC",
    },
    "N37": {
        "description": "pool",
        "pronunciation": "S",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAAAIklEQVR4nGP8z0AMYCJKFQMLAwMjQUX/iTVt5ChjpGosAACZsQMXVsbt9QAAAABJRU5ErkJggg==",
    },
    "T26": {
        "description": "birdtrap",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAaCAAAAAD+7nGkAAAA3ElEQVR4nK3SP2oCQRTH8a9hN6SQYCGeI9V2gjew3EDqiKmsrESPIFjIW29g7wWsJXVOkiIoyc9iMojL+lzBV8zfD29mHgNeSJLUgobPCuDt2TWADOwAPFyTkNRj3J0l3qaFTi6zYRwVF1m67Hd4XQNObV9Mkv3XTdWmY9+KEVn50GkvawIw3wHhUBXbc7TZhySTxzAP2Uw/Z+pLGiyk93ZcqLpbrt8xSNlpqYItpBykHI+lUg4zdfHY06dWkGmEy5BiU2Z/QONCjUuRUNRQwwQ+riq74VtaDVbzCUd4BWxGJTPxpAAAAABJRU5ErkJggg==",
    },
    "W1": {
        "description": "oil jar",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABOklEQVR4nE3NMUsbYQCA4ee+u1w2ER2kUBNEqODaQSwSdAm6F6cu/gT/jJM/wEJXl0DWkkUFQU1DQZDGitxgCEYkdz2Hi9B3e6aXrfurRc3PTYtX91vQfujsXpfXu52HNrD3OOp/7Y8e9xD9/pfEDcXgU+yuyEM0Te7+5GWU5GWUfGzkDp+OvHf0dKh+OkpnTEen9fDam9uceXOu9xpcTnZm3plcCobPazOvPQ+RXJxHVecXiUQ+/jJJIK/9zCXUot5f+NCqgePiABwUxwRuwwpYCbcEOmIQ64B60V3AQreoEwiW5zG/XMG021zCUrM7JZB/T2uopSc5AX0lSr9U/r+ADREiG5Xj7ckLXibbceX1YYZsuF45rA4yZIPV6p86G2N8JiXQnt6Am2mbhH3fWtCw/wOtrHwva3kDt213s9Yoqv0AAAAASUVORK5CYII=",
    },
    "S16": {
        "description": "pectoral",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAACBUlEQVR4nE3Ov08TcRzG8ef76feu7bWUQBFrIeIAQREkscZNoP4YFRNWcNc0bioLqy4aVmMVjYPpP6ATGgM1Dq2NJNTYQoWiJRRoz4b2Wtu7+ziokWd8DU/eAABAm2XmWQ2H5o/ufEvkitGuQ/aQ40M4GedH/2lwfW8YwNDu+uA/0mK8CgBY5djfy7b5BuuXAITL3Jj3AQCmWsycncBYhplbUwCgRUuRPFv1St3ifKT0RAMw0rh1n7PPt18WXmT4wU1jGISmcTBQu5pdvPHu62S1v9psgZxXlpd+pYqTbriv7ySbS+8vO8k7nciXS+5gFmsBd6WcT0x7yTQUkEMNbGGjRxUCSt2kELPHz8wqpMWiy8Mcokggenc41rItCLRenbr3NHCbOvVCJy3q6TAmPutvlY6C7qU6QRC4JSAYbBPIpN4C9jUnICEtdvl2sR2g0ymke9pl9yZyQdl+LI3kGTIlpG27+r4gc9xl2xKKSQ6GCcHWnxZhw3LQhws490MnWAConA9h/CPVPNAMs5Yex9hKzWpq8BikCAgJuyEhLWYICKa2En6qKsgBh8VOTceen84vI3miQ3YW8P2o7OhLIh6i3ChGylX3wCek+t3V/VGc3cBs/U3xmcuXWVAW1nzq4+Jr4w7CW3wwA5ozVow5EjMV3rwIpSvY7YK4tsm5SQFXoPeI+htAVOrw+AFulgAAAABJRU5ErkJggg==",
    },
    "U2": {
        "description": "sickle",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAAAAACzJtCvAAABFElEQVR4nI2RIW/CUBRGTyeZaIJmuq7JVFVNM4neL0CwTEyN4PEoZgl+wZFMkExV4jaxTNT0B7CZZ88EIRmkBa57yXnn+967Ec0jANH+eNWCHU07FkUXYRfaAG7OXVcIfp2zPZByy/Wie063hLm6GhZFL27FKu3DRFU/2nVD3SZAmo/0ROxQjQEyw6l6SbALULg4hVGbA7mb5JRsrUDitv2h0FMTSIPjdiidBk1gYJm1McXuu7pQWjcndotJqTrPiafBYdO24mJcqWEzAga6agrsz1TL9Qh6ea3lYV4vjtPpTLUe7brN1WVxKFnt1nufZdkeqZb5IRP1n+6Al07ohEcAfniu3o/7RP+X//kNb6+/DbX/AGbginjGzmpUAAAAAElFTkSuQmCC",
    },
    "D16": {
        "description": "vertical marking of eye of horus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAZCAAAAADY5WvkAAAApElEQVR4nAXBvS6DYRgA0NPH+8XUzWaRWBqDC9ChE7sEcQUibsE9WEwWk0QiTYfXaDHaxGBBtGbbl9CkPx7nwMbL9KBgbVsfHjNrsDcYE5wYYmU/P3eyRu/YxSvulhObWcuhK6sErQ6R1iVx2Z5K4vq5mBHvN92zlvj91mvBfZ5nDT583TZBGI/6QdF0usGT+ULw4KgIGlt/gmKZYJg/b7A7yfoPhP031iXFzxkAAAAASUVORK5CYII=",
    },
    "D47": {
        "description": "hand with palm up",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAJCAAAAAB7rAGRAAAAz0lEQVR4nHWPMUtCYRiFn8/h/oH+gTS5fIRgu80X3NouCK1uDYkhhNB2G3TU5iAJCkKowaGl1U+aJHBq00lEtLyn5aafSM/0vu95OYcDHh1teClk+Q8pHWrfeir6iqGRWwXDRwdw2QCG988OmBzAw4/MIsowuyFMU9rXFsBGTpLGUGumSnwhoa8QsF0nucimGXl9+pFXQssQz+YPC2ebZd4z9aMS5/F+HTuA11EAkJgWUJlqJvVP7falKkm3XlcDUD48PtmxSjJ3b+8f6+3hF2T/dzNeCbGTAAAAAElFTkSuQmCC",
    },
    "I6": {
        "description": "crocodile scales",
        "pronunciation": "km",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAARCAAAAAAJJIjvAAAAqUlEQVR4nHWPIQ7CQBBFfxuCWkFPQEhqwZFqmiKRBIUsSU/BDbBNQKNqcWhqcSRcohzhIZptWnb5bublv8wEGiReLWeZHUY9kGySTPrITXID4H7Op5Ik6NC2Aey+ZZ1zHemgi8cnxTVA0dtYp8lpU7jsCM/UDE2WVQC5j5kTvEp/7wrlD5AEoaSxtFt4bg8l85aih/+zCppi4nFqDtT71O2Aav4mwG3YfAHdYGlxr+IXwwAAAABJRU5ErkJggg==",
    },
    "H6": {
        "description": "feather",
        "pronunciation": "Sw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAA30lEQVR4nDXOMUsCcRzG8e//d8dlBSYRiIJEYSCCjg0NNTU5OQWt0uIURC+iyclX4AtwSGlMaBCcRBSakhsOoSBE6SzPu7/D/9o+PMPzPEDmeTWfPUCq/fFYHflwuyjDpSf7N28jyB6Qd2tw/dOnNDwjMXUrklFLjtOtrti7mp1ojhyGoLGQYgQAshYFCqTwF+L5NnLR+eL7xUGiT2By4oiygM15VgCILNsArQ02IAB7p0qJDrga3AeBhEf1ntN88nif+XcFgLHumNEkrwa530lc1bBMghvGsOOH8I+1wRay+kQPL5hv4wAAAABJRU5ErkJggg==",
    },
    "S11": {
        "description": "broad collar",
        "pronunciation": "wsx",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAUCAAAAACy3qJfAAABX0lEQVR4nFWRS0iUARhFD8MfE7goDF+LUDSFwDeUAwMJRrukZUFrBRujwHQjQtkiWgqFGxcStApkxEIEQxEUpLAQKRwfZE0gmg8QBeHH4+JX0rs63Pvdzf0A4MqNsS/VAUBharelKodTvR7KOlQA0PPT6cmGE/vW+NGjy7pdBL36TzcTADSqqw/UNXJ1a0o9qgCYMDuldil3VP1zL+NN4q12Q0ovvrVxw87fzuaR8iWVs/NAzuYi9SY3ZMIyqDMdizsM7L8oISRcyHKJQ/g2ms+IPQC3rQPgqu0AHcbucgDwOTN3HeANawAx6N8ZAaDc8Hny8Qd3AXgqNZ9sBuCZqjOlAIz+5do709EA8SAIgggbTMeWB6gtA+AwDMMwChIsAn3+4rza3C4HKrTtfJDxCQC1e3adsXPnHDzB4i1flZZEWPRe+/5f3VfXl5cyK+r3yjP1C3lN6a+qPz4+jB57DKPyr1Q5eDoUAAAAAElFTkSuQmCC",
    },
    "E33": {
        "description": "monkey",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAYCAAAAAC+OKDoAAABv0lEQVR4nH2PTUhUARRGz4xvRi370QipTa0GFMsWbpIMCirBwEDbCkFGP7iJQigCKULctJAiCCIIw9xIQVKIS4MskKBFGROFtYnUbJoctdHT4im9zPp2l3O557uwSoqqquvSmmmqLCL2Nz7yvexk0jpg9Evf4IqF2nNT1TUAY7dj5A/U07piIdmTms6YaTEc27ofrKKIZjIIYFeN8dlFoGBNkHjyPpjNA7HwRnx9jNQYLBQAkJ8v/DQzX5kAaEwnnbpV/yJgG5y+2TODha+7ADh0Iku+4mHo+Aj79NI/GoxqX/x/FXthKCAOWfaPpyOgrOonwcg8FYwPQa0uqi+XYGmsI6+qd8h4BqBTTzXraAl0Dr9T7U8dVd3+2XKARHkJNOgYx9S5/mATjKhmbYp4J3So27vhcDCUXIw2nlbnvABAY8jdAvzxZpIkADtgtgX4EYVfbR7UDoCtH7xOXN0Q4TuV4qxXwwaTsE4tjiiquEEuxwBAjleQABp+H9ijZezVEiCY8DjwTK8s48P3dYC6nO0AZ80APF9qRGn7PdXLw/pmI9Cuj4HzahdAS6/LWWgl1fZo5u21zaxt+6ZPdwO/AMnf68j1g7YMAAAAAElFTkSuQmCC",
    },
    "Q7": {
        "description": "brazier",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABi0lEQVR4nDWOTUtUYRiGr/c5r4NnGOfjoDJjZBINFM5Cg/JjU4ugpPkFtok2LSIKatVPaBf4D0KIcHbqokConFmooIvATor5NUGbSKeZ05lpztPi2L27L7g/gN7nqlqZ4b/s48O112+ildSZ733Yql7Azv+cOgOzhxsl4Hb7VSYGlb17PYDb2B2PgdYuAfBSnwIgjXcNAFa4lgSQzudfABwxMwwgTieM16JcAkDSV+Oum59WBwHEnI/vXdlanQQQunHiugQXBZClkQzA33Pd7LQBpN7nAiS9RnMgDYjvDQJMEbS8acBu/wGgGNYJi4CtuwmAiaZPcwKwDgYgH3wnyANWXRfAnhxx0gNI5OUAXANEgKgqgAEkB0hCDf79jC3WvhU182DPjoZZk33xrGCPj0eGqiYtA63IbN/ZSi08erKQ2ix/lVte29A37BTKybwp9Cu7nbJpHiz77eBH+GWp3kV3xpzKZZzFDx8XHW68R6sFANG5ORUAfZsAuOuXSvtlgNNZAGqn6+u/a8A/gqaEkTInB38AAAAASUVORK5CYII=",
    },
    "D12": {
        "description": "pupil",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAAAAAA6I3INAAAAUklEQVR4nF2PQQ3AMAwDTwMzBiVVXn0GSzgUQgncPu2kxr+zrMQG6FN1dgAIzczU2BQNWmjAu10IfRmHIBws28HmwuRX+nCrhMup8qjUqCWvCR/MI00/+it1JQAAAABJRU5ErkJggg==",
    },
    "N4": {
        "description": "sky with rain",
        "pronunciation": "idt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAWCAAAAACJLLHfAAAAdUlEQVR4nMXRSw6DMAxF0UfFjBV7aW83ZA3A+DIIH4EgpFJRPYrlYzuSG1QTnyqlVmoeEbXTvmFBISLvpawgBIIgWYK1S4fEiQABybpnciIznyvHxJlZZSaDFqXxnsn7Ra/YuJVfuMLvWfePpVMdu/pbP6yvGS3Fl+p9IibxAAAAAElFTkSuQmCC",
    },
    "L6": {
        "description": "shell",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAASCAAAAACcZ7q1AAAAz0lEQVR4nF3QsUsCcRjG8edGl6b+AQ3CCNxET4LEg3AM9xvEBl0bW3UxWtoCR0FvaXENl6DBwKUmOXFpzwKlw6Gvg3e/O33HDw8vz/sK37Z0MNC/PLRf4OX6aM/cVwAGdjm20z6zlhcA920nNKuKJ8l9A8hEyXcKkqQmlCK7oacQN2blN2HDAFMr9bPa4TNjE7xjYklSA3KRpeFLkuTTMUEH5pJ0wuLYYB0+HyV9UIvPuQKezpWHSowXHjA8G/FXTHzjdgkAD8kXZbvTf2C9BVd3ZIDdlVFmAAAAAElFTkSuQmCC",
    },
    "D58": {
        "description": "foot",
        "pronunciation": "b",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAAA5UlEQVR4nGNgQAZ7/v36l8aIIvTq9rboD0woQv/2tF5gRhViYGVgZkATYmBgICzEpoAh9F8WQ+jGfwyhl5hmMRFlI9FC/9GF/jPw/EcT+qln+AdN6J8Q/0l0s/79/4FpIyNaqGI6QpiJkfEvilCG6evPnw2QBNR2/rhlwrbhNFyAS/fg/69bGFQuvIHw2VTs5v9/uzqSgUH98n8GBgYGUY/JV///vxnAwMDAIHv6P4ubtLaWLc+lhgt3rzAwMDA8XqnD+JyHh2H2h3cMTP/ZGRgYGP7YOTJ+5GVkePWXjYcZag3LcQB0O0YN5bChzwAAAABJRU5ErkJggg==",
    },
    "F17": {
        "description": "horn and vase from which water flows",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB30lEQVR4nH2QXUhTcRjGn3M2NtzMOYYfaBFeJH4gFjUsSI2oi5hx0AtDbTOym8iMblpI0E1dhleFMrVAiLyoNAJJvJC6UiO/pkOT0ViRxba0TbDp2dNF5yxXZ3uu/v/3x/PwvC+godzz7tfk5lC9VfgXlReHmisc+sQ7kx3rQyixpOLO8CrJnnP5B1tG+R3BoKf6LzTl3icjr47qAaBynuiOMnxRSRBrFkjG3eXKd4CAM0L25wAA7F858Ylk8O4BAJC+EYC0RNljBGDw8Fpe9/QwydlHJxte+DkHALU+sg/AcfkBYLSYz9xa22Y8QfntFQBAY4wbRyxt3JGUhoUnup6/fHrJpvQdJIed9F41ax0JaIpx9cNimTYEdBMfOyK3NYAIAJBHiwIztop0bmS5x6q8K3VpufVHQ+FMwGVIg4WmUKmtN/ZGyhdTxuqjfrLvxi9Xe93stD8u/2+/7Ps8fhY5jvHwl59MSnUbnxSsuUIP+7eEfdsFzYYEdnUCpcMqznpWc9rX6bRv3Nvy7ogQCEC8fkHN1t/hKUB383Egyj3SK3j3/WYIkHuEsuzU7n9kGBnJTnsUoDreqjVWgxz+qUzYtL82E14wH9NolJQ1sHIogzs6VlqsgZN7T1Uta+DfRRvKnmZZdJYAAAAASUVORK5CYII=",
    },
    "E7": {
        "description": "donkey",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAACU0lEQVR4nHXRXUhTYRgH8P+ZZ185vwbN5cqapBWaIUSUJLqRmCCIFZQV9HEROqmoiwhHdwaNNCFBGUYxD4R9EE5XiGQXiqzWlRpNyY9s1Uxw6tZmO53t6WJz6+L4XD4/3uf9v88LJKqg04DNizU+WjqgUMk3YU3TX1o23eNqU0Q5Z5iIiGiuTJSzB2LsvykTY52NiP4Qha6LX36ViHz9keAdcS79SNTT9ZYeM6Kc0U9LbeWv6b1elNmG4OwFeTNRs/j04l/0KQ/6evu8RSHCWfe/HiqpsRdD+yw6dvt8frydfnZXbHplJecydmvl9YvXsipLIqtzvARAJL1w9stkewCMN+0lnRyj472Xw203Vuz+DIYBQLy/9DA/0zgCIiFiTVVwQp+ylTfLpPJYyVh9GSesG9DpXXeoAMU06VoW8hKxZFKg6gdZoCqo0AAAR7O28QQrbz1UoHZRcCTf4aEFd6ZEFt+hgUw4M/90kN3wlQ5Lbqh1VOv5EGZAvAp1vXuCJut/K/+uAwDBFWAR5ZVGPCnKOdjCJn1cB3hta9lSkGT3UeASJiJM0uX5Agty98T+zLmP96nVYSF5nAl1PSB6lQkA2D5Jb+qGqd2Z9NPBc3lEXBoAoMA3U46m3xSVJNyc4hYmIIk3sj6PwrmMZPyGcHTL1gGaPgIASuvPGkDeHR3c4Fw33ZWwtf61agDYFnaxAJ6vVsVZao8ua4D93wLVANh3gQYA5hCXGvfG0GohgIsRhxbAKfIUASe8dCWeprCj7xiAvVNTFQB2jgy1qrHjBQ1q8A+aZPlZi89QmgAAAABJRU5ErkJggg==",
    },
    "F45": {
        "description": "uterus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAAAqElEQVR4nO3HoQqDUBiG4c/DQbDYDCoMHINhsVpM3seiS6KXYjGt2mWCN2CceC5gMJYchqHBoGFw/oWl1eW96X1g1zQTpZuUaKbaVs7+6W4fdtf9rXhsjxdQjiL2F1r8uEBOTHYYMrVBo2YDOsmYowtuCQiLC91haGXZT15CiTf1pWzhVjRGPKSQRyNVLqCZBhBQABimBo51BaBAAZ4AGL77+ye/QJ95AxU5QDvThsRSAAAAAElFTkSuQmCC",
    },
    "A11": {
        "description": "seated man holding scepter of authority and shepherd's crook",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAACBElEQVR4nF2RTUiTARyHn71ba5pl+3itIZpfA0WKUaFERXoIqeiQUKChtzp0kaWHCDxUUIdBIkSNNAWhURBKQqF1WoZKUIZmq2XlXNRyqbmJ7qO9/w5LqJ7jw3P6/QB0bkmd4z/2xD7G3P8qpWlivD5QC6Ueb5fLnpEVAbnUMqegn5BkNOGzAqB77H8rg1Ce/Nl9on1tL6CDfuPKsmfC6rHk2kyNF0auAKgv43VATeTkEWfwdchnAGjRbgOYBqZ3MiOSmO8zczAcdQCQJ6OqS7RPnYMOBmQqB4AyeWop0iRgBuZlLR+gcGTSQaX0f/EaYGEmdc8Kph45jsU9vqVbrhmpNbXJk2JcIq8OP0s0O8KiHQDokRfuOYmtrsjnnK6vPrkKYHsoIp1HE6Ilh2bv7l9cBGD3GxnOy17VJC4SPDsrmVFK24sxLUv/mUeaiKQB8vtuOcG0POukXm50hAXgssiKeyPxOwqN6RJ9QbUBKCLwvVXt0H3T2DQTTYdCCjDGgxpX3bBRg7KkAArgpyq787qKWX/sdHz9JcevWAGMSWpuScatgAGIBipODVXafUF//FDRemkZFfnwvM0INEza/pTmbdy8P70AsDVLyYT7golmyFJzYYM3XZApLxb+2N60o8oeGQ7vapDyEFDXuyR/8/78ZnQRG+9i+oXemuoUkC5RpbXjN1i29DotrvPUAAAAAElFTkSuQmCC",
    },
    "Y5": {
        "description": "senet board",
        "pronunciation": "mn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAANCAAAAADgPUOHAAAAOUlEQVR4nGNgYGD4/x+T+IfKZWLADhhRubiUoev6yUaEqp+M/4kyjQXDGVjAf2LdNpiVERkgRJoGAD9YEwBxJiSmAAAAAElFTkSuQmCC",
    },
    "L1": {
        "description": "dung beetle",
        "pronunciation": "xpr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAAB/klEQVR4nEXSS0iUARTF8f98Mz5T1NLUCukBob1wkY9I05VCEhQkQrTIwLCFSAhp0MKISmjRxmiVmGQRRWAmhdkEZomPVChlwpocH5VaptPoqDNfp4WO3tXhdzcXzgWAnZ8qAGKyI1if4xpIBoqG9q1bmEOD+4Grag5fw3qpBqBSyg9Y7E/NFweHhBvpTvXErmLJvOwdpnR/1zWpacWi3qmnTq4nLabautUdD0Cp51/aTfM0VP725Y14SgEOjupi3pgjKyUl+ZWuH1tsjQOjWoOnJuV2uUbHvVq+1TV/GKJqNbuo1rQDqam1Iz7J786G1E5JQ4kARF4akfy5EFLyrNn7NHBy9uTs3e1A6Kb4sdG0gP5qD1sJwU59zLACWCv0eHWb4FqY8TftTdxS8FZqTAIg973ac+zuqc/OKUf3st4kAVlOmVUEn3BrunzP1i+SPZPNddJSBHBFj8AyPDetFm5898x4bcBGNYDlzvAFh2lURZefWzoCmFgB4obLvlFfbKv29UVDjBqBr3oemUEQCf3y3Y4iWg1wxqOpTGw+QoXtvL9mWiHppUUWT3gQQFKfLrctjT8wvTN6mfvam4UBFhsT+Wf/nDT8k0cLBkItFoDIh6YdKLtXCMR2zR0CoHBhcMda3f2d2zCAD3935wTQuqHjBwYw0U7gBbD0vjD5D6qM6+DAj2DBAAAAAElFTkSuQmCC",
    },
    "V35": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAYCAAAAAA9/JnTAAABBklEQVR4nFWPPUuCARRGT2GRYFAguLQ0RUvQGARNWlNEZElBQ0N/IKEQXUOCwFmioKWvIWrpXSqEhgJ/SEsSlBhGnAbr1fcu93J47vPcC6myjTSRSmXUapSV9U0vIkxr5PUyyq6gpKfR3Q0o+NUDx2Z0C4p63aPM+g7s6W0PfPYe2NWVSE4cyNue6rKKgwCBwQRAP8AIbYBKe3481J3b6WfWun7lTl948d9x1tzflPMufCXceHAOgMRHM2Qlz4cBkja6ZzVMEoM1qrD9LQzV64/LS0fAiZuTT3bqoOjrdB/IfgEO47R24DPBKmTUYHEAoH+9qQaQ1pswYkkVsj/HoyGLpYNW6xfEC4DBKb0AHwAAAABJRU5ErkJggg==",
    },
    "A22": {
        "description": "statue of man with staff and scepter of authority",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAAB4ElEQVR4nFWRX0hTcRzFP/d3r7tad+Yaa+EMsYikon+EYFKpUaNFQiRh5EtQ2VM99GD5FhGEC8MeYy+9ZA9RIBZIBYVhSLL+mRa0hQ1bs1g629yu2/31sEnbefue8/3yPZwD/+EekDIgKMHagYXgyIeDQJGwpcN43P61uZRcGbxyRJ/JAlrRfexm9JY1UxiMVgBqRk/or+WZAhmI7Aag7wben68qAGhIyzag6lniEhzPPlARoObYDPgP2HMQSTY3ooGUdEeGT7Xfd9mAnNMDsCd+eyQxLu+tuDC9mq6sDBgCkONev6vnbOqjvUw0JV5ut2uAqEhd60tCZtF9smNowieXzScBy7pbi00HDaRSUIxKZ6evLgcClHQEmwLst3kf/paHM1KDttnBjRfNJ9Hq02OJbbX1nrflwOg7Wpdk/HNYzobCKSnNFgGmxVz42691dVPdRwdNlj7F8nkG6zdsuiMffakaDsn+nZOFxxIM5XIPkJsqTr6/6w+95yKiDIAXwTxb891y0yvPl3TkMIbmUSgtzuF4niZqKiBQ1eWKf7yBsXkBgh3rzfzi1ekQbK3MgEBXnwKs8rsmY1Tv092gkTLLm3StcZcPY2/LoQY636eU655j6l8hnMDiwhrAmov/A6kerawyOvHnAAAAAElFTkSuQmCC",
    },
    "Z95": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAL0lEQVR4nGP8zwAFLNMZyAaM7+CmHKfAlCswFhP5hjAwboWz3uFTR8CUaXAWPIQAgZkHaeEAYTwAAAAASUVORK5CYII=",
    },
    "U11": {
        "pronunciation": "HqAt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABaElEQVR4nKXOzyvDcRzH8ef361uT1qgV5ceItcRhygxxonaSg18npyWl/LgpfwLJQUpZO+zg5ibJAbkImwwp1kK4LE1t+RH2/b4dkH3Xbl6nT49evT8vyIpnX2TOTk7aY5J+kaAthwMS7O6JGe4cXtXbYFaaAfVPbeVGEkXJ6OZyRzIM2kGs2ty264sw03KcMLctDmvBtL5XnjsQWhNRJ5iPADWloXgeNtglD8N7flbyM//nV56/H9qvFLV5am0OllOPN/snnz9oGY2+iBgihoik9gZ/uOouE1kaqRiTLtfUypWcA6XDDholVAwMSD1QtSMqWAMb3g82U4CCCtwfosL1uHO+hEzWIB1NqS8InlnfEPNuZWJ9MrxrYM3CQsB9mxmkQbbqgD5xAd5T0SpPO4cueIr6zo4j6010uHrdHnWb5EIJoPlC58/ynVR4sV1Z61/1fwA4nWVFAOnE5QOa/6jQACAez/r0C15ghxsNJyauAAAAAElFTkSuQmCC",
    },
    "A30": {
        "description": "man with hands raised in front",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABg0lEQVR4nE2PS0hUYRiGnznnjLchxwszjigEkWLhDVeiiCLSIpnMXbjVdCfKBKEiiIi4ENFyI7rQohT3EiWiIhltsjCaQBd5P2dMYmQY8zLncyHM77d7H573hQ8wuLlAVKxagLZqABoPBkeDvx5yj+U/5YDvd2iqqlUC2pDx826HE9rTA/SnWMnIrHNYxhIZ+2fgD3d5GQlNOZekh1qzi5KT5gQSpqUvb9d0MxP1Z4+fN4BnTV4OxCYzvlrDuBY/AEVh+XYe2Tp9Bvq7DYA+ERGRjzr6+zkNeP0Z+7iz6X4JWQVbAPgqSlNJvejlhd1rAJgmEJ0uy2t2xD+DrJzKt95LhxYH9Y/dOfVrScp4U9D0KGhpyvhvzgd14xZwPT3EYRcp4L6zgH3lU8ATs9DTYmq0O7cn7Kn+Ec/siUREVlWlkU/5T2KGqtSxfpgWeqAMH2ec/U1XoCqyyf4mt4zt74itgNe1c0RmceRmNKOmtMZ9Sfnzwg0HgOZv8aCtfHmVuzdxDTqFiI9pREi7AAAAAElFTkSuQmCC",
    },
    "T33": {
        "description": "knife-sharpener of butcher",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAASCAAAAAASvfPJAAABUElEQVR4nIXRTSiDARzH8e/z7MWYluxhQ1FcKCeTl4PksrIDhSMprxelkIuDHDiQKA7kxEWtOYgU0fJyo0VRc5iL8hJKTTIbfwcv42DP7/z51a//H5fLVZpFgjj2ZBrjSGbYtH+QrKz8o7QOJ41rynBTMQDeB5PZ709So6HfKLexN68vtHqhkHaa86c+eW62HO/QrEV5V2eBvqn5LgUyWicAvOHcK1us3gzApqX6uxYsst8fKQBVbXXpwFxg/bpHC6qFrTbb292NMxtgx3s4WtvyVTEtLz2KiIj4qmvcKQBVgyIiZ4sismtRfjbZG147tXdDqsHBy1bKS4UWnzvTG2c/qWgXqyrPT28gt90FJ9v9kfxEhwUISDkBGddRYyIllIlfh/lkCGokpiZmHowABh32CiCgw1QEhIjOtpA8V+YFZUOHDXy+xqPDrAsicunmA1ZgemTrxIAwAAAAAElFTkSuQmCC",
    },
    "U10": {
        "description": "grain measure (with plural, for grain particles)",
        "pronunciation": "it",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAcCAAAAAAhXDLDAAAA5ElEQVR4nK2RsQ3CMBBFj8ITgOhCaxZAInQoFYnEHJkgihjAS2QKU0BJgxSkLABig6xA8SmSOD6BbQp+42/7+fx9JhpVQglhmxJKEFMFxMI2FbDhSAIgsY1ZMBIFUDFT9uOICIWCGVKvA/2gCZ/K7W6+NrNbe748OJBqfEinrIredyeJ7rQk6ioeWRVAy8H1F+vBGUQSR0gat3qqmbXxzUVAO/MjFANNAKFIZT6kS+LNEgHtNPCiGGjI1Ze+u4v8evJ0d0ji+iPTk75wrutxu9a5ZEm8ilQWQgIaw7ovscK69I+wbxBrzi0/WR1AAAAAAElFTkSuQmCC",
    },
    "F16": {
        "description": "horn",
        "pronunciation": "db",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAXCAAAAABCcGJ6AAAA9klEQVR4nI3NP0tCcRjF8dPFoeFqDQ1GSwgOFUS1NAQN1dYQJA7hK7ClMXAIBWfHXoNLFBRCxU0oMAdb0sClrS0wCKK/9G0J4XeF+3jG83w4j4BiWmYKQG/SdkWAU9uVPoET243eAce2Uxs4stkE8OPbrgJ82C4GkLPnqsCtzeI8TRPY7gG/xJrJFukkHzkcwq2oxZnpXq+lOhcLBtuhprEyVOaj3T1z0mYXzrdXI9gu7VlJuRvC+XJcGWqStNW8Ci4dN+K4aibWOGjqTZLyye//1t8feJx9BzbWZ5zyObQmSUv1hKQXr3/5HZcGmecn9lJTy275BxPzhq8YBsiaAAAAAElFTkSuQmCC",
    },
    "M3": {
        "description": "branch",
        "pronunciation": "xt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAJCAAAAACQm7qSAAAAcklEQVR4nIXPwQ2DQAxE0U9TnHIyfVkKBaSa2SMUQBdUMjmwsEFZiblZerbGOHnOYKb1HAR81h5L60K2bSvjn6mxTGmvVHcaboyQraxHz0i/LNK2KpXU8ADEQtngDWWbwVDaD/FiBLiWjiqyeu33Xtt7vpJcZsMiJjG7AAAAAElFTkSuQmCC",
    },
    "O35": {
        "description": "combination of bolt and legs",
        "pronunciation": "zb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAATCAAAAAAy1ptvAAABAElEQVR4nH2Su0pDQRRFV2LMT9gKgoUfYGFxCQQEg5UELCxsFAQbU/oBdoKglaidnaD4KkREsLSx8IqdiEUQQQTBV5bF1ZBJMtnFcPZhzdnDcKBVc6rZEfRzBvZil3kKa1QHB4K+gbbh1BPYCtvBjSxRH62HiW0qP6n6Uc4F7XwbJg97UKQtJNSBLjOlzvaAit8KbOpOj8TDPqaBF5iMj0p0HWBIXYpSGzoKwKKmscRChdUrAJ7hJzbqXIf/yo7/bmpcq//1dYyq6G3TJBFqRV1ourQbNXF0o74nmRs72+/yrtJntgolAEbuOrelAMz083r5la83AKjdpw1yb8et1C/YW5tijs5rCgAAAABJRU5ErkJggg==",
    },
    "O27": {
        "description": "hall of columns",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAABqElEQVR4nMWRz0tUURSAv/vutRmfMFr0Y1y5E0EUFRcugpYtkoHQpVD9Be4ENw5GCiUuXOhC09oGQdA/UCDuqkWpkMFUuEoUHMdx9P06Lt57M+IbB1x1Vh/nfPfec85V4lk0isAY58OR18AwmcdG7413aAkPXLgv0AKo4M+CNrh933wN4JmaEWbwdb+LAc6W/gH0jORVrPQ/em4B2WeiMEDq+1uAVfdV9ZZ35TmAJ62WYAFiIDcIQu8owGgvAoM5aBIgfn/87phH95p6D0zKU1f1vNn7GA0VKcWu5Tv26r0dgMPO1+1tK7d+RaV4Tr27ua+3CxpAF7YPrB+7+pKC/eLnRj4dcjpf+DxjV7cXgypNSTEaWhUnvBOVUDC/uRmzLpCtFhr/4fWVAIJ6XOtFsoaMRNzewm1JKMfrGU6+hHz61eZoK6GkFn30AzdMLvjoh0nlZZHUeqg0TZ/Rmku0K81QXagNzZJQro7/oAhIPb6gpCFdj7GQcBeUoRxna+wKxs/OVgBTmQWcMO/MA6cAlZmSb26MlBzAGxhQCJ8A3PtDCuEv4AwH5hwvt40AvdfhAwAAAABJRU5ErkJggg==",
    },
    "D9": {
        "description": "eye with flowing tears",
        "pronunciation": "rmi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAWCAAAAACJLLHfAAABrklEQVR4nHWQzYsMcBjHP3Zmdmd2mTU7E22riFJqLustaaSNg+SCg+K0kvwBLtbbhSJRllLKQZtanLZWGRZFbNokkU3JZYld42UZM9jl4zCvtpnv5ff9Pc+n3/f3PFDSos4hKxrqTIapaFbJrOluXx+t1L/filyeTDNDsTPqlGZO9/3QB8/HVL10LNlSTUUn9MnxFw4DHe+8ABtuXFP19dZAOXTum1h68Dw+TAGsHPkZAdg5J7V6QTN3n4X5DRD/Yi/Q6gEAwmbLMV3DhYmAeRlvAzR5tTCyuQLTvuTOn5xmn768RyDxVW8CcMWLUVj8wUHCtO7b/Ul15FwMGukdV7Vv2YokY7rnrHpyVyFqdLS7lP5Kl1//q2qmar3ms6sSVbuIty0Feh77n+5vmbnZoubrjgZO6HY268Y6FIedBg5qCo74eUa3oWQO8Q0IQghCxPrrYHkC5WI/dNTBoLHsxiEVqY0F2VQuZvbD2poTrNNm4Kh2Ac36seZrIZgNpf/lfpFoq4XlOTUBvC1e90KyVuiAXQA8KpxxTQer2kW/MDeQB+A9MYDpbU1TLZMV7B8RKOFHtOn53gAAAABJRU5ErkJggg==",
    },
    "T16": {
        "description": "scimitar",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAABH0lEQVR4nIXQTyiDcRzH8fdPnj1FkVEr63Egf27LQZaDyxO7cFguW8pBaQdOc3OguEgpLnYUrRhycVBzUbvsIruQLU5Ks9plLXtmPF8HS9jkc/v2fX0P3w8iW/yfRvD1p+vvPL1llO5QdqlJCbwHTn6B4VCl1WEFAbD0Vx0lQMXxU43FIZ6jYNnKuX8Jm2GWryQlB93fUMti8do/5OpwG4bRpQGEhb6oTHtFZqpGaw7eFHSmFqSayPrGmiWoAXnEvJOniXHTNEceRGZhVSTpB2Avk87cJo+BeUnAUs7+vD73waS8ddY+fiSjANunsdhZD9D2Iu56BUUl7/kaAiK2q36ROyIXc84GDW8oJaXdPxTa4GGinM8+Z4tyv9KuasEHYgt21Oi+w3MAAAAASUVORK5CYII=",
    },
    "V20": {
        "description": "cattle hobble",
        "pronunciation": "mD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAANCAAAAAC4QtCeAAAASklEQVR4nKXHoQ3AMAxFwaesZpgFvKhZUGi4B/ASUdAvSaXyHjuglyRVB7CliAgtA9sqBy9tYyodwFOTlAOAK9HgGmqcN4fGx+88bwoj2cCuZG0AAAAASUVORK5CYII=",
    },
    "B4": {
        "description": "combination of woman giving birth and three skins tied together",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABqUlEQVR4nD3QQUgbURAG4H83LxtFE6gkBks1FbRKSMCipCBIxUNFFIQi9VIRT71IT4Io6MUeSsQKXqOFgoWCBylWtFAFoygeXFBaJNXUaNEEW6PGYF42uxkPu+vc/o+Z4c0DjHqRJJqvxH25lmjhw85ooZmFIaKVjoDy0oTyy62lq9ij0HaZqEPv3/PSbod9uqGW6VDEQkfObCYR7jJGaq/lOfmLhLG0uaQ1RnRxPNCXMnJx3Xsi5ST6/8aA9nhq/Le6Latcz/6fNFUgq1mNG/CZqMee46kM5yIAFDjU4yfCnhReZ6IIAM8bv80G+LvbxXlLSgSAmpJB7TC3d7qZRL8IPGx5PfyvK0YWZOOIipa2hZXDoNWbAEggMFbzyRUZ8fapaQDQQMztynu+2twz30F5qQUVrEdNHJx+jJwBIM9b2HEQbjae749u8g0faMI8uGiS8qtO4VVQO/qjSZSzKdaOUiQFeNv9vqcRoWq33BGXoX9pZzrwJvp49EcToMvVzS9lOba/v26CxKz5eklrLTPB49SUZyXZ6gf3HSAAgMUEDkFau2CcA7gDIjyuEFiRq7YAAAAASUVORK5CYII=",
    },
    "Aa40": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAABv0lEQVR4nHXPT0iTcRzH8ffzbOnskaEmCxokSAjPGoa68tIhG0SX2CGwQ6ZQYVJHwS5e09tzk+heQXQQMZVouQnZQsIm6mHNGc0/zcPms6Ej/8Svw3QO93u+l9+H74vf7/v9QUlpxoGhYVGOflOY/Q4L1XfC98I7uhwV46eOHjMUqVZmhoEXmSr5w7FGoDHmlerbqAIo0TcnLfVk7KWEAESiSTbYl/QD4E/6JHc9zqPs9Ej0mjYPwA+tTaLn7NsAmHZXuapnjrJKRUWRh9yF80ZqrRBsqURzUcWrwgd6f70e6qlRgZ6/HcdoH+y79RFgr/56zeFIaC6S3o3/OVZFG/U++Aw8eva84e7t9S397OJKZO8AYGMLfCvrfuC+ORWMD1y+syTmvnxfFkIIsb+hQPuH3Eh2oN75aWJiM3Rh7eW0MfuuDjxNbhdVvdMRITIL8WU3BIIPndTNPy5u5fg36wgnf4dvjncPMzYGPGkxOV0XJ7MBAALZyYYypfp9rhPozI1WlyPYot/O4/q6YJMhdImn9Imuko5akmdWr1S2rc5YaH5TRU3lLTQdaqn1BtMWymJr99UlrHR/dzB/WNr4D2VMlvXv/829AAAAAElFTkSuQmCC",
    },
    "P11": {
        "description": "mooringpost",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAAqklEQVR4nAXBQSuDcQAH4Of9tURYcp2S2MVp5SJy4eKruOwL+BqKzzOF7MLptagddtBKKcth866/5+G6lFKilNtnWjd/+iXbvcaqHJ/eqeRKrZLL+h4xfEfUDaK7gjhoI4+dDeRlv4cMnSBPn13k6+NivcjPeO2skfmg7C5F/XtetEy+9+YlJq9bnSqqwc5hifKWNmwummWYjyMsHirBCDiaNcF0lGA2rf4BTd49PjJ/ThsAAAAASUVORK5CYII=",
    },
    "M35": {
        "description": "stack(of grain)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAASCAAAAABON7DtAAAAjklEQVR4nH3OsQ3CMBSE4d+eIBtkAWhA0Rsgg+ABMkRWgQXcILmAENo02SF9MsNRGCNBwXWfTicdAFWSUkVJL0l9UVAMISq8ed0MbE2lHAEeOoGHA2eAC0fw2J4FYGFnQFhjHsU1ALO6zE4zmGSZJplveE6Z00jjW27lzp3W1wyFA7UT7vNdeL7yQ6d/7QseZzEC0KfhpQAAAABJRU5ErkJggg==",
    },
    "Aa16": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAALCAAAAACxVUmcAAAAhElEQVR4nGNggAAWDbdn/5EAC0RY0TCCS5IBCTAyMDAwSFTmMTAwMDxkY4QJP2VgYGBgOPT/////pxqRlPMwMDBIHPv////fEgZ00P////81hhjCiv///2/BEGUQzvv//zamMMPUp//fyWCI8jD+Y2T4eleYGVmQiZv9GuN/LGacf8IIAG4RMcbQKzssAAAAAElFTkSuQmCC",
    },
    "M9": {
        "description": "lotus flower",
        "pronunciation": "zSn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAABvklEQVR4nGPg2vbh//+v/Vp8nMwMuABTwq43//7//XusREYUqzJGSYZfb6V7nT9/ZWNT+LHw9KGPr/+jK7nO9G7xma/xYdJJDxydhWT598259+njMxQle5iVZRne3T4r4fsl7q16mCcDA8PHc8svn0BSwsBgbMqj6CK/wlGOgYHhxc2XJuLHOa0/FJ+5BFdS+O8zo4SFhciHy/c+/3t48+yL2c6On3eYMlxc/e7qIYia71+///////+9lcGMDAwMDAzMyx+oMyz////L//8PJ9gwMDAwsAT+ZRJlNwvgtVfw+/T5yuGnf3/8/R/vwFByW44nJt99ac8PBgYGBpOU8gN/Htcs+P3//8/zm9fe/7zn2/8UBgYGBv3O3//7uRgY9h5/9P/f8yXGUtv/N9v7N/3//////4XuEEdwRb78ZcvAeJ3x/eKTb9hyvK83vIvxkubdue7R37vvYJ6JmPRen1GS8c8r5toYpjn2ohKvJp9//+E9crCx7LfxZWBgYC5++ev/z1PTrGREMKNo0p9zDAyO777/2+smwMOONZLZ7v9j4N44RYyZCas0AwMDA8M99FjFpgSPfhgYVTL4lQAATcC+OnONeGkAAAAASUVORK5CYII=",
    },
    "G46": {
        "description": "combination of quail chick and sickle",
        "pronunciation": "mAw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAACBUlEQVR4nF3OXUiTcRSA8WfDbThtlUtbW3MKhYFJX5polixRwugib0InZRCBtAzSi0ojveimwEuhSBPBsgRDCCfENFFyM1dislmmQvaB9k6ZLDVN/128c6XP3fnB4RyAzJXA/A8zcDUwONZrAFCC9VV78YV5hwXUfamlWgCUpsbW7xWLwyXGEkCJGpnnAsrob/vi+xvOxsIarK0AKBeu7R91veim74AZdqCISyDUXnEDsoNN2mKRZ3Z5K0wy61cuQWSlaDW0TWUaHcJdFgWgF9c51xJ3SzzZPjx9LKrQH3wKoJupYdSbye2FAroHLKiqVwEUV0b3uNJA43anNKxloHs0DoDxc5m3nDs90vKk8BhjPcGL8lG7lN+h6Rq3FM5KWfopUa+TOWHorrPp8lsFNn9jv3i2c/31mxOJb17P2sA2J1rCypbx6hiX7zConv+xhtVcK0Z2RagArP76dU3zuh8OVIX2WharEgFMD3zOjIahySLZLQ5RCtF1khCSZ9ru+NWZo0a9NblU2InYnTLC7w+tg6vmUzknHc683OWx5h7+dX/J/kkIR02Rnv+7F6RcfNnGxrTtEyR5A5uUdH8BNPtCk3Kdj8R8JD378SbWHH/3k6PGtk1syO+cIbnja5ijU5NBkRvp5UTWy6UQRxysTJe6VIZU1flDp5POxNdKsr8XG6qT9S8nls6jRCPwVwAAAABJRU5ErkJggg==",
    },
    "F44": {
        "description": "bone with meat",
        "pronunciation": "iwa",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAASCAAAAAAWSCP0AAABe0lEQVR4nF2QTSjDcRzGn/+02kajxmE1JZksk5dWkosclINMSUqSLC8lq5UVJXEQubDisBuRki1vteblQGskL60UagcN48IBjaI9Drb//v89p9/z/D4939/3B3WhxaIHoDKP/5JkfLjcoodcwqC5RDh331m1raYiAMDtfWYguCuHCACfni4AN4IAKFT5AEJHnmMZdFkFAC68TfxHrQ2KHgArO+siRU5hhHwwSPsrOw9I2kT/Ss7VeklOOwsECdd9QvYnTf0CRfmapHWzX5wXTd/1VYSMxUhyZ6XXWFaRuFA80qkDgP8JunDOx1iepkOrAgBs+bXhbWX8e2wSaDz8SbapQ7QDQNupL8Q0uaqTVPYT3YnjwNB69FFKbaQ+7JmrZalXLy0vv5Pk/ugdPZJtakiHdDvo90gv6hiQhqXkYoEMayF5xrgsK/4m2zXSxE+ShFx2kvQbchNWaY6QpJBG2RwmANFhDQDEZgwAEEyHkKWxNhuNon25yNhc+wNFOMFOQAIQ7wAAAABJRU5ErkJggg==",
    },
    "V31": {
        "description": "basket-with-handle(hieroglyph)",
        "pronunciation": "k",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAAoklEQVR4nIWQoQ0CQQAEhwYQeBQSeeYKOAQFvKWTt18DaNS71wd4DA1gEISgng7IIIAQCPDrNjvZbBa7tF2MoCddWp9noPEPEu+FQ9I/LqqUuoBs/sXFbFZKT5D8xcWs6eARBYKavlBJDbB1txGg0DZPP6BpbrUARld93FGpzl+Vaa5a3c14uS97z2AFcNkBhAHAZP1tbz/UTfs4vm3q0H9Lb1NAgBbUt7M2AAAAAElFTkSuQmCC",
    },
    "T8": {
        "description": "dagger",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAA0UlEQVR4nAXBIW4CQRQG4P/9szOZ3Yptk7o6HAJBCEeoQ9RxBS6D6R2QVWCaXgFUBQpLQtpA1xB2Zniv34fxzsx2Y/l43fw8vX0hLQEsk9jfr8nzY/X5MGq77zuAla0AzNcnO63nHM7c0c2GPO+nL9P9mfABwYNdqFCFjoe2QdMeqL5C5ZVwBB0ICoQgWKMmmMsAg5LZS0SUnjE4uBBpaNDA2IMgepYrwWuhFoEUpakTp0bNQUJWagaQlbeLF3+5UVN9r5NS0+R9khRxsbXtIv4DyvVWTY5b2U4AAAAASUVORK5CYII=",
    },
    "E5": {
        "description": "cow suckling calf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAbCAAAAAA1sqIBAAABYUlEQVR4nH2SMW5UQRBE327qnJgYCdSkPoklTsAZxilnQE1CRP4vMQiJwMiCCzh31il6BDOzu0b+7uTr91TXVFXPAeDVm6+vAf7+hHuAz794Wgcg7tirH/dj5ABxx/s1HR8BeAdvr07Y208AOiGPzxJuKtAnivRZGGod2/V3AFrs6fsCV+g4N/fY0u4RlvwPe3T8PhtQ97RVevy/2VRvAB6X2m+c2bpqNDVjdQIgjBTdGH91o9blbQ40KbFwQCzbkJnR7IA18Gpe6DoXCmGbtOqYE7eu1raQRUqb+lUNaFQHoivDjqHUJUzb2GtXozz1w+yXMO1/VCtp2la/KnM5b2pfnMTYiZpqVo4cOjhdJ2RXy2JicySR84K5CjXQNLRDWN1T2l3HXSPiFB9WXjyF1TYzhTDWm5lx5NrFMgNANUbocUqtoI2tK4wdxxxc4TYNyCEpGpRtHFcMlm181qt4of4BOWh7QNER+i4AAAAASUVORK5CYII=",
    },
    "C17": {
        "description": "god with falcon head and two plumes",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABnElEQVR4nE2QT0iTcRzGP+/v3bt3UOGarQJbzD+0CUWCiAgG4ejQIYLoEAldBl6GJEmnDtGhi0gU7FA05qhLiHQU1B0XC6QkcsrQnIexDnPztZnb0r3fDrbRc3s+fHgODzQTFRGJu1rd2BSxrUqfaoLBM1B4e1B1NEHwZNb5uliptQyfnXEtXhWtZfiM655H/dVGazQhkj+0Z0zFqfMK0NuwXuS0Up3elDxxQSArIiJxJ+9+JXZv4Z4XWUqKrHepVSNhh+i9yat7HyuxHg89W5ZdvGGMlm8z+36oEeHcJ5F8WGNqL7p5wZNep2Pu21EUuFKWSY1pQbX7UzFAyy274UFV2aXJwbtjIJKzoNNUYOhtbx6CCJwe0oDLMv90L2T+/ADBH3kFmd/ZZxsTbocDcivbCiR5gsjIxJ8dqFt+BSwE3V9mHnu/A3QoYKXbfzS3bxx/pYCy9yLpz+iAoIBSJkB9ixLoJgD6y0WTvrAHfF/XABivef9dv72gAOqmfgxqDacCOMuwCyAwYF7SgPvP/RtrBeCat90BcEf+y19Iw6doj6RrSQAAAABJRU5ErkJggg==",
    },
    "M43": {
        "description": "vine on trellis",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACwAAAAeCAAAAAByXaN7AAACf0lEQVR4nJXRW0iTYRgH8P/3+U1NzcPmnFvbCiWQvLDdZIeLCCPDKKmgkIqEJWZgFwZGJ+yAJZHRhUQXBULRifIIFWjbnDSbN0FUjnWYYdg8zaZ+zu37tqeL4fbtojafmxee9/c+7/u8D6CxfgKAg3Qa0mgWXgPAJV9ZNMdifEYPIKUUlhh8YVS3DkBm6mBMutZ/DtDw9ryYLG5QA1Dq7GaiKS6L+cXsv0fX03qE7BjsRo3128b1nWl8NEdEJFI4QhSJUGRxaCOWaaHU4xmW31UyZ6e8psOJ4JHcOxwUxi5nuWFg7KilQG+vckkubKKGIsG1A4fpPKB2zBUD9aFb2EuVRVRb8p1aWAlWTHgnQ+3Yt0CONewVorvIGCHxWJZp8qe/EsUfA/XSXoxE3g1KC9/tPaMcEKcGdS0LLuEBTi3RIyWwh/9cKMFFP+gJU8HfX/vldr6NP0En349tsi7o0u3TuQBWPaZry0MB8PUlLlKAN3HJS0zyqzchgZaGR9PVPO+fBuC7+menOoqD8/CAUg5tywfL+YPvUmfzdmdSAEx4II7ezQcko7lMcig/EFF5jpX653YZiMi2Gubx8HY1PZQBABc5MNVUp+g1Ca1JBe1mobnCfXM+stUHncIdUxnIUbMAVPpsAJocIFI5wzljiK0MzAIAJgAA49KvhRjujUUC4bfJFQljYQSUMIYzvCSGfSvBzEpwEEEAMi6ek/XoZaIKLzyhwNQyZv6ptYXDPreYJKYbZHGxaNGdHUpiRGztMcV9M3VlbQcXBMoUHfEbHHpmVBGQV/3UFh8vdmprA4Q67XM+7m+A7TM3euxbGt9a8H+8CID1tJW0Tss9bbP4CyvVGNYh9wvDAAAAAElFTkSuQmCC",
    },
    "Z91": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAECAAAAACfTYFWAAAAE0lEQVR4nGNgQAKM/5A4TAy4AAAmQwECh6viJQAAAABJRU5ErkJggg==",
    },
    "V22": {
        "description": "whip",
        "pronunciation": "mH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAZCAAAAAB4egMKAAABGklEQVR4nI3RoU4DQRSF4b+IKsQoDCXzAJOu3CAwlTzCprKWV8CSPgBy1TagEVCP2Ca1syEkJAiyi8BsSqb+IEraYJg56ib3m5PczECLrvEv7GJOs/FuavznhkMGggV0jScbjybmeL/Z4p8f3jZ7tt2vtv69azxweLK6XX0ASM6uZddS4fgbN6+DpLZ0UGpOJWck1ecGcNVvHGBKSSqhaBUkSQqSQggh9KEPfR/a6ibHSP3cMcBeD7u7KY0nG58M2Z0DZJeTEd3FfXa24f/YSrVVEVFAFazqOKO2tWycFa2Vg6MIWxogzr55SmF4xzSBvcIoZoBcahPavsAktNFLebyNR7hKaMulkMBMkPIEN1PS77OUUhjrNDbTD0kTkdMNpRyqAAAAAElFTkSuQmCC",
    },
    "D51": {
        "description": "one finger (horizontal)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAICAAAAACw8NI0AAAAZElEQVR4nH2QsQ3AIBADjzUyAhtQImULNvl5yBqkTJMaKUtkBadBIgVwnfUnS35HJ0S/ERnhcgI4Kj4NhabpF567ntdAEkgGJuVFl0TRa1pbSFDUrGC5aAJg02PHtVfscb4A+AC0jmHJinqrRAAAAABJRU5ErkJggg==",
    },
    "G19": {
        "description": "combination of owl and forearm with conical loaf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACoElEQVR4nG3TfyzUcRgH8Pf3ez98ufy4K8uPJEY4jYyUXVIq0Vpqa0xWq4XKbM2KSaph5UetVcsoobS2GlrZsrE0p43MSouIuNoJ+dWZuY6783364yRd3n9+XnuefZ5nexgAgPhCCA8IewvU+DdCAIDvcXaQIXHyYP6yHOwQ+UFAVpW+FnPL8UpRbEm5v0PzIdnIcsxDy+WhzbDe1oxNySIullQ+bqpiyZ8nJiwj2RUA1oixfWif/0QxBPFG5dYFlrUQ3ZcC7m+vwar9sfBqjMx53cYXAwoTxxl+tPIBwKnZPhbF+gCsGjD2ZNo9+RwCAMgdD9kyvRmCWzffK+DcVoGDmtMeDBx7B9wB4EYFXLsUbGD4ve40DBXGxU1plf2EkSSnIgkATEMkIjZwrOfRtijUlOZMsjksAGWhIhrArBgGPSOM4WMk0hyXqjSvgoTbKWVa4DKXajvNe8rl4yIwRgEA4FVfUPCDSOsmNRhy2iUBgO7OiHCk12t1Op2OiIgMc0RERHrSa3W6eWq0BwScKf4qPt1iQ9fwCWtW9rrWxoLjOOGSxXItLZ0OEF8xlvkgVJ/JmC++Mb35LMDEtXf4IXvMz5yVR452OgKQvhzJt28tMS9XJuJhJSDykqR+f5aiOWzOJxE+IYd/f5Fl4Ke66gH5f9VRM88hHaJs+NwdpSbbper9RVPbMD8e7tFXp9sLy6dENRZL2E89kzf60Ui/NB7F9TIEddBUwpLB5d/KEXaJb61ug5s6DdhDNKn4y2d0wcCB8d0r3IBc1WqIzhFlsQB2Zuz39PTewfGudmv1P2e+AqWUCMP1ixQIIHqWFjLzhqZM40Spklxgo2xggMII/UJ/Vjh7p8p0J/HnDe8MocMMIJXwix+gxTPw2HRMZKj8DakSFWcStUX6AAAAAElFTkSuQmCC",
    },
    "T2": {
        "description": "mace with round head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAVCAAAAADkj3hyAAABAElEQVR4nIXQP0tCcRjF8XNBtKQIWhoEMdsuEQThUkt/BtGxwTloaGqJCBqaTGlpiKaoWWoRKuoFRINvwCAHL5Q0hQVSYem3QS4tPfye6QwfzoFHGvO3AepzUdk3kb+tAXCdtpF3tyC9liOxtZQmA5MBrEhSka5dBv3FQdphyVRXnbcwvuybauamF8ZLVi2VOKLwtz5ksVlYj0iS0p/smps+ELRaT22A/0c9SfnT7rAn/Xz0vn3podDsmI2DiyfPgYpDSUqW4Ks65XR7QD8wvxJetALwfuxy82cAzYNRh8vWAR43XH2ZE4DnwxGHy10ANDZjrt17gC3PwcaXs9OZ2i9d7nlcE9hOgAAAAABJRU5ErkJggg==",
    },
    "W20": {
        "description": "milk jug with cover",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABDklEQVR4nG2QMUgCYRTHf3ffl4T0tYYHLYFTLk6O7S6CYHNbuEZTg0NEtJlbbS0ucYKT0NwmIhTRmIYtEbfchWR6vobvoDN6y3u/93//x+MBBPK+x29cfcvrboobc7lM4dqF3NvKBZjffW6QjofHlAoOK8j/qG2KU3ho2OKY6Nq2piIiItNkojSWTkfGpQR7MsjlBtKzVAxHBSiMwiIAbWkBtKQNLmRlCDCULOg8JurnHaQfmTyOrFzlHLkHOw2WuJy+3CwBP7BK4IP2MMpDcFDG++vVZ+xvn68DXyeTWwB/VgYoz3xw4TlT16DrmSdreFtUobqYJM9pqgpUVDNZtxnE3W78YRJUtVAkrCngB2pSXyuVLWx3AAAAAElFTkSuQmCC",
    },
    "F27": {
        "description": "skin of cow with bent tail",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABZUlEQVR4nGPQKdv5/+fff////fl135qJcaOJ1MfdT3984udWcbmxhPH+m0kv7r348ZeVS9qy5TfDvU1MDFAge+Uw0001VRhXgO8g02lxARiXg/ch0xsudhhXiu0ZE+vffwwMrFEWDAwM7P/vM8m9/cTAkLx0HhsDw3+Gf0yOD18zaBa/kWuHGPFwNTPryv9X//2fxxD4VYOJ8dnfMJVTx17PNp/G+/s/w+NT5R+cJ/R9TrG88eS4GEP3uy+b9e4GfSxisJpZxsXAqaoqYv/f7n0xAwMLFyPL99sMDP///rsjx8Dw5w8D1P2/bjAyMDAwQLhMTKLXJNng3JPrEy6IcsC53895vLEIY4RxGdY+Yd3ryATnPvjtvdpFDc798V//wIc9WjAuw0kv66VSqRywgOD6v1zh4bc8WCgyzvhmnfz/gSVMWvfDfIGL/1fDuAz2T6tn/nwL5zKk/X/w4z+Cy9X/8f97AMM6jGsQoJLqAAAAAElFTkSuQmCC",
    },
    "G35": {
        "description": "cormorant",
        "pronunciation": "aq",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAACVUlEQVR4nH3SXUiTURwG8GebH9t0rtxMRs4F5aBy4fqgXfQFMkuilBJUVgQWsVDSFgSm3SkEfYEXuxClsmIQhQ3CRLoorCYqTERFWNmrzY/hptnW9s7t3b8Lk17N1//VOZwfz3ngHBEAIKtEz0kmOn0QHpH+3gTL0tSlVGGTVjTCuSsue7ievUJEs/81kUv74FnJt8kzYgGU4KJENN/25K2P7qZvbJJsCaUFEJ8g+Vbo00ObVAckMpOb3m8XSAIAkWKHZc+0FIUmZ1wwRnWt20tERJ1qQSM63E/DzgB5x2xpwoVO0WAB6ucHHUc2aX2SXikhv+qIeGqMgkjfFX+UDcD6ktxVWUIq+1P8oQ4AGgPUcV5ImReizmIAKHPQ74ajGyOlbYbGq1IBZDYNkLtSuaGSPSaaqwYAGProp+Mc/1C0ujDaTZh1LXP+MfdS3S7z1ItW5n8EY7sRb77m5euYDvbCPqC3d4AZWo9ga5I9v5GsNZs0u+UAwHmZAPV8Hl2Dsm5ZqfwdoFXnxBUFmWc1AOCf8bib+f1O/6CnGWgEAChUB2o9tDK1fFTM0K8tt7s/ru61dUtEseMG3ZqkSaJ6X3D6ouL+l+HRkW6bQWudpaE2qYiP7LkIKhBpY5qly32ZeZI51we5toam+ElF31c6BIM0b1FtM98Zp5C/p5UlPmpkqaUrlrhCtFidBIhTc693RilK9r/XqbNZ8bH6nZM3K0sXy3JKD+pjAIDk5EP5iZR2AJAWtoTC4XA0QVwkRgsVGSmyfy8ikSQBgKQ8yBFvlvsb1v3PP6BXDlpIZiS5AAAAAElFTkSuQmCC",
    },
    "S38": {
        "description": "crook",
        "pronunciation": "HqA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAAcUlEQVR4nGNgkFr3/08tF4P41v+fvv1tZ/D+v8054OEvhsD/UQwMs/8zaTG8Y2Bm+MVw4qUwA9fZM0ziiz4wFBkeZJASYUz9s4GfgYFB/sE5eQYGBgbj/8UMDEwMDP8ZjjIwMDEwMDD8hNKMUJph4GkAVF0hh9B0y/sAAAAASUVORK5CYII=",
    },
    "O51": {
        "description": "pile of grain",
        "pronunciation": "Snwt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAACZUlEQVR4nH2SS0hUcRjFf3fUGGeulIyp+UJRwZQph5FQoUUhZOiiIBctZMJF7aIWFZK7MkmIXOUiSCIIpHQV2iJsEViK+ZjUdEgmH6XefKTjXMbHna/FTEzq5FkdvnM4//Pn+yCCDomg4595bISaEwjshKfmBHOAKCjpC1aHaXWwryQimCLUWaR5wtSjFTmjetKs3k3gSEbW4YDXmhbNE++gZwlsT6emr//swREfxVOYGRz2k/jk0qHZgZ3hYGZhlMoun1YMt0Tmr0Cx5nNF+Xu6OroBv98Fn7+EjanS9P0xlnZptgIklZ3Lx9os7ZZ9fQpyjRE/cLyj9+1l/CNGbsG+nJr15XIgt0dkpBTKl9dr9uVkqZOrQO0Zvt7+BKuTatbezqpd6Z8BPj/afPMRmOkvs6sbu59yDBh1IXby6p3TQJ0x4NhTp2ptpQKAs6Mi9UDFylrVnj7Z6sQ8wKnHRbzvBOYn1OzdnoQik9sLcOEEH25OAl63yZ4Q7qzmbS8tklMSdOsAr8f0gVkA3R105rhJSYr7FnutVvne8MWW75sDYHDwYn1i5ytgzpdnw34/W16g7UxLd77L6A0fVe0PkRsAzl7Dld8t0zsaMuTs225qlLbQes7PiLQnA1ja5N6D7T7nkCBjVMp4lzSFYh6KdBwL0SbpGpdKxgTxoLaKLg0hwZqT8/cAG0SXVhWPKLKYSmpjHcuzRgxIwI/ZYoqJ1SUuw8azuwsspCAakNkSEDFERLbW1rZERMQQCbRkApoo8isZsKgmEQUQQVEARFGCGzqgHQ3vXdf5PxQR/wEyYFUUOdgB8AcV6xGdL7flBwAAAABJRU5ErkJggg==",
    },
    "D44": {
        "description": "arm with sekhem scepter",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAASCAAAAAASvfPJAAABG0lEQVR4nIXRPyiEcRzH8ff97k6KU8/gz6AMdIvrJpPhTIqV2aAUynKLSQYlZXCTzUSnTldPSSeWm5Q6peiOKzLoSp6SJIf0fAyWU/d77r18+9Wrb9/6MZz2laFluXOpGm/JpMNtVYOE6enuQhewr84AdiRlkVJMyrWrNUlCWsdUtGNTcSl3L6QVSEoxC9uQx5IM9MMqRCzskxoO5o75p/Q0yMK+OMBgZlx6t6gnXpur8BxRwFxOLXrglS3LUoOIOpA8K0k63W3OMtJC+EURPkYBxpnoyD9uvgHLsR+AkB+edd77cAtZByD+reKYL0mqHBdPrvW/2o0kgCFfVwrMDwGMlODhtr3hpLbyXrTh6fwN1/4LjQ3knxOB4BdNq6LKTqb81AAAAABJRU5ErkJggg==",
    },
    "M11": {
        "description": "flower on long twisted stalk",
        "pronunciation": "wdn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAANCAAAAAAC4Vj+AAAAkklEQVR4nH3QoQoCQRSF4SOszSLsO8gGg08ha9ansMtstZgFq8IEk5PdJ1lhi1nBomCT+U3TZubkj3vuveo3pfJ5d9tJXgC/VV7c90CdExdVFs4Z4aTSkYjHFEFe4wMWO+FUWbDzKDBPCk0Pa6metWpjZPwVwFLyPr7IzYSP+UeTOGXQH08vSZ9RtCRkKDUkavgDCdh9hNdVxCIAAAAASUVORK5CYII=",
    },
    "F34": {
        "description": "heart",
        "pronunciation": "ib",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAARCAAAAAD1MaMlAAAArElEQVR4nE2QMU7DUBBEn10GTuQD4NqiRhRxwxGgTcpIEc1yFnMC3OQIkU+AC5Q0ifRS7A/yNDs70oxmFwBmVZ0BqHjiG78AeMttpdEYAGET+kAcdbRg1GNU0g5QjNAOVFKxhNTDOYMS4XmAF/25K6O+AnRe+1TW2iV7dpdkd1dgPhTf6T90+5fztAGoAabHHmC9mhZl9hm16PdrQJRPJBr9DG2WZ3wcLo7vyW/071xWKe4vpwAAAABJRU5ErkJggg==",
    },
    "S42": {
        "description": "sekhemscepter",
        "pronunciation": "xrp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAApklEQVR4nL3GMQqCABhA4cdPhImhQRBIQUu0hKMX8BJFd+gmbYVtUnt0j4gUB5eWKHBwaFfMv6Wu0BseH+BcqqsNAvPeyl6AwCTf5RMQxDMwPEEYT1+8pmOEgRETGwME18zITBehqRKSqkEo65S0Lmn1A2tdta3gTFg0qtoUIY/3adQZnt4P/I0eZnvd+uBEetPIAege9dgFgLkuAQGe3L+S73/9Vx9hfDggjnAVowAAAABJRU5ErkJggg==",
    },
    "S3": {
        "description": "red crown",
        "pronunciation": "dSrt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABtUlEQVR4nGNgYLF0F2JAAdyb/zPw5ly+18yHImxx/z9D5qur775aIIsKXPz/n+HLJ7+P/x2QRBkz//97xML989fh93eQhG3rThovZpj9ORjFYIFVFye+1GIQ331PDVk49M/cl3uFGBji/69gRohynN6X9zuekYGBIf9XMwtc2PFX7f5j0gwMDAwME/93woW3rwz5VA9h8s78v0oRqvi5+8LPSlAlzP7PPqXwMjAwMK9Z7/hvNsIm6b7fm7QZGEJ/OzR+c2BgYGAR1uL8y/BXnPenr9qOX6GnHyftOcHAwMDgde3Nq9evvvz//+////+n7Cq/eDMwMDCwsIouvMP2//+//wwMrK9X/Znx9DoDAwMDg/KhRCQ/Wr9vhjBYlu1HeIah8zskJJj+f+Vngouq+vfdgjJd7urARBkT/ptBWEwMf/jgccMZ+/4LTPjaSyOYMI/V2tswNvPx/8eOnS2VZmRgmPtUD2F7ytp7//9/+6bFoPhqPiOSYxn0OqYHngpi6PmmzoAKmNzeK2nfe4PgQ2nP1fcUFTvQFDOo/C9m6n0ojC4sc+91yddaRnRhJqdlr+6ZIPgAt2qhNcCiziQAAAAASUVORK5CYII=",
    },
    "T15": {
        "description": "throw stick slanted",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAAt0lEQVR4nAXBTyuDARwA4Kcf9qZmqbV28SeJ90QOUivb0dfwRRx9BTelfAYnJ6vFaVhGb+KimJqDRF7LvJ7H114Znu9bsP97VEHjIZ8jrtqlHSI/+WxUsPj4uo3SQXGchFEmncf6U74b3LWThWA8ZSYoBrJgevzRDarN3ktQ37oZhom10a2QtN7OUe1fJ8Jq7eJH2Cx3MHlY1Iml9HJIrKRnf8RyrYPYGGaQnc4i0u474rsHMejDPxIxOmhbnCwEAAAAAElFTkSuQmCC",
    },
    "F24": {
        "description": "f23 reversed",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAOCAAAAABmqTEpAAABBElEQVR4nIXPoUsEQRQG8G+LeH0QTAsbX72/QAyXNAgbXhCuWgX/BWHAIGwSLq3BMG0MBhHThQWD/UCQKcOhsG35muHcvVmD96V58HvD9zLo2SnQARN0z6u7T2wyvdh7esCQDH4GD3TA0QGA9f3iA4CfoZu83brBKckaAFCojSS5LPPIRiAM5cAc0VJ/h0KXJEkGcx1s6lwLJYthrVBb11bYvtNL9AkDKUhTzBlyuFhL7Ns5QhlHSBu2AOCiF7qBkWaM+q4uikRf9pe+6AiFfHvfvsSgm+efVNuvDSsIgyKDuTpMmz2+fiVTdX7yfXyzvsT/MZa1zOl2MIjjyjbcxTAlSf4AlWqW+OnVs6UAAAAASUVORK5CYII=",
    },
    "Aa27": {
        "pronunciation": "nD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAeCAAAAAA9AKCrAAAAvElEQVR4nNXNvwpBcRxA8RO/DMRAmYgMimwewAPYzBZPIJuHkBewWHTLaFLEJAYUXRkYKF3KgPyXfA23m2dwts90AIoiImMP2IAH2/7RuJgYHSq5xVNMLI2rM1ETUMDnVkgyB1TJNpv4zkEVcWTcPJurmWRDw+X0IxzScW0TRbunwg2kudUveU/7Ki1daetOt+qNpIoPfwwXqPqu8YqDC4CyyDiAOaV3xjhZmOwZ3C041Ft/WwCx84PZ3+ALp7ZMQsSrblUAAAAASUVORK5CYII=",
    },
    "N34": {
        "description": "ingot of metal",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAWCAAAAAAQ1GhqAAAAsUlEQVR4nKWRIRLCMBBFPxiu0gOQGc7AASrWM8NNOEB9FaKOGQycIAKFRFdHxT2HaUq2M1V8leTt/v072agIeW1XyaYiu+qdqmepv4itkqNuK805B3edlzAGV0gubnvdaxD0KaecXMuVKZElfLYypoGnAy1pms7DgWbEpHAZiS6wFEmSMnSL1QxM0pvlx8zmBucqWBOZc7YJXhYkKfQjxKquS0DOGRiHg/c+xQgQ+1/KLxgWVz1CdeOfAAAAAElFTkSuQmCC",
    },
    "G27": {
        "description": "flamingo",
        "pronunciation": "dSr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAbCAAAAADehRkCAAABfElEQVR4nI3RIYvcQBiH8YfSQg8KDVVXV1NzJ8ZFrSk1hZq1C2dG1lX3K0TmA5wZFyiBiltTeeYo+QQVdXEDI048lELFbvZuN4H2VZmZ38yf9w0QsyaIqpauZqnirddJojl1Y1HdLCgFxH53py+a17OnjEYKBo0AnLVqOFbJtHsr9BOjavXTSaCu0RzY6LDfPc+Hz51KfckkzwGacjhrHc4fq1VTgKoZS6YxT+5s3De0UwQjVXZolUadRtaaHyksXdaajaWiUUsXAOpxDA9qM82yzlvgbRrVsgHGfa9T9/veDiNoOtVhq+uZYqumlGqAurlVta2Ix1Ou3FdJAFUcVDmtwX6ruU55HNMKCMWfM5Xs0A6oU8klwWDzZMaQGwDurl5++HaRy+VNWkhc0dhNy/o6hZmBwZrwoHZ1mhguuZtfPVUX3C8EnKqPfP8P9Z5fcPUv9YoOXvPsePfp8TLCl99fX/BuIRboVUuZ/mK/mBjeADz/8wOA+8/rY/UXTRH8lg/kvi8AAAAASUVORK5CYII=",
    },
    "A42": {
        "description": "king with uraeus and flagellum",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAACHklEQVR4nFXRT0iTcRzH8fee55kzJ1gbLmoTVuolykNlIZhaOaOk6I+WVlIQCVHhoUOB1cEohaDsEI5GBpUIGRhiCAMvWRG2SAODZSo6lxo1m24+m9uzXxeX9jl9vi++fC9fSEbasmMjymmP8NWbWJG0j5GRwsbpQGBWe5a+wuWCbuEVl3YWFffFG1IBSDEAUBESYrxVxv5lMR+AWncaAO1qZ9O0fzsnRI0EGEsdGwBwfW6aO/X+Ztpk1CgBuYepBiAYDUi9bqEFI4sAt4QYBcA6nE360FWOJXZJwJFI2JgFMCW5ys2hIM2DoxKUWSefxKsAEnd3dz9YSFTbuvxAx1jvpn63AqwZeFSqipMeUQfkjdR3KweDe4G2oI2Zp/p28VgPF9WidgxhlwFuOzk6nEGNiBXoTC8+RLNaztdQOAiy9irfSu6biJttouTdwzoRCrcCZHtfg2lhoZ8rQ/axWn1P6LcoV+C4VgZmMeXg13XzkJ3Vatc99YJMfcwCmfGzKMaq/SkzEOhp0e586rdMREEXm0Pa3Jn3XSURTqXJ67SVtM0DSAA6gMbneiqiN2YrAYta8e9b5/7kQLOY37fk0pJ/W5UBDT8TQUAkLwEDb9dC4LLHB9h1yz4/UQx0HPADOSv2GSuSQEQBDv34uuzj6+Rk3RrwLXuWJZasvvW5KMnBpN+jIWuA7Lx/7UzSSxzyS1DigBxLVBqWOHNG/J+/Vv3jJGUTfRQAAAAASUVORK5CYII=",
    },
    "N9": {
        "description": "moon with lower half obscured",
        "pronunciation": "pzD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAA6UlEQVR4nFXQvyuEARjA8e97Tueui650yiiFLBbFovwDiuH1Y7OQTJKJQeTHH0A2i0nODW69cimRv+BETpcRcbr5a+Dc6zt+np5neABI9E/VVEvDWSAAgum5ztHbr5b42HVpA4BEQd92AJbfPQDgQn9mEFQsdNEa6jGNYmXnGclZpNm45zz4mY0QR/V4L7n0QOzyj6op/Ncu+wYCLD0mAeon3QC6RXtjK9kx+CE1b6LXWZfJKyciMuQr6QUNm5T3DDL3PkfEEOipWpyJAaw+6XYiADJ7i7wctpFao7x5+vuA2XxFvcut9AHf6+pogVCGKvsAAAAASUVORK5CYII=",
    },
    "M26": {
        "description": "floweringsedge",
        "pronunciation": "Sma",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAABXUlEQVR4nJWQv0sCARTHvyeScgliIuLQIBoY2BT2A5qcdBIxcLPNvWiJoP+gIQL3ssk6JCQ6NBwEwQqVKD0ISyFB5OBC0PxFvobEO9Klt7zv+7wf8L6AbQn2YyJhTw85Dt+9Z70bvvuyo4CLFx/SiU5/RNcKaLijSwNgqj1NkEq1vxHf3ALET5Lh6PUgeMoCQF+xzoxzISNPgmQ5rZj5GVAR/4JuvxL43QCATAsAUCwCAFoZQF2oWiRGfoaRLJxVHd82zZ0/5N6kEbBg21gzD+xXABJdvkLpQLkcSFOF7yYAAHyddQSzg15vkA062DoPQEhWawygC7fbYR3A1KpJgdkNLLO3j/fPYh6rppV1l/dL4AAkOlyJciFBCOWoxHV+b6YaGqsnOuz3h1GPVdNIAQCMZgDaGFFMC8BsVLznajZd0y7k8xOpnuXXTOvkye/ppjMiihHnH+gjIvKNix9gJYPVYJ1KqAAAAABJRU5ErkJggg==",
    },
    "F3": {
        "description": "hippopotamus head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAYCAAAAAC30wCSAAABzElEQVR4nG2SS0iUYRSGHzVNQmZG1IoiKIIwspKgjQTeE6JFV5MycJMEGtiFpCC6EBVB4MICoSiQIGjTsogoKEIMK1qNNmJQm0xzzMWQaU+Lf0xnxrN6ec9z+N5z+CC1stcdjqvTuxeaS1KZbUVHN4eB3J2Dn1m8Vp1RfdryQbV5USS7Q6MvwhCKq9qYiZS0j9t1AuC8/pgcT+jeNKSiSe1aWVZXBM8G64Gsh5qSvuSrehBGtB04lRzUhnkmMqpT+4Eh31fDmqmKwD+2gLqlozUAFBcANGl10DmkgdhyR6+nJXzzMilq7AEgZrQgfdN9HghEVtzbAHoy8x7DI3Nx4wLZMJ0J3Vi7KRDxBmI5cHp4CIBd/QPDHz9tDHq9bpjj71oLKy4587jzkTrWVVWaA0CZrp+DQiYiUK76/d39ugDYXr+jWzvmnz5nOdCsiaRRfO2qanTPgnz59gK0aBmQX3/vjz5/e7G2MGWLiQEAWvXK5QsTOubZzFW/Jc/e1j+rfX1VxFyeAU2YlVSlx2PdwKvKm50ALFv6d6aq8jckGrdOpU3laS6srmlyvqIZH/mBra9/qf70SF44FAqFC9MRiPRMzuqXJ23hSO5/8x/Oq+HoeeCpjAAAAABJRU5ErkJggg==",
    },
    "F8": {
        "description": "forepart of ram",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAAB9UlEQVR4nG2PX0iTYRTGf++32RJ1Nd2otnCRFFFCURBqFOUfSCqyf4jFLiqqERGBdSHRRd100X0wgmhdFAVCBnVnSAhloCC0mSwbjJwho9jMzdy373Th55zbzs3L8/zOe55z1OjjsZABKktx7XOq+dmZMVFYQh81wPJ3EtjoyYm187hdBbttAOgxZYCW/p7Vcps3GVi8oLwXe6wGoOnpPQUzf+q6dUqBAkCc5++vf9LQCrEfsfhoP2DJt9a9EpGOlyLyomS19i/ZiH94PCPpmczlInYkZXTVUhOQeKvrQrJ7FauZkD6Ap9IHXJVThbApMVJ/ZjvN0/0OgBvSa1+BLYnpt6nwm/iiec2J0WBlHlr9GRFJ6f9qTWPr4ND+lb89A58HDjwT57L2LvQXxNrc1dwTl6mqH6VPFx30IA+PZt9ZSqCZ2RibbQC0Qig4AFhz13V9qhhW0AKA/1zgPcV1OPFQARsi0W0lDIZjHlC3syfLMAJzl8AzHi7HaMwFUHcMX1lIctBRHf3gMJU179v32uud9oW5Y+5bf0xLme/aK+2dFV/Rv0XPzrf9Xj2uY0hE5NPYr6SEdhZF7YjIUiVutj0PNi3bS5lutynX9VbVYW2Ohyf0fKb72kHDsB0yOwyNEV9kZSHlFCq7qoxdW3THbg0Wfa+B/6bvupcegbCGAAAAAElFTkSuQmCC",
    },
    "Aa12": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAFCAAAAADustqTAAAAJklEQVR4nGP8z0AAsDAwLMAnn8DA8B+/Ic//szAwzMdvCyNBdwAAvJUHjMklEO4AAAAASUVORK5CYII=",
    },
    "O33": {
        "description": "façade of palace",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAAA6UlEQVR4nOXQvyvEcRzH8cedy/fb/ZDJoFvOpAxGdZNJDMpycoVjUCwyGlwWncEii1FSlpvNFov/wCCDb0miq5Mu08cgm6+62Wt51ftZz3q/MkFKcqdpJD2Zx1Rb0r/N9HeV6mVQrpd+7t1DMNFrgNXeJGh1cqXF+xesx5sfn0Rb8f4ZRpYGMumfah/D2EXrCmabKw+wsZbznkBeJ4E3zwm8+st23R5uXd6M7p3fjm+f3E01Dp5mFna783PCkaGwrBJqqqGqFip2QlEzZA0qyCuI5eXFCiJFkWzqOP+N/Db4N4lSSFDsy/YFgTk7FivbqhcAAAAASUVORK5CYII=",
    },
    "O48": {
        "description": "enclosed mound",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAAjElEQVR4nI2QMQrCQBBFX3KCaWzGSlZschav4eQ6a+UxBM9iG8ukF7b9FpGw4BY+mOYNDH8+ACmKJJVIAB0wPA6MwI3X+QmASdkALEsG4FqcL77IIU3aDLimRChTkRUUGSCtg6mgoFaEen74T7XON0I0ouKa95uZ171J1131dgcM9yOXvi4HTvGuKvwAUttQRtYmLngAAAAASUVORK5CYII=",
    },
    "S28": {
        "description": "cloth with fringe on top and folded cloth",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAAA60lEQVR4nM3OMW7CQBAF0L+LHQuDhWi5QZQa0eQAkZAoqHMBKl+D0ilyha2g4AjhABSUVBTQIhFgY3vt/TRRYineggIpv5t9MzuDAUddxmCCwwLrNRYHJETM7ogDT0OfkAI5WKAECiIHUpw0NGZczrlS3CizV8ej2hu1oVpxvuRMaMnGJfDPfnCRTY3wy7Yy0zZZqxQWTIQjb6UHEvUhJKzDYOHZqOfACCJ7cE0iF3Hzp3h6fd89D6ef8rs+Vztf+IgJO78PsoIh2ggQ1eOf/Hv0INy4/Ujrfxmzf6+D7oC01o2FKd3oB/4NO6/ZUl/K77qpmgAAAABJRU5ErkJggg==",
    },
    "N8": {
        "description": "sunshine",
        "pronunciation": "Hnmmt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAVCAAAAABTMoBVAAAA6ElEQVR4nD3MvyuEAQCH8efe7k1cHUlMp+OS4mwGZfAnGKzqBovpukEoNpPBLgsm+TGpU+rKIIPFz6KL6YpuOFmUcOcx3Hue7TN8vwCk5r7dyKZp1rV1pZXT3W4Ahh+0uPmjZx0hTOk2ADs6T2rdw2i05wUHv9VI9NlASy32fIrOtsiMATT+OQp63FK/cq29EUesMV70vROAMV0iPlD3bQFYq/o4BGS+tPz0qpU2AAo2W25eHJkvWMh7D0DWZ3LmePmAACa4I0mScgICmKSdGDH2WSQgPc0lADesDMbJnNdPCAm5XU3U/gD0r2eIcZzYcAAAAABJRU5ErkJggg==",
    },
    "F11": {
        "description": "head and neck of animal",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABK0lEQVR4nH3PMUsCARyG8edOzWyoliAHswKJsCwCnXIRgjaDanAL+gSFUC0uBS1Bg7RERV+gIdoaHBoDkSgHi8CKoMjD0iBPz/u3WHc29Gy/4R1esjGsNiLoR55fRh+inGkHvhbD9/s9hDKScgAwdHvjA2XZeIsCKLuyBqCmRZuAri2zMNmfACJZKa4sHDbkOX0tAFFNfso5Aa3xUugLuAB9G/BnmsWQd7MuleMxB6jrIu9JlL3KvAoQe6yezgDBrxSgOuO+es69OOvJd04BOOIlkZpeWvWUTwBQg3Oh0cj5p3/pbtx6OpjfmTYSoLb8Uetrmk3L5YuAy+WwzNXI62W3zU6pPLltBhPa3DtQs1uC4ardirtu/rvnj/U2izIsdhsdSUNsbuCt6/ANXJVz/bLWhAoAAAAASUVORK5CYII=",
    },
    "P5": {
        "description": "sail",
        "pronunciation": "nfw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAABp0lEQVR4nH3SvUtbURgG8OeccxOvxhg/og2NJmAbvzU6OHVQKJaWViwO+g8IDl20iA6io4urDgqOuinoUipOCmKxBqGDCIUWtdQ0NwQjSczNued0SGw+bpMzve/7G877HA6QPbadUzt6r5eyE5qjnHMOXSSzEwXw2DhALSDUaW+Ltaiel+EY0zQAjADroyQlCQWEyjRpqUkZMCA0wcr/KMDnyp5OfYWCRgM0DC6d3g4ungyXX96l76g9iFSj4IwHlx2Z8nXoRaFi7KLxsTx6Y1J34n0mkQJhUnFjy2hDjWFSy1OR0cnnlyZtEhrgbm50zRhnJmT7x3YoE++e3XsQGfmphwwS+/eKlVND5/5fpM431N9nqDxc8VsniaAIncRbe2F1vcL35CcCoKpeQnG+bR8UW4kKd7d6yBnERejHww3JWXLTvxBnDu/C/DIBZDppNqD0bTCahMWepnyldd/mYuzBv7hrCgCAfIiuquj6uvY/BDB9FZgN7lmLKAZ0+aW2GIJuy48kt89TcRs+lUUVttsrFNckISW0rGCP/DZVUkVJtZbUgu/1F38mjEsQeP+fAAAAAElFTkSuQmCC",
    },
    "G2": {
        "description": "two egyptian vultures",
        "pronunciation": "AA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACiklEQVR4nG3SW0iTcRgG8Of7djBLpoGaphOloQjlTUmCRYmZRBeaFQSC0QGLoBIJI8QDdGGlkoUVRYpSCkkQYaUQascFSpSWp+F0Hpp2oducc7p9355uSt1n79Uf3h/P+4f3BQBsvTBDkmRrANaVACA3e1eMCACwNPvaB+eUJqCIa2u6RtEXoYusb3YAADrfor9qMm+PMkPUqjVxrTKn5q+GFieKqcuF4vrPAAbLSHCRFA1AVTekV0wBAEw7hx1vrPsByO0JJ/6XEdzfHnjTadwEIPKz7dLalvrfw5NwOmhHsincq0VIpatRUmZsHjLlcM5nNtlGJsbNNlf2uoxll3737Nd03fx4vix4DQ/OdTmUIS18Zy4fcM9K8QCQY20LUYoEz6+xXhvJ+yoAKOcRpVCNf9k+QJIsAQBDh0uvJKccmZeXSNqt6QAQ8bspUiFS2RPdQPLeLVupGsB5XlOI2AVmxC2SDcJ1uRIAiux7/YV+gW3aatKVhRu+Ci0Q0fdoo5+IWSCPpS20Si1aPGaJCGS4D/oLj9FiLR2L77PuxBazq9EATd0zlZ9gQbnPborrlMsgPCSHqzRhEzlY2T4ACDYEx8b/EDPD+ArYltGd8KIi2m9Kz3MvaW3i0sXQQ1bb4IbbtLJWtyqi5+n1/b3m113VV2Y0uhrSk7sqkiSLc/XiywKnixF0h3wauCKyR5Kj6vkhObGb7jN3U5A7GgfdKJdKV0SvMRAVrAUK6Q0GoH1vjEKam2Y1kBIuQU5JGs/9uA8HzhodUB2fEgfHTn5qqDJ2HFbjaM3kotNpJyn99JLy4BDpdTi/5SFr1vaki23CS51KFgCZUKm9PogaeqASoDUVzuUXJErq738AdXZQLWy6uFsAAAAASUVORK5CYII=",
    },
    "O44": {
        "description": "emblem of min",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABFklEQVR4nI2OMUsCcRiHnxM5xAInQwhaHF2KlggaGm5qiEKXQCwcGgStKaKmoK/QUC029yEELyEXyVqMOMhaSjSnPA7v3gbv3/DPod/ywsPz/t6XUTMN5CSQbSDdHFHu1zKYzxcl+xEytX4ZCm4dq7Oaq75A3S0ARtHfzzrrw+8jKn7RAKB7v/FWuCmRanWZJC9Xx8PXQ6sq+ZDEG8HK8tlXb2zHQ8KeDDrOWOTSUGTT83Yr7+PPjyUgAnBnG8n5RG+ncb2mJGsgIgckHxophbbEOzUgK2VFYt2nBSDWPpn0QNCORgH33CEaSuG8NZWj4o90ov75Jwl0EkmIRsxFX3fiujPtViAaCdJzujMz+6dH35rS/JsfVcdiiilmuswAAAAASUVORK5CYII=",
    },
    "O2": {
        "description": "combination of house and mace with round head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAAAtUlEQVR4nGP8z4ADsDBcPoJN3EaX4X83Vh3d/5kY2LDKsDEw4bKGSBkWKRbsMq4nb510xSYjNUPrlNYMKSwyseLRTnFisUgyjBDAIPRzHcPqn0JwPsP//79///79+zxD0RcrBquvOQznf//+/fv3//+MSxgZGRgYGJ6UMZxjaK1iNP7fJcPAwMDwHzk84/7//x+P1Wtcu//v4cLqn29rGFZ/wx4GtxluYw8DBiY0Hi4wKoNPBgBFUzbVnNB5EAAAAABJRU5ErkJggg==",
    },
    "B9": {
        "description": "woman holding sistrum",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAACEUlEQVR4nFWRXUiTcRTGn////W82bbWMcDFcn7ZaYFBau1gFBTZjEASDMCKIEQaBIPZBkF11FcSCCGpUN6tIwi4iqCHerAZuDJmhMje3onRWjIXNdx++2+nifaf23JzD7+I5z+EB1mpj7xTRaBf+l3WIPt17OJ/p4mtpg48o6sWxbLgFvTPp5EcrAKC99CVWpHfi1O9OTm1zrWYFAFhfRjadGbH6EznBh+PJ3LN5AGDGygNvsPtpp0QEeGlyvep9nKJD1xBJ7Zx2CPwozMoqHnvS03E4WTktATA+p4VuLYrpRomUAGzTDtHYSk0WDUuWRMIpwKUqJ8PgrJbeE4h5BrNC9y3i5AqLLVYBAOKq8namoIDJr/u5rfmEeYcEAIrzlwzOAFR1YuueAVxmkWVGZsWxPQWAwEikAWy5Vago+vL9C9f7iHHOuBCpnqOuZiaZcrX8wdzZsfdwP5Y7SgBgc7tu/63O5UOXMj79QLxKP91qNGOgXKGi3Z7yQd/2ZuG8pEY+4AqffPVnijOBSvLr4kRVAABqS+HQ95tH7EoagOB67etNL4ItwDiNNgHwpQ5BNcmH2h1gHyDXS9RmRRhA/s/jJQAMVG93/8TdBkCnA2Aaebl5pXV/fJ+2ebIXV0ywZGysnxfFVRytWZi61WrKKh4un9MOFdftBtR3YPXuMjxaBgDs3dC/7Y5KLUGiGq3qyj9aiNZcLqtiJQAAAABJRU5ErkJggg==",
    },
    "I4": {
        "description": "crocodileon shrine",
        "pronunciation": "sbk",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAACWElEQVR4nHWSXUhTYRjHf5vH5ZzU0mZBOrIcSaIiSlQYgRUoiCVRiUjSB2HehBdRToxIptRFd/YBhkGgN1JEKVlGGhVFmGgIRqLO7EI0KbYp7Wzn6eJsueb8w3vxPv/feT7O8yIBvxrwfSyNX8eaWrp9pPLBmFcbLjGvybgWZ+rXZ+zvXpaBQoshNuOcWRCZq06+NB+Q/gOW2NCVqR+z4xPSnP9iOij39lhXlzRgcF7Y2P2kLXC1g/ai7fGd37oi7F+eJQCUa14Zc5WlxQFNvZ+9EqFXziwwAKbLxxyJTDa/nQDy8mv1FEFNSbJtZvTUiH63OAc8IqOVDlPEZKkkn+52y3BuOJDQ9MkvMpLxj3Dc6UgFTk7L0Mpn9i6vvNvqOHcoDrBVvZmrsFYUGama0CJm2D05l0ajeBrKiyvaZbmG08GpMhOtQSUE7DhIToprNrMwmNSiLqTGseg4c9a47eYX9+9wHvszEZFbF3skSlk4VR3JfBzthVWjNKh6reyjH54aoxeqyYk8Gns0dMbH65YYq9yUh8MsOmMuoDxFogkD+wBBZxx1ZGfHyBOSArDBzqPO1V5dcQSjMXu/dzWjOdIHc32hflT6BwG4u1N3v9YC9A2ltzS5fooCJJbg9QGwN7TjZACWfHyXXe9FAez1GHXPz+F5sL30hyeL7zxvNSiAyUrorQsj82ALNxTP8VZntWIEBHf3Slg/ADx012+5YTLoRcb7wsn/0/Nxi6XdF2pEVcO1VEAl9M9VFf5c1/R9lXr0YCLTGhgpCN3NQJsRIGethyEiOZDwFxGJI15q/NHMAAAAAElFTkSuQmCC",
    },
    "S4": {
        "description": "combination of red crown and basket",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB6klEQVR4nHXRXUhTYRgH8P95z87WtmSSVzKk0CREbDNEMzKFwAhXVxYSiYxQMKIL6aY7r7wQLbGLpMIIbJIogS5EL8wC+0JEUNRiRfiBMbO0jXnOtrOni53jeY/M5+r5Pz/eD94X0OrYu9h1C7iyBuaDbj3Y7u/Rwnmem1QadukhNzl983czp6eX6FctmJYEcTTpUA21NBdhc2WfAUfF+EeDvY2If1ndj87xCYnbWnxMtObhBpdpiPM7RPSUv2jOJA3b9SCtbJN8hmfc2KGhbK1vC1VSp2Bi+LZo0AkAOPG1/aVyAQeq7DV98gFA2/eTFLDzJBbk5+eV9KnRfm9BVcj3eaPUtDJXJaOeX40E0mP9FxgbmQIAkgUmB59Yu83nuqnVCGfXt7TX1B+VYDO4xt2bMnOK28nuCT+CmfmqudIXOZylh85p9XCuOjUTwgGOKHGtKxpNPFvTWQimmEyAzfftR3pSeFyZC5PlCJCIQdjN2vkHAIqkfXdChk2EwACW7cDtxFim2wNAxZ+/sPfEH2TWrMnVBuBoF01dzKAt8+E6AHB10PbdPNG8svyFMuYFBAC4Ve9x9b7BcpQBIKmYFV8r3fxwL6oxrJ5L/pzUXIQBIGuZJfl2YOEnoDOAc9WFfq19tTj7PpZu/wOoJq3EFEw0pAAAAABJRU5ErkJggg==",
    },
    "Q6": {
        "description": "sarcophagus",
        "pronunciation": "qrsw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAAAAACzJtCvAAAApElEQVR4nO3RsQ3CMBSE4d9RGlagTYWEx0mTXWjMLmmyRVYIElVWQKZwQXUUOMKGBNLRcKX9yeenZ0hj66oBoB27IbuRnsgpibOpmVg04ep9uISQSckIA9j6AO14Ok9VdrevGjh2A6BHqXV5SfoJZ2PpAkqghCSpn0UAtpckGS2BLCXc/MYU6ZnJid9CnPRzRPHVAPzZa1Yua+Vr5dsKZ/KjZd0BmsNji/wjT0AAAAAASUVORK5CYII=",
    },
    "O43": {
        "description": "low fence",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAAg0lEQVR4nI3PMQoCUQxF0fPFQsEVuBHX8F3V36XiApxCGy0Eq2fhjDowA6a4CeGFcAHtmUbLNIeqSVLbNBsWYGdf7ExTpQiGPsNiyf262lLf30d8lHU/9wZJ0mqSU6uX5NzqZ/PrMOc4NiUHSL58BE4xigWOHXSB28/JpozTc7X4K+UFS/9vBF4bgDkAAAAASUVORK5CYII=",
    },
    "M34": {
        "description": "ear of emmer",
        "pronunciation": "bdt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAeCAAAAAA9AKCrAAABO0lEQVR4nIWLTyhDcQDHP+/nGQ1ltjiuZSKMiz/5EyLpcUItBzVOioOLZRcODspFkpSDf4dd1ZbDiINNJMkUEQebcZIDSvPem+ewlIt8Dt9vn8MHkF10BKnLAwE5C+b+TKffCgI+1cYKXVEfQJBvnDVmyIUhezUyI/ptt6mpdnQxciE47BNuV+61qTiIsN6/tl1lSfHhla8e2Ta+07tfHn5uH1wzJCYK60vNSW39cbZFNB80XBdl28Tp1IYQjplQya6M383RvGTZjlrqHLG4fV55RVES3ic9lRi7DDn5GNjc82l6NB6pWcYb7bpbutLVl6ppQ7IFoierqYy3ycrWLeh8n/MbX6fHhgfAHQurakr3ZAMwYqiaNkSagoCR9PFDWezcCiAD3NzzAiAAMKUvvRK/hL9F+t1k/tN8A2vtbjCRNU0MAAAAAElFTkSuQmCC",
    },
    "M24": {
        "description": "combination of sedge and mouth",
        "pronunciation": "rsw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABHElEQVR4nGP4/////3cd8gwQwDKdgUFMLeTv7AcMMMBqfu1lPgMSiP97BMJgYmBgYGA484YXmXv/PQMy99tPRmQuAyOKLBxQk8vEiOAwMrFsfX3i5L33/xgYBJXMLURZnsuXKO6Zxs4QmOVy//5DBgY+raiTP3/8+HkySouPgYGNkYGBN/Pr10xeBgZGNsaDb06evPL2AoOBsI65uQjTedakA5tiODljNh1IYj3PwMCt7LXi18+fv1Z4KXND7ONa9///Oi6E/eavXpkjO+7CBQjNwsDAwMDAzPaf+f8/iBf4Yy885uN/fC6Wn4GBkcGy48fl02cYTEx1OSqOMzGwsn3/9O3372+fvrOxMjAwMIjlPvh09+6nB7liDAwA0k5gFGtKqm4AAAAASUVORK5CYII=",
    },
    "O20": {
        "description": "shrine",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAAA3ElEQVR4nOXMsUqCYRTG8f97OHyC5PCC07e051CDQ4Mgjg45SLg7dQPf7m4UtBUNzUotYhcQeAGueguBNPn6ib6nIZHSS+g3neeB80C2LeLKlWq1UnYUtxlKSZaFbqcuxI/hy1JKKJGbVuPzeUKteX81IgI9W9mTB/CPm5X1UKAwHZ+JEOP75TmgABcjflEc1+t9TF4dCrzxh3BEMW43AGJgiqFAdvjoSH1K3/s+qU/5mV/kgfBFYJGH3bwgOHDILh75H1VOIJCzP/S0bQ8hoXXiGtytE9oDZnZg/g2mGVIMD11bSgAAAABJRU5ErkJggg==",
    },
    "G4": {
        "description": "buzzard",
        "pronunciation": "tyw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAACCklEQVR4nG3RXUiTYRjG8f+c1cxMtA+zKaMGmbnClIFgSmRQJohUktDHydIgKoIOrA6KCsNYtCI8qJy1lLA2BEtooJiFuTIojI2MoayGttlyDNeKd2tvBx4433fP6e+5uO/neiAzp7QjGJx9lYv87Hk2FG6zRs+LTUnQK4rTxUX16V3Pl8lxk1Y7ch8wTK1OEoUDLg2cjMmHpgAfVq2HaOxPUlRE4jA0ZkqKIkvB3VlnVibDDQWU1XpuVN9JlS+ULxpwj34yVzqNcsyZbcS7P19Nse+xDBUXBtf01gLox00pUs18c67KngtQ5m6RZev9hddvKwBqgq1SVPb1Zfdemb8XvSpVXdys6r2UBnA6tFO60xPRSLd1OZBm68+TaGXghzHD2L0dyBp4LUH1R8NgDU3O1mwo9VsXV5U1cC3XsRXty6d7Uyn3dakWv2Yk42zPSjg49qCciu+dKcwXD4BnXfrDtc1gC4X1bZ5jVe2JyZLJBkz+U8p9EXu12nLxkHAvca45etwiug/bLCcm9ZwJieLdBO0IvXd4nW3BIs0LB6qbvyORWwv46Kt286Bd8zaPwskjrHjXGRAWfigenxj/p/y2e5ovQ01p4eGN/Z8XWhidoMDlKgDQ+I8uufyrDgVQ0gixLbtmenbocA4DLc0qX4OpXQAYiAnC39BPnzAXCMwJgiDqtk3NVAD/AeX1w+lo3J1eAAAAAElFTkSuQmCC",
    },
    "Aa2": {
        "description": "pustule",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAAAAACo4kLRAAABE0lEQVR4nE3PQSiDcRzG8e//zWStNMlWSqm3LZQTB0pppdTrtESubq5KDptmV1dn281FUWoUDrgo7SAOs1pLDl6H9yaxtvY+Dsze7/HTr6d+BmKxiTW4vGvU2/xm+ofW5+cArrwDP1L2AEx6e8YrhHpD8TRAJX/2BXxIDoCTe5AkaRWQzv+WnJ1P4egRkLJ0stuiqjwW9PxjfQxFAasVQGqJRhxB9tUl0LKUgclT7Qb1WE9hEoe6DyIVfwBSUjmIG8pYCKbtAL4wZWHwqSW7eHHbZxHmzZjnRFdvUkBJDmp2b3MCFiRJrdHOr3sCGM/VJeloEcBekmsAiG6NrPgRCu/Xg7ObFDtDoejw/klV3025xeQPqh5w0xSGuJ4AAAAASUVORK5CYII=",
    },
    "U35": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAABc0lEQVR4nGNgQACr/1ZIPCYEMyz0T2gYAzbw8v+f/y+xysgv/r9YHpuEUOLz/88ThTAluGf8f7ro6f/pAhgy8V/36DLo7vmajC6h/Om/q6iUqOv/j8pQERYozf71/xY2BoZfn76xQ0UYoTSvZcPveQwMSSyNxz+jGce8dwUDA8OKvcwwAXgY/N2uw8HAobP9L0yAJYrx1mk9LY6D9x9KeWzwkLqPMKXv/+NFt/7fMmCQedHD0PNCGiHD0vr1//+t6gwMjBv2qu/dyoiQ8d968sDBU7O1GBhMLk+5ZIakZdrPZU8/XYvcX//g+5fsC1+4vsFkGB2j+H4Ic/bJT/3xVZiB4c6jucvgPmVl+stVnZt/+gcH+3/GfxMkfz7Nv/cdYWjL8+MF6979fGdpbHLj///DbvY6cCm7df//f/3/9c//Pz////////+XSXBXipsxGDbWX2RgYPjHwMDAwMyFHHQ2/22QeEhph4GDgQOHDCoYeBkAdVuOHkB7Z6cAAAAASUVORK5CYII=",
    },
    "N10": {
        "description": "moon with lower section obscured",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAASCAAAAACcZ7q1AAAA80lEQVR4nFXNvyuEARzH8fej86MnUoZLV0qnlJhuNeoo3IBy3WRgkBgsikz+CMlmQZZbpC6JyEadgWQxMLEgv8u9LXfu8R5f9f18AUh/WG4rBGIA2QZ2aoOf+mEy2c0vgPi5J/0ATBzqWRxoLHpEpVEtdtA0rX1/xozOx4ZyrB2QGlfqCvuspiYzvPlMa77ydxaOS4GwN/hws06ANXPJy8WBZVQ3qnt5FbVApIKipXTU0iV5955/3cn0hYkoJb4f6dz2JGrHbhB0P7lUpQUdA1o+XWlrBgh7X3ztCgHab/UqNzWVu9abZPmgZ/dd1Z/TkRD4BVGzfdv1s+7iAAAAAElFTkSuQmCC",
    },
    "U26": {
        "pronunciation": "wbA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAuklEQVR4nK2LoQ6CUABFz3ugBDcijRlsjLlhoBAMRKrf4Te4+QdWf0HHRmFkNVLcHIWImwEsBGaQZ4BP8KRzz3Zhr5RSao9urt6nr7ZZmSzKBEjKhZxZR+BozWQoGqARoYzqF/CqIzlPn8AznUuz+gCfytQtJ5LQO5ZQjIg1LA/b+7B85QMSMDBGG/if9fSj+fhDdh/Xh4sA4lzkMeDduvbSdjdPN+yJtKeabQBZTp4BEBTnIhjOO7UDfu7NOeKDSD7OAAAAAElFTkSuQmCC",
    },
    "F10": {
        "description": "head and neck of animal",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAA3ElEQVR4nL2OP0sCcQBA3+XhgeA/8BaHtEFCp0DQahLcIpwFsY8Q9BlsSKRBXRp0cBBHUSIIXRwcHXIyOs7owMUQFL1ClJ+DZUO7b3rDGx43X0UALFkTJb9QAZLiFtTXmguOjUcHEBcPnlDXvHACVkPMv8W6PZMhapabJ6n62gbhj+fgnTWUMhIE+m/2zD28FKExPgSgmgehXwKcT9NwLSad1lVM7ylApKV9LqcDL1v8sycbcADwPtfMX0eysPMt+3GxApAgd7o6Gw+lUkWGIx+yy4/7pxwV/vr/nxvlGERc+XB1TQAAAABJRU5ErkJggg==",
    },
    "N24": {
        "description": "irrigation canal system",
        "pronunciation": "spAt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAOCAAAAACNnooqAAAAR0lEQVR4nMXPwQmAQAwEwLnYgN2lewX7kPj1E8+H4LLMKxB2lBeJN0eQVTkTVVBb7+3j0hvkvOPPjQ8GHGDvDdKZpLX3y40XjdpJIzsO0IgAAAAASUVORK5CYII=",
    },
    "N6": {
        "description": "sun with uraeus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAUCAAAAADAEcDpAAABVElEQVR4nHWQTSjDYRzHv/PSmpeYUHawkmiaZAcHlAOHXZVyUjZHlFIixV2Zct9FXBxkJMpLciJXRVitHFZeEpO8fxzM/v9H9j19v9/n8/x+PY9kqCoQjMNDf32usso/e3gMcL7Rk5Xpgc+bSDi0ePdMLPg/0wXLlWl/AKPWSYVnYjO2HpTUAb2ZOr8PajJpDwAkwaR9bpS1jP9hiCoKbmP7EuW/dng6xdcZu9o3B0lOfFYY46iRhLZoN6FiZtIuR3Jp4VFevSvfhFJxpwVJxbmSvvRXLuxQyC3JoQ+TKfI8W1Ce3l4kSX4TarLf6oZTVnQBXgN6YtwKpQAHbWAvpQic2OIAv+q2Sj9A2Mq1SQBS1zBYmO624SkJrRZVdgHclqsTYKdkAOBhSLqEs0BJ5v+q63ySVDif3nvlk6ScXYDEnMN8dkHDiBtpZfUeSfJMtTRLr9+L87ppKt5kOAAAAABJRU5ErkJggg==",
    },
    "O25": {
        "description": "obelisk",
        "pronunciation": "txn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAApklEQVR4nL3MvQnCQBxA8Xf/xMQPCCIc6UVICkEnsJA0dlYZxBncwRlcQiytggOIhUIaQdBUXryclY7gq37VA8K1W4cApKUrUxBYNKtmARAVGzZFhJDE9ayOE3x0N1+2Wxof98of/a3FpyMHE0gPYaI9PD1GUBeLvfo/KQQ8wAPh2x/lQDDWYt8GtR8Njk5N7yflbs8ATKSpMgCySpndGWA4V+57+QCz0zPbWJLqNwAAAABJRU5ErkJggg==",
    },
    "Aa26": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAAAtUlEQVR4nLXOrw8BcRzG8fd9nF/nplFESVAIqikEm0oRqIJ/weYPEPwV0gVZNLO5ImKzCWeCzcYIzle47/kPtNfzhGcPyxIA+a2SYtsCMA1f7H4BIHb2BCsFIK+nkKgJgBgClTgACMhH03lU65qTY6xnBty4NAZBTfmg7tNkwdkZMBqm8fZ+BqB5UkqtXQHm3dkDvYjd8VeuocO49RbNxS0e8nKNhoyYhAye/YHqRyVmyGc29wXxNC8wqR3/8AAAAABJRU5ErkJggg==",
    },
    "E17": {
        "description": "jackal",
        "pronunciation": "zAb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAACTElEQVR4nH3SX0jTURTA8e/cH9zUJZm5TVTSwLIakQ82ECn7o1EhJYZQaWYRVC++RGF/qN6Koj8KPQhWUoRLexAsQixcIdqytEGKaD2oFHM6oaZz+3l6mJp72O7LPdzz4Zx7ORcACsbqnbuJsDQA+DWlyaroJNmQQGYkEgOgPhIPhqhVtBaVb0GiVDFYbu7yVHfoI1ZpjEuJz7762nlgPhLBKyL3LHqaRnWRyM4Xzu5R+ZF/wncyYhmDKdF2+dH80dbgoYgGQNUwWeV3JEc1hUp5nTjyY1GhTTGbzWZL4lJKs7j3OZIumErfvvypDazdYVCjUrketC12WOpUZ9ueeL5sAxD85f4YE8g8OH3GHkYoat42wvpTqxaUtsHZSTA+LXHl+cIInfr9UwCxelVexjytFfdpqpQVd4H2242V2QWKsnXznNUI+/p8hr1l9rDJrXZL+3cRma0tK7SLI/BtWmQiLezZ6nERkZE96UBdoENkQUTOhZGzQRGRWgBtw5jbHxAR8ZgWvxQAm9QAOgDlT+qa9/UAxpqVw70r7mFFrgOkuWQuz/hcRGS6YAVpkWfF3hCxiXyGuBkRkSex/xslMf5mKhRaCF6Ev04Aa+oyyUmfaWYuFOfT4wQuBYCckmVSvM79hR7UgCGXx15g4jegK1omGQwpePzDgNX2zi7A2B26vWSF8rqs071DW+D4VxPm8ldyJXR8Sw4/lNAIdNf6Raoht3/AsrFLxGMF4IZfKnIGRAOgTvB3fWhBX2V1af1p0DEAoM/6NN47WHPsH4B26qXR0R/0AAAAAElFTkSuQmCC",
    },
    "N35": {
        "description": "ripple of water",
        "pronunciation": "n",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAFCAAAAADnWXrpAAAAM0lEQVR4nIXEQQEAIAgEwT278qWEDSxDFXJY4Gwg8xggbjBNliuH2W27h2WQ4f/iCJ3hBw9RS6iWOCOAAAAAAElFTkSuQmCC",
    },
    "E24": {
        "description": "panther",
        "pronunciation": "Aby",
        "src": "iVBORw0KGgoAAAANSUhEUgAAADEAAAAUCAAAAAABlopFAAAB6klEQVR4nHWSS0iUURhAj+Mr7WFQUFBBGylNqE3vgiiUCJOgUhKCHos2QUEEGkVEgURhNVDRroJACDUF29QmLFQweohCCdKLQEccUBxTsdNixulvGr/N5Z7vnvvde78LychYs7PPlPiypyiTOWPfs9epgna0HExZlhEf5lWU5lcTidybCgWzv5ecWs25+jTbnx5XG1akqxzV+//Bii71aWn6sx5Vy1NYlarp1wND2rkyCAoq9e2jtubQXMZ5tTUIjnVpy5wFAHrVLX+nWQ9y2l8uLuwHWBjLjcHJfD+9yEQglBMDWovhyoGJpKJ1eUVlW/ceLtuuXoV/2lG9GSq9+9iO7ICh6kxD3aJp9QQjDo2MjU12Xr5WO67WFfDqe/WMF5NGc0Q1DBBV3f31QzL3SdWqsHcu2Jek2TsGB7pXAZSonf7oeD6bKk7UH3VqXJ/EYeANaNNRBtQNCbBe9eGtNwkxDHA2GjDU2wyqtQmwTj0C3FT9ZrQAmAy0ul5j8xlWbyRIu8bvFFaPl2vjmeDnCA3rIRhR3QbAWnU5ANfVHi6p+nFWaFQtjTfYTUDuO7UXgF2qA5CXlZ2ZsywhlKjWADWqGyE/og4VAtBjvLeJw8SH6W4m2pqALGBmKSx4Dz/39wNktPyCz02zxh8Je1rv+1HWfAAAAABJRU5ErkJggg==",
    },
    "S14": {
        "description": "combination of collar of beads and mace with round head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABy0lEQVR4nHWTvUtbURjGf/c012hocFAjRTARrF1SuLeTdGgz+Ed0EWImcbKQXRfRoVLocEUnB5eAQ0ZxaYeSqdZgLkXwY5FYaINwLVdz83HfDq1Nb+15pvO8P8553/McDkR0dBT1KuKyw8NZtMpURCoZHe3f9HM5f7Nfg9O+o5TjpzW9BxL7YbifGNBgQYFCNIePNfYeT+41xjTYXG1Kt7lq6kYfX/K8pXEdhcTpaSJSiEXcTZObSCEa6j1Fd9+7lAHW20HCMGa0lRnYwZd4OzSloxTe6yoGz7afQrVlGm1lBiow4+3QlHafBbX8Z1I1ud6q5f9tmq9tXUstxUL1cJdCfWPkbziyUS+we1hdwFt2CqgZ52Jl6A4OrVw4M4qCs+zRsHYsYDq48tZePkmln79Y866CacDasRq48ZINHByX5Uzq7z+JnEn5+ACwS3FX3QYKYNQ9Z5FyZvAdi5y7owAquFXGr3723GXphA/1bx85KV3O2b9TiUEowHfe8Gi9UuyrrHuv4AcgIcSE1l2SX4s8lHrxT8AtRCWTXV3m3WRSTeQ6mldTndxEzJ9Ndf6PO5OzPvMiU72S6/bWUyLzxgMLN+hhen8snqX6Ez8/s++NKpD4AAAAAElFTkSuQmCC",
    },
    "Aa31": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA0AAAAeCAAAAADSwsuVAAABUklEQVR4nD3QTSiDcQDH8e/zJ2bWWpnGcpGXRdgODt6aXFaUWu5OmiJvWYmDlIM4Kg5qkojIaYoLLpOUl5W3HUxyo6FHy7Py2P4O23xvn/qdfgCwKAP5ZLOH5bs7C8PS59jbrimjRt3HxG81IICq11N2nmwZtYUivBz4lPTycRxofjGAAK/5BjjX/AC5p2cARNZBYDEGAFhxmBC4KioBCDo7EaKpoK8WIKbWISzts5GtGiC+a0HYnfW9sb2OPIh6HMx8yVXb1HOwGo/sFi5tvmhzv+b2olVLuQmHS4T/aoTeyNzDFfLICl0fa9Ye7e1MIBQ4aLFf3w1aCpAnxQD4fxYOU/9iKilTyBNrWspQSiceKs3+sx0Vk47yDAqNzzTcL2fkSXgRw/qooiiKYr4MFUHOsdR1Xdd/5QC5JL83NADKNAQeZ1xVVVVVE/0VMC3/c/8BGPqEviDkFJkAAAAASUVORK5CYII=",
    },
    "A25": {
        "description": "man striking, with left arm hanging behind back",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAAB4UlEQVR4nGWQTUjTcRjHP/+5l5oS1szaIo2Y9rIO1aHshV0qCKIaQUIHaSh4KowQwohCD1JQtyAr8FAye4FusihjFC2iLSIXSLaaI4iZmZJuLff393Tov5x/n9Pz5fN8nzeYD29PIv2pSWNR2Pr/xE+0ftxkSMs8Weq3L2mrLfiKetVym5F51EDNRT1/tEi+/dhtZPbrKrynU79gNbTE1xWLKk4nc4HzyVtHDDK24/8ka/T3Ie2y/Hq8C2BYbyyC2pDeDdbjBUm6gcOpqLHC/kmR914ouyHyug62PJd2APaNyUzv52EfXJKwXLNgvy2FO8Fg05Xv8tRvrwulamieawx9bYCGERElIhLxAO5Xk2cD2Z4u6QAOxiX3MvLigetf05mfUcl0Sz/A5siZqmUuh7HhG5G3iXNDMQBWlnyPqAyuH3h0L28BGFclxDna8sXmsjhKqwGoXDGSpi+n5ReRNncfRGatMTNY+y4DeIbaN1pNpNz5bGcZ1c4142bPhg95JaLkYYV5jl5w6E96p3DazJ5Ts6qr3H5ABl0moF2VDFA9Fas3dZNpbmqQjXr9JrI6wH0Bla2sMhHf1tFpAAtqIdFaCU8AcwpKL3VuCx6buJsD6rcvMHQkMqI6HXAynpL03r8xVrywARTyGQAAAABJRU5ErkJggg==",
    },
    "W13": {
        "description": "pot",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAATCAAAAABaJRlXAAAAp0lEQVR4nK3QMQrCQBCF4T+SS8Q2ja3VYhcU0tqIe5uAXc6hR4g2gYS09ukEBXMBb/AssiYbSOkrdoeP2WHYAEB4CYAFcwnHBsZn873/UTMR4zShHqwmcZpSDlqS9sVasoNaqR940ssb+1QGQOvuPplaINxLO0+3koVDo8tks7Mqy1Wq/IVNJRVER6m7/XxTvCUbAXEu6SO5M4/dx5okXS0BukfZ3IEv2B9Cc2Hp6y8AAAAASUVORK5CYII=",
    },
    "N2": {
        "description": "sky with sceptre",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAAA8UlEQVR4nGP8z4ALsDBcOYxVwlaH4X8fdj19/1kY+GIaWCG8fz/ZmaASvxt5GRj//2e8/JSZgYGBgYHL8Ok9RkYGBgaGvzI6f5kZ/v/fyQ9VqvQ/Gmac4O7//xn+HxCH8bX/J8KtEt//n+GoLANCKpsZzpE7huwo3f/3Whmxu1dyx7dvLNilGITX/UGSYkKWevuemQGHFCoPVQq3uqEt9Z/hLw4pDi4GEewmsM/9//+GIVaphM+zK1+uEMQmtfmCCEPPcz0sMqx/FzAwWP8LwOKMfz/+MzD8Z/yDTWo/EwMDy6tHWKT+r2NmYGA7fQPGBwAOsEdeBm01XwAAAABJRU5ErkJggg==",
    },
    "A41": {
        "description": "king with uraeus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABtUlEQVR4nFXOT0iTcRjA8e/728ZecEH+iZYriyQhQgsi1DKF8uKthjAhNUHs0iHoEhEMdgkMVBjIKgrEQ7BDSIcuGSRUhHQomS2ScLNJuHpZG2Pyvnvd+3TYFvQcP3wfngfAc+bcUbyTnyV9Zz8A+L/Ya93RX7ncn8rTBgC8A+/lmzPR0z+wakf0ajVli2zOK9rXrbNVYbkUnzZSpxmTa6oqsQ/Rwkgi7M1YvpoUzLz2+o04Batc2zr1tZUD328Rci7UmvS+R0O+Yo7ZT6law12R+LvR6xKuw5GNmSFHggm5WZflHy0UH3qey2MPruHLLog9YDzpY1LKPTyTYivgZmUDTu6kY8hvexqgMxOHg7u7q0jkfvmiBjcqfeCXn4MYS3q0NAIzpg8O7Y3DlH2JxewJFtZ1CJhXUK/yjYRzsbbeBQtAobZfnlfpaN9YYE3qz0WyTWiLUugFAmYQRbJZR+6VrCIggGIl4YfM7Y87wDFAkTX6gSdBA+gAFKQGAccCGN5OomCzrX6ELiODguON/2TrcAcavOgOobltV0Wp5rm3E26udrUsoXnK7j3lMiWk05mX/+cvtYC6VmUrN18AAAAASUVORK5CYII=",
    },
    "A8": {
        "description": "man performing hnw-rite",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAAB7UlEQVR4nEWRW0iTARiGn3/7N8uFeFpOsbUlFNKyWBl0IYQU0mUWRgeiixKCDpAQVERElAUhC6JBhiJeFMUKukuomJaFxLCiELFZumqnlOBvs52+Lvb/67t8eHk+Xl6F0qmNikRyWPuTPf9hvW9+bvokqAOhphKseRg/PlZIelD9ctGAygWJN9tb832o/fLCoJ6ESPYw7+5Bd2rOZFhrh6+ojgrlO4xHVxnZDtnOkv9xbD20fBODOieSLX0FGQLaI1GDWnxyZ/MPedJ58Jwmr40Gw1O3XbR9FBER6S1Cb0DOKMAtkcEDx/ZWAtA8KXIDyvBlb6oAJoB9G2GlY9el8uqEP2d8codlQYsHf322jz+1Fd8ADW5sJpudaU0Z/VOiWbAC0btpc4YStUIkVV175BmWtYbV3PNWZnZ4eqUOJr/W6HTLT5G/5zkqdjoWZxt1gyXPjOOqqQpv/fXKREHPbovItT0TIpKT53NfGii2yOdZF+iKwavO/SMUdMP7WWeOZVW/Twc00qYVejYzL+7LH6Z2DmlgdXWXZtBEPm0CLIciMmBM5l2UNxtAOfFgSWTMoXcrX06kfXfz1tVmyVjLrMWo62VotDjByKmABOsA1Kb7rYMLbchsKPgo5iScBCAskk5l58+uqQD8WhcA/wBJctGqCIYMVgAAAABJRU5ErkJggg==",
    },
    "S29": {
        "description": "folded cloth",
        "pronunciation": "s",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAAS0lEQVR4nK3MoQ2AMBRF0ft/EDBjkw5BUs9iNV0ES5MKDCnuYbpBUccdSHoihEs6A1V7UkN53bKc8vaCY2A4AH8yzn6jA8wWAM3WH589F5ecaXhZAAAAAElFTkSuQmCC",
    },
    "G54": {
        "description": "plucked bird",
        "pronunciation": "snD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAAClUlEQVR4nH3SW0jTcRQH8K86d+kiNtLN0lbTvKyJBmpgGoImRv+erLSMzEKlCEzQMmoMQkksITWiDMxQITJ9SBFLo6x5o4cVZpZdnDPM6ezm5q79Tw9ba9L0vJ1zPvwu5/cD/obwqknPxmNJ+Pj6uqfByklzTDeFernVOJWqQSnHlYobyZgBwbhq9T/CVZhM36l0lTMV1ZORQUJ/9y6XEPiVmAx5GKV9jpUCFPkLFzpjWi0N2s0OQcL90XLz+Tsb3m7lAwDCakhfAHTQkrC9PuArGdc0ijgAEluCNQNtQB9ZXDvJI78MtHfYHpjlVgBI/DCpkOmG0vzdr5kzR3V+wCWKAyBI+KTZAaT3m2+J3YxXwRwpfZD6tVUKRI9ZcwEAR/pSlsyvsK98HVBP13g4S0/gObgyfyDbOMrAuJi+jAEAxIyQCqReiQCn3y96s28AbpYckJ4J92Qe6QX43YzAG/QsSXSPcj2ZYrsG7DDivzVSTw11Rrj3ZBUpAHB8nipA5rzYQV6z0dQldSchbXQFQL6RGiTQ0kiUPW4PLex1J1kdtp7tQKFBV7senKL2NePVJ4vuHzw29hkIZbwJAG93qqldjRPV02W9vwDuxMdDsdYC4UO6qQyAsOsH63h1fQ6Ozj1PBgB4p5EKl82HA5vI3rIWWdYShmEYpopKcZFmMp0/NXOqDtWGbN5ONTXx+T9rAQDiztlMvyT1VJjzgBnTVZwy7XDipnfsXcw/dhTDe/WnoKBYp+FWsUokv9TFhWjtI/anzmrkC3bC4DIQ3bafwza1Ljp4lsg1JlGUXBbBc40j6LqtGFteDQUESSSeHsSByjW6GQtbKVhWANhY1m8ismxeyYAjS+omMopXRPCKKlFTM///xh/n3Ry80dtEpQAAAABJRU5ErkJggg==",
    },
    "X4": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAKCAAAAAD9OHM/AAAAUElEQVR4nI2QsQ0AIQwDT18zUBZgF0ZhB7bJYkfL05DrYkW2bCB9kEB7fmk2umZwMHWed6R20nWKDCMcP2mZ6OUVEJefftQohhYrFAepzbsBPNu0pUgKshQAAAAASUVORK5CYII=",
    },
    "N22": {
        "description": "broad tongue of land",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAALCAAAAACmd9lVAAAAYUlEQVR4nIWQsQmAQBAER7ELuzHxtJePDO1H0PweqxFswQbWxECef51kg2Fh7yqREJ+crwOkU1l8aanEkLYBgtXECclyFnNpLVrMpSavgB26727R9i5txc0jxPB7b8L7Vzf6RVohqBRw/gAAAABJRU5ErkJggg==",
    },
    "G37": {
        "description": "sparrow",
        "pronunciation": "nDs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAcCAAAAAAot5K5AAABG0lEQVR4nIWTsW0EMQwEx4CLYuzkemAlD6gFtUFnV4I7cA2XOtxQ4TrQ2+//vzszEQQMl6slBEDYXoN/Kl1V1jkXqyuINpynUjbkRnic6G22FZEQ44yDGJqnx9lc0kGua0bZywnnhuwOKZ1wJTx9hXQ5mco6/bFsOh6sQv3KXXSYtMwvR3j0I06gqz9iHK2uecAtt+UowrKgrFx+BGsXLAlYxxi5ALF65B5YdoeoMUblBNV2LM5FAIts263bbq09aDbbdWuvCdvbdoeF/eHCw7bmA7Lsqid3rbs7M7OkKV2SHjg5kK7LJUtuAW/yHdfdof58ibzaU73uJPNb7+8ADT7vxArSj4YBuKnNSIuvI20/1dOSXsA7nS8P92/1lujT7/rc/gAAAABJRU5ErkJggg==",
    },
    "D20": {
        "description": "nose, eye and cheek (cursive)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAAAAADhgtq/AAABIklEQVR4nH2Qv0tCURiGX6P/oLW7FjhFQ0RjEERRs61OTS7R0CBhSw1F1BIXjJrq4hKISyLWVIktNkhLU8KNFg2xMLw8Ddcf9+ildznv9z3n/T7OkUxNJbLVGu8rGlYiW60BZIZBGuD5aCSgNC7p0fY/IEElHCxh9sf7iRN9PziSVDo2IwS1GQBJIOXbaBI4HGyH7cG9J0h2bYV7SzptfNS7r7+t+ecOb/lmb4l7IElRSZLNj9qwp8XWVx247I/NNddkbblQLBUKHeBz3QfX2JKk2KM/Lle88MEZuX465jhOrFeswnzYb2n6hplQoEy7Eg4E+5KkSWfDBGOSJ0myZq/sBQO9ctezeYIgMpda9s4ldVrxCUXMgbvlhvcLeC/xYPsP6B2jmsgiRxAAAAAASUVORK5CYII=",
    },
    "Aa6": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAARCAAAAAB/HjpkAAABaklEQVR4nF2RPUiVYRhAD/d6IxIkzIyUuESWP+iahSDi5BAEEYRtLXcwiMpa2v1Dt0BBTURQIQxRMYcghAbdIgdDtLAhrEGRa8jHzTwN9+f79N3O4fD+PC8AXN12vfEMp9bjvx62RviGHi1Wn65W1FSI8WXV49oTTfGmqk0FcUG/v1FrotWqfsio5/KiXSeY1eFI1KbSqj7IiYuBLkGXjhaiO2o/qF9KsqZffQH06XgueqoOAPtqJwD1ppd/AvBJuwF4qL4EeKd6F6DHwF0Armd0Jg7t6isAljzecACo0mH/ZA9KpnUuWfles5vTpSltJHHP7Wv25u5TFqjqXmVO7MhrH1E3bwfG82+byVaXw/k/qXU61nDpx+AVivP2/hTA5E6e31L6dbQiNnZziM+kC4M6ADksoJzlWzN6lHEhnPmIaylHQl4xo7Et4glKIl/Dr99Rev4vwcei28ln55kIbUDLLYKQV8sTBP8B64DMxYx8PYkAAAAASUVORK5CYII=",
    },
    "H3": {
        "description": "head of spoonbill",
        "pronunciation": "pAq",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAYCAAAAAA9/JnTAAABQElEQVR4nFXQvWuTURiG8SshNBlsaodOImKooEEyiIvQP0BECiIhQ6BBHApFBFOwFBUd7CA4COLQxVIRnEIwIYMUimAXCfmAgAgKZnIwWaqGFAq5HN70bbynw4+b55zzQJjE3QP1b276mMh+VbWei4R0/xlbrcTw1qWPx7XfvgegMQqp7jA43DM6pguXWRpfddS6rtcgfR5YN6AzukPyja4lQ3vqTyr6peOLI5vXBymbs+BbigLEv/lyyjZAzczzHsCyIzY9DVByoVcFbmtm1lUAyl75VSHOng36weCInu1vU/hsh0WfBA/wYd48f/QmDgJ6ZHHTbPQEG6VXXA3sDgMAm4WaP8Zf/G502yytobZnAnqsvDMbu5E6x4f9wC7ymjjEut3dcIeHVDnJ//lklFPmYhMUX2CFAenJ2lxT1fI/6KaQrkxp4AwAAAAASUVORK5CYII=",
    },
    "A26": {
        "description": "man with one arm pointing forward",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABoUlEQVR4nF3QS0hUYRjG8f85M3PGGZVRpowTLspLDt4obUwJXTQEoi1s6YVAEIJatWvRKhm6QCUiodImMRFCAy8gmIR4AcEQ1BTRhRYo3qgZPIqeZr4WYnyf7/LHy/M+vCCNkftBjAY4N5c/z43b/ef1iWg1a60GFdOnj+fyae8EXdLM4uFwuKLkSNXN9bIk3/h+F+g5bwbD2qn+fJ9489XuxRgwI4TYajbBmbfy264msLdcBF19PV++H+/Xh9qE2IzWQZN4hvMBcKEy52E5YxOj72p6sIjhBNjrJu2Oa2SXqAmPVo1TBXZ6QSvITC4LZfU7/iuAr+WqFS6xbJ9D7nuyQGLp1J/YDZ+sh907ork2chIMyAmYnrcvMFYXE+RdUlxj6O74r+uypt6LLCGSglqjrN6MyQ2E+9rffDk3u8AKOYwEPaL0dRsVXwGrdV0+5u8T2683xCf161ac9qfPcahaWE5vfN7WVTUvLawwe+BUNYuPcQQo6rlvfQNNUzV4e2ANbnljnPX1+0sLq/gR5e5LQ5ypKxR87MFegyveoQ74B7fticTu2Z+KAAAAAElFTkSuQmCC",
    },
    "P4": {
        "description": "boat with net",
        "pronunciation": "wHa",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAUCAAAAADE5BDUAAABgUlEQVR4nI2PP0jUcRiHn5+/nwUtucRFcJhYB15ctji0RUtU5GYNbUEg5aKTUlOE0DnoDZGY1dTSENTQUS79MSLvEkqq5UgqOoVK+4MWh/Q0dMdV/DKf6X35ft7nfb8AGzNXdKaJGMLs/p2Jat1176N+iUvBZDF/Ng2sz1z13aTOx8cG1ZkNYdCR3dM7shJ+z5SA9ta+2vtwfhmgubAJllp45EUO+CwJiebT/sbyyPAuoN/PQ2bxFuSmgS71+bU7BwHozl+fUHOdjbtd5II4Bef8VNFK7193pV6oJ2/LgOggR1RzMR84fv6DTtMvT7SdvQt+SyS3xwTvunKY4iJNndoBLafUpbelck890l1WL8EDLwMDegho4MTCnH9S7gEeO5sEaC34tPGXYMu2VDqdeqjjW3e0tQGEU94Pqvqj+uPGsZjThgp6s95uHlVfvX4/RhhFIRBE7Jt7U9KXaYAAQCrrYlQA8xNfk8UztdjqBES14t8INPxHVCWqT6yy1DXZ5Ceg6cnZP/g3IQAAAABJRU5ErkJggg==",
    },
    "P8": {
        "description": "oar",
        "pronunciation": "xrw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAeCAAAAADBFYthAAAAmUlEQVR4nFXLsQmDQBgG0M9PyEGiiBaCWtja6UJZwzJLOIKzuIGdjSCk0OYMKEK8+9MkRZrXPVTDOFRM/LufUC3PRVHoUggA+CkQ0GRRZiiBFwhP5+Kc3A/32DlPapopFvZ/iUCEV894V0bpO40YntsZomtvbce83/qcmYbOuI4YV1oDY78riBEHROEUQCMPaVBq0SVU/arVB8g6QtDRW23KAAAAAElFTkSuQmCC",
    },
    "T19": {
        "description": "harpoon head",
        "pronunciation": "qs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAAzklEQVR4nE3OsSvEcRzG8Vff+2VzR7L86lJiUFImGQwy3HCDhUEGuzK59QzS/QHEZKCUSVZ/gfmU8h8gEs5y5PoYfie2dz3P++kBNCIV0JVZr2NKZmYV/YCtyCzOYQGHERERlPM8z3cj0+ng7bee/rx/UJkfgTR9dNmqwEl8ftc0Im1cHJQGkB5G281rpObE4N4LlFrdGo1IvdP77bFiaumpXd0MWHm/uQ2w1o2A8aHaYyTM7t8dS7iaPC8X3vJHrygP77wWoHr21f9Xf/4ByYg/yvY22T8AAAAASUVORK5CYII=",
    },
    "N29": {
        "description": "slope of hill",
        "pronunciation": "q",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAARCAAAAADxxHMYAAAAhElEQVR4nFXKoQ3CUBSF4Z9AAkkZBFWPqCE3TIBEkmBYAIOtInlDVCJYoyswwTPIJhDEwcDrvcf9Xw6Urfo8tIuxTRqymtK11Bu6F0hKBpI7GB6STgTQwwLUOhPgli1Ao5YA3f/5g6O6ABe98bDWyxwsD9KVEWabPey2FQCfKUye1Ry/L4vwQoz4ovF9AAAAAElFTkSuQmCC",
    },
    "G13": {
        "description": "image of falcon with two plumes",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAeCAAAAACDVvj2AAABdElEQVR4nH2TvUtCURjGn3v9SNHIoiIqGiQQxQhsaWjMomgs2gIjKCr6D4poaGiohv6AaojGhiCkgugPsKUEg4boS6QPE9HUW0/D9Xodzj3P8r6H8+N53sM5B9DlfyR52gSZVkiSPhkSJsldHsuYe5LszdIhYUokCyhRuKnq5Q/AE5xiA9Uoa5DlAIDGDj6Asqyo7ccOLyqyLCdccbQP5WVR4yTJAqlY++hzuC0cVJl9vVoKrMo6y1FLER5eBYAY1qeQcCSBoCXTDFdqekCbBa7arObZJm9jAKK/THVbMAGN5AKAwDtzOxaQv0hyC0DkiLweFUM9X+QnAGCT5LwYmmQ+oncT5+Rcq4gJ88Boffs5lgMiKMGuWj/2wueQgFGYbjRXG+TlsM3YimYAAFouHsyG3mqQ72wQWD25IwBUaGqx3rj/8INMLgXcXkW/xeKForhmXk3C05fRGvZGAGC5ypRvVMXp9tiNt1HpNPFvRfwV6pX+B/AbpKXr6Dh7AAAAAElFTkSuQmCC",
    },
    "Aa24": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAARCAAAAACUKYFnAAABL0lEQVR4nGWQTUrDQBiGnwmjRfuTQhEqRaRQNd4gvYGgCxeKZ8ii+x6hN+g1BFuYExhX1YLbrFSElJakpoISiIupzU/fxfC98zzMB4MKFKjk/0iTVhUoEUCfgRn2GUA9owXwdA9wbYMIzJSE/Yw2yALhH2zKbDdDCH8zxPDoCbGzL0QPT7UzUR6OEKYQwsGTU7sEcQwlbPuOXCqwBCpM5SuWvjuhN8pJF8OOHjq8cJO4urjJVjbkVn5Q1aWKk1/JcEPe4TE5k8Bp4nbzVtdNztEEg2f9XI2Jm9fcCeU1wcCnFUto4Rd24tMGTQy+OSaGI6KitqIBcMgKg4g6Ehr8FLWIJkCTCINParBHhbeiNqdMDcrMkSyx9Ld+FbUZ1sN6kCzGlwCMl1tLR1cAjCL+AFZTdQYU+Ag+AAAAAElFTkSuQmCC",
    },
    "M32": {
        "description": "rhizome",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAABMUlEQVR4nAXBzyuDcRzA8ffzebbn8SvLkB/LNGorLSKJUA6cJAdxcthJpOzi4u7iD3DD0cWFlB+hOCjSFMVEieyy2fzI1uyx5/l6vVi6r96OGhvLoZTgDdiWg6rU5crsyUcN22k05bZYYYfK/IU+QwzdVqpqKO9/EJRbJ2RYhbyrmB31art0BWxCMaW+MlmlTlwzgfT1Vrx/KuzmN7Heq+EeT/ygbgZNwDOZET6uCsD3J4ImAGgISgHgIH+1fgAaDFlt7QbQIy9yWuIH8HgOxEUZwFjbjjxd9tYAQdISPw/7wGyOv8vfW90QNHXEctByt1mqLTgjgL6W8Zn7j0EEO+k1OgcOXxA4Tk3Mu84sgPKdohNrB4HchcPZMwDDr0olpwFqj9TinNqrByLWCkStWf4B3qxxlwL1VzgAAAAASUVORK5CYII=",
    },
    "T14": {
        "description": "throw stick vertically",
        "pronunciation": "qmA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAAcklEQVR4nMXOsQ0BARiG4cclNnAxAY1CISYQ5S1hFStIJAag1SjEAmqV6sQKmotc4lf8uRhB9+T9mk/cZsDxdRmB4Sk2mSaPZpFatucB6O/jUIJpHasct/Gcg/Ia60xV3BPjpk0UuyjA5y2h18FfEb8/Xxb3HgkN1QYuAAAAAElFTkSuQmCC",
    },
    "F42": {
        "description": "rib",
        "pronunciation": "spr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAALCAAAAAAykXCnAAAA00lEQVR4nIWOoU7DYBSFvwaBaTIUD4BA1pEaJJ5i5v6Ed6jhESpQGB4Av9P5iYkmSyULcnPFcpdcDAnhR6xZaSb43D3nS+6BniCLA941Uw4kAOQPGRfUQ5ydp+xYVu0QKboCI8pS8mjKB6U9HH+RbK8lqKibBi5PbrNTAL7efmC2WQGi+PxeVkn5+PLKdQHQj7qapPA+Wcw2q732nKhgx8e6r1nc9b/sDOqqBd2k4xVBFrfKCTLv7t1NAZ7i0dogj7FzAeCmMI/H0hhzbaP+kTA38QtbG2vsLjTJ9wAAAABJRU5ErkJggg==",
    },
    "M14": {
        "description": "combination of papyrus and cobra",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAeCAAAAAATRYE5AAAB3ElEQVR4nF2Q30tTYRjHv+97tnO2xo4bOF2CP8CJEKRgE8xJhQMxxJtJBgpGdwX9BXVv6I0QCedGEUlv1CuNBNNIJRqmTsQV5EU/aBOkho65uV9PFztn76nvzfu8z+f9vs/DFyhJCSwkiBILAUVvsNIhawMX8wVIQ1eWHmVhkhKmuAfwxCms4B+5NVrjfI00N/6TZbUYChVXLcadATd6+MlsDu0bv1AT3BFP247olF4AmCN6ZfqiI0p+9xS5gX6iftHn67V4+sReeAmkgbRp5lCx7uqID/WAD/C9LQMGQNrsLLxJ1DV7cfJZ4ht7W3906Fonusx/yhGdV9+aiPyI+B06aXhPlIrmiC7HHg63NkzTokvPqinIeNWzLevNycbmipnRu0HlsVijMvt8LOt11PR9/+a4QzO8DLzcynllKvZ6kB3vjj8QoJvF4qwbQHjY1vcuWQ4NauYr0nYA2N6/HZEFuJbaR+o6AOC3q9YEKvJJkLOUUxGbAtD5GbuQjAgPxHAQKGOU/IPFDAxlQmdzwsFkzuVSEEn73k/hyDtVOPMAgFN4HMIRVbu61CgAYCnT4hVgxdY7YFsGAHz5qMhitnwYix1YAQCWaeoQAPeJBvXyXjZgApKmGauos/6/Jj6mqsguM9cAAAAASUVORK5CYII=",
    },
    "Z10": {
        "description": "crossed diagonal sticks",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAPCAAAAADbz1AHAAABJUlEQVR4nF3OTyiDARzG8adpkvdAKweZwyi9Tqu1A9mJLKU4WKFY5MCB7CLyp6zeA7WLsowm9bY3F5u35ORfXJSETWpqaTswKf9O06v2uLzauz3HT/1+fYHBdStK1pJaBapnqLiLvemEhwJGH06DX7KzwI0Sz5Y5Bo0y8Mgrne0BMoB+RjEVeclM2wbi8kQH0Lb7+zRbaT34TA4DgO811wNsMyY9q81oPaZap99XXZIeiAnOQXxj2mUIqd9ndhzeJMluY2CZJ5EN01+O3jgnawruJH0wK+R9A1bIDZ0dYe2uHX7+rEkf3DFjj0ddJsC7RbUWrhtGAGCJuT4gxPNO3HIBCi8s/28rNvPfIhY12GPvzDuMJUKGcjQN00hq3oKiCUPXDP4BzN59XrOwIPgAAAAASUVORK5CYII=",
    },
    "V1": {
        "pronunciation": "100",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAUCAAAAACRhfOKAAAAgklEQVR4nEXMoRHCQBgF4SUyigZOJxXEUUNk3AkMlEAHKAw9MIOhBFQchZy8maOBxeQfnvrEzgNOT9ULMBdtzZbZN+sAZ2V17QHuohOOMNrBFzJMoBk/pCq6UlXlrX0qWjOjFrbdNIVfOoSLtQ9rDS56DM+6/G8Ku8i5dhsfHKJIth8xn00LbSuFvAAAAABJRU5ErkJggg==",
    },
    "R24": {
        "description": "two bows tied horizontally",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAQCAAAAABfdVLCAAAAxUlEQVR4nI2RMUrEUBCGv00vBLyC4AVeE1Cw9gixSmerh9hSS2FbUS/g0wMkRW5h8VptB6w+i2whbHazfzUDH/PPP0PvmgWt7dGyhBWl6MlhqtZSfcI5QOuMWoAzeF/xcDdcQvvy87Ez5/r05hX6i8d7INvRRE67dimb6MxTNxrGDAXJCPttc6XG/PqhNkAF/AJ7sP8ajXDeNPx2nOpsR5qN0OTYRljxdHvMQTZOfvvPm3RDMerDq9dajnn9l1YDz0vYG8Mf0c+NuxZJc8oAAAAASUVORK5CYII=",
    },
    "D3": {
        "description": "hair",
        "pronunciation": "Sny",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAUCAAAAAAv06vXAAABGklEQVR4nHXQvyvEcRzH8acbjSahbkZ06YqOMhlcl013JVHCYCG/Ssp2i0U32E4pBpuJyEJEna78Iwa5uDvnafDjUt/Pa3z16P2qN4kNI1IaHOilmZbTziQUY7Fm9ZZMAlwdPF/8dfpa2OJfUvulkqrFwm91XIlatPFRUz36WaQv3byS7EgBnGT/mr0VIpK9bliGouritTobpSBRVZhToU3ruWg2VnUTcpqBvOajFZPaBo8KnHkWUNx7CzwJjGtILVgfhrhrwLmZENMbQOOw7HpITSsw4h1QK4dUysb3SUCHwpMPQFVgxzyxaJWmFbhkCT5Z7Q/c6vYJGNFRul7cDk0eag+oTuxaCal5FWZUBsKPzdbfl4ApM9DuF0vLuWUKCvAVAAAAAElFTkSuQmCC",
    },
    "M38": {
        "description": "wide bundle of flax",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAZCAAAAACTTbgJAAABN0lEQVR4nI2SIVIDQRBFHyk8HCBUUGBGbxWCE2DBjOIC3AEVJBxg7ajFJ9gdCwYFhZwYToB8iOyySQhUvumunlfd/WdmT/7RXhdHx+RMznQhZ8gvXXY88KXFQpJgwkRxYqJIuzqmliRnwpJqxAoT1itUJQhOscYpSlepVle0xtg1EmyRKPW6r1JQbHsqIUopAzKCpzF3CzjncSgv7hg/rfWqjEgrqUWCEZG4vhbYYEiSxDiV2iDN6lr7QL6E+MXpEYELqE6IcJk33iE592PmTKM+O9cP56YNKvqHmjgZqLCslW1gueqpiWiSxqmxEWc3YoAqqbPBZDEuPZLEOthZPLwfsGIr0vTUNf5cRNDr3uSWzftBp3owAnjjt1775P2B2y3nm5r476/v1TragfpkF4rdqMVO1Pgb8IkSwkaM8iQAAAAASUVORK5CYII=",
    },
    "T6": {
        "description": "combination of mace with round head and two cobras",
        "pronunciation": "HDD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACMklEQVR4nG3SX0hTURwH8O+5d7tzOWy5xmwgKxdttBb4JyOChcunYD0E9SBRozGyBPtjwiyyorQ/T0kv0UN/BCuwENTyodRiEIvUaIIxSWJDTKk5t9zc3b2308NdOOn+Xg6cz+93fj/OOUBBmJIjxVAO4xCltzlF4m6lfR2ZhsItdn2pXgUA1kQ3Sj99YQrsgshLlwCgirqBwMrqoUxb84fGmL8GAIEIiAVVjLe8bPtjSyuADO+BYf9PaRXtF7/OLtIZAuh6hdmYdGXtgA5K7wHArh4a79q01iopdQGc1bI3/dFhsW7eqpf3VQDqAHPjHnuJIHDbnmgYqPnPXeP5uvYczYqUjjYcWQ4d9HpcJ6dFesoGEADwt9jkLCpwiL4Jx6s2Hog0hQmc9X+CWRdLJBDmzvQDoq2sqB5qPeue88M+IWSD/4aL9wLQGHxzCx2vUi0I02/POwOsbIt98rpvIekL9TFjL02H684b8v3yl/L+qMqaKQPU7gCl5wwAak/zU167CgBwLDKWIABME+aV70tg9CUc5Xnp+ossUJxkYwQAuXYZA8MsJ+A3uHlP7XzzJIyxomECgOw4UcGqaERQn4lE+ZG33drdKWNUO5h/+xKdTgcg/mxD26+7zvF2GNO0U+4speQcUpS4OfhQeGcDWGGm8HfIMXn8kMZqFtShgf8NUzeanDUCRKpg6FlaZ6AMVbTcVZRrJYZRMvQve/VBR7Wi/Xi0RbhvrFe07Osc2/9051/bYc+irHqJCwAAAABJRU5ErkJggg==",
    },
    "E20": {
        "description": "set-animal",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACLElEQVR4nHXSXUiTURgH8P9eNz9xU+Zc5UVgrGhkW3VRLiIvjCKwqAyiT3aRUIbRTSHUqOyiEILAPowaiTgqkRiMQgeuCCTSmKVpq3ZhKrmW4b7KaXv/XWxu79g6N+c8z+98nwMAAGyB5Vc8BcgoQrzyKJ8ZK3MzWR6vAuJmBDN1iWVgKJaFE5PrhC+fFVk4Xuq+OWo6Yqr/qPlHZB9sMWVWrHzjvTo9JHSK6mxbW9caa34aey6OQjebRorqcT90rrulFZfOAYbJM+kjd0XrjuCrz9Y/OiO2AI/fa9LY6Sp1IxIZvmYo7pzTQuc/KVXD77bjImpPbABQO9cA2KdqJHyW1o5oop0/8UiO6vmPG1Ns4c9Q61LQPWGE7Dr71yS5hRysWAqOiUeBkvaYXZ9IaAboXpXsu40XARS0s2tlPLHdT2vqhVfTux+ApjvqWg8AObcY2pPayDIydABAqVWcrgVQ0sthyROuILnYWKVAzkGfbyewI8jLSH4HiMBQuM1vH1cV3W+8Z365tXjEKrkEI7lbezNMkn13eF7ew2bpFVr4fS3k2kNBLtA26Nb/+muSsoNd+QBg5tveV6d9DvaVSVQ5TQsAoNw9U2XCE/45BSD5FcsKEQAA+F9oVQP4hClXivPKmlSLPgjqItAZuoHCPLz2AImDCU31etnYB1zYOzk2sqVoU4Pp8PxDJhfOd5Kz9Qp1mCRJMUq+S5AAYGEcuN2zWO6Np2S5iDxI8D/Hct/r0D+fPAAAAABJRU5ErkJggg==",
    },
    "F9": {
        "description": "leopardhead",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAaCAAAAACf9lPmAAAAm0lEQVR4nM3OKw4CMRRG4TNkPJq9IEm6ATxiDJuAbRSBRxSBI2yImQ00yINoO5CwAX7T5ruPXKgZ9OXrFKBvcuYK692SR5WoQ+kdQ5OUjMUuVSKoRsj3KgoxpgxaexQgj6CEXBZ/5omzlFZdwKYRRwD6G/t+y7SCwLOWgqrpMJnn6WhJ+ixk1Gz5Nqrjjbr5Arr6LvjJv9LX9S1vKphlhlDDkM0AAAAASUVORK5CYII=",
    },
    "U37": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAaCAAAAADz8AHjAAABV0lEQVR4nIWRv0tCYRSGn3sR7hD+aLDimkYqwo0gAiUhymoJpKX1bhE4tfU/9AcEYbiIU0NDm1BgU0hIQUJgJNqQCVpD3e1sDf5I0a5n+c75zsN73vN9Cp3wJI+W3+pPVav2YYHuXpre2NQBUwFmAvuJGAigdQ7QACmQLCvh4EZsm8eH+6/3StA77w/6p+LwXCXdrkNphYzIbToVZXxkhBvJ/9MEiIua4LNbnGT0EeAHRMxuXyQ3AhiiQq2T+8aNcKFCyMaDhZoj29/CNUbBkbo+jq4jhUsvgIHLAio94BAFiCyEI6FdANG6jbtm46XRrFB0KD3WPNeAxyoua8eNBtC+eD076AOYWQrJTup0LgYic74tje/ZPz/66DsYa0O2LSnZLAzkRDy2gCFyai9RnCShi+3XA6aIYU/kJy1CSVpXuT07Gy0RkeDAjToMNFfbE2ZglEUG6195P3LpVLjewAAAAABJRU5ErkJggg==",
    },
    "O45": {
        "description": "domed building",
        "pronunciation": "ipt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAASCAAAAACcZ7q1AAAA40lEQVR4nFXQsUuCcRDG8a/iW7YYubokIk0VRENtDrVENIU4iba1hIESQdBf0NjSkn+ABFJCQ/FCjU4SNIhCiwQlVkOb8jj8zre86fjAPXcc/NXM8tqdJP0j8g9PmrKlqzepf1nYvwnseCjdbwIcmc09S42c60/NfCk/mTDbk4pBcEkAO3rNBpR8FLCt7gS8Xd/dcqETo7TUrncECb0bnX0NDuBQLFRUc3Srsu1d9TUPwLpadks4Ff34AZhtsmUZkevYOQCLvHyahWN8A1BlxckvEcj04hp5GxTkQWiQITT1QVdj0glaohTTKucAAAAASUVORK5CYII=",
    },
    "C8": {
        "description": "ithyphallic god with two plumes, uplifted arm and flagellum",
        "pronunciation": "mnw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABnUlEQVR4nFWPT0iTYRzHP8+zZ73OvctmCtofMp2XhQfDDhKzCIXCNCU6pAidbIcYBEFdRPDexUtCdJJQ8JAnQQmJUBQkK2ZMA5EifHPO4ZtuMmjv02Xvy/odP3y+X35fALiR0QfXiMV9gASg/yy/D2h7NUzpgtNFPSGrl7XVWHJ67Ddb2040/K1uRCIBc8wer1qnuzJA300k8FhtDKWT53oKl4q+RFhC4FlFx51C+oUxk8+noi0C4o/ejmd320fXrpi6Ya8eaj/Nxazh+UGYjTdvDWwoc+yqzZfEu0RTQ+/kjnhYxZmXvz6orqOM1vprhNuLM+B/sgR9Ojt5rwYw/EDtdjsxvXm5NEBCJnefu6BKRF3o/fgzShs+4Trhoffd9ZHQis+dLZPXn1p1nXJVaK/HmVr9c6vakq6jgB9+x7S1lwIWGiM56TUrIGOcShUdXUb2hZHVojzlnKgKA1FG8pvC6vz7nxM8vRhKH5URf1Mgp1J7Hjn/fL0ZcbHguLEHO1offl/TE97Pr0Of7WOzlROPOMc1wUBlcn/eJf8A/N+L9GL/SNkAAAAASUVORK5CYII=",
    },
    "M20": {
        "description": "field of reeds",
        "pronunciation": "sxt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACOklEQVR4nG3STUhUURyG8eccr44fk0lmEjgYShMMmOYklIs2BkFktqqgINq0iAyKNm2CqLDIVoVCy1ApIpBQF2FgGoHQEBouxHKQdGRyvvxoxroz999izp1FdFcP749zFpcD8D12tRIAnklPY75Oyuv2fNUsZZ1BD0DpkGyHGgHUFUmvnwKgbSN0M/sSoOaDczESqgV0r1z/GOlAQ1atDS51lgCOYw9Ptu4ByMqnob0tSoOVmYpOld8FdMn41sjvpwDli9HhZHejhuPeSfqzLUBg/3vGZ9oVVHZ8TkQH6qs0tJaFWbEdoL5mgUTKASoCy79yEUSDnY2yGldAjij2iigQkhBGaRBscl4ABxsptQRy5MBCNGXFts7/AFWNKXyiANA0BHKS3yqOYYoTpjS7dltm8/hQJvcpbbipdtFs1UeSGZOn7bhh4Yu5UgivGyYdNgzT7sZcwoSOfCvwjwL//OPyZqrAXwu8kHM5liiwLnDRv6WxlmNmstLzrmamXdaeo+5Y0uJ1D/t8hpcrR2/lt81Y7/OKfM5ffuPP144esW/r+BhY59ZkyPvCVnBwVmYOnJUgUPww69xJjQJciMrAu4wCDoVk9rEEAfSDbZG3AJxfFUkqgMPTInnGcyNhmM45wzSNigSha6IOdU9GoG6iC87ENxSMPIKGGQnCNfFTVJQaA790o3hlK0iPA5ckaJFikxxOFtbZQsggkEoDG2xZfQGepKC8uY+dXG6Ddt0vVDX3gZ/7yn0+///+Aq187EUmjDzxAAAAAElFTkSuQmCC",
    },
    "X7": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAARCAAAAADMVhJ+AAAAl0lEQVR4nEWNoQoCURREz3tuEZvIgtlkMGyx2YyyoMGmwSoo+B/6Awb/YDG41WZUwSTYxT9YBGUMd3lOmnNnhgumfqFHXPrKVlJawkz3welgPpJGrHIPQItXhksMUq7wbhr0WINs0tURmMsDtNkTdBMhWXbO4Z5IY0uATDkGUX0yZAeAYPPUwupTua//XGpVB0XccPp/4Ac/NDCwLwDHNgAAAABJRU5ErkJggg==",
    },
    "M5": {
        "description": "combination of palm branch and flat loaf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAAwklEQVR4nHXNMQsBYRjA8f/doUgpGSxkkc1kl2KwGq/M1ImRj6As7LfI4ivIYrP6BApJIaVcSuceA3du4J1+z/P86wWAUG0uIgpApNzM7jZ3ADIzp5vg/Ur2Ig6oAEFteXEtrHANZ59Vn/np59da0TslOyKVjwf70dsq5A4Trz+lCl6fH357YhOv5zr+86/yZ++3heXO1alMqwBo9bWIrOsaYDibdqO1dQzQLTMNpE1LV47X/i0AdrQXU+T+CADYofALm8o+jyXxW4kAAAAASUVORK5CYII=",
    },
    "G24": {
        "description": "lapwing with twisted wings",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAZCAAAAAB4egMKAAABQElEQVR4nH2SIVIEMRBF/yI5wSpcuAZyPGIEYqviqEKju1BTOAThCJgcgMNwgMioNpiHyOxMhprlq0zy+vfvrpF6YdrXVf8RunMiXihRXp8SkHahIcFKVdUdbsKBslAuyf9ww1eB58HOE4T5vdKlDcnJ0pBCrhtK8pWLAAxKyGgd116rX/AclBkkiaRQNom876uZKzjb+20+qVgrXm7N9vysaCPnvOutHxuqEhNLRcf9SZ6lWucKOovc1VTIkhLFAE59pzVDhMbJHGLdpl43FqQMadSuAnVtnB38Ahp9GQRTzA7kUTq013f9vL20Ga9vHyTp8XiQpPHu/qiPJ6n9qU1ezKwA7o6/NtvROI8FUHzBJUlT8WmQpBEpwymTQ4AazKzFaT4TlKhTdalExbawmOctLgdpmBwnzCP8p3jz+a1f7i38oLf362IAAAAASUVORK5CYII=",
    },
    "R22": {
        "description": "two narrow belemnites",
        "pronunciation": "xm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAFCAAAAADnWXrpAAAAe0lEQVR4nI2OIQ7CUBAFn8DhUPxDQPJ9DZglIRWc5euK9kDFbJMq9gyFQ4DCoQdREpCMmnGjlIsHX8xx++nwkpPaHphmlwLHcEJSysVjAvpWAE1daSbAZBCfruoGYNFtTuquz1dcHndJGsbDOBwlKa33u+VqK51v+uvrDQbmbYPZCoz7AAAAAElFTkSuQmCC",
    },
    "S7": {
        "description": "blue crown",
        "pronunciation": "xprS",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAAB3klEQVR4nG3TT0jTYRzH8bfbSMG5w8oQClfhrEyC3EHaIQPbUsG6dSgkg6guQURQRGSQ4CUWCCXRwSS6SLgodDTwICEJOZmZq5C2sE2arcWawdjy9+2w0fb78719eD08f77P88D/cg4URERGHBjU3kCm8CG8uJF9dcIAQ/KwZ1+T0zMlqftWDTYuRi9bALB1z8lEtQodoYy7nM7mpg5X6rjcroznJdENQM2VB7W4kjGbaq6Tc8nhLUDHikRb7yhOzT6aZpV1XzPezyLR+ccm3SGuxmUdzycREbcOwS8F06ay4ifyXY8XvSxYLu18Y+ZpTGsHH+2GICIZiesmPv1uofN1uhMRkaAWb8iTxj2pexZERJ6pbddopreWsVwXZBWRQRXun054oeHLjB1OzYpyrcJ23Iq9OACMygWA/r+rW81lDPzq3w4cSafrAarv/owmRtpNQF3LMf+GB6BqSOktjW+bnonLoKn+3JpI0A6AOzdcsZprKe8LiMiqq5jH1lQtaIuI/AjLQKmLeZ/6Wuze683jkW3F8DVs1zaImudvrQBVZ/706JC6l0tWgPbkpB4xD+W7ANukHDJQWpZDDujbnNC+52Id/fax9XhhvsEQoSP+PvXb4KeU6mZ2ua+c/gGf7L+UAlbVGAAAAABJRU5ErkJggg==",
    },
    "N25": {
        "description": "three hills",
        "pronunciation": "xAst",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAQCAAAAABfdVLCAAABBElEQVR4nK3QsUpCURyA8e9KIRg1BM0NPUBPYBBhg0tQEIRBDeKkSxjtTVGD0AM49QIOtQSR+AAFEUU3kmiJApfcGr6G4+2Kiw2d6fDx438Ofxg50dKz9bnROjGf/+5dDqn1nQXKmeMhUpid7NBU62k70vsnPU1LXW1iv6WVpK1oCU50NykVbfXFmIZWB/HOA4BDrwehqg1isQf6FuKiDzMA2a/BA5lXzfIRWFHbAHQtBb+hOYC2FuEzMPJaALZ8zwWWO/MKWNU8KWNbq/t7XZeTn09rZ6pmmP7LaKl6ke5hU9VzEmbI7fj2pja8+LWXx7gTrhpJxLgjmbEmLOZvLPI/p/0AP7ONHZDmUHoAAAAASUVORK5CYII=",
    },
    "S8": {
        "description": "atefcrown",
        "pronunciation": "Atf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAACTUlEQVR4nG2SW0iTYRjH/zvpLOaMVk03iebsYgW5RGVlsMaSgtKKQDQKtCJvhM6BQTGNPFBkJyKwI1Z0uOi0SqiQKUXtYu5bboxyfaE5Y4itRLfPbU8XO+S+/F+9z/vjz/N/n+cF5lJjjC4tmZMAwDOiyecbASEfmB7syUYue7893L3pP5fBRxELmP5MLHR+UovTobge1bX1gUXKnaMrYiXbeVbRBSpSU0IDa3h9BYt//pInztNn3vO8G6KWZUPRD8f8MXLq+Jl0w8xKGzUBil66XVOSxqSN3+2rD0VbAOR/pAHX6MFZUNNDXbn7nDVCAOvoel4h4/kHC76x2wRabwUASN8xS8WtE/tTsHCQ1UHypE0IAFlcJ05QS2oYWoe9DOIOW/yF5qk62Ge2pHp6qA6wsKXxst85b/20ryg5IivdEsDoMSZq1xu0UlvSmusJmWH40pxopPhai0dhc3KDwaBIr7xqbY/EaYPKJVow5Ugl3hoZ6WOlKD9rArDcy4g3T3YCQGYc+2hYJ+kIeccrRdhL5dgxUwVA2NSszwDgxw23+ei5CuZKAVTgIGO9ANDgZ/tevnj6x6HBw5sZKAmuVQ4FVKI7ryUAxNfe5h035ADuqfy8ifmcIBJVaM4LTu86EkmFqu6yDhIRPd7dS6sOEEdMdz4ACFKjrNIqjTkATlUW/7445pZny+5NzNqgMLv45DRRiCh8dzQ4yV3OQrrKxl75iYJDP0Ih7rMaSP+xWZxVpvQe7pGbRBLbCM8K47gj0Knn3yZVGoh2ZMyq/wLlNOq+Lgx8cQAAAABJRU5ErkJggg==",
    },
    "G47": {
        "description": "duckling",
        "pronunciation": "TA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAACFElEQVR4nF2QXUiTARSGn8+t4WR+XkzKUrHQajSlNEmMXZQUJlRkkKwCL2oREf2gJTW6SO0iaYGBWiFEoEVYYYhkaVJGGER0IRn5MzV1kLbKnKbTbacLG5s7V+85z/l5OQqGXO3CoqWy2d7PstAieYe8/pVRe3S2yeWIKKtXpMUnciYCkNDklSbj+Us9P9RIZP4mgdsHUmskkhi7pidEZKDniW5ZXSE2HV+87rqJoseR2wBU9/eRjZGuAWhQe13jAGyJcfeHkcxt1aNHNLBqf3ZB3Ojznkf+4OQN0Z+th4TWgIjIZIESBLlzdVx8nWLtm69XK6Q3L3TsmFgoFqeMWVcYPjxMDLNR7slgzd2JZztQ7A/04QbtP00Qk6aCyXMyHGhuTW0KygsjJ6JDJHH+qTGo49rEEUJmsYXa0u3+9p3BpLI7Nnx5ScBTowGg0FvLhlQAjFnrAHOb3EkBjB/dOQWuoeMGoNrnzAair8iX7ZA57K7qq6oTh47NgyWFyQDsutcNWU6ZOqpoShcd2vxPccFjxQtgdsrBpa9ezRg49R+oLz6DvqUTgOjWuZtfh3KW9P1ZG7A2YakvbVb88jI5X4G90qgHUMs6u940Hi7y/JkRz/Dfy+ZaX0cSsPXcW5FpERH/u14RkekxeZUElI/ITHvZ7opBEQnM+UVEfpeuBvANN1jiFVh/7f2iy7avuevX+GkA/gFMhN2sq+N6CwAAAABJRU5ErkJggg==",
    },
    "I1": {
        "description": "gecko",
        "pronunciation": "aSA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACGklEQVR4nH2SS2gTURSG/0nSzqQhNdZKg49RLA1NqlbRUFTEYsAKPgKxKojiRt1JF5UKXYgggt3Y4MYHVBB0U5WCDxBXWSjBgtBqa00iaZI2bUgbpjFPZjI5LmZSIzXzr+7hfPfc8597AEWWKVq4ZkRt1S1RaeacQQNIE9HiCf2ahK5yKHz3x6xuIwDoqrFKUfnGhM7LCyIAHOgtgMmPzeYqkLkBAJq9uYwHAHBGIiIaf9iqVGi87oLPJ/J9BxELwFACIiE7AKdTGATA9LudBWFTrmxqQEL6kTEnvHnT8BGgRMtLV8cBJsoL/e+2SbKBlZO6Oug3y7fs61nQ0BNZt5wF4PHL6eR0d/t2hlENN7VcmJVp3lGx0TKazv5eISk9ddzabG7UAwBzfo4ie1etbnHuPPQ1R0QUnQgP7Oqw2TYCY/Sa+2difVkiosXJ4K8Fos+X3a1vxEGuMihuh5GPC6bot+LIF2Op6xVbPmUNXHp+h32QUm7b3/8kok/HlGh3hG52D9DQvo/Uo5bvChNRvFONTMO0IhRnQiOHYx71s4IpAIFJFcjdf7rOwpbv2s7ObQAU8xftUr3/7WrDTc9OItN59FExdHpeHQ7HctV/3PZYfqHnfZS0oYY4lwPMbco7agEAgCsi9fzdqP9o9AMsa3ewWveK4a2awP4gdWg9AVFCWROIp1DSBFJZtGv2AFfiJaNN+Oq189gz/Qd+EtVnsYVaCAAAAABJRU5ErkJggg==",
    },
    "I12": {
        "description": "erect cobra",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABZElEQVR4nFXPTyiDcRgH8O/7vhvL1tiSWpnYaKRpGLLsMjfCgRNn5TLtIuXC3YFyUFwYB2UmLhMbpcVBFrJa/rTsokxbJhtb7/s42G+b5/b91NP3eTB6JSXeM9EesCHasvdOvd135TM3Pah44tQOzdHYV54qXUTBB1EaKCyt0bogOBMbLBufX5sAHOz/RR4W/fEjUFd/x6BWfgDAaAgykCMAoD95y6CMAKiHd+MM+EgWcCrdxEBISTDPnkXypbygJ5LPSMs/DGrasjn7kDvKzuIram7IUbXHHgFskkMX91cUMs9xoqp6J10EQBJS1yiFAUHti8Viwe12GQCeQwethMLhcKr5chUAZwloz09yWYjUOq4Y8UH2mUytwjRBpnIAcxcf0HjEU4uhs8Nm627wp/vAQTdfByJQY/PS4WLIVexrmdyMm5NWrijQhrwqL18CCU9nxorSUX7Tyz+QbRD9A2gXvn4B5N1/FxnbtiwAAAAASUVORK5CYII=",
    },
    "D24": {
        "description": "upper lip with teeth",
        "pronunciation": "spt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAICAAAAACw8NI0AAAAkklEQVR4nG3OsQ2DQBBE0SF1CUREbuPkCohdANVQA7GlCWnAcrJFWFcD2Tn9DjgQRp5kN3ia3UaHpOvtXtfH8/3Sn6QhOCWGdDJjBgjsBRtsAiCPu2wngDBJRaJIIBUlHABTKynNa42MVAl1tdbSOQmIvsNykZYfVizT9QHUw2CKjQ05g41d8AaayrZHP5fj2MEXRoqGGWWDzXYAAAAASUVORK5CYII=",
    },
    "G52": {
        "description": "goose picking up grain",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAWCAAAAACJLLHfAAABuElEQVR4nG2ST0iTcRjHv07XhJYkmQXipoJI2kCmBynooJ5nBls3ESTwKBQMxBi77KBEHiQQvXoQGmiODrmTHkWkGEUKWsmYf2iTMpkT9umw7d3eF7+n5/vw+f2eh+d5pLLauj1LQKSru9Mus6qMqO7xs5bzQad0nLCfLXCydS0Wmrgt6f2GI98+ZpekyTc5WdU/B0tpYgVXH90E/jZYKR9czChGk5GZAP68G6qupJ4CXD7/Tqgi6VkDfo/cMhJPMDQbrHweAxgoGtsi8HlmH4A08eBNgwslgNcuSVIYOJL0CK6k2dMDIB7s9fZ4O++714Ev7nrpzj/AL0l9MCpJD4KfMGtTzlGAwtS9kGoslGuMr2XL2Iqm9kiyUexlFZiruSvJIbW5pkvYK+XY9rBS6jkKQGY5ZS46X2OX23c5XMIyks4zzQGpd8epfB5J0g2nADLGBOp+gV8aB7d5T7BOumy3iEpKciYr9oOk4Wyn9EuCXQuWBcKGewsdksBnpmwv4pW32SXlJJeyHyy/PVzl571i7P8IRFT7DSIWzBHgpaThi1TqoDCk5AmQsGAKJBqk1q+WLR52mKD/CMIsEj3psgYAAAAASUVORK5CYII=",
    },
    "F1": {
        "description": "ox head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAA9klEQVR4nD3OvUuVAQCF8d/1vYpommLoIC6CziIIwYV4UWgxWvwLFCnDqTUENxUH0VWIFvdwKC4OOgXi5t1yKBtdDKPBrzoOXn228/AMB+9nn2lSKdcLLQyuvhluqtG1/n/wOvmz0A9TV6mBopEkc+wmO818PEnS+JxkTPc8WM4D5VGuq/ALv68HcEArVH8kXws7+0mS71AmE2AjydIgfEnt7fkwuk4yB0ZyJh/Bp5Rg67xPvfkn0zB5+4T2B/WKFk+Lv1zem2VQ29v2yOXPXpzmZOh+Py+P8wHV+sxIY6WjUnS2LaIHla6X7160cvPt4n/cbB5yB/H5Z0hm/uk2AAAAAElFTkSuQmCC",
    },
    "N23": {
        "description": "irrigation canal",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAALCAAAAABaYvKfAAAARElEQVR4nGP8z4AJmLCIMTAwMPj+/++LymBgYGCY938eGgOP0v1oDAYGBt//H3xRGSiGzUUyNQDVVMYv3Bhu/MqIzUcAtM4mQIHwGC8AAAAASUVORK5CYII=",
    },
    "G14": {
        "description": "vulture",
        "pronunciation": "mwt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAAB7klEQVR4nGNgYE399f//A1dmBkzAWv7w26EXN185Y5GLf/a/PuzjtP+Tscg9+P9/m46q6r81e+8tkUSTO3TgwPdlvHzff1xb/vOcOobWjP+xLFcPiTO0/9/Njy7HdCCTISyWgYGv7/8sPnTJzFtSDDKyTAwsHZ9d0eVcv61PfvqJm4GBY9kRNTQ55oyD/9/FMzIwMPBvOG2IrjPgUyqEofPucTSanOi/DCjL9vO/IFQ5gZ8tMKbLs9/2KHIcx24pw9jeb66JIMsxhv53gHP8/3cwMDAwMDBBuP/fM5jC5TYedEMJWa17xyXgHN//2Sg29v5vhrO599wXQ5jJwPCFIU4Vxv66SsEDWY71KY89nHPrSx8nkhzTksk5ojDOmR7+BnaEfTVLFV/mMvCbsDEwMDAwsJ/+08QBl8v9zlfyQ0riaJcQMwMDA4PX1bfacDN/c8z88DeG90vp5X5DcQaGbf2MKYwwufwJfy8qPtznfpvL9cXlNT+OfZ9hAjez6W746///P//UE/K48//v55uXXv+HSUkc6mFwfPt3azUPAwN33u/6+v//3zIwMDDw8HBKr/u/Kyrn4a8KCQYGBgammr/lRd82MzAweG7duvHofyg4PqNVioGBs/H3sh8nGBg0Lv9HBQeVGBjY2s7u3wgArtLLY5KkddoAAAAASUVORK5CYII=",
    },
    "A53": {
        "description": "standing mummy",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAABBUlEQVR4nC3JzyuDcRzA8ff346FFPcyS4XGi7LhI3BykHSj5cXPksIOrk3/ASZLLan+Ig4tsSlJam4lYmppSW8tss+35fhy226tegNl7rlUSnoHtRP58cq0BkSf9TA56RcxZJ36iSbnHy3wESMcCD1K/mbrYGouFLMRVK351My2R48udkaOqqzL6ctj8u2u1kNvVt4l0ITzdETBLr6X8/JCAzH5pYT3rAKqkZF8AtWR9RwAj+HNhARBcd0DAZoJEyzUBvXbNSu5bgN9wMFr0BWjPhHIWAcp2uG4Q4Kdv3Hal0lYQAJSerDVdWUxvA/3S3cVT867gHCxseFfL0UdoqmqjVN/lH/JCZXAjQUxUAAAAAElFTkSuQmCC",
    },
    "D60": {
        "description": "foot under vase from which water flows",
        "pronunciation": "wab",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABqklEQVR4nGXQP2uTURTH8e89uc+TpjakGUJtJQpWg5PYaovawUHEocRuGhFE0UUKRdFFHPQdFF9BQUqKg+CgGMVqQfwDajF2yNBBY42BBIwBE0lCchzSxz6Ys9x7Pvy4h3vAV0Ope99UP14N201wT6xWLpw/Usz8CqXmY17MWVp5qsXZCWBmvezpvmzhyfhI935Du2fselOviZdIVQ1AbGEa8plCabEGRDLbDTCQTm5cPn2JT4ls7ntA90/fBTiq9eMk74yGEy9UVXV5DxB8uJHcfFGyPz90crsArrRnvTkm/XyyNA/C6Fx+0VN979pGDsQc2Pmu+u/Pr2pBHJDAyf5nW5swAQMg1s2/5v+SgxOlYq9GwkZ61dhHtV4VZ7Xt601XEdePbQwgqPpU3/5wAFE1Pm01jBiwrU7ApzOhoVYW5OLgH58mQn2dMsiZTn0L4+OVlgyC8LXgmXNuqfzgczMOQnzY07mFqTdroeAIWLb1AdAfPXurmr5PJDoJFhTYfWrqWGP55jpUfg+ABdhx+9BYbmXty3Ac3EwYLPVm9OVeiI0dthbQ9mP4C/L2h8+2PVRwAAAAAElFTkSuQmCC",
    },
    "M42": {
        "description": "flower",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAAAAADhgtq/AAAAtklEQVR4nH2SsQ3CMBBFH3QpIrEAG7hJkRVoIxqKtCnpsgzNZQGPwBLewSxgHS3S0ZEEXfI7++v5n84fZokJrjrrrXMdyWQfUkF0Ph79l9dOSaTiMw2tj6uifk6sxzq6TDCzsLzoRDVnlYCYEERzVpUrBxleT1Jzq5kGmAbeMTVczhPWA1SMZoaZjUAFve0wq5zHImdvtp/E7hsftL2DEonFdUgkXOfU0J58Bj7uADs92O7OX9++jFZr788CZSkAAAAASUVORK5CYII=",
    },
    "D46": {
        "description": "hand",
        "pronunciation": "d",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAAeklEQVR4nIWP0QkDMQxDX0oHKrgz6WbyjVQS6EbuR5ociQt9XzbIsgQDxYVYKVPktDEbtPP1JqGIOpfaHasem5e8PZcrGdP8AHkkBKA69yLTFejLlslFzY12PG5wnH9UcAfnp8xs/LCe0ZNk6eIqvXOiLSUKoBx/a/kBHl5jibvXhSIAAAAASUVORK5CYII=",
    },
    "A54": {
        "description": "lying mummy",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAA8klEQVR4nHWOoU7DUABFz0ueKGqmZGFDMgQPg1nCB5BM4SZKHWFYvmB8AsFDl1SA6BRgluCbzC4Mg6bIyVfxkosYJIOkV997zoXfxDQmE4C7jqFQp7FWCbiRVEhqxDmJzlyaS3pudpaSKY8Z3SePmLhN2gXg82G52bq4AyT1oZSXJO/9ynsvyVd5njigcytJaKgydplUZf3eet5yLskLvx5KPslkdPgGwP7H/0ut3bRLsGFcVRhtL7YuKQCYMJtC3E73Tl5974g6gjpa7fBi9HU1heHABs4B6jqKfnATS8AGbBib06dN0dniYGDD7H351883A4N25+1ZfWQAAAAASUVORK5CYII=",
    },
    "E6": {
        "description": "horse",
        "pronunciation": "zzmt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACWUlEQVR4nHWSWUiUYRSGn38aTUR06sItCpxiGiy01YXCsNKLUouI0KILky40yzJBDLrJpA1aCNuggoRQlIgmyikry6AyWyZLTdNcbsZJp5lkcsn5Txe/OoF27t7vOe85h3M+BYCsldVdTi/TQw+AHFj3zvn0rXuGBABzi4jHW5PwH7cSxJ3qjCz7G5nBq9vZJUO5VuOJl2EzlY7rF1FH1Ig0NWeaE4g3gDJ7cNCj6GbCXn9goGhMYVprPWDpVXITC26zYDrWIrj9PJAv2VMvfr7ikLKwCVBRJ2Dosc49JlPoZG6WbT5QIFU6wLCp8Kv8FJH3+WZtLQF9fUDbwI7Bek9Y+taeV1VNptSU2It1mjv7AYB/jktG3CInzf5AvFx6rk6cRADGbj5ZHKXrbe1RzJ8F53DNeJKG/0TOdQJqdzcAu8ObYY7tWZ5dm9yxbH8As6ZWtQ0goTnE2KnhbvYt4ULeRgMAkdEeCIwp37XUquWfEqldK/Lj9fFDG+Do70xIa9TflXgAikdFxCmtFffuexyNL9zeeiOPKgxWWQ2w3CEiMnQ9VKfzSy5sdIuI5aDrnKFW4gD9mXERqcuYnCy1QcZF5FrIQ4kDIj6KSEO470BRtrZcq9gCLZKggy2L+hi7Zffh71775WaU4U73Lx0hm12l44z+c969xitz1lAjrrJ2iO34kKl+ifHRJGctKY7Heu0XH5aiZKn00fU9kqjcGE2fmMPSG10up6eoqVNKyOy/6q/J7f1n9faWeZM0qFKKMTnsqyb0t0+p4R2lk1QpGTzix4r6smBN/wVFOQEEefH3qgAAAABJRU5ErkJggg==",
    },
    "O26": {
        "description": "stela",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAAA0klEQVR4nO3OvwqCUBQG8O/ca1AgRENN4hIYLa3RA/QIBTX4QK69QUvQ4mtIiGuIU9AUiCWB9kdt8OoNamruW+75fsO5ByjTX4XxPVz1RaXyGa7VzQm9xdXcQ2bpWwYAGJa/lKp5dqucWran1WwGejXqgQkADACbuOeKz+6ECVanTlxx7ExVwbzL5D+sywUjezuqLAxf8+f3EP22JKGHhDsSALTlTBkfjjVr+u6ZZ1REF6QNXnP2aKLdQTL/3DxPFZqNxGUVFhhcKBc1j8RQKG3cXipHOQsTKbXPAAAAAElFTkSuQmCC",
    },
    "D40": {
        "description": "forearm with stick",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAAoklEQVR4nIXQsQpBcRiG8YftjGa7s5PVLOUKyOQCTpmUyWRXtjOQxX5uQTYpg8WiZFDKohT1WIznzzv/evr6AIwJLs40jQFchFVDvUwBPIdVppn+Uzf7HATYOAoqJ5BYbNbKK+rh2B4ieKraC7Y6MLQ42ALMZ9VwDih1VfX9Xo5z/nZLIRH4stw9NGUqQHv9w6keCwBxp1W77k6vSnTPvWr9AUypgBPmsGTAAAAAAElFTkSuQmCC",
    },
    "M36": {
        "description": "bundle of flax",
        "pronunciation": "Dr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAASCAAAAAB+u6HMAAAAkklEQVR4nHWQsQ3CUAxEXxBLUHqVsMWfg+5TUiZjmC2cERghjOAy5VEEkUQJrznp6U6WjEmq0lTnAIAqc7npGxWAIs9XeuYcViKgaE12kmhs5M6PB/2lNBBaHFKqA0JbHBrQMPyabQv9DVAs85B3KoB8LWWZgGstJ7fC9nyoCk4csJPP4UC+r3/mZ4DY+82fRoAPocl7GURYH9kAAAAASUVORK5CYII=",
    },
    "Y3": {
        "description": "scribe's equipment",
        "pronunciation": "zS",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAeCAAAAAATRYE5AAACCElEQVR4nG3RXUiTYRTA8f/77t3mNnJuI8UQQqsLpSAKCvq6qCRLSSHKQdSFNYyF3RWJdeG6ij6MKGEmhje5iEExiLQoCU1stlreKCnRCFluytZazX28bxevrA93bp7D+T2c5/AcAQDK1+ij8W9qrjn+aziiptS+T8+G/XvUO2ciyg2bWt8S9tZVH30YPQTsH493jsyPdABI7vFSwNAVtMGLVy7Hhw6PAmCZvgzA7mQN2EcPTA+2ZHsAyhacAGwKbQUcz5yWkNsIUJVqAEDrdQP0D3hfr0IChKWfAGR+bAC47S3enEACEAR1OjED8M6vC4FIgRAoCIKQLQD6UvtEfZ3jf8jpOsfszwOGIyooKGpd0V06/7Tpmp4JQG80bkzWG41FAvQP5q7rbk2lfcXA50gsnvoeW1zcBfezd61vEo0DVwHJ1j2TSmsMlgtmIHnRW93y5IQIiLpgb2xHSZ9HUawHK0Pd21sfqe9Jitzgaju3tlcRfDXyUnNuZnlAEXl1yWi8SkB+maqtGA58zYMUmLpS9lgWqPg0J4/ZTHnQBs/6XQ8EpL09Ye6Z1v9pZTh1s71cQY6erixqM8eXQSJ9uF1cN99F7tiQ78s+59s8oBHVY7apUdPnJQ/aIU9z8I4MTE7+9Z8iYuSkdefHFXuRyJCJQWoF5LaZAMz/rBCQEq0aAJlEHhbmgN9MRLepjfhSHAAAAABJRU5ErkJggg==",
    },
    "D54": {
        "description": "legs walking",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAASCAAAAAB6TnHxAAAA10lEQVR4nGXOIUsDARjG8f+4WxBdMhgsBvtAZMGF07JkMSkDi99jmBaWLi5oH2PMcBgELYKfYOA0CH6EKSKIiv+F3W13800PP16e94X8xHY3+TdbI1/j9WXd+VZ9KC9xT1Vvirr66c/1n06qBb7TJodqJ6+BfqzAQF8qOT7XBlB+1uZC1768B6Clw0Lz7NSuJgvWcZoefZ9rX6M0RnqSxks129jXJATg6giOMy5l4UI9nfdVNQn3GgdBHRgAsH0WvW3MPlC1ndWqaffTOOgDENaSXyhNbpkCenZsipOx6ysAAAAASUVORK5CYII=",
    },
    "N21": {
        "description": "short tongue of land",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAALCAAAAACvnHkvAAAAxUlEQVR4nFWNvwsBARzF3ylyUgaDgRVFynhlsNiv/ANntJlMBpLNIBODxGKVYr5FBiaRzoAbmEVRfj7D+XWf5fXt83pfweGJ1+xACxdts3suT/ggZMKx0PeatrC9zdaGIbScExa7eI8kbw8vADTFycA2B9nAD7lcp8EVHY2rvBf/BOT6iASsXXKvKpJJYkwA8PdJ0izTNFJSVJ08DtsJ8W0q/JYckqKeyUOpKvuALBemcUlRjyTZKZI9wfwYfncw5YoK0AsvB8tXCn443gIAAAAASUVORK5CYII=",
    },
    "S25": {
        "description": "garment with ties",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAAAAACzJtCvAAABA0lEQVR4nHWTzWkDMRCFP5tcfHMB6mBhL4H0My24ArM9uAC3YPB90kDSgcEV7K4J5ODDy2F/JEvKnPRmPvTeCAQAmKtabiT1H/XC7TpJolKS1O1m0es+yGqYPR939cAWDvvx+F2DgLev42N/AOCmEyavUS7jpBtAJ0GQQklNXakDBl0BHyrh7NeBi0Zop/RVV59HPw0mtdP9JTYlaSTjOs+9DBdmB+lCP5+tfLml5RpZHjaU4RYD08gUDSjDLZ1GilMvMV/57do8k+0QOJc3E/IdbN09NSXfIaaQNmKziPWUaxGz4bQp1fAZxTadvKfiIxUJ9mqZVVzB8u9iCROxkGMhYn8YYeLTm5ClBAAAAABJRU5ErkJggg==",
    },
    "Aa18": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAdCAAAAAB6E5ipAAAAuklEQVR4nK2QoQ7CMBRFT2mTYdFLCB+DH2r8Zqf3EygsiGIwwyAgGRexjKxdMYTnek/ufbcPkqkVbiEVByDvlQMHQZZ41aBMWh0EkgdwKdSFZgewiPUHlANI11wV6lxlH6TN+IjTSvbnnCVIkyhzXFsLwKsAno/loPcnoyZnh8pBriQ+/c9kHMDsgmYkJLuqjyfZ5YHZ3SbzX+KghT7Setp7gaOCzkbEdlvAGUCJZ2V+bwBYPycGvlz0DYQLPh3bIzghAAAAAElFTkSuQmCC",
    },
    "P1": {
        "description": "boat",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACoAAAAWCAAAAACTEFFRAAABgklEQVR4nI2SP0jUYRjHP7/jlAIlIoIIbygbWorXoBwaIgKXBiGIEm4LcqtoqeFmhyAoWm6SRlESfkdTUEgNIkLJoSAUdgUmGHhg9kfh+DS83nnIedx3+vI+n+f78j7PCwcr+3bpQleberOeW+qQBA2doqXO2R4tdhr7Se/UfaY9OgIX6z45gLkyUPuwAAgDC+3CDj9W7QWKupjA4OCl1hMONR0P8fHq769baktwWt+f44gBCM5vqOpNFifDsWZwSrUAXDbA0aqVP6pWr6Lq7HjYJWf8Voh+xwwn1ZrqRB8JSzG+6qN4n6djzxOnOPvXrZBb1zkAjuet6/PHnpfej+Qz9YezOXKbrjV2dmL0Vx3e1Ok0TdM0VR/kob+sL7JFfdMX4d7z8+7Tl3wGmNFygGvq08a2uobuDh2KIxjbPXp4q5sSMAyvr8O9vSk1Apcr39c3/kX/s7IqUFDLzWjLza0J9KvufZeVU6x0A8SWWHD7DAlw41VTd3b/wxoCSG6/2/kPxvcOws8qjpgAAAAASUVORK5CYII=",
    },
    "N11": {
        "description": "crescent moon",
        "pronunciation": "iaH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAABBElEQVR4nHWQsUrDYBSFj4tIHMSh0Ekogi4ZEgdXfQRRiEMlIMGpz1DlR8igfQQR6VQzSUdx+EWcdJRMyg9SKA7GoZOLn0MVm7ae6XLud7nnXmlU1cQCgE2qpcbMSB1vbi3qVq9a0oY+rmxbk6plA4r9ehhKUhDEScEgq41TBjor44NgSk74wN2OpPW9tOecc32TBJIiy2PwR/nQkZZPuvD57JxzDui2alIG/i/l5RxIKfQOw4UfK2j2wUgJuTe01t45rd98YcO5UpLAwnXcohjuveD+Et52J6+PCsgsbUmVBgDH81OeJM8A0Kjo6AlIV6dBkuQbIG8KXs62Z/+jJEXnDr4BuJGEMQaLUeMAAAAASUVORK5CYII=",
    },
    "H8": {
        "description": "egg",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAASCAAAAACh9dvTAAAAqElEQVR4nD2PIRLCUAxEt5WI4rG1PUJNDeKLGmbCcTD1nekZYmAG8yUGUTymVwBRFQx2ET+fmM2+STKbApB+g9tjQapK1EiquJeZ6zgZ6UDJAIRnBq6BlhrGxJu0UvoZLO0H5w4gBycNqTXUXo2DE03KiN3B/fWNHrWSeWAggY60nC2yxP2IreUJj2gMACAkXJ8BCKQiA5vGlfP/SyVpKlWRw7V7fOMFP2tyXKGHx6s4AAAAAElFTkSuQmCC",
    },
    "Aa17": {
        "pronunciation": "sA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAASCAAAAAB6TnHxAAAAfElEQVR4nI2OMQ7CUAxDX/u/VKnqdeAoOWfO0aljF7ZMTEh0AQFmqBggf8CLlSfLMXzLFJfgVya5K9FFkLHLQKkkBJJnrMjUTmpk8bMiUwulEWDepH9kO13H8jluw+7PUlnZJl73B5ShB2CbDhWOqXCmz18AKswN3DVGAW+q1Dzt8lnBZwAAAABJRU5ErkJggg==",
    },
    "I3": {
        "description": "crocodile",
        "pronunciation": "mzH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACkAAAAMCAAAAADaasuvAAABDElEQVR4nIWQvyvEYRzH3zcY6BjcQFEmZbi6QeRJKMVqUjIoZTDIZJAo9/wFLpNnsHAesdxgUJfNz4k7u/KrHsroblEvgzt976R7T59evfp83n0EQOml4ONqENzkgiuUAN/AtCGMxhN9EmW8N/+LsSZz9CWppV1E8NvO6dUfU3pWRzElSTLLFTzSpYfzrdv6vcNZ2JDkImxsFTi0A/VunuK2gBrYeQDk0t01sG0PAFfpugYSu5IEZOZbo27vJWAczjlneUIGuF6UpvOB9+O5ZHOkWRZDNaqOK5LGN4F09fz6DQD7RrJgLZAZTM6e8PkaQgDKsR/Tzzz2fCSW7i70+9aJMySlhuifkuTvvwGnE5gQ/2OQgQAAAABJRU5ErkJggg==",
    },
    "N15": {
        "description": "star in circle",
        "pronunciation": "dwAt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAAAAACMIRMSAAABiklEQVR4nF2Sv2tTURiGn2YwSCAK3YooBYlLJOjiUApa7SylpGDJ4lJEznLF/hWNS0d/0EUi2EG0xDooKA6NIthBYutYeuG6KF6lgsE+DvcmsX239zwH3u9874FMxWq9pdqqn+OQ5tumqqntxgEwsa7Gf9VYbU8MybT69AQojLXV6T6Z0s9zkCGodwdsSrdHGCLYytkZ7WZkgOhqBUYjneUQqms0ynKsNg+iJTVeZl97+nXmvzESVUWfnVd9N56hSke11lb0Biyq7uxqHKtGsKBoBBy57kALAJEWsuA/K8fv7ABsN4/dzccsQA+AH7dXAdYWUwB6UNjnSnYpVFl7ztmQuctA+PQ9M7/15Jj9pyXdQO2lVwEea4CgT7J1vKhRuukmcE3fA2xoA+gYynB00xVKW3opr65bpmWnDDDvXvjotzw/JHZCav4LmiZ6v1/sA01cys3pPf0VqpmphVTTCjACMB5uwYdXu6+5eGryAjTvfWGgxpvhDjfynLx6inOzxckSP9/y6GF+9A/2vAp3+VXkIgAAAABJRU5ErkJggg==",
    },
    "D56": {
        "description": "leg",
        "pronunciation": "sbq",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABOklEQVR4nD3OSyhEYRQH8P/33TvGpBnchWEYRYOU2QxFFl5lKUWhzCQba9koStlJ2alJjZJYWFgqj8WIWYiVjUeSR+PRGHNTmty5986x+b773/06/3M6gExfTp/3OqpNGNZnXMp1SCfrOUOIxeh8eOD1QE4zj5GqPYoJ9ZtLmMjvVwrevJT5dmlGaNnswJAR9wmmfln12XUzwAEAJcdU0WpC0gzVmIbCJFk4+ratkGTSmvxLBYKSqz/13gx6FfnUlt6prj01SHbTKRaoS5TxnnfjzlQlnzdcSH/LU8BmXdhCuUPdH80XBt2SDJptB1TJQla1ySRJrpFlM2fXzzm4w8YEvvS0bQMAlNErOmrDymUIAJ/eoYu5EDBLU2p7ZKTndiyZBdBS9LB7T7D48cBdAG/SxkFERRJZLP0Hy2x2y4T/CUkAAAAASUVORK5CYII=",
    },
    "A32": {
        "description": "man dancing with arms to the back",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABiElEQVR4nFWOO0hbARSGP2+u72i0OEiLCrEV8ZlSH0VwKBpqh06C6aS2INgOjkJQ0E0sSKFb1EVEEUqGFIeOFiOSIkKV0PqgxNiqwRA1Eq7eSo7DlRvzb//Hx38OADh3Dg62mwFmBYDW8HVfpXe3AjLmBODRz/ONHy7rYR9Y5kUBnjT4Fc/4VzUG9qdJgNKjdQ9DspcLTadxBTj5WLfJX31bg/KSLRXs7mfWNo89q/4LSg2HWNyXIu58XhyLiHa2VqfWjoRDr7L/c6ZHFkIrx1FwBR6WSXzp/eBNPwCo3RnvuihwhSMWn0H4rF2J/Hljm0oW3DmjGzlNA3599rUmmHngFwlu6pVGU4DYN4ady5lFKacssWpjQhwppzPPd5H/OBk1FcuveAeN59+zTKeneuu37aVtUTcdr8TCItKF6ZxSnJzxkkiRyQC5vj3up/DDpXYlvWmsJSAynUaoikqsOh2NifjyzJ8B/oHTuK8aIPPtrpVgitQ7nrd9aikPmRul+wkJtq8tG+0WQFWXD2hkPaMAAAAASUVORK5CYII=",
    },
    "S2": {
        "description": "combination of white crown and basket",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABoklEQVR4nHWSXShkYRjH/8c5g8kclpEZ24yPbJpRSMQ2uJg7CW1xS5QwVxtKpLgkl1KUxFzggnKJRG1IknyuuUE+a5TFatr1dc7jYs4ck/Oe5+rf/9fzf5/3eV9AW6m+QyvDVoofIErRxxl0dWdTdIQW9+K/Ub+5+O9su2TTpX6yeHTPjvJSvTC9ZGJTYURe5LMCwzwbN9CmAzXUzTGp63QlE5HzVMmkRRfkBkQ/VbBo7tXzTw4QH1ZZ9xL3qBcAxH99qhe2tfacX2MAAGKsEqW39yUAgFipXzWFkOBc5rY1AIAUQdpwS9XBRFA5wyLVbmdB3X1QdeBjKWp3PHetqK/0op1seVARxh1/3ke4hwMAinPLzTwAis53vNUWBp+EXjj6HBNekvC01fTIAaDQPARltNdi7xk6qUun1TIutyBt/bGMSROXaeoLkL59Ux2ppeYZWkgGAPvu09w3wyfo+S17lQ+X1HPsHy1NMMYAAAymaFvrBl12iwgNmV1eY/cFpLlzgyz8SJGsdt/k/hZUDCR9b7Q55QBPnPn56HDo5E/QfgczxoHj1duLAQAAAABJRU5ErkJggg==",
    },
    "X8": {
        "description": "cone-shapedbread",
        "pronunciation": "rdi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABb0lEQVR4nFXPT0vCcADG8ef3a6mZ4DQPy42k/MNQiwbNhi4KPPgCeie9lo69CA92VMjlJQVRjFIimYepIOSfFWWlHVxmz+n7OT4AAODi42IRFADgSK2lHCveidajOyvmt+62+D+TQ1/Jd0iW3jx9unk63Vya3a0Oq7vs0ny8PqnH+aUz0/w8P838mom3eui14oxlu6IPMNAVu2VVKJgwC4JqWXq5B3D/IlmWxzoAfSwvLgWMLAMbmKwRACgQ3dC+7EX7l7YRBSggOh4hCzIeHSJA4TwblRBxR1AanTlBwUe0ITlyHZGhFuFBsc3V4FcMxY8atw1KEmwRgu/WJ6DIJgh1JpsNBLkqF0SjmXRSV7jxtp42r830+lsj7KKhWOXdI5aNsuh5r8RCNDPR4BUfxg+iF9okQ/c7Xaje/Gfeq6Lb2acnz31y3G6i2T4m/ecT6s69zqVWG+2WNH/NuZnZuWQ70C+/14KBq+nejMzxbz8SuH2SxdwfmwAAAABJRU5ErkJggg==",
    },
    "S32": {
        "description": "cloth with fringe on the side",
        "pronunciation": "siA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAAU0lEQVR4nKXRMQqAQAxE0R8QxMbOA+Zie7/1ApZjscpW7gibaoowD5IAhJ0AEijX5pdBddApLa+5OjQBSvM/2no6DZotHgZVj/PoY7IPrxw/XgDcFrQZqLCcVrcAAAAASUVORK5CYII=",
    },
    "V26": {
        "pronunciation": "aD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAJCAAAAAB7rAGRAAAA3UlEQVR4nGNggAGLrbv/o4DdWy3gkowMDP4MTM9P+JvHiHIwoIIfr5ec3Ggj8I9pCwNjUoMsAwPDNS0GBoYf6z5/uvSZ6TMD7x9+PV7OcA6YxMtyhryjS6/+//////elZmiGMRgu/f73////15cczWNgYGBgyHv0/38euiIGBgaG1P//n6UzMDAwMEaKfvn+PDWK4ce6iafQTSsJ4mBYNV2Si+0H41YvhPiyD5/uf/n97T/Lf349Xr4ghJe2MFrEOmhd287wiyFSAotPmVh/B6jf3LMaIWixdSvucAMAfoJvkhPvUycAAAAASUVORK5CYII=",
    },
    "G44": {
        "description": "two quail chicks",
        "pronunciation": "ww",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAACXUlEQVR4nFXRXUiTYRQH8P/efanzI3HqXE4FzdKLNIuJFBQZeaGmURFGoVAXVmYWFZqRmpQQ0o0aXYiIaUY6IbxSA1cMbQ1lYUyTdJpzpmtrarb5One6mNs7n7uH33MOz/kfAECy8vAeZLKr64Yo7D63xmbmapT23rwL5qEIfxDfo9rU04afPxJy9uaulfhJko4+MJXyaseyoEKJziEhR4KbXxbiSmVMj2E0Brjtkvp3DO7TxwKNvXQHKNqsF/lbGp0DrpLrChDa7G5gvP0AuDZtCFAlPApBaXqV8IGzjqtKpXx+hyrKXMkzaZOErevxHMnnrkVam8JvTKSM7AMOLL2R+Igpn1Wqw6CYLZu/hBatnVoDfJY4WTWVj6+z89MtjKlfWud+yVnN5OWOoKVmdcVa/dN2CBrdZQB4AADFYM9Jw4aDLblb+ycpf1zScDz7t7fsxbBct7h01FgcOz8YA+y3dIV6KdpSHfLpIfNcLRHxAeCJI49L0pkJINF+cWdU8+cin7VrjwCCZxPZnnuBiXyfPOWwvIrjpS/bu1L5CIrIeks8n2mVbluHvThxe6PbeDbNZh7m4hrX1ThocfH7fRutWAdOSLm0oFcJ1VSrGuN10+usWADe5UARadtqJVm4ldpdolGT3zpxfUWB4F8a0yEwxiZP6jvCP7a9gHKrMWIGxaF9u0iWMgAU2oI+OpFr0eyijLR3kIrNOf1soKxzy5MCwpJXpyFJn3Ay5+MPjrxHYfyU5zUv43GGWSNWyEXst9woaDWBZ6L1bW0sAOiJiOgvS0T0z01ERMQWAsB/jpz0M3Du4+UAAAAASUVORK5CYII=",
    },
    "F48": {
        "description": "intestine",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAMCAAAAADNSFtmAAAARklEQVR4nI2PsRHAIBDDBGX2+SKzkXmomI9WbIDj1j6djCkvTfbDNd+9hlra0gjpiTMBKkkPRv6FropKRusOM3Kij/745QHsELKcF+6U0QAAAABJRU5ErkJggg==",
    },
    "S6": {
        "description": "combination of pschent crown and basket",
        "pronunciation": "sxmty",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACOUlEQVR4nGWSXUhTYRjH/2dnZ7VNZG07G4E0whFSWDQ0mXNepZRCREgXXZhehIhGhYh3XRZEH0TYXWAgRFPsY2qRTZeUgYKEq2xFVFZzzTnbmR9jH+fp4nTOPvxf/d/n977P877v8wCyNIxi4YyQd2cPXVap5Ui7a/3WD3nRwC8fbG7OvhflQGdqNTBm/L84u3LPSxHyWZV0E0Jb99oByddkPY6ISHQ9V2088Xpy0CBlHp8tHyDhW8iVw2eoTzJst/iQdwu0GH2GPD16ogcA3pNO8rhG36+GuvJxTawPgGGKYkfBjND887cl+RgXqMtinaLwMcAVSvcs3lYVYNMd8k3SrybANELDHUuVKJR2iEhwAajNrlQF7qqKMG6KwVoAeEHn235WFUFz73qis7quztlCscqXb5gCyLa+IqI/q0I8lnrc0LhxSQrLm6xLMwM7VCwAJvMg3u+oTwMA5I7Rlu++kkq9r1+ikO8XubErV6kxMYpCjOXcQ0y9n/4WY2UugIr6LyjGUCZDdXHauw2TVnb2Fn9UOWS3WHneyuFUuNXAAoDFH9ytUCaaTulZbMRLy8T4ZoIVOaNhc75E+o5kXD1zZOGrjuG49BbDchogm0oayxIAkMlW62Ad/O1GkTQcx3EcjoeHAd4XNhdzAIA74rMD0E0LHfw2aLqS9dsAAFqPEDy3pwCa2wOZIZvcsROOJm7u44fErAjAqas4tL90bG40lWvo3tOHy23CxJqKNCf1kc/vni4AAP4BLdjVftzJ6QwAAAAASUVORK5CYII=",
    },
    "O15": {
        "description": "enclosure with cup and flat loaf",
        "pronunciation": "wsxt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB7UlEQVR4nKWSXUiTYRTHf8/T2VaS1JYQ0aLIWqQZkdBNFBWGRTcLipBC1MCrLkyWd5EFQfQxupAuisRoQSBEehEMhkV0UxRBlK6UyHKmFZaJrr2+H11szvW2rjoXDzz8OOf8/+ccZXwXvdXh71DPLWOZGj/zMZYphrXv6Op28Q4l6vyqCGYiXuOT0s7j9SEpQs136oYtVw8FKkbeZqxsQc+CPN5QsURXS/SwzUBbqNwB9NhAOo8vBm3TES8wu6UrBKAmhvYaeWkAggjmysqTPUDJ9Z0ukYIC+TD64xNQMtPv2xawB5P8UcLzZuQgwPpNMf/tu73NBeYxLTTfNgOUBx9kPKeTViF2HOCxfy2wZuyL1sPpgv65gXSf67hjLG5IfF2BFKrL4dS9Y/vh13lTu5UDYJ2IKki/dw12DjP50k3mjf07/g8LKmeksiz9rEi2ZFccefLoaTSM66zmlF+qvzBY3daYSjmubACaI69uPbx2amn7wqLZddR8BtjncWHDtrG50pP9GtMKbCD7GtJqOmy8PDObxSqCpqo2DrVVaKdVWkZ/9oeC+Wp2anx4z4s47N7eN6lbZKop4QQKulmvw/cXAdIXpqlbjHXe2PT8dZtlN3tz5g+oVYb4z0ppZ0ceL+9qPOJNAuauHVMZ/29T2aJQW+CXiQAAAABJRU5ErkJggg==",
    },
    "O34": {
        "description": "door bolt",
        "pronunciation": "z",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAGCAAAAABhzQhHAAAAS0lEQVR4nGNkQAUJXn93ujNvW4AqyoKuKJSBIYKBgQFVGeN/NMOUGO4pMdxDE2RiIAPEr/r/f9X//6vi8bprIQPD3x1/mbcuRBUGAAwjFGeg9yXXAAAAAElFTkSuQmCC",
    },
    "A19": {
        "description": "bent man leaning on staff",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAAB2UlEQVR4nE2R30tTcRjGP+d7jmsLpqtj1jpC2hT1JmorYUUXDQuDDLGLmUQ3XYT0B4RIN2EgBKMIgqCLYFEEXRgUdiEMCaNJ9GOZaCyXk5bsVC6a22ie8+3izOi9evjwvi/v87wAQNecHdvlSAQAxujGjZa4/380dNpVeLqtw0EaAEe8+fB+X/TVH5vNulsZbr703kreutyu1tChNzI5Hrw4tS5nz7ng7B0V9va+zbehX63KF7u5Zi7UAYxlOqHr420ZQdozgH4inQ4Cj4/mp7iXyw4NDE6uy+J8n3A/9MUkkUVZKZWr02MnP5vDA3OuHhP9vrWSjR9zw/Efv37KaPCr5tHLoVIR0Oq/BBbadqaFaAxYv4sArSOBB/3joWpBaP6cBYB0a6P52eaSqimeVcdYZmLfGvmGKy0C5eUGADv6XsOn1PllATWje4xJUMrxM+JfGvXWN5B171KaXUtRDK4F221pLKLpfHeyDHU8AZhANGE6g34eRS6YVNE8RafrQNP8SCaRfb5VESpLAESZWYbESlgVfqkA0G0nbbCnDa9ocDZt11cTgCz4PKL2pnBraglAUZTNU/u33HSELTWQdB8+eKqSAujpLUCs0Ol9Zkn5QYXG6zmZNP4Cz3yu08N8MtEAAAAASUVORK5CYII=",
    },
    "U4": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABqUlEQVR4nGNgQAVG/////98O5zIxoIM9M5E4mNJTMvBKc7HglUYBWKX/45H+z8DAhUeag+FPggcuy0z+X5Sd+v9zuhp2adVn/xeLJNz9f60/nA+LNEvoi/8nujxjXv3/fmlHlwamAvH8d//fl5qn9T75/P8kIwMDg4APK8Ir/37/uBaVLj4vmUHUbsE/FgYGoZkhN9h+MzEw/2ZiYP79V5WVsX7PKj2RN6/FWXcxMAit/j9RWU1FVQWCVbb8YWRgCH5qzqB05384A9ec79/evnrx8gUMf3rKyCB85IaE1OH/03lYOI/uZfrH9pvpHysMf/4v3WldzbPYor/xCza/iy34WmNw6P8UNqwhY7b/cqTk5TeVHNgkBX2fH3CTPXjIAqtW5T0v2rnTrsxnxyYpMePSLGutfZdqubBIqk1896RXe9ujo9ZwIXjCktc3STu2cofqqWPx+zEdVH/h/1Qr88n/V8dimspec/n/PBOtra92O/Ngynq/u79GznDjk/PGmJIiAc1f/02KnPtvE9YEtuXT/////7+uCsQmycDw////f9cn6GOXZAAA0Q+wLCLxalQAAAAASUVORK5CYII=",
    },
    "Z6": {
        "description": "substitute for various human figures",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAVCAAAAAAPuMNxAAAAh0lEQVR4nNXPIQ6DQBSE4ZfgqgiOExRVh9legCOR1GE5BHZlHQK5wZBwgho0ptkEg/qxJWn6nu3oL5kZGX0phrzBIv0IJln+sXTBGaQL8M2dpQs71Er7NLCxV6m+E67aoR6IuaJEpIe10NllhlZnksQfPz/ygJeBSQ3PzOA68AZ2W4iW2vvUHK4iedjpegVVAAAAAElFTkSuQmCC",
    },
    "G51": {
        "description": "bird pecking at fish",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAeCAAAAACOSIixAAACTUlEQVR4nG2SS0jUURTGf/NQcirBES0pzIzUSIsiy0dQFNGqUlpkgj2gwiSRwkWLBEGjDNpoDzdCrbQ3PZRIxIJQJCUMIww1y0foqDjZmO+vxTwc5++3ut+9v3vOueceALAkJJUuSHMXErdvW4lRJgCO5li2xgFtDszVHa3LcECBJA0ODY+4JEkP8iOWgQ5JfyuL3OvKupp/kvJiDNT7+REVRoR77Z7CW6OaKS+LXwLt17mQT5IKbIt79o+Siux+1E2VAoeHJOXErfFt3+uVdGltgueNJde43lwLxVdWw2yefcYy+DZLjj9nsgEo+dAAUCLNSGObTQBBcT9mp5xfJ7SoDjesLmJ3TEgDWX512EPiutxUo4caBrjYL+ldkhUIT969M36v0w05ojyUw329UZLmevv7PKnmpqen9cvTIR9Fhef4flpAR80gn8n/Cbm10NBkpPxUDL8rIASDUuXLCNIWXiknkDGbls7T029UeMbJn9p3PrCCbiNlfRi9xAeBhVlDrGjA6nWXeQ2THDQUL0n1XtOuSMxPNB4TSA1JeuFZn3Lp0Y0WSZ2bljDxZDRKrpMAR9r9BuF5tq+TB7JbTGFnbwOfW1esyoS+8SCYjg4DcNZZZeJOenImIybW1ycA0LCrZqx4BiDxqguIzPBlfAnYBiRJ67qbNxreBoxJd60wmVJ2wgxVkbE9VeVfMAcvAMzbsoJkNk1FhUGbm0/r8Vb9/diUDHrsjbuh03g4PpkaaquW5PR+mSn0+Ol0CwCjTfMA5jfPcM5jS8kN5j/NF1QaU30iQAAAAABJRU5ErkJggg==",
    },
    "V32": {
        "pronunciation": "msn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAAAxklEQVR4nH2QsWoCQRBA3waLfIAQMIXlISLkH+y0SCMIV1zhf5llr9XGwvT5ARFCCCnt/YeXYsNdlhBfNbPzZoZZ6InaJxr5h6gQNd60sqIab1oQVfCvlUzrCmBUJwtSPQKo1skUBHiBTdd44LmLu4Luiu68tJi+UxRqt78+4kfLbK1B7wBODPqdBZsBJ4Ag+1V+ulw/3j+PEpCwnMymw3Eu7FfkE1oA5o/FCZc3ABqAkJr29fwFwHIymw4f7vvJAFRPi6b9Bh59fFFP+CWSAAAAAElFTkSuQmCC",
    },
    "F31": {
        "description": "three skins tied together",
        "pronunciation": "ms",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABW0lEQVR4nJWKzyuDcRyAn/fbd3slWu+8a1EzzIlWXNxEFBcttItykR9FObjsT3B08Q/YzYHkoB1G2oFErM1h1Kg3EomXWu9C+jjg4Oi5PU8PQBNks9AEAIn8COfnJPIJAJblofvoqPtRlgGw0pJxnIykre/bN+eJeDM+fuhwRJwOAAMYX7DqqLir2wD9268X0YOD6IW71QsTLyKLzXd3kSWRlwmC6+LF5uVzNubJelC7ha7jq8tbrq82egou7fflVuxSyaa1fN+uOsOxAENtLQMEYuFONQXTetBfM6ynYUoHHj5s8/2Jd7Ph1hcgfrIXJVIsRmjJncS1in9WCTUSuvF6DKWSZu0oSdtOMlZjjlMWyfh3RHb8uyIlvdJX2VfpCptqzanLQWoSSKWAyRRY2cN6OD2F+sOspZU2DfADhvmmNCKAAIig+MO/VBtK/ValDO2eBauQA6rFZ/cLK3aFqdNvZ94AAAAASUVORK5CYII=",
    },
    "O49": {
        "description": "village",
        "pronunciation": "niwt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAAl0lEQVR4nG2Quw3CQBBEHxYFOL4MHSKBVqjhwnFJLgOJWkhNaIeWkC5kCM7GSNwm+9HO7OwAEJVtOysC7IDz/UAH9DyvDwBa2wKQ7RYgeEq2QHaaHCAOTiRbshPJQ0Qu5TeJbKk0ZdkZiwIpE2RWYliPNPxHBZi9XN/oKyIqUgket4dGh9rbe5gvt2P/boo58yLkpNePhR+8YZhmRH/b8gAAAABJRU5ErkJggg==",
    },
    "M7": {
        "description": "combination of palm branch and stool",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAtklEQVR4nF3OoUoEQBAG4G/XXfAwCWIy+AQKXhIxCmIRBEWMlgt2m88iJl/BewHNhgvGKybBosId565hV4OTPpiZfwbks6daAwYHV5vTKWyMy2gV7C4eVojIS4+fTdWzJt66itiVaVq71mr7ttZ9RMenJ727/P7aNVnc9LnBYZuDy77By29evxgxN0faE7a+h5lQUSIlub+LNbg4TyZjGKbYf8o9wV/Wf83Al1SO1mFnFkoA9eMHAqUwNvGhYgkAAAAASUVORK5CYII=",
    },
    "B7": {
        "description": "queen wearing diadem and holding flower",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAACMklEQVR4nF3SXUjTURjH8e//7EVFsU1CTcMXNEWUpZZXiYIm0cWiAiGpiLyJLiqEEKyIQOwigsAKKRKCoigkTfHCNFeZkogvOJeaztAEi1zD6dza/tvpYrNsz9V5+PAcOL/nwPYq3J+FzdFpUdtA/CcHR/ry3auvHquSyHonb3zyjliDgwmRste7rnalJeZPPIyKpAa/Y8V2Jz13skKJkMqOMe+Hk76K8wdEhKTGtU80DRRkjBVrI8QpExrTS59YVa8WwJRpnwqLpaXe4M4r9uMDuLjs+nxka8hQ3bMZvJ2Tuwjsco8VXJ3J+nthq5Tydfk8ULJ6CZ29dguiV1TZ430wLSB5ox1/R3VcWNI8FtlpOZwsoNLoR+Qeak4JyfHlYWXEujtOKGXV8UcRpcrZvqLQW30BloSiJW1Sym4wueX6TAqgmb6Z/zThStAu1sfBCXNd1M/f0oBRu2w79Uv745hwfQMreAb4eUJp1rAvdgjQuBwiu+7CrBdYxbzRevoMifpZ0CR+cWkzoqZUHTBqrdL3339kiF/zAxqPSvt46uxlgLvSDC+kv1cB0dIWIypGV0J5d/+ugWtL2iEJMXucPhG/Fgzt6M2CaSdztV+HAX2KJyiQOVFLAMFnWVXwtqgXiM37LsVCeePmewCeR2cDa35Auu1gDqgNocB0g/e28q6xZQNGoybcm/sN4dPHlyBwOgPhXpcR3oSSWWJi2w+pqUtqcgCQtCP2+rl/ULYot1Wg8A8NWOHMyqX6pAAAAABJRU5ErkJggg==",
    },
    "N1": {
        "description": "sky",
        "pronunciation": "pt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAARUlEQVR4nJXNsRHAMAzDQDiXpTWaxvEkcKE6ssL6j1gy2TNSvLCuyOnbHxY2i+raKw0UDXd+53IbirYKclusVZDFLgpSDwJrYdu2kj5DAAAAAElFTkSuQmCC",
    },
    "A17": {
        "description": "child sitting with hand to mouth",
        "pronunciation": "Xrd",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABz0lEQVR4nF3RX0hTcRjG8e85O3ZW+S8ss5grmiyCuikvypg1vIhW5EVQXgW5riRG0lVGBJURhBAIxa40SJBgRH+YUTAqCCnFoAUj5rywnKJZsibr7Oh5u5jDsz2XH15+P573BXvOTMvvk5Sl+saXudHZlzVl3CnyxHUx5QE0G/tWbk783J9Zto82HGt9kW3Cl++x66l3IoP5sS3RRKNNzy7J4PGtPWZodMq7rs60hLXN3dPWrd2pqQvONa0bMh7629Min1zQLUP1Bb4qf4cXRV6PRUDvF7kCgHdBROTe4bqWtw68sVfWj70Azavpj9d2KLBr8gAdSdc5M6wBs12xJAC5ZU/8kLryfKRNBWbCBcVwtil5UY35Paq9k1WpK5aqoCh2rmrZPmJV5kxNt9bRffqZRGr1b2Hck7EiHuwf/zMfdFGTecDlXKCwWO1O5zbiodpg/kTFe44mJwqz7aasJXG76oiMN2oAmt8BiQEVcQzMEWAmUzhBXETOF795JEEAlJCZXTUaihy9uwEAfVgu/crW24tpwL7mr583OUr6qoDb8yZXkTLKuTrzWNN6l0of2ejr6zPuY4qd2dn7b8EflcXWEuXD90jH9fzTgF6i/wFojbkjTta3sAAAAABJRU5ErkJggg==",
    },
    "F12": {
        "description": "head and neck of animal",
        "pronunciation": "wsr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAApUlEQVR4nGNgYGBgYGBQ/bDNQ4URwha7zfhyDwuEbc3OzvuOCcKWYWVg4ISy//xnYNCBsn8wMDBAtArEXPt/rfwpg6ZU65MP71aYCJg+Y/j5//+FmW4MDAyrP7JMCVB69lRDRETL/hoDU8zH/0cTrv7//38OAwMjvwA7A/+UX/9rGaBA8MZrB6j5DMz/Ht+AsRkYWVngbAYGhsHMhoYhw7+f//8BACB3MiXl9OiaAAAAAElFTkSuQmCC",
    },
    "C7": {
        "description": "god with seth-animal head",
        "pronunciation": "stX",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABjElEQVR4nD3PT0iTcRzH8ffzex6bz8g/kZT9YSFFBaFl5mVCEIQ09LYui25egy4iZOQlDyHmVWLQxUspo0MSRXaIFkQbQTRSx2It0i3RtT2z/Xm2+e2wx31uLz6Xzwca6YjIVCR7nf0c25NETSZQjitxTut0Nl2KQb0iGI7rPUVju6o1+1v9m/nQqYzjQ7Pzf94sf0JvlNqcfFkaN5/K28MAajr3kPExfov0K+DBnWB+pvO7j8c/R4Dh0ubqr6jEtxYIhYF7eWuhu/V2TdLXZiwAn98FlzJSz3wtNg/cFIlOiuzvcY0WKh+WMyjMbgBz6ElET8ZQvcGX031gnkla7kIWNRk4cj80Anbh/UdNg8V3nhuFVN/5nM88oD0X9exy12ufvuQXSrb7IJz9G3Tj3ZL1C3DxR5n2F3sDMCVhF1zZ+KysFe0uPEokbND1rEHcGnVV7MGawImj3xSxtbYuyO0COq8U6XXD64xuYUdBmXOOT4KCVsqOq7gNOjz4j2sAMkgArqZKVWnE/pf+D8wsoXjp1vd+AAAAAElFTkSuQmCC",
    },
    "V11": {
        "description": "cartouche-(divided)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAAAAABXO2kQAAAAV0lEQVR4nKXQQRGAMAxE0T84wE0d1AIG8IKECqmFKELA50gn5MYe3yXZRYE2XILCpcn6qY7GGw2NVUA1INmdCY3jazPTluG/7cXd6r+qR9W32qXaj7zzA7Ezbg0Z1fCpAAAAAElFTkSuQmCC",
    },
    "E34": {
        "description": "hare",
        "pronunciation": "wn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAAAAACzJtCvAAABwklEQVR4nG2RMYgTQRiFv8CRY6wWkSOcR5rT5izcctFGK6+zECRgIUi4yuVQZEmdwibdlldZHtiJWy6cxQgHU0gKRU6WxUJEtjhBJhheYbHZkKx53f/z8d77Zzps1KD/EK7vweXzU4DORmL72o7/cXbxNJxf2WwzslP5aRoDjJVtZEzi5O3jZlS6kUqsStsM1uZ6k1SyQYuyVtYYgNjmrpSTKsnbNuUhgFxSNbUxwFQubFGuAnAqbI2Q5PITswaFThVA6RYMWPlJb90q8t4BqIFcoTJtl4981QNGsgYgnUpFvB6nEZGvop4Baw0gSUViWk7yuaxxWoRZa+N2GNAJnw1/hZf1MHlxzl0AgsP+DDN7+7PBILs/ZvfO8BOY41dfecT7v9sHfGN+tc+HJw2Icaqc8vphCu8rlyVHPQjMflJU6bKlySpyhe0+Ng8xmZzB1G17foR37eNG8rdhLBdkvtkwkDOYVbTnlYMpVErLpSmVky0tgygtJR1BIklb5nj33tmFmR3uYAe39r68+3gK8c1hF9gqX59wY5G3VKV1AUonkuQ72YPV2t//zLvMuxys7Oaff7/8/1/q+vt57XgyiQLgH+6wAm2s9CVWAAAAAElFTkSuQmCC",
    },
    "N13": {
        "description": "combination of crescent moon and star",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAbCAAAAABKY7DwAAABMUlEQVR4nHXRoU8CYRjH8Z+IhaBuNHUzmNSNoMXqxGmx3NQuidG8vwEyt2FkEhzB5G7CMBgMmGzgTDjFoOPcHEKx6NdwHMpx96Tfu8/e53n2vpJXUQseL9P7CiwHviGE33HL3gpSozLg9HRga8Pu/AD2GFiW6y3g1n8XaxAqH/Aw6UO8dA6chKGMJ9gIQxlvPv2PysPZRBgqT39JUC+MYNSqw54WoagaQMH00LS+gCtJNhdSsgm0yxmBMuUX4D4pSTPdZ0mxg2uAGlQBbg5j7pjZO3ej1OrKriSp2mqeDvdaHm6XAjgafZaIF/rq9dRVYCWhVILNIJsHNAUsBGAJclIWipExMyEnSVk49lu8Q9tNrzhx38BPWHfjGvTn/E0TXk6AOYSIJDnbDe/c2HH+fu4XRiTBM/JLkBQAAAAASUVORK5CYII=",
    },
    "G50": {
        "description": "two plovers",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAcCAAAAAAot5K5AAACDElEQVR4nHWRT0iTcRjHP5tzvkLRpUNtETIsSBdF2SE7RLeiU6SXEBIvMwKTKAyE6tDl9RDmYVBQeFEjxIKwJeQlu2zRX0goIdzc+jPHdMtcbtW3Q27vJu+ey+/3fJ/P830eeAAMMxYzneAx0zK3US0606aZdtJ0M2aay0F7Zu9ASCEIzfXl9QhCCtliKUktYErSQi3Elm2xe4klpbzkpPiabsHTdLXdprRITg8N/ugA0cVqmEvfKAjYrv18XXXYIE7gN3/JArThYLo+GrB3CyiAT+q4KDXAdf0IHLLHDPCtSuoCoFNSPECdjRvAZxXH7Z6XtBbYiIUBOK1rlvhAUr69gnuuhBNgVv4ytU/S98Ey4agUAfAoWtH+uiDpuJV3SDMOwDf00agAfRHlJqy0W8rebwR6NXOsnBuVFC211n2SlJl0QfMXjVh38EuS5vcUlR0LDPXw06hZ2QQFx9tnbuqHI3AuCBAptnkl7koan5MV8eTsO0kvPCdK9ik1elc0CjekcFKSNNF76YkkaZe1a1gQ1BhwWQN0SdkjAP7mJv9hd4lyKgloDDipYVhav0yxvP5uRQCtwOTLLdCGYYe1/P/tvACk3DCNyw57TA8AGWBzAWpLlbI4Jb0H0CvgjG5DQh/KARfg7r8K7Zz1+HgDeGno7vdwfqPXvowSg9RM6VfoIK3j+ZErUupOBfIPqPwR5GvXi9IAAAAASUVORK5CYII=",
    },
    "F35": {
        "description": "heart andwindpipe",
        "pronunciation": "nfr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA7UlEQVR4nGNgYGCw+W/LwMDAxMDAwMjAAGX9Y/jHwMDAwsLDwMfAJ8DwhcHpPwQ4sTzoYJCNXvqY4T4DAwOD0X8jqA5uBm4oiwFuCums3wy/ISxRbQZtIQYGBgbphf///98kycAgNuPNk/O3/i8TZYi+d1qaV2TFq3iG86/U+KxFNF/tY/jfI7Tt/wHhCeeYfl4IVo/UCTjDwPAlkJ+XQYhP/x4TE+NHlsAvn9h/M7FZ8s2f0cvq8oWJWZdXJtmOSYyDcafyGcaUw8e1/jCYXfs/j2HP/9/BTGcWMPBJizIcPcDAoLjp+alf28wZANRKTbmIXhNWAAAAAElFTkSuQmCC",
    },
    "G28": {
        "description": "glossy ibis",
        "pronunciation": "gm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAWCAAAAACX5YFsAAABLklEQVR4nI2SrVIDMRSFvzoQ2KoV1UgeJIMrvMDOug5mTbFMMEzjeAMWiergeIi8QATmVoYZkAexP7RlSzkqueebm/sTAJjLLNGqMUmSlQW/tNQyEiIAQbJQVqVJqve4oAsArb1vsmIfdnEPTZKZZfBmUgHr3inSNqroAbz8EEmD6bKy6/JZB3jJYuO9B+VyQOdRWgHEIRE+mpnJQzDJVl3fRZSWTNJsr7XqMdxAeX495ePr8xngasbt71lRJ3VluSqllMzMpBGQOilWO5FmlINarXJMKbWLWk1GybDYNAu4b28nl7y8jadEBknhgPsjpxIwOwpGFf8CnTJQ5HiEK7IcEFQeAVP71XI/90NadmvY3cb2HN3dFDg9gw0w3TW3z2qJXk8P7wfeXL/+Uf032Ci0zOatCFUAAAAASUVORK5CYII=",
    },
    "H4": {
        "description": "head of vulture",
        "pronunciation": "nr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAATCAAAAACBnrN1AAAA00lEQVR4nCXLMUgCAQBA0a9EgoNTg9TWFjQLLg23SFBTEQW1iJOJ0BBBQ4JBNHnQEt3akNDg0nYERRAODYJQowg5BVEkIlR8B8c3PGBhta/6V85AKnqxOxg/2tsjuPb9knKF0vczQ89ycwBs/KNq2FiBTadQz6mZaM+Dn9lsOz/4Ig1Ay6sbWwAQG63rFgAPHje1AMCRTX4sAjDzG9OzMg11w6LqSQK4denC0Ui3kwAfswTpZXaAQ08z9xF0YmDRJ0hR8A5g19eDaug4AEjuD9W3NSb8gWxhBNPXmwAAAABJRU5ErkJggg==",
    },
    "A44": {
        "description": "king wearing white crown with flagellum",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAAB6klEQVR4nG3SXUjTURjH8e9/bi5dc4rMVokF5UUuAhFEColB0EUQEUlFSZE3XohLsKwgqLsigkEkQhkkCyN68aKkrjKokKjoZQiBzvCizZpSm2/7b+7XRVOm7Vw953wOzw/OcyDvMjpG8wMt4VR+aJ0z88uJ2fH+hGXVobUAPP6i5sno6us1F2uLA+rzRu6tFvfw6P3pAVdD+ux/GX1S0Gm5GfL+29qNZWmIaqa94umAAwBnsHNZqibMjz8jmWyzw5rbuiTVkfj2q1IXFoBKiro3ZeXXvPNGtckiABVhJTS4MUt1g0ot6roB4JVawrq91G+fJA15AKNXi/VNih3JSqf6I5o6BOxeUGyb7Zb+NANQFgpVXpMuQOET83uPnaoPCm0GqNFdtsyrFXZFRjMd0G5KD0qAZ7rMqd9ta7AEpo5P7IQ2SQqWwudpH29eO7Cc3Jv0fXkL0TRJjl3CVT72krStAOKSugHPsPyPNdN4NNUNQ10G1lcObA+B6Iu6seeuxt7MwhmM8qhynn9//IqN07N6BM7xA7mD8SW/rcc4n6yFtZ/cYF2Wd+9dQoHJH1BCYsU0z31dl616IoWQ83fuGO5stcFhrJCktQ4oLi2xW0eUmwOVO/ZYy5pKM2a931yR06ZEbCouSToI/AXWasqqFncPWwAAAABJRU5ErkJggg==",
    },
    "F22": {
        "description": "hind-quarters of lion",
        "pronunciation": "pH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAUCAAAAAC2K3JiAAABQElEQVR4nF2RyyuEURjGf98MGs2wkDTKgsXU1BSSUi5/gGLBTknIX0CNjMTCtZTckkuTRmIjYk9qRrnUKFaEUhYUamqaEj0W851PeTfnefqd9+l9zwEgP9j9cx7KIVt93604VXd8KcWabdeh8B860sP0mzRv0JpD2rUFRKUJADqVsAxq0zZA5EWzANyqF8AFWLgBJsvSA2MACb6cxKfT7Om50zhQrLiDlmWHe780CNyr0qAqxV02y2gYIlK5jSqkqC39z5qiMKUd0xbWh5G+tFpYkfrNXWnOsCVdQ0w3PtuvSm7DYgpQLfUYv6FSI+s1CnvatydjEedNz05C4CLo7PapIiO3VcuuZLpoImk+7INCGsECf00GMgWHnvehdYD2mPfKF+TCaiiZCTipC695yoxkx+6yUp5c/tdj0nIfbP4CNex5b9DUTHIAAAAASUVORK5CYII=",
    },
    "U29": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAAA00lEQVR4nDWOMW7CQBBF38yO7QQRhESJIqGQFD4Hx0hDkyqXgZKjcIs0qakjIVMkMXgt76RYZ6qnr/e/BkB3OwUMqFZU14yTJyZXUGBjthmF6Y3pv/tJNaJ8IyPWSk2ubZtmm1O5fHARx4DUkXLqCDgoLHQYdAEK69C2YZ0FT3gWliHGsAQD7b7oNO+KIgIGL/FEl2ul93AHCsnBU35nPAOf18wdDIrZIzMDg+PbK80R0MDefU9QOXdF8eC/sS+tOJwGkvnzu3n8cUBuSfq2BCDe/wHkL0cIYvgVdgAAAABJRU5ErkJggg==",
    },
    "H2": {
        "description": "head of crested bird",
        "pronunciation": "wSm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAbCAAAAAA1sqIBAAABNklEQVR4nI2RLU8DQRRFbwmuNIGgQdRCyBJMg9+wjgRWT7D8DeSgl4QgCKJySRCbLBK1poj5Aa3Cr5kmuIPotunHNsNVkzdn7n3vjbSsyDoAnI20XQlAUZYl1PZoG5V6Ch9LUgbgF56Dh6VAh+8NybXgADweoGFOrQOMLHb2xs+YRrWkKJ/1zaSqqqoaDiSp4BlqM5+kc//YncdOF6f32/xqT+nLvqbjn19JalqYlMO7uIGMQzmSYls3qZ22kfOb87fjg6Zrc/Krj9bNFBifr1R22rBLdbtt9VUZvCMOYjU5oyAVgyMNUYmnIAuaObIR68WNSbOzz92Lp5BX6unX9ANUH9I0PGZNodonASqhPNQ/zLxkwh+AlTa3sS5DJOFbblb2dq1IfX2FsLFeGes7FNoDoNdy8wfwVcLZbTkMgAAAAABJRU5ErkJggg==",
    },
    "K1": {
        "description": "tilapia",
        "pronunciation": "in",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAATCAAAAADZ4SBsAAABt0lEQVR4nG2STUiUURiFn89JG6OMaNShcApcOYuCQlpV1CKwkQgxMkkXLYJwFUG1KIJwkQvdtagoykURWbkxpE0QRgsLJhL6IZDGiZB+EPtxqtGnhTPOl3Z25/Dc+573cqGg6M7M7Kt0Ov3JRWoDWFbE9h6ve3DtZyTX1JgrRszsiULJAvW6iyVKjjq2Nhz0mlpKUTdpZ9hf0oaV8Xg8nqgMxyN+XxWyF0uN3zS3rSvG5zQFBAXboGbGM9lsNvtxUtXT1QlYPuVDiPTaFQDEpv12Y+Hm9sFHqnalnukpDqgzG4GavBeA/seJIhmhe3JCdfau5sc+eJmyuOMkp44wpn/6y0OFjzmrpmCTw2we8DxtPmdU1Y7wouVf3AfQ85sX/qqCZA1PCqveCnG3HQU4KQM/NHcVmNbXLQfbj3ZtKEJb76vVwNs0Kw6pTrx77/yABUWGVL0O27wHa1r7Cg9bQs4M3cmpHU/Vl7v7vBkArK9v7qyF8SgQlAXM1c7TAa2NzUlgS/F81f6WxR9NR4DqpuGvOyqC0qRYRXtPGZztjhnkE4fzVM6dAChf/fmf0gTbewYzV/iP/gI6qQC3US4r6wAAAABJRU5ErkJggg==",
    },
    "O12": {
        "description": "combination of palace and forearm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAABg0lEQVR4nK2RvS9DYRjFf+91e69WVUppIpFII12Q8AdQMdgaJP4AIr5Wk0nCYCMmiUVibERiILH5GkS3VtV3xeJrIE18tNF6DVd7r/TanOEdzsk5z/s8R1BEYvV1rGt32T3YXKRUU5UdWd+Er1tHSEoRlwaSws6rRQcANt3YqVJvANCMXCXoTyctybFfyf6kfBixqKeJcLh3u6COy+f7J4t6vgs16YK6/tI5JS1zUWDGc+ZTAPAs7ucflV9LBYaeR4814493aIqKXtPe+pHbSyAlU66dgwopAb6MjernGzW9Ibc5pzpCPbmtJpcWlCBFaPVNiv7G7Eambq2l9HYr6WERDVbFPzNtFemHD4HqEGQoN1SnEhUBUekUIvv1/h4JEpnLEfH0/ZjFm5oqJrmrufZCbdlt6RSzo5hJWa7hSE0DzDpt+708BODwxrbfvDcE4M3bjS02eGLr1a8mARZ0W+/FEQBHKdNr7Uj5g/kL/6XmLa8By0afgSWAwIttTKGFuEl9AzKynNpV1sABAAAAAElFTkSuQmCC",
    },
    "U14": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAOCAAAAABmqTEpAAAAt0lEQVR4nHWRu43EMAwFJ9xOBDh0B+5h+7FyVbCFqCa5AqVzAWWdfJ+XCBCGj3wkqHrwW+mohjqgBS0PYptETlDdYQvuGobbewCeCYBsDxOVou09PSYRjscLgCs4VWuYTss5dXSBonbV2p8AwOeuA0pzVV7A5ReAI9+mapuoJUZt58+9jQC97gAU7RnYcl06jrBktVfubseo9fGeg0QhRci8r6c6/SZFii2O8sdZbxa9RsZ/lIr6BXPXB9he7fCRAAAAAElFTkSuQmCC",
    },
    "Aa15": {
        "pronunciation": "M",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAKCAAAAAD5zaMCAAAAdklEQVR4nGNkgAB2dRYoi+GvaT8PAwqASukZJXH8hwr9EkFTw8DIwMDAoNIewsDwhhUq9P/nN+Ztp9gQatgZGBgYku78X9bHgB9M/v/LiYAS8Zb//3sIqGGovvE/mZAahv//dxFUw/KV+3OwCH417Axha/4TBAA38T9tq3YKewAAAABJRU5ErkJggg==",
    },
    "O9": {
        "description": "combination of enclosure, flat loaf and basket",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAABP0lEQVR4nM2SsUsCURzHv/fuONSwDlxaCiQUBImg2UGQFm91Eg4cImkJwSm4udYGo03wD3BraRdcXEIuTA4XiRQaLgsk9H4NnvfO49ncd3m/ex9+n3c/3pMIf0TB65MsRsuzNFqj/JbG/KiF1MTKCWHOmqTA6vOeLoB6b15nAExyaukQS9ccMgEAkWKXBu1S3EfxUntA3WIEkABg9+jh+Mf5fgFcBmR29tTnqv3JTSzbGNM640aWrecFALj9zuXd+6rev+r0w/9oUNKrkmT4Ss6jatl6s8pqNHBgoN1sTq+nTVMwPAzShxUFSmWoc7PCeUGrXshLSSvwrQCd2TEGuPZMaM541YHQrAC4OZSgCc0AcJ5YBD/ZJpUfVfV0ay9ACLw0FqYb+ff0CwAtVquXwLy3H0Ds5B4JgcQgHv8WfgEDhGzi28q5LAAAAABJRU5ErkJggg==",
    },
    "D4": {
        "description": "eye",
        "pronunciation": "ir",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAAAx0lEQVR4nG2RsU0EQQxF/4ZIF9IBIRGxAyJEeJJDClhNP1uDrwkihIgJEFPAhoZsCngEw+6B5hx9S89f9vekrez2/u5akvT9/vL5potlUQEyGwB1sYtUBVhtl2T4iAVrQHewRngFBjBYPWi/HYSkZQCD1VXIHSuSpGODeiYDXPLdrbLt70CN3vnKsZv0Qdt5zQmQi0sWkDGbls45zJKVqD0bIFNl0y0ZZGYUk6Qp9CBJujr8P/7r+fXj/IrpT8Q3j3qSpNP4qx97q6LMHnkewwAAAABJRU5ErkJggg==",
    },
    "O17": {
        "description": "open gateway with serpents",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAaCAAAAADz8AHjAAAA5klEQVR4nM2SIU/DQBiGnzZL1kFITmMxdUzvR2DwZf+JP1AcCjlDgpxoMoMcBlNR12DWRxUxNtoNOke4nPjuvud9782Xg6BvLK1DqlnQBU96m+qC2hygVjKdolJqmmmZqldLC2J4AV4BVsAzJAWcv2/gYs11iOEDAM5YbwsSsPmqb4BKw73ml5WGSmeF5jN1WmoZ1RMGVyRsmPy2gSYf0ufNaAxt58ZeP4HRgWTcPcgOiH70bwHioQTNKeCkw38Akr/JsB11y+G42y7wAHDXF/rYAeZAfuQ93wPHPfiWRPvH+hl2v5pPdxlll5vWoLIAAAAASUVORK5CYII=",
    },
    "G3": {
        "description": "combination of egyptian vulture and sickle",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACwUlEQVR4nFXRf0jUdxzH8ef3e3eepd4lmZZDqWDFimjVqIYJbaz6w5RyprJG7UcDR9Q2Wr9oYJBFbTG2WFRkQybbSFhwRW7lnO38kYE7VivQu36gu/BH3nXZqSnevfpDj9P3v48Pb16f1xvA+c7btZKki9MBINEkPksqO+4M+O4Ot/X3FhuArehCflznNUlScdG5eV/ptAlsD6kihlYSE/2DSXNC7obA+ZJU+zD2ff7AyKTlhmE4mt8HOBmcD5b7Hl9L6oSZIGkgJADPMwMwn3vfzIgzgLESwP3kXcAW+Dm6ginj6p8GsM+fhu3RZ1wJH7RORAMgYh2GhLUZr1zKfzawq09Jx7IvdzwEY5wvbzj0Irt1k+/Fts7P5+Tlrjaj/qx2V9ffE8vXjbZ+qyVOWNVzy0FaudpeXXdCkTuxhN09P3RvBijXH4DrUyAv+CCW7aq8j88CJJyKLiKz0gFOd7Asxnm6vfNpAYCzur6kcTcsPK9ya4xTOkcLv7u7GCCre0jzbR8+GD02K/7zD9SQVdW2CiB/0LP1r/CjTyYXs0Xa4awKfmkDY89gV3PZ7Cm9lfrcN6bPqNRRGyS31qZNbZVDvx8IFZB4ZqQhCxZ5c6dg5h7VpYebHMy6Kc97Fjrc9jjmVDRJden3hsqM5EvSyF5Kw5ti+NrFTknqmPu1bs3kgHT7z/rMG79OA8D+xXNJ0li0pzoY+cheFQ27HBf8//UtGz9GoKe+9szp7++NP/qmv2bjPym0SC4TYO7OXNMAW1f06imvJBXi3cXSm4oUTIq+Vz+mclxXNhTPZkffUjZL1ycoKdlCnSrgiFoArD/1ZnM4Ei4AZi7fX/Pbybd61f9xTqOiB1fn5lhWtDesWdCuX1Lg2mNJGpKkgCT1Pf0/ldd9oWq/BtZjbW4cE1iiwjTHUMIb6U8S+Ldo29YMPPd5CUHdR5s9JKmwAAAAAElFTkSuQmCC",
    },
    "I15": {
        "description": "snake",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAUCAAAAADAEcDpAAABo0lEQVR4nH3Sy4vNYRgH8M85M2MYbCbKtWRloyiahJpMLuVWkjFIYSGKFfIfWPAHjMWssEBRQsSCkhhKLrmNZsEUCymGxjDz+1qc3zkp5V0+fd7v87xPr4kHklyY73+nef9arPm+F6xvHZ906de/6t5oko95AieTpH8P6Orr7Ts2u0St7e/z1rk8Y05y8VSS5TiRJMmKetbivDE9mWZbvrApuc+Mb/lxeuu7fK2jjRngeKZIOjGYTHU2HxbS+jrzoMpqYamKuIMXFEYcfs7oZTdL9BuLthgpg5sM/UYLTFAtEWO63Ror0URb/1pCcwMNNx+3u6xOWmVyg9QGqKHxfR58KuuFl48baJY9jbhly+xERbXQ5vy3GmZDj0rqSTwahI8Fd30uQxh3JWW7pkb6ZsxwBuxDyidXGcQmtKmiKC8VKFTq6BKjI1jpFwrby3Wp9hmro6HbWm/jiAriaAvxguKVuY1RViY52N6ZLEBXMjBvXdKNjp9J+udMAB21f7ELXE+SPG0DS74kOVTr2d1fZHhvbcqZvdeuXttRM6rtPTeGH/4BbRy3/u/mJEoAAAAASUVORK5CYII=",
    },
    "V28": {
        "description": "a twisted wick",
        "pronunciation": "H",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAA40lEQVR4nAXBvS8DcQDH4c99L5c7Ha5Vg3YhNZDD4jVRLKbOBovB5v+w62YRVolB6GCqVZOmk9ENjWg1kmtrQLyc3v08D7BrPjeAyduX+CwHBx/754Ml4fduarYjEnd8+vtXhP5Csf0k7h+2t+7egeOft2UEsWt6CH+lNgwQE8FpNINIYzFC2MZ1bKDw3OquAzoxgwIi/cMaQ+R2WqNFRNE76uQRctLYINIknxFi6BxOvQLWhbnMIEyb8AthzzJnA2v9ZrSKKEd7/U3kVRqdRsVTUKpTL81zFWbJPl6TVC2savoP+SJNDtgA86YAAAAASUVORK5CYII=",
    },
    "A2": {
        "description": "man with hand to mouth",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAAB/klEQVR4nFWQS0hUARSGv7lzrUkdiULDzJiSmFaZlqGJBW3CosLKWoSghYjkxuwBQRAZSQ+KoDbVJisUWxS4E0OjJB9Ys9CI0lGxMkev4aDpPP8Wo2nf6vDxc37OgX+c6pPUvI3/KApaN689VUPccrn6raZfurnn27LcFvoVCowVZQyVA8aizUlsLnYMXvnhW7WUTL40EHZDY/duq3jROWq6JXVn0jTzsTN5QdprpUhTm9odd/6oJzUmE+s013J25WU9cnLAoy4XAAc1Us7W2tcVDmDjBe+bdCCzN1BK2bBKF/Y9UxVwLNywtzUieZwAlPg1mAHVsiQN9KkGIOGdpKNwXhporcjK887YgZyRD19UDynZ211rgebwHmDf1Mn7mls6Lz/0CozKb878aRlAVuWJdOjwGxBf6At+9WBC0pNsesr6sQHRoM0+8R0DTBdj7vdXMQBFwW5iADauuz8fSfspiE+JEvtvoBPzV8GnW6E4SMqb10L7aXVuYH2fhi6+6NBkstEogM3yZ7DmjCT5xruc9iaZQIBobkl1uG3W1vj80LnIjgIAUqWwHu83gRV3e4zD8pqAG8Ye3o4AxG0KJexi2ARuyHPcGyuejwRZ1/vAJL10Z7A+Jc0GEE3LsVxVSRPktkjh8XFr6rdlWROzivbX5RuMKsZo++TCpKGiv0Nx9PugwA/TAAAAAElFTkSuQmCC",
    },
    "U24": {
        "description": "handdrill(hieroglyph)",
        "pronunciation": "Hmt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA3UlEQVR4nH3NsUsCYRzG8e/7ehLn0hGEkYJCQggNQtDin1CDnA66NCqu0mRLW4v+B+6NSnFbS9ygEEGDiwSKkuHmIYrJ5b0Od6v9pg8Pz8MPAK7sCP6dObdIADKHMV9ajQkAovr76LfM+TMAJ5WZ6pejkLTG+VNzbKexHgBo9MTaGmx0SBWEAjcMKAyje3/9EzcMzeFvvfDmKyQgJJLgL+xVOASABoXVZaBvxD8LcNU2UEo/8vPsp6ofA2gvT6XhjYCco9yl2r5Kph3nq+313gTQvBid330AJFrvxQN2jxdAr6fxg0EAAAAASUVORK5CYII=",
    },
    "U38": {
        "description": "scale",
        "pronunciation": "mxAt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB/klEQVR4nHWSvW9SURjGf/dyoXzcio3VCgrSiiWKizXRYKxCl4ounevg6ObioomxsXbQGN1c/At0at1MoyGWqAkQWxrTNobwoRRNQ6SpxCL1chy4fCXwTud5fnnOOe97jkRHfSxueC/Wrn6me30orQhxp6WVTmwSkX+rj1paAvbFTAZdOoxl/pYlQKue26mnJW/+q1THdnPmcP4XIE54dQuLmGlsFv3xYsMNwIywADIwxfiQjvvST/aGAYbGmWpEhBbSl7H3Yz8XAEKaiNbTJmemeqSxu+ZQPRJwtJpxGEGGM8bZyIVGg9bFxD0BSiAyaxwDGSb6Xq5cU3Us791fAtQr8Vf2CZDB96fyzWVrTmJpB7AdK+xu+0DG7F4glvd3Tu90Ic68y4zMKc88yXS4E0+uJ3k9ehIZ36FNtEKwE4e2NL4f8CEzmszCm361naoHFyGbGEG5Pr19S+O48/HTdJOO3B44ux+D+UZOsWzZbkJ1TdVaYU1dD00idosWiQEDIKRyBSAmzgOYVSGBqJUUSu2HivrDVyq6bv8t0qXLbtODd1FB13JuCiFEztFmye3tOB8mUs/d/T2wv5b4XXxb8/fAwdyayfQlF+yBw6mMUcmkwt2xx7WsSQZt2eXpevG57CCfVhnMzrW8tr4D9rvSsPJM2APdwta40CtubZr/AWd1rXWG1f0jAAAAAElFTkSuQmCC",
    },
    "X1": {
        "description": "loaf of bread",
        "pronunciation": "t",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAALCAAAAABaYvKfAAAAXElEQVR4nGXLsRGAIBAF0cWaCIisgxoo5mJLsA4asoQ1UBgZX3Szfw4ASnTVHoVpd5q16VEB6qHtaaEx9nHXub5fFUp8GzSjEHYW3dgy5xpPcpK0RmSDy8UFSf5uOZRBZdj4YrgAAAAASUVORK5CYII=",
    },
    "R23": {
        "description": "two broad belemnites",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAJCAAAAACQm7qSAAAAnklEQVR4nI2QoQ0CURAFhwJogOQEwa5A4bAUgPuGoBGX0Az2oA3k4QlUgPgJBXwKGMSFQxyCEWteMnlvoadWULqjNUPSVY2wI0K9pk84gmo3mc4ZAxxnS47n1ZbLYwPw4vZ4HjJUrWppm0UU1QZoVEssmraothWa1xEAFMEEJMECQMQ6a+86/XCdPq4/e/Ub74ON98SQ7l8ZyILuv9Ebe7KJfsPLLJwAAAAASUVORK5CYII=",
    },
    "F19": {
        "description": "lower jaw-bone of ox",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAATCAAAAADZ4SBsAAAA5ElEQVR4nIXSMUrEUBCA4V97sQzkAskFUuwp7FJGeIXsSdIGrBd5B3iV3ZaxyxE8hTAe4LfIIlokGZhi4GOYYQZ2olXtoX7aU1z04tJMustGvzrVA/Y4WzotZZ/Ra69VPmAsast8xHpNEN4fOHijPTSzCYaDTRl8B4pBAjjfMp3+qbM2gEqUjsnE4ESn6U+rWWug1RG1V1HrTr2dr+qyOgC8aoMYEldRg8Ul57xEqBMASa8g69WMUI3fYqwBqNcnCY3tVasU6xyjRtlA9WkOLcAd+ZnvDfYAfLx8riNmt2O+VAD8AKe8xg6sfGZ3AAAAAElFTkSuQmCC",
    },
    "W6": {
        "description": "metal vessel",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAOCAAAAAAOWrMRAAAAjklEQVR4nFWPsQ3CQBAEx8gpXVAC0n9MN5/wcvguwAVQELkTKqABhBMkZwRDYMn/XLS7mlvddQDSTgf0VW6zIX1r2o1wmWDcgwnG+0xSLZUrqgmN0VDjYIx6YAHmGs/AAsXVf9rVAiFrrnHStFH529ynQ5W5gXei1gya9q+PjxM3AK48z5/amF+q+k6b/wFsm0bdboYRYgAAAABJRU5ErkJggg==",
    },
    "D36": {
        "description": "forearm (palm upwards)",
        "pronunciation": "a",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAAlUlEQVR4nGNgwA9Et/z/P1eOhYAqTU8GBq9vBBQxbPn/f8f//4RUvf2fwnCdoKof3QwMBf+ZCKhiv8jAwMlASBUDC4xQtrL6+Ydx1Ulsiv79hDJa/0PARU8sqt4sYGAohrs+4v///////fuPCv59+/9/LuvE/4w73Bnu1HL/YJrNjtttdxm3/tVQhbDfnviHVQ0j8xEAfZpJ8AGZzHsAAAAASUVORK5CYII=",
    },
    "Aa29": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAAeUlEQVR4nIXNIQrCcBiG8ed9J4PZZzaLh/AAa8tWgwfwEiuewuZhFIwmFdsYWP4wts9gFZZ+6eEB9hFhcHftDflt9zYoPXsDymUAmCCAmdYbgctDpcDLWiN4XgD4cUHgV3MXOJ1PozCp/eXZ9OEvGrrB8FkdF8A2Ir6GfCFwq80pTwAAAABJRU5ErkJggg==",
    },
    "U8": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAQCAAAAAAkUZAOAAAAgUlEQVR4nH2PIRLCQBAE5/IBnoGCIgaTFDaCylsi7wl5wv0AExFJ4ajkMBie1DEIBDdru3dmN6DCBEmqSvQ7l5ligKTqkIhu/wpjZ3gDJMPrBOyNcANaw08J3u6CeoHFCRHI5onjBNyNsIsfyIPpiPmnI/w1+kZ6rXo+ChHnMQOwAb+lPCH37dtNAAAAAElFTkSuQmCC",
    },
    "T28": {
        "description": "butcher's block",
        "pronunciation": "Xr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAASCAAAAACcZ7q1AAAAgElEQVR4nE3QS7FDUQhE0XVtPBPRcRUwjJWoIjpiIjb6Dc4vDCig6U0VoLOi4YJ4A/foIZ0nnumsUUUaHak56+iUSg9tWEnrsM2p4WsqGzeYNXVzf+4t4KqXtnBSm/GD8wM8lgM8aauVmumUHbzmtRfSV74f7vGs25vH37W/c+IfM/drgVVAjNgAAAAASUVORK5CYII=",
    },
    "F49": {
        "description": "intestine",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAMCAAAAADNSFtmAAAAQklEQVR4nIWRuRHAIADDBDtRZDYyDxXrpVZGkGudnzM8ltgBfIreRUiLYMJJn+rjgt61K2ZdHdlYZvkcGD39JZ9Y/KKfsZKK38IIAAAAAElFTkSuQmCC",
    },
    "U31": {
        "pronunciation": "rtH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAQCAAAAAC0QunBAAAANklEQVR4nGNgYDD//3+7OQMBQD1FDEQpItIsBvP/z6hqGiHABFP6/CcBo/4StpFz8IYqtZQBAM6cTmPxU7LkAAAAAElFTkSuQmCC",
    },
    "V33": {
        "pronunciation": "sSr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAWCAAAAADswUOgAAAAz0lEQVR4nF3PsUoDQRDG8Y/TQkLA4hq5kMYiFkHY5vAlAkqEXCFogk1eQFh9BDvtbZM09sc1KS+NJBBQOfA5LP8WO3cHTrXzm/12WKn/QXWhto6vAXotTPbfbgVnDYBPnAdXw8sOvHPwYHAgtwHv4DFuYi4n1PaopjuTt/aSSWR9mrM+L4ETgylE0hd5YlARSzqENPTPDCRJYxaSpIxlGHRBklRwa9HiJ/ynqLfPmr1N/YNfS5KFQ6cIjw7hxiYBNILXq9Ond7i37GUJwOdcf6gzbQfIw0mQAAAAAElFTkSuQmCC",
    },
    "W5": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACQklEQVR4nIWTT0jaYRjHP/mzETUNDK3WoC6FxIJUgtE/FoXZQeqgEDEK2m0QrC6DLp2C6tQhz0EdOljRIbIOQUGjoMhigyiENKuRqPgvrak/d8jSpbDv6fl+nw8v7/vwvJDRjJh6kjiTlUqzam1S4vJBWbWoJa+KD+aiI8BIdO6gOC+hD9U4txUotp01IX0mlmTKLjE+1qpH3zoWF7vyEqpN74anm27PhndTlY9QqZcfEysKFCuJx2W1Kg/RpAtS0vHAQ0cJQV1THkLtdVNUv8tufRFurzqXEJQ2Fyq3DZtbhcumFHKISsNpjKHgJZfBIWKnhsocoq7Bi8R8BVyZJXgb6nIImfMIsdQKWEtFjpyy10Rh856D9sgqsBppx7HXXPiKKDOFkgwKUSAqDJIMmcpeERXVh0g7dwDY6ZRyWF3Bv5q2K9D7WwBo8etR2KfTHakJgDf9vk+Sz/L3JgBB/lUupvpP/wBQkOI/kobupjOTF799eCj6NZsVfC9n3Z61iKP+hY8L/tGsA+zrmOOWFz8RW5QjX4xNvCSWuBmZNdybtqrrgAbQBK6ft6M3bJVB482d4ckP308CMHk//BQY7m4akXDSJ8wbAQgJCQASQggA47zQdwLAF09sQA6Ub53rAN35VjkgH4h5vjxfuOc2taQBan37VVTt+2oBzVLqtifzzDZL4GzWqGQ8MqWbioyjNM6eBSxt2YMr1q6l/BfHjmTYFU46ji/8qTVt+t8VPDNv32lb6iobAH7+vvhxfBtJN/4CRvPa3nMTNvkAAAAASUVORK5CYII=",
    },
    "E4": {
        "description": "sacred cow",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAACa0lEQVR4nHWTX0iTURjGn+/b1rDUpeaMkJxtWQM1ywqpkDCzG8NRF1kQpIneVWTUClIwLzSUSIMYJChWZkgJXvRvM7KLgpXmJDMJFXNNh8LKbTr3zaeLqZnT5+49z+8857wv5wAAgHQPA6Xrsba2e9zSkOng2oDO2eUiG2WhjlhelgggXpSkut9zq2yVJ+RpChF2xzP5eGKuIbBaetHkUewYaTc9/Vm+mi3COpsBgzrp+GahCvKomFBAKUrbCsL0cburfMf6vmQFDw5fhmhsL09wYIDUZHxnfXDthnl50iv7+55UfRvTe/lOCwDQjvOF4R9QSpYABj5nrx4AoGgi6Tq3BKQ4adFtukW6LwMAZCapNUD2qZaIGrK7h2RDsMyyf4xuI9m0cRE4RcfgMEmLBgCEThbikDPwiUULfoSNN7fWkjQrASjvBt7GQPGMr4enkgGIEIvVj/44ZnpmaRUARcWFCeMU/C1SfJ3iqgwAUsZqACDWFPA25yLZzgoAwAPmV/szAcgqGbz8Rfo4/aSDHyIBAHEdXz9PHwAgZNunLHmxkSk2U+LJAZLXw1URAJBDtosAIG8h6XXNOBMAHOkc9NL/Kz9nT1Jka8FCF4dnSHKuOFglVd5zkpTGjGkAAAEIM50F0HHGvTiXfWoxWaa6Mm7prw6+oBKS7IrDfxK1ef2sUQCA2kySLMRKbbHydhQg1pNDjfdt3aoQQm/1XwJOe31GnQz7R6+FAMhxvRGgSx35kRntd5en7voWQjzcCwDhzRN2h2PUUR0aUTYvB7Azt9YlB9b5slf8LM6nCXIAEcrzkgBQsUFYEUAV/gJAQhRFGuMDYgAAAABJRU5ErkJggg==",
    },
    "Z5": {
        "description": "diagonal stroke (from hieratic)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAAAAAA6I3INAAAARUlEQVR4nGXOMQqAQAwF0WGvmUMJ23iU3MrGZkorMYnpHgzkowbfZeouJjSHo/uuJHvOL3fkMXKA9fKkjeHq4w7N+i7UB6tLJOuFFUz+AAAAAElFTkSuQmCC",
    },
    "Aa13": {
        "pronunciation": "im",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAICAAAAABbx2k3AAAAhElEQVR4nGNkgAFVHoseLgYUsLrrP4TBCBUQdvSTlVdEVcTw5wQnAwMDA8MriCql7FReBoYb0z4xQaXl4v4wMDCyc0H4txgYGBgYfP7///9/ew4DLsDGwMDAEPr///9N4TjVQED8//9XvPErYVS0n8/wNeeZKBseRRyMV2T5CNjFwMAAAGs/H2Ls4RjKAAAAAElFTkSuQmCC",
    },
    "O36": {
        "description": "wall",
        "pronunciation": "inb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAAxUlEQVR4nHWQPQ6CYBAFZzdgbLSi8AwWdJzDA9hYUHkgWo03MPEGlnQUHkAaURskUEh0LSCfP4mvmlfs5mXEaNfb02S28BHDxYPbEiAZw8MKAAp76KZRAUSbDdG+FEDKfaRpNgBgkKVKJQBIhaL9xzd17YODaQtAOw00DnsOY452FkDOdsQc29dt7jDXJPe68XlCsKsEkGoX6PXgA+Afrn838OzpiTLqTNgIjcI7APcwYlVfBJBLvfp04inDOcAQ/XHo3L4AFG9N+HRMXZsAAAAASUVORK5CYII=",
    },
    "R6": {
        "description": "broad censer",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAATCAAAAADQCoAWAAABTUlEQVR4nH2QPyjEcRjGn37HHUedPyUGzi0Gg8EkmVDqBoMyKeEGq4RBKUeSRTLYJAMZ/EmOBV3q5KJIxO+mO6Uw6fyLDB/Dz3HnLs/2Pt/P+z7v95V+5ayeBoBAbZEyyuHbfz/j9fEDQgMt9nQgb/iTt0kHl0F//UQMDryOP0QXHM5KInI8LqnnDqKu77fcYndpUeMu5x2SZCNyMiVJmokTLLCQmhAAYav6RaRlGJEkI/v51ZSW6tK3m5LGBiVp9bNviHjCTp6iUaBfknWJzUzIIhCzybCq1u30O6x1SnJHXcaBaZoXL/J+9KYCzrk2SVJ5s6xuTwAiZZISQd2wV1IRAjZ+uopHINwkrsN+yX4LDZKqgJuk0ZWnYHJ1tOJ5gIUcSXI+ASn5Put77La7k5ysZGR+J9/nIHs9+OOkjsgo39+gdBUCxv+IbUv3X6aGrq6zG2emAAAAAElFTkSuQmCC",
    },
    "E23": {
        "description": "lying lion",
        "pronunciation": "rw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAPCAAAAACt9eKMAAABAElEQVR4nH2RIW7DQBREJxf4krHJgrJIbi5RFhTuc5SZGgamUtjCZVUVkgO4ZHFIAypfwP2+wCtok2xIhnzNaDQazZeucABY6xGqAXzdJLAHLps4Zkg6MD2wJbaMwQnVRCr0OjR16crqXhXZKJT1ugQcLyxAriVluhCB1DUmmTogdZuiGaQ4cugBB/C/k3NVdlsDsIPeJFnv7jnjW2AojdUAE1PRV4EkhRF/KQMBSsF20Es63E/uEK87rPYjAONG5rAo0vT2vLRZX6enpUma39VK+mn1ISk0koXVPnOD40NsQpP+GYvYarbZJGm2z7MkneO36r69+5JfEoYYb2rkHr9pfNPFU+kb6QAAAABJRU5ErkJggg==",
    },
    "E27": {
        "description": "giraffe",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABYklEQVR4nF3PT0iTARzG8e/e2WxTEzFJBP8Qu3gbuSQLaSED6ySkeMjwEKgFJYp0nRfJezejbkGxokuXMRaEYsc05piip0hrgsRk77vXevd4mO7VPZcffPhefsD4l9At8Hmo7H0+8e3m/UmjAl1pSdt/5txkIJdJS1/9FWj+8P+jqeIdN4lmnH9SIeTKsiVJ5rUKGO3fB8MpZLtNAxBTcdhtDgEftU9dKZ8S1fKks79KfgTuVom50Xf5vESCkXuc2Qs5O5/3e840JixNba7GbjSeNqP65Sc4s7uX7DuRx/ob8kL3krK9ZVmU9NqHn1davgLAgmTaL6Px8HWVHp7KyoSd0/pzKQXAvEqztCYc2fufcgZQF8RK8nvojXx26sAArj7A8IMVt/A0XDz5opAFDIdLP5/VAF4o5QHH+7Y4NlIDPIItj6DFqL/QFACmC1IUuJ2RdfQuAB1pKd8LbXFJaxGOAbStkfih0QEuAAAAAElFTkSuQmCC",
    },
    "E19": {
        "description": "wolf on standard with mace",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAAB7UlEQVR4nG2SXUiTcRSHn/f/vu/8WHMELvvQoUE1iDIQMimm3VhQUDddRBcLIYICCe0miG4KpLrowygs8KKPUY6oGyHoC+lihdBMw5yQk2RGw6y21YbbPF1sroXv7+qc83AO5/w4AJg3DrNcCkCrPWSzYKA85xJSb0UquqMictuyq+HCo5jEvZYMjnyXB8uKGgDm89afQbL+l0Z2Tkqoay08m2ts7vz6aTgau6YX16s4OBbt2XY34VgZvXgzUOnq7CkOPH/8SWRN04jP9nlaiSRVa/Xp65k8S/cq8KWy0r2iyuGwO+9JYk+hLXcMaHy/V07m831xCe/UAVROgHbHbN4yCL5ho98NoMwGqNxhFFee703j7jIA7k9soSUZaFoaiN4vkmsB1Jmxs267faKfRQwTIDcI6nGbjkZtn2d8P/AqVG6OD4mxq2MrkLwyAKw+NfUhJXlNR2YKkQQ1gBpp3p7LOLv00ae6ls0ZXk8NDJd4WRaTWwUD6+Iir9U/tBChzMyHM32glSCxIUvnDVJ4m+rLXwZcbN6AZDDKFTAZQmnAunfOh77fV4/WM3VHD/8a/QZsCvxQQEVocvHPUJ1/gfW71ezHBEC44xIATu+JA1WYCZE2LLUqKdJekqv/6HzCGuk6L0asUfotqdJP+wv1pb0ejoevpAAAAABJRU5ErkJggg==",
    },
    "G5": {
        "description": "falcon",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAAB9klEQVR4nG3QXUhTcRgG8Id5bKyvOQumIZrpRYrByGYfF2VlhNZFVwVJHwtF0sSL0nRIVNCNBMnog8CEFFNEKmiyQpZBjEAb02BNd5wOycRjlpQejWZPF53Ns83n6oEfL///+wIwD5D+PVgjG8pcf0g6C9YwywT5pGqeYla8LVC6kwY3WR5v3ycHtciZoTy5K85OnhILTJKrodQnmuIwf7o7ryIVOE9vTqwlfViZk4LXoWmkd3ss9ofe9t7QA8Jtfs6MscZAgrLqpeHBndG23xOppbwvRJk5eCBctW20RA92vUgM170BcUuUFS3eXBfuFvakqy0lEKrbqHRdB59tUmPlEkeLNQo6eUtt6+1kyJatPDnL42rsoEx6m9MAIOHc3NQxlR0aqWP5A/lrrQEA2tip2jLv09nFJhhs41Ll7mQY3rB21YzubV3NAO6Ry/3Vm/Fq7AiA/7+bSSyZOKEHDgIOj62v81dWa2Fk0Dfb+/sKzkhNflFnrFkg6YrcZ5g///6oGZjPuMhHSch3kmxYNZKkQzC+5mM90t+R40cV85CUe55eAAoZOgxkSGSfYn5ea5FMAIDLK9O5gHVpyCoI+3K5vCMVmfqt9Q/dlNGaUt9e5rurrdLCPMRIvtntpwFdC4Mvnzv4EcV+qjJWrQEM1i+cen81+x8NefO2ZVv93QAAAABJRU5ErkJggg==",
    },
    "S24": {
        "description": "girdle knot",
        "pronunciation": "Tz",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAICAAAAACw8NI0AAAAkUlEQVR4nI2QMQrCUBBEH+I9wgfvYG0VsP9gt2vlGbxA7mAl2HxY+4CVpdEzCB5lLCQYAwGneNUUbwZJiqZiIlUTkkRIg6ZHcfASPuhIMW/ztk5LMvvz87BaZ4B6A1x3iwxwf12OLSgArHSSpJS+1OPkACFmU1KjuLzcej0LKezDXqwrLh9NsCgGVsJ+J/DfIW8oSnl9v/WiSgAAAABJRU5ErkJggg==",
    },
    "W19": {
        "description": "milk jug with handle",
        "pronunciation": "mi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAABH0lEQVR4nEWOMUtCYRiFn/v24f0yIpVIkJQKxEEURCX8A61RRNAWteRfcI2ItrZo6Ae0NTQFLoWERcstyDLvcEW7pkhCNjRkgxc6cODwLM8B2HgfuesAEG1Zx1Y7CkDJKVBwSgBUikCxAgKqD/QVCIwEkBEI/xHg16uAGQCCGgRek0DyBQRqJjBRA4HyDBAqg4AdmmYqaAMQHq6x+hUGge9OhFhvOHYcXEdu9j1XM7+Ua3vb1T7tej/ij2dWfMx11tzROQ3g36xXT6v1LT8YWauRItV4yhtGezJQ/YC55c8feTNbXaVUt2U+Y94eAXB451MXyeCCX4xBJnKpFoeJThNjPuHGIH1vZ8jYD2lAbzvWueXsagwI7K3M9q5OBvwBJHJV46ltLewAAAAASUVORK5CYII=",
    },
    "T30": {
        "description": "knife",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAASCAAAAAASvfPJAAAA4klEQVR4nIXPP0tCYRTH8d+lLfB9tPUQrpKDi44mbo13EN/CA70IewdXXBTJJbiCSIPz3R1KkIIwoqLrUMG3IYue+8/fdM7hw+EcD0kaTe+vVRQP9Zs6lHqb98FjvrsCGQsAQ7+R60KQZGwUvwITa3Ld+KcwNooLZIj/WxbKGcs/KGOjeJVNQ26H/r8+b2n5Axyo3fvrlguP72CzaCtFA3d0YF6Ap4W7UzBPnnjSwY01UsBc8lL07FNVSae73tNlt3+eVG7qW5B4KBUzVd64kb6CPUy1ZwIlv83IBQB72dEI4Bu+M5DTlmag9AAAAABJRU5ErkJggg==",
    },
    "W24": {
        "description": "pot",
        "pronunciation": "nw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAARCAAAAADxxHMYAAAAe0lEQVR4nGWOuxGDQAwFVzduhk5uiGhCGS7ADeACTEIVutCdUM4jYMQx9mb79JkHoRuBgRrJZAChdAUYXA4YDyrkzUT9guQ5dwkWRb8ILWVg68HGYMJuT0Xhh/+g4d2cVnbGHozsINX0Kp1t/OrlGHxmeAMvWJ+5eVKBA5drPMoHNIzPAAAAAElFTkSuQmCC",
    },
    "D52": {
        "description": "phallus",
        "pronunciation": "mt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAMCAAAAAAvlEAfAAAAzklEQVR4nH2OoU5CYRiGn/8YDGwSCE4JOi/ABhuj/PdgZs7+B0chcwdQvAcDCQIE953NQSNZqRAkncIGbLyEgwIi52nfvmfv+7rw5EmJOWATdZKP2e5w5mPAc0rMrzfW8ur4eVsLZkpZ2EsewCTJLBUKf9JMSgIOnuurm+JPRRI5cH3Gm5Wmc3hs+6+KSwOaixJQ5vJin9IbvM8B86//DAYgdKVuALiTnZMAqbnbFZ2XeqwJwJAMacD9devzgWpGG4xkkmkdsqTGRJK+33Jb2lRVknX5BZsAAAAASUVORK5CYII=",
    },
    "O4": {
        "description": "shelter",
        "pronunciation": "h",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAAAAACVjBrPAAAANUlEQVR4nGP8z4AVMGEXZmBhYGDEFP2PUz0F4i+Qncb4H24vgkUbe+kqzoLMQfIwkvqHyEoAa4wI7Jyz7sUAAAAASUVORK5CYII=",
    },
    "D31": {
        "description": "arms embracing club",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABiklEQVR4nHXQPUsjYRiF4XueTJzEHScmkCBbqMWCsiksbIwiKWwstxQLu/wFWxHFSktB0cpfsGCrWNmIiLBhx8Yv0DASCUJi4kzyzrOFFiLs3Z2rPAAMH6uqHg/zUW73TVX1bTf3Acuhvp6fv2q4/L6nGqqTrjup2pgCcPbU7HuzswP7RvccoFTX6siO6s5IVesl8A60szSn29s6t9TRA49VoyuyHhQKwbqsqFnlVK9THN7D/SGpaz2VYrQVoRFESrQVFSXTOInput88NyI+aWQEY8OfRH7IrkLSIK2+GFrGskwLjNOSi+y8YGEZtZD5wQs5s2cEgRhBZuwzqUOPF6PJ+IWeRZ3xp+Y0xb+jP/wi0+2ncWneuZsZ9X5ODMaZzfRdU559SottZyiX7CyW8J8lvIJKfzfldvsrcBXa9CCbDsa0ls5CD+GoFq75N33Orb8W1o4QLjcegratareDh41LrPdff9f4/gsA4Uv/gURZpJz4BGX38dEtf4IFyedlAQAbgIJUkAIA/wDx/q9sEcnpbAAAAABJRU5ErkJggg==",
    },
    "H5": {
        "description": "wing",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAALCAAAAADdUxuZAAABKElEQVR4nG2QsUsCcRTHPxfSNRxGcENNF8QNDhJN5eCS3FBo4JQgQYQQOTY1+AdIQwQNIS2BQ0jDDR26REtTLYcQQd5yNwQqNXhI/H5NDaeY0Xd57/E+vO97T+E/aUvsGuYarhc08ECxduaijrUwoVRAyviokq5ykx+lUv01rDls+qfph6tNfRtUsMVFwkyYxl/Pal8IMfArGpimYm+lXACMWQBix4CWiQO59dIiPJYCYlBrT+01Mc5c1pPFzGoyAFtM63kQxXRVCFHQIn4G2Mc+oxWSgpxsF0Mog/Okt+T1uz6mup8Mb/l4RUjpg3MI7rlUa+wVu2xEVIO7jgy8UNzLr17v+83DtimfrITx+tBZnnfGJ1sUDCpZ/QDLwtBAO3qBfKc/+csPY1B5KGwXMBkAAAAASUVORK5CYII=",
    },
    "E28": {
        "description": "oryx",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAAB+ElEQVR4nHXRXUiTYRTA8f/7bsoqXRFSXWSSmbMEsZIoL6IaEVFbTCjsAxtB9AVOqUERFWUQdmEwL7qMwsuu+iCiIClRmsMx3RbhhWxkSytzQ/e9nS62FcXbuTv8zjnPc54H/kTrlJP/hOGAe6x2m8OoZcqZn6NrHZNhk4apzqhvZ0/a3V6ugdfk+73RD+c1D9z+Q9JyV9E04zsRuWnQtLJekWSXdh82EenXJpYPi8hg71ZNvC4iIuGNGqRezszERPKXtPp2f0s3WeYk1qJhpqfxG2BdzPfvMZv/eR7FveWqK5un9ZQNRe+Z0guAon/vD8RQhOeRFaG+iLJu3xJLQ660bHKVt2dI8aqLrxqOPLOB+e3SqjwAOVVJnrsVPUtd/Rp0F+L7afTXlM6qBpoX5EVxnYnZvSeih0v46BDUhsVbTE8vTPgyF0tYHzJjFcmXLjCyA0KdY2VIR2VmWed028qXUETl2IACc5/LkM3EjPAp1fQbafQDuAYqJPt1vu/k39+3SQJvROyFZHXqo09ERC2OtfDw6DS6QtY9a7MGYb7YWB4fN+GSx4Xa8QA4ZOhOEW/LA2iJePQA9kQ3HEy16Qql6+0ShNCkClBhMYxAFbkcAHXDct8IzV88eqAjkaymcjBtKwztktc1oDqzT1TYEExcgeO5mV38AsvyyMuoMFc4AAAAAElFTkSuQmCC",
    },
    "S13": {
        "description": "combination of collar of beads and foot",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACDElEQVR4nHXSX0hTURwH8O+592wuN9xCvaWylELW6+gPVA9aPZQ9jD0EIwwCIZiB9NZLiL1EL+JLYnuQoEAofRvSChz4IoNGCxZipcRt1upOqA3cn7x/fj3cOe9k9weXw48P95zD93eAppohonTbQS80s1tdL3bu2bJDvrnmgS2z8udSiWwZDOKy/d8wPD2qPRtqt/+fpecAjokwj2PkxPUTvMc8RVcAgI2VqWWVxxi4eGe6HaW5HZHpTNQcGnGdRNK773nbp/ECgSLlRpKzh26I2eRIjooB9qxXkCfOxYyH74sN851/LETTTweMPPRoLARIo7QakUyUIqs0KgGhWFTn+cSQDBRcyvFXa9mPW50XnMFLXxRXAZC9iTwybDEIQNlYomXa/a0QvaWlDQVAcJFlBIMYAKQWNvem8OBnbhyCtrmQMmMweP02YYQmKuXvqvCtpN//EbekppqRxeEJp26fLNRoziRSAQHQ9ge4u1L+Y3jcmXpLGiBI/UbThIiqjfn0S4J/WBWbA2P1VVSH/Tw7eWTmgKj+AUD1xuWsEO3gtYY6BkWw/Yda4x3Rpm3PzFee9H1IoHWFf9G2z7eSbmXsbPxv5fUVDK6X2GHzDk1tV+nlaQcwkK1ZmONo36muW1fxZuvTPADI7/yMLHztUQBfn6spZ/UuAOi91pg43AGg66IYcZlvmtqSFv8P+FrfcZUhsZ4AAAAASUVORK5CYII=",
    },
    "A1": {
        "description": "seated man",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAAB80lEQVR4nF3RXUjTARTG4d+m1sQ+LExFqUxtJZVhFIupFFYQBFIEEUVZUIQhfeGFZRQVBuFVF0nBgqDIqMCiEiYhiBJSShgSQtmSWJsfcwNtTrf/3i7mJvpenfNwLg68MJf83qDRt40FSWvwV53/+bFwAe+bkcNmn2mYr1mDL255xzZ8dS4DzAlOyXA12jxnly42zbs2nTKepTnlOQxAUXrczXZXYenYvdgScJfH/bS/lJ5+KwAO74AtplfVtZZyd1cRAM/VAkC90ZEL3FV3LmA+OTFeY2LNI7l3AtyQPmQBppIfur7qjaQL61fDHcm33wRQEYo4Jf0dCg7XWlqHv+n9EgDLzbD061J9Z42ha662sshgGQCL6sLf93I8lLlnIBTxOMLRx7MvH0yBKuVzxpAk9SQD5GV/DoOAt5svdo0XrNsCsLLlT/vWJA6pALInq1N3NPcBVEoB/zkOqBAso7WQnpkM/JsKnmh6GBkSsCkjCgEAljsNa/Gw73U0G3OnriRKfCkHlVNS2/13hi4nCqjTKyiRNDHmjXEyoGlydqdVuPsHn3xZMW6KM1Hs7ZNNRz4BmpjjfGi53QfAtC/RsN3vr4jPR43a2evtT1OPde+ayQuOJBkbG83FAORU/1awudXvkTyjnmlp5IEN6AhqYXqt/AcrD+7vcJkaygAAAABJRU5ErkJggg==",
    },
    "C5": {
        "description": "god with ram head holding ankh",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAACRklEQVR4nF2RXUiTYRiGr+9zOr90OkWSXJoKGUwN7M80UXP9ECsKJAqCOpDoBzuqIA86MOikOgiiqCAx+vOHIilSkVCXmIVKRoUliGaODdacm5uf29zbwZzOnrPnvl7u53nvRxLTlq79lem+mf6OUlP6+Fv7np2p9p7OveUG6fbmClmMf9eVav1CEiGUQJ8nP1cK9X6VyNiaMD81ZsgtuLgWWOy+NWHdmKl4h6xEKu7pouPD4xGfu4r/KumGaC5TYEent15ZjRp913Q9pwH5lbi0ihzxngOTEUPL0eyRvxUAaFLifbOwYdZ1b40ztSgjbbL1Qu9BiwDkfqtlC7Qoz08GbUnGNDwMDm9PA0B9Z+sDHg5WQ9XcR9GeQ910Xhidf+kB9FnAKbHPIX6Wm/3FAFxxqmrfmwwA+bov3zUX6t8tKgHkTwtabaY7CSDV1DOT3NxkiCMEIDdODgdqTowCJGwacNjSp0UhAkBuP9YUDC+Eorf6v2XG6i+HW83ZbWeUO7onKqCEXDTkuBKSXb6lJGpVIR5oAbOrDKgNdh/SRpL9M/pMNGig/vM64Kq7JKzL4HZP1eRlvYihwmYHjJqJZcRQSmjseMF9fbE7BMT651ZiNzlMYBavA3cBWiPnlYFhaRdYHh3WOAE0q65V15UMuo7xQoA2ezQqspUBOiMAbdGG/BookcDzIyzFRCPv0IH4FY/f0YhFXeQpkjwWjeIKrMt/EYmRWRqAavOXm2JJiFmfmD2xbF7jEIEFERRCVVV13qm+zwHgHzh+4yhv76GUAAAAAElFTkSuQmCC",
    },
    "D55": {
        "description": "legs walking backwards",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAASCAAAAAB6TnHxAAAAxUlEQVR4nGWQoWrDYBSFv07URAxWWTM3NQp7gJpWjto2eg8yyh4gTM1Mz0TFRRQmOjkohPoM6qsWU/NV5A/8aa869+NyzuECwPjDjKsZZbXV/RXeqvp0QUtV/erTyVEttEl6OFOfWWoZ06TWHJJGY5xqDTDX1wjn3brVyL3oqk167o1VUFXkvtR5kFPNI49pp9XPVt0Aww6v4CW/SAxl2/tBsWB3uPt9/wNI/oEfNt8U7Z9C7lvYBimz2+EJ9muAlNXp4RHOz/lwcWKvW40AAAAASUVORK5CYII=",
    },
    "M23": {
        "description": "sedge",
        "pronunciation": "sw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAAA30lEQVR4nGP4/////3cd8gwQwDKdgUFMLeTv7AcMMMBqfu1lPgMSiP97BMJgYmBgYGA484YXmXv/PQMy99tPRmQuAyOKLBzQjssi+evDXyibWYCNZf+7SxcOX/3LwKBta6AnxJimY2B7Z2kcw6JolcMXrjAwMPCoL/n+9+/3Jeo8DAwMihLMDAz2b9/aMzAwSygy3vtw9cruc+cYjIxcdbQFGCP0jV0frwxhWBMuu/vsRQYGBk7J2t///v2uleSE2T7537/JSI5RevRICeIqBgYGBoZ77xjuIXHhTifJgwAvEkZPnZ+F6wAAAABJRU5ErkJggg==",
    },
    "A56": {
        "description": "seated man holding stick",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACj0lEQVR4nG2SXUiTcRTGn/fdu16/FupscyNIV9N5kWBiRQ4xLSQxKMrAMEijQZCGlRRDvSiMylIxwQszMdQs6kIwNAPNr5rpujDzI3SpS+f8aM65781/F658Lzx35/w45/Cc5wCcyBjVDC5kYac4aXjHonDt7E6snJDeD/1LzbQvp7dRgBBW9+FEq5cAkLMA4nL2+djxZc9dyejETBmFmJumTADPSFe4r6/aVRNY4F5IgGzY3iIBcMRAlL7GPJsrmn7lGLgwNJ4qAIDXHlclAwB+dfrF5To6IPHxGqkVAwDUzi8Lj1iAqtKliSJDAEHbSpuhgQcAbNl07kwpgxhjqTAWAGTTs2HF6/EAgPiV6xn6kvDOvrAr3UEALttIt7xDFwUAdM6f4ku6tzqpTLspA9ge8tSct1szGQUAUOkrVSvZWXMfJ06BX0RI7oj5eVLPkAIAcM58/0z9XIniUxq/yENI/TghMyldbwAAvBuL2rGjoDof7h3xVug9zUplsqRi2Cc7+FoEAMWY9LzFbtSvGg3GVUMOs3UuSw0AOAk16w5yqW3+Hga/ehgAbEGKWWXaGrDZqdQ2ObbNkU4R8j0VwP6xSCakr4Hi+HdH7HRM1dySwE28HhOhud7KtA9s1e3FjQp/WiAQ8gnh/EKhKbtJ7RfXNTHo0Gq+Wl9QHBb8/nPG4mm2zuKYykxPbx2N5j7RMXP28tKP+foEIYADxnxfmQEA67rUOK1vGSAAQOw0l6325zff2/BVvP/XMQAQkSTWJKt48FCWl8Niv3/SGZ4slFWzVY2/Z20U/2DoCV2wSCawbLE95Yd2hS05540dZiZQTolEwFV5be8GACqyPRqAy05ToOgnP0HdjgUmL34D8BdyggjowCyFyQAAAABJRU5ErkJggg==",
    },
    "R18": {
        "description": "combination of wig on pole and irrigation canal system",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABtElEQVR4nE2PX0gTARzHv3fdcrZaE1EQSoWk+TKCJRRNDQ16ECLoDyqClEIxCHq2IJ/qPQjqZW9OIo0efJHYhBZGsIgwZTOW4uYOdaC2293tdrt9feh29X35ffnw4/v7/gAAze8On/qmtp63o64Hy7eTC0uPN7oBQAKA7OlPnsits2uyQzZPtsqRhfh6EQBEADBVug4QyMMhneV9iyh8/Uc6isplH34OwsmpSr5R98Ru81/SNGjg2rlwPh75og7RnU6h7aVJkmXlD0nuhQDg4tX+aWs7UY5/NwtX6qVf74gYL8lPMj12cvulH8OoCJ7r77/ZKxd+kyT3B5xP71h3g8FglB9O1cmY1gngGQvzHXZnb2wXwEfkjLc+SAAaevM6gGLKszbvOZQASC2BVwDPnJh49EIEAAgPVzSSO2/cgnOsZTjFXwNe/K8R3redaM8NrNhOumnSBUvowY02HoMpuLBK5jI6s+ks9UyOXEUgyVDXrOo/71dnu0JMBhA1WFIqNUVRahWlRCMqebXjc3qff4bC5PrnxnuaVwxbSCzKlaVYzJAXE7DCSJO6Wq3pmmZVVZ1MHwFLo8wL5FWmHgAAAABJRU5ErkJggg==",
    },
    "R1": {
        "description": "high table with offerings",
        "pronunciation": "xAwt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACOElEQVR4nHXRTUgUYRgH8P+88868s9OutrqxfuTHLlhJrWSQEWVgheGpTyooDEQiCKIOHaxOHTp06RIhhUQEBbGoxyLRTTZEvBllHirdttVdP1bdndmZnRneLgkrNP/T8zw/nufyAPB/4/x7NYDw2Crn2fEwtqTPnnqafwIAvhjnA1sR/nFjDz5kAOBOweJT/5bVWj8AoFOLAne1i8ApbSh8zR7yAvC8TPycf9MEIrepA0BM304j/erGwR2ZM5cA5cHp2P3XBz6eQFWctwJ1qe7DC5xnf6dMvvQo1GucA7BzMolg3GwA6lI9NVE+29UcuZ3jvHcwCQDoMYggz2hAiMmp7rXEyMyXZfVF7XBVDgCQKRAj4wXQoSxCH25pA+sgz1PL8+UAAK8C3OL7gME1FTjLb2JXNlkDnMwcByC/WofYx0fDV1fSEIQjPF7fxScCgkAnEpcbrg/pj4U/lQyOCGzYVPLAEBhWqcMrAJsCGu1/iERUMkVHEovUprZUlBy5KDiyHTjWoNJnLReoYwu2qYuWZIlw5JycE4gtWT4Rb4GyK4v5omUYOt9MUdetgqkZn274AYAxxpjCFOXo17HC3CGFMaYojDEKUADm5vM+zwTE0cnSd5LSRiQEG3BlQhxiu3NTZCQtu7PH92uauDMRCER3rq/4EW30uPI2kp1r3evK1VktXeZ3Y1q/WFjP73bj8vb3K0aiTXZhtXGaL73rrCw9WFIHvef3ozkYWsB/0563HG4W7pWM/gIZ7OMhznJyYwAAAABJRU5ErkJggg==",
    },
    "C12": {
        "description": "god with two plumes and scepter",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABvElEQVR4nDXQ32uNcRzA8ffzfb5HrT2bH8fYduws2zHMmaJtmp8pLkhruPFjLpQL58bihl3IhTY6JTeSiRsUSRlF0TAi2fw+Vup0tNjZcY5T6Hg854fn+bgw77/g3Qv+Z56W73duApgANCdF5LGGSPiAC3TPSJQSVZpt0cMeUN1zecFYvpLFcWkCuJra93ZVfKvaG/qtgED7YLmuCOUVJx0FbJ53Y8VQzfgkZZuyS4Dj8kPOxAZM7fgAjMDreP1+84qr/s1IKX1hRxQL6MyGwbolud5wKbVBgxRhzdpYbXejV3VQgzMB/vTGhqcLXyaDCv4Y8Mq63nrOO/XF1IjpYvjUov6MpKaJKu+srsM//GBL2XS3qwBtjtyeW3GsuefDyrtvLo3SFBfpBeN5hOinRy9UZTDSf6SVjsB98rlvSpuMDtRfbFuanwDPRWU+++XEnEOhoSINXtFQkyO71Vjf0Z33hPm5n4YqjGyfyfmPtV8xxPFQPMy0UOx7No5lvVNoYsn1wzxJpEFKBhoKBmSzgOFzUaCmTH4VOyxRLG+cPWX0fvUudMu14Lo9AtTVLFP2WWYNimfbtm2LSLydvyX6sNBhj2HKAAAAAElFTkSuQmCC",
    },
    "T35": {
        "description": "butcher's knife",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAeCAAAAADBFYthAAAAjklEQVR4nE3NPQ4BQQCG4Xe/2TWxlfgpOQGJOIBexDXsRZxF4gSOsAkJlVKp3GzFTKydUdI87QP9fWjo7ppLxepRFJ7ric1b8xsZwgCCP1tAjAzoMOsFdEzSiDIDqPYCne8CvfIpyLkl6FkuEkQ9AWE+EeGiRXhsFIGI8C2IEH9XRyAGVBL5eO1T7HCbfAFC4SqNm3qwfQAAAABJRU5ErkJggg==",
    },
    "S21": {
        "description": "ring",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAASCAAAAACcZ7q1AAABIUlEQVR4nEXMzSuDAQDH8a+HHIZSpLyVyEVLS3NQTsRh1KKWP0BuXhbNydVLUnJgTl5GUTahHCgl8pJEcbGEg6dQ0zJ7EPFzsOx7/By+ANgczpAkhZwOG5AG4Jx4qZ6PkNtWmN55CClAw3ZkJ/qQRbzobIrFjg/ApYViSfv7kte3JQ9kunVSIGuiGZr8es85Vi2Ve1aHrvnLE1P726DRUjaUf1WesJUecoabkfrk47859T8ZzGzwmLQLRncNUlrjq0lLhR+D76tMb9J+AIOaOz6TVk1VKQdav/b/U57qx0+pWI40qjdBGbeqew2AS4ezmrYDuC09n8sDBDU2Eo5K0s2l9BXIBhi4v23sDi6tdZVMKlyY2Ng33yzTNM3YUdAO/AJ7KYDGA592XAAAAABJRU5ErkJggg==",
    },
    "E3": {
        "description": "calf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAdCAAAAADj60EcAAACHklEQVR4nH3TT0jTYRzH8fdvzunYMA37g5hlSbHsICFlRkFQUZIdGosyVpfAS38g+kMd8pTVILxFRBAd6pCRgtRRyYV/GhYI4czMhFZIILaGTdN9Omy//aasfU/P8/m9nj+/5+EBKGqaVfzKoCbKyFX+nmGpd1rKqRoVckxKUmtO1qt2yiWpNAdad1uDJ6mIRKQvhyo8/1FG5xHlAzjvr24A2j6FhsxvJd6EAEf3GEjB9JirI+EJZamnpXaI7e5L/eO7AJw4OGekRi3YTxUm9KeYphG656To3mQ+tiPbvsalzzjpSsxrzA481OZs7JvME63XAPArWpSNTUqRVHOPPkLcn009kPTSlmwHe7bWYLiWgi11AGuBNynGXYLumcRS5u7fBswD39PZcf2VF3BarFJfgVlJPiv8LQ0VcFkhKxrWDZAknz2d1YbZXv1+kdrpmbwENgNFq7m1EJAB7oytPJFU7F9+Ua8l6VkG2yDp8Yhq3CW77rU1FBccsGxHBlufjNJH3JjBbBa7zhkXYF687QI0G0dZXpKXKak51S2TwkDdstkuwQf6YGOq3wJNwACAde5FkuCs9XAS+glg12KHzpsqr11qAUZNtl96C2CT1viqTPZcihdC/bzuAOCStArAIR1LL9kpxSqBLukcAK1S8um8UDDfVFVSrBxgVFoJcFH64QHYJ91MT3ZaozsBNk2NHwYoCby6tgKAR+r3AP8AE2Y5/blLV+4AAAAASUVORK5CYII=",
    },
    "R3": {
        "description": "low table with offerings",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACUElEQVR4nH2SXUiTURjH/2fved9t6abiwtaSyeZHfkZfEElgKVgJtYssopuIpLyTPugitCIJCoK+LhTqJoK6qJsalWIEiaA2W5SD0FZZRkOtpbbi3fvxdLHN9lbuf3f+z+/8z3Oec4A0deiqTqSpakuaydOJ4J1v7u1x/1TeKBZXnTzry1AGcEmjXnsmYM1Hork9BstkJHYV3mzXGwyWoVMU199vi+YWZ8jIK7oexTtjrDFDVQRAAgCIJk39Twap+yQQAPBgZLCMpRFL3CUuETCxLPACBXAFS+bLAof+7PX4iei0DeWjPdw5dBzWYTqCDZGB0hSwOvzr5YsQnQQu9krO50dhDwxKMHdSe+qU/Ss6G7Y09ewswE+HTiqwNP9EHHKfoicJR8WNCzPfP5yraUSsahVla9hbFAHwOcyThK2gXwEgmMvBUVXl0RCaUQEIEiWJyVfH8gHYEcbd6XjlpB+PPx3kgMcjpDq9TF15qBh/KAGvfS1PgJyRH06UjL2tS840pxAHGiZWLrc94oL3rOTsVxyl5oH3XvcbMZGQ0y3rREQ6pUknIl2Z75DAIJ1p65qwEgAwRT7VK+24PWxPLGO7164LAZVfAt6F4W6L1jfPNy8sG79eyeLi1mXPYtlJJ15tzY9YNz0QWOIhx8da/NxVQ9JhR+JabLbW3DpCPtXCAEDV5rjFy2rP1wI0wxgAsLhs4THBAgC6mAsAV3mrG+F7gem//isAEostaNpcCqKn69k/5ZQ2TvWB6NqidYAPz5kQ7c9AqN3g0OUMBG5V/watkuEZyFcCGwAAAABJRU5ErkJggg==",
    },
    "Y4": {
        "description": "scribe's equipment",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAeCAAAAAATRYE5AAACEElEQVR4nG3RS0hUURzH8e+9Ha9zZ2B8pWIIYShkGUERQS8i8lEuWgzSLFxZU2EELWoh4kKL6F1kCT4wWmQjISRtEqOCNPGROQWhlARTmOWjuTPMpHdm7m0xjwr9r/78PhzO/3+OBNn71YdRAMhNW7s88z3Wk3XDnDuVB8C+0dlp/V1pLK8f+DnQqA0fBA7Pd1cVV/TMbgPAdNdPuJpePocszy0VyBluFQBtkZq+qfJBJ2wK7gWgYSoDwNrqzah95gK2e7cAULuQC4jQueIO/Uc7cGJ0EgCvzQYIAtUTfgdA0dcwAKFlCRDgfa2/BQjLsTklCUAGJFYpGYhIq5AMrorKMWdO6kpwqOP9zqFGJfofCBgrT7220HxeV8xYZBJv7E/1ydvK9WjfA5AsVmtlsMRqTQW48uhI4E3mvch92LO46PMvab65LwKQU3pr2tyOaiAtfPXX76hiKayNL/X45M4Wb8GhTNN0d6bv8nV4FBEf4rNydH5d18dLpnq54E4zhhk/wbfxV/mlSy8MpA3aYHq2QQJsWUPGzKd8JONJ7oXJcZGEQls7s20HBFJX0+hpT0oStLQzloLj8wZmXt3NY6pB4vKRsy0l69WyIuQGB3Uf9CTQqZUM9U5vBAHymshfoKcHAOPujq3d/WX/QOK53+9WgmF5JSwRCkEYQeKT41WlAWyOCmDGnowD9osyQNT/B0CnusdL1xNuAAAAAElFTkSuQmCC",
    },
    "R5": {
        "description": "narrow censer",
        "pronunciation": "kp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAMCAAAAAAvlEAfAAAA/0lEQVR4nIXMMSiEYRzH8e//ufc9nLfTEYOFjqiL1OmGd1IGSpRYRLpYDBajUZlEqRsMJuMxKJtSBkUmpXdwSleWy3Il5a63e3gM543t+U6/+n/6C1GtAyvbAsD7elnJaxWgq88kjjMSmZmetazH3ZtecCjpmDp/bDESjs7p0McBIL3ZvUp5vxo/hIlcw3M+M3mtwEjq4XQsIUDH1g7wMf7CX7neUEC+LyEYcaD/ahAg+Xx08gVg3A2vc+oXPwXhMELqfqi2167Ti+6/RzTqsfjt9bSvACSZL3Ax37wc+PXmEHepEvHJ3QrLN8bMYqlmTNFmVBuUbAhjAqtRcGZFP4jXR28hV7t3AAAAAElFTkSuQmCC",
    },
    "M15": {
        "description": "clump of papyrus with buds",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAAB5klEQVR4nE3QTUiTARzH8e/ztI3ZoDeXBhm9iNXF6GKmQwys6OIhevEgdIjYYUF1kSQIykMJhV5iYWW3VIigoIPS20XT2QoqWr4wt9Y2mc0t9+Kenu3x30Fb+x8//A+/3w8AeiQViEQ16QXABMBsPnglU3vH8puS82UdtMq4FQB11Zzr69Qmw6WV/pVrqXviPt5cb1qDzZ2dFx+LLLVMiPTtBaBrUmTmYERGysYf9YvvLByKSZ99Iqg8S27E98TaLHJa/fWDRauuim4sYey58RbvElR3y8d5PwNx8IikO+wAnJyWGQbj8F4K7f+S1EfmGIzTrunOYmavf8PWAtjMQw+KZoyVty0LO4z+km5eKlagSj6VmC66opA36yXmMSy5fEXN8J/ifls6Rj40JNM76478H+WoTLmC3sRArmm0bd2aJQKLiWgs9z16TeTYKjmWb7pFROTFWDb8FIDKSXG2fI66Wu+mMz3uQjVAb0w7rw7P7KYh867qgvj2oZ6r74r9VA5bNpEMmcOBSPpWmXr/+Qn/K1V8C0yNHuBN+KXljOnbSuMpVPN0BEwGRBtfd6PpISu22CXg8rzCfv22x2SkrmookgUyAnNfOlGuzw6BLTD9FWprtkHDQ7tiVlYKqKHtAAuVgGPXX/Gw4HvDxIOtAAAAAElFTkSuQmCC",
    },
    "A15": {
        "description": "man falling",
        "pronunciation": "xr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAVCAAAAAAPuMNxAAABTklEQVR4nIWSIW/bYBRFjwsrAxcVhBpUKZsmJX+hxC0ZdaeBqGZhUxVa0F/QmlsqKYgCp3CTTJMKqk3RmDtQZDI58BQ4nqrKSy/53ns6uvc96QtgeEz5h/Hnw7/LDa0OTtr36Ajg+9MdZJUmXLtLyyC7YfPt7HTB6XPA+QX8+voMgcFlwtOP/fsHPnz5uEGzOFFjAMZzV1EbGNpsV2AtSmZG0o1SqxCAgatuNhPFBGjBQZLrehyHENrM4kHLLVnUsSXECqO827mepFlb5SkQEauQqp+0qfKoccJk3rw+tCmBuWqVN2oIxLM2aKpM80LVBUBSrUtgpRF9unX+qiu16MVwEXTl8BEg6MWWzd4Wqh4BNsNe7HdnVWtZqKNebNReNVRTarXfjQigUKFSp/0UQJhrAbWWg/9TJLU/QU13QFv9+0k7FKJX/Te+jX3H6wURp+Zup3TCyAAAAABJRU5ErkJggg==",
    },
    "Aa9": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAICAAAAAC0BQIJAAAAT0lEQVR4nIXQMQ5AUBAE0LdIiPufUeEEImIU6PyYYrLFKyZbYBu1Mu1RUaRplJB46isJazrSJDcrFVJUgzh1Bj+bejE89zJ/gCPveH5fcAEd+x7ZdxGe0gAAAABJRU5ErkJggg==",
    },
    "E2": {
        "description": "bull charging",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAbCAAAAAA1sqIBAAABS0lEQVR4nI2TLVIsMRRGD1SBZQPoFr0EthPBsAHMKyqi1fhXQ9UodtAoJB7JHqgxrRDXHMwTSfd0HiPmmnSSc2+++9NQTAfOsOx0DnZmuOxsh3zi+qJSf8r6wxXA91+A+5uyY/uE7xlSCdQDy0bViDC0J+sYutnpHkgCd4Oqw90sWyCFvkKXgE5P6gZgJ7Ue+VS+M4abehJVX2OHGQs3kDJE82aRW7UB2c9QpZXWhT2MC9apTqPh8vwcD1wwSjlCDcjHPozuUb1onYGXj2e2T5Bueaxd+Ln6lfopy1422H1d3wC+H663Zfv1X4V036kDXYyr6LStGQ2YVkU5GDH8wrRftYZa7eQQbbCRBquT79RMar0/YnXw29aUYAzrmgOkBjtU3/HY6PI1FffFdaqX5TRZvnaaFirpa02ujpxGVbbKM8+jERVfflzt4R8f9SchtQmV6wAAAABJRU5ErkJggg==",
    },
    "U41": {
        "description": "plummet",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABSElEQVR4nF2RMUtCURiGn3PzpgUJCXGXwh8QJEIJEkUNd0yagtocmoMLrQ2t/oBwV3BpNQhaakttDQpSapAQCYLqmsHbcG5pfcs55+E93/ee9wCACSQFht8yRd1f3qk4QpnhTZr51jADEAPcwIS7MqEJ9j+tZLIjW514pPncSbJ2dHzF62DUm4IK0c6JVhf3H5liij+1Uld9Zeyc3OtK6u4lfw1WVC8dlOqqZCzwTlX1AK+qUw+AjX5tDoC5Wn8DHNfNpi56APQuUlnXRZLyUcO8JMWaeAujqU/PAMUxTRFihwN/zNn2TBxJ+nGbkyTH98ssRWSRsu8DWx8nkza5k7AADrTb6wkA4qvttn3nmdIApHU+Cw683rEJwCa3Lzax6/ecDemtEY1Y6tjrD4/ZiCSaQwC+WtPY3wkHEw0AJ3yPCMYsA2AAvgGl9HoBuhaVkgAAAABJRU5ErkJggg==",
    },
    "A37": {
        "description": "man in vessel",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAACXUlEQVR4nHWQSUiUARiGn/lnc1zJ0rQUzUMqJuISYWiIRUjiwehQF5tD5SELL0W5UFQoRGVUuFwDFSwyxUoqKaIJPWiWuJQlLiPmqDmBCzr5fx38/9EOvqfv/R74lhc2K6pMHpnZQmktEzIVvwWM+CpS0dxu2egom2hBIsvK/XjbJlpuD9JKUwwv89KeTa54YRKykKmb5N+NtpOr2V4Y/QaR07oLapd8W8fHW/rV2fOIuB8GA7C9e/FTGNuG5FueBSDg2hoiIsNns3yI6hB5b8W/R0TqbJDuEEHUumoRT2OJQ5z3ejNIHu+oWZKG6zVud5eHZblpzamcFZGGZF6VcchVquT1iDwvPpDjonBkOBhDeMJVuz80lQS+Vm+AX/RuMxydMY2iKsjUVD/ASq77iAFYXARM9h0mpzN0zfuh++BeR4IenyVgTvk+uCdOh2GpnvIL80bNqWtjimeAYzpNSayu/WsRze2MWFB4O6nHbs79VYrJuyYytkfBiJ6sb2z9Ih7VoE82zCgMjURoNnT/fGBQRrh2pNVu7FVYda75AGCIs9754641q9qemK5OBR6bTwBgPGedrrrdjWed2tJVA+A31gyAz4Rcgey5J+vUrhaZACqdKQCnxBEJ+6YG1yf9/BwJQLrctUBIp1oIpLkGAMyXV85otw7OpUH+iisDCP/RD5A1Px6svVIkX8K5qPYFArY+VwIEPV06rKcS1y+j7bNyHiDJKZcIaZVib2YkNYnIcqrN3zez3iONFR/mqnZtUIwPRP62tbS1zoiIiOc4/8lS8GJa1uV+V5Sqdf8Bcc3/pNOCdqoAAAAASUVORK5CYII=",
    },
    "M2": {
        "description": "plant",
        "pronunciation": "Hn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAA10lEQVR4nH2SW20EMQxFj4poIQyDQjC2QLgMFkLKoBDM4PQjs6q0k1n/WMrx4zo2LOvwyVp3z1+nDz9+KDCaOG9xNaSvDexaPnBc60d1QIRjo9/UtClhpz4NQzCYzfxTsIhYeOFZqeUhOC+85wqZgtf/jXUIw1Pd+3jpb4uHrk68D+Dv88zc4qjwlJvxo8VhgeNhveOKWZriZjHU08IJ5fYwqs/0ub+b0Tm1bzGj10a8SnvxTsjd0Y1uE8wNr2in+o5T0dRtPpVW5y2nomr2+v8D5icFqv4BGIPSMd6h7o4AAAAASUVORK5CYII=",
    },
    "D61": {
        "description": "three toes oriented leftward",
        "pronunciation": "sAH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAcCAAAAAAot5K5AAAAqUlEQVR4nOWTwQ3DIBAEx5FLu3Tg1JCaUsO5g7iufNcPOGzFh+N/9sOAFnZBAgBccrpUZS5cPdq56lJGzSXVnRlVjfZmoOQkFLo9GaxUzaidBj7FJKNdtdIjo3bacmcpARltoUvjjOIK3wu5/sc2ggNehiO92hNK+qgr22z9sJ3vh00ODCDmrm0CmB+xo1/NZe2HSZF8IBN29juD5KftQy7sgs3kXLDhkq+SZNZYSiQVSQAAAABJRU5ErkJggg==",
    },
    "G43": {
        "description": "quail chick",
        "pronunciation": "w",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABkElEQVR4nGNgYGBgKP328esKTgYUwJzxv8Uz59skVmRB661/V/ElMZf+NEeIMTE8ZvrF8smCZdblOFQjzB5O5mZgWPqAEVU46b8hA0Pr9zRU4aDPGgwMEtu+ZKOIBvzTYe6qEN3+OxlZ1PGbscaXjRwSm19yI4nyLF1jtZuHgcH58wQ2JGHPV0mP9DmWXfj8v4sZydWbtlYWcf+bJDTtXxuSauc7xY9TltYw8Mz5H49kxv4Zdo+P3ZBhEJx/SgAhavfeyOjTQh4GBsMvc3gQztg+m4GdkYGBgaH/iztCsf8vDQjD+OWRCLgo76aDehBW2PP/CMWB/15Mk2Vi4BKxWvcfKZhuqP97u/hdrOrzOweQRO8831fO/nbF8wNHkcPo/iK2I/+nQPwKF1QVePdr1v9fDKig6qkEA8/nKlS17A7fXjAUfNmBqlTt1mQGhgt7mVHVWsmtZxDjWvkXxpcxlWVgEJj1i4s594k4RIiRwaNO9uYFDmUzoWlcPtwLjy77x8DAwKD29D8y+GrPwMDAAADUX5T9kRYbXgAAAABJRU5ErkJggg==",
    },
    "A39": {
        "description": "man on two giraffes",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAeCAAAAABslJPIAAADLUlEQVR4nH2Rf0zUBRjGP/e94/QO9E7cNbACLSHAkiUky01HZ2tFv3NMJ+pazVausLZcaYBZk0XrDySDLSo3M3UVc6IlVN4mMGELsJshNAvuhhADYdLJccf9ePrjyK3+6Pn3/bzP++554N9yFreecPK/2vqrAtVWANei/4zWF5sBVnTHP/L1OwDKPRvSstY4AEh//8Des5PvmADuHbyy9OveBQD5I5O/+8ffAqA0LKnTlXCrjO/uHCgA4JwkDa7GIOlF6/VrsVMTALeVuU1jx1eeKr8d6CfS0L9ikwlbRaBjTf5w5wPJdx850xOTylK6JO/Z/clu/ybjodEfl/CCT/tSeVvBG9PS3OifsaY3g6NtAWl6zPvK8Njs3LNIkt5bFbnyTUP9kWIWnpfUQmbdTx3xvj26PKTDluawud9deXW2+hgAoV/ckFPQU86Csl19U81Nj0ziSFlMrbYGts8HdEhDo3oVAN/h34btmIzpm39Z7KGoYUoQ1pRIjZcIAIvvN6e6kAFIvX/Y70ggeSXR4rx4DGDLSEXMvh4MwJ4dC8xuzwPgPodtcwZO4JlGU28vuYnNB6O7kyr1iRmgSrXb9kW+sy1vDEQfpVrdyxIV6kkyPcGvCpfbs89fskC9Wq/PnFsLNfLeiQWIswz/c0+/0TXaVrSyOcZd2eR667+fhRCJt1inFgeQuatLUheF3dqb78BVePJ4n25sm0c6nAtz7oHk1bUjgdJWVaVkvvyxf3xSkg7OI/49J6T6HQVQIakl3RvX9LdVWT5J784jkr6sCyhcm1MnyfOYFHoKkj+VtP8W0raIokNS/5SkwFXpB4Adkpoc/yADOWBu1C0VAOyUdDHdAJKArHUQmwAI94SAYCLVC0HJAHw9EJ0DLID/+dcmPBcSRUaobDXiBuBvB0sGEAGGT8YsDV/wEpBayvBQussAsreA4YSUtWq7ZsNiftgfLgGcRZhNGY8bQFpa4nCJO/j5lJWbkQ2Xjq5yLyEexxYxFRnz/oRZutM4fTltwhhoz33ig7bTmxn/jPyL4Y0WwCnT9M/tWGeO1oTONMXnDsyEBl//0ErwoDXiObbxb9GPlZicNLQ1AAAAAElFTkSuQmCC",
    },
    "X3": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAATCAAAAACMgMMyAAAAe0lEQVR4nEWOIQ7CQBQFJ3uCBsutquAQX6N7h0o0CrNofH0T3JomPcAqQjCDKLBPTV5eJg+gq85sKWoPwEFVAFbvoQMQCmcnoHgFlMSTB3ADJl8AYaALAM4JTl994pfdH4/71rbBu+EFVvMmk67YA6MLhObI28uxqnXgA5owPwkXe/2NAAAAAElFTkSuQmCC",
    },
    "U12": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABSUlEQVR4nMXQzSvDARzH8fd+flhrshw4MAfWWhzmsJaHuSiODp5KKbWklId/wR8gRU7koLg5EXLYxEF5ik0KiYUDytoD1raffR2MfvVz9zm+Lp9PH9Cn/0MmMcQXfcpuAqDouT29JmJk816gUDHyoCS0mJHTkWQiaGSl5DqWMHJR5UvaaWTJYWk1MsAfA3Ut/8ySJacBoP6QpdFTU9a8XGGZuds/zeaxePjsXSSZkY+USHy3N8/2e+14bqhyRNqcE/NXcg6UD1RTL0ulQI+4AHtQFLAubHgzbMUBEwrwcIACt6OOKRuabtEnqslVsBi2pvLP/e42ja2PH+3ksOrQDLgjWi91sl0LdIkT8IZErQr5+i6InnWET47XG2hxdro9SoDXaRugdiydv8l34kezTabV7hV/BsDhqLAAJJ4vH1H9h+YcADc3utIvNm1+qeRpoZgAAAAASUVORK5CYII=",
    },
    "R21": {
        "description": "flower with horns",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA0AAAAeCAAAAADSwsuVAAABGklEQVR4nLXPzyvDcRzH8ef38/0Oi7TyY6UdFpNkSUnbxcnBaSHFxUW5KMUR5eCmhJscVkpptXLYWtGOfsSknJT8SJo4LIkNW/tsbwff+Q+8bo/D6/AEoPVFy10LoAA8meT14ZSy1X1/uTM3atjKmy7lzJdsfXcGilD5lX29H18VWTPgD2EvUBAROf5Fw76I1qVcYlihJtP6qC+x0R7afF8nmsnGILqE71SuVE9svG6ktuhqCwfDC/irGCttXzynJNIMgONAROTBC9aQNt5Sg1COu7ssI+mh3OgG0lnjCROIi7zKKpgA/XJyu7acGwCg43zRG5ln66wJBcG9lUdHPbM3E1iwq6lRQmHawAJtp3zatX/7PzmqnSbAD6DKY8Rf3f+3AAAAAElFTkSuQmCC",
    },
    "D59": {
        "description": "foot and forearm",
        "pronunciation": "ab",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAABq0lEQVR4nH3QSyhEURgH8P+5zr1z504h03iFBUU0g0SeO4qkLJQaGxaWVkIpC9lIkVKKZCNWpjwTsbAQCyaPpDwWCJFHec+dmXuPxcw0c6/mfovb+c6v87/fOYC2ci/YSU5Ez2mZK7MiwxHdrW1Hw6ItuktxZ7OqEt1VRbRofwjjogZWlnx/aOAVi7aHIYP8bhtS+/45Y6GV/dLRG6fLJ1x4g3Odpnzpznu/q1NDAeomeEIBLq2CV9znAIDnrU6BkWCWCIAivr8mm/ivxicZAOVcZup3wP3vAAgnVEp8Y3He7+GFAPgd+af2vUuRgZkaVnrTXWRMevLKSm01AEYQyA5+cfMi0nd7HZ+o3l4Tef2ZJ3Jh/WLL/hIfGMEUu0MgFgmlj2eUeA8AwDnavjLeEb4QhWcX2+FeMseCj7iw/v1UXa9zYvYwI7c0ue+MvLVkw2fgHYNvq2I0JzlTI9zAtaQdIFQ0a+Lza7McMG9PR24HxkqqKnCmrM4tyID/g2g9pt5am+l4dR3P+ADA59U66emymICledoQA4DRyjWNS9kJAOBsFoLnfpYj/A8Xf4IZTVzEtQAAAABJRU5ErkJggg==",
    },
    "V38": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAAxklEQVR4nI3QKwvCYABG4bOXD8NMBhERxrANg3gvholp3Z9psC0Jq94xiEEQEUTEsLQFGc6i3ZOefIDh+z0EYHY6zcBQ6oQEpVj0CtNpoYcs3xwOxreM3QpvhC1bTjOCqOnIra5hXXXVPz/gce6rvXjCc9HW+JhBdhyrmAKkRWEBWIhv/yEHyFFiA9iJ5p4B4821HZShPNhqWa9Apb7U5d6F7v2i694Hf39VugtqtWCXKo+yRiOLcsPqNeG1whBvRmxi+E34AECTRwH7D3PLAAAAAElFTkSuQmCC",
    },
    "N20": {
        "description": "tongue of land",
        "pronunciation": "wDb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAJCAAAAAB7rAGRAAAAr0lEQVR4nHWKvw7BYBxFz6e0/iREYiA06WQzMXgKMRnELmIxSryAF7Axmm0Si9lbWGhsDEKi9Gf4UB16lntz71F8cfJCiNew/+txoF72UHSrj7B2qwVdNcxBD4CH4Yc1ud1lBcAQdc2wsEwVGx2IxC0hckxGC5qzqL1tsFmnENylRGiXnCqepp1EKob4hWCffXKuY5tXwTexn+C1HeE37nQ073+aJmsJIJVxmlawvgH3eC28k+2VugAAAABJRU5ErkJggg==",
    },
    "U36": {
        "description": "fuller's-club",
        "pronunciation": "Hm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAAsElEQVR4nEXMsWrCUBxG8XO/XKSDkNaGFkEXU6GrhbxGXiEP0Kdx8AXqW6h7wK4NQqHg6CKFDmJIcv8Ogp0O/IYD2WaTQfp5Om1fmHdF0c3ZLeHjW68VfE2FAyEMAmrHMGl99egtrtQA1goARAiAkIB/NDO0vu/dDVYq356fZqWPQiBEvkliksYfjn2OB9UGVqsGqOUA3O1yjQGYHw1bhiOfn/84527/s+A9dd1vQA8XH9g970XtkTwAAAAASUVORK5CYII=",
    },
    "E32": {
        "description": "baboon",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAZCAAAAADsnKr4AAABuklEQVR4nHXQS0iUURiH8WcGHS3SCkmKKO0iLoShqIyEolqFWlK0KFqYREIQFE1kRRujQFeVmxYVFIFIyxa2yNpMVCYRSBdJoYsUTeaFNomN87T45lNJPatz3t85L+//AABLHjTGmH8tPuXHI/nz8uruzEkdalozN0cGn/UWlneph+fSEx8s+vQQmtUblbP8gL4Mds1f1Wtl/3md3t5UEeyTqu0VM7sTvdn4vaeu+hFA7PL2KqDtaeeCyMTyQ+ZMBrf2aPig5LHTKzMeFOtNT7eMxj+PjddSr68YCv3P7GBnbGIoCoC0z/Y3tC6NBV5AeqZ09r/vi3P+BccKAVinW0NbUZ1WdbTVO5wNxo7rk4XR3Oii1z9H1Ezqr6qtoefVnQsT9e/dn8PKMdW3kAhjl6o6UrYMgAuqJmDtaNY3qLote+pRdTdQk62k/JJyJJzxl2pH8FkA7CqmcngqY0ERVxNkpvPG+tzIsG4Ojh1eItLrwSmv8RZc1yoAanUVXLEtq/n3fhsBwvmStkDpDwcAKN7ZpUeBHcHE+7p1PeUDOgjA6ed+a8klfj+VultC3sXhyWQDW945kTwO8A8C+e6gXl8wSwAAAABJRU5ErkJggg==",
    },
    "G1": {
        "description": "egyptian vulture",
        "pronunciation": "A",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACEklEQVR4nG3RW0iTARQH8P/3udjstlEus5vJxlhNvlxrC8SUgZkPYTFy0ktKYaUp9RT44IvVii4YYaAUa1mULBw0cZUXgqAkKnxIoW2EkE7WbunKbc2105Pbvrn/0+H8OPCHA+zSaOqeEhHFm8APU3VfBUx+EsSYo/Y2vgkMKgB5z2o78FcpXuQZe0WhUNRtrTTnIViwFjli6QKgCx7gb9n0+IvhchoBmHvfUZrLWIi3bbgjGeXYVcZWMr2eeWMy+bF+lbk0ui22Tv894zeTKrvnocUXlkcAoPe7irOM7Q7d9LQCwLGlrzuyD339A0E5ABhCT4RZaF44885aBABtkZU+K52HxOTSFwGA3de4hn9XvTwsG/osA4Bryct8PBIhk3Rk6hSAAsfSQZ7V0BuvevvzyNUSQLb8UJRp6nCtzYp1PWFPuxAmjzrTStwV+lktJK+JxvbAMb4po+efgPSDR4cFJwLCV+duaZoyLBHTxsfULATTseudvfWW04VpY6iUZveLwLpd5601ZY2q22nLX19sKFNfKmSdgxw3OiDBbnGqi3JmZp6IJpytovEHjNSciLakrCphlF/83n02VI4G7z7I/eRNfbLlNwcMXgALwObdixtEd1nIjmvzsfPE9D9IN8u4hpNKNCft1T3O0E+0T9KPl5YJin/pexsNuImmmlHRP9f32FeOKGVnZCNEhx1h6voPbETT+eflATsAAAAASUVORK5CYII=",
    },
    "U3": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB40lEQVR4nGNgQAOZ/////+8L4zGhSzMwLF6PYLNgSufJB8LZWHTzcjPgk0YGZEn/wyP9m4FBEY+00s//re64bMv+f1pi2v/3TVbYpZ1e/V8iZf3y/4sd+aKMUDFOeUVFJWEuVgYGBqbQ239frrEMvf7jx+/7kxkZGBgYvKO8+RkYTt9/tuXUZwYGsfB449+9a8VVvFSUGBgYJIq+//83uWrl7f//P29s9uNlYJDJfPa/mIGBrfAvA7/dgZ9nDA5tZ2CTCL/7//+f5wfbdBgYjN+s5GHgXfufYf73/9+9OTx+bVVSav+5Q4TR98q/J72uDE3nxBlS/35gsCm6+P/Djq6P/19/+P97Unb1oaNf/39pCfkylyHh/dNQRgYGVX1+awV2Dq7/fxm5WP7/fr7/0gvBLkEvw0mv0ndBPMbKKyQqDgUCjAzuZ+4bp/x46401YJirXi+Uif69zQyrrNWkTyVKUbcquLBJakx8dsZSbd3zACxynFZnXpz3UC99u8AGU5ItcPv/PREqOT9PVvNjykau+L8vWqr+/sU2LJIOJ7/esFdovvw5Tg5TUnr/szPeGvlv7mfws6LLcRiWH/1/NLT0+/Fadizuzbv7///////nZwtjkWRgWPH///8Xa8OZsckBAJ4Lvv5cHuMJAAAAAElFTkSuQmCC",
    },
    "U33": {
        "description": "'pestle'-(curved top)",
        "pronunciation": "ti",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAA1UlEQVR4nAXBvS4EURzG4d//nTnLZJuVkEWEgmqyPrsRiVIneq1r0bkAhYsQcQGKLVQSha2IySYbYsVa8TGcOcfz4OvY3wGOz4fxag0mN85CPM0g7XRjt40l7iiWnTTW9S2LSwISyARMEKcENLBCwDasC9iMNA248L4QrM73Bolga/YjJIKGXr8TYXlzoJbQXCi9iXpc9m7eRSt/8s+VyFdGCBHCmIjwcQTIlmeuMeT23CNmgv49hsy9/GGm6mFhmnYmLsOhFW8pn1+7Pwd34E5+q+H+Px69Si7RnY/tAAAAAElFTkSuQmCC",
    },
    "V30": {
        "description": "basket(hieroglyph)",
        "pronunciation": "nb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAAAiklEQVR4nI3RsRGCUBBF0YslUIkzGPzQ4BtQAC1RA7V8DCzAwFxbgBauASqDMMCLdnfOvGQz2ZPDLgUatkhQ4qYLGiGZVl1IJiC66kLSCFD4GZYS1WIYK+1SuYTK1Gn1W2vV5q8yNqr1rHwCpygb7y1AOyxFDnC5MmNwKs/HnD4H+sft+bqTfV/5Bpr8RcdBElEAAAAAAElFTkSuQmCC",
    },
    "F36": {
        "description": "lung and windpipe",
        "pronunciation": "zmA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAAA9klEQVR4nGXNsUrDUACF4T/JTeqsDopgsmrBvV0UC118DH0CfYc+Q+lQULo7CRnEB8jQQTAISSHQBqJTmt4UbMi9Do1dnM43nZ9HrddKrbV+Es9pffND68UKDOD9jesLEAA2sOXUYAqYgALVMIf8Py2wGpaeVzYMXDdozjJF1lAU2wGodjV1iPrj6Y66RgMCrzJMjBM7oS/zkdajXPbx00FcFPEg9fkY0smyDsNQIJnVzJBahGdOGVM656E56fYqKated2JGTruWsm7bkbmK7veVOniIVuZ8fLy3WLSOxnPB1+bW4W7zDbifyyRZhh7A1auu/Ev4BRNibv8h01GIAAAAAElFTkSuQmCC",
    },
    "I7": {
        "description": "frog",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAcCAAAAAAsQkKEAAABfUlEQVR4nH2SoXrkMAyEB/QB9AqGC9NHMOwxwz0YuNAwhYWBgS7MIwTuwsDCwhS6bKCXzYFNm6TNnpj0/TOSJQNAkiSlI+6H9WIukt7/Q0WN0SrfSTrZPaOs0QC8iJn9HcpL6g1olBzFfcpR5zIZYID1yvUu1YptmftYL9HtDXUmwxTmJFJTvdPzQKal7JLEl99uviiunGtSpP9NcfuYepI4+G1bbiHA6iwVhnUtMOInFoZCrRfidrfoqbK+58A9ylqVlZcvSjsUJvGwZD23U85RZZ0XsZtIs6b5SR2ldskOmbVjXmTmvPewYXNMT+Ksr0XbUCSpHBw1PHxDb9d1m/bp8/kD3q4fr/FpgR7tgu+D2Z/r3wuqC1xVraSRRKa+vsyUDbFIRZIWhIAyGW+jJzXex2Yck3UCUJ0SSQCpOE8ymlkz6hZ5DBQsSWVsADKrN0sSc5Yk9l04de+lJFASyZuODSzk2YQ5T0Vl8ICnSJIMPpAdADtmzTVNvQfwD4UcJyZNx5VvAAAAAElFTkSuQmCC",
    },
    "Aa14": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAA2ElEQVR4nGNgIAj43O6wEFKjqySdJMWIV4lYtHwmG8OfiXgVxf//////hmoGJtxKnBc8+P//XK4tTgVMPEpFi////zQjECqA5i5Hln8MDF867RkYGI6cLIELMxpzhPyGspn/GrhCmS9vJN9F0sz4mQfZrCPnOThZGXiWLkexgZHxP4LTOpP/5QfuDwwMDAwMer//M/xj2K7EwMDAwBDI2MdgZf6bgYHhNxdU7YSr7Aw/9PIQmp8f3s7IwMDN85+BgeF/kO9/hv86igjZv8ffM37vvs/84yMDAB5SQT4DT4ENAAAAAElFTkSuQmCC",
    },
    "S37": {
        "description": "fan",
        "pronunciation": "xw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA5klEQVR4nDXPv0rDcBTF8e+9QYUOBcHo5tjB3akIDuLk6tAKotAH6NLBh7FoF0dfQBAR9xaxWO0gEv+goimGNk2aXIf83D6ce+Bw0SPLWiWA0nm3/1IHdBo97o9qSwC7ParDGii34erNWV1QBuE6d8seil1vM2+GwpsPgIIlTAQUZv7O1jgH8Iffkw1QSH8WpQ8iew2ClbnTDoevvTLlbtyUp+O1y5ODzYcmbSr3z4MKbUCvZhceKMg0jrTYGOtvDgokJG43k6wQKakV2ddC7HofvLtrlH86hRo6BRI4GebE/0fk5gF/iiVXzdxLiaAAAAAASUVORK5CYII=",
    },
    "S26": {
        "description": "apron",
        "pronunciation": "Sndyt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAcCAAAAACvhnu/AAABhUlEQVR4nE2SsYvVQBDGf3eI3Gu9QlTO5mEhxEaEkN5AKsEihdURK20exM4iFvKqgI3Nnn9AakEw1YGkEIu1kJTbRqz2xGrzsPks9uXhVLO/Hb75mJkj/o/s8Z37t25eP3nxYSGJ1RJB+naoHCQFa1IAI6WLQJjqQ00vvb8W06er+c+iv7sND44id/dg/rk7uXF69ePz6avV94gLSd6aphxCC0z6FHnnLxIAWpfCWorNimlYbI1Auvix+3+SqYs8vhTWkZuQAqk8ABvZiDdhAEgVALgM28hHX0SuHKjCvtxo2uuqBnofu5Zhr3smDYAPCUDmtPh2EiTeRXF1bYhpJ0HhLwBaWeh9A1BJYKYKaLzLIHUjQCbB6BOopW1cjwEIYu1HKLzUAFxKBrA6fvj7K/nreeYJwF0oK/jC8bPVVfWO5y/nRznku49vfr3d8BckN9kMRjXQupzST+dbIWnIAKMexpBA7Z0VUr8GKBUao3AG1F6iWk7FS3EuUHkdjoZOUpwzpNt/Merl0eG284YAAAAASUVORK5CYII=",
    },
    "S36": {
        "description": "sunshade",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAAAk0lEQVR4nGNgYGBg4HPY/f///90OfAwQwOq67j8ErHNlZWBgZGBtTxI8cfwsA4OxpcX7eZW/GZha/18KFWZmYGBgFg699L+ViSHqzXVvBhjwvvE2muHKuwQGBIh/d4Xh/05uJBGO7f9Z/p/g50cSOuPB+J8BDTBWQGjllDl3UWXM/5tDWUxQmpuBG00EAUZFSBUBAPvdLzZ3PjwgAAAAAElFTkSuQmCC",
    },
    "F13": {
        "description": "horns",
        "pronunciation": "wp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAYCAAAAAC+OKDoAAABBUlEQVR4nHWSsW3DMBBFXwKk9Q6uDHiArCD4NtECWsVQyT4Nu5TuvIAaD8Hi3L4mhR1HsSVWPL6HO/wD0Z7V0yvqdo1vVUbNNSF1JFwd0qsBqW1ZaJq8c+K66ZZ4t7lyAkI8LglHMYC9tMUZreEeIGNcSrp1jFu+rCzl6KXehCptehWmhhXe4Zvua/eSo9t9dXwD8OmI5VkoMvp5u9uYfGrROdG8F9UB85/RpQzWexVeKOYsSZ8WLgYPY+DsQ+lTzwx/HNKeoraAaGqh//cLIh2gqKWoBQZz1gAirUGkagZRnzjEqAEHPUDo+MSBmKwDwFCdXjHQndVUPc928jZXfjf3MXv7ASE4t76RBIJLAAAAAElFTkSuQmCC",
    },
    "O40": {
        "description": "stair single",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAbCAAAAABOlmDNAAAAYklEQVR4nL2RwQrAIAxD0yFjsP//2HnJDrOII4U6cDmpz4RGAaGTLlMY9EWRGLDn1hbgpqX4PRrH7aS7VUq6fylGjdPF5Nd29/EhvGMdzoskCeza7cdV4RKkzo4mZcFr5tw3maYWQm7iAS0AAAAASUVORK5CYII=",
    },
    "U13": {
        "pronunciation": "hb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAaCAAAAAAV2cqnAAABRElEQVR4nIWSzyvDcRjH32YiyY+UA7JMfsTRwWYjJ2o5uDpw4Cb/gYN2EyFFyIlChIvZQkm7UObgtHJZcVhT7LDUtPRyQG37bn2e0+f9/ryed89TjwAWZapn4KnVRLkOgbjDhLWlAC5MWNd2Ajg3zmY/SENoxMg1vgMTRqwjmIGXBiNnuwMWq4ycD2DSYleU5WovQKwm12xmJa9tKAmwlm05M4yP5sf7AY6yjADHvTHLFNWPQNz1L6fB5/+07lB+C3D6p+bYdXNipaRBgOiyW5KidE8zVYhS3SoALmmeD0VxF6SkBQA2tE/fGEuyFaZ2JEkzV536HCgSJKmH/xp+SxW9ZAfcO1tmI5DgphhUHiAuSQoB4SKQJwiXv88zCEv2nG/vFypJezYl7bXXSiQrZVlwi0J1nZf10PRNaX99TmfkdV36Ac1JwIMPgdeBAAAAAElFTkSuQmCC",
    },
    "F5": {
        "description": "hartebeest head",
        "pronunciation": "SsA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAAB40lEQVR4nG3ST0jTcRjH8ff20zDackNSMyNcaSQtIlSKokN/1x9irTwUWXixQx06JKSBHbyvjIhkXspASg+1KPpDhclIJjJphZHtksVabqH7yWzxm0+H337bkD6nhxfPw/P98v2yEKylIKs/ZgZtANflUVGeq15JoBqABlW2571FS+wEwDw9zp4cmzYq/oDusTHqc25v5IlemZnFkXNrDYrhCVbk3SExw0ExGb5WSU0ZntYqdhvuIahC/dGmYnB+Ff+qrE9LF86bH+RNmZlP9zKHWotOdl/bX3GhCs33wDqYuD8HKC8l1T8uMh9PTv0MjxxxTdzQF9pDmcUXt/qi0mfdRbU3ct5Y1yZPS2Ayvg1TayjcYLBlSDxnatdovs7X4fTn8tz5N58YWtfv0pRfqdGIkk7m2gOxLetvNx6UK1DcpvqM63v/tADNkdgBAPek3wbAcW2Y8vagKqN64yl5DrCsR5rqJiTYPRJ36fOdi81A5btve8fiHXZqos9KAVj59ssmqBhO/pg9DXD572F9wJm6uxxzx8z3swBsnRvI/oBzqR6gtCz7KAOqBaBkx8VklIK0iwXwPFQl4ip094wD2535hV53XSFTGbq0LyS9NoUlefxb1K6lCFyV9+7/MBu8x4zyHxEhsJYnSA2qAAAAAElFTkSuQmCC",
    },
    "K2": {
        "description": "barbel",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAQCAAAAAC0QunBAAABQ0lEQVR4nH2PPUiCARCGz8pMFAIha1GEIILASlqEECOiRh0CCYciCCFqqKGfIXSRhmqQaAjKFhclaKgsCKLAIaLBaIxAUGgQRAgiNJ8G+fyUxHd673juvTuROlkc8X1ppo4673HZJ+ebUjXZN9+B25bM3DkAWFvlPADf0fEQ6ci0rTnTE6nA9bpZRLwpKB8tWv4x/WOP8KmtxSbOgEtfYKqBeoMyN2K8G1Q6tnAGIB4ZVilIDwSfZQWX2ms7yOUBwmsWEVP3TEigaBbxg6nxkmj16ScfgGZrdFZO2hYk68w2Yla3r+9Xa9Dmh7rSohFnqjoWDJh0ekNnba1iEpxqRETEuzNSy1jOaREKjj01dlsxG2kAih+FH4BSNZ7XEsC9OuC+APxK5YnFvgC97vilQqXuXN1uhlW1bLceJq8mRIy9S8k/W9OjNBlou3AAAAAASUVORK5CYII=",
    },
    "B12": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAACSElEQVR4nGNgQABGz63//99OY2bAApgrvzzomnT2ZxQ2Sd///x81CMidvqiEReOlN0de/z+rovHBDSbEBJcMkzisk7XYSPfl608wIRa4JAfT67YtT4Jes/zFYqXp0z9LJbYWc8jcsMCUZA3d/uzBYxcGOYQkws7fq9sfyP9lY2D49wtTksFrGsfGPwwM/4QtWTGMDb+aIS993ZtB+v8+IXSdioWHZjx8w8DAwHabWwtNkin0cZUzK9P/XwxfGe7Eoxnqd9PMaiE3+9MOz95HDkc8UOTcnnRwXrlpwPji49v/Hx0iT2sjyeX9ncre8PTFPP7wgx8PHzrit/+OA1wu/foM2/5jsbsOiHCt3snM0nQnq32TAdRBUR0rt/dpNa/4+p+BmYmJ809nnLvgljINBgYGBq3prz9dvFQhyMC1cb84Y9D1aAYGBvXj1x4uUmJgCH/8//+6Uj8GBgbujfvFGQyu9zAwMDBIN///tcaNZfn+E/8LnzIwMDD8/Pvvt6kZ/18GBgaGp7VK+p7BLDEHPrG9Y2BgYNCy12Ev8xIT/w/1gJCtHiyAuO0PPfv6/WbHqi8dcE+wQlKCaoit8LEFf5me7jLVRYpEFgYGBuacEMH7fWv/MDAwMDAxIkUiCwMDQ2bXufSbQln/fux+yMDL8BBF0j6HTTVZSJP7//+4WyzWghdQJBX/l2r9urb64z8WNUlRGXb/81+QJP+zHN/AxMAvr8r35wvbG7EMhcXbfsMl/0pv/MHAwMrz4Arjf9Z/rGzBLuUzIZIA+ZTXe+mpHpsAAAAASUVORK5CYII=",
    },
    "F23": {
        "description": "forelegof ox",
        "pronunciation": "xpS",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAOCAAAAABmqTEpAAABAUlEQVR4nIXPL0sEURQF8DPNyQ5bBwYst+oXMBgMbptwg7BBMAkGP4PwECwbtj+D4YHhmQyLacMEwW58wYcYpi3HZJj/Bvekx+XHu+cmGKKnP6u39p1fHpyk2AIp4J8ekx6V10fbFC9zAMXF+QzA1yuQAvNm2KpAgVSMebkhyWi0AABYkjpWJtxmgSTJTWsAZQ26jvkonu81xVhregMUpKLumItio0MeuBgIAAiJnjmKjw4AalY6gZHaLi19FImu6zKFGdkwDVH2hpZ5mEBdN5dqoGDJbPhgyT9xSMr72c16//nhatQnOz4b1/u8+4bjQixNhv/DynzQyQ4FkuThLvULVdCSo7wDXGsAAAAASUVORK5CYII=",
    },
    "Aa20": {
        "pronunciation": "apr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAA6ElEQVR4nAXBPWvCYBiG0StP3oQghUgJhVIQ2ooOuurSXVc3V139SV1cxckf4OLg6KB0EArdBDdTNH7R5O457DoAnR3atqG9FQtt6vWNFlSXmk61rEJjJa0aAANpABDPpXkMXk+TiXoe0ezUbJ5mkSs/j78Yt8uWVNawriQWRAEEUWDmjnB05rxi+EGt8GilkpS2LIj7ntePAxfSfaRFSFeSpK5lxahWGxWZ87Ofb94y30rRAQ5RyTjvYX/GMB98w7xbDvnNM+UC5bIkvcM9TaxyySG/vtjfJYXfK+7h/fNK9Bo6exoChP96mGKMH5bmXQAAAABJRU5ErkJggg==",
    },
    "A45": {
        "description": "king wearing red crown",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAABl0lEQVR4nEWOT0iTcRjHP7/fXpmbCZv/SGHSKjRQIf8QiaEiQh2ig3SK6LA8iVQnyVMdlE7qTT0kEQjiMBiRQjBsSEVBLfSS4abRCkUU/zDfnLE9Ht69b8/xw+f7fb4A0HssMq2A6i+mBuCKe3ThWhDcfQ2rBgD/8Hm1C7oGVAQA6jZl6x5Ur0iqwSIMZec0DIq8K8sTNZJ5VNSaEJnwYt+YvFkXWb2I1czt+5Xbn8IVz1YSeSHwa63GjxHOhuzIud8yVUX7XhTyqUJFSHrPFEcAa/Odcui52Xn8wXk0LX9e7R+kJwyHvDxpZkYOO3BSom60HFDc6XKcFyLrP/YlXuo4OQiOR6lvtUn91TDJeYOCgE3Ox0ZZTJbALUArT5mOPhhgU17DZ0DPLi0+N7MX2CWSIw4gkpan6mvcS6289QEGyw+Hn6S1aaI4OgGQv22B7yIf4ZJEigC9XOhP9Uzx01lLUyzmwd0d/O98S9aeJRPdAEVOAO3aqLhr2Zk9twDQsvXeIp753cuAoa/7GyfTGqSgpqT/8Q6nBO2VGxtaHzYAAAAASUVORK5CYII=",
    },
    "F37": {
        "description": "backbone and ribs and spinal cord",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAVCAAAAAAPuMNxAAAAxElEQVR4nIXRIQ7CMBTG8Q9CAoakEjmOUYtEIOqmOcLjENMkGBIkxxiaU8xMFLkEUfXlITZCGC/0L37q5bVpgb6SLCxH3dmajiJL0+8KsrAcVbE1HdWyMv1uR+4sP3X819X3UxPiiSXwhCEwXxwu3XvjmTQVaqMhfzPRkHSff41jE6JK9jV8kr2qz/5AaLxo7QCUpGlfEhdjANDybjqsi060BgqytBzyGlxMP//2Ux1d0Gl27LTaALPs2O2x3ubPBESTvAAdLOFlLoZ4WwAAAABJRU5ErkJggg==",
    },
    "A13": {
        "description": "man with arms tied behind his back",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAAB/0lEQVR4nFXST0iTcRzH8fe2R9dwTLMkhUZFWporHYNAJiamA2EgIdYhUCIrimgHD1mph5K6FZXUJehUFysUzSQjyFDSMEUblfTX6I9krVXMPXt89u3QHtt+xxcfvny+P74mACgZfj9v2zJ1t7jzHUlPGQk1F1H1SWLVyUytqn5521vRKGPOZLb2RsfmVTltUUdyE2QGcHvvdXaVxmN6aH1KPrd/oRCbFiB6LmU8e+OP969VH7TK7YwU3x3WY2euL2pa7E72PzEBUL7BE/AP1TsjjoNDB1KbigvA/PCH638fIA0TkHnNu7I5JV8nHqBEwvJtZ3I+JnmAf6Lh9eoTyoqmFiO/7XMbmKfaqY9Ly5E/svwVPYOQ/qEJAno0fPWpMUdddFsgrsHFC1bHvknDTWSYEGs28FHH6jAcAN2+DuwVFmhYdvPMEln2NVDuR8dsuGj5NWcn1UInmek3R6PjRtwVFBk4dlzz0SBbx3vSEtw4+/tytYN8qeOQ7omcQgFwXdk+WPV1CdzoeF8U2EIAFIfedABQ8EpqN2qjUwuVKLCjtfvSc/LKSm2+TeSUKUVZj54B3rmXUDMw80tERPYc7fY9KQQ2z8qtjmBUROa6vD9llyUNG8B5ERER/X57Dqu+RyoTBZU4wHTfdH8E2rKHg8ZCmScn+qoS13Rj6bDBfwHsRcZel/EOywAAAABJRU5ErkJggg==",
    },
    "N7": {
        "description": "combination of sun and butcher's block",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABgElEQVR4nGWOsUsCcQCFv/t5dU5ZgkOGkHQuQSBEIip5FTRFUFOTHI4VNAX9A0HNObg0GFTr4WJjQ41RUIMQkoZ44VkG4XCeeg02BH7bg4/3HoCi15qNRrOmKww5s42VWGzFsM+G+djaUgCULesYYG+Q+DNJDPZg+vFCgoCqBkC6eJxGM6MQPK3XT4MQNTV57LUKm9snHLzlqb6OCdcjg1/J5RQ/yB5Xlvo9+LL3sb+g15dkJzL7RDF8xGURZiPO6MrIj9GnkOsaWiymGd3cnzmeebcaDes9Mw7IQD80I4BBqA9IwNz91NMDi9F2sjI0lu8ma7uc/3wvV0AAesXYmJ/fMCr6sFMyM1QPD6tkTAkEhM0biqpa5MYMg4AdT5MJ152g6dkBAekXWH1+XoWXNAgUbwFfu1Rq+yh4FSBl+smWoZzFb6YQxLs263Wor2N34wjfWqETXMhDfiHYKaz55KVkKaGpTgpH1W9bySWu3NZHx/20rE+389FyryVH5j+9X8vNnUPJj8wZAAAAAElFTkSuQmCC",
    },
    "W15": {
        "description": "water jar with rack",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABaklEQVR4nD3RPUjUcRzA4ee+f7EDX6IwxQtDk6IcgizQwU0IyhYJWoIggqDd1mhoiSAKmnpxaG5ra6sGhWooQhGUKKrzXfC8yzu9+zUc9Nme+UOMvSml/+UMvRxdmPnL6NnpKuJu7csE3Es5KPxYOJWDB+kQ3KhMgfH59Lgb+x/7YHC9+C49DeZmCvCoeLl3+vcwU9VJKD6nf/e2eL11vQ25TXZ3MrExW2hFZY7KfCYqxYDGDvs7OdHSA/IjHByuiYnJ92UsD4fe7lVxwWwNnw5kuld+ivU0CF87jxhY/iNerV7sQKk1r6NaFeWVgZP43nXMma0NsTbTdw5rXf3Ol5No7Clhs9aj8CuJo+NrH1BdalVbItpPf95G9duelUXiUnpbRr2UUSL6csU69hfz6gvErgzUSQ0ir1lnknUQuSZbTiTtx4lG04dHtmVjRDR9c/mFO1cHtSTQc8v9rG3oykNP0jU8a97cHPoHdaaUhNR37eQAAAAASUVORK5CYII=",
    },
    "D18": {
        "description": "ear",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAYCAAAAAA9/JnTAAABIUlEQVR4nE2RvSvEARyHH79Od5OXDEdJXsrIZpHBpAwulFHUXRgsNoMkkz/gLOcugxIT5W8QpayK5JDrvCTXeS09hnvzGZ8+3z5PfaGUUP+Z6l4btUzsqfq20ldFaT1J5lWdCUqo3dxqrGApwwFA+ILkwMF79qoIMFKuHcfcBcJZ9R6ANjULQORDDSornwB8vQABQD0Q6QCgrqqSUS32AA9aLMMt1V7YVQ8rzYY+7YZPNVE9j2iUlHrbCZDQs9Zrz9lUXQRY8nld9b2gOgow6GPTkJXMAHSl3GFM1TVdBWDs9BfG1e2lV9dKeznTMOnTfGve6bKDN1GI2xL6drni5T5A0KwbVVd/FqKQ0XjtOemCudkjb+f+Paxx6lLvUl3/0B/T9raWgcxK8wAAAABJRU5ErkJggg==",
    },
    "B10": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAAB4ElEQVR4nE3QW0iTcRzG8e///74b7zIzU2pdrHNLyCDrRrBgmpRkQaVEdrgoKegAHeimYtXNbipC7IQQu9MQIsiJeCEqdbPwQDPFjNYrsgVpDmEzca97/104refyw/PAjx8spzKk1FAN/+XKzMSjxpGpY9qylM6pmD9n+/fPniWRodmPk2rAszfmk1kq291Tcisom6Z+avLwxTwAwzVU11rvL3IJxVn1wgkYH5KtQe1ZeutABZdf2ScAqkxLXWg5viZ8iEmlbgNwI67sPjfXmmVDBhcA1YmuqNNBpEJ/rN879aeJ6/s73qdebwHN0q3WI7KuPJXX1jmxYAFCSsY6ko3ml8Cv5x4E4HBJeLP+3Fez5q1pClDZyxuUSnW1xKvFu5GNomoaIP/8zYPO1VZ3YbNqD4aVDhTL5Gg682md0b7rgJHoB8oi0+o+WkfPWs37MnV1kw77NlzyHu3v3Pz0t/0tOj88rkPGTgQ4XZBr2qALJxK64z4j8OBk7tLrJAyOVxcQvRtLZkkHYRnAcP3gv5bqlTtBhdOQWxyJIoGQfUYsFvaU9/5AAgv2quzGmTMHEpgZdRcCoG2bHVsktyr1AWDU5hsr0KH2TlGyJCNArXQYTyr9Am/bDqx5G0BoLsHDv4GYssjW+7XlAAAAAElFTkSuQmCC",
    },
    "D26": {
        "description": "liquid issuing from lips",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAYCAAAAAAuK9knAAAA2UlEQVR4nHWRMUqDQRBGn0H4tYiFiK0HEFIKCluq2KXwBmIzaG+Te1jt36ewEo/gAQSP4AU02MmzyMas+u+rBt7O7rcz8IvNuX1HA7VvqJHqLDX6clZj0BpboZoHrALMBuxRzuW97PLUD/HlkpzguXbxqupbhLq6HYDJi2rkT4CO0LxS44V6Cj4BRJ3lQHUKGyYi62Kd8lB9GANpnaWwr55Dcf3dSZXwXs9KObdPXbWJKz8m9Tcrt6fH/2ZXuPaxpXZ12lA7t3+GWnGpFy333m5Db1pqBNst9w1xRIkSOYG4OAAAAABJRU5ErkJggg==",
    },
    "V15": {
        "description": "tethering rope w/ walking legs",
        "pronunciation": "iTi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAZCAAAAAB4egMKAAABEElEQVR4nI2SvUoDQRzEfzls7AWJFmnFxnRpAwqXRrAzYBBkC2Mjdr7C+QRiwCLYBjFVhEtlIRY+gaTQIrGwsVDhEBmLu6AX2b831Sw7zMeyEMaS4hATJcEQNgzJ8KP9jPQKyMQZ/B/qJGdXSvEoFxTRQVAgtPJSZCl09gssjftl/iwdSKMv6dDuWpfEldSanZBHA1ocwYrtNpLWIZHszLE+ga5Ut0IbS2wCN7BtmUm3ACQaz/tlkZQ+dFdq+mV30+ouUc+f+aZBRmVsjaRKRl0+Nbf0mMlTRt+h6jE7laIpP/ek7vT6PzdbFw952RzA4u5qWAY4ARb2arXlEtCZMWreZz/rsgrBwSQ9XK/9knwDOr/FQ3VS7BwAAAAASUVORK5CYII=",
    },
    "C6": {
        "description": "god with jackal head",
        "pronunciation": "inpw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABkklEQVR4nD2QTUhUYRSGn/s1M3qvl0KT0UltxvGHUCLLYKhVbaIs+jGIFHQ1oaAt2rQSCVq2ULcRRRBuLMIpgsyk0qiw2kgLJTI0TAd1JOePmbn3tJi5c3YP78vh4YXCDWcSdjcoh2vchoQVLofrNlP6fj3hcIn5ySagiv2zwb/L3zxGgfd1Dr2ceUbgFC643GWWH3lvpucO6q2A+638vtfhC7cQkkcuoP1z2vo+30/9G1lu1oDK85WlzRe7Tt/+2XhGK/x3PzkWW7g/PuXoMCxyVR+NF/2Ap6/X3UVuwnpg9GSL4XT8zzXPpDi5t3pVjMwqyuwbuVEBR6sW9u7RTLiUeLz2wc9A9sqFQPV8mv4Nfyj6w3dXGiH467na8B7+cj34qj2bBNMboW0nonFTJFoCITmHPiH18FC2SqFTTqjUC27Bna9RGw6goGrxowYnW0BFkseBsZVDeSfP4lKDgnGjKc+qJmcryGiFEXxlsysKelUyv3IsHbc0/NO17/4ltwHVtx2GwdhuTmzLlpwVTy39B9+5i8SSDjbEAAAAAElFTkSuQmCC",
    },
    "D30": {
        "description": "two arms upraised with tail",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABKElEQVR4nJWQv0sCcRyGnzsvLYwg+oEgWVmUEEVD0KAhESEODdVUEAj9DU3R2tLY2NomElEtQQ0RbREYkZYNOpTaEEbcgdp9GorA77n4jg8v78v7aoIlddm64ldfbzbAef1w41r+9dILYCzf+kNh7i8/ahIbNnuC0RSgGdOjnopZyAADff718PuMoEiLPld0QG+gUnGJ7aAUS97uJrRg7AfVXEiKnA2pXoRaPKJa20+tkbvHfsU7OWHartCCQi3ymptN3bt3fJKK/0HfmvumeETAeBjMPq3EymDDRS3i6zLTEkBkd6qcy+bylmWKiIwxXxJjZzGR2D4AfdWWpc62zCvVKuCdm21sHE87XgM6UqJuA6xPx2IAvSn9bkod/wIgLSR4Wshtjf4AYMRyeulpERoAAAAASUVORK5CYII=",
    },
    "Aa5": {
        "description": "part of steering gear of a ship",
        "pronunciation": "Hp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACQElEQVR4nHXSW0jTYRgG8Gebqf/VyBunoRabLtdiFLbCkoRQO2gXkVeBUiBJylqQhV1taohGCEGlZLK6CGJFShmBNmNYQmAommsr8oRYoULO6Q647elms83Dc/t74XsPHxCTy/dF2DpJPe7TW3vyJ/pWSrZSSRffNM8t5os359LFiTQY+Eu7qR77M1YEKN7SnLKJykdn8yGkIsEarNmo6Q+pF8NoycQ+uzNnAxtWrcnIdbEekiv8UrBOj467ipBoI3/mYo+NZiG2ra+sE1AbCI6yF+IyzldEq3CPnXLoJpmX3Rtqwg4TB5X/dbtx2ZoNPGcZkOlYOAlpI/tVa3zCu3QJaA2UiwHsfjayF4nmUGVkeRIDWyUwBfTboClRIWu4PwO3OKcJc2rPDx32DzuUOOjyzatwYPpjSvlfHgmz7MGgQvt5VgvN71c13lElqv1PmlYCusjbBfR5vcVQL7i1oma+lsru+Mi+9Ahrv9FVL8jaeV0E9fRyNYTH5FVJhOMb+DReVrc6LAVQ6HYoUTjJhrXFqb47zyYZPePZAJBYO9uXhfMTI7vCurN9Jh/nFlkRnrSG3Zk4s9AS/nUX2IicDxzKCJer7bwJtLE5DgAK7SMqcQsHjkd6iTs1ZC+GZpwFAA45WY/SGeqjTmTipA5VwTEd8l5yIOXwNNvkUZxm4SOZcI022H1OhayD3dEKyF947grxllWQNtzwLF1EbNIH/bfRGQI5Ven0GBLWMZLe+6d8hP5dyD9fJVmvgLoruNTxD3S988reSdenAAAAAElFTkSuQmCC",
    },
    "G41": {
        "description": "pintail alighting",
        "pronunciation": "xn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACEAAAAeCAAAAACHoyjLAAACU0lEQVR4nG2TX0iTURjGn88NF6KmtmK2yvJPYENHfygr9UJB0QJBmoVC3WQrJ0GaURR0UcybusqLNOjGkBp4YVHBWpHMKYOmjYopZa6JmDOnaOoc33y62Frr83uvXs7zOw/nvM85UCkEIQGylWJ26gBlY/IiNw3+8i9JdVVBY/WcCCjDhgMILc/Ynw2sxeuKsppaZDr8e8uBHDe7Wy0MGuKBqgd82+Ki476TAPaPfBaers6908T0wie/p5sO9ZBBP4MAkOe2lRZdCtZHdV2fN9yS1zbCT82Hy71vAAD6mVeJx2kWAADpA7yape4M2ZoygfZQYWTbvun5SVq1AATj/Eqd+q7PcStNAEqmzIqoczJJngWEC+LiqVZOmDUAkqp/jOb8PVvSGMl24JxI+z3a9gBA/kP6Sv9dr5qe/vGG5jWS/q40AIXnvQu9JXED2LHUb5xdJklvDYCt18fYV5UYP6JUi3ixjSTtlQC2W1e6z6j/T0Go5E1VvelygxZA+kteSZXmBIXZuQ0JkZRzQyZlTIgFH/6eq8P6eoReGRc3WABqy+SRaLs7bN0sQ6B07lt+pEt5TJMcsauHQ1GXjF73QTlE6+WXskibbnHfkUNOBjmsj7pY+UgOeUEOF2Q9TwCQYWOXDFFLsvtYYHG2pwhHgwsGYQNhJEc/BshZ8sZODx1bpIDaxcCJDvJ9cecUf4oc0kiJ2+RYh4/MB2o+kHRpASjjAI0ByDYB1zxA39cKlU6xJrUQGSZXY4NIyZZ8V72HkxUTfC15F3FVFxg+rfH4iiXLfwB/Bgdyf4Qq+AAAAABJRU5ErkJggg==",
    },
    "V34": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAaCAAAAACf9lPmAAAAzklEQVR4nIWOoU4DURBFTzepgb9Brd0mTRAg+wkIQPELFSQokk14QRRDaqhsVpAQVOEn8BgIQUBlexCvb/u2hqtmzr1zMwSd0pX6FXbRjS666Bl+uuxTb6tubjDZsMMMHky0Ul15kcGlUSfb5FjrWn3axrSGuxy9WwM8aCJHXsdhnp6p/E7mo4ECGHKV0Bunwx7QFkQV7GoJ8NtkpLEA9v87BMCsfxSXxlFW1USn7S/d2CHFSg1twRlA+WKAXmQzON/rX6Yd4Ph1rX7cl8AfdEt0k6L8OHUAAAAASUVORK5CYII=",
    },
    "T11": {
        "description": "arrow",
        "pronunciation": "zwn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAICAAAAABbx2k3AAAAZUlEQVR4nI2QQQ2AQAwEF1xggm+xgYkLSpoTgI/6wAFqhgeEwMER9rfNJLOpVE03xgJr3pulsCfTO+CDQx6QBRBTwaQZcJOUARrqyjNN+wOSDmMqrtPdKMnibb054OaQ7WvV5RMbqdw8phAlT3sAAAAASUVORK5CYII=",
    },
    "A21": {
        "description": "man holding staff with handkerchief",
        "pronunciation": "sr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABzElEQVR4nE2OTUiTYQCAn+/93u2bjpXtc5v0Qy5Z0LSsyEEFlVSGBy+ChVIMi4HdBaGDdBSCfiA6hJcOlUUhdSkmEYFegghx4ErDzCg1lbA+f7bv/d4OsvA5PjyHB0o0jM8u5arYzMi35rbPfWKTaVROB+dzZfDftju9HbVBpUGW1FIoOJLTdwtAKax25ls+6KMAxJ9dAxB/B2Ti8Vj3DvD163wU6FtsgkB65SJCLxQTTZC6FD4Fa1NlB5DuYGe0PRToij6vCjpkUEik+6TuHq8vF2/aTvTQJ4nEX7web33wvpASmtOxhyYS68fX/CvAjYSdzvB62JQouTG2Vtlbkfzl1dmCPQEPALXSujv90TtSK6xGSwEQq3x7LGtuW/ZLLYYVgJEZvzKPvfNFvRCBAQ/Ad/zOFGgl00JrA4AehgANSRGxNUB5anYOMMw/Wh7e7wK0nPlyK6hXqyfvz0g5twywL7B9+rvVbb8cHZX+mUXAX8PtGzCctUwlNj7jJ3kKTGYbYoitANi7xiYA3vgiiJ5QEUjwSAGY5TaiZvAncGH1HQAWClGY9mBv81AegHUMpCEqztafI/8b4GDG9JCuc6J/C96Exqe7riYX4B8TVaBIsg5rUwAAAABJRU5ErkJggg==",
    },
    "D22": {
        "description": "mouth with two strokes",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAASCAAAAAASvfPJAAAAiUlEQVR4nGNkQAL2ao6RUOby/bcOMmAB9qnH/qOBY6n2aGq676CJQ3Xd6UaIzMWqFa50rj0DA4P9JuxqkFVusmf4////MX8F7IoYGBgYFPyP/f//n1jTiHQb0T5FEccbbjClyIpwuJaBgYHh/39MFgMDAwMDE04tLMQpI9I0GipDAVxIPn2BIgMAsZuQ8X2FCHwAAAAASUVORK5CYII=",
    },
    "U6": {
        "pronunciation": "mr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAABO0lEQVR4nGMQ2f/QngEN6Pz8v4MfTUxo1f//MznRBJP///83lRtVjG3L////O5hRBaf/f3jif4s4ilj0n+3al/8vRxHUeHuRQ/Xu/0VSSGLsTx5rMhg//b9ImwkheO2jBwODxaf/v8pZGRgYGBiYGBgYjvCZMzA8v8fAWpsLtz72/wJGhpTv/////1wA85L5+6NSPu+Ou/nu/P/zkDxETHr72zXv/mYxMPDM/ft/Ey9EsOL///+TmBgYGGTy3/xfDFEZ9P//NKi0z/X/JyFhs+P/BX2o4cq7/0Nl3/0/xgMVZBWAMkr+/i1nQAMiM//fdUUXlP32/yl6FDBW//gZh66Qfc7/B0LogjqPfjegizHU//9chBYtDJx3///0RFdo+/P/Pl40MdbCJ/9rMIxs/v/SEF1M8PLvGQwMALxbe6ZxjZDVAAAAAElFTkSuQmCC",
    },
    "P2": {
        "description": "ship under sail",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAeCAAAAABlfzOyAAACRElEQVR4nH2UXUiTcRTGf3t9nZsDhYxKixRCQqICkzCoiMqrpAvBq4igjxsJsRAkxSwzyIu+MG1YDUKoi4gwjFghFgWJhBmEYZRooKRuBTK/554utr2+zdFzdc5zHg7nnP85f0iCpk5HAmMkk3m2KoExEyVm7sJkZsoq1u7kHZ6bq94DUBtwqcUWsRdRV5EDgaAWdzC6NmWxMyfkG9rgeJOQ+IakT6cBHvQCbHkiaeDWqsqbpUoAWr5FiQapcHWD+DW/HsA7HPUzvqssiSx3WSUA54dihKF3McMuG/WyDuDpdIyIkJYkG+gtQH6/5fclyQa0Aihi+Q67rPvn2D2AO4QAnE5LNm1ZFPVK0iMwx2bcAI3KjEZe6CjA5kLgqqIo4KbqAbig6KMeUTtAsfxsvy4btgHkTaoDgClV0v0lu1gLDNtVCqqxTPOSQic9p2YlST0ck5CkiZ35D5UUHbuycComuwJOSe9TMQzTkXF8ROGDpJqG4QIojcsuAr/UbbVeoyHLZq/6n4vHAUkV7JZWhtWonLh5Nij5FMZdJklfJR2yZA3RU6g+9+G3JkpLx9UMdMXr7Xr10gWAV/4u/+tBSarCEVCTC0h7lrxL36V9QFVIl2NPe6AHYLwwJctzoiAS9M5GhGP5I+wvqUltvT8QLSXzriRppu7aP/tSe7tPajfji3KmzbrChSmnYruj8EaAkZk1y+n1bSbkmj8+uwVguFeGQmQwLIz01D+uok2YsES/zxOL2T+FWNal7KKl6NWXl/NfiL9OUVbz1SUvFQAAAABJRU5ErkJggg==",
    },
    "L4": {
        "description": "locust",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAC0AAAAWCAAAAABxzEooAAACFklEQVR4nHWSTUhUYRiFn/kxTSYYi6FUmKKioEgDmQqiCGNolFwUQrUyoa64sojcSkLESLUICm62qBaRM0NERGUtKglG6EqRiJspqBZJNaSYFjlzT4s70238OavvfTjf+X7eF4IKM0/d6Yr5qCCFF7ir0va6pd3RUlI7IaUWN3vZTFcpOrEafi7u9nwbynR7/ietSQaODMacIlyWdxa+6a8Ah6XSiz+UOKcoEGo/KVdnD4D/PdBy1TVXxzjFNnaMv1wPZGwBaG422MfxWx4Et9uAqtaaShjrXTu1p+U8wKeE59qHfymH7nGly+9tfkQj1EVuFHlgKAjwtjW7LFDvA2D68kFgGEB61xyXNNQTDcZtLanneD0g+hLW786bAGRXTqxxjph8NVfuK3eyye8DOANIsjLFDiW+8Fj2d0lKl3z18rhkAwpLY0W4cRVNauKSdOy1pPEtBX4xK+kpIEuS6bb/qC5QL4WJTeUl9a6oDpyWpLv+WsCUTEmjPc6GNmk63ZGQIkBdqvDEB1tDTpYhURkdlX7lcrncrPsJuwB8+0ck072/IQuAuGTJkiWxd1KS9MQL4H0j7WSBDDXIkCkTKLvj5KeSIUhpcKFbpilDlhoAIkr7N5n9kn4MD0vbF4+2ZDjlrDoBGmP3JSUd5oy2CWBcx+gwRxoK074hw2dzZqYfauyKj3JTrZJ5KNLdAy/+SHpW7xr/ApibSyeGML5CAAAAAElFTkSuQmCC",
    },
    "D34": {
        "description": "armswith shieldand battle axe",
        "pronunciation": "aHA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAcCAAAAAAhXDLDAAAB3ElEQVR4nG3RwUsUYRjH8e+7ze46rVoUlZdIIaK61EZE0S0IWwjzUPcQjx3y0NalOtilvyAoXKigg2sdOrRhBQlmFktbIBhUihaR1pYga9uO+evwzsxqO7/b88xn3uedZwBI7Uun07tj+InldG0ba+Kee1l897bQEtQHZ/X+eny12FKSJi/d0ueg8UmSbm+oi+Y3mgcoy7WNG7LpCUmXlAXapCYAOlakC/ckTZhgzFVlADOgOdt4LRXhgaR+n+x/VQHISpcBaJJ0HBiSyu0+GV0G1lfVZ+u7khyAYemJbR0bKwFX9NSWg5LuAHDCk//ajM5DUtoOQF6SdlrdLc0nAKQ+SKoMtJy+L0ld/i1NURoLyVnpj78NnQnXsUNaAeyPSULCtn9n8iGZuYgZBAcAAYw4uM+yrMoU7AkIQOcw/2eolF4KBgGPGgWMc+hASBZPRQh+Qm9IzHIUyUE1JLEogak/imMiiVcnBdZFkpNg/O0iD9oXKl7vGrHxgzS9yRKjGs3fJGl0a120TkvS42B1C60/ZrvHmTv69eFUHKB25HDNBegMTvEGpIkvH9WYmw5UQDgvRhJu7O+Sp2BMbVc/8KvnuQOZairJYq7xe/a2FfKV7+AfN7m5kXSkAPgHsin9dG1lBEYAAAAASUVORK5CYII=",
    },
    "P7": {
        "description": "combination of mast and forearm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABvUlEQVR4nHXPT0iUQRjH8e/MvO/65hbham2LlZUHS7I2I4wCO/XnkEGnuoQVSWBBhyK9dooO0SFS6CR06VQdOgiBYLgQVAcJ+kO5W0m1RkQuG++rvu8+HZSaaPqdZp7PzPPMgJWj7zbAxTdWRVtr06pCiNMb/5Q8i/3t8ZmIzUG+5OSgOXtBM7+ixd2clVdy2ey6UsrdPLUmTACdc3Mmc6TJINn1bk6n9mwD0qtxZqf0A3x65n6aLHwDKCZu7voxDfA80+qcfXDVyEdDbS9dUy72K2+rwMt25bxdV+gRoP2pdrKexQBlq2Rzc75gQPz6nIvV2s8vAOo6G92zJ84C0CsAwfkdxduWqsrXQ4AZkmsA+Z8S2cx9mTlAcEvkOMBNGX0iNu++K+XBO/LlUhPA2HjDsarNBDfmRUr7FzeP++ie8QC9TCQEiC7PDXw4Ob7IMoevPRoO7+sIK4XRSWBhcODBkhItJxGPpL401Xi6p/9hBfDoviqJFxuVbDo1Fhs13FYeqZrru/g376OMutfSmUhiZouvaoA58XrCQxSiwNeTasvWDqNr4aPv0xFg4qFzjj6/vybDf+31f84t5Rdwl5IDOgNhUAAAAABJRU5ErkJggg==",
    },
    "G36": {
        "description": "swallow",
        "pronunciation": "wr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAZCAAAAAB4egMKAAABBElEQVR4nH2SsVEsQQxEm19EhCVsslAOeHhDCJtGu2RwNh4hbAoyZT6M2/1Xt8esLNVM67WkkiRJBkjN41lSvOenJL98zHVQdCSSiblsAEMgBT6xjVzQ1qFPeNJytQvTE+A/SSq9ScX36+tXnjXokhgjpZwCJRlpGyAMZ7gq753WzNilYF+I6TNdedf1tEGjWNftN01NhEZaYCO6anILLilGFc5rGVv2wGtJMaob7AFAPe7HdP5P97g8EBNY1ptZjlEAfQCCgWGo20rcjAPNMiUpbbjOGuOgUhEatxNJ0+3lOENiqeruydXc02gc5lL3xcMXNq89egX4WY8r0JP+uq6n48MvCPDigkXMgf0AAAAASUVORK5CYII=",
    },
    "N16": {
        "description": "land with grains",
        "pronunciation": "tA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAJCAAAAAB/WdGsAAAAVElEQVR4nI3OsQ3DMBQD0efAA3i4ZApvJmWc7KDOpbuAKdwozYevJQkefZypGN3SXt4qnrpkLzv25FE3Lu7daaV2knbn7J8R+ASOTMEs/gUr2Ob1D+h6UxXMa4/EAAAAAElFTkSuQmCC",
    },
    "O21": {
        "description": "façade of shrine",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABEAAAAeCAAAAADvUKrzAAAA5klEQVR4nK3OrU4DQRSG4Xdmj6A/CQKzzTJYXJEICJYrKCSI3kwVyIpimpomFXAbQIKvIGAaKsBAUspmm3aZQWx3WFb3c+dJzncO3YUrZtGV4cnBzQfr7Jw9DalcJoMcGCRXFcXhrZnmYqatR2E8aXhpTMYI8fztKJfXeYwGpX2PVqAB8SJk8j+bkuzOxbECdzf6k9M2QK0gS7ud6q9lYQsXO1VqVpRl8z9rIPWTXcs3KRZLyiz7cGXu94MHp4JWc+8ZhDCqmtnnLrwEphqF70S9uO97+sl1KJ1zqfdyqUt7S/2U7ttfcFNN0OZ7VmIAAAAASUVORK5CYII=",
    },
    "Aa10": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAICAAAAABbx2k3AAAAnUlEQVR4nHXNsQnCQBSH8e/ASoJaWJ5WAZsc2ElGcACbgNjoEC6QQRQygm5gwCp4lqnCDSDB/tkc5ND4dX/eDx65iIg8bqc84W+DKSWQknLEvmtXPHuUElZ3gPEsizdAL1USHibarLcAZX217tWpXMeR8cPrZLg/AHB2RdsAKA+SLNDYipgIA7ZyRdsovlrsQu5f/Kiu+SjTSwNw+QBEYTq68gyMkgAAAABJRU5ErkJggg==",
    },
    "M8": {
        "description": "pool with lotus flowers",
        "pronunciation": "SA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAATCAAAAADdFPBRAAAA9ElEQVR4nI2QIXLDQAxFnzM5QGihCgt9hMLCwL1CwhLmK2zY5gg2My3rFQIDs0eQWcp+gWPXnandfiTpvdFoVIDtHMgNAKF0oMnwA1TqcwPwRxOAMAF2d4OkREokRTC52c3sfn8A+llSxCQjKZrcaFWPgN6SIrSuGpLkhukiG8Bg1YCoBLQyiELVAFgBZK4A9QvAhQzO6wSsGHMO4TTUDR9dM5L1t7R/+jwOdX6+lHkkk022fbOxOWwOTBOGD/4aD1CQdt37ldkcN+c9Qe28AdAq4LJlyeSFKJYlxKrjr010/7pp3ZSHNvu8U25PDRCX3iRF+AKKgsl8Xbcb2AAAAABJRU5ErkJggg==",
    },
    "A46": {
        "description": "king wearing red crown with flagellum",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAAB9klEQVR4nFXRX0hTARTH8e+9m3/I0o1lukY2M6OHsFkxCZPoJaiXcOUksJIQR/RQEBEUFAQWRJDUS/RgSIESBJKRGRRUhCsh/AMDbVt/sOXMueGW29ptp4c1ujtPhw8/DodzQFfbZscdAAbPkp7L+yT9ugE4GvTr3fU71f/tIlTPyrDerVPy/esOuClyVe8ci8sBcERkoaXAOa3doWJIZNRU6FzOjIzJuxWPWqDqlYDI8rXrM3WF6arE5INb6zZEgjnvcuc92gEcSg6UAzDsr895xa9PO7GMZJsBsIfkvALAJZH5M42BUG6bE2l5WwZg9srkq6UP0gOA8lwk2QJwJD1aW/pRfu4DVMwWXvp6AGKJGtvBTYQmANizIL1752oBhiQTDcvnWkA1Npv488bQZ4P6hoDxnjts9wAUP5T0cb5IJ2v6x7rEVTQlP6pBtVvJxJoq6LaUPG51IWqCslJQt24kS7eJ3ScXn8xbI5H0bYoEeBaT5OHtEyKpDpgehDZ5sRqYW1xItNIuEom3N8YHFdyaE6CqstJWgqE34byfjGmnoMlbozuxW3OUP5J5B+waqwPyj3k/s3n57IViM6AAGP95NKwQuuHzAZmsLh8PKsDTMKxUO3Uu2pZ8t2q/bg7aOW9WAVE717fdHf/vKdOAKCDKWs1vhb+nR85U1qrD/gAAAABJRU5ErkJggg==",
    },
    "C3": {
        "description": "god with ibis head",
        "pronunciation": "DHwty",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABpElEQVR4nEXPT0iTcRzH8ffz87FaYlNzQ/sjhGS7WEn+gRAk6dLs0M3o0MFLIBhYQeApg1wIXUIUBcWBCBYoGkRUlKAHyzRGEyfYcAhqj6yF0nyetef5enCz9+37On2+cJDrxoTIWD7Z3MPLH77J35HTmfv8O+l93z8jEiwAKApsix1JPOpPzds1QG1YNsaffv/pnVq6Ka1QviKT1dCyfivxuGx5Gi0gQTfQ133H9GkvTE6FUsVA6eKVzkHFPUfFJ5//Bq6eTPp/OMQSuvXEAaiI255VCG3qOADkei8WXY/+SpjZqbftpCPO1sNQFs7OiGNMrYp9+M2DtPTRLKKy8MfBYCHKIeRp5LA2h6Kw/jjABQ2wLZSnd/zNfRcURtAB6JGetVRAy3n7urGKM1/3eCmNPLPaKqKjQOVGmGsypLs+xbt2R4AGGcY7a3qoM1ISBJqlRRkfj/r40pGLBtplVhTzybvwapoFOObfM+HE3CLga3dDqXz26uwsVQGRCFBGeFtBLK8gM7+JmChIy24GzqUNdPJrSwasA/CLBUe6/8n/1i/tAyHfuIEot+IqAAAAAElFTkSuQmCC",
    },
    "G26": {
        "description": "sacred ibis on standard",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAABqElEQVR4nHWSTSjDcRjHv7+NzWRM4yB52dBIXg6kRBaStyQ7IwckJeLiIsrFxUnsIK4SeTlxmJTESoSjZN6bzaa/edv+f4+D1X7mv+fye54+z/d5vr9+PwAADBN0Vw/ZYDXrTiJrlCwceiIiWtPIsQGRbt6JVmSgptd/36/olmhS8R8Ov11VApoP6pAZ6lkoAJAs2bNknDbtvgFIct0eaq1nLCC5/f96tE4ix9HZiZ+WLYaQMnh2zkSbLzSBGpOuVdg8Xg3T9vusv0nWPPmWC8PoOE3HAACU5aMPn1vFah6m79GiObglZ1Z8na/iL260k3uu3ZSRBAAWO92PMo7WLunx5RSd22Dfrtu+Rol/CoF5RuraVGJ+LIn6TJX3id9a6rUh/kAoAwBUNzSV8MoirQ2Cx2sHAOwA4BypLSeLAOPaubSlqucRESLt8kgLYMPxV1nb/MqkxErjy4qovMzWjSVYL0INUxQWdZzS+yACoO+4ZAAQntUfQcgApBq+GAAxpaGiCOg6jT0XZDyxvGuitEiOYb4jU0SIQX9uqAj/rPvPyshQ8ulDxQ+PNatJXxDTKgAAAABJRU5ErkJggg==",
    },
    "B1": {
        "description": "seated woman",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABpUlEQVR4nFXRQUiTcRjH8e/739/xqnMFkoZC6RpaizyYmiFSECTULlGHSCgpiiwj8JAnb9ZhiIEEESJdPUgStUMQgVSEq2BarRoTNDo40UnG8H1z8+nS+/r2PX748VwecOsXkbF6PJ1ann4zLyM7XVDX85K4cbBPhvwOhX4n4vlndwO9G2ccGpqdSnXNFierk6/1Pwr4xlffbT7NZFMHnFXTevJiZFTOcX7BvX8kkf0209PMsWXl0Exblz9T/hXD0O6M1MqFlo+lVk5tk9kqDZ0PwyseqpgeYau2cstDd9j8krPz2kNnS/yTp8s7dmvAEAAsMezjZrdP03QtGJ/6A2ZhwrxXgs4TePLjuzyqgp5caFDSc/KSPfM39z+Xy3C/eCjS3fxABqj9/Jjq+K+jxOxSMCaWGtVSPBrKXn3/oqOwboHfrqqAzrVbUCNzH2JAZVJaIfg2BQyLHAbqRdqASz8N0L2rYaBOXu0CGhbbAR02gTqJ+RSk01eAQsYCYLGogIV9nncqFLDDcqERAwXRk+Mu2Wygy273BaMnHNpLAD7J/2UjfwEfHqXFhYu2aQAAAABJRU5ErkJggg==",
    },
    "S23": {
        "description": "two whipswith shen ring",
        "pronunciation": "dmD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAZCAAAAACTTbgJAAABxUlEQVR4nH2SX2jNYRyHnzjjYie2dPy3rRCbP5HMFa4UF8rFtOVCLijKxSw3W3ZNZG1NJ44mzA3CjZ3Ihbg4Uo6skM2/XWxaqOmoM5o8Ln6/33bOGT437/s+7/PW+/2+L4SJZ7LlFGX+ywNMiz9LwGI7p0ndeqOYvNDLM4pRQnVNIWlQbSi22jRvsgBUqPp1SaFUo2bTdkyR05oc1PMFUuyVmpqrSyNSpXJJbZuyjqtC3s8LQ9KuaZarroyk1RM7NAv1ei0gRzUNfPK+DyPr5HXuWA3c0maAJn0L8FTKPRJIC54wxzEABnQD0K9NAHETTDwLrLNXSPgIgBa9Cdv0KgAzreeclQArbKXO2cGJjDbW6kj4ps9TzPNiGdD5Dr4bXvGgfuiaLIJMDnrcDZvdAj6OKrmneiFaVXqYraao67nNzgE3BnTTG0db9ctkL8ds5O4IfTqkYR38sgXivdoeNUnXH5Pqmj61ImAd7gGg2+HQOqEGPy92KB82LugWxIyqWZXTU/uDeW0w9Hom3Jy0SO6tojjrfveXlVolvxVg0H0ALJuy/pLtjq8FZr029x9rV/LH+PvhoVG/df1bij0wysdFhRt/AB6z/wlTNskvAAAAAElFTkSuQmCC",
    },
    "B2": {
        "description": "pregnant woman",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAAB80lEQVR4nF2RXUhTcRiHn/P3LIcOV1MzCrUtpgvqpg+HS6NupIwsxYQwKIMgLCxKEIogiCCwq6gIb4rZmmJmol10Y5KKJOhkhREkyjTcVHQrY+XO9u/CeYSey4f3g/f3QpLiH1LKWnDUo2P2ypHRieU611jXhqxPSP+jvY9/zq5W6M4S9PWEov6mVvn7qC4bvrVNFrWPTZTPSZ91Xd6aqjoIZz+n34tJfVPu/NfORvq+YJ2PndP7qzoXAvsH22HEl4lIynf3e7fuWY3Ay+2O9cKK7qU5r+3jebBrtUlnn/aWOiz0uCB9qhkVgJr8gQEgtgX+DB3ZJgCUQk6eANSrthQxvTlVBcjYgbnsvUbgSsdkyqHFtZHO4A3PigOy30op5XieALDn9D/ULiksDHLZg1AEYHAR8bmvpYIg0oiUArCc+RAyZs8nQJAIdlvNgOmVrKYkehGoXC7ltHSqlLjTXrzm+vAbIBaPsYKiOlvyywOUFdeEgaWEQAVGZRvwqRuAXX9PcUy6xL5wC2puzhAAGuasp8Tx7KbEPXN77Yrs73daZfwAWJ+MNx9OprUz2ng81JeJpWu2SM+/UDZwsxKKZPXG9009wQsGUH+F60LDJptBE0oCY0fB87xev2K827TYn1GwSVNEnLQsiM88g4wH8j+i/wDbrckrzHADeAAAAABJRU5ErkJggg==",
    },
    "A12": {
        "description": "soldier with bow and quiver",
        "pronunciation": "mSa",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAAB/klEQVR4nE3RT0iTcQDG8e/erdVM0NKRiR00m9hcA4UwM8oSDx4SC8tNw0OSVFJosENdlCj6M6KCjFFdrMgIyZASTCtHyiaWsWkuSNMymlNMnc7cO/frkJOe4+fyPTzw/8y+xUsggSEvQvst9cNzAJmevojZmvI644AtffKnFTrak2YtAiRj8t4JAJQm88edpW5AymzqVQMQW/PzzZX4MKBiIaQAIFUXPDgSul8QRhWKBLIa2uQjd05Gy4nSYMr6ZQBK3tXM6Ycd2299ZXeg9DUAlc3JlF131k7NSzpN2TqANS39F2NephuNbY+lUQo1ADH5FT2zM9ahdmWjFJAlbTYUtz6ROjYVnBkypAxg/N0a9Nms8vTlX6acQNeprOFi8rqTB1qEmDlM3c2ksM+mtHyQEu3fpg7t6qpu5nvUkld9wqNOVG0Yg7BjHyCxcOzAOefxBFV0NMDGKsfbZUWgM32i3GBQuW43BuFRvvdF7B+F2KaV3G42f67rAL8rxy7G4sz+AAAVIRd88efqvPP3+p/+SAJQPRgEiyinQXhy1zr3AKDRQpqwmcfPx0B39uqJOiG6CgHsGatWJN9QA1urx6tWra1dgXLH8xEhXkUoYbIyvnZ8dnp0UrxfodRen8ku7p7Vc1o8+0dRDxfl5WslAFeXVrr6gBjL0ABwoR74C1Dgxdia03hsAAAAAElFTkSuQmCC",
    },
    "G34": {
        "description": "ostrich",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABk0lEQVR4nG2RTyhDARzHv297s61lMbOHDGGjcBgpLZGUNQcOEgkHBzeHlZvkplz8vTo4vJCQohwcXIai5v+fGg6GsjDU2PZsPwdvvD2+x0/fvv2+vy+A2gsSuiFThWsvRrTOyrCPiIiu1ImU5SORAnteLCZPAcAd+1SJRAEAHaU+4S9OssHzT0bRUyQHf93VhvuADLMAqjD7DuQ7cplVtyTjLmgHrAefRAuSEDOntZl7PEnOZaRxuh93XZg+Xmguc+CTyLvisonZyuh2IGV3iG1wR6HkRm8Xhp8AoDI8YjCpwWQYjcY0rnWGNrIBgOkLrE3NtCWLmSpe4NUAoGh3n57RUkP85rFgjfirQktn1N8qdrVe88zPQS2LoTue2N0jzc24Q1K4K0Tf2vIQI+G9E6+bTR/TgfRGTcKDTjb1h5dmwFImnVaj9L8JrB7wfq8jqt00adIrmfi/47Ky3mbLzr0Ml7QJfi3tP8dnEFWT3w8VtEhU/f5jVvl5tA+/bsWgLrU5/cHlLA7tSJwVYbEgzRsAAF+OXJTSW6V/9gAAAABJRU5ErkJggg==",
    },
    "C2": {
        "description": "god with falcon head and sun-disk holding ankh",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAeCAAAAADrpXrOAAAB10lEQVR4nE3RQUiTcRjH8e/732bzhamDZYdYaNA6LIwCC4SgokKItIhKOpgWqadOYqcCQYrqFB2DOnlIrEOHKVkGFo3MjJWXgeXIeo3caizf9W7v3vfp8I70OT18eA7P83vgf7XnZK0k3Wpd0J/K/Qv90z8PbLCtf9MhiMsI65O+4JQJS9RvMHEPhyGOiV8/0ZScAcg9vHRnIdC1koA2SxZbAYLjryZF5AWomH1t21mA7tNf7OcV9pxBOdZYMgrU3SRuPMkQHtzlT9cO+X376l/KvUN7e/Qt36d6ruK7XChnjR/Hoc2YHZXrO4082zsXxVl9txu4K468uZIVxuRPOe/dc9ESV8R11O3Bc7N6ewjAwTLf37A0wJeR0rgPGHJT6dHGeVEQNqnp6AWatTkCzioKsr0FAsNHoaG0EJBIEwpITWT6Mg/6ahvNmXLBrUZya44dqdzA0jd/NBJLVwAYKG+mxXDdZ0AsbSuAT7+O8HFE0+YB4TMAwdfTEEzISaDVTCgAy2iJYvVPfAVC+qSX/du6Llju+ABEWPYsqe1XUBGggRXPMpWa6rMCB9csr1Xa70p110160LPm/KMq2Y9V0Q9Ap37qWBVjMgzA+WxRbHEcsaXsFEv/AOOTxkhknQxoAAAAAElFTkSuQmCC",
    },
    "N14": {
        "description": "star",
        "pronunciation": "sbA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAWCAAAAAAOHVjZAAAAwklEQVR4nK2OIXLCUBRFD0gkNhpHDWsIqlMES4jEoLKE6P4VEMUOUo1iAw0SExbAABs4FTSED0iuOnPmzX0XbgmhY/odLnkdfX0f5W1etyFWYatfVKohb/fk36oVkNZqs16gLNaNWqcADOYb1Uor1c18APQAyD5GnwD87H9X8bdMNXveeeJy4fS0N9Wy1PRBJyqoSexLLaDQMtK5FgCF5nd6eLS5UuNx2JWfdXLFiZ6Tu5Zxy+P/pj7AYbpr/W52AOAPjV5tsvQ8S6wAAAAASUVORK5CYII=",
    },
    "F51": {
        "description": "piece of flesh",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAARCAAAAADIo8JDAAAAb0lEQVR4nFXOsRHDQAhE0V+bo6uBVtTCtXGhcie0ohYICdcBSD6RMG92ZwDslMLpsVAsSc2lCZy3V+0p30nIim0FAB7+AbCuS9WLtMol32K87iqsf3HF4KvnOc8cR+ZNhnKk+DvXsZGhaydTycv5A6/4TNcqu7l2AAAAAElFTkSuQmCC",
    },
    "D6": {
        "description": "eye with painted upper lid",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAOCAAAAACNnooqAAABY0lEQVR4nF2RPUhbYRiFnxuvglliggohaBrQInVQJ42CBQ0o6NBBB8FiB526uTi4VLoI/uAoIi0hOhTBxX90Emq3aCtmEBQigoRCgrQ1Js31dLiapJ7l/c7L+c77BzbMhtCVnnDzpumVSREMO9Q3j3iChezxXXopdcAzvJaUmMzTmd9/MtLy7P9eFanN2AS8DGQA5zYAi75+wmtbRVbVipR7pz4/dhX7NN1YAwweSiNFXpU/H+WrCTM3UAv8HV1PW9yV8yKe96qUpB1pHIB9fb+QlA1VRSRvoaJLSnTxkLTZW3WXriTvJZ0r6SyoOnQNqMtmfg0Dvt0jSXOuvGhU6gTeX9k0qHf2o+nriZT+FfJ7KKVX+gLgVgsAYfXZqvaej/bU82Y26YHagDt7O0SUDz/WrZK9aMNGXfHSLaPtG5ky4/kxyJkwHnECmHEMKHE7sNrHMFqrADi9dDjOFiyUyj39+Qeh3JzNoyTGiAAAAABJRU5ErkJggg==",
    },
    "F14": {
        "description": "horns with palm branch",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAAB6klEQVR4nK2STUjTcRjHP/4bMzYDl3O6Q6B5cbUlkRErTxMcTOhUYZewF1xgXaTYXYgdghK8RJGnDjs4FkFsSq/Quznyz8oNWjkIIbfByLWUNp8O238v9HLquX2fz+95vs/z8IP60HvvrctsVeoa4NEb3PwY588R3rjd8hcEsQ+GetnYdqtUqJdKY2kT/4D8J6jzZ16/LGlKap7bnIfMiKzu0RI7k++qcO+qCIEfEtUDYBpZkjcaa47J9wDOR/JzDIDruefpRQ2OFeTBEfAVZN4IsHzftKBWmHFOCpdQmE14e+0AWbuj6uiweRMhFFLppY4+gJkvD/s3KtDeqaZTKBSzlm+tADOj/ry29o51S6ZIEwS+ph2nNgF4X9oHwPY7UUvnCAokXAtDPeWCYqVw9+DiYAwUeNps+nysnNQOdDzZangBCkTbrKEzHfU3tZy9u6slCgrkoifnZLq9xtpubc6fiOfKYlSGL24FzYCqAuagXBiW05WXAykffom4jagqRndEruBbGdD6nF8b0k2JBF2q6gqKXNN50ueqJtZnax59f0iyhUJWQgf0nsxja22E7lf5sM0wviKSHDfawvknPfXDd03EZarPMjnZvn+6tDzR1bg2ve7Lxbef6D6ouxpJ8FscFhERcdb+0S9eirjMGEdGdgAAAABJRU5ErkJggg==",
    },
    "Aa23": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAZCAAAAAB4egMKAAAA4UlEQVR4nIWSsQ3DIBBFn24LLxApTZZgFLZCyhCuU3kFNxYTOFK6LHApbMNxJM41oMeX+E8AsGa2yStleph132iusRYKMBEACEw11kIBFm4A3FhqzMNh1D8zDkD6cbjWNUFUjXtda1AcNEfVKPC8b3Ubg8MhMN2fIPDe6zYGGPgG4XWJM1fgymxjBcbL60TBTAKG8XEeeozDfkHSQNBEMxZKqesMWiilrjP4Ctfc/KJfMKt7Awe3S5n8Gzgote7iYwZKrTv72Beo5VOfwtwbWCilbmdg4RFbegMLj9jcG1j4Acs2/SX38+sVAAAAAElFTkSuQmCC",
    },
    "C18": {
        "description": "squatting god",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABjElEQVR4nE2QzyuDcRzH3893z2MbG5sW+RUybWklc5BczMlJyVL+gCmlHERx4CRJ7bDDihRK7eBXEUejSNhcHKa1ZOWAojG2Z9vz7ONge/Z8jq/evd+fXsD/aTdJXlqnEAC+gNg3kvPZjAyAFVD64GuPTkOPKgQxtc9dRI/VSM8EarIkoLox+YHEzIo6ZWR2b7hssLio8zzd9kNurkRVtaEJAGCLUJwkKS9L9EbEAQB6XKxzWMNAOxFKKvUjcmbZl1tTDeq2KB/qXYybS6gjS5T+dsXmSk80CDez5+XZuz5OSbloRvN+KAwFdQpqS4sRuh6afO5WkD1BJBHR60Cxq8rPXyVZIpzjqIhSD54Nxr3cqxTmpgJG4dcQTmlYyQQcdCRG8RFX3AN5caE8LXpjJSTUh2OYkE5UCi2tP0AtlyootDisjVb7GdDOPgEe+lF3i8WsxZ0fMDIAqAlI78Fxp9mkB/iLtwoAPtpuUFans7td4HmIrn8hzKavk93OS65+deSHAACcSZMXSSj7A/eHmWnWW/hIAAAAAElFTkSuQmCC",
    },
    "V5": {
        "pronunciation": "snT",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABtElEQVR4nC2QTUiTcRyAn/f/39bUssiay4FbhQYTC9GEMCrcwVKIjKAuQWZd6mAXsVOXQVBBFEEaO/SJhJhYORsIZiXowZNm2cI+RKNU6MPNd3Ov76/DfG7P4bk8APgvi0iqRZPF2ytTT3p+frvlBUCNTJwpwxX6KF0bAN3/pxqAwnD6uka1mk14DoYOeeCSnKV8/Cm+l7Ik/T4qklHCViNXpL3yqDwr2Pg6jvkm3/+p2wU3zT2ELeVOroYC91dg2O3D0grDcC5OAZoMBgoBpYAtpACFS2XIAX1ycgZHXI2VF8WsBiiu6fi+bkeaurlaZ18U2j97qf59g02x55xaLNs23QxX5QhcW63KGX5w0cyj2L6noeRHhMPm0oiTO/OVgBEZZOeK1LH1aw8o5FGg4oC2gsZ5T0f2x2BntK8tUTLbuvarRaSmaOLh36o1b5ZlQ0XkxXpAgaNh2c63X1FakPXjwaZfjdSmC7O9Huh0Tj5mtOu27AWF39+dGdqe547dnTsBiuDmBd7llspsfH4fKGYy+1lQSWuXpHPBwfuhtulz9hf7mN7dC0Dg7b/EBU4nUh/q4T/xPqUzjmyZSgAAAABJRU5ErkJggg==",
    },
    "P6": {
        "description": "mast",
        "pronunciation": "aHa",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAA6ElEQVR4nI3GMU7CYBiA4ff/+peGhiZIE+xQMDiwsGnCQNxkZGHkAF5AEqIH4RgsDFxAZEIHZGFkYdGGxOQfkNCPQQ/gMz0wXPj4iyES1PXIUeuBDZv20ahthjZKas9GTSESioPkMhkUsWHsTuDi0FbLD/eSX5erNvJ6Bwi8SIzpp2naN0bUOcA5lfYuA7Jd27zcve8lv7iZW/9z+wPfNZ/VGIDxykomBjQT83XYenC6Cmz89gFQuEVHAIyUfNMCWpucua4bNNb6Snemy6elzrpQmajqpAJQmuq0BAAd7QACeHh/+/XfnQGYu0wgMgUIiQAAAABJRU5ErkJggg==",
    },
    "G15": {
        "description": "combination of vulture and flagellum",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACMElEQVR4nG2Pa0iTcRjFz266uTmzXOqUBGsUGJRg9EW6sX2wi4WRZUmmRWs0C6ywQEUslWwSJEGFUJAtg7AaKhRGW9scRIYGrnLgpZUzauFqtzbn04f2vu+izqdznt//fx4eQHQ8QjStEeBfierdQavn/Zdt/2FHZqmx3HedrsVz0j6OfSQaXKtSLT4cmuzNBlAX0LPspcUc6pHLQ2Gn8debNVCHiHQJtdrFKuG4NRNtZMp919vumavmmOCFDuWHAbnBZzVL0eY3HeWgzpWD3BV8CNupGkgZvtPPQU2wr8btkwLi+zYVsPOTdqqCLT1hIW8lD0Da41eFQPfdTZ/3sj93/zj2x6yfd1dCMabe6CllmIK0cVf8M1aGGgcqgrvikyXhS8wztSdSLBnqsPpuxQdi+8RKBpZ+d2YUBaO3ZfHM209b2OV76DLqnyq4M+gMd69lVAkhFwsm7VlsKKOTSFQntbBe+nx6OQA+k/2oWsX4wIO87YlMNCvbzIYPgSuSBMa/11WbwYTXhvTmZG5fY0/eXC3SipIAAMmOhYtilp0Kpp4NKzPtHUsFALDD6S1gO6OSm/MLh9ID50avFmYDA508LY9h+i4ayZ8xa6bEGs+4kWz+7g1sZ4vrwFciX3jdshIXRf0TY9+IQUqbAVu9sScNqYD0dLSpicgLAHKZNOcRPTuon4leyAIAfkPsfF3QBKBkcKDfTnE5brQqgZTmiDE8DKx+S3/Lkg+IWkfMfb8B4erti6VxQr0AAAAASUVORK5CYII=",
    },
    "A40": {
        "description": "seated god",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAAB3klEQVR4nE2RW0iTcRjGf///vh2aGnOtLAxzF5WdQ4JmBxECg64WXYR2UCIKhahuKiiC6ioiKkQpComwoJuiKBCqFSlZ1IwOUM5BEwUdY5OscKe+t4v0257LH+/zHp4XClpxIy2hoINiBb5lh7+Py1FVxHyfQk3r1zR0RpuNAuwxrzXYwPksvtRiTdmpeOLtDgcHpG22gfepOuOv2e7/XOftzeoZuDNwviSYrO/ykpmqsdzpAYDNY7X0yGxlqD9wEZBFrcVbbkrkXtW7dsnQsm6xoBEVyYmI2dwl1qJ7KlP2si8fzVaP3Tr78HBi/2C6kWppvzMzSO++7tv3wPP+Kz4QDEBj3ku+CZ+uGkiRNpVgQN2x/IfODlSFTmuGbq7KCrhuy0+54EZ1JBtBnRt5ndEsXPmjbfTUiVLy079AKcNQGu0K398bPblRVqfGgb8L1tnB3j1ZydZYxD/Rq0CfldGrmtyEZw59l6oeV2QEsJktxzVogEftZeZDwMxO/xYDnJgw1j1y5AVQujavALbEtgGw2AG4bkWWA5S/67NZYZW/fD4fDUrchVeXbOhPoMHhXOIqhJ3zKWDulcygFSHG3XiLYdQeOhh+ErT8+Zj7cqmKVNsTky7Q/5MVc577zz9Gg696dA5c0gAAAABJRU5ErkJggg==",
    },
    "F41": {
        "description": "vertebrae",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAYCAAAAAAq3gkaAAABj0lEQVR4nG2RTUhUcRTFf//neyrOOOMUSfIgBiEInXBRy1r0BQVmi2bRQCFtAqlF6Kpl6EJdBLpsoYtAjBbhoo0WBCHiMiywhlzIDELz4aQMTvp8p8WbDyvP6t57zrn3ci/UYeJvctda+R/h6y9+auG+VRcmNsGwf/7m0GkAFt+HFDA77cf4AezNuPwIQK70yjJQvHoHCtnXDh3ASFr6UtM+k2YbzrPSj+roGWk46Gb5bmLHKYe6veTWCp3PH7K7diECMUa+61j4ZsCaOgN8eOTaTS1m39tz5lz4NugChC5Kv3trM69Ii3ZbLZuUdKkar0ougDECmjzg67vp7PDlfpvPL2OOMAu98or5AQAO0j1HDjwWk54Ao5Vm02aXvV83bpGbCJuAPnco1bUp6WnD2XmEmdMKgLHvbss7+QA2Mq0AXrSHE/OnLCdvStFA6hMcbs8PAbDO7anlpWVJ92rdRiVtfUpFgmz8QNmW6sOyqszbjRWi61IS4LG0xN/ISJVCKS99/Ieg721Zkjamu6qFPxt+tBZvOCUbAAAAAElFTkSuQmCC",
    },
    "V8": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAcCAAAAABwyAGgAAAAwUlEQVR4nD2QIW7DQBBFn4yCLGMfINLCaG8RhZpYRUU9RGioQUlJuYFJtLh4j9CDBHTgK4izg/6b+XpgAGZVZwDmsNGo70AxeljdKLGNxRtJWdxiQ0khUdJVDFKIhqL01QRAMrrHLycATtwhWwGozkA1A5MCTNZ2gIiBwejpgPvhzJmvBwBZZx15TuiuBFY1vyBrAHQAf3Bo8Aa0muq650k/InoABr3w6QLAYoVBj8/vHNuq+rNbJr6N8aUhvOzS4j9E8YMUdlJamQAAAABJRU5ErkJggg==",
    },
    "A20": {
        "description": "man leaning on forked staff",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAAB9klEQVR4nFXQTUiTcQDH8e/+z7PJNlfT6TASrCwTfGEyMDEq8hBBtF5mdDAidrVAkjLtIkIaHYqgDpGHLD31ZicjiMxeFMQwM5Bai8RczrVNca5tbf8O2yP5O374nn4AtnwADMe/Lh5TAUAH9MS6AGtrg0gpbSMACGDzJoAD7RV+z89mscaxJIBD+WEZWirN1dhcFAcwccMz6TFlGHCEOgEq3sm7R57JW7uyXBPoAKCkWd6zn4vMdtsy9dJjHQBO2QmuoHygB6gMz9cAhsYvM9vBOCblZYMKOwzW6/1h9rTgK/ci+RQ4Pwi0Ll5KpKNR+dHzMFiPeeL1ts/XgBY/jtFfb50m9EOv8k6srh6+71UBHZOu3KUQJKdbnxaOV+Y8d4rMMYvfQwBTqdreo311MxbB/3sxN3ozPL7lj349Lwd60yxs7ShYz66y3zA23+Rbzw2+90DstluAql9ju38FEobxaRVqQzKrVVUf9irpHJsAeNSlxe64lFLKlBsBqBpvUP6272+TyRQqpDVVnUrfVYYjd4wIzBs1Lz7IAPBkbp8iKN2ZyLK1dHYKWB4pNgns+RqXMxgEhFpgFHqXZXeWT8WHUwAyLUVZHdVFmfjQ2BuAuADRuHAl/zSUNPUM4I0AeWfqk/DtJGe74WJUSnkBqO5fkS8L/wH7cbVRsJNPEQAAAABJRU5ErkJggg==",
    },
    "E16": {
        "description": "lying canine on shrine",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACKElEQVR4nH3ST0hUURTH8e8brziao68k/xQ1tAkypRQCZZJKWmQgFoFYZIG4MEn6AxFWUFC0cFUxkmFBWVGLpiRU3BQKEhFYEfg3wrQZTUacmpmsaXzvtBjT0cbO5p7Dh3sXv3sgUhPjDmKUZe6czcr5DxcbrsxlOcHR7H8TtxxvcvUE9u6aicWQUjYgrtR0aUyMpVVPA6ZzNUnd/rxY3OkTc9LtvZDz7mGM6xr2ylQjPXN7w9i92y3vAxC/IQ7f13mO1NHz1ZXV4Y4hA3u+Mt2Xuxa/kuw7bSt5MCEi/c9dg+I+sphtk+dAJeu6npSQbTsQ/lm+iHdL/d82o7curkuuWaJ058h0GQCW2qa2T8H8Bpk6ZgGwWq3WdWf7pWNlRW1heVdf0H19/1RTkRn2pQJIMBicMeT7q8Bbr/zoayktyMt1mgGpeXED4IkYIiLiPRFfcrPGoreLiIiYj6567KCldW9+9ljDMvIagFVlM4CUHmbbmfFToDkGJ/Yppay6ruu6nqKUUmrP6Ieexh2tGoBjSv6p6YKD/uyPDjRgOPH+kp8oX5Flb7+z3nYcYHRJwNA6DReHsodzNeDzlyIgJRkg7AVoK0wjYaw5KWMhunqPx+PxdM7PoYbCNYfU/Chc+sXJqKTv1hWzwHDFoCJqX31VzQPRbPtG9DabL7eEFaAZACH8YEZkNrJEQRTwe6MTKDBvhViLE2BrKOqVgUhSsyJimpF+dI7+AGsi8bkTC/LXAAAAAElFTkSuQmCC",
    },
    "G16": {
        "description": "vulture and cobra each on a basket",
        "pronunciation": "nbty",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAAAAABoYUP1AAAC7ElEQVR4nFWSa0iUaRTHf+874+iMjk3mLSZCTUrNLPISRkV7ASklKqIkshKCIpBdIndjAyMtCspSQ6Q+7JQgxtrFNIWoMJrKDBMzu1CpJW4rVurOmDM5M3v2wzteej79D//fec6FA4kdIn0L+f4ZU5cnqppMavp2/e/+uoDv/LgzA2878jSiWyRy+YbPs2b6mzu716cd6d8OwIvegd7SWV3xOXOngSp5vCAorGQwCgDF8qzJ3NYqtaYpQMl+K/L09nC1EVRk9A7OEd+D3LIpQJpKnba7nR15Of4fb/IoeW6NnJ4uctAdBxFlvRpR1RkVogZFtkup3u/PG7seCoTcs4erwODirNTTOUObnh9Y5weig+sdgNdh1AMs9j1ztobCii9tSzUg15MNEO5oDAVQ94tkAAFHpd0KwKGP6QD5UqhoGYWeOADdWSkEYKRGBSzv2uf7a8b0VACQ3H8nGODrJcBQLbsmp9J19Whi37+rgETXWWD16BXz1NzHB9MBmNN61QQ7eyIhrMGdNr2YeM9hTeTJEtj9Gub95d427aNz14cAsKit3krlE4wtE4dnnoDh40C+pja6d8x53sCvnq4gAPxnE/DqVL5VXROrYB9ZaQy6aVynL3ED4N++WP5MfxlzYuS+vfX1fMY8aiAJae0zAG/CyX888QNbY1OX2Ep+0P104+mK4txL4/e6J3tQx1zvR20fKjoX1HX3NXrthpRjPhF581ugH9jSYvnDdetM+PFzllPfnP996vv95182N4v49uqBH4Ojj13LdH21X/h84e5ovsEwvjZlQ4prdbwnQM1SWJV9aLLQw0ez9wBQ4ZhAiV2WrOeVQl71Gwc6AEUfGGxUhpyiMyvAhCcw2h0OkU2+qgjVZDKZ1KiLPpvNdzFKiyKqfDW1AoS1yOUMgMwGaTabm6UhEyDjsrQYywQgpnh8qLygoHLYUWQFa5FjuLKgoHxovDiGItG6SzovXq+UJ2hRQrl4vXI+Ccho/B/ysyLk+h5KzwAAAABJRU5ErkJggg==",
    },
    "A24": {
        "description": "man striking with both hands",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAABuklEQVR4nE3RS0hUYRjG8f/5/I5jozPlVA6DERQoWUTOKGgQZgOR0a4SIolCiaRVbSIQWrSuRRewmKCyRVBIBVFkUEYXj5Z0USwZotvoaTNpOuU4Hc/b4kQzz/LHw7N4X14vwkukR8abAMgc9KT83NzFa/1rAVUa9aj1sJkba4wCmnLtAITVxJp2XxZQ1FcD8Mq5fvyKqwEkvQOAshNOauu7ywCjkigGoMJOreycWAfqOWU5AFr8nV8vfd5ThPpB5XYAFQ/O4JzftgxiSZGze002vbg6WEPobhNwWp6MzPXvPnnL3z24igM3l0LsS1egI51zelgvjyId32s03yarAj9nQtN3iLlbngaXh6E5OWRJ1j6GfiBy+8jsLswLspDtbqgqwYjbmdqi+/egzpJTBgDBvr5iDj1WDB8dSAgAKza8d7FnNQzsT3r38VcMOQga+Cdm+3AyQKXP4H+WTLm/XSl9pvKUG1dvE5YuEPwp2cnq0akCisuHanw3pKDWhvWJ+d5fBdToWH/AzuQpEpp8CGiVp5bwyEfAzW+ZrcYZAENr72Mbow2bp99AuG7fYq9SPyYiL6HZSi/0/gW1FqJigf2dEwAAAABJRU5ErkJggg==",
    },
    "E12": {
        "description": "pig",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAWCAAAAACJLLHfAAABoklEQVR4nIXRTUhUYRTG8f+dSRm/EgX1RkNiMkiooLiQyFYVggnpwhqhpYriLlJwo0vdWAhttO2gKH2gObaIBMtFkG4MXRQoiRDiqAyOium9j4uxvOPM4Nm8nPP+XnheDgBQfaCXZRlcVl7pT7Al6zJ2S9qQ9nq8+QXeqwnuDQCKVhl8Xv7iPgA7nemAdWiljttR1PTduJ35xGUVLv0cAVqNxoq/rvTMFJDcsDcVHl6CwWevOZD0NVGOjonAmwVpwF0v2UjqSp65VPo9LG0RkXpLkjufJUmT+Ecsad6b1BVFJL0HaJN08ioliRv9x+DOYkhqSszenTPgniUNpSZkPetDzsG2NBrP3uouGS7HwBehWU/zfpwcbVXnmqZpmua164TJYj/mYUDxtbCrh3DFydzRIxjIcYERaXgEVIF9IcaY1B8830q+9K14RfLHs+wHUt9Ze0PyQZWtApxf4Iju8KfQ/3YaNmBxDTuGpdXyC2ZIi7aV5Xw8hJabxCwoZ1O2B9o16wHgg5QNrOqz4VC5X7ReB53LZ9n8x6E2D8bj7bkaOAVGccwmXNSgYAAAAABJRU5ErkJggg==",
    },
    "Z93": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAaCAAAAACmkeK9AAAAFUlEQVR4nGP8x4AATAyDCjAOSbcBACJKAwSvuZbOAAAAAElFTkSuQmCC",
    },
    "T10": {
        "description": "composite bow",
        "pronunciation": "pD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAGCAAAAACK+rNEAAAAqklEQVR4nI2LIQ8BcRxA3//cjcAF20UzmyQQbxPYBQqbQNVtZj6AwuYDGDYfQLwg0QQiwReQBaMgcOZ+itk0r773lPAHSyWwPkYV8ir8qkVQA8A/W85Bv5jMBgA0w6dkqJL4VOPWdxg6PuWpyKVoA0Tic0++dDIAmG2RfUqBWwO6oj37wOOmA3gW0PM1bvU0u+xdgZFrxGzgunoomWwCAFKqGnkTgO3IvfMGqIs9EqN+YSkAAAAASUVORK5CYII=",
    },
    "D41": {
        "description": "forearm with palm down and bent upper arm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAAr0lEQVR4nGNgwAM0r/9cik8eApb+//+fsLKd/1O+/c8ipGrPfwa9//+NCahq/a/KoP1pJxcBZa8OsDPk/O8moMrw/wQGhmeHJAgo2/lfj6H0fxojAwODdbgcAwMDw6OVR7Eoc9O+9n8rA4P1pP84wYv/////f/PnO4P+8v//909imPT/////33Ao/sp4UW/jo5VH+wov3X2y8s5LBnGVcBkmBgYGBgZpE6ilZ1+cBQB87nYfDxas4AAAAABJRU5ErkJggg==",
    },
    "V21": {
        "description": "fetter + cobra",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAABoElEQVR4nH3QTyiDYRwH8O+7vWz+zNbKvxgj5qB28OfAgYNyYRitlORPDpSLZUqIkxQXZSc5OShZKcuBk+1ApCiMMDYXf6LMNu+reR6H7X0Te/c9/Z7vp+d56geIyZv3Uhp2dyThX4pc9HBhbvWZ2BR/Kd1BpgoApmYz2CaWcrVWwwLVr75MAEA/XZYLNhrhySQwROzRs+Heq4rRuN/V5/NXYZaaokXaBtVGJ1mvLsc4kzwOgoNoE7oQXpS1TqAl7K4F8BmreNEuZw2dFm4bAIlVBIwMAMACSKbyDUSQk6HPy35/vMhFkIhWR2jhcCO2UtQPH2xJQA3X1eIxAAbAss7Zo5TfuO4Iz0ZImC8fK8PgWgAMgIElxznLcbriEoUqhOtbz1lpXft+9zMDQG3KYqm5ZirM+N6Uhcqmhlf7er79bERc3TQVJhu1Pr6YmqlVJjRJEDalgN1CV/ac9aL9Tpq7S2k+0cc1YNfTqeDZ+AavIfgtcQ9fFRZOygCEEthpAgskMFba6Iu0He1I2aWHk/zPzxmrpWz3W1MpZdzTU+oPqXyRZvhOKZgAAAAASUVORK5CYII=",
    },
    "U23": {
        "description": "chisel",
        "pronunciation": "Ab",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAArklEQVR4nG3FMQ7BYBzG4d/3+icGFQlhQuxmg9HWxeIQVrtbWJ3BJdpEjCaSJiLmGiSaRqX0cwHP8pB5732mLcDWguOGVUC6gEWqPIEkV70Jzbp6U5j2RB/62G5gDHY6F59PcXapTowrd3Ujbh6G9/sQ1ZZRtKzRimezuGWiABnqIOx7WLP/ovD1CmXVJfVJZTzfLsd45DwwypISAwcI+FPQaASISbc7QW7ebs/dD20UOydaXiOhAAAAAElFTkSuQmCC",
    },
    "N42": {
        "description": "well with line of water",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAATCAAAAABXO2kQAAAAZklEQVR4nL2NMQ2AMBREXwleqgEFdfBtsNUHCtDB2ImkDmqjBo6hIaGBgTDwpsu7+/lOODrEwJ0n5/RuN/L9xy8uEzoRyKxKnUtaMSleVJQMQlU9z1t2EBZP2QEmT5m3VltSIxnAAaUIJZmXcnBCAAAAAElFTkSuQmCC",
    },
    "I8": {
        "description": "tadpole",
        "pronunciation": "Hfn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAABaElEQVR4nG3RTyjDARQH8O+2mH8p/xLJyGVt9dtqGw6UP/lzUi6LNgcXB6UobsOFsnZSSihJWVwm7YDL0iSp/ZHMFH4Rak3b1Mr+5LfnMPvN7PdOr897vffqAVCaEisqEf6FyhGk2O1CSa4OO8muN5jpRJ3DX/Q2JgbGH/y6vxwg4uwA1I8015TlbivRvRxAu5+uR7NeMRujVQkA+TIl9uuyBUMywgCA2PBE51kXrZE+nfVckK2Sd8Wdvyyd1WzSsYz3CY4BAKYZRTaa51nz7igE+talQO1loDrDxR7OiFLWDACD4Wm+fZF2oA12AQC2fA0ZZr69jeVxC1AgQUtohr9xm45GIjEjqibbsHEgzXg9S0T0aZq6+WjtfB3ipw+w9BtX2pclcYZPO3rPnFZlvyfKaHzIexZkXvdzKk8BSzLuFGBFmFgBlu4RifM5FQUEmHPHhDjlCgkxiBNAQLortBIJFwm26w5/ANKUjQ0D4FDrAAAAAElFTkSuQmCC",
    },
    "C20": {
        "description": "mummy-shaped god in shrine",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABjklEQVR4nE3BS0gUcRzA8e//tzNtm2GJqNkmLj0PsbEFWcHSpdehDKRTh6BTFp06dYsudvdQx46V9CAwiiAKjOgBiWGLgmKbNOrYtg9z151m5v/rFn0+hh0XrlV6iQu/anO+51y53rt813Rl89CsbMFX1RF4q/776uC4XAa6kzfytH1uXV7glVWtHn23+qwW/Tz8Qo4Z2HRmaW1sKtGyDVQnGrr4yMa/VWdKcp/RKg0/lNLQpUy7PGF1TO9ctbzxBhycYb52avli8Hz/yU5/Iw/07KTOB69b0ztvTxTlViQletaNr3izRWdNlibdx3z6eBAwUVIq085T7p1L78V0ffEknHFrRN7WflqO/AiE+ul2lOqhZKJ7sSnY3Sksw8dzkolUwFrrMhLuE2IjgJg/NL+d2EyAEMXGuKzM5lJsUIFIgUZhVxIQcIQQynQoCHE2hQN1PW9AiNYnUJhaOAUICkQw/b2ssRHc2NLnku4oGItgEyF9B/bc3P6SIHaokyX7ARo58j1kRrWo//BQ//cXo4HHYN0cCjQAAAAASUVORK5CYII=",
    },
    "D8": {
        "description": "eye enclosed in sandy tract",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAABZElEQVR4nHWOT0iTARiHn2+NQF1UoKLhRmCEICjzz00FG+ZhnTsN2gKDbokotkhQmOA8eBfFFAU9SHVxEUXEaILLDikYgbkdEv+MHdKNtW/48/DN1cXn9j7v7335AeBsC+R0QayzvdV3WhqVfXQDADpe7ST+6fyH9c09/ccPPxjcme3i7Rszlypbvg5A6t1+hPKKK9aP/IMAnwdoDintBPCES/dbvv6blHClNUZSegnwRJJ6BlYXwnuSlI9HfJ5i7oW+IW1aqcPJhBqB7gP9nI7uStLCircd4FhIz6BjUZpr+qQjICs1ADPFAu8b4UhIcfh+0Sp4/7U0Ad1ef9F8rYX0qZF0/a1LOR7+ueU3b1dbXba277YCZ1/KbJn5WXg+HjF6g12HI9PW/rFNmcEWWNow8yr/uGPZvlDVkOFwrzn4dWxHyp6Yyt2rgejvq2CruGYHo1BZz/AU4B6NFXQ5hfWnds4BXd/15CrkpQAAAAAASUVORK5CYII=",
    },
    "A14": {
        "description": "falling man with blood streaming from his head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAACPElEQVR4nH3RWUgUUBjF8f+Mk7jUGEWNC9VICxgKLZSUhdAmYUIQSS4UEVFRVi8VZaEFYb0EJlZvJdNDRYkt0uYSZWTCSGa0PCTmjObkXo5Oo3Z6GCvT0e/x/g6X+50LBJ8flFfVcxhndqvDdvK2J2Mcjqvs3sHklP4rZr88rUqte3Ofdkm39q8dywZbJnQ7y7+5wtMXdt0vqhgdkCrK2+xWYO66w2o+GznKO9w7l3zJDJgUHQKk1AxUr/zfa7+nkddW43KfAQg95/UULAge4Q+HjjEl/81772UTQHDac+eAPT0u4o9vVAHAzLqP1uGTWTmv3PqwfQoApl5CAIK8MbubZxgN1eU/HacvJCdtLYo7AkCs7oUAoZckSeq4kWMG2GLv87VRqfZUgK1e6WJKau47PTtoAPIHjg/vr9YsI5iLpcVgnJUsd8EkqOpOAiDhgeR+Eh8VkC1tA+CEmhOJ6nRMA8C4S8rNa+zs7ZXKAHirp8bQF7rq2yaxUcqevSjPI+krwPzeXwfY1NUU7vMNr4ckx9v675IeAxSq0LS+4fXqPwVFlqr+us1W5iwtjAHW9NQGLP+sZf8a3qNDJoMxKtFiAEw2pXBG7UsDfWgAS2xd+99wUEmSNexRxOCnPvcQwm0Cl2vEd3nFzf6Ihrog49R4/M2+NknXLObAwOkxWS0aG7AUfXJ6PCWbV0WbSejxe8e8Y8X2funOWstdvw6EZeS/lC7EjeeA9ZRDRydwuKaWCX1Fk5/3jxhD+o/fYCT+D4OGbE0AAAAASUVORK5CYII=",
    },
    "S33": {
        "description": "sandal",
        "pronunciation": "Tb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAABQklEQVR4nAXBzSvDcRzA8ffv8/tiDxgKy1Phsl12oBTycBEpSp4vkpxQzlP7EyY5uTmIIxflwHJRc/KssBqJw0Ie5mHbb/t9vV4AZaMX6bkaANyr9xn9vOUFClf123o4pvd80Pp+VOswvMFMGHNeD2MUUnx4JgUdDzcEZp1fO0mxc3dxmhcdRBMCeQrTKwzWi6HsLCnVSeOPZBN+PzndhX0u1p7Hh013fsoSkilLKvKqAtW2EH/MufpwDpVbirePkroArgkrorB+ppqqkYaza6A/qbXW+rRGwNCkb7OIIQBExr7ZfRXIit6+iHD5B0xnopW0Jzfd4DzQa1B68j0hxkIL+WCa7kkZnyoCwKBLbahfZYJppT0qRCzoAfNlKQCwH4KRqwaHAGYcfEXulAAFbdCb+ARg5WlgRi8DgD/6/nXcA/9FQXgZtwvBswAAAABJRU5ErkJggg==",
    },
    "S10": {
        "description": "headband",
        "pronunciation": "mDH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAYCAAAAAA0FzmpAAABPElEQVR4nG3QPSjEcRzH8ff971/KOeWfQSGDRB5OyYBSJCRK3cZCecils5yYDXJlZZFcBsJglOXqRKGUbjdYLhl0OXk8fAz/e8R7+f16Db9f3y8AmLWepqZGFwCM6LYZE4DeCUs4N+/CQEMfVZ4oQN22Uu20MyY9KQhQL32tAax+SrvHOtiwPaTXMvvl0qAknUgBcE8qWUE6nyQpBHgjWifbpSR1AAnd5zB+ScsAsj/JdCRtAAY85vkTTA2CAY48N4Bi+8grCUyDYd+ytQJdfkjoIpdnJEnXLrxnGsjxTXtR47h9Uk+GV6SYJMXAutFVd4pnpb0pSZIDasKVH0PvTr6L/P0PWwuct3G3D1Bymt7/ezVwKM1jAvHO0bkXMOPDABRAi/P3WEBAerP+zAsReC78xz/BWvzHo0tQ/gPMi5zXU1VIQwAAAABJRU5ErkJggg==",
    },
    "M13": {
        "description": "papyrusstem",
        "pronunciation": "wAD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAAA8ElEQVR4nC2PsU4CQRRFz7wZdo3MRinQ1oqKjmoqfoDCBGPhZ1FtR7QwobOg1J5QaEzQkFi7YmJQIWbXCDyL3e4U5ybnEoXRUnU5CpEZnv5eb3AX8Q1TXRzB8UKnNAZ6Z+2tDhpgx9rv69gCdFbz+VcHAK5UL0uip9oDBMghr7AFrUqYqE4AA7xu0BMQkL3nJy8g0Nx//0ya4CCWDzExCHgxO+NBoGuyN9MFB/XihaIODtrFA3kbHBz+rVEPDnT1zY8DB0aVosrRMsUBkSUqcZsckGxBYOZD8DMAwi4dagCg9phl97Vyeq56Vh2yaeqAf8zqU+iNIo9RAAAAAElFTkSuQmCC",
    },
    "A7": {
        "description": "fatigued man",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACT0lEQVR4nHWQXUjTARTFz9/Nv27J1pIxU4RQFA3rIdoEV64PikQoioo+BgvBrCDCmtDHgw+KDxUUgUWkbFFLVEgsqKzUGUkTGREaJiakaX7NRKem+287PUzBrXXfzv1xzz33AuEVZ3UtcaJ2E6JX3iLHyhsDHUkhKY/AuQrE59T5j6aNAwBiwmmMEfPt29JbvQFEw4ibqTozrVhmIKq5IM7WL+pMebLvUZMJ5exUnyAr/pNc18jTMQ9piAoV+18tDBuhsE1dSPyXyq8x2JgHQG3xtBwQInHWIFuUIZtRNsgjDhOPpc1s1gMAUpPhixw2c6Kw55EMAB6TTZEP7ZDKZXfHtwNIn/RO/c4Np4VsV+EwLwuAlb0feTBsd0rZr6o5dLpOaQARgoDgWpzRZLr0DpgfJgAJPmLXGpzg0D9rBiDICEC7VPEikLEGn9fDrYhdtcoWvnyYNppWZeoNifSzyaTB02415O+lfDwPXlmZPdlNiaysdLH1alebrtT2hzW4zm+ZAICLS7S9JR9AZ74XpMdFt3moAxvc/hIAUP5ktdjrH1pu0CK+jL7RgvV4/SkBJZzUA1B+tscdWe5LsfTSXrv49TgApI4ZoXKyGYBML+INW+OR7CDrQ/uKutSARQqGsmX2LxiAHS0zt9ShRo8TgMrBkLrPO0CxNLJ35dDigB0AcqoBYGPRxIgG6QODBaJCuXV3vvGsRyrduUUJQK7MOLTPIFpnkZ3Uv+ecIGRpA1TF4ua8p6+9xosnP0jWJQLrbs+RJBl0O9vanM4BvtTiL5nT9yeR4z98AAAAAElFTkSuQmCC",
    },
    "W9": {
        "description": "stone jug",
        "pronunciation": "Xnm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAYCAAAAADWyyLQAAAA00lEQVR4nE3QoU4DcRDE4S+n66pOEcSFBFV3CQ4LkkdAFIkhhytINKJPgEKjuL5DBSEhTS64PgAY1CD+veTWbPaX2ZnNcppJ3XKynsyvM7qkrpOWNplhSE+fJcv0qI69s7NgYYeKJ7YaGltI0GYgaYsCF47hZ1TMkoEh6wI6j8k5Tb7rQ2xyCVfJS6dLbtJT1Ek5fV1An3mqr2fKAfCn8jkFHyoeWIzg6B71xONNxX6jGRV3YJVhjC29KZ8poMKeGmWxwu/GNZzZHKxWk6ePJqXm/AMDkIbdnzKQoQAAAABJRU5ErkJggg==",
    },
    "D39": {
        "description": "forearm with bowl",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAAu0lEQVR4nIXOIQ9BYRjF8f+LsRG0uxts3BEkxWcwydgETRV9A002mi5Jomg2gSS5TXs3QbDZbB6zR1G4rzn1/HZ24E+6Irb6D3lbERkC+KVCMfg9VbVHoK6qqg236sgUK7FMbQnA2K1SHABaa90PJifVilP1z2CFi94ARnpyoYycwUosywpgTtqlctwBUA0h396pLqLIsxKClQSUb8k4QPNpDMDj874PmFnN+xp4EIkJOr0CANfNuzZR9QIhcUMlQ7P/1wAAAABJRU5ErkJggg==",
    },
    "A48": {
        "description": "beardless man seated and holding knife",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAAAAAAJeWG3AAABsUlEQVR4nFXST0gUcRjG8e/+dmacKTHKDrlQHjIpFDIDc1uoDiIRmGiQJGKnMJGuHiL1YERB0GEPdSgpC8NiJejgpU6JB0Uvm+C/FnS33WTFZTPUbXVeD87k9B4/h+d9eHnBM747G7Jy3eC/aZ6VH4nYoyNeK4+KDFQPSZsX74lsJp4c/TrtscKIvGutm6L2F6cKXKxYE4vLS+cD39WncLGDG6s0snWgxrIQeaP20F+/LO/r4133bURSZ9yAhtHV2ZxInCWRgf1lLyU6mBij9ovMaK4Zr5PnzOEpaFjL33YxkA7D0KTic5d21sWdop9o+iFFUaU01Th41fBjL5fBxYzIuHODV8kQXEkr5sJZgt17XQtji5DLA3SKyIODAMkeIJTSgAkWtH79YZ4SYv8aX5KbJR9yd+HpynEglFKAjZW69ex5N1b2DwAa4KNlZL3PfGxURTKADUBQfp+Aghci7QDXkgDmWwkCeuvcSUAfjALQK98AUAD6x1EFEEcHN03pIwpgLOp5ACGtABbmPVha+VcBFB/b2kfzcEADuBGcCZmObZf6OjTAuKBOR/wO2v5MdhcWKpxVAuOC9wAAAABJRU5ErkJggg==",
    },
    "U25": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAA9UlEQVR4nLXMv0sCYRyA8ed9i3qPEBpOkhAaG4raag0aMghpSZwbDNocg6CGqK1f0NJUVNAa0lLgYhR4amhTYEkNEmFQEJzHcX4bUugf6Jk+0wPtZstDHQ7fpNoaS98/GgBC01WpjQJYU9mqNF5PRyB0IBtpceab7zF264eFp8A7rpw/I+v7tdjF8pe/mKPZuNp5eSslztyWXu371vZAeMI1d3p7Ldoz8+GY8a0FUFYX9T1lKboRF7QRFzQAuhc6Rv6Y/zIAk1KxAQVEjj4H8ytBC1BxiS55tgZwAvF88TfRcH3LZZHMAwBzYpJi/T6L+XD/iQ8/OR5XnjVflyMAAAAASUVORK5CYII=",
    },
    "D63": {
        "description": "two toes oriented leftward",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABVklEQVR4nK2RzyvDcRjHX5/5fqNNrS2rSfLjMOUqUg6E/Auu4qCk1P4IJ0U5WJTiqHbBbVxkSllNcrCSNSfZwmYZ4/s4fL/fMfvhwPv2fF69n+d5Px9afP5FkVxGIoDy+vyzIvm0cQUA2v37rZG4WI3lAOSq5cZIXK/tPSsLEx0BcJvlR7IbAIdh456pF9KxrFk2e6fzPMbvjIKFlxvm+nnatWYtuScneN0/1QVbbcFdEZEIKAWu4LaIyJnJFEDboObcPBwHBYJnuJGtyz7brRSgyQHflI/bqyEALsplBXNYpVBVjurPv2GtLlb6n5r/L64evBYuu5qqsIn5Fba7WCinDU6E0nW6vE5n4KuHSPvOxtFDaVBGKpQLD1hTlay0/hit93Y2Hc+fm+7K1RiNipz0lcX4nkstyHo2XAMDgeTYUKo21kMJz02Vd1szxdRbHdwRKqY/Ab0kgh8VNo+AAAAAAElFTkSuQmCC",
    },
    "D5": {
        "description": "eye touched up with paint",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAALCAAAAADdUxuZAAABI0lEQVR4nGWPTSjDARjGfxv5yIWYTSOEiDEXTMtKazfloxTlJLlQlnBzUlgUSQ5uLkgpDtSOu4hGloMTNSetls8DMXsc/msrntvzvr+e93kBhjftkN+4mJQkRTzOYv4oG4hu/RyZLUMOEwDO2bxgOJRat39fp9FtpRSYmpmISlIw4LeUY/NrPRM4IkkbXo0CON51sS9JWpBUmKEKpGADlS+G61UPXTsPRnp/hvJqBWh1G67KyBw4iEuKl6SpUASgZdpwPvlS88mwFOuwAtC2pzqAMnUDcLoL5JjNpr7BNUnS6ji2Mem1qdPjrp+X7ly1x9KJ3fWYejp2fnl1+7TM4Yc+9V+JhM6KrBXGZbOpVAJIVs/lqrkG4OY+K770bOLrLV38F2DsocQkaupyAAAAAElFTkSuQmCC",
    },
    "G38": {
        "description": "white-fronted goose",
        "pronunciation": "gb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB/0lEQVR4nGNgYGBgYHW68P//UkEG7IAp4fjDFZ8/5jFjkWJgsFg59U/2q5ovQaKY0izOURFcDIYhLL9/Wum9wJR2VDj3l4HFC4tOJBDy4P//10o4pdlv/n+QgFOWJfXX/5UcOKWDPv3/nIhT1vTs/3/n9HHJClz4///ft51SOKS1/l82kJ/54VijjDCWgGMo/pbGwMDoMP3i85MT/FgxpHtvyjEwMDAIrXz18Nu3eRbIUkwMDAxvRZQYGBjTjr+xtjdcELhxlQ2qFSpfV7AxeL+2YGRgYGDQmXLz17ZwZCuYZv7vY0y6mw7lihSd+99rhSSvvP+/If/p/yuMoXz5zv9PV9sj5AWrn02SWf7rw81kZREBRgYGhtJn/99NF0YoKH8+VV5k3fErl1/+nxESEnPt/f///68FyjHC5C0X/Ug+xSDBpOXFxSAYxAIRPAuXZtBfz7rr4JJ/DAwMDAxmwr94jCrYLtxHcqDU1f8/jzTZCTEyCM29fffh6///vxYj+1/n1f//724/64i/+f//3weP7736386IJM2U1cXZtj8hmoHh0/r9l1j/SAZfQgm+yF9fzRk4Zv3/nsDOwMDAwMDGjSK94v90BgaGtP/31GEiUB+wcv77Y6tqzsAZzcZTy8DABpOG2K1WIvvvtwM/TPCe/xVkQ7VO/kcBj81gMgCb6shzXfD0EwAAAABJRU5ErkJggg==",
    },
    "O10": {
        "description": "combination of enclosure and falcon",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACS0lEQVR4nH2TXUiTYRSAn+/b3ApFC0bqLjJCypIFhYQRKIkV2YV1USCmBEVIZBgUSWGJVlKZTIlZXoRp9EcZdFHRD6UG/SIaDAkFEU0zdTrdmrq508W3zS3Bc3U4D+c85/DyKsJSocfeBv45r2BYFqrujb8DkJGKWAHjvpqbtpyFpucOAKyC2GDdkxkZk8mCEH4xAYBNVMBYlmX4uqbYfyl+kVsFovOVvhJMcauvJSxeDVw7005uMRwsVG0JhSPhUEBswOb+zpTtJurkapTmdprNZrP5rrYay1+L+B/rYxvkPABvJRB6ADxz7krHM99UqeFM60fg1lsActO1bvLtmi3u3u/sBbdVVC2xswIA54l3LRtC2EAAd1KhJZOnf142Rd4NUL1jrZaMtuwvC7/NBsAq76NErRB9wVMcYDYJYl2VODNSAFCuyOEgDg6ftxPV+qUqC5Dmkerc/4azsaO3o8jhrF8P+ryxYUtkN309Q7ofluIDH+oTfQ+OcC5yczyD99uLfjVlJhzrrd09XpCdp4vAzFT8SYwlzeXyTB9tb155Iz3CTaVMuMuTBhpvuzN1h/p98t4QdhhUSo78HR1PSx/4ZCC52+c7pdgCLwbgl8FpeTr5nayXDwt6j7+RXSOeMLdfcXwbvVgKPQVb69Su6y7rhBp0K8q2fk/58OwmRQX2DDVietWVVKe5Y2pmXV4REZmZcp81QpO4x8a7LLWiZw5iYxoQQRFUrydZhZLPlsHuFgRF7G3Mu0MbKIo/RmV+1qfqjUpGqrL0F/wHB7oFQvxF5nAAAAAASUVORK5CYII=",
    },
    "U5": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAAAAACzJtCvAAABc0lEQVR4nIWRP2iTURRHT9JgwIZ+UEQyCZWKVoKIRToUCbRRu3R2ERwUDOhkwUXBQTp0ad1MlhJnkYAIBQNCl2ihWyHdFBW6lWCwBcmf4/BpbeL3kbPddw/39+57EEmuqTZz0c1/BKoGR3UyWktSTpT76kjSAHSHhaKULAzVKoL7R1kxoXziEhfGv1bGh6W+gXX1XXHuZjaI1T7bW4TndlV34scVtXkWmMo/1vCo4ACHbdNF7Y4BzPgjBVCo8Wpg1p3Or1KtceJkC8iw8WdW5b8NBPacBfJuT0QlhnC+Zi8Fk+6PkoLbg4Eh2UaSqQ65j6wexO6Ze/HTzjm4Z306zplbbqtm4YN7o5HKqflndbVXmWVs5dAHUb+VWXiyox5sL6Xhrr6/HCEtvFTd2liCM9e+az1zvJs8HQQX10qq3x4BcL2kVvN9Em/Dd7p19cr0X+XL6z4HEosPbwBlgPsAtNpPdzcH75PwWLHbSIxUq62+s5DfONXLLE2GUaoAAAAASUVORK5CYII=",
    },
    "N38": {
        "description": "deep pool",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAAASklEQVR4nK2RMQ6AMBDDXP5eKS/tHxiQGWDlegOZLUVOhnRytChQVyogS0WjBReNosTzk5saHoxYJKB7hetVIDr3pU2FziDj1xdukDFd8bEGdj8AAAAASUVORK5CYII=",
    },
    "W23": {
        "description": "beer jug",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABMAAAAUCAAAAABKPlmoAAAAeElEQVR4nJWPwRHDIAwE15m0GFIKbklDanFLm4fAliev6AGa45D2NkBKbfAA9iKVXtdB+iDmU1yu0JFXADw70Pi8gDetHTnJdM0PKlGkFAPQfmp97rYy62K511/ahb+6UZacXDNS4v0YC/4yRpkyVA9vKekZPjLkFxBxVkp1u5dBAAAAAElFTkSuQmCC",
    },
    "U40": {
        "description": "a support-(to lift)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAAAfElEQVR4nGNggID2/5sUGZCA9eO/izRQBF79vxqBLOD44P9zXyYkAdE1//+nIqsQ3v3/FjKfQfrgf2QNDE/3M6DwGf6j8RnR+Ay04ktmSqLwNaZpoPD/MPyhqf2k8r8yfGVgYGD4ycAyjYGBgYFBkqH2OQMDgykD439U9QBHRSACbbvqSAAAAABJRU5ErkJggg==",
    },
    "C1": {
        "description": "god with sun-disk and uraeus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA8AAAAeCAAAAADWNxuoAAABqElEQVR4nD3P30tTcRzG8ff5Ot3xNJM0p9IM/LEkESXRNrWI8MKEoAJBhUC98B8QJOguvAi6CSGo6KZAL1z+ljCpmxWiCBrSUGcDp3NpK9sUp2dtnW8XR/pcPS94Lp4PAPBMShm9Z+b8qxn21ejkRDRYCUDz1pNX8mmm2hQeAyAn+TW8XQF4/TYExBPJ4MEuYBQ3IOCv74Ja+qhSu12y0WEDaI0ZezIwd5B4fNKgAOJ81rw2o7gcC/spARgRd15yZ+jmgGtt0ZzwLrTp+TWVOzN/1vTidF9hr+9c4596AUDI+VFr9Kv+pRIFgDvjCrA+XLdm9mtTwag0pJSzADiXNx5GDGO8X24C0Ll+41bsw7LbsZ0SSvU1y5sab5YYXs35/ilNtL0d9Vw55qLmjTuMQ0SXc/r64GU0gl9+w4lI8LzmeKpC19NejBDLFBO0h+77ZluWUkAu2Bf0PGwe+QDg5TdL5L2r7OdRD1sAhKH6xwigpgPqaL9gJVCugp4E8qsCAl7b3eYXFBTtCPicfenUVmtcQIY1+9RHnLFAN3eLTRfSDB26/H/G4T82LKjYI8uF3AAAAABJRU5ErkJggg==",
    },
    "H7": {
        "description": "claw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAABDklEQVR4nGNgQAMej/4vZUNwmdDlmRgZOBjxyKMrH4TyHATkL/3FL3/gD375XwTMZyIgj0vtqDwDA8Off/jl5QRQuCwMDAzmNl+ZWGb9YGBgYGBgdeBj+Iyigq318s9Pn7+tmTnPhIGBsfT1//8TkGQZRdIaWKHsxy+YGFV5GRi+nbj4hZmBgZF16gMGxoZYJYanW97/ZGBg+rqfQbVW/fKVSAYGBgaG3/8Z7+2sZPzKdbXh/pU44+8MDIy//mp4vk44ZyP+l/GHXJEoA8PvSobr9UKMIgs+//zx/fuP37//X3JlYmBkZmZmYlNtfPP//1VGjSdfmDNzL/zk11NgeHxo765n/2FO47QPVLYEACoYWCjuEefyAAAAAElFTkSuQmCC",
    },
    "V10": {
        "description": "cartouche",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAATCAAAAADZ4SBsAAAAdUlEQVR4nMXSMRnDMAxE4feVQdiYQSiYQLgEgoGEwiEKgNelnVrX2nrzr0HSAdCGs4wGKMA5Rarnix3voc+0oR67Qtd8RwAtGmXXTBFAVMn9W0FuxfQF61G8FgoufSwRAH9i23LTDap3K36h+NNqQ6p9q7T3Cb7hxtUmsio+AAAAAElFTkSuQmCC",
    },
    "V3": {
        "pronunciation": "sTAw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAPCAAAAACt9eKMAAAApUlEQVR4nI2RMQrCQBBFX8BGSL9bprf0Eh4gh0lrZ5PCU6RbbD2NVUBIuQHLb7FmGcWs/uq9GRhmGACCogIpawxBIYSXr3AFCL993KkoMKDodJGKnLSTTkVOOzj3g5OrK3Ml/slmBqiBeSnVMKfSZ5ooHRa5GO5lBFppzDIq5s39pMmccZPahXcyL9pbwdtxveSzXKWGry0XdcbI8DbumGXQhJHIE327j6tzODJNAAAAAElFTkSuQmCC",
    },
    "F38": {
        "description": "backbone and ribs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAPCAAAAADFBmC0AAAA0UlEQVR4nGXOv0qCcRhH8RMVBlJJm+CSo0OCNEQ05lboewHdQ0t3EGQgtYg3YVP/p4Z8hbbQKzChcImgwYhXOA3208GzPPAZvjxoDVKbC0DxPEVIn2Hlah1ID7amPNRTOOsDvFoMXO1oRMkIePE3cCYa2clwbxnqWp7OHOsdkQLvfi4Hzqm76APs6EngjS99o6cxi+p28EP1MqtWiLW1FJ5Rf6qJWnhSH//5SLX/oX43EvUmvwbsOWs0OReQTZwPOIjntAuw2lTH7evb4QTH7f0/7leql1HgK4kAAAAASUVORK5CYII=",
    },
    "O30": {
        "description": "support",
        "pronunciation": "zxnt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAAW0lEQVR4nM3FoRlAQACA0fddUG1AtcCNYASLmMISos4UigXOCpogCE6whD+831qiXF0duktaCsWc9HcU716dpmraa4ZnewY0Zz4bGPMI2twSOBwEwocMwddf/gKb4hvNQfQ+EgAAAABJRU5ErkJggg==",
    },
    "A3": {
        "description": "man sitting on heel",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABYAAAAeCAAAAAANjLGKAAAB9ElEQVR4nF3QT0jTARjG8a+/+WdpLshGoFIedqgQwYbZIgrLIDxEpqAVSWlQdLCwTh6qQ2RCUoQV/oFIKY3+SSe1izbJzJqlghVLAmvFZrpMpmPa02G60vf44X15Xh74NwXfpSsJLJvUodCQa7bMWMbN6sleV/3rwFLdNqFp9wVTQxVAdITzze1fQidbJuaXbtf418PInU9HASi0LHCm900GnXLbAJhpMi/4OdXH2KcehT+UKsJqzlNnCju9bUkADWPegwC2Vm/lRmB3Z9smIO743FQxGDV6Fb5aNfM4HoiqCEyUxG4O6XVCEsCKQZUbAGcVrH8vTW4dKIqDa1LHagBrn6Tp+6PWp4EnOdnjLVO+DQCk98tTmtBjsn/TB2dX6oDKwzFp1RnQf4r9TX75SrvUCMDaE/kW+DgCnJZfkhPAdFFyNqZefwtsGSgsqvT3RQMkMxlfamnKguiS2W4f9/YAmOrUG5v3NfjZ4billymLlRpnNJfIec39VPeD/mQAA/jjwnQEA54XF9y0LhYKic/UscPdkBEH++ZLImy6FAz8rooBVrpUHxNxh0c3EsHYXidpTYSzPMPxkF77Q0v4cKDQvKt1XPN3L//He9/pxUO/RpvLyFEwCQBLbu24JI1dtQO5uh2OzByU5G8/ZIsCODacBvAXzjPbx76CiagAAAAASUVORK5CYII=",
    },
    "S39": {
        "description": "shepherd's crook",
        "pronunciation": "awt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAeCAAAAADF4FtcAAAATklEQVR4nNXFsQ2AIBBA0e/lCgumcgCXoLFgA8ayYhBaBpCCmJBAaM45fM1DfbXnUuJY7xqR2cIR2sSSwyUTcqdnhB3Y0LMAoDcACP/6AwIgF5OcbltGAAAAAElFTkSuQmCC",
    },
    "F28": {
        "description": "skin of cow with straight tail",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAABMklEQVR4nHXPvUtCcRTG8e/9XTXf8gVSCCKENJLWhiyIJqEhQqjFLVqaa4uGoCFcarKtploaGvoLhMCGCMsCi7JCKkNCENGrXfPXkMJ16Nk+HHjOOdjnEnVdSinbrddpi7Kc8L2kChq4gtHitpIMHzy8fQJiaGQ3beL2GADahXIlJy5DdjrxerMi73N32T+AEFJ2GdCKoq0oYI5PAp5GVTgb37BydGgBPupiKl8mvK4M73gAhL8qrVtBHGu7tED8YEtGN+/uF2f2XRL20if5ONc3zOaez9xCj4xunKJYHalVe1ljPjuuQqY4BrEl8E8A/kdtAQBTqQSE3GoAAAHAoM0cMlCAbmDE2flC0JP/KHrY+jJQpZ41MNNU1b+rALioyCfD9D2n14wLYld9xubzWhOAXw0vYmksfOonAAAAAElFTkSuQmCC",
    },
    "N18": {
        "description": "sandy tract",
        "pronunciation": "iw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAICAAAAACw8NI0AAAAQElEQVR4nI2QQREAIAzDAnJwNQkYGQZmYmawUxyM5Z27XgqW+pDG8A2XigUHKay0sJCQ1xKAa/4lgOZoN6F3yAMfglgvV3EzxQAAAABJRU5ErkJggg==",
    },
    "S27": {
        "description": "cloth with two strands",
        "pronunciation": "mnxt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAAA9klEQVR4nL2QvYrCQBRGz4yDpLAULHdKsVQsfQG18znstRT0DdTeVtdabHyDfYFYrWAVBVEE8SdjkcRMxIVF2P2KgcPhu/cyADDeYsX7BEACYIytQpA2vFIpYavUL1v/uuutM1Ril7KVnxjo/+muW2LgzVaJUkTSeqPIny8MMVBp6cTCkekY8u6lHlP94uYf0DFm9qg5M2M6EejlwdvXIqrtvcNSh9A+NqvrSVhzJutq89gOILeZK3qnSkCVUw813+QAaJ0bUFhNBYCYrgrQOLcAsu4CoHstA5SvXYCFm0UNP/RuIED7/S+g5BeHYDJ69C2ePsLKHQOJW2UWJ7Q+AAAAAElFTkSuQmCC",
    },
    "T9": {
        "description": "bow",
        "pronunciation": "pd",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAHCAAAAABBpmDhAAAAYklEQVR4nIXOsQ3CQAADwCMLRGG2DJDiN4FhaH4FGCJlOqi+QpnANEg0eXGtLcsSqOmokAzAWcc3GFYzOB0SzFY1D8a2H4/tbeSe6pLUsqUd197Zyi25mp699z+vifK31xYfnLB8USjX2b8AAAAASUVORK5CYII=",
    },
    "R4": {
        "description": "loaf on mat",
        "pronunciation": "Htp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAPCAAAAACpADKxAAAAuElEQVR4nIWRMQrCQBBF/yQSgpLS3kYbF9JYeQwhjXcwvUeInVYW9iEX0AMEPIEXsEglsTAGYkYYKwm7xeZ383nzGBjASMzCsdGRMfu3+rocqcbc1ZKLQsi5lSE5AjixFYpeAIAqskHvfTCbhv6hskGFiAgzF1rr6NAZKzVfrHGxHlXuPCB56iVtaNjZpNxOgC/uybhDuCH5WM0AQJC0j0kfDoJeEwaostp4oNt6rde6/zsRkPSL8AOyqTen4Pse2gAAAABJRU5ErkJggg==",
    },
    "W4": {
        "description": "festival chamber, (the tail is also vertical 'great': ꜥꜣ)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAABxUlEQVR4nH2SP2gTURzHP5ecmtMmkRbLFR2K2Ni5SFN0q5Vg/4AUAmnRyaUOmW0Rl9hScSmdMmWxHVInN9Hg5hAMBQldkhyZtKWGkOu1Ju019ucQtHcB77d93ud933tfeArAjaH4MwCr5OPsdggg/c74DihceTSUuFX4ehJ5WDt7muNBxnftQ/lS9I6Rrbz/xUJOiq8ndEgWYsW9qam9YqyQhIGJN98kt4DdSA0AoOvc2zbN7bvoOoCipxo2ssn5TDeb0w7cFJUDBxsmhgMPUFEcXDGpOFDBh3P6NK3PteDW/ZrW71pQXaT5JeChe/wEvdIqlz3u9iuuIt1aAfE4vNnmxEMf/ZZD73TLQ5s2poe22lhd2namT11pG5Xo4jlLmOeO4lGUwx7+P0fK4w0zVr0IQPv+y+v8ePW58x775serTwiuH6cjnb1jRm12tmaMdSiSPl4PgvpCypMA49XdOMR3q+MAk2VZUgEuLEk9qcKy5HuhNy8pUJN1WfxbeqYmO/OD2tppNhzO2muBwfkd+TnjaJAT2V8ZWW1tbbWWR1b2RT6NOhuE5jINKb21RKyNkjQyc6GuioHhxBdTRKSeTwz/+3B/AEJWquX/92b+AAAAAElFTkSuQmCC",
    },
    "V37": {
        "pronunciation": "idr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAYCAAAAAAuK9knAAAAy0lEQVR4nH3RMU5CQRCA4f+9IOd4iR6AxMJJ0EoLahv2SNyBAxhDScMZXixsKAh4EQt+i33i87Ew3ey3s5mdgUKMkyaoS/b6dn4Wm00ASU0DSqrpMukV8o8qS83kGPWT3j1rGEFVLKqO5f91b1w0oIZhwznyzCZFm1w31toUqNF1vYWXgj3DlqmlwkaPj7A8Hy0kXd5AqPMBzdUACD3EP4pdRxDa9jHaE+XK91mXzFZ7vwN+l3D/AXwdAO5ugYe298x00Z62/rl4yhU/Qm1tXr5AdVkAAAAASUVORK5CYII=",
    },
    "U34": {
        "pronunciation": "xsf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAuUlEQVR4nLXOMQsBcRzG8e/9Y5GrMyhMBotS13UvgAwXyn55D7yEewUMFpYb8CqOWVmVdDudLoVBN1E/g/MSPMO3z/gA2GIDCvqD96APwF7esgeg7ItfBsi7Jzm5ech4Eq9i8XI4152Ftbv2uIhbrBRdibQ4q2fh9Xxp7VFpDsPzFJYBsF6gCGoFjOoGRaR36RgRiuOjRfNxQHHbNurm9g5ghrPQBICJjL/AEef7lIQklUr72z8kAHwAsUQ8NAMFH9YAAAAASUVORK5CYII=",
    },
    "V36": {
        "description": "doubled container(or-added-glyphs)many spellings",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAAAxklEQVR4nM3QMSuEcQDH8c//8TCQW0hIXoDSyUsgg023sJAyKCaTsimLuhdhU2YDi0EZKHVdWZHZLe4kHc/f8Hhczzvw3T79tp/OToD551UQW1uYbcRaztjeNNeIBc8uPw7v3g8K1iu3sbVQzZnoe1s73b7qB1KZp/VvmSzn8KQshHGjE69dYq/6oNTNOUztXozsfR2Jx2AmrkzfdxcTA2BIeNl43E8UBQ/XSz2iqcSTaontZon8V36CTs7UcgXGfue/42rwA7boUFH9ynYFAAAAAElFTkSuQmCC",
    },
    "O22": {
        "description": "booth with pole",
        "pronunciation": "zH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAeCAAAAACOSIixAAABl0lEQVR4nI2Qv0sbYRyHH7NVECu2/ggo59BB6FJRM8RfoXRwqpQTChVKC4dOjuLm/6AgnAgB3bTQoRlKIZIIQshYLIVWsFRKBXGoKb4O6sfhJPfmcmI+y3vP9z53z5e3iWqetvYNT3cFz8fb5cN/+9VXTcHh9LfNjhFJcf30+6+w5Y7OwzWfzo72D0sAqSf9PS1TACu7H4JPBiTtrE5E/wRklvOSUkDytbQGMOEt5WQUxCi35GUAfMlNsnWlN2SyqqaQL4TgZ5iRPiItkpWk3Lrnvny7p3d4KniT7pyfkySfBQmJIf3xx29XcaWU5N5S2v+rFBIqkTV+uPF7SV6IvtmgIFRClfFwzE/9sChtRFkJgN9Fa/6FzxbtHQAkACr2JXXRY6OB86BlZ+TVzlTa4nNorm895jndFjdXjXYGgWe1oxhjL9QsFm98sUtx8l5j5ze+PrrXyBmmthJn5IJLG+ONnHAUmcQZK/xvwBjJHcYEDxowOiQbMHbQ3oCxPnHGVudhnRFJKlnTTeW1YXFZkupajpFxoq0bmjvKMjuuupsAAAAASUVORK5CYII=",
    },
    "A52": {
        "description": "noble squatting with flagellum",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACbElEQVR4nGWSa0jTcRSGn23/bWrWyOUFL2kmZiQjy0pNJVJK1EoypAz8UigVSkKRhBhZGIhCBBoFYVZKFyMKE8ksxZDID5qp05oXzMxMLTdyOjd/fdi0rPPt8Jz3PRcOLIuIGjEvDMflAMiWoV2VP1rNKxK1Offm+DdaTRnAlscjof8hj9HBoZ6BCiePtqsKwO6MM8DKXKuhqnssI3z8eormj+CaL7BjpDI/lKhOf+KNcUvsvMgHNPVNQMIDOUH67EXP8BxigOkTG+/u8VBJSgwjwqGSFYh2vR/AsLCNv5y5nZA5empxq+l+XUcugFGf/kpYxoWYiHSwN7Y82dlWLbAziCLjSV3ZbKnSjkqGOnYTZdxmz8rfS0QvpAHI2Zr09FMzfb2BAHjFfLbyzX5Judvlh2FGG9GeBakAycFPYOarE4A8UVPr8wjp4FpVcbm3UhWiqAGLSQLAklf1Ftg7mxb3xdbbb60AtG3VaoDCbpEB+L0QE5bh2jGRAkhl3W4AhF1ZA+CuF8U66cjPKIDTejdAor1DALqb7lMHNLZIVyOAWQYggQAQ5qa2wkyT87wVYN6y/B/qRPutfR3NbgDZXdplLCQ2wL3IeE4OKG90rrZ7ArDK1+twkJf6/p0FQLP93a8ltj42y79/8HlDp71w3tZocWjUZ/SiO+qv7knmQ445OZqec8FlMst7QTHUYrMG7NeFOh1rmLaXDZTg/mFyZm5i2DQ1NWmaNlTGN9R52nXKMb5vTpVE18ckF4HU07bJ6fWlxostMqA+sBrXOYEkWdWAQp2smvFRUCUDNjwLdgzRJ1S2BSidiIsQYt1vRlLtl4ffxJ8AAAAASUVORK5CYII=",
    },
    "T1": {
        "description": "mace with flat head",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAJCAAAAAB/WdGsAAAAv0lEQVR4nGNgYGj4P1ufiwEfYGFgMGdwldz4cRUeRYzSueUMDAwMDNveLLvxEEXK6icDAwMD408HQ8Zp7koMp4xYGBgYGBi6PzczMCSq/GJkYGD4nqSGUP//////ORxTXv3///////8Xj134jwkY/v///7+UgYFjzT8sslDAUi+dxsCXKqwZzMDAcH45N9wGZOsYGRimZn3jYmBgWPV2+fkvGA5n/KUR9oGFgeEVw4srBz693/ILzePHINSlVQwAjrhs+52YuhIAAAAASUVORK5CYII=",
    },
    "A38": {
        "description": "man holding necks of two emblematic animals with panther heads",
        "pronunciation": "qiz",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAACmklEQVR4nDWSWUiUURiGn/lnFIccxYUsjRa1UnSqaS9Rw8gMIS8KisyiKK2IugjCghaoqLQ0WiAvWmgRCSnLFsJWCMUmNZdSRM3MzNSZxiXHyvm/Lv5/ztX78MDHec/5YMoraZoGAKsd431qAQBR/VI9k8Cb8rTrvA9A2DORU5f7LQB7nEda3mFTT5pz+mIB0sR9ojmpNgYIr64k0cmVP9sKv8sSAFtPjfnytxZfYJenP3tGveLz9/rKIVSAukvWe4unlPwFLEpr5gPFlF0Rl7/wjQJAtyemfFGA2Q1tg5mdE00AGXZ7BMDsz3Iw9pNc8IPg6ppNWoNmeT4BmFYvuUZKRfbDZLsUa/KxuLIMzKgTuYqpXGRo3bJHMpykyQK3yPXTNdJW9d0QWPUpz+N0SYVznyZvdG3MFBFHsu1bjLmq1HRLJC9ttBCAFWPXwPqhI5WAzxfXuTYz+eVRRWlsigQsxcPzAH8/4L2I5Gnj1qu5vpAychvvsXte9DzVYqhaEUTAXZntdXN774c8eaHlSUOuOYS8bQ30ynyXmTKHlg0ZUqgEhzWO6S44/pgbk0ED6exeoqRGPf6nywWrXkO7GqKRs9em2H43qrqcb9ySvHapb7hGvY+MdLfH6y6oQfqbR0VO6VzoUPxeNengZ/26fc2Oj8zSWcFkHPbedTo3y+mcUBTqPwKAqijOhAhdZuEEbgws1P4jIsGhHFucqMs4GQXG7f7RACQuOk7kl4blWsvh2qkAKbIfwNzQEYlxt/w8ALBXSgAI/HMW4I7kKKAc/urJj7Zm2Me3AlgS1BKzxVr275C2dMYzYyIig1nJyUnpD0WkqFx+7PSWMKTn94iI2+F0jIuIyK9zywD0Z2bm9BUborTYdalyoBWA/9G/Hb+BeotAAAAAAElFTkSuQmCC",
    },
    "F39": {
        "description": "backbone and spinal cord",
        "pronunciation": "imAx",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACQ0lEQVR4nH3QT0iTcRwG8Of37vXdhjnTyeZrm7q5aUaYY6jTIok2qIONMuhQ5iUIMSiKGpEXD4HQLkGHtJvSsEvCDGoVppkUZkWJmiv/bNOVuLTYhrp/vw6tvWC8PdcPX54vDwAAxOJzd2zN9fRsLN/q84euudfPchCyh7p2b97B6cSF/Ncuye1NU7WnBADAAABbG+pUZi0w9XHf4dpgko1RouEEzjKse7WBh6WmNy908THon8xV0qTAqhtz+vsfV6tqvkZ4zyjD+sMtT0MCc7OOvFlHRD3WySg2Yhb1sFw5v5Vh1sLH2dwUI82O640vox2K6RP7RgRmVN9m8pa8mqaplcb8BVWxa96eSiDDXN1P6ZkwGqyr4HsflykmZAUTYYFzm30lp7xsXXhcpleiVRYwlvevCKNYfMaj08qi96NSc8CB0X5J62JdmlhA26K179faS03TzYc01W2G1Mn2qUCaCQzXrV9iHOIskpAgKSfRZI3n0lqaK5ymrsEsShmkCKGUgJKEteOR0/fHB2g3g21RTVJ3ozTdbXaNU0ZOAACUxhKEqypHk67tFQBS0c7vsEnig1ECgGZzpl0YWs6x3z03cXUMAHLUhueJHmMhz/N8YWm548dna0Fx/wNn5IMt3bX3WFGmN8/WIAV0wcs36UzZ9qcyuTh0pJt2y8U4e+lK2Xf/AdHz82/VXVt9olz563hxcE2UuXefZMMb/yz2N7FF7c57ElFGL3cwTMT5WVCfEkUAA5EQ/Q+bo3SSiDOp14z8BpEI0geJ9BgEAAAAAElFTkSuQmCC",
    },
    "N26": {
        "description": "two hills",
        "pronunciation": "Dw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAPCAAAAADW0SBAAAAAuklEQVR4nIXOIXICQRBG4bdRyKkKgir0HGDtilyBqog9AyfYQyA5AgdAjcBO3JxkYuLWP8RCNkBCWnX11931w7pYOx6qq5Y1hF7dP/Je7QNtdnMy3mv0tDG37Golmu85G6l1RzYTdHurWw1kM8UBWr1lbWGwoB1QTD81WYBO0eU0SN/xYpqWl8r1bdIhLGARBq+vtJFm6o+vb3wCKz6+3i8Mc6j+MI46jod+Djhf/1Ly8qcB0PiU/7k+A2ZtY0sNzjuLAAAAAElFTkSuQmCC",
    },
    "U39": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAmElEQVR4nL3OsQqCUBiG4bfj4NRQONVS4toUgiQuXYpL1+JNOEQQwoFw7RocW72ACMS1Qb+Go7fQNz3ww8vPcUOmDDDNBTfD3hucXufd1+m6vR/ceXXTWxkA64cmsXzO4uR6gDf15v1LA+5/v/joU/hAPkoac4yfqqRU6hO1TaKkaSMThJXBVGFgYuqOriaml7WyVv1Cc/kHE7k0vnV0XykAAAAASUVORK5CYII=",
    },
    "G18": {
        "description": "two owls",
        "pronunciation": "mm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAAC80lEQVR4nGXTfUzMARgH8O/vuruflCIVCplFTTrVOCYvM7SMkbwPvTCb+aORibxt3iY2LyEreemFsfBHzLsp/shLF+m8nBtJlNQVuTt3XXe/rz8y3O++/z3bZ8/z7NkeAUDQJ28A+LC5eVsAIdhPXnPALUoAIHQVStfEsx3D8APeYnTTY3gkyPkyEkA6+SU7flLiV6bCs5OAAbsKzHYtYLjYDKF000iBHp1CLGlPSTq7WdFo7ewiO4PdgQKAy0eoBV6tu4ia/b391IeyHcmeOwWz8ABfREHT/CDCyoNArnmJB/J95ExcH6wO0FRL40KjgF6hT38uFORq2vcNCL7ymeR1IDzp6jvt26YIOVKXmBRLWJ5XbG6Lwi2ysf980w1/uZpryRnbtgDixJoTMNZNHg2s6KqZLUPCg3Zt+X0RmFYfnd42BgC28K6PTO3jhQTrcW/4VJ1TVt33BRBo6E6RoYjv+sFrulKhLOCsGCnfG8BS+0P5Wi2OM6qNpkNYxifiGmu+AIiXnAkytINMRJbj4CoyF5nSWRGIMLb2cUfR5E2lYlVlI2nwQ4audAqwg4VBbkjr+OGIB8KeU3JmAcN0rZPgf4/L3VB8bWbHUQHI4J7V3zRAyPOmeZjAphg3ZByq+zwSSGFkqGW3AlBvtRWIt3lE8R+KM4ZVO7Z4IY2RXrmfQqAchCxn4VoTZ/6HMjsnbGfdUKRxN1ZwBobc2I7F7RYbdf+OpfhCfTWlvapFNJe95pvwvgbeC+uf001eHvhXNVP6ZZGceYdJs+4j9dPrfranA+vtZI7vHzPHZspOXllLumiYG7iTNPNAUUMolDsd5Ok/6BifBCLg2a88iQuBbdIrfVm/ZI4H1A2kEb5xcbFxI4pYAmx1tUQ9bhkM7GoZ3lsFrxK7FshmfRXK2JN3e/aZaLvDYo1mfEUJACCmriEpSFFbkyq0WnsGKkXYJEHV7eqAODDlNgBg1PnYSv1UzSkhXPasKlGQut67eorYI1MBVP4GC3llLjKQ6h8AAAAASUVORK5CYII=",
    },
    "G25": {
        "description": "northern bald ibis",
        "pronunciation": "Ax",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAAB9UlEQVR4nG3RW0jTcRTA8e906rDZzFltawhmkdjDRIIFKTUtyhQKemjQQ3SlmkEh9WJJ4IXEIIjA0U1KgnSwrhSBbLCHlRemVIti0cVqpWOKtNoCx6+HQfP/287j+Rx+5/IDAHSub5HkdR1yqADQ9yQKZposz058zigAim/Hy49sdh17EFiVRUsH5sLjN0qe51uiRzO1ItBXqNJ0/g0VcTlWIOuKl8cB7KIzB9tXjcznh9SA5pGwAWP1kjreVQOcTAaqTQbDqFNi0QqwNCJSMaJUtcMFcFq34BoXGkEo2+KVoeTvxmyQihZh6Y+0ry/PlUENQCI5d2D/1lt5E17/RwWnbm5w/2z9tKHrjaoxGfQ8Dme8br732jb00Iip7tzI2/t79LLn7Ai23Dxk1UJ+zZlQvGuNXFDqOut477OXAeu6RXi3Pt0bAP2+jaPRq1MffoWHxw72xF44ffOLGbZcmuxd0mysMM7nVWn5E3HeUTboEHdryzA11BdV9noTIjqs5JVBEfO0+4QYbNvF3oHANmm+C6K/TYinzfYOv9e89kdU4sPiYu6r2QZAf8o/8WVa4u64nSvTdelzKLlpysP3ResouUQzOKNIKdla7Ib48trsvNqhnaSwSlX8P5P6b5Zt2glYa5LXFszbQ25pYPpmRTqepPP/AIYXu+elwyV1AAAAAElFTkSuQmCC",
    },
    "M10": {
        "description": "lotus bud with straight stem",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAAAAABXZoBIAAABC0lEQVR4nM3QMUvDcBDG4Teli4WOIhghaHWTujn4BXT0O7h2VLCIdPAr2KEdBImLFKzujoLSyUE6KBVKoCA2UAvGVJSfQ8R/Ukhmb7rj4T24s5AkqVHPS9boWfGyfvHloUCoXqt4N4jpUQe8rjd8/xgBQHM7Z6K2Ty1qV1uue3YK/o7JbnyyH1t1C5TNuNinaqYnYFw0cxmjNr11P7Hq8IvGQtRes6xLsGO69AquJIkbqQKVxMHVEDbndcCctAdvTkILF0C9y/nWMUBYUrJqQfQHHu9hMq1yVjxOZh2pFPC9Nq1/1YbdVFSbq1wqDmVZ6VF/mG7qk75W0j9DKwvzQcYTxp2M5MwkA5v6AbK2gqs29zAPAAAAAElFTkSuQmCC",
    },
    "O37": {
        "description": "falling wall",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACgAAAAaCAAAAADgJ0EXAAABs0lEQVR4nIWTPUhbURiG30iHWpFWRbHJUoyDiC3SoYKLQkGhEBy6SG2cSkedHLS0WxxKQLBDzOAPSLGI0tIfCqVLxUVIVUjh1nZIUNGgS4dWycHk6XCTkNxck3f67nuee97znR9J0v0z2GlSRdVIkr9Wuj3dUJmU5AeAs9ZqM3bZZa3VXAG8IslI+nn9pm5Yr79+ykotPTrYdYMDENK1lS8Ap8PB2fBywmxNecvTT/loV6EjAIwxxph40In64E6+nomRzcPR3hLMo3n2S5zmbzYaD9UV2+1LcOzIuNp/ngFM8mWRGTmAQ5cO3/wGCBcWpSw4ovNq7EsD/45Tqb8Pa3yyT2Vj3ZXtfUFOln7lqj/JNje0vi1hj8v7JP8TPzZ8bmzdMIBHqr81ZCSdP76nzDurcWWzDLU6dFL8PZA0QHrRyT0HVktDQnEDsBcJFttvIdbt6DJqjAHg8+hgwd1hzxniDcbtGwGw8Mw2n8JkeYveqS2TWA7PrgNsj41IisJgOSipOxBokR6Nf88Aa3OdR/DAFSzI92o1t8NDlUFJ7wG4uFsVVBpgWrl3fbk8Ex/2pZSk/9uTDyodBkYnAAAAAElFTkSuQmCC",
    },
    "U17": {
        "description": "pick, opening earth",
        "pronunciation": "grg",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACAAAAAXCAAAAABPbhI9AAAAh0lEQVR4nJWOwQkCMRQFJ7tgOZYg/G62Bwt5JdmIVw9eF+R5yK4Iid/sg0AOw/wBwLaCZLJy5mJdI2VkgIQ5Oz5on5EBWzvjhnBATQWIFpCZ5T3jpvaIo77KLP0KbeboCL4UvyZzUht3UMGQYkoUZUxxrKKkSmDi/nxt//XRAYopWdXIiT97AwPuYMonfcUBAAAAAElFTkSuQmCC",
    },
    "F4": {
        "description": "forepart of lion",
        "pronunciation": "HAt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAXCAAAAABCcGJ6AAABRUlEQVR4nH2Sr0/EQBCFv1MsCSQYLKL/QIMq6mxTXVvcidOkAgUpCn36JBINsglJE1QTQrFN1u65ngH1EFt+hb2O2ezuN2/2zQ7sjmzQsDATAIDJ64fyTsonqbSTSsinuaKXnOaQWBW7oGXr3HKZSUpIbROGcqthVaomltawCMtFVi6FtiaRCoilEJbIRgCYWjKAdBfEVqPZ0WUVltNgXRMT9er8wRDECklqFp1cNuYFMVpJkmzKJJa11kldMm53vA0wmfSlRRN06rkfhWKnGJSyXwld+POTOK6sen8XRZfq/yFxWjpJvZynCqu+zWEGCUenHtq/8uvb7euL13o+3l6sAdKxST6qCGN+5rrqhjkAM8HN9Z/CEYdmDz7eX6rzg4uxF066/ybS38rWDZKfFWZRfcLGwCFb3o95fBoz5mTA5szb/AR5McSewcXWlQAAAABJRU5ErkJggg==",
    },
    "S40": {
        "description": "wꜣssceptre(uꜣs)",
        "pronunciation": "wAs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAeCAAAAAA06wDRAAAAnklEQVR4nL3GPwsBcRzA4c/9+rnkoqwGiyzKajORrLK7zduQ5Ubq3oDdbFaMBrqN/CvGU4dON1zua7j34JkegGznJD7A8PjyXGASrNrVHMYgkR5AfSvJ1ATG4WLpN4DgWWlFLiAjipsDKH9NcDVBzfZgCFAwYH4B/Sal+E9E0mjLtABoPmIbIO859q0GlKRflq6CONKZ70dBuNP6fP8BJCA0/atCTbIAAAAASUVORK5CYII=",
    },
    "S22": {
        "description": "shoulder-knot",
        "pronunciation": "sT",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAZCAAAAAB4egMKAAAA/UlEQVR4nH2SvZECMQxGn3euDlrYTSiKGkR41EAbBGSkZob8OhEFvAv255jD5hsH3tWz9UkyhJoGTYWpBmAA0eZiCQKitrkwUJEBeJbiqZ30ZCnP5ch8or5DdQkFwMUlc0MIXlYLEqrmulYFc50FANm2r/r7PQAE93cGgHJn68DkbPX9NkWn9Suxtkuokm5lZ+SL/5dCMnJpVUjmo5ESwEfm3DdFNgP/NIkojJJJtilIMnFk6XQPWyY0gNB5bQABwlCOwP7Wo2574FgAK73HCyHVeVg//ZQs4QE4fMYOwPDJ/paZL3YEXHvE9TtgB0xWz/2bztZ5RKFjHxs14BedOfLVHHiWjgAAAABJRU5ErkJggg==",
    },
    "Aa8": {
        "description": "irrigation tunnels",
        "pronunciation": "qn",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAICAAAAACw8NI0AAAAIElEQVR4nGP8z8DIgAqwiTAxEAWIVMb4n5qmsTAMgBcA7KIGD5eSlaYAAAAASUVORK5CYII=",
    },
    "E9": {
        "description": "newborn hartebeest",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAcCAAAAAAot5K5AAABKklEQVR4nK2RMU4kQQxF36zIh0vUBZC4CVKHK/URuEAN3KEkEnJQzRk2JoFo79BZyx0SPYLqYWYQtDrAiWXrlb+/C8DasSI0kgJ50J+xUA3uw7yMlaSh1HFRFJL2lFigshXooSwoQtg55yVMKYAuSTbNGiQdOoCu2uLknBtiu6HeTJfQP87NfUs3+/3zgUsOFNu9ktbuc0Qa1TKX/+yTqf0Cmo7blFC1HAzUARhN4HBmLTRmTnMbEeY4O1xz/qA9kCJ64D5nW+NkWgHoj//cqzrks0sl7TpHxsMqoY1IOYxx9s2rnToyl9UM5JwHPyOMY9GGnDY0vtSqXgDXT1cA7O7Iu+mW7XT7yLTd/5+X3PFtnBuGv7r5nvzyjj9rsGkdxq9ib+uw93XYCx9C/wJTDb1V1QAAAABJRU5ErkJggg==",
    },
    "T21": {
        "description": "harpoon",
        "pronunciation": "wa",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAPCAAAAACt9eKMAAAAb0lEQVR4nLWRsQ2AMAwEP8gNJVuwjDMmO7AJiBkQHaLiKSIkBzmEBjeW9fdvWQ7wS4FlKmiGIqlmbnxqQKhGASNB9jUqkpz1CxWrG/+nzN1MbT9FJFc8zFEA4c1sD8/aAcDRJo/NKEeb7zGvEveGXVQ0TkR4vqihAAAAAElFTkSuQmCC",
    },
    "Aa19": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAaCAAAAAB535iiAAABAklEQVR4nG3OvyvEcRzH8af3fa9TfNUpvyapMyiJxaZY/Ass1xlkNuhKDP4FmQw3yHB0KQMpTDIYbAyWKwrlO4jhcqF7GU7X53vfz3t69ejVuxcA0Dn3LEk6msriXKZwKulWqp8UBx2/lqLV9fTK1of0OtHieanS34xXUjTwzyPSYquz/KW34Wbc1YHz81haAGBS6nVH3OscDJaovrtepgdgVtpwmWlpE3J70lrM2dZTaH3d0BH3R8IwKI3SfgHZYjCWYICceZkZ+/T6gxUufH5olxUPl3astn+T9OjHqJ8ld95hkGn3rpcyvp3pBl4Xfv8N/F4byvv7jGPQIBX3FN/8AXURV51c8lV0AAAAAElFTkSuQmCC",
    },
    "A55": {
        "description": "mummy on bed",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAaCAAAAAD+7nGkAAABKUlEQVR4nIXQL2scQRjH8W+PiBJ1VPdUy7lMXeHeQM26ihOFcdF9C3VnI0Ngo1aOKQc1rahbOBlbqCqMWGjNA6HmCxFHIAlk9meGGT48fwYAUkqwn2hmO2qUGqmFlnstXej5c2DXw2pSNxTd9TWmkt8/VZNCNTShGhERau0f0mxMohRDx7w+brMdQo067FJKpDy5HaQGbId+/bDPKg9l8j57Bjn36TD3SblXzTAIh7H1D8CRffFijlVPeMvn1/8fP785e3w/5YQ/8HG27QuWf+H2a4N8Oh6j5lalC3UBv+GmxS7h2wK+w7sW+3XL1QJu4EOLcc2/BQAvm+wHr4Ci0WRYWOZpnklVx3VTdYpa2rXST+VgdE21UmU/NxhVBzazbK0dSw8zjE7uANWOsW4e0UxlAAAAAElFTkSuQmCC",
    },
    "G32": {
        "description": "heron on perch",
        "pronunciation": "baHi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAACNElEQVR4nHXQW0iTYRwG8OfbQfdtidDwPM3ScLRJVJZKZKCFBeaFkXRTQlmpiBUVSASdLqTIPBBEhxutboaRtlVYEUmK5jAwJ9qmiJbQhTH9dJuytaeLvPi+oc/NC++P9/8+/AEAgPaUj5w5hLWiLmwZJ2dCzuvpkZTdbnPMkfx5eJIcas5UoPEFSU74GbjtIEn3jZNpVsMqClsqEgLit7aeXIDurhNJAOZdVwYUE6qCXi85Vn+nm1ys2xDx+Re+zyvpJT0DHe5Ab98rtRxTR+gvg6fvWIljabajuOy4INeMSfK5zWMCUh6PsmmTcnDyy8ZnyyGpTgUgs3H6+7XtclUlIXaA9L6+JADIGaXnYESx0nkyuPzrUY4BYm14+rxOyVV+Dp3tZMh+JhWVTjbrlVzj81VE1QxJdNYakz7xvkHJ1SvzexBvfTotTTy4bA/c1QkAoDHtE8NQLXw4fXPmokHUCpbkAr3kz2oQgKgjRYVZABDqmdtrAhbeFfs/GzfHJmIW2GYLcjUSSXKuPP/cFIN/yE4Nsk3Du7DoirEsxryZ2hpvjTbutPV3ZVxIULluAYLm4eC9RFQPJ179+rZ0o9raXS5vGm2OBlBv10M8YG+KkpMGWBkHAGpUCHwctIQj9H9CfwlA6lcsQLV6igWiFuvGzKX89fUJ2brGdXdbPADxt6PVZwaQ3rVDrhwx6/QF7WyIG+uvtGp3S/sVndNaAurcOBxN0ZvzfozG6kOKtxFZLpLhPzhLBZaU1aEpAAAAAElFTkSuQmCC",
    },
    "Q2": {
        "description": "carryingchair",
        "pronunciation": "wz",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAYCAAAAAC30wCSAAAA3ElEQVR4nI3RMW4CMRSE4TEgbaBLQpUT5AQWJ0A+QjruQJ2CSEg+ACVNJHqU3ICWggMABU2EUtIlFT8FaFnkfey+0vrkeR5LxmS9LcDw2QKSFL5gsWIT7hgP+5H0zdpWbxBfJWnOzEQQu5KkHhjkaUx8yLmBPlm3VYFG/HVUgSK/XndRu7+BgklRK0QgvrRMFOISOJ7rKUf+5x+m7755I2ZQQB4YpBsCeeMuwMdjagS67heZlJDrQk7KxK7U3D7N6v5y7qz/K06jhpFcdZxr1IijVtwZHS6x6SWSpBOH6m6U2l6BLgAAAABJRU5ErkJggg==",
    },
    "I2": {
        "description": "turtle",
        "pronunciation": "Styw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAXCAAAAABCcGJ6AAABT0lEQVR4nHWSMUhCURiFj4UVBhUkRDQUNNVmU1AQDRE0CoFLqAQ1tDUFLUFD0XJraoi2CBqKoJYcg8gGBamGBJPAUArUlqgGvwZFn+89z/Sf/3733P9ermSRf6ls+i3ewLKcCj6RWrf45xJXPid2CDDX8AQuSI85sDKQ67WcuZGGlAP7gvftPZqUmnZNo9BAMgALLlgZY210mhhEq7XPmOoaNEPVAV9YldS1CJAflcjFnZRkYM0jE+O8Yx/SyVeXrBo3ousK8/J/AARdKclwrMBZ/WIzLTBRklc94XAUXOevaYtaMbAC0Arb/KuXvlDLOFOxBky2iDMUxq2++O36boniUFMjwu+F106F39ixtT7h0UzUrWfKHCV4mLXvLANw3/SR7iRJbTby9jLel5WkTC4rSRo8CdjTfuB02OILALt2qvsgTzLU8L4bKETaJekfd37eREGJ3H0AAAAASUVORK5CYII=",
    },
    "Z2": {
        "description": "plural stroke (horizontal)",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAALCAAAAAA2ZKCaAAAAGUlEQVR4nGP8z8DIgAqwiTAxEAVGldFUGQDgzAMVuD/0EAAAAABJRU5ErkJggg==",
    },
    "M1": {
        "description": "tree",
        "pronunciation": "iAm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAABF0lEQVR4nC2QvUsCcRyHn/t6p1YOUcJVNAURRiE0RENF0AvVWIsNThUGQkRLrbW3C279A+05RnrkJEE4lJdBGE5GR96LacPPz/RMD3wegKEr91pHbbXRa6YFBNhqpu2bQQBG6scsNo4AOKlOwe0DCJHtxxoUIiDoyW/gWZ9ASBpF4G36ACEefQd+yiZiLNmvAHdrphgLdgsAc1iiIQcAazIhy8kcAB1BBvxfAHxvVzZfvgD4tFbksN0GIGjNCGEBQMKaUHEBaFcQpxQoj+VIbEMDQFuP0avG1aNqT7KhnAZoeT0LKf8SuPBSAGe1OebtU2V+ypApqybdwt74/n1X9fmYHUvUUVz8G+2W+tzxz91OnwNvxw+AfxhGWP6WjCPQAAAAAElFTkSuQmCC",
    },
    "V17": {
        "description": "lifesaver",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAeCAAAAAAwHtDsAAABGklEQVR4nAXBsUsCYRyA4de7r0uDw4RIHaVQsRYv28q5bO7+gdrbXHOSApfGKLjaBGsI3AoimhLDxSIsJRNDiwyyJcH79TxAuiRSSgMsPPZOT3oPi0BOtmBbcmB/3JtgVvs2rjgKlCNjVX+a8oDHdxbT2jcGgHH9qk36QgpUyGfQveubYL5Xujh/koSkjBwC+d8sZIf5ACx1ypFI+S2F4qWVeSJz+wxQcEXcAiiojw7YqQNgDXu9oQUKcIP8AApEjrAFFES9G+KN1tDQLcPvn7B0IFgb7+bcWhBY/fyemx/0V9BIzBRbzeJsAk1LcihyTFwjXP3yw/SgEsZ293TQ98ebnMsawLpcII0YQLwhGpctgOYVdFIAsNz+BzYGbs9bQtGfAAAAAElFTkSuQmCC",
    },
    "N33": {
        "description": "grain",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAAj0lEQVR4nI2QsQ3CQBAEx98JekQLVwUF4AI4UpfyRC7AErVQAKkd2jnSp0uADW/hgIlOo9Xp9gCIniUpewSoALvtuAAtw/EBgEnJACxJ70GTMWOTDGKvjwFTH3ElCpKcXIbAlJGzwhX44T+1sT401KWqabZOxTR+C41LSV3L2hVg3Z5zgJbhdJ/zB38WL3wBENNFJr8u2HkAAAAASUVORK5CYII=",
    },
    "W3": {
        "description": "alabasterbasin",
        "pronunciation": "Hb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAOCAAAAABmqTEpAAAA30lEQVR4nI2QIZLCQBBFH8i5QNwKKhIXsWZdbBwiR4jLNeIwKC6AiuYCs4aikOMomKLWrKAKhf2IqTCTKNpM1+/Xv6d7Jj6J+UcUuIndTt5rN9bkWKscUxbsmCu1ppCyqPTaA+zVRy2TCugSKVfwLqU8ae0Ac4lcp01INuoidTHMeS6uq+j3N3qAfnVdPIdRx+GzNiR2WOyYjC+dXAVAO6zQAlA5ufQQXtqa0N1CG9zNVvLpZTC1lbfVkvrhmsY9apaV9bK1YRLNXZO4N+/iLAHz4vsr+wHg9/92OJ1j6QUU4nva2vDKcAAAAABJRU5ErkJggg==",
    },
    "I10": {
        "description": "cobra",
        "pronunciation": "D",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAABT0lEQVR4nHXPOyxDcRQG8O+2t0NpSx+oR6RSFilpRMRECE2IQcTYSMpEDGoREaPZY7ERi0GkEaIRsWvSSL0Gz0u0tDq0Womrj3v/BoPB/5z1l/N95wB+pcjmwZ0JKTQdf2zlmsSuFkbS21xrXIq9dG8mBA4JgOCe/LJ5OSYCLAdxB0B5bU2bopPuH7J/Bo8K23hHvdVilpMGe+o9haf1699MbOiDs7rSaOBQJxY1Qi43tFiVH9uXIQCYWl2JMAZjj7Mlo49HwnfJzt7+E19aAGAerRMBsIIqZSsGGhzW2Nqea/l07t/tJoOjq7lP8ZXtzvBeFkRP5tV4FNBwjBWPvabBsJNnAA5uh2WFMDxrVZUyppRoKQMg06aJkKYonyJBajW7oNa2GGun+84SlEXx8U1ZHC4rlejMMy+5d44mygo3cJMWYhaqD/bgG2movPwBFk52x1re8+YAAAAASUVORK5CYII=",
    },
    "I13": {
        "description": "erect cobra on basket",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABcUlEQVR4nEWOzS9cYRjFf+91JWNCItJYDCY2IiSqXRCrSRiJhYXubBALIyGkiV1j1zYsmrJFWEpYiNAmQtIW8RV/gG8LX+3oNS2D8TE372PhvubZnV/OOc+BwJebhBPTnxTe9YrTVt0wKR+epeJ1U91u0ldQoRu+exareE2ivy5lPsOECs+vyiiZi4UMiEifBW8vwwAW0PhvRkPI+W1Azs0tEEjEPWAFt46BMuevB5TvMA55pbNJE0m7BiJ61DxJj7ZCebTTWwWu1tjdjxPGQMlFC9XynhdHvd+lf+dbCqTrO/IurlKgMLZRk7see6lgZY/J+0pSDhf8e5sG2CC+TP0npEjenToA/HioGBQREXepPRsbtN09sACozK5ha8iG1drmcALAeiU9t3bY/wYCprKoTgljB0aKai5l/PpjatLnfSG4eFhl9LttEYg8Luc/6+BPfeYq0jr6tqd2kkpntdd+nR4BqNqS/+dHJ3EZ8LH8BC7ujavY+F6NAAAAAElFTkSuQmCC",
    },
    "D49": {
        "description": "fist",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAQCAAAAADCeFtKAAAA3ElEQVR4nG3OP0tCURjH8a+niyIUYouLoSBETU5hL8HBWVzcpKWxWu9YvYGod3HXS2hDSLja4uYmRIuicONeyp+Dfzrq/U7PeT7Dc5DVd/XUwco2+d7xjnXc1dyXvm4s60wkjWfRX+0SKj3p/t/OXF+SFGhWB16l5sZM2ZX0Xl6/n6Uwv9GC9GgdKY2k6NpkchngxB+y1cPy07cA7mTbSLZ/x1NNAVoh+51LBkjE2QAM8HN0FYNLc7iINQDzGaT3lkVFDjB/egnabykBkCB5eEAJ6AKQvfuYazevsQBixoJVS/H+mAAAAABJRU5ErkJggg==",
    },
    "O24": {
        "description": "pyramid",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABKElEQVR4nFXRy2rCUBCA4T9HKShKFtZFRMSNolUKaiNFBH2FPpDP4WO4FtyFgrdiyKJ4Q9wUEUSULIoBky5yMZ3NzPmYORcOACDrukw4GqbZcCvhpu712nWrqJuqP1TDEGt/0Y79PkYaiqYpjdAeRWu9tooPkFR7u7VVKThU0Ycw1JWgI5OawjSVCSCvGGAoeX8i0j+nIX3uR7yOZGlugjkvJX2oLC2wlhUfWumRDfYo3fKgud8AbPZND2qHE8DpUHMhr87OAOeZmgcBb4zvAPcxbyCgfNu599ndyiCId44rF1bHThxBrqBdXLhohRyCrGz4bzDkLEKqJyY+TBJ1CTFYPH5jMRDS56v9bXtr8SIMybmenoIO61nG6RGKnhPlQwnBO5LD//gDwJVbTutKKqwAAAAASUVORK5CYII=",
    },
    "W7": {
        "description": "granite bowl",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAWCAAAAAAQ1GhqAAAAkElEQVR4nH2RwQHDIAwDD/rpLlnBazCYu0YG6zMD5KE8gASctHpZSDI2ALgiHEiAuCFBHvl3DwaT3C7mUmdD2Y2xmpwZCqyTskJ5jIBrN5DmW5pZygBbUDZo+7yD0vjisZ1JvvyZ+vemeZi/YdxvCvXmmRian2QInfPU/1mhGMDLzkgCbr+arswTqvKZzio7AA/xXRWadRKNAAAAAElFTkSuQmCC",
    },
    "O3": {
        "description": "combination of house, oar, tall loaf and beer jug",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAAB4UlEQVR4nL2RPWhTYRSGn/v16096jZZAe0uaILUOKjSDXURbwVjBDh0KUhTt5lAQpYRQXLIoKk4FUUQEUSsuhiJu1cEmKBWd0ppBIW2pMUICScQmam7v/RxuLF6Mq2c5532fwzkHDkypf0QECcxu8Hdsm7CRwPmvDeCOCRCAd8vR9a3SC0hX+zOO/indsMs92g2VG4oGt/wPWGkEKjjXnikCJD/V7eBhAB8gkdwA4PTjOhx65GSJRlfAqVfKsEQIOnY5RjbvXpRKuaQE/N9LjtBb0CtwKOTIOeDC28SIo4bL5WHgbv3bg3DC2rC+OL0xpWJAZ1/fdRXu3d3G9pef95/8dgvASJpm0gC0wSX10A+MFo5DNL8TCFdnZqphaL+YUT/t1yMa8YQP+rPTQFSFQioKU5Xs1clZc30P5k0B8v0b8C6mDSO9qHvmarEmfPNqUkhlw6YS0D6QKBQSAx6taf6KRXE64/39FQXCXLbtZVPWivuCwN7OVYENgAatqwuwsNK2+ar3FHjOlt8JswVAM0ETFlhS48WHcUH3kac5ER86qHeMdz+BSs8YjAWrrN8x+hnN3TM5pjL34/mSH5ovr0Uia5eaoad2+8DH563gvZZTKn0OIJCyrFQAkKUfOfUAfgFnqcArPj7PJAAAAABJRU5ErkJggg==",
    },
    "D28": {
        "description": "two arms upraised",
        "pronunciation": "kA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAAAAADFHGIkAAAAsElEQVR4nK3QMWrDMBxG8Yc7+ziFXMAEQrYMovfwSeohvYQhN4gO0UK3NmQImA71Ejq0vAwRJPy19hvfD4Qk2rym2jq3JOsOJrL0MfeYUc4RzvjbwDhHmEcemPQU4ahfzRv8RPiD1+YFDhE+YQuaIiQFtI3QFogdlKau1/0z1LcqsIiwKrCM8AiAfkR4Lw+Mf7JRgb363N1yN6gZSHpH3aDljLS3Wk4AT6PTff12l+ACtjt2QTWqAxkAAAAASUVORK5CYII=",
    },
    "M27": {
        "description": "combination of flowering sedge and forearm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAACA0lEQVR4nHWSTUjTcRjHP7+/m2O5LcWXXrACbekkUS9FBxlEKUREEV2k6BCFRIcSKtDsGiRBXjxEFN6ChURuGF1Cg8SZFOZBItL5sjdz2z+b+2vbfh0295Lue3p4Pjzf3/P78gAgrLXUPpZy7sEetkt59KNtUHvnWvt+ZwdK7avF0MBu021taida+VG+LgezO/KfKYC+u2XoRCusBXJAvb25WAcQn737vMsIiI2s3ZAt0JsqRbrl9GRopwz5ggoAMu8hAE5HzvdX6vLXMGUqy9OxREChgKSXYkWHqDjWGIuPzgAkszQJoGN/X53BcCDufBIBs2LdGhX2wagU7VWqe7PKcXS79wv1mpg8Ypn+qzWZVL8sYiNpTH1BAEbFLWqE2SiElOF1BP3NdgB9kQYgomkX10wqDRWAZ6F0Wwfsuj5XXZKzKYbStrrh+a0IviQ2gpdsgDMMHDozLqP+xsx2ZfUTicCS52H58KrlxsyiT1Mb9gmy+uBt6Xy/srAc+xqbuH/8jZaDSno7pn8CJx2bcrQDeJm40HM4Q8cTmytXmwX6sT8VYL04KdcXbNnh6k9xn/9X3963q6VdHv9yTD1Ylpva1O+GK47ZJW/sW9B1q2lEkqfLNwHrZyl97cDZe9tTh3Nh2bNTPyUxEsm/lbzbkFoyXnC0ZmBeGzhViLZKKWV3bucfmLDAUQJhB6sAAAAASUVORK5CYII=",
    },
    "K3": {
        "description": "mullet",
        "pronunciation": "ad",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAPCAAAAACt9eKMAAABUElEQVR4nHWRTyjDcRyGn9nWLJk/0xASacVBIhIXiUwOTmpCSjngIKW0FAc5cHCQg5QDMnZgWjgsIsnB1uQ4B3GQtR1Eyt/t47Bfsy3e2/ft6X369KVqXEREvqeqytX8G5WzoBaA0M3Lmuf2X0zgYaRp1DppyoNlUt2PfV+QfT2byG2GRBpLpQGmXecSiy1pLsPyJhedviX4uJ+zmWdORETkOFkKza60wNg2vRvwPhH2FlUUd6V7tgwq7e5DIIFdF9nrVmxPWtDvXEYfLXFrUD44BnD4nW8IDvoBGO6rBwb2MwVUeqNC+0VEPoa0cYoa++9BC0pn9CtFT505BtqU7qo/KgVyvYUQzNAB869qgZTwSsDdCuCwxt9hOXKCffdGkrP657+03QUSsfccYtL4ZJ1WwieaiOM5UtIBwXbfn4Nmx4Gj2pRn0oCubPEs4jX8ADhSvqawsv6nAAAAAElFTkSuQmCC",
    },
    "R8": {
        "description": "cloth on pole",
        "pronunciation": "nTr",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAAe0lEQVR4nGM0lpX5Y6fBwvZHlIfxP8Nn5v93nj5m1Ddh+L/Xwc5RiYuBIf8/C8PHCx8YGBgYGNgZWBgCPZcs5fl08xUTA0PDuv//////u3/q8f+MDDzWTHJGPlIMMMAqIiXV+p+FgYGBgeH3GwaGDwxMcDkmJDbDiGADAPayI4gvbZY1AAAAAElFTkSuQmCC",
    },
    "V24": {
        "pronunciation": "wD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAeCAAAAADBFYthAAAAf0lEQVR4nHXOsQ2CUBRG4XP/yjw3oKMjYQFmsGIArK1MWMjKwugKugb2EhtaMDcB88DeaHPa70D1qhDA7wpEtsogbZYmpYyHWNppvT06vmc3aLzzQPPMOCkkJEFtTt5Sd5uupuiffUG4LOcgv043F/52hGFflkwIM0PEOf69+gCzESmcwMZpBAAAAABJRU5ErkJggg==",
    },
    "T3": {
        "description": "mace with round head",
        "pronunciation": "HD",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAAZklEQVR4nMXFuwmAMBRA0ZuHn14iOEAKXcSFLJzAUbJCyjQ2loITZAAtAxokjuFpDrBtIJiuM6Bdzk6zxHGMC6ctS3tK41PyjSAgENahXwNTzG+caOfrmluo96Oi4H7Ug4ACBPihD6ExIA22GEJCAAAAAElFTkSuQmCC",
    },
    "E31": {
        "description": "goat with collar",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACWElEQVR4nHXRXUiTYRQH8P/7bM53ydRFas5Wzo+yMJDIL1YklVYSQpAk3rQLTbILvRCy1CSIkWEYDcmyQigYycqtQpbdSJK0EjO/ElGJ5tbMAj+n073v6Waaxtu5e/hx/s95ngMESplkXyjRfa+AZO1s8TwtKqaX0qr5ZMk50Th5XyGp23rM2S2LbVmcpMoa3dVd1r0h0smoo+VVR+p/ECmzHhIE4qU1zNGUY5oWvwRJ84VhJVA6fVRaE0cMN+shs/VLTcYSHi93xPogvNrnqY35ByN3c46wPGXsct/UjbOjGZxxYn4CTAQT2eIUwi3H5GmP2NuVLQ+aT1+2pZ88lY0BkolggtztGNRkgnuv9dqaTelOPpMvrFdn8PJAcGmcyhvzDLpO566H4210nmuwb7xXvf0ivdNCabmNlM+GFXP4zPPNg50ZTgRbujOw43VKQdXxStXqZqbJOQBAA3XtRw2JQ2XajU+uNgIcAHvEuTFEdsdx+OiUf+uUs4QDrt4nEX1N1wEAmkgAGCD/KhGJs789syTODVdQFcAAuH8CUAbRPCdYo+46TUlRVzlS1EG1YUll3v5yn39RAQCyYqqVfyBX2l+2UG54O80HA0D02NAe6GnuCFhAQ7f62md6Agc+3jqK8R9j7nUu0JdwsI0oAIBdg5fg7fWvf0TIC58WQKsYDCBf+HoQUL0xcmvdeVn3fgG8ggAE17ChHoAlr1CA82+pO5aAXL0fQJFO6AZwRbMWnTxJrjRA3UqVDIecVBcKlNNCYYAvUV9qEBDdQfGAYfAwD8Bsi+OBP+B66XPzvTyGAAAAAElFTkSuQmCC",
    },
    "R25": {
        "description": "two bows tied vertically",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAeCAAAAADmuwqJAAABz0lEQVR4nG2QT0iTcRjHP++799WtNk2TMrMVUSM1lpFGfy7VwboUCIJQUATRoYjAyyoQRDopBFmHCLr091DLYBHEDiEYeNhFzEswL2KTEk3fbW173+3p8PstC3pODx8+8H2+Dw3vxRvxsz67R4tlts+IZGKBKrP6k7Li4T83JeKeqtIzjoikgdaXnkzYCm56Jz+f3mkH4KEUtbrjm3sesICeMEZfCYAWv0NXCoAV+Wc+KNebGgKoSHSwzqTyS1Ff5iMABw7X5+ZvPrcUxYK6vZuvdi98iqWwdZqRbTt2+pCTiKUBRNPC8Xgb2Xx42AYIlnVa2M1XzEi7mIaWTWBjYkN9Q7A22HLRYW3aM3SaeBDovNBxZPFV8s0Pn6YV6LvcnZ+8NpMCn04r7R/fuSd3723GUZKaeRERN18oFday2YLElVuTfm1jBe2c19rL9yadZk/fBuBsT/Nq/MW4qdN8QGQ4smV27OtssaxdsRtrr1xffjaW+7txsevzPr6MLhw1TKBG1A1L//360AMG0krYdrdpclCtUZEOffquJckcBBNCA7jVTsYyzZcCQOiRyONQtectkdWTcCNZlsTWP+2jcyITnZRE7jeu/4QTTxZl5DeCOs33NFxaWwAAAABJRU5ErkJggg==",
    },
    "D33": {
        "description": "arms rowing",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAAB8klEQVR4nHXPT0gUcRQH8O+MO7uLGy2RJKa7HWJ0SSOytCy9WJhG9OfSsTREQoryknXpkBBsWKR1yAgFJTCKii6GtIc2xCRdlQRDDVZMkSGw1h1Wc2a+HVZ33Vnnnd77fb7wfk/ARolOm102gJXLjQ6AXTeiAGBL+KEOeVoUDUHNRxSSY1+2yXN9d9cuOTW4519PoahxR9ZPpNTJleZN05W5ylSG+41akpyKl+6YHC6GMhODPN1mdumt3n4wEX4+uMcckPv4bf96b3+o15gdpREGi9f7M/M309x5mxy7LgEAfBOBXAA4tjlwgaQaP9PVpVYAwI+yJFeEyZlRZbhVBPCA73YD4O9AYVzz+hXylef+Gle/nwPkwbAMwPeIsx8Lqr+OhRT+OrF3G/wadaoLoZZPehkAbG8n1RhJrc0FAK0a693lT/RVnccBANm9OklG8gUAgF9jHSBITcvdWfHFOT2Lf8l+JwDA9lhTdqVdXjUQ4zU7AFTN8YWU5shsCf1pPuzNk1+SF9MZgK1+SR0KTJELpVs6cP7WDEk+zbBwoI4kBw5Y+mmS5OcjyRchxY/6/+nGKXH8Q2d4S3d5NMOoPluDL33vJ62WCN6r44yNNHksv5FRGCQjk707LRPeewppBGsFq4CjQSUZbbDe4XsWIZf/A0Wn1aZVs4MBAAAAAElFTkSuQmCC",
    },
    "U19": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACIAAAAZCAAAAABxkaNwAAAAwElEQVR4nIXSPQrCMBTA8aegq0dwcZKgi0fwHFLwBKJuglsnL+EFxFk6Cx11UXB+2ElBLEUE/w5FOkhe3pJAfryPJMIv7uKJGtXWZyiNgk/UfQf/ZC3iAoXcjWOASEHuS5Npuc4hCTTlgChkCvKQiYDEO1Zl2Mem6l4BHliqNS2f9KKWcmNVBQodGfVcjAKcl01bARwiq3XpLJ7AxDTSU2DWMM3gDQztPP0PrGwiW9gFiJx4hf7uRqy7ERGRdpp9AeuxcvxSXLBFAAAAAElFTkSuQmCC",
    },
    "V4": {
        "description": "lasso",
        "pronunciation": "wA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABoAAAAeCAAAAAAXsFEEAAABuklEQVR4nHXRTUhUURTA8f97vrHQcUyiRgtmYShFlGGmUSY066SMgTaCtZCIqLCgRW1ciKVBCxHc1EKqRYIEQu1cmJA1NKNQhKIYlebnQA7DNON8nBbvOfc64Vmdc3/381xQcTQkIhK7VUpemJeHRRbnfsqP/oY8upuSVx3+U00PF2W+Zpvcjv956gag9pl81OXgUqK90MndY3JFox75VJgrrqeDqmBQbmgTF9bOgekU3vgLjX6XVimSREyjKZdXkUoAwutW3kguplM70ufivYqyhk4uTxbMkf5yoNKX/G+pVXHsUuzOyrUjs5Unfdnk+BfnwoAVeGx435oYFcFMpODAett7gEzUOajt+YaIyEtoT98DoEz6trZt/SaZtejgo4GIX5EFQMhD8ubu5tpExzjqMIBdAyLZ1xSVuJ0nlMkb++/YF470fl1tVPfek5rw2VlA7hPYuKCoeHKp3u5G669R3nFeUTK8v9wm/1QIY/lwUY7S02aNYQK4NoFMgaWWBTlRAsDfhdM8SPdo/Ts0H7kKwAfpavwePaO3tluGADgejm8ud3o0onomaidVLRfrtn0YPBF2irMr/wBlLJooObiK9wAAAABJRU5ErkJggg==",
    },
    "D11": {
        "description": "left part of the eye of horus",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAA4UlEQVR4nE3QPS+DARDA8f8jqmkIEVapShiaStpNDNrYRMRIYrcZiJDYLHwEg9YHkBiwYGoYfAQGg0kQ8bJIJa2/4Xnx3Ha/u9zlLiAVfYXOVHGzOyWzo8ut4eMk7SpsNVQfE5luqi8Dlz5FUKmrXmTGdCOUhto+7YeyAmQnW+ohACWbAEcfvl4Vw/Z1zwD0Ld6R8Tcbkkux+Q3AgzoX0w8AI2vqfEhfnai2eOvnNgAz1iML7vV5BSh5Ho+dOFDv9stDuprcWKnuvNu+Vvd6/l8zuHuj6niQ+ld+oZqr9Z78AeJraD14raDpAAAAAElFTkSuQmCC",
    },
    "W12": {
        "description": "jar stand",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAAAAACRecryAAAAwklEQVR4nG3MMUrDcBzF8U/ESRA3p0j/W8gFsnRy0jNUchEP4NpdMqW1q5voCbyEW7OkIEQ8wM+hsRL1Oz2+vPcytrkPB850F9DE44/0FA2oYkrFMX2XTx76fWiG4iBPhu2Yqrg72DIaHOFTDrdw6v67EM9IkbCIcuzumZvjmtGWdqS1dYJ6tLWOChXv6v10to1CihCRFBEzsIyBNpIULUMsySwevL26Ol9R715c5m422vhLmwWZCUEWVn5R0//z0H8BcbJ0U5wGbuwAAAAASUVORK5CYII=",
    },
    "F46": {
        "description": "intestine",
        "pronunciation": "qAb",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAALCAAAAADQTWveAAAAXElEQVR4nIWQsQ2AIBQFL8alGMFxtMWJCAsYOwZwDSawNGdBDVx9ef+/B0SHBKCMFY0UTYEuIStvS+ujaBwZIesKNzjSzpYz6ZVm/8ByPewzia1/plZVgeObjPgDJtm37Eecq6kAAAAASUVORK5CYII=",
    },
    "F15": {
        "description": "horns with palm branch and sun",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABwAAAAeCAAAAAAariFDAAAB6ElEQVR4nHWSX0hTYRjGn3OmTWVOEANxuMhkuFUaq0CMsIIkE5aked3FsJvuEkS6iupGaUKkXkgycV4U/SXxIiNRWXm2osA5GoL5Ny90mxfTtuXO08XmcZOd9+p9vh/v+/A93wekl6afZKhpX+ZkwMutCCQshuzQfHSkO2GSkK20XyKXsgIAOL72NWOTmC7k+M89VZgQjkANCtfLLaqW1cv0qk1q7xhBNai/eXhVGgw7E6qOQPF7ejIni3RKHxqOatKQpkyUPDcUGYhoBEWcezWNKa5eTMny5+RQQbIvalniDK4EuVYHADjrYyxOVw0A4CG52YTcPvJjPgDrPMdstjH6rQCsq+SIFjBMMdwA5Li2z+sBfX18EBA6d2WfCQBaY+wSUB+8lXQbdefjRNS28E4HEfD/fmk3gPJsEj473Qj7jyrdiwhEYKnAP38Bwn5Yi4UV6BivKfkGiEB09IzbcWxHSH2Ca94Bx9xGy4MFQATkiebScTe993IBIK85eMouWfZmUpcv/C5XfJLe8qkJMDsZ2u010qkE2cb7xkmSc29e+8hYJ6Sdq0qMeS4+qR2OkCQZbj8ZkNsPMkalI+BpGNr4R26vfLi76L2d+ZZVj1Z++dcZ/+z5u9VRhsNl7vkTpbw++7hSOfoPk4XFC0DoX84AAAAASUVORK5CYII=",
    },
    "A47": {
        "description": "shepherd seated and wrapped in mantle, holding stick",
        "pronunciation": "iry",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAACF0lEQVR4nGXSX0iTURjH8e/77vVPJpaFTM1ImvTHinAFWSIJjgiakAbNK6mwCwm0G5OuhO7sQoLChURKGpEGSUoXaRjWpFASTIVuZmbmckvXpnNTt6eLzXdh5+qc3+fA8xyeA1tWzo1Ah2Xf1hTIffFb1l29Zf9Lndy/aLspU3uBhOvVcbAuSefVI9SEHiShVq9PxuW9iIjcU5oW87XEUs0HJRZ5PgGYx7sMUmHRempPo1atDKq3XavSABBqB1onU9LfvdEivVVFI/ltOy5tA8AAWtpYIPDjJFDsk5lxcdoAVj5ai5KvzFvNfQKc84tMNJoBmBGfq7P5z9rP0CAcckREmmO9ldXWeEREPDVGDvdJeMQbrNvsu9C93n+ifcwIvf6Z2fO1wbm8mNwSp4nWz9mo1uTGu6Npkeynpqhk4feiZGTB9OOUA8YPIjKcCXDsqzSo2CM22KmCUvAsLOLIAE7NiwXsUrlZ92jIOyQDOVCxMbsd7GJDjcpCwsDlh6UtmaQanqxEo5h4FLervqPsDBvyKZbHRJk+uHv5zrfu4rOOIUAJreqDKZcKKF8MSBPAo6k8tJi42QMvtS7/MABrQV0WVtOA7mu73kaHYdBlukcBaIueEjeCmx0Q8V9Ij38HHL90CX8pzNDz1ONO/T2wHAnrUrDfHxdD/iuXLnNzJbnxa0v1/5RpkX6TEt0mtVd+d8YlL4fXfwHNeNdELJ+AGQAAAABJRU5ErkJggg==",
    },
    "G17": {
        "description": "owl",
        "pronunciation": "m",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAeCAAAAAD4cjo6AAACGklEQVR4nG3RW0iTYRgH8P/37fAxl+ms2Q7aMKZRa4FKaXcFLhzNLgKtwA5CIhuCFQTVhexC8WIohhU0UwZ5URF6YcuUMWdII8wTndDKzOXGUmeQO+p4u5iTfd96rl7eH+/D87x/CoD6Hk2BilkHwS4+gEu6zyE6frBoJIq0mhtW5uRKbv48zLmnAchlj4f07iBz9D8W31ovtakYpjy9JTZtWNxspq2TxenWO57V59Wg0L1oTDN9oLzEKlPkaW4HGrkmX7GCNpOFAUWjr4FiG1Xv0WSNDWhzgN6NSs5D8ZvZbJcZAPLGvfkcLPPfuBuVA0BVoIXmYN1a7fArFQCYQtyugu/dR6andACyxxx72EbfDxpUjrVaALqtK5xR24iTl2H70yYFut5L2Hj502o1cH7JfQpFyz1ClhleWpxioOzFsgEXNypYdtap/FEDgG9ZeSp9PsiwTXRmRg1KJdXPvb3qvwUk8ktMwxsN1mB317PZirDR3pSaZZVTlOnySfhPSL9A2eIn03tTdogsdMbI9X39jkgz6A5CXot3rJ08nPD4CIlWmqYOQe0if02CJLZ/2y9r+BJ8MH9AONpD4XiIrJ/cpgzvIyD3owWFQlz4rQWvnhAzP/OczB6FVh5WBwqYJXwF7Mama/FucUcxbCRZ7zwk8cva+TsFEI04qA/hnZx4Q50+AMDpVtFE5MQqpUgJ6lfylH+sbles7x96+MWm66LVCQAAAABJRU5ErkJggg==",
    },
    "X2": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA0AAAAUCAAAAABzWejzAAAAh0lEQVR4nE2PsRGEMAwEFzdASBFuQLUoph4qICEgo42fcRWuQa7gCPAbNruZ1d0IAJfkdFx6o0mOSwYJVkqlFlYAQg64AhJ5LhWoZTZg7/euHYiwpywCsq4+dCkP8VElY+wmWHpaYBIfUvuElg7a9NA4GDUmAZtOAE5tANLPyEX6K5LG7vv7DXFYUSmdRRZfAAAAAElFTkSuQmCC",
    },
    "O5": {
        "description": "winding wall from upper-left corner",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABsAAAAUCAAAAABZ6RlcAAAAMklEQVR4nGP8z8DIAAP/GVAAEwNuwILKRZjB8B+vvlE5Gsr9wyP3B1WOBSO2ibHvPwMAP4YHI6En+rsAAAAASUVORK5CYII=",
    },
    "D23": {
        "description": "mouth with three strokes",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAeCAAAAABlfzOyAAAAmElEQVR4nGNkQAL2ao6RUOby/bcOMmAB9qnH/qOBY6n2aGq676CJQ3Xd6UaIzMWqFa50rj0DA4P9JuxqkFVusmf4////MX8F7IoYGBgYFPyP/f//n1jTiHQb0T6FiaMH2///CF2MCIX/GRxQYuEAsiSSsv8QbXD6JkKOCV0tEs2KWxkOMFSVsWMV/f8fO40DYJMedD4dXsoAnEqR8ZPuyPkAAAAASUVORK5CYII=",
    },
    "D50": {
        "description": "one finger",
        "pronunciation": "Dba",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAeCAAAAAAqIjBiAAAA0ElEQVR4nAXBMUsCYQDH4d/9O/AwFdIORNSgoBxqy5bjNkeXWvsE7k3i3sdwEtqqD9DQ3qIVIURSSMOpqZAcXfa+PQ9kr+wowLu0r7ar8vltB6NS5SjiRie/lYs4cu6iTPPhVEG/NYgTpdLj9k5W64ONr+q+hrV8YkL1i7np57HufX/2VtKL434/FiQcoqIAhABsIrDkPgTGO1wK/rb2BjKQKvS0jU17RiFm0zPyZ3NAu5NVBlQbLgMc5Z/jxmIhfgivn0SC3tcuZ1XApV4H/gGo3EZDdsHJcAAAAABJRU5ErkJggg==",
    },
    "D25": {
        "description": "lips",
        "pronunciation": "spty",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACMAAAAOCAAAAACAgPptAAAAiUlEQVR4nJWRwQnDQAwEx22ogzTg75WRRxpwL67BT7/u5w6CikgfbmDyiJOYYMNlQCDYBa2kjh3lcns18+POEX1d/bLW/kcv40fbStWxvA0xqeZcNUGF1Dqn6hRAWdQcCmAGhAGRAmVIdSmoeY3DhBDXVE/E/2mZ1ZK5ZXeg4YYb57/o9raTnz4BXQGsE65qH5sAAAAASUVORK5CYII=",
    },
    "E29": {
        "description": "gazelle",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAeCAAAAAD8h+oHAAAB8klEQVR4nG3SXUiTURzH8e/zbLA1N1n2SjBbZQsLpMiS0ouSMChv1oWwJIneCCQJIrrwyi6CCoq86CaCoERqoBcpzTCjF6JXX5dQQVulwpjPEirXtufZv4s9gvHsd3PO4cM5//85HChk859LCv9FNceVLr+zqGy8RiyHNer+qExsKQIcMuR1laMIlL2RLw1Xg0WkSWTyrZy1woYJEZEulwXsfSIiWr11SygpY30StcK6AdGq1k9/tkr4p4RLeZHaDYqy+IEUgd/j7RW3vt7Pq6iRHzZsqQSAEq5cNlzqq+uuA0CbsqHORpJ3Myger2N2+2BjtFXfW5nDbs8rHjAG2z8UTu48snrrpgcCgOu2lneHYqcK1XYmr4SeeM3KTftQOv72mI306+++7zDnR4fctKRnzJUvJXIxUFtmA7Zlg/SKLHR/0pDMpOg39xysb5XRRu3j0II0Z2VR5uRhYOHWMT/AwOMlZMrPANnTJhzISW+3SBtAdV6+ZWXMlKeSO7Z8Xs4BVIvsOv9L7ACUeHnfnwYdwCN6bLimpvCrast5lVDjBGygHlfSRmYqCYCzR6bXYL8joyXQYMgFhRsjKkBzkOczYACsuK4mXsrSiiyAPy6aD5wRGXHRkZPLKof1ZwBt8qkFWBWfO6G6H+XvrcXRNd/5DwSO1hZa3y3/AAAAAElFTkSuQmCC",
    },
    "G53": {
        "description": "human-headed bird with bowl with smoke",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB0AAAAeCAAAAAD1bEp9AAACOklEQVR4nG3RTUgTABQH8P8+nOHaXENJDAMNKQonS9Ih0Rd2CcqDiSFZkYWHOnQpDMKyQmVRoSut1UVXBycjP8Iki5CcHSqmFUYhtqnbtGmbttHmPv4dRhu5veP/x+Px3gMAQNpEsjsXSWtdo8P14Ss7NyXVu6SpKK+PBnkSVCyRjhHdLlvgaBKt9IZ/+xnWnKdW9L8IAUglL2WyQlfGfEKfEMAqs0uDn3BlL8JrVAzgo0/14tFCWkkJhGsZAPbXOUlOkbbSpDudZeh0dv51OsuSaRVrAaDe6S4XJOpx3pYAQN7E95xE3WZhNC2Y7ZImcjtPAAAEZ0IdwnicekgNACe9c9GBsiFejquk2VsJQDBCvQwAoHy/Whxnlc2zA0BLkF3RF2ksXxQx3dBPA4C0KUaeHAAAFLI9M8Z3uKIAMEjSXgEAopuRYzFtIu+LBNhO9zI9T3cCyLEs5kXt1NVZ0j/Qulv2c7iXD8cXLilTobLXpgAArKGg5Z3ZxtHM5wb1/A1ls/+1rkh4YbJ5PQBUTS5oMuQtLBc8c1a38Za0l5x5XD1N/VYA8gf+OhyZ9hbDSIeF4XuvSNIXID8fBnCR5jIPdRJxD0mSkQ4jI4YfJN1VwOb+CO2jxZCYFltNQd/YWL50kOeyOgPkPABFoz4HACbfpmF8aQ+ALPNKLrRh/vm3dEG9lo62Bmug51qpGGVuY8WWaVqjph74xljNDJeLa/zLb35xQgwASN/omovdLiVdM9Rdc3Af+hr+Av2MFDbNI4H3AAAAAElFTkSuQmCC",
    },
    "U20": {
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAJCAAAAAB/WdGsAAAAq0lEQVR4nGOYfOv///////+p1dNgZsABGG8rQuU2f1/AvgGHov8Mu1bwqIeJMjAwMDBc+3T+/P3r776jq/r/v4iBgYGBQWbNog//////////LF8NDQyTJudB2Vaq0h5C2gwMDAwMszkZGBh+fvj999/PL1++MCx/8z8FWZfD8tlT/6OCG4wKBfm39X6guUGPl4ufU16SPRkmYP7/fwcuv0MBE8OZQgZ0g9ABAORbTFpvssSfAAAAAElFTkSuQmCC",
    },
    "N40": {
        "description": "poolwith legs",
        "pronunciation": "Sm",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAYCAAAAACzJtCvAAAAzElEQVR4nMXQP0tCUQCG8edKo1+kpfXMfoQa4062RLhKk2vU2mDgKm4i6AdobbKxJaEhuERzgzn4OHRCuerxDkHv9sKP9/zJpEpqlRRHkB1EVl37F5b96Yds5VpdfKn2UmvnwKANUE+wuxNg/lBm5bypBlQTj+urLuEqzVS/AzBLsY5qB+AmxQp1BEBIsO7P/X+P38em6iWHWFCfWLPbnSp/VfNYJur79lBzMla9B+Bi+Kw6K6NHY04BXmLZYDUgnDVi+yyA1nFsH2u2AuHogQqkfIldAAAAAElFTkSuQmCC",
    },
    "K7": {
        "description": "puffer",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB8AAAAeCAAAAADxmZpAAAABj0lEQVR4nG2ST0jTYRzGn21pSUxaRXgIoToNpIPQwcKDOzaIpOggghK1g3bqD0KdBElPpbEVNAJRyNHBasjYwUAxGywIEo1GQS6IEFRY8zAo9+kw536/991zep7388D7vt/3lSSdfANL7W2HVF8HHu5A4dVcj7cu9iyzpx+3bSiF3pUThz2i3C2Nj2xZlQRfKqbj7ug/HjUaOAypWvrKSzdu6oWwI6dIuPjZJFOuhZ9MOuPjDY64+ANoccRdxowDrRKpBa9X2waf0R1HYlmmklxz8FmLi3mHp8/im4Xa/kWdsPiz5rV9fzVLyCo8ZbVq/begyyqk+ezbs4FvTFs8BNGqP/OLF+1mIQYXq/7YE4jecPMs+dZaurwCudkrjrF8YMLVv/+9AEzH4udbTwcb5P/E+j1jy+evq/8wPQTA/AWjkfzLvj4O5+C6z10IlADe54F+6RzOh5IkxQH+HH0LNyUFyZj3XgTwaaEys0FMrlMl6JQyLEoasLmajl8akrQAv/Plos0lT6Okg93rsBP5D4yWzFk7zaVBAAAAAElFTkSuQmCC",
    },
    "F43": {
        "description": "ribs",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAUCAAAAACl/DKWAAAAzklEQVR4nF2QLW7DQBCFP0eWQWAu0BvY2iMUp8cIDAqIyk18gh5jpEWt1ANYVkmUqgUxW1nqokKD14CCzY+TIfP75s28zJ64tdcc4PsvZVVyJqf1aWAd5ORpdGdNzgSZgPkA8PYMQLP5XcQBWhfOmCgnI+enu0ArOg6ASVKTGKXEPsqFXZT0McqFJRn0D5Pbj3Nm8HkkbouiKDbA++mBMaZAo52nLa1fRQ8wA/hKnZduf10qlVDLl9eSybNSqKe6SY+t/I2UFqX2Tl7rL/z/r4Byq+zrUu8AAAAASUVORK5CYII=",
    },
    "N19": {
        "description": "two sandy tracts",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAWCAAAAACJLLHfAAAARUlEQVR4nO2RqxVAIQzFcti0C3UClmDCPPckrUAgiI64H4hlwQrISlJNdAZbYirmXgJIRy0BNLVutmbT5m5X867/OX/9B0zbOhSJWqNtAAAAAElFTkSuQmCC",
    },
    "Z7": {
        "description": "coil(hieratic equivalent)",
        "pronunciation": "W",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAARCAAAAADMVhJ+AAAAfklEQVR4nFWNuxHCQBQDdxgX4BYgJCR6tVwLlPBaOLJzCSZzSg2uwpSg0KEIzMco25FmBcRk2y0Awh5ztBWA1gRoFjQnAMgFK0ALpPNAnVH/2Fon2IAcHcBwrbr0txknsNiu0HEGTuX4vL+N3xRPPwh9XgHSyv1wT83rH23KFx6PQ2YGRpjuAAAAAElFTkSuQmCC",
    },
    "E8": {
        "description": "kid",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAeCAAAAABhiuOPAAACvElEQVR4nH3TX0jdZRzH8ffvnJ9HZ/7ZUZd6oReKhbgGabhQwZreWIxRWMjIuT8R22pBbcmgWeZcpNskCTJcMxRv6uKURMP+LGwg22AulS1jdkC3cta04yyPnnN+x08XP/OcUPtefb/P8+LL93l4HrAj4Q2f1ZfD+mECOMyMAy8ky+3cAAGGu7r7F0lXD6VujNIuKng/qNAHSf/T6HkFPin/XOMl688TBxg5Xlmt7PpLJzath4qPZsCWRmmsyuU+Ma/6B9dB+5a74826ZzT09siB+WbzWEtx769jAQMj1kyLTw4DYPl9e940LOf4WW9jaU+d+VZNHpycNnFkJj6ZmbzaaynXUGhwWwpc2u9l+5HEglx7w5q9sxzyLxE2t2Yv5Rm3s7g2mVrianwHoLJ0WYDh8A4H7t8T0FTvzKS2570cUj5WG7CzYu3gPaGR2JU0/bMbO8i66UlZg67p/RiHnf7++p/tD+Vl3A6uQRbXl1eL8pnv2+Y87shu/qtbAS77EyJrcXV3rfBcEfCcvfCafiiGSu+PkcsAPpLU4OSx/seBuCPXpStND59Z7HdFo0eGpIkyWn8b7uo83RVUICgN9MxPPfGfGc9L+ppOLXx4Uxp6qXVR0kxA/dHPLPMbSfJMWO8mFR7cvY3asDQ9JwWOR6EXfVL3Kz4Fnrbrw5IanvJKA46oM2+mv7njSzkK7ToMjF1o/5uiKJQCn46Hzy04S+3ahIsj/BEmIYIS3PAzXPnCeDQfoLAWRqZwGRBBhytpGYXQsNKOAiRncKvPD0SjxAcmPX7gO8NRVQDEbsI3KwTzq+jZQwxOAPz0FUklQFYakz4w4Oq/qKojNei5BxAaxbkFYnMdjN4l/lgioysm5pRUb//ygkXdckF1SGOlUHhHM9m2SW+3Zrvy7bxsaXovuGq+7a0wYM/c+MvOfwCd8CET3l9IzAAAAABJRU5ErkJggg==",
    },
    "D37": {
        "description": "forearm with bread cone",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACUAAAAMCAAAAADAVishAAAAqUlEQVR4nIXOoQrCYBiF4XfjZzDD2sBk8EIEs2AWFhQ0GARXDeurY2Cb0QuQ3YnBIEOTgmBYUIOD4xX87ssP7/ng/4WlVPQAho5dDSTdcmCqxK5KqZQA6WpXTy04CVBWh1alFGK5RKyDpT12BB8CJexlb0WwkdvnzIHUHgMgEaDHxPZ9AbGce5e38eA7qjwAtzGNaQz1dgx8fHbzfOW8Oi1jQOXOskurKn5i2j2iYz6X0AAAAABJRU5ErkJggg==",
    },
    "W21": {
        "description": "wine jars",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAAAAACMfPpKAAAAiklEQVR4nH3OwY0CMQwF0JdpigJyppO0wxSREjhyox84fw5Bk4xYrQ/2ky1ZH1ySixUbXLk6AZ6v1/MMSGs5Ay2krYB7yH0FpNOzYqN58NAm+F6lT6CN0TOhHEnW2uDN24oiykjiQNn+evDf399t2e2llLKbKNSkjn4AbrmNdgBqkiR1Yqx70uuKD2ZRbUvhpR3OAAAAAElFTkSuQmCC",
    },
    "Aa7": {
        "description": "a smiting-blade",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACQAAAAPCAAAAACpADKxAAAA6klEQVR4nH2PP0hCcRRGz+M95Q1iSktCCCGNDmKTBEKNDUJT0KhriwQ1BE01BU6KiwjmVoMu4Vxoi1JDe9AYBC35J598DRYkD39nuvdy7uW7YCRSmEhts8PJk6SB2TmXHo/GMjpN6Zh1GaUt6YrMq+omqawSKek9anASumflU17SdKimXQ70vbkwdG3btt2/brWjLrQUBxwAwqnxrJoG4CVvWci72YASO7nG2+9ScH8kH7PhGVTm31uOt/0AoztnMVDotA/uV2cPgOS1lFkSvahbAJzLLL3IYTBg+ZTp2gUf89Kf5h/PMQB+AJVTfAQ8TARVAAAAAElFTkSuQmCC",
    },
    "P9": {
        "description": "combination of oar and horned viper",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAABTElEQVR4nGNggIGMU+e6WRgwwdZS90t8cB4TnCVx7zEPGxbxf8zM//9jEUcFRIgjmcLAgHAZi/x7vn9YxDnUXgsgdLAoZz7c7qPY/Ibhpdy9T78R5n8Wad8Vf+YrA8OV34y3fyHE9dhvfvtm/JeB4eyvv2cQ6hnf7d7y/6kB99mXLv7PBKft+gKT8Fm1cffv9Pz/L178+f///1ZnmHoGTkZm1Uydhdf/bWRiYOR89Jh1e/8/hh+MEFet8GaLes78h5ORmcUtm4GBIRcizsDfweDA80p+618Ghr+/GRkY2BjhLpgheijeCDN8WPQevpQWwQxAywc6AhdTMcNHgv3ety8KmOZYf/nB8MAFU5xn9z+G3SyY4v9/MTD8/ocpzvCPgQEhjCRuxMCgx44pfldXhN32Dqb7Va6tavjghCnOUP376xoswgzCS/bqIngAmQ9yAJW9fGUAAAAASUVORK5CYII=",
    },
    "W25": {
        "description": "pot with legs",
        "pronunciation": "ini",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA0AAAAeCAAAAADSwsuVAAABMUlEQVR4nDXOPUtCYQDF8b+PV1OLhLTCaOhtKCvqEr2h1VTQEBSEfQepoaHP0EfoC7RENLREQ1s5RCiES9ArpaZoKpFXzOt9Gp7b+INzDgcAjq2a2TSsRQ2A042ThHO/+KRUFfNObajs0AC8B+1unerUAgBbtaMgRJO3AOzmBwDipgDArAAYCIBWxzjgGgaAma9ETNf3CueK2y9WJlM2IkrEpJQ/cbdaIcdZ3mv82oK7lOjDVphWmtlOW3NULxjpsnPZUqRf1vX/Xu699ObpsWXmM+Y93Uohf0mal1ZUadkv4ToXVtL5hO+CkmuMJOQeAgLA3Va9gVZRfRmdqHwAFaVQ4BEgq14HPSmAckMABLgCcAgBrGzSBJj2aYOr0bVeBL6lnXUHzw0p66+Th+mSlPIPp6prb86lQfIAAAAASUVORK5CYII=",
    },
    "C11": {
        "description": "god with arms supporting the sky and palm branch on head",
        "pronunciation": "HH",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAACFklEQVR4nE2RX0hTYRjGn3N2tjMX0zkky1lWrhWEJJhksQvtwrFqhOAOhEmtKJFgN4Fgd/0jo4QtIuiiyItY0oURouBF0pgjEyN1FuFMSWr+wz/TOGs7Z28XZzun5+p5fu/L+33f+wGqHm1d0gKad+SMNfKC0zD7uj3n3CWzkootrO52o2JLd8l5qmsKIy23KqFs7GGen84S25+ZUULDofNCjpczGfjoLACgRZwWhp4oJ9eLPZyICgCo6TIeNF+f+nUfANZSvewyzvAAf7McSWE54C4GgH2mBLuwcMIEmI4g2LHHGnZUANB7Z1fZubcWL7DehbqLrLw/KwEo8EYXOek7/MOyoR41qUV7J29LFDIufiMDVM0TZYmovZXi8p/5TzKR2AwOU1ecu71WYqRoorLNccM2iZHwgPIO/bO56pcbpVcF3JE8ZTZtfToDnJvdgD3pzxGlJsuI/KwC7IbP+T2juLOnCQBEBvB8/KrOaMuuidcYsN/6wEz2Mmq/5e/jpbuBnQXcF9ABUfux47/Jf2pkoC7mhi97T+OFo3QLe8fjq7WXRXrOqNwYoRDgIdpeiYoTler81DY46A5j5t25k4MlZu3+MVf1g6KtjsEYwOI/1Yo03KgHAPQPmTXenQwWAQD4Y+uv8pCB803gvS8sgTE2XNBvBp8uKYXQNPWFSNOHFqWf0mmDHF+RRid0kC2uo45x4QeAf5Kczl35wsUjAAAAAElFTkSuQmCC",
    },
    "R19": {
        "description": "scepter with feather",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAeCAAAAAA59XCWAAAA8UlEQVR4nGNggAORKT+mMjIwMDAIKDKznVXpfrWzjYGBgcH00MMnC3QupFvOu8nIwB7T+nb9PvmiqY9KHx1kYMr4+9Oea/FZzopFLAwMDJqH//9bsOr/nRnT2BkYGBiavx+/8P//uaYwYQYGBgaGH9c1XH/+v3HcjIGBgYGBiX33jUN7GVLZeSHc+5sYmL4z/P7zDcKtOMXAwMQw49hTuOsYI/4f8YQwmRgYGP7/ZFi8HcFlYGQ4yYDEZWBgReUyDAj3H8NfZK4IgwSSCuFT/3eyI2Sn/jVTakfIft7AcOk6QvYZI8O/5wjuXgaG3/sgXADDOFA6EtYIWwAAAABJRU5ErkJggg==",
    },
    "N5": {
        "description": "sun",
        "pronunciation": "zw",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAAAAABzpdGLAAAAo0lEQVR4nG2QIQ7CQBREXwkHWINZFNkG04tg0NgqlussCoksjgTTi+CaIltPsnYQ2zSb0JHvz5/8PwA4HyUpegdQANVrxwW48Tm+ATBSMAAmSAbAarRMsqMsuF4zAave4RXIFOSJab1umjoFR+QTkRLzWif/4VTScQdgxZ8mV0vHo53YQvzCEQunYjVsZzKkuZGum+ztAqieJedVXg7s/Ter8AcKYFG4nxlnzAAAAABJRU5ErkJggg==",
    },
    "O13": {
        "description": "battlemented enclosure",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAAAAAAeW/F+AAACNklEQVR4nG2SXUhTYRjH/8e9c1859+lCcZ9U1pbBWjZInHODVqyiJDDBZoX0oUHSRV0aRWhBF0kOKjDImyCCIrxKiaKLkCQXiVEkJaMIrX21crbzdrFzjufU3rv/83/eP8/v4QEAAOsUAKzjmzAcqPCaPQyjAfTq6pKJ6rv1ip6h8JsN1nSP+kHgZYPhjqvq4ObRAAEAOEOGumuatYXFfq2hY7usKWSPvX+9197dRgCAHLD0jq/5uUPe24Xvfu0KlD6YGyNeWAl0EezuQucWaFy4ALjM8iicKoT1JhMA1Jy/R2mOln8MABwfSfdl8f87uQuMrbVjnqa1ZVxcp4T+2eeWAapMGZuAINmPPQ8ruIL6GFWqLtHVDqb92dPnbMYCAOieYlm6wvDeCMXWya/LlKZLtrXJdaOYEtlkYch52M/rytpmzy9mNRpEvr+zSlDtgyjKUuLpFOtbbr7iw42ejdGPOXH48kJy9qyXq9R73DvtYkSC4GllKzgUazN955BJ7On7J1ge+0Uy09im/mc5piOU4w7OpnL0h5ib0W27kuNHQ8Ojid8SbmK7HBZyaoKJOr+Eu5ic1vl45RuWAWLuCufgIYfQO+MeYCVjkQ9nnJZzoVKgLW4UILjfyCUqH5eOBl9uz83cWhJzY2BiKpsXJlfpj85Lljr2NuYwclIbizo05rw4fPHzxTgv5N/G+kYLEI6lAGK76s4CcgYAluZOKf2aQpz3WwBF5BOllK0FAPifJPKSO/8LasvbMshxXRAAAAAASUVORK5CYII=",
    },
    "W8": {
        "description": "granite bowl",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAAAAAArYZAiAAAAoElEQVR4nI2RsQ3CQBAEx7TgyCWQ0MQHpI6gAmL0EZ04eCqAzJkJaIIEIX0vQ2BshCXLbHZ3I93uHfyqblXbetIuPD8f97G87LgBW677sRc26wOqOcUAUDW5KwHKLjcVQIjppYqmPKA6Lqt1QF5JUQjHHjV+3ZzskRhACylYkqxGozHln3z14LgnZ5ZGe8fHAEsRPhNdPkhW/fe8E8086w2qIJrHJ7o0KQAAAABJRU5ErkJggg==",
    },
    "M4": {
        "description": "palm branch",
        "pronunciation": "rnp",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAeCAAAAADbKWvvAAAAhElEQVR4nGNgYGAQrzv97+9fFgYGxsLiD+V/GBgYGDiePI5mYGBgYGDg/lrEwMDAwMTAwPD3NYzFwAxnMeBh/YOzFJkhLImMA1z/GRgYGFgWm52xgEj/n8zxPoGBgYGB6b+5xn+Iumr283wQJqPB/D/xUCP5PydAzfv1H2YyE14XUJUFAMj5H9C2m3QZAAAAAElFTkSuQmCC",
    },
    "A51": {
        "description": "noble on chair with flagellum",
        "pronunciation": "Spsi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABcAAAAeCAAAAADiTtq0AAACMUlEQVR4nFXRX0hTcRQH8O+2O0RzuLV/IgtrZZI2ihB1FiGMrFRkCJEvmSswGGwPSoToaz0k/ROslyyECYFEJW5BGhVsDp1LIyc5dTEs29bGXOTcurrTw71X6vdy+H04B84f4L8nMk9TrFe1+792jIum71t3H5FLx/MlegYAKF7MfX2o76QejtU++qQDABt5ApPjigm3GgBwI03UCkCSCDadtTyGZbWUAVDbMpuUnXFlgFRyIXyuriS8VwYAk/fGDI2JAwBe0Vx1+ZrzChkBNM+bl7TVqTagj/XPxmcSlI4fBdSe9q5RiYUChegY0ObFfgVywSYA1qzWexWGVXp6CEBnptsQ7QMYRLNvNItYeH69wxiSMIaVwUyUBQBJmbdXDJji5Kjoz9JLiJccAIOdZSMAnGJQdWHzm34Kcpm6IC0SNrTnZJlWZt6PKn/Na+l727/LVJ2fI1aH9kyO2hjeGrqqpb9T7MyHnxD/sZ6+zXvlcGDkR9AX2wJQzI6Z9vHpQ74i7i5KZX1oomSa+HzTVGr4hIhlpPmQFVm0B8E7RY63yPnatahOmeSd9TfInetigPJUtYO38JFj+efKoQUFAECieLDRTXbO67z6Lz3CGJrQJtWIOV/Wl/sEjz0pQDM36Du7Myy0DOi2ySMGUHinPr9xdH3X0ztgAWjGt12unEVQ9UCSyI3D9vmEFZc3TILbiDKJEeZFBSJH7tdt5wR3h0v9/StwRIiI6K1McNHF1E3gL4V34haAbsS3AAAAAElFTkSuQmCC",
    },
    "Y1": {
        "description": "papyrusroll",
        "pronunciation": "mDAt",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAKCAAAAAD9OHM/AAAASElEQVR4nI2OuQ3AMBDD6CBbeyTN55ouEhhJ4YcHqNJJgi8RUAHDHEM11udhStS8uvZl6K/GtrumZblhcEPZmuQ6CuOw9DCtA0ZlQsOWWYvzAAAAAElFTkSuQmCC",
    },
    "M41": {
        "description": "piece of wood",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABkAAAAHCAAAAADYXrlUAAAAhklEQVR4nGPgVLSp+A8BB/JsGBCAMcdR1BbK/sxwbt25IzAZFvag/wwM/w6vZ/jNlKZibz+d4cQfuDabmU//v/dgYGBgYKjf8v//WWQj5Xpe/f8/11KDgYFBYeH//5sbbBgYGBih+hKSGRgY+j4xPNcsYGBgYGDYeBAqw8DEr50k6oNkDgMA5KEtySKvP+IAAAAASUVORK5CYII=",
    },
    "O7": {
        "description": "combination of enclosure and flat loaf",
        "src": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAeCAAAAADf3LvSAAAAtklEQVR4nKXQoQ6BYRTG8f/3en0T2CSBJNm+KRrJRShEV4DNFFVxAxTBDSg2cwVGU0TFBJskCIZ5hO8dppmTfjs7O+fZ8cSrLKt1qEIRNVy3IUPMOYYFTD513DzAoPhwMV4M48Jybdb6k0pnf8aSKbVmt9GhvgTNd5Kk3VyW7TQJcApAbbezLUPEOYJ5x/nRFywAvaxH4FxP3zFuJjr2/a7rg9Aft759AXQNM1RzkCgPKOB9/PYJ1eg2C+kg6NQAAAAASUVORK5CYII=",
    },
    "T25": {
        "description": "float",
        "pronunciation": "DbA",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABAAAAAeCAAAAAAAksHNAAABs0lEQVR4nEWOT0iTcRzGP+9v7zujd+WQReArLXWHdLYyK0+LukiQRXTpHwYtp8dOQotBduneKQohhKDoUCYhFI0GIikRLSulKOuQ0sy2yTt77W3z22G2ntvz8HkeHgDa8yIimWYAHcD1z2c9W94uVINv93bHivGAC6B649tYfrojaR9eEQClD366G8U50WeOrAGgzmdEpCTyvgUAfe32s+5A7SmLkst/7c1P/bAvVBoA6owZO250qCqwXwab2vrt9mpwsRgdftP49cY/b86NbpzKaNdzofWN1mD6V12tmfIeWCcGZj3MzjcwOW6CAj1SKAdNX5CR8D5QUH/oCXHLOccDpxUU1KzexJJLjcbHD92bUdDlXfRtv/JiaxuPKhsHx8u7Iq+yrzvIWkEUlP5ox6YnCxPJwPPfLSgQpyk2VOBz4LS7ZKDwGMXo9zRMpAY2vDvrh9D0y2w/QJc9djQVhPCMjFUe37cf/+xUlMr4EzsBErkjdX6NxFUDFpcU5CMmd/SaeoOVGV0DvAKW3rxn7sumTjRA0uGFVXWy4VrSqyEiYoWGL/so5oZuFXoA6HUfjjp/ATdlndyemM5iAAAAAElFTkSuQmCC",
    },
    "Z11": {
        "description": "two planks crossed and joined",
        "pronunciation": "imi",
        "src": "iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAAAAAAEZxHwAAAAqUlEQVR4nMWSsQ4BQRBA38yti0QtEj/kC1T3B76ALxDxAb5ANKLWqlUKCtQUSp24G8Xu7d0laraYeXm7k92ZLAAgVzPbedag+ufFU5uqtR09koYit4hlRkqoFD9WeQzgMr+jkPc8Y2HNOQZyLKeA7qF9yIBJpgggEpuSqnDGqSwcFgrGKiW9jBVE3NrfUijJfVN/VxLDH4fzVb0oAjmf7D3odG+Nw/Vv8gGq6UVizqjWPAAAAABJRU5ErkJggg==",
    },
    "Q5": {
        "description": "chest",
        "src": "iVBORw0KGgoAAAANSUhEUgAAACYAAAAPCAAAAACt9eKMAAAANklEQVR4nGP8z0AMYCJKFQMLAwMjQUX/iTVtGChjYWBgYMAfxIwkmoYviCE2EW8aocj/T7xpAB3oBiOmtLxCAAAAAElFTkSuQmCC",
    },
}
