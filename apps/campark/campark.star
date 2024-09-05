"""
Applet: CamPark
Summary: Cambridge Car Park Spaces
Description: Real Time spaces in Cambridge UK Car Parks
Author: derekllaw

Uses Smart Cambridge parking API
"""

load("http.star", "http")
load("render.star", "render")
load("secret.star", "secret")

# constants
SECRET = "AV6+xWcEWfKUGe/P0Ndmq+DM9dPl/v//QNSfFjI+XkhQtHl59qJzWkT0cGkKVCbfpNsZQphvxjuG6jtmPYxsd1qBotcLqc6KaUCUDsUOqmhV1vtnpwel5GDk7EgzpLd+1lh6uHgiHbRCC/Sz0rJe75tqK7rLBW5cZovC8b3JSKaaeYWukYXWrJXp7CCU/A=="
API_BASE = "https://smartcambridge.org/api/v1/parking/"
SCREEN_WIDTH = 64
BIG_FONT = "5x8"
SMALL_FONT = "tom-thumb"
PARK = "car_park"
RIDE = "park_and_ride"

def render_fixed(n):
    """ Render number in at least 3 characters

    Args:
        n: number

    Returns:
        padded string
    """
    text_num = "%d" % n
    pad = ""
    if len(text_num) == 2:
        pad = " "
    elif len(text_num) == 1:
        pad = "  "
    return (pad + text_num)

def render_row(capacity, free, name, font):
    """ Render row with free spaces in green, or red if less than 10% free

    Args:
        capacity: total spaces
        free: free spaces
        name: text
        font: font
    """
    free_colour = "#0F0" if free > (capacity // 10) else "F00"
    free_text = render_fixed(free)
    return render.Row(children = [
        render.Text(free_text, color = free_colour, font = font),
        render.Marquee(child = render.Text(name, font = font), width = (SCREEN_WIDTH - len(free_text) * 5)),
    ])

def main(config):
    """ Entry point

    Args:
        config: config object

    Returns:
        render root
    """

    # Collect output rows here
    rows = []

    api_token = secret.decrypt(SECRET) or config.get("api_token")

    # check for missing api_token
    if not api_token:
        rows.append(render.Text("No key found"))
    else:
        headers = {"Authorization": "Token %s" % api_token}

        # fetch list of parking ids
        response = http.get(API_BASE, headers = headers, ttl_seconds = 60 * 60 * 24)  # this list is unlikely to change
        if response.status_code != 200:
            rows.append(render.Text("API error %d" % response.status_code))
        else:
            park_list = response.json()["parking_list"]
            count = {PARK: 0, RIDE: 0}

            for park in park_list:
                count[park["parking_type"]] += 1

            for parking_type in [PARK]:
                font = BIG_FONT if count[parking_type] <= 5 else SMALL_FONT
                for park in park_list:
                    if park["parking_type"] == parking_type:
                        api_latest = "{}/latest/{}/".format(API_BASE, park["parking_id"])

                        response = http.get(api_latest, headers = headers, ttl_seconds = 60 * 15)  # 15 minutes between updates
                        if response.status_code != 200:
                            rows.append(render.Text("API error %d" % response.status_code))
                        else:
                            data = response.json()
                            rows.append(render_row(data["spaces_capacity"], data["spaces_free"], park["parking_name"].title(), font))

    return render.Root(
        child = render.Column(rows, expanded = True, main_align = "space_around"),
        show_full_animation = True,
    )
