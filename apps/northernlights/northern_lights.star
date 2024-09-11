"""
Applet: Northern Lights
Summary: Northern Lights Data
Description: Displays the current Northern Lights data from the NOAA including the KP index, wind speed, Bz, and a brieft summary of the most resent NOAA notifications. This data will show you the current space weather conditions for aurura level estimates.
Author: @objectivelabs
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#base 64 encoded northern lights image logo
NORTHERN_LIGHTS_ICON_20PX = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAIAAAAC64paAAAACXBIWXMAAAsTAAALEwEAmpwYAAAGLWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuOWNjYzRkZTkzLCAyMDIyLzAzLzE0LTE0OjA3OjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIGV4aWY6UGl4ZWxYRGltZW5zaW9uPSIyMDciIGV4aWY6UGl4ZWxZRGltZW5zaW9uPSIxNzciIGV4aWY6VXNlckNvbW1lbnQ9IlNjcmVlbnNob3QiIHhtcDpDcmVhdGVEYXRlPSIyMDIyLTA2LTE3VDExOjAzOjU2LTA1OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMi0wNi0xN1QxMToyNTo1OC0wNTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMi0wNi0xN1QxMToyNTo1OC0wNTowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6OTUzZDY1ODUtYTNiZi00YmYyLWE4ZjYtODMwMzk4YmJiNDMzIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6Y2I0OWYzZGMtYWNlYi1hZDRkLTg2YWYtN2Q2YWFjNWUyODQ5IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6Mzg2M2IyNTAtOGIyZi00N2IyLTkzYjEtOThlNDVmYjUyZTE5Ij4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6Mzg2M2IyNTAtOGIyZi00N2IyLTkzYjEtOThlNDVmYjUyZTE5IiBzdEV2dDp3aGVuPSIyMDIyLTA2LTE3VDExOjA0OjMwLTA1OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjMuMyAoTWFjaW50b3NoKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6OTUzZDY1ODUtYTNiZi00YmYyLWE4ZjYtODMwMzk4YmJiNDMzIiBzdEV2dDp3aGVuPSIyMDIyLTA2LTE3VDExOjI1OjU4LTA1OjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjMuMyAoTWFjaW50b3NoKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz6A4Jm7AAACb0lEQVQ4EdXBSWsTUQAH8P9b5s2WTDqdNGkyXUxXRKz04lUFjwrix1PwC4gHRaEHoRcPRRCxFbSlpnaheyZLbZb35s2zFAW96Lm/H64mgguUUccFpUZrwBBKjVJGDvA/HIBVLFHHIZxng4ExGbUdkyqjVNpoGDXAH6jtGZMaKXGJAXAmY+YJFniGGiIoCzyQjBV8XoqMVEQbMMZyvj0R29fGdLNlpMQlDoCHlDqMVRyrDQZCPUcfwBBCXGGFE4aCaEMMWJgzSvXXM/zGAdiTVEPh8DhMLFBC5ix+s2B6AGW6b/Vtfd5qm17K8hTEpEQCIIABGIDCnXzyum7WflRJGYkyW13HY95tW4wzl/N87DInk6rDy5pHSq2dR1mxVK40OwkDoBKldmUwWRtdWEAU8MKw1Q6JpHxMWlOUzab52B2aKORuWfamCDYr1Zl5bZGTw10OYNAMMBnS0gidn6eyd7a3nWnNT4PcitfP79NqT0S+bil8CumXPOLuIPLSRALgAPzyaCpTqzreK48cLC8n9Q0DMNsOyYyrplhbKFv0jo4sPxRzw+roW8/PK0EBcAABHRaWcHipu7IpNs7i3HRKUqm6an0HUcd9eE8u3ki/bwFMcUu7ks/Uzl6+AsAALBbvj4p4b2258XlFqZZQmLKvR7TocFccnzsbDa8DJXuZ71huoJNG493bZGkJacoBjDbF+/ab/e5XXJBodnZk6+Ru9Cjms3W2SZpp8OLwlCUiKla92vP6s+ZgB5cIgAhhA038bQjBA/9xjdfKtFRl8bas+9r52P/wRD/V+IXgnyq0PM2mKqzSyc6Os6PVdFXjyvsJ0DkUGWClkDEAAAAASUVORK5CYII=""")

#Noaa data APi urls
kp_url = "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json"
windspeed_url = "https://services.swpc.noaa.gov/products/summary/solar-wind-speed.json"
bz_url = "https://services.swpc.noaa.gov/products/summary/solar-wind-mag-field.json"
alerts_url = "https://services.swpc.noaa.gov/products/alerts.json"

