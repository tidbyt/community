"""
Applet: Bin Menu
Summary: Display your bin schedule
Description: This app can display your bin schedule and when they need to be put out, just need to add your own dates.
Author: Bin Boy
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("time.star", "time")

# Load Bin images from base64 encoded data
SILVER_BIN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABgAAAAgCAYAAAAIXrg4AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAYoAMABAAAAAEAAAAgAAAAAGG5qPQAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4yODwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KzVJ22wAAAVBJREFUSA3tVcERgyAQ1ExasRptxkpsRscZW7EYkmPYG1g5wOSTR3yEu71jF9aAXfd/Kg70hbor1Lhk8nAhIV3XlYku+TRNF+wNKK8Gb9C1EDLbeZ4MdfM8C+a5H6H6EfmFOQDLskjk3cAOEmukWttNYeUyXR7PrQJB1VfCFn185wccsUXPHAEac7W7mAqIas0WJs/ZxD14ybCK61/nEPiayCJoEhjH0ZpfxasCIMdYZaSGogCTck5c2bQosG1bMonzpGgksUCfu7hAitHgUTg+ZALGAtoUB7AFY1xrifWgWc2tK7fmV3dgTWzFf0NAXn7uD9Cyi+o7EGLcrhLzhbjvu9c5jgN6yb3WbNEwDCDQMUOuNQRFAawe5LJ6weSa5qvaOf0oaiAibJEcNgdLsAomAy4jrOn7xBltyaPhg61d9wKL8x4LdYstiTVU/6e2Ay/IGmWF3aDpxwAAAABJRU5ErkJggg==
""")

BROWN_BIN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABgAAAAgCAYAAAAIXrg4AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAYoAMABAAAAAEAAAAgAAAAAGG5qPQAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4yODwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KzVJ22wAAAWlJREFUSA3tVbFxAjEQ/Pc4oACHHmICl4BdiAlNAZRCAXYIRXxouwSPhwII3YPgNNobaV8n6U1CwAfobu+0K+0jfdfdnooDfaHuCjUumTxcSEjfX5dMNMrX++8RdgaUV4Mz6FoIme3n+MdQt/08COa570L1X+Qj5gBsXhYSeTewg8QaqdZ2U1i5TJfHc6tAUPWVsEUfT/kBR2zRfY4AjbnaVEwFRLVmC5PnbOIevGRYxfWLcwhcTGQRNAm87b6s+VW8KgByjFVGaigKMCnnxJVNiwIfq+dkEudJ0UhigT53cYEUo8GjcHzIBIwFtCkOYAvGuNYS60GzmltXbs2v7sCa2Ipfh4C8/NwfoGUX1XcgxLhdJeYL8Xc29zrDMEAvudeaLXp6fACBjhlyrSEoCmD1IJfVCybXNF/VzulHUQMRYYvksDlYglUwGXAZYU3fJ85oSx4NH2ztmhZYnNNYqFtsSayh+i21HTgBXDxmULC9++QAAAAASUVORK5CYII=
""")

GREEN_BIN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABgAAAAgCAYAAAAIXrg4AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAYoAMABAAAAAEAAAAgAAAAAGG5qPQAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4yODwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KzVJ22wAAAWlJREFUSA3tVTFuAjEQvIsi8YBUoURpoM8vIvGE8Cl68oRIVPcFetKlTKo8IGkMa3lW9pzX9oWGgivw7ux6xp7Dvq67PRUH+kLdFWpcMnm4kJAuv16ZaJR/zN9G2BlQXg3OoGshZLbfww9D3ed6L5jnvgvVf5GPmAOweH+RyLuBHSTWSLW2m8LKZbo8nlsFgqqvhC36eMoPOGKL7nMEaMzVpmIqIKo1W5g8ZxP34CXDKq5fnEPgYiKLoEng+Liz5lfxqgDIMVYZqaEowKScE1c2LQqsvjfJJM6TopHEAn3u4gIpRoNH4fiQCRgLaFMcwBaMca0l1oNmNbeu3Jpf3YE1sRW/DgF5+bk/QMsuqu9AiHG7SswX4tP2z+sMwwC95F5rtmj2/AACHTPkWkNQFMDqQS6rF0yuab6qndOPogYiwhbJYXOwBKtgMuAywpq+T5zRljwaPtjaNS2wOKexULfYklhD9VtqO3ACgqBnSzv0NkcAAAAASUVORK5CYII=
""")

