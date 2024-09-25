"""
Applet: Solar Powerwall
Summary: Tesla Solar Powerwall Mon
Description: Display the whole energy flow for solar panels, powerwall, grid and house 
Author: lcervo (based on jweier & marcusb's Tesla Solar applet)
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

DUMMY_DATA = {
    "response": {
        "solar_power": 937,
        "percentage_charged": 87.59770786188773,
        "battery_power": 300,
        "load_power": 1567,
        "grid_status": "Active",
        "grid_power": 0,
        "generator_power": 0,
        "timestamp": "2024-09-24T18:27:11+01:00",
    },
}

TESLA_AUTH_URL = "https://auth.tesla.com/oauth2/v3/token"
URL = "https://owner-api.teslamotors.com/api/1/energy_sites/{}/live_status?language=en"

CACHE_TTL = 25200

BATTERY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAJCAYAAADtj3ZXAAAAAXNSR0IArs4c6QAAAK5JREFUKFN1
UVsSxCAMAnv/46ina9jJo5O6M/UrGiAQCQAmiRAkgCDgNb0SBIACxOyRdIC/gk4cg44rWrb6lEho
EmaW+BA1iZeTc+Kj2vUpJJnmmjm7J78nfLsI8pwBoDxv5OiMmejPR9mWbq21o0mTaXBkhoz15Tje
Zaa1d4DoF14jFlZLbIW3WomaSWtPUDxtp5ec3LwzzrEjB92+cb7cOvmxz/r/+t5B+rfH+QF3QH+b
d75IOgAAAABJRU5ErkJggg==
""")

CLOUDS = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAICAYAAADN5B7xAAAAAXNSR0IArs4c6QAAAKRJREFUKFNd
UNsRBCEIS5rDasRaxGrcLY4bwL3bOT8cXkkIJABpzQEgvsjdM83HKIBwOK59kU3EdSjcecrf2QM/
JHCYGSjSXLVnk3QUeer8VIKKgM0HMHr232MZnyFVzWYCgqZUNFltGbSPtyOYLYDh4WZ6CiYRSRc9
1ovCS3LZwr537pUKtUuZlibe+8g46nMu3NdmOXoAf4eJy9WNib13kR7ABwQlU4HKN3e7AAAAAElF
TkSuQmCC
""")

SUN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAICAYAAADN5B7xAAAAAXNSR0IArs4c6QAAAJJJREFUKFNV
UEsWAyEMAvfa+x+zzrrSB3HsdJdH+CUkgDUhDnJNiSAEwLgItC5qQgayzcKiCzKj6KUIC0LrGQq+
nZxS3HIpmRLThrN+u70k1qXDi5PlnXS6q8XM4LqoilWqBZbA4aFqrUm1AeYgvly9+id8z5+H0W18
jgkwofYQO5k7+f8GN3g7Utw/Om89+H7nF6BfW+6PI0ouAAAAAElFTkSuQmCC
""")

SOLAR_PANEL = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAPCAYAAADtc08vAAAAAXNSR0IArs4c6QAAAVZJREFUOE+F
U0t2gzAMHDkHgqwgB4KcqXCgmBVwoFrtSLJDX/tevUhAvxnNGAGPAND29ytg6fgRKEvbYfj/EwBX
sNr05wDlgToxg5Ogp5DoYFbUa+IIKj3Vot2wRtxKcWwz+uGjrcfomSfL2YLvZtVuWBpbPux5Rj9G
TNT04kBJiYR+LujoS4sye2wTeg5lue0k2LcZSZLYSq4wULSo8EVcAYK1Z9OePL3WwR2+0f0sqv0Y
e8bQc5vQjWsM8+YjzzbAsK6GllL0PqzN5yNP6B9ro83q40XhYPuz3QcIUJsNwtYSnK+3eNXTunul
3xiE9bbzlZhPu2hB79NNqms2gM3u8VsR932Bmm1Odc8TUrrRijAvVqgDSNtzij0/cX8s9l7vPu28
STLxqnVSiup9JJKzZzHRGTPPSVYVR366dVff2UPvTRBr9hvpdz9w67fArCl/8f079wWvrsgLTGBJ
QQAAAABJRU5ErkJggg==
""")

HOUSE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAPCAYAAADtc08vAAAAAXNSR0IArs4c6QAAAVZJREFUOE9l
U0GSwjAMs9Lz7k+AG33Slh+VJ8GeylO419qRnYR0ttPJhNqWZckAZsY4LJ/hfp7vBM2254++foK1
CMZI/4QGtMu8cnvcIOS8Lz231VRImJBGFpf5HgXkTtKslILzdeXrd4ESI39o3GmrxWle+XrcQDoB
RFd3skxIkIGJggdakfCsxQXRrYlDJ1GAZNc0CYBManNG4pTF/ibFAV86aXQnyoSzWEpYmgVHdd6e
C5zOgtJB+Y4UK99EI9OZBNtFlFLhFugKj9aOsksTOicUnK6rcGHuexia3Y+70PZixHMyCEGitIKY
TwDDkvzfrbQwAKpDfcPCtlA++XoANsdhpRaoAXflJtt+7PK6ZgmDQxftwVSgrY4SLViwjTGq07k4
bQSrlqUjYiPw1jFHUGz4L4SFolVHODDo9ibn2EyNlIYnBxWY3vY17skxhdKvQZOq1x+E4fgQaS4O
uwAAAABJRU5ErkJggg==
""")

