load("encoding/base64.star", "base64")
load("render.star", "render")

ICON_WASHER = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhJJREFUOE9VVQFu4zAMo+x3Lti97NrtnbYGkpLTBAPaqLZEkZQWABII/elbAJnwU2HGMxzkMT56Sx64D0cmAsEIg84YGciqwQsu4Er8xcmZJ1REt/lbpj9d56609q7yTia4n7D13Un5jDGUzO2k6mb/mGshxkTuhZgTe28MJmh0vEQk1Rg/914YMZ1M0IxcTedOxKwgL+6NGAM7E2PwMgsMbJ4DYy4as1B2y0YAXxjDpOfz3Z0eAg/X5Fd3xCEblyiWbec6opHgjkumej8SfshNhHKAVC7b8Lzgi7PSXOSK6OOjYrCU951ZHJbtShQhZMvsrRRLYG2xexw4C42sRJpyY44hodh2+UW6ueUx7akSifx8+nd1Ao+DVNadGgh2aH83h/QVAqvtcM9Fmxa5UuoLVFvLtj+GOtXGNPy9qn0E3q//Svv97xuv1wvXdUlZGrg9212VD00+26G3JPpe+Pn5rUkpFu0LXF8XXDhdeDZN8nB4dCNLZbreRiTx7/fblpDSoWQ2v/Qv73ocna4Ssvhj1GrYifQoyAGQ8WuJEAunJsh7Gdty9OhxjBhx/Q8TlIr3mjNqd+VZPuay900msNd6LIN721UBb0KfR2KS8wOpqXgsTvqIK8wzWqXunScz2+xE1vvSqYylFlKNrpfgYzN3pJ1WIGsR30NdovR69mb2Vmnb978Fub+aJAon6d3rTePYH7N4gi5b+kNtAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "done": {
        "de": "Waschmaschine ist fertig!",
        "en": "Wash cycle has completed!",
    },
}

def main(config):
    lang = config.get("lang", "en")

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = ICON_WASHER),
                    render.Marquee(
                        width = 35,
                        child = render.Text(LOCALIZED_STRINGS["done"][lang]),
                    ),
                ],
            ),
        ),
    )
