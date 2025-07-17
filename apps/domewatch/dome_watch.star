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
load("render.star", "render")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"
DOME_WATCH_API_URL = "https://api3.domewatch.us"
API_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRpZEJ5dCIsImlhdCI6MTUxNjIzOTAyMn0.uXwcFp_oWP5bGXEJLJN8texjF9NYjGd_9wDMRIP7Aug"

# Mock mode configuration
MOCK_MODE = False
MOCK_TIMER_VALUE = "0:00"  # Test values: "15:00", "2:30", "0:00", "-1:45", "-5:00"

def main(config):
    """
    Main entry point for the applet.
    """
    print("Running applet")
    floor = getFloorActivityFromAPI()
    return getRoot(config, floor)

def getRoot(config, floor):
    """
    Determines which screen to display based on the floor status.
    """

    # Use .get() for safety in case the API response is malformed
    if floor.get("now", {}).get("value") == "voting":
        return renderVotingRoot(config, floor)
    else:
        return renderNonVotingRoot(floor)

def renderVotingRoot(config, floor):
    """
    Renders the main screen for when a vote is active.
    This version includes a continuously scrolling marquee.
    """
    timezone = config.get("timezone") or DEFAULT_TIMEZONE
    now = time.now().in_location(timezone)

    # --- NEW ---
    # Get the original question text.
    question_text = floor.get("roll_call", {}).get("question", "Loading...")

    # Repeat the text 10 times to create a very long, continuous scroll.
    # This will feel like an endless loop to the user.
    scroll_text = (question_text + " ") * 10

    return render.Root(
        delay = 125,
        show_full_animation = True,
        child = render.Column(
            main_align = "space_around",
            cross_align = "space_around",
            children = [
                render.Marquee(
                    width = 64,
                    height = 20,
                    child = render.Text(
                        # Use the new, long, repeating text here
                        content = scroll_text,
                        font = "CG-pixel-4x5-mono",
                    ),
                ),
                # The rest of the voting grid and timer remains exactly the same...
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Column(
                            main_align = "space_around",
                            cross_align = "space_around",
                            children = [
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "D", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "R", font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "Y", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("yeas", 0)), font = "CG-pixel-4x5-mono", color = "#00FF00")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("yeas", 0)), font = "CG-pixel-4x5-mono", color = "#00FF00")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "N", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("nays", 0)), font = "CG-pixel-4x5-mono", color = "#FF0000")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("nays", 0)), font = "CG-pixel-4x5-mono", color = "#FF0000")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "P", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("present", 0)), font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("present", 0)), font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "NV", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("not_voting", 0)), font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("not_voting", 0)), font = "CG-pixel-4x5-mono")),
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