GRID = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAV9JREFUOE9d
k9uWxSAMQoP+/ycrZ3Yubdf40HbZSICgIiIUCuebZ8SxHa5viV2HHKG1NLXBXp8NuYpmXV9vLc4U
SCjuPV6796wQp23e+VV4qk7n2ntRXLyAv9eGQUG+zeRa3ar+w9SHA/RR2MfSlhOlAfKIQtf2Qmgv
aqp7JO3U2Z39sKiGdBZ6qbYUW9K91+sBQKRjFZXIWi0VEQfoKlSsUPgevA4YnY+RHAQEtshfO0cT
SHqoj4SxZIrK4poCdtIsbU3atPssfp1TEh6nazhJ1+fWJGavc9KReAuSWsnuFshDv1IGXqWJABXF
ni5Fe6U+CudfppBTZAQ/1p7ofiUw7+oyjQHBNQzsvGWg8KctwBX901g0ienkgUllSok3zJDXBr46
eyzwzo6FnXmv0CkuJuJYG4kJxSAchwBpv+63urlmgJH4DNRkZ24juU+KeQlq7nPFvmOe8aVE7syf
Xz9QUiESRvuC3gAAAABJRU5ErkJggg==
""")

RED_COLOR = "#ff0000"
LIGHT_RED_COLOR = "#ff9999"
GREEN_COLOR = "#00ff00"
LIGHT_GREEN_COLOR = "#99ff99"

def get_access_token(refresh_token, site_id):
    #Try to load access token from cache
    access_token_cached = cache.get(site_id)

    if access_token_cached != None:
        print("Hit! Using cached access token " + access_token_cached)
        return {"status_code": "Cached", "access_token": str(access_token_cached)}
    else:
        print("Miss! Getting new access token from Tesla API.")

        auth_rep = http.post(TESLA_AUTH_URL, json_body = {
            "grant_type": "refresh_token",
            "client_id": "ownerapi",
            "refresh_token": refresh_token,
            "scope": "openid email offline_access",
        })

        #Check the HTTP response code
        if auth_rep.status_code != 200:
            return {"status_code": str(auth_rep.status_code), "access_token": "None"}
        else:
            access_token = auth_rep.json()["access_token"]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(site_id, access_token, ttl_seconds = CACHE_TTL)
            return {"status_code": str(auth_rep.status_code), "access_token": str(access_token)}

def get_grid_panel(value):
    is_negative = value.startswith("-")
    if is_negative:
        value = value.replace("-", "")

    return render.Stack(
        children = [
            render.Padding(
                pad = (0, 3, 0, 0),
                child = render.Image(src = GRID),
            ),
            render.Padding(
                pad = (16, 14, 0, 0),
                child = render.Text(
                    color = GREEN_COLOR if is_negative else RED_COLOR,
                    content = value,
                    font = "tom-thumb",
                ),
            ) if value != "0" else None,
        ],
    )

def get_solar_panel(value):
    return render.Stack(
        children = [
            render.Padding(
                pad = (15, 0, 0, 0),
                child = render.Image(src = SOLAR_PANEL),
            ),
            render.Padding(
                pad = (16, 0, 0, 0),
                child = render.Image(src = SUN if value != "0" else CLOUDS),
            ),
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text(
                    content = value,
                    font = "tom-thumb",
                ),
            ) if value != "0" else None,
        ],
    )

def get_battery_panel(percentage, power):
    is_negative = power.startswith("-")
    if is_negative:
        power = power.replace("-", "")

    pad = 0
    if percentage == 100:
        pad = 0
    elif percentage >= 10:
        pad = 2
    else:
        pad = 4
    return render.Stack(
        children = [
            render.Padding(
                pad = (1 + pad, 2, 0, 0),
                child = render.Text(
                    content = str(percentage),
                    font = "tom-thumb",
                ),
            ),
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Image(src = BATTERY),
            ),
            render.Padding(
                pad = (16, 5, 0, 0),
                child = render.Text(
                    color = GREEN_COLOR if is_negative else RED_COLOR,
                    content = power,
                    font = "tom-thumb",
                ),
            ) if power != "0" else None,
        ],
    )

def get_home_panel(value):
    return render.Stack(
        children = [
            render.Padding(
                pad = (12, 0, 0, 0),
                child = render.Image(src = HOUSE),
            ),
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text(
                    content = value,
                    font = "tom-thumb",
                ),
            ) if value != "0" else None,
        ],
    )

def main(config):
    print("-------Starting new update-------")

    site_id = humanize.url_encode(config.str("site_id", ""))
    refresh_token = config.str("refresh_token")
    error_in_http_calls = False
    error_details = {}
    body = ""
    data = {}

    if refresh_token and site_id:
        url = URL.format(site_id)
        print("Refresh Token: " + refresh_token)
        print("Site ID: " + site_id)
        print("Tesla Auth URL: " + TESLA_AUTH_URL)
        print("Tesla Data URL: " + url)

        #Generate a new access token from the refresh token
        access_token = get_access_token(refresh_token, site_id)

        if access_token["access_token"] == "None":
            error_details = {"error_section": "refresh_token", "error": "HTTP error " + str(access_token["status_code"])}
            error_in_http_calls = True
        else:
            rep = http.get(url, headers = {"Authorization": "Bearer " + access_token["access_token"]})
            if rep.status_code != 200:
                response_error = rep.json()
                error_details = {"error_section": "site_id", "error": "Error " + response_error["error"]}
                error_in_http_calls = True

            body = json.decode(rep.body())
    else:
        print("Using Dummy Data")
        body = DUMMY_DATA

    if error_in_http_calls == False:
        data = body["response"]
    else:
        print("Error details: ", str(error_details))

    MIN_POWER_THRESHOLD = 0.01  # 10 Watts

    # Power Data Conversion
    solar_power = data["solar_power"] / 1000  # kW
    load_power = data["load_power"] / 1000  # kW
    grid_power = data["grid_power"] / 1000  # kW
    battery_power = data["battery_power"] / 1000  # kW

    solar_power_str = format_power(solar_power)
    load_power_str = format_power(load_power)
    grid_power_str = format_power(grid_power)
    battery_power_str = format_power(battery_power)
    percentage_charged = int(math.round(data["percentage_charged"]))

    # Battery Charging and Discharging Power
    battery_charging_power = abs(battery_power) if battery_power < 0 else 0
    battery_discharging_power = battery_power if battery_power > 0 else 0

    # Solar to House Power
    solar_to_house_power = min(solar_power, load_power)
    solar_to_house_power = max(solar_to_house_power, 0)  # Ensure non-negative

    # Remaining Load After Solar Contribution
    remaining_load = load_power - solar_to_house_power
    remaining_load = max(remaining_load, 0)

    # Battery to House Power
    battery_to_house_power = min(battery_discharging_power, remaining_load)
    battery_to_house_power = max(battery_to_house_power, 0)

    # Update Remaining Load
    remaining_load -= battery_to_house_power
    remaining_load = max(remaining_load, 0)

    # Grid to House Power
    grid_to_house_power = min(grid_power, remaining_load) if grid_power > 0 else 0
    grid_to_house_power = max(grid_to_house_power, 0)

    # Solar Surplus Power
    solar_surplus_power = max(solar_power - solar_to_house_power, 0)

    # Solar to Battery Power
    solar_to_battery_power = min(solar_surplus_power, battery_charging_power)
    solar_to_battery_power = max(solar_to_battery_power, 0)

    # Grid to Battery Power
    grid_to_battery_power = battery_charging_power - solar_to_battery_power
    grid_to_battery_power = max(grid_to_battery_power, 0)
    grid_to_battery_power = grid_to_battery_power if grid_to_battery_power > MIN_POWER_THRESHOLD else 0

    # Solar to Grid Power
    solar_to_grid_power = solar_surplus_power - solar_to_battery_power
    solar_to_grid_power = max(solar_to_grid_power, 0)

    # Arrows with Conditional Display Logic

    # Solar to House
    solar_to_house = get_arrow(
        start_position = (30, 8),
        length = 18,
        direction = "right",
        color = GREEN_COLOR,
    ) if solar_to_house_power > 0 else None

    # Battery to House
    battery_to_house = get_angled_arrow(
        start_position = (48, 25),
        length = 20,
        fs_length = 11,
        direction = "right-up",
        color = RED_COLOR,
    ) if battery_to_house_power > 0 else None

    # Grid to House
    grid_to_house = get_angled_arrow(
        start_position = (17, 20),
        length = 42,
        fs_length = 38,
        direction = "right-up",
        color = RED_COLOR,
    ) if grid_to_house_power > 0 else None

    # Solar to Battery
    solar_to_battery = get_angled_arrow(
        start_position = (29, 10),
        length = 19,
        fs_length = 9,
        direction = "right-down",
        color = GREEN_COLOR,
    ) if solar_to_battery_power > 0 else None

    # Grid to Battery
    grid_to_battery = get_arrow(
        start_position = (17, 23),
        length = 15,
        direction = "right",
        color = RED_COLOR,
    ) if grid_to_battery_power > 0 else None

    # Solar to Grid
    solar_to_grid = get_angled_arrow(
        start_position = (16, 7),
        length = 16,
        fs_length = 9,
        direction = "left-down",
        color = GREEN_COLOR,
    ) if solar_to_grid_power > 0 else None

    return render.Root(
        child = render.Stack(
            children = [
                solar_to_house,
                solar_to_grid,
                grid_to_battery,
                grid_to_house,
                battery_to_house,
                solar_to_battery,
                render.Padding(
                    pad = (0, 13, 0, 0),
                    child = get_grid_panel(grid_power_str),
                ),
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = get_solar_panel(solar_power_str),
                ),
                render.Padding(
                    pad = (32, 22, 0, 0),
                    child = get_battery_panel(percentage_charged, battery_power_str),
                ),
                render.Padding(
                    pad = (36, 0, 0, 0),
                    child = get_home_panel(load_power_str),
                ),
            ],
        ),
    )

def get_arrow(start_position, length, direction = "right", color = "#fff"):
    left, top = start_position

    renderer = render.Row if direction in ["right", "left"] else render.Column

    # Determine the renderer and padding based on the direction
    if direction in ["right", "left"]:
        renderer = render.Row
        pad_left = left if direction == "right" else left - length + 1
        pad_top = top
    else:  # "up" or "down"
        renderer = render.Column
        pad_left = left
        pad_top = top if direction == "down" else top - length + 1

    # Create the arrow shaft
    arrow_lines = render.Padding(
        pad = (pad_left, pad_top, 0, 0),
        child = renderer(
            children = [
                render.Box(width = 1, height = 1, color = color)
                for _ in range(length)
            ],
        ),
    )

    tip_positions = []
    if direction == "right":
        tip_positions = [
            (length + left - 3, top - 2),
            (length + left - 2, top - 1),
            (length + left - 2, top + 1),
            (length + left - 3, top + 2),
        ]
    elif direction == "left":
        tip_positions = [
            (left - 3, top - 2),
            (left - 4, top - 1),
            (left - 4, top + 1),
            (left - 3, top + 2),
        ]
    elif direction == "up":
        tip_positions = [
            (left - 2, top - length + 3),
            (left - 1, top - length + 2),
            (left + 1, top - length + 2),
            (left + 2, top - length + 3),
        ]
    elif direction == "down":
        tip_positions = [
            (left - 2, top + length - 3),
            (left - 1, top + length - 2),
            (left + 1, top + length - 2),
            (left + 2, top + length - 3),
        ]

    # Build the arrow tip
    arrow_tip = render.Stack(
        children = [
            render.Padding(
                pad = (pos_left, pos_top, 0, 0),
                child = render.Box(width = 1, height = 1, color = color),
            )
            for pos_left, pos_top in tip_positions
        ],
    )

    # Combine the arrow line and tip in the correct order based on direction
    return render.Stack(children = [arrow_tip, arrow_lines])

def get_angled_arrow(start_position, length, fs_length = 0, direction = "right-up", color = "#fff"):
    left, top = start_position
    if fs_length == 0:
        fs_length = length // 2

    # Map directions to signs and primary axis
    direction_map = {
        "right-down": {"h_sign": 1, "v_sign": 1, "primary_axis": "h"},
        "down-right": {"h_sign": 1, "v_sign": 1, "primary_axis": "v"},
        "right-up": {"h_sign": 1, "v_sign": -1, "primary_axis": "h"},
        "up-right": {"h_sign": 1, "v_sign": -1, "primary_axis": "v"},
        "left-down": {"h_sign": -1, "v_sign": 1, "primary_axis": "h"},
        "down-left": {"h_sign": -1, "v_sign": 1, "primary_axis": "v"},
        "left-up": {"h_sign": -1, "v_sign": -1, "primary_axis": "h"},
        "up-left": {"h_sign": -1, "v_sign": -1, "primary_axis": "v"},
    }

    # Ensure the direction is valid
    if not direction_map.get(direction):
        # Since 'raise' is not supported, return an empty render or handle as needed
        return render.Box(width = 0, height = 0)

    h_sign = direction_map[direction]["h_sign"]
    v_sign = direction_map[direction]["v_sign"]
    primary_axis = direction_map[direction]["primary_axis"]

    # Initialize parts based on primary axis
    if primary_axis == "h":
        # Start with horizontal part
        part1 = [
            render.Padding(
                pad = (left + h_sign * i, top, 0, 0),
                child = render.Box(width = 1, height = 1, color = color),
            )
            for i in range(fs_length)
        ]

        # Then vertical part
        part2 = [
            render.Padding(
                pad = (left + h_sign * (fs_length - 1), top + v_sign * (j + 1), 0, 0),
                child = render.Box(width = 1, height = 1, color = color),
            )
            for j in range(length - fs_length)
        ]

        # Base positions for the tip
        base_x = left + h_sign * (fs_length - 1)
        base_y = top + v_sign * (length - fs_length)

        # Tip offsets
        tip_offsets = [
            (0, 1 * v_sign),
            (-1 * h_sign, 0 * v_sign),
            (-2 * h_sign, -1 * v_sign),
            (1 * h_sign, 0 * v_sign),
            (2 * h_sign, -1 * v_sign),
        ]
    else:
        # Start with vertical part
        part1 = [
            render.Padding(
                pad = (left, top + v_sign * i, 0, 0),
                child = render.Box(width = 1, height = 1, color = color),
            )
            for i in range(fs_length)
        ]

        # Then horizontal part
        part2 = [
            render.Padding(
                pad = (left + h_sign * (j + 1), top + v_sign * (fs_length - 1), 0, 0),
                child = render.Box(width = 1, height = 1, color = color),
            )
            for j in range(length - fs_length)
        ]

        # Base positions for the tip
        base_x = left + h_sign * (length - fs_length)
        base_y = top + v_sign * (fs_length - 1)

        # Tip offsets
        tip_offsets = [
            (0 * h_sign, 0),
            (-1 * h_sign, -1 * v_sign),
            (-2 * h_sign, -2 * v_sign),
            (-1 * h_sign, 1 * v_sign),
            (-2 * h_sign, 2 * v_sign),
        ]

    # Combine the parts
    arrow_lines = render.Stack(children = part1 + part2)

    # Calculate tip positions
    tip_positions = [
        (base_x + dx, base_y + dy)
        for dx, dy in tip_offsets
    ]

    # Build the arrow tip
    arrow_tip = render.Stack(
        children = [
            render.Padding(
                pad = (pos_x, pos_y, 0, 0),
                child = render.Box(width = 1, height = 1, color = color),
            )
            for pos_x, pos_y in tip_positions
        ],
    )

    # Combine all parts
    return render.Stack(children = [arrow_lines, arrow_tip])

def format_power(p):
    if p:
        return humanize.float("#,###.##", p)
    else:
        return "0"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "refresh_token",
                name = "Refresh Token",
                desc = "Refresh Token for the Tesla Owner API.",
                icon = "key",
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "The site ID that should be monitored.",
                icon = "solarPanel",
            ),
        ],
    )
