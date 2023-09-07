"""
Applet: ChartMogul ARR
Summary: Displays ChartMogul ARR
Description: Displays the user's ChartMogul monthly ARR value.
Author: Luke Hutchinson and Dakota Walker
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    CHARTMOGUL_KEY = config.str("chartmogul_api_key")
    if CHARTMOGUL_KEY != None:
        url = "https://api.chartmogul.com/v1/metrics/arr"

        auth_header = "Basic " + base64.encode(CHARTMOGUL_KEY)

        headers = {
            "Authorization": auth_header,
        }

        response = http.get(
            url = url,
            headers = headers,
            params = {
                "start-date": "2023-01-01",
                "end-date": "2023-12-31",
            },
        )

        if response.status_code != 200:
            return render.Root(
                child = render.Text("API failure."),
            )

        response_json = response.json()
        arr = response_json["summary"]["current"]
        arr = int(arr / 100000)
        arr = str(arr)
        arr = arr.split(".")[0]
        return render.Root(
            child = render.Text("$%sK USD" % arr),
        )
    else:
        return render.Root(
            child = render.Text("$12K USD"),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "chartmogul_api_key",
                name = "ChartMogul API Key",
                desc = "ChartMogul authentication API key for completing requests to ChartMogul API.",
                icon = "key",
            ),
        ],
    )
