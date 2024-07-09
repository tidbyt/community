"""
Applet: Congress Watch
Summary: Updates from U.S. Congress
Description: Displays updates from U.S. Congress.
Author: Robert Ison
"""

load("cache.star", "cache")  #Caching
load("encoding/base64.star", "base64")  #Encoding Images
load("encoding/json.star", "json")  #JSON Data from congress.gov API site
load("http.star", "http")  #HTTP Client
load("render.star", "render")  #Render the display for Tidbyt
load("schema.star", "schema")  #Keep Track of Settings
load("secret.star", "secret")  #Encrypt the API Key
load("time.star", "time")  #Ensure Timely display of congressional actions

API_KEY = "IwiU6rcUFvTMiiVCz1HXblunVhKixvY5L3mDTHsU"
API_KEY_ENCRYPTED = "AV6+xWcEONGMeP4KdGqCO9aQ5vhdBFz4VLyxinpFW+SIsoiYmqcCR33CU6kNEc01NR/ywxYUNJl0CeNkNTZ/lT8rDEjKlENdTMU8/A8YsYjnrUhnq6QLIeO6BRVtGRTwcILtm0fPZrEWId8Ta4cETXU09Ib6LO8AYeHorr0mvi2wNiNn776WxcF+UIkBXg=="#
CONGRESS_API_URL = "https://api.congress.gov/v3/"
CONGRESS_SESSION_LENGTH_IN_DAYS = 720  #730, but we'll shorten it some to make sure we don't miss
CONGRESS_BILL_TTL = 12 * 60 * 60  #12 hours * 60 mins/hour * 60 seconds/min
MAX_ITEMS = 50

senate_icon = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAw3pUWHRSYXcgcHJvZmlsZSB0eXBlIGV4aWYAAHjabVBbDsMgDPvPKXaEvArhOHTtpN1gx1+AtCpVLeE6ceRCYP99P/BqYFLQJVsqKaFDixauLgwHamdC7RwFHmLqw2mwt8S/MkpLMX/0Cackqq6WS5C9w1hno2jk2y0ofiTtRuxii6ASQcLDoAio41mYiuXrE9YdZ9g40Ehyzz5D7rVm3962eFOYdyFBZ5E0LiDtKEh1kTubD5KYa3GrxiiNhTzt6QD8Ad0yWR/a/LVjAAABhGlDQ1BJQ0MgcHJvZmlsZQAAeJx9kT1Iw0AcxV9TpUUqDhYREcxQXbSLijjWKhShQqgVWnUwufQLmjQkLS6OgmvBwY/FqoOLs64OroIg+AHi7OCk6CIl/i8ptIjx4Lgf7+497t4BQqPMNKsrBmh61Uwl4mImuyoGXhFAEAMYwbjMLGNOkpLwHF/38PH1LsqzvM/9OXrVnMUAn0gcY4ZZJd4gntmsGpz3icOsKKvE58QTJl2Q+JHristvnAsOCzwzbKZT88RhYrHQwUoHs6KpEU8TR1RNp3wh47LKeYuzVq6x1j35C0M5fWWZ6zSHkcAiliBBhIIaSiijiiitOikWUrQf9/APOX6JXAq5SmDkWEAFGmTHD/4Hv7u18lOTblIoDnS/2PbHKBDYBZp12/4+tu3mCeB/Bq70tr/SAGY/Sa+3tcgR0LcNXFy3NWUPuNwBBp8M2ZQdyU9TyOeB9zP6pizQfwv0rLm9tfZx+gCkqavkDXBwCIwVKHvd493Bzt7+PdPq7wey3HLAo6VLtgAADXppVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+Cjx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDQuNC4wLUV4aXYyIj4KIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIgogICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgIHhtbG5zOkdJTVA9Imh0dHA6Ly93d3cuZ2ltcC5vcmcveG1wLyIKICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICB4bXBNTTpEb2N1bWVudElEPSJnaW1wOmRvY2lkOmdpbXA6YjdkNmM1YmItMDllNC00NjZjLWJmODgtNTMzYWU2N2NhYjNmIgogICB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjQwNzg2NmRlLTU4NTktNGY0ZC05ZWVmLTgyMmFjZDEwNWMxMCIKICAgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmM5Y2NiOWUyLTA3OGQtNGNiZi1hMDhjLTZkOWIyMTFlNmI3OSIKICAgR0lNUDpBUEk9IjIuMCIKICAgR0lNUDpQbGF0Zm9ybT0iTWFjIE9TIgogICBHSU1QOlRpbWVTdGFtcD0iMTcyMDQ3Nzk1ODYxNjM0NyIKICAgR0lNUDpWZXJzaW9uPSIyLjEwLjM2IgogICBkYzpGb3JtYXQ9ImltYWdlL3BuZyIKICAgdGlmZjpPcmllbnRhdGlvbj0iMSIKICAgeG1wOkNyZWF0b3JUb29sPSJHSU1QIDIuMTAiCiAgIHhtcDpNZXRhZGF0YURhdGU9IjIwMjQ6MDc6MDhUMTg6MzI6MzYtMDQ6MDAiCiAgIHhtcDpNb2RpZnlEYXRlPSIyMDI0OjA3OjA4VDE4OjMyOjM2LTA0OjAwIj4KICAgPHhtcE1NOkhpc3Rvcnk+CiAgICA8cmRmOlNlcT4KICAgICA8cmRmOmxpCiAgICAgIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiCiAgICAgIHN0RXZ0OmNoYW5nZWQ9Ii8iCiAgICAgIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGYzYjJhMGItNzg4NC00ODMzLTk0NzEtOTI1MjYwODliN2I4IgogICAgICBzdEV2dDpzb2Z0d2FyZUFnZW50PSJHaW1wIDIuMTAgKE1hYyBPUykiCiAgICAgIHN0RXZ0OndoZW49IjIwMjQtMDctMDhUMTg6MzI6MzgtMDQ6MDAiLz4KICAgIDwvcmRmOlNlcT4KICAgPC94bXBNTTpIaXN0b3J5PgogIDwvcmRmOkRlc2NyaXB0aW9uPgogPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgIAo8P3hwYWNrZXQgZW5kPSJ3Ij8+OdIajgAAAAZiS0dEAOAApAAro1pwXAAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB+gHCBYgJh51uS0AAABISURBVDjLY2CgEDDikvj///9/FIWMjIxEGYCuEUMDmkGMxGrEZRAjOZqRDWGiNBCpYwBywKCz8clRzwWjBlAhM1GSEil1AAMANBoUMIVLXC0AAAAASUVORK5CYII=""")

