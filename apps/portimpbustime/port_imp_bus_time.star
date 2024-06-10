"""
Applet: Port Imp Bus Time
Summary: Shows buses for stop 21923
Description: Shows the next buses for bus stop 21923 in Port Imperial NJ.
Author: jagmitbhatthal
"""

load("http.star", "http")
load("render.star", "render")

BUS_TIMES_URL = "https://fetch-bus-times-7a42a83f6367.herokuapp.com/bus_times"

def main():
    response = http.get(BUS_TIMES_URL, ttl_seconds = 60)
    bus_times = str(response.body())

    # Remove any leading and trailing quotation marks
    bus_times = bus_times.strip('"')

    # Replace \n\n with two newlines and \n with one newline
    bus_times = bus_times.replace("\\n\\n", "\n\n").replace("\\n", "\n")

    # Ensure there are no trailing quotation marks by explicitly removing any remaining ones
    if bus_times and bus_times[-1] == '"':
        bus_times = bus_times[:-1]

    return render.Root(
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            child = render.WrappedText(
                content = bus_times,
                color = "#fa0",
                width = 64,
            ),
            offset_start = 16,
            offset_end = 32,
        ),
        delay = 200,
        show_full_animation = True,
    )

# Ensure the function is called in the script
main()
