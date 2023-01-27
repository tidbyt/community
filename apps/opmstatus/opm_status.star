"""
Applet: OPM Status
Summary: Displays current OPM status
Description: Displays the current Office of Personnel Management status, which is used by federal employees to know if the normal working conditions have been changed by inclement weather, health hazards, or other alerts. Updates every 2 hours.
Author: AdamMoses-GitHub
Reference: https://www.opm.gov/policy-data-oversight/snow-dismissal-procedures/current-status/
"""

# -------------------------

load("cache.star", "cache")
load("http.star", "http")

# load some modules
load("render.star", "render")

# -------------------------

# URL to the OPM operating status JSON feed
OPM_JSON_URL = "https://www.opm.gov/json/operatingstatus.json"

# how often to refresh the feed, in seconds
EXPIRE_URL_DATA = 7200

DARK_YELLOW = "#AB9144"
DARK_RED = "#8B0000"
DARK_GREEN = "#006400"
DARK_BLUE = "#00008B"

# -------------------------

# takes the data from the URL get of the json and formats for display
def format_opm_url_data(opm_status_summary, opm_applies_to_date):
    # add period to end of status, if needed
    if (opm_status_summary[:-1] != "."):
        opm_status_summary += "."

    # split date into parts
    opm_date_split = opm_applies_to_date.split(" ")

    # extract the month name, day of month, and the year
    month_name = opm_date_split[0]
    day_value = opm_date_split[1][:-1]  # remove the trailing comma
    year_value = opm_date_split[-1]

    # if month is more than 4 characters, reduce to 3 and add period
    if (len(month_name) > 4):
        month_name = month_name[0:3] + "."

    # combine elements for final date value
    opm_applies_to_date = "" + month_name + " " + day_value + " " + year_value

    return opm_status_summary, opm_applies_to_date

# -------------------------

def main():
    print("-- opm_status_v1.star::main() START")

    # get the data cached flag value from the cache
    data = cache.get(OPM_JSON_URL + ".dataischached")

    # check if data has been cached already
    if data == None:
        # if not already cached, fetch the data
        print("no cache, fetching JSON data")

        # query the JSON url to get the opm status data
        url_response = http.get(OPM_JSON_URL)

        # if the request failed, write out error
        if url_response.status_code != 200:
            fail("OPM Status request failed with status %d", url_response.status_code)

        # grab relevant parts from the JSON dict
        statussummary_val = url_response.json()["StatusSummary"]
        appliesto_val = url_response.json()["AppliesTo"]
        statustype_val = url_response.json()["Icon"]

        # format the parts using function
        statussummary_val, appliesto_val = format_opm_url_data(statussummary_val, appliesto_val)

        # set the data is cached value to note for future occurences
        cache.set(
            OPM_JSON_URL + ".dataischached",
            "YES",
            ttl_seconds = EXPIRE_URL_DATA,
        )

        # store the opm status and applies to date
        cache.set(
            OPM_JSON_URL + ".status",
            statussummary_val,
            ttl_seconds = EXPIRE_URL_DATA,
        )
        cache.set(
            OPM_JSON_URL + ".appliesto",
            appliesto_val,
            ttl_seconds = EXPIRE_URL_DATA,
        )
        cache.set(
            OPM_JSON_URL + ".type",
            statustype_val,
            ttl_seconds = EXPIRE_URL_DATA,
        )
        cache.set(
            OPM_JSON_URL + ".cachecount",
            "1",
            ttl_seconds = EXPIRE_URL_DATA,
        )

    else:
        # if cached, update the cache count
        cache_count_str = cache.get(OPM_JSON_URL + ".cachecount")
        print("already cached, cache count = " + cache_count_str)
        cache_count_int = int(cache_count_str)
        cache_count_str = str(cache_count_int + 1)
        cache.set(
            OPM_JSON_URL + ".cachecount",
            cache_count_str,
            ttl_seconds = EXPIRE_URL_DATA,
        )

    # get the summary and applies to date from the cache
    opm_status_summary = cache.get(OPM_JSON_URL + ".status")
    opm_applies_to_date = cache.get(OPM_JSON_URL + ".appliesto")
    opm_status_type = cache.get(OPM_JSON_URL + ".type")

    # assume color is green for "Open", otherwise set color accordingly
    status_color = DARK_GREEN
    if (opm_status_type == "Alert"):
        status_color = DARK_YELLOW
    elif (opm_status_type == "Closed"):
        status_color = DARK_GREEN

    # build the relevant text widgets
    status_title_text = render.Text("OPM Status:")
    status_text = render.Marquee(
        width = len(opm_status_summary),
        child = render.Text(opm_status_summary, color = status_color),
        offset_start = 64,
    )
    for_date_text = render.Text("For Date:")
    applies_to_text = render.Text(
        content = opm_applies_to_date,
        color = DARK_BLUE,
    )

    # build widget from all rows of above text
    all_rows = render.Column(children = [
        status_title_text,
        status_text,
        for_date_text,
        applies_to_text,
    ])

    print("-- opm_status_v1.star::main() END")

    # return the rendered rows widget
    return render.Root(
        child = all_rows,
    )

# -------------------------

# --- THE END ---
