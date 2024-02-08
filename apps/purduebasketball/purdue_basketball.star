"""
Applet: Purdue Basketball
Summary: Shows basketball record
Description: Shows Purdues bball record.
Author: Griffinov22
"""
load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("encoding/base64.star", "base64")
load("time.star", "time")

purdue_logo = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACgAAAAXCAYAAAB50g0VAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAViSURBVEhLvVdbbBtFFD27a3v9iJ2HHyl5NA15tFVFaNqCAhUhpQ/EV6EIKn75QIIf2n7wEm8kJNSABBGiH0jwBxRBBXwAKiKUqgqhIaiV0vTlBic0SRs3cRK/7fUyd7zj2htHbVHgRJOZvbv3zpl7Z+4dS5qm6dFoFE6nE8lkEjabDdlsFrIsg5DL5WCxWJBOp2G32xGPx1FRUYH/S0daWFjQHQ7HEiVd17kijUlG71KpFFdOJBIw6yiKwicROmzhJRMW66iqyuX0XuhIkrSEJOlI7EGnic0TkQKBxroWx/T5I/wZIOL0ztyXQ+k3OvuTSnRYL8mQFTsUmxuuyiao7jWwqU5OkhYiMbfrVqt1CTnhQRrPTQ5idnoU0xEHl60kyA+KnIPdqqHSyUjZnahq2A6XpxaZTAYSc7lO4RBhFeSEB7VsGtPnPsfEjBX7XuzD1NQ0l68UZFnie211YwN2bO/Grq23wVvlQKB1DxQWbrmYTDkk5oPcuwPD4wiFxrnrV7IlkymEw9cw/Ocp9L73IYZGosimF5BOzHBHyRTSct6jnlr02hnMRlUc/emYQfm/A3G5PBXmYz2Xym83dkB0ijWdHnOoY/PjmBs/irGrbkxMzjI5OzC6hEuhK/jo0MfckBk1NdV47sAzzF5+D5sRT2TwxZffYeTMWUNyHTTnB+++hq4NErzNu9k+DEAmN5c7wUQyMZc30hxYRPdGK+7vVHFnuxsjI6NcXg7beu5DV4eTf1uudW+qQkvL7cbXpVi3th3N9U7IlgpOjrjJlG/M+Ux4sLp+KwJtj6Fu/ROorN/Gjfw1lcVvg7/zsRlkY0dPFxRJRzKtLGmRuA1/nE3hl2PHDY1S7NrZA687hcrAhkLOlSKRiE6niDI3CYh1cQIViXru8nFcuxpC36eD+Orrb/k7M2prA7in627jqRS06NnZOQwNDSPBHGLG2vY2vPPGU2j0Z1HT/AjcnmpeeW6q1El6BpOjnyE4reLpfW/ziVYStG9ffelZtvdkuAObEGjcUih1ciwWK0uOVkyNQr4QHkE6o6P/xOiKkqMcuGVzJ958ZT/uWq/A4a6Dt66TcyFOxO2GpU7TsixRH8YkO/0HXj6EixcvcbkZnRs7uNEbQVZk7pm6VbXY2NGKlgY733cOdwN8ax5gTpEL9bhQ6kSKIXKUWuIs9+WThI6clkEqPoPvTyzg9bd6udQMv9+Hvt4X4PNkDMnykNgBssg6VFbaFNYrtipU+O6A29vGyF2/aBAXchgvdcWpJTz2A+ZmryKashgmgVRGwcG+wxgYKH969z6+B3t33wvVphkSwEdecfkhWStBtT7DPGLlUdLYZcDFCrALdlctrKqHF2SROYp7IiuxKw0b54WpeBgzwW9wKmjFwfc/KZxkwthYiK+oHJqaGvkWIVBYnt//JNY1xFg9fRg2h7fs5MU9Ybl3JaWOylqcee7Hn0/i3LkLuHAhWGjLkSOEQhOF73zeGqyqzsDqqC2QI/tinuJoib54LPqCDu0/PnmOFe75S7gyb0N//6/G1LcGMv7gzm5+baoMdBRIkX0xjziEwimkU0zOrCMtLi7qFJbw3ycRuXIKQ+dtOH16xJjy1qCyRP9QTyvq/Rb4Wx/N7z1W5yn8lCnETdp8/yQIcuJwCB2JGdDj8RjCwSPIZWNsJctfvW4GdEpdvs3w+NoZmSQqPH6e1+i6T1d4qlbFaY28RRBhFeSEDi91DrsVkXAQNmNlMlsFKbB/eSV27GnVaaM+lv4mUZlOxvAG02Hrc3pWQyNvsLmzmsTzI1WrmympgpzQkZhQX66aEMgAGSKDZPjf/kJzuVy8Mtyajgv/AIyH9xPiK2PkAAAAAElFTkSuQmCC""")


def main(config):
        year = time.now().year
        cbb_stat_endpoint = "https://api.sportsdata.io/v3/cbb/scores/json/TeamSeasonStats/" + str(year) + "?key=" + config.str("api_key", "")
        
        purdue_stat = get_purdue_stat(cbb_stat_endpoint)
        wins = int(purdue_stat["wins"])
        losses = int(purdue_stat["losses"])
                # child = render.Text("{}-{}".format(wins,losses))

        return render.Root(
                child = render.Box(
                        # width=48,
                        padding = 5,
                        child = render.Column(
                                children = [render.Row(
                                        children = [
                                                render.Image(src=purdue_logo, width=24),
                                                render.Text("{}-{}".format(wins,losses))
                                        ],
                                        main_align = "space_between",
                                        cross_align = "center",
                                        expanded = True
                                )],
                                cross_align = "center",
                                
                        )
                )
                
                
                
        )


def get_purdue_stat(endpoint): 
        data = http.get(endpoint)
        if (data.status_code != 200):
            fail("could not fetch college sports api. You might want to look at your api key.")
        
        res = data.json()

        for obj in res:
           if (obj["Team"] == "PUR"):
                return {"wins": obj["Wins"], "losses": obj["Losses"]}
       
        return {"wins":0, "losses":0}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "api key",
                desc = "API key you can get for free at api.sportsdata.io",
                icon = "key",
            )
        ],
    )