def renderVotingTimer(now, floor):
    """
    Timer function that formats overtime to include hours (H:MM:SS)
    after one hour has passed.
    """

    # First check if we have a valid "value" field
    timer_value = floor.get("timer", {}).get("value", "")

    if timer_value and timer_value != "0:00":
        is_negative = timer_value.startswith("-")
        clean_value = timer_value.lstrip("-")

        if ":" in clean_value:
            parts = clean_value.split(":")
            if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
                minutes = int(parts[0])
                seconds = int(parts[1])
                total_seconds = minutes * 60 + seconds

                if is_negative:
                    # Already in overtime - generate count-up from this point
                    frames = []
                    for i in range(total_seconds, total_seconds + 301):
                        # --- MODIFICATION FOR H:MM:SS FORMAT ---
                        if i < 3600:
                            # Less than 1 hour: -MM:SS
                            min = i // 60
                            sec = i % 60
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(min) + ":" + sec_str
                        else:
                            # 1+ hour: -H:MM:SS
                            hr = i // 3600
                            rem_sec = i % 3600
                            min = rem_sec // 60
                            sec = rem_sec % 60
                            min_str = str(min)
                            if min < 10:
                                min_str = "0" + min_str
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(hr) + ":" + min_str + ":" + sec_str

                        # --- END MODIFICATION ---

                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FF0000"))
                    return render.Animation(children = frames)
                else:
                    # Counting down - generate countdown to 0:00 then overtime
                    frames = []

                    # Countdown to 0:00
                    for i in range(total_seconds, -1, -1):
                        min = i // 60
                        sec = i % 60
                        sec_str = str(sec)
                        if sec < 10:
                            sec_str = "0" + sec_str
                        content_str = str(min) + ":" + sec_str
                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FFFFFF"))

                    # Continue into overtime
                    for i in range(1, 301):
                        # --- MODIFICATION FOR H:MM:SS FORMAT ---
                        if i < 3600:
                            # Less than 1 hour: -MM:SS
                            min = i // 60
                            sec = i % 60
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(min) + ":" + sec_str
                        else:
                            # 1+ hour: -H:MM:SS (unlikely to be hit in this 5-min animation, but good practice)
                            hr = i // 3600
                            rem_sec = i % 3600
                            min = rem_sec // 60
                            sec = rem_sec % 60
                            min_str = str(min)
                            if min < 10:
                                min_str = "0" + min_str
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(hr) + ":" + min_str + ":" + sec_str

                        # --- END MODIFICATION ---

                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FF0000"))
                    return render.Animation(children = frames)

    # If value is "0:00" or unavailable, use timestamp-based calculation
    timestamp = floor.get("timer", {}).get("timestamp")
    if not timestamp:
        return render.Text("ERR: NO TIME")

    voting_ends = time.parse_time(timestamp)
    duration = now - voting_ends
    seconds_elapsed = int(duration.seconds)

    # Generate overtime animation from current point
    frames = []
    for i in range(seconds_elapsed, seconds_elapsed + 301):
        # --- MODIFICATION FOR H:MM:SS FORMAT ---
        if i < 3600:
            # Less than 1 hour: -MM:SS
            min = i // 60
            sec = i % 60
            sec_str = str(sec)
            if sec < 10:
                sec_str = "0" + sec_str
            content_str = "-" + str(min) + ":" + sec_str
        else:
            # 1+ hour: -H:MM:SS
            hr = i // 3600
            rem_sec = i % 3600
            min = rem_sec // 60
            sec = rem_sec % 60
            min_str = str(min)
            if min < 10:
                min_str = "0" + min_str
            sec_str = str(sec)
            if sec < 10:
                sec_str = "0" + sec_str
            content_str = "-" + str(hr) + ":" + min_str + ":" + sec_str

        # --- END MODIFICATION ---

        for _ in range(8):
            frames.append(render.Text(content = content_str, color = "#FF0000"))

    return render.Animation(children = frames)

def renderNonVotingRoot(floor):
    """
    Renders the screen for when there is no active vote.
    """
    return render.Root(
        delay = 300,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            children = getNonVotingChildren(floor),
        ),
    )

def getNonVotingChildren(floor):
    """
    Builds the widgets for the non-voting screen.
    """
    children = [
        render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        # NOTE: You will need to add your getStatusIcon function back
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
                            content = floor.get("now", {}).get("text", "No activity"),
                        ),
                    ],
                ),
            ],
        ),
    ]

    if "timeline" in floor and floor["timeline"]:
        children.append(getNonVotingMarquee(floor))
    return children

