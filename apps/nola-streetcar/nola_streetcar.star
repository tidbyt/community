"""
Applet: NOLA Streetcar Arrivals
Summary: Shows next arrival time
Desc: Displays the next streetcar arrival time for a selected New Orleans RTA route, direction, and stop ID. Find your stop ID using the RTA website's map tools.
Author: Cline (Generated)
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Base URLs
STOPS_URL = "https://www.norta.com/RTAStops"
PREDICTIONS_URL = "https://www.norta.com/RTAPredictions"

# Hardcoded Route Info (Ideally fetched dynamically)
ROUTES = {
    "12": "St. Charles",
    "46": "Rampart-Loyola",
    "47": "Canal-Cemeteries",
    "48": "Canal-City Park/Museum",
    "49": "Loyola-Riverfront",
}

# Hardcoded Direction Info
DIRECTIONS = {
    "0": "Outbound",
    "1": "Inbound",
}

# Route Colors
ROUTE_COLORS = {
    "12": "#00FF00",  # Green
    "46": "#800080",  # Purple
    "47": "#FFFF00",  # Yellow
    "48": "#FF0000",  # Red
    "49": "#4169E1",  # Royal Blue
    "DEFAULT": "#FFFFFF",  # White for unknown
}

# Arrival Time Colors (Matching the NYC example image)
ARRIVAL_TIME_COLOR = "#FFCC00"  # Yellow/Orange
DIRECTION_TEXT_COLOR = "#FFFFFF"  # White
DIVIDER_COLOR = "#666666"  # Grey

# Helper function to parse the arrival time string
def parse_arrival_time(eta_str):
    if not eta_str or eta_str == "--":
        return "None"

    # Handle "Due" case first
    if eta_str.strip().upper() == "DUE":
        return "now"

    img_pos = eta_str.find("<img")
    if img_pos != -1:
        time_part = eta_str[:img_pos].strip()

        # Handle "0 min(s)" case
        if time_part.startswith("0 min"):
            return "now"

        # Replace "mins" with "min"
        if time_part.endswith(" mins"):
            return time_part[:-1]  # Remove the 's'
        else:
            return time_part  # Return as is if it doesn't end with " mins"
    else:
        # Handle cases where it might just be a number (though API seems to include units)
        if eta_str.strip() == "0":
            return "now"
        return eta_str.strip()

def get_schema():
    # Build route_options using a loop instead of list comprehension
    route_options = []
    for k, v in ROUTES.items():
        route_options.append(schema.Option(display = v + " (%s)" % k, value = k))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "route_id",
                name = "Streetcar Line",
                desc = "Select the streetcar line.",
                icon = "train",
                default = route_options[0].value,
                options = route_options,
            ),
            schema.Text(
                id = "stop_id",
                name = "Stop ID",
                desc = "Enter the specific Stop ID (e.g., 5514). Find IDs on the NORTA website.",
                icon = "mapPin",  # Changed from location_dot
            ),
        ],
    )

def main(config):
    route_id = config.get("route_id", "12")
    stop_id = config.get("stop_id")

    if not stop_id:
        return render.Root(
            child = render.Text("Please configure Stop ID"),
        )

    # --- Get Predictions (Both Directions) ---
    inbound_arrival_time = "N/A"
    outbound_arrival_time = "N/A"  # Only need the first outbound time for the new layout

    # Fetch Inbound (directionID=1)
    preds_params_in = {
        "routeID": route_id,
        "stopID": stop_id,
        "directionID": "1",
    }
    preds_resp_in = http.get(PREDICTIONS_URL, params = preds_params_in)

    if preds_resp_in.status_code == 200:
        preds_data_in = preds_resp_in.json()
        prediction_in = None
        if type(preds_data_in) == "list" and len(preds_data_in) > 0:
            prediction_in = preds_data_in[0]
        elif type(preds_data_in) == "dict":
            prediction_in = preds_data_in

        if prediction_in:
            eta1_in_str = prediction_in.get("etA1")
            inbound_arrival_time = parse_arrival_time(eta1_in_str)
        else:
            inbound_arrival_time = "No data"
            print("Unexpected format or empty data for inbound predictions: %s" % preds_data_in)
    else:
        inbound_arrival_time = "Err %d" % preds_resp_in.status_code
        print("Failed to fetch inbound predictions: %d" % preds_resp_in.status_code)

    # Fetch Outbound (directionID=0)
    preds_params_out = {
        "routeID": route_id,
        "stopID": stop_id,
        "directionID": "0",
    }
    preds_resp_out = http.get(PREDICTIONS_URL, params = preds_params_out)

    if preds_resp_out.status_code == 200:
        preds_data_out = preds_resp_out.json()
        prediction_out = None
        if type(preds_data_out) == "list" and len(preds_data_out) > 0:
            prediction_out = preds_data_out[0]
        elif type(preds_data_out) == "dict":
            prediction_out = preds_data_out

        if prediction_out:
            eta1_out_str = prediction_out.get("etA1")
            outbound_arrival_time = parse_arrival_time(eta1_out_str)

            # If first is None or not useful, try the second arrival time
            if outbound_arrival_time == "None":
                eta2_out_str = prediction_out.get("etA2")
                outbound_arrival_time = parse_arrival_time(eta2_out_str)
        else:
            outbound_arrival_time = "No data"
            print("Unexpected format or empty data for outbound predictions: %s" % preds_data_out)
    else:
        outbound_arrival_time = "Err %d" % preds_resp_out.status_code
        print("Failed to fetch outbound predictions: %d" % preds_resp_out.status_code)

    # --- Render Output (NYC Subway Style) ---
    route_color = ROUTE_COLORS.get(route_id, ROUTE_COLORS["DEFAULT"])

    # Route indicator (Square + Number)
    indicator_size = 11  # Reduced size
    route_indicator = render.Box(
        width = indicator_size,
        height = indicator_size,
        child = render.Stack(
            # Stack layers children. Place Text directly on top of Box.
            children = [
                render.Box(width = indicator_size, height = indicator_size, color = route_color),  # Background square
                # Wrap Text in Padding for centering adjustment
                render.Padding(
                    pad = (1, 1, 2, 1),  # Values T, R, B, L - Adjusted for 11x11 box and 5x8 font
                    child = render.Text(
                        content = route_id,
                        font = "5x8",  # Reduced font for number inside indicator
                        color = "#000000" if route_color == ROUTE_COLORS["47"] else "#FFFFFF",
                    ),
                ),
            ],
        ),
    )

    # Function to create one section (Inbound or Outbound)
    def create_section(direction_text, arrival_time):
        return render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                route_indicator,
                render.Column(
                    cross_align = "center",  # Changed from "end" to "center"
                    children = [
                        render.Text(content = direction_text, font = "tom-thumb", color = DIRECTION_TEXT_COLOR),  # Smaller font for direction
                        render.Text(content = arrival_time, font = "5x8", color = ARRIVAL_TIME_COLOR),  # Reduced font for time
                    ],
                ),
            ],
        )

    # Create the two sections
    inbound_section = create_section("Inbound", inbound_arrival_time)
    outbound_section = create_section("Outbound", outbound_arrival_time)

    # Divider line - Use render.Box
    divider = render.Box(width = 64, height = 1, color = DIVIDER_COLOR)

    # Final layout using a Column
    final_layout = render.Column(
        children = [
            inbound_section,
            divider,
            outbound_section,
        ],
    )

    # Wrap final_layout in Padding for vertical centering
    return render.Root(
        child = render.Padding(
            pad = (4, 0, 5, 0),  # T, R, B, L - Calculated for vertical centering
            child = final_layout,
        ),
    )
