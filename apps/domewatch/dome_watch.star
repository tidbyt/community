"""
Applet: Dome Watch
Summary: US House Floor activity
Description: Show current US House floor activity in real-time, include live vote counts.
Author: Shaun Brown
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"
DOME_WATCH_API_URL = "https://api3.domewatch.us"
API_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRpZEJ5dCIsImlhdCI6MTUxNjIzOTAyMn0.uXwcFp_oWP5bGXEJLJN8texjF9NYjGd_9wDMRIP7Aug"

def main(config):
    print("Running applet")

    # Get floor status from Dome Watch API
    floor = getFloorActivityFromAPI()
    return getRoot(config, floor)

def getRoot(config, floor):
    if floor["now"]["value"] == "voting":
        return renderVotingRoot(config, floor)
    else:
        return renderNonVotingRoot(floor)

def renderNonVotingRoot(floor):
    return render.Root(
        delay = 300,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            children = getNonVotingChildren(floor),
        ),
    )

def getNonVotingChildren(floor):
    children = [
        render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                render.Column(
                    # expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Image(src = getStatusIcon(floor), height = 23),
                    ],
                ),
                render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            align = "center",
                            font = getFloorStatusFont(floor),
                            color = "#FFFFFF",
                            content = floor["now"]["text"],
                        ),
                    ],
                ),
            ],
        ),
    ]

    # Check if floor["timeline"] exists
    if "timeline" in floor:
        # Add nonVotingMarquee to children.
        children.append(getNonVotingMarquee(floor))
    return children

def getNonVotingMarquee(floor):
    return render.Marquee(
        child = render.WrappedText(
            content = getVotingMarqueeText(floor),
            font = "tom-thumb",
            color = "#FFFFFF",
            align = "center",
            width = 64,
        ),
        align = "center",
        scroll_direction = "vertical",
        height = 5,
        width = 64,
        delay = 5,
    )

def getVotingMarqueeText(floor):
    # For each item in floor["timeline"], add to marqueeText with a • separator.
    marqueeText = ""
    for key in floor["timeline"]:
        marqueeText += floor["timeline"][key]["text"] + " • "
    return marqueeText[:-3]

def getStatusIcon(floor):
    if floor["now"]["value"] == "voting":
        return base64.decode("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")

    elif floor["now"]["value"] != "adjourned":
        return base64.decode("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")

    else:
        return base64.decode("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")

# Returns a small font when needed to fit text on the screen.
def getFloorStatusFont(floor):
    if floor["now"]["value"] == "adjourned":
        return "tom-thumb"
    else:
        return "5x8"

def getFloorActivityFromAPI():
    floor_cached = cache.get("floor")
    if floor_cached != None:
        print("Using cached floor activity")

        # De-stringify the floor object.
        floor = json.decode(floor_cached)
    else:
        print("Getting floor activity from API")
        response = http.get(DOME_WATCH_API_URL + "/floor", headers = {
            "Authorization": "Bearer " + API_TOKEN,
        })
        if response.status_code != 200:
            fail("DomeWatch error getting floor activity from API")
        floor = response.json()

        # If floor is voting, set cache to 1 second. Otherwise, set cache to 20 seconds.
        if floor["now"]["value"] == "voting":
            ttl = 1
        else:
            ttl = 20

        cache.set("floor", json.encode(floor), ttl_seconds = ttl)

    return floor

# When voting, we make an api call every second. This function is therefore invoked every second.
def renderVotingTimer(now, floor):
    voting_ends = time.parse_time(floor["timer"]["timestamp"])

    # If the voting end is in the future, calculate the time remaining.
    # Otherwise, calculate time passed.
    # Prepend a negative sign if the voting end is in the past.
    prepend = ""
    color = "#FFFFFF"
    if voting_ends > now:
        dateDiff = voting_ends - now
    else:
        dateDiff = now - voting_ends
        prepend = "-"
        color = "#FF0000"

    # Calculate the days, hours, minutes, and seconds.
    days = math.floor(dateDiff.hours / 24)
    hours = math.floor(dateDiff.hours - days * 24)
    minutes = math.floor(dateDiff.minutes - (days * 24 * 60 + hours * 60))
    seconds = math.floor(dateDiff.seconds - (days * 24 * 60 * 60 + hours * 60 * 60 + minutes * 60))

    # If the seconds are less than 10, add a leading zero.
    if seconds < 10:
        seconds = "0" + str(seconds)

    # Combine the hours and minutes into a string using the format HH:MM.
    formatted_time = prepend + str(minutes) + ":" + str(seconds)

    return render.Text(
        content = formatted_time,
        color = color,
    )

def renderVotingRoot(config, floor):
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    return render.Root(
        # delay = 100, # in milliseconds
        child = render.Column(
            main_align = "space_around",
            cross_align = "space_around",
            children = [
                render.Marquee(
                    width = 64,
                    height = 20,
                    child = render.Text(
                        content = floor["roll_call"]["question"],
                        font = "CG-pixel-4x5-mono",
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Column(
                            main_align = "space_around",
                            cross_align = "space_around",
                            children = [
                                render.Padding(
                                    pad = (0, 1, 0, 1),
                                    child = render.Text(
                                        content = "",
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                                render.Padding(
                                    pad = (0, 1, 0, 1),
                                    child = render.Text(
                                        content = "D",
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                                render.Padding(
                                    pad = (0, 1, 0, 1),
                                    child = render.Text(
                                        content = "R",
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = "Y",
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = str(floor["votes"]["counts"]["blue"]["yeas"]),
                                        font = "CG-pixel-4x5-mono",
                                        color = "#00FF00",
                                    ),
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = str(floor["votes"]["counts"]["red"]["yeas"]),
                                        font = "CG-pixel-4x5-mono",
                                        color = "#00FF00",
                                    ),
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = "N",
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = str(floor["votes"]["counts"]["blue"]["nays"]),
                                        font = "CG-pixel-4x5-mono",
                                        color = "FF0000",
                                    ),
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = str(floor["votes"]["counts"]["red"]["nays"]),
                                        font = "CG-pixel-4x5-mono",
                                        color = "FF0000",
                                    ),
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = "P",
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = str(floor["votes"]["counts"]["blue"]["present"]),
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = str(floor["votes"]["counts"]["red"]["present"]),
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = "NV",
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = str(floor["votes"]["counts"]["blue"]["not_voting"]),
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        content = str(floor["votes"]["counts"]["red"]["not_voting"]),
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Box(
                    child = renderVotingTimer(now, floor),
                ),
            ],
        ),
    )