# Fetch data from the given URL
def fetch_data(url):
    resp = http.get(url)
    if resp.status_code != 200:
        fail("Request failed with status " + str(resp.status_code))
    return resp.json()

# Parse the alert message to extract the event type and predicted storm level
def parse_alert_message(alert):
    # Helper function to extract data between two markers
    alert = alert.replace("\r\n", " ").replace("\r", " ").replace("\n", " ")
    alert = alert.split(" UTC ", 1)[1] if " UTC " in alert else ""

    def extract_between(text, start, end):
        start_idx = text.find(start)
        if start_idx == -1:
            return None
        start_idx += len(start)
        end_idx = text.find(end, start_idx)
        if end_idx == -1:
            return text[start_idx:]
        return text[start_idx:end_idx].strip()

    # Extract event type
    event_type = None
    if "ALERT" in alert:
        event_type = "ALERT"
    elif "WARNING" in alert:
        event_type = "Warning"
    elif "WATCH" in alert:
        event_type = "Watch"
    elif "SUMMARY" in alert:
        event_type = "Summary"

    # Extract predicted storm level
    predicted_level = extract_between(alert, "Geomagnetic Storm Category ", " Predicted")

    # Format the output
    summary = "{}: {} predicted".format(
        event_type if event_type else "N/A",
        predicted_level if predicted_level else "None",
    )
    return summary

# Main function to fetch data and render the UI
def main():
    # Check if the data is already cached
    kp = cache.get("kp") or False
    windspeed = cache.get("windspeed") or False
    bz = cache.get("bz") or False
    alert = cache.get("alert") or False

    # If KP is not cached, fetch new data and cache for 5 minutes (300 seconds)
    if not kp:
        kp_data = fetch_data(kp_url)
        if kp_data and len(kp_data) > 1:
            # KP index is the second item in this list (index 1)
            latest_entry = kp_data[-1]
            kp = latest_entry[1]  # Extract KP value
            print("Kp: ", kp)
            cache.set("kp", kp, ttl_seconds = 300)  # Cache the latest KP value

    # If WindSpeed is not cached, fetch new data and cache for 5 minutes (300 seconds)
    if not windspeed:
        windspeed_data = fetch_data(windspeed_url)

        # Directly access the 'WindSpeed' key from the JSON object
        if "WindSpeed" in windspeed_data:
            windspeed = windspeed_data["WindSpeed"]
            print("WindSpeed: ", windspeed)
            cache.set("windspeed", windspeed, ttl_seconds = 300)
        else:
            print("WindSpeed data not available in the response")

    # If Bz is not cached, fetch new data and cache for 5 minutes (300 seconds)
    if not bz:
        bz_data = fetch_data(bz_url)

        # Directly access the 'Bz' key from the JSON object
        if "Bz" in bz_data:
            bz = bz_data["Bz"]
            print("Bz: ", bz)
            cache.set("bz", bz, ttl_seconds = 300)
        else:
            print("Bz data not available in the response")

    # If Alert is not cached, fetch new data and cache for 5 minutes (300 seconds)
    if not alert:
        alert_data = fetch_data(alerts_url)
        if alert_data and len(alert_data) > 0:
            # The latest data entry is the last item in the list (-1 index)
            # Alert index is the second item in this list (index 1)
            latest_alert_entry = alert_data[-1]
            alert = latest_alert_entry["message"]  # Extract KP value
            alert = parse_alert_message(alert)
            print("Alert value: ", alert)
            cache.set("alert", alert, ttl_seconds = 300)  # Cache the latest KP value

    # Render the UI
    return render.Root(
        child = render.Column(
            children = [
                # First Row with just the logo
                render.Row(
                    main_align = "center",
                    children = [
                        render.Image(src = NORTHERN_LIGHTS_ICON_20PX, width = 64, height = 8),
                    ],
                ),
                # Second Row with three columns for KP, Wind, Bz
                render.Row(
                    main_align = "space_between",
                    children = [
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(content = "  Kp  ", color = "#ffffff"),
                                render.Text(content = str(kp), color = "#3abe3e"),
                            ],
                        ),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(content = " Wind ", color = "#ffffff"),
                                render.Text(content = str(windspeed), color = "#3abe3e"),
                            ],
                        ),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(content = "  Bz  ", color = "#ffffff"),
                                render.Text(content = str(bz), color = "#3abe3e"),
                            ],
                        ),
                    ],
                ),
                # Third Row for Marquee of NOAA alerts
                render.Marquee(
                    width = 64,
                    child = render.Text(alert, color = "#fff"),
                ),
            ],
        ),
    )

# Define the schema for the applet
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
