"""
Applet: Capital Bikeshare
Summary: Bikeshare status in DC
Description: Reports the number of eBikes and normal bikes available at a given dock in DC.
Author: abrahamrowe
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    defaultStationName = "Montello Ave & Holbrook Terr NE"
    stationName = config.str("bikeShareName", defaultStationName)
    stationID = "c645ddde-0156-47ab-9616-3121f541a6f0"
    stationInformationURL = "https://gbfs.capitalbikeshare.com/gbfs/en/station_information.json"
    stationStatusURL = "https://gbfs.lyft.com/gbfs/1.1/dca-cabi/en/station_status.json"

    stationInformation = http.get(stationInformationURL, ttl_seconds = 240)  # cache for 4 minutes
    if stationInformation.status_code != 200:
        fail("Capital Bikeshare request failed with status %d", stationInformation.status_code)

    # for development purposes: check if result was served from cache or not
    if stationInformation.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Capital Bikeshare API.")

    stationStatus = http.get(stationStatusURL, ttl_seconds = 240)  # cache for 4 minutes

    if stationStatus.status_code != 200:
        fail("Capital Bikeshare request failed with status %d", stationInformation.status_code)

    # for development purposes: check if result was served from cache or not
    if stationStatus.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Capital Bikeshare API.")

    # identify the correct station_id

    for item in stationInformation.json()["data"]["stations"]:
        if item["name"] == stationName:
            stationID = item["station_id"]

    numberBikes = 0
    numberEBikes = 0
    for item in stationStatus.json()["data"]["stations"]:
        if item["station_id"] == stationID:
            numberBikes = item["num_bikes_available"]
            numberEBikes = item["num_ebikes_available"]

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 16,
                    color = "#FF6961",
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.WrappedText(stationName, color = "#000000", font = "5x8"),
                        ],
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text("Bikes: " + str(int(numberBikes)), font = "tb-8"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text("eBikes: " + str(int(numberEBikes)), font = "tb-8"),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "bikeShareName",
                name = "Bikeshare Dock Name",
                desc = "Go to https://account.capitalbikeshare.com/map and enter the dock name exactly as it is displayed on the site. For example, 'Walter Reed Dr & 8th St S'.",
                icon = "bicycle",
            ),
        ],
    )
