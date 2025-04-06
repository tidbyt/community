load("encoding/base64.star", "base64")
load("render.star", "render")

ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAjNJREFUOE9dVEtyKkEMk7uPBCzDNuTEkGVgSXKkab+SZA/U6wXU9MeWJdkREZl4XwkkENF7gUQivI1AICP1XxvI9Lf2tc2fdIS1Ft5eay/qjPcUpBYDzDGUxskU+JWbwcYYaMwZ4dj84VWhbDQMnljJN1NnwhYhxIK6tkSMgZUbZkyhHXNgrQ0juL90noth03cYkI+FnviMlsmwVgohD4myC/CFVzGu2kFybUoiToWwnwrhAst8XwrMW521HoqEKo9VdMISxzBZ2pxz573ZLSIblMptJ2xd1e4BieJlruYupi0AnC9P7f3cTrue4giAA+4Fmy3G5HmS9JiFRDhwvvzhfjvIOuevJ+63oywmd7JkcUiVm9ngVXkDW24Whaoj8HF54vF9EhKZN4CPyy8e1yOv6w6riighbS7Csym3tYpDJzCi08uXQvzrPQuPXKyqS5b91EcuWca2yuevP/zcjkU+KRE7TsSg3wf3RtmmlbTy5avcKmDw0VMi8FQp6qLLfuLBs2pVGXuXSwS6rTa1EXszjeJ6dA3VwiKeAT9Zts/kDIpSTrGxy3DiY9r1JP9+PRQ6U6LQkTh/Uvmj0oj3QWeYlpo2xtDDoXwrHhm0Gk2IWmUHaN6nB4h7uRykXqbKo9C8fNgzi4RbKJdOGGxX0mQblW3alD1NbLyeIP+L0pPW1rDV7N0eGfs84B553CexR5y7wkJ7Ark6LbWdvnva7AO2UFVL9XSpcWpbtJSet/t6n0j/AENviC1XLMEuAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "done": {
        "de": "Spülmaschine ist fertig!",
        "en": "Dishwashing cycle has completed!",
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
                    render.Image(src = ICON),
                    render.Marquee(
                        width = 35,
                        child = render.Text(LOCALIZED_STRINGS["done"][lang]),
                    ),
                ],
            ),
        ),
    )