period_options = [
    schema.Option(
        display = "Today",
        value = "1",
    ),
    schema.Option(
        display = "This Week",
        value = "7",
    ),
    schema.Option(
        display = "This Month",
        value = "31",
    ),
    schema.Option(
        display = "Last 90 Days",
        value = "90",
    ),
]

source = [
    schema.Option(
        display = "House of Representatives",
        value = "House",
    ),
    schema.Option(
        display = "Senate",
        value = "Senate",
    ),
    schema.Option(
        display = "House and Senate",
        value = "Both",
    ),
]

scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def main(config):
    api_key = secret.decrypt(API_KEY_ENCRYPTED) or API_KEY

    #Get the current congress
    congress_session_url = "%scongress/current?API_KEY=%s&format=json" % (CONGRESS_API_URL, api_key)
    congress_session_body = cache.get(congress_session_url)

    if congress_session_body == None:
        print("Cache Expired, getting new session info")
        congress_session_body = http.get(url = congress_session_url).body()

    congress_session_body = json.decode(congress_session_body)

    if congress_session_body == None:
        #Error getting data
        fail("Error: Failed to get data from cache or http get calling")

    #Congress Session INfo
    congress_number = congress_session_body["congress"]["number"]
    senate_start = None
    house_start = None

    for i in range(0, len(congress_session_body["congress"]["sessions"])):
        current_start_date = time.parse_time(congress_session_body["congress"]["sessions"][i]["startDate"], format = "2006-01-02")

        if congress_session_body["congress"]["sessions"][i]["chamber"] == "House of Representatives":
            if house_start == None or house_start < current_start_date:
                house_start = current_start_date
        elif congress_session_body["congress"]["sessions"][i]["chamber"] == "Senate":
            if senate_start == None or senate_start < current_start_date:
                senate_start = current_start_date

    session_duration_days = (time.now() - senate_start).hours / 24

    cache_ttl = int((CONGRESS_SESSION_LENGTH_IN_DAYS - session_duration_days) * 60 * 60 * 24)

    #let's cache this for what should be the rest of the session
    cache.set(congress_session_url, json.encode(congress_session_body), ttl_seconds = cache_ttl)

    #Get Bill Data for past X days where X = the most days we search based on period options
    bill_data_from_date = (time.now() - time.parse_duration("%sh" % config.get("period", period_options[-1].value) * 24))
    congress_bill_url = "%sbill/%s?limit=%s&sort=updateDate+desc&api_key=%s&format=json&fromDateTime=%sT00:00:00Z" % (CONGRESS_API_URL, congress_number, MAX_ITEMS, api_key, bill_data_from_date.format("2006-01-02"))

    congress_data = json.decode(get_cachable_data(congress_bill_url, CONGRESS_BILL_TTL))
    filtered_congress_data = filter_bills(congress_data, config.get("period", period_options[0].value), config.get("source", source[-1].value))

    number_filtered_items = len(filtered_congress_data)
    if (number_filtered_items == 0):
        return []

    #let's diplay a random bill from the filtered list
    random_number = randomize(0, number_filtered_items)
    row1 = filtered_congress_data[random_number]["originChamber"]
    row2 = "%s%s %s" % (filtered_congress_data[random_number]["type"], filtered_congress_data[random_number]["number"], filtered_congress_data[random_number]["title"])
    row3 = (filtered_congress_data[random_number]["latestAction"]["text"])

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Marquee(
                            width = 47,
                            height = 8,
                            child = render.Text(row1, font = "6x13", color = "#fff"),
                        ),
                        render.Image(senate_icon),
                        render.Box(width = 1, height = 16, color = "#000"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 15,
                            child = render.Text(row2, font = "5x8", color = "#ff0"),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = len(row2) * 5,
                            child = render.Text(row3, font = "5x8", color = "#f4a306"),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def filter_bills(data, period, source):
    filtered_data = [
        bill
        for bill in data["bills"]
        if (source == "Senate" and bill["originChamberCode"] == "S") or (source == "Both") or (source == "House" and bill["originChamberCode"] == "H")
        if ((time.now() - time.parse_time(bill["updateDate"], format = "2006-01-02")).hours / 24 < int(period))
    ]

    return filtered_data

def randomize(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max - min) + min)

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "period",
                name = "Period",
                desc = "Display Items",
                icon = "calendar",
                options = period_options,
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "source",
                name = "Source",
                desc = "Chamber",
                icon = "landmarkDome",
                options = source,
                default = source[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
