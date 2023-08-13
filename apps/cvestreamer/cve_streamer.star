"""
Applet: CVE Streamer
Summary: Displays recent CVEs
Description: This app displays CVEs from the National Vulnerability Database (https://nvd.nist.gov/vuln) published within the last 30 days.  Keyword search optional, multiple keywords function like an 'AND'.  CVE ID color coded for base severity: red/critical, orange/high, yellow/medium, green/low.
Author: Anthony Rocchio
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TIMEFRAME = 30  # number of days to go back in time
NUM_CVE_TO_GET = 15  # Max CVEs to pull from API
BASE = "https://services.nvd.nist.gov/rest/json/cves/2.0?resultsPerPage=%s&noRejected" % NUM_CVE_TO_GET
SEV_COLORS = {
    "CRITICAL": "#FF0000",  # RED
    "HIGH": "#FFA500",  # ORANGE
    "MEDIUM": "#FFFF00",  # YELLOW
    "LOW": "#00FF00",  # GREEN
    "NONE": "#FFF",
}
MAX_DESCRIPTION_LEN = 300

def get_cves(url, start, end, keyword):
    """ Query the CVE API, return the json if successful
    otherwise return a blank string for error processing
    """

    formatted_url = "%s&pubStartDate=%s&pubEndDate=%s" % (url, start, end)
    if keyword != "":
        formatted_url += "&keywordSearch=%s" % keyword

    res = http.get(formatted_url, ttl_seconds = 3600)
    if res.status_code != 200:
        return ""
    return res.json()

def get_date(timezone):
    """ Return start and end dates for calling the API """

    now = time.now().in_location(timezone)
    time_duration = "%sh" % (24 * TIMEFRAME)
    start_date = (now - time.parse_duration(time_duration))

    return (start_date.format("2006-01-02T15:04:05.999"), now.format("2006-01-02T15:04:05.999"))

def get_random_index(total_results):
    """ return a random number between 0 and all of the results returned 
        sometimes the total results is more than the value returned due to pagination
        so we should make the lesser of the 2 numbers the max value (minus 1 because
        the number function is inclusive)
    """

    max = NUM_CVE_TO_GET if NUM_CVE_TO_GET < total_results else math.floor(total_results)
    return random.number(0, max - 1)

def parse_cve(vuln):
    """ take a json formated CVE and return a dict of it """

    cve_to_display = {}
    cve_to_display["title"] = vuln["id"][4:]
    english_description = [des for des in vuln["descriptions"] if des["lang"] == "en"][0]
    cve_to_display["description"] = english_description["value"] if len(english_description["value"]) < MAX_DESCRIPTION_LEN else "%s ..." % english_description["value"][:MAX_DESCRIPTION_LEN]

    if "metrics" in vuln.keys():
        if "cvssMetricV31" in vuln["metrics"].keys():
            cve_to_display["base_severity"] = vuln["metrics"]["cvssMetricV31"][0]["cvssData"]["baseSeverity"]
        else:
            cve_to_display["base_severity"] = "NONE"
    else:
        cve_to_display["base_severity"] = "NONE"
    return cve_to_display

def get_root_child(cves, keyword):
    """ take a cve and return the appropriate display widget """

    if cves == "" or "totalResults" not in cves.keys():
        return render.Marquee(
            scroll_direction = "vertical",
            height = 30,
            child = render.WrappedText(content = "Error querying CVE API"),
        )

    if cves["totalResults"] == 0:
        return render.Marquee(
            scroll_direction = "vertical",
            height = 30,
            child = render.WrappedText(content = "No CVEs for %s in the last %s days" % (keyword, TIMEFRAME)),
        )
    else:
        # so we aren't seeing the same CVE every time, randomize the index of the CVE displayed
        random_index = get_random_index(cves["totalResults"])

        cve_to_display = parse_cve(cves["vulnerabilities"][random_index]["cve"])
        base_severity = cve_to_display["base_severity"]

        return render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = 64,
                            height = 10,
                            color = SEV_COLORS[base_severity],
                            child = render.Text(content = cve_to_display["title"], font = "Dina_r400-6", color = "#000"),
                        ),
                    ],
                ),
                render.Marquee(
                    scroll_direction = "vertical",
                    height = 20,
                    child = render.WrappedText(" \n%s" % cve_to_display["description"], font = "tom-thumb"),
                ),
            ],
        )

def main(config):
    keyword = humanize.url_encode(config.get("keyword", ""))
    timezone = config.get("timezone") or "America/New_York"

    start_date, end_date = get_date(timezone)
    cves = get_cves(BASE, start_date, end_date, keyword)

    return render.Root(
        show_full_animation = True,
        delay = 100,
        child = get_root_child(cves, keyword),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "keyword",
                name = "Keyword",
                desc = "Keyword to search CVEs for",
                icon = "key",
            ),
        ],
    )
