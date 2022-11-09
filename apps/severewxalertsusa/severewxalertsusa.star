"""
Applet: SevereWxAlertsUsa
Summary: USA Severe WX Alerts
Description: Display count and contents of Severe Weather Alerts issued by the US National Weather Service for your location.
Author: aschechter88
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("cache.star", "cache")
load("math.star", "math")

DEFAULT_LOCATION = """
{
	"lat": "47.2631",
    "lng": "-122.3447",
    "locality": "Seattle"
}
"""

EXCLAMATIONPOINT_IMG = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAAA6FJREFUeF7tnFty6zAMQ5MN3P2vsxtIJ5600+ZaEiWRIFijv1VsGkfgQ/HkftMflQJ3qmgUzE1AyDaBgAgImQJk4cghAkKmAFk4coiAkClAFo4cIiBkCpCF8xcc8mhoWvLZSgb9A0ALxnNJyWcrGbQRSEkolYH03PHFrNzzlQt4wh1yCLBhsbhDQEBArDBKpq2KKUtAQDvfcptRm1t+JqnkkFOxHx+/Od7/nXIt85xVAjXB+C4ahaFcCUiJrqsCkCl3VHfJ1YDQu4QdyJI7KrukHJD3rmrUK1frupiBbLlj4BLa1FUKyKw7KqYuViAu7qjoEkYgrjCqueQyQI6iUWCCZwMS4o5KqYseyGohb7XD7C5hAhLqjp+AmKGwAIHBYK8llwTCDIUBCNQdhgKfOsVTAvEu5JMFPvXliGwgKe4wFPg0l2QC2YbR6JYOva0u61wjRZuUm752KAWQToFPcUkWkG0YAyHNDhGQ26357tTjo/m/83d7zs+mplKWoeuCblrozbxSlUHEKYcwnQijgbikKjAQaC0RkLdkmH3OhQTi6g7Pos40l6CAuBVyo3hLNYShlqQCsQ5vK0cfgdcO1Sz04t5d1TsYj0l9AXaoZqEXf55gtB54dwdH1RBDSgzVLPLioTAQQDr3CNMt7MIdd9xnJ/KFtLJV1A0uCZtNooCEuwPlELRLIoBAYBAACXGJgLTyYdIEDwPi0VUh294zTohjFW8gIRN5ZlFHF3gIkAh3IGsIEoonEKg7BKRf/GCdlbEGhy6LfDHCyyHuR+uhijpcPAqKB5BLuWNwRL89m+wCuSSMSCgCspG+esf/qz/CuQPk0u6Icok7kKiZY2Mjh3/Uc4JfBQKfOSaOMo6lyI3h2XF5AnH7nsO6pSO/wrXG4J26VoBQuCNrUu+B8khds0CoCjmTQwYbxKyzeeFrZ9C4g9EhnZjMOpsXRr9BMpuziwExT/DbQJDdzDs0tpTlUeCtQKhqx4qb0J9ZLfAWIIKxQHN1NhGQBbGtH1lxyQiI3GFV/2Tdikt6QJow0EcTG5qkf3TWJUtAMjurdIUnA5h1SQtIzx3wM6tJDaiWCwgVjuNnBZ+bvnnC8d9sdRJ/1x2v+tGtL2SapIYTDST14f7ozX+VjbMaot2PJS8gWL2HdxOQoUTYBUMgR91+i2k00WMfofbdutpKaDK4AiIgZAqQhSOHCAiZAmThyCECQqYAWThyiICQKUAWjhwiIGQKkIXzCePGFnRmQM7hAAAAAElFTkSuQmCC")
WARNING_IMG = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAABABJREFUeF7t3G1u1DAQBuBUojeBU8DxyyngJiBRpSKrNBvb8/HOeGwPv1CbeNN5/I6dbLsvW/4LVYGXUFeTF7MlSLBJEAnkX6faRKpB14T0Ami5dwXq8eJRIa5QPWrjlpBREErpccOxfqHRIdxTYwkyG8aBY1kzk5Y1K4RLWtDabhhvX77e9vsff3+3dlHI76PrB0uIKUSp+NTKOiDBYBADwTG0AC0oIyBELdUJgWJYQ1yhDGDUKJoBIBjeCKX0AHE0NRUnRI0RBcIoNWIUyYnTYhw4oLRIastOiAojaioM2xgbhXPCUhjAtHBqTE6IGGO0VBilhYxCOXB5DFBaKLUmJUQEMksygLswCEhi3PQwxS6siVI7IDEqz2CsUKAgs7Yp8EJfTUnpm+x0rIahXOiLKBCQVTEUKCwQVjpWx0Cj3EklSOsNFczO6zYl1y8mhgADmRIxSO9W9f3Pr2rpfr5+U5RWfipzO/yUkvMXhkrHJCC7/CcUEUjvdOw/RVSQ/do0KUkQeXcqnukKEiEd0ROiSQk7IQlCi5Q0JSyQKBgjJISZkodDgtAmvOgoRkr4IJHSMUpCGClJENGUF5zETQm5ZWVCBBq8e5IPCxJINIyRWha3bSWIbOKzziK2rUwIq6qKgxNk27ZeT3vv3BJkZpCIC/poizpxYaetIQmiWDxOpxLaVoJgSk0bJUE6vYVb4kmQBKFFF3VU5LdwhVtf2hqyDx5xYR8JhNCuHo+x8tEJKrKVcZYAcagj7CUSBFZKzEAJgqkjbBQ4SNSFHVYxw4GIGLxFPUHkYgkir53JmUQQ/i85ZEr4XkSMR7v69J9t25q//R7xBpFfJr8zzEEipST6nToDQ56QBKGnyw0kCkrkhEgx2GvIMT8irCUJcklrb5SoIMx0XEPx9GlAzZ1WlJRMAlL9o8+91mSQ3mtJRBBtOp7i8n/2D4ESDQSBMTQIfQPqc6QlyFCty6fc9VdBYZQSwgbpvZ70RBFg1Ope/cxF1lqyIgoaoyrF3XFF2Q57pUWI0ap581NJ2SlZISlWGE0tyTZ49qRYYpiCzJgUBQa11s2WdUx4UeuaCcUDg6ymaV2jtzAlBLfG5ISokzJiWrwx2HqIpIwAA4CQ1padEEhSIqP0xBAropISCQYEoa2pOCGwpJzvrL3fhQQiHD9G9XPdKU8R1ANIH7HULs4axgBCnQyYKLJ9lZC0QEYA58tFTOyP8WADecBQ2ptD8U0g0Ak5X6T4rp7SYwMdg57MJglZAcYEwjIhM6OYYlisIaWOMnobM4fwSsgd0Cg4bgimuwTGohsVpgtEz4REa2tdAa7FCHUxN1LoFEX/eeE3hoyOlYfeVSD8jFmNLUGCiSdIMJB3Az+ndAmyQLEAAAAASUVORK5CYII=")

## run the main applications
def main(config):
    jsonLocation = json.decode(config.str("location") or DEFAULT_LOCATION)  ## set the location from the schema data or use the default

    alerts = get_alerts(jsonLocation["lat"], jsonLocation["lng"])  ## call for the alerts for this location

    foundAlerts = 0  # default alert detection to false

    columnFrames = []  # Create the master list of frames for the sequence render

    ## check for alerts and count.
    foundAlerts += len(alerts)

    ## if found, render summary frame
    if (foundAlerts):  ## render the summary card and then each card
        columnFrames.append(render_summary_card_for_alerts(jsonLocation, foundAlerts))

        alertCounter = 0  ## this...could have been done differently

        for alert in alerts:
            alertCounter += 1
            columnFrames.append(render_alert(alert, alertCounter, foundAlerts))
    elif config.bool("alert_only", False):  ## no alerts, hide app
        return []
    else:  ## no alerts, show the green no alerts screen
        columnFrames.append(render_summary_card_zero_alerts(jsonLocation))

    return render.Root(
        render.Animation(columnFrames),
        delay = 5000,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display alerts.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "alert_only",
                name = "Alerts only",
                desc = "Enable to show app only when there are alerts.",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )

## Acquire the set of Weather Alerts for this lat/long point for both Forecast Zone and County level alerts. Return a dict.
def get_alerts(lat, long):
    ## truncate location for privacy without sacrificing useable accuracy
    truncatedLat = truncate_location_digits(lat)
    truncatedLong = truncate_location_digits(long)

    ## master list
    alerts = []

    ## check cache, 5 minutes TTL
    cachekey = "lawnchairs.severewxalertsusa." + truncatedLat + "." + truncatedLong  ##cache key is for a lat/long pair

    if (cache.get(cachekey) != None):
        ## cache hit
        alerts = json.decode(cache.get(cachekey))
        return alerts

    else:
        ## cache miss

        ## Get the alerts for the lat/long point and append them to the alerts dictionary.

        pointAlertsResponse = http.get("https://api.weather.gov/alerts/active?point=" + truncatedLat + "," + truncatedLong)

        for item in pointAlertsResponse.json()["features"]:
            ## filter out test alerts
            if (item["properties"]["status"] == "Test"):
                continue
            else:
                alerts.append(item)

        # set cache. cast object to jsonstring
        cache.set(
            key = cachekey,
            value = json.encode(alerts),
            ttl_seconds = 300,
        )

        return alerts

## Render the alert frame
def render_alert(alert, alertIndex, totalAlerts):
    ## Master column.
    column = []

    ## top row - Alert count row
    alertCountRenderText = render.Text(
        content = "WX ALERT " + str(alertIndex) + "/" + str(totalAlerts),
        color = "#FFFF00",
        font = "CG-pixel-3x5-mono",  # tiny
    )
    alertCountRenderBox = render.Box(
        child = alertCountRenderText,
        height = 5,
    )
    alertCounterRenderRow = render.Row(
        children = [alertCountRenderBox],
        expanded = True,
        main_align = "center",
    )
    column.append(alertCounterRenderRow)  ## add top row to master column

    ## middle row - alert icon and text
    titleRowWidgets = []

    ## Severity Icon for moderate
    if (alert["properties"]["severity"] == "Moderate" or alert["properties"]["severity"] == "Minor"):
        circle = render.Image(
            src = EXCLAMATIONPOINT_IMG,
            height = 16,
            width = 16,
        )
        box = render.Box(
            child = circle,
            width = 16,
            height = 22,
        )
        titleRowWidgets.append(box)

        ## Severity Icon for severe/extreme
    elif ((alert["properties"]["severity"] == "Severe" or alert["properties"]["severity"] == "Extreme")):
        circle = render.Image(
            src = WARNING_IMG,
            height = 16,
            width = 16,
        )
        box = render.Box(
            child = circle,
            width = 16,
            height = 22,
        )
        titleRowWidgets.append(box)

    ## Main Alert Text
    mainAlertText = alert["properties"]["event"]

    mainAlertTextWrappedWidget = render.WrappedText(
        content = mainAlertText.upper(),
        align = "center",
        font = "CG-pixel-4x5-mono",  # tiny
        color = "#FF0000",  # red
    )

    mainAlertTextWrappedWidget = render.Box(
        child = mainAlertTextWrappedWidget,
        height = 22,
        width = 48,
    )
    titleRowWidgets.append(mainAlertTextWrappedWidget)

    titleRow = render.Row(
        children = titleRowWidgets,
        expanded = True,
        main_align = "center",
    )

    column.append(titleRow)

    ## bottom row - Alert Expiration Time

    ## "ends" is the key, but can be None for ongoing/until further notice events.
    ## see https://github.com/weather-gov/api/discussions/385#discussioncomment-592840

    if (alert["properties"]["ends"] == None):
        untilText = "ongoing"
    else:
        alertExpirationTime = time.parse_time(alert["properties"]["ends"])
        untilText = "End: " + alertExpirationTime.format("15:04 Mon")  ## format date

    alertRenderText = render.WrappedText(
        untilText,
        align = "center",
        font = "CG-pixel-3x5-mono",  ## make it small
    )
    alertRenderBox = render.Box(
        child = alertRenderText,
        height = 5,
    )
    alertRow = render.Row(
        children = [alertRenderBox],
        expanded = True,
        main_align = "center",
    )

    column.append(alertRow)

    ## Return master column assembly
    return render.Column(
        children = column,
        main_align = "center",
    )

def render_summary_card_for_alerts(location, alerts):
    # master column list
    master_column = []

    # first row -- fixed title
    titleText = render.Text(
        content = "WEATHER ALERTS",
        color = "#FFFF00",
        font = "CG-pixel-3x5-mono",  # tiny
    )
    titleBox = render.Box(
        child = titleText,
        height = 5,
    )
    titleRow = render.Row(
        children = [titleBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(titleRow)

    ## text format
    alertsCountString = " ALERT"
    if (alerts > 1):
        alertsCountString += "S"

    ## center row
    alertsText = render.Text(
        content = str(alerts) + alertsCountString,
        color = "#FFFF00",
        font = "6x13",
    )
    alertsBox = render.Box(
        child = alertsText,
        height = 17,
    )

    alertsRow = render.Row(
        children = [alertsBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(alertsRow)

    # location row -- bottom
    # location row -- bottom
    locationText = render.WrappedText(
        content = location["locality"],
        align = "center",
        font = "CG-pixel-3x5-mono",  # tiny
    )
    locationBox = render.Box(
        child = locationText,
        height = 10,
    )
    locationRow = render.Row(
        children = [locationBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(locationRow)

    return render.Column(master_column)

def render_summary_card_zero_alerts(location):
    # master column list
    master_column = []

    # first row -- fixed title
    titleText = render.Text(
        content = "WEATHER ALERTS",
        color = "#FFFF00",
        font = "CG-pixel-3x5-mono",  # tiny
    )
    titleBox = render.Box(
        child = titleText,
        height = 5,
    )
    titleRow = render.Row(
        children = [titleBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(titleRow)

    ## center row
    alertsText = render.Text(
        content = "No Alerts",
        color = "#00FF00",
        font = "6x13",
    )

    alertsBox = render.Box(
        child = alertsText,
        height = 17,
    )

    alertsRow = render.Row(
        children = [alertsBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(alertsRow)

    # location row -- bottom
    locationText = render.WrappedText(
        content = location["locality"],
        align = "center",
        font = "CG-pixel-3x5-mono",  # tiny
    )
    locationBox = render.Box(
        child = locationText,
        height = 10,
    )
    locationRow = render.Row(
        children = [locationBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(locationRow)

    return render.Column(master_column)

def truncate_location_digits(inputDigits):
    return str(int(math.round(float(inputDigits) * 200)) / 200)
