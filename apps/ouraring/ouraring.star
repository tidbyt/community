"""
Applet: Oura Ring
Summary: View your Oura Ring scores
Description: Displays the three scores from your Oura Ring along with a historical chart over the past seven days.
Author: Aiden Vigue
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ACTIVITY_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAICAYAAADaxo44AAAACXBIWXMAAAsTAAALEwEAmpwYAAAGeWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuZWRhMmIzZmFjLCAyMDIxLzExLzE3LTE3OjIzOjE5ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjMuMSAoTWFjaW50b3NoKSIgeG1wOkNyZWF0ZURhdGU9IjIwMjItMDItMjBUMTc6NDU6MjRaIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMi0wMy0xMlQxMjozOFoiIHhtcDpNZXRhZGF0YURhdGU9IjIwMjItMDMtMTJUMTI6MzhaIiBkYzpmb3JtYXQ9ImltYWdlL3BuZyIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpkZjU1OTY3YS04NTUwLTQ4OTAtYjgyYi1kMzMxZmY1NjkzMWUiIHhtcE1NOkRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDpmZTgzYjE5Yy1hMDdhLWIzNDctODhiMS0wZWFkYWI4YjhiMjUiIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDowZGZjMTU2Yy1mMTlkLTQ5NjItOGFjZS04ZTExYzc3MTRlMmEiPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjBkZmMxNTZjLWYxOWQtNDk2Mi04YWNlLThlMTFjNzcxNGUyYSIgc3RFdnQ6d2hlbj0iMjAyMi0wMi0yMFQxNzo0NToyNFoiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMy4xIChNYWNpbnRvc2gpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDphYzYyYzg5OS1hY2RjLTRmMmMtOGJkNy02OWFmODBhZTJkNzUiIHN0RXZ0OndoZW49IjIwMjItMDMtMTJUMTI6MTc6MTFaIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjMuMSAoTWFjaW50b3NoKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGY1NTk2N2EtODU1MC00ODkwLWI4MmItZDMzMWZmNTY5MzFlIiBzdEV2dDp3aGVuPSIyMDIyLTAzLTEyVDEyOjM4WiIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIzLjEgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+bq5RSQAAAF1JREFUCJltjLEVRAAUBGe9d+jENacaketGDwJKkRjBR3Qbzu5OVP7mKVTOGQECNO9g6cWg4lOoEOH7gaVTJSr+mlIMLQayHfVIyZCCr4pVMGQvmJVSJcERvd+ZyAVgJzcslQ/SGQAAAABJRU5ErkJggg==
""")

READINESS_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAYAAAAHBAMAAADZviHeAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAD1BMVEUAAAD//wH+6zr8/J3///+gc84KAAAAAWJLR0QEj2jZUQAAAAd0SU1FB+YMDhYXH7nGnqwAAAAXSURBVAjXY2BgFGBgEGQAU0KChgxIfAAKCwC7LjfA3wAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMi0xMi0xNFQyMjoyMzozMSswMDowMHoZanIAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjItMTItMTRUMjI6MjM6MzErMDA6MDALRNLOAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDIyLTEyLTE0VDIyOjIzOjMxKzAwOjAwXFHzEQAAACd0RVh0d2VicDptdXgtYmxlbmQAQXRvcEJhY2tncm91bmRBbHBoYUJsZW5ks7p01QAAAABJRU5ErkJggg==""")

