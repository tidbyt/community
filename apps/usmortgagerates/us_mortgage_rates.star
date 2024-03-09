"""
Applet: US Mortgage Rates
Summary: Average US mortgage rates
Description: Tracks average mortgage rates in the US based on FRED economic data.
Author: sullivan1337
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Uses https://fred.stlouisfed.org/docs/api/fred/series_observations.html API schema
FRED_API_BASE_URL = "https://api.stlouisfed.org/fred/series/observations"
CACHE_DURATION = 43200  # get new data every 12 hours

# Mapping of series IDs to their display names
SERIES_NAMES = {
    "OBMMIC30YF": "30-Year Fixed",
    "OBMMIJUMBO30YF": "30-Year Jumbo",
    "MORTGAGE15US": "15-Year Fixed",
    "MORTGAGE30US": "30-Year Fixed",
}

# Reformat date to fit to screen size
def reformat_date(date_str):
    year, month, day = date_str.split("-")
    month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    month_index = int(month) - 1
    short_year = year[-2:]
    new_date = "On {} {} '{}".format(month_names[month_index], day, short_year)
    return new_date

def main(config):
    # Generate a valid API key from https://fredaccount.stlouisfed.org/apikeys
    FRED_API_KEY = config.str("fred_api_key")
    SERIES_ID = config.str("mortgage", "OBMMIC30YF")

    if not FRED_API_KEY:
        return render.Root(child = render.Text("API key missing"))

    params = {
        "series_id": SERIES_ID,
        "api_key": FRED_API_KEY,
        "file_type": "json",
        "limit": "1",
        "sort_order": "desc",
    }

    response = http.get(url = FRED_API_BASE_URL, params = params, ttl_seconds = CACHE_DURATION)
    if response.status_code != 200:
        return render.Root(child = render.Text("API failure."))

    response_json = response.json()
    if "observations" in response_json and len(response_json["observations"]) > 0:
        mortgage_type_name = SERIES_NAMES.get(SERIES_ID, "Selected Mortgage Rate")
        observations = response_json["observations"]

        # Show only the most recent response
        observations_displayed = observations[:1]

        formatted_data = [
            render.Box(
                child = render.Column(
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text("{0}".format(reformat_date(obs["date"])), font = "tb-8", color = "#FFFFFF"),
                        render.Text(mortgage_type_name, font = "tb-8", height = 10, color = "#FFFFFF"),
                        render.Text("{0}%".format(obs["value"]), font = "tb-8", height = 10, color = "#FFFFFF"),
                    ],
                ),
            )
            for obs in observations_displayed
        ]

        return render.Root(child = render.Column(children = formatted_data, main_align = "space_evenly", cross_align = "center"))  # Centers the entire column
    else:
        return render.Root(child = render.Text("No data available."))

def get_schema():
    mortgage_options = [
        schema.Option(display = "30-Year Fixed Rate Index (updated daily)", value = "OBMMIC30YF"),
        schema.Option(display = "30-Year Fixed Rate Jumbo Index (updated daily)", value = "OBMMIJUMBO30YF"),
        schema.Option(display = "15-Year Fixed Rate (updated every Thursday)", value = "MORTGAGE15US"),
        schema.Option(display = "30-Year Fixed Rate (updated every Thursday)", value = "MORTGAGE30US"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "fred_api_key", name = "FRED API Key", desc = "FRED API key for authenticating requests.", icon = "key"),
            schema.Dropdown(id = "mortgage", name = "Mortgage Type", desc = "Which type of mortgage to track.", icon = "circle", default = mortgage_options[0].value, options = mortgage_options),
        ],
    )
