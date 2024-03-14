"""
Applet: Park Wait Times
Summary: Park Wait Times
Description: Displays theme park ride wait times at various theme parks.
Author: hx009
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

COLOR_GREEN = "#4CFF00"
COLOR_YELLOW = "#FFD800"
COLOR_RED = "#FF0000"
COLOR_GRAY = "#A0A0A0"
CACHE_TIME_SECONDS = 300  # cache for 5 minutes per https://queue-times.com/en-US/pages/api
PARKS_URL = "https://queue-times.com/parks.json"

ICON_CEDAR_FAIR = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAJlSURBVDhP1ZPNS1RhFMZ/d+51nBzNafxmHNOiUNOUQolMQ9FFZCIkgYGQi6iF1aJw00a3EUKrcNGmFhIZQQhqBZWpiFgNKho6fqSi48eoo87o3Dszb9exvyBXPZvDe855n+cczjlSpeBQMPy1/4xDE0gtLS0iEAiyt6cRaYogQpHDgQ2/7vOrmBUJc6QRWT7QUtUAjpFZpmeXOZuXgTQ5tSRetX1lzb1NTLSJCwWniMrNZE6VyIkMYA7tYgz6SYyzsO0N0friI9MzLo5YY5i3WJFuNzwXZ7LsVFcWsuTaoGtggs8+mUeFNq4UZ6NEKPhVlcHBYXr7xzDHWLlZU4xbUrjaMY1sTSxsevigiozjiaTa4rCeTickK3gco4yO/caemsD4xBIdXcNUlOWSn5NESnI87Ysab1xBDF6fH00Lhvvbh0mWSLAnca+hmlT985Onr2l/20N9XSlFF/M5FhvLyx8ztM3shHMNK6seuj85EOJgIexmhVVV4JjfZMK5jM2eQl62jckxJ2trm/T4j9K5LlMX78cWpSCnnShp2idZXvHoUzDiXl6n77uTZ72zXEqzcLeujJNZ6QwsbNLRN8r8xg43bDJmzUu3Nwqp4lqzeNxYw7f+cRzDM2xteamqLEA7f46hXRlLhERAL04xSIwsrFNv8VFgNRCIS6b2hx/KK5vFwqJb70CIzg8/xZ37rUJVtfC7ccgtbvWuiF8eVXjUoLj+xSU6Frzh2OyOJjLfzQnpclmtKC/NxWw2oRPhnHJRUpSNQVccXNMVdBTGRxLSq+he9JEVayQ9WmFbC/F+3sd/f0zwBymUDk0EnMGhAAAAAElFTkSuQmCC"""
ICON_DISNEY = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAIpSURBVDhPXZPNS1RRGMbPmWlaRAUlRYs+zNGpheSqQWaKIoqwonLRlYjAlkUZBBK4EUKC6OMfqIXZqkGaiIJcuNAYA1s1GVk204e16YMWQoGTnn7PnXOHnAd+nPc8933fe8/HtaZOzdlg1aIxAeEuSIWmMe9gPGbM8PtCbq5qVVVrsD3dGZtPJLoJr8JPeAQzIG2DI9AAfcsrlcHpyTzv8Q188S3CLrhIwnCUEMnnnCJU3hA5vcqJ6+Hqxh0XGM7B3nIhN/bj67ST/7/k/Zp9XVyzuXWE6Y2FePw38xe2KRtswHgDpyl+3JQ5sc5Y2+qcKX6YyGkpZmsmaLDWyJuSR81R7LuQUoM+gg4+aQ+fmCZ+AmthJuZcG82WsZYi80b4BgfInSJ3nPghG2s6IO/X3AsqlloWrT2L2UOsYmk9nPe5D+CwGjTDS5De+jHSTRiohjWV/PgKkmpQk3W2n+EYfA+NpfoCh8jRKUSKq8Fn0Dmb0sT9Cut7SrhS8zqt4Nmocvy8BcpqoGPplOP1Fz5VwyX6yNrnfSypZjTGTRoiaOc0snL9Bl2CP5p7zRnn5IUidzdDWrXhTcS4wnAS9nMXwrcns0GK23SccIGkfKmQK8sndwvDGNwhdyBskMx0JZx19wh3QjcPnsmvF8X7GG7DczbzjPYjbCD5JpcJdRcmIQ/Rz6QN05p10a5TfC3azFqDSHz6Rj5df+VB2BSaxszCCMmDLEXH6WXMP8E0ziXi0Ay4AAAAAElFTkSuQmCC"""
ICON_SEA_WORLD = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAFNSURBVDhPYxgFDIxQGg5C9tyR4WH5pwLEd6bYaDyBCuMEGAa4bb9nwsLIsJqP9Z8CL8vfO5zM/1eyMf2f02Ol+QCqBAVgGAACWstuJlhzvZ9vzvuA4SMbG8O9/wp//jJwL2Vh+t8CdNUdqDIwQDFANrtPgplPKINZQLRYl+83T4fICgYFwe0MzIK/GB6wuDHc/uf3Z99X9Ylv/4g1zHdQ+wLSAzZA2NJPhZlfuIaZXySciZuPA4gZRHk4GWbz7mVQ5T/GwCTwm4GZ/xeY/sfPxHD1X8aTQ980MossE7cw8oorpTALSbgw8QneYOYVvMHEzf+CkZHRh4lXIB9oEAszNz8DkP1Agff3E0Fepr9mgk+eGAr8l5AVuM7ynenlDhQv8Eqq6jALibUz84u+ZeETOgI09AwjB/eVZ4ua/kCV4AfcApIKUOYoIBowMAAAsC9at/TdWj8AAAAASUVORK5CYII="""
ICON_SIX_FLAGS = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAKHSURBVDhPXVJdSFRBFJ47c++6u+62uhba9oNtmEhpaFGhESRZQg8SG4EFUW8h0Yv0UNAfEfTQg0FQvWiCRFBI0EOQLdsPRYhW4oOkafqwkum6q3v33r13/jpz7am5l+HMme98851vRkOn+9F/Q0pCMDcdRDDSMcIa0jQkEdLUJkH1JwABKchDksBsuhfa647v2zKfs5nUHC7WAB4ZwmqChZDCphASqBMiGvLdTDRO9iSGrhzZuy2KoEaxqeEVcLGu1DjYEEOUu1CmaQ4TIzOZrt4vrXfejM5kiE8HWQopJRAioAz7jeTVo6kb7c11VXCe7bKT9989fPG9qboiFi3lOVs6bE3Yvx6CfqOrrbYmFunYs3XeLPoMfep33izSvouH7nY2RcsD6Zy9YlEupCdJyGCJ3vN6InJ2YEf3y1efZ7GmBii3HEaZaGvYdL61JhI0AAniVM9g4PSfvJm1jPIgXbZMh6m8X//wY+Hc40+LWUvxYgw4LMGfImNchgMGYfLUgeqBa8f2xyvms5aUMldwM3kHcalMgh7ghEjIV1+7YS5jFV3O88WgTz/TEge6Vdt98nHGZWJ7Vbizubo3OWW6rOAKJWmw+/CqRbMFN+uxXn46srEssFyglAoOa4luJRrh//pr6frzMQwcDhXrw/65JXN8dtlhvO/9z+HppUdvJ6cXTR2rF/BtNnN7cKzjXmpoPE0qWzrBikv9w5TLZGpq964YiI5XhhdWbNvlOzeXZQt0Ir3y4NnoqkAcOoe3AP2BHnBNCxggAGQIKRlEykC4YhWQUAkxCKwx3IWhE0OHQNkAnzJU/RLQkIEYKmBXeK8JA5kXeGC1qTCKWF2PdwgcoSBQLxFCfwHiI15HMtlqEAAAAABJRU5ErkJggg=="""
ICON_UNIVERSAL = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAALjSURBVDhPjZPPb1RVFMc/9/2czm9nWmpptRQDk6YuBMGgJrjQFTHRpYlrEgob44oNhB1/gvwHNLAhmGh0Y0xMkAQIQsEmtTO1dmgHO8N7nem8NzNv5nreTBvjzm/yzTv3vPs9956c71XWhad5hfoG+FyYEP4fhMI7Gr2o7AvLN2XxxTAtUELTUJhKysaLGBoirekPRLKfGkEtKWfx90CiRLw53u9aiqxjkHGNYRwrOn3NbjhgtzugK3FcROrFCJVzcUUfCFO2QTFpMlewOZL3CYM9uj0XbYyx0x2j0ujRCPq0e3q/kNwycWlVmwak5dTj4zalSRubHTzrOuvbAflwhsryPDPFaSbffoeKB3/UI1q9gbQEhmkZ2MJcwmK26NLyXzLhbPDu7iPyvRItb4G/U9NUy5s0n9xnbtwlP2bhiCbWqsxX6/qEVeH9gsfclEW0/TMpp0PTX2dq8ih1v00qWUAN+jx4WOX42U9ZrmX5rjlPvWcjlzf5LP0TJX4h9eIus26Txys7mIMcRqdFsu/jdjZorN3jkzMTHPJ/4APne5KW3F+ZqPGvy/pq8Qb1epv24HW2KmWsCYu1LRe/m+X07DPq2QZpsqQ9mVC6xHShS7/jcb17DVWQFkrBQ157Y4a3JvKs/niL2ssOJ88eJmy3SGcsOWkX6YCtP2vMnvqS7T2T2vpfrKTeE798eOXaztgROmaRTC5HImqTtho8/7XK3naEG77i2OQjGrUyXnSCzMI5fqunKVvHxI4OhmHGDlJ4HVira5z5jyC/IDOWFoIuz180uf1tm2pwjqMfn2e1YfIqShCJBwwjnsJlXzwV20qMJLedzhq8mVPY7Rpb1U1xXJ/DU1NYhRk2fdjwtBwmthbFUJW53BxaWTiysglJWwlBrD+EjJswYujAQL5iwgOEUiCQx6T3H1NcQv7GXY0SB5kD7/+bGG1YMiRelNWSUJ7oSBxjKBLKtIff/0L2arWktVr8B5HuK5eiLW0QAAAAAElFTkSuQmCC"""

DEFAULT_PARK = "5"
DEFAULT_SHOW_ACTUAL_WAIT_TIMES = False
DEFAULT_SHOW_CLOSED_RIDES = True
DEFAULT_LITTLE_OR_NO_WAIT_MAX_MINUTES = "15"
DEFAULT_MODERATE_WAIT_MAX_MINUTES = "30"
DEFAULT_FONT = "tom-thumb"
DEFAULT_PIXELS_BETWEEN_RIDES = "2"

def main(config):
    """App entry point

    Args:
        config: User configuration values

    Returns:
        The rendered app
    """
    show_actual_wait_times = config.bool("show_actual_wait_times", DEFAULT_SHOW_ACTUAL_WAIT_TIMES)
    show_closed_rides = config.bool("show_closed_rides", DEFAULT_SHOW_CLOSED_RIDES)
    little_or_no_wait_max_minutes = int(config.get("little_or_no_wait_max_minutes", DEFAULT_LITTLE_OR_NO_WAIT_MAX_MINUTES))
    moderate_wait_max_minutes = int(config.get("moderate_wait_max_minutes", DEFAULT_MODERATE_WAIT_MAX_MINUTES))
    selected_font = config.get("font", DEFAULT_FONT)
    pixels_between_rides = int(config.get("pixels_between_rides", DEFAULT_PIXELS_BETWEEN_RIDES))

    park_list = get_http_data(PARKS_URL)
    park_details = get_http_data("https://queue-times.com/parks/" + config.get("park", DEFAULT_PARK) + "/queue_times.json")
    park_name = "park name"
    operator_name = "operator name"

    for x in range(len(park_list)):
        for y in range(len(park_list[x]["parks"])):
            if str(int(park_list[x]["parks"][y]["id"])) == config.get("park", DEFAULT_PARK):
                park_name = park_list[x]["parks"][y]["name"]
                operator_name = park_list[x]["name"]

    if len(park_details["lands"]) == 0 and len(park_details["rides"]) == 0:
        return render.Root(
            child = render.Column(
                children = [
                    render.WrappedText(content = park_name, font = selected_font),
                    render.WrappedText(content = "Data not available", font = selected_font, color = COLOR_GRAY),
                ],
            ),
        )
    else:
        at_least_one_ride_open = False
        wait_times = []
        wait_times.append(render.WrappedText(content = "Powered by Queue-Times.com", font = selected_font))
        wait_times.append(render.Box(width = 64, height = pixels_between_rides))
        wait_times.append(get_operator_logo(operator_name))
        wait_times.append(render.WrappedText(content = park_name, font = selected_font))
        wait_times.append(render.Box(width = 64, height = pixels_between_rides))

        for land_index in range(len(park_details["lands"])):
            for land_ride_index in range(len(park_details["lands"][land_index]["rides"])):
                if park_details["lands"][land_index]["rides"][land_ride_index]["is_open"]:
                    at_least_one_ride_open = True
                    ride_name = park_details["lands"][land_index]["rides"][land_ride_index]["name"]

                    if show_actual_wait_times:
                        ride_name += " (" + str(int(park_details["lands"][land_index]["rides"][land_ride_index]["wait_time"])) + "min)"

                    if park_details["lands"][land_index]["rides"][land_ride_index]["wait_time"] <= little_or_no_wait_max_minutes:
                        wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_GREEN))
                    elif park_details["lands"][land_index]["rides"][land_ride_index]["wait_time"] <= moderate_wait_max_minutes:
                        wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_YELLOW))
                    else:
                        wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_RED))

                    wait_times.append(render.Box(width = 64, height = pixels_between_rides))
                elif show_closed_rides:
                    wait_times.append(render.WrappedText(content = park_details["lands"][land_index]["rides"][land_ride_index]["name"], font = selected_font, color = COLOR_GRAY))
                    wait_times.append(render.Box(width = 64, height = pixels_between_rides))

        for ride_index in range(len(park_details["rides"])):
            if park_details["rides"][ride_index]["is_open"]:
                at_least_one_ride_open = True
                ride_name = park_details["rides"][ride_index]["name"]

                if show_actual_wait_times:
                    ride_name += " (" + str(int(park_details["rides"][ride_index]["wait_time"])) + "min)"

                if park_details["rides"][ride_index]["wait_time"] <= little_or_no_wait_max_minutes:
                    wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_GREEN))
                elif park_details["rides"][ride_index]["wait_time"] <= moderate_wait_max_minutes:
                    wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_YELLOW))
                else:
                    wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_RED))

                wait_times.append(render.Box(width = 64, height = pixels_between_rides))
            elif show_closed_rides:
                wait_times.append(render.WrappedText(content = park_details["rides"][ride_index]["name"], font = selected_font, color = COLOR_GRAY))
                wait_times.append(render.Box(width = 64, height = pixels_between_rides))

        if at_least_one_ride_open:
            wait_times.append(render.Box(width = 64, height = 1))
        else:
            wait_times.clear()
            wait_times.append(render.WrappedText(content = park_name, font = selected_font))
            wait_times.append(render.WrappedText(content = "Park is closed", font = selected_font, color = COLOR_GRAY))

        return render.Root(
            delay = 100,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Marquee(
                        height = 32,
                        width = 64,
                        offset_start = 32,
                        scroll_direction = "vertical",
                        child = render.Column(
                            main_align = "space_between",
                            children = wait_times,
                        ),
                    ),
                ],
            ),
        )

def get_operator_logo(operator_name):
    """Attempts to retrieve a logo image for a given park operator name

    Args:
        operator_name: A park operator name

    Returns:
        The park operator logo if available, otherwise a 1x1 box
    """
    if operator_name == "Cedar Fair Entertainment Company":
        return render.Image(src = base64.decode(ICON_CEDAR_FAIR))
    elif operator_name == "SeaWorld Parks \u0026 Entertainment":
        return render.Image(src = base64.decode(ICON_SEA_WORLD))
    elif operator_name == "Six Flags Entertainment Corporation":
        return render.Image(src = base64.decode(ICON_SIX_FLAGS))
    elif operator_name == "Universal Parks \u0026 Resorts":
        return render.Image(src = base64.decode(ICON_UNIVERSAL))
    elif operator_name == "Walt Disney Attractions":
        return render.Image(src = base64.decode(ICON_DISNEY))
    else:
        return render.Box(height = 1, width = 1)

def get_http_data(url):
    """Attempts to retrieve JSON data from a remote URL

    Args:
        url: The url to retrieve JSON data from

    Returns:
        JSON data from the specified url
    """
    res = http.get(url, ttl_seconds = CACHE_TIME_SECONDS)
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())
    return res.json()

def get_schema():
    """App configuration

    Returns:
        Application configuration options
    """
    park_json = get_http_data(PARKS_URL)
    parks = []
    parks.append(schema.Option(display = "None", value = "0"))

    for x in range(len(park_json)):
        for y in range(len(park_json[x]["parks"])):
            parks.append(schema.Option(display = park_json[x]["name"] + " - " + park_json[x]["parks"][y]["name"], value = str(int(park_json[x]["parks"][y]["id"]))))

    little_or_no_wait_options = []
    for minutes in range(1, 60):
        little_or_no_wait_options.append(schema.Option(display = str(minutes), value = str(minutes)))

    moderate_wait_options = []
    for minutes in range(1, 120):
        moderate_wait_options.append(schema.Option(display = str(minutes), value = str(minutes)))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "park",
                name = "Park",
                desc = "The park to retrieve wait times for.",
                icon = "gear",
                default = DEFAULT_PARK,
                options = parks,
            ),
            schema.Toggle(
                id = "show_actual_wait_times",
                name = "Show Actual Wait Times",
                desc = "A toggle to enable showing actual wait times",
                icon = "clock",
                default = DEFAULT_SHOW_ACTUAL_WAIT_TIMES,
            ),
            schema.Toggle(
                id = "show_closed_rides",
                name = "Show Closed Rides",
                desc = "A toggle to enable showing or hiding closed rides",
                icon = "gear",
                default = DEFAULT_SHOW_CLOSED_RIDES,
            ),
            schema.Dropdown(
                id = "little_or_no_wait_max_minutes",
                name = "Little Or No Wait Max Minutes",
                desc = "The max minutes a wait is considered little wait",
                icon = "clock",
                default = DEFAULT_LITTLE_OR_NO_WAIT_MAX_MINUTES,
                options = little_or_no_wait_options,
            ),
            schema.Dropdown(
                id = "moderate_wait_options",
                name = "Moderate Wait Max Minutes",
                desc = "The max minutes a wait is considered moderate",
                icon = "clock",
                default = DEFAULT_MODERATE_WAIT_MAX_MINUTES,
                options = moderate_wait_options,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Select font",
                icon = "font",
                default = DEFAULT_FONT,
                options = [
                    schema.Option(
                        display = "10x20",
                        value = "10x20",
                    ),
                    schema.Option(
                        display = "5x8",
                        value = "5x8",
                    ),
                    schema.Option(
                        display = "6x13",
                        value = "6x13",
                    ),
                    schema.Option(
                        display = "CG-pixel-3x5-mono",
                        value = "CG-pixel-3x5-mono",
                    ),
                    schema.Option(
                        display = "CG-pixel-4x5-mono",
                        value = "CG-pixel-4x5-mono",
                    ),
                    schema.Option(
                        display = "Dina_r400-6",
                        value = "Dina_r400-6",
                    ),
                    schema.Option(
                        display = "tb-8",
                        value = "tb-8",
                    ),
                    schema.Option(
                        display = "tom-thumb",
                        value = "tom-thumb",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "pixels_between_rides",
                name = "Pixel Buffer",
                desc = "Pixels to pad between rides displayed",
                icon = "buffer",
                default = DEFAULT_PIXELS_BETWEEN_RIDES,
                options = [
                    schema.Option(
                        display = "0",
                        value = "0",
                    ),
                    schema.Option(
                        display = "1",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3",
                        value = "3",
                    ),
                    schema.Option(
                        display = "4",
                        value = "4",
                    ),
                    schema.Option(
                        display = "5",
                        value = "5",
                    ),
                    schema.Option(
                        display = "6",
                        value = "6",
                    ),
                    schema.Option(
                        display = "7",
                        value = "7",
                    ),
                    schema.Option(
                        display = "8",
                        value = "8",
                    ),
                    schema.Option(
                        display = "9",
                        value = "9",
                    ),
                    schema.Option(
                        display = "10",
                        value = "10",
                    ),
                ],
            ),
        ],
    )
