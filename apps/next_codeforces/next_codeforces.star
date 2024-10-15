"""
Applet: Next Codeforces
Summary: Countdown to Contest
Description: Show the time until the next Codeforces contest.
Author: vzsky
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CF_API = "https://codeforces.com/api/contest.list"
CF_LOGO = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAYAAAD+Bd/7AAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw1AUhU9bpVIqHewg4pChCoIFURHHWoUiVAi1QqsOJi/9gyYNSYqLo+BacPBnserg4qyrg6sgCP6AODs4KbpIifclhRYxXni8j/PuObx3H+BvVplq9iQAVbOMTCop5PKrQvAVIUTgwwTGJGbqc6KYhmd93VMn1V2cZ3n3/Vn9SsFkgE8gTjDdsIg3iGc2LZ3zPnGUlSWF+Jx43KALEj9yXXb5jXPJYT/PjBrZzDxxlFgodbHcxaxsqMTTxDFF1Sjfn3NZ4bzFWa3WWfue/IXhgrayzHVaw0hhEUsQIUBGHRVUYSFOu0aKiQydJz38Q45fJJdMrgoYORZQgwrJ8YP/we/ZmsWpSTcpnAR6X2z7YwQI7gKthm1/H9t26wQIPANXWsdfawKzn6Q3OlrsCIhsAxfXHU3eAy53gMEnXTIkRwrQ8heLwPsZfVMeGLgFQmvu3NrnOH0AsjSr9A1wcAiMlih73ePdfd1z+7enPb8fvOByxFbEuNwAAAAGYktHRAD/AP8A/6C9p5MAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAHdElNRQfoCg8BODVk/ilXAAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAADRJREFUCNdjYEACkhPO/peccPY/shgLAw6wQ0H9PwMDAwPT3+ul//9eL/2PSyETAwFAuQIA1+ANhXuaC5kAAAAASUVORK5CYII=")

CF_RED = "#bc2424"
CF_BLUE = "#1c94cc"
CF_YELLOW = "#fcd474"

DEFAULT_LOCATION = {
    "lat": 13.7563,
    "lng": 100.5018,
    "locality": "Bangkok",
}
DEFAULT_TIMEZONE = "Asia/Bangkok"

def relative_time(start, target):
    relative = abs(int((start - target).seconds))
    MIN = 60
    HOUR = 60 * MIN
    DAY = 24 * HOUR
    if (relative > 40 * HOUR):
        answer = str(relative // DAY) + " days"
    elif (relative > 99 * MIN):
        answer = str(relative // HOUR) + " hours"
    elif (relative > 150):
        answer = str(relative // MIN) + " mins"
    elif (relative > 10):
        answer = str(relative) + " secs"
    else:
        return "NOW!"

    return "in " + answer if start < target else answer + " ago"

def parse_contest(contest, timezone):
    id = int(contest["id"])
    name = contest["name"]
    timestamp = int(contest["startTimeSeconds"])
    contest_time = time.from_timestamp(timestamp)
    str_date = contest_time.in_location(timezone).format("02 Jan")
    str_time = contest_time.in_location(timezone).format("15:04")
    time_until = relative_time(time.now(), contest_time)
    return id, name, str_date, str_time, time_until

def render_countdown(name, date, time, until):
    return render.Box(render.Column(
        cross_align = "center",
        main_align = "space-around",
        children = [
            render.Row(children = [
                render.Box(render.Image(src = CF_LOGO), width = 12, height = 7),
                render.Marquee(
                    render.Text(name, font = "5x8", offset = 1),
                    width = 50,
                ),
            ]),
            render.Text(until, font = "tb-8", color = CF_RED),
            render.Row(children = [
                render.Text(date, color = CF_BLUE),
                render.Text(" - "),
                render.Text(time, color = CF_YELLOW),
            ]),
        ],
    ))

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))

    rep = http.get(CF_API)
    if rep.status_code != 200:
        fail("Codeforces API request failed with status %d", rep.status_code)

    contests = rep.json()["result"]
    live = [contest for contest in contests if contest["phase"] == "BEFORE" and contest["frozen"] == False]
    first = sorted(live, key = lambda contest: contest["startTimeSeconds"])[0]

    _, name, date, time, until = parse_contest(first, timezone)

    return render.Root(
        child = render_countdown(name, date, time, until),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the time",
                icon = "locationDot",
            ),
        ],
    )