SLEEP_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAHCAYAAAArkDztAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABqADAAQAAAABAAAABwAAAABW8BQVAAAAO0lEQVQIHWNgAIKyi7//g2gUABKUWfvtP05JmGqYAkaYAIgGCS6785shSoUVIQxTCaPBMiAOUfaAVAMAVYEsSbx+oJAAAAAASUVORK5CYII=
""")

def readinessIcon(score, dim):
    return render.Padding(pad = (0, 0, 0, 0), child = render.Row(children = [render.Padding(pad = (0, 1, 0, 0), child = render.Image(src = READINESS_ICON)), render.Padding(pad = (2, 2, 0, 0), child = render.Text(str(score), font = "tom-thumb", color = "#FFF" if not dim else "#444"))]))

def activityIcon(score, dim):
    return render.Padding(pad = (0, 0, 0, 0), child = render.Row(children = [render.Image(src = ACTIVITY_ICON), render.Padding(pad = (2, 2, 0, 0), child = render.Text(str(score), font = "tom-thumb", color = "#FFF" if not dim else "#444"))]))

def sleepIcon(score, dim):
    return render.Padding(pad = (0, 0, 0, 0), child = render.Row(children = [render.Padding(pad = (0, 1, 0, 0), child = render.Image(src = SLEEP_ICON)), render.Padding(pad = (2, 2, 0, 0), child = render.Text(str(score), font = "tom-thumb", color = "#FFF" if not dim else "#444"))]))

def activityView(readiness_scores, activity_scores, sleep_scores):
    avg = cal_average(activity_scores)
    points = []
    for index, score in enumerate(activity_scores):
        points.append((index, score - avg))

    return render.Column(
        children = [render.Row(children = [readinessIcon(readiness_scores[-1], True), activityIcon(activity_scores[-1], False), sleepIcon(sleep_scores[-1], True)], main_align = "space_evenly", expanded = True), render.Plot(
            data = points,
            width = 64,
            height = 19,
            color = "#0f0",
            color_inverted = "#F33",
            fill = True,
        )],
        main_align = "space_between",
        expanded = True,
    )

def readinessView(readiness_scores, activity_scores, sleep_scores):
    avg = cal_average(readiness_scores)
    points = []
    for index, score in enumerate(readiness_scores):
        points.append((index, score - avg))

    return render.Column(
        children = [render.Row(children = [readinessIcon(readiness_scores[-1], False), activityIcon(activity_scores[-1], True), sleepIcon(sleep_scores[-1], True)], main_align = "space_evenly", expanded = True), render.Plot(
            data = points,
            width = 64,
            height = 19,
            color = "#0f0",
            color_inverted = "#F33",
            fill = True,
        )],
        main_align = "space_between",
        expanded = True,
    )

def sleepView(readiness_scores, activity_scores, sleep_scores):
    avg = cal_average(sleep_scores)
    points = []
    for index, score in enumerate(sleep_scores):
        points.append((index, score - avg))

    return render.Column(
        children = [render.Row(children = [readinessIcon(readiness_scores[-1], True), activityIcon(activity_scores[-1], True), sleepIcon(sleep_scores[-1], False)], main_align = "space_evenly", expanded = True), render.Plot(
            data = points,
            width = 64,
            height = 19,
            color = "#0f0",
            color_inverted = "#F33",
            fill = True,
        )],
        main_align = "space_between",
        expanded = True,
    )

def errorView(message):
    return render.Root(child = render.WrappedText(
        content = message,
        width = 64,
        color = "#fff",
    ))

def main(config):
    apikey = config.get("apikey", "notset")

    sleep_scores = [78, 86, 67, 92, 65, 82, 85]
    activity_scores = [76, 95, 71, 80, 66, 91, 83]
    readiness_scores = [62, 73, 68, 70, 88, 79, 61]

    if apikey != "notset":
        days = config.get("days", "7")

        now = time.now()
        from_date = (now - time.parse_duration(str(int(days) * 24) + "h")).format("2006-01-02")
        to_date = now.format("2006-01-02")

        sleep_data = None
        sleep_dto = cache.get("oura_sleep_data_" + apikey)
        if sleep_dto != None:
            sleep_data = json.decode(sleep_dto)
        else:
            rep = http.get("https://api.ouraring.com/v2/usercollection/daily_sleep?start_date=" + from_date + "&" + "end_date=" + to_date, headers = {"Authorization": "Bearer " + apikey})
            if rep.status_code != 200:
                return errorView("API error")
            sleep_data = rep.json()
            cache.set("oura_sleep_data_" + apikey, json.encode(sleep_data), ttl_seconds = 1800)

        activity_data = None
        activity_dto = cache.get("oura_activity_data_" + apikey)
        if activity_dto != None:
            activity_data = json.decode(activity_dto)
        else:
            rep = http.get("https://api.ouraring.com/v2/usercollection/daily_activity?start_date=" + from_date + "&" + "end_date=" + to_date, headers = {"Authorization": "Bearer " + apikey})
            if rep.status_code != 200:
                return errorView("API error")
            activity_data = rep.json()
            cache.set("oura_activity_data_" + apikey, json.encode(activity_data), ttl_seconds = 1800)

        readiness_data = None
        readiness_dto = cache.get("oura_readiness_data_" + apikey)
        if readiness_dto != None:
            readiness_data = json.decode(readiness_dto)
        else:
            rep = http.get("https://api.ouraring.com/v2/usercollection/daily_readiness?start_date=" + from_date + "&" + "end_date=" + to_date, headers = {"Authorization": "Bearer " + apikey})
            if rep.status_code != 200:
                return errorView("API error")
            readiness_data = rep.json()
            cache.set("oura_readiness_data_" + apikey, json.encode(readiness_data), ttl_seconds = 1800)

        #Populate array of last 7 scores.
        for day in sleep_data["data"]:
            sleep_scores.append(int(day["score"]))

        for day in activity_data["data"]:
            activity_scores.append(int(day["score"]))

        for day in readiness_data["data"]:
            readiness_scores.append(int(day["score"]))

    return render.Root(
        delay = 2000,
        child = render.Animation(
            children = [
                readinessView(readiness_scores, activity_scores, sleep_scores),
                activityView(readiness_scores, activity_scores, sleep_scores),
                sleepView(readiness_scores, activity_scores, sleep_scores),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apikey",
                name = "Oura PAT",
                desc = "Oura API Key. Get yours at cloud.ouraring.com",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "days",
                name = "Graph Lookback",
                desc = "Number of previous days to graph",
                icon = "calendar",
                default = "7",
            ),
        ],
    )

def cal_average(num):
    sum_num = 0
    for t in num:
        sum_num = sum_num + t

    avg = sum_num / len(num)
    return avg
