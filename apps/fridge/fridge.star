load("encoding/base64.star", "base64")
load("render.star", "render")

ICON_FRIDGE_CLOSED = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAfZJREFUOE9dVQlyRSEIA73/kYU2C/razp8uopCEQDMiG5/ojMCnQ986ox2KzOhohBGMCMd5pnfRHZ0ZmZn4lXcyM6qOH/E1Eyk2yXTGwki3EUhheOVUBcn2WqrrC0MA8fuAyfA6o8+JXFvomYbMQAmoEVymjQOdI5Uv6md3VFesXFHVsYGSdykL0uHvjq4m7VvOmC5aPDDSPs3iYLX2tq6UDZkkKINAaPmlFShIdBSbs2N5qkqU3x0lxNfpjsWIUrIho8tF625axlMlEBZYDOSHqFN2j3S6jX36WCUxnKegDoiEMpQBRfDHbV9/SWn6UuynzVEtmUiFhKwhLoKybCP8Usx+e953QsmBRqLbkgdv/EoJocd+JiVYGfJab9gaS52OtdeFzcaRAqrBClum9mh86Dm5m3QOikMm+bBb2GwrWaPO85TMPq3zzHqGUZwJkegfCBnbZuXoQQ9oQZqTcKi7YdlOuNlIWE0+dFPmMYPTsTeufxaE++zBTloNjQSCO+taQc0gxmgCxAWBScHzTJ3s08yAscFqVgdto1WEbVNqyt15s8LeeEN8GtoToQ2FWTZl9/TOK7p2d+a48EK2UEQu3TiqM26XjDc1l3YHaRAntRk2poxF4lHBVJHNNFDG9nKYrfXdpFaTcy0Z778J77w7z2T8W/wHepFpL2+vpssAAAAASUVORK5CYII=
""")
ICON_FRIDGE_OPEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAjVJREFUOE9VVMGRGzEMA8WKLldA7Oc59Sb39KWAOBVJzACgZGc/O6ulSAAEGQFUIYAo+AkEClWBiAL/RfmtmH1ejNxP8BjgWei2f/Cw5lLSOgXOLSVQAUeraI7hZEpCEJ2wIrDWwggfEvcOcyDRdeHDBVjkNxjPGKEO5tIz58QY4yR0zc7DQsal2DUXMhNrTkTmoS8s/iLCiRFpuuTRtKMFYmX/KqxZojtr6c06PFcHfAGmnNTArdm0eb6hMjRHNpv0HbHqBrqmn1X8KcyYTNKUJc6JKowcp4uryKq/SSoiivoTFwUW9KNCwD+7v6K1bdSgI5DsrDQuJzS1EEImoNh8ywKdb/ecFK8fj40dX7++ifLTo1Sqq84q6/HiMzvAnuObLK63P0eCr893BO/Q/LYcKbs70oNGPfWflEseHXLC99ujrQV8fb4hhm0jqWyb7jI9NdKC26TuNE0/lwzMxJfbw65C4P7zDSOzHfGCUHeXKVMPadZ2Yj0beKBm4fLjoQTk9bs1tAf3pBAsG7AWghZQdfeqV8WZBNrpSoTtVVKWTIb8f5cZnERh73Ri6yijB/05cfn4ezyqhPJhW0u2aeft0bOwTvpcURaWCYWwJ/P++X6G4YUyYwtzcT736O1+7P3maakiQlL2srhTw+xUzYQC2nk1Dd3i9dmeiOfm2XuRcfbty6rV9b2/2ibsttykjhuZkvRO5LRo90V2W7doVtr4emVZmwPaf3sp7i2+d22PeHvSGv8DMwh9M8JCSOkAAAAASUVORK5CYII=
""")

LOCALIZED_STRINGS = {
    "close": {
        "de": "Kühlschrank",
        "en": "Close the",
    },
    "fridge": {
        "de": "schliessen!",
        "en": "fridge!",
    },
}

def main(config):
    lang = config.get("lang", "en")

    return render.Root(
        delay = 1000,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_FRIDGE_OPEN),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["close"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["fridge"][lang]),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = [
                            render.Image(src = ICON_FRIDGE_CLOSED),
                            render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (0, 0, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["close"][lang]),
                                    ),
                                    render.Padding(
                                        pad = (0, 10, 0, 0),
                                        child = render.Text(LOCALIZED_STRINGS["fridge"][lang]),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
