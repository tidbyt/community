load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")

# Fetch data from your deployed Lambda API
def fetch_data():
    res = http.get("https://up8y1e1xae.execute-api.us-east-1.amazonaws.com/lax-departures")
    if res.status_code != 200:
        return None

    data = json.decode(res.body())
    if type(data.get("departures", None)) != "list":
        return None

    return data["departures"][:6]  # First 6 flights max

# Build one page of output
def make_page(flights, page_index, total_pages):
    rows = []

    # Header row with left and right components
    rows.append(render.Row(children = [
        render.Text("Next From LAX", font = "tb-8", color = "#fcf7c5"),
        render.Text(" {}/{}".format(page_index + 1, total_pages), font = "5x8", color = "#666666"),
    ]))

    # Add flight rows
    for flight in flights:
        status = flight.get("status", "").lower()

        if "canceled" in status:
            time_color = "#ff5555"  # red
        elif flight.get("is_past"):
            time_color = "#888888"  # gray
        else:
            time_color = "#a8ffb0"  # light green

        rows.append(
            render.Row(children = [
                render.Text(flight["scheduled_time"], font = "5x8", color = time_color),
                render.Text(" {} {}".format(flight["airline"], flight["destination"]), font = "5x8"),
            ]),
        )

    return render.Column(children = rows)

# Main entrypoint
def main():
    flights = fetch_data()
    if flights == None:
        return render.Root(child = render.Text("Error", font = "5x8", color = "#ff0000"))

    pages = []
    total_pages = (min(len(flights), 6) + 2) // 3  # ceil(len / 3)

    for page_index, i in enumerate(range(0, min(len(flights), 6), 3)):
        page_flights = flights[i:i + 3]
        page = make_page(page_flights, page_index, total_pages)

        # Repeat page N times to control timing
        for _ in range(200):
            pages.append(page)

    return render.Root(
        child = render.Sequence(children = pages),
    )
