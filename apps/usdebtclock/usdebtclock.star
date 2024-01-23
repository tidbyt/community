"""
Applet: USDebtClock
Summary: Displays the US total debt
Description: Displays the total debt by the United States of America in dollars.
Author: PMK (@pmk)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("time.star", "time")
load("schema.star", "schema")

DEFAULT_IS_ANIMATING = True
DEFAULT_HAS_BACKGROUND_IMAGE = True

FRAMES_PER_SECOND = 30

NUMBER_SUFFIX = ["trillion", "billion", "million", "thousand", "dollar debt"]

BACKGROUND_IMAGE = base64.decode("""
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
""")

def get_data(ttl_seconds = 60 * 60 * 6):
    url = "https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v2/accounting/od/debt_to_penny?sort=-record_date&format=json&page%5Bnumber%5D=1&page%5Bsize%5D=2"
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Treasury.gov request failed with status %d", response.status_code)
    return response.json()

def convert_to_chunks_by_thousands_separator(big_float_number):
    return humanize.comma(int(float(big_float_number))).split(",")

def convert_duration_to_seconds(duration):
    return int(duration / time.second)

def get_current_debt(raw_data, fr):
    latest_debt = int(float(raw_data[0]["tot_pub_debt_out_amt"]))
    previous_debt = int(float(raw_data[1]["tot_pub_debt_out_amt"]))

    latest_date = time.parse_time(raw_data[0]["record_date"] + "T00:00:00.00Z")
    previous_date = time.parse_time(raw_data[1]["record_date"] + "T00:00:00.00Z")

    diff_number_latest_previous = latest_debt - previous_debt
    diff_number_latest_previous_per_second = int(diff_number_latest_previous / convert_duration_to_seconds(latest_date - previous_date))
    diff_current_latest_in_seconds = convert_duration_to_seconds(time.now() - latest_date)

    return latest_debt + diff_number_latest_previous_per_second + ((diff_current_latest_in_seconds / 30) * fr)

def render_content(raw_data, fr):
    total_debt = get_current_debt(raw_data, fr)
    total_debt_chunks = convert_to_chunks_by_thousands_separator(total_debt)

    rows = []
    for idx, c in enumerate(total_debt_chunks):
        rows.append(
            render.Row(
                expanded = True,
                children = [
                    render.Box(
                        width = 12,
                        height = 6,
                        child = render.Row(
                            expanded = True,
                            main_align = "end",
                            children = [
                                render.Text(
                                    content = "{}".format(int(c)),
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ),

                    render.Padding(
                        pad = (3, 0, 0, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "start",
                            children = [
                                render.Text(
                                    content = NUMBER_SUFFIX[idx],
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ),
                ]
            )
        )
    return render.Column(
        children = rows,
    )

def render_animated_content(raw_data):
    # HOW TO ANIMATE THIS!?
    # [render_content(raw_data)] * 300,
    return render.Animation(
        children = [
            render_content(raw_data, fr) for fr in range(1500)
        ],
    )

    return render_content(raw_data, 1)

def main(config):
    is_animating = config.bool("is_animating", DEFAULT_IS_ANIMATING)
    has_background_image = config.bool("has_background_image", DEFAULT_HAS_BACKGROUND_IMAGE)

    raw_data = get_data()["data"]

    conditional_background_image_elements = []
    if has_background_image:
        conditional_background_image_elements.append(
            render.Stack(
                children = [
                    render.Padding(
                        pad = (-5, -9, 0, 0),
                        child = render.Image(
                            src = BACKGROUND_IMAGE,
                            width = 68,
                            height = 50,
                        ),
                    ),
                    render.Box(
                        width = 64,
                        height = 32,
                        color = "#000B",
                    ),
                ],
            ),
        )

    conditional_background_image_elements.append(
        render.Padding(
            pad = (3, 1, 0, 0),
            child = render_animated_content(raw_data) if is_animating else render_content(raw_data, 1),
        ),
    )

    return render.Root(
        # delay = 32, # 30 fps
        delay = FRAMES_PER_SECOND,
        child = render.Stack(
            children = conditional_background_image_elements,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "has_background_image",
                name = "Show background image?",
                desc = "Will show the animated background image.",
                default = True,
                icon = "user",
            ),
            schema.Toggle(
                id = "is_animating",
                name = "Show animation?",
                desc = "Will animate the numbers.",
                default = True,
                icon = "user",
            ),
        ],
    )
