load("bsoup.star", "bsoup")
load("http.star", "http")
load("render.star", "render")

TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64

PARTY_COLOR_DICT = {
    "CDU/CSU": "#ffffff",
    "SPD": "#EB0000",
    "GRÜNE": "#66B032",
    "FDP": "#FFED00",
    "DIE LINKE": "#FF00FF",
    "AfD": "#0000FF",
    "FW": "#888888",
    "BSW": "#FFA500",
    "Sonstige": "#888888",
}

SHORT_PARTY_NAME_DICT = {
    "CDU/CSU": "CDU",
    "SPD": "SPD",
    "GRÜNE": "Grüne",
    "FDP": "FDP",
    "DIE LINKE": "Linke",
    "AfD": "AfD",
    "FW": "FW",
    "BSW": "BSW",
    "Sonstige": "Sonstige",
}

def main():
    # Example usage:
    html_text = http.get("https://www.wahlrecht.de/umfragen/").body()
    data = extract_data(html_text)
    showing_data = get_representative_data(data)
    # print(showing_data)

    return render.Root(
        render.Row(
            [
                render.Column(main_align = "center", expanded = True, children = [
                    render.Padding(
                        pad = (0, 0, 3, 0),
                        child =
                            render.PieChart(
                                colors = [PARTY_COLOR_DICT[party["name"]] for party in showing_data["results"]],
                                weights = [party["percentage"] for party in showing_data["results"]],
                                diameter = 16,
                            ),
                    ),
                ]),
                render.Column([
                    render.Text(get_display_line_for_party(party), font = "tom-thumb", color = PARTY_COLOR_DICT[party["name"]])
                    for party in showing_data["results"]
                ], main_align = "center", expanded = True),
            ],
        ),
    )

def get_display_line_for_party(party):
    space = 11
    name = SHORT_PARTY_NAME_DICT[party["name"]]
    percentage = str(party["percentage"]) + "%"
    spaces = space - visible_string_length(name) - len(percentage)
    return name + " " + (" " * (spaces - 1)) + percentage

def visible_string_length(s):
    special_chars = ["ü", "ä", "ö"]
    length = len(s)
    for char in special_chars:
        count = s.count(char)
        length -= count
    return length

def get_representative_data(results):
    # gets the most recent poll
    latest = results[0]
    for result in results:
        # compare year, month, day
        if result["date"]["year"] > latest["date"]["year"]:
            latest = result
        elif result["date"]["year"] == latest["date"]["year"] and result["date"]["month"] > latest["date"]["month"]:
            latest = result
        elif result["date"]["year"] == latest["date"]["year"] and result["date"]["month"] == latest["date"]["month"] and result["date"]["day"] > latest["date"]["day"]:
            latest = result

    # sort parties by percentage
    latest["results"] = sorted(latest["results"], key = lambda x: x["percentage"], reverse = True)

    # remove below 5% and Sonstige
    latest["results"] = [result for result in latest["results"] if can_be_float(result["percentage"]) and float(result["percentage"]) >= 5 and result["name"] != "Sonstige"]

    # if a percentage is X.0 then make it an integer
    for result in latest["results"]:
        percentage = result["percentage"]
        if can_be_float(percentage) and float(percentage) % 1 == 0:
            result["percentage"] = int(percentage)

    return latest

def parse_date(date_str):
    parts = date_str.strip().split(".")
    return {
        "day": int(parts[0]),
        "month": int(parts[1]),
        "year": int(parts[2]),
    }

# Main extraction function.
def extract_data(html_text):
    # Parse the HTML document.
    doc = bsoup.parseHtml(html_text)

    results = []

    # Try to find the table with the polling data

    # Let's try to find the header row with "Institut"
    headers = doc.find_all("tr")
    p = 0

    for head in headers:
        row = head.child("th")
        if not row:
            continue
        row_title = row.get_text()
        if row_title == "Erhebung":
            continue
        elif row_title == "Institut":
            cols = row.parent().find_all("th", {"class": "in"})
            for j in range(0, len(cols)):
                results.append({
                    "name": cols[j].child("a").get_text(),
                })
        elif row_title == "Veröffentl.":
            cols = row.parent().find_all("span", {"class": "li"})
            i = 0
            for col in cols:
                date = col.get_text()
                date = parse_date(date)
                results[i]["date"] = date
                i += 1
        else:
            party_name = row_title
            cols = row.parent().find_all("td")
            i = 0

            # Prepare the results array for the current party in all poll creators
            if p == 0:
                for j in range(0, len(results)):
                    results[j]["results"] = []

            # Add the distribution to the current party
            for col in cols:
                if col.attrs().get("class") == "w":
                    continue
                percentage_string = col.get_text()
                percentage_string = percentage_string.replace(",", ".").replace("%", "").replace(" ", "")
                if percentage_string == "" or percentage_string == "–":
                    continue
                else:
                    results[i]["results"].append({"name": party_name, "percentage": percentage_string})
                    i += 1
            p += 1

    return results

def can_be_float(s):
    return type(s) == "string" and s.replace(".", "", 1).isdigit()