def getNonVotingMarquee(floor):
    """
    Builds the vertical marquee for the non-voting screen timeline.
    """
    marqueeText = []

    # THE CORRECTED LINE: Use type() to check if the value is a dictionary.
    if type(floor.get("timeline")) == "dict":
        for key in floor["timeline"]:
            marqueeText.append(floor["timeline"][key].get("text", ""))

    full_text = " • ".join(marqueeText)

    return render.Marquee(
        child = render.WrappedText(
            content = full_text,
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

def getStatusIcon(floor):
    if floor["now"]["value"] == "voting":
        return base64.decode("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")

    elif floor["now"]["value"] != "adjourned":
        return base64.decode("iVBORw0KGgoAAAANSUhEUgAAAGIAAACACAYAAADwKbyHAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAADdNJREFUeJztnXuQW1d9x7/fc6WrXa3Xu+tXbBM7gcQJeQy0E5OAY21kr2JPUko7Aw7Tx0xcSluGMG1D05mmrzgUSluGIQMtdID0j8yUAqY4LRlCkpW1u3aMaZ0WWtwmkCHYjvHba3ufutI93/6xazu2tesr7ZV0tb2fGf2h+/ie39VX93XO75xDtCiTQ7nNBvYPBd4FAAT2Wou/acvmX2h2bLXAZgdQC8WhvkcBfAJXxi9Qj6YyO/+6CWHNiZYzYmJw40ZD9mPm2GXJje2Z/oEGhjVnTLMDqBZDPozZ/0A0Vh9tVDxh0XJGELgzwEbvaEAoodJyRgjoCLBZZ90DCZmWM2K+EhsREWIjIkJsRESIjYgIsRERITYiIsRGRITYiIgQGxERYiMiwnw1glJrVfG3jBESODnY9xCA9gCbp71dfd8eL2SvrXdcYdES/xrtvrvT89u+BuK+Knc9a8lfboVGosgboUI2UXKc5wRsrFFijLR3u5nCD0INLGQif2nyTOKROZgAAB2S+Sft3+KGFlQdiLQR2nvfQlB/HILULaXTw1tD0KkbkTaiVCq+FyG1tkn4QBg69SLSRkjsDVFtrQrZBeHphUukjSC0KkQ5p5hwVoaoFyqRNkLENWHqOVZLwtQLk0gbATHUFzKfpidMvTBJNDuAmZjYnVsNq+7prwcA7gfwP6Rek+VR4+C45E/AOlZAmcZ36Zu0dbRclisNdZ1gbgN0C4CpS5x0Y7OO52pE1ghKbSQf9ImB9vX9B+eiNVrILk+axDrAnwwrvph5SuSrOC5HAicGsm9yTKKTDjuspi5fBv6wyskxP1UeSa/bebjZcVZL5I0oFjbdLqec41Q/iJunP+mr7DYK8BVALwvaC6MX2tYXXql/tLUTSSO8oY13WvIDFN4DYEVIsgcpPC3wy6l7+v87JM3QiIwR2ndHsjTe9aCI34N4e31L4/cAPeFmMl8nt9n6lhWMphshbTOl3UO/JvExADc0uPgfiPjTtkz+mQaXewVNNWJicNObHeM/KWFDM+MA+G0/YX+7mTf5pr1ZTw72PWTo/7D5JgCA7nfK/K/iYO6BZkXQ8DNC+7e43snTXwCjWS1N4bPJ3szDjb53NNQIFbLdRcc8Q/DuRpZbA0+7vv8r3DDQsDfxhhmhF3JdXkrPI0gfuEjA512//EuNMqMh9wgVsgs8V99By5gAANrkOc527bsj2YjS6m6EBHoJ8ySId9a7rDrw7uJY9xONKKjuRnhDuccgNu1pZK6Q+LA3lPutupdTT/GJXbmskfKIegPU1SnCd9amNjz/w3oVULcfSPt+MW2EL9WzjAaSguM/Vc/7Rd1+pNL4xCeA6LaI1cDPexNddRtaoi6XpsnBe9eQdj+AhjxxNJDRkocbF+Tyx8IWrssZQeN/HPPPBABY4Lr6k3oIh35GFIf63gbg+/XQjgieNVwz13b0ywn9jBDxu5i/JgCAa3x8OGzRUH8w7Vrf4yn1Oq7elNnicNhNt1/Ltd8aD0sx1DOiqLZfx7w3AQDUUxob3xKmYriXJirU4KKMiFCPNbRL02ghuzzpOK8DcMLSjDgll8VrmNk9HIZYaGeEm0jcj/8/JgBA0rOpTWGJhWaEpExYWq0CDUI75hDvEVwfnlZrIIVnRCj3CO3ZvMgrl0+FodViWNdMdnP9iyNzFQrljCh75ZvD0GlBTMmm1oQiFIaIiJvC0GlFRITyJwzLiLeEodOSiKFU9YfSUYXEYikMJZwDMApgBOAooWFNZXaXAEDShWd2Q45LKFYSEXShixbJTlw4TqUFdBLowcVPkAF9Z4RCKP3yQjFi6sCvvO9TOCbiMITDIo5RPCbakxRPiDxp6B8tl3WqvZwY4b39Z8OIpVq0f4s7duR0T9Jxegz9Hp+2hzA9ApYYg1USVwpaReBNAFYCSF2yP7EojDjCMULm+xQOkfZVwvmxTx1KjSQP8/5nK/5jowRv2+4BODb9mRVpm5ncM7QKZdzgGHOjpBsFnqh/lDENIzLtBipkE0iUOyeNu9CUTZrGT1s4PYBtJ9AGALB0aXjJNd3KpgHA0FxSJS1pHFQRAGRVhHHGDfxhWWfcJux4m/XOoX1ilGtfKjXoEGelrkaMvLhpWUpaLWuvJblMFssILZXREoJLJVwDYMn0p1mjx5QAnARwktBxwRyndELESUInpu5tOOz59uCCDQNH6xXEnI2YHLx3jTF6l6TrBKwmuBq0qyFeh2CjjbUSkwAOkDhop7qCHSB5wEJ72zL5H81FeE5GFIdynwL0B3PVmQdIxBdTRxY9xAe2+7UI1PzUVBzM/RGgR2rdf55BCr9TXHEaAD5Uk0AtO6mQXeI5zmsA6jnszlGABVHjnKrlrLUa5RURuykuBJDDG1726oCFsW9LrS/sr3bHmqo4Ssb5Bcxugg/wVQATtehD2OG67s2p3v5fbcvkP+geXXQrgI9VrUNtc48uuq0tk/9gqrf/gZKnWwQM1RQTMDF9TLNdegx8p6Ym1JqMmKWST4Q+4/r+klRv/xp31O0B9fEq5Y+6KXcr3/nsufML+MB2383ktwkaDCpCopDK7Hz8jdfsBbn8sbLvvx/A6Spj+gt31O1J9favcVlcSvAJABUrdWhU01Wixko/VnzUpPA5t3fnR7lh4AwA8P5ni6nMzj8D8I0qxAfeaMIFbUIEnwsqIqjittOPoP9aRTxfS/Xm//x8LQEzu4fd3v6HCf5dxXLFmmrdwsziUDKZeHyGdf9chc6hmVaQDJxzSuD4LKuDV0uI36y0OOlpG2Y4K2ohTCMOct1zFU95I1WTnhjawYVRhpEq/jGYy58CEFraZZhGjIWo1SqEdszzoRPJvCA2IiLERkSE2IiIEBsREWIjIkJsRESIjYgIsRERITYiIjRkSGo/gWMo4/MER8Cp7ApanoFhSbAjkhkHUTS+zpZd/WwmneRI8h/RObIjUKGLVsxY/eAn9NmEx29Yh10QUqRNE6YTsq6ILogpiGlBnb4TvKJxLtTUQlca6MuIeIslTxqDU7ZUPplqbz9eqfp6PqO99y0sTkwsM8nEEmux2EhLKPwkmc3vanZsMTXS9OwLaZvB7v6ucXW0OfTbjUUXjO9aOBfmFqLUDepirJaGhl0V9azOwujiwIiiRJ45/9XAH4F1PGtw1pczkebYJNbnzjZ7IN5wegwVsguKwHLHmGWWZimJxdaqh2APjboF9UCme7rhvhvCQpBpQG/I1G46ZYAjkMZBnANwBuAwaM8QHBY0LMszxnBYwikje8K39ngKOMoNA6NzLXxWI/T1Lc7EtaeWJ8u63sKsErjKwK6SeD2ApSBWAFiG+ZdIVi0TAI5DOALgBKmfWphDhA4Z2EOlBH/a/vrio7PlPFF7Ni8qWf8mWPtWgWsArBZwPadmIVmJ+TnKTDMoAfiZOJUhCOAgoR/DmJeTxvkRi0N9jWiajLkK8QtdNFBUbpQ1wlcBfQWUlbCB4D3NjqhG2IwzQoQ+B2NvdzN5Q4s7AeypXgU73HT721O9+cdSmZ2Pt/XuzEJ8tHoZvUjatanePCHeSuLTABr+KFvtPWKS4N+LdogyywV9BMCt1RQo4ZG2e/KfvmTZc5s6vHb/PxA8v/WUy+KaywckkUBvV+7fAd0RSIV62W3vuOPycZcmB/seIvG3AWM5z3+C+qTACQPkJHwIl/W3m41qzohxGm5we/sfTmV27nB7+7/gps/8XJW5pK+lejOfuXwhNz8/BuofAqsIeyqNCkNCpAYCy1g8WWnwq1Rv/vMAfhI4HvAlN33mrlRm5/a2TP4ZN5P/fWOxAVXk/gY3gvpLd33/3ksWrX2pRPEjwQPGv834BisGnoxJwJEZ12nWDL/Lt67YuYSEQO2rQuevLu8Clszmvwvgk0EVghtRTvxLpcWuLf9vUAkRM76BSrbxVQxmljxVy+Bvy2LlNHzx6cChBN3QbXcqpxdms5GYLKmZCCxXWu6mkgeCasTvEdFAsRERITYiIsRGRITYiIgQGxERYiMiQmxERIiNiAixEREhNiIixEZEhMgYQcPAA7xfZZiFwKNWUsHLrDdzN2L7/sBJahSWz7jSmtsClyneJW2rGDuBdVXovHWWtSsC6xg750S94EZ4lZv9vGuGqxm+524VsleMk6q99y0EVc00lDd4u3ZdMftVcbDv/QJygVWo39Ced12RHDfy4qZlYBWGYoYBiGf4zSoR2IgiS2+vtJxGvxlUA0B3yTFfHRvafOHfNj64aVWx5D0DYHUVOgDwseJQ37e8oY1bi0N975vc1fdlEF+pUuMmr5zeMVrIXjhTx3bfuzJl/a8CqJhbWwnayrOrFDX5jsAagZMHhH1ucryX6757oR3WG9q4VeCXUH3+6ijAPdO5r3ei+ROAlAV9jzBjgNah+gHBRHKrm+l/6sKCF3JdXpvdDfH2QPtXmcVxENRTkjkH6N0EeqsMeL7zHUl5GiyG+CCC32eqNiKmPsQtdFEhNiIixEZEhFZIQi4CrDAVpWaa/60b4GUvWGpDxDvTJABYgGcpeSLGQHmQGQMAUucg+BJK4HTClTQioAygTPD8JEejMLYkC98Ycw4AZDUGIw8yVsRZAHB8jcmxHqxjrZlaVi6XxzsS5anpDY6sOFfrSMK1oEK2G4kyAWCinOgwiYQLACybNBOlFABQaPPpTJk43RV4enkHaFx7cVkC1nRObTY1tuzFSUSUJpCygEuwY/re3AUgCXABoAX/B9QrGz5D3ZPCAAAAAElFTkSuQmCC")

    else:
        return base64.decode("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")

def getFloorStatusFont(floor):
    """
    Returns a smaller font for the "adjourned" status to ensure it fits.
    """
    if floor.get("now", {}).get("value") == "adjourned":
        return "tom-thumb"
    else:
        return "5x8"

def getFloorActivityFromAPI():
    """
    Fetches floor activity from the Dome Watch API, with caching.
    """

    # Return mock data if in mock mode
    if MOCK_MODE:
        print("Using mock data with timer: " + MOCK_TIMER_VALUE)
        return {
            "now": {"text": "Voting", "value": "voting"},
            "roll_call": {
                "bill": {"id": "566", "number": "566"},
                "number": "187",
                "question": "H RES 566 - MOCK TEST - On Ordering the Previous Question (Timer: " + MOCK_TIMER_VALUE + ")",
            },
            "timeline": {"next_votes": {"text": "Next votes: Later this afternoon"}},
            "timer": {
                "seconds_remaining": 1 if not MOCK_TIMER_VALUE.startswith("-") else 0,
                "timestamp": "2025-07-04T16:15:29.017Z",
                "value": MOCK_TIMER_VALUE,
            },
            "votes": {
                "counts": {
                    "blue": {"nays": "82", "not_voting": "130", "present": "", "yeas": ""},
                    "red": {"nays": "", "not_voting": "193", "present": "", "yeas": "27"},
                    "totals": {"nays": "82", "not_voting": "323", "present": "", "yeas": "27"},
                    "white": {"nays": "", "not_voting": "", "present": "", "yeas": ""},
                },
                "roll_call": {
                    "bill": {"id": "566", "number": "566"},
                    "number": "187",
                    "question": "H RES 566 - MOCK TEST - Timer: " + MOCK_TIMER_VALUE,
                },
                "timer": {
                    "seconds_remaining": 1 if not MOCK_TIMER_VALUE.startswith("-") else 0,
                    "timestamp": "2025-07-02T13:33:39.949Z",
                    "value": MOCK_TIMER_VALUE,
                },
            },
        }
    floor_cached = cache.get("floor")
    if floor_cached != None:
        print("Using cached floor activity")
        return json.decode(floor_cached)

    print("Getting floor activity from API")
    response = http.get(DOME_WATCH_API_URL + "/floor", headers = {
        "Authorization": "Bearer " + API_TOKEN,
    })

    if response.status_code != 200:
        fail("DomeWatch API error: %d %s" % (response.status_code, response.body()))

    floor = response.json()

    if floor.get("now", {}).get("value") == "voting":
        ttl = 1
    else:
        ttl = 20

    cache.set("floor", json.encode(floor), ttl_seconds = ttl)
    return floor
