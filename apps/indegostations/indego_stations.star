"""
Applet: Indego Stations
Summary: Indego station availability
Description: The user selects an Indego (Philadelphia bike share) station and Tidbyt will regularly display the number of regular and electric bikes available.
Author: RayPatt
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

url = "https://kiosks.bicycletransit.workers.dev/phl"

ebike = base64.decode("""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""")

bike = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV/TSkUqDlYQcYhQnayIijhqFYpQodQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdHJSdJES/5cUWsR4cNyPd/ced+8AoV5mqhkYB1TNMlLxmJjJrorBVwQgoA9jGJKYqc8lkwl4jq97+Ph6F+VZ3uf+HN1KzmSATySeZbphEW8QT29aOud94jArSgrxOfGoQRckfuS67PIb54LDAs8MG+nUPHGYWCy0sdzGrGioxFPEEUXVKF/IuKxw3uKslquseU/+wlBOW1nmOs1BxLGIJSQhQkYVJZRhIUqrRoqJFO3HPPwDjj9JLplcJTByLKACFZLjB/+D392a+ckJNykUAzpebPtjGAjuAo2abX8f23bjBPA/A1day1+pAzOfpNdaWuQI6NkGLq5bmrwHXO4A/U+6ZEiO5Kcp5PPA+xl9UxbovQW61tzemvs4fQDS1FXiBjg4BEYKlL3u8e7O9t7+PdPs7wd3y3KptciwAQAAAAZiS0dEAHkArgDn4Ak+cAAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+YEAhU7HRYZ3g4AAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAzElEQVQ4y+2UyxnCIBCEZwiHmApiWbEbGojd0BYlxIP51otrIvKIeHVPPHaGn/0WgH/8GvxWICLyZkCymBwLSuF8+Mg1qfkR45QZANgIX7QMOUEtTAtF6bCs4fVyTpLWyG1r8attE4tyhLq3X9fc15WdD9J3Wzt1zFOpeJ7GZG8a54MQwG3d9DrMUYuI7BuaJNXUztO4kByO1Mv50D/zP16HmloApxRFTOJ8GGptlnybtb1avgGwFM5bm76cFpLc2r5edwCdkpG0Ld/YAyMCmWAhR+OJAAAAAElFTkSuQmCC""")

lightning = base64.decode("""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ZUV2ZW50IyIKICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgIHhtbG5zOkdJTVA9Imh0dHA6Ly93d3cuZ2ltcC5vcmcveG1wLyIKICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICB4bXBNTTpEb2N1bWVudElEPSJnaW1wOmRvY2lkOmdpbXA6ZjE5NGQ1MWQtM2ViMC00YjEwLWIyM2QtNjgwMDM3OTJiNGExIgogICB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjIyMGNkOTQ2LTg5MjMtNGQyOC1hMThkLWIzOWRlZTcyNjFhZiIKICAgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmMxNDlkNDc3LTcyNjctNDYzMS04ZmM4LWI1M2M5M2RkZDhmZiIKICAgZGM6Rm9ybWF0PSJpbWFnZS9wbmciCiAgIEdJTVA6QVBJPSIyLjAiCiAgIEdJTVA6UGxhdGZvcm09Ik1hYyBPUyIKICAgR0lNUDpUaW1lU3RhbXA9IjE2NDg5OTk2NTAwNTYzMjYiCiAgIEdJTVA6VmVyc2lvbj0iMi4xMC4zMCIKICAgdGlmZjpPcmllbnRhdGlvbj0iMSIKICAgeG1wOkNyZWF0b3JUb29sPSJHSU1QIDIuMTAiPgogICA8eG1wTU06SGlzdG9yeT4KICAgIDxyZGY6U2VxPgogICAgIDxyZGY6bGkKICAgICAgc3RFdnQ6YWN0aW9uPSJzYXZlZCIKICAgICAgc3RFdnQ6Y2hhbmdlZD0iLyIKICAgICAgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo0ZmYwYjVlYy1iZDBjLTRkODUtODczNS1mZWEwNzFlY2ZlYWUiCiAgICAgIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkdpbXAgMi4xMCAoTWFjIE9TKSIKICAgICAgc3RFdnQ6d2hlbj0iMjAyMi0wNC0wM1QxMToyNzozMC0wNDowMCIvPgogICAgPC9yZGY6U2VxPgogICA8L3htcE1NOkhpc3Rvcnk+CiAgPC9yZGY6RGVzY3JpcHRpb24+CiA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgCjw/eHBhY2tldCBlbmQ9InciPz7Q2vKCAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH5gQDDxses5nq1QAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAAxSURBVAjXY2RAAv/f5HFCmf8YkQT/w9iMIpMYGbEJMqCD/2/y/iMrwi2IbhwDAwMDAKgAHBzXyKd/AAAAAElFTkSuQmCC""")

def main(config):
    rep = http.get(url)
    if rep.status_code != 200:
        fail("Request failed with status %d", rep.status_code)

    station_no = int(config.get("Station", 1))

    all = rep.json()["features"]

    name = all[(station_no)]["properties"]["name"]

    bikes = rep.json()["features"][station_no]["properties"]["classicBikesAvailable"]
    ebikes = rep.json()["features"][station_no]["properties"]["electricBikesAvailable"]
    reward = rep.json()["features"][station_no]["properties"]["rewardBikesAvailable"]
    if (reward > 0):
        reward = "+"
    else:
        reward = "-"

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(child = render.Text(name), width = 64),
                render.Row(
                    expanded = False,
                    children = [
                        render.Column(
                            expanded = True,
                            children = [
                                render.Image(src = bike),
                            ],
                        ),
                        render.Row(
                            cross_align = "start",
                            children = [
                                render.Column(
                                    cross_align = "end",
                                    children = [
                                        render.Text(" " + str(int(bikes))),
                                        render.Text(" " + str(int(ebikes))),
                                    ],
                                ),
                                render.Column(
                                    cross_align = "Start",
                                    children = [
                                        render.Text(" Bikes"),
                                        render.Row(
                                            children = [
                                                render.Image(src = lightning),
                                                render.Text("Bikes"),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    rep = http.get(url)
    if rep.status_code != 200:
        fail("Request failed with status %d", rep.status_code)

    all = rep.json()["features"]

    tmp = []
    tmp2 = []

    no_stations = len(all) - 1

    i = 0
    for _ in range(0, no_stations):
        tmp.append(all[i]["properties"]["name"])
        tmp2.append(str(i))
        i = i + 1

    tmp, tmp2 = zip(*sorted(zip(tmp, tmp2)))

    options = []
    for idx, i in enumerate(tmp):
        options.append(
            schema.Option(display = i, value = tmp2[idx]),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "Station",
                name = "Station Name",
                desc = "The desired station to display",
                icon = "brush",
                default = options[0].value,
                options = options,
            ),
        ],
    )
