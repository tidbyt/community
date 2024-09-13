"""
Applet: Haikubox Linker
Summary: Displays Haikubox bird data
Description: This app uses the convenient Haikubox API to display a list of bird species detected and how many times they were heard today on your Tidbyt device.
Author: jachansky
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Use API request to gather data on birds spotted today
def fetchBirdData(serial_code, date):
    print(serial_code)
    print(date)

    # API Request
    url = "https://api.haikubox.com/haikubox/" + serial_code + "/daily-count?date=" + date
    response = http.get(url)

    # If request successful
    if response.status_code == 200:
        bird_data = json.decode(str(response.body()))

        # Create a list with each bird count as a string formatted like "<bird species>: <number of detections>"
        species_counts = []
        for bird_info in bird_data:
            bird = bird_info["bird"]
            count = bird_info["count"]
            line = bird + ": " + str(count)
            species_counts.append(line)
        return species_counts
    else:
        return ["No data found"]

def main(config):
    # Assign values if None rather than default
    if config.str("speed") == None:
        speed = 200
    else:
        speed = int(config.str("speed"))

    if config.str("serial_code") == None:
        serial_code = "0000"
    else:
        serial_code = config.str("serial_code")

    now = time.now()
    date = now.format("2006-01-02")
    species_counts = fetchBirdData(serial_code, str(date))

    spaced_counts = []
    for species in species_counts:
        spaced_counts.append(species)
        spaced_counts.append(" ")

    # Extra space appended after each species to create two newlines
    formatted_counts = "\n".join(spaced_counts)

    # Return the render output
    return render.Root(
        delay = speed,
        child = render.Marquee(
            height = 32,
            child = render.WrappedText(
                content = formatted_counts,
                width = 64,
                font = "tom-thumb",
            ),
            scroll_direction = "vertical",
            offset_start = 1,
            offset_end = 32,
            # offset_end was giving me issues and removing it fixed it,
            # offset_end = len(species_counts) * 18,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serial_code",
                name = "Device Serial Code",
                desc = "Enter the serial code of your device (ex: 1000000066e59043)",
                icon = "crow",
                default = "0000",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "The speed at which the text vertically pans",
                icon = "gauge",
                default = "100",
                options = [
                    schema.Option(
                        display = "fast",
                        value = "100",
                    ),
                    schema.Option(
                        display = "slow",
                        value = "300",
                    ),
                ],
            ),
        ],
    )
