"""
Applet: NYC ASP Status
Summary: NYC alt side parking status
Description: Displays whether New York City alternate side parking (street cleaning) rules are in effect today (or next day after 3PM).
Author: Adam Wojciechowski
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

months = ["", "Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."]
days = ["", "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "11th", "12th", "13th", "14th", "15th", "16th", "17th", "18th", "19th", "20th", "21st", "22nd", "23rd", "24th", "25th", "26th", "27th", "28th", "29th", "30th", "31st"]

URL = "https://api.nyc.gov/public/api/GetCalendar?"
API_KEY = "AV6+xWcE+YMm4G7gYV3hsgC6XO9XBxoNBMw1B4gG84iLo24VAPx3tG0tmCSyzMglcBeNT5LFENVoEmi5foVQ6S85R4uYaVTr/Cl8FTs98wIoh9DVpW7ixeguWF/T9hoLgNrhEp201IbPBYkeOWUBV9Lofm8m2k6KTVvQrZAKM49tKUP3iao="

TTL_SECONDS = 300

DEFAULT_SHOW_APP = False

RED_IMG = "PD94bWwgdmVyc2lvbj0iMS4wIj8+Cjxzdmcgd2lkdGg9IjEyMCIgaGVpZ2h0PSIxMjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6c3ZnPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAwIDAgMTIwIDEyMCIgdmVyc2lvbj0iMS4xIiB4bWw6c3BhY2U9InByZXNlcnZlIj4KIDxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI+LnN0MHtmaWxsOiNGRkZGRkY7fQoJLnN0MXtmaWxsOiNDMjEzMDA7fQoJLnN0MntmaWxsOm5vbmU7c3Ryb2tlOiNDMjEzMDA7c3Ryb2tlLXdpZHRoOjY7c3Ryb2tlLWxpbmVjYXA6cm91bmQ7c3Ryb2tlLW1pdGVybGltaXQ6MTA7fTwvc3R5bGU+CiA8ZyBjbGFzcz0ibGF5ZXIiPgogIDx0aXRsZT5MYXllciAxPC90aXRsZT4KICA8Y2lyY2xlIGNsYXNzPSJzdDAiIGN4PSI2MCIgY3k9IjYwIiBpZD0ic3ZnXzEiIG9wYWNpdHk9IjAiIHI9IjU0LjUiLz4KICA8ZyBpZD0ic3ZnXzIiPgogICA8ZyBpZD0ic3ZnXzMiPgogICAgPGcgaWQ9InN2Z180Ij4KICAgICA8cGF0aCBjbGFzcz0ic3QxIiBkPSJtNTkuOSwwLjFjLTMzLjEsMCAtNjAsMjYuOSAtNjAsNjBzMjYuOSw2MCA2MCw2MHM2MCwtMjYuOSA2MCwtNjBzLTI2LjksLTYwIC02MCwtNjB6bTAsMTEwYy0yNy42LDAgLTUwLC0yMi40IC01MCwtNTBzMjIuNCwtNTAgNTAsLTUwczUwLDIyLjQgNTAsNTBzLTIyLjQsNTAgLTUwLDUweiIgaWQ9InN2Z181Ii8+CiAgICAgPGcgaWQ9InN2Z182Ij4KICAgICAgPHBhdGggY2xhc3M9InN0MSIgZD0ibTgyLjksNjUuOWMtMy41LDIuOSAtOC42LDQuNCAtMTUuMSw0LjRsLTEyLjUsMGwwLDIxLjZsLTEyLjUsMGwwLC02MC4ybDI1LjgsMGM2LDAgMTAuNywxLjYgMTQuMiw0LjdjMy41LDMuMSA1LjMsNy45IDUuMywxNC40YzAuMSw3LjEgLTEuNywxMi4xIC01LjIsMTUuMXptLTkuNiwtMjEuN2MtMS42LC0xLjMgLTMuOCwtMiAtNi43LC0ybC0xMS4zLDBsMCwxNy43bDExLjMsMGMyLjksMCA1LjEsLTAuNyA2LjcsLTIuMmMxLjYsLTEuNCAyLjQsLTMuNyAyLjQsLTYuOWMwLC0zLjEgLTAuOCwtNS4zIC0yLjQsLTYuNnoiIGlkPSJzdmdfNyIvPgogICAgIDwvZz4KICAgIDwvZz4KICAgPC9nPgogICA8ZyBpZD0ic3ZnXzgiPgogICAgPGxpbmUgY2xhc3M9InN0MiIgaWQ9InN2Z185IiB4MT0iMTYuMyIgeDI9IjgzLjQiIHkxPSIyMy4yIiB5Mj0iODMuMiIvPgogICAgPGcgaWQ9InN2Z18xMCI+CiAgICAgPHBvbHlnb24gY2xhc3M9InN0MSIgaWQ9InN2Z18xMSIgcG9pbnRzPSIxMDAsNzUuNyA3NC45LDk0LjMgNjUuOSw5MS44IDkyLjEsNzIuOSAgICAiLz4KICAgICA8ZyBpZD0ic3ZnXzEyIj4KICAgICAgPHBvbHlnb24gY2xhc3M9InN0MCIgaWQ9InN2Z18xMyIgcG9pbnRzPSI3NC45LDk0LjMgNzQuOSw5OS4yIDY1LjksOTYuNSA2NS45LDkxLjggICAgICIvPgogICAgICA8cG9seWdvbiBjbGFzcz0ic3QwIiBpZD0ic3ZnXzE0IiBwb2ludHM9Ijk5LjcsODEuMyA3NC45LDk5LjIgNzQuOSw5NC4zIDEwMCw3NS43ICAgICAiLz4KICAgICA8L2c+CiAgICA8L2c+CiAgIDwvZz4KICA8L2c+CiA8L2c+Cjwvc3ZnPg=="
GREEN_IMG = "PD94bWwgdmVyc2lvbj0iMS4wIj8+Cjxzdmcgd2lkdGg9IjEyMCIgaGVpZ2h0PSIxMjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6c3ZnPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAwIDAgMTIwIDEyMCIgdmVyc2lvbj0iMS4xIiB4bWw6c3BhY2U9InByZXNlcnZlIj4KIDxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI+LnN0MHtmaWxsOiNGRkZGRkY7fQoJLnN0MXtmaWxsOiMwMEZGMDA7fQoJLnN0MntmaWxsOm5vbmU7c3Ryb2tlOiMwMEZGMDA7c3Ryb2tlLXdpZHRoOjY7c3Ryb2tlLWxpbmVjYXA6cm91bmQ7c3Ryb2tlLW1pdGVybGltaXQ6MTA7fTwvc3R5bGU+CiA8ZyBjbGFzcz0ibGF5ZXIiPgogIDx0aXRsZT5MYXllciAxPC90aXRsZT4KICA8Y2lyY2xlIGNsYXNzPSJzdDAiIGN4PSI2MCIgY3k9IjYwIiBpZD0ic3ZnXzEiIG9wYWNpdHk9IjAiIHI9IjU0LjUiLz4KICA8ZyBpZD0ic3ZnXzIiPgogICA8ZyBpZD0ic3ZnXzMiPgogICAgPGcgaWQ9InN2Z180Ij4KICAgICA8cGF0aCBjbGFzcz0ic3QxIiBkPSJtNTkuOSwwLjFjLTMzLjEsMCAtNjAsMjYuOSAtNjAsNjBzMjYuOSw2MCA2MCw2MHM2MCwtMjYuOSA2MCwtNjBzLTI2LjksLTYwIC02MCwtNjB6bTAsMTEwYy0yNy42LDAgLTUwLC0yMi40IC01MCwtNTBzMjIuNCwtNTAgNTAsLTUwczUwLDIyLjQgNTAsNTBzLTIyLjQsNTAgLTUwLDUweiIgaWQ9InN2Z181Ii8+CiAgICAgPGcgaWQ9InN2Z182Ij4KICAgICAgPHBhdGggY2xhc3M9InN0MSIgZD0ibTgyLjksNjUuOWMtMy41LDIuOSAtOC42LDQuNCAtMTUuMSw0LjRsLTEyLjUsMGwwLDIxLjZsLTEyLjUsMGwwLC02MC4ybDI1LjgsMGM2LDAgMTAuNywxLjYgMTQuMiw0LjdjMy41LDMuMSA1LjMsNy45IDUuMywxNC40YzAuMSw3LjEgLTEuNywxMi4xIC01LjIsMTUuMXptLTkuNiwtMjEuN2MtMS42LC0xLjMgLTMuOCwtMiAtNi43LC0ybC0xMS4zLDBsMCwxNy43bDExLjMsMGMyLjksMCA1LjEsLTAuNyA2LjcsLTIuMmMxLjYsLTEuNCAyLjQsLTMuNyAyLjQsLTYuOWMwLC0zLjEgLTAuOCwtNS4zIC0yLjQsLTYuNnoiIGlkPSJzdmdfNyIvPgogICAgIDwvZz4KICAgIDwvZz4KICAgPC9nPgogICA8ZyBpZD0ic3ZnXzgiPgogICAgPGxpbmUgY2xhc3M9InN0MiIgaWQ9InN2Z185IiB4MT0iMTYuMyIgeDI9IjgzLjQiIHkxPSIyMy4yIiB5Mj0iODMuMiIvPgogICAgPGcgaWQ9InN2Z18xMCI+CiAgICAgPHBvbHlnb24gY2xhc3M9InN0MSIgaWQ9InN2Z18xMSIgcG9pbnRzPSIxMDAsNzUuNyA3NC45LDk0LjMgNjUuOSw5MS44IDkyLjEsNzIuOSAgICAiLz4KICAgICA8ZyBpZD0ic3ZnXzEyIj4KICAgICAgPHBvbHlnb24gY2xhc3M9InN0MCIgaWQ9InN2Z18xMyIgcG9pbnRzPSI3NC45LDk0LjMgNzQuOSw5OS4yIDY1LjksOTYuNSA2NS45LDkxLjggICAgICIgdHJhbnNmb3JtPSJtYXRyaXgoMSAwIDAgMSAwIDApIi8+CiAgICAgIDxwb2x5Z29uIGNsYXNzPSJzdDAiIGlkPSJzdmdfMTQiIHBvaW50cz0iOTkuNyw4MS4zIDc0LjksOTkuMiA3NC45LDk0LjMgMTAwLDc1LjcgICAgICIvPgogICAgIDwvZz4KICAgIDwvZz4KICAgPC9nPgogIDwvZz4KIDwvZz4KPC9zdmc+"

def main(config):
    showApp = config.bool("showOnlySuspended", DEFAULT_SHOW_APP)

    status = get_asp_status(URL + "fromdate=%s&todate=%s" % (display_date()[0].format("2006-01-02"), display_date()[1].format("2006-01-02")), TTL_SECONDS)

    if (status[0] == "IN EFFECT" and showApp == True):
        # Don't display the app in the user's rotation
        return []

    return render.Root(
        render.Box(
            child = render.Row(
                expanded = False,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(
                        src = base64.decode(img_picker(status)),
                        height = 18,
                        width = 18,
                    ),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Marquee(
                                height = 8,
                                width = 45,
                                align = "center",
                                scroll_direction = "horizontal",
                                child = render.WrappedText(status[0]),
                            ),
                            render.WrappedText(display_date()[2]),
                            render.Marquee(
                                height = 8,
                                width = 42,
                                align = "center",
                                scroll_direction = "horizontal",
                                child = render.WrappedText("%s %s %s" % (months[display_date()[0].month], days[display_date()[0].day], status[1])),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_asp_status(url, timeout):
    headers = {"Cache-Control": "no-cache", "Ocp-Apim-Subscription-Key": secret.decrypt(API_KEY) or "demo"}
    if headers["Ocp-Apim-Subscription-Key"] == "demo":
        return ["IN EFFECT", "- DEMO MODE"]
    response = http.get(url = url, headers = headers, ttl_seconds = timeout)
    if response.status_code != 200:
        return ["ERROR", "- Couldn't load ASP status"]
        #fail("status %d from %s: %s" % (response.status_code, url, response.body()))

    asp_status = response.json()["days"][0]["items"][0]["status"]
    if asp_status == "SUSPENDED":
        asp_exception = response.json()["days"][0]["items"][0]["exceptionName"]
        return [asp_status, "- " + asp_exception]
    if asp_status == "NOT IN EFFECT":
        asp_exception = response.json()["days"][0]["items"][0]["details"]
        return [asp_status, ""]
    else:
        return [asp_status, ""]

def display_date():
    nyTime = time.now().in_location("America/New_York")
    if nyTime.hour >= 15:
        newToday = (nyTime + time.parse_duration("24h"))
        newTomorrow = nyTime + time.parse_duration("48h")
        return [newToday, newTomorrow, "TOMORROW"]
    else:
        timeNow = nyTime
        timeTomorrow = (nyTime + time.parse_duration("24h"))
        return [timeNow, timeTomorrow, "TODAY"]

def img_picker(status):
    if status[0] == "SUSPENDED" or status[0] == "NOT IN EFFECT":
        return GREEN_IMG
    else:
        return RED_IMG

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "showOnlySuspended",
                name = "Show Only When Suspended",
                desc = "Show this app only when alternate side parking rules are suspended.",
                icon = "eye",
                default = False,
            ),
        ],
    )