TEAL_BIN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABgAAAAgCAYAAAAIXrg4AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAUGVYSWZNTQAqAAAACAACARIAAwAAAAEAAQAAh2kABAAAAAEAAAAmAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAYoAMABAAAAAEAAAAgAAAAAGG5qPQAAAIwaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj42NDwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K9kzRbAAAAVVJREFUSA3tVbttxDAM9QW3QlbIAtnBjV1kivSexIBnsWHAfcpbIG7TpU+riIYoiB+J8jVBkFxDke/xPUpn2U3z//vpE7gYAzgDB7iooYFE9On2mfV4f37UMKJJEs92JUGu9nV746Xm4/UFalE3LgKzanouHETRjGiSxDPcOI4HcRgGbDAj6yGa11w3NuXw2rowgMnneTb79303OUB4YCyyPYbdlXKDu0RKTdUGXdeVdLJYlQGKY8yqKYBpwEV5rmiSkmmwLAtp4DkBlUQzuPR9T6goipGAIQkXUzyFmoHox2PBKAiFgrhoGrc0ucZPa1U7SBvOrn+/QdV/gE9V+hJc1/U4rW3b8NTEEwSAeUQgDq9uEEcjVEzEsSSiaSA6fGGaplh2Ln4E4yKCfqFuKxCOBv7hgQvVtm2TmV7oiULq7tfqVIyDqaWFvFMRBjgzxCnxP0L+Br1xU57RpzSpAAAAAElFTkSuQmCC
""")

WHITE = "#ffffff"
GREEN = "#29e65f"
BROWN = "#9c5a3c"
SILVER = "#b4b4b4"
TEAL = "#26cdeb"

def main():
    now = time.now().in_location("GMT")
    currentDay = now.day
    currentMonth = now.month

    # For testing.
    #currentDay = 13
    #currentMonth = 5

    preText = "Next Bin:"
    dayThing = ""
    displayDay = ""

    # Flags
    warning_flag = False

    displayMonth = month_maker(currentMonth)
    displayDay, binText, binColour, BIN_ICON, binDay, preText, warning_flag, displayMonth = myBins(currentDay, currentMonth, preText, warning_flag, displayMonth)
    dayThing = date_thing_maker(displayDay)

    if warning_flag == True:
        WARNING = "#FF5733"
        preText = "TONIGHT!"
        displayMonth = ""
        displayDay = ""
        binDay = "Bin Out."
        dayThing = ""
    else:
        WARNING = WHITE

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = BIN_ICON),
                    render.Column(
                        children = [
                            render.WrappedText(content = preText, color = WARNING),
                            render.WrappedText(content = binText, color = binColour),
                            render.WrappedText(content = binDay, color = WHITE),
                            render.WrappedText(content = str(displayDay) + dayThing + " " + displayMonth, color = WHITE),
                        ],
                    ),
                ],
            ),
        ),
    )

def date_thing_maker(displayDay):
    displayDay = ""
    if displayDay == 3 or displayDay == 23:
        dayThing = "rd"
    elif displayDay == 2 or displayDay == 22:
        dayThing = "nd"
    elif displayDay == 1 or displayDay == 31:
        dayThing = "st"
    else:
        dayThing = "th"

    return dayThing

def month_maker(currentMonth):
    month = ""
    if currentMonth == 1:
        month = "Jan"
    elif currentMonth == 2:
        month = "Feb"
    elif currentMonth == 3:
        month = "March"
    elif currentMonth == 4:
        month = "April"
    elif currentMonth == 5:
        month = "May"
    elif currentMonth == 6:
        month = "June"
    elif currentMonth == 7:
        month = "July"
    elif currentMonth == 8:
        month = "Aug"
    elif currentMonth == 9:
        month = "Sept"
    elif currentMonth == 10:
        month = "Oct"
    elif currentMonth == 11:
        month = "Nov"
    elif currentMonth == 12:
        month = "Dec"

    return month

def myBins(currentDay, currentMonth, preText, warning_flag, displayMonth):
    extraBin = False
    longMonth = False
    displayDay = ""
    customDay = ""
    binText = ""
    binColour = ""
    binDay = ""
    BIN_ICON = GREEN_BIN_ICON

    e1, e2, e3, e4, e5, e6, e7, e8, e9, b1, b2, b3, b4, b5, b6, b7, b8, b9, extraBin, longMonth, customDay = getMonthData(currentDay, currentMonth, extraBin, longMonth, customDay)

    print(customDay)

    if currentDay >= 1 and currentDay < e1:
        displayDay = e1
        binText, binColour, BIN_ICON, binDay = get_bin_info(b1, customDay)

        if currentDay == displayDay - 1:
            warning_flag = True

    s2 = e1
    if currentDay >= s2 and currentDay < e2:
        displayDay = e2
        binText, binColour, BIN_ICON, binDay = get_bin_info(b2, customDay)

        if currentDay == displayDay - 1:
            warning_flag = True

    s3 = e2
    if currentDay >= s3 and currentDay < e3:
        displayDay = e3
        binText, binColour, BIN_ICON, binDay = get_bin_info(b3, customDay)

        if currentDay == displayDay - 1:
            warning_flag = True

    s4 = e3
    if currentDay >= s4 and currentDay < e4:
        displayDay = e4
        binText, binColour, BIN_ICON, binDay = get_bin_info(b4, customDay)

        if currentDay == displayDay - 1:
            warning_flag = True

    s5 = e4
    if currentDay >= s5 and currentDay < e5:
        displayDay = e5
        binText, binColour, BIN_ICON, binDay = get_bin_info(b5, customDay)

        if currentDay == displayDay - 1:
            warning_flag = True

    s6 = e5
    if currentDay >= s6 and currentDay < e6:
        displayDay = e6
        binText, binColour, BIN_ICON, binDay = get_bin_info(b6, customDay)

        if currentDay == displayDay - 1:
            warning_flag = True

    s7 = 0
    s8 = 0
    s9 = 0

    if extraBin == True and longMonth == False:
        s7 = e6
        if currentDay >= s7 and currentDay < e7:
            displayDay = e7
            binText, binColour, BIN_ICON, binDay = get_bin_info(b7, customDay)

            if currentDay == displayDay - 1:
                warning_flag = True

        s8 = e7
        if currentDay >= s8:
            displayDay = e8
            binText, binColour, BIN_ICON, binDay = get_bin_info(b8, customDay)
            displayMonth = month_maker(currentMonth + 1)

    elif longMonth == True and extraBin == True:
        s7 = e6
        if currentDay >= s7 and currentDay < e7:
            displayDay = e7
            binText, binColour, BIN_ICON, binDay = get_bin_info(b7, customDay)

            if currentDay == displayDay - 1:
                warning_flag = True

        s8 = e7
        if currentDay >= s8 and currentDay < e8:
            displayDay = e8
            binText, binColour, BIN_ICON, binDay = get_bin_info(b8, customDay)

            if currentDay == displayDay - 1:
                warning_flag = True

        s9 = e8
        if currentDay >= s9:
            displayDay = e9
            binText, binColour, BIN_ICON, binDay = get_bin_info(b9, customDay)
            displayMonth = month_maker(currentMonth + 1)

    else:
        s7 = e6
        if currentDay >= s8:
            displayDay = e7
            binText, binColour, BIN_ICON, binDay = get_bin_info(b7, customDay)
            displayMonth = month_maker(currentMonth + 1)

    return (displayDay, binText, binColour, BIN_ICON, binDay, preText, warning_flag, displayMonth)

def getMonthData(day, month, eB, lM, cD):
    # Example to add custom day in the data.
    #if day >= 10 and day < 13:
    #        cD = "Saturday"
    #    else:
    #        cD = ""
    e1 = 0
    e2 = 0
    e3 = 0
    e4 = 0
    e5 = 0
    e6 = 0
    e7 = 0
    e8 = 0
    e9 = 0
    b1 = ""
    b2 = ""
    b3 = ""
    b4 = ""
    b5 = ""
    b6 = ""
    b7 = ""
    b8 = ""
    b9 = ""

    print(day)
    if month == 5:
        e1 = 10
        b1 = "silver"
        e2 = 13
        b2 = "brown"
        e3 = 17
        b3 = "green"
        e4 = 24
        b4 = "silver"
        e5 = 27
        b5 = "brown"
        e6 = 28
        b6 = "teal"
        e7 = 31
        b7 = "green"

        # This is the first bin the next month.
        e8 = 7
        b8 = "silver"
        e9 = 99
        b9 = ""
        eB = True

    if month == 6:
        e1 = 7
        b1 = "silver"
        e2 = 10
        b2 = "brown"
        e3 = 14
        b3 = "green"
        e4 = 21
        b4 = "silver"
        e5 = 24
        b5 = "brown"
        e6 = 28
        b6 = "green"

        # This is the first bin the next month.
        e7 = 5
        b7 = "silver"
        e8 = 99
        b8 = ""
        e9 = 99
        b9 = ""

    if month == 7:
        e1 = 5
        b1 = "silver"
        e2 = 8
        b2 = "brown"
        e3 = 12
        b3 = "green"
        e4 = 19
        b4 = "silver"
        e5 = 22
        b5 = "brown"
        e6 = 23
        b6 = "teal"
        e7 = 26
        b7 = "green"

        # This is the first bin the next month.
        e8 = 2
        b8 = "silver"
        e9 = 99
        b9 = ""
        eB = True

    if month == 8:
        e1 = 2
        b1 = "silver"
        e2 = 5
        b2 = "brown"
        e3 = 9
        b3 = "green"
        e4 = 16
        b4 = "silver"
        e5 = 19
        b5 = "brown"
        e6 = 23
        b6 = "green"
        e7 = 30
        b7 = "silver"

        # This is the first bin the next month.
        e8 = 2
        b8 = "brown"
        e9 = 99
        b9 = ""
        eB = True

    if month == 9:
        e1 = 2
        b1 = "brown"
        e2 = 6
        b2 = "green"
        e3 = 13
        b3 = "silver"
        e4 = 16
        b4 = "brown"
        e5 = 17
        b5 = "teal"
        e6 = 20
        b6 = "green"
        e7 = 27
        b7 = "silver"
        e8 = 30
        b8 = "brown"
        e9 = 4
        b9 = "green"
        eB = True
        lM = True

    if month == 10:
        e1 = 4
        b1 = "green"
        e2 = 11
        b2 = "silver"
        e3 = 14
        b3 = "brown"
        e4 = 18
        b4 = "green"
        e5 = 25
        b5 = "silver"
        e6 = 28
        b6 = "brown"

        # This is the first bin the next month.
        e7 = 5
        b7 = "green"
        e8 = 99
        b8 = ""
        e9 = 99
        b9 = ""

    return (e1, e2, e3, e4, e5, e6, e7, e8, e9, b1, b2, b3, b4, b5, b6, b7, b8, b9, eB, lM, cD)

def get_bin_info(bin_colour, customDay):
    print(customDay)

    binText = ""
    binColour = ""
    binDay = ""
    BIN_ICON = SILVER_BIN_ICON

    if bin_colour == "brown":
        binText = "Brown"
        binColour = BROWN
        BIN_ICON = BROWN_BIN_ICON
        binDay = "Monday"

    elif bin_colour == "silver":
        binText = "Silver"
        binColour = SILVER
        BIN_ICON = SILVER_BIN_ICON
        binDay = "Friday"

    elif bin_colour == "green":
        binText = "Green"
        binColour = GREEN
        BIN_ICON = GREEN_BIN_ICON
        binDay = "Friday"

    elif bin_colour == "teal":
        binText = "Teal"
        binColour = TEAL
        BIN_ICON = TEAL_BIN_ICON
        binDay = "Tuesday"

    if customDay != "":
        binDay = customDay

    return (binText, binColour, BIN_ICON, binDay)
