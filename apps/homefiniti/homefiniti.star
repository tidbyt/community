"""
Applet: Homefiniti
Summary: Homefiniti visitor stats
Description: View live visitor stats of your Homefiniti-hosted website.
Author: Donald Mull Jr
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

TTL_SECONDS = 60

ONEIL_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QAAAAAAAD5Q7t/AAAACXBI
WXMAAC4jAAAuIwF4pT92AAAEq0lEQVRIx52VW4iVVRSAv7X3PsczpzxSRPUQDoLlocvkLXMG02Iq
U4kepBIE07LoPHR5KIig20NQ9hAVcYhGK5woiyLKW1mTll3EmQgNm6QXLYyoh5jR6Thn77V6+P+Z
OZpktZ82//rX+va6w2nO8NZl04e3LysDHPvsusdHvuh+EuD4N/PbRr+9Ysbp9OWfhEPvL5uDo18c
TxPsbSnoVvFpknjtdoXRmyQ0HxEX5xZn9g/8a8BQb/d5eL/OnDwlBX85Xt7AgwSQoDskaMTrEhci
4iPi41pXaOwUP/qE+OZDvnrw51Z74W9Is7NRXSXiV1my/AWCwf7JN2y7HuDYzsVfGqEzE1mPpmJy
Yh6xZ4BTA472zD3PcGdZakYsDAGVzLj7GpgP8uv4G5I7iNGJ+N3AAsArdlzUF+KB6kXi4p+++uNP
AG4cpXGdoN+Lxr1orJDSEVK63tTuIRkkm3AyCpYc2gz3m8nVlsJhi8VJpr7P0qQfzMLTY/+OA8T0
GTQiGqeIxiNo7Kys/HiHqELSEwAkwZJg0VHu6ttl6hZa8octFSZbKmJx0rMnABr1GXPERi8Wi6BN
0Li6svrzwwDE2M4YZDxEGYQk0wHKXX2HULfSYkBjEW2WOpr7Z84BcI16dTpIv5htEouIxXcmr927
A2B4Q9dCNPaSEqi2eJBDlNeHty+9FqCt69PdlkKvpYCp77EU+pv7ZnU44AiwThDEDLG4HuDoy7MC
Gl+VFEtogpRaAAYRLOFR2Ti8bVkbgKl7xWLAUgFLxRdM/Y+uVBscAd7KilEQ008ARNMSsea0PC+g
sSVECmpjnpxvytKsUORTS14tBnS02Fuc2T/iGvXqo8DmXPfnttrB0bxULhaNZHmJiE54IEkzSMog
JOYBnLHoI7PovrPkMHVb/tyz6PkAlIC2sWKdaPHkMECzbjCYOhGidIlk3xAcIH7CO1HwAEWEgivV
Bh8GunP51Ea9GrKytQNCQiwLkWi8aHj9lQPDryzYg6a5pNTqyZ5xeHSXWXJY9IvLXX0116hXS8CN
Ld3dnXngtovxSxboiFgT0TgbjfNIkbHES9LfLOmWfDgutIQn65HlRz9eUnZAO/BYC2AVQKk2eBxk
jRgqpCzJFhFt5klPY5C7ptyyfSR7vd3RUsIPmMkMyRqtOgeYCfTkkKtKtcHduewGw14zkXNNPCYB
XAFzhd/NhTsrqz9/D2DozcWz8W4AL+DlXinw5eSlWwbGx3WjXp0GHMwH4GFgYak2eCjv9LJhS01c
p0lwJuErXNh85tr+EYChjde04/wuvG/HO3DSUVm+df8J+6BRr/YCK4FRoAgcAlaUaoNf/+PG29A5
21x4Fx/acT5a8EGc21S5eduKkwEXAOeQ1VgfUMlFvUBPqTa4q9XwsZcuWWBSWGuucFsWspDw4WpC
+MOcDE+59cNDp9xojXr1wjxUJ58E7Mt6wi4zkWASMClgrgAuYOI6Kmt2729Vcqcw1ADeyJYMt7d8
98AsYJYgIZtbCbHmfYJeiqVNYjr0n5Z+Xl39wIvARuCDvPOvA1tu8KCJzC3fPTjA/z2NerWjUa+W
8/tzjXr1pfxebtRnzD6d/l+EVGcqps4DawAAAABJRU5ErkJggg==
""")
PERSON_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHCAYAAADAp4fuAAAAAXNSR0IArs4c6QAAADRJREFUGFd1jMEKAEAQQfn/j57tKTVzWAckWNIImpFtrOCEGwlpFbRNguk8+v08Leb93BcPLuwk/neqrrgAAAAASUVORK5CYII=")
ENVELOPE_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAYAAAD+Bd/7AAAAAXNSR0IArs4c6QAAADdJREFUGFd9jtEKACAMAr3//2jDoLGC5ZNMuYlt6yMkjR1AJI15Qee2C/nQS5fv/ARRpxVh2rkAha0m8k92rkgAAAAASUVORK5CYII=")

API_URL = "https://app.homefiniti.com/api/v2/tidbyt_summary/"

def get_real_data(config):
    api_key = config.str("api_key")

    if not api_key:
        fail("No API key specified")

    # note: fails with "Bad Request" if there is no user-agent or the default "go" user agent
    response = http.get(API_URL, ttl_seconds = TTL_SECONDS, headers = {"user-agent": "tidbyt", "x-tidbyt-access-token": api_key, "accept": "application/json"})
    response_json = json.decode(response.body())
    visits_today = response_json["stats"]["visits_today"]["value"]
    visits_60_minutes = response_json["stats"]["visits_60_minutes"]["value"]
    leads_today = response_json["stats"]["leads_today"]["value"]

    return (visits_today, visits_60_minutes, leads_today)

def main(config):
    api_key = config.str("api_key")

    if api_key:
        (visits_today, visits_60_minutes, leads_today) = get_real_data(config)
    else:
        visits_today = config.str("visits_today", "99999")
        visits_60_minutes = config.str("visits_60_minutes", "999")
        leads_today = config.str("leads_today", "999")

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Padding(
                    pad = (0, -1, 0, -1),
                    child = render.Column(
                        children = [
                            render.Text("NOW"),
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Padding(child = render.Image(src = PERSON_ICON), pad = (0, 0, 2, 1)),
                                    render.Text(str(visits_60_minutes) + " "),
                                ],
                            ),
                            render.Box(width = 2, height = 2),  # spacer
                            render.Text("TODAY"),
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Padding(child = render.Image(src = PERSON_ICON), pad = (0, 0, 2, 1)),
                                    render.Text(str(visits_today) + " "),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Column(
                    children = [
                        render.Image(src = ONEIL_ICON),
                        render.Box(width = 2, height = 1),  # spacer
                        render.Row(
                            cross_align = "center",
                            children = [
                                render.Padding(child = render.Image(src = ENVELOPE_ICON), pad = (0, 1, 2, 1)),
                                render.Text(str(leads_today) + " "),
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
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Homefiniti API key",
                icon = "key",
            ),
        ],
    )
