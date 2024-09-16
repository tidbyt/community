# https://developer.trimet.org/ws_docs/arrivals2_ws.shtml

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_APP_ID = "PLEASE_REGISTER_WITH_TRIMET"
DEFAULT_LOC_ID = 5103
CACHE_TIME_IN_SECONDS = 30
BUS_COLOR = "#0E4C8C"

TRIMET_LOGO = base64.decode("""
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
""")

def main(config):
    trimet_app_id = config.str("trimet_app_id", DEFAULT_APP_ID)
    loc_id = config.str("loc_id", DEFAULT_LOC_ID)
    trimet_api_url = "https://developer.trimet.org/ws/v2/arrivals?locIDs=%s&appID=%s" % (loc_id, trimet_app_id)

    trimet_data = http.get(trimet_api_url, ttl_seconds = CACHE_TIME_IN_SECONDS)
    stop_rows = []

    if trimet_data.status_code != 200:
        print("Trimet request failed with status %d" % trimet_data.status_code)
    else:
        print("Cache hit!" if (trimet_data.headers.get("Tidbyt-Cache-Status") == "HIT") else "Cache miss!")

        location_name = "%s - %s" % (trimet_data.json()["resultSet"]["location"][0]["desc"], trimet_data.json()["resultSet"]["location"][0]["dir"])

        stop_rows.append(
            render.Row(
                children = [
                    render.Marquee(
                        child = render.Text(location_name),
                        width = 64,
                        offset_start = 32,
                        offset_end = 32,
                        align = "start",
                    ),
                ],
            ),
        )

        if (len(trimet_data.json()["resultSet"]["arrival"]) > 0):
            stop_rows.append(add_stop_row(trimet_data.json()["resultSet"]["arrival"][0]))

            if (len(trimet_data.json()["resultSet"]["arrival"]) > 1):
                stop_rows.append(add_stop_row(trimet_data.json()["resultSet"]["arrival"][1]))

    return render.Root(
        child = render.Row(
            children = [
                render.Image(src = TRIMET_LOGO),
                render.Column(
                    children = stop_rows,
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
        ),
    )

def add_stop_row(row):
    # trimet sends data in milliseconds since epoch, convert to seconds
    # estimated time is more accurate than scheduled time
    route = str(int(row["route"]))

    arrival_in_minutes = calculate_arrival_time_in_minutes(time.from_timestamp(int(row["estimated" if ("estimated" in row) else "scheduled"] * 0.001)))

    return render.Row(
        children = [
            render.Circle(
                color = BUS_COLOR,
                diameter = 10,
                child = render.Marquee(
                    child = render.Text(route),
                    align = "center",
                    width = 10,
                    offset_start = 32,
                    offset_end = 32,
                ),
            ),
            render.Marquee(
                child = render.Text("%s" % arrival_in_minutes),
                align = "start",
                width = 15,
                offset_start = 32,
                offset_end = 32,
            ),
        ],
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
    )

def calculate_arrival_time_in_minutes(arrival):
    delta_arrival = arrival - time.now()

    if (delta_arrival.minutes < 10):
        return " %s" % int(delta_arrival.minutes)
    else:
        return "%s" % int(delta_arrival.minutes)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "trimet_app_id",
                name = "Trimet APP ID",
                desc = "Register here: https://developer.trimet.org/appid/registration/",
                icon = "user",
            ),
            schema.Text(
                id = "loc_id",
                name = "Trimet Stop ID",
                desc = "The Stop ID that you would like to track with the app.",
                icon = "user",
            ),
        ],
    )
