load("encoding/base64.star", "base64")
load("render.star", "render")

ICON_DRYER = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAiRJREFUOE9NVEGSwzAIE/ZDm76syUNtdiSBs50cmtiAkASBQCIBRCCAftFnPfrOKwFkoi6BP0fw5xR8jYjoSH3YeysweZinmi8zUDmdiEnGCCbxd93phAjsvTBjVCknH2O4AUacHhyWLMg7k6Vchg0lH17eayOYIBdGjEo4sfQ+kckCgcV7jCSyzZh5cBGl2idXey2MOYsXIlyYYzaDvFRciVG1aYQsZhIqoS/ysBQyS9LB5DR/579a9G2iNy6hVr96JSJy1rQzmQl3ZSMsdOWKpZhpuOKwylBVckj4FMBhjboURkgA+8LnAqEY1auW1RpV3pjTrJqCxJgUqTUEiGhKeXkEKd7dVVnKLRPVkopD1XamlFbqakPGyNRZ6IyvC/Gfw9abDayVStjq3s8P1/U9/Nz3g8/3UnF2Q7vs3Jh2dE2PISjvXokYLcIgbNz3jevzPSP3qMilu+RT3qXVyvdWWYQmshDSyDMmfs+N73UdS9w/JyN/4nuE2x89055QTwqf4o1tiKNIPGzzcptM9Dw3Pp/rHUtxOM7OeBNSJSomHwKrkp814FVkqwjV8BLZiaCVWuVaFLq8yyYdyNnt6kW1kVHVMt6xkaEZKd2tyjJ2WYUuhdXsAZW95NN3R2ZNl/ZmT1bPQVbCd1H1QL+D73Ew30zrSfGKs2Xj36Zr09bEeiH07jtr0lNha9Qo9hYqlXXsbVtr/rWBp6F3q1G9k/4q1bP9B/iZniiwNfaqAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "done": {
        "de": "Trockner ist fertig!",
        "en": "Drying cycle has completed!",
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
                    render.Image(src = ICON_DRYER),
                    render.Marquee(
                        width = 35,
                        child = render.Text(LOCALIZED_STRINGS["done"][lang]),
                    ),
                ],
            ),
        ),
    )
