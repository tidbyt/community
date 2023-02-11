"""
Applet: Octoprint
Summary: Octoprint Status Screen
Description: Recreation of the traditional Marlin LCD screen output for a 3D printer from your locally hosted, publically available Octoprint server.
Author: Cameron Battagler
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

def get_printer_status(octoprint_url, octoprint_api_key):
    api_auth = {"X-Api-Key": octoprint_api_key}
    printer_response = http.get(octoprint_url + "api/printer?exclude=sd", headers = api_auth)
    success = True
    error_message = ""
    if printer_response.status_code != 200:
        success = False
        error_message = "Octoprint unreachable"
        if printer_response.status_code == 403:
            error_message = error_message + ": Bad API Key"

    printer_json = printer_response.json()
    return {
        "success": success,
        "error_message": error_message,
        "json": printer_json,
    }

def get_current_print_job(octoprint_url, octoprint_api_key):
    api_auth = {"X-Api-Key": octoprint_api_key}
    job_response = http.get(octoprint_url + "api/job", headers = api_auth)
    if job_response.status_code != 200:
        return False
    job_json = job_response.json()
    return job_json

def main(config):
    OCTOPRINT_URL = config.get("octoprinturl", "")
    API_KEY = config.get("octoprintapikey", "")

    theme = config.get("theme", "bw")

    if theme == "wb":
        bg_color = "#FFFFFF"
        fg_color = "#000000"
    elif theme == "bb":
        bg_color = "#000058"
        fg_color = "#6F8CA1"
    elif theme == "gm":
        bg_color = "#003000"
        fg_color = "#3CBC3C"
    else:
        bg_color = "#000000"
        fg_color = "#FFFFFF"

    valid_url = True
    valid_api_key = True

    if OCTOPRINT_URL.endswith("/") == False:
        OCTOPRINT_URL = OCTOPRINT_URL + "/"

    if OCTOPRINT_URL.find("http") == -1 or OCTOPRINT_URL.find("://") == -1 or OCTOPRINT_URL.find(".") == -1:
        valid_url = False

    if len(API_KEY) != 32:
        valid_api_key = False

    printing = False
    if (valid_url and valid_api_key):
        printer = get_printer_status(OCTOPRINT_URL, API_KEY)
        if (printer["success"] != False):
            if printer["json"]["state"]["flags"]["printing"] == True:
                printing = True
            job = get_current_print_job(OCTOPRINT_URL, API_KEY)
        else:
            job = False
    else:
        printer = {
            "success": False,
            "error_message": "Octoprint unreachable: Invalid URL or API Key",
        }
        job = False

    hot_nozzle = False
    hot_bed = False

    hotend_target_temp = 0.0
    hotend_actual_temp = 0.0

    bed_target_temp = 0.0
    bed_actual_temp = 0.0

    if (printer["success"] != False):
        hotend_target_temp = printer["json"]["temperature"]["tool0"]["target"]
        hotend_actual_temp = printer["json"]["temperature"]["tool0"]["actual"]
        bed_target_temp = printer["json"]["temperature"]["bed"]["target"]
        bed_actual_temp = printer["json"]["temperature"]["bed"]["actual"]

    hotend_target_temp_readable = humanize.float("###.", hotend_target_temp) + "°"
    hotend_actual_temp_readable = humanize.float("###.", hotend_actual_temp) + "°"
    if (hotend_actual_temp >= 100):
        hot_nozzle = True

    bed_target_temp_readable = humanize.float("###.", bed_target_temp) + "°"
    bed_actual_temp_readable = humanize.float("###.", bed_actual_temp) + "°"
    if (bed_actual_temp >= 30):
        hot_bed = True

    job_name = ""
    job_progress_readable = ""
    job_print_time_formatted = ""
    if (printer["success"] != False and printing):
        job_name = job["job"]["file"]["display"]
        job_progress_readable = humanize.float("###.", job["progress"]["completion"]) + "%"
        minutes_total = job["progress"]["printTime"] // 60
        hours = minutes_total // 60
        minutes = minutes_total % 60
        job_print_time_formatted = humanize.float("##.", hours) + ":" + humanize.float("##.", minutes)
        progress = int(40 * (job["progress"]["completion"] / 100))
        remainder = 40 - progress
    else:
        if printer["success"] == False and job == False:
            job_name = printer["error_message"]
        else:
            job_name = job["job"]["file"]["display"]
        job_progress_readable = "0%"
        job_print_time_formatted = "00:00"
        progress = 0
        remainder = 40

    return render.Root(
        child =
            render.Stack(
                children = [
                    render.Box(width = 64, height = 32, color = bg_color),
                    render.Column(
                        children = [
                            render.Row(
                                children = [
                                    render.Column(
                                        children = [
                                            draw_nozzle(hot_nozzle, fg_color, bg_color),
                                        ],
                                        cross_align = "end",
                                    ),
                                    render.Column(
                                        children = [
                                            render.Text(hotend_target_temp_readable, font = "CG-pixel-4x5-mono", color = fg_color),
                                            render.Box(width = 5, height = 5),
                                            render.Text(hotend_actual_temp_readable, font = "CG-pixel-4x5-mono", color = fg_color),
                                        ],
                                        cross_align = "center",
                                    ),
                                    render.Column(
                                        children = [
                                            render.Text(bed_target_temp_readable, font = "CG-pixel-4x5-mono", color = fg_color),
                                            render.Box(width = 5, height = 5),
                                            render.Text(bed_actual_temp_readable, font = "CG-pixel-4x5-mono", color = fg_color),
                                        ],
                                        cross_align = "center",
                                    ),
                                    render.Column(
                                        children = [
                                            draw_bed(hot_bed, fg_color, bg_color),
                                        ],
                                        cross_align = "start",
                                    ),
                                ],
                                expanded = True,
                                main_align = "space_around",
                            ),
                            render.Row(
                                children = [
                                    render.Box(
                                        child = render.Text(job_progress_readable, font = "CG-pixel-4x5-mono", color = fg_color),
                                        height = 11,
                                        width = 22,
                                    ),
                                    render.Column(
                                        children = [
                                            render.Box(
                                                child = render.Text(job_print_time_formatted, font = "tom-thumb", color = fg_color),
                                                width = 42,
                                                height = 8,
                                            ),
                                            render.Box(
                                                child = render.Row(
                                                    children = draw_progress_bar(progress, remainder, fg_color, bg_color),
                                                    expanded = True,
                                                ),
                                                padding = 1,
                                                height = 3,
                                                color = fg_color,
                                            ),
                                        ],
                                    ),
                                ],
                                expanded = True,
                            ),
                            render.Row(
                                children = [
                                    render.Marquee(
                                        child = render.Text(job_name, font = "tom-thumb", color = fg_color),
                                        scroll_direction = "horizontal",
                                        width = 64,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
    )

def draw_progress_bar(progress, remainder, fg_color, bg_color):
    if (progress == 0):
        return [
            render.Box(
                height = 1,
                width = remainder,
                color = bg_color,
            ),
        ]
    else:
        return [
            render.Box(
                height = 1,
                width = progress,
                color = fg_color,
            ),
            render.Box(
                height = 1,
                width = remainder,
                color = bg_color,
            ),
        ]

def draw_nozzle(hot, fg_color, bg_color):
    if (hot):
        return render.Column(
            children = [
                render.Box(
                    width = 10,
                    height = 2,
                    color = bg_color,
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = bg_color,
                    child = render.Box(
                        width = 8,
                        height = 1,
                        color = fg_color,
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 3,
                    color = fg_color,
                ),
                render.Box(
                    width = 10,
                    height = 2,
                    color = bg_color,
                    child = render.Box(
                        width = 8,
                        height = 2,
                        color = fg_color,
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 2,
                    color = fg_color,
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = fg_color,
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = bg_color,
                    child = render.Box(
                        width = 6,
                        height = 1,
                        color = fg_color,
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = bg_color,
                    child = render.Box(
                        width = 4,
                        height = 1,
                        color = fg_color,
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = bg_color,
                    child = render.Box(
                        width = 2,
                        height = 1,
                        color = fg_color,
                    ),
                ),
            ],
        )
    else:
        return render.Column(
            children = [
                render.Box(
                    width = 10,
                    height = 2,
                    color = bg_color,
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = bg_color,
                    child = render.Box(
                        width = 8,
                        height = 1,
                        color = fg_color,
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 3,
                    color = fg_color,
                    child = render.Box(
                        width = 8,
                        height = 3,
                        color = bg_color,
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 2,
                    color = bg_color,
                    child = render.Box(
                        width = 8,
                        height = 2,
                        color = fg_color,
                        child = render.Box(
                            width = 6,
                            height = 2,
                            color = bg_color,
                        ),
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 2,
                    color = fg_color,
                    child = render.Box(
                        width = 8,
                        height = 2,
                        color = bg_color,
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = fg_color,
                    child = render.Box(
                        width = 6,
                        height = 1,
                        color = bg_color,
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = bg_color,
                    child = render.Box(
                        width = 6,
                        height = 1,
                        color = fg_color,
                        child = render.Box(
                            width = 4,
                            height = 1,
                            color = bg_color,
                        ),
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = bg_color,
                    child = render.Box(
                        width = 4,
                        height = 1,
                        color = fg_color,
                        child = render.Box(
                            width = 2,
                            height = 1,
                            color = bg_color,
                        ),
                    ),
                ),
                render.Box(
                    width = 10,
                    height = 1,
                    color = bg_color,
                    child = render.Box(
                        width = 2,
                        height = 1,
                        color = fg_color,
                    ),
                ),
            ],
        )

def draw_bed(hot, fg_color, bg_color):
    if (hot):
        return render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = 5,
                            height = 1,
                            color = bg_color,
                            child = render.Box(width = 1, height = 1, color = fg_color),
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 3,
                            height = 2,
                            color = bg_color,
                            child = render.Box(width = 1, height = 2, color = fg_color),
                        ),
                        render.Box(
                            width = 1,
                            height = 2,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 2,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 5,
                            height = 1,
                            color = bg_color,
                            child = render.Box(width = 1, height = 1, color = fg_color),
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 6,
                            height = 1,
                            color = bg_color,
                            child = render.Box(width = 1, height = 1, color = fg_color),
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 10,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 4,
                            height = 1,
                            color = bg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 2,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 2,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 2,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 2,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 3,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 4,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 5,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 6,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 10,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
            ],
        )
    else:
        return render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = 14,
                            height = 5,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 10,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 4,
                            height = 1,
                            color = bg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 2,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 3,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 4,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 5,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                        render.Box(
                            width = 8,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 6,
                            height = 1,
                            color = bg_color,
                        ),
                        render.Box(
                            width = 10,
                            height = 1,
                            color = fg_color,
                        ),
                    ],
                ),
            ],
        )

def get_schema():
    options = [
        schema.Option(
            display = "Black and White",
            value = "bw",
        ),
        schema.Option(
            display = "White and Black",
            value = "wb",
        ),
        schema.Option(
            display = "Beautiful Blue",
            value = "bb",
        ),
        schema.Option(
            display = "Green Meanie",
            value = "gm",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "octoprinturl",
                name = "Octoprint Url",
                desc = "Your self hosted, publically availble octoprint instance. Make sure your Octoprint is secure, we just need access to the API.",
                icon = "print",
            ),
            schema.Text(
                id = "octoprintapikey",
                name = "Octoprint API Key",
                desc = "Your octoprint API key you generated in Application Keys.",
                icon = "key",
            ),
            schema.Dropdown(
                id = "theme",
                name = "Theme",
                desc = "Color of the text and background.",
                icon = "palette",
                default = options[0].value,
                options = options,
            ),
        ],
    )
